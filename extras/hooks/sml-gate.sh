#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/hooks/sml-gate.sh
# Component: Extra Hook Module: Structured Metadata Layout - Semantic Safety Gate
# Target Category: T2 Boundary Integration Hook
# Paired Template: extras/templates/sml.txt
# Requirements: Model conditioning via SML v2.0 prompt template or --system directive
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

# Idempotent declaration of the expected SML schema version
if [ -z "${SML_SCHEMA_VERSION:-}" ]; then
  readonly SML_SCHEMA_VERSION="2.0"
fi

# Portable Base64 encoding helper ensuring continuous, single-line output
_sml_encode_b64() {
  if type b64encode >/dev/null 2>&1; then
    b64encode | LC_ALL=C tr -d ' \t\r\n'
  elif command -v openssl >/dev/null 2>&1; then
    openssl enc -base64 2>/dev/null | LC_ALL=C tr -d ' \t\r\n'
  else
    base64 2>/dev/null | LC_ALL=C tr -d ' \t\r\n'
  fi
}

# =============================================================================
# PRE-EXECUTION HOOK
# =============================================================================
# Purpose: Executed in an isolated subshell before request dispatching.
# Returns: Status code 0 to proceed, or non-zero to halt pipeline.
# =============================================================================
pre_execution_hook() {
  # Pre-dispatch pass-through: prompt conditioning is managed via template/CLI
  return 0
}

# =============================================================================
# POST-EXECUTION HOOK
# =============================================================================
# Purpose: Boundary gate validation, Markdown sanitization, and output transformation.
# Arguments:
#   $1: Execution status string ("SUCCESS" or "ERROR")
#   $2: Exit code from network/API layer (e.g. 0)
#   $3: HTTP status code from endpoint (e.g. 200)
# Output: Emits TRANSFORMED_PAYLOAD or FALLBACK_PAYLOAD in Base64 via Core whitelist.
# =============================================================================
post_execution_hook() {
  local status_code="${1:-SUCCESS}"
  local exit_code="${2:-0}"
  local http_status="${3:-200}"

  # 1. Handle API or network errors with a structured fallback payload
  if [ "$status_code" != "SUCCESS" ] || [ "$exit_code" -ne 0 ]; then
    local error_payload="SML_GATE_ERROR: Upstream API transaction failed (HTTP status: ${http_status}, exit code: ${exit_code})."
    local b64_fallback=""
    b64_fallback="$(printf '%s' "$error_payload" | _sml_encode_b64 || true)"
    if [ -n "$b64_fallback" ]; then
      printf 'FALLBACK_PAYLOAD=%s\n' "$b64_fallback"
    fi
    return 0
  fi

  # 2. Acquire raw response text from memory environment or isolated disk response file
  local raw_text="${RAW_RESPONSE_TEXT:-}"

  if [ -z "$raw_text" ] && [ -n "${RESP:-}" ] && [ -f "${RESP:-}" ] && [ -s "${RESP:-}" ]; then
    if command -v jq >/dev/null 2>&1; then
      # Full parity extraction matching Core extract_text_from_resp algorithm
      raw_text="$(jq -r '
        if .choices and (.choices|length > 0) then
          [ .choices[]? | (.message?.content // .delta?.content // .text? // "") ] | map(select(.!="")) | join("\n\n")
        elif (.output_text? // empty) != "" then
          .output_text
        elif .data and (.data|length > 0) then
          [ .data[]?.text? // empty ] | map(select(.!="")) | join("\n\n")
        else
          empty
        end
      ' "$RESP" 2>/dev/null || true)"
    fi
    # Fallback to plain text read if structured JSON extraction yields empty
    if [ -z "$raw_text" ]; then
      raw_text="$(cat "$RESP" 2>/dev/null || true)"
    fi
  fi

  # Fail-Closed: exit cleanly if no response text could be resolved
  if [ -z "$raw_text" ]; then
    return 0
  fi

  # 3. Non-Destructive Markdown Outer Code-Block Unwrapping
  # Strips only outer enclosing markdown fences without corrupting internal code blocks
  local clean_text=""
  clean_text="$(printf '%s\n' "$raw_text" | LC_ALL=C awk '
    BEGIN { first_non_empty=1 }
    NF {
      if (first_non_empty) {
        first_non_empty=0
        if ($0 ~ /^[[:space:]]*```/) next
      }
    }
    { lines[NR] = $0 }
    END {
      last_idx = NR
      while (last_idx > 0 && lines[last_idx] ~ /^[[:space:]]*$/) {
        last_idx--
      }
      if (last_idx > 0 && lines[last_idx] ~ /^[[:space:]]*```[a-zA-Z0-9_-]*[[:space:]]*$/) {
        delete lines[last_idx]
      }
      for (i = 1; i <= NR; i++) {
        if (i in lines) print lines[i]
      }
    }
  ' | LC_ALL=C sed -e 's/\r$//')"

  # 4. Strict POSIX ERE Anchored Validation of All 5 Mandatory SML v2.0 Headers
  local has_version has_listen has_outcome has_transition has_evidence

  has_version="$(printf '%s\n' "$clean_text" | LC_ALL=C grep -E "^[[:space:]]*SML_VERSION:[[:space:]]*${SML_SCHEMA_VERSION}" || true)"
  has_listen="$(printf '%s\n' "$clean_text" | LC_ALL=C grep -E "^[[:space:]]*LISTEN_SUMMARY:" || true)"
  has_outcome="$(printf '%s\n' "$clean_text" | LC_ALL=C grep -E "^[[:space:]]*CONVERSATION_OUTCOME:" || true)"
  has_transition="$(printf '%s\n' "$clean_text" | LC_ALL=C grep -E "^[[:space:]]*PROPOSED_TRANSITION:" || true)"
  has_evidence="$(printf '%s\n' "$clean_text" | LC_ALL=C grep -E "^[[:space:]]*EVIDENCE_TYPE:" || true)"

  if [ -n "$has_version" ] && \
     [ -n "$has_listen" ] && \
     [ -n "$has_outcome" ] && \
     [ -n "$has_transition" ] && \
     [ -n "$has_evidence" ]; then

    # 5. Emit Transformed Clean Payload in Base64 for Safe Core Ingestion
    local b64_transformed=""
    b64_transformed="$(printf '%s' "$clean_text" | _sml_encode_b64 || true)"
    if [ -n "$b64_transformed" ]; then
      printf 'TRANSFORMED_PAYLOAD=%s\n' "$b64_transformed"
    fi
    return 0
  fi

  # 6. Syntax Validation Failure: Emit structured corrective instruction for self-healing retries
  local corrective_msg
  corrective_msg="[SML_VALIDATION_FAILURE]
The response does not strictly comply with the Structured Metadata Layout (SML v2.0) specification.
Mandatory headers missing or misformatted. You MUST include:
- SML_VERSION: 2.0
- LISTEN_SUMMARY:
- CONVERSATION_OUTCOME:
- PROPOSED_TRANSITION:
- EVIDENCE_TYPE:

Do not wrap the response in Markdown code fences. Please reformat and return the full response adhering to this schema."

  local b64_err_fallback=""
  b64_err_fallback="$(printf '%s' "$corrective_msg" | _sml_encode_b64 || true)"
  if [ -n "$b64_err_fallback" ]; then
    printf 'FALLBACK_PAYLOAD=%s\n' "$b64_err_fallback"
  fi

  return 0
}
