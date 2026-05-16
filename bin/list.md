## GroqBash - Inventario Funzioni

Diviso per macro sezioni, poi in ordine alfabetico.

- **[PRECORE_BOOT](#section-precore_boot)**
```sh
_detect_base64_opts
_file_mtime
_mktemp_in_dir                            atomic_write
b64_atomic_read
b64_atomic_write                          b64decode
b64encode                                 canonical_config_dir
canonical_model_file                      canonical_provider_file
canonical_provider_url_file
cleanup_run_tmp_on_exit
cleanup_tmp
dbg
enforce_network_policy
ensure_api_key_for_provider
ensure_config_dir
ensure_run_tmpdir
extract_text_from_resp
file_size
is_truthy
is_valid_json_file
is_valid_json_string
jq_safe
list_files_sorted_by_mtime
load_provider_module
lock_exec
log_error
log_info
log_prefix
log_warn
provider_api_env_var_name
resolve_provider_url
resolve_script_dir
show_payload_head
stage_b64
tac_fallback
ui_state_write
write_provider_url_if_missing
```
- **[PRECORE_RUN](#section-precore_run)**
```sh
_get_file_signature
_get_owner
_get_perm_string
_is_world_writable
_normalize_bool_env
_session_hash
_tmpf
getfile_signature
make_tmpdir
manifest_add_part
manifest_create
manifest_read
rotate_history
save_to_history
session_append
session_cache_get
session_cache_invalidate
session_cache_key
session_cache_set
session_messages_tmp_path
session_now_ts
session_read_window
session_sanitize_cmd
session_validate_id
```
- **[PROVIDER](#section-provider)**
```sh
_cleanup_local_tmp
auto_select_model_groq
autoselectmodelgroq
buildpayload_groq
buildpayloadgroq
call_api_groq
call_api_streaming_groq
call_api_streaming_groq_legacy
refresh_models_groq
refreshmodelsgroq
validate_model_groq
validatemodelgroq
```
- **[CORE_SETUP](#section-core_setup)**
```sh
ARGS
auto_select_model_dispatch
build_payload_from_vars
call_api_once
call_api_streaming
call_provider
collect_input_from_files
detect_empty_edge_case
expand_args_to_content
extract_api_error
FILE_INPUTS
file_readable
finalize_and_output
is_number
is_supported_model
is_tty_out
list_models_cli
load_local_config
load_whitelist
perform_request_once
refresh_models_dispatch
resolve_model
trim
validate_model_core
validate_model_dispatch
```
- **[CORE_PROVIDER](#section-core_provider)**
```sh
assemble_content
validate_provider_interface
```

---

### SECTION: PRECORE_BOOT

---

**name**: "_detect_base64_opts"  

**file**: "groqbash"  

**line_range**: "L1116"  

**body_snippet**: 
```sh
# source: groqbash:1116\n_detect_base64_opts() {\n  # Default conservative options\n  B64_WRAP_OPT=\"\"\n  B64_DECODE_OPT=\"-d\"\n\n  # Detect encode option that prevents line wrapping (GNU coreutils)\n  if printf '' | base64 -w0 >/dev/null 2>&1; then\n    B64_WRAP_OPT=\"-w0\"\n  else\n    B64_WRAP_OPT=\"\"\n  fi\n\n  # Detect decode option -d vs -D\n  if printf 'dGVzdA==' | base64 -d 2>/dev/null | grep -q 'test'; then\n    B64_DECODE_OPT=\"-d\"\n  elif printf 'dGVzdA==' | base64 -D 2>/dev/null | grep -q 'test'; then\n    B64_DECODE_OPT=\"-D\"\n  else\n    B64_DECODE_OPT=\"-d\"\n  fi\n\n  export B64_WRAP_OPT B64_DECODE_OPT\n}
```

**line_start**: 1116  

**body_full**:
```sh
# source: groqbash:1116\n_detect_base64_opts() {\n  # Default conservative options\n  B64_WRAP_OPT=\"\"\n  B64_DECODE_OPT=\"-d\"\n\n  # Detect encode option that prevents line wrapping (GNU coreutils)\n  if printf '' | base64 -w0 >/dev/null 2>&1; then\n    B64_WRAP_OPT=\"-w0\"\n  else\n    B64_WRAP_OPT=\"\"\n  fi\n\n  # Detect decode option -d vs -D\n  if printf 'dGVzdA==' | base64 -d 2>/dev/null | grep -q 'test'; then\n    B64_DECODE_OPT=\"-d\"\n  elif printf 'dGVzdA==' | base64 -D 2>/dev/null | grep -q 'test'; then\n    B64_DECODE_OPT=\"-D\"\n  else\n    B64_DECODE_OPT=\"-d\"\n  fi\n\n  export B64_WRAP_OPT B64_DECODE_OPT\n}"
```

---

**name**: "_file_mtime"  

**file**: "groqbash"  

**line_range**: "L1176"  

**body_snippet**: 
```sh
# source: groqbash:1176\n_file_mtime() {\n  local f=\"$1\"\n  if [ ! -e \"$f\" ]; then printf '0'; return 0; fi\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) stat -f %m \"$f\" 2>/dev/null || printf '0' ;;\n    *) stat -c %Y \"$f\" 2>/dev/null || printf '0' ;;\n  esac\n}
```

**line_start**: 1176  

**body_full**:
```sh
# source: groqbash:1176\n_file_mtime() {\n  local f=\"$1\"\n  if [ ! -e \"$f\" ]; then printf '0'; return 0; fi\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) stat -f %m \"$f\" 2>/dev/null || printf '0' ;;\n    *) stat -c %Y \"$f\" 2>/dev/null || printf '0' ;;\n  esac\n}"
```

---

**name**: "_mktemp_in_dir"  

**file**: "groqbash"  

**line_range**: "L564"  

**body_snippet**: 
```sh
# source: groqbash:564\n_mktemp_in_dir() {\n  local base=\"${1:-}\" prefix=\"${2:-groq}\" tmp\n  if [ -z \"$base\" ]; then\n    log_error \"TMP\" \"_mktemp_in_dir: base dir required\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  # Delegate to _tmpf which already enforces umask/perms and returns a path\n  tmp=\"$(_tmpf file \"$base\" \"$prefix\" 2>/dev/null || true)\"\n  if [ -z \"$tmp\" ]; then\n    log_error \"TMP\" \"_mktemp_in_dir: failed to create temp in $base\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  printf '%s' \"$tmp\"\n  return 0\n}
```

**line_start**: 564  

**body_full**:
```sh
# source: groqbash:564\n_mktemp_in_dir() {\n  local base=\"${1:-}\" prefix=\"${2:-groq}\" tmp\n  if [ -z \"$base\" ]; then\n    log_error \"TMP\" \"_mktemp_in_dir: base dir required\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  # Delegate to _tmpf which already enforces umask/perms and returns a path\n  tmp=\"$(_tmpf file \"$base\" \"$prefix\" 2>/dev/null || true)\"\n  if [ -z \"$tmp\" ]; then\n    log_error \"TMP\" \"_mktemp_in_dir: failed to create temp in $base\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  printf '%s' \"$tmp\"\n  return 0\n}"
```

---

**name**: "atomic_write"  

**file**: "groqbash"  

**line_range**: "L612"  

**body_snippet**: 
```sh
# source: groqbash:612\natomic_write() {\n  # Atomic write with optional lock support.\n  # Usage: atomic_write /path/to/target [timeout_seconds]\n  local dest=\"$1\"\n  local timeout=\"${2:-10}\"\n  [ -n \"$dest\" ] || return \"$GROQBASHERRTMP\"\n  local destdir tmp lockfile rc\n\n  destdir=\"$(dirname -- \"$dest\")\"\n  mkdir -p \"$destdir\" 2>/dev/null || { log_error \"ATOMICFAIL\" \"cannot create dir $destdir\"; return \"$GROQBASHERRTMP\"; }\n  lockfile=\"${destdir}/.groqbash.lock\"\n\n  tmp=\"$(mktemp -p \"$destdir\" .groq-atomic.XXXXXX 2>/dev/null || true)\"\n  [ -n \"$tmp\" ] || tmp=\"$destdir/.groq-atomic.$$.$RANDOM\"\n\n  if ! cat - > \"$tmp\"; then\n    rm -f -- \"$tmp\" 2>/dev/null || true\n    log_error \"ATOMICFAIL\" \"writing to temp failed\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  chmod 600 \"$tmp\" 2>/dev/null || true\n\n  # If lock_exec available, use it to perform the mv under lock; otherwise mv directly\n  if type lock_exec >/dev/null 2>&1; then\n    lock_exec \"$lockfile\" \"$timeout\" -- sh -c '\n      set -e\n      mv -f -- \"$1\" \"$2\"\n      chmod 600 \"$2\" 2>/dev/null || true\n    ' _ \"$tmp\" \"$dest\" || { rc=$?; rm -f -- \"$tmp\" 2>/dev/null || true; return \"$rc\"; }\n  else\n    if mv -f -- \"$tmp\" \"$dest\" 2>/dev/null; then\n      chmod 600 \"$dest\" 2>/dev/null || true\n    else\n      rc=$?\n      rm -f -- \"$tmp\" 2>/dev/null || true\n      log_error \"ATOMICFAIL\" \"mv failed with rc $rc\"\n      return \"$rc\"\n    fi\n  fi\n\n  return 0\n}
```

**line_start**: 612  

**body_full**:
```sh
# source: groqbash:612\natomic_write() {\n  # Atomic write with optional lock support.\n  # Usage: atomic_write /path/to/target [timeout_seconds]\n  local dest=\"$1\"\n  local timeout=\"${2:-10}\"\n  [ -n \"$dest\" ] || return \"$GROQBASHERRTMP\"\n  local destdir tmp lockfile rc\n\n  destdir=\"$(dirname -- \"$dest\")\"\n  mkdir -p \"$destdir\" 2>/dev/null || { log_error \"ATOMICFAIL\" \"cannot create dir $destdir\"; return \"$GROQBASHERRTMP\"; }\n  lockfile=\"${destdir}/.groqbash.lock\"\n\n  tmp=\"$(mktemp -p \"$destdir\" .groq-atomic.XXXXXX 2>/dev/null || true)\"\n  [ -n \"$tmp\" ] || tmp=\"$destdir/.groq-atomic.$$.$RANDOM\"\n\n  if ! cat - > \"$tmp\"; then\n    rm -f -- \"$tmp\" 2>/dev/null || true\n    log_error \"ATOMICFAIL\" \"writing to temp failed\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  chmod 600 \"$tmp\" 2>/dev/null || true\n\n  # If lock_exec available, use it to perform the mv under lock; otherwise mv directly\n  if type lock_exec >/dev/null 2>&1; then\n    lock_exec \"$lockfile\" \"$timeout\" -- sh -c '\n      set -e\n      mv -f -- \"$1\" \"$2\"\n      chmod 600 \"$2\" 2>/dev/null || true\n    ' _ \"$tmp\" \"$dest\" || { rc=$?; rm -f -- \"$tmp\" 2>/dev/null || true; return \"$rc\"; }\n  else\n    if mv -f -- \"$tmp\" \"$dest\" 2>/dev/null; then\n      chmod 600 \"$dest\" 2>/dev/null || true\n    else\n      rc=$?\n      rm -f -- \"$tmp\" 2>/dev/null || true\n      log_error \"ATOMICFAIL\" \"mv failed with rc $rc\"\n      return \"$rc\"\n    fi\n  fi\n\n  return 0\n}"
```

---

**name**: "b64_atomic_read"  

**file**: "groqbash"  

**line_range**: "L888"  

**body_snippet**: 
```sh
# source: groqbash:888\nb64_atomic_read() {\n  local src=\"$1\"\n  [ -f \"$src\" ] || return 1\n  b64decode < \"$src\"\n  return $?\n}
```

**line_start**: 888  

**body_full**:
```sh
# source: groqbash:888\nb64_atomic_read() {\n  local src=\"$1\"\n  [ -f \"$src\" ] || return 1\n  b64decode < \"$src\"\n  return $?\n}"
```

---

**name**: "b64_atomic_write"  

**file**: "groqbash"  

**line_range**: "L862"  

**body_snippet**: 
```sh
# source: groqbash:862\nb64_atomic_write() {\n  local dest=\"$1\"\n  local timeout=\"${2:-10}\"\n  shift 2 || true\n  [ -n \"$dest\" ] || { log_error \"B64FAIL\" \"b64_atomic_write: dest required\"; return \"$GROQBASHERRTMP\"; }\n  local destdir tmp lockfile\n  destdir=\"$(dirname -- \"$dest\")\"\n  mkdir -p \"$destdir\" 2>/dev/null || { log_error \"B64FAIL\" \"cannot create dir $destdir\"; return \"$GROQBASHERRTMP\"; }\n  # Use a lock specific to the destination directory to avoid global contention\n  lockfile=\"${destdir%/}/.groqbash.lock\"\n  tmp=\"$(mktemp -p \"$destdir\" .groq-b64.XXXXXX 2>/dev/null || true)\"\n  [ -n \"$tmp\" ] || tmp=\"$destdir/.groq-b64.$$.$RANDOM\"\n  if ! b64encode > \"$tmp\"; then\n    rm -f -- \"$tmp\" 2>/dev/null || true\n    log_error \"B64FAIL\" \"base64 encoding failed\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  chmod 600 \"$tmp\" 2>/dev/null || true\n  lock_exec \"$lockfile\" \"$timeout\" -- sh -c '\n    set -e\n    mv -f -- \"$1\" \"$2\"\n    chmod 600 \"$2\" 2>/dev/null || true\n  ' _ \"$tmp\" \"$dest\" || { rc=$?; rm -f -- \"$tmp\" 2>/dev/null || true; return \"$rc\"; }\n  return 0\n}
```

**line_start**: 862  

**body_full**:
```sh
# source: groqbash:862\nb64_atomic_write() {\n  local dest=\"$1\"\n  local timeout=\"${2:-10}\"\n  shift 2 || true\n  [ -n \"$dest\" ] || { log_error \"B64FAIL\" \"b64_atomic_write: dest required\"; return \"$GROQBASHERRTMP\"; }\n  local destdir tmp lockfile\n  destdir=\"$(dirname -- \"$dest\")\"\n  mkdir -p \"$destdir\" 2>/dev/null || { log_error \"B64FAIL\" \"cannot create dir $destdir\"; return \"$GROQBASHERRTMP\"; }\n  # Use a lock specific to the destination directory to avoid global contention\n  lockfile=\"${destdir%/}/.groqbash.lock\"\n  tmp=\"$(mktemp -p \"$destdir\" .groq-b64.XXXXXX 2>/dev/null || true)\"\n  [ -n \"$tmp\" ] || tmp=\"$destdir/.groq-b64.$$.$RANDOM\"\n  if ! b64encode > \"$tmp\"; then\n    rm -f -- \"$tmp\" 2>/dev/null || true\n    log_error \"B64FAIL\" \"base64 encoding failed\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  chmod 600 \"$tmp\" 2>/dev/null || true\n  lock_exec \"$lockfile\" \"$timeout\" -- sh -c '\n    set -e\n    mv -f -- \"$1\" \"$2\"\n    chmod 600 \"$2\" 2>/dev/null || true\n  ' _ \"$tmp\" \"$dest\" || { rc=$?; rm -f -- \"$tmp\" 2>/dev/null || true; return \"$rc\"; }\n  return 0\n}"
```

---

**name**: "b64decode"  

**file**: "groqbash"  

**line_range**: "L371"  

**body_snippet**: 
```sh
# source: groqbash:371\nb64decode() {\n  # Use base64 with decode option if set; fall back to -d explicitly\n  if [ -n \"${B64_DECODE_OPT:-}\" ]; then\n    base64 ${B64_DECODE_OPT}\n  else\n    base64 -d\n  fi\n}
```

**line_start**: 371  

**body_full**:
```sh
# source: groqbash:371\nb64decode() {\n  # Use base64 with decode option if set; fall back to -d explicitly\n  if [ -n \"${B64_DECODE_OPT:-}\" ]; then\n    base64 ${B64_DECODE_OPT}\n  else\n    base64 -d\n  fi\n}"
```

---

**name**: "b64encode"  

**file**: "groqbash"  

**line_range**: "L362"  

**body_snippet**: 
```sh
# source: groqbash:362\nb64encode() {\n  # Use base64 with wrap option if available; ensure single-line output\n  if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n    base64 ${B64_WRAP_OPT}\n  else\n    base64 | tr -d '\\n'\n  fi\n}
```

**line_start**: 362  

**body_full**:
```sh
# source: groqbash:362\nb64encode() {\n  # Use base64 with wrap option if available; ensure single-line output\n  if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n    base64 ${B64_WRAP_OPT}\n  else\n    base64 | tr -d '\\n'\n  fi\n}"
```

---

**name**: "canonical_config_dir"  

**file**: "groqbash"  

**line_range**: "L74"  

**body_snippet**: 
```sh
# source: groqbash:74\ncanonical_config_dir() {\n  printf '%s' \"${GROQBASH_CONFIG_DIR%/}\"\n}
```

**line_start**: 74  

**body_full**:
```sh
# source: groqbash:74\ncanonical_config_dir() {\n  printf '%s' \"${GROQBASH_CONFIG_DIR%/}\"\n}"
```

---

**name**: "canonical_model_file"  

**file**: "groqbash"  

**line_range**: "L84"  

**body_snippet**: 
```sh
# source: groqbash:84\ncanonical_model_file() {\n  local prov=\"${1:-}\"\n  printf '%s\\n' \"$(canonical_config_dir)/model.${prov}\"\n}
```

**line_start**: 84  

**body_full**:
```sh
# source: groqbash:84\ncanonical_model_file() {\n  local prov=\"${1:-}\"\n  printf '%s\\n' \"$(canonical_config_dir)/model.${prov}\"\n}"
```

---

**name**: "canonical_provider_file"  

**file**: "groqbash"  

**line_range**: "L79"  

**body_snippet**: 
```sh
# source: groqbash:79\ncanonical_provider_file() {\n  printf '%s\\n' \"$(canonical_config_dir)/provider\"\n}
```

**line_start**: 79  

**body_full**:
```sh
# source: groqbash:79\ncanonical_provider_file() {\n  printf '%s\\n' \"$(canonical_config_dir)/provider\"\n}"
```

---

**name**: "canonical_provider_url_file"  

**file**: "groqbash"  

**line_range**: "L91"  

**body_snippet**: 
```sh
# source: groqbash:91\ncanonical_provider_url_file() {\n  # prefer canonical_config_dir() if present\n  if type canonical_config_dir >/dev/null 2>&1; then\n    cfgdir=\"$(canonical_config_dir)\"\n  else\n    cfgdir=\"${GROQBASH_CONFIG_DIR:-${GROQBASH_DIR%/}/config}\"\n  fi\n  printf '%s' \"${cfgdir%/}/provider-url\"\n}
```

**line_start**: 91  

**body_full**:
```sh
# source: groqbash:91\ncanonical_provider_url_file() {\n  # prefer canonical_config_dir() if present\n  if type canonical_config_dir >/dev/null 2>&1; then\n    cfgdir=\"$(canonical_config_dir)\"\n  else\n    cfgdir=\"${GROQBASH_CONFIG_DIR:-${GROQBASH_DIR%/}/config}\"\n  fi\n  printf '%s' \"${cfgdir%/}/provider-url\"\n}"
```

---

**name**: "cleanup_run_tmp_on_exit"  

**file**: "groqbash"  

**line_range**: "L805"  

**body_snippet**: 
```sh
# source: groqbash:805\n  cleanup_run_tmp_on_exit() {\n    if [ \"${DEBUG_PRESERVE:-0}\" -eq 1 ]; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"TMP\" \"DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR\"\n      fi\n      return 0\n    fi\n    if [ -n \"${RUN_TMPDIR:-}\" ]; then\n      case \"$RUN_TMPDIR\" in\n        \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\")\n          rm -rf -- \"$RUN_TMPDIR\" 2>/dev/null || true\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"Cleaned RUN_TMPDIR: $RUN_TMPDIR\"\n          fi\n          ;;\n        *)\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"RUN_TMPDIR outside GROQBASH_TMPDIR; not removed: $RUN_TMPDIR\"\n          fi\n          ;;\n      esac\n    fi\n  }
```

**line_start**: 805  

**body_full**:
```sh
# source: groqbash:805\n  cleanup_run_tmp_on_exit() {\n    if [ \"${DEBUG_PRESERVE:-0}\" -eq 1 ]; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"TMP\" \"DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR\"\n      fi\n      return 0\n    fi\n    if [ -n \"${RUN_TMPDIR:-}\" ]; then\n      case \"$RUN_TMPDIR\" in\n        \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\")\n          rm -rf -- \"$RUN_TMPDIR\" 2>/dev/null || true\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"Cleaned RUN_TMPDIR: $RUN_TMPDIR\"\n          fi\n          ;;\n        *)\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"RUN_TMPDIR outside GROQBASH_TMPDIR; not removed: $RUN_TMPDIR\"\n          fi\n          ;;\n      esac\n    fi\n  }"
```

---

**name**: "cleanup_tmp"  

**file**: "groqbash"  

**line_range**: "L847"  

**body_snippet**: 
```sh
# source: groqbash:847\ncleanup_tmp() {\n  if [ -n \"${RUN_TMPDIR:-}\" ]; then\n    case \"$RUN_TMPDIR\" in\n      \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\")\n        rm -rf -- \"$RUN_TMPDIR\" 2>/dev/null || true\n        ;;\n      *)\n        ;;\n    esac\n  fi\n}
```

**line_start**: 847  

**body_full**:
```sh
# source: groqbash:847\ncleanup_tmp() {\n  if [ -n \"${RUN_TMPDIR:-}\" ]; then\n    case \"$RUN_TMPDIR\" in\n      \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\")\n        rm -rf -- \"$RUN_TMPDIR\" 2>/dev/null || true\n        ;;\n      *)\n        ;;\n    esac\n  fi\n}"
```

---

**name**: "dbg"  

**file**: "groqbash"  

**line_range**: "L444"  

**body_snippet**: 
```sh
# source: groqbash:444\ndbg() {\n  if [ \"${DEBUG:-0}\" -ne 0 ]; then\n    printf '%s\\n' \"$*\" >&2\n  fi\n}
```

**line_start**: 444  

**body_full**:
```sh
# source: groqbash:444\ndbg() {\n  if [ \"${DEBUG:-0}\" -ne 0 ]; then\n    printf '%s\\n' \"$*\" >&2\n  fi\n}"
```

---

**name**: "enforce_network_policy"  

**file**: "groqbash"  

**line_range**: "L173"  

**body_snippet**: 
```sh
# source: groqbash:173\nenforce_network_policy() {\n  # If DRY_RUN or GROQBASH_SKIP_NETWORK are truthy, disallow network.\n  if is_truthy \"${DRY_RUN:-0}\" || is_truthy \"${GROQBASH_SKIP_NETWORK:-0}\"; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"NETWORK\" \"Network calls disabled by DRY_RUN or GROQBASH_SKIP_NETWORK; skipping HTTP.\"\n    fi\n    return 1\n  fi\n\n  # QUIET does not disable network by itself, but if QUIET is used with a policy variable we enforce it.\n  if is_truthy \"${GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET:-0}\" && is_truthy \"${QUIET:-0}\"; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"NETWORK\" \"Network calls disabled due to QUIET policy.\"\n    fi\n    return 1\n  fi\n\n  return 0\n}
```

**line_start**: 173  

**body_full**:
```sh
# source: groqbash:173\nenforce_network_policy() {\n  # If DRY_RUN or GROQBASH_SKIP_NETWORK are truthy, disallow network.\n  if is_truthy \"${DRY_RUN:-0}\" || is_truthy \"${GROQBASH_SKIP_NETWORK:-0}\"; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"NETWORK\" \"Network calls disabled by DRY_RUN or GROQBASH_SKIP_NETWORK; skipping HTTP.\"\n    fi\n    return 1\n  fi\n\n  # QUIET does not disable network by itself, but if QUIET is used with a policy variable we enforce it.\n  if is_truthy \"${GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET:-0}\" && is_truthy \"${QUIET:-0}\"; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"NETWORK\" \"Network calls disabled due to QUIET policy.\"\n    fi\n    return 1\n  fi\n\n  return 0\n}"
```

---

**name**: "ensure_api_key_for_provider"  

**file**: "groqbash"  

**line_range**: "L108"  

**body_snippet**: 
```sh
# source: groqbash:108\nensure_api_key_for_provider() {\n  local prov=\"$1\"\n  local envvar current_key input_key custom_var custom_env\n  [ -n \"$prov\" ] || return 1\n  envvar=\"$(provider_api_env_var_name \"$prov\")\"\n  custom_var=\"PROVIDER_API_ENV_${prov}\"\n  custom_env=\"${!custom_var:-}\"\n  if [ -n \"$custom_env\" ]; then\n    envvar=\"$custom_env\"\n  fi\n  current_key=\"${!envvar:-}\"\n\n  # If key present, sync groq alias and return\n  if [ -n \"$current_key\" ]; then\n    if [ \"$prov\" = \"groq\" ] && [ \"$envvar\" != \"GROQ_API_KEY\" ]; then\n      export GROQ_API_KEY=\"$current_key\"\n    fi\n    return 0\n  fi\n\n  # Non-interactive: fail fast with clear error (do not prompt)\n  if [ ! -t 0 ]; then\n    printf 'groqbash: ERROR: missing API key for provider %s (env %s) in non-interactive mode\\n' \"$prov\" \"$envvar\" >&2\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  # Interactive prompt (preserve previous behavior)\n  printf 'Enter API key for provider %s (env %s): ' \"$prov\" \"$envvar\" >&2\n  if ! IFS= read -r input_key; then\n    printf '\\ngroqbash: ERROR: no input received. Aborting.\\n' >&2\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  # Normalize input: strip CR/LF, leading \"export \"  
 and VAR=VALUE forms\n  input_key=\"$(printf '%s' \"$input_key\" | tr -d '\\r\\n')\"\n  input_key=\"$(printf '%s' \"$input_key\" | sed -E 's/^[[:space:]]*export[[:space:]]+//I')\"\n  if printf '%s' \"$input_key\" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*='; then\n    input_key=\"$(printf '%s' \"$input_key\" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*=[\\\"\\x27]?([^\\\"\\x27]*).*$/\\1/')\"\n  fi\n\n  if [ -z \"$input_key\" ]; then\n    printf 'groqbash: ERROR: API key required. Aborting.\\n' >&2\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  export \"$envvar\"=\"$input_key\"\n  if [ \"$prov\" = \"groq\" ] && [ \"$envvar\" != \"GROQ_API_KEY\" ]; then\n    export GROQ_API_KEY=\"$input_key\"\n  fi\n\n  printf '\\n--------------------------------------\\n' >&2\n  printf '\\nTo avoid re-entering the key for subsequent invocations, run this in your shell:\\n' >&2\n  printf '\\n export %s=\"%s\"\\n' \"$envvar\" \"$input_key\" >&2\n  printf '\\nYou can add that line to your shell profile (e.g., ~/.bashrc or ~/.profile) to persist it across sessions.\\n' >&2\n  printf '\\n--------------------------------------\\n' >&2\n\n  return 0\n}
```

**line_start**: 108  

**body_full**:
```sh
# source: groqbash:108\nensure_api_key_for_provider() {\n  local prov=\"$1\"\n  local envvar current_key input_key custom_var custom_env\n  [ -n \"$prov\" ] || return 1\n  envvar=\"$(provider_api_env_var_name \"$prov\")\"\n  custom_var=\"PROVIDER_API_ENV_${prov}\"\n  custom_env=\"${!custom_var:-}\"\n  if [ -n \"$custom_env\" ]; then\n    envvar=\"$custom_env\"\n  fi\n  current_key=\"${!envvar:-}\"\n\n  # If key present, sync groq alias and return\n  if [ -n \"$current_key\" ]; then\n    if [ \"$prov\" = \"groq\" ] && [ \"$envvar\" != \"GROQ_API_KEY\" ]; then\n      export GROQ_API_KEY=\"$current_key\"\n    fi\n    return 0\n  fi\n\n  # Non-interactive: fail fast with clear error (do not prompt)\n  if [ ! -t 0 ]; then\n    printf 'groqbash: ERROR: missing API key for provider %s (env %s) in non-interactive mode\\n' \"$prov\" \"$envvar\" >&2\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  # Interactive prompt (preserve previous behavior)\n  printf 'Enter API key for provider %s (env %s): ' \"$prov\" \"$envvar\" >&2\n  if ! IFS= read -r input_key; then\n    printf '\\ngroqbash: ERROR: no input received. Aborting.\\n' >&2\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  # Normalize input: strip CR/LF, leading \"export \"  
 and VAR=VALUE forms\n  input_key=\"$(printf '%s' \"$input_key\" | tr -d '\\r\\n')\"\n  input_key=\"$(printf '%s' \"$input_key\" | sed -E 's/^[[:space:]]*export[[:space:]]+//I')\"\n  if printf '%s' \"$input_key\" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*='; then\n    input_key=\"$(printf '%s' \"$input_key\" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*=[\\\"\\x27]?([^\\\"\\x27]*).*$/\\1/')\"\n  fi\n\n  if [ -z \"$input_key\" ]; then\n    printf 'groqbash: ERROR: API key required. Aborting.\\n' >&2\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  export \"$envvar\"=\"$input_key\"\n  if [ \"$prov\" = \"groq\" ] && [ \"$envvar\" != \"GROQ_API_KEY\" ]; then\n    export GROQ_API_KEY=\"$input_key\"\n  fi\n\n  printf '\\n--------------------------------------\\n' >&2\n  printf '\\nTo avoid re-entering the key for subsequent invocations, run this in your shell:\\n' >&2\n  printf '\\n export %s=\"%s\"\\n' \"$envvar\" \"$input_key\" >&2\n  printf '\\nYou can add that line to your shell profile (e.g., ~/.bashrc or ~/.profile) to persist it across sessions.\\n' >&2\n  printf '\\n--------------------------------------\\n' >&2\n\n  return 0\n}"
```

---

**name**: "ensure_config_dir"  

**file**: "groqbash"  

**line_range**: "L237"  

**body_snippet**: 
```sh
# source: groqbash:237\nensure_config_dir() {\n  # Normalize\n  GROQBASH_CONFIG_DIR=\"${GROQBASH_CONFIG_DIR%/}\"\n  if [ -z \"$GROQBASH_CONFIG_DIR\" ]; then\n    GROQBASH_CONFIG_DIR=\"${GROQBASH_DIR%/}/config\"\n  fi\n\n  # Try to create directory (idempotent)\n  if ! mkdir -p \"${GROQBASH_CONFIG_DIR}\" 2>/dev/null; then\n    log_error \"CONFIG\" \"cannot create config dir: ${GROQBASH_CONFIG_DIR}\"\n    return 1\n  fi\n\n  # Enforce strict perms\n  chmod 700 \"${GROQBASH_CONFIG_DIR}\" 2>/dev/null || true\n\n  # Quick writability check: try to create a temp file inside\n  if ! : > \"${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check\" 2>/dev/null; then\n    log_error \"CONFIG\" \"config dir not writable: ${GROQBASH_CONFIG_DIR}\"\n    return 1\n  else\n    rm -f \"${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check\" 2>/dev/null || true\n  fi\n\n  return 0\n}
```

**line_start**: 237  

**body_full**:
```sh
# source: groqbash:237\nensure_config_dir() {\n  # Normalize\n  GROQBASH_CONFIG_DIR=\"${GROQBASH_CONFIG_DIR%/}\"\n  if [ -z \"$GROQBASH_CONFIG_DIR\" ]; then\n    GROQBASH_CONFIG_DIR=\"${GROQBASH_DIR%/}/config\"\n  fi\n\n  # Try to create directory (idempotent)\n  if ! mkdir -p \"${GROQBASH_CONFIG_DIR}\" 2>/dev/null; then\n    log_error \"CONFIG\" \"cannot create config dir: ${GROQBASH_CONFIG_DIR}\"\n    return 1\n  fi\n\n  # Enforce strict perms\n  chmod 700 \"${GROQBASH_CONFIG_DIR}\" 2>/dev/null || true\n\n  # Quick writability check: try to create a temp file inside\n  if ! : > \"${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check\" 2>/dev/null; then\n    log_error \"CONFIG\" \"config dir not writable: ${GROQBASH_CONFIG_DIR}\"\n    return 1\n  else\n    rm -f \"${GROQBASH_CONFIG_DIR%/}/.groqbash_tmp_check\" 2>/dev/null || true\n  fi\n\n  return 0\n}"
```

---

**name**: "ensure_run_tmpdir"  

**file**: "groqbash"  

**line_range**: "L722"  

**body_snippet**: 
```sh
# source: groqbash:722\nensure_run_tmpdir() {\n  # Usage:\n  #   ensure_run_tmpdir            -> create/export RUN_TMPDIR PAYLOAD RESP ERRF in-process\n  #   ensure_run_tmpdir --print    -> print RUN_TMPDIR to stdout (no trap, safe for subshell capture)\n  local print_only=0 subshell=0 tmpdir\n  if [ \"${1:-}\" = \"--print\" ]; then print_only=1; fi\n\n  # Detect subshell: prefer comparing BASHPID to $$ (reliable in bash)\n  # If BASHPID differs from $$ we are in a subshell; treat as subshell context.\n  if [ -n \"${BASHPID:-}\" ] && [ \"${BASHPID:-}\" != \"$$\" ]; then\n    subshell=1\n  fi\n\n  # If RUN_TMPDIR already set and valid, reuse it (do not clobber existing values)\n  if [ -n \"${RUN_TMPDIR:-}\" ] && [ -d \"${RUN_TMPDIR:-}\" ]; then\n    chmod 700 \"$RUN_TMPDIR\" 2>/dev/null || true\n    : \"${PAYLOAD:=$RUN_TMPDIR/payload}\"\n    : \"${RESP:=$RUN_TMPDIR/resp.json}\"\n    : \"${ERRF:=$RUN_TMPDIR/err.log}\"\n    if [ \"$print_only\" -eq 0 ] && [ \"$subshell\" -eq 0 ]; then\n      : > \"$RESP\" 2>/dev/null || true\n      chmod 600 \"$RESP\" 2>/dev/null || true\n      : > \"$ERRF\" 2>/dev/null || true\n      chmod 600 \"$ERRF\" 2>/dev/null || true\n      export RUN_TMPDIR PAYLOAD RESP ERRF\n    fi\n    if [ \"$print_only\" -eq 1 ]; then\n      printf '%s' \"$RUN_TMPDIR\"\n    fi\n    return 0\n  fi\n\n  # Ensure base tmpdir exists and has strict perms\n  if [ -z \"${GROQBASH_TMPDIR:-}\" ]; then\n    log_error \"TMP\" \"GROQBASH_TMPDIR not set\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  mkdir -p \"$GROQBASH_TMPDIR\" 2>/dev/null || { log_error \"TMP\" \"cannot create base tmpdir $GROQBASH_TMPDIR\"; return 1; }\n  chmod 700 \"$GROQBASH_TMPDIR\" 2>/dev/null || true\n\n  # Try mktemp under GROQBASH_TMPDIR, fallback to make_tmpdir, then timestamped dir\n  tmpdir=\"$(mktemp -d \"${GROQBASH_TMPDIR%/}/run.XXXXXX\" 2>/dev/null || true)\"\n  if [ -z \"$tmpdir\" ] || [ ! -d \"$tmpdir\" ]; then\n    tmpdir=\"$(make_tmpdir 2>/dev/null || true)\"\n  fi\n  if [ -z \"$tmpdir\" ] || [ ! -d \"$tmpdir\" ]; then\n    tmpdir=\"${GROQBASH_TMPDIR%/}/run-$(date -u +%Y%m%dT%H%M%SZ)-$$\"\n    mkdir -p \"$tmpdir\" 2>/dev/null || { log_error \"TMP\" \"cannot create fallback RUN_TMPDIR $tmpdir\"; return 1; }\n  fi\n\n  # Enforce strict perms\n  chmod 700 \"$tmpdir\" 2>/dev/null || true\n\n  # Assign into RUN_TMPDIR local then export if requested\n  RUN_TMPDIR=\"$tmpdir\"\n\n  # Provider-agnostic payload path (set only if unset)\n  : \"${PAYLOAD:=$RUN_TMPDIR/payload}\"\n  : \"${RESP:=$RUN_TMPDIR/resp.json}\"\n  : \"${ERRF:=$RUN_TMPDIR/err.log}\"\n\n  # Create RESP/ERRF files only in main process and when not print-only\n  if [ \"$print_only\" -eq 0 ] && [ \"$subshell\" -eq 0 ]; then\n    : > \"$RESP\" 2>/dev/null || true\n    chmod 600 \"$RESP\" 2>/dev/null || true\n    : > \"$ERRF\" 2>/dev/null || true\n    chmod 600 \"$ERRF\" 2>/dev/null || true\n  fi\n\n  # Remove any empty groq.b64 staging files inside GROQBASH_TMPDIR to avoid confusing later logic\n  if [ -n \"${GROQBASH_TMPDIR:-}\" ] && [ -d \"${GROQBASH_TMPDIR:-}\" ]; then\n    for f in \"${GROQBASH_TMPDIR%/}/\"*.b64 \"${RUN_TMPDIR%/}/\"*.b64; do\n      [ -e \"$f\" ] || continue\n      if [ ! -s \"$f\" ]; then\n        rm -f -- \"$f\" 2>/dev/null || true\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"TMP\" \"Removed empty staging file: $f\"\n        fi\n      fi\n    done\n  fi\n\n  # Define cleanup function but install trap only when running in main process\n  cleanup_run_tmp_on_exit() {\n    if [ \"${DEBUG_PRESERVE:-0}\" -eq 1 ]; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"TMP\" \"DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR\"\n      fi\n      return 0\n    fi\n    if [ -n \"${RUN_TMPDIR:-}\" ]; then\n      case \"$RUN_TMPDIR\" in\n        \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\")\n          rm -rf -- \"$RUN_TMPDIR\" 2>/dev/null || true\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"Cleaned RUN_TMPDIR: $RUN_TMPDIR\"\n          fi\n          ;;\n        *)\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"RUN_TMPDIR outside GROQBASH_TMPDIR; not removed: $RUN_TMPDIR\"\n          fi\n          ;;\n      esac\n    fi\n  }\n\n  # Install
```

**line_start**: 722  

**body_full**:
```sh
# source: groqbash:722\nensure_run_tmpdir() {\n  # Usage:\n  #   ensure_run_tmpdir            -> create/export RUN_TMPDIR PAYLOAD RESP ERRF in-process\n  #   ensure_run_tmpdir --print    -> print RUN_TMPDIR to stdout (no trap, safe for subshell capture)\n  local print_only=0 subshell=0 tmpdir\n  if [ \"${1:-}\" = \"--print\" ]; then print_only=1; fi\n\n  # Detect subshell: prefer comparing BASHPID to $$ (reliable in bash)\n  # If BASHPID differs from $$ we are in a subshell; treat as subshell context.\n  if [ -n \"${BASHPID:-}\" ] && [ \"${BASHPID:-}\" != \"$$\" ]; then\n    subshell=1\n  fi\n\n  # If RUN_TMPDIR already set and valid, reuse it (do not clobber existing values)\n  if [ -n \"${RUN_TMPDIR:-}\" ] && [ -d \"${RUN_TMPDIR:-}\" ]; then\n    chmod 700 \"$RUN_TMPDIR\" 2>/dev/null || true\n    : \"${PAYLOAD:=$RUN_TMPDIR/payload}\"\n    : \"${RESP:=$RUN_TMPDIR/resp.json}\"\n    : \"${ERRF:=$RUN_TMPDIR/err.log}\"\n    if [ \"$print_only\" -eq 0 ] && [ \"$subshell\" -eq 0 ]; then\n      : > \"$RESP\" 2>/dev/null || true\n      chmod 600 \"$RESP\" 2>/dev/null || true\n      : > \"$ERRF\" 2>/dev/null || true\n      chmod 600 \"$ERRF\" 2>/dev/null || true\n      export RUN_TMPDIR PAYLOAD RESP ERRF\n    fi\n    if [ \"$print_only\" -eq 1 ]; then\n      printf '%s' \"$RUN_TMPDIR\"\n    fi\n    return 0\n  fi\n\n  # Ensure base tmpdir exists and has strict perms\n  if [ -z \"${GROQBASH_TMPDIR:-}\" ]; then\n    log_error \"TMP\" \"GROQBASH_TMPDIR not set\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  mkdir -p \"$GROQBASH_TMPDIR\" 2>/dev/null || { log_error \"TMP\" \"cannot create base tmpdir $GROQBASH_TMPDIR\"; return 1; }\n  chmod 700 \"$GROQBASH_TMPDIR\" 2>/dev/null || true\n\n  # Try mktemp under GROQBASH_TMPDIR, fallback to make_tmpdir, then timestamped dir\n  tmpdir=\"$(mktemp -d \"${GROQBASH_TMPDIR%/}/run.XXXXXX\" 2>/dev/null || true)\"\n  if [ -z \"$tmpdir\" ] || [ ! -d \"$tmpdir\" ]; then\n    tmpdir=\"$(make_tmpdir 2>/dev/null || true)\"\n  fi\n  if [ -z \"$tmpdir\" ] || [ ! -d \"$tmpdir\" ]; then\n    tmpdir=\"${GROQBASH_TMPDIR%/}/run-$(date -u +%Y%m%dT%H%M%SZ)-$$\"\n    mkdir -p \"$tmpdir\" 2>/dev/null || { log_error \"TMP\" \"cannot create fallback RUN_TMPDIR $tmpdir\"; return 1; }\n  fi\n\n  # Enforce strict perms\n  chmod 700 \"$tmpdir\" 2>/dev/null || true\n\n  # Assign into RUN_TMPDIR local then export if requested\n  RUN_TMPDIR=\"$tmpdir\"\n\n  # Provider-agnostic payload path (set only if unset)\n  : \"${PAYLOAD:=$RUN_TMPDIR/payload}\"\n  : \"${RESP:=$RUN_TMPDIR/resp.json}\"\n  : \"${ERRF:=$RUN_TMPDIR/err.log}\"\n\n  # Create RESP/ERRF files only in main process and when not print-only\n  if [ \"$print_only\" -eq 0 ] && [ \"$subshell\" -eq 0 ]; then\n    : > \"$RESP\" 2>/dev/null || true\n    chmod 600 \"$RESP\" 2>/dev/null || true\n    : > \"$ERRF\" 2>/dev/null || true\n    chmod 600 \"$ERRF\" 2>/dev/null || true\n  fi\n\n  # Remove any empty groq.b64 staging files inside GROQBASH_TMPDIR to avoid confusing later logic\n  if [ -n \"${GROQBASH_TMPDIR:-}\" ] && [ -d \"${GROQBASH_TMPDIR:-}\" ]; then\n    for f in \"${GROQBASH_TMPDIR%/}/\"*.b64 \"${RUN_TMPDIR%/}/\"*.b64; do\n      [ -e \"$f\" ] || continue\n      if [ ! -s \"$f\" ]; then\n        rm -f -- \"$f\" 2>/dev/null || true\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"TMP\" \"Removed empty staging file: $f\"\n        fi\n      fi\n    done\n  fi\n\n  # Define cleanup function but install trap only when running in main process\n  cleanup_run_tmp_on_exit() {\n    if [ \"${DEBUG_PRESERVE:-0}\" -eq 1 ]; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"TMP\" \"DEBUG_PRESERVE set; preserving RUN_TMPDIR=$RUN_TMPDIR\"\n      fi\n      return 0\n    fi\n    if [ -n \"${RUN_TMPDIR:-}\" ]; then\n      case \"$RUN_TMPDIR\" in\n        \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\")\n          rm -rf -- \"$RUN_TMPDIR\" 2>/dev/null || true\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"Cleaned RUN_TMPDIR: $RUN_TMPDIR\"\n          fi\n          ;;\n        *)\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"TMP\" \"RUN_TMPDIR outside GROQBASH_TMPDIR; not removed: $RUN_TMPDIR\"\n          fi\n          ;;\n      esac\n    fi\n  }\n\n  # Install trap only if we are in the main shell and not in print-only mode\n  if [ \"$subshell\" -eq 0 ] && [ \"$print_only\" -eq 0 ]; then\n    trap cleanup_run_tmp_on_exit EXIT INT TERM\n  fi\n\n  # Export variables in main process (if not print-only)\n  if [ \"$print_only\" -eq 0 ]; then\n    export RUN_TMPDIR PAYLOAD RESP ERRF\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"TMP\" \"Created RUN_TMPDIR: $RUN_TMPDIR\"\n    fi\n  else\n    printf '%s' \"$RUN_TMPDIR\"\n  fi\n\n  return 0\n}"
```

---

**name**: "extract_text_from_resp"  

**file**: "groqbash"  

**line_range**: "L656"  

**body_snippet**: 
```sh
# source: groqbash:656\nextract_text_from_resp() {\n  # Extract textual content from RESP and print to stdout.\n  # Return codes:\n  # 0 = success (text printed)\n  # 2 = RESP is diagnostic (no real content)\n  # 1 = no textual content found or error\n  local resp_file=\"${RESP:-}\"\n  if [ -z \"${resp_file:-}\" ]; then\n    log_error \"EXTRACT\" \"RESP path not set\"\n    return 1\n  fi\n\n  if ! is_valid_json_file \"$resp_file\"; then\n    log_warn \"EXTRACT\" \"RESP missing or not valid JSON: $resp_file\"\n    # If file exists but not JSON, output raw content as fallback\n    if [ -f \"$resp_file\" ]; then\n      cat \"$resp_file\" 2>/dev/null || true\n      return 0\n    fi\n    return 1\n  fi\n\n  # If diagnostic JSON, bail with info\n  if jq -e 'has(\"diagnostic\") and .diagnostic==true' \"$resp_file\" >/dev/null 2>&1; then\n    log_warn \"EXTRACT\" \"RESP is diagnostic JSON; skipping text extraction\"\n    return 2\n  fi\n\n  # 1) choices[].message.content or choices[].delta.content\n  if jq -e '.choices and (.choices|length>0) and ( [ .choices[]? | (.message?.content // .delta?.content // \"\") ] | map(select(.!=\"\")) | length > 0 )' \"$resp_file\" >/dev/null 2>&1; then\n    jq -r '[.choices[]? | (.message?.content // .delta?.content // \"\")] | map(select(.!=\"\")) | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n    return 0\n  fi\n\n  # 2) choices[].text (older formats)\n  if jq -e '.choices and (.choices|length>0) and ( [ .choices[]? | (.text? // \"\") ] | map(select(.!=\"\")) | length > 0 )' \"$resp_file\" >/dev/null 2>&1; then\n    jq -r '[.choices[]?.text? // empty] | map(select(.!=\"\")) | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n    return 0\n  fi\n\n  # 3) output_text or data[].text\n  if jq -e '(.output_text? // empty) != \"\" or (.data and (.data|length>0) and ( [ .data[]? | (.text? // \"\") ] | map(select(.!=\"\")) | length > 0 ))' \"$resp_file\" >/dev/null 2>&1; then\n    if [ \"$(jq -r '.output_text // empty' \"$resp_file\" 2>/dev/null)\" != \"\" ]; then\n      jq -r '.output_text' \"$resp_file\" 2>/dev/null || return 1\n      return 0\n    else\n      jq -r '[.data[]?.text? // empty] | map(select(.!=\"\")) | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n      return 0\n    fi\n  fi\n\n  # 4) fallback: any string scalars concatenated\n  if jq -e 'paths(scalars) as $p | getpath($p) | type==\"string\"' \"$resp_file\" >/dev/null 2>&1; then\n    jq -r '[.. | scalars | select(type==\"string\")] | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n    return 0\n  fi\n\n  log_warn \"EXTRACT\" \"No textual content found in RESP\"\n  return 1\n}
```

**line_start**: 656  

**body_full**:
```sh
# source: groqbash:656\nextract_text_from_resp() {\n  # Extract textual content from RESP and print to stdout.\n  # Return codes:\n  # 0 = success (text printed)\n  # 2 = RESP is diagnostic (no real content)\n  # 1 = no textual content found or error\n  local resp_file=\"${RESP:-}\"\n  if [ -z \"${resp_file:-}\" ]; then\n    log_error \"EXTRACT\" \"RESP path not set\"\n    return 1\n  fi\n\n  if ! is_valid_json_file \"$resp_file\"; then\n    log_warn \"EXTRACT\" \"RESP missing or not valid JSON: $resp_file\"\n    # If file exists but not JSON, output raw content as fallback\n    if [ -f \"$resp_file\" ]; then\n      cat \"$resp_file\" 2>/dev/null || true\n      return 0\n    fi\n    return 1\n  fi\n\n  # If diagnostic JSON, bail with info\n  if jq -e 'has(\"diagnostic\") and .diagnostic==true' \"$resp_file\" >/dev/null 2>&1; then\n    log_warn \"EXTRACT\" \"RESP is diagnostic JSON; skipping text extraction\"\n    return 2\n  fi\n\n  # 1) choices[].message.content or choices[].delta.content\n  if jq -e '.choices and (.choices|length>0) and ( [ .choices[]? | (.message?.content // .delta?.content // \"\") ] | map(select(.!=\"\")) | length > 0 )' \"$resp_file\" >/dev/null 2>&1; then\n    jq -r '[.choices[]? | (.message?.content // .delta?.content // \"\")] | map(select(.!=\"\")) | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n    return 0\n  fi\n\n  # 2) choices[].text (older formats)\n  if jq -e '.choices and (.choices|length>0) and ( [ .choices[]? | (.text? // \"\") ] | map(select(.!=\"\")) | length > 0 )' \"$resp_file\" >/dev/null 2>&1; then\n    jq -r '[.choices[]?.text? // empty] | map(select(.!=\"\")) | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n    return 0\n  fi\n\n  # 3) output_text or data[].text\n  if jq -e '(.output_text? // empty) != \"\" or (.data and (.data|length>0) and ( [ .data[]? | (.text? // \"\") ] | map(select(.!=\"\")) | length > 0 ))' \"$resp_file\" >/dev/null 2>&1; then\n    if [ \"$(jq -r '.output_text // empty' \"$resp_file\" 2>/dev/null)\" != \"\" ]; then\n      jq -r '.output_text' \"$resp_file\" 2>/dev/null || return 1\n      return 0\n    else\n      jq -r '[.data[]?.text? // empty] | map(select(.!=\"\")) | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n      return 0\n    fi\n  fi\n\n  # 4) fallback: any string scalars concatenated\n  if jq -e 'paths(scalars) as $p | getpath($p) | type==\"string\"' \"$resp_file\" >/dev/null 2>&1; then\n    jq -r '[.. | scalars | select(type==\"string\")] | join(\"\\n\\n\")' \"$resp_file\" 2>/dev/null || return 1\n    return 0\n  fi\n\n  log_warn \"EXTRACT\" \"No textual content found in RESP\"\n  return 1\n}"
```

---

**name**: "file_size"  

**file**: "groqbash"  

**line_range**: "L388"  

**body_snippet**: 
```sh
# source: groqbash:388\nfile_size() {\n  local f=\"$1\"\n  if [ -z \"$f\" ] || [ ! -f \"$f\" ]; then\n    printf '0'\n    return 0\n  fi\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) stat -f %z \"$f\" 2>/dev/null || printf '0' ;;\n    *) stat -c %s \"$f\" 2>/dev/null || printf '0' ;;\n  esac\n}
```

**line_start**: 388  

**body_full**:
```sh
# source: groqbash:388\nfile_size() {\n  local f=\"$1\"\n  if [ -z \"$f\" ] || [ ! -f \"$f\" ]; then\n    printf '0'\n    return 0\n  fi\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) stat -f %z \"$f\" 2>/dev/null || printf '0' ;;\n    *) stat -c %s \"$f\" 2>/dev/null || printf '0' ;;\n  esac\n}"
```

---

**name**: "is_truthy"  

**file**: "groqbash"  

**line_range**: "L380"  

**body_snippet**: 
```sh
# source: groqbash:380\nis_truthy() {\n  case \"${1:-}\" in\n    1|true|TRUE|True|yes|YES|Yes) return 0 ;;\n    *) return 1 ;;\n  esac\n}
```

**line_start**: 380  

**body_full**:
```sh
# source: groqbash:380\nis_truthy() {\n  case \"${1:-}\" in\n    1|true|TRUE|True|yes|YES|Yes) return 0 ;;\n    *) return 1 ;;\n  esac\n}"
```

---

**name**: "is_valid_json_file"  

**file**: "groqbash"  

**line_range**: "L401"  

**body_snippet**: 
```sh
# source: groqbash:401\nis_valid_json_file() {\n  local f=\"$1\"\n  [ -f \"$f\" ] || return 1\n  [ -s \"$f\" ] || return 1\n  # Trim leading BOM/whitespace by letting jq parse; jq -e returns 0 on valid JSON\n  jq -e . \"$f\" >/dev/null 2>&1\n}
```

**line_start**: 401  

**body_full**:
```sh
# source: groqbash:401\nis_valid_json_file() {\n  local f=\"$1\"\n  [ -f \"$f\" ] || return 1\n  [ -s \"$f\" ] || return 1\n  # Trim leading BOM/whitespace by letting jq parse; jq -e returns 0 on valid JSON\n  jq -e . \"$f\" >/dev/null 2>&1\n}"
```

---

**name**: "is_valid_json_string"  

**file**: "groqbash"  

**line_range**: "L352"  

**body_snippet**: 
```sh
# source: groqbash:352\nis_valid_json_string() {\n  local s=\"$1\"\n  [ -n \"${s:-}\" ] || return 1\n  printf '%s' \"$s\" | jq -e . >/dev/null 2>&1\n}
```

**line_start**: 352  

**body_full**:
```sh
# source: groqbash:352\nis_valid_json_string() {\n  local s=\"$1\"\n  [ -n \"${s:-}\" ] || return 1\n  printf '%s' \"$s\" | jq -e . >/dev/null 2>&1\n}"
```

---

**name**: "jq_safe"  

**file**: "groqbash"  

**line_range**: "L1189"  

**body_snippet**: 
```sh
# source: groqbash:1189\njq_safe() {\n  # wrapper to run jq and capture errors to ERRF if set\n  local filter=\"$1\" file=\"$2\" rc\n  if [ -z \"$file\" ] || [ ! -s \"$file\" ]; then\n    return 1\n  fi\n  if ! jq -e \"$filter\" \"$file\" >/dev/null 2>&1; then\n    rc=$?\n    # If ERRF is defined, append jq stderr for diagnostics\n    if [ -n \"${ERRF:-}\" ]; then\n      jq \"$filter\" \"$file\" 2>>\"$ERRF\" >/dev/null 2>&1 || true\n    fi\n    return \"$rc\"\n  fi\n  return 0\n}
```

**line_start**: 1189  

**body_full**:
```sh
# source: groqbash:1189\njq_safe() {\n  # wrapper to run jq and capture errors to ERRF if set\n  local filter=\"$1\" file=\"$2\" rc\n  if [ -z \"$file\" ] || [ ! -s \"$file\" ]; then\n    return 1\n  fi\n  if ! jq -e \"$filter\" \"$file\" >/dev/null 2>&1; then\n    rc=$?\n    # If ERRF is defined, append jq stderr for diagnostics\n    if [ -n \"${ERRF:-}\" ]; then\n      jq \"$filter\" \"$file\" 2>>\"$ERRF\" >/dev/null 2>&1 || true\n    fi\n    return \"$rc\"\n  fi\n  return 0\n}"
```

---

**name**: "list_files_sorted_by_mtime"  

**file**: "groqbash"  

**line_range**: "L1146"  

**body_snippet**: 
```sh
# source: groqbash:1146\nlist_files_sorted_by_mtime() {\n  local dir=\"$1\"\n  find \"$dir\" -type f -print0 2>/dev/null | while IFS= read -r -d '' f; do\n    case \"$(uname 2>/dev/null || echo Linux)\" in\n      Darwin) mtime=\"$(stat -f %m \"$f\" 2>/dev/null || echo 0)\" ;;\n      *) mtime=\"$(stat -c %Y \"$f\" 2>/dev/null || echo 0)\" ;;\n    esac\n    printf '%s|%s\\n' \"$mtime\" \"$f\"\n  done | sort -n\n}
```

**line_start**: 1146  

**body_full**:
```sh
# source: groqbash:1146\nlist_files_sorted_by_mtime() {\n  local dir=\"$1\"\n  find \"$dir\" -type f -print0 2>/dev/null | while IFS= read -r -d '' f; do\n    case \"$(uname 2>/dev/null || echo Linux)\" in\n      Darwin) mtime=\"$(stat -f %m \"$f\" 2>/dev/null || echo 0)\" ;;\n      *) mtime=\"$(stat -c %Y \"$f\" 2>/dev/null || echo 0)\" ;;\n    esac\n    printf '%s|%s\\n' \"$mtime\" \"$f\"\n  done | sort -n\n}"
```

---

**name**: "load_provider_module"  

**file**: "groqbash"  

**line_range**: "L1021"  

**body_snippet**: 
```sh
# source: groqbash:1021\nload_provider_module() {\n  local provider=\"$1\"\n\n  # Skip if already loaded for the same provider\n  if [ \"${LOADED_PROVIDER_NAME:-}\" = \"$provider\" ] && [ \"${PROVIDER_MODULE_LOADED:-0}\" -eq 1 ]; then\n    return 0\n  fi\n\n  LOADED_PROVIDER_NAME=\"$provider\"\n  PROVIDER_MODULE_LOADED=0\n  PROVIDER_MODULE_PATH=\"$PROVIDERS_DIR/${provider}.sh\"\n  PROVIDER_DIR=\"$PROVIDERS_DIR\"\n\n  if [ ! -d \"$PROVIDER_DIR\" ]; then\n    mkdir -p \"$PROVIDER_DIR\" 2>/dev/null || { log_error \"PROVIDER\" \"cannot create provider directory.\"; return 1; }\n  fi\n\n  if _is_world_writable \"$PROVIDER_DIR\"; then\n    log_error \"SEC\" \"provider directory is world-writable.\"\n    return 1\n  fi\n\n  local current_user owner file_owner perms group_write others_write beforesig aftersig invalid_provider _req\n  current_user=\"$(id -un 2>/dev/null || printf '')\"\n  owner=\"$(_get_owner \"$PROVIDER_DIR\")\"\n  [ -n \"$owner\" ] && [ \"$owner\" != \"$current_user\" ] && log_warn \"SEC\" \"provider directory owned by $owner\"\n\n  if [ ! -f \"$PROVIDER_MODULE_PATH\" ]; then\n    if [ \"$provider\" != \"groq\" ]; then\n      printf 'Provider %s is not installed.\\n' \"$provider\" >&2\n      PROVIDER_MODULE_LOADED=0\n      return 0\n    else\n      PROVIDER_MODULE_LOADED=1\n      return 0\n    fi\n  fi\n\n  if [ -L \"$PROVIDER_MODULE_PATH\" ]; then\n    log_error \"SEC\" \"provider file is symlink.\"\n    return 1\n  fi\n\n  file_owner=\"$(_get_owner \"$PROVIDER_MODULE_PATH\")\"\n  [ -n \"$file_owner\" ] && [ \"$file_owner\" != \"$current_user\" ] && { log_error \"SEC\" \"wrong owner for provider file.\"; return 1; }\n\n  perms=\"$(_get_perm_string \"$PROVIDER_MODULE_PATH\")\"\n  group_write=\"$(printf '%s' \"$perms\" | awk '{print substr($0,6,1)}')\"\n  others_write=\"$(printf '%s' \"$perms\" | awk '{print substr($0,9,1)}')\"\n  if [ \"$group_write\" = \"w\" ] || [ \"$others_write\" = \"w\" ]; then\n    log_error \"SEC\" \"provider file writable by group/world.\"\n    return 1\n  fi\n\n  beforesig=\"$(getfile_signature \"$PROVIDER_MODULE_PATH\" 2>/dev/null || true)\"\n\n  if bash -n \"$PROVIDER_MODULE_PATH\" 2>/dev/null; then\n    . \"$PROVIDER_MODULE_PATH\"\n    PROVIDER_MODULE_LOADED=1\n\n    invalid_provider=0\n    for _req in \"buildpayload_${provider}\" \"call_api_${provider}\"; do\n      type \"$_req\" >/dev/null 2>&1 || invalid_provider=1\n    done\n\n    aftersig=\"$(getfile_signature \"$PROVIDER_MODULE_PATH\" 2>/dev/null || true)\"\n    [ \"$beforesig\" != \"$aftersig\" ] && { log_error \"SEC\" \"provider file changed.\"; return 1; }\n\n    if [ \"$invalid_provider\" -eq 1 ]; then\n      log_warn \"PROVIDER\" \"provider module incomplete; falling back to embedded provider.\"\n      PROVIDER_MODULE_LOADED=0\n    fi\n  else\n    log_warn \"PROVIDER\" \"provider module invalid; falling back to embedded provider.\"\n    PROVIDER_MODULE_LOADED=0\n  fi\n\n  # --- Write provider capabilities to ui_state (canonical) ---\n  if [ -n \"${provider:-}\" ]; then\n    supports_streaming=0\n    supports_refresh_models=0\n    if type \"call_api_streaming_${provider}\" >/dev/null 2>&1; then supports_streaming=1; fi\n    if type \"refresh_models_${provider}\" >/dev/null 2>&1; then supports_refresh_models=1; fi\n    loaded_from=\"${PROVIDER_MODULE_PATH:-embedded}\"\n    prov_json=\"$(jq -c -n --arg p \"$provider\" --arg loaded \"$loaded_from\" --argjson sstream \"$supports_streaming\" --argjson srefresh \"$supports_refresh_models\" '{provider:$p, supports_streaming:$sstream, supports_refresh_models:$srefresh, loaded_from:$loaded}')\"\n    ui_state_write \"provider_capabilities.json\" \"$prov_json\" || log_warn \"UI_STATE\" \"failed to write provider_capabilities for $provider\"\n  fi\n\n  return 0\n}
```

**line_start**: 1021  

**body_full**:
```sh
# source: groqbash:1021\nload_provider_module() {\n  local provider=\"$1\"\n\n  # Skip if already loaded for the same provider\n  if [ \"${LOADED_PROVIDER_NAME:-}\" = \"$provider\" ] && [ \"${PROVIDER_MODULE_LOADED:-0}\" -eq 1 ]; then\n    return 0\n  fi\n\n  LOADED_PROVIDER_NAME=\"$provider\"\n  PROVIDER_MODULE_LOADED=0\n  PROVIDER_MODULE_PATH=\"$PROVIDERS_DIR/${provider}.sh\"\n  PROVIDER_DIR=\"$PROVIDERS_DIR\"\n\n  if [ ! -d \"$PROVIDER_DIR\" ]; then\n    mkdir -p \"$PROVIDER_DIR\" 2>/dev/null || { log_error \"PROVIDER\" \"cannot create provider directory.\"; return 1; }\n  fi\n\n  if _is_world_writable \"$PROVIDER_DIR\"; then\n    log_error \"SEC\" \"provider directory is world-writable.\"\n    return 1\n  fi\n\n  local current_user owner file_owner perms group_write others_write beforesig aftersig invalid_provider _req\n  current_user=\"$(id -un 2>/dev/null || printf '')\"\n  owner=\"$(_get_owner \"$PROVIDER_DIR\")\"\n  [ -n \"$owner\" ] && [ \"$owner\" != \"$current_user\" ] && log_warn \"SEC\" \"provider directory owned by $owner\"\n\n  if [ ! -f \"$PROVIDER_MODULE_PATH\" ]; then\n    if [ \"$provider\" != \"groq\" ]; then\n      printf 'Provider %s is not installed.\\n' \"$provider\" >&2\n      PROVIDER_MODULE_LOADED=0\n      return 0\n    else\n      PROVIDER_MODULE_LOADED=1\n      return 0\n    fi\n  fi\n\n  if [ -L \"$PROVIDER_MODULE_PATH\" ]; then\n    log_error \"SEC\" \"provider file is symlink.\"\n    return 1\n  fi\n\n  file_owner=\"$(_get_owner \"$PROVIDER_MODULE_PATH\")\"\n  [ -n \"$file_owner\" ] && [ \"$file_owner\" != \"$current_user\" ] && { log_error \"SEC\" \"wrong owner for provider file.\"; return 1; }\n\n  perms=\"$(_get_perm_string \"$PROVIDER_MODULE_PATH\")\"\n  group_write=\"$(printf '%s' \"$perms\" | awk '{print substr($0,6,1)}')\"\n  others_write=\"$(printf '%s' \"$perms\" | awk '{print substr($0,9,1)}')\"\n  if [ \"$group_write\" = \"w\" ] || [ \"$others_write\" = \"w\" ]; then\n    log_error \"SEC\" \"provider file writable by group/world.\"\n    return 1\n  fi\n\n  beforesig=\"$(getfile_signature \"$PROVIDER_MODULE_PATH\" 2>/dev/null || true)\"\n\n  if bash -n \"$PROVIDER_MODULE_PATH\" 2>/dev/null; then\n    . \"$PROVIDER_MODULE_PATH\"\n    PROVIDER_MODULE_LOADED=1\n\n    invalid_provider=0\n    for _req in \"buildpayload_${provider}\" \"call_api_${provider}\"; do\n      type \"$_req\" >/dev/null 2>&1 || invalid_provider=1\n    done\n\n    aftersig=\"$(getfile_signature \"$PROVIDER_MODULE_PATH\" 2>/dev/null || true)\"\n    [ \"$beforesig\" != \"$aftersig\" ] && { log_error \"SEC\" \"provider file changed.\"; return 1; }\n\n    if [ \"$invalid_provider\" -eq 1 ]; then\n      log_warn \"PROVIDER\" \"provider module incomplete; falling back to embedded provider.\"\n      PROVIDER_MODULE_LOADED=0\n    fi\n  else\n    log_warn \"PROVIDER\" \"provider module invalid; falling back to embedded provider.\"\n    PROVIDER_MODULE_LOADED=0\n  fi\n\n  # --- Write provider capabilities to ui_state (canonical) ---\n  if [ -n \"${provider:-}\" ]; then\n    supports_streaming=0\n    supports_refresh_models=0\n    if type \"call_api_streaming_${provider}\" >/dev/null 2>&1; then supports_streaming=1; fi\n    if type \"refresh_models_${provider}\" >/dev/null 2>&1; then supports_refresh_models=1; fi\n    loaded_from=\"${PROVIDER_MODULE_PATH:-embedded}\"\n    prov_json=\"$(jq -c -n --arg p \"$provider\" --arg loaded \"$loaded_from\" --argjson sstream \"$supports_streaming\" --argjson srefresh \"$supports_refresh_models\" '{provider:$p, supports_streaming:$sstream, supports_refresh_models:$srefresh, loaded_from:$loaded}')\"\n    ui_state_write \"provider_capabilities.json\" \"$prov_json\" || log_warn \"UI_STATE\" \"failed to write provider_capabilities for $provider\"\n  fi\n\n  return 0\n}"
```

---

**name**: "lock_exec"  

**file**: "groqbash"  

**line_range**: "L527"  

**body_snippet**: 
```sh
# source: groqbash:527\nlock_exec() {\n  local lockfile=\"$1\"\n  local timeout=\"${2:-10}\"\n  shift 2\n  if [ \"$1\" != \"--\" ]; then\n    log_error \"USAGE\" \"lock_exec <lockfile> <timeout> -- <cmd> [args...]\"\n    return 2\n  fi\n  shift\n\n  mkdir -p \"$(dirname \"$lockfile\")\" 2>/dev/null || { log_error \"LOCKFAIL\" \"cannot create lockfile dir: $(dirname \"$lockfile\")\"; return 2; }\n\n  if command -v flock >/dev/null 2>&1; then\n    # Use a dedicated file descriptor to ensure lock is released when subshell exits\n    (\n      # Open FD 9 for the lockfile inside subshell to avoid leaking FDs to caller\n      exec 9>\"$lockfile\"\n      if ! flock -x -w \"$timeout\" 9; then\n        printf '%sERROR: LOCKTIMEOUT: could not acquire lock on %s within %s seconds\\n' \"$(log_prefix)\" \"$lockfile\" \"$timeout\" >&2\n        exit 124\n      fi\n      # Execute the requested command in this subshell under lock\n      set -e\n      \"$@\"\n    )\n    rc=$?\n    return $rc\n  fi\n\n  # flock missing: fail with clear message\n  log_error \"LOCK\" \"flock not available; cannot acquire lock on $lockfile. Install util-linux/coreutils or run on supported platform.\"\n  return 2\n}
```

**line_start**: 527  

**body_full**:
```sh
# source: groqbash:527\nlock_exec() {\n  local lockfile=\"$1\"\n  local timeout=\"${2:-10}\"\n  shift 2\n  if [ \"$1\" != \"--\" ]; then\n    log_error \"USAGE\" \"lock_exec <lockfile> <timeout> -- <cmd> [args...]\"\n    return 2\n  fi\n  shift\n\n  mkdir -p \"$(dirname \"$lockfile\")\" 2>/dev/null || { log_error \"LOCKFAIL\" \"cannot create lockfile dir: $(dirname \"$lockfile\")\"; return 2; }\n\n  if command -v flock >/dev/null 2>&1; then\n    # Use a dedicated file descriptor to ensure lock is released when subshell exits\n    (\n      # Open FD 9 for the lockfile inside subshell to avoid leaking FDs to caller\n      exec 9>\"$lockfile\"\n      if ! flock -x -w \"$timeout\" 9; then\n        printf '%sERROR: LOCKTIMEOUT: could not acquire lock on %s within %s seconds\\n' \"$(log_prefix)\" \"$lockfile\" \"$timeout\" >&2\n        exit 124\n      fi\n      # Execute the requested command in this subshell under lock\n      set -e\n      \"$@\"\n    )\n    rc=$?\n    return $rc\n  fi\n\n  # flock missing: fail with clear message\n  log_error \"LOCK\" \"flock not available; cannot acquire lock on $lockfile. Install util-linux/coreutils or run on supported platform.\"\n  return 2\n}"
```

---

**name**: "log_error"  

**file**: "groqbash"  

**line_range**: "L437"  

**body_snippet**: 
```sh
# source: groqbash:437\nlog_error() {\n  local code=\"${1:-ERROR}\" msg=\"${2:-}\"\n  printf '%sERROR: %s: %s\\n' \"$(log_prefix)\" \"$code\" \"$msg\" >&2\n  if [ -n \"$GROQBASH_LOG\" ]; then printf '%s ERROR %s %s\\n' \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$code\" \"$msg\" >>\"$GROQBASH_LOG\" 2>/dev/null || true; fi\n}
```

**line_start**: 437  

**body_full**:
```sh
# source: groqbash:437\nlog_error() {\n  local code=\"${1:-ERROR}\" msg=\"${2:-}\"\n  printf '%sERROR: %s: %s\\n' \"$(log_prefix)\" \"$code\" \"$msg\" >&2\n  if [ -n \"$GROQBASH_LOG\" ]; then printf '%s ERROR %s %s\\n' \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$code\" \"$msg\" >>\"$GROQBASH_LOG\" 2>/dev/null || true; fi\n}"
```

---

**name**: "log_info"  

**file**: "groqbash"  

**line_range**: "L423"  

**body_snippet**: 
```sh
# source: groqbash:423\nlog_info() {\n  local code=\"${1:-INFO}\" msg=\"${2:-}\"\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    printf '%sINFO: %s: %s\\n' \"$(log_prefix)\" \"$code\" \"$msg\" >&2\n  fi\n  if [ -n \"$GROQBASH_LOG\" ]; then printf '%s INFO %s %s\\n' \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$code\" \"$msg\" >>\"$GROQBASH_LOG\" 2>/dev/null || true; fi\n}
```

**line_start**: 423  

**body_full**:
```sh
# source: groqbash:423\nlog_info() {\n  local code=\"${1:-INFO}\" msg=\"${2:-}\"\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    printf '%sINFO: %s: %s\\n' \"$(log_prefix)\" \"$code\" \"$msg\" >&2\n  fi\n  if [ -n \"$GROQBASH_LOG\" ]; then printf '%s INFO %s %s\\n' \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$code\" \"$msg\" >>\"$GROQBASH_LOG\" 2>/dev/null || true; fi\n}"
```

---

**name**: "log_prefix"  

**file**: "groqbash"  

**line_range**: "L421"  

**body_snippet**: 
```sh
# source: groqbash:421\nlog_prefix() { printf 'groqbash: %s: ' \"$SCRIPT_NAME\"; }
```

**line_start**: 421  

**body_full**:
```sh
# source: groqbash:421\nlog_prefix() { printf 'groqbash: %s: ' \"$SCRIPT_NAME\"; }"
```

---

**name**: "log_warn"  

**file**: "groqbash"  

**line_range**: "L431"  

**body_snippet**: 
```sh
# source: groqbash:431\nlog_warn() {\n  local code=\"${1:-WARN}\" msg=\"${2:-}\"\n  printf '%sWARN: %s: %s\\n' \"$(log_prefix)\" \"$code\" \"$msg\" >&2\n  if [ -n \"$GROQBASH_LOG\" ]; then printf '%s WARN %s %s\\n' \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$code\" \"$msg\" >>\"$GROQBASH_LOG\" 2>/dev/null || true; fi\n}
```

**line_start**: 431  

**body_full**:
```sh
# source: groqbash:431\nlog_warn() {\n  local code=\"${1:-WARN}\" msg=\"${2:-}\"\n  printf '%sWARN: %s: %s\\n' \"$(log_prefix)\" \"$code\" \"$msg\" >&2\n  if [ -n \"$GROQBASH_LOG\" ]; then printf '%s WARN %s %s\\n' \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$code\" \"$msg\" >>\"$GROQBASH_LOG\" 2>/dev/null || true; fi\n}"
```

---

**name**: "provider_api_env_var_name"  

**file**: "groqbash"  

**line_range**: "L344"  

**body_snippet**: 
```sh
# source: groqbash:344\nprovider_api_env_var_name() {\n  local prov=\"$1\"\n  local prov_upper\n  prov_upper=\"$(printf '%s' \"$prov\" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')\"\n  printf '%s' \"${prov_upper}_API_KEY\"\n}
```

**line_start**: 344  

**body_full**:
```sh
# source: groqbash:344\nprovider_api_env_var_name() {\n  local prov=\"$1\"\n  local prov_upper\n  prov_upper=\"$(printf '%s' \"$prov\" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')\"\n  printf '%s' \"${prov_upper}_API_KEY\"\n}"
```

---

**name**: "resolve_provider_url"  

**file**: "groqbash"  

**line_range**: "L301"  

**body_snippet**: 
```sh
# source: groqbash:301\nresolve_provider_url() {\n  local prov=\"${1:-$PROVIDER}\" prov_file prov_val\n  # 1) ENV\n  if [ -n \"${GROQBASH_API_URL:-}\" ]; then\n    GROQBASH_PROVIDER_URL=\"${GROQBASH_API_URL}\"\n    export GROQBASH_PROVIDER_URL\n    return 0\n  fi\n  if [ -n \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    return 0\n  fi\n  # 2) provider-url file\n  prov_file=\"$(canonical_provider_url_file)\"\n  if [ -f \"$prov_file\" ] && [ -s \"$prov_file\" ]; then\n    prov_val=\"$(sed -n '1p' \"$prov_file\" 2>/dev/null | awk '{$1=$1;print}')\"\n    if [ -n \"$prov_val\" ]; then\n      GROQBASH_PROVIDER_URL=\"$prov_val\"\n      export GROQBASH_PROVIDER_URL\n      return 0\n    fi\n  fi\n  # 3) embedded default for groq only (minimal)\n  if [ \"${prov:-}\" = \"groq\" ]; then\n    GROQBASH_PROVIDER_URL=\"https://api.groq.com/openai/v1/chat/completions\"\n    export GROQBASH_PROVIDER_URL\n    return 0\n  fi\n  return 1\n}
```

**line_start**: 301  

**body_full**:
```sh
# source: groqbash:301\nresolve_provider_url() {\n  local prov=\"${1:-$PROVIDER}\" prov_file prov_val\n  # 1) ENV\n  if [ -n \"${GROQBASH_API_URL:-}\" ]; then\n    GROQBASH_PROVIDER_URL=\"${GROQBASH_API_URL}\"\n    export GROQBASH_PROVIDER_URL\n    return 0\n  fi\n  if [ -n \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    return 0\n  fi\n  # 2) provider-url file\n  prov_file=\"$(canonical_provider_url_file)\"\n  if [ -f \"$prov_file\" ] && [ -s \"$prov_file\" ]; then\n    prov_val=\"$(sed -n '1p' \"$prov_file\" 2>/dev/null | awk '{$1=$1;print}')\"\n    if [ -n \"$prov_val\" ]; then\n      GROQBASH_PROVIDER_URL=\"$prov_val\"\n      export GROQBASH_PROVIDER_URL\n      return 0\n    fi\n  fi\n  # 3) embedded default for groq only (minimal)\n  if [ \"${prov:-}\" = \"groq\" ]; then\n    GROQBASH_PROVIDER_URL=\"https://api.groq.com/openai/v1/chat/completions\"\n    export GROQBASH_PROVIDER_URL\n    return 0\n  fi\n  return 1\n}"
```

---

**name**: "resolve_script_dir"  

**file**: "groqbash"  

**line_range**: "L64"  

**body_snippet**: 
```sh
# source: groqbash:64\nresolve_script_dir() {\n  local src=\"$0\" rl dir\n  if command -v readlink >/dev/null 2>&1 && [ -L \"$src\" ]; then\n    rl=\"$(readlink \"$src\" 2>/dev/null || true)\"\n    [ -n \"$rl\" ] && case \"$rl\" in /*) src=\"$rl\" ;; *) src=\"$(dirname \"$src\")/$rl\" ;; esac\n  fi\n  dir=\"$(cd \"$(dirname \"$src\")\" >/dev/null 2>&1 && pwd || printf '%s' \"$(dirname \"$src\")\")\"\n  printf '%s' \"$dir\"\n}
```

**line_start**: 64  

**body_full**:
```sh
# source: groqbash:64\nresolve_script_dir() {\n  local src=\"$0\" rl dir\n  if command -v readlink >/dev/null 2>&1 && [ -L \"$src\" ]; then\n    rl=\"$(readlink \"$src\" 2>/dev/null || true)\"\n    [ -n \"$rl\" ] && case \"$rl\" in /*) src=\"$rl\" ;; *) src=\"$(dirname \"$src\")/$rl\" ;; esac\n  fi\n  dir=\"$(cd \"$(dirname \"$src\")\" >/dev/null 2>&1 && pwd || printf '%s' \"$(dirname \"$src\")\")\"\n  printf '%s' \"$dir\"\n}"
```

---

**name**: "show_payload_head"  

**file**: "groqbash"  

**line_range**: "L581"  

**body_snippet**: 
```sh
# source: groqbash:581\nshow_payload_head() {\n  local path=\"${1:-$PAYLOAD}\" lines=\"${2:-200}\"\n  if [ -z \"${path:-}\" ]; then\n    printf 'groqbash: ERROR: payload file missing: %s\\n' \"<unset>\" >&2\n    exit \"$GROQBASHERRTMP\"\n  fi\n  if [ ! -e \"$path\" ]; then\n    printf 'groqbash: ERROR: payload file missing: %s\\n' \"$path\" >&2\n    exit \"$GROQBASHERRTMP\"\n  fi\n  if [ ! -s \"$path\" ]; then\n    printf 'groqbash: INFO: payload exists but is empty: %s\\n' \"$path\" >&2\n    return 0\n  fi\n\n  # Diagnostic output only when DEBUG=1\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    printf 'groqbash: INFO: payload path: %s\\n' \"$path\" >&2\n    printf 'groqbash: INFO: payload (head %d lines):\\n' \"$lines\" >&2\n    if printf '%s' \"$path\" | grep -qE '\\.b64$'; then\n      b64decode < \"$path\" 2>/dev/null | head -n \"$lines\" >&2 || true\n    else\n      head -n \"$lines\" \"$path\" 2>/dev/null >&2 || true\n    fi\n  fi\n\n  return 0\n}
```

**line_start**: 581  

**body_full**:
```sh
# source: groqbash:581\nshow_payload_head() {\n  local path=\"${1:-$PAYLOAD}\" lines=\"${2:-200}\"\n  if [ -z \"${path:-}\" ]; then\n    printf 'groqbash: ERROR: payload file missing: %s\\n' \"<unset>\" >&2\n    exit \"$GROQBASHERRTMP\"\n  fi\n  if [ ! -e \"$path\" ]; then\n    printf 'groqbash: ERROR: payload file missing: %s\\n' \"$path\" >&2\n    exit \"$GROQBASHERRTMP\"\n  fi\n  if [ ! -s \"$path\" ]; then\n    printf 'groqbash: INFO: payload exists but is empty: %s\\n' \"$path\" >&2\n    return 0\n  fi\n\n  # Diagnostic output only when DEBUG=1\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    printf 'groqbash: INFO: payload path: %s\\n' \"$path\" >&2\n    printf 'groqbash: INFO: payload (head %d lines):\\n' \"$lines\" >&2\n    if printf '%s' \"$path\" | grep -qE '\\.b64$'; then\n      b64decode < \"$path\" 2>/dev/null | head -n \"$lines\" >&2 || true\n    else\n      head -n \"$lines\" \"$path\" 2>/dev/null >&2 || true\n    fi\n  fi\n\n  return 0\n}"
```

---

**name**: "stage_b64"  

**file**: "groqbash"  

**line_range**: "L452"  

**body_snippet**: 
```sh
# source: groqbash:452\nstage_b64() {\n  # Dual-mode stage_b64:\n  # - If called with two args: stage_b64 /path/to/src /path/to/dst.b64\n  # - If called with one arg: stage_b64 /path/to/dst.b64  (reads stdin)\n  local src dst max_bytes tmp_local tmp_b64 workdir size b64_opts\n  if [ \"$#\" -eq 2 ]; then\n    src=\"$1\"; dst=\"$2\"\n  elif [ \"$#\" -eq 1 ]; then\n    dst=\"$1\"\n    src=\"\"\n  else\n    log_error \"STAGE\" \"stage_b64 usage: stage_b64 [src] dst\"\n    return 1\n  fi\n\n  max_bytes=\"${MAX_STAGE_BYTES:-10485760}\" # default 10MB\n  [ -n \"$dst\" ] || return 1\n  workdir=\"$(dirname \"$dst\")\"\n  mkdir -p \"$workdir\" 2>/dev/null || { log_error \"STAGE\" \"cannot create workdir $workdir\"; return 1; }\n\n  # If src provided, validate it; else read stdin into tmp_local\n  if [ -n \"$src\" ]; then\n    if [ ! -f \"$src\" ] || [ ! -s \"$src\" ]; then\n      log_error \"STAGE\" \"stage_b64: source payload missing or empty: $src\"\n      return 1\n    fi\n    tmp_local=\"$src\"\n    tmp_local_is_temp=0\n  else\n    tmp_local=\"$(mktemp \"${RUN_TMPDIR%/}/payload.tmp.XXXXXX\" 2>/dev/null || true)\"\n    [ -n \"$tmp_local\" ] || tmp_local=\"${RUN_TMPDIR%/}/payload.tmp.$$\"\n    if ! cat - > \"$tmp_local\" 2>/dev/null; then\n      rm -f -- \"$tmp_local\" 2>/dev/null || true\n      log_error \"STAGE\" \"failed to write staging payload from stdin\"\n      return 1\n    fi\n    tmp_local_is_temp=1\n  fi\n\n  # Size check\n  size=\"$(file_size \"$tmp_local\" 2>/dev/null || echo 0)\"\n  if [ \"$size\" -gt \"$max_bytes\" ]; then\n    log_error \"STAGE\" \"staged payload exceeds max allowed size ($size > $max_bytes)\"\n    [ \"$tmp_local_is_temp\" -eq 1 ] && rm -f -- \"$tmp_local\" 2>/dev/null || true\n    return 1\n  fi\n\n  # Create base64 staging file atomically in workdir\n  tmp_b64=\"$(mktemp \"${workdir%/}/.groq-b64.XXXXXX\" 2>/dev/null || true)\"\n  [ -n \"$tmp_b64\" ] || tmp_b64=\"${workdir%/}/.groq-b64.$$.$RANDOM\"\n  if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n    base64 ${B64_WRAP_OPT} \"$tmp_local\" > \"$tmp_b64\" 2>/dev/null || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  else\n    base64 \"$tmp_local\" > \"$tmp_b64\" 2>/dev/null || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  fi\n  chmod 600 \"$tmp_b64\" 2>/dev/null || true\n\n  # Atomic move into place under lock if available\n  lockfile=\"${workdir%/}/.groqbash.lock\"\n  if type lock_exec >/dev/null 2>&1; then\n    lock_exec \"$lockfile\" 10 -- sh -c 'set -e; mv -f -- \"$1\" \"$2\"; chmod 600 \"$2\" 2>/dev/null || true' _ \"$tmp_b64\" \"$dst\" || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  else\n    mv -f \"$tmp_b64\" \"$dst\" 2>/dev/null || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  fi\n\n  [ \"$tmp_local_is_temp\" -eq 1 ] && rm -f -- \"$tmp_local\" 2>/dev/null || true\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"STAGE\" \"staged base64 payload: $dst (size $(wc -c < \"$dst\" 2>/dev/null)B)\"\n  fi\n  return 0\n}
```

**line_start**: 452  

**body_full**:
```sh
# source: groqbash:452\nstage_b64() {\n  # Dual-mode stage_b64:\n  # - If called with two args: stage_b64 /path/to/src /path/to/dst.b64\n  # - If called with one arg: stage_b64 /path/to/dst.b64  (reads stdin)\n  local src dst max_bytes tmp_local tmp_b64 workdir size b64_opts\n  if [ \"$#\" -eq 2 ]; then\n    src=\"$1\"; dst=\"$2\"\n  elif [ \"$#\" -eq 1 ]; then\n    dst=\"$1\"\n    src=\"\"\n  else\n    log_error \"STAGE\" \"stage_b64 usage: stage_b64 [src] dst\"\n    return 1\n  fi\n\n  max_bytes=\"${MAX_STAGE_BYTES:-10485760}\" # default 10MB\n  [ -n \"$dst\" ] || return 1\n  workdir=\"$(dirname \"$dst\")\"\n  mkdir -p \"$workdir\" 2>/dev/null || { log_error \"STAGE\" \"cannot create workdir $workdir\"; return 1; }\n\n  # If src provided, validate it; else read stdin into tmp_local\n  if [ -n \"$src\" ]; then\n    if [ ! -f \"$src\" ] || [ ! -s \"$src\" ]; then\n      log_error \"STAGE\" \"stage_b64: source payload missing or empty: $src\"\n      return 1\n    fi\n    tmp_local=\"$src\"\n    tmp_local_is_temp=0\n  else\n    tmp_local=\"$(mktemp \"${RUN_TMPDIR%/}/payload.tmp.XXXXXX\" 2>/dev/null || true)\"\n    [ -n \"$tmp_local\" ] || tmp_local=\"${RUN_TMPDIR%/}/payload.tmp.$$\"\n    if ! cat - > \"$tmp_local\" 2>/dev/null; then\n      rm -f -- \"$tmp_local\" 2>/dev/null || true\n      log_error \"STAGE\" \"failed to write staging payload from stdin\"\n      return 1\n    fi\n    tmp_local_is_temp=1\n  fi\n\n  # Size check\n  size=\"$(file_size \"$tmp_local\" 2>/dev/null || echo 0)\"\n  if [ \"$size\" -gt \"$max_bytes\" ]; then\n    log_error \"STAGE\" \"staged payload exceeds max allowed size ($size > $max_bytes)\"\n    [ \"$tmp_local_is_temp\" -eq 1 ] && rm -f -- \"$tmp_local\" 2>/dev/null || true\n    return 1\n  fi\n\n  # Create base64 staging file atomically in workdir\n  tmp_b64=\"$(mktemp \"${workdir%/}/.groq-b64.XXXXXX\" 2>/dev/null || true)\"\n  [ -n \"$tmp_b64\" ] || tmp_b64=\"${workdir%/}/.groq-b64.$$.$RANDOM\"\n  if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n    base64 ${B64_WRAP_OPT} \"$tmp_local\" > \"$tmp_b64\" 2>/dev/null || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  else\n    base64 \"$tmp_local\" > \"$tmp_b64\" 2>/dev/null || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  fi\n  chmod 600 \"$tmp_b64\" 2>/dev/null || true\n\n  # Atomic move into place under lock if available\n  lockfile=\"${workdir%/}/.groqbash.lock\"\n  if type lock_exec >/dev/null 2>&1; then\n    lock_exec \"$lockfile\" 10 -- sh -c 'set -e; mv -f -- \"$1\" \"$2\"; chmod 600 \"$2\" 2>/dev/null || true' _ \"$tmp_b64\" \"$dst\" || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  else\n    mv -f \"$tmp_b64\" \"$dst\" 2>/dev/null || { rm -f -- \"$tmp_local\" \"$tmp_b64\" 2>/dev/null || true; return 1; }\n  fi\n\n  [ \"$tmp_local_is_temp\" -eq 1 ] && rm -f -- \"$tmp_local\" 2>/dev/null || true\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"STAGE\" \"staged base64 payload: $dst (size $(wc -c < \"$dst\" 2>/dev/null)B)\"\n  fi\n  return 0\n}"
```

---

**name**: "tac_fallback"  

**file**: "groqbash"  

**line_range**: "L1161"  

**body_snippet**: 
```sh
# source: groqbash:1161\ntac_fallback() {\n  local f=\"$1\"\n  if command -v tac >/dev/null 2>&1; then\n    tac \"$f\"\n    return $?\n  fi\n  # awk-based fallback: print file in reverse\n  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' \"$f\"\n  return 0\n}
```

**line_start**: 1161  

**body_full**:
```sh
# source: groqbash:1161\ntac_fallback() {\n  local f=\"$1\"\n  if command -v tac >/dev/null 2>&1; then\n    tac \"$f\"\n    return $?\n  fi\n  # awk-based fallback: print file in reverse\n  awk ' { lines[NR] = $0 } END { for (i=NR; i>0; i--) print lines[i] } ' \"$f\"\n  return 0\n}"
```

---

**name**: "ui_state_write"  

**file**: "groqbash"  

**line_range**: "L899"  

**body_snippet**: 
```sh
# source: groqbash:899\nui_state_write() {\n  # Write UI state JSON atomically.\n  # Usage: ui_state_write filename content_string\n  local name=\"$1\"; local content=\"$2\"\n  local dir target\n\n  if [ -n \"${GROQBASH_CONFIG_DIR:-}\" ]; then\n    dir=\"${GROQBASH_CONFIG_DIR%/}/ui_state\"\n  else\n    dir=\"${RUN_TMPDIR%/}/ui_state\"\n  fi\n\n  if [ -z \"${name:-}\" ]; then\n    log_error \"UI_STATE\" \"ui_state_write requires a filename\"\n    return 1\n  fi\n\n  mkdir -p \"$dir\" 2>/dev/null || { log_warn \"UI_STATE\" \"failed to create ui_state dir: $dir\"; return 1; }\n  chmod 700 \"$dir\" 2>/dev/null || true\n  target=\"$dir/$name\"\n\n  # Use atomic_write helper (timeout optional) to write content\n  printf '%s' \"$content\" | atomic_write \"$target\" 10 || { log_warn \"UI_STATE\" \"atomic write failed for $target\"; return 1; }\n  chmod 600 \"$target\" 2>/dev/null || true\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"UI_STATE\" \"wrote $target (size $(wc -c < \"$target\" 2>/dev/null)B)\"\n  fi\n  return 0\n}
```

**line_start**: 899  

**body_full**:
```sh
# source: groqbash:899\nui_state_write() {\n  # Write UI state JSON atomically.\n  # Usage: ui_state_write filename content_string\n  local name=\"$1\"; local content=\"$2\"\n  local dir target\n\n  if [ -n \"${GROQBASH_CONFIG_DIR:-}\" ]; then\n    dir=\"${GROQBASH_CONFIG_DIR%/}/ui_state\"\n  else\n    dir=\"${RUN_TMPDIR%/}/ui_state\"\n  fi\n\n  if [ -z \"${name:-}\" ]; then\n    log_error \"UI_STATE\" \"ui_state_write requires a filename\"\n    return 1\n  fi\n\n  mkdir -p \"$dir\" 2>/dev/null || { log_warn \"UI_STATE\" \"failed to create ui_state dir: $dir\"; return 1; }\n  chmod 700 \"$dir\" 2>/dev/null || true\n  target=\"$dir/$name\"\n\n  # Use atomic_write helper (timeout optional) to write content\n  printf '%s' \"$content\" | atomic_write \"$target\" 10 || { log_warn \"UI_STATE\" \"atomic write failed for $target\"; return 1; }\n  chmod 600 \"$target\" 2>/dev/null || true\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"UI_STATE\" \"wrote $target (size $(wc -c < \"$target\" 2>/dev/null)B)\"\n  fi\n  return 0\n}"
```

---

**name**: "write_provider_url_if_missing"  

**file**: "groqbash"  

**line_range**: "L269"  

**body_snippet**: 
```sh
# source: groqbash:269\nwrite_provider_url_if_missing() {\n  local prov=\"$1\" url=\"$2\" file dir tmp\n  [ -z \"$prov\" ] && return 1\n  [ -z \"$url\" ] && return 1\n  file=\"$(canonical_provider_url_file)\"\n  dir=\"$(dirname \"$file\")\"\n  mkdir -p \"$dir\" 2>/dev/null || return 1\n  # If file already exists and non-empty, do nothing\n  if [ -f \"$file\" ] && [ -s \"$file\" ]; then\n    return 0\n  fi\n  # Write atomically into RUN_TMPDIR if available, else directly (best-effort)\n  if [ -n \"${RUN_TMPDIR:-}\" ] && [ -d \"${RUN_TMPDIR:-}\" ]; then\n    tmp=\"$(mktemp -p \"${RUN_TMPDIR}\" provider-url.XXXX 2>/dev/null || true)\"\n  else\n    tmp=\"$(mktemp 2>/dev/null || true)\"\n  fi\n  if [ -n \"$tmp\" ]; then\n    printf '%s\\n' \"$url\" > \"$tmp\"\n    mv -f \"$tmp\" \"$file\" 2>/dev/null || cp -f \"$tmp\" \"$file\" 2>/dev/null || { rm -f \"$tmp\" 2>/dev/null || true; return 1; }\n    chmod 600 \"$file\" 2>/dev/null || true\n    return 0\n  else\n    # fallback: write directly\n    printf '%s\\n' \"$url\" > \"$file\" 2>/dev/null || return 1\n    chmod 600 \"$file\" 2>/dev/null || true\n    return 0\n  fi\n}
```

**line_start**: 269  

**body_full**:
```sh
# source: groqbash:269\nwrite_provider_url_if_missing() {\n  local prov=\"$1\" url=\"$2\" file dir tmp\n  [ -z \"$prov\" ] && return 1\n  [ -z \"$url\" ] && return 1\n  file=\"$(canonical_provider_url_file)\"\n  dir=\"$(dirname \"$file\")\"\n  mkdir -p \"$dir\" 2>/dev/null || return 1\n  # If file already exists and non-empty, do nothing\n  if [ -f \"$file\" ] && [ -s \"$file\" ]; then\n    return 0\n  fi\n  # Write atomically into RUN_TMPDIR if available, else directly (best-effort)\n  if [ -n \"${RUN_TMPDIR:-}\" ] && [ -d \"${RUN_TMPDIR:-}\" ]; then\n    tmp=\"$(mktemp -p \"${RUN_TMPDIR}\" provider-url.XXXX 2>/dev/null || true)\"\n  else\n    tmp=\"$(mktemp 2>/dev/null || true)\"\n  fi\n  if [ -n \"$tmp\" ]; then\n    printf '%s\\n' \"$url\" > \"$tmp\"\n    mv -f \"$tmp\" \"$file\" 2>/dev/null || cp -f \"$tmp\" \"$file\" 2>/dev/null || { rm -f \"$tmp\" 2>/dev/null || true; return 1; }\n    chmod 600 \"$file\" 2>/dev/null || true\n    return 0\n  else\n    # fallback: write directly\n    printf '%s\\n' \"$url\" > \"$file\" 2>/dev/null || return 1\n    chmod 600 \"$file\" 2>/dev/null || true\n    return 0\n  fi\n}"
```

---

### SECTION: PRECORE_RUN

---

**name**: "_get_file_signature"  

**file**: "groqbash"  

**line_range**: "L1471"  

**body_snippet**: 
```sh
# source: groqbash:1471\n_get_file_signature() {\n  local path=\"$1\"\n  local hash=\"\" stat_out=\"\" dev=\"\" inode=\"\" size=\"\" ctime=\"\" mtime=\"\" uid=\"\" gid=\"\" mode=\"\"\n  # Return empty string if not a regular file\n  [ -f \"$path\" ] || { printf ''; return 0; }\n\n  # Decide whether to compute content hash (default 1)\n  local use_hash=\"${GROQBASH_SIG_HASH:-1}\"\n\n  # Compute SHA256 if requested and available\n  if [ \"${use_hash}\" != \"0\" ] && command -v sha256sum >/dev/null 2>&1; then\n    hash=\"$(sha256sum \"$path\" 2>/dev/null | awk '{print $1}' || true)\"\n  else\n    hash=\"\"\n  fi\n\n  # Collect stat output in a portable way\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin)\n      # BSD/macOS stat format: device inode size ctime mtime uid gid mode\n      stat_out=\"$(stat -f '%d %i %z %c %m %u %g %p' \"$path\" 2>/dev/null || true)\"\n      ;;\n    *)\n      # GNU stat format: device inode size ctime mtime uid gid mode\n      stat_out=\"$(stat -c '%d %i %s %Z %Y %u %g %a' \"$path\" 2>/dev/null || true)\"\n      ;;\n  esac\n\n  # If stat failed, ensure variables are empty and continue (do not abort)\n  if [ -z \"${stat_out:-}\" ]; then\n    dev=\"\"; inode=\"\"; size=\"\"; ctime=\"\"; mtime=\"\"; uid=\"\"; gid=\"\"; mode=\"\"\n  else\n    # Parse stat_out using a here-doc to avoid process substitution portability issues\n    read -r dev inode size ctime mtime uid gid mode <<EOF\n$stat_out\nEOF\n    # If read failed for any reason, reset to empty strings\n    if [ -z \"${dev:-}\" ] && [ -z \"${inode:-}\" ] && [ -z \"${size:-}\" ]; then\n      dev=\"\"; inode=\"\"; size=\"\"; ctime=\"\"; mtime=\"\"; uid=\"\"; gid=\"\"; mode=\"\"\n    fi\n  fi\n\n  # Output a stable, linear signature: hash|dev|inode|size|ctime|mtime|uid|gid|mode\n  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s' \\\n    \"${hash:-}\" \"${dev:-}\" \"${inode:-}\" \"${size:-}\" \"${ctime:-}\" \"${mtime:-}\" \"${uid:-}\" \"${gid:-}\" \"${mode:-}\"\n}
```

**line_start**: 1471  

**body_full**:
```sh
# source: groqbash:1471\n_get_file_signature() {\n  local path=\"$1\"\n  local hash=\"\" stat_out=\"\" dev=\"\" inode=\"\" size=\"\" ctime=\"\" mtime=\"\" uid=\"\" gid=\"\" mode=\"\"\n  # Return empty string if not a regular file\n  [ -f \"$path\" ] || { printf ''; return 0; }\n\n  # Decide whether to compute content hash (default 1)\n  local use_hash=\"${GROQBASH_SIG_HASH:-1}\"\n\n  # Compute SHA256 if requested and available\n  if [ \"${use_hash}\" != \"0\" ] && command -v sha256sum >/dev/null 2>&1; then\n    hash=\"$(sha256sum \"$path\" 2>/dev/null | awk '{print $1}' || true)\"\n  else\n    hash=\"\"\n  fi\n\n  # Collect stat output in a portable way\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin)\n      # BSD/macOS stat format: device inode size ctime mtime uid gid mode\n      stat_out=\"$(stat -f '%d %i %z %c %m %u %g %p' \"$path\" 2>/dev/null || true)\"\n      ;;\n    *)\n      # GNU stat format: device inode size ctime mtime uid gid mode\n      stat_out=\"$(stat -c '%d %i %s %Z %Y %u %g %a' \"$path\" 2>/dev/null || true)\"\n      ;;\n  esac\n\n  # If stat failed, ensure variables are empty and continue (do not abort)\n  if [ -z \"${stat_out:-}\" ]; then\n    dev=\"\"; inode=\"\"; size=\"\"; ctime=\"\"; mtime=\"\"; uid=\"\"; gid=\"\"; mode=\"\"\n  else\n    # Parse stat_out using a here-doc to avoid process substitution portability issues\n    read -r dev inode size ctime mtime uid gid mode <<EOF\n$stat_out\nEOF\n    # If read failed for any reason, reset to empty strings\n    if [ -z \"${dev:-}\" ] && [ -z \"${inode:-}\" ] && [ -z \"${size:-}\" ]; then\n      dev=\"\"; inode=\"\"; size=\"\"; ctime=\"\"; mtime=\"\"; uid=\"\"; gid=\"\"; mode=\"\"\n    fi\n  fi\n\n  # Output a stable, linear signature: hash|dev|inode|size|ctime|mtime|uid|gid|mode\n  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s' \\\n    \"${hash:-}\" \"${dev:-}\" \"${inode:-}\" \"${size:-}\" \"${ctime:-}\" \"${mtime:-}\" \"${uid:-}\" \"${gid:-}\" \"${mode:-}\"\n}"
```

---

**name**: "_get_owner"  

**file**: "groqbash"  

**line_range**: "L1462"  

**body_snippet**: 
```sh
# source: groqbash:1462\n_get_owner() {\n  local path=\"$1\" owner=\"\"\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) owner=\"$(stat -f %Su \"$path\" 2>/dev/null || true)\" ;;\n    *) if command -v stat >/dev/null 2>&1; then owner=\"$(stat -c %U \"$path\" 2>/dev/null || true)\"; elif command -v find >/dev/null 2>&1; then owner=\"$(find \"$path\" -maxdepth 0 -printf '%u' 2>/dev/null || true)\"; fi ;;\n  esac\n  printf '%s' \"$owner\"\n}
```

**line_start**: 1462  

**body_full**:
```sh
# source: groqbash:1462\n_get_owner() {\n  local path=\"$1\" owner=\"\"\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) owner=\"$(stat -f %Su \"$path\" 2>/dev/null || true)\" ;;\n    *) if command -v stat >/dev/null 2>&1; then owner=\"$(stat -c %U \"$path\" 2>/dev/null || true)\"; elif command -v find >/dev/null 2>&1; then owner=\"$(find \"$path\" -maxdepth 0 -printf '%u' 2>/dev/null || true)\"; fi ;;\n  esac\n  printf '%s' \"$owner\"\n}"
```

---

**name**: "_get_perm_string"  

**file**: "groqbash"  

**line_range**: "L1453"  

**body_snippet**: 
```sh
# source: groqbash:1453\n_get_perm_string() {\n  local path=\"$1\" perm=\"\"\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) perm=\"$(stat -f %Sp \"$path\" 2>/dev/null || true)\" ;;\n    *) if command -v stat >/dev/null 2>&1; then perm=\"$(stat -c %A \"$path\" 2>/dev/null || true)\"; elif command -v find >/dev/null 2>&1; then perm=\"$(find \"$path\" -maxdepth 0 -printf '%M' 2>/dev/null || true)\"; fi ;;\n  esac\n  printf '%s' \"$perm\"\n}
```

**line_start**: 1453  

**body_full**:
```sh
# source: groqbash:1453\n_get_perm_string() {\n  local path=\"$1\" perm=\"\"\n  case \"$(uname 2>/dev/null || echo Linux)\" in\n    Darwin) perm=\"$(stat -f %Sp \"$path\" 2>/dev/null || true)\" ;;\n    *) if command -v stat >/dev/null 2>&1; then perm=\"$(stat -c %A \"$path\" 2>/dev/null || true)\"; elif command -v find >/dev/null 2>&1; then perm=\"$(find \"$path\" -maxdepth 0 -printf '%M' 2>/dev/null || true)\"; fi ;;\n  esac\n  printf '%s' \"$perm\"\n}"
```

---

**name**: "_is_world_writable"  

**file**: "groqbash"  

**line_range**: "L1520"  

**body_snippet**: 
```sh
# source: groqbash:1520\n_is_world_writable() {\n  local d=\"$1\" perms others_write\n  [ -d \"$d\" ] || return \"$GROQBASHERRTMP\"\n  perms=\"$(_get_perm_string \"$d\")\"\n  [ -z \"$perms\" ] && return \"$GROQBASHERRTMP\"\n  others_write=\"$(printf '%s' \"$perms\" | awk '{print substr($0,9,1)}')\"\n  [ \"$others_write\" = \"w\" ]\n}
```

**line_start**: 1520  

**body_full**:
```sh
# source: groqbash:1520\n_is_world_writable() {\n  local d=\"$1\" perms others_write\n  [ -d \"$d\" ] || return \"$GROQBASHERRTMP\"\n  perms=\"$(_get_perm_string \"$d\")\"\n  [ -z \"$perms\" ] && return \"$GROQBASHERRTMP\"\n  others_write=\"$(printf '%s' \"$perms\" | awk '{print substr($0,9,1)}')\"\n  [ \"$others_write\" = \"w\" ]\n}"
```

---

**name**: "_normalize_bool_env"  

**file**: "groqbash"  

**line_range**: "L2130"  

**body_snippet**: 
```sh
# source: groqbash:2130\n_normalize_bool_env() {\n  local var val\n  for var in ALLOW_API_CALLS DRY_RUN DEBUG; do\n    val=\"${!var:-}\"\n    if [ -n \"$val\" ]; then\n      if is_truthy \"$val\"; then\n        export \"$var\"=1\n      else\n        export \"$var\"=0\n      fi\n    fi\n  done\n}
```

**line_start**: 2130  

**body_full**:
```sh
# source: groqbash:2130\n_normalize_bool_env() {\n  local var val\n  for var in ALLOW_API_CALLS DRY_RUN DEBUG; do\n    val=\"${!var:-}\"\n    if [ -n \"$val\" ]; then\n      if is_truthy \"$val\"; then\n        export \"$var\"=1\n      else\n        export \"$var\"=0\n      fi\n    fi\n  done\n}"
```

---

**name**: "_session_hash"  

**file**: "groqbash"  

**line_range**: "L1989"  

**body_snippet**: 
```sh
# source: groqbash:1989\n_session_hash() {\n  local s=\"$1\" h=\"\"\n  if command -v sha256sum >/dev/null 2>&1; then\n    h=\"$(printf '%s' \"$s\" | sha256sum 2>/dev/null | awk '{print $1}' || true)\"\n  elif command -v openssl >/dev/null 2>&1; then\n    h=\"$(printf '%s' \"$s\" | openssl dgst -sha256 2>/dev/null | awk '{print $2}' || true)\"\n  else\n    # fallback: base64 of string (not cryptographic but stable)\n    h=\"$(printf '%s' \"$s\" | base64 | tr -d '\\n' | cut -c1-64)\"\n  fi\n  printf '%s' \"${h:-}\"\n}
```

**line_start**: 1989  

**body_full**:
```sh
# source: groqbash:1989\n_session_hash() {\n  local s=\"$1\" h=\"\"\n  if command -v sha256sum >/dev/null 2>&1; then\n    h=\"$(printf '%s' \"$s\" | sha256sum 2>/dev/null | awk '{print $1}' || true)\"\n  elif command -v openssl >/dev/null 2>&1; then\n    h=\"$(printf '%s' \"$s\" | openssl dgst -sha256 2>/dev/null | awk '{print $2}' || true)\"\n  else\n    # fallback: base64 of string (not cryptographic but stable)\n    h=\"$(printf '%s' \"$s\" | base64 | tr -d '\\n' | cut -c1-64)\"\n  fi\n  printf '%s' \"${h:-}\"\n}"
```

---

**name**: "_tmpf"  

**file**: "groqbash"  

**line_range**: "L1555"  

**body_snippet**: 
```sh
# source: groqbash:1555\n_tmpf() {\n  local mode=\"$1\" base=\"$2\" prefix=\"${3:-groq}\" tmp\n  if [ -z \"$mode\" ] || [ -z \"$base\" ]; then\n    log_error \"TMP\" \"_tmpf usage: _tmpf <file|dir> <base_dir> [prefix]\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  # Prefer provided base, else GROQBASH_TMPDIR\n  if [ -z \"$base\" ] || [ ! -d \"$base\" ]; then\n    base=\"${GROQBASH_TMPDIR:-}\"\n  fi\n  if [ -z \"$base\" ] || [ ! -d \"$base\" ]; then\n    log_error \"TMP\" \"tmp base directory not available: $base\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  # Ensure base is inside GROQBASH_TMPDIR for safety\n  case \"$base\" in\n    \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\") ;;\n    *)\n      # If base is not under GROQBASH_TMPDIR, prefer GROQBASH_TMPDIR\n      base=\"${GROQBASH_TMPDIR:-$base}\"\n      ;;\n  esac\n\n  umask 077\n  if [ \"$mode\" = \"file\" ]; then\n    tmp=\"$(mktemp -p \"$base\" \"${prefix}.XXXX\" 2>/dev/null || true)\"\n    if [ -z \"$tmp\" ]; then\n      tmp=\"${base%/}/${prefix}.$$.$RANDOM\"\n      : > \"$tmp\" 2>/dev/null || true\n    fi\n    chmod 600 \"$tmp\" 2>/dev/null || true\n    printf '%s' \"$tmp\"\n    return 0\n  elif [ \"$mode\" = \"dir\" ]; then\n    tmp=\"$(mktemp -d -p \"$base\" \"${prefix}.XXXX\" 2>/dev/null || true)\"\n    if [ -z \"$tmp\" ]; then\n      tmp=\"${base%/}/${prefix}.$$.$RANDOM\"\n      mkdir -p \"$tmp\" 2>/dev/null || true\n    fi\n    chmod 700 \"$tmp\" 2>/dev/null || true\n    printf '%s' \"$tmp\"\n    return 0\n  else\n    log_error \"TMP\" \"_tmpf: unknown mode: $mode\"\n    return \"$GROQBASHERRTMP\"\n  fi\n}
```

**line_start**: 1555  

**body_full**:
```sh
# source: groqbash:1555\n_tmpf() {\n  local mode=\"$1\" base=\"$2\" prefix=\"${3:-groq}\" tmp\n  if [ -z \"$mode\" ] || [ -z \"$base\" ]; then\n    log_error \"TMP\" \"_tmpf usage: _tmpf <file|dir> <base_dir> [prefix]\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  # Prefer provided base, else GROQBASH_TMPDIR\n  if [ -z \"$base\" ] || [ ! -d \"$base\" ]; then\n    base=\"${GROQBASH_TMPDIR:-}\"\n  fi\n  if [ -z \"$base\" ] || [ ! -d \"$base\" ]; then\n    log_error \"TMP\" \"tmp base directory not available: $base\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  # Ensure base is inside GROQBASH_TMPDIR for safety\n  case \"$base\" in\n    \"$GROQBASH_TMPDIR\"/*|\"$GROQBASH_TMPDIR\") ;;\n    *)\n      # If base is not under GROQBASH_TMPDIR, prefer GROQBASH_TMPDIR\n      base=\"${GROQBASH_TMPDIR:-$base}\"\n      ;;\n  esac\n\n  umask 077\n  if [ \"$mode\" = \"file\" ]; then\n    tmp=\"$(mktemp -p \"$base\" \"${prefix}.XXXX\" 2>/dev/null || true)\"\n    if [ -z \"$tmp\" ]; then\n      tmp=\"${base%/}/${prefix}.$$.$RANDOM\"\n      : > \"$tmp\" 2>/dev/null || true\n    fi\n    chmod 600 \"$tmp\" 2>/dev/null || true\n    printf '%s' \"$tmp\"\n    return 0\n  elif [ \"$mode\" = \"dir\" ]; then\n    tmp=\"$(mktemp -d -p \"$base\" \"${prefix}.XXXX\" 2>/dev/null || true)\"\n    if [ -z \"$tmp\" ]; then\n      tmp=\"${base%/}/${prefix}.$$.$RANDOM\"\n      mkdir -p \"$tmp\" 2>/dev/null || true\n    fi\n    chmod 700 \"$tmp\" 2>/dev/null || true\n    printf '%s' \"$tmp\"\n    return 0\n  else\n    log_error \"TMP\" \"_tmpf: unknown mode: $mode\"\n    return \"$GROQBASHERRTMP\"\n  fi\n}"
```

---

**name**: "getfile_signature"  

**file**: "groqbash"  

**line_range**: "L1518"  

**body_snippet**: 
```sh
# source: groqbash:1518\ngetfile_signature() { _get_file_signature \"$1\"; }
```

**line_start**: 1518  

**body_full**:
```sh
# source: groqbash:1518\ngetfile_signature() { _get_file_signature \"$1\"; }"
```

---

**name**: "make_tmpdir"  

**file**: "groqbash"  

**line_range**: "L1530"  

**body_snippet**: 
```sh
# source: groqbash:1530\nmake_tmpdir() {\n  umask 077\n  local tmpd lockfile\n  lockfile=\"$TMP_LOCK\"\n  mkdir -p \"$GROQBASH_TMPDIR\" 2>/dev/null || return \"$GROQBASHERRTMP\"\n  lock_exec \"$lockfile\" \"$GROQBASH_LOCK_TIMEOUT_TMP\" -- sh -c '\n    set -e\n    base=\"$1\"\n    tmpd=\"$(mktemp -d -p \"$base\" groq.XXXX 2>/dev/null || true)\"\n    if [ -z \"$tmpd\" ]; then\n      tmpd=\"$base/groq.$$.$RANDOM\"\n      mkdir -p \"$tmpd\"\n    fi\n    chmod 700 \"$tmpd\" 2>/dev/null || true\n    printf \"%s\" \"$tmpd\"\n  ' _ \"$GROQBASH_TMPDIR\"\n  return $?\n}
```

**line_start**: 1530  

**body_full**:
```sh
# source: groqbash:1530\nmake_tmpdir() {\n  umask 077\n  local tmpd lockfile\n  lockfile=\"$TMP_LOCK\"\n  mkdir -p \"$GROQBASH_TMPDIR\" 2>/dev/null || return \"$GROQBASHERRTMP\"\n  lock_exec \"$lockfile\" \"$GROQBASH_LOCK_TIMEOUT_TMP\" -- sh -c '\n    set -e\n    base=\"$1\"\n    tmpd=\"$(mktemp -d -p \"$base\" groq.XXXX 2>/dev/null || true)\"\n    if [ -z \"$tmpd\" ]; then\n      tmpd=\"$base/groq.$$.$RANDOM\"\n      mkdir -p \"$tmpd\"\n    fi\n    chmod 700 \"$tmpd\" 2>/dev/null || true\n    printf \"%s\" \"$tmpd\"\n  ' _ \"$GROQBASH_TMPDIR\"\n  return $?\n}"
```

---

**name**: "manifest_add_part"  

**file**: "groqbash"  

**line_range**: "L1378"  

**body_snippet**: 
```sh
# source: groqbash:1378\nmanifest_add_part() {\n  local manifest=\"$1\" name=\"$2\" file_path=\"$3\" mime=\"$4\" timeout=\"${5:-$GROQBASH_LOCK_TIMEOUT_MODELS}\"\n  [ -f \"$file_path\" ] || { log_error \"MANIFESTFAIL\" \"manifest_add_part: file not found: $file_path\"; return 1; }\n  mkdir -p \"$(dirname \"$manifest\")\" 2>/dev/null || true\n\n  # Ensure a lockfile specific to this manifest (avoid global contention)\n  lockfile=\"${manifest}.lock\"\n\n  # First, stage the part as a base64 file in the manifest directory (atomic in destdir)\n  local destdir part_b64 tmpstamp tmp_part\n  destdir=\"$(dirname \"$manifest\")\"\n  tmpstamp=\"$(date +%s)-$$\"\n  part_b64=\"$destdir/parts-$(basename \"$file_path\").${tmpstamp}.b64\"\n  tmp_part=\"$GROQBASH_TMPDIR/part.tmp.$$\"\n\n  # write base64 staging atomically into RUN tmp then move into destdir\n  if ! b64encode < \"$file_path\" > \"$tmp_part\"; then\n    rm -f \"$tmp_part\" 2>/dev/null || true\n    log_error \"B64FAIL\" \"manifest_add_part: b64 encode failed\"\n    return 1\n  fi\n  mv -f \"$tmp_part\" \"$part_b64\" 2>/dev/null || { rm -f \"$tmp_part\" 2>/dev/null || true; log_error \"MANIFESTFAIL\" \"cannot move staged part to $part_b64\"; return 1; }\n  chmod 600 \"$part_b64\" 2>/dev/null || true\n\n  # Now update manifest atomically under lock using jq --arg\n  lock_exec \"$lockfile\" \"$timeout\" -- sh -c '\n    set -e\n    manifest=\"$1\"\n    part_b64=\"$2\"\n    name=\"$3\"\n    mime=\"$4\"\n    tmp=\"$(mktemp -p \"$(dirname \"$manifest\")\" manifest.edit.XXXX)\"\n    if [ -f \"${manifest}.b64\" ]; then\n      # decode base64 staging to tmp using exported decode opt\n      base64 ${B64_DECODE_OPT} < \"${manifest}.b64\" > \"$tmp\" 2>/dev/null || printf \"%s\" \"{\\\"parts\\\":[]}\" > \"$tmp\"\n    elif [ -f \"$manifest\" ]; then\n      cp -f \"$manifest\" \"$tmp\"\n    else\n      printf \"%s\" \"{\\\"parts\\\":[]}\" > \"$tmp\"\n    fi\n    jq --arg name \"$name\" --arg path \"$part_b64\" --arg enc \"b64\" --arg type \"$mime\" \\\n       \".parts += [{name:\\$name, path:\\$path, encoding:\\$enc, type:\\$type}]\" \"$tmp\" > \"${tmp}.new\"\n    mv -f \"${tmp}.new\" \"$tmp\"\n    # write back both manifest and base64 staging atomically\n    if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n      base64 ${B64_WRAP_OPT} \"$tmp\" > \"${manifest}.b64\"\n    else\n      base64 \"$tmp\" | tr -d \"\\n\" > \"${manifest}.b64\"\n    fi\n    cp -f \"$tmp\" \"$manifest\"\n    chmod 600 \"$manifest\" 2>/dev/null || true\n    rm -f \"$tmp\" 2>/dev/null || true\n  ' _ \"$manifest\" \"$part_b64\" \"$name\" \"$mime\" || { log_error \"MANIFESTFAIL\" \"manifest_add_part: update failed\"; return 1; }\n\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"MANIFEST_ADD\" \"added part $name -> $part_b64\"\n  fi\n  return 0\n}
```

**line_start**: 1378  

**body_full**:
```sh
# source: groqbash:1378\nmanifest_add_part() {\n  local manifest=\"$1\" name=\"$2\" file_path=\"$3\" mime=\"$4\" timeout=\"${5:-$GROQBASH_LOCK_TIMEOUT_MODELS}\"\n  [ -f \"$file_path\" ] || { log_error \"MANIFESTFAIL\" \"manifest_add_part: file not found: $file_path\"; return 1; }\n  mkdir -p \"$(dirname \"$manifest\")\" 2>/dev/null || true\n\n  # Ensure a lockfile specific to this manifest (avoid global contention)\n  lockfile=\"${manifest}.lock\"\n\n  # First, stage the part as a base64 file in the manifest directory (atomic in destdir)\n  local destdir part_b64 tmpstamp tmp_part\n  destdir=\"$(dirname \"$manifest\")\"\n  tmpstamp=\"$(date +%s)-$$\"\n  part_b64=\"$destdir/parts-$(basename \"$file_path\").${tmpstamp}.b64\"\n  tmp_part=\"$GROQBASH_TMPDIR/part.tmp.$$\"\n\n  # write base64 staging atomically into RUN tmp then move into destdir\n  if ! b64encode < \"$file_path\" > \"$tmp_part\"; then\n    rm -f \"$tmp_part\" 2>/dev/null || true\n    log_error \"B64FAIL\" \"manifest_add_part: b64 encode failed\"\n    return 1\n  fi\n  mv -f \"$tmp_part\" \"$part_b64\" 2>/dev/null || { rm -f \"$tmp_part\" 2>/dev/null || true; log_error \"MANIFESTFAIL\" \"cannot move staged part to $part_b64\"; return 1; }\n  chmod 600 \"$part_b64\" 2>/dev/null || true\n\n  # Now update manifest atomically under lock using jq --arg\n  lock_exec \"$lockfile\" \"$timeout\" -- sh -c '\n    set -e\n    manifest=\"$1\"\n    part_b64=\"$2\"\n    name=\"$3\"\n    mime=\"$4\"\n    tmp=\"$(mktemp -p \"$(dirname \"$manifest\")\" manifest.edit.XXXX)\"\n    if [ -f \"${manifest}.b64\" ]; then\n      # decode base64 staging to tmp using exported decode opt\n      base64 ${B64_DECODE_OPT} < \"${manifest}.b64\" > \"$tmp\" 2>/dev/null || printf \"%s\" \"{\\\"parts\\\":[]}\" > \"$tmp\"\n    elif [ -f \"$manifest\" ]; then\n      cp -f \"$manifest\" \"$tmp\"\n    else\n      printf \"%s\" \"{\\\"parts\\\":[]}\" > \"$tmp\"\n    fi\n    jq --arg name \"$name\" --arg path \"$part_b64\" --arg enc \"b64\" --arg type \"$mime\" \\\n       \".parts += [{name:\\$name, path:\\$path, encoding:\\$enc, type:\\$type}]\" \"$tmp\" > \"${tmp}.new\"\n    mv -f \"${tmp}.new\" \"$tmp\"\n    # write back both manifest and base64 staging atomically\n    if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n      base64 ${B64_WRAP_OPT} \"$tmp\" > \"${manifest}.b64\"\n    else\n      base64 \"$tmp\" | tr -d \"\\n\" > \"${manifest}.b64\"\n    fi\n    cp -f \"$tmp\" \"$manifest\"\n    chmod 600 \"$manifest\" 2>/dev/null || true\n    rm -f \"$tmp\" 2>/dev/null || true\n  ' _ \"$manifest\" \"$part_b64\" \"$name\" \"$mime\" || { log_error \"MANIFESTFAIL\" \"manifest_add_part: update failed\"; return 1; }\n\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"MANIFEST_ADD\" \"added part $name -> $part_b64\"\n  fi\n  return 0\n}"
```

---

**name**: "manifest_create"  

**file**: "groqbash"  

**line_range**: "L1356"  

**body_snippet**: 
```sh
# source: groqbash:1356\nmanifest_create() {\n  local manifest=\"$1\"\n  local timeout=\"${2:-$GROQBASH_LOCK_TIMEOUT_MODELS}\"\n  mkdir -p \"$(dirname \"$manifest\")\" 2>/dev/null || { log_error \"MANIFESTFAIL\" \"manifest_create: cannot create dir\"; return 1; }\n  lock_exec \"${manifest}.lock\" \"$timeout\" -- sh -c '\n   set -e\n   manifest=\"$1\"\n   tmp=\"$(mktemp -p \"$(dirname \"$manifest\")\" manifest.tmp.XXXX)\"\n   printf \"%s\" \"{\\\"parts\\\":[]}\" > \"$tmp\"\n   # write base64 staging using base64 binary and exported opts\n   if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n     base64 ${B64_WRAP_OPT} \"$tmp\" > \"${manifest}.b64\"\n   else\n     base64 \"$tmp\" | tr -d \"\\n\" > \"${manifest}.b64\"\n   fi\n   mv -f \"$tmp\" \"$manifest\"\n   chmod 600 \"$manifest\" 2>/dev/null || true\n ' _ \"$manifest\"\n\n  return $?\n}
```

**line_start**: 1356  

**body_full**:
```sh
# source: groqbash:1356\nmanifest_create() {\n  local manifest=\"$1\"\n  local timeout=\"${2:-$GROQBASH_LOCK_TIMEOUT_MODELS}\"\n  mkdir -p \"$(dirname \"$manifest\")\" 2>/dev/null || { log_error \"MANIFESTFAIL\" \"manifest_create: cannot create dir\"; return 1; }\n  lock_exec \"${manifest}.lock\" \"$timeout\" -- sh -c '\n   set -e\n   manifest=\"$1\"\n   tmp=\"$(mktemp -p \"$(dirname \"$manifest\")\" manifest.tmp.XXXX)\"\n   printf \"%s\" \"{\\\"parts\\\":[]}\" > \"$tmp\"\n   # write base64 staging using base64 binary and exported opts\n   if [ -n \"${B64_WRAP_OPT:-}\" ]; then\n     base64 ${B64_WRAP_OPT} \"$tmp\" > \"${manifest}.b64\"\n   else\n     base64 \"$tmp\" | tr -d \"\\n\" > \"${manifest}.b64\"\n   fi\n   mv -f \"$tmp\" \"$manifest\"\n   chmod 600 \"$manifest\" 2>/dev/null || true\n ' _ \"$manifest\"\n\n  return $?\n}"
```

---

**name**: "manifest_read"  

**file**: "groqbash"  

**line_range**: "L1438"  

**body_snippet**: 
```sh
# source: groqbash:1438\nmanifest_read() {\n  local manifest=\"$1\"\n  if [ -f \"$manifest\" ]; then\n    cat \"$manifest\"\n    return 0\n  fi\n  if [ -f \"${manifest}.b64\" ]; then\n    b64decode < \"${manifest}.b64\"\n    return $?\n  fi\n  return 1\n}
```

**line_start**: 1438  

**body_full**:
```sh
# source: groqbash:1438\nmanifest_read() {\n  local manifest=\"$1\"\n  if [ -f \"$manifest\" ]; then\n    cat \"$manifest\"\n    return 0\n  fi\n  if [ -f \"${manifest}.b64\" ]; then\n    b64decode < \"${manifest}.b64\"\n    return $?\n  fi\n  return 1\n}"
```

---

**name**: "rotate_history"  

**file**: "groqbash"  

**line_range**: "L1226"  

**body_snippet**: 
```sh
# source: groqbash:1226\nrotate_history() {\n  local timeout=\"${1:-$GROQBASH_LOCK_TIMEOUT_HISTORY}\"\n  local dir=\"${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}\"\n  local max_files=\"${GROQBASH_HISTORY_MAX_FILES:-100}\"\n  local max_bytes=\"${GROQBASH_HISTORY_MAX_BYTES:-104857600}\"\n  local keep_days=\"${GROQBASH_HISTORY_KEEP_DAYS:-90}\"\n\n  lock_exec \"${HISTORY_LOCK}\" \"$timeout\" -- sh -c '\n    set -e\n    dir=\"$1\"\n    max_files=\"$2\"\n    max_bytes=\"$3\"\n    keep_days=\"$4\"\n\n    # Remove files older than keep_days first\n    find \"$dir\" -type f -mtime +\"$keep_days\" -print0 | xargs -0 -r rm -f --\n\n    # Compute total bytes and remove oldest until under threshold\n    while :; do\n      total=0\n      # Build list of files with mtime and size\n      files_list=\"$(mktemp -p \"$(dirname \"$dir\")\" groq-rot.XXXX 2>/dev/null || true)\"\n      if [ -z \"$files_list\" ]; then\n        files_list=\"/tmp/groq-rot.$$\"\n      fi\n      : > \"$files_list\"\n      find \"$dir\" -type f -print0 2>/dev/null | while IFS= read -r -d \"\" f; do\n        if [ -f \"$f\" ]; then\n          # portable size\n          case \"$(uname 2>/dev/null || echo Linux)\" in\n            Darwin) size=\"$(stat -f %z \"$f\" 2>/dev/null || echo 0)\" ;;\n            *) size=\"$(stat -c %s \"$f\" 2>/dev/null || echo 0)\" ;;\n          esac\n          mtime=0\n          case \"$(uname 2>/dev/null || echo Linux)\" in\n            Darwin) mtime=\"$(stat -f %m \"$f\" 2>/dev/null || echo 0)\" ;;\n            *) mtime=\"$(stat -c %Y \"$f\" 2>/dev/null || echo 0)\" ;;\n          esac\n          printf \"%s|%s|%s\\n\" \"$mtime\" \"$size\" \"$f\" >> \"$files_list\"\n        fi\n      done\n\n      # Sum sizes\n      if [ -s \"$files_list\" ]; then\n        while IFS='|' read -r mtime size path; do\n          total=$((total + (size + 0)))\n        done < \"$files_list\"\n      fi\n\n      # If under limit, break\n      if [ \"$total\" -le \"$max_bytes\" ]; then\n        rm -f \"$files_list\" 2>/dev/null || true\n        break\n      fi\n\n      # Remove oldest file\n      oldest=\"$(sort -n \"$files_list\" | head -n1 | awk -F\"|\" '\\''{print $3}'\\'')\"\n      if [ -z \"$oldest\" ]; then\n        rm -f \"$files_list\" 2>/dev/null || true\n        break\n      fi\n      rm -f -- \"$oldest\" 2>/dev/null || true\n      rm -f \"$files_list\" 2>/dev/null || true\n    done\n\n    # Enforce max files count\n    while :; do\n      count=$(find \"$dir\" -type f 2>/dev/null | wc -l | tr -d \" \")\n      if [ \"$count\" -le \"$max_files\" ]; then break; fi\n      # find oldest and remove\n      oldest=\"$(find \"$dir\" -type f -printf \"%T@ %p\\n\" 2>/dev/null | sort -n | head -n1 | awk '\\''{print $2}'\\'')\"\n      [ -z \"$oldest\" ] && break\n      rm -f -- \"$oldest\" 2>/dev/null || true\n    done\n  ' _ \"$dir\" \"$max_files\" \"$max_bytes\" \"$keep_days\"\n  return $?\n}
```

**line_start**: 1226  

**body_full**:
```sh
# source: groqbash:1226\nrotate_history() {\n  local timeout=\"${1:-$GROQBASH_LOCK_TIMEOUT_HISTORY}\"\n  local dir=\"${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}\"\n  local max_files=\"${GROQBASH_HISTORY_MAX_FILES:-100}\"\n  local max_bytes=\"${GROQBASH_HISTORY_MAX_BYTES:-104857600}\"\n  local keep_days=\"${GROQBASH_HISTORY_KEEP_DAYS:-90}\"\n\n  lock_exec \"${HISTORY_LOCK}\" \"$timeout\" -- sh -c '\n    set -e\n    dir=\"$1\"\n    max_files=\"$2\"\n    max_bytes=\"$3\"\n    keep_days=\"$4\"\n\n    # Remove files older than keep_days first\n    find \"$dir\" -type f -mtime +\"$keep_days\" -print0 | xargs -0 -r rm -f --\n\n    # Compute total bytes and remove oldest until under threshold\n    while :; do\n      total=0\n      # Build list of files with mtime and size\n      files_list=\"$(mktemp -p \"$(dirname \"$dir\")\" groq-rot.XXXX 2>/dev/null || true)\"\n      if [ -z \"$files_list\" ]; then\n        files_list=\"/tmp/groq-rot.$$\"\n      fi\n      : > \"$files_list\"\n      find \"$dir\" -type f -print0 2>/dev/null | while IFS= read -r -d \"\" f; do\n        if [ -f \"$f\" ]; then\n          # portable size\n          case \"$(uname 2>/dev/null || echo Linux)\" in\n            Darwin) size=\"$(stat -f %z \"$f\" 2>/dev/null || echo 0)\" ;;\n            *) size=\"$(stat -c %s \"$f\" 2>/dev/null || echo 0)\" ;;\n          esac\n          mtime=0\n          case \"$(uname 2>/dev/null || echo Linux)\" in\n            Darwin) mtime=\"$(stat -f %m \"$f\" 2>/dev/null || echo 0)\" ;;\n            *) mtime=\"$(stat -c %Y \"$f\" 2>/dev/null || echo 0)\" ;;\n          esac\n          printf \"%s|%s|%s\\n\" \"$mtime\" \"$size\" \"$f\" >> \"$files_list\"\n        fi\n      done\n\n      # Sum sizes\n      if [ -s \"$files_list\" ]; then\n        while IFS='|' read -r mtime size path; do\n          total=$((total + (size + 0)))\n        done < \"$files_list\"\n      fi\n\n      # If under limit, break\n      if [ \"$total\" -le \"$max_bytes\" ]; then\n        rm -f \"$files_list\" 2>/dev/null || true\n        break\n      fi\n\n      # Remove oldest file\n      oldest=\"$(sort -n \"$files_list\" | head -n1 | awk -F\"|\" '\\''{print $3}'\\'')\"\n      if [ -z \"$oldest\" ]; then\n        rm -f \"$files_list\" 2>/dev/null || true\n        break\n      fi\n      rm -f -- \"$oldest\" 2>/dev/null || true\n      rm -f \"$files_list\" 2>/dev/null || true\n    done\n\n    # Enforce max files count\n    while :; do\n      count=$(find \"$dir\" -type f 2>/dev/null | wc -l | tr -d \" \")\n      if [ \"$count\" -le \"$max_files\" ]; then break; fi\n      # find oldest and remove\n      oldest=\"$(find \"$dir\" -type f -printf \"%T@ %p\\n\" 2>/dev/null | sort -n | head -n1 | awk '\\''{print $2}'\\'')\"\n      [ -z \"$oldest\" ] && break\n      rm -f -- \"$oldest\" 2>/dev/null || true\n    done\n  ' _ \"$dir\" \"$max_files\" \"$max_bytes\" \"$keep_days\"\n  return $?\n}"
```

---

**name**: "save_to_history"  

**file**: "groqbash"  

**line_range**: "L1304"  

**body_snippet**: 
```sh
# source: groqbash:1304\nsave_to_history() {\n  local content=\"$1\"\n  local filename\n  filename=\"$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt\"\n  mkdir -p \"$GROQBASH_HISTORY_DIR\" 2>/dev/null || true\n  local tmpf dest lockfile\n  # Create tmp file in history dir to ensure same-filesystem atomic mv\n  tmpf=\"$(mktemp -p \"$GROQBASH_HISTORY_DIR\" groq-out.XXXX 2>/dev/null || true)\"\n  [ -n \"$tmpf\" ] || tmpf=\"$GROQBASH_HISTORY_DIR/.groq-out.$$.$RANDOM\"\n  if ! : > \"$tmpf\" 2>/dev/null; then\n    log_error \"HISTORYFAIL\" \"save_to_history: cannot create tmp file in $GROQBASH_HISTORY_DIR\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  printf '%s\\n' \"$content\" > \"$tmpf\"\n  dest=\"$GROQBASH_HISTORY_DIR/$filename\"\n  lockfile=\"$HISTORY_LOCK\"\n  lock_exec \"$lockfile\" \"$GROQBASH_LOCK_TIMEOUT_HISTORY\" -- sh -c '\n    set -e\n    mv -f -- \"$1\" \"$2\"\n    chmod 600 \"$2\" 2>/dev/null || true\n    \n    # --- Write last_history metadata to ui_state ---\n    if [ -f \"$dest\" ]; then\n      size_bytes=\"$(file_size \"$dest\" 2>/dev/null || echo 0)\"\n      ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      basename=\"$(basename \"$dest\")\"\n      history_json=\"$(jq -c -n --arg path \"$dest\" --arg base \"$basename\" --arg ts \"$ts\" --argjson size \"$size_bytes\" '{saved:true, path:$path, basename:$base, ts:$ts, size_bytes:$size}')\"\n      ui_state_write \"last_history.json\" \"$history_json\" || log_warn \"UI_STATE\" \"failed to write last_history.json\"\n    else\n      ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      history_json=\"$(jq -c -n --arg ts \"$ts\" '{saved:false, ts:$ts}')\"\n      ui_state_write \"last_history.json\" \"$history_json\" || true\n    fi\n\n  ' _ \"$tmpf\" \"$dest\" || { rc=$?; rm -f -- \"$tmpf\" 2>/dev/null || true; return \"$rc\"; }\n  if [ \"${GROQBASH_ROTATE_HISTORY:-0}\" -eq 1 ]; then\n    rotate_history \"$GROQBASH_LOCK_TIMEOUT_HISTORY\" || true\n  fi\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"HISTORY_SAVE\" \"$dest\"\n  fi\n  return 0\n}
```

**line_start**: 1304  

**body_full**:
```sh
# source: groqbash:1304\nsave_to_history() {\n  local content=\"$1\"\n  local filename\n  filename=\"$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt\"\n  mkdir -p \"$GROQBASH_HISTORY_DIR\" 2>/dev/null || true\n  local tmpf dest lockfile\n  # Create tmp file in history dir to ensure same-filesystem atomic mv\n  tmpf=\"$(mktemp -p \"$GROQBASH_HISTORY_DIR\" groq-out.XXXX 2>/dev/null || true)\"\n  [ -n \"$tmpf\" ] || tmpf=\"$GROQBASH_HISTORY_DIR/.groq-out.$$.$RANDOM\"\n  if ! : > \"$tmpf\" 2>/dev/null; then\n    log_error \"HISTORYFAIL\" \"save_to_history: cannot create tmp file in $GROQBASH_HISTORY_DIR\"\n    return \"$GROQBASHERRTMP\"\n  fi\n  printf '%s\\n' \"$content\" > \"$tmpf\"\n  dest=\"$GROQBASH_HISTORY_DIR/$filename\"\n  lockfile=\"$HISTORY_LOCK\"\n  lock_exec \"$lockfile\" \"$GROQBASH_LOCK_TIMEOUT_HISTORY\" -- sh -c '\n    set -e\n    mv -f -- \"$1\" \"$2\"\n    chmod 600 \"$2\" 2>/dev/null || true\n    \n    # --- Write last_history metadata to ui_state ---\n    if [ -f \"$dest\" ]; then\n      size_bytes=\"$(file_size \"$dest\" 2>/dev/null || echo 0)\"\n      ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      basename=\"$(basename \"$dest\")\"\n      history_json=\"$(jq -c -n --arg path \"$dest\" --arg base \"$basename\" --arg ts \"$ts\" --argjson size \"$size_bytes\" '{saved:true, path:$path, basename:$base, ts:$ts, size_bytes:$size}')\"\n      ui_state_write \"last_history.json\" \"$history_json\" || log_warn \"UI_STATE\" \"failed to write last_history.json\"\n    else\n      ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      history_json=\"$(jq -c -n --arg ts \"$ts\" '{saved:false, ts:$ts}')\"\n      ui_state_write \"last_history.json\" \"$history_json\" || true\n    fi\n\n  ' _ \"$tmpf\" \"$dest\" || { rc=$?; rm -f -- \"$tmpf\" 2>/dev/null || true; return \"$rc\"; }\n  if [ \"${GROQBASH_ROTATE_HISTORY:-0}\" -eq 1 ]; then\n    rotate_history \"$GROQBASH_LOCK_TIMEOUT_HISTORY\" || true\n  fi\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"HISTORY_SAVE\" \"$dest\"\n  fi\n  return 0\n}"
```

---

**name**: "session_append"  

**file**: "groqbash"  

**line_range**: "L1769"  

**body_snippet**: 
```sh
# source: groqbash:1769\nsession_append() {\n  # Usage: session_append <session_id> <role> <content> <meta_json>\n  local sid=\"$1\" role=\"$2\" content=\"$3\" meta_json=\"$4\"\n  # Prefer SESSION_DIR (set during init), then GROQBASH_HISTORY_DIR, then local fallback\n  local base_sessions_dir=\"${SESSION_DIR:-${GROQBASH_HISTORY_DIR:-./groqbash.d}/sessions}\"\n  local session_file=\"${base_sessions_dir%/}/${sid}.ndjson\"\n  local lockfile=\"${session_file}.lock\"\n  local invocation_ts message_id marker normalized rand tmpf found=0 role_norm line timeout\n  local marker_dir created_marker=0 sess_dir tmp_init\n\n  [ -n \"$sid\" ] || return 1\n  [ -n \"$content\" ] || content=\"\"\n\n  # Ensure we clean up marker_dir on unexpected exit; normal successful path will disable the trap.\n  trap 'if [ \"${created_marker:-0}\" -eq 1 ] && [ -n \"${marker_dir:-}\" ]; then rm -rf -- \"$marker_dir\" 2>/dev/null || true; fi' RETURN\n\n  invocation_ts=\"$(session_now_ts)\"\n  message_id=\"$(printf '%s' \"$meta_json\" | jq -r '.id // empty' 2>/dev/null || true)\"\n  if [ -z \"$message_id\" ]; then\n    normalized=\"$(printf '%s' \"$content\" | sed -e 's/\\r$//' -e 's/\\r\\n/\\n/g' | awk '{$1=$1; print}')\"\n    rand=\"$(printf '%04x' $((RANDOM & 0xFFFF)))\"\n    if command -v sha256sum >/dev/null 2>&1; then\n      message_id=\"$(printf '%s|%s|%s' \"$normalized\" \"$invocation_ts\" \"$rand\" | sha256sum | cut -c1-16)\"\n    elif command -v openssl >/dev/null 2>&1; then\n      message_id=\"$(printf '%s|%s|%s' \"$normalized\" \"$invocation_ts\" \"$rand\" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)\"\n    else\n      message_id=\"$rand\"\n    fi\n  fi\n\n  # Ensure session directory and file exist before creating marker/lock (race-safe init)\n  sess_dir=\"$(dirname \"$session_file\")\"\n  if ! mkdir -p \"$sess_dir\" 2>/dev/null; then\n    log_error \"SESSION\" \"cannot create session directory: $sess_dir\"\n    return 1\n  fi\n  chmod 700 \"$sess_dir\" 2>/dev/null || true\n\n  if [ ! -f \"$session_file\" ]; then\n    tmp_init=\"${RUN_TMPDIR:-$GROQBASH_TMPDIR}/session.init.$$\"\n    : > \"$tmp_init\" 2>/dev/null || true\n    if ! mv -f \"$tmp_init\" \"$session_file\" 2>/dev/null; then\n      cp -f \"$tmp_init\" \"$session_file\" 2>/dev/null || true\n    fi\n    chmod 600 \"$session_file\" 2>/dev/null || true\n  fi\n\n  # Marker: prefer message_id-based idempotency (cross-process). Fallback: run-unique marker to avoid duplicate append from same process.\n  if [ -n \"${message_id:-}\" ]; then\n    marker_dir=\"${RUN_TMPDIR:-$GROQBASH_TMPDIR}/session-msg-${message_id}.lockdir\"\n    if mkdir \"$marker_dir\" 2>/dev/null; then\n      printf '%s\\n' \"$$\" > \"${marker_dir}/owner.pid\" 2>/dev/null || true\n      printf '%s\\n' \"$(date +%s)\" > \"${marker_dir}/owner.ts\" 2>/dev/null || true\n      chmod 700 \"$marker_dir\" 2>/dev/null || true\n      created_marker=1\n    else\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"SESSION\" \"append skipped: marker exists for message_id $message_id\"\n      fi\n      return 0\n    fi\n  else\n    marker_dir=\"${RUN_TMPDIR:-$GROQBASH_TMPDIR}/run-$$-${RANDOM}.lockdir\"\n    mkdir -p \"$marker_dir\" 2>/dev/null || true\n    printf '%s\\n' \"$$\" > \"${marker_dir}/owner.pid\" 2>/dev/null || true\n    printf '%s\\n' \"$(date +%s)\" > \"${marker_dir}/owner.ts\" 2>/dev/null || true\n    chmod 700 \"$marker_dir\" 2>/dev/null || true\n    created_marker=1\n  fi\n\n  # Prepare tmp file for any transient checks (kept minimal)\n  tmpf=\"$(mktemp -p \"${RUN_TMPDIR:-$GROQBASH_TMPDIR}\" session.append.XXXX 2>/dev/null || true)\"\n  : > \"${tmpf:-/dev/null}\" 2>/dev/null || true\n\n  timeout=\"${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}\"\n\n  # Acquire exclusive lock on session file\n  exec 200>\"$lockfile\" 2>/dev/null || true\n  if ! flock -x -w \"$timeout\" 200 2>/dev/null; then\n    # Could not acquire lock: cleanup marker if we created it\n    if [ \"${created_marker:-0}\" -eq 1 ]; then rm -rf -- \"$marker_dir\" 2>/dev/null || true; fi\n    exec 200>&- 2>/dev/null || true\n    rm -f \"$tmpf\" 2>/dev/null || true\n    log_error \"SESSION\" \"could not acquire session lock for append\"\n    return 1\n  fi\n\n  # If message_id present, do a 
```

**line_start**: 1769  

**body_full**:
```sh
# source: groqbash:1769\nsession_append() {\n  # Usage: session_append <session_id> <role> <content> <meta_json>\n  local sid=\"$1\" role=\"$2\" content=\"$3\" meta_json=\"$4\"\n  # Prefer SESSION_DIR (set during init), then GROQBASH_HISTORY_DIR, then local fallback\n  local base_sessions_dir=\"${SESSION_DIR:-${GROQBASH_HISTORY_DIR:-./groqbash.d}/sessions}\"\n  local session_file=\"${base_sessions_dir%/}/${sid}.ndjson\"\n  local lockfile=\"${session_file}.lock\"\n  local invocation_ts message_id marker normalized rand tmpf found=0 role_norm line timeout\n  local marker_dir created_marker=0 sess_dir tmp_init\n\n  [ -n \"$sid\" ] || return 1\n  [ -n \"$content\" ] || content=\"\"\n\n  # Ensure we clean up marker_dir on unexpected exit; normal successful path will disable the trap.\n  trap 'if [ \"${created_marker:-0}\" -eq 1 ] && [ -n \"${marker_dir:-}\" ]; then rm -rf -- \"$marker_dir\" 2>/dev/null || true; fi' RETURN\n\n  invocation_ts=\"$(session_now_ts)\"\n  message_id=\"$(printf '%s' \"$meta_json\" | jq -r '.id // empty' 2>/dev/null || true)\"\n  if [ -z \"$message_id\" ]; then\n    normalized=\"$(printf '%s' \"$content\" | sed -e 's/\\r$//' -e 's/\\r\\n/\\n/g' | awk '{$1=$1; print}')\"\n    rand=\"$(printf '%04x' $((RANDOM & 0xFFFF)))\"\n    if command -v sha256sum >/dev/null 2>&1; then\n      message_id=\"$(printf '%s|%s|%s' \"$normalized\" \"$invocation_ts\" \"$rand\" | sha256sum | cut -c1-16)\"\n    elif command -v openssl >/dev/null 2>&1; then\n      message_id=\"$(printf '%s|%s|%s' \"$normalized\" \"$invocation_ts\" \"$rand\" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)\"\n    else\n      message_id=\"$rand\"\n    fi\n  fi\n\n  # Ensure session directory and file exist before creating marker/lock (race-safe init)\n  sess_dir=\"$(dirname \"$session_file\")\"\n  if ! mkdir -p \"$sess_dir\" 2>/dev/null; then\n    log_error \"SESSION\" \"cannot create session directory: $sess_dir\"\n    return 1\n  fi\n  chmod 700 \"$sess_dir\" 2>/dev/null || true\n\n  if [ ! -f \"$session_file\" ]; then\n    tmp_init=\"${RUN_TMPDIR:-$GROQBASH_TMPDIR}/session.init.$$\"\n    : > \"$tmp_init\" 2>/dev/null || true\n    if ! mv -f \"$tmp_init\" \"$session_file\" 2>/dev/null; then\n      cp -f \"$tmp_init\" \"$session_file\" 2>/dev/null || true\n    fi\n    chmod 600 \"$session_file\" 2>/dev/null || true\n  fi\n\n  # Marker: prefer message_id-based idempotency (cross-process). Fallback: run-unique marker to avoid duplicate append from same process.\n  if [ -n \"${message_id:-}\" ]; then\n    marker_dir=\"${RUN_TMPDIR:-$GROQBASH_TMPDIR}/session-msg-${message_id}.lockdir\"\n    if mkdir \"$marker_dir\" 2>/dev/null; then\n      printf '%s\\n' \"$$\" > \"${marker_dir}/owner.pid\" 2>/dev/null || true\n      printf '%s\\n' \"$(date +%s)\" > \"${marker_dir}/owner.ts\" 2>/dev/null || true\n      chmod 700 \"$marker_dir\" 2>/dev/null || true\n      created_marker=1\n    else\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"SESSION\" \"append skipped: marker exists for message_id $message_id\"\n      fi\n      return 0\n    fi\n  else\n    marker_dir=\"${RUN_TMPDIR:-$GROQBASH_TMPDIR}/run-$$-${RANDOM}.lockdir\"\n    mkdir -p \"$marker_dir\" 2>/dev/null || true\n    printf '%s\\n' \"$$\" > \"${marker_dir}/owner.pid\" 2>/dev/null || true\n    printf '%s\\n' \"$(date +%s)\" > \"${marker_dir}/owner.ts\" 2>/dev/null || true\n    chmod 700 \"$marker_dir\" 2>/dev/null || true\n    created_marker=1\n  fi\n\n  # Prepare tmp file for any transient checks (kept minimal)\n  tmpf=\"$(mktemp -p \"${RUN_TMPDIR:-$GROQBASH_TMPDIR}\" session.append.XXXX 2>/dev/null || true)\"\n  : > \"${tmpf:-/dev/null}\" 2>/dev/null || true\n\n  timeout=\"${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}\"\n\n  # Acquire exclusive lock on session file\n  exec 200>\"$lockfile\" 2>/dev/null || true\n  if ! flock -x -w \"$timeout\" 200 2>/dev/null; then\n    # Could not acquire lock: cleanup marker if we created it\n    if [ \"${created_marker:-0}\" -eq 1 ]; then rm -rf -- \"$marker_dir\" 2>/dev/null || true; fi\n    exec 200>&- 2>/dev/null || true\n    rm -f \"$tmpf\" 2>/dev/null || true\n    log_error \"SESSION\" \"could not acquire session lock for append\"\n    return 1\n  fi\n\n  # If message_id present, do a quick existence check under lock by searching for the id token.\n  if [ -n \"${message_id:-}\" ] && [ -f \"$session_file\" ]; then\n    # Only search for the id field; this is cheap and avoids content-based heuristics\n    if grep -F \"\\\"id\\\":\\\"$message_id\\\"\" \"$session_file\" >/dev/null 2>/dev/null; then\n      # duplicate detected: release lock and keep marker (treat as done)\n      flock -u 200 2>/dev/null || true\n      exec 200>&- 2>/dev/null || true\n      rm -f \"$tmpf\" 2>/dev/null || true\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"SESSION\" \"append skipped: duplicate detected for message_id $message_id\"\n      fi\n      return 0\n    fi\n  fi\n\n  # Normalize role and meta, build line\n  meta_json=\"$(printf '%s' \"$meta_json\" | jq -c '.' 2>/dev/null || printf '%s' '{}' )\"\n  case \"$role\" in user|assistant|system) role_norm=\"$role\" ;; *) role_norm=\"user\" ;; esac\n\n  # Global guard: skip appending empty user messages\n  if [ \"$role_norm\" = \"user\" ] && [ -z \"${content:-}\" ]; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"SESSION\" \"skipping append of empty user message for session $sid\"\n    fi\n    # disable cleanup trap so marker is preserved if needed\n    trap - RETURN\n    return 0\n  fi\n\n  # Build a compact single-line NDJSON record for the session\n  # Use jq -c -n to produce compact JSON (one line)\n  # Ensure meta_json is valid JSON (it was normalized earlier in the function)\n  line=\"$(jq -c -n \\\n    --arg ts \"$invocation_ts\" \\\n    --arg role \"$role_norm\" \\\n    --arg content \"$content\" \\\n    --argjson meta \"$meta_json\" \\\n    '{ts:$ts, role:$role, content:$content, meta:$meta}')\"\n\n  # Perform append (we already hold the lock)\n  if ! printf \"%s\\n\" \"$line\" >> \"$session_file\" 2>/dev/null; then\n    # If append failed, try to reinitialize file safely\n    : > \"$session_file\" 2>/dev/null || true\n    if ! printf \"%s\\n\" \"$line\" >> \"$session_file\" 2>/dev/null; then\n      # Append definitively failed: cleanup marker if we created it\n      if [ \"${created_marker:-0}\" -eq 1 ]; then\n        rm -rf -- \"$marker_dir\" 2>/dev/null || true\n      fi\n      flock -u 200 2>/dev/null || true\n      exec 200>&- 2>/dev/null || true\n      rm -f \"$tmpf\" 2>/dev/null || true\n      log_error \"SESSION\" \"failed to append message to $session_file\"\n      return 1\n    fi\n  fi\n\n  chmod 600 \"$session_file\" 2>/dev/null || true\n\n  # Release lock\n  flock -u 200 2>/dev/null || true\n  exec 200>&- 2>/dev/null || true\n\n  rm -f \"$tmpf\" 2>/dev/null || true\n\n  # Leave marker in place to indicate completion (used for idempotency if message_id present)\n  touch \"${marker_dir}/done\" 2>/dev/null || true\n\n  # Successful completion: disable trap so marker is preserved\n  trap - RETURN\n\n  # --- Update ui_state session metadata (canonical single source) ---\n  # Build session meta JSON under lock-free context (we already released file lock)\n  if ensure_run_tmpdir >/dev/null 2>&1; then\n    # Compute msg_count and last_ts safely (session_file exists)\n    msg_count=0\n    last_ts=\"\"\n    if [ -f \"$session_file\" ]; then\n      msg_count=\"$(wc -l < \"$session_file\" 2>/dev/null || echo 0)\"\n      # Extract last ts from last NDJSON line if possible\n      last_line=\"$(tail -n 1 \"$session_file\" 2>/dev/null || true)\"\n      if printf '%s' \"$last_line\" | jq -e . >/dev/null 2>&1; then\n        last_ts=\"$(printf '%s' \"$last_line\" | jq -r '.ts // empty' 2>/dev/null || true)\"\n      fi\n    fi\n\n    meta_json=\"$(jq -c -n --arg id \"$sid\" --argjson msg_count \"$msg_count\" --arg last_ts \"${last_ts:-}\" \\\n      '{id:$id, active:true, msg_count:$msg_count, last_ts:$last_ts}')\"\n\n    # Write canonical ui_state session file\n    ui_state_write \"sessions/${sid}.json\" \"$meta_json\" || log_warn \"UI_STATE\" \"failed to write session meta for $sid\"\n    # Update sessions index (best-effort): read existing index, add sid if missing\n    idx_file=\"${GROQBASH_CONFIG_DIR%/}/ui_state/sessions/index.json\"\n    if [ -f \"$idx_file\" ]; then\n      if jq -e --arg sid \"$sid\" '(.sessions // []) | index($sid) // empty' \"$idx_file\" >/dev/null 2>&1; then\n        : # already present\n      else\n        # append sid\n        tmp_idx=\"$(mktemp -p \"${RUN_TMPDIR:-$GROQBASH_TMPDIR}\" uiidx.XXXX 2>/dev/null || true)\"\n        if [ -n \"$tmp_idx\" ]; then\n          jq --arg sid \"$sid\" '.sessions = ((.sessions // []) + [$sid])' \"$idx_file\" > \"${tmp_idx}.new\" 2>/dev/null && mv -f \"${tmp_idx}.new\" \"$tmp_idx\" && ui_state_write \"sessions/index.json\" \"$(cat \"$tmp_idx\")\" || true\n          rm -f \"$tmp_idx\" 2>/dev/null || true\n        fi\n      fi\n    else\n      # create new index\n      ui_state_write \"sessions/index.json\" \"$(jq -c -n --argjson arr '[]' '{sessions:[]}' )\" >/dev/null 2>&1 || true\n      # then append sid\n      ui_state_write \"sessions/index.json\" \"$(jq -c -n --arg sid \"$sid\" '{sessions:[$sid]}' )\" >/dev/null 2>&1 || true\n    fi\n  fi\n\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"SESSION\" \"appended message id ${message_id:-<no-id>} to $session_file\"\n  fi\n  return 0\n}"
```

---

**name**: "session_cache_get"  

**file**: "groqbash"  

**line_range**: "L2009"  

**body_snippet**: 
```sh
# source: groqbash:2009\nsession_cache_get() {\n  local sid=\"$1\" params=\"$2\" out=\"$3\"\n  local key file ts now ttl\n  key=\"$(session_cache_key \"$sid\" \"$params\")\" || return 1\n  file=\"${SESSION_CACHE_DIR%/}/${key}.cache\"\n  if [ ! -f \"$file\" ]; then return 1; fi\n  # First line: expiry epoch; rest: payload\n  read -r ts < \"$file\" 2>/dev/null || ts=0\n  now=\"$(date +%s)\"\n  if [ \"$now\" -ge \"$ts\" ]; then\n    # expired\n    rm -f \"$file\" 2>/dev/null || true\n    return 1\n  fi\n  # output payload to out\n  if [ -n \"$out\" ]; then\n    tail -n +2 \"$file\" > \"$out\" 2>/dev/null || return 1\n  else\n    tail -n +2 \"$file\" 2>/dev/null || return 0\n  fi\n  return 0\n}
```

**line_start**: 2009  

**body_full**:
```sh
# source: groqbash:2009\nsession_cache_get() {\n  local sid=\"$1\" params=\"$2\" out=\"$3\"\n  local key file ts now ttl\n  key=\"$(session_cache_key \"$sid\" \"$params\")\" || return 1\n  file=\"${SESSION_CACHE_DIR%/}/${key}.cache\"\n  if [ ! -f \"$file\" ]; then return 1; fi\n  # First line: expiry epoch; rest: payload\n  read -r ts < \"$file\" 2>/dev/null || ts=0\n  now=\"$(date +%s)\"\n  if [ \"$now\" -ge \"$ts\" ]; then\n    # expired\n    rm -f \"$file\" 2>/dev/null || true\n    return 1\n  fi\n  # output payload to out\n  if [ -n \"$out\" ]; then\n    tail -n +2 \"$file\" > \"$out\" 2>/dev/null || return 1\n  else\n    tail -n +2 \"$file\" 2>/dev/null || return 0\n  fi\n  return 0\n}"
```

---

**name**: "session_cache_invalidate"  

**file**: "groqbash"  

**line_range**: "L2053"  

**body_snippet**: 
```sh
# source: groqbash:2053\nsession_cache_invalidate() {\n  local sid=\"$1\" params=\"$2\" key pattern\n  if [ -z \"$sid\" ]; then return 1; fi\n  if [ -n \"$params\" ]; then\n    key=\"$(session_cache_key \"$sid\" \"$params\")\" || return 1\n    rm -f \"${SESSION_CACHE_DIR%/}/${key}.cache\" 2>/dev/null || true\n  else\n    # remove all entries for sid\n    pattern=\"${SESSION_CACHE_DIR%/}/${sid}|*.cache\"\n    # shell globbing safe removal\n    for f in ${pattern}; do\n      [ -e \"$f\" ] && rm -f -- \"$f\" 2>/dev/null || true\n    done\n  fi\n  return 0\n}
```

**line_start**: 2053  

**body_full**:
```sh
# source: groqbash:2053\nsession_cache_invalidate() {\n  local sid=\"$1\" params=\"$2\" key pattern\n  if [ -z \"$sid\" ]; then return 1; fi\n  if [ -n \"$params\" ]; then\n    key=\"$(session_cache_key \"$sid\" \"$params\")\" || return 1\n    rm -f \"${SESSION_CACHE_DIR%/}/${key}.cache\" 2>/dev/null || true\n  else\n    # remove all entries for sid\n    pattern=\"${SESSION_CACHE_DIR%/}/${sid}|*.cache\"\n    # shell globbing safe removal\n    for f in ${pattern}; do\n      [ -e \"$f\" ] && rm -f -- \"$f\" 2>/dev/null || true\n    done\n  fi\n  return 0\n}"
```

---

**name**: "session_cache_key"  

**file**: "groqbash"  

**line_range**: "L2002"  

**body_snippet**: 
```sh
# source: groqbash:2002\nsession_cache_key() {\n  local sid=\"$1\" params=\"$2\"\n  [ -n \"$sid\" ] || return 1\n  params=\"${params:-}\"\n  printf '%s|%s' \"$sid\" \"$(_session_hash \"$params\")\"\n}
```

**line_start**: 2002  

**body_full**:
```sh
# source: groqbash:2002\nsession_cache_key() {\n  local sid=\"$1\" params=\"$2\"\n  [ -n \"$sid\" ] || return 1\n  params=\"${params:-}\"\n  printf '%s|%s' \"$sid\" \"$(_session_hash \"$params\")\"\n}"
```

---

**name**: "session_cache_set"  

**file**: "groqbash"  

**line_range**: "L2032"  

**body_snippet**: 
```sh
# source: groqbash:2032\nsession_cache_set() {\n  local sid=\"$1\" params=\"$2\" ttl=\"${3:-300}\" infile=\"$4\"\n  local key file expiry now\n  key=\"$(session_cache_key \"$sid\" \"$params\")\" || return 1\n  file=\"${SESSION_CACHE_DIR%/}/${key}.cache\"\n  now=\"$(date +%s)\"\n  expiry=$((now + (ttl + 0)))\n  # Write atomically\n  {\n    printf '%s\\n' \"$expiry\"\n    if [ -n \"$infile\" ] && [ -f \"$infile\" ]; then\n      cat \"$infile\"\n    else\n      cat -\n    fi\n  } > \"${file}.tmp.$$\" 2>/dev/null || return 1\n  mv -f \"${file}.tmp.$$\" \"$file\" 2>/dev/null || { rm -f \"${file}.tmp.$$\" 2>/dev/null || true; return 1; }\n  chmod 600 \"$file\" 2>/dev/null || true\n  return 0\n}
```

**line_start**: 2032  

**body_full**:
```sh
# source: groqbash:2032\nsession_cache_set() {\n  local sid=\"$1\" params=\"$2\" ttl=\"${3:-300}\" infile=\"$4\"\n  local key file expiry now\n  key=\"$(session_cache_key \"$sid\" \"$params\")\" || return 1\n  file=\"${SESSION_CACHE_DIR%/}/${key}.cache\"\n  now=\"$(date +%s)\"\n  expiry=$((now + (ttl + 0)))\n  # Write atomically\n  {\n    printf '%s\\n' \"$expiry\"\n    if [ -n \"$infile\" ] && [ -f \"$infile\" ]; then\n      cat \"$infile\"\n    else\n      cat -\n    fi\n  } > \"${file}.tmp.$$\" 2>/dev/null || return 1\n  mv -f \"${file}.tmp.$$\" \"$file\" 2>/dev/null || { rm -f \"${file}.tmp.$$\" 2>/dev/null || true; return 1; }\n  chmod 600 \"$file\" 2>/dev/null || true\n  return 0\n}"
```

---

**name**: "session_messages_tmp_path"  

**file**: "groqbash"  

**line_range**: "L1628"  

**body_snippet**: 
```sh
# source: groqbash:1628\nsession_messages_tmp_path() {\n  local sid=\"$1\"\n  ensure_run_tmpdir || return 1\n  printf '%s' \"$RUN_TMPDIR/session-${sid}-messages.json\"\n}
```

**line_start**: 1628  

**body_full**:
```sh
# source: groqbash:1628\nsession_messages_tmp_path() {\n  local sid=\"$1\"\n  ensure_run_tmpdir || return 1\n  printf '%s' \"$RUN_TMPDIR/session-${sid}-messages.json\"\n}"
```

---

**name**: "session_now_ts"  

**file**: "groqbash"  

**line_range**: "L1623"  

**body_snippet**: 
```sh
# source: groqbash:1623\nsession_now_ts() {\n  # UTC timestamp, seconds resolution, format YYYY-MM-DDTHH:MM:SSZ\n  date -u +%Y-%m-%dT%H:%M:%SZ\n}
```

**line_start**: 1623  

**body_full**:
```sh
# source: groqbash:1623\nsession_now_ts() {\n  # UTC timestamp, seconds resolution, format YYYY-MM-DDTHH:MM:SSZ\n  date -u +%Y-%m-%dT%H:%M:%SZ\n}"
```

---

**name**: "session_read_window"  

**file**: "groqbash"  

**line_range**: "L1642"  

**body_snippet**: 
```sh
# source: groqbash:1642\nsession_read_window() {\n  # Usage: session_read_window <session_id> <N> <out_file>\n  local sid=\"$1\" n=\"${2:-10}\" out=\"$3\"\n  local history_dir=\"${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}\"\n  local session_file=\"$history_dir/sessions/${sid}.ndjson\"\n  local tmpdir=\"${RUN_TMPDIR:-${GROQBASH_TMPDIR:-$PWD/groqbash.d/tmp}}\"\n  local tmpf out_tmp line role content role_norm role_json content_json\n\n  [ -n \"$sid\" ] || return 1\n  [ -n \"$out\" ] || return 1\n\n  mkdir -p \"${history_dir%/}/sessions\" 2>/dev/null || true\n  chmod 700 \"${history_dir%/}/sessions\" 2>/dev/null || true\n\n  if ! printf '%s' \"$n\" | grep -qE '^[0-9]+$'; then n=10; fi\n  if [ \"$n\" -le 0 ]; then n=10; fi\n\n  # Ensure tmpdir exists and is writable (must be inside groqbash.d/)\n  mkdir -p \"${tmpdir%/}\" 2>/dev/null || true\n  chmod 700 \"${tmpdir%/}\" 2>/dev/null || true\n  if ! : > \"${tmpdir%/}/.groqbash_tmp_check\" 2>/dev/null; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      printf 'DEBUG: session_read_window: tmpdir not writable: %s\\n' \"$tmpdir\" >&2\n    fi\n    return 1\n  else\n    rm -f \"${tmpdir%/}/.groqbash_tmp_check\" 2>/dev/null || true\n  fi\n\n  # Create a tmpf inside tmpdir (no /tmp, no /dev/null)\n  tmpf=\"${tmpdir%/}/session.read.$$.$RANDOM\"\n  : > \"$tmpf\" 2>/dev/null || { if [ \"${DEBUG:-0}\" -eq 1 ]; then printf 'DEBUG: session_read_window: cannot create tmpf %s\\n' \"$tmpf\" >&2; fi; return 1; }\n\n  # Extract last N records robustly (records separated by blank line)\n  if [ -f \"$session_file\" ]; then\n    # Acquire a short lock on the session file to avoid partial reads during concurrent append\n    lock_exec \"${session_file}.lock\" 5 -- sh -c '\n      set -e\n      session_file=\"$1\"\n      n=\"$2\"\n      tmpf=\"$3\"\n      if grep -q \"^$\" \"$session_file\" 2>/dev/null; then\n        awk -v n=\"$n\" \"BEGIN{RS=\\\"\\\"; ORS=RS} {rec[++c]=\\$0} END{start=c-n+1; if(start<1) start=1; for(i=start;i<=c;i++) print rec[i]}\" \"$session_file\" > \"$tmpf\" 2>/dev/null || cp -f \"$session_file\" \"$tmpf\" 2>/dev/null || true\n      else\n        if ! tail -n \"$n\" \"$session_file\" 2>/dev/null > \"$tmpf\"; then\n          cp -f \"$session_file\" \"$tmpf\" 2>/dev/null || true\n        fi\n      fi\n    ' _ \"$session_file\" \"$n\" \"$tmpf\"\n  else\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      printf 'DEBUG: session_read_window: session file not found: %s\\n' \"$session_file\" >&2\n    fi\n  fi\n\n  # Prepare atomic output in same dir as out\n  out_tmp=\"${out}.tmp.$$\"\n  mkdir -p \"$(dirname \"$out\")\" 2>/dev/null || true\n  : > \"$out_tmp\"\n  chmod 600 \"$out_tmp\" 2>/dev/null || true\n\n  printf '%s' '{\"messages\":[' >> \"$out_tmp\"\n    local first=1\n  # Use jq -c to compact each JSON record (handles pretty-printed and single-line NDJSON)\n  if jq -c . \"$tmpf\" >/dev/null 2>&1; then\n    jq -c . \"$tmpf\" 2>/dev/null | while IFS= read -r line || [ -n \"$line\" ]; do\n      role=\"$(printf '%s' \"$line\" | jq -r '.role // \"user\"')\"\n      case \"$role\" in user|assistant|system) role_norm=\"$role\" ;; *) role_norm=\"user\" ;; esac\n      content=\"$(printf '%s' \"$line\" | jq -r '.content // \"\"')\"\n      role_json=\"$(printf '%s' \"$role_norm\" | jq -R -c '.')\"\n      content_json=\"$(printf '%s' \"$content\" | jq -R -s '.')\"\n      if [ \"$first\" -eq 0 ]; then printf ',' >> \"$out_tmp\"; fi\n      printf '%s' \"{\\\"role\\\":${role_json},\\\"content\\\":${content_json}}\" >> \"$out_tmp\" 2>/dev/null || true\n      first=0\n    done\n  else\n    # fallback: try to treat tmpf as line-based NDJSON\n    while IFS= read -r line || [ -n \"$line\" ]; do\n      if printf '%s' \"$line\" | jq -e . >/dev/null 2>&1; then\n        role=\"$(printf '%s' \"$line\" | jq -r '.role // \"user\"')\"\n        case \"$role\" in user|assistant|system) role_norm=\"$role\" ;; *) role_norm=\"user\" ;; esac\n        content=\"$(printf '%s' \"$line\" | jq -r '.content // \"\"')\"\n        role_json=\"$(printf '%s' \"$role_norm\" | jq -R -c '.')\"\n        content_json=\"$(printf '%s' \"$content\" | jq -R -s '.')\"\n        if [ \"$first\" -eq 0 ]; then printf ',' >> \"$out_tmp\"; fi\n        printf '%s' \"{\\\"role\\\":${role_json},\\\"content\\\":${content_json}}\" >> \"$
```

**line_start**: 1642  

**body_full**:
```sh
# source: groqbash:1642\nsession_read_window() {\n  # Usage: session_read_window <session_id> <N> <out_file>\n  local sid=\"$1\" n=\"${2:-10}\" out=\"$3\"\n  local history_dir=\"${GROQBASH_HISTORY_DIR:-$PWD/groqbash.d/history}\"\n  local session_file=\"$history_dir/sessions/${sid}.ndjson\"\n  local tmpdir=\"${RUN_TMPDIR:-${GROQBASH_TMPDIR:-$PWD/groqbash.d/tmp}}\"\n  local tmpf out_tmp line role content role_norm role_json content_json\n\n  [ -n \"$sid\" ] || return 1\n  [ -n \"$out\" ] || return 1\n\n  mkdir -p \"${history_dir%/}/sessions\" 2>/dev/null || true\n  chmod 700 \"${history_dir%/}/sessions\" 2>/dev/null || true\n\n  if ! printf '%s' \"$n\" | grep -qE '^[0-9]+$'; then n=10; fi\n  if [ \"$n\" -le 0 ]; then n=10; fi\n\n  # Ensure tmpdir exists and is writable (must be inside groqbash.d/)\n  mkdir -p \"${tmpdir%/}\" 2>/dev/null || true\n  chmod 700 \"${tmpdir%/}\" 2>/dev/null || true\n  if ! : > \"${tmpdir%/}/.groqbash_tmp_check\" 2>/dev/null; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      printf 'DEBUG: session_read_window: tmpdir not writable: %s\\n' \"$tmpdir\" >&2\n    fi\n    return 1\n  else\n    rm -f \"${tmpdir%/}/.groqbash_tmp_check\" 2>/dev/null || true\n  fi\n\n  # Create a tmpf inside tmpdir (no /tmp, no /dev/null)\n  tmpf=\"${tmpdir%/}/session.read.$$.$RANDOM\"\n  : > \"$tmpf\" 2>/dev/null || { if [ \"${DEBUG:-0}\" -eq 1 ]; then printf 'DEBUG: session_read_window: cannot create tmpf %s\\n' \"$tmpf\" >&2; fi; return 1; }\n\n  # Extract last N records robustly (records separated by blank line)\n  if [ -f \"$session_file\" ]; then\n    # Acquire a short lock on the session file to avoid partial reads during concurrent append\n    lock_exec \"${session_file}.lock\" 5 -- sh -c '\n      set -e\n      session_file=\"$1\"\n      n=\"$2\"\n      tmpf=\"$3\"\n      if grep -q \"^$\" \"$session_file\" 2>/dev/null; then\n        awk -v n=\"$n\" \"BEGIN{RS=\\\"\\\"; ORS=RS} {rec[++c]=\\$0} END{start=c-n+1; if(start<1) start=1; for(i=start;i<=c;i++) print rec[i]}\" \"$session_file\" > \"$tmpf\" 2>/dev/null || cp -f \"$session_file\" \"$tmpf\" 2>/dev/null || true\n      else\n        if ! tail -n \"$n\" \"$session_file\" 2>/dev/null > \"$tmpf\"; then\n          cp -f \"$session_file\" \"$tmpf\" 2>/dev/null || true\n        fi\n      fi\n    ' _ \"$session_file\" \"$n\" \"$tmpf\"\n  else\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      printf 'DEBUG: session_read_window: session file not found: %s\\n' \"$session_file\" >&2\n    fi\n  fi\n\n  # Prepare atomic output in same dir as out\n  out_tmp=\"${out}.tmp.$$\"\n  mkdir -p \"$(dirname \"$out\")\" 2>/dev/null || true\n  : > \"$out_tmp\"\n  chmod 600 \"$out_tmp\" 2>/dev/null || true\n\n  printf '%s' '{\"messages\":[' >> \"$out_tmp\"\n    local first=1\n  # Use jq -c to compact each JSON record (handles pretty-printed and single-line NDJSON)\n  if jq -c . \"$tmpf\" >/dev/null 2>&1; then\n    jq -c . \"$tmpf\" 2>/dev/null | while IFS= read -r line || [ -n \"$line\" ]; do\n      role=\"$(printf '%s' \"$line\" | jq -r '.role // \"user\"')\"\n      case \"$role\" in user|assistant|system) role_norm=\"$role\" ;; *) role_norm=\"user\" ;; esac\n      content=\"$(printf '%s' \"$line\" | jq -r '.content // \"\"')\"\n      role_json=\"$(printf '%s' \"$role_norm\" | jq -R -c '.')\"\n      content_json=\"$(printf '%s' \"$content\" | jq -R -s '.')\"\n      if [ \"$first\" -eq 0 ]; then printf ',' >> \"$out_tmp\"; fi\n      printf '%s' \"{\\\"role\\\":${role_json},\\\"content\\\":${content_json}}\" >> \"$out_tmp\" 2>/dev/null || true\n      first=0\n    done\n  else\n    # fallback: try to treat tmpf as line-based NDJSON\n    while IFS= read -r line || [ -n \"$line\" ]; do\n      if printf '%s' \"$line\" | jq -e . >/dev/null 2>&1; then\n        role=\"$(printf '%s' \"$line\" | jq -r '.role // \"user\"')\"\n        case \"$role\" in user|assistant|system) role_norm=\"$role\" ;; *) role_norm=\"user\" ;; esac\n        content=\"$(printf '%s' \"$line\" | jq -r '.content // \"\"')\"\n        role_json=\"$(printf '%s' \"$role_norm\" | jq -R -c '.')\"\n        content_json=\"$(printf '%s' \"$content\" | jq -R -s '.')\"\n        if [ \"$first\" -eq 0 ]; then printf ',' >> \"$out_tmp\"; fi\n        printf '%s' \"{\\\"role\\\":${role_json},\\\"content\\\":${content_json}}\" >> \"$out_tmp\" 2>/dev/null || true\n        first=0\n      fi\n    done < \"$tmpf\"\n  fi\n  printf '%s' ']}' >> \"$out_tmp\"\n\n  # Atomic replace\n  if mv -f \"$out_tmp\" \"$out\" 2>/dev/null; then\n    :\n  else\n    cp -f \"$out_tmp\" \"$out\" 2>/dev/null || true\n    rm -f \"$out_tmp\" 2>/dev/null || true\n  fi\n\n  rm -f \"$tmpf\" 2>/dev/null || true\n  chmod 600 \"$out\" 2>/dev/null || true\n\n  # --- Update ui_state session metadata after read_window (best-effort) ---\n  if [ -n \"$sid\" ]; then\n    if ensure_run_tmpdir >/dev/null 2>&1; then\n      msg_count=0\n      last_ts=\"\"\n      if [ -f \"$session_file\" ]; then\n        msg_count=\"$(wc -l < \"$session_file\" 2>/dev/null || echo 0)\"\n        last_line=\"$(tail -n 1 \"$session_file\" 2>/dev/null || true)\"\n        if printf '%s' \"$last_line\" | jq -e . >/dev/null 2>&1; then\n          last_ts=\"$(printf '%s' \"$last_line\" | jq -r '.ts // empty' 2>/dev/null || true)\"\n        fi\n      fi\n      meta_json=\"$(jq -c -n --arg id \"$sid\" --argjson msg_count \"$msg_count\" --arg last_ts \"${last_ts:-}\" '{id:$id, active:(( $msg_count | tonumber) > 0), msg_count:$msg_count, last_ts:$last_ts}')\"\n      ui_state_write \"sessions/${sid}.json\" \"$meta_json\" || log_warn \"UI_STATE\" \"failed to update session meta for $sid (read_window)\"\n    fi\n  fi\n\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    printf 'DEBUG: session_read_window done: out=%s size=%s tmpf=%s\\n' \"$out\" \"$( [ -f \"$out\" ] && wc -c < \"$out\" || echo 0 )\" \"$tmpf\" >&2\n  fi\n\n  return 0\n}"
```

---

**name**: "session_sanitize_cmd"  

**file**: "groqbash"  

**line_range**: "L1634"  

**body_snippet**: 
```sh
# source: groqbash:1634\nsession_sanitize_cmd() {\n  local cmd=\"$1\"\n  # Remove env-like KEY=VAL, redact tokens/keys, truncate to 256 chars\n  local sanitized\n  sanitized=\"$(printf '%s' \"$cmd\" | sed -E 's/[A-Za-z0-9_]+=([^[:space:]]+)//g' | sed -E 's/(token|key|secret)[^[:space:]]*/[REDACTED]/Ig' )\"\n  printf '%s' \"$(printf '%s' \"$sanitized\" | cut -c1-256)\"\n}
```

**line_start**: 1634  

**body_full**:
```sh
# source: groqbash:1634\nsession_sanitize_cmd() {\n  local cmd=\"$1\"\n  # Remove env-like KEY=VAL, redact tokens/keys, truncate to 256 chars\n  local sanitized\n  sanitized=\"$(printf '%s' \"$cmd\" | sed -E 's/[A-Za-z0-9_]+=([^[:space:]]+)//g' | sed -E 's/(token|key|secret)[^[:space:]]*/[REDACTED]/Ig' )\"\n  printf '%s' \"$(printf '%s' \"$sanitized\" | cut -c1-256)\"\n}"
```

---

**name**: "session_validate_id"  

**file**: "groqbash"  

**line_range**: "L1617"  

**body_snippet**: 
```sh
# source: groqbash:1617\nsession_validate_id() {\n  local id=\"$1\"\n  if [ -z \"$id\" ]; then return 1; fi\n  if printf '%s' \"$id\" | grep -qE '^[A-Za-z0-9._-]{1,128}$'; then return 0; else return 1; fi\n}
```

**line_start**: 1617  

**body_full**:
```sh
# source: groqbash:1617\nsession_validate_id() {\n  local id=\"$1\"\n  if [ -z \"$id\" ]; then return 1; fi\n  if printf '%s' \"$id\" | grep -qE '^[A-Za-z0-9._-]{1,128}$'; then return 0; else return 1; fi\n}"
```

---

### SECTION: PROVIDER

---

**name**: "_cleanup_local_tmp"  

**file**: "groqbash"  

**line_range**: "L2173"  

**body_snippet**: 
```sh
# source: groqbash:2173\n_cleanup_local_tmp() {\n  local tmp_payload=\"$1\" tmp_b64_local=\"$2\" json_input_file=\"$3\"\n  [ -n \"$tmp_payload\" ] && rm -f -- \"$tmp_payload\" 2>/dev/null || true\n  [ -n \"$tmp_b64_local\" ] && rm -f -- \"$tmp_b64_local\" 2>/dev/null || true\n  [ -n \"$json_input_file\" ] && rm -f -- \"$json_input_file\" 2>/dev/null || true\n}
```

**line_start**: 2173  

**body_full**:
```sh
# source: groqbash:2173\n_cleanup_local_tmp() {\n  local tmp_payload=\"$1\" tmp_b64_local=\"$2\" json_input_file=\"$3\"\n  [ -n \"$tmp_payload\" ] && rm -f -- \"$tmp_payload\" 2>/dev/null || true\n  [ -n \"$tmp_b64_local\" ] && rm -f -- \"$tmp_b64_local\" 2>/dev/null || true\n  [ -n \"$json_input_file\" ] && rm -f -- \"$json_input_file\" 2>/dev/null || true\n}"
```

---

**name**: "auto_select_model_groq"  

**file**: "groqbash"  

**line_range**: "L3002"  

**body_snippet**: 
```sh
# source: groqbash:3002\nauto_select_model_groq() {\n  # Return the first supported model candidate from MODELS_FILE for Groq provider.\n  # Normalizes entries by stripping common prefixes like \"models/\" and \"groq:\".\n  # Prints the selected model (normalized) to stdout and returns 0 on success,\n  # returns 1 if no suitable model found.\n  local file=\"$MODELS_FILE\" line norm cnt=0\n  if [ -f \"$file\" ] && [ -s \"$file\" ]; then\n    while IFS= read -r line || [ -n \"$line\" ]; do\n      [ -z \"$line\" ] && continue\n      cnt=$((cnt+1))\n      norm=\"$(printf '%s' \"$line\" | sed -e 's#^models/##' -e 's#^groq[:/ -]*##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n      if is_supported_model \"$norm\"; then\n        printf '%s' \"$norm\"\n        return 0\n      fi\n      [ \"$cnt\" -ge \"$MAX_MODELS\" ] && break\n    done < \"$file\"\n  fi\n  return 1\n}
```

**line_start**: 3002  

**body_full**:
```sh
# source: groqbash:3002\nauto_select_model_groq() {\n  # Return the first supported model candidate from MODELS_FILE for Groq provider.\n  # Normalizes entries by stripping common prefixes like \"models/\" and \"groq:\".\n  # Prints the selected model (normalized) to stdout and returns 0 on success,\n  # returns 1 if no suitable model found.\n  local file=\"$MODELS_FILE\" line norm cnt=0\n  if [ -f \"$file\" ] && [ -s \"$file\" ]; then\n    while IFS= read -r line || [ -n \"$line\" ]; do\n      [ -z \"$line\" ] && continue\n      cnt=$((cnt+1))\n      norm=\"$(printf '%s' \"$line\" | sed -e 's#^models/##' -e 's#^groq[:/ -]*##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n      if is_supported_model \"$norm\"; then\n        printf '%s' \"$norm\"\n        return 0\n      fi\n      [ \"$cnt\" -ge \"$MAX_MODELS\" ] && break\n    done < \"$file\"\n  fi\n  return 1\n}"
```

---

**name**: "autoselectmodelgroq"  

**file**: "groqbash"  

**line_range**: "L3023"  

**body_snippet**: 
```sh
# source: groqbash:3023\nautoselectmodelgroq() { auto_select_model_groq \"$@\"; }
```

**line_start**: 3023  

**body_full**:
```sh
# source: groqbash:3023\nautoselectmodelgroq() { auto_select_model_groq \"$@\"; }"
```

---

**name**: "buildpayload_groq"  

**file**: "groqbash"  

**line_range**: "L2180"  

**body_snippet**: 
```sh
# source: groqbash:2180\nbuildpayload_groq() {\n  # Build payload for Groq provider into tmp_payload\n  # Assumes: MODEL, TURE, MAX_TOKENS, MESSAGES_JSON, BUILD_MESSAGES_FILE, STREAM_MODE, JSON_INPUT, CONTENT may be set\n  local tmp_payload stream_json VALID_MESSAGES_JSON http_code edgecase now_ts model_from_file payload_size staged_b64 tmp_b64 content_val msgs\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n  tmp_payload=\"$(_mktemp_in_dir \"$RUN_TMPDIR\" payload.XXXXXX.json 2>/dev/null || printf '%s' \"$RUN_TMPDIR/payload.json\")\"\n\n  # Normalize stream_json to a JSON boolean literal (true/false)\n  if is_truthy \"${STREAM_MODE:-0}\"; then\n    stream_json=true\n  else\n    stream_json=false\n  fi\n  case \"${stream_json:-}\" in\n    true|false) ;;    # valid\n    1) stream_json=true ;;\n    0) stream_json=false ;;\n    *) stream_json=false ;;\n  esac\n\n  # Validate numeric inputs used with tonumber in jq\n  if ! printf '%s' \"${TURE:-}\" | grep -qE '^[0-9]+([.][0-9]+)?$'; then\n    log_warn \"ARGS\" \"invalid TURE value '${TURE:-}'; defaulting to 1.0\"\n    TURE=\"1.0\"\n  fi\n  if ! printf '%s' \"${MAX_TOKENS:-}\" | grep -qE '^[0-9]+$'; then\n    log_warn \"ARGS\" \"invalid MAX_TOKENS value '${MAX_TOKENS:-}'; defaulting to 4096\"\n    MAX_TOKENS=\"4096\"\n  fi\n\n  # Priority for messages:\n  # 1) JSON_INPUT (if provided) -> .messages or .content/.prompt\n  # 2) MESSAGES_JSON (explicit)\n  # 3) BUILD_MESSAGES_FILE -> .messages\n  # 4) CONTENT (positional/stdin)\n  # 5) fallback single empty user message\n  VALID_MESSAGES_JSON=\"\"\n\n  if [ -n \"${JSON_INPUT:-}\" ] && is_valid_json_string \"${JSON_INPUT}\"; then\n    # Prefer explicit .messages array in JSON_INPUT\n    msgs=\"$(printf '%s' \"$JSON_INPUT\" | jq -c '.messages // empty' 2>/dev/null || true)\"\n    if [ -n \"$msgs\" ]; then\n      VALID_MESSAGES_JSON=\"$msgs\"\n    else\n      # Try to extract a single content/prompt field and wrap it\n      content_val=\"$(printf '%s' \"$JSON_INPUT\" | jq -r '.content // .prompt // empty' 2>/dev/null || true)\"\n      if [ -n \"$content_val\" ]; then\n        VALID_MESSAGES_JSON=\"$(jq -c -n --arg content \"$content_val\" '[{role:\"user\"  
content:$content}]')\"\n      fi\n    fi\n  fi\n\n  if [ -z \"$VALID_MESSAGES_JSON\" ] && is_valid_json_string \"${MESSAGES_JSON:-}\"; then\n    VALID_MESSAGES_JSON=\"${MESSAGES_JSON}\"\n  fi\n\n  if [ -z \"$VALID_MESSAGES_JSON\" ] && [ -n \"${BUILD_MESSAGES_FILE:-}\" ] && is_valid_json_file \"${BUILD_MESSAGES_FILE}\"; then\n    VALID_MESSAGES_JSON=\"$(jq -c '.messages // []' \"$BUILD_MESSAGES_FILE\" 2>/dev/null || true)\"\n  fi\n\n  # If still empty, but CONTENT present (from args/stdin), use it\n  if [ -z \"$VALID_MESSAGES_JSON\" ] && [ -n \"${CONTENT:-}\" ]; then\n    VALID_MESSAGES_JSON=\"$(jq -c -n --arg content \"$CONTENT\" '[{role:\"user\"  
content:$content}]')\"\n  fi\n\n  # Final fallback: single empty user message to avoid --argjson errors\n  if [ -z \"$VALID_MESSAGES_JSON\" ]; then\n    VALID_MESSAGES_JSON='[{\"role\":\"user\"  
\"content\":\"\"}]'\n    log_warn \"PAYLOAD\" \"MESSAGES_JSON invalid or missing; using fallback single empty user message\"\n  fi\n\n  # Ensure messages is a non-empty array; if empty, fallback to single empty user message\n  if ! printf '%s' \"$VALID_MESSAGES_JSON\" | jq -e 'type==\"array\" and (length>0)' >/dev/null 2>&1; then\n    log_warn \"PAYLOAD\" \"VALID_MESSAGES_JSON is empty or not an array; using fallback single empty user message\"\n    VALID_MESSAGES_JSON='[{\"role\":\"user\"  
\"content\":\"\"}]'\n  fi\n\n  # If MODEL not set, try to read from BUILD_MESSAGES_FILE (if present and valid)\n  if [ -z \"${MODEL:-}\" ] && [ -n \"${BUILD_MESSAGES_FILE:-}\" ] && is_valid_json_file \"${BUILD_MESSAGES_FILE}\"; then\n    model_from_file=\"$(jq -r '.model // .provider?.model // empty' \"$BUILD_MESSAGES_FILE\" 2>/dev/null || true)\"\n    if [ -n \"$model_from_file\" ]; then\n      MODEL=\"$model_from_file\"\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"PAYLOAD\" \"MODEL set from BUILD_MESSAGES_FILE: ${MODEL}\"\n      fi\n    fi\n  fi\n\n  # Build payload using validated values; pass messages via validated JSON string\n  if ! jq -n --arg model \"${MODEL
```

**line_start**: 2180  

**body_full**:
```sh
# source: groqbash:2180\nbuildpayload_groq() {\n  # Build payload for Groq provider into tmp_payload\n  # Assumes: MODEL, TURE, MAX_TOKENS, MESSAGES_JSON, BUILD_MESSAGES_FILE, STREAM_MODE, JSON_INPUT, CONTENT may be set\n  local tmp_payload stream_json VALID_MESSAGES_JSON http_code edgecase now_ts model_from_file payload_size staged_b64 tmp_b64 content_val msgs\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n  tmp_payload=\"$(_mktemp_in_dir \"$RUN_TMPDIR\" payload.XXXXXX.json 2>/dev/null || printf '%s' \"$RUN_TMPDIR/payload.json\")\"\n\n  # Normalize stream_json to a JSON boolean literal (true/false)\n  if is_truthy \"${STREAM_MODE:-0}\"; then\n    stream_json=true\n  else\n    stream_json=false\n  fi\n  case \"${stream_json:-}\" in\n    true|false) ;;    # valid\n    1) stream_json=true ;;\n    0) stream_json=false ;;\n    *) stream_json=false ;;\n  esac\n\n  # Validate numeric inputs used with tonumber in jq\n  if ! printf '%s' \"${TURE:-}\" | grep -qE '^[0-9]+([.][0-9]+)?$'; then\n    log_warn \"ARGS\" \"invalid TURE value '${TURE:-}'; defaulting to 1.0\"\n    TURE=\"1.0\"\n  fi\n  if ! printf '%s' \"${MAX_TOKENS:-}\" | grep -qE '^[0-9]+$'; then\n    log_warn \"ARGS\" \"invalid MAX_TOKENS value '${MAX_TOKENS:-}'; defaulting to 4096\"\n    MAX_TOKENS=\"4096\"\n  fi\n\n  # Priority for messages:\n  # 1) JSON_INPUT (if provided) -> .messages or .content/.prompt\n  # 2) MESSAGES_JSON (explicit)\n  # 3) BUILD_MESSAGES_FILE -> .messages\n  # 4) CONTENT (positional/stdin)\n  # 5) fallback single empty user message\n  VALID_MESSAGES_JSON=\"\"\n\n  if [ -n \"${JSON_INPUT:-}\" ] && is_valid_json_string \"${JSON_INPUT}\"; then\n    # Prefer explicit .messages array in JSON_INPUT\n    msgs=\"$(printf '%s' \"$JSON_INPUT\" | jq -c '.messages // empty' 2>/dev/null || true)\"\n    if [ -n \"$msgs\" ]; then\n      VALID_MESSAGES_JSON=\"$msgs\"\n    else\n      # Try to extract a single content/prompt field and wrap it\n      content_val=\"$(printf '%s' \"$JSON_INPUT\" | jq -r '.content // .prompt // empty' 2>/dev/null || true)\"\n      if [ -n \"$content_val\" ]; then\n        VALID_MESSAGES_JSON=\"$(jq -c -n --arg content \"$content_val\" '[{role:\"user\"  
content:$content}]')\"\n      fi\n    fi\n  fi\n\n  if [ -z \"$VALID_MESSAGES_JSON\" ] && is_valid_json_string \"${MESSAGES_JSON:-}\"; then\n    VALID_MESSAGES_JSON=\"${MESSAGES_JSON}\"\n  fi\n\n  if [ -z \"$VALID_MESSAGES_JSON\" ] && [ -n \"${BUILD_MESSAGES_FILE:-}\" ] && is_valid_json_file \"${BUILD_MESSAGES_FILE}\"; then\n    VALID_MESSAGES_JSON=\"$(jq -c '.messages // []' \"$BUILD_MESSAGES_FILE\" 2>/dev/null || true)\"\n  fi\n\n  # If still empty, but CONTENT present (from args/stdin), use it\n  if [ -z \"$VALID_MESSAGES_JSON\" ] && [ -n \"${CONTENT:-}\" ]; then\n    VALID_MESSAGES_JSON=\"$(jq -c -n --arg content \"$CONTENT\" '[{role:\"user\"  
content:$content}]')\"\n  fi\n\n  # Final fallback: single empty user message to avoid --argjson errors\n  if [ -z \"$VALID_MESSAGES_JSON\" ]; then\n    VALID_MESSAGES_JSON='[{\"role\":\"user\"  
\"content\":\"\"}]'\n    log_warn \"PAYLOAD\" \"MESSAGES_JSON invalid or missing; using fallback single empty user message\"\n  fi\n\n  # Ensure messages is a non-empty array; if empty, fallback to single empty user message\n  if ! printf '%s' \"$VALID_MESSAGES_JSON\" | jq -e 'type==\"array\" and (length>0)' >/dev/null 2>&1; then\n    log_warn \"PAYLOAD\" \"VALID_MESSAGES_JSON is empty or not an array; using fallback single empty user message\"\n    VALID_MESSAGES_JSON='[{\"role\":\"user\"  
\"content\":\"\"}]'\n  fi\n\n  # If MODEL not set, try to read from BUILD_MESSAGES_FILE (if present and valid)\n  if [ -z \"${MODEL:-}\" ] && [ -n \"${BUILD_MESSAGES_FILE:-}\" ] && is_valid_json_file \"${BUILD_MESSAGES_FILE}\"; then\n    model_from_file=\"$(jq -r '.model // .provider?.model // empty' \"$BUILD_MESSAGES_FILE\" 2>/dev/null || true)\"\n    if [ -n \"$model_from_file\" ]; then\n      MODEL=\"$model_from_file\"\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"PAYLOAD\" \"MODEL set from BUILD_MESSAGES_FILE: ${MODEL}\"\n      fi\n    fi\n  fi\n\n  # Build payload using validated values; pass messages via validated JSON string\n  if ! jq -n --arg model \"${MODEL:-}\" --argjson stream \"$stream_json\" --arg ture \"$TURE\" --arg max_tokens \"$MAX_TOKENS\" \\\n       --argjson messages \"$(printf '%s' \"$VALID_MESSAGES_JSON\")\" \\\n       '{model:$model, stream:$stream, temperature:($ture|tonumber), max_tokens:($max_tokens|tonumber), messages:$messages }' >\"$tmp_payload\" 2>/dev/null; then\n    log_error \"PAYLOAD\" \"jq failed to build payload; tmp_payload not created\"\n    rm -f \"$tmp_payload\" 2>/dev/null || true\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  # Ensure tmp_payload is non-empty before proceeding\n  if [ ! -s \"$tmp_payload\" ]; then\n    log_error \"PAYLOAD\" \"tmp_payload is empty after jq; aborting\"\n    rm -f \"$tmp_payload\" 2>/dev/null || true\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  # Diagnostic: show payload path and content on stderr only when DEBUG=1 (safe: do not print API keys)\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    payload_size=$(wc -c < \"$tmp_payload\" 2>/dev/null || echo 0)\n    log_info \"PAYLOAD\" \"tmp_payload path: $tmp_payload size=${payload_size}B\"\n    log_info \"PAYLOAD\" \"tmp_payload content (head 2000 chars):\"\n    head -c 2000 \"$tmp_payload\" >&2 || true\n  fi\n\n  # If stage_b64 helper exists, create a base64-staged payload and prefer it (keeps backward compatibility)\n  staged_b64=\"\"\n  if type stage_b64 >/dev/null 2>&1; then\n    tmp_b64=\"${tmp_payload}.b64\"\n    if stage_b64 < \"$tmp_payload\" > \"$tmp_b64\" 2>/dev/null; then\n      staged_b64=\"$tmp_b64\"\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"PAYLOAD\" \"Created base64-staged payload: $staged_b64\"\n      fi\n    else\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_warn \"PAYLOAD\" \"stage_b64 failed; using raw JSON payload\"\n      fi\n      rm -f \"$tmp_b64\" 2>/dev/null || true\n    fi\n  fi\n\n  # Provide tmp_payload path for caller to use (do not export)\n  if [ -n \"$staged_b64\" ]; then\n    GROQBASH_TMP_PAYLOAD=\"$staged_b64\"\n    PAYLOAD=\"${PAYLOAD:-$staged_b64}\"\n  else\n    GROQBASH_TMP_PAYLOAD=\"$tmp_payload\"\n    PAYLOAD=\"${PAYLOAD:-$tmp_payload}\"\n  fi\n\n  return 0\n}"
```

---

**name**: "buildpayloadgroq"  

**file**: "groqbash"  

**line_range**: "L2322"  

**body_snippet**: 
```sh
# source: groqbash:2322\nbuildpayloadgroq() { buildpayload_groq \"$@\"; }
```

**line_start**: 2322  

**body_full**:
```sh
# source: groqbash:2322\nbuildpayloadgroq() { buildpayload_groq \"$@\"; }"
```

---

**name**: "call_api_groq"  

**file**: "groqbash"  

**line_range**: "L2327"  

**body_snippet**: 
```sh
# source: groqbash:2327\ncall_api_groq() {\n  # Robust non-streaming call to Groq API\n  # Expects: RUN_TMPDIR, RESP path variable, and payload file (GROQBASH_TMP_PAYLOAD or PAYLOAD)\n  local tmp_payload resp_tmp ERRF http_code rc resp_size errf_size now_ts stderr_head provider_url send_payload decoded_payload key_header CURL_CMD_ARR\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n\n  # Determine payload file to send\n  tmp_payload=\"${GROQBASH_TMP_PAYLOAD:-${PAYLOAD:-}}\"\n  if [ -z \"${tmp_payload:-}\" ]; then\n    log_error \"CALL\" \"no payload file specified (GROQBASH_TMP_PAYLOAD or PAYLOAD)\"\n    return 1\n  fi\n\n  # Network policy: same semantics as streaming path\n  if ! enforce_network_policy >/dev/null 2>&1; then\n    if is_truthy \"${DRY_RUN:-0}\"; then\n      # show_payload_head is diagnostic; show only when DEBUG=1\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        show_payload_head \"${PAYLOAD:-}\" 200 || true\n        log_info \"DRYRUN\" \"DRY-RUN: skipping non-streaming HTTP call\"\n      fi\n      return 0\n    fi\n    log_error \"NETWORK\" \"Network calls disabled; aborting non-streaming request.\"\n    return \"$GROQBASHERRCURL_FAILED\"\n  fi\n\n  # Ensure API key present (unless dry-run)\n  if [ -n \"${PROVIDER_API_ENV_groq:-}\" ] && [ -n \"${!PROVIDER_API_ENV_groq:-}\" ]; then\n    GROQ_API_KEY=\"${!PROVIDER_API_ENV_groq}\"\n  fi\n  if [ -z \"${GROQ_API_KEY:-}\" ] && [ -z \"${GROQBASH_API_KEY:-}\" ] && [ \"${DRY_RUN:-0}\" -ne 1 ]; then\n    log_error \"APIKEY\" \"GROQ_API_KEY (or GROQBASH_API_KEY) is not set.\"\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  # Use canonical provider URL resolved earlier by resolve_provider_url.\n  # Do not reconstruct provider_url locally; rely on GROQBASH_PROVIDER_URL.\n  if [ -z \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    # Best-effort: attempt to populate canonical provider URL now.\n    resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n  fi\n  provider_url=\"${GROQBASH_PROVIDER_URL:-}\"\n  if [ -z \"${provider_url:-}\" ]; then\n    log_error \"CALL\" \"no provider URL set (GROQBASH_PROVIDER_URL)\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"no_provider_url\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  # Safety: refuse to call curl with empty payload\n  if [ ! -s \"$tmp_payload\" ]; then\n    log_error \"PAYLOAD\" \"Refusing to call curl: payload file is empty or missing: $tmp_payload\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"empty_payload\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  # If payload is base64-staged (.b64), decode to a temporary file for sending\n  send_payload=\"$tmp_payload\"\n  decoded_payload=\"\"\n  if printf '%s' \"$tmp_payload\" | grep -qE '\\.b64$'; then\n    decoded_payload=\"${RUN_TMPDIR%/}/payload.dec.$$\"\n    if ! b64decode < \"$tmp_payload\" > \"$decoded_payload\" 2> /dev/null; then\n      log_error \"B64DECODE\" \"base64 decode failed for payload; aborting non-streaming call\"\n      rm -f \"$decoded_payload\" 2>/dev/null || true\n      now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      jq -c -n --arg ts \"$now_ts\" --arg note \"b64_decode_failed\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n      return \"$GROQBASHERRTMP\"\n    fi\n    # ensure decoded payload is non-empty\n    if [ ! -s \"$decoded_payload\" ]; then\n      log_error \"PAYLOAD\" \"decoded payload is empty; aborting\"\n      rm -f \"$decoded_payload\" 2>/dev/null || true\n      now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      jq -c -n --arg ts \"$now_ts\" --arg note \"empty_decoded_payload\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n      return 1\n    fi\n    send_payload=\"$decoded_payload\"\n  fi\n\n  # Prepare tmp files\n  resp_tmp=\"${RUN_TMPDIR%/}/resp.json\"\n  ERRF=\"${RUN_TMPDIR%/}/curl.err\"\n  : > \"$ERRF\" 2>/dev/null || true\n  rm -f \"$resp_tmp\" 2>/dev/null || true\n\n  # Diagnostic: l
```

**line_start**: 2327  

**body_full**:
```sh
# source: groqbash:2327\ncall_api_groq() {\n  # Robust non-streaming call to Groq API\n  # Expects: RUN_TMPDIR, RESP path variable, and payload file (GROQBASH_TMP_PAYLOAD or PAYLOAD)\n  local tmp_payload resp_tmp ERRF http_code rc resp_size errf_size now_ts stderr_head provider_url send_payload decoded_payload key_header CURL_CMD_ARR\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n\n  # Determine payload file to send\n  tmp_payload=\"${GROQBASH_TMP_PAYLOAD:-${PAYLOAD:-}}\"\n  if [ -z \"${tmp_payload:-}\" ]; then\n    log_error \"CALL\" \"no payload file specified (GROQBASH_TMP_PAYLOAD or PAYLOAD)\"\n    return 1\n  fi\n\n  # Network policy: same semantics as streaming path\n  if ! enforce_network_policy >/dev/null 2>&1; then\n    if is_truthy \"${DRY_RUN:-0}\"; then\n      # show_payload_head is diagnostic; show only when DEBUG=1\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        show_payload_head \"${PAYLOAD:-}\" 200 || true\n        log_info \"DRYRUN\" \"DRY-RUN: skipping non-streaming HTTP call\"\n      fi\n      return 0\n    fi\n    log_error \"NETWORK\" \"Network calls disabled; aborting non-streaming request.\"\n    return \"$GROQBASHERRCURL_FAILED\"\n  fi\n\n  # Ensure API key present (unless dry-run)\n  if [ -n \"${PROVIDER_API_ENV_groq:-}\" ] && [ -n \"${!PROVIDER_API_ENV_groq:-}\" ]; then\n    GROQ_API_KEY=\"${!PROVIDER_API_ENV_groq}\"\n  fi\n  if [ -z \"${GROQ_API_KEY:-}\" ] && [ -z \"${GROQBASH_API_KEY:-}\" ] && [ \"${DRY_RUN:-0}\" -ne 1 ]; then\n    log_error \"APIKEY\" \"GROQ_API_KEY (or GROQBASH_API_KEY) is not set.\"\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  # Use canonical provider URL resolved earlier by resolve_provider_url.\n  # Do not reconstruct provider_url locally; rely on GROQBASH_PROVIDER_URL.\n  if [ -z \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    # Best-effort: attempt to populate canonical provider URL now.\n    resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n  fi\n  provider_url=\"${GROQBASH_PROVIDER_URL:-}\"\n  if [ -z \"${provider_url:-}\" ]; then\n    log_error \"CALL\" \"no provider URL set (GROQBASH_PROVIDER_URL)\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"no_provider_url\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  # Safety: refuse to call curl with empty payload\n  if [ ! -s \"$tmp_payload\" ]; then\n    log_error \"PAYLOAD\" \"Refusing to call curl: payload file is empty or missing: $tmp_payload\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"empty_payload\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  # If payload is base64-staged (.b64), decode to a temporary file for sending\n  send_payload=\"$tmp_payload\"\n  decoded_payload=\"\"\n  if printf '%s' \"$tmp_payload\" | grep -qE '\\.b64$'; then\n    decoded_payload=\"${RUN_TMPDIR%/}/payload.dec.$$\"\n    if ! b64decode < \"$tmp_payload\" > \"$decoded_payload\" 2> /dev/null; then\n      log_error \"B64DECODE\" \"base64 decode failed for payload; aborting non-streaming call\"\n      rm -f \"$decoded_payload\" 2>/dev/null || true\n      now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      jq -c -n --arg ts \"$now_ts\" --arg note \"b64_decode_failed\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n      return \"$GROQBASHERRTMP\"\n    fi\n    # ensure decoded payload is non-empty\n    if [ ! -s \"$decoded_payload\" ]; then\n      log_error \"PAYLOAD\" \"decoded payload is empty; aborting\"\n      rm -f \"$decoded_payload\" 2>/dev/null || true\n      now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n      jq -c -n --arg ts \"$now_ts\" --arg note \"empty_decoded_payload\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n      return 1\n    fi\n    send_payload=\"$decoded_payload\"\n  fi\n\n  # Prepare tmp files\n  resp_tmp=\"${RUN_TMPDIR%/}/resp.json\"\n  ERRF=\"${RUN_TMPDIR%/}/curl.err\"\n  : > \"$ERRF\" 2>/dev/null || true\n  rm -f \"$resp_tmp\" 2>/dev/null || true\n\n  # Diagnostic: log call only when DEBUG=1\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"CALL\" \"Invoking curl to provider (payload: $send_payload) -> $provider_url\"\n  fi\n\n  # Choose Authorization header if key present\n  # Build curl command: prefer http1.1, follow redirects for non-streaming, include CURL_BASE_OPTS if set\n  CURL_CMD_ARR=()\n  if command -v stdbuf >/dev/null 2>&1; then\n    CURL_CMD_ARR+=(stdbuf -oL curl --http1.1 -sS -L)\n  else\n    CURL_CMD_ARR+=(curl --http1.1 -sS -L)\n  fi\n\n  # Append any global base opts if defined\n  if [ -n \"${CURL_BASE_OPTS[*]:-}\" ]; then\n    CURL_CMD_ARR+=(\"${CURL_BASE_OPTS[@]}\")\n  fi\n\n  # Always include Content-Type header and Authorization if available\n  CURL_CMD_ARR+=( -H \"Content-Type: application/json\" )\n  if [ -n \"${GROQ_API_KEY:-}\" ]; then\n    CURL_CMD_ARR+=( -H \"Authorization: Bearer ${GROQ_API_KEY}\" )\n  elif [ -n \"${GROQBASH_API_KEY:-}\" ]; then\n    CURL_CMD_ARR+=( -H \"Authorization: Bearer ${GROQBASH_API_KEY}\" )\n  fi\n\n  # Execute curl: write body to resp_tmp, capture http_code via -w, stderr to ERRF\n  # Do NOT use --fail (we want body even on 4xx/5xx)\n  http_code=\"$(\"${CURL_CMD_ARR[@]}\" -o \"$resp_tmp\" -w '%{http_code}' --data-binary @\"$send_payload\" \"$provider_url\" 2> \"$ERRF\")\"\n  rc=$?\n\n  # Cleanup decoded payload if used\n  if [ -n \"$decoded_payload\" ]; then\n    rm -f \"$decoded_payload\" 2>/dev/null || true\n  fi\n\n  # Capture diagnostics immediately\n  resp_size=0; [ -f \"$resp_tmp\" ] && resp_size=$(wc -c < \"$resp_tmp\" 2>/dev/null || echo 0)\n  errf_size=0; [ -f \"$ERRF\" ] && errf_size=$(wc -c < \"$ERRF\" 2>/dev/null || echo 0)\n\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"CURL\" \"curl rc=${rc} http_code=${http_code:-?} resp_tmp_size=${resp_size}B ERRF_size=${errf_size}B resp_tmp='${resp_tmp}' ERRF='${ERRF}'\"\n    if [ -s \"$ERRF\" ]; then\n      log_info \"CURL\" \"curl stderr (head 400 chars):\"\n      head -c 400 \"$ERRF\" 2>/dev/null | sed -n '1,20p' >&2 || true\n    fi\n    if [ -s \"$resp_tmp\" ]; then\n      log_info \"CURL\" \"resp_tmp content (head 400 chars):\"\n      head -c 400 \"$resp_tmp\" 2>/dev/null | sed -n '1,20p' >&2 || true\n    fi\n  fi\n\n  if [ -s \"$resp_tmp\" ]; then\n    # Ensure file ends with newline to avoid concatenation with subsequent output\n    # Use tail -c1 if available, otherwise use awk to check last character\n    last_char=\"\"\n    if command -v tail >/dev/null 2>&1; then\n      last_char=\"$(tail -c 1 \"$resp_tmp\" 2>/dev/null || printf '')\"\n    else\n      last_char=\"$(awk 'END{printf \"%s\"  
 substr($0,length($0),1)}' \"$resp_tmp\" 2>/dev/null || printf '')\"\n    fi\n    if [ \"$last_char\" != $'\\n' ]; then\n      printf '\\n' >> \"$resp_tmp\" 2>/dev/null || true\n      resp_size=$((resp_size + 1)) 2>/dev/null || true\n    fi\n\n    # If resp_tmp is not valid JSON, attempt a conservative diagnostic extraction:\n    if ! jq -e . \"$resp_tmp\" >/dev/null 2>&1; then\n      prefix_file=\"${resp_tmp}.json_prefix\"\n      tail_file=\"${resp_tmp}.tail\"\n      awk '\n        BEGIN { in_str=0; depth=0; started=0; }\n        {\n          line=$0\n          for (i=1;i<=length(line);i++) {\n            c=substr(line,i,1)\n            if (c==\"\\\"\") { in_str = !in_str; }\n            if (!in_str) {\n              if (c==\"{\" || c==\"[\") { if (depth==0) started=1; depth++; }\n              else if (c==\"}\" || c==\"]\") { depth--; if (depth==0) { print substr(line,1,i); exit } }\n            }\n          }\n          if (started) print \"\"\n        }' \"$resp_tmp\" > \"$prefix_file\" 2>/dev/null || true\n\n      if [ -s \"$prefix_file\" ] && jq -e . \"$prefix_file\" >/dev/null 2>&1; then\n        # Save trailing content for manual inspection (files only; messages suppressed unless DEBUG)\n        printf '--- TRAILING NON-JSON DATA (diagnostic) ---\\n' > \"$tail_file\" 2>/dev/null || true\n        cat \"$resp_tmp\" >> \"$tail_file\" 2>/dev/null || true\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"RESP\" \"Created diagnostic prefix/tail files: ${prefix_file} ${tail_file}\"\n        fi\n      else\n        rm -f \"$prefix_file\" 2>/dev/null || true\n      fi\n    fi\n  fi\n\n  # Defensive RESP fallback and directory creation\n  if [ -z \"${RESP:-}\" ]; then\n    RESP=\"${RUN_TMPDIR%/}/resp.json\"\n  fi\n  mkdir -p \"$(dirname \"$RESP\")\" 2>/dev/null || true\n\n  # Attempt to move resp_tmp -> RESP, fallback to cp, then diagnostic\n  if [ -s \"$resp_tmp\" ]; then\n    # If resp_tmp and RESP are identical paths, skip mv/cp (nothing to do)\n    if [ \"${resp_tmp%/}\" = \"${RESP%/}\" ]; then\n      chmod 600 \"$RESP\" 2>/dev/null || true\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"RESP\" \"RESP already at resp_tmp: ${RESP}\"\n      fi\n    else\n      if mv -f \"$resp_tmp\" \"${RESP}\" 2>/dev/null; then\n        chmod 600 \"${RESP}\" 2>/dev/null || true\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"RESP\" \"Wrote RESP from resp_tmp: ${RESP}\"\n        fi\n      else\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_warn \"RESP\" \"mv failed; attempting cp to write RESP\"\n        fi\n        if cp -f \"$resp_tmp\" \"${RESP}\" 2>/dev/null; then\n          chmod 600 \"${RESP}\" 2>/dev/null || true\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"RESP\" \"Wrote RESP via cp: ${RESP}\"\n          fi\n        else\n          log_error \"RESP\" \"failed to write RESP from resp_tmp; writing diagnostic RESP\"\n          now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n          stderr_head=\"$(head -c 200 \"${ERRF:-/dev/null}\" 2>/dev/null | sed 's/\"/\\\\\"/g' || true)\"\n          jq -c -n --arg http \"${http_code:-0}\" --arg ts \"$now_ts\" --arg err \"$stderr_head\" \\\n            '{diagnostic:true, last_http_status:($http|tonumber), last_time_utc:$ts, stderr_head:$err}' > \"${RESP}\" 2>/dev/null || true\n        fi\n      fi\n    fi\n  else\n    # resp_tmp empty: write diagnostic RESP (only in this case) and log clearly (log suppressed unless DEBUG)\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_warn \"RESP\" \"resp_tmp empty; writing diagnostic RESP (no body received). This is diagnostic only and does not mask real responses.\"\n    fi\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    stderr_head=\"$(head -c 200 \"${ERRF:-/dev/null}\" 2>/dev/null | sed 's/\"/\\\\\"/g' || true)\"\n    jq -c -n --arg http \"${http_code:-0}\" --arg ts \"$now_ts\" --arg err \"$stderr_head\" \\\n      '{diagnostic:true, last_http_status:($http|tonumber), last_time_utc:$ts, stderr_head:$err}' > \"${RESP}\" 2>/dev/null || printf '{\"diagnostic\":true,\"last_http_status\":%s,\"last_time_utc\":\"%s\"}\\n' \"${http_code:-0}\" \"$now_ts\" > \"${RESP}\"\n  fi\n\n  # Return transport rc (0 if curl succeeded at transport level)\n  return \"${rc:-0}\"\n}"
```

---

**name**: "call_api_streaming_groq"  

**file**: "groqbash"  

**line_range**: "L2570"  

**body_snippet**: 
```sh
# source: groqbash:2570\ncall_api_streaming_groq() {\n  # Streaming call for Groq provider with robust checks and diagnostics.\n  # Expects: RUN_TMPDIR, RESP variable, and payload file (GROQBASH_TMP_PAYLOAD or PAYLOAD).\n  local tmp_payload provider_url resp_raw resp_lines resp_valid resp_chunks resp_tmp ERRF rc stderr_head now_ts decoded_payload finish_reason req_id edgecase send_payload CURL_CMD\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n\n  # Network policy and API key checks (preserve existing repo semantics)\n  if ! enforce_network_policy >/dev/null 2>&1; then\n    if is_truthy \"${DRY_RUN:-0}\"; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        show_payload_head \"${PAYLOAD:-}\" 200 || true\n        log_info \"DRYRUN\" \"DRY-RUN: skipping streaming HTTP call\"\n      fi\n      return 0\n    fi\n    log_error \"NETWORK\" \"Network calls disabled; aborting streaming request.\"\n    return \"$GROQBASHERRCURL_FAILED\"\n  fi\n\n  if [ -n \"${PROVIDER_API_ENV_groq:-}\" ] && [ -n \"${!PROVIDER_API_ENV_groq:-}\" ]; then\n    GROQ_API_KEY=\"${!PROVIDER_API_ENV_groq}\"\n  fi\n  if [ -z \"${GROQ_API_KEY:-}\" ] && [ -z \"${GROQBASH_API_KEY:-}\" ]; then\n    log_error \"APIKEY\" \"GROQ_API_KEY (or GROQBASH_API_KEY) is not set.\"\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  tmp_payload=\"${GROQBASH_TMP_PAYLOAD:-${PAYLOAD:-}}\"\n  if [ -z \"${tmp_payload:-}\" ]; then\n    log_error \"CALL_STREAM\" \"no payload file specified (GROQBASH_TMP_PAYLOAD or PAYLOAD)\"\n    return 1\n  fi\n  if [ ! -s \"$tmp_payload\" ]; then\n    log_error \"CALL_STREAM\" \"Refusing to call curl: payload file is empty or missing: $tmp_payload\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"empty_payload\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  # Use canonical provider URL resolved earlier by resolve_provider_url.\n  # Do not reconstruct provider_url locally; rely on GROQBASH_PROVIDER_URL.\n  if [ -z \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    # Best-effort: attempt to populate canonical provider URL now.\n    resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n  fi\n  provider_url=\"${GROQBASH_PROVIDER_URL:-}\"\n  if [ -z \"${provider_url:-}\" ]; then\n    log_error \"CALL_STREAM\" \"no provider URL set (GROQBASH_PROVIDER_URL)\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"no_provider_url\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  resp_raw=\"${RUN_TMPDIR%/}/resp.raw\"\n  resp_lines=\"${RUN_TMPDIR%/}/resp.lines\"\n  resp_valid=\"${RUN_TMPDIR%/}/resp.valid.jsons\"\n  resp_chunks=\"${RUN_TMPDIR%/}/resp.chunks.json\"\n  ERRF=\"${RUN_TMPDIR%/}/curl_stream.err\"\n  : > \"$ERRF\" 2>/dev/null || true\n  rm -f \"$resp_raw\" \"$resp_lines\" \"$resp_valid\" \"$resp_chunks\" 2>/dev/null || true\n\n  # Diagnostic: log streaming call only when DEBUG=1\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"CALL_STREAM\" \"Invoking streaming curl to $provider_url (payload: $tmp_payload)\"\n  fi\n\n  # Prepare decoded payload if payload is base64 staged\n  decoded_payload=\"${RUN_TMPDIR%/}/payload.dec.$$\"\n  if printf '%s' \"${tmp_payload}\" | grep -qE '\\.b64$'; then\n    if ! b64decode < \"$tmp_payload\" > \"$decoded_payload\" 2>\"$ERRF\"; then\n      log_error \"B64DECODE\" \"base64 decode failed for payload; see $ERRF\"\n      rm -f \"$decoded_payload\" 2>/dev/null || true\n      return \"$GROQBASHERRTMP\"\n    fi\n    send_payload=\"$decoded_payload\"\n  else\n    send_payload=\"$tmp_payload\"\n  fi\n\n  # Build curl command (use http1.1 to avoid some server buffering issues)\n  if command -v stdbuf >/dev/null 2>&1; then\n    CURL_CMD=(stdbuf -oL curl --http1.1 -sS -N)\n  else\n    CURL_CMD=(curl --http1.1 -sS -N)\n  fi\n\n  # Stream: capture raw stream to file and process lines for \"data: \" JSON chunks\n  \"${CURL_CMD[@]}\" -H \"Authorization: Bearer ${GROQ_API_KEY:-${GROQBASH_API_KEY:-}}\" -H \"Content-Type: application/json\" --data-binary @\"$send_payload\" \"$provider_url\" 2> \"$ERRF\" | tee -a
```

**line_start**: 2570  

**body_full**:
```sh
# source: groqbash:2570\ncall_api_streaming_groq() {\n  # Streaming call for Groq provider with robust checks and diagnostics.\n  # Expects: RUN_TMPDIR, RESP variable, and payload file (GROQBASH_TMP_PAYLOAD or PAYLOAD).\n  local tmp_payload provider_url resp_raw resp_lines resp_valid resp_chunks resp_tmp ERRF rc stderr_head now_ts decoded_payload finish_reason req_id edgecase send_payload CURL_CMD\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n\n  # Network policy and API key checks (preserve existing repo semantics)\n  if ! enforce_network_policy >/dev/null 2>&1; then\n    if is_truthy \"${DRY_RUN:-0}\"; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        show_payload_head \"${PAYLOAD:-}\" 200 || true\n        log_info \"DRYRUN\" \"DRY-RUN: skipping streaming HTTP call\"\n      fi\n      return 0\n    fi\n    log_error \"NETWORK\" \"Network calls disabled; aborting streaming request.\"\n    return \"$GROQBASHERRCURL_FAILED\"\n  fi\n\n  if [ -n \"${PROVIDER_API_ENV_groq:-}\" ] && [ -n \"${!PROVIDER_API_ENV_groq:-}\" ]; then\n    GROQ_API_KEY=\"${!PROVIDER_API_ENV_groq}\"\n  fi\n  if [ -z \"${GROQ_API_KEY:-}\" ] && [ -z \"${GROQBASH_API_KEY:-}\" ]; then\n    log_error \"APIKEY\" \"GROQ_API_KEY (or GROQBASH_API_KEY) is not set.\"\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  tmp_payload=\"${GROQBASH_TMP_PAYLOAD:-${PAYLOAD:-}}\"\n  if [ -z \"${tmp_payload:-}\" ]; then\n    log_error \"CALL_STREAM\" \"no payload file specified (GROQBASH_TMP_PAYLOAD or PAYLOAD)\"\n    return 1\n  fi\n  if [ ! -s \"$tmp_payload\" ]; then\n    log_error \"CALL_STREAM\" \"Refusing to call curl: payload file is empty or missing: $tmp_payload\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"empty_payload\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  # Use canonical provider URL resolved earlier by resolve_provider_url.\n  # Do not reconstruct provider_url locally; rely on GROQBASH_PROVIDER_URL.\n  if [ -z \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    # Best-effort: attempt to populate canonical provider URL now.\n    resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n  fi\n  provider_url=\"${GROQBASH_PROVIDER_URL:-}\"\n  if [ -z \"${provider_url:-}\" ]; then\n    log_error \"CALL_STREAM\" \"no provider URL set (GROQBASH_PROVIDER_URL)\"\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    jq -c -n --arg ts \"$now_ts\" --arg note \"no_provider_url\" '{diagnostic:true, note:$note, time:$ts}' > \"${RESP:-$RUN_TMPDIR/resp.json}\" 2>/dev/null || true\n    return 1\n  fi\n\n  resp_raw=\"${RUN_TMPDIR%/}/resp.raw\"\n  resp_lines=\"${RUN_TMPDIR%/}/resp.lines\"\n  resp_valid=\"${RUN_TMPDIR%/}/resp.valid.jsons\"\n  resp_chunks=\"${RUN_TMPDIR%/}/resp.chunks.json\"\n  ERRF=\"${RUN_TMPDIR%/}/curl_stream.err\"\n  : > \"$ERRF\" 2>/dev/null || true\n  rm -f \"$resp_raw\" \"$resp_lines\" \"$resp_valid\" \"$resp_chunks\" 2>/dev/null || true\n\n  # Diagnostic: log streaming call only when DEBUG=1\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"CALL_STREAM\" \"Invoking streaming curl to $provider_url (payload: $tmp_payload)\"\n  fi\n\n  # Prepare decoded payload if payload is base64 staged\n  decoded_payload=\"${RUN_TMPDIR%/}/payload.dec.$$\"\n  if printf '%s' \"${tmp_payload}\" | grep -qE '\\.b64$'; then\n    if ! b64decode < \"$tmp_payload\" > \"$decoded_payload\" 2>\"$ERRF\"; then\n      log_error \"B64DECODE\" \"base64 decode failed for payload; see $ERRF\"\n      rm -f \"$decoded_payload\" 2>/dev/null || true\n      return \"$GROQBASHERRTMP\"\n    fi\n    send_payload=\"$decoded_payload\"\n  else\n    send_payload=\"$tmp_payload\"\n  fi\n\n  # Build curl command (use http1.1 to avoid some server buffering issues)\n  if command -v stdbuf >/dev/null 2>&1; then\n    CURL_CMD=(stdbuf -oL curl --http1.1 -sS -N)\n  else\n    CURL_CMD=(curl --http1.1 -sS -N)\n  fi\n\n  # Stream: capture raw stream to file and process lines for \"data: \" JSON chunks\n  \"${CURL_CMD[@]}\" -H \"Authorization: Bearer ${GROQ_API_KEY:-${GROQBASH_API_KEY:-}}\" -H \"Content-Type: application/json\" --data-binary @\"$send_payload\" \"$provider_url\" 2> \"$ERRF\" | tee -a \"$resp_raw\" | \\\n  while IFS= read -r line; do\n    # Normalize and emit content to stdout for interactive consumption\n    case \"$line\" in\n      'data: [DONE]'|'data:[DONE]') break ;;\n      data:\\ * )\n        json=\"${line#data: }\"\n        # Try to parse JSON and extract incremental content safely\n        content=\"$(printf '%s' \"$json\" | jq -r 'try (fromjson | (.choices[]?.delta?.content // .choices[]?.message?.content // \"\")) catch \"\"' 2>>\"$ERRF\" || true)\"\n        if [ -n \"$content\" ]; then\n          printf '%s' \"$content\"\n        fi\n        ;;\n      *)\n        # Some streams may emit raw JSON lines without \"data: \" prefix\n        if printf '%s' \"$line\" | jq -e . >/dev/null 2>&1; then\n          content=\"$(printf '%s' \"$line\" | jq -r '(.choices[]?.delta?.content // .choices[]?.message?.content // \"\")' 2>>\"$ERRF\" || true)\"\n          if [ -n \"$content\" ]; then\n            printf '%s' \"$content\"\n          fi\n        fi\n        ;;\n    esac\n  done\n\n  # Capture curl exit code from pipeline\n  rc=${PIPESTATUS[0]:-0}\n\n  # Cleanup decoded payload if used\n  rm -f \"$decoded_payload\" 2>/dev/null || true\n\n  # Diagnostics: sizes and stderr head (only printed when DEBUG=1)\n  local resp_size errf_size\n  resp_size=0; [ -f \"$resp_raw\" ] && resp_size=$(wc -c < \"$resp_raw\" 2>/dev/null || echo 0)\n  errf_size=0; [ -f \"$ERRF\" ] && errf_size=$(wc -c < \"$ERRF\" 2>/dev/null || echo 0)\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"CALL_STREAM\" \"curl rc=${rc} resp_raw_size=${resp_size}B ERRF_size=${errf_size}B resp_raw='${resp_raw}' ERRF='${ERRF}'\"\n    if [ -s \"$ERRF\" ]; then\n      log_info \"CALL_STREAM\" \"curl stderr (head 400 chars):\"\n      head -c 400 \"$ERRF\" 2>/dev/null | sed -n '1,20p' >&2 || true\n    fi\n    if [ -s \"$resp_raw\" ]; then\n      log_info \"CALL_STREAM\" \"resp_raw head (first 400 chars):\"\n      head -c 400 \"$resp_raw\" 2>/dev/null | sed -n '1,20p' >&2 || true\n    fi\n  fi\n\n  # Extract lines starting with \"data:\" into resp.lines\n  if [ -s \"$resp_raw\" ]; then\n    grep -E '^data:' \"$resp_raw\" 2>/dev/null | sed -E 's/^data:[[:space:]]*//' > \"$resp_lines\" 2>/dev/null || true\n  fi\n\n  # Validate JSON lines and collect valid ones\n  : > \"$resp_valid\" 2>/dev/null || true\n  if [ -f \"$resp_lines\" ] && [ -s \"$resp_lines\" ]; then\n    while IFS= read -r _line; do\n      if printf '%s' \"$_line\" | jq -e . >/dev/null 2>&1; then\n        printf '%s\\n' \"$_line\" >> \"$resp_valid\"\n      fi\n    done < \"$resp_lines\"\n  fi\n\n  # If we have valid JSONs, assemble into chunks array\n  if [ -s \"$resp_valid\" ]; then\n    jq -s '.' \"$resp_valid\" > \"$resp_chunks\" 2>/dev/null || true\n    # produce a concatenated text file for convenience\n    jq -r 'map(.choices[]?.delta?.content // .choices[]?.message?.content // \"\") | join(\"\")' \"$resp_chunks\" > \"${RUN_TMPDIR%/}/resp.text.txt\" 2>/dev/null || true\n    # write final JSON: prefer last object as final response\n    if jq -e 'type==\"array\"' \"$resp_chunks\" >/dev/null 2>&1; then\n      jq -c '.[-1]' \"$resp_chunks\" > \"${RUN_TMPDIR%/}/resp.json\" 2>/dev/null || true\n    else\n      cp -f \"$resp_chunks\" \"${RUN_TMPDIR%/}/resp.json\" 2>/dev/null || true\n    fi\n  else\n    # If no data: lines but resp_raw itself is valid JSON, copy it\n    if jq -e . \"$resp_raw\" >/dev/null 2>&1; then\n      cp -f \"$resp_raw\" \"${RUN_TMPDIR%/}/resp.json\" 2>/dev/null || true\n    fi\n  fi\n\n  # Finalize RESP: move resp.json -> RESP if present, else write diagnostic\n  resp_tmp=\"${RUN_TMPDIR%/}/resp.json\"\n\n  # Defensive RESP fallback and directory creation\n  if [ -z \"${RESP:-}\" ]; then\n    RESP=\"${RUN_TMPDIR%/}/resp.json\"\n  fi\n  mkdir -p \"$(dirname \"$RESP\")\" 2>/dev/null || true\n\n  if [ -s \"$resp_tmp\" ]; then\n    # If resp_tmp and RESP are identical paths, skip mv/cp (nothing to do)\n    if [ \"${resp_tmp%/}\" = \"${RESP%/}\" ]; then\n      chmod 600 \"${RESP}\" 2>/dev/null || true\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"CALL_STREAM\" \"RESP already at resp_tmp: ${RESP}\"\n      fi\n    else\n      if mv -f \"$resp_tmp\" \"${RESP}\" 2>/dev/null; then\n        chmod 600 \"${RESP}\" 2>/dev/null || true\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"CALL_STREAM\" \"Wrote RESP from streaming output: ${RESP}\"\n        fi\n      else\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_warn \"CALL_STREAM\" \"mv failed; attempting cp to write RESP\"\n        fi\n        if cp -f \"$resp_tmp\" \"${RESP}\" 2>/dev/null; then\n          chmod 600 \"${RESP}\" 2>/dev/null || true\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            log_info \"CALL_STREAM\" \"Wrote RESP via cp: ${RESP}\"\n          fi\n        else\n          log_error \"CALL_STREAM\" \"failed to write RESP from streaming output\"\n          # fallback diagnostic write\n          now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n          stderr_head=\"$(head -c 200 \"${ERRF:-/dev/null}\" 2>/dev/null | sed 's/\"/\\\\\"/g' || true)\"\n          jq -c -n --arg http \"0\" --arg ts \"$now_ts\" --arg err \"$stderr_head\" \\\n            '{diagnostic:true, streaming:true, last_http_status:($http|tonumber), last_time_utc:$ts, stderr_head:$err}' > \"${RESP}\" 2>/dev/null || true\n        fi\n      fi\n    fi\n  else\n    # No final JSON extracted: write diagnostic RESP (only in this case)\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_warn \"CALL_STREAM\" \"No JSON chunks extracted from stream; writing diagnostic RESP\"\n    fi\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    stderr_head=\"$(head -c 200 \"$ERRF\" 2>/dev/null | sed 's/\"/\\\\\"/g' || true)\"\n    jq -c -n --arg http \"0\" --arg ts \"$now_ts\" --arg err \"$stderr_head\" \\\n      '{diagnostic:true, streaming:true, last_http_status:($http|tonumber), last_time_utc:$ts, stderr_head:$err}' > \"${RESP}\" 2>/dev/null || true\n  fi\n\n  # Write last API metadata to ui_state (best-effort)\n  if ensure_run_tmpdir >/dev/null 2>&1; then\n    http_code=200\n    finish_reason=\"$(jq -r '.choices[0]?.finish_reason // empty' \"${RESP}\" 2>/dev/null || echo \"\")\"\n    req_id=\"$(jq -r '.x_groq?.id // .id // empty' \"${RESP}\" 2>/dev/null || echo \"\")\"\n    edgecase=0\n    if [ \"${GROQBASH_EDGE_EMPTY:-0}\" -eq 1 ]; then edgecase=1; fi\n    now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n    api_json=\"$(jq -c -n --argjson http \"$http_code\" --arg fr \"${finish_reason:-}\" --argjson edge \"$edgecase\" --arg id \"${req_id:-}\" --arg ts \"$now_ts\" '{last_http_status:$http, last_finish_reason:$fr, last_edgecase_detected:$edge, last_req_id:$id, last_time_utc:$ts}')\"\n    ui_state_write \"last_api.json\" \"$api_json\" || { if [ \"${DEBUG:-0}\" -eq 1 ]; then log_warn \"UI_STATE\" \"failed to write last_api.json (streaming)\"; fi; }\n  fi\n\n  return \"${rc:-0}\"\n}"
```

---

**name**: "call_api_streaming_groq_legacy"  

**file**: "groqbash"  

**line_range**: "L2805"  

**body_snippet**: 
```sh
# source: groqbash:2805\ncall_api_streaming_groq_legacy() { call_api_streaming_groq \"$@\"; }
```

**line_start**: 2805  

**body_full**:
```sh
# source: groqbash:2805\ncall_api_streaming_groq_legacy() { call_api_streaming_groq \"$@\"; }"
```

---

**name**: "refresh_models_groq"  

**file**: "groqbash"  

**line_range**: "L2813"  

**body_snippet**: 
```sh
# source: groqbash:2813\nrefresh_models_groq() {\n  # Fetch Groq models and write normalized model names to MODELS_FILE.\n  # Prefer .data[].name then .data[].id then top-level array .[].name/.id.\n  if [ -n \"${PROVIDER_API_ENV_groq:-}\" ] && [ -n \"${!PROVIDER_API_ENV_groq:-}\" ]; then\n    GROQ_API_KEY=\"${!PROVIDER_API_ENV_groq}\"\n  fi\n  if [ -z \"${GROQ_API_KEY:-}\" ]; then\n    log_error \"APIKEY\" \"GROQ_API_KEY is required to refresh models.\"\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n  local workdir tmpd out errf api_url tmp_parsed tmp_trim tmpout rc\n  workdir=\"${RUN_TMPDIR:-}\"\n  [ -n \"$workdir\" ] || return \"$GROQBASHERRTMP\"\n  tmpd=\"$(mktemp -d -p \"$workdir\" groq-models.XXXX)\" || return \"$GROQBASHERRTMP\"\n  out=\"$tmpd/models.json\"\n  errf=\"$tmpd/curl.err\"\n  # Derive models API URL from the canonical provider URL (GROQBASH_PROVIDER_URL).\n  # Do not introduce new env var semantics; attempt to resolve provider URL if needed.\n  resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n  if [ -n \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    # Extract origin (scheme + host[:port]) and append canonical models path.\n    origin=\"$(printf '%s' \"$GROQBASH_PROVIDER_URL\" | sed -E 's#(https?://[^/]+).*#\\1#')\"\n    api_url=\"${origin%/}/openai/v1/models\"\n  else\n    # Fallback to embedded groq models endpoint only if provider is groq (preserve prior behavior).\n    if [ \"${PROVIDER:-}\" = \"groq\" ]; then\n      # Do not introduce new env var semantics; attempt to resolve provider URL if needed.\n      resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n      if [ -n \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n        # Extract origin (scheme + host[:port]) and append canonical models path.\n        origin=\"$(printf '%s' \"$GROQBASH_PROVIDER_URL\" | sed -E 's#(https?://[^/]+).*#\\1#')\"\n        api_url=\"${origin%/}/openai/v1/models\"\n      else\n        # No canonical provider URL available: fail (do not use hardcoded endpoint).\n        log_error \"MODELREFRESH\" \"no provider URL available to refresh models\"\n        rm -rf \"$tmpd\"\n        return \"$GROQBASHERRAPI\"\n      fi\n    else\n      log_error \"MODELREFRESH\" \"no provider URL available to refresh models\"\n      rm -rf \"$tmpd\"\n      return \"$GROQBASHERRAPI\"\n    fi\n  fi\n\n  rm -f \"$out\" \"$errf\" 2>/dev/null || true\n  if ! curl \"${CURL_BASE_OPTS[@]}\" -H \"Authorization: Bearer ${GROQ_API_KEY}\" -H \"Content-Type: application/json\" \"${api_url}?limit=${MAX_MODELS}\" -o \"$out\" 2>\"$errf\"; then\n    log_error \"MODELREFRESH\" \"Failed to fetch models from $api_url\"\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      head -n 200 \"$errf\" >&2 || true\n    fi\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  if ! jq -e . \"$out\" >/dev/null 2>&1; then\n    log_error \"MODELREFRESH\" \"Invalid JSON received from $api_url\"\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      head -n 200 \"$errf\" >&2 || true\n    fi\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  tmp_parsed=\"$tmpd/parsed_models.txt\"\n  : > \"$tmp_parsed\"\n\n  # Extract candidate names: prefer .data[].name, then .data[].id, then top-level array .[].name/.id\n  jq -r '\n    if (has(\"data\") and (.data|type) == \"array\") then\n      .data[]? | (.name // .id // empty)\n    elif (type == \"array\") then\n      .[]? | (.name // .id // empty)\n    else\n      empty\n    end\n  ' \"$out\" | awk 'NF{print}' | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' | sort -u > \"$tmp_parsed\" 2>/dev/null || true\n\n  if [ ! -s \"$tmp_parsed\" ]; then\n    log_error \"MODELREFRESH\" \"models refresh: parsed list empty\"\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      head -n 200 \"$errf\" >&2 || true\n    fi\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  # Normalize entries: strip common prefixes like \"models/\" and \"groq:\"; validate allowed chars\n  tmp_trim=\"$tmpd/parsed_trimmed.txt\"\n  awk '{\n    g=$0\n    sub(/^models\\//,\"\"  
g)\n    sub(/^groq[:\\/-]*/,\"\"  
g)\n    # keep only plausible model names (alnum and common separators)\n    if (g ~ /^[[:alnum:]._\\/:-]+$/) print g\n  }' \"$tmp_parsed\" | awk -v M=
```

**line_start**: 2813  

**body_full**:
```sh
# source: groqbash:2813\nrefresh_models_groq() {\n  # Fetch Groq models and write normalized model names to MODELS_FILE.\n  # Prefer .data[].name then .data[].id then top-level array .[].name/.id.\n  if [ -n \"${PROVIDER_API_ENV_groq:-}\" ] && [ -n \"${!PROVIDER_API_ENV_groq:-}\" ]; then\n    GROQ_API_KEY=\"${!PROVIDER_API_ENV_groq}\"\n  fi\n  if [ -z \"${GROQ_API_KEY:-}\" ]; then\n    log_error \"APIKEY\" \"GROQ_API_KEY is required to refresh models.\"\n    return \"$GROQBASHERRNOAPIKEY\"\n  fi\n\n  ensure_run_tmpdir || return \"$GROQBASHERRTMP\"\n  local workdir tmpd out errf api_url tmp_parsed tmp_trim tmpout rc\n  workdir=\"${RUN_TMPDIR:-}\"\n  [ -n \"$workdir\" ] || return \"$GROQBASHERRTMP\"\n  tmpd=\"$(mktemp -d -p \"$workdir\" groq-models.XXXX)\" || return \"$GROQBASHERRTMP\"\n  out=\"$tmpd/models.json\"\n  errf=\"$tmpd/curl.err\"\n  # Derive models API URL from the canonical provider URL (GROQBASH_PROVIDER_URL).\n  # Do not introduce new env var semantics; attempt to resolve provider URL if needed.\n  resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n  if [ -n \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n    # Extract origin (scheme + host[:port]) and append canonical models path.\n    origin=\"$(printf '%s' \"$GROQBASH_PROVIDER_URL\" | sed -E 's#(https?://[^/]+).*#\\1#')\"\n    api_url=\"${origin%/}/openai/v1/models\"\n  else\n    # Fallback to embedded groq models endpoint only if provider is groq (preserve prior behavior).\n    if [ \"${PROVIDER:-}\" = \"groq\" ]; then\n      # Do not introduce new env var semantics; attempt to resolve provider URL if needed.\n      resolve_provider_url \"${PROVIDER:-}\" >/dev/null 2>&1 || true\n      if [ -n \"${GROQBASH_PROVIDER_URL:-}\" ]; then\n        # Extract origin (scheme + host[:port]) and append canonical models path.\n        origin=\"$(printf '%s' \"$GROQBASH_PROVIDER_URL\" | sed -E 's#(https?://[^/]+).*#\\1#')\"\n        api_url=\"${origin%/}/openai/v1/models\"\n      else\n        # No canonical provider URL available: fail (do not use hardcoded endpoint).\n        log_error \"MODELREFRESH\" \"no provider URL available to refresh models\"\n        rm -rf \"$tmpd\"\n        return \"$GROQBASHERRAPI\"\n      fi\n    else\n      log_error \"MODELREFRESH\" \"no provider URL available to refresh models\"\n      rm -rf \"$tmpd\"\n      return \"$GROQBASHERRAPI\"\n    fi\n  fi\n\n  rm -f \"$out\" \"$errf\" 2>/dev/null || true\n  if ! curl \"${CURL_BASE_OPTS[@]}\" -H \"Authorization: Bearer ${GROQ_API_KEY}\" -H \"Content-Type: application/json\" \"${api_url}?limit=${MAX_MODELS}\" -o \"$out\" 2>\"$errf\"; then\n    log_error \"MODELREFRESH\" \"Failed to fetch models from $api_url\"\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      head -n 200 \"$errf\" >&2 || true\n    fi\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  if ! jq -e . \"$out\" >/dev/null 2>&1; then\n    log_error \"MODELREFRESH\" \"Invalid JSON received from $api_url\"\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      head -n 200 \"$errf\" >&2 || true\n    fi\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  tmp_parsed=\"$tmpd/parsed_models.txt\"\n  : > \"$tmp_parsed\"\n\n  # Extract candidate names: prefer .data[].name, then .data[].id, then top-level array .[].name/.id\n  jq -r '\n    if (has(\"data\") and (.data|type) == \"array\") then\n      .data[]? | (.name // .id // empty)\n    elif (type == \"array\") then\n      .[]? | (.name // .id // empty)\n    else\n      empty\n    end\n  ' \"$out\" | awk 'NF{print}' | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' | sort -u > \"$tmp_parsed\" 2>/dev/null || true\n\n  if [ ! -s \"$tmp_parsed\" ]; then\n    log_error \"MODELREFRESH\" \"models refresh: parsed list empty\"\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      head -n 200 \"$errf\" >&2 || true\n    fi\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  # Normalize entries: strip common prefixes like \"models/\" and \"groq:\"; validate allowed chars\n  tmp_trim=\"$tmpd/parsed_trimmed.txt\"\n  awk '{\n    g=$0\n    sub(/^models\\//,\"\"  
g)\n    sub(/^groq[:\\/-]*/,\"\"  
g)\n    # keep only plausible model names (alnum and common separators)\n    if (g ~ /^[[:alnum:]._\\/:-]+$/) print g\n  }' \"$tmp_parsed\" | awk -v M=\"$MAX_MODELS\" 'NR<=M{print}' > \"$tmp_trim\" || true\n\n  if [ ! -s \"$tmp_trim\" ]; then\n    log_error \"MODELREFRESH\" \"no valid model names after normalization\"\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRAPI\"\n  fi\n\n  # Ensure destination dir exists and write atomically via base64 staging\n  mkdir -p \"$(dirname \"$MODELS_FILE\")\" 2>/dev/null || true\n  tmpout=\"$(_mktemp_in_dir \"$(dirname \"$MODELS_FILE\")\" 2>/dev/null || true)\"\n  [ -n \"$tmpout\" ] || tmpout=\"$MODELS_FILE.tmp\"\n  cat \"$tmp_trim\" > \"$tmpout\"\n\n  if ! b64_atomic_write \"${MODELS_FILE}.b64\" 10 < \"$tmpout\"; then\n    log_error \"MODELREFRESH\" \"failed to stage models file\"\n    rm -f \"$tmpout\" 2>/dev/null || true\n    rm -rf \"$tmpd\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  lockfile=\"$MODELS_LOCK\"\n  lock_exec \"$lockfile\" 10 -- sh -c '\n    set -e\n    manifest_b64=\"$1\"\n    dest=\"$2\"\n    base64 ${B64_DECODE_OPT} < \"$manifest_b64\" > \"$dest\"\n    chmod 600 \"$dest\" 2>/dev/null || true\n  ' _ \"${MODELS_FILE}.b64\" \"$MODELS_FILE\" || { log_error \"MODELREFRESH\" \"failed to write models file under lock\"; rm -rf \"$tmpd\"; return \"$GROQBASHERRTMP\"; }\n\n  chmod 600 \"$MODELS_FILE\" 2>/dev/null || true\n\n  # Informational only when DEBUG=1\n  if [ \"${DEBUG:-0}\" -eq 1 ]; then\n    log_info \"MODELREFRESH\" \"Models refreshed and saved to: $MODELS_FILE (max ${MAX_MODELS})\"\n  fi\n\n  rm -rf \"$tmpd\"\n  return 0\n}"
```

---

**name**: "refreshmodelsgroq"  

**file**: "groqbash"  

**line_range**: "L2951"  

**body_snippet**: 
```sh
# source: groqbash:2951\nrefreshmodelsgroq() { refresh_models_groq \"$@\"; }
```

**line_start**: 2951  

**body_full**:
```sh
# source: groqbash:2951\nrefreshmodelsgroq() { refresh_models_groq \"$@\"; }"
```

---

**name**: "validate_model_groq"  

**file**: "groqbash"  

**line_range**: "L2958"  

**body_snippet**: 
```sh
# source: groqbash:2958\nvalidate_model_groq() {\n  # Provider-specific validation for Groq models.\n  # Accepts either exact matches as stored in MODELS_FILE or normalized names\n  # (stripping common prefixes like \"models/\" or \"groq:\"), and enforces textual support.\n  local model=\"$1\" norm_model file_match\n  [ -n \"$model\" ] || { printf 'groqbash: ERROR: validate_model_groq: model required\\n' >&2; return 1; }\n\n  # Normalize incoming model for comparison: strip leading \"models/\" and \"groq:\" and trim\n  norm_model=\"$(printf '%s' \"$model\" | sed -e 's#^models/##' -e 's#^groq[:/ -]*##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n\n  # If MODELS_FILE exists and non-empty, require presence (allow either raw or normalized forms)\n  if [ -f \"${MODELS_FILE:-}\" ] && [ -s \"${MODELS_FILE:-}\" ]; then\n    # Exact match first (file may contain provider-specific forms)\n    if grep -x -F -q \"$model\" \"$MODELS_FILE\" 2>/dev/null; then\n      file_match=1\n    else\n      # Compare against normalized entries (strip common prefixes in file)\n      if awk '{g=$0; sub(/^models\\//,\"\"  
g); sub(/^groq[:\\/ -]*/,\"\"  
g); print g}' \"$MODELS_FILE\" | grep -x -F -q \"$norm_model\" 2>/dev/null; then\n        file_match=1\n      else\n        file_match=0\n      fi\n    fi\n\n    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Ensure the (normalized) model is text-capable\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}
```

**line_start**: 2958  

**body_full**:
```sh
# source: groqbash:2958\nvalidate_model_groq() {\n  # Provider-specific validation for Groq models.\n  # Accepts either exact matches as stored in MODELS_FILE or normalized names\n  # (stripping common prefixes like \"models/\" or \"groq:\"), and enforces textual support.\n  local model=\"$1\" norm_model file_match\n  [ -n \"$model\" ] || { printf 'groqbash: ERROR: validate_model_groq: model required\\n' >&2; return 1; }\n\n  # Normalize incoming model for comparison: strip leading \"models/\" and \"groq:\" and trim\n  norm_model=\"$(printf '%s' \"$model\" | sed -e 's#^models/##' -e 's#^groq[:/ -]*##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n\n  # If MODELS_FILE exists and non-empty, require presence (allow either raw or normalized forms)\n  if [ -f \"${MODELS_FILE:-}\" ] && [ -s \"${MODELS_FILE:-}\" ]; then\n    # Exact match first (file may contain provider-specific forms)\n    if grep -x -F -q \"$model\" \"$MODELS_FILE\" 2>/dev/null; then\n      file_match=1\n    else\n      # Compare against normalized entries (strip common prefixes in file)\n      if awk '{g=$0; sub(/^models\\//,\"\"  
g); sub(/^groq[:\\/ -]*/,\"\"  
g); print g}' \"$MODELS_FILE\" | grep -x -F -q \"$norm_model\" 2>/dev/null; then\n        file_match=1\n      else\n        file_match=0\n      fi\n    fi\n\n    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Ensure the (normalized) model is text-capable\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}"
```

---

**name**: "validatemodelgroq"  

**file**: "groqbash"  

**line_range**: "L2997"  

**body_snippet**: 
```sh
# source: groqbash:2997\nvalidatemodelgroq() { validate_model_groq \"$@\"; }
```

**line_start**: 2997  

**body_full**:
```sh
# source: groqbash:2997\nvalidatemodelgroq() { validate_model_groq \"$@\"; }"
```

---

### SECTION: CORE_SETUP

---

**name**: "ARGS"  

**file**: "groqbash"  

**line_range**: "L3613"  

**body_snippet**: 
```sh
    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}\n\n#--4<---[ SECTION: CORE_SETUP_CLI_PARSE ]--->4--\n# CLI parsing (flags, normalization, immediate actions)\n# ---------------------------------------------------------------------------\nJSON_INPUT=\"${JSON_INPUT:-}\" TEMPLATE=\"${TEMPLATE:-}\" BATCH_FILE=\"${BATCH_FILE:-}\" CHAT_MODE=\"${CHAT_MODE:-0}\" SET_DEFAULT_MODEL=\"${SET_DEFAULT_MODEL:-}\"\nLIST_MODELS=\"${LIST_MODELS:-0}\" LIST_PROVIDERS=\"${LIST_PROVIDERS:-0}\" FORCE_SAVE_MODE=\"${FORCE_SAVE_MODE:-}\" OUT_PATH=\"${OUT_PATH:-}\"\nDRY_RUN=\"${DRY_RUN:-0}\" STREAM_MODE=\"${STREAM_MODE:-0}\" QUIET=\"${QUIET:-0}\" INSTALL_EXTRAS=\"${INSTALL_EXTRAS:-0}\" DEBUG=\"${DEBUG:-0}\"\nPROVIDER_CLI=\"${PROVIDER_CLI:-}\" PROVIDER_INTERACTIVE=\"${PROVIDER_INTERACTIVE:-0}\"\nSHOW_CONFIG=\"${SHOW_CONFIG:-0}\" DIAGNOSTICS=\"${DIAGNOSTICS:-0}\"\nFILE_INPUTS=() ARGS=() OUTPUT_MODE=\"${OUTPUT_MODE:-text}\"\nMODEL_CLI_SET=\"${MODEL_CLI_SET:-0}\"\nINSTALL_EXTRAS_SRC=\"\"\n\nwhile [ $# -gt 0 ]; do\n  case \"$1\" in\n    --refresh-models|--refresh-model) REFRESH_MODELS=1; shift ;;\n    --list-models) LIST_MODELS=1; shift ;;\n    --list-providers) LIST_PROVIDERS=1; shift ;;\n    --list-providers-raw) LIST_PROVIDERS_RAW=1; shift ;;\n    --list-models-raw) LIST_MODELS_RAW=1; shift ;;\n    --set-default) SET_DEFAULT_MODEL=\"${2:-}\"; shift 2 ;;\n    -m|--model) MODEL=\"${2:-}\"; MODEL_CLI_SET=1; shift 2 ;;\n    -f) FILE_INPUTS+=(\"${2:-}\"); shift 2 ;;\n    --json-input) JSON_INPUT=\"${2:-}\"; shift 2 ;;\n    --template) TEMPLATE=\"${2:-}\"; shift 2 ;;\n    --batch) BATCH_FILE=\"${2:-}\"; shift 2 ;;\n    --session)\n      # opt-in session id\n      SESSION_ID=\"${2:-}\"\n      if [ -n \"$SESSION_ID\" ] && [ \"${SESSION_ID:0:1}\" != \"-\" ]; then\n        shift 2\n      else\n\n# NOTE: ARGS is initialized as an array for CLI positional/flag arguments.\n
```

**line_start**: 3613  

**body_full**:
```sh
    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}\n\n#--4<---[ SECTION: CORE_SETUP_CLI_PARSE ]--->4--\n# CLI parsing (flags, normalization, immediate actions)\n# ---------------------------------------------------------------------------\nJSON_INPUT=\"${JSON_INPUT:-}\" TEMPLATE=\"${TEMPLATE:-}\" BATCH_FILE=\"${BATCH_FILE:-}\" CHAT_MODE=\"${CHAT_MODE:-0}\" SET_DEFAULT_MODEL=\"${SET_DEFAULT_MODEL:-}\"\nLIST_MODELS=\"${LIST_MODELS:-0}\" LIST_PROVIDERS=\"${LIST_PROVIDERS:-0}\" FORCE_SAVE_MODE=\"${FORCE_SAVE_MODE:-}\" OUT_PATH=\"${OUT_PATH:-}\"\nDRY_RUN=\"${DRY_RUN:-0}\" STREAM_MODE=\"${STREAM_MODE:-0}\" QUIET=\"${QUIET:-0}\" INSTALL_EXTRAS=\"${INSTALL_EXTRAS:-0}\" DEBUG=\"${DEBUG:-0}\"\nPROVIDER_CLI=\"${PROVIDER_CLI:-}\" PROVIDER_INTERACTIVE=\"${PROVIDER_INTERACTIVE:-0}\"\nSHOW_CONFIG=\"${SHOW_CONFIG:-0}\" DIAGNOSTICS=\"${DIAGNOSTICS:-0}\"\nFILE_INPUTS=() ARGS=() OUTPUT_MODE=\"${OUTPUT_MODE:-text}\"\nMODEL_CLI_SET=\"${MODEL_CLI_SET:-0}\"\nINSTALL_EXTRAS_SRC=\"\"\n\nwhile [ $# -gt 0 ]; do\n  case \"$1\" in\n    --refresh-models|--refresh-model) REFRESH_MODELS=1; shift ;;\n    --list-models) LIST_MODELS=1; shift ;;\n    --list-providers) LIST_PROVIDERS=1; shift ;;\n    --list-providers-raw) LIST_PROVIDERS_RAW=1; shift ;;\n    --list-models-raw) LIST_MODELS_RAW=1; shift ;;\n    --set-default) SET_DEFAULT_MODEL=\"${2:-}\"; shift 2 ;;\n    -m|--model) MODEL=\"${2:-}\"; MODEL_CLI_SET=1; shift 2 ;;\n    -f) FILE_INPUTS+=(\"${2:-}\"); shift 2 ;;\n    --json-input) JSON_INPUT=\"${2:-}\"; shift 2 ;;\n    --template) TEMPLATE=\"${2:-}\"; shift 2 ;;\n    --batch) BATCH_FILE=\"${2:-}\"; shift 2 ;;\n    --session)\n      # opt-in session id\n      SESSION_ID=\"${2:-}\"\n      if [ -n \"$SESSION_ID\" ] && [ \"${SESSION_ID:0:1}\" != \"-\" ]; then\n        shift 2\n      else\n\n# NOTE: ARGS is initialized as an array for CLI positional/flag arguments.\n"
```

---

**name**: "auto_select_model_dispatch"  

**file**: "groqbash"  

**line_range**: "L3086"  

**body_snippet**: 
```sh
# source: groqbash:3086\nauto_select_model_dispatch() {\n  local fn=\"auto_select_model_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  fi\n  return 1\n}
```

**line_start**: 3086  

**body_full**:
```sh
# source: groqbash:3086\nauto_select_model_dispatch() {\n  local fn=\"auto_select_model_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  fi\n  return 1\n}"
```

---

**name**: "build_payload_from_vars"  

**file**: "groqbash"  

**line_range**: "L3220"  

**body_snippet**: 
```sh
# source: groqbash:3220\nbuild_payload_from_vars() {\n  ensure_run_tmpdir\n  local fn=\"buildpayload_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  else\n    rc=$?\n    if [ \"$rc\" -eq 127 ]; then\n      log_error \"PROVIDER\" \"Provider '$PROVIDER' does not provide $fn().\"\n      exit \"$GROQBASHERRAPI\"\n    else\n      return \"$rc\"\n    fi\n  fi\n}
```

**line_start**: 3220  

**body_full**:
```sh
# source: groqbash:3220\nbuild_payload_from_vars() {\n  ensure_run_tmpdir\n  local fn=\"buildpayload_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  else\n    rc=$?\n    if [ \"$rc\" -eq 127 ]; then\n      log_error \"PROVIDER\" \"Provider '$PROVIDER' does not provide $fn().\"\n      exit \"$GROQBASHERRAPI\"\n    else\n      return \"$rc\"\n    fi\n  fi\n}"
```

---

**name**: "call_api_once"  

**file**: "groqbash"  

**line_range**: "L3238"  

**body_snippet**: 
```sh
# source: groqbash:3238\ncall_api_once() {\n  if [ \"${DRY_RUN:-0}\" -eq 1 ]; then\n    # show_payload_head is diagnostic; show only when DEBUG=1\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      show_payload_head \"$PAYLOAD\" 200 || true\n      log_info \"DRYRUN\" \"DRY-RUN: skipping provider HTTP call\"\n    fi\n    return 0\n  fi\n  local fn=\"call_api_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  else\n    rc=$?\n    if [ \"$rc\" -eq 127 ]; then\n      log_error \"PROVIDER\" \"Provider '$PROVIDER' does not provide $fn().\"\n      exit \"$GROQBASHERRAPI\"\n    else\n      return \"$rc\"\n    fi\n  fi\n}
```

**line_start**: 3238  

**body_full**:
```sh
# source: groqbash:3238\ncall_api_once() {\n  if [ \"${DRY_RUN:-0}\" -eq 1 ]; then\n    # show_payload_head is diagnostic; show only when DEBUG=1\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      show_payload_head \"$PAYLOAD\" 200 || true\n      log_info \"DRYRUN\" \"DRY-RUN: skipping provider HTTP call\"\n    fi\n    return 0\n  fi\n  local fn=\"call_api_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  else\n    rc=$?\n    if [ \"$rc\" -eq 127 ]; then\n      log_error \"PROVIDER\" \"Provider '$PROVIDER' does not provide $fn().\"\n      exit \"$GROQBASHERRAPI\"\n    else\n      return \"$rc\"\n    fi\n  fi\n}"
```

---

**name**: "call_api_streaming"  

**file**: "groqbash"  

**line_range**: "L3261"  

**body_snippet**: 
```sh
# source: groqbash:3261\ncall_api_streaming() {\n  if [ \"${DRY_RUN:-0}\" -eq 1 ]; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      show_payload_head \"$PAYLOAD\" 200 || true\n      log_info \"DRYRUN\" \"DRY-RUN: skipping provider streaming HTTP call\"\n    fi\n    return 0\n  fi\n  local fn=\"call_api_streaming_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  else\n    rc=$?\n    if [ \"$rc\" -eq 127 ]; then\n      log_error \"PROVIDER\" \"Provider '$PROVIDER' does not provide $fn().\"\n      exit \"$GROQBASHERRAPI\"\n    else\n      return \"$rc\"\n    fi\n  fi\n}
```

**line_start**: 3261  

**body_full**:
```sh
# source: groqbash:3261\ncall_api_streaming() {\n  if [ \"${DRY_RUN:-0}\" -eq 1 ]; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      show_payload_head \"$PAYLOAD\" 200 || true\n      log_info \"DRYRUN\" \"DRY-RUN: skipping provider streaming HTTP call\"\n    fi\n    return 0\n  fi\n  local fn=\"call_api_streaming_${PROVIDER}\"\n  if call_provider \"$fn\"; then\n    return 0\n  else\n    rc=$?\n    if [ \"$rc\" -eq 127 ]; then\n      log_error \"PROVIDER\" \"Provider '$PROVIDER' does not provide $fn().\"\n      exit \"$GROQBASHERRAPI\"\n    else\n      return \"$rc\"\n    fi\n  fi\n}"
```

---

**name**: "call_provider"  

**file**: "groqbash"  

**line_range**: "L3034"  

**body_snippet**: 
```sh
# source: groqbash:3034\ncall_provider() {\n  local fn=\"$1\" shift_args=(\"${@:2}\")\n  if type \"$fn\" >/dev/null 2>&1; then\n    \"$fn\" \"${shift_args[@]}\"\n    return $?\n  fi\n  return 127\n}
```

**line_start**: 3034  

**body_full**:
```sh
# source: groqbash:3034\ncall_provider() {\n  local fn=\"$1\" shift_args=(\"${@:2}\")\n  if type \"$fn\" >/dev/null 2>&1; then\n    \"$fn\" \"${shift_args[@]}\"\n    return $?\n  fi\n  return 127\n}"
```

---

**name**: "collect_input_from_files"  

**file**: "groqbash"  

**line_range**: "L3496"  

**body_snippet**: 
```sh
# source: groqbash:3496\ncollect_input_from_files() {\n  local out=\"\" first=1 f\n  for f in \"$@\"; do\n    if file_readable \"$f\"; then\n      [ \"$first\" -eq 0 ] && out=\"${out}\"$'\\n\\n'\"--- FILE: ${f} ---\"$'\\n\\n'\n      out=\"${out}$(cat \"$f\")\"; first=0\n    else log_error \"FILE\" \"file not readable: $f\"; exit \"$GROQBASHERRTMP\"; fi\n  done\n  printf '%s' \"$out\"\n}
```

**line_start**: 3496  

**body_full**:
```sh
# source: groqbash:3496\ncollect_input_from_files() {\n  local out=\"\" first=1 f\n  for f in \"$@\"; do\n    if file_readable \"$f\"; then\n      [ \"$first\" -eq 0 ] && out=\"${out}\"$'\\n\\n'\"--- FILE: ${f} ---\"$'\\n\\n'\n      out=\"${out}$(cat \"$f\")\"; first=0\n    else log_error \"FILE\" \"file not readable: $f\"; exit \"$GROQBASHERRTMP\"; fi\n  done\n  printf '%s' \"$out\"\n}"
```

---

**name**: "detect_empty_edge_case"  

**file**: "groqbash"  

**line_range**: "L3304"  

**body_snippet**: 
```sh
# source: groqbash:3304\ndetect_empty_edge_case() {\n  # Populate edge-case variables and set GROQBASH_EDGE_EMPTY=1 when response is an \"empty completion\" edge.\n  local resp=\"${RESP:-}\"\n  GROQBASH_EDGE_EMPTY=0\n  GROQBASH_EDGE_REQ_ID=\"\"\n  GROQBASH_EDGE_FINISH_REASON=\"\"\n  GROQBASH_EDGE_COMPLETION_TOKENS=0\n\n  if [ -z \"${resp:-}\" ] || [ ! -s \"$resp\" ]; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # If not valid JSON, consider it empty for edge detection\n  if ! is_valid_json_file \"$resp\"; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # If diagnostic JSON, mark as empty\n  if jq -e 'has(\"diagnostic\") and .diagnostic==true' \"$resp\" >/dev/null 2>&1; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # Extract fields safely\n  local content finish_reason completion_tokens req_id\n  content=\"$(jq -r '.choices[0]?.message?.content // .choices[0]?.delta?.content // \"\"' \"$resp\" 2>/dev/null || echo \"\")\"\n  finish_reason=\"$(jq -r '.choices[0]?.finish_reason // \"\"' \"$resp\" 2>/dev/null || echo \"\")\"\n  completion_tokens=\"$(jq -r '.usage?.completion_tokens // 0' \"$resp\" 2>/dev/null || echo 0)\"\n  req_id=\"$(jq -r '.x_groq?.id // .id // empty' \"$resp\" 2>/dev/null || echo \"\")\"\n\n  GROQBASH_EDGE_REQ_ID=\"${req_id:-}\"\n  GROQBASH_EDGE_FINISH_REASON=\"${finish_reason:-}\"\n  GROQBASH_EDGE_COMPLETION_TOKENS=\"${completion_tokens:-0}\"\n\n  # Heuristic: empty content with finish_reason \"stop\" and very small completion tokens (1) => edge empty\n  if [ -z \"$content\" ] && [ \"$finish_reason\" = \"stop\" ] && [ \"${completion_tokens:-0}\" -le 1 ]; then\n    GROQBASH_EDGE_EMPTY=1\n  else\n    GROQBASH_EDGE_EMPTY=0\n  fi\n\n  return 0\n}
```

**line_start**: 3304  

**body_full**:
```sh
# source: groqbash:3304\ndetect_empty_edge_case() {\n  # Populate edge-case variables and set GROQBASH_EDGE_EMPTY=1 when response is an \"empty completion\" edge.\n  local resp=\"${RESP:-}\"\n  GROQBASH_EDGE_EMPTY=0\n  GROQBASH_EDGE_REQ_ID=\"\"\n  GROQBASH_EDGE_FINISH_REASON=\"\"\n  GROQBASH_EDGE_COMPLETION_TOKENS=0\n\n  if [ -z \"${resp:-}\" ] || [ ! -s \"$resp\" ]; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # If not valid JSON, consider it empty for edge detection\n  if ! is_valid_json_file \"$resp\"; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # If diagnostic JSON, mark as empty\n  if jq -e 'has(\"diagnostic\") and .diagnostic==true' \"$resp\" >/dev/null 2>&1; then\n    GROQBASH_EDGE_EMPTY=1\n    return 0\n  fi\n\n  # Extract fields safely\n  local content finish_reason completion_tokens req_id\n  content=\"$(jq -r '.choices[0]?.message?.content // .choices[0]?.delta?.content // \"\"' \"$resp\" 2>/dev/null || echo \"\")\"\n  finish_reason=\"$(jq -r '.choices[0]?.finish_reason // \"\"' \"$resp\" 2>/dev/null || echo \"\")\"\n  completion_tokens=\"$(jq -r '.usage?.completion_tokens // 0' \"$resp\" 2>/dev/null || echo 0)\"\n  req_id=\"$(jq -r '.x_groq?.id // .id // empty' \"$resp\" 2>/dev/null || echo \"\")\"\n\n  GROQBASH_EDGE_REQ_ID=\"${req_id:-}\"\n  GROQBASH_EDGE_FINISH_REASON=\"${finish_reason:-}\"\n  GROQBASH_EDGE_COMPLETION_TOKENS=\"${completion_tokens:-0}\"\n\n  # Heuristic: empty content with finish_reason \"stop\" and very small completion tokens (1) => edge empty\n  if [ -z \"$content\" ] && [ \"$finish_reason\" = \"stop\" ] && [ \"${completion_tokens:-0}\" -le 1 ]; then\n    GROQBASH_EDGE_EMPTY=1\n  else\n    GROQBASH_EDGE_EMPTY=0\n  fi\n\n  return 0\n}"
```

---

**name**: "expand_args_to_content"  

**file**: "groqbash"  

**line_range**: "L3506"  

**body_snippet**: 
```sh
# source: groqbash:3506\nexpand_args_to_content() {\n  local out=\"\" first=1 a\n  for a in \"${ARGS[@]}\"; do\n    if file_readable \"$a\"; then\n      [ \"$first\" -eq 0 ] && out=\"${out}\"$'\\n\\n'\"--- FILE: ${a} ---\"$'\\n\\n'\n      out=\"${out}$(cat \"$a\")\"; first=0\n    else\n      [ \"$first\" -eq 0 ] && out=\"${out}\"$'\\n\\n'\n      out=\"${out}${a}\"; first=0\n    fi\n  done\n  printf '%s' \"$out\"\n}
```

**line_start**: 3506  

**body_full**:
```sh
# source: groqbash:3506\nexpand_args_to_content() {\n  local out=\"\" first=1 a\n  for a in \"${ARGS[@]}\"; do\n    if file_readable \"$a\"; then\n      [ \"$first\" -eq 0 ] && out=\"${out}\"$'\\n\\n'\"--- FILE: ${a} ---\"$'\\n\\n'\n      out=\"${out}$(cat \"$a\")\"; first=0\n    else\n      [ \"$first\" -eq 0 ] && out=\"${out}\"$'\\n\\n'\n      out=\"${out}${a}\"; first=0\n    fi\n  done\n  printf '%s' \"$out\"\n}"
```

---

**name**: "extract_api_error"  

**file**: "groqbash"  

**line_range**: "L3283"  

**body_snippet**: 
```sh
# source: groqbash:3283\nextract_api_error() {\n  [ ! -s \"${RESP:-}\" ] && return 0\n\n  if jq -e . \"$RESP\" >/dev/null 2>&1; then\n    # Prefer explicit error.message, then any non-empty choice content (first), else empty.\n    jq -r '\n      ( [ .error?.message // empty ] \n        + [ .choices[]? | (.message?.content // .delta?.content // empty) ] )\n      | map(select(length > 0))\n      | .[0] // empty\n    ' \"$RESP\" 2>/dev/null | head -n1 || true\n  else\n    awk 'NF{print; exit}' \"$RESP\" 2>/dev/null || true\n  fi\n}
```

**line_start**: 3283  

**body_full**:
```sh
# source: groqbash:3283\nextract_api_error() {\n  [ ! -s \"${RESP:-}\" ] && return 0\n\n  if jq -e . \"$RESP\" >/dev/null 2>&1; then\n    # Prefer explicit error.message, then any non-empty choice content (first), else empty.\n    jq -r '\n      ( [ .error?.message // empty ] \n        + [ .choices[]? | (.message?.content // .delta?.content // empty) ] )\n      | map(select(length > 0))\n      | .[0] // empty\n    ' \"$RESP\" 2>/dev/null | head -n1 || true\n  else\n    awk 'NF{print; exit}' \"$RESP\" 2>/dev/null || true\n  fi\n}"
```

---

**name**: "FILE_INPUTS"  

**file**: "groqbash"  

**line_range**: "L3613"  

**body_snippet**: 
```sh
# SOURCE: groqbash:3613\n# TYPE: variable (array)\n# USAGE: populated by CLI parsing; used to hold non-file arguments\n    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}\n\n#--4<---[ SECTION: CORE_SETUP_CLI_PARSE ]--->4--\n# CLI parsing (flags, normalization, immediate actions)\n# ---------------------------------------------------------------------------\nJSON_INPUT=\"${JSON_INPUT:-}\" TEMPLATE=\"${TEMPLATE:-}\" BATCH_FILE=\"${BATCH_FILE:-}\" CHAT_MODE=\"${CHAT_MODE:-0}\" SET_DEFAULT_MODEL=\"${SET_DEFAULT_MODEL:-}\"\nLIST_MODELS=\"${LIST_MODELS:-0}\" LIST_PROVIDERS=\"${LIST_PROVIDERS:-0}\" FORCE_SAVE_MODE=\"${FORCE_SAVE_MODE:-}\" OUT_PATH=\"${OUT_PATH:-}\"\nDRY_RUN=\"${DRY_RUN:-0}\" STREAM_MODE=\"${STREAM_MODE:-0}\" QUIET=\"${QUIET:-0}\" INSTALL_EXTRAS=\"${INSTALL_EXTRAS:-0}\" DEBUG=\"${DEBUG:-0}\"\nPROVIDER_CLI=\"${PROVIDER_CLI:-}\" PROVIDER_INTERACTIVE=\"${PROVIDER_INTERACTIVE:-0}\"\nSHOW_CONFIG=\"${SHOW_CONFIG:-0}\" DIAGNOSTICS=\"${DIAGNOSTICS:-0}\"\nFILE_INPUTS=() ARGS=() OUTPUT_MODE=\"${OUTPUT_MODE:-text}\"\nMODEL_CLI_SET=\"${MODEL_CLI_SET:-0}\"\nINSTALL_EXTRAS_SRC=\"\"\n\nwhile [ $# -gt 0 ]; do\n  case \"$1\" in\n    --refresh-models|--refresh-model) REFRESH_MODELS=1; shift ;;\n    --list-models) LIST_MODELS=1; shift ;;\n    --list-providers) LIST_PROVIDERS=1; shift ;;\n    --list-providers-raw) LIST_PROVIDERS_RAW=1; shift ;;\n    --list-models-raw) LIST_MODELS_RAW=1; shift ;;\n    --set-default) SET_DEFAULT_MODEL=\"${2:-}\"; shift 2 ;;\n    -m|--model) MODEL=\"${2:-}\"; MODEL_CLI_SET=1; shift 2 ;;\n    -f) FILE_INPUTS+=(\"${2:-}\"); shift 2 ;;\n    --json-input) JSON_INPUT=\"${2:-}\"; shift 2 ;;\n    --template) TEMPLATE=\"${2:-}\"; shift 2 ;;\n    --batch) BATCH_FILE=\"${2:-}\"; shift 2 ;;\n    --session)\n      # opt-in session id\n      SESSION_ID=\"${2:-}\"\n      if [ -n \"$SESSION_ID\" ] && [ \"${SESSION_ID:0:1}\" != \"-\" ]; then\n        shift 2\n      else\n\n# NOTE: FILE_INPUTS is initialized as an array for -f/--file flags.\n
```

**line_start**: 3613  

**body_full**:
```sh
# SOURCE: groqbash:3613\n# TYPE: variable (array)\n# USAGE: populated by CLI parsing; used to hold non-file arguments\n    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}\n\n#--4<---[ SECTION: CORE_SETUP_CLI_PARSE ]--->4--\n# CLI parsing (flags, normalization, immediate actions)\n# ---------------------------------------------------------------------------\nJSON_INPUT=\"${JSON_INPUT:-}\" TEMPLATE=\"${TEMPLATE:-}\" BATCH_FILE=\"${BATCH_FILE:-}\" CHAT_MODE=\"${CHAT_MODE:-0}\" SET_DEFAULT_MODEL=\"${SET_DEFAULT_MODEL:-}\"\nLIST_MODELS=\"${LIST_MODELS:-0}\" LIST_PROVIDERS=\"${LIST_PROVIDERS:-0}\" FORCE_SAVE_MODE=\"${FORCE_SAVE_MODE:-}\" OUT_PATH=\"${OUT_PATH:-}\"\nDRY_RUN=\"${DRY_RUN:-0}\" STREAM_MODE=\"${STREAM_MODE:-0}\" QUIET=\"${QUIET:-0}\" INSTALL_EXTRAS=\"${INSTALL_EXTRAS:-0}\" DEBUG=\"${DEBUG:-0}\"\nPROVIDER_CLI=\"${PROVIDER_CLI:-}\" PROVIDER_INTERACTIVE=\"${PROVIDER_INTERACTIVE:-0}\"\nSHOW_CONFIG=\"${SHOW_CONFIG:-0}\" DIAGNOSTICS=\"${DIAGNOSTICS:-0}\"\nFILE_INPUTS=() ARGS=() OUTPUT_MODE=\"${OUTPUT_MODE:-text}\"\nMODEL_CLI_SET=\"${MODEL_CLI_SET:-0}\"\nINSTALL_EXTRAS_SRC=\"\"\n\nwhile [ $# -gt 0 ]; do\n  case \"$1\" in\n    --refresh-models|--refresh-model) REFRESH_MODELS=1; shift ;;\n    --list-models) LIST_MODELS=1; shift ;;\n    --list-providers) LIST_PROVIDERS=1; shift ;;\n    --list-providers-raw) LIST_PROVIDERS_RAW=1; shift ;;\n    --list-models-raw) LIST_MODELS_RAW=1; shift ;;\n    --set-default) SET_DEFAULT_MODEL=\"${2:-}\"; shift 2 ;;\n    -m|--model) MODEL=\"${2:-}\"; MODEL_CLI_SET=1; shift 2 ;;\n    -f) FILE_INPUTS+=(\"${2:-}\"); shift 2 ;;\n    --json-input) JSON_INPUT=\"${2:-}\"; shift 2 ;;\n    --template) TEMPLATE=\"${2:-}\"; shift 2 ;;\n    --batch) BATCH_FILE=\"${2:-}\"; shift 2 ;;\n    --session)\n      # opt-in session id\n      SESSION_ID=\"${2:-}\"\n      if [ -n \"$SESSION_ID\" ] && [ \"${SESSION_ID:0:1}\" != \"-\" ]; then\n        shift 2\n      else\n\n# NOTE: FILE_INPUTS is initialized as an array for -f/--file flags.\n"
```

---

**name**: "file_readable"  

**file**: "groqbash"  

**line_range**: "L3520"  

**body_snippet**: 
```sh
# source: groqbash:3520\nfile_readable() { [ -r \"$1\" ] && [ -f \"$1\" ]; }
```

**line_start**: 3520  

**body_full**:
```sh
# source: groqbash:3520\nfile_readable() { [ -r \"$1\" ] && [ -f \"$1\" ]; }"
```

---

**name**: "finalize_and_output"  

**file**: "groqbash"  

**line_range**: "L3354"  

**body_snippet**: 
```sh
# source: groqbash:3354\nfinalize_and_output() {\n  local mode=\"$1\" text=\"$2\"\n  if { [ \"$mode\" = \"json\" ] || [ \"$mode\" = \"pretty\" ]; } && [ ! -s \"${RESP:-}\" ]; then\n    log_error \"RESP\" \"response file missing or empty: ${RESP:-<unset>}\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  case \"$mode\" in\n    json) cat \"$RESP\" ;;\n    pretty) if jq -e . \"$RESP\" >/dev/null 2>&1; then jq . \"$RESP\"; else cat \"$RESP\"; fi ;;\n    raw) printf '%s' \"$text\" ;;\n    text) printf '%s\\n' \"$text\" ;;\n    *) printf '%s\\n' \"$text\" ;;\n  esac\n\n  if [ \"$mode\" = \"text\" ] || [ \"$mode\" = \"raw\" ]; then\n    [ \"${FORCE_SAVE_MODE:-}\" = \"nosave\" ] && return 0\n    local len do_save=0 dest_dir dest_path\n    len=\"$(printf '%s' \"$text\" | wc -c | tr -d ' ')\"\n    if [ \"${FORCE_SAVE_MODE:-}\" = \"save\" ]; then\n      do_save=1\n    else\n      if [ \"$len\" -gt \"$THRESHOLD\" ]; then\n        do_save=1\n      fi\n    fi\n    if [ \"$do_save\" -eq 1 ]; then\n      if [ -n \"$OUT_PATH\" ]; then\n        if [ -d \"$OUT_PATH\" ]; then dest_dir=\"$OUT_PATH\"; dest_path=\"$dest_dir/$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt\"; else dest_path=\"$OUT_PATH\"; dest_dir=\"$(dirname \"$dest_path\")\"; fi\n      else dest_dir=\"$GROQBASH_HISTORY_DIR\"; dest_path=\"$dest_dir/$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt\"; fi\n      mkdir -p \"$dest_dir\" 2>/dev/null || true\n\n      if [ -z \"${RUN_TMPDIR:-}\" ] || [ ! -d \"$RUN_TMPDIR\" ]; then\n        log_error \"TMPFAIL\" \"RUN_TMPDIR not available for saving output.\"\n        return \"$GROQBASHERRTMP\"\n      fi\n\n      # Save via save_to_history which handles atomic tmp creation and rotation\n      save_to_history \"$text\" || log_warn \"HISTORY\" \"Failed to save output to history.\"\n    fi\n  fi\n}
```

**line_start**: 3354  

**body_full**:
```sh
# source: groqbash:3354\nfinalize_and_output() {\n  local mode=\"$1\" text=\"$2\"\n  if { [ \"$mode\" = \"json\" ] || [ \"$mode\" = \"pretty\" ]; } && [ ! -s \"${RESP:-}\" ]; then\n    log_error \"RESP\" \"response file missing or empty: ${RESP:-<unset>}\"\n    return \"$GROQBASHERRTMP\"\n  fi\n\n  case \"$mode\" in\n    json) cat \"$RESP\" ;;\n    pretty) if jq -e . \"$RESP\" >/dev/null 2>&1; then jq . \"$RESP\"; else cat \"$RESP\"; fi ;;\n    raw) printf '%s' \"$text\" ;;\n    text) printf '%s\\n' \"$text\" ;;\n    *) printf '%s\\n' \"$text\" ;;\n  esac\n\n  if [ \"$mode\" = \"text\" ] || [ \"$mode\" = \"raw\" ]; then\n    [ \"${FORCE_SAVE_MODE:-}\" = \"nosave\" ] && return 0\n    local len do_save=0 dest_dir dest_path\n    len=\"$(printf '%s' \"$text\" | wc -c | tr -d ' ')\"\n    if [ \"${FORCE_SAVE_MODE:-}\" = \"save\" ]; then\n      do_save=1\n    else\n      if [ \"$len\" -gt \"$THRESHOLD\" ]; then\n        do_save=1\n      fi\n    fi\n    if [ \"$do_save\" -eq 1 ]; then\n      if [ -n \"$OUT_PATH\" ]; then\n        if [ -d \"$OUT_PATH\" ]; then dest_dir=\"$OUT_PATH\"; dest_path=\"$dest_dir/$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt\"; else dest_path=\"$OUT_PATH\"; dest_dir=\"$(dirname \"$dest_path\")\"; fi\n      else dest_dir=\"$GROQBASH_HISTORY_DIR\"; dest_path=\"$dest_dir/$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt\"; fi\n      mkdir -p \"$dest_dir\" 2>/dev/null || true\n\n      if [ -z \"${RUN_TMPDIR:-}\" ] || [ ! -d \"$RUN_TMPDIR\" ]; then\n        log_error \"TMPFAIL\" \"RUN_TMPDIR not available for saving output.\"\n        return \"$GROQBASHERRTMP\"\n      fi\n\n      # Save via save_to_history which handles atomic tmp creation and rotation\n      save_to_history \"$text\" || log_warn \"HISTORY\" \"Failed to save output to history.\"\n    fi\n  fi\n}"
```

---

**name**: "is_number"  

**file**: "groqbash"  

**line_range**: "L3524"  

**body_snippet**: 
```sh
# source: groqbash:3524\nis_number() { printf '%s\\n' \"$1\" | awk 'BEGIN{exit 0} {exit !( $0+0 == $0+0 )}'; }
```

**line_start**: 3524  

**body_full**:
```sh
# source: groqbash:3524\nis_number() { printf '%s\\n' \"$1\" | awk 'BEGIN{exit 0} {exit !( $0+0 == $0+0 )}'; }"
```

---

**name**: "is_supported_model"  

**file**: "groqbash"  

**line_range**: "L3527"  

**body_snippet**: 
```sh
# source: groqbash:3527\nis_supported_model() {\n  # Return 0 if model name appears to support text-only usage.\n  # Reject models that clearly indicate image/audio/embedding/multimodal capabilities.\n  local m=\"${1:-}\" l\n  [ -n \"$m\" ] || return 1\n  l=\"$(printf '%s' \"$m\" | tr '[:upper:]' '[:lower:]')\"\n\n  # Patterns that indicate non-text capabilities\n  case \"$l\" in\n    *image*|*imagen*|*img*|*vision*|*vqa*|*vit*|*clip*|*render*|*generate-image*|*generate_image* ) return 1 ;;\n    *audio*|*speech*|*tts*|*wav2vec*|*whisper*|*native-audio* ) return 1 ;;\n    *embed*|*embedding*|*vector* ) return 1 ;;\n    *multimodal*|*vision_audio*|*vision-audio* ) return 1 ;;\n    *) return 0 ;;\n  esac\n}
```

**line_start**: 3527  

**body_full**:
```sh
# source: groqbash:3527\nis_supported_model() {\n  # Return 0 if model name appears to support text-only usage.\n  # Reject models that clearly indicate image/audio/embedding/multimodal capabilities.\n  local m=\"${1:-}\" l\n  [ -n \"$m\" ] || return 1\n  l=\"$(printf '%s' \"$m\" | tr '[:upper:]' '[:lower:]')\"\n\n  # Patterns that indicate non-text capabilities\n  case \"$l\" in\n    *image*|*imagen*|*img*|*vision*|*vqa*|*vit*|*clip*|*render*|*generate-image*|*generate_image* ) return 1 ;;\n    *audio*|*speech*|*tts*|*wav2vec*|*whisper*|*native-audio* ) return 1 ;;\n    *embed*|*embedding*|*vector* ) return 1 ;;\n    *multimodal*|*vision_audio*|*vision-audio* ) return 1 ;;\n    *) return 0 ;;\n  esac\n}"
```

---

**name**: "is_tty_out"  

**file**: "groqbash"  

**line_range**: "L4081"  

**body_snippet**: 
```sh
# source: groqbash:4081\nis_tty_out() {\n  # Return success if stdout is a TTY\n  [ -t 1 ]\n}
```

**line_start**: 4081  

**body_full**:
```sh
# source: groqbash:4081\nis_tty_out() {\n  # Return success if stdout is a TTY\n  [ -t 1 ]\n}"
```

---

**name**: "list_models_cli"  

**file**: "groqbash"  

**line_range**: "L3544"  

**body_snippet**: 
```sh
# source: groqbash:3544\nlist_models_cli() {\n  # Print MODELS_FILE entries in a provider-agnostic way.\n  # Normalize entries (strip leading \"models/\") and mark non-text models.\n  if [ ! -s \"${MODELS_FILE:-}\" ]; then\n    printf 'No models available locally. Consider --refresh-models.\\n' >&2\n    return 1\n  fi\n\n  local count=0 model norm\n  while IFS= read -r model || [ -n \"$model\" ]; do\n    [ -z \"$model\" ] && continue\n    count=$((count+1))\n    norm=\"$(printf '%s' \"$model\" | sed -e 's/^models\\///' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n    if is_supported_model \"$norm\"; then\n      printf '%s\\n' \"$norm\"\n    else\n      printf '%s\\t[NOT SUPPORTED: Requires non-text input]\\n' \"$norm\"\n    fi\n    if [ \"$count\" -ge \"$MAX_MODELS\" ]; then break; fi\n  done < \"$MODELS_FILE\"\n  return 0\n}
```

**line_start**: 3544  

**body_full**:
```sh
# source: groqbash:3544\nlist_models_cli() {\n  # Print MODELS_FILE entries in a provider-agnostic way.\n  # Normalize entries (strip leading \"models/\") and mark non-text models.\n  if [ ! -s \"${MODELS_FILE:-}\" ]; then\n    printf 'No models available locally. Consider --refresh-models.\\n' >&2\n    return 1\n  fi\n\n  local count=0 model norm\n  while IFS= read -r model || [ -n \"$model\" ]; do\n    [ -z \"$model\" ] && continue\n    count=$((count+1))\n    norm=\"$(printf '%s' \"$model\" | sed -e 's/^models\\///' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n    if is_supported_model \"$norm\"; then\n      printf '%s\\n' \"$norm\"\n    else\n      printf '%s\\t[NOT SUPPORTED: Requires non-text input]\\n' \"$norm\"\n    fi\n    if [ \"$count\" -ge \"$MAX_MODELS\" ]; then break; fi\n  done < \"$MODELS_FILE\"\n  return 0\n}"
```

---

**name**: "load_local_config"  

**file**: "groqbash"  

**line_range**: "L4049"  

**body_snippet**: 
```sh
# source: groqbash:4049\nload_local_config() {\n  local cfg=\"${GROQBASH_CONFIG_DIR%/}/config\" key val\n  [ -f \"$cfg\" ] || return 0\n  while IFS= read -r line || [ -n \"$line\" ]; do\n    case \"$line\" in ''|\\#*) continue ;; esac\n    key=\"${line%%=*}\"\n    val=\"${line#*=}\"\n    case \"$key\" in\n      MODEL) [ -n \"$val\" ] && MODEL=\"$val\" ;;\n      TEMPERATURE|TURE) [ -n \"$val\" ] && TURE=\"$val\" ;;\n      MAX_TOKENS) [ -n \"$val\" ] && MAX_TOKENS=\"$val\" ;;\n      FORMAT) [ -n \"$val\" ] && OUTPUT_MODE=\"$val\" ;;\n      THRESHOLD) [ -n \"$val\" ] && THRESHOLD=\"$val\" ;;\n    esac\n  done < \"$cfg\"\n}
```

**line_start**: 4049  

**body_full**:
```sh
# source: groqbash:4049\nload_local_config() {\n  local cfg=\"${GROQBASH_CONFIG_DIR%/}/config\" key val\n  [ -f \"$cfg\" ] || return 0\n  while IFS= read -r line || [ -n \"$line\" ]; do\n    case \"$line\" in ''|\\#*) continue ;; esac\n    key=\"${line%%=*}\"\n    val=\"${line#*=}\"\n    case \"$key\" in\n      MODEL) [ -n \"$val\" ] && MODEL=\"$val\" ;;\n      TEMPERATURE|TURE) [ -n \"$val\" ] && TURE=\"$val\" ;;\n      MAX_TOKENS) [ -n \"$val\" ] && MAX_TOKENS=\"$val\" ;;\n      FORMAT) [ -n \"$val\" ] && OUTPUT_MODE=\"$val\" ;;\n      THRESHOLD) [ -n \"$val\" ] && THRESHOLD=\"$val\" ;;\n    esac\n  done < \"$cfg\"\n}"
```

---

**name**: "load_whitelist"  

**file**: "groqbash"  

**line_range**: "L4066"  

**body_snippet**: 
```sh
# source: groqbash:4066\nload_whitelist() {\n  ALLOWED_MODELS=\"${ALLOWED_MODELS:-}\"\n  if [ -f \"$MODELS_FILE\" ] && [ -s \"$MODELS_FILE\" ]; then\n    # Normalize entries: strip leading \"models/\" and trim whitespace\n    # Keep one model per line in ALLOWED_MODELS\n    ALLOWED_MODELS=\"$(awk '{ gsub(/^models\\//,\"\"); sub(/^[[:space:]]+/,\"\"); sub(/[[:space:]]+$/,\"\"); if (NF) print }' \"$MODELS_FILE\" 2>/dev/null || true)\"\n  fi\n}
```

**line_start**: 4066  

**body_full**:
```sh
# source: groqbash:4066\nload_whitelist() {\n  ALLOWED_MODELS=\"${ALLOWED_MODELS:-}\"\n  if [ -f \"$MODELS_FILE\" ] && [ -s \"$MODELS_FILE\" ]; then\n    # Normalize entries: strip leading \"models/\" and trim whitespace\n    # Keep one model per line in ALLOWED_MODELS\n    ALLOWED_MODELS=\"$(awk '{ gsub(/^models\\//,\"\"); sub(/^[[:space:]]+/,\"\"); sub(/[[:space:]]+$/,\"\"); if (NF) print }' \"$MODELS_FILE\" 2>/dev/null || true)\"\n  fi\n}"
```

---

**name**: "perform_request_once"  

**file**: "groqbash"  

**line_range**: "L3400"  

**body_snippet**: 
```sh
# source: groqbash:3400\nperform_request_once() {\n  local attempt=1 rc\n  while [ \"$attempt\" -le \"$MAX_RETRIES\" ]; do\n    if call_api_once; then\n      if [ \"${DRY_RUN:-0}\" -eq 1 ]; then\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"DRYRUN\" \"DRY-RUN: request simulated successfully. Payload: $PAYLOAD\"\n        fi\n        return 0\n      fi\n\n      # reset diagnostica all'inizio della gestione della risposta\n      GROQBASH_EDGE_EMPTY=0\n      GROQBASH_EDGE_REQ_ID=\"\"\n      GROQBASH_EDGE_FINISH_REASON=\"\"\n      GROQBASH_EDGE_COMPLETION_TOKENS=0\n\n      local text api_err\n      text=\"$(extract_text_from_resp || true)\"\n\n      # Esegui il rilevamento dell'edge case qui, sempre, subito dopo l'estrazione\n      detect_empty_edge_case || true\n\n      # Ensure last_api.json exists (fallback if provider didn't write it)\n      ui_last=\"${GROQBASH_CONFIG_DIR%/}/ui_state/last_api.json\"\n      if [ ! -f \"$ui_last\" ] || [ \"$ui_last\" -ot \"${RESP:-/dev/null}\" ]; then\n        # Build fallback api_json from available globals\n        finish_reason=\"$(jq -r '.choices[0]?.finish_reason // empty' \"$RESP\" 2>/dev/null || echo \"\")\"\n        req_id=\"$(jq -r '.x_groq?.id // .id // empty' \"$RESP\" 2>/dev/null || echo \"\")\"\n        edgecase=0\n        if [ \"${GROQBASH_EDGE_EMPTY:-0}\" -eq 1 ]; then edgecase=1; fi\n        now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n        http_code_fallback=0\n        # try to infer http code from RESP presence\n        if [ -s \"$RESP\" ]; then http_code_fallback=200; fi\n        api_json=\"$(jq -c -n --argjson http \"$http_code_fallback\" --arg fr \"${finish_reason:-}\" --argjson edge \"$edgecase\" --arg id \"${req_id:-}\" --arg ts \"$now_ts\" '{last_http_status:$http, last_finish_reason:$fr, last_edgecase_detected:$edge, last_req_id:$id, last_time_utc:$ts}')\"\n        ui_state_write \"last_api.json\" \"$api_json\" || { if [ \"${DEBUG:-0}\" -eq 1 ]; then log_warn \"UI_STATE\" \"failed to write fallback last_api.json\"; fi; }\n      fi\n\n      if [ -z \"$text\" ] && [ \"$OUTPUT_MODE\" != \"json\" ] && [ \"$OUTPUT_MODE\" != \"pretty\" ]; then\n        api_err=\"$(extract_api_error || true)\"\n        if [ -n \"$api_err\" ]; then\n          log_error \"API\" \"API error: $api_err\"\n          return \"$GROQBASHERRAPI\"\n        else\n          # Se l'edge case \u00e8 stato rilevato, emetti il log strutturato una sola volta\n          if [ \"${GROQBASH_EDGE_EMPTY:-0}\" -eq 1 ]; then\n            printf '%s\\n' \\\n              \"API edge case detected: empty completion\" \\\n              \"  req_id: ${GROQBASH_EDGE_REQ_ID:-<none>}\" \\\n              \"  finish_reason: ${GROQBASH_EDGE_FINISH_REASON:-<none>}\" \\\n              \"  completion_tokens: ${GROQBASH_EDGE_COMPLETION_TOKENS:-0}\" >&2\n\n            log_error \"API\" \"empty completion returned by provider (see previous diagnostic lines).\"\n            return \"$GROQBASHERRAPI\"\n          fi\n\n          # fallback generico: nessun testo e nessun errore esplicito\n          log_error \"API\" \"no textual content extracted from response.\"\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            head -n 50 \"${RESP:-/dev/null}\" >&2 || true\n          fi\n          return \"$GROQBASHERRAPI\"\n        fi\n      fi\n      # Ensure separation between JSON and assistant text\n      if [ \"$OUTPUT_MODE\" = \"text\" ] || [ \"$OUTPUT_MODE\" = \"raw\" ]; then\n        printf '\\n'  # <-- newline separator\n      fi\n\n      finalize_and_output \"$OUTPUT_MODE\" \"$text\"\n      return 0\n    else\n      rc=$?\n      if [ \"$rc\" -eq \"$GROQBASHERRCURL_FAILED\" ]; then\n        printf 'groqbash: WARN: Network error (curl). Retrying...\\n' >&2\n      elif [ \"$rc\" -eq \"$GROQBASHERRAPI\" ]; then\n        printf 'groqbash: ERROR: HTTP/API error. Not retrying.\\n' >&2\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          head -n 50 \"${RESP:-/dev/null}\" >&2 || true\n        fi\n        return \"$GROQBASHERRAPI\"\n      else\n        printf 'groqbash: WARN: Unknown error (code %s). Retrying...\\n' \"$rc\" >&2\n      fi\n    fi\n\n    attempt=$((attempt + 1)); sleep $((attempt * 1))\n  done\n\n  log_error \"REQUEST\" \"request failed after $MAX_RETR
```

**line_start**: 3400  

**body_full**:
```sh
# source: groqbash:3400\nperform_request_once() {\n  local attempt=1 rc\n  while [ \"$attempt\" -le \"$MAX_RETRIES\" ]; do\n    if call_api_once; then\n      if [ \"${DRY_RUN:-0}\" -eq 1 ]; then\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          log_info \"DRYRUN\" \"DRY-RUN: request simulated successfully. Payload: $PAYLOAD\"\n        fi\n        return 0\n      fi\n\n      # reset diagnostica all'inizio della gestione della risposta\n      GROQBASH_EDGE_EMPTY=0\n      GROQBASH_EDGE_REQ_ID=\"\"\n      GROQBASH_EDGE_FINISH_REASON=\"\"\n      GROQBASH_EDGE_COMPLETION_TOKENS=0\n\n      local text api_err\n      text=\"$(extract_text_from_resp || true)\"\n\n      # Esegui il rilevamento dell'edge case qui, sempre, subito dopo l'estrazione\n      detect_empty_edge_case || true\n\n      # Ensure last_api.json exists (fallback if provider didn't write it)\n      ui_last=\"${GROQBASH_CONFIG_DIR%/}/ui_state/last_api.json\"\n      if [ ! -f \"$ui_last\" ] || [ \"$ui_last\" -ot \"${RESP:-/dev/null}\" ]; then\n        # Build fallback api_json from available globals\n        finish_reason=\"$(jq -r '.choices[0]?.finish_reason // empty' \"$RESP\" 2>/dev/null || echo \"\")\"\n        req_id=\"$(jq -r '.x_groq?.id // .id // empty' \"$RESP\" 2>/dev/null || echo \"\")\"\n        edgecase=0\n        if [ \"${GROQBASH_EDGE_EMPTY:-0}\" -eq 1 ]; then edgecase=1; fi\n        now_ts=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n        http_code_fallback=0\n        # try to infer http code from RESP presence\n        if [ -s \"$RESP\" ]; then http_code_fallback=200; fi\n        api_json=\"$(jq -c -n --argjson http \"$http_code_fallback\" --arg fr \"${finish_reason:-}\" --argjson edge \"$edgecase\" --arg id \"${req_id:-}\" --arg ts \"$now_ts\" '{last_http_status:$http, last_finish_reason:$fr, last_edgecase_detected:$edge, last_req_id:$id, last_time_utc:$ts}')\"\n        ui_state_write \"last_api.json\" \"$api_json\" || { if [ \"${DEBUG:-0}\" -eq 1 ]; then log_warn \"UI_STATE\" \"failed to write fallback last_api.json\"; fi; }\n      fi\n\n      if [ -z \"$text\" ] && [ \"$OUTPUT_MODE\" != \"json\" ] && [ \"$OUTPUT_MODE\" != \"pretty\" ]; then\n        api_err=\"$(extract_api_error || true)\"\n        if [ -n \"$api_err\" ]; then\n          log_error \"API\" \"API error: $api_err\"\n          return \"$GROQBASHERRAPI\"\n        else\n          # Se l'edge case \u00e8 stato rilevato, emetti il log strutturato una sola volta\n          if [ \"${GROQBASH_EDGE_EMPTY:-0}\" -eq 1 ]; then\n            printf '%s\\n' \\\n              \"API edge case detected: empty completion\" \\\n              \"  req_id: ${GROQBASH_EDGE_REQ_ID:-<none>}\" \\\n              \"  finish_reason: ${GROQBASH_EDGE_FINISH_REASON:-<none>}\" \\\n              \"  completion_tokens: ${GROQBASH_EDGE_COMPLETION_TOKENS:-0}\" >&2\n\n            log_error \"API\" \"empty completion returned by provider (see previous diagnostic lines).\"\n            return \"$GROQBASHERRAPI\"\n          fi\n\n          # fallback generico: nessun testo e nessun errore esplicito\n          log_error \"API\" \"no textual content extracted from response.\"\n          if [ \"${DEBUG:-0}\" -eq 1 ]; then\n            head -n 50 \"${RESP:-/dev/null}\" >&2 || true\n          fi\n          return \"$GROQBASHERRAPI\"\n        fi\n      fi\n      # Ensure separation between JSON and assistant text\n      if [ \"$OUTPUT_MODE\" = \"text\" ] || [ \"$OUTPUT_MODE\" = \"raw\" ]; then\n        printf '\\n'  # <-- newline separator\n      fi\n\n      finalize_and_output \"$OUTPUT_MODE\" \"$text\"\n      return 0\n    else\n      rc=$?\n      if [ \"$rc\" -eq \"$GROQBASHERRCURL_FAILED\" ]; then\n        printf 'groqbash: WARN: Network error (curl). Retrying...\\n' >&2\n      elif [ \"$rc\" -eq \"$GROQBASHERRAPI\" ]; then\n        printf 'groqbash: ERROR: HTTP/API error. Not retrying.\\n' >&2\n        if [ \"${DEBUG:-0}\" -eq 1 ]; then\n          head -n 50 \"${RESP:-/dev/null}\" >&2 || true\n        fi\n        return \"$GROQBASHERRAPI\"\n      else\n        printf 'groqbash: WARN: Unknown error (code %s). Retrying...\\n' \"$rc\" >&2\n      fi\n    fi\n\n    attempt=$((attempt + 1)); sleep $((attempt * 1))\n  done\n\n  log_error \"REQUEST\" \"request failed after $MAX_RETRIES attempts.\"\n  return \"$GROQBASHERRAPI\"\n}"
```

---

**name**: "refresh_models_dispatch"  

**file**: "groqbash"  

**line_range**: "L3044"  

**body_snippet**: 
```sh
# source: groqbash:3044\nrefresh_models_dispatch() {\n  local destfile=\"${1:-${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}}\"\n  local fn=\"refresh_models_${PROVIDER}\"\n  local rc=0\n\n  if ! type \"$fn\" >/dev/null 2>&1; then\n    log_error \"MODELREFRESH\" \"Provider '$PROVIDER' does not implement $fn().\"\n    return 127\n  fi\n\n  # Try provider-specific refresh; prefer passing destfile but tolerate providers that ignore args\n  if \"$fn\" \"$destfile\" 2>/dev/null; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"MODELREFRESH\" \"Models refreshed for provider $PROVIDER -> $destfile\"\n    fi\n    return 0\n  fi\n\n  rc=$?\n  if \"$fn\" 2>/dev/null; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"MODELREFRESH\" \"Models refreshed for provider $PROVIDER (no explicit dest)\"\n    fi\n    return 0\n  fi\n\n  rc=$?\n  log_error \"MODELREFRESH\" \"refresh_models for provider $PROVIDER failed (rc $rc).\"\n  return \"$rc\"\n}
```

**line_start**: 3044  

**body_full**:
```sh
# source: groqbash:3044\nrefresh_models_dispatch() {\n  local destfile=\"${1:-${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}}\"\n  local fn=\"refresh_models_${PROVIDER}\"\n  local rc=0\n\n  if ! type \"$fn\" >/dev/null 2>&1; then\n    log_error \"MODELREFRESH\" \"Provider '$PROVIDER' does not implement $fn().\"\n    return 127\n  fi\n\n  # Try provider-specific refresh; prefer passing destfile but tolerate providers that ignore args\n  if \"$fn\" \"$destfile\" 2>/dev/null; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"MODELREFRESH\" \"Models refreshed for provider $PROVIDER -> $destfile\"\n    fi\n    return 0\n  fi\n\n  rc=$?\n  if \"$fn\" 2>/dev/null; then\n    if [ \"${DEBUG:-0}\" -eq 1 ]; then\n      log_info \"MODELREFRESH\" \"Models refreshed for provider $PROVIDER (no explicit dest)\"\n    fi\n    return 0\n  fi\n\n  rc=$?\n  log_error \"MODELREFRESH\" \"refresh_models for provider $PROVIDER failed (rc $rc).\"\n  return \"$rc\"\n}"
```

---

**name**: "resolve_model"  

**file**: "groqbash"  

**line_range**: "L3097"  

**body_snippet**: 
```sh
# source: groqbash:3097\nresolve_model() {\n  # Guard: warn if MODEL is present in environment but not provided via -m/--set-default.\n  # This helps CI/users who export MODEL expecting it to behave like -m.\n  if [ -n \"${MODEL:-}\" ] && [ \"${MODEL_CLI_SET:-0}\" -ne 1 ]; then\n    # Only warn when no provider-specific persisted default exists (avoid noisy logs).\n    model_cfg=\"$(canonical_model_file \"${PROVIDER:-groq}\")\"\n    if [ ! -s \"$model_cfg\" ]; then\n      log_warn \"MODEL\" \"MODEL is set in environment but not passed with -m/--set-default; use -m for per-run override or --set-default to persist.\"\n    fi\n  fi\n\n  FINAL_MODEL=\"\"\n\n  # 1) CLI-specified model (highest priority)\n  if [ \"${MODEL_CLI_SET:-0}\" -eq 1 ] && [ -n \"${MODEL:-}\" ]; then\n    FINAL_MODEL=\"$MODEL\"\n    return 0\n  fi\n\n  # Determine active provider robustly for provider-specific default lookup:\n  # Precedence: PROVIDER_CLI -> persisted provider file under canonical config dir -> $PROVIDER -> fallback groq\n  if [ -n \"${PROVIDER_CLI:-}\" ]; then\n    active_provider=\"${PROVIDER_CLI}\"\n  elif [ -f \"$(canonical_provider_file)\" ] && [ -s \"$(canonical_provider_file)\" ]; then\n    active_provider=\"$(sed -n '1p' \"$(canonical_provider_file)\" 2>/dev/null || true)\"\n    active_provider=\"$(printf '%s' \"$active_provider\" | awk '{$1=$1;print}')\"\n    [ -z \"$active_provider\" ] && active_provider=\"${PROVIDER:-groq}\"\n  else\n    active_provider=\"${PROVIDER:-groq}\"\n  fi\n\n  # 2) provider-specific persisted default (model.<active_provider>)\n  # Determine active provider robustly: precedence PROVIDER_CLI -> persisted provider file -> $PROVIDER -> fallback groq\n  if [ -n \"${PROVIDER_CLI:-}\" ]; then\n    active_provider=\"${PROVIDER_CLI}\"\n  elif [ -f \"$(canonical_provider_file)\" ] && [ -s \"$(canonical_provider_file)\" ]; then\n    active_provider=\"$(sed -n '1p' \"$(canonical_provider_file)\" 2>/dev/null || true)\"\n    active_provider=\"$(printf '%s' \"$active_provider\" | awk '{$1=$1;print}')\"\n    [ -z \"$active_provider\" ] && active_provider=\"${PROVIDER:-groq}\"\n  else\n    active_provider=\"${PROVIDER:-groq}\"\n  fi\n\n  MODEL_PROVIDER_CFG=\"$(canonical_model_file \"${active_provider}\")\"\n  # Defensive check: refuse to read model files if canonical config dir is invalid\n  if [ -z \"$(canonical_config_dir)\" ] || [ \"$(canonical_config_dir)\" = \"/\" ]; then\n    log_error \"SEC\" \"refusing to read provider-specific model file: invalid canonical config dir: $(canonical_config_dir)\"\n  else\n    if [ -s \"$MODEL_PROVIDER_CFG\" ]; then\n      candidate=\"$(sed -n '1p' \"$MODEL_PROVIDER_CFG\" 2>/dev/null || true)\"\n      candidate=\"$(printf '%s' \"$candidate\" | awk '{$1=$1;print}')\"\n      if [ -n \"$candidate\" ] && is_supported_model \"$candidate\"; then\n        if validate_model_core \"$candidate\" >/dev/null 2>&1 && validate_model_dispatch \"$candidate\" >/dev/null 2>&1; then\n          FINAL_MODEL=\"$candidate\"\n          return 0\n        fi\n      fi\n    fi\n  fi\n\n  # 3) provider auto-select (only if provider module can provide it)\n  candidate=\"$(auto_select_model_dispatch 2>/dev/null || true)\"\n  if [ -n \"$candidate\" ] && is_supported_model \"$candidate\"; then\n    if validate_model_dispatch \"$candidate\" >/dev/null 2>&1 && validate_model_core \"$candidate\" >/dev/null 2>&1; then\n      FINAL_MODEL=\"$candidate\"\n      return 0\n    fi\n  fi\n\n  # 4) first supported entry in MODELS_FILE (if present)\n  if [ -f \"${MODELS_FILE:-}\" ] && [ -s \"${MODELS_FILE:-}\" ]; then\n    cnt=0\n    while IFS= read -r m || [ -n \"$m\" ]; do\n      [ -z \"$m\" ] && continue\n      cnt=$((cnt+1))\n      if is_supported_model \"$m\"; then\n        if validate_model_core \"$m\" >/dev/null 2>&1 && validate_model_dispatch \"$m\" >/dev/null 2>&1; then\n          FINAL_MODEL=\"$m\"\n          return 0\n        fi\n      fi\n      [ \"$cnt\" -ge \"$MAX_MODELS\" ] && break\n    done < \"$MODELS_FILE\"\n  fi\n\n  # 5) config MODEL= in config file (legacy)\n  if [ -f \"${GROQBASH_CONFIG_DIR%/}/config\" ]; then\n    cfg_model=\"$(awk -F= '/^MODEL=/ {sub(/^MODEL=/,\"\"); print; exit}' \"${GROQBASH_CONFIG_DIR%/}/config\" 2>/dev/null 
```

**line_start**: 3097  

**body_full**:
```sh
# source: groqbash:3097\nresolve_model() {\n  # Guard: warn if MODEL is present in environment but not provided via -m/--set-default.\n  # This helps CI/users who export MODEL expecting it to behave like -m.\n  if [ -n \"${MODEL:-}\" ] && [ \"${MODEL_CLI_SET:-0}\" -ne 1 ]; then\n    # Only warn when no provider-specific persisted default exists (avoid noisy logs).\n    model_cfg=\"$(canonical_model_file \"${PROVIDER:-groq}\")\"\n    if [ ! -s \"$model_cfg\" ]; then\n      log_warn \"MODEL\" \"MODEL is set in environment but not passed with -m/--set-default; use -m for per-run override or --set-default to persist.\"\n    fi\n  fi\n\n  FINAL_MODEL=\"\"\n\n  # 1) CLI-specified model (highest priority)\n  if [ \"${MODEL_CLI_SET:-0}\" -eq 1 ] && [ -n \"${MODEL:-}\" ]; then\n    FINAL_MODEL=\"$MODEL\"\n    return 0\n  fi\n\n  # Determine active provider robustly for provider-specific default lookup:\n  # Precedence: PROVIDER_CLI -> persisted provider file under canonical config dir -> $PROVIDER -> fallback groq\n  if [ -n \"${PROVIDER_CLI:-}\" ]; then\n    active_provider=\"${PROVIDER_CLI}\"\n  elif [ -f \"$(canonical_provider_file)\" ] && [ -s \"$(canonical_provider_file)\" ]; then\n    active_provider=\"$(sed -n '1p' \"$(canonical_provider_file)\" 2>/dev/null || true)\"\n    active_provider=\"$(printf '%s' \"$active_provider\" | awk '{$1=$1;print}')\"\n    [ -z \"$active_provider\" ] && active_provider=\"${PROVIDER:-groq}\"\n  else\n    active_provider=\"${PROVIDER:-groq}\"\n  fi\n\n  # 2) provider-specific persisted default (model.<active_provider>)\n  # Determine active provider robustly: precedence PROVIDER_CLI -> persisted provider file -> $PROVIDER -> fallback groq\n  if [ -n \"${PROVIDER_CLI:-}\" ]; then\n    active_provider=\"${PROVIDER_CLI}\"\n  elif [ -f \"$(canonical_provider_file)\" ] && [ -s \"$(canonical_provider_file)\" ]; then\n    active_provider=\"$(sed -n '1p' \"$(canonical_provider_file)\" 2>/dev/null || true)\"\n    active_provider=\"$(printf '%s' \"$active_provider\" | awk '{$1=$1;print}')\"\n    [ -z \"$active_provider\" ] && active_provider=\"${PROVIDER:-groq}\"\n  else\n    active_provider=\"${PROVIDER:-groq}\"\n  fi\n\n  MODEL_PROVIDER_CFG=\"$(canonical_model_file \"${active_provider}\")\"\n  # Defensive check: refuse to read model files if canonical config dir is invalid\n  if [ -z \"$(canonical_config_dir)\" ] || [ \"$(canonical_config_dir)\" = \"/\" ]; then\n    log_error \"SEC\" \"refusing to read provider-specific model file: invalid canonical config dir: $(canonical_config_dir)\"\n  else\n    if [ -s \"$MODEL_PROVIDER_CFG\" ]; then\n      candidate=\"$(sed -n '1p' \"$MODEL_PROVIDER_CFG\" 2>/dev/null || true)\"\n      candidate=\"$(printf '%s' \"$candidate\" | awk '{$1=$1;print}')\"\n      if [ -n \"$candidate\" ] && is_supported_model \"$candidate\"; then\n        if validate_model_core \"$candidate\" >/dev/null 2>&1 && validate_model_dispatch \"$candidate\" >/dev/null 2>&1; then\n          FINAL_MODEL=\"$candidate\"\n          return 0\n        fi\n      fi\n    fi\n  fi\n\n  # 3) provider auto-select (only if provider module can provide it)\n  candidate=\"$(auto_select_model_dispatch 2>/dev/null || true)\"\n  if [ -n \"$candidate\" ] && is_supported_model \"$candidate\"; then\n    if validate_model_dispatch \"$candidate\" >/dev/null 2>&1 && validate_model_core \"$candidate\" >/dev/null 2>&1; then\n      FINAL_MODEL=\"$candidate\"\n      return 0\n    fi\n  fi\n\n  # 4) first supported entry in MODELS_FILE (if present)\n  if [ -f \"${MODELS_FILE:-}\" ] && [ -s \"${MODELS_FILE:-}\" ]; then\n    cnt=0\n    while IFS= read -r m || [ -n \"$m\" ]; do\n      [ -z \"$m\" ] && continue\n      cnt=$((cnt+1))\n      if is_supported_model \"$m\"; then\n        if validate_model_core \"$m\" >/dev/null 2>&1 && validate_model_dispatch \"$m\" >/dev/null 2>&1; then\n          FINAL_MODEL=\"$m\"\n          return 0\n        fi\n      fi\n      [ \"$cnt\" -ge \"$MAX_MODELS\" ] && break\n    done < \"$MODELS_FILE\"\n  fi\n\n  # 5) config MODEL= in config file (legacy)\n  if [ -f \"${GROQBASH_CONFIG_DIR%/}/config\" ]; then\n    cfg_model=\"$(awk -F= '/^MODEL=/ {sub(/^MODEL=/,\"\"); print; exit}' \"${GROQBASH_CONFIG_DIR%/}/config\" 2>/dev/null || true)\"\n    cfg_model=\"$(printf '%s' \"$cfg_model\" | awk '{$1=$1;print}')\"\n    if [ -n \"$cfg_model\" ] && is_supported_model \"$cfg_model\"; then\n      if validate_model_core \"$cfg_model\" >/dev/null 2>&1 && validate_model_dispatch \"$cfg_model\" >/dev/null 2>&1; then\n        FINAL_MODEL=\"$cfg_model\"\n        return 0\n      fi\n    fi\n  fi\n\n  # 6) ALLOWED_MODELS fallback (first supported)\n  if [ -n \"${ALLOWED_MODELS:-}\" ]; then\n    cnt=0\n    while IFS= read -r m || [ -n \"$m\" ]; do\n      [ -z \"$m\" ] && continue\n      cnt=$((cnt+1))\n      if is_supported_model \"$m\"; then\n        if validate_model_core \"$m\" >/dev/null 2>&1 && validate_model_dispatch \"$m\" >/dev/null 2>&1; then\n          FINAL_MODEL=\"$m\"\n          return 0\n        fi\n      fi\n      [ \"$cnt\" -ge \"$MAX_MODELS\" ] && break\n    done <<EOF\n$(printf '%s\\n' \"$ALLOWED_MODELS\")\nEOF\n  fi\n\n  # Nothing found\n  FINAL_MODEL=\"\"\n  return 1\n}"
```

---

**name**: "trim"  

**file**: "groqbash"  

**line_range**: "L3522"  

**body_snippet**: 
```sh
# source: groqbash:3522\ntrim() { printf '%s' \"$1\" | awk '{$1=$1; print}'; }
```

**line_start**: 3522  

**body_full**:
```sh
# source: groqbash:3522\ntrim() { printf '%s' \"$1\" | awk '{$1=$1; print}'; }"
```

---

**name**: "validate_model_core"  

**file**: "groqbash"  

**line_range**: "L3567"  

**body_snippet**: 
```sh
# source: groqbash:3567\nvalidate_model_core() {\n  # Validate a model name against local MODELS_FILE (if present) and textual support.\n  # Accepts exact matches or matches after stripping common provider prefixes like \"models/\".\n  local model=\"$1\" norm_model file_match\n  [ -n \"$model\" ] || { printf 'groqbash: ERROR: validate_model_core: model required\\n' >&2; return 1; }\n\n  # Normalize incoming model for comparison: strip leading \"models/\" and surrounding whitespace\n  norm_model=\"$(printf '%s' \"$model\" | sed -e 's#^models/##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n\n  # If MODELS_FILE exists and non-empty, require presence (allow either raw or prefixed forms)\n  if [ -f \"${MODELS_FILE:-}\" ] && [ -s \"${MODELS_FILE:-}\" ]; then\n    # Check exact match first (file may contain provider-specific forms)\n    if grep -x -F -q \"$model\" \"$MODELS_FILE\" 2>/dev/null; then\n      file_match=1\n    else\n      # Check normalized match (strip leading models/ in file entries and compare)\n      if awk '{gsub(/^models\\//,\"\"); print}' \"$MODELS_FILE\" | grep -x -F -q \"$norm_model\" 2>/dev/null; then\n        file_match=1\n      else\n        file_match=0\n      fi\n    fi\n\n    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}
```

**line_start**: 3567  

**body_full**:
```sh
# source: groqbash:3567\nvalidate_model_core() {\n  # Validate a model name against local MODELS_FILE (if present) and textual support.\n  # Accepts exact matches or matches after stripping common provider prefixes like \"models/\".\n  local model=\"$1\" norm_model file_match\n  [ -n \"$model\" ] || { printf 'groqbash: ERROR: validate_model_core: model required\\n' >&2; return 1; }\n\n  # Normalize incoming model for comparison: strip leading \"models/\" and surrounding whitespace\n  norm_model=\"$(printf '%s' \"$model\" | sed -e 's#^models/##' -e 's/^[[:space:]]*//;s/[[:space:]]*$//')\"\n\n  # If MODELS_FILE exists and non-empty, require presence (allow either raw or prefixed forms)\n  if [ -f \"${MODELS_FILE:-}\" ] && [ -s \"${MODELS_FILE:-}\" ]; then\n    # Check exact match first (file may contain provider-specific forms)\n    if grep -x -F -q \"$model\" \"$MODELS_FILE\" 2>/dev/null; then\n      file_match=1\n    else\n      # Check normalized match (strip leading models/ in file entries and compare)\n      if awk '{gsub(/^models\\//,\"\"); print}' \"$MODELS_FILE\" | grep -x -F -q \"$norm_model\" 2>/dev/null; then\n        file_match=1\n      else\n        file_match=0\n      fi\n    fi\n\n    if [ \"$file_match\" -ne 1 ]; then\n      printf 'groqbash: ERROR: The model \"%s\" is not present in %s\\n' \"$model\" \"$MODELS_FILE\" >&2\n      return 1\n    fi\n  fi\n\n  # Check textual support (reject obvious multimodal/audio/image models by name patterns)\n  if ! is_supported_model \"$norm_model\"; then\n    printf 'groqbash: ERROR: The \"%s\" model is not supported by GroqBash (requires non-text input).\\n' \"$model\" >&2\n    return 1\n  fi\n\n  return 0\n}"
```

---

**name**: "validate_model_dispatch"  

**file**: "groqbash"  

**line_range**: "L3075"  

**body_snippet**: 
```sh
# source: groqbash:3075\nvalidate_model_dispatch() {\n  local model=\"$1\"\n  local fn=\"validate_model_${PROVIDER}\"\n  if type \"$fn\" >/dev/null 2>&1; then\n    \"$fn\" \"$model\"\n    return $?\n  fi\n  # Default permissive behavior if provider does not implement validation\n  return 0\n}
```

**line_start**: 3075  

**body_full**:
```sh
# source: groqbash:3075\nvalidate_model_dispatch() {\n  local model=\"$1\"\n  local fn=\"validate_model_${PROVIDER}\"\n  if type \"$fn\" >/dev/null 2>&1; then\n    \"$fn\" \"$model\"\n    return $?\n  fi\n  # Default permissive behavior if provider does not implement validation\n  return 0\n}"
```

---

### SECTION: CORE_PROVIDER

---

**name**: "assemble_content"  

**file**: "groqbash"  

**line_range**: "L4467"  

**body_snippet**: 
```sh
# source: groqbash:4467\nassemble_content() {\n  CONTENT=\"${CONTENT:-}\"\n  local tmpl tmp_tmpl tmp_final extra file_content\n\n  if [ -n \"$JSON_INPUT\" ]; then CONTENT=\"\"; return 0; fi\n\n  if [ \"${#FILE_INPUTS[@]}\" -gt 0 ]; then\n    CONTENT=\"$(collect_input_from_files \"${FILE_INPUTS[@]}\")\"\n    if [ \"${#ARGS[@]}\" -gt 0 ]; then\n      extra=\"$(expand_args_to_content)\"\n      [ -n \"$extra\" ] && CONTENT=\"${CONTENT}\"$'\\n\\n'\"$extra\"\n    fi\n    return 0\n  fi\n\n  if [ -n \"$TEMPLATE\" ]; then\n    if [ \"${#FILE_INPUTS[@]}\" -gt 0 ]; then\n      CONTENT=\"$(collect_input_from_files \"${FILE_INPUTS[@]}\")\"\n    elif [ -n \"$STDIN_CONTENT\" ]; then\n      CONTENT=\"$STDIN_CONTENT\"\n    else\n      if [ \"${#ARGS[@]}\" -gt 0 ]; then CONTENT=\"$(expand_args_to_content)\"; else CONTENT=\"\"; fi\n    fi\n\n    tmpl=\"$(cat \"$GROQBASH_TEMPLATES_DIR/$TEMPLATE\" 2>/dev/null || true)\"\n    ensure_run_tmpdir\n    tmp_tmpl=\"$(_mktemp_in_dir \"$RUN_TMPDIR\" 2>/dev/null || true)\"\n\n    if [ -n \"$tmp_tmpl\" ]; then\n      # Preserve original newlines while replacing the placeholder\n      printf '%s' \"$tmpl\" | awk -v repl=\"$CONTENT\" '{ gsub(/\\{\\{CONTENT\\}\\}/, repl); print }' > \"$tmp_tmpl\"\n      tmp_final=\"${tmp_tmpl}.final\"\n      mv \"$tmp_tmpl\" \"$tmp_final\" 2>/dev/null || true\n      file_content=\"$(cat \"$tmp_final\" 2>/dev/null || printf '%s' \"$tmpl\")\"\n      CONTENT=\"$file_content\"\n      rm -f \"$tmp_final\" 2>/dev/null || true\n    else\n      # Fallback: perform replacement while preserving newlines\n      CONTENT=\"$(printf '%s' \"$tmpl\" | awk -v repl=\"$CONTENT\" '{ gsub(/\\{\\{CONTENT\\}\\}/, repl); print }')\"\n    fi\n    return 0\n  fi\n\n  if [ -n \"$STDIN_CONTENT\" ]; then\n    CONTENT=\"$STDIN_CONTENT\"\n    if [ \"${#ARGS[@]}\" -gt 0 ]; then\n      extra=\"$(expand_args_to_content)\"\n      [ -n \"$extra\" ] && CONTENT=\"${CONTENT}\"$'\\n\\n'\"$extra\"\n    fi\n    return 0\n  fi\n\n  if [ \"${#ARGS[@]}\" -gt 0 ]; then CONTENT=\"$(expand_args_to_content)\"; else CONTENT=\"\"; fi\n  return 0\n}
```

**line_start**: 4467  

**body_full**:
```sh
# source: groqbash:4467\nassemble_content() {\n  CONTENT=\"${CONTENT:-}\"\n  local tmpl tmp_tmpl tmp_final extra file_content\n\n  if [ -n \"$JSON_INPUT\" ]; then CONTENT=\"\"; return 0; fi\n\n  if [ \"${#FILE_INPUTS[@]}\" -gt 0 ]; then\n    CONTENT=\"$(collect_input_from_files \"${FILE_INPUTS[@]}\")\"\n    if [ \"${#ARGS[@]}\" -gt 0 ]; then\n      extra=\"$(expand_args_to_content)\"\n      [ -n \"$extra\" ] && CONTENT=\"${CONTENT}\"$'\\n\\n'\"$extra\"\n    fi\n    return 0\n  fi\n\n  if [ -n \"$TEMPLATE\" ]; then\n    if [ \"${#FILE_INPUTS[@]}\" -gt 0 ]; then\n      CONTENT=\"$(collect_input_from_files \"${FILE_INPUTS[@]}\")\"\n    elif [ -n \"$STDIN_CONTENT\" ]; then\n      CONTENT=\"$STDIN_CONTENT\"\n    else\n      if [ \"${#ARGS[@]}\" -gt 0 ]; then CONTENT=\"$(expand_args_to_content)\"; else CONTENT=\"\"; fi\n    fi\n\n    tmpl=\"$(cat \"$GROQBASH_TEMPLATES_DIR/$TEMPLATE\" 2>/dev/null || true)\"\n    ensure_run_tmpdir\n    tmp_tmpl=\"$(_mktemp_in_dir \"$RUN_TMPDIR\" 2>/dev/null || true)\"\n\n    if [ -n \"$tmp_tmpl\" ]; then\n      # Preserve original newlines while replacing the placeholder\n      printf '%s' \"$tmpl\" | awk -v repl=\"$CONTENT\" '{ gsub(/\\{\\{CONTENT\\}\\}/, repl); print }' > \"$tmp_tmpl\"\n      tmp_final=\"${tmp_tmpl}.final\"\n      mv \"$tmp_tmpl\" \"$tmp_final\" 2>/dev/null || true\n      file_content=\"$(cat \"$tmp_final\" 2>/dev/null || printf '%s' \"$tmpl\")\"\n      CONTENT=\"$file_content\"\n      rm -f \"$tmp_final\" 2>/dev/null || true\n    else\n      # Fallback: perform replacement while preserving newlines\n      CONTENT=\"$(printf '%s' \"$tmpl\" | awk -v repl=\"$CONTENT\" '{ gsub(/\\{\\{CONTENT\\}\\}/, repl); print }')\"\n    fi\n    return 0\n  fi\n\n  if [ -n \"$STDIN_CONTENT\" ]; then\n    CONTENT=\"$STDIN_CONTENT\"\n    if [ \"${#ARGS[@]}\" -gt 0 ]; then\n      extra=\"$(expand_args_to_content)\"\n      [ -n \"$extra\" ] && CONTENT=\"${CONTENT}\"$'\\n\\n'\"$extra\"\n    fi\n    return 0\n  fi\n\n  if [ \"${#ARGS[@]}\" -gt 0 ]; then CONTENT=\"$(expand_args_to_content)\"; else CONTENT=\"\"; fi\n  return 0\n}"
```

---

**name**: "validate_provider_interface"  

**file**: "groqbash"  

**line_range**: "L4267"  

**body_snippet**: 
```sh
# source: groqbash:4267\nvalidate_provider_interface() {\n  local p=\"$1\"\n  local missing=0\n  local required=( \"buildpayload_${p}\" \"call_api_${p}\" )\n  local optional=( \"call_api_streaming_${p}\" \"refresh_models_${p}\" \"validate_model_${p}\" \"auto_select_model_${p}\" )\n  local f\n\n  for f in \"${required[@]}\"; do\n    if ! type \"$f\" >/dev/null 2>&1; then\n      log_error \"PROVIDER\" \"Provider '$p' module does not define required function $f().\"\n      missing=1\n    fi\n  done\n\n  for f in \"${optional[@]}\"; do\n    if ! type \"$f\" >/dev/null 2>&1; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"PROVIDER\" \"Provider '$p' missing optional function $f()\"\n      fi\n    fi\n  done\n\n  return $missing\n}
```

**line_start**: 4267  

**body_full**:
```sh
# source: groqbash:4267\nvalidate_provider_interface() {\n  local p=\"$1\"\n  local missing=0\n  local required=( \"buildpayload_${p}\" \"call_api_${p}\" )\n  local optional=( \"call_api_streaming_${p}\" \"refresh_models_${p}\" \"validate_model_${p}\" \"auto_select_model_${p}\" )\n  local f\n\n  for f in \"${required[@]}\"; do\n    if ! type \"$f\" >/dev/null 2>&1; then\n      log_error \"PROVIDER\" \"Provider '$p' module does not define required function $f().\"\n      missing=1\n    fi\n  done\n\n  for f in \"${optional[@]}\"; do\n    if ! type \"$f\" >/dev/null 2>&1; then\n      if [ \"${DEBUG:-0}\" -eq 1 ]; then\n        log_info \"PROVIDER\" \"Provider '$p' missing optional function $f()\"\n      fi\n    fi\n  done\n\n  return $missing\n}"
```

---
