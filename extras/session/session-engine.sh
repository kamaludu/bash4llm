#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/session/session-engine.sh
# Extra: Additional Session engine
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Contract: exposes session_engine_enabled, session_engine_build_window,
#           session_engine_append, session_engine_snapshot
# Safety: uses only RUN_TMPDIR and BASH4LLM_HISTORY_DIR; uses lock_exec/atomic_write;
#         on any failure returns non-zero and leaves original files untouched.
# Behavior: Option A for --session-window: explicit N -> last N messages across segments,
#           do not apply target_bytes trimming in that case.
#
# NOTE (contractual): this engine requires a valid RUN_TMPDIR (or BASH4LLM_TMPDIR)
# to create temporary files. If RUN_TMPDIR is unset or not writable the engine
# will return non-zero and the core must fallback to legacy session handling.
# =============================================================================

# --- Defaults (can be overridden via env) ---
: "${BASH4LLM_SESSION_ENGINE:=on}"
: "${BASH4LLM_SESSION_SEGMENT_MAX_BYTES:=1048576}"
: "${BASH4LLM_SESSION_SEGMENT_MAX_FILES:=100}"
: "${BASH4LLM_SESSION_COMPRESSION_ENABLED:=0}"
: "${BASH4LLM_SESSION_COMPRESSION_CMD:=gzip}"
: "${BASH4LLM_SESSION_SUMMARY_ENABLED:=0}"
: "${BASH4LLM_SESSION_SUMMARY_THRESHOLD_MESSAGES:=500}"
: "${BASH4LLM_SESSION_SUMMARY_MAX_DEPTH:=3}"
: "${BASH4LLM_SESSION_TARGET_BYTES:=32768}"
: "${BASH4LLM_SESSION_MIN_MESSAGES:=3}"
: "${BASH4LLM_SESSION_MAX_MESSAGES:=200}"
: "${BASH4LLM_SESSION_DEDUP_ENABLED:=1}"
: "${BASH4LLM_SESSION_MIN_CONTENT_BYTES:=8}"
: "${BASH4LLM_SESSION_DEDUP_WINDOW:=20}"
: "${SESSION_CACHE_ENABLED:=1}"
: "${SESSION_CACHE_TTL_SEC:=30}"

# Ensure required globals exist (provided by core)
: "${BASH4LLM_HISTORY_DIR:?}"
: "${RUN_TMPDIR:=${BASH4LLM_TMPDIR:-}}"

SE_DIR="${BASH4LLM_EXTRAS_DIR%/}/session"
SE_SESSION_DIR="${BASH4LLM_HISTORY_DIR%/}/sessions"

# In-process cache (non-persistent)
declare -A SE_CACHE_MTIME    # file mtime at cache creation (for invalidation)
declare -A SE_CACHE_WINDOW   # cached JSON window (key: sid|params_hash)
declare -A SE_CACHE_STORED_TS # epoch when cache entry was stored (for TTL)

_se_log() {
  local lvl="$1" msg="$2"
  if type log_info >/dev/null 2>&1; then
    case "$lvl" in
      info) log_info "SESSION" "$msg" ;;
      warn) log_warn "SESSION" "$msg" ;;
      err)  log_error "SESSION" "$msg" ;;
      *) printf 'session-engine: %s: %s\n' "$lvl" "$msg" >&2 ;;
    esac
  else
    printf 'session-engine: %s: %s\n' "$lvl" "$msg" >&2
  fi
}

# Reverse a stream or file portably (macOS and Linux compatible)
_se_reverse() {
  local f="${1:-}"
  if [ -n "$f" ]; then
    if command -v tac >/dev/null 2>&1; then
      tac "$f"
    elif type tac_fallback >/dev/null 2>&1; then
      tac_fallback "$f"
    else
      awk '{lines[NR]=$0} END{for(i=NR;i>0;i--) print lines[i]}' "$f"
    fi
  else
    if command -v tac >/dev/null 2>&1; then
      tac
    else
      awk '{lines[NR]=$0} END{for(i=NR;i>0;i--) print lines[i]}'
    fi
  fi
}

# Portable mtime extraction (macOS and Linux compatible)
_se_file_mtime() {
  local f="$1"
  if type _file_mtime >/dev/null 2>&1; then
    _file_mtime "$f"
  else
    case "$(uname 2>/dev/null || echo Linux)" in
      Darwin) stat -f %m "$f" 2>/dev/null || true ;;
      *) stat -c %Y "$f" 2>/dev/null || true ;;
    esac
  fi
}

# safe tmp file in RUN_TMPDIR (creates file and returns path)
_se_tmpf() {
  local base="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}"
  [ -n "$base" ] || return 1
  mkdir -p "$base" 2>/dev/null || return 1
  if command -v mktemp >/dev/null 2>&1; then
    local f
    # Portable mktemp format (works on both Linux and macOS)
    f="$(mktemp "$base/se.XXXXXX" 2>/dev/null)" || return 1
    chmod 600 "$f" 2>/dev/null || true
    printf '%s' "$f"
  else
    local f="$base/se.$$.$RANDOM"
    : > "$f" 2>/dev/null || return 1
    chmod 600 "$f" 2>/dev/null || true
    printf '%s' "$f"
  fi
}

# list segments for a session (sorted ascending). includes base file first.
_se_list_segments() {
  local sid="$1" dir="${SE_SESSION_DIR%/}"
  [ -n "$sid" ] || return 1
  if [ ! -d "$dir" ]; then return 0; fi
  (
    [ -f "$dir/${sid}.ndjson" ] && printf '%s|%s\n' "000" "$dir/${sid}.ndjson"
    for f in "$dir/${sid}."*.ndjson "$dir/${sid}."*.ndjson.gz; do
      [ -e "$f" ] || continue
      idx="$(basename "$f" | sed -E "s/^${sid}\.([0-9]{3})\.ndjson(\.gz)?$/\1/")"
      printf '%s|%s\n' "${idx:-999}" "$f"
    done
  ) | sort -n -t'|' -k1,1 | awk -F'|' '{print $2}'
  return 0
}

# portable file size helper (uses core file_size if available)
_se_file_size() {
  local f="$1"
  if type file_size >/dev/null 2>&1; then
    file_size "$f"
  else
    [ -f "$f" ] && wc -c < "$f" 2>/dev/null || printf '0'
  fi
}

# compute simple weight (role+content length)
_se_compute_weight() {
  local role="$1" content="$2"
  printf '%d' $(( ${#role} + ${#content} ))
}

# dedupe check in last N lines (returns 0 if duplicate found)
_se_dedupe_check() {
  local session_file="$1" role="$2" content="$3" window="${4:-$BASH4LLM_SESSION_DEDUP_WINDOW}"
  [ -f "$session_file" ] || return 1

  local tmp
  tmp="$(_se_tmpf)" || return 1
  tail -n "$window" "$session_file" 2>/dev/null > "$tmp" || { rm -f "$tmp" 2>/dev/null || true; return 1; }

  while IFS= read -r line || [ -n "$line" ]; do
    if printf '%s' "$line" | jq -e --arg r "$role" --arg c "$content" '(.role == $r) and ((.content // "") == $c)' >/dev/null 2>&1; then
      rm -f "$tmp" 2>/dev/null || true
      return 0
    fi
  done < "$tmp"

  rm -f "$tmp" 2>/dev/null || true
  return 1
}

# compress segment if enabled and tool exists (non-destructive)
_se_compress_segment() {
  local seg="$1"
  if [ "${BASH4LLM_SESSION_COMPRESSION_ENABLED:-0}" -ne 1 ]; then return 0; fi
  if [ ! -f "$seg" ]; then return 0; fi
  if ! command -v "${BASH4LLM_SESSION_COMPRESSION_CMD}" >/dev/null 2>&1; then
    _se_log warn "compression cmd not found: ${BASH4LLM_SESSION_COMPRESSION_CMD}; skipping compression"
    return 0
  fi
  local tmpc
  tmpc="$(_se_tmpf).gz" || return 1
  if "${BASH4LLM_SESSION_COMPRESSION_CMD}" -c "$seg" > "$tmpc" 2>/dev/null; then
    if mv -f "$tmpc" "${seg}.gz" 2>/dev/null; then
      chmod 600 "${seg}.gz" 2>/dev/null || true
      return 0
    else
      rm -f "$tmpc" 2>/dev/null || true
      return 1
    fi
  else
    rm -f "$tmpc" 2>/dev/null || true
    return 1
  fi
}

# rotate segment if current file exceeds threshold
# NOTE: next index computation is performed INSIDE the lock to avoid races.
_se_segment_rotate_if_needed() {
  local session_file="$1"
  local max_bytes="${BASH4LLM_SESSION_SEGMENT_MAX_BYTES:-1048576}"
  [ -f "$session_file" ] || return 0
  local sz
  sz="$(_se_file_size "$session_file")"
  if [ "$sz" -le "$max_bytes" ]; then return 0; fi

  local lockfile="${session_file}.lock"
  # perform rotation inside lock_exec critical section using bash to support 10# evaluation
  lock_exec "$lockfile" 5 -- bash -c '
    set -e
    session_file="$1"
    dir="$(dirname "$session_file")"
    base="$(basename "$session_file" .ndjson)"
    # compute current max index by scanning files inside lock
    max=0
    for p in "$dir/${base}."*.ndjson "$dir/${base}."*.ndjson.gz; do
      [ -e "$p" ] || continue
      idx="$(basename "$p" | sed -E "s/^$base\.([0-9]{3})\.ndjson(\.gz)?$/\1/")"
      case "$idx" in
        ""|"$p") continue ;;
      esac
      if printf "%s\n" "$idx" | grep -qE "^[0-9]+$"; then
        if [ "$idx" -gt "$max" ]; then max="$idx"; fi
      fi
    done
    next=$((10#$max + 1))
    nextp="$(printf "%03d" "$next")"
    dest="$dir/${base}.${nextp}.ndjson"
    # move current to numbered segment atomically
    if mv -f "$session_file" "$dest"; then
      chmod 600 "$dest" 2>/dev/null || true
    else
      # if mv fails, exit non-zero to signal caller
      exit 2
    fi
  ' _ "$session_file" || {
    _se_log err "segment rotation failed for $session_file"
    return 1
  }

  # After rotation, optionally compress oldest segments if count exceeds limit
  local cnt
  cnt="$( (ls -1 "${SE_SESSION_DIR%/}/$(basename "$session_file" .ndjson)."*.ndjson 2>/dev/null || true) | wc -l | tr -d ' ' )"
  if [ -z "$cnt" ]; then cnt=0; fi
  if [ "$cnt" -gt "${BASH4LLM_SESSION_SEGMENT_MAX_FILES:-100}" ]; then
    local to_compress
    to_compress="$(ls -1 "${SE_SESSION_DIR%/}/$(basename "$session_file" .ndjson)."*.ndjson 2>/dev/null | sort | head -n $((cnt - BASH4LLM_SESSION_SEGMENT_MAX_FILES)) )"
    for s in $to_compress; do
      _se_compress_segment "$s" || _se_log warn "failed to compress $s"
    done
  fi

  return 0
}

# invalidate cache entries for a session id (prefix match)
_se_invalidate_cache_for_sid() {
  local sid="$1"
  local k
  for k in "${!SE_CACHE_WINDOW[@]}"; do
    case "$k" in
      "${sid}"\|*) unset "SE_CACHE_WINDOW[$k]" "SE_CACHE_MTIME[$k]" "SE_CACHE_STORED_TS[$k]" ;;
    esac
  done
}

# --- Public API: session_engine_enabled
session_engine_enabled() {
  if [ "${BASH4LLM_SESSION_ENGINE:-on}" = "off" ]; then return 1; fi
  if [ ! -d "${SE_DIR}" ]; then return 1; fi
  # require RUN_TMPDIR to be set and writable
  if [ -z "${RUN_TMPDIR:-}" ] && [ -z "${BASH4LLM_TMPDIR:-}" ]; then
    _se_log warn "session engine disabled: RUN_TMPDIR/BASH4LLM_TMPDIR not set"
    return 1
  fi
  return 0
}

# --- Public API: session_engine_append <session_id> <role> <content> <meta_json>
session_engine_append() {
  local sid="$1" role="$2" content="$3" meta_json="$4"
  local session_file="${SE_SESSION_DIR%/}/${sid}.ndjson"
  local lockfile="${session_file}.lock"
  local tmpf marker_dir created_marker=0

  # Validate sid if CORE provides validator
  if type session_validate_id >/dev/null 2>&1; then
    if ! session_validate_id "$sid"; then
      _se_log err "append: invalid session id: $sid"
      return 1
    fi
  fi

  if [ -z "$sid" ] || [ -z "$role" ]; then
    _se_log err "append: missing sid or role"
    return 1
  fi

  if ! mkdir -p "${SE_SESSION_DIR%/}" 2>/dev/null; then
    _se_log err "append: cannot create session dir ${SE_SESSION_DIR}"
    return 1
  fi
  chmod 700 "${SE_SESSION_DIR%/}" 2>/dev/null || true

  if ! ensure_run_tmpdir >/dev/null 2>&1; then
    _se_log err "append: cannot ensure RUN_TMPDIR"
    return 1
  fi

  # 1) Segmentation: rotate if needed (non-destructive)
  if ! _se_segment_rotate_if_needed "$session_file"; then
    _se_log err "append: segmentation failed for $session_file"
    return 1
  fi

  # 2) Dedup/noise detection
  local mark_ignored=0
  if [ "${BASH4LLM_SESSION_DEDUP_ENABLED:-1}" -eq 1 ]; then
    if _se_dedupe_check "$session_file" "$role" "$content" "${BASH4LLM_SESSION_DEDUP_WINDOW:-20}"; then
      mark_ignored=1
    fi
  fi

  # 3) Build NDJSON line with optional meta
  local ts hash schema meta_line line
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if command -v sha256sum >/dev/null 2>&1; then
    hash="$(printf '%s' "${role}|${content}" | sha256sum | awk '{print $1}')"
  else
    hash=""
  fi
  schema="1"
  if ! meta_line="$(printf '%s' "${meta_json:-}" | jq -c '.' 2>/dev/null)"; then
    meta_line="{}"
  fi
  if [ "$mark_ignored" -eq 1 ]; then
    meta_line="$(printf '%s' "$meta_line" | jq -c '. + {ignored:true}' 2>/dev/null || printf '%s' "$meta_line")"
  fi

  line="$(jq -c -n --arg ts "$ts" --arg role "$role" --arg content "$content" --arg hash "$hash" --arg schema "$schema" --argjson meta "$meta_line" \
    '{ts:$ts, role:$role, content:$content, hash:$hash, schema_version:$schema, meta:$meta}')" || {
    _se_log err "append: failed to compose JSON line"
    return 1
  }

  # 4) Idempotency marker (same semantics as core)
  local message_id
  message_id="$(printf '%s' "$meta_json" | jq -r '.id // empty' 2>/dev/null || true)"
  if [ -n "$message_id" ]; then
    marker_dir="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}/session-msg-${message_id}.lockdir"
    if mkdir "$marker_dir" 2>/dev/null; then
      printf '%s\n' "$$" > "${marker_dir}/owner.pid" 2>/dev/null || true
      printf '%s\n' "$(date +%s)" > "${marker_dir}/owner.ts" 2>/dev/null || true
      chmod 700 "$marker_dir" 2>/dev/null || true
      created_marker=1
    else
      _se_log info "append skipped: marker exists for message_id $message_id"
      return 0
    fi
  else
    marker_dir="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}/run-$$-${RANDOM}.lockdir"
    mkdir -p "$marker_dir" 2>/dev/null || true
    printf '%s\n' "$$" > "${marker_dir}/owner.pid" 2>/dev/null || true
    printf '%s\n' "$(date +%s)" > "${marker_dir}/owner.ts" 2>/dev/null || true
    chmod 700 "$marker_dir" 2>/dev/null || true
    created_marker=1
  fi

  # 5) Append under lock (atomic)
  if ! lock_exec "$lockfile" 5 -- bash -c '
    set -e
    session_file="$1"
    line="$2"
    if [ ! -f "$session_file" ]; then
      : > "$session_file"
      chmod 600 "$session_file" 2>/dev/null || true
    fi
    printf "%s\n" "$line" >> "$session_file"
    chmod 600 "$session_file" 2>/dev/null || true
  ' _ "$session_file" "$line"; then
    if [ "${created_marker:-0}" -eq 1 ]; then rm -rf -- "$marker_dir" 2>/dev/null || true; fi
    _se_log err "append: failed to write to $session_file"
    return 1
  fi

  # 6) Post-append rotation attempt (non-fatal)
  if ! _se_segment_rotate_if_needed "$session_file"; then
    _se_log warn "append: post-append rotation failed for $session_file"
  fi

  # 7) Update in-process cache: invalidate entries for this sid
  _se_invalidate_cache_for_sid "$sid"

  touch "${marker_dir}/done" 2>/dev/null || true
  return 0
}

# --- Public API: session_engine_build_window <session_id> <N> <target_bytes> <out_file>
# Option A: N > 0 -> last N non-ignored messages.
# Option B: N = 0 -> weight-based accumulation up to target_bytes.
session_engine_build_window() {
  local sid="$1" N="$2" target_bytes="$3" out="$4"
  local session_file="${SE_SESSION_DIR%/}/${sid}.ndjson"
  local tmpf

  if type session_validate_id >/dev/null 2>&1; then
    if ! session_validate_id "$sid"; then
      _se_log err "build_window: invalid session id: $sid"
      return 1
    fi
  fi

  [ -n "$sid" ] || { _se_log err "build_window: missing session id"; return 1; }
  [ -n "$out" ] || { _se_log err "build_window: missing out file"; return 1; }

  if ! ensure_run_tmpdir >/dev/null 2>&1; then
    _se_log err "build_window: cannot ensure RUN_TMPDIR"
    return 1
  fi

  tmpf="$(_se_tmpf)" || return 1
  : > "$tmpf" || { rm -f "$tmpf" 2>/dev/null || true; return 1; }

  local params_hash
  params_hash="$(printf '%s|%s|%s' "$N" "$target_bytes" "${BASH4LLM_SESSION_TARGET_BYTES:-}" | (command -v sha256sum >/dev/null 2>&1 && sha256sum | awk '{print $1}' || cat) 2>/dev/null || true)"
  local cache_key="${sid}|${params_hash}"

  if [ "${SESSION_CACHE_ENABLED:-1}" -eq 1 ] && [ -f "$session_file" ]; then
    local cached_mtime stored_ts now
    cached_mtime="$(_se_file_mtime "$session_file")"
    stored_ts="${SE_CACHE_STORED_TS[$cache_key]:-}"
    now="$(date +%s)"
    if [ -n "${SE_CACHE_MTIME[$cache_key]:-}" ] && [ "${SE_CACHE_MTIME[$cache_key]}" = "$cached_mtime" ] && [ -n "${SE_CACHE_WINDOW[$cache_key]:-}" ]; then
      if [ -n "$stored_ts" ] && [ "${SESSION_CACHE_TTL_SEC:-0}" -gt 0 ]; then
        if [ $((now - stored_ts)) -le "${SESSION_CACHE_TTL_SEC:-0}" ]; then
          printf '%s' "${SE_CACHE_WINDOW[$cache_key]}" > "$out" 2>/dev/null || true
          rm -f "$tmpf" 2>/dev/null || true
          return 0
        fi
      else
        printf '%s' "${SE_CACHE_WINDOW[$cache_key]}" > "$out" 2>/dev/null || true
        rm -f "$tmpf" 2>/dev/null || true
        return 0
      fi
    fi
  fi

  local -a seg_arr=()
  local seg
  while IFS= read -r seg; do
    [ -z "$seg" ] && continue
    case "$seg" in *.gz) continue ;; esac
    if [ -f "$seg" ]; then
      seg_arr+=("$seg")
    fi
  done < <(_se_list_segments "$sid" 2>/dev/null)

  # Guard against empty segment array to prevent cat from waiting on stdin
  if [ "${#seg_arr[@]}" -eq 0 ]; then
    printf '%s' '{"messages":[]}' > "$out" 2>/dev/null || true
    rm -f "$tmpf" 2>/dev/null || true
    return 0
  fi

  if printf '%s' "$N" | grep -qE '^[0-9]+$' && [ "$N" -gt 0 ]; then
    # Option A: Explicit N override (single jq call, filtering non-objects to prevent crashes)
    if ! cat "${seg_arr[@]}" 2>/dev/null | jq -s --argjson n "$N" '
      [ .[] | select(type == "object" and .meta?.ignored != true) ]
      | (if length <= $n then . else .[-$n:] end)
      | {messages: map({role: .role, content: .content})}
    ' > "$tmpf" 2>/dev/null; then
      _se_log err "build_window: jq failed to assemble messages for explicit N override"
      rm -f "$tmpf" 2>/dev/null || true
      return 1
    fi
  else
    # Option B: target_bytes limit logic using recursive/reduce logic in a single fork
    local target="${target_bytes:-${BASH4LLM_SESSION_TARGET_BYTES:-32768}}"
    local min_msgs="${BASH4LLM_SESSION_MIN_MESSAGES:-3}"
    local max_msgs="${BASH4LLM_SESSION_MAX_MESSAGES:-200}"

    if ! cat "${seg_arr[@]}" 2>/dev/null | jq -s \
      --argjson min "$min_msgs" \
      --argjson max "$max_msgs" \
      --argjson target "$target" \
      '
      [ .[] | select(type == "object" and .meta?.ignored != true) ] | reverse |
      reduce .[] as $msg (
        {acc: [], total_bytes: 0, count: 0, stop: false};
        if .stop then .
        else
          ((($msg.role // "") | length) + (($msg.content // "") | length)) as $w |
          if .count < $min then
            .acc += [$msg] | .total_bytes += $w | .count += 1
          elif .count >= $max then
            .stop = true
          elif (.total_bytes + $w) <= $target then
            .acc += [$msg] | .total_bytes += $w | .count += 1
          else
            .stop = true
          end
        end
      ) | .acc | reverse | {messages: map({role: .role, content: .content})}
      ' > "$tmpf" 2>/dev/null; then
      _se_log err "build_window: jq failed to assemble messages for target_bytes limit"
      rm -f "$tmpf" 2>/dev/null || true
      return 1
    fi
  fi

  if [ -s "$tmpf" ]; then
    if mv -f "$tmpf" "$out" 2>/dev/null || cp -f "$tmpf" "$out" 2>/dev/null; then
      chmod 600 "$out" 2>/dev/null || true
      if [ "${SESSION_CACHE_ENABLED:-1}" -eq 1 ] && [ -f "$session_file" ]; then
        local mt
        mt="$(_se_file_mtime "$session_file")"
        SE_CACHE_MTIME["$cache_key"]="${mt:-$(date +%s)}"
        SE_CACHE_WINDOW["$cache_key"]="$(cat "$out" 2>/dev/null || true)"
        SE_CACHE_STORED_TS["$cache_key"]="$(date +%s)"
      fi
      rm -f "$tmpf" 2>/dev/null || true
      return 0
    fi
  fi

  rm -f "$tmpf" 2>/dev/null || true
  return 1
}

# --- Public API: session_engine_snapshot <session_id> <out_file>
session_engine_snapshot() {
  local sid="$1" out="$2"
  local dir="${SE_SESSION_DIR%/}"

  # Validate sid if CORE provides validator
  if type session_validate_id >/dev/null 2>&1; then
    if ! session_validate_id "$sid"; then
      _se_log err "snapshot: invalid session id: $sid"
      return 1
    fi
  fi

  [ -n "$sid" ] || return 1
  [ -n "$out" ] || return 1
  if [ ! -d "$dir" ]; then
    printf '%s' '{"error":"no sessions directory"}' > "$out" 2>/dev/null || true
    return 1
  fi

  local tmp="$(_se_tmpf)" || return 1
  : > "$tmp"
  local segments_list
  segments_list="$(_se_list_segments "$sid")"
  local total_msgs=0 total_size=0 seg_count=0
  for s in $segments_list; do
    seg_count=$((seg_count+1))
    sz="$(_se_file_size "$s")"
    total_size=$((total_size + sz))
    if [ -f "$s" ]; then
      c="$(wc -l < "$s" 2>/dev/null || echo 0)"
      total_msgs=$((total_msgs + c))
    fi
  done

  local last_tmp="$(_se_tmpf).last" || { rm -f "$tmp" 2>/dev/null || true; return 1; }
  : > "$last_tmp"
  for s in $segments_list; do
    case "$s" in *.gz) continue ;; esac
    cat "$s" >> "$last_tmp"
  done
  tail -n 50 "$last_tmp" > "${last_tmp}.tail" 2>/dev/null || true

  local summaries_tmp="$(_se_tmpf).sums" || { rm -f "$tmp" "$last_tmp" "${last_tmp}.tail" 2>/dev/null || true; return 1; }
  : > "$summaries_tmp"
  for s in $segments_list; do
    case "$s" in *.gz) continue ;; esac
    awk 'NF' "$s" | while IFS= read -r line || [ -n "$line" ]; do
      if printf '%s' "$line" | jq -e '.meta?.summary == true' >/dev/null 2>&1; then
        printf '%s\n' "$line" >> "$summaries_tmp"
      fi
    done
  done

  # Build snapshot JSON
  jq -n --arg sid "$sid" \
    --argjson message_count "$total_msgs" \
    --argjson segments "$seg_count" \
    --argjson total_size "$total_size" \
    --slurpfile last "${last_tmp}.tail" \
    --slurpfile sums "$summaries_tmp" \
    '{session_id:$sid, stats:{message_count:$message_count, segments:$seg_count, total_size_bytes:$total_size}, last_messages:($last|map(.)), summaries:($sums|map(.))}' > "$out" 2>/dev/null || {
      _se_log err "snapshot: failed to assemble JSON"
      rm -f "$tmp" "$last_tmp" "${last_tmp}.tail" "$summaries_tmp" 2>/dev/null || true
      return 1
    }

  rm -f "$tmp" "$last_tmp" "${last_tmp}.tail" "$summaries_tmp" 2>/dev/null || true
  return 0
}
# End of session-engine.sh
