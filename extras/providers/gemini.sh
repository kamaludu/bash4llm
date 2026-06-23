#!/usr/bin/env bash
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the Groq API
# File: gemini.sh
# Version: 2.0.0
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# =============================================================================
# Provider: Gemini (extras/providers/gemini.sh)
# Purpose: Bash4LLM provider adapter for Gemini-style APIs (compat shim)
# =============================================================================

# -------------------------
# Helpers
# -------------------------
_get_models_file_gemini() {
  printf '%s' "${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/gemini.txt}"
}

_get_work_tmpdir_gemini() {
  # RUN_TMPDIR è sempre definita ed esportata dal core prima dell'esecuzione
  printf '%s' "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}"
}

_mktemp_in_dir_gemini() {
  local dir="$1" tmpf
  [ -n "$dir" ] || return 1
  [ -d "$dir" ] || return 1
  # Sintassi portabile universale compatibile sia con Linux che con macOS
  tmpf="$(mktemp "$dir/gemini-XXXXXX" 2>/dev/null || true)"
  [ -n "$tmpf" ] || return 1
  printf '%s' "$tmpf"
}

_gemini_write_atomic() {
  local src="${1:-}" dst="${2:-}"
  if [ -z "${src:-}" ] || [ -z "${dst:-}" ] || [ ! -s "$src" ]; then
    return 1
  fi
  # Il core garantisce sempre la presenza di atomic_write
  cat "$src" | atomic_write "$dst"
}

_gemini_substitute_model_in_template() {
  local template="$1" model="$2"
  printf '%s' "${template//\$\{MODEL\}/$model}"
}

# -------------------------
# buildpayload_gemini
# -------------------------
buildpayload_gemini() {
  if [ -z "${PAYLOAD:-}" ]; then
    printf "Error: \$PAYLOAD not set; cannot write payload\n" >&2
    return 2
  fi

  local workdir tmpf messages_json messages_arg input_messages_json sys_prompt
  workdir="$(_get_work_tmpdir_gemini)"
  [ -n "$workdir" ] || return 3

  tmpf="$(_mktemp_in_dir_gemini "$workdir")" || return 3

  messages_arg=''
  # Verifica prioritaria se il core ha popolato la cronologia di sessione
  if [ -n "${BUILD_MESSAGES_FILE:-}" ] && [ -f "${BUILD_MESSAGES_FILE}" ]; then
    messages_json="$(jq -c '.messages // if type=="array" then . else [.] end' "${BUILD_MESSAGES_FILE}" 2>/dev/null || true)"
    if [ -n "$messages_json" ] && [ "$messages_json" != "null" ]; then
      messages_arg=1
      # CORREZIONE: Unisce immediatamente l'input corrente alla cronologia se presente
      if [ -n "${CONTENT:-}" ]; then
        messages_json="$(printf '%s' "$messages_json" | jq -c --arg content "$CONTENT" '. + [{role: "user", content: $content}]' 2>/dev/null || printf '%s' "$messages_json")"
      fi
    fi
  elif [ -n "${MESSAGES_JSON:-}" ]; then
    if [ -f "${MESSAGES_JSON}" ]; then
      messages_json="$(cat "${MESSAGES_JSON}" 2>/dev/null || true)"
    else
      messages_json="${MESSAGES_JSON}"
    fi
    if printf '%s' "${messages_json}" | jq -e . >/dev/null 2>&1; then
      messages_arg=1
    fi
  fi

  # Normalizza l'input in un array JSON standard in formato OpenAI
  if [ -n "${messages_arg}" ]; then
    input_messages_json="$(printf '%s' "${messages_json}" | jq -c 'if type=="array" then . else [.] end' 2>/dev/null || true)"
  else
    if [ -z "${CONTENT:-}" ]; then
      printf 'Error: no MESSAGES_JSON and no CONTENT provided; cannot build payload\n' >&2
      rm -f "$tmpf" 2>/dev/null || true
      return 4
    fi
    input_messages_json="$(jq -n --arg content "${CONTENT:-}" '[{role: "user", content: $content}]' 2>/dev/null)"
  fi

  sys_prompt="${SYSTEM_PROMPT:-}"

  # Costruisce il payload nativo per l'API Gemini tramite jq
  if ! jq -n \
         --argjson messages "${input_messages_json}" \
         --arg system_prompt "${sys_prompt}" \
         --arg temp "${TURE:-}" \
         --arg max_tok "${MAX_TOKENS:-}" \
         '
         # 1) Estrae e unisce le istruzioni di sistema
         ((($messages | map(select(.role == "system") | .content) | join("\n")) + (if $system_prompt != "" then "\n" + $system_prompt else "" end) | sub("^\\s+"; "") | sub("\\s+$"; ""))) as $sys_instruction |

         # 2) Converte i turni di conversazione (mappando "assistant" -> "model")
         ($messages | map(select(.role != "system") | {
           role: (if .role == "assistant" then "model" else "user" end),
           parts: [{text: (.content // "")}]
         })) as $contents |

         # 3) Configura i parametri di generazione (se presenti)
         ({} |
          if $temp != "" then . + {temperature: ($temp | tonumber)} else . end |
          if $max_tok != "" then . + {maxOutputTokens: ($max_tok | tonumber)} else . end
         ) as $gen_config |

         # 4) Compone il payload finale nativo di Gemini
         ({contents: $contents} |
          if $sys_instruction != "" then . + {systemInstruction: {parts: [{text: $sys_instruction}]}} else . end |
          if ($gen_config | keys | length) > 0 then . + {generationConfig: $gen_config} else . end
         )
         ' > "$tmpf" 2>/dev/null; then
    printf 'Error: jq failed to construct the Gemini API payload\n' >&2
    rm -f "$tmpf" 2>/dev/null || true
    return 5
  fi

  if [ -s "$tmpf" ]; then
    if [ "$(tail -c1 "$tmpf" 2>/dev/null || true)" != "" ]; then
      printf '\n' >> "$tmpf" 2>/dev/null || true
    fi
  fi

  if ! jq -e . "$tmpf" >/dev/null 2>&1; then
    printf 'Error: built payload is not valid JSON\n' >&2
    rm -f "$tmpf" 2>/dev/null || true
    return 6
  fi

  # Scrive il payload finale nella destinazione b64 o normale
  if [ "${PAYLOAD##*.}" = "b64" ] && type stage_b64 >/dev/null 2>&1; then
    if stage_b64 "$tmpf" "$PAYLOAD"; then
      rm -f "$tmpf" 2>/dev/null || true
      return 0
    else
      _gemini_write_atomic "$tmpf" "${PAYLOAD}" || cp -f "$tmpf" "${PAYLOAD}" 2>/dev/null || true
      rm -f "$tmpf" 2>/dev/null || true
      return 0
    fi
  fi

  umask 077
  if _gemini_write_atomic "$tmpf" "${PAYLOAD}"; then
    rm -f "$tmpf" 2>/dev/null || true
    chmod 600 "${PAYLOAD}" 2>/dev/null || true
    return 0
  else
    cp -f "$tmpf" "${PAYLOAD}" 2>/dev/null || true
    chmod 600 "${PAYLOAD}" 2>/dev/null || true
    rm -f "$tmpf" 2>/dev/null || true
    return 0
  fi
}

# -------------------------
# gemini_report_error
# -------------------------
gemini_report_error() {
  local resp_file="${1:-}"
  local err_file="${2:-}"
  local msg=""

  if [ -s "$resp_file" ] && jq -e . "$resp_file" >/dev/null 2>&1; then
    msg="$(jq -r '.error?.message // .error? // empty' "$resp_file" 2>/dev/null || true)"
  fi

  if [ -n "$msg" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "API" "Gemini API error: $msg"
    else
      printf 'gemini: ERROR: API: %s\n' "$msg" >&2
    fi
  elif [ -s "$err_file" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "API" "Gemini API call failed. Curl stderr:"
    else
      printf 'gemini: ERROR: API call failed. Curl stderr:\n' >&2
    fi
    head -n 20 "$err_file" >&2 || true
  else
    if type log_error >/dev/null 2>&1; then
      log_error "API" "Gemini API call failed with an unknown error."
    else
      printf 'gemini: ERROR: API call failed with an unknown error.\n' >&2
    fi
  fi
}

# -------------------------
# call_api_gemini (non-streaming)
# -------------------------
call_api_gemini() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$BASH4LLMERRTMP"
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required for provider gemini."
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$BASH4LLMERRNOAPIKEY"
  fi

  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  local key
  key="${!prov_env:-${BASH4LLM_API_KEY:-${GEMINI_API_KEY:-}}}"

  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key not available for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$BASH4LLMERRNOAPIKEY"
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    printf 'Error: payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "payload file missing or empty" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 3
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
    local workdir_dr
    workdir_dr="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_dr%/}/resp.json}"
    umask 077
    jq -n '{choices:[]}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 0
  fi

  local workdir tmpout tmpresp errf api_url model_subst key_trim http_code time_total active_model
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  [ -n "$workdir" ] || return 4

  tmpout="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  tmpresp="$(_mktemp_in_dir_gemini "$workdir")" || return 4
  errf="$(_mktemp_in_dir_gemini "$workdir")" || errf="${workdir%/}/curl.err"

  active_model="${MODEL:-}"
  model_subst="${active_model#models/}"
  if [ -z "$model_subst" ]; then
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    local resp_path="${RESP:-${workdir%/}/resp.json}"
    umask 077
    jq -n --arg err "MODEL not set" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 7
  fi

  api_url="https://generativelanguage.googleapis.com/v1beta/models/${model_subst}:generateContent"
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  dbg "call_api_gemini: url=${api_url}"

  if ! curl "${CURL_BASE_OPTS[@]:-}" --silent --show-error --no-buffer --max-time 120 \
       -H "x-goog-api-key: ${key_trim}" -H "Content-Type: application/json" \
       --data-binary @"$PAYLOAD" -o "$tmpresp" -w '%{http_code} %{time_total}' "$api_url" 2>"$errf" >"$tmpout"; then
    :
  fi

  http_code="$(awk '{print $1}' "$tmpout" 2>/dev/null || true)"
  time_total="$(awk '{print $2}' "$tmpout" 2>/dev/null || true)"

  if [ -z "${http_code:-}" ]; then
    if [ -s "${tmpout:-}" ]; then
      http_code="$(awk '{print $1}' "$tmpout" 2>/dev/null || echo "000")"
      time_total="$(awk '{print $2}' "$tmpout" 2>/dev/null || echo "0")"
    else
      http_code="000"
      time_total="0"
    fi
  fi

  local resp_path="${RESP:-$workdir/resp.json}"

  if [ -s "$tmpresp" ]; then
    _gemini_write_atomic "$tmpresp" "${resp_path}"
  else
    umask 077
    jq -n --arg code "${http_code:-000}" --arg msg "empty response body" '{error:{code:$code,message:$msg}}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
  fi

  if [ -s "${resp_path}" ] && jq -e . "${resp_path}" >/dev/null 2>&1; then
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${resp_path}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      tmpconv="$(_mktemp_in_dir_gemini "$workdir" 2>/dev/null || true)"
      if [ -z "$tmpconv" ]; then
        tmpconv="${workdir%/}/gemini-conv.$$"
        : > "$tmpconv" 2>/dev/null || true
      fi
      umask 077
      jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv"
      _gemini_write_atomic "$tmpconv" "${resp_path}" || { cp -f "$tmpconv" "${resp_path}" 2>/dev/null || true; chmod 600 "${resp_path}" 2>/dev/null || true; }
      rm -f "$tmpconv" 2>/dev/null || true
    fi
  fi

  case "$http_code" in
    2*)
      rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true
      return 0
      ;;
    *)
      gemini_report_error "$tmpresp" "$errf"
      if ! jq -e . "${resp_path}" >/dev/null 2>&1; then
        umask 077
        jq -n --arg code "${http_code:-000}" --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{code:$code,stderr:$stderr}}' > "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
      rm -f "$tmpresp" "$tmpout" "$errf" 2>/dev/null || true
      return 5
      ;;
  esac
}

# -------------------------
# call_api_streaming_gemini (streaming)
# -------------------------
call_api_streaming_gemini() {
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$BASH4LLMERRTMP"
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required for provider gemini."
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$BASH4LLMERRNOAPIKEY"
  fi

  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"
  local key
  key="${!prov_env:-${BASH4LLM_API_KEY:-${GEMINI_API_KEY:-}}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key not available for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$BASH4LLMERRNOAPIKEY"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    local workdir_dr
    workdir_dr="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_dr%/}/resp.json}"
    umask 077
    jq -n '{choices:[]}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 0
  fi

  local workdir RESP_RAW errf api_url model_subst key_trim rc active_model
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  [ -n "$workdir" ] || return 4

  RESP_RAW="$(_mktemp_in_dir_gemini "$workdir")" || RESP_RAW="${workdir%/}/resp.raw"
  errf="$(_mktemp_in_dir_gemini "$workdir")" || errf="${workdir%/}/curl.err"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true

  active_model="${MODEL:-}"
  model_subst="${active_model#models/}"
  if [ -z "$model_subst" ]; then
    printf '%s\n' "Error: MODEL not set. Set MODEL to a Gemini model name (e.g., gemini-2.5-flash)." >&2
    local resp_path="${RESP:-${workdir%/}/resp.json}"
    umask 077
    jq -n --arg err "MODEL not set" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return 7
  fi

  # Utilizza l'endpoint :streamGenerateContent?alt=sse
  api_url="https://generativelanguage.googleapis.com/v1beta/models/${model_subst}:streamGenerateContent?alt=sse"
  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  dbg "call_api_streaming_gemini: url=${api_url}"

  curl "${CURL_BASE_OPTS[@]:-}" -H "x-goog-api-key: ${key_trim}" -H "Content-Type: application/json" --no-buffer --max-time 0 --data-binary @"$PAYLOAD" "$api_url" 2>"$errf" | \
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      data:\ * ) line="${line#data: }" ;;
      '' ) continue ;;
    esac

    if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      chunk="$(printf '%s' "$line" | jq -r 'try (if .candidates then (.candidates[]?.content?.parts[]?.text // empty) elif .content then (.content?.parts[]?.text // empty) elif .outputs then (.outputs[]?.content?.parts[]?.text // empty) else empty end) catch empty' 2>>"$errf" || true)"
      if [ -n "$chunk" ]; then
        # CORRETTO: Stampa il chunk di testo grezzo direttamente a schermo per simulare la digitazione fluida
        printf '%s' "$chunk"
      fi
    else
      printf '%s\n' "$line"
    fi

    printf '%s\n' "$line" >> "$RESP_RAW"
  done

  rc=${PIPESTATUS[0]:-0}
  if [ "$rc" -ne 0 ]; then
    local resp_path="${RESP:-${workdir%/}/resp.json}"
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      gemini_report_error "$RESP_RAW" "$errf"
      if ! jq -e . "${resp_path}" >/dev/null 2>&1; then
        umask 077
        _gemini_write_atomic "$RESP_RAW" "${resp_path}" 2>/dev/null || cp -f "$RESP_RAW" "${resp_path}" 2>/dev/null || true
        chmod 600 "${resp_path}" 2>/dev/null || true
      fi
    else
      printf '%s\n' "gemini: errore durante lo streaming. Vedi curl stderr (head):" >&2
      head -n 50 "$errf" >&2 || true
      umask 077
      jq -n --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{stderr:$stderr}}' > "${resp_path}" 2>/dev/null || true
      chmod 600 "${resp_path}" 2>/dev/null || true
    fi
    return 6
  fi

  local resp_path="${RESP:-$workdir/resp.json}"

  if [ -n "${resp_path:-}" ]; then
    _gemini_write_atomic "$RESP_RAW" "${resp_path}"
  fi

  if [ -n "${resp_path:-}" ] && [ -s "${resp_path}" ] && jq -e . "${resp_path}" >/dev/null 2>&1; then
    extracted_text="$(jq -r '([(.candidates[]?.content?.parts[]?.text), (.content?.parts[]?.text), (.outputs[]?.content?.parts[]?.text)] | map(select(.!=null and .!="")) | .[0]) // empty' "${resp_path}" 2>/dev/null || true)"
    if [ -n "${extracted_text}" ]; then
      tmpconv="$(_mktemp_in_dir_gemini "$workdir" 2>/dev/null || true)"
      if [ -z "$tmpconv" ]; then
        tmpconv="${workdir%/}/gemini-conv.$$"
        : > "$tmpconv" 2>/dev/null || true
      fi
      umask 077
      jq -n --arg text "$extracted_text" '{choices:[{message:{content:$text}}]}' > "$tmpconv"
      _gemini_write_atomic "$tmpconv" "${resp_path}" || { cp -f "$tmpconv" "${resp_path}" 2>/dev/null || true; chmod 600 "${resp_path}" 2>/dev/null || true; }
      rm -f "$tmpconv" 2>/dev/null || true
    fi
  fi

  return 0
}
# -------------------------
# refresh_models_gemini
# -------------------------
refresh_models_gemini() {
  local outpath="${1:-$(_get_models_file_gemini)}"
  local prov_env
  prov_env="$(provider_api_env_var_name "gemini")"

  local provider_url_file
  if type canonical_provider_url_file >/dev/null 2>&1; then
    provider_url_file="$(canonical_provider_url_file)"
  else
    provider_url_file="${BASH4LLM_CONFIG_DIR:-${BASH4LLM_DIR:-./bash4llm.d}}/provider-url.gemini"
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    if [ -z "$outpath" ]; then
      log_error "MODELREFRESH" "MODELS file path not provided."
      return "$BASH4LLMERRTMP"
    fi
    umask 077
    mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
    local tmp_models
    tmp_models="$(_mktemp_in_dir_gemini "$(dirname "$outpath")" 2>/dev/null || true)" || tmp_models="${outpath}.tmp"
    printf '%s\n' "gemini-2.5-flash" "gemini-3.5-flash" "gemini-3.5-pro" > "$tmp_models" 2>/dev/null || true

    if type b64_atomic_write >/dev/null 2>&1; then
      if ! b64_atomic_write "${outpath}.b64" 10 < "$tmp_models"; then
        rm -f "$tmp_models" 2>/dev/null || true
        return "$BASH4LLMERRTMP"
      fi
      lockfile="${MODELS_LOCK:-${outpath}.lock}"
      lock_exec "$lockfile" 10 -- sh -c '
        set -e
        manifest_b64="$1"
        dest="$2"
        base64 ${B64_DECODE_OPT:-} < "$manifest_b64" > "$dest"
        chmod 600 "$dest" 2>/dev/null || true
      ' _ "${outpath}.b64" "$outpath" || { rm -f "$tmp_models" 2>/dev/null || true; return "$BASH4LLMERRTMP"; }
    else
      mv "$tmp_models" "${outpath}.new" 2>/dev/null || cp -f "$tmp_models" "${outpath}.new" 2>/dev/null || true
      chmod 600 "${outpath}.new" 2>/dev/null || true
      mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
    fi
    chmod 600 "$outpath" 2>/dev/null || true
    rm -f "$tmp_models" 2>/dev/null || true

    umask 077
    local provider_url_value="https://generativelanguage.googleapis.com"
    mkdir -p "$(dirname "$provider_url_file")" 2>/dev/null || true
    local tmp_pu
    tmp_pu="$(_mktemp_in_dir_gemini "$(dirname "$provider_url_file")" 2>/dev/null || true)" || tmp_pu="${provider_url_file}.tmp"
    printf '%s\n' "${provider_url_value}" > "$tmp_pu" 2>/dev/null || true

    if [ -n "${tmp_pu:-}" ] && [ -s "$tmp_pu" ]; then
      if type atomic_write >/dev/null 2>&1; then
        if ! cat "$tmp_pu" | atomic_write "$provider_url_file"; then
          cp -f "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || true
          mv -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || true
        fi
      else
        mv "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || cp -f "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || true
        chmod 600 "${provider_url_file}.new" 2>/dev/null || true
        mv -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || cp -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || true
      fi
      chmod 600 "$provider_url_file" 2>/dev/null || true
    fi

    BASH4LLM_PROVIDER_URL="${provider_url_value}"
    return 0
  fi

  if ! ensure_api_key_for_provider "gemini"; then
    log_error "APIKEY" "API key required to refresh models."
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key required to refresh models" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$BASH4LLMERRNOAPIKEY"
  fi

  local key="${!prov_env:-${BASH4LLM_API_KEY:-${GEMINI_API_KEY:-}}}"
  if [ -z "$key" ]; then
    log_error "APIKEY" "API key not available in env $prov_env"
    local workdir_err
    workdir_err="$(_get_work_tmpdir_gemini)"
    local resp_path="${RESP:-${workdir_err%/}/resp.json}"
    umask 077
    jq -n --arg err "API key not available for provider gemini" '{error:$err}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    return "$BASH4LLMERRNOAPIKEY"
  fi

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$BASH4LLMERRTMP"
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$BASH4LLMERRTMP"
  fi

  local workdir tmpd out errf curlout parsed tmpfinal http_code time_total key_trim tmpout lockfile resp_path
  workdir="${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}"
  [ -n "$workdir" ] || return "$BASH4LLMERRTMP"

  tmpd="$(mktemp -d -p "$workdir" gemini-models.XXXX 2>/dev/null || true)" || return "$BASH4LLMERRTMP"

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"
  parsed="$tmpd/parsed_models.txt"
  tmpfinal="$tmpd/final_models.txt"
  resp_path="${RESP:-${workdir%/}/resp.json}"

  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}' 2>/dev/null || printf '%s' "$key")"

  local api_url="https://generativelanguage.googleapis.com/v1beta/models"
  api_url="${api_url}?pageSize=${MAX_MODELS:-200}&key=${key_trim}"

  rm -f "$out" "$errf" "$curlout" 2>/dev/null || true
  if ! curl "${CURL_BASE_OPTS[@]:-}" -H "Content-Type: application/json" --silent --show-error --no-buffer --max-time 120 -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout"; then
    log_error "MODELREFRESH" "HTTP request to Gemini models endpoint failed."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    umask 077
    jq -n --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{stderr:$stderr}}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$BASH4LLMERRAPI"
  fi

  if [ -s "${curlout:-}" ]; then
    read -r http_code time_total < "$curlout" 2>/dev/null || {
      http_code="$(awk '{print $1}' "$curlout" 2>/dev/null || echo "000")"
      time_total="$(awk '{print $2}' "$curlout" 2>/dev/null || echo "0")"
    }
  else
    http_code="000"
    time_total="0"
  fi

  http_code="${http_code:-000}"

  if [ "${http_code:0:1}" != "2" ]; then
    log_error "MODELREFRESH" "models.list HTTP code: $http_code"
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    umask 077
    jq -n --arg code "${http_code:-000}" --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{code:$code,stderr:$stderr}}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$BASH4LLMERRAPI"
  fi

  if ! jq -e . "$out" >/dev/null 2>&1; then
    log_error "MODELREFRESH" "Invalid JSON received from Gemini models endpoint."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    umask 077
    jq -n --arg stderr "$(head -n 200 "$errf" 2>/dev/null || true)" '{error:{stderr:$stderr}}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$BASH4LLMERRAPI"
  fi

  jq -r '.models[]?.name // empty' "$out" | awk 'NF{print}' | sort -u > "$parsed" 2>/dev/null || true

  if [ ! -s "$parsed" ]; then
    log_error "MODELREFRESH" "parsed models list empty"
    umask 077
    jq -n --arg msg "parsed models list empty" '{error:$msg}' > "${resp_path}" 2>/dev/null || true
    chmod 600 "${resp_path}" 2>/dev/null || true
    rm -rf "$tmpd"
    return "$BASH4LLMERRAPI"
  fi

  awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' "$parsed" > "$tmpfinal" || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true
  tmpout="$(_mktemp_in_dir_gemini "$(dirname "$outpath")" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"

  if [ -n "${tmpfinal:-}" ] && [ -s "$tmpfinal" ]; then
    cat "$tmpfinal" > "$tmpout"
  else
    : > "$tmpout"
  fi

  umask 077
  if type b64_atomic_write >/dev/null 2>&1; then
    if ! b64_atomic_write "${outpath}.b64" 10 < "$tmpout"; then
      log_error "MODELREFRESH" "failed to stage models file"
      rm -f "$tmpout" 2>/dev/null || true
      rm -rf "$tmpd"
      return "$BASH4LLMERRTMP"
    fi
    lockfile="${MODELS_LOCK:-${outpath}.lock}"
    lock_exec "$lockfile" 10 -- sh -c '
      set -e
      manifest_b64="$1"
      dest="$2"
      base64 ${B64_DECODE_OPT:-} < "$manifest_b64" > "$dest"
      chmod 600 "$dest" 2>/dev/null || true
    ' _ "${outpath}.b64" "$outpath" || { log_error "MODELREFRESH" "failed to write models file under lock"; rm -rf "$tmpd"; return "$BASH4LLMERRTMP"; }
  else
    mv "$tmpout" "${outpath}.new" 2>/dev/null || cp -f "$tmpout" "${outpath}.new" 2>/dev/null || true
    chmod 600 "${outpath}.new" 2>/dev/null || true
    mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
  fi

  chmod 600 "$outpath" 2>/dev/null || true

  umask 077
  local provider_url_value="https://generativelanguage.googleapis.com"
  mkdir -p "$(dirname "$provider_url_file")" 2>/dev/null || true
  local tmp_pu
  tmp_pu="$(_mktemp_in_dir_gemini "$(dirname "$provider_url_file")" 2>/dev/null || true)" || tmp_pu="${provider_url_file}.tmp"
  printf '%s\n' "${provider_url_value}" > "$tmp_pu" 2>/dev/null || true

  if [ -n "${tmp_pu:-}" ] && [ -s "$tmp_pu" ]; then
    if type atomic_write >/dev/null 2>&1; then
      if ! cat "$tmp_pu" | atomic_write "$provider_url_file"; then
        cp -f "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || true
        mv -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || true
      fi
    else
      mv "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || cp -f "$tmp_pu" "${provider_url_file}.new" 2>/dev/null || true
      chmod 600 "${provider_url_file}.new" 2>/dev/null || true
      mv -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || cp -f "${provider_url_file}.new" "$provider_url_file" 2>/dev/null || true
    fi
    chmod 600 "$provider_url_file" 2>/dev/null || true
  fi

  BASH4LLM_PROVIDER_URL="${provider_url_value}"

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
}

# -------------------------
# auto_select_model_gemini
# -------------------------
auto_select_model_gemini() {
  local file="$(_get_models_file_gemini)"
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
# end of file
