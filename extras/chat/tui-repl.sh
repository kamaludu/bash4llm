#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: tui-repl.sh
# Component: TUI REPL Interactive Module (External Extra)
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
  # Dynamic fallback if invoked directly outside the core (3-level search)
  _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  _repo_root="$(cd "$_self_dir/../../.." >/dev/null 2>&1 && pwd)"
  if [ -f "$_repo_root/bash4llm" ]; then
    CORE_SCRIPT="$_repo_root/bash4llm"
  elif [ -f "$_repo_root/bash4llm.sh" ]; then
    CORE_SCRIPT="$_repo_root/bash4llm.sh"
  fi
fi

if [ -n "$CORE_SCRIPT" ] && [ -f "$CORE_SCRIPT" ]; then
  # Sourcing the core under the BASH4LLM_SOURCE_ONLY=1 guard
  export BASH4LLM_SOURCE_ONLY=1
  # shellcheck source=/dev/null
  . "$CORE_SCRIPT"
else
  printf 'tui-repl.sh: %sERROR%s: Cannot locate core bash4llm script.\n' "${C_RED:-}" "${C_RST:-}" >&2
  printf 'Please run directly using: bash4llm --chat\n' >&2
  exit 15
fi

# Validation of interactive TTY environment
if [ ! -t 0 ] || [ ! -t 1 ]; then
  log_error "TUI" "TUI REPL requires a valid and active interactive TTY."
  exit 15
fi

# --- PHASE 2: REPL STATE DICTIONARY AND VARIABLE INITIALIZATION ---
# Map inherited operational state or initialize defaults
SESSION_ID="${BASH4LLM_ACTIVE_SESSION:-}"
MODEL="${BASH4LLM_ACTIVE_MODEL:-}"
TEMPERATURE="${BASH4LLM_ACTIVE_TEMPERATURE:-1.0}"
TURE="$TEMPERATURE"

# Fallback safety configuration if inherited state is empty
[ -n "$MODEL" ] || {
  # Resolve default model by reusing the core function
  if resolve_model >/dev/null 2>&1 && [ -n "${FINAL_MODEL:-}" ]; then
    MODEL="$FINAL_MODEL"
  else
    MODEL="default"
  fi
}

# Ensure required directories for run-specific temporary state
ensure_run_tmpdir >/dev/null 2>&1 || {
  log_error "TUI" "Unable to initialize secure run-specific temporary directory."
  exit "$BASH4LLM_ERR_TMP"
}

# --- PHASE 3: INPUT HISTORY CONFIGURATION (ISOLATED READLINE) ---
# Manually enable history mechanisms in current REPL process
set -o history 2>/dev/null || true
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTFILE="${BASH4LLM_HISTORY_DIR}/tui_history"

# Secure initialization of internal history file
if [ ! -f "$HISTFILE" ]; then
  : > "$HISTFILE" 2>/dev/null
  chmod 600 "$HISTFILE" 2>/dev/null || true
fi
history -r "$HISTFILE" 2>/dev/null || true

# Escape sequences wrapping for Readline prompt length calculations
RL_START=$'\001'
RL_END=$'\002'

# --- PHASE 4: SIGNAL MANAGEMENT ARCHITECTURE (SIGINT / Ctrl+C) ---
# Dynamic flag to distinguish network streaming from passive prompt state
IS_STREAMING=0

handle_sigint() {
  if [ "$IS_STREAMING" -eq 1 ]; then
    # If receiving streaming API data, let the core pipeline handle curl interruption
    :
  else
    # If in passive input prompt, clear the line and display a fresh prompt
    printf '\n' >&2
  fi
}
trap handle_sigint INT

# --- PHASE 5: SEQUENTIAL RENDERING UTILITIES AND GRAPHICAL HELPERS ---
print_banner() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  printf '%b' "
${C_LOGO}  Bash4LLM⁺  ${C_RST} — ${C_BCYAN}Interactive TUI Shell (v${SCRIPT_VERSION:-2.3.0})${C_RST}
  Active Session: ${C_YELLOW}${SESSION_ID:-<None>}${C_RST} | Model: ${C_BGREEN}${MODEL:-<Default>}${C_RST}
  Type ${C_BYELLOW}/?${C_RST} or ${C_BYELLOW}/help${C_RST} to list available commands and keyboard shortcuts.
----------------------------------------
" >&2
}

print_status_bar() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  local stream_status="Disabled"
  if [ "${STREAM_MODE:-0}" -eq 1 ]; then stream_status="Enabled"; fi
  
  printf '%b' "
  ${C_BCYAN}[REPL STATUS]${C_RST} Session: ${C_BOLD}${SESSION_ID:-none}${C_RST} | LLM: ${C_GREEN}${MODEL:-default}${C_RST} | Temp: ${C_YELLOW}${TEMPERATURE:-1.0}${C_RST} | Stream: ${C_BOLD}${stream_status}${C_RST}
" >&2
}

# --- PHASE 6: PAGINATED SESSION SELECTION WIZARD ---
_format_ts() {
  local ts="${1:-}"
  if [ -n "$ts" ]; then
    # Convert ISO8601 format (YYYY-MM-DDTHH:MM:SSZ) to YYYY-MM-DD HH:MM
    printf '%s %s' "${ts:0:10}" "${ts:11:5}"
  else
    printf 'N/A'
  fi
}

load_sessions_wizard() {
  local session_dir="${BASH4LLM_HISTORY_DIR}/sessions"
  safe_mkdir "$session_dir" 700

  # Fetch existing .ndjson session files sorted by mtime descending (newest first)
  local -a files=()
  local mtime f
  while IFS='|' read -r mtime f; do
    if [ -f "$f" ] && [ "${f##*.}" = "ndjson" ]; then
      files+=("$f")
    fi
  done < <(list_files_sorted_by_mtime "$session_dir" | tac_fallback)

  local total_sessions="${#files[@]}"

  # If no sessions found on disk, skip wizard and initialize a new one
  if [ "$total_sessions" -eq 0 ]; then
    SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
    local new_sess_file="${session_dir}/${SESSION_ID}.ndjson"
    : > "$new_sess_file"
    chmod 600 "$new_sess_file"
    log_info_user "TUI" "No sessions found on disk. Initialized new session: ${SESSION_ID}"
    return 0
  fi

  # Pagination parameters
  local page_size=10
  local current_page=0
  local total_pages=$(( (total_sessions + page_size - 1) / page_size ))

  while true; do
    if [ -t 1 ]; then
      clear 2>/dev/null || printf '\033[H\033[2J' >&2
    fi

    printf '%b' "
${C_LOGO}  EXISTING SESSION SELECTION WIZARD  ${C_RST}
  Page: ${C_BOLD}$((current_page + 1)) of ${total_pages}${C_RST} (Total sessions: ${total_sessions})
----------------------------------------
" >&2

    local start_idx=$((current_page * page_size))
    local end_idx=$((start_idx + page_size))
    [ "$end_idx" -gt "$total_sessions" ] && end_idx="$total_sessions"

    # Sequential rendering of each session row
    local i
    for ((i = start_idx; i < end_idx; i++)); do
      local s_file="${files[i]}"
      local s_id
      s_id="$(basename "$s_file" .ndjson)"

      # Extract creation timestamp (first line)
      local first_line creation_ts creation_date
      first_line="$(head -n 1 "$s_file" 2>/dev/null || true)"
      creation_ts="$(printf '%s' "$first_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      creation_date="$(_format_ts "$creation_ts")"

      # Extract title from UI metadata JSON or fall back to the first user message
      local meta_file title
      meta_file="${BASH4LLM_CONFIG_DIR}/ui_state/sessions/${s_id}.json"
      title=""
      if [ -f "$meta_file" ]; then
        title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
      fi
      if [ -z "$title" ] && [ -f "$s_file" ]; then
        title="$(jq -r 'select(.role=="user") | .content' "$s_file" 2>/dev/null | head -n 1 | tr -d '\n\r' | cut -c 1-35 || true)"
      fi
      [ -n "$title" ] || title="Session ${s_id:0:8}"

      # Extract last message timestamp (last line)
      local last_line last_ts last_date
      last_line="$(tail -n 1 "$s_file" 2>/dev/null || true)"
      last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      last_date="$(_format_ts "$last_ts")"

      # Print formatted row in a compatible sequential manner with variable expansion
      printf "  ${C_BCYAN}[%2d]${C_RST} %s ${C_CYAN}>${C_RST} %-35s ${C_CYAN}>${C_RST} %s\n" \
        "$((i + 1))" "$creation_date" "$title" "$last_date" >&2
    done

    printf '%b' "
  ----------------------------------------
  Navigation Options:
  ${C_BGREEN} [ + / n ] ${C_RST} Next Page         | ${C_BGREEN} [ - / p ] ${C_RST} Previous Page
  ${C_BGREEN} [   c   ] ${C_RST} New Blank Session | ${C_BGREEN} [   q   ] ${C_RST} Exit REPL
  ----------------------------------------
" >&2

    # Read user control input
    local choice
    printf '  Enter index number or option command: ' >&2
    IFS= read -r choice || { printf '\n' >&2; exit 0; }
    choice="$(printf '%s' "$choice" | awk '{$1=$1;print}')"

    case "$choice" in
      + | n | N)
        current_page=$(( (current_page + 1) % total_pages ))
        ;;
      - | p | P)
        current_page=$(( (current_page - 1 + total_pages) % total_pages ))
        ;;
      c | C | new | NEW)
        SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_sess_file="${session_dir}/${SESSION_ID}.ndjson"
        : > "$new_sess_file"
        chmod 600 "$new_sess_file"
        break
        ;;
      q | Q | exit | EXIT)
        printf '\nExited.\n' >&2
        exit 0
        ;;
      *)
        if printf '%s\n' "$choice" | grep -qE '^[0-9]+$'; then
          local target_idx=$((choice - 1))
          if [ "$target_idx" -ge 0 ] && [ "$target_idx" -lt "$total_sessions" ]; then
            local selected_file="${files[target_idx]}"
            SESSION_ID="$(basename "$selected_file" .ndjson)"
            break
          else
            printf '\n  %sIndex out of range!%s Please try again.\n' "${C_RED:-}" "${C_RST:-}" >&2
            sleep 1
          fi
        else
          printf '\n  %sInvalid choice!%s Please enter a valid index number or option.\n' "${C_RED:-}" "${C_RST:-}" >&2
          sleep 1
        fi
        ;;
    esac
  done

  # Final visual screen cleanup before starting the chat
  if [ -t 1 ]; then
    clear 2>/dev/null || printf '\033[H\033[2J' >&2
  fi
  return 0
}

# --- PHASE 7: INTERACTIVE CONFIGURATION INTERFACE (/config AND /menu) ---
show_config_menu() {
  while true; do
    printf '%b' "
  ${C_LOGO}  CONFIGURATION MENU  ${C_RST}
  1) Change Active Provider (Current: ${C_YELLOW}${PROVIDER:-groq}${C_RST})
  2) Change LLM Model       (Current: ${C_YELLOW}${MODEL:-default}${C_RST})
  3) Manage API Key         (env: ${C_YELLOW}$(provider_api_env_var_name "${PROVIDER:-groq}")${C_RST})
  4) Refresh Model List     (API network call)
  5) List Locally Cached Models
  6) Return to Chat
" >&2
    local m_sel
    printf '  Choose an option (1-6): ' >&2
    IFS= read -r m_sel || return 0
    m_sel="$(trim "$m_sel")"

    case "$m_sel" in
      1)
        printf '\n  Installed providers: %s\n' "$SUPPORTED_PROVIDERS" >&2
        printf '  Enter provider name: ' >&2
        local new_prov
        IFS= read -r new_prov || continue
        new_prov="$(trim "$new_prov")"
        if [ -n "$new_prov" ]; then
          case " $SUPPORTED_PROVIDERS " in
            *" $new_prov "*)
              PROVIDER="$new_prov"
              load_provider_module "$PROVIDER" >/dev/null 2>&1 || true
              resolve_provider_url "$PROVIDER" >/dev/null 2>&1 || true
              # Reset model to default to prevent conflicts between different providers
              resolve_model >/dev/null 2>&1 && MODEL="${FINAL_MODEL:-default}"
              printf '\n  %sProvider successfully set to %s.%s\n' "${C_GREEN:-}" "$PROVIDER" "${C_RST:-}" >&2
              ;;
            *) printf '\n  %sUnknown provider!%s\n' "${C_RED:-}" "${C_RST:-}" >&2 ;;
          esac
        fi
        ;;
      2)
        printf '\n  Enter the name of the new model: ' >&2
        local new_model
        IFS= read -r new_model || continue
        new_model="$(trim "$new_model")"
        if [ -n "$new_model" ]; then
          if validate_model_dispatch "$new_model" >/dev/null 2>&1; then
            MODEL="$new_model"
            printf '\n  %sModel successfully set to: %s%s\n' "${C_GREEN:-}" "$MODEL" "${C_RST:-}" >&2
          else
            printf '\n  %sInvalid or unregistered model name.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
          fi
        fi
        ;;
      3)
        local key_var
        key_var="$(provider_api_env_var_name "${PROVIDER:-groq}")"
        printf '\n  Configure key for: %s (Current: %s)\n' "$key_var" "${!key_var:-<not set>}" >&2
        printf '  Enter the new API key: ' >&2
        local new_key
        IFS= read -r new_key || continue
        new_key="$(trim "$new_key")"
        if [ -n "$new_key" ]; then
          export "${key_var}=${new_key}"
          if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
          printf '\n  %sAPI key updated successfully.%s\n' "${C_GREEN:-}" "${C_RST:-}" >&2
        fi
        ;;
      4)
        printf '\n  Starting model list download...\n' >&2
        if ensure_api_key_for_provider "$PROVIDER"; then
          if refresh_models_dispatch; then
            printf '\n  %sModel list refreshed successfully.%s\n' "${C_GREEN:-}" "${C_RST:-}" >&2
          else
            printf '\n  %sFailed to refresh model list from provider API.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
          fi
        fi
        ;;
      5)
        printf '\n  --- Locally Cached Models (%s) ---\n' "$PROVIDER" >&2
        list_models_cli || true
        printf '  ----------------------------------------\n' >&2
        ;;
      6 | q | Q | "")
        return 0
        ;;
      *)
        printf '\n  %sInvalid option!%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

show_tools_menu() {
  while true; do
    printf '%b' "
  ${C_LOGO}  CONTEXT MENU (TOOLS)  ${C_RST}
  1) Rename Active Session  (Current: ${C_YELLOW}${SESSION_ID:-none}${C_RST})
  2) Delete Active Session  (Removes raw files from disk)
  3) Start New Session      (Generates a new empty session ID)
  4) Toggle Stream Mode     (Current state: ${C_YELLOW}${STREAM_MODE:-0}${C_RST})
  5) View Status and Full Diagnostics Information
  6) Return to Chat
" >&2
    local m_sel
    printf '  Choose an option (1-6): ' >&2
    IFS= read -r m_sel || return 0
    m_sel="$(trim "$m_sel")"

    case "$m_sel" in
      1)
        printf '\n  Enter new title for active session: ' >&2
        local new_title
        IFS= read -r new_title || continue
        new_title="$(trim "$new_title")"
        if [ -n "$new_title" ]; then
          session_rename_core "$SESSION_ID" "$new_title"
          printf '\n  %sSession successfully renamed.%s\n' "${C_GREEN:-}" "${C_RST:-}" >&2
        fi
        ;;
      2)
        printf '\n  %sWARNING:%s Are you sure you want to delete session %s? [y/N]: ' "${C_RED:-}" "${C_RST:-}" "$SESSION_ID" >&2
        local confirm
        IFS= read -r confirm || continue
        confirm="$(trim "$confirm")"
        if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
          session_delete_core "$SESSION_ID"
          printf '\n  %sSession deleted.%s Restarting wizard...\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
          sleep 1
          load_sessions_wizard
          return 0
        else
          printf '\n  Deletion canceled.\n' >&2
        fi
        ;;
      3)
        SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_sess_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
        : > "$new_sess_file"
        chmod 600 "$new_sess_file"
        printf '\n  %sNew blank session created: %s%s\n' "${C_GREEN:-}" "$SESSION_ID" "${C_RST:-}" >&2
        return 0
        ;;
      4)
        if [ "${STREAM_MODE:-0}" -eq 1 ]; then
          STREAM_MODE=0
          printf '\n  %sStreaming disabled.%s Non-stream responses are now active.\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
        else
          STREAM_MODE=1
          printf '\n  %sStreaming enabled.%s Real-time generation is now active.\n' "${C_GREEN:-}" "${C_RST:-}" >&2
        fi
        ;;
      5)
        printf '\n  --- COMPLETE DIAGNOSTICS ---' >&2
        print_status_bar
        printf '  NDJSON Session File:  %s/sessions/%s.ndjson\n' "$BASH4LLM_HISTORY_DIR" "$SESSION_ID" >&2
        printf '  Configuration File:   %s/config\n' "$BASH4LLM_CONFIG_DIR" >&2
        printf '  TUI Historical Log:   %s\n' "$HISTFILE" >&2
        printf '  ----------------------------------------\n' >&2
        ;;
      6 | q | Q | "")
        return 0
        ;;
      *)
        printf '\n  %sInvalid option!%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

# --- PHASE 8: INTERACTIVE REPL CHAT LOOP ---
run_repl() {
  # If no active session is inherited, load the wizard
  if [ -z "$SESSION_ID" ]; then
    load_sessions_wizard
  fi

  print_banner
  print_status_bar

  # ANSI color codes wrapped in Readline non-printable wrappers for cursor safety
  local prompt_str="${RL_START}${C_BCYAN}${RL_END}Tu > ${RL_START}${C_RST}${RL_END}"

  # Disable strict modes specifically for user interaction to prevent abrupt crashes
  set +e 2>/dev/null || true
  set +u 2>/dev/null || true

  while true; do
    # Wait for user input via standard Readline interface
    local userline=""
    IFS= read -r -e -p "$prompt_str" userline
    local read_rc=$?

    # Intercept Ctrl+D (EOF), Ctrl+C, or read failures
    if [ "$read_rc" -ne 0 ]; then
      if [ "$read_rc" -eq 130 ]; then
        # Ctrl+C pressed during prompt: output newline and restart loop
        printf '\n' >&2
        continue
      fi
      printf '\nExited.\n' >&2
      break
    fi

    userline="$(trim "$userline")"
    [ -z "$userline" ] && continue

    # Write the command line to the isolated history file
    history -s "$userline" 2>/dev/null || true
    history -w "$HISTFILE" 2>/dev/null || true

    # Slash Commands Parser
    case "$userline" in
      /exit | /quit)
        break
        ;;
      /clear)
        if [ -t 1 ]; then
          clear 2>/dev/null || printf '\033[H\033[2J' >&2
        fi
        print_banner
        print_status_bar
        continue
        ;;
      /help | /\?)
        printf '%b' "
${C_BCYAN}---- Available TUI Commands: ----${C_RST}
  ${C_BGREEN}/help${C_RST}, ${C_BGREEN}/?${C_RST}             - Display this help guide and shortcuts
  ${C_BGREEN}/exit${C_RST}, ${C_BGREEN}/quit${C_RST}          - Save state and exit the interactive TUI
  ${C_BGREEN}/clear${C_RST}                - Clear screen visually (non-destructive)
  ${C_BGREEN}/reset-session${C_RST}        - Wipe history of the current active session
  ${C_BGREEN}/history [N]${C_RST}          - Browse last N messages (default 20, or -all) in pager
  ${C_BGREEN}/config${C_RST}               - Configuration menu (Provider, Model, API keys)
  ${C_BGREEN}/menu${C_RST}                 - Context tools menu (Rename, Delete session, Stream toggles)

${C_BCYAN}---- Keyboard Shortcuts (Readline): ----${C_RST}
  ${C_BGREEN}Ctrl + D${C_RST}                - Exit the REPL safely (signals EOF)
  ${C_BGREEN}Ctrl + C${C_RST}                - Interrupt current API generation OR clear current prompt
  ${C_BGREEN}Ctrl + L${C_RST}                - Clear the screen visual buffer (native terminal shortcut)
  ${C_BGREEN}Ctrl + A${C_RST} / ${C_BGREEN}Ctrl + E${C_RST}        - Move cursor to beginning / end of line
  ${C_BGREEN}Ctrl + U${C_RST} / ${C_BGREEN}Ctrl + K${C_RST}        - Cut text before / after cursor
${C_CYAN}----------------------------------------${C_RST}
" >&2
        continue
        ;;
      /reset-session)
        printf '\n  %sSECURITY:%s Are you sure you want to clear the active session? [y/N]: ' "${C_RED:-}" "${C_RST:-}" >&2
        local confirm
        IFS= read -r confirm
        confirm="$(trim "$confirm")"
        if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
          local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
          : > "$session_file" 2>/dev/null
          session_cache_invalidate "$SESSION_ID" >/dev/null 2>/dev/null || true
          printf '\n  %sSession successfully cleared (history emptied).%s\n\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
        else
          printf '\n  Action canceled.\n\n' >&2
        fi
        continue
        ;;
      /history | /history\ *)
        local opt="${userline#/history}"
        opt="$(trim "$opt")"
        local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"

        if [ ! -f "$session_file" ] || [ ! -s "$session_file" ]; then
          printf '\n  %sThe history for this session is currently empty.%s\n\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
          continue
        fi

        local lines_to_read=40
        local print_alert=0
        if [ -z "$opt" ]; then
          lines_to_read=40 # 20 message turns default (10 user - 10 assistant)
          print_alert=1
        elif [ "$opt" = "-all" ]; then
          lines_to_read=999999
        elif printf '%s\n' "$opt" | grep -qE '^[0-9]+$'; then
          lines_to_read=$(( opt * 2 ))
        else
          printf '  Invalid command syntax. Use: /history [N] or /history -all\n' >&2
          continue
        fi

        local tmp_hist
        tmp_hist="$(_tmpf file "$RUN_TMPDIR" hist_preview 2>/dev/null)"
        if [ -n "$tmp_hist" ]; then
          if [ "$print_alert" -eq 1 ]; then
            printf '[Displaying the last 20 messages. Type "/history -all" to read everything]\n\n' > "$tmp_hist"
          fi

          tail -n "$lines_to_read" "$session_file" | while IFS= read -r line || [ -n "$line" ]; do
            local role content
            role="$(printf '%s' "$line" | jq -r '.role // empty' 2>/dev/null)"
            content="$(printf '%s' "$line" | jq -r '.content // empty' 2>/dev/null)"
            if [ "$role" = "user" ]; then
              printf '%sTu >%s\n%s\n\n' "${C_BCYAN:-}" "${C_RST:-}" "$content" >> "$tmp_hist"
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
      /*)
        printf '  %sUnknown slash command!%s Type /help for help.\n' "${C_RED:-}" "${C_RST:-}" >&2
        continue
        ;;
    esac

    # Process standard user query to be forwarded to the API
    CONTENT="$userline"

    # 1. Configure session context and compile history file
    BUILD_MESSAGES_FILE="$RUN_TMPDIR/session-${SESSION_ID}-messages.json"
    export BUILD_MESSAGES_FILE

    if [ "${SE_AVAILABLE:-0}" -eq 1 ]; then
      session_engine_build_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "${BASH4LLM_SESSION_TARGET_BYTES:-}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 \
        || session_read_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    else
      session_read_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    fi

    # 2. Generate structured payload JSON file
    if ! build_payload_from_vars >/dev/null 2>&1; then
      log_error "TUI" "Failed to correctly assemble the API payload JSON."
      continue
    fi

    # 3. Validate API credentials before proceeding
    if ! ensure_api_key_for_provider "$PROVIDER"; then
      log_error "APIKEY" "API access key is missing for provider $PROVIDER."
      continue
    fi

    # 4. Output visual response header
    printf '\n%s%s - %s:%s\n' "${C_BGREEN:-}" "$PROVIDER" "$MODEL" "${C_RST:-}" >&2

    # 5. Synchronous invocation (stream or non-stream) with signal protection
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

    # 6. Save discussion to active history NDJSON on disk
    if [ "$call_rc" -eq 0 ] && [ "${DRY_RUN:-0}" -ne 1 ]; then
      local meta_source="cli"
      local meta_cmd="$(session_sanitize_cmd "$0")"
      local meta_json
      meta_json="$(jq -c -n --arg source "$meta_source" --arg cmd "$meta_cmd" --arg id "" '{source:$source, cmd:$cmd, id:$id}')"

      # Append User message
      if [ "${SE_AVAILABLE:-0}" -eq 1 ]; then
        session_engine_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 \
          || session_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      else
        session_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      fi

      # Read, extract, and append Assistant response
      if [ -s "${RESP:-}" ]; then
        local assistant_text
        assistant_text="$(extract_text_from_resp 2>/dev/null || true)"
        assistant_text="$(printf '%s' "$assistant_text" | sed -e 's/\r$//' -e '/^[[:space:]]*$/d' || true)"
        if [ -n "$assistant_text" ]; then
          meta_source="provider"
          meta_json="$(jq -c -n --arg source "$meta_source" --arg model "$MODEL" --arg id "" '{source:$source, model:$model, id:$id}')"

          if [ "${SE_AVAILABLE:-0}" -eq 1 ]; then
            session_engine_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 \
              || session_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          else
            session_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          fi
        fi
      fi
    fi

    # Reset variables for the next turn
    unset CONTENT
    printf '\n' >&2
  done

  # Restore standard terminal echo on exit
  stty echo 2>/dev/null || true
  return 0
}

# --- OPERATIONAL ENTRY POINT ---
run_repl

# Clean up temporary state safely on exit
if ! type cleanup_run_tmp_on_exit >/dev/null 2>&1; then
  # Fallback cleanup when function was not loaded due to inherited state
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "$RUN_TMPDIR" ]; then
    case "$RUN_TMPDIR" in
      "$BASH4LLM_TMPDIR"/*)
        rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
        ;;
    esac
  fi
fi
exit 0
