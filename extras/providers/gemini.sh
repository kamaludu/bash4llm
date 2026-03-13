#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/providers/gemini.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# gemini.sh - GroqBash provider for Google Gemini (generateContent)
# - Uses only models/<model>:generateContent?key=...
# - Converts OpenAI-style messages[] -> Gemini contents/parts
# - Auth via API key in query string only by default
# - Compatible with GroqBash tmpdir/atomic helpers
# - No use of /v1beta/openai/chat/completions

# Enable strict mode only when executed directly, not when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Accept either GEMINI_API_KEY or legacy GEMINIAPIKEY
GEMINI_API_KEY="${GEMINI_API_KEY:-${GEMINIAPIKEY:-}}"

# Default endpoints (overridable via env)
# API_URL_GEMINI is a template; call functions will substitute ${MODEL} if present.
API_URL_GEMINI_TEMPLATE="${GEMINI_API_URL_TEMPLATE:-https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent}"
MODELS_ENDPOINT_GEMINI="${GEMINI_MODELS_URL:-https://generativelanguage.googleapis.com/v1beta/models}"

# -------------------------
# Helpers
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

# Provide a no-op dbg() if not defined to avoid "command not found" errors.
if ! type dbg >/dev/null 2>&1; then
  dbg() { :; }
fi

# Detect credential type: returns "apikey", "oauth", or "none"
# Default behavior: if key looks like API key (starts with AIza or contains "AIza"), treat as apikey.
# If it looks like an OAuth access token (starts with "ya29."), treat as oauth.
# This only affects optional OAuth branch; API key flow is primary and default.
detect_gemini_cred_type() {
  local key="${1:-${GEMINI_API_KEY:-}}"
  key="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -z "$key" ]; then
    printf '%s' "none"
    return 0
  fi
  case "$key" in
    AIza*|AIza*) printf '%s' "apikey" ;;
    ya29.*)      printf '%s' "oauth" ;;
    *)          printf '%s' "apikey" ;; # default to apikey to avoid forcing oauth
  esac
  return 0
}

# Report error to stderr based on Gemini error JSON or fallback to curl stderr.
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
  local workdir tmp_payload model_in_file model_to_use user_prompt
  workdir="$(_get_work_tmpdir_gemini)" || return 1
  tmp_payload="$(_mktemp_in_dir_gemini "$workdir")" || return 1
  umask 077

  # If JSON_INPUT provided and already in Gemini format (has "contents"), pass through.
  if [ -n "${JSON_INPUT:-}" ] && [ -s "${JSON_INPUT:-}" ]; then
    if jq -e 'has("contents")' "$JSON_INPUT" >/dev/null 2>&1; then
      cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
      return 0
    fi
    # If JSON_INPUT has messages[], convert them
    if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
      # Build contents array from messages
      jq -r '{
        contents: (.messages | map(
          if type=="object" then
            { role: (.role // "user"), parts: [ { text: (if (.content|type)=="object" then (.content|tostring) else .content end) } ] }
          else
            { role: "user", parts: [ { text: (tostring) } ] }
          end
        ))
      }' "$JSON_INPUT" > "$tmp_payload" 2>/dev/null || true

      cat "$tmp_payload" | atomic_write "$PAYLOAD"
      return 0
    fi
    # If JSON_INPUT has "prompt", convert to contents
    if jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
      user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
      jq -n --arg user "$user_prompt" '{contents:[{role:"user",parts:[{text:$user}]}]}' > "$tmp_payload"
      cat "$tmp_payload" | atomic_write "$PAYLOAD"
      return 0
    fi
    # Otherwise pass through raw JSON_INPUT
    cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
    return 0
  fi

  # If CONTENT variable is set (plain text), convert to contents
  if [ -n "${CONTENT:-}" ]; then
    local esc_content
    esc_content="$(_escape_json_string_gemini "${CONTENT:-}")"
    jq -n --arg user "$esc_content" '{contents:[{role:"user",parts:[{text:$user}]}]}' > "$tmp_payload"
    cat "$tmp_payload" | atomic_write "$PAYLOAD"
    return 0
  fi

  # If no input, create an empty contents payload (caller should validate)
  jq -n '{contents:[]}' > "$tmp_payload"
  cat "$tmp_payload" | atomic_write "$PAYLOAD"
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

  local workdir tmpout api_url http_code time_total tmpresp errf key_trim api_template model_subst
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpout="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  tmpresp="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  errf="$(_mktemp_in_dir_gemini "$workdir")" || return 4

  api_template="${API_URL_GEMINI_TEMPLATE:-$API_URL_GEMINI_TEMPLATE}"
  model_subst="${MODEL:-}"
  if [ -z "$model_subst" ]; then
    # If no MODEL provided, try default or fail
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    return 7
  fi

  # Build final URL by substituting ${MODEL} in template and appending ?key=
  api_url="$(printf '%s' "$api_template" | sed -e "s/\${MODEL}/$model_subst/g")"
  key_trim="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  # Append key as query parameter
  case "$api_url" in
    *\?*) api_url="${api_url}&key=${key_trim}" ;;
    *)    api_url="${api_url}?key=${key_trim}" ;;
  esac

  dbg "call_api_gemini: url=${api_url}"

  # Perform request; ensure Content-Type JSON; explicitly clear Authorization header to avoid inherited tokens
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

  # Handle HTTP codes
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

  # Use curl to stream; write to RESP_RAW; parse lines that are JSON
  curl ${CURL_BASE_OPTS:-} -H "Authorization:" -H "Content-Type: application/json" --no-buffer --max-time 0 --data-binary @"$PAYLOAD" "$api_url" 2>"$errf" | \
  while IFS= read -r line; do
    # Many Gemini streaming responses are newline-delimited JSON or SSE-like "data: {...}"
    case "$line" in
      data:\ * ) line="${line#data: }" ;;
      '' ) continue ;;
    esac
    # If line is valid JSON, try to extract text parts
    if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      # Try common shapes: content.parts[].text or candidates[].content.parts[].text
      chunk="$(printf '%s' "$line" | jq -r 'try (if .candidates then (.candidates[]?.content?.parts[]?.text // empty) elif .content then (.content?.parts[]?.text // empty) elif .outputs then (.outputs[]?.content?.parts[]?.text // empty) else empty end) catch empty' 2>/dev/null || true)"
      if [ -n "$chunk" ]; then
        printf '%s' "$chunk"
      fi
    else
      # Not JSON: print raw
      printf '%s\n' "$line"
    fi
    # append raw to RESP_RAW for diagnostics
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

  # Save RESP_RAW to RESP if requested
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
# Fetches models list from MODELS_ENDPOINT_GEMINI and writes MODELS_FILE.
# Uses API key in query string; does not use OpenAI-compatible endpoints.
refresh_models_gemini() {
  local outpath="${1:-${MODELS_FILE:-${MODELSFILE:-}}}"
  local key="${GEMINI_API_KEY:-}"
  if [ -z "$outpath" ]; then
    printf '%s\n' "Error: MODELS file path not provided." >&2
    return 7
  fi
  if [ -z "$key" ]; then
    printf '%s\n' "Error: GEMINI_API_KEY is required to refresh models." >&2
    return 2
  fi

  local workdir tmpd out errf curlout parsed tmpfinal http_code time_total api_url key_trim
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX 2>/dev/null || true)"
  [ -n "$tmpd" ] || return 4

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"
  parsed="$tmpd/parsed_models.txt"
  tmpfinal="$tmpd/final_models.txt"

  api_url="${MODELS_ENDPOINT_GEMINI:-}"
  key_trim="$(printf '%s' "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  case "$api_url" in
    *\?*) api_url="${api_url}&pageSize=${MAX_MODELS:-200}" ;;
    *) api_url="${api_url}?pageSize=${MAX_MODELS:-200}" ;;
  esac

  # Use API key in query string; explicitly clear Authorization header
  curl ${CURL_BASE_OPTS:-} -H "Authorization:" -H "Content-Type: application/json" --silent --show-error --no-buffer --max-time 120 -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout" || true

  read -r http_code time_total < "$curlout" 2>/dev/null || http_code="$(cat "$curlout" 2>/dev/null || echo "000")"
  http_code="${http_code:-000}"
  if [ "${http_code:0:1}" != "2" ]; then
    printf '%s\n' "gemini: models.list HTTP code: $http_code" >&2
    head -n 200 "$out" >&2 || true
    head -n 200 "$errf" >&2 || true
    gemini_report_error "$out" "$errf"
    rm -rf "$tmpd" 2>/dev/null || true
    return 8
  fi

  if jq -e . "$out" >/dev/null 2>&1; then
    jq -r '.models[]?.name // .models[]?.id // empty' "$out" > "$parsed" 2>/dev/null || true
  else
    grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' "$out" 2>/dev/null | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' > "$parsed" 2>/dev/null || true
    if [ ! -s "$parsed" ]; then
      grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' "$out" 2>/dev/null | sed -E 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' > "$parsed" 2>/dev/null || true
    fi
  fi

  if [ ! -s "$parsed" ]; then
    printf '%s\n' "gemini: parsed models list empty; raw response (head):" >&2
    head -n 200 "$out" >&2 || true
    head -n 200 "$errf" >&2 || true
    gemini_report_error "$out" "$errf"
    rm -rf "$tmpd" 2>/dev/null || true
    return 9
  fi

  awk '!seen[$0]++{print}' "$parsed" | head -n "${MAX_MODELS:-200}" > "$tmpfinal" 2>/dev/null || true
  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true

  # Write final models file atomically
  if type atomic_write >/dev/null 2>&1; then
    cat "$tmpfinal" | atomic_write "$outpath" || cp -f "$tmpfinal" "$outpath" 2>/dev/null || true
  else
    cp -f "$tmpfinal" "$outpath" 2>/dev/null || true
  fi
  chmod 600 "$outpath" 2>/dev/null || true

  rm -rf "$tmpd" 2>/dev/null || true
  dbg "Models refreshed and saved to: $outpath (max ${MAX_MODELS:-200})"
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
