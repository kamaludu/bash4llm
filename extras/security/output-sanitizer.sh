#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/security/output-sanitizer.sh
# Authority: Architecture Specification (Edition 2026.1)
# Component: Extra Content Safety & Output Sanitizer Engine
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Purpose: Zero-Eval Output Sanitization & Terminal Escape Code Filter

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

STRICT_MODE=0
NO_ANSI=0

while [ $# -gt 0 ]; do
  case "$1" in
    --strict-output|--strict) STRICT_MODE=1; shift ;;
    --no-ansi) NO_ANSI=1; shift ;;
    *) shift ;;
  esac
done

case "${BASH4LLM_STRICT_OUTPUT:-0}" in
  1|true|TRUE|True|yes|YES|Yes) STRICT_MODE=1 ;;
esac

case "${NO_COLOR:-0}" in
  1|true|TRUE|True|yes|YES|Yes) NO_ANSI=1 ;;
esac

# =======================================
# Zero-Eval Output Sanitizer Engine (100% Standalone & Portable)
# =======================================
sanitize_stream() {
  # Step 1: POSIX T2 Strict Whitelist (Preserves \t, \r, \n, printable ASCII characters, and \033 for ANSI cleanup)
  LC_ALL=C tr -dc '\t\r\n\033[:print:]' | \
  awk -v esc=$'\033' -v strict="$STRICT_MODE" -v no_ansi="$NO_ANSI" '
    {
      line = $0

      # Step 2: Strip ANSI Terminal Escape Sequences (including extended/private modes)
      if (no_ansi == 1 || strict == 1) {
        ansi_regex = esc "\\[[0-9;?<=>]*[a-zA-Z]"
        gsub(ansi_regex, "", line)
        gsub(esc "\\([^B]", "", line)
        gsub(esc, "", line) # Rimuove eventuali caratteri ESC orfani o residui
      }

      # Step 3: Level 2 Strict Output Mode (Escape shell metacharacters for pipeline safety)
      if (strict == 1) {
        gsub(/\\/, "\\\\", line)
        gsub(/\$/, "\\$", line)
        gsub(/`/, "\\`", line)
        gsub(/!/, "\\!", line)
      }

      print line
    }
  '
}

sanitize_stream
exit 0
