## GroqBash Top‑Level Execution Map

GroqBash Top-Level Execution Model (FULL)

Source: groqbash/ and groqbash/list/ (analysis produced under groqbash/list/analysis/)
Generated: 2026-05-18T16:41:54Z (UTC)

Method: conservative synthesis from claims_map.tsv and evidence_master.tsv

---

1) Execution Order Overview

Short summary:

Step-by-step flow (claims referenced):
Step (C001): Script sets strict shell options and shebang

>>> Evidence snippet for C001:
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

  Evidence:   EVID_SHEBANG_0001:groqbash/groqbash:15; EVID_SHEBANG_0002:groqbash/groqbash:1; EVID_SHEBANG_0003:groqbash/list/auto_fill_decls.py:1; 

Step (C002): Script enforces required system commands at startup

>>> Evidence snippet for C002:
```sh
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

  Evidence:   EVID_REQCMD_0046:groqbash/groqbash:1163; EVID_REQCMD_0047:groqbash/groqbash:1457; EVID_REQCMD_0048:groqbash/groqbash:1466; 

Step (C003): Script defines helper functions for encoding, JSON validation, and logging

>>> Evidence snippet for C003:
```sh
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

  Evidence:   EVID_HELP_0315:groqbash/groqbash:1039; EVID_HELP_0316:groqbash/groqbash:1060; EVID_HELP_0317:groqbash/groqbash:1071; 

Step (C004): Script normalizes DEBUG from GROQBASH_DEBUG/DEBUG

>>> Evidence snippet for C004:
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

  Evidence:   EVID_DEBUG_0901:groqbash/list/cli_parsing_blocks.txt:49; EVID_DEBUG_0902:groqbash/list/cli_parsing_blocks.txt:51; EVID_DEBUG_0903:groqbash/list/cli_parsing_blocks.txt:52; 

Step (C005): Script registers cleanup trap for EXIT/INT/TERM

>>> Evidence snippet for C005:
```sh
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
```sh

  Evidence:   EVID_TRAP_1154:groqbash/groqbash:805; EVID_TRAP_1155:groqbash/groqbash:831; EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301; 

Step (C006): Script uses RUN_TMPDIR/GROQBASH_TMPDIR for staging

>>> Evidence snippet for C006:
```sh
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

  Evidence:   EVID_TMP_1192:groqbash/groqbash:1013; EVID_TMP_1193:groqbash/groqbash:1190; EVID_TMP_1194:groqbash/groqbash:1197; 

Step (C007): Script exposes long CLI flags and parsing markers

>>> Evidence snippet for C007:
```sh
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


  Evidence:   EVID_CLIPARSE_28724:groqbash/groqbash:1000; EVID_CLIPARSE_28725:groqbash/groqbash:1001; EVID_CLIPARSE_28726:groqbash/groqbash:1002; 

Step (C008): Script supports print-only flags that avoid network calls

>>> Evidence snippet for C008:
```sh
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


  Evidence:   EVID_CLIPARSE_28724:groqbash/groqbash:1000; EVID_CLIPARSE_28725:groqbash/groqbash:1001; EVID_CLIPARSE_28726:groqbash/groqbash:1002; 

Step (C009): Script resolves provider and canonical model paths

>>> Evidence snippet for C009:
```sh
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

  Evidence:   EVID_HELP_0315:groqbash/groqbash:1039; EVID_HELP_0316:groqbash/groqbash:1060; EVID_HELP_0317:groqbash/groqbash:1071; 

Step (C011): Network calls are encapsulated in dedicated functions (call_api_groq)

>>> Evidence snippet for C011:
```sh
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

  Evidence:   EVID_TMP_1192:groqbash/groqbash:1013; EVID_TMP_1193:groqbash/groqbash:1190; EVID_TMP_1194:groqbash/groqbash:1197; 

Step (C012): Script uses here-docs or subshells for payload staging

>>> Evidence snippet for C012:
```sh
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


  Evidence:   EVID_CLIPARSE_28724:groqbash/groqbash:1000; EVID_CLIPARSE_28725:groqbash/groqbash:1001; EVID_CLIPARSE_28726:groqbash/groqbash:1002; 

---

2) Top-Level State Model

Top-level variables (conservative list with inferred role and evidence pointers):
 - groqbash/groqbash:1011:MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1012:HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1013:TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1016:GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1017:GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1018:GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1216:GROQBASH_ROTATE_HISTORY="${GROQBASH_ROTATE_HISTORY:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1217:GROQBASH_HISTORY_MAX_FILES="${GROQBASH_HISTORY_MAX_FILES:-100}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1218:GROQBASH_HISTORY_MAX_BYTES="${GROQBASH_HISTORY_MAX_BYTES:-104857600}" # 100MB — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1219:GROQBASH_HISTORY_KEEP_DAYS="${GROQBASH_HISTORY_KEEP_DAYS:-90}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:17:SCRIPT_NAME="groqbash" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:18:SCRIPT_VERSION="2.0.0" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:196:SCRIPTDIR="$(resolve_script_dir)" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:1984:SESSION_CACHE_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}/session_cache" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:19:SCRIPT_DATE="2026-05-07" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2076:CONTENT="${CONTENT:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2077:JSON_INPUT="${JSON_INPUT:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2079:SESSION_ID="${SESSION_ID:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2080:SESSION_WINDOW="${SESSION_WINDOW:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2082:TEMPLATE="${TEMPLATE:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2083:BATCH_FILE="${BATCH_FILE:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2084:CHAT_MODE="${CHAT_MODE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2085:SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2086:REFRESH_MODELS="${REFRESH_MODELS:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2087:LIST_MODELS="${LIST_MODELS:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2088:FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2089:OUT_PATH="${OUT_PATH:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:208:CANONICAL_EXTRAS_DIR="${GROQBASH_DIR%/}/extras" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2090:SYSTEM_PROMPT="${SYSTEM_PROMPT:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2091:TURE="${TURE:-${TEMPERATURE:-1.0}}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2092:TEMPERATURE="${TEMPERATURE:-${TURE:-1.0}}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2093:TURE="${TURE:-$TEMPERATURE}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2094:MAX_TOKENS="${MAX_TOKENS:-4096}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2095:MODEL="${MODEL:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2096:AUTO_POLICY="${AUTO_POLICY:-preferred}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2097:DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2098:QUIET="${QUIET:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2099:DRY_RUN="${DRY_RUN:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:209:LEGACY_EXTRAS_DIR="${SCRIPTDIR%/}/extras" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2100:STREAM_MODE="${STREAM_MODE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2101:OUTPUT_MODE="${OUTPUT_MODE:-text}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2102:THRESHOLD="${THRESHOLD:-1000}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2103:MAX_RETRIES="${MAX_RETRIES:-3}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2104:SUPPORTED_PROVIDERS="${SUPPORTED_PROVIDERS:-groq gemini huggingface}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2105:PROVIDER="${PROVIDER:-groq}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2117:CURL_BASE_OPTS=( --silent --show-error --no-buffer --max-time 120 ) — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:212:GROQBASH_EXTRAS_DIR="${CANONICAL_EXTRAS_DIR}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:2157:GROQ_API_KEY="${GROQ_API_KEY:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:215:PROVIDERS_DIR="${PROVIDERS_DIR:-${GROQBASH_EXTRAS_DIR%/}/providers}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:221:GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:222:GROQBASH_MODELS_DIR="${GROQBASH_MODELS_DIR:-$GROQBASH_DIR/models}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:223:GROQBASH_TEMPLATES_DIR="${GROQBASH_TEMPLATES_DIR:-$GROQBASH_DIR/templates}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:224:GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:225:GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-$GROQBASH_DIR/tmp}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:226:MODELS_FILE="${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:227:MAX_MODELS="${MAX_MODELS:-200}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:230:GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR%/}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:24:GROQBASH_ERR_NO_API_KEY=10 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:25:GROQBASH_ERR_BAD_MODEL=11 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:26:GROQBASH_ERR_CURL_FAILED=12 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:27:GROQBASH_ERR_INVALID_JSON=13 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:28:GROQBASH_ERR_NO_PROMPT=14 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:29:GROQBASH_ERR_TMP=15 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:30:GROQBASH_ERR_API=16 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:32:GROQBASHERRNOAPIKEY=$GROQBASH_ERR_NO_API_KEY — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:338:PROVIDER_FILE="$(canonical_provider_file)" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:33:GROQBASHERRBAD_MODEL=$GROQBASH_ERR_BAD_MODEL — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:34:GROQBASHERRCURL_FAILED=$GROQBASH_ERR_CURL_FAILED — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:35:GROQBASHERRINVALID_JSON=$GROQBASH_ERR_INVALID_JSON — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3608:JSON_INPUT="${JSON_INPUT:-}" TEMPLATE="${TEMPLATE:-}" BATCH_FILE="${BATCH_FILE:-}" CHAT_MODE="${CHAT_MODE:-0}" SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3609:LIST_MODELS="${LIST_MODELS:-0}" LIST_PROVIDERS="${LIST_PROVIDERS:-0}" FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-}" OUT_PATH="${OUT_PATH:-}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3610:DRY_RUN="${DRY_RUN:-0}" STREAM_MODE="${STREAM_MODE:-0}" QUIET="${QUIET:-0}" INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}" DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3611:PROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3612:SHOW_CONFIG="${SHOW_CONFIG:-0}" DIAGNOSTICS="${DIAGNOSTICS:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3613:FILE_INPUTS=() ARGS=() OUTPUT_MODE="${OUTPUT_MODE:-text}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3614:MODEL_CLI_SET="${MODEL_CLI_SET:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3615:INSTALL_EXTRAS_SRC="" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:36:GROQBASHERRNO_PROMPT=$GROQBASH_ERR_NO_PROMPT — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3704:SE_ENGINE_PATH="${GROQBASH_EXTRAS_DIR%/}/session/session-engine.sh" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3705:SE_AVAILABLE=0 — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:3776:SUPPORTED_PROVIDERS="$(printf '%s ' "${_supported_providers_arr[@]}" | sed 's/ $//')" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:37:GROQBASHERRTMP=$GROQBASH_ERR_TMP — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:38:GROQBASHERRAPI=$GROQBASH_ERR_API — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:4105:SUPPORTED_PROVIDERS="$(printf '%s ' "${_supported_providers_arr[@]}" | sed 's/ $//')" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:414:DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:418:DEBUG="${DEBUG:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:419:GROQBASH_LOG="${GROQBASH_LOG:-}" # optional path to append structured logs — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:4459:MODEL="$FINAL_MODEL" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:4462:STDIN_CONTENT="" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:720:DEBUG_PRESERVE="${DEBUG_PRESERVE:-0}" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)
 - groqbash/groqbash:987:SESSION_DIR="${GROQBASH_HISTORY_DIR%/}/sessions" — role: inferred; configurable via ENV: unknown — evidence: (evidence: none found)

Relationships (conservative):
 - RUN_TMPDIR contains PAYLOAD, RESP, ERRF; DEBUG influences cleanup behavior.

---

3) Top-Level Side-Effects

Observed side-effects (each with conservative description):
 - Creates directories for tmp, sessions, ui_state; writes payload/response/error files; uses lock files to coordinate.

---

4) Top-Level Control Flow

Main branches (conservative):
 - Print-only / dry-run: recognized by long flags; avoids network calls.
 - Normal run: parse CLI → resolve provider → prepare tmp → build payload → call API → handle response → cleanup.
 - Early exit: help/version, source-only, missing deps, invalid provider perms.

For each branch, see claims_map.tsv for evidence pointers.

---

5) Top-Level Dependencies

Conservative list of required tools (typical): bash, jq, curl, mktemp, stat, flock, base64, awk, sed, grep, xargs, tr, sort, head, wc, tee, date, mv, chmod, cp, rm, printf.
Behavior: script checks for required commands and exits early if missing.

---

6) Top-Level Behavioral Guarantees (Invariants)

 - If GROQBASH_SOURCE_ONLY is set, main runtime does not execute
   Evidence:   EVID_REQCMD_0046:groqbash/groqbash:1163; EVID_REQCMD_0047:groqbash/groqbash:1457; EVID_REQCMD_0048:groqbash/groqbash:1466; 

 - Temporary artifacts are removed on exit unless debug-preserve
   Evidence:   EVID_TRAP_1154:groqbash/groqbash:805; EVID_TRAP_1155:groqbash/groqbash:831; EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301; 

 - Provider modules are validated before sourcing
   Evidence:   EVID_REQCMD_0046:groqbash/groqbash:1163; EVID_REQCMD_0047:groqbash/groqbash:1457; EVID_REQCMD_0048:groqbash/groqbash:1466; 

 - Script enforces required system commands at startup
   Evidence:   EVID_REQCMD_0046:groqbash/groqbash:1163; EVID_REQCMD_0047:groqbash/groqbash:1457; EVID_REQCMD_0048:groqbash/groqbash:1466; 

 - Script registers cleanup trap for EXIT/INT/TERM
   Evidence:   EVID_TRAP_1154:groqbash/groqbash:805; EVID_TRAP_1155:groqbash/groqbash:831; EVID_TRAP_1156:groqbash/list/cli_parsing_blocks.txt:301; 

---

Appendix: key analysis files (for traceability)
 - groqbash/list/analysis/evidence_master.tsv
 - groqbash/list/analysis/claims_map.tsv
 - groqbash/list/analysis/*_raw.txt

End of file.
