#!/usr/bin/env bash
# =============================================================================
# Environment layer for GroqBash GUI
# File: gui-env.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
#
# Centralized error / logging / diagnostics layer and runtime environment.
# This file is intended to be sourced by all GUI scripts (CGI and CLI).
#
# Contract (short):
# - Callers should `set -euo pipefail` before sourcing this file.
# - Caller must set UI_ROOT (absolute) before calling canonicalize_ui_root()
#   or use gui_env_init MODE which will canonicalize and prepare logs.
# - All logs are written under $UI_ROOT/logs (dir perms 700, file perms 600).
# - Use log_debug|log_info|log_warn|log_error for structured logs.
# - Use fatal (CLI) or cgi_fatal (CGI) for unrecoverable errors.
#
# Security constraints:
# - No writes outside UI_ROOT except when INSTALL_MODE=1 and explicitly allowed.
# - No secrets printed to HTTP responses; detailed diagnostics only in logs.
#
# Portability:
# - Avoids GNU-only flags where possible; relies on coreutils commonly available.
# - Designed to run on Termux/Android, Linux, macOS, WSL.

# Prevent double-sourcing
: "${GUI_ENV_LOADED:=}"
if [[ -n "${GUI_ENV_LOADED:-}" ]]; then
  return 0 2>/dev/null || true
fi
GUI_ENV_LOADED=1

# -------------------------
# Basic helpers (timestamp, safe printf)
# -------------------------
_now_iso() {
  # ISO-8601 UTC timestamp (fallbacks kept minimal)
  if command -v date >/dev/null 2>&1; then
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  else
    printf '%sZ' "$(date +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || printf '%s' "$(date 2>/dev/null)")"
  fi
}

_safe_printf() {
  printf '%s' "$1"
}

# -------------------------
# PS4 for set -x traces (include UTC timestamp and script name)
# -------------------------
export PS4='+[$(_now_iso)] ${BASH_SOURCE##*/}:${LINENO}: '

# -------------------------
# UI_ROOT placeholder (caller may set before sourcing)
# -------------------------
: "${UI_ROOT:=${UI_ROOT:-}}"

# Derived variables (populated by canonicalize_ui_root)
: "${CGI_DIR:=${CGI_DIR:-}}"
: "${LOG_DIR:=${LOG_DIR:-}}"
: "${SERVER_LOG:=${SERVER_LOG:-}}"
: "${ERROR_LOG:=${ERROR_LOG:-}}"

# -------------------------
# Structured logging primitives (server vs error logs)
# -------------------------
# Log format:
#   TIMESTAMP groqbash: LEVEL: TAG: pid=PID: MESSAGE
_log_common() {
  # _log_common LEVEL TAG MSG...
  local level="$1"; shift
  local tag="$1"; shift
  local msg="$*"
  local ts pid out target_dir target_file
  ts="$(_now_iso)"
  pid="$$"
  out="${ts} groqbash: ${level}: ${tag}: pid=${pid}: ${msg}"

  # Decide destination: ERROR -> ERROR_LOG, others -> SERVER_LOG
  if [[ "${level}" == "ERROR" || "${level}" == "FATAL" || "${level}" == "CGI_FATAL" ]]; then
    target_file="${ERROR_LOG:-}"
  else
    target_file="${SERVER_LOG:-}"
  fi

  if [[ -n "${target_file:-}" ]]; then
    target_dir="$(dirname -- "$target_file" 2>/dev/null || true)"
    if [[ -n "$target_dir" ]]; then
      mkdir -p -- "$target_dir" 2>/dev/null || true
      # Append safely; best-effort (do not fail caller)
      printf '%s\n' "$out" >>"$target_file" 2>/dev/null || printf '%s\n' "$out" >&2 || true
      return 0
    fi
  fi

  # Fallback to stderr if no log path available
  printf '%s\n' "$out" >&2 || true
  return 0
}

log_debug() { _log_common "DEBUG" "${1:-DEBUG}" "${@:2}"; }
log_info()  { _log_common "INFO"  "${1:-INFO}"  "${@:2}"; }
log_warn()  { _log_common "WARN"  "${1:-WARN}"  "${@:2}"; }
log_error() { _log_common "ERROR" "${1:-ERROR}" "${@:2}"; }

# Safe append helper for other modules
safe_append_log() {
  # safe_append_log <file> <line...>
  local file="$1"; shift
  local line="$*"
  if [[ -z "$file" ]]; then return 1; fi
  mkdir -p -- "$(dirname -- "$file")" 2>/dev/null || true
  printf '%s\n' "$line" >>"$file" 2>/dev/null || printf '%s\n' "$line" >&2 || true
  return 0
}

# -------------------------
# Log rotation helper (centralized)
# -------------------------
log_rotate_if_needed() {
  # log_rotate_if_needed <file> <max_bytes>
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

# -------------------------
# Fatal helpers
# -------------------------
fatal() {
  # fatal RC MSG  -- CLI context
  local rc="${1:-1}"; shift || true
  local msg="${*:-Fatal error}"
  log_error "FATAL" "$msg"
  # Ensure stderr flushed
  exec 2>&2 || true
  exit "$rc"
}

cgi_fatal() {
  # cgi_fatal RC MSG  -- CGI context: log and emit minimal HTTP 500
  local rc="${1:-1}"; shift || true
  local msg="${*:-Server error}"
  log_error "CGI_FATAL" "$msg"

  # Emit minimal safe HTTP 500 response (no sensitive details)
  printf 'Status: 500 Internal Server Error\r\n'
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
  printf '<!doctype html><html><head><meta charset="utf-8"><title>Server Error</title></head><body>'
  printf '<h1>500 Internal Server Error</h1>'
  printf '<p>An internal server error occurred. The administrator has been notified.</p>'
  printf '</body></html>\n'
  # Ensure logs flushed
  exec 2>&2 || true
  exit "$rc"
}

# -------------------------
# HTTP helpers (minimal, safe)
# -------------------------
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

# -------------------------
# Mode detection helpers
# -------------------------
is_cgi_mode() {
  # Heuristic: presence of REQUEST_METHOD or GATEWAY_INTERFACE
  if [[ -n "${REQUEST_METHOD:-}" || -n "${GATEWAY_INTERFACE:-}" ]]; then
    return 0
  fi
  return 1
}

# -------------------------
# Canonicalize and validate UI_ROOT
# -------------------------
canonicalize_ui_root() {
  # Ensures UI_ROOT is set, exists, is a directory, not a symlink, and is inside $HOME.
  # On success: sets UI_ROOT to canonical path and exports it.
  # On failure: logs and returns non-zero.
  local orig ui_real home_real

  orig="${UI_ROOT:-}"
  if [[ -z "$orig" ]]; then
    log_error "INIT" "UI_ROOT not set"
    return 1
  fi

  # Resolve to absolute canonical path
  if command -v readlink >/dev/null 2>&1; then
    ui_real="$(readlink -f -- "$orig" 2>/dev/null || true)"
  fi
  if [[ -z "$ui_real" ]]; then
    ui_real="$(cd -- "$orig" 2>/dev/null && pwd -P || true)"
  fi
  if [[ -z "$ui_real" || ! -d "$ui_real" ]]; then
    log_error "INIT" "UI_ROOT invalid or not a directory: ${orig:-<unset>}"
    return 1
  fi

  # Disallow UI_ROOT being a symlink itself
  if [ -L "$orig" ]; then
    log_error "INIT" "UI_ROOT must not be a symlink: $orig"
    return 1
  fi

  # Ensure UI_ROOT is inside HOME (safety constraint)
  home_real="$(cd "${HOME:-/}" 2>/dev/null && pwd -P || true)"
  case "$ui_real" in
    "$home_real"/*|"$home_real") ;;
    *)
      log_error "INIT" "UI_ROOT ($ui_real) must be inside HOME ($home_real)"
      return 1
      ;;
  esac

  UI_ROOT="$ui_real"
  export UI_ROOT

  # Derived paths
  CGI_DIR="${UI_ROOT%/}/cgi-bin"
  LOG_DIR="${UI_ROOT%/}/logs"
  SERVER_LOG="${LOG_DIR%/}/server.log"
  ERROR_LOG="${LOG_DIR%/}/errors.log"
  export CGI_DIR LOG_DIR SERVER_LOG ERROR_LOG

  return 0
}

# -------------------------
# Ensure logs directory and error log exist with safe perms
# -------------------------
ensure_logs_dir() {
  # Create LOG_DIR and log files with strict perms (dir 700, files 600).
  if [[ -z "${UI_ROOT:-}" ]]; then
    log_error "INIT" "UI_ROOT not set; cannot create logs"
    return 1
  fi

  mkdir -p -- "$LOG_DIR" 2>/dev/null || true
  chmod 700 -- "$LOG_DIR" 2>/dev/null || true

  # Ensure SERVER_LOG exists
  if [[ ! -f "$SERVER_LOG" ]]; then
    : >"$SERVER_LOG" 2>/dev/null || {
      log_error "INIT" "cannot create SERVER_LOG: $SERVER_LOG"
      return 1
    }
  fi
  chmod 600 -- "$SERVER_LOG" 2>/dev/null || true

  # Ensure ERROR_LOG exists
  if [[ ! -f "$ERROR_LOG" ]]; then
    : >"$ERROR_LOG" 2>/dev/null || {
      log_error "INIT" "cannot create ERROR_LOG: $ERROR_LOG"
      return 1
    }
  fi
  chmod 600 -- "$ERROR_LOG" 2>/dev/null || true

  return 0
}

# -------------------------
# Exit hooks registry and on-exit handler
# -------------------------
_GUI_ENV_EXIT_HOOKS=()

gui_env_register_exit_hook() {
  # gui_env_register_exit_hook function_name
  local fn="$1"
  if [[ -z "$fn" ]]; then return 1; fi
  if declare -f "$fn" >/dev/null 2>&1; then
    _GUI_ENV_EXIT_HOOKS+=("$fn")
    return 0
  fi
  return 1
}

gui_env_on_exit() {
  # Run registered hooks in LIFO order, best-effort
  local i
  for (( i=${#_GUI_ENV_EXIT_HOOKS[@]}-1; i>=0; i-- )); do
    local h="${_GUI_ENV_EXIT_HOOKS[i]}"
    if declare -f "$h" >/dev/null 2>&1; then
      "$h" || true
    fi
  done
  # Write a brief exit diagnostic
  log_info "EXIT" "gui_env_on_exit executed"
  return 0
}

# -------------------------
# Trap installation (safe, idempotent)
# -------------------------
install_default_traps() {
  # install_default_traps MODE
  # MODE: "cgi" or "cli"
  local mode="${1:-}"
  if [[ -z "$mode" ]]; then
    mode="cli"
  fi

  # Guard to avoid double-install
  if [[ "${_GUI_ENV_TRAPS_INSTALLED:-}" == "1" ]]; then
    return 0
  fi
  _GUI_ENV_TRAPS_INSTALLED=1

  # Prevent recursion in trap handlers
  _GUI_ENV_TRAP_INVOKED=0

  _gui_env_err_trap() {
    local rc=$?
    if [[ "${_GUI_ENV_TRAP_INVOKED:-0}" -ne 0 ]]; then
      return 0
    fi
    _GUI_ENV_TRAP_INVOKED=1
    # Run exit hooks first (best-effort)
    gui_env_on_exit || true
    if [[ "$mode" == "cgi" ]]; then
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
    # Run exit hooks
    gui_env_on_exit || true
    if [[ "$rc" -ne 0 ]]; then
      if [[ "$mode" == "cgi" ]]; then
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

# -------------------------
# Convenience initializer
# -------------------------
gui_env_init() {
  # gui_env_init MODE
  # MODE: "cgi" or "cli"
  local mode="${1:-cli}"
  canonicalize_ui_root || return 1
  ensure_logs_dir || return 1

  # Rotate logs at init to avoid unbounded growth
  log_rotate_if_needed "${SERVER_LOG:-/dev/null}" 1048576 || true
  log_rotate_if_needed "${ERROR_LOG:-/dev/null}" 1048576 || true

  install_default_traps "$mode" || return 1

  # Redirect stderr to ERROR_LOG for diagnostics if writable and not already redirected
  if [[ -n "${ERROR_LOG:-}" && -w "$(dirname -- "$ERROR_LOG")" ]]; then
    # Avoid double-redirect if already redirected
    if ! { exec 2>>"$ERROR_LOG"; } 2>/dev/null; then
      # best-effort: if redirect fails, log and continue
      log_warn "INIT" "Failed to redirect stderr to $ERROR_LOG"
    fi
  fi

  return 0
}

# ---------------------------------------------------------------------------
# env_detect
# - sets flags: IS_TERMUX, IS_LINUX, IS_MAC, IS_WSL, IS_CYGWIN
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
# - performs environment-specific runtime preparation BEFORE ensure_groqbash_available
# - IMPORTANT: runtime must be read-only for shadow/wrapper persistence unless
#   INSTALL_MODE=1 (explicit install/adapt invocation).
# ---------------------------------------------------------------------------
env_prepare_runtime() {
  : "${UI_ROOT:=${PWD}}"
  : "${TMP_DIR:=${UI_ROOT%/}/tmp}"
  : "${CFG_DIR:=${UI_ROOT%/}/config}"
  : "${BOOTSTRAP_LOCK:=${TMP_DIR%/}/bootstrap.lock}"
  : "${BASH_PATH:=$(command -v bash 2>/dev/null || true)}"
  : "${INSTALL_MODE:=0}"   # 0 = normal runtime (no writes), 1 = install/adapt (allowed writes)"

  # --- Safe defaults for GUI runtime (single source of truth) ---
  : "${MAX_PROMPT_CHARS:=4096}"
  : "${MAX_RESPONSE_CHARS:=8192}"
  : "${MAX_TOKENS:=2048}"
  : "${PROVIDER_CACHE_FILE:=${CFG_DIR%/}/providers.txt}"
  : "${PROVIDER_MODELS_DIR:=${CFG_DIR%/}/models}"
  export MAX_PROMPT_CHARS MAX_RESPONSE_CHARS MAX_TOKENS PROVIDER_CACHE_FILE PROVIDER_MODELS_DIR
  # ----------------------------------------------------------------

  # Ensure runtime dirs exist and safe perms (idempotent)
  mkdir -p "${TMP_DIR%/}" "${CFG_DIR%/}" "${UI_ROOT%/}/bin" 2>/dev/null || true
  chmod 700 "${TMP_DIR%/}" "${CFG_DIR%/}" "${UI_ROOT%/}/bin" 2>/dev/null || true

  # Log ownership for debugging if CGI runs as different user
  if command -v stat >/dev/null 2>&1; then
    _tmp_owner="$(stat -c '%U:%G' "${TMP_DIR%/}" 2>/dev/null || true)"
    _cfg_owner="$(stat -c '%U:%G' "${CFG_DIR%/}" 2>/dev/null || true)"
    log_info "ENV" "TMP_DIR owner: ${_tmp_owner:-<unknown>}, CFG_DIR owner: ${_cfg_owner:-<unknown>}"
  fi

  # Determine deterministic real binary locations (robust list)
  local groqbash_real groqbash_shadow BIN_DIR wrapper tmp_shadow rc real_hash shadow_hash
  groqbash_shadow="/data/data/com.termux/files/usr/bin/groqbash"

  local candidates=(
    "${UI_ROOT%/}/../groqbash/groqbash"
    "${UI_ROOT%/}/../../groqbash/groqbash"
    "${PWD%/}/groqbash"
    "${HOME%/}/groqbash/groqbash"
    "/data/data/com.termux/files/home/groqbash/groqbash"
  )

  groqbash_real=""
  for cand in "${candidates[@]}"; do
    if [[ -x "$cand" ]]; then
      groqbash_real="$cand"
      log_info "ENV" "Found local groqbash candidate: $groqbash_real"
      break
    fi
  done

  # RUNTIME-ONLY behavior (no persistent writes)
  if [[ "${INSTALL_MODE:-0}" -ne 1 ]]; then
    # Prefer persisted groqbash-path if present and valid
    if [[ -f "${CFG_DIR%/}/groqbash-path" ]]; then
      local persisted
      persisted="$(sed -n '1p' "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true)"
      if [[ -n "$persisted" && -x "$persisted" ]]; then
        GROQBASH_CMD="$persisted"
        export GROQBASH_CMD
        PATH="${UI_ROOT%/}/bin:${PATH:-}"
        export PATH
        log_info "ENV" "Runtime mode: using persisted GROQBASH_CMD=${GROQBASH_CMD}"
        return 0
      else
        log_warn "ENV" "Persisted groqbash-path exists but is not executable or empty; ignoring in runtime"
      fi
    fi

    # If Termux, prefer wrapper/shadow only if already present and executable
    if [[ "${IS_TERMUX:-0}" -eq 1 ]]; then
      BIN_DIR="${UI_ROOT%/}/bin"
      wrapper="$BIN_DIR/groqbash-wrapper"
      if [[ -x "$wrapper" ]]; then
        GROQBASH_CMD="$wrapper"
        export GROQBASH_CMD
        PATH="$BIN_DIR:${PATH:-}"
        export PATH
        log_info "ENV" "Runtime mode (Termux): using existing wrapper $wrapper"
        return 0
      fi
      # If no wrapper, prefer groqbash_real if available
      if [[ -n "$groqbash_real" && -x "$groqbash_real" ]]; then
        GROQBASH_CMD="$groqbash_real"
        export GROQBASH_CMD
        log_info "ENV" "Runtime mode (Termux): no wrapper found, using local repo binary $groqbash_real"
        return 0
      fi
      log_warn "ENV" "Runtime mode (Termux): no wrapper and no local repo binary found; leaving GROQBASH_CMD unset"
      return 0
    fi

    # Non-Termux runtime: prefer local repo binary if present
    if [[ -n "$groqbash_real" && -x "$groqbash_real" ]]; then
      GROQBASH_CMD="$groqbash_real"
      export GROQBASH_CMD
      log_info "ENV" "Runtime mode (non-Termux): using local repo binary $groqbash_real"
      return 0
    fi

    # Nothing resolved; leave defaults
    log_warn "ENV" "Runtime mode: no groqbash resolved (no persisted path, no wrapper, no local binary)"
    return 0
  fi

  # ---------------------------
  # INSTALL_MODE=1 (install/adapt)
  # Allowed to create/update shadow/wrapper/persist groqbash-path
  # ---------------------------

  # If not Termux, do not create a shadow; persist groqbash_real into groqbash-path
  if [[ "${IS_TERMUX:-0}" -ne 1 ]]; then
    if [[ -n "$groqbash_real" && -x "$groqbash_real" ]]; then
      # Persist groqbash_real into CFG_DIR/groqbash-path atomically
      mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
      if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" ]]; then
        tmp_path="$(portable_mktemp "${CFG_DIR%/}")" || tmp_path="${CFG_DIR%/}/groqbash-path.tmp"
        if printf '%s\n' "$groqbash_real" >"$tmp_path" 2>/dev/null; then
          line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
          if [[ "$line_count" -eq 1 ]]; then
            mv -f -- "$tmp_path" "${CFG_DIR%/}/groqbash-path"
            chmod 600 "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
            log_info "ENV" "INSTALL_MODE: persisted groqbash-path -> $groqbash_real"
            GROQBASH_CMD="$groqbash_real"
            export GROQBASH_CMD
            return 0
          else
            log_warn "ENV" "INSTALL_MODE: refusing to persist groqbash-path: temp file contains ${line_count} non-empty lines"
            rm -f -- "$tmp_path" 2>/dev/null || true
            return 0
          fi
        else
          log_warn "ENV" "INSTALL_MODE: failed to write temporary groqbash-path at $tmp_path"
          rm -f -- "$tmp_path" 2>/dev/null || true
          return 0
        fi
      else
        log_warn "ENV" "INSTALL_MODE: CFG_DIR not writable; cannot persist groqbash-path"
        return 0
      fi
    else
      log_warn "ENV" "INSTALL_MODE: no local repo binary found to persist on non-Termux"
      return 0
    fi
  fi

  # From here: IS_TERMUX=1 and INSTALL_MODE=1 -> perform Termux shadow/wrapper update
  # Ensure TMP_DIR usable and flock available; bail gracefully if not
  ensure_tmpdir || { log_warn "ENV" "ensure_tmpdir failed; skipping Termux shadow/wrapper update"; return 0; }
  if ! command -v flock >/dev/null 2>&1; then
    log_warn "ENV" "flock not available; skipping Termux shadow/wrapper update"
    return 0
  fi

  # Acquire bootstrap lock (fd 9)
  exec 9>"${BOOTSTRAP_LOCK}" 2>/dev/null || { log_warn "ENV" "cannot open BOOTSTRAP_LOCK"; return 0; }
  if ! flock -x -w 5 9; then
    exec 9>&- 2>/dev/null || true
    log_warn "ENV" "Could not acquire bootstrap lock; skipping Termux shadow/wrapper update"
    return 0
  fi

  # Helper to release lock before any early return
  _release_lock() {
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
  }

  # Compute hashes once to decide whether to update shadow
  real_hash="$(compute_hash "$groqbash_real" 2>/dev/null || true)"
  shadow_hash="$(compute_hash "$groqbash_shadow" 2>/dev/null || true)"

  # Initialize rc defensively
  rc=1

  if [[ -z "$shadow_hash" || "$real_hash" != "$shadow_hash" ]]; then
    tmp_shadow="$(portable_mktemp "$TMP_DIR" "groqbash-shadow.XXXXXX")" || tmp_shadow=""
    if [[ -n "$tmp_shadow" ]]; then
      if ! cp -f -- "$groqbash_real" "$tmp_shadow" 2>/dev/null; then
        log_warn "ENV" "Failed to copy real groqbash to tmp shadow"
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        _release_lock
        return 0
      fi

      # Patch shebang defensively if BASH_PATH resolved and executable
      if [[ -n "${BASH_PATH:-}" && -x "$BASH_PATH" ]]; then
        if head -n1 "$tmp_shadow" 2>/dev/null | grep -qE '^#!'; then
          sed -i '1s|^#!.*|#!'"$BASH_PATH"'|' "$tmp_shadow" 2>/dev/null || true
        fi
      fi

      if ! mv -f -- "$tmp_shadow" "$groqbash_shadow" 2>/dev/null; then
        log_warn "ENV" "Failed to move tmp shadow into place"
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        _release_lock
        return 0
      fi
      rc=0
    else
      # portable_mktemp failed: log explicit reason and do NOT perform unsafe direct copy
      log_warn "ENV" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; refusing to perform direct copy to $groqbash_shadow in INSTALL_MODE"
      _release_lock
      return 0
    fi

    if (( rc != 0 )); then
      log_warn "ENV" "Shadow update returned non-zero rc"
      _release_lock
      return 0
    fi

    chmod 750 "$groqbash_shadow" 2>/dev/null || true
    shadow_hash="$(compute_hash "$groqbash_shadow" 2>/dev/null || true)"
    log_info "ENV" "INSTALL_MODE: Updated groqbash shadow at $groqbash_shadow"
  else
    log_info "ENV" "INSTALL_MODE: groqbash shadow already up-to-date"
  fi

  # Ensure BASH_PATH resolved and executable before creating wrapper
  if [[ -z "${BASH_PATH:-}" || ! -x "$BASH_PATH" ]]; then
    _release_lock
    log_warn "ENV" "BASH_PATH not resolved or not executable; skipping wrapper creation"
    return 0
  fi

  # Create wrapper in UI_ROOT/bin pointing to shadow using resolved BASH_PATH
  BIN_DIR="${UI_ROOT%/}/bin"
  mkdir -p "$BIN_DIR" 2>/dev/null || true
  chmod 700 "$BIN_DIR" 2>/dev/null || true
  wrapper="$BIN_DIR/groqbash-wrapper"

  # Write wrapper atomically into TMP_DIR, then move only if different
  local tmp_wrapper new_wrapper_hash existing_wrapper_hash wrapper_hash
  tmp_wrapper="$(portable_mktemp "$TMP_DIR" "wrapper.XXXXXX")" || tmp_wrapper=""
  if [[ -n "$tmp_wrapper" ]]; then
    printf '%s\n' "#!$BASH_PATH" "exec \"$BASH_PATH\" \"$groqbash_shadow\" \"\$@\"" >"$tmp_wrapper" 2>/dev/null || {
      log_warn "ENV" "Failed to write tmp wrapper"
      rm -f -- "$tmp_wrapper" 2>/dev/null || true
      _release_lock
      return 0
    }

    # If wrapper exists, compare hashes and avoid unnecessary mv
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
    # fallback: do NOT perform unsafe direct write in INSTALL_MODE; require mktemp
    log_warn "ENV" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; refusing to write wrapper directly in INSTALL_MODE"
    _release_lock
    return 0
  fi

  chmod 750 "$wrapper" 2>/dev/null || true

  # compute wrapper hash once for later use
  wrapper_hash="$(compute_hash "$wrapper" 2>/dev/null || true)"

  # release lock
  _release_lock

  # Export wrapper preference for runtime if executable
  if [[ -x "$wrapper" ]]; then
    GROQBASH_CMD="$wrapper"
    export GROQBASH_CMD
    PATH="$BIN_DIR:${PATH:-}"
    export PATH
    log_info "ENV" "INSTALL_MODE: Termux wrapper ensured at $wrapper (hash: ${wrapper_hash:-<none>})"
  else
    log_warn "ENV" "Wrapper not executable; GROQBASH_CMD not set to wrapper"
  fi

  # Persist groqbash-path into CFG_DIR atomically; ensure CFG_DIR exists
  if [[ -n "${CFG_DIR:-}" ]]; then
    mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
    if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" && -n "${wrapper:-}" && -x "$wrapper" ]]; then
      # write into a temp file inside CFG_DIR and validate it contains exactly one non-empty line
      tmp_path="$(portable_mktemp "${CFG_DIR%/}")" || tmp_path="${CFG_DIR%/}/groqbash-path.tmp"
      if printf '%s\n' "$wrapper" >"$tmp_path" 2>/dev/null; then
        # normalize and count non-empty lines
        line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
        if [[ "$line_count" -eq 1 ]]; then
          mv -f -- "$tmp_path" "${CFG_DIR%/}/groqbash-path"
          chmod 600 "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
          log_info "ENV" "INSTALL_MODE: Persisted groqbash-path to ${CFG_DIR%/}/groqbash-path -> $wrapper"
        else
          log_warn "ENV" "INSTALL_MODE: Refusing to persist groqbash-path: temp file contains ${line_count} non-empty lines (expected 1); tmp: $tmp_path"
          rm -f -- "$tmp_path" 2>/dev/null || true
        fi
      else
        log_warn "ENV" "INSTALL_MODE: Failed to write temporary groqbash-path at $tmp_path; skipping persist"
        rm -f -- "$tmp_path" 2>/dev/null || true
      fi
    else
      log_warn "ENV" "INSTALL_MODE: CFG_DIR not writable or wrapper unset/not executable; skipping persist of groqbash-path"
    fi
  fi

  return 0
}

# ---------------------------------------------------------------------------
# env_after_groqbash_resolved
# - operations that require GROQBASH_CMD already resolved
# ---------------------------------------------------------------------------
env_after_groqbash_resolved() {
  if [[ -n "${GROQBASH_CMD:-}" && -x "${GROQBASH_CMD}" ]]; then
    # Lightweight diagnostic: count providers if possible (best-effort)
    local prov_count
    prov_count="$("${GROQBASH_CMD}" --list-providers-raw 2>/dev/null | wc -l 2>/dev/null || true)"
    log_info "ENV" "groqbash resolved: ${GROQBASH_CMD} (providers: ${prov_count:-0})"
  else
    log_warn "ENV" "groqbash not resolved in env_after_groqbash_resolved"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Utility: ensure_tmpdir, portable_mktemp, portable_mktemp alias,
# atomic_write, atomic_append_conv, compute_hash, same_filesystem
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

# Canonical portable_mktemp: portable_mktemp <dir> [template]
portable_mktemp() {
  local dir="${1:-}" template="${2:-.tmp.XXXXXX}"
  local dir_real tmp candidate base i rand

  if [[ -z "$dir" ]]; then
    log_error "GUIIO" "portable_mktemp called with empty dir"
    return 1
  fi

  # Ensure directory exists and is writable
  mkdir -p -- "$dir" 2>/dev/null || { log_error "GUIIO" "portable_mktemp: cannot create dir: $dir"; return 1; }
  dir_real="$(cd -- "$dir" 2>/dev/null && pwd -P || true)"
  if [[ -z "$dir_real" || ! -d "$dir_real" || ! -w "$dir_real" ]]; then
    log_error "GUIIO" "portable_mktemp: dir invalid or not writable: ${dir:-<unset>} -> ${dir_real:-<unresolved>}"
    return 1
  fi

  # Optional confinement: prefer TMP_DIR if set, otherwise allow UI_ROOT/.tmp
  if [[ -n "${TMP_DIR:-}" ]]; then
    case "$dir_real" in
      "$TMP_DIR"/*|"$TMP_DIR") ;;
      *)
        log_error "GUIIO" "portable_mktemp: dir ${dir_real} is not inside TMP_DIR (${TMP_DIR:-<unset>})"
        return 1
        ;;
    esac
  fi

  # Try mktemp -p if available (portable systems)
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

  # Fallback deterministic loop (avoid collisions)
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

# Atomic write: atomic_write <dest> <content>
atomic_write() {
  local dest="$1" content="${2:-}" dest_dir tmp
  dest_dir="$(dirname -- "$dest")"
  ensure_tmpdir || return 1
  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(portable_mktemp "$TMP_DIR" "atomic.XXXXXX")"; then
    :
  else
    tmp="$(portable_mktemp "$dest_dir" "atomic.XXXXXX")"
  fi
  umask 077
  printf '%s' "$content" >"$tmp" || { log_error "GUIIO" "Failed to write to temp file $tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  if command -v sync >/dev/null 2>&1; then sync || true; fi
  mv -f "$tmp" "$dest" || { log_error "GUIIO" "mv failed in atomic_write from $tmp to $dest"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  chmod 600 "$dest" || true
  return 0
}

# Atomic append for conversation files: atomic_append_conv <conv_file> <line...>
atomic_append_conv() {
  local conv_file="$1" append_text="$2" tmp dest_dir lockfile lockfd
  if [[ -z "$conv_file" ]]; then return 1; fi
  dest_dir="$(dirname -- "$conv_file")"
  mkdir -p -- "$dest_dir" 2>/dev/null || true

  # Prefer to use a lockfile to serialize appends if flock available
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

# Atomic append variant that reads from stdin and appends into convfile (used by some callers)
atomic_append_conv_in_uiroot() {
  local convfile="$1"
  if [[ -z "$convfile" ]]; then return 1; fi
  local dir tmpf lockfile lockfd
  dir="$(dirname -- "$convfile")"
  mkdir -p -- "$dir" 2>/dev/null || true

  # Use portable_mktemp only; if it fails, fail the function
  tmpf="$(portable_mktemp "$dir" "conv.XXXXXX")" || return 1

  if [[ -f "$convfile" ]]; then
    cp -a -- "$convfile" "$tmpf" || { rm -f -- "$tmpf" 2>/dev/null || true; return 1; }
  else
    : >"$tmpf"
  fi

  # Append stdin to tmpf
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
  # Returns 0 if basic health checks pass, non-zero otherwise.
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
  if [[ -n "${GROQBASH_CMD:-}" && ! -x "${GROQBASH_CMD}" ]]; then
    log_warn "HEALTH" "GROQBASH_CMD set but not executable: ${GROQBASH_CMD:-<unset>}"
    ok=1
  fi
  return $ok
}

gui_env_dump_diag() {
  # Dump compact diagnostics: last N lines of logs and key vars
  local lines="${1:-50}"
  printf '--- DIAGNOSTIC DUMP (%s lines) ---\n' "$lines"
  printf 'UI_ROOT=%s\n' "${UI_ROOT:-<unset>}"
  printf 'TMP_DIR=%s\n' "${TMP_DIR:-<unset>}"
  printf 'LOG_DIR=%s\n' "${LOG_DIR:-<unset>}"
  printf 'GROQBASH_CMD=%s\n' "${GROQBASH_CMD:-<unset>}"
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

# End of gui-env.sh
