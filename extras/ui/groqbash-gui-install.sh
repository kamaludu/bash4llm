#!/usr/bin/env bash
# =============================================================================
# extras/ui/groqbash-gui-install.sh
# Installer for GroqBash GUI Apache integration (CGI)
# - Practical, robust, Apache-driven installer
# - No edits to httpd.conf; writes a single groqbash-gui.conf in an included dir
# =============================================================================
set -euo pipefail
umask 077

PROJECT_NAME="groqbash-gui"
DEFAULT_PORT="19970"
CGI_URL_PATH="/groqbash-gui/cgi"
STATIC_URL_PATH="/groqbash-gui/static"
CONF_FILENAME="${PROJECT_NAME}.conf"

# Runtime vars
APP_ROOT=""
APP_BIN=""
APP_STATIC=""
APP_RUNTIME_DIR=""
APP_CGI_RUNTIME_DIR=""
CGI_SOCK_PATH=""

APACHECTL=""
SERVER_ROOT=""
SERVER_CONFIG_FILE=""
SERVER_CONFIG_PATH=""
APACHE_CONF_DIR=""
FINAL_CONF_PATH=""
PORT="$DEFAULT_PORT"
TMP_FILES=()
NONINTERACTIVE=0
EXPLICIT_APACHE_ROOT=""

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
err()  { printf 'ERROR: %s\n' "$*" >&2; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
info() { printf 'INFO: %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
cleanup_tmp() {
  for f in "${TMP_FILES[@]:-}"; do
    [[ -e "$f" ]] && rm -f -- "$f" || true
  done
}
trap cleanup_tmp EXIT INT TERM

# ---------------------------------------------------------------------------
# safe_mktemp_in_dir DIR [TEMPLATE]
# Create temp file inside DIR (same filesystem). Fallback uses pid,RAND,timestamp+sha1.
# ---------------------------------------------------------------------------
safe_mktemp_in_dir() {
  local dir="$1"; shift
  local tmpl="${1:-tmp.XXXXXX}"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null || return 1
  fi
  local tmp
  if tmp="$(mktemp -p "$dir" "$tmpl" 2>/dev/null)"; then
    printf '%s' "$tmp"
    return 0
  fi
  local stamp rand seed hash short
  stamp="$(date +%s%N 2>/dev/null || printf '%s' "$RANDOM")"
  rand="$RANDOM"
  seed="${$}${rand}${stamp}"
  hash="$(printf '%s' "$seed" | sha1sum 2>/dev/null | awk '{print $1}' || printf '%s' "$seed")"
  short="${hash:0:12}"
  tmp="$dir/${tmpl%XXXXXX}$$.${rand}.${stamp}.${short}"
  : >"$tmp"
  printf '%s' "$tmp"
  return 0
}

# ---------------------------------------------------------------------------
# write_conf_atomic TARGET GENFILE
# Move GENFILE into pending inside APACHE_CONF_DIR, run configtest, commit.
# On any failure remove pending and leave TARGET untouched.
# ---------------------------------------------------------------------------
write_conf_atomic() {
  local target="$1" genfile="$2"
  local ddir pending
  ddir="$(dirname -- "$target")"
  pending="$(safe_mktemp_in_dir "$ddir" "$(basename "$target").pending.XXXXXX")"
  TMP_FILES+=("$pending")
  if ! mv -f "$genfile" "$pending" 2>/dev/null; then
    rm -f -- "$genfile" || true
    err "Failed to move generated config to pending location."
    TMP_FILES=("${TMP_FILES[@]/$pending}") || true
    return 1
  fi
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

# ---------------------------------------------------------------------------
# locate_ui_root [start]
# Find project root by locating gui-server.sh
# ---------------------------------------------------------------------------
locate_ui_root() {
  local start dir candidate
  start="${1:-$(pwd)}"
  dir="$start"
  while true; do
    candidate="$dir/groqbash/groqbash.d/extras/ui/gui-server.sh"
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$(cd "$dir" && pwd -P)"
      return 0
    fi
    [[ "$dir" == "/" || "$dir" == "." ]] && break
    dir="$(dirname -- "$dir")"
  done
  return 1
}

# ---------------------------------------------------------------------------
# detect_apache
# ---------------------------------------------------------------------------
detect_apache() {
  if command -v apachectl >/dev/null 2>&1; then
    APACHECTL="apachectl"
  elif command -v httpd >/dev/null 2>&1; then
    APACHECTL="httpd"
  else
    err "Apache not found (apachectl or httpd). Aborting."
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# derive_server_root
# Parse HTTPD_ROOT and SERVER_CONFIG_FILE from apachectl -V and normalize.
# ---------------------------------------------------------------------------
derive_server_root() {
  local out httpd_root scf cfgpath cfgdir
  out="$("$APACHECTL" -V 2>/dev/null || true)"
  httpd_root="$(printf '%s\n' "$out" | sed -n 's/.*-D[[:space:]]*HTTPD_ROOT=\"\([^\"]*\)\".*/\1/p' | head -n1 || true)"
  scf="$(printf '%s\n' "$out" | sed -n 's/.*-D[[:space:]]*SERVER_CONFIG_FILE=\"\([^\"]*\)\".*/\1/p' | head -n1 || true)"

  if [[ -n "${EXPLICIT_APACHE_ROOT:-}" ]]; then
    if [[ -d "$EXPLICIT_APACHE_ROOT" ]]; then
      httpd_root="$(cd "$EXPLICIT_APACHE_ROOT" 2>/dev/null && pwd -P || printf '%s' "$EXPLICIT_APACHE_ROOT")"
      info "Using explicit Apache root: $httpd_root"
    else
      err "Explicit Apache root provided but directory does not exist: $EXPLICIT_APACHE_ROOT"
      return 1
    fi
  fi

  if [[ -z "$httpd_root" || -z "$scf" ]]; then
    err "Could not determine HTTPD_ROOT or SERVER_CONFIG_FILE from '$APACHECTL -V'."
    return 1
  fi

  SERVER_ROOT="$(cd "$httpd_root" 2>/dev/null && pwd -P || printf '%s' "$httpd_root")"
  SERVER_CONFIG_FILE="$scf"

  if [[ "$SERVER_CONFIG_FILE" = /* ]]; then
    cfgpath="$SERVER_CONFIG_FILE"
  else
    cfgpath="$SERVER_ROOT/$SERVER_CONFIG_FILE"
  fi

  if [[ -e "$cfgpath" ]]; then
    cfgdir="$(cd "$(dirname -- "$cfgpath")" 2>/dev/null && pwd -P)"
    SERVER_CONFIG_PATH="$cfgdir/$(basename -- "$cfgpath")"
  else
    err "SERVER_CONFIG_PATH does not exist: $cfgpath"
    return 1
  fi

  if [[ ! -r "$SERVER_CONFIG_PATH" ]]; then
    err "SERVER_CONFIG_PATH is not readable: $SERVER_CONFIG_PATH"
    return 1
  fi

  info "Derived SERVER_ROOT: $SERVER_ROOT"
  info "Derived SERVER_CONFIG_PATH: $SERVER_CONFIG_PATH"
  return 0
}

# ---------------------------------------------------------------------------
# expand_simple_pattern PATTERN BASES...
# Practical expansion for common patterns (dir/*.conf, dir/*.conf.gz etc.)
# Returns newline-separated matches.
# ---------------------------------------------------------------------------
expand_simple_pattern() {
  local pattern="$1"; shift
  local base cand dirpart bname
  # Absolute pattern
  if [[ "$pattern" = /* ]]; then
    cand="$pattern"
    if [[ "$cand" =~ [\*\?

\[] ]]; then
      dirpart="$(dirname -- "$cand")"
      bname="$(basename -- "$cand")"
      if [[ -d "$dirpart" ]]; then
        find "$dirpart" -maxdepth 1 -type f -name "$bname" -print
      fi
    else
      [[ -e "$cand" ]] && printf '%s\n' "$cand"
    fi
    return 0
  fi
  # Relative: try each base
  for base in "$@"; do
    cand="$base/$pattern"
    if [[ "$cand" =~ [\*\?

\[] ]]; then
      dirpart="$(dirname -- "$cand")"
      bname="$(basename -- "$cand")"
      if [[ -d "$dirpart" ]]; then
        find "$dirpart" -maxdepth 1 -type f -name "$bname" -print
      fi
    else
      [[ -e "$cand" ]] && printf '%s\n' "$cand"
    fi
  done
}

# ---------------------------------------------------------------------------
# parse_includes ENTRY [DEPTH_LIMIT]
# Recursively parse Include/IncludeOptional up to DEPTH_LIMIT (default 10).
# Tracks visited files to avoid cycles. Prints included file paths, one per line.
# ---------------------------------------------------------------------------
parse_includes() {
  local entry="$1"; shift
  local limit="${1:-10}"
  local -a stack
  local -A seen
  stack=("$entry")
  seen=()
  local depth=0 file curdir line pat matches m
  while [[ "${#stack[@]}" -gt 0 ]]; do
    file="${stack[0]}"; stack=("${stack[@]:1}")
    # Normalize
    if [[ -e "$file" ]]; then
      file="$(cd "$(dirname -- "$file")" 2>/dev/null && pwd -P)/$(basename -- "$file")"
    else
      continue
    fi
    [[ -n "${seen[$file]:-}" ]] && continue
    seen["$file"]=1
    # Emit the file as included
    printf '%s\n' "$file"
    # Prevent excessive recursion
    depth=$((depth+1))
    if (( depth > limit )); then
      warn "Include parsing depth limit ($limit) reached; stopping further recursion."
      continue
    fi
    curdir="$(dirname -- "$file")"
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Strip comments and trim
      line="${line%%#*}"
      line="$(printf '%s' "$line" | awk '{$1=$1;print}')"
      if [[ "$line" =~ ^[Ii]nclude(Optional)?[[:space:]]+(.+)$ ]]; then
        pat="${BASH_REMATCH[2]}"
        pat="${pat%\"}"; pat="${pat#\"}"
        pat="${pat%\'}"; pat="${pat#\'}"
        # Expand pattern against curdir, SERVER_ROOT, CONF_BASE_DIR
        matches="$(expand_simple_pattern "$pat" "$curdir" "$SERVER_ROOT" "$(dirname -- "$SERVER_CONFIG_PATH")")"
        while IFS= read -r m; do
          [[ -z "$m" ]] && continue
          # If directory, add its files (common case)
          if [[ -d "$m" ]]; then
            while IFS= read -r -d '' f; do
              stack+=("$f")
            done < <(find "$m" -maxdepth 1 -type f -print0)
          else
            stack+=("$m")
          fi
        done <<<"$matches"
      fi
    done <"$file"
  done

  # Print unique seen files (order not critical)
  for k in "${!seen[@]}"; do
    printf '%s\n' "$k"
  done
}

# ---------------------------------------------------------------------------
# detect_conf_dir
# Probe candidate dirs, run configtest, then verify inclusion with bounded parse.
# ---------------------------------------------------------------------------
detect_conf_dir() {
  local CONF_BASE_DIR cand probe included_files ok
  CONF_BASE_DIR="$(dirname -- "$SERVER_CONFIG_PATH")"
  local candidates=( "$CONF_BASE_DIR/conf.d" "$CONF_BASE_DIR/sites-enabled" "$CONF_BASE_DIR/extra" "$CONF_BASE_DIR" )
  for cand in "${candidates[@]}"; do
    [[ -d "$cand" ]] || continue
    probe="$cand/.${CONF_FILENAME}.probe.$$"
    printf '%s\n' "# probe for ${PROJECT_NAME}" >"$probe"
    TMP_FILES+=("$probe")
    if "$APACHECTL" configtest >/dev/null 2>&1; then
      # Parse includes with depth limit 10
      included_files="$(parse_includes "$SERVER_CONFIG_PATH" 10 || true)"
      ok=0
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        local fdir
        fdir="$(dirname -- "$f")"
        if [[ "$fdir" = "$cand" ]]; then ok=1; break; fi
        case "$fdir" in
          "$cand"/*) ok=1; break ;;
        esac
      done <<<"$included_files"
      if [[ "$ok" -eq 1 ]]; then
        APACHE_CONF_DIR="$cand"
        rm -f -- "$probe" || true
        TMP_FILES=("${TMP_FILES[@]/$probe}") || true
        info "Selected Apache conf dir: $APACHE_CONF_DIR"
        return 0
      fi
    fi
    rm -f -- "$probe" || true
    TMP_FILES=("${TMP_FILES[@]/$probe}") || true
  done
  printf 'ERROR: Could not find a usable Apache conf directory near %s\n' "$SERVER_CONFIG_PATH" >&2
  return 1
}

# ---------------------------------------------------------------------------
# check_dependencies
# Required tools per environment assumptions
# ---------------------------------------------------------------------------
check_dependencies() {
  local reqs=(bash coreutils find awk gawk sed mktemp sha1sum curl jq)
  local cmd
  for cmd in "${reqs[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      err "Required command missing: $cmd"
      return 1
    fi
  done
  return 0
}

# ---------------------------------------------------------------------------
# check_permissions
# Create runtime dirs and set permissions (best-effort). Use find for files.
# ---------------------------------------------------------------------------
check_permissions() {
  local script1="$APP_BIN/gui-server.sh"
  local script2="$APP_BIN/gui-bootstrap.sh"
  local templates_dir="$APP_BIN/templates"
  local runtime_dirs=( "$APP_BIN/config" "$APP_BIN/conversations" "$APP_BIN/files" "$APP_BIN/logs" "$APP_BIN/tmp" "$APP_BIN/assets" "$APP_RUNTIME_DIR" "$APP_CGI_RUNTIME_DIR" )

  for s in "$script1" "$script2"; do
    if [[ ! -f "$s" ]]; then
      err "Critical script missing: $s"
      return 1
    fi
    if ! chmod 755 "$s" 2>/dev/null; then
      warn "Could not set 755 on $s (may require elevated privileges)"
    fi
  done

  if [[ -d "$templates_dir" ]]; then
    find "$templates_dir" -type f -exec chmod 644 {} \; 2>/dev/null || warn "Could not set 644 on some template files"
  fi

  for d in "${runtime_dirs[@]}"; do
    if [[ -n "$d" ]]; then
      mkdir -p "$d" 2>/dev/null || true
      if ! chmod 700 "$d" 2>/dev/null; then
        warn "Could not set 700 on runtime dir $d (may require elevated privileges)"
      fi
    fi
  done

  if [[ -d "$APP_BIN/config" ]]; then
    find "$APP_BIN/config" -maxdepth 1 -type f -exec chmod 600 {} \; 2>/dev/null || warn "Could not set 600 on some config files"
  fi

  return 0
}

# ---------------------------------------------------------------------------
# check_groqbash_cmd
# Ensure groqbash is resolvable via gui-bootstrap.sh
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# check_cgi_module (warn only)
# ---------------------------------------------------------------------------
check_cgi_module() {
  local mods
  mods="$("$APACHECTL" -M 2>/dev/null || true)"
  if ! printf '%s\n' "$mods" | grep -E 'cgid_module|cgi_module' >/dev/null 2>&1; then
    warn "Neither mod_cgid nor mod_cgi appears to be loaded. CGI may not work until you enable one of them in your Apache config."
  else
    info "CGI module appears loaded."
  fi
}

# ---------------------------------------------------------------------------
# port_in_use: prefer ss/netstat, fallback to /dev/tcp
# ---------------------------------------------------------------------------
port_in_use() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :$p )" >/dev/null 2>&1 && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tln | awk '{print $4}' | grep -E ":$p\$" >/dev/null 2>&1 && return 0 || return 1
  else
    if ( exec 3<>/dev/tcp/127.0.0.1/"$p" ) 2>/dev/null; then
      exec 3>&- 3<&- || true
      return 0
    fi
    return 1
  fi
}

choose_port() {
  local tries=3 alt
  while port_in_use "$PORT"; do
    warn "Port $PORT appears in use."
    if (( tries <= 0 )); then
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

# ---------------------------------------------------------------------------
# generate_vhost_config OUT
# Emit ScriptSock (absolute) before Listen and VirtualHost
# ---------------------------------------------------------------------------
generate_vhost_config() {
  local out="$1"
  cat >"$out" <<EOF
# groqbash-gui Apache config (generated)
# ScriptSock must be in server config context and point to a socket path we control
ScriptSock "${CGI_SOCK_PATH}"

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
</VirtualHost>
EOF
}

# ---------------------------------------------------------------------------
# run_configtest
# ---------------------------------------------------------------------------
run_configtest() {
  if ! "$APACHECTL" configtest >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# reload_apache best-effort
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# summarize
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-root) APP_ROOT="$2"; shift 2 ;;
      --port) PORT="$2"; shift 2 ;;
      --apache-root) EXPLICIT_APACHE_ROOT="$2"; shift 2 ;;
      --non-interactive) NONINTERACTIVE=1; shift ;;
      -h|--help) printf 'Usage: %s [--app-root PATH] [--port PORT] [--apache-root PATH] [--non-interactive]\n' "$0"; exit 0 ;;
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
  APP_RUNTIME_DIR="${APP_BIN}/runtime"
  APP_CGI_RUNTIME_DIR="${APP_RUNTIME_DIR}/cgid"
  CGI_SOCK_PATH="${APP_CGI_RUNTIME_DIR}/cgisock"

  detect_apache || exit 1
  derive_server_root || exit 1

  check_dependencies || exit 1

  if ! detect_conf_dir; then
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

  # Ensure runtime dirs exist and are private
  mkdir -p "$APP_RUNTIME_DIR" "$APP_CGI_RUNTIME_DIR" 2>/dev/null || true
  if ! chmod 700 "$APP_RUNTIME_DIR" 2>/dev/null; then
    warn "Could not set 700 on $APP_RUNTIME_DIR (may require elevated privileges)"
  fi
  if ! chmod 700 "$APP_CGI_RUNTIME_DIR" 2>/dev/null; then
    warn "Could not set 700 on $APP_CGI_RUNTIME_DIR (may require elevated privileges)"
  fi

  check_permissions || exit 1

  if ! check_groqbash_cmd; then
    err "GROQBASH_CMD check failed. Aborting."
    exit 1
  fi

  check_cgi_module

  if port_in_use "$PORT"; then
    info "Default port $PORT appears in use."
    if ! choose_port; then
      exit 1
    fi
  fi

  mkdir -p "$(dirname -- "$CGI_SOCK_PATH")" 2>/dev/null || true
  if ! chmod 700 "$(dirname -- "$CGI_SOCK_PATH")" 2>/dev/null; then
    warn "Could not set 700 on $(dirname -- "$CGI_SOCK_PATH") (may require elevated privileges)"
  fi

  # Generate config into temp inside APACHE_CONF_DIR
  local gen_tmp
  gen_tmp="$(safe_mktemp_in_dir "$APACHE_CONF_DIR" "${CONF_FILENAME}.gen.XXXXXX")"
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
