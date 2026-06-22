# =============================================================================
# Bash4LLM — Bash-first wrapper for the Groq API
# File: extras/providers/mistral.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/bash4llm
# =============================================================================

# When sourced, avoid enabling strict mode globally.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Provide no-op dbg() if not defined by core
if ! type dbg >/dev/null 2>&1; then
  dbg() { :; }
fi

# -------------------------
# Helpers
# -------------------------
_get_api_key_mistral() {
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local prov_env key=""
  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "mistral")"
    if [ -n "$prov_env" ]; then
      key="${!prov_env:-}"
    fi
  fi
  if [ -z "$key" ]; then
    key="${MISTRAL_API_KEY:-}"
  fi

  [ "$_set_u_was_on" -eq 1 ] && set -u
  printf '%s' "$key"
}

_get_work_tmpdir_mistral() {
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

_mktemp_in_dir_mistral() {
  local dir="$1" tmpf
  [ -n "$dir" ] || return 1
  [ -d "$dir" ] || return 1
  tmpf="$(mktemp "${dir%/}/mistral-XXXXXX" 2>/dev/null || true)"
  [ -n "$tmpf" ] || return 1
  printf '%s' "$tmpf"
  return 0
}

_escape_json_string_mistral() {
  if type escape_json_string >/dev/null 2>&1; then
    escape_json_string "$1"
    return $?
  fi
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

# -------------------------
# buildpayload_mistral
# -------------------------
buildpayload_mistral() {
  local workdir tmp_payload model_in_file model_to_use user_prompt

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return 1
  fi

  workdir="$(_get_work_tmpdir_mistral)" || return 1
  tmp_payload="$(_mktemp_in_dir_mistral "$workdir")" || return 1
  umask 077

  # Quick dependency check
  if ! command -v jq >/dev/null 2>&1; then
    dbg "DEPENDENCY" "jq not found"
    return 1
  fi

  # JSON_INPUT mode
  if [ -n "${JSON_INPUT:-}" ]; then
    if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
      if type atomic_write >/dev/null 2>&1; then
        cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
      else
        cp -f "$JSON_INPUT" "$PAYLOAD" 2>/dev/null || true
        chmod 600 "$PAYLOAD" 2>/dev/null || true
      fi
      return 0
    fi

    if jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
      user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
      model_in_file="$(jq -r '.model // empty' "$JSON_INPUT" 2>/dev/null || true)"
      model_to_use="${model_in_file:-${MODEL:-}}"

      jq -n --arg model "$model_to_use" \
            --argjson stream "$(is_truthy "${STREAM_MODE:-0}" && printf true || printf false)" \
            --arg temp "${TEMP:-1.0}" \
            --arg max_tokens "${MAX_TOKENS:-4096}" \
            --arg user "$user_prompt" \
            '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:[{role:"user",content:$user}] }' \
            > "$tmp_payload"

      if type atomic_write >/dev/null 2>&1; then
        cat "$tmp_payload" | atomic_write "$PAYLOAD"
      else
        cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
        chmod 600 "$PAYLOAD" 2>/dev/null || true
      fi
      return 0
    fi

    if type atomic_write >/dev/null 2>&1; then
      cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
    else
      cp -f "$JSON_INPUT" "$PAYLOAD" 2>/dev/null || true
      chmod 600 "$PAYLOAD" 2>/dev/null || true
    fi
    return 0
  fi

  # Build from variables
  local stream_flag=false model temp max_tokens esc_content esc_system
  is_truthy "${STREAM_MODE:-0}" && stream_flag=true

  model="${MODEL:-}"
  temp="${TEMP:-1.0}"
  max_tokens="${MAX_TOKENS:-4096}"

  esc_content="$(_escape_json_string_mistral "${CONTENT:-}")"
  esc_system="$(_escape_json_string_mistral "${SYSTEM_PROMPT:-}")"

  if [ -n "${SYSTEM_PROMPT:-}" ]; then
    jq -n --arg model "$model" \
          --argjson stream "$stream_flag" \
          --arg temp "$temp" \
          --arg max_tokens "$max_tokens" \
          --arg system "$esc_system" \
          --arg user "$esc_content" \
          '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber),
            messages:[{role:"system",content:$system},{role:"user",content:$user}] }' \
          > "$tmp_payload"
  else
    jq -n --arg model "$model" \
          --argjson stream "$stream_flag" \
          --arg temp "$temp" \
          --arg max_tokens "$max_tokens" \
          --arg user "$esc_content" \
          '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber),
            messages:[{role:"user",content:$user}] }' \
          > "$tmp_payload"
  fi

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp_payload" | atomic_write "$PAYLOAD"
  else
    cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
    chmod 600 "$PAYLOAD" 2>/dev/null || true
  fi
  return 0
}

# -------------------------
# call_api_mistral (non-streaming)
# -------------------------
call_api_mistral() {
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local key
  key="$(_get_api_key_mistral)"

  if [ -z "$key" ]; then
    echo "Error: MISTRAL_API_KEY is not set." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 2
  fi
  if [ ! -s "${PAYLOAD:-}" ]; then
    echo "Error: payload file missing or empty: ${PAYLOAD:-<unset>}" >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 3
  fi
  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 0
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  fi

  local workdir tmpout tmpresp api_url http_code time_total
  workdir="$(_get_work_tmpdir_mistral)" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  tmpout="$(_mktemp_in_dir_mistral "$workdir")" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  tmpresp="$(_mktemp_in_dir_mistral "$workdir")" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  ERRF="${ERRF:-$workdir/curl.err}"
  RESP="${RESP:-$workdir/resp.json}"
  
  # RISOLUZIONE INLINE: Adeguamento al sandboxing di bash4llm
  api_url="${MISTRAL_API_URL:-https://api.mistral.ai/v1/chat/completions}"

  # Costruisce in modo robusto l'array dei comandi per curl per evitare argomenti vuoti ""
  local -a curl_cmd=(curl)
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    -H "Authorization: Bearer $key"
    -H "Content-Type: application/json"
    --data-binary @"$PAYLOAD"
    -o "$tmpresp"
    -w '%{http_code} %{time_total}'
    "$api_url"
  )

  # Esegue la chiamata tramite l'array di comandi
  "${curl_cmd[@]}" 2>"$ERRF" >"$tmpout" || true

  read -r http_code time_total < "$tmpout" 2>/dev/null || {
    http_code="$(cat "$tmpout" 2>/dev/null || echo "000")"
    time_total="0"
  }

  if [ -s "$tmpresp" ]; then
    # Assicura la presenza di un a capo finale per evitare sovrapposizioni del prompt della shell
    local last_char=""
    if command -v tail >/dev/null 2>&1; then
      last_char="$(tail -c 1 "$tmpresp" 2>/dev/null || printf '')"
    else
      last_char="$(awk 'END{printf "%s", substr($0,length($0),1)}' "$tmpresp" 2>/dev/null || printf '')"
    fi
    if [ "$last_char" != $'\n' ]; then
      printf '\n' >> "$tmpresp" 2>/dev/null || true
    fi

    if type atomic_write >/dev/null 2>&1; then
      cat "$tmpresp" | atomic_write "${RESP:-$workdir/resp.json}"
    else
      cp -f "$tmpresp" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
      chmod 600 "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi
  else
    : > "${RESP:-/dev/null}" 2>/dev/null || true
  fi

  rm -f "$tmpresp" "$tmpout" 2>/dev/null || true

  [ "$_set_u_was_on" -eq 1 ] && set -u

  case "$http_code" in
    2*) return 0 ;;
    *)
      dbg "HTTP error code: $http_code"
      dbg "Response (head):"; head -n 200 "${RESP:-/dev/null}" >&2 || true
      dbg "Curl stderr (head):"; head -n 200 "$ERRF" >&2 || true
      return 5
      ;;
  esac
}

# -------------------------
# call_api_streaming_mistral (SSE)
# -------------------------
call_api_streaming_mistral() {
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local key
  key="$(_get_api_key_mistral)"

  if [ -z "$key" ]; then
    echo "Error: MISTRAL_API_KEY is not set." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 2
  fi
  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 0
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  fi

  local api_url rc RESP_RAW workdir
  
  # RISOLUZIONE INLINE: Adeguamento al sandboxing di bash4llm
  api_url="${MISTRAL_API_URL:-https://api.mistral.ai/v1/chat/completions}"
  
  workdir="$(_get_work_tmpdir_mistral)" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  RESP_RAW="${RUN_TMPDIR:-$workdir}/resp.raw"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true
  ERRF="${ERRF:-$workdir/curl.err}"
  RESP="${RESP:-$workdir/resp.json}"

  # Costruisce in modo robusto l'array dei comandi per curl per evitare argomenti vuoti ""
  local -a curl_cmd=(curl)
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    -H "Authorization: Bearer $key"
    -H "Content-Type: application/json"
    --data-binary @"$PAYLOAD"
    "$api_url"
  )

  "${curl_cmd[@]}" 2>"$ERRF" | tee -a "$RESP_RAW" | \
  while IFS= read -r line; do
    case "$line" in
      'data: [DONE]'|'data:[DONE]') break ;;
      data:\ * )
        json="${line#data: }"
        chunk="$(printf '%s' "$json" | jq -r '.choices[]?.delta?.content // empty' 2>/dev/null || true)"
        [ -n "$chunk" ] && printf '%s' "$chunk"
        ;;
      *) ;;
    esac
  done

  rc=${PIPESTATUS[0]:-0}
  [ "$rc" -ne 0 ] && {
    dbg "curl stderr (head):"; head -n 50 "$ERRF" >&2 || true
    [ "$_set_u_was_on" -eq 1 ] && set -u
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
    jq -r 'map(.choices[]?.delta?.content // "") | join("")' "$RUN_TMPDIR/resp.chunks.json" > "$RUN_TMPDIR/resp.text.txt" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$RUN_TMPDIR/resp.chunks.json" | atomic_write "${RESP:-$RUN_TMPDIR/resp.json}" "${BASH4LLM_LOCK_TIMEOUT_TMP:-}" || cp -f "$RUN_TMPDIR/resp.chunks.json" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    else
      cp -f "$RUN_TMPDIR/resp.chunks.json" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    fi

    if [ -n "${RUN_TMPDIR:-}" ] && case "$RUN_TMPDIR" in "${BASH4LLM_TMPDIR:-}"/*) true;; "${BASH4LLM_TMPDIR:-}") true;; *) false;; esac; then
      rm -f "$RUN_TMPDIR/resp.lines" "$RUN_TMPDIR/resp.valid.jsons" 2>/dev/null || true
    fi
  else
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      cp -f "$RESP_RAW" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    fi
  fi

  [ "$_set_u_was_on" -eq 1 ] && set -u

  return 0
}

# -------------------------
# refresh_models_mistral
# -------------------------
refresh_models_mistral() {
  # Temporaneamente disattiva set -u (nounset) per sicurezza durante la lettura delle variabili
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local outpath="${1:-${MODELS_FILE:-}}"
  local key=""
  key="$(_get_api_key_mistral)"

  if [ -z "$key" ]; then
    echo "Error: MISTRAL_API_KEY is required to refresh models." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 2
  fi
  if [ -z "$outpath" ]; then
    echo "Error: MODELS file path not provided." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 7
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  fi

  local workdir tmpd out errf api_url parsed http_code
  workdir="$(_get_work_tmpdir_mistral)" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return 4; }
  tmpd="$(mktemp -d "${workdir}/mistral-models.XXXXXX" 2>/dev/null || true)"

  if [ -z "$tmpd" ] || [ ! -d "$tmpd" ]; then
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 4
  fi

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  
  # RISOLUZIONE INLINE: Adeguamento al sandboxing di bash4llm
  api_url="${MISTRAL_MODELS_URL:-https://api.mistral.ai/v1/models}"

  # Costruisce in modo robusto l'array dei comandi per curl per evitare argomenti vuoti ""
  local -a curl_cmd=(curl -s -w "%{http_code}")
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    -H "Authorization: Bearer $key"
    -H "Content-Type: application/json"
    "$api_url" -o "$out"
  )

  http_code=$("${curl_cmd[@]}" 2>"$errf" || echo "CURL_FAILED")

  if [ "$http_code" = "CURL_FAILED" ] || [ ! -f "$out" ]; then
    dbg "curl stderr:"; head -n 50 "$errf" >&2 || true
    rm -rf "$tmpd" 2>/dev/null || true
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 8
  fi

  if [ "$http_code" != "200" ]; then
    rm -rf "$tmpd" 2>/dev/null || true
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 8
  fi

  parsed="$tmpd/parsed_models.txt"
  jq -r '
    if type == "array" then
      .[]? | (.id // .name // empty)
    elif (has("data") and (.data|type) == "array") then
      .data[]? | (.id // .name // empty)
    else
      empty
    end
  ' "$out" | sort -u > "$parsed" 2>/dev/null || true

  if [ -s "$parsed" ]; then
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$parsed" | atomic_write "$outpath"
    else
      cp -f "$parsed" "$outpath" 2>/dev/null || true
      chmod 600 "$outpath" 2>/dev/null || true
    fi
    chmod 600 "$outpath" 2>/dev/null || true
    rm -rf "$tmpd" 2>/dev/null || true
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 0
  fi

  dbg "Raw response (head):"; head -n 50 "$out" >&2 || true
  rm -rf "$tmpd" 2>/dev/null || true
  [ "$_set_u_was_on" -eq 1 ] && set -u
  return 9
}

# -------------------------
# validate/autoselect
# -------------------------
validate_model_mistral() {
  local model="$1"
  local file="${MODELS_FILE:-}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    grep -x -F -q "$model" "$file" 2>/dev/null
    return $?
  fi
  return 0
}

auto_select_model_mistral() {
  local file="${MODELS_FILE:-}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    awk 'NF{print; exit}' "$file" 2>/dev/null || true
    return 0
  fi
  printf ''
  return 0
}
