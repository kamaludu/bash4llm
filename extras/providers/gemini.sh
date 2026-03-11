#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/providers/gemini.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Enable strict mode only when executed directly, not when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Accept either GEMINI_API_KEY or legacy GEMINIAPIKEY
GEMINI_API_KEY="${GEMINI_API_KEY:-${GEMINIAPIKEY:-}}"

# Endpoints (can be overridden by env)
API_URL_GEMINI="${GEMINI_API_URL:-https://generativelanguage.googleapis.com/v1beta/openai/chat/completions}"
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
# This makes debug calls optional without changing provider logic.
if ! type dbg >/dev/null 2>&1; then
  dbg() { :; }
fi

# Detect credential type: returns "apikey" or "oauth"
detect_gemini_cred_type() {
  local key="${1:-${GEMINI_API_KEY:-}}"
  if [ -z "$key" ]; then
    printf '%s' "none"
    return 0
  fi
  # API keys issued by Google commonly start with "AIza"
  if printf '%s' "$key" | grep -qE '^AIza'; then
    printf '%s' "apikey"
  else
    printf '%s' "oauth"
  fi
  return 0
}

# Report error to stderr based on Gemini error JSON or fallback to curl stderr.
# Usage: gemini_report_error <json_file> <curl_err_file>
gemini_report_error() {
  local jsonf="${1:-}" errf="${2:-}" status msg code raw
  status="" ; msg="" ; code=""

  if [ -n "$jsonf" ] && [ -s "$jsonf" ] && jq -e . "$jsonf" >/dev/null 2>&1; then
    # Try multiple common locations for status/code/message
    status="$(jq -r '.error?.status // .error?.code // .status // empty' "$jsonf" 2>/dev/null || true)"
    code="$(jq -r '.error?.code // .error?.status // empty' "$jsonf" 2>/dev/null || true)"
    msg="$(jq -r '.error?.message // .error?.details // .message // empty' "$jsonf" 2>/dev/null || true)"
  else
    # If JSON not present or invalid, capture raw head for diagnostics
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
      # Try code-based mapping if status empty
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

# Mini-note for users about OAuth tokens (placeholder)
# Per generare un token OAuth o Service Account, consulta la documentazione ufficiale Google.
# Su ambienti come Termux è consigliato usare un Service Account e generare il token tramite script dedicati o da un altro sistema.

# -------------------------
# buildpayload_gemini
# -------------------------
buildpayload_gemini() {
  local workdir tmp_payload model_in_file model_to_use user_prompt
  workdir="$(_get_work_tmpdir_gemini)" || return 1
  tmp_payload="$(_mktemp_in_dir_gemini "$workdir")" || return 1
  umask 077

  # JSON input file
  if [ -n "${JSON_INPUT:-}" ]; then
    if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
      cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
      return 0
    fi

    if jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
      user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
      model_in_file="$(jq -r '.model // empty' "$JSON_INPUT" 2>/dev/null || true)"
      model_to_use="${model_in_file:-${MODEL:-}}"

      jq -n --arg model "$model_to_use" \
            --argjson stream "$(is_truthy "${STREAM_MODE:-0}" && printf true || printf false)" \
            --arg temp "${TEMP:-${TURE:-1.0}}" \
            --arg max_tokens "${MAX_TOKENS:-${MAXTOKENS:-4096}}" \
            --arg user "$user_prompt" \
            '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:[{role:"user",content:$user}] }' \
            > "$tmp_payload"

      cat "$tmp_payload" | atomic_write "$PAYLOAD"
      return 0
    fi

    cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
    return 0
  fi

  # Build payload from variables
  local stream_flag=false model temp max_tokens esc_content esc_system
  is_truthy "${STREAM_MODE:-0}" && stream_flag=true

  model="${MODEL:-}"
  temp="${TEMP:-${TURE:-1.0}}"
  max_tokens="${MAX_TOKENS:-${MAXTOKENS:-4096}}"

  esc_content="$(_escape_json_string_gemini "${CONTENT:-}")"
  esc_system="$(_escape_json_string_gemini "${SYSTEM_PROMPT:-${SYSTEMPROMPT:-}}")"

  if [ -n "${SYSTEM_PROMPT:-${SYSTEMPROMPT:-}}" ]; then
    jq -n --arg model "$model" \
          --argjson stream "$stream_flag" \
          --arg temp "$temp" \
          --arg max_tokens "$max_tokens" \
          --arg system "$esc_system" \
          --arg user "$esc_content" \
          '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:[{role:"system",content:$system},{role:"user",content:$user}] }' \
          > "$tmp_payload"
  else
    jq -n --arg model "$model" \
          --argjson stream "$stream_flag" \
          --arg temp "$temp" \
          --arg max_tokens "$max_tokens" \
          --arg user "$esc_content" \
          '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:[{role:"user",content:$user}] }' \
          > "$tmp_payload"
  fi

  cat "$tmp_payload" | atomic_write "$PAYLOAD"
  return 0
}

# -------------------------
# call_api_gemini
# -------------------------
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

  local workdir tmpout api_url http_code time_total tmpresp cred_type
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpout="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  tmpresp="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  api_url="${API_URL_GEMINI}"

  cred_type="$(detect_gemini_cred_type "$key")"

  if [ "$cred_type" = "apikey" ]; then
    # Use API key as query param (default behavior)
    api_url="${api_url}?key=${key}"
    dbg "call_api_gemini: using API key; url=${api_url}"
    if ! curl ${CURL_BASE_OPTS:-} -H "Content-Type: application/json" --data-binary @"$PAYLOAD" -o "$tmpresp" -w '%{http_code} %{time_total}' "$api_url" 2>"$ERRF" >"$tmpout"; then
      # curl returned non-zero; continue to inspect outputs
      :
    fi
  else
    # Use OAuth/Service Account token in Authorization header
    dbg "call_api_gemini: using OAuth token; url=${api_url}"
    if ! curl ${CURL_BASE_OPTS:-} -H "Authorization: Bearer ${key}" -H "Content-Type: application/json" --data-binary @"$PAYLOAD" -o "$tmpresp" -w '%{http_code} %{time_total}' "$api_url" 2>"$ERRF" >"$tmpout"; then
      :
    fi
  fi

  # Ensure we can read http_code even if curl returned non-zero
  read -r http_code time_total < "$tmpout" 2>/dev/null || {
    http_code="$(cat "$tmpout" 2>/dev/null || echo "000")"
    time_total="0"
  }

  # Verify that tmpresp was written; if not, surface curl stderr for diagnostics
  if [ ! -s "$tmpresp" ]; then
    printf '%s\n' "gemini: attenzione: risposta vuota o file temporaneo non scritto: $tmpresp" >&2
    if [ -s "$ERRF" ]; then
      printf '%s\n' "gemini: curl stderr (head):" >&2
      head -n 80 "$ERRF" >&2 || true
    fi
  fi

  cat "$tmpresp" | atomic_write "$RESP"
  rm -f "$tmpresp" "$tmpout" 2>/dev/null || true

  case "$http_code" in
    2*) return 0 ;;
    *)
      # Provide user-friendly messages based on response JSON or curl stderr
      gemini_report_error "$RESP" "$ERRF"

      # If credential type is oauth and error indicates UNAUTHENTICATED or PERMISSION_DENIED, give specific hint
      if [ "$cred_type" = "oauth" ]; then
        if jq -e '.error?.status == "UNAUTHENTICATED" or .error?.status == "PERMISSION_DENIED"' "$RESP" >/dev/null 2>&1; then
          printf '%s\n' "gemini: il token OAuth/Service Account è scaduto o non valido. Genera un nuovo token." >&2
        fi
      else
        # For API key, if common errors appear, give a clear hint
        if jq -e '.error?.status == "PERMISSION_DENIED" or .error?.status == "UNAUTHENTICATED" or .error?.code == "API_KEY_INVALID"' "$RESP" >/dev/null 2>&1; then
          printf '%s\n' "gemini: la richiesta è stata rifiutata. Verifica che la tua API Key sia valida e abbia accesso alla Gemini API." >&2
        fi
      fi

      # If response file is present but parsing didn't find structured error, also show raw head for debugging
      if [ -s "$RESP" ]; then
        if ! jq -e . "$RESP" >/dev/null 2>&1; then
          printf '%s\n' "gemini: risposta non JSON (head):" >&2
          head -n 80 "$RESP" >&2 || true
        else
          # If JSON but gemini_report_error didn't match, show a short head of the JSON for context
          if ! jq -e '.error' "$RESP" >/dev/null 2>&1; then
            printf '%s\n' "gemini: risposta JSON senza campo error (head):" >&2
            head -n 80 "$RESP" >&2 || true
          fi
        fi
      fi

      return 5
      ;;
  esac
}

# -------------------------
# call_api_streaming_gemini
# -------------------------
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

  local api_url rc RESP_RAW cred_type
  api_url="${API_URL_GEMINI}"
  RESP_RAW="${RUN_TMPDIR:-}/resp.raw"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  cred_type="$(detect_gemini_cred_type "$key")"

  if [ "$cred_type" = "apikey" ]; then
    api_url="${api_url}?key=${key}"
    # Use API key as query param
    curl ${CURL_BASE_OPTS:-} -H "Content-Type: application/json" --data-binary @"$PAYLOAD" "$api_url" 2>"$ERRF" | tee -a "$RESP_RAW" | \
    while IFS= read -r line; do
      case "$line" in
        'data: [DONE]'|'data:[DONE]') break ;;
        data:\ * )
          json="${line#data: }"
          chunk="$(printf '%s' "$json" | jq -r 'try (fromjson | (.choices[]?.delta?.content // .choices[]?.message?.content // empty)) catch empty' 2>/dev/null || true)"
          [ -n "$chunk" ] && printf '%s' "$chunk"
          ;;
        *) printf '%s' "$line" ;;
      esac
    done
  else
    # Use Authorization header for OAuth token
    curl ${CURL_BASE_OPTS:-} -H "Authorization: Bearer ${key}" -H "Content-Type: application/json" --data-binary @"$PAYLOAD" "$api_url" 2>"$ERRF" | tee -a "$RESP_RAW" | \
    while IFS= read -r line; do
      case "$line" in
        'data: [DONE]'|'data:[DONE]') break ;;
        data:\ * )
          json="${line#data: }"
          chunk="$(printf '%s' "$json" | jq -r 'try (fromjson | (.choices[]?.delta?.content // .choices[]?.message?.content // empty)) catch empty' 2>/dev/null || true)"
          [ -n "$chunk" ] && printf '%s' "$chunk"
          ;;
        *) printf '%s' "$line" ;;
      esac
    done
  fi

  rc=${PIPESTATUS[0]:-0}
  [ "$rc" -ne 0 ] && {
    # Report error using curl stderr and any partial JSON in RESP_RAW
    # If RESP_RAW contains JSON error objects, prefer them
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      gemini_report_error "$RESP_RAW" "$ERRF"
    else
      printf '%s\n' "gemini: errore durante lo streaming. Vedi curl stderr (head):" >&2
      head -n 50 "$ERRF" >&2 || true
    fi
    # If oauth token used and error suggests auth problem, print hint
    if [ "$cred_type" = "oauth" ]; then
      if jq -e '.error?.status == "UNAUTHENTICATED" or .error?.status == "PERMISSION_DENIED"' "$RESP_RAW" >/dev/null 2>&1; then
        printf '%s\n' "gemini: il token OAuth/Service Account è scaduto o non valido. Genera un nuovo token." >&2
      fi
    fi
    return 6
  }

  # Post-processing: build resp.chunks.json, resp.text.txt and write RESP atomically
  : > "$RUN_TMPDIR/resp.lines" 2>/dev/null || true
  grep -E '^data:' "$RESP_RAW" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' > "$RUN_TMPDIR/resp.lines" 2>/dev/null || true

  : > "$RUN_TMPDIR/resp.valid.jsons" 2>/dev/null || true
  while IFS= read -r _line; do
    if printf '%s' "$_line" | jq -e . >/dev/null 2>&1; then
      printf '%s\n' "$_line" >> "$RUN_TMPDIR/resp.valid.jsons"
    fi
  done < "$RUN_TMPDIR/resp.lines"

  if [ -s "$RUN_TMPDIR/resp.valid.jsons" ]; then
    jq -s '.' "$RUN_TMPDIR/resp.valid.jsons" > "$RUN_TMPDIR/resp.chunks.json" 2>/dev/null || true
    jq -r 'map(.choices[]?.delta?.content // .choices[]?.message?.content // "") | join("")' "$RUN_TMPDIR/resp.chunks.json" > "$RUN_TMPDIR/resp.text.txt" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$RUN_TMPDIR/resp.chunks.json" | atomic_write "${RESP:-$RUN_TMPDIR/resp.json}" "${GROQBASH_LOCK_TIMEOUT_TMP:-}" || cp -f "$RUN_TMPDIR/resp.chunks.json" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    else
      cp -f "$RUN_TMPDIR/resp.chunks.json" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    fi

    # safe cleanup of intermediates if RUN_TMPDIR is under GROQBASH_TMPDIR
    if [ -n "${RUN_TMPDIR:-}" ] && case "$RUN_TMPDIR" in "${GROQBASH_TMPDIR:-}"/*) true;; "${GROQBASH_TMPDIR:-}") true;; *) false;; esac; then
      rm -f "$RUN_TMPDIR/resp.lines" "$RUN_TMPDIR/resp.valid.jsons" 2>/dev/null || true
    fi
  else
    # fallback: if RESP_RAW is valid JSON, copy to RESP
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      cp -f "$RESP_RAW" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    fi
  fi

  return 0
}

# -------------------------
# refresh_models_gemini
# -------------------------
refresh_models_gemini() {
  local outpath="${1:-${MODELS_FILE:-${MODELSFILE:-}}}"
  local key="${GEMINI_API_KEY:-}"
  if [ -z "$key" ]; then
    echo "Error: GEMINI_API_KEY is required to refresh models." >&2
    return 2
  fi
  if [ -z "$outpath" ]; then
    echo "Error: MODELS file path not provided." >&2
    return 7
  fi

  local workdir tmpd out errf api_url parsed tmpout curlout http_code time_total cred_type
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX 2>/dev/null || true)"
  [ -n "$tmpd" ] || return 4
  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"
  api_url="${MODELS_ENDPOINT_GEMINI}"

  cred_type="$(detect_gemini_cred_type "$key")"

  if [ "$cred_type" = "apikey" ]; then
    api_url="${api_url}?key=${key}"
    # Always capture http_code via -w into curlout
    if ! curl ${CURL_BASE_OPTS:-} -H "Content-Type: application/json" --silent --show-error --no-buffer --max-time 120 -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout"; then
      # curl returned non-zero; still inspect outputs
      :
    fi
    read -r http_code time_total < "$curlout" 2>/dev/null || http_code="$(cat "$curlout" 2>/dev/null || echo "000")"
    if [ -z "$http_code" ]; then http_code="000"; fi
    if [ "${http_code:0:1}" != "2" ]; then
      printf '%s\n' "gemini: models.list HTTP code: $http_code" >&2
      printf '%s\n' "gemini: raw response (head):" >&2
      head -n 200 "$out" >&2 || true
      printf '%s\n' "gemini: curl stderr (head):" >&2
      head -n 200 "$errf" >&2 || true
      gemini_report_error "$out" "$errf"
      rm -rf "$tmpd" 2>/dev/null || true
      return 8
    fi
  else
    # OAuth token path: use Authorization header and capture http_code
    if ! curl ${CURL_BASE_OPTS:-} -H "Authorization: Bearer ${key}" -H "Content-Type: application/json" -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout"; then
      :
    fi
    read -r http_code time_total < "$curlout" 2>/dev/null || http_code="$(cat "$curlout" 2>/dev/null || echo "000")"
    if [ -z "$http_code" ]; then http_code="000"; fi
    if [ "${http_code:0:1}" != "2" ]; then
      printf '%s\n' "gemini: models.list HTTP code: $http_code" >&2
      printf '%s\n' "gemini: raw response (head):" >&2
      head -n 200 "$out" >&2 || true
      printf '%s\n' "gemini: curl stderr (head):" >&2
      head -n 200 "$errf" >&2 || true
      gemini_report_error "$out" "$errf"
      if jq -e '.error?.status == "UNAUTHENTICATED" or .error?.status == "PERMISSION_DENIED"' "$out" >/dev/null 2>&1; then
        printf '%s\n' "gemini: il token OAuth/Service Account è scaduto o non valido. Genera un nuovo token." >&2
      fi
      rm -rf "$tmpd" 2>/dev/null || true
      return 8
    fi
  fi

  parsed="$tmpd/parsed_models.txt"
  jq -r '.models[]?.name // .models[]?.id // empty' "$out" | sort -u > "$parsed" 2>/dev/null || true

  if [ -s "$parsed" ]; then
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$parsed" | atomic_write "$outpath" 10 || { gemini_report_error "$out" "$errf"; rm -rf "$tmpd" 2>/dev/null || true; return 9; }
    else
      cat "$parsed" > "$outpath" || { gemini_report_error "$out" "$errf"; rm -rf "$tmpd" 2>/dev/null || true; return 9; }
    fi
    rm -rf "$tmpd" 2>/dev/null || true
    dbg "Models refreshed and saved to: $outpath"
    return 0
  fi

  # If parsed empty, report raw response for diagnostics
  printf '%s\n' "gemini: parsed models list empty; raw response (head):" >&2
  head -n 200 "$out" >&2 || true
  printf '%s\n' "gemini: curl stderr (head):" >&2
  head -n 200 "$errf" >&2 || true
  gemini_report_error "$out" "$errf"
  rm -rf "$tmpd" 2>/dev/null || true
  return 9
}

validate_model_gemini() {
  local model="$1"
  local file="${MODELS_FILE:-${MODELSFILE:-}}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    grep -x -F -q "$model" "$file" 2>/dev/null
    return $?
  fi
  return 0
}

auto_select_model_gemini() {
  local file="${MODELS_FILE:-${MODELSFILE:-}}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    awk 'NF{print; exit}' "$file" 2>/dev/null || true
    return 0
  fi
  printf ''
  return 0
}
