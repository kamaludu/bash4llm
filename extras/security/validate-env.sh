#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/security/validate-env.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
set -euo pipefail

_ok()   { printf 'OK: %s\n' "$*"; }
_warn() { printf 'WARN: %s\n' "$*"; }
_err()  { printf 'ERROR: %s\n' "$*"; }

# Portable stat uid getter (GNU stat -c %u or BSD stat -f %u)
_stat_uid() {
  local f="$1"
  if stat -c '%u' "$f" >/dev/null 2>&1; then
    stat -c '%u' "$f" 2>/dev/null || true
  elif stat -f '%u' "$f" >/dev/null 2>&1; then
    stat -f '%u' "$f" 2>/dev/null || true
  else
    printf '' 
  fi
}

_is_world_writable() {
  local d="$1" perms others_write
  [ -d "$d" ] || return 1
  # use ls fallback for portability
  perms="$(ls -ld -- "$d" 2>/dev/null | awk '{print $1}' 2>/dev/null || true)"
  [ -z "$perms" ] && return 1
  others_write="$(printf '%s' "$perms" | awk '{print substr($0,9,1)}')"
  [ "$others_write" = "w" ]
}

# Accept some legacy env var names but prefer canonical ones
GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-${GROQBASHTMPDIR:-}}"
GROQBASH_EXTRAS_DIR="${GROQBASH_EXTRAS_DIR:-${GROQBASHEXTRASDIR:-}}"
GROQBASH_DIR="${GROQBASH_DIR:-${GROQBASH_HOME:-}}"

critical_fail=0

printf 'Checking required tools...\n'
required_tools="bash curl jq gawk find stat mktemp awk sed grep flock"
for t in $required_tools; do
  if command -v "$t" >/dev/null 2>&1; then
    _ok "Found required tool: $t"
  else
    _err "Missing required tool: $t"
    critical_fail=1
  fi
done

printf '\nChecking recommended environment hints...\n'
# no checks for package names; only report presence of useful commands
if command -v flock >/dev/null 2>&1; then
  _ok "flock available for atomic locks"
else
  _warn "flock not found: atomic directory locks may be unavailable"
fi

if command -v gawk >/dev/null 2>&1; then
  _ok "gawk available"
else
  _warn "gawk not found; awk may be present but gawk is recommended"
fi

if command -v jq >/dev/null 2>&1; then
  jq_ver="$(jq --version 2>/dev/null | sed 's/jq-//')"
  _ok "jq version $jq_ver"
fi

# Derive GROQBASH_DIR only if not set
if [ -z "${GROQBASH_DIR:-}" ]; then
  _script_path="${BASH_SOURCE[0]:-$0}"
  if [ -n "$_script_path" ]; then
    _script_dir="$(cd "$(dirname "$_script_path")" >/dev/null 2>&1 && pwd -P || true)"
    # assume repo root is two levels up from extras/security by default
    GROQBASH_DIR_CANDIDATE="$(cd "$_script_dir/../.." >/dev/null 2>&1 && pwd -P || true || echo "$_script_dir")"
    GROQBASH_DIR="$GROQBASH_DIR_CANDIDATE"
    _warn "GROQBASH_DIR not set; derived candidate: $GROQBASH_DIR"
  fi
else
  _ok "GROQBASH_DIR set: $GROQBASH_DIR"
fi

# If PROVIDERS_DIR not set and GROQBASH_DIR known, set sensible default
if [ -z "${PROVIDERS_DIR:-}" ] && [ -n "${GROQBASH_DIR:-}" ]; then
  PROVIDERS_DIR="${GROQBASH_DIR%/}/groqbash.d/extras/providers"
fi

printf '\nValidating GROQBASH_TMPDIR...\n'
if [ -z "${GROQBASH_TMPDIR:-}" ]; then
  _warn "GROQBASH_TMPDIR is not set. GroqBash will use its default internal tmpdir."
else
  case "$GROQBASH_TMPDIR" in
    /*) : ;;
    *)
      _err "GROQBASH_TMPDIR must be an absolute path: $GROQBASH_TMPDIR"
      critical_fail=1
      ;;
  esac

  if [ -n "${GROQBASH_DIR:-}" ] && [ -n "${GROQBASH_TMPDIR:-}" ]; then
    case "$GROQBASH_TMPDIR" in
      "$GROQBASH_DIR"/*) : ;;
      *)
        _err "GROQBASH_TMPDIR must be inside GROQBASH_DIR ($GROQBASH_DIR): $GROQBASH_TMPDIR"
        critical_fail=1
        ;;
    esac
  fi

  if [ -n "$GROQBASH_TMPDIR" ]; then
    if [ -d "$GROQBASH_TMPDIR" ]; then
      if _is_world_writable "$GROQBASH_TMPDIR"; then
        _err "GROQBASH_TMPDIR is world-writable: $GROQBASH_TMPDIR"
        critical_fail=1
      else
        _ok "GROQBASH_TMPDIR exists and is not world-writable: $GROQBASH_TMPDIR"
      fi
    else
      old_umask="$(umask)"
      umask 077
      if mkdir -p -- "$GROQBASH_TMPDIR" 2>/dev/null; then
        umask "$old_umask"
        _ok "GROQBASH_TMPDIR created with restrictive permissions: $GROQBASH_TMPDIR"
        owner_uid="$(_stat_uid "$GROQBASH_TMPDIR" || true)"
        if [ -n "$owner_uid" ] && [ "$owner_uid" != "$(id -u)" ]; then
          _warn "GROQBASH_TMPDIR owner differs from current user (uid $owner_uid)"
        fi
      else
        umask "$old_umask"
        _err "GROQBASH_TMPDIR does not exist and cannot be created: $GROQBASH_TMPDIR"
        critical_fail=1
      fi
    fi
  fi
fi

printf '\nValidating GROQBASH_EXTRAS_DIR...\n'
if [ -z "${GROQBASH_EXTRAS_DIR:-}" ]; then
  _err "GROQBASH_EXTRAS_DIR is not set. Set it to your groqbash extras directory."
  critical_fail=1
else
  case "$GROQBASH_EXTRAS_DIR" in
    /*) : ;;
    *)
      _err "GROQBASH_EXTRAS_DIR must be an absolute path: $GROQBASH_EXTRAS_DIR"
      critical_fail=1
      ;;
  esac
  if [ -d "$GROQBASH_EXTRAS_DIR" ]; then
    if _is_world_writable "$GROQBASH_EXTRAS_DIR"; then
      _err "GROQBASH_EXTRAS_DIR is world-writable: $GROQBASH_EXTRAS_DIR"
      critical_fail=1
    else
      _ok "GROQBASH_EXTRAS_DIR exists and is not world-writable: $GROQBASH_EXTRAS_DIR"
    fi
  else
    old_umask="$(umask)"
    umask 077
    if mkdir -p -- "$GROQBASH_EXTRAS_DIR" 2>/dev/null; then
      umask "$old_umask"
      _ok "GROQBASH_EXTRAS_DIR created with restrictive permissions: $GROQBASH_EXTRAS_DIR"
    else
      umask "$old_umask"
      _err "GROQBASH_EXTRAS_DIR does not exist and cannot be created: $GROQBASH_EXTRAS_DIR"
      critical_fail=1
    fi
  fi
fi

printf '\nValidating PROVIDERS_DIR and provider modules...\n'
if [ -n "${PROVIDERS_DIR:-}" ] && [ -d "${PROVIDERS_DIR}" ]; then
  _ok "PROVIDERS_DIR exists: $PROVIDERS_DIR"
  sh_count=0
  if command -v find >/dev/null 2>&1; then
    while IFS= read -r -d '' f; do
      sh_count=$((sh_count+1))
    done < <(find "$PROVIDERS_DIR" -maxdepth 1 -type f -name '*.sh' -print0 2>/dev/null || true)
  fi
  _ok "Provider modules found: $sh_count"
else
  _warn "PROVIDERS_DIR missing or not a directory: ${PROVIDERS_DIR:-<unset>}"
fi

printf '\nSummary:\n'
if [ "$critical_fail" -ne 0 ]; then
  _err "One or more critical checks failed. Fix the issues above before running groqbash in untrusted environments."
  exit 2
else
  _ok "All critical environment checks passed (subject to warnings above)."
  exit 0
fi
