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
    printf '%s' "$tmp"
    return 0
  fi
  tmp="${dir}/.tmp.$$.$RANDOM.$(date +%s)"
  mkdir -p -- "$dir"
  ( set -C; : >"$tmp" ) 2>/dev/null || return 1
  printf '%s' "$tmp"
  return 0
}

# -------- Escape replacement for sed (escape & and backslashes) --------
sed_escape_replacement() {
  # $1: string to escape
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

# -------- Atomic write inside UI_ROOT --------
atomic_write_in_uiroot() {
  # $1: dest path (absolute)
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

  local tmpnorm
  tmpnorm="$(portable_mktemp "$(dirname -- "$file")")" || err "mktemp failed for $(dirname -- "$file")"
  sed -e 's/\r$//' "$file" >"$tmpnorm"
  mv -f -- "$tmpnorm" "$file"
  if ! path_within_ui_root "$file"; then
    err "Post-normalize check failed: $file is outside UI_ROOT"
  fi

  local current_first
  current_first="$(head -n1 -- "$file" || true)"
  local target_shebang="#!${bash_path}"

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

# -------- Generate Termux Apache config (only writes under UI_ROOT) --------
generate_termux_apache_config() {
  local conf="$UI_ROOT/apache-termux-gui-19970.conf"
  local logs_dir="$UI_ROOT/logs"
  local www_dir="$UI_ROOT/www"
  local cgi_dir="$UI_ROOT/cgi-bin"
  mkdir -p -- "$logs_dir" "$www_dir" "$cgi_dir"
  chmod 700 -- "$logs_dir" "$www_dir" "$cgi_dir" || true

  local tmpconf
  tmpconf="$(portable_mktemp "$UI_ROOT")" || err "Failed to create temp for apache conf"
  cat >"$tmpconf" <<'EOF'
# GroqBash GUI Termux Apache config (standalone, confined to UI_ROOT)
# Generated by groqbash-gui-adapt.sh
Listen 127.0.0.1:19970
ServerName localhost

DocumentRoot "__WWW_DIR__"
<Directory "__WWW_DIR__">
    Options -Indexes +FollowSymLinks
    Require local
</Directory>

ScriptAlias /cgi-bin/ "__CGI_DIR__"
<Directory "__CGI_DIR__">
    Options +ExecCGI -Indexes
    Require local
</Directory>

ErrorLog "__LOG_DIR__/error.log"
CustomLog "__LOG_DIR__/access.log" common

<RequireAny>
    Require ip 127.0.0.1
    Require host localhost
</RequireAny>
EOF

  # Escape replacements to avoid sed issues with special chars
  local esc_www esc_cgi esc_log
  esc_www="$(sed_escape_replacement "$www_dir")"
  esc_cgi="$(sed_escape_replacement "$cgi_dir")"
  esc_log="$(sed_escape_replacement "$logs_dir")"

  sed -e "s|__WWW_DIR__|${esc_www}|g" \
      -e "s|__CGI_DIR__|${esc_cgi}|g" \
      -e "s|__LOG_DIR__|${esc_log}|g" \
      "$tmpconf" | atomic_write_in_uiroot "$conf"
  rm -f -- "$tmpconf" || true
  chmod 600 -- "$conf" || true
  info "Generated Apache config: $conf"
}

# -------- Generate Termux launcher script (only writes under UI_ROOT) --------
generate_termux_launcher() {
  local launcher="$UI_ROOT/groqbash-gui-termux.sh"
  local conf="$UI_ROOT/apache-termux-gui-19970.conf"
  local logs_dir="$UI_ROOT/logs"
  local status_dir="$UI_ROOT/.status"
  mkdir -p -- "$status_dir"
  chmod 700 -- "$status_dir" || true

  local termux_bash
  termux_bash="$(find_termux_bash || true)"
  if [ -z "$termux_bash" ]; then
    err "No Termux bash found; cannot generate launcher"
  fi

  local tmplaunch
  tmplaunch="$(portable_mktemp "$UI_ROOT")" || err "Failed to create temp for launcher"

  cat >"$tmplaunch" <<'EOF'
#!__TERMUX_BASH__
set -euo pipefail
umask 077

UI_ROOT="__UI_ROOT__"
CONF="$UI_ROOT/apache-termux-gui-19970.conf"
LOGS="$UI_ROOT/logs"
STATUS_DIR="$UI_ROOT/.status"
URL="http://127.0.0.1:19970/"

TS() { date +%s; }

log() { printf '%s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if [ ! -d "$UI_ROOT" ]; then
  err "UI_ROOT missing: $UI_ROOT"
fi
if [ ! -f "$CONF" ]; then
  err "Apache config not found: $CONF"
fi

is_listening() {
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | awk '{print $4}' | grep -q '127.0.0.1:19970' && return 0 || return 1
  elif command -v netstat >/dev/null 2>&1; then
    netstat -ltn 2>/dev/null | awk '{print $4}' | grep -q '127.0.0.1:19970' && return 0 || return 1
  else
    return 1
  fi
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

wait_for_listen() {
  local i max=8
  for i in $(seq 1 $max); do
    if is_listening; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if is_listening; then
  log "127.0.0.1:19970 already listening; opening browser"
else
  httpd_bin="$(find_httpd || true)"
  if [ -z "$httpd_bin" ]; then
    err "No httpd/apachectl binary found in PATH; cannot start server"
  fi

  if [ "$httpd_bin" = "httpd" ]; then
    # Start httpd as the invoking Termux user (no root). This assumes httpd binary runs in userland.
    "$httpd_bin" -f "$CONF" >/dev/null 2>>"$LOGS/error.log" &
  else
    if "$httpd_bin" -h 2>&1 | grep -q -- '-f'; then
      "$httpd_bin" -f "$CONF" >/dev/null 2>>"$LOGS/error.log" &
    else
      err "apachectl does not support -f on this system; to avoid modifying global config, please start httpd manually with the config in $CONF"
    fi
  fi

  if ! wait_for_listen; then
    err "Server did not start or is not listening on 127.0.0.1:19970"
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
      "$tmplaunch" | atomic_write_in_uiroot "$launcher"
  rm -f -- "$tmplaunch" || true
  chmod 755 -- "$launcher" || true
  info "Generated Termux launcher: $launcher"
}

# -------- Main --------
main() {
  check_deps

  canonicalize_ui_root

  # create essential runtime dirs under UI_ROOT
  mkdir -p -- "$UI_ROOT/.tmp" "$UI_ROOT/logs" "$UI_ROOT/www" "$UI_ROOT/cgi-bin" "$UI_ROOT/.status"
  chmod 700 -- "$UI_ROOT/.tmp" "$UI_ROOT/logs" "$UI_ROOT/www" "$UI_ROOT/cgi-bin" "$UI_ROOT/.status" || true

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
  info "To test the Apache config manually (if httpd supports it): httpd -t -f $UI_ROOT/apache-termux-gui-19970.conf"
}

main "$@"
