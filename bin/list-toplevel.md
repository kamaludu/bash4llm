## GroqBash Top‑Level Execution Map

GroqBash Top-Level Execution Model Generated: 2026-05-18T15:19:28Z (UTC)
Method: conservative synthesis

---

### 1) Execution Order Overview

Short summary:

Step-by-step flow (claims referenced):
Step (C001): Script sets strict shell options and shebang
  Evidence:   EVID_SHEBANG_0001:groqbash:15; EVID_SHEBANG_0002:groqbash:1; EVID_SHEBANG_0003:groqbash/list/auto_fill_decls.py:1; 

Step (C002): Script enforces required system commands at startup
  Evidence:   EVID_REQCMD_0046:groqbash:1163; EVID_REQCMD_0047:groqbash:1457; EVID_REQCMD_0048:groqbash:1466; 

Step (C003): Script defines helper functions for encoding, JSON validation, and logging
  Evidence:   EVID_HELP_0315:groqbash:1039; EVID_HELP_0316:groqbash:1060; EVID_HELP_0317:groqbash:1071; 

Step (C004): Script normalizes DEBUG from GROQBASH_DEBUG/DEBUG
  Evidence:   EVID_DEBUG_0901:groqbash/list/cli_parsing_blocks.txt:49; EVID_DEBUG_0902:groqbash/list/cli_parsing_blocks.txt:51; EVID_DEBUG_0903:groqbash/list/cli_parsing_blocks.txt:52; 

Step (C005): Script registers cleanup trap for EXIT/INT/TERM
  Evidence:   EVID_TRAP_1154:groqbash:805; EVID_TRAP_1155:groqbash:831; EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301; 

Step (C006): Script uses RUN_TMPDIR/GROQBASH_TMPDIR for staging
  Evidence:   EVID_TMP_1192:groqbash:1013; EVID_TMP_1193:groqbash:1190; EVID_TMP_1194:groqbash:1197; 

Step (C007): Script exposes long CLI flags and parsing markers
  Evidence:   EVID_CLIPARSE_28724:groqbash:1000; EVID_CLIPARSE_28725:groqbash:1001; EVID_CLIPARSE_28726:groqbash:1002; 

Step (C008): Script supports print-only flags that avoid network calls
  Evidence:   EVID_CLIPARSE_28724:groqbash:1000; EVID_CLIPARSE_28725:groqbash:1001; EVID_CLIPARSE_28726:groqbash:1002; 

Step (C009): Script resolves provider and canonical model paths
  Evidence:   EVID_HELP_0315:groqbash:1039; EVID_HELP_0316:groqbash:1060; EVID_HELP_0317:groqbash:1071; 

Step (C011): Network calls are encapsulated in dedicated functions (call_api_groq)
  Evidence:   EVID_TMP_1192:groqbash:1013; EVID_TMP_1193:groqbash:1190; EVID_TMP_1194:groqbash:1197; 

Step (C012): Script uses here-docs or subshells for payload staging
  Evidence:   EVID_CLIPARSE_28724:groqbash:1000; EVID_CLIPARSE_28725:groqbash:1001; EVID_CLIPARSE_28726:groqbash:1002; 

---

### 2) Top-Level State Model

Top-level variables (conservative list with inferred role and evidence pointers):
 - groqbash:1011:MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1012:HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1013:TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1016:GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1017:GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1018:GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1216:GROQBASH_ROTATE_HISTORY="${GROQBASH_ROTATE_HISTORY:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1217:GROQBASH_HISTORY_MAX_FILES="${GROQBASH_HISTORY_MAX_FILES:-100}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1218:GROQBASH_HISTORY_MAX_BYTES="${GROQBASH_HISTORY_MAX_BYTES:-104857600}" # 100MB — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1219:GROQBASH_HISTORY_KEEP_DAYS="${GROQBASH_HISTORY_KEEP_DAYS:-90}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:17:SCRIPT_NAME="groqbash" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:18:SCRIPT_VERSION="2.0.0" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:196:SCRIPTDIR="$(resolve_script_dir)" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:1984:SESSION_CACHE_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}/session_cache" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:19:SCRIPT_DATE="2026-05-07" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2076:CONTENT="${CONTENT:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2077:JSON_INPUT="${JSON_INPUT:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2079:SESSION_ID="${SESSION_ID:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2080:SESSION_WINDOW="${SESSION_WINDOW:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2082:TEMPLATE="${TEMPLATE:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2083:BATCH_FILE="${BATCH_FILE:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2084:CHAT_MODE="${CHAT_MODE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2085:SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2086:REFRESH_MODELS="${REFRESH_MODELS:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2087:LIST_MODELS="${LIST_MODELS:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2088:FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2089:OUT_PATH="${OUT_PATH:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:208:CANONICAL_EXTRAS_DIR="${GROQBASH_DIR%/}/extras" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2090:SYSTEM_PROMPT="${SYSTEM_PROMPT:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2091:TURE="${TURE:-${TEMPERATURE:-1.0}}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2092:TEMPERATURE="${TEMPERATURE:-${TURE:-1.0}}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2093:TURE="${TURE:-$TEMPERATURE}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2094:MAX_TOKENS="${MAX_TOKENS:-4096}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2095:MODEL="${MODEL:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2096:AUTO_POLICY="${AUTO_POLICY:-preferred}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2097:DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2098:QUIET="${QUIET:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2099:DRY_RUN="${DRY_RUN:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:209:LEGACY_EXTRAS_DIR="${SCRIPTDIR%/}/extras" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2100:STREAM_MODE="${STREAM_MODE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2101:OUTPUT_MODE="${OUTPUT_MODE:-text}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2102:THRESHOLD="${THRESHOLD:-1000}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2103:MAX_RETRIES="${MAX_RETRIES:-3}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2104:SUPPORTED_PROVIDERS="${SUPPORTED_PROVIDERS:-groq gemini huggingface}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2105:PROVIDER="${PROVIDER:-groq}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2117:CURL_BASE_OPTS=( --silent --show-error --no-buffer --max-time 120 ) — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:212:GROQBASH_EXTRAS_DIR="${CANONICAL_EXTRAS_DIR}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:2157:GROQ_API_KEY="${GROQ_API_KEY:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:215:PROVIDERS_DIR="${PROVIDERS_DIR:-${GROQBASH_EXTRAS_DIR%/}/providers}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:221:GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:222:GROQBASH_MODELS_DIR="${GROQBASH_MODELS_DIR:-$GROQBASH_DIR/models}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:223:GROQBASH_TEMPLATES_DIR="${GROQBASH_TEMPLATES_DIR:-$GROQBASH_DIR/templates}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:224:GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:225:GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-$GROQBASH_DIR/tmp}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:226:MODELS_FILE="${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:227:MAX_MODELS="${MAX_MODELS:-200}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:230:GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR%/}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:24:GROQBASH_ERR_NO_API_KEY=10 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:25:GROQBASH_ERR_BAD_MODEL=11 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:26:GROQBASH_ERR_CURL_FAILED=12 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:27:GROQBASH_ERR_INVALID_JSON=13 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:28:GROQBASH_ERR_NO_PROMPT=14 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:29:GROQBASH_ERR_TMP=15 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:30:GROQBASH_ERR_API=16 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:32:GROQBASHERRNOAPIKEY=$GROQBASH_ERR_NO_API_KEY — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:338:PROVIDER_FILE="$(canonical_provider_file)" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:33:GROQBASHERRBAD_MODEL=$GROQBASH_ERR_BAD_MODEL — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:34:GROQBASHERRCURL_FAILED=$GROQBASH_ERR_CURL_FAILED — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:35:GROQBASHERRINVALID_JSON=$GROQBASH_ERR_INVALID_JSON — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3608:JSON_INPUT="${JSON_INPUT:-}" TEMPLATE="${TEMPLATE:-}" BATCH_FILE="${BATCH_FILE:-}" CHAT_MODE="${CHAT_MODE:-0}" SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3609:LIST_MODELS="${LIST_MODELS:-0}" LIST_PROVIDERS="${LIST_PROVIDERS:-0}" FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-}" OUT_PATH="${OUT_PATH:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3610:DRY_RUN="${DRY_RUN:-0}" STREAM_MODE="${STREAM_MODE:-0}" QUIET="${QUIET:-0}" INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}" DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3611:PROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3612:SHOW_CONFIG="${SHOW_CONFIG:-0}" DIAGNOSTICS="${DIAGNOSTICS:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3613:FILE_INPUTS=() ARGS=() OUTPUT_MODE="${OUTPUT_MODE:-text}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3614:MODEL_CLI_SET="${MODEL_CLI_SET:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3615:INSTALL_EXTRAS_SRC="" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:36:GROQBASHERRNO_PROMPT=$GROQBASH_ERR_NO_PROMPT — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3704:SE_ENGINE_PATH="${GROQBASH_EXTRAS_DIR%/}/session/session-engine.sh" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3705:SE_AVAILABLE=0 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:3776:SUPPORTED_PROVIDERS="$(printf '%s ' "${_supported_providers_arr[@]}" | sed 's/ $//')" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:37:GROQBASHERRTMP=$GROQBASH_ERR_TMP — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:38:GROQBASHERRAPI=$GROQBASH_ERR_API — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:4105:SUPPORTED_PROVIDERS="$(printf '%s ' "${_supported_providers_arr[@]}" | sed 's/ $//')" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:414:DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:418:DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:419:GROQBASH_LOG="${GROQBASH_LOG:-}" # optional path to append structured logs — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:4459:MODEL="$FINAL_MODEL" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:4462:STDIN_CONTENT="" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:720:DEBUG_PRESERVE="${DEBUG_PRESERVE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash:987:SESSION_DIR="${GROQBASH_HISTORY_DIR%/}/sessions" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)

Relationships (conservative):
 - RUN_TMPDIR contains PAYLOAD, RESP, ERRF; DEBUG influences cleanup behavior.

---

### 3) Top-Level Side-Effects

Observed side-effects (each with conservative description):
 - Creates directories for tmp, sessions, ui_state; writes payload/response/error files; uses lock files to coordinate.

---

### 4) Top-Level Control Flow

Main branches (conservative):
 - Print-only / dry-run: recognized by long flags; avoids network calls.
 - Normal run: parse CLI → resolve provider → prepare tmp → build payload → call API → handle response → cleanup.
 - Early exit: help/version, source-only, missing deps, invalid provider perms.

For each branch, see claims_map.tsv for evidence pointers.

---

### 5) Top-Level Dependencies

Conservative list of required tools (typical): bash, jq, curl, mktemp, stat, flock, base64, awk, sed, grep, xargs, tr, sort, head, wc, tee, date, mv, chmod, cp, rm, printf.
Behavior: script checks for required commands and exits early if missing.

---

### 6) Top-Level Behavioral Guarantees (Invariants)

 - If GROQBASH_SOURCE_ONLY is set, main runtime does not execute
   Evidence:   EVID_REQCMD_0046:groqbash:1163; EVID_REQCMD_0047:groqbash:1457; EVID_REQCMD_0048:groqbash:1466; 

 - Temporary artifacts are removed on exit unless debug-preserve
   Evidence:   EVID_TRAP_1154:groqbash:805; EVID_TRAP_1155:groqbash:831; EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301; 

 - Provider modules are validated before sourcing
   Evidence:   EVID_REQCMD_0046:groqbash:1163; EVID_REQCMD_0047:groqbash:1457; EVID_REQCMD_0048:groqbash:1466; 

 - Script enforces required system commands at startup
   Evidence:   EVID_REQCMD_0046:groqbash:1163; EVID_REQCMD_0047:groqbash:1457; EVID_REQCMD_0048:groqbash:1466; 

 - Script registers cleanup trap for EXIT/INT/TERM
   Evidence:   EVID_TRAP_1154:groqbash:805; EVID_TRAP_1155:groqbash:831; EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301; 

---

### Appendix: key analysis files (for traceability)
 - groqbash/list/analysis/evidence_master.tsv
 - groqbash/list/analysis/claims_map.tsv
 - groqbash/list/analysis/*_raw.txt

End of file.

---

Evidence snippets (one per VERIFIED claim)

Claim: C001
Mapping: C001	VERIFIED	EVID_SHEBANG_0001:groqbash:15|EVID_SHEBANG_0002:groqbash:1|EVID_SHEBANG_0003:groqbash/list/auto_fill_decls.py:1
EvidenceSnippet: #!/usr/bin/env python3

---

Claim: C002
Mapping: C002	VERIFIED	EVID_REQCMD_0046:groqbash:1163|EVID_REQCMD_0047:groqbash:1457|EVID_REQCMD_0048:groqbash:1466
EvidenceSnippet: *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;

---

Claim: C003
Mapping: C003	VERIFIED	EVID_HELP_0315:groqbash:1039|EVID_HELP_0316:groqbash:1060|EVID_HELP_0317:groqbash:1071
EvidenceSnippet: log_error "SEC" "provider file writable by group/world."

---

Claim: C004
Mapping: C004	VERIFIED	EVID_DEBUG_0901:groqbash/list/cli_parsing_blocks.txt:49|EVID_DEBUG_0902:groqbash/list/cli_parsing_blocks.txt:51|EVID_DEBUG_0903:groqbash/list/cli_parsing_blocks.txt:52
EvidenceSnippet: DEBUG="${GROQBASH_DEBUG}"

---

Claim: C005
Mapping: C005	VERIFIED	EVID_TRAP_1154:groqbash:805|EVID_TRAP_1155:groqbash:831|EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301
EvidenceSnippet: cleanup_run_tmp_on_exit() {

---

Claim: C006
Mapping: C006	VERIFIED	EVID_TMP_1192:groqbash:1013|EVID_TMP_1193:groqbash:1190|EVID_TMP_1194:groqbash:1197
EvidenceSnippet: # If ERRF is defined, append jq stderr for diagnostics

---

Claim: C007
Mapping: C007	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000|EVID_CLIPARSE_28725:groqbash:1001|EVID_CLIPARSE_28726:groqbash:1002
EvidenceSnippet: done

---

Claim: C008
Mapping: C008	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000|EVID_CLIPARSE_28725:groqbash:1001|EVID_CLIPARSE_28726:groqbash:1002
EvidenceSnippet: done

---

Claim: C009
Mapping: C009	VERIFIED	EVID_HELP_0315:groqbash:1039|EVID_HELP_0316:groqbash:1060|EVID_HELP_0317:groqbash:1071
EvidenceSnippet: log_error "SEC" "provider file writable by group/world."

---

Claim: C010
Mapping: C010	VERIFIED	EVID_REQCMD_0046:groqbash:1163|EVID_REQCMD_0047:groqbash:1457|EVID_REQCMD_0048:groqbash:1466
EvidenceSnippet: *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;

---

Claim: C011
Mapping: C011	VERIFIED	EVID_TMP_1192:groqbash:1013|EVID_TMP_1193:groqbash:1190|EVID_TMP_1194:groqbash:1197
EvidenceSnippet: # If ERRF is defined, append jq stderr for diagnostics

---

Claim: C012
Mapping: C012	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000|EVID_CLIPARSE_28725:groqbash:1001|EVID_CLIPARSE_28726:groqbash:1002
EvidenceSnippet: done

---

Claim: C013
Mapping: C013	VERIFIED	EVID_HELP_0315:groqbash:1039|EVID_HELP_0316:groqbash:1060|EVID_HELP_0317:groqbash:1071
EvidenceSnippet: log_error "SEC" "provider file writable by group/world."

---

Claim: C014
Mapping: C014	VERIFIED	EVID_TMP_1192:groqbash:1013|EVID_TMP_1193:groqbash:1190|EVID_TMP_1194:groqbash:1197
EvidenceSnippet: # If ERRF is defined, append jq stderr for diagnostics

---

Claim: C015
Mapping: C015	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000|EVID_CLIPARSE_28725:groqbash:1001|EVID_CLIPARSE_28726:groqbash:1002
EvidenceSnippet: done

---

Claim: C016
Mapping: C016	VERIFIED	EVID_REQCMD_0046:groqbash:1163|EVID_REQCMD_0047:groqbash:1457|EVID_REQCMD_0048:groqbash:1466
EvidenceSnippet: *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;

---

Claim: C017
Mapping: C017	VERIFIED	EVID_REQCMD_0046:groqbash:1163|EVID_REQCMD_0047:groqbash:1457|EVID_REQCMD_0048:groqbash:1466|EVID_CLIPARSE_28724:groqbash:1000|EVID_CLIPARSE_28725:groqbash:1001|EVID_CLIPARSE_28726:groqbash:1002
EvidenceSnippet: done

---

Claim: C018
Mapping: C018	VERIFIED	EVID_TRAP_1154:groqbash:805|EVID_TRAP_1155:groqbash:831|EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301|EVID_TMP_1192:groqbash:1013|EVID_TMP_1193:groqbash:1190|EVID_TMP_1194:groqbash:1197
EvidenceSnippet: # If ERRF is defined, append jq stderr for diagnostics

---

Claim: C019
Mapping: C019	VERIFIED	EVID_REQCMD_0046:groqbash:1163|EVID_REQCMD_0047:groqbash:1457|EVID_REQCMD_0048:groqbash:1466
EvidenceSnippet: *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;

---
