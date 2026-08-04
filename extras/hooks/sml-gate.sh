#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Extra Hook Module: SML v2.0 Semantic Safety Gate
# File: extras/hooks/sml-gate.sh
# Target Category: T2 Boundary Integration Hook
# =============================================================================

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

post_execution_hook() {
  local status_code="${1:-SUCCESS}"
  local exit_code="${2:-0}"
  local http_status="${3:-200}"

  if [ "$status_code" != "SUCCESS" ]; then
    return 0
  fi

  # Reading of the extracted text available in memory or via variable
  local text_payload="${RAW_RESPONSE_TEXT:-}"

  if [ -n "$text_payload" ]; then
    # Check for the presence of SML v2.0 headers and mandatory keys
    if echo "$text_payload" | grep -q "SML_VERSION: 2.0" && \
       echo "$text_payload" | grep -q "LISTEN_SUMMARY:" && \
       echo "$text_payload" | grep -q "CONVERSATION_OUTCOME:"; then
      
      # Transformed payload generation and output in Base64 for the Core
      local b64_payload=""
      b64_payload="$(printf '%s' "$text_payload" | base64 | tr -d '\n')"
      printf 'TRANSFORMED_PAYLOAD=%s\n' "$b64_payload"
    fi
  fi

  return 0
}
