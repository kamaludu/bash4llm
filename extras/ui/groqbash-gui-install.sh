#!/usr/bin/env bash
# =============================================================================
# Minimal, robust installer for GroqBash GUI (Apache CGI)
# File: extras/ui/groqbash-gui-install.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Key: NO character-class patterns (no [...] used to detect globs)
set -euo pipefail
umask 077

PROJECT_NAME="groqbash-gui"
CONF_FILENAME="${PROJECT_NAME}.conf"
DEFAULT_PORT="19970"
CGI_URL_PATH="/groqbash-gui/cgi"
STATIC_URL_PATH="/groqbash-gui/static"

# runtime
APP_ROOT=""
APACHE_ROOT_OVERRIDE=""
PORT="$DEFAULT_PORT"
NONINTERACTIVE=0

APACHECTL=""
SERVER_ROOT=""
SERVER_CONFIG_PATH=""
APACHE_CONF_DIR=""
FINAL_CONF_PATH=""

TMP_FILES=()

err(){ printf 'ERROR: %s\n' "$*" >&2; }
warn(){ printf 'WARNING: %s\n' "$*" >&2; }
info(){ printf 'INFO: %s\n' "$*"; }

trap 'for f in "${TMP_FILES[@]:-}"; do [[ -e "$f" ]] && rm -f -- "$f"; done' EXIT INT TERM

portable_sha1() {
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 1 | awk '{print $1}'
  else
    awk '{s=s $0} END{print length(s)}'
  fi
}

safe_mktemp_in_dir() {
  local dir="$1" tmpl="${2:-tmp.XXXXXX}" tmp
  mkdir -p "$dir" 2>/dev/null || return 1
  if tmp="$(mktemp -p "$dir" "$tmpl" 2>/dev/null)"; then
    printf '%s' "$tmp"; return 0
  fi
  if (cd "$dir" 2>/dev/null && tmp="$(mktemp "$tmpl" 2>/dev/null)"); then
    printf '%s' "$dir/$tmp"; return 0
  fi
  local stamp rand seed hash short
  stamp="$(date +%s%N 2>/dev/null || printf '%s' "$RANDOM")"
  rand="$RANDOM"
  seed="${$}${rand}${stamp}"
  hash="$(printf '%s' "$seed" | portable_sha1 2>/dev/null || printf '%s' "$seed")"
  short="${hash:0:12}"
  tmp="$dir/${tmpl%XXXXXX}$$.${rand}.${stamp}.${short}"
  : >"$tmp"
  printf '%s' "$tmp"
}

# Detect apachectl/httpd
detect_apache() {
  if command -v apachectl >/dev/null 2>&1; then APACHECTL="apachectl"
  elif command -v httpd >/dev/null 2>&1; then APACHECTL="httpd"
  else err "apachectl or httpd not found"; return 1; fi
  return 0
}

# Derive SERVER_ROOT and SERVER_CONFIG_PATH from apachectl -V
derive_server_root() {
  local out httpd_root scf cfgpath cfgdir

  out="$("$APACHECTL" -V 2>/dev/null || true)"

  httpd_root="$(
    printf '%s\n' "$out" |
    awk -F'"' '/HTTPD_ROOT=/ {print $2; exit}'
  )"

  scf="$(
    printf '%s\n' "$out" |
    awk -F'"' '/SERVER_CONFIG_FILE=/ {print $2; exit}'
  )"

  if [[ -n "${APACHE_ROOT_OVERRIDE:-}" ]]; then
    if [[ -d "$APACHE_ROOT_OVERRIDE" ]]; then
      httpd_root="$(cd "$APACHE_ROOT_OVERRIDE" 2>/dev/null && pwd -P)"
      info "Using explicit Apache root: $httpd_root"
    else
      err "Provided --apache-root does not exist: $APACHE_ROOT_OVERRIDE"
      return 1
    fi
  fi

  if [[ -z "$httpd_root" || -z "$scf" ]]; then
    err "Could not parse HTTPD_ROOT or SERVER_CONFIG_FILE from $APACHECTL -V"
    return 1
  fi

  SERVER_ROOT="$(cd "$httpd_root" 2>/dev/null && pwd -P)"
  if [[ "$scf" = /* ]]; then
    cfgpath="$scf"
  else
    cfgpath="$SERVER_ROOT/$scf"
  fi

  if [[ ! -e "$cfgpath" ]]; then
    err "Server config file not found: $cfgpath"
    return 1
  fi

  cfgdir="$(cd "$(dirname -- "$cfgpath")" 2>/dev/null && pwd -P)"
  SERVER_CONFIG_PATH="$cfgdir/$(basename -- "$cfgpath")"

  if [[ ! -r "$SERVER_CONFIG_PATH" ]]; then
    err "Cannot read $SERVER_CONFIG_PATH"
    return 1
  fi

  info "Derived SERVER_ROOT: $SERVER_ROOT"
  info "Derived SERVER_CONFIG_PATH: $SERVER_CONFIG_PATH"
  return 0
}

# Detect if a string contains glob chars (* ? [) WITHOUT using [...]
contains_glob() {
  case "$1" in
    *\** ) return 0 ;;
    *\?* ) return 0 ;;
  esac

  case "$1" in
    *[*]* ) return 0 ;;
  esac

  return 1
}

# Expand simple patterns: absolute or relative to provided bases.
expand_simple_pattern() {
  local pattern="$1"; shift
  local base cand dirpart bname
  # if absolute
  if [[ "$pattern" = /* ]]; then
    cand="$pattern"
    if contains_glob "$cand"; then
      dirpart="$(dirname -- "$cand")"
      bname="$(basename -- "$cand")"
      [[ -d "$dirpart" ]] && find "$dirpart" -maxdepth 1 -type f -name "$bname" -print || true
    else
      [[ -e "$cand" ]] && printf '%s\n' "$cand"
    fi
    return 0
  fi
  for base in "$@"; do
    cand="$base/$pattern"
    if contains_glob "$cand"; then
      dirpart="$(dirname -- "$cand")"
      bname="$(basename -- "$cand")"
      [[ -d "$dirpart" ]] && find "$dirpart" -maxdepth 1 -type f -name "$bname" -print || true
    else
      [[ -e "$cand" ]] && printf '%s\n' "$cand"
    fi
  done
}

# Minimal parse_includes: follow Include/IncludeOptional lines (simple cases)
parse_includes() {
  local entry="$1" limit="${2:-6}"
  local -a stack seen
  stack=("$entry"); seen=()
  local depth=0 file curdir line pat matches m
  while [[ "${#stack[@]}" -gt 0 ]]; do
    file="${stack[0]}"; stack=("${stack[@]:1}")
    [[ -e "$file" ]] || continue
    file="$(cd "$(dirname -- "$file")" 2>/dev/null && pwd -P)/$(basename -- "$file")"
    for m in "${seen[@]}"; do [[ "$m" = "$file" ]] && continue 2; done
    seen+=("$file")
    printf '%s\n' "$file"
    depth=$((depth+1))
    if (( depth > limit )); then warn "Include depth limit reached"; continue; fi
    curdir="$(dirname -- "$file")"
    while IFS= read -r line || [[ -n "$line" ]]; do
      # trim leading/trailing
      line="$(printf '%s' "$line" | awk '{$1=$1;print}')"
      [[ -z "$line" ]] && continue
      # simple match: Include or IncludeOptional at line start (case-insensitive)
      if printf '%s\n' "$line" | grep -Eiq '^[[:space:]]*include(optional)?[[:space:]]+'; then
        pat="$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*[Ii]nclude(Optional)?[[:space:]]+//; s/[[:space:]]+$//')"
        case "$pat" in
          \"*\" ) pat="${pat#\"}"; pat="${pat%\"}" ;;
          \'*\' ) pat="${pat#\'}"; pat="${pat%\'}" ;;
          * ) pat="${pat%%#*}"; pat="$(printf '%s' "$pat" | awk '{$1=$1;print}')" ;;
        esac
        matches="$(expand_simple_pattern "$pat" "$curdir" "$SERVER_ROOT" "$(dirname -- "$SERVER_CONFIG_PATH")")"
        if [[ -n "$matches" ]]; then
          while IFS= read -r m; do
            [[ -z "$m" ]] && continue
            if [[ -d "$m" ]]; then
              while IFS= read -r -d '' f; do stack+=("$f"); done < <(find "$m" -maxdepth 1 -type f -print0 2>/dev/null)
            else
              stack+=("$m")
            fi
          done <<<"$matches"
        fi
      fi
    done <"$file"
  done
  for f in "${seen[@]}"; do printf '%s\n' "$f"; done | sort -u || true
}

# Pragmatic detect_conf_dir: check a few standard candidates and ensure they are included
detect_conf_dir() {
  local base_dir candidates cand probe included_files ok
  base_dir="$(dirname -- "$SERVER_CONFIG_PATH")"
  candidates=( "$base_dir/conf.d" "$base_dir/extra" "$base_dir/sites-enabled" "$base_dir" )
  for cand in "${candidates[@]}"; do
    [[ -d "$cand" ]] || continue
    # skip empty
    if ! find "$cand" -maxdepth 1 -type f -print -quit >/dev/null 2>&1; then continue; fi
    probe="$cand/.${CONF_FILENAME}.probe.$$"
    printf '%s\n' "# probe" >"$probe"
    TMP_FILES+=("$probe")
    # quick sanity: configtest should run
    if ! "$APACHECTL" configtest >/dev/null 2>&1; then
      rm -f -- "$probe" || true
      TMP_FILES=("${TMP_FILES[@]/$probe}") || true
      continue
    fi
    included_files="$(parse_includes "$SERVER_CONFIG_PATH" 6 || true)"
    ok=0
    if [[ -n "$included_files" ]]; then
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        fdir="$(dirname -- "$f")"
        if [[ "$fdir" = "$cand" ]] || [[ "$fdir" = "$cand"/* ]]; then ok=1; break; fi
      done <<<"$included_files"
    fi
    if [[ "$ok" -eq 1 ]]; then
      APACHE_CONF_DIR="$cand"
      rm -f -- "$probe" || true
      TMP_FILES=("${TMP_FILES[@]/$probe}") || true
      info "Selected Apache conf dir: $APACHE_CONF_DIR"
      return 0
    fi
    rm -f -- "$probe" || true
    TMP_FILES=("${TMP_FILES[@]/$probe}") || true
  done
  err "Could not find usable Apache conf dir near $SERVER_CONFIG_PATH"
  return 1
}

check_dependencies() {
  local reqs=(bash find sed mktemp awk)
  # awk or gawk acceptable (we require awk)
  if ! command -v awk >/dev/null 2>&1; then err "awk required"; return 1; fi
  if ! command -v sha1sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then err "sha1sum or shasum required"; return 1; fi
  local c
  for c in "${reqs[@]}"; do
    if ! command -v "$c" >/dev/null 2>&1; then err "Required command missing: $c"; return 1; fi
  done
  return 0
}

check_permissions_and_dirs() {
  local app_bin="$1"
  local runtime_dirs=( "$app_bin/config" "$app_bin/conversations" "$app_bin/files" "$app_bin/logs" "$app_bin/tmp" "$app_bin/assets" )
  for d in "${runtime_dirs[@]}"; do
    mkdir -p "$d" 2>/dev/null || true
    chmod 700 "$d" 2>/dev/null || warn "Could not set 700 on $d"
  done
  chmod 755 "$app_bin/gui-server.sh" 2>/dev/null || warn "Could not set 755 on gui-server.sh"
  chmod 755 "$app_bin/gui-bootstrap.sh" 2>/dev/null || warn "Could not set 755 on gui-bootstrap.sh"
  [[ -d "$app_bin/templates" ]] && find "$app_bin/templates" -type f -exec chmod 644 {} \; 2>/dev/null || true
  [[ -d "$app_bin/config" ]] && find "$app_bin/config" -maxdepth 1 -type f -exec chmod 600 {} \; 2>/dev/null || true
}

check_groqbash_bootstrap() {
  local bootstrap="$1/gui-bootstrap.sh"
  if [[ ! -f "$bootstrap" ]]; then err "Missing $bootstrap"; return 1; fi
  if ! ( set -euo pipefail; . "$bootstrap"; ensure_groqbash_available ); then
    err "ensure_groqbash_available failed"; return 1
  fi
  return 0
}

check_cgi_module() {
  local mods
  mods="$("$APACHECTL" -M 2>/dev/null || true)"
  if ! printf '%s\n' "$mods" | grep -E 'cgid_module|cgi_module' >/dev/null 2>&1; then
    warn "mod_cgid or mod_cgi not detected; CGI may not work until enabled"
  else
    info "CGI module appears loaded"
  fi
}

# port_in_use with ss/netstat/dev/tcp
port_in_use() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :$p )" >/dev/null 2>&1 && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    if netstat -tln >/dev/null 2>&1; then
      netstat -tln | awk '{print $4}' | grep -E ":$p\$" >/dev/null 2>&1 && return 0 || return 1
    fi
  fi
  if ( exec 3<>/dev/tcp/127.0.0.1/"$p" ) 2>/dev/null; then
    exec 3>&- 3<&- || true
    return 0
  fi
  return 1
}

choose_port_interactive() {
  local tries=3 alt
  while port_in_use "$PORT"; do
    warn "Port $PORT in use"
    if (( tries <= 0 )); then err "No available port chosen"; return 1; fi
    if [[ "$NONINTERACTIVE" -eq 1 ]]; then err "Port in use and non-interactive"; return 1; fi
    printf 'Choose alternative port (or Enter to abort): '
    read -r alt || true
    [[ -z "$alt" ]] && { err "Aborted"; return 1; }
    if ! printf '%s' "$alt" | grep -Eq '^[0-9]+$' || (( alt < 1025 || alt > 65535 )); then
      warn "Invalid port"; tries=$((tries-1)); continue
    fi
    PORT="$alt"
  done
  return 0
}

generate_vhost_config() {
  local out="$1" app_bin="$2" app_static="$3" sock="$4"
  cat >"$out" <<EOF
# ${PROJECT_NAME} Apache config (generated)
ScriptSock "${sock}"

Listen ${PORT}
<VirtualHost *:${PORT}>
    ScriptAlias ${CGI_URL_PATH} "${app_bin}/gui-server.sh"
    Alias ${STATIC_URL_PATH} "${app_static}"

    <Directory "${app_bin}">
        Options +ExecCGI -Indexes
        AllowOverride None
        Require all granted
    </Directory>
EOF
  if [[ "$app_static" != "$app_bin" ]]; then
    cat >>"$out" <<EOF

    <Directory "${app_static}">
        Options -ExecCGI -Indexes
        AllowOverride None
        Require all granted
    </Directory>
EOF
  fi
  cat >>"$out" <<EOF

</VirtualHost>
EOF
}

run_configtest() {
  "$APACHECTL" configtest >/dev/null 2>&1
}

reload_apache() {
  if "$APACHECTL" graceful >/dev/null 2>&1; then return 0; fi
  if "$APACHECTL" restart >/dev/null 2>&1; then return 0; fi
  if command -v service >/dev/null 2>&1; then
    service apache2 reload >/dev/null 2>&1 || service httpd reload >/dev/null 2>&1 && return 0 || true
  fi
  warn "Apache reload failed; manual reload may be required"
  return 2
}

summarize() {
  printf '\n'
  info "APP_ROOT: $APP_ROOT"
  info "APACHE_CONF: $FINAL_CONF_PATH"
  info "PORT: $PORT"
  info "URL: http://localhost:${PORT}${CGI_URL_PATH}"
  printf '\n'
}

usage() {
  printf 'Usage: %s [--app-root PATH] [--apache-root PATH] [--port PORT] [--non-interactive]\n' "$0"
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-root) APP_ROOT="$2"; shift 2 ;;
      --apache-root) APACHE_ROOT_OVERRIDE="$2"; shift 2 ;;
      --port) PORT="$2"; shift 2 ;;
      --non-interactive) NONINTERACTIVE=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown arg: $1"; usage; exit 2 ;;
    esac
  done

  if [[ -z "${APP_ROOT:-}" ]]; then
    if ui_root="$(pwd)"; then
      # try to locate ui by walking up
      if [[ -f "./groqbash/groqbash.d/extras/ui/gui-server.sh" ]]; then
        APP_ROOT="$(pwd)"
      else
        # walk up
        local d="$PWD"
        while [[ "$d" != "/" && "$d" != "." ]]; do
          if [[ -f "$d/groqbash/groqbash.d/extras/ui/gui-server.sh" ]]; then
            APP_ROOT="$d"; break
          fi
          d="$(dirname -- "$d")"
        done
      fi
    fi
    if [[ -z "${APP_ROOT:-}" ]]; then err "Provide --app-root"; exit 1; fi
  fi

  APP_BIN="${APP_ROOT}/groqbash/groqbash.d/extras/ui"
  APP_STATIC="$APP_BIN"
  APP_RUNTIME_DIR="${APP_BIN}/runtime"
  APP_CGI_RUNTIME_DIR="${APP_RUNTIME_DIR}/cgid"
  CGI_SOCK_PATH="${APP_CGI_RUNTIME_DIR}/cgisock"

  detect_apache || exit 1
  derive_server_root || exit 1
  check_dependencies || exit 1
  detect_conf_dir || exit 1

  FINAL_CONF_PATH="${APACHE_CONF_DIR}/${CONF_FILENAME}"

  if [[ ! -d "$APP_BIN" ]]; then err "APP_BIN not found: $APP_BIN"; exit 1; fi
  if [[ ! -f "$APP_BIN/gui-server.sh" || ! -f "$APP_BIN/gui-bootstrap.sh" ]]; then err "Required UI scripts missing in $APP_BIN"; exit 1; fi

  mkdir -p "$APP_RUNTIME_DIR" "$APP_CGI_RUNTIME_DIR" 2>/dev/null || true
  chmod 700 "$APP_RUNTIME_DIR" 2>/dev/null || true
  chmod 700 "$APP_CGI_RUNTIME_DIR" 2>/dev/null || true

  check_permissions_and_dirs "$APP_BIN" || exit 1
  check_groqbash_bootstrap "$APP_BIN" || exit 1
  check_cgi_module

  if port_in_use "$PORT"; then
    info "Default port $PORT in use"
    if ! choose_port_interactive; then exit 1; fi
  fi

  mkdir -p "$(dirname -- "$CGI_SOCK_PATH")" 2>/dev/null || true
  chmod 700 "$(dirname -- "$CGI_SOCK_PATH")" 2>/dev/null || true

  local gen_tmp
  gen_tmp="$(safe_mktemp_in_dir "$APACHE_CONF_DIR" "${CONF_FILENAME}.gen.XXXXXX")"
  TMP_FILES+=("$gen_tmp")
  generate_vhost_config "$gen_tmp" "$APP_BIN" "$APP_STATIC" "$CGI_SOCK_PATH"

  if [[ -f "$FINAL_CONF_PATH" ]]; then
    if cmp -s "$gen_tmp" "$FINAL_CONF_PATH"; then
      info "Config identical; nothing to do"
      rm -f -- "$gen_tmp" || true
      TMP_FILES=("${TMP_FILES[@]/$gen_tmp}") || true
      summarize; exit 0
    fi
    if [[ "$NONINTERACTIVE" -eq 1 ]]; then
      err "Existing config differs and non-interactive mode set"; rm -f -- "$gen_tmp" || true; exit 1
    fi
    printf 'Existing config differs. Overwrite? [y/N]: '
    read -r ans || true
    case "$ans" in [Yy]) ;; *) info "Aborting"; rm -f -- "$gen_tmp" || true; exit 0 ;; esac
  fi

  if ! mv -f "$gen_tmp" "${FINAL_CONF_PATH}.pending" 2>/dev/null; then
    err "Failed to stage config"; rm -f -- "$gen_tmp" || true; exit 1
  fi
  TMP_FILES+=("${FINAL_CONF_PATH}.pending")

  if ! run_configtest; then
    rm -f -- "${FINAL_CONF_PATH}.pending" || true
    err "apachectl configtest failed after staging; pending file removed"; exit 1
  fi

  if ! mv -f "${FINAL_CONF_PATH}.pending" "$FINAL_CONF_PATH"; then
    err "Failed to install config"; rm -f -- "${FINAL_CONF_PATH}.pending" || true; exit 1
  fi
  TMP_FILES=("${TMP_FILES[@]/${FINAL_CONF_PATH}.pending}") || true

  if ! reload_apache; then
    warn "Apache reload failed; config installed at $FINAL_CONF_PATH"
    summarize; exit 2
  fi

  info "Installation completed"
  summarize
  exit 0
}

main "$@"
