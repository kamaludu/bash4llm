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

# --- Termux compatibility: create wrapper + env shim and export GROQBASH_CMD and PATH
create_termux_compat_bootstrap() {
  # run only on Termux
  [[ -d "/data/data/com.termux/files/usr" ]] || return 0

  # If UI_ROOT is not yet resolved, do not create user wrappers here.
  # The bootstrap will call this function again after UI_ROOT is canonicalized.
  if [[ -z "${UI_ROOT:-}" ]]; then
    return 0
  fi

  local bash_path env_path groqbash_path USER_HOME BIN_DIR

  # reliable detection methods
  bash_path="$(command -v bash 2>/dev/null || true)"
  if [[ -z "$bash_path" ]]; then
    bash_path="$(type -P bash 2>/dev/null || true)"
  fi

  # minimal sensible fallbacks
  bash_path="${bash_path:-/data/data/com.termux/files/usr/bin/bash}"
  bash_path="${bash_path:-/system/bin/bash}"

  # ensure executable
  if [[ ! -x "$bash_path" ]]; then
    printf 'WARNING: Termux bash not found or not executable at %s; skipping Termux compatibility\n' "$bash_path" >&2
    return 1
  fi

  # detect env if available
  env_path="$(command -v env 2>/dev/null || true)"
  env_path="${env_path:-/data/data/com.termux/files/usr/bin/env}"
  [[ -x "$env_path" ]] || env_path=""

  # groqbash path (standard Termux install); non fatal if missing
  groqbash_path="/data/data/com.termux/files/usr/bin/groqbash"
  if [[ ! -x "$groqbash_path" ]]; then
    printf 'WARNING: groqbash not executable at %s; wrapper will still be created\n' "$groqbash_path" >&2
  fi

  # prepare user bin
  USER_HOME="${HOME:-/data/data/com.termux/files/home}"

  # Prefer creating wrappers inside UI_ROOT when available to avoid polluting $HOME/bin.
  # Fall back to $USER_HOME/bin only if UI_ROOT is not set.
  BIN_DIR="${UI_ROOT:-$USER_HOME}/bin"

  mkdir -p "$BIN_DIR" 2>/dev/null || true
  chmod 700 "$BIN_DIR" 2>/dev/null || true

  # create wrapper that forces the detected bash to interpret groqbash (bypasses shebang)
  cat > "$BIN_DIR/groqbash-wrapper" <<EOF
#!${bash_path}
exec ${bash_path} ${groqbash_path} "\$@"
EOF
  chmod 750 "$BIN_DIR/groqbash-wrapper" 2>/dev/null || true
  chown "$(id -u):$(id -g)" "$BIN_DIR/groqbash-wrapper" 2>/dev/null || true

  # optional env shim if env found
  if [[ -n "$env_path" && -x "$env_path" ]]; then
    cat > "$BIN_DIR/env" <<EOF
#!${bash_path}
exec ${env_path} "\$@"
EOF
    chmod 750 "$BIN_DIR/env" 2>/dev/null || true
    chown "$(id -u):$(id -g)" "$BIN_DIR/env" 2>/dev/null || true
  fi

  # export for use by gui-server and any child processes (CGI)
  export GROQBASH_CMD="${BIN_DIR}/groqbash-wrapper"
  export PATH="${BIN_DIR}:/data/data/com.termux/files/usr/bin:/system/bin:/usr/bin:/bin:${PATH:-}"

  return 0
}
# --- end Termux compatibility function ---

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

# Termux compatibility will be initialized after UI_ROOT is resolved
# (create_termux_compat_bootstrap is called later, once UI_ROOT is known,
# to avoid creating $HOME/bin outside the UI tree).

# Limits (can be overridden before sourcing)
: "${MAX_PROMPT_CHARS:=5000}"
: "${MAX_MODEL_OUTPUT_CHARS:=20000}"
: "${VALID_NAME_RE:='^[A-Za-z0-9_-]+$'}"
: "${MAX_NAME_LEN:=255}"

# ---------------------------------------------------------------------------
# Explicit dependency check (no implicit deps)
# ---------------------------------------------------------------------------
for cmd in awk sed tr df mktemp readlink wc dd cat mv chmod rm printf basename dirname flock base64 head grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'groqbash: ERROR: required command not found: %s\n' "$cmd" >&2
    return 1 2>/dev/null || exit 1
  fi
done

# ---------------------------------------------------------------------------
# Resolve this script's directory reliably
# ---------------------------------------------------------------------------
_bootstrap_source="${BASH_SOURCE[0]:-}"
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

# Call Termux compat only after UI_ROOT has been resolved so wrappers and shims
# are created inside the UI tree (avoid creating $HOME/bin outside the UI).
create_termux_compat_bootstrap || printf 'WARNING: create_termux_compat_bootstrap failed\n' >&2

LOCK_FILE="$TMP_DIR/gui.lock"
SERVER_LOG="$LOG_DIR/server.log"
ERROR_LOG="$LOG_DIR/errors.log"

CURRENT_CONV_FILE="$CFG_DIR/current-conversation"
LANG_CURRENT_FILE="$CFG_DIR/lang-current"
THEME_CURRENT_FILE="$CFG_DIR/gui-theme"
DEFAULT_MODEL_FILE="$CFG_DIR/default-model"
DEFAULT_PROVIDER_FILE="$CFG_DIR/default-provider"
API_KEY_FILE="$CFG_DIR/api-key"

LOCK_HELD=0

# Default GUI lock timeout (seconds) - configurable via env
: "${GROQBASHGUILOCKTIMEOUT:=10}"

# -------------------------
# Logging and rotation
# -------------------------
log_info() {
  local code msg
  if [ "$#" -eq 1 ]; then
    code="INFO"
    msg="$1"
  else
    code="${1:-INFO}"
    msg="${2:-}"
  fi
  mkdir -p "$(dirname "$SERVER_LOG")" 2>/dev/null || true
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
  mkdir -p "$(dirname "$SERVER_LOG")" 2>/dev/null || true
  printf 'groqbash: WARN: %s: %s\n' "$code" "$msg" >>"$SERVER_LOG" 2>/dev/null || true
}

log_error() {
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
  if [[ -z "$dir" || ! -d "$dir" || ! -w "$dir" ]]; then
    return 1
  fi
  if command -v mktemp >/dev/null 2>&1; then
    if mktemp --help >/dev/null 2>&1; then
      if tmp="$(mktemp --tmpdir="$dir" "$template" 2>/dev/null)"; then
        printf '%s' "$tmp"
        return 0
      fi
    fi
    if tmp="$(mktemp "$dir/$template" 2>/dev/null)"; then
      printf '%s' "$tmp"
      return 0
    fi
  fi
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
    ( set -C; : >"$candidate" ) 2>/dev/null && { printf '%s' "$candidate"; return 0; } || true
    i=$((i+1))
  done
  log_error "GUIIO" "mktemp_portable failed to create temp file in $dir"
  return 1
}

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

atomic_append_conv_in_uiroot() {
  # Usage: atomic_append_conv_in_uiroot <convfile> <<'EOF' ... EOF
  local convfile="$1"
  if [[ -z "$convfile" ]]; then
    return 1
  fi

  # Ensure destination dir exists
  local dir tmpf
  dir="$(dirname -- "$convfile")"
  mkdir -p -- "$dir" 2>/dev/null || true

  # Create a tmp file in the same directory to preserve filesystem semantics
  tmpf="${convfile}.tmp.$$"

  # If conversation exists, copy it to tmp (preserve mode if possible)
  if [[ -f "$convfile" ]]; then
    cp -a -- "$convfile" "$tmpf" 2>/dev/null || : 
  else
    : >"$tmpf"
  fi

  # Append raw stdin to tmp file (no sed, no substitution)
  cat >> "$tmpf"

  # Atomically replace the conversation file
  mv -f -- "$tmpf" "$convfile"
  chmod 600 "$convfile" || true
  return 0
}

# -------------------------
# flock availability and lock management (fd 9)
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
  if ! flock -x -w "$GROQBASHGUILOCKTIMEOUT" 9; then
    log_error "LOCKTIMEOUT" "could not acquire GUI lock on $LOCK_FILE within ${GROQBASHGUILOCKTIMEOUT}s"
    print_http_error "503 Service Unavailable" "Server busy; please retry"
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
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}
html_escape_stream() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}

# -------------------------
# Validation and sanitization
# -------------------------
validate_name() {
  local name="$1"
  [[ -z "$name" ]] && return 1
  [[ "$name" == "." || "$name" == ".." ]] && return 1
  # reject path separators and backslash (NUL cannot practically appear in shell vars)
  [[ "$name" == *"/"* || "$name" == *"\\"* ]] && return 1
  # reject control characters (0x00-0x1F)
  if printf '%s' "$name" | awk '/[[:cntrl:]]/ { exit 0 } END { exit 1 }'; then
    return 1
  fi
  # allow letters, digits, dot, underscore, hyphen; disallow leading dot (hidden files)
  if [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    (( ${#name} <= MAX_NAME_LEN )) || return 1
    return 0
  fi
  return 1
}

sanitize_param() {
  local v="$1"
  v="$(printf '%s' "$v" | tr -d '\000-\011\013\014\016-\037' | tr '\t' ' ' | sed -E 's/  +/ /g')"
  printf '%s' "$v"
}

sanitize_model_output() {
  local v max=10000
  v="${1:-}"
  # strip ANSI escape sequences (single sed expression)
  v="$(printf '%s' "$v" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')"
  # remove control chars and normalize newlines
  v="$(printf '%s' "$v" | tr -d '\000-\010\013\014\016-\037' | sed -e 's/\r$//' -e 's/\r\n/\n/g')"
  # collapse tabs/spaces and trim
  v="$(printf '%s' "$v" | tr '\t' ' ' | sed -E 's/  +/ /g')"
  v="$(printf '%s' "$v" | sed -E 's/^[ \t]+//; s/[ \t]+$//')"
  if [ "${#v}" -gt "$max" ]; then
    v="${v:0:max}"
    v="$v\n\n[TRUNCATED]"
  fi
  # IMPORTANT: do NOT HTML-escape here; conversation files must contain plain text.
  printf '%s' "$v"
}

# Build CURRENT_CONV as safe HTML for insertion into templates.
# Reads the current conversation file (plain text), sanitizes each line,
# removes any literal "{{CURRENT_CONV}}" tokens that may appear in model output,
# escapes HTML entities and preserves newlines by wrapping content in <pre>.
# Usage: build_current_conv_block [convfile]
build_current_conv_block() {
  local convfile line out htmlbuf
  convfile="${1:-$(get_current_conversation_file || true)}"
  if [[ -z "$convfile" || ! -f "$convfile" ]]; then
    CURRENT_CONV=""
    return 0
  fi

  htmlbuf=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    # remove accidental template tokens that may come from model output
    line="${line//\{\{CURRENT_CONV\}\}/ }"
    # optional: decode double-escaped numeric entities if html_unescape exists
    if type html_unescape >/dev/null 2>&1; then
      line="$(html_unescape "$line")"
    fi
    # sanitize (remove control chars / ANSI) but do NOT HTML-escape here
    out="$(sanitize_model_output "$line")"
    # now escape for HTML insertion
    out="$(html_escape "$out")"
    htmlbuf+="${out}"$'\n'
  done < "$convfile"

  CURRENT_CONV="<pre>$(printf '%s' "$htmlbuf")</pre>"
  return 0
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
# Language file helpers (bootstrap-level)
# - find_lang_conf: locate gui-lang.conf
# - read_txt_key: read TXT_KEY.lang value
# -------------------------
find_lang_conf() {
  local candidates=(
    "${CFG_DIR:-/data/data/com.termux/files/home/groqbash/etc}/gui-lang.conf"
    "${UI_ROOT:-/data/data/com.termux/files/home/groqbash/groqbash.d/extras/ui}/gui-lang.conf"
    "${UI_ROOT:-/data/data/com.termux/files/home/groqbash/groqbash.d/extras/ui}/extras/ui/gui-lang.conf"
    "${UI_ROOT:-/data/data/com.termux/files/home/groqbash/groqbash.d/extras/ui}/static/gui-lang.conf"
    "${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)}/gui-lang.conf"
    "$HOME/.config/groqbash/gui-lang.conf"
    "$UI_ROOT/../gui-lang.conf"
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -r "$c" ]]; then
      printf '%s' "$c"
      return 0
    fi
  done
  return 1
}

read_txt_key() {
  local key="$1" lang="$2" lang_conf val default_lang
  lang_conf="$(find_lang_conf || true)"
  if [[ -z "$lang_conf" ]]; then
    printf ''
    return 0
  fi

  val="$(awk -F= -v k="${key}.${lang}" '
    $1 == k {
      sub(/^[^=]*=/, "", $0)
      print $0
      exit
    }
  ' "$lang_conf" 2>/dev/null || true)"

  if [[ -n "$val" ]]; then
    printf '%s' "$val"
    return 0
  fi

  default_lang="$(awk -F= '$1=="DEFAULT_LANG" {print $2; exit}' "$lang_conf" 2>/dev/null || true)"
  if [[ -n "$default_lang" ]]; then
    val="$(awk -F= -v k="${key}.${default_lang}" '
      $1 == k {
        sub(/^[^=]*=/, "", $0)
        print $0
        exit
      }
    ' "$lang_conf" 2>/dev/null || true)"
    printf '%s' "$val"
    return 0
  fi

  printf ''
}

# -------------------------
# Template rendering helper
# -------------------------
render_template() {
  local file="$1"
  shift || true
  if [[ ! -f "$file" ]]; then return 1; fi

  local lang_arg="${1:-}"
  local content
  content="$(cat "$file")" || content=""

  # Pre-generated HTML placeholders (do not escape)
  content="${content//\{\{MODEL_OPTIONS\}\}/$MODEL_OPTIONS}"
  content="${content//\{\{CONV_LIST\}\}/$CONV_LIST}"

  content="${content//\{\{LANG_OPTIONS\}\}/$LANG_OPTIONS}"

  # Runtime placeholders: escape here (but NOT CURRENT_CONV)
  local esc_LANG_CODE esc_THEME esc_PROVIDER_CURRENT esc_MODEL_CURRENT esc_API_KEY_FIELD
  local esc_THEME_IS_light esc_THEME_IS_dark esc_MODEL_WHITELIST_PRESENT esc_CURRENT_CONV_FILE esc_CONFIGURED

  esc_LANG_CODE="$(html_escape "${LANG_CODE:-}")"
  esc_THEME="$(html_escape "${THEME:-}")"
  esc_PROVIDER_CURRENT="$(html_escape "${PROVIDER_CURRENT:-}")"
  esc_MODEL_CURRENT="$(html_escape "${MODEL_CURRENT:-}")"
  esc_API_KEY_FIELD="$(html_escape "${API_KEY_FIELD:-}")"
  esc_THEME_IS_light="$(html_escape "${THEME_IS_light:-}")"
  esc_THEME_IS_dark="$(html_escape "${THEME_IS_dark:-}")"
  esc_MODEL_WHITELIST_PRESENT="$(html_escape "${MODEL_WHITELIST_PRESENT:-}")"
  esc_CURRENT_CONV_FILE="$(html_escape "${CURRENT_CONV_FILE:-}")"
  esc_CONFIGURED="$(html_escape "${CONFIGURED:-}")"

  content="${content//\{\{LANG_CODE\}\}/$esc_LANG_CODE}"
  content="${content//\{\{THEME\}\}/$esc_THEME}"
  content="${content//\{\{PROVIDER_CURRENT\}\}/$esc_PROVIDER_CURRENT}"
  content="${content//\{\{MODEL_CURRENT\}\}/$esc_MODEL_CURRENT}"
  content="${content//\{\{API_KEY_FIELD\}\}/$esc_API_KEY_FIELD}"
  content="${content//\{\{THEME_IS_light\}\}/$esc_THEME_IS_light}"
  content="${content//\{\{THEME_IS_dark\}\}/$esc_THEME_IS_dark}"
  content="${content//\{\{MODEL_WHITELIST_PRESENT\}\}/$esc_MODEL_WHITELIST_PRESENT}"
  content="${content//\{\{CURRENT_CONV_FILE\}\}/$esc_CURRENT_CONV_FILE}"
  content="${content//\{\{CONFIGURED\}\}/$esc_CONFIGURED}"

  # Localization placeholders {{TXT_KEY}}
  local txt_keys
  txt_keys="$(awk '{
    while (match($0,/\{\{TXT_[A-Za-z0-9_]+\}\}/)) {
      k=substr($0,RSTART+2,RLENGTH-4);
      print k;
      $0=substr($0,RSTART+RLENGTH);
    }
  }' "$file" | sort -u || true)"
  if [[ -n "$txt_keys" ]]; then
    local k val
    for k in $txt_keys; do
      val=''
      if [[ -n "${!k:-}" ]]; then
        val="${!k}"
      else
        local lang_clean
        lang_clean="$(sanitize_param "$lang_arg")"
        if [[ -z "$lang_clean" ]]; then lang_clean="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"; fi
        val="$(read_txt_key "$k" "$lang_clean" || true)"
      fi
      val="$(html_escape "$val")"
      content="${content//\{\{$k\}\}/$val}"
    done
  fi

  # Positional replacements
  local i=1 arg esc
  for arg in "$@"; do
    esc="$(html_escape "$arg")"
    content="${content//\{\{$i\}\}/$esc}"
    i=$((i+1))
  done

  # Insert CURRENT_CONV last, after all other replacements, to avoid double-mangling
  # CURRENT_CONV is expected to be pre-built HTML (via build_current_conv_block)
  content="${content//\{\{CURRENT_CONV\}\}/$CURRENT_CONV}"

  printf '%s' "$content"
  return 0
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

# Return the current conversation file path; if invalid, fallback to conv-001.txt
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

# IMPORTANT: return empty string when no default is set (GUI must treat empty as "not configured")
get_default_model() { read_config_or_default "$DEFAULT_MODEL_FILE" ""; }
get_default_provider() { read_config_or_default "$DEFAULT_PROVIDER_FILE" ""; }

# -------------------------
# API key helpers (secure storage for GUI)
# - store API key in CFG_DIR/api-key with mode 600
# - do NOT expose the key to templates or logs
# -------------------------
provider_api_env_var_name() {
  # Uppercase provider and append _API_KEY (e.g. groq -> GROQ_API_KEY)
  local prov="$1"
  if [[ -z "$prov" ]]; then
    printf '%s' "GROQ_API_KEY"
    return 0
  fi
  printf '%s' "$(printf '%s' "$prov" | tr '[:lower:]' '[:upper:]')_API_KEY"
}

save_api_key_file() {
  local key="$1"
  if [[ -z "$key" ]]; then
    rm -f "$API_KEY_FILE" 2>/dev/null || true
    return 0
  fi
  mkdir -p "$(dirname "$API_KEY_FILE")" 2>/dev/null || true
  atomic_write "$API_KEY_FILE" "$key" || return 1
  chmod 600 "$API_KEY_FILE" || true
  return 0
}

read_api_key_file() {
  if [[ -r "$API_KEY_FILE" ]]; then
    sed -n '1p' "$API_KEY_FILE" 2>/dev/null || printf ''
  else
    printf ''
  fi
}

export_api_key_for_provider() {
  local prov="$1"
  local key
  key="$(read_api_key_file)"
  if [[ -z "$key" ]]; then
    return 1
  fi
  local envname
  envname="$(provider_api_env_var_name "$prov")"
  # Export only in current process environment (CGI request)
  export "$envname"="$key"
  return 0
}

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
# Ensure config defaults (REVISED)
# - Do NOT populate default-model or default-provider with the literal "default".
# - Leave model/provider files empty if not configured; GUI must treat empty as "not configured".
# - Still ensure conversation file exists.
# -------------------------
ensure_config_defaults() {
  local conv_default="conv-001.txt"
  local lang_default="en"

  if [[ ! -f "$CURRENT_CONV_FILE" ]]; then
    atomic_write "$CURRENT_CONV_FILE" "$conv_default" || true
  fi
  if [[ ! -f "$LANG_CURRENT_FILE" ]]; then
    atomic_write "$LANG_CURRENT_FILE" "$lang_default" || true
  fi
  if [[ ! -f "$THEME_CURRENT_FILE" ]]; then
    atomic_write "$THEME_CURRENT_FILE" "light" || true
  fi

  # IMPORTANT: do not write "default" into these files.
  # Create empty files if missing so GUI can detect "not configured" (empty content).
  if [[ ! -f "$DEFAULT_MODEL_FILE" ]]; then
    mkdir -p "$(dirname "$DEFAULT_MODEL_FILE")" 2>/dev/null || true
    : >"$DEFAULT_MODEL_FILE" || true
    chmod 600 "$DEFAULT_MODEL_FILE" || true
  fi
  if [[ ! -f "$DEFAULT_PROVIDER_FILE" ]]; then
    mkdir -p "$(dirname "$DEFAULT_PROVIDER_FILE")" 2>/dev/null || true
    : >"$DEFAULT_PROVIDER_FILE" || true
    chmod 600 "$DEFAULT_PROVIDER_FILE" || true
  fi

  # Ensure conversation file exists and is valid
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
# - normalize GROQBASH_CMD to an absolute path when possible
# -------------------------
ensure_groqbash_available() {
  # If GROQBASH_CMD is a command name or path, try to resolve to absolute path
  if command -v "$GROQBASH_CMD" >/dev/null 2>&1; then
    GROQBASH_CMD="$(command -v "$GROQBASH_CMD")"
    return 0
  fi
  for p in "$UI_ROOT/../groqbash" "$UI_ROOT/../bin/groqbash" "$HOME/groqbash/groqbash" "$HOME/groqbash"; do
    if [[ -x "$p" ]]; then
      GROQBASH_CMD="$p"
      return 0
    fi
  done
  return 1
}

# -------------------------
# Termux helper (best-effort)
# -------------------------
fix_termux_perms() {
  # best-effort: ensure directories have safe perms on Termux
  if [[ -n "${is_termux:-}" && "${is_termux}" == "true" ]]; then
    chmod 700 "$TMP_DIR" 2>/dev/null || true
    chmod 700 "$LOG_DIR" 2>/dev/null || true
    chmod 700 "$CFG_DIR" 2>/dev/null || true
    chmod 700 "$CONV_DIR" 2>/dev/null || true
  fi
  return 0
}

# Expose key variables for gui-server.sh
export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR \
       LOCK_FILE SERVER_LOG ERROR_LOG CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE \
       DEFAULT_MODEL_FILE DEFAULT_PROVIDER_FILE API_KEY_FILE GROQBASH_CMD

# GUI base path for CGI endpoints (ensure trailing slash)
: "${GUI_CGI_BASE:=/groqbash-gui/cgi/}"
# normalize to always end with a single slash
GUI_CGI_BASE="${GUI_CGI_BASE%/}/"
export GUI_CGI_BASE

# End of bootstrap
return 0 2>/dev/null || true
