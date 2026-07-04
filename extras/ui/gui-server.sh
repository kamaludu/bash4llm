#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM+ — Bash-first wrapper for the LLM
# File: extras/ui/gui-server.sh
# Extra: GUI-CGI Router 
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# CGI server routing and dispatch logic.

# Prevents writing core dumps for safety
ulimit -c 0 2>/dev/null || true

# Cryptographically secure pseudorandom byte generator from /dev/urandom for session IDs and cookies
generate_secure_token() {
  od -An -tx1 -N16 /dev/urandom | tr -d '[:space:]'
}

run_if_func() {
  local fn="${1:-}" shift_args=("${@:2}")
  if type "$fn" >/dev/null 2>&1; then
    "$fn" "${shift_args[@]}"
    return $?
  fi
  return 127
}

# Source the CGI-bootstrap script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [[ -f "$SCRIPT_DIR/gui-bootstrap.sh" ]]; then
  . "$SCRIPT_DIR/gui-bootstrap.sh"
fi

# Set absolute repository directories
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"
BASH4LLM_DIR="${REPO_ROOT}/bash4llm.d"
export BASH4LLM_DIR

# Get active models cache file path based on current provider setting
get_models_file() {
  local prov
  prov="${PROVIDER_CURRENT:-$(get_default_provider)}"
  printf '%s\n' "${CFG_DIR%/}/models.${prov}.txt"
}

# Determine configuration completeness using localized provider variables (SSOT)
is_configured() {
  local prov model models_file entries
  prov="${PROVIDER_CURRENT:-$(get_default_provider)}"
  model="${MODEL_CURRENT:-$(get_default_model)}"
  models_file="$(get_models_file)"
  if [[ -z "$prov" ]]; then
    return 1
  fi
  if [[ -z "$(read_api_key_file "$prov")" ]]; then
    return 1
  fi
  if [[ -n "$model" ]]; then
    return 0
  fi
  if [[ -f "$models_file" ]]; then
    entries="$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)"
    if [[ -n "$entries" ]]; then
      return 0
    fi
  fi
  return 1
}

# Secure dispatcher for shell parameters (Arguments Sanitization & Whitelisting)
call_bash4llm_with_args() {
  if [[ -z "${BASH4LLM_CMD:-}" || ! -x "${BASH4LLM_CMD}" ]]; then
    log_error "GUIIO" "BASH4LLM_CMD not set or not executable: ${BASH4LLM_CMD:-<unset>}"
    return 1
  fi

  local -a argv=()
  local stdin_payload=""
  local key val

  while (( $# )); do
    key="$1"; shift || true
    case "$key" in
      --provider)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid provider: $val"; return 1; fi
        argv+=( "--provider" "$val" )
        ;;
      --model)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid model: $val"; return 1; fi
        argv+=( "--model" "$val" )
        ;;
      --prompt-from-stdin)
        stdin_payload="${1:-}"; shift || true
        ;;
      --init-session)
        argv+=( "--init-session" )
        ;;
      --delete-session)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid session id for deletion: $val"; return 1; fi
        argv+=( "--delete-session" "$val" )
        ;;
      --rename-session)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid session id for renaming: $val"; return 1; fi
        argv+=( "--rename-session" "$val" )
        ;;
      --session)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid session id: $val"; return 1; fi
        argv+=( "--session" "$val" )
        ;;
      --set-default)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid model name for default: $val"; return 1; fi
        argv+=( "--set-default" "$val" )
        ;;
      --title)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val" 256)"
        argv+=( "--title" "$val" )
        ;;
      --refresh-models)
        argv+=( "--refresh-models" )
        ;;
      --session-window)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if [[ "$val" =~ ^[0-9]+$ ]]; then
          argv+=( "--session-window" "$val" )
        fi
        ;;
      *)
        log_error "GUIIO" "call_bash4llm_with_args: Blocked non-secure argument parameters: $key"
        return 1
        ;;
    esac
  done

  # Secure process isolation: Load correct API key immediately before spawning the child process
  local active_prov
  active_prov="${PROVIDER_CURRENT:-$(get_default_provider)}"
  export_api_key_for_provider "$active_prov" || true

  local out rc
  if [[ -n "$stdin_payload" ]]; then
    out="$(printf '%s' "$stdin_payload" | "${BASH4LLM_CMD}" "${argv[@]}" 2>>"${ERROR_LOG:-/dev/null}" || true)"
    rc=$?
  else
    out="$("${BASH4LLM_CMD}" "${argv[@]}" 2>>"${ERROR_LOG:-/dev/null}" || true)"
    rc=$?
  fi
  printf '%s' "$out"
  return $rc
}

refresh_models_via_bash4llm() {
  local prov models_file out
  prov="$1"
  models_file="$(get_models_file)"
  if ! (declare -f ensure_bash4llm_available >/dev/null 2>&1 && ensure_bash4llm_available); then
    log_error "GUIIO" "bash4llm not available for model refresh dispatch"
    return 1
  fi

  prov="$(sanitize_param "$prov")"
  if ! validate_name "$prov"; then
    log_error "GUIIO" "Invalid provider given for refresh: $prov"
    return 1
  fi

  export_api_key_for_provider "$prov" || true

  # Delegate refresh command directly to core wrapper
  if call_bash4llm_with_args --provider "$prov" --refresh-models >/dev/null 2>>"${ERROR_LOG:-/dev/null}"; then
    log_info "GUIIO" "Models list successfully refreshed for provider: $prov"
    return 0
  else
    log_warn "GUIIO" "Core model refresh process returned non-zero status"
    return 1
  fi
}

get_title_file_for_conv() {
  local conv_path="$1"
  printf '%s' "${conv_path%.txt}.title"
}

read_conv_title() {
  local session_id="$1" title_file
  title_file="${BASH4LLM_DIR}/config/ui_state/sessions/${session_id}.json"
  if [[ -f "$title_file" ]]; then
    jq -r '.title // empty' "$title_file" 2>/dev/null || printf ''
  else
    printf ''
  fi
}

build_lang_options() {
  local lang_conf lang_code out code label
  lang_conf="$(find_lang_conf || true)"
  lang_code="$1"
  out=''
  if [[ -n "$lang_conf" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$line" ]] && continue
      if [[ "$line" =~ ^LANG_NAME\.([a-zA-Z_-]+)=(.*)$ ]]; then
        code="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]}"
        code="$(sanitize_param "$code")"
        label="$(sanitize_param "$label")"
        if [[ "$code" == "$lang_code" ]]; then
          out+="<option value=\"$(html_escape "$code")\" selected>$(html_escape "$label")</option>"
        else
          out+="<option value=\"$(html_escape "$code")\">$(html_escape "$label")</option>"
        fi
        out+=$'\n'
      fi
    done <"$lang_conf"
  fi
  printf '%s' "$out"
}

build_provider_options() {
  local cur prov out providers_file
  cur="$1"
  out=''
  providers_file="${PROVIDER_CACHE_FILE:-${CFG_DIR%/}/providers.txt}"
  run_if_func ensure_provider_cache_fresh
  if [[ -f "$providers_file" ]]; then
    while IFS= read -r prov; do
      prov="$(sanitize_param "$prov")"
      [ -z "$prov" ] && continue
      if [[ "$prov" == "$cur" ]]; then
        out+='<option value="'"$(html_escape "$prov")"'" selected>'"$(html_escape "$prov")"'</option>'
      else
        out+='<option value="'"$(html_escape "$prov")"'">'"$(html_escape "$prov")"'</option>'
      fi
      out+=$'\n'
    done < <(awk 'NF{print}' "$providers_file" 2>/dev/null || true)
  else
    out='<option value="groq" selected>groq</option>'
  fi
  PROVIDER_OPTIONS="$out"
  export PROVIDER_OPTIONS
  return 0
}

# Strictly map core file as absolute Single Source of Truth
build_model_list_and_select() {
  local cur m out_list out_opts models_file prov
  cur="$1"
  prov="${2:-$PROVIDER_CURRENT}"
  out_list=''
  out_opts=''
  models_file="$(get_models_file)"

  # Ensures that the model cache for the current provider is fresh before rendering
  if declare -f ensure_model_cache_fresh >/dev/null 2>&1; then
    ensure_model_cache_fresh "$prov" >/dev/null 2>&1 || true
  fi

  if [[ ! -f "$models_file" || ! -s "$models_file" ]]; then
    mkdir -p "$(dirname "$models_file")" 2>/dev/null || true
    # Provide safe fallback to prevent empty state exceptions
    printf '%s\n' "llama3-8b-8192" "llama3-70b-8192" "mixtral-8x7b-32768" "gemma2-9b-it" > "$models_file" 2>/dev/null || true
  fi

  if [[ -f "$models_file" ]]; then
    while IFS= read -r m || [[ -n "$m" ]]; do
      m="$(sanitize_param "$m")"
      [[ -z "$m" ]] && continue
      out_list+="${m}"$'\n'
      if [[ "$m" == "$cur" ]]; then
        out_opts+='<option value="'"$(html_escape "$m")"'" selected>'"$(html_escape "$m")"'</option>'
      else
        out_opts+='<option value="'"$(html_escape "$m")"'">'"$(html_escape "$m")"'</option>'
      fi
      out_opts+=$'\n'
    done < "$models_file"
  fi
  MODEL_LIST_SCROLL="$out_list"
  MODEL_SELECT_OPTIONS="$out_opts"
  export MODEL_LIST_SCROLL MODEL_SELECT_OPTIONS
  return 0
}

handle_post_settings() {
  if ! (declare -f gui_acquire_lock >/dev/null 2>&1 && gui_acquire_lock); then
    log_error "GUILOCK" "Lock collision: Aborted settings updates"
    cgi_fatal 1 "Server busy"
  fi

  local body model provider lang api_key action theme use_sessions session_window ct
  ct="${CONTENT_TYPE:-application/x-www-form-urlencoded}"
  case "$ct" in
    application/x-www-form-urlencoded*|multipart/form-data*) ;;
    *)
      log_error "GUIIO" "Unsupported media type header: ${ct:-<unset>}"
      print_http_error "415 Unsupported Media Type" "Unsupported content type: ${ct:-<unset>}"
      gui_release_lock
      return 1
      ;;
  esac

  body="$(read_post_body)"
  action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"
  action="$(sanitize_param "$action")"

  if [[ "$action" == "save_api" ]]; then
    # Step 1, 2, 3: Configure Provider & API Key
    api_key="$(printf '%s' "$body" | parse_form_field "api_key" || printf '')"
    provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
    
    api_key="$(sanitize_param "$api_key")"
    provider="$(sanitize_param "$provider")"

    if [[ -n "$provider" ]] && validate_name "$provider"; then
      # Atomic write for current provider persistence within the tenant
      gui_atomic_write "${CFG_DIR}/provider" "$provider"
      # Synchronization with the backend core
      call_bash4llm_with_args --provider "$provider" >/dev/null 2>&1 || true
    else
      provider="$PROVIDER_CURRENT"
    fi

    # Dynamic management of the API Key state
    local key_file="${CFG_DIR}/api-key.${provider}"
    if [[ "$api_key" == "••••••••••••••••" ]]; then
      # Key not modified by user
      true
    elif [[ -z "$api_key" ]]; then
      # File removal when input is empty
      rm -f -- "$key_file" 2>/dev/null || true
      log_info "GUIIO" "API key removed for provider: $provider"
    else
      # Update/Resave Key
      save_api_key_file "$api_key" "$provider" || log_warn "GUIIO" "Error saving API Key"
    fi

  elif [[ "$action" == "refresh_models" ]]; then
    # Step 4: Refresh compatible models
    provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
    provider="$(sanitize_param "$provider")"

    if [[ -z "$provider" ]]; then
      provider="$PROVIDER_CURRENT"
    fi

    api_key="$(read_api_key_file "$provider")"
    if [[ -n "$api_key" ]]; then
      gui_release_lock
      
      # 1. Forcefully removes the local GUI cache to avoid stale reads
      rm -f "${CFG_DIR}/models.${provider}.txt" 2>/dev/null || true
      
      # 2. Refreshes via the bash4llm core
      refresh_models_via_bash4llm "$provider" || log_error "GUIIO" "Refresh routine failed"
      
      # 3. Force local GUI cache alignment
      if declare -f ensure_model_cache_fresh >/dev/null 2>&1; then
        ensure_model_cache_fresh "$provider" || log_error "GUIIO" "Failed to align local GUI model cache"
      fi
      
      gui_acquire_lock || true
    else
      log_warn "GUIIO" "Refresh routine bypassed: missing key"
    fi

  elif [[ "$action" == "set_model" ]]; then
    # Step 6: Select and Set Default Model
    model="$(printf '%s' "$body" | parse_form_field "model" || printf '')"
    provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
    
    model="$(sanitize_param "$model")"
    provider="$(sanitize_param "$provider")"

    if [[ -n "$provider" ]] && validate_name "$provider"; then
      call_bash4llm_with_args --provider "$provider" >/dev/null 2>&1 || true
    fi

    if [[ -n "$model" ]] && validate_name "$model"; then
      # Sync and save default model choice inside core files
      call_bash4llm_with_args --provider "$provider" --set-default "$model" >/dev/null 2>&1 || true
    fi

  elif [[ "$action" == "save_memory" ]]; then
    # Save session conversation parameters
    use_sessions="$(printf '%s' "$body" | parse_form_field "use_sessions" || printf 'enabled')"
    use_sessions="$(sanitize_param "$use_sessions")"
    gui_atomic_write "${CFG_DIR}/use-sessions" "$use_sessions"

    session_window="$(printf '%s' "$body" | parse_form_field "session_window" || printf '10')"
    session_window="$(sanitize_param "$session_window")"
    gui_atomic_write "${SESSION_WINDOW_FILE}" "$session_window"

  else
    # Save interface parameters (Theme & Language)
    theme="$(printf '%s' "$body" | parse_form_field "theme" || printf '')"
    theme="$(sanitize_param "$theme")"
    if [[ -n "$theme" ]]; then
      gui_atomic_write "$THEME_CURRENT_FILE" "$theme"
    fi

    lang="$(printf '%s' "$body" | parse_form_field "lang" || printf '')"
    lang="$(sanitize_param "$lang")"
    if [[ -n "$lang" ]]; then
      gui_atomic_write "$LANG_CURRENT_FILE" "$lang"
    fi
  fi

  gui_release_lock
  return 0
}

handle_post_main() {
  local body action sid
  body="$(cat -)"
  action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"
  action="$(sanitize_param "$action")"

  if [[ "$action" == "deleteconv" ]]; then
    sid="$(printf '%s' "$body" | parse_form_field "delete_conv" || printf '')"
    sid="$(sanitize_param "$sid")"
    if [[ -n "$sid" ]] && validate_name "$sid"; then
      if declare -f session_delete_core >/dev/null 2>&1; then
        session_delete_core "$sid" >/dev/null 2>/dev/null
      else
        call_bash4llm_with_args --delete-session "$sid" >/dev/null 2>/dev/null
      fi
    fi
  fi
  return 0
}

handle_post_main_submit() {
  local body prompt provider model active_conv swin use_sessions_val pending_file safe_args
  body="$(cat -)"
  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"
  prompt="$(sanitize_param "$prompt")"
  
  if [[ -z "$prompt" ]]; then
    return 0
  fi

  # Anti-DoS: Prevents multiple background instances from starting if there is an active process
  if is_generation_in_progress; then
    log_warn "CGI" "Submission blocked: generation already active for this session."
    return 0
  fi

  provider="$(get_default_provider)"
  model="$(get_default_model)"
  active_conv="$(read_config_or_default "$CURRENT_CONV_FILE" "")"
  active_conv="$(sanitize_param "$active_conv")"

  if [[ -z "$active_conv" ]] || ! validate_name "$active_conv"; then
    active_conv="session-$(generate_secure_token)"
    gui_atomic_write "$CURRENT_CONV_FILE" "$active_conv"
    call_bash4llm_with_args --session "$active_conv" --init-session >/dev/null 2>/dev/null || true
  fi

  # Atomic writing of the .pending marker before process decoupling
  pending_file="${TMP_DIR}/session-${active_conv}.pending"
  : > "$pending_file"
  chmod 600 "$pending_file" 2>/dev/null || true

  safe_args=()
  if [[ -n "$provider" ]]; then safe_args+=( --provider "$provider" ); fi
  if [[ -n "$model" ]]; then safe_args+=( --model "$model" ); fi

  use_sessions_val="$(read_config_or_default "${CFG_DIR}/use-sessions" "enabled")"
  if [[ "$use_sessions_val" == "enabled" ]]; then
    swin="$(get_session_window)"
    safe_args+=( --session "$active_conv" --session-window "$swin" )
  else
    safe_args+=( --session "$active_conv" --session-window 1 )
  fi

  # Generate secure JSON payload for injection via stdin
  local api_key_val secure_json_payload
  api_key_val="$(read_api_key_file "$provider")"
  secure_json_payload="$(jq -n \
    --arg api_key "$api_key_val" \
    --arg prompt "$prompt" \
    '{api_key: $api_key, prompt: $prompt}')"

  # PROCESS DECOUPLING: Background core startup decoupled from web server timeout.
  # At the end of the background execution, the .pending marker is automatically cleared.
  (
    printf '%s' "$secure_json_payload" | "${BASH4LLM_CMD}" "${safe_args[@]}" >/dev/null 2>>"${ERROR_LOG:-/dev/null}"
    rm -f "$pending_file" 2>/dev/null || true
  ) >/dev/null 2>&1 &

  return 0
}

handle_post_main_rename() {
  local body sid title
  body="$(cat -)"
  sid="$(printf '%s' "$body" | parse_form_field "rename_conv" || printf '')"
  sid="$(sanitize_param "$sid")"
  title="$(printf '%s' "$body" | parse_form_field "new_title" || printf '')"
  title="$(sanitize_param "$title")"

  if [[ -n "$sid" ]] && validate_name "$sid" && [[ -n "$title" ]]; then
    if declare -f session_rename_core >/dev/null 2>&1; then
      session_rename_core "$sid" "$title" >/dev/null 2>/dev/null
    else
      call_bash4llm_with_args --rename-session "$sid" --title "$title" >/dev/null 2>/dev/null
    fi
  fi
  return 0
}

handle_post_main_new_conv() {
  local rand_part new_conv_name
  rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
  new_conv_name="session-$(generate_secure_token)"
  gui_atomic_write "$CURRENT_CONV_FILE" "$new_conv_name"
  call_bash4llm_with_args --session "$new_conv_name" --init-session >/dev/null 2>/dev/null || true
  return 0
}

handle_post_main_select_conv() {
  local body sid
  body="$(cat -)"
  sid="$(printf '%s' "$body" | parse_form_field "select_conv" || printf '')"
  sid="$(sanitize_param "$sid")"
  if [[ -n "$sid" ]] && validate_name "$sid"; then
    gui_atomic_write "$CURRENT_CONV_FILE" "$sid"
  fi
  return 0
}

handle_post_main_dispatch() {
  local body action rename_conv select_conv new_conv prompt ct
  ct="${CONTENT_TYPE:-application/x-www-form-urlencoded}"
  case "$ct" in
    application/x-www-form-urlencoded*|multipart/form-data*) ;;
    *)
      log_error "GUIIO" "Unsupported media type header: ${ct:-<unset>}"
      print_http_error "415 Unsupported Media Type" "Unsupported content type: ${ct:-<unset>}"
      return 1
      ;;
  esac

  body="$(cat -)"
  action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"
  action="$(sanitize_param "$action")"
  rename_conv="$(printf '%s' "$body" | parse_form_field "rename_conv" || printf '')"
  rename_conv="$(sanitize_param "$rename_conv")"
  select_conv="$(printf '%s' "$body" | parse_form_field "select_conv" || printf '')"
  select_conv="$(sanitize_param "$select_conv")"
  new_conv="$(printf '%s' "$body" | parse_form_field "new_conv" || printf '')"
  new_conv="$(sanitize_param "$new_conv")"
  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"
  prompt="$(sanitize_param "$prompt")"

  if ! (declare -f gui_acquire_lock >/dev/null 2>&1 && gui_acquire_lock); then
    log_error "GUILOCK" "Lock collision: Aborted main POST operations"
    cgi_fatal 1 "Server busy"
  fi

  if [[ -n "$rename_conv" ]] && validate_name "$rename_conv"; then
    printf '%s' "$body" | handle_post_main_rename
  elif [[ "$action" == "new_conv" || "$action" == "new" || -n "$new_conv" ]]; then
    handle_post_main_new_conv
  elif [[ -n "$select_conv" ]] && validate_name "$select_conv"; then
    printf '%s' "$body" | handle_post_main_select_conv
  elif [[ -n "$prompt" ]]; then
    gui_release_lock
    printf '%s' "$body" | handle_post_main_submit
    gui_acquire_lock || true
  fi

  gui_release_lock
  return 0
}

build_conv_list() {
  local out=""
  local ui_state_dir="${BASH4LLM_DIR}/config/ui_state"
  local idx_file="${ui_state_dir}/sessions/index.json"
  local lang_code
  lang_code="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"

  local active_conv
  active_conv="$(read_config_or_default "$CURRENT_CONV_FILE" "")"
  active_conv="$(sanitize_param "$active_conv")"

  local listed_active=0

  reverse_lines() {
    if command -v tac >/dev/null 2>&1; then
      tac 2>/dev/null
    else
      awk '{a[NR]=$0} END {for(i=NR; i>0; i--) print a[i]}'
    fi
  }

  if [[ -n "$active_conv" ]]; then
    local in_index=0
    if [[ -f "$idx_file" ]]; then
      if jq -e --arg sid "$active_conv" '.sessions[] | select(. == $sid)' "$idx_file" >/dev/null 2>&1; then
        in_index=1
      fi
    fi
    if [[ "$in_index" -eq 0 ]]; then
      local title="New Conversation"
      out+="<ul class=\"session-menu\"><li class=\"session-item active\">"
      out+="<a class=\"conv-link\" href=\"?page=main&select_conv=$(html_escape "$active_conv")&lang=$(html_escape "$lang_code")\">📄 ✨ <em>$(html_escape "$title")</em></a>"
      out+="</li></ul>"$'\n'
      listed_active=1
    fi
  fi

  if [[ -f "$idx_file" ]]; then
    local sids sid meta_file title msg_count
    sids="$(jq -r '.sessions[] // empty' "$idx_file" 2>/dev/null | reverse_lines)"
    
    out+="<ul class=\"session-menu\">"
    while read -r sid; do
      [[ -z "$sid" ]] && continue
      if validate_name "$sid"; then
        meta_file="${ui_state_dir}/sessions/${sid}.json"
        title=""
        msg_count=0
        if [[ -f "$meta_file" ]]; then
          title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
          msg_count="$(jq -r '.msg_count // 0' "$meta_file" 2>/dev/null || echo 0)"
        fi
        
        if [[ -z "$title" ]]; then
          if [[ "$sid" =~ ^session-([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2}) ]]; then
            title="Chat: ${BASH_REMATCH[3]}/${BASH_REMATCH[2]}/${BASH_REMATCH[1]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}"
          else
            title="Chat: ${sid}"
          fi
        fi
        
        if [[ "$sid" == "$active_conv" ]]; then
          out+="<li class=\"session-item active\">"
          out+="<a class=\"conv-link\" href=\"?page=main&select_conv=$(html_escape "$sid")&lang=$(html_escape "$lang_code")\">📄 $(html_escape "$title") <span class=\"msg-count\">(${msg_count})</span></a>"
          out+="<div class=\"session-actions\">"
          out+="<form method=\"POST\" class=\"rename-form\" action=\"?page=main&lang=$(html_escape "$lang_code")\">"
          out+="<input type=\"hidden\" name=\"rename_conv\" value=\"$(html_escape "$sid")\">"
          out+="<input type=\"text\" name=\"new_title\" class=\"input-rename\" value=\"$(html_escape "$title")\" required>"
          out+="<button type=\"submit\" class=\"btn-save\">Save</button>"
          out+="</form>"
          out+="<a href=\"?page=deleteconv&delete_conv=$(html_escape "$sid")&lang=$(html_escape "$lang_code")\" class=\"btn-delete\" title=\"Delete chat\">✕</a>"
          out+="</div>"
          out+="</li>"
          listed_active=1
        else
          out+="<li class=\"session-item\">"
          out+="<a class=\"conv-link\" href=\"?page=main&select_conv=$(html_escape "$sid")&lang=$(html_escape "$lang_code")\">📄 $(html_escape "$title") <span class=\"msg-count\">(${msg_count})</span></a>"
          out+="<div class=\"session-actions\">"
          out+="<a href=\"?page=main&select_conv=$(html_escape "$sid")&lang=$(html_escape "$lang_code")\" class=\"btn-edit\" title=\"Select chat\">✎</a>"
          out+="<a href=\"?page=deleteconv&delete_conv=$(html_escape "$sid")&lang=$(html_escape "$lang_code")\" class=\"btn-delete\" title=\"Delete chat\">✕</a>"
          out+="</div>"
          out+="</li>"
        fi
        
      fi
    done <<< "$sids"
    out+="</ul>"
  fi

  if [[ -z "$out" ]]; then
    out="<div class=\"no-sessions\">No conversations yet</div>"
  fi
  printf '%s' "$out"
}

render_page_main() {
  local lang="$1" theme model_cur prov_cur conv_file configured
  model_cur="$MODEL_CURRENT"
  prov_cur="$PROVIDER_CURRENT"
  
  local active_conv
  active_conv="$(read_config_or_default "$CURRENT_CONV_FILE" "")"
  active_conv="$(sanitize_param "$active_conv")"
  if ! validate_name "$active_conv"; then
    local rand_part
    rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    active_conv="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
    gui_atomic_write "$CURRENT_CONV_FILE" "$active_conv"
    call_bash4llm_with_args --session "$active_conv" --init-session >/dev/null 2>/dev/null || true
  fi

  conv_file="${BASH4LLM_DIR}/history/sessions/${active_conv}.ndjson"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  configured=0
  if is_configured; then configured=1; fi

  CONV_LIST="$(build_conv_list)"
  export CONV_LIST

  build_current_conv_block "$conv_file"

  : "${TXT_USE_SESSIONS:=Conversation Memory (Sessions)}"
  : "${TXT_SESSIONS_ENABLED:=Enabled}"
  : "${TXT_SESSIONS_DISABLED:=Disabled}"
  export TXT_USE_SESSIONS TXT_SESSIONS_ENABLED TXT_SESSIONS_DISABLED

  local html_current_title
  html_current_title="$(read_conv_title "$active_conv")"
  if [[ -z "$html_current_title" ]]; then
    html_current_title="Session: $active_conv"
  fi
  export html_current_title

  # Performs asynchronous tag checking and exports THEME_REFRESH_TAG and PENDING_STATUS_HTML
  check_pending_marker
  
  # Calculating the submit button disabled state for the template
  SUBMIT_DISABLED_ATTR=""
  if is_generation_in_progress; then
    SUBMIT_DISABLED_ATTR="disabled"
  fi
  export SUBMIT_DISABLED_ATTR
  
  LANG_OPTIONS="$(build_lang_options "$lang")"
  export LANG_OPTIONS

  if [[ "$theme" == "dark" ]]; then
    THEME_IS_dark="selected"
    THEME_IS_light=""
  else
    THEME_IS_dark=""
    THEME_IS_light="selected"
  fi
  export THEME_IS_dark THEME_IS_light

  CURRENT_MODEL="$model_cur"
  CURRENT_PROVIDER="$prov_cur"
  LANG_CODE="$lang"
  THEME="$theme"
  export CURRENT_MODEL CURRENT_PROVIDER LANG_CODE THEME

  # Mask API key visually in rendering
  API_KEY_FIELD="$(read_api_key_file "$prov_cur")"
  if [[ -n "$API_KEY_FIELD" ]]; then
    API_KEY_FIELD="••••••••••••••••"
  fi
  export API_KEY_FIELD

  build_provider_options "$prov_cur"
  build_model_list_and_select "$model_cur" "$prov_cur"

  render_template "${TEMPLATES_DIR}/header.html"
  render_template "${TEMPLATES_DIR}/content.html"
  render_template "${TEMPLATES_DIR}/footer.html"
}

render_page_settings() {
  local lang="$1" theme model_cur prov_cur api_key_val
  model_cur="$MODEL_CURRENT"
  prov_cur="$PROVIDER_CURRENT"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  
  # Load active key for visual masking evaluation
  api_key_val="$(read_api_key_file "$prov_cur")"

  if [[ -z "$api_key_val" ]]; then
    API_KEY_FIELD=""
    REFRESH_DISABLED_ATTR="disabled"
    MODEL_SELECT_DISABLED_ATTR="disabled"
    API_KEY_WARNING_HTML="<p class=\"api-warning\">⚠️ Save an API Key (Step 3) to enable model refreshing and listing.</p>"
  else
    API_KEY_FIELD="••••••••••••••••"
    REFRESH_DISABLED_ATTR=""
    MODEL_SELECT_DISABLED_ATTR=""
    API_KEY_WARNING_HTML=""
  fi
  export REFRESH_DISABLED_ATTR MODEL_SELECT_DISABLED_ATTR API_KEY_WARNING_HTML API_KEY_FIELD

  local use_sessions_val
  use_sessions_val="$(read_config_or_default "${CFG_DIR}/use-sessions" "enabled")"
  if [[ "$use_sessions_val" == "enabled" ]]; then
    USE_SESSIONS_enabled="selected"
    USE_SESSIONS_disabled=""
  else
    USE_SESSIONS_enabled=""
    USE_SESSIONS_disabled="selected"
  fi
  export USE_SESSIONS_enabled USE_SESSIONS_disabled

  SESSION_WINDOW_VALUE="$(get_session_window)"
  export SESSION_WINDOW_VALUE

  : "${TXT_USE_SESSIONS:=Conversation Memory (Sessions)}"
  : "${TXT_SESSIONS_ENABLED:=Enabled}"
  : "${TXT_SESSIONS_DISABLED:=Disabled}"
  export TXT_USE_SESSIONS TXT_SESSIONS_ENABLED TXT_SESSIONS_DISABLED

  # Performs asynchronous tag checking and exports THEME_REFRESH_TAG and PENDING_STATUS_HTML
  check_pending_marker
  LANG_OPTIONS="$(build_lang_options "$lang")"
  export LANG_OPTIONS

  if [[ "$theme" == "dark" ]]; then
    THEME_IS_dark="selected"
    THEME_IS_light=""
  else
    THEME_IS_dark=""
    THEME_IS_light="selected"
  fi
  export THEME_IS_dark THEME_IS_light

  LANG_CODE="$lang"
  THEME="$theme"
  export LANG_CODE THEME

  build_provider_options "$prov_cur"
  build_model_list_and_select "$model_cur" "$prov_cur"

  render_template "${TEMPLATES_DIR}/settings-header.html"
  render_template "${TEMPLATES_DIR}/settings-content.html"
  render_template "${TEMPLATES_DIR}/footer.html"
}

main() {
  # Safe browser session cookie extraction
  local tenant_cookie=""
  if [[ -n "${HTTP_COOKIE:-}" ]]; then
    tenant_cookie="$(printf '%s' "$HTTP_COOKIE" | tr ';' '\n' | awk -F= '$1 ~ /BASH4LLM_TENANT/ {print $2}' | tr -d '[:space:]' || true)"
    tenant_cookie="${tenant_cookie:0:32}"
    if [[ ! "$tenant_cookie" =~ ^[a-f0-9]{32}$ ]]; then
      tenant_cookie=""
    fi
  fi

  # Generate a new cookie if absent or invalid
  NEW_TENANT_COOKIE=""
  if [[ -z "$tenant_cookie" ]]; then
    tenant_cookie="$(generate_secure_token)"
    NEW_TENANT_COOKIE="$tenant_cookie"
  fi
  TENANT_HASH="$tenant_cookie"
  export TENANT_HASH

  # ABSOLUTE MULTI-TENANT ISOLATION: Confinement of history, configuration and locks for each client
  BASH4LLM_DIR="${UI_ROOT}/tmp/gui-runtime.d/tenant_${TENANT_HASH}"
  CFG_DIR="${BASH4LLM_DIR}/config"
  TMP_DIR="${BASH4LLM_DIR}/tmp"
  CONV_DIR="${BASH4LLM_DIR}/conversations"
  LOCK_FILE="${TMP_DIR}/gui.lock"
  CURRENT_CONV_FILE="${CFG_DIR}/current-conv"
  LANG_CURRENT_FILE="${CFG_DIR}/current-lang"
  THEME_CURRENT_FILE="${CFG_DIR}/current-theme"
  SESSION_WINDOW_FILE="${CFG_DIR}/session-window"

  export BASH4LLM_DIR CFG_DIR TMP_DIR CONV_DIR LOCK_FILE CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE SESSION_WINDOW_FILE

  # Securely create isolated directories for the current tenant
  mkdir -p "$BASH4LLM_DIR" "$CFG_DIR" "$TMP_DIR" "$CONV_DIR" "$BASH4LLM_DIR/history" "$BASH4LLM_DIR/history/sessions" 2>/dev/null || true
  chmod 700 "$BASH4LLM_DIR" "$CFG_DIR" "$TMP_DIR" "$CONV_DIR" "$BASH4LLM_DIR/history" "$BASH4LLM_DIR/history/sessions" 2>/dev/null || true

  # Continue with the initialization flow...
  run_if_func ensure_dirs
  if [[ "${IS_TERMUX:-0}" = "1" ]]; then
    run_if_func fix_termux_perms || true
  fi
  run_if_func ensure_config_defaults
  
  PROVIDER_CURRENT="$(get_default_provider)"
  MODEL_CURRENT="$(get_default_model)"
  export PROVIDER_CURRENT MODEL_CURRENT

  local select_conv
  select_conv="$(get_query_param "select_conv" 2>/dev/null || printf '')"
  select_conv="$(sanitize_param "$select_conv")"
  if [[ -n "$select_conv" ]]; then
    if validate_name "$select_conv"; then
      gui_atomic_write "$CURRENT_CONV_FILE" "$select_conv"
      print_http_redirect "?page=main"
      return 0
    fi
  fi

  # Safely delete conversation session via core routines
  local delete_conv
  delete_conv="$(get_query_param "delete_conv" 2>/dev/null || printf '')"
  delete_conv="$(sanitize_param "$delete_conv")"
  if [[ -n "$delete_conv" ]] && validate_name "$delete_conv"; then
    if gui_acquire_lock; then
      gui_release_lock
      
      if declare -f session_delete_core >/dev/null 2>&1; then
        session_delete_core "$delete_conv" >/dev/null 2>/dev/null
      else
        call_bash4llm_with_args --delete-session "$delete_conv" >/dev/null 2>/dev/null
      fi
      
      gui_acquire_lock || true

      local active_conv state_dir idx_file
      active_conv="$(read_config_or_default "$CURRENT_CONV_FILE" "")"
      if [[ "$active_conv" == "$delete_conv" ]]; then
        state_dir="${BASH4LLM_DIR}/config/ui_state"
        idx_file="${state_dir}/sessions/index.json"
        local fallback_sid=""
        if [[ -f "$idx_file" ]]; then
          fallback_sid="$(jq -r '.sessions[0] // empty' "$idx_file" 2>/dev/null || true)"
        fi
        if [[ -z "$fallback_sid" || ! "$fallback_sid" =~ ^[A-Za-z0-9._-]+$ ]]; then
          local rand_part
          rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
          fallback_sid="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
        fi
        gui_atomic_write "$CURRENT_CONV_FILE" "$fallback_sid"
      fi
      gui_release_lock
    fi
    print_http_redirect "?page=main"
    return 0
  fi

  # Secure session initialization delegating parameters to core interface
  local action_conv new_conv_param page_param
  action_conv="$(get_query_param "action" 2>/dev/null || printf '')"
  new_conv_param="$(get_query_param "new_conv" 2>/dev/null || printf '')"
  page_param="$(get_query_param "page" 2>/dev/null || printf '')"
  if [[ "$action_conv" == "new_conv" || "$action_conv" == "new" || "$new_conv_param" == "1" || "$page_param" == "newconv" ]]; then
    local rand_part new_conv_name
    rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    new_conv_name="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
    gui_atomic_write "$CURRENT_CONV_FILE" "$new_conv_name"
    
    call_bash4llm_with_args --session "$new_conv_name" --init-session >/dev/null 2>/dev/null || true
    print_http_redirect "?page=main"
    return 0
  fi

  run_if_func log_rotate_if_needed "${SERVER_LOG:-/dev/null}" 1048576 || true
  run_if_func log_rotate_if_needed "${ERROR_LOG:-/dev/null}" 1048576 || true

  if ! command -v flock >/dev/null 2>&1; then
    log_error "GUILOCK" "flock missing in PATH environment"
    cgi_fatal 1 "Server misconfiguration: flock not available"
  fi
  
  if ! (declare -f ensure_bash4llm_available >/dev/null 2>&1 && ensure_bash4llm_available); then
    log_error "GUIIO" "bash4llm not found: ${BASH4LLM_CMD:-<unset>}"
    cgi_fatal 1 "bash4llm not found on server."
  fi

  local method="${REQUEST_METHOD:-}"
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  if [[ -z "$method" ]]; then
    method="GET"
  fi

  QUERY_STRING="${QUERY_STRING:-}"
  QUERY_STRING="$(printf '%s' "$QUERY_STRING" | tr -d '\000-\037')"

  # Protected fallback assignments prevent trap triggers on initial load
  local lang_code
  lang_code="$(get_query_param "lang" 2>/dev/null || printf '')"
  if [[ -n "$lang_code" ]]; then
    lang_code="$(sanitize_param "$lang_code")"
    if validate_name "$lang_code"; then
      gui_atomic_write "$LANG_CURRENT_FILE" "$lang_code"
    else
      lang_code="en"
    fi
  else
    lang_code="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi
  
  run_if_func load_translations "$lang_code"

  # Protected fallback assignments prevent trap triggers on initial load
  local theme_code
  theme_code="$(get_query_param "theme" 2>/dev/null || printf '')"
  if [[ -n "$theme_code" ]]; then
    theme_code="$(sanitize_param "$theme_code")"
    if [[ "$theme_code" == "light" || "$theme_code" == "dark" ]]; then
      gui_atomic_write "$THEME_CURRENT_FILE" "$theme_code"
    else
      theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
    fi
  else
    theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  fi

  case "${REQUEST_URI:-${QUERY_STRING:-}} " in
    *page=settings*)
      if [[ "$method" == "POST" ]]; then
        if handle_post_settings; then
          print_http_redirect "?page=settings"
        else
          cgi_fatal 1 "settings handler failed"
        fi
      else
        print_http_header
        render_page_settings "$lang_code"
      fi
      ;;
    *page=main*|*page=main\&*|*page=main\?*|*page=*)
      if [[ "$method" == "POST" ]]; then
        if handle_post_main_dispatch; then
          print_http_redirect "?page=main"
        else
          cgi_fatal 1 "main handler failed"
        fi
      else
        print_http_header
        render_page_main "$lang_code"
      fi
      ;;
    *)
      print_http_header
      render_page_main "$lang_code"
      ;;
  esac
  return 0
}

main "$@"
