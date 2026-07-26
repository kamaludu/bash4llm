#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/regression.sh
# Component: Level 3 — Regression Test Suite
# Scope: Short-running. End-to-end functional flow verification.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'regression.sh: [FATAL ERROR] Bash 4.0 or superior is required.\n' >&2
    exit 15
  fi
  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'regression.sh: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
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

calc_sha256() {
  local input="${1:-}"
  if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$input" | sha256sum | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then printf '%s' "$input" | openssl dgst -sha256 -r | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then printf '%s' "$input" | shasum -a 256 | awk '{print $1}'
  else printf ''; fi
}

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
      printf '\n%s[FAIL-FAST] Halting Level 3 execution on first test failure.%s\n\n' "$C_BRED" "$C_RST" >&2
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
  printf 'regression.sh: [FATAL ERROR] Target executable bash4llm not found.\n' >&2
  exit 15
fi

if [ -n "${ROOT_DIR:-}" ] && [ -w "$ROOT_DIR" ]; then
  TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
else
  TEST_SANDBOX_PARENT="${PWD}/.test_tmp"
fi
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.regr.XXXXXX")"
cleanup_sandbox() { rm -rf "$TEST_SANDBOX" 2>/dev/null || true; rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true; }
trap cleanup_sandbox EXIT INT TERM

export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_regr_key"

mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp" "${BASH4LLM_DIR}/templates"
printf 'llama-3.3-70b-versatile\n' > "${BASH4LLM_DIR}/models/groq.txt"

printf '\n%b[LEVEL 3] Regression Test Suite (End-to-End Functional Flow)%b\n' "$C_BCYAN" "$C_RST"

# 1. Pipe STDIN Prompt Assembly
set +e
echo "Piped STDIN Regression Prompt" | "$TARGET_BIN" --dry-run >/dev/null 2>&1
rc_piped=$?
set -e
assert_test "STDIN piping prompt assembly" 0 $rc_piped

# 2. File Input Processing (-f)
tmp_input_file="${TEST_SANDBOX}/regression_input.txt"
printf 'Regression File Input Payload' > "$tmp_input_file"
set +e
"$TARGET_BIN" -f "$tmp_input_file" --dry-run >/dev/null 2>&1
rc_filein=$?
set -e
assert_test "File input processing (-f)" 0 $rc_filein

# 3. Template Engine Expansion
printf 'Header\n{{CONTENT}}\nFooter' > "${BASH4LLM_DIR}/templates/regression.tmpl"
set +e
"$TARGET_BIN" --template regression.tmpl "Expanded Payload Data" --dry-run >/dev/null 2>&1
rc_tmpl=$?
set -e
assert_test "Template engine variable expansion (--template)" 0 $rc_tmpl

# 4. Thread History Lifecycle
raw_thread_id="regression_user_thread_01"
set +e
"$TARGET_BIN" --thread "$raw_thread_id" --init-thread >/dev/null 2>&1
rc_th_init=$?
set -e
assert_test "Thread lifecycle: Initialization (--init-thread)" 0 $rc_th_init

expected_hash="$(calc_sha256 "$raw_thread_id")"
set +e
"$TARGET_BIN" --thread "$raw_thread_id" --rename-thread "$raw_thread_id" --title "Regression Title" >/dev/null 2>&1
rc_th_ren=$?
set -e
meta_file="${BASH4LLM_DIR}/config/ui_state/threads/${expected_hash}.json"
if [ "$rc_th_ren" -eq 0 ] && [ -f "$meta_file" ] && grep -q "Regression Title" "$meta_file"; then
  assert_test "Thread lifecycle: Metadata renaming (--rename-thread)" 0 0
else
  assert_test "Thread lifecycle: Metadata renaming (--rename-thread)" 0 1 "Check ui_state thread metadata write."
fi

set +e
"$TARGET_BIN" --delete-thread "$raw_thread_id" >/dev/null 2>&1
rc_th_del=$?
set -e
thread_ndjson="${BASH4LLM_DIR}/history/threads/${expected_hash}.ndjson"
if [ "$rc_th_del" -eq 0 ] && [ ! -f "$thread_ndjson" ]; then
  assert_test "Thread lifecycle: Safe deletion (--delete-thread)" 0 0
else
  assert_test "Thread lifecycle: Safe deletion (--delete-thread)" 0 1 "Check thread file purge."
fi

printf '\n%s-------------------------------------------------------%s\n' "$C_BOLD" "$C_RST"
printf ' Level 3 Regression Results: %d Passed, %d Failed (Total: %d)\n' "$PASS" "$FAIL" "$TOTAL"
printf '%s-------------------------------------------------------%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
