#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM+ — Bash-first wrapper for the LLM
# File: extras/ui/gui-env.sh
# Extra: GUI-CGI Environment layer
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Centralized error / logging / diagnostics layer and runtime environment.
# This file is intended to be sourced by all GUI scripts (CGI and CLI).

# Prevent double-sourcing robustly by checking function declaration
if declare -f gui_env_init >/dev/null 2>&1; then
  return 0 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Basic helpers (timestamp, safe printf)
# ---------------------------------------------------------------------------
_now_iso() {
  if command -v date >/dev/null 2>&1; then
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  else
    printf '%sZ' "$(date +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || printf '%s' "$(date 2>/dev/null)")"
  fi
}

_safe_printf() {
  printf '%s' "$1"
}

# ---------------------------------------------------------------------------
# Robust PS4: include timestamp and script name; avoid unbound-variable with set -u
# ---------------------------------------------------------------------------
{
  _ps4_src="${BASH_SOURCE[0]:-$0}"
  _ps4_name="${_ps4_src##*/}"
  export PS4='+[$(_now_iso)] '"${_ps4_name}"':${LINENO}: '
  unset _ps4_src _ps4_name
} 2>/dev/null || true

# ---------------------------------------------------------------------------
# UI_ROOT placeholder (caller may set before sourcing)
# ---------------------------------------------------------------------------
if [[ -z "${UI_ROOT:-}" ]]; then
  # Safe autoresolution based on the real path of gui-env.sh
  UI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
  export UI_ROOT
fi

# Centralized Single Source of Truth for runtime variables and safe fallbacks
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
: "${DEFAULT_MODEL_FILE:=${CFG_DIR}/default-model}"
: "${DEFAULT_PROVIDER_FILE:=${CFG_DIR}/default-provider}"
: "${API_KEY_FILE:=${CFG_DIR}/api-key}"
: "${BASH4LLM_CMD:=}"
: "${conv_default:=conv-1.txt}"

# ---------------------------------------------------------------------------
# Structured logging primitives (server vs error logs)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Log rotation helper (centralized)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Fatal helpers
# ---------------------------------------------------------------------------
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
  printf '<p>An internal server error occurred. The administrator has been notified.</p>'
  printf '</body></html>\n'
  exec 2>&2 || true
  exit "$rc"
}

# ---------------------------------------------------------------------------
# Safe path canonicalization and verification helpers
# ---------------------------------------------------------------------------
_canonical_path() {
  local target="$1"
  if [[ -z "$target" ]]; then return 1; fi
  if command -v readlink >/dev/null 2>&1; then
    readlink -f -- "$target" 2>/dev/null || printf '%s' "$target"
  else
    local parent real_parent bname
    if [[ -d "$target" ]]; then
      (cd -- "$target" 2>/dev/null && pwd -P) || printf '%s' "$target"
    else
      parent="$(dirname -- "$target")"
      bname="$(basename -- "$target")"
      real_parent="$(cd -- "$parent" 2>/dev/null && pwd -P || printf '%s' "$parent")"
      printf '%s/%s' "${real_parent%/}" "$bname"
    fi
  fi
}

path_within_ui_root() {
  local p="$1"
  if [[ -z "${UI_ROOT:-}" ]]; then
    return 0
  fi
  local p_real root_real
  p_real="$(_canonical_path "$p")"
  root_real="$(_canonical_path "$UI_ROOT")"

  case "$p_real" in
    "$root_real"/*|"$root_real") return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Sanitization and parsing helpers (central)
# ---------------------------------------------------------------------------
url_decode() {
  local s="$1"
  s="${s//+/ }"
  printf '%b\n' "${s//%/\\x}" 2>/dev/null || printf '%s\n' "$s"
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
  # Strictly alphanumeric, dashes, and underscores. Rejects all folder navigation, LFI, and Path Traversal.
  if [[ "$name" =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)?$ ]]; then
    return 0
  else
    return 1
  fi
}

read_post_body() {
  local max="${1:-65536}"
  local ctlen="${CONTENT_LENGTH:-0}"
  if [[ -n "$ctlen" && "$ctlen" -gt "$max" ]]; then
    log_warn "CGI" "POST body too large: ${ctlen} > ${max}"
    dd bs=1 count="$max" 2>/dev/null || true
    return 1
  fi
  if [ -n "${CONTENT_LENGTH:-}" ]; then
    dd bs=1 count="${CONTENT_LENGTH}" 2>/dev/null || true
  else
    head -c "$max"
  fi
}

parse_form_field() {
  local key="$1"
  local body
  body="$(cat -)"
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

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# HTTP helpers (minimal, safe)
# ---------------------------------------------------------------------------
print_http_header() {
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
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

print_http_redirect() {
  local loc="$1"
  printf 'Status: 303 See Other\r\n'
  printf 'Location: %s\r\n' "$loc"
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf '\r\n'
  printf '<html><body>See <a href="%s">%s</a></body></html>' "$(printf '%s' "$loc" | sed -e 's/&/\&amp;/g')" "$(printf '%s' "$loc" | sed -e 's/&/\&amp;/g')"
}

# ---------------------------------------------------------------------------
# Mode detection helpers
# ---------------------------------------------------------------------------
is_cgi_mode() {
  if [[ -n "${REQUEST_METHOD:-}" || -n "${GATEWAY_INTERFACE:-}" ]]; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Canonicalize and validate UI_ROOT
# ---------------------------------------------------------------------------
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
          log_error "INIT" "UI_ROOT ($ui_real) is not within the trusted application base ($env_dir)"
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

# ---------------------------------------------------------------------------
# Ensure logs directory and error log exist with safe perms
# ---------------------------------------------------------------------------
ensure_logs_dir() {
  if [[ -z "${UI_ROOT:-}" ]]; then
    log_error "INIT" "UI_ROOT not set; cannot create logs"
    return 1
  fi

  mkdir -p -- "$LOG_DIR" 2>/dev/null || true
  chmod 700 -- "$LOG_DIR" 2>/dev/null || true

  if [[ ! -f "$SERVER_LOG" ]]; then
    : >"$SERVER_LOG" 2>/dev/null || {
      log_error "INIT" "cannot create SERVER_LOG: $SERVER_LOG"
      return 1
    }
  fi
  chmod 600 -- "$SERVER_LOG" 2>/dev/null || true

  if [[ ! -f "$ERROR_LOG" ]]; then
    : >"$ERROR_LOG" 2>/dev/null || {
      log_error "INIT" "cannot create ERROR_LOG: $ERROR_LOG"
      return 1
    }
  fi
  chmod 600 -- "$ERROR_LOG" 2>/dev/null || true

  return 0
}

# ---------------------------------------------------------------------------
# Exit hooks registry and on-exit handler
# ---------------------------------------------------------------------------
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
  log_info "EXIT" "gui_env_on_exit executed"
  return 0
}

# ---------------------------------------------------------------------------
# Trap installation (safe, idempotent)
# ---------------------------------------------------------------------------
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
      cgi_fatal "$rc" "Uncaught error in CGI"
    else
      fatal "$rc" "Uncaught error in CLI"
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
        cgi_fatal "$rc" "Script exited with non-zero status"
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

# ---------------------------------------------------------------------------
# Convenience initializer
# ---------------------------------------------------------------------------
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
      log_warn "INIT" "Failed to redirect stderr to $ERROR_LOG"
    fi
  fi

  return 0
}

# ---------------------------------------------------------------------------
# env_detect
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# env_prepare_runtime
# ---------------------------------------------------------------------------
env_prepare_runtime() {
  : "${UI_ROOT:=${PWD}}"
  : "${TMP_DIR:=${UI_ROOT%/}/tmp}"
  : "${CFG_DIR:=${UI_ROOT%/}/config}"
  : "${BOOTSTRAP_LOCK:=${TMP_DIR%/}/bootstrap.lock}"
  : "${BASH_PATH:=$(command -v bash 2>/dev/null || true)}"
  : "${INSTALL_MODE:=0}"

  mkdir -p "$TMP_DIR" 2>/dev/null || {
    log_error "GUIIO" "Cannot create TMP_DIR: $TMP_DIR"
    return 1
  }

  local tmp_test
  if ! tmp_test="$(portable_mktemp "${TMP_DIR%/}" ".tmp.XXXXXX" 2>/dev/null || true)"; then
    log_error "GUIIO" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; aborting env_prepare_runtime"
    return 1
  else
    rm -f -- "$tmp_test" 2>/dev/null || true
  fi
  
  : "${MAX_PROMPT_CHARS:=4096}"
  : "${MAX_RESPONSE_CHARS:=8192}"
  : "${MAX_TOKENS:=2048}"
  : "${PROVIDER_CACHE_FILE:=${CFG_DIR%/}/providers.txt}"
  : "${PROVIDER_MODELS_DIR:=${CFG_DIR%/}/models}"
  export MAX_PROMPT_CHARS MAX_RESPONSE_CHARS MAX_TOKENS PROVIDER_CACHE_FILE PROVIDER_MODELS_DIR

  mkdir -p "${TMP_DIR%/}" "${CFG_DIR%/}" "${UI_ROOT%/}/bin" 2>/dev/null || true
  chmod 700 "${TMP_DIR%/}" "${CFG_DIR%/}" "${UI_ROOT%/}/bin" 2>/dev/null || true

  if command -v stat >/dev/null 2>&1; then
    _tmp_owner="$(stat -c '%U:%G' "${TMP_DIR%/}" 2>/dev/null || true)"
    _cfg_owner="$(stat -c '%U:%G' "${CFG_DIR%/}" 2>/dev/null || true)"
    log_info "ENV" "TMP_DIR owner: ${_tmp_owner:-<unknown>}, CFG_DIR owner: ${_cfg_owner:-<unknown>}"
  fi

  local bash4llm_real bash4llm_shadow BIN_DIR wrapper tmp_shadow rc real_hash shadow_hash
  bash4llm_shadow="/data/data/com.termux/files/usr/bin/bash4llm"

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
      log_info "ENV" "Found local bash4llm candidate: $bash4llm_real"
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
        log_info "ENV" "Runtime mode: using persisted BASH4LLM_CMD=${BASH4LLM_CMD}"
        return 0
      else
        log_warn "ENV" "Persisted bash4llm-path exists but is not executable or empty; ignoring in runtime"
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
        log_info "ENV" "Runtime mode (Termux): using existing wrapper $wrapper"
        return 0
      fi
      if [[ -n "$bash4llm_real" && -x "$bash4llm_real" ]]; then
        BASH4LLM_CMD="$bash4llm_real"
        export BASH4LLM_CMD
        log_info "ENV" "Runtime mode (Termux): no wrapper found, using local repo binary $bash4llm_real"
        return 0
      fi
      log_warn "ENV" "Runtime mode (Termux): no wrapper and no local repo binary found; leaving BASH4LLM_CMD unset"
      return 0
    fi

    if [[ -n "$bash4llm_real" && -x "$bash4llm_real" ]]; then
      BASH4LLM_CMD="$bash4llm_real"
      export BASH4LLM_CMD
      log_info "ENV" "Runtime mode (non-Termux): using local repo binary $bash4llm_real"
      return 0
    fi

    log_warn "ENV" "Runtime mode: no bash4llm resolved (no persisted path, no wrapper, no local binary)"
    return 0
  fi

  if [[ "${IS_TERMUX:-0}" -ne 1 ]]; then
    if [[ -n "$bash4llm_real" && -x "$bash4llm_real" ]]; then
      mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
      if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" ]]; then
        local tmp_path line_count
        tmp_path="$(portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}")" || tmp_path="${CFG_DIR%/}/bash4llm-path.tmp"
        if printf '%s\n' "$bash4llm_real" >"$tmp_path" 2>/dev/null; then
          line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
          if [[ "$line_count" -eq 1 ]]; then
            mv -f -- "$tmp_path" "${CFG_DIR%/}/bash4llm-path"
            chmod 600 "${CFG_DIR%/}/bash4llm-path" 2>/dev/null || true
            log_info "ENV" "INSTALL_MODE: persisted bash4llm-path -> $bash4llm_real"
            BASH4LLM_CMD="$bash4llm_real"
            export BASH4LLM_CMD
            return 0
          else
            log_warn "ENV" "INSTALL_MODE: refusing to persist bash4llm-path: temp file contains ${line_count} non-empty lines"
            rm -f -- "$tmp_path" 2>/dev/null || true
            return 0
          fi
        else
          log_warn "ENV" "INSTALL_MODE: failed to write temporary bash4llm-path at $tmp_path"
          rm -f -- "$tmp_path" 2>/dev/null || true
          return 0
        fi
      else
        log_warn "ENV" "INSTALL_MODE: CFG_DIR not writable; cannot persist bash4llm-path"
        return 0
      fi
    else
      log_warn "ENV" "INSTALL_MODE: no local repo binary found to persist on non-Termux"
      return 0
    fi
  fi

  ensure_tmpdir || { log_warn "ENV" "ensure_tmpdir failed; skipping Termux shadow/wrapper update"; return 0; }
  if ! command -v flock >/dev/null 2>&1; then
    log_warn "ENV" "flock not available; skipping Termux shadow/wrapper update"
    return 0
  fi

  exec 9>"${BOOTSTRAP_LOCK}" 2>/dev/null || { log_warn "ENV" "cannot open BOOTSTRAP_LOCK"; return 0; }
  if ! flock -x -w 5 9; then
    exec 9>&- 2>/dev/null || true
    log_warn "ENV" "Could not acquire bootstrap lock; skipping Termux shadow/wrapper update"
    return 0
  fi

  _release_lock() {
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
  }

  real_hash="$(compute_hash "$bash4llm_real" 2>/dev/null || true)"
  shadow_hash="$(compute_hash "$bash4llm_shadow" 2>/dev/null || true)"
  rc=1

  if [[ -z "$shadow_hash" || "$real_hash" != "$shadow_hash" ]]; then
    tmp_shadow="$(portable_mktemp "$TMP_DIR" "bash4llm-shadow.XXXXXX")" || tmp_shadow=""
    if [[ -n "$tmp_shadow" ]]; then
      if ! cp -f -- "$bash4llm_real" "$tmp_shadow" 2>/dev/null; then
        log_warn "ENV" "Failed to copy real bash4llm to tmp shadow"
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        _release_lock
        return 0
      fi

      if [[ -n "${BASH_PATH:-}" && -x "$BASH_PATH" ]]; then
        if head -n1 "$tmp_shadow" 2>/dev/null | grep -qE '^#!'; then
          sed -i '1s|^#!.*|#!'"$BASH_PATH"'|' "$tmp_shadow" 2>/dev/null || true
        fi
      fi

      if ! mv -f -- "$tmp_shadow" "$bash4llm_shadow" 2>/dev/null; then
        log_warn "ENV" "Failed to move tmp shadow into place"
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        _release_lock
        return 0
      fi
      rc=0
    else
      log_warn "ENV" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; refusing to perform direct copy to $bash4llm_shadow in INSTALL_MODE"
      _release_lock
      return 0
    fi

    if (( rc != 0 )); then
      log_warn "ENV" "Shadow update returned non-zero rc"
      _release_lock
      return 0
    fi

    chmod 750 "$bash4llm_shadow" 2>/dev/null || true
    shadow_hash="$(compute_hash "$bash4llm_shadow" 2>/dev/null || true)"
    log_info "ENV" "INSTALL_MODE: Updated bash4llm shadow at $bash4llm_shadow"
  else
    log_info "ENV" "INSTALL_MODE: bash4llm shadow already up-to-date"
  fi

  if [[ -z "${BASH_PATH:-}" || ! -x "$BASH_PATH" ]]; then
    _release_lock
    log_warn "ENV" "BASH_PATH not resolved or not executable; skipping wrapper creation"
    return 0
  fi

  BIN_DIR="${UI_ROOT%/}/bin"
  mkdir -p "$BIN_DIR" 2>/dev/null || true
  chmod 700 "$BIN_DIR" 2>/dev/null || true
  wrapper="$BIN_DIR/bash4llm-wrapper"

  local tmp_wrapper new_wrapper_hash existing_wrapper_hash wrapper_hash
  tmp_wrapper="$(portable_mktemp "$TMP_DIR" "wrapper.XXXXXX")" || tmp_wrapper=""
  if [[ -n "$tmp_wrapper" ]]; then
    printf '%s\n' "#!$BASH_PATH" "exec \"$BASH_PATH\" \"$bash4llm_shadow\" \"\$@\"" >"$tmp_wrapper" 2>/dev/null || {
      log_warn "ENV" "Failed to write tmp wrapper"
      rm -f -- "$tmp_wrapper" 2>/dev/null || true
      _release_lock
      return 0
    }

    if [[ -f "$wrapper" ]]; then
      new_wrapper_hash="$(compute_hash "$tmp_wrapper" 2>/dev/null || true)"
      existing_wrapper_hash="$(compute_hash "$wrapper" 2>/dev/null || true)"
      if [[ -n "$new_wrapper_hash" && -n "$existing_wrapper_hash" && "$new_wrapper_hash" == "$existing_wrapper_hash" ]]; then
        rm -f -- "$tmp_wrapper" 2>/dev/null || true
        rc=0
      else
        if ! mv -f -- "$tmp_wrapper" "$wrapper" 2>/dev/null; then
          log_warn "ENV" "Failed to move new wrapper into place"
          rm -f -- "$tmp_wrapper" 2>/dev/null || true
          _release_lock
          return 0
        fi
        rc=0
      fi
    else
      if ! mv -f -- "$tmp_wrapper" "$wrapper" 2>/dev/null; then
        log_warn "ENV" "Failed to move wrapper into place"
        rm -f -- "$tmp_wrapper" 2>/dev/null || true
        _release_lock
        return 0
      fi
      rc=0
    fi
  else
    log_warn "ENV" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; refusing to write wrapper directly in INSTALL_MODE"
    _release_lock
    return 0
  fi

  chmod 750 "$wrapper" 2>/dev/null || true
  wrapper_hash="$(compute_hash "$wrapper" 2>/dev/null || true)"
  _release_lock

  if [[ -x "$wrapper" ]]; then
    BASH4LLM_CMD="$wrapper"
    export BASH4LLM_CMD
    PATH="$BIN_DIR:${PATH:-}"
    export PATH
    log_info "ENV" "INSTALL_MODE: Termux wrapper ensured at $wrapper (hash: ${wrapper_hash:-<none>})"
  else
    log_warn "ENV" "Wrapper not executable; BASH4LLM_CMD not set to wrapper"
  fi

  if [[ -n "${CFG_DIR:-}" ]]; then
    mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
    if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" && -n "${wrapper:-}" && -x "$wrapper" ]]; then
      local tmp_path line_count
      tmp_path="$(portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}")" || tmp_path="${CFG_DIR%/}/bash4llm-path.tmp"
      if printf '%s\n' "$wrapper" >"$tmp_path" 2>/dev/null; then
        line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
        if [[ "$line_count" -eq 1 ]]; then
          mv -f -- "$tmp_path" "${CFG_DIR%/}/bash4llm-path"
          chmod 600 "${CFG_DIR%/}/bash4llm-path" 2>/dev/null || true
          log_info "ENV" "INSTALL_MODE: Persisted bash4llm-path to ${CFG_DIR%/}/bash4llm-path -> $wrapper"
        else
          log_warn "ENV" "INSTALL_MODE: Refusing to persist bash4llm-path: temp file contains ${line_count} non-empty lines (expected 1); tmp: $tmp_path"
          rm -f -- "$tmp_path" 2>/dev/null || true
        fi
      else
        log_warn "ENV" "INSTALL_MODE: Failed to write temporary bash4llm-path at $tmp_path; skipping persist"
        rm -f -- "$tmp_path" 2>/dev/null || true
      fi
    else
      log_warn "ENV" "INSTALL_MODE: CFG_DIR not writable or wrapper unset/not executable; skipping persist of bash4llm-path"
    fi
  fi

  return 0
}

# ---------------------------------------------------------------------------
# env_after_bash4llm_resolved
# ---------------------------------------------------------------------------
env_after_bash4llm_resolved() {
  if [[ -n "${BASH4LLM_CMD:-}" && -x "${BASH4LLM_CMD}" ]]; then
    local prov_count
    prov_count="$("${BASH4LLM_CMD}" --list-providers-raw 2>/dev/null | wc -l 2>/dev/null || true)"
    log_info "ENV" "bash4llm resolved: ${BASH4LLM_CMD} (providers: ${prov_count:-0})"
  else
    log_warn "ENV" "bash4llm not resolved in env_after_bash4llm_resolved"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Utility: ensure_tmpdir, portable_mktemp, atomic_write, compute_hash, same_filesystem
# ---------------------------------------------------------------------------
ensure_tmpdir() {
  if [[ -e "$TMP_DIR" && ! -d "$TMP_DIR" ]]; then
    log_error "GUIIO" "TMP_DIR exists and is not a directory: $TMP_DIR"
    return 1
  fi
  if [[ ! -d "$TMP_DIR" ]]; then
    mkdir -p "$TMP_DIR" 2>/dev/null || true
    chmod 700 "$TMP_DIR" 2>/dev/null || true
  fi
  if [[ ! -w "$TMP_DIR" ]]; then
    log_error "GUIIO" "TMP_DIR $TMP_DIR not writable"
    return 1
  fi
  return 0
}

portable_mktemp() {
  local dir="${1:-}" template="${2:-.tmp.XXXXXX}"
  local dir_real tmp candidate base i rand

  if [[ -z "$dir" ]]; then
    log_error "GUIIO" "portable_mktemp called with empty dir"
    return 1
  fi

  mkdir -p -- "$dir" 2>/dev/null || { log_error "GUIIO" "portable_mktemp: cannot create dir: $dir"; return 1; }
  dir_real="$(cd -- "$dir" 2>/dev/null && pwd -P || true)"
  if [[ -z "$dir_real" || ! -d "$dir_real" || ! -w "$dir_real" ]]; then
    log_error "GUIIO" "portable_mktemp: dir invalid or not writable: ${dir:-<unset>} -> ${dir_real:-<unresolved>}"
    return 1
  fi

  if [[ -n "${TMP_DIR:-}" ]]; then
    case "$dir_real" in
      "$TMP_DIR"/*|"$TMP_DIR") ;;
      *)
        log_error "GUIIO" "portable_mktemp: dir ${dir_real} is not inside TMP_DIR (${TMP_DIR:-<unset>})"
        return 1
        ;;
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

  log_error "GUIIO" "portable_mktemp failed to create temp file in $dir_real"
  return 1
}

atomic_write() {
  local dest="$1" content="${2:-}" dest_dir tmp

  if [[ -z "${dest:-}" ]]; then
    log_error "GUIIO" "atomic_write called without destination"
    return 1
  fi

  dest_dir="$(dirname -- "$dest")"

  if declare -f path_within_ui_root >/dev/null 2>&1 && [[ -n "${UI_ROOT:-}" ]]; then
    if ! path_within_ui_root "$dest"; then
      log_error "GUIIO" "atomic_write: refusing to write outside UI_ROOT: $dest"
      return 1
    fi
  fi

  ensure_tmpdir || return 1

  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(portable_mktemp "$TMP_DIR" "atomic.XXXXXX")"; then
    :
  else
    tmp="$(portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}" "atomic.XXXXXX")"
  fi

  if [[ -z "${tmp:-}" ]]; then
    log_error "GUIIO" "atomic_write: portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}"
    return 1
  fi

  umask 077
  printf '%s' "$content" >"$tmp" || { log_error "GUIIO" "Failed to write to temp file $tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }

  if command -v sync >/dev/null 2>&1; then sync || true; fi

  mv -f "$tmp" "$dest" || { log_error "GUIIO" "mv failed in atomic_write from $tmp to $dest"; rm -f "$tmp" 2>/dev/null || true; return 1; }

  chmod 600 "$dest" 2>/dev/null || true
  return 0
}

atomic_append_conv() {
  local conv_file="$1" append_text="$2" tmp dest_dir lockfile lockfd
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

  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(portable_mktemp "$TMP_DIR" "conv.XXXXXX")"; then
    :
  else
    tmp="$(portable_mktemp "$dest_dir" "conv.XXXXXX")"
  fi
  if [[ -f "$conv_file" ]]; then
    cat "$conv_file" >"$tmp" 2>/dev/null || { log_error "GUIIO" "Failed to copy existing conversation to tmp"; rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  else
    : >"$tmp"
  fi
  printf '%s\n' "$append_text" >>"$tmp" || { log_error "GUIIO" "Failed to append text to tmp"; rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  mv -f "$tmp" "$conv_file" || { log_error "GUIIO" "mv failed in atomic_append_conv"; rm -f "$tmp" 2>/dev/null || true; [[ -n "$lockfd" ]] && { flock -u "$lockfd" 2>/dev/null || true; exec {lockfd}>&- 2>/dev/null || true; }; return 1; }
  chmod 600 "$conv_file" || true

  if [[ -n "$lockfd" ]]; then
    flock -u "$lockfd" 2>/dev/null || true
    exec {lockfd}>&- 2>/dev/null || true
  fi
  return 0
}

atomic_append_conv_in_uiroot() {
  local convfile="$1"
  if [[ -z "$convfile" ]]; then return 1; fi
  local dir tmpf
  dir="$(dirname -- "$convfile")"
  mkdir -p -- "$dir" 2>/dev/null || true

  tmpf="$(portable_mktemp "${TMP_DIR:-${UI_ROOT%/}/tmp}" "conv.XXXXXX")" || return 1

  if [[ -f "$convfile" ]]; then
    cp -a -- "$convfile" "$tmpf" || { rm -f -- "$tmpf" 2>/dev/null || true; return 1; }
  else
    : >"$tmpf"
  fi

  cat >> "$tmpf"

  mv -f -- "$tmpf" "$convfile" || { rm -f -- "$tmpf" 2>/dev/null || true; return 1; }
  chmod 600 "$convfile" || true
  return 0
}

compute_hash() {
  local file="$1" tmpf
  [[ -f "$file" ]] || { printf ''; return 0; }
  tmpf="$(portable_mktemp "$TMP_DIR" "hash.XXXXXX")" || { printf ''; return 0; }
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

# ---------------------------------------------------------------------------
# Health and diagnostics helpers
# ---------------------------------------------------------------------------
gui_env_health_check() {
  local ok=0
  if ! ensure_tmpdir; then
    log_warn "HEALTH" "TMP_DIR check failed: ${TMP_DIR:-<unset>}"
    ok=1
  fi
  if [[ -z "${LOG_DIR:-}" || ! -d "${LOG_DIR:-}" || ! -w "${LOG_DIR:-}" ]]; then
    log_warn "HEALTH" "LOG_DIR not writable: ${LOG_DIR:-<unset>}"
    ok=1
  fi
  if ! command -v flock >/dev/null 2>&1; then
    log_warn "HEALTH" "flock not available"
    ok=1
  fi
  if [[ -n "${BASH4LLM_CMD:-}" && ! -x "${BASH4LLM_CMD}" ]]; then
    log_warn "HEALTH" "BASH4LLM_CMD set but not executable: ${BASH4LLM_CMD:-<unset>}"
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

# ---------------------------------------------------------------------------
# Configuration Getters/Setters and Shared State Getters
# ---------------------------------------------------------------------------
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
      log_error "INIT" "Failed to create directory: $d"
      return 1
    }
    chmod 700 -- "$d" 2>/dev/null || true
  done

  : "${DEFAULT_MODEL_FILE:=${CFG_DIR}/default-model}"
  : "${DEFAULT_PROVIDER_FILE:=${CFG_DIR}/default-provider}"
  : "${CURRENT_CONV_FILE:=${CFG_DIR}/current-conv}"
  : "${LANG_CURRENT_FILE:=${CFG_DIR}/current-lang}"
  : "${THEME_CURRENT_FILE:=${CFG_DIR}/current-theme}"
  : "${API_KEY_FILE:=${CFG_DIR}/api-key}"

  return 0
}

ensure_sh_executables() {
  local target_dir="${1:-}"
  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    log_warn "ENV" "ensure_sh_executables: target_dir invalid or missing"
    return 1
  fi
  
  if declare -f path_within_ui_root >/dev/null 2>&1; then
    if ! path_within_ui_root "$target_dir"; then
      log_error "ENV" "ensure_sh_executables: attempt to access external path"
      return 1
    fi
  fi

  find "$target_dir" -type f -name "*.sh" -exec chmod 750 {} + 2>/dev/null || true
  return 0
}

remove_unnecessary_symlinks() {
  local target_dir="${1:-}"
  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    log_warn "ENV" "remove_unnecessary_symlinks: target_dir invalid or missing"
    return 1
  fi

  if declare -f path_within_ui_root >/dev/null 2>&1; then
    if ! path_within_ui_root "$target_dir"; then
      log_error "ENV" "remove_unnecessary_symlinks: attempt to access external path"
      return 1
    fi
  fi

  find "$target_dir" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  return 0
}

# ---------------------------------------------------------------------------
# Global Config default loader / setter
# ---------------------------------------------------------------------------
ensure_config_defaults() {
  : "${CFG_DIR:=${UI_ROOT}/config}"
  : "${CONV_DIR:=${UI_ROOT}/conversations}"
  
  local default_model_file="${CFG_DIR}/default-model"
  local default_provider_file="${CFG_DIR}/default-provider"
  local current_conv_file="${CFG_DIR}/current-conv"
  local lang_current_file="${CFG_DIR}/current-lang"
  local theme_current_file="${CFG_DIR}/current-theme"
  local use_sessions_file="${CFG_DIR}/use-sessions"
  local conv_default="conv-1.txt"

  if [[ ! -f "$default_model_file" ]]; then
    mkdir -p "$(dirname "$default_model_file")" 2>/dev/null || true
    : > "$default_model_file"
    chmod 600 "$default_model_file" 2>/dev/null || true
  fi

  if [[ ! -f "$default_provider_file" ]]; then
    mkdir -p "$(dirname "$default_provider_file")" 2>/dev/null || true
    printf 'groq\n' > "$default_provider_file" 2>/dev/null || true
    chmod 600 "$default_provider_file" 2>/dev/null || true
  fi

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

  # Seed the default use-sessions configuration as "enabled" to ensure immediate log writes
  if [[ ! -f "$use_sessions_file" ]]; then
    mkdir -p "$(dirname "$use_sessions_file")" 2>/dev/null || true
    printf 'enabled\n' > "$use_sessions_file" 2>/dev/null || true
    chmod 600 "$use_sessions_file" 2>/dev/null || true
  fi

  local conv
  conv="$(read_config_or_default "$current_conv_file" "$conv_default")"
  conv="$(sanitize_param "$conv")"
  
  if ! validate_name "$conv"; then
    conv="$conv_default"
    atomic_write "$current_conv_file" "$conv" || true
  fi

  # conversations/ folder is deprecated but initialized for backward compatibility
  if [[ ! -f "$CONV_DIR/$conv" ]]; then
    atomic_write "$CONV_DIR/$conv" "" || true
  fi

  return 0
}

get_default_provider() {
  read_config_or_default "${DEFAULT_PROVIDER_FILE:-${CFG_DIR}/default-provider}" "groq"
}

get_default_model() {
  read_config_or_default "${DEFAULT_MODEL_FILE:-${CFG_DIR}/default-model}" ""
}

read_api_key_file() {
  read_config_or_default "${API_KEY_FILE:-${CFG_DIR}/api-key}" ""
}

save_api_key_file() {
  atomic_write "${API_KEY_FILE:-${CFG_DIR}/api-key}" "$1"
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

export_api_key_for_provider() {
  local provider="$1"
  if [[ -z "$provider" ]]; then return 1; fi
  local key
  key="$(read_api_key_file)"
  if [[ -n "$key" ]]; then
    local env_var
    env_var="$(printf '%s' "$provider" | tr '[:lower:]' '[:upper:]')_API_KEY"
    export "$env_var"="$key"
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

# ---------------------------------------------------------------------------
# NDJSON-based Session Conversation Block Builder (SSOT Compliant)
# ---------------------------------------------------------------------------
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
  temp_json="$(portable_mktemp "$TMP_DIR" "hconv.XXXXXX")" || return 1

  local is_full
  is_full="$(get_query_param "full_history" 2>/dev/null || printf '0')"
  local window_size=20
  if [[ "$is_full" == "1" ]]; then
    window_size=99999
  fi
  
  # Delegate directly to core's session retrieval logic (SSOT)
  if declare -f session_read_window >/dev/null 2>&1; then
    session_read_window "$active_conv" "$window_size" "$temp_json" >/dev/null 2>&1
  else
    # Perfect isolated fallback mapping of NDJSON records directly with jq
    local session_file="${BASH4LLM_DIR}/history/sessions/${active_conv}.ndjson"
    if [[ -f "$session_file" ]]; then
      printf '{"messages":[' > "$temp_json"
      local first=1 line role content r_json c_json
      while IFS= read -r line || [[ -n "$line" ]]; do
        if printf '%s\n' "$line" | jq -e . >/dev/null 2>&1; then
          role="$(printf '%s\n' "$line" | jq -r '.role // "user"')"
          content="$(printf '%s\n' "$line" | jq -r '.content // ""')"
          r_json="$(jq -R -c . <<< "$role")"
          c_json="$(jq -R -s . <<< "$content")"
          c_json="${c_json%$'\n'}"
          if [[ "$first" -eq 0 ]]; then printf ',' >> "$temp_json"; fi
          printf '{"role":%s,"content":%s}' "$r_json" "$c_json" >> "$temp_json"
          first=0
        fi
      done < <(tail -n "$window_size" "$session_file" 2>/dev/null)
      printf ']}' >> "$temp_json"
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
  if [[ "$is_full" != "1" && "$total_lines" -gt 20 ]]; then
    local current_page current_conv_name
    current_page="$(get_query_param "page" 2>/dev/null || printf 'main')"
    current_conv_name="$(read_config_or_default "${CURRENT_CONV_FILE:-${CFG_DIR}/current-conv}" "conv-1.txt")"
    current_conv_name="$(sanitize_param "$current_conv_name")"
    CURRENT_CONV+="<div class=\"load-more-container\" style=\"margin: 1.5rem 0; text-align: center;\"><a class=\"btn btn-secondary\" href=\"?page=${current_page}&select_conv=${current_conv_name}&full_history=1\">Load full history (${total_lines} turns)</a></div>"$'\n'
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

# ---------------------------------------------------------------------------
# Cooperative Locking System (flock + directory lock fallback, no /tmp leaks)
# ---------------------------------------------------------------------------
acquire_lock() {
  local lockfile="${LOCK_FILE:-${TMP_DIR}/gui.lock}"
  local timeout=3
  local lockdir="${lockfile}.dir"
  local pidfile="${lockdir}/pid"
  local current_pid="${BASHPID:-$$}"

  # Exclude Termux from flock to align with core security policies
  if command -v flock >/dev/null 2>&1 && [[ -z "${TERMUX_VERSION:-}" ]]; then
    exec 8>"$lockfile" 2>/dev/null || return 1
    if flock -x -w "$timeout" 8 2>/dev/null; then
      printf '%s\n' "$current_pid" >"$lockfile" 2>/dev/null || true
      return 0
    fi
  fi

  # Safe atomic folder cooperative fallback
  local i=0
  while (( i < 30 )); do
    if mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$current_pid" > "$pidfile" 2>/dev/null || true
      return 0
    fi

    # Stale lock cleanup verification
    if [[ -f "$pidfile" ]]; then
      local lp
      lp="$(cat "$pidfile" 2>/dev/null || true)"
      if [[ -n "$lp" ]] && ! kill -0 "$lp" 2>/dev/null; then
        rm -rf "$lockdir" 2>/dev/null || true
        continue
      fi
    fi

    sleep 0.1
    i=$((i+1))
  done
  return 1
}

release_lock() {
  local lockfile="${LOCK_FILE:-${TMP_DIR}/gui.lock}"
  local lockdir="${lockfile}.dir"
  if command -v flock >/dev/null 2>&1; then
    flock -u 8 2>/dev/null || true
    exec 8>&- 2>/dev/null || true
  fi
  rm -rf "$lockdir" 2>/dev/null || true
  return 0
}
