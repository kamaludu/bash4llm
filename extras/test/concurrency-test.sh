#!/usr/bin/env bash
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the Groq API
# File: extras/test/concurrency-test.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# =============================================================================
# Concurrency test for Bash4LLM
# Usage: extras/test/concurrency-test.sh [path-to-bash4llm] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN]
set -euo pipefail

show_help() {
  cat <<'USAGE' >&2
Usage: concurrency-test.sh [BASH4LLM_BIN] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN]
Defaults: ./bash4llm 10 5 0.05
This script launches concurrent writers and refreshers and performs basic integrity checks.
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

BASH4LLM_BIN="${1:-./bash4llm}"
N_WRITERS="${2:-10}"
N_REFRESHERS="${3:-5}"
SLEEP_BETWEEN="${4:-0.05}"
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

printf 'bash4llm: INFO: Starting concurrency test: writers=%s refreshers=%s sleep=%s\n' "$N_WRITERS" "$N_REFRESHERS" "$SLEEP_BETWEEN" >&2

# Writers: each writes a unique prompt and forces save
writer_pids=()
i=1
while [ "$i" -le "$N_WRITERS" ]; do
  (
    prompt="concurrency-writer-${i}-$(date +%s%N)"
    # Use --text and --save to force history write
    if ! printf '%s\n' "$prompt" | "$BASH4LLM_BIN" --text --save >/dev/null 2>&1; then
      printf 'bash4llm: WARN: writer %s failed\n' "$i" >&2
      exit 1
    fi
  ) &
  writer_pids+=("$!")
  i=$((i+1))
  # sleep may not support fractional seconds on all platforms; try and ignore failure
  sleep "$SLEEP_BETWEEN" 2>/dev/null || sleep 1
done

# Refreshers: run refresh-models in parallel (may require API key)
refresher_pids=()
j=1
while [ "$j" -le "$N_REFRESHERS" ]; do
  (
    if ! "$BASH4LLM_BIN" --refresh-models >/dev/null 2>&1; then
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

# Integrity checks
bad_history=0
base="${BASH4LLM_HISTORY_DIR:-${BASH4LLM_DIR:-./bash4llm.d}}"
HIST_DIR="${base%/}/history"
if [ -d "$HIST_DIR" ]; then
  # count files robustly
  count_total=$(find "$HIST_DIR" -type f -print0 2>/dev/null | tr -cd '\0' | wc -c || echo 0)
  printf 'bash4llm: INFO: history files count: %s\n' "$count_total" >&2
  while IFS= read -r -d '' f; do
    if [ ! -s "$f" ]; then
      printf 'bash4llm: ERROR: empty history file detected: %s\n' "$f" >&2
      bad_history=1
    fi
    # optional: check ownership/perm anomalies (skip if not needed)
  done < <(find "$HIST_DIR" -type f -print0 2>/dev/null || true)
else
  printf 'bash4llm: WARN: history dir not found: %s\n' "$HIST_DIR" >&2
fi

# Models file checks (if present)
bad_models=0
models_base="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-${BASH4LLM_DIR:-./bash4llm.d}}}"
MODELS_FILE_PATH="${models_base%/}/models/models.txt"
if [ -f "$MODELS_FILE_PATH" ]; then
  if [ ! -s "$MODELS_FILE_PATH" ]; then
    printf 'bash4llm: WARN: models file exists but empty: %s\n' "$MODELS_FILE_PATH" >&2
    bad_models=1
  else
    while IFS= read -r line || [ -n "$line" ]; do
      # trim leading/trailing whitespace (POSIX-safe)
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
  printf 'bash4llm: INFO: models file not present (may be normal)\n' >&2
fi

# Final verdict
if [ "$bad_history" -ne 0 ] || [ "$bad_models" -ne 0 ]; then
  printf 'bash4llm: ERROR: concurrency test detected issues (history:%s models:%s)\n' "$bad_history" "$bad_models" >&2
  EXIT_CODE=4
else
  printf 'bash4llm: INFO: concurrency test completed: no obvious corruption detected.\n' >&2
fi

exit "$EXIT_CODE"
