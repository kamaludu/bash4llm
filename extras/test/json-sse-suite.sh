#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/json-sse-suite.sh
# Extra: Optional test suite for JSON and SSE
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Purpose
#  - Small test suite for JSON escaping and SSE "content" parsing logic.
#  - Provides two reusable functions:
#      * escape_json_string STRING  -> returns STRING escaped for JSON
#      * parse_sse_content LINE     -> extracts and normalizes the "content" value from an SSE line
#
# REQUIREMENTS (Optional / Secondary tool)
#  - This is an optional test helper.
#  - It strictly REQUIRES Python 3 (python3 executable) available in the PATH.
#  - Python is used here to validate JSON serialization boundaries.
#
# Behavior and implementation
#  - escape_json_string uses python3 + json.dumps to produce correct escaping.
#  - parse_sse_content reads from stdin and uses python3 + json.JSONDecoder().raw_decode
#    to find the first JSON object and return .content (normalized).
#  - The file is sourcable: it defines functions without running tests when sourced.
#    Tests run only when the script is executed directly.
# -----------------------------------------------------------------------------

# Safely determine if the script is being sourced or executed directly
_BASH4LLM_TEST_SOURCED=0
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  _BASH4LLM_TEST_SOURCED=1
fi

# Only set strict shell options if executed directly,
# preventing pollution of the calling interactive shell when sourced.
if [ "$_BASH4LLM_TEST_SOURCED" -eq 0 ]; then
  set -euo pipefail
fi

# Prominent dependency check with sourcing guard to prevent parent terminal closure
if ! command -v python3 >/dev/null 2>&1; then
  printf 'bash4llm: ERROR: [OPTIONAL TOOL] json-sse-suite.sh richiede python3 nel PATH.\n' >&2
  printf 'Si prega di installare python3 o procedere senza eseguire questo test ausiliario.\n' >&2
  if [ "$_BASH4LLM_TEST_SOURCED" -eq 1 ]; then
    unset _BASH4LLM_TEST_SOURCED
    return 3 2>/dev/null || exit 3
  else
    exit 3
  fi
fi

escape_json_string() {
  local s="$1"
  printf '%s' "$s" | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read())[1:-1])'
}

parse_sse_content() {
  local line="$1"
  line="${line#data: }"
  printf '%s' "$line" | python3 -c '
import sys, json
s = sys.stdin.read()
dec = json.JSONDecoder()
idx = 0
obj = None
while True:
    try:
        obj, end = dec.raw_decode(s[idx:])
        break
    except Exception:
        next_brace = s.find("{", idx+1)
        if next_brace == -1:
            obj = None
            break
        idx = next_brace
if obj is None:
    sys.exit(0)
v = obj.get("content", "")
if isinstance(v, str):
    print(json.dumps(v)[1:-1], end="")'
}

if [ "$_BASH4LLM_TEST_SOURCED" -eq 0 ]; then
  printf 'bash4llm: INFO: Avvio suite opzionale di test JSON/SSE (Richiede Python 3)...\n\n' >&2

  # Test-only variables and helper functions are isolated here
  total=0; failed=0
  run_test(){ total=$((total+1)); local name="$1"; shift; if "$@"; then printf 'PASS: %s\n' "$name"; else printf 'FAIL: %s\n' "$name"; failed=$((failed+1)); fi }

  test_escape_simple(){ local inp='Hello world'; out="$(escape_json_string "$inp")"; [ "$out" = 'Hello world' ]; }
  test_escape_quotes(){ local inp='He said "Hi"'; out="$(escape_json_string "$inp")"; [ "$out" = 'He said \"Hi\"' ]; }
  test_escape_backslash(){ local inp='C:\path\to\file'; out="$(escape_json_string "$inp")"; [ "$out" = 'C:\\path\\to\\file' ]; }
  test_escape_newline(){ local inp='Line1
Line2'; out="$(escape_json_string "$inp")"; [ "$out" = 'Line1\nLine2' ]; }
  test_escape_control(){ local inp=$'Tab\tCR\rEnd'; out="$(escape_json_string "$inp")"; [ "$out" = 'Tab\tCR\rEnd' ]; }

  test_parse_simple(){ local line='data: {"content":"Hello"}'; out="$(parse_sse_content "$line")"; [ "$out" = 'Hello' ]; }
  test_parse_escaped_quotes(){ local line='data: {"content":"He said \"Hi\" to her"}'; out="$(parse_sse_content "$line")"; [ "$out" = 'He said \"Hi\" to her' ] || [ "$out" = 'He said "Hi" to her' ]; }
  test_parse_backslashes(){ local line='data: {"content":"C:\\\\path\\\\file"}'; out="$(parse_sse_content "$line")"; [ "$out" = 'C:\\path\\file' ] || [ "$out" = 'C:\\\\path\\\\file' ]; }
  test_parse_multiple_fields(){ local line='data: {"id":"1","content":"Multi","other":"x"}'; out="$(parse_sse_content "$line")"; [ "$out" = 'Multi' ]; }
  test_parse_no_content(){ local line='data: {"message":"no content here"}'; out="$(parse_sse_content "$line" || true)"; [ -z "$out" ]; }

  run_test "escape: simple" test_escape_simple
  run_test "escape: quotes" test_escape_quotes
  run_test "escape: backslash" test_escape_backslash
  run_test "escape: newline" test_escape_newline
  run_test "escape: control chars" test_escape_control

  run_test "parse SSE: simple" test_parse_simple
  run_test "parse SSE: escaped quotes" test_parse_escaped_quotes
  run_test "parse SSE: backslashes" test_parse_backslashes
  run_test "parse SSE: multiple fields" test_parse_multiple_fields
  run_test "parse SSE: no content" test_parse_no_content

  printf '\nTest summary: %d total, %d failed\n' "$total" "$failed"
  
  # Clean namespace before exit
  unset _BASH4LLM_TEST_SOURCED
  if [ "$failed" -ne 0 ]; then exit 2; else exit 0; fi
fi

# Clean namespace when sourced successfully without leaking test state variables
unset _BASH4LLM_TEST_SOURCED
