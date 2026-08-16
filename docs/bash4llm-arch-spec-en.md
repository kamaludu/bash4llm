# BASH4LLM⁺ SYSTEM TECHNICAL SPECIFICATION (v2.8.5+)  [🇮🇹](bash4llm-arch-spec.md) 🇬🇧

## SECTION 1: GENERAL ARCHITECTURE AND RELATIONSHIPS BETWEEN MACRO-SECTIONS

The Bash4LLM⁺ system is structured on a **Lean & Flat** architecture composed of **5 Macro-Sections (Level 0)** and **23 Flat Sections (Level 1)** without intermediate subsections. Runtime stability and integration are guaranteed by a dependency hierarchy, strict system requirements, and security constants enforced at the filesystem level.

```text
[PRECORE_BOOT] ──> [PRECORE_RUN] ──> [PROVIDER] ──> [CORE_SETUP] ──> [CORE_PROVIDER]
   (7 Sections)       (5 Sections)    (Groq Direct)   (7 Sections)       (4 Sections)
```

### 1.1 Dependencies between Sections
* **PRECORE_RUN**: Depends on `PRECORE_BOOT` for environment sanitization, canonical path resolution, environment variable management, security/integrity helpers (`BOOT_SECURITY`), the central network mediation function `_exec_curl_secure`, the exclusive lock acquisition utility (`lock_exec`), module integrity verification (`verify_module_integrity`), Ed25519 manifest signature validation (`_verify_manifest_signature`), and secure temporary directory initialization (`ensure_run_tmpdir`).
* **SECURITY EXTENSION (openssl-helper.sh)**: Optional extension loaded during bootstrap if enabled by `BASH4LLM_VAULT_ENABLED`. Provides in-memory API key decryption, mandatory Vault policy enforcement (`BASH4LLM_REQUIRE_VAULT`), and SSL hashing/diagnostic services.
* **SESSION ENGINE EXTENSION (session-engine.sh)**: Optional extension loaded during initial configuration for advanced thread management (segmentation, compression, and caching). If absent or disabled, the system executes a transparent fallback to core NDJSON logic.
* **PROVIDER**: Depends on `PRECORE_BOOT` and `PRECORE_RUN` for endpoint URL resolution, network authorization checks, secure HTTP execution via `_exec_curl_secure`, transactional payload staging, I/O buffering, and atomic writing of logs and UI states.
* **CORE_SETUP**: Depends on `PRECORE_BOOT`, `PRECORE_RUN`, and `PROVIDER` for provider-specific call dispatching, trust domain resolution (`builtin`, `vendor`, `local`), formal CLI parameter validation, syntactic whitelist extraction, initialization guard execution (`_lock_security_guards`), and external extension integration.
* **CORE_PROVIDER**: Depends on all preceding sections for secure loading of external provider modules, interactive menu initialization, model alignment, prompt assembly (`PROMPT_ASSEMBLY`), and execution pipeline dispatching management (`PIPELINE_EXEC`).

### 1.2 Mandatory System Requirements
Before allowing any processing, the core script verifies the presence in `PATH` of the following **23 essential binaries and utilities**. The absence of at least one causes immediate script termination with status code `15`:
1. `bash` • 2. `jq` • 3. `curl` • 4. `mktemp` • 5. `stat` • 6. `base64` • 7. `find` • 8. `awk` • 9. `sed` • 10. `grep` • 11. `xargs` • 12. `tr` • 13. `sort` • 14. `head` • 15. `wc` • 16. `tee` • 17. `date` • 18. `mv` • 19. `chmod` • 20. `cp` • 21. `rm` • 22. `printf` • 23. `comm`.
*Note: The `flock` utility is excluded from this validation loop to enable execution and automatic fallback on platforms that do not support it natively (such as Termux).*

### 1.3 Global Security and Filesystem Invariants
The Bash4LLM⁺ runtime enforces isolation and data protection rules across persistent and temporary storage to prevent privilege escalation, race conditions, environment hijacking, or directory traversal attacks:
* **Unified Network Mediation and Zero Secret Exposure (`argv`) [INV-1]**: All HTTP calls (synchronous, streaming, model refresh, and key validation) are routed through the central function `_exec_curl_secure()`. Authentication headers containing Bearer tokens or API keys are written strictly to isolated private temporary header files (`0600`) and forwarded to `curl` via File Descriptor redirection (`/dev/fd/3`), completely eliminating credential exposure in process argument vectors (`ps aux` / `/proc/<pid>/cmdline`).
* **Runtime Directory and Temporary File Isolation [INV-2]**: The primary directory `$BASH4LLM_TMPDIR` must reside entirely within the root directory `$BASH4LLM_DIR`. The use of the operating system's global `/tmp` directory is strictly prohibited. Process operations reside in `$BASH4LLM_RUN_DIR` (`var/run`), lock files in `$BASH4LLM_LOCKS_DIR` (`var/run/locks`), and rate limiting tracking in `$BASH4LLM_RATES_DIR` (`tmp/rates`).
* **Startup Environment Sanitization and `eval` Prohibition [INV-3]**: At bootstrap initialization, the Core performs proactive environment sanitization by removing risky variables (`unset BASH_ENV ENV CDPATH GLOBIGNORE`). Introducing new `eval` constructs is prohibited. The single preexisting `eval` for signal trap restoration is isolated and documented.
* **Fail-Closed Module Cryptographic Integrity and Ed25519 Signature [INV-4]**: Any extension, external provider module, or hook script must belong to the current executing user, must not have public or group write permissions (`group/world-writable`), must pass SHA-256 hash verification against `extras/manifest.sha256`, and must pass Ed25519 cryptographic signature validation (`manifest.sha256.sig`). Any mismatch causes immediate runtime termination with error code `BASH4LLM_ERR_SEC` (17).
* **Read-Only Initialization Guards**: At the conclusion of the bootstrap phase, the `_lock_security_guards()` function marks all security, mediation, and filesystem management functions (`_exec_curl_secure`, `verify_module_integrity`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `read_secure_input`, `enforce_network_policy`, `execute_isolated_hook`) as `readonly -f`, preventing in-memory function overwriting or deletion.
* **Filesystem Invariant for Atomicity [INV-5]**: Every atomic write operation is executed by writing to a temporary file located within the same filesystem (same physical partition) as the final destination file. This guarantees that the move (`mv`) translates into a single atomic system call at the inode level.

---

## SECTION 2: PRECORE_BOOT

This macro-section handles primary shell initialization, environment sanitization, early CLI argument inspection, operating environment validation, path security, and the exposition of core logging, encoding, and I/O functions. It is divided into **7 Flat Sections**.

### 2.1 PRECORE_BOOT Variables
* **SCRIPT_NAME**: Program identifier name (constant: `"bash4llm"`).
* **SCRIPT_VERSION**: Current software version (constant: `"2.8.5"`).
* **SCRIPT_DATE**: Software release date (constant: `"2026-08-07"`).
* **BASH4LLM_SUPPORTED_PROVIDER_API**: Provider API version contract supported by the core (exported constant: `1`).
* **Global Error Constants**:
    * `BASH4LLM_ERR_NO_API_KEY` (Value `10`): Absence of a valid API key.
    * `BASH4LLM_ERR_BAD_MODEL` (Value `11`): Unsupported, invalid, or excluded model.
    * `BASH4LLM_ERR_CURL_FAILED` (Value `12`): Network failure or curl error.
    * `BASH4LLM_ERR_PARSE` (Value `13`): JSON parsing error, or response syntactic/SML validation failure.
    * `BASH4LLM_ERR_NO_PROMPT` (Value `14`): Absence of prompt text or input JSON.
    * `BASH4LLM_ERR_TMP` (Value `15`): I/O, permissions, or lock error on temporary files.
    * `BASH4LLM_ERR_API` (Value `16`): Application error or invalid HTTP code returned by the API.
    * `BASH4LLM_ERR_SEC` (Value `17`): Violation of security policies, permissions, signing, or integrity failure.
* **Constant Aliases**: `BASH4LLMERR_NO_API_KEY` (10), `BASH4LLMERR_BAD_MODEL` (11), `BASH4LLMERR_CURL_FAILED` (12), `BASH4LLMERR_PARSE` (13), `BASH4LLMERR_NO_PROMPT` (14), `BASH4LLMERR_TMP` (15), `BASH4LLMERR_API` (16), `BASH4LLMERR_SEC` (17).
* **Read Variables**:
    * `DEBUG`, `BASH4LLM_DEBUG`: Development trace configuration.
    * `BASH4LLM_DIR`, `BASH4LLM_ROOT`: Root installation path.
    * `BASH4LLM_CONFIG_DIR`, `BASH4LLM_MODELS_DIR`, `BASH4LLM_TEMPLATES_DIR`, `BASH4LLM_HISTORY_DIR`, `BASH4LLM_TMPDIR`, `BASH4LLM_RUN_DIR`, `BASH4LLM_LOCKS_DIR`, `BASH4LLM_RATES_DIR`, `BASH4LLM_EXTRAS_DIR`, `PROVIDERS_DIR`, `BASH4LLM_LOCAL_EXTRAS_DIR`, `LOCAL_PROVIDERS_DIR`: Operational working directories (vendor and local).
    * `BASH4LLM_GUI_NO_BROWSER`: Boolean flag (1 or 0) to disable automatic browser launching by the WebApp GUI.
    * `MAX_STAGE_BYTES`: Maximum byte threshold for Base64 payloads (default `10485760` bytes, equal to 10MB).
    * `MAX_MODELS`: Maximum limit of local models (default `200`).
    * `BASH4LLM_LOG`: Centralized trace log file path.
    * `BASH4LLM_LOCK_TIMEOUT_TMP`, `BASH4LLM_LOCK_TIMEOUT_MODELS`, `BASH4LLM_LOCK_TIMEOUT_HISTORY`: Timeouts for exclusive locks (default `10` seconds).
    * `BASH4LLM_VAULT_ENABLED`: Controls activation of the OpenSSL encrypted Key Vault extension (default `1`).
    * `BASH4LLM_REQUIRE_VAULT`: When set to 1, enforces mandatory retrieval of keys from the encrypted Vault.
    * `BASH4LLM_REQUIRE_MANIFEST_SIG`: When set to 1, enforces mandatory presence and validity of the manifest Ed25519 signature.
    * `BASH4LLM_IGNORE_SEC_CHECKS`: Bypasses POSIX ownership checks when set to 1 (useful for WSL/Cygwin).
* **Written/Modified Variables**:
    * `SCRIPTDIR`: Absolute resolution of the script path.
    * `BASH4LLM_CORE_SCRIPT`: Authoritative canonical path to the `bash4llm` core script exported for wrappers.
    * `CANONICAL_EXTRAS_DIR`, `LEGACY_EXTRAS_DIR`, `CANONICAL_LOCAL_EXTRAS_DIR`: Normalized physical and local extension paths.
    * `MODELS_FILE`: Local model whitelist file (`<provider>.txt`).
    * `PROVIDER_FILE`: Local file containing the active selected provider (`provider`).
    * `THREAD_DIR`: Directory storing thread NDJSON logs (`history/threads`).
    * `MODELS_LOCK`, `HISTORY_LOCK`, `TMP_LOCK`: Paths to respective exclusive lock files under `var/run/locks`.
    * `B64_WRAP_OPT`, `B64_DECODE_OPT`: Detected formatting flags for the `base64` command.
    * `RUN_TMPDIR`, `PAYLOAD`, `RESP`, `ERRF`: Instance runtime temporary channels and directories.
    * `BASH4LLM_OPENSSL_ACTIVE`: Boolean flag asserting the operational availability of the OpenSSL module.
    * `SAFE_THREAD_ID`: Thread identifier cryptographically anonymized via SHA-256/MD5.
    * `BASH4LLM_KEY_MANUAL_PROMPT`: Tracks manual TTY API key entry to activate the persistence reminder.
    * `VALIDATE_SML`, `VALIDATE_REGEX`, `SANITIZE_OUTPUT`, `JSON_DIAGNOSTICS`: Activation flags for Deterministic Extensions.

### 2.2 Functional Mapping by Section in PRECORE_BOOT

#### Section 1: `PRECORE_BOOT_SETUP_SHELL`
* **Activities**: Enforces `set -euo pipefail` only when the script is executed directly to avoid polluting the user's interactive shell during sourcing. Performs environment sanitization (`unset BASH_ENV ENV CDPATH GLOBIGNORE`), disables core dumps (`ulimit -c 0`), performs platform autodection (Android/Termux, macOS, WSL, Cygwin, BSD, Linux), resets deterministic extension states, and defines error constants and ANSI color codes (with `NO_COLOR` support).

#### Section 2: `PRECORE_BOOT_SETUP_ENV_CMDS`
* **Activities**: Validates Bash version ($\ge 4.0$) and the presence in `PATH` of the 23 mandatory binaries.

#### Section 3: `PRECORE_BOOT_EARLY_UTILITIES`
* **Functions**: `resolve_script_dir`, `safe_mkdir`, `check_required_arg`, `canonical_config_dir`, `canonical_provider_file`, `canonical_model_file`, `canonical_provider_url_file`, `trim_space`, `_is_readonly_func`, `sync_models_file_path`, `_normalize_model_name`, `is_truthy`, `_extract_notes_section`, `emit_json_diagnostics`, `log_prefix`, `log_info`, `log_warn`, `log_error`, `log_info_user`, `dbg`.
* **Activities**: Foundational utilities for path calculation, string manipulation, model normalization associative caching (`BASH4LLM_MODEL_CACHE`), Zero-Eval documentation parsing, structured JSON diagnostic emission (`emit_json_diagnostics`), and coordinated logging engine.

#### Section 4: `PRECORE_BOOT_SECURITY`
* **Functions**: `read_secure_input`, `validate_file_input`, `_get_perm_string`, `_get_owner`, `validate_path_security`, `_core_sha256`, `verify_module_integrity`, `_provider_env_snapshot`, `_provider_env_restore`, `_verify_manifest_signature`, `ensure_api_key_for_provider`, `enforce_network_policy`.
* **Activities**: Complete isolation of security mechanisms: null-byte/control character validation, silenced TTY input (`stty -echo`), POSIX permission and ownership checks, SHA-256 cryptographic verification and Ed25519 strictly *fail-closed* signature verification against the manifest, execution environment snapshot/restore, secure API key resolution (with Key Vault integration), and network policy enforcement.

#### Section 5: `PRECORE_BOOT_DIR_PATH`
* **Functions**: `ensure_config_dir`, `write_provider_url_if_missing`, `resolve_provider_url`.
* **Activities**: Physical initialization of working directory trees (`var/run`, `locks`, `tmp`), loading of OpenSSL helper if present, and transactional resolution/registration of provider connection URLs.

#### Section 6: `PRECORE_BOOT_STORAGE_LOCKS`
* **Functions**: `provider_api_env_var_name`, `print_persistence_reminder`, `is_valid_json_string`, `b64encode`, `b64decode`, `file_size`, `is_valid_json_file`, `stage_b64`, `lock_exec`, `_mktemp_in_dir`, `show_payload_head`, `atomic_write`, `extract_text_from_resp`, `cleanup_run_tmp_on_exit`, `ensure_run_tmpdir`, `b64_atomic_write`, `b64_atomic_read`, `ui_state_write`, `run_static_config_check`, `explain_error_code`.
* **Activities**: High-performance I/O primitive management: Base64 encoding/decoding, payload staging, cross-process atomic locking (`lock_exec`), `$RUN_TMPDIR` lifecycle management, atomic filesystem writes, response text extraction, static configuration linter, and formal error code explanation.

#### Section 7: `PRECORE_BOOT_CLI_HELPERS`
* **Functions**: `_resolve_provider_module_path`, `load_provider_module`, `_detect_base64_opts`, `_file_mtime`, `jq_safe`.
* **Activities**: Early interception of CLI diagnostic flags (`--check-config`, `--explain-error`, `--print-*`), `base64` option detection, provider domain resolution (`builtin`, `vendor`, `local`), lock constant definitions, and anti-TOCTOU staging copy loading of external provider modules with whitelist filtering on exported functions (`load_provider_module`).

---

## SECTION 3: PRECORE_RUN

This macro-section manages long-term persistence, history rotation, multimodal attachment manifests, the central network engine `_exec_curl_secure`, and the unified NDJSON thread engine. It is divided into **5 Flat Sections**.

### 3.1 PRECORE_RUN Variables
* **Read Variables**:
    * `BASH4LLM_ROTATE_HISTORY`: Activates automatic history maintenance and rotation (default `0`).
    * `BASH4LLM_HISTORY_MAX_FILES` (default `100`), `BASH4LLM_HISTORY_MAX_BYTES` (default 100MB), `BASH4LLM_HISTORY_KEEP_DAYS` (default `90`).
    * `THREAD_ID`: Active thread identifier.
    * `SAFE_THREAD_ID`: Thread identifier cryptographically anonymized via SHA-256/MD5.
    * `THREAD_WINDOW`: Size of the historical message window to retrieve (default `10`).
    * `BASH4LLM_RATE_LIMIT`: API request limit per thread within the 30s sliding window (default `unlimited`).
    * `BASH4LLM_AUTH_TOKEN`: Authorized secret token to bypass the local rate limiter.
    * `FALLBACK_PAYLOAD`: Base64-encoded fallback payload returned by hooks upon API errors.
    * `TRANSFORMED_PAYLOAD`: Base64-encoded transformed payload returned by post-execution hooks.
    * `BASH4LLM_SESSION_ENGINE`: Controls activation of the advanced session management module (default `"on"`).
* **Written/Modified Variables**:
    * `THREAD_DIR`: Directory path storing thread NDJSON files (`history/threads`).
    * `BASH4LLM_RATES_DIR`: Directory tracking rate limiter transactions (`tmp/rates`).
    * Updates to registers and metadata under `ui_state/threads/`.

### 3.2 Functional Mapping by Section in PRECORE_RUN

#### Section 1: `PRECORE_RUN_HISTORY`
* **Functions**: `rotate_history`, `save_to_history`.
* **Activities**: Disk output saving and O(N) rotation engine based on file count limits, cumulative byte size, and retention days.

#### Section 2: `PRECORE_RUN_MANIFEST`
* **Functions**: `manifest_create`, `manifest_add_part`, `manifest_read`.
* **Activities**: Lock-protected creation and updating of JSON/Base64 manifests for multimodal attachment handling.

#### Section 3: `PRECORE_RUN_UTIL_HELPERS`
* **Functions**: `anonymize_thread_id`, `execute_isolated_hook`, `_get_file_signature`, `getfile_signature`, `_is_world_writable`, `_locked_history_save`, `_locked_manifest_create`, `_locked_manifest_add_part`, `check_local_rate_limit`, `make_tmpdir`, `_tmpf`.
* **Activities**: Strict PII anonymization (SHA-256 hashing of `THREAD_ID`), sandboxing for `pre`/`post` hook execution with Zero-Eval whitelist parsing, file status signature checks, 30s sliding window local rate limiter, and protected temporary allocation.

#### Section 4: `PRECORE_RUN_THREAD_ENGINE`
* **Functions**: `thread_validate_id`, `thread_now_ts`, `thread_messages_tmp_path`, `thread_sanitize_cmd`, `_update_thread_index`, `_thread_delete_locked`, `thread_delete_core`, `_thread_rename_locked`, `thread_rename_core`, `acquire_thread_lock`, `release_thread_lock`, `_thread_read_window_locked`, `thread_read_window`, `thread_append`, `_thread_hash`, `thread_cache_key`, `thread_cache_get`, `thread_cache_set`, `thread_cache_invalidate`.
* **Activities**: **Unified Thread Management Engine**: includes ID validation, command sanitization with sensitive data redaction (`[REDACTED]`), CRUD operations (NDJSON message window reading, idempotent appending with message ID, atomic renaming, and deletion), concurrency control via exclusive locks, and TTL-based response caching.

#### Section 5: `PRECORE_RUN_RUNTIME_GLOBALS`
* **Functions**: `_normalize_bool_env`, `_exec_curl_secure`.
* **Activities**: Global state variable initialization and definition of the **central network mediation function `_exec_curl_secure()`**, which guarantees authentication token isolation in `0600` temporary header files and File Descriptor redirection (`/dev/fd/3`) to eliminate secret leaks in `argv`.

---

## SECTION 4: SECURITY EXTENSION (openssl-helper.sh)

Optional extension (located in `extras/security/`) enabled by default if the `openssl` binary is present. Provides API credential management via multi-layered encryption with a master password.

### 4.1 Vault Support Files
* `keys.enc`: Contains the internal symmetric unlocking key (*Vault Key*) encrypted with the user's Master Password.
* `keys.rec`: Contains the same *Vault Key* encrypted with a random 128-bit hexadecimal offline recovery key (*Recovery Key*).
* `keys.dat`: Contains the actual JSON payload of all provider API keys, encrypted with the *Vault Key*.

### 4.2 Security Extension Functions
* **`_vault_read_password`**: Securely reads a password without terminal echo via `read_secure_input`.
* **`_vault_set_opts`**: Configures AES-256-CBC, salt, and PBKDF2 with 100,000 iterations.
* **`_vault_encrypt_to_file` / `_vault_decrypt_file`**: Atomic disk file encryption and decryption.
* **`vault_exists` / `vault_init`**: Checks state and initializes the Master Password and Recovery Key.
* **`vault_load_keys`**: Decrypts the JSON key database in memory using session token `_B4L_RT_CTX`.
* **`vault_change_password`**: Changes Master Password and re-encrypts Vault Key while generating a new recovery token.
* **`vault_destroy`**: Secure physical destruction of encrypted files via `shred` or zero overwriting (`dd`).
* **`vault_recover`**: Restores Vault access using the offline hexadecimal *Recovery Key*.
* **`vault_manage_keys` / `vault_console`**: Interactive CLI key management interface activated by the `--vault` option.
* **`_secure_hash_sha256`**: Calculates SHA-256 hash for pre-sourcing integrity checks.
* **`diagnose_tls_connection`**: Executes a test handshake via `openssl s_client` against port 443 of the endpoint to verify the TLS chain.

---

## SECTION 5: SESSION ENGINE EXTENSION (session-engine.sh)

Optional session optimization extension (located in `extras/session/`). Manages automatic NDJSON log segmentation, compression, and reactive context construction via in-process caching.

### 5.1 Session Engine Functions
* **`_se_list_segments`**: Returns the sorted list of session NDJSON segments (e.g. `chat1.001.ndjson`).
* **`_se_segment_rotate_if_needed`**: When the log exceeds `$BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (1MB), rotates the file to the next segment and applies `gzip` compression to older blocks.
* **`session_engine_append`**: Appends a message with automatic deduplication within the `BASH4LLM_SESSION_DEDUP_WINDOW` (20 lines) and clears read cache.
* **`session_engine_build_window`**: Compiles context window for the model:
    * Returns data from cache if valid against `SESSION_CACHE_TTL_SEC` (30s).
    * **N > 0**: Extracts exactly the last N messages.
    * **N = 0**: Calculates byte size and accumulates messages up to `$BASH4LLM_SESSION_TARGET_BYTES` (32KB).
* **`session_engine_snapshot`**: Generates a JSON telemetry report with statistics, active segments, last 50 lines, and conversation summaries.

---

## SECTION 6: PROVIDER (embedded: groq)

This macro-section encompasses the Groq provider implementation built into the Core.

### 6.1 Groq Module Functions
* **`buildpayload_groq`**: Compiles the OpenAI-compatible JSON payload file reading user input (`CONTENT`, `JSON_INPUT`, `SYSTEM_PROMPT`, or `BUILD_MESSAGES_FILE`), sets temperature and max tokens, producing `$PAYLOAD` (with optional Base64 staging).
* **`call_api_groq`**: Synchronous non-streaming HTTP call routed via `_exec_curl_secure()`: isolates the API key in a secure temporary header file with File Descriptor redirection and saves the response in `$RESP`.
* **`call_api_streaming_groq`**: Real-time SSE streaming connection via `_exec_curl_secure()`: processes stream in real time with `tee` and `jq --unbuffered`, outputs tokens to `stdout`, compiles final synthetic JSON into `$RESP`, and updates `last_api.json`.
* **`validate_key_groq`**: Rapid diagnostic test (10s timeout) against the `/models` endpoint via `_exec_curl_secure()` to validate API key.
* **`auto_select_model_groq` / `validate_model_groq` / `refresh_models_groq`**: Manage automatic selection of first valid choice, local validation, and synchronization of the model catalog in `$MODELS_FILE` via `_exec_curl_secure()`.

---

## SECTION 7: CORE_SETUP

Handles command-line parameter parsing (CLI), dispatching interface, whitelisting, `readonly -f` guard registration, and proactive action resolution. It is divided into **7 Flat Sections**.

### 7.1 Functional Mapping by Section in CORE_SETUP

#### Section 1: `CORE_SETUP_DISPATCH_HELPERS`
* **Functions**: `validate_provider_interface`, `call_provider`, `validate_provider_key_dispatch`, `refresh_models_dispatch`, `validate_model_dispatch`, `auto_select_model_dispatch`, `_lock_security_guards`.
* **Activities**: Dynamic dispatching interface and execution of **`_lock_security_guards()`** to mark security and mediation functions as `readonly -f` at the conclusion of bootstrap.

#### Section 2: `CORE_SETUP_API_CALL`
* **Functions**: `resolve_model`, `build_payload_from_vars`, `call_api_once`, `call_api_streaming`, `extract_api_error`, `detect_empty_edge_case`, `finalize_and_output`, `validate_response_syntax`, `perform_request_once`.
* **Activities**: Request execution wrapper: resolves final model choice (`FINAL_MODEL`), handles linear backoff retry loops on error (`$MAX_RETRIES`), performs syntactic response validation (`validate_response_syntax` with SML v2.0 or REGEX verification), intercepts empty responses, and manages output formatting (`json`, `pretty`, `text`, `raw`) with sanitization filtering (`--sanitize`) and automatic saving if exceeding `$THRESHOLD`.

#### Section 3: `CORE_SETUP_INPUT_HELPERS`
* **Functions**: `collect_input_from_files`, `expand_args_to_content`, `file_readable`, `is_supported_model`, `list_models_cli`, `validate_model_core`, `load_local_config`, `load_whitelist`, `is_tty_out`, `_cleanup_sourced_env`.
* **Activities**: Input collection and expansion from `-f` files, input readability and security validation (`validate_file_input`), supported model linter, local configuration loading, and interactive sourcing protection with Vault unlocking.

#### Section 4: `CORE_SETUP_CLI_PARSE`
* **Activities**: Main CLI argument parsing loop (`while [ $# -gt 0 ]`), flag interpretation, immediate thread ID anonymization (`anonymize_thread_id`), handling validation and diagnostic options (`--validate-sml`, `--validate-regex`, `--sanitize`, `--json-diagnostics`), atomic active provider resolution and persistence in `canonical_provider_file`, and automatic loading of the corresponding module.

#### Section 5: `CORE_SETUP_SESSION_ENGINE`
* **Activities**: Attempts import and integrity verification of `extras/session/session-engine.sh`. Upon successful verification, activates `_engine_available=1`, otherwise triggers automatic fallback to core NDJSON logic.

#### Section 6: `CORE_SETUP_NORM_FLAGS`
* **Activities**: Normalization of raw export CLI flags and local provider/model listing (`--list-providers`, `--list-providers-raw`, `--list-models-raw`).

#### Section 7: `CORE_SETUP_ACTIONS`
* **Activities**: Immediate execution of non-network CLI commands: thread deletion (`--delete-thread`), thread renaming (`--rename-thread`), manual initialization (`--init-thread`), provider and model listing, default model persistence (`--set-default`), Vault console launch (`--vault`), **delegation of WebApp GUI launch (`--gui`/`--webapp`) to `extras/gui-py/gui-py.sh`**, Master Test Suite execution (`--run-all-tests`), and `extras` package installation/synchronization with SHA-256 manifest integrity verification and Ed25519 signature with hardened permissions (`700`/`600`, with `0700` for `gui-py/gui-py.sh`).

---

## SECTION 8: CORE_PROVIDER

Manages interactive interaction, complex prompt assembly, and final dispatching to execution pipelines. It is divided into **4 Flat Sections**.

### 8.1 Functional Mapping by Section in CORE_PROVIDER

#### Section 1: `CORE_PROVIDER_PRO_LOAD`
* **Activities**: Handles interactive provider selection when `--provider` is passed without arguments or with `list`. Presents a numbered terminal menu, persists choice, and loads the selected provider module.

#### Section 2: `CORE_PROVIDER_SHOW`
* **Activities**: Executes early display CLI commands and terminates execution: prints configuration paths (`--print-*`), displays active variables (`--show-config`), or runs full self-diagnostic audit with provider TLS handshake tests and extension states (`--diagnostics`).

#### Section 3: `CORE_PROVIDER_PROMPT_ASSEMBLY`
* **Functions**: `assemble_content`.
* **Activities**: **Context Preparation and Assembly**:
    1. Triggers automatic model refresh if requested or if local catalog is empty.
    2. Synchronizes thread ID anonymization to `$SAFE_THREAD_ID`.
    3. Loads configuration and local whitelist.
    4. Ensures existence of `$RUN_TMPDIR`.
    5. Resolves and formally validates final model (`MODEL`).
    6. Intercepts and extracts data from standard input (`stdin`), sanitizing and redacting API keys passed via JSON.
    7. Executes `assemble_content()` to concatenate input files (`-f`), CLI prompts, or expand `{{CONTENT}}` placeholders in template files (`--template`).
    8. Validates that prompt content is non-empty, aborting with error `BASH4LLM_ERR_NO_PROMPT` (14) upon failure.

#### Section 4: `CORE_PROVIDER_PIPELINE_EXEC`
* **Activities**: **Pipeline Dispatching and Execution**:
    * **Branch A - BATCH Cycle (`--batch`)**: Scans file line by line, retrieves thread session window via Session Engine or NDJSON fallback, builds payload, and runs requests sequentially, displaying persistence reminder (`print_persistence_reminder`).
    * **Branch B - CHAT Mode (`--chat`/`--tui`)**: Verifies cryptographic integrity of `extras/chat/tui-repl.sh` via `verify_module_integrity`, exports environment variables, and transfers process control (`exec bash`) to the interactive REPL interface.
    * **Branch C - Single Request (SSE Streaming / Synchronous)**: Prepares thread history file, builds payload via `build_payload_from_vars`, ensures API key presence (via Vault or TTY prompt), and executes HTTP call (streaming via `call_api_streaming` or synchronous via `perform_request_once`). Upon successful completion, securely appends user prompt and assistant response to thread log.

---

## SECTION 9: FILESYSTEM STRUCTURE AND MEMORY LAYOUT

To guarantee data persistence, domain isolation, and security integration, the `bash4llm.d/` runtime directory and extension domains are structured as follows:

```text
bash4llm.d/
├── config/                                # Configuration and provider persistence (700)
│   ├── config                             # User global variables and parameters (600)
│   ├── provider                           # Persists active provider name (600)
│   ├── provider-url                       # Persists active provider API URL (600)
│   ├── model.<provider>                   # Persists provider default model (600)
│   ├── keys.enc                           # Vault Key encrypted with Master Password (600)
│   ├── keys.rec                           # Vault Key encrypted with offline Recovery Key (600)
│   ├── keys.dat                           # Encrypted database containing JSON API keys (600)
│   ├── thread_cache/                      # Isolated TTL cache of thread windows (700)
│   ├── providers/                         # Directory for advanced configurations (700)
│   │   └── hf_endpoints                   # Hugging Face model/endpoint mappings
│   └── ui_state/                          # State directory for GUI and automations (700)
│       ├── last_api.json                  # State of the last API call (600)
│       ├── last_history.json              # State of the last saved output (600)
│       ├── provider_capabilities.json     # Active provider capability list (600)
│       └── threads/                       # Session indices and metadata (700)
│           ├── index.json                 # Structured list of active threads (600)
│           └── <safe_thread_id>.json      # Thread state metadata (SHA-256 anonymized)
├── models/                                # Local catalogs of permitted models (700)
│   └── <provider>.txt                     # Validated model whitelist (600)
├── templates/                             # Reusable prompt template storage (700)
├── history/                               # Response output archiving (700)
│   ├── threads/                           # Active thread NDJSON logs (Core fallback) (700)
│   │   └── <safe_thread_id>.ndjson        # SHA-256 anonymized NDJSON log (600)
│   └── sessions/                          # Advanced session NDJSON logs (Session Engine) (700)
│       ├── <safe_thread_id>.ndjson        # Primary anonymized NDJSON log (600)
│       ├── <safe_thread_id>.001.ndjson    # Rotated historical segment (600)
│       └── <safe_thread_id>.001.ndjson.gz # Rotated and compressed segment (600)
├── var/                                   # Isolated runtime processes and files (700)
│   └── run/                              # Process runtime directory (700)
│       └── locks/                         # Isolated lock files directory (700)
│           ├── models.lock                # Model synchronization lock
│           ├── history.lock               # History synchronization lock
│           └── tmp.lock                   # Temporary file allocation lock
├── tmp/                                   # Secure exclusive-access area (700)
│   ├── gui_uploads/                       # Temporary context files uploaded via WebUI (600)
│   └── rates/                             # Rate limiting transaction tracking (700)
│       └── <safe_thread_id>/              # Request timestamps for sliding window
├── local-extras/                          # User extensions untracked by network manifest (700)
│   └── providers/                         # User local provider modules (domain local:<name>) (700)
└── extras/                                # Official Vendor extensions installed via installer (700)
    ├── manifest.sha256                    # SHA-256 cryptographic integrity manifest (600)
    ├── manifest.sha256.sig                # Ed25519 cryptographic signature of manifest (600)
    ├── official-ed25519.pub               # Official public key for Ed25519 signature verification (600)
    ├── chat/                              # Text User Interface (TUI) REPL & Translations (700)
    │   ├── langs/                         # TUI internationalization files (.properties)
    │   │   ├── de.properties
    │   │   ├── en.properties
    │   │   ├── es.properties
    │   │   ├── fr.properties
    │   │   └── it.properties
    │   ├── SPEC-TUI.md                    # TUI module technical specification
    │   └── tui-repl.sh                    # Interactive CLI REPL entrypoint (700)
    ├── docs/                              # Documentation and reference shell modules
    │   ├── bash4llm-completion.sh         # Native shell autocompletion module
    │   ├── core-notes.sh                  # Core design notes and architecture
    │   ├── help.txt                       # Quick CLI help guide
    │   ├── manual-en.txt                  # Full user manual in English
    │   └── manual-it.txt                  # Full user manual in Italian
    ├── gui-py/                            # Python 3.10+ WebApp graphical interface (700)
    │   ├── gui-py.sh                      # Launcher CLI Wrapper (POSIX Bash 4.0+, 700)
    │   ├── main.py                        # Asynchronous Adapter Entrypoint (FastAPI + Uvicorn)
    │   ├── config.py                      # Dataclass, Runtime Settings, Temp Validation
    │   ├── models.py                      # Dataclass Job, State Enum, Termination Cause
    │   ├── security.py                    # T3 Tempdir Isolation, Advisory Lock, Host/CSRF
    │   ├── ipc.py                         # Subprocess Executor, Pipe I/O, SSE Dispatcher
    │   ├── static/                        # HTML5 SPA, Zero-framework CSS, app.js, help.html, error.html
    │   │   ├── index.html
    │   │   ├── help.html
    │   │   ├── error.html
    │   │   ├── style.css
    │   │   └── app.js
    │   └── langs/                         # Multilingual translations (.json)
    │       ├── de.json
    │       ├── en.json
    │       ├── es.json
    │       ├── fr.json
    │       └── it.json
    ├── hooks/                             # Extension modules and safety gate
    │   └── sml-gate.sh                    # Semantic Safety Gate (Structured Metadata Layout)
    ├── providers/                         # Vendor extension provider modules
    │   ├── gemini.sh
    │   ├── huggingface.md
    │   ├── huggingface.sh
    │   └── mistral.sh
    ├── security/                          # Security, encryption, and output sanitization
    │   ├── OPENSSL-HELPER.md
    │   ├── generate-manifest.sh           # Manifest generator and Ed25519 signer
    │   ├── openssl-helper.sh              # OpenSSL Encrypted Key Vault engine (600)
    │   └── output-sanitizer.sh            # Zero-Eval ANSI filter and output sanitizer (700)
    ├── session/                           # Advanced session management engine
    │   ├── README.md
    │   ├── session-engine.sh              # Main session engine script
    │   └── struttura.md
    └── test/                              # Automated test suite and hardening
        ├── README-tests.md
        ├── compatibility.sh
        ├── concurrency.sh
        ├── hardening.sh
        ├── help-test.txt
        ├── regression.sh
        ├── run-all-tests.sh               # Master Unified Automated Test Suite (700)
        ├── sanity.sh
        ├── scintilla-t3.sh                # SCINTILLA Core — T3 Test Suite
        └── stress.sh
```

---
