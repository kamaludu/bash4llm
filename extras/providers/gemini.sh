#!/usr/bin/env bash
# =============================================================================
# GroqBash⁺ — Bash-first wrapper for the Groq API
# File: gemini.sh
# Version: 2.0.0
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# =============================================================================
# Provider: Gemini (extras/providers/gemini.sh)
# Purpose: GroqBash provider adapter for Gemini-style APIs (compat shim)
# Notes: Localized fixes applied to enforce GroqBash invariants:
# -----------------------------------------------------------------------------

# When sourced, avoid enabling strict mode globally.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

API_URL_GEMINI_TEMPLATE='https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent'
MODELS_ENDPOINT_GEMINI='https://generativelanguage.googleapis.com/v1beta/models'

# Provide no-op dbg() if not defined by core
if ! type dbg >/dev/null 2>&1; then
  dbg() { :; }
fi

# -------------------------
# Helpers (tmpdir, mktemp, safe writes)
# -------------------------
_get_work_tmpdir_gemini() {
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "${RUN_TMPDIR:-}" ]; then
    printf '%s' "$RUN_TMPDIR"
    return 0
  fi
  if [ -n "${GROQBASH_TMPDIR:-}" ] && [ -d "${GROQBASH_TMPDIR:-}" ]; then
    printf '%s' "$GROQBASH_TMPDIR"
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

_mktemp_in_dir_gemini() {
  local dir="$1" tmpf
  [ -n "$dir" ] || return 1
  [ -d "$dir" ] || return 1
  tmpf="$(mktemp -p "$dir" gemini-XXXX 2>/dev/null || true)"
  [ -n "$tmpf" ] || return 1
  printf '%s' "$tmpf"
  return 0
}

_write_atomic() {
  local src="$1" dst="$2"
  if type atomic_write >/dev/null 2>&1; then
    cat "$src" | atomic_write "$dst"
    return $?
  fi
  cat "$src" > "$dst"
  chmod 600 "$dst" 2>/dev/null || true
  return 0
}

_b64_atomic_write() {
  if type b64_atomic_write >/dev/null 2>&1; then
    b64_atomic_write "$@"
    return $?
  fi
  # Fallback: decode to dest (not atomic) but ensure dest is under allowed dirs
  local staged="$1" dest="$2"
  base64 ${B64_DECODE_OPT:-} < "$staged" > "$dest"
  chmod 600 "$dest" 2>/dev/null || true
  return 0
}

# -------------------------
# Safe substitute ${MODEL} in template without sed
# -------------------------
_substitute_model_in_template() {
  local template="$1" model="$2"
  printf '%s' "${template//\$\{MODEL\}/$model}"
}

# -------------------------
# buildpayload_gemini (NEW)
# -------------------------
buildpayload_gemini() {
  if [ -z "${PAYLOAD:-}" ]; then
    printf "Error: \$PAYLOAD not set; cannot write payload\n" >&2
    return 2
  fi

  local workdir tmpf messages_json messages_arg
  workdir="$(_get_work_tmpdir_gemini)" || workdir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
  [ -n "$workdir" ] || return 3

  tmpf="$(_mktemp_in_dir_gemini "$workdir")" || tmpf="${workdir%/}/payload.$$"

  messages_arg=''
  if [ -n "${MESSAGES_JSON:-}" ]; then
    if [ -f "${MESSAGES_JSON}" ]; then
      messages_json="$(cat "${MESSAGES_JSON}" 2>/dev/null || true)"
    else
      messages_json="${MESSAGES_JSON}"
    fi
    if printf '%s' "${messages_json}" | jq -e . >/dev/null 2>&1; then
      if printf '%s' "${messages_json}" | jq -e 'if type=="array" then . else [.] end' >/dev/null 2>&1; then
        messages_arg=1
      else
        messages_arg=''
      fi
    else
      messages_arg=''
    fi
  fi

  if [ -z "${messages_arg}" ]; then
    if [ -z "${CONTENT:-}" ]; then
      printf 'Error: no MESSAGES_JSON and no CONTENT provided; cannot build payload\n' >&2
      return 4
    fi
  fi

  local jq_extra_args=()
  if [ -n "${TURE:-}" ]; then
    if printf '%s' "${TURE}" | grep -Eq '^[0-9]+([.][0-9]+)?$'; then
      jq_extra_args+=( --argjson temperature "${TURE}" )
    else
      jq_extra_args+=( --arg temperature "${TURE}" )
    fi
  fi

  if [ -n "${MAX_TOKENS:-}" ]; then
    if printf '%s' "${MAX_TOKENS}" | grep -Eq '^[0-9]+$'; then
      jq_extra_args+=( --argjson max_tokens "${MAX_TOKENS}" )
    else
      jq_extra_args+=( --arg max_tokens "${MAX_TOKENS}" )
    fi
  fi

  if [ -n "${STREAM_MODE:-}" ] && is_truthy "${STREAM_MODE:-0}"; then
    jq_extra_args+=( --argjson stream true )
  fi

  umask 077
  if [ -n "${messages_arg}" ]; then
    local msgs_tmp
    msgs_tmp="$(_mktemp_in_dir_gemini "$workdir")" || msgs_tmp="${workdir%/}/msgs.$$"
    printf '%s' "${messages_json}" > "$msgs_tmp"
    if jq -n --slurpfile messages "$msgs_tmp" "${jq_extra_args[@]:-}" \
         '$payload = {} |
          ($messages[0] // []) as $msgs |
          ($payload + {model: env.MODEL} + (if ($msgs|length)>0 then {messages:$msgs} else {} end) + (if ($ARGS.named.temperature != null) then {temperature:$ARGS.named.temperature} else {} end) + (if ($ARGS.named.max_tokens != null) then {max_tokens:$ARGS.named.max_tokens} else {} end) + (if ($ARGS.named.stream != null) then {stream:$ARGS.named.stream} else {} end))' > "$tmpf" 2>/dev/null; then
      :
    else
      jq -n --slurpfile messages "$msgs_tmp" '$payload={model:env.MODEL,messages:$messages[0]}' > "$tmpf" 2>/dev/null || true
    fi
    rm -f "$msgs_tmp" 2>/dev/null || true
  else
    if jq -n --arg model "${MODEL:-}" --arg content "${CONTENT:-}" "${jq_extra_args[@]:-}" \
         '{model:$model, messages:[{role:"user", content:$content}]}' > "$tmpf" 2>/dev/null; then
      :
    else
      printf '{"model":"%s","messages":[{"role":"user","content":"%s"}]}\n' "${MODEL:-}" "${CONTENT:-}" > "$tmpf" 2>/dev/null || true
    fi
  fi

  if [ -s "$tmpf" ]; then
    if [ "$(tail -c1 "$tmpf" 2>/dev/null || true)" != "" ]; then
      printf '\n' >> "$tmpf" 2>/dev/null || true
    fi
  fi

  if ! jq -e . "$tmpf" >/dev/null 2>&1; then
    printf 'Error: built payload is not valid JSON\n' >&2
    rm -f "$tmpf" 2>/dev/null || true
    return 5
  fi

  if [ "${PAYLOAD##*.}" = "b64" ] && type stage_b64 >/dev/null 2>&1; then
    if stage_b64 "$tmpf" "$PAYLOAD"; then
      rm -f "$tmpf" 2>/dev/null || true
      return 0
    else
      _write_atomic "$tmpf" "${PAYLOAD}" || cp -f "$tmpf" "${PAYLOAD}" 2>/dev/null || true
      rm -f "$tmpf" 2>/dev/null || true
      return 0
    fi
  fi

  umask 077
  if _write_atomic "$tmpf" "${PAYLOAD}"; then
    rm -f "$tmpf" 2>/dev/null || true
    chmod 600 "${PAYLOAD}" 2>/dev/null || true
    return 0
  else
    cp -f "$tmpf" "${PAYLOAD}" 2>/dev/null || true
    chmod 600 "${PAYLOAD}" 2>/dev/null || true
    rm -f "$tmpf" 2>/dev/null || true
    return 0
  fi
}

# -------------------------
# call_api_gemini (non-streaming)
# -------------------------
call_api_gemini() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required for provider gemini."
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"API key required for provider gemini"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$GROQBASHERRNOAPIKEY"
  fi

  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  local key
  key="${!prov_env:-${GROQBASH_API_KEY:-${GEMINI_API_KEY:-}}}"

  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key not available for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"API key not available for provider gemini"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$GROQBASHERRNOAPIKEY"
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    printf 'Error: payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "payload file missing or empty" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"payload file missing or empty"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 3
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
    local workdir_dr
    workdir_dr="$(_get_work_tmpdir_gemini)" || workdir_dr="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_dr%/}/resp.json}"
    umask 077
    jq -n '{choices:[]}' > "${resp_path}" 2>/dev/null || printf '{"choices":[]}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 0
  fi

  local workdir tmpout tmpresp errf api_template api_url model_subst key_trim http_code time_total
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpout="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  tmpresp="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  errf="$(_mktemp_in_dir_gemini "$workdir")" || errf="${workdir%/}/curl.err"
  chmod 600 "$errf" 2>/dev/null || true

  api_template="${API_URL_GEMINI_TEMPLATE:-$API_URL_GEMINI_TEMPLATE}"
  model_subst="${MODEL#models/}"
  if [ -z "$model_subst" ]; then
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    local resp_path="${RESP:-${workdir%/}/resp.json}"
    umask 077
    jq -n --arg err "MODEL not set" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"MODEL not set"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 7
  fi

  api_url="$(_substitute_model_in_template "$api_template" "$model_subst")"

  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  dbg "call_api_gemini: url=${api_url}"

  if ! curl "${CURL_BASE_OPTS[@]:-}" --silent --show-error --no-buffer --max-time 120 \
       -H "Authorization: Bearer ${key_trim}" -H "Content-Type: application/json" \
       --data-binary @"$PAYLOAD" -o "$tmpresp" -w '%{http_code} %{time_total}' "$api_url" 2>"$errf" >"$tmpout"; then
    :
  fi

  http_code="$(awk '{print $1}' "$tmpout" 2>/dev/null || true)"
  time_total="$(awk '{print $2}' "$tmpout" 2>/dev/null || true)"
  if [ -z "$http_code" ]; then
    http_code="$(cat "$tmpout" 2>/dev/null || echo "000")"
    http_code="$(printf '%s' "$http_code" | awk '{print $1}' 2>/dev/null || true)"
  fi
  time_total="${time_total:-0}"

  local resp_path="${RESP:-$workdir/resp.json}"

  if [ -s "$tmpresp" ]; then
    if [ -n "${RESP:-}" ]; then
      _write_atomic "$tmpresp" "${resp_path}"
    else
      cp -f "$tmpresp" "${resp_path}" 2>/dev/null || true
      chmod 600 "${resp_path}" 2>/dev/null || true
    fi
  else
    umask 077
    jq -n --arg code "${http_code:-000}" --arg msg "empty response body" '{error:{code:$code,message:$msg}}' > "${resp_path}" 2>/dev/null || printf '{"error":{"code":"%s","message":"%s"}}\n' "${http_code:-000}" "empty response body" > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
  fi

  if [ -s "${resp_path}" ] && jq -e . "${resp_path}" >/dev/null 2>&1; then
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${resp_path}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      tmpconv="$(_mktemp_in_dir_gemini "$workdir" 2>/dev/null || true)"
      if [ -z "$tmpconv" ]; then
        tmpconv="${workdir%/}/gemini-conv.$$"
        : > "$tmpconv" 2>/dev/null || true
      fi
      umask 077
      jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv"
      _write_atomic "$tmpconv" "${resp_path}" || { cp -f "$tmpconv" "${resp_path}" 2>/dev/null || true; chmod 600 "${resp_path}" 2>/dev/null || true; }
      rm -f "$tmpconv" 2>/dev/null || true
    fi
  fi

  case "$http_code" in
    2*)
      rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true
      return 0
      ;;
    *)
      gemini_report_error "$tmpresp" "$errf"
      if ! jq -e . "${resp_path}" >/dev/null 2>&1; then
        umask 077
        jq -n --arg code "${http_code:-000}" --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{code:$code,stderr:$stderr}}' > "${resp_path}" 2>/dev/null || printf '{"error":{"code":"%s","stderr":"%s"}}\n' "${http_code:-000}" "$(head -n 200 "$errf" 2>/dev/null || true)" > "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
      rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true
      return 5
      ;;
  esac
}

# -------------------------
# call_api_streaming_gemini (streaming)
# -------------------------
call_api_streaming_gemini() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required for provider gemini."
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"API key required for provider gemini"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$GROQBASHERRNOAPIKEY"
  fi

  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  local key
  key="${!prov_env:-${GROQBASH_API_KEY:-${GEMINI_API_KEY:-}}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key not available for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"API key not available for provider gemini"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$GROQBASHERRNOAPIKEY"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    local workdir_dr
    workdir_dr="$(_get_work_tmpdir_gemini)" || workdir_dr="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_dr%/}/resp.json}"
    umask 077
    jq -n '{choices:[]}' > "${resp_path}" 2>/dev/null || printf '{"choices":[]}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 0
  fi

  local workdir RESP_RAW errf api_template api_url model_subst key_trim rc
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  RESP_RAW="$(_mktemp_in_dir_gemini "$workdir")" || RESP_RAW="${workdir%/}/resp.raw"
  errf="$(_mktemp_in_dir_gemini "$workdir")" || errf="${workdir%/}/curl.err"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  api_template="${API_URL_GEMINI_TEMPLATE:-$API_URL_GEMINI_TEMPLATE}"
  model_subst="${MODEL#models/}"
  if [ -z "$model_subst" ]; then
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    local resp_path="${RESP:-${workdir%/}/resp.json}"
    umask 077
    jq -n --arg err "MODEL not set" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"MODEL not set"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 7
  fi

  api_url="$(_substitute_model_in_template "$api_template" "$model_subst")"
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  dbg "call_api_streaming_gemini: url=${api_url}"

  curl "${CURL_BASE_OPTS[@]:-}" -H "Authorization: Bearer ${key_trim}" -H "Content-Type: application/json" --no-buffer --max-time 0 --data-binary @"$PAYLOAD" "$api_url" 2>"$errf" | \
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      data:\ * ) line="${line#data: }" ;;
      '' ) continue ;;
    esac

    if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      chunk="$(printf '%s' "$line" | jq -r 'try (if .candidates then (.candidates[]?.content?.parts[]?.text // empty) elif .content then (.content?.parts[]?.text // empty) elif .outputs then (.outputs[]?.content?.parts[]?.text // empty) else empty end) catch empty' 2>>"$errf" || true)"
      if [ -n "$chunk" ]; then
        # Emit OpenAI-like SSE chunk: data: { "choices":[{"delta":{"content":"..."}}] }
        # Build JSON payload for the chunk and prefix with "data: "
        chunk_json="$(jq -Rn --arg t "$chunk" '{choices:[{delta:{content:$t}}]}' 2>/dev/null || true)"
        if [ -n "$chunk_json" ]; then
          printf 'data: %s\n\n' "$chunk_json"
        else
          # fallback: escape with @json
          esc="$(printf '%s' "$chunk" | jq -R -s -c '@json' 2>/dev/null || printf '%s' "\"$chunk\"")"
          printf 'data: {"choices":[{"delta":{"content":%s}}]}\n\n' "$esc"
        fi
      fi
    else
      # Non-JSON line: forward as-is (still part of stream)
      printf '%s\n' "$line"
    fi

    printf '%s\n' "$line" >> "$RESP_RAW"
  done

  rc=${PIPESTATUS[0]:-0}
  if [ "$rc" -ne 0 ]; then
    local resp_path="${RESP:-${workdir%/}/resp.json}"
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      gemini_report_error "$RESP_RAW" "$errf"
      if ! jq -e . "${resp_path}" >/dev/null 2>&1; then
        umask 077
        _write_atomic "$RESP_RAW" "${resp_path}" 2>/dev/null || cp -f "$RESP_RAW" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
    else
      printf '%s\n' "gemini: errore durante lo streaming. Vedi curl stderr (head):" >&2
      head -n 50 "$errf" >&2 || true
      umask 077
      jq -n --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{stderr:$stderr}}' > "${resp_path}" 2>/dev/null || printf '{"error":{"stderr":"%s"}}\n' "$(head -n 200 "$errf" 2>/dev/null || true)" > "${resp_path}" 2>/dev/null || true
      chmod 600 "${resp_path}" 2>/dev/null || true
    fi
    return 6
  fi

  local resp_path="${RESP:-$workdir/resp.json}"

  if [ -n "${resp_path:-}" ]; then
    _write_atomic "$RESP_RAW" "${resp_path}"
  fi

  if [ -n "${resp_path:-}" ] && [ -s "${resp_path}" ] && jq -e . "${resp_path}" >/dev/null 2>&1; then
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${resp_path}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      tmpconv="$(_mktemp_in_dir_gemini "$workdir" 2>/dev/null || true)"
      if [ -z "$tmpconv" ]; then
        tmpconv="${workdir%/}/gemini-conv.$$"
        : > "$tmpconv" 2>/dev/null || true
      fi
      umask 077
      jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv"
      _write_atomic "$tmpconv" "${resp_path}" || { cp -f "$tmpconv" "${resp_path}" 2>/dev/null || true; chmod 600 "${resp_path}" 2>/dev/null || true; }
      rm -f "$tmpconv" 2>/dev/null || true
    fi
  fi

  return 0
}

# -------------------------
# refresh_models_gemini
# -------------------------
refresh_models_gemini() {
  local outpath="${1:-${MODELS_FILE:-${MODELSFILE:-}}}"
  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"

  local provider_url_file
  if type canonical_provider_url_file >/dev/null 2>&1; then
    provider_url_file="$(canonical_provider_url_file)"
  else
    provider_url_file="${GROQBASH_CONFIG_DIR:-${GROQBASH_DIR:-./groqbash.d}}/provider-url.gemini"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    if [ -z "$outpath" ]; then
      log_error "MODELREFRESH" "MODELS file path not provided."
      return "$GROQBASHERRTMP"
    fi
    umask 077
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    local tmp_models
    tmp_models="$(_mktemp_in_dir_gemini "$(dirname "$outpath")" 2>/dev/null || true)" || tmp_models="${outpath}.tmp"
    printf '%s\n' "" > "$tmp_models" 2>/dev/null || true
    if type b64_atomic_write >/dev/null 2>&1; then
      if ! b64_atomic_write "${outpath}.b64" 10 < "$tmp_models"; then
        rm -f "$tmp_models" 2>/dev/null || true
        return "$GROQBASHERRTMP"
      fi
      lockfile="${MODELS_LOCK:-${outpath}.lock}"
      lock_exec "$lockfile" 10 -- sh -c '
        set -e
        manifest_b64="$1"
        dest="$2"
        base64 ${B64_DECODE_OPT:-} < "$manifest_b64" > "$dest"
        chmod 600 "$dest" 2>/dev/null || true
      ' _ "${outpath}.b64" "$outpath" || { rm -f "$tmp_models" 2>/dev/null || true; return "$GROQBASHERRTMP"; }
    else
      mv "$tmp_models" "${outpath}.new" 2>/dev/null || cp -f "$tmp_models" "${outpath}.new" 2>/dev/null || true
      chmod 600 "${outpath}.new" 2>/dev/null || true
      mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
    fi
    chmod 600 "$outpath" 2>/dev/null || true
    rm -f "$tmp_models" 2>/dev/null || true

    umask 077
    local provider_url_value
    provider_url_value="$(printf '%s' "${GROQBASH_PROVIDER_URL:-${MODELS_ENDPOINT_GEMINI:-}}" | awk -F/ '{print $1"//"$3}')"
    mkdir -p "$(dirname "$provider_url_file")" 2>/dev/null || true
    local tmp_pu
    tmp_pu="$(_mktemp_in_dir_gemini "$(dirname "$provider_url_file")" 2>/dev/null || true)" || tmp_pu="${provider_url_file}.tmp"
    printf '%s\n' "${provider_url_value}" > "$tmp_pu" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmp_pu" | atomic_write "$provider_url_file"
    else
      mv "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || cp -f "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || true
      chmod 600 "${provider_url_file}.new" 2>/dev/null || true
      mv -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || cp -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || true
    fi
    chmod 600 "$provider_url_file" 2>/dev/null || true
    GROQBASH_PROVIDER_URL="${provider_url_value}"
    return 0
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required to refresh models."
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required to refresh models" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"API key required to refresh models"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$GROQBASHERRNOAPIKEY"
  fi

  local key="${!prov_env:-${GROQBASH_API_KEY:-${GEMINI_API_KEY:-}}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)" || workdir_err="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key not available for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || printf '{"error":"API key not available for provider gemini"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$GROQBASHERRNOAPIKEY"
  fi

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$GROQBASHERRTMP"
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  local workdir tmpd out errf curlout parsed tmpfinal http_code time_total key_trim tmpout lockfile resp_path
  workdir="$(_get_work_tmpdir_gemini)" || workdir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
  [ -n "$workdir" ] || return "$GROQBASHERRTMP"
  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX 2>/dev/null || true)" || return "$GROQBASHERRTMP"

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"
  parsed="$tmpd/parsed_models.txt"
  tmpfinal="$tmpd/final_models.txt"
  resp_path="${RESP:-${workdir%/}/resp.json}"

  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  local api_url="${MODELS_ENDPOINT_GEMINI}"
  case "$api_url" in
    *\?*) api_url="${api_url}&pageSize=${MAX_MODELS:-200}" ;;
    *)    api_url="${api_url}?pageSize=${MAX_MODELS:-200}" ;;
  esac

  rm -f "$out" "$errf" "$curlout" 2>/dev/null || true
  if ! curl "${CURL_BASE_OPTS[@]:-}" -H "Authorization: Bearer ${key_trim}" -H "Content-Type: application/json" --silent --show-error --no-buffer --max-time 120 -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout"; then
    log_error "MODELREFRESH" "HTTP request to Gemini models endpoint failed."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    umask 077
    jq -n --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{stderr:$stderr}}' > "${resp_path}" 2>/dev/null || printf '{"error":{"stderr":"%s"}}\n' "$(head -n 200 "$errf" 2>/dev/null || true)" > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  read -r http_code time_total < "$curlout" 2>/dev/null || http_code="$(cat "$curlout" 2>/dev/null || echo "000")"
  http_code="${http_code:-000}"

  if [ "${http_code:0:1}" != "2" ]; then
    log_error "MODELREFRESH" "models.list HTTP code: $http_code"
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    umask 077
    jq -n --arg code "${http_code:-000}" --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{code:$code,stderr:$stderr}}' > "${resp_path}" 2>/dev/null || printf '{"error":{"code":"%s","stderr":"%s"}}\n' "${http_code:-000}" "$(head -n 200 "$errf" 2>/dev/null || true)" > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  if ! jq -e . "$out" >/dev/null 2>&1; then
    log_error "MODELREFRESH" "Invalid JSON received from Gemini models endpoint."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    umask 077
    jq -n --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{stderr:$stderr}}' > "${resp_path}" 2>/dev/null || printf '{"error":{"stderr":"%s"}}\n' "$(head -n 200 "$errf" 2>/dev/null || true)" > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  jq -r '.models[]?.name // empty' "$out" | awk 'NF{print}' | sort -u > "$parsed" 2>/dev/null || true

  if [ ! -s "$parsed" ]; then
    log_error "MODELREFRESH" "parsed models list empty"
    umask 077
    jq -n --arg msg "parsed models list empty" '{error:$msg}' > "${resp_path}" 2>/dev/null || printf '{"error":"parsed models list empty"}\n' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' "$parsed" > "$tmpfinal" || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
  tmpout="$(_mktemp_in_dir_gemini "$(dirname "$outpath")" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"
  cat "$tmpfinal" > "$tmpout"

  umask 077
  if type b64_atomic_write >/dev/null 2>&1; then
    if ! b64_atomic_write "${outpath}.b64" 10 < "$tmpout"; then
      log_error "MODELREFRESH" "failed to stage models file"
      rm -f "$tmpout" 2>/dev/null || true
      rm -rf "$tmpd"
      return "$GROQBASHERRTMP"
    fi
    lockfile="${MODELS_LOCK:-${outpath}.lock}"
    lock_exec "$lockfile" 10 -- sh -c '
      set -e
      manifest_b64="$1"
      dest="$2"
      base64 ${B64_DECODE_OPT:-} < "$manifest_b64" > "$dest"
      chmod 600 "$dest" 2>/dev/null || true
    ' _ "${outpath}.b64" "$outpath" || { log_error "MODELREFRESH" "failed to write models file under lock"; rm -rf "$tmpd"; return "$GROQBASHERRTMP"; }
  else
    mv "$tmpout" "${outpath}.new" 2>/dev/null || cp -f "$tmpout" "${outpath}.new" 2>/dev/null || true
    chmod 600 "${outpath}.new" 2>/dev/null || true
    mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
  fi

  chmod 600 "$outpath" 2>/dev/null || true

  umask 077
  local provider_url_value
  provider_url_value="$(printf '%s' "${GROQBASH_PROVIDER_URL:-${MODELS_ENDPOINT_GEMINI:-}}" | awk -F/ '{print $1"//"$3}')"
  mkdir -p "$(dirname "$provider_url_file")" 2>/dev/null || true
  local tmp_pu
  tmp_pu="$(_mktemp_in_dir_gemini "$(dirname "$provider_url_file")" 2>/dev/null || true)" || tmp_pu="${provider_url_file}.tmp"
  printf '%s\n' "${provider_url_value}" > "$tmp_pu" 2>/dev/null || true
  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp_pu" | atomic_write "$provider_url_file"
  else
    mv "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || cp -f "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || true
    chmod 600 "${provider_url_file}.new" 2>/dev/null || true
    mv -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || cp -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || true
  fi
  chmod 600 "$provider_url_file" 2>/dev/null || true
  GROQBASH_PROVIDER_URL="${provider_url_value}"

  log_info "MODELREFRESH" "Gemini models refreshed and saved to: $outpath (max ${MAX_MODELS:-200})"

  rm -rf "$tmpd"
  return 0
}

# -------------------------
# validate_model_gemini
# -------------------------
validate_model_gemini() {
  local m="${1:-}"
  [ -n "$m" ] || return 1
  if printf '%s' "$m" | awk 'NF{exit 0} {exit 1}'; then
    return 0
  fi
  return 1
}

# -------------------------
# auto_select_model_gemini
# -------------------------
auto_select_model_gemini() {
  local file="${MODELS_FILE:-${MODELSFILE:-}}"
  local cnt=0 model
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    while IFS= read -r model || [ -n "$model" ]; do
      [ -z "$model" ] && continue
      cnt=$((cnt+1))
      if type is_supported_model >/dev/null 2>&1; then
        if is_supported_model "$model"; then
          printf '%s\n' "$model"
          return 0
        fi
      else
        printf '%s\n' "$model"
        return 0
      fi
      if [ "$cnt" -ge "${MAX_MODELS:-200}" ]; then
        break
      fi
    done < "$file"
  fi
  printf ''
  return 0
}
# End of provider
