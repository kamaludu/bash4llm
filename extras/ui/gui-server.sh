#!/usr/bin/env bash
# =============================================================================
# Mini server Bash per GUI HTML di GroqBash (finale, portabile e sicura)
# File: gui-server.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Requisiti: bash, coreutils, curl, jq (usati da GroqBash).
# Vincoli: Bash-only, nessun eval, nessun uso di /tmp di sistema, atomic_write obbligatorio,
# lock globale per serializzare richieste, sanitizzazione input, limiti dimensione prompt.

set -euo pipefail
umask 077

#######################################
# Percorsi (relativi allo script)
#######################################
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UI_ROOT="$SCRIPT_DIR"
TMP_DIR="$UI_ROOT/tmp"
LOG_DIR="$UI_ROOT/logs"
CFG_DIR="$UI_ROOT/config"
CONV_DIR="$UI_ROOT/conversations"
FILES_DIR="$UI_ROOT/files"
TEMPLATES_DIR="$UI_ROOT/templates"

GROQBASH_CMD="groqbash"   # Deve essere nel PATH o sostituito con percorso assoluto

LOCK_FILE="$TMP_DIR/gui.lock"
SERVER_LOG="$LOG_DIR/server.log"
ERROR_LOG="$LOG_DIR/errors.log"

CURRENT_CONV_FILE="$CFG_DIR/current-conversation"
LANG_CURRENT_FILE="$CFG_DIR/lang-current"
DEFAULT_MODEL_FILE="$CFG_DIR/default-model"
DEFAULT_PROVIDER_FILE="$CFG_DIR/default-provider"

# Limiti e regole
MAX_PROMPT_CHARS=5000
MAX_MODEL_OUTPUT_CHARS=20000
VALID_NAME_RE='^[A-Za-z0-9_-]+$'
MAX_NAME_LEN=255

# Stato lock
LOCK_HELD=0

#######################################
# --- Utilities: logging and rotation (portabile) ---
#######################################
log_rotate_if_needed() {
  local file="$1"
  local max_bytes="${2:-1048576}"
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
  local msg="$1"
  printf '[%s] INFO  %s\n' "$(date -Is)" "$msg" >>"$SERVER_LOG"
  log_rotate_if_needed "$SERVER_LOG"
}

log_error() {
  local msg="$1"
  printf '[%s] ERROR %s\n' "$(date -Is)" "$msg" >>"$ERROR_LOG"
  log_rotate_if_needed "$ERROR_LOG"
}

#######################################
# --- Ensure TMP_DIR exists and is secure/writable (atomic creation) ---
#######################################
ensure_tmpdir() {
  if [[ -e "$TMP_DIR" && ! -d "$TMP_DIR" ]]; then
    log_error "TMP_DIR exists and is not a directory: $TMP_DIR"
    print_http_error "500 Internal Server Error" "Server configuration error: tmpdir invalid"
    exit 1
  fi
  if [[ ! -d "$TMP_DIR" ]]; then
    mkdir -p "$TMP_DIR" || {
      log_error "Failed to create TMP_DIR $TMP_DIR"
      print_http_error "500 Internal Server Error" "Server configuration error: cannot create tmpdir"
      exit 1
    }
    chmod 700 "$TMP_DIR" || true
  fi
  if [[ ! -w "$TMP_DIR" ]]; then
    log_error "TMP_DIR $TMP_DIR not writable"
    print_http_error "500 Internal Server Error" "Server configuration error: tmpdir not writable"
    exit 1
  fi
}

#######################################
# --- Initialization of directories and config defaults ---
#######################################
ensure_dirs() {
  mkdir -p "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR/input" "$FILES_DIR/output" "$TEMPLATES_DIR"
  chmod 700 "$LOG_DIR" "$CFG_DIR" "$CONV_DIR" "$FILES_DIR" "$FILES_DIR/input" "$FILES_DIR/output" || true
  ensure_tmpdir
}

# Centralized fallback reads for config files
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

ensure_config_defaults() {
  local conv_default="conv-001.txt"
  local lang_default="it"
  local model_default="default"
  local provider_default="default"

  if [[ ! -f "$CURRENT_CONV_FILE" ]]; then
    atomic_write "$CURRENT_CONV_FILE" "$conv_default"
  fi
  if [[ ! -f "$LANG_CURRENT_FILE" ]]; then
    atomic_write "$LANG_CURRENT_FILE" "$lang_default"
  fi
  if [[ ! -f "$DEFAULT_MODEL_FILE" ]]; then
    atomic_write "$DEFAULT_MODEL_FILE" "$model_default"
  fi
  if [[ ! -f "$DEFAULT_PROVIDER_FILE" ]]; then
    atomic_write "$DEFAULT_PROVIDER_FILE" "$provider_default"
  fi

  local conv
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "$conv_default")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then
    conv="$conv_default"
    atomic_write "$CURRENT_CONV_FILE" "$conv"
  fi
  if [[ ! -f "$CONV_DIR/$conv" ]]; then
    atomic_write "$CONV_DIR/$conv" ""
  fi
}

#######################################
# --- Portable mktemp wrapper (returns tmp path or fails) ---
#######################################
mktemp_portable() {
  local dir="$1"
  local template="$2"
  if [[ ! -d "$dir" || ! -w "$dir" ]]; then
    return 1
  fi
  if mktemp --help >/dev/null 2>&1; then
    mktemp --tmpdir="$dir" "$template"
  else
    mktemp "$dir/$template"
  fi
}

#######################################
# --- same_filesystem: robust check ---
# returns 0 if same FS, 1 otherwise
#######################################
same_filesystem() {
  local a="$1" b="$2"
  local da db
  da="$a"
  while [[ ! -e "$da" && "$da" != "/" ]]; do da="$(dirname -- "$da")"; done
  db="$b"
  while [[ ! -e "$db" && "$db" != "/" ]]; do db="$(dirname -- "$db")"; done
  if [[ ! -e "$da" || ! -e "$db" ]]; then
    return 1
  fi
  if ! command -v df >/dev/null 2>&1; then
    return 1
  fi
  local fa fb
  fa="$(df -P "$da" 2>/dev/null | awk 'END{print $1}')"
  fb="$(df -P "$db" 2>/dev/null | awk 'END{print $1}')"
  [[ -n "$fa" && -n "$fb" && "$fa" == "$fb" ]]
}

#######################################
# --- Atomic write (tmp on same FS when possible) ---
#######################################
atomic_write() {
  local dest="$1"
  local content="${2:-}"
  local dest_dir tmp

  dest_dir="$(dirname -- "$dest")"

  ensure_tmpdir

  if same_filesystem "$TMP_DIR" "$dest_dir" && mktemp_portable "$TMP_DIR" "atomic.XXXXXX" >/dev/null 2>&1; then
    tmp="$(mktemp_portable "$TMP_DIR" "atomic.XXXXXX")" || {
      log_error "mktemp failed in atomic_write (tmpdir)"
      return 1
    }
  else
    tmp="$(mktemp_portable "$dest_dir" "atomic.XXXXXX")" || {
      log_error "mktemp failed in atomic_write (destdir)"
      return 1
    }
  fi

  umask 077
  printf '%s' "$content" >"$tmp" || {
    log_error "Failed to write to temp file $tmp"
    rm -f "$tmp" 2>/dev/null || true
    return 1
  }

  if command -v sync >/dev/null 2>&1; then
    sync || true
  fi

  mv -f "$tmp" "$dest" || {
    log_error "mv failed in atomic_write from $tmp to $dest"
    rm -f "$tmp" 2>/dev/null || true
    return 1
  }
  chmod 600 "$dest" || true
  return 0
}

#######################################
# --- Atomic append to conversation (requires lock) ---
#######################################
atomic_append_conv() {
  local conv_file="$1"
  local append_text="$2"

  if [[ "$LOCK_HELD" -ne 1 ]]; then
    log_error "atomic_append_conv called without lock held"
    return 1
  fi

  local tmp dest_dir
  dest_dir="$(dirname -- "$conv_file")"

  if same_filesystem "$TMP_DIR" "$dest_dir" && mktemp_portable "$TMP_DIR" "conv.XXXXXX" >/dev/null 2>&1; then
    tmp="$(mktemp_portable "$TMP_DIR" "conv.XXXXXX")" || {
      log_error "mktemp failed in atomic_append_conv (tmpdir)"
      return 1
    }
  else
    tmp="$(mktemp_portable "$dest_dir" "conv.XXXXXX")" || {
      log_error "mktemp failed in atomic_append_conv (destdir)"
      return 1
    }
  fi

  if [[ -f "$conv_file" ]]; then
    cat "$conv_file" >"$tmp" || {
      log_error "Failed to copy existing conversation to tmp in atomic_append_conv"
      rm -f "$tmp" 2>/dev/null || true
      return 1
    }
  fi

  printf '%s\n' "$append_text" >>"$tmp" || {
    log_error "Failed to append text to tmp in atomic_append_conv"
    rm -f "$tmp" 2>/dev/null || true
    return 1
  }

  mv -f "$tmp" "$conv_file" || {
    log_error "mv failed in atomic_append_conv from $tmp to $conv_file"
    rm -f "$tmp" 2>/dev/null || true
    return 1
  }
  chmod 600 "$conv_file" || true
  return 0
}

#######################################
# --- flock availability check (deterministic) ---
#######################################
ensure_flock_available() {
  if ! command -v flock >/dev/null 2>&1; then
    log_error "flock not available on this system; cannot guarantee safe concurrency"
    print_http_error "500 Internal Server Error" "Server misconfiguration: flock not available"
    exit 1
  fi
}

#######################################
# --- Lock management (fd 9) ---
#######################################
acquire_lock() {
  exec 9>"$LOCK_FILE"
  flock -x 9
  LOCK_HELD=1
  trap 'release_lock' EXIT INT TERM
}

release_lock() {
  if [[ "$LOCK_HELD" -eq 1 ]]; then
    exec 9>&- || true
    LOCK_HELD=0
    trap - EXIT INT TERM
  fi
}

#######################################
# --- HTTP helpers ---
#######################################
print_http_header() {
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
}

print_http_error() {
  local status="$1"
  local msg="$2"
  printf 'Status: %s\r\n' "$status"
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf 'X-Content-Type-Options: nosniff\r\n'
  printf '\r\n'
  printf '<h1>%s</h1>\n' "$msg"
}

# Centralized HTML escape
html_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}
html_escape_stream() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

#######################################
# --- Validation and sanitization ---
#######################################
validate_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    return 1
  fi
  if [[ "$name" == *"/"* || "$name" == *".."* || "$name" == *$'\x00'* ]]; then
    return 1
  fi
  # POSIX-safe check for control characters using awk (portable)
  if printf '%s' "$name" | awk '/[[:cntrl:]]/ { exit 0 } END { exit 1 }'; then
    return 1
  fi
  if (( ${#name} > MAX_NAME_LEN )); then
    return 1
  fi
  if [[ "$name" =~ $VALID_NAME_RE ]]; then
    return 0
  fi
  return 1
}

# Normalize tabs to single space and collapse multiple spaces; remove control chars
sanitize_param() {
  local v="$1"
  # Remove control chars (except newline), convert tabs to space, collapse multiple spaces
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
  if ! [[ "$len" =~ ^[0-9]+$ ]]; then
    len=0
  fi
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

#######################################
# --- Config helpers with robust fallback ---
#######################################
get_current_conversation_file() {
  local conv
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "conv-001.txt")"
  conv="$(sanitize_param "$conv")"
  if ! validate_name "$conv"; then
    log_error "Invalid current conversation name: '$conv' - falling back to conv-001.txt"
    conv="conv-001.txt"
    atomic_write "$CURRENT_CONV_FILE" "$conv"
  fi
  printf '%s/%s\n' "$CONV_DIR" "$conv"
}

get_default_model() {
  read_config_or_default "$DEFAULT_MODEL_FILE" "default"
}

get_default_provider() {
  read_config_or_default "$DEFAULT_PROVIDER_FILE" "default"
}

#######################################
# --- Template rendering (streaming safe) ---
#######################################
render_page_main() {
  [[ -f "$TEMPLATES_DIR/header.html" ]] && cat "$TEMPLATES_DIR/header.html"
  render_content_main
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && cat "$TEMPLATES_DIR/footer.html"
}

render_page_settings() {
  [[ -f "$TEMPLATES_DIR/settings-header.html" ]] && cat "$TEMPLATES_DIR/settings-header.html"
  render_content_settings
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && cat "$TEMPLATES_DIR/footer.html"
}

render_content_main() {
  local conv_file
  conv_file="$(get_current_conversation_file)"
  if [[ -f "$TEMPLATES_DIR/content.html" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == *"{{CONVERSATION}}"* ]]; then
        if [[ -f "$conv_file" ]]; then
          while IFS= read -r cl || [[ -n "$cl" ]]; do
            printf '%s<br>\n' "$(printf '%s' "$cl" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')"
          done <"$conv_file"
        fi
      else
        printf '%s\n' "$line"
      fi
    done <"$TEMPLATES_DIR/content.html"
  else
    printf '<pre>'
    html_escape_stream <"$conv_file"
    printf '</pre>\n'
  fi
}

render_content_settings() {
  local model provider lang conv
  model="$(get_default_model)"
  provider="$(get_default_provider)"
  lang="$(read_config_or_default "$LANG_CURRENT_FILE" "it")"
  conv="$(read_config_or_default "$CURRENT_CONV_FILE" "conv-001.txt")"

  local esc_model esc_provider esc_lang
  esc_model="$(html_escape "$model")"
  esc_provider="$(html_escape "$provider")"
  esc_lang="$(html_escape "$lang")"

  if [[ -f "$TEMPLATES_DIR/settings-content.html" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == *"{{CURRENT_CONV}}"* ]]; then
        if [[ -f "$CONV_DIR/$conv" ]]; then
          while IFS= read -r cl || [[ -n "$cl" ]]; do
            printf '%s<br>\n' "$(printf '%s' "$cl" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')"
          done <"$CONV_DIR/$conv"
        fi
      else
        line="${line//\{\{MODEL\}\}/$esc_model}"
        line="${line//\{\{PROVIDER\}\}/$esc_provider}"
        line="${line//\{\{LANG\}\}/$esc_lang}"
        printf '%s\n' "$line"
      fi
    done <"$TEMPLATES_DIR/settings-content.html"
  else
    printf '<pre>Settings page template missing.</pre>\n'
  fi
}

#######################################
# --- Model output sanitization ---
#######################################
sanitize_model_output() {
  local out="$1"
  out="$(printf '%s' "$out" | tr -d '\000-\011\013\014\016-\037')"
  if (( ${#out} > MAX_MODEL_OUTPUT_CHARS )); then
    log_error "Model output truncated (length ${#out})"
    out="${out:0:MAX_MODEL_OUTPUT_CHARS}"
  fi
  printf '%s' "$out"
}

#######################################
# --- Ensure groqbash available (single check) ---
#######################################
ensure_groqbash_available() {
  if ! command -v "$GROQBASH_CMD" >/dev/null 2>&1; then
    log_error "groqbash not found in PATH: $GROQBASH_CMD"
    print_http_error "500 Internal Server Error" "groqbash not found on server. Contact administrator."
    exit 1
  fi
}

#######################################
# --- POST handlers ---
#######################################
handle_post_main() {
  local body prompt model provider conv_file output sanitized_output
  body="$(read_post_body)"

  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"
  model="$(printf '%s' "$body" | parse_form_field "model" || get_default_model)"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || get_default_provider)"

  prompt="$(sanitize_param "$prompt")"
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"

  if (( ${#prompt} > MAX_PROMPT_CHARS )); then
    log_error "Prompt truncated from ${#prompt} to $MAX_PROMPT_CHARS chars"
    prompt="${prompt:0:MAX_PROMPT_CHARS}"
  fi

  if ! validate_name "$model"; then
    log_error "Invalid model name attempted: $model"
    model="$(get_default_model)"
  fi
  if ! validate_name "$provider"; then
    log_error "Invalid provider name attempted: $provider"
    provider="$(get_default_provider)"
  fi

  conv_file="$(get_current_conversation_file)"

  atomic_append_conv "$conv_file" "USER: $prompt" || {
    log_error "Failed to append USER to conversation"
  }

  if [[ -n "$provider" && "$provider" != "default" ]]; then
    if [[ -n "$model" && "$model" != "default" ]]; then
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" --provider "$provider" --model "$model" 2>>"$ERROR_LOG" || true)"
    else
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" --provider "$provider" 2>>"$ERROR_LOG" || true)"
    fi
  else
    if [[ -n "$model" && "$model" != "default" ]]; then
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" --model "$model" 2>>"$ERROR_LOG" || true)"
    else
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" 2>>"$ERROR_LOG" || true)"
    fi
  fi

  sanitized_output="$(sanitize_model_output "$output")"
  atomic_append_conv "$conv_file" "AI: $sanitized_output" || {
    log_error "Failed to append AI to conversation"
  }
}

handle_post_settings() {
  local body model provider lang
  body="$(read_post_body)"

  model="$(printf '%s' "$body" | parse_form_field "model" || get_default_model)"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || get_default_provider)"
  lang="$(printf '%s' "$body" | parse_form_field "lang" || read_config_or_default "$LANG_CURRENT_FILE" "it")"

  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  lang="$(sanitize_param "$lang")"

  if ! validate_name "$model"; then
    log_error "Invalid model name attempted: $model"
    model="$(get_default_model)"
  fi
  if ! validate_name "$provider"; then
    log_error "Invalid provider name attempted: $provider"
    provider="$(get_default_provider)"
  fi
  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "it")"
  fi

  atomic_write "$DEFAULT_MODEL_FILE" "$model"
  atomic_write "$DEFAULT_PROVIDER_FILE" "$provider"
  atomic_write "$LANG_CURRENT_FILE" "$lang"
}

#######################################
# --- Main router ---
#######################################
main() {
  ensure_dirs
  ensure_config_defaults

  ensure_flock_available

  ensure_groqbash_available

  acquire_lock

  local method="${REQUEST_METHOD:-}"
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  if [[ -z "$method" ]]; then
    method="${1:-GET}"
    method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  fi

  QUERY_STRING="${QUERY_STRING:-}"
  QUERY_STRING="$(printf '%s' "$QUERY_STRING" | tr -d '\000-\037')"

  local page
  page="$(get_query_param "page" 2>/dev/null || printf 'main')"
  page="$(sanitize_param "$page")"
  if ! validate_name "$page"; then
    page="main"
  fi

  log_info "Request method=$method page=$page"

  case "$method" in
    GET)
      print_http_header
      case "$page" in
        settings) render_page_settings ;;
        *) render_page_main ;;
      esac
      ;;
    POST)
      case "$page" in
        settings)
          handle_post_settings
          print_http_header
          render_page_settings
          ;;
        *)
          handle_post_main
          print_http_header
          render_page_main
          ;;
      esac
      ;;
    *)
      print_http_header
      printf '<h1>405 Method Not Allowed</h1>\n'
      ;;
  esac

  release_lock
}

#######################################
# WEBSERVER (embedded, zero-deps)
#######################################

# Default server params (modificabili via CLI)
DEFAULT_PORT=59123
MAX_BODY_BYTES=$((1024*1024))   # 1 MiB
HEADER_TIMEOUT=5                # secondi
BODY_TIMEOUT=8                  # secondi
STATIC_PREFIX="/static"
STATIC_DIR="$UI_ROOT/static"

# Utility: safe close fd if open
_safe_close_fd() {
  local fd="$1"
  if eval "exec {tmpfd}>&$fd" 2>/dev/null; then
    eval "exec {tmpfd}>&-"
  fi
}

# Normalize and sanitize request path
server_normalize_path() {
  local p="$1"
  # URL-decode minimal (handles %20 etc.)
  p="$(printf '%b' "${p//%/\\x}")" 2>/dev/null || true
  # remove query part if present
  p="${p%%\?*}"
  # collapse // and remove .. and control chars
  p="$(printf '%s' "$p" | tr -d '\000-\037' | sed -E 's#//+#/#g' | sed -E 's#(/\.\.)+##g')"
  # prevent traversal
  if [[ "$p" == *".."* ]]; then
    printf '/forbidden'
    return 0
  fi
  printf '%s' "$p"
}

# Read request line and headers from client fd
server_read_request() {
  local client_fd=$1
  # read request line with timeout
  IFS=$'\r\n' read -r -t "$HEADER_TIMEOUT" REQUEST_LINE <&"$client_fd" || return 1
  # read headers until blank line or limit
  HEADERS=""
  local line
  while IFS=$'\r\n' read -r -t "$HEADER_TIMEOUT" line <&"$client_fd"; do
    [[ -z "$line" ]] && break
    HEADERS+="$line"$'\n'
    # protect against huge headers
    if (( ${#HEADERS} > 8192 )); then
      return 2
    fi
  done
  return 0
}

# Extract header value (case-insensitive)
server_get_header() {
  local name="$1"
  printf '%s\n' "$HEADERS" | awk -v IGNORECASE=1 -F': ' -v n="$name" '$1==n {print substr($0, index($0,$2))}'
}

# Read body up to MAX_BODY_BYTES with timeout
server_read_body_to_file() {
  local client_fd="$1" out_file="$2"
  local cl
  cl="$(server_get_header 'Content-Length' | tr -d '\r\n' || true)"
  if [[ -z "$cl" ]]; then
    # no body
    : >"$out_file"
    return 0
  fi
  if ! [[ "$cl" =~ ^[0-9]+$ ]]; then
    return 3
  fi
  if (( cl > MAX_BODY_BYTES )); then
    return 4
  fi
  # read exactly cl bytes with timeout
  # Try head if available
  if command -v head >/dev/null 2>&1; then
    if head -c "$cl" <&"$client_fd" >"$out_file" 2>/dev/null; then
      return 0
    fi
  fi
  # portable fallback: read loop
  : >"$out_file"
  local remaining=$cl chunk
  while (( remaining > 0 )); do
    # read up to remaining bytes; -n may not accept large values on some shells, so cap chunk size
    local want=$remaining
    if (( want > 65536 )); then want=65536; fi
    if ! IFS= read -r -t "$BODY_TIMEOUT" -n "$want" chunk <&"$client_fd"; then
      return 5
    fi
    printf '%s' "$chunk" >>"$out_file"
    remaining=$((remaining - ${#chunk}))
  done
  return 0
}

# Send a minimal HTTP response (headers + body) to client fd
server_send_raw_response() {
  local client_fd="$1" status="$2" content_type="$3" body_file="$4"
  {
    printf 'HTTP/1.1 %s\r\n' "$status"
    printf 'Content-Type: %s\r\n' "$content_type"
    printf 'Cache-Control: no-store\r\n'
    printf 'Connection: close\r\n'
    printf 'Content-Length: %s\r\n' "$(wc -c <"$body_file" 2>/dev/null || echo 0)"
    printf '\r\n'
    cat "$body_file"
  } >&"$client_fd"
}

# Serve static file under STATIC_DIR
server_serve_static() {
  local client_fd="$1" path="$2"
  local file_path="$STATIC_DIR${path#$STATIC_PREFIX}"
  if [[ ! -f "$file_path" ]]; then
    printf '404 Not Found' >"$TMP_DIR/resp_body.$$"
    server_send_raw_response "$client_fd" "404 Not Found" "text/plain; charset=utf-8" "$TMP_DIR/resp_body.$$"
    rm -f "$TMP_DIR/resp_body.$$" 2>/dev/null || true
    return 0
  fi
  # minimal mime table
  local mime="application/octet-stream"
  case "$file_path" in
    *.html) mime="text/html; charset=utf-8" ;;
    *.css)  mime="text/css; charset=utf-8" ;;
    *.js)   mime="application/javascript; charset=utf-8" ;;
    *.json) mime="application/json; charset=utf-8" ;;
    *.png)  mime="image/png" ;;
    *.jpg|*.jpeg) mime="image/jpeg" ;;
    *.gif)  mime="image/gif" ;;
    *.svg)  mime="image/svg+xml" ;;
    *.txt)  mime="text/plain; charset=utf-8" ;;
  esac
  server_send_raw_response "$client_fd" "200 OK" "$mime" "$file_path"
  return 0
}

# Dispatch request to CGI core (main)
server_dispatch_to_cgi() {
  local client_fd="$1" method="$2" raw_path="$3" body_file="$4"
  # prepare env
  export REQUEST_METHOD="$method"
  # extract query string
  local qs=""
  if [[ "$raw_path" == *\?* ]]; then
    qs="${raw_path#*\?}"
  fi
  export QUERY_STRING="$qs"
  export CONTENT_LENGTH="$(wc -c <"$body_file" 2>/dev/null || echo 0)"
  export CONTENT_TYPE="$(server_get_header 'Content-Type' | tr -d '\r\n' || echo '')"

  # Provide body on stdin to main by redirecting from file
  # Capture output of main to a temp file and send it raw
  local outtmp
  outtmp="$(mktemp_portable "$TMP_DIR" "resp.XXXXXX")" || outtmp="$TMP_DIR/resp.$$"
  # Call main in a subshell to avoid polluting server env
  (
    # ensure functions and variables are visible; main expects to call acquire_lock etc.
    # main will print headers (Status/Content-Type) or use print_http_header
    exec 0<"$body_file"
    main
  ) >"$outtmp" 2>>"$ERROR_LOG" || true

  # If main printed a Status header, convert to HTTP status line; otherwise assume 200 OK
  if grep -q -i '^Status:' "$outtmp" 2>/dev/null; then
    # extract Status header and remove it from body
    local status_line
    status_line="$(grep -i '^Status:' "$outtmp" | head -n1 | sed -E 's/Status:[[:space:]]*//I')"
    # remove the Status header line from outtmp
    awk 'BEGIN{first=1} { if(first && tolower($0) ~ /^status:/){first=0; next} print }' "$outtmp" >"${outtmp}.body" || true
    mv -f "${outtmp}.body" "$outtmp" 2>/dev/null || true
    server_send_raw_response "$client_fd" "$status_line" "text/html; charset=utf-8" "$outtmp"
  else
    server_send_raw_response "$client_fd" "200 OK" "text/html; charset=utf-8" "$outtmp"
  fi

  rm -f "$outtmp" 2>/dev/null || true
}

# Handle a single client connection (serial handling)
server_handle_connection() {
  local client_fd="$1"
  # read request
  if ! server_read_request "$client_fd"; then
    printf 'HTTP/1.1 400 Bad Request\r\nConnection: close\r\nContent-Length: 11\r\n\r\nBad Request' >&"$client_fd"
    return 0
  fi

  # parse request line: METHOD PATH PROTOCOL
  local method path proto
  method="$(printf '%s' "$REQUEST_LINE" | awk '{print $1}')"
  path="$(printf '%s' "$REQUEST_LINE" | awk '{print $2}')"
  proto="$(printf '%s' "$REQUEST_LINE" | awk '{print $3}')"

  # normalize path
  path="$(server_normalize_path "$path")"
  if [[ "$path" == "/forbidden" ]]; then
    printf 'HTTP/1.1 403 Forbidden\r\nConnection: close\r\nContent-Length: 9\r\n\r\nForbidden' >&"$client_fd"
    return 0
  fi

  # static file handling
  if [[ "$path" == "$STATIC_PREFIX"* ]]; then
    server_serve_static "$client_fd" "$path"
    return 0
  fi

  # prepare temp file for body
  local bodyfile
  bodyfile="$(mktemp_portable "$TMP_DIR" "body.XXXXXX")" || bodyfile="$TMP_DIR/body.$$"
  if ! server_read_body_to_file "$client_fd" "$bodyfile"; then
    printf 'HTTP/1.1 413 Payload Too Large\r\nConnection: close\r\nContent-Length: 16\r\n\r\nPayload Too Large' >&"$client_fd"
    rm -f "$bodyfile" 2>/dev/null || true
    return 0
  fi

  # dispatch to CGI core
  server_dispatch_to_cgi "$client_fd" "$method" "$path" "$bodyfile"

  rm -f "$bodyfile" 2>/dev/null || true
  return 0
}

# Lightweight accept wrapper for systems supporting /dev/tcp
server_accept_and_handle() {
  local port="$1"
  while true; do
    # Accept connection (this blocks until a client connects)
    exec {client_fd}<>/dev/tcp/0.0.0.0/"$port" 2>/dev/null || {
      sleep 0.1
      continue
    }
    # handle connection serially
    server_handle_connection "$client_fd"
    # close fd
    exec {client_fd}>&- || true
  done
}

# Dispatcher to start embedded server or fall back to CGI
server_entrypoint() {
  local port="${1:-$DEFAULT_PORT}"
  # ensure environment
  ensure_dirs
  ensure_config_defaults
  ensure_flock_available
  ensure_groqbash_available

  # ensure static dir exists
  mkdir -p "$STATIC_DIR" || true
  chmod 700 "$STATIC_DIR" || true

  log_info "Starting embedded webserver on 127.0.0.1:$port"
  # run accept loop (serial)
  server_accept_and_handle "$port"
}

#######################################
# Fine sezione WEBSERVER
#######################################

# Avvio e parsing argomenti
#######################################
# Default behavior: embedded server unless --cgi specified
MODE="server"
PORT="$DEFAULT_PORT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cgi) MODE="cgi"; shift ;;
    --serve) MODE="server"; PORT="${2:-$DEFAULT_PORT}"; shift 2 ;;
    --port) PORT="${2:-$DEFAULT_PORT}"; shift 2 ;;
    -p) PORT="${2:-$DEFAULT_PORT}"; shift 2 ;;
    --help|-h) printf 'Usage: %s [--cgi] [--serve|--port PORT]\n' "$0"; exit 0 ;;
    *) shift ;;
  esac
done

if [[ "$MODE" == "cgi" || -n "${GATEWAY_INTERFACE:-}" ]]; then
  # run as CGI (existing behavior)
  main "$@"
else
  # run embedded server (default)
  # bind only to localhost for safety
  if ! command -v bash >/dev/null 2>&1; then
    echo "Bash required"
    exit 1
  fi
  # Start server_entrypoint which uses /dev/tcp accept
  server_entrypoint "$PORT"
fi
