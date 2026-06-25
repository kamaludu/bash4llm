#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM+ — Bash-first wrapper for the LLM
# File: extras/lib/debug.sh
# Extra: Debug helper
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Purpose: Optional debug and diagnostics helpers for bash4llm.
# Source this file to enable richer diagnostics. The core does not require it.
# Usage (optional):
#   . /path/to/bash4llm.d/extras/lib/debug.sh
# This file intentionally avoids side effects on load.

[ -n "${BASH4LLM_DEBUG_SH_LOADED:-}" ] && return 0
BASH4LLM_DEBUG_SH_LOADED=1

# verbose_log: controlled verbose logging
# Usage: verbose_log "LEVEL" "some message"
verbose_log() {
  local level="${1:-INFO}"; shift || true
  # Only print if DEBUG is set to 1
  [ "${DEBUG:-0}" -eq 1 ] || return 0
  printf '[%s] %s\n' "$level" "$*" >&2
}

# dump_state: print a compact snapshot of important variables
# Usage: dump_state
dump_state() {
  {
    printf '=== bash4llm state dump ===\n'
    printf 'PROVIDER=%s\n' "${PROVIDER:-}"
    printf 'MODEL=%s\n' "${MODEL:-}"
    printf 'STREAM_MODE=%s\n' "${STREAM_MODE:-}"
    printf 'OUTPUT_MODE=%s\n' "${OUTPUT_MODE:-}"
    if [ -n "${GROQ_API_KEY:-}" ]; then
      printf 'GROQ_API_KEY set? yes\n'
    else
      printf 'GROQ_API_KEY set? no\n'
    fi
    printf 'BASH4LLM_CONFIG_DIR=%s\n' "${BASH4LLM_CONFIG_DIR:-}"
    printf 'BASH4LLM_MODELS_DIR=%s\n' "${BASH4LLM_MODELS_DIR:-}"
    printf 'BASH4LLM_TMPDIR=%s\n' "${BASH4LLM_TMPDIR:-}"
    if [ -n "${ALLOWED_MODELS:-}" ]; then
      printf 'ALLOWED_MODELS present? yes\n'
    else
      printf 'ALLOWED_MODELS present? no\n'
    fi
    printf '============================\n'
  } >&2
}

# print_env_subset: print selected environment variables useful for debugging
# Usage: print_env_subset VAR1 VAR2 ...
print_env_subset() {
  local var
  for var in "$@"; do
    printf '%s=%s\n' "$var" "${!var:-}" >&2
  done
}

# structured_debug: print a key:value list in aligned columns
# Usage: structured_debug key1 "value1" key2 "value2" ...
structured_debug() {
  local -a pairs=("$@")
  local i key val max=0
  for ((i=0;i<${#pairs[@]};i+=2)); do
    key="${pairs[i]}"
    [ "${#key}" -gt "$max" ] && max="${#key}"
  done
  for ((i=0;i<${#pairs[@]};i+=2)); do
    key="${pairs[i]}"; val="${pairs[i+1]:-}"
    printf '%-*s : %s\n' "$max" "$key" "$val" >&2
  done
}

# trace_cmd: run a command and print it before execution (debug only)
# Usage: trace_cmd ls -la /tmp
trace_cmd() {
  if [ "${DEBUG:-0}" -eq 1 ]; then
    printf '[TRACE] %s\n' "$*" >&2
    "$@"
    return $?
  else
    "$@"
    return $?
  fi
}

# safe_dump_file_head: print head of a file for quick inspection
# Avoid following symlinks and skip non-regular files
safe_dump_file_head() {
  local f="$1" n="${2:-20}"
  if [ -z "$f" ]; then
    printf 'safe_dump_file_head: no file provided\n' >&2
    return 1
  fi
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf 'File not readable or not a regular file: %s\n' "$f" >&2
    return 1
  fi
  printf '--- head of %s (first %s lines) ---\n' "$f" "$n" >&2
  head -n "$n" "$f" >&2 || true
  printf '--- end ---\n' >&2
}

# End of extras/lib/debug.sh
