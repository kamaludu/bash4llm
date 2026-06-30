#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM+ — Bash-first wrapper for the LLM
# File: extras/ui/gui-server.sh
# Extra: GUI-CGI Mini router Bash 
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# CGI mini-server and page controller for the graphic web interface.
#

run_if_func() {
  local fn="${1:-}" shift_args=("${@:2}")
  if type "$fn" >/dev/null 2>&1; then
    "$fn" "${shift_args[@]}"
    return $?
  fi
  return 127
}

# ---------------------------------------------------------------------------
# Sourcing Environment and Lifecycle Bootstrap
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [[ -f "$SCRIPT_DIR/gui-bootstrap.sh" ]]; then
  # shellcheck source=extras/ui/gui-bootstrap.sh
  . "$SCRIPT_DIR/gui-bootstrap.sh"
fi

# Force absolute synchronization of BASH4LLM_DIR across CLI/CGI context
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"
BASH4LLM_DIR="${REPO_ROOT}/bash4llm.d"
export BASH4LLM_DIR

# ---------------------------------------------------------------------------
# Core Helpers & State Delegation to bash4llm
# ---------------------------------------------------------------------------
is_configured() {
  local prov model models_file entries
  prov="$(get_default_provider)"
  model="$(get_default_model)"
  models_file="$(get_models_file)"
  if [[ -z "$prov" ]]; then
    return 1
  fi
  if [[ -z "$(read_api_key_file)" ]]; then
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
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid provider for core call: $val"; return 1; fi
        argv+=( "--provider" "$val" )
        ;;
      --model)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        if ! validate_name "$val"; then log_error "GUIIO" "Invalid model for core call: $val"; return 1; fi
        argv+=( "--model" "$val" )
        ;;
      --prompt-from-stdin)
        stdin_payload="${1:-}"; shift || true
        ;;
      --init-session)
        argv+=( "--init-session" )
        ;;
      --delete-session|--rename-session|--session|--title)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        argv+=( "$key" "$val" )
        ;;
      --*)
        val="${1:-}"; shift || true
        val="$(sanitize_param "$val")"
        argv+=( "$key" "$val" )
        ;;
      *)
        log_error "GUIIO" "call_bash4llm_with_args: unexpected positional arg: $key"
        return 1
        ;;
    esac
  done

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

get_models_file() {
  local candidate groq_dir provider models_candidate
  if [[ -n "${BASH4LLM_CMD:-}" && "${BASH4LLM_CMD}" = /* ]]; then
    groq_dir="$(cd "$(dirname -- "$BASH4LLM_CMD")" 2>/dev/null && pwd -P || printf '%s' ".")"
    candidate="$groq_dir/bash4llm.d/models/models.txt"
    [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  fi
  provider="$(get_default_provider 2>/dev/null || true)"
  if [[ -n "${CFG_DIR:-}" && -n "$provider" ]]; then
    models_candidate="${CFG_DIR%/}/models.${provider}.txt"
    [[ -f "$models_candidate" ]] && { printf '%s' "$models_candidate"; return 0; }
  fi
  if [[ -n "${UI_ROOT:-}" ]]; then
    candidate="$UI_ROOT/../bash4llm.d/models/models.txt"
    [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
    candidate="$UI_ROOT/models/models.txt"
    [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  fi
  candidate="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)/bash4llm.d/models/models.txt"
  printf '%s' "${candidate:-models/models.txt}"
  return 0
}

refresh_models_via_bash4llm() {
  local prov models_file out
  prov="$1"
  models_file="$(get_models_file)"
  if ! (declare -f ensure_bash4llm_available >/dev/null 2>&1 && ensure_bash4llm_available); then
    log_error "GUIIO" "bash4llm not available for refresh"
    return 1
  fi

  prov="$(sanitize_param "$prov")"
  if ! validate_name "$prov"; then
    log_error "GUIIO" "Invalid provider for refresh: $prov"
    return 1
  fi

  export_api_key_for_provider "$prov" || true

  out="$(call_bash4llm_with_args --provider "$prov" --refresh-models </dev/null 2>>"${ERROR_LOG:-/dev/null}" || true)"
  out="$(printf '%s\n' "$out" | sed -n '/\S/ p' | sed -e 's/[[:space:]]\+$//')"
  if [[ -n "$out" ]]; then
    atomic_write "$models_file" "$out" || { log_error "GUIIO" "Failed to write models file"; return 1; }
    log_info "GUIIO" "Models refreshed for provider $prov"
    return 0
  else
    log_warn "GUIIO" "Refresh returned empty list for provider $prov"
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

build_model_list_and_select() {
  local cur m out_list out_opts models_file provider
  cur="$1"
  out_list=''
  out_opts=''
  provider="${2:-}"
  if [[ -z "$provider" ]]; then
    provider="$(read_config_or_default "$DEFAULT_PROVIDER_FILE" "")"
  fi
  if [[ -n "$provider" ]]; then
    run_if_func ensure_model_cache_fresh "$provider"
    models_file="${CFG_DIR%/}/models.${provider}.txt"
    if [[ ! -f "$models_file" ]]; then
      models_file="$(get_models_file)"
    fi
  else
    models_file="$(get_models_file)"
  fi

  if [[ ! -f "$models_file" || ! -s "$models_file" ]]; then
    mkdir -p "$(dirname "$models_file")" 2>/dev/null || true
    printf '%s\n' "llama3-8b-8192" "llama3-70b-8192" "mixtral-8x7b-32768" "gemma2-9b-it" > "$models_file" 2>/dev/null || true
  fi

  if [[ -f "$models_file" ]]; then
    while IFS= read -r m; do
      m="$(sanitize_param "$m")"
      [ -z "$m" ] && continue
      out_list+="${m}"$'\n'
      if [[ "$m" == "$cur" ]]; then
        out_opts+='<option value="'"$(html_escape "$m")"'" selected>'"$(html_escape "$m")"'</option>'
      else
        out_opts+='<option value="'"$(html_escape "$m")"'">'"$(html_escape "$m")"'</option>'
      fi
      out_opts+=$'\n'
    done < <(awk 'NF{print}' "$models_file" 2>/dev/null || true)
  fi
  MODEL_LIST_SCROLL="$out_list"
  MODEL_SELECT_OPTIONS="$out_opts"
  export MODEL_LIST_SCROLL MODEL_SELECT_OPTIONS
  return 0
}

# ---------------------------------------------------------------------------
# POST handlers and rendering
# ---------------------------------------------------------------------------
handle_post_settings() {
  if ! (declare -f acquire_lock >/dev/null 2>&1 && acquire_lock); then
    log_error "GUILOCK" "Failed to acquire lock in handle_post_settings"
    cgi_fatal 1 "Server busy"
  fi

  local body model provider lang api_key action theme use_sessions ct
  ct="${CONTENT_TYPE:-application/x-www-form-urlencoded}"
  case "$ct" in
    application/x-www-form-urlencoded*|multipart/form-data*) ;;
    *)
      log_error "GUIIO" "Unsupported Content-Type for POST in settings: ${ct:-<unset>}"
      print_http_error "415 Unsupported Media Type" "Unsupported content type: ${ct:-<unset>}"
      release_lock
      return 1
      ;;
  esac

  body="$(read_post_body)"
  model="$(printf '%s' "$body" | parse_form_field "model" || printf '')"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
  lang="$(printf '%s' "$body" | parse_form_field "lang" || read_config_or_default "$LANG_CURRENT_FILE" "en")"
  api_key="$(printf '%s' "$body" | parse_form_field "api_key" || printf '')"
  action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"
  theme="$(printf '%s' "$body" | parse_form_field "theme" || printf '')"
  use_sessions="$(printf '%s' "$body" | parse_form_field "use_sessions" || printf 'enabled')"
  
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  lang="$(sanitize_param "$lang")"
  api_key="$(sanitize_param "$api_key")"
  theme="$(sanitize_param "$theme")"
  use_sessions="$(sanitize_param "$use_sessions")"
  
  if [[ -n "$theme" ]]; then
    if [[ "$theme" == "light" || "$theme" == "dark" ]]; then
      atomic_write "$THEME_CURRENT_FILE" "$theme" || log_warn "GUIIO" "Failed to write theme"
    else
      log_warn "GUIIO" "Invalid theme value attempted: $theme"
    fi
  fi
  
  if [[ "$use_sessions" == "enabled" || "$use_sessions" == "disabled" ]]; then
    atomic_write "${CFG_DIR%/}/use-sessions" "$use_sessions" || log_warn "GUIIO" "Failed to write use-sessions configuration"
  fi

  if [[ "$action" == "refresh_models" ]]; then
    provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
    provider="$(sanitize_param "$provider")"
    if [[ -z "$provider" ]]; then
      log_warn "GUIIO" "Refresh requested but provider empty"
    else
      if validate_name "$provider"; then
        release_lock
        refresh_models_via_bash4llm "$provider" || log_error "GUIIO" "Failed to refresh models: $provider"
        acquire_lock || true
      else
        log_warn "GUIIO" "Invalid provider attempted for refresh: $provider"
      fi
    fi
  fi
  
  if [[ "$action" == "set_model" ]]; then
    model="$(printf '%s' "$body" | parse_form_field "model" || printf '')"
    model="$(sanitize_param "$model")"
    if [[ -z "$model" ]]; then
      log_warn "GUIIO" "Set model requested but model empty"
    else
      if validate_name "$model"; then
        atomic_write "$DEFAULT_MODEL_FILE" "$model" || log_warn "GUIIO" "Failed to write default model"
      else
        log_warn "GUIIO" "Invalid model attempted to set: $model"
      fi
    fi
  fi
  if [[ -n "$model" ]]; then
    if ! validate_name "$model"; then
      log_error "GUIIO" "Invalid model name attempted: $model"
      model=""
    fi
  fi
  if [[ -n "$provider" ]]; then
    if ! validate_name "$provider"; then
      log_error "GUIIO" "Invalid provider name attempted: $provider"
      provider=""
    fi
  fi
  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi
  if [[ -z "${CFG_DIR:-}" || ! -d "${CFG_DIR%/}" || ! -w "${CFG_DIR%/}" ]]; then
    log_warn "GUIIO" "CFG_DIR not writable or unset; cannot persist provider/lang"
  else
    atomic_write "$DEFAULT_PROVIDER_FILE" "$provider" || log_warn "GUIIO" "Failed to write default provider"
    if [[ -n "$provider" ]]; then
      ensure_model_cache_fresh "$provider" || log_warn "MODEL" "ensure_model_cache_fresh failed for $provider"
    fi
    atomic_write "$LANG_CURRENT_FILE" "$lang" || true
  fi
  if [[ -n "$api_key" ]]; then
    save_api_key_file "$api_key" || log_warn "GUIIO" "Failed to save API key"
  fi

  release_lock
  return 0
}

handle_post_main() {
  if ! (declare -f acquire_lock >/dev/null 2>&1 && acquire_lock); then
    log_error "GUILOCK" "Failed to acquire lock in handle_post_main"
    cgi_fatal 1 "Server busy"
  fi

  local body prompt model provider conv_file output sanitized_output models_file lang model_raw provider_raw conv_title_raw conv_title _max_prompt ct
  ct="${CONTENT_TYPE:-application/x-www-form-urlencoded}"
  case "$ct" in
    application/x-www-form-urlencoded*|multipart/form-data*) ;;
    *)
      log_error "GUIIO" "Unsupported Content-Type for POST in main: ${ct:-<unset>}"
      print_http_error "415 Unsupported Media Type" "Unsupported content type: ${ct:-<unset>}"
      release_lock
      return 1
      ;;
  esac

  body="$(read_post_body)"
  
  local post_rename_conv post_new_title
  post_rename_conv="$(printf '%s' "$body" | parse_form_field "rename_conv" || printf '')"
  post_rename_conv="$(sanitize_param "$post_rename_conv")"
  post_new_title="$(printf '%s' "$body" | parse_form_field "new_title" || printf '')"
  post_new_title="$(sanitize_param "$post_new_title")"

  # Rinomina delegata interamente a bash4llm (Fonte di Verità)
  if [[ -n "$post_rename_conv" ]] && validate_name "$post_rename_conv" && [[ -n "$post_new_title" ]]; then
    release_lock
    call_bash4llm_with_args --rename-session "$post_rename_conv" --title "$post_new_title" >/dev/null 2>/dev/null
    return 0
  fi

  local post_select_conv post_action post_new_conv
  post_select_conv="$(printf '%s' "$body" | parse_form_field "select_conv" || printf '')"
  post_select_conv="$(sanitize_param "$post_select_conv")"
  post_action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"
  post_action="$(sanitize_param "$post_action")"
  post_new_conv="$(printf '%s' "$body" | parse_form_field "new_conv" || printf '')"

  # Creazione delegata interamente a bash4llm (Fonte di Verità)
  if [[ "$post_action" == "new_conv" || "$post_action" == "new" || "$post_select_conv" == "new" || -n "$post_new_conv" ]]; then
    local rand_part new_conv_name
    rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    new_conv_name="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
    atomic_write "$CURRENT_CONV_FILE" "$new_conv_name"
    release_lock
    
    # Inizializza la conversazione tramite il core per renderla persistente nell'indice
    call_bash4llm_with_args --session "$new_conv_name" --init-session >/dev/null 2>/dev/null || true
    return 0
  elif [[ -n "$post_select_conv" ]]; then
    if validate_name "$post_select_conv"; then
      atomic_write "$CURRENT_CONV_FILE" "$post_select_conv"
      release_lock
      return 0
    fi
  fi

  lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"
  model_raw="$(printf '%s' "$body" | parse_form_field "model" || true)"
  provider_raw="$(printf '%s' "$body" | parse_form_field "provider" || true)"
  model="${model_raw:-$(get_default_model)}"
  provider="${provider_raw:-$(get_default_provider)}"
  
  prompt="$(sanitize_param "$prompt")"
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  
  _max_prompt=${MAX_PROMPT_CHARS:-4096}
  if (( ${#prompt} > _max_prompt )); then
    log_warn "GUIIO" "Prompt truncated from ${#prompt} to ${_max_prompt} chars"
    prompt="${prompt:0:_max_prompt}"
  fi
  unset _max_prompt

  if [[ -n "$model" ]] && ! validate_name "$model"; then
    log_error "GUIIO" "Invalid model name attempted: $model"
    model=""
  fi
  if [[ -n "$provider" ]] && ! validate_name "$provider"; then
    log_error "GUIIO" "Invalid provider name attempted: $provider"
    provider=""
  fi

  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi

  local active_conv
  active_conv="$(read_config_or_default "$CURRENT_CONV_FILE" "")"
  active_conv="$(sanitize_param "$active_conv")"
  if ! validate_name "$active_conv"; then
    local rand_part
    rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    active_conv="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
    atomic_write "$CURRENT_CONV_FILE" "$active_conv"
    call_bash4llm_with_args --session "$active_conv" --init-session >/dev/null 2>/dev/null || true
  fi

  conv_file="${BASH4LLM_DIR}/history/sessions/${active_conv}.ndjson"

  if ! { declare -f export_api_key_for_provider >/dev/null 2>&1 && export_api_key_for_provider "$provider"; }; then
    log_error "GUIIO" "API key missing for provider $provider"
    release_lock
    cgi_fatal 1 "API key missing. Set it in Settings."
  fi

  if ! is_configured; then
    log_error "GUIIO" "Attempt to call bash4llm while GUI not configured"
    release_lock
    cgi_fatal 1 "GUI not configured. Please set provider, API key and model in Settings."
  fi

  models_file="$(get_models_file)"
  if [[ -f "$models_file" ]]; then
    if [[ -n "$model" ]]; then
      if ! grep -Fxq "$model" "$models_file" 2>/dev/null; then
        log_error "GUIIO" "Model $model not in whitelist"
        release_lock
        cgi_fatal 1 "Selected model not whitelisted."
      fi
    else
      model="$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)"
      model="$(sanitize_param "$model")"
      if [[ -z "$model" ]]; then
        release_lock
        cgi_fatal 1 "No models found in whitelist."
      fi
    fi
  fi

  release_lock

  local -a safe_args=()
  if [[ -n "$provider" ]]; then safe_args+=( --provider "$provider" ); fi
  if [[ -n "$model" ]]; then safe_args+=( --model "$model" ); fi

  local use_sessions_val
  use_sessions_val="$(read_config_or_default "${CFG_DIR}/use-sessions" "enabled")"
  if [[ "$use_sessions_val" == "enabled" ]]; then
    safe_args+=( --session "$active_conv" )
  fi

  if ! output="$(printf '%s' "$prompt" | call_bash4llm_with_args "${safe_args[@]}" 2>>"${ERROR_LOG:-/dev/null}" || true)"; then
    log_error "GUIIO" "bash4llm invocation failed"
    cgi_fatal 1 "bash4llm invocation failed."
  fi

  return 0
}

build_model_options() {
  local models_file model_cur out m
  models_file="$(get_models_file)"
  model_cur="$1"
  out=''
  if [[ -f "$models_file" ]]; then
    while IFS= read -r m; do
      m="$(sanitize_param "$m")"
      [ -z "$m" ] && continue
      if [[ "$m" == "$model_cur" ]]; then
        out+='<option value="'"$(html_escape "$m")"'" selected>'"$(html_escape "$m")"'</option>'
      else
        out+='<option value="'"$(html_escape "$m")"'">'"$(html_escape "$m")"'</option>'
      fi
      out+=$'\n'
    done < <(awk 'NF{print}' "$models_file" 2>/dev/null || true)
  fi
  printf '%s' "$out"
}

# ---------------------------------------------------------------------------
# Global Session Index List Builder (Source of truth: ui_state/index.json)
# ---------------------------------------------------------------------------
# Versione refactoring: nessuna formattazione estetica in linea, solo classi semantiche
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
      out+="<ul class=\"session-menu\"><li class=\"session-item draft-item\">"
      out+="<a class=\"conv-link\" href=\"?page=main&select_conv=$(html_escape "$active_conv")&lang=$(html_escape "$lang_code")\">✨ <em>$(html_escape "$title")</em></a>"
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
        
        # Parsing data e ora dall'ID sessione (Part 1)
        if [[ -z "$title" ]]; then
          if [[ "$sid" =~ ^session-([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2}) ]]; then
            title="Chat: ${BASH_REMATCH[3]}/${BASH_REMATCH[2]}/${BASH_REMATCH[1]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}"
          else
            title="Chat: ${sid}"
          fi
        fi
        
        if [[ "$sid" == "$active_conv" ]]; then
          # Item Attivo: contiene il form semantico per la rinomina
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
          # Item Standard
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

build_conv_list_raw() {
  local out f bn title sid
  out=''
  if [[ -d "$CONV_DIR" ]]; then
    for f in "$CONV_DIR"/conv-*.txt; do
      [ -e "$f" ] || continue
      bn="$(basename -- "$f")"
      sid="${bn%.txt}"
      title="$(read_conv_title "$sid")"
      if [[ -n "$title" ]]; then
        out+="$(html_escape "$sid") — $(html_escape "$title")"$'\n'
      else
        out+="$(html_escape "$sid")"$'\n'
      fi
    done
  fi
  printf '%s' "$out"
}

render_page_main() {
  local lang="$1" theme model_cur prov_cur conv_file configured
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  
  local active_conv
  active_conv="$(read_config_or_default "$CURRENT_CONV_FILE" "")"
  active_conv="$(sanitize_param "$active_conv")"
  if ! validate_name "$active_conv"; then
    local rand_part
    rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    active_conv="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
    atomic_write "$CURRENT_CONV_FILE" "$active_conv"
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
  MODEL_CURRENT="$model_cur"
  PROVIDER_CURRENT="$prov_cur"
  LANG_CODE="$lang"
  THEME="$theme"
  export CURRENT_MODEL CURRENT_PROVIDER MODEL_CURRENT PROVIDER_CURRENT LANG_CODE THEME

  API_KEY_FIELD="$(read_api_key_file)"
  export API_KEY_FIELD

  build_provider_options "$prov_cur"
  build_model_list_and_select "$model_cur" "$prov_cur"

  render_template "${TEMPLATES_DIR}/header.html"
  render_template "${TEMPLATES_DIR}/content.html"
  render_template "${TEMPLATES_DIR}/footer.html"
}

render_page_settings() {
  local lang="$1" theme model_cur prov_cur
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"

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

  : "${TXT_USE_SESSIONS:=Conversation Memory (Sessions)}"
  : "${TXT_SESSIONS_ENABLED:=Enabled}"
  : "${TXT_SESSIONS_DISABLED:=Disabled}"
  export TXT_USE_SESSIONS TXT_SESSIONS_ENABLED TXT_SESSIONS_DISABLED

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

  API_KEY_FIELD="$(read_api_key_file)"
  LANG_CODE="$lang"
  THEME="$theme"
  export API_KEY_FIELD LANG_CODE THEME

  build_provider_options "$prov_cur"
  build_model_list_and_select "$model_cur" "$prov_cur"

  render_template "${TEMPLATES_DIR}/settings-header.html"
  render_template "${TEMPLATES_DIR}/settings-content.html"
  render_template "${TEMPLATES_DIR}/footer.html"
}

# ---------------------------------------------------------------------------
# Main controller router
# ---------------------------------------------------------------------------
main() {
  run_if_func ensure_dirs
  if [[ "${IS_TERMUX:-0}" = "1" ]]; then
    run_if_func fix_termux_perms || true
  fi
  run_if_func ensure_config_defaults

  local select_conv
  select_conv="$(get_query_param "select_conv" 2>/dev/null || printf '')"
  select_conv="$(sanitize_param "$select_conv")"
  if [[ -n "$select_conv" ]]; then
    if validate_name "$select_conv"; then
      atomic_write "$CURRENT_CONV_FILE" "$select_conv"
      print_http_redirect "?page=main"
      return 0
    fi
  fi

  # Cancellazione delegata interamente a bash4llm (Fonte di Verità)
  local delete_conv
  delete_conv="$(get_query_param "delete_conv" 2>/dev/null || printf '')"
  delete_conv="$(sanitize_param "$delete_conv")"
  if [[ -n "$delete_conv" ]] && validate_name "$delete_conv"; then
    if acquire_lock; then
      # Rilascia temporaneamente il lock durante l'esecuzione del core per evitare deadlock
      release_lock
      call_bash4llm_with_args --delete-session "$delete_conv" >/dev/null 2>/dev/null
      acquire_lock || true

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
        atomic_write "$CURRENT_CONV_FILE" "$fallback_sid"
      fi
      release_lock
    fi
    print_http_redirect "?page=main"
    return 0
  fi

  # Nuova conversazione delegata interamente a bash4llm (Fonte di Verità)
  local action_conv new_conv_param page_param
  action_conv="$(get_query_param "action" 2>/dev/null || printf '')"
  new_conv_param="$(get_query_param "new_conv" 2>/dev/null || printf '')"
  page_param="$(get_query_param "page" 2>/dev/null || printf '')"
  if [[ "$action_conv" == "new_conv" || "$action_conv" == "new" || "$new_conv_param" == "1" || "$page_param" == "newconv" ]]; then
    local rand_part new_conv_name
    rand_part="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    new_conv_name="session-$(date +%Y%m%d-%H%M%S)-${rand_part}"
    atomic_write "$CURRENT_CONV_FILE" "$new_conv_name"
    
    # Inizializza la conversazione tramite il core per renderla persistente nell'indice
    call_bash4llm_with_args --session "$new_conv_name" --init-session >/dev/null 2>/dev/null || true
    print_http_redirect "?page=main"
    return 0
  fi

  run_if_func log_rotate_if_needed "${SERVER_LOG:-/dev/null}" 1048576 || true
  run_if_func log_rotate_if_needed "${ERROR_LOG:-/dev/null}" 1048576 || true

  if ! command -v flock >/dev/null 2>&1; then
    log_error "GUILOCK" "flock missing in PATH"
    cgi_fatal 1 "Server misconfiguration: flock not available"
  fi
  
  if ! (declare -f ensure_bash4llm_available >/dev/null 2>&1 && ensure_bash4llm_available); then
    log_error "GUIIO" "bash4llm not found: ${BASH4LLM_CMD:-<unset>}"
    cgi_fatal 1 "bash4llm not found on server. Contact administrator."
  fi

  local method="${REQUEST_METHOD:-}"
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  if [[ -z "$method" ]]; then
    method="${1:-GET}"
    method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  fi

  QUERY_STRING="${QUERY_STRING:-}"
  QUERY_STRING="$(printf '%s' "$QUERY_STRING" | tr -d '\000-\037')"

  local lang_code
  lang_code="$(get_query_param "lang" 2>/dev/null || printf '')"
  if [[ -n "$lang_code" ]]; then
    lang_code="$(sanitize_param "$lang_code")"
    if validate_name "$lang_code"; then
      atomic_write "$LANG_CURRENT_FILE" "$lang_code"
    else
      lang_code="en"
    fi
  else
    lang_code="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi
  
  run_if_func load_translations "$lang_code"

  local theme_code
  theme_code="$(get_query_param "theme" 2>/dev/null || printf '')"
  if [[ -n "$theme_code" ]]; then
    theme_code="$(sanitize_param "$theme_code")"
    if [[ "$theme_code" == "light" || "$theme_code" == "dark" ]]; then
      atomic_write "$THEME_CURRENT_FILE" "$theme_code"
    else
      theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
    fi
  else
    theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  fi

  case "${REQUEST_URI:-${QUERY_STRING:-}} " in
    *page=settings*|*page=settings\&*|*page=settings\?*)
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
        if handle_post_main; then
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
