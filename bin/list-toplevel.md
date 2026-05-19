## GroqBash Top‑Level Inventory (for LLM)

Generated: 2026-05-18T22:14:35Z (UTC)

### TL;DR 
- Step (C001): Script sets strict shell options and shebang
- Step (C002): Script enforces required system commands at startup
- Step (C003): Script defines helper functions for encoding, JSON validation, and logging
- Step (C004): Script normalizes DEBUG from GROQBASH_DEBUG/DEBUG
- Step (C005): Script registers cleanup trap for EXIT/INT/TERM
- Step (C006): Script uses RUN_TMPDIR/GROQBASH_TMPDIR for staging
- Step (C007): Script exposes long CLI flags and parsing markers
- Step (C008): Script supports print-only flags that avoid network calls
- Step (C009): Script resolves provider and canonical model paths
- Step (C010): Script checks provider directory ownership/permissions
- Step (C011): Network calls are encapsulated in dedicated functions (call_api_groq)
- Step (C012): Script uses here-docs or subshells for payload staging

---

### 1) Execution Order Overview 

#### Step (C001):
Step (C001): Script sets strict shell options and shebang

**Evidence:**
 - EVID_SHEBANG_0001:groqbash:15
 - EVID_SHEBANG_0002:groqbash:1

```sh
# =============================================================================
# Requirements (no fallbacks): bash coreutils findutils util-linux gawk curl jq

########################################
# SECTION: PRECORE_BOOT - BEGIN
########################################
#--1<---[ SECTION: PRECORE_BOOT_SETUP_SHELL ]--->1--
set -euo pipefail

SCRIPT_NAME="groqbash"
SCRIPT_VERSION="2.0.0"
SCRIPT_DATE="2026-05-07"

# ---------------------------------------------------------------------------
# Canonical error codes

```

---

#### Step (C002):
Step (C002): Script enforces required system commands at startup

**Evidence:**
 - EVID_REQCMD_0046:groqbash:1163
 - EVID_REQCMD_0047:groqbash:1457

#### # SHARED_SNIPPET: C002,C010,C016,C017,C019
```sh
# SHARED_SNIPPET: C002,C010,C016,C017,C019


# ---------------------------------------------------------------------------
# tac_fallback: portable reverse file lines (fallback to awk)
# Usage: tac_fallback <file>
# ---------------------------------------------------------------------------
tac_fallback() {
  local f="$1"
  if command -v tac >/dev/null 2>&1; then
    tac "$f"
    return $?
  fi
  # awk-based fallback: print file in reverse
  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' "$f"
  return 0
}

```

---

#### Step (C003):
Step (C003): Script defines helper functions for encoding, JSON validation, and logging

**Evidence:**
 - EVID_HELP_0315:groqbash:1039
 - EVID_HELP_0316:groqbash:1060

#### # SHARED_SNIPPET: C003,C009,C013
```sh
# SHARED_SNIPPET: C003,C009,C013

  PROVIDER_DIR="$PROVIDERS_DIR"

  if [ ! -d "$PROVIDER_DIR" ]; then
    mkdir -p "$PROVIDER_DIR" 2>/dev/null || { log_error "PROVIDER" "cannot create provider directory."; return 1; }
  fi

  if _is_world_writable "$PROVIDER_DIR"; then
    log_error "SEC" "provider directory is world-writable."
    return 1
  fi

  local current_user owner file_owner perms group_write others_write beforesig aftersig invalid_provider _req
  current_user="$(id -un 2>/dev/null || printf '')"
  owner="$(_get_owner "$PROVIDER_DIR")"
  [ -n "$owner" ] && [ "$owner" != "$current_user" ] && log_warn "SEC" "provider directory owned by $owner"

```

---

#### Step (C004):
Step (C004): Script normalizes DEBUG from GROQBASH_DEBUG/DEBUG

**Evidence:**
 - EVID_DEBUG_0901:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:49
 - EVID_DEBUG_0902:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:51

```sh
  local f="$1"
  [ -f "$f" ] || return 1
  [ -s "$f" ] || return 1
  # Trim leading BOM/whitespace by letting jq parse; jq -e returns 0 on valid JSON
  jq -e . "$f" >/dev/null 2>&1
}

# Normalize debug variable: prefer DEBUG, but respect GROQBASH_DEBUG if DEBUG unset
# Place this after CLI parsing and before any logging or DEBUG checks
if [ -n "${GROQBASH_DEBUG:-}" ] && [ -z "${DEBUG:-}" ]; then
  DEBUG="${GROQBASH_DEBUG}"
fi
DEBUG="${DEBUG:-0}"

# ---------------------------------------------------------------------------

```

---

#### Step (C005):
Step (C005): Script registers cleanup trap for EXIT/INT/TERM

**Evidence:**
 - EVID_TRAP_1154:groqbash:805
 - EVID_TRAP_1155:groqbash:831

#### # SHARED_SNIPPET: C005,C018
```sh
# SHARED_SNIPPET: C005,C018

          log_info "TMP" "Removed empty staging file: $f"
        fi
      fi
    done
  fi

  # Define cleanup function but install trap only when running in main process
  cleanup_run_tmp_on_exit() {
    if [ "${DEBUG_PRESERVE:-0}" -eq 1 ]; then
      if [ "${DEBUG:-0}" -eq 1 ]; then
        log_info "TMP" "DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR"
      fi
      return 0
    fi
    if [ -n "${RUN_TMPDIR:-}" ]; then

```

---

#### Step (C006):
Step (C006): Script uses RUN_TMPDIR/GROQBASH_TMPDIR for staging

**Evidence:**
 - EVID_TMP_1192:groqbash:1013
 - EVID_TMP_1193:groqbash:1190

#### # SHARED_SNIPPET: C006,C011,C014
```sh
# SHARED_SNIPPET: C006,C011,C014

# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.

# ---------------------------------------------------------------------------
# Centralized lock names (co-located with resources)
# ---------------------------------------------------------------------------
MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}"
HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}"
TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}"

# Lock timeouts (configurable via env)
GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}"
GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}"
GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}"

# Load and validate provider module for given provider name

```

---

#### Step (C007):
Step (C007): Script exposes long CLI flags and parsing markers

**Evidence:**
 - EVID_CLIPARSE_28724:groqbash:1000
 - EVID_CLIPARSE_28725:groqbash:1001

#### # SHARED_SNIPPET: C007,C008,C012,C015
```sh
# SHARED_SNIPPET: C007,C008,C012,C015


# Ensure directories are not symlinks and have strict perms
for d in "$GROQBASH_DIR" "$(canonical_config_dir)" "$GROQBASH_MODELS_DIR" "$GROQBASH_TEMPLATES_DIR" "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" "$GROQBASH_EXTRAS_DIR" "$(canonical_config_dir)/providers"; do
  if [ -L "$d" ]; then
    printf 'groqbash: ERROR: directory is a symlink: %s\n' "$d" >&2
    exit "$GROQBASHERRTMP"
  fi
  mkdir -p "$d" 2>/dev/null || { printf 'groqbash: ERROR: cannot create directory: %s\n' "$d" >&2; exit "$GROQBASHERRTMP"; }
  chmod 700 "$d" 2>/dev/null || true
done

# Legacy extras handling (fail only when a legacy dir exists outside the chosen source/destination)
# Note: do not treat SCRIPTDIR/extras as fatal if it will be used as the explicit source for install.
# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.


```

---

#### Step (C008):
Step (C008): Script supports print-only flags that avoid network calls

**Evidence:**
 - EVID_CLIPARSE_28724:groqbash:1000
 - EVID_CLIPARSE_28725:groqbash:1001

#### # SHARED_SNIPPET: C007,C008,C012,C015
```sh
# SHARED_SNIPPET: C007,C008,C012,C015


# Ensure directories are not symlinks and have strict perms
for d in "$GROQBASH_DIR" "$(canonical_config_dir)" "$GROQBASH_MODELS_DIR" "$GROQBASH_TEMPLATES_DIR" "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" "$GROQBASH_EXTRAS_DIR" "$(canonical_config_dir)/providers"; do
  if [ -L "$d" ]; then
    printf 'groqbash: ERROR: directory is a symlink: %s\n' "$d" >&2
    exit "$GROQBASHERRTMP"
  fi
  mkdir -p "$d" 2>/dev/null || { printf 'groqbash: ERROR: cannot create directory: %s\n' "$d" >&2; exit "$GROQBASHERRTMP"; }
  chmod 700 "$d" 2>/dev/null || true
done

# Legacy extras handling (fail only when a legacy dir exists outside the chosen source/destination)
# Note: do not treat SCRIPTDIR/extras as fatal if it will be used as the explicit source for install.
# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.


```

---

#### Step (C009):
Step (C009): Script resolves provider and canonical model paths

**Evidence:**
 - EVID_HELP_0315:groqbash:1039
 - EVID_HELP_0316:groqbash:1060

#### # SHARED_SNIPPET: C003,C009,C013
```sh
# SHARED_SNIPPET: C003,C009,C013

  PROVIDER_DIR="$PROVIDERS_DIR"

  if [ ! -d "$PROVIDER_DIR" ]; then
    mkdir -p "$PROVIDER_DIR" 2>/dev/null || { log_error "PROVIDER" "cannot create provider directory."; return 1; }
  fi

  if _is_world_writable "$PROVIDER_DIR"; then
    log_error "SEC" "provider directory is world-writable."
    return 1
  fi

  local current_user owner file_owner perms group_write others_write beforesig aftersig invalid_provider _req
  current_user="$(id -un 2>/dev/null || printf '')"
  owner="$(_get_owner "$PROVIDER_DIR")"
  [ -n "$owner" ] && [ "$owner" != "$current_user" ] && log_warn "SEC" "provider directory owned by $owner"

```

---

#### Step (C010):
Step (C010): Script checks provider directory ownership/permissions

**Evidence:**
 - EVID_REQCMD_0046:groqbash:1163
 - EVID_REQCMD_0047:groqbash:1457

#### # SHARED_SNIPPET: C002,C010,C016,C017,C019
```sh
# SHARED_SNIPPET: C002,C010,C016,C017,C019


# ---------------------------------------------------------------------------
# tac_fallback: portable reverse file lines (fallback to awk)
# Usage: tac_fallback <file>
# ---------------------------------------------------------------------------
tac_fallback() {
  local f="$1"
  if command -v tac >/dev/null 2>&1; then
    tac "$f"
    return $?
  fi
  # awk-based fallback: print file in reverse
  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' "$f"
  return 0
}

```

---

#### Step (C011):
Step (C011): Network calls are encapsulated in dedicated functions (call_api_groq)

**Evidence:**
 - EVID_TMP_1192:groqbash:1013
 - EVID_TMP_1193:groqbash:1190

#### # SHARED_SNIPPET: C006,C011,C014
```sh
# SHARED_SNIPPET: C006,C011,C014

# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.

# ---------------------------------------------------------------------------
# Centralized lock names (co-located with resources)
# ---------------------------------------------------------------------------
MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}"
HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}"
TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}"

# Lock timeouts (configurable via env)
GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}"
GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}"
GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}"

# Load and validate provider module for given provider name

```

---

#### Step (C012):
Step (C012): Script uses here-docs or subshells for payload staging

**Evidence:**
 - EVID_CLIPARSE_28724:groqbash:1000
 - EVID_CLIPARSE_28725:groqbash:1001

#### # SHARED_SNIPPET: C007,C008,C012,C015
```sh
# SHARED_SNIPPET: C007,C008,C012,C015


# Ensure directories are not symlinks and have strict perms
for d in "$GROQBASH_DIR" "$(canonical_config_dir)" "$GROQBASH_MODELS_DIR" "$GROQBASH_TEMPLATES_DIR" "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" "$GROQBASH_EXTRAS_DIR" "$(canonical_config_dir)/providers"; do
  if [ -L "$d" ]; then
    printf 'groqbash: ERROR: directory is a symlink: %s\n' "$d" >&2
    exit "$GROQBASHERRTMP"
  fi
  mkdir -p "$d" 2>/dev/null || { printf 'groqbash: ERROR: cannot create directory: %s\n' "$d" >&2; exit "$GROQBASHERRTMP"; }
  chmod 700 "$d" 2>/dev/null || true
done

# Legacy extras handling (fail only when a legacy dir exists outside the chosen source/destination)
# Note: do not treat SCRIPTDIR/extras as fatal if it will be used as the explicit source for install.
# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.


```

---

#### Step (C013):
Step (C013): Top-level uppercase variables are defined

**Evidence:**
 - EVID_HELP_0315:groqbash:1039
 - EVID_HELP_0316:groqbash:1060

#### # SHARED_SNIPPET: C003,C009,C013
```sh
# SHARED_SNIPPET: C003,C009,C013

  PROVIDER_DIR="$PROVIDERS_DIR"

  if [ ! -d "$PROVIDER_DIR" ]; then
    mkdir -p "$PROVIDER_DIR" 2>/dev/null || { log_error "PROVIDER" "cannot create provider directory."; return 1; }
  fi

  if _is_world_writable "$PROVIDER_DIR"; then
    log_error "SEC" "provider directory is world-writable."
    return 1
  fi

  local current_user owner file_owner perms group_write others_write beforesig aftersig invalid_provider _req
  current_user="$(id -un 2>/dev/null || printf '')"
  owner="$(_get_owner "$PROVIDER_DIR")"
  [ -n "$owner" ] && [ "$owner" != "$current_user" ] && log_warn "SEC" "provider directory owned by $owner"

```

---

#### Step (C014):
Step (C014): Script creates/removes directories and files for config/history/tmp

**Evidence:**
 - EVID_TMP_1192:groqbash:1013
 - EVID_TMP_1193:groqbash:1190

#### # SHARED_SNIPPET: C006,C011,C014
```sh
# SHARED_SNIPPET: C006,C011,C014

# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.

# ---------------------------------------------------------------------------
# Centralized lock names (co-located with resources)
# ---------------------------------------------------------------------------
MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}"
HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}"
TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}"

# Lock timeouts (configurable via env)
GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}"
GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}"
GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}"

# Load and validate provider module for given provider name

```

---

#### Step (C015):
Step (C015): Print-only branches do not perform HTTP

**Evidence:**
 - EVID_CLIPARSE_28724:groqbash:1000
 - EVID_CLIPARSE_28725:groqbash:1001

#### # SHARED_SNIPPET: C007,C008,C012,C015
```sh
# SHARED_SNIPPET: C007,C008,C012,C015


# Ensure directories are not symlinks and have strict perms
for d in "$GROQBASH_DIR" "$(canonical_config_dir)" "$GROQBASH_MODELS_DIR" "$GROQBASH_TEMPLATES_DIR" "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" "$GROQBASH_EXTRAS_DIR" "$(canonical_config_dir)/providers"; do
  if [ -L "$d" ]; then
    printf 'groqbash: ERROR: directory is a symlink: %s\n' "$d" >&2
    exit "$GROQBASHERRTMP"
  fi
  mkdir -p "$d" 2>/dev/null || { printf 'groqbash: ERROR: cannot create directory: %s\n' "$d" >&2; exit "$GROQBASHERRTMP"; }
  chmod 700 "$d" 2>/dev/null || true
done

# Legacy extras handling (fail only when a legacy dir exists outside the chosen source/destination)
# Note: do not treat SCRIPTDIR/extras as fatal if it will be used as the explicit source for install.
# The immediate-action install-extras logic will perform the final legacy checks in context of chosen source.


```

---

#### Step (C016):
Step (C016): Script requires core tools like jq/curl/mktemp

**Evidence:**
 - EVID_REQCMD_0046:groqbash:1163
 - EVID_REQCMD_0047:groqbash:1457

#### # SHARED_SNIPPET: C002,C010,C016,C017,C019
```sh
# SHARED_SNIPPET: C002,C010,C016,C017,C019


# ---------------------------------------------------------------------------
# tac_fallback: portable reverse file lines (fallback to awk)
# Usage: tac_fallback <file>
# ---------------------------------------------------------------------------
tac_fallback() {
  local f="$1"
  if command -v tac >/dev/null 2>&1; then
    tac "$f"
    return $?
  fi
  # awk-based fallback: print file in reverse
  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' "$f"
  return 0
}

```

---

#### Step (C017):
Step (C017): If GROQBASH_SOURCE_ONLY is set, main runtime does not execute

**Evidence:**
 - EVID_REQCMD_0046:groqbash:1163
 - EVID_REQCMD_0047:groqbash:1457
 - EVID_REQCMD_0048:groqbash:1466
 - EVID_CLIPARSE_28724:groqbash:1000
 - EVID_CLIPARSE_28725:groqbash:1001

#### # SHARED_SNIPPET: C002,C010,C016,C017,C019
```sh
# SHARED_SNIPPET: C002,C010,C016,C017,C019


# ---------------------------------------------------------------------------
# tac_fallback: portable reverse file lines (fallback to awk)
# Usage: tac_fallback <file>
# ---------------------------------------------------------------------------
tac_fallback() {
  local f="$1"
  if command -v tac >/dev/null 2>&1; then
    tac "$f"
    return $?
  fi
  # awk-based fallback: print file in reverse
  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' "$f"
  return 0
}

```

---

#### Step (C018):
Step (C018): Temporary artifacts are removed on exit unless debug-preserve

**Evidence:**
 - EVID_TRAP_1154:groqbash:805
 - EVID_TRAP_1155:groqbash:831
 - EVID_TRAP_1156:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:301
 - EVID_TMP_1192:groqbash:1013
 - EVID_TMP_1193:groqbash:1190

#### # SHARED_SNIPPET: C005,C018
```sh
# SHARED_SNIPPET: C005,C018

          log_info "TMP" "Removed empty staging file: $f"
        fi
      fi
    done
  fi

  # Define cleanup function but install trap only when running in main process
  cleanup_run_tmp_on_exit() {
    if [ "${DEBUG_PRESERVE:-0}" -eq 1 ]; then
      if [ "${DEBUG:-0}" -eq 1 ]; then
        log_info "TMP" "DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR"
      fi
      return 0
    fi
    if [ -n "${RUN_TMPDIR:-}" ]; then

```

---

#### Step (C019):
Step (C019): Provider modules are validated before sourcing

**Evidence:**
 - EVID_REQCMD_0046:groqbash:1163
 - EVID_REQCMD_0047:groqbash:1457

#### # SHARED_SNIPPET: C002,C010,C016,C017,C019
```sh
# SHARED_SNIPPET: C002,C010,C016,C017,C019


# ---------------------------------------------------------------------------
# tac_fallback: portable reverse file lines (fallback to awk)
# Usage: tac_fallback <file>
# ---------------------------------------------------------------------------
tac_fallback() {
  local f="$1"
  if command -v tac >/dev/null 2>&1; then
    tac "$f"
    return $?
  fi
  # awk-based fallback: print file in reverse
  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' "$f"
  return 0
}

```

---


### 2) Top‑Level State Model 

#### 2.1 Variables referenced by claims (inferred from evidence file:line references)

 - ALLOWED_MODELS — evidence: referenced in claims
 - ALLOW_API_CALLS — evidence: referenced in claims
 - API — evidence: referenced in claims
 - APIKEY — evidence: referenced in claims
 - API_NET — evidence: referenced in claims
 - ARGS — evidence: referenced in claims
 - ATOMICFAIL — evidence: referenced in claims
 - AUTO_POLICY — evidence: referenced in claims
 - BASHPID — evidence: referenced in claims
 - BATCH_FILE — evidence: referenced in claims
 - BEGIN — evidence: referenced in claims
 - BOM — evidence: referenced in claims
 - BSD — evidence: referenced in claims
 - BUILD_MESSAGES_FILE — evidence: referenced in claims
 - CALL — evidence: referenced in claims
 - CALL_STREAM — evidence: referenced in claims
 - CANONICAL_EXTRAS_DIR — evidence: referenced in claims
 - CHAT — evidence: referenced in claims
 - CHAT_MODE — evidence: referenced in claims
 - CLI — evidence: referenced in claims
 - CONFIG — evidence: referenced in claims
 - CONTENT — evidence: referenced in claims
 - CONVERSATION — evidence: referenced in claims
 - CORE — evidence: referenced in claims
 - CORE_PROVIDER — evidence: referenced in claims
 - CORE_PROVIDER_MAIN — evidence: referenced in claims
 - CORE_PROVIDER_PRO_LOAD — evidence: referenced in claims
 - CORE_PROVIDER_SHOW — evidence: referenced in claims
 - CORE_SETUP — evidence: referenced in claims
 - CORE_SETUP_ACTIONS — evidence: referenced in claims
 - CORE_SETUP_API_CALL — evidence: referenced in claims
 - CORE_SETUP_CLI_PARSE — evidence: referenced in claims
 - CORE_SETUP_DISPATCH_HELPERS — evidence: referenced in claims
 - CORE_SETUP_INPUT_HELPERS — evidence: referenced in claims
 - CORE_SETUP_NORM_FLAGS — evidence: referenced in claims
 - CORE_SETUP_SESSION_ENGINE — evidence: referenced in claims
 - CURL — evidence: referenced in claims
 - CURL_BASE_OPTS — evidence: referenced in claims
 - CURL_CMD — evidence: referenced in claims
 - CURL_CMD_ARR — evidence: referenced in claims
 - DATA — evidence: referenced in claims
 - DDTHH — evidence: referenced in claims
 - DEBUG — evidence: referenced in claims
 - DEBUG_PRESERVE — evidence: referenced in claims
 - DEST_BASE — evidence: referenced in claims
 - DEST_PROV — evidence: referenced in claims
 - DIAG — evidence: referenced in claims
 - DIAGNOSTICS — evidence: referenced in claims
 - DONE — evidence: referenced in claims
 - DRY — evidence: referenced in claims
 - DRYRUN — evidence: referenced in claims
 - DRY_RUN — evidence: referenced in claims
 - END — evidence: referenced in claims
 - ENV — evidence: referenced in claims
 - EOF — evidence: referenced in claims
 - ERRF — evidence: referenced in claims
 - ERROR — evidence: referenced in claims
 - EXIT — evidence: referenced in claims
 - EXTRACT — evidence: referenced in claims
 - EXTRAS — evidence: referenced in claims
 - FILE — evidence: referenced in claims
 - FILE_INPUTS — evidence: referenced in claims
 - FINAL_MODEL — evidence: referenced in claims
 - FORCE_SAVE_MODE — evidence: referenced in claims
 - FORMAT — evidence: referenced in claims
 - FOUND_AND_FILLED — evidence: referenced in claims
 - GNU — evidence: referenced in claims
 - GPL — evidence: referenced in claims
 - GROQBASHERRAPI — evidence: referenced in claims
 - GROQBASHERRBAD_MODEL — evidence: referenced in claims
 - GROQBASHERRCURL_FAILED — evidence: referenced in claims
 - GROQBASHERRINVALID_JSON — evidence: referenced in claims
 - GROQBASHERRNOAPIKEY — evidence: referenced in claims
 - GROQBASHERRNO_PROMPT — evidence: referenced in claims
 - GROQBASHERRTMP — evidence: referenced in claims
 - GROQBASH_API_KEY — evidence: referenced in claims
 - GROQBASH_API_URL — evidence: referenced in claims
 - GROQBASH_CONFIG_DIR — evidence: referenced in claims
 - GROQBASH_DEBUG — evidence: referenced in claims
 - GROQBASH_DIR — evidence: referenced in claims
 - GROQBASH_EDGE_COMPLETION_TOKENS — evidence: referenced in claims
 - GROQBASH_EDGE_EMPTY — evidence: referenced in claims
 - GROQBASH_EDGE_FINISH_REASON — evidence: referenced in claims
 - GROQBASH_EDGE_REQ_ID — evidence: referenced in claims
 - GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET — evidence: referenced in claims
 - GROQBASH_ERR_API — evidence: referenced in claims
 - GROQBASH_ERR_BAD_MODEL — evidence: referenced in claims
 - GROQBASH_ERR_CURL_FAILED — evidence: referenced in claims
 - GROQBASH_ERR_INVALID_JSON — evidence: referenced in claims
 - GROQBASH_ERR_NO_API_KEY — evidence: referenced in claims
 - GROQBASH_ERR_NO_PROMPT — evidence: referenced in claims
 - GROQBASH_ERR_TMP — evidence: referenced in claims
 - GROQBASH_EXTRAS_DIR — evidence: referenced in claims
 - GROQBASH_HISTORY_DIR — evidence: referenced in claims
 - GROQBASH_HISTORY_KEEP_DAYS — evidence: referenced in claims
 - GROQBASH_HISTORY_MAX_BYTES — evidence: referenced in claims
 - GROQBASH_HISTORY_MAX_FILES — evidence: referenced in claims
 - GROQBASH_LOCK_TIMEOUT_HISTORY — evidence: referenced in claims
 - GROQBASH_LOCK_TIMEOUT_MODELS — evidence: referenced in claims
 - GROQBASH_LOCK_TIMEOUT_TMP — evidence: referenced in claims
 - GROQBASH_LOG — evidence: referenced in claims
 - GROQBASH_MODELS_DIR — evidence: referenced in claims
 - GROQBASH_PROVIDER_URL — evidence: referenced in claims
 - GROQBASH_ROOT — evidence: referenced in claims
 - GROQBASH_ROTATE_HISTORY — evidence: referenced in claims
 - GROQBASH_SESSION_ENGINE — evidence: referenced in claims
 - GROQBASH_SESSION_TARGET_BYTES — evidence: referenced in claims
 - GROQBASH_SIG_HASH — evidence: referenced in claims
 - GROQBASH_SKIP_NETWORK — evidence: referenced in claims
 - GROQBASH_SOURCE_ONLY — evidence: referenced in claims
 - GROQBASH_TEMPLATES_DIR — evidence: referenced in claims
 - GROQBASH_TMPDIR — evidence: referenced in claims
 - GROQBASH_TMP_PAYLOAD — evidence: referenced in claims
 - GROQ_API_KEY — evidence: referenced in claims
 - GUI — evidence: referenced in claims
 - HISTORY — evidence: referenced in claims
 - HISTORYFAIL — evidence: referenced in claims
 - HISTORY_LOCK — evidence: referenced in claims
 - HISTORY_SAVE — evidence: referenced in claims
 - HTTP — evidence: referenced in claims
 - IFS — evidence: referenced in claims
 - INFO — evidence: referenced in claims
 - INPUT — evidence: referenced in claims
 - INSTALL_EXTRAS — evidence: referenced in claims
 - INSTALL_EXTRAS_SRC — evidence: referenced in claims
 - INT — evidence: referenced in claims
 - JSON — evidence: referenced in claims
 - JSON_INPUT — evidence: referenced in claims
 - KEY — evidence: referenced in claims
 - LAST_CHECK_LINES — evidence: referenced in claims
 - LEGACY_EXTRAS_DIR — evidence: referenced in claims
 - LEGACY_REAL — evidence: referenced in claims
 - LHS — evidence: referenced in claims
 - LIST_MODELS — evidence: referenced in claims
 - LIST_MODELS_RAW — evidence: referenced in claims
 - LIST_PROVIDERS — evidence: referenced in claims
 - LIST_PROVIDERS_RAW — evidence: referenced in claims
 - LOADED_PROVIDER_NAME — evidence: referenced in claims
 - LOCK — evidence: referenced in claims
 - LOCKFAIL — evidence: referenced in claims
 - LOCKTIMEOUT — evidence: referenced in claims
 - MANIFESTFAIL — evidence: referenced in claims
 - MANIFEST_ADD — evidence: referenced in claims
 - MAX_MODELS — evidence: referenced in claims
 - MAX_RETRIES — evidence: referenced in claims
 - MAX_STAGE_BYTES — evidence: referenced in claims
 - MAX_TOKENS — evidence: referenced in claims
 - MESSAGES_JSON — evidence: referenced in claims
 - MODEL — evidence: referenced in claims
 - MODELREFRESH — evidence: referenced in claims
 - MODELS_FILE — evidence: referenced in claims
 - MODELS_LOCK — evidence: referenced in claims
 - MODEL_CLI_SET — evidence: referenced in claims
 - MODEL_PROVIDER_CFG — evidence: referenced in claims
 - MVP — evidence: referenced in claims
 - NDJSON — evidence: referenced in claims
 - NETWORK — evidence: referenced in claims
 - NON — evidence: referenced in claims
 - NOT — evidence: referenced in claims
 - NOTE — evidence: referenced in claims
 - ORS — evidence: referenced in claims
 - OUTPUT_MODE — evidence: referenced in claims
 - OUT_PATH — evidence: referenced in claims
 - PAYLOAD — evidence: referenced in claims
 - PIPESTATUS — evidence: referenced in claims
 - PRECORE_BOOT — evidence: referenced in claims
 - PRECORE_BOOT_CLI_HELPERS — evidence: referenced in claims
 - PRECORE_BOOT_DIR_PATH — evidence: referenced in claims
 - PRECORE_BOOT_EARLY_HELPERS — evidence: referenced in claims
 - PRECORE_BOOT_HELPERS — evidence: referenced in claims
 - PRECORE_BOOT_SETUP_ENV_CMDS — evidence: referenced in claims
 - PRECORE_BOOT_SETUP_SHELL — evidence: referenced in claims
 - PRECORE_RUN — evidence: referenced in claims
 - PRECORE_RUN_HISTORY — evidence: referenced in claims
 - PRECORE_RUN_MANIFEST — evidence: referenced in claims
 - PRECORE_RUN_RUNTIME_GLOBALS — evidence: referenced in claims
 - PRECORE_RUN_SESSION_CACHE — evidence: referenced in claims
 - PRECORE_RUN_SESSION_MVP — evidence: referenced in claims
 - PRECORE_RUN_UTIL_HELPERS — evidence: referenced in claims
 - PRECORE_SESSION_MVP — evidence: referenced in claims
 - PRECORE_UTIL_HELPERS — evidence: referenced in claims
 - PRINT_CONFIG_DIR — evidence: referenced in claims
 - PRINT_MODEL_FILE — evidence: referenced in claims
 - PRINT_PROVIDER_FILE — evidence: referenced in claims
 - PROVIDER — evidence: referenced in claims
 - PROVIDERS_DIR — evidence: referenced in claims
 - PROVIDER_API_ENV_ — evidence: referenced in claims
 - PROVIDER_CLI — evidence: referenced in claims
 - PROVIDER_DIR — evidence: referenced in claims
 - PROVIDER_FILE — evidence: referenced in claims
 - PROVIDER_INTERACTIVE — evidence: referenced in claims
 - PROVIDER_INTERACTIVE_SELECTED — evidence: referenced in claims
 - PROVIDER_MODULE_LOADED — evidence: referenced in claims
 - PROVIDER_MODULE_PATH — evidence: referenced in claims
 - PWD — evidence: referenced in claims
 - QUIET — evidence: referenced in claims
 - RANDOM — evidence: referenced in claims
 - REDACTED — evidence: referenced in claims
 - REFRESH_MODELS — evidence: referenced in claims
 - REQUEST — evidence: referenced in claims
 - RESP — evidence: referenced in claims
 - RETURN — evidence: referenced in claims
 - ROOT — evidence: referenced in claims
 - RUN — evidence: referenced in claims
 - RUN_TMPDIR — evidence: referenced in claims
 - SCRIPTDIR — evidence: referenced in claims
 - SCRIPT_DATE — evidence: referenced in claims
 - SCRIPT_NAME — evidence: referenced in claims
 - SCRIPT_VERSION — evidence: referenced in claims
 - SEC — evidence: referenced in claims
 - SECTION — evidence: referenced in claims
 - SESSION — evidence: referenced in claims
 - SESSION_CACHE_DIR — evidence: referenced in claims
 - SESSION_DIR — evidence: referenced in claims
 - SESSION_ID — evidence: referenced in claims
 - SESSION_WINDOW — evidence: referenced in claims
 - SET_DEFAULT_MODEL — evidence: referenced in claims
 - SE_AVAILABLE — evidence: referenced in claims
 - SE_ENGINE_PATH — evidence: referenced in claims
 - SHOW_CONFIG — evidence: referenced in claims
 - SRC — evidence: referenced in claims
 - SRC_BASE — evidence: referenced in claims
 - SSZ — evidence: referenced in claims
 - STAGE — evidence: referenced in claims
 - STDIN_CONTENT — evidence: referenced in claims
 - STREAM — evidence: referenced in claims
 - STREAM_MODE — evidence: referenced in claims
 - SUBSECTION — evidence: referenced in claims
 - SUPPORTED — evidence: referenced in claims
 - SUPPORTED_PROVIDERS — evidence: referenced in claims
 - SYSTEM_PROMPT — evidence: referenced in claims
 - TEMPERATURE — evidence: referenced in claims
 - TEMPLATE — evidence: referenced in claims
 - TERM — evidence: referenced in claims
 - THRESHOLD — evidence: referenced in claims
 - TMP — evidence: referenced in claims
 - TMPFAIL — evidence: referenced in claims
 - TMP_LOCK — evidence: referenced in claims
 - TRAILING — evidence: referenced in claims
 - TRUE — evidence: referenced in claims
 - TTY — evidence: referenced in claims
 - TURE — evidence: referenced in claims
 - UI_STATE — evidence: referenced in claims
 - URL — evidence: referenced in claims
 - USAGE — evidence: referenced in claims
 - UTC — evidence: referenced in claims
 - VAL — evidence: referenced in claims
 - VALID_MESSAGES_JSON — evidence: referenced in claims
 - VALUE — evidence: referenced in claims
 - VAR — evidence: referenced in claims
 - WARN — evidence: referenced in claims
 - WARNING — evidence: referenced in claims
 - XXXX — evidence: referenced in claims
 - XXXXXX — evidence: referenced in claims
 - YES — evidence: referenced in claims
 - YYYY — evidence: referenced in claims
 - _API_KEY — evidence: referenced in claims

---

#### 2.2 Appendix: Unreferenced Top‑Level Vars

 - groqbash:1011:MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}"
 - groqbash:1012:HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}"
 - groqbash:1013:TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}"
 - groqbash:1016:GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}"
 - groqbash:1017:GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}"
 - groqbash:1018:GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}"
 - groqbash:1216:GROQBASH_ROTATE_HISTORY="${GROQBASH_ROTATE_HISTORY:-0}"
 - groqbash:1217:GROQBASH_HISTORY_MAX_FILES="${GROQBASH_HISTORY_MAX_FILES:-100}"
 - groqbash:1218:GROQBASH_HISTORY_MAX_BYTES="${GROQBASH_HISTORY_MAX_BYTES:-104857600}" # 100MB
 - groqbash:1219:GROQBASH_HISTORY_KEEP_DAYS="${GROQBASH_HISTORY_KEEP_DAYS:-90}"
 - groqbash:17:SCRIPT_NAME="groqbash"
 - groqbash:18:SCRIPT_VERSION="2.0.0"
 - groqbash:196:SCRIPTDIR="$(resolve_script_dir)"
 - groqbash:1984:SESSION_CACHE_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}/session_cache"
 - groqbash:19:SCRIPT_DATE="2026-05-07"
 - groqbash:2076:CONTENT="${CONTENT:-}"
 - groqbash:2077:JSON_INPUT="${JSON_INPUT:-}"
 - groqbash:2079:SESSION_ID="${SESSION_ID:-}"
 - groqbash:2080:SESSION_WINDOW="${SESSION_WINDOW:-}"
 - groqbash:2082:TEMPLATE="${TEMPLATE:-}"
 - groqbash:2083:BATCH_FILE="${BATCH_FILE:-}"
 - groqbash:2084:CHAT_MODE="${CHAT_MODE:-0}"
 - groqbash:2085:SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}"
 - groqbash:2086:REFRESH_MODELS="${REFRESH_MODELS:-0}"
 - groqbash:2087:LIST_MODELS="${LIST_MODELS:-0}"
 - groqbash:2088:FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-0}"
 - groqbash:2089:OUT_PATH="${OUT_PATH:-}"
 - groqbash:208:CANONICAL_EXTRAS_DIR="${GROQBASH_DIR%/}/extras"
 - groqbash:2090:SYSTEM_PROMPT="${SYSTEM_PROMPT:-}"
 - groqbash:2091:TURE="${TURE:-${TEMPERATURE:-1.0}}"
 - groqbash:2092:TEMPERATURE="${TEMPERATURE:-${TURE:-1.0}}"
 - groqbash:2093:TURE="${TURE:-$TEMPERATURE}"
 - groqbash:2094:MAX_TOKENS="${MAX_TOKENS:-4096}"
 - groqbash:2095:MODEL="${MODEL:-}"
 - groqbash:2096:AUTO_POLICY="${AUTO_POLICY:-preferred}"
 - groqbash:2097:DEBUG="${DEBUG:-0}"
 - groqbash:2098:QUIET="${QUIET:-0}"
 - groqbash:2099:DRY_RUN="${DRY_RUN:-0}"
 - groqbash:209:LEGACY_EXTRAS_DIR="${SCRIPTDIR%/}/extras"
 - groqbash:2100:STREAM_MODE="${STREAM_MODE:-0}"
 - groqbash:2101:OUTPUT_MODE="${OUTPUT_MODE:-text}"
 - groqbash:2102:THRESHOLD="${THRESHOLD:-1000}"
 - groqbash:2103:MAX_RETRIES="${MAX_RETRIES:-3}"
 - groqbash:2104:SUPPORTED_PROVIDERS="${SUPPORTED_PROVIDERS:-groq gemini huggingface}"
 - groqbash:2105:PROVIDER="${PROVIDER:-groq}"
 - groqbash:2117:CURL_BASE_OPTS=( --silent --show-error --no-buffer --max-time 120 )
 - groqbash:212:GROQBASH_EXTRAS_DIR="${CANONICAL_EXTRAS_DIR}"
 - groqbash:2157:GROQ_API_KEY="${GROQ_API_KEY:-}"
 - groqbash:215:PROVIDERS_DIR="${PROVIDERS_DIR:-${GROQBASH_EXTRAS_DIR%/}/providers}"
 - groqbash:221:GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}"
 - groqbash:222:GROQBASH_MODELS_DIR="${GROQBASH_MODELS_DIR:-$GROQBASH_DIR/models}"
 - groqbash:223:GROQBASH_TEMPLATES_DIR="${GROQBASH_TEMPLATES_DIR:-$GROQBASH_DIR/templates}"
 - groqbash:224:GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}"
 - groqbash:225:GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-$GROQBASH_DIR/tmp}"
 - groqbash:226:MODELS_FILE="${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}"
 - groqbash:227:MAX_MODELS="${MAX_MODELS:-200}"
 - groqbash:230:GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR%/}"
 - groqbash:24:GROQBASH_ERR_NO_API_KEY=10
 - groqbash:25:GROQBASH_ERR_BAD_MODEL=11
 - groqbash:26:GROQBASH_ERR_CURL_FAILED=12
 - groqbash:27:GROQBASH_ERR_INVALID_JSON=13
 - groqbash:28:GROQBASH_ERR_NO_PROMPT=14
 - groqbash:29:GROQBASH_ERR_TMP=15
 - groqbash:30:GROQBASH_ERR_API=16
 - groqbash:32:GROQBASHERRNOAPIKEY=$GROQBASH_ERR_NO_API_KEY
 - groqbash:338:PROVIDER_FILE="$(canonical_provider_file)"
 - groqbash:33:GROQBASHERRBAD_MODEL=$GROQBASH_ERR_BAD_MODEL
 - groqbash:34:GROQBASHERRCURL_FAILED=$GROQBASH_ERR_CURL_FAILED
 - groqbash:35:GROQBASHERRINVALID_JSON=$GROQBASH_ERR_INVALID_JSON
 - groqbash:3608:JSON_INPUT="${JSON_INPUT:-}" TEMPLATE="${TEMPLATE:-}" BATCH_FILE="${BATCH_FILE:-}" CHAT_MODE="${CHAT_MODE:-0}" SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}"
 - groqbash:3609:LIST_MODELS="${LIST_MODELS:-0}" LIST_PROVIDERS="${LIST_PROVIDERS:-0}" FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-}" OUT_PATH="${OUT_PATH:-}"
 - groqbash:3610:DRY_RUN="${DRY_RUN:-0}" STREAM_MODE="${STREAM_MODE:-0}" QUIET="${QUIET:-0}" INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}" DEBUG="${DEBUG:-0}"
 - groqbash:3611:PROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}"
 - groqbash:3612:SHOW_CONFIG="${SHOW_CONFIG:-0}" DIAGNOSTICS="${DIAGNOSTICS:-0}"
 - groqbash:3613:FILE_INPUTS=() ARGS=() OUTPUT_MODE="${OUTPUT_MODE:-text}"
 - groqbash:3614:MODEL_CLI_SET="${MODEL_CLI_SET:-0}"
 - groqbash:3615:INSTALL_EXTRAS_SRC=""
 - groqbash:36:GROQBASHERRNO_PROMPT=$GROQBASH_ERR_NO_PROMPT
 - groqbash:3704:SE_ENGINE_PATH="${GROQBASH_EXTRAS_DIR%/}/session/session-engine.sh"
 - groqbash:3705:SE_AVAILABLE=0
 - groqbash:3776:SUPPORTED_PROVIDERS="$(printf '%s ' "${_supported_providers_arr[@]}" | sed 's/ $//')"
 - groqbash:37:GROQBASHERRTMP=$GROQBASH_ERR_TMP
 - groqbash:38:GROQBASHERRAPI=$GROQBASH_ERR_API
 - groqbash:4105:SUPPORTED_PROVIDERS="$(printf '%s ' "${_supported_providers_arr[@]}" | sed 's/ $//')"
 - groqbash:414:DEBUG="${DEBUG:-0}"
 - groqbash:418:DEBUG="${DEBUG:-0}"
 - groqbash:419:GROQBASH_LOG="${GROQBASH_LOG:-}" # optional path to append structured logs
 - groqbash:4459:MODEL="$FINAL_MODEL"
 - groqbash:4462:STDIN_CONTENT=""
 - groqbash:720:DEBUG_PRESERVE="${DEBUG_PRESERVE:-0}"
 - groqbash:987:SESSION_DIR="${GROQBASH_HISTORY_DIR%/}/sessions"

---

### 3) Top‑Level Side‑Effects, Control Flow, Dependencies, Invariants 

#### 3.1 Side‑Effects (conservative summary from evidence):  

```sh
groqbash:1000:  mkdir -p "$d" 2>/dev/null || { printf 'groqbash: ERROR: cannot create directory: %s\n' "$d" >&2; exit "$GROQBASHERRTMP"; }
groqbash:1011:MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}"
groqbash:1012:HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}"
groqbash:1013:TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}"
groqbash:1035:    mkdir -p "$PROVIDER_DIR" 2>/dev/null || { log_error "PROVIDER" "cannot create provider directory."; return 1; }
groqbash:1098:  # --- Write provider capabilities to ui_state (canonical) ---
groqbash:1106:    ui_state_write "provider_capabilities.json" "$prov_json" || log_warn "UI_STATE" "failed to write provider_capabilities for $provider"
groqbash:1142:# Portable file size and listing helpers for rotate_history
groqbash:1222:# rotate_history: all rotation logic executed atomically under HISTORY_LOCK
groqbash:1226:rotate_history() {
groqbash:1228:  local dir="${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}"
groqbash:1233:  lock_exec "${HISTORY_LOCK}" "$timeout" -- sh -c '
groqbash:1304:save_to_history() {
groqbash:1308:  mkdir -p "$GROQBASH_HISTORY_DIR" 2>/dev/null || true
groqbash:1310:  # Create tmp file in history dir to ensure same-filesystem atomic mv
groqbash:1314:    log_error "HISTORYFAIL" "save_to_history: cannot create tmp file in $GROQBASH_HISTORY_DIR"
groqbash:1319:  lockfile="$HISTORY_LOCK"
groqbash:1325:    # --- Write last_history metadata to ui_state ---
groqbash:1330:      history_json="$(jq -c -n --arg path "$dest" --arg base "$basename" --arg ts "$ts" --argjson size "$size_bytes" '{saved:true, path:$path, basename:$base, ts:$ts, size_bytes:$size}')"
groqbash:1331:      ui_state_write "last_history.json" "$history_json" || log_warn "UI_STATE" "failed to write last_history.json"
groqbash:1334:      history_json="$(jq -c -n --arg ts "$ts" '{saved:false, ts:$ts}')"
groqbash:1335:      ui_state_write "last_history.json" "$history_json" || true
groqbash:1340:    rotate_history "$GROQBASH_LOCK_TIMEOUT_HISTORY" || true
groqbash:1359:  mkdir -p "$(dirname "$manifest")" 2>/dev/null || { log_error "MANIFESTFAIL" "manifest_create: cannot create dir"; return 1; }
groqbash:1381:  mkdir -p "$(dirname "$manifest")" 2>/dev/null || true
groqbash:1529:# Tmpdir creation under TMP_LOCK to avoid races
groqbash:1533:  lockfile="$TMP_LOCK"
groqbash:1534:  mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || return "$GROQBASHERRTMP"
groqbash:1541:      mkdir -p "$tmpd"
groqbash:1594:      mkdir -p "$tmp" 2>/dev/null || true
groqbash:161:  printf '\nYou can add that line to your shell profile (e.g., ~/.bashrc or ~/.profile) to persist it across sessions.\n' >&2
groqbash:1645:  local history_dir="${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}"
groqbash:1646:  local session_file="$history_dir/sessions/${sid}.ndjson"
groqbash:1653:  mkdir -p "${history_dir%/}/sessions" 2>/dev/null || true
groqbash:1654:  chmod 700 "${history_dir%/}/sessions" 2>/dev/null || true
groqbash:1660:  mkdir -p "${tmpdir%/}" 2>/dev/null || true
groqbash:1699:  mkdir -p "$(dirname "$out")" 2>/dev/null || true
groqbash:1745:  # --- Update ui_state session metadata after read_window (best-effort) ---
groqbash:1758:      ui_state_write "sessions/${sid}.json" "$meta_json" || log_warn "UI_STATE" "failed to update session meta for $sid (read_window)"
groqbash:1773:  local base_sessions_dir="${SESSION_DIR:-${GROQBASH_HISTORY_DIR:-./groqbash.d}/sessions}"
groqbash:1774:  local session_file="${base_sessions_dir%/}/${sid}.ndjson"
groqbash:1783:  trap 'if [ "${created_marker:-0}" -eq 1 ] && [ -n "${marker_dir:-}" ]; then rm -rf -- "$marker_dir" 2>/dev/null || true; fi' RETURN
groqbash:1801:  if ! mkdir -p "$sess_dir" 2>/dev/null; then
groqbash:1832:    mkdir -p "$marker_dir" 2>/dev/null || true
groqbash:1849:    if [ "${created_marker:-0}" -eq 1 ]; then rm -rf -- "$marker_dir" 2>/dev/null || true; fi
groqbash:1902:        rm -rf -- "$marker_dir" 2>/dev/null || true
groqbash:1926:  # --- Update ui_state session metadata (canonical single source) ---
groqbash:1944:    # Write canonical ui_state session file
groqbash:1945:    ui_state_write "sessions/${sid}.json" "$meta_json" || log_warn "UI_STATE" "failed to write session meta for $sid"
groqbash:1946:    # Update sessions index (best-effort): read existing index, add sid if missing
groqbash:1947:    idx_file="${GROQBASH_CONFIG_DIR%/}/ui_state/sessions/index.json"
groqbash:1949:      if jq -e --arg sid "$sid" '(.sessions // []) | index($sid) // empty' "$idx_file" >/dev/null 2>&1; then
groqbash:1955:          jq --arg sid "$sid" '.sessions = ((.sessions // []) + [$sid])' "$idx_file" > "${tmp_idx}.new" 2>/dev/null && mv -f "${tmp_idx}.new" "$tmp_idx" && ui_state_write "sessions/index.json" "$(cat "$tmp_idx")" || true
groqbash:1961:      ui_state_write "sessions/index.json" "$(jq -c -n --argjson arr '[]' '{sessions:[]}' )" >/dev/null 2>&1 || true
groqbash:1963:      ui_state_write "sessions/index.json" "$(jq -c -n --arg sid "$sid" '{sessions:[$sid]}' )" >/dev/null 2>&1 || true
groqbash:1985:mkdir -p "$SESSION_CACHE_DIR" 2>/dev/null || true
groqbash:2111:  mkdir -p "${GROQBASH_CONFIG_DIR%/}" 2>/dev/null || true
groqbash:224:GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}"
groqbash:245:  if ! mkdir -p "${GROQBASH_CONFIG_DIR}" 2>/dev/null; then
groqbash:2518:  mkdir -p "$(dirname "$RESP")" 2>/dev/null || true
groqbash:2745:  mkdir -p "$(dirname "$RESP")" 2>/dev/null || true
groqbash:275:  mkdir -p "$dir" 2>/dev/null || return 1
groqbash:2790:  # Write last API metadata to ui_state (best-effort)
groqbash:2799:    ui_state_write "last_api.json" "$api_json" || { if [ "${DEBUG:-0}" -eq 1 ]; then log_warn "UI_STATE" "failed to write last_api.json (streaming)"; fi; }
groqbash:2850:        rm -rf "$tmpd"
groqbash:2855:      rm -rf "$tmpd"
groqbash:2866:    rm -rf "$tmpd"
groqbash:2875:    rm -rf "$tmpd"
groqbash:2898:    rm -rf "$tmpd"
groqbash:2914:    rm -rf "$tmpd"
groqbash:2919:  mkdir -p "$(dirname "$MODELS_FILE")" 2>/dev/null || true
groqbash:2927:    rm -rf "$tmpd"
groqbash:2931:  lockfile="$MODELS_LOCK"
groqbash:2938:  ' _ "${MODELS_FILE}.b64" "$MODELS_FILE" || { log_error "MODELREFRESH" "failed to write models file under lock"; rm -rf "$tmpd"; return "$GROQBASHERRTMP"; }
groqbash:2947:  rm -rf "$tmpd"
groqbash:3384:      mkdir -p "$dest_dir" 2>/dev/null || true
groqbash:3391:      # Save via save_to_history which handles atomic tmp creation and rotation
groqbash:3392:      save_to_history "$text" || log_warn "HISTORY" "Failed to save output to history."
groqbash:3424:      ui_last="${GROQBASH_CONFIG_DIR%/}/ui_state/last_api.json"
groqbash:3436:        ui_state_write "last_api.json" "$api_json" || { if [ "${DEBUG:-0}" -eq 1 ]; then log_warn "UI_STATE" "failed to write fallback last_api.json"; fi; }
groqbash:3879:  if ! mkdir -p "$(canonical_config_dir)" 2>/dev/null; then
groqbash:3964:  mkdir -p "${DEST_BASE}" "${DEST_PROV}" 2>/dev/null || { log_error "EXTRAS" "cannot create extras dest: ${DEST_BASE}"; exit "$GROQBASHERRTMP"; }
groqbash:3996:    mkdir -p "$destdir" 2>/dev/null || { log_error "EXTRAS" "cannot create dest dir: $destdir"; exit "$GROQBASHERRTMP"; }
groqbash:4580:      # Ensure sessions dir exists with strict perms
groqbash:4581:      mkdir -p "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:4582:      chmod 700 "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:4661:      mkdir -p "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:4662:      chmod 700 "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:4708:    mkdir -p "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:4709:    chmod 700 "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:470:  mkdir -p "$workdir" 2>/dev/null || { log_error "STAGE" "cannot create workdir $workdir"; return 1; }
groqbash:4826:    mkdir -p "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:4827:    chmod 700 "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:510:  lockfile="${workdir%/}/.groqbash.lock"
groqbash:537:  mkdir -p "$(dirname "$lockfile")" 2>/dev/null || { log_error "LOCKFAIL" "cannot create lockfile dir: $(dirname "$lockfile")"; return 2; }
groqbash:621:  mkdir -p "$destdir" 2>/dev/null || { log_error "ATOMICFAIL" "cannot create dir $destdir"; return "$GROQBASHERRTMP"; }
groqbash:622:  lockfile="${destdir}/.groqbash.lock"
groqbash:759:  mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || { log_error "TMP" "cannot create base tmpdir $GROQBASH_TMPDIR"; return 1; }
groqbash:769:    mkdir -p "$tmpdir" 2>/dev/null || { log_error "TMP" "cannot create fallback RUN_TMPDIR $tmpdir"; return 1; }
groqbash:815:          rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
groqbash:851:        rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
groqbash:869:  mkdir -p "$destdir" 2>/dev/null || { log_error "B64FAIL" "cannot create dir $destdir"; return "$GROQBASHERRTMP"; }
groqbash:871:  lockfile="${destdir%/}/.groqbash.lock"
groqbash:895:# ui_state_write: helper centralizzato per scrivere file JSON per la GUI (atomic)
groqbash:896:# Usage: ui_state_write <relpath> <json-string>
groqbash:897:# Writes to: $GROQBASH_CONFIG_DIR/ui_state/<relpath>
groqbash:899:ui_state_write() {
groqbash:901:  # Usage: ui_state_write filename content_string
groqbash:906:    dir="${GROQBASH_CONFIG_DIR%/}/ui_state"
groqbash:908:    dir="${RUN_TMPDIR%/}/ui_state"
groqbash:912:    log_error "UI_STATE" "ui_state_write requires a filename"
groqbash:916:  mkdir -p "$dir" 2>/dev/null || { log_warn "UI_STATE" "failed to create ui_state dir: $dir"; return 1; }
groqbash:983:mkdir -p "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
groqbash:984:mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || true
groqbash:987:SESSION_DIR="${GROQBASH_HISTORY_DIR%/}/sessions"
groqbash:988:mkdir -p "$SESSION_DIR" 2>/dev/null || true
groqbash:992:mkdir -p "$(canonical_config_dir)" "$GROQBASH_MODELS_DIR" "$GROQBASH_TEMPLATES_DIR" "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" "$GROQBASH_EXTRAS_DIR" "$(canonical_config_dir)/providers" 2>/dev/null || true
```

---

#### 3.2 Dependencies / Required tools:  

```sh
groqbash:1163:  if command -v tac >/dev/null 2>&1; then
groqbash:1457:    *) if command -v stat >/dev/null 2>&1; then perm="$(stat -c %A "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then perm="$(find "$path" -maxdepth 0 -printf '%M' 2>/dev/null || true)"; fi ;;
groqbash:1466:    *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;
groqbash:1481:  if [ "${use_hash}" != "0" ] && command -v sha256sum >/dev/null 2>&1; then
groqbash:1790:    if command -v sha256sum >/dev/null 2>&1; then
groqbash:1792:    elif command -v openssl >/dev/null 2>&1; then
groqbash:1991:  if command -v sha256sum >/dev/null 2>&1; then
groqbash:1993:  elif command -v openssl >/dev/null 2>&1; then
groqbash:2423:  if command -v stdbuf >/dev/null 2>&1; then
groqbash:2472:    if command -v tail >/dev/null 2>&1; then
groqbash:2651:  if command -v stdbuf >/dev/null 2>&1; then
groqbash:539:  if command -v flock >/dev/null 2>&1; then
groqbash:55:for cmd in bash jq curl mktemp stat flock base64 find awk sed grep xargs tr sort head wc tee date mv chmod cp rm printf; do
groqbash:56:  if ! command -v "$cmd" >/dev/null 2>&1; then
groqbash:57:    printf 'groqbash: ERROR: required command not found: %s\n' "$cmd" >&2
groqbash:66:  if command -v readlink >/dev/null 2>&1 && [ -L "$src" ]; then
```

---

### Appendices 

#### Appendix A: claims_map (compact)

C001	VERIFIED	 
EVID_SHEBANG_0001:groqbash:15||EVID_SHEBANG_0002:groqbash:1||EVID_SHEBANG_0003:/data/data/com.termux/files/home/groqbash/list/auto_fill_decls.py:1
C002	VERIFIED	EVID_REQCMD_0046:groqbash:1163||EVID_REQCMD_0047:groqbash:1457||EVID_REQCMD_0048:groqbash:1466
C003	VERIFIED	EVID_HELP_0315:groqbash:1039||EVID_HELP_0316:groqbash:1060||EVID_HELP_0317:groqbash:1071
C004	VERIFIED	EVID_DEBUG_0901:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:49||EVID_DEBUG_0902:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:51||EVID_DEBUG_0903:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:52
C005	VERIFIED	EVID_TRAP_1154:groqbash:805||EVID_TRAP_1155:groqbash:831||EVID_TRAP_1156:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:301
C006	VERIFIED	EVID_TMP_1192:groqbash:1013||EVID_TMP_1193:groqbash:1190||EVID_TMP_1194:groqbash:1197
C007	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000||EVID_CLIPARSE_28725:groqbash:1001||EVID_CLIPARSE_28726:groqbash:1002
C008	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000||EVID_CLIPARSE_28725:groqbash:1001||EVID_CLIPARSE_28726:groqbash:1002
C009	VERIFIED	EVID_HELP_0315:groqbash:1039||EVID_HELP_0316:groqbash:1060||EVID_HELP_0317:groqbash:1071
C010	VERIFIED	EVID_REQCMD_0046:groqbash:1163||EVID_REQCMD_0047:groqbash:1457||EVID_REQCMD_0048:groqbash:1466
C011	VERIFIED	EVID_TMP_1192:groqbash:1013||EVID_TMP_1193:groqbash:1190||EVID_TMP_1194:groqbash:1197
C012	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000||EVID_CLIPARSE_28725:groqbash:1001||EVID_CLIPARSE_28726:groqbash:1002
C013	VERIFIED	EVID_HELP_0315:groqbash:1039||EVID_HELP_0316:groqbash:1060||EVID_HELP_0317:groqbash:1071
C014	VERIFIED	EVID_TMP_1192:groqbash:1013||EVID_TMP_1193:groqbash:1190||EVID_TMP_1194:groqbash:1197
C015	VERIFIED	EVID_CLIPARSE_28724:groqbash:1000||EVID_CLIPARSE_28725:groqbash:1001||EVID_CLIPARSE_28726:groqbash:1002
C016	VERIFIED	EVID_REQCMD_0046:groqbash:1163||EVID_REQCMD_0047:groqbash:1457||EVID_REQCMD_0048:groqbash:1466
C017	VERIFIED	EVID_REQCMD_0046:groqbash:1163||EVID_REQCMD_0047:groqbash:1457||EVID_REQCMD_0048:groqbash:1466||EVID_CLIPARSE_28724:groqbash:1000||EVID_CLIPARSE_28725:groqbash:1001||EVID_CLIPARSE_28726:groqbash:1002
C018	VERIFIED	EVID_TRAP_1154:groqbash:805||EVID_TRAP_1155:groqbash:831||EVID_TRAP_1156:/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:301||EVID_TMP_1192:groqbash:1013||EVID_TMP_1193:groqbash:1190||EVID_TMP_1194:groqbash:1197
C019	VERIFIED	EVID_REQCMD_0046:groqbash:1163||EVID_REQCMD_0047:groqbash:1457||EVID_REQCMD_0048:groqbash:1466

---

#### Appendix B: snippet index (compact)  

C001	EVID_SHEBANG_0001	groqbash:15
C002	EVID_REQCMD_0046	groqbash:1163
C003	EVID_HELP_0315	groqbash:1039
C004	EVID_DEBUG_0901	/data/data/com.termux/files/home/groqbash/list/cli_parsing_blocks.txt:49
C005	EVID_TRAP_1154	groqbash:805
C006	EVID_TMP_1192	groqbash:1013
C007	EVID_CLIPARSE_28724	groqbash:1000
C008	EVID_CLIPARSE_28724	groqbash:1000
C009	EVID_HELP_0315	groqbash:1039
C010	EVID_REQCMD_0046	groqbash:1163
C011	EVID_TMP_1192	groqbash:1013
C012	EVID_CLIPARSE_28724	groqbash:1000
C013	EVID_HELP_0315	groqbash:1039
C014	EVID_TMP_1192	groqbash:1013
C015	EVID_CLIPARSE_28724	groqbash:1000
C016	EVID_REQCMD_0046	groqbash:1163
C017	EVID_REQCMD_0046	groqbash:1163
C018	EVID_TRAP_1154	groqbash:805
C019	EVID_REQCMD_0046	groqbash:1163

---

#### Appendix C: notes  

- Snippets annotated with '# SHARED_SNIPPET:' are shared across claims; the annotation is preserved.
- Evidence entries prefer references to groqbash/groqbash when available.
- To keep prompts short, omit Appendices A–C when pasting to an LLM.

---
