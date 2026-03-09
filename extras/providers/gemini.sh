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

  local workdir tmpout api_url http_code time_total tmpresp
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpout="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  tmpresp="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  api_url="${API_URL_GEMINI}"

  curl ${CURL_BASE_OPTS:-} \
       -H "Authorization: Bearer $key" \
       -H "Content-Type: application/json" \
       --data-binary @"$PAYLOAD" \
       -o "$tmpresp" \
       -w '%{http_code} %{time_total}' \
       "$api_url" \
       2>"$ERRF" >"$tmpout" || true

  read -r http_code time_total < "$tmpout" 2>/dev/null || {
    http_code="$(cat "$tmpout" 2>/dev/null || echo "000")"
    time_total="0"
  }

  cat "$tmpresp" | atomic_write "$RESP"
  rm -f "$tmpresp" "$tmpout" 2>/dev/null || true

  case "$http_code" in
    2*) return 0 ;;
    *)
      dbg "HTTP error code: $http_code"
      dbg "Response (head):"; head -n 200 "$RESP" >&2 || true
      dbg "Curl stderr (head):"; head -n 200 "$ERRF" >&2 || true
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

  local api_url rc RESP_RAW
  api_url="${API_URL_GEMINI}"
  RESP_RAW="${RUN_TMPDIR:-}/resp.raw"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  curl ${CURL_BASE_OPTS:-} \
       -H "Authorization: Bearer $key" \
       -H "Content-Type: application/json" \
       --data-binary @"$PAYLOAD" \
       "$api_url" \
       2>"$ERRF" | tee -a "$RESP_RAW" | \
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

  rc=${PIPESTATUS[0]:-0}
  [ "$rc" -ne 0 ] && {
    dbg "curl stderr (head):"; head -n 50 "$ERRF" >&2 || true
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

  local workdir tmpd out errf api_url parsed tmpout
  workdir="$(_get_work_tmpdir_gemini)" || return 4
  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX 2>/dev/null || true)"
  [ -n "$tmpd" ] || return 4
  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  api_url="${MODELS_ENDPOINT_GEMINI}"

  if ! curl ${CURL_BASE_OPTS:-} \
            -H "Authorization: Bearer $key" \
            -H "Content-Type: application/json" \
            "$api_url" -o "$out" 2>"$errf"; then
    dbg "curl stderr:"; head -n 50 "$errf" >&2 || true
    rm -rf "$tmpd" 2>/dev/null || true
    return 8
  fi

  parsed="$tmpd/parsed_models.txt"
  jq -r '.models[]?.name // empty' "$out" | sort -u > "$parsed" 2>/dev/null || true

  if [ -s "$parsed" ]; then
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    tmpout="$(_mktemp_in_dir_gemini "$(dirname "$outpath")")" || tmpout="$outpath.tmp"
    cat "$parsed" | atomic_write "$outpath"
    rm -rf "$tmpd" 2>/dev/null || true
    return 0
  fi

  dbg "Raw response (head):"; head -n 50 "$out" >&2 || true
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
