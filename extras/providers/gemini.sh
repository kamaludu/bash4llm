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

# Hardcoded canonical endpoints (do not allow external templates to inject broken values)
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
# call_api_gemini (non-streaming)
# -------------------------
call_api_gemini() {
  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  # Ensure CORE provides API key (uses core helper if available)
  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required for provider gemini."
    return "$GROQBASHERRNOAPIKEY"
  fi

  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  local key="${!prov_env:-${GROQ_API_KEY:-}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    return "$GROQBASHERRNOAPIKEY"
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    printf 'Error: payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
    return 3
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
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
    return 7
  fi

  api_url="$(_substitute_model_in_template "$api_template" "$model_subst")"

  # Trim key
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  dbg "call_api_gemini: url=${api_url}"

  # Use header-based auth to avoid leaking key in URLs
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

  # Ensure RESP/ERRF are set under workdir/RUN_TMPDIR
  RESP="${RESP:-$workdir/resp.json}"
  ERRF="${ERRF:-$errf}"

  # Save response atomically if possible
  if [ -s "$tmpresp" ]; then
    if [ -n "${RESP:-}" ]; then
      _write_atomic "$tmpresp" "${RESP}"
    else
      cp -f "$tmpresp" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
      chmod 600 "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi
  else
    : > "${RESP:-/dev/null}" 2>/dev/null || true
  fi

  # --- BEGIN: Gemini -> OpenAI-like response compatibility shim ---
  # Convert Gemini response to OpenAI-like JSON so CORE can extract textual content.
  if [ -n "${RESP:-}" ] && [ -s "${RESP}" ] && jq -e . "${RESP}" >/dev/null 2>&1; then
    # Extract first non-empty textual part from common Gemini response locations.
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${RESP}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      # Use workdir for temporary conversion file; never write to /tmp
      tmpconv="$(_mktemp_in_dir_gemini "$workdir" 2>/dev/null || true)"
      if [ -z "$tmpconv" ]; then
        tmpconv="${workdir%/}/gemini-conv.$$"
        : > "$tmpconv" 2>/dev/null || true
      fi
      umask 077
      jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv"
      # Atomically replace RESP with the converted OpenAI-like JSON
      _write_atomic "$tmpconv" "${RESP}" || { cp -f "$tmpconv" "${RESP}" 2>/dev/null || true; chmod 600 "${RESP}" 2>/dev/null || true; }
      rm -f "$tmpconv" 2>/dev/null || true
    fi
  fi
  # --- END: Gemini -> OpenAI-like response compatibility shim ---

  case "$http_code" in
    2*)
      rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true
      return 0
      ;;
    *)
      gemini_report_error "$tmpresp" "$errf"
      rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true
      return 5
      ;;
  esac
}

# -------------------------
# call_api_streaming_gemini (streaming)
# -------------------------
call_api_streaming_gemini() {
  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  # Ensure CORE provides API key
  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required for provider gemini."
    return "$GROQBASHERRNOAPIKEY"
  fi
  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  local key="${!prov_env:-${GROQ_API_KEY:-}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    return "$GROQBASHERRNOAPIKEY"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
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
    return 7
  fi

  api_url="$(_substitute_model_in_template "$api_template" "$model_subst")"
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  dbg "call_api_streaming_gemini: url=${api_url}"

  # Use header-based auth and array-safe curl expansion
  curl "${CURL_BASE_OPTS[@]:-}" -H "Authorization: Bearer ${key_trim}" -H "Content-Type: application/json" --no-buffer --max-time 0 --data-binary @"$PAYLOAD" "$api_url" 2>"$errf" | \
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      data:\ * ) line="${line#data: }" ;;
      '' ) continue ;;
    esac

    if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      chunk="$(printf '%s' "$line" | jq -r 'try (if .candidates then (.candidates[]?.content?.parts[]?.text // empty) elif .content then (.content?.parts[]?.text // empty) elif .outputs then (.outputs[]?.content?.parts[]?.text // empty) else empty end) catch empty' 2>>"$errf" || true)"
      if [ -n "$chunk" ]; then
        printf '%s' "$chunk"
      fi
    else
      printf '%s\n' "$line"
    fi

    printf '%s\n' "$line" >> "$RESP_RAW"
  done

  rc=${PIPESTATUS[0]:-0}
  if [ "$rc" -ne 0 ]; then
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      gemini_report_error "$RESP_RAW" "$errf"
    else
      printf '%s\n' "gemini: errore durante lo streaming. Vedi curl stderr (head):" >&2
      head -n 50 "$errf" >&2 || true
    fi
    return 6
  fi

  # Ensure RESP path
  RESP="${RESP:-$workdir/resp.json}"

  if [ -n "${RESP:-}" ]; then
    _write_atomic "$RESP_RAW" "${RESP}"
  fi

  # --- BEGIN: Gemini -> OpenAI-like response compatibility shim (streaming) ---
  if [ -n "${RESP:-}" ] && [ -s "${RESP}" ] && jq -e . "${RESP}" >/dev/null 2>&1; then
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${RESP}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      tmpconv="$(_mktemp_in_dir_gemini "$workdir" 2>/dev/null || true)"
      if [ -z "$tmpconv" ]; then
        tmpconv="${workdir%/}/gemini-conv.$$"
        : > "$tmpconv" 2>/dev/null || true
      fi
      umask 077
      jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv"
      _write_atomic "$tmpconv" "${RESP}" || { cp -f "$tmpconv" "${RESP}" 2>/dev/null || true; chmod 600 "${RESP}" 2>/dev/null || true; }
      rm -f "$tmpconv" 2>/dev/null || true
    fi
  fi
  # --- END: Gemini -> OpenAI-like response compatibility shim (streaming) ---

  return 0
}

# -------------------------
# refresh_models_gemini
# -------------------------
refresh_models_gemini() {
  local outpath="${1:-${MODELS_FILE:-${MODELSFILE:-}}}"
  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "GROQ_API_KEY required to refresh models."
    return "$GROQBASHERRNOAPIKEY"
  fi
  local key="${!prov_env:-${GROQ_API_KEY:-}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    return "$GROQBASHERRNOAPIKEY"
  fi

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$GROQBASHERRTMP"
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  local workdir tmpd out errf curlout parsed tmpfinal http_code time_total key_trim tmpout lockfile
  workdir="$(_get_work_tmpdir_gemini)" || workdir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
  [ -n "$workdir" ] || return "$GROQBASHERRTMP"
  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX 2>/dev/null || true)" || return "$GROQBASHERRTMP"

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"
  parsed="$tmpd/parsed_models.txt"
  tmpfinal="$tmpd/final_models.txt"

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
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  read -r http_code time_total < "$curlout" 2>/dev/null || http_code="$(cat "$curlout" 2>/dev/null || echo "000")"
  http_code="${http_code:-000}"

  if [ "${http_code:0:1}" != "2" ]; then
    log_error "MODELREFRESH" "models.list HTTP code: $http_code"
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  if ! jq -e . "$out" >/dev/null 2>&1; then
    log_error "MODELREFRESH" "Invalid JSON received from Gemini models endpoint."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  jq -r '.models[]?.name // empty' "$out" | awk 'NF{print}' | sort -u > "$parsed" 2>/dev/null || true

  if [ ! -s "$parsed" ]; then
    log_error "MODELREFRESH" "parsed models list empty"
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' "$parsed" > "$tmpfinal" || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
  tmpout="$(_mktemp_in_dir_gemini "$(dirname "$outpath")" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"
  cat "$tmpfinal" > "$tmpout"

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
  # Disallow whitespace-only names
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
