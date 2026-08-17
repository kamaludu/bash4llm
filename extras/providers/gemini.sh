#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/providers/gemini.sh
# Authority: Architecture Specification (Edition 2026.1)
# Extra: Provider Gemini Module (T3 Hardened & Whitelist Compliant)
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Purpose: Bash4LLM provider adapter for Gemini APIs (Google Generative Language)
# Invariants: Zero unwhitelisted private helpers, strict argv secret isolation.

# Sourcing guard: prevent strict shell flags pollution when sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# -----------------------------------------------------------------------------
# 1. buildpayload_gemini
# Transforms conversation history into native Gemini API JSON schema
# -----------------------------------------------------------------------------
buildpayload_gemini() {
  if [ -z "${PAYLOAD:-}" ]; then
    printf 'gemini: ERROR: PAYLOAD variable is unset; cannot write payload\n' >&2
    return 2
  fi

  local workdir tmpf messages_json messages_arg input_messages_json sys_prompt p_val
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    tmpf="$(_tmpf file "$workdir" gemini 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  else
    tmpf="$(mktemp "${workdir%/}/gemini.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
  fi
  chmod 600 "$tmpf" 2>/dev/null || true

  messages_arg=''
  if [ -n "${BUILD_MESSAGES_FILE:-}" ] && [ -f "${BUILD_MESSAGES_FILE:-}" ]; then
    messages_json="$(jq -c '.messages // if type=="array" then . else [.] end' "${BUILD_MESSAGES_FILE:-}" 2>/dev/null || true)"
    if [ -n "$messages_json" ] && [ "$messages_json" != "null" ]; then
      messages_arg=1
      if [ -n "${CONTENT:-}" ]; then
        messages_json="$(printf '%s' "$CONTENT" | jq -sR --argjson msgs "$messages_json" '$msgs + [{role: "user", content: .}]' 2>/dev/null || printf '%s' "$messages_json")"
      fi
    fi
  elif [ -n "${MESSAGES_JSON:-}" ]; then
    if [ -f "${MESSAGES_JSON:-}" ]; then
      messages_json="$(cat "${MESSAGES_JSON:-}" 2>/dev/null || true)"
    else
      messages_json="${MESSAGES_JSON}"
    fi
    if printf '%s' "${messages_json}" | jq -e . >/dev/null 2>&1; then
      messages_arg=1
    fi
  fi

  if [ -n "${messages_arg}" ]; then
    input_messages_json="$(printf '%s' "${messages_json}" | jq -c 'if type=="array" then . else [.] end' 2>/dev/null || true)"
  else
    if [ -z "${CONTENT:-}" ]; then
      printf 'gemini: ERROR: No MESSAGES_JSON and no CONTENT provided; cannot build payload\n' >&2
      rm -f "$tmpf" 2>/dev/null || true
      return "${BASH4LLM_ERR_NO_PROMPT:-14}"
    fi
    input_messages_json="$(printf '%s' "${CONTENT:-}" | jq -sR '[{role: "user", content: .}]' 2>/dev/null)"
  fi

  sys_prompt="${SYSTEM_PROMPT:-}"

  # Pass message array to jq via pipeline (safe under set -u)
  if ! printf '%s' "${input_messages_json}" | jq \
         --arg system_prompt "${sys_prompt}" \
         --arg temp "${TEMPERATURE:-${TURE:-}}" \
         --arg max_tok "${MAX_TOKENS:-}" \
         '
         . as $messages |
         # 1. Extract and merge system instructions
         ((($messages | map(select(.role == "system") | .content) | join("\n")) + (if $system_prompt != "" then "\n" + $system_prompt else "" end) | sub("^\\s+"; "") | sub("\\s+$"; ""))) as $sys_instruction |

         # 2. Convert conversation turns mapping "assistant" -> "model"
         ($messages | map(select(.role != "system") | {
           role: (if .role == "assistant" then "model" else "user" end),
           parts: [{text: (.content // "")}]
         })) as $contents |

         # 3. Build generation configuration
         ({} |
          if $temp != "" then . + {temperature: ($temp | tonumber)} else . end |
          if $max_tok != "" then . + {maxOutputTokens: ($max_tok | tonumber)} else . end
         ) as $gen_config |

         # 4. Construct final Gemini-native payload
         ({contents: $contents} |
          if $sys_instruction != "" then . + {systemInstruction: {parts: [{text: $sys_instruction}]}} else . end |
          if ($gen_config | keys | length) > 0 then . + {generationConfig: $gen_config} else . end
         )
         ' > "$tmpf" 2>/dev/null; then
    printf 'gemini: ERROR: jq failed to construct the Gemini API payload\n' >&2
    rm -f "$tmpf" 2>/dev/null || true
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if [ -s "$tmpf" ]; then
    if [ "$(tail -c1 "$tmpf" 2>/dev/null || true)" != "" ]; then
      printf '\n' >> "$tmpf" 2>/dev/null || true
    fi
  fi

  if ! jq -e . "$tmpf" >/dev/null 2>&1; then
    printf 'gemini: ERROR: Built payload is not valid JSON\n' >&2
    rm -f "$tmpf" 2>/dev/null || true
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  p_val="${PAYLOAD:-}"
  if [ "${p_val##*.}" = "b64" ] && type stage_b64 >/dev/null 2>&1; then
    if stage_b64 "$tmpf" "$PAYLOAD"; then
      rm -f "$tmpf" 2>/dev/null || true
      return 0
    fi
  fi

  umask 077
  if type atomic_write >/dev/null 2>&1; then
    atomic_write "$PAYLOAD" 10 < "$tmpf"
  else
    cat "$tmpf" > "$PAYLOAD" && chmod 600 "$PAYLOAD" 2>/dev/null || true
  fi
  rm -f "$tmpf" 2>/dev/null || true
  return 0
}

# -----------------------------------------------------------------------------
# 2. call_api_gemini (Synchronous HTTP call)
# -----------------------------------------------------------------------------
call_api_gemini() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key required for provider gemini."
    fi
    local workdir_err="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  local prov_env key=""
  prov_env="$(provider_api_env_var_name "gemini")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    key="${!prov_env}"
  fi
  : "${key:=${BASH4LLM_API_KEY:-${GEMINI_API_KEY:-}}}"

  if [ -z "$key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key not available in env $prov_env"
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    printf 'gemini: ERROR: Payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
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

  local workdir tmpout tmpresp errf api_url model_subst key_trim http_code active_model send_payload decoded_payload resp_path extracted_text tmpconv
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" gemini-out 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    tmpresp="$(_tmpf file "$workdir" gemini-resp 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    errf="$(_tmpf file "$workdir" gemini-err 2>/dev/null)" || errf="${workdir%/}/curl.err"
  else
    tmpout="$(mktemp "${workdir%/}/gemini-out.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    tmpresp="$(mktemp "${workdir%/}/gemini-resp.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    errf="${workdir%/}/curl.err"
  fi

  send_payload="$PAYLOAD"
  decoded_payload=""
  if [[ "${PAYLOAD:-}" == *.b64 ]]; then
    if type _tmpf >/dev/null 2>&1; then
      decoded_payload="$(_tmpf file "$workdir" gemini-dec 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    else
      decoded_payload="$(mktemp "${workdir%/}/gemini-dec.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    fi

    if ! b64decode < "$PAYLOAD" > "$decoded_payload" 2>/dev/null; then
      rm -f "$tmpout" "$tmpresp" "$decoded_payload" 2>/dev/null || true
      return "${BASH4LLM_ERR_TMP:-15}"
    fi
    send_payload="$decoded_payload"
  fi

  active_model="${MODEL:-}"
  model_subst="${active_model#models/}"
  if [ -z "$model_subst" ]; then
    printf 'gemini: ERROR: MODEL not set. Set MODEL to a Gemini model name (e.g. gemini-2.5-flash).\n' >&2
    rm -f "$tmpout" "$tmpresp" "$decoded_payload" 2>/dev/null || true
    return "${BASH4LLM_ERR_BAD_MODEL:-11}"
  fi

  api_url="https://generativelanguage.googleapis.com/v1beta/models/${model_subst}:generateContent"
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  local -a extra_opts=(-w '%{http_code}')
  http_code="$(_exec_curl_secure "POST" "$api_url" "x-goog-api-key: ${key_trim}" "$send_payload" "$tmpresp" "$errf" 0 "${extra_opts[@]}" || echo "000")"

  rm -f "$decoded_payload" 2>/dev/null || true

  resp_path="${RESP:-$workdir/resp.json}"

  if [ -s "$tmpresp" ]; then
    if type atomic_write >/dev/null 2>&1; then
      atomic_write "${resp_path}" 10 < "$tmpresp"
    else
      cp -f "$tmpresp" "${resp_path}" 2>/dev/null || true
      chmod 600 "${resp_path}" 2>/dev/null || true
    fi
  else
    umask 077
    jq -n --arg code "${http_code:-000}" --arg msg "empty response body" '{error:{code:$code,message:$msg}}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
  fi

  # Transform native Gemini response to standard OpenAI choices format
  if [ -s "${resp_path}" ] && jq -e . "${resp_path}" >/dev/null 2>&1; then
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${resp_path}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      if type _tmpf >/dev/null 2>&1; then
        tmpconv="$(_tmpf file "$workdir" gemini-conv 2>/dev/null)" || true
      else
        tmpconv="$(mktemp "${workdir%/}/gemini-conv.XXXXXX" 2>/dev/null)" || true
      fi
      if [ -n "${tmpconv:-}" ]; then
        jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv" 2>/dev/null || true
        if type atomic_write >/dev/null 2>&1; then
          atomic_write "${resp_path}" 10 < "$tmpconv"
        else
          cp -f "$tmpconv" "${resp_path}" 2>/dev/null || true
          chmod 600 "${resp_path}" 2>/dev/null || true
        fi
        rm -f "$tmpconv" 2>/dev/null || true
      fi
    fi
  fi

  rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true

  case "$http_code" in
    2*) return 0 ;;
    *)
      if type log_error >/dev/null 2>&1; then
        log_error "API" "Gemini API HTTP Error status: $http_code"
      fi
      return "${BASH4LLM_ERR_API:-16}"
      ;;
  esac
}

# -----------------------------------------------------------------------------
# 3. call_api_streaming_gemini (SSE Streaming with JSON Error Fallback)
# -----------------------------------------------------------------------------
call_api_streaming_gemini() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key required for provider gemini."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  local prov_env key=""
  prov_env="$(provider_api_env_var_name "gemini")"
  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    key="${!prov_env}"
  fi
  : "${key:=${BASH4LLM_API_KEY:-${GEMINI_API_KEY:-}}}"

  if [ -z "$key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key not available in env $prov_env"
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    local workdir_dr="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
    local resp_path="${RESP:-${workdir_dr%/}/resp.json}"
    umask 077
    jq -n '{choices:[]}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 0
  fi

  local workdir RESP_RAW errf api_url model_subst key_trim rc active_model send_payload decoded_payload resp_path clean_chunks unified_text synthetic_resp
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  if [ -z "$workdir" ] || [ ! -d "$workdir" ]; then
    return "${BASH4LLM_ERR_TMP:-15}"
  fi

  if type _tmpf >/dev/null 2>&1; then
    RESP_RAW="$(_tmpf file "$workdir" gemini-raw 2>/dev/null)" || RESP_RAW="${workdir%/}/resp.raw"
    errf="$(_tmpf file "$workdir" gemini-err 2>/dev/null)" || errf="${workdir%/}/curl.err"
  else
    RESP_RAW="$(mktemp "${workdir%/}/gemini-raw.XXXXXX" 2>/dev/null)" || RESP_RAW="${workdir%/}/resp.raw"
    errf="${workdir%/}/curl.err"
  fi
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  send_payload="$PAYLOAD"
  decoded_payload=""
  if [[ "${PAYLOAD:-}" == *.b64 ]]; then
    if type _tmpf >/dev/null 2>&1; then
      decoded_payload="$(_tmpf file "$workdir" gemini-dec 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    else
      decoded_payload="$(mktemp "${workdir%/}/gemini-dec.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"
    fi
    if ! b64decode < "$PAYLOAD" > "$decoded_payload" 2>/dev/null; then
      rm -f "$RESP_RAW" "$decoded_payload" 2>/dev/null || true
      return "${BASH4LLM_ERR_TMP:-15}"
    fi
    send_payload="$decoded_payload"
  fi

  active_model="${MODEL:-}"
  model_subst="${active_model#models/}"
  if [ -z "$model_subst" ]; then
    printf 'gemini: ERROR: MODEL not set. Set MODEL to a Gemini model name.\n' >&2
    rm -f "$RESP_RAW" "$decoded_payload" 2>/dev/null || true
    return "${BASH4LLM_ERR_BAD_MODEL:-11}"
  fi

  api_url="https://generativelanguage.googleapis.com/v1beta/models/${model_subst}:streamGenerateContent?alt=sse"
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  # Unbuffered streaming pipeline routed through _exec_curl_secure
  _exec_curl_secure "POST" "$api_url" "x-goog-api-key: ${key_trim}" "$send_payload" "" "$errf" 1 | \
  tee -a "$RESP_RAW" | \
  jq --unbuffered -j -R '
    select(length > 0) |
    if startswith("data: ") then sub("^data:[[:space:]]*"; "") else . end |
    try (
      fromjson |
      if .error then ("\nAPI Error: " + .error.message + "\n")
      elif .candidates then (.candidates[]?.content?.parts[]?.text // empty)
      elif .content then (.content?.parts[]?.text // empty)
      elif .outputs then (.outputs[]?.content?.parts[]?.text // empty)
      else empty end
    ) catch empty
  '

  rc=${PIPESTATUS[0]:-0}
  rm -f "$decoded_payload" 2>/dev/null || true

  resp_path="${RESP:-$workdir/resp.json}"

  if [ "$rc" -ne 0 ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "CURL" "Gemini streaming network call failed with code $rc"
    fi
    if [ -s "$RESP_RAW" ] && jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      if type atomic_write >/dev/null 2>&1; then
        atomic_write "${resp_path}" 10 < "$RESP_RAW"
      else
        cp -f "$RESP_RAW" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
    fi
    rm -f "$RESP_RAW" "$errf" 2>/dev/null || true
    return "${BASH4LLM_ERR_CURL_FAILED:-12}"
  fi

  # Synthesize standard OpenAI choices response from SSE stream chunks
  if type _tmpf >/dev/null 2>&1; then
    clean_chunks="$(_tmpf file "$workdir" gemini-chunks 2>/dev/null)" || clean_chunks="${workdir%/}/gemini-chunks.tmp"
  else
    clean_chunks="$(mktemp "${workdir%/}/gemini-chunks.XXXXXX" 2>/dev/null)" || clean_chunks="${workdir%/}/gemini-chunks.tmp"
  fi

  grep -E '^data:' "$RESP_RAW" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' | jq -s '.' > "$clean_chunks" 2>/dev/null || true

  if [ -s "$clean_chunks" ] && jq -e . "$clean_chunks" >/dev/null 2>&1; then
    unified_text="$(jq -r 'map(.candidates[]?.content?.parts[]?.text // .content?.parts[]?.text // .outputs[]?.content?.parts[]?.text // "") | join("")' "$clean_chunks" 2>/dev/null || true)"
    if [ -n "${unified_text}" ]; then
      if type _tmpf >/dev/null 2>&1; then
        synthetic_resp="$(_tmpf file "$workdir" gemini-synthetic 2>/dev/null)" || synthetic_resp="${workdir%/}/gemini-syn.json"
      else
        synthetic_resp="$(mktemp "${workdir%/}/gemini-synthetic.XXXXXX" 2>/dev/null)" || synthetic_resp="${workdir%/}/gemini-syn.json"
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
    # Fallback if SSE clean_chunks is empty but RESP_RAW holds raw JSON response/error
    if [ -s "$RESP_RAW" ] && jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      if type atomic_write >/dev/null 2>&1; then
        atomic_write "${resp_path}" 10 < "$RESP_RAW"
      else
        cp -f "$RESP_RAW" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
    fi
  fi

  rm -f "$clean_chunks" "$RESP_RAW" "$errf" 2>/dev/null || true
  return 0
}

# -----------------------------------------------------------------------------
# 4. refresh_models_gemini
# -----------------------------------------------------------------------------
refresh_models_gemini() {
  local outpath="${1:-${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/gemini.txt}}"
  local prov_env key="" workdir tmpd out errf parsed tmpfinal http_code key_trim

  prov_env="$(provider_api_env_var_name "gemini")"

  if is_truthy "${DRY_RUN:-0}"; then
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    printf '%s\n' "gemini-2.5-flash" "gemini-3.5-flash" "gemini-3.5-pro" > "$outpath"
    chmod 600 "$outpath" 2>/dev/null || true
    BASH4LLM_PROVIDER_URL="https://generativelanguage.googleapis.com"
    export BASH4LLM_PROVIDER_URL
    return 0
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key required to refresh models."
    fi
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  if [ -n "${prov_env:-}" ] && declare -p "$prov_env" >/dev/null 2>&1; then
    key="${!prov_env}"
  fi
  : "${key:=${BASH4LLM_API_KEY:-${GEMINI_API_KEY:-}}}"

  if [ -z "$key" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "API key not available in env $prov_env"
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

  tmpd="$(mktemp -d "${workdir%/}/gemini-models.XXXXXX" 2>/dev/null)" || return "${BASH4LLM_ERR_TMP:-15}"

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  parsed="$tmpd/parsed_models.txt"
  tmpfinal="$tmpd/final_models.txt"

  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"
  api_url="https://generativelanguage.googleapis.com/v1beta/models?pageSize=${MAX_MODELS:-200}"

  local -a extra_opts=(-w '%{http_code}')
  http_code="$(_exec_curl_secure "GET" "$api_url" "x-goog-api-key: ${key_trim}" "" "$out" "$errf" 0 "${extra_opts[@]}" || echo "000")"

  if [ "${http_code:0:1}" != "2" ] || [ ! -s "$out" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "MODELREFRESH" "Gemini models endpoint failed (HTTP $http_code)."
    fi
    rm -rf "$tmpd" 2>/dev/null || true
    return "${BASH4LLM_ERR_API:-16}"
  fi

  jq -r '.models[]?.name // empty' "$out" | awk 'NF{print}' | sed -E 's/^models\///' | sort -u > "$parsed" 2>/dev/null || true

  if [ ! -s "$parsed" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "MODELREFRESH" "Parsed Gemini models list is empty."
    fi
    rm -rf "$tmpd" 2>/dev/null || true
    return "${BASH4LLM_ERR_API:-16}"
  fi

  awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' "$parsed" > "$tmpfinal" 2>/dev/null || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
  if type atomic_write >/dev/null 2>&1; then
    atomic_write "$outpath" 10 < "$tmpfinal"
  else
    cat "$tmpfinal" > "$outpath" && chmod 600 "$outpath" 2>/dev/null || true
  fi

  BASH4LLM_PROVIDER_URL="https://generativelanguage.googleapis.com"
  export BASH4LLM_PROVIDER_URL

  if type log_info_user >/dev/null 2>&1; then
    log_info_user "MODELREFRESH" "Gemini models refreshed and saved to: $outpath"
  fi

  rm -rf "$tmpd" 2>/dev/null || true
  return 0
}

# -----------------------------------------------------------------------------
# 5. validate_model_gemini
# -----------------------------------------------------------------------------
validate_model_gemini() {
  local m="${1:-}"
  [ -n "$m" ] || return 1
  return 0
}

# -----------------------------------------------------------------------------
# 6. auto_select_model_gemini
# -----------------------------------------------------------------------------
auto_select_model_gemini() {
  local file="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/gemini.txt}"
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

# -----------------------------------------------------------------------------
# 7. validate_key_gemini
# -----------------------------------------------------------------------------
validate_key_gemini() {
  local key="${1:-}"
  local http_code curl_rc=0
  local tmpout errf workdir

  if [ -z "$key" ]; then
    return 1
  fi

  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-/tmp}}"
  if type _tmpf >/dev/null 2>&1; then
    tmpout="$(_tmpf file "$workdir" gemini-key 2>/dev/null)" || return 1
  else
    tmpout="$(mktemp "${workdir%/}/gemini-key.XXXXXX" 2>/dev/null)" || return 1
  fi
  errf="${tmpout}.err"

  local api_url="https://generativelanguage.googleapis.com/v1beta/models"

  local -a key_val_opts=(--max-time 10 -w "%{http_code}")
  http_code="$(_exec_curl_secure "GET" "$api_url" "x-goog-api-key: ${key}" "" "$tmpout" "$errf" 0 "${key_val_opts[@]}" || echo "CURL_ERR")"
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
# 8. normalize_model_gemini
# -----------------------------------------------------------------------------
normalize_model_gemini() {
  local name="${1:-}"
  name="${name#models/}"
  printf '%s' "$name"
}
