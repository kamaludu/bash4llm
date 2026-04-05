#!/usr/bin/env bash
# =============================================================================
# File: groqbash-gui-adapt.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Adapt GroqBash GUI for the current environment (Termux-specific shebang fixes).
# Hard constraints: only depends on bash, coreutils, findutils, util-linux, gawk, curl, jq.
# Idempotent, safe to re-run. Operates only inside groqbash/groqbash.d/extras/ui.
set -euo pipefail
umask 077

# -------- Configuration --------
UI_ROOT_DEFAULT="${HOME:-$PWD}/groqbash/groqbash.d/extras/ui"
UI_ROOT="${UI_ROOT:-$UI_ROOT_DEFAULT}"

# TARGET_FILES will be normalized after canonicalizing UI_ROOT
TARGET_FILES_REL=(
  "gui-server.sh"
  "gui-bootstrap.sh"
)
CGI_DIR_REL="cgi-bin"

DEFAULT_PORT=19970

TS() { date +%s; }

# -------- Logging & exit helpers (stderr only) --------
log() { printf '%s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf 'INFO: %s\n' "$*" >&2; }

# -------- Utility: ensure absolute canonical UI_ROOT and confinement --------
canonicalize_ui_root() {
  if [ -z "${UI_ROOT:-}" ]; then
    err "UI_ROOT is empty"
  fi
  if [ ! -e "$UI_ROOT" ]; then
    err "UI_ROOT does not exist: $UI_ROOT"
  fi
  if [ ! -d "$UI_ROOT" ]; then
    err "UI_ROOT is not a directory: $UI_ROOT"
  fi
  if [ -L "$UI_ROOT" ]; then
    err "UI_ROOT must not be a symlink: $UI_ROOT"
  fi
  local oldpwd
  oldpwd="$(pwd -P)"
  if ! cd -- "$UI_ROOT" 2>/dev/null; then
    err "Failed to cd into UI_ROOT: $UI_ROOT"
  fi
  UI_ROOT="$(pwd -P)"
  cd -- "$oldpwd" || true

  case "$UI_ROOT" in
    "$HOME"/*) ;;
    "$HOME") ;;
    *)
      err "UI_ROOT must be inside HOME: $HOME; got: $UI_ROOT"
      ;;
  esac

  CGI_DIR="$UI_ROOT/$CGI_DIR_REL"
}

# -------- Evita scritture fuori da UI_ROOT (Termux / sicurezza) --------
# Sposta eventuale $HOME/bin creato per errore dentro UI_ROOT/bin e impedisce
# la creazione di nuovi wrapper fuori da UI_ROOT.
enforce_ui_root_only_writes() {
  local home_bin ui_bin moved=0

  # percorso bin dell'utente (possibile fonte di artefatti indesiderati)
  home_bin="${HOME:-/data/data/com.termux/files/home}/bin"
  ui_bin="${UI_ROOT}/bin"

  # Se esiste una home_bin e non è dentro UI_ROOT, spostane il contenuto in UI_ROOT/bin
  if [ -d "$home_bin" ] && ! path_within_ui_root "$home_bin"; then
    mkdir -p -- "$ui_bin" 2>/dev/null || true
    # sposta solo file regolari e non sovrascrive
    if find "$home_bin" -maxdepth 1 -type f -print0 | grep -q .; then
      while IFS= read -r -d '' f; do
        # evita sovrascrivere file già presenti in UI_ROOT/bin
        if [ ! -e "$ui_bin/$(basename -- "$f")" ]; then
          mv -n -- "$f" "$ui_bin/" 2>/dev/null || cp -n -- "$f" "$ui_bin/" 2>/dev/null || true
          moved=1
        fi
      done < <(find "$home_bin" -maxdepth 1 -type f -print0 2>/dev/null)
    fi
    # se la directory home_bin è ora vuota, rimuovila
    if [ -d "$home_bin" ] && [ -z "$(ls -A "$home_bin" 2>/dev/null)" ]; then
      rmdir --ignore-fail-on-non-empty "$home_bin" 2>/dev/null || true
    fi
  fi

  # Assicura che ogni codice che crea wrapper usi UI_ROOT/bin: esporta BIN_DIR per i processi figli
  export BIN_DIR="$ui_bin"
  mkdir -p -- "$BIN_DIR" 2>/dev/null || true
  chmod 700 -- "$BIN_DIR" 2>/dev/null || true

  if [ "$moved" -eq 1 ]; then
    info "Spostati file da $home_bin a $BIN_DIR per confinare gli artefatti nella UI_ROOT"
  fi

  return 0
}

# -------- Path safety check: ensure path is inside UI_ROOT (canonicalized) --------
path_within_ui_root() {
  # $1: candidate path (absolute or relative)
  local p="$1"
  if [ -z "$p" ]; then
    return 1
  fi

  # If relative, it's considered under UI_ROOT
  if [ "${p#/}" = "$p" ]; then
    return 0
  fi

  # For absolute paths, canonicalize the parent directory to avoid ../ bypass
  local cand_dir real_dir
  cand_dir="$(dirname -- "$p")"
  if ! real_dir="$(cd -- "$cand_dir" 2>/dev/null && pwd -P)"; then
    return 1
  fi

  case "$real_dir" in
    "$UI_ROOT"/*|"$UI_ROOT") return 0 ;;
    *) return 1 ;;
  esac
}

# -------- Portable mktemp fallback (atomic create) --------
portable_mktemp() {
  # $1: destdir
  local dir="$1" tmp
  if tmp="$(mktemp "${dir}/.tmp.XXXXXX" 2>/dev/null)"; then
    chmod 600 -- "$tmp" 2>/dev/null || true
    printf '%s' "$tmp"
    return 0
  fi
  tmp="${dir}/.tmp.$$.$RANDOM.$(date +%s)"
  mkdir -p -- "$dir"
  ( set -C; : >"$tmp" ) 2>/dev/null || return 1
  chmod 600 -- "$tmp" 2>/dev/null || true
  printf '%s' "$tmp"
  return 0
}

# -------- Escape replacement for sed (escape & and backslashes) --------
sed_escape_replacement() {
  # Escape backslash, delimiter '|' (used in sed), slash and ampersand
  local s
  s="$1"
  # escape backslash first
  s="${s//\\/\\\\}"
  # escape delimiter '|' and slash and ampersand
  s="${s//|/\\|}"
  s="${s//\//\\/}"
  s="${s//&/\\&}"
  printf '%s' "$s"
}

# -------- Atomic write inside UI_ROOT --------
# NOTE: atomic_write_in_uiroot reads the content to write from stdin.
# Usage: atomic_write_in_uiroot "/path/inside/ui_root" <sourcefile
# This design avoids loading large content into shell variables and ensures
# the write is atomic and confined to UI_ROOT. Callers must redirect the
# source into the function as shown above.
atomic_write_in_uiroot() {
  # $1: dest path (absolute)
  # NOTE: reads content from stdin. Usage:
  #   atomic_write_in_uiroot "/path/inside/ui_root" <sourcefile
  local dest="$1"
  if [ -z "$dest" ]; then
    err "atomic_write_in_uiroot: dest empty"
  fi
  if ! path_within_ui_root "$dest"; then
    err "Refusing to write outside UI_ROOT: $dest"
  fi
  local destdir tmp
  destdir="$(dirname -- "$dest")"
  mkdir -p -- "$destdir"
  chmod 700 -- "$destdir" || true
  tmp="$(portable_mktemp "$destdir")" || {
    err "portable_mktemp failed for $destdir"
  }
  chmod 600 -- "$tmp" || true
  cat >"$tmp"
  mv -f -- "$tmp" "$dest"
  chmod 600 -- "$dest" 2>/dev/null || true
  if ! path_within_ui_root "$dest"; then
    err "Post-write check failed: $dest is outside UI_ROOT"
  fi
}

# -------- Atomic append inside UI_ROOT --------
atomic_append_conv_in_uiroot() {
  local dest="$1"
  if ! path_within_ui_root "$dest"; then
    err "Refusing to append outside UI_ROOT: $dest"
  fi
  local destdir tmp
  destdir="$(dirname -- "$dest")"
  mkdir -p -- "$destdir"
  chmod 700 -- "$destdir" || true
  tmp="$(portable_mktemp "$destdir")" || {
    err "portable_mktemp failed for $destdir"
  }
  chmod 600 -- "$tmp" || true
  if [ -e "$dest" ]; then
    cat -- "$dest" >"$tmp"
  fi
  cat >>"$tmp"
  mv -f -- "$tmp" "$dest"
  if ! path_within_ui_root "$dest"; then
    err "Post-append check failed: $dest is outside UI_ROOT"
  fi
}

# -------- Dependency check (no fallback; fail with clear message) --------
# Note: pgrep is intentionally not required here to avoid failing adaptation on
# minimal systems. pgrep is only used at runtime by the generated launcher if present.
check_deps() {
  local deps=(bash sed awk grep uname mktemp mv cp chmod date printf test head tail find curl jq)
  local miss=()
  for d in "${deps[@]}"; do
    if ! command -v "$d" >/dev/null 2>&1; then
      miss+=("$d")
    fi
  done
  if [ "${#miss[@]}" -ne 0 ]; then
    err "Missing required commands: ${miss[*]}. Install required packages and retry."
  fi
}

# -------- Environment detection --------
detect_env() {
  if [ -d "/data/data/com.termux/files/usr" ]; then
    printf 'termux'
    return 0
  fi
  if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
    printf 'macos'
    return 0
  fi
  if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
    printf 'wsl'
    return 0
  fi
  if uname -o 2>/dev/null | grep -qi cygwin 2>/dev/null; then
    printf 'cygwin'
    return 0
  fi
  if [ "$(uname -s 2>/dev/null)" = "Linux" ]; then
    printf 'linux'
    return 0
  fi
  printf 'unknown'
  return 0
}

# -------- Termux bash discovery (small safe fallback set) --------
find_termux_bash() {
  local candidates=(
    "/data/data/com.termux/files/usr/bin/bash"
    "/system/bin/bash"
  )
  for p in "${candidates[@]}"; do
    if [ -x "$p" ]; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}

# -------- Safety helpers --------
is_regular_file() {
  [ -f "$1" ] && [ ! -L "$1" ]
}

backup_file_in_uiroot() {
  local f="$1" ts bdir b
  ts="$(TS)"
  if ! path_within_ui_root "$f"; then
    err "Refusing to backup outside UI_ROOT: $f"
  fi
  bdir="$(dirname -- "$f")"
  mkdir -p -- "$bdir"
  chmod 700 -- "$bdir" || true
  b="${f}.bak.${ts}"
  cp -- "$f" "$b"
  printf '%s' "$b"
}

atomic_replace_first_line_in_uiroot() {
  local file="$1" new_shebang="$2"
  if ! path_within_ui_root "$file"; then
    err "Refusing to modify outside UI_ROOT: $file"
  fi
  local tmp
  tmp="$(portable_mktemp "$(dirname -- "$file")")" || {
    err "portable_mktemp failed for $(dirname -- "$file")"
  }
  {
    printf '%s\n' "$new_shebang"
    # preserve rest of file, normalizing CRLF
    tail -n +2 -- "$file" | sed -e 's/\r$//'
  } >"$tmp"
  mv -f -- "$tmp" "$file"
  if ! path_within_ui_root "$file"; then
    err "Post-replace check failed: $file is outside UI_ROOT"
  fi
}

# -------- Process a single file (idempotent) --------
process_target() {
  local file="$1" bash_path="$2"
  if [ ! -e "$file" ]; then
    info "Skipping missing file: $file"
    return 0
  fi
  if ! path_within_ui_root "$file"; then
    info "Skipping file outside UI_ROOT: $file"
    return 0
  fi
  if ! is_regular_file "$file" ; then
    info "Skipping non-regular file (symlink/device): $file"
    return 0
  fi

  # Normalize line endings safely in-place using a temp file inside UI_ROOT
  local tmpnorm
  tmpnorm="$(portable_mktemp "$(dirname -- "$file")")" || err "mktemp failed for $(dirname -- "$file")"
  sed -e 's/\r$//' "$file" >"$tmpnorm"
  mv -f -- "$tmpnorm" "$file"
  if ! path_within_ui_root "$file"; then
    err "Post-normalize check failed: $file is outside UI_ROOT"
  fi

  # Decide action based on file type: shell scripts get shebang patch; others get readable perms
  local current_first ext target_shebang
  current_first="$(head -n1 -- "$file" || true)"
  ext="${file##*.}"
  target_shebang="#!${bash_path}"

  # If not a shell script (no shebang and not .sh), ensure readable perms and return
  if [[ "$current_first" != "#!"* && "$ext" != "sh" ]]; then
    info "Not a shell script; ensuring readable perms: $file"
    chmod 644 -- "$file" 2>/dev/null || true
    return 0
  fi

  # If shebang already matches target, ensure executable and return
  if [ "$current_first" = "$target_shebang" ]; then
    info "Shebang already correct: $file"
    chmod 755 -- "$file" || true
    return 0
  fi

  # Backup and atomically replace first line with the correct shebang
  local backup
  backup="$(backup_file_in_uiroot "$file")" || err "Failed to backup $file"
  info "Backup created: $backup"

  atomic_replace_first_line_in_uiroot "$file" "$target_shebang" || {
    err "Failed to write new shebang to $file; attempting rollback"
    mv -f -- "$backup" "$file" || err "Rollback failed for $file"
    err "Rolled back $file to backup"
  }

  chmod 755 -- "$file" || err "Failed to chmod $file"

  info "Patched shebang: $file -> $target_shebang"
}

# -------- Generate Termux Apache config (only writes under UI_ROOT) --------
generate_termux_apache_config() {
  local conf="$UI_ROOT/apache-termux-gui-${DEFAULT_PORT}.conf"
  local logs_dir="$UI_ROOT/logs"
  local www_dir="$UI_ROOT/www"
  local cgi_dir="$UI_ROOT/cgi-bin"
  local static_dir="$UI_ROOT/static"

  # create dirs with recommended perms (ensure existence)
  mkdir -p -- "$logs_dir" "$www_dir" "$cgi_dir" "$UI_ROOT/var/run/apache2" "$static_dir"
  chmod 700 -- "$logs_dir" || true
  chmod 755 -- "$www_dir" "$cgi_dir" "$static_dir" || true
  chmod 700 -- "$UI_ROOT/var/run/apache2" || true

  # Modules to try: name:path
  modules_to_try=(
    "mpm_prefork_module:/data/data/com.termux/files/usr/libexec/apache2/mod_mpm_prefork.so"
    "authz_core_module:/data/data/com.termux/files/usr/libexec/apache2/mod_authz_core.so"
    "authz_host_module:/data/data/com.termux/files/usr/libexec/apache2/mod_authz_host.so"
    "alias_module:/data/data/com.termux/files/usr/libexec/apache2/mod_alias.so"
    "cgi_module:/data/data/com.termux/files/usr/libexec/apache2/mod_cgi.so"
    "log_config_module:/data/data/com.termux/files/usr/libexec/apache2/mod_log_config.so"
    "logio_module:/data/data/com.termux/files/usr/libexec/apache2/mod_logio.so"
    "unixd_module:/data/data/com.termux/files/usr/libexec/apache2/mod_unixd.so"
    "dir_module:/data/data/com.termux/files/usr/libexec/apache2/mod_dir.so"
  )

  # build header with LoadModule lines only for existing modules
  local tmpheader loaded_mods name path
  tmpheader="$(portable_mktemp "$UI_ROOT")" || err "mktemp failed for header"
  loaded_mods=""
  for m in "${modules_to_try[@]}"; do
    name="${m%%:*}"
    path="${m#*:}"
    if [ -f "$path" ]; then
      printf 'LoadModule %s "%s"\n' "$name" "$path" >>"$tmpheader"
      loaded_mods="${loaded_mods} ${name}"
    fi
  done
  printf '\nServerName localhost\nDirectoryIndex index.html\n\n' >>"$tmpheader"
  info "Will include LoadModule for:${loaded_mods}"

  # build body (template) without global <RequireAny>
  local tmpconf
  tmpconf="$(portable_mktemp "$UI_ROOT")" || err "Failed to create temp for apache conf"
  cat >"$tmpconf" <<'EOF'
# GroqBash GUI Termux Apache config (standalone, confined to UI_ROOT)
# Generated by groqbash-gui-adapt.sh

Listen 127.0.0.1:__PORT__

# Runtime files confined to UI_ROOT to avoid global /var/run conflicts
PidFile "__UI_ROOT__/var/run/apache2/httpd.pid"
ScoreBoardFile "__LOG_DIR__/apache_runtime_status"

DocumentRoot "__WWW_DIR__"
<Directory "__WWW_DIR__">
    Options -Indexes +FollowSymLinks
    Require local
</Directory>

# CGI entrypoint: single executable that renders the GUI
# Map the canonical GUI URL to the gui-server.sh entrypoint inside UI_ROOT
ScriptAlias /groqbash-gui/cgi/ "__UI_ROOT__/gui-server.sh"
# Optional backwards-compat alias (commented): map /cgi-bin/ to the same entrypoint if needed
# ScriptAlias /cgi-bin/ "__UI_ROOT__/gui-server.sh"

# Serve static assets from dedicated static directory (note trailing slashes)
Alias /groqbash-gui/static/ "__UI_ROOT__/static/"

<Directory "__UI_ROOT__/static/">
    Options -Indexes +FollowSymLinks
    Require local
</Directory>

# Normalize requests without trailing slash to the canonical CGI base (idempotent redirect)
RedirectMatch 301 ^/groqbash-gui/cgi$ /groqbash-gui/cgi/

# Grant ExecCGI on the application directory (app_bin / UI_ROOT)
<Directory "__UI_ROOT__/">
    Options +ExecCGI -Indexes
    AllowOverride None
    Require local
</Directory>

ErrorLog "__LOG_DIR__/error.log"
CustomLog "__LOG_DIR__/access.log" common
EOF

  # Escape replacements
  local esc_www esc_cgi esc_log esc_uiroot finaltmp
  esc_www="$(sed_escape_replacement "$www_dir")"
  esc_cgi="$(sed_escape_replacement "$cgi_dir")"
  esc_log="$(sed_escape_replacement "$logs_dir")"
  esc_uiroot="$(sed_escape_replacement "$UI_ROOT")"

  # concatenate header + body, substitute placeholders, write atomically inside UI_ROOT
  finaltmp="$(portable_mktemp "$UI_ROOT")" || err "mktemp failed for final conf"
  cat "$tmpheader" "$tmpconf" | \
    sed -e "s|__WWW_DIR__|${esc_www}|g" \
        -e "s|__CGI_DIR__|${esc_cgi}|g" \
        -e "s|__LOG_DIR__|${esc_log}|g" \
        -e "s|__UI_ROOT__|${esc_uiroot}|g" \
        -e "s|__PORT__|${DEFAULT_PORT}|g" \
    >"$finaltmp"

  atomic_write_in_uiroot "$conf" <"$finaltmp"

  # cleanup temps
  rm -f -- "$tmpheader" "$tmpconf" "$finaltmp" || true

  # secure perms for config and ensure logs exist
  chmod 600 -- "$conf" || true
  touch "$logs_dir/error.log" "$logs_dir/access.log" 2>/dev/null || true
  chmod 600 -- "$logs_dir/error.log" "$logs_dir/access.log" 2>/dev/null || true

  # Explicit permissions policy (idempotent enforcement)
  # Directories
  chmod 755 -- "$www_dir" "$cgi_dir" "$static_dir" || true
  chmod 700 -- "$logs_dir" || true

  # Files: static assets -> 644; CGI scripts -> 755
  if [ -d "$static_dir" ]; then
    find "$static_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
  fi
  find "$www_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
  find "$cgi_dir" -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
  find "$cgi_dir" -type f ! -name '*.sh' -exec chmod 644 {} \; 2>/dev/null || true

  # Ensure scoreboard file exists and has safe perms
  : >"$logs_dir/apache_runtime_status" 2>/dev/null || true
  chmod 600 "$logs_dir/apache_runtime_status" 2>/dev/null || true

  info "Generated Apache config: $conf"
  info "DocumentRoot: $www_dir"
  info "CGI dir: $cgi_dir"
  info "Static dir: $static_dir"
  info "Logs: $logs_dir"
}

# -------- Generate Termux launcher script (only writes under UI_ROOT) --------
generate_termux_launcher() {
  local launcher="$UI_ROOT/groqbash-gui-termux.sh"
  local conf="$UI_ROOT/apache-termux-gui-${DEFAULT_PORT}.conf"
  local logs_dir="$UI_ROOT/logs"
  local status_dir="$UI_ROOT/.status"
  local static_dir="$UI_ROOT/static"
  mkdir -p -- "$status_dir"
  chmod 700 -- "$status_dir" || true

  local termux_bash
  termux_bash="$(find_termux_bash || true)"
  if [ -z "$termux_bash" ]; then
    err "No Termux bash found; cannot generate launcher"
  fi

  # Locate candidate httpd/apachectl in PATH
  local httpd_path
  httpd_path="$(command -v httpd 2>/dev/null || true)"
  if [ -z "$httpd_path" ]; then
    httpd_path="$(command -v apachectl 2>/dev/null || true)"
  fi

  if [ -z "$httpd_path" ]; then
    err "No httpd or apachectl found in PATH; launcher requires a userland httpd available to the Termux user."
  fi

  # Ownership check: prefer userland under Termux data or owned by current uid
  local owner_uid
  owner_uid="$(stat -c '%u' "$httpd_path" 2>/dev/null || true)"
  if [ -n "$owner_uid" ]; then
    if [ "$owner_uid" -ne "$(id -u)" ]; then
      case "$httpd_path" in
        /data/data/*|/data/data/com.termux/*|/data/data/com.termux/files/*) ;;
        *)
          err "httpd at $httpd_path appears not to be a Termux userland binary (owner UID $owner_uid). Launcher requires a httpd that can be started by the Termux user."
          ;;
      esac
    fi
  else
    case "$httpd_path" in
      /data/data/*|/data/data/com.termux/*|/data/data/com.termux/files/*) ;;
      *)
        err "Unable to verify ownership of $httpd_path; to be safe, launcher requires a userland httpd located under Termux data."
        ;;
    esac
  fi

  if ! command -v pgrep >/dev/null 2>&1; then
    info "Note: pgrep not found on this system. Generated launcher will still work but runtime process detection may be limited."
  fi

  local tmplaunch
  tmplaunch="$(portable_mktemp "$UI_ROOT")" || err "Failed to create temp for launcher"

  cat >"$tmplaunch" <<'EOF'
#!__TERMUX_BASH__
set -euo pipefail
umask 077

UI_ROOT="__UI_ROOT__"
CONF="$UI_ROOT/apache-termux-gui-__PORT__.conf"
LOGS="$UI_ROOT/logs"
STATUS_DIR="$UI_ROOT/.status"
URL="http://127.0.0.1:__PORT__/"

TS() { date +%s; }
log() { printf 'INFO: %s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if [ ! -d "$UI_ROOT" ]; then
  err "UI_ROOT missing: $UI_ROOT"
fi
if [ ! -f "$CONF" ]; then
  err "Apache config not found: $CONF"
fi

is_listening() {
  if command -v ss >/dev/null 2>&1; then
    ss_out="$(ss -ltn 2>&1 || true)"
    if printf '%s' "$ss_out" | grep -q -E "127\.0\.0\.1:__PORT__"; then
      return 0
    fi
    if printf '%s' "$ss_out" | grep -qiE 'permission denied|cannot open netlink|operation not permitted'; then
      :
    fi
  fi
  if command -v netstat >/dev/null 2>&1; then
    if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -q "127.0.0.1:__PORT__"; then
      return 0
    fi
  fi
  if ( exec 3<>/dev/tcp/127.0.0.1/"__PORT__" ) 2>/dev/null; then
    exec 3>&- 3<&- || true
    return 0
  fi
  return 1
}

find_httpd() {
  if command -v httpd >/dev/null 2>&1; then
    printf '%s' "httpd"
    return 0
  fi
  if command -v apachectl >/dev/null 2>&1; then
    printf '%s' "apachectl"
    return 0
  fi
  return 1
}

ensure_no_stale_pid() {
  PIDFILE="$UI_ROOT/var/run/apache2/httpd.pid"
  if [ -f "$PIDFILE" ]; then
    pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [ -n "$pid" ] && ! ps -p "$pid" >/dev/null 2>&1; then
      log "Removing stale pidfile: $PIDFILE (pid $pid not running)"
      rm -f -- "$PIDFILE" || true
    else
      log "Pidfile present and process $pid running (or unreadable pid); attempting controlled stop"
      httpd_bin="$(find_httpd || true)"
      if [ -n "$httpd_bin" ]; then
        "$httpd_bin" -k stop -f "$CONF" 2>>"$LOGS/error.log" || true
        sleep 1
        if [ -f "$PIDFILE" ]; then
          pid2="$(cat "$PIDFILE" 2>/dev/null || true)"
          if [ -n "$pid2" ] && ! ps -p "$pid2" >/dev/null 2>&1; then
            rm -f -- "$PIDFILE" || true
          fi
        fi
      fi
    fi
  fi
}

wait_for_listen() {
  local i max=10
  for i in $(seq 1 $max); do
    if is_listening; then
      return 0
    fi
    sleep 0.3
  done
  return 1
}

is_running_with_conf() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f -- "$CONF" >/dev/null 2>&1
    return $?
  fi
  ps aux 2>/dev/null | grep -F -- "$CONF" | grep -v grep >/dev/null 2>&1
  return $?
}

if is_listening || is_running_with_conf; then
  log "127.0.0.1:__PORT__ already listening or httpd already started with $CONF; opening browser"
else
  httpd_bin="$(find_httpd || true)"
  if [ -z "$httpd_bin" ]; then
    err "No httpd/apachectl binary found in PATH; cannot start server"
  fi

  # Ensure runtime dirs exist and have safe perms, and ensure static dir exists and is traversable
  mkdir -p -- "$UI_ROOT/var/run/apache2" "$LOGS" "$UI_ROOT/static"
  chmod 700 -- "$UI_ROOT/var/run/apache2" "$LOGS" 2>/dev/null || true
  chmod 755 -- "$UI_ROOT/static" 2>/dev/null || true
  # ensure static assets are readable if present
  if [ -d "$UI_ROOT/static" ]; then
    find "$UI_ROOT/static" -type f -exec chmod 644 {} \; 2>/dev/null || true
  fi

  if "$httpd_bin" -t -f "$CONF" >/dev/null 2>&1; then
    if "$httpd_bin" -h 2>/dev/null | grep -q -- '-k'; then
      "$httpd_bin" -f "$CONF" -k start >/dev/null 2>>"$LOGS/error.log" &
    else
      "$httpd_bin" -f "$CONF" >/dev/null 2>>"$LOGS/error.log" &
    fi
  else
    log "Diagnostic: '$httpd_bin -t -f $CONF' failed; attempting direct start and then checking listen status"
    "$httpd_bin" -f "$CONF" >/dev/null 2>>"$LOGS/error.log" &
  fi

  if ! wait_for_listen; then
    log "Server did not start listening on 127.0.0.1:__PORT__; dumping httpd -t output for debugging"
    "$httpd_bin" -t -f "$CONF" 2>>"$LOGS/error.log" || true
    err "Server did not start or is not listening on 127.0.0.1:__PORT__ (see $LOGS/error.log)"
  fi
  log "Started httpd using $httpd_bin (logs: $LOGS)"
fi

# Open browser
if command -v termux-open-url >/dev/null 2>&1; then
  termux-open-url "$URL" || log "termux-open-url failed; open manually: $URL"
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 || log "xdg-open failed; open manually: $URL"
else
  log "Open your browser at: $URL"
fi

TSV=$(TS)
echo "launched_at=$TSV" >"$STATUS_DIR/last-launch.$TSV"
EOF

  sed -e "s|__TERMUX_BASH__|${termux_bash}|g" \
      -e "s|__UI_ROOT__|${UI_ROOT}|g" \
      -e "s|__PORT__|${DEFAULT_PORT}|g" \
      "$tmplaunch" | atomic_write_in_uiroot "$launcher"
  rm -f -- "$tmplaunch" || true
  chmod 750 -- "$launcher" || true
  info "Generated Termux launcher: $launcher"
}

# -------- Helper: safe remove stale global pid (best-effort) --------
cleanup_global_stale_pid() {
  local global_pidfile="/data/data/com.termux/files/usr/var/run/apache2/httpd.pid"
  if [ -f "$global_pidfile" ]; then
    local pid
    pid="$(cat "$global_pidfile" 2>/dev/null || true)"
    if [ -n "$pid" ] && ! ps -p "$pid" >/dev/null 2>&1; then
      warn "Removing stale global pid file: $global_pidfile (pid $pid not running)"
      rm -f -- "$global_pidfile" 2>/dev/null || true
    fi
  fi
}

# -------- Main --------
main() {
  check_deps

  canonicalize_ui_root
  enforce_ui_root_only_writes

  # trap: cleanup temporary files created under UI_ROOT on exit or error
  cleanup_tmp() {
    # remove only files that match the portable_mktemp prefixes created by this script
    # limit depth to avoid accidental wide deletions
    if [ -d "$UI_ROOT" ]; then
      find "$UI_ROOT" -maxdepth 3 -type f -name '.tmp.*' -exec rm -f -- {} + 2>/dev/null || true
    fi
  }
  trap 'cleanup_tmp' EXIT INT TERM

  # create essential runtime dirs under UI_ROOT (including confined runtime for httpd)
  mkdir -p -- "$UI_ROOT/.tmp" "$UI_ROOT/logs" "$UI_ROOT/www" "$UI_ROOT/cgi-bin" "$UI_ROOT/.status" "$UI_ROOT/var/run/apache2"
  chmod 700 -- "$UI_ROOT/.tmp" "$UI_ROOT/logs" "$UI_ROOT/www" "$UI_ROOT/cgi-bin" "$UI_ROOT/.status" "$UI_ROOT/var/run/apache2" || true

  # normalize TARGET_FILES to absolute paths under UI_ROOT
  TARGET_FILES=()
  for rel in "${TARGET_FILES_REL[@]}"; do
    TARGET_FILES+=("$UI_ROOT/$rel")
  done
  CGI_DIR="$UI_ROOT/$CGI_DIR_REL"

  env_type="$(detect_env)"
  info "Detected environment: $env_type"

  case "$env_type" in
    termux)
      bash_path="$(find_termux_bash || true)"
      if [ -z "$bash_path" ]; then
        err "No valid bash found on Termux. Required: /data/data/com.termux/files/usr/bin/bash or /system/bin/bash"
      fi
      info "Using bash: $bash_path"

      files_to_process=()
      for f in "${TARGET_FILES[@]}"; do
        files_to_process+=("$f")
      done
      if [ -d "$CGI_DIR" ]; then
        while IFS= read -r -d '' shf; do
          files_to_process+=("$shf")
        done < <(find "$CGI_DIR" -maxdepth 1 -type f -name '*.sh' -print0)
      fi

      declare -A seen=()
      for f in "${files_to_process[@]}"; do
        [ -z "$f" ] && continue
        if [ ! -e "$f" ]; then
          info "Target not present, skipping: $f"
          continue
        fi
        if ! path_within_ui_root "$f"; then
          info "Skipping file outside UI_ROOT: $f"
          continue
        fi
        if [ "${seen[$f]+_}" ]; then
          continue
        fi
        seen["$f"]=1
        process_target "$f" "$bash_path"
      done

      ensure_sh_executables "$UI_ROOT"

      generate_termux_apache_config
      generate_termux_launcher
      ;;
    linux|macos|wsl|cygwin|unknown)
      info "No adaptation required for environment: $env_type"
      local sysbash
      sysbash="$(command -v bash || true)"
      if [ -n "$sysbash" ]; then
        declare -A seen2=()
        for f in "${TARGET_FILES[@]}"; do
          [ -z "$f" ] && continue
          if [ ! -e "$f" ]; then
            info "Target not present, skipping: $f"
            continue
          fi
          if ! path_within_ui_root "$f"; then
            info "Skipping file outside UI_ROOT: $f"
            continue
          fi
          if [ "${seen2[$f]+_}" ]; then
            continue
          fi
          seen2["$f"]=1
          process_target "$f" "$sysbash"
        done
      fi
      ;;
    *)
      err "Unhandled environment: $env_type"
      ;;
  esac

  info "groqbash-gui-adapt.sh completed"
  info "Artifacts (if any) are confined to: $UI_ROOT"
  info "If Termux: use $UI_ROOT/groqbash-gui-termux.sh to start the GUI (the launcher will start the confined httpd if needed and open the browser)."
  info "To test the Apache config manually (if httpd supports it): httpd -t -f $UI_ROOT/apache-termux-gui-${DEFAULT_PORT}.conf"
}

main "$@"
