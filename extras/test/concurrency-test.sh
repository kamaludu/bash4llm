#!/usr/bin/env bash
# extras/test/concurrency-test.sh
# Concurrency test for GroqBash
# Usage: extras/test/concurrency-test.sh [path-to-groqbash] [N_WRITERS] [N_REFRESHERS] [SLEEP_BETWEEN]
# Default: ./groqbash 10 5 0.05
set -euo pipefail

GROQBASH_BIN="${1:-./groqbash}"
N_WRITERS="${2:-10}"
N_REFRESHERS="${3:-5}"
SLEEP_BETWEEN="${4:-0.05}"
TMPTEST_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" groqbash-test.XXXX)"
EXIT_CODE=0

cleanup() {
  rm -rf -- "$TMPTEST_DIR" || true
}
trap cleanup EXIT

if [ ! -x "$GROQBASH_BIN" ]; then
  printf 'groqbash: ERROR: binary not found or not executable: %s\n' "$GROQBASH_BIN" >&2
  exit 2
fi

printf 'groqbash: INFO: Starting concurrency test: writers=%s refreshers=%s sleep=%s\n' "$N_WRITERS" "$N_REFRESHERS" "$SLEEP_BETWEEN"

# Writers: each writes a unique prompt and forces save
writer_pids=()
for i in $(seq 1 "$N_WRITERS"); do
  (
    prompt="concurrency-writer-${i}-$(date +%s%N)"
    # Use --text and --save to force history write
    printf '%s\n' "$prompt" | "$GROQBASH_BIN" --text --save >/dev/null 2>&1 || printf 'groqbash: WARN: writer %s failed\n' "$i" >&2
  ) &
  writer_pids+=("$!")
  sleep "$SLEEP_BETWEEN"
done

# Refreshers: run refresh-models in parallel (may require API key)
refresher_pids=()
for j in $(seq 1 "$N_REFRESHERS"); do
  (
    if ! "$GROQBASH_BIN" --refresh-models >/dev/null 2>&1; then
      printf 'groqbash: INFO: refresher %s exited non-zero (may be expected without API key)\n' "$j" >&2
    fi
  ) &
  refresher_pids+=("$!")
  sleep "$SLEEP_BETWEEN"
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
HIST_DIR="${GROQBASH_HISTORY_DIR:-${GROQBASH_DIR:-./groqbash.d}/history}"
if [ -d "$HIST_DIR" ]; then
  count_total=$(find "$HIST_DIR" -type f | wc -l || echo 0)
  printf 'groqbash: INFO: history files count: %s\n' "$count_total"
  while IFS= read -r -d '' f; do
    if [ ! -s "$f" ]; then
      printf 'groqbash: ERROR: empty history file detected: %s\n' "$f" >&2
      bad_history=1
    fi
  done < <(find "$HIST_DIR" -type f -print0 2>/dev/null || true)
else
  printf 'groqbash: WARN: history dir not found: %s\n' "$HIST_DIR" >&2
fi

# Models file checks (if present)
bad_models=0
MODELS_FILE_PATH="${MODELS_FILE:-${GROQBASH_MODELS_DIR:-${GROQBASH_DIR:-./groqbash.d}/models}/models.txt}"
if [ -f "$MODELS_FILE_PATH" ]; then
  if [ ! -s "$MODELS_FILE_PATH" ]; then
    printf 'groqbash: WARN: models file exists but empty: %s\n' "$MODELS_FILE_PATH" >&2
    bad_models=1
  else
    while IFS= read -r line || [ -n "$line" ]; do
      line_trimmed="$(printf '%s' "$line" | awk '{$1=$1;print}')"
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
  printf 'groqbash: INFO: concurrency test completed: no obvious corruption detected.\n'
fi

exit "$EXIT_CODE"
