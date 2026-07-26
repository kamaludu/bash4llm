#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/stress.sh
# Component: Level 6 — Stress Test Suite
# Scope: Long-running / Resource-intensive. Scalability and resource boundaries.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'stress.sh: [FATAL ERROR] Bash 4.0 or superior is required.\n' >&2
    exit 15
  fi
  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'stress.sh: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
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
      printf '\n%s[FAIL-FAST] Halting Level 6 execution on first test failure.%s\n\n' "$C_BRED" "$C_RST" >&2
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
  printf 'stress.sh: [FATAL ERROR] Target executable bash4llm not found.\n' >&2
  exit 15
fi

if [ -n "${ROOT_DIR:-}" ] && [ -w "$ROOT_DIR" ]; then
  TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
else
  TEST_SANDBOX_PARENT="${PWD}/.test_tmp"
fi
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.stress.XXXXXX")"
cleanup_sandbox() { rm -rf "$TEST_SANDBOX" 2>/dev/null || true; rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true; }
trap cleanup_sandbox EXIT INT TERM

export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_stress_key"

mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp"
printf 'llama-3.3-70b-versatile\n' > "${BASH4LLM_DIR}/models/groq.txt"

printf '\n%b[LEVEL 6] Stress Test Suite (Scalability & Resource Boundaries)%b\n' "$C_BCYAN" "$C_RST"

# 1. Base64 Large Payload Staging Stress
large_payload_file="${TEST_SANDBOX}/large_payload.tmp"
awk 'BEGIN { for (i=0; i<15000; i++) print "Stress test line content payload token expansion " i }' > "$large_payload_file"

set +e
(
  export BASH4LLM_DIR="${BASH4LLM_DIR}"
  export BASH4LLM_SOURCE_ONLY=1
  . "$TARGET_BIN" >/dev/null 2>&1 || true
  ensure_run_tmpdir >/dev/null 2>&1 || exit 1
  stage_b64 "$large_payload_file" "${RUN_TMPDIR}/large_staged.b64" >/dev/null 2>&1
)
rc_stage=$?
set -e
assert_test "High-volume base64 payload staging memory handling" 0 $rc_stage

# 2. History Retention Rotation Policy Enforcement
hist_dir="${BASH4LLM_DIR}/history/threads"
mkdir -p "$hist_dir"
for ((i=1; i<=15; i++)); do
  printf '{"ts":"2026-01-01T00:00:00Z","role":"user","content":"stale"}\n' > "${hist_dir}/stale_thread_${i}.ndjson"
done

set +e
(
  export BASH4LLM_DIR="${BASH4LLM_DIR}"
  export BASH4LLM_HISTORY_MAX_FILES=10
  export BASH4LLM_SOURCE_ONLY=1
  . "$TARGET_BIN" >/dev/null 2>&1 || true
  rotate_history 5 >/dev/null 2>&1
)
rc_rot=$?
set -e
remaining_cnt="$(find "$hist_dir" -type f -name "*.ndjson" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$rc_rot" -eq 0 ] && [ "$remaining_cnt" -le 10 ]; then rc_rot_test=0; else rc_rot_test=1; fi
assert_test "History retention rotation policy enforcement" 0 $rc_rot_test

printf '\n%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"
printf ' Level 6 Stress Results: %d Passed, %d Failed (Total: %d)\n' "$PASS" "$FAIL" "$TOTAL"
printf '%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
