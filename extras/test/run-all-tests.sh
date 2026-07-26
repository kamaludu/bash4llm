#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/run-all-tests.sh
# Component: Master Unified Automated Test Suite & Orchestrator
# Scope: Single entrypoint master test orchestrator.
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

FAIL_FAST=0
TARGET_LEVEL=0 # 0 = Execute all levels (Sanity -> Compatibility -> Regression -> Hardening -> Concurrency -> Stress)
FORWARD_ARGS=()

parse_cli_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
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
      --sanity|--level-1|--level=1)
        TARGET_LEVEL=1
        shift
        ;;
      --compatibility|--level-2|--level=2)
        TARGET_LEVEL=2
        shift
        ;;
      --regression|--level-3|--level=3)
        TARGET_LEVEL=3
        shift
        ;;
      --hardening|--level-4|--level=4)
        TARGET_LEVEL=4
        shift
        ;;
      --concurrency|--level-5|--level=5)
        TARGET_LEVEL=5
        shift
        ;;
      --stress|--level-6|--level=6)
        TARGET_LEVEL=6
        shift
        ;;
      --level)
        if [ $# -gt 1 ] && [[ "$2" =~ ^[1-6]$ ]]; then
          TARGET_LEVEL="$2"
          shift 2
        else
          printf 'run-all-tests: ERROR: --level requires an integer between 1 and 6\n' >&2
          exit 15
        fi
        ;;
      --level=*)
        local lvl="${1#--level=}"
        if [[ "$lvl" =~ ^[1-6]$ ]]; then
          TARGET_LEVEL="$lvl"
          shift
        else
          printf 'run-all-tests: ERROR: --level requires an integer between 1 and 6\n' >&2
          exit 15
        fi
        ;;
      --help|-h)
        printf 'Usage: %s [OPTIONS]\n' "$0"
        printf 'Options:\n'
        printf '  --fail-fast           Halt execution immediately on first test failure\n'
        printf '  --sanity, --level 1   Execute Level 1: Sanity Test Suite (sanity.sh)\n'
        printf '  --compatibility, -2   Execute Level 2: Compatibility Test Suite (compatibility.sh)\n'
        printf '  --regression, -3      Execute Level 3: Regression Test Suite (regression.sh)\n'
        printf '  --hardening, -4       Execute Level 4: Hardening Test Suite (hardening.sh)\n'
        printf '  --concurrency, -5     Execute Level 5: Concurrency Test Suite (concurrency.sh)\n'
        printf '  --stress, -6          Execute Level 6: Stress Test Suite (stress.sh)\n'
        printf '  --no-color            Disable ANSI terminal color output\n'
        printf '  --dry-run             Simulate request flows without external network\n'
        exit 0
        ;;
      *)
        shift
        ;;
    esac
  done
}
parse_cli_args "$@"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

execute_level_script() {
  local level_num="${1:-}"
  local script_name="${2:-}"
  local desc="${3:-}"
  local script_path="${SCRIPT_DIR}/${script_name}"

  printf '\n%s>>> Executing Level %d: %s (%s)%s\n' "$C_BCYAN" "$level_num" "$desc" "$script_name" "$C_RST"

  if [ -f "$script_path" ] && [ -r "$script_path" ]; then
    set +e
    bash "$script_path" ${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}
    local rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
      printf '  [%sLEVEL %d FAILED%s] %s returned exit code %d\n' "$C_BRED" "$level_num" "$C_RST" "$script_name" "$rc"
      if [ "$FAIL_FAST" -eq 1 ]; then
        printf '\n%s[FAIL-FAST HALT] Halting master suite execution due to failure in Level %d.%s\n\n' "$C_BRED" "$level_num" "$C_RST" >&2
        exit 1
      fi
      return 1
    else
      printf '  [%sLEVEL %d PASSED%s] %s completed successfully.\n' "$C_BGREEN" "$level_num" "$C_RST" "$script_name"
      return 0
    fi
  else
    printf '  [%sLEVEL %d ERROR%s] Level script missing: %s\n' "$C_BRED" "$level_num" "$C_RST" "$script_path" >&2
    if [ "$FAIL_FAST" -eq 1 ]; then
      printf '\n%s[FAIL-FAST HALT] Halting execution due to missing Level %d script.%s\n\n' "$C_BRED" "$level_num" "$C_RST" >&2
      exit 1
    fi
    return 1
  fi
}

main() {
  printf '\n%s=======================================================%s\n' "$C_BOLD" "$C_RST"
  printf '%s Bash4LLM⁺ — Master Unified Test Suite (Edition 2026.1) %s\n' "$C_BCYAN" "$C_RST"
  printf '%s Authority: Test Architecture Specification %s\n' "$C_CYAN" "$C_RST"
  printf '%s=======================================================%s\n' "$C_BOLD" "$C_RST"

  local level_failures=0

  if [ "$TARGET_LEVEL" -eq 0 ] || [ "$TARGET_LEVEL" -eq 1 ]; then
    execute_level_script 1 "sanity.sh" "Sanity Check Suite" || level_failures=$((level_failures + 1))
  fi

  if [ "$TARGET_LEVEL" -eq 0 ] || [ "$TARGET_LEVEL" -eq 2 ]; then
    execute_level_script 2 "compatibility.sh" "Public Contract Compatibility Suite" || level_failures=$((level_failures + 1))
  fi

  if [ "$TARGET_LEVEL" -eq 0 ] || [ "$TARGET_LEVEL" -eq 3 ]; then
    execute_level_script 3 "regression.sh" "End-to-End Regression Suite" || level_failures=$((level_failures + 1))
  fi

  if [ "$TARGET_LEVEL" -eq 0 ] || [ "$TARGET_LEVEL" -eq 4 ]; then
    execute_level_script 4 "hardening.sh" "Security Boundaries & Hardening Suite" || level_failures=$((level_failures + 1))
  fi

  if [ "$TARGET_LEVEL" -eq 0 ] || [ "$TARGET_LEVEL" -eq 5 ]; then
    execute_level_script 5 "concurrency.sh" "Process Lock Contention Suite" || level_failures=$((level_failures + 1))
  fi

  if [ "$TARGET_LEVEL" -eq 0 ] || [ "$TARGET_LEVEL" -eq 6 ]; then
    execute_level_script 6 "stress.sh" "Scalability & Resource Stress Suite" || level_failures=$((level_failures + 1))
  fi

  printf '\n%s-------------------------------------------------------%s\n' "$C_BOLD" "$C_RST"
  if [ "$level_failures" -eq 0 ]; then
    printf ' %sRESULT: ALL VERIFICATION LEVELS PASSED SUCCESSFULLY%s\n' "$C_BGREEN" "$C_RST"
    printf '%s=======================================================%s\n\n' "$C_BOLD" "$C_RST"
    exit 0
  else
    printf ' %sRESULT: SUITE FAILED (%d level failures detected)%s\n' "$C_BRED" "$level_failures" "$C_RST"
    printf '%s=======================================================%s\n\n' "$C_BOLD" "$C_RST"
    exit 1
  fi
}

main "$@"
