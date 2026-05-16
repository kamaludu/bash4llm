documents.md written to ~/groqbash/list/documents.md
 groqbash\n- **Line**: L3613\n- **Section**: misc
\n```sh
    if [ "$file_match" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model "%s" is not present in %s\n' "$model" "$MODELS_FILE" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model "$norm_model"; then\n    printf 'groqbash: ERROR: The "%s" model is not supported by GroqBash (requires non-text input).\n' "$model" >&2\n    return 1\n  fi\n\n  return 0\n}\n\n#--4<---[ SECTION: CORE_SETUP_CLI_PARSE ]--->4--\n# CLI parsing (flags, normalization, immediate actions)\n# ---------------------------------------------------------------------------\nJSON_INPUT="${JSON_INPUT:-}" TEMPLATE="${TEMPLATE:-}" BATCH_FILE="${BATCH_FILE:-}" CHAT_MODE="${CHAT_MODE:-0}" SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}"\nLIST_MODELS="${LIST_MODELS:-0}" LIST_PROVIDERS="${LIST_PROVIDERS:-0}" FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-}" OUT_PATH="${OUT_PATH:-}"\nDRY_RUN="${DRY_RUN:-0}" STREAM_MODE="${STREAM_MODE:-0}" QUIET="${QUIET:-0}" INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}" DEBUG="${DEBUG:-0}"\nPROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}"\nSHOW_CONFIG="${SHOW_CONFIG:-0}" DIAGNOSTICS="${DIAGNOSTICS:-0}"\nFILE_INPUTS=() ARGS=() OUTPUT_MODE="${OUTPUT_MODE:-text}"\nMODEL_CLI_SET="${MODEL_CLI_SET:-0}"\nINSTALL_EXTRAS_SRC=""\n\nwhile [ $# -gt 0 ]; do\n  case "$1" in\n    --refresh-models|--refresh-model) REFRESH_MODELS=1; shift ;;
```\n
\n## FILE_INPUTS
\n- **File**: groqbash\n- **Line**: L3613\n- **Section**: misc
\n```sh
# SOURCE: groqbash:3613\n# TYPE: variable (array)\n# USAGE: populated by CLI parsing; used to hold non-file arguments\n    if [ "$file_match" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model "%s" is not present in %s\n' "$model" "$MODELS_FILE" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model "$norm_model"; then\n    printf 'groqbash: ERROR: The "%s" model is not supported by GroqBash (requires non-text input).\n' "$model" >&2\n    return 1\n  fi\n\n  return 0\n}\n\n#--4<---[ SECTION: CORE_SETUP_CLI_PARSE ]--->4--\n# CLI parsing (flags, normalization, immediate actions)\n# ---------------------------------------------------------------------------\nJSON_INPUT="${JSON_INPUT:-}" TEMPLATE="${TEMPLATE:-}" BATCH_FILE="${BATCH_FILE:-}" CHAT_MODE="${CHAT_MODE:-0}" SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}"\nLIST_MODELS="${LIST_MODELS:-0}" LIST_PROVIDERS="${LIST_PROVIDERS:-0}" FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-}" OUT_PATH="${OUT_PATH:-}"\nDRY_RUN="${DRY_RUN:-0}" STREAM_MODE="${STREAM_MODE:-0}" QUIET="${QUIET:-0}" INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}" DEBUG="${DEBUG:-0}"\nPROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}"\nSHOW_CONFIG="${SHOW_CONFIG:-0}" DIAGNOSTICS="${DIAGNOSTICS:-0}"\nFILE_INPUTS=() ARGS=() OUTPUT_MODE="${OUTPUT_MODE:-text}"\nMODEL_CLI_SET="${MODEL_CLI_SET:-0}"\nINSTALL_EXTRAS_SRC=""\n
```\n
\n## _cleanup_local_tmp
\n- **File**: groqbash\n- **Line**: L2173\n- **Section**: misc
\n```sh
# source: groqbash:2173\n_cleanup_local_tmp() {\n  local tmp_payload="$1" tmp_b64_local="$2" json_input_file="$3"\n  [ -n "$tmp_payload" ] && rm -f -- "$tmp_payload" 2>/dev/null || true\n  [ -n "$tmp_b64_local" ] && rm -f -- "$tmp_b64_local" 2>/dev/null || true\n  [ -n "$json_input_file" ] && rm -f -- "$json_input_file" 2>/dev/null || true\n}
```\n
\n## _detect_base64_opts
\n- **File**: groqbash\n- **Line**: L1116\n- **Section**: misc
\n```sh
# source: groqbash:1116\n_detect_base64_opts() {\n  # Default conservative options\n  B64_WRAP_OPT=""\n  B64_DECODE_OPT="-d"\n\n  # Detect encode option that prevents line wrapping (GNU coreutils)\n  if printf '' | base64 -w0 >/dev/null 2>&1; then\n    B64_WRAP_OPT="-w0"\n  else\n    B64_WRAP_OPT=""\n  fi\n\n  # Detect decode option -d vs -D\n  if printf 'dGVzdA==' | base64 -d 2>/dev/null | grep -q 'test'; then\n    B64_DECODE_OPT="-d"\n  elif printf 'dGVzdA==' | base64 -D 2>/dev/null | grep -q 'test'; then\n    B64_DECODE_OPT="-D"\n  else\n    B64_DECODE_OPT="-d"\n  fi\n\n  export B64_WRAP_OPT B64_DECODE_OPT\n}
```\n
\n## _file_mtime
\n- **File**: groqbash\n- **Line**: L1176\n- **Section**: misc
\n```sh
# source: groqbash:1176\n_file_mtime() {\n  local f="$1"\n  if [ ! -e "$f" ]; then printf '0'; return 0; fi\n  case "$(uname 2>/dev/null || echo Linux)" in\n    Darwin) stat -f %m "$f" 2>/dev/null || printf '0' ;;\n    *) stat -c %Y "$f" 2>/dev/null || printf '0' ;;\n  esac\n}
```\n
\n## _get_file_signature
\n- **File**: groqbash\n- **Line**: L1471\n- **Section**: misc
\n```sh
# source: groqbash:1471\n_get_file_signature() {\n  local path="$1"\n  local hash="" stat_out="" dev="" inode="" size="" ctime="" mtime="" uid="" gid="" mode=""\n  # Return empty string if not a regular file\n  [ -f "$path" ] || { printf ''; return 0; }\n\n  # Decide whether to compute content hash (default 1)\n  local use_hash="${GROQBASH_SIG_HASH:-1}"\n\n  # Compute SHA256 if requested and available\n  if [ "${use_hash}" != "0" ] && command -v sha256sum >/dev/null 2>&1; then\n    hash="$(sha256sum "$path" 2>/dev/null | awk '{print $1}' || true)"\n  else\n    hash=""\n  fi\n\n  # Collect stat output in a portable way\n  case "$(uname 2>/dev/null || echo Linux)" in\n    Darwin)\n      # BSD/macOS stat format: device inode size ctime mtime uid gid mode\n      stat_out="$(stat -f '%d %i %z %c %m %u %g %p' "$path" 2>/dev/null || true)"\n      ;;\n    *)\n      # GNU stat format: device inode size ctime mtime uid gid mode\n      stat_out="$(stat -c '%d %i %s %Z %Y %u %g %a' "$path" 2>/dev/null || true)"\n      ;;\n  esac\n\n  # If stat failed, ensure variables are empty and continue (do not abort)
```\n
\n## _get_owner
\n- **File**: groqbash\n- **Line**: L1462\n- **Section**: misc
\n```sh
# source: groqbash:1462\n_get_owner() {\n  local path="$1" owner=""\n  case "$(uname 2>/dev/null || echo Linux)" in\n    Darwin) owner="$(stat -f %Su "$path" 2>/dev/null || true)" ;;\n    *) if command -v stat >/dev/null 2>&1; then owner="$(stat -c %U "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then owner="$(find "$path" -maxdepth 0 -printf '%u' 2>/dev/null || true)"; fi ;;\n  esac\n  printf '%s' "$owner"\n}
```\n
\n## _get_perm_string
\n- **File**: groqbash\n- **Line**: L1453\n- **Section**: misc
\n```sh
# source: groqbash:1453\n_get_perm_string() {\n  local path="$1" perm=""\n  case "$(uname 2>/dev/null || echo Linux)" in\n    Darwin) perm="$(stat -f %Sp "$path" 2>/dev/null || true)" ;;\n    *) if command -v stat >/dev/null 2>&1; then perm="$(stat -c %A "$path" 2>/dev/null || true)"; elif command -v find >/dev/null 2>&1; then perm="$(find "$path" -maxdepth 0 -printf '%M' 2>/dev/null || true)"; fi ;;\n  esac\n  printf '%s' "$perm"\n}
```\n
\n## _is_world_writable
\n- **File**: groqbash\n- **Line**: L1520\n- **Section**: misc
\n```sh
# source: groqbash:1520\n_is_world_writable() {\n  local d="$1" perms others_write\n  [ -d "$d" ] || return "$GROQBASHERRTMP"\n  perms="$(_get_perm_string "$d")"\n  [ -z "$perms" ] && return "$GROQBASHERRTMP"\n  others_write="$(printf '%s' "$perms" | awk '{print substr($0,9,1)}')"\n  [ "$others_write" = "w" ]\n}
```\n
\n## _mktemp_in_dir
\n- **File**: groqbash\n- **Line**: L564\n- **Section**: misc
\n```sh
# source: groqbash:564\n_mktemp_in_dir() {\n  local base="${1:-}" prefix="${2:-groq}" tmp\n  if [ -z "$base" ]; then\n    log_error "TMP" "_mktemp_in_dir: base dir required"\n    return "$GROQBASHERRTMP"\n  fi\n  # Delegate to _tmpf which already enforces umask/perms and returns a path\n  tmp="$(_tmpf file "$base" "$prefix" 2>/dev/null || true)"\n  if [ -z "$tmp" ]; then\n    log_error "TMP" "_mktemp_in_dir: failed to create temp in $base"\n    return "$GROQBASHERRTMP"\n  fi\n  printf '%s' "$tmp"\n  return 0\n}
```\n
\n## _normalize_bool_env
\n- **File**: groqbash\n- **Line**: L2130\n- **Section**: misc
\n```sh
# source: groqbash:2130\n_normalize_bool_env() {\n  local var val\n  for var in ALLOW_API_CALLS DRY_RUN DEBUG; do\n    val="${!var:-}"\n    if [ -n "$val" ]; then\n      if is_truthy "$val"; then\n        export "$var"=1\n      else\n        export "$var"=0\n      fi\n    fi\n  done\n}
```\n
\n## _session_hash
\n- **File**: groqbash\n- **Line**: L1989\n- **Section**: misc
\n```sh
# source: groqbash:1989\n_session_hash() {\n  local s="$1" h=""\n  if command -v sha256sum >/dev/null 2>&1; then\n    h="$(printf '%s' "$s" | sha256sum 2>/dev/null | awk '{print $1}' || true)"\n  elif command -v openssl >/dev/null 2>&1; then\n    h="$(printf '%s' "$s" | openssl dgst -sha256 2>/dev/null | awk '{print $2}' || true)"\n  else\n    # fallback: base64 of string (not cryptographic but stable)\n    h="$(printf '%s' "$s" | base64 | tr -d '\n' | cut -c1-64)"\n  fi\n  printf '%s' "${h:-}"\n}
```\n
\n## _tmpf
\n- **File**: groqbash\n- **Line**: L1555\n- **Section**: misc
\n```sh
# source: groqbash:1555\n_tmpf() {\n  local mode="$1" base="$2" prefix="${3:-groq}" tmp\n  if [ -z "$mode" ] || [ -z "$base" ]; then\n    log_error "TMP" "_tmpf usage: _tmpf <file|dir> <base_dir> [prefix]"\n    return "$GROQBASHERRTMP"\n  fi\n\n  # Prefer provided base, else GROQBASH_TMPDIR\n  if [ -z "$base" ] || [ ! -d "$base" ]; then\n    base="${GROQBASH_TMPDIR:-}"\n  fi\n  if [ -z "$base" ] || [ ! -d "$base" ]; then\n    log_error "TMP" "tmp base directory not available: $base"\n    return "$GROQBASHERRTMP"\n  fi\n\n  # Ensure base is inside GROQBASH_TMPDIR for safety\n  case "$base" in\n    "$GROQBASH_TMPDIR"/*|"$GROQBASH_TMPDIR") ;;\n    *)\n      # If base is not under GROQBASH_TMPDIR, prefer GROQBASH_TMPDIR\n      base="${GROQBASH_TMPDIR:-$base}"\n      ;;\n  esac\n\n  umask 077\n  if [ "$mode" = "file" ]; then\n    tmp="$(mktemp -p "$base" "${prefix}.XXXX" 2>/dev/null || true)"\n    if [ -z "$tmp" ]; then
```\n
\n## assemble_content
\n- **File**: groqbash\n- **Line**: L4467\n- **Section**: misc
\n```sh
# source: groqbash:4467\nassemble_content() {\n  CONTENT="${CONTENT:-}"\n  local tmpl tmp_tmpl tmp_final extra file_content\n\n  if [ -n "$JSON_INPUT" ]; then CONTENT=""; return 0; fi\n\n  if [ "${#FILE_INPUTS[@]}" -gt 0 ]; then\n    CONTENT="$(collect_input_from_files "${FILE_INPUTS[@]}")"\n    if [ "${#ARGS[@]}" -gt 0 ]; then\n      extra="$(expand_args_to_content)"\n      [ -n "$extra" ] && CONTENT="${CONTENT}"$'\n\n'"$extra"\n    fi\n    return 0\n  fi\n\n  if [ -n "$TEMPLATE" ]; then\n    if [ "${#FILE_INPUTS[@]}" -gt 0 ]; then\n      CONTENT="$(collect_input_from_files "${FILE_INPUTS[@]}")"\n    elif [ -n "$STDIN_CONTENT" ]; then\n      CONTENT="$STDIN_CONTENT"\n    else\n      if [ "${#ARGS[@]}" -gt 0 ]; then CONTENT="$(expand_args_to_content)"; else CONTENT=""; fi\n    fi\n\n    tmpl="$(cat "$GROQBASH_TEMPLATES_DIR/$TEMPLATE" 2>/dev/null || true)"\n    ensure_run_tmpdir\n    tmp_tmpl="$(_mktemp_in_dir "$RUN_TMPDIR" 2>/dev/null || true)"\n\n    if [ -n "$tmp_tmpl" ]; then
```\n
\n## atomic_write
\n- **File**: groqbash\n- **Line**: L612\n- **Section**: misc
\n```sh
# source: groqbash:612\natomic_write() {\n  # Atomic write with optional lock support.\n  # Usage: atomic_write /path/to/target [timeout_seconds]\n  local dest="$1"\n  local timeout="${2:-10}"\n  [ -n "$dest" ] || return "$GROQBASHERRTMP"\n  local destdir tmp lockfile rc\n\n  destdir="$(dirname -- "$dest")"\n  mkdir -p "$destdir" 2>/dev/null || { log_error "ATOMICFAIL" "cannot create dir $destdir"; return "$GROQBASHERRTMP"; }\n  lockfile="${destdir}/.groqbash.lock"\n\n  tmp="$(mktemp -p "$destdir" .groq-atomic.XXXXXX 2>/dev/null || true)"\n  [ -n "$tmp" ] || tmp="$destdir/.groq-atomic.$$.$RANDOM"\n\n  if ! cat - > "$tmp"; then\n    rm -f -- "$tmp" 2>/dev/null || true\n    log_error "ATOMICFAIL" "writing to temp failed"\n    return "$GROQBASHERRTMP"\n  fi\n  chmod 600 "$tmp" 2>/dev/null || true\n\n  # If lock_exec available, use it to perform the mv under lock; otherwise mv directly\n  if type lock_exec >/dev/null 2>&1; then\n    lock_exec "$lockfile" "$timeout" -- sh -c '\n      set -e\n      mv -f -- "$1" "$2"\n      chmod 600 "$2" 2>/dev/null || true\n    ' _ "$tmp" "$dest" || { rc=$?; rm -f -- "$tmp" 2>/dev/null || true; return "$rc"; }
```\n
\n## auto_select_model_dispatch
\n- **File**: groqbash\n- **Line**: L3086\n- **Section**: misc
\n```sh
# source: groqbash:3086\nauto_select_model_dispatch() {\n  local fn="auto_select_model_${PROVIDER}"\n  if call_provider "$fn"; then\n    return 0\n  fi\n  return 1\n}
```\n
\n## auto_select_model_groq
\n- **File**: groqbash\n- **Line**: L3002\n- **Section**: misc
\n```sh
# source: groqbash:3002\nauto_select_model_groq() {\n  # Return the first supported model candidate from MODELS_FILE for Groq provider.\n  # Normalizes entries by stripping common prefixes like "models/" and "groq:".\n  # Prints the selected model (normalized) to stdout and returns 0 on success,\n  # returns 1 if no suitable model found.\n  local file="$MODELS_FILE" line norm cnt=0\n  if [ -f "$file" ] && [ -s "$file" ]; then\n    while IFS= read -r line || [ -n "$line" ]; do\n      [ -z "$line" ] && continue\n      cnt=$((cnt+1))\n      norm="$(printf '%s' "$line" | sed -e 's#^models/##' -e 's#^groq[:/ -]*##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')"\n      if is_supported_model "$norm"; then\n        printf '%s' "$norm"\n        return 0\n      fi\n      [ "$cnt" -ge "$MAX_MODELS" ] && break\n    done < "$file"\n  fi\n  return 1\n}
```\n
\n## autoselectmodelgroq
\n- **File**: groqbash\n- **Line**: L3023\n- **Section**: misc
\n```sh
# source: groqbash:3023\nautoselectmodelgroq() { auto_select_model_groq "$@"; }
```\n
\n## b64_atomic_read
\n- **File**: groqbash\n- **Line**: L888\n- **Section**: misc
\n```sh
# source: groqbash:888\nb64_atomic_read() {\n  local src="$1"\n  [ -f "$src" ] || return 1\n  b64decode < "$src"\n  return $?\n}
```\n
\n## b64_atomic_write
\n- **File**: groqbash\n- **Line**: L862\n- **Section**: misc
\n```sh
# source: groqbash:862\nb64_atomic_write() {\n  local dest="$1"\n  local timeout="${2:-10}"\n  shift 2 || true\n  [ -n "$dest" ] || { log_error "B64FAIL" "b64_atomic_write: dest required"; return "$GROQBASHERRTMP"; }\n  local destdir tmp lockfile\n  destdir="$(dirname -- "$dest")"\n  mkdir -p "$destdir" 2>/dev/null || { log_error "B64FAIL" "cannot create dir $destdir"; return "$GROQBASHERRTMP"; }\n  # Use a lock specific to the destination directory to avoid global contention\n  lockfile="${destdir%/}/.groqbash.lock"\n  tmp="$(mktemp -p "$destdir" .groq-b64.XXXXXX 2>/dev/null || true)"\n  [ -n "$tmp" ] || tmp="$destdir/.groq-b64.$$.$RANDOM"\n  if ! b64encode > "$tmp"; then\n    rm -f -- "$tmp" 2>/dev/null || true\n    log_error "B64FAIL" "base64 encoding failed"\n    return "$GROQBASHERRTMP"\n  fi\n  chmod 600 "$tmp" 2>/dev/null || true\n  lock_exec "$lockfile" "$timeout" -- sh -c '\n    set -e\n    mv -f -- "$1" "$2"\n    chmod 600 "$2" 2>/dev/null || true\n  ' _ "$tmp" "$dest" || { rc=$?; rm -f -- "$tmp" 2>/dev/null || true; return "$rc"; }\n  return 0\n}
```\n
\n## b64decode
\n- **File**: groqbash\n- **Line**: L371\n- **Section**: misc
\n```sh
# source: groqbash:371\nb64decode() {\n  # Use base64 with decode option if set; fall back to -d explicitly\n  if [ -n "${B64_DECODE_OPT:-}" ]; then\n    base64 ${B64_DECODE_OPT}\n  else\n    base64 -d\n  fi\n}
```\n
\n## b64encode
\n- **File**: groqbash\n- **Line**: L362\n- **Section**: misc
\n```sh
# source: groqbash:362\nb64encode() {\n  # Use base64 with wrap option if available; ensure single-line output\n  if [ -n "${B64_WRAP_OPT:-}" ]; then\n    base64 ${B64_WRAP_OPT}\n  else\n    base64 | tr -d '\n'\n  fi\n}
```\n
\n## build_payload_from_vars
\n- **File**: groqbash\n- **Line**: L3220\n- **Section**: misc
\n```sh
# source: groqbash:3220\nbuild_payload_from_vars() {\n  ensure_run_tmpdir\n  local fn="buildpayload_${PROVIDER}"\n  if call_provider "$fn"; then\n    return 0\n  else\n    rc=$?\n    if [ "$rc" -eq 127 ]; then\n      log_error "PROVIDER" "Provider '$PROVIDER' does not provide $fn()."\n      exit "$GROQBASHERRAPI"\n    else\n      return "$rc"\n    fi\n  fi\n}
```\n
\n## buildpayload_groq
\n- **File**: groqbash\n- **Line**: L2180\n- **Section**: misc
\n```sh
# source: groqbash:2180\nbuildpayload_groq() {\n  # Build payload for Groq provider into tmp_payload\n  # Assumes: MODEL, TURE, MAX_TOKENS, MESSAGES_JSON, BUILD_MESSAGES_FILE, STREAM_MODE, JSON_INPUT, CONTENT may be set\n  local tmp_payload stream_json VALID_MESSAGES_JSON http_code edgecase now_ts model_from_file payload_size staged_b64 tmp_b64 content_val msgs\n\n  ensure_run_tmpdir || return "$GROQBASHERRTMP"\n  tmp_payload="$(_mktemp_in_dir "$RUN_TMPDIR" payload.XXXXXX.json 2>/dev/null || printf '%s' "$RUN_TMPDIR/payload.json")"\n\n  # Normalize stream_json to a JSON boolean literal (true/false)\n  if is_truthy "${STREAM_MODE:-0}"; then\n    stream_json=true\n  else\n    stream_json=false\n  fi\n  case "${stream_json:-}" in\n    true|false) ;;    # valid\n    1) stream_json=true ;;\n    0) stream_json=false ;;\n    *) stream_json=false ;;\n  esac\n\n  # Validate numeric inputs used with tonumber in jq\n  if ! printf '%s' "${TURE:-}" | grep -qE '^[0-9]+([.][0-9]+)?$'; then\n    log_warn "ARGS" "invalid TURE value '${TURE:-}'; defaulting to 1.0"\n    TURE="1.0"\n  fi\n  if ! printf '%s' "${MAX_TOKENS:-}" | grep -qE '^[0-9]+$'; then\n    log_warn "ARGS" "invalid MAX_TOKENS value '${MAX_TOKENS:-}'; defaulting to 4096"\n    MAX_TOKENS="4096"
```\n
\n## buildpayloadgroq
\n- **File**: groqbash\n- **Line**: L2322\n- **Section**: misc
\n```sh
# source: groqbash:2322\nbuildpayloadgroq() { buildpayload_groq "$@"; }
```\n
\n## call_api_groq
\n- **File**: groqbash\n- **Line**: L2327\n- **Section**: misc
\n```sh
# source: groqbash:2327\ncall_api_groq() {\n  # Robust non-streaming call to Groq API\n  # Expects: RUN_TMPDIR, RESP path variable, and payload file (GROQBASH_TMP_PAYLOAD or PAYLOAD)\n  local tmp_payload resp_tmp ERRF http_code rc resp_size errf_size now_ts stderr_head provider_url send_payload decoded_payload key_header CURL_CMD_ARR\n\n  ensure_run_tmpdir || return "$GROQBASHERRTMP"\n\n  # Determine payload file to send\n  tmp_payload="${GROQBASH_TMP_PAYLOAD:-${PAYLOAD:-}}"\n  if [ -z "${tmp_payload:-}" ]; then\n    log_error "CALL" "no payload file specified (GROQBASH_TMP_PAYLOAD or PAYLOAD)"\n    return 1\n  fi\n\n  # Network policy: same semantics as streaming path\n  if ! enforce_network_policy >/dev/null 2>&1; then\n    if is_truthy "${DRY_RUN:-0}"; then\n      # show_payload_head is diagnostic; show only when DEBUG=1\n      if [ "${DEBUG:-0}" -eq 1 ]; then\n        show_payload_head "${PAYLOAD:-}" 200 || true\n        log_info "DRYRUN" "DRY-RUN: skipping non-streaming HTTP call"\n      fi\n      return 0\n    fi\n    log_error "NETWORK" "Network calls disabled; aborting non-streaming request."\n    return "$GROQBASHERRCURL_FAILED"\n  fi\n\n  # Ensure API key present (unless dry-run)
```\n
\n## call_api_once
\n- **File**: groqbash\n- **Line**: L3238\n- **Section**: misc
\n```sh
# source: groqbash:3238\ncall_api_once() {\n  if [ "${DRY_RUN:-0}" -eq 1 ]; then\n    # show_payload_head is diagnostic; show only when DEBUG=1\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      show_payload_head "$PAYLOAD" 200 || true\n      log_info "DRYRUN" "DRY-RUN: skipping provider HTTP call"\n    fi\n    return 0\n  fi\n  local fn="call_api_${PROVIDER}"\n  if call_provider "$fn"; then\n    return 0\n  else\n    rc=$?\n    if [ "$rc" -eq 127 ]; then\n      log_error "PROVIDER" "Provider '$PROVIDER' does not provide $fn()."\n      exit "$GROQBASHERRAPI"\n    else\n      return "$rc"\n    fi\n  fi\n}
```\n
\n## call_api_streaming
\n- **File**: groqbash\n- **Line**: L3261\n- **Section**: misc
\n```sh
# source: groqbash:3261\ncall_api_streaming() {\n  if [ "${DRY_RUN:-0}" -eq 1 ]; then\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      show_payload_head "$PAYLOAD" 200 || true\n      log_info "DRYRUN" "DRY-RUN: skipping provider streaming HTTP call"\n    fi\n    return 0\n  fi\n  local fn="call_api_streaming_${PROVIDER}"\n  if call_provider "$fn"; then\n    return 0\n  else\n    rc=$?\n    if [ "$rc" -eq 127 ]; then\n      log_error "PROVIDER" "Provider '$PROVIDER' does not provide $fn()."\n      exit "$GROQBASHERRAPI"\n    else\n      return "$rc"\n    fi\n  fi\n}
```\n
\n## call_api_streaming_groq
\n- **File**: groqbash\n- **Line**: L2570\n- **Section**: misc
\n```sh
# source: groqbash:2570\ncall_api_streaming_groq() {\n  # Streaming call for Groq provider with robust checks and diagnostics.\n  # Expects: RUN_TMPDIR, RESP variable, and payload file (GROQBASH_TMP_PAYLOAD or PAYLOAD).\n  local tmp_payload provider_url resp_raw resp_lines resp_valid resp_chunks resp_tmp ERRF rc stderr_head now_ts decoded_payload finish_reason req_id edgecase send_payload CURL_CMD\n\n  ensure_run_tmpdir || return "$GROQBASHERRTMP"\n\n  # Network policy and API key checks (preserve existing repo semantics)\n  if ! enforce_network_policy >/dev/null 2>&1; then\n    if is_truthy "${DRY_RUN:-0}"; then\n      if [ "${DEBUG:-0}" -eq 1 ]; then\n        show_payload_head "${PAYLOAD:-}" 200 || true\n        log_info "DRYRUN" "DRY-RUN: skipping streaming HTTP call"\n      fi\n      return 0\n    fi\n    log_error "NETWORK" "Network calls disabled; aborting streaming request."\n    return "$GROQBASHERRCURL_FAILED"\n  fi\n\n  if [ -n "${PROVIDER_API_ENV_groq:-}" ] && [ -n "${!PROVIDER_API_ENV_groq:-}" ]; then\n    GROQ_API_KEY="${!PROVIDER_API_ENV_groq}"\n  fi\n  if [ -z "${GROQ_API_KEY:-}" ] && [ -z "${GROQBASH_API_KEY:-}" ]; then\n    log_error "APIKEY" "GROQ_API_KEY (or GROQBASH_API_KEY) is not set."\n    return "$GROQBASHERRNOAPIKEY"\n  fi\n\n  tmp_payload="${GROQBASH_TMP_PAYLOAD:-${PAYLOAD:-}}"
```\n
\n## call_api_streaming_groq_legacy
\n- **File**: groqbash\n- **Line**: L2805\n- **Section**: misc
\n```sh
# source: groqbash:2805\ncall_api_streaming_groq_legacy() { call_api_streaming_groq "$@"; }
```\n
\n## call_provider
\n- **File**: groqbash\n- **Line**: L3034\n- **Section**: misc
\n```sh
# source: groqbash:3034\ncall_provider() {\n  local fn="$1" shift_args=("${@:2}")\n  if type "$fn" >/dev/null 2>&1; then\n    "$fn" "${shift_args[@]}"\n    return $?\n  fi\n  return 127\n}
```\n
\n## canonical_config_dir
\n- **File**: groqbash\n- **Line**: L74\n- **Section**: misc
\n```sh
# source: groqbash:74\ncanonical_config_dir() {\n  printf '%s' "${GROQBASH_CONFIG_DIR%/}"\n}
```\n
\n## canonical_model_file
\n- **File**: groqbash\n- **Line**: L84\n- **Section**: misc
\n```sh
# source: groqbash:84\ncanonical_model_file() {\n  local prov="${1:-}"\n  printf '%s\n' "$(canonical_config_dir)/model.${prov}"\n}
```\n
\n## canonical_provider_file
\n- **File**: groqbash\n- **Line**: L79\n- **Section**: misc
\n```sh
# source: groqbash:79\ncanonical_provider_file() {\n  printf '%s\n' "$(canonical_config_dir)/provider"\n}
```\n
\n## canonical_provider_url_file
\n- **File**: groqbash\n- **Line**: L91\n- **Section**: misc
\n```sh
# source: groqbash:91\ncanonical_provider_url_file() {\n  # prefer canonical_config_dir() if present\n  if type canonical_config_dir >/dev/null 2>&1; then\n    cfgdir="$(canonical_config_dir)"\n  else\n    cfgdir="${GROQBASH_CONFIG_DIR:-${GROQBASH_DIR%/}/config}"\n  fi\n  printf '%s' "${cfgdir%/}/provider-url"\n}
```\n
\n## cleanup_run_tmp_on_exit
\n- **File**: groqbash\n- **Line**: L805\n- **Section**: misc
\n```sh
# source: groqbash:805\n  cleanup_run_tmp_on_exit() {\n    if [ "${DEBUG_PRESERVE:-0}" -eq 1 ]; then\n      if [ "${DEBUG:-0}" -eq 1 ]; then\n        log_info "TMP" "DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR"\n      fi\n      return 0\n    fi\n    if [ -n "${RUN_TMPDIR:-}" ]; then\n      case "$RUN_TMPDIR" in\n        "$GROQBASH_TMPDIR"/*|"$GROQBASH_TMPDIR")\n          rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true\n          if [ "${DEBUG:-0}" -eq 1 ]; then\n            log_info "TMP" "Cleaned RUN_TMPDIR: $RUN_TMPDIR"\n          fi\n          ;;\n        *)\n          if [ "${DEBUG:-0}" -eq 1 ]; then\n            log_info "TMP" "RUN_TMPDIR outside GROQBASH_TMPDIR; not removed: $RUN_TMPDIR"\n          fi\n          ;;\n      esac\n    fi\n  }
```\n
\n## cleanup_tmp
\n- **File**: groqbash\n- **Line**: L847\n- **Section**: misc
\n```sh
# source: groqbash:847\ncleanup_tmp() {\n  if [ -n "${RUN_TMPDIR:-}" ]; then\n    case "$RUN_TMPDIR" in\n      "$GROQBASH_TMPDIR"/*|"$GROQBASH_TMPDIR")\n        rm -rf -- "$RUN_TMPDIR" 2>/dev/null || true\n        ;;\n      *)\n        ;;\n    esac\n  fi\n}
```\n
\n## collect_input_from_files
\n- **File**: groqbash\n- **Line**: L3496\n- **Section**: misc
\n```sh
# source: groqbash:3496\ncollect_input_from_files() {\n  local out="" first=1 f\n  for f in "$@"; do\n    if file_readable "$f"; then\n      [ "$first" -eq 0 ] && out="${out}"$'\n\n'"--- FILE: ${f} ---"$'\n\n'\n      out="${out}$(cat "$f")"; first=0\n    else log_error "FILE" "file not readable: $f"; exit "$GROQBASHERRTMP"; fi\n  done\n  printf '%s' "$out"\n}
```\n
\n## dbg
\n- **File**: groqbash\n- **Line**: L444\n- **Section**: misc
\n```sh
# source: groqbash:444\ndbg() {\n  if [ "${DEBUG:-0}" -ne 0 ]; then\n    printf '%s\n' "$*" >&2\n  fi\n}
```\n
\n## detect_empty_edge_case
\n- **File**: groqbash\n- **Line**: L3304\n- **Section**: misc
\n```sh
# source: groqbash:3304\ndetect_empty_edge_case() {\n  # Populate edge-case variables and set GROQBASH_EDGE_EMPTY=1 when response is an "empty completion" edge.\n  local resp="${RESP:-}"\n  GROQBASH_EDGE_EMPTY=0\n  GROQBASH_EDGE_REQ_ID=""\n  GROQBASH_EDGE_FINISH_REASON=""\n  GROQBASH_EDGE_COMPLETION_TOKENS=0\n\n  if [ -z "${resp:-}" ] || [ ! -s "$resp" ]; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # If not valid JSON, consider it empty for edge detection\n  if ! is_valid_json_file "$resp"; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # If diagnostic JSON, mark as empty\n  if jq -e 'has("diagnostic") and .diagnostic==true' "$resp" >/dev/null 2>&1; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # Extract fields safely\n  local content finish_reason completion_tokens req_id\n  content="$(jq -r '.choices[0]?.message?.content // .choices[0]?.delta?.content // ""' "$resp" 2>/dev/null || echo "")"\n  finish_reason="$(jq -r '.choices[0]?.finish_reason // ""' "$resp" 2>/dev/null || echo "")"
```\n
\n## enforce_network_policy
\n- **File**: groqbash\n- **Line**: L173\n- **Section**: misc
\n```sh
# source: groqbash:173\nenforce_network_policy() {\n  # If DRY_RUN or GROQBASH_SKIP_NETWORK are truthy, disallow network.\n  if is_truthy "${DRY_RUN:-0}" || is_truthy "${GROQBASH_SKIP_NETWORK:-0}"; then\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      log_info "NETWORK" "Network calls disabled by DRY_RUN or GROQBASH_SKIP_NETWORK; skipping HTTP."\n    fi\n    return 1\n  fi\n\n  # QUIET does not disable network by itself, but if QUIET is used with a policy variable we enforce it.\n  if is_truthy "${GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET:-0}" && is_truthy "${QUIET:-0}"; then\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      log_info "NETWORK" "Network calls disabled due to QUIET policy."\n    fi\n    return 1\n  fi\n\n  return 0\n}
```\n
\n## ensure_api_key_for_provider
\n- **File**: groqbash\n- **Line**: L108\n- **Section**: misc
\n```sh
# source: groqbash:108\nensure_api_key_for_provider() {\n  local prov="$1"\n  local envvar current_key input_key custom_var custom_env\n  [ -n "$prov" ] || return 1\n  envvar="$(provider_api_env_var_name "$prov")"\n  custom_var="PROVIDER_API_ENV_${prov}"\n  custom_env="${!custom_var:-}"\n  if [ -n "$custom_env" ]; then\n    envvar="$custom_env"\n  fi\n  current_key="${!envvar:-}"\n\n  # If key present, sync groq alias and return\n  if [ -n "$current_key" ]; then\n    if [ "$prov" = "groq" ] && [ "$envvar" != "GROQ_API_KEY" ]; then\n      export GROQ_API_KEY="$current_key"\n    fi\n    return 0\n  fi\n\n  # Non-interactive: fail fast with clear error (do not prompt)\n  if [ ! -t 0 ]; then\n    printf 'groqbash: ERROR: missing API key for provider %s (env %s) in non-interactive mode\n' "$prov" "$envvar" >&2\n    return "$GROQBASHERRNOAPIKEY"\n  fi\n\n  # Interactive prompt (preserve previous behavior)\n  printf 'Enter API key for provider %s (env %s): ' "$prov" "$envvar" >&2\n  if ! IFS= read -r input_key; then
```\n
\n## ensure_config_dir
\n- **File**: groqbash\n- **Line**: L237\n- **Section**: misc
\n```sh
# source: groqbash:237\nensure_config_dir() {\n  # Normalize\n  GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR%/}"\n  if [ -z "$GROQBASH_CONFIG_DIR" ]; then\n    GROQBASH_CONFIG_DIR="${GROQBASH_DIR%/}/config"\n  fi\n\n  # Try to create directory (idempotent)\n  if ! mkdir -p "${GROQBASH_CONFIG_DIR}" 2>/dev/null; then\n    log_error "CONFIG" "cannot create config dir: ${GROQBASH_CONFIG_DIR}"\n    return 1\n  fi\n\n  # Enforce strict perms\n  chmod 700 "${GROQBASH_CONFIG_DIR}" 2>/dev/null || true\n\n  # Quick writability check: try to create a temp file inside\n  if ! : > "${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check" 2>/dev/null; then\n    log_error "CONFIG" "config dir not writable: ${GROQBASH_CONFIG_DIR}"\n    return 1\n  else\n    rm -f "${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check" 2>/dev/null || true\n  fi\n\n  return 0\n}
```\n
\n## ensure_run_tmpdir
\n- **File**: groqbash\n- **Line**: L722\n- **Section**: misc
\n```sh
# source: groqbash:722\nensure_run_tmpdir() {\n  # Usage:\n  #   ensure_run_tmpdir            -> create/export RUN_TMPDIR PAYLOAD RESP ERRF in-process\n  #   ensure_run_tmpdir --print    -> print RUN_TMPDIR to stdout (no trap, safe for subshell capture)\n  local print_only=0 subshell=0 tmpdir\n  if [ "${1:-}" = "--print" ]; then print_only=1; fi\n\n  # Detect subshell: prefer comparing BASHPID to $$ (reliable in bash)\n  # If BASHPID differs from $$ we are in a subshell; treat as subshell context.\n  if [ -n "${BASHPID:-}" ] && [ "${BASHPID:-}" != "$$" ]; then\n    subshell=1\n  fi\n\n  # If RUN_TMPDIR already set and valid, reuse it (do not clobber existing values)\n  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "${RUN_TMPDIR:-}" ]; then\n    chmod 700 "$RUN_TMPDIR" 2>/dev/null || true\n    : "${PAYLOAD:=$RUN_TMPDIR/payload}"\n    : "${RESP:=$RUN_TMPDIR/resp.json}"\n    : "${ERRF:=$RUN_TMPDIR/err.log}"\n    if [ "$print_only" -eq 0 ] && [ "$subshell" -eq 0 ]; then\n      : > "$RESP" 2>/dev/null || true\n      chmod 600 "$RESP" 2>/dev/null || true\n      : > "$ERRF" 2>/dev/null || true\n      chmod 600 "$ERRF" 2>/dev/null || true\n      export RUN_TMPDIR PAYLOAD RESP ERRF\n    fi\n    if [ "$print_only" -eq 1 ]; then\n      printf '%s' "$RUN_TMPDIR"\n    fi
```\n
\n## expand_args_to_content
\n- **File**: groqbash\n- **Line**: L3506\n- **Section**: misc
\n```sh
# source: groqbash:3506\nexpand_args_to_content() {\n  local out="" first=1 a\n  for a in "${ARGS[@]}"; do\n    if file_readable "$a"; then\n      [ "$first" -eq 0 ] && out="${out}"$'\n\n'"--- FILE: ${a} ---"$'\n\n'\n      out="${out}$(cat "$a")"; first=0\n    else\n      [ "$first" -eq 0 ] && out="${out}"$'\n\n'\n      out="${out}${a}"; first=0\n    fi\n  done\n  printf '%s' "$out"\n}
```\n
\n## extract_api_error
\n- **File**: groqbash\n- **Line**: L3283\n- **Section**: misc
\n```sh
# source: groqbash:3283\nextract_api_error() {\n  [ ! -s "${RESP:-}" ] && return 0\n\n  if jq -e . "$RESP" >/dev/null 2>&1; then\n    # Prefer explicit error.message, then any non-empty choice content (first), else empty.\n    jq -r '\n      ( [ .error?.message // empty ] \n        + [ .choices[]? | (.message?.content // .delta?.content // empty) ] )\n      | map(select(length > 0))\n      | .[0] // empty\n    ' "$RESP" 2>/dev/null | head -n1 || true\n  else\n    awk 'NF{print; exit}' "$RESP" 2>/dev/null || true\n  fi\n}
```\n
\n## extract_text_from_resp
\n- **File**: groqbash\n- **Line**: L656\n- **Section**: misc
\n```sh
# source: groqbash:656\nextract_text_from_resp() {\n  # Extract textual content from RESP and print to stdout.\n  # Return codes:\n  # 0 = success (text printed)\n  # 2 = RESP is diagnostic (no real content)\n  # 1 = no textual content found or error\n  local resp_file="${RESP:-}"\n  if [ -z "${resp_file:-}" ]; then\n    log_error "EXTRACT" "RESP path not set"\n    return 1\n  fi\n\n  if ! is_valid_json_file "$resp_file"; then\n    log_warn "EXTRACT" "RESP missing or not valid JSON: $resp_file"\n    # If file exists but not JSON, output raw content as fallback\n    if [ -f "$resp_file" ]; then\n      cat "$resp_file" 2>/dev/null || true\n      return 0\n    fi\n    return 1\n  fi\n\n  # If diagnostic JSON, bail with info\n  if jq -e 'has("diagnostic") and .diagnostic==true' "$resp_file" >/dev/null 2>&1; then\n    log_warn "EXTRACT" "RESP is diagnostic JSON; skipping text extraction"\n    return 2\n  fi\n\n  # 1) choices[].message.content or choices[].delta.content
```\n
\n## file_readable
\n- **File**: groqbash\n- **Line**: L3520\n- **Section**: misc
\n```sh
# source: groqbash:3520\nfile_readable() { [ -r "$1" ] && [ -f "$1" ]; }
```\n
\n## file_size
\n- **File**: groqbash\n- **Line**: L388\n- **Section**: misc
\n```sh
# source: groqbash:388\nfile_size() {\n  local f="$1"\n  if [ -z "$f" ] || [ ! -f "$f" ]; then\n    printf '0'\n    return 0\n  fi\n  case "$(uname 2>/dev/null || echo Linux)" in\n    Darwin) stat -f %z "$f" 2>/dev/null || printf '0' ;;\n    *) stat -c %s "$f" 2>/dev/null || printf '0' ;;\n  esac\n}
```\n
\n## finalize_and_output
\n- **File**: groqbash\n- **Line**: L3354\n- **Section**: misc
\n```sh
# source: groqbash:3354\nfinalize_and_output() {\n  local mode="$1" text="$2"\n  if { [ "$mode" = "json" ] || [ "$mode" = "pretty" ]; } && [ ! -s "${RESP:-}" ]; then\n    log_error "RESP" "response file missing or empty: ${RESP:-<unset>}"\n    return "$GROQBASHERRTMP"\n  fi\n\n  case "$mode" in\n    json) cat "$RESP" ;;\n    pretty) if jq -e . "$RESP" >/dev/null 2>&1; then jq . "$RESP"; else cat "$RESP"; fi ;;\n    raw) printf '%s' "$text" ;;\n    text) printf '%s\n' "$text" ;;\n    *) printf '%s\n' "$text" ;;\n  esac\n\n  if [ "$mode" = "text" ] || [ "$mode" = "raw" ]; then\n    [ "${FORCE_SAVE_MODE:-}" = "nosave" ] && return 0\n    local len do_save=0 dest_dir dest_path\n    len="$(printf '%s' "$text" | wc -c | tr -d ' ')"\n    if [ "${FORCE_SAVE_MODE:-}" = "save" ]; then\n      do_save=1\n    else\n      if [ "$len" -gt "$THRESHOLD" ]; then\n        do_save=1\n      fi\n    fi\n    if [ "$do_save" -eq 1 ]; then\n      if [ -n "$OUT_PATH" ]; then\n        if [ -d "$OUT_PATH" ]; then dest_dir="$OUT_PATH"; dest_path="$dest_dir/$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt"; else dest_path="$OUT_PATH"; dest_dir="$(dirname "$dest_path")"; fi
```\n
\n## getfile_signature
\n- **File**: groqbash\n- **Line**: L1518\n- **Section**: misc
\n```sh
# source: groqbash:1518\ngetfile_signature() { _get_file_signature "$1"; }
```\n
\n## is_number
\n- **File**: groqbash\n- **Line**: L3524\n- **Section**: misc
\n```sh
# source: groqbash:3524\nis_number() { printf '%s\n' "$1" | awk 'BEGIN{exit 0} {exit !( $0+0 == $0+0 )}'; }
```\n
\n## is_supported_model
\n- **File**: groqbash\n- **Line**: L3527\n- **Section**: misc
\n```sh
# source: groqbash:3527\nis_supported_model() {\n  # Return 0 if model name appears to support text-only usage.\n  # Reject models that clearly indicate image/audio/embedding/multimodal capabilities.\n  local m="${1:-}" l\n  [ -n "$m" ] || return 1\n  l="$(printf '%s' "$m" | tr '[:upper:]' '[:lower:]')"\n\n  # Patterns that indicate non-text capabilities\n  case "$l" in\n    *image*|*imagen*|*img*|*vision*|*vqa*|*vit*|*clip*|*render*|*generate-image*|*generate_image* ) return 1 ;;\n    *audio*|*speech*|*tts*|*wav2vec*|*whisper*|*native-audio* ) return 1 ;;\n    *embed*|*embedding*|*vector* ) return 1 ;;\n    *multimodal*|*vision_audio*|*vision-audio* ) return 1 ;;\n    *) return 0 ;;\n  esac\n}
```\n
\n## is_truthy
\n- **File**: groqbash\n- **Line**: L380\n- **Section**: misc
\n```sh
# source: groqbash:380\nis_truthy() {\n  case "${1:-}" in\n    1|true|TRUE|True|yes|YES|Yes) return 0 ;;\n    *) return 1 ;;\n  esac\n}
```\n
\n## is_tty_out
\n- **File**: groqbash\n- **Line**: L4081\n- **Section**: misc
\n```sh
# source: groqbash:4081\nis_tty_out() {\n  # Return success if stdout is a TTY\n  [ -t 1 ]\n}
```\n
\n## is_valid_json_file
\n- **File**: groqbash\n- **Line**: L401\n- **Section**: misc
\n```sh
# source: groqbash:401\nis_valid_json_file() {\n  local f="$1"\n  [ -f "$f" ] || return 1\n  [ -s "$f" ] || return 1\n  # Trim leading BOM/whitespace by letting jq parse; jq -e returns 0 on valid JSON\n  jq -e . "$f" >/dev/null 2>&1\n}
```\n
\n## is_valid_json_string
\n- **File**: groqbash\n- **Line**: L352\n- **Section**: misc
\n```sh
# source: groqbash:352\nis_valid_json_string() {\n  local s="$1"\n  [ -n "${s:-}" ] || return 1\n  printf '%s' "$s" | jq -e . >/dev/null 2>&1\n}
```\n
\n## jq_safe
\n- **File**: groqbash\n- **Line**: L1189\n- **Section**: misc
\n```sh
# source: groqbash:1189\njq_safe() {\n  # wrapper to run jq and capture errors to ERRF if set\n  local filter="$1" file="$2" rc\n  if [ -z "$file" ] || [ ! -s "$file" ]; then\n    return 1\n  fi\n  if ! jq -e "$filter" "$file" >/dev/null 2>&1; then\n    rc=$?\n    # If ERRF is defined, append jq stderr for diagnostics\n    if [ -n "${ERRF:-}" ]; then\n      jq "$filter" "$file" 2>>"$ERRF" >/dev/null 2>&1 || true\n    fi\n    return "$rc"\n  fi\n  return 0\n}
```\n
\n## list_files_sorted_by_mtime
\n- **File**: groqbash\n- **Line**: L1146\n- **Section**: misc
\n```sh
# source: groqbash:1146\nlist_files_sorted_by_mtime() {\n  local dir="$1"\n  find "$dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' f; do\n    case "$(uname 2>/dev/null || echo Linux)" in\n      Darwin) mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)" ;;\n      *) mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)" ;;\n    esac\n    printf '%s|%s\n' "$mtime" "$f"\n  done | sort -n\n}
```\n
\n## list_models_cli
\n- **File**: groqbash\n- **Line**: L3544\n- **Section**: misc
\n```sh
# source: groqbash:3544\nlist_models_cli() {\n  # Print MODELS_FILE entries in a provider-agnostic way.\n  # Normalize entries (strip leading "models/") and mark non-text models.\n  if [ ! -s "${MODELS_FILE:-}" ]; then\n    printf 'No models available locally. Consider --refresh-models.\n' >&2\n    return 1\n  fi\n\n  local count=0 model norm\n  while IFS= read -r model || [ -n "$model" ]; do\n    [ -z "$model" ] && continue\n    count=$((count+1))\n    norm="$(printf '%s' "$model" | sed -e 's/^models\///' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')"\n    if is_supported_model "$norm"; then\n      printf '%s\n' "$norm"\n    else\n      printf '%s\t[NOT SUPPORTED: Requires non-text input]\n' "$norm"\n    fi\n    if [ "$count" -ge "$MAX_MODELS" ]; then break; fi\n  done < "$MODELS_FILE"\n  return 0\n}
```\n
\n## load_local_config
\n- **File**: groqbash\n- **Line**: L4049\n- **Section**: misc
\n```sh
# source: groqbash:4049\nload_local_config() {\n  local cfg="${GROQBASH_CONFIG_DIR%/}/config" key val\n  [ -f "$cfg" ] || return 0\n  while IFS= read -r line || [ -n "$line" ]; do\n    case "$line" in ''|\#*) continue ;; esac\n    key="${line%%=*}"\n    val="${line#*=}"\n    case "$key" in\n      MODEL) [ -n "$val" ] && MODEL="$val" ;;\n      TEMPERATURE|TURE) [ -n "$val" ] && TURE="$val" ;;\n      MAX_TOKENS) [ -n "$val" ] && MAX_TOKENS="$val" ;;\n      FORMAT) [ -n "$val" ] && OUTPUT_MODE="$val" ;;\n      THRESHOLD) [ -n "$val" ] && THRESHOLD="$val" ;;\n    esac\n  done < "$cfg"\n}
```\n
\n## load_provider_module
\n- **File**: groqbash\n- **Line**: L1021\n- **Section**: misc
\n```sh
# source: groqbash:1021\nload_provider_module() {\n  local provider="$1"\n\n  # Skip if already loaded for the same provider\n  if [ "${LOADED_PROVIDER_NAME:-}" = "$provider" ] && [ "${PROVIDER_MODULE_LOADED:-0}" -eq 1 ]; then\n    return 0\n  fi\n\n  LOADED_PROVIDER_NAME="$provider"\n  PROVIDER_MODULE_LOADED=0\n  PROVIDER_MODULE_PATH="$PROVIDERS_DIR/${provider}.sh"\n  PROVIDER_DIR="$PROVIDERS_DIR"\n\n  if [ ! -d "$PROVIDER_DIR" ]; then\n    mkdir -p "$PROVIDER_DIR" 2>/dev/null || { log_error "PROVIDER" "cannot create provider directory."; return 1; }\n  fi\n\n  if _is_world_writable "$PROVIDER_DIR"; then\n    log_error "SEC" "provider directory is world-writable."\n    return 1\n  fi\n\n  local current_user owner file_owner perms group_write others_write beforesig aftersig invalid_provider _req\n  current_user="$(id -un 2>/dev/null || printf '')"\n  owner="$(_get_owner "$PROVIDER_DIR")"\n  [ -n "$owner" ] && [ "$owner" != "$current_user" ] && log_warn "SEC" "provider directory owned by $owner"\n\n  if [ ! -f "$PROVIDER_MODULE_PATH" ]; then\n    if [ "$provider" != "groq" ]; then
```\n
\n## load_whitelist
\n- **File**: groqbash\n- **Line**: L4066\n- **Section**: misc
\n```sh
# source: groqbash:4066\nload_whitelist() {\n  ALLOWED_MODELS="${ALLOWED_MODELS:-}"\n  if [ -f "$MODELS_FILE" ] && [ -s "$MODELS_FILE" ]; then\n    # Normalize entries: strip leading "models/" and trim whitespace\n    # Keep one model per line in ALLOWED_MODELS\n    ALLOWED_MODELS="$(awk '{ gsub(/^models\//,""); sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); if (NF) print }' "$MODELS_FILE" 2>/dev/null || true)"\n  fi\n}
```\n
\n## lock_exec
\n- **File**: groqbash\n- **Line**: L527\n- **Section**: misc
\n```sh
# source: groqbash:527\nlock_exec() {\n  local lockfile="$1"\n  local timeout="${2:-10}"\n  shift 2\n  if [ "$1" != "--" ]; then\n    log_error "USAGE" "lock_exec <lockfile> <timeout> -- <cmd> [args...]"\n    return 2\n  fi\n  shift\n\n  mkdir -p "$(dirname "$lockfile")" 2>/dev/null || { log_error "LOCKFAIL" "cannot create lockfile dir: $(dirname "$lockfile")"; return 2; }\n\n  if command -v flock >/dev/null 2>&1; then\n    # Use a dedicated file descriptor to ensure lock is released when subshell exits\n    (\n      # Open FD 9 for the lockfile inside subshell to avoid leaking FDs to caller\n      exec 9>"$lockfile"\n      if ! flock -x -w "$timeout" 9; then\n        printf '%sERROR: LOCKTIMEOUT: could not acquire lock on %s within %s seconds\n' "$(log_prefix)" "$lockfile" "$timeout" >&2\n        exit 124\n      fi\n      # Execute the requested command in this subshell under lock\n      set -e\n      "$@"\n    )\n    rc=$?\n    return $rc\n  fi\n
```\n
\n## log_error
\n- **File**: groqbash\n- **Line**: L437\n- **Section**: misc
\n```sh
# source: groqbash:437\nlog_error() {\n  local code="${1:-ERROR}" msg="${2:-}"\n  printf '%sERROR: %s: %s\n' "$(log_prefix)" "$code" "$msg" >&2\n  if [ -n "$GROQBASH_LOG" ]; then printf '%s ERROR %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$msg" >>"$GROQBASH_LOG" 2>/dev/null || true; fi\n}
```\n
\n## log_info
\n- **File**: groqbash\n- **Line**: L423\n- **Section**: misc
\n```sh
# source: groqbash:423\nlog_info() {\n  local code="${1:-INFO}" msg="${2:-}"\n  if [ "${DEBUG:-0}" -eq 1 ]; then\n    printf '%sINFO: %s: %s\n' "$(log_prefix)" "$code" "$msg" >&2\n  fi\n  if [ -n "$GROQBASH_LOG" ]; then printf '%s INFO %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$msg" >>"$GROQBASH_LOG" 2>/dev/null || true; fi\n}
```\n
\n## log_prefix
\n- **File**: groqbash\n- **Line**: L421\n- **Section**: misc
\n```sh
# source: groqbash:421\nlog_prefix() { printf 'groqbash: %s: ' "$SCRIPT_NAME"; }
```\n
\n## log_warn
\n- **File**: groqbash\n- **Line**: L431\n- **Section**: misc
\n```sh
# source: groqbash:431\nlog_warn() {\n  local code="${1:-WARN}" msg="${2:-}"\n  printf '%sWARN: %s: %s\n' "$(log_prefix)" "$code" "$msg" >&2\n  if [ -n "$GROQBASH_LOG" ]; then printf '%s WARN %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$msg" >>"$GROQBASH_LOG" 2>/dev/null || true; fi\n}
```\n
\n## make_tmpdir
\n- **File**: groqbash\n- **Line**: L1530\n- **Section**: misc
\n```sh
# source: groqbash:1530\nmake_tmpdir() {\n  umask 077\n  local tmpd lockfile\n  lockfile="$TMP_LOCK"\n  mkdir -p "$GROQBASH_TMPDIR" 2>/dev/null || return "$GROQBASHERRTMP"\n  lock_exec "$lockfile" "$GROQBASH_LOCK_TIMEOUT_TMP" -- sh -c '\n    set -e\n    base="$1"\n    tmpd="$(mktemp -d -p "$base" groq.XXXX 2>/dev/null || true)"\n    if [ -z "$tmpd" ]; then\n      tmpd="$base/groq.$$.$RANDOM"\n      mkdir -p "$tmpd"\n    fi\n    chmod 700 "$tmpd" 2>/dev/null || true\n    printf "%s" "$tmpd"\n  ' _ "$GROQBASH_TMPDIR"\n  return $?\n}
```\n
\n## manifest_add_part
\n- **File**: groqbash\n- **Line**: L1378\n- **Section**: misc
\n```sh
# source: groqbash:1378\nmanifest_add_part() {\n  local manifest="$1" name="$2" file_path="$3" mime="$4" timeout="${5:-$GROQBASH_LOCK_TIMEOUT_MODELS}"\n  [ -f "$file_path" ] || { log_error "MANIFESTFAIL" "manifest_add_part: file not found: $file_path"; return 1; }\n  mkdir -p "$(dirname "$manifest")" 2>/dev/null || true\n\n  # Ensure a lockfile specific to this manifest (avoid global contention)\n  lockfile="${manifest}.lock"\n\n  # First, stage the part as a base64 file in the manifest directory (atomic in destdir)\n  local destdir part_b64 tmpstamp tmp_part\n  destdir="$(dirname "$manifest")"\n  tmpstamp="$(date +%s)-$$"\n  part_b64="$destdir/parts-$(basename "$file_path").${tmpstamp}.b64"\n  tmp_part="$GROQBASH_TMPDIR/part.tmp.$$"\n\n  # write base64 staging atomically into RUN tmp then move into destdir\n  if ! b64encode < "$file_path" > "$tmp_part"; then\n    rm -f "$tmp_part" 2>/dev/null || true\n    log_error "B64FAIL" "manifest_add_part: b64 encode failed"\n    return 1\n  fi\n  mv -f "$tmp_part" "$part_b64" 2>/dev/null || { rm -f "$tmp_part" 2>/dev/null || true; log_error "MANIFESTFAIL" "cannot move staged part to $part_b64"; return 1; }\n  chmod 600 "$part_b64" 2>/dev/null || true\n\n  # Now update manifest atomically under lock using jq --arg\n  lock_exec "$lockfile" "$timeout" -- sh -c '\n    set -e\n    manifest="$1"\n    part_b64="$2"
```\n
\n## manifest_create
\n- **File**: groqbash\n- **Line**: L1356\n- **Section**: misc
\n```sh
# source: groqbash:1356\nmanifest_create() {\n  local manifest="$1"\n  local timeout="${2:-$GROQBASH_LOCK_TIMEOUT_MODELS}"\n  mkdir -p "$(dirname "$manifest")" 2>/dev/null || { log_error "MANIFESTFAIL" "manifest_create: cannot create dir"; return 1; }\n  lock_exec "${manifest}.lock" "$timeout" -- sh -c '\n   set -e\n   manifest="$1"\n   tmp="$(mktemp -p "$(dirname "$manifest")" manifest.tmp.XXXX)"\n   printf "%s" "{\"parts\":[]}" > "$tmp"\n   # write base64 staging using base64 binary and exported opts\n   if [ -n "${B64_WRAP_OPT:-}" ]; then\n     base64 ${B64_WRAP_OPT} "$tmp" > "${manifest}.b64"\n   else\n     base64 "$tmp" | tr -d "\n" > "${manifest}.b64"\n   fi\n   mv -f "$tmp" "$manifest"\n   chmod 600 "$manifest" 2>/dev/null || true\n ' _ "$manifest"\n\n  return $?\n}
```\n
\n## manifest_read
\n- **File**: groqbash\n- **Line**: L1438\n- **Section**: misc
\n```sh
# source: groqbash:1438\nmanifest_read() {\n  local manifest="$1"\n  if [ -f "$manifest" ]; then\n    cat "$manifest"\n    return 0\n  fi\n  if [ -f "${manifest}.b64" ]; then\n    b64decode < "${manifest}.b64"\n    return $?\n  fi\n  return 1\n}
```\n
\n## perform_request_once
\n- **File**: groqbash\n- **Line**: L3400\n- **Section**: misc
\n```sh
# source: groqbash:3400\nperform_request_once() {\n  local attempt=1 rc\n  while [ "$attempt" -le "$MAX_RETRIES" ]; do\n    if call_api_once; then\n      if [ "${DRY_RUN:-0}" -eq 1 ]; then\n        if [ "${DEBUG:-0}" -eq 1 ]; then\n          log_info "DRYRUN" "DRY-RUN: request simulated successfully. Payload: $PAYLOAD"\n        fi\n        return 0\n      fi\n\n      # reset diagnostica all'inizio della gestione della risposta\n      GROQBASH_EDGE_EMPTY=0\n      GROQBASH_EDGE_REQ_ID=""\n      GROQBASH_EDGE_FINISH_REASON=""\n      GROQBASH_EDGE_COMPLETION_TOKENS=0\n\n      local text api_err\n      text="$(extract_text_from_resp || true)"\n\n      # Esegui il rilevamento dell'edge case qui, sempre, subito dopo l'estrazione\n      detect_empty_edge_case || true\n\n      # Ensure last_api.json exists (fallback if provider didn't write it)\n      ui_last="${GROQBASH_CONFIG_DIR%/}/ui_state/last_api.json"\n      if [ ! -f "$ui_last" ] || [ "$ui_last" -ot "${RESP:-/dev/null}" ]; then\n        # Build fallback api_json from available globals\n        finish_reason="$(jq -r '.choices[0]?.finish_reason // empty' "$RESP" 2>/dev/null || echo "")"\n        req_id="$(jq -r '.x_groq?.id // .id // empty' "$RESP" 2>/dev/null || echo "")"
```\n
\n## provider_api_env_var_name
\n- **File**: groqbash\n- **Line**: L344\n- **Section**: misc
\n```sh
# source: groqbash:344\nprovider_api_env_var_name() {\n  local prov="$1"\n  local prov_upper\n  prov_upper="$(printf '%s' "$prov" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')"\n  printf '%s' "${prov_upper}_API_KEY"\n}
```\n
\n## refresh_models_dispatch
\n- **File**: groqbash\n- **Line**: L3044\n- **Section**: misc
\n```sh
# source: groqbash:3044\nrefresh_models_dispatch() {\n  local destfile="${1:-${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}}"\n  local fn="refresh_models_${PROVIDER}"\n  local rc=0\n\n  if ! type "$fn" >/dev/null 2>&1; then\n    log_error "MODELREFRESH" "Provider '$PROVIDER' does not implement $fn()."\n    return 127\n  fi\n\n  # Try provider-specific refresh; prefer passing destfile but tolerate providers that ignore args\n  if "$fn" "$destfile" 2>/dev/null; then\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      log_info "MODELREFRESH" "Models refreshed for provider $PROVIDER -> $destfile"\n    fi\n    return 0\n  fi\n\n  rc=$?\n  if "$fn" 2>/dev/null; then\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      log_info "MODELREFRESH" "Models refreshed for provider $PROVIDER (no explicit dest)"\n    fi\n    return 0\n  fi\n\n  rc=$?\n  log_error "MODELREFRESH" "refresh_models for provider $PROVIDER failed (rc $rc)."\n  return "$rc"
```\n
\n## refresh_models_groq
\n- **File**: groqbash\n- **Line**: L2813\n- **Section**: misc
\n```sh
# source: groqbash:2813\nrefresh_models_groq() {\n  # Fetch Groq models and write normalized model names to MODELS_FILE.\n  # Prefer .data[].name then .data[].id then top-level array .[].name/.id.\n  if [ -n "${PROVIDER_API_ENV_groq:-}" ] && [ -n "${!PROVIDER_API_ENV_groq:-}" ]; then\n    GROQ_API_KEY="${!PROVIDER_API_ENV_groq}"\n  fi\n  if [ -z "${GROQ_API_KEY:-}" ]; then\n    log_error "APIKEY" "GROQ_API_KEY is required to refresh models."\n    return "$GROQBASHERRNOAPIKEY"\n  fi\n\n  ensure_run_tmpdir || return "$GROQBASHERRTMP"\n  local workdir tmpd out errf api_url tmp_parsed tmp_trim tmpout rc\n  workdir="${RUN_TMPDIR:-}"\n  [ -n "$workdir" ] || return "$GROQBASHERRTMP"\n  tmpd="$(mktemp -d -p "$workdir" groq-models.XXXX)" || return "$GROQBASHERRTMP"\n  out="$tmpd/models.json"\n  errf="$tmpd/curl.err"\n  # Derive models API URL from the canonical provider URL (GROQBASH_PROVIDER_URL).\n  # Do not introduce new env var semantics; attempt to resolve provider URL if needed.\n  resolve_provider_url "${PROVIDER:-}" >/dev/null 2>&1 || true\n  if [ -n "${GROQBASH_PROVIDER_URL:-}" ]; then\n    # Extract origin (scheme + host[:port]) and append canonical models path.\n    origin="$(printf '%s' "$GROQBASH_PROVIDER_URL" | sed -E 's#(https?://[^/]+).*#\1#')"\n    api_url="${origin%/}/openai/v1/models"\n  else\n    # Fallback to embedded groq models endpoint only if provider is groq (preserve prior behavior).\n    if [ "${PROVIDER:-}" = "groq" ]; then\n      # Do not introduce new env var semantics; attempt to resolve provider URL if needed.
```\n
\n## refreshmodelsgroq
\n- **File**: groqbash\n- **Line**: L2951\n- **Section**: misc
\n```sh
# source: groqbash:2951\nrefreshmodelsgroq() { refresh_models_groq "$@"; }
```\n
\n## resolve_model
\n- **File**: groqbash\n- **Line**: L3097\n- **Section**: misc
\n```sh
# source: groqbash:3097\nresolve_model() {\n  # Guard: warn if MODEL is present in environment but not provided via -m/--set-default.\n  # This helps CI/users who export MODEL expecting it to behave like -m.\n  if [ -n "${MODEL:-}" ] && [ "${MODEL_CLI_SET:-0}" -ne 1 ]; then\n    # Only warn when no provider-specific persisted default exists (avoid noisy logs).\n    model_cfg="$(canonical_model_file "${PROVIDER:-groq}")"\n    if [ ! -s "$model_cfg" ]; then\n      log_warn "MODEL" "MODEL is set in environment but not passed with -m/--set-default; use -m for per-run override or --set-default to persist."\n    fi\n  fi\n\n  FINAL_MODEL=""\n\n  # 1) CLI-specified model (highest priority)\n  if [ "${MODEL_CLI_SET:-0}" -eq 1 ] && [ -n "${MODEL:-}" ]; then\n    FINAL_MODEL="$MODEL"\n    return 0\n  fi\n\n  # Determine active provider robustly for provider-specific default lookup:\n  # Precedence: PROVIDER_CLI -> persisted provider file under canonical config dir -> $PROVIDER -> fallback groq\n  if [ -n "${PROVIDER_CLI:-}" ]; then\n    active_provider="${PROVIDER_CLI}"\n  elif [ -f "$(canonical_provider_file)" ] && [ -s "$(canonical_provider_file)" ]; then\n    active_provider="$(sed -n '1p' "$(canonical_provider_file)" 2>/dev/null || true)"\n    active_provider="$(printf '%s' "$active_provider" | awk '{$1=$1;print}')"\n    [ -z "$active_provider" ] && active_provider="${PROVIDER:-groq}"\n  else\n    active_provider="${PROVIDER:-groq}"
```\n
\n## resolve_provider_url
\n- **File**: groqbash\n- **Line**: L301\n- **Section**: misc
\n```sh
# source: groqbash:301\nresolve_provider_url() {\n  local prov="${1:-$PROVIDER}" prov_file prov_val\n  # 1) ENV\n  if [ -n "${GROQBASH_API_URL:-}" ]; then\n    GROQBASH_PROVIDER_URL="${GROQBASH_API_URL}"\n    export GROQBASH_PROVIDER_URL\n    return 0\n  fi\n  if [ -n "${GROQBASH_PROVIDER_URL:-}" ]; then\n    return 0\n  fi\n  # 2) provider-url file\n  prov_file="$(canonical_provider_url_file)"\n  if [ -f "$prov_file" ] && [ -s "$prov_file" ]; then\n    prov_val="$(sed -n '1p' "$prov_file" 2>/dev/null | awk '{$1=$1;print}')"\n    if [ -n "$prov_val" ]; then\n      GROQBASH_PROVIDER_URL="$prov_val"\n      export GROQBASH_PROVIDER_URL\n      return 0\n    fi\n  fi\n  # 3) embedded default for groq only (minimal)\n  if [ "${prov:-}" = "groq" ]; then\n    GROQBASH_PROVIDER_URL="https://api.groq.com/openai/v1/chat/completions"\n    export GROQBASH_PROVIDER_URL\n    return 0\n  fi\n  return 1\n}
```\n
\n## resolve_script_dir
\n- **File**: groqbash\n- **Line**: L64\n- **Section**: misc
\n```sh
# source: groqbash:64\nresolve_script_dir() {\n  local src="$0" rl dir\n  if command -v readlink >/dev/null 2>&1 && [ -L "$src" ]; then\n    rl="$(readlink "$src" 2>/dev/null || true)"\n    [ -n "$rl" ] && case "$rl" in /*) src="$rl" ;; *) src="$(dirname "$src")/$rl" ;; esac\n  fi\n  dir="$(cd "$(dirname "$src")" >/dev/null 2>&1 && pwd || printf '%s' "$(dirname "$src")")"\n  printf '%s' "$dir"\n}
```\n
\n## rotate_history
\n- **File**: groqbash\n- **Line**: L1226\n- **Section**: misc
\n```sh
# source: groqbash:1226\nrotate_history() {\n  local timeout="${1:-$GROQBASH_LOCK_TIMEOUT_HISTORY}"\n  local dir="${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}"\n  local max_files="${GROQBASH_HISTORY_MAX_FILES:-100}"\n  local max_bytes="${GROQBASH_HISTORY_MAX_BYTES:-104857600}"\n  local keep_days="${GROQBASH_HISTORY_KEEP_DAYS:-90}"\n\n  lock_exec "${HISTORY_LOCK}" "$timeout" -- sh -c '\n    set -e\n    dir="$1"\n    max_files="$2"\n    max_bytes="$3"\n    keep_days="$4"\n\n    # Remove files older than keep_days first\n    find "$dir" -type f -mtime +"$keep_days" -print0 | xargs -0 -r rm -f --\n\n    # Compute total bytes and remove oldest until under threshold\n    while :; do\n      total=0\n      # Build list of files with mtime and size\n      files_list="$(mktemp -p "$(dirname "$dir")" groq-rot.XXXX 2>/dev/null || true)"\n      if [ -z "$files_list" ]; then\n        files_list="/tmp/groq-rot.$$"\n      fi\n      : > "$files_list"\n      find "$dir" -type f -print0 2>/dev/null | while IFS= read -r -d "" f; do\n        if [ -f "$f" ]; then\n          # portable size
```\n
\n## save_to_history
\n- **File**: groqbash\n- **Line**: L1304\n- **Section**: misc
\n```sh
# source: groqbash:1304\nsave_to_history() {\n  local content="$1"\n  local filename\n  filename="$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt"\n  mkdir -p "$GROQBASH_HISTORY_DIR" 2>/dev/null || true\n  local tmpf dest lockfile\n  # Create tmp file in history dir to ensure same-filesystem atomic mv\n  tmpf="$(mktemp -p "$GROQBASH_HISTORY_DIR" groq-out.XXXX 2>/dev/null || true)"\n  [ -n "$tmpf" ] || tmpf="$GROQBASH_HISTORY_DIR/.groq-out.$$.$RANDOM"\n  if ! : > "$tmpf" 2>/dev/null; then\n    log_error "HISTORYFAIL" "save_to_history: cannot create tmp file in $GROQBASH_HISTORY_DIR"\n    return "$GROQBASHERRTMP"\n  fi\n  printf '%s\n' "$content" > "$tmpf"\n  dest="$GROQBASH_HISTORY_DIR/$filename"\n  lockfile="$HISTORY_LOCK"\n  lock_exec "$lockfile" "$GROQBASH_LOCK_TIMEOUT_HISTORY" -- sh -c '\n    set -e\n    mv -f -- "$1" "$2"\n    chmod 600 "$2" 2>/dev/null || true\n    \n    # --- Write last_history metadata to ui_state ---\n    if [ -f "$dest" ]; then\n      size_bytes="$(file_size "$dest" 2>/dev/null || echo 0)"\n      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"\n      basename="$(basename "$dest")"\n      history_json="$(jq -c -n --arg path "$dest" --arg base "$basename" --arg ts "$ts" --argjson size "$size_bytes" '{saved:true, path:$path, basename:$base, ts:$ts, size_bytes:$size}')"\n      ui_state_write "last_history.json" "$history_json" || log_warn "UI_STATE" "failed to write last_history.json"\n    else
```\n
\n## session_append
\n- **File**: groqbash\n- **Line**: L1769\n- **Section**: misc
\n```sh
# source: groqbash:1769\nsession_append() {\n  # Usage: session_append <session_id> <role> <content> <meta_json>\n  local sid="$1" role="$2" content="$3" meta_json="$4"\n  # Prefer SESSION_DIR (set during init), then GROQBASH_HISTORY_DIR, then local fallback\n  local base_sessions_dir="${SESSION_DIR:-${GROQBASH_HISTORY_DIR:-./groqbash.d}/sessions}"\n  local session_file="${base_sessions_dir%/}/${sid}.ndjson"\n  local lockfile="${session_file}.lock"\n  local invocation_ts message_id marker normalized rand tmpf found=0 role_norm line timeout\n  local marker_dir created_marker=0 sess_dir tmp_init\n\n  [ -n "$sid" ] || return 1\n  [ -n "$content" ] || content=""\n\n  # Ensure we clean up marker_dir on unexpected exit; normal successful path will disable the trap.\n  trap 'if [ "${created_marker:-0}" -eq 1 ] && [ -n "${marker_dir:-}" ]; then rm -rf -- "$marker_dir" 2>/dev/null || true; fi' RETURN\n\n  invocation_ts="$(session_now_ts)"\n  message_id="$(printf '%s' "$meta_json" | jq -r '.id // empty' 2>/dev/null || true)"\n  if [ -z "$message_id" ]; then\n    normalized="$(printf '%s' "$content" | sed -e 's/\r$//' -e 's/\r\n/\n/g' | awk '{$1=$1; print}')"\n    rand="$(printf '%04x' $((RANDOM & 0xFFFF)))"\n    if command -v sha256sum >/dev/null 2>&1; then\n      message_id="$(printf '%s|%s|%s' "$normalized" "$invocation_ts" "$rand" | sha256sum | cut -c1-16)"\n    elif command -v openssl >/dev/null 2>&1; then\n      message_id="$(printf '%s|%s|%s' "$normalized" "$invocation_ts" "$rand" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)"\n    else\n      message_id="$rand"\n    fi\n  fi
```\n
\n## session_cache_get
\n- **File**: groqbash\n- **Line**: L2009\n- **Section**: misc
\n```sh
# source: groqbash:2009\nsession_cache_get() {\n  local sid="$1" params="$2" out="$3"\n  local key file ts now ttl\n  key="$(session_cache_key "$sid" "$params")" || return 1\n  file="${SESSION_CACHE_DIR%/}/${key}.cache"\n  if [ ! -f "$file" ]; then return 1; fi\n  # First line: expiry epoch; rest: payload\n  read -r ts < "$file" 2>/dev/null || ts=0\n  now="$(date +%s)"\n  if [ "$now" -ge "$ts" ]; then\n    # expired\n    rm -f "$file" 2>/dev/null || true\n    return 1\n  fi\n  # output payload to out\n  if [ -n "$out" ]; then\n    tail -n +2 "$file" > "$out" 2>/dev/null || return 1\n  else\n    tail -n +2 "$file" 2>/dev/null || return 0\n  fi\n  return 0\n}
```\n
\n## session_cache_invalidate
\n- **File**: groqbash\n- **Line**: L2053\n- **Section**: misc
\n```sh
# source: groqbash:2053\nsession_cache_invalidate() {\n  local sid="$1" params="$2" key pattern\n  if [ -z "$sid" ]; then return 1; fi\n  if [ -n "$params" ]; then\n    key="$(session_cache_key "$sid" "$params")" || return 1\n    rm -f "${SESSION_CACHE_DIR%/}/${key}.cache" 2>/dev/null || true\n  else\n    # remove all entries for sid\n    pattern="${SESSION_CACHE_DIR%/}/${sid}|*.cache"\n    # shell globbing safe removal\n    for f in ${pattern}; do\n      [ -e "$f" ] && rm -f -- "$f" 2>/dev/null || true\n    done\n  fi\n  return 0\n}
```\n
\n## session_cache_key
\n- **File**: groqbash\n- **Line**: L2002\n- **Section**: misc
\n```sh
# source: groqbash:2002\nsession_cache_key() {\n  local sid="$1" params="$2"\n  [ -n "$sid" ] || return 1\n  params="${params:-}"\n  printf '%s|%s' "$sid" "$(_session_hash "$params")"\n}
```\n
\n## session_cache_set
\n- **File**: groqbash\n- **Line**: L2032\n- **Section**: misc
\n```sh
# source: groqbash:2032\nsession_cache_set() {\n  local sid="$1" params="$2" ttl="${3:-300}" infile="$4"\n  local key file expiry now\n  key="$(session_cache_key "$sid" "$params")" || return 1\n  file="${SESSION_CACHE_DIR%/}/${key}.cache"\n  now="$(date +%s)"\n  expiry=$((now + (ttl + 0)))\n  # Write atomically\n  {\n    printf '%s\n' "$expiry"\n    if [ -n "$infile" ] && [ -f "$infile" ]; then\n      cat "$infile"\n    else\n      cat -\n    fi\n  } > "${file}.tmp.$$" 2>/dev/null || return 1\n  mv -f "${file}.tmp.$$" "$file" 2>/dev/null || { rm -f "${file}.tmp.$$" 2>/dev/null || true; return 1; }\n  chmod 600 "$file" 2>/dev/null || true\n  return 0\n}
```\n
\n## session_messages_tmp_path
\n- **File**: groqbash\n- **Line**: L1628\n- **Section**: misc
\n```sh
# source: groqbash:1628\nsession_messages_tmp_path() {\n  local sid="$1"\n  ensure_run_tmpdir || return 1\n  printf '%s' "$RUN_TMPDIR/session-${sid}-messages.json"\n}
```\n
\n## session_now_ts
\n- **File**: groqbash\n- **Line**: L1623\n- **Section**: misc
\n```sh
# source: groqbash:1623\nsession_now_ts() {\n  # UTC timestamp, seconds resolution, format YYYY-MM-DDTHH:MM:SSZ\n  date -u +%Y-%m-%dT%H:%M:%SZ\n}
```\n
\n## session_read_window
\n- **File**: groqbash\n- **Line**: L1642\n- **Section**: misc
\n```sh
# source: groqbash:1642\nsession_read_window() {\n  # Usage: session_read_window <session_id> <N> <out_file>\n  local sid="$1" n="${2:-10}" out="$3"\n  local history_dir="${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}"\n  local session_file="$history_dir/sessions/${sid}.ndjson"\n  local tmpdir="${RUN_TMPDIR:-${GROQBASH_TMPDIR:-$PWD/groqbash.d/tmp}}"\n  local tmpf out_tmp line role content role_norm role_json content_json\n\n  [ -n "$sid" ] || return 1\n  [ -n "$out" ] || return 1\n\n  mkdir -p "${history_dir%/}/sessions" 2>/dev/null || true\n  chmod 700 "${history_dir%/}/sessions" 2>/dev/null || true\n\n  if ! printf '%s' "$n" | grep -qE '^[0-9]+$'; then n=10; fi\n  if [ "$n" -le 0 ]; then n=10; fi\n\n  # Ensure tmpdir exists and is writable (must be inside groqbash.d/)\n  mkdir -p "${tmpdir%/}" 2>/dev/null || true\n  chmod 700 "${tmpdir%/}" 2>/dev/null || true\n  if ! : > "${tmpdir%/}/.groqbash_tmp_check" 2>/dev/null; then\n    if [ "${DEBUG:-0}" -eq 1 ]; then\n      printf 'DEBUG: session_read_window: tmpdir not writable: %s\n' "$tmpdir" >&2\n    fi\n    return 1\n  else\n    rm -f "${tmpdir%/}/.groqbash_tmp_check" 2>/dev/null || true\n  fi\n
```\n
\n## session_sanitize_cmd
\n- **File**: groqbash\n- **Line**: L1634\n- **Section**: misc
\n```sh
# source: groqbash:1634\nsession_sanitize_cmd() {\n  local cmd="$1"\n  # Remove env-like KEY=VAL, redact tokens/keys, truncate to 256 chars\n  local sanitized\n  sanitized="$(printf '%s' "$cmd" | sed -E 's/[A-Za-z0-9_]+=([^[:space:]]+)//g' | sed -E 's/(token|key|secret)[^[:space:]]*/[REDACTED]/Ig' )"\n  printf '%s' "$(printf '%s' "$sanitized" | cut -c1-256)"\n}
```\n
\n## session_validate_id
\n- **File**: groqbash\n- **Line**: L1617\n- **Section**: misc
\n```sh
# source: groqbash:1617\nsession_validate_id() {\n  local id="$1"\n  if [ -z "$id" ]; then return 1; fi\n  if printf '%s' "$id" | grep -qE '^[A-Za-z0-9._-]{1,128}$'; then return 0; else return 1; fi\n}
```\n
\n## show_payload_head
\n- **File**: groqbash\n- **Line**: L581\n- **Section**: misc
\n```sh
# source: groqbash:581\nshow_payload_head() {\n  local path="${1:-$PAYLOAD}" lines="${2:-200}"\n  if [ -z "${path:-}" ]; then\n    printf 'groqbash: ERROR: payload file missing: %s\n' "<unset>" >&2\n    exit "$GROQBASHERRTMP"\n  fi\n  if [ ! -e "$path" ]; then\n    printf 'groqbash: ERROR: payload file missing: %s\n' "$path" >&2\n    exit "$GROQBASHERRTMP"\n  fi\n  if [ ! -s "$path" ]; then\n    printf 'groqbash: INFO: payload exists but is empty: %s\n' "$path" >&2\n    return 0\n  fi\n\n  # Diagnostic output only when DEBUG=1\n  if [ "${DEBUG:-0}" -eq 1 ]; then\n    printf 'groqbash: INFO: payload path: %s\n' "$path" >&2\n    printf 'groqbash: INFO: payload (head %d lines):\n' "$lines" >&2\n    if printf '%s' "$path" | grep -qE '\.b64$'; then\n      b64decode < "$path" 2>/dev/null | head -n "$lines" >&2 || true\n    else\n      head -n "$lines" "$path" 2>/dev/null >&2 || true\n    fi\n  fi\n\n  return 0\n}
```\n
\n## stage_b64
\n- **File**: groqbash\n- **Line**: L452\n- **Section**: misc
\n```sh
# source: groqbash:452\nstage_b64() {\n  # Dual-mode stage_b64:\n  # - If called with two args: stage_b64 /path/to/src /path/to/dst.b64\n  # - If called with one arg: stage_b64 /path/to/dst.b64  (reads stdin)\n  local src dst max_bytes tmp_local tmp_b64 workdir size b64_opts\n  if [ "$#" -eq 2 ]; then\n    src="$1"; dst="$2"\n  elif [ "$#" -eq 1 ]; then\n    dst="$1"\n    src=""\n  else\n    log_error "STAGE" "stage_b64 usage: stage_b64 [src] dst"\n    return 1\n  fi\n\n  max_bytes="${MAX_STAGE_BYTES:-10485760}" # default 10MB\n  [ -n "$dst" ] || return 1\n  workdir="$(dirname "$dst")"\n  mkdir -p "$workdir" 2>/dev/null || { log_error "STAGE" "cannot create workdir $workdir"; return 1; }\n\n  # If src provided, validate it; else read stdin into tmp_local\n  if [ -n "$src" ]; then\n    if [ ! -f "$src" ] || [ ! -s "$src" ]; then\n      log_error "STAGE" "stage_b64: source payload missing or empty: $src"\n      return 1\n    fi\n    tmp_local="$src"\n    tmp_local_is_temp=0\n  else
```\n
\n## tac_fallback
\n- **File**: groqbash\n- **Line**: L1161\n- **Section**: misc
\n```sh
# source: groqbash:1161\ntac_fallback() {\n  local f="$1"\n  if command -v tac >/dev/null 2>&1; then\n    tac "$f"\n    return $?\n  fi\n  # awk-based fallback: print file in reverse\n  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' "$f"\n  return 0\n}
```\n
\n## trim
\n- **File**: groqbash\n- **Line**: L3522\n- **Section**: misc
\n```sh
# source: groqbash:3522\ntrim() { printf '%s' "$1" | awk '{$1=$1; print}'; }
```\n
\n## ui_state_write
\n- **File**: groqbash\n- **Line**: L899\n- **Section**: misc
\n```sh
# source: groqbash:899\nui_state_write() {\n  # Write UI state JSON atomically.\n  # Usage: ui_state_write filename content_string\n  local name="$1"; local content="$2"\n  local dir target\n\n  if [ -n "${GROQBASH_CONFIG_DIR:-}" ]; then\n    dir="${GROQBASH_CONFIG_DIR%/}/ui_state"\n  else\n    dir="${RUN_TMPDIR%/}/ui_state"\n  fi\n\n  if [ -z "${name:-}" ]; then\n    log_error "UI_STATE" "ui_state_write requires a filename"\n    return 1\n  fi\n\n  mkdir -p "$dir" 2>/dev/null || { log_warn "UI_STATE" "failed to create ui_state dir: $dir"; return 1; }\n  chmod 700 "$dir" 2>/dev/null || true\n  target="$dir/$name"\n\n  # Use atomic_write helper (timeout optional) to write content\n  printf '%s' "$content" | atomic_write "$target" 10 || { log_warn "UI_STATE" "atomic write failed for $target"; return 1; }\n  chmod 600 "$target" 2>/dev/null || true\n  if [ "${DEBUG:-0}" -eq 1 ]; then\n    log_info "UI_STATE" "wrote $target (size $(wc -c < "$target" 2>/dev/null)B)"\n  fi\n  return 0\n}
```\n
\n## validate_model_core
\n- **File**: groqbash\n- **Line**: L3567\n- **Section**: misc
\n```sh
# source: groqbash:3567\nvalidate_model_core() {\n  # Validate a model name against local MODELS_FILE (if present) and textual support.\n  # Accepts exact matches or matches after stripping common provider prefixes like "models/".\n  local model="$1" norm_model file_match\n  [ -n "$model" ] || { printf 'groqbash: ERROR: validate_model_core: model required\n' >&2; return 1; }\n\n  # Normalize incoming model for comparison: strip leading "models/" and surrounding whitespace\n  norm_model="$(printf '%s' "$model" | sed -e 's#^models/##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')"\n\n  # If MODELS_FILE exists and non-empty, require presence (allow either raw or prefixed forms)\n  if [ -f "${MODELS_FILE:-}" ] && [ -s "${MODELS_FILE:-}" ]; then\n    # Check exact match first (file may contain provider-specific forms)\n    if grep -x -F -q "$model" "$MODELS_FILE" 2>/dev/null; then\n      file_match=1\n    else\n      # Check normalized match (strip leading models/ in file entries and compare)\n      if awk '{gsub(/^models\//,""); print}' "$MODELS_FILE" | grep -x -F -q "$norm_model" 2>/dev/null; then\n        file_match=1\n      else\n        file_match=0\n      fi\n    fi\n\n    if [ "$file_match" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model "%s" is not present in %s\n' "$model" "$MODELS_FILE" >&2\n      return 1\n    fi\n  fi\n
```\n
\n## validate_model_dispatch
\n- **File**: groqbash\n- **Line**: L3075\n- **Section**: misc
\n```sh
# source: groqbash:3075\nvalidate_model_dispatch() {\n  local model="$1"\n  local fn="validate_model_${PROVIDER}"\n  if type "$fn" >/dev/null 2>&1; then\n    "$fn" "$model"\n    return $?\n  fi\n  # Default permissive behavior if provider does not implement validation\n  return 0\n}
```\n
\n## validate_model_groq
\n- **File**: groqbash\n- **Line**: L2958\n- **Section**: misc
\n```sh
# source: groqbash:2958\nvalidate_model_groq() {\n  # Provider-specific validation for Groq models.\n  # Accepts either exact matches as stored in MODELS_FILE or normalized names\n  # (stripping common prefixes like "models/" or "groq:"), and enforces textual support.\n  local model="$1" norm_model file_match\n  [ -n "$model" ] || { printf 'groqbash: ERROR: validate_model_groq: model required\n' >&2; return 1; }\n\n  # Normalize incoming model for comparison: strip leading "models/" and "groq:" and trim\n  norm_model="$(printf '%s' "$model" | sed -e 's#^models/##' -e 's#^groq[:/ -]*##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')"\n\n  # If MODELS_FILE exists and non-empty, require presence (allow either raw or normalized forms)\n  if [ -f "${MODELS_FILE:-}" ] && [ -s "${MODELS_FILE:-}" ]; then\n    # Exact match first (file may contain provider-specific forms)\n    if grep -x -F -q "$model" "$MODELS_FILE" 2>/dev/null; then\n      file_match=1\n    else\n      # Compare against normalized entries (strip common prefixes in file)\n      if awk '{g=$0; sub(/^models\//,"",g); sub(/^groq[:\/ -]*/,"",g); print g}' "$MODELS_FILE" | grep -x -F -q "$norm_model" 2>/dev/null; then\n        file_match=1\n      else\n        file_match=0\n      fi\n    fi\n\n    if [ "$file_match" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model "%s" is not present in %s\n' "$model" "$MODELS_FILE" >&2\n      return 1\n    fi\n  fi
```\n
\n## validate_provider_interface
\n- **File**: groqbash\n- **Line**: L4267\n- **Section**: misc
\n```sh
# source: groqbash:4267\nvalidate_provider_interface() {\n  local p="$1"\n  local missing=0\n  local required=( "buildpayload_${p}" "call_api_${p}" )\n  local optional=( "call_api_streaming_${p}" "refresh_models_${p}" "validate_model_${p}" "auto_select_model_${p}" )\n  local f\n\n  for f in "${required[@]}"; do\n    if ! type "$f" >/dev/null 2>&1; then\n      log_error "PROVIDER" "Provider '$p' module does not define required function $f()."\n      missing=1\n    fi\n  done\n\n  for f in "${optional[@]}"; do\n    if ! type "$f" >/dev/null 2>&1; then\n      if [ "${DEBUG:-0}" -eq 1 ]; then\n        log_info "PROVIDER" "Provider '$p' missing optional function $f()"\n      fi\n    fi\n  done\n\n  return $missing\n}
```\n
\n## validatemodelgroq
\n- **File**: groqbash\n- **Line**: L2997\n- **Section**: misc
\n```sh
# source: groqbash:2997\nvalidatemodelgroq() { validate_model_groq "$@"; }
```\n
\n## write_provider_url_if_missing
\n- **File**: groqbash\n- **Line**: L269\n- **Section**: misc
\n```sh
# source: groqbash:269\nwrite_provider_url_if_missing() {\n  local prov="$1" url="$2" file dir tmp\n  [ -z "$prov" ] && return 1\n  [ -z "$url" ] && return 1\n  file="$(canonical_provider_url_file)"\n  dir="$(dirname "$file")"\n  mkdir -p "$dir" 2>/dev/null || return 1\n  # If file already exists and non-empty, do nothing\n  if [ -f "$file" ] && [ -s "$file" ]; then\n    return 0\n  fi\n  # Write atomically into RUN_TMPDIR if available, else directly (best-effort)\n  if [ -n "${RUN_TMPDIR:-}" ] && [ -d "${RUN_TMPDIR:-}" ]; then\n    tmp="$(mktemp -p "${RUN_TMPDIR}" provider-url.XXXX 2>/dev/null || true)"\n  else\n    tmp="$(mktemp 2>/dev/null || true)"\n  fi\n  if [ -n "$tmp" ]; then\n    printf '%s\n' "$url" > "$tmp"\n    mv -f "$tmp" "$file" 2>/dev/null || cp -f "$tmp" "$file" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || true; return 1; }\n    chmod 600 "$file" 2>/dev/null || true\n    return 0\n  else\n    # fallback: write directly\n    printf '%s\n' "$url" > "$file" 2>/dev/null || return 1\n    chmod 600 "$file" 2>/dev/null || true\n    return 0\n  fi\n}
```\n
