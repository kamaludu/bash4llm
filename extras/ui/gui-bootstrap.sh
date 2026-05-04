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
# Resolve this script's directory reliably and UI_ROOT (minimal derivation)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
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

: "${UI_ROOT:=${UI_ROOT:-}}"
if [[ -z "${UI_ROOT:-}" ]]; then
  if [[ "$(basename "$BOOTSTRAP_DIR")" == "cgi-bin" ]]; then
    UI_ROOT="$(cd "$BOOTSTRAP_DIR/.." 2>/dev/null && pwd -P || printf '%s' "$BOOTSTRAP_DIR")"
  else
    UI_ROOT="$BOOTSTRAP_DIR"
  fi
fi
export UI_ROOT

# ---------------------------------------------------------------------------
# Strict dependency check (rigid, only declared requirements)
# If any required tool is missing, abort immediately with a clear error.
# (Use direct stderr prints here because logging layer may not be initialized yet)
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

# ---------------------------------------------------------------------------
# Source centralized environment layer and initialize (centralized logging/traps)
# ---------------------------------------------------------------------------
if [[ -f "${UI_ROOT%/}/gui-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${UI_ROOT%/}/gui-env.sh"
  gui_env_init cli
elif [[ -f "${SCRIPT_DIR%/}/gui-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR%/}/gui-env.sh"
  gui_env_init cli
else
  printf 'groqbash: ERROR: required file gui-env.sh missing in UI_ROOT (%s); aborting\n' "${UI_ROOT:-<unset>}" >&2
  exit 1
fi

# Prevent double sourcing
if [[ "${__GUI_BOOTSTRAP_LOADED:-}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi
__GUI_BOOTSTRAP_LOADED=1

# ---------------------------------------------------------------------------
# Ensure HOME is defined in non-interactive/CGI environments
# ---------------------------------------------------------------------------
: "${HOME:=${UI_ROOT:-$PWD}}"
export HOME

# ---------------------------------------------------------------------------
# Directories (single source of truth)
# These defaults are permissive only if not already set by gui-env or caller.
# ---------------------------------------------------------------------------
: "${TMP_DIR:=${TMP_DIR:-${UI_ROOT%/}/tmp}}"
: "${LOG_DIR:=${LOG_DIR:-${UI_ROOT%/}/logs}}"
: "${CFG_DIR:=${CFG_DIR:-${UI_ROOT%/}/config}}"
: "${CONV_DIR:=${CONV_DIR:-${UI_ROOT%/}/conversations}}"
: "${FILES_DIR:=${FILES_DIR:-${UI_ROOT%/}/files}}"
: "${TEMPLATES_DIR:=${TEMPLATES_DIR:-${UI_ROOT%/}/templates}}"

# Ensure TMP_DIR is the single source of truth; export TMPDIR for compatibility
mkdir -p "$TMP_DIR" 2>/dev/null || true
chmod 700 "$TMP_DIR" 2>/dev/null || true
export TMPDIR="$TMP_DIR"

# Ensure log dir exists (gui-env may have already created it)
mkdir -p "$LOG_DIR" 2>/dev/null || true
chmod 700 "$LOG_DIR" 2>/dev/null || true

export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR

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
# Files and defaults (do not override values set by gui-env)
# ---------------------------------------------------------------------------
: "${GROQBASH_CMD:=${GROQBASH_CMD:-groqbash}}"
: "${GROQBASHGUILOCKTIMEOUT:=10}"

LOCK_FILE="${LOCK_FILE:-${TMP_DIR%/}/gui.lock}"            # CGI lock (conversations)
BOOTSTRAP_LOCK="${BOOTSTRAP_LOCK:-${TMP_DIR%/}/bootstrap.lock}" # bootstrap lock (wrapper/shadow)
SERVER_LOG="${SERVER_LOG:-${LOG_DIR%/}/server.log}"
ERROR_LOG="${ERROR_LOG:-${LOG_DIR%/}/errors.log}"
BOOTSTRAP_LOG="${BOOTSTRAP_LOG:-${LOG_DIR%/}/bootstrap.log}"

CURRENT_CONV_FILE="${CURRENT_CONV_FILE:-${CFG_DIR%/}/current-conversation}"
LANG_CURRENT_FILE="${LANG_CURRENT_FILE:-${CFG_DIR%/}/lang-current}"
THEME_CURRENT_FILE="${THEME_CURRENT_FILE:-${CFG_DIR%/}/gui-theme}"
DEFAULT_MODEL_FILE="${DEFAULT_MODEL_FILE:-${CFG_DIR%/}/default-model}"
DEFAULT_PROVIDER_FILE="${DEFAULT_PROVIDER_FILE:-${CFG_DIR%/}/default-provider}"
API_KEY_FILE="${API_KEY_FILE:-${CFG_DIR%/}/api-key}"

LOCK_HELD=0

# ---------------------------------------------------------------------------
# flock availability and CGI lock management (fd 9)
# ---------------------------------------------------------------------------
ensure_flock_available() {
  if ! command -v flock >/dev/null 2>&1; then
    log_error "GUILLOCK" "flock not available on this system; cannot guarantee safe concurrency"
    return 1
  fi
  return 0
}

acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null || true
  exec 9>"$LOCK_FILE"
  if ! flock -x -w "$GROQBASHGUILOCKTIMEOUT" 9; then
    log_error "LOCKTIMEOUT" "could not acquire GUI lock on $LOCK_FILE within ${GROQBASHGUILOCKTIMEOUT}s"
    exec 9>&- || true
    LOCK_HELD=0
    return 1
  fi
  LOCK_HELD=1
  # Do not install global traps here; gui-env.sh manages traps centrally.
  return 0
}

release_lock() {
  if [[ "$LOCK_HELD" -eq 1 ]]; then
    exec 9>&- || true
    LOCK_HELD=0
  fi
}

# ---------------------------------------------------------------------------
# HTML escaping/unescaping and helpers (kept local)
# ---------------------------------------------------------------------------
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
# validate_name <name> [maxlen]
# Accepts letters, digits, dot, underscore, hyphen; no slashes, no control chars; max 255 chars.
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

# sanitize_param <value> [maxlen]
# - rimuove NUL e control chars, normalizza whitespace, trim, collapse spazi, applica maxlen
sanitize_param() {
  local v="${1:-}"
  local maxlen="${2:-256}"
  # remove NUL and control chars except tab/newline/space
  v="$(printf '%s' "$v" | tr -d '\000' | tr -d '\013\014' | sed -E 's/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+/ /g')"
  # normalize tabs to space, collapse multiple spaces
  v="$(printf '%s' "$v" | tr '\t' ' ' | sed -E 's/  +/ /g')"
  # trim leading/trailing whitespace
  v="$(printf '%s' "$v" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  # enforce max length
  if (( ${#v} > maxlen )); then
    v="${v:0:maxlen}"
  fi
  printf '%s' "$v"
}

sanitize_model_output() {
  local v="${1:-}"
  local max="${2:-10000}"
  # remove ANSI escape sequences
  v="$(printf '%s' "$v" | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g')"
  # remove control chars except newline and tab/space, normalize CRLF
  v="$(printf '%s' "$v" | tr -d '\000-\010\013\014\016-\037' | sed -e 's/\r$//' -e 's/\r\n/\n/g')"
  # normalize tabs and collapse spaces
  v="$(printf '%s' "$v" | tr '\t' ' ' | sed -E 's/  +/ /g')"
  # trim
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
  local len="${CONTENT_LENGTH:-}"
  if [[ -n "$len" && "$len" =~ ^[0-9]+$ && "$len" -gt 0 ]]; then
    if command -v head >/dev/null 2>&1; then
      head -c "$len"
    else
      dd bs=1 count="$len" 2>/dev/null || true
    fi
    return 0
  fi

  # CONTENT_LENGTH missing or zero: log via centralized logger and fallback to read-all
  log_warn "GUIIO" "CONTENT_LENGTH missing or zero for POST; falling back to read-all"
  cat
  return 0
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
# Language file helpers (kept)
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
# Template rendering helper (kept)
# ---------------------------------------------------------------------------
render_template() {
  local file="$1"
  shift || true
  if [[ ! -f "$file" ]]; then return 1; fi
  local lang_arg="${1:-}"
  local content
  content="$(cat "$file")" || content=""

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
  export "$envname"="$key"
  return 0
}

# ---------------------------------------------------------------------------
# Ensure runtime dirs and defaults
# ---------------------------------------------------------------------------
ensure_dirs() {
  mkdir -p "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR"/input "$FILES_DIR"/output "$TEMPLATES_DIR" 2>/dev/null || true
  chmod 700 "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR" "$FILES_DIR"/input "$FILES_DIR"/output 2>/dev/null || true
  ensure_tmpdir || return 1
  return 0
}

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

ensure_config_defaults() {
  local conv_default="conv-001.txt"
  local lang_default="en"
  if [[ ! -f "$CURRENT_CONV_FILE" ]]; then atomic_write "$CURRENT_CONV_FILE" "$conv_default" || true; fi
  if [[ ! -f "$LANG_CURRENT_FILE" ]]; then atomic_write "$LANG_CURRENT_FILE" "$lang_default" || true; fi
  if [[ ! -f "$THEME_CURRENT_FILE" ]]; then atomic_write "$THEME_CURRENT_FILE" "light" || true; fi
  if [[ ! -f "$DEFAULT_MODEL_FILE" ]]; then mkdir -p "$(dirname "$DEFAULT_MODEL_FILE")" 2>/dev/null || true; : >"$DEFAULT_MODEL_FILE"; chmod 600 "$DEFAULT_MODEL_FILE" || true; fi
  if [[ ! -f "$DEFAULT_PROVIDER_FILE" ]]; then mkdir -p "$(dirname "$DEFAULT_PROVIDER_FILE")" 2>/dev/null || true; : >"$DEFAULT_PROVIDER_FILE"; chmod 600 "$DEFAULT_PROVIDER_FILE" || true; fi
  local conv
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "$conv_default")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then conv="$conv_default"; atomic_write "$CURRENT_CONV_FILE" "$conv" || true; fi
  if [[ ! -f "$CONV_DIR/$conv" ]]; then atomic_write "$CONV_DIR/$conv" "" || true; fi
}

# ---------------------------------------------------------------------------
# Ensure groqbash available (DETERMINISTIC: discovery-only)
# ---------------------------------------------------------------------------
ensure_groqbash_available() {
  if [[ -n "${UI_ROOT:-}" && -n "${CFG_DIR:-}" ]]; then
    local cfg="${CFG_DIR%/}/groqbash-path"
    if [[ -f "$cfg" ]]; then
      local p
      p="$(sed -n '1p' "$cfg" 2>/dev/null || true)"
      if [[ -n "$p" && -x "$p" ]]; then
        case "$p" in
          "${UI_ROOT%/}/bin/"*|*/groqbash.d/extras/ui/bin/*|"$PWD/"* )
            GROQBASH_CMD="$(readlink -f "$p" 2>/dev/null || printf '%s' "$p")"
            export GROQBASH_CMD
            return 0
            ;;
          *)
            log_warn "GUIIO" "Persisted groqbash-path '$p' is not a UI wrapper/repo path; ignoring"
            ;;
        esac
      else
        log_warn "GUIIO" "Configured groqbash path '$p' not executable; will attempt discovery"
      fi
    fi
  fi

  if [[ -n "${UI_ROOT:-}" ]]; then
    local wrapper_path="${UI_ROOT%/}/bin/groqbash-wrapper"
    if [[ -x "$wrapper_path" ]]; then
      GROQBASH_CMD="$(readlink -f "$wrapper_path" 2>/dev/null || printf '%s' "$wrapper_path")"
      export GROQBASH_CMD
      return 0
    fi
  fi

  if [[ -n "${GROQBASH_CMD:-}" && "${GROQBASH_CMD}" = /* && -x "${GROQBASH_CMD}" ]]; then
    GROQBASH_CMD="$(readlink -f "$GROQBASH_CMD" 2>/dev/null || printf '%s' "$GROQBASH_CMD")"
    export GROQBASH_CMD
    return 0
  fi

  local candidates=(
    "${PREFIX:-/data/data/com.termux/files/usr}/bin/groqbash"
    "/data/data/com.termux/files/usr/bin/groqbash"
    "/usr/local/bin/groqbash"
    "/usr/bin/groqbash"
    "$UI_ROOT/../groqbash/groqbash"
    "$HOME/groqbash/groqbash"
    "$HOME/repo-groqbash/bin/groqbash"
    "$PWD/groqbash"
  )
  local p
  for p in "${candidates[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ -x "$p" ]]; then
      GROQBASH_CMD="$(readlink -f "$p" 2>/dev/null || printf '%s' "$p")"
      export GROQBASH_CMD
      log_info "GUIIO" "Discovered groqbash at $GROQBASH_CMD (discovery-only; not persisting)"
      return 0
    fi
  done

  log_error "GUIIO" "groqbash not found: set GROQBASH_CMD to an absolute executable path or create UI_ROOT/bin/groqbash-wrapper."
  return 1
}

# ---------------------------------------------------------------------------
# Resolve BASH_PATH once (deterministic for wrapper creation)
# ---------------------------------------------------------------------------
BASH_PATH="$(command -v bash 2>/dev/null || true)"
if [[ -n "$BASH_PATH" && ! -x "$BASH_PATH" ]]; then
  BASH_PATH=""
fi

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
# Cache refresh helpers (deterministic, single-shot per invocation)
# ---------------------------------------------------------------------------
ensure_provider_cache_fresh() {
  local providers_file="${CFG_DIR%/}/providers.txt"
  local lockfd tmpf out rc
  local lockfile="${BOOTSTRAP_LOCK:-$TMP_DIR/bootstrap.lock}"

  mkdir -p "$(dirname -- "$providers_file")" 2>/dev/null || true

  exec {lockfd}>"$lockfile" 2>/dev/null || return 1
  if ! flock -x -w 5 "$lockfd"; then
    exec {lockfd}>&- 2>/dev/null || true
    return 0
  fi

  if [[ -z "${GROQBASH_CMD:-}" || ! -x "${GROQBASH_CMD}" ]]; then
    flock -u "$lockfd" 2>/dev/null || true
    exec {lockfd}>&- 2>/dev/null || true
    log_warn "PROV" "ensure_provider_cache_fresh: groqbash not available"
    return 0
  fi

  tmpf="$(portable_mktemp "$TMP_DIR" "providers.XXXXXX")" || tmpf=""
  if [[ -n "$tmpf" ]]; then
    "${GROQBASH_CMD}" --list-providers-raw 2>/dev/null | awk 'NF' >"$tmpf" 2>/dev/null || rc=$?
    if [[ -s "$tmpf" ]]; then
      atomic_write "$providers_file" "$(cat "$tmpf")" || true
      chmod 644 "$providers_file" 2>/dev/null || true
      log_info "PROV" "Providers cache refreshed: $providers_file"
    else
      rm -f -- "$tmpf" 2>/dev/null || true
      log_warn "PROV" "Providers refresh produced no data; keeping existing cache"
    fi
  else
    log_warn "PROV" "Could not create tmp file for providers refresh"
  fi

  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&- 2>/dev/null || true
  return 0
}

ensure_model_cache_fresh() {
  local provider="$1"
  if [[ -z "$provider" ]]; then
    log_warn "MODEL" "ensure_model_cache_fresh called without provider"
    return 1
  fi
  if ! validate_name "$provider"; then
    log_warn "MODEL" "Invalid provider name: $provider"
    return 1
  fi

  local models_file="${CFG_DIR%/}/models.${provider}.txt"
  local lockfd tmpf rc
  local lockfile="${BOOTSTRAP_LOCK:-$TMP_DIR/bootstrap.lock}"

  mkdir -p "$(dirname -- "$models_file")" 2>/dev/null || true

  exec {lockfd}>"$lockfile" 2>/dev/null || return 1
  if ! flock -x -w 5 "$lockfd"; then
    exec {lockfd}>&- 2>/dev/null || true
    return 0
  fi

  if [[ -z "${GROQBASH_CMD:-}" || ! -x "${GROQBASH_CMD}" ]]; then
    flock -u "$lockfd" 2>/dev/null || true
    exec {lockfd}>&- 2>/dev/null || true
    log_warn "MODEL" "ensure_model_cache_fresh: groqbash not available"
    return 0
  fi

  tmpf="$(portable_mktemp "$TMP_DIR" "models.${provider}.XXXXXX")" || tmpf=""
  if [[ -n "$tmpf" ]]; then
    "${GROQBASH_CMD}" --list-models-raw --provider "$provider" 2>/dev/null | awk 'NF' >"$tmpf" 2>/dev/null || rc=$?
    if [[ -s "$tmpf" ]]; then
      atomic_write "$models_file" "$(cat "$tmpf")" || true
      chmod 644 "$models_file" 2>/dev/null || true
      log_info "MODEL" "Models cache refreshed for provider '$provider': $models_file"
    else
      rm -f -- "$tmpf" 2>/dev/null || true
      log_warn "MODEL" "Models refresh for '$provider' produced no data; keeping existing cache"
    fi
  else
    log_warn "MODEL" "Could not create tmp file for models refresh for '$provider'"
  fi

  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&- 2>/dev/null || true
  return 0
}

# ---------------------------------------------------------------------------
# Final initialization sequence (strict order)
# ---------------------------------------------------------------------------
env_detect || log_warn "ENV" "env_detect returned non-zero"
ensure_dirs || { log_error "INIT" "ensure_dirs failed"; exit 1; }
ensure_sh_executables "$UI_ROOT" || true
remove_unnecessary_symlinks "$UI_ROOT" || true
ensure_config_defaults || true
fix_termux_perms || true
env_prepare_runtime || log_warn "ENV" "env_prepare_runtime returned non-zero"

if ! ensure_groqbash_available; then
  log_error "GROQ" "groqbash binary not found in allowed locations; aborting"
  printf 'groqbash: ERROR: groqbash binary not found; aborting\n' >&2
  exit 1
fi

env_after_groqbash_resolved || log_warn "ENV" "env_after_groqbash_resolved returned non-zero"

export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR \
       LOCK_FILE SERVER_LOG ERROR_LOG CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE \
       DEFAULT_MODEL_FILE DEFAULT_PROVIDER_FILE API_KEY_FILE GROQBASH_CMD

return 0 2>/dev/null || true
# End of bootstrap
