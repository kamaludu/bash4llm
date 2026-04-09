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

# ---------------------------------------------------------------------------
# Strict dependency check (rigid, only declared requirements)
# If any required tool is missing, abort immediately with a clear error.
# ---------------------------------------------------------------------------
_required_cmds=(bash mv cp chmod rm find flock awk curl jq)
_missing=()
for _c in "${_required_cmds[@]}"; do
  if ! command -v "$_c" >/dev/null 2>&1; then
    _missing+=("$_c")
  fi
done

if [[ ${#_missing[@]} -ne 0 ]]; then
  printf 'groqbash: ERROR: missing required tools: %s\n' "$(printf '%s ' "${_missing[@]}")" >&2
  printf 'groqbash: ERROR: required toolset not available; aborting bootstrap\n' >&2
  exit 1
fi
unset _required_cmds _missing _c

# Prevent double sourcing
if [[ "${__GUI_BOOTSTRAP_LOADED:-}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi
__GUI_BOOTSTRAP_LOADED=1

# ---------------------------------------------------------------------------
# Resolve this script's directory reliably and UI_ROOT
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

if [[ -z "${UI_ROOT:-}" ]]; then
  if [[ "$(basename "$BOOTSTRAP_DIR")" == "cgi-bin" ]]; then
    UI_ROOT="$(cd "$BOOTSTRAP_DIR/.." && pwd -P)"
  else
    UI_ROOT="$BOOTSTRAP_DIR"
  fi
fi

: "${HOME:=${UI_ROOT:-$PWD}}"
export HOME

# ---------------------------------------------------------------------------
# Directories (single source of truth)
# ---------------------------------------------------------------------------
: "${TMP_DIR:="$UI_ROOT/tmp"}"
: "${LOG_DIR:="$UI_ROOT/logs"}"
: "${CFG_DIR:="$UI_ROOT/config"}"
: "${CONV_DIR:="$UI_ROOT/conversations"}"
: "${FILES_DIR:="$UI_ROOT/files"}"
: "${TEMPLATES_DIR:="$UI_ROOT/templates"}"

# Ensure TMP_DIR is the single source of truth; export TMPDIR for compatibility
mkdir -p "$TMP_DIR"
chmod 700 "$TMP_DIR"
export TMPDIR="$TMP_DIR"

# Ensure log dir exists and rotate logs (single format)
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"

export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR

# --- Ensure HOME is defined in non-interactive/CGI environments
if [[ -z "${HOME:-}" ]]; then
  if [[ -n "${UI_ROOT:-}" ]]; then
    HOME="$UI_ROOT"
  else
    HOME="$PWD"
  fi
  export HOME
fi

# --- Template variables defaults (avoid unbound variable under set -u) ---
: "${PROVIDER_OPTIONS:=''}"
: "${MODEL_LIST_SCROLL:=''}"
: "${MODEL_SELECT_OPTIONS:=''}"
: "${MODEL_OPTIONS:=''}"
: "${CONV_LIST:=''}"
: "${LANG_OPTIONS:=''}"
: "${API_KEY_FIELD:=''}"
: "${PROVIDER_CURRENT:=''}"
: "${MODEL_CURRENT:=''}"
: "${LANG_CODE:=''}"
: "${THEME:=''}"
: "${THEME_IS_light:=''}"
: "${THEME_IS_dark:=''}"
: "${MODEL_WHITELIST_PRESENT:=''}"
: "${CURRENT_CONV_FILE:=''}"
: "${CONFIGURED:=''}"

# ---------------------------------------------------------------------------
# Files and defaults
# ---------------------------------------------------------------------------
: "${GROQBASH_CMD:=groqbash}"
: "${GROQBASHGUILOCKTIMEOUT:=10}"

LOCK_FILE="$TMP_DIR/gui.lock"            # CGI lock (conversations)
BOOTSTRAP_LOCK="$TMP_DIR/bootstrap.lock" # bootstrap lock (wrapper/shadow)
SERVER_LOG="$LOG_DIR/server.log"
ERROR_LOG="$LOG_DIR/errors.log"
BOOTSTRAP_LOG="$LOG_DIR/bootstrap.log"

CURRENT_CONV_FILE="$CFG_DIR/current-conversation"
LANG_CURRENT_FILE="$CFG_DIR/lang-current"
THEME_CURRENT_FILE="$CFG_DIR/gui-theme"
DEFAULT_MODEL_FILE="$CFG_DIR/default-model"
DEFAULT_PROVIDER_FILE="$CFG_DIR/default-provider"
API_KEY_FILE="$CFG_DIR/api-key"

LOCK_HELD=0

# ---------------------------------------------------------------------------
# Logging helpers (single format: ISO UTC timestamp) and rotation helper
# ---------------------------------------------------------------------------
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

log_info() {
  local code msg
  if [ "$#" -eq 1 ]; then code="INFO"; msg="$1"; else code="${1:-INFO}"; msg="${2:-}"; fi
  mkdir -p "$(dirname "$SERVER_LOG")"
  printf '%s groqbash: INFO: %s: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$code" "$msg" >>"$SERVER_LOG"
}

log_warn() {
  local code msg
  if [ "$#" -eq 1 ]; then code="WARN"; msg="$1"; else code="${1:-WARN}"; msg="${2:-}"; fi
  mkdir -p "$(dirname "$SERVER_LOG")"
  printf '%s groqbash: WARN: %s: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$code" "$msg" >>"$SERVER_LOG"
}

log_error() {
  local code msg
  if [ "$#" -eq 1 ]; then code="ERROR"; msg="$1"; else code="${1:-ERROR}"; msg="${2:-}"; fi
  mkdir -p "$(dirname "$ERROR_LOG")"
  printf '%s groqbash: ERROR: %s: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$code" "$msg" >>"$ERROR_LOG"
}

# rotate server and bootstrap logs at startup
log_rotate_if_needed "$SERVER_LOG" 1048576
log_rotate_if_needed "$BOOTSTRAP_LOG" 1048576

# ---------------------------------------------------------------------------
# mktemp_portable (MANDATORY: uses TMP_DIR or provided dir; disallows /tmp)
# ---------------------------------------------------------------------------
mktemp_portable() {
  # Usage: mktemp_portable <dir> <template>
  local dir="$1" template="$2"
  local dir_real base rand i tmpname candidate

  if [[ -z "$dir" || -z "$template" ]]; then
    return 1
  fi

  dir_real="$(cd "$dir" 2>/dev/null && pwd -P || true)"
  if [[ -z "$dir_real" || ! -d "$dir_real" || ! -w "$dir_real" ]]; then
    return 1
  fi

  # Enforce that dir is inside TMP_DIR
  case "$dir_real" in
    "$TMP_DIR"/*|"$TMP_DIR") ;;
    *) return 1 ;;
  esac

  base="$(date +%s%N 2>/dev/null || printf '%s' "$$")"
  i=0
  while (( i < 200 )); do
    rand="${base}.$RANDOM.$$.$i"
    if [[ "$template" == *"XXXXXX"* ]]; then
      tmpname="${template//XXXXXX/$rand}"
    else
      tmpname="${template}.$rand"
    fi
    candidate="$dir_real/$tmpname"
    ( set -C; : >"$candidate" ) 2>/dev/null && { printf '%s' "$candidate"; return 0; }
    i=$((i+1))
  done

  log_error "GUIIO" "mktemp_portable failed to create temp file in $dir_real"
  return 1
}

# ---------------------------------------------------------------------------
# compute_hash (support function moved out of Termux bootstrap)
# - signature and logic preserved: ignore shebang, hash content
# ---------------------------------------------------------------------------
compute_hash() {
  local file="$1" tmpf
  [[ -f "$file" ]] || { printf ''; return 0; }
  tmpf="$(mktemp_portable "$TMP_DIR" "hash.XXXXXX")" || { printf ''; return 0; }
  # ignore shebang line if present
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

# ---------------------------------------------------------------------------
# Filesystem helpers
# ---------------------------------------------------------------------------
same_filesystem() {
  local a="$1" b="$2" da db fa fb
  da="$a"; while [[ ! -e "$da" && "$da" != "/" ]]; do da="$(dirname -- "$da")"; done
  db="$b"; while [[ ! -e "$db" && "$db" != "/" ]]; do db="$(dirname -- "$db")"; done
  if [[ ! -e "$da" || ! -e "$db" ]]; then return 1; fi
  fa="$(df -P "$da" 2>/dev/null | awk 'END{print $1}')" || fa=""
  fb="$(df -P "$db" 2>/dev/null | awk 'END{print $1}')" || fb=""
  [[ -n "$fa" && -n "$fb" && "$fa" == "$fb" ]]
}

ensure_tmpdir() {
  if [[ -e "$TMP_DIR" && ! -d "$TMP_DIR" ]]; then
    log_error "GUIIO" "TMP_DIR exists and is not a directory: $TMP_DIR"
    print_http_error "500 Internal Server Error" "Server configuration error: tmpdir invalid"
    return 1
  fi
  if [[ ! -d "$TMP_DIR" ]]; then
    mkdir -p "$TMP_DIR"
    chmod 700 "$TMP_DIR"
  fi
  if [[ ! -w "$TMP_DIR" ]]; then
    log_error "GUIIO" "TMP_DIR $TMP_DIR not writable"
    print_http_error "500 Internal Server Error" "Server configuration error: tmpdir not writable"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Atomic write and append (use mktemp_portable and TMP_DIR)
# ---------------------------------------------------------------------------
atomic_write() {
  local dest="$1" content="${2:-}" dest_dir tmp
  dest_dir="$(dirname -- "$dest")"
  ensure_tmpdir || return 1
  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(mktemp_portable "$TMP_DIR" "atomic.XXXXXX")"; then
    :
  else
    tmp="$(mktemp_portable "$dest_dir" "atomic.XXXXXX")"
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
  if same_filesystem "$TMP_DIR" "$dest_dir" && tmp="$(mktemp_portable "$TMP_DIR" "conv.XXXXXX")"; then
    :
  else
    tmp="$(mktemp_portable "$dest_dir" "conv.XXXXXX")"
  fi
  if [[ -f "$conv_file" ]]; then cat "$conv_file" >"$tmp" || { log_error "GUIIO" "Failed to copy existing conversation to tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }; fi
  printf '%s\n' "$append_text" >>"$tmp" || { log_error "GUIIO" "Failed to append text to tmp"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  mv -f "$tmp" "$conv_file" || { log_error "GUIIO" "mv failed in atomic_append_conv"; rm -f "$tmp" 2>/dev/null || true; return 1; }
  chmod 600 "$conv_file" || true
  return 0
}

atomic_append_conv_in_uiroot() {
  local convfile="$1"
  if [[ -z "$convfile" ]]; then return 1; fi
  local dir tmpf
  dir="$(dirname -- "$convfile")"
  mkdir -p -- "$dir"
  # Use mktemp_portable only; if it fails, fail the function
  tmpf="$(mktemp_portable "$dir" "conv.XXXXXX")" || return 1
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

# ---------------------------------------------------------------------------
# flock availability and CGI lock management (fd 9)
# ---------------------------------------------------------------------------
ensure_flock_available() {
  if ! command -v flock >/dev/null 2>&1; then
    log_error "GUILLOCK" "flock not available on this system; cannot guarantee safe concurrency"
    print_http_error "500 Internal Server Error" "Server misconfiguration: flock not available"
    return 1
  fi
  return 0
}

acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")"
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

# ---------------------------------------------------------------------------
# HTTP helpers and escaping/unescaping
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
  printf '<h1>%s</h1>\n' "$(html_escape "$msg")"
}

html_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}
html_escape_stream() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}

html_unescape_fallback() {
  printf '%s' "$1" | sed -e 's/&amp;#39;/\x27/g' -e "s/&#39;/\x27/g" -e 's/&quot;/"/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/&/g'
}

html_unescape() {
  printf '%s' "$1" \
    | sed -E 's/&#x([0-9A-Fa-f]+);/\\x\1/g' \
    | awk '{
        gsub(/\\x([0-9A-Fa-f]{2})/,"\\x\\1");
        printf "%s", $0
      }' \
    | sed -e 's/&amp;#([0-9]+);/\\\x\1/g' 2>/dev/null || true
  printf '%s' "$1" \
    | sed -e 's/&amp;#39;/\x27/g' -e "s/&#39;/\x27/g" -e 's/&quot;/"/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&amp;/&/g'
}

# ---------------------------------------------------------------------------
# Validation and sanitization
# ---------------------------------------------------------------------------
validate_name() {
  local name="$1"
  [[ -n "$name" ]] || return 1
  [[ "$name" == "." || "$name" == ".." ]] && return 1
  [[ "$name" == *"/"* || "$name" == *"\\"* ]] && return 1
  if printf '%s' "$name" | awk '/[[:cntrl:]]/ { exit 0 } END { exit 1 }'; then return 1; fi
  if [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    (( ${#name} <= 255 )) || return 1
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
  v="$(printf '%s' "$v" | sed -r 's/\x1B

\[[0-9;]*[a-zA-Z]//g')"
  v="$(printf '%s' "$v" | tr -d '\000-\010\013\014\016-\037' | sed -e 's/\r$//' -e 's/\r\n/\n/g')"
  v="$(printf '%s' "$v" | tr '\t' ' ' | sed -E 's/  +/ /g')"
  v="$(printf '%s' "$v" | sed -E 's/^[ \t]+//; s/[ \t]+$//')"
  if [ "${#v}" -gt "$max" ]; then
    v="${v:0:max}"
    v="$v\n\n[TRUNCATED]"
  fi
  printf '%s' "$v"
}

# ---------------------------------------------------------------------------
# Build CURRENT_CONV block
# ---------------------------------------------------------------------------
build_current_conv_block() {
  local convfile line out htmlbuf token
  convfile="${1:-$(get_current_conversation_file || true)}"
  if [[ -z "$convfile" || ! -f "$convfile" ]]; then
    CURRENT_CONV=""
    return 0
  fi
  token='{{CURRENT_CONV}}'
  htmlbuf=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line//${token}/ }"
    if type html_unescape >/dev/null 2>&1; then
      line="$(html_unescape "$line")"
    fi
    out="$(sanitize_model_output "$line")"
    out="$(html_escape "$out")"
    htmlbuf+="${out}"$'\n'
  done < "$convfile"
  CURRENT_CONV="<pre>$(printf '%s' "$htmlbuf")</pre>"
  return 0
}

# ---------------------------------------------------------------------------
# URL / form helpers
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Language file helpers
# ---------------------------------------------------------------------------
find_lang_conf() {
  local candidates=(
    "${CFG_DIR:-$UI_ROOT/config}/gui-lang.conf"
    "${UI_ROOT:-}/gui-lang.conf"
    "${UI_ROOT:-}/extras/ui/gui-lang.conf"
    "${UI_ROOT:-}/static/gui-lang.conf"
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

# ---------------------------------------------------------------------------
# Template rendering helper
# ---------------------------------------------------------------------------
render_template() {
  local file="$1"
  shift || true
  if [[ ! -f "$file" ]]; then return 1; fi
  local lang_arg="${1:-}"
  local content
  content="$(cat "$file")" || content=""

  # Direct HTML fragments (do not HTML-escape these)
  content="${content//\{\{PROVIDER_OPTIONS\}\}/${PROVIDER_OPTIONS:-}}"
  content="${content//\{\{MODEL_LIST_SCROLL\}\}/${MODEL_LIST_SCROLL:-}}"
  content="${content//\{\{MODEL_SELECT_OPTIONS\}\}/${MODEL_SELECT_OPTIONS:-}}"
  content="${content//\{\{MODEL_OPTIONS\}\}/${MODEL_OPTIONS:-}}"
  content="${content//\{\{CONV_LIST\}\}/${CONV_LIST:-}}"
  content="${content//\{\{LANG_OPTIONS\}\}/${LANG_OPTIONS:-}}"

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

  local i=1 arg esc
  for arg in "$@"; do
    esc="$(html_escape "$arg")"
    content="${content//\{\{$i\}\}/$esc}"
    i=$((i+1))
  done

  local token prefix suffix
  token='{{CURRENT_CONV}}'
  if [[ "$content" == *"$token"* ]]; then
    prefix="${content%%$token*}"
    suffix="${content#*$token}"
    content="${prefix}${CURRENT_CONV}${suffix}"
    unset prefix suffix token
  fi

  printf '%s' "$content"
  return 0
}

# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------
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

get_default_model() { read_config_or_default "$DEFAULT_MODEL_FILE" ""; }
get_default_provider() { read_config_or_default "$DEFAULT_PROVIDER_FILE" ""; }

# ---------------------------------------------------------------------------
# API key helpers
# ---------------------------------------------------------------------------
provider_api_env_var_name() {
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
  mkdir -p "$(dirname "$API_KEY_FILE")"
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
  export "$envname"="$key"
  return 0
}

# ---------------------------------------------------------------------------
# Ensure runtime dirs and defaults
# ---------------------------------------------------------------------------
ensure_dirs() {
  mkdir -p "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR"/input "$FILES_DIR"/output "$TEMPLATES_DIR"
  chmod 700 "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR" "$FILES_DIR"/input "$FILES_DIR"/output
  ensure_tmpdir || return 1
  return 0
}

# ---------------------------------------------------------------------------
# Remove unnecessary symlinks inside UI_ROOT (hardened)
# - If cp or mv fails, return error instead of continuing silently.
# ---------------------------------------------------------------------------
remove_unnecessary_symlinks() {
  local ui="$1" target link rc
  [[ -d "$ui" ]] || return 0
  while IFS= read -r -d '' link; do
    target="$(readlink -f "$link" 2>/dev/null || readlink "$link" 2>/dev/null || true)"
    if [[ -z "$target" ]]; then
      rm -f -- "$link" 2>/dev/null || true
      continue
    fi
    case "$target" in
      "$ui"/*)
        if [[ -f "$target" ]]; then
          cp -a -- "$target" "${link}.tmp" || { rm -f -- "${link}.tmp" 2>/dev/null || true; return 1; }
          mv -f -- "${link}.tmp" "$link" || { rm -f -- "${link}.tmp" 2>/dev/null || true; return 1; }
        fi
        ;;
      *)
        ;;
    esac
  done < <(find "$ui" -maxdepth 3 -type l -print0 2>/dev/null)
  return 0
}

# ---------------------------------------------------------------------------
# Ensure .sh executables and static perms
# ---------------------------------------------------------------------------
ensure_sh_executables() {
  local ui="${1:-$UI_ROOT}"
  if [[ -z "$ui" || ! -d "$ui" ]]; then
    log_warn "PERMS" "ensure_sh_executables: UI_ROOT missing or invalid: $ui"
    return 0
  fi
  if [[ -d "$ui/cgi-bin" ]]; then
    find "$ui/cgi-bin" -maxdepth 1 -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
  fi
  find "$ui" -maxdepth 1 -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
  if [[ -d "$ui/static" ]]; then
    find "$ui/static" -type f -exec chmod 644 {} \; 2>/dev/null || true
    chmod 755 "$ui/static" 2>/dev/null || true
  fi
  mkdir -p "$ui/logs" "$ui/var/run/apache2" 2>/dev/null || true
  chmod 700 "$ui/logs" "$ui/var/run/apache2" 2>/dev/null || true
  return 0
}

# ---------------------------------------------------------------------------
# Ensure config defaults
# ---------------------------------------------------------------------------
ensure_config_defaults() {
  local conv_default="conv-001.txt"
  local lang_default="en"
  if [[ ! -f "$CURRENT_CONV_FILE" ]]; then atomic_write "$CURRENT_CONV_FILE" "$conv_default" || true; fi
  if [[ ! -f "$LANG_CURRENT_FILE" ]]; then atomic_write "$LANG_CURRENT_FILE" "$lang_default" || true; fi
  if [[ ! -f "$THEME_CURRENT_FILE" ]]; then atomic_write "$THEME_CURRENT_FILE" "light" || true; fi
  if [[ ! -f "$DEFAULT_MODEL_FILE" ]]; then mkdir -p "$(dirname "$DEFAULT_MODEL_FILE")"; : >"$DEFAULT_MODEL_FILE"; chmod 600 "$DEFAULT_MODEL_FILE" || true; fi
  if [[ ! -f "$DEFAULT_PROVIDER_FILE" ]]; then mkdir -p "$(dirname "$DEFAULT_PROVIDER_FILE")"; : >"$DEFAULT_PROVIDER_FILE"; chmod 600 "$DEFAULT_PROVIDER_FILE" || true; fi
  local conv
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "$conv_default")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then conv="$conv_default"; atomic_write "$CURRENT_CONV_FILE" "$conv" || true; fi
  if [[ ! -f "$CONV_DIR/$conv" ]]; then atomic_write "$CONV_DIR/$conv" "" || true; fi
}

# ---------------------------------------------------------------------------
# Ensure groqbash available (DETERMINISTIC: only allowed locations)
# Allowed locations:
#   $UI_ROOT/../groqbash/groqbash
#   $HOME/groqbash/groqbash
# If not found there, return failure (caller must abort).
# ---------------------------------------------------------------------------
ensure_groqbash_available() {
  # 0) prefer persisted path written by installer
  if [[ -n "${UI_ROOT:-}" ]]; then
    local cfg="$CFG_DIR/groqbash-path"
    if [[ -f "$cfg" ]]; then
      local p
      p="$(sed -n '1p' "$cfg" 2>/dev/null || true)"
      if [[ -n "$p" && -x "$p" ]]; then
        GROQBASH_CMD="$(readlink -f "$p" 2>/dev/null || printf '%s' "$p")"
        export GROQBASH_CMD
        return 0
      else
        log_warn "GUIIO" "Configured groqbash path '$p' not executable; will attempt discovery"
      fi
    fi
  fi

  # 1) Prefer a local wrapper inside UI_ROOT/bin if present
  if [[ -n "${UI_ROOT:-}" ]]; then
    local wrapper_path="${UI_ROOT%/}/bin/groqbash-wrapper"
    if [[ -x "$wrapper_path" ]]; then
      GROQBASH_CMD="$(readlink -f "$wrapper_path" 2>/dev/null || printf '%s' "$wrapper_path")"
      export GROQBASH_CMD
      return 0
    fi
  fi

  # 2) If GROQBASH_CMD already absolute and executable, accept it
  if [[ -n "${GROQBASH_CMD:-}" && "${GROQBASH_CMD}" = /* && -x "${GROQBASH_CMD}" ]]; then
    GROQBASH_CMD="$(readlink -f "$GROQBASH_CMD" 2>/dev/null || printf '%s' "$GROQBASH_CMD")"
    export GROQBASH_CMD
    return 0
  fi

  # 3) Try common locations (PREFIX-aware) and repo locations
  local candidates=(
    "${PREFIX:-/data/data/com.termux/files/usr}/bin/groqbash"
    "/data/data/com.termux/files/usr/bin/groqbash"
    "/usr/local/bin/groqbash"
    "/usr/bin/groqbash"
    "$UI_ROOT/../groqbash/groqbash"
    "$HOME/groqbash/groqbash"
    "$HOME/repo-groqbash/bin/groqbash"
  )
  local p
  for p in "${candidates[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ -x "$p" ]]; then
      GROQBASH_CMD="$(readlink -f "$p" 2>/dev/null || printf '%s' "$p")"
      export GROQBASH_CMD
      # persist discovered path for future runs if config dir writable
      if [[ -n "${CFG_DIR:-}" && -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" ]]; then
        printf '%s\n' "$GROQBASH_CMD" >"${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
        chmod 600 "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
      fi
      return 0
    fi
  done

  # 4) Not found — log clear actionable error
  log_error "GUIIO" "groqbash non trovato: imposta GROQBASH_CMD a un path assoluto eseguibile o crea UI_ROOT/bin/groqbash-wrapper. Controlla installer per aggiornare $CFG_DIR/groqbash-path."
  return 1
}

# ---------------------------------------------------------------------------
# Resolve BASH_PATH once (deterministic for wrapper creation)
# - Do not use command -v inside the wrapper; resolve once here.
# - If not resolvable to an executable, leave empty; create_termux_compat_bootstrap will fail.
# ---------------------------------------------------------------------------
BASH_PATH="$(command -v bash 2>/dev/null || true)"
if [[ -n "$BASH_PATH" && ! -x "$BASH_PATH" ]]; then
  BASH_PATH=""
fi

# ---------------------------------------------------------------------------
# Minimal Termux wrapper + shadow update (uses BOOTSTRAP_LOCK; local trap avoided)
# - Only: determine groqbash_real; update shadow if necessary; create wrapper in UI_ROOT/bin
# - No global trap changes; no fallback to arbitrary paths.
# ---------------------------------------------------------------------------
create_termux_compat_bootstrap() {
  [[ -d "/data/data/com.termux/files/usr" ]] || return 0
  [[ -n "${UI_ROOT:-}" ]] || return 0

  ensure_tmpdir || return 1
  if ! command -v flock >/dev/null 2>&1; then return 1; fi

  local groqbash_real groqbash_shadow BIN_DIR wrapper tmp_shadow rc real_hash shadow_hash
  groqbash_shadow="/data/data/com.termux/files/usr/bin/groqbash"

  # Deterministic allowed locations
  local candidates=("$UI_ROOT/../groqbash/groqbash" "$HOME/groqbash/groqbash")
  groqbash_real=""
  for p in "${candidates[@]}"; do
    if [[ -x "$p" ]]; then groqbash_real="$p"; break; fi
  done
  if [[ -z "$groqbash_real" ]]; then
    return 1
  fi

  # Acquire bootstrap lock (fd 9) local to this function
  exec 9>"$BOOTSTRAP_LOCK" 2>/dev/null || return 1
  if ! flock -x -w 5 9; then exec 9>&- 2>/dev/null || return 1; fi

  # Use compute_hash (moved out)
  real_hash="$(compute_hash "$groqbash_real")"
  shadow_hash="$(compute_hash "$groqbash_shadow")"

  if [[ -z "$shadow_hash" || "$real_hash" != "$shadow_hash" ]]; then
    tmp_shadow="$(mktemp_portable "$TMP_DIR" "groqbash-shadow.XXXXXX")" || tmp_shadow=""
    if [[ -n "$tmp_shadow" ]]; then
      cp -f -- "$groqbash_real" "$tmp_shadow" || { flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true; return 1; }
      mv -f -- "$tmp_shadow" "$groqbash_shadow" || { rm -f -- "$tmp_shadow" 2>/dev/null || true; flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true; return 1; }
      rc=0
    else
      cp -f -- "$groqbash_real" "$groqbash_shadow" || { flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true; return 1; }
      rc=$?
    fi
    if (( rc != 0 )); then
      flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true
      return 1
    fi
    chmod 750 "$groqbash_shadow" 2>/dev/null || true
  fi

  # Ensure BASH_PATH is resolved and executable before creating wrapper
  if [[ -z "${BASH_PATH:-}" || ! -x "$BASH_PATH" ]]; then
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
    return 1
  fi

  # Create wrapper in UI_ROOT/bin pointing to shadow using resolved BASH_PATH
  BIN_DIR="${UI_ROOT%/}/bin"
  mkdir -p "$BIN_DIR"
  chmod 700 "$BIN_DIR"
  wrapper="$BIN_DIR/groqbash-wrapper"
  printf '%s\n' "#!$BASH_PATH" "exec \"$BASH_PATH\" \"$groqbash_shadow\" \"\$@\"" >"$wrapper"
  chmod 750 "$wrapper"

  # release lock
  flock -u 9 2>/dev/null || true
  exec 9>&- 2>/dev/null || true

  export GROQBASH_CMD="$wrapper"
  export PATH="$BIN_DIR:${PATH:-}"
  return 0
}

# ---------------------------------------------------------------------------
# Termux perms best-effort
# ---------------------------------------------------------------------------
fix_termux_perms() {
  if [[ -d "/data/data/com.termux/files/usr" ]]; then
    chmod 700 "$TMP_DIR" 2>/dev/null || true
    chmod 700 "$LOG_DIR" 2>/dev/null || true
    chmod 700 "$CFG_DIR" 2>/dev/null || true
    chmod 700 "$CONV_DIR" 2>/dev/null || true
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Final initialization sequence (strict order)
# ---------------------------------------------------------------------------
ensure_dirs || { log_error "INIT" "ensure_dirs failed"; return 1 2>/dev/null || exit 1; }
ensure_sh_executables "$UI_ROOT" || true
remove_unnecessary_symlinks "$UI_ROOT" || true
ensure_config_defaults || true
fix_termux_perms || true

if ! ensure_groqbash_available; then
  log_error "GROQ" "groqbash binary not found in allowed locations; aborting"
  printf 'groqbash: ERROR: groqbash binary not found; aborting\n' >&2
  return 1 2>/dev/null || exit 1
fi

# Call Termux compat bootstrap now that UI_ROOT/TMP_DIR are stable
create_termux_compat_bootstrap || log_warn "BOOTSTRAP" "create_termux_compat_bootstrap failed or not applicable"

# Export key variables for gui-server.sh
export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR \
       LOCK_FILE SERVER_LOG ERROR_LOG CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE \
       DEFAULT_MODEL_FILE DEFAULT_PROVIDER_FILE API_KEY_FILE GROQBASH_CMD

# End of bootstrap
return 0 2>/dev/null || true
