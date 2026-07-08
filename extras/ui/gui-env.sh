#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/ui/gui-env.sh
# Extra: GUI-CGI Environment layer
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Centralized error, logging, diagnostics layer and runtime environment.

# Prevents writing core dumps for safety
ulimit -c 0 2>/dev/null || true

# Prevent double-sourcing by checking function declaration
if declare -f gui_env_init >/dev/null 2>&1; then
  return 0 2>/dev/null || true
fi

# Basic helper to generate ISO 8601 UTC timestamps
_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_safe_printf() {
  printf '%s' "$1"
}

# Configure robust and safe PS4 trace output
{
  _ps4_src="${BASH_SOURCE[0]:-$0}"
  _ps4_name="${_ps4_src##*/}"
  export PS4='+[$(_now_iso)] '"${_ps4_name}"':${LINENO}: '
  unset _ps4_src _ps4_name
} 2>/dev/null || true

# Safe UI_ROOT automatic path resolution
if [[ -z "${UI_ROOT:-}" ]]; then
  UI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
  export UI_ROOT
fi

# Environment runtime constants and file paths (Declared globally as single source of truth)
: "${TMP_DIR:=${UI_ROOT}/tmp}"
: "${LOG_DIR:=${UI_ROOT}/logs}"
: "${CFG_DIR:=${UI_ROOT}/config}"
: "${CONV_DIR:=${UI_ROOT}/conversations}"
: "${FILES_DIR:=${UI_ROOT}/files}"
: "${TEMPLATES_DIR:=${UI_ROOT}/templates}"
: "${LOCK_FILE:=${TMP_DIR}/gui.lock}"
: "${SERVER_LOG:=${LOG_DIR}/server.log}"
: "${ERROR_LOG:=${LOG_DIR}/errors.log}"
: "${CURRENT_CONV_FILE:=${CFG_DIR}/current-conv}"
: "${LANG_CURRENT_FILE:=${CFG_DIR}/current-lang}"
: "${THEME_CURRENT_FILE:=${CFG_DIR}/current-theme}"
: "${SESSION_WINDOW_FILE:=${CFG_DIR}/session-window}"
: "${BASH4LLM_CMD:=}"
: "${conv_default:=conv-1.txt}"

# Primitives for structured logging
_log_common() {
  local level="$1"; shift
  local tag="$1"; shift
  local msg="$*"
  local ts pid out target_dir target_file
  ts="$(_now_iso)"
  pid="$$"
  out="${ts} bash4llm: ${level}: ${tag}: pid=${pid}: ${msg}"

  if [[ "${level}" == "ERROR" || "${level}" == "FATAL" || "${level}" == "CGI_FATAL" ]]; then
    target_file="${ERROR_LOG:-}"
  else
    target_file="${SERVER_LOG:-}"
  fi

  if [[ -n "${target_file:-}" ]]; then
    target_dir="$(dirname -- "$target_file" 2>/dev/null || true)"
    if [[ -n "$target_dir" ]]; then
      mkdir -p -- "$target_dir" 2>/dev/null || true
      printf '%s\n' "$out" >>"$target_file" 2>/dev/null || printf '%s\n' "$out" >&2 || true
      return 0
    fi
  fi

  printf '%s\n' "$out" >&2 || true
  return 0
}

log_debug() { _log_common "DEBUG" "${1:-DEBUG}" "${@:2}"; }
log_info()  { _log_common "INFO"  "${1:-INFO}"  "${@:2}"; }
log_warn()  { _log_common "WARN"  "${1:-WARN}"  "${@:2}"; }
log_error() { _log_common "ERROR" "${1:-ERROR}" "${@:2}"; }

safe_append_log() {
  local file="$1"; shift
  local line="$*"
  if [[ -z "$file" ]]; then return 1; fi
  mkdir -p -- "$(dirname -- "$file")" 2>/dev/null || true
  printf '%s\n' "$line" >>"$file" 2>/dev/null || printf '%s\n' "$line" >&2 || true
  return 0
}

# Rotate log files on maximum size bounds
log_rotate_if_needed() {
  local file="$1" max_bytes="${2:-1048576}"
  if [[ -z "$file" ]]; then return 1; fi
  if [[ -f "$file" ]]; then
    local size
    size="$(wc -c <"$file" 2>/dev/null || echo 0)"
    if (( size > max_bytes )); then
      mv -f "$file" "${file}.old" 2>/dev/null || true
      : >"$file" 2>/dev/null || true
    fi
  fi
  return 0
}

fatal() {
  local rc="${1:-1}"; shift || true
  local msg="${*:-Fatal error}"
  log_error "FATAL" "$msg"
  exec 2>&2 || true
  exit "$rc"
}

cgi_fatal() {
  local rc="${1:-1}"; shift || true
  local msg="${*:-Server error}"
  log_error "CGI_FATAL" "$msg"

  printf 'Status: 500 Internal Server Error\r\n'
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
  printf '<!doctype html><html><head><meta charset="utf-8"><title>Server Error</title></head><body>'
  printf '<h1>500 Internal Server Error</h1>'
  printf '<p>An internal server error occurred. Please configure the LLM GUI using the settings page.</p>'
  printf '</body></html>\n'
  exec 2>&2 || true
  exit "$rc"
}

# Resolve canonical paths safely, handling non-existent paths gracefully (macOS/BSD compatibility)
_canonical_path() {
  local target="$1"
  [[ -z "$target" ]] && return 1
  if [[ -e "$target" ]]; then
    readlink -f -- "$target" 2>/dev/null || printf '%s' "$target"
  else
    local parent file parent_canon
    parent="$(dirname -- "$target")"
    file="$(basename -- "$target")"
    if [[ -d "$parent" ]]; then
      parent_canon="$(cd -- "$parent" >/dev/null 2>&1 && pwd -P || readlink -f -- "$parent" 2>/dev/null || printf '%s' "$parent")"
      printf '%s/%s' "${parent_canon%/}" "$file"
    else
      readlink -f -- "$target" 2>/dev/null || printf '%s' "$target"
    fi
  fi
}

# Restrict file execution and access paths to UI directory perimeter
path_within_ui_root() {
  local p="$1"
  if [[ -z "${UI_ROOT:-}" ]]; then
    return 0
  fi
  local p_real root_real core_real
  p_real="$(_canonical_path "$p")"
  root_real="$(_canonical_path "$UI_ROOT")"
  core_real="$(_canonical_path "${BASH4LLM_DIR:-}")"

  case "$p_real" in
    "$root_real"/*|"$root_real") return 0 ;;
    *)
      if [[ -n "$core_real" ]]; then
        case "$p_real" in
          "$core_real"/*|"$core_real") return 0 ;;
        esac
      fi
      return 1
      ;;
  esac
}

# String sanitization and URL decoding helpers
url_decode() {
  local s="${1:-}"
  s="${s//+/ }"
  local decoded=""
  local i=0
  local len=${#s}
  while (( i < len )); do
    local c="${s:i:1}"
    if [[ "$c" == "%" && $(( i + 2 )) -lt len ]]; then
      local hex="${s:i+1:2}"
      local octal
      # Converte in ottale per garantire la massima portabilità di printf su tutte le piattaforme
      if printf -v octal '%03o' "0x$hex" 2>/dev/null; then
        printf -v c "\\$octal"
        i=$(( i + 3 ))
      else
        i=$(( i + 1 ))
      fi
    else
      i=$(( i + 1 ))
    fi
    decoded+="$c"
  done
  printf '%s\n' "$decoded"
}

html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&#x27;}"
  printf '%s' "$s"
}

sanitize_param() {
  local s="$1"
  local maxlen="${2:-256}"
  s="$(printf '%s' "$s" | tr -d '\000' | sed -E 's/[\x00-\x1F\x7F]+/ /g')"
  s="$(printf '%s' "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  s="$(printf '%s' "$s" | tr -s '[:space:]' ' ')"
  if [ "${#s}" -gt "$maxlen" ]; then
    s="${s:0:$maxlen}"
  fi
  printf '%s' "$s"
}

validate_name() {
  local name="$1"
  local maxlen="${2:-128}"
  if [[ -z "$name" ]]; then return 1; fi
  if (( ${#name} > maxlen )); then return 1; fi
  if [[ "$name" =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)?$ ]]; then
    return 0
  else
    return 1
  fi
}

# Global POST body cache to allow multiple reads without consuming standard input
_GUI_CACHED_POST_BODY=""
_GUI_POST_BODY_READ=0

read_post_body() {
  local max="${1:-65536}"
  if [[ "$_GUI_POST_BODY_READ" -eq 1 ]]; then
    printf '%s' "$_GUI_CACHED_POST_BODY"
    return 0
  fi
  _GUI_POST_BODY_READ=1
  local ctlen="${CONTENT_LENGTH:-0}"
  if [[ -n "$ctlen" && "$ctlen" -gt "$max" ]]; then
    log_warn "CGI" "POST body exceeds bounds limit: ${ctlen} > ${max}"
    _GUI_CACHED_POST_BODY="$(dd bs=1 count="$max" 2>/dev/null || true)"
    printf '%s' "$_GUI_CACHED_POST_BODY"
    return 1
  fi
  if [ -n "${CONTENT_LENGTH:-}" ]; then
    _GUI_CACHED_POST_BODY="$(dd bs=1 count="${CONTENT_LENGTH}" 2>/dev/null || true)"
  else
    _GUI_CACHED_POST_BODY="$(head -c "$max")"
  fi
  printf '%s' "$_GUI_CACHED_POST_BODY"
  return 0
}

parse_form_field() {
  local key="$1"
  local body
  if [[ "$_GUI_POST_BODY_READ" -eq 1 ]]; then
    body="$_GUI_CACHED_POST_BODY"
  else
    body="$(cat -)"
  fi
  local kv
  kv="$(printf '%s' "$body" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1); exit}')"
  if [[ -z "$kv" ]]; then
    printf ''
    return 0
  fi
  local decoded
  decoded="$(url_decode "$kv" 2>/dev/null || printf '%s' "$kv")"
  decoded="$(sanitize_param "$decoded")"
  printf '%s' "$decoded"
}

get_tenant_from_request() {
  local tenant=""
  # 1. Attempting to extract from QUERY_STRING (GET)
  if [[ -n "${QUERY_STRING:-}" ]]; then
    tenant="$(printf '%s' "$QUERY_STRING" | tr '&' '\n' | awk -F= '$1=="tenant"{print substr($0, index($0,"=")+1); exit}')"
    if [[ -n "$tenant" ]]; then
      tenant="$(url_decode "$tenant" 2>/dev/null || printf '%s' "$tenant")"
      tenant="$(sanitize_param "$tenant")"
    fi
  fi
  # 2. Attempt to extract from the request body (POST)
  if [[ -z "$tenant" && "${REQUEST_METHOD:-}" == "POST" ]]; then
    local dummy
    dummy="$(read_post_body)"
    tenant="$(printf '%s' "$_GUI_CACHED_POST_BODY" | tr '&' '\n' | awk -F= '$1=="tenant"{print substr($0, index($0,"=")+1); exit}')"
    if [[ -n "$tenant" ]]; then
      tenant="$(url_decode "$tenant" 2>/dev/null || printf '%s' "$tenant")"
      tenant="$(sanitize_param "$tenant")"
    fi
  fi
  
  # Format validation (alphanumeric, hyphens, underscores)
  if [[ -n "$tenant" ]] && validate_name "$tenant"; then
    printf '%s' "$tenant"
    return 0
  fi
  printf ''
  return 1
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

print_http_header() {
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
}

print_http_redirect() {
  local loc="$1"
  if [[ -n "${TENANT_HASH:-}" ]]; then
    if [[ "$loc" == *"?"* ]]; then
      if [[ "$loc" != *"tenant="* ]]; then
        loc="${loc}&tenant=${TENANT_HASH}"
      fi
    else
      loc="${loc}?tenant=${TENANT_HASH}"
    fi
  fi
  printf 'Status: 303 See Other\r\n'
  printf 'Location: %s\r\n' "$loc"
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf '\r\n'
  printf '<html><body>See <a href="%s">%s</a></body></html>' "$(printf '%s' "$loc" | sed -e 's/&/\&amp;/g')" "$(printf '%s' "$loc" | sed -e 's/&/\&amp;/g')"
}

print_http_error() {
  local status="$1" msg="$2"
  printf 'Status: %s\r\n' "$status"
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
  printf '<h1>%s</h1>\n' "$(printf '%s' "$msg" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')"
}

is_cgi_mode() {
  if [[ -n "${REQUEST_METHOD:-}" || -n "${GATEWAY_INTERFACE:-}" ]]; then
    return 0
  fi
  return 1
}

# Validate and secure UI_ROOT
canonicalize_ui_root() {
  local orig ui_real env_script env_dir

  orig="${UI_ROOT:-}"
  if [[ -z "$orig" ]]; then
    log_error "INIT" "UI_ROOT not set"
    return 1
  fi

  ui_real="$(_canonical_path "$orig")"
  if [[ -z "$ui_real" || ! -d "$ui_real" ]]; then
    log_error "INIT" "UI_ROOT invalid or not a directory: ${orig:-<unset>}"
    return 1
  fi

  env_script="${BASH_SOURCE[0]:-$0}"
  env_dir="$(dirname -- "$(_canonical_path "$env_script")")"

  case "$ui_real" in
    "$env_dir"/*|"$env_dir") ;;
    *)
      case "$env_dir" in
        "$ui_real"/*) ;;
        *)
          log_error "INIT" "UI_ROOT ($ui_real) outside secure scope perimeter ($env_dir)"
          return 1
          ;;
      esac
      ;;
  esac

  UI_ROOT="$ui_real"
  export UI_ROOT

  CGI_DIR="${UI_ROOT%/}/cgi-bin"
  LOG_DIR="${UI_ROOT%/}/logs"
  SERVER_LOG="${LOG_DIR%/}/server.log"
  ERROR_LOG="${LOG_DIR%/}/errors.log"
  export CGI_DIR LOG_DIR SERVER_LOG ERROR_LOG

  return 0
}

ensure_logs_dir() {
  if [[ -z "${UI_ROOT:-}" ]]; then
    log_error "INIT" "UI_ROOT not resolved; logs aborted"
    return 1
  fi

  mkdir -p -- "$LOG_DIR" 2>/dev/null || true
  chmod 700 -- "$LOG_DIR" 2>/dev/null || true

  if [[ ! -f "$SERVER_LOG" ]]; then
    : >"$SERVER_LOG" 2>/dev/null || {
      log_error "INIT" "Cannot instantiate SERVER_LOG: $SERVER_LOG"
      return 1
    }
  fi
  chmod 600 -- "$SERVER_LOG" 2>/dev/null || true

  if [[ ! -f "$ERROR_LOG" ]]; then
    : >"$ERROR_LOG" 2>/dev/null || {
      log_error "INIT" "Cannot instantiate ERROR_LOG: $ERROR_LOG"
      return 1
    }
  fi
  chmod 600 -- "$ERROR_LOG" 2>/dev/null || true

  return 0
}

# Trap hooks management
_GUI_ENV_EXIT_HOOKS=()

gui_env_register_exit_hook() {
  local fn="$1"
  if [[ -z "$fn" ]]; then return 1; fi
  if declare -f "$fn" >/dev/null 2>&1; then
    _GUI_ENV_EXIT_HOOKS+=("$fn")
    return 0
  fi
  return 1
}

gui_env_on_exit() {
  local i
  for (( i=${#_GUI_ENV_EXIT_HOOKS[@]}-1; i>=0; i-- )); do
    local h="${_GUI_ENV_EXIT_HOOKS[i]}"
    if declare -f "$h" >/dev/null 2>&1; then
      "$h" || true
    fi
  done
  log_info "EXIT" "CGI exited cleanly"
  return 0
}

install_default_traps() {
  local mode="${1:-}"
  if [[ -z "$mode" ]]; then
    mode="cli"
  fi

  _GUI_ENV_TRAP_MODE="${mode}"

  if [[ "${_GUI_ENV_TRAPS_INSTALLED:-}" == "1" ]]; then
    return 0
  fi
  _GUI_ENV_TRAPS_INSTALLED=1
  _GUI_ENV_TRAP_INVOKED=0

  _gui_env_err_trap() {
    local rc=$?
    if [[ "${_GUI_ENV_TRAP_INVOKED:-0}" -ne 0 ]]; then
      return 0
    fi
    _GUI_ENV_TRAP_INVOKED=1
    gui_env_on_exit || true
    if [[ "${_GUI_ENV_TRAP_MODE:-cli}" == "cgi" ]]; then
      cgi_fatal "$rc" "Uncaught error exception in CGI runtime loop"
    else
      fatal "$rc" "Uncaught error exception in CLI"
    fi
  }

  _gui_env_exit_trap() {
    local rc=$?
    if [[ "${_GUI_ENV_TRAP_INVOKED:-0}" -ne 0 ]]; then
      return 0
    fi
    _GUI_ENV_TRAP_INVOKED=1
    gui_env_on_exit || true
    if [[ "$rc" -ne 0 ]]; then
      if [[ "${_GUI_ENV_TRAP_MODE:-cli}" == "cgi" ]]; then
        cgi_fatal "$rc" "CGI script terminated with non-zero status"
      else
        log_error "EXIT" "Script exited with status $rc"
        exit "$rc"
      fi
    fi
  }

  trap '_gui_env_err_trap' ERR
  trap '_gui_env_exit_trap' EXIT

  return 0
}

gui_env_init() {
  local mode="${1:-cli}"
  canonicalize_ui_root || return 1
  ensure_logs_dir || return 1

  local target_umask="${BASH4LLM_UMASK:-077}"
  umask "$target_umask"

  log_rotate_if_needed "${SERVER_LOG:-/dev/null}" 1048576 || true
  log_rotate_if_needed "${ERROR_LOG:-/dev/null}" 1048576 || true

  install_default_traps "$mode" || return 1

  if [[ -n "${ERROR_LOG:-}" && -w "$(dirname -- "$ERROR_LOG")" ]]; then
    if ! { exec 2>>"$ERROR_LOG"; } 2>/dev/null; then
      log_warn "INIT" "Failed to link stderr stream to log output"
    fi
  fi

  return 0
}

env_detect() {
  IS_TERMUX=0
  IS_LINUX=0
  IS_MAC=0
  IS_WSL=0
  IS_CYGWIN=0

  local uname_s
  uname_s="$(uname -s 2>/dev/null || true)"

  if [[ -d "/data/data/com.termux/files/usr" ]]; then
    IS_TERMUX=1
  elif [[ "$uname_s" == "Darwin" ]]; then
    IS_MAC=1
  elif [[ "$uname_s" == "Linux" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
      IS_WSL=1
    else
      IS_LINUX=1
    fi
  elif [[ "$uname_s" == *"CYGWIN"* || "$uname_s" == *"MINGW"* ]]; then
    IS_CYGWIN=1
  fi

  export IS_TERMUX IS_LINUX IS_MAC IS_WSL IS_CYGWIN
  return 0
}

env_prepare_runtime() {
  local bash4llm_real BIN_DIR wrapper tmp_wrapper rc real_hash wrapper_hash
  
  local candidates=(
    "${UI_ROOT%/}/../bash4llm/bash4llm"
    "${UI_ROOT%/}/../../bash4llm/bash4llm"
    "${PWD%/}/bash4llm"
    "${HOME%/}/bash4llm/bash4llm"
    "/data/data/com.termux/files/home/bash4llm/bash4llm"
  )

  bash4llm_real=""
  for cand in "${candidates[@]}"; do
    if [[ -x "$cand" ]]; then
      bash4llm_real="$cand"
      break
    fi
  done

  if [[ "${INSTALL_MODE:-0}" -ne 1 ]]; then
    if [[ -f "${CFG_DIR%/}/bash4llm-path" ]]; then
      local persisted
      persisted="$(sed -n '1p' "${CFG_DIR%/}/bash4llm-path" 2>/dev/null || true)"
      if [[ -n "$persisted" && -x "$persisted" ]]; then
        BASH4LLM_CMD="$persisted"
        export BASH4LLM_CMD
        PATH="${UI_ROOT%/}/bin:${PATH:-}"
        export PATH
        return 0
      fi
    fi

    if [[ "${IS_TERMUX:-0}" -eq 1 ]]; then
      BIN_DIR="${UI_ROOT%/}/bin"
      wrapper="$BIN_DIR/bash4llm-wrapper"
      if [[ -x "$wrapper" ]]; then
        BASH4LLM_CMD="$wrapper"
        export BASH4LLM_CMD
        PATH="$BIN_DIR:${PATH:-}"
        export PATH
        return 0
      fi
      if [[ -n "$bash4llm_real" && -x "$bash4llm_real" ]]; then
        BASH4LLM_CMD="$bash4llm_real"
        export BASH4LLM_CMD
        return 0
      fi
      return 0
    fi

    if [[ -n "$bash4llm_real" && -x "$bash4llm_real" ]]; then
      BASH4LLM_CMD="$bash4llm_real"
      export BASH4LLM_CMD
      return 0
    fi
    return 0
  fi

  # Se non siamo su Termux, persiste semplicemente il percorso reale ed esce
  if [[ "${IS_TERMUX:-0}" -ne 1 ]]; then
    if [[ -n "$bash4llm_real" && -x "$bash4llm_real" ]]; then
      mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
      if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" ]]; then
        local tmp_path line_count
        tmp_path="$(gui_portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}")" || tmp_path="${CFG_DIR%/}/bash4llm-path.tmp"
        if printf '%s\n' "$bash4llm_real" >"$tmp_path" 2>/dev/null; then
          line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
          if [[ "$line_count" -eq 1 ]]; then
            mv -f -- "$tmp_path" "${CFG_DIR%/}/bash4llm-path"
            chmod 600 "${CFG_DIR%/}/bash4llm-path" 2>/dev/null || true
            BASH4LLM_CMD="$bash4llm_real"
            export BASH4LLM_CMD
            return 0
          else
            rm -f -- "$tmp_path" 2>/dev/null || true
            return 0
          fi
        else
          rm -f -- "$tmp_path" 2>/dev/null || true
          return 0
        fi
      else
        return 0
      fi
    else
      return 0
    fi
  fi

  # --- LOGICA SOLO PER TERMUX (Generazione del Wrapper diretto) ---
  ensure_tmpdir || return 0
  if ! command -v flock >/dev/null 2>&1; then
    return 0
  fi

  exec 9>"${BOOTSTRAP_LOCK}" 2>/dev/null || return 0
  if ! flock -x -w 5 9; then
    exec 9>&- 2>/dev/null || true
    return 0
  fi

  _release_lock() {
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
  }

  if [[ -z "$bash4llm_real" ]]; then
    _release_lock
    return 0
  fi

  local termux_bash
  termux_bash="$(command -v bash 2>/dev/null || echo "/data/data/com.termux/files/usr/bin/bash")"

  local BIN_DIR="$UI_ROOT/bin"
  mkdir -p -- "$BIN_DIR" 2>/dev/null || true
  chmod 750 -- "$BIN_DIR" 2>/dev/null || true
  wrapper="$BIN_DIR/bash4llm-wrapper"

  tmp_wrapper="$(gui_portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}")" || tmp_wrapper=""
  if [[ -n "$tmp_wrapper" ]]; then
    # Il wrapper ora chiama direttamente l'interprete passandogli il file reale
    printf '%s\n' "#!$termux_bash" "exec \"$termux_bash\" \"$bash4llm_real\" \"\$@\"" >"$tmp_wrapper" 2>/dev/null || {
      rm -f -- "$tmp_wrapper" 2>/dev/null || true
      _release_lock
      return 0
    }

    if ! mv -f -- "$tmp_wrapper" "$wrapper" 2>/dev/null; then
      rm -f -- "$tmp_wrapper" 2>/dev/null || true
      _release_lock
      return 0
    fi
  else
    _release_lock
    return 0
  fi

  chmod 750 "$wrapper" 2>/dev/null || true
  _release_lock

  BASH4LLM_CMD="$wrapper"
  export BASH4LLM_CMD
  PATH="$BIN_DIR:${PATH:-}"
  export PATH

  # Persiste la configurazione del percorso
  mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
  local tmp_path line_count
  tmp_path="$(gui_portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}")" || tmp_path="${CFG_DIR%/}/bash4llm-path.tmp"
  if printf '%s\n' "$wrapper" >"$tmp_path" 2>/dev/null; then
    mv -f -- "$tmp_path" "${CFG_DIR%/}/bash4llm-path" 2>/dev/null
    chmod 600 "${CFG_DIR%/}/bash4llm-path" 2>/dev/null || true
  else
    rm -f -- "$tmp_path" 2>/dev/null || true
  fi

  return 0
}

env_after_bash4llm_resolved() {
  return 0
}

# General purpose utility and safety IO helpers
ensure_tmpdir() {
  if [[ -e "$TMP_DIR" && ! -d "$TMP_DIR" ]]; then
    return 1
  fi
  if [[ ! -d "$TMP_DIR" ]]; then
    mkdir -p "$TMP_DIR" 2>/dev/null || true
    chmod 700 "$TMP_DIR" 2>/dev/null || true
  fi
  if [[ ! -w "$TMP_DIR" ]]; then
    return 1
  fi
  return 0
}

# Renamed to gui_portable_mktemp to prevent namespace clashing with core
gui_portable_mktemp() {
  local dir="${1:-}" template="${2:-.tmp.XXXXXX}"
  local dir_real tmp candidate base i rand

  if [[ -z "$dir" ]]; then
    return 1
  fi

  mkdir -p -- "$dir" 2>/dev/null || return 1
  dir_real="$(cd -- "$dir" 2>/dev/null && pwd -P || true)"
  if [[ -z "$dir_real" || ! -d "$dir_real" || ! -w "$dir_real" ]]; then
    return 1
  fi

  if [[ -n "${TMP_DIR:-}" ]]; then
    case "$dir_real" in
      "$TMP_DIR"/*|"$TMP_DIR") ;;
      *) return 1 ;;
    esac
  fi

  if command -v mktemp >/dev/null 2>&1; then
    if tmp="$(mktemp -p "$dir_real" "$template" 2>/dev/null)"; then
      chmod 600 -- "$tmp" 2>/dev/null || true
      printf '%s' "$tmp"
      return 0
    fi
    if tmp="$(mktemp "${dir_real}/${template}" 2>/dev/null)"; then
      chmod 600 -- "$tmp" 2>/dev/null || true
      printf '%s' "$tmp"
      return 0
    fi
  fi

  base="$(date +%s%N 2>/dev/null || printf '%s' "$$")"
  i=0
  while (( i < 200 )); do
    rand="${base}.$RANDOM.$$.$i"
    if [[ "$template" == *"XXXXXX"* ]]; then
      candidate="${template//XXXXXX/$rand}"
    else
      candidate="${template}.$rand"
    fi
    tmp="$dir_real/$candidate"
    ( set -C; : >"$tmp" ) 2>/dev/null && { chmod 600 -- "$tmp" 2>/dev/null || true; printf '%s' "$tmp"; return 0; }
    i=$((i+1))
  done

  return 1
}

# Renamed to gui_atomic_write to prevent namespace clashing with core
gui_atomic_write() {
  local dest="$1" content="${2:-}" dest_dir tmp

  if [[ -z "${dest:-}" ]]; then
    return 1
  fi

  dest_dir="$(dirname -- "$dest")"

  if declare -f path_within_ui_root >/dev/null 2>&1 && [[ -n "${UI_ROOT:-}" ]]; then
    if ! path_within_ui_root "$dest"; then
      return 1
    fi
  fi

  ensure_tmpdir || return 1

  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(gui_portable_mktemp "$TMP_DIR" "atomic.XXXXXX")"; then
    :
  else
    tmp="$(gui_portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}" "atomic.XXXXXX")"
  fi

  if [[ -z "${tmp:-}" ]]; then
    return 1
  fi

  umask 077
  printf '%s' "$content" >"$tmp" || { rm -f "$tmp" 2>/dev/null || true; return 1; }

  if command -v sync >/dev/null 2>&1; then sync || true; fi

  mv -f "$tmp" "$dest" || { rm -f "$tmp" 2>/dev/null || true; return 1; }

  chmod 600 "$dest" 2>/dev/null || true
  return 0
}

# Securing context conversation append sequentially with transactional POSIX locks (Isolating namespace)
gui_atomic_append_conv() {
  local conv_file="$1" append_text="${2:-}" tmp dest_dir lockfile lockfd
  if [[ -z "$conv_file" ]]; then return 1; fi
  dest_dir="$(dirname -- "$conv_file")"
  mkdir -p -- "$dest_dir" 2>/dev/null || true

  lockfile="${conv_file}.lock"
  if command -v flock >/dev/null 2>&1; then
    exec {lockfd}>"$lockfile" 2>/dev/null || lockfd=""
    if [[ -n "$lockfd" ]]; then
      flock -x "$lockfd" 2>/dev/null || true
    fi
  fi

  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(gui_portable_mktemp "$TMP_DIR" "conv.XXXXXX")"; then
    :
  else
    tmp="$(gui_portable_mktemp "$dest_dir" "conv.XXXXXX")"
  fi

  if [[ -f "$conv_file" ]]; then
    cat "$conv_file" >"$tmp" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  else
    : >"$tmp"
  fi

  if [[ -n "$append_text" ]]; then
    printf '%s\n' "$append_text" >>"$tmp" || { rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  else
    cat >>"$tmp" || { rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  fi

  mv -f "$tmp" "$conv_file" || { rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  chmod 600 "$conv_file" || true

  if [[ -n "$lockfd" ]]; then
    flock -u "$lockfd" 2>/dev/null || true
    exec {lockfd}>&- 2>/dev/null || true
  fi
  return 0
}

compute_hash() {
  local file="$1" tmpf
  [[ -f "$file" ]] || { printf ''; return 0; }
  tmpf="$(gui_portable_mktemp "$TMP_DIR" "hash.XXXXXX")" || { printf ''; return 0; }
  tail -n +2 "$file" >"$tmpf" 2>/dev/null || cat "$file" >"$tmpf" 2>/dev/null || true
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$tmpf" 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$tmpf" 2>/dev/null | awk '{print $1}'
  else
    stat -c '%s-%Y' "$tmpf" 2>/dev/null || printf ''
  fi
  rm -f -- "$tmpf" 2>/dev/null || true
}

same_filesystem() {
  local a="$1" b="$2" da db fa fb
  da="$a"; while [[ ! -e "$da" && "$da" != "/" ]]; do da="$(dirname -- "$da")"; done
  db="$b"; while [[ ! -e "$db" && "$db" != "/" ]]; do db="$(dirname -- "$db")"; done
  if [[ ! -e "$da" || ! -e "$db" ]]; then return 1; fi
  fa="$(df -P "$da" 2>/dev/null | awk 'END{print $1}')" || fa=""
  fb="$(df -P "$db" 2>/dev/null | awk 'END{print $1}')" || fb=""
  [[ -n "$fa" && -n "$fb" && "$fa" == "$fb" ]]
}

gui_env_health_check() {
  local ok=0
  if ! ensure_tmpdir; then
    ok=1
  fi
  if [[ -z "${LOG_DIR:-}" || ! -d "${LOG_DIR:-}" || ! -w "${LOG_DIR:-}" ]]; then
    ok=1
  fi
  if ! command -v flock >/dev/null 2>&1; then
    ok=1
  fi
  if [[ -n "${BASH4LLM_CMD:-}" && ! -x "${BASH4LLM_CMD}" ]]; then
    ok=1
  fi
  return $ok
}

gui_env_dump_diag() {
  local lines="${1:-50}"
  printf '--- DIAGNOSTIC DUMP (%s lines) ---\n' "$lines"
  printf 'UI_ROOT=%s\n' "${UI_ROOT:-<unset>}"
  printf 'TMP_DIR=%s\n' "${TMP_DIR:-<unset>}"
  printf 'LOG_DIR=%s\n' "${LOG_DIR:-<unset>}"
  printf 'BASH4LLM_CMD=%s\n' "${BASH4LLM_CMD:-<unset>}"
  printf '--- SERVER_LOG (last %s lines) ---\n' "$lines"
  if [[ -f "${SERVER_LOG:-}" ]]; then
    tail -n "$lines" "${SERVER_LOG}" 2>/dev/null || true
  fi
  printf '--- ERROR_LOG (last %s lines) ---\n' "$lines"
  if [[ -f "${ERROR_LOG:-}" ]]; then
    tail -n "$lines" "${ERROR_LOG}" 2>/dev/null || true
  fi
  return 0
}

# SSOT configuration helpers reading from core files directly
read_config_or_default() {
  local file="$1" default="${2:-}"
  if [[ -f "$file" && -r "$file" ]]; then
    local val
    val="$(head -n 1 "$file" 2>/dev/null || true)"
    val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)"
    if [[ -n "$val" ]]; then
      printf '%s' "$val"
      return 0
    fi
  fi
  printf '%s' "$default"
  return 0
}

ensure_dirs() {
  : "${UI_ROOT:=${UI_ROOT:-$PWD}}"
  : "${TMP_DIR:=${UI_ROOT}/tmp}"
  : "${LOG_DIR:=${UI_ROOT}/logs}"
  : "${CFG_DIR:=${UI_ROOT}/config}"
  : "${CONV_DIR:=${UI_ROOT}/conversations}"
  : "${FILES_DIR:=${UI_ROOT}/files}"
  : "${TEMPLATES_DIR:=${UI_ROOT}/templates}"

  local d
  for d in "$TMP_DIR" "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR" "$TEMPLATES_DIR"; do
    mkdir -p -- "$d" 2>/dev/null || {
      return 1
    }
    chmod 700 -- "$d" 2>/dev/null || true
  done
  
  return 0
}

ensure_sh_executables() {
  local target_dir="${1:-}"
  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    return 1
  fi
  
  if declare -f path_within_ui_root >/dev/null 2>&1; then
    if ! path_within_ui_root "$target_dir"; then
      return 1
    fi
  fi

  find "$target_dir" -type f -name "*.sh" -exec chmod 750 {} + 2>/dev/null || true
  return 0
}

remove_unnecessary_symlinks() {
  local target_dir="${1:-}"
  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    return 1
  fi

  if declare -f path_within_ui_root >/dev/null 2>&1; then
    if ! path_within_ui_root "$target_dir"; then
      return 1
    fi
  fi

  find "$target_dir" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  return 0
}

ensure_config_defaults() {  
  local lang_current_file="${CFG_DIR}/current-lang"
  local theme_current_file="${CFG_DIR}/current-theme"
  local use_sessions_file="${CFG_DIR}/use-sessions"
  local session_window_file="${CFG_DIR}/session-window"

  if [[ ! -f "$lang_current_file" ]]; then
    mkdir -p "$(dirname "$lang_current_file")" 2>/dev/null || true
    printf 'en\n' > "$lang_current_file" 2>/dev/null || true
    chmod 600 "$lang_current_file" 2>/dev/null || true
  fi

  if [[ ! -f "$theme_current_file" ]]; then
    mkdir -p "$(dirname "$theme_current_file")" 2>/dev/null || true
    printf 'light\n' > "$theme_current_file" 2>/dev/null || true
    chmod 600 "$theme_current_file" 2>/dev/null || true
  fi

  if [[ ! -f "$use_sessions_file" ]]; then
    mkdir -p "$(dirname "$use_sessions_file")" 2>/dev/null || true
    printf 'enabled\n' > "$use_sessions_file" 2>/dev/null || true
    chmod 600 "$use_sessions_file" 2>/dev/null || true
  fi

  if [[ ! -f "$session_window_file" ]]; then
    mkdir -p "$(dirname "$session_window_file")" 2>/dev/null || true
    printf '10\n' > "$session_window_file" 2>/dev/null || true
    chmod 600 "$session_window_file" 2>/dev/null || true
  fi

  return 0
}

# SSOT configuration helpers reading from core provider directly
get_default_provider() {
  local p_file provider
  if [[ -n "${BASH4LLM_CMD:-}" && -x "${BASH4LLM_CMD}" ]]; then
    p_file="$("${BASH4LLM_CMD}" --print-provider-file 2>/dev/null || true)"
    p_file="$(printf '%s' "$p_file" | awk '{$1=$1;print}')"
  fi
  if [[ -z "$p_file" || ! -f "$p_file" ]]; then
    p_file="${BASH4LLM_DIR:-${UI_ROOT}/../bash4llm.d}/config/provider"
  fi
  read_config_or_default "$p_file" "groq"
}

# SSOT configuration helpers reading from core model file directly
get_default_model() {
  local prov m_file model
  prov="$(get_default_provider)"
  if [[ -n "${BASH4LLM_CMD:-}" && -x "${BASH4LLM_CMD}" && -n "$prov" ]]; then
    m_file="$("${BASH4LLM_CMD}" --print-model-file "$prov" 2>/dev/null || true)"
    m_file="$(printf '%s' "$m_file" | awk '{$1=$1;print}')"
  fi
  if [[ -z "$m_file" || ! -f "$m_file" ]]; then
    m_file="${BASH4LLM_DIR:-${UI_ROOT}/../bash4llm.d}/config/model.${prov}"
  fi
  read_config_or_default "$m_file" ""
}

get_session_window() {
  local win
  win="$(read_config_or_default "${SESSION_WINDOW_FILE:-${CFG_DIR}/session-window}" "10")"
  if [[ "$win" =~ ^[0-9]+$ ]] && (( win >= 1 && win <= 20 )); then
    printf '%s' "$win"
  else
    printf '10'
  fi
}

# Read API key for a specific provider (POSIX permissions & Provider segregations)
read_api_key_file() {
  local provider="${1:-}"
  if [[ -z "$provider" ]]; then
    provider="$(get_default_provider)"
  fi
  local key_file="${CFG_DIR}/api-key.${provider}"
  read_config_or_default "$key_file" ""
}

# Write API key for a specific provider securing permissions statically to 600
save_api_key_file() {
  local api_key="$1"
  local provider="${2:-}"
  if [[ -z "$provider" ]]; then
    provider="$(get_default_provider)"
  fi
  local key_file="${CFG_DIR}/api-key.${provider}"
  mkdir -p "$(dirname "$key_file")" 2>/dev/null || true
  gui_atomic_write "$key_file" "$api_key" || return 1
  chmod 600 "$key_file" 2>/dev/null || true
  return 0
}

get_current_conversation_file() {
  local conv
  conv="$(read_config_or_default "${CURRENT_CONV_FILE:-${CFG_DIR}/current-conv}" "conv-1.txt")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then
    conv="conv-1.txt"
  fi
  printf '%s' "${CONV_DIR:-${UI_ROOT}/conversations}/$conv"
}

get_query_param() {
  local key="$1"
  if [[ -z "${QUERY_STRING:-}" ]]; then return 1; fi
  local kv
  kv="$(printf '%s' "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1); exit}')"
  if [[ -n "$kv" ]]; then
    url_decode "$kv"
    return 0
  fi
  return 1
}

# Export provider specific API key to clean sub-environment avoiding exposure in CLI command string
export_api_key_for_provider() {
  local provider="$1"
  if [[ -z "$provider" ]]; then return 1; fi
  local key
  key="$(read_api_key_file "$provider")"
  if [[ -n "$key" ]]; then
    local env_var
    env_var="$(printf '%s' "$provider" | tr '[:lower:]' '[:upper:]')_API_KEY"
    export "$env_var"="$key"
    export BASH4LLM_API_KEY="$key"
    return 0
  fi
  return 1
}

find_lang_conf() {
  local candidates=(
    "${UI_ROOT}/static/gui-lang.conf"
    "${UI_ROOT}/gui-lang.conf"
    "${UI_ROOT}/config/gui-lang.conf"
    "${UI_ROOT}/lang.conf"
    "${UI_ROOT}/config/lang.conf"
  )
  local cand
  for cand in "${candidates[@]}"; do
    if [[ -f "$cand" ]]; then
      printf '%s' "$cand"
      return 0
    fi
  done
  return 1
}

sanitize_model_output() {
  local s="$1"
  printf '%s' "$s" | tr -d '\000' | sed -E 's/\r$//g'
}

# NDJSON Parser parsing files under core's native structured session history
build_current_conv_block() {
  local file="$1"
  CURRENT_CONV=""
  local active_conv
  active_conv="$(basename "$file" .ndjson)"
  
  if [[ -z "$active_conv" ]]; then
    return 1
  fi
  
  local temp_json
  ensure_tmpdir || return 1
  temp_json="$(gui_portable_mktemp "$TMP_DIR" "hconv.XXXXXX")" || return 1

  local is_full
  is_full="$(get_query_param "full_history" 2>/dev/null || printf '0')"
  local window_size
  window_size="$(get_session_window)"
  if [[ "$is_full" == "1" ]]; then
    window_size=99999
  fi
  
  # Fetch session history using core logic
  if declare -f session_read_window >/dev/null 2>&1; then
    session_read_window "$active_conv" "$window_size" "$temp_json" >/dev/null 2>&1
  else
    local session_file="${BASH4LLM_DIR}/history/sessions/${active_conv}.ndjson"
    if [[ -f "$session_file" ]]; then
      # Highly optimized fallback: single jq execution instead of spawning multiple jq inside a loop
      tail -n "$window_size" "$session_file" 2>/dev/null | jq -s -c '{
        messages: map({role: (.role // "user"), content: (.content // "")})
      }' > "$temp_json" 2>/dev/null
    fi
  fi

  if [[ -f "$temp_json" && -s "$temp_json" ]]; then
    local idx=0 role content escaped_role escaped_content
    while read -r role; do
      content="$(jq -r ".messages[$idx].content // \"\"" "$temp_json" 2>/dev/null)"
      escaped_role="$(html_escape "$role")"
      escaped_content="$(html_escape "$content")"
      
      escaped_content="${escaped_content//$'\n'/<br>}"
      escaped_content="${escaped_content//$'\r'/}"

      if [[ "$escaped_role" == "user" ]]; then
        CURRENT_CONV+="<div class=\"message user-message\"><strong>User:</strong> ${escaped_content}</div>"$'\n'
      elif [[ "$escaped_role" == "assistant" ]]; then
        CURRENT_CONV+="<div class=\"message ai-message\"><strong>Assistant:</strong> ${escaped_content}</div>"$'\n'
      else
        CURRENT_CONV+="<div class=\"message system-message\"><strong>System:</strong> ${escaped_content}</div>"$'\n'
      fi
      idx=$((idx + 1))
    done < <(jq -r '.messages[]?.role // empty' "$temp_json" 2>/dev/null)
  fi

  rm -f -- "$temp_json" 2>/dev/null || true

  local total_lines=0
  local session_file="${BASH4LLM_DIR}/history/sessions/${active_conv}.ndjson"
  if [[ -f "$session_file" ]]; then
    total_lines="$(wc -l < "$session_file" 2>/dev/null || echo 0)"
  fi
  if [[ "$is_full" != "1" && "$total_lines" -gt "$window_size" ]]; then
    local current_page current_conv_name
    current_page="$(get_query_param "page" 2>/dev/null || printf 'main')"
    current_conv_name="$(read_config_or_default "${CURRENT_CONV_FILE:-${CFG_DIR}/current-conv}" "conv-1.txt")"
    current_conv_name="$(sanitize_param "$current_conv_name")"
    CURRENT_CONV+="<div class=\"load-more-container\"><a class=\"btn-secondary\" href=\"?page=${current_page}&select_conv=${current_conv_name}&full_history=1\">Load full history (${total_lines} turns)</a></div>"$'\n'
  fi
  export CURRENT_CONV
}

load_translations() {
  local lang_code="${1:-en}"
  local lang_conf key_lang val key code
  lang_conf="$(find_lang_conf || true)"
  if [[ -n "$lang_conf" && -f "$lang_conf" ]]; then
    while IFS="=" read -r key_lang val || [[ -n "$key_lang" ]]; do
      key_lang="${key_lang#"${key_lang%%[![:space:]]*}"}"
      key_lang="${key_lang%"${key_lang##*[![:space:]]}"}"
      val="${val#"${val%%[![:space:]]*}"}"
      val="${val%"${val##*[![:space:]]}"}"
      
      [[ "$key_lang" == "#"* ]] && continue
      [[ -z "$key_lang" ]] && continue
      [[ "$key_lang" != *"."* ]] && continue
      
      key="${key_lang%%.*}"
      code="${key_lang#*.}"
      
      key="${key//[[:space:]]/}"
      code="${code//[[:space:]]/}"
      
      if [[ "$code" == "$lang_code" ]]; then
        export "$key"="$val" 2>/dev/null || true
      fi
    done < <(awk -F'[ \t][ \t]+' '{for(i=1;i<=NF;i++) if($i ~ /=/) print $i}' "$lang_conf" 2>/dev/null || cat "$lang_conf")
  fi
}

render_template() {
  local file="$1"
  if [[ ! -f "$file" ]]; then return 1; fi
  awk '
  {
    while (match($0, /[{][{][A-Za-z0-9_]+[}][}]/)) {
      target = substr($0, RSTART, RLENGTH)
      varname = substr(target, 3, length(target) - 4)
      val = ENVIRON[varname]
      $0 = substr($0, 1, RSTART - 1) val substr($0, RSTART + RLENGTH)
    }
    while (match($0, /[$][{][A-Za-z0-9_]+[}]/)) {
      target = substr($0, RSTART, RLENGTH)
      varname = substr(target, 3, length(target) - 3)
      val = ENVIRON[varname]
      $0 = substr($0, 1, RSTART - 1) val substr($0, RSTART + RLENGTH)
    }
    print
  }' "$file"
}

# Directory-based atomic locking (Prefixing namespaces)
gui_acquire_lock() {
  local lockfile="${LOCK_FILE:-${TMP_DIR}/gui.lock}"
  local timeout=5

  # Symlink Poisoning Prevention
  if [[ -L "$lockfile" ]]; then
    log_error "SEC" "gui lockfile is a symlink: $lockfile. Aborting."
    return 1
  fi

  mkdir -p "$(dirname -- "$lockfile")" 2>/dev/null || true

  # Associating file descriptor 8 with the .lock file for kernel control
  exec 8>"$lockfile"
  if flock -x -w "$timeout" 8; then
    return 0
  else
    log_error "GUILOCK" "Could not acquire exclusive lock on $lockfile within $timeout seconds"
    exec 8>&- 2>/dev/null || true
    return 1
  fi
}

gui_release_lock() {
  local lockfile="${LOCK_FILE:-${TMP_DIR}/gui.lock}"
  if [[ -L "$lockfile" ]]; then
    log_error "SEC" "gui lockfile is a symlink during release: $lockfile. Aborting."
    return 1
  fi
  # Closing the file descriptor to force automatic release of the system lock
  exec 8>&- 2>/dev/null || true
  return 0
}

# Asynchronous handling: checks the status of the .pending marker, prevents deadlocks, and exports the update tag.
check_pending_marker() {
  local active_conv pending_file now mtime diff
  active_conv="$(read_config_or_default "${CURRENT_CONV_FILE:-${CFG_DIR}/current-conv}" "conv-1.txt")"
  active_conv="$(sanitize_param "$active_conv")"
  
  THEME_REFRESH_TAG=""
  PENDING_STATUS_HTML=""
  export THEME_REFRESH_TAG PENDING_STATUS_HTML

  [[ -z "$active_conv" ]] && return 0
  pending_file="${TMP_DIR}/session-${active_conv}.pending"

  if [[ -f "$pending_file" ]]; then
    # Prevent Symlink Poisoning on the Marker File
    if [[ -L "$pending_file" ]]; then
      log_error "SEC" "pending marker is a symlink: $pending_file. Removing and aborting."
      rm -f "$pending_file" 2>/dev/null || true
      return 0
    fi

    now="$(date +%s)"
    case "$(uname 2>/dev/null || echo Linux)" in
      Darwin) mtime="$(stat -f %m "$pending_file" 2>/dev/null || echo 0)" ;;
      *) mtime="$(stat -c %Y "$pending_file" 2>/dev/null || echo 0)" ;;
    esac

    diff=$((now - mtime))
    if (( diff > 90 )); then
      # Deadlock Prevention: The marker is orphaned or the server has crashed. Remove and report.
      rm -f "$pending_file" 2>/dev/null || true
      log_warn "CGI" "Pending marker for $active_conv timed out after ${diff}s. Forced removal."
      PENDING_STATUS_HTML="<div class=\"message system-message\"><strong>System:</strong> Generazione fallita o timeout superato.</div>"
      export PENDING_STATUS_HTML
    else
      # Background process is running normally: enable HTTP refresh and show indicator
      THEME_REFRESH_TAG='<meta http-equiv="refresh" content="3">'
      PENDING_STATUS_HTML="<div class=\"message system-message\"><strong>System:</strong> Generazione della risposta in corso...</div>"
      export THEME_REFRESH_TAG PENDING_STATUS_HTML
    fi
  fi
}

# Anti-DoS: Checks whether active valid processing is in progress to prevent overlapping concurrent requests.
is_generation_in_progress() {
  local active_conv pending_file
  active_conv="$(read_config_or_default "${CURRENT_CONV_FILE:-${CFG_DIR}/current-conv}" "conv-1.txt")"
  active_conv="$(sanitize_param "$active_conv")"
  [[ -z "$active_conv" ]] && return 1
  pending_file="${TMP_DIR}/session-${active_conv}.pending"
  
  if [[ -f "$pending_file" ]]; then
    local now mtime diff
    now="$(date +%s)"
    case "$(uname 2>/dev/null || echo Linux)" in
      Darwin) mtime="$(stat -f %m "$pending_file" 2>/dev/null || echo 0)" ;;
      *) mtime="$(stat -c %Y "$pending_file" 2>/dev/null || echo 0)" ;;
    esac
    diff=$((now - mtime))
    if (( diff <= 90 )); then
      return 0 # Active generation in progress
    else
      rm -f "$pending_file" 2>/dev/null || true
    fi
  fi
  return 1 # Free for sending
}
