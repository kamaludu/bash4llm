#!/usr/bin/env bash
# =============================================================================
# Adapt GroqBash GUI for the current environment (Termux-specific shebang fixes)
# File: groqbash-gui-adapt.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Constraints: only depends on bash, coreutils, findutils, util-linux, gawk, curl, jq.
# No use of system /tmp; no eval; idempotent; confined writes under UI_ROOT.
set -euo pipefail
umask 077

# -------- Configuration --------
UI_ROOT_DEFAULT="${HOME:-$PWD}/groqbash/groqbash.d/extras/ui"
UI_ROOT="${UI_ROOT:-$UI_ROOT_DEFAULT}"
: "${INSTALL_MODE:=0}"

TARGET_FILES_REL=(
  "gui-server.sh"
  "gui-bootstrap.sh"
)
CGI_DIR_REL="cgi-bin"

DEFAULT_PORT=19970

TS() { date +%s; }

# -------- Logging helpers (stderr) --------
log()  { printf '%s\n' "$*" >&2; }
info() { printf 'INFO: %s\n' "$*" >&2; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# -------- Canonicalize UI_ROOT and confinement --------
canonicalize_ui_root() {
  if [ -z "${UI_ROOT:-}" ]; then err "UI_ROOT is empty"; fi
  if [ ! -e "$UI_ROOT" ]; then err "UI_ROOT does not exist: $UI_ROOT"; fi
  if [ ! -d "$UI_ROOT" ]; then err "UI_ROOT is not a directory: $UI_ROOT"; fi
  if [ -L "$UI_ROOT" ]; then err "UI_ROOT must not be a symlink: $UI_ROOT"; fi

  local oldpwd
  oldpwd="$(pwd -P)"
  if ! cd -- "$UI_ROOT" 2>/dev/null; then err "Failed to cd into UI_ROOT: $UI_ROOT"; fi
  UI_ROOT="$(pwd -P)"
  cd -- "$oldpwd" || true

  case "$UI_ROOT" in
    "$HOME"/*|"$HOME") ;;
    *) err "UI_ROOT must be inside HOME: $HOME; got: $UI_ROOT";;
  esac

  CGI_DIR="$UI_ROOT/$CGI_DIR_REL"
}

# -------- Prevent writes outside UI_ROOT --------
enforce_ui_root_only_writes() {
  local home_bin ui_bin moved=0
  home_bin="${HOME:-/data/data/com.termux/files/home}/bin"
  ui_bin="${UI_ROOT}/bin"

  if [ -d "$home_bin" ] && ! path_within_ui_root "$home_bin"; then
    mkdir -p -- "$ui_bin" 2>/dev/null || true
    if find "$home_bin" -maxdepth 1 -type f -print0 | grep -q .; then
      while IFS= read -r -d '' f; do
        if [ ! -e "$ui_bin/$(basename -- "$f")" ]; then
          mv -n -- "$f" "$ui_bin/" 2>/dev/null || cp -n -- "$f" "$ui_bin/" 2>/dev/null || true
          moved=1
        fi
      done < <(find "$home_bin" -maxdepth 1 -type f -print0 2>/dev/null)
    fi
    if [ -d "$home_bin" ] && [ -z "$(ls -A "$home_bin" 2>/dev/null)" ]; then
      rmdir --ignore-fail-on-non-empty "$home_bin" 2>/dev/null || true
    fi
  fi

  export BIN_DIR="$ui_bin"
  mkdir -p -- "$BIN_DIR" 2>/dev/null || true
  chmod 700 -- "$BIN_DIR" 2>/dev/null || true

  if [ "$moved" -eq 1 ]; then
    info "Moved files from $home_bin to $BIN_DIR to confine artifacts in UI_ROOT"
  fi
}

# -------- Path safety check --------
path_within_ui_root() {
  local p="$1"
  [ -n "$p" ] || return 1
  # Require absolute path
  if [ "${p#/}" = "$p" ]; then return 1; fi
  local cand_dir real_dir
  cand_dir="$(dirname -- "$p")"
  if ! real_dir="$(cd -- "$cand_dir" 2>/dev/null && pwd -P)"; then return 1; fi
  case "$real_dir" in "$UI_ROOT"/*|"$UI_ROOT") return 0;; *) return 1;; esac
}

# -------- Escape replacement for sed --------
sed_escape_replacement() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//|/\\|}"
  s="${s//\//\\/}"
  s="${s//&/\\&}"
  printf '%s' "$s"
}

# -------- Atomic write confined to UI_ROOT --------
atomic_write_in_uiroot() {
  local dest="$1"
  [ -n "$dest" ] || err "atomic_write_in_uiroot: dest empty"
  if ! path_within_ui_root "$dest"; then err "Refusing to write outside UI_ROOT: $dest"; fi
  local destdir tmp
  destdir="$(dirname -- "$dest")"
  mkdir -p -- "$destdir"
  chmod 700 -- "$destdir" || true
  tmp="$(portable_mktemp "$destdir")" || err "portable_mktemp failed for $destdir"
  chmod 600 -- "$tmp" || true
  cat >"$tmp"
  mv -f -- "$tmp" "$dest"
  chmod 600 -- "$dest" 2>/dev/null || true
  if ! path_within_ui_root "$dest"; then err "Post-write check failed: $dest is outside UI_ROOT"; fi
}

# -------- Atomic append confined to UI_ROOT --------
atomic_append_conv_in_uiroot() {
  local dest="$1"
  if ! path_within_ui_root "$dest"; then err "Refusing to append outside UI_ROOT: $dest"; fi
  local destdir tmp
  destdir="$(dirname -- "$dest")"
  mkdir -p -- "$destdir"
  chmod 700 -- "$destdir" || true
  tmp="$(portable_mktemp "$destdir")" || err "portable_mktemp failed for $destdir"
  chmod 600 -- "$tmp" || true
  if [ -e "$dest" ]; then cat -- "$dest" >"$tmp"; fi
  cat >>"$tmp"
  mv -f -- "$tmp" "$dest"
  if ! path_within_ui_root "$dest"; then err "Post-append check failed: $dest is outside UI_ROOT"; fi
}

# -------- Dependency check (strict) --------
check_deps() {
  local deps=(bash sed awk grep uname mktemp mv cp chmod date printf head tail find curl jq readlink flock)
  local miss=()
  for d in "${deps[@]}"; do
    if ! command -v "$d" >/dev/null 2>&1; then miss+=("$d"); fi
  done
  if [ "${#miss[@]}" -ne 0 ]; then err "Missing required commands: ${miss[*]}"; fi
}

# -------- Environment detection --------
detect_env() {
  if [ -d "/data/data/com.termux/files/usr" ]; then printf 'termux'; return 0; fi
  if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then printf 'macos'; return 0; fi
  if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then printf 'wsl'; return 0; fi
  if uname -o 2>/dev/null | grep -qi cygwin 2>/dev/null; then printf 'cygwin'; return 0; fi
  if [ "$(uname -s 2>/dev/null)" = "Linux" ]; then printf 'linux'; return 0; fi
  printf 'unknown'; return 0
}

# -------- Termux bash discovery --------
find_termux_bash() {
  local candidates=(
    "/data/data/com.termux/files/usr/bin/bash"
    "/system/bin/bash"
    "/bin/bash"
  )
  for p in "${candidates[@]}"; do
    if [ -x "$p" ]; then printf '%s' "$p"; return 0; fi
  done
  return 1
}

# -------- Safety helpers --------
is_regular_file() { [ -f "$1" ] && [ ! -L "$1" ]; }

backup_file_in_uiroot() {
  local f="$1" ts bdir b
  ts="$(TS)"
  if ! path_within_ui_root "$f"; then err "Refusing to backup outside UI_ROOT: $f"; fi
  bdir="$(dirname -- "$f")"
  mkdir -p -- "$bdir"
  chmod 700 -- "$bdir" || true
  b="${f}.bak.${ts}"
  cp -- "$f" "$b"
  chmod 600 -- "$b" 2>/dev/null || true
  printf '%s' "$b"
}

atomic_replace_first_line_in_uiroot() {
  local file="$1" new_shebang="$2"
  if ! path_within_ui_root "$file"; then err "Refusing to modify outside UI_ROOT: $file"; fi
  local tmp
  tmp="$(portable_mktemp "$(dirname -- "$file")")" || err "portable_mktemp failed for $(dirname -- "$file")"
  {
    printf '%s\n' "$new_shebang"
    tail -n +2 -- "$file" | sed -e 's/\r$//'
  } >"$tmp"
  mv -f -- "$tmp" "$file"
  chmod 755 -- "$file" 2>/dev/null || true
  if ! path_within_ui_root "$file"; then err "Post-replace check failed: $file is outside UI_ROOT"; fi
}

# -------- Process a single file (idempotent) --------
process_target() {
  local file="$1" bash_path="$2"
  [ -e "$file" ] || { info "Skipping missing file: $file"; return 0; }
  if ! path_within_ui_root "$file"; then info "Skipping file outside UI_ROOT: $file"; return 0; fi
  if ! is_regular_file "$file"; then info "Skipping non-regular file: $file"; return 0; fi

  local tmpnorm
  tmpnorm="$(portable_mktemp "$(dirname -- "$file")")" || err "mktemp failed for $(dirname -- "$file")"
  sed -e 's/\r$//' "$file" >"$tmpnorm"
  mv -f -- "$tmpnorm" "$file"
  if ! path_within_ui_root "$file"; then err "Post-normalize check failed: $file is outside UI_ROOT"; fi

  local current_first ext target_shebang
  current_first="$(head -n1 -- "$file" || true)"
  ext="${file##*.}"
  target_shebang="#!${bash_path}"

  if [[ "$current_first" != "#!"* && "$ext" != "sh" ]]; then
    info "Not a shell script; ensuring readable perms: $file"
    chmod 644 -- "$file" 2>/dev/null || true
    return 0
  fi

  if [ "$current_first" = "$target_shebang" ]; then
    info "Shebang already correct: $file"
    chmod 755 -- "$file" || true
    return 0
  fi

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

# -------- Generate Termux Apache config (confined) --------
generate_termux_apache_config() {
  local conf="$UI_ROOT/apache-termux-gui-${DEFAULT_PORT}.conf"
  local logs_dir="$UI_ROOT/logs" www_dir="$UI_ROOT/www" cgi_dir="$UI_ROOT/cgi-bin" static_dir="$UI_ROOT/static"

  mkdir -p -- "$logs_dir" "$www_dir" "$cgi_dir" "$UI_ROOT/var/run/apache2" "$static_dir"
  chmod 700 -- "$logs_dir" || true
  chmod 755 -- "$www_dir" "$cgi_dir" "$static_dir" || true
  chmod 700 -- "$UI_ROOT/var/run/apache2" || true

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

  local tmpheader loaded_mods name path
  tmpheader="$(portable_mktemp "$UI_ROOT")" || err "mktemp failed for header"
  loaded_mods=""
  for m in "${modules_to_try[@]}"; do
    name="${m%%:*}"; path="${m#*:}"
    if [ -f "$path" ]; then
      printf 'LoadModule %s "%s"\n' "$name" "$path" >>"$tmpheader"
      loaded_mods="${loaded_mods} ${name}"
    fi
  done
  printf '\nServerName localhost\nDirectoryIndex index.html\n\n' >>"$tmpheader"
  info "Will include LoadModule for:${loaded_mods}"

  local tmpconf finaltmp
  tmpconf="$(portable_mktemp "$UI_ROOT")" || err "Failed to create temp for apache conf"
  cat >"$tmpconf" <<'EOF'
# GroqBash GUI Termux Apache config (standalone, confined to UI_ROOT)
# Generated by groqbash-gui-adapt.sh

Listen 127.0.0.1:__PORT__

PidFile "__UI_ROOT__/var/run/apache2/httpd.pid"
ScoreBoardFile "__LOG_DIR__/apache_runtime_status"

DocumentRoot "__WWW_DIR__"
<Directory "__WWW_DIR__">
    Options -Indexes +FollowSymLinks
    Require local
</Directory>

ScriptAlias /groqbash-gui/cgi/ "__UI_ROOT__/gui-server.sh"

Alias /groqbash-gui/static/ "__UI_ROOT__/static/"

<Directory "__UI_ROOT__/static/">
    Options -Indexes +FollowSymLinks
    Require local
</Directory>

RedirectMatch 301 ^/groqbash-gui/cgi$ /groqbash-gui/cgi/

<Directory "__UI_ROOT__/">
    Options +ExecCGI -Indexes
    AllowOverride None
    Require local
</Directory>

ErrorLog "__LOG_DIR__/error.log"
CustomLog "__LOG_DIR__/access.log" common
EOF

  local esc_www esc_cgi esc_log esc_uiroot
  esc_www="$(sed_escape_replacement "$www_dir")"
  esc_cgi="$(sed_escape_replacement "$cgi_dir")"
  esc_log="$(sed_escape_replacement "$logs_dir")"
  esc_uiroot="$(sed_escape_replacement "$UI_ROOT")"

  finaltmp="$(portable_mktemp "$UI_ROOT")" || err "mktemp failed for final conf"
  cat "$tmpheader" "$tmpconf" | sed -e "s|__WWW_DIR__|${esc_www}|g" -e "s|__CGI_DIR__|${esc_cgi}|g" -e "s|__LOG_DIR__|${esc_log}|g" -e "s|__UI_ROOT__|${esc_uiroot}|g" -e "s|__PORT__|${DEFAULT_PORT}|g" >"$finaltmp"

  atomic_write_in_uiroot "$conf" <"$finaltmp"
  rm -f -- "$tmpheader" "$tmpconf" "$finaltmp" || true

  chmod 600 -- "$conf" || true
  touch "$logs_dir/error.log" "$logs_dir/access.log" 2>/dev/null || true
  chmod 600 -- "$logs_dir/error.log" "$logs_dir/access.log" 2>/dev/null || true

  chmod 755 -- "$www_dir" "$cgi_dir" "$static_dir" || true
  chmod 700 -- "$logs_dir" || true

  if [ -d "$static_dir" ]; then find "$static_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true; fi
  find "$www_dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
  find "$cgi_dir" -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
  find "$cgi_dir" -type f ! -name '*.sh' -exec chmod 644 {} \; 2>/dev/null || true

  : >"$logs_dir/apache_runtime_status" 2>/dev/null || true
  chmod 600 "$logs_dir/apache_runtime_status" 2>/dev/null || true

  info "Generated Apache config: $conf"
}

# -------- Generate Termux launcher (confined) --------
generate_termux_launcher() {
  local launcher="$UI_ROOT/groqbash-gui-termux.sh"
  local conf="$UI_ROOT/apache-termux-gui-${DEFAULT_PORT}.conf"
  local logs_dir="$UI_ROOT/logs" status_dir="$UI_ROOT/.status" static_dir="$UI_ROOT/static"
  mkdir -p -- "$status_dir" 2>/dev/null || true
  chmod 700 -- "$status_dir" 2>/dev/null || true

  local termux_bash
  termux_bash="$(find_termux_bash || true)"
  if [ -z "$termux_bash" ]; then err "No Termux bash found; cannot generate launcher"; fi

  local httpd_path
  httpd_path="$(command -v httpd 2>/dev/null || true)"
  if [ -z "$httpd_path" ]; then httpd_path="$(command -v apachectl 2>/dev/null || true)"; fi
  if [ -z "$httpd_path" ]; then err "No httpd or apachectl found in PATH"; fi

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
log() { printf '%s\n' "INFO: $*" >&2; }
err() { printf '%s\n' "ERROR: $*" >&2; exit 1; }

if [ ! -d "$UI_ROOT" ]; then err "UI_ROOT missing: $UI_ROOT"; fi
if [ ! -f "$CONF" ]; then err "Apache config not found: $CONF"; fi

is_listening() {
  if command -v ss >/dev/null 2>&1; then
    ss_out="$(ss -ltn 2>&1 || true)"
    if printf '%s' "$ss_out" | grep -q -E "127\.0\.0\.1:__PORT__"; then return 0; fi
  fi
  if command -v netstat >/dev/null 2>&1; then
    if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -q "127.0.0.1:__PORT__"; then return 0; fi
  fi
  if ( exec 3<>/dev/tcp/127.0.0.1/"__PORT__" ) 2>/dev/null; then exec 3>&- 3<&- || true; return 0; fi
  return 1
}

find_httpd() {
  if command -v httpd >/dev/null 2>&1; then printf '%s' "httpd"; return 0; fi
  if command -v apachectl >/dev/null 2>&1; then printf '%s' "apachectl"; return 0; fi
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
      log "Pidfile present; attempting controlled stop"
      httpd_bin="$(find_httpd || true)"
      if [ -n "$httpd_bin" ]; then
        "$httpd_bin" -k stop -f "$CONF" 2>>"$LOGS/error.log" || true
        sleep 1
        if [ -f "$PIDFILE" ]; then
          pid2="$(cat "$PIDFILE" 2>/dev/null || true)"
          if [ -n "$pid2" ] && ! ps -p "$pid2" >/dev/null 2>&1; then rm -f -- "$PIDFILE" || true; fi
        fi
      fi
    fi
  fi
}

wait_for_listen() {
  local i max=10
  for i in $(seq 1 $max); do
    if is_listening; then return 0; fi
    sleep 0.3
  done
  return 1
}

is_running_with_conf() {
  if command -v pgrep >/dev/null 2>&1; then pgrep -f -- "$CONF" >/dev/null 2>&1; return $?; fi
  ps aux 2>/dev/null | grep -F -- "$CONF" | grep -v grep >/dev/null 2>&1; return $?
}

if is_listening || is_running_with_conf; then
  log "127.0.0.1:__PORT__ already listening or httpd started with $CONF; opening browser"
else
  httpd_bin="$(find_httpd || true)"
  if [ -z "$httpd_bin" ]; then err "No httpd/apachectl binary found in PATH; cannot start server"; fi

  mkdir -p -- "$UI_ROOT/var/run/apache2" "$LOGS" "$UI_ROOT/static"
  chmod 700 -- "$UI_ROOT/var/run/apache2" "$LOGS" 2>/dev/null || true
  chmod 755 -- "$UI_ROOT/static" 2>/dev/null || true
  if [ -d "$UI_ROOT/static" ]; then find "$UI_ROOT/static" -type f -exec chmod 644 {} \; 2>/dev/null || true; fi

  if "$httpd_bin" -t -f "$CONF" >/dev/null 2>&1; then
    if "$httpd_bin" -h 2>/dev/null | grep -q -- '-k'; then
      "$httpd_bin" -f "$CONF" -k start >/dev/null 2>>"$LOGS/error.log" &
    else
      "$httpd_bin" -f "$CONF" >/dev/null 2>>"$LOGS/error.log" &
    fi
  else
    log "Diagnostic: '$httpd_bin -t -f $CONF' failed; attempting direct start"
    "$httpd_bin" -f "$CONF" >/dev/null 2>>"$LOGS/error.log" &
  fi

  if ! wait_for_listen; then
    log "Server did not start listening on 127.0.0.1:__PORT__; dumping httpd -t output"
    "$httpd_bin" -t -f "$CONF" 2>>"$LOGS/error.log" || true
    err "Server did not start or is not listening on 127.0.0.1:__PORT__ (see $LOGS/error.log)"
  fi
  log "Started httpd using $httpd_bin (logs: $LOGS)"
fi

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

  sed -e "s|__TERMUX_BASH__|$(sed_escape_replacement "$termux_bash")|g" \
      -e "s|__UI_ROOT__|$(sed_escape_replacement "$UI_ROOT")|g" \
      -e "s|__PORT__|$(sed_escape_replacement "$DEFAULT_PORT")|g" \
      "$tmplaunch" | atomic_write_in_uiroot "$launcher"
  rm -f -- "$tmplaunch" || true
  chmod 750 -- "$launcher" || true
  info "Generated Termux launcher: $launcher"
}

# -------- Helper: cleanup stale global pid --------
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

# -------- Install/update shadow + wrapper (idempotent) --------
install_termux_shadow_wrapper() {
  if [ "${INSTALL_MODE:-0}" -ne 1 ]; then info "INSTALL_MODE != 1; skipping Termux shadow/wrapper installation"; return 0; fi

  local candidates=(
    "${UI_ROOT%/}/../groqbash/groqbash"
    "${UI_ROOT%/}/../../groqbash/groqbash"
    "${PWD%/}/groqbash"
    "${HOME%/}/groqbash/groqbash"
    "/data/data/com.termux/files/home/groqbash/groqbash"
  )
  local groqbash_real=""
  for cand in "${candidates[@]}"; do [ -x "$cand" ] && { groqbash_real="$cand"; break; }; done
  if [ -z "$groqbash_real" ]; then info "No local groqbash binary found among candidates; cannot install Termux shadow/wrapper"; return 0; fi

  local groqbash_shadow="/data/data/com.termux/files/usr/bin/groqbash"
  local tmpdir="$UI_ROOT/tmp"
  mkdir -p -- "$tmpdir" 2>/dev/null || true
  chmod 700 -- "$tmpdir" 2>/dev/null || true

  portable_mktemp "$tmpdir" >/dev/null 2>&1 || err "portable_mktemp unavailable; aborting"
  local lockfile="$tmpdir/bootstrap.lock"
  exec 9>"$lockfile" 2>/dev/null || err "Cannot open lockfile $lockfile"

  # Save existing traps and install local cleanup trap
  _old_trap_return="$(trap -p RETURN 2>/dev/null || true)"
  _old_trap_exit="$(trap -p EXIT 2>/dev/null || true)"
  _old_trap_int="$(trap -p INT 2>/dev/null || true)"
  _old_trap_term="$(trap -p TERM 2>/dev/null || true)"

  _release_lock_and_restore() {
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
    # restore previous traps if any
    if [ -n "${_old_trap_return:-}" ]; then eval "$_old_trap_return" 2>/dev/null || true; fi
    if [ -n "${_old_trap_exit:-}" ]; then eval "$_old_trap_exit" 2>/dev/null || true; fi
    if [ -n "${_old_trap_int:-}" ]; then eval "$_old_trap_int" 2>/dev/null || true; fi
    if [ -n "${_old_trap_term:-}" ]; then eval "$_old_trap_term" 2>/dev/null || true; fi
    unset _old_trap_return _old_trap_exit _old_trap_int _old_trap_term
  }

  trap '_release_lock_and_restore' RETURN EXIT INT TERM

  if ! flock -x -w 5 9; then
    _release_lock_and_restore
    err "Could not acquire lock"
  fi

  local tmp_shadow
  tmp_shadow="$(portable_mktemp "$tmpdir")" || tmp_shadow=""
  [ -n "$tmp_shadow" ] || { _release_lock_and_restore; err "Failed to create tmp shadow"; }

  if ! cp -f -- "$groqbash_real" "$tmp_shadow"; then
    rm -f -- "$tmp_shadow" 2>/dev/null || true
    _release_lock_and_restore
    err "Failed to copy groqbash_real to tmp shadow"
  fi

  local termux_bash
  termux_bash="$(find_termux_bash || true)"
  if [ -n "$termux_bash" ] && [ -x "$termux_bash" ]; then
    if head -n1 "$tmp_shadow" 2>/dev/null | grep -qE '^#!'; then
      sed -i '1s|^#!.*|#!'"$termux_bash"'|' "$tmp_shadow" 2>/dev/null || true
    fi
  fi

  if ! mv -f -- "$tmp_shadow" "$groqbash_shadow"; then
    rm -f -- "$tmp_shadow" 2>/dev/null || true
    _release_lock_and_restore
    err "Failed to move tmp shadow into place"
  fi
  chmod 750 -- "$groqbash_shadow" 2>/dev/null || true
  info "Installed Termux shadow: $groqbash_shadow"

  local BIN_DIR="$UI_ROOT/bin"
  mkdir -p -- "$BIN_DIR" 2>/dev/null || true
  chmod 700 -- "$BIN_DIR" 2>/dev/null || true
  local wrapper="$BIN_DIR/groqbash-wrapper"
  local tmp_wrapper
  tmp_wrapper="$(portable_mktemp "$tmpdir")" || tmp_wrapper=""
  [ -n "$tmp_wrapper" ] || { _release_lock_and_restore; err "Failed to create tmp wrapper"; }

  # Write robust, autosufficient wrapper template (fixed GROQBASH_ROOT derivation)
  cat >"$tmp_wrapper" <<'EOF'
#!__TERMUX_BASH__
set -euo pipefail
umask 077

# Resolve wrapper path robustly: prefer BASH_SOURCE, resolve symlink if possible
_wrpsrc="${BASH_SOURCE[0]:-$0}"
if command -v readlink >/dev/null 2>&1; then
  _wrpsrc="$(readlink -f -- "$_wrpsrc" 2>/dev/null || printf '%s' "$_wrpsrc")"
fi
_wrppath="$(cd "$(dirname -- "$_wrpsrc")" 2>/dev/null && pwd -P || true)"

# Derive UI_ROOT from wrapper location if not provided
if [ -z "${UI_ROOT:-}" ]; then
  if [ -n "$_wrppath" ]; then
    UI_ROOT="$(cd "$_wrppath/.." 2>/dev/null && pwd -P || true)"
  fi
fi
: "${UI_ROOT:=__UI_ROOT__}"

# GROQBASH_ROOT fallback: robust derivation from wrapper location (reach repo root)
# Start from bin -> ui -> extras -> groqbash.d -> groqbash (repo root)
if [ -z "${GROQBASH_ROOT:-}" ]; then
  if [ -n "$_wrppath" ]; then
    GROQBASH_ROOT="$(cd "$_wrppath/../../../.." 2>/dev/null && pwd -P || true)"
  fi
fi

# If derivation landed on groqbash.d, move up one level to repo root
if [ -n "${GROQBASH_ROOT:-}" ]; then
  case "${GROQBASH_ROOT##*/}" in
    groqbash.d)
      GROQBASH_ROOT="$(cd "$GROQBASH_ROOT/.." 2>/dev/null && pwd -P || true)"
      ;;
  esac
fi

: "${GROQBASH_ROOT:=__GROQBASH_ROOT__}"

# GROQBASH_DIR and extras/providers
: "${GROQBASH_DIR:=${GROQBASH_ROOT%/}/groqbash.d}"
: "${GROQBASH_EXTRAS_DIR:=${GROQBASH_DIR%/}/extras}"
: "${PROVIDERS_DIR:=${GROQBASH_EXTRAS_DIR%/}/providers}"

# BIN_DIR fallback and ensure existence
: "${BIN_DIR:=__BIN_DIR__}"
if [ -z "${BIN_DIR:-}" ]; then BIN_DIR="${UI_ROOT%/}/bin"; fi
mkdir -p -- "${UI_ROOT%/}/bin" 2>/dev/null || true
[ -d "$BIN_DIR" ] || mkdir -p -- "$BIN_DIR" 2>/dev/null || true

export UI_ROOT GROQBASH_ROOT GROQBASH_DIR GROQBASH_EXTRAS_DIR PROVIDERS_DIR BIN_DIR

# Build PATH deterministically: UI_ROOT/bin then BIN_DIR then existing PATH, avoid duplicates
_newpath="${UI_ROOT%/}/bin"
case ":$PATH:" in *":${_newpath}:"*) :;; *) _newpath="${_newpath}:$PATH";; esac
if [ -n "$BIN_DIR" ] && [ "$BIN_DIR" != "${UI_ROOT%/}/bin" ]; then
  case ":$_newpath:" in *":${BIN_DIR}:"*) :;; *) _newpath="${BIN_DIR}:$_newpath";; esac
fi

# Ensure minimal system bins are always present (handles env -i / minimal CGI env)
case ":$_newpath:" in *":/data/data/com.termux/files/usr/bin:"*) :;; *) _newpath="${_newpath}:/data/data/com.termux/files/usr/bin";; esac
case ":$_newpath:" in *":/bin:"*) :;; *) _newpath="${_newpath}:/bin";; esac

# Trim possible leading/trailing colons
_newpath="${_newpath#:}"
_newpath="${_newpath%:}"

export PATH="$_newpath"

# Export additional runtime dirs used by core
: "${GROQBASH_TMPDIR:="${GROQBASH_DIR%/}/tmp"}"
: "${GROQBASH_HISTORY_DIR:="${GROQBASH_DIR%/}/history"}"
: "${GROQBASH_CONFIG_DIR:="${GROQBASH_DIR%/}/config"}"
: "${GROQBASH_MODELS_DIR:="${GROQBASH_DIR%/}/models"}"
export GROQBASH_TMPDIR GROQBASH_HISTORY_DIR GROQBASH_CONFIG_DIR GROQBASH_MODELS_DIR

# Diagnostics only when enabled
if [ "${GROQBASH_DEBUG:-0}" = "1" ]; then
  printf '%s\n' "INFO: UI_ROOT=$UI_ROOT" >&2
  printf '%s\n' "INFO: GROQBASH_ROOT=$GROQBASH_ROOT" >&2
  printf '%s\n' "INFO: GROQBASH_DIR=$GROQBASH_DIR" >&2
  printf '%s\n' "INFO: PROVIDERS_DIR=$PROVIDERS_DIR" >&2
  printf '%s\n' "INFO: PATH=$PATH" >&2
fi

# Validate critical paths early
if [ -n "${GROQBASH_DIR:-}" ] && [ ! -d "${GROQBASH_DIR}" ]; then
  printf '%s\n' "ERROR: GROQBASH_DIR does not exist: $GROQBASH_DIR" >&2
  exit 1
fi

if [ -n "${PROVIDERS_DIR:-}" ] && [ ! -d "${PROVIDERS_DIR}" ]; then
  [ "${GROQBASH_DEBUG:-0}" = "1" ] && printf '%s\n' "DEBUG: PROVIDERS_DIR not found: $PROVIDERS_DIR" >&2
fi

GROQBASH_SHADOW="__GROQBASH_SHADOW__"
TERMUX_BASH="__TERMUX_BASH__"

if [ -z "$TERMUX_BASH" ] || [ ! -x "$TERMUX_BASH" ]; then
  TERMUX_BASH="/bin/bash"
fi

if [ ! -x "$GROQBASH_SHADOW" ]; then
  printf '%s\n' "ERROR: groqbash shadow not executable or missing: $GROQBASH_SHADOW" >&2
  exit 1
fi

exec "$TERMUX_BASH" "$GROQBASH_SHADOW" "$@"
EOF

  sed -e "s|__TERMUX_BASH__|$(sed_escape_replacement "$termux_bash")|g" \
      -e "s|__GROQBASH_SHADOW__|$(sed_escape_replacement "$groqbash_shadow")|g" \
      -e "s|__GROQBASH_ROOT__|$(sed_escape_replacement "${GROQBASH_ROOT:-}")|g" \
      -e "s|__GROQBASH_DIR__|$(sed_escape_replacement "${GROQBASH_DIR:-}")|g" \
      -e "s|__GROQBASH_EXTRAS_DIR__|$(sed_escape_replacement "${GROQBASH_EXTRAS_DIR:-}")|g" \
      -e "s|__PROVIDERS_DIR__|$(sed_escape_replacement "${PROVIDERS_DIR:-}")|g" \
      -e "s|__BIN_DIR__|$(sed_escape_replacement "${BIN_DIR:-}")|g" \
      -e "s|__UI_ROOT__|$(sed_escape_replacement "${UI_ROOT:-}")|g" \
      "$tmp_wrapper" > "${tmp_wrapper}.out" && mv -f -- "${tmp_wrapper}.out" "$tmp_wrapper"

  sed -i -e 's/\r$//' "$tmp_wrapper" 2>/dev/null || true

  if [ -f "$wrapper" ]; then
    if ! cmp -s "$tmp_wrapper" "$wrapper"; then
      mv -f -- "$tmp_wrapper" "$wrapper" || { rm -f -- "$tmp_wrapper" 2>/dev/null || true; _release_lock_and_restore; err "Failed to move new wrapper into place"; }
    else
      rm -f -- "$tmp_wrapper" 2>/dev/null || true
    fi
  else
    mv -f -- "$tmp_wrapper" "$wrapper" || { rm -f -- "$tmp_wrapper" 2>/dev/null || true; _release_lock_and_restore; err "Failed to move wrapper into place"; }
  fi
  chmod 750 -- "$wrapper" 2>/dev/null || true
  info "Installed Termux wrapper: $wrapper"

  local cfg_dir="$UI_ROOT/config"
  mkdir -p -- "$cfg_dir" 2>/dev/null || true
  chmod 700 -- "$cfg_dir" 2>/dev/null || true
  local tmp_path
  tmp_path="$(portable_mktemp "$cfg_dir")" || tmp_path="${cfg_dir}/groqbash-path.tmp"
  if printf '%s\n' "$wrapper" >"$tmp_path"; then
    local line_count
    line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
    if [ "$line_count" -eq 1 ]; then
      mv -f -- "$tmp_path" "${cfg_dir%/}/groqbash-path"
      chmod 600 -- "${cfg_dir%/}/groqbash-path" 2>/dev/null || true
      info "Persisted groqbash-path -> ${cfg_dir%/}/groqbash-path -> $wrapper"
    else
      rm -f -- "$tmp_path" 2>/dev/null || true
      info "Refusing to persist groqbash-path: temp file contains ${line_count} non-empty lines"
    fi
  else
    rm -f -- "$tmp_path" 2>/dev/null || true
    info "Failed to write temporary groqbash-path; skipping persist"
  fi

  # release lock and restore traps
  _release_lock_and_restore

  return 0
}

# -------- Main --------
main() {
  check_deps
  canonicalize_ui_root
  
  # Ensure UI_ROOT is writable (portable_mktemp will fail otherwise)
  if [ ! -w "$UI_ROOT" ]; then
    err "UI_ROOT not writable: $UI_ROOT"
  fi

  BOOTSTRAP="$UI_ROOT/gui-bootstrap.sh"
  if [[ -f "$BOOTSTRAP" ]]; then
    # Temporarily disable nounset to avoid unbound-variable failures while sourcing bootstrap/env
    set +u
    if ! . "$BOOTSTRAP"; then
      info "Warning: failed to source bootstrap at $BOOTSTRAP"
    fi
    set -u
  else
    info "Warning: bootstrap not found at $BOOTSTRAP; continuing"
  fi

  # Fail-fast: ensure portable_mktemp is defined by the sourced bootstrap/env
  if ! declare -f portable_mktemp >/dev/null 2>&1; then
    err "portable_mktemp not defined after sourcing bootstrap; aborting adapt. Check gui-env.sh sourcing and TMP_DIR"
  fi

  # Ensure TMP_DIR exists, is confined under UI_ROOT and writable
  : "${TMP_DIR:=${UI_ROOT%/}/tmp}"
  # Create and secure TMP_DIR
  mkdir -p -- "$TMP_DIR" 2>/dev/null || err "Cannot create TMP_DIR: $TMP_DIR"
  chmod 700 -- "$TMP_DIR" 2>/dev/null || true
  # Verify writability
  if [ ! -w "$TMP_DIR" ]; then
    err "TMP_DIR not writable: $TMP_DIR"
  fi

  enforce_ui_root_only_writes

  if [ -n "${UI_ROOT:-}" ]; then
    if repo_root="$(cd "$UI_ROOT/../../.." 2>/dev/null && pwd -P)"; then
      export GROQBASH_ROOT="$repo_root"
      export GROQBASH_DIR="${GROQBASH_DIR:-$GROQBASH_ROOT/groqbash.d}"
      export GROQBASH_EXTRAS_DIR="${GROQBASH_EXTRAS_DIR:-$GROQBASH_DIR/extras}"
      export PROVIDERS_DIR="${PROVIDERS_DIR:-$GROQBASH_EXTRAS_DIR/providers}"
      export BIN_DIR="${BIN_DIR:-$UI_ROOT/bin}"
      export GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-$GROQBASH_DIR/tmp}"
      export GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}"
      export GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}"
      export GROQBASH_MODELS_DIR="${GROQBASH_MODELS_DIR:-$GROQBASH_DIR/models}"
      info "Exported GROQBASH_ROOT=$GROQBASH_ROOT"
    else
      info "Warning: could not derive GROQBASH_ROOT from UI_ROOT; skipping export"
    fi
  fi

  cleanup_tmp() {
    if [ -d "$UI_ROOT" ]; then find "$UI_ROOT" -maxdepth 3 -type f -name '.tmp.*' -exec rm -f -- {} + 2>/dev/null || true; fi
  }
  trap 'cleanup_tmp' EXIT INT TERM

  mkdir -p -- "$UI_ROOT/tmp" "$UI_ROOT/logs" "$UI_ROOT/www" "$UI_ROOT/cgi-bin" "$UI_ROOT/.status" "$UI_ROOT/var/run/apache2"
  chmod 700 -- "$UI_ROOT/tmp" "$UI_ROOT/logs" "$UI_ROOT/www" "$UI_ROOT/cgi-bin" "$UI_ROOT/.status" "$UI_ROOT/var/run/apache2" || true

  TARGET_FILES=()
  for rel in "${TARGET_FILES_REL[@]}"; do TARGET_FILES+=("$UI_ROOT/$rel"); done
  CGI_DIR="$UI_ROOT/$CGI_DIR_REL"

  env_type="$(detect_env)"
  info "Detected environment: $env_type"

  case "$env_type" in
    termux)
      bash_path="$(find_termux_bash || true)"
      if [ -z "$bash_path" ]; then err "No valid bash found on Termux"; fi
      info "Using bash: $bash_path"

      files_to_process=()
      for f in "${TARGET_FILES[@]}"; do files_to_process+=("$f"); done
      if [ -d "$CGI_DIR" ]; then
        while IFS= read -r -d '' shf; do files_to_process+=("$shf"); done < <(find "$CGI_DIR" -maxdepth 1 -type f -name '*.sh' -print0)
      fi

      declare -A seen=()
      for f in "${files_to_process[@]}"; do
        [ -z "$f" ] && continue
        if [ ! -e "$f" ]; then info "Target not present, skipping: $f"; continue; fi
        if ! path_within_ui_root "$f"; then info "Skipping file outside UI_ROOT: $f"; continue; fi
        if [ "${seen[$f]+_}" ]; then continue; fi
        seen["$f"]=1
        process_target "$f" "$bash_path"
      done

      if type ensure_sh_executables >/dev/null 2>&1; then ensure_sh_executables "$UI_ROOT" || info "Warning: ensure_sh_executables failed"; else info "Warning: ensure_sh_executables not available"; fi

      generate_termux_apache_config
      generate_termux_launcher
      install_termux_shadow_wrapper
      ;;
    linux|macos|wsl|cygwin|unknown)
      info "No adaptation required for environment: $env_type"
      local sysbash
      sysbash="$(command -v bash || true)"
      if [ -n "$sysbash" ]; then
        declare -A seen2=()
        for f in "${TARGET_FILES[@]}"; do
          [ -z "$f" ] && continue
          if [ ! -e "$f" ]; then info "Target not present, skipping: $f"; continue; fi
          if ! path_within_ui_root "$f"; then info "Skipping file outside UI_ROOT: $f"; continue; fi
          if [ "${seen2[$f]+_}" ]; then continue; fi
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
  info "To test the Apache config manually: httpd -t -f $UI_ROOT/apache-termux-gui-${DEFAULT_PORT}.conf"
}

main "$@"
