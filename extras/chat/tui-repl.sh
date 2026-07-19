#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/chat/tui-repl.sh
# Component: TUI REPL Interactive Module (Refactored Thread Version - Part 1)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

# Disable history recording globally during the parsing phase to prevent pollution
set +o history 2>/dev/null || true

# Prevent unbound variables
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

# Ensure an interactive TTY environment is active
if [ ! -t 0 ] || [ ! -t 1 ]; then
  printf 'tui-repl.sh: ERROR: TUI REPL requires a valid and active interactive TTY.\n' >&2
  exit 15
fi

# --- PHASE 2: TERMINAL CLEANUP AND SIGNAL LIFECYCLE MANAGEMENT ---

# Clean up terminal state, disable bracketed paste, and release concurrency locks on exit
tui_cleanup() {
  local rc=$?
  
  # Ensure terminal echo is restored in case of abnormal interruption
  stty echo 2>/dev/null || true
  
  # Disable Bracketed Paste Mode safely before exiting to restore standard TTY state
  printf '\e[?2004l' >&2
  
  # Release active parent thread locks
  if type release_thread_lock >/dev/null 2>&1; then
    release_thread_lock 2>/dev/null || true
  fi
  
  # Delete temporary files tied to the current execution process
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "$RUN_TMPDIR" ]; then
    case "$RUN_TMPDIR" in
      "$BASH4LLM_TMPDIR"/*)
        rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
        ;;
    esac
  fi
  
  # Unset EXIT trap before calling exit to prevent redundant recursion
  trap - EXIT
  exit "$rc"
}

# Trap system signals to ensure graceful shutdown and execution of the cleanup routine
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 1' HUP QUIT
trap tui_cleanup EXIT

# Override core's tac_fallback with a robust, pipe-compatible version
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

# Formatting utility for bracketed attributes wrapped in <...> with C_YELLOW
color_attributes() {
  local text="$1"
  if [ -n "${C_YELLOW:-}" ]; then
    local tmp="${text//</${C_YELLOW}<}"
    printf '%s' "${tmp//>/>${C_RST:-}}"
  else
    printf '%s' "$text"
  fi
}

# --- PHASE 3: REPL STATE AND VARIABLE INITIALIZATION ---
THREAD_ID="${BASH4LLM_ACTIVE_THREAD:-}"
MODEL="${BASH4LLM_ACTIVE_MODEL:-}"

# Inherit global parameters with safe, validated defaults
TEMPERATURE="${TEMPERATURE:-${TURE:-1.0}}"
TURE="$TEMPERATURE"
MAX_TOKENS="${MAX_TOKENS:-4096}"
THRESHOLD="${THRESHOLD:-1000}"
OUTPUT_MODE="${OUTPUT_MODE:-text}"

# Synchronize the TUI session window with the core's THREAD_WINDOW CLI parameter
SESSION_WINDOW="${THREAD_WINDOW:-10}"

# State variable for the Incognito/Private mode
PRIVATE_MODE=0
# Backup of the previous HISTFILE to restore when toggling private mode off
ORIG_HISTFILE=""

# Synchronize model cache path for the current provider
sync_models_file_path

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

# --- PHASE 4: DECLARATIVE DICTIONARIES & SECURE i18n PARSER ---
declare -A T_MSG

# Load translation properties file with strict alphanumeric key validation
load_lang_secure() {
  local lang_code="${1:-en}"
  local lang_dir
  lang_dir="$(dirname "${BASH_SOURCE[0]}")/langs"
  local lang_file="${lang_dir}/${lang_code}.properties"

  local rx_lang='^[a-z]{2}$'
  if [[ ! "$lang_code" =~ $rx_lang ]]; then
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

  local key val safe_key trimmed_val
  while IFS='=' read -r key val || [ -n "$key" ]; do
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    safe_key="${key//[!A-Za-z0-9_]/}"
    [ -n "$safe_key" ] || continue

    trimmed_val="${val//$'\r'/}"
    trimmed_val="$(trim_space "$trimmed_val")"

    T_MSG["$safe_key"]="$trimmed_val"
  done < "$lang_file"
}

# Helper to retrieve translated strings by key with formatting support
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

# Read persisted language from local configuration file
get_stored_lang() {
  local cfg_dir="${BASH4LLM_CONFIG_DIR:-}"
  local cfg_file="${cfg_dir%/}/config"
  local stored_lang=""
  
  if [ -f "$cfg_file" ]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == BASH4LLM_LANG=* ]]; then
        stored_lang="${line#BASH4LLM_LANG=}"
        break
      fi
    done < "$cfg_file"
    
    stored_lang="${stored_lang// /}"
    stored_lang="${stored_lang,,}"
  fi
  printf '%s' "$stored_lang"
}

# Safely write chosen language preference to the configuration file
save_lang_config() {
  local lang="${1:-en}"
  local cfg_dir="${BASH4LLM_CONFIG_DIR:-}"
  local cfg_file="${cfg_dir%/}/config"
  local tmp_cfg
  
  safe_mkdir "$(dirname "$cfg_file")" 700
  
  tmp_cfg="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" config_update 2>/dev/null)"
  if [ -z "$tmp_cfg" ]; then
    tmp_cfg="${BASH4LLM_TMPDIR:-/tmp}/.config_update.$$.tmp"
  fi
  
  if [ -f "$cfg_file" ]; then
    grep -v "^BASH4LLM_LANG=" "$cfg_file" > "$tmp_cfg" 2>/dev/null || true
  fi
  
  printf 'BASH4LLM_LANG=%s\n' "$lang" >> "$tmp_cfg"
  
  atomic_write "$cfg_file" 10 < "$tmp_cfg"
  rm -f "$tmp_cfg" 2>/dev/null || true
}

# Interactive language selection wizard
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
    printf '  %s (1-5) [Default: 1]: ' "$(_msg config_prompt)" >&2
    if ! IFS= read -r choice; then
      printf '\n' >&2
      choice="1"
    fi
    choice="${choice// /}"
    [ -z "$choice" ] && choice="1"

    case "$choice" in
      1) selected_lang="en"; break ;;
      2) selected_lang="it"; break ;;
      3) selected_lang="es"; break ;;
      4) selected_lang="fr"; break ;;
      5) selected_lang="de"; break ;;
      *)
        printf '\n  %s\n' "$(_msg wizard_invalid_choice)" >&2
        sleep 1
        ;;
    esac
  done

  save_lang_config "$selected_lang"
  BASH4LLM_LANG="$selected_lang"
  export BASH4LLM_LANG
}

# Perform safe i18n bootstrapping and load language arrays
bootstrap_i18n() {
  local lang
  lang="$(get_stored_lang)"

  if [ -z "$lang" ]; then
    # Load fallback language so the prompt itself can render
    load_lang_secure "en" >/dev/null 2>&1 || true
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

# --- PHASE 5: INPUT HISTORY CONFIGURATION (ISOLATED READLINE) ---

# Define Readline configuration parameters (history stays disabled during load)
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTFILE="${BASH4LLM_HISTORY_DIR:-}/tui_history"

# Securely initialize the local command history storage file if missing
if [ ! -f "$HISTFILE" ]; then
  : > "$HISTFILE" 2>/dev/null
  chmod 600 "$HISTFILE" 2>/dev/null || true
fi

# Escape sequences wrapping readline-rendered non-printing characters to prevent cursor desync
RL_START=$'\001'
RL_END=$'\002'
# --- PHASE 6: SEQUENTIAL RENDERING UTILITIES ---

# Render the stylized main header banner of the application
print_banner() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  local b_title b_sess b_help
  b_title="$(_msg banner_title)"
  
  local r_sess="${THREAD_ID:-}"
  local r_prov="${PROVIDER:-groq}"
  local r_model="${MODEL:-}"

  [ -n "$r_sess" ] || r_sess="$(_msg attribute_none)"
  [ -n "$r_model" ] || r_model="$(_msg attribute_default)"

  # Apply non-destructive color styling to state configurations
  local col_sess="${C_YELLOW:-}${r_sess}${C_RST:-}"
  local col_prov="${C_YELLOW:-}${r_prov}${C_RST:-}"
  local col_model="${C_YELLOW:-}${r_model}${C_RST:-}"

  b_sess="$(_msg banner_session_full "$col_sess" "$col_prov" "$col_model")"
  
  b_help="$(_msg banner_help)"
  b_help="$(color_attributes "$b_help")"

  # Print banner outputs directly to stderr to safeguard standard output redirection
  printf '%b' "
${C_LOGO:-} Bash4LLM⁺ ${C_RST:-} ${C_BGREEN:-} ${b_title} ${C_RST:-}
  ${b_sess}
  ${b_help}
${C_BGREEN:-}----------------------------------------${C_RST:-}
" >&2
}

# Standardize date output strings safely
_format_ts() {
  local ts="${1:-}"
  if [ -n "$ts" ]; then
    printf '%s' "${ts:0:10}"
  else
    printf '%s' "$(_msg attribute_na)"
  fi
}

# Print standardized modular configuration items inside interactive menus
print_menu_item() {
  local index="$1"
  local desc="$2"
  local value="${3:-}"
  local label="${4:-$(_msg menu_current)}"

  local colored_val
  colored_val="$(color_attributes "$value")"

  if [ -n "$value" ]; then
    printf "  ${C_BCYAN:-}%d)${C_RST:-} %-26s (${C_CYAN:-}%s${C_RST:-}: %s)\n" "$index" "$desc" "$label" "$colored_val" >&2
  else
    printf "  ${C_BCYAN:-}%d)${C_RST:-} %s\n" "$index" "$desc" >&2
  fi
}

# Display a unified horizontal parameter layout block
print_status_bar() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  local stream_status
  if [ "${STREAM_MODE:-0}" -eq 1 ]; then
    stream_status="$(_msg status_enabled)"
  else
    stream_status="$(_msg status_disabled)"
  fi

  local r_sess="${THREAD_ID:-}"
  local r_model="${MODEL:-}"
  [ -n "$r_sess" ] || r_sess="$(_msg attribute_none)"
  [ -n "$r_model" ] || r_model="$(_msg attribute_default)"

  # Print active parameters including the contextual Incognito indicator
  local col_sess="${C_YELLOW:-}${r_sess}${C_RST:-}"
  if [ "$PRIVATE_MODE" -eq 1 ]; then
    col_sess="${C_BRED:-}$(_msg status_private_mode)${C_RST:-}"
  fi

  local col_model="${C_YELLOW:-}${r_model}${C_RST:-}"
  local col_temp="${C_YELLOW:-}${TEMPERATURE:-1.0}${C_RST:-}"
  local col_tokens="${C_YELLOW:-}${MAX_TOKENS:-4096}${C_RST:-}"
  local col_threshold="${C_YELLOW:-}${THRESHOLD:-1000}${C_RST:-}"
  local col_format="${C_YELLOW:-}${OUTPUT_MODE:-text}${C_RST:-}"
  local col_stream="${C_YELLOW:-}${stream_status}${C_RST:-}"

  printf "  %b%s%b %s\n  %b%s%b %s | %b%s%b %s | %b%s%b %s | %b%s%b %s | %b%s%b %s | %b%s%b %s\n" \
    "${C_BCYAN:-}" "$(_msg label_repl_status)" "${C_RST:-}" "$col_sess" \
    "${C_BCYAN:-}" "$(_msg label_llm)" "${C_RST:-}" "$col_model" \
    "${C_BCYAN:-}" "$(_msg label_temp)" "${C_RST:-}" "$col_temp" \
    "${C_BCYAN:-}" "$(_msg label_tokens)" "${C_RST:-}" "$col_tokens" \
    "${C_BCYAN:-}" "$(_msg label_threshold)" "${C_RST:-}" "$col_threshold" \
    "${C_BCYAN:-}" "$(_msg label_format)" "${C_RST:-}" "$col_format" \
    "${C_BCYAN:-}" "$(_msg label_stream)" "${C_RST:-}" "$col_stream" >&2
}

# --- PHASE 7: PAGINATED THREAD SELECTION WIZARD ---

# Display previous conversation streams on disk inside a paginated selection menu
load_threads_wizard() {
  local hist_dir="${BASH4LLM_HISTORY_DIR:-}"
  local thread_dir="${hist_dir%/}/threads"
  safe_mkdir "$thread_dir" 700

  local -a files=()
  local mtime f
  while IFS='|' read -r mtime f; do
    if [ -f "$f" ] && [ "${f##*.}" = "ndjson" ]; then
      files+=("$f")
    fi
  done < <(list_files_sorted_by_mtime "$thread_dir" | tac_fallback)

  local total_threads="${#files[@]}"

  # Instantly generate a new thread if no historical logs are found
  if [ "$total_threads" -eq 0 ] || [ -z "${files:-}" ]; then
    THREAD_ID="thread-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
    local new_thread_file="${thread_dir}/${THREAD_ID}.ndjson"
    : > "$new_thread_file"
    chmod 600 "$new_thread_file"
    local init_msg
    init_msg="$(_msg wizard_no_sessions "$THREAD_ID")"
    log_info_user "TUI" "$init_msg"
    return 0
  fi

  local page_size=10
  local current_page=0
  local total_pages=$(( (total_threads + page_size - 1) / page_size ))

  while true; do
    if [ -t 1 ]; then
      clear 2>/dev/null || printf '\033[H\033[2J' >&2
    fi

    local w_title w_page
    w_title="$(_msg wizard_title)"
    w_page="$(_msg wizard_page "$((current_page + 1))" "$total_pages" "$total_threads")"

    printf '\n%b' "  ${C_BANNER:-}  ${w_title}  ${C_RST:-}\n\n" >&2
    printf "  %s\n" "${w_page}" >&2
    printf '%b' "  ${C_BBLUE:-}----------------------------------------${C_RST:-}\n\n" >&2

    local start_idx=$((current_page * page_size))
    local end_idx=$((start_idx + page_size))
    [ "$end_idx" -gt "$total_threads" ] && end_idx="$total_threads"

    local new_session_label="<$(_msg wizard_new_session)>"
    local colored_new_session="$(color_attributes "$new_session_label")"

    printf "  ${C_BCYAN:-}[ 1]${C_RST:-} %s\n\n" "$colored_new_session" >&2

    local i
    for ((i = start_idx; i < end_idx; i++)); do
      local s_file="${files[i]}"
      local filename="${s_file##*/}"
      local s_id="${filename%.ndjson}"

      local last_line last_ts last_date
      last_line="$(tail -n 1 "$s_file" 2>/dev/null || true)"
      last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      last_date="$(_format_ts "$last_ts")"

      local cfg_dir="${BASH4LLM_CONFIG_DIR:-}"
      local meta_file="${cfg_dir%/}/ui_state/threads/${s_id}.json"
      local title=""
      if [ -f "$meta_file" ]; then
        title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
      fi
      if [ -z "$title" ] && [ -f "$s_file" ]; then
        title="$(jq -r 'select(.role=="user") | .content' "$s_file" 2>/dev/null | head -n 1 || true)"
        title="${title//$'\n'/}"
        title="${title//$'\r'/}"
        title="${title:0:18}"
      fi
      [ -n "$title" ] || title="$(_msg thread_default_title "${s_id:0:8}")"

      printf "  ${C_BCYAN:-}[%2d]${C_RST:-} %s ${C_CYAN:-}>${C_RST:-} %s\n\n" \
        "$((i + 2))" "$last_date" "$title" >&2
    done

    printf '%b' "  ${C_BBLUE:-}----------------------------------------${C_RST:-}\n\n" >&2
    printf "  ${BG_WHITE:-}${C_BBLUE:-} %s: ${C_RST:-}\n" "$(_msg wizard_nav)" >&2
    printf "  [ + / n ] %s\n" "$(_msg wizard_next_page)" >&2
    printf "  [ - / p ] %s\n" "$(_msg wizard_prev_page)" >&2
    printf "  [   q   ] %s\n\n" "$(_msg wizard_exit_repl)" >&2
    printf '%b' "  ${C_BBLUE:-}----------------------------------------${C_RST:-}\n" >&2

    local choice
    printf '  %s ' "$(_msg wizard_prompt)" >&2
    if ! IFS= read -r choice; then
      printf '\n' >&2
      exit 0
    fi
    choice="$(trim_space "$choice")"
    printf '\n' >&2

    case "$choice" in
      + | n | N)
        current_page=$(( (current_page + 1) % total_pages ))
        ;;
      - | p | P)
        current_page=$(( (current_page - 1 + total_pages) % total_pages ))
        ;;
      1 | c | C | new | NEW)
        THREAD_ID="thread-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_thread_file="${thread_dir}/${THREAD_ID}.ndjson"
        : > "$new_thread_file"
        chmod 600 "$new_thread_file"
        break
        ;;
      q | Q | exit | EXIT)
        printf '\n%s\n' "$(_msg exited)" >&2
        exit 0
        ;;
      *)
        local rx_num='^[0-9]+$'
        if [[ "$choice" =~ $rx_num ]]; then
          local target_idx=$((choice - 2))
          if [ "$target_idx" -ge 0 ] && [ "$target_idx" -lt "$total_threads" ] && [ -n "${files[target_idx]+x}" ]; then
            local selected_file="${files[target_idx]}"
            local selfilename="${selected_file##*/}"
            THREAD_ID="${selfilename%.ndjson}"
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

# --- ASSISTED PROVIDER SELECTION (WIZARD) ---
select_provider_wizard() {
  local -a prov_arr=()
  local p i sel idx chosen prev_provider target_provider_file

  IFS=' ' read -r -a prov_arr <<< "${SUPPORTED_PROVIDERS:-groq}"

  if [ "${#prov_arr[@]}" -eq 0 ]; then
    printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_no_providers)" "${C_RST:-}" >&2
    return 1
  fi

  local title_val
  title_val="$(_msg config_provider_title)"

  printf '\n%b%s%b\n\n' "${C_BANNER:-}" " ${title_val} " "${C_RST:-}" >&2

  for ((i=0; i<${#prov_arr[@]}; i++)); do
    p="${prov_arr[i]}"
    if [ "$p" = "${PROVIDER:-}" ]; then
      printf "  ${C_BCYAN:-}[%2d]${C_RST:-} %s (%s)\n" "$((i + 1))" "$p" "$(_msg menu_current)" >&2
    else
      printf "  ${C_BCYAN:-}[%2d]${C_RST:-} %s\n" "$((i + 1))" "$p" >&2
    fi
  done

  printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2

  printf '  %s ' "$(_msg config_prompt)" >&2
  if ! IFS= read -r sel; then
    return 0
  fi
  sel="$(trim_space "$sel")"

  if [ -z "$sel" ] || [ "$sel" = "q" ] || [ "$sel" = "Q" ]; then
    return 0
  fi

  chosen=""
  if [[ "$sel" =~ ^[0-9]+$ ]]; then
    idx=$((sel - 1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#prov_arr[@]}" ]; then
      chosen="${prov_arr[idx]}"
    fi
  else
    for p in "${prov_arr[@]}"; do
      if [ "$p" = "$sel" ]; then
        chosen="$p"
        break
      fi
    done
  fi

  if [ -z "$chosen" ]; then
    printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg config_provider_unknown)" "${C_RST:-}" >&2
    sleep 1
    return 1
  fi

  prev_provider="${PROVIDER:-}"
  PROVIDER="$chosen"

  if ! ensure_config_dir; then
    log_error "PROVIDER" "cannot persist provider selection: config dir unavailable."
    PROVIDER="$prev_provider"
    return 1
  fi

  target_provider_file="$(canonical_provider_file)"
  if ! printf '%s\n' "$PROVIDER" | atomic_write "$target_provider_file" 10; then
    log_error "PROVIDER" "cannot persist provider selection to $target_provider_file."
    PROVIDER="$prev_provider"
    return 1
  fi

  chmod 600 "$target_provider_file" 2>/dev/null || true
  rm -f "$(canonical_provider_url_file)" 2>/dev/null || true

  load_provider_module "$PROVIDER" >/dev/null 2>&1 || true
  resolve_provider_url "$PROVIDER" >/dev/null 2>&1 || true

  if [ "$prev_provider" != "$PROVIDER" ]; then
    sync_models_file_path "$PROVIDER"
    resolve_model >/dev/null 2>&1 && MODEL="${FINAL_MODEL:-}"
  fi

  printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_provider_success "$PROVIDER")" "${C_RST:-}" >&2
  sleep 1
  return 0
}

# --- ASSISTED MODEL SELECTION (WIZARD) ---
select_model_wizard() {
  if [ ! -s "${MODELS_FILE:-}" ]; then
    printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_no_local_models)" "${C_RST:-}" >&2
    sleep 2
    return 1
  fi

  local -a models_arr=()
  local line norm

  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    norm="$(_normalize_model_name "$line")"
    if is_supported_model "$norm"; then
      models_arr+=("$norm")
    fi
  done < "$MODELS_FILE"

  local total_models="${#models_arr[@]}"
  if [ "$total_models" -eq 0 ]; then
    printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_no_compatible_models)" "${C_RST:-}" >&2
    sleep 2
    return 1
  fi

  local page_size=20
  local current_page=0
  local total_pages=$(( (total_models + page_size - 1) / page_size ))
  local title_val
  title_val="$(_msg config_model_title)"

  while true; do
    if [ -t 1 ]; then
      clear 2>/dev/null || printf '\033[H\033[2J' >&2
    fi

    printf '\n%b%s%b\n\n' "${C_BANNER:-}" " ${title_val} " "${C_RST:-}" >&2
    printf "  %s\n\n" "$(_msg model_wizard_page "$((current_page + 1))" "$total_pages" "$total_models")" >&2

    local start_idx=$((current_page * page_size))
    local end_idx=$((start_idx + page_size))
    [ "$end_idx" -gt "$total_models" ] && end_idx="$total_models"

    local i
    for ((i = start_idx; i < end_idx; i++)); do
      local m_name="${models_arr[i]}"
      if [ "$m_name" = "${MODEL:-}" ]; then
        printf "  ${C_BCYAN:-}[%2d]${C_RST:-} %s (%s)\n" "$((i + 1))" "$m_name" "$(_msg menu_current)" >&2
      else
        printf "  ${C_BCYAN:-}[%2d]${C_RST:-} %s\n" "$((i + 1))" "$m_name" >&2
      fi
    done

    printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2

    local btn_prev="${BG_WHITE:-}${C_BBLUE:-}< [ -/p ]${C_RST:-}"
    local btn_quit="${BG_WHITE:-}${C_BBLUE:-}[ q ] $(_msg word_exit)${C_RST:-}"
    local btn_next="${BG_WHITE:-}${C_BBLUE:-}[ +/n ] >${C_RST:-}"
    
    printf "  %s  %s  %s\n\n" "$btn_prev" "$btn_quit" "$btn_next" >&2

    local choice
    printf '  %s ' "$(_msg wizard_prompt)" >&2
    if ! IFS= read -r choice; then
      return 0
    fi
    choice="$(trim_space "$choice")"

    if [ -z "$choice" ] || [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
      return 0
    fi

    case "$choice" in
      + | n | N)
        current_page=$(( (current_page + 1) % total_pages ))
        ;;
      - | p | P)
        current_page=$(( (current_page - 1 + total_pages) % total_pages ))
        ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
          local target_idx=$((choice - 1))
          if [ "$target_idx" -ge 0 ] && [ "$target_idx" -lt "$total_models" ]; then
            MODEL="${models_arr[target_idx]}"
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_model_success "$MODEL")" "${C_RST:-}" >&2
            sleep 1
            return 0
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
}

# --- PHASE 8: PERSISTENT CONFIGURATION WRITER ---

# Save active configurations safely to the core config file using atomic writes
save_all_configs_to_file() {
  local cfg_file="${BASH4LLM_CONFIG_DIR:-}/config"
  local tmp_cfg
  safe_mkdir "$(dirname "$cfg_file")" 700
  tmp_cfg="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" config_save 2>/dev/null)"
  if [ -z "$tmp_cfg" ]; then
    tmp_cfg="${BASH4LLM_TMPDIR:-/tmp}/.config_save.$$.tmp"
  fi

  if [ -f "$cfg_file" ]; then
    grep -vE "^(MODEL|TEMPERATURE|TURE|MAX_TOKENS|FORMAT|THRESHOLD|BASH4LLM_LANG)=" "$cfg_file" > "$tmp_cfg" 2>/dev/null || true
  else
    : > "$tmp_cfg"
  fi

  # Append normalized global configuration values
  {
    printf 'MODEL=%s\n' "${MODEL:-}"
    printf 'TEMPERATURE=%s\n' "${TEMPERATURE:-1.0}"
    printf 'TURE=%s\n' "${TEMPERATURE:-1.0}"
    printf 'MAX_TOKENS=%s\n' "${MAX_TOKENS:-4096}"
    printf 'FORMAT=%s\n' "${OUTPUT_MODE:-text}"
    printf 'THRESHOLD=%s\n' "${THRESHOLD:-1000}"
    printf 'BASH4LLM_LANG=%s\n' "${BASH4LLM_LANG:-en}"
  } >> "$tmp_cfg"

  atomic_write "$cfg_file" 10 < "$tmp_cfg"
  rm -f "$tmp_cfg" 2>/dev/null || true
}

# --- PHASE 9: INTERACTIVE CONFIGURATION MENU ---

# Display and handle settings wizard inputs
show_config_menu() {
  while true; do
    local config_title=" $(_msg config_title) "
    printf '\n%b%b%s%b\n' "${C_BANNER:-}" "$config_title" "${C_RST:-}" >&2
    
    print_menu_item 1 "$(_msg config_opt_provider)" "${PROVIDER:-groq}"
    print_menu_item 2 "$(_msg config_opt_model)" "${MODEL:-<Default>}"
    print_menu_item 3 "$(_msg config_opt_key)" "$(provider_api_env_var_name "${PROVIDER:-groq}")" "$(_msg menu_env)"
    print_menu_item 4 "$(_msg config_opt_lang)" "${BASH4LLM_LANG:-en}"
    print_menu_item 5 "$(_msg config_opt_temp)" "${TEMPERATURE:-1.0}"
    print_menu_item 6 "$(_msg config_opt_tokens)" "${MAX_TOKENS:-4096}"
    print_menu_item 7 "$(_msg config_opt_threshold)" "${THRESHOLD:-1000}"
    print_menu_item 8 "$(_msg config_opt_format)" "${OUTPUT_MODE:-text}"
    print_menu_item 9 "$(_msg config_opt_refresh)"
    print_menu_item 10 "$(_msg config_opt_list)"
    print_menu_item 11 "$(_msg config_opt_return)"

    printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2

    local m_sel
    printf '  %s ' "$(_msg config_prompt)" >&2
    if ! IFS= read -r m_sel; then
      return 0
    fi
    m_sel="$(trim_space "$m_sel")"
    printf '\n' >&2

    case "$m_sel" in
      1)
        if select_provider_wizard; then
          save_all_configs_to_file
        fi
        ;;
      2)
        printf '\n  %s ' "$(_msg config_model_prompt_choice)" >&2
        local new_model
        if IFS= read -r new_model; then
          new_model="$(trim_space "$new_model")"
          if [ -z "$new_model" ]; then
            select_model_wizard
          else
            if validate_model_dispatch "$new_model" >/dev/null 2>&1; then
              MODEL="$new_model"
              printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_model_success "$MODEL")" "${C_RST:-}" >&2
              sleep 1
            else
              printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg config_model_invalid)" "${C_RST:-}" >&2
              sleep 1
            fi
          fi
          save_all_configs_to_file
        fi
        ;;
      3)
        local key_var key_val="" _u_set=0
        key_var="$(provider_api_env_var_name "${PROVIDER:-groq}")"
        case "$-" in *u*) _u_set=1; set +u;; esac
        key_val="${!key_var:-}"
        [ "$_u_set" -eq 1 ] && set -u
        
        printf '\n  %s\n' "$(_msg config_key_title "$key_var" "${key_val:-<not set>}")" >&2
        printf '  %s ' "$(_msg config_key_prompt)" >&2
        local new_key
        if IFS= read -r new_key; then
          new_key="$(trim_space "$new_key")"
          if [ -n "$new_key" ]; then
            local val_rc=0 loop_active=1
            while [ "$loop_active" -eq 1 ]; do
              printf '\n  %s\n' "$(_msg config_key_checking)" >&2
              validate_provider_key_dispatch "$new_key"
              val_rc=$?

              if [ "$val_rc" -eq 127 ]; then
                printf '\n  %s%s%s\n' "${C_YELLOW:-}" "$(_msg config_key_not_supported)" "${C_RST:-}" >&2
                export "${key_var}=${new_key}"
                if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
                loop_active=0
              elif [ "$val_rc" -eq 28 ]; then
                printf '\n  %s%s%s\n' "${C_BRED:-}" "$(_msg config_key_timeout)" "${C_RST:-}" >&2
                printf '  %s ' "$(_msg config_key_timeout_prompt)" >&2
                local timeout_choice
                if IFS= read -r timeout_choice; then
                  timeout_choice="$(trim_space "${timeout_choice,,}")"
                  if [ "$timeout_choice" = "r" ]; then
                    continue
                  elif [ "$timeout_choice" = "p" ]; then
                    export "${key_var}=${new_key}"
                    if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
                    printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_key_success)" "${C_RST:-}" >&2
                    loop_active=0
                  else
                    loop_active=0
                  fi
                else
                  loop_active=0
                fi
              elif [ "$val_rc" -eq 0 ]; then
                printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_key_valid)" "${C_RST:-}" >&2
                export "${key_var}=${new_key}"
                if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
                printf '  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_key_success)" "${C_RST:-}" >&2
                loop_active=0
              else
                printf '\n  %s%s%s\n' "${C_BRED:-}" "$(_msg config_key_invalid)" "${C_RST:-}" >&2
                printf '  %s' "$(_msg config_key_save_invalid_prompt)" >&2
                local confirm_save
                if IFS= read -r confirm_save; then
                  confirm_save="$(trim_space "${confirm_save,,}")"
                  if [[ "$confirm_save" =~ ^[yY](es)?$ ]]; then
                    export "${key_var}=${new_key}"
                    if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
                    printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_key_success)" "${C_RST:-}" >&2
                  fi
                fi
                loop_active=0
              fi
            done
          fi
        fi
        ;;
      4)
        prompt_lang_selection
        load_lang_secure "$BASH4LLM_LANG"
        save_all_configs_to_file
        printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_lang_success "$BASH4LLM_LANG")" "${C_RST:-}" >&2
        ;;
      5)
        printf '\n  %s ' "$(_msg config_temp_prompt)" >&2
        local new_temp
        if IFS= read -r new_temp; then
          new_temp="$(trim_space "$new_temp")"
          if [[ "$new_temp" =~ ^((0|1)(\.[0-9]+)?|2(\.0+)?)$ ]]; then
            TEMPERATURE="$new_temp"
            TURE="$new_temp"
            save_all_configs_to_file
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_temp_success)" "${C_RST:-}" >&2
          else
            printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_invalid_temp)" "${C_RST:-}" >&2
          fi
          sleep 1
        fi
        ;;
      6)
        printf '\n  %s ' "$(_msg config_tokens_prompt)" >&2
        local new_tokens
        if IFS= read -r new_tokens; then
          new_tokens="$(trim_space "$new_tokens")"
          if [[ "$new_tokens" =~ ^[0-9]+$ ]] && [ "$new_tokens" -ge 1 ] && [ "$new_tokens" -le 32768 ]; then
            MAX_TOKENS="$new_tokens"
            save_all_configs_to_file
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_tokens_success)" "${C_RST:-}" >&2
          else
            printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_invalid_tokens)" "${C_RST:-}" >&2
          fi
          sleep 1
        fi
        ;;
      7)
        printf '\n  %s ' "$(_msg config_threshold_prompt)" >&2
        local new_threshold
        if IFS= read -r new_threshold; then
          new_threshold="$(trim_space "$new_threshold")"
          if [[ "$new_threshold" =~ ^[0-9]+$ ]] && [ "$new_threshold" -ge 0 ] && [ "$new_threshold" -le 10485760 ]; then
            THRESHOLD="$new_threshold"
            save_all_configs_to_file
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_threshold_success)" "${C_RST:-}" >&2
          else
            printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_invalid_threshold)" "${C_RST:-}" >&2
          fi
          sleep 1
        fi
        ;;
      8)
        printf '\n  %s ' "$(_msg config_format_prompt)" >&2
        local new_format
        if IFS= read -r new_format; then
          new_format="$(trim_space "$new_format")"
          case "$new_format" in
            text|raw|json|pretty)
              OUTPUT_MODE="$new_format"
              save_all_configs_to_file
              printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_format_success)" "${C_RST:-}" >&2
              ;;
            *)
              printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_invalid_format)" "${C_RST:-}" >&2
              ;;
          esac
          sleep 1
        fi
        ;;
      9)
        printf '\n  %s\n' "$(_msg config_refresh_start)" >&2
        if ensure_api_key_for_provider "$PROVIDER"; then
          if refresh_models_dispatch; then
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg config_refresh_success)" "${C_RST:-}" >&2
          else
            printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg config_refresh_failed)" "${C_RST:-}" >&2
          fi
        fi
        ;;
      10)
        local cached_title=" $(_msg config_cached_title "$PROVIDER") "
        printf '\n%b%b%s%b\n\n' "${BG_WHITE:-}" "${C_BBLUE:-}" "$cached_title" "${C_RST:-}" >&2
        list_models_cli >&2 || true
        printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2
        ;;
      11 | q | Q | "")
        return 0
        ;;
      *)
        printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_invalid_option)" "${C_RST:-}" >&2
        ;;
    esac
  done
}
# --- PHASE 10: INTERACTIVE CONTEXTUAL TOOLS MENU ---

# Display and handle thread management utility outputs
show_thread_menu() {
  while true; do
    # Fetch the friendly title of the active thread from its metadata file
    local current_friendly_title=""
    local meta_file="${BASH4LLM_CONFIG_DIR:-}/ui_state/threads/${THREAD_ID}.json"
    if [ -f "$meta_file" ]; then
      current_friendly_title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
    fi
    # Fallback to THREAD_ID if no friendly title has been configured yet
    [ -n "$current_friendly_title" ] || current_friendly_title="$THREAD_ID"

    local thread_title=" $(_msg tools_title) "
    printf '\n%b%b%s%b\n' "${C_BANNER:-}" "$thread_title" "${C_RST:-}" >&2
    print_menu_item 1 "$(_msg tools_opt_rename)" "${current_friendly_title}"
    print_menu_item 2 "$(_msg tools_opt_delete)"
    print_menu_item 3 "$(_msg tools_opt_start)"
    print_menu_item 4 "$(_msg tools_opt_read_past)"
    print_menu_item 5 "$(_msg tools_opt_load_past)"
    print_menu_item 6 "$(_msg tools_opt_return)"
    
    printf '%b----------------------------------------%b\n' "${C_BBLUE:-}" "${C_RST:-}" >&2

    local m_sel
    printf '  %s ' "$(_msg tools_prompt)" >&2
    if ! IFS= read -r m_sel; then
      return 0
    fi
    m_sel="$(trim_space "$m_sel")"
    printf '\n' >&2

    case "$m_sel" in
      1)
        printf '\n  %s ' "$(_msg tools_rename_prompt)" >&2
        local new_title
        if IFS= read -r new_title; then
          new_title="$(trim_space "$new_title")"
          if [ -n "$new_title" ]; then
            thread_rename_core "$THREAD_ID" "$new_title"
            printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg tools_rename_success)" "${C_RST:-}" >&2
          fi
        fi
        ;;
      2)
        printf '\n  %s ' "$(_msg tools_delete_warn "$THREAD_ID")" >&2
        local confirm
        if IFS= read -r confirm; then
          confirm="$(trim_space "$confirm")"
          if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
            thread_delete_core "$THREAD_ID"
            printf '\n  %s%s%s\n' "${C_YELLOW:-}" "$(_msg tools_delete_success)" "${C_RST:-}" >&2
            sleep 1
            load_threads_wizard
            return 0
          else
            printf '\n  %s\n' "$(_msg tools_delete_cancel)" >&2
          fi
        fi
        ;;
      3)
        THREAD_ID="thread-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_thread_file="${BASH4LLM_HISTORY_DIR:-}/threads/${THREAD_ID}.ndjson"
        : > "$new_thread_file"
        chmod 600 "$new_thread_file"
        printf '\n  %s%s%s\n' "${C_GREEN:-}" "$(_msg tools_new_session "$THREAD_ID")" "${C_RST:-}" >&2
        return 0
        ;;
      4)
        # Scan and browse previous conversation files safely
        local hist_dir="${BASH4LLM_HISTORY_DIR:-}"
        local thread_dir="${hist_dir%/}/threads"
        local -a files=()
        local f mtime
        while IFS='|' read -r mtime f; do
          if [ -f "$f" ] && [ "${f##*.}" = "ndjson" ]; then
            files+=("$f")
          fi
        done < <(list_files_sorted_by_mtime "$thread_dir" | tac_fallback)

        if [ "${#files[@]}" -eq 0 ]; then
          printf '\n  %s%s%s\n' "${C_YELLOW:-}" "$(_msg tools_err_no_threads)" "${C_RST:-}" >&2
          sleep 1
          continue
        fi

        local tmp_preview
        tmp_preview="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" threads_view 2>/dev/null)"
        if [ -n "$tmp_preview" ]; then
          for f in "${files[@]}"; do
            local filename="${f##*/}"
            local tid="${filename%.ndjson}"
            local last_line last_ts last_date
            last_line="$(tail -n 1 "$f" 2>/dev/null || true)"
            last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
            last_date="$(_format_ts "$last_ts")"
            
            local cfg_dir="${BASH4LLM_CONFIG_DIR:-}"
            local meta_file="${cfg_dir%/}/ui_state/threads/${tid}.json"
            local title=""
            if [ -f "$meta_file" ]; then
              title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
            fi
            [ -n "$title" ] || title="$(_msg thread_default_title "${tid:0:8}")"
            
            printf "=== [%s] %s (ID: %s) ===\n" "$last_date" "$title" "$tid" >> "$tmp_preview"
            tail -n 20 "$f" | while IFS= read -r line || [ -n "$line" ]; do
              local role content
              role="$(printf '%s' "$line" | jq -r '.role // empty' 2>/dev/null)"
              content="$(printf '%s' "$line" | jq -r '.content // empty' 2>/dev/null)"
              if [ "$role" = "user" ]; then
                printf "  %s > %s\n" "$(_msg role_user_label)" "$content" >> "$tmp_preview"
              elif [ "$role" = "assistant" ]; then
                printf "  %s > %s\n\n" "$(_msg role_assistant_label)" "$content" >> "$tmp_preview"
              fi
            done
            printf "\n\n" >> "$tmp_preview"
          done

          if command -v less >/dev/null 2>&1; then
            less -R "$tmp_preview"
          else
            cat "$tmp_preview" | head -n 100
          fi
          rm -f "$tmp_preview" 2>/dev/null || true
        fi
        ;;
      5)
        # Load a past Thread and clear the memory cache window
        load_threads_wizard
        if type thread_cache_invalidate >/dev/null 2>&1; then
          thread_cache_invalidate "$THREAD_ID" >/dev/null 2>&1 || true
        fi
        return 0
        ;;
      6 | q | Q | "")
        return 0
        ;;
      *)
        printf '\n  %s%s%s\n' "${C_RED:-}" "$(_msg err_invalid_option)" "${C_RST:-}" >&2
        ;;
    esac
  done
}

# --- PHASE 11: INTERACTIVE REPL CHAT LOOP ---

# Handle graceful signal interruptions inside standard interactive prompt blocks
handle_sigint() {
  printf '\n' >&2
}

# Start the primary chat session loop
run_repl() {
  if [ -z "$THREAD_ID" ]; then
    load_threads_wizard
  fi

  print_banner

  # Bind standard signal handler to manage SIGINT during inactive input states
  trap handle_sigint INT

  # Clear current volatile in-memory shell history to purge script execution/parsing footprint
  history -c 2>/dev/null || true
  
  # Reload exclusively the clean historical prompt user records from disk
  history -r "$HISTFILE" 2>/dev/null || true

  # Ensure auto-history recording inside Readline remains permanently disabled
  set +o history 2>/dev/null || true

  # Allow loose variable execution safely inside the prompt cycle
  set +e 2>/dev/null || true
  set +u 2>/dev/null || true

  # Enable Bracketed Paste Mode on terminal to safeguard against bulk line paste execution
  printf '\e[?2004h' >&2

  while true; do
    local prompt_sym prompt_str
    prompt_sym="$(_msg prompt_tu)"
    
    # Render customized Incognito layout prompt if Private Mode is active
    if [ "$PRIVATE_MODE" -eq 1 ]; then
      prompt_str="${RL_START}${C_MAGENTA:-}${RL_END}$(_msg prompt_incognito) ${RL_START}${C_BRED:-}${RL_END}${prompt_sym} ${RL_START}${C_RST:-}${RL_END}"
    else
      prompt_str="${RL_START}${C_BCYAN:-}${RL_END}${prompt_sym} ${RL_START}${C_RST:-}${RL_END}"
    fi

    local userline=""
    IFS= read -r -e -p "$prompt_str" userline
    local read_rc=$?

    # Handle standard inputs or signals
    if [ "$read_rc" -ne 0 ]; then
      if [ "$read_rc" -eq 130 ]; then
        printf '\n' >&2
        continue
      fi
      printf '\n%s\n' "$(_msg exited)" >&2
      break
    fi

    # Clean bracketed paste marker sequences if they leak into the variable
    userline="${userline//$'\e'[200~/}"
    userline="${userline//$'\e'[201~/}"

    userline="$(trim_space "$userline")"
    [ -z "$userline" ] && continue

    # Prevent command entries from polluting history records if Incognito mode is enabled
    if [ "$PRIVATE_MODE" -ne 1 ]; then
      history -s "$userline" 2>/dev/null || true
      history -w "${HISTFILE:-}" 2>/dev/null || true
    fi

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
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/help, /?" "$( _msg help_desc_help )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/exit, /quit" "$( _msg help_desc_exit )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/clear" "$( _msg help_desc_clear )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/thread" "$(_msg help_desc_thread)" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/private" "$(_msg help_desc_private)" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/config" "$( _msg help_desc_config )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/undo" "$( _msg help_desc_undo )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/status" "$( _msg help_desc_status )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/system [prompt]" "$( _msg help_desc_system )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/model [name]" "$( _msg help_desc_model )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/temperature, /ture [v]" "$( _msg help_desc_temp )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/max [valore]" "$( _msg help_desc_max )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/threshold [val]" "$( _msg help_desc_threshold )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/format [format]" "$( _msg help_desc_format )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/file <path>" "$( _msg help_desc_file )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/block" "$( _msg help_desc_block )" >&2
        printf "  ${C_BGREEN:-}%-22s${C_RST:-} %s\n" "/edit" "$( _msg help_desc_edit )"
        
        printf "\n${C_LOGO:-} %s ${C_RST:-}\n" "$(_msg cmd_help_shortcuts_title)" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + D" "$( _msg help_sc_d_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + C" "$( _msg help_sc_c_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + L" "$( _msg help_sc_l_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + A / E" "$( _msg help_sc_ae_desc )" >&2
        printf "  ${C_BYELLOW:-}%-15s${C_RST:-} %s\n" "Ctrl + U / K" "$( _msg help_sc_uk_desc )"
        
        printf '%b----------------------------------------%b\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
        continue
        ;;
      /private)
          # Toggle private mode and modify environment variables dynamically
          if [ "$PRIVATE_MODE" -eq 0 ]; then
            PRIVATE_MODE=1
            ORIG_HISTFILE="${HISTFILE:-}"
            HISTFILE=""
            printf '\n%b########################################%b' "${C_MAGENTA:-}" "${C_RST:-}" >&2
            printf '\n%s%s%s\n\n' "${C_MAGENTA:-}" "$(_msg cmd_private_on)" "${C_RST:-}" >&2
          else
          PRIVATE_MODE=0
          HISTFILE="${ORIG_HISTFILE:-${BASH4LLM_HISTORY_DIR:-}/tui_history}"
          printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_private_off)" "${C_RST:-}" >&2
        fi
        continue
        ;;
      /thread | /threads)
        show_thread_menu
        continue
        ;;
      /config)
        show_config_menu
        continue
        ;;
      /undo)
        local hist_dir="${BASH4LLM_HISTORY_DIR:-}"
        local thread_file="${hist_dir%/}/threads/${THREAD_ID}.ndjson"
        if [ -f "$thread_file" ] && [ -s "$thread_file" ]; then
          local total_lines
          total_lines="$(wc -l < "$thread_file" 2>/dev/null | tr -d ' ' || echo 0)"
          if [ "$total_lines" -ge 2 ]; then
            local tmp_undo
            tmp_undo="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" undo 2>/dev/null)"
            if [ -n "$tmp_undo" ]; then
              head -n "$((total_lines - 2))" "$thread_file" > "$tmp_undo" 2>/dev/null \
                && mv -f "$tmp_undo" "$thread_file" 2>/dev/null || true
              rm -f "$tmp_undo" 2>/dev/null || true
              if type thread_cache_invalidate >/dev/null 2>&1; then
                thread_cache_invalidate "$THREAD_ID" >/dev/null 2>&1 || true
              fi
              printf '\n%s%s%s\n\n' "${C_YELLOW:-}" "$(_msg cmd_undo_success)" "${C_RST:-}" >&2
            else
              printf '%s\n' "$(_msg cmd_undo_error_tmp)" >&2
            fi
          elif [ "$total_lines" -eq 1 ]; then
            : > "$thread_file" 2>/dev/null || true
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
        local hist_dir="${BASH4LLM_HISTORY_DIR:-}"
        local thread_file="${hist_dir%/}/threads/${THREAD_ID}.ndjson"
        local msg_count=0 size_bytes=0
        if [ -f "$thread_file" ]; then
          msg_count="$(wc -l < "$thread_file" 2>/dev/null | tr -d ' ' || echo 0)"
          size_bytes="$(file_size "$thread_file" 2>/dev/null || echo 0)"
        fi
        local stat_title=" $(_msg cmd_status_title) "
        printf '\n%b%b%s%b\n\n' "${BG_WHITE:-}" "${C_BBLUE:-}" "$stat_title" "${C_RST:-}" >&2
        
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_provider)" "${C_RST:-}" "$(color_attributes "${PROVIDER:-}")" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_model)" "${C_RST:-}" "$(color_attributes "${MODEL:-}")" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_temp)" "${C_RST:-}" "${TEMPERATURE:-1.0}" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg label_tokens)" "${C_RST:-}" "${MAX_TOKENS:-4096}" >&2
        
        # Fetch the friendly title of the active thread for the status report
        local current_friendly_title=""
        local meta_file="${BASH4LLM_CONFIG_DIR:-}/ui_state/threads/${THREAD_ID}.json"
        if [ -f "$meta_file" ]; then
          current_friendly_title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
        fi
        [ -n "$current_friendly_title" ] || current_friendly_title="$(_msg attribute_not_configured)"

        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg label_threshold)" "${C_RST:-}" "${THRESHOLD:-1000}" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg label_format)" "${C_RST:-}" "${OUTPUT_MODE:-text}" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg label_thread_title)" "${C_RST:-}" "$(color_attributes "${current_friendly_title}")" >&2
        printf "  %b%s%b : %s\n" "${C_CYAN:-}" "$(_msg cmd_status_session)" "${C_RST:-}" "$(color_attributes "${THREAD_ID:-}")" >&2
        
        local bytes_msgs_fmt
        bytes_msgs_fmt="$(_msg cmd_status_bytes_msgs "$size_bytes" "$msg_count")"
        printf "  %b%s%b : %s (%s)\n" "${C_CYAN:-}" "$(_msg cmd_status_file)" "${C_RST:-}" "$(basename "$thread_file")" "$bytes_msgs_fmt" >&2
        
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
          SYSTEM_PROMPT="$(trim_space "$new_sys")"
          printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_system_updated)" "${C_RST:-}" >&2
        fi
        continue
        ;;
      /model | /model\ *)
        if [ "$userline" = "/model" ]; then
          printf '\n  %s: %s\n\n' "$(_msg cmd_status_model)" "${MODEL}" >&2
        else
          local new_model="${userline#/model }"
          new_model="${new_model//[!A-Za-z0-9._\/:-]/}"
          new_model="$(trim_space "$new_model")"
          if [ -z "$new_model" ]; then
            printf '%s\n' "$(_msg cmd_model_invalid)" >&2
          else
            if validate_model_dispatch "$new_model" >/dev/null 2>&1; then
              MODEL="$new_model"
              save_all_configs_to_file
              printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_model_success "$MODEL")" "${C_RST:-}" >&2
            else
              printf '%s\n' "$(_msg cmd_model_not_supported "$new_model")" >&2
            fi
          fi
        fi
        continue
        ;;
      /temperature | /ture | /temperature\ * | /ture\ *)
        if [ "$userline" = "/temperature" ] || [ "$userline" = "/ture" ]; then
          printf '\n  %s: %s\n\n' "$(_msg cmd_status_temp)" "${TEMPERATURE}" >&2
        else
          local val=""
          if [[ "$userline" == /temperature\ * ]]; then
            val="${userline#/temperature }"
          else
            val="${userline#/ture }"
          fi
          val="$(trim_space "$val")"
          if [[ "$val" =~ ^((0|1)(\.[0-9]+)?|2(\.0+)?)$ ]]; then
            TEMPERATURE="$val"
            TURE="$val"
            save_all_configs_to_file
            printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_temp_success "${TEMPERATURE}")" "${C_RST:-}" >&2
          else
            printf '\n%s%s%s\n\n' "${C_RED:-}" "$(_msg err_invalid_temp)" "${C_RST:-}" >&2
          fi
        fi
        continue
        ;;
      /max | /max\ *)
        if [ "$userline" = "/max" ]; then
          printf '\n  %s: %s\n\n' "$(_msg label_tokens)" "${MAX_TOKENS}" >&2
        else
          local val="${userline#/max }"
          val="$(trim_space "$val")"
          if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 1 ] && [ "$val" -le 32768 ]; then
            MAX_TOKENS="$val"
            save_all_configs_to_file
            printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_tokens_success "${MAX_TOKENS}")" "${C_RST:-}" >&2
          else
            printf '\n%s%s%s\n\n' "${C_RED:-}" "$(_msg err_invalid_tokens)" "${C_RST:-}" >&2
          fi
        fi
        continue
        ;;
      /threshold | /threshold\ *)
        if [ "$userline" = "/threshold" ]; then
          printf '\n  %s: %s\n\n' "$(_msg label_threshold)" "${THRESHOLD}" >&2
        else
          local val="${userline#/threshold }"
          val="$(trim_space "$val")"
          if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 0 ] && [ "$val" -le 10485760 ]; then
            THRESHOLD="$val"
            save_all_configs_to_file
            printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_threshold_success "${THRESHOLD}")" "${C_RST:-}" >&2
          else
            printf '\n%s%s%s\n\n' "${C_RED:-}" "$(_msg err_invalid_threshold)" "${C_RST:-}" >&2
          fi
        fi
        continue
        ;;
      /format | /format\ *)
        if [ "$userline" = "/format" ]; then
          printf '\n  %s: %s\n\n' "$(_msg label_format)" "${OUTPUT_MODE}" >&2
        else
          local val="${userline#/format }"
          val="$(trim_space "$val")"
          case "$val" in
            text|raw|json|pretty)
              OUTPUT_MODE="$val"
              save_all_configs_to_file
              printf '\n%s%s%s\n\n' "${C_GREEN:-}" "$(_msg cmd_format_success "${OUTPUT_MODE}")" "${C_RST:-}" >&2
              ;;
            *)
              printf '\n%s%s%s\n\n' "${C_RED:-}" "$(_msg err_invalid_format)" "${C_RST:-}" >&2
              ;;
          esac
        fi
        continue
        ;;
      /file\ *)
        local file_cmd_args="${userline#/file }"
        file_cmd_args="$(trim_space "$file_cmd_args")"
        if [ -z "$file_cmd_args" ]; then
          printf '%s\n' "$(_msg cmd_file_syntax)" >&2
          continue
        fi

        local file_path file_prompt file_content combined_prompt
        file_path="${file_cmd_args%% *}"
        file_prompt="${file_cmd_args#* }"
        if [ "$file_path" = "$file_cmd_args" ]; then
          file_prompt=""
        else
          file_prompt="$(trim_space "$file_prompt")"
        fi

        validate_file_input "$file_path"
        local check_rc=$?
        case "$check_rc" in
          1) printf '%s\n' "$(_msg cmd_file_syntax)" >&2; continue ;;
          2) printf '%s\n' "$(_msg cmd_file_not_found "$file_path")" >&2; continue ;;
          3) printf '%s\n' "$(_msg cmd_file_err_empty "$file_path")" >&2; continue ;;
          4) printf '%s\n' "$(_msg cmd_file_err_binary "$file_path")" >&2; continue ;;
        esac

        local file_size_val
        file_size_val="$(file_size "$file_path" 2>/dev/null || echo 0)"
        if [ "$file_size_val" -gt 102400 ]; then
          printf '%s\n' "$(_msg cmd_file_limit "$file_path" "$((file_size_val / 1024))")" >&2
          continue
        fi

        file_content="$(cat "$file_path" 2>/dev/null || true)"
        if [ -n "$file_prompt" ]; then
          combined_prompt="$(printf 'Prompt: %s\n\n[File Attached: %s]\n---\n%s\n---\n' \
            "$file_prompt" "${file_path##*/}" "$file_content")"
        else
          combined_prompt="$(printf '[File Attached: %s]\n---\n%s\n---\n' \
            "${file_path##*/}" "$file_content")"
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
        local editor_cmd
        editor_cmd="${EDITOR:-nano}"
        editor_cmd="${editor_cmd%% *}"
        
        if ! command -v "$editor_cmd" >/dev/null 2>&1; then
          if command -v nano >/dev/null 2>&1; then
            editor_cmd="nano"
          elif command -v vi >/dev/null 2>&1; then
            editor_cmd="vi"
          else
            printf '%s\n' "$(_msg cmd_edit_no_editor)" >&2
            continue
          fi
        fi

        local tmp_edit_file
        tmp_edit_file="$(_tmpf file "${RUN_TMPDIR:-$BASH4LLM_TMPDIR}" edit 2>/dev/null)"
        if [ -z "$tmp_edit_file" ] || [ ! -f "$tmp_edit_file" ]; then
          printf '%s\n' "$(_msg cmd_edit_error_tmp)" >&2
          continue
        fi

        # Invoke the parsed editor safely
        "$editor_cmd" "$tmp_edit_file"

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

    local run_tmp="${RUN_TMPDIR:-}"
    BUILD_MESSAGES_FILE="${run_tmp%/}/thread-${THREAD_ID}-messages.json"
    export BUILD_MESSAGES_FILE

    _engine_available=0
    _engine_path="${BASH4LLM_EXTRAS_DIR:-}/session/session-engine.sh"
    if [ -f "$_engine_path" ] && type session_engine_build_window >/dev/null 2>&1; then
      _engine_available=1
    fi

    # Read historical chat context
    if [ "${_engine_available:-0}" -eq 1 ]; then
      session_engine_build_window "$THREAD_ID" "${SESSION_WINDOW:-10}" "${BASH4LLM_SESSION_TARGET_BYTES:-}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 \
        || thread_read_window "$THREAD_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    else
      thread_read_window "$THREAD_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    fi

    if ! build_payload_from_vars >/dev/null 2>&1; then
      log_error "TUI" "$(_msg cmd_err_payload)"
      continue
    fi

    if ! ensure_api_key_for_provider "$PROVIDER"; then
      log_error "APIKEY" "$(_msg cmd_err_key "$PROVIDER")"
      continue
    fi

    # Determine header color based on private mode status
    local model_header_color="${C_BGREEN:-}"
    if [ "$PRIVATE_MODE" -eq 1 ]; then
      model_header_color="${C_BMAGENTA:-}"
    fi

    printf '\n%s%s - %s:%s\n' "$model_header_color" "$PROVIDER" "$MODEL" "${C_RST:-}" >&2

    IS_STREAMING=1
    local call_rc=0
    
    # Establish local signal trap handler around generation cycles safely
    trap 'printf "\n%s\n" "$(_msg err_interrupted_user)" >&2; call_rc=130' INT
    if [ "${STREAM_MODE:-0}" -eq 1 ]; then
      call_api_streaming
      call_rc=$?
    else
      perform_request_once
      call_rc=$?
    fi
    trap handle_sigint INT
    IS_STREAMING=0

    # Persist turns on disk unless Incognito/Private mode is active
    if [ "$call_rc" -eq 0 ] && [ "${DRY_RUN:-0}" -ne 1 ] && [ "$PRIVATE_MODE" -ne 1 ]; then
      local meta_source="cli"
      local meta_cmd="$(thread_sanitize_cmd "$0")"
      local meta_json
      meta_json="$(jq -c -n --arg source "$meta_source" --arg cmd "$meta_cmd" --arg id "" '{source:$source, cmd:$cmd, id:$id}')"

      if [ "${_engine_available:-0}" -eq 1 ]; then
        session_engine_append "$THREAD_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 \
          || thread_append "$THREAD_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      else
        thread_append "$THREAD_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      fi

      if [ -s "${RESP:-}" ]; then
        local assistant_text
        assistant_text="$(extract_text_from_resp 2>/dev/null || true)"
        assistant_text="$(printf '%s' "$assistant_text" | sed -e 's/\r$//' -e '/^[[:space:]]*$/d' || true)"
        if [ -n "$assistant_text" ]; then
          meta_source="provider"
          meta_json="$(jq -c -n --arg source "$meta_source" --arg model "$MODEL" --arg id "" '{source:$source, model:$model, id:$id}')"

          if [ "${_engine_available:-0}" -eq 1 ]; then
            session_engine_append "$THREAD_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 \
              || thread_append "$THREAD_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          else
            thread_append "$THREAD_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          fi
        fi
      fi
    fi

    unset CONTENT
    printf '\n' >&2
  done

  # Restore standard Bracketed Paste state and return TTY parameters safely
  printf '\e[?2004l' >&2
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
