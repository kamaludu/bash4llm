#!/usr/bin/env bash
# =============================================================================
# Bash4LLM — Bash-first wrapper for the Groq API
# File: extras/providers/huggingface.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/bash4llm
# =============================================================================

# When sourced, avoid enabling strict mode globally.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Requirements: bash curl jq base64

HFAPIKEY="${HFAPIKEY:-}"

# Default helpers for tmpdir and mktemp in project-local tmpdir
_get_work_tmpdir_hf() {
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

_mktemp_in_dir_hf() {
  local dir="$1" tmpf
  [ -z "$dir" ] && return 1
  [ ! -d "$dir" ] && return 1
  tmpf="$(mktemp -p "$dir" hf-XXXX 2>/dev/null || true)"
  [ -z "$tmpf" ] && return 1
  printf '%s' "$tmpf"
  return 0
}

# -------------------------
# HF endpoints config helpers
# -------------------------
hf_default_endpoints_file() {
  local cfgdir
  if [ -n "${BASH4LLM_CONFIG_DIR:-}" ]; then
    cfgdir="${BASH4LLM_CONFIG_DIR}"
  else
    # fallback for standalone sourcing
    local base
    base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd 2>/dev/null || pwd)"
    cfgdir="${base}/bash4llm.d/config"
  fi
  printf '%s' "${cfgdir%/}/providers/hf_endpoints"
}

# Load endpoints file
hf_load_endpoints() {
  local f
  f="$(hf_default_endpoints_file)"
  if [ ! -f "$f" ]; then
    mkdir -p "$(dirname "$f")" 2>/dev/null || true
    : > "$f" 2>/dev/null || true
    chmod 644 "$f" 2>/dev/null || true
  fi
  printf '%s' "$f"
  return 0
}

# Get endpoint URL for a model name
hf_get_endpoint_for_model() {
  local model="$1" f
  f="$(hf_load_endpoints)" || return 1
  awk -F'|' -v m="$model" 'BEGIN{OFS=FS} $1==m {print $2; exit}' "$f" 2>/dev/null || true
}

# List endpoints
hf_list_endpoints() {
  local f i=0
  f="$(hf_load_endpoints)" || return 1
  if [ ! -s "$f" ]; then
    printf 'No Hugging Face endpoints registered (file: %s)\n' "$f" >&2
    return 0
  fi
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Sostituito controllo case con test di stringa nativo per evitare problemi di commenti
    [[ "$line" == "#"* ]] && continue
    model="$(printf '%s' "$line" | awk -F'|' '{print $1}')"
    url="$(printf '%s' "$line" | awk -F'|' '{print $2}')"
    i=$((i+1))
    printf '%d) %s -> %s\n' "$i" "$model" "$url"
  done < "$f"
  return 0
}

# Add an endpoint
hf_add_endpoint() {
  local model="$1" url="$2" f tmp
  f="$(hf_load_endpoints)" || return 1

  case "$url" in
    https://*) ;;
    *) 
      if type log_error >/dev/null 2>&1; then
        log_error "HF" "Endpoint URL must start with https://"
      else
        printf 'bash4llm: ERROR: HF: Endpoint URL must start with https://\n' >&2
      fi
      return 1 
      ;;
  esac

  # Verifica corretta del duplicato (esce con 0 se trova corrispondenze)
  if awk -F'|' -v m="$model" '$1==m{found=1; exit} END{exit !found}' "$f" 2>/dev/null; then
    if type log_error >/dev/null 2>&1; then
      log_error "HF" "Model '$model' already present in endpoints file"
    else
      printf 'bash4llm: ERROR: HF: Model '\''%s'\'' already present in endpoints file\n' "$model" >&2
    fi
    return 1
  fi

  tmp="$(_mktemp_in_dir_hf "$(dirname "$f")" 2>/dev/null || true)"
  [ -z "$tmp" ] && tmp="${f}.tmp"

  printf '%s|%s\n' "$model" "$url" > "$tmp"
  if [ -s "$f" ]; then
    cat "$f" >> "$tmp" 2>/dev/null || true
  fi

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp" | atomic_write "$f" || mv -f "$tmp" "$f"
  else
    mv -f "$tmp" "$f" 2>/dev/null || cp -f "$tmp" "$f" 2>/dev/null || true
  fi
  chmod 644 "$f" 2>/dev/null || true
  rm -f "$tmp" 2>/dev/null || true
  return 0
}

# Remove endpoint
hf_remove_endpoint() {
  local model="$1" f tmp
  f="$(hf_load_endpoints)" || return 1
  if ! awk -F'|' -v m="$model" '$1==m{found=1} END{exit !found}' "$f" 2>/dev/null; then
    if type log_error >/dev/null 2>&1; then
      log_error "HF" "Model '$model' not found in endpoints file"
    else
      printf 'bash4llm: ERROR: HF: Model '\''%s'\'' not found in endpoints file\n' "$model" >&2
    fi
    return 1
  fi
  tmp="$(_mktemp_in_dir_hf "$(dirname "$f")" 2>/dev/null || true)"
  [ -z "$tmp" ] && tmp="${f}.tmp"

  awk -F'|' -v m="$model" '$1!=m {print}' "$f" > "$tmp" 2>/dev/null || true

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp" | atomic_write "$f" || mv -f "$tmp" "$f"
  else
    mv -f "$tmp" "$f" 2>/dev/null || cp -f "$tmp" "$f" 2>/dev/null || true
  fi
  chmod 644 "$f" 2>/dev/null || true
  rm -f "$tmp" 2>/dev/null || true
  return 0
}

# -------------------------
# buildpayload_huggingface
# -------------------------
buildpayload_huggingface() {
  local workdir tmp_payload model_in_file model_to_use user_prompt joined

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $BASH4LLMERRTMP
  fi

  workdir="$(_get_work_tmpdir_hf)" || return $BASH4LLMERRTMP
  tmp_payload="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP
  umask 077

  PAYLOAD="${PAYLOAD:-${workdir}/payload.json}"
  RESP="${RESP:-${workdir}/resp.json}"

  # Rilevamento formato endpoint (OpenAI chat completions o legacy)
  local endpoint_url is_openai=1
  endpoint_url="$(hf_get_endpoint_for_model "$MODEL" 2>/dev/null || true)"
  if [ -n "$endpoint_url" ] && [[ "$endpoint_url" != */v1/chat/completions ]]; then
    is_openai=0
  fi

  if [ "$is_openai" -eq 1 ]; then
    # Payload standard OpenAI Chat Completions per router.huggingface.co/v1
    local messages_arr="[]"
    if [ -n "${JSON_INPUT:-}" ]; then
      if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
        jq --arg model "$MODEL" --argjson max_tokens "${MAX_TOKENS:-256}" \
           '.model = $model | .max_tokens = ($max_tokens|tonumber)' "$JSON_INPUT" > "$tmp_payload"
      elif jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
        user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
        jq -n --arg model "$MODEL" --arg prompt "$user_prompt" --argjson max_tokens "${MAX_TOKENS:-256}" \
           '{model:$model, messages:[{role:"user", content:$prompt}], max_tokens:($max_tokens|tonumber)}' > "$tmp_payload"
      else
        cat "$JSON_INPUT" > "$tmp_payload"
      fi
    else
      # Gestione della cronologia di sessione (BUILD_MESSAGES_FILE)
      if [ -n "${BUILD_MESSAGES_FILE:-}" ] && is_valid_json_file "${BUILD_MESSAGES_FILE}"; then
        local history_msgs
        history_msgs="$(jq -c '.messages // []' "$BUILD_MESSAGES_FILE" 2>/dev/null || true)"
        if printf '%s' "$history_msgs" | jq -e 'type=="array" and (length>0)' >/dev/null 2>&1; then
          # Accoda il prompt corrente (CONTENT) alla cronologia della sessione
          messages_arr="$(jq -n --argjson hist "$history_msgs" --arg usr "$CONTENT" '$hist + [{role:"user", content:$usr}]')"
        fi
      fi

      # Se non c'è cronologia, inizializza l'array con il solo prompt corrente
      if [ "$messages_arr" = "[]" ]; then
        if [ -n "${SYSTEM_PROMPT:-}" ]; then
          messages_arr="$(jq -n --arg sys "$SYSTEM_PROMPT" --arg usr "$CONTENT" '[{role:"system", content:$sys}, {role:"user", content:$usr}]')"
        else
          messages_arr="$(jq -n --arg usr "$CONTENT" '[{role:"user", content:$usr}]')"
        fi
      else
        # Se la cronologia è presente e il prompt corrente è stato accodato,
        # inserisci in testa il SYSTEM_PROMPT se definito
        if [ -n "${SYSTEM_PROMPT:-}" ]; then
          messages_arr="$(jq -n --argjson msgs "$messages_arr" --arg sys "$SYSTEM_PROMPT" '[{role:"system", content:$sys}] + $msgs')"
        fi
      fi

      local stream_val="false"
      if [ "${STREAM_MODE:-0}" -eq 1 ]; then
        stream_val="true"
      fi
      jq -n --arg model "$MODEL" --argjson messages "$messages_arr" --argjson max_tokens "${MAX_TOKENS:-256}" --argjson stream "$stream_val" \
         '{model:$model, messages:$messages, max_tokens:($max_tokens|tonumber), stream:$stream}' > "$tmp_payload"
    fi
  else
    # Payload legacy text-generation
    if [ -n "${JSON_INPUT:-}" ]; then
      if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
        jq --arg model "$MODEL" --argjson max_tokens "${MAX_TOKENS:-256}" \
           '.model = $model | .max_tokens = ($max_tokens|tonumber)' "$JSON_INPUT" > "$tmp_payload"
      elif jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
        user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
        jq -n --arg inputs "$user_prompt" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
           '{inputs:$inputs, parameters:$params}' > "$tmp_payload"
      else
        cat "$JSON_INPUT" > "$tmp_payload"
      fi
    else
      if [ -n "${SYSTEM_PROMPT:-}" ]; then
        joined="$(printf 'System: %s\n\nUser: %s' "$SYSTEM_PROMPT" "$CONTENT")"
      else
        joined="$CONTENT"
      fi
      jq -n --arg inputs "$joined" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
         '{inputs:$inputs, parameters:$params}' > "$tmp_payload"
    fi
  fi

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp_payload" | atomic_write "$PAYLOAD"
  else
    mv -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
  fi
  chmod 600 "$PAYLOAD" 2>/dev/null || true
  rm -f "$tmp_payload" 2>/dev/null || true

  return 0
}

# -------------------------
# call_api_huggingface
# -------------------------
call_api_huggingface() {
  local prov_env

  if type ensure_api_key_for_provider >/dev/null 2>&1; then
    if ! ensure_api_key_for_provider "huggingface"; then
      if type log_error >/dev/null 2>&1; then
        log_error "APIKEY" "HF API key required to call Hugging Face."
      else
        printf 'bash4llm: ERROR: APIKEY: HF API key required to call Hugging Face.\n' >&2
      fi
      return $BASH4LLMERRNOAPIKEY
    fi
  fi

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    HFAPIKEY="${!prov_env:-${HFAPIKEY:-}}"
  fi

  if [ -z "${HFAPIKEY:-}" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "APIKEY" "HF API key not set (env ${prov_env:-HUGGINGFACE_API_KEY})."
    else
      printf 'bash4llm: ERROR: APIKEY: HF API key not set.\n' >&2
    fi
    return $BASH4LLMERRNOAPIKEY
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $BASH4LLMERRTMP
  fi

  local workdir
  workdir="$(_get_work_tmpdir_hf)" || return $BASH4LLMERRTMP
  PAYLOAD="${PAYLOAD:-${workdir}/payload.json}"
  RESP="${RESP:-${workdir}/resp.json}"
  ERRF="${ERRF:-${workdir}/curl.err}"

  if [ "${DEBUG:-0}" -ne 0 ]; then
    if type dbg >/dev/null 2>&1; then
      dbg "PAYLOAD path: ${PAYLOAD:-<unset>}"
      dbg "RESP path: ${RESP:-<unset>}"
    else
      printf 'bash4llm: DEBUG: PAYLOAD path: %s\n' "${PAYLOAD:-<unset>}" >&2
      printf 'bash4llm: DEBUG: RESP path: %s\n' "${RESP:-<unset>}" >&2
    fi
    printf 'bash4llm: DEBUG: using payload file: %s\n' "${PAYLOAD:-<unset>}" >&2
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    if type log_error >/dev/null 2>&1; then
      log_error "HTTP" "payload file missing or empty: ${PAYLOAD:-<unset>}"
    else
      printf 'bash4llm: ERROR: HTTP: payload file missing or empty: %s\n' "${PAYLOAD:-<unset>}" >&2
    fi
    return $BASH4LLMERRTMP
  fi

  if [ "${DRY_RUN:-0}" -ne 0 ]; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
    return 0
  fi

  local endpoint_url api_url
  endpoint_url="$(hf_get_endpoint_for_model "$MODEL" 2>/dev/null || true)"
  if [ -z "${endpoint_url:-}" ]; then
    api_url="https://router.huggingface.co/v1/chat/completions"
    if [ "${DEBUG:-0}" -ne 0 ]; then
      if type log_info >/dev/null 2>&1; then
        log_info "CALL" "No custom endpoint found; using unified serverless router: $api_url"
      else
        printf 'bash4llm: INFO: CALL: No custom endpoint found; using unified serverless router: %s\n' "$api_url" >&2
      fi
    fi
  else
    api_url="${endpoint_url%/}"
  fi

  if [ "${DEBUG:-0}" -ne 0 ]; then
    if type dbg >/dev/null 2>&1; then
      dbg "Repro curl (redacted): curl -H 'Authorization: Bearer <REDACTED>' -H 'Content-Type: application/json' --data-binary @\"$PAYLOAD\" \"$api_url\""
    else
      printf 'bash4llm: DEBUG: Repro curl (redacted): curl -H '\''Authorization: Bearer <REDACTED>'\'' -H '\''Content-Type: application/json'\'' --data-binary @"%s" "%s"\n' "$PAYLOAD" "$api_url" >&2
    fi
  fi

  local tmpout tmpresp hdr_file http_result http_code time_total http_ct http_body err_text
  tmpout="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP
  tmpresp="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP
  hdr_file="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP

  : > "$tmpout" 2>/dev/null || true
  : > "$ERRF" 2>/dev/null || true
  : > "$tmpresp" 2>/dev/null || true
  : > "$hdr_file" 2>/dev/null || true

  http_result="$(curl "${CURL_BASE_OPTS[@]:-}" \
    -sS -D "$hdr_file" \
    -H "Authorization: Bearer $HFAPIKEY" \
    -H "Content-Type: application/json" \
    --data-binary @"$PAYLOAD" \
    -o "$tmpresp" -w '%{http_code} %{time_total}' \
    "$api_url" 2>"$ERRF" || true)"

  read -r http_code time_total <<EOF
$http_result
EOF
  http_code="${http_code:-000}"
  http_ct="$(tr '[:upper:]' '[:lower:]' < "$hdr_file" 2>/dev/null | grep -i '^content-type:' || true)"
  http_body="$(cat "$tmpresp" 2>/dev/null || true)"

  if [ -s "$tmpresp" ]; then
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmpresp" | atomic_write "${RESP}" || cp -f "$tmpresp" "${RESP}" 2>/dev/null || true
    else
      cp -f "$tmpresp" "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true
    fi
  else
    : > "${RESP}"
  fi

  rm -f "$tmpout" "$hdr_file" "$ERRF" 2>/dev/null || true

  case "$http_code" in
    2*)
      if printf '%s' "$http_ct" | grep -q 'application/json'; then
        # cat "${RESP}" || printf '%s' "$http_body"  <- Silenziato per evitare la duplicazione del JSON grezzo
        return 0
      else
        if [ "${DEBUG:-0}" -ne 0 ]; then
          if type dbg >/dev/null 2>&1; then
            dbg "HF non-json response (truncated): $(printf '%s' "$http_body" | head -c 2048)"
          else
            printf 'bash4llm: DEBUG: HF non-json response (truncated): %s\n' "$(printf '%s' "$http_body" | head -c 2048)" >&2
          fi
        fi
        if type log_error >/dev/null 2>&1; then
          log_error "HTTP" "API returned non-JSON response (status $http_code). See debug logs."
        else
          printf 'bash4llm: ERROR: HTTP: API returned non-JSON response (status %s).\n' "$http_code" >&2
        fi
        return $BASH4LLMERRAPI
      fi
      ;;
    *)
      if printf '%s' "$http_body" | grep -qi '<pre'; then
        err_text="$(printf '%s' "$http_body" | sed -n 's/.*<pre[^>]*>\(.*\)<\/pre>.*/\1/p' | sed 's/<[^>]*>//g' | awk '{$1=$1;print}')"
      else
        err_text="$(printf '%s' "$http_body" | sed 's/<[^>]*>/ /g' | tr -s '[:space:]' ' ' | awk '{print; exit}')"
      fi
      err_text="$(printf '%s' "$err_text" | sed -n '1,6p' | awk '{$1=$1;print}')"

      if [ -n "$err_text" ]; then
        if type log_error >/dev/null 2>&1; then
          log_error "HTTP" "API error (status $http_code): $err_text"
        else
          printf 'bash4llm: ERROR: HTTP: API error (status %s): %s\n' "$http_code" "$err_text" >&2
        fi
      else
        if type log_error >/dev/null 2>&1; then
          log_error "HTTP" "API error (status $http_code). See debug logs for details."
        else
          printf 'bash4llm: ERROR: HTTP: API error (status %s).\n' "$http_code" >&2
        fi
      fi

      printf '{"error":"HTTP %s","message":%s}\n' "$http_code" "$(printf '%s' "$err_text" | jq -R -s . 2>/dev/null || printf 'null')" > "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true
      return $BASH4LLMERRAPI
      ;;
  esac
}

# -------------------------
# call_api_streaming_huggingface
# -------------------------
call_api_streaming_huggingface() {
  local prov_env

  if type ensure_api_key_for_provider >/dev/null 2>&1; then
    if ! ensure_api_key_for_provider "huggingface"; then
      log_error "APIKEY" "HF API key required to call Hugging Face."
      return $BASH4LLMERRNOAPIKEY
    fi
  fi

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    HFAPIKEY="${!prov_env:-${HFAPIKEY:-}}"
  fi

  if [ -z "${HFAPIKEY:-}" ]; then
    log_error "APIKEY" "HF API key not set."
    return $BASH4LLMERRNOAPIKEY
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    return 0
  fi

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $BASH4LLMERRTMP
  fi

  local api_url rc RESP_RAW workdir hdr_file ERRF
  workdir="$(_get_work_tmpdir_hf)" || return $BASH4LLMERRTMP
  RESP_RAW="${RESP_RAW:-${workdir}/resp.raw}"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true
  ERRF="${ERRF:-${workdir}/curl.err}"
  RESP="${RESP:-$workdir/resp.json}"
  hdr_file="$(_mktemp_in_dir_hf "$workdir")" || return $BASH4LLMERRTMP

  local endpoint_url
  endpoint_url="$(hf_get_endpoint_for_model "$MODEL" 2>/dev/null || true)"
  if [ -z "${endpoint_url:-}" ]; then
    api_url="https://router.huggingface.co/v1/chat/completions"
  else
    api_url="${endpoint_url%/}"
  fi

  curl "${CURL_BASE_OPTS[@]:-}" \
       -sS -D "$hdr_file" \
       -H "Authorization: Bearer $HFAPIKEY" \
       -H "Content-Type: application/json" \
       --no-buffer \
       --data-binary @"$PAYLOAD" \
       "$api_url" \
       2>"$ERRF" | tee -a "$RESP_RAW" | \
  while IFS= read -r line; do
    case "$line" in
      'data: [DONE]'|'data:[DONE]') break ;;
      data:\ * )
        json="${line#data: }"
        raw="$(printf '%s' "$json" | jq -j 'try (if type=="string" then fromjson else . end | .choices[]?.delta?.content // .choices[]?.message?.content // empty) catch empty' 2>>"$ERRF" || true)"
        [ -n "$raw" ] && printf '%s' "$raw"
        ;;
      *) ;;
    esac
  done

  rc=${PIPESTATUS[0]:-0}
  [ "$rc" -ne 0 ] && {
    dbg "curl stderr (head):"; head -n 50 "$ERRF" >&2 || true
    rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
    return $BASH4LLMERRCURL_FAILED
  }

  : > "$workdir/resp.lines" 2>/dev/null || true
  grep -E '^data:' "$RESP_RAW" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' > "$workdir/resp.lines" 2>/dev/null || true

  : > "$workdir/resp.valid.jsons" 2>/dev/null || true
  while IFS= read -r _line; do
    if printf '%s' "$_line" | jq -e . >/dev/null 2>&1; then
      printf '%s\n' "$_line" >> "$workdir/resp.valid.jsons"
    fi
  done < "$workdir/resp.lines"

  if [ -s "$workdir/resp.valid.jsons" ]; then
    jq -s '.' "$workdir/resp.valid.jsons" > "$workdir/resp.chunks.json" 2>/dev/null || true
    if type atomic_write >/dev/null 2>&1; then
      cat "$workdir/resp.chunks.json" | atomic_write "${RESP:-$workdir/resp.json}" "${BASH4LLM_LOCK_TIMEOUT_TMP:-}" || cp -f "$workdir/resp.chunks.json" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    else
      cp -f "$workdir/resp.chunks.json" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi
  else
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      cp -f "$RESP_RAW" "${RESP:-$workdir/resp.json}" 2>/dev/null || true
    fi
  fi

  rm -f "$hdr_file" "$ERRF" "$workdir/resp.lines" "$workdir/resp.valid.jsons" "$workdir/resp.chunks.json" 2>/dev/null || true
  return 0
}

# -------------------------
# refresh_models_huggingface
# -------------------------
refresh_models_huggingface() {
  local outpath="${1:-${MODELS_FILE:-}}"
  local f tmpd tmpout

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$BASH4LLMERRTMP"
  fi

  f="$(hf_load_endpoints)" || return "$BASH4LLMERRTMP"

  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$BASH4LLMERRTMP"
  fi
  tmpd="$(_get_work_tmpdir_hf)" || tmpd="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}"
  tmpout="$(_mktemp_in_dir_hf "$tmpd" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"

  awk -F'|' 'NF && $1!~/^#/ {print $1}' "$f" | awk 'NF{print}' | sort -u > "$tmpout" 2>/dev/null || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmpout" | atomic_write "$outpath"
  else
    mv "$tmpout" "${outpath}.new" 2>/dev/null || cp -f "$tmpout" "${outpath}.new" 2>/dev/null || true
    chmod 600 "${outpath}.new" 2>/dev/null || true
    mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
  fi

  chmod 600 "$outpath" 2>/dev/null || true
  log_info "MODELREFRESH" "Hugging Face models refreshed from local endpoints and saved to: $outpath"
  return 0
}

validate_model_huggingface() {
  local model="$1"
  if [ "$model" = "deepseek-ai/DeepSeek-R1" ] || [ "$model" = "deepseek-ai/DeepSeek-R1:fastest" ]; then
    return 0
  fi
  if [ -f "$MODELS_FILE" ] && [ -s "$MODELS_FILE" ]; then
    grep -x -F -q "$model" "$MODELS_FILE" 2>/dev/null
    return $?
  fi
  return 0
}

auto_select_model_huggingface() {
  local file="$MODELS_FILE" result=""
  if [ -f "$file" ] && [ -s "$file" ]; then
    result="$(awk 'NF{print; exit}' "$file" 2>/dev/null || true)"
    printf '%s' "$result"
    return 0
  fi
  printf ''
  return 0
}
