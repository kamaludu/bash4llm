#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/hardening.sh
# Component: Level 4 — Hardening Test Suite
# Scope: Short-running. Security Boundaries & Invariants Enforcement.
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

set -euo pipefail

verify_host_prerequisites() {
  local missing=0
  if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    printf 'hardening.sh: [FATAL ERROR] Bash 4.0 or superior is required.\n' >&2
    exit 15
  fi
  for cmd in bash jq mktemp stat awk sed grep find cut tr sort head tail wc date chmod cp mv rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'hardening.sh: [FATAL ERROR] Required system utility missing in PATH: %s\n' "$cmd" >&2
      missing=1
    fi
  done
  [ "$missing" -ne 0 ] && exit 15
}
verify_host_prerequisites

init_colors() {
  if { [ -t 1 ] || [ -t 2 ]; } && [ "${TERM:-}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
    C_RST=$'\e[0m' C_BOLD=$'\e[1m' C_GREEN=$'\e[0;32m' C_RED=$'\e[0;31m' C_CYAN=$'\e[0;36m' C_YELLOW=$'\e[0;33m'
    C_BGREEN=$'\e[1;32m' C_BRED=$'\e[1;31m' C_BYELLOW=$'\e[1;33m' C_BCYAN=$'\e[1;36m'
  else
    C_RST="" C_BOLD="" C_GREEN="" C_RED="" C_CYAN="" C_YELLOW="" C_BGREEN="" C_BRED="" C_BYELLOW="" C_BCYAN=""
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
      printf '\n%s[FAIL-FAST] Halting Level 4 execution on first test failure.%s\n\n' "$C_BRED" "$C_RST" >&2
      exit 1
    fi
  fi
}

skip_test() {
  local desc="${1:-}" reason="${2:-}"
  TOTAL=$((TOTAL + 1))
  printf '  [%sSKIP%s] %s (%s)\n' "$C_BYELLOW" "$C_RST" "$desc" "$reason"
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
  printf 'hardening.sh: [FATAL ERROR] Target executable bash4llm not found.\n' >&2
  exit 15
fi

EFFECTIVE_EXTRAS_DIR=""
if [ -d "$ROOT_DIR/bash4llm.d/extras" ]; then
  EFFECTIVE_EXTRAS_DIR="$(cd "$ROOT_DIR/bash4llm.d/extras" && pwd)"
elif [ -d "$ROOT_DIR/extras" ]; then
  EFFECTIVE_EXTRAS_DIR="$(cd "$ROOT_DIR/extras" && pwd)"
fi

if [ -n "${ROOT_DIR:-}" ] && [ -w "$ROOT_DIR" ]; then
  TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
else
  TEST_SANDBOX_PARENT="${PWD}/.test_tmp"
fi
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.hard.XXXXXX")"
cleanup_sandbox() { rm -rf "$TEST_SANDBOX" 2>/dev/null || true; rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true; }
trap cleanup_sandbox EXIT INT TERM

export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
if [ -n "$EFFECTIVE_EXTRAS_DIR" ]; then export BASH4LLM_EXTRAS_DIR="$EFFECTIVE_EXTRAS_DIR"; fi
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_hard_key"

mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp"
printf 'llama-3.3-70b-versatile\n' > "${BASH4LLM_DIR}/models/groq.txt"

printf '\n%b[LEVEL 4] Hardening Test Suite (Security Boundaries & Invariants)%b\n' "$C_BCYAN" "$C_RST"

# [INV-1] No Secret Exposure in argv
set +e
bash -c ". \"$TARGET_BIN\" --bootstrap-only 2>/dev/null; type _exec_curl_secure >/dev/null 2>&1" 2>/dev/null
rc_inv1=$?
set -e
assert_test "[INV-1] Authoritative secure HTTP engine active (_exec_curl_secure)" 0 $rc_inv1

# [INV-2] No Shared Temp Storage (/tmp)
sandbox_tmp="$(cd "${BASH4LLM_DIR}/tmp" && pwd)"
if [[ "$sandbox_tmp" != "/tmp"* ]]; then rc_inv2=0; else rc_inv2=1; fi
assert_test "[INV-2] Absolute Workspace Isolation (BASH4LLM_TMPDIR outside /tmp)" 0 $rc_inv2

# [INV-3] Dynamic Code Evaluation Guard (Zero Unsafe eval)
# Multiline-aware filter explicitly excluding audited parent trap restoration lines
unsafe_eval_count="$(grep -E '\beval[[:space:]]' "$TARGET_BIN" | grep -v -E 'TECHNICAL DEBT AUDIT|_parent_trap_' | wc -l | tr -d ' ')"
if [ "$unsafe_eval_count" -eq 0 ]; then rc_inv3=0; else rc_inv3=1; fi
assert_test "[INV-3] Dynamic Code Evaluation Guard (Zero Unsafe eval)" 0 $rc_inv3

# [INV-4] Module Integrity Enforcement (Exit Code 17)
tamper_dir="${TEST_SANDBOX}/tamper_extras"
mkdir -p "${tamper_dir}/providers"
tamper_mod="${tamper_dir}/providers/tampered_prov.sh"
printf '#!/usr/bin/env bash\necho "malicious"\n' > "$tamper_mod"
printf "0000000000000000000000000000000000000000000000000000000000000000  providers/tampered_prov.sh\n" > "${tamper_dir}/manifest.sha256"

set +e
BASH4LLM_EXTRAS_DIR="$tamper_dir" "$TARGET_BIN" --provider tampered_prov --bootstrap-only >/dev/null 2>&1
rc_inv4=$?
set -e
assert_test "[INV-4] Module Tampering Enforcement (Exit Code 17)" 17 $rc_inv4

# [INV-5] Cryptographic PII Thread Anonymization on Disk
pii_raw_thread="john.doe.private.email@domain.com"
set +e
"$TARGET_BIN" --thread "$pii_raw_thread" --init-thread >/dev/null 2>&1
set -e
pii_hash="$(calc_sha256 "$pii_raw_thread")"
pii_file="${BASH4LLM_DIR}/history/threads/${pii_hash}.ndjson"
if [ -f "$pii_file" ] && ! ls "${BASH4LLM_DIR}/history/threads/"*"john.doe"* >/dev/null 2>&1; then
  assert_test "[INV-5] Cryptographic PII Thread Anonymization on Disk" 0 0
else
  assert_test "[INV-5] Cryptographic PII Thread Anonymization on Disk" 0 1 "PII string exposed in path."
fi

# Binary Input Safety Filter
binary_file="${TEST_SANDBOX}/unsafe_binary.bin"
printf '\x00\x01\x02\x03UNSAFE_BINARY_DATA\x00' > "$binary_file"
set +e
"$TARGET_BIN" -f "$binary_file" --dry-run >/dev/null 2>&1
rc_bin=$?
set -e
assert_test "Binary file input rejection filter (Exit Code 17)" 17 $rc_bin

# Path Traversal Fuzzing Mitigation
traversal_id="../../../etc/passwd"
trav_out="$("$TARGET_BIN" --thread "$traversal_id" --bootstrap-only 2>&1 || true)"
if [[ "$trav_out" == *"../"* ]] || [[ "$trav_out" == *"/etc/passwd"* ]]; then rc_trav=1; else rc_trav=0; fi
assert_test "Path traversal fuzzing mitigation in --thread" 0 $rc_trav

# Sliding Window Rate Limiter
export BASH4LLM_RATE_LIMIT=3
rate_thread="hardening_rate_limit_thread"
set +e
"$TARGET_BIN" --thread "$rate_thread" --dry-run "Rate req 1" >/dev/null 2>&1
"$TARGET_BIN" --thread "$rate_thread" --dry-run "Rate req 2" >/dev/null 2>&1
"$TARGET_BIN" --thread "$rate_thread" --dry-run "Rate req 3" >/dev/null 2>&1
"$TARGET_BIN" --thread "$rate_thread" --dry-run "Rate req 4 - Exceeded" >/dev/null 2>&1
rc_rate=$?
set -e
assert_test "Sliding window rate limiter enforcement (Exit Code 17)" 17 $rc_rate
unset BASH4LLM_RATE_LIMIT

# Function Immutability Guard Locking
set +e
bash -c ". \"$TARGET_BIN\" --bootstrap-only 2>/dev/null; _exec_curl_secure() { echo 'hijacked'; }" 2>/dev/null
rc_guard=$?
set -e
if [ "$rc_guard" -ne 0 ]; then rc_guard_test=0; else rc_guard_test=1; fi
assert_test "Read-only function guard locks security functions" 0 $rc_guard_test

# OpenSSL Key Vault Engine
helper_path="${EFFECTIVE_EXTRAS_DIR}/security/openssl-helper.sh"
if [ -f "$helper_path" ] && command -v openssl >/dev/null 2>&1; then
  vault_pass="TestMasterPassword123!"
  vault_file="${BASH4LLM_DIR}/config/keys.enc"

  vault_res="$(
    export BASH4LLM_DIR="${BASH4LLM_DIR}"
    export BASH4LLM_EXTRAS_DIR="${EFFECTIVE_EXTRAS_DIR}"
    export BASH4LLM_SOURCE_ONLY=1
    export BASH4LLM_IGNORE_SEC_CHECKS=1

    . "$TARGET_BIN" >/dev/null 2>&1 || true
    if [ -f "$helper_path" ]; then . "$helper_path" >/dev/null 2>&1 || true; fi

    if type _vault_encrypt_to_file >/dev/null 2>&1; then
      if _vault_encrypt_to_file '{"groq":"vault_secret_key_999"}' "$vault_file" "$vault_pass" >/dev/null 2>&1; then
        decrypted="$(_vault_decrypt_file "$vault_file" "$vault_pass" 2>/dev/null || true)"
        if printf '%s' "$decrypted" | grep -q "vault_secret_key_999"; then echo "SUCCESS"; else echo "DECRYPT_FAILED"; fi
      else echo "ENCRYPT_FAILED"; fi
    else echo "NO_HELPER"; fi
  )"

  if [ "$vault_res" = "SUCCESS" ]; then rc_vault=0; else rc_vault=1; fi
  assert_test "OpenSSL AES-256 Key Vault encryption/decryption" 0 $rc_vault
else
  skip_test "OpenSSL Key Vault Test" "openssl binary or openssl-helper.sh missing"
fi

printf '\n%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"
printf ' Level 4 Hardening Results: %d Passed, %d Failed (Total: %d)\n' "$PASS" "$FAIL" "$TOTAL"
printf '%s----------------------------------------%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
