########################################
# SECTION: PRECORE - BEGIN
########################################
#--1<---[ SECTION: PRECORE_SETUP_SHELL ]--->1--
set -euo pipefail

SCRIPT_NAME="groqbash"
SCRIPT_VERSION="2.0.0"
SCRIPT_DATE="2026-05-07"

# ---------------------------------------------------------------------------
# Canonical error codes
# ---------------------------------------------------------------------------
GROQBASH_ERR_NO_API_KEY=10
GROQBASH_ERR_BAD_MODEL=11
GROQBASH_ERR_CURL_FAILED=12
GROQBASH_ERR_INVALID_JSON=13
GROQBASH_ERR_NO_PROMPT=14
GROQBASH_ERR_TMP=15
GROQBASH_ERR_API=16

GROQBASHERRNOAPIKEY=$GROQBASH_ERR_NO_API_KEY
GROQBASHERRBAD_MODEL=$GROQBASH_ERR_BAD_MODEL
GROQBASHERRCURL_FAILED=$GROQBASH_ERR_CURL_FAILED
GROQBASHERRINVALID_JSON=$GROQBASH_ERR_INVALID_JSON
GROQBASHERRNO_PROMPT=$GROQBASH_ERR_NO_PROMPT
GROQBASHERRTMP=$GROQBASH_ERR_TMP
GROQBASHERRAPI=$GROQBASH_ERR_API
#--1<---[ /SECTION: PRECORE_SETUP_SHELL ]--->1--
#--2<---[ SECTION: PRECORE_SETUP_ENV_CMDS ]--->2--
# ---------------------------------------------------------------------------
# Dev/Test guard for sourcing only
# ---------------------------------------------------------------------------
# When set to 1, importing the script (GROQBASH_SOURCE_ONLY=1 . ./groqbash)
# will load function definitions without executing the main runtime flow.
if [ "${GROQBASH_SOURCE_ONLY:-0}" -eq 1 ]; then
  # If sourced from a shell, return to the caller; if executed directly,
  # exit with success to avoid running the main program.
  return 0 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------------------
# Verify mandatory commands (no fallback)
# ---------------------------------------------------------------------------
for cmd in bash jq curl mktemp stat flock base64 find awk sed grep xargs tr sort head wc tee date mv chmod cp rm printf; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'groqbash: ERROR: required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
done
#--2<---[ /SECTION: PRECORE_SETUP_ENV_CMDS ]--->2--
#--3<---[ SECTION: PRECORE_EARLY_HELPERS ]--->3--
# Early Helpers 
resolve_script_dir() {
  local src="$0" rl dir
  if command -v readlink >/dev/null 2>&1 && [ -L "$src" ]; then
    rl="$(readlink "$src" 2>/dev/null || true)"
    [ -n "$rl" ] && case "$rl" in /*) src="$rl" ;; *) src="$(dirname "$src")/$rl" ;; esac
  fi
  dir="$(cd "$(dirname "$src")" >/dev/null 2>&1 && pwd || printf '%s' "$(dirname "$src")")"
  printf '%s' "$dir"
}
# Return canonical config dir (no trailing slash)
canonical_config_dir() {
  printf '%s' "${GROQBASH_CONFIG_DIR%/}"
}

# Return canonical provider file path
canonical_provider_file() {
  printf '%s\n' "$(canonical_config_dir)/provider"
}

# Return canonical model file path for a provider argument
canonical_model_file() {
  local prov="${1:-}"
  printf '%s\n' "$(canonical_config_dir)/model.${prov}"
}

# Minimal provider-url helpers (embedded groq fallback)
# Returns canonical provider-url file path: <config_dir>/provider-url
canonical_provider_url_file() {
  # prefer canonical_config_dir() if present
  if type canonical_config_dir >/dev/null 2>&1; then
    cfgdir="$(canonical_config_dir)"
  else
    cfgdir="${GROQBASH_CONFIG_DIR:-${GROQBASH_DIR%/}/config}"
  fi
  printf '%s' "${cfgdir%/}/provider-url"
}

#--3<---[ SUBSECTION: API_NET ]--->3--
# ensure_api_key_for_provider (robusta, non-interactive safe)
# - Garantisce che la API key per il provider sia presente.
# - In modalità non-interattiva (stdin non TTY) non prompta: esce con codice d'errore.
# - In modalità interattiva prompta come prima.
# - Sincronizza GROQ_API_KEY per compatibilità retro.
# ---------------------------------------------------------------------------
ensure_api_key_for_provider() {
  local prov="$1"
  local envvar current_key input_key custom_var custom_env
  [ -n "$prov" ] || return 1
  envvar="$(provider_api_env_var_name "$prov")"
  custom_var="PROVIDER_API_ENV_${prov}"
  custom_env="${!custom_var:-}"
  if [ -n "$custom_env" ]; then
    envvar="$custom_env"
  fi
  current_key="${!envvar:-}"

  # If key present, sync groq alias and return
  if [ -n "$current_key" ]; then
    if [ "$prov" = "groq" ] && [ "$envvar" != "GROQ_API_KEY" ]; then
      export GROQ_API_KEY="$current_key"
    fi
    return 0
  fi

  # Non-interactive: fail fast with clear error (do not prompt)
  if [ ! -t 0 ]; then
    printf 'groqbash: ERROR: missing API key for provider %s (env %s) in non-interactive mode\n' "$prov" "$envvar" >&2
    return "$GROQBASHERRNOAPIKEY"
  fi

  # Interactive prompt (preserve previous behavior)
  printf 'Enter API key for provider %s (env %s): ' "$prov" "$envvar" >&2
  if ! IFS= read -r input_key; then
    printf '\ngroqbash: ERROR: no input received. Aborting.\n' >&2
    return "$GROQBASHERRNOAPIKEY"
  fi

  # Normalize input: strip CR/LF, leading "export ", and VAR=VALUE forms
  input_key="$(printf '%s' "$input_key" | tr -d '\r\n')"
  input_key="$(printf '%s' "$input_key" | sed -E 's/^[[:space:]]*export[[:space:]]+//I')"
  if printf '%s' "$input_key" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*='; then
    input_key="$(printf '%s' "$input_key" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*=[\"\x27]?([^\"\x27]*).*$/\1/')"
  fi

  if [ -z "$input_key" ]; then
    printf 'groqbash: ERROR: API key required. Aborting.\n' >&2
    return "$GROQBASHERRNOAPIKEY"
  fi

  export "$envvar"="$input_key"
  if [ "$prov" = "groq" ] && [ "$envvar" != "GROQ_API_KEY" ]; then
    export GROQ_API_KEY="$input_key"
  fi

  printf '\n--------------------------------------\n' >&2
  printf '\nTo avoid re-entering the key for subsequent invocations, run this in your shell:\n' >&2
  printf '\n export %s="%s"\n' "$envvar" "$input_key" >&2
  printf '\nYou can add that line to your shell profile (e.g., ~/.bashrc or ~/.profile) to persist it across sessions.\n' >&2
  printf '\n--------------------------------------\n' >&2

  return 0
}

# ---------------------------------------------------------------------------
# enforce_network_policy
# - Central check to prevent any HTTP call when DRY_RUN or GROQBASH_SKIP_NETWORK set.
# - Should be invoked at the start of any provider call_api_* function.
# - Returns 0 if network allowed, non-zero otherwise.
# ---------------------------------------------------------------------------
enforce_network_policy() {
  # If DRY_RUN or GROQBASH_SKIP_NETWORK are truthy, disallow network.
  if is_truthy "${DRY_RUN:-0}" || is_truthy "${GROQBASH_SKIP_NETWORK:-0}"; then
    if [ "${DEBUG:-0}" -eq 1 ]; then
      log_info "NETWORK" "Network calls disabled by DRY_RUN or GROQBASH_SKIP_NETWORK; skipping HTTP."
    fi
    return 1
  fi

  # QUIET does not disable network by itself, but if QUIET is used with a policy variable we enforce it.
  if is_truthy "${GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET:-0}" && is_truthy "${QUIET:-0}"; then
    if [ "${DEBUG:-0}" -eq 1 ]; then
      log_info "NETWORK" "Network calls disabled due to QUIET policy."
    fi
    return 1
  fi

  return 0
}
#--3<---[ /SUBSECTION: API_NET ]--->3--
#--3<---[ /SECTION: PRECORE_EARLY_HELPERS ]--->3--

#--4<---[ SECTION: PRECORE_DIR_PATH ]--->4--
SCRIPTDIR="$(resolve_script_dir)"
# Allow external override of repository root via GROQBASH_ROOT.
# Priority: explicit GROQBASH_DIR env > GROQBASH_ROOT env > SCRIPTDIR-derived default.
if [ -n "${GROQBASH_DIR:-}" ]; then
  : # keep explicit GROQBASH_DIR from environment
elif [ -n "${GROQBASH_ROOT:-}" ]; then
  GROQBASH_DIR="${GROQBASH_ROOT%/}/groqbash.d"
else
  GROQBASH_DIR="$SCRIPTDIR/groqbash.d"
fi

# Canonical runtime destination for extras (always under groqbash.d)
CANONICAL_EXTRAS_DIR="${GROQBASH_DIR%/}/extras"
LEGACY_EXTRAS_DIR="${SCRIPTDIR%/}/extras"

# Export canonical extras and providers dirs
GROQBASH_EXTRAS_DIR="${CANONICAL_EXTRAS_DIR}"
# Providers shipped as extras live under GROQBASH_EXTRAS_DIR by default;
# fall back to a providers dir under canonical config dir only if extras not set.
PROVIDERS_DIR="${PROVIDERS_DIR:-${GROQBASH_EXTRAS_DIR%/}/providers}"
# Ensure a canonical fallback exists if extras not configured
: "${PROVIDERS_DIR:=$(canonical_config_dir)/providers}"
export GROQBASH_EXTRAS_DIR PROVIDERS_DIR

# Standard directories (derived from GROQBASH_DIR, overridable via env)
GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}"
GROQBASH_MODELS_DIR="${GROQBASH_MODELS_DIR:-$GROQBASH_DIR/models}"
GROQBASH_TEMPLATES_DIR="${GROQBASH_TEMPLATES_DIR:-$GROQBASH_DIR/templates}"
GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}"
GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-$GROQBASH_DIR/tmp}"
MODELS_FILE="${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}"
MAX_MODELS="${MAX_MODELS:-200}"

# Defensive normalization: ensure GROQBASH_CONFIG_DIR is non-empty and normalized
GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR%/}"
if [ -z "$GROQBASH_CONFIG_DIR" ]; then
  GROQBASH_CONFIG_DIR="${GROQBASH_DIR%/}/config"
fi
#--4<---[ /SECTION: PRECORE_DIR_PATH ]--->4--

# Helper: ensure config dir exists and is usable before any writes
ensure_config_dir() {
  # Normalize
  GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR%/}"
  if [ -z "$GROQBASH_CONFIG_DIR" ]; then
    GROQBASH_CONFIG_DIR="${GROQBASH_DIR%/}/config"
  fi

  # Try to create directory (idempotent)
  if ! mkdir -p "${GROQBASH_CONFIG_DIR}" 2>/dev/null; then
    log_error "CONFIG" "cannot create config dir: ${GROQBASH_CONFIG_DIR}"
    return 1
  fi

  # Enforce strict perms
  chmod 700 "${GROQBASH_CONFIG_DIR}" 2>/dev/null || true

  # Quick writability check: try to create a temp file inside
  if ! : > "${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check" 2>/dev/null; then
    log_error "CONFIG" "config dir not writable: ${GROQBASH_CONFIG_DIR}"
    return 1
  else
    rm -f "${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check" 2>/dev/null || true
  fi

  return 0
}

# Ensure config dir exists now (fail early if not)
ensure_config_dir || { log_error "CONFIG" "config dir unavailable; aborting."; exit "$GROQBASHERRTMP"; }

# Write provider-url file (single-line, non-secret). Best-effort; do not write API keys.
# Usage: write_provider_url_if_missing <provider> <url>
write_provider_url_if_missing() {
  local prov="$1" url="$2" file dir tmp
  [ -z "$prov" ] && return 1
  [ -z "$url" ] && return 1
  file="$(canonical_provider_url_file)"
  dir="$(dirname "$file")"
  mkdir -p "$dir" 2>/dev/null || return 1
  # If file already exists and non-empty, do nothing
  if [ -f "$file" ] && [ -s "$file" ]; then
    return 0
  fi
  # Write atomically into RUN_TMPDIR if available, else directly (best-effort)
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "${RUN_TMPDIR:-}" ]; then
    tmp="$(mktemp -p "${RUN_TMPDIR}" provider-url.XXXX 2>/dev/null || true)"
  else
    tmp="$(mktemp 2>/dev/null || true)"
  fi
  if [ -n "$tmp" ]; then
    printf '%s\n' "$url" > "$tmp"
    mv -f "$tmp" "$file" 2>/dev/null || cp -f "$tmp" "$file" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || true; return 1; }
    chmod 600 "$file" 2>/dev/null || true
    return 0
  else
    # fallback: write directly
    printf '%s\n' "$url" > "$file" 2>/dev/null || return 1
    chmod 600 "$file" 2>/dev/null || true
    return 0
  fi
}

# Resolve provider URL with priority: ENV (GROQBASH_API_URL / GROQBASH_PROVIDER_URL) > provider-url file > embedded default (groq)
# Usage: resolve_provider_url <provider>
resolve_provider_url() {
  local prov="${1:-$PROVIDER}" prov_file prov_val
  # 1) ENV
  if [ -n "${GROQBASH_API_URL:-}" ]; then
    GROQBASH_PROVIDER_URL="${GROQBASH_API_URL}"
    export GROQBASH_PROVIDER_URL
    return 0
  fi
  if [ -n "${GROQBASH_PROVIDER_URL:-}" ]; then
    return 0
  fi
  # 2) provider-url file
  prov_file="$(canonical_provider_url_file)"
  if [ -f "$prov_file" ] && [ -s "$prov_file" ]; then
    prov_val="$(sed -n '1p' "$prov_file" 2>/dev/null | awk '{$1=$1;print}')"
    if [ -n "$prov_val" ]; then
      GROQBASH_PROVIDER_URL="$prov_val"
      export GROQBASH_PROVIDER_URL
      return 0
    fi
  fi
  # 3) embedded default for groq only (minimal)
  if [ "${prov:-}" = "groq" ]; then
    GROQBASH_PROVIDER_URL="https://api.groq.com/openai/v1/chat/completions"
    export GROQBASH_PROVIDER_URL
    return 0
  fi
  return 1
}

# Fail-fast if canonical_config_dir is empty for any reason
if [ -z "$(canonical_config_dir)" ]; then
  printf 'groqbash: ERROR: CONFIG: canonical config dir is empty; aborting.\n' >&2
  exit 1
fi

# Canonical PROVIDER_FILE path built only from GROQBASH_CONFIG_DIR
PROVIDER_FILE="$(canonical_provider_file)"

#--5<---[ SECTION: PRECORE_HELPERS ]--->5--
# Provider API key helpers (available early)
# - provider_api_env_var_name <prov> -> prints canonical env var name (e.g., GROQ_API_KEY)
# - ensure_api_key_for_provider <prov> -> ensures API key is set (may prompt interactively)
provider_api_env_var_name() {
  local prov="$1"
  local prov_upper
  prov_upper="$(printf '%s' "$prov" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')"
  printf '%s' "${prov_upper}_API_KEY"
}

# Check if a string is valid JSON (non-empty, parsable by jq)
is_valid_json_string() {
  local s="$1"
  [ -n "${s:-}" ] || return 1
  printf '%s' "$s" | jq -e . >/dev/null 2>&1
}

# Portable base64 wrappers (Linux, macOS, BusyBox)
# - b64encode: reads stdin, writes base64 without newlines
# - b64decode: reads base64 stdin, writes decoded bytes
# These functions replace all direct base64 calls.
b64encode() {
  # Use base64 with wrap option if available; ensure single-line output
  if [ -n "${B64_WRAP_OPT:-}" ]; then
    base64 ${B64_WRAP_OPT}
  else
    base64 | tr -d '\n'
  fi
}

b64decode() {
  # Use base64 with decode option if set; fall back to -d explicitly
  if [ -n "${B64_DECODE_OPT:-}" ]; then
    base64 ${B64_DECODE_OPT}
  else
    base64 -d
  fi
}

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|True|yes|YES|Yes) return 0 ;;
    *) return 1 ;;
  esac
}

# - file_size returns bytes (portable)
file_size() {
  local f="$1"
  if [ -z "$f" ] || [ ! -f "$f" ]; then
    printf '0'
    return 0
  fi
  case "$(uname 2>/dev/null || echo Linux)" in
    Darwin) stat -f %z "$f" 2>/dev/null || printf '0' ;;
    *) stat -c %s "$f" 2>/dev/null || printf '0' ;;
  esac
}

# Check if a file contains valid JSON (non-empty, parsable by jq)
is_valid_json_file() {
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
# Logging structured (activabile via DEBUG o GROQBASH_LOG)
DEBUG="${DEBUG:-0}"
GROQBASH_LOG="${GROQBASH_LOG:-}" # optional path to append structured logs

log_prefix() { printf 'groqbash: %s: ' "$SCRIPT_NAME"; }

log_info() {
  local code="${1:-INFO}" msg="${2:-}"
  if [ "${DEBUG:-0}" -eq 1 ]; then
    printf '%sINFO: %s: %s\n' "$(log_prefix)" "$code" "$msg" >&2
  fi
  if [ -n "$GROQBASH_LOG" ]; then printf '%s INFO %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$msg" >>"$GROQBASH_LOG" 2>/dev/null || true; fi
}

log_warn() {
  local code="${1:-WARN}" msg="${2:-}"
  printf '%sWARN: %s: %s\n' "$(log_prefix)" "$code" "$msg" >&2
  if [ -n "$GROQBASH_LOG" ]; then printf '%s WARN %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$msg" >>"$GROQBASH_LOG" 2>/dev/null || true; fi
}

log_error() {
  local code="${1:-ERROR}" msg="${2:-}"
  printf '%sERROR: %s: %s\n' "$(log_prefix)" "$code" "$msg" >&2
  if [ -n "$GROQBASH_LOG" ]; then printf '%s ERROR %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$msg" >>"$GROQBASH_LOG" 2>/dev/null || true; fi
}

# debug helper: if DEBUG is (1)
dbg() {
  if [ "${DEBUG:-0}" -ne 0 ]; then
    printf '%s\n' "$*" >&2
  fi
}

# stage_b64: read stdin, write atomic base64 staging file under RUN_TMPDIR or destdir
# Usage: stage_b64 <dest_b64_path> <max_bytes>
stage_b64() {
  # Dual-mode stage_b64:
  # - If called with two args: stage_b64 /path/to/src /path/to/dst.b64
  # - If called with one arg: stage_b64 /path/to/dst.b64  (reads stdin)
  local src dst max_bytes tmp_local tmp_b64 workdir size b64_opts
  if [ "$#" -eq 2 ]; then
    src="$1"; dst="$2"
  elif [ "$#" -eq 1 ]; then
    dst="$1"
    src=""
  else
    log_error "STAGE" "stage_b64 usage: stage_b64 [src] dst"
    return 1
  fi

  max_bytes="${MAX_STAGE_BYTES:-10485760}" # default 10MB
  [ -n "$dst" ] || return 1
  workdir="$(dirname "$dst")"
  mkdir -p "$workdir" 2>/dev/null || { log_error "STAGE" "cannot create workdir $workdir"; return 1; }

  # If src provided, validate it; else read stdin into tmp_local
  if [ -n "$src" ]; then
    if [ ! -f "$src" ] || [ ! -s "$src" ]; then
      log_error "STAGE" "stage_b64: source payload missing or empty: $src"
      return 1
    fi
    tmp_local="$src"
    tmp_local_is_temp=0
  else
    tmp_local="$(mktemp "${RUN_TMPDIR%/}/payload.tmp.XXXXXX" 2>/dev/null || true)"
    [ -n "$tmp_local" ] || tmp_local="${RUN_TMPDIR%/}/payload.tmp.$$"
    if ! cat - > "$tmp_local" 2>/dev/null; then
      rm -f -- "$tmp_local" 2>/dev/null || true
      log_error "STAGE" "failed to write staging payload from stdin"
      return 1
    fi
    tmp_local_is_temp=1
  fi

  # Size check
  size="$(file_size "$tmp_local" 2>/dev/null || echo 0)"
  if [ "$size" -gt "$max_bytes" ]; then
    log_error "STAGE" "staged payload exceeds max allowed size ($size > $max_bytes)"
    [ "$tmp_local_is_temp" -eq 1 ] && rm -f -- "$tmp_local" 2>/dev/null || true
    return 1
  fi

  # Create base64 staging file atomically in workdir
  tmp_b64="$(mktemp "${workdir%/}/.groq-b64.XXXXXX" 2>/dev/null || true)"
  [ -n "$tmp_b64" ] || tmp_b64="${workdir%/}/.groq-b64.$$.$RANDOM"
  if [ -n "${B64_WRAP_OPT:-}" ]; then
    base64 ${B64_WRAP_OPT} "$tmp_local" > "$tmp_b64" 2>/dev/null || { rm -f -- "$tmp_local" "$tmp_b64" 2>/dev/null || true; return 1; }
  else
    base64 "$tmp_local" > "$tmp_b64" 2>/dev/null || { rm -f -- "$tmp_local" "$tmp_b64" 2>/dev/null || true; return 1; }
  fi
  chmod 600 "$tmp_b64" 2>/dev/null || true

  # Atomic move into place under lock if available
  lockfile="${workdir%/}/.groqbash.lock"
  if type lock_exec >/dev/null 2>&1; then
    lock_exec "$lockfile" 10 -- sh -c 'set -e; mv -f -- "$1" "$2"; chmod 600 "$2" 2>/dev/null || true' _ "$tmp_b64" "$dst" || { rm -f -- "$tmp_local" "$tmp_b64" 2>/dev/null || true; return 1; }
  else
    mv -f "$tmp_b64" "$dst" 2>/dev/null || { rm -f -- "$tmp_local" "$tmp_b64" 2>/dev/null || true; return 1; }
  fi

  [ "$tmp_local_is_temp" -eq 1 ] && rm -f -- "$tmp_local" 2>/dev/null || true
  if [ "${DEBUG:-0}" -eq 1 ]; then
    log_info "STAGE" "staged base64 payload: $dst (size $(wc -c < "$dst" 2>/dev/null)B)"
  fi
  return 0
}

# lock_exec: acquire exclusive flock on a lockfile with timeout (improved)
# Usage: lock_exec <lockfile> <timeout> -- <command> [args...]
# Guarantees: acquista lock, esegue comando in subshell, rilascia lock sempre.
lock_exec() {
  local lockfile="$1"
  local timeout="${2:-10}"
  shift 2
  if [ "$1" != "--" ]; then
    log_error "USAGE" "lock_exec <lockfile> <timeout> -- <cmd> [args...]"
    return 2
  fi
  shift

  mkdir -p "$(dirname "$lockfile")" 2>/dev/null || { log_error "LOCKFAIL" "cannot create lockfile dir: $(dirname "$lockfile")"; return 2; }

  if command -v flock >/dev/null 2>&1; then
    # Use a dedicated file descriptor to ensure lock is released when subshell exits
    (
      # Open FD 9 for the lockfile inside subshell to avoid leaking FDs to caller
      exec 9>"$lockfile"
      if ! flock -x -w "$timeout" 9; then
        printf '%sERROR: LOCKTIMEOUT: could not acquire lock on %s within %s seconds\n' "$(log_prefix)" "$lockfile" "$timeout" >&2
        exit 124
      fi
      # Execute the requested command in this subshell under lock
      set -e
      "$@"
    )
    rc=$?
    return $rc
  fi

  # flock missing: fail with clear message
  log_error "LOCK" "flock not available; cannot acquire lock on $lockfile. Install util-linux/coreutils or run on supported platform."
  return 2
}

# Compatibility wrapper: _mktemp_in_dir -> uses _tmpf to create a secure temp file
# Usage: _mktemp_in_dir <dir> [prefix]
# Returns path on stdout or non-zero on failure.
_mktemp_in_dir() {
  local base="${1:-}" prefix="${2:-groq}" tmp
  if [ -z "$base" ]; then
    log_error "TMP" "_mktemp_in_dir: base dir required"
    return "$GROQBASHERRTMP"
  fi
  # Delegate to _tmpf which already enforces umask/perms and returns a path
  tmp="$(_tmpf file "$base" "$prefix" 2>/dev/null || true)"
  if [ -z "$tmp" ]; then
    log_error "TMP" "_mktemp_in_dir: failed to create temp in $base"
    return "$GROQBASHERRTMP"
  fi
  printf '%s' "$tmp"
  return 0
}

# Debug-safe payload preview (decodes b64 payloads)
show_payload_head() {
  local path="${1:-$PAYLOAD}" lines="${2:-200}"
  if [ -z "${path:-}" ]; then
    printf 'groqbash: ERROR: payload file missing: %s\n' "<unset>" >&2
    exit "$GROQBASHERRTMP"
  fi
  if [ ! -e "$path" ]; then
    printf 'groqbash: ERROR: payload file missing: %s\n' "$path" >&2
    exit "$GROQBASHERRTMP"
  fi
  if [ ! -s "$path" ]; then
    printf 'groqbash: INFO: payload exists but is empty: %s\n' "$path" >&2
    return 0
  fi

  # Diagnostic output only when DEBUG=1
  if [ "${DEBUG:-0}" -eq 1 ]; then
    printf 'groqbash: INFO: payload path: %s\n' "$path" >&2
    printf 'groqbash: INFO: payload (head %d lines):\n' "$lines" >&2
    if printf '%s' "$path" | grep -qE '\.b64$'; then
      b64decode < "$path" 2>/dev/null | head -n "$lines" >&2 || true
    else
      head -n "$lines" "$path" 2>/dev/null >&2 || true
    fi
  fi

  return 0
}

# Atomic raw write helper
# - atomic_write <dest> <timeout> -- (reads stdin)
atomic_write() {
  # Atomic write with optional lock support.
  # Usage: atomic_write /path/to/target [timeout_seconds]
  local dest="$1"
  local timeout="${2:-10}"
  [ -n "$dest" ] || return "$GROQBASHERRTMP"
  local destdir tmp lockfile rc

  destdir="$(dirname -- "$dest")"
  mkdir -p "$destdir" 2>/dev/null || { log_error "ATOMICFAIL" "cannot create dir $destdir"; return "$GROQBASHERRTMP"; }
  lockfile="${destdir}/.groqbash.lock"

  tmp="$(mktemp -p "$destdir" .groq-atomic.XXXXXX 2>/dev/null || true)"
  [ -n "$tmp" ] || tmp="$destdir/.groq-atomic.$$.$RANDOM"

  if ! cat - > "$tmp"; then
    rm -f -- "$tmp" 2>/dev/null || true
    log_error "ATOMICFAIL" "writing to temp failed"
    return "$GROQBASHERRTMP"
  fi
  chmod 600 "$tmp" 2>/dev/null || true

  # If lock_exec available, use it to perform the mv under lock; otherwise mv directly
  if type lock_exec >/dev/null 2>&1; then
    lock_exec "$lockfile" "$timeout" -- sh -c '
      set -e
      mv -f -- "$1" "$2"
      chmod 600 "$2" 2>/dev/null || true
    ' _ "$tmp" "$dest" || { rc=$?; rm -f -- "$tmp" 2>/dev/null || true; return "$rc"; }
  else
    if mv -f -- "$tmp" "$dest" 2>/dev/null; then
      chmod 600 "$dest" 2>/dev/null || true
    else
      rc=$?
      rm -f -- "$tmp" 2>/dev/null || true
      log_error "ATOMICFAIL" "mv failed with rc $rc"
      return "$rc"
    fi
  fi

  return 0
}

# Response extraction helpers
extract_text_from_resp() {
  # Extract textual content from RESP and print to stdout.
  # Return codes:
  # 0 = success (text printed)
  # 2 = RESP is diagnostic (no real content)
  # 1 = no textual content found or error
  local resp_file="${RESP:-}"
  if [ -z "${resp_file:-}" ]; then
    log_error "EXTRACT" "RESP path not set"
    return 1
  fi

  if ! is_valid_json_file "$resp_file"; then
    log_warn "EXTRACT" "RESP missing or not valid JSON: $resp_file"
    # If file exists but not JSON, output raw content as fallback
    if [ -f "$resp_file" ]; then
      cat "$resp_file" 2>/dev/null || true
      return 0
    fi
    return 1
  fi

  # If diagnostic JSON, bail with info
  if jq -e 'has("diagnostic") and .diagnostic==true' "$resp_file" >/dev/null 2>&1; then
    log_warn "EXTRACT" "RESP is diagnostic JSON; skipping text extraction"
    return 2
  fi

  # 1) choices[].message.content or choices[].delta.content
  if jq -e '.choices and (.choices|length>0) and ( [ .choices[]? | (.message?.content // .delta?.content // "") ] | map(select(.!="")) | length > 0 )' "$resp_file" >/dev/null 2>&1; then
    jq -r '[.choices[]? | (.message?.content // .delta?.content // "")] | map(select(.!="")) | join("\n\n")' "$resp_file" 2>/dev/null || return 1
    return 0
  fi

  # 2) choices[].text (older formats)
  if jq -e '.choices and (.choices|length>0) and ( [ .choices[]? | (.text? // "") ] | map(select(.!="")) | length > 0 )' "$resp_file" >/dev/null 2>&1; then
    jq -r '[.choices[]?.text? // empty] | map(select(.!="")) | join("\n\n")' "$resp_file" 2>/dev/null || return 1
    return 0
  fi

  # 3) output_text or data[].text
  if jq -e '(.output_text? // empty) != "" or (.data and (.data|length>0) and ( [ .data[]? | (.text? // "") ] | map(select(.!="")) | length > 0 ))' "$resp_file" >/dev/null 2>&1; then
    if [ "$(jq -r '.output_text // empty' "$resp_file" 2>/dev/null)" != "" ]; then
      jq -r '.output_text' "$resp_file" 2>/dev/null || return 1
      return 0
    else
      jq -r '[.data[]?.text? // empty] | map(select(.!="")) | join("\n\n")' "$resp_file" 2>/dev/null || return 1
      return 0
    fi
  fi

  # 4) fallback: any string scalars concatenated
  if jq -e 'paths(scalars) as $p | getpath($p) | type=="string"' "$resp_file" >/dev/null 2>&1; then
    jq -r '[.. | scalars | select(type=="string")] | join("\n\n")' "$resp_file" 2>/dev/null || return 1
    return 0
  fi

  log_warn "EXTRACT" "No textual content found in RESP"
  return 1
}

# Ensure and create a run-specific tmpdir under GROQBASH_TMPDIR and set neutral payload path.
# Robust fallback chain: reuse RUN_TMPDIR if valid -> mktemp -> make_tmpdir -> timestamped dir.
# Enforces strict perms and avoids /tmp usage. Removes empty groq.b64 staging files safely.
DEBUG_PRESERVE="${DEBUG_PRESERVE:-0}"

ensure_run_tmpdir() {
  # Usage:
  #   ensure_run_tmpdir            -> create/export RUN_TMPDIR PAYLOAD RESP ERRF in-process
  #   ensure_run_tmpdir --print    -> print RUN_TMPDIR to stdout (no trap, safe for subshell capture)
  local print_only=0 subshell=0 tmpdir
  if [ "${1:-}" = "--print" ]; then print_only=1; fi

  # Detect subshell: prefer comparing BASHPID to $$ (reliable in bash)
  # If BASHPID differs from $$ we are in a subshell; treat as subshell context.
  if [ -n "${BASHPID:-}" ] && [ "${BASHPID:-}" != "$$" ]; then
    subshell=1
  fi

  # If RUN_TMPDIR already set and valid, reuse it (do not clobber existing values)
  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "${RUN_TMPDIR:-}" ]; then
    chmod 700 "$RUN_TMPDIR" 2>/dev/null || true
    : "${PAYLOAD:=$RUN_TMPDIR/payload}"
    : "${RESP:=$RUN_TMPDIR/resp.json}"
    : "${ERRF:=$RUN_TMPDIR/err.log}"
    if [ "$print_only" -eq 0 ] && [ "$subshell" -eq 0 ]; then
      : > "$RESP" 2>/dev/null || true
      chmod 600 "$RESP" 2>/dev/null || true
      : > "$ERRF" 2>/dev/null || true
      chmod 600 "$ERRF" 2>/dev/null || true
      export RUN_TMPDIR PAYLOAD RESP ERRF
    fi
    if [ "$print_only" -eq 1 ]; then
      printf '%s' "$RUN_TMPDIR"
    fi
    return 0
  fi

  # Ensure base tmpdir exists and has strict perms
  if [ -z "${GROQBASH_TMPDIR:-}" ]; then
    log_error "TMP" "GROQBASH_TMPDIR not set"
    return "$GROQBASHERRTMP"
  fi
  mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || { log_error "TMP" "cannot create base tmpdir $GROQBASH_TMPDIR"; return 1; }
  chmod 700 "$GROQBASH_TMPDIR" 2>/dev/null || true

  # Try mktemp under GROQBASH_TMPDIR, fallback to make_tmpdir, then timestamped dir
  tmpdir="$(mktemp -d "${GROQBASH_TMPDIR%/}/run.XXXXXX" 2>/dev/null || true)"
  if [ -z "$tmpdir" ] || [ ! -d "$tmpdir" ]; then
    tmpdir="$(make_tmpdir 2>/dev/null || true)"
  fi
  if [ -z "$tmpdir" ] || [ ! -d "$tmpdir" ]; then
    tmpdir="${GROQBASH_TMPDIR%/}/run-$(date -u +%Y%m%dT%H%M%SZ)-$$"
    mkdir -p "$tmpdir" 2>/dev/null || { log_error "TMP" "cannot create fallback RUN_TMPDIR $tmpdir"; return 1; }
  fi

  # Enforce strict perms
  chmod 700 "$tmpdir" 2>/dev/null || true

  # Assign into RUN_TMPDIR local then export if requested
  RUN_TMPDIR="$tmpdir"

  # Provider-agnostic payload path (set only if unset)
  : "${PAYLOAD:=$RUN_TMPDIR/payload}"
  : "${RESP:=$RUN_TMPDIR/resp.json}"
  : "${ERRF:=$RUN_TMPDIR/err.log}"

  # Create RESP/ERRF files only in main process and when not print-only
  if [ "$print_only" -eq 0 ] && [ "$subshell" -eq 0 ]; then
    : > "$RESP" 2>/dev/null || true
    chmod 600 "$RESP" 2>/dev/null || true
    : > "$ERRF" 2>/dev/null || true
    chmod 600 "$ERRF" 2>/dev/null || true
  fi

  # Remove any empty groq.b64 staging files inside GROQBASH_TMPDIR to avoid confusing later logic
  if [ -n "${GROQBASH_TMPDIR:-}" ] && [ -d "${GROQBASH_TMPDIR:-}" ]; then
    for f in "${GROQBASH_TMPDIR%/}/"*.b64 "${RUN_TMPDIR%/}/"*.b64; do
      [ -e "$f" ] || continue
      if [ ! -s "$f" ]; then
        rm -f -- "$f" 2>/dev/null || true
        if [ "${DEBUG:-0}" -eq 1 ]; then
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
      case "$RUN_TMPDIR" in
        "$GROQBASH_TMPDIR"/*|"$GROQBASH_TMPDIR")
          rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
          if [ "${DEBUG:-0}" -eq 1 ]; then
            log_info "TMP" "Cleaned RUN_TMPDIR: $RUN_TMPDIR"
          fi
          ;;
        *)
          if [ "${DEBUG:-0}" -eq 1 ]; then
            log_info "TMP" "RUN_TMPDIR outside GROQBASH_TMPDIR; not removed: $RUN_TMPDIR"
          fi
          ;;
      esac
    fi
  }

  # Install trap only if we are in the main shell and not in print-only mode
  if [ "$subshell" -eq 0 ] && [ "$print_only" -eq 0 ]; then
    trap cleanup_run_tmp_on_exit EXIT INT TERM
  fi

  # Export variables in main process (if not print-only)
  if [ "$print_only" -eq 0 ]; then
    export RUN_TMPDIR PAYLOAD RESP ERRF
    if [ "${DEBUG:-0}" -eq 1 ]; then
      log_info "TMP" "Created RUN_TMPDIR: $RUN_TMPDIR"
    fi
  else
    printf '%s' "$RUN_TMPDIR"
  fi

  return 0
}

cleanup_tmp() {
  if [ -n "${RUN_TMPDIR:-}" ]; then
    case "$RUN_TMPDIR" in
      "$GROQBASH_TMPDIR"/*|"$GROQBASH_TMPDIR")
        rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true
        ;;
      *)
        ;;
    esac
  fi
}

# Atomic base64 write/read helpers (use for payloads, manifests, staging)
# - b64_atomic_write <dest.b64> <timeout> -- (reads stdin)
# - b64_atomic_read <src.b64> (writes decoded to stdout)
b64_atomic_write() {
  local dest="$1"
  local timeout="${2:-10}"
  shift 2 || true
  [ -n "$dest" ] || { log_error "B64FAIL" "b64_atomic_write: dest required"; return "$GROQBASHERRTMP"; }
  local destdir tmp lockfile
  destdir="$(dirname -- "$dest")"
  mkdir -p "$destdir" 2>/dev/null || { log_error "B64FAIL" "cannot create dir $destdir"; return "$GROQBASHERRTMP"; }
  # Use a lock specific to the destination directory to avoid global contention
  lockfile="${destdir%/}/.groqbash.lock"
  tmp="$(mktemp -p "$destdir" .groq-b64.XXXXXX 2>/dev/null || true)"
  [ -n "$tmp" ] || tmp="$destdir/.groq-b64.$$.$RANDOM"
  if ! b64encode > "$tmp"; then
    rm -f -- "$tmp" 2>/dev/null || true
    log_error "B64FAIL" "base64 encoding failed"
    return "$GROQBASHERRTMP"
  fi
  chmod 600 "$tmp" 2>/dev/null || true
  lock_exec "$lockfile" "$timeout" -- sh -c '
    set -e
    mv -f -- "$1" "$2"
    chmod 600 "$2" 2>/dev/null || true
  ' _ "$tmp" "$dest" || { rc=$?; rm -f -- "$tmp" 2>/dev/null || true; return "$rc"; }
  return 0
}

b64_atomic_read() {
  local src="$1"
  [ -f "$src" ] || return 1
  b64decode < "$src"
  return $?
}

# ui_state_write: helper centralizzato per scrivere file JSON per la GUI (atomic)
# Usage: ui_state_write <relpath> <json-string>
# Writes to: $GROQBASH_CONFIG_DIR/ui_state/<relpath>
# Guarantees: atomic write, strict perms, non-fatal on error (logs warning).
ui_state_write() {
  # Write UI state JSON atomically.
  # Usage: ui_state_write filename content_string
  local name="$1"; local content="$2"
  local dir target

  if [ -n "${GROQBASH_CONFIG_DIR:-}" ]; then
    dir="${GROQBASH_CONFIG_DIR%/}/ui_state"
  else
    dir="${RUN_TMPDIR%/}/ui_state"
  fi

  if [ -z "${name:-}" ]; then
    log_error "UI_STATE" "ui_state_write requires a filename"
    return 1
  fi

  mkdir -p "$dir" 2>/dev/null || { log_warn "UI_STATE" "failed to create ui_state dir: $dir"; return 1; }
  chmod 700 "$dir" 2>/dev/null || true
  target="$dir/$name"

  # Use atomic_write helper (timeout optional) to write content
  printf '%s' "$content" | atomic_write "$target" 10 || { log_warn "UI_STATE" "atomic write failed for $target"; return 1; }
  chmod 600 "$target" 2>/dev/null || true
  if [ "${DEBUG:-0}" -eq 1 ]; then
    log_info "UI_STATE" "wrote $target (size $(wc -c < "$target" 2>/dev/null)B)"
  fi
  return 0
}
#--5<---[ /SECTION: PRECORE_HELPERS ]--->5--
#--6<---[ SECTION: PRECORE_CLI_HELPERS ]--->6--
# Internal CLI helpers: print canonical config paths (safe, single-file)
# These flags are handled early and exit immediately after printing.
# Supported forms:
#   ./groqbash --print-config-dir
#   ./groqbash --print-provider-file
#   ./groqbash --print-model-file <provider>
#   ./groqbash --print-model-file=<provider>
# ---------------------------------------------------------------------------
if [ "$#" -gt 0 ]; then
  # Iterate through args to support flags anywhere on the command line
  i=1
  while [ $i -le $# ]; do
    eval "arg=\${$i}"
    case "$arg" in
      --print-config-dir)
        printf '%s\n' "$(canonical_config_dir)"
        exit 0
        ;;
      --print-provider-file)
        printf '%s\n' "$(canonical_provider_file)"
        exit 0
        ;;
      --print-model-file)
        # next positional must be provider name
        next_index=$((i+1))
        if [ $next_index -le $# ]; then
          eval "prov=\${$next_index}"
          printf '%s\n' "$(canonical_model_file "$prov")"
          exit 0
        else
          printf 'groqbash: ERROR: usage: --print-model-file <provider>\n' >&2
          exit 2
        fi
        ;;
      --print-model-file=*)
        prov="${arg#--print-model-file=}"
        printf '%s\n' "$(canonical_model_file "$prov")"
        exit 0
        ;;
      # allow short-circuit if user passed combined flags like --help etc.
      --help|-h)
        # fall through to normal help handling later
        break
        ;;
      *)
        # not one of our print flags; continue scanning
        ;;
    esac
    i=$((i+1))
  done
fi

# Ensure essential directories exist with strict perms
mkdir -p "$GROQBASH_HISTORY_DIR/sessions" 2>/dev/null || true
mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || true
chmod 700 "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" 2>/dev/null || true
# Ensure session dir exists and has strict perms
SESSION_DIR="${GROQBASH_HISTORY_DIR%/}/sessions"
mkdir -p "$SESSION_DIR" 2>/dev/null || true
chmod 700 "$SESSION_DIR" 2>/dev/null || true

umask 077
mkdir -p "$(canonical_config_dir)" "$GROQBASH_MODELS_DIR" "$GROQBASH_TEMPLATES_DIR" "$GROQBASH_HISTORY_DIR" "$GROQBASH_TMPDIR" "$GROQBASH_EXTRAS_DIR" "$(canonical_config_dir)/providers" 2>/dev/null || true

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
load_provider_module() {
  local provider="$1"

  # Skip if already loaded for the same provider
  if [ "${LOADED_PROVIDER_NAME:-}" = "$provider" ] && [ "${PROVIDER_MODULE_LOADED:-0}" -eq 1 ]; then
    return 0
  fi

  LOADED_PROVIDER_NAME="$provider"
  PROVIDER_MODULE_LOADED=0
  PROVIDER_MODULE_PATH="$PROVIDERS_DIR/${provider}.sh"
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

  if [ ! -f "$PROVIDER_MODULE_PATH" ]; then
    if [ "$provider" != "groq" ]; then
      printf 'Provider %s is not installed.\n' "$provider" >&2
      PROVIDER_MODULE_LOADED=0
      return 0
    else
      PROVIDER_MODULE_LOADED=1
      return 0
    fi
  fi

  if [ -L "$PROVIDER_MODULE_PATH" ]; then
    log_error "SEC" "provider file is symlink."
    return 1
  fi

  file_owner="$(_get_owner "$PROVIDER_MODULE_PATH")"
  [ -n "$file_owner" ] && [ "$file_owner" != "$current_user" ] && { log_error "SEC" "wrong owner for provider file."; return 1; }

  perms="$(_get_perm_string "$PROVIDER_MODULE_PATH")"
  group_write="$(printf '%s' "$perms" | awk '{print substr($0,6,1)}')"
  others_write="$(printf '%s' "$perms" | awk '{print substr($0,9,1)}')"
  if [ "$group_write" = "w" ] || [ "$others_write" = "w" ]; then
    log_error "SEC" "provider file writable by group/world."
    return 1
  fi

  beforesig="$(getfile_signature "$PROVIDER_MODULE_PATH" 2>/dev/null || true)"

  if bash -n "$PROVIDER_MODULE_PATH" 2>/dev/null; then
    . "$PROVIDER_MODULE_PATH"
    PROVIDER_MODULE_LOADED=1

    invalid_provider=0
    for _req in "buildpayload_${provider}" "call_api_${provider}"; do
      type "$_req" >/dev/null 2>&1 || invalid_provider=1
    done

    aftersig="$(getfile_signature "$PROVIDER_MODULE_PATH" 2>/dev/null || true)"
    [ "$beforesig" != "$aftersig" ] && { log_error "SEC" "provider file changed."; return 1; }

    if [ "$invalid_provider" -eq 1 ]; then
      log_warn "PROVIDER" "provider module incomplete; falling back to embedded provider."
      PROVIDER_MODULE_LOADED=0
    fi
  else
    log_warn "PROVIDER" "provider module invalid; falling back to embedded provider."
    PROVIDER_MODULE_LOADED=0
  fi

  # --- Write provider capabilities to ui_state (canonical) ---
  if [ -n "${provider:-}" ]; then
    supports_streaming=0
    supports_refresh_models=0
    if type "call_api_streaming_${provider}" >/dev/null 2>&1; then supports_streaming=1; fi
    if type "refresh_models_${provider}" >/dev/null 2>&1; then supports_refresh_models=1; fi
    loaded_from="${PROVIDER_MODULE_PATH:-embedded}"
    prov_json="$(jq -c -n --arg p "$provider" --arg loaded "$loaded_from" --argjson sstream "$supports_streaming" --argjson srefresh "$supports_refresh_models" '{provider:$p, supports_streaming:$sstream, supports_refresh_models:$srefresh, loaded_from:$loaded}')"
    ui_state_write "provider_capabilities.json" "$prov_json" || log_warn "UI_STATE" "failed to write provider_capabilities for $provider"
  fi

  return 0
}

# ---------------------------------------------------------------------------
# Detect portable base64 encode/decode commands (avoid parsing --help)
# Sets B64_ENCODE_CMD and B64_DECODE_CMD arrays used by wrappers
# ---------------------------------------------------------------------------
_detect_base64_opts() {
  # Default conservative options
  B64_WRAP_OPT=""
  B64_DECODE_OPT="-d"

  # Detect encode option that prevents line wrapping (GNU coreutils)
  if printf '' | base64 -w0 >/dev/null 2>&1; then
    B64_WRAP_OPT="-w0"
  else
    B64_WRAP_OPT=""
  fi

  # Detect decode option -d vs -D
  if printf 'dGVzdA==' | base64 -d 2>/dev/null | grep -q 'test'; then
    B64_DECODE_OPT="-d"
  elif printf 'dGVzdA==' | base64 -D 2>/dev/null | grep -q 'test'; then
    B64_DECODE_OPT="-D"
  else
    B64_DECODE_OPT="-d"
  fi

  export B64_WRAP_OPT B64_DECODE_OPT
}
_detect_base64_opts

# ---------------------------------------------------------------------------
# Portable file size and listing helpers for rotate_history
# - list_files_sorted_by_mtime lists files with mtime and path (portable)
# ---------------------------------------------------------------------------
# list_files_sorted_by_mtime <dir> -> prints "mtime_seconds|path" lines sorted ascending
list_files_sorted_by_mtime() {
  local dir="$1"
  find "$dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' f; do
    case "$(uname 2>/dev/null || echo Linux)" in
      Darwin) mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)" ;;
      *) mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)" ;;
    esac
    printf '%s|%s\n' "$mtime" "$f"
  done | sort -n
}

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

# ---------------------------------------------------------------------------
# _file_mtime: portable mtime in seconds for a file
# Usage: _file_mtime <file> -> prints epoch seconds or 0
# ---------------------------------------------------------------------------
_file_mtime() {
  local f="$1"
  if [ ! -e "$f" ]; then printf '0'; return 0; fi
  case "$(uname 2>/dev/null || echo Linux)" in
    Darwin) stat -f %m "$f" 2>/dev/null || printf '0' ;;
    *) stat -c %Y "$f" 2>/dev/null || printf '0' ;;
  esac
}

# ---------------------------------------------------------------------------
# jq_safe: run jq with error handling; returns 0 if JSON valid and jq succeeded
# Usage: jq_safe <filter> <file>
# ---------------------------------------------------------------------------
jq_safe() {
  # wrapper to run jq and capture errors to ERRF if set
  local filter="$1" file="$2" rc
  if [ -z "$file" ] || [ ! -s "$file" ]; then
    return 1
  fi
  if ! jq -e "$filter" "$file" >/dev/null 2>&1; then
    rc=$?
    # If ERRF is defined, append jq stderr for diagnostics
    if [ -n "${ERRF:-}" ]; then
      jq "$filter" "$file" 2>>"$ERRF" >/dev/null 2>&1 || true
    fi
    return "$rc"
  fi
  return 0
}
#--6<---[ /SECTION: PRECORE_CLI_HELPERS ]--->6--

#--7<---[ SECTION: PRECORE_HISTORY ]--->7--
# History rotation and compaction (portable)
# ---------------------------------------------------------------------------
GROQBASH_ROTATE_HISTORY="${GROQBASH_ROTATE_HISTORY:-0}"
GROQBASH_HISTORY_MAX_FILES="${GROQBASH_HISTORY_MAX_FILES:-100}"
GROQBASH_HISTORY_MAX_BYTES="${GROQBASH_HISTORY_MAX_BYTES:-104857600}" # 100MB
GROQBASH_HISTORY_KEEP_DAYS="${GROQBASH_HISTORY_KEEP_DAYS:-90}"

# ---------------------------------------------------------------------------
# rotate_history: all rotation logic executed atomically under HISTORY_LOCK
# - Ensures file counting, size summing and deletions happen under the same lock.
# - Uses portable stat helper _file_mtime/_file_size where needed.
# ---------------------------------------------------------------------------
rotate_history() {
  local timeout="${1:-$GROQBASH_LOCK_TIMEOUT_HISTORY}"
  local dir="${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}"
  local max_files="${GROQBASH_HISTORY_MAX_FILES:-100}"
  local max_bytes="${GROQBASH_HISTORY_MAX_BYTES:-104857600}"
  local keep_days="${GROQBASH_HISTORY_KEEP_DAYS:-90}"

  lock_exec "${HISTORY_LOCK}" "$timeout" -- sh -c '
    set -e
    dir="$1"
    max_files="$2"
    max_bytes="$3"
    keep_days="$4"

    # Remove files older than keep_days first
    find "$dir" -type f -mtime +"$keep_days" -print0 | xargs -0 -r rm -f --

    # Compute total bytes and remove oldest until under threshold
    while :; do
      total=0
      # Build list of files with mtime and size
      files_list="$(mktemp -p "$(dirname "$dir")" groq-rot.XXXX 2>/dev/null || true)"
      if [ -z "$files_list" ]; then
        files_list="/tmp/groq-rot.$$"
      fi
      : > "$files_list"
      find "$dir" -type f -print0 2>/dev/null | while IFS= read -r -d "" f; do
        if [ -f "$f" ]; then
          # portable size
          case "$(uname 2>/dev/null || echo Linux)" in
            Darwin) size="$(stat -f %z "$f" 2>/dev/null || echo 0)" ;;
            *) size="$(stat -c %s "$f" 2>/dev/null || echo 0)" ;;
          esac
          mtime=0
          case "$(uname 2>/dev/null || echo Linux)" in
            Darwin) mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)" ;;
            *) mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)" ;;
          esac
          printf "%s|%s|%s\n" "$mtime" "$size" "$f" >> "$files_list"
        fi
      done

      # Sum sizes
      if [ -s "$files_list" ]; then
        while IFS='|' read -r mtime size path; do
          total=$((total + (size + 0)))
        done < "$files_list"
      fi

      # If under limit, break
      if [ "$total" -le "$max_bytes" ]; then
        rm -f "$files_list" 2>/dev/null || true
        break
      fi

      # Remove oldest file
      oldest="$(sort -n "$files_list" | head -n1 | awk -F"|" '\''{print $3}'\'')"
      if [ -z "$oldest" ]; then
        rm -f "$files_list" 2>/dev/null || true
        break
      fi
      rm -f -- "$oldest" 2>/dev/null || true
      rm -f "$files_list" 2>/dev/null || true
    done

    # Enforce max files count
    while :; do
      count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d " ")
      if [ "$count" -le "$max_files" ]; then break; fi
      # find oldest and remove
      oldest="$(find "$dir" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | head -n1 | awk '\''{print $2}'\'')"
      [ -z "$oldest" ] && break
      rm -f -- "$oldest" 2>/dev/null || true
    done
  ' _ "$dir" "$max_files" "$max_bytes" "$keep_days"
  return $?
}

save_to_history() {
  local content="$1"
  local filename
  filename="$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt"
  mkdir -p "$GROQBASH_HISTORY_DIR" 2>/dev/null || true
  local tmpf dest lockfile
  # Create tmp file in history dir to ensure same-filesystem atomic mv
  tmpf="$(mktemp -p "$GROQBASH_HISTORY_DIR" groq-out.XXXX 2>/dev/null || true)"
  [ -n "$tmpf" ] || tmpf="$GROQBASH_HISTORY_DIR/.groq-out.$$.$RANDOM"
  if ! : > "$tmpf" 2>/dev/null; then
    log_error "HISTORYFAIL" "save_to_history: cannot create tmp file in $GROQBASH_HISTORY_DIR"
    return "$GROQBASHERRTMP"
  fi
  printf '%s\n' "$content" > "$tmpf"
  dest="$GROQBASH_HISTORY_DIR/$filename"
  lockfile="$HISTORY_LOCK"
  lock_exec "$lockfile" "$GROQBASH_LOCK_TIMEOUT_HISTORY" -- sh -c '
    set -e
    mv -f -- "$1" "$2"
    chmod 600 "$2" 2>/dev/null || true
    
    # --- Write last_history metadata to ui_state ---
    if [ -f "$dest" ]; then
      size_bytes="$(file_size "$dest" 2>/dev/null || echo 0)"
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      basename="$(basename "$dest")"
      history_json="$(jq -c -n --arg path "$dest" --arg base "$basename" --arg ts "$ts" --argjson size "$size_bytes" '{saved:true, path:$path, basename:$base, ts:$ts, size_bytes:$size}')"
      ui_state_write "last_history.json" "$history_json" || log_warn "UI_STATE" "failed to write last_history.json"
    else
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      history_json="$(jq -c -n --arg ts "$ts" '{saved:false, ts:$ts}')"
      ui_state_write "last_history.json" "$history_json" || true
    fi

  ' _ "$tmpf" "$dest" || { rc=$?; rm -f -- "$tmpf" 2>/dev/null || true; return "$rc"; }
  if [ "${GROQBASH_ROTATE_HISTORY:-0}" -eq 1 ]; then
    rotate_history "$GROQBASH_LOCK_TIMEOUT_HISTORY" || true
  fi
  if [ "${DEBUG:-0}" -eq 1 ]; then
    log_info "HISTORY_SAVE" "$dest"
  fi
  return 0
}
#--7<---[ /SECTION: PRECORE_HISTORY ]--->7--
#--8<---[ SECTION: PRECORE_MANIFEST ]--->8--
# ---------------------------------------------------------------------------
# Manifest multimodale helpers (atomic, jq --arg usage)
# - manifest_create <manifest_path> [timeout]
# - manifest_add_part <manifest_path> <name> <file_path> <mime> [timeout]
# - manifest_read <manifest_path>
# Manifest stored as both JSON file and base64 staging file manifest.b64
# ---------------------------------------------------------------------------
manifest_create() {
  local manifest="$1"
  local timeout="${2:-$GROQBASH_LOCK_TIMEOUT_MODELS}"
  mkdir -p "$(dirname "$manifest")" 2>/dev/null || { log_error "MANIFESTFAIL" "manifest_create: cannot create dir"; return 1; }
  lock_exec "${manifest}.lock" "$timeout" -- sh -c '
   set -e
   manifest="$1"
   tmp="$(mktemp -p "$(dirname "$manifest")" manifest.tmp.XXXX)"
   printf "%s" "{\"parts\":[]}" > "$tmp"
   # write base64 staging using base64 binary and exported opts
   if [ -n "${B64_WRAP_OPT:-}" ]; then
     base64 ${B64_WRAP_OPT} "$tmp" > "${manifest}.b64"
   else
     base64 "$tmp" | tr -d "\n" > "${manifest}.b64"
   fi
   mv -f "$tmp" "$manifest"
   chmod 600 "$manifest" 2>/dev/null || true
 ' _ "$manifest"

  return $?
}

manifest_add_part() {
  local manifest="$1" name="$2" file_path="$3" mime="$4" timeout="${5:-$GROQBASH_LOCK_TIMEOUT_MODELS}"
  [ -f "$file_path" ] || { log_error "MANIFESTFAIL" "manifest_add_part: file not found: $file_path"; return 1; }
  mkdir -p "$(dirname "$manifest")" 2>/dev/null || true

  # Ensure a lockfile specific to this manifest (avoid global contention)
  lockfile="${manifest}.lock"

  # First, stage the part as a base64 file in the manifest directory (atomic in destdir)
  local destdir part_b64 tmpstamp tmp_part
  destdir="$(dirname "$manifest")"
  tmpstamp="$(date +%s)-$$"
  part_b64="$destdir/parts-$(basename "$file_path").${tmpstamp}.b64"
  tmp_part="$GROQBASH_TMPDIR/part.tmp.$$"

  # write base64 staging atomically into RUN tmp then move into destdir
  if ! b64encode < "$file_path" > "$tmp_part"; then
    rm -f "$tmp_part" 2>/dev/null || true
    log_error "B64FAIL" "manifest_add_part: b64 encode failed"
    return 1
  fi
  mv -f "$tmp_part" "$part_b64" 2>/dev/null || { rm -f "$tmp_part" 2>/dev/null || true; log_error "MANIFESTFAIL" "cannot move staged part to $part_b64"; return 1; }
  chmod 600 "$part_b64" 2>/dev/null || true

  # Now update manifest atomically under lock using jq --arg
  lock_exec "$lockfile" "$timeout" -- sh -c '
    set -e
    manifest="$1"
    part_b64="$2"
    name="$3"
    mime="$4"
    tmp="$(mktemp -p "$(dirname "$manifest")" manifest.edit.XXXX)"
    if [ -f "${manifest}.b64" ]; then
      # decode base64 staging to tmp using exported decode opt
      base64 ${B64_DECODE_OPT} < "${manifest}.b64" > "$tmp" 2>/dev/null || printf "%s" "{\"parts\":[]}" > "$tmp"
    elif [ -f "$manifest" ]; then
      cp -f "$manifest" "$tmp"
    else
      printf "%s" "{\"parts\":[]}" > "$tmp"
    fi
    jq --arg name "$name" --arg path "$part_b64" --arg enc "b64" --arg type "$mime" \
       ".parts += [{name:\$name, path:\$path, encoding:\$enc, type:\$type}]" "$tmp" > "${tmp}.new"
    mv -f "${tmp}.new" "$tmp"
    # write back both manifest and base64 staging atomically
    if [ -n "${B64_WRAP_OPT:-}" ]; then
      base64 ${B64_WRAP_OPT} "$tmp" > "${manifest}.b64"
    else
      base64 "$tmp" | tr -d "\n" > "${manifest}.b64"
    fi
    cp -f "$tmp" "$manifest"
    chmod 600 "$manifest" 2>/dev/null || true
    rm -f "$tmp" 2>/dev/null || true
  ' _ "$manifest" "$part_b64" "$name" "$mime" || { log_error "MANIFESTFAIL" "manifest_add_part: update failed"; return 1; }

  if [ "${DEBUG:-0}" -eq 1 ]; then
    log_info "MANIFEST_ADD" "added part $name -> $part_b64"
  fi
  return 0
}

manifest_read() {
  local manifest="$1"
  if [ -f "$manifest" ]; then
    cat "$manifest"
    return 0
  fi
  if [ -f "${manifest}.b64" ]; then
    b64decode < "${manifest}.b64"
    return $?
  fi
  return 1
}
#--8<---[ /SECTION: PRECORE_MANIFEST ]--->8--

#--9<---[ SECTION: PRECORE_UTIL_HELPERS ]--->9--
# Utility helpers
_get_perm_string() {
  local path="$1" perm=""
  case "$(uname 2>/dev/null || echo Linux)" in
    Darwin) perm="$(stat -f %Sp "$path" 2>/dev/null || true)" ;;
    *) if command -v stat >/dev/null 2>&1; then perm="$(stat -c %A "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then perm="$(find "$path" -maxdepth 0 -printf '%M' 2>/dev/null || true)"; fi ;;
  esac
  printf '%s' "$perm"
}

_get_owner() {
  local path="$1" owner=""
  case "$(uname 2>/dev/null || echo Linux)" in
    Darwin) owner="$(stat -f %Su "$path" 2>/dev/null || true)" ;;
    *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;
  esac
  printf '%s' "$owner"
}

_get_file_signature() {
  local path="$1"
  local hash="" stat_out="" dev="" inode="" size="" ctime="" mtime="" uid="" gid="" mode=""
  # Return empty string if not a regular file
  [ -f "$path" ] || { printf ''; return 0; }

  # Decide whether to compute content hash (default 1)
  local use_hash="${GROQBASH_SIG_HASH:-1}"

  # Compute SHA256 if requested and available
  if [ "${use_hash}" != "0" ] && command -v sha256sum >/dev/null 2>&1; then
    hash="$(sha256sum "$path" 2>/dev/null | awk '{print $1}' || true)"
  else
    hash=""
  fi

  # Collect stat output in a portable way
  case "$(uname 2>/dev/null || echo Linux)" in
    Darwin)
      # BSD/macOS stat format: device inode size ctime mtime uid gid mode
      stat_out="$(stat -f '%d %i %z %c %m %u %g %p' "$path" 2>/dev/null || true)"
      ;;
    *)
      # GNU stat format: device inode size ctime mtime uid gid mode
      stat_out="$(stat -c '%d %i %s %Z %Y %u %g %a' "$path" 2>/dev/null || true)"
      ;;
  esac

  # If stat failed, ensure variables are empty and continue (do not abort)
  if [ -z "${stat_out:-}" ]; then
    dev=""; inode=""; size=""; ctime=""; mtime=""; uid=""; gid=""; mode=""
  else
    # Parse stat_out using a here-doc to avoid process substitution portability issues
    read -r dev inode size ctime mtime uid gid mode <<EOF
$stat_out
EOF
    # If read failed for any reason, reset to empty strings
    if [ -z "${dev:-}" ] && [ -z "${inode:-}" ] && [ -z "${size:-}" ]; then
      dev=""; inode=""; size=""; ctime=""; mtime=""; uid=""; gid=""; mode=""
    fi
  fi

  # Output a stable, linear signature: hash|dev|inode|size|ctime|mtime|uid|gid|mode
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s' \
    "${hash:-}" "${dev:-}" "${inode:-}" "${size:-}" "${ctime:-}" "${mtime:-}" "${uid:-}" "${gid:-}" "${mode:-}"
}

getfile_signature() { _get_file_signature "$1"; }

_is_world_writable() {
  local d="$1" perms others_write
  [ -d "$d" ] || return "$GROQBASHERRTMP"
  perms="$(_get_perm_string "$d")"
  [ -z "$perms" ] && return "$GROQBASHERRTMP"
  others_write="$(printf '%s' "$perms" | awk '{print substr($0,9,1)}')"
  [ "$others_write" = "w" ]
}

# Tmpdir creation under TMP_LOCK to avoid races
make_tmpdir() {
  umask 077
  local tmpd lockfile
  lockfile="$TMP_LOCK"
  mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || return "$GROQBASHERRTMP"
  lock_exec "$lockfile" "$GROQBASH_LOCK_TIMEOUT_TMP" -- sh -c '
    set -e
    base="$1"
    tmpd="$(mktemp -d -p "$base" groq.XXXX 2>/dev/null || true)"
    if [ -z "$tmpd" ]; then
      tmpd="$base/groq.$$.$RANDOM"
      mkdir -p "$tmpd"
    fi
    chmod 700 "$tmpd" 2>/dev/null || true
    printf "%s" "$tmpd"
  ' _ "$GROQBASH_TMPDIR"
  return $?
}

# _tmpf: create a temporary file or directory inside a given base dir
# Usage:
#   _tmpf file <base_dir> <prefix>
#   _tmpf dir  <base_dir> <prefix>
# Returns path on stdout or non-zero on failure.
# Guarantees: uses GROQBASH_TMPDIR as fallback, enforces umask/permissions.
_tmpf() {
  local mode="$1" base="$2" prefix="${3:-groq}" tmp
  if [ -z "$mode" ] || [ -z "$base" ]; then
    log_error "TMP" "_tmpf usage: _tmpf <file|dir> <base_dir> [prefix]"
    return "$GROQBASHERRTMP"
  fi

  # Prefer provided base, else GROQBASH_TMPDIR
  if [ -z "$base" ] || [ ! -d "$base" ]; then
    base="${GROQBASH_TMPDIR:-}"
  fi
  if [ -z "$base" ] || [ ! -d "$base" ]; then
    log_error "TMP" "tmp base directory not available: $base"
    return "$GROQBASHERRTMP"
  fi

  # Ensure base is inside GROQBASH_TMPDIR for safety
  case "$base" in
    "$GROQBASH_TMPDIR"/*|"$GROQBASH_TMPDIR") ;;
    *)
      # If base is not under GROQBASH_TMPDIR, prefer GROQBASH_TMPDIR
      base="${GROQBASH_TMPDIR:-$base}"
      ;;
  esac

  umask 077
  if [ "$mode" = "file" ]; then
    tmp="$(mktemp -p "$base" "${prefix}.XXXX" 2>/dev/null || true)"
    if [ -z "$tmp" ]; then
      tmp="${base%/}/${prefix}.$$.$RANDOM"
      : > "$tmp" 2>/dev/null || true
    fi
    chmod 600 "$tmp" 2>/dev/null || true
    printf '%s' "$tmp"
    return 0
  elif [ "$mode" = "dir" ]; then
    tmp="$(mktemp -d -p "$base" "${prefix}.XXXX" 2>/dev/null || true)"
    if [ -z "$tmp" ]; then
      tmp="${base%/}/${prefix}.$$.$RANDOM"
      mkdir -p "$tmp" 2>/dev/null || true
    fi
    chmod 700 "$tmp" 2>/dev/null || true
    printf '%s' "$tmp"
    return 0
  else
    log_error "TMP" "_tmpf: unknown mode: $mode"
    return "$GROQBASHERRTMP"
  fi
}
#--9<---[ /SECTION: PRECORE_UTIL_HELPERS ]--->9--

#--10<---[ SECTION: PRECORE_SESSION_MVP ]--->10--
# Session helpers (MVP - Minimum Viable Product)
# - session_validate_id <id> -> 0 if valid, 1 if invalid
# - session_now_ts -> prints UTC timestamp YYYY-MM-DDTHH:MM:SSZ
# - session_messages_tmp_path <session_id> -> prints path under RUN_TMPDIR
# - session_read_window <session_id> <N> <out_file> -> reads last N NDJSON lines, normalizes roles, writes {"messages":[...]}
# - session_append <session_id> <role> <content> <meta_json> -> idempotent append under lock
# - session_sanitize_cmd <cmd> -> prints sanitized cmd (truncate, remove env-like KEY=VAL, redact tokens)
# - session_marker_create <message_id> -> create marker file in RUN_TMPDIR to avoid double append in same process
# ---------------------------------------------------------------------------

session_validate_id() {
  local id="$1"
  if [ -z "$id" ]; then return 1; fi
  if printf '%s' "$id" | grep -qE '^[A-Za-z0-9._-]{1,128}$'; then return 0; else return 1; fi
}

session_now_ts() {
  # UTC timestamp, seconds resolution, format YYYY-MM-DDTHH:MM:SSZ
  date -u +%Y-%m-%dT%H:%M:%SZ
}

session_messages_tmp_path() {
  local sid="$1"
  ensure_run_tmpdir || return 1
  printf '%s' "$RUN_TMPDIR/session-${sid}-messages.json"
}

session_sanitize_cmd() {
  local cmd="$1"
  # Remove env-like KEY=VAL, redact tokens/keys, truncate to 256 chars
  local sanitized
  sanitized="$(printf '%s' "$cmd" | sed -E 's/[A-Za-z0-9_]+=([^[:space:]]+)//g' | sed -E 's/(token|key|secret)[^[:space:]]*/[REDACTED]/Ig' )"
  printf '%s' "$(printf '%s' "$sanitized" | cut -c1-256)"
}

session_read_window() {
  # Usage: session_read_window <session_id> <N> <out_file>
  local sid="$1" n="${2:-10}" out="$3"
  local history_dir="${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}"
  local session_file="$history_dir/sessions/${sid}.ndjson"
  local tmpdir="${RUN_TMPDIR:-${GROQBASH_TMPDIR:-$PWD/groqbash.d/tmp}}"
  local tmpf out_tmp line role content role_norm role_json content_json

  [ -n "$sid" ] || return 1
  [ -n "$out" ] || return 1

  mkdir -p "${history_dir%/}/sessions" 2>/dev/null || true
  chmod 700 "${history_dir%/}/sessions" 2>/dev/null || true

  if ! printf '%s' "$n" | grep -qE '^[0-9]+$'; then n=10; fi
  if [ "$n" -le 0 ]; then n=10; fi

  # Ensure tmpdir exists and is writable (must be inside groqbash.d/)
  mkdir -p "${tmpdir%/}" 2>/dev/null || true
  chmod 700 "${tmpdir%/}" 2>/dev/null || true
  if ! : > "${tmpdir%/}/.groqbash_tmp_check" 2>/dev/null; then
    if [ "${DEBUG:-0}" -eq 1 ]; then
      printf 'DEBUG: session_read_window: tmpdir not writable: %s\n' "$tmpdir" >&2
    fi
    return 1
  else
    rm -f "${tmpdir%/}/.groqbash_tmp_check" 2>/dev/null || true
  fi

  # Create a tmpf inside tmpdir (no /tmp, no /dev/null)
  tmpf="${tmpdir%/}/session.read.$$.$RANDOM"
  : > "$tmpf" 2>/dev/null || { if [ "${DEBUG:-0}" -eq 1 ]; then printf 'DEBUG: session_read_window: cannot create tmpf %s\n' "$tmpf" >&2; fi; return 1; }

  # Extract last N records robustly (records separated by blank line)
  if [ -f "$session_file" ]; then
    # Acquire a short lock on the session file to avoid partial reads during concurrent append
    lock_exec "${session_file}.lock" 5 -- sh -c '
      set -e
      session_file="$1"
      n="$2"
      tmpf="$3"
      if grep -q "^$" "$session_file" 2>/dev/null; then
        awk -v n="$n" "BEGIN{RS=\"\"; ORS=RS} {rec[++c]=\$0} END{start=c-n+1; if(start<1) start=1; for(i=start;i<=c;i++) print rec[i]}" "$session_file" > "$tmpf" 2>/dev/null || cp -f "$session_file" "$tmpf" 2>/dev/null || true
      else
        if ! tail -n "$n" "$session_file" 2>/dev/null > "$tmpf"; then
          cp -f "$session_file" "$tmpf" 2>/dev/null || true
        fi
      fi
    ' _ "$session_file" "$n" "$tmpf"
  else
    if [ "${DEBUG:-0}" -eq 1 ]; then
      printf 'DEBUG: session_read_window: session file not found: %s\n' "$session_file" >&2
    fi
  fi

  # Prepare atomic output in same dir as out
  out_tmp="${out}.tmp.$$"
  mkdir -p "$(dirname "$out")" 2>/dev/null || true
  : > "$out_tmp"
  chmod 600 "$out_tmp" 2>/dev/null || true

  printf '%s' '{"messages":[' >> "$out_tmp"
    local first=1
  # Use jq -c to compact each JSON record (handles pretty-printed and single-line NDJSON)
  if jq -c . "$tmpf" >/dev/null 2>&1; then
    jq -c . "$tmpf" 2>/dev/null | while IFS= read -r line || [ -n "$line" ]; do
      role="$(printf '%s' "$line" | jq -r '.role // "user"')"
      case "$role" in user|assistant|system) role_norm="$role" ;; *) role_norm="user" ;; esac
      content="$(printf '%s' "$line" | jq -r '.content // ""')"
      role_json="$(printf '%s' "$role_norm" | jq -R -c '.')"
      content_json="$(printf '%s' "$content" | jq -R -s '.')"
      if [ "$first" -eq 0 ]; then printf ',' >> "$out_tmp"; fi
      printf '%s' "{\"role\":${role_json},\"content\":${content_json}}" >> "$out_tmp" 2>/dev/null || true
      first=0
    done
  else
    # fallback: try to treat tmpf as line-based NDJSON
    while IFS= read -r line || [ -n "$line" ]; do
      if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
        role="$(printf '%s' "$line" | jq -r '.role // "user"')"
        case "$role" in user|assistant|system) role_norm="$role" ;; *) role_norm="user" ;; esac
        content="$(printf '%s' "$line" | jq -r '.content // ""')"
        role_json="$(printf '%s' "$role_norm" | jq -R -c '.')"
        content_json="$(printf '%s' "$content" | jq -R -s '.')"
        if [ "$first" -eq 0 ]; then printf ',' >> "$out_tmp"; fi
        printf '%s' "{\"role\":${role_json},\"content\":${content_json}}" >> "$out_tmp" 2>/dev/null || true
        first=0
      fi
    done < "$tmpf"
  fi
  printf '%s' ']}' >> "$out_tmp"

  # Atomic replace
  if mv -f "$out_tmp" "$out" 2>/dev/null; then
    :
  else
    cp -f "$out_tmp" "$out" 2>/dev/null || true
    rm -f "$out_tmp" 2>/dev/null || true
  fi

  rm -f "$tmpf" 2>/dev/null || true
  chmod 600 "$out" 2>/dev/null || true

  # --- Update ui_state session metadata after read_window (best-effort) ---
  if [ -n "$sid" ]; then
    if ensure_run_tmpdir >/dev/null 2>&1; then
      msg_count=0
      last_ts=""
      if [ -f "$session_file" ]; then
        msg_count="$(wc -l < "$session_file" 2>/dev/null || echo 0)"
        last_line="$(tail -n 1 "$session_file" 2>/dev/null || true)"
        if printf '%s' "$last_line" | jq -e . >/dev/null 2>&1; then
          last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
        fi
      fi
      meta_json="$(jq -c -n --arg id "$sid" --argjson msg_count "$msg_count" --arg last_ts "${last_ts:-}" '{id:$id, active:(( $msg_count | tonumber) > 0), msg_count:$msg_count, last_ts:$last_ts}')"
      ui_state_write "sessions/${sid}.json" "$meta_json" || log_warn "UI_STATE" "failed to update session meta for $sid (read_window)"
    fi
  fi

  if [ "${DEBUG:-0}" -eq 1 ]; then
    printf 'DEBUG: session_read_window done: out=%s size=%s tmpf=%s\n' "$out" "$( [ -f "$out" ] && wc -c < "$out" || echo 0 )" "$tmpf" >&2
  fi

  return 0
}

session_append() {
  # Usage: session_append <session_id> <role> <content> <meta_json>
  local sid="$1" role="$2" content="$3" meta_json="$4"
  # Prefer SESSION_DIR (set during init), then GROQBASH_HISTORY_DIR, then local fallback
  local base_sessions_dir="${SESSION_DIR:-${GROQBASH_HISTORY_DIR:-./groqbash.d}/sessions}"
  local session_file="${base_sessions_dir%/}/${sid}.ndjson"
  local lockfile="${session_file}.lock"
  local invocation_ts message_id marker normalized rand tmpf found=0 role_norm line timeout
  local marker_dir created_marker=0 sess_dir tmp_init

  [ -n "$sid" ] || return 1
  [ -n "$content" ] || content=""

  # Ensure we clean up marker_dir on unexpected exit; normal successful path will disable the trap.
  trap 'if [ "${created_marker:-0}" -eq 1 ] && [ -n "${marker_dir:-}" ]; then rm -rf -- "$marker_dir" 2>/dev/null || true; fi' RETURN

  invocation_ts="$(session_now_ts)"
  message_id="$(printf '%s' "$meta_json" | jq -r '.id // empty' 2>/dev/null || true)"
  if [ -z "$message_id" ]; then
    normalized="$(printf '%s' "$content" | sed -e 's/\r$//' -e 's/\r\n/\n/g' | awk '{$1=$1; print}')"
    rand="$(printf '%04x' $((RANDOM & 0xFFFF)))"
    if command -v sha256sum >/dev/null 2>&1; then
      message_id="$(printf '%s|%s|%s' "$normalized" "$invocation_ts" "$rand" | sha256sum | cut -c1-16)"
    elif command -v openssl >/dev/null 2>&1; then
      message_id="$(printf '%s|%s|%s' "$normalized" "$invocation_ts" "$rand" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)"
    else
      message_id="$rand"
    fi
  fi

  # Ensure session directory and file exist before creating marker/lock (race-safe init)
  sess_dir="$(dirname "$session_file")"
  if ! mkdir -p "$sess_dir" 2>/dev/null; then
    log_error "SESSION" "cannot create session directory: $sess_dir"
    return 1
  fi
  chmod 700 "$sess_dir" 2>/dev/null || true

  if [ ! -f "$session_file" ]; then
    tmp_init="${RUN_TMPDIR:-$GROQBASH_TMPDIR}/session.init.$$"
    : > "$tmp_init" 2>/dev/null || true
    if ! mv -f "$tmp_init" "$session_file" 2>/dev/null; then
      cp -f "$tmp_init" "$session_file" 2>/dev/null || true
    fi
    chmod 600 "$session_file" 2>/dev/null || true
  fi

  # Marker: prefer message_id-based idempotency (cross-process). Fallback: run-unique marker to avoid duplicate append from same process.
  if [ -n "${message_id:-}" ]; then
    marker_dir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}/session-msg-${message_id}.lockdir"
    if mkdir "$marker_dir" 2>/dev/null; then
      printf '%s\n' "$$" > "${marker_dir}/owner.pid" 2>/dev/null || true
      printf '%s\n' "$(date +%s)" > "${marker_dir}/owner.ts" 2>/dev/null || true
      chmod 700 "$marker_dir" 2>/dev/null || true
      created_marker=1
    else
      if [ "${DEBUG:-0}" -eq 1 ]; then
        log_info "SESSION" "append skipped: marker exists for message_id $message_id"
      fi
      return 0
    fi
  else
    marker_dir="${RUN_TMPDIR:-$GROQBASH_TMPDIR}/run-$$-${RANDOM}.lockdir"
    mkdir -p "$marker_dir" 2>/dev/null || true
    printf '%s\n' "$$" > "${marker_dir}/owner.pid" 2>/dev/null || true
    printf '%s\n' "$(date +%s)" > "${marker_dir}/owner.ts" 2>/dev/null || true
    chmod 700 "$marker_dir" 2>/dev/null || true
    created_marker=1
  fi

  # Prepare tmp file for any transient checks (kept minimal)
  tmpf="$(mktemp -p "${RUN_TMPDIR:-$GROQBASH_TMPDIR}" session.append.XXXX 2>/dev/null || true)"
  : > "${tmpf:-/dev/null}" 2>/dev/null || true

  timeout="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}"

  # Acquire exclusive lock on session file
  exec 200>"$lockfile" 2>/dev/null || true
  if ! flock -x -w "$timeout" 200 2>/dev/null; then
    # Could not acquire lock: cleanup marker if we created it
    if [ "${created_marker:-0}" -eq 1 ]; then rm -rf -- "$marker_dir" 2>/dev/null || true; fi
    exec 200>&- 2>/dev/null || true
    rm -f "$tmpf" 2>/dev/null || true
    log_error "SESSION" "could not acquire session lock for append"
    return 1
  fi

  # If message_id present, do a quick existence check under lock by searching for the id token.
  if [ -n "${message_id:-}" ] && [ -f "$session_file" ]; then
    # Only search for the id field; this is cheap and avoids content-based heuristics
    if grep -F "\"id\":\"$message_id\"" "$session_file" >/dev/null 2>/dev/null; then
      # duplicate detected: release lock and keep marker (treat as done)
      flock -u 200 2>/dev/null || true
      exec 200>&- 2>/dev/null || true
      rm -f "$tmpf" 2>/dev/null || true
      if [ "${DEBUG:-0}" -eq 1 ]; then
        log_info "SESSION" "append skipped: duplicate detected for message_id $message_id"
      fi
      return 0
    fi
  fi

  # Normalize role and meta, build line
  meta_json="$(printf '%s' "$meta_json" | jq -c '.' 2>/dev/null || printf '%s' '{}' )"
  case "$role" in user|assistant|system) role_norm="$role" ;; *) role_norm="user" ;; esac

  # Global guard: skip appending empty user messages
  if [ "$role_norm" = "user" ] && [ -z "${content:-}" ]; then
    if [ "${DEBUG:-0}" -eq 1 ]; then
      log_info "SESSION" "skipping append of empty user message for session $sid"
    fi
    # disable cleanup trap so marker is preserved if needed
    trap - RETURN
    return 0
  fi

  # Build a compact single-line NDJSON record for the session
  # Use jq -c -n to produce compact JSON (one line)
  # Ensure meta_json is valid JSON (it was normalized earlier in the function)
  line="$(jq -c -n \
    --arg ts "$invocation_ts" \
    --arg role "$role_norm" \
    --arg content "$content" \
    --argjson meta "$meta_json" \
    '{ts:$ts, role:$role, content:$content, meta:$meta}')"

  # Perform append (we already hold the lock)
  if ! printf "%s\n" "$line" >> "$session_file" 2>/dev/null; then
    # If append failed, try to reinitialize file safely
    : > "$session_file" 2>/dev/null || true
    if ! printf "%s\n" "$line" >> "$session_file" 2>/dev/null; then
      # Append definitively failed: cleanup marker if we created it
      if [ "${created_marker:-0}" -eq 1 ]; then
        rm -rf -- "$marker_dir" 2>/dev/null || true
      fi
      flock -u 200 2>/dev/null || true
      exec 200>&- 2>/dev/null || true
      rm -f "$tmpf" 2>/dev/null || true
      log_error "SESSION" "failed to append message to $session_file"
      return 1
    fi
  fi

  chmod 600 "$session_file" 2>/dev/null || true

  # Release lock
  flock -u 200 2>/dev/null || true
  exec 200>&- 2>/dev/null || true

  rm -f "$tmpf" 2>/dev/null || true

  # Leave marker in place to indicate completion (used for idempotency if message_id present)
  touch "${marker_dir}/done" 2>/dev/null || true

  # Successful completion: disable trap so marker is preserved
  trap - RETURN

  # --- Update ui_state session metadata (canonical single source) ---
  # Build session meta JSON under lock-free context (we already released file lock)
  if ensure_run_tmpdir >/dev/null 2>&1; then
    # Compute msg_count and last_ts safely (session_file exists)
    msg_count=0
    last_ts=""
    if [ -f "$session_file" ]; then
      msg_count="$(wc -l < "$session_file" 2>/dev/null || echo 0)"
      # Extract last ts from last NDJSON line if possible
      last_line="$(tail -n 1 "$session_file" 2>/dev/null || true)"
      if printf '%s' "$last_line" | jq -e . >/dev/null 2>&1; then
        last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      fi
    fi

    meta_json="$(jq -c -n --arg id "$sid" --argjson msg_count "$msg_count" --arg last_ts "${last_ts:-}" \
      '{id:$id, active:true, msg_count:$msg_count, last_ts:$last_ts}')"

    # Write canonical ui_state session file
    ui_state_write "sessions/${sid}.json" "$meta_json" || log_warn "UI_STATE" "failed to write session meta for $sid"
    # Update sessions index (best-effort): read existing index, add sid if missing
    idx_file="${GROQBASH_CONFIG_DIR%/}/ui_state/sessions/index.json"
    if [ -f "$idx_file" ]; then
      if jq -e --arg sid "$sid" '(.sessions // []) | index($sid) // empty' "$idx_file" >/dev/null 2>&1; then
        : # already present
      else
        # append sid
        tmp_idx="$(mktemp -p "${RUN_TMPDIR:-$GROQBASH_TMPDIR}" uiidx.XXXX 2>/dev/null || true)"
        if [ -n "$tmp_idx" ]; then
          jq --arg sid "$sid" '.sessions = ((.sessions // []) + [$sid])' "$idx_file" > "${tmp_idx}.new" 2>/dev/null && mv -f "${tmp_idx}.new" "$tmp_idx" && ui_state_write "sessions/index.json" "$(cat "$tmp_idx")" || true
          rm -f "$tmp_idx" 2>/dev/null || true
        fi
      fi
    else
      # create new index
      ui_state_write "sessions/index.json" "$(jq -c -n --argjson arr '[]' '{sessions:[]}' )" >/dev/null 2>&1 || true
      # then append sid
      ui_state_write "sessions/index.json" "$(jq -c -n --arg sid "$sid" '{sessions:[$sid]}' )" >/dev/null 2>&1 || true
    fi
  fi

  if [ "${DEBUG:-0}" -eq 1 ]; then
    log_info "SESSION" "appended message id ${message_id:-<no-id>} to $session_file"
  fi
  return 0
}

# Default parameters for session helpers (configurable via env)
: "${LAST_CHECK_LINES:=50}"
#--10<---[ /SECTION: PRECORE_SESSION_MVP ]--->10--

#--11<---[ SECTION: PRECORE_SESSION_CACHE ]--->11--
# Session cache helpers
# - session_cache_key <sid> <params_string> -> prints key
# - session_cache_get <sid> <params_string> <out_file> -> returns 0 if cache hit and not expired
# - session_cache_set <sid> <params_string> <ttl_sec> <infile> -> stores cache
# - session_cache_invalidate <sid> [<params_string>] -> invalidates cache entries
# Cache stored under $GROQBASH_MODELS_DIR/session_cache or $GROQBASH_TMPDIR/session_cache
# ---------------------------------------------------------------------------
SESSION_CACHE_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}/session_cache"
mkdir -p "$SESSION_CACHE_DIR" 2>/dev/null || true
chmod 700 "$SESSION_CACHE_DIR" 2>/dev/null || true

# Compute a stable hash for params_string (portable)
_session_hash() {
  local s="$1" h=""
  if command -v sha256sum >/dev/null 2>&1; then
    h="$(printf '%s' "$s" | sha256sum 2>/dev/null | awk '{print $1}' || true)"
  elif command -v openssl >/dev/null 2>&1; then
    h="$(printf '%s' "$s" | openssl dgst -sha256 2>/dev/null | awk '{print $2}' || true)"
  else
    # fallback: base64 of string (not cryptographic but stable)
    h="$(printf '%s' "$s" | base64 | tr -d '\n' | cut -c1-64)"
  fi
  printf '%s' "${h:-}"
}

session_cache_key() {
  local sid="$1" params="$2"
  [ -n "$sid" ] || return 1
  params="${params:-}"
  printf '%s|%s' "$sid" "$(_session_hash "$params")"
}

session_cache_get() {
  local sid="$1" params="$2" out="$3"
  local key file ts now ttl
  key="$(session_cache_key "$sid" "$params")" || return 1
  file="${SESSION_CACHE_DIR%/}/${key}.cache"
  if [ ! -f "$file" ]; then return 1; fi
  # First line: expiry epoch; rest: payload
  read -r ts < "$file" 2>/dev/null || ts=0
  now="$(date +%s)"
  if [ "$now" -ge "$ts" ]; then
    # expired
    rm -f "$file" 2>/dev/null || true
    return 1
  fi
  # output payload to out
  if [ -n "$out" ]; then
    tail -n +2 "$file" > "$out" 2>/dev/null || return 1
  else
    tail -n +2 "$file" 2>/dev/null || return 0
  fi
  return 0
}

session_cache_set() {
  local sid="$1" params="$2" ttl="${3:-300}" infile="$4"
  local key file expiry now
  key="$(session_cache_key "$sid" "$params")" || return 1
  file="${SESSION_CACHE_DIR%/}/${key}.cache"
  now="$(date +%s)"
  expiry=$((now + (ttl + 0)))
  # Write atomically
  {
    printf '%s\n' "$expiry"
    if [ -n "$infile" ] && [ -f "$infile" ]; then
      cat "$infile"
    else
      cat -
    fi
  } > "${file}.tmp.$$" 2>/dev/null || return 1
  mv -f "${file}.tmp.$$" "$file" 2>/dev/null || { rm -f "${file}.tmp.$$" 2>/dev/null || true; return 1; }
  chmod 600 "$file" 2>/dev/null || true
  return 0
}

session_cache_invalidate() {
  local sid="$1" params="$2" key pattern
  if [ -z "$sid" ]; then return 1; fi
  if [ -n "$params" ]; then
    key="$(session_cache_key "$sid" "$params")" || return 1
    rm -f "${SESSION_CACHE_DIR%/}/${key}.cache" 2>/dev/null || true
  else
    # remove all entries for sid
    pattern="${SESSION_CACHE_DIR%/}/${sid}|*.cache"
    # shell globbing safe removal
    for f in ${pattern}; do
      [ -e "$f" ] && rm -f -- "$f" 2>/dev/null || true
    done
  fi
  return 0
}
#--11<---[ /SECTION: PRECORE_SESSION_CACHE ]--->11--
#--12<---[ SECTION: PRECORE_RUNTIME_GLOB ]--->12--
# Runtime globals and normalization (non-destructive defaults)
# ---------------------------------------------------------------------------
# NOTE: Do not assign RUN_TMPDIR/RESP/PAYLOAD/ERRF to empty strings here.
# Those variables must remain unset unless explicitly created by ensure_run_tmpdir
# in the main process. Assign only safe, non-runtime defaults.
CONTENT="${CONTENT:-}"
JSON_INPUT="${JSON_INPUT:-}"
# Session CLI flags defaults (initialized to avoid set -u failures)
SESSION_ID="${SESSION_ID:-}"
SESSION_WINDOW="${SESSION_WINDOW:-}"
# Runtime flags and other non-runtime defaults
TEMPLATE="${TEMPLATE:-}"
BATCH_FILE="${BATCH_FILE:-}"
CHAT_MODE="${CHAT_MODE:-0}"
SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}"
REFRESH_MODELS="${REFRESH_MODELS:-0}"
LIST_MODELS="${LIST_MODELS:-0}"
FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-0}"
OUT_PATH="${OUT_PATH:-}"
SYSTEM_PROMPT="${SYSTEM_PROMPT:-}"
TURE="${TURE:-${TEMPERATURE:-1.0}}"
TEMPERATURE="${TEMPERATURE:-${TURE:-1.0}}"
TURE="${TURE:-$TEMPERATURE}"
MAX_TOKENS="${MAX_TOKENS:-4096}"
MODEL="${MODEL:-}"
AUTO_POLICY="${AUTO_POLICY:-preferred}"
DEBUG="${DEBUG:-0}"
QUIET="${QUIET:-0}"
DRY_RUN="${DRY_RUN:-0}"
STREAM_MODE="${STREAM_MODE:-0}"
OUTPUT_MODE="${OUTPUT_MODE:-text}"
THRESHOLD="${THRESHOLD:-1000}"
MAX_RETRIES="${MAX_RETRIES:-3}"
SUPPORTED_PROVIDERS="${SUPPORTED_PROVIDERS:-groq gemini huggingface}"
PROVIDER="${PROVIDER:-groq}"
# Ensure config dir exists and is usable before reading persisted provider
# (this uses the ensure_config_dir helper if present; otherwise create dir defensively)
if type ensure_config_dir >/dev/null 2>&1; then
  ensure_config_dir >/dev/null 2>&1 || true
else
  mkdir -p "${GROQBASH_CONFIG_DIR%/}" 2>/dev/null || true
fi

# NOTE: Do NOT reassign RUN_TMPDIR, RESP, PAYLOAD, ERRF to empty values anywhere
# after this point; those are runtime-managed and must be created by ensure_run_tmpdir
# in the main process.
CURL_BASE_OPTS=( --silent --show-error --no-buffer --max-time 120 )

# Ensure runtime tmpdir early so RESP/RUN_TMPDIR are available for later code
if [ "${GROQBASH_SOURCE_ONLY:-0}" -eq 0 ]; then
  if ! ensure_run_tmpdir >/dev/null 2>&1; then
    log_error "TMP" "cannot create or access RUN_TMPDIR ($GROQBASH_TMPDIR). Aborting."
    exit "$GROQBASHERRTMP"
  fi
fi

# ---------------------------------------------------------------------------
# Helpers: normalization
# ---------------------------------------------------------------------------
_normalize_bool_env() {
  local var val
  for var in ALLOW_API_CALLS DRY_RUN DEBUG; do
    val="${!var:-}"
    if [ -n "$val" ]; then
      if is_truthy "$val"; then
        export "$var"=1
      else
        export "$var"=0
      fi
    fi
  done
}
_normalize_bool_env
#--12<---[ /SECTION: PRECORE_RUNTIME_GLOB ]--->12--
########################################
# SECTION: PRECORE - END
########################################
