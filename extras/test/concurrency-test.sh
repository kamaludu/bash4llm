#!/usr/bin/env bash
# =============================================================================
# GroqBash⁺ — Bash-first wrapper for the Groq API
# File: extras/test/concurrency-test.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# =============================================================================
# Concurrency test for GroqBash
# Usage: extras/test/concurrency-test.sh [path-to-groqbash] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN]
set -euo pipefail

show_help() {
  cat <<'USAGE' >&2
Usage: concurrency-test.sh [GROQBASH_BIN] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN]
Defaults: ./groqbash 10 5 0.05
This script launches concurrent writers and refreshers and performs basic integrity checks.
Exit codes:
  0  success (no obvious corruption)
  2  groqbash binary not found / not executable
  3  one or more writers failed
  4  integrity checks detected issues
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  show_help
  exit 0
fi

GROQBASH_BIN="${1:-./groqbash}"
N_WRITERS="${2:-10}"
N_REFRESHERS="${3:-5}"
SLEEP_BETWEEN="${4:-0.05}"
TMPTEST_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" groqbash-test.XXXX)"
EXIT_CODE=0

cleanup() {
  rm -rf -- "$TMPTEST_DIR" || true
}

trap 'rc=$?; cleanup; exit $rc' EXIT

if [ ! -x "$GROQBASH_BIN" ]; then
  printf 'groqbash: ERROR: binary not found or not executable: %s\n' "$GROQBASH_BIN" >&2
  exit 2
fi

printf 'groqbash: INFO: Starting concurrency test: writers=%s refreshers=%s sleep=%s\n' "$N_WRITERS" "$N_REFRESHERS" "$SLEEP_BETWEEN" >&2

# Writers: each writes a unique prompt and forces save
writer_pids=()
i=1
while [ "$i" -le "$N_WRITERS" ]; do
  (
    prompt="concurrency-writer-${i}-$(date +%s%N)"
    # Use --text and --save to force history write
    if ! printf '%s\n' "$prompt" | "$GROQBASH_BIN" --text --save >/dev/null 2>&1; then
      printf 'groqbash: WARN: writer %s failed\n' "$i" >&2
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
    if ! "$GROQBASH_BIN" --refresh-models >/dev/null 2>&1; then
      printf 'groqbash: INFO: refresher %s exited non-zero (may be expected without API key)\n' "$j" >&2
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
    printf 'groqbash: WARN: writer pid %s exited non-zero\n' "$pid" >&2
    EXIT_CODE=3
  fi
done

# Wait for refreshers
for pid in "${refresher_pids[@]}"; do
  if ! wait "$pid"; then
    printf 'groqbash: INFO: refresher pid %s exited non-zero (may be expected)\n' "$pid" >&2
  fi
done

# Integrity checks
bad_history=0
base="${GROQBASH_HISTORY_DIR:-${GROQBASH_DIR:-./groqbash.d}}"
HIST_DIR="${base%/}/history"
if [ -d "$HIST_DIR" ]; then
  # count files robustly
  count_total=$(find "$HIST_DIR" -type f -print0 2>/dev/null | tr -cd '\0' | wc -c || echo 0)
  printf 'groqbash: INFO: history files count: %s\n' "$count_total" >&2
  while IFS= read -r -d '' f; do
    if [ ! -s "$f" ]; then
      printf 'groqbash: ERROR: empty history file detected: %s\n' "$f" >&2
      bad_history=1
    fi
    # optional: check ownership/perm anomalies (skip if not needed)
  done < <(find "$HIST_DIR" -type f -print0 2>/dev/null || true)
else
  printf 'groqbash: WARN: history dir not found: %s\n' "$HIST_DIR" >&2
fi

# Models file checks (if present)
bad_models=0
models_base="${MODELS_FILE:-${GROQBASH_MODELS_DIR:-${GROQBASH_DIR:-./groqbash.d}}}"
MODELS_FILE_PATH="${models_base%/}/models/models.txt"
if [ -f "$MODELS_FILE_PATH" ]; then
  if [ ! -s "$MODELS_FILE_PATH" ]; then
    printf 'groqbash: WARN: models file exists but empty: %s\n' "$MODELS_FILE_PATH" >&2
    bad_models=1
  else
    while IFS= read -r line || [ -n "$line" ]; do
      # trim leading/trailing whitespace (POSIX-safe)
      line_trimmed="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      if [ -n "$line_trimmed" ]; then
        if ! printf '%s\n' "$line_trimmed" | grep -qE '^[[:alnum:]._:-]+$'; then
          printf 'groqbash: ERROR: invalid model id in models file: %s\n' "$line_trimmed" >&2
          bad_models=1
        fi
      fi
    done < "$MODELS_FILE_PATH"
  fi
else
  printf 'groqbash: INFO: models file not present (may be normal)\n' >&2
fi

# Final verdict
if [ "$bad_history" -ne 0 ] || [ "$bad_models" -ne 0 ]; then
  printf 'groqbash: ERROR: concurrency test detected issues (history:%s models:%s)\n' "$bad_history" "$bad_models" >&2
  EXIT_CODE=4
else
  printf 'groqbash: INFO: concurrency test completed: no obvious corruption detected.\n' >&2
fi

exit "$EXIT_CODE"
