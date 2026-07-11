#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/chat/tui-repl.sh
# Component: TUI REPL Interactive Module (External Extra) - Part 1
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Clean execution environment: inherits variables from parent process group.
set -u

# --- PHASE 1: BOOTSTRAP, SOURCING GUARD, AND CORE LIBRARY IMPORT ---
CORE_SCRIPT="${BASH4LLM_CORE_SCRIPT:-}"

if [ -z "$CORE_SCRIPT" ] || [ ! -f "$CORE_SCRIPT" ]; then
  _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  _repo_root="$(cd "$_self_dir/../../.." >/dev/null 2>&1 && pwd)"
  if [ -f "$_repo_root/bash4llm" ]; then
    CORE_SCRIPT="$_repo_root/bash4llm"
  elif [ -f "$_repo_root/bash4llm.sh" ]; then
    CORE_SCRIPT="$_repo_root/bash4llm.sh"
  fi
fi

if [ -n "$CORE_SCRIPT" ] && [ -f "$CORE_SCRIPT" ]; then
  export BASH4LLM_SOURCE_ONLY=1
  # shellcheck source=/dev/null
  . "$CORE_SCRIPT"
else
  printf 'tui-repl.sh: ERROR: Cannot locate core bash4llm script.\n' >&2
  printf 'Please run directly using: bash4llm --chat\n' >&2
  exit 15
fi

# Validation of interactive TTY environment
if [ ! -t 0 ] || [ ! -t 1 ]; then
  printf 'tui-repl.sh: ERROR: TUI REPL requires a valid and active interactive TTY.\n' >&2
  exit 15
fi

# Overwrite core's tac_fallback with a robust, pipe-compatible version
tac_fallback() {
  local f="${1:-}"
  if command -v tac >/dev/null 2>&1; then
    if [ -n "$f" ]; then
      tac "$f"
    else
      tac
    fi
    return $?
  fi
  if [ -n "$f" ]; then
    awk '{ lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] }' "$f"
  else
    awk '{ lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] }'
  fi
  return 0
}

# Color placeholders and conditional attributes wrapped in <...> with C_YELLOW
color_attributes() {
  local text="$1"
  if [ -n "${C_YELLOW:-}" ]; then
    printf '%s' "$text" | sed "s/\(<[^>]*>\)/${C_YELLOW}\1${C_RST:-}/g"
  else
    printf '%s' "$text"
  fi
}

# --- PHASE 2: REPL STATE DICTIONARY AND VARIABLE INITIALIZATION ---
SESSION_ID="${BASH4LLM_ACTIVE_SESSION:-}"
MODEL="${BASH4LLM_ACTIVE_MODEL:-}"
TEMPERATURE="${BASH4LLM_ACTIVE_TEMPERATURE:-1.0}"
TURE="$TEMPERATURE"

[ -n "$MODEL" ] || {
  if resolve_model >/dev/null 2>&1 && [ -n "${FINAL_MODEL:-}" ]; then
    MODEL="$FINAL_MODEL"
  else
    MODEL=""
  fi
}

ensure_run_tmpdir >/dev/null 2>&1 || {
  printf 'tui-repl.sh: ERROR: Unable to initialize secure run-specific temporary directory.\n' >&2
  exit "$BASH4LLM_ERR_TMP"
}

# --- PHASE 2.1: DECLARATIVE DICTIONARIES & SECURE PARSER ---
declare -A T_MSG

load_lang_secure() {
  local lang_code="${1:-en}"
  local lang_dir="$(dirname "${BASH_SOURCE[0]}")/langs"
  local lang_file="${lang_dir}/${lang_code}.properties"

  if [[ ! "$lang_code" =~ ^[a-z]{2}$ ]]; then
    lang_code="en"
    lang_file="${lang_dir}/en.properties"
  fi

  if [ ! -f "$lang_file" ] || [ ! -r "$lang_file" ]; then
    lang_file="${lang_dir}/en.properties"
  fi

  if [ ! -f "$lang_file" ]; then
    if type log_warn >/dev/null 2>&1; then
      log_warn "I18N" "Language translation files directory is missing or unreadable."
    else
      printf 'tui-repl.sh: WARN: Language translation files directory is missing or unreadable.\n' >&2
    fi
    return 1
  fi

  local key val
  while IFS='=' read -r key val || [ -n "$key" ]; do
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    local safe_key
    safe_key="$(printf '%s' "$key" | tr -d -c 'A-Za-z0-9_')"
    [ -n "$safe_key" ] || continue

    local trimmed_val
    trimmed_val="$(printf '%s' "$val" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    T_MSG["$safe_key"]="$trimmed_val"
  done < "$lang_file"
}

_msg() {
  local key="${1:-}"
  local val=""
  
  if [ -n "$key" ]; then
    if [ "${T_MSG[$key]+x}" = "x" ]; then
      val="${T_MSG[$key]}"
    fi
  fi
  
  if [ -z "$val" ]; then
    val="$key"
  fi

  if [ $# -gt 1 ]; then
    printf "$val" "${@:2}"
  else
    printf '%s' "$val"
  fi
}

get_stored_lang() {
  local cfg_file="${BASH4LLM_CONFIG_DIR%/}/config"
  local stored_lang=""
  
  if [ -f "$cfg_file" ]; then
    stored_lang="$(awk -F= '/^BASH4LLM_LANG=/ {sub(/^BASH4LLM_LANG=/,""); print; exit}' "$cfg_file" 2>/dev/null || true)"
    stored_lang="$(printf '%s' "$stored_lang" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"
  fi
  printf '%s' "$stored_lang"
}

save_lang_config() {
  local lang="${1:-en}"
  local cfg_file="${BASH4LLM_CONFIG_DIR%/}/config"
  local tmp_cfg
  
  safe_mkdir "$(dirname "$cfg_file")" 700
  
  tmp_cfg="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" config_update 2>/dev/null)"
  if [ -z "$tmp_cfg" ]; then
    tmp_cfg="${BASH4LLM_TMPDIR}/.config_update.$$.tmp"
  fi
  
  if [ -f "$cfg_file" ]; then
    grep -v "^BASH4LLM_LANG=" "$cfg_file" > "$tmp_cfg" 2>/dev/null || true
  fi
  
  printf 'BASH4LLM_LANG=%s\n' "$lang" >> "$tmp_cfg"
  
  atomic_write "$cfg_file" 10 < "$tmp_cfg"
  rm -f "$tmp_cfg" 2>/dev/null || true
}

prompt_lang_selection() {
  local choice=""
  local selected_lang="en"
  
  while true; do
    printf '%b' "
${C_BANNER:-} LANGUAGE•LINGUA•IDIOMA•LANGUE•SPRACHE ${C_RST:-}
  1 - English
  2 - Italiano
  3 - Español
  4 - Français
  5 - Deutsch
" >&2
    printf '  Choose / Scegli (1-5) [Default: 1]: ' >&2
    if ! IFS= read -r choice; then
      printf '\n' >&2
      choice="1"
    fi
    choice="$(printf '%s' "$choice" | tr -d ' ')"
    [ -z "$choice" ] && choice="1"

    case "$choice" in
      1) selected_lang="en"; break ;;
      2) selected_lang="it"; break ;;
      3) selected_lang="es"; break ;;
      4) selected_lang="fr"; break ;;
      5) selected_lang="de"; break ;;
      *)
        printf '\n  Invalid choice / Scelta non valida.\n' >&2
        sleep 1
        ;;
    esac
  done

  save_lang_config "$selected_lang"
  BASH4LLM_LANG="$selected_lang"
  export BASH4LLM_LANG
}

bootstrap_i18n() {
  local lang
  lang="$(get_stored_lang)"
  
  if [ -z "$lang" ]; then
    prompt_lang_selection
    lang="$(get_stored_lang)"
  fi
  
  case "$lang" in
    en|it|es|fr|de) ;;
    *) lang="en" ;;
  esac
  
  BASH4LLM_LANG="$lang"
  export BASH4LLM_LANG
  load_lang_secure "$BASH4LLM_LANG"
}

bootstrap_i18n

# --- PHASE 3: INPUT HISTORY CONFIGURATION (ISOLATED READLINE) ---
set -o history 2>/dev/null || true
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTFILE="${BASH4LLM_HISTORY_DIR}/tui_history"

if [ ! -f "$HISTFILE" ]; then
  : > "$HISTFILE" 2>/dev/null
  chmod 600 "$HISTFILE" 2>/dev/null || true
fi
history -r "$HISTFILE" 2>/dev/null || true

RL_START=$'\001'
RL_END=$'\002'

# --- PHASE 4: SIGNAL MANAGEMENT ARCHITECTURE ---
IS_STREAMING=0

handle_sigint() {
  if [ "$IS_STREAMING" -eq 1 ]; then
    :
  else
    printf '\n' >&2
  fi
}
trap handle_sigint INT

# --- PHASE 5: SEQUENTIAL RENDERING UTILITIES ---
print_banner() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  local b_title b_sess b_help
  b_title="$(_msg banner_title)"
  
  local r_sess="${SESSION_ID:-}"
  local r_prov="${PROVIDER:-groq}"
  local r_model="${MODEL:-}"

  [ -n "$r_sess" ] || r_sess="$(_msg attribute_none)"
  [ -n "$r_model" ] || r_model="$(_msg attribute_default)"

  # Yellow formatting applied directly to runtime parameters
  local col_sess="${C_YELLOW:-}${r_sess}${C_RST:-}"
  local col_prov="${C_YELLOW:-}${r_prov}${C_RST:-}"
  local col_model="${C_YELLOW:-}${r_model}${C_RST:-}"

  b_sess="$(_msg banner_session_full "$col_sess" "$col_prov" "$col_model")"
  
  b_help="$(_msg banner_help)"
  b_help="$(color_attributes "$b_help")"

  # Divider is C_BGREEN
  printf '%b' "
${C_LOGO:-} Bash4LLM⁺ ${C_RST:-} ${C_BGREEN:-} ${b_title} ${C_RST:-}
  ${b_sess}
  ${b_help}
${C_BGREEN:-}----------------------------------------${C_RST:-}
" >&2
}

# --- PHASE 6: PAGINATED SESSION SELECTION WIZARD ---
_format_ts() {
  local ts="${1:-}"
  if [ -n "$ts" ]; then
    printf '%s' "${ts:0:10}"
  else
    printf 'N/A'
  fi
}

load_sessions_wizard() {
  local session_dir="${BASH4LLM_HISTORY_DIR}/sessions"
  safe_mkdir "$session_dir" 700

  local -a files=()
  local mtime f
  while IFS='|' read -r mtime f; do
    if [ -f "$f" ] && [ "${f##*.}" = "ndjson" ]; then
      files+=("$f")
    fi
  done < <(list_files_sorted_by_mtime "$session_dir" | tac_fallback)

  local total_sessions="${#files[@]}"

  if [ "$total_sessions" -eq 0 ] || [ -z "${files:-}" ]; then
    SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
    local new_sess_file="${session_dir}/${SESSION_ID}.ndjson"
    : > "$new_sess_file"
    chmod 600 "$new_sess_file"
    local init_msg
    init_msg="$(_msg wizard_no_sessions "$SESSION_ID")"
    log_info_user "TUI" "$init_msg"
    return 0
  fi

  local page_size=10
  local current_page=0
  local total_pages=$(( (total_sessions + page_size - 1) / page_size ))

  while true; do
    if [ -t 1 ]; then
      clear 2>/dev/null || printf '\033[H\033[2J' >&2
    fi

    local w_title w_page
    w_title="$(_msg wizard_title)"
    w_page="$(_msg wizard_page "$((current_page + 1))" "$total_pages" "$total_sessions")"

    # Display Wizard Header Section
    printf '\n%b' "  ${C_BANNER:-}  ${w_title}  ${C_RST:-}\n\n" >&2
    printf "  %s\n\n" "${w_page}" >&2
    printf '%b' "  ${C_BBLUE:-}----------------------------------------${C_RST:-}\n\n" >&2

    local start_idx=$((current_page * page_size))
    local end_idx=$((start_idx + page_size))
    [ "$end_idx" -gt "$total_sessions" ] && end_idx="$total_sessions"

    # Retrieve and wrap the new session label as a placeholder
    local new_session_label="<$(_msg wizard_new_session)>"
    local colored_new_session="$(color_attributes "$new_session_label")"

    # Option [ 1] is mapped to the placeholder option "New Empty Session"
    printf "  ${C_BCYAN:-}[ 1]${C_RST:-} %s\n\n" "$colored_new_session" >&2

    local i
    for ((i = start_idx; i < end_idx; i++)); do
      local s_file="${files[i]}"
      local s_id
      s_id="$(basename "$s_file" .ndjson)"

      local last_line last_ts last_date
      last_line="$(tail -n 1 "$s_file" 2>/dev/null || true)"
      last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      last_date="$(_format_ts "$last_ts")"

      local meta_file title
      meta_file="${BASH4LLM_CONFIG_DIR}/ui_state/sessions/${s_id}.json"
      title=""
      if [ -f "$meta_file" ]; then
        title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
      fi
      if [ -z "$title" ] && [ -f "$s_file" ]; then
        title="$(jq -r 'select(.role=="user") | .content' "$s_file" 2>/dev/null | head -n 1 | tr -d '\n\r' | cut -c 1-18 || true)"
      fi
      [ -n "$title" ] || title="Session ${s_id:0:8}"

      # Existing physical sessions are shifted to start from index [ 2]
      printf "  ${C_BCYAN:-}[%2d]${C_RST:-} %s ${C_CYAN:-}>${C_RST:-} %s\n\n" \
        "$((i + 2))" "$last_date" "$title" >&2
    done

    printf '%b' "  ${C_BBLUE:-}----------------------------------------${C_RST:-}\n\n" >&2
    printf "  %s:\n\n" "$(_msg wizard_nav)" >&2
    printf "  [ + / n ] %s\n\n" "$(_msg wizard_next_page)" >&2
    printf "  [ - / p ] %s\n\n" "$(_msg wizard_prev_page)" >&2
    printf "  [   q   ] %s\n\n" "$(_msg wizard_exit_repl)" >&2
    printf '%b' "  ${C_BBLUE:-}----------------------------------------${C_RST:-}\n" >&2

    local choice
    printf '  %s ' "$(_msg wizard_prompt)" >&2
    if ! IFS= read -r choice; then
      printf '\n' >&2
      exit 0
    fi
    choice="$(printf '%s' "$choice" | awk '{$1=$1;print}')"
    printf '\n' >&2

    case "$choice" in
      + | n | N)
        current_page=$(( (current_page + 1) % total_pages ))
        ;;
      - | p | P)
        current_page=$(( (current_page - 1 + total_pages) % total_pages ))
        ;;
      1 | c | C | new | NEW)
        SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_sess_file="${session_dir}/${SESSION_ID}.ndjson"
        : > "$new_sess_file"
        chmod 600 "$new_sess_file"
        break
        ;;
      q | Q | exit | EXIT)
        printf '\n%s\n' "$(_msg exited)" >&2
        exit 0
        ;;
      *)
        if printf '%s\n' "$choice" | grep -qE '^[0-9]+$'; then
          local target_idx=$((choice - 2))
          if [ "$target_idx" -ge 0 ] && [ "$target_idx" -lt "$total_sessions" ] && [ -n "${files[target_idx]+x}" ]; then
            local selected_file="${files[target_idx]}"
            SESSION_ID="$(basename "$selected_file" .ndjson)"
            break
          else
            printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg wizard_out_of_range)" "${C_RST:-}" >&2
            sleep 1
          fi
        else
          printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg wizard_invalid_choice)" "${C_RST:-}" >&2
          sleep 1
        fi
        ;;
    esac
  done

  if [ -t 1 ]; then
    clear 2>/dev/null || printf '\033[H\033[2J' >&2
  fi
  return 0
}
# --- PHASE 7: MENU ITEM AND MENU HELPERS ---
print_menu_item() {
  local index="$1"
  local desc="$2"
  local value="${3:-}"
  local label="${4:-$(_msg menu_current)}"

  local colored_val
  colored_val="$(color_attributes "$value")"

  if [ -n "$value" ]; then
    printf "  ${C_BCYAN:-}%d)${C_RST:-} %-22s (${C_CYAN:-}%s${C_RST:-}: %s)\n" "$index" "$desc" "$label" "$colored_val" >&2
  else
    printf "  ${C_BCYAN:-}%d)${C_RST:-} %s\n" "$index" "$desc" >&2
  fi
}

print_status_bar() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  local stream_status
  if [ "${STREAM_MODE:-0}" -eq 1 ]; then
    stream_status="$(_msg status_enabled)"
  else
    stream_status="$(_msg status_disabled)"
  fi

  local r_sess="${SESSION_ID:-}"
  local r_model="${MODEL:-}"
  [ -n "$r_sess" ] || r_sess="$(_msg attribute_none)"
  [ -n "$r_model" ] || r_model="$(_msg attribute_default)"

  # Variables formatted in yellow natively
  local col_sess="${C_YELLOW:-}${r_sess}${C_RST:-}"
  local col_model="${C_YELLOW:-}${r_model}${C_RST:-}"
  local col_temp="${C_YELLOW:-}${TEMPERATURE:-1.0}${C_RST:-}"
  local col_stream="${C_YELLOW:-}${stream_status}${C_RST:-}"

  # Prints single unified line formatting with static labels in C_BCYAN
  printf "  %b%s%b %s | %b%s%b %s | %b%s%b %s | %b%s%b %s\n" \
    "${C_BCYAN:-}" "$(_msg label_repl_status)" "${C_RST:-}" "$col_sess" \
    "${C_BCYAN:-}" "$(_msg label_llm)" "${C_RST:-}" "$col_model" \
    "${C_BCYAN:-}" "$(_msg label_temp)" "${C_RST:-}" "$col_temp" \
    "${C_BCYAN:-}" "$(_msg label_stream)" "${C_RST:-}" "$col_stream" >&2
}

show_config_menu() {
  while true; do
    local config_title=" $(_msg config_title) "
    printf '\n%b%b%s%b\n' "${C_BANNER:-}" "$config_title" "${C_RST:-}" >&2
    print_menu_item 1 "$(_msg config_opt_provider)" "${PROVIDER:-groq}"
    print_menu_item 2 "$(_msg config_opt_model)" "${MODEL:-<Default>}"
    print_menu_item 3 "$(_msg config_opt_key)" "$(provider_api_env_var_name "${PROVIDER:-groq}")" "$(_msg menu_env)"
    print_menu_item 4 "$(_msg config_opt_lang)" "${BASH4LLM_LANG:-en}"
    print_menu_item 5 "$(_msg config_opt_refresh)"
    print_menu_item 6 "$(_msg config_opt_list)"
    print_menu_item 7 "$(_msg config_opt_return)"
    
    # Separator is C_BBLUE
    printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2

    local m_sel
    printf '  %s ' "$(_msg config_prompt)" >&2
    if ! IFS= read -r m_sel; then
      return 0
    fi
    m_sel="$(trim "$m_sel")"
    printf '\n' >&2

    case "$m_sel" in
      1)
        printf '\n  %s\n' "$(_msg config_providers_installed "$SUPPORTED_PROVIDERS")" >&2
        printf '  %s ' "$(_msg config_provider_prompt)" >&2
        local new_prov
        if IFS= read -r new_prov; then
          new_prov="$(trim "$new_prov")"
          if [ -n "$new_prov" ]; then
            case " $SUPPORTED_PROVIDERS " in
              *" $new_prov "*)
                PROVIDER="$new_prov"
                load_provider_module "$PROVIDER" >/dev/null 2>&1 || true
                resolve_provider_url "$PROVIDER" >/dev/null 2>&1 || true
                resolve_model >/dev/null 2>&1 && MODEL="${FINAL_MODEL:-}"
                printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_provider_success "$PROVIDER")" "${C_RST:-}" >&2
                ;;
              *) printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg config_provider_unknown)" "${C_RST:-}" >&2 ;;
            esac
          fi
        fi
        ;;
      2)
        printf '\n  %s ' "$(_msg config_model_prompt)" >&2
        local new_model
        if IFS= read -r new_model; then
          new_model="$(trim "$new_model")"
          if [ -n "$new_model" ]; then
            if validate_model_dispatch "$new_model" >/dev/null 2>&1; then
              MODEL="$new_model"
              printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_model_success "$MODEL")" "${C_RST:-}" >&2
            else
              printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg config_model_invalid)" "${C_RST:-}" >&2
            fi
          fi
        fi
        ;;
      3)
        local key_var
        key_var="$(provider_api_env_var_name "${PROVIDER:-groq}")"
        local key_val="${!key_var:-}"
        printf '\n  %s\n' "$(_msg config_key_title "$key_var" "${key_val:-<not set>}")" >&2
        printf '  %s ' "$(_msg config_key_prompt)" >&2
        local new_key
        if IFS= read -r new_key; then
          new_key="$(trim "$new_key")"
          if [ -n "$new_key" ]; then
            export "${key_var}=${new_key}"
            if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_key_success)" "${C_RST:-}" >&2
          fi
        fi
        ;;
      4)
        prompt_lang_selection
        load_lang_secure "$BASH4LLM_LANG"
        printf '\n  %sLanguage set to: %s%s\n' "${C_GREEN:-}" "$BASH4LLM_LANG" "${C_RST:-}" >&2
        ;;
      5)
        printf '\n  %s\n' "$(_msg config_refresh_start)" >&2
        if ensure_api_key_for_provider "$PROVIDER"; then
          if refresh_models_dispatch; then
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_refresh_success)" "${C_RST:-}" >&2
          else
            printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg config_refresh_failed)" "${C_RST:-}" >&2
          fi
        fi
        ;;
      6)
        local cached_title=" $(_msg config_cached_title "$PROVIDER") "
        printf '\n%b%b%s%b\n\n' "${BG_WHITE:-}" "${C_BBLUE:-}" "$cached_title" "${C_RST:-}" >&2
        list_models_cli >&2 || true
        printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2
        ;;
      7 | q | Q | "")
        return 0
        ;;
      * )
        printf '\n  %sInvalid option!%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

show_tools_menu() {
  while true; do
    local tools_title=" $(_msg tools_title) "
    printf '\n%b%b%s%b\n' "${C_BANNER:-}" "$tools_title" "${C_RST:-}" >&2
    print_menu_item 1 "$(_msg tools_opt_rename)" "${SESSION_ID:-}"
    print_menu_item 2 "$(_msg tools_opt_delete)"
    print_menu_item 3 "$(_msg tools_opt_start)"
    
    local stream_state
    if [ "${STREAM_MODE:-0}" -eq 1 ]; then
      stream_state="$(_msg status_enabled)"
    else
      stream_state="$(_msg status_disabled)"
    fi
    print_menu_item 4 "$(_msg tools_opt_stream)" "$stream_state" "$(_msg menu_status)"
    print_menu_item 5 "$(_msg tools_opt_status)"
    print_menu_item 6 "$(_msg tools_opt_return)"

    # Separator is C_BBLUE
    printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2

    local m_sel
    printf '  %s ' "$(_msg tools_prompt)" >&2
    if ! IFS= read -r m_sel; then
      return 0
    fi
    m_sel="$(trim "$m_sel")"
    printf '\n' >&2

    case "$m_sel" in
      1)
        printf '\n  %s ' "$(_msg tools_rename_prompt)" >&2
        local new_title
        if IFS= read -r new_title; then
          new_title="$(trim "$new_title")"
          if [ -n "$new_title" ]; then
            session_rename_core "$SESSION_ID" "$new_title"
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg tools_rename_success)" "${C_RST:-}" >&2
          fi
        fi
        ;;
      2)
        printf '\n  %s ' "$(_msg tools_delete_warn "$SESSION_ID")" >&2
        local confirm
        if IFS= read -r confirm; then
          confirm="$(trim "$confirm")"
          if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
            session_delete_core "$SESSION_ID"
            printf '\n  %s%s%s\n' "${C_YELLOW:-}" "$(_msg tools_delete_success)" "${C_RST:-}" >&2
            sleep 1
            load_sessions_wizard
            return 0
          else
            printf '\n  %s\n' "$(_msg tools_delete_cancel)" >&2
          fi
        fi
        ;;
      3)
        SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_sess_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
        : > "$new_sess_file"
        chmod 600 "$new_sess_file"
        printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg tools_new_session "$SESSION_ID")" "${C_RST:-}" >&2
        return 0
        ;;
      4)
        if [ "${STREAM_MODE:-0}" -eq 1 ]; then
          STREAM_MODE=0
          printf '\n  %s%s%s\n' "${C_YELLOW:-}" "$(_msg tools_stream_disabled)" "${C_RST:-}" >&2
        else
          STREAM_MODE=1
          printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg tools_stream_enabled)" "${C_RST:-}" >&2
        fi
        ;;
      5)
        local diag_title=" $(_msg tools_diag_title) "
        printf '\n%b%b%s%b\n\n' "${BG_WHITE:-}" "${C_BBLUE:-}" "$diag_title" "${C_RST:-}" >&2
        print_status_bar
        
        # Fixed labels in C_BCYAN, trailing paths / outputs in plain reset color
        printf "  %b%s%b %s/sessions/%s.ndjson\n" "${C_BCYAN:-}" "$(_msg label_diag_session)" "${C_RST:-}" "${BASH4LLM_HISTORY_DIR}" "${SESSION_ID}" >&2
        printf "  %b%s%b %s/config\n" "${C_BCYAN:-}" "$(_msg label_diag_config)" "${C_RST:-}" "${BASH4LLM_CONFIG_DIR}" >&2
        printf "  %b%s%b %s\n" "${C_BCYAN:-}" "$(_msg label_diag_history)" "${C_RST:-}" "${HISTFILE}" >&2
        
        printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2
        ;;
      6 | q | Q | "")
        return 0
        ;;
      * )
        printf '\n  %sInvalid option!%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

# --- PHASE 8: INTERACTIVE REPL CHAT LOOP ---
run_repl() {
  if [ -z "$SESSION_ID" ]; then
    load_sessions_wizard
  fi

  print_banner
  # Automated print_status_bar call removed from startup for visual cleanliness

  set +e 2>/dev/null || true
  set +u 2>/dev/null || true

  while true; do
    local prompt_sym prompt_str
    prompt_sym="$(_msg prompt_tu)"
    prompt_str="${RL_START}${C_BCYAN:-}${RL_END}${prompt_sym} ${RL_START}${C_RST:-}${RL_END}"

    local userline=""
    IFS= read -r -e -p "$prompt_str" userline
    local read_rc=$?

    if [ "$read_rc" -ne 0 ]; then
      if [ "$read_rc" -eq 130 ]; then
        printf '\n' >&2
        continue
      fi
      printf '\n%s\n' "$(_msg exited)" >&2
      break
    fi

    userline="$(trim "$userline")"
    [ -z "$userline" ] && continue

    history -s "$userline" 2>/dev/null || true
    history -w "$HISTFILE" 2>/dev/null || true

    case "$userline" in
      /exit | /quit)
        break
        ;;
      /clear)
        if [ -t 1 ]; then
          clear 2>/dev/null || printf '\033[H\033[2J' >&2
        fi
        print_banner
        continue
        ;;
      /help | /\?)
        printf "\n${C_LOGO:-}.  %s   ${C_RST:-}\n" "$(_msg cmd_help_title)" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/help, /?" "$( _msg help_desc_help )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/exit, /quit" "$( _msg help_desc_exit )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/clear" "$( _msg help_desc_clear )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/reset-session" "$( _msg help_desc_reset )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/history [n]" "$( _msg help_desc_history )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/config" "$( _msg help_desc_config )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/menu" "$( _msg help_desc_menu )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/undo" "$( _msg help_desc_undo )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/status" "$( _msg help_desc_status )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/system [prompt]" "$( _msg help_desc_system )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/model [name]" "$( _msg help_desc_model )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/file <path>" "$( _msg help_desc_file )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/block" "$( _msg help_desc_block )" >&2
        printf "  ${C_BGREEN:-}%-15s${C_RST:-} %s\n" "/edit" "$( _msg help_desc_edit )" >&2
        
        printf "\n${C_LOGO:-} %s ${C_RST:-}\n" "$(_msg cmd_help_shortcuts_title)" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + D" "$( _msg help_sc_d_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + C" "$( _msg help_sc_c_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + L" "$( _msg help_sc_l_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + A / E" "$( _msg help_sc_ae_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + U / K" "$( _msg help_sc_uk_desc )" >&2
        
        # Help footer is C_BGREEN
        printf '%b----------------------------------------%b\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
        continue
        ;;
      /reset-session)
        printf '\n  %s ' "$(_msg cmd_reset_warn)" >&2
        local confirm
        IFS= read -r confirm
        confirm="$(trim "$confirm")"
        if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
          local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
          : > "$session_file" 2>/dev/null
          if type session_cache_invalidate >/dev/null 2>&1; then
            session_cache_invalidate "$SESSION_ID" >/dev/null 2>&1 || true
          fi
          printf '\n  %s%s%s\n\n' "${C_YELLOW:-}" "$(_msg cmd_reset_success)" "${C_RST:-}" >&2
        else
          printf '\n  %s\n\n' "$(_msg cmd_reset_cancel)" >&2
        fi
        continue
        ;;
      /history | /history\ *)
        local opt="${userline#/history}"
        opt="$(trim "$opt")"
        local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"

        if [ ! -f "$session_file" ] || [ ! -s "$session_file" ]; then
          printf '\n  %s%s%s\n\n' "${C_YELLOW:-}" "$(_msg cmd_history_empty)" "${C_RST:-}" >&2
          continue
        fi

        local lines_to_read=40
        local print_alert=0
        if [ -z "$opt" ]; then
          lines_to_read=40
          print_alert=1
        elif [ "$opt" = "-all" ]; then
          lines_to_read=999999
        elif printf '%s\n' "$opt" | grep -qE '^[0-9]+$'; then
          lines_to_read=$(( opt * 2 ))
        else
          printf '  %s\n' "$(_msg cmd_history_syntax)" >&2
          continue
        fi

        local tmp_hist
        tmp_hist="$(_tmpf file "$RUN_TMPDIR" hist_preview 2>/dev/null)"
        if [ -n "$tmp_hist" ]; then
          if [ "$print_alert" -eq 1 ]; then
            _msg cmd_history_alert 20; printf '\n\n' >> "$tmp_hist"
          fi

          tail -n "$lines_to_read" "$session_file" | while IFS= read -r line || [ -n "$line" ]; do
            local role content
            role="$(printf '%s' "$line" | jq -r '.role // empty' 2>/dev/null)"
            content="$(printf '%s' "$line" | jq -r '.content // empty' 2>/dev/null)"
            local u_prompt
            u_prompt="$(_msg prompt_tu)"
            if [ "$role" = "user" ]; then
              printf '%s%s >%s\n%s\n\n' "${C_BCYAN:-}" "$u_prompt" "${C_RST:-}" "$content" >> "$tmp_hist"
            elif [ "$role" = "assistant" ]; then
              printf '%s%s - %s >%s\n%s\n\n' "${C_BGREEN:-}" "$PROVIDER" "$MODEL" "${C_RST:-}" "$content" >> "$tmp_hist"
            fi
          done

          if command -v less >/dev/null 2>&1; then
            less -R "$tmp_hist"
          else
            cat "$tmp_hist" | head -n 100
          fi
          rm -f "$tmp_hist" 2>/dev/null || true
        fi
        continue
        ;;
      /config)
        show_config_menu
        continue
        ;;
      /menu)
        show_tools_menu
        continue
        ;;
      /undo)
        local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
        if [ -f "$session_file" ] && [ -s "$session_file" ]; then
          local total_lines
          total_lines="$(wc -l < "$session_file" 2>/dev/null | tr -d ' ' || echo 0)"
          if [ "$total_lines" -ge 2 ]; then
            local tmp_undo
            tmp_undo="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" undo 2>/dev/null)"
            if [ -n "$tmp_undo" ]; then
              head -n "$((total_lines - 2))" "$session_file" > "$tmp_undo" 2>/dev/null \
                && mv -f "$tmp_undo" "$session_file" 2>/dev/null || true
              rm -f "$tmp_undo" 2>/dev/null || true
              if type session_cache_invalidate >/dev/null 2>&1; then
                session_cache_invalidate "$SESSION_ID" >/dev/null 2>&1 || true
              fi
              printf '\n%s%s%s\n\n' "${C_YELLOW:-}" "$(_msg cmd_undo_success)" "${C_RST:-}" >&2
            else
              printf '%s\n' "$(_msg cmd_undo_error_tmp)" >&2
            fi
          elif [ "$total_lines" -eq 1 ]; then
            : > "$session_file" 2>/dev/null || true
            printf '\n%s%s%s\n\n' "${C_YELLOW:-}" "$(_msg cmd_undo_truncated)" "${C_RST:-}" >&2
          else
            printf '\n%s\n\n' "$(_msg cmd_undo_empty)" >&2
          fi
        else
          printf '\n%s\n\n' "$(_msg cmd_undo_no_hist)" >&2
        fi
        continue
        ;;
      /status)
        local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
        local msg_count=0 size_bytes=0
        if [ -f "$session_file" ]; then
          msg_count="$(wc -l < "$session_file" 2>/dev/null | tr -d ' ' || echo 0)"
          size_bytes="$(file_size "$session_file" 2>/dev/null || echo 0)"
        fi
        local stat_title=" $(_msg cmd_status_title) "
        printf '\n%b%b%s%b\n\n' "${BG_WHITE:-}" "${C_BBLUE:-}" "$stat_title" "${C_RST:-}" >&2
        
        # Labels in C_CYAN, parameters natively processed inside standard error streams
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_provider)" "${C_RST:-}" "$(color_attributes "${PROVIDER:-}")" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_model)" "${C_RST:-}" "$(color_attributes "${MODEL:-}")" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_temp)" "${C_RST:-}" "${TEMPERATURE:-1.0}" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_session)" "${C_RST:-}" "$(color_attributes "${SESSION_ID:-}")" >&2
        
        local bytes_msgs_fmt
        bytes_msgs_fmt="$(_msg cmd_status_bytes_msgs "$size_bytes" "$msg_count")"
        printf "  %b%s%b : %s (%s)\n" "${C_CYAN:-}" "$(_msg cmd_status_file)" "${C_RST:-}" "$(basename "$session_file")" "$bytes_msgs_fmt" >&2
        
        if [ -n "${SYSTEM_PROMPT:-}" ]; then
          printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_sys_prompt)" "${C_RST:-}" "${SYSTEM_PROMPT}" >&2
        else
          printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_sys_prompt)" "${C_RST:-}" "$(color_attributes "$(_msg cmd_status_sys_not_set)")" >&2
        fi
        printf '\n' >&2
        continue
        ;;
      /system | /system\ *)
        if [ "$userline" = "/system" ]; then
          if [ -n "${SYSTEM_PROMPT:-}" ]; then
            printf '\n%s\n%s\n\n' "$(_msg cmd_system_active)" "${SYSTEM_PROMPT}" >&2
          else
            printf '\n%s\n\n' "$(_msg cmd_system_not_set)" >&2
          fi
        else
          local new_sys="${userline#/system }"
          SYSTEM_PROMPT="$(printf '%s' "$new_sys" | awk '{$1=$1;print}')"
          printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_system_updated)" "${C_RST:-}" >&2
        fi
        continue
        ;;
      /model\ *)
        local new_model="${userline#/model }"
        new_model="$(printf '%s' "$new_model" | tr -d -c 'A-Za-z0-9._/:-' | awk '{$1=$1;print}')"
        if [ -z "$new_model" ]; then
          printf '%s\n' "$(_msg cmd_model_invalid)" >&2
        else
          if validate_model_dispatch "$new_model" >/dev/null 2>&1; then
            MODEL="$new_model"
            printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_model_success "$MODEL")" "${C_RST:-}" >&2
          else
            printf '%s\n' "$(_msg cmd_model_not_supported "$new_model")" >&2
          fi
        fi
        continue
        ;;
      /file\ *)
        local file_cmd_args="${userline#/file }"
        file_cmd_args="$(printf '%s' "$file_cmd_args" | awk '{$1=$1;print}')"
        if [ -z "$file_cmd_args" ]; then
          printf '%s\n' "$(_msg cmd_file_syntax)" >&2
          continue
        fi

        local file_path file_prompt file_size file_content combined_prompt
        file_path="$(printf '%s' "$file_cmd_args" | awk '{print $1}')"
        file_prompt="$(printf '%s' "$file_cmd_args" | cut -d' ' -f2-)"
        if [ "$file_path" = "$file_cmd_args" ]; then
          file_prompt=""
        fi

        if [ ! -f "$file_path" ] || [ ! -r "$file_path" ]; then
          printf '%s\n' "$(_msg cmd_file_not_found "$file_path")" >&2
          continue
        fi

        file_size="$(file_size "$file_path" 2>/dev/null || echo 0)"
        if [ "$file_size" -gt 102400 ]; then
          printf '%s\n' "$(_msg cmd_file_limit "$file_path" "$((file_size / 1024))")" >&2
          continue
        fi

        file_content="$(cat "$file_path" 2>/dev/null || true)"
        if [ -n "$file_prompt" ]; then
          combined_prompt="$(printf 'Prompt: %s\n\n[File Attached: %s]\n---\n%s\n---\n' \
            "$file_prompt" "$(basename "$file_path")" "$file_content")"
        else
          combined_prompt="$(printf '[File Attached: %s]\n---\n%s\n---\n' \
            "$(basename "$file_path")" "$file_content")"
        fi

        CONTENT="$combined_prompt"
        ;;
      /block)
        printf '%s\n' "$(_msg cmd_block_enter)" >&2
        local block_content="" block_line="" read_block_rc=0
        while true; do
          block_line=""
          IFS= read -r -e -p "  | " block_line
          read_block_rc=$?
          if [ "$read_block_rc" -ne 0 ]; then
            printf '\n%s\n' "$(_msg cmd_block_interrupted)" >&2
            block_content=""
            break
          fi
          if [ "$block_line" = "/end" ]; then
            break
          fi
          if [ -z "$block_content" ]; then
            block_content="$block_line"
          else
            block_content="${block_content}"$'\n'"$block_line"
          fi
        done
        if [ -n "$block_content" ]; then
          CONTENT="$block_content"
        else
          continue
        fi
        ;;
      /edit)
        local editor="${EDITOR:-}"
        if [ -z "$editor" ]; then
          if command -v nano >/dev/null 2>&1; then
            editor="nano"
          elif command -v vi >/dev/null 2>&1; then
            editor="vi"
          else
            printf '%s\n' "$(_msg cmd_edit_no_editor)" >&2
            continue
          fi
        fi

        local tmp_edit_file
        tmp_edit_file="$(_tmpf file "$RUN_TMPDIR" edit 2>/dev/null)"
        if [ -z "$tmp_edit_file" ] || [ ! -f "$tmp_edit_file" ]; then
          printf '%s\n' "$(_msg cmd_edit_error_tmp)" >&2
          continue
        fi

        "$editor" "$tmp_edit_file"

        if [ -s "$tmp_edit_file" ]; then
          CONTENT="$(cat "$tmp_edit_file")"
        else
          printf '%s\n' "$(_msg cmd_edit_empty)" >&2
          rm -f "$tmp_edit_file" 2>/dev/null || true
          continue
        fi
        rm -f "$tmp_edit_file" 2>/dev/null || true
        ;;
      /*)
        printf '  %s\n' "$(_msg cmd_unknown_slash)" >&2
        continue
        ;;
    esac

    if [ -z "${CONTENT:-}" ] && [ -n "${userline:-}" ]; then
      CONTENT="$userline"
    fi

    BUILD_MESSAGES_FILE="$RUN_TMPDIR/session-${SESSION_ID}-messages.json"
    export BUILD_MESSAGES_FILE

    if [ "${BASH4LLM_PLAT_WSL:-0}" -eq 1 ] || [ "${BASH4LLM_PLAT_LINUX:-0}" -eq 1 ] || [ -n "${BASH_VERSION:-}" ]; then
      if [ -n "${BASH4LLM_CONFIG_DIR:-}" ]; then
        _engine_available=0
        _engine_path="${BASH4LLM_EXTRAS_DIR:-}/session/session-engine.sh"
        if [ -f "$_engine_path" ] && type session_engine_build_window >/dev/null 2>&1; then
          _engine_available=1
        fi
      fi
    fi

    if [ "${_engine_available:-0}" -eq 1 ]; then
      session_engine_build_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "${BASH4LLM_SESSION_TARGET_BYTES:-}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 \
        || session_read_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    else
      session_read_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    fi

    if ! build_payload_from_vars >/dev/null 2>&1; then
      log_error "TUI" "$(_msg cmd_err_payload)"
      continue
    fi

    if ! ensure_api_key_for_provider "$PROVIDER"; then
      log_error "APIKEY" "$(_msg cmd_err_key "$PROVIDER")"
      continue
    fi

    printf '\n%s%s - %s:%s\n' "${C_BGREEN:-}" "$PROVIDER" "$MODEL" "${C_RST:-}" >&2

    # Invoking standard streaming or core execution pathways securely on stderr
    IS_STREAMING=1
    local call_rc=0
    if [ "${STREAM_MODE:-0}" -eq 1 ]; then
      call_api_streaming
      call_rc=$?
    else
      perform_request_once
      call_rc=$?
    fi
    IS_STREAMING=0

    if [ "$call_rc" -eq 0 ] && [ "${DRY_RUN:-0}" -ne 1 ]; then
      local meta_source="cli"
      local meta_cmd="$(session_sanitize_cmd "$0")"
      local meta_json
      meta_json="$(jq -c -n --arg source "$meta_source" --arg cmd "$meta_cmd" --arg id "" '{source:$source, cmd:$cmd, id:$id}')"

      if [ "${_engine_available:-0}" -eq 1 ]; then
        session_engine_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 \
          || session_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      else
        session_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      fi

      if [ -s "${RESP:-}" ]; then
        local assistant_text
        assistant_text="$(extract_text_from_resp 2>/dev/null || true)"
        assistant_text="$(printf '%s' "$assistant_text" | sed -e 's/\r$//' -e '/^[[:space:]]*$/d' || true)"
        if [ -n "$assistant_text" ]; then
          meta_source="provider"
          meta_json="$(jq -c -n --arg source "$meta_source" --arg model "$MODEL" --arg id "" '{source:$source, model:$model, id:$id}')"

          if [ "${_engine_available:-0}" -eq 1 ]; then
            session_engine_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 \
              || session_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          else
            session_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          fi
        fi
      fi
    fi

    unset CONTENT
    printf '\n' >&2
  done

  stty echo 2>/dev/null || true
  return 0
}

# --- OPERATIONAL ENTRY POINT ---
run_repl

if ! type cleanup_run_tmp_on_exit >/dev/null 2>&1; then
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "$RUN_TMPDIR" ]; then
    case "$RUN_TMPDIR" in
      "$BASH4LLM_TMPDIR"/*)
        rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
        ;;
    esac
  fi
fi
exit 0
