#!/usr/bin/env bash
set -euo pipefail

# groqbash-gui-install.sh
# Installer for groqbash-gui Apache integration (Termux-friendly).
# Requirements: bash, coreutils, findutils, util-linux, gawk, curl, jq, apachectl, flock

PROJECT_NAME="groqbash-gui"
DEFAULT_PORT="19970"
CGI_URL_PATH="/groqbash-gui/cgi"
STATIC_URL_PATH="/groqbash-gui/static"
CONF_FILENAME="${PROJECT_NAME}.conf"
TERMUX_HOME="/data/data/com.termux/files/home"
TERMUX_PATH="/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets"

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
NONINTERACTIVE=0
EXPLICIT_APACHE_ROOT=""

# Logging helpers
err() { printf '%s\n' "ERROR: $*" >&2; }
warn() { printf '%s\n' "WARNING: $*" >&2; }
info() { printf '%s\n' "INFO: $*"; }

# Cleanup temp files on exit
cleanup_tmp() {
  for f in "${TMP_FILES[@]:-}"; do
    [[ -e "$f" ]] && rm -f -- "$f" || true
  done
}
on_exit() {
  cleanup_tmp
}
trap on_exit EXIT INT TERM

# Atomic write helper
write_atomic() {
  local dest="$1" src="$2" tmp
  tmp="$(mktemp "${dest}.tmp.XXXXXX")"
  TMP_FILES+=("$tmp")
  cat "$src" >"$tmp"
  sync || true
  mv -f "$tmp" "$dest"
  TMP_FILES=("${TMP_FILES[@]/$tmp}") || true
}

# Locate UI root by finding gui-server.sh in expected tree
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

# Detect apachectl/httpd
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
  # allow -v and -V to run later
  return 0
}

# Derive SERVER_ROOT and SERVER_CONFIG_FILE robustly from apachectl -V output
derive_server_root() {
  local out
  out="$("$APACHECTL" -V 2>/dev/null || true)"
  # Use robust sed extraction for -D HTTPD_ROOT="..."
  SERVER_ROOT="$(printf '%s\n' "$out" | sed -n 's/.*-D[[:space:]]*HTTPD_ROOT=\"\([^\"]*\)\".*/\1/p' | head -n1 || true)"
  SERVER_CONFIG_FILE="$(printf '%s\n' "$out" | sed -n 's/.*-D[[:space:]]*SERVER_CONFIG_FILE=\"\([^\"]*\)\".*/\1/p' | head -n1 || true)"
  # If SERVER_ROOT found and SERVER_CONFIG_FILE is relative, compute absolute path
  if [[ -n "$SERVER_ROOT" && -n "$SERVER_CONFIG_FILE" ]]; then
    # Normalize SERVER_ROOT
    SERVER_ROOT="$(cd "$SERVER_ROOT" 2>/dev/null && pwd -P || printf '%s' "$SERVER_ROOT")"
    return 0
  fi
  # If user provided explicit apache root, use it (explicit wins)
  if [[ -n "${EXPLICIT_APACHE_ROOT:-}" ]]; then
    if [[ -d "$EXPLICIT_APACHE_ROOT" ]]; then
      SERVER_ROOT="$(cd "$EXPLICIT_APACHE_ROOT" 2>/dev/null && pwd -P || printf '%s' "$EXPLICIT_APACHE_ROOT")"
      return 0
    else
      err "Explicit Apache root provided but directory does not exist: $EXPLICIT_APACHE_ROOT"
      return 1
    fi
  fi
  err "Could not determine Apache ServerRoot from $APACHECTL -V"
  return 1
}

# Candidate conf dirs in order
candidate_conf_dirs() {
  printf '%s\n' \
    "$SERVER_ROOT/conf.d" \
    "$SERVER_ROOT/extra" \
    "$SERVER_ROOT/conf" \
    "$SERVER_ROOT"
}

# Probe conf dir by writing a minimal probe file and running configtest
detect_conf_dir() {
  local cand tmpconf probe
  for cand in $(candidate_conf_dirs); do
    [[ -d "$cand" ]] || continue
    probe="$cand/.${CONF_FILENAME}.probe.$$"
    printf '%s\n' "## probe $PROJECT_NAME" >"$probe"
    TMP_FILES+=("$probe")
    if "$APACHECTL" configtest >/dev/null 2>&1; then
      APACHE_CONF_DIR="$cand"
      rm -f -- "$probe" || true
      TMP_FILES=("${TMP_FILES[@]/$probe}") || true
      return 0
    else
      rm -f -- "$probe" || true
      TMP_FILES=("${TMP_FILES[@]/$probe}") || true
    fi
  done
  return 1
}

# Check required commands
check_dependencies() {
  local reqs=(bash awk sed tr df mktemp readlink wc dd cat mv chmod rm printf basename dirname flock gawk curl jq)
  local cmd
  for cmd in "${reqs[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      err "Required command missing: $cmd"
      return 1
    fi
  done
  return 0
}

# Apply permission policy
check_permissions() {
  local script1="$APP_BIN/gui-server.sh"
  local script2="$APP_BIN/gui-bootstrap.sh"
  local templates_dir="$APP_BIN/templates"
  local runtime_dirs=( "$APP_BIN/config" "$APP_BIN/conversations" "$APP_BIN/files" "$APP_BIN/logs" "$APP_BIN/tmp" "$APP_BIN/assets" )
  local runtime_files=( "$APP_BIN/config/current-conversation" "$APP_BIN/config/lang-current" "$APP_BIN/config/gui-theme" "$APP_BIN/config/default-model" "$APP_BIN/config/default-provider" )
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
  if [[ -d "$templates_dir" ]]; then
    find "$templates_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
  fi
  for d in "${runtime_dirs[@]}"; do
    mkdir -p "$d" 2>/dev/null || true
    if ! chmod 700 "$d" 2>/dev/null; then
      warn "Could not tighten permissions on runtime dir $d"
    fi
  done
  for f in "${runtime_files[@]}"; do
    if [[ -e "$f" ]]; then
      if ! chmod 600 "$f" 2>/dev/null; then
        warn "Could not tighten permissions on runtime file $f"
      fi
    fi
  done
  return 0
}

# Verify GROQBASH_CMD via bootstrap (safe subshell)
check_groqbash_cmd() {
  local bootstrap="$APP_BIN/gui-bootstrap.sh"
  if [[ ! -f "$bootstrap" ]]; then
    err "gui-bootstrap.sh not found at $bootstrap"
    return 1
  fi
  if ! ( set -euo pipefail; . "$bootstrap"; ensure_groqbash_available ); then
    err "groqbash binary not resolvable by bootstrap (ensure_groqbash_available failed)"
    return 1
  fi
  return 0
}

# Check if port is in use
port_in_use() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :$p )" >/dev/null 2>&1 && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln | awk '{print $4}' | grep -E ":$p\$" >/dev/null 2>&1 && return 0 || return 1
  else
    return 1
  fi
}

# Prompt for alternative port
choose_port() {
  local tries=3 alt
  while port_in_use "$PORT"; do
    warn "Port $PORT appears in use."
    if [[ "$tries" -le 0 ]]; then
      err "No available port chosen. Aborting."
      return 1
    fi
    if [[ "$NONINTERACTIVE" -eq 1 ]]; then
      err "Port $PORT in use and non-interactive mode set. Aborting."
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

# Generate vhost config to file
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

# Write final conf atomically with configtest rollback rules
write_conf_atomic() {
  local target="$1" genfile="$2" pending
  pending="${target}.pending"
  if ! mv -f "$genfile" "$pending" 2>/dev/null; then
    rm -f -- "$genfile" || true
    err "Failed to move generated config to pending location."
    return 1
  fi
  TMP_FILES+=("$pending")
  if ! "$APACHECTL" configtest >/dev/null 2>&1; then
    rm -f -- "$pending" || true
    TMP_FILES=("${TMP_FILES[@]/$pending}") || true
    err "apachectl configtest failed after writing ${pending}; file removed."
    return 2
  fi
  if ! mv -f "$pending" "$target"; then
    rm -f -- "$pending" || true
    TMP_FILES=("${TMP_FILES[@]/$pending}") || true
    err "Failed to move ${pending} to $target; operation aborted."
    return 1
  fi
  TMP_FILES=("${TMP_FILES[@]/$pending}") || true
  return 0
}

# Run configtest wrapper
run_configtest() {
  if ! "$APACHECTL" configtest >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# Reload apache best-effort
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

# Print summary
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

# Main
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-root) APP_ROOT="$2"; shift 2 ;;
      --port) PORT="$2"; shift 2 ;;
      --apache-root) EXPLICIT_APACHE_ROOT="$2"; shift 2 ;;
      --non-interactive) NONINTERACTIVE=1; shift ;;
      -h|--help) printf 'Usage: %s [--app-root PATH] [--port PORT] [--apache-root PATH]\n' "$0"; exit 0 ;;
      *) err "Unknown arg: $1"; exit 2 ;;
    esac
  done

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

  detect_apache || exit 1
  derive_server_root || exit 1

  check_dependencies || exit 1

  if ! detect_conf_dir; then
    err "Could not find a writable/parsable Apache conf directory under $SERVER_ROOT. Aborting."
    exit 1
  fi

  FINAL_CONF_PATH="${APACHE_CONF_DIR}/${CONF_FILENAME}"

  if [[ ! -d "$APP_BIN" ]]; then
    err "APP_BIN not found at $APP_BIN"
    exit 1
  fi
  if [[ ! -f "$APP_BIN/gui-server.sh" || ! -f "$APP_BIN/gui-bootstrap.sh" ]]; then
    err "Required UI scripts missing in $APP_BIN"
    exit 1
  fi

  check_permissions || exit 1

  if ! check_groqbash_cmd; then
    err "GROQBASH_CMD check failed. Aborting."
    exit 1
  fi

  if port_in_use "$PORT"; then
    info "Default port $PORT appears in use."
    if ! choose_port; then
      exit 1
    fi
  fi

  local gen_tmp
  gen_tmp="$(mktemp "${APACHE_CONF_DIR}/${CONF_FILENAME}.gen.XXXXXX")"
  TMP_FILES+=("$gen_tmp")
  generate_vhost_config "$gen_tmp"

  if [[ -f "$FINAL_CONF_PATH" ]]; then
    if cmp -s "$gen_tmp" "$FINAL_CONF_PATH"; then
      info "Configuration already installed and identical. Nothing to do."
      rm -f -- "$gen_tmp" || true
      TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
      summarize
      exit 0
    else
      if [[ "$NONINTERACTIVE" -eq 1 ]]; then
        err "Existing config differs and non-interactive mode set. Aborting."
        rm -f -- "$gen_tmp" || true
        TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
        exit 1
      fi
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

  if ! write_conf_atomic "$FINAL_CONF_PATH" "$gen_tmp"; then
    err "Failed to install Apache config. Aborting."
    rm -f -- "$gen_tmp" || true
    TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
    exit 1
  fi
  rm -f -- "$gen_tmp" || true
  TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true

  if ! run_configtest; then
    rm -f -- "$FINAL_CONF_PATH" || true
    err "apachectl configtest failed after installing $FINAL_CONF_PATH. File removed. Aborting."
    exit 1
  fi

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
