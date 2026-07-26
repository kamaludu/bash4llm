#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/compatibility.sh
# Component: Level 2 — Compatibility Test Suite
# Scope: Short-running. Public Compatibility Contract verification.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'compatibility.sh: [FATAL ERROR] Bash 4.0 or superior is required.\n' >&2
    exit 15
  fi
  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'compatibility.sh: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
      missing=1
    fi
  done
  [ "$missing" -ne 0 ] && exit 15
}
verify_host_prerequisites

init_colors() {
  if { [ -t 1 ] || [ -t 2 ]; } && [ "${TERM:-}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
    C_RST=$'\e[0m' C_BOLD=$'\e[1m' C_GREEN=$'\e[0;32m' C_RED=$'\e[0;31m' C_CYAN=$'\e[0;36m'
    C_BGREEN=$'\e[1;32m' C_BRED=$'\e[1;31m' C_BCYAN=$'\e[1;36m'
  else
    C_RST="" C_BOLD="" C_GREEN="" C_RED="" C_CYAN="" C_BGREEN="" C_BRED="" C_BCYAN=""
  fi
}
init_colors

PASS=0; FAIL=0; TOTAL=0; FAIL_FAST=0
declare -a FAILED_LOGS=()

parse_cli_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --fail-fast) FAIL_FAST=1; shift ;;
      --no-color) export NO_COLOR=1; init_colors; shift ;;
      --dry-run) shift ;;
      *) shift ;;
    esac
  done
}
parse_cli_args "$@"

assert_test() {
  local desc="${1:-}" expected_rc="${2:-0}" actual_rc="${3:-0}" hint="${4:-}"
  TOTAL=$((TOTAL + 1))
  if [ "$expected_rc" -eq "$actual_rc" ]; then
    printf '  [%sPASS%s] %s\n' "$C_BGREEN" "$C_RST" "$desc"
    PASS=$((PASS + 1))
  else
    printf '  [%sFAIL%s] %s (Expected: %d, Got: %d)\n' "$C_BRED" "$C_RST" "$desc" "$expected_rc" "$actual_rc"
    FAIL=$((FAIL + 1))
    FAILED_LOGS+=("$desc [Expected: $expected_rc, Got: $actual_rc] ${hint:+— Hint: $hint}")
    if [ "$FAIL_FAST" -eq 1 ]; then
      printf '\n%s[FAIL-FAST] Halting Level 2 execution on first test failure.%s\n\n' "$C_BRED" "$C_RST" >&2
      exit 1
    fi
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR=""
TARGET_BIN=""

if [ -f "$SCRIPT_DIR/../../bash4llm" ]; then
  ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  TARGET_BIN="$ROOT_DIR/bash4llm"
elif [ -f "$SCRIPT_DIR/../../../bash4llm" ]; then
  ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  TARGET_BIN="$ROOT_DIR/bash4llm"
elif command -v bash4llm >/dev/null 2>&1; then
  TARGET_BIN="$(command -v bash4llm)"
  ROOT_DIR="$(dirname "$TARGET_BIN")"
fi

if [ -z "$TARGET_BIN" ] || [ ! -x "$TARGET_BIN" ]; then
  printf 'compatibility.sh: [FATAL ERROR] Target executable bash4llm not found.\n' >&2
  exit 15
fi

if [ -n "${ROOT_DIR:-}" ] && [ -w "$ROOT_DIR" ]; then
  TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
else
  TEST_SANDBOX_PARENT="${PWD}/.test_tmp"
fi
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.compat.XXXXXX")"
cleanup_sandbox() { rm -rf "$TEST_SANDBOX" 2>/dev/null || true; rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true; }
trap cleanup_sandbox EXIT INT TERM

export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_compat_key"

mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp"
printf 'llama-3.3-70b-versatile\nwhisper-large-v3\n' > "${BASH4LLM_DIR}/models/groq.txt"

printf '\n%b[LEVEL 2] Compatibility Test Suite (Public Contract Verification)%b\n' "$C_BCYAN" "$C_RST"

# 1. Canonical Exit Code 10: Missing API Key in non-interactive stdin mode
set +e
(
  unset GROQ_API_KEY BASH4LLM_API_KEY PROVIDER_API_ENV_groq
  export BASH4LLM_REQUIRE_VAULT=0
  "$TARGET_BIN" "Non-interactive test prompt" </dev/null >/dev/null 2>&1
)
rc_10=$?
set -e
assert_test "Canonical Exit Code 10: Missing API Key Contract" 10 $rc_10 "Check non-interactive API key prompt rejection."

# 2. Canonical Exit Code 11: Bad/Unsupported Multimodal Model
set +e
"$TARGET_BIN" -m "whisper-large-v3" --dry-run "Test audio model" >/dev/null 2>&1
rc_11=$?
set -e
assert_test "Canonical Exit Code 11: Bad / Multimodal Model Contract" 11 $rc_11 "Check validate_model_core filter."

# 3. Canonical Exit Code 12: Network / cURL Failure in Streaming Mode
set +e
(
  export BASH4LLM_SKIP_NETWORK=0
  export BASH4LLM_API_URL="https://127.0.0.1:65534/nonexistent"
  export GROQ_API_KEY="dummy_key_for_curl_fail_test"
  "$TARGET_BIN" --stream "Streaming network failure prompt" >/dev/null 2>&1
)
rc_12=$?
set -e
assert_test "Canonical Exit Code 12: Network Call Failure Contract" 12 $rc_12 "Check cURL connection failure path in streaming mode."

# 4. Canonical Exit Code 14: Missing Prompt Contract
set +e
"$TARGET_BIN" </dev/null >/dev/null 2>&1
rc_14=$?
set -e
assert_test "Canonical Exit Code 14: Missing Prompt Contract" 14 $rc_14 "Check empty prompt validation."

# 5. Canonical Exit Code 15: Directory / System Path Failure (/tmp rejection)
set +e
(
  export BASH4LLM_DIR="/tmp"
  "$TARGET_BIN" --version >/dev/null 2>&1
)
rc_15=$?
set -e
assert_test "Canonical Exit Code 15: System / Temp Directory Rejection Contract" 15 $rc_15 "Check BASH4LLM_DIR /tmp guard."

# 6. Canonical Exit Code 17: Security Violation / Binary Input Filter
bin_file="${TEST_SANDBOX}/binary_input.bin"
printf '\x00\x01\x02UNSAFE_BINARY_DATA' > "$bin_file"
set +e
"$TARGET_BIN" -f "$bin_file" --dry-run >/dev/null 2>&1
rc_17=$?
set -e
assert_test "Canonical Exit Code 17: Security Policy Violation Contract" 17 $rc_17 "Check validate_file_input binary guard."

# 7. Output Schemas Verification
set +e
"$TARGET_BIN" --json --dry-run "Format Test" >/dev/null 2>&1
rc_json=$?
"$TARGET_BIN" --pretty --dry-run "Pretty Test" >/dev/null 2>&1
rc_pretty=$?
"$TARGET_BIN" --raw --dry-run "Raw Test" >/dev/null 2>&1
rc_raw=$?
"$TARGET_BIN" --text --dry-run "Text Test" >/dev/null 2>&1
rc_text=$?
set -e
assert_test "Output Schema Contract: --json option" 0 $rc_json
assert_test "Output Schema Contract: --pretty option" 0 $rc_pretty
assert_test "Output Schema Contract: --raw option" 0 $rc_raw
assert_test "Output Schema Contract: --text option" 0 $rc_text

# 8. Default Model Persistence Contract
set +e
"$TARGET_BIN" --provider groq --set-default "llama-3.3-70b-versatile" >/dev/null 2>&1
rc_setdef=$?
set -e
assert_test "Default model persistence contract (--set-default)" 0 $rc_setdef

printf '\n%s-------------------------------------------------------%s\n' "$C_BOLD" "$C_RST"
printf ' Level 2 Compatibility Results: %d Passed, %d Failed (Total: %d)\n' "$PASS" "$FAIL" "$TOTAL"
printf '%s-------------------------------------------------------%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
