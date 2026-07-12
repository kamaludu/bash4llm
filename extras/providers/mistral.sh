#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/providers/mistral.sh
# Extra: Provider Mistral
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
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
      if [ -n "${!prov_env+x}" ]; then
        key="${!prov_env}"
      fi
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
  local dir="$1"
  # Delega la creazione sicura alle funzioni del core se disponibili
  if type _tmpf >/dev/null 2>&1; then
    _tmpf file "$dir" mistral
    return $?
  elif type _mktemp_in_dir >/dev/null 2>&1; then
    _mktemp_in_dir "$dir" mistral
    return $?
  fi

  # Fallback robusto locale
  local tmpf
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
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  workdir="$(_get_work_tmpdir_mistral)" || return "${BASH4LLM_ERR_TMP:-15}"
  tmp_payload="$(_mktemp_in_dir_mistral "$workdir")" || return "${BASH4LLM_ERR_TMP:-15}"
  umask 077

  # Quick dependency check
  if ! command -v jq >/dev/null 2>&1; then
    dbg "DEPENDENCY" "jq not found"
    return "${BASH4LLM_ERR_TMP:-15}"
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
            --arg temp "${TURE:-${TEMPERATURE:-${TEMP:-1.0}}}" \
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

  # CORREZIONE: Integrazione completa della logica della cronologia e del prompt OpenAI-compatible
  local VALID_MESSAGES_JSON=""

  if [ -z "$VALID_MESSAGES_JSON" ] && is_valid_json_string "${MESSAGES_JSON:-}"; then
    VALID_MESSAGES_JSON="${MESSAGES_JSON}"
  fi

  if [ -z "$VALID_MESSAGES_JSON" ] && [ -n "${BUILD_MESSAGES_FILE:-}" ] && is_valid_json_file "${BUILD_MESSAGES_FILE}"; then
    local msgs_from_file
    msgs_from_file="$(jq -c '.messages // []' "$BUILD_MESSAGES_FILE" 2>/dev/null || true)"
    if printf '%s' "$msgs_from_file" | jq -e 'type=="array" and (length>0)' >/dev/null 2>&1; then
      if [ -n "${CONTENT:-}" ]; then
        VALID_MESSAGES_JSON="$(printf '%s' "$msgs_from_file" | jq -c --arg content "$CONTENT" '. + [{role:"user", content:$content}]' 2>/dev/null || printf '%s' "$msgs_from_file")"
      else
        VALID_MESSAGES_JSON="$msgs_from_file"
      fi
    fi
  fi

  if [ -z "$VALID_MESSAGES_JSON" ] && [ -n "${CONTENT:-}" ]; then
    VALID_MESSAGES_JSON="$(jq -c -n --arg content "$CONTENT" '[{role:"user",content:$content}]')"
  fi

  if [ -z "$VALID_MESSAGES_JSON" ]; then
    VALID_MESSAGES_JSON='[{"role":"user","content":""}]'
  fi

  # Inserimento opzionale del system prompt in testa
  if [ -n "${SYSTEM_PROMPT:-}" ]; then
    VALID_MESSAGES_JSON="$(jq -n --argjson messages "$VALID_MESSAGES_JSON" --arg sys "$SYSTEM_PROMPT" '[{role:"system", content:$sys}] + $messages' 2>/dev/null || printf '%s' "$VALID_MESSAGES_JSON")"
  fi

  # Compilazione del payload finale tramite jq (sicuro, senza bisogno di escape manuale Bash)
  local stream_flag=false model temp max_tokens
  is_truthy "${STREAM_MODE:-0}" && stream_flag=true

  model="${MODEL:-}"
  temp="${TURE:-${TEMPERATURE:-${TEMP:-1.0}}}"
  max_tokens="${MAX_TOKENS:-4096}"

  if ! jq -n --arg model "$model" \
       --argjson stream "$stream_flag" \
       --arg temp "$temp" \
       --arg max_tokens "$max_tokens" \
       --argjson messages "$VALID_MESSAGES_JSON" \
       '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:$messages }' \
       > "$tmp_payload" 2>/dev/null; then
    printf 'Error: jq failed to construct the Mistral API payload\n' >&2
    rm -f "$tmp_payload" 2>/dev/null || true
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp_payload" | atomic_write "$PAYLOAD"
  else
    cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
    chmod 600 "$PAYLOAD" 2>/dev/null || true
  fi

  rm -f "$tmp_payload" 2>/dev/null || true
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

  # Gestione ed applicazione della policy di rete globale del core
  if type enforce_network_policy >/dev/null 2>&1; then
    if ! enforce_network_policy; then
      if is_truthy "${DRY_RUN:-0}"; then
        if type show_payload_head >/dev/null 2>&1 && [ "${DEBUG:-0}" -eq 1 ]; then
          show_payload_head "${PAYLOAD:-}" 200 || true
        fi
        dbg "DRY-RUN: skipping HTTP call (exit 0)"
        [ "$_set_u_was_on" -eq 1 ] && set -u
        return 0
      fi
      echo "Error: Network calls disabled by policy." >&2
      [ "$_set_u_was_on" -eq 1 ] && set -u
      return "${BASH4LLM_ERR_CURL_FAILED:-12}"
    fi
  fi

  local key
  key="$(_get_api_key_mistral)"

  if [ -z "$key" ]; then
    echo "Error: MISTRAL_API_KEY is not set." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi
  if [ ! -s "${PAYLOAD:-}" ]; then
    echo "Error: payload file missing or empty: ${PAYLOAD:-<unset>}" >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
  fi

  local workdir tmpout tmpresp api_url http_code time_total
  workdir="$(_get_work_tmpdir_mistral)" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
  tmpout="$(_mktemp_in_dir_mistral "$workdir")" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
  tmpresp="$(_mktemp_in_dir_mistral "$workdir")" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
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
      return "${BASH4LLM_ERR_API:-16}"
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

  # Gestione ed applicazione della policy di rete globale del core in modalità streaming
  if type enforce_network_policy >/dev/null 2>&1; then
    if ! enforce_network_policy; then
      if is_truthy "${DRY_RUN:-0}"; then
        dbg "DRY-RUN: skipping streaming HTTP call (exit 0)"
        [ "$_set_u_was_on" -eq 1 ] && set -u
        return 0
      fi
      echo "Error: Network calls disabled by policy." >&2
      [ "$_set_u_was_on" -eq 1 ] && set -u
      return "${BASH4LLM_ERR_CURL_FAILED:-12}"
    fi
  fi

  local key
  key="$(_get_api_key_mistral)"

  if [ -z "$key" ]; then
    echo "Error: MISTRAL_API_KEY is not set." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
  fi

  local api_url rc RESP_RAW workdir
  
  # RISOLUZIONE INLINE: Adeguamento al sandboxing di bash4llm
  api_url="${MISTRAL_API_URL:-https://api.mistral.ai/v1/chat/completions}"
  
  workdir="$(_get_work_tmpdir_mistral)" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
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
    return "${BASH4LLM_ERR_CURL_FAILED:-12}"
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
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi
  if [ -z "$outpath" ]; then
    echo "Error: MODELS file path not provided." >&2
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
  fi

  local workdir tmpd out errf api_url parsed http_code
  workdir="$(_get_work_tmpdir_mistral)" || { [ "$_set_u_was_on" -eq 1 ] && set -u; return "${BASH4LLM_ERR_TMP:-15}"; }
  tmpd="$(mktemp -d "${workdir}/mistral-models.XXXXXX" 2>/dev/null || true)"

  if [ -z "$tmpd" ] || [ ! -d "$tmpd" ]; then
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_TMP:-15}"
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
    return "${BASH4LLM_ERR_CURL_FAILED:-12}"
  fi

  if [ "$http_code" != "200" ]; then
    rm -rf "$tmpd" 2>/dev/null || true
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_API:-16}"
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
  ' "$out" | awk 'NF{print}' | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' | sort -u > "$parsed" 2>/dev/null || true

  # Sanitizzazione e normalizzazione dei modelli (solo caratteri sicuri)
  local tmp_trim
  tmp_trim="$tmpd/parsed_trimmed.txt"
  awk '{
    g=$0
    sub(/^models\//,"",g)
    sub(/^mistral[:\/-]*/,"",g)
    if (g ~ /^[[:alnum:]._\/:-]+$/) print g
  }' "$parsed" | awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' > "$tmp_trim" 2>/dev/null || true

  if [ -s "$tmp_trim" ]; then
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmp_trim" | atomic_write "$outpath"
    else
      cp -f "$tmp_trim" "$outpath" 2>/dev/null || true
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
  return "${BASH4LLM_ERR_API:-16}"
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

validate_key_mistral() {
  # Temporarily disable set -u if it is currently active
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local key="${1:-}"
  local http_code curl_rc=0
  local tmpout errf workdir

  if [ -z "$key" ]; then
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return 1
  fi

  workdir="$(_get_work_tmpdir_mistral)"
  [ -n "$workdir" ] || workdir="${BASH4LLM_TMPDIR:-/tmp}"

  tmpout="$(_mktemp_in_dir_mistral "$workdir" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${workdir}/mistral-key-diag.tmp"
  errf="${tmpout}.err"

  # Resolve the models API URL matching the provider configuration
  local api_url="${MISTRAL_MODELS_URL:-https://api.mistral.ai/v1/models}"

  # Build the curl command array robustly
  local -a curl_cmd=(curl -s -w "%{http_code}")
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    --max-time 10
    -H "Authorization: Bearer $key"
    -H "Content-Type: application/json"
    "$api_url" -o "$tmpout"
  )

  # Execute the validation check with a rigid 10-second timeout limit
  http_code="$("${curl_cmd[@]}" 2>"$errf" || echo "CURL_ERR")"
  curl_rc=$?

  rm -f "$tmpout" "$errf" 2>/dev/null || true

  # Restore set -u state if it was active
  [ "$_set_u_was_on" -eq 1 ] && set -u

  # Detect specific network timeouts (curl exit code 28) or general failures
  if [ "$http_code" = "CURL_ERR" ] || [ "$curl_rc" -eq 28 ]; then
    return 28
  fi

  # HTTP 200 = Valid token; HTTP 401 = Invalid token
  if [ "$http_code" = "200" ]; then
    return 0
  else
    return 1
  fi
}
