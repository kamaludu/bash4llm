#!/usr/bin/env bash
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the Groq API
# File: extras/lib/utils.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/bash4llm
# =============================================================================
# utils.sh — utility functions for bash4llm extras
# Provides small, portable and safe helpers (trim, numbers, join, tmpfile, debug).
# Used by providers and extras to avoid duplicated logic.
# No global side effects: only function definitions.
# Load with:  . "$BASH4LLM_EXTRAS_DIR/lib/utils.sh"
# ---
# gb_mktempfile, gb_ensure_tmpdir - handle secure temporary files.
# gb_trim, gb_is_number, gb_join - simplify string parsing and manipulation.
# gb_debug - enables diagnostic logging only when DEBUG is set.

# Load guard (exact, valid POSIX/Bash form)
if [ -n "${BASH4LLMUTILSLOADED:-}" ]; then
  return 0
fi
BASH4LLMUTILSLOADED=1

# No side effects on source: only function definitions and the load guard above.

# gb_trim: trim leading and trailing whitespace
# Usage: gb_trim "  text  "    OR    printf '  text ' | gb_trim
gb_trim() {
  local input
  if [ $# -gt 0 ]; then
    input="$1"
  else
    # read one line from stdin
    IFS= read -r input || input=''
  fi
  # Use awk for portability and correctness
  printf '%s' "$input" | awk '{ sub(/^[ \t\r\n]+/, ""); sub(/[ \t\r\n]+$/, ""); print }'
}

# gb_is_number: return 0 if argument is a valid integer or decimal, else 1
# Accepts optional leading + or - and decimal point. No output on success.
# Usage: gb_is_number "3.14" && echo ok || echo not
gb_is_number() {
  local v="${1:-}"
  [ -n "$v" ] || return 1
  printf '%s' "$v" | grep -E -q '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
  return $?
}

# gb_join: join arguments with separator (first arg is separator)
# Usage: gb_join "," "a" "b" "c"  -> outputs: a,b,c
gb_join() {
  local sep="$1"
  shift || true
  local out=""
  local first=1
  local v
  for v in "$@"; do
    if [ "$first" -eq 1 ]; then
      out="$v"
      first=0
    else
      out="${out}${sep}${v}"
    fi
  done
  printf '%s' "$out"
}

# gb_mktempfile: create a secure temp file
# Usage: tmpf="$(gb_mktempfile "prefix")"
# Prints the filename to stdout or returns non-zero on failure.
gb_mktempfile() {
  local prefix="${1:-tmp}"
  local tmpf=""

  # Prefer BASH4LLM_TMPDIR if set and appears safe
  if [ -n "${BASH4LLM_TMPDIR:-}" ] && [ -d "${BASH4LLM_TMPDIR}" ]; then
    # Reject if tmpdir is a symlink
    if [ -L "${BASH4LLM_TMPDIR}" ]; then
      return 1
    fi
    # Prefer mktemp -p when available (GNU, BusyBox)
    if mktemp -p "${BASH4LLM_TMPDIR}" "${prefix}.XXXXXX" >/dev/null 2>&1; then
      tmpf="$(mktemp -p "${BASH4LLM_TMPDIR}" "${prefix}.XXXXXX" 2>/dev/null || true)"
    fi
  fi

  # Fallback to system mktemp without -p
  if [ -z "$tmpf" ]; then
    if mktemp "${prefix}.XXXXXX" >/dev/null 2>&1; then
      tmpf="$(mktemp "${prefix}.XXXXXX" 2>/dev/null || true)"
    fi
  fi

  # Ensure file exists and has safe perms
  if [ -n "$tmpf" ] && [ -f "$tmpf" ]; then
    chmod 600 "$tmpf" 2>/dev/null || true
    printf '%s' "$tmpf"
    return 0
  fi

  return 1
}

# gb_debug: controlled debug printing to stderr
# Usage: gb_debug "message" or gb_debug "fmt %s" "arg"
gb_debug() {
  if [ -z "${DEBUG:-}" ]; then
    return 0
  fi
  if [ $# -eq 0 ]; then
    return 0
  fi
  printf '[gb-debug] %s\n' "$(printf "$@")" >&2
}

# gb_ensure_tmpdir: ensure BASH4LLM_TMPDIR exists and is writable (optional helper)
# Usage: gb_ensure_tmpdir && echo ok || echo fail
# Behavior: creates directory with mode 700, rejects symlink paths.
gb_ensure_tmpdir() {
  [ -n "${BASH4LLM_TMPDIR:-}" ] || return 1

  # Reject if path is a symlink
  if [ -L "${BASH4LLM_TMPDIR}" ]; then
    return 1
  fi

  if [ -d "${BASH4LLM_TMPDIR}" ]; then
    [ -w "${BASH4LLM_TMPDIR}" ] || return 1
    return 0
  fi

  mkdir -p "${BASH4LLM_TMPDIR}" 2>/dev/null || return 1
  chmod 700 "${BASH4LLM_TMPDIR}" 2>/dev/null || true
  return 0
}

# End of extras/lib/utils.sh
