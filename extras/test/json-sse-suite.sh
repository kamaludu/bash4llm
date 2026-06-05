#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/test/json-sse-suite.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Requirements
#  - python3 must be available in PATH (required). Exits with code 3 if missing.
#  - optional: jq (if an alternative parser is preferred).
# Purpose
#  - Small test suite for JSON escaping and SSE "content" parsing logic.
#  - Provides two reusable functions:
#      * escape_json_string STRING  -> returns STRING escaped for JSON
#      * parse_sse_content LINE     -> extracts and normalizes the "content" value from an SSE line
# Behavior and implementation
#  - escape_json_string uses python3 + json.dumps to produce correct escaping.
#  - parse_sse_content reads from stdin and uses python3 + json.JSONDecoder().raw_decode
#    to find the first JSON object and return .content (normalized).
#  - The file is sourcable: it defines functions without running tests when sourced.
#    Tests run only when the script is executed directly.
# Quick usage
#  - Source to use the functions:  source ./json-sse-suite.sh
#  - Run the test suite:          ./json-sse-suite.sh
# Exit codes
#  - 0  : all tests passed
#  - 2  : one or more tests failed
#  - 3  : python3 not found
# -----------------------------------------------------------------------------
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  printf 'ERROR: json-sse-suite.sh richiede python3 nel PATH.\n' >&2
  exit 3
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

# runner e test (eseguiti solo se lo script è lanciato direttamente)
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
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
  if [ "$failed" -ne 0 ]; then exit 2; else exit 0; fi
fi
