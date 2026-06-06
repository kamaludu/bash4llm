#!/usr/bin/env bash
# =============================================================================
# GroqBash — Core Notes (final)
# File: extras/docs/core-notes.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/<your-repo>/groqbash
# =============================================================================
# Purpose: Design notes and operational guidance for groqbash core.
# This file is documentation only. It is safe to source for tests (GROQBASH_SOURCE_ONLY)
# and must not change runtime behavior when sourced.

: <<'DOC'
groqbash — Core Notes
=================================

Overview
--------
groqbash is a Bash-first orchestrator for LLM provider calls with a Groq-first
embedded provider. The core provides secure primitives (atomic writes, locks,
base64 staging), session and history management, provider discovery and a
provider contract (buildpayload_*, call_api_*). Provider modules live under
runtime extras and are loaded on demand.

Design goals
- Minimal trusted core; provider extensions as runtime extras.
- Strong filesystem invariants: all runtime files under GROQBASH_DIR.
- Atomicity and locking for all persistent writes.
- No eval, no execution of model-generated content.
- DRY_RUN and centralized network policy to prevent accidental network calls.

-------------------------------------------------------------------------------
PRECORE_BOOT (bootstrap primitives)
-------------------------------------------------------------------------------
Purpose
Initialize runtime invariants and provide low-level helpers used by all other
sections: path resolution, config dir creation, base64 options detection,
portable tmp helpers, logging and safe provider loading.

Key primitives (documented)
- resolve_script_dir()
  Determine canonical script directory; prints path to stdout.
- canonical_config_dir(), canonical_provider_file(), canonical_model_file(), canonical_provider_url_file()
  Canonical path helpers; used by CLI --print-* flags and persistence.
- ensure_config_dir()
  Create/config dir with perms 700; fail-fast on inability to create or if dir is a symlink.
- ensure_run_tmpdir([--print])
  Create per-run RUN_TMPDIR under GROQBASH_TMPDIR; export PAYLOAD/RESP/ERRF; install cleanup trap.
- _detect_base64_opts(), B64_WRAP_OPT, B64_DECODE_OPT
  Platform-portable base64 option detection and exported opts.
- _mktemp_in_dir(), _tmpf(), make_tmpdir()
  Force creation of tmpfiles/dirs under GROQBASH_TMPDIR; explicitly reject /tmp or external dirs.
- atomic_write(dest [,timeout])
  Write stdin to temp file then mv atomically under lock_exec.
- b64_atomic_write/read, stage_b64(src|stdin dst)
  Atomic base64 staging with MAX_STAGE_BYTES checks.
- lock_exec(lockfile timeout -- command ...)
  Acquire exclusive flock with timeout and run command in subshell; clear rc on failure.
- log_info(code,msg), log_warn(code,msg), log_error(code,msg)
  Structured logging helpers honoring DEBUG and GROQBASH_LOG.
- enforce_network_policy()
  Central policy check: returns 0 if network allowed; non-zero if blocked.
  Respects DRY_RUN, GROQBASH_SKIP_NETWORK, GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET, QUIET.
- ui_state_write(relpath, json-string)
  Atomically write JSON state under $GROQBASH_CONFIG_DIR/ui_state with perms 600; best-effort.
- load_provider_module(provider)
  Safe-load provider module from PROVIDERS_DIR: security checks (no symlink, owner, perms),
  `bash -n` syntax check, source in isolated subshell, import only function definitions,
  write provider_capabilities.json via ui_state_write, set LOADED_PROVIDER_NAME/PROVIDER_MODULE_LOADED.
- validate_provider_interface(p)
  Verify required functions exist (buildpayload_<p>, call_api_<p>); log missing functions.

Invariants and policies
- All created dirs: mode 700; files: mode 600.
- GROQBASH_TMPDIR must be inside GROQBASH_DIR; _tmpf enforces this.
- Fail-fast on missing mandatory external commands (bash, curl, jq, awk, coreutils).

-------------------------------------------------------------------------------
PRECORE_RUN (runtime primitives: history, manifest, session, cache)
-------------------------------------------------------------------------------
Purpose
Provide atomic, lock-protected runtime primitives for history rotation, multimodal
manifest staging, session NDJSON handling and session cache.

Key primitives (documented)
- rotate_history()
  Rotate history under HISTORY_LOCK using GROQBASH_HISTORY_MAX_FILES / MAX_BYTES / KEEP_DAYS.
- save_to_history(payload_json)
  Atomically append/save history entry, update last_history.json via ui_state_write, call rotate_history when needed.
- manifest_create(manifest_path), manifest_add_part(manifest, srcfile), manifest_read(manifest)
  Multimodal manifest management: parts array + staged base64 parts; manifest.b64 staging;
  manifest_add_part stages part via stage_b64, updates manifest under lock, writes manifest.b64.
- session_validate_id(sid)
  Validate session id pattern and length; return 0/1.
- session_now_ts()
  Return epoch UTC timestamp for session records.
- session_messages_tmp_path(session_id)
  Path helper for session tmp files under RUN_TMPDIR.
- session_read_window(session_id, N, out_file)
  Read last N NDJSON lines from sessions/<sid>.ndjson, normalize roles, produce {"messages":[...]} atomically.
  Requires RUN_TMPDIR writable; updates ui_state best-effort.
- session_append(session_id, role, content, meta_json)
  Idempotent append: generate message_id if missing, create marker dir, acquire flock on session file,
  check duplicates, append NDJSON, leave done marker, update ui_state; cleans markers on failure.
- session_marker_create / session_cache_key / session_cache_get / session_cache_set / session_cache_invalidate
  Session cache primitives:
  - Key format: sid|sha256(params_string)
  - Cache file format: first line = expiry_epoch; subsequent lines = payload JSON.
  - session_cache_get removes expired files and returns 0 on hit.
  - session_cache_set writes atomically under GROQBASH_CONFIG_DIR/session_cache with perms 600.
  - TTL enforced by expiry epoch first line.
- _get_perm_string, _get_owner, getfile_signature, _is_world_writable
  Portable file metadata helpers; used for security checks.
- list_files_sorted_by_mtime, _file_mtime, tac_fallback
  Portable utilities for file ordering and fallback behaviors.

Invariants and policies
- All session and cache files are NDJSON or JSON; session NDJSON: one record per line {ts, role, content, meta}.
- Atomicity: all writes under locks and mv atomic within same filesystem.
- No use of system /tmp; all tmp under GROQBASH_TMPDIR/RUN_TMPDIR.

-------------------------------------------------------------------------------
PROVIDER (embedded: groq)
-------------------------------------------------------------------------------
Purpose
Provider-specific implementation for Groq-compatible API: payload builder,
non-streaming and streaming calls, models refresh and validation.

Key functions (documented)
- buildpayload_groq()
  Build and validate payload JSON from MODEL, TURE (temperature), MAX_TOKENS, MESSAGES_JSON,
  BUILD_MESSAGES_FILE, JSON_INPUT, CONTENT, STREAM_MODE. Produce GROQBASH_TMP_PAYLOAD or PAYLOAD.
  Fail with diagnostics if payload empty or jq fails.
- call_api_groq()
  Non-streaming HTTP call using CURL_BASE_OPTS; decode .b64 payload if needed; enforce_network_policy;
  require GROQ_API_KEY or PROVIDER_API_ENV_groq/GROQBASH_API_KEY; write RESP (resp.json) and diagnostics.
- call_api_streaming_groq()
  Streaming (SSE) call: write resp.raw, parse lines prefixed with data:, extract JSON chunks,
  build resp.chunks.json and resp.text.txt incrementally, write final RESP atomically.
- refresh_models_groq()
  Call /openai/v1/models, normalize names, filter supported models, write MODELS_FILE atomically via b64_atomic_write
  under MODELS_LOCK; respect MAX_MODELS; produce diagnostics on failure.
- validate_model_groq(model)
  Check presence in MODELS_FILE (if exists) and call is_supported_model; return 0 if valid.
- auto_select_model_groq()
  Scan MODELS_FILE and return first supported normalized model on stdout; return 1 if none.

Operational notes
- Uses RUN_TMPDIR, MODELS_FILE, MODELS_LOCK, MAX_MODELS.
- All network calls respect enforce_network_policy and DRY_RUN.
- On any error produce RESP diagnostic JSON with reason, timestamp and stderr fragment.

-------------------------------------------------------------------------------
CORE_SETUP (CLI, model resolution, request orchestration)
-------------------------------------------------------------------------------
Purpose
Normalize CLI and env flags, resolve FINAL_MODEL, dispatch to provider functions,
handle retries, extract text from RESP, detect edge cases and finalize output.

Key flows and functions (documented)
- resolve_model()
  Priority (highest → lowest):
    1) CLI -m/--model
    2) per-provider persisted file groqbash.d/config/model.<provider> (first non-empty line)
    3) provider auto-select (auto_select_model_<provider>())
    4) first supported entry in MODELS_FILE (normalized)
    5) MODEL in groqbash.d/config
    6) first supported entry in ALLOWED_MODELS
  Sets FINAL_MODEL or returns non-zero if unresolved.
- call_provider(function_name, ...)
  Generic dispatch: call buildpayload_<prov>, call_api_<prov>, etc.; return 127 if function missing.
- refresh_models_dispatch(), validate_model_dispatch(), auto_select_model_dispatch()
  Provider-dispatch wrappers with clear error codes and logging.
- build_payload_from_vars()
  Ensure RUN_TMPDIR and delegate to buildpayload_<PROVIDER>; set GROQBASH_TMP_PAYLOAD/PAYLOAD.
- call_api_once() / call_api_streaming()
  Wrapper that respects DRY_RUN and delegates to provider call_api_* functions.
- perform_request_once()
  Retry loop with MAX_RETRIES and linear backoff for transport errors; distinguishes API errors vs transport errors.
  After response: extract_text_from_resp(), detect_empty_edge_case(), finalize_and_output().
- extract_text_from_resp()
  Heuristics to extract textual content from RESP JSON; supports multiple response shapes; writes diagnostics to ERRF.
- detect_empty_edge_case()
  Inspect RESP for empty completions; set GROQBASH_EDGE_EMPTY and related GROQBASH_EDGE_* diagnostics.
- finalize_and_output(mode, text)
  Emit output according to OUTPUT_MODE (json/pretty/text/raw), save long outputs via save_to_history when FORCE_SAVE_MODE or THRESHOLD exceeded,
  write last_api.json fallback via ui_state_write.

Operational invariants
- CURL_BASE_OPTS is the conservative base for all curl invocations.
- DRY_RUN prevents real network calls; call_api wrappers must honor DRY_RUN.
- All provider errors produce RESP diagnostic JSON when possible.

-------------------------------------------------------------------------------
CORE_PROVIDER (discovery, selection, persistence)
-------------------------------------------------------------------------------
Purpose
Discover available providers (builtin + extras), persist provider choice, resolve provider URL and API key, and validate provider interface.

Key behaviors (documented)
- Discovery
  SUPPORTED_PROVIDERS built from builtin providers + files under GROQBASH_EXTRAS_DIR/providers or PROVIDERS_DIR.
- Persistence
  canonical_provider_file() returns groqbash.d/config/provider; writing uses atomic_write and chmod 600.
  When provider changes, invalidate MODELS_FILE to avoid stale lists.
- resolve_provider_url(provider)
  Resolution precedence: ENV (GROQBASH_API_URL / GROQBASH_PROVIDER_URL) > provider-url file > embedded default (for groq).
  Exports GROQBASH_PROVIDER_URL on success.
- ensure_api_key_for_provider(provider)
  Compute provider API env var name via provider_api_env_var_name; if missing:
    - If interactive TTY: prompt and export; else fail with GROQBASHERRNOAPIKEY unless DRY_RUN.
- validate_provider_interface(provider)
  Ensure required functions exist; log and return non-zero if missing.
- load_provider_module(provider)
  See PRECORE_BOOT: security checks, bash -n, subshell import, write provider_capabilities.json via ui_state_write.

Security and side-effects
- Provider modules must not bypass PRECORE primitives for I/O or locking.
- Provider selection persistence uses atomic_write and perms 600.
- write_provider_url_if_missing(provider, url) writes provider-url file atomically when safe.

-------------------------------------------------------------------------------
SESSION CACHE (explicit)
-------------------------------------------------------------------------------
Purpose
Reduce repeated work by caching session-derived payloads/responses.

Key points
- session_cache_key(sid, params) => sid|sha256(params_string).
- Cache file format: first line expiry_epoch; subsequent lines payload JSON.
- session_cache_get removes expired files and returns 0 on hit; session_cache_set writes atomically.
- Cache stored under ${GROQBASH_CONFIG_DIR%/}/session_cache with perms 600.
- TTL enforced by expiry_epoch; invalidation via session_cache_invalidate() when session changes.

-------------------------------------------------------------------------------
HISTORY & MANIFEST (explicit)
-------------------------------------------------------------------------------
Purpose
Persist conversation history and multimodal manifests safely.

Key points
- save_to_history() writes entries atomically and updates last_history.json via ui_state_write.
- rotate_history() enforces GROQBASH_HISTORY_MAX_FILES, GROQBASH_HISTORY_MAX_BYTES, GROQBASH_HISTORY_KEEP_DAYS under HISTORY_LOCK.
- manifest_create/add_part/read:
  - manifest JSON contains "parts" array; each part staged as .b64 via stage_b64.
  - manifest.b64 is the base64-encoded manifest; both manifest and manifest.b64 updated under lock.
  - manifest_add_part requires source file existence and stages part atomically.

-------------------------------------------------------------------------------
NETWORK POLICY (centralized)
-------------------------------------------------------------------------------
Purpose
Centralize decision to allow or block network calls.

Key points
- enforce_network_policy() is the single gate for network access.
- Inputs: DRY_RUN, GROQBASH_SKIP_NETWORK, GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET, QUIET, DEBUG.
- Behavior:
  - If DRY_RUN => block real network calls (simulate).
  - If GROQBASH_SKIP_NETWORK=1 => block network.
  - If QUIET and GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET=1 => block network.
  - When blocked, call_api_* must return non-zero and produce RESP diagnostic.
- All provider call sites must call enforce_network_policy() before curl.

-------------------------------------------------------------------------------
STREAMING (explicit)
-------------------------------------------------------------------------------
Purpose
Conservative SSE parsing and incremental output.

Key points
- call_api_streaming_* writes raw stream to RUN_TMPDIR/resp.raw.
- Parser extracts lines prefixed with "data:"; handles [DONE] sentinel.
- Minimal unescape applied; JSON fragments validated before aggregation.
- resp.chunks.json (array) and resp.text.txt (concatenated text) are produced; final RESP written atomically.
- Streaming emits incremental text to stdout but never executes content.

-------------------------------------------------------------------------------
EDGE CASES AND DIAGNOSTICS
-------------------------------------------------------------------------------
Purpose
Detect empty completions and other anomalies; provide structured diagnostics.

Key points
- extract_text_from_resp() attempts multiple heuristics; returns rc codes:
  - 0: text extracted
  - 1: no text
  - 2: diagnostic-only (malformed JSON)
- detect_empty_edge_case() sets GROQBASH_EDGE_EMPTY and related GROQBASH_EDGE_* variables.
- perform_request_once() uses these signals to decide retry vs fail and logs a single structured diagnostic entry.

-------------------------------------------------------------------------------
UI STATE AND DIAGNOSTIC FILES
-------------------------------------------------------------------------------
Purpose
Expose provider capabilities and last API call state for UI/automation.

Key points
- ui_state_write(relpath, json) writes under $GROQBASH_CONFIG_DIR/ui_state with perms 600.
- provider_capabilities.json written by load_provider_module() describing provider features.
- last_api.json written as fallback by CORE_SETUP when RESP exists; used by UI and automation.
- save_to_history() and finalize_and_output() update ui_state best-effort.

-------------------------------------------------------------------------------
CANONICAL VARIABLES (reference)
-------------------------------------------------------------------------------
Important names (use exact names):
GROQBASH_DIR, GROQBASH_EXTRAS_DIR, PROVIDERS_DIR, GROQBASH_CONFIG_DIR,
MODELS_FILE, MODELS_LOCK, PROVIDER_FILE, RUN_TMPDIR, GROQBASH_TMP_PAYLOAD,
PAYLOAD, RESP, ERRF, STREAM_MODE, DRY_RUN, DEBUG, QUIET, SESSION_ID,
SESSION_WINDOW, OUTPUT_MODE, FORCE_SAVE_MODE, THRESHOLD, MAX_RETRIES,
GROQBASH_TMPDIR, GROQBASH_HISTORY_DIR, GROQBASH_LOCK_TIMEOUT_*,
GROQBASH_ROTATE_HISTORY, GROQBASH_HISTORY_MAX_FILES, GROQBASH_HISTORY_MAX_BYTES,
GROQBASH_HISTORY_KEEP_DAYS, ALLOWED_MODELS, MAX_MODELS, CURL_BASE_OPTS,
B64_WRAP_OPT, B64_DECODE_OPT, GROQ_API_KEY, PROVIDER_API_ENV_groq, GROQBASH_API_KEY,
TURE (temperature alias), TEMPERATURE (recommended alias).

Notes
- TURE is retained for backward compatibility; document TEMPERATURE as alias in user-facing docs.
- CURL_BASE_OPTS default: --silent --show-error --no-buffer --max-time 120.

-------------------------------------------------------------------------------
OPERATIONAL TIPS (concise)
-------------------------------------------------------------------------------
- To add a provider: install groqbash.d/extras/providers/<prov>.sh implementing buildpayload_<prov> and call_api_<prov>.
- To refresh models: groqbash --refresh-models (dispatches to refresh_models_<prov>).
- To debug model selection: check groqbash.d/config/model.<provider>, groqbash.d/models/models.txt, and MODEL env.
- Preflight checklist before release: verify perms (700/600), ensure _tmpf rejects /tmp, run static checks (bash -n) on provider modules, test enforce_network_policy with DRY_RUN.

-------------------------------------------------------------------------------
EXAMPLES (short)
-------------------------------------------------------------------------------
- Single prompt:
  groqbash "Summarize this text"
- Refresh models (embedded groq):
  groqbash --refresh-models
- Start session and append:
  groqbash --session myid --append "User message"

-------------------------------------------------------------------------------
CHANGE NOTES (summary)
-------------------------------------------------------------------------------
This document is the authoritative core notes aligned to:
- groqbash_compact_no_code (functions, variables, code_map)
- SPEC TECNICA STRUTTURALE (PRECORE_BOOT, PRECORE_RUN, PROVIDER, CORE_SETUP, CORE_PROVIDER)
All critical primitives and invariants from the SPEC are explicitly documented above.

-------------------------------------------------------------------------------
END
DOC
