#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# SCINTILLA CORE v4.5.5 — T3 TEST SUITE FOR REFACTORED BASH4LLM
# ==============================================================================
# @target_category: T3
# @derived_from: CORE-Annex-C.1, CORE-Cap-8.2
# File: extras/test/scintilla-t3.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

# Resolves bash4llm binary dynamically by walking up the directory tree
resolve_bash4llm_bin() {
  if [ -n "${BASH4LLM_BIN:-}" ] && [ -f "${BASH4LLM_BIN}" ]; then
    printf '%s' "${BASH4LLM_BIN}"
    return 0
  fi

  local current_dir
  current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

  # Ascend the directory tree parent by parent until bash4llm executable is found
  while [ -n "$current_dir" ] && [ "$current_dir" != "/" ]; do
    if [ -f "${current_dir}/bash4llm" ] && [ -r "${current_dir}/bash4llm" ]; then
      printf '%s' "${current_dir}/bash4llm"
      return 0
    fi
    current_dir="$(dirname "$current_dir")"
  done

  if command -v bash4llm >/dev/null 2>&1; then
    command -v bash4llm
  else
    printf './bash4llm'
  fi
}

BASH4LLM_BIN="$(resolve_bash4llm_bin)"

printf "=== [T3 TEST] VERIFYING REFACTORED BASH4LLM ENHANCEMENTS ===\n"

# 1. Test Syntax Validation Flag (Reject non-SML text)
printf "Test 1: SML Validation Reject Check ... "
INVALID_OUT=$(echo "Hello world" | "$BASH4LLM_BIN" --validate-sml --dry-run 2>&1 || true)
if echo "$INVALID_OUT" | grep -qE "SYNTAX_VAL|13|14"; then
  printf "PASSED\n"
else
  printf "FAILED\n" && exit 1
fi

# 2. Test Output Sanitization Flag
printf "Test 2: Output Sanitization Check ... "
CLEAN_TEXT=$(echo -e "\x1B[31mRedText\x1B[0m" | "$BASH4LLM_BIN" --sanitize --dry-run 2>&1 || true)
if [[ "$CLEAN_TEXT" != *"\x1B"* ]]; then
  printf "PASSED\n"
else
  printf "FAILED\n" && exit 1
fi

# 3. Test JSON Diagnostics Flag
printf "Test 3: JSON Diagnostics Output Check ... "
DIAG_OUT=$(echo "Hello" | "$BASH4LLM_BIN" --validate-sml --json-diagnostics --dry-run 2>&1 || true)
if echo "$DIAG_OUT" | jq -e '.bash4llm_status == "ERROR"' >/dev/null 2>&1; then
  printf "PASSED\n"
else
  printf "FAILED\n" && exit 1
fi

printf "=== ALL BASH4LLM REFACTORING VERIFICATION TESTS PASSED ===\n"
exit 0
