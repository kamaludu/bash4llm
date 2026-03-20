#!/usr/bin/env bash
# =============================================================================
# Portable environment bootstrap for GroqBash GUI CGI
# File: gui-bootstrap.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
set -euo pipefail
umask 077

# Prevent double sourcing
if [[ "${__GUI_BOOTSTRAP_LOADED:-}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi
__GUI_BOOTSTRAP_LOADED=1

# Allow overrides from environment before sourcing
: "${GROQBASH_CMD:=groqbash}"
: "${UI_ROOT:=}"
: "${TMP_DIR:=}"
: "${LOG_DIR:=}"
: "${CFG_DIR:=}"
: "${CONV_DIR:=}"
: "${FILES_DIR:=}"
: "${TEMPLATES_DIR:=}"

# Limits (can be overridden before sourcing)
: "${MAX_PROMPT_CHARS:=5000}"
: "${MAX_MODEL_OUTPUT_CHARS:=20000}"
: "${VALID_NAME_RE:='^[A-Za-z0-9_-]+$'}"
: "${MAX_NAME_LEN:=255}"

# ---------------------------------------------------------------------------
# Explicit dependency check (no implicit deps)
# - ensure all external commands used by the GUI scripts are present
# - builtins (bash) are intentionally NOT listed
# ---------------------------------------------------------------------------
for cmd in awk sed tr df mktemp readlink wc dd cat mv chmod rm printf basename dirname flock base64; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'groqbash: ERROR: required command not found: %s\n' "$cmd" >&2
    # Fail fast: GUI bootstrap cannot guarantee safe operation without these tools
    return 1 2>/dev/null || exit 1
  fi
done

# ---------------------------------------------------------------------------
# Resolve this script's directory reliably (portable, avoids readlink -f portability issues)
# - This routine resolves a symlink target when possible and falls back to
#   deriving the directory from the source path. It avoids relying on
#   readlink -f which is not portable on all platforms (macOS/BSD).
# ---------------------------------------------------------------------------
_bootstrap_source="${BASH_SOURCE[0]:-}"
# If the source is a symlink, try to resolve the link target (portable)
if command -v readlink >/dev/null 2>&1 && [ -L "$_bootstrap_source" ]; then
  _rl="$(readlink "$_bootstrap_source" 2>/dev/null || true)"
  if [ -n "$_rl" ]; then
    case "$_rl" in
      /*) _bootstrap_source="$_rl" ;;
      *) _bootstrap_source="$(dirname "$_bootstrap_source")/$_rl" ;;
    esac
  fi
fi
BOOTSTRAP_DIR="$(cd "$(dirname -- "$_bootstrap_source")" >/dev/null 2>&1 && pwd -P || printf '%s' "$(dirname "$_bootstrap_source")")"

# If UI_ROOT not provided, assume parent of bootstrap dir (cgi-bin -> ui)
if [[ -z "$UI_ROOT" ]]; then
  if [[ "$(basename "$BOOTSTRAP_DIR")" == "cgi-bin" ]]; then
    UI_ROOT="$(cd "$BOOTSTRAP_DIR/.." && pwd -P)"
  else
    UI_ROOT="$BOOTSTRAP_DIR"
  fi
fi

# Default dirs relative to UI_ROOT if not overridden
: "${TMP_DIR:="$UI_ROOT/tmp"}"
: "${LOG_DIR:="$UI_ROOT/logs"}"
: "${CFG_DIR:="$UI_ROOT/config"}"
: "${CONV_DIR:="$UI_ROOT/conversations"}"
: "${FILES_DIR:="$UI_ROOT/files"}"
: "${TEMPLATES_DIR:="$UI_ROOT/templates"}"

LOCK_FILE="$TMP_DIR/gui.lock"
SERVER_LOG="$LOG_DIR/server.log"
ERROR_LOG="$LOG_DIR/errors.log"

CURRENT_CONV_FILE="$CFG_DIR/current-conversation"
LANG_CURRENT_FILE="$CFG_DIR/lang-current"
THEME_CURRENT_FILE="$CFG_DIR/gui-theme"
DEFAULT_MODEL_FILE="$CFG_DIR/default-model"
DEFAULT_PROVIDER_FILE="$CFG_DIR/default-provider"

LOCK_HELD=0

# Default GUI lock timeout (seconds) - configurable via env
: "${GROQBASHGUILOCKTIMEOUT:=10}"

# -------------------------
# Logging and rotation (uniform prefixes to match GroqBash)
# -------------------------
log_prefix() { printf 'groqbash: %s: ' "$SCRIPT_NAME"; } 2>/dev/null || true

log_info() {
  # Usage: log_info [CODE] MESSAGE
  local code msg
  if [ "$#" -eq 1 ]; then
    code="INFO"
    msg="$1"
  else
    code="${1:-INFO}"
    msg="${2:-}"
  fi
  printf 'groqbash: INFO: %s: %s\n' "$code" "$msg" >>"$SERVER_LOG" 2>/dev/null || true
}

log_warn() {
  local code msg
  if [ "$#" -eq 1 ]; then
    code="WARN"
    msg="$1"
  else
    code="${1:-WARN}"
    msg="${2:-}"
  fi
  printf 'groqbash: WARN: %s: %s\n' "$code" "$msg" >>"$SERVER_LOG" 2>/dev/null || true
}

log_error() {
  # Usage: log_error [CODE] MESSAGE
  local code msg
  if [ "$#" -eq 1 ]; then
    code="ERROR"
    msg="$1"
  else
    code="${1:-ERROR}"
    msg="${2:-}"
  fi
  mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null || true
  printf 'groqbash: ERROR: %s: %s\n' "$code" "$msg" >>"$ERROR_LOG" 2>/dev/null || true
}

log_rotate_if_needed() {
  local file="$1" max_bytes="${2:-1048576}"
  if [[ -f "$file" ]]; then
    local size
    size="$(wc -c <"$file" 2>/dev/null || echo 0)"
    if (( size > max_bytes )); then
      mv -f "$file" "${file}.old" 2>/dev/null || true
      : >"$file"
    fi
  fi
}

# -------------------------
# Portable mktemp wrapper
# -------------------------
mktemp_portable() {
  local dir="$1" template="$2"
  # Validate dir
  if [[ -z "$dir" || ! -d "$dir" || ! -w "$dir" ]]; then
    return 1
  fi

  # Try mktemp with --tmpdir if supported
  if command -v mktemp >/dev/null 2>&1; then
    if mktemp --help >/dev/null 2>&1; then
      if tmp="$(mktemp --tmpdir="$dir" "$template" 2>/dev/null)"; then
        printf '%s' "$tmp"
        return 0
      fi
    fi
    # Fallback to mktemp with explicit path
    if tmp="$(mktemp "$dir/$template" 2>/dev/null)"; then
      printf '%s' "$tmp"
      return 0
    fi
  fi

  # Final fallback: create a unique filename atomically using shell noclobber
  local i=0 rand base file candidate tmpname
  base="$(date +%s%N 2>/dev/null || printf '%s' "$$")"
  while (( i < 100 )); do
    rand="${base}.$RANDOM.$$.$i"
    if [[ "$template" == *"XXXXXX"* ]]; then
      tmpname="${template//XXXXXX/$rand}"
    else
      tmpname="${template}.$rand"
    fi
    candidate="$dir/$tmpname"
    # Attempt atomic creation with noclobber
    ( set -C; : >"$candidate" ) 2>/dev/null && { printf '%s' "$candidate"; return 0; } || true
    i=$((i+1))
  done

  log_error "GUIIO" "mktemp_portable failed to create temp file in $dir"
  return 1
}
# NOTE: mktemp_portable should be tested on macOS and BusyBox to ensure the
# fallback behavior works as expected in those environments.

# -------------------------
# same_filesystem
# -------------------------
same_filesystem() {
  local a="$1" b="$2" da db fa fb
  da="$a"; while [[ ! -e "$da" && "$da" != "/" ]]; do da="$(dirname -- "$da")"; done
  db="$b"; while [[ ! -e "$db" && "$db" != "/" ]]; do db="$(dirname -- "$db")"; done
  if [[ ! -e "$da" || ! -e "$db" ]]; then return 1; fi
  if ! command -v df >/dev/null 2>&1; then return 1; fi
  fa="$(df -P "$da" 2>/dev/null | awk 'END{print $1}')" || fa=""
  fb="$(df -P "$db" 2>/dev/null | awk 'END{print $1}')" || fb=""
  [[ -n "$fa" && -n "$fb" && "$fa" == "$fb" ]]
}

# -------------------------
# ensure tmpdir exists and writable
# -------------------------
ensure_tmpdir() {
  if [[ -e "$TMP_DIR" && ! -d "$TMP_DIR" ]]; then
    log_error "GUIIO" "TMP_DIR exists and is not a directory: $TMP_DIR"
    print_http_error "500 Internal Server Error" "Server configuration error: tmpdir invalid"
    return 1
  fi
  if [[ ! -d "$TMP_DIR" ]]; then
    mkdir -p "$TMP_DIR" || { log_error "GUIIO" "Failed to create TMP_DIR $TMP_DIR"; print_http_error "500 Internal Server Error" "Server configuration error: cannot create tmpdir"; return 1; }
    chmod 700 "$TMP_DIR" || true
  fi
  if [[ ! -w "$TMP_DIR" ]]; then
    log_error "GUIIO" "TMP_DIR $TMP_DIR not writable"
    print_http_error "500 Internal Server Error" "Server configuration error: tmpdir not writable"
    return 1
  fi
  return 0
}

# -------------------------
# Atomic write and append
# -------------------------
atomic_write() {
  local dest="$1" content="${2:-}" dest_dir tmp
  dest_dir="$(dirname -- "$dest")"
  ensure_tmpdir || return 1
  if same_filesystem "$TMP_DIR" "$dest_dir" && mktemp_portable "$TMP_DIR" "atomic.XXXXXX" >/dev/null 2>&1; then
    tmp="$(mktemp_portable "$TMP_DIR" "atomic.XXXXXX")" || { log_error "GUIIO" "mktemp failed in atomic_write (tmpdir)"; return 1; }
  else
    tmp="$(mktemp_portable "$dest_dir" "atomic.XXXXXX")" || { log_error "GUIIO" "mktemp failed in atomic_write (destdir)"; return 1; }
  fi
  umask 077
  printf '%s' "$content" >"$tmp" || { log_error "GUIIO" "Failed to write to temp file $tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  if command -v sync >/dev/null 2>&1; then sync || true; fi
  mv -f "$tmp" "$dest" || { log_error "GUIIO" "mv failed in atomic_write from $tmp to $dest"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  chmod 600 "$dest" || true
  return 0
}

# atomic_append_conv must be called only when a lock is held (documented)
# It performs an atomic append by writing a tmp file and renaming it into place.
atomic_append_conv() {
  local conv_file="$1" append_text="$2" tmp dest_dir
  if [[ "$LOCK_HELD" -ne 1 ]]; then log_error "GUILOCK" "atomic_append_conv called without lock held"; return 1; fi
  dest_dir="$(dirname -- "$conv_file")"
  if same_filesystem "$TMP_DIR" "$dest_dir" && mktemp_portable "$TMP_DIR" "conv.XXXXXX" >/dev/null 2>&1; then
    tmp="$(mktemp_portable "$TMP_DIR" "conv.XXXXXX")" || { log_error "GUIIO" "mktemp failed in atomic_append_conv (tmpdir)"; return 1; }
  else
    tmp="$(mktemp_portable "$dest_dir" "conv.XXXXXX")" || { log_error "GUIIO" "mktemp failed in atomic_append_conv (destdir)"; return 1; }
  fi
  if [[ -f "$conv_file" ]]; then cat "$conv_file" >"$tmp" || { log_error "GUIIO" "Failed to copy existing conversation to tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }; fi
  printf '%s\n' "$append_text" >>"$tmp" || { log_error "GUIIO" "Failed to append text to tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  mv -f "$tmp" "$conv_file" || { log_error "GUIIO" "mv failed in atomic_append_conv"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  chmod 600 "$conv_file" || true
  return 0
}

# -------------------------
# flock availability and lock management (fd 9)
# - acquire_lock now uses a configurable timeout to avoid indefinite blocking
# - on timeout we log a LOCKTIMEOUT event and return non-zero
# -------------------------
ensure_flock_available() {
  if ! command -v flock >/dev/null 2>&1; then
    log_error "GUILLOCK" "flock not available on this system; cannot guarantee safe concurrency"
    print_http_error "500 Internal Server Error" "Server misconfiguration: flock not available"
    return 1
  fi
  return 0
}

acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null || true
  exec 9>"$LOCK_FILE"
  # Use timeout to avoid indefinite blocking; log LOCKTIMEOUT on failure
  if ! flock -x -w "$GROQBASHGUILOCKTIMEOUT" 9; then
    log_error "LOCKTIMEOUT" "could not acquire GUI lock on $LOCK_FILE within ${GROQBASHGUILOCKTIMEOUT}s"
    # Inform client that server is busy/unavailable
    print_http_error "503 Service Unavailable" "Server busy; please retry"
    # Close fd and mark not held
    exec 9>&- || true
    LOCK_HELD=0
    return 1
  fi
  LOCK_HELD=1
  trap 'release_lock' EXIT INT TERM
  return 0
}

release_lock() {
  if [[ "$LOCK_HELD" -eq 1 ]]; then
    exec 9>&- || true
    LOCK_HELD=0
    trap - EXIT INT TERM
  fi
}

# -------------------------
# HTTP helpers and escaping
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
  printf '<h1>%s</h1>\n' "$(html_escape "$msg")"
}

html_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}
html_escape_stream() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# -------------------------
# Validation and sanitization
# -------------------------
validate_name() {
  local name="$1"

  [[ -z "$name" ]] && return 1
  [[ "$name" == "." || "$name" == ".." ]] && return 1
  [[ "$name" == *"/"* || "$name" == *"\\"* || "$name" == *$'\x00'* ]] && return 1

  # SAFE: non fa fallire la pipeline con set -e
  if printf '%s' "$name" | awk '/[[:cntrl:]]/ { found=1 } END { exit found }'; then
    return 1
  fi

  (( ${#name} > MAX_NAME_LEN )) && return 1

  return 0
}

sanitize_param() {
  local v="$1"
  v="$(printf '%s' "$v" | tr -d '\000-\011\013\014\016-\037' | tr '\t' ' ' | sed -E 's/  +/ /g')"
  printf '%s' "$v"
}

url_decode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

get_query_param() {
  local name="$1"
  local qs="${QUERY_STRING:-}"
  local IFS='&' pair key value
  for pair in $qs; do
    key="${pair%%=*}"
    value="${pair#*=}"
    if [[ "$key" == "$name" ]]; then
      url_decode "$value"
      return 0
    fi
  done
  return 1
}

read_post_body() {
  local len="${CONTENT_LENGTH:-0}"
  if ! [[ "$len" =~ ^[0-9]+$ ]]; then len=0; fi
  # Documented: CONTENT_LENGTH must be validated; we cap and handle missing values.
  if (( len > 0 )); then
    if command -v head >/dev/null 2>&1; then
      head -c "$len"
    else
      dd bs=1 count="$len" 2>/dev/null || true
    fi
  fi
}

parse_form_field() {
  local name="$1"
  local body
  body="$(cat)"
  local IFS='&' pair key value
  for pair in $body; do
    key="${pair%%=*}"
    value="${pair#*=}"
    if [[ "$key" == "$name" ]]; then
      url_decode "$value"
      return 0
    fi
  done
  return 1
}

# -------------------------
# Config helpers
# -------------------------
read_config_or_default() {
  local file="$1" default="$2"
  if [[ -r "$file" ]]; then
    local v
    v="$(sed -n '1p' "$file" 2>/dev/null || echo "")"
    if [[ -n "$v" ]]; then
      printf '%s' "$v"
      return 0
    fi
  fi
  printf '%s' "$default"
  return 0
}

get_current_conversation_file() {
  local conv
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "conv-001.txt")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then
    log_error "GUIIO" "Invalid current conversation name: '$conv' - falling back to conv-001.txt"
    conv="conv-001.txt"
    atomic_write "$CURRENT_CONV_FILE" "$conv" || true
  fi
  printf '%s/%s\n' "$CONV_DIR" "$conv"
}

get_default_model() { read_config_or_default "$DEFAULT_MODEL_FILE" "default"; }
get_default_provider() { read_config_or_default "$DEFAULT_PROVIDER_FILE" "default"; }

# -------------------------
# Ensure runtime dirs exist (safe)
# -------------------------
ensure_dirs() {
  mkdir -p "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR"/input "$FILES_DIR"/output "$TEMPLATES_DIR" 2>/dev/null || true
  chmod 700 "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR" "$FILES_DIR"/input "$FILES_DIR"/output 2>/dev/null || true
  ensure_tmpdir || return 1
  return 0
}

# -------------------------
# Ensure config defaults (moved to bootstrap)
# -------------------------
ensure_config_defaults() {
  local conv_default="conv-001.txt"
  local lang_default="en"
  local model_default="default"
  local provider_default="default"

  if [[ ! -f "$CURRENT_CONV_FILE" ]]; then
    atomic_write "$CURRENT_CONV_FILE" "$conv_default" || true
  fi
  if [[ ! -f "$LANG_CURRENT_FILE" ]]; then
    atomic_write "$LANG_CURRENT_FILE" "$lang_default" || true
  fi
  if [[ ! -f "$THEME_CURRENT_FILE" ]]; then
    atomic_write "$THEME_CURRENT_FILE" "light" || true
  fi
  if [[ ! -f "$DEFAULT_MODEL_FILE" ]]; then
    atomic_write "$DEFAULT_MODEL_FILE" "$model_default" || true
  fi
  if [[ ! -f "$DEFAULT_PROVIDER_FILE" ]]; then
    atomic_write "$DEFAULT_PROVIDER_FILE" "$provider_default" || true
  fi

  local conv
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "$conv_default")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then
    conv="$conv_default"
    atomic_write "$CURRENT_CONV_FILE" "$conv" || true
  fi
  if [[ ! -f "$CONV_DIR/$conv" ]]; then
    atomic_write "$CONV_DIR/$conv" "" || true
  fi
}

# -------------------------
# Ensure groqbash available (search fallbacks)
# -------------------------
ensure_groqbash_available() {
  if command -v "$GROQBASH_CMD" >/dev/null 2>&1; then
    return 0
  fi
  # try common relative locations
  for p in "$UI_ROOT/../groqbash" "$UI_ROOT/../bin/groqbash" "$HOME/groqbash/groqbash" "$HOME/groqbash"; do
    if [[ -x "$p" ]]; then
      GROQBASH_CMD="$p"
      return 0
    fi
  done
  return 1
}

# Expose key variables for gui-server.sh
export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR \
       LOCK_FILE SERVER_LOG ERROR_LOG CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE \
       DEFAULT_MODEL_FILE DEFAULT_PROVIDER_FILE GROQBASH_CMD

# End of bootstrap
return 0 2>/dev/null || true
