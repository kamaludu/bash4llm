#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/sanity.sh
# Component: Level 1 — Sanity Test Suite
# Scope: Interactive / Fast. Rapid black-box system vitality check.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

# [TST-4] Fail-Fast Host Dependency Verification
verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'sanity.sh: [FATAL ERROR] Bash 4.0 or superior is required to run tests.\n' >&2
    exit 15
  fi

  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'sanity.sh: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
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
      printf '\n%s[FAIL-FAST] Halting Level 1 execution on first test failure.%s\n\n' "$C_BRED" "$C_RST" >&2
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
  printf 'sanity.sh: [FATAL ERROR] Target executable bash4llm not found or not executable.\n' >&2
  exit 15
fi

# [TST-1] Absolute Workspace Isolation with Write Permission Fallback
if [ -n "${ROOT_DIR:-}" ] && [ -w "$ROOT_DIR" ]; then
  TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
else
  TEST_SANDBOX_PARENT="${PWD}/.test_tmp"
fi
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.sanity.XXXXXX")"
cleanup_sandbox() { rm -rf "$TEST_SANDBOX" 2>/dev/null || true; rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true; }
trap cleanup_sandbox EXIT INT TERM

export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_sanity_key"

mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp"
printf 'llama-3.3-70b-versatile\n' > "${BASH4LLM_DIR}/models/groq.txt"

printf '\n%b[LEVEL 1] Sanity Test Suite (Immediate System Vitality)%b\n' "$C_BCYAN" "$C_RST"

set +e
"$TARGET_BIN" --version >/dev/null 2>&1
rc_ver=$?
set -e
assert_test "Core CLI bootstrap and --version flag" 0 $rc_ver "Verify executable path and syntax."

set +e
"$TARGET_BIN" --help >/dev/null 2>&1
rc_help=$?
set -e
assert_test "Help documentation flag (--help)" 0 $rc_help "Check help file in extras/docs/help.txt."

cfg_dir="$("$TARGET_BIN" --print-config-dir 2>/dev/null || true)"
rc_cfg=1
[ "$cfg_dir" = "${BASH4LLM_DIR}/config" ] && rc_cfg=0
assert_test "Canonical config directory getter (--print-config-dir)" 0 $rc_cfg "Check BASH4LLM_DIR environment override."

prov_raw="$("$TARGET_BIN" --list-providers-raw 2>/dev/null || true)"
rc_prov=1
printf '%s' "$prov_raw" | grep -q "groq" && rc_prov=0
assert_test "Provider discoverability (--list-providers-raw)" 0 $rc_prov "Check provider discovery engine."

set +e
"$TARGET_BIN" --check-config >/dev/null 2>&1
rc_lint=$?
set -e
assert_test "Static configuration security linter (--check-config)" 0 $rc_lint "Check static config parser."

printf '\n%s-----------------------------------------%s\n' "$C_BOLD" "$C_RST"
printf ' Level 1 Sanity Results: %d Passed, %d Failed (Total: %d)\n' "$PASS" "$FAIL" "$TOTAL"
printf '%s-----------------------------------------%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
