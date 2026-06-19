#!/usr/bin/env bash
# =============================================================================
# Bash4LLM — Bash-first wrapper for the Groq API
# File: extras/providers/huggingface.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/bash4llm
# =============================================================================

# When sourced, avoid enabling strict mode globally.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

HFAPIKEY="${HFAPIKEY:-}"

# Default helpers for tmpdir and mktemp in project-local tmpdir
_get_work_tmpdir_hf() {
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "${RUN_TMPDIR:-}" ]; then
    printf '%s' "$RUN_TMPDIR"
    return 0
  fi
  if [ -n "${BASH4LLM_TMPDIR:-}" ] && [ -d "${BASH4LLM_TMPDIR:-}" ]; then
    printf '%s' "$BASH4LLM_TMPDIR"
    return 0
  fi
  if type make_tmpdir >/dev/null 2>&1; then
    local d
    d="$(make_tmpdir 2>/dev/null || true)"
    if [ -n "$d" ] && [ -d "$d" ]; then
      printf '%s' "$d"
      return 0
    fi
  fi
  return 1
}

_mktemp_in_dir_hf() {
  local dir="$1" tmpf
  [ -z "$dir" ] && return 1
  [ ! -d "$dir" ] && return 1
  tmpf="$(mktemp -p "$dir" hf-XXXX 2>/dev/null || true)"
  [ -z "$tmpf" ] && return 1
  printf '%s' "$tmpf"
  return 0
}

# -------------------------
# HF endpoints config helpers
# -------------------------
hf_default_endpoints_file() {
  # derive repo root relative to this script if possible
  local base
  base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd 2>/dev/null || pwd)"
  printf '%s' "${HF_ENDPOINTS_FILE:-${base}/bash4llm.d/config/providers/hf_endpoints}"
}

# Load endpoints file (no remote calls). Returns 0 if file exists or empty file is acceptable.
hf_load_endpoints() {
  local f
  f="$(hf_default_endpoints_file)"
  if [ ! -f "$f" ]; then
    # ensure directory exists
    mkdir -p "$(dirname "$f")" 2>/dev/null || true
    : > "$f" 2>/dev/null || true
    chmod 644 "$f" 2>/dev/null || true
  fi
  printf '%s' "$f"
  return 0
}

# Get endpoint URL for a model name (exact match on left field). Prints URL or empty.
hf_get_endpoint_for_model() {
  local model="$1" f
  f="$(hf_load_endpoints)" || return 1
  # exact match on model name (field before first |)
  awk -F'|' -v m="$model" 'BEGIN{OFS=FS} $1==m {print $2; exit}' "$f" 2>/dev/null || true
}

# List endpoints (human readable)
hf_list_endpoints() {
  local f i=0
  f="$(hf_load_endpoints)" || return 1
  if [ ! -s "$f" ]; then
    printf 'No Hugging Face endpoints registered (file: %s)\n' "$f" >&2
    return 0
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    model="$(printf '%s' "$line" | awk -F'|' '{print $1}')"
    url="$(printf '%s' "$line" | awk -F'|' '{print $2}')"
    i=$((i+1))
    printf '%d) %s -> %s\n' "$i" "$model" "$url"
  done < "$f"
  return 0
}

# Add an endpoint: model|url
hf_add_endpoint() {
  local model="$1" url="$2" f tmp
  f="$(hf_load_endpoints)" || return 1
  # minimal validation
  case "$url" in
    https://*) ;;
    *) log_error "HF" "Endpoint URL must start with https://"; return 1 ;;
  esac
  # ensure no duplicate model
  if awk -F'|' -v m="$model" '$1==m{exit 1}' "$f" 2>/dev/null; then
    log_error "HF" "Model '$model' already present in endpoints file"
    return 1
  fi
  tmp="$(_mktemp_in_dir_hf "$(dirname "$f")" 2>/dev/null || true)" || tmp="${f}.tmp"
  printf '%s|%s\n' "$model" "$url" >> "$tmp"
  # append existing content then move atomically
  if [ -s "$f" ]; then
    cat "$f" >> "$tmp" 2>/dev/null || true
  fi
  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp" | atomic_write "$f" || mv -f "$tmp" "$f"
  else
    mv -f "$tmp" "$f" 2>/dev/null || cp -f "$tmp" "$f" 2>/dev/null || true
  fi
  chmod 644 "$f" 2>/dev/null || true
  return 0
}

# Remove endpoint by model name
hf_remove_endpoint() {
  local model="$1" f tmp
  f="$(hf_load_endpoints)" || return 1
  if ! awk -F'|' -v m="$model" '$1==m{found=1} END{exit !found}' "$f" 2>/dev/null; then
    log_error "HF" "Model '$model' not found in endpoints file"
    return 1
  fi
  tmp="$(_mktemp_in_dir_hf "$(dirname "$f")" 2>/dev/null || true)" || tmp="${f}.tmp"
  awk -F'|' -v m="$model" '$1!=m{print $0}' "$f" > "$tmp" 2>/dev/null || true
  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp" | atomic_write "$f" || mv -f "$tmp" "$f"
  else
    mv -f "$tmp" "$f" 2>/dev/null || cp -f "$tmp" "$f" 2>/dev/null || true
  fi
  chmod 644 "$f" 2>/dev/null || true
  return 0
}

# -------------------------
# buildpayload_huggingface
# -------------------------
buildpayload_huggingface() {
  local workdir tmp_payload model_in_file model_to_use user_prompt joined

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $BASH4LLMERRTMP
  fi

  workdir="$(_get_work_tmpdir_hf)" || return $BASH4LLMERRTMP
  tmp_payload="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP
  umask 077

  # Ensure PAYLOAD/RESP variables point to safe file paths (use .json for clarity)
  PAYLOAD="${PAYLOAD:-${workdir}/payload.json}"
  RESP="${RESP:-${workdir}/resp.json}"

  if [ -n "${JSON_INPUT:-}" ]; then
    # If JSON contains OpenAI-style messages, convert to HF Inference inputs
    if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
      # join messages into a single textual input (preserve role labels)
      joined="$(jq -r '[.messages[] | (if .role then (.role + ": ") else "" end) + (.content // "")] | join("\n\n")' "$JSON_INPUT" 2>/dev/null || true)"
      jq -n --arg inputs "$joined" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
         '{inputs:$inputs, parameters:$params}' > "$tmp_payload"
      if type atomic_write >/dev/null 2>&1; then
        cat "$tmp_payload" | atomic_write "$PAYLOAD"
      else
        cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
        chmod 600 "$PAYLOAD" 2>/dev/null || true
      fi
      return 0
    fi

    # If JSON contains "prompt", convert to HF inputs
    if jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
      user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
      model_in_file="$(jq -r '.model // empty' "$JSON_INPUT" 2>/dev/null || true)"
      model_to_use="${model_in_file:-$MODEL}"
      jq -n --arg inputs "$user_prompt" --arg model "$model_to_use" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
         '{inputs:$inputs, model:$model, parameters:$params}' > "$tmp_payload"
      if type atomic_write >/dev/null 2>&1; then
        cat "$tmp_payload" | atomic_write "$PAYLOAD"
      else
        cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
        chmod 600 "$PAYLOAD" 2>/dev/null || true
      fi
      return 0
    fi

    # Pass through raw JSON_INPUT (assume already HF-style)
    if type atomic_write >/dev/null 2>&1; then
      cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
    else
      cp -f "$JSON_INPUT" "$PAYLOAD" 2>/dev/null || true
      chmod 600 "$PAYLOAD" 2>/dev/null || true
    fi
    return 0
  fi

  # No JSON_INPUT: build inputs from SYSTEM_PROMPT + CONTENT
  if [ -n "${SYSTEM_PROMPT:-}" ]; then
    joined="$(printf 'System: %s\n\nUser: %s' "$SYSTEM_PROMPT" "$CONTENT")"
  else
    joined="$CONTENT"
  fi

  jq -n --arg inputs "$joined" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
     '{inputs:$inputs, parameters:$params}' > "$tmp_payload"

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp_payload" | atomic_write "$PAYLOAD"
  else
    cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
    chmod 600 "$PAYLOAD" 2>/dev/null || true
  fi
  return 0
}

# -------------------------
# call_api_huggingface
# -------------------------
call_api_huggingface() {
  local prov_env

  # Resolve API key via core helper if available
  if type ensure_api_key_for_provider >/dev/null 2>&1; then
    if ! ensure_api_key_for_provider "huggingface"; then
      log_error "APIKEY" "HF API key required to call Hugging Face."
      return $BASH4LLMERRNOAPIKEY
    fi
  fi

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    HFAPIKEY="${!prov_env:-${HFAPIKEY:-}}"
  fi

  if [ -z "${HFAPIKEY:-}" ]; then
    log_error "APIKEY" "HF API key not set (env ${prov_env:-HUGGINGFACE_API_KEY})."
    return $BASH4LLMERRNOAPIKEY
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $BASH4LLMERRTMP
  fi

  # Ensure PAYLOAD/RESP have sensible defaults inside the project tmpdir
  workdir="$(_get_work_tmpdir_hf)" || return $BASH4LLMERRTMP
  PAYLOAD="${PAYLOAD:-${workdir}/payload.json}"
  RESP="${RESP:-${workdir}/resp.json}"
  ERRF="${ERRF:-${workdir}/curl.err}"

  dbg "PAYLOAD path: ${PAYLOAD:-<unset>}"
  dbg "RESP path: ${RESP:-<unset>}"

  # Expose payload path for reproducibility (stderr)
  printf 'bash4llm: DEBUG: using payload file: %s\n' "${PAYLOAD:-<unset>}" >&2

  if [ ! -s "${PAYLOAD:-}" ]; then
    log_error "HTTP" "payload file missing or empty: ${PAYLOAD:-<unset>}"
    return $BASH4LLMERRTMP
  fi
  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
    return 0
  fi

  # Resolve endpoint for requested model from local endpoints file
  local endpoint_url
  endpoint_url="$(hf_get_endpoint_for_model "$MODEL" 2>/dev/null || true)"
  if [ -z "${endpoint_url:-}" ]; then
    log_error "HTTP" "Model '$MODEL' not registered in local HF endpoints. Use bash4llm --provider to add an endpoint."
    printf '{"error":"model_not_registered","model":"%s","hint":"Register endpoint in bash4llm.d/config/providers/hf_endpoints"}\n' "$MODEL" > "${RESP}" 2>/dev/null || true
    chmod 600 "${RESP}" 2>/dev/null || true
    return $BASH4LLMERRAPI
  fi

  # Build api_url from endpoint_url (user-provided endpoint is authoritative)
  api_url="${endpoint_url%/}"

  # Show a redacted reproducible curl command in debug logs
  dbg "Repro curl (redacted): curl -H 'Authorization: Bearer <REDACTED>' -H 'Content-Type: application/json' --data-binary @\"$PAYLOAD\" \"$api_url\""

  local tmpout tmpresp hdr_file http_result http_code time_total http_ct http_body err_text rc
  tmpout="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP
  tmpresp="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP
  hdr_file="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP

  : > "$tmpout" 2>/dev/null || true
  : > "$ERRF" 2>/dev/null || true
  : > "$tmpresp" 2>/dev/null || true
  : > "$hdr_file" 2>/dev/null || true

  # Perform request: capture headers to hdr_file, body to tmpresp, and write http_code/time to tmpout
  http_result="$(curl "${CURL_BASE_OPTS[@]:-}" \
    -sS -D "$hdr_file" \
    -H "Authorization: Bearer $HFAPIKEY" \
    -H "Content-Type: application/json" \
    --data-binary @"$PAYLOAD" \
    -o "$tmpresp" -w '%{http_code} %{time_total}' \
    "$api_url" 2>"$ERRF" || true)"

  # Parse http_code and time_total
  read -r http_code time_total <<EOF
$http_result
EOF
  http_code="${http_code:-000}"

  # Determine content-type (lowercased)
  http_ct="$(tr '[:upper:]' '[:lower:]' < "$hdr_file" 2>/dev/null | grep -i '^content-type:' || true)"
  http_body="$(cat "$tmpresp" 2>/dev/null || true)"

  # Persist response atomically if present
  if [ -s "$tmpresp" ]; then
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmpresp" | atomic_write "${RESP}" || cp -f "$tmpresp" "${RESP}" 2>/dev/null || true
    else
      cp -f "$tmpresp" "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true
    fi
  else
    : > "${RESP}" 2>/dev/null || true
  fi

  # Cleanup tmpout (we keep RESP and PAYLOAD for inspection)
  rm -f "$tmpout" 2>/dev/null || true

  # Handle HTTP status
  case "$http_code" in
    2*)
      # Success: if JSON, print it; otherwise log debug and return success
      if printf '%s' "$http_ct" | grep -q 'application/json'; then
        cat "${RESP}" || printf '%s' "$http_body"
        return 0
      else
        dbg "HF non-json response (truncated): $(printf '%s' "$http_body" | head -c 2048)"
        log_error "HTTP" "API returned non-JSON response (status $http_code). See debug logs."
        return $BASH4LLMERRAPI
      fi
      ;;
    404)
      # Endpoint returned 404: provide actionable hint
      dbg "HTTP 404 response headers (head):"; head -n 50 "$hdr_file" >&2 || true
      dbg "HTTP body (truncated):"; printf '%s' "$http_body" | head -c 2048 >&2 || true
      dbg "curl stderr (head):"; head -n 200 "$ERRF" >&2 || true

      log_error "HTTP" "API error (status 404): endpoint returned 404. Check endpoint URL and token permissions."
      printf '{"error":"HTTP 404","message":%s,"hint":"Check endpoint URL, token permissions, or use a different endpoint."}\n' \
        "$(printf '%s' "$http_body" | sed -n '1,6p' | jq -R -s . 2>/dev/null || printf 'null')" > "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true

      rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
      return $BASH4LLMERRAPI
      ;;
    *)
      # Other non-2xx errors: extract textual error from HTML if possible
      err_text=""
      if printf '%s' "$http_body" | grep -qi '<pre'; then
        err_text="$(printf '%s' "$http_body" | sed -n 's/.*<pre[^>]*>\(.*\)<\/pre>.*/\1/p' | sed 's/<[^>]*>//g' | awk '{$1=$1;print}')"
      else
        err_text="$(printf '%s' "$http_body" | sed 's/<[^>]*>/ /g' | tr -s '[:space:]' ' ' | awk '{print; exit}')"
      fi
      err_text="$(printf '%s' "$err_text" | sed -n '1,6p' | awk '{$1=$1;print}')"

      dbg "HTTP $http_code response headers (head):"; head -n 50 "$hdr_file" >&2 || true
      dbg "HTTP body (truncated):"; printf '%s' "$http_body" | head -c 2048 >&2 || true
      dbg "curl stderr (head):"; head -n 200 "$ERRF" >&2 || true

      if [ -n "$err_text" ]; then
        log_error "HTTP" "API error (status $http_code): $err_text"
      else
        log_error "HTTP" "API error (status $http_code). See debug logs for details."
      fi

      printf '{"error":"HTTP %s","message":%s}\n' "$http_code" "$(printf '%s' "$err_text" | jq -R -s . 2>/dev/null || printf 'null')" > "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true

      rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
      return $BASH4LLMERRAPI
      ;;
  esac
}

# -------------------------
# call_api_streaming_huggingface
# -------------------------
call_api_streaming_huggingface() {
  local prov_env

  # Resolve API key via core helper if available
  if type ensure_api_key_for_provider >/dev/null 2>&1; then
    if ! ensure_api_key_for_provider "huggingface"; then
      log_error "APIKEY" "HF API key required to call Hugging Face."
      return $BASH4LLMERRNOAPIKEY
    fi
  fi

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    HFAPIKEY="${!prov_env:-${HFAPIKEY:-}}"
  fi

  if [ -z "${HFAPIKEY:-}" ]; then
    log_error "APIKEY" "HF API key not set (env ${prov_env:-HUGGINGFACE_API_KEY})."
    return $BASH4LLMERRNOAPIKEY
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    return 0
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $BASH4LLMERRTMP
  fi

  local api_url rc RESP_RAW workdir hdr_file ERRF
  workdir="$(_get_work_tmpdir_hf)" || return $BASH4LLMERRTMP
  RESP_RAW="${RESP_RAW:-${workdir}/resp.raw}"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true
  ERRF="${ERRF:-${workdir}/curl.err}"
  RESP="${RESP:-$workdir/resp.json}"
  hdr_file="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP

  # Resolve endpoint for requested model from local endpoints file
  local endpoint_url
  endpoint_url="$(hf_get_endpoint_for_model "$MODEL" 2>/dev/null || true)"
  if [ -z "${endpoint_url:-}" ]; then
    log_error "HTTP" "Model '$MODEL' not registered in local HF endpoints. Use bash4llm --provider to add an endpoint."
    return $BASH4LLMERRAPI
  fi

  # Build api_url from endpoint_url (user-provided endpoint is authoritative)
  api_url="${endpoint_url%/}"

  # Use array-safe expansion of CURL_BASE_OPTS if defined by core
  curl "${CURL_BASE_OPTS[@]:-}" \
       -sS -D "$hdr_file" \
       -H "Authorization: Bearer $HFAPIKEY" \
       -H "Content-Type: application/json" \
       --no-buffer \
       --data-binary @"$PAYLOAD" \
       "$api_url" \
       2>"$ERRF" | tee -a "$RESP_RAW" | \
  while IFS= read -r line; do
    case "$line" in
      'data: [DONE]'|'data:[DONE]') break ;;
      data:\ * )
        json="${line#data: }"
        raw="$(printf '%s' "$json" | jq -R -c 'fromjson? | (.choices[]?.delta?.content // .choices[]?.message?.content // empty) | select(length>0)' 2>>"$ERRF" || true)"
        [ -n "$raw" ] && printf '%s' "$raw"
        ;;
      *) ;;
    esac
  done

  rc=${PIPESTATUS[0]:-0}
  [ "$rc" -ne 0 ] && {
    dbg "curl stderr (head):"; head -n 50 "$ERRF" >&2 || true
    rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
    return $BASH4LLMERRCURL_FAILED
  }

  # Post-processing: build resp.chunks.json, resp.text.txt and write RESP atomically
  : > "$workdir/resp.lines" 2>/dev/null || true
  grep -E '^data:' "$RESP_RAW" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' > "$workdir/resp.lines" 2>/dev/null || true

  : > "$workdir/resp.valid.jsons" 2>/dev/null || true
  while IFS= read -r _line; do
    if printf '%s' "$_line" | jq -e . >/dev/null 2>&1; then
      printf '%s\n' "$_line" >> "$workdir/resp.valid.jsons"
    fi
  done < "$workdir/resp.lines"

  if [ -s "$workdir/resp.valid.jsons" ]; then
    jq -s '.' "$workdir/resp.valid.jsons" > "$workdir/resp.chunks.json" 2>/dev/null || true
    jq -r 'map(.choices[]?.delta?.content // .choices[]?.message?.content // "") | join("")' "$workdir/resp.chunks.json" > "$workdir/resp.text.txt" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$workdir/resp.chunks.json" | atomic_write "${RESP:-$workdir/resp.json}" "${BASH4LLM_LOCK_TIMEOUT_TMP:-}" || cp -f "$workdir/resp.chunks.json" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    else
      cp -f "$workdir/resp.chunks.json" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi

    if [ -n "${RUN_TMPDIR:-}" ] && case "$RUN_TMPDIR" in "${BASH4LLM_TMPDIR:-}"/*) true;; "${BASH4LLM_TMPDIR:-}") true;; *) false;; esac; then
      rm -f "$workdir/resp.lines" "$workdir/resp.valid.jsons" 2>/dev/null || true
    fi
  else
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      cp -f "$RESP_RAW" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi
  fi

  rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
  return 0
}

# -------------------------
# refresh_models_huggingface
# -------------------------
refresh_models_huggingface() {
  # For the local-endpoints architecture, refresh_models simply reads the hf_endpoints
  # file and writes the model names (one per line) to the provided outpath.
  local outpath="${1:-${MODELS_FILE:-}}"
  local f tmpd tmpout

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$BASH4LLMERRTMP"
  fi

  f="$(hf_load_endpoints)" || return "$BASH4LLMERRTMP"

  # Create a temp file under project tmpdir and write model names
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$BASH4LLMERRTMP"
  fi
  tmpd="$(_get_work_tmpdir_hf)" || tmpd="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}"
  tmpout="$(_mktemp_in_dir_hf "$tmpd" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"

  # Extract model names (left field) ignoring comments and blank lines
  awk -F'|' 'NF && $1!~/^#/ {print $1}' "$f" | awk 'NF{print}' | sort -u > "$tmpout" 2>/dev/null || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmpout" | atomic_write "$outpath"
  else
    mv "$tmpout" "${outpath}.new" 2>/dev/null || cp -f "$tmpout" "${outpath}.new" 2>/dev/null || true
    chmod 600 "${outpath}.new" 2>/dev/null || true
    mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
  fi

  chmod 600 "$outpath" 2>/dev/null || true
  log_info "MODELREFRESH" "Hugging Face models refreshed from local endpoints and saved to: $outpath"
  return 0
}

validate_model_huggingface() {
  local model="$1"
  # Validate against local models list (MODELS_FILE) if present, else accept
  if [ -f "$MODELS_FILE" ] && [ -s "$MODELS_FILE" ]; then
    grep -x -F -q "$model" "$MODELS_FILE" 2>/dev/null
    return $?
  fi
  return 0
}

auto_select_model_huggingface() {
  local file="$MODELS_FILE" result=""
  if [ -f "$file" ] && [ -s "$file" ]; then
    result="$(awk 'NF{print; exit}' "$file" 2>/dev/null || true)"
    printf '%s' "$result"
    return 0
  fi
  printf ''
  return 0
}
