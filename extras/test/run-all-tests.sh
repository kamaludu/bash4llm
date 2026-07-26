#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/run-all-tests.sh
# Component: Master Unified Automated Test Suite & Orchestrator
# Scope: Single entrypoint master test orchestrator.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================

set -euo pipefail

# [TST-4] Fail-Fast Host Dependency Verification
verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'run-all-tests: [FATAL ERROR] Bash 4.0 or superior is required.\n' >&2
    exit 15
  fi

  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'run-all-tests: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
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
    C_RST=$'\e[0m' C_BOLD=$'\e[1m' C_GREEN=$'\e[0;32m' C_RED=$'\e[0;31m' C_YELLOW=$'\e[0;33m' C_CYAN=$'\e[0;36m'
    C_BGREEN=$'\e[1;32m' C_BRED=$'\e[1;31m' C_BYELLOW=$'\e[1;33m' C_BCYAN=$'\e[1;36m'
  else
    C_RST="" C_BOLD="" C_GREEN="" C_RED="" C_YELLOW="" C_CYAN="" C_BGREEN="" C_BRED="" C_BYELLOW="" C_BCYAN=""
  fi
}
init_colors

# Architectural Constants & Canonical Suite Map
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRAS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST_FILE="${EXTRAS_DIR}/manifest.sha256"

declare -A CANONICAL_SUITES=(
  ["sanity"]="Level 1 — Sanity Test Suite|sanity.sh|1"
  ["compatibility"]="Level 2 — Compatibility Test Suite|compatibility.sh|2"
  ["regression"]="Level 3 — Regression Test Suite|regression.sh|3"
  ["hardening"]="Level 4 — Hardening Test Suite|hardening.sh|4"
  ["concurrency"]="Level 5 — Concurrency Test Suite|concurrency.sh|5"
  ["stress"]="Level 6 — Stress Test Suite|stress.sh|6"
)

# Ordered list of canonical level names for full pipeline execution
CANONICAL_ORDER=("sanity" "compatibility" "regression" "hardening" "concurrency" "stress")

FAIL_FAST=0
FORWARD_ARGS=()
REQUESTED_SUITES=()

display_help() {
  local help_file="${SCRIPT_DIR}/help-test.txt"
  if [ -f "$help_file" ] && [ -r "$help_file" ]; then
    if [ -z "${C_BCYAN:-}" ]; then
      cat "$help_file"
    else
      sed \
        -e "s/^\([A-Za-z][A-Za-z[:blank:]&]*:\)/${C_BCYAN}\1${C_RST}/" \
        -e "s/\(--[a-zA-Z0-9-][a-zA-Z0-9-]*\)/${C_BGREEN}\1${C_RST}/g" \
        "$help_file"
    fi
  else
    printf 'run-all-tests: Help manual file missing at: %s\n' "$help_file" >&2
  fi
  exit 0
}

# Parse CLI options and positional commands/suite selections
parse_cli_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      help|-h|--help)
        display_help
        ;;
      list)
        printf '%bAuthorized Canonical Test Suites:%b\n' "$C_BCYAN" "$C_RST"
        for suite in "${CANONICAL_ORDER[@]}"; do
          IFS='|' read -r desc file_name level_num <<< "${CANONICAL_SUITES[$suite]}"
          printf '  • %b%-15s%b (%s)\n' "$C_BGREEN" "$suite" "$C_RST" "$desc"
        done
        exit 0
        ;;
      all)
        REQUESTED_SUITES=("${CANONICAL_ORDER[@]}")
        shift
        ;;
      --fail-fast)
        FAIL_FAST=1
        FORWARD_ARGS+=("--fail-fast")
        shift
        ;;
      --no-color)
        export NO_COLOR=1
        init_colors
        FORWARD_ARGS+=("--no-color")
        shift
        ;;
      --dry-run)
        FORWARD_ARGS+=("--dry-run")
        shift
        ;;
      -*)
        printf 'run-all-tests: ERROR: Unknown option %s\n' "$1" >&2
        printf 'Use "bash4llm --test help" for usage details.\n' >&2
        exit 15
        ;;
      *)
        # Positional suite name matching canonical suites
        if [ -n "${CANONICAL_SUITES[$1]:-}" ]; then
          REQUESTED_SUITES+=("$1")
        else
          printf 'run-all-tests: ERROR: Unrecognized canonical test suite: %s\n' "$1" >&2
          printf 'Use "bash4llm --test list" to view available suites.\n' >&2
          exit 15
        fi
        shift
        ;;
    esac
  done

  # Default to executing all canonical suites if none explicitly selected
  if [ "${#REQUESTED_SUITES[@]}" -eq 0 ]; then
    REQUESTED_SUITES=("${CANONICAL_ORDER[@]}")
  fi
}
parse_cli_args "$@"

# [INV-4] Module Integrity Verification Helper
verify_module_integrity_local() {
  local target_file="${1:-}"
  local rel_path="" expected_hash="" actual_hash=""

  [ -f "$target_file" ] || return 1
  [ -f "$MANIFEST_FILE" ] || return 1

  rel_path="test/$(basename "$target_file")"
  expected_hash="$(awk -v rel="$rel_path" '{sub(/\r$/,""); if ($2 == rel) {print $1; exit}}' "$MANIFEST_FILE" 2>/dev/null || true)"

  if [ -z "$expected_hash" ]; then
    printf 'run-all-tests: [SECURITY ERROR] Suite %s not registered in manifest.sha256!\n' "$rel_path" >&2
    return 17
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    actual_hash="$(sha256sum "$target_file" 2>/dev/null | awk '{print $1}')"
  elif command -v openssl >/dev/null 2>&1; then
    actual_hash="$(openssl dgst -sha256 -r "$target_file" 2>/dev/null | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual_hash="$(shasum -a 256 "$target_file" 2>/dev/null | awk '{print $1}')"
  fi

  if [ "$expected_hash" != "$actual_hash" ]; then
    printf 'run-all-tests: [SECURITY ERROR] Integrity mismatch for %s!\n' "$rel_path" >&2
    return 17
  fi

  return 0
}

# [TST-7] Set Intersection Verification & Level Execution Dispatcher
execute_canonical_suite() {
  local suite_key="${1:-}"
  if [ -z "${CANONICAL_SUITES[$suite_key]:-}" ]; then
    return 1
  fi

  IFS='|' read -r desc file_name level_num <<< "${CANONICAL_SUITES[$suite_key]}"
  local script_path="${SCRIPT_DIR}/${file_name}"

  printf '\n%s>>> Executing %s (%s)%s\n' "$C_BCYAN" "$desc" "$file_name" "$C_RST"

  # 1. Physical File Existence Check
  if [ ! -f "$script_path" ] || [ ! -r "$script_path" ]; then
    printf '  [%sERROR%s] Missing executable script for canonical suite: %s\n' "$C_BRED" "$C_RST" "$script_path" >&2
    if [ "$FAIL_FAST" -eq 1 ]; then exit 1; fi
    return 1
  fi

  # 2. Manifest Whitelist & SHA-256 Integrity Verification (Set Intersection Model)
  if ! verify_module_integrity_local "$script_path"; then
    printf '  [%sSECURITY ERROR%s] Suite %s failed integrity check! (Exit Code 17)\n' "$C_BRED" "$C_RST" "$file_name" >&2
    if [ "$FAIL_FAST" -eq 1 ]; then exit 17; fi
    return 17
  fi

  # 3. Execution
  set +e
  bash "$script_path" ${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}
  local rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    printf '  [%sLEVEL %s FAILED%s] %s returned exit code %d\n' "$C_BRED" "$level_num" "$C_RST" "$file_name" "$rc"
    if [ "$FAIL_FAST" -eq 1 ]; then
      printf '\n%s[FAIL-FAST HALT] Halting execution due to failure in %s.%s\n\n' "$C_BRED" "$suite_key" "$C_RST" >&2
      exit 1
    fi
    return 1
  else
    printf '  [%sLEVEL %s PASSED%s] %s completed successfully.\n' "$C_BGREEN" "$level_num" "$C_RST" "$file_name"
    return 0
  fi
}

main() {
  printf '\n%s========================================%s\n' "$C_BOLD" "$C_RST"
  printf '%s Bash4LLM⁺ — Master Unified Test Suite (Edition 2026.1) %s\n' "$C_BCYAN" "$C_RST"
  printf '%s========================================%s\n' "$C_BOLD" "$C_RST"

  local level_failures=0
  local executed_count=0

  for suite_key in "${REQUESTED_SUITES[@]}"; do
    executed_count=$((executed_count + 1))
    execute_canonical_suite "$suite_key" || level_failures=$((level_failures + 1))
  done

  printf '\n%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"
  if [ "$level_failures" -eq 0 ]; then
    printf ' %sRESULT: ALL %d EXECUTED TEST SUITES PASSED SUCCESSFULLY%s\n' "$C_BGREEN" "$executed_count" "$C_RST"
    printf '%s========================================%s\n\n' "$C_BOLD" "$C_RST"
    exit 0
  else
    printf ' %sRESULT: SUITE FAILED (%d failures detected among %d suites)%s\n' "$C_BRED" "$level_failures" "$executed_count" "$C_RST"
    printf '%s========================================%s\n\n' "$C_BOLD" "$C_RST"
    exit 1
  fi
}

main "$@"
