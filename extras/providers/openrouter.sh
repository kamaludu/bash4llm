#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/providers/openrouter.sh
# Authority: Architecture Specification (Edition 2026.1)
# Extra: Provider OpenRouter Module (T3 Hardened & Whitelist Compliant)
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Purpose: Bash4LLM provider adapter for OpenRouter APIs (including free models)
# Invariants: Zero unwhitelisted private helpers, strict argv secret isolation.

# Sourcing guard: prevent strict shell flags pollution when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Declare Provider API Version Contract
BASH4LLM_PROVIDER_API_VERSION=1

# -----------------------------------------------------------------------------
# 1. buildpayload_openrouter
# Compiles OpenAI-compatible chat completion payload for OpenRouter endpoints
# -----------------------------------------------------------------------------
buildpayload_openrouter() {
  local workdir tmp_payload user_prompt model_in_file model_to_use

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    tmp_payload="$(_tmpf file "$workdir" openrouter 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  else
    tmp_payload="$(mktemp "${workdir%/}/openrouter.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  fi
  chmod 600 "$tmp_payload" 2>/dev/null || true

  # 1. Polymorphic JSON_INPUT handling (supports both raw string and file path)
  if [ -n "${JSON_INPUT:-}" ]; then
    local raw_json=""
    if [ -f "${JSON_INPUT}" ]; then
      raw_json="$(cat "${JSON_INPUT}" 2>/dev/null || true)"
    else
      raw_json="${JSON_INPUT}"
    fi

    if printf '%s' "$raw_json" | jq -e . >/dev/null 2>&1; then
      if printf '%s' "$raw_json" | jq -e 'has("messages")' >/dev/null 2>&1; then
        printf '%s' "$raw_json" > "$tmp_payload"
        if type atomic_write >/dev/null 2>&1; then
          atomic_write "${PAYLOAD:-$workdir/payload.json}" 10 < "$tmp_payload"
        else
          cp -f "$tmp_payload" "${PAYLOAD:-$workdir/payload.json}" 2>/dev/null || true
          chmod 600 "${PAYLOAD:-$workdir/payload.json}" 2>/dev/null || true
        fi
        rm -f "$tmp_payload" 2>/dev/null || true
        return 0
      elif printf '%s' "$raw_json" | jq -e 'has("prompt")' >/dev/null 2>&1; then
        user_prompt="$(printf '%s' "$raw_json" | jq -r '.prompt' 2>/dev/null || true)"
        model_in_file="$(printf '%s' "$raw_json" | jq -r '.model // empty' 2>/dev/null || true)"
        model_to_use="${model_in_file:-${MODEL:-openrouter/free}}"

        jq -n --arg model "$model_to_use" \
              --argjson stream "$(is_truthy "${STREAM_MODE:-0}" && printf true || printf false)" \
              --arg temp "${TEMPERATURE:-${TURE:-1.0}}" \
              --arg max_tokens "${MAX_TOKENS:-4096}" \
              --arg user "$user_prompt" \
              '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:[{role:"user",content:$user}] }' \
              > "$tmp_payload" 2>/dev/null || true

        if type atomic_write >/dev/null 2>&1; then
          atomic_write "${PAYLOAD:-$workdir/payload.json}" 10 < "$tmp_payload"
        else
          cp -f "$tmp_payload" "${PAYLOAD:-$workdir/payload.json}" 2>/dev/null || true
          chmod 600 "${PAYLOAD:-$workdir/payload.json}" 2>/dev/null || true
        fi
        rm -f "$tmp_payload" 2>/dev/null || true
        return 0
      fi
    fi
  fi

  # 2. Conversation messages compilation
  local VALID_MESSAGES_JSON="" msgs_from_file

  if [ -z "$VALID_MESSAGES_JSON" ] && [ -n "${MESSAGES_JSON:-}" ]; then
    if [ -f "${MESSAGES_JSON}" ]; then
      VALID_MESSAGES_JSON="$(cat "${MESSAGES_JSON}" 2>/dev/null || true)"
    else
      VALID_MESSAGES_JSON="${MESSAGES_JSON}"
    fi
  fi

  if [ -z "$VALID_MESSAGES_JSON" ] && [ -n "${BUILD_MESSAGES_FILE:-}" ] && [ -f "${BUILD_MESSAGES_FILE}" ]; then
    msgs_from_file="$(jq -c '.messages // []' "${BUILD_MESSAGES_FILE}" 2>/dev/null || true)"
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

  # 3. System prompt injection
  if [ -n "${SYSTEM_PROMPT:-}" ]; then
    VALID_MESSAGES_JSON="$(jq -n --argjson messages "$VALID_MESSAGES_JSON" --arg sys "${SYSTEM_PROMPT:-}" '[{role:"system", content:$sys}] + $messages' 2>/dev/null || printf '%s' "$VALID_MESSAGES_JSON")"
  fi

  # 4. Final compilation to JSON
  local stream_flag=false model_val temp_val max_tokens_val
  is_truthy "${STREAM_MODE:-0}" && stream_flag=true
  model_val="${MODEL:-openrouter/free}"
  temp_val="${TEMPERATURE:-${TURE:-1.0}}"
  max_tokens_val="${MAX_TOKENS:-4096}"

  if ! jq -n --arg model "$model_val" \
       --argjson stream "$stream_flag" \
       --arg temp "$temp_val" \
       --arg max_tokens "$max_tokens_val" \
       --argjson messages "$VALID_MESSAGES_JSON" \
       '{model:$model, stream:$stream, temperature:($temp|tonumber), max_tokens:($max_tokens|tonumber), messages:$messages }' \
       > "$tmp_payload" 2>/dev/null; then
    printf 'openrouter: ERROR: jq failed to construct the OpenRouter API payload\n' >&2
    rm -f "$tmp_payload" 2>/dev/null || true
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type atomic_write >/dev/null 2>&1; then
    atomic_write "${PAYLOAD:-$workdir/payload.json}" 10 < "$tmp_payload"
  else
    cp -f "$tmp_payload" "${PAYLOAD:-$workdir/payload.json}" 2>/dev/null || true
    chmod 600 "${PAYLOAD:-$workdir/payload.json}" 2>/dev/null || true
  fi

  rm -f "$tmp_payload" 2>/dev/null || true
  return 0
}

# -----------------------------------------------------------------------------
# 2. call_api_openrouter (Synchronous HTTP call)
# -----------------------------------------------------------------------------
call_api_openrouter() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if ! ensure_api_key_for_provider "openrouter"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key required for provider openrouter."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  local prov_env key=""
  prov_env="$(provider_api_env_var_name "openrouter")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    key="${!prov_env}"
  fi
  : "${key:=${OPENROUTER_API_KEY:-${BASH4LLM_API_KEY:-}}}"

  if [ -z "$key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "OPENROUTER_API_KEY is not set."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    printf 'openrouter: ERROR: Payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    local workdir_dr="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
    local resp_path="${RESP:-${workdir_dr%/}/resp.json}"
    umask 077
    jq -n '{choices:[]}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 0
  fi

  local workdir tmpout tmpresp api_url http_code send_payload decoded_payload resp_path errf_path
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" openrouter-out 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    tmpresp="$(_tmpf file "$workdir" openrouter-resp 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  else
    tmpout="$(mktemp "${workdir%/}/openrouter-out.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    tmpresp="$(mktemp "${workdir%/}/openrouter-resp.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  errf_path="${ERRF:-$workdir/curl.err}"
  resp_path="${RESP:-$workdir/resp.json}"
  api_url="${OPENROUTER_API_URL:-${BASH4LLM_PROVIDER_URL:-https://openrouter.ai/api/v1/chat/completions}}"

  send_payload="$PAYLOAD"
  decoded_payload=""
  if [[ "${PAYLOAD:-}" == *.b64 ]]; then
    if type _tmpf >/dev/null 2>&1; then
      decoded_payload="$(_tmpf file "$workdir" openrouter-dec 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    else
      decoded_payload="$(mktemp "${workdir%/}/openrouter-dec.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    fi

    if ! b64decode < "$PAYLOAD" > "$decoded_payload" 2>/dev/null; then
      rm -f "$tmpout" "$tmpresp" "$decoded_payload" 2>/dev/null || true
      return "${BASH4LLM_ERR_TMP:-15}"
    fi
    send_payload="$decoded_payload"
  fi

  # Pass OpenRouter app attribution headers safely via additional options vector
  local -a extra_opts=(-w '%{http_code}' -H 'HTTP-Referer: https://github.com/kamaludu/bash4llm' -H 'X-Title: Bash4LLM+')
  http_code="$(_exec_curl_secure "POST" "$api_url" "$key" "$send_payload" "$tmpresp" "$errf_path" 0 "${extra_opts[@]}" || echo "000")"

  rm -f "$decoded_payload" 2>/dev/null || true

  if [ -s "$tmpresp" ]; then
    if type atomic_write >/dev/null 2>&1; then
      atomic_write "${resp_path}" 10 < "$tmpresp"
    else
      cp -f "$tmpresp" "${resp_path}" 2>/dev/null || true
      chmod 600 "${resp_path}" 2>/dev/null || true
    fi
  else
    : > "${resp_path}" 2>/dev/null || true
  fi

  rm -f "$tmpresp" "$tmpout" 2>/dev/null || true

  case "$http_code" in
    2*) return 0 ;;
    *)
      if type log_error >/dev/null 2>&1; then
        log_error "API" "OpenRouter API HTTP Error status: $http_code"
      fi
      return "${BASH4LLM_ERR_API:-16}"
      ;;
  esac
}

# -----------------------------------------------------------------------------
# 3. call_api_streaming_openrouter (SSE Streaming with JSON Error Fallback)
# -----------------------------------------------------------------------------
call_api_streaming_openrouter() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if ! ensure_api_key_for_provider "openrouter"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key required for provider openrouter."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  local prov_env key=""
  prov_env="$(provider_api_env_var_name "openrouter")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    key="${!prov_env}"
  fi
  : "${key:=${OPENROUTER_API_KEY:-${BASH4LLM_API_KEY:-}}}"

  if [ -z "$key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "OPENROUTER_API_KEY is not set."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    return 0
  fi

  local api_url rc RESP_RAW workdir resp_path errf_path clean_chunks unified_text synthetic_resp send_payload decoded_payload
  api_url="${OPENROUTER_API_URL:-${BASH4LLM_PROVIDER_URL:-https://openrouter.ai/api/v1/chat/completions}}"

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    RESP_RAW="$(_tmpf file "$workdir" openrouter-raw 2>/dev/null)" || RESP_RAW="${workdir%/}/resp.raw"
  else
    RESP_RAW="$(mktemp "${workdir%/}/openrouter-raw.XXXXXX" 2>/dev/null)" || RESP_RAW="${workdir%/}/resp.raw"
  fi
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  errf_path="${ERRF:-$workdir/curl.err}"
  resp_path="${RESP:-$workdir/resp.json}"

  send_payload="$PAYLOAD"
  decoded_payload=""
  if [[ "${PAYLOAD:-}" == *.b64 ]]; then
    if type _tmpf >/dev/null 2>&1; then
      decoded_payload="$(_tmpf file "$workdir" openrouter-dec 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    else
      decoded_payload="$(mktemp "${workdir%/}/openrouter-dec.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    fi

    if ! b64decode < "$PAYLOAD" > "$decoded_payload" 2>/dev/null; then
      rm -f "$RESP_RAW" "$decoded_payload" 2>/dev/null || true
      return "${BASH4LLM_ERR_TMP:-15}"
    fi
    send_payload="$decoded_payload"
  fi

  local -a extra_opts=(-H 'HTTP-Referer: https://github.com/kamaludu/bash4llm' -H 'X-Title: Bash4LLM+')

  # Single-pass unbuffered streaming pipeline via Authoritative Network Path
  _exec_curl_secure "POST" "$api_url" "$key" "$send_payload" "" "$errf_path" 1 "${extra_opts[@]}" | \
  tee -a "$RESP_RAW" | \
  jq --unbuffered -j -R '
    if startswith("data: ") then
      sub("^data:[[:space:]]*"; "") |
      select(. != "[DONE]") |
      try (fromjson | .choices[]?.delta?.content // empty) catch empty
    else
      try (
        fromjson |
        if .error.message then ("\nAPI Error: " + .error.message + "\n")
        elif .message then ("\nAPI Error: " + .message + "\n")
        else empty end
      ) catch empty
    end
  '

  rc=${PIPESTATUS[0]:-0}
  rm -f "$decoded_payload" 2>/dev/null || true

  if [ "$rc" -ne 0 ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "CURL" "OpenRouter streaming network call failed with code $rc"
    fi
    if [ -s "$RESP_RAW" ] && jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      if type atomic_write >/dev/null 2>&1; then
        atomic_write "${resp_path}" 10 < "$RESP_RAW"
      else
        cp -f "$RESP_RAW" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
    fi
    rm -f "$RESP_RAW" 2>/dev/null || true
    return "${BASH4LLM_ERR_CURL_FAILED:-12}"
  fi

  # Synthesize standard OpenAI choices response from SSE stream chunks
  if type _tmpf >/dev/null 2>&1; then
    clean_chunks="$(_tmpf file "$workdir" openrouter-chunks 2>/dev/null)" || clean_chunks="${workdir%/}/openrouter-chunks.tmp"
  else
    clean_chunks="$(mktemp "${workdir%/}/openrouter-chunks.XXXXXX" 2>/dev/null)" || clean_chunks="${workdir%/}/openrouter-chunks.tmp"
  fi

  grep -E '^data:' "$RESP_RAW" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' | jq -s '.' > "$clean_chunks" 2>/dev/null || true

  if [ -s "$clean_chunks" ] && jq -e . "$clean_chunks" >/dev/null 2>&1; then
    unified_text="$(jq -r 'map(.choices[]?.delta?.content // "") | join("")' "$clean_chunks" 2>/dev/null || true)"

    if [ -n "${unified_text}" ]; then
      if type _tmpf >/dev/null 2>&1; then
        synthetic_resp="$(_tmpf file "$workdir" openrouter-synthetic 2>/dev/null)" || synthetic_resp="${workdir%/}/openrouter-syn.json"
      else
        synthetic_resp="$(mktemp "${workdir%/}/openrouter-synthetic.XXXXXX" 2>/dev/null)" || synthetic_resp="${workdir%/}/openrouter-syn.json"
      fi

      jq -n --arg text "$unified_text" '{choices:[{message:{content:$text}}]}' > "$synthetic_resp" 2>/dev/null || true
      if type atomic_write >/dev/null 2>&1; then
        atomic_write "${resp_path}" 10 < "$synthetic_resp"
      else
        cp -f "$synthetic_resp" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
      rm -f "$synthetic_resp" 2>/dev/null || true
    fi
  else
    # Fallback if SSE clean_chunks is empty but RESP_RAW holds raw JSON error
    if [ -s "$RESP_RAW" ] && jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      if type atomic_write >/dev/null 2>&1; then
        atomic_write "${resp_path}" 10 < "$RESP_RAW"
      else
        cp -f "$RESP_RAW" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
    fi
  fi

  rm -f "$clean_chunks" "$RESP_RAW" 2>/dev/null || true
  return 0
}

# -----------------------------------------------------------------------------
# 4. refresh_models_openrouter
# Fetches model catalog, prioritizing free models (:free, openrouter/free, zero-pricing)
# -----------------------------------------------------------------------------
refresh_models_openrouter() {
  local outpath="${1:-${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/openrouter.txt}}"
  local prov_env key="" workdir tmpd out errf api_url http_code tmp_trim

  prov_env="$(provider_api_env_var_name "openrouter")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    key="${!prov_env}"
  fi
  : "${key:=${OPENROUTER_API_KEY:-${BASH4LLM_API_KEY:-}}}"

  if [ -z "$key" ]; then
    if ! ensure_api_key_for_provider "openrouter"; then
      if type log_error >/dev/null 2>&1; then
        log_error "APIKEY" "OPENROUTER_API_KEY is required to refresh models."
      fi
      return "${BASH4LLM_ERR_NO_API_KEY:-10}"
    fi
    if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
      key="${!prov_env}"
    fi
    : "${key:=${OPENROUTER_API_KEY:-${BASH4LLM_API_KEY:-}}}"
  fi

  if [ -z "$key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "OPENROUTER_API_KEY is not set."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  tmpd="$(mktemp -d "${workdir%/}/openrouter-models.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  api_url="${OPENROUTER_MODELS_URL:-https://openrouter.ai/api/v1/models}"

  local -a extra_opts=(-w "%{http_code}" -H 'HTTP-Referer: https://github.com/kamaludu/bash4llm' -H 'X-Title: Bash4LLM+')
  http_code="$(_exec_curl_secure "GET" "$api_url" "$key" "" "$out" "$errf" 0 "${extra_opts[@]}" || echo "000")"

  if [ "${http_code:0:1}" != "2" ] || [ ! -s "$out" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "MODELREFRESH" "OpenRouter models endpoint failed (HTTP $http_code)."
    fi
    rm -rf "$tmpd" 2>/dev/null || true
    return "${BASH4LLM_ERR_API:-16}"
  fi

  tmp_trim="$tmpd/parsed_trimmed.txt"

  # Preserve order: 1) openrouter/free, 2) free models (:free / 0-cost), 3) other models
  # Deduplicate on-the-fly with awk to avoid jq unique_by alphabetical sort
  {
    printf 'openrouter/free\n'
    jq -r '
      (if (has("data") and (.data|type) == "array") then .data elif (type == "array") then . else [] end) |
      .[] | select(.id != null and .id != "") |
      select((.id | endswith(":free")) or (.pricing?.prompt == "0" and .pricing?.completion == "0")) |
      .id
    ' "$out" 2>/dev/null
    jq -r '
      (if (has("data") and (.data|type) == "array") then .data elif (type == "array") then . else [] end) |
      .[] | select(.id != null and .id != "") |
      select((.id | endswith(":free") | not) and (.pricing?.prompt != "0" or .pricing?.completion != "0")) |
      .id
    ' "$out" 2>/dev/null
  } | awk '{
    g=$0
    sub(/^models\//,"",g)
    sub(/^[[:space:]]+|[[:space:]]+$/,"",g)
    if (g ~ /^[[:alnum:]._\/:-]+$/ && !seen[g]++) print g
  }' | awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' > "$tmp_trim" 2>/dev/null || true

  if [ -s "$tmp_trim" ]; then
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      atomic_write "$outpath" 10 < "$tmp_trim"
    else
      cat "$tmp_trim" > "$outpath" && chmod 600 "$outpath" 2>/dev/null || true
    fi

    if type log_info_user >/dev/null 2>&1; then
      log_info_user "MODELREFRESH" "OpenRouter models refreshed and saved to: $outpath"
    fi
    rm -rf "$tmpd" 2>/dev/null || true
    return 0
  fi

  rm -rf "$tmpd" 2>/dev/null || true
  return "${BASH4LLM_ERR_API:-16}"
}

# -----------------------------------------------------------------------------
# 5. validate_model_openrouter
# -----------------------------------------------------------------------------
validate_model_openrouter() {
  local model="${1:-}"
  local file="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/openrouter.txt}"

  # Builtin OpenRouter routers are always valid
  if [ "$model" = "openrouter/free" ] || [ "$model" = "openrouter/auto" ]; then
    return 0
  fi

  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    grep -x -F -q "$model" "$file" 2>/dev/null
    return $?
  fi
  [ -n "$model" ] || return 1
  return 0
}

# -----------------------------------------------------------------------------
# 6. auto_select_model_openrouter
# Prioritizes openrouter/free or the first available model in catalog
# -----------------------------------------------------------------------------
auto_select_model_openrouter() {
  local file="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/openrouter.txt}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    if grep -x -F -q "openrouter/free" "$file" 2>/dev/null; then
      printf 'openrouter/free'
      return 0
    fi
    awk 'NF{print; exit}' "$file" 2>/dev/null || true
    return 0
  fi
  printf 'openrouter/free'
  return 0
}

# -----------------------------------------------------------------------------
# 7. validate_key_openrouter
# Validates API key against OpenRouter auth verification endpoint
# -----------------------------------------------------------------------------
validate_key_openrouter() {
  local key="${1:-}"
  local http_code curl_rc=0
  local tmpout errf workdir

  if [ -z "$key" ]; then
    return 1
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-/tmp}}"
  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" openrouter-key 2>/dev/null)" || return 1
  else
    tmpout="$(mktemp "${workdir%/}/openrouter-key.XXXXXX" 2>/dev/null)" || return 1
  fi
  errf="${tmpout}.err"

  # Official OpenRouter key info and auth verification endpoint
  local api_url="${OPENROUTER_AUTH_URL:-https://openrouter.ai/api/v1/key}"

  local -a key_val_opts=(--max-time 10 -w "%{http_code}" -H 'HTTP-Referer: https://github.com/kamaludu/bash4llm' -H 'X-Title: Bash4LLM+')
  http_code="$(_exec_curl_secure "GET" "$api_url" "$key" "" "$tmpout" "$errf" 0 "${key_val_opts[@]}" || echo "CURL_ERR")"
  curl_rc=$?

  rm -f "$tmpout" "$errf" 2>/dev/null || true

  if [ "$http_code" = "CURL_ERR" ] || [ "$curl_rc" -eq 28 ]; then
    return 28
  fi

  if [ "$http_code" = "200" ]; then
    return 0
  else
    return 1
  fi
}

# -----------------------------------------------------------------------------
# 8. normalize_model_openrouter
# Preserves author/model slugs and openrouter/* namespaces
# -----------------------------------------------------------------------------
normalize_model_openrouter() {
  local name="${1:-}"
  name="${name#models/}"
  printf '%s' "$name"
}
