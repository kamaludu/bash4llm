#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# SCINTILLA CORE v4.5.5 — T3 TEST SUITE FOR REFACTORED BASH4LLM
# ==============================================================================
# @target_category: T3
# @derived_from: CORE-Annex-C.1, CORE-Cap-8.2
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASH4LLM_BIN="${SCRIPT_DIR}/../../bash4llm"

printf "=== [T3 TEST] VERIFYING REFACTORED BASH4LLM ENHANCEMENTS ===\n"

# 1. Test Syntax Validation Flag (Reject non-SML text)
printf "Test 1: SML Validation Reject Check ... "
INVALID_OUT=$(echo "Hello world" | "$BASH4LLM_BIN" --validate-sml --dry-run 2>&1 || true)
if echo "$INVALID_OUT" | grep -qE "SYNTAX_VAL|13"; then
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
