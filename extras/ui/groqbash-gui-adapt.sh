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
UI_ROOT="${HOME:-$PWD}/groqbash/groqbash.d/extras/ui"
TARGET_FILES=(
  "$UI_ROOT/gui-server.sh"
  "$UI_ROOT/gui-bootstrap.sh"
)
CGI_DIR="$UI_ROOT/cgi-bin"

TS() { date +%s; }

# -------- Logging & exit helpers --------
log() { printf '%s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf 'INFO: %s\n' "$*" >&2; }

# -------- Dependency check (no fallback; fail with clear message) --------
check_deps() {
  local deps=(bash sed awk grep uname mktemp mv cp chmod date printf test head tail find)
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

backup_file() {
  local f="$1" ts b
  ts="$(TS)"
  b="${f}.bak.${ts}"
  cp -- "$f" "$b"
  printf '%s' "$b"
}

atomic_replace_first_line() {
  local file="$1" new_shebang="$2"
  local tmp
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  {
    printf '%s\n' "$new_shebang"
    tail -n +2 -- "$file" | sed -e 's/\r$//'
  } >"$tmp"
  mv -f -- "$tmp" "$file"
}

# -------- Process a single file (idempotent) --------
process_target() {
  local file="$1" bash_path="$2"
  if [ ! -e "$file" ]; then
    info "Skipping missing file: $file"
    return 0
  fi
  if ! is_regular_file "$file"; then
    info "Skipping non-regular file (symlink/device): $file"
    return 0
  fi

  local tmpnorm
  tmpnorm="$(mktemp "${file}.norm.XXXXXX")"
  sed -e 's/\r$//' "$file" >"$tmpnorm"
  mv -f -- "$tmpnorm" "$file"

  local current_first
  current_first="$(head -n1 -- "$file" || true)"
  local target_shebang="#!${bash_path}"

  if [ "$current_first" = "$target_shebang" ]; then
    info "Shebang already correct: $file"
    chmod 755 -- "$file" || true
    return 0
  fi

  local backup
  backup="$(backup_file "$file")" || err "Failed to backup $file"
  info "Backup created: $backup"

  atomic_replace_first_line "$file" "$target_shebang" || {
    err "Failed to write new shebang to $file; attempting rollback"
    mv -f -- "$backup" "$file" || err "Rollback failed for $file"
    err "Rolled back $file to backup"
  }

  chmod 755 -- "$file" || err "Failed to chmod $file"

  info "Patched shebang: $file -> $target_shebang"
}

# -------- Main --------
main() {
  check_deps

  if [ ! -d "$UI_ROOT" ]; then
    err "UI directory not found: $UI_ROOT"
  fi

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
        f_abs="$f"
        if [ ! -e "$f_abs" ]; then
          info "Target not present, skipping: $f_abs"
          continue
        fi
        if [ "${seen[$f_abs]+_}" ]; then
          continue
        fi
        seen["$f_abs"]=1
        process_target "$f_abs" "$bash_path"
      done
      ;;
    linux|macos|wsl|cygwin|unknown)
      info "No adaptation required for environment: $env_type"
      ;;
    *)
      err "Unhandled environment: $env_type"
      ;;
  esac

  info "groqbash-gui-adapt.sh completed"
}

main "$@"
