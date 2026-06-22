#!/usr/bin/env bash
# =============================================================================
# Bash4LLM — Bash-first wrapper for the Groq API
# File: extras/security/validate-env.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/bash4llm
# =============================================================================
# Purpose:
#   Verify the minimum environment required to run bash4llm safely.
#   Checks presence of critical commands (bash, curl, jq, gawk, find, stat,
#   mktemp, flock, etc.), correctness of runtime directories and the tmp
#   policy (BASH4LLM_TMPDIR must be absolute, not world-writable and, when
#   possible, located inside BASH4LLM_DIR). Emits WARN for non-critical
#   absences and ERROR for conditions that prevent safe execution.
#
# Usage:
#   Export the required environment variables (example):
#     export BASH4LLM_DIR="$PWD"
#     export BASH4LLM_EXTRAS_DIR="$BASH4LLM_DIR/bash4llm.d/extras"
#     export BASH4LLM_TMPDIR="$BASH4LLM_DIR/bash4llm.d/tmp"
#     export PROVIDERS_DIR="$BASH4LLM_EXTRAS_DIR/providers"
#     ./validate-env.sh
#
#   Alternative usage (only to test a restricted PATH):
#     PATH="/usr/bin:/bin" ./validate-env.sh
#   Note: overwriting PATH can remove binaries installed in non-standard
#   locations (e.g., Termux). Prefer using export to set variables.
#
# Output and exit codes:
#   - exit 0 : all critical checks passed (WARNs may still be present).
#   - exit 2 : one or more critical checks failed (ERROR).
#
# How to fix common ERRORs:
#   - Missing tool: install the missing command or restore PATH.
#   - BASH4LLM_TMPDIR not absolute or outside BASH4LLM_DIR: set an
#     absolute path under BASH4LLM_DIR with restrictive permissions.
#   - BASH4LLM_EXTRAS_DIR missing: create the directory or set the variable.
#
# Security notes:
#   - The script creates directories with umask 077 when necessary.
#   - It does not change existing permissions without notice; it flags
#     world-writable directories as critical conditions.
# ---------------------------------------------------------------------------

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
BASH4LLM_TMPDIR="${BASH4LLM_TMPDIR:-${BASH4LLMTMPDIR:-}}"
BASH4LLM_EXTRAS_DIR="${BASH4LLM_EXTRAS_DIR:-${BASH4LLMEXTRASDIR:-}}"
BASH4LLM_DIR="${BASH4LLM_DIR:-${BASH4LLM_HOME:-}}"

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

# Derive BASH4LLM_DIR only if not set
if [ -z "${BASH4LLM_DIR:-}" ]; then
  _script_path="${BASH_SOURCE[0]:-$0}"
  if [ -n "$_script_path" ]; then
    _script_dir="$(cd "$(dirname "$_script_path")" >/dev/null 2>&1 && pwd -P || true)"
    # assume repo root is two levels up from extras/security by default
    BASH4LLM_DIR_CANDIDATE="$(cd "$_script_dir/../.." >/dev/null 2>&1 && pwd -P || true || echo "$_script_dir")"
    BASH4LLM_DIR="$BASH4LLM_DIR_CANDIDATE"
    _warn "BASH4LLM_DIR not set; derived candidate: $BASH4LLM_DIR"
  fi
else
  _ok "BASH4LLM_DIR set: $BASH4LLM_DIR"
fi

# If PROVIDERS_DIR not set and BASH4LLM_DIR known, set sensible default
if [ -z "${PROVIDERS_DIR:-}" ] && [ -n "${BASH4LLM_DIR:-}" ]; then
  PROVIDERS_DIR="${BASH4LLM_DIR%/}/bash4llm.d/extras/providers"
fi

printf '\nValidating BASH4LLM_TMPDIR...\n'
if [ -z "${BASH4LLM_TMPDIR:-}" ]; then
  _warn "BASH4LLM_TMPDIR is not set. Bash4LLM will use its default internal tmpdir."
else
  case "$BASH4LLM_TMPDIR" in
    /*) : ;;
    *)
      _err "BASH4LLM_TMPDIR must be an absolute path: $BASH4LLM_TMPDIR"
      critical_fail=1
      ;;
  esac

  if [ -n "${BASH4LLM_DIR:-}" ] && [ -n "${BASH4LLM_TMPDIR:-}" ]; then
    case "$BASH4LLM_TMPDIR" in
      "$BASH4LLM_DIR"/*) : ;;
      *)
        _err "BASH4LLM_TMPDIR must be inside BASH4LLM_DIR ($BASH4LLM_DIR): $BASH4LLM_TMPDIR"
        critical_fail=1
        ;;
    esac
  fi

  if [ -n "$BASH4LLM_TMPDIR" ]; then
    if [ -d "$BASH4LLM_TMPDIR" ]; then
      if _is_world_writable "$BASH4LLM_TMPDIR"; then
        _err "BASH4LLM_TMPDIR is world-writable: $BASH4LLM_TMPDIR"
        critical_fail=1
      else
        _ok "BASH4LLM_TMPDIR exists and is not world-writable: $BASH4LLM_TMPDIR"
      fi
    else
      old_umask="$(umask)"
      umask 077
      if mkdir -p -- "$BASH4LLM_TMPDIR" 2>/dev/null; then
        umask "$old_umask"
        _ok "BASH4LLM_TMPDIR created with restrictive permissions: $BASH4LLM_TMPDIR"
        owner_uid="$(_stat_uid "$BASH4LLM_TMPDIR" || true)"
        if [ -n "$owner_uid" ] && [ "$owner_uid" != "$(id -u)" ]; then
          _warn "BASH4LLM_TMPDIR owner differs from current user (uid $owner_uid)"
        fi
      else
        umask "$old_umask"
        _err "BASH4LLM_TMPDIR does not exist and cannot be created: $BASH4LLM_TMPDIR"
        critical_fail=1
      fi
    fi
  fi
fi

printf '\nValidating BASH4LLM_EXTRAS_DIR...\n'
if [ -z "${BASH4LLM_EXTRAS_DIR:-}" ]; then
  _err "BASH4LLM_EXTRAS_DIR is not set. Set it to your bash4llm extras directory."
  critical_fail=1
else
  case "$BASH4LLM_EXTRAS_DIR" in
    /*) : ;;
    *)
      _err "BASH4LLM_EXTRAS_DIR must be an absolute path: $BASH4LLM_EXTRAS_DIR"
      critical_fail=1
      ;;
  esac
  if [ -d "$BASH4LLM_EXTRAS_DIR" ]; then
    if _is_world_writable "$BASH4LLM_EXTRAS_DIR"; then
      _err "BASH4LLM_EXTRAS_DIR is world-writable: $BASH4LLM_EXTRAS_DIR"
      critical_fail=1
    else
      _ok "BASH4LLM_EXTRAS_DIR exists and is not world-writable: $BASH4LLM_EXTRAS_DIR"
    fi
  else
    old_umask="$(umask)"
    umask 077
    if mkdir -p -- "$BASH4LLM_EXTRAS_DIR" 2>/dev/null; then
      umask "$old_umask"
      _ok "BASH4LLM_EXTRAS_DIR created with restrictive permissions: $BASH4LLM_EXTRAS_DIR"
    else
      umask "$old_umask"
      _err "BASH4LLM_EXTRAS_DIR does not exist and cannot be created: $BASH4LLM_EXTRAS_DIR"
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
  _err "One or more critical checks failed. Fix the issues above before running bash4llm in untrusted environments."
  exit 2
else
  _ok "All critical environment checks passed (subject to warnings above)."
  exit 0
fi
