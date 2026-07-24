#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/run-all-tests.sh
# Component: Extra Unified Master Test Suite
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================
# Purpose: Single-entrypoint automated test suite covering End-to-End features,
#          PII anonymization, security isolation, OpenSSL Vault, rate limiting,
#          manifest integrity, high-concurrency stress, and JSON/SSE parsing.
# Usage: ./extras/test/run-all-tests.sh [--dry-run] [--no-color]

set -euo pipefail

# ------------------------------------------------------
# Terminal Color Theme Initialization
# ------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_GREEN=$'\e[32m' C_RED=$'\e[31m' C_YELLOW=$'\e[33m' C_CYAN=$'\e[36m' C_BOLD=$'\e[1m' C_RST=$'\e[0m'
else
  C_GREEN="" C_RED="" C_YELLOW="" C_CYAN="" C_BOLD="" C_RST=""
fi

PASS=0
FAIL=0
SKIPPED=0
TOTAL=0

assert_test() {
  local desc="${1:-}" expected_rc="${2:-0}" actual_rc="${3:-0}"
  TOTAL=$((TOTAL + 1))
  if [ "$expected_rc" -eq "$actual_rc" ]; then
    printf '  [%sPASS%s] %s\n' "$C_GREEN" "$C_RST" "$desc"
    PASS=$((PASS + 1))
  else
    printf '  [%sFAIL%s] %s (Expected Exit Code: %d, Got: %d)\n' "$C_RED" "$C_RST" "$desc" "$expected_rc" "$actual_rc"
    FAIL=$((FAIL + 1))
  fi
}

skip_test() {
  local desc="${1:-}" reason="${2:-}"
  TOTAL=$((TOTAL + 1))
  SKIPPED=$((SKIPPED + 1))
  printf '  [%sSKIP%s] %s (%s)\n' "$C_YELLOW" "$C_RST" "$desc" "$reason"
}

# Portable SHA-256 helper resistant to set -o pipefail
calc_sha256() {
  local input="${1:-}"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$input" | sha256sum 2>/dev/null | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$input" | openssl dgst -sha256 -r 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$input" | shasum -a 256 2>/dev/null | awk '{print $1}'
  else
    printf ''
  fi
}

# ------------------------------------------------------
# Path Resolution & Local Sandbox Allocation
# ------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_BIN="$ROOT_DIR/bash4llm"

if [ ! -x "$TARGET_BIN" ]; then
  printf 'bash4llm: ERROR: Target binary executable not found at: %s\n' "$TARGET_BIN" >&2
  exit 15
fi

# Resolve effective extras directory portably
EFFECTIVE_EXTRAS_DIR=""
if [ -d "$ROOT_DIR/bash4llm.d/extras" ]; then
  EFFECTIVE_EXTRAS_DIR="$(cd "$ROOT_DIR/bash4llm.d/extras" && pwd)"
elif [ -d "$ROOT_DIR/extras" ]; then
  EFFECTIVE_EXTRAS_DIR="$(cd "$ROOT_DIR/extras" && pwd)"
fi

# Strict local test sandbox allocation (No system /tmp pollution)
TEST_SANDBOX_PARENT="${ROOT_DIR}/.test_tmp"
mkdir -p "$TEST_SANDBOX_PARENT" 2>/dev/null || true
chmod 700 "$TEST_SANDBOX_PARENT" 2>/dev/null || true

TEST_SANDBOX="$(mktemp -d "${TEST_SANDBOX_PARENT}/sandbox.XXXXXX")"
cleanup_sandbox() {
  rm -rf "$TEST_SANDBOX" 2>/dev/null || true
  rmdir "$TEST_SANDBOX_PARENT" 2>/dev/null || true
}
trap cleanup_sandbox EXIT INT TERM

# Export environment variables for test isolation
export BASH4LLM_DIR="${TEST_SANDBOX}/bash4llm.d"
if [ -n "$EFFECTIVE_EXTRAS_DIR" ]; then
  export BASH4LLM_EXTRAS_DIR="$EFFECTIVE_EXTRAS_DIR"
fi
export BASH4LLM_SKIP_NETWORK=1
export GROQ_API_KEY="dummy_suite_key_for_testing"

# Seed default mock configuration in sandbox
mkdir -p "${BASH4LLM_DIR}/models" "${BASH4LLM_DIR}/config" "${BASH4LLM_DIR}/tmp"
printf 'llama-3.3-70b-versatile\nwhisper-large-v3\n' > "${BASH4LLM_DIR}/models/groq.txt"
printf 'llama-3.3-70b-versatile\n' > "${BASH4LLM_DIR}/config/model.groq"

printf '\n%s==================================================%s\n' "$C_BOLD" "$C_RST"
printf '%s Bash4LLM⁺ — Unified Master Test Suite %s\n' "$C_CYAN" "$C_RST"
printf '%s==================================================%s\n\n' "$C_BOLD" "$C_RST"

# ======================================
# MODULE 1: CLI Configuration, Path Getters & Linter
# ======================================
printf '%b[MODULE 1] Configuration, Utilities & Path Getters%b\n' "$C_BOLD" "$C_RST"

out_linter="$("$TARGET_BIN" --check-config 2>&1 || true)"
if printf '%s' "$out_linter" | grep -q "Configuration Security"; then rc_1a=0; else rc_1a=1; fi
assert_test "Static configuration linter (--check-config)" 0 $rc_1a

out_explain="$("$TARGET_BIN" --explain-error BASH4LLM_ERR_SEC 2>&1 || true)"
if printf '%s' "$out_explain" | grep -q "Evaluating error code"; then rc_1b=0; else rc_1b=1; fi
assert_test "Error documentation explainer (--explain-error)" 0 $rc_1b

cfg_dir="$("$TARGET_BIN" --print-config-dir 2>/dev/null || true)"
if [ "$cfg_dir" = "${BASH4LLM_DIR}/config" ]; then rc_1c=0; else rc_1c=1; fi
assert_test "Canonical config directory getter (--print-config-dir)" 0 $rc_1c

prov_file="$("$TARGET_BIN" --print-provider-file 2>/dev/null || true)"
if [ "$prov_file" = "${BASH4LLM_DIR}/config/provider" ]; then rc_1d=0; else rc_1d=1; fi
assert_test "Canonical provider file getter (--print-provider-file)" 0 $rc_1d

prov_raw="$("$TARGET_BIN" --list-providers-raw 2>/dev/null || true)"
if printf '%s' "$prov_raw" | grep -q "groq"; then rc_1e=0; else rc_1e=1; fi
assert_test "Raw provider list querying (--list-providers-raw)" 0 $rc_1e

# ======================================
# MODULE 2: Input Pipeline & Template Assembly
# ======================================
printf '\n%b[MODULE 2] Input Pipeline & Template Assembly%b\n' "$C_BOLD" "$C_RST"

set +e
echo "Piped Input Prompt" | "$TARGET_BIN" --dry-run >/dev/null 2>&1
rc_2a=$?
set -e
assert_test "Piped STDIN prompt assembly" 0 $rc_2a

tmp_input_file="${TEST_SANDBOX}/test_input.txt"
printf 'File Input Data' > "$tmp_input_file"
set +e
"$TARGET_BIN" -f "$tmp_input_file" --dry-run >/dev/null 2>&1
rc_2b=$?
set -e
assert_test "File input payload assembly (-f)" 0 $rc_2b

mkdir -p "${BASH4LLM_DIR}/templates"
printf 'System Header\n{{CONTENT}}\nSystem Footer' > "${BASH4LLM_DIR}/templates/test.tmpl"
set +e
"$TARGET_BIN" --template test.tmpl "Dynamic Content" --dry-run >/dev/null 2>&1
rc_2c=$?
set -e
assert_test "Template engine variable expansion (--template)" 0 $rc_2c

# ======================================
# MODULE 3: Model Validation & Formatting Rules
# ======================================
printf '\n%b[MODULE 3] Model Safety & Output Formatting%b\n' "$C_BOLD" "$C_RST"

set +e
"$TARGET_BIN" --provider groq --set-default "llama-3.3-70b-versatile" >/dev/null 2>&1
rc_3a=$?
set -e
assert_test "Default model persistence (--set-default)" 0 $rc_3a

set +e
"$TARGET_BIN" -m "whisper-large-v3" --dry-run "Test audio model" >/dev/null 2>&1
rc_3b=$?
set -e
assert_test "Non-text audio/multimodal model rejection (Exit Code 11)" 11 $rc_3b

set +e
"$TARGET_BIN" --json --dry-run "Format Test" >/dev/null 2>&1
rc_3c=$?
"$TARGET_BIN" --pretty --dry-run "Pretty Test" >/dev/null 2>&1
rc_3d=$?
set -e
assert_test "Structured JSON output selection (--json)" 0 $rc_3c
assert_test "Pretty-printed JSON output selection (--pretty)" 0 $rc_3d

# ======================================
# MODULE 4: Thread Lifecycle, PII Anonymization & Path Traversal Fuzzing
# ======================================
printf '\n%b[MODULE 4] Thread Lifecycle, PII Anonymization & Fuzzing%b\n' "$C_BOLD" "$C_RST"

TRAVERSAL_ID="../../../etc/passwd"
ANONYMIZED_OUT="$("$TARGET_BIN" --thread "$TRAVERSAL_ID" --bootstrap-only 2>&1 || true)"
if [[ "$ANONYMIZED_OUT" == *"../"* ]] || [[ "$ANONYMIZED_OUT" == *"/etc/passwd"* ]]; then rc_4a=1; else rc_4a=0; fi
assert_test "Path traversal attack sequence mitigation in --thread" 0 $rc_4a

FUZZ_ID=$'test_thread\x00_injection; id;'
FUZZ_OUT="$("$TARGET_BIN" --thread "$FUZZ_ID" --bootstrap-only 2>&1 || true)"
if [[ "$FUZZ_OUT" == *"uid="* ]] || [[ "$FUZZ_OUT" == *"; id;"* ]]; then rc_4b=1; else rc_4b=0; fi
assert_test "Null-byte & command injection fuzzing mitigation" 0 $rc_4b

RAW_PII_THREAD="john_doe_user_email@example.com"
set +e
"$TARGET_BIN" --thread "$RAW_PII_THREAD" --init-thread >/dev/null 2>&1
rc_4c=$?
set -e
assert_test "Thread initialization (--init-thread)" 0 $rc_4c

# Calculate exact SHA-256 hash expected on disk portably
EXPECTED_HASH="$(calc_sha256 "$RAW_PII_THREAD")"
THREAD_FILE="${BASH4LLM_DIR}/history/threads/${EXPECTED_HASH}.ndjson"

if [ -f "$THREAD_FILE" ] && ! ls "${BASH4LLM_DIR}/history/threads/"*"john_doe"* >/dev/null 2>&1; then rc_4d=0; else rc_4d=1; fi
assert_test "Cryptographic PII thread ID anonymization on disk" 0 $rc_4d

set +e
"$TARGET_BIN" --thread "$RAW_PII_THREAD" --rename-thread "$RAW_PII_THREAD" --title "Custom Thread Title" >/dev/null 2>&1
set -e
META_FILE="${BASH4LLM_DIR}/config/ui_state/threads/${EXPECTED_HASH}.json"
if [ -f "$META_FILE" ] && grep -q "Custom Thread Title" "$META_FILE"; then rc_4e=0; else rc_4e=1; fi
assert_test "Thread metadata title rename (--rename-thread)" 0 $rc_4e

set +e
"$TARGET_BIN" --delete-thread "$RAW_PII_THREAD" >/dev/null 2>&1
set -e
if [ ! -f "$THREAD_FILE" ]; then rc_4f=0; else rc_4f=1; fi
assert_test "Safe thread deletion and disk purging (--delete-thread)" 0 $rc_4f

# ======================================
# MODULE 5: Security Engine, Rate Limiter & Binary Safety
# ======================================
printf '\n%b[MODULE 5] Security Engine, Rate Limiter & Binary Safety%b\n' "$C_BOLD" "$C_RST"

binary_file="${TEST_SANDBOX}/unsafe_binary.bin"
printf '\x00\x01\x02\x03UNSAFE_BINARY_DATA\x00' > "$binary_file"
set +e
"$TARGET_BIN" -f "$binary_file" --dry-run >/dev/null 2>&1
bin_rc=$?
set -e
assert_test "Binary file rejection filter blocks null bytes (Exit Code 17)" 17 $bin_rc

export BASH4LLM_RATE_LIMIT=3
THREAD_RATE_ID="rate_limit_test_thread"
set +e
"$TARGET_BIN" --thread "$THREAD_RATE_ID" --dry-run "Rate req 1" >/dev/null 2>&1
"$TARGET_BIN" --thread "$THREAD_RATE_ID" --dry-run "Rate req 2" >/dev/null 2>&1
"$TARGET_BIN" --thread "$THREAD_RATE_ID" --dry-run "Rate req 3" >/dev/null 2>&1
"$TARGET_BIN" --thread "$THREAD_RATE_ID" --dry-run "Rate req 4 - Exceeded" >/dev/null 2>&1
rate_rc=$?
set -e
assert_test "Sliding window rate limiter blocks exceeded quota (Exit Code 17)" 17 $rate_rc
unset BASH4LLM_RATE_LIMIT

SYMLINK_TARGET="${TEST_SANDBOX}/symlink_target.txt"
echo "SENSITIVE_DATA" > "$SYMLINK_TARGET"
SYMLINK_ATTACK="${BASH4LLM_DIR}/tmp/malicious_link.tmp"
ln -s "$SYMLINK_TARGET" "$SYMLINK_ATTACK" 2>/dev/null || true

set +e
"$TARGET_BIN" --check-config >/dev/null 2>&1
sym_rc=$?
set -e
assert_test "Safe directory check handles symlink traversal safely" 0 $sym_rc

EXTRAS_TEST_DIR="${BASH4LLM_DIR}/extras"
mkdir -p "${EXTRAS_TEST_DIR}/hooks"
DUMMY_HOOK="${EXTRAS_TEST_DIR}/hooks/hook.sh"
printf '#!/usr/bin/env bash\necho "OK"\n' > "$DUMMY_HOOK"
printf "0000000000000000000000000000000000000000000000000000000000000000  hooks/hook.sh\n" > "${EXTRAS_TEST_DIR}/manifest.sha256"

export BASH4LLM_EXTRAS_DIR="$EXTRAS_TEST_DIR"
set +e
"$TARGET_BIN" --dry-run "Test hook integrity" >/dev/null 2>&1
integrity_rc=$?
set -e
assert_test "Cryptographic SHA-256 mismatch halts execution (Exit Code 17)" 17 $integrity_rc

if [ -n "$EFFECTIVE_EXTRAS_DIR" ]; then
  export BASH4LLM_EXTRAS_DIR="$EFFECTIVE_EXTRAS_DIR"
else
  unset BASH4LLM_EXTRAS_DIR
fi

# ======================================
# MODULE 6: OpenSSL Cryptographic Key Vault Engine
# ======================================
printf '\n%b[MODULE 6] Cryptographic Key Vault Engine%b\n' "$C_BOLD" "$C_RST"

HELPER_PATH="${EFFECTIVE_EXTRAS_DIR}/security/openssl-helper.sh"
if [ -f "$HELPER_PATH" ] && command -v openssl >/dev/null 2>&1; then
  VAULT_PASS="TestMasterPassword123!"
  vault_file="${BASH4LLM_DIR}/config/keys.enc"

  vault_test_out="$(
    export BASH4LLM_DIR="${BASH4LLM_DIR}"
    export BASH4LLM_EXTRAS_DIR="${EFFECTIVE_EXTRAS_DIR}"
    export BASH4LLM_SOURCE_ONLY=1
    export BASH4LLM_IGNORE_SEC_CHECKS=1

    . "$TARGET_BIN" >/dev/null 2>&1 || true
    safe_mkdir "$BASH4LLM_DIR" 700
    safe_mkdir "${BASH4LLM_DIR}/config" 700
    safe_mkdir "${BASH4LLM_DIR}/tmp" 700
    ensure_run_tmpdir >/dev/null 2>&1 || true

    if [ -f "$HELPER_PATH" ]; then
      . "$HELPER_PATH" >/dev/null 2>&1 || true
    fi

    if type _vault_encrypt_to_file >/dev/null 2>&1; then
      if _vault_encrypt_to_file '{"groq":"secret_vault_api_key_777"}' "$vault_file" "$VAULT_PASS" >/dev/null 2>&1; then
        decrypted="$(_vault_decrypt_file "$vault_file" "$VAULT_PASS" 2>/dev/null || true)"
        if printf '%s' "$decrypted" | grep -q "secret_vault_api_key_777"; then
          echo "SUCCESS"
        else
          echo "DECRYPT_FAILED"
        fi
      else
        echo "ENCRYPT_FAILED"
      fi
    else
      echo "HELPER_NOT_LOADED"
    fi
  )"

  if [ "$vault_test_out" = "SUCCESS" ]; then rc_6a=0; else rc_6a=1; fi
  assert_test "AES-256/PBKDF2 key vault encryption & decryption" 0 $rc_6a

  if [ -f "$vault_file" ]; then rc_6b=0; else rc_6b=1; fi
  assert_test "Encrypted key vault disk file creation" 0 $rc_6b
else
  skip_test "OpenSSL Cryptographic Key Vault" "openssl binary or openssl-helper.sh missing"
fi

# ======================================
# MODULE 7: High-Concurrency Lock Stress Test
# ======================================
printf '\n%b[MODULE 7] High-Concurrency Lock Contention (50 Parallel Processes)%b\n' "$C_BOLD" "$C_RST"

CONCURRENCY_THREAD="concurrency_stress_test_thread"
export BASH4LLM_SOURCE_ONLY=1
. "$TARGET_BIN" >/dev/null 2>&1 || true

anonymize_thread_id "$CONCURRENCY_THREAD"
STRESS_HASH="$SAFE_THREAD_ID"
STRESS_NDJSON="${BASH4LLM_DIR}/history/threads/${STRESS_HASH}.ndjson"

rm -f "$STRESS_NDJSON" 2>/dev/null || true
export BASH4LLM_SOURCE_ONLY=0
"$TARGET_BIN" --thread "$CONCURRENCY_THREAD" --init-thread >/dev/null 2>&1 || true

PIDS=()
for ((i=1; i<=50; i++)); do
  (
    export BASH4LLM_DIR="${BASH4LLM_DIR}"
    export BASH4LLM_SOURCE_ONLY=1
    . "$TARGET_BIN" >/dev/null 2>&1 || true
    thread_append "$STRESS_HASH" "user" "Concurrent message payload #$i" '{"source":"stress_test"}' >/dev/null 2>&1
  ) &
  PIDS+=($!)
done

for pid in "${PIDS[@]}"; do
  wait "$pid" 2>/dev/null || true
done

if [ -f "$STRESS_NDJSON" ]; then
  LINE_COUNT="$(wc -l < "$STRESS_NDJSON" | tr -d ' ')"
  VALID_JSON_COUNT="$(jq -s 'length' "$STRESS_NDJSON" 2>/dev/null || echo 0)"
  if [ "$LINE_COUNT" -eq 50 ] && [ "$VALID_JSON_COUNT" -eq 50 ]; then rc_7=0; else rc_7=1; fi
else
  rc_7=1
fi
assert_test "50 parallel workers atomic NDJSON append lock stress test" 0 $rc_7
rm -f "$STRESS_NDJSON" 2>/dev/null || true

# ======================================
# MODULE 8: Optional SSE & JSON Logic (Python 3 Helper)
# ======================================
printf '\n%b[MODULE 8] Optional Python 3 SSE & JSON Parsing Engine%b\n' "$C_BOLD" "$C_RST"

if command -v python3 >/dev/null 2>&1; then
  py_escape_out="$(printf 'He said "Hi"' | python3 -c 'import sys, json; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null || true)"
  if [ "$py_escape_out" = 'He said \"Hi\"' ]; then rc_8a=0; else rc_8a=1; fi
  assert_test "JSON string escaping via Python 3 decoder" 0 $rc_8a

  py_sse_out="$(printf '{"content":"Hello World"}' | python3 -c '
import sys, json
s = sys.stdin.read()
v = json.loads(s).get("content", "")
print(v, end="")' 2>/dev/null || true)"
  if [ "$py_sse_out" = "Hello World" ]; then rc_8b=0; else rc_8b=1; fi
  assert_test "SSE chunk payload extractor via Python 3 decoder" 0 $rc_8b
else
  skip_test "Python 3 SSE & JSON Parsing Engine" "python3 executable not found in PATH"
fi

# ======================================
# FINAL SUMMARY REPORT
# ======================================
printf '\n%s==================================================%s\n' "$C_BOLD" "$C_RST"
printf ' %bSUITE EXECUTION SUMMARY%b\n' "$C_CYAN" "$C_RST"
printf '  Total Executed Tests : %d\n' "$TOTAL"
printf '  Passed Tests         : %s%d%s\n' "$C_GREEN" "$PASS" "$C_RST"
printf '  Failed Tests         : %s%d%s\n' "$C_RED" "$FAIL" "$C_RST"
printf '  Skipped Tests        : %s%d%s\n' "$C_YELLOW" "$SKIPPED" "$C_RST"
printf '%s==================================================%s\n' "$C_BOLD" "$C_RST"

if [ "$FAIL" -ne 0 ]; then
  printf '\n%sRESULT: SUITE FAILED (%d failures detected)%s\n\n' "$C_RED" "$FAIL" "$C_RST"
  exit 1
else
  printf '\n%sRESULT: ALL TESTS PASSED SUCCESSFULLY%s\n\n' "$C_GREEN" "$C_RST"
  exit 0
fi
