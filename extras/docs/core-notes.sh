#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first wrapper for the Groq API
# File: extras/docs/core-notes.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/<your-repo>/groqbash
# =============================================================================
# Purpose: Extended design notes and operational guidance for groqbash core.
# This is documentation intended to be sourced or read by humans; it does not
# alter runtime behavior when sourced. Keep it optional and read-only.

: <<'DOC'
groqbash — Core Notes
=====================

Overview
--------
groqbash is intentionally Groq-first: the core implements the embedded Groq
provider (endpoint, payload builder, streaming parser, and request orchestration).
All non-core providers live under the runtime extras providers directory and are
loaded on demand by the core when PROVIDER != "groq".

This split keeps the core small, auditable, and stable while allowing provider
extensions to be developed independently as extras.

Guard for sourcing / test
-------------------------
The codebase exposes a guard mechanism to support unit testing and development:
if the environment variable `GROQBASH_SOURCE_ONLY` is set prior to sourcing the
main script, the main runtime flow is skipped and only function definitions and
primitives are loaded into the current shell. This allows testing of internal
helpers without triggering CLI parsing, tmpdir creation, interactive prompts,
or network calls.

Provider architecture
---------------------
- **SUPPORTED_PROVIDERS** (declared in core) lists known providers for UI/help.
- **PROVIDER** defaults to "groq". The core reads `groqbash.d/config/provider`
  (first line) if present to override the default.
- CLI override: `--provider <name>` sets PROVIDER for the current run and may be
  persisted to `groqbash.d/config/provider` depending on the command flow.
- Interactive selection: `--provider` (no arg) or `--provider list` shows a
  numbered menu, lets the user pick a provider, saves it, and may trigger a
  provider-aware refresh-models.

Provider modules (runtime: GROQBASH_EXTRAS_DIR/providers or PROVIDERS_DIR)
- Provider modules are runtime extras and must be installed under the runtime
  extras providers directory (e.g., `groqbash.d/extras/providers`), not the
  repository `./extras` source tree. The core loads these modules on demand.

- **Interface (exact names used by the core)**:
    - `buildpayload_<provider>()` — build and stage the payload for the provider.
      **Note:** the core expects the function name without an extra underscore
      between "build" and "payload" (i.e., `buildpayload_...`).
    - `call_api_<provider>()` — perform the non-streaming HTTP call and write the
      response to the canonical RESP file.
    - Optional functions (if present, the core will use them):
      - `call_api_streaming_<provider>()` — streaming/SSE support (invoked when `--stream` is requested).
      - `refresh_models_<provider>()` — fetch and normalize provider model list.
      - `validate_model_<provider>()` — provider-specific model validation.
      - `auto_select_model_<provider>()` — provider-specific auto-selection logic.

- **Operational note:** the core communicates with provider modules exclusively
  via the functions listed above. Provider modules must not bypass PRECORE
  primitives for I/O, atomic writes, or locking.

- **Missing module behavior:** if a requested external provider module is not
  installed, the core prints a clear message (e.g., "Provider '<prov>' is not
  installed. Run --install-extras.") and exits with a non-zero status.

Model precedence (final model selection)
----------------------------------------
When the script decides which MODEL to use for a request, the precedence is
implemented as follows (highest to lowest):

  1) CLI: `-m/--model <name>` (highest precedence for this execution)
  2) Per-provider persisted config: `groqbash.d/config/model.<provider>` (first non-empty line)
  3) Provider auto-selection: `auto_select_model_<provider>()` invoked via dispatch
  4) First supported entry in the canonical whitelist `MODELS_FILE` (default:
     `groqbash.d/models/models.txt`) after normalization
  5) `MODEL` entry in `groqbash.d/config` (if present)
  6) First supported entry in `ALLOWED_MODELS` (if present)

- **Note:** the core primarily relies on the normalized text whitelist
  (`MODELS_FILE`) and provider-specific validation/auto-select logic. Provider
  modules may produce provider-specific manifests, but the canonical core file
  is `MODELS_FILE` unless a provider module explicitly implements a different
  mechanism and the core dispatch uses it.

Dynamic default logic
---------------------
- The core provides helper logic to derive a dynamic default model via provider
  dispatch (e.g., `auto_select_model_<provider>()`). The helper is robust and
  never aborts the script on parse errors; it returns an empty string so the
  fallback chain continues.

refresh-models behavior
-----------------------
- The core invokes provider-specific refresh via `refresh_models_<provider>()`
  (dispatch). For the embedded Groq provider, the implementation queries Groq
  endpoints and updates the canonical `MODELS_FILE` (whitelist).
- Provider modules may write provider-specific manifests (JSON or other formats)
  if they choose; the core will use provider-specific outputs only when the
  provider module implements and the core dispatch expects them.
- The core does not assume a single JSON manifest format for all providers;
  refresh behavior is provider-specific and invoked via the dispatch mechanism.

RUN_TMPDIR, atomic write and locking invariants
-----------------------------------------------
- Every run creates an isolated `RUN_TMPDIR` under `GROQBASH_TMPDIR` for staging
  payloads, responses, and temporary artifacts.
- All critical writes (MODELS_FILE, history entries, payload staging, RESP) use
  atomic write primitives and are protected by flock-based locks to avoid
  corruption under concurrent execution.
- Canonical lock files used by the core include:
    - `MODELS_LOCK` (e.g., `groqbash.d/models/models.lock`)
    - `HISTORY_LOCK` (e.g., `groqbash.d/history/history.lock`)
    - `TMP_LOCK` (e.g., `groqbash.d/tmp/tmp.lock`)
- File and directory permissions are restrictive by design (directories `700`,
  files `600`) to enforce least privilege.

Session management (detailed)
-----------------------------
- `--session <session_id>` enables sessioning. The core validates session IDs
  via `session_validate_id` (pattern and length checks).
- `session_read_window <session_id> <N> <out_file>`:
  - Reads the session NDJSON (`groqbash.d/history/sessions/<session_id>.ndjson`)
    and produces a JSON file with `{ "messages": [...] }` containing the last N
    messages. It acquires locks to avoid races.
  - If the NDJSON is missing or unreadable, the core attempts to reconstruct the
    window via `tail` or falls back to a single user message to ensure the API
    receives at least one message.
- `session_append <session_id> <role> <content> <meta_json>`:
  - Appends messages idempotently using `message_id` markers to avoid duplicates.
  - Uses exclusive locks for atomic append operations.
  - Appends both user and assistant messages (assistant appended only when a
    non-empty assistant response is available and not in DRY_RUN).
- `SESSION_WINDOW` defaults to `10` if not provided; the core warns if a value
  greater than `20` is requested.

Streaming behavior
------------------
- Streaming is supported when a provider module implements
  `call_api_streaming_<provider>()`. The core will call this function when
  `--stream` is requested and the provider exposes streaming support.
- The streaming implementation writes raw stream output to `RUN_TMPDIR/resp.raw`.
  The core then:
  - extracts lines prefixed with `data:` (handling `data: [DONE]` or `data:[DONE]`),
  - filters and validates JSON fragments,
  - constructs `resp.chunks.json` (array of chunk objects) and `resp.text.txt`
    (concatenated textual fragments),
  - writes the canonical `RESP` atomically from the reconstructed chunks when
    valid.
- The streaming parser is intentionally conservative: it applies a minimal,
  safe unescape (e.g., `\"` → `"`, `\\` → `\`, `\/` → `/`) and performs
  best-effort cleanup only to avoid over‑interpreting partial JSON fragments.
- `--stream` is incompatible with `--json` and `--pretty` (the core enforces this).

Edge case API handling and centralized diagnostics
-------------------------------------------------
- The core centralizes handling of notable API edge cases (for example, "empty
  completion"). The detection and decision path is composed of:
    1) `extract_text_from_resp` — attempts to extract textual content from RESP
    2) `detect_empty_edge_case` — inspects the response structure for patterns
       indicating an empty completion (e.g., empty `message.content` or `delta`,
       finish reason, and low completion token counts)
    3) `perform_request_once` — orchestrates retries and final decision
- When an edge case is detected, the core sets diagnostic variables such as:
    - `GROQBASH_EDGE_EMPTY=1`
    - `GROQBASH_EDGE_REQ_ID` (if present in the response)
    - `GROQBASH_EDGE_FINISH_REASON`
    - `GROQBASH_EDGE_COMPLETION_TOKENS`
- The core emits a single structured diagnostic log entry at a defined point in
  the request handling flow (to avoid duplicate diagnostics). That log includes
  key fields (e.g., request id, finish reason, completion tokens) and is used
  by operators and automation to triage the event. After logging, the core
  follows the configured retry/fail policy.

Security and filesystem invariants (non-negotiable)
--------------------------------------------------
The core enforces the following invariants:
- **All runtime files must reside under `GROQBASH_DIR`** (default:
  `SCRIPTDIR/groqbash.d`). No runtime files are written outside this tree.
- **No use of system `/tmp`**: all temporary and staging files are created
  under `GROQBASH_TMPDIR` and `RUN_TMPDIR`.
- **No `eval` and no execution of model-generated content**: external inputs are
  treated strictly as data and never executed as code.
- **All writes to history and models are atomic and protected by locks**.
- **Provider modules must use PRECORE primitives for I/O and locking** and must
  not bypass the atomic/write/lock APIs.

Help and extras path resolution (operational note)
-------------------------------------------------
- The runtime help file is expected under the runtime extras docs path:
  `GROQBASH_EXTRAS_DIR/docs/help.txt` or, if `GROQBASH_EXTRAS_DIR` is not set,
  under `${SCRIPTDIR%/}/groqbash.d/extras/docs/help.txt`. The core resolves the
  help path in that order to avoid reading help from the repository source
  `./extras/docs` at runtime.

Operational tips
----------------
- To add a provider:
  1) Create `groqbash.d/extras/providers/<provider>.sh` implementing the required
     functions (`buildpayload_<prov>`, `call_api_<prov>`, optional streaming/refresh).
  2) Ensure the module checks for required env vars (API keys) and fails clearly if missing.
  3) The module should not redefine core functions or change global state.

- To debug model selection:
  * Check `groqbash.d/config/model.<provider>`
  * Check `groqbash.d/models/models.txt` (refresh with `--refresh-models`)
  * Check `MODEL` environment variable and `groqbash.d/config` `MODEL=` entries

- To keep the core minimal, place optional helpers and diagnostics under
  `groqbash.d/extras/lib/` and source them only when needed.

Canonical variable and flag names (reference)
--------------------------------------------
A non-exhaustive list of important names used by the core (use exact names):
`GROQBASH_DIR`, `GROQBASH_EXTRAS_DIR`, `PROVIDERS_DIR`, `MODELS_FILE`,
`PROVIDER_FILE`, `RUN_TMPDIR`, `PAYLOAD`, `RESP`, `ERRF`, `STREAM_MODE`, `DRY_RUN`,
`DEBUG`, `QUIET`, `SESSION_ID`, `SESSION_WINDOW`, `OUTPUT_MODE`, `FORCE_SAVE_MODE`,
`THRESHOLD`, `MAX_RETRIES`, `ALLOWED_MODELS`.

Examples and common workflows
-----------------------------
- Install extras (from repo source) into runtime extras:
  - Use the `--install-extras` action which validates ownership and permissions
    and copies files into `GROQBASH_EXTRAS_DIR` (runtime).
- Refresh models for the embedded provider:
  - `groqbash --refresh-models` (invokes provider-specific refresh via dispatch).
- Run a single prompt:
  - `groqbash "Summarize this text"`

DOC
