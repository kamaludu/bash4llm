#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/lib/utils.sh
# Extra: Utility functions (v2.5.0 aligned)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# utils.sh — utility functions for bash4llm extras
# Provides small, portable and safe helpers (trim, numbers, join, tmpfile, debug).
# Used by providers and extras to avoid duplicated logic.
# No global side effects: only function definitions.
# Load with:  . "$BASH4LLM_EXTRAS_DIR/lib/utils.sh"
# -----------------------------------------------------------------------------

# Safely handle loading guard preventing terminal exits, warnings or nounset errors
if [ -n "${BASH4LLMUTILSLOADED:-}" ]; then
  if [ "${BASH_SOURCE[0]:-}" != "${0:-}" ]; then
    return 0
  else
    exit 0
  fi
fi
BASH4LLMUTILSLOADED=1

# gb_trim: trim leading and trailing whitespace using pure Bash native pattern matching
# Usage: gb_trim "  text  "    OR    printf '  text ' | gb_trim
gb_trim() {
  local var="${1:-}"
  if [ -z "$var" ] && [ ! -t 0 ]; then
    # Read one line from stdin if no direct argument and stdin is a pipe
    IFS= read -r var || var=''
  fi
  # Pure Bash 4.0+ native trim (forkless O(1) complexity)
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

# gb_is_number: return 0 if argument is a valid integer or decimal, else 1 (Zero-Fork)
# Usage: gb_is_number "3.14" && echo ok || echo not
gb_is_number() {
  local v="${1:-}"
  [ -n "$v" ] || return 1
  # Native Bash 4.x regex check avoiding external grep execution
  if [[ "$v" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
    return 0
  else
    return 1
  fi
}

# gb_join: join arguments with separator (first arg is separator)
# Usage: gb_join "," "a" "b" "c"  -> outputs: a,b,c
gb_join() {
  local sep="${1:-}"
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

# gb_mktempfile: create a secure temp file (GNU & BSD compliant via direct template path)
# Usage: tmpf="$(gb_mktempfile "prefix")"
gb_mktempfile() {
  local prefix="${1:-tmp}"
  local tmpdir="${BASH4LLM_TMPDIR:-}"
  local tmpf=""

  # Fallback to system temp directory if BASH4LLM_TMPDIR is unset or unsafe
  if [ -z "$tmpdir" ] || [ ! -d "$tmpdir" ] || [ -L "$tmpdir" ]; then
    tmpdir="/tmp"
  fi

  # Direct template path passing is natively and fully supported on both GNU and BSD mktemp
  tmpf="$(mktemp "${tmpdir%/}/${prefix}.XXXXXX" 2>/dev/null || true)"

  # Ensure file exists and apply safe permissions
  if [ -n "$tmpf" ] && [ -f "$tmpf" ]; then
    chmod 600 "$tmpf" 2>/dev/null || true
    printf '%s' "$tmpf"
    return 0
  fi

  return 1
}

# gb_debug: controlled debug printing protecting stdout from Format String injections and text values of DEBUG
# Usage: gb_debug "some debug message"
gb_debug() {
  # Safe check supporting both integer 1 and boolean (true/TRUE) formats without nounset/integer errors
  case "${DEBUG:-0}" in
    1|[tT][rR][uU][eE]) ;;
    *) return 0 ;;
  esac
  [ $# -gt 0 ] || return 0
  printf '[gb-debug] %s\n' "$*" >&2
}

# gb_ensure_tmpdir: ensure BASH4LLM_TMPDIR exists and is writable (optional helper)
# Usage: gb_ensure_tmpdir && echo ok || echo fail
gb_ensure_tmpdir() {
  local tmpdir="${BASH4LLM_TMPDIR:-}"
  [ -n "$tmpdir" ] || return 1

  # Reject if path is a symlink
  if [ -L "$tmpdir" ]; then
    return 1
  fi

  if [ -d "$tmpdir" ]; then
    [ -w "$tmpdir" ] || return 1
    return 0
  fi

  # Delegate to core safe_mkdir if available, otherwise fallback
  if type safe_mkdir >/dev/null 2>&1; then
    safe_mkdir "$tmpdir" 700 || return 1
  else
    mkdir -p "$tmpdir" 2>/dev/null || return 1
    chmod 700 "$tmpdir" 2>/dev/null || true
  fi
  return 0
}

# End of extras/lib/utils.sh
