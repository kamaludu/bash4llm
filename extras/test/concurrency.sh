#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/concurrency.sh
# Component: Level 5 — Concurrency Test Suite
# Scope: Medium-running. Multi-process synchronization correctness.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'test: [FATAL ERROR] Bash 4.0 or superior is required.\n' >&2
    exit 15
  fi
  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'test: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
      missing=1
    fi
  done
  if [ "$missing" -ne 0 ]; then
    exit 15
  fi
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
      printf '\n%s[FAIL-FAST] Halting Level 5 execution on first test failure.%s\n\n' "$C_BRED" "$C_RST" >&2
      exit 1
    fi
  fi
}

detect_safe_concurrency() {
  if [ -n "${BASH4LLM_TEST_CONCURRENCY:-}" ] && [[ "${BASH4LLM_TEST_CONCURRENCY}" =~ ^[0-9]+$ ]]; then
    printf '%s' "$BASH4LLM_TEST_CONCURRENCY"
    return
  fi
  if [ "${BASH4LLM_PLAT_ANDROID:-0}" -eq 1 ] || [ -n "${TERMUX_VERSION:-}" ]; then printf '10'; return; fi
  if [ "${BASH4LLM_PLAT_CYGWIN:-0}" -eq 1 ]; then printf '10'; return; fi
  if [ "${BASH4LLM_PLAT_WSL:-0}" -eq 1 ]; then printf '20'; return; fi

  local cores=2
  if command -v nproc >/dev/null 2>&1; then
    cores="$(nproc 2>/dev/null || echo 2)"
  elif command -v sysctl >/dev/null 2>&1; then
    cores="$(sysctl -n hw.ncpu 2>/dev/null || echo 2)"
  fi
  
  if ! [[ "$cores" =~ ^[0-9]+$ ]]; then cores=2; fi

  local calc=$((cores * 10))
  if [ "$calc" -gt 40 ]; then calc=40; fi
  if [ "$calc" -lt 10 ]; then calc=10; fi
  printf '%s' "$calc"
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
  printf 'concurrency.sh: [FATAL ERROR] Target executable bash4llm not found.\n' >&2
  exit 15
fi

if [ -n "${ROOT_DIR:-}" ] && [ -w "$ROOT_DIR" ]; then
  TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
else
  TEST_SANDBOX_PARENT="${PWD}/.test_tmp"
fi
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.conc.XXXXXX")"
cleanup_sandbox() { rm -rf "$TEST_SANDBOX" 2>/dev/null || true; rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true; }
trap cleanup_sandbox EXIT INT TERM

export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_conc_key"

mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp"
printf 'llama-3.3-70b-versatile\n' > "${BASH4LLM_DIR}/models/groq.txt"

# Source bash4llm FIRST so platform detection environment variables are fully populated
export BASH4LLM_SOURCE_ONLY=1
. "$TARGET_BIN" >/dev/null 2>&1 || true

workers="$(detect_safe_concurrency)"
printf '\n%b[LEVEL 5] Concurrency Test Suite (%d Parallel Process Workers)%b\n' "$C_BCYAN" "$workers" "$C_RST"

raw_conc_thread="concurrency_level5_thread"
anonymize_thread_id "$raw_conc_thread"
conc_hash="$SAFE_THREAD_ID"
conc_ndjson="${BASH4LLM_DIR}/history/threads/${conc_hash}.ndjson"

rm -f "$conc_ndjson" 2>/dev/null || true
export BASH4LLM_SOURCE_ONLY=0
"$TARGET_BIN" --thread "$raw_conc_thread" --init-thread >/dev/null 2>&1 || true

pids=()
for ((i=1; i<=workers; i++)); do
  (
    export BASH4LLM_DIR="${BASH4LLM_DIR}"
    export BASH4LLM_SOURCE_ONLY=1
    . "$TARGET_BIN" >/dev/null 2>&1 || true
    thread_append "$conc_hash" "user" "Concurrent message payload #$i" '{"source":"concurrency_test"}' >/dev/null 2>&1
  ) &
  pids+=($!)
done

for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || true
done

if [ -f "$conc_ndjson" ]; then
  line_cnt="$(wc -l < "$conc_ndjson" | tr -d ' ')"
  valid_json_cnt="$(jq -s 'length' "$conc_ndjson" 2>/dev/null || echo 0)"
  if [ "$line_cnt" -eq "$workers" ] && [ "$valid_json_cnt" -eq "$workers" ]; then rc_conc=0; else rc_conc=1; fi
else
  rc_conc=1
fi

assert_test "$workers parallel process workers atomic NDJSON append lock stress" 0 $rc_conc
rm -f "$conc_ndjson" 2>/dev/null || true

printf '\n%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"
printf ' Level 5 Concurrency Results: %d Passed, %d Failed (Total: %d)\n' "$PASS" "$FAIL" "$TOTAL"
printf '%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
