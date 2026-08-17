#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/providers/huggingface.sh
# Authority: Architecture Specification (Edition 2026.1)
# Extra: Provider Hugging Face Module (T3 Hardened & Spec-Aligned)
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Purpose: Bash4LLM adapter for Hugging Face Inference APIs & Serverless Router.
# Complies with huggingface.md specification (Dedicated Endpoints + Serverless Router).

# Sourcing guard: prevent strict shell flags pollution when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# -----------------------------------------------------------------------------
# 1. buildpayload_huggingface
# Compiles payload for Serverless Router or legacy Text-Generation endpoints
# -----------------------------------------------------------------------------
buildpayload_huggingface() {
  local workdir tmp_payload user_prompt joined

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    tmp_payload="$(_tmpf file "$workdir" hf 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  else
    tmp_payload="$(mktemp "${workdir%/}/hf.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  fi
  chmod 600 "$tmp_payload" 2>/dev/null || true

  # Auto-seed hf_endpoints configuration if missing or empty (Zero-Config clean install)
  local hf_file="${BASH4LLM_CONFIG_DIR%/}/providers/hf_endpoints"
  if [ ! -f "$hf_file" ] || [ ! -s "$hf_file" ]; then
    mkdir -p "$(dirname "$hf_file")" 2>/dev/null || true
    chmod 700 "$(dirname "$hf_file")" 2>/dev/null || true
    cat <<'EOF' > "$hf_file"
# Hugging Face Endpoints Mapping (Format: <model_id>|<endpoint_url>)
meta-llama/Llama-3.3-70B-Instruct|https://router.huggingface.co/v1/chat/completions
meta-llama/Llama-3.1-8B-Instruct|https://router.huggingface.co/v1/chat/completions
deepseek-ai/DeepSeek-R1|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-72B-Instruct|https://router.huggingface.co/v1/chat/completions
mistralai/Mistral-7B-Instruct-v0.3|https://router.huggingface.co/v1/chat/completions
microsoft/Phi-3.5-mini-instruct|https://router.huggingface.co/v1/chat/completions
EOF
    chmod 600 "$hf_file" 2>/dev/null || true
  fi

  # Inline resolution of endpoint format (OpenAI chat completions vs legacy text-generation)
  local endpoint_url="" is_openai=1
  if [ -f "$hf_file" ]; then
    endpoint_url="$(awk -F'|' -v m="${MODEL:-}" '$1==m{print $2; exit}' "$hf_file" 2>/dev/null || true)"
  fi
  if [ -n "$endpoint_url" ] && [[ "$endpoint_url" != */v1/chat/completions ]]; then
    is_openai=0
  fi

  if [ "$is_openai" -eq 1 ]; then
    # OpenAI Chat Completions schema for router.huggingface.co/v1
    local messages_arr="[]"
    if [ -n "${JSON_INPUT:-}" ]; then
      local raw_json=""
      if [ -f "${JSON_INPUT}" ]; then
        raw_json="$(cat "${JSON_INPUT}" 2>/dev/null || true)"
      else
        raw_json="${JSON_INPUT}"
      fi

      if printf '%s' "$raw_json" | jq -e . >/dev/null 2>&1; then
        if printf '%s' "$raw_json" | jq -e 'has("messages")' >/dev/null 2>&1; then
          printf '%s' "$raw_json" | jq --arg model "${MODEL:-}" \
             --argjson max_tokens "${MAX_TOKENS:-256}" \
             --arg temp "${TEMPERATURE:-${TURE:-1.0}}" \
             '.model = $model | .max_tokens = ($max_tokens|tonumber) | .temperature = ($temp|tonumber)' > "$tmp_payload" 2>/dev/null || true
        elif printf '%s' "$raw_json" | jq -e 'has("prompt")' >/dev/null 2>&1; then
          user_prompt="$(printf '%s' "$raw_json" | jq -r '.prompt' 2>/dev/null || true)"
          jq -n --arg model "${MODEL:-}" --arg prompt "$user_prompt" \
                --argjson max_tokens "${MAX_TOKENS:-256}" \
                --arg temp "${TEMPERATURE:-${TURE:-1.0}}" \
             '{model:$model, messages:[{role:"user", content:$prompt}], max_tokens:($max_tokens|tonumber), temperature:($temp|tonumber)}' > "$tmp_payload" 2>/dev/null || true
        else
          printf '%s' "$raw_json" > "$tmp_payload"
        fi
      fi
    else
      # Manage conversation history from BUILD_MESSAGES_FILE
      if [ -n "${BUILD_MESSAGES_FILE:-}" ] && [ -f "${BUILD_MESSAGES_FILE}" ]; then
        local history_msgs
        history_msgs="$(jq -c '.messages // []' "${BUILD_MESSAGES_FILE}" 2>/dev/null || true)"
        if printf '%s' "$history_msgs" | jq -e 'type=="array" and (length>0)' >/dev/null 2>&1; then
          if [ -n "${CONTENT:-}" ]; then
            messages_arr="$(jq -n --argjson hist "$history_msgs" --arg usr "${CONTENT:-}" '$hist + [{role:"user", content:$usr}]' 2>/dev/null || printf '%s' "$history_msgs")"
          else
            messages_arr="$history_msgs"
          fi
        fi
      fi

      # Fallback single message if history is empty
      if [ "$messages_arr" = "[]" ]; then
        if [ -n "${SYSTEM_PROMPT:-}" ]; then
          messages_arr="$(jq -n --arg sys "${SYSTEM_PROMPT:-}" --arg usr "${CONTENT:-}" '[{role:"system", content:$sys}, {role:"user", content:$usr}]' 2>/dev/null || true)"
        else
          messages_arr="$(jq -n --arg usr "${CONTENT:-}" '[{role:"user", content:$usr}]' 2>/dev/null || true)"
        fi
      else
        # Prepend system prompt to reconstructed history
        if [ -n "${SYSTEM_PROMPT:-}" ]; then
          messages_arr="$(jq -n --argjson msgs "$messages_arr" --arg sys "${SYSTEM_PROMPT:-}" '[{role:"system", content:$sys}] + $msgs' 2>/dev/null || printf '%s' "$messages_arr")"
        fi
      fi

      local stream_val="false"
      if is_truthy "${STREAM_MODE:-0}"; then
        stream_val="true"
      fi

      jq -n --arg model "${MODEL:-}" \
            --argjson messages "$messages_arr" \
            --argjson max_tokens "${MAX_TOKENS:-256}" \
            --argjson stream "$stream_val" \
            --arg temp "${TEMPERATURE:-${TURE:-1.0}}" \
         '{model:$model, messages:$messages, max_tokens:($max_tokens|tonumber), stream:$stream, temperature:($temp|tonumber)}' > "$tmp_payload" 2>/dev/null || true
    fi
  else
    # Legacy text-generation payload
    if [ -n "${JSON_INPUT:-}" ]; then
      local raw_json=""
      if [ -f "${JSON_INPUT}" ]; then
        raw_json="$(cat "${JSON_INPUT}" 2>/dev/null || true)"
      else
        raw_json="${JSON_INPUT}"
      fi

      if printf '%s' "$raw_json" | jq -e . >/dev/null 2>&1; then
        if printf '%s' "$raw_json" | jq -e 'has("messages")' >/dev/null 2>&1; then
          printf '%s' "$raw_json" | jq --arg model "${MODEL:-}" \
             --argjson max_tokens "${MAX_TOKENS:-256}" \
             --arg temp "${TEMPERATURE:-${TURE:-1.0}}" \
             '.model = $model | .max_tokens = ($max_tokens|tonumber) | .temperature = ($temp|tonumber)' > "$tmp_payload" 2>/dev/null || true
        elif printf '%s' "$raw_json" | jq -e 'has("prompt")' >/dev/null 2>&1; then
          user_prompt="$(printf '%s' "$raw_json" | jq -r '.prompt' 2>/dev/null || true)"
          jq -n --arg inputs "$user_prompt" \
                --argjson params "$(jq -n --argjson max_t "${MAX_TOKENS:-256}" --arg t "${TEMPERATURE:-${TURE:-1.0}}" '{max_new_tokens:$max_t, temperature:($t|tonumber)}' 2>/dev/null)" \
             '{inputs:$inputs, parameters:$params}' > "$tmp_payload" 2>/dev/null || true
        else
          printf '%s' "$raw_json" > "$tmp_payload"
        fi
      fi
    else
      if [ -n "${SYSTEM_PROMPT:-}" ]; then
        joined="$(printf 'System: %s\n\nUser: %s' "${SYSTEM_PROMPT:-}" "${CONTENT:-}")"
      else
        joined="${CONTENT:-}"
      fi
      jq -n --arg inputs "$joined" \
            --argjson params "$(jq -n --argjson max_t "${MAX_TOKENS:-256}" --arg t "${TEMPERATURE:-${TURE:-1.0}}" '{max_new_tokens:$max_t, temperature:($t|tonumber)}' 2>/dev/null)" \
         '{inputs:$inputs, parameters:$params}' > "$tmp_payload" 2>/dev/null || true
    fi
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
# 2. call_api_huggingface (Synchronous HTTP call)
# -----------------------------------------------------------------------------
call_api_huggingface() {
  local prov_env hf_key=""

  if ! ensure_api_key_for_provider "huggingface"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "HF API key required for provider huggingface."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  prov_env="$(provider_api_env_var_name "huggingface")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    hf_key="${!prov_env}"
  fi
  : "${hf_key:=${HUGGINGFACE_API_KEY:-${BASH4LLM_API_KEY:-}}}"

  if [ -z "$hf_key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "HF API key not set (env ${prov_env:-HUGGINGFACE_API_KEY})."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  local workdir
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    printf 'huggingface: ERROR: Payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    return 0
  fi

  # Inline resolution of endpoint URL with fallback to unified serverless router
  local hf_file="${BASH4LLM_CONFIG_DIR%/}/providers/hf_endpoints"
  local endpoint_url="" api_url=""
  if [ -f "$hf_file" ]; then
    endpoint_url="$(awk -F'|' -v m="${MODEL:-}" '$1==m{print $2; exit}' "$hf_file" 2>/dev/null || true)"
  fi
  if [ -z "${endpoint_url:-}" ]; then
    api_url="https://router.huggingface.co/v1/chat/completions"
  else
    api_url="${endpoint_url%/}"
  fi

  local tmpout tmpresp errf_path resp_path http_code
  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" hf-out 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    tmpresp="$(_tmpf file "$workdir" hf-resp 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  else
    tmpout="$(mktemp "${workdir%/}/hf-out.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    tmpresp="$(mktemp "${workdir%/}/hf-resp.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  errf_path="${ERRF:-$workdir/curl.err}"
  resp_path="${RESP:-$workdir/resp.json}"

  local -a extra_opts=(-w '%{http_code}')
  http_code="$(_exec_curl_secure "POST" "$api_url" "$hf_key" "$PAYLOAD" "$tmpresp" "$errf_path" 0 "${extra_opts[@]}" || echo "000")"

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
        log_error "API" "Hugging Face API HTTP Error status: $http_code"
      fi
      return "${BASH4LLM_ERR_API:-16}"
      ;;
  esac
}

# -----------------------------------------------------------------------------
# 3. call_api_streaming_huggingface (SSE Streaming with JSON Error Fallback)
# -----------------------------------------------------------------------------
call_api_streaming_huggingface() {
  local prov_env hf_key=""

  if ! ensure_api_key_for_provider "huggingface"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "HF API key required for provider huggingface."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  prov_env="$(provider_api_env_var_name "huggingface")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    hf_key="${!prov_env}"
  fi
  : "${hf_key:=${HUGGINGFACE_API_KEY:-${BASH4LLM_API_KEY:-}}}"

  if [ -z "$hf_key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "HF API key not set."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    return 0
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  local workdir
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  local hf_file="${BASH4LLM_CONFIG_DIR%/}/providers/hf_endpoints"
  local endpoint_url="" api_url=""
  if [ -f "$hf_file" ]; then
    endpoint_url="$(awk -F'|' -v m="${MODEL:-}" '$1==m{print $2; exit}' "$hf_file" 2>/dev/null || true)"
  fi
  if [ -z "${endpoint_url:-}" ]; then
    api_url="https://router.huggingface.co/v1/chat/completions"
  else
    api_url="${endpoint_url%/}"
  fi

  local RESP_RAW errf_path resp_path rc clean_chunks unified_text synthetic_resp
  if type _tmpf >/dev/null 2>&1; then
    RESP_RAW="$(_tmpf file "$workdir" hf-raw 2>/dev/null)" || RESP_RAW="${workdir%/}/resp.raw"
  else
    RESP_RAW="$(mktemp "${workdir%/}/hf-raw.XXXXXX" 2>/dev/null)" || RESP_RAW="${workdir%/}/resp.raw"
  fi
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  errf_path="${ERRF:-$workdir/curl.err}"
  resp_path="${RESP:-$workdir/resp.json}"

  # Unbuffered streaming pipeline routed through _exec_curl_secure
  _exec_curl_secure "POST" "$api_url" "$hf_key" "$PAYLOAD" "" "$errf_path" 1 | \
  tee -a "$RESP_RAW" | \
  jq --unbuffered -j -R '
    if startswith("data: ") then
      sub("^data:[[:space:]]*"; "") |
      select(. != "[DONE]") |
      try (fromjson | .choices[]?.delta?.content // .choices[]?.message?.content // empty) catch empty
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

  if [ "$rc" -ne 0 ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "CURL" "Hugging Face streaming network call failed with code $rc"
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
    clean_chunks="$(_tmpf file "$workdir" hf-chunks 2>/dev/null)" || clean_chunks="${workdir%/}/hf-chunks.tmp"
  else
    clean_chunks="$(mktemp "${workdir%/}/hf-chunks.XXXXXX" 2>/dev/null)" || clean_chunks="${workdir%/}/hf-chunks.tmp"
  fi

  grep -E '^data:' "$RESP_RAW" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' | jq -s '.' > "$clean_chunks" 2>/dev/null || true

  if [ -s "$clean_chunks" ] && jq -e . "$clean_chunks" >/dev/null 2>&1; then
    unified_text="$(jq -r 'map(.choices[]?.delta?.content // .choices[]?.message?.content // "") | join("")' "$clean_chunks" 2>/dev/null || true)"

    if [ -n "${unified_text}" ]; then
      if type _tmpf >/dev/null 2>&1; then
        synthetic_resp="$(_tmpf file "$workdir" hf-synthetic 2>/dev/null)" || synthetic_resp="${workdir%/}/hf-syn.json"
      else
        synthetic_resp="$(mktemp "${workdir%/}/hf-synthetic.XXXXXX" 2>/dev/null)" || synthetic_resp="${workdir%/}/hf-syn.json"
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
# 4. refresh_models_huggingface
# -----------------------------------------------------------------------------
refresh_models_huggingface() {
  local outpath="${1:-${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/huggingface.txt}}"
  local hf_file="${BASH4LLM_CONFIG_DIR%/}/providers/hf_endpoints"
  local workdir tmpout

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" hf-models 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  else
    tmpout="$(mktemp "${workdir%/}/hf-models.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  # Auto-seed hf_endpoints if missing or empty
  if [ ! -f "$hf_file" ] || [ ! -s "$hf_file" ]; then
    mkdir -p "$(dirname "$hf_file")" 2>/dev/null || true
    chmod 700 "$(dirname "$hf_file")" 2>/dev/null || true
    cat <<'EOF' > "$hf_file"
# Hugging Face Endpoints Mapping (Format: <model_id>|<endpoint_url>)
meta-llama/Llama-3.3-70B-Instruct|https://router.huggingface.co/v1/chat/completions
meta-llama/Llama-3.1-8B-Instruct|https://router.huggingface.co/v1/chat/completions
deepseek-ai/DeepSeek-R1|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-72B-Instruct|https://router.huggingface.co/v1/chat/completions
mistralai/Mistral-7B-Instruct-v0.3|https://router.huggingface.co/v1/chat/completions
microsoft/Phi-3.5-mini-instruct|https://router.huggingface.co/v1/chat/completions
EOF
    chmod 600 "$hf_file" 2>/dev/null || true
  fi

  # Parse model identifiers from local endpoints mapping
  awk -F'|' 'NF && $1!~/^#/ {print $1}' "$hf_file" | awk 'NF{print}' | sort -u > "$tmpout" 2>/dev/null || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
  if type atomic_write >/dev/null 2>&1; then
    atomic_write "$outpath" 10 < "$tmpout"
  else
    cat "$tmpout" > "$outpath" && chmod 600 "$outpath" 2>/dev/null || true
  fi

  if type log_info_user >/dev/null 2>&1; then
    log_info_user "MODELREFRESH" "Hugging Face models refreshed and saved to: $outpath"
  fi

  rm -f "$tmpout" 2>/dev/null || true
  return 0
}

# -----------------------------------------------------------------------------
# 5. validate_model_huggingface
# -----------------------------------------------------------------------------
validate_model_huggingface() {
  local model="${1:-}"
  local file="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/huggingface.txt}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    grep -x -F -q "$model" "$file" 2>/dev/null
    return $?
  fi
  [ -n "$model" ] || return 1
  return 0
}

# -----------------------------------------------------------------------------
# 6. auto_select_model_huggingface
# -----------------------------------------------------------------------------
auto_select_model_huggingface() {
  local file="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/huggingface.txt}"
  if [ -n "$file" ] && [ -f "$file" ] && [ -s "$file" ]; then
    awk 'NF{print; exit}' "$file" 2>/dev/null || true
    return 0
  fi
  printf ''
  return 0
}

# -----------------------------------------------------------------------------
# 7. validate_key_huggingface
# -----------------------------------------------------------------------------
validate_key_huggingface() {
  local key="${1:-}"
  local http_code curl_rc=0
  local tmpout errf workdir

  if [ -z "$key" ]; then
    return 1
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-/tmp}}"
  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" hf-key 2>/dev/null)" || return 1
  else
    tmpout="$(mktemp "${workdir%/}/hf-key.XXXXXX" 2>/dev/null)" || return 1
  fi
  errf="${tmpout}.err"

  # Identity verification via HF API whoami-v2
  local api_url="https://huggingface.co/api/whoami-v2"

  local -a key_val_opts=(--max-time 10 -w "%{http_code}")
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
# 8. normalize_model_huggingface
# -----------------------------------------------------------------------------
normalize_model_huggingface() {
  local name="${1:-}"
  name="${name#models/}"
  printf '%s' "$name"
}

# =============================================================================
# SECTION: ADMINISTRATIVE CLI HELPERS (Interactive Sourcing - Section 3.2)
# Available when this module is sourced directly in an interactive shell session.
# =============================================================================

# -----------------------------------------------------------------------------
# hf_list_endpoints
# Lists all model mappings and endpoint URLs registered in hf_endpoints
# -----------------------------------------------------------------------------
hf_list_endpoints() {
  local cfg_dir="${BASH4LLM_CONFIG_DIR:-./bash4llm.d/config}"
  local hf_file="${cfg_dir%/}/providers/hf_endpoints"
  local i=0 model url

  if [ ! -f "$hf_file" ] || [ ! -s "$hf_file" ]; then
    printf 'No Hugging Face endpoints registered (file: %s)\n' "$hf_file" >&2
    return 0
  fi

  printf 'Configured Hugging Face Endpoints (%s):\n' "$hf_file"
  while IFS='|' read -r model url _ || [ -n "$model" ]; do
    [ -z "$model" ] && continue
    [[ "$model" == "#"* ]] && continue
    i=$((i+1))
    printf '  %d) %s -> %s\n' "$i" "$model" "$url"
  done < "$hf_file"
  return 0
}

# -----------------------------------------------------------------------------
# hf_add_endpoint <model_id> <endpoint_url>
# Adds or updates a dedicated endpoint mapping in hf_endpoints
# -----------------------------------------------------------------------------
hf_add_endpoint() {
  local model="${1:-}"
  local url="${2:-}"
  local cfg_dir="${BASH4LLM_CONFIG_DIR:-./bash4llm.d/config}"
  local hf_file="${cfg_dir%/}/providers/hf_endpoints"
  local tmp_file=""

  if [ -z "$model" ] || [ -z "$url" ]; then
    printf 'Usage: hf_add_endpoint "<model_id>" "<endpoint_url>"\n' >&2
    printf 'Example: hf_add_endpoint "google/gemma-2-2b-it" "https://router.huggingface.co/v1/chat/completions"\n' >&2
    return 1
  fi

  case "$url" in
    https://*) ;;
    *)
      printf 'hf_add_endpoint: ERROR: Endpoint URL must start with https://\n' >&2
      return 1
      ;;
  esac

  mkdir -p "$(dirname "$hf_file")" 2>/dev/null || true
  chmod 700 "$(dirname "$hf_file")" 2>/dev/null || true
  [ -f "$hf_file" ] || : > "$hf_file" 2>/dev/null || true

  tmp_file="$(mktemp "${hf_file}.tmp.XXXXXX" 2>/dev/null || true)"
  [ -n "$tmp_file" ] || tmp_file="${hf_file}.tmp.$$"

  # Filter out previous model entry if present and append updated mapping
  awk -F'|' -v m="$model" '$1!=m {print}' "$hf_file" > "$tmp_file" 2>/dev/null || true
  printf '%s|%s\n' "$model" "$url" >> "$tmp_file"

  if type atomic_write >/dev/null 2>&1; then
    atomic_write "$hf_file" 10 < "$tmp_file"
  else
    mv -f "$tmp_file" "$hf_file" 2>/dev/null || cp -f "$tmp_file" "$hf_file" 2>/dev/null || true
    chmod 600 "$hf_file" 2>/dev/null || true
  fi
  rm -f "$tmp_file" 2>/dev/null || true

  printf 'Endpoint registered: %s -> %s\n' "$model" "$url"
  return 0
}

# -----------------------------------------------------------------------------
# hf_remove_endpoint <model_id>
# Removes an endpoint mapping from hf_endpoints
# -----------------------------------------------------------------------------
hf_remove_endpoint() {
  local model="${1:-}"
  local cfg_dir="${BASH4LLM_CONFIG_DIR:-./bash4llm.d/config}"
  local hf_file="${cfg_dir%/}/providers/hf_endpoints"
  local tmp_file=""

  if [ -z "$model" ]; then
    printf 'Usage: hf_remove_endpoint "<model_id>"\n' >&2
    return 1
  fi

  if [ ! -f "$hf_file" ]; then
    printf 'hf_remove_endpoint: ERROR: Configuration file not found: %s\n' "$hf_file" >&2
    return 1
  fi

  if ! awk -F'|' -v m="$model" '$1==m{found=1} END{exit !found}' "$hf_file" 2>/dev/null; then
    printf 'hf_remove_endpoint: Model "%s" not found in %s\n' "$model" "$hf_file" >&2
    return 1
  fi

  tmp_file="$(mktemp "${hf_file}.tmp.XXXXXX" 2>/dev/null || true)"
  [ -n "$tmp_file" ] || tmp_file="${hf_file}.tmp.$$"

  awk -F'|' -v m="$model" '$1!=m {print}' "$hf_file" > "$tmp_file" 2>/dev/null || true

  if type atomic_write >/dev/null 2>&1; then
    atomic_write "$hf_file" 10 < "$tmp_file"
  else
    mv -f "$tmp_file" "$hf_file" 2>/dev/null || cp -f "$tmp_file" "$hf_file" 2>/dev/null || true
    chmod 600 "$hf_file" 2>/dev/null || true
  fi
  rm -f "$tmp_file" 2>/dev/null || true

  printf 'Endpoint removed for model: %s\n' "$model"
  return 0
}
