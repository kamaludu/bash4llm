#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/providers/gemini.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# groqbash.d/extras/providers/gemini.sh
# Provider Gemini (Google Generative Language) per GroqBash
# - Uses only models/${MODEL}:generateContent?key=${GEMINI_API_KEY}
# - Converts OpenAI-style messages[] -> Gemini contents/parts
# - Auth via API key in query string only (no Authorization header for API key)
# - Minimal, robust, compatible with GroqBash tmpdir/atomic helpers

# Enable strict mode only when executed directly, not when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Accept either GEMINI_API_KEY or legacy GEMINIAPIKEY
GEMINI_API_KEY="${GEMINI_API_KEY:-${GEMINIAPIKEY:-}}"

# Default endpoints (overridable via env)
# Template: ${MODEL} will be substituted by the code before calling
API_URL_GEMINI_TEMPLATE="${GEMINI_API_URL_TEMPLATE:-https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent}"
MODELS_ENDPOINT_GEMINI="${GEMINI_MODELS_URL:-https://generativelanguage.googleapis.com/v1beta/models}"

# -------------------------
# Helpers (compatible with GroqBash)
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

_escape_json_string_gemini() {
  if type escape_json_string >/dev/null 2>&1; then
    escape_json_string "$1"
    return $?
  fi
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

# Provide a no-op dbg() if not defined
if ! type dbg >/dev/null 2>&1; then
  dbg() { :; }
fi

# -------------------------
# gemini_report_error
# -------------------------
gemini_report_error() {
  local jsonf="${1:-}" errf="${2:-}"
  local status msg code raw
  status="" ; msg="" ; code="" ; raw=""

  if [ -n "$jsonf" ] && [ -s "$jsonf" ] && jq -e . "$jsonf" >/dev/null 2>&1; then
    status="$(jq -r 'if type=="array" then .[0] else . end | (.error?.status // .status // empty) | tostring' "$jsonf" 2>/dev/null || true)"
    code="$(jq -r 'if type=="array" then .[0] else . end | (.error?.code // .error?.status // .code // empty) | tostring' "$jsonf" 2>/dev/null || true)"
    msg="$(jq -r 'if type=="array" then .[0] else . end | (.error?.message // .message // empty) | tostring' "$jsonf" 2>/dev/null || true)"
    if [ -z "$msg" ]; then
      msg="$(jq -r 'if type=="array" then .[0] else . end | (.error?.details[]? // .details[]? // empty) | tostring' "$jsonf" 2>/dev/null | head -n1 || true)"
    fi
  else
    if [ -n "$jsonf" ] && [ -s "$jsonf" ]; then
      raw="$(head -n 200 "$jsonf" 2>/dev/null || true)"
    fi
  fi

  status="$(printf '%s' "$status" | tr '[:lower:]' '[:upper:]')"
  code="$(printf '%s' "$code" | tr '[:lower:]' '[:upper:]')"

  case "$status" in
    INVALID_ARGUMENT)
      printf '%s\n' "gemini: richiesta malformata (INVALID_ARGUMENT). Controlla il payload." >&2
      ;;
    PERMISSION_DENIED)
      printf '%s\n' "gemini: richiesta rifiutata (PERMISSION_DENIED). Verifica che la tua API Key abbia accesso alla Gemini API." >&2
      ;;
    UNAUTHENTICATED)
      printf '%s\n' "gemini: credenziale non valida o scaduta (UNAUTHENTICATED)." >&2
      ;;
    NOT_FOUND)
      printf '%s\n' "gemini: risorsa non trovata (NOT_FOUND). Verifica il modello richiesto." >&2
      ;;
    RESOURCE_EXHAUSTED)
      printf '%s\n' "gemini: limite di risorse raggiunto (RATE LIMIT). Riprova più tardi." >&2
      ;;
    INTERNAL|UNAVAILABLE)
      printf '%s\n' "gemini: errore interno del servizio Google. Riprova più tardi." >&2
      ;;
    "")
      case "$code" in
        PERMISSION_DENIED|API_KEY_INVALID)
          printf '%s\n' "gemini: richiesta rifiutata. Controlla la tua API Key." >&2
          ;;
        UNAUTHENTICATED)
          printf '%s\n' "gemini: credenziale non valida o scaduta." >&2
          ;;
        *)
          if [ -n "$msg" ]; then
            printf '%s\n' "gemini: errore: $msg" >&2
          elif [ -n "$raw" ]; then
            printf '%s\n' "gemini: errore: risposta non JSON. Vedi head della risposta:" >&2
            printf '%s\n' "$raw" >&2
          else
            if [ -n "$errf" ] && [ -s "$errf" ]; then
              printf '%s\n' "gemini: errore HTTP. Vedi curl stderr (head):" >&2
              head -n 50 "$errf" >&2 || true
            else
              printf '%s\n' "gemini: errore sconosciuto durante la richiesta." >&2
            fi
          fi
          ;;
      esac
      ;;
    *)
      if [ -n "$msg" ]; then
        printf '%s\n' "gemini: errore: $msg" >&2
      else
        if [ -n "$errf" ] && [ -s "$errf" ]; then
          printf '%s\n' "gemini: errore HTTP ($status). Vedi curl stderr (head):" >&2
          head -n 50 "$errf" >&2 || true
        else
          printf '%s\n' "gemini: errore HTTP ($status)." >&2
        fi
      fi
      ;;
  esac

  return 0
}

# -------------------------
# buildpayload_gemini
# -------------------------
# Converts OpenAI-style messages[] or other inputs into Gemini contents/parts payload.
# Writes JSON to $PAYLOAD (atomic_write if available).
buildpayload_gemini() {
  local workdir tmp_payload
  workdir="$(_get_work_tmpdir_gemini)" || return 1
  tmp_payload="$(_mktemp_in_dir_gemini "$workdir")" || return 1
  umask 077

  # Helper to write atomically if available, otherwise fallback to safe write
  _write_payload() {
    local src="$1" dst="$2"
    if type atomic_write >/dev/null 2>&1; then
      cat "$src" | atomic_write "$dst"
    else
      cat "$src" > "$dst"
      chmod 600 "$dst" 2>/dev/null || true
    fi
  }

  # If JSON_INPUT provided and already in Gemini format (has "contents"), pass through.
  if [ -n "${JSON_INPUT:-}" ] && [ -s "${JSON_INPUT:-}" ]; then
    if jq -e 'has("contents")' "$JSON_INPUT" >/dev/null 2>&1; then
      _write_payload "$JSON_INPUT" "$PAYLOAD"
      return 0
    fi

    # If JSON_INPUT has messages[], convert them to contents[]
    if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
      jq -c '{
        contents: (.messages | map(
          if type=="object" then
            { role: (.role // "user"), parts: [ { text: (if (.content|type)=="object" then (.content|tostring) else .content end) } ] }
          else
            { role: "user", parts: [ { text: (tostring) } ] }
          end
        ))
      }' "$JSON_INPUT" > "$tmp_payload" 2>/dev/null || true

      _write_payload "$tmp_payload" "$PAYLOAD"
      return 0
    fi

    # If JSON_INPUT has "prompt", convert to contents
    if jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
      local user_prompt
      user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
      jq -n --arg user "$user_prompt" '{contents:[{role:"user",parts:[{text:$user}]}]}' > "$tmp_payload"
      _write_payload "$tmp_payload" "$PAYLOAD"
      return 0
    fi

    # Otherwise pass through raw JSON_INPUT
    _write_payload "$JSON_INPUT" "$PAYLOAD"
    return 0
  fi

  # If CONTENT variable is set (plain text), convert to contents
  if [ -n "${CONTENT:-}" ]; then
    local esc_content
    esc_content="$(_escape_json_string_gemini "${CONTENT:-}")"
    jq -n --arg user "$esc_content" '{contents:[{role:"user",parts:[{text:$user}]}]}' > "$tmp_payload"
    _write_payload "$tmp_payload" "$PAYLOAD"
    return 0
  fi

  # No input: create empty contents (caller should validate)
  jq -n '{contents:[]}' > "$tmp_payload"
  _write_payload "$tmp_payload" "$PAYLOAD"
  return 0
}

# -------------------------
# call_api_gemini
# -------------------------
# Non-streaming call to Gemini generateContent endpoint.
# Expects $PAYLOAD to contain Gemini-style JSON (contents/parts).
call_api_gemini() {
  local key="${GEMINI_API_KEY:-}"
  if [ -z "$key" ]; then
    echo "Error: GEMINI_API_KEY is not set." >&2
    return 2
  fi
  if [ ! -s "${PAYLOAD:-}" ]; then
    echo "Error: payload file missing or empty: ${PAYLOAD:-<unset>}" >&2
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
  errf="$(_mktemp_in_dir_gemini "$workdir")" || return 4

  api_template="${API_URL_GEMINI_TEMPLATE:-$API_URL_GEMINI_TEMPLATE}"
  model_subst="${MODEL:-}"
  if [ -z "$model_subst" ]; then
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    return 7
  fi

  # Build URL and append API key as query parameter
  api_url="$(printf '%s' "$api_template" | sed -e "s/\${MODEL}/$model_subst/g")"
  key_trim="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  case "$api_url" in
    *\?*) api_url="${api_url}&key=${key_trim}" ;;
    *)    api_url="${api_url}?key=${key_trim}" ;;
  esac

  dbg "call_api_gemini: url=${api_url}"

  # Use curl; explicitly clear Authorization header to avoid inherited tokens
  if ! curl ${CURL_BASE_OPTS:-} --silent --show-error --no-buffer --max-time 120 \
       -H "Authorization:" -H "Content-Type: application/json" \
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

  # Save response atomically if possible
  if [ -s "$tmpresp" ]; then
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmpresp" | atomic_write "${RESP:-$workdir/resp.json}" || cp -f "$tmpresp" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    else
      cp -f "$tmpresp" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi
  else
    : > "${RESP:-/dev/null}" 2>/dev/null || true
  fi

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
# call_api_streaming_gemini
# -------------------------
# Streaming call: uses same generateContent endpoint; handles newline-delimited JSON or SSE-like chunks.
call_api_streaming_gemini() {
  local key="${GEMINI_API_KEY:-}"
  if [ -z "$key" ]; then
    echo "Error: GEMINI_API_KEY is not set." >&2
    return 2
  fi
  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    return 0
  fi

  local workdir RESP_RAW api_template api_url model_subst key_trim errf rc
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  RESP_RAW="$(_mktemp_in_dir_gemini "$workdir")" || RESP_RAW="${workdir}/resp.raw"
  errf="$(_mktemp_in_dir_gemini "$workdir")" || errf="${workdir}/curl.err"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  api_template="${API_URL_GEMINI_TEMPLATE:-$API_URL_GEMINI_TEMPLATE}"
  model_subst="${MODEL:-}"
  if [ -z "$model_subst" ]; then
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    return 7
  fi

  api_url="$(printf '%s' "$api_template" | sed -e "s/\${MODEL}/$model_subst/g")"
  key_trim="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  case "$api_url" in
    *\?*) api_url="${api_url}&key=${key_trim}" ;;
    *)    api_url="${api_url}?key=${key_trim}" ;;
  esac

  dbg "call_api_streaming_gemini: url=${api_url}"

  curl ${CURL_BASE_OPTS:-} -H "Authorization:" -H "Content-Type: application/json" --no-buffer --max-time 0 --data-binary @"$PAYLOAD" "$api_url" 2>"$errf" | \
  while IFS= read -r line; do
    case "$line" in
      data:\ * ) line="${line#data: }" ;;
      '' ) continue ;;
    esac
    if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      chunk="$(printf '%s' "$line" | jq -r 'try (if .candidates then (.candidates[]?.content?.parts[]?.text // empty) elif .content then (.content?.parts[]?.text // empty) elif .outputs then (.outputs[]?.content?.parts[]?.text // empty) else empty end) catch empty' 2>/dev/null || true)"
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

  if [ -n "${RESP:-}" ]; then
    if type atomic_write >/dev/null 2>&1; then
      cat "$RESP_RAW" | atomic_write "${RESP}" || cp -f "$RESP_RAW" "${RESP}" 2>/dev/null || true
    else
      cp -f "$RESP_RAW" "${RESP}" 2>/dev/null || true
    fi
  fi

  return 0
}

# -------------------------
# refresh_models_gemini
# -------------------------
# Attempts to fetch models list from MODELS_ENDPOINT_GEMINI.
# If the API key is not authorized for models.list (common), writes a safe static fallback models.txt.
refresh_models_gemini() {
  # Strict, jq-only refresh for Gemini models
  local outpath="${1:-${MODELS_FILE:-${MODELSFILE:-}}}"
  local key="${GEMINI_API_KEY:-}"
  local api_url="${MODELS_ENDPOINT_GEMINI:-https://generativelanguage.googleapis.com/v1beta/models}"
  local max="${MAX_MODELS:-200}"

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$GROQBASHERRTMP"
  fi
  if [ -z "$key" ]; then
    log_error "APIKEY" "GEMINI_API_KEY is required to refresh models."
    return "$GROQBASHERRNOAPIKEY"
  fi

  ensure_run_tmpdir || return "$GROQBASHERRTMP"
  local workdir tmpd out errf curlout parsed tmpfinal http_code time_total key_trim tmpout lockfile
  workdir="$(_get_work_tmpdir_gemini)" || workdir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
  [ -n "$workdir" ] || return "$GROQBASHERRTMP"
  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX)" || return "$GROQBASHERRTMP"

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"
  parsed="$tmpd/parsed_models.txt"
  tmpfinal="$tmpd/final_models.txt"

  key_trim="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  case "$api_url" in
    *\?*) api_url="${api_url}&pageSize=${max}&key=${key_trim}" ;;
    *)    api_url="${api_url}?pageSize=${max}&key=${key_trim}" ;;
  esac

  # Fetch models list (explicitly clear Authorization header)
  rm -f "$out" "$errf" "$curlout" 2>/dev/null || true
  if ! curl ${CURL_BASE_OPTS:-} -H "Authorization:" -H "Content-Type: application/json" --silent --show-error --no-buffer --max-time 120 -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout"; then
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

  # Parse model names using jq (strict)
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

  # Trim to MAX_MODELS defensively
  awk -v M="$max" 'NR<=M{print}' "$parsed" > "$tmpfinal" || true

  # Ensure destination dir exists
  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
  tmpout="$(_mktemp_in_dir "$(dirname "$outpath")" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"
  cat "$tmpfinal" > "$tmpout"

  # Atomic write via base64 staging and lock (project pattern)
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
    base64 ${B64_DECODE_OPT} < "$manifest_b64" > "$dest"
    chmod 600 "$dest" 2>/dev/null || true
  ' _ "${outpath}.b64" "$outpath" || { log_error "MODELREFRESH" "failed to write models file under lock"; rm -rf "$tmpd"; return "$GROQBASHERRTMP"; }

  chmod 600 "$outpath" 2>/dev/null || true
  log_info "MODELREFRESH" "Gemini models refreshed and saved to: $outpath (max ${max})"

  rm -rf "$tmpd"
  return 0
}

# -------------------------
# validate_model_gemini
# -------------------------
validate_model_gemini() {
  # Minimal provider-specific validation.
  return 0
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
