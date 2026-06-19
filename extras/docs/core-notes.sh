#!/usr/bin/env bash
# =============================================================================
# Bash4LLM — Core Notes
# File: extras/docs/core-notes.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/<your-repo>/bash4llm
# =============================================================================
# Purpose: Design notes and operational guidance for bash4llm core.
# This file is documentation only. It is safe to source for tests (BASH4LLM_SOURCE_ONLY)
# and must not change runtime behavior when sourced.

: <<'DOC'
bash4llm — Core Notes
=================================

Overview
--------
bash4llm is a Bash-first orchestrator for LLM provider calls with a Groq-first
embedded provider. The core provides secure primitives (atomic writes, locks,
base64 staging), session and history management, provider discovery and a
provider contract (buildpayload_*, call_api_*). Provider modules live under
runtime extras and are loaded on demand.

Design goals
- Minimal trusted core; provider extensions as runtime extras.
- Strong filesystem invariants: all runtime files under BASH4LLM_DIR.
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
  Determine canonical script directory ($SCRIPTDIR); prints path to stdout.
- canonical_config_dir()
  Normalize and return the canonical config directory path ($BASH4LLM_CONFIG_DIR).
- canonical_provider_file()
  Return the path to the provider persistence file under the canonical config directory.
- canonical_model_file(provider)
  Return the path to the default model file for the specified provider under config.
- canonical_provider_url_file()
  Return the path to the active provider API URL file under config.
- ensure_api_key_for_provider(provider)
  Validate API key presence in environment. If missing in non-interactive TTY, fail with
  BASH4LLMERRNOAPIKEY. In interactive TTY, prompt, sanitize input (remove export commands, spaces),
  export to env, and show permanent save instructions.
- enforce_network_policy()
  Central policy check: returns 0 if network allowed; non-zero if blocked.
  Respects DRY_RUN, BASH4LLM_SKIP_NETWORK, BASH4LLM_ENFORCE_NO_NETWORK_IF_QUIET, QUIET.
- log_prefix()
  Return unified log header prefix: bash4llm: <SCRIPT_NAME>:.
- log_info(code, msg), log_warn(code, msg), log_error(code, msg)
  Structured logging helpers writing to stderr (if DEBUG active) and appending to BASH4LLM_LOG.
- dbg(...)
  Print fast diagnostic messages to stderr when DEBUG is enabled.
- ensure_config_dir()
  Create config dir with permissions 700, test write access, and fail-fast if unable or if it is a symlink.
- write_provider_url_if_missing(provider, url)
  Atomically and transactionally write provider API URL to the canonical URL file; set permissions 600.
- resolve_provider_url(provider)
  Determine active API URL: prioritize ENV (BASH4LLM_API_URL/BASH4LLM_PROVIDER_URL), then provider-url file,
  falling back to Groq native default. Exports BASH4LLM_PROVIDER_URL.
- provider_api_env_var_name(provider)
  Normalize provider name to uppercase, replace non-alphanumeric chars with "_" and append "_API_KEY".
- is_valid_json_string(string)
  Validate if input string is syntactically correct JSON using jq.
- b64encode() / b64decode()
  Base64 stream encoding and decoding utilizing platform-portable options.
- is_truthy(val)
  Return 0 (true) if value matches 1, true, TRUE, True, yes, YES, Yes; 1 otherwise.
- file_size(path)
  Determine precise file size in bytes using portable stat flags.
- is_valid_json_file(path)
  Validate if file exists, contains data, and is valid JSON.
- stage_b64([src,] dst)
  Securely encode source (file or stdin) to Base64 under size limits ($MAX_STAGE_BYTES), writing atomically to dst with permissions 600.
- lock_exec(lockfile, timeout -- command ...)
  Acquire exclusive flock with timeout and run command in subshell; fail with status 124 on timeout.
- _mktemp_in_dir(root_dir, [prefix])
  Create unique temp file inside the designated root directory.
- show_payload_head(path, [lines])
  Extract and print first lines of payload for debugging; decodes base64 (.b64) payloads on the fly.
- atomic_write(dest, [timeout])
  Write stdin to temp file inside dest's parent folder, apply mode 600, lock parent, and mv atomically to dest.
- extract_text_from_resp()
  Resilient extraction of assistant text from RESP JSON. Supports OpenAI delta/message content, plain text,
  custom outputs, and recursive fallback; writes malformed/diagnostic indicators to ERRF.
- ensure_run_tmpdir([--print])
  Create per-run isolated RUN_TMPDIR (mode 700) under BASH4LLM_TMPDIR; export PAYLOAD/RESP/ERRF (mode 600);
  install EXIT/INT/TERM cleanup trap.
- cleanup_tmp()
  Recursively remove RUN_TMPDIR directory when safe.
- b64_atomic_write(dest, [timeout])
  Encode stdin to Base64 and write atomically to dest under lock with permissions 600.
- b64_atomic_read(path)
  Perform safe, atomic read and real-time Base64 decoding of a file.
- ui_state_write(filename, json_content)
  Atomically write state files to the UI state directory under lock with permissions 600.
- load_provider_module(provider)
  Safe-load external provider modules with checks (no group/world writable, belongs to owner, `bash -n` check,
  cryptographic signatures check). Source in a subshell, verify interface functions buildpayload_<p> and call_api_<p>,
  import into main environment, and write provider_capabilities.json via ui_state_write.
- _detect_base64_opts()
  Detect system base64 flags (B64_WRAP_OPT and B64_DECODE_OPT) dynamically for GNU and macOS/BSD.
- list_files_sorted_by_mtime(dir)
  List directory files sorted by modification time (ascending) portably.
- tac_fallback(file)
  Invert file line order using tac or an awk-based fallback.
- _file_mtime(file)
  Get file modification time as a Unix timestamp.
- jq_safe(filter, json_file)
  Execute safe jq operations; write errors to ERRF on failure instead of crashing.

Blocks of Code / Flows
- PRECORE_BOOT_SETUP_SHELL: Set restrictive options (`set -euo pipefail`).
- PRECORE_BOOT_SOURCE_ONLY_CHECK: If BASH4LLM_SOURCE_ONLY=1, exit with status 0 immediately after source.
- PRECORE_BOOT_VERIFY_CMDS: Validate the presence of mandatory utilities (bash, jq, curl, mktemp, stat, flock, etc.).
- PRECORE_BOOT_DIR_RESOLUTION: Resolve $BASH4LLM_DIR dynamically.
- PRECORE_BOOT_FALLBACK_PROVIDERS: Export fallback paths for $BASH4LLM_EXTRAS_DIR and $PROVIDERS_DIR.
- PRECORE_BOOT_DIR_INVARIANTS: Ensure safe directory boundaries (e.g., $BASH4LLM_TMPDIR must reside inside $BASH4LLM_DIR, not system /tmp).
- PRECORE_BOOT_ENSURE_CONFIG_DIR: Ensure active configuration directory is valid.
- PRECORE_BOOT_FAILFAST_CONFIG_DIR: Fail-fast if canonical configuration path resolution returns empty.
- PRECORE_BOOT_NORMALIZE_DEBUG: Normalize DEBUG environment flags (defaulting to 0).
- PRECORE_BOOT_EARLY_PRINT_CONFIG: Early intercept and execution of command-line path printing queries.
- PRECORE_BOOT_MKDIR_PERMS: Create the workspace structure, enforce 700 directory permissions (no symlinks), and apply umask 077.
- PRECORE_BOOT_DETECT_B64_OPTS: Execute _detect_base64_opts.

-------------------------------------------------------------------------------
PRECORE_RUN (runtime primitives: history, manifest, session, cache)
-------------------------------------------------------------------------------
Purpose
Provide atomic, lock-protected runtime primitives for history rotation, multimodal
manifest staging, session NDJSON handling, and session cache.

Key primitives (documented)
- rotate_history([timeout])
  Rotate history under HISTORY_LOCK using BASH4LLM_HISTORY_MAX_FILES, MAX_BYTES, and KEEP_DAYS.
- save_to_history(text)
  Atomically append/save history entry, update last_history.json via ui_state_write, call rotate_history.
- manifest_create(manifest_path, [timeout])
  Initialize new manifest JSON part-array and .b64 counterpart atomically with permissions 600.
- manifest_add_part(manifest, part_name, src_file, mime_type, [timeout])
  Stage source file as Base64, append details to manifest JSON under lock, and regenerate manifest.b64.
- manifest_read(manifest)
  Read and print manifest JSON contents, fallback to decoding .b64 if needed.
- _get_perm_string(path) / _get_owner(path)
  Retrieve file symbolic permissions and user ownership portably.
- getfile_signature(path)
  Generate integrity footprint: hash and/or file system metadata (device, inode, size, mtime, permissions, uid, gid).
- _is_world_writable(path)
  Check if a path is group/world writable (vulnerable to external writing).
- make_tmpdir()
  Create unique directory inside $BASH4LLM_TMPDIR under lock with permissions 700.
- _tmpf(type, base_dir, [prefix])
  Strict temp file (600) or directory (700) generator verifying path containment inside allowed tmp boundaries.
- session_validate_id(sid)
  Validate session ID structure (alphanumeric, ".", "-", "_" with length 1 to 128 characters).
- session_now_ts()
  Return current time as an ISO 8601 UTC timestamp.
- session_messages_tmp_path(session_id)
  Return path to temporary messages file inside RUN_TMPDIR.
- session_sanitize_cmd(cmd)
  Mask sensitive env variables, credentials, and API keys with [REDACTED], truncating strings to 256 characters.
- session_read_window(session_id, [window_size], out_file)
  Extract last N session lines from NDJSON file, build normalized messages array JSON, and update UI state.
- session_append(session_id, role, content, meta_json)
  Idempotent append: generate unique message_id, manage block marker (.lockdir), lock session file,
  append NDJSON line, update index, and write session metadata via ui_state_write.
- _session_hash(string)
  Generate SHA-256 hash or fallback to truncated Base64 if tools are missing.
- session_cache_key(sid, params)
  Generate cache key matching sid and SHA-256 of parameters.
- session_cache_get(sid, params, [out_file])
  Retrieve cached response; delete and return 1 if expired based on Unix epoch TTL first-line header.
- session_cache_set(sid, params, [ttl], [src_file])
  Write cache atomically with TTL expiration Unix timestamp as first line under session_cache (perms 600).
- session_cache_invalidate(sid, [params])
  Selectively or completely purge cache files for a given session.
- _normalize_bool_env()
  Convert boolean environment flags (ALLOW_API_CALLS, DRY_RUN, DEBUG) to normalized 0 or 1 integers.

Blocks of Code / Flows
- block_mkdir_session_cache: Allocate and configure $SESSION_CACHE_DIR with permissions 700.
- block_ensure_config_dir: Ensure configuration directory is present and accessible.
- block_ensure_run_tmpdir: Invoke ensure_run_tmpdir if BASH4LLM_SOURCE_ONLY=0.
- block_normalize_bool_env_call: Normalize environment flags.
- block_last_check_lines_default: Default LAST_CHECK_LINES to 50 if unset.

-------------------------------------------------------------------------------
PROVIDER (embedded: groq)
-------------------------------------------------------------------------------
Purpose
Provider-specific implementation for Groq-compatible API: payload builder,
non-streaming and streaming calls, models refresh and validation.

Key functions (documented)
- _cleanup_local_tmp(payload, b64, json)
  Securely remove local work files.
- buildpayload_groq() / buildpayloadgroq() (alias)
  Compile and write Groq-compatible JSON payload from variables (MODEL, TURE, MAX_TOKENS, and message sources:
  JSON_INPUT, MESSAGES_JSON, BUILD_MESSAGES_FILE, or CONTENT). Perform Base64 staging.
- call_api_groq()
  Sincronous HTTP call. Handles .b64 payload decoding, appends buffering parameters (stdbuf), builds curl headers with
  GROQ_API_KEY, isolates clean JSON outputs (cuts trailing non-JSON data), writes RESP (600) or diagnostic JSON.
- call_api_streaming_groq() / call_api_streaming_groq_legacy() (alias)
  Streaming HTTP SSE call. Pipeline processing of SSE streams, incremental print of tokens to stdout, writes raw stream
  and chunk accumulators under RUN_TMPDIR, compiles final RESP, and updates last_api.json.
- refresh_models_groq() / refreshmodelsgroq() (alias)
  Query /openai/v1/models, normalize names, enforce MAX_MODELS, and write MODELS_FILE atomically under lock (10s) in Base64.
- validate_model_groq(model) / validatemodelgroq() (alias)
  Validate requested model against local MODELS_FILE and support checks (is_supported_model).
- auto_select_model_groq() / autoselectmodelgroq() (alias)
  Extract first supported text-only model from local models file and print to stdout.

Blocks of Code / Flows
- GROQ_API_KEY_override: Override GROQ_API_KEY with PROVIDER_API_ENV_groq if defined in the active environment.

-------------------------------------------------------------------------------
CORE_SETUP (CLI, model resolution, request orchestration)
-------------------------------------------------------------------------------
Purpose
Normalize CLI and env flags, resolve FINAL_MODEL, dispatch to provider functions,
handle retries, extract text from RESP, detect edge cases, and finalize output.

Key flows and functions (documented)
- call_provider(function_name, ...)
  Execute dynamic provider-specific function; returns status 127 if function is not loaded.
- refresh_models_dispatch([models_file])
  Dispatch model refresh routine to active provider, with fallback for backward-compatible signatures.
- validate_model_dispatch(model)
  Dispatch model validation; fall back to a permissive warning if provider validation is not implemented.
- resolve_model()
  Determine FINAL_MODEL by resolving priorities (highest to lowest):
    1) CLI -m/--model
    2) Persisted default model file: bash4llm.d/config/model.<provider>
    3) Provider auto-select (auto_select_model_<provider>())
    4) First supported model in local MODELS_FILE
    5) MODEL variable in bash4llm.d/config
    6) First supported entry in global ALLOWED_MODELS
  Returns non-zero on total resolution failure.
- build_payload_from_vars()
  Ensure RUN_TMPDIR is active, delegate to buildpayload_<PROVIDER>, and set payload variables.
- call_api_once() / call_api_streaming()
  Wrapper that respects DRY_RUN and delegates to call_api_<PROVIDER> or call_api_streaming_<PROVIDER>.
- extract_api_error()
  Inspect RESP JSON to parse formal error messages or extract plain error fragments.
- detect_empty_edge_case()
  Check RESP for empty text completions with status 200 (stop signal, zero tokens generated). Set BASH4LLM_EDGE_EMPTY=1
  and export request diagnostics.
- finalize_and_output(mode, text)
  Format output (json/pretty/raw/text). Automatically save results via save_to_history if content exceeds character
  THRESHOLD or if FORCE_SAVE_MODE is active.
- perform_request_once()
  Execute call_api_once with linear backoff retry loops (up to MAX_RETRIES). Extract text, detect empty completions,
  parse errors, update last_api.json, and finalize outputs.
- collect_input_from_files(file_list...)
  Concatenate source files with visual delimiters separating structures.
- expand_args_to_content(args...)
  Read existing files or append arguments literally to build prompt content.
- file_readable(path)
  Confirm file is regular and readable.
- trim(string)
  Remove leading and trailing whitespaces and tabs via awk.
- is_number(val)
  Verify string is a valid numeric value (integer or decimal).
- is_supported_model(model)
  Filter out non-textual model formats (vision, audio, whisper, tts, embedding, multimodal) to prevent errors.
- list_models_cli()
  Print local models to stderr, highlighting unsupported non-textual models.
- validate_model_core(model)
  Central validation routine: normalize names, verify against local files, and check is_supported_model.
- load_local_config()
  Parse the user configuration file (bash4llm.d/config/config) and populate operational variables.
- load_whitelist()
  Load allowed models into the global whitelist string $ALLOWED_MODELS.
- is_tty_out()
  Check if stdout is a real interactive terminal (TTY).

Blocks of Code / Flows
- parse_cli_arguments: Process parameters (inputs, batches, sessions, formats, providers, flags). Append unmatched positional arguments to $ARGS.
- source_session_engine: Dry-run and source the external session engine extension if available; set SE_AVAILABLE=1.
- verify_api_calls_and_rebuild_providers: Intercept network blocks and scan providers/ directory to rebuild $SUPPORTED_PROVIDERS.
- raw_listings: Intercept and fulfill immediate raw provider or model queries, exiting with status 0.
- immediate_actions: Process actions not requiring model calls (help, listings, default model persistence, extension installation).
- normalize_boolean_flags: Convert active flag configurations to pure 0 or 1 booleans.

-------------------------------------------------------------------------------
CORE_PROVIDER (discovery, selection, persistence)
-------------------------------------------------------------------------------
Purpose
Discover available providers (builtin + extras), persist provider choice, resolve provider URL and API key, and validate provider interface.

Key behaviors (documented)
- validate_provider_interface(provider)
  Verify that the loaded provider module defines the mandatory buildpayload_<p> and call_api_<p> functions.
- assemble_content()
  Build the prompt $CONTENT with strict priorities:
    1) Clear content if JSON_INPUT is defined.
    2) Concatenate files from FILE_INPUTS and append pos args.
    3) Apply TEMPLATE placeholders (replacing {{CONTENT}} with the prompt).
    4) Use captured standard input ($STDIN_CONTENT).
    5) Fall back to expanding $ARGS.

Blocks of Code / Flows
- CORE_PROVIDER_PRO_LOAD_INITIALIZATION: Locate modules and resolve the active provider from CLI or configuration. Perform interactive selector menus, write choice to PROVIDER_FILE (600), invalidate old models/URLs, and trigger secure loading.
- CORE_PROVIDER_PRO_LOAD_VALIDATION_REFRESH: Validate the active provider interface. Trigger local model alignment (automatic background or manual CLI refresh requests) requiring provider API keys.
- CORE_PROVIDER_SHOW: Process diagnostics and settings configurations (print paths or render the configuration/integrity diagnostic checklist).
- CORE_PROVIDER_MAIN_RESOLVE: Handle BOOTSTRAP_ONLY halts, load configurations, resolve and validate the model, and capture standard input ($STDIN_CONTENT).
- CORE_PROVIDER_MAIN_EXECUTION: Run prompt assembly and parameter validation. Execute the three main operation tracks: BATCH processing, interactive CHAT_MODE loop (Ctrl+D capture), or Single Prompt standard execution.

-------------------------------------------------------------------------------
SESSION CACHE (explicit)
-------------------------------------------------------------------------------
Purpose
Reduce repeated work by caching session-derived payloads/responses.

Key points
- session_cache_key(sid, params) => sid|sha256(params_string).
- Cache file format: first line expiry_epoch; subsequent lines payload JSON.
- session_cache_get removes expired files and returns 0 on hit; session_cache_set writes atomically.
- Cache stored under ${BASH4LLM_CONFIG_DIR%/}/session_cache with perms 600.
- TTL enforced by expiry_epoch; invalidation via session_cache_invalidate() when session changes.

-------------------------------------------------------------------------------
HISTORY & MANIFEST (explicit)
-------------------------------------------------------------------------------
Purpose
Persist conversation history and multimodal manifests safely.

Key points
- save_to_history() writes entries atomically and updates last_history.json via ui_state_write.
- rotate_history() enforces BASH4LLM_HISTORY_MAX_FILES, BASH4LLM_HISTORY_MAX_BYTES, BASH4LLM_HISTORY_KEEP_DAYS under HISTORY_LOCK.
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
- Inputs: DRY_RUN, BASH4LLM_SKIP_NETWORK, BASH4LLM_ENFORCE_NO_NETWORK_IF_QUIET, QUIET, DEBUG.
- Behavior:
  - If DRY_RUN => block real network calls (simulate).
  - If BASH4LLM_SKIP_NETWORK=1 => block network.
  - If QUIET and BASH4LLM_ENFORCE_NO_NETWORK_IF_QUIET=1 => block network.
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
- detect_empty_edge_case() sets BASH4LLM_EDGE_EMPTY and related BASH4LLM_EDGE_* variables.
- perform_request_once() uses these signals to decide retry vs fail and logs a single structured diagnostic entry.

-------------------------------------------------------------------------------
UI STATE AND DIAGNOSTIC FILES
-------------------------------------------------------------------------------
Purpose
Expose provider capabilities and last API call state for UI/automation.

Key points
- ui_state_write(relpath, json) writes under $BASH4LLM_CONFIG_DIR/ui_state with perms 600.
- provider_capabilities.json written by load_provider_module() describing provider features.
- last_api.json written as fallback by CORE_SETUP when RESP exists; used by UI and automation.
- save_to_history() and finalize_and_output() update ui_state best-effort.

-------------------------------------------------------------------------------
CANONICAL VARIABLES (reference)
-------------------------------------------------------------------------------
Important names (use exact names):
BASH4LLM_DIR, BASH4LLM_EXTRAS_DIR, PROVIDERS_DIR, BASH4LLM_CONFIG_DIR,
MODELS_FILE, MODELS_LOCK, PROVIDER_FILE, RUN_TMPDIR, BASH4LLM_TMP_PAYLOAD,
PAYLOAD, RESP, ERRF, STREAM_MODE, DRY_RUN, DEBUG, QUIET, SESSION_ID,
SESSION_WINDOW, OUTPUT_MODE, FORCE_SAVE_MODE, THRESHOLD, MAX_RETRIES,
BASH4LLM_TMPDIR, BASH4LLM_HISTORY_DIR, BASH4LLM_LOCK_TIMEOUT_*,
BASH4LLM_ROTATE_HISTORY, BASH4LLM_HISTORY_MAX_FILES, BASH4LLM_HISTORY_MAX_BYTES,
BASH4LLM_HISTORY_KEEP_DAYS, ALLOWED_MODELS, MAX_MODELS, CURL_BASE_OPTS,
B64_WRAP_OPT, B64_DECODE_OPT, GROQ_API_KEY, PROVIDER_API_ENV_groq,
SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_DATE, SCRIPTDIR, CANONICAL_EXTRAS_DIR,
LEGACY_EXTRAS_DIR, BASH4LLM_MODELS_DIR, BASH4LLM_TEMPLATES_DIR, SESSION_DIR,
HISTORY_LOCK, TMP_LOCK, BASH4LLM_LOCK_TIMEOUT_TMP, BASH4LLM_LOCK_TIMEOUT_MODELS,
BASH4LLM_LOCK_TIMEOUT_HISTORY, LAST_CHECK_LINES, BOOTSTRAP_ONLY, SE_ENGINE_PATH,
SE_AVAILABLE, FINAL_MODEL, CONTENT, JSON_INPUT, BATCH_FILE, CHAT_MODE,
SET_DEFAULT_MODEL, REFRESH_MODELS, LIST_MODELS, OUT_PATH, SYSTEM_PROMPT,
MAX_TOKENS, MODEL, AUTO_POLICY, SUPPORTED_PROVIDERS, PROVIDER,
TURE (temperature alias), TEMPERATURE (recommended alias).

Error Code Constants & Direct Alias Mappings:
- BASH4LLM_ERR_NO_API_KEY (10) / BASH4LLMERRNOAPIKEY
- BASH4LLM_ERR_BAD_MODEL (11) / BASH4LLMERRBAD_MODEL
- BASH4LLM_ERR_CURL_FAILED (12) / BASH4LLMERRCURL_FAILED
- BASH4LLM_ERR_INVALID_JSON (13) / BASH4LLMERRINVALID_JSON
- BASH4LLM_ERR_NO_PROMPT (14) / BASH4LLMERRNO_PROMPT
- BASH4LLM_ERR_TMP (15) / BASH4LLMERRTMP
- BASH4LLM_ERR_API (16) / BASH4LLMERRAPI

Notes
- TURE is retained for backward compatibility; document TEMPERATURE as alias in user-facing docs.
- CURL_BASE_OPTS default: --silent --show-error --no-buffer --max-time 120.

-------------------------------------------------------------------------------
OPERATIONAL TIPS (concise)
-------------------------------------------------------------------------------
- To add a provider: install bash4llm.d/extras/providers/<prov>.sh implementing buildpayload_<prov> and call_api_<prov>.
- To refresh models: bash4llm --refresh-models (dispatches to refresh_models_<prov>).
- To debug model selection: check bash4llm.d/config/model.<provider>, bash4llm.d/models/models.txt, and MODEL env.
- Preflight checklist before release: verify perms (700/600), ensure _tmpf rejects /tmp, run static checks (bash -n) on provider modules, test enforce_network_policy with DRY_RUN.

-------------------------------------------------------------------------------
EXAMPLES (short)
-------------------------------------------------------------------------------
- Single prompt:
  bash4llm "Summarize this text"
- Refresh models (embedded groq):
  bash4llm --refresh-models
- Start session and append:
  bash4llm --session myid --append "User message"

-------------------------------------------------------------------------------
CHANGE NOTES (summary)
-------------------------------------------------------------------------------
This document is the authoritative core notes aligned to:
- bash4llm_lossless_logic_outline.txt
All critical primitives, structures, aliases, and invariants from the SPEC are documented above.

-------------------------------------------------------------------------------
END
DOC
