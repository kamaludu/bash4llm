# TECHNICAL SPECIFICATION OF THE BASH4LLM⁺ SYSTEM (v2.8.5)   [🇮🇹](bash4llm-arch-spec.md) 🇬🇧

## SECTION 1: GENERAL ARCHITECTURE AND RELATIONSHIPS BETWEEN MACRO-SECTIONS

The Bash4LLM⁺ system is structured on a **Lean & Flat** architecture composed of **5 Macro-Sections (Level 0)** and **23 Flat Sections (Level 1)** without intermediate sub-sections. The stability and integration of the runtime are guaranteed by a hierarchy of dependencies, strict system requirements, and security constants applied at the file-system level.

```text
[PRECORE_BOOT] ──> [PRECORE_RUN] ──> [PROVIDER] ──> [CORE_SETUP] ──> [CORE_PROVIDER]
   (7 Sections)       (5 Sections)    (Groq Direct)   (7 Sections)       (4 Sections)
```

### 1.1 Dependencies between Sections
* **PRECORE_RUN**: Depends on `PRECORE_BOOT` for environment sanitization, loading of canonical paths, environment variable management, security/integrity helpers (`BOOT_SECURITY`), the central network mediation function `_exec_curl_secure`, the utility for acquiring exclusive locks (`lock_exec`), module integrity verification (`verify_module_integrity`), Ed25519 manifest signature validation (`_verify_manifest_signature`), and secure initialization of the temporary directory (`ensure_run_tmpdir`).
* **SECURITY EXTENSION (openssl-helper.sh)**: Optional extension loaded during bootstrap if enabled by `BASH4LLM_VAULT_ENABLED`. Provides in-memory decryption of API keys, enforcement of mandatory Vault policy (`BASH4LLM_REQUIRE_VAULT`), and SSL hashing/diagnostic services.
* **SESSION ENGINE EXTENSION (session-engine.sh)**: Optional extension loaded during initial setup for advanced thread management (segmentation, compression, and caching). If absent or disabled, the system performs a transparent fallback to the core's NDJSON logic.
* **PROVIDER**: Depends on `PRECORE_BOOT` and `PRECORE_RUN` for endpoint URL resolution, network authorization verification, secure HTTP execution via `_exec_curl_secure`, transactional staging of payloads, I/O buffering, and atomic writing of logs and UI states.
* **CORE_SETUP**: Depends on `PRECORE_BOOT`, `PRECORE_RUN`, and `PROVIDER` for dispatching provider-specific calls, resolving trust domains (`builtin`, `vendor`, `local`), formal validation of CLI parameters, syntactic extraction of whitelists, execution of initialization guards (`_lock_security_guards`), and integration of external extensions.
* **CORE_PROVIDER**: Depends on all previous sections for protected loading of external provider modules, initialization of the interactive menu, alignment of models, prompt assembly (`PROMPT_ASSEMBLY`), and management of execution pipeline dispatching (`PIPELINE_EXEC`).

### 1.2 Mandatory System Requirements
Before allowing any processing, the core script verifies the presence in `PATH` of the following **23 essential binaries and utilities**. The absence of at least one of them causes the immediate termination of the script with status code `15`:
1. `bash` • 2. `jq` • 3. `curl` • 4. `mktemp` • 5. `stat` • 6. `base64` • 7. `find` • 8. `awk` • 9. `sed` • 10. `grep` • 11. `xargs` • 12. `tr` • 13. `sort` • 14. `head` • 15. `wc` • 16. `tee` • 17. `date` • 18. `mv` • 19. `chmod` • 20. `cp` • 21. `rm` • 22. `printf` • 23. `comm`.
*Note: The `flock` utility is excluded from this check loop to allow execution and automatic fallback on platforms that do not natively support it (such as Termux).*

### 1.3 Global Security and File-System Invariants
The Bash4LLM⁺ runtime enforces isolation and data protection rules for persistent and temporary data to prevent privilege escalation, race conditions, environment hijacking, or directory traversal attacks:
* **Unified Network Mediation and Zero Secret Exposure (`argv`) [INV-1]**: All HTTP calls (synchronous, streaming, model refresh, and key validation) are routed through the central function `_exec_curl_secure()`. Authentication headers containing Bearer tokens or API keys are written exclusively to isolated temporary header files (`0600`) and forwarded to `curl` via File Descriptor redirection (`/dev/fd/3`), preventing credential exposure in process argument vectors (`ps aux` / `/proc/<pid>/cmdline`).
* **Isolation of Temporary Files and Runtime Directories [INV-2]**: The main directory `$BASH4LLM_TMPDIR` must reside entirely within the root directory `$BASH4LLM_DIR`. The use of the system global `/tmp` directory is forbidden. Process operations reside in `$BASH4LLM_RUN_DIR` (`var/run`), lock files in `$BASH4LLM_LOCKS_DIR` (`var/run/locks`), and rate limiting tracking in `$BASH4LLM_RATES_DIR` (`tmp/rates`).
* **Environment Sanitization at Bootstrap and Prohibition of `eval` [INV-3]**: At bootstrap start, the Core performs preventive environment sanitization by unsetting high-risk variables (`unset BASH_ENV ENV CDPATH GLOBIGNORE`). The introduction of new `eval` constructs is forbidden. The only pre-existing `eval` for signal trap restoration is isolated and documented.
* **Cryptographic Integrity of Fail-Closed Modules and Ed25519 Signature [INV-4]**: Any extension, external provider module, or hook script must belong to the current executing user, must not have public or group write permissions (`group/world-writable`), must pass SHA-256 hash verification against `extras/manifest.sha256`, and validation of the Ed25519 cryptographic signature (`manifest.sha256.sig`). Any discrepancy causes an immediate runtime halt with error code `BASH4LLM_ERR_SEC` (17).
* **Read-Only Initialization Guards**: At the end of the bootstrap phase, the `_lock_security_guards()` function marks all security, mediation, and filesystem management functions (`_exec_curl_secure`, `verify_module_integrity`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `read_secure_input`, `enforce_network_policy`, `execute_isolated_hook`) as `readonly -f`, preventing their overwriting or deletion in memory.
* **File-System Invariant for Atomicity [INV-5]**: Every atomic write operation is performed by writing to a temporary file located within the same file-system (same physical partition) as the final destination file. This ensures that moving (`mv`) translates into a single atomic system call at the inode level.

---

## SECTION 2: PRECORE_BOOT

This macro-section handles primary shell initialization, environment sanitization, preventive CLI argument parsing, operational environment validation, path security, and exposure of fundamental logging, encoding, and I/O functions. It is divided into **7 Flat Sections**.

### 2.1 Variables of PRECORE_BOOT
* **SCRIPT_NAME**: Program identification name (constant: `"bash4llm"`).
* **SCRIPT_VERSION**: Current software version (constant: `"2.8.5"`).
* **SCRIPT_DATE**: Software release date (constant: `"2026-08-07"`).
* **BASH4LLM_SUPPORTED_PROVIDER_API**: Provider API contract version supported by the core (exported constant: `1`).
* **Global Error Constants**:
    * `BASH4LLM_ERR_NO_API_KEY` (Value `10`): Absence of a valid API key.
    * `BASH4LLM_ERR_BAD_MODEL` (Value `11`): Unsupported, invalid, or excluded model.
    * `BASH4LLM_ERR_CURL_FAILED` (Value `12`): Network failure or curl error.
    * `BASH4LLM_ERR_PARSE` (Value `13`): JSON parsing error, or response syntax/SML validation failure.
    * `BASH4LLM_ERR_NO_PROMPT` (Value `14`): Absence of text prompt or input JSON.
    * `BASH4LLM_ERR_TMP` (Value `15`): I/O error, permissions, or lock error on temporary files.
    * `BASH4LLM_ERR_API` (Value `16`): Application error or invalid HTTP code sent by APIs.
    * `BASH4LLM_ERR_SEC` (Value `17`): Violation of security policies, permissions, signing, or integrity failure.
* **Constant Aliases**: `BASH4LLMERR_NO_API_KEY` (10), `BASH4LLMERR_BAD_MODEL` (11), `BASH4LLMERR_CURL_FAILED` (12), `BASH4LLMERR_PARSE` (13), `BASH4LLMERR_NO_PROMPT` (14), `BASH4LLMERR_TMP` (15), `BASH4LLMERR_API` (16), `BASH4LLMERR_SEC` (17).
* **Read Variables**:
    * `DEBUG`, `BASH4LLM_DEBUG`: Development trace configuration.
    * `BASH4LLM_DIR`, `BASH4LLM_ROOT`: Installation root path.
    * `BASH4LLM_CONFIG_DIR`, `BASH4LLM_MODELS_DIR`, `BASH4LLM_TEMPLATES_DIR`, `BASH4LLM_HISTORY_DIR`, `BASH4LLM_TMPDIR`, `BASH4LLM_RUN_DIR`, `BASH4LLM_LOCKS_DIR`, `BASH4LLM_RATES_DIR`, `BASH4LLM_EXTRAS_DIR`, `PROVIDERS_DIR`, `BASH4LLM_LOCAL_EXTRAS_DIR`, `LOCAL_PROVIDERS_DIR`: Operational working directories (vendor and local).
    * `MAX_STAGE_BYTES`: Maximum byte threshold for Base64 payloads (default `10485760` bytes, equal to 10MB).
    * `MAX_MODELS`: Maximum limit of local models (default `200`).
    * `BASH4LLM_LOG`: Path of the centralized trace log file.
    * `BASH4LLM_LOCK_TIMEOUT_TMP`, `BASH4LLM_LOCK_TIMEOUT_MODELS`, `BASH4LLM_LOCK_TIMEOUT_HISTORY`: Timeout for exclusive locks (default `10` seconds).
    * `BASH4LLM_VAULT_ENABLED`: Controls activation of the OpenSSL encrypted Vault extension (default `1`).
    * `BASH4LLM_REQUIRE_VAULT`: If set to 1, enforces mandatory key retrieval from the encrypted Vault.
    * `BASH4LLM_REQUIRE_MANIFEST_SIG`: If set to 1, makes presence and validity of the Ed25519 manifest signature mandatory.
    * `BASH4LLM_IGNORE_SEC_CHECKS`: Ignores POSIX ownership checks if set to 1 (useful for WSL/Cygwin).
* **Written/Modified Variables**:
    * `SCRIPTDIR`: Absolute resolution of the script path.
    * `CANONICAL_EXTRAS_DIR`, `LEGACY_EXTRAS_DIR`, `CANONICAL_LOCAL_EXTRAS_DIR`: Normalized paths of physical and local extensions.
    * `MODELS_FILE`: Local file of the model whitelist (`<provider>.txt`).
    * `PROVIDER_FILE`: Local file containing the last selected provider (`provider`).
    * `THREAD_DIR`: Directory for registering thread NDJSON logs (`history/threads`).
    * `MODELS_LOCK`, `HISTORY_LOCK`, `TMP_LOCK`: Paths of the respective exclusive lock files under `var/run/locks`.
    * `B64_WRAP_OPT`, `B64_DECODE_OPT`: Detected formatting options and flags for the `base64` command.
    * `RUN_TMPDIR`, `PAYLOAD`, `RESP`, `ERRF`: Temporary channels and folders of the instance runtime.
    * `BASH4LLM_OPENSSL_ACTIVE`: Boolean flag attesting operational availability of the OpenSSL module.
    * `SAFE_THREAD_ID`: Thread identifier cryptographically anonymized via SHA-256/MD5.
    * `BASH4LLM_KEY_MANUAL_PROMPT`: Tracks manual TTY insertion of the API key to trigger the persistence reminder.
    * `VALIDATE_SML`, `VALIDATE_REGEX`, `SANITIZE_OUTPUT`, `JSON_DIAGNOSTICS`: Enable flags for Scintilla-Ready deterministic extensions.

### 2.2 Functional Mapping by Section in PRECORE_BOOT

#### Section 1: `PRECORE_BOOT_SETUP_SHELL`
* **Activity**: Sets `set -euo pipefail` only if the script is directly executed, so as not to pollute the user's interactive shell when sourced. Performs environment sanitization (`unset BASH_ENV ENV CDPATH GLOBIGNORE`), disables core dumps (`ulimit -c 0`), performs platform autodetect (Android/Termux, macOS, WSL, Cygwin, BSD, Linux), resets deterministic extensions state, and defines error constants and ANSI color codes (with `NO_COLOR` support).

#### Section 2: `PRECORE_BOOT_SETUP_ENV_CMDS`
* **Activity**: Verifies the Bash version ($\ge 4.0$) and presence in `PATH` of the 23 mandatory binaries.

#### Section 3: `PRECORE_BOOT_EARLY_UTILITIES`
* **Functions**: `resolve_script_dir`, `safe_mkdir`, `check_required_arg`, `canonical_config_dir`, `canonical_provider_file`, `canonical_model_file`, `canonical_provider_url_file`, `trim_space`, `_is_readonly_func`, `sync_models_file_path`, `_normalize_model_name`, `is_truthy`, `_extract_notes_section`, `emit_json_diagnostics`, `log_prefix`, `log_info`, `log_warn`, `log_error`, `log_info_user`, `dbg`.
* **Activity**: Fundamental utilities for path calculation, string manipulation, model normalization associative cache (`BASH4LLM_MODEL_CACHE`), Zero-Eval documentation parsing, emission of structured JSON diagnostics (`emit_json_diagnostics`), and coordinated logging engine.

#### Section 4: `PRECORE_BOOT_SECURITY`
* **Functions**: `read_secure_input`, `validate_file_input`, `_get_perm_string`, `_get_owner`, `validate_path_security`, `_core_sha256`, `verify_module_integrity`, `_provider_env_snapshot`, `_provider_env_restore`, `_verify_manifest_signature`, `ensure_api_key_for_provider`, `enforce_network_policy`.
* **Activity**: Complete isolation of security mechanisms: null bytes/control character validation, muted TTY prompt (`stty -echo`), POSIX ownership and permission checks, strictly *fail-closed* SHA-256 cryptographic verification and Ed25519 signature check against the manifest, execution environment snapshot/restore, secure API key resolution (with Key Vault integration), and network policy enforcement.

#### Section 5: `PRECORE_BOOT_DIR_PATH`
* **Functions**: `ensure_config_dir`, `write_provider_url_if_missing`, `resolve_provider_url`.
* **Activity**: Physical initialization of the working directory tree (`var/run`, `locks`, `tmp`), loading of the OpenSSL helper if present, and transactional resolution/registration of provider connection URLs.

#### Section 6: `PRECORE_BOOT_STORAGE_LOCKS`
* **Functions**: `provider_api_env_var_name`, `print_persistence_reminder`, `is_valid_json_string`, `b64encode`, `b64decode`, `file_size`, `is_valid_json_file`, `stage_b64`, `lock_exec`, `_mktemp_in_dir`, `show_payload_head`, `atomic_write`, `extract_text_from_resp`, `cleanup_run_tmp_on_exit`, `ensure_run_tmpdir`, `b64_atomic_write`, `b64_atomic_read`, `ui_state_write`, `run_static_config_check`, `explain_error_code`.
* **Activity**: Management of high-performance I/O primitives: Base64 encoding/decoding, payload staging, cross-process atomic locking (`lock_exec`), lifecycle management of `$RUN_TMPDIR`, atomic filesystem writes, text extraction from responses, static configuration linter, and formal explanation of error codes.

#### Section 7: `PRECORE_BOOT_CLI_HELPERS`
* **Functions**: `_resolve_provider_module_path`, `load_provider_module`, `_detect_base64_opts`, `_file_mtime`, `jq_safe`.
* **Activity**: Early interception of CLI diagnostic flags (`--check-config`, `--explain-error`, `--print-*`), detection of `base64` options, provider domain resolution (`builtin`, `vendor`, `local`), definition of lock constants, and loading of external provider modules into an anti-TOCTOU staging copy in an isolated sandbox with whitelist filtering on exported functions (`load_provider_module`).

---

## SECTION 3: PRECORE_RUN

This macro-section handles long-term persistence, history rotation, manifests for multimodal attachments, the central network engine `_exec_curl_secure`, and the unified NDJSON thread management engine. It is divided into **5 Flat Sections**.

### 3.1 Variables of PRECORE_RUN
* **Read Variables**:
    * `BASH4LLM_ROTATE_HISTORY`: Enables automatic history rotation and maintenance (default `0`).
    * `BASH4LLM_HISTORY_MAX_FILES` (default `100`), `BASH4LLM_HISTORY_MAX_BYTES` (default 100MB), `BASH4LLM_HISTORY_KEEP_DAYS` (default `90`).
    * `THREAD_ID`: Active thread identifier.
    * `SAFE_THREAD_ID`: Thread identifier cryptographically anonymized via SHA-256/MD5.
    * `THREAD_WINDOW`: Size of historical message window to retrieve (default `10`).
    * `BASH4LLM_RATE_LIMIT`: API request limit per thread in 30s window (default `unlimited`).
    * `BASH4LLM_AUTH_TOKEN`: Authorized token to bypass local rate limiter.
    * `FALLBACK_PAYLOAD`: Base64 encoded fallback payload returned by hooks on API errors.
    * `TRANSFORMED_PAYLOAD`: Base64 encoded transformed payload returned by post-execution hooks.
    * `BASH4LLM_SESSION_ENGINE`: Controls activation of the advanced session management module (default `"on"`).
* **Written/Modified Variables**:
    * `THREAD_DIR`: Directory path containing thread NDJSON files (`history/threads`).
    * `BASH4LLM_RATES_DIR`: Tracking directory for rate limiter transactions (`tmp/rates`).
    * Update of logs and metadata in `ui_state/threads/`.

### 3.2 Functional Mapping by Section in PRECORE_RUN

#### Section 1: `PRECORE_RUN_HISTORY`
* **Functions**: `rotate_history`, `save_to_history`.
* **Activity**: Saving outputs to disk and O(N) rotation engine based on file limits, overall byte size, and retention days.

#### Section 2: `PRECORE_RUN_MANIFEST`
* **Functions**: `manifest_create`, `manifest_add_part`, `manifest_read`.
* **Activity**: Lock-protected creation and updating of JSON/Base64 manifests for multimodal attachment management.

#### Section 3: `PRECORE_RUN_UTIL_HELPERS`
* **Functions**: `anonymize_thread_id`, `execute_isolated_hook`, `_get_file_signature`, `getfile_signature`, `_is_world_writable`, `_locked_history_save`, `_locked_manifest_create`, `_locked_manifest_add_part`, `check_local_rate_limit`, `make_tmpdir`, `_tmpf`.
* **Activity**: Strict PII anonymization (SHA-256 hashing of `THREAD_ID`), sandbox for `pre`/`post` hook execution with Zero-Eval whitelist parsing, file state signature checking, sliding-window local rate limiter (30s), and protected temporary allocation.

#### Section 4: `PRECORE_RUN_THREAD_ENGINE`
* **Functions**: `thread_validate_id`, `thread_now_ts`, `thread_messages_tmp_path`, `thread_sanitize_cmd`, `_update_thread_index`, `_thread_delete_locked`, `thread_delete_core`, `_thread_rename_locked`, `thread_rename_core`, `acquire_thread_lock`, `release_thread_lock`, `_thread_read_window_locked`, `thread_read_window`, `thread_append`, `_thread_hash`, `thread_cache_key`, `thread_cache_get`, `thread_cache_set`, `thread_cache_invalidate`.
* **Activity**: **Unified Thread Management Engine**: includes ID validation, command sanitization with sensitive data redaction (`[REDACTED]`), CRUD operations (NDJSON message window reading, idempotent append with message ID, atomic renaming and deletion), concurrency management via exclusive locks, and response caching system with TTL.

#### Section 5: `PRECORE_RUN_RUNTIME_GLOBALS`
* **Functions**: `_normalize_bool_env`, `_exec_curl_secure`.
* **Activity**: Global state variable initialization and definition of the **central network mediation function `_exec_curl_secure()`**, which guarantees isolation of authentication tokens in temporary `0600` header files and File Descriptor redirection (`/dev/fd/3`) to eliminate secret leaks in `argv`.

---

## SECTION 4: SECURITY EXTENSION (openssl-helper.sh)

Optional extension (located in `extras/security/`) enabled by default if the `openssl` binary is present. Provides API credential management through multi-level encryption with a master password.

### 4.1 Vault Support Files
* `keys.enc`: Contains the internal symmetric unlock key (*Vault Key*) encrypted with the user's Master Password.
* `keys.rec`: Contains the same *Vault Key* encrypted with an offline 128-bit random hexadecimal recovery key (*Recovery Key*).
* `keys.dat`: Contains the actual JSON payload of API keys for all providers, encrypted with the *Vault Key*.

### 4.2 Functions of the Security Extension
* **`_vault_read_password`**: Securely reads a password without echo via `read_secure_input`.
* **`_vault_set_opts`**: Configures AES-256-CBC algorithm, salt, and PBKDF2 with 100,000 iterations.
* **`_vault_encrypt_to_file` / `_vault_decrypt_file`**: Atomic encryption and decryption of files on disk.
* **`vault_exists` / `vault_init`**: Checks status and initialization of the Master Password and Recovery Key.
* **`vault_load_keys`**: Decrypts the JSON database of keys in memory using the session token `_B4L_RT_CTX`.
* **`vault_change_password`**: Changes Master Password and re-encrypts Vault Key, generating a new recovery token.
* **`vault_destroy`**: Secure physical destruction of encrypted files via `shred` or zero-overwrite (`dd`).
* **`vault_recover`**: Restores access to the vault via offline hexadecimal *Recovery Key*.
* **`vault_manage_keys` / `vault_console`**: Interactive CLI key management interface activated by the `--vault` option.
* **`_secure_hash_sha256`**: Computes SHA-256 hash for integrity checks before sourcing.
* **`diagnose_tls_connection`**: Performs test handshake via `openssl s_client` to port 443 of the endpoint to verify TLS chain.

---

## SECTION 5: SESSION ENGINE EXTENSION (session-engine.sh)

Optional session optimization extension (located in `extras/session/`). Handles automatic segmentation of NDJSON logs, compression, and reactive context building via in-process caching.

### 5.1 Functions of the Session Engine
* **`_se_list_segments`**: Returns the ordered list of NDJSON session segments (e.g., `chat1.001.ndjson`).
* **`_se_segment_rotate_if_needed`**: If the log exceeds `$BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (1MB), rotates file into next segment and applies `gzip` compression to older blocks.
* **`session_engine_append`**: Appends a message with automatic deduplication within `BASH4LLM_SESSION_DEDUP_WINDOW` (20 lines) and flushes the read cache.
* **`session_engine_build_window`**: Compiles context window for model:
    * Returns data from cache if valid relative to `SESSION_CACHE_TTL_SEC` (30s).
    * **N > 0**: Extracts exactly the last N messages.
    * **N = 0**: Calculates byte weight and accumulates messages up to `$BASH4LLM_SESSION_TARGET_BYTES` (32KB).
* **`session_engine_snapshot`**: Generates JSON telemetry report with statistics, active segments, last 50 lines, and conversation summaries.

---

## SECTION 6: PROVIDER (embedded: groq)

This macro-section encompasses the implementation of the Groq provider built into the Core.

### 6.1 Functions of the Groq module
* **`buildpayload_groq`**: Compiles OpenAI-compatible payload JSON file by reading user input (`CONTENT`, `JSON_INPUT`, `SYSTEM_PROMPT`, or `BUILD_MESSAGES_FILE`), sets temperature and max tokens, producing `$PAYLOAD` file (with optional Base64 staging).
* **`call_api_groq`**: Synchronous non-streaming HTTP call forwarded via `_exec_curl_secure()`: isolates API key in a secure temporary header file with File Descriptor redirection and saves response in `$RESP`.
* **`call_api_streaming_groq`**: Real-time SSE streaming connection via `_exec_curl_secure()`: processes stream in real time with `tee` and `jq --unbuffered`, sends tokens to `stdout`, compiles final synthetic JSON in `$RESP`, and updates `last_api.json`.
* **`validate_key_groq`**: Fast diagnostic test (10s timeout) on `/models` endpoint via `_exec_curl_secure()` to validate API key.
* **`auto_select_model_groq` / `validate_model_groq` / `refresh_models_groq`**: Manage auto-selection of first valid choice, verification, and local synchronization of model catalog in `$MODELS_FILE` via `_exec_curl_secure()`.

---

## SECTION 7: CORE_SETUP

Handles command line interface (CLI) parameter parsing, dispatching interface, whitelisting, registration of `readonly -f` guards, and preventive action resolution. It is divided into **7 Flat Sections**.

### 7.1 Functional Mapping by Section in CORE_SETUP

#### Section 1: `CORE_SETUP_DISPATCH_HELPERS`
* **Functions**: `validate_provider_interface`, `call_provider`, `validate_provider_key_dispatch`, `refresh_models_dispatch`, `validate_model_dispatch`, `auto_select_model_dispatch`, `_lock_security_guards`.
* **Activity**: Dynamic dispatching interface and execution of **`_lock_security_guards()`** to mark security and mediation functions as `readonly -f` at the end of bootstrap.

#### Section 2: `CORE_SETUP_API_CALL`
* **Functions**: `resolve_model`, `build_payload_from_vars`, `call_api_once`, `call_api_streaming`, `extract_api_error`, `detect_empty_edge_case`, `finalize_and_output`, `validate_response_syntax`, `perform_request_once`.
* **Activity**: Request execution wrapper: resolves final model to adopt (`FINAL_MODEL`), manages linear retry loops on error (`$MAX_RETRIES`), executes syntactic response validation (`validate_response_syntax` with SML v2.0 or REGEX check), intercepts empty responses, and manages output formatting (`json`, `pretty`, `text`, `raw`) with application of sanitization filter (`--sanitize`) and automatic saving if exceeding `$THRESHOLD`.

#### Section 3: `CORE_SETUP_INPUT_HELPERS`
* **Functions**: `collect_input_from_files`, `expand_args_to_content`, `file_readable`, `is_supported_model`, `list_models_cli`, `validate_model_core`, `load_local_config`, `load_whitelist`, `is_tty_out`, `_cleanup_sourced_env`.
* **Activity**: Collection and expansion of arguments from `-f` files, verification of readability and safety of input (`validate_file_input`), supported models linter, local configuration loading, and protection block for interactive sourcing with Vault unlocking.

#### Section 4: `CORE_SETUP_CLI_PARSE`
* **Activity**: Main CLI argument parsing loop (`while [ $# -gt 0 ]`), flag interpretation, immediate anonymization of received thread IDs (`anonymize_thread_id`), management of validation and diagnostic options (`--validate-sml`, `--validate-regex`, `--sanitize`, `--json-diagnostics`), atomic resolution and persistence of active provider in `canonical_provider_file`, and automatic loading of respective module.

#### Section 5: `CORE_SETUP_SESSION_ENGINE`
* **Activity**: Attempts import and integrity check of `extras/session/session-engine.sh`. If verified successfully, sets `_engine_available=1` flag, otherwise activates automatic fallback to core NDJSON logic.

#### Section 6: `CORE_SETUP_NORM_FLAGS`
* **Activity**: Normalization of raw export CLI options and listing of local providers or models (`--list-providers`, `--list-providers-raw`, `--list-models-raw`).

#### Section 7: `CORE_SETUP_ACTIONS`
* **Activity**: Immediate management and execution of short CLI commands that do not require network calls to LLM models: thread deletion (`--delete-thread`), thread renaming (`--rename-thread`), manual initialization (`--init-thread`), provider and model listing, default model saving (`--set-default`), Vault console launch (`--vault`), Master Test Suite execution (`--run-all-tests`), and installation/synchronization of `extras` package with SHA-256 manifest integrity verification, Ed25519 signature checking, and permission hardening (`700`/`600`).

---

## SECTION 8: CORE_PROVIDER

Handles interactive interaction, assembly of complex prompts, and final routing to execution pipelines. It is divided into **4 Flat Sections**.

### 8.1 Functional Mapping by Section in CORE_PROVIDER

#### Section 1: `CORE_PROVIDER_PRO_LOAD`
* **Activity**: Handles interactive provider selection when sending `--provider` flag without arguments or value `list`. Displays a numbered menu on terminal, persists choice, and loads selected provider module.

#### Section 2: `CORE_PROVIDER_SHOW`
* **Activity**: Executes preventive display CLI commands and halts execution: prints configuration paths (`--print-*`), displays active variables (`--show-config`), or performs full diagnostic check with TLS handshake test to provider endpoint and extension status (`--diagnostics`).

#### Section 3: `CORE_PROVIDER_PROMPT_ASSEMBLY`
* **Functions**: `assemble_content`.
* **Activity**: **Context Preparation and Assembly**:
    1. Performs automatic model refresh if requested or if local catalog is empty.
    2. Synchronizes thread ID anonymization in `$SAFE_THREAD_ID`.
    3. Loads local configuration and whitelist.
    4. Guarantees presence of `$RUN_TMPDIR` directory.
    5. Resolves and performs formal validation of final model (`MODEL`).
    6. Intercepts and extracts data from standard input (`stdin`), sanitizing and redacting any API keys passed via JSON.
    7. Executes `assemble_content()` to combine input files (`-f`), CLI prompts, or expand `{{CONTENT}}` placeholders inside template files (`--template`).
    8. Verifies that prompt content is not empty, halting execution with `BASH4LLM_ERR_NO_PROMPT` (14) error in case of anomalies.

#### Section 4: `CORE_PROVIDER_PIPELINE_EXEC`
* **Activity**: **Pipeline Routing and Execution**:
    * **Branch A - BATCH Cycle (`--batch`)**: Scans file line by line, retrieves thread session window via Session Engine or NDJSON fallback, compiles payload, and executes requests in sequence, printing persistence reminder (`print_persistence_reminder`).
    * **Branch B - CHAT Mode (`--chat`/`--tui`)**: Verifies cryptographic integrity of `extras/chat/tui-repl.sh` module via `verify_module_integrity`, exports environment variables, and transfers process (`exec bash`) to interactive REPL interface.
    * **Branch C - Single Request (SSE Streaming / Synchronous)**: Prepares thread historical message file, compiles payload via `build_payload_from_vars`, ensures API key presence (via Vault or TTY prompt), and executes HTTP call (streaming via `call_api_streaming` or synchronous via `perform_request_once`). Upon successful return, securely appends user message and assistant response to thread log.

---

## SECTION 9: FILE-SYSTEM STRUCTURE AND MEMORY LAYOUT

To ensure information persistence, domain isolation, and security integration, the `bash4llm.d/` runtime directory and extension domains are organized as follows:

```text
bash4llm.d/
├── config/                                # Configuration and provider persistence (700)
│   ├── config                             # User global variables and parameters (600)
│   ├── provider                           # Stores active provider name (600)
│   ├── provider-url                       # Stores active provider API URL (600)
│   ├── model.<provider>                   # Stores provider default model (600)
│   ├── keys.enc                           # Vault key encrypted with Master Password (600)
│   ├── keys.rec                           # Vault key encrypted with offline Recovery Key (600)
│   ├── keys.dat                           # Encrypted database containing API keys JSON (600)
│   ├── thread_cache/                      # Isolated cache with TTL for thread windows (700)
│   ├── providers/                         # Directory for advanced configurations (700)
│   │   └── hf_endpoints                   # Hugging Face models/endpoint mapping
│   └── ui_state/                          # State folder for GUI and automations (700)
│       ├── last_api.json                  # State of last API call (600)
│       ├── last_history.json              # State of last saved output (600)
│       ├── provider_capabilities.json     # Capabilities list of active provider (600)
│       └── threads/                       # Indexes and session metadata (700)
│           ├── index.json                 # Structured list of active threads (600)
│           └── <safe_thread_id>.json      # Thread state metadata (SHA-256 anonymized)
├── models/                                # Local catalogs of allowed models (700)
│   └── <provider>.txt                     # Validated models whitelist (600)
├── templates/                             # Reusable prompt templates area (700)
├── history/                               # Response output archiving (700)
│   ├── threads/                           # NDJSON historical files of active threads (Core fallback) (700)
│   │   └── <safe_thread_id>.ndjson        # SHA-256 anonymized NDJSON log (600)
│   └── sessions/                          # Advanced historical NDJSON files (Session Engine) (700)
│       ├── <safe_thread_id>.ndjson        # Main anonymized NDJSON log (600)
│       ├── <safe_thread_id>.001.ndjson    # Rotated historical segment (600)
│       └── <safe_thread_id>.001.ndjson.gz # Rotated and compressed historical segment (600)
├── var/                                   # Process and isolated runtime files (700)
│   └── run/                              # Process runtime directory (700)
│       └── locks/                         # Isolated lock files directory (700)
│           ├── models.lock                # Models synchronization lock
│           ├── history.lock               # History synchronization lock
│           └── tmp.lock                   # Temporary file allocation lock
├── tmp/                                   # Secure area with exclusive access (700)
│   └── rates/                             # Rate limiting transaction tracking (700)
│       └── <safe_thread_id>/              # Request timestamps for sliding window
├── local-extras/                          # User extensions not tracked by network manifest (700)
│   └── providers/                         # Local user provider modules (domain local:<name>) (700)
└── extras/                                # Official Vendor extensions installed via installer (700)
    ├── manifest.sha256                    # SHA-256 cryptographic integrity manifest (600)
    ├── manifest.sha256.sig                # Ed25519 cryptographic signature of manifest (600)
    ├── official-ed25519.pub               # Official public key for Ed25519 signature check (600)
    ├── chat/                              # Interactive chat interface (tui-repl.sh, SPEC-TUI.md, langs/)
    ├── hooks/                             # Pre/post execution extension modules (sml-gate.sh, hook.sh)
    ├── security/                          # Security (openssl-helper.sh, output-sanitizer.sh, generate-manifest.sh)
    ├── test/                              # Automated test suite (run-all-tests.sh, scintilla-t3.sh, stress.sh, etc.)
    ├── docs/                              # Documentation (core-notes.sh, help.txt, manual-it.txt, bash4llm-completion.sh)
    ├── providers/                         # Additional Vendor providers (gemini.sh, huggingface.sh, mistral.sh)
    └── session/                           # Optimization and sessions (session-engine.sh)
```
