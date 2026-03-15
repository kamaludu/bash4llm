#!/usr/bin/env bash
set -euo pipefail

# groqbash-gui-install.sh
# Single-file installer for groqbash-gui Apache integration (Termux-friendly).
# Strict: idempotent, atomic writes, rollback rules, permission policy.

# --- Configurable defaults ---
PROJECT_NAME="groqbash-gui"
DEFAULT_PORT="19970"
CGI_URL_PATH="/groqbash-gui/cgi"
STATIC_URL_PATH="/groqbash-gui/static"
CONF_FILENAME="${PROJECT_NAME}.conf"
# Termux environment defaults for CGI
TERMUX_HOME="/data/data/com.termux/files/home"
TERMUX_PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets"

# --- Globals populated at runtime ---
APP_ROOT=""
APP_BIN=""
APP_STATIC=""
APACHECTL=""
APACHECTL_BIN=""
SERVER_ROOT=""
APACHE_CONF_DIR=""
FINAL_CONF_PATH=""
PORT="$DEFAULT_PORT"
TMP_FILES=()

# --- Helpers ---
err() { printf '%s\n' "ERROR: $*" >&2; }
warn() { printf '%s\n' "WARNING: $*" >&2; }
info() { printf '%s\n' "INFO: $*"; }

cleanup_tmp() {
  for f in "${TMP_FILES[@]:-}"; do
    [[ -e "$f" ]] && rm -f -- "$f" || true
  done
}
on_exit() {
  cleanup_tmp
}
trap on_exit EXIT INT TERM

# atomic write: write to temp in same dir then mv
write_atomic() {
  local dest="$1" content_file="$2" tmp
  tmp="$(mktemp "${dest}.tmp.XXXXXX")"
  TMP_FILES+=("$tmp")
  cat "$content_file" >"$tmp"
  sync || true
  mv -f "$tmp" "$dest"
  TMP_FILES=("${TMP_FILES[@]/$tmp}") || true
}

# find upward for gui-server.sh
locate_ui_root() {
  local start dir candidate
  if [[ -n "${1:-}" ]]; then
    start="$1"
  else
    start="$(pwd)"
  fi
  dir="$start"
  while true; do
    candidate="$dir/groqbash/groqbash.d/extras/ui/gui-server.sh"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$(cd "$dir" && pwd -P)"
      return 0
    fi
    if [[ "$dir" == "/" || "$dir" == "." ]]; then break; fi
    dir="$(dirname -- "$dir")"
  done
  return 1
}

# detect apachectl/httpd
detect_apache() {
  if command -v apachectl >/dev/null 2>&1; then
    APACHECTL="apachectl"
  elif command -v httpd >/dev/null 2>&1; then
    APACHECTL="httpd"
  else
    err "Apache not found (apachectl or httpd). Aborting."
    return 1
  fi
  APACHECTL_BIN="$(command -v "$APACHECTL")"
  # basic checks
  "$APACHECTL" -v >/dev/null 2>&1 || true
  "$APACHECTL" -V >/dev/null 2>&1 || true
  return 0
}

# parse apachectl -V for SERVER_ROOT and SERVER_CONFIG_FILE
derive_server_root() {
  local out
  out="$("$APACHECTL" -V 2>/dev/null || true)"
  SERVER_ROOT="$(printf '%s\n' "$out" | awk -F': ' '/HTTPD_ROOT/ {print $2}' | tr -d '"')"
  if [[ -z "$SERVER_ROOT" ]]; then
    SERVER_ROOT="$(printf '%s\n' "$out" | awk -F': ' '/SERVER_CONFIG_FILE/ {print $2}' | sed -E 's#/[^/]+$##' | tr -d '"')"
  fi
  if [[ -z "$SERVER_ROOT" ]]; then
    err "Could not determine Apache ServerRoot from $APACHECTL -V"
    return 1
  fi
  return 0
}

# candidate conf dirs in order
candidate_conf_dirs() {
  printf '%s\n' \
    "$SERVER_ROOT/conf.d" \
    "$SERVER_ROOT/extra" \
    "$SERVER_ROOT/conf" \
    "$SERVER_ROOT"
}

# probe conf dir by writing temp conf and running configtest
detect_conf_dir() {
  local cand tmpconf name ok
  for cand in $(candidate_conf_dirs); do
    [[ -d "$cand" ]] || continue
    name=".${CONF_FILENAME}.probe.$$"
    tmpconf="$cand/$name"
    # create minimal valid conf that will be ignored but parsed
    printf '%s\n' "## probe $PROJECT_NAME" >"$tmpconf"
    TMP_FILES+=("$tmpconf")
    if "$APACHECTL" configtest >/dev/null 2>&1; then
      # configtest passed with probe file present -> accept
      APACHE_CONF_DIR="$cand"
      # remove probe file (we will create final later)
      rm -f -- "$tmpconf" || true
      TMP_FILES=("${TMP_FILES[@]/$tmpconf}") || true
      return 0
    else
      # remove probe and continue
      rm -f -- "$tmpconf" || true
      TMP_FILES=("${TMP_FILES[@]/$tmpconf}") || true
    fi
  done
  return 1
}

# check required commands (hard requirements)
check_dependencies() {
  local reqs=(bash awk sed tr df mktemp readlink wc dd cat mv chmod rm printf basename dirname flock gawk curl jq)
  local cmd
  for cmd in "${reqs[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      err "Required command missing: $cmd"
      return 1
    fi
  done
  # apachectl already detected
  return 0
}

# check and tighten permissions per policy
check_permissions() {
  local script1="$APP_BIN/gui-server.sh"
  local script2="$APP_BIN/gui-bootstrap.sh"
  local templates_dir="$APP_BIN/templates"
  local runtime_dirs=( "$APP_BIN/config" "$APP_BIN/conversations" "$APP_BIN/files" "$APP_BIN/logs" "$APP_BIN/tmp" "$APP_BIN/assets" )
  local runtime_files=( "$APP_BIN/config/current-conversation" "$APP_BIN/config/lang-current" "$APP_BIN/config/gui-theme" "$APP_BIN/config/default-model" "$APP_BIN/config/default-provider" )
  # scripts
  for s in "$script1" "$script2"; do
    if [[ ! -f "$s" ]]; then
      err "Critical script missing: $s"
      return 1
    fi
    if ! chmod 755 "$s" 2>/dev/null; then
      err "Cannot set 755 on critical script $s; aborting."
      return 1
    fi
  done
  # templates and static files
  if [[ -d "$templates_dir" ]]; then
    find "$templates_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
  fi
  # runtime dirs
  for d in "${runtime_dirs[@]}"; do
    if [[ -e "$d" && ! -d "$d" ]]; then
      warn "Expected directory but found file: $d"
    fi
    mkdir -p "$d" 2>/dev/null || true
    if ! chmod 700 "$d" 2>/dev/null; then
      warn "Could not tighten permissions on runtime dir $d"
    fi
  done
  # runtime files
  for f in "${runtime_files[@]}"; do
    if [[ -e "$f" ]]; then
      if ! chmod 600 "$f" 2>/dev/null; then
        warn "Could not tighten permissions on runtime file $f"
      fi
    fi
  done
  return 0
}

# check GROQBASH_CMD via sourcing bootstrap and calling ensure_groqbash_available
check_groqbash_cmd() {
  local bootstrap="$APP_BIN/gui-bootstrap.sh"
  if [[ ! -f "$bootstrap" ]]; then
    err "gui-bootstrap.sh not found at $bootstrap"
    return 1
  fi
  # source in a subshell to avoid polluting environment
  if ! ( set -euo pipefail; . "$bootstrap"; ensure_groqbash_available ); then
    err "groqbash binary not resolvable by bootstrap (ensure_groqbash_available failed)"
    return 1
  fi
  return 0
}

# check port availability
port_in_use() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :$p )" >/dev/null 2>&1 && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln | awk '{print $4}' | grep -E ":$p\$" >/dev/null 2>&1 && return 0 || return 1
  else
    # fallback: try to bind with nc (not guaranteed)
    if command -v nc >/dev/null 2>&1; then
      (echo >"/dev/tcp/127.0.0.1/$p") >/dev/null 2>&1 && return 0 || return 1
    fi
    # cannot determine; assume free
    return 1
  fi
}

# prompt for port if busy
choose_port() {
  local tries=3
  while port_in_use "$PORT"; do
    warn "Port $PORT appears in use."
    if [[ "$tries" -le 0 ]]; then
      err "No available port chosen. Aborting."
      return 1
    fi
    printf 'Choose alternative port (or press Enter to abort): '
    read -r alt || true
    if [[ -z "$alt" ]]; then
      err "User aborted port selection."
      return 1
    fi
    if ! [[ "$alt" =~ ^[0-9]+$ ]] || (( alt < 1025 || alt > 65535 )); then
      warn "Invalid port: $alt"
      tries=$((tries-1))
      continue
    fi
    PORT="$alt"
  done
  return 0
}

# generate vhost content to a temp file
generate_vhost_config() {
  local out="$1"
  cat >"$out" <<EOF
# groqbash-gui Apache config (generated)
Listen ${PORT}
<VirtualHost *:${PORT}>
    ScriptAlias ${CGI_URL_PATH} "${APP_BIN}/gui-server.sh"
    Alias ${STATIC_URL_PATH} "${APP_STATIC}"

    <Directory "${APP_BIN}">
        Options +ExecCGI -Indexes
        AllowOverride None
        Require all granted
    </Directory>

    <Directory "${APP_STATIC}">
        Options -ExecCGI -Indexes
        AllowOverride None
        Require all granted
    </Directory>

    # Ensure CGI environment for Termux
    SetEnv HOME ${TERMUX_HOME}
    SetEnv PATH ${TERMUX_PATH}
</VirtualHost>
EOF
}

# write conf atomically with rollback rules
write_conf_atomic() {
  local target="$1" tmpf
  tmpf="$(mktemp "${target}.tmp.XXXXXX")"
  TMP_FILES+=("$tmpf")
  generate_vhost_config "$tmpf"
  # attempt to place temp into candidate dir and run configtest
  if ! mv -f "$tmpf" "${target}.pending" 2>/dev/null; then
    rm -f -- "$tmpf" || true
    TMP_FILES=("${TMP_FILES[@]/$tmpf}") || true
    err "Failed to move temp conf to ${target}.pending"
    return 1
  fi
  TMP_FILES+=("${target}.pending")
  # run configtest with pending file present
  if ! "$APACHECTL" configtest >/dev/null 2>&1; then
    # rollback: delete pending
    rm -f -- "${target}.pending" || true
    TMP_FILES=("${TMP_FILES[@]/${target}.pending}") || true
    err "apachectl configtest failed after writing ${target}.pending; file removed."
    return 2
  fi
  # atomic final move
  if ! mv -f "${target}.pending" "$target"; then
    rm -f -- "${target}.pending" || true
    TMP_FILES=("${TMP_FILES[@]/${target}.pending}") || true
    err "Failed to move ${target}.pending to $target; operation aborted."
    return 1
  fi
  TMP_FILES=("${TMP_FILES[@]/${target}.pending}") || true
  return 0
}

# run configtest (wrapper)
run_configtest() {
  if ! "$APACHECTL" configtest >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# reload apache with best-effort and messages
reload_apache() {
  if "$APACHECTL" graceful >/dev/null 2>&1; then
    return 0
  fi
  if "$APACHECTL" restart >/dev/null 2>&1; then
    return 0
  fi
  if command -v service >/dev/null 2>&1; then
    if service apache2 reload >/dev/null 2>&1 || service httpd reload >/dev/null 2>&1; then
      return 0
    fi
  fi
  warn "Apache reload/restart failed. Manual reload required."
  return 2
}

# summarize final state
summarize() {
  printf '\n'
  info "Installation summary:"
  info "APP_ROOT: $APP_ROOT"
  info "APP_BIN: $APP_BIN"
  info "APACHE_CONF: $FINAL_CONF_PATH"
  info "PORT: $PORT"
  info "URL: http://localhost:${PORT}${CGI_URL_PATH}"
  printf '\n'
}

# --- Main flow ---
main() {
  # parse args: optional APP_ROOT and PORT
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-root) APP_ROOT="$2"; shift 2 ;;
      --port) PORT="$2"; shift 2 ;;
      --non-interactive) NONINTERACTIVE=1; shift ;;
      -h|--help) printf 'Usage: %s [--app-root PATH] [--port PORT]\n' "$0"; exit 0 ;;
      *) err "Unknown arg: $1"; exit 2 ;;
    esac
  done

  # locate UI root if APP_ROOT not provided
  if [[ -z "${APP_ROOT:-}" ]]; then
    if ui_root="$(locate_ui_root)"; then
      APP_ROOT="$ui_root"
    else
      err "Could not locate groqbash UI root. Provide --app-root pointing to parent of groqbash/."
      exit 1
    fi
  fi

  APP_BIN="${APP_ROOT}/groqbash/groqbash.d/extras/ui"
  APP_STATIC="$APP_BIN"

  # detect apache
  detect_apache || exit 1

  # derive server root
  derive_server_root || exit 1

  # check dependencies
  check_dependencies || exit 1

  # detect conf dir
  if ! detect_conf_dir; then
    err "Could not find a writable/parsable Apache conf directory. Aborting."
    exit 1
  fi

  FINAL_CONF_PATH="${APACHE_CONF_DIR}/${CONF_FILENAME}"

  # check APP_BIN exists and contains required scripts
  if [[ ! -d "$APP_BIN" ]]; then
    err "APP_BIN not found at $APP_BIN"
    exit 1
  fi
  if [[ ! -f "$APP_BIN/gui-server.sh" || ! -f "$APP_BIN/gui-bootstrap.sh" ]]; then
    err "Required UI scripts missing in $APP_BIN"
    exit 1
  fi

  # permissions
  check_permissions || exit 1

  # check groqbash cmd via bootstrap
  if ! check_groqbash_cmd; then
    err "GROQBASH_CMD check failed. Aborting."
    exit 1
  fi

  # port handling
  if port_in_use "$PORT"; then
    info "Default port $PORT appears in use."
    if ! choose_port; then
      exit 1
    fi
  fi

  # generate config to temp file and attempt to write into APACHE_CONF_DIR atomically
  # but first check idempotence
  local gen_tmp
  gen_tmp="$(mktemp "${APACHE_CONF_DIR}/${CONF_FILENAME}.gen.XXXXXX")"
  TMP_FILES+=("$gen_tmp")
  generate_vhost_config "$gen_tmp"

  if [[ -f "$FINAL_CONF_PATH" ]]; then
    # compare
    if cmp -s "$gen_tmp" "$FINAL_CONF_PATH"; then
      info "Configuration already installed and identical. Nothing to do."
      rm -f -- "$gen_tmp" || true
      TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
      summarize
      exit 0
    else
      printf 'Existing config differs. Overwrite? [y/N]: '
      read -r ans || true
      if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        info "Aborting per user choice. Existing config left intact."
        rm -f -- "$gen_tmp" || true
        TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
        exit 0
      fi
    fi
  fi

  # attempt atomic write with rollback semantics
  if ! write_conf_atomic "$FINAL_CONF_PATH" "$gen_tmp"; then
    # write_conf_atomic returns 2 for configtest failure, 1 for write failure
    err "Failed to install Apache config. Aborting."
    rm -f -- "$gen_tmp" || true
    TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
    exit 1
  fi
  rm -f -- "$gen_tmp" || true
  TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true

  # final configtest (should pass)
  if ! run_configtest; then
    # rollback: delete final conf
    rm -f -- "$FINAL_CONF_PATH" || true
    err "apachectl configtest failed after installing $FINAL_CONF_PATH. File removed. Aborting."
    exit 1
  fi

  # attempt reload
  if ! reload_apache; then
    warn "Apache reload failed. Configuration file remains at $FINAL_CONF_PATH. Please reload Apache manually."
    summarize
    exit 2
  fi

  info "Installation completed successfully."
  summarize
  exit 0
}

main "$@"
