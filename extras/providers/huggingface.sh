#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/providers/huggingface.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================

# When sourced, avoid enabling strict mode globally.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

HFAPIKEY="${HFAPIKEY:-}"

_get_work_tmpdir_hf() {
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
# buildpayload_huggingface
# -------------------------
buildpayload_huggingface() {
  local workdir tmp_payload model_in_file model_to_use user_prompt joined

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $GROQBASHERRTMP
  fi

  workdir="$(_get_work_tmpdir_hf)" || return $GROQBASHERRTMP
  tmp_payload="$(_mktemp_in_dir_hf "$workdir")" || return $GROQBASHERRTMP
  umask 077

  if [ -n "${JSON_INPUT:-}" ]; then
    # If JSON contains OpenAI-style messages, convert to HF Inference inputs
    if jq -e 'has("messages")' "$JSON_INPUT" >/dev/null 2>&1; then
      # join messages into a single textual input (preserve role labels)
      joined="$(jq -r '[.messages[] | (if .role then (.role + ": ") else "" end) + (.content // "")] | join("\n\n")' "$JSON_INPUT" 2>/dev/null || true)"
      jq -n --arg inputs "$joined" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
         '{inputs:$inputs, parameters:$params}' > "$tmp_payload"
      if type atomic_write >/dev/null 2>&1; then
        cat "$tmp_payload" | atomic_write "$PAYLOAD"
      else
        cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
        chmod 600 "$PAYLOAD" 2>/dev/null || true
      fi
      return 0
    fi

    # If JSON contains "prompt", convert to HF inputs
    if jq -e 'has("prompt")' "$JSON_INPUT" >/dev/null 2>&1; then
      user_prompt="$(jq -r '.prompt' "$JSON_INPUT" 2>/dev/null || true)"
      model_in_file="$(jq -r '.model // empty' "$JSON_INPUT" 2>/dev/null || true)"
      model_to_use="${model_in_file:-$MODEL}"
      jq -n --arg inputs "$user_prompt" --arg model "$model_to_use" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
         '{inputs:$inputs, model:$model, parameters:$params}' > "$tmp_payload"
      if type atomic_write >/dev/null 2>&1; then
        cat "$tmp_payload" | atomic_write "$PAYLOAD"
      else
        cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
        chmod 600 "$PAYLOAD" 2>/dev/null || true
      fi
      return 0
    fi

    # Pass through raw JSON_INPUT (already HF-style)
    if type atomic_write >/dev/null 2>&1; then
      cat "$JSON_INPUT" | atomic_write "$PAYLOAD"
    else
      cp -f "$JSON_INPUT" "$PAYLOAD" 2>/dev/null || true
      chmod 600 "$PAYLOAD" 2>/dev/null || true
    fi
    return 0
  fi

  # No JSON_INPUT: build inputs from SYSTEM_PROMPT + CONTENT
  if [ -n "${SYSTEM_PROMPT:-}" ]; then
    joined="$(printf 'System: %s\n\nUser: %s' "$SYSTEM_PROMPT" "$CONTENT")"
  else
    joined="$CONTENT"
  fi

  jq -n --arg inputs "$joined" --argjson params "$(jq -n '{max_new_tokens:('"${MAX_TOKENS:-256}"')}' 2>/dev/null)" \
     '{inputs:$inputs, parameters:$params}' > "$tmp_payload"

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmp_payload" | atomic_write "$PAYLOAD"
  else
    cp -f "$tmp_payload" "$PAYLOAD" 2>/dev/null || true
    chmod 600 "$PAYLOAD" 2>/dev/null || true
  fi
  return 0
}

# -------------------------
# call_api_huggingface
# -------------------------
call_api_huggingface() {
  local prov_env

  # Resolve API key via core helper if available
  if type ensure_api_key_for_provider >/dev/null 2>&1; then
    if ! ensure_api_key_for_provider "huggingface"; then
      log_error "APIKEY" "HF API key required to call Hugging Face."
      return $GROQBASHERRNOAPIKEY
    fi
  fi

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    HFAPIKEY="${!prov_env:-${HFAPIKEY:-}}"
  fi

  if [ -z "${HFAPIKEY:-}" ]; then
    log_error "APIKEY" "HF API key not set (env ${prov_env:-HUGGINGFACE_API_KEY})."
    return $GROQBASHERRNOAPIKEY
  fi

  if [ ! -s "${PAYLOAD:-}" ]; then
    log_error "HTTP" "payload file missing or empty: ${PAYLOAD:-<unset>}"
    return $GROQBASHERRTMP
  fi
  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping HTTP call (exit 0)\n' >&2
    return 0
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $GROQBASHERRTMP
  fi

  local workdir tmpout tmpresp hdr_file ERRF RESP api_url http_result http_code time_total http_ct http_body err_text
  workdir="$(_get_work_tmpdir_hf)" || return $GROQBASHERRTMP
  tmpout="$(_mktemp_in_dir_hf "$workdir")" || return $GROQBASHERRTMP
  tmpresp="$(_mktemp_in_dir_hf "$workdir")" || return $GROQBASHERRTMP
  hdr_file="$(_mktemp_in_dir_hf "$workdir")" || return $GROQBASHERRTMP
  ERRF="${ERRF:-$workdir/curl.err}"
  RESP="${RESP:-$workdir/resp.json}"

  # Build model-specific Inference API URL (use MODEL resolved by core)
  api_model_path="$(printf '%s' "$MODEL" | sed 's/ /%20/g')"
  api_url="${HUGGINGFACE_API_HOST:-https://api-inference.huggingface.co}/models/${api_model_path}"

  : > "$tmpout" 2>/dev/null || true
  : > "$ERRF" 2>/dev/null || true
  : > "$tmpresp" 2>/dev/null || true
  : > "$hdr_file" 2>/dev/null || true

  # Perform request: capture headers to hdr_file, body to tmpresp, and write http_code/time to tmpout
  http_result="$(curl "${CURL_BASE_OPTS[@]:-}" \
    -sS -D "$hdr_file" \
    -H "Authorization: Bearer $HFAPIKEY" \
    -H "Content-Type: application/json" \
    --data-binary @"$PAYLOAD" \
    -o "$tmpresp" -w '%{http_code} %{time_total}' \
    "$api_url" 2>"$ERRF" || true)"

  # Parse http_code and time_total
  read -r http_code time_total <<EOF
$http_result
EOF
  http_code="${http_code:-000}"

  # Determine content-type (lowercased)
  http_ct="$(tr '[:upper:]' '[:lower:]' < "$hdr_file" 2>/dev/null | grep -i '^content-type:' || true)"
  http_body="$(cat "$tmpresp" 2>/dev/null || true)"

  # Persist response atomically if present
  if [ -s "$tmpresp" ]; then
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmpresp" | atomic_write "${RESP}" || cp -f "$tmpresp" "${RESP}" 2>/dev/null || true
    else
      cp -f "$tmpresp" "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true
    fi
  else
    : > "${RESP}" 2>/dev/null || true
  fi

  # Cleanup tmp files we no longer need (keep RESP if needed)
  rm -f "$tmpresp" "$tmpout" 2>/dev/null || true

  # Handle HTTP status
  case "$http_code" in
    2*)
      # Success: if JSON, print it; otherwise log debug and return success
      if printf '%s' "$http_ct" | grep -q 'application/json'; then
        printf '%s' "$http_body"
        return 0
      else
        dbg "HF non-json response (truncated): $(printf '%s' "$http_body" | head -c 2048)"
        log_error "HTTP" "API returned non-JSON response (status $http_code). See debug logs."
        return $GROQBASHERRAPI
      fi
      ;;
    *)
      # Extract textual error from HTML if possible (prefer <pre> or plain text)
      err_text=""
      if printf '%s' "$http_body" | grep -qi '<pre'; then
        err_text="$(printf '%s' "$http_body" | sed -n 's/.*<pre[^>]*>\(.*\)<\/pre>.*/\1/p' | sed 's/<[^>]*>//g' | awk '{$1=$1;print}')"
      else
        # fallback: strip tags and take first non-empty lines
        err_text="$(printf '%s' "$http_body" | sed 's/<[^>]*>/ /g' | tr -s '[:space:]' ' ' | awk '{print; exit}')"
      fi
      # Truncate and sanitize
      err_text="$(printf '%s' "$err_text" | sed -n '1,6p' | awk '{$1=$1;print}')"

      dbg "HTTP $http_code response headers (head):"; head -n 50 "$hdr_file" >&2 || true
      dbg "HTTP body (truncated):"; printf '%s' "$http_body" | head -c 2048 >&2 || true
      dbg "curl stderr (head):"; head -n 200 "$ERRF" >&2 || true

      # If we extracted a meaningful message, show it to the user
      if [ -n "$err_text" ]; then
        log_error "HTTP" "API error (status $http_code): $err_text"
      else
        log_error "HTTP" "API error (status $http_code). See debug logs for details."
      fi

      # Write a sanitized error JSON to RESP to avoid leaking raw HTML
      printf '{"error":"HTTP %s from Hugging Face inference endpoint","message":%s}\n' "$http_code" "$(printf '%s' "$err_text" | jq -R -s . 2>/dev/null || printf 'null')" > "${RESP}" 2>/dev/null || true
      chmod 600 "${RESP}" 2>/dev/null || true

      rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
      return $GROQBASHERRAPI
      ;;
  esac
}

# -------------------------
# call_api_streaming_huggingface
# -------------------------
call_api_streaming_huggingface() {
  local prov_env

  # Resolve API key via core helper if available
  if type ensure_api_key_for_provider >/dev/null 2>&1; then
    if ! ensure_api_key_for_provider "huggingface"; then
      log_error "APIKEY" "HF API key required to call Hugging Face."
      return $GROQBASHERRNOAPIKEY
    fi
  fi

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    HFAPIKEY="${!prov_env:-${HFAPIKEY:-}}"
  fi

  if [ -z "${HFAPIKEY:-}" ]; then
    log_error "APIKEY" "HF API key not set (env ${prov_env:-HUGGINGFACE_API_KEY})."
    return $GROQBASHERRNOAPIKEY
  fi

  if is_truthy "${DRY_RUN:-0}"; then
    printf 'DRY-RUN: skipping streaming HTTP call (exit 0)\n' >&2
    return 0
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return $GROQBASHERRTMP
  fi

  local api_url rc RESP_RAW workdir hdr_file ERRF
  workdir="$(_get_work_tmpdir_hf)" || return $GROQBASHERRTMP
  RESP_RAW="${RUN_TMPDIR:-$workdir}/resp.raw"
  : > "$RESP_RAW" 2>/dev/null || true
  chmod 600 "$RESP_RAW" 2>/dev/null || true
  ERRF="${ERRF:-$workdir/curl.err}"
  RESP="${RESP:-$workdir/resp.json}"
  hdr_file="$(_mktemp_in_dir_hf "$workdir")" || return $GROQBASHERRTMP

  # Build model-specific Inference API URL (use MODEL resolved by core)
  api_model_path="$(printf '%s' "$MODEL" | sed 's/ /%20/g')"
  api_url="${HUGGINGFACE_API_HOST:-https://api-inference.huggingface.co}/models/${api_model_path}"

  # Use array-safe expansion of CURL_BASE_OPTS if defined by core
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
        raw="$(printf '%s' "$json" | jq -R -c 'fromjson? | (.choices[]?.delta?.content // .choices[]?.message?.content // empty) | select(length>0)' 2>>"$ERRF" || true)"
        [ -n "$raw" ] && printf '%s' "$raw"
        ;;
      *) ;;
    esac
  done

  rc=${PIPESTATUS[0]:-0}
  [ "$rc" -ne 0 ] && {
    dbg "curl stderr (head):"; head -n 50 "$ERRF" >&2 || true
    rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
    return $GROQBASHERRCURL_FAILED
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

    if [ -n "${RUN_TMPDIR:-}" ] && case "$RUN_TMPDIR" in "${GROQBASH_TMPDIR:-}"/*) true;; "${GROQBASH_TMPDIR:-}") true;; *) false;; esac; then
      rm -f "$RUN_TMPDIR/resp.lines" "$RUN_TMPDIR/resp.valid.jsons" 2>/dev/null || true
    fi
  else
    if jq -e . "$RESP_RAW" >/dev/null 2>&1; then
      cp -f "$RESP_RAW" "${RESP:-$RUN_TMPDIR/resp.json}" 2>/dev/null || true
    fi
  fi

  rm -f "$hdr_file" "$ERRF" 2>/dev/null || true
  return 0
}

# -------------------------
# refresh_models_huggingface
# -------------------------
refresh_models_huggingface() {
  local outpath="${1:-${MODELS_FILE:-}}"
  local prov_env hf_key workdir tmpd out errf curlout parsed tmpout http_code time_total api_url

  # Resolve API key via core helper if available
  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "huggingface")"
    hf_key="${!prov_env:-${HFAPIKEY:-}}"
  else
    hf_key="${HFAPIKEY:-}"
  fi

  if [ -z "$hf_key" ]; then
    log_error "APIKEY" "Hugging Face API key required to refresh models."
    return "$GROQBASHERRNOAPIKEY"
  fi

  if [ -z "$outpath" ]; then
    log_error "MODELREFRESH" "MODELS file path not provided."
    return "$GROQBASHERRTMP"
  fi

  # Ensure runtime tmpdir is available and validated by PRECORE
  if type ensure_run_tmpdir >/dev/null 2>&1; then
    ensure_run_tmpdir || return "$GROQBASHERRTMP"
  fi

  workdir="$(_get_work_tmpdir_hf)" || workdir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}"
  [ -n "$workdir" ] || return "$GROQBASHERRTMP"

  tmpd="$(mktemp -d -p "$workdir" hf-models.XXXX 2>/dev/null || true)"
  [ -n "$tmpd" ] || return "$GROQBASHERRTMP"

  out="$tmpd/models.json"
  errf="$tmpd/curl.err"
  curlout="$tmpd/curl.out"

  # Hugging Face models listing endpoint (public API)
  api_url="https://huggingface.co/api/models?full=false&limit=${MAX_MODELS:-200}"

  rm -f "$out" "$errf" "$curlout" 2>/dev/null || true

  # Use array-safe expansion of CURL_BASE_OPTS and header auth
  if ! curl "${CURL_BASE_OPTS[@]:-}" -H "Authorization: Bearer ${hf_key}" --silent --show-error --no-buffer --max-time 120 -w '%{http_code} %{time_total}' "$api_url" -o "$out" 2>"$errf" >"$curlout"; then
    log_error "MODELREFRESH" "HTTP request to Hugging Face models endpoint failed."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  read -r http_code time_total < "$curlout" 2>/dev/null || http_code="$(cat "$curlout" 2>/dev/null || echo "000")"
  http_code="${http_code:-000}"

  if [ "${http_code:0:1}" != "2" ]; then
    log_error "MODELREFRESH" "models.list HTTP code: $http_code"
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  # Validate JSON
  if ! jq -e . "$out" >/dev/null 2>&1; then
    log_error "MODELREFRESH" "Invalid JSON received from Hugging Face models endpoint."
    log_info "MODELREFRESH" "curl stderr (head):"
    head -n 200 "$errf" >&2 || true
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  # Extract model ids (robust extraction)
  parsed="$tmpd/parsed_models.txt"
  jq -r '.[]? | (.modelId // .id // .model // empty)' "$out" | awk 'NF{print}' | sort -u > "$parsed" 2>/dev/null || true

  if [ ! -s "$parsed" ]; then
    log_error "MODELREFRESH" "parsed models list empty"
    rm -rf "$tmpd"
    return "$GROQBASHERRAPI"
  fi

  # Limit to MAX_MODELS
  tmpout="$(_mktemp_in_dir_hf "$(dirname "$outpath")" 2>/dev/null || true)"
  [ -n "$tmpout" ] || tmpout="${outpath}.tmp"
  awk -v M="${MAX_MODELS:-200}" 'NR<=M{print}' "$parsed" > "$tmpout" || true

  mkdir -p "$(dirname "$outpath")" 2>/dev/null || true

  # Write atomically (use b64_atomic_write if available, else atomic_write)
  if type b64_atomic_write >/dev/null 2>&1; then
    if ! b64_atomic_write "${outpath}.b64" 10 < "$tmpout"; then
      log_error "MODELREFRESH" "failed to stage models file"
      rm -f "$tmpout" 2>/dev/null || true
      rm -rf "$tmpd"
      return "$GROQBASHERRTMP"
    fi
    lockfile="${MODELS_LOCK:-${outpath}.lock}"
    lock_exec "$lockfile" 10 -- sh -c '
      set -e
      manifest_b64="$1"
      dest="$2"
      base64 ${B64_DECODE_OPT:-} < "$manifest_b64" > "$dest"
      chmod 600 "$dest" 2>/dev/null || true
    ' _ "${outpath}.b64" "$outpath" || { log_error "MODELREFRESH" "failed to write models file under lock"; rm -rf "$tmpd"; return "$GROQBASHERRTMP"; }
  else
    if type atomic_write >/dev/null 2>&1; then
      cat "$tmpout" | atomic_write "$outpath"
    else
      mv "$tmpout" "${outpath}.new" 2>/dev/null || cp -f "$tmpout" "${outpath}.new" 2>/dev/null || true
      chmod 600 "${outpath}.new" 2>/dev/null || true
      mv -f "${outpath}.new" "$outpath" 2>/dev/null || cp -f "${outpath}.new" "$outpath" 2>/dev/null || true
    fi
  fi

  chmod 600 "$outpath" 2>/dev/null || true
  log_info "MODELREFRESH" "Hugging Face models refreshed and saved to: $outpath (max ${MAX_MODELS:-200})"

  rm -rf "$tmpd"
  return 0
}

validate_model_huggingface() {
  local model="$1"
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
