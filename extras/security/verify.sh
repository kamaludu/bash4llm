#!/usr/bin/env bash
# =============================================================================
# Bash4LLM — Bash-first wrapper for the Groq API
# File: extras/security/verify.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/bash4llm
# =============================================================================
# Purpose:
#   Performs read‑only security checks on bash4llm provider modules and the
#   extras directory. Validates file integrity, absence of symlinks, safe
#   permissions (no group/other write), ownership, and prints checksums when
#   available.
#
# Usage:
#   Export the required environment variables before running:
#     export BASH4LLM_EXTRAS_DIR="/absolute/path/to/bash4llm.d/extras"
#     export BASH4LLM_DIR="/absolute/path/to/bash4llm"
#     export BASH4LLM_TMPDIR="... (optional)"
#     export PROVIDERS_DIR="$BASH4LLM_EXTRAS_DIR/providers"
#   Then run:
#     ./verify.sh
#
# Behavior:
#   - Exit 0: all critical checks passed (WARN messages may appear).
#   - Exit 2: one or more critical checks failed (ERROR).
#   - Set STRICT_VERIFY=1 to treat owner mismatches as fatal errors.
# ---------------------------------------------------------------------------

set -euo pipefail

_ok()   { printf 'OK: %s\n' "$*"; }
_warn() { printf 'WARN: %s\n' "$*"; }
_err()  { printf 'ERROR: %s\n' "$*"; }

# Accept canonical and legacy env names
BASH4LLM_EXTRAS_DIR="${BASH4LLM_EXTRAS_DIR:-${BASH4LLMEXTRASDIR:-}}"
BASH4LLM_DIR="${BASH4LLM_DIR:-${BASH4LLM_HOME:-}}"
BASH4LLM_TMPDIR="${BASH4LLM_TMPDIR:-${BASH4LLMTMPDIR:-}}"

# Portable owner getter: returns username or empty string
_get_owner() {
  local f="$1"
  if command -v stat >/dev/null 2>&1; then
    if stat -c '%U' "$f" >/dev/null 2>&1; then
      stat -c '%U' "$f" 2>/dev/null || printf ''
    elif stat -f '%Su' "$f" >/dev/null 2>&1; then
      stat -f '%Su' "$f" 2>/dev/null || printf ''
    else
      printf ''
    fi
  else
    # fallback to ls parsing (less reliable)
    ls -ld -- "$f" 2>/dev/null | awk '{print $3}' 2>/dev/null || printf ''
  fi
}

# Portable permission string getter (ls fallback)
_get_perms() {
  local f="$1"
  ls -ld -- "$f" 2>/dev/null | awk '{print $1}' 2>/dev/null || printf ''
}

# World-writable check (directory)
_is_world_writable() {
  local d="$1" perms others_write
  [ -d "$d" ] || return 1
  perms="$(_get_perms "$d")"
  [ -z "$perms" ] && return 1
  others_write="$(printf '%s' "$perms" | awk '{print substr($0,9,1)}')"
  [ "$others_write" = "w" ]
}

# Ensure extras dir provided
if [ -z "${BASH4LLM_EXTRAS_DIR:-}" ]; then
  _err "BASH4LLM_EXTRAS_DIR is not set. Export it to point to your bash4llm extras directory."
  exit 2
fi

# Ensure absolute path
case "$BASH4LLM_EXTRAS_DIR" in
  /*) : ;;
  *)
    _err "BASH4LLM_EXTRAS_DIR must be an absolute path: $BASH4LLM_EXTRAS_DIR"
    exit 2
    ;;
esac

# Ensure exists (do not create)
if [ ! -d "$BASH4LLM_EXTRAS_DIR" ]; then
  _err "Extras directory does not exist: $BASH4LLM_EXTRAS_DIR"
  exit 2
fi

# Check extras dir perms
if _is_world_writable "$BASH4LLM_EXTRAS_DIR"; then
  _err "Extras directory is world-writable: $BASH4LLM_EXTRAS_DIR"
  exit 2
else
  _ok "Extras directory permissions look sane: $BASH4LLM_EXTRAS_DIR"
fi

# Providers directory (default under extras)
PROV_DIR="${PROVIDERS_DIR:-$BASH4LLM_EXTRAS_DIR/providers}"

if [ ! -d "$PROV_DIR" ]; then
  _warn "Providers directory not found: $PROV_DIR"
  # Not fatal; no providers installed
  exit 0
fi

# Current user (username)
CURRENT_USER="$(id -un 2>/dev/null || printf '')"

# Check for checksum tool
SHA_TOOL=""
if command -v sha256sum >/dev/null 2>&1; then
  SHA_TOOL="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA_TOOL="shasum -a 256"
fi

# Diagnostic: check atomic/lock primitives
if command -v flock >/dev/null 2>&1; then
  _ok "flock available for atomic locks"
else
  _warn "flock not found: atomic directory locks may be unavailable"
fi

# Optional tmp policy check (warn only)
if [ -n "${BASH4LLM_TMPDIR:-}" ] && [ -n "${BASH4LLM_DIR:-}" ]; then
  case "$BASH4LLM_TMPDIR" in
    "$BASH4LLM_DIR"/*) _ok "BASH4LLM_TMPDIR is inside BASH4LLM_DIR";;
    *)
      _warn "BASH4LLM_TMPDIR is not inside BASH4LLM_DIR: $BASH4LLM_TMPDIR"
      ;;
  esac
fi

# Enable nullglob in bash to avoid literal glob when no matches
if [ -n "${BASH_VERSION:-}" ]; then
  # shellcheck disable=SC2034
  shopt -s nullglob 2>/dev/null || true
fi

any_error=0
printf 'Verifying provider files in: %s\n' "$PROV_DIR"

for f in "$PROV_DIR"/*.sh; do
  [ -e "$f" ] || continue
  printf '\nFile: %s\n' "$f"

  # Regular file
  if [ ! -f "$f" ]; then
    _err "Not a regular file: $f"
    any_error=1
    continue
  else
    _ok "Regular file"
  fi

  # Symlink check
  if [ -L "$f" ]; then
    _err "Provider file is a symlink: $f"
    any_error=1
    continue
  else
    _ok "Not a symlink"
  fi

  # Owner check (portable)
  file_owner="$(_get_owner "$f")"
  if [ -z "$file_owner" ]; then
    _warn "Unable to determine owner for $f"
  else
    if [ -n "$CURRENT_USER" ] && [ "$file_owner" != "$CURRENT_USER" ]; then
      # By default warn; make fatal only if STRICT_VERIFY=1
      if [ "${STRICT_VERIFY:-0}" -eq 1 ]; then
        _err "Owner mismatch: $file_owner (expected: $CURRENT_USER) for $f"
        any_error=1
        continue
      else
        _warn "Owner differs: $file_owner (current: $CURRENT_USER) for $f"
      fi
    else
      _ok "Owned by current user: ${file_owner:-<unknown>}"
    fi
  fi

  # Permission checks (group/world write)
  perms="$(_get_perms "$f")"
  group_write="$(printf '%s' "$perms" | awk '{print substr($0,6,1)}')"
  others_write="$(printf '%s' "$perms" | awk '{print substr($0,9,1)}')"
  if [ "$group_write" = "w" ] || [ "$others_write" = "w" ]; then
    _err "Provider file is writable by group or world: $f (perms: $perms)"
    any_error=1
    continue
  else
    _ok "Not group/world writable (perms: $perms)"
  fi

  # Optional checksum (print only)
  if [ -n "$SHA_TOOL" ]; then
    printf 'Checksum: '
    if [ "$SHA_TOOL" = "sha256sum" ]; then
      sha256sum "$f" | awk '{print $1}'
    else
      shasum -a 256 "$f" | awk '{print $1}'
    fi
  else
    _warn "No SHA256 tool found (sha256sum/shasum); skipping checksum"
  fi

  _ok "Provider file passed checks: $f"
done

if [ "$any_error" -ne 0 ]; then
  _err "One or more provider files failed verification."
  exit 2
fi

_ok "All provider files verified successfully."
exit 0
