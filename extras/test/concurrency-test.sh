#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/test/concurrency-test.sh
# Extra: Concurrency test
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Concurrency test for Bash4LLM⁺ (v2.5.0 aligned)
# Usage: extras/test/concurrency-test.sh [path-to-bash4llm] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN] [--dry-run]
set -euo pipefail

show_help() {
  cat <<'USAGE' >&2
Usage: concurrency-test.sh [BASH4LLM_BIN] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN] [--dry-run]
Defaults: ./bash4llm 10 5 0.05
This script launches concurrent writers and refreshers and performs basic integrity checks.
Adding the --dry-run option executes the concurrent writers in simulation mode (recommended offline).
Exit codes:
  0  success (no obvious corruption)
  2  bash4llm binary not found / not executable
  3  one or more writers failed
  4  integrity checks detected issues
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  show_help
  exit 0
fi

# Robust position-independent argument parsing
BASH4LLM_BIN="./bash4llm"
N_WRITERS="10"
N_REFRESHERS="5"
SLEEP_BETWEEN="0.05"
DRY_RUN_ARG=""

positional_args=()
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN_ARG="--dry-run"
  else
    positional_args+=("$arg")
  fi
done

if [ "${#positional_args[@]}" -ge 1 ]; then
  BASH4LLM_BIN="${positional_args[0]}"
fi
if [ "${#positional_args[@]}" -ge 2 ]; then
  N_WRITERS="${positional_args[1]}"
fi
if [ "${#positional_args[@]}" -ge 3 ]; then
  N_REFRESHERS="${positional_args[2]}"
fi
if [ "${#positional_args[@]}" -ge 4 ]; then
  SLEEP_BETWEEN="${positional_args[3]}"
fi

TMPTEST_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" bash4llm-test.XXXX)"
EXIT_CODE=0

cleanup() {
  rm -rf -- "$TMPTEST_DIR" || true
}

trap 'rc=$?; cleanup; exit $rc' EXIT

if [ ! -x "$BASH4LLM_BIN" ]; then
  printf 'bash4llm: ERROR: binary not found or not executable: %s\n' "$BASH4LLM_BIN" >&2
  exit 2
fi

printf 'bash4llm: INFO: Starting concurrency test: writers=%s refreshers=%s sleep=%s (dry-run:%s)\n' \
  "$N_WRITERS" "$N_REFRESHERS" "$SLEEP_BETWEEN" "${DRY_RUN_ARG:-false}" >&2

# Writers: each writes a unique prompt and forces save
writer_pids=()
i=1
while [ "$i" -le "$N_WRITERS" ]; do
  (
    prompt="concurrency-writer-${i}-$(date +%s%N)"
    # Use --text and --save to force history write, append dry-run if specified
    if ! printf '%s\n' "$prompt" | "$BASH4LLM_BIN" --text --save ${DRY_RUN_ARG} >/dev/null 2>&1; then
      printf 'bash4llm: WARN: writer %s failed\n' "$i" >&2
      exit 1
    fi
  ) &
  writer_pids+=("$!")
  i=$((i+1))
  sleep "$SLEEP_BETWEEN" 2>/dev/null || sleep 1
done

# Refreshers: run refresh-models in parallel (may require API key or dry-run)
refresher_pids=()
j=1
while [ "$j" -le "$N_REFRESHERS" ]; do
  (
    # Refresh models, append dry-run context if requested
    if ! "$BASH4LLM_BIN" --refresh-models ${DRY_RUN_ARG} >/dev/null 2>&1; then
      printf 'bash4llm: INFO: refresher %s exited non-zero (may be expected without API key)\n' "$j" >&2
      exit 0
    fi
  ) &
  refresher_pids+=("$!")
  j=$((j+1))
  sleep "$SLEEP_BETWEEN" 2>/dev/null || sleep 1
done

# Wait for writers
for pid in "${writer_pids[@]}"; do
  if ! wait "$pid"; then
    printf 'bash4llm: WARN: writer pid %s exited non-zero\n' "$pid" >&2
    EXIT_CODE=3
  fi
done

# Wait for refreshers
for pid in "${refresher_pids[@]}"; do
  if ! wait "$pid"; then
    printf 'bash4llm: INFO: refresher pid %s exited non-zero (may be expected)\n' "$pid" >&2
  fi
done

# Integrity checks on History files
bad_history=0
HIST_DIR="${BASH4LLM_HISTORY_DIR:-${BASH4LLM_DIR:-./bash4llm.d}/history}"
if [ -d "$HIST_DIR" ]; then
  count_total=$(find "$HIST_DIR" -type f -print0 2>/dev/null | tr -cd '\0' | wc -c || echo 0)
  printf 'bash4llm: INFO: history files count: %s\n' "$count_total" >&2
  while IFS= read -r -d '' f; do
    if [ ! -s "$f" ]; then
      printf 'bash4llm: ERROR: empty history file detected: %s\n' "$f" >&2
      bad_history=1
    fi
  done < <(find "$HIST_DIR" -type f -print0 2>/dev/null || true)
else
  printf 'bash4llm: WARN: history dir not found: %s\n' "$HIST_DIR" >&2
fi

# MODELS_FILE check (aligned with provider-specific naming of v2.5.0)
bad_models=0
PROVIDER_NAME="${PROVIDER:-groq}"
MODELS_FILE_PATH="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-${BASH4LLM_DIR:-./bash4llm.d}/models}/${PROVIDER_NAME}.txt}"
if [ -f "$MODELS_FILE_PATH" ]; then
  if [ ! -s "$MODELS_FILE_PATH" ]; then
    printf 'bash4llm: WARN: models file exists but empty: %s\n' "$MODELS_FILE_PATH" >&2
    bad_models=1
  else
    while IFS= read -r line || [ -n "$line" ]; do
      line_trimmed="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      if [ -n "$line_trimmed" ]; then
        if ! printf '%s\n' "$line_trimmed" | grep -qE '^[[:alnum:]._:-]+$'; then
          printf 'bash4llm: ERROR: invalid model id in models file: %s\n' "$line_trimmed" >&2
          bad_models=1
        fi
      fi
    done < "$MODELS_FILE_PATH"
  fi
else
  printf 'bash4llm: INFO: models file not present: %s (may be normal)\n' "$MODELS_FILE_PATH" >&2
fi

# Final verdict
if [ "$bad_history" -ne 0 ] || [ "$bad_models" -ne 0 ]; then
  printf 'bash4llm: ERROR: concurrency test detected issues (history:%s models:%s)\n' "$bad_history" "$bad_models" >&2
  EXIT_CODE=4
else
  printf 'bash4llm: INFO: concurrency test completed: no obvious corruption detected.\n' >&2
fi

exit "$EXIT_CODE"
