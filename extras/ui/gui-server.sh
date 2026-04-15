#!/usr/bin/env bash
# =============================================================================
# Mini server Bash per GUI HTML di GroqBash (router, logica applicativa)
# File: gui-server.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Ensure UI_ROOT is defined early for minimal/stripped CGI envs to avoid "unbound variable"
: "${UI_ROOT:=${UI_ROOT:-}}"
if [[ -z "${UI_ROOT:-}" ]]; then
  if [[ "$(basename "$SCRIPT_DIR")" == "cgi-bin" ]]; then
    UI_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P || printf '%s' "$PWD")"
  else
    UI_ROOT="$(cd "$SCRIPT_DIR" 2>/dev/null && pwd -P || printf '%s' "$PWD")"
  fi
fi
export UI_ROOT

BOOTSTRAP="$SCRIPT_DIR/gui-bootstrap.sh"
if [[ ! -f "$BOOTSTRAP" ]]; then
  printf 'Status: 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\nBootstrap missing: %s\n' "$BOOTSTRAP"
  exit 1
fi
: "${GROQBASH_CMD:=groqbash}"
# shellcheck source=/dev/null
source "$BOOTSTRAP"

# -------------------------
# Ensure environment layer is initialized (non-negotiable)
# -------------------------
# gui-env.sh defines UI_ROOT, CFG_DIR, TMP_DIR and the safe defaults.
# Must run after bootstrap so helpers are available.
if [[ -f "$SCRIPT_DIR/gui-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/gui-env.sh" || true
  # initialize runtime environment (idempotent)
  if declare -f env_prepare_runtime >/dev/null 2>&1; then
    env_prepare_runtime || true
  fi
fi

# Ensure minimal runtime defaults (do not override gui-env.sh single source of truth)
: "${UI_ROOT:=${UI_ROOT:-}}"
: "${CFG_DIR:=${CFG_DIR:-${PWD%/}/config}}"
: "${TMP_DIR:=${TMP_DIR:-${UI_ROOT:-$PWD}/tmp}}"
: "${ERROR_LOG:=${ERROR_LOG:-${CFG_DIR%/}/error.log}}"
: "${SERVER_LOG:=${SERVER_LOG:-${CFG_DIR%/}/server.log}}"
export UI_ROOT CFG_DIR TMP_DIR ERROR_LOG SERVER_LOG

# Ensure log files directory exists and is writable where possible
if [[ -n "${CFG_DIR:-}" && ! -d "${CFG_DIR%/}" ]]; then
  mkdir -p -- "${CFG_DIR%/}" 2>/dev/null || true
fi

# -------------------------
# Small helper: call function if exists (avoid set -u crashes)
# -------------------------
run_if_func() {
  local fn="$1"; shift
  if declare -f "$fn" >/dev/null 2>&1; then
    "$fn" "$@"
    return $?
  else
    # log_warn may not exist early; guard
    if declare -f log_warn >/dev/null 2>&1; then
      log_warn "INIT" "Function $fn not defined; skipping"
    fi
    return 0
  fi
}

# -------------------------
# Safe atomic write/append wrappers (hardening)
# -------------------------
atomic_write_safe() {
  # atomic_write_safe <path> <content>
  local path="$1"; shift
  local content="$*"
  if [[ -z "${path:-}" ]]; then
    return 1
  fi

  # Ensure parent dir exists
  mkdir -p -- "$(dirname -- "$path")" 2>/dev/null || true

  # Prefer existing atomic_write implementation if available
  if declare -f atomic_write >/dev/null 2>&1; then
    atomic_write "$path" "$content"
    return $?
  fi

  # Ensure TMP_DIR exists and use it exclusively (never system /tmp)
  : "${TMP_DIR:=${TMP_DIR:-${UI_ROOT:-$PWD}/tmp}}"
  mkdir -p -- "${TMP_DIR%/}" 2>/dev/null || true

  local tmp
  # Try mktemp inside TMP_DIR; do NOT fall back to system tmp
  tmp="$(mktemp "${TMP_DIR%/}/.tmp.XXXXXX" 2>/dev/null || true)"

  # If mktemp failed, create a safe predictable temp file inside TMP_DIR
  if [[ -z "$tmp" ]]; then
    tmp="${TMP_DIR%/}/.tmp.$RANDOM.$$"
    : >"$tmp" 2>/dev/null || { tmp=''; }
  fi

  # If still no tmp, attempt direct write to target (best-effort)
  if [[ -z "$tmp" ]]; then
    printf '%s' "$content" > "$path" 2>/dev/null || return 1
    return 0
  fi

  # Write to temp, set restrictive perms, then move atomically
  printf '%s' "$content" >"$tmp" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || true; return 1; }
  chmod 600 "$tmp" 2>/dev/null || true
  mv -f "$tmp" "$path" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || return 1; }

  return 0
}

atomic_append_conv_safe() {
  # atomic_append_conv_safe <conv_file> <line...>
  local conv="$1"; shift
  local line="$*"
  if [[ -z "${conv:-}" ]]; then
    return 1
  fi
  mkdir -p -- "$(dirname -- "$conv")" 2>/dev/null || true
  if declare -f atomic_append_conv >/dev/null 2>&1; then
    atomic_append_conv "$conv" "$line"
    return $?
  fi
  # Fallback append with locking if flock available
  if command -v flock >/dev/null 2>&1; then
    (
      flock -x 200
      printf '%s\n' "$line" >>"$conv"
    ) 200>"${conv}.lock"
    return $?
  else
    printf '%s\n' "$line" >>"$conv" 2>/dev/null || return 1
    return 0
  fi
}

# -------------------------
# Environment normalization and wrapper enforcement
# -------------------------
: "${GROQBASH_CONFIG_DIR:=${GROQBASH_CONFIG_DIR:-}}"
if [[ -z "${CFG_DIR:-}" ]]; then
  if [[ -n "${GROQBASH_CONFIG_DIR:-}" ]]; then
    CFG_DIR="$GROQBASH_CONFIG_DIR"
  elif [[ -n "${UI_ROOT:-}" ]]; then
    CFG_DIR="${UI_ROOT%/}/config"
  else
    CFG_DIR="${PWD%/}/config"
  fi
fi
export CFG_DIR

# PROVIDER cache/file defaults (ensure variables exist even if gui-env.sh not present)
: "${PROVIDER_CACHE_FILE:=${CFG_DIR%/}/providers.txt}"
: "${PROVIDER_MODELS_DIR:=${CFG_DIR%/}/models}"
export PROVIDER_CACHE_FILE PROVIDER_MODELS_DIR

# If a persisted groqbash-path exists, prefer it (resolve to absolute if possible)
if [[ -f "${CFG_DIR%/}/groqbash-path" ]]; then
  read -r _p <"${CFG_DIR%/}/groqbash-path" 2>/dev/null || _p=''
  if [[ -n "$_p" ]]; then
    if command -v readlink >/dev/null 2>&1; then
      _p="$(readlink -f -- "$_p" 2>/dev/null || printf '%s' "$_p")"
    fi
    if [[ -x "$_p" ]]; then
      GROQBASH_CMD="$_p"
      export GROQBASH_CMD
      if [[ -n "${UI_ROOT:-}" ]]; then
        case ":${PATH:-}:" in *":${UI_ROOT%/}/bin:"*) ;; *) PATH="${UI_ROOT%/}/bin:${PATH:-}"; export PATH ;; esac
      fi
      run_if_func log_info "GUI" "Using persisted GROQBASH_CMD from groqbash-path: $GROQBASH_CMD"
    else
      run_if_func log_warn "GUI" "Persisted groqbash-path not executable: ${_p}"
    fi
  fi
fi

# Ensure GROQBASH_ROOT/GROQBASH_DIR consistent with UI_ROOT if not set
if [[ -z "${GROQBASH_ROOT:-}" && -n "${UI_ROOT:-}" ]]; then
  GROQBASH_ROOT="$(cd "$UI_ROOT/../../.." 2>/dev/null && pwd -P || true)"
  if [[ "${GROQBASH_ROOT##*/}" == "groqbash.d" ]]; then
    GROQBASH_ROOT="$(cd "$GROQBASH_ROOT/.." 2>/dev/null && pwd -P || true)"
  fi
fi
: "${GROQBASH_ROOT:=${GROQBASH_ROOT:-}}"
: "${GROQBASH_DIR:=${GROQBASH_DIR:-${GROQBASH_ROOT%/}/groqbash.d}}"
export GROQBASH_ROOT GROQBASH_DIR

: "${PROVIDERS_DIR:=${PROVIDERS_DIR:-${GROQBASH_DIR%/}/extras/providers}}"
export PROVIDERS_DIR

# Force use of UI_ROOT/bin/groqbash-wrapper when present and executable.
if [[ -n "${UI_ROOT:-}" && -x "${UI_ROOT%/}/bin/groqbash-wrapper" ]]; then
  GROQBASH_CMD="${UI_ROOT%/}/bin/groqbash-wrapper"
  export GROQBASH_CMD
  case ":${PATH:-}:" in
    *":${UI_ROOT%/}/bin:"*) ;;
    *) PATH="${UI_ROOT%/}/bin:${PATH:-}"; export PATH ;;
  esac
  run_if_func log_info "GUI" "Forcing GROQBASH_CMD -> wrapper: $GROQBASH_CMD"
else
  if [[ -z "${GROQBASH_CMD:-}" && -f "${CFG_DIR%/}/groqbash-path" ]]; then
    read -r p <"${CFG_DIR%/}/groqbash-path" 2>/dev/null || p=''
    if [[ -n "$p" && -x "$p" ]]; then
      GROQBASH_CMD="$p"
      export GROQBASH_CMD
      case ":${PATH:-}:" in
        *":${UI_ROOT%/}/bin:"*) ;;
        *) PATH="${UI_ROOT%/}/bin:${PATH:-}"; export PATH ;;
      esac
      run_if_func log_info "GUI" "Using persisted GROQBASH_CMD: $GROQBASH_CMD"
    else
      run_if_func log_info "GUI" "Persisted groqbash-path missing or not executable: ${p:-<empty>}"
    fi
  fi
fi

# -------------------------
# Helpers (small, focused)
# -------------------------
is_configured() {
  local prov model models_file entries
  prov="$(get_default_provider)"
  model="$(get_default_model)"
  models_file="$(get_models_file)"
  if [[ -z "$prov" ]]; then
    return 1
  fi
  if [[ -z "$(read_api_key_file)" ]]; then
    return 1
  fi
  if [[ -n "$model" ]]; then
    return 0
  fi
  if [[ -f "$models_file" ]]; then
    entries="$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)"
    if [[ -n "$entries" ]]; then
      return 0
    fi
  fi
  return 1
}

call_groqbash_with_args() {
  if [[ -z "${GROQBASH_CMD:-}" || ! -x "${GROQBASH_CMD}" ]]; then
    run_if_func log_error "GUIIO" "GROQBASH_CMD not set or not executable: ${GROQBASH_CMD:-<unset>}"
    return 1
  fi
  # Capture stdout and preserve stderr into ERROR_LOG
  local out rc
  out="$("${GROQBASH_CMD}" "$@" </dev/null 2>>"${ERROR_LOG:-/dev/null}" || true)"
  rc=$?
  printf '%s' "$out"
  return $rc
}

get_models_file() {
  local candidate groq_dir provider models_candidate
  if [[ -n "${GROQBASH_CMD:-}" && "${GROQBASH_CMD}" = /* ]]; then
    groq_dir="$(cd "$(dirname -- "$GROQBASH_CMD")" 2>/dev/null && pwd -P || printf '%s' ".")"
    candidate="$groq_dir/groqbash.d/models/models.txt"
    [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  fi
  provider="$(get_default_provider 2>/dev/null || true)"
  if [[ -n "${CFG_DIR:-}" && -n "$provider" ]]; then
    models_candidate="${CFG_DIR%/}/models.${provider}.txt"
    [[ -f "$models_candidate" ]] && { printf '%s' "$models_candidate"; return 0; }
  fi
  if [[ -n "${UI_ROOT:-}" ]]; then
    candidate="$UI_ROOT/../groqbash.d/models/models.txt"
    [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
    candidate="$UI_ROOT/models/models.txt"
    [[ -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  fi
  candidate="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)/groqbash.d/models/models.txt"
  printf '%s' "${candidate:-models/models.txt}"
  return 0
}

refresh_models_via_groqbash() {
  local prov models_file out
  prov="$1"
  models_file="$(get_models_file)"
  if ! (declare -f ensure_groqbash_available >/dev/null 2>&1 && ensure_groqbash_available); then
    run_if_func log_error "GUIIO" "groqbash not available for refresh"
    return 1
  fi
  export_api_key_for_provider "$prov" || true
  out="$("$GROQBASH_CMD" --provider "$prov" --refresh-models </dev/null 2>>"${ERROR_LOG:-/dev/null}" || true)"
  out="$(printf '%s\n' "$out" | sed -n '/\S/ p' | sed -e 's/[[:space:]]\+$//')"
  if [[ -n "$out" ]]; then
    atomic_write_safe "$models_file" "$out" || { run_if_func log_error "GUIIO" "Failed to write models file"; return 1; }
    run_if_func log_info "GUIIO" "Models refreshed for provider $prov"
    return 0
  else
    run_if_func log_warn "GUIIO" "Refresh returned empty list for provider $prov"
    return 1
  fi
}

get_title_file_for_conv() {
  local conv_path="$1"
  printf '%s' "${conv_path%.txt}.title"
}

read_conv_title() {
  local conv_path="$1" title_file
  title_file="$(get_title_file_for_conv "$conv_path")"
  if [[ -r "$title_file" ]]; then
    sed -n '1p' "$title_file" 2>/dev/null || printf ''
  else
    printf ''
  fi
}

find_lang_conf() {
  local candidates=()
  [[ -n "${CFG_DIR:-}" ]] && candidates+=("$CFG_DIR/gui-lang.conf")
  [[ -n "${UI_ROOT:-}" ]] && candidates+=("$UI_ROOT/gui-lang.conf" "$UI_ROOT/static/gui-lang.conf" "$UI_ROOT/extras/ui/gui-lang.conf")
  [[ -n "${SCRIPT_DIR:-}" ]] && candidates+=("$SCRIPT_DIR/gui-lang.conf")
  [[ -n "${HOME:-}" ]] && candidates+=("$HOME/.config/groqbash/gui-lang.conf")
  [[ -n "${UI_ROOT:-}" ]] && candidates+=("$UI_ROOT/../gui-lang.conf")
  local c
  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -r "$c" ]]; then
      printf '%s' "$c"
      return 0
    fi
  done
  return 1
}

build_lang_options() {
  local lang_conf lang_code out code label
  lang_conf="$(find_lang_conf || true)"
  lang_code="$1"
  out=''
  if [[ -n "$lang_conf" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$line" ]] && continue
      if [[ "$line" =~ ^LANG_NAME\.([a-zA-Z_-]+)=(.*)$ ]]; then
        code="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]}"
        code="$(sanitize_param "$code")"
        label="$(sanitize_param "$label")"
        if [[ "$code" == "$lang_code" ]]; then
          out+="<option value=\"$(html_escape "$code")\" selected>$(html_escape "$label")</option>"
        else
          out+="<option value=\"$(html_escape "$code")\">$(html_escape "$label")</option>"
        fi
        out+=$'\n'
      fi
    done <"$lang_conf"
  fi
  printf '%s' "$out"
}

read_txt_key() {
  local key="$1" lang="$2" lang_conf val default_lang
  lang_conf="$(find_lang_conf || true)"
  if [[ -z "$lang_conf" ]]; then
    printf ''
    return 0
  fi
  val="$(awk -F= -v k="${key}.${lang}" '
    $1 == k {
      sub(/^[^=]*=/, "", $0)
      print $0
      exit
    }
  ' "$lang_conf" 2>/dev/null || true)"
  if [[ -n "$val" ]]; then
    printf '%s' "$val"
    return 0
  fi
  default_lang="$(awk -F= '$1=="DEFAULT_LANG" {print $2; exit}' "$lang_conf" 2>/dev/null || true)"
  if [[ -n "$default_lang" ]]; then
    val="$(awk -F= -v k="${key}.${default_lang}" '
      $1 == k {
        sub(/^[^=]*=/, "", $0)
        print $0
        exit
      }
    ' "$lang_conf" 2>/dev/null || true)"
    printf '%s' "$val"
    return 0
  fi
  printf ''
}

build_provider_options() {
  local cur prov out providers_file
  cur="$1"
  out=''
  providers_file="${PROVIDER_CACHE_FILE:-${CFG_DIR%/}/providers.txt}"
  run_if_func ensure_provider_cache_fresh
  if [[ -f "$providers_file" ]]; then
    while IFS= read -r prov; do
      prov="$(sanitize_param "$prov")"
      [ -z "$prov" ] && continue
      if [[ "$prov" == "$cur" ]]; then
        out+='<option value="'"$(html_escape "$prov")"'" selected>'"$(html_escape "$prov")"'</option>'
      else
        out+='<option value="'"$(html_escape "$prov")"'">'"$(html_escape "$prov")"'</option>'
      fi
      out+=$'\n'
    done < <(awk 'NF{print}' "$providers_file" 2>/dev/null || true)
  else
    run_if_func log_warn "PROV" "providers cache missing; provider list empty"
  fi
  PROVIDER_OPTIONS="$out"
  return 0
}

build_model_list_and_select() {
  local cur m out_list out_opts models_file provider
  cur="$1"
  out_list=''
  out_opts=''
  provider="${2:-}"
  if [[ -z "$provider" ]]; then
    provider="$(read_config_or_default "$DEFAULT_PROVIDER_FILE" "")"
  fi
  if [[ -n "$provider" ]]; then
    run_if_func ensure_model_cache_fresh "$provider"
    models_file="${CFG_DIR%/}/models.${provider}.txt"
    if [[ ! -f "$models_file" ]]; then
      models_file="$(get_models_file)"
    fi
  else
    models_file="$(get_models_file)"
  fi
  if [[ -f "$models_file" ]]; then
    while IFS= read -r m; do
      m="$(sanitize_param "$m")"
      [ -z "$m" ] && continue
      out_list+="${m}"$'\n'
      if [[ "$m" == "$cur" ]]; then
        out_opts+='<option value="'"$(html_escape "$m")"'" selected>'"$(html_escape "$m")"'</option>'
      else
        out_opts+='<option value="'"$(html_escape "$m")"'">'"$(html_escape "$m")"'</option>'
      fi
      out_opts+=$'\n'
    done < <(awk 'NF{print}' "$models_file" 2>/dev/null || true)
  else
    run_if_func log_warn "MODEL" "models file missing for provider '$provider'"
  fi
  MODEL_LIST_SCROLL="$out_list"
  MODEL_SELECT_OPTIONS="$out_opts"
  return 0
}

handle_post_settings() {
  local body model provider lang api_key action theme
  body="$(read_post_body)"
  model="$(printf '%s' "$body" | parse_form_field "model" || printf '')"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
  lang="$(printf '%s' "$body" | parse_form_field "lang" || read_config_or_default "$LANG_CURRENT_FILE" "en")"
  api_key="$(printf '%s' "$body" | parse_form_field "api_key" || printf '')"
  action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  lang="$(sanitize_param "$lang")"
  api_key="$(sanitize_param "$api_key")"
  theme="$(printf '%s' "$body" | parse_form_field "theme" || printf '')"
  theme="$(sanitize_param "$theme")"
  if [[ -n "$theme" ]]; then
    if [[ "$theme" == "light" || "$theme" == "dark" ]]; then
      atomic_write_safe "$THEME_CURRENT_FILE" "$theme" || run_if_func log_warn "GUIIO" "Failed to write theme"
    else
      run_if_func log_warn "GUIIO" "Invalid theme value attempted: $theme"
    fi
  fi
  if [[ "$action" == "refresh_models" ]]; then
    provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
    provider="$(sanitize_param "$provider")"
    if [[ -z "$provider" ]]; then
      run_if_func log_warn "GUIIO" "Refresh requested but provider empty"
    else
      if validate_name "$provider"; then
        refresh_models_via_groqbash "$provider" || run_if_func log_error "GUIIO" "Refresh models failed for $provider"
      else
        run_if_func log_warn "GUIIO" "Invalid provider attempted for refresh: $provider"
      fi
    fi
  fi
  if [[ "$action" == "set_model" ]]; then
    model="$(printf '%s' "$body" | parse_form_field "model" || printf '')"
    model="$(sanitize_param "$model")"
    if [[ -z "$model" ]]; then
      run_if_func log_warn "GUIIO" "Set model requested but model empty"
    else
      if validate_name "$model"; then
        atomic_write_safe "$DEFAULT_MODEL_FILE" "$model" || run_if_func log_warn "GUIIO" "Failed to write default model"
      else
        run_if_func log_warn "GUIIO" "Invalid model attempted to set: $model"
      fi
    fi
  fi
  if [[ -n "$model" ]]; then
    if ! validate_name "$model"; then
      run_if_func log_error "GUIIO" "Invalid model name attempted: $model"
      model=""
    fi
  fi
  if [[ -n "$provider" ]]; then
    if ! validate_name "$provider"; then
      run_if_func log_error "GUIIO" "Invalid provider name attempted: $provider"
      provider=""
    fi
  fi
  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi
  if [[ -z "${CFG_DIR:-}" || ! -d "${CFG_DIR%/}" || ! -w "${CFG_DIR%/}" ]]; then
    run_if_func log_warn "GUIIO" "CFG_DIR not writable or unset; cannot persist provider/lang"
  else
    atomic_write_safe "$DEFAULT_PROVIDER_FILE" "$provider" || run_if_func log_warn "GUIIO" "Failed to write default provider"
    if [[ -n "$provider" ]]; then
      run_if_func ensure_model_cache_fresh "$provider" || run_if_func log_warn "MODEL" "ensure_model_cache_fresh failed for $provider"
    fi
    atomic_write_safe "$LANG_CURRENT_FILE" "$lang" || true
  fi
  if [[ -n "$api_key" ]]; then
    save_api_key_file "$api_key" || run_if_func log_warn "GUIIO" "Failed to save API key"
  fi
  return 0
}

handle_post_main() {
  local body prompt model provider conv_file output sanitized_output models_file lang
  body="$(read_post_body)"
  lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"
  model_raw="$(printf '%s' "$body" | parse_form_field "model" || true)"
  provider_raw="$(printf '%s' "$body" | parse_form_field "provider" || true)"
  model="${model_raw:-$(get_default_model)}"
  provider="${provider_raw:-$(get_default_provider)}"
  conv_title_raw="$(printf '%s' "$body" | parse_form_field "conv_title" || true)"
  conv_title="$(sanitize_param "$conv_title_raw")"
  prompt="$(sanitize_param "$prompt")"
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  _max_prompt=${MAX_PROMPT_CHARS:-4096}
  if (( ${#prompt} > _max_prompt )); then
    run_if_func log_error "GUIIO" "Prompt truncated from ${#prompt} to ${_max_prompt} chars"
    prompt="${prompt:0:_max_prompt}"
  fi
  unset _max_prompt
  if [[ -n "$model" ]]; then
    if ! validate_name "$model"; then
      run_if_func log_error "GUIIO" "Invalid model name attempted: $model"
      model=""
    fi
  fi
  if [[ -n "$provider" ]]; then
    if ! validate_name "$provider"; then
      run_if_func log_error "GUIIO" "Invalid provider name attempted: $provider"
      provider=""
    fi
  fi
  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi
  conv_file="$(get_current_conversation_file)"
  if [[ -n "$conv_title" ]]; then
    title_file="$(get_title_file_for_conv "$conv_file")"
    atomic_write_safe "$title_file" "$conv_title" || run_if_func log_warn "GUIIO" "Failed to write conversation title"
  fi
  atomic_append_conv_safe "$conv_file" "USER: $prompt" || run_if_func log_error "GUIIO" "Failed to append USER to conversation"
  if ! is_configured; then
    run_if_func log_error "GUIIO" "Attempt to call groqbash while GUI not configured"
    atomic_append_conv_safe "$conv_file" "AI: ERROR: GUI not configured. Please set provider, API key and model in Settings." || true
    return 0
  fi
  if ! (declare -f export_api_key_for_provider >/dev/null 2>&1 && export_api_key_for_provider "$provider"); then
    run_if_func log_error "GUIIO" "API key missing for provider $provider"
    atomic_append_conv_safe "$conv_file" "AI: ERROR: API key missing for provider $provider. Set it in Settings." || true
    return 0
  fi
  models_file="$(get_models_file)"
  if [[ -f "$models_file" ]]; then
    if [[ -n "$model" ]]; then
      if ! grep -Fxq "$model" "$models_file" 2>/dev/null; then
        run_if_func log_error "GUIIO" "Model $model not in whitelist"
        atomic_append_conv_safe "$conv_file" "AI: ERROR: Selected model not in whitelist. Please refresh models or choose another model." || true
        return 0
      fi
    else
      model="$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)"
      model="$(sanitize_param "$model")"
      if [[ -z "$model" ]]; then
        atomic_append_conv_safe "$conv_file" "AI: ERROR: No model selected and whitelist empty. Please refresh models in Settings." || true
        return 0
      fi
    fi
  fi
  local groq_args=()
  if [[ -n "$provider" ]]; then groq_args+=(--provider "$provider"); fi
  if [[ -n "$model" ]]; then groq_args+=(--model "$model"); fi
  if ! output="$(printf '%s' "$prompt" | call_groqbash_with_args "${groq_args[@]}" 2>>"${ERROR_LOG:-/dev/null}" || true)"; then
    run_if_func log_error "GUIIO" "groqbash invocation failed"
    atomic_append_conv_safe "$conv_file" "AI: ERROR: groqbash invocation failed. Check server logs." || true
    return 0
  fi
  if type html_unescape >/dev/null 2>&1; then
    output="$(html_unescape "$output")"
  else
    output="$(html_unescape_fallback "$output")"
  fi
  sanitized_output="$(sanitize_model_output "$output")"
  atomic_append_conv_safe "$conv_file" "AI: $sanitized_output" || run_if_func log_error "GUIIO" "Failed to append AI to conversation"
}

build_model_options() {
  local models_file model_cur out m
  models_file="$(get_models_file)"
  model_cur="$1"
  out=''
  if [[ -f "$models_file" ]]; then
    while IFS= read -r m; do
      m="$(sanitize_param "$m")"
      [ -z "$m" ] && continue
      if [[ "$m" == "$model_cur" ]]; then
        out+='<option value="'"$(html_escape "$m")"'" selected>'"$(html_escape "$m")"'</option>'
      else
        out+='<option value="'"$(html_escape "$m")"'">'"$(html_escape "$m")"'</option>'
      fi
      out+=$'\n'
    done < <(awk 'NF{print}' "$models_file" 2>/dev/null || true)
  fi
  printf '%s' "$out"
}

build_conv_list() {
  local out f bn title
  out=''
  if [[ -d "$CONV_DIR" ]]; then
    for f in "$CONV_DIR"/conv-*.txt; do
      [ -e "$f" ] || continue
      bn="$(basename -- "$f")"
      title="$(read_conv_title "$f")"
      if [[ -n "$title" ]]; then
        out+="$(html_escape "$bn") — $(html_escape "$title")"$'\n'
      else
        out+="$(html_escape "$bn")"$'\n'
      fi
    done
  fi
  printf '%s' "$out"
}

render_page_main() {
  local lang="$1" theme model_cur prov_cur conv_file configured
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  conv_file="$(get_current_conversation_file)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  if is_configured; then configured="true"; else configured="false"; fi
  MODEL_OPTIONS="$(build_model_options "$model_cur")"
  CONV_LIST="$(build_conv_list)"
  build_current_conv_block "$conv_file"
  LANG_CODE="$(sanitize_param "$lang")"
  THEME="$(sanitize_param "$theme")"
  PROVIDER_CURRENT="$(sanitize_param "$prov_cur")"
  MODEL_CURRENT="$(sanitize_param "$model_cur")"
  API_KEY_FIELD="$(html_escape "$(read_api_key_file)")"
  LANG_OPTIONS="$(build_lang_options "$LANG_CODE")"
  if [[ "$THEME" == "light" ]]; then
    THEME_IS_light="selected"; THEME_IS_dark=""
  else
    THEME_IS_light=""; THEME_IS_dark="selected"
  fi
  local models_file
  models_file="$(get_models_file)"
  if [[ -f "$models_file" && -n "$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)" ]]; then
    MODEL_WHITELIST_PRESENT="true"
  else
    MODEL_WHITELIST_PRESENT="false"
  fi
  CURRENT_CONV_FILE="$(basename -- "$conv_file" 2>/dev/null || printf '')"
  : "${GUI_CGI_BASE:=/groqbash-gui/cgi/}"
  GUI_CGI_BASE="${GUI_CGI_BASE%/}/"
  export MODEL_OPTIONS CONV_LIST CURRENT_CONV
  export LANG_CODE THEME PROVIDER_CURRENT MODEL_CURRENT LANG_OPTIONS THEME_IS_light THEME_IS_dark API_KEY_FIELD MODEL_WHITELIST_PRESENT CURRENT_CONV_FILE CONFIGURED="$configured"
  export GUI_CGI_BASE
  local esc_lang esc_theme esc_model esc_provider esc_conv esc_cgi_base
  esc_lang="$(html_escape "$LANG_CODE")"
  esc_theme="$(html_escape "$THEME")"
  esc_model="$(html_escape "$MODEL_CURRENT")"
  esc_provider="$(html_escape "$PROVIDER_CURRENT")"
  esc_conv="$(html_escape "$CURRENT_CONV_FILE")"
  esc_cgi_base="$(html_escape "$GUI_CGI_BASE")"
  [[ -f "$TEMPLATES_DIR/header.html" ]] && render_template "$TEMPLATES_DIR/header.html" "$esc_lang" "$esc_theme" "$esc_model" "$esc_provider" "$esc_conv" "$esc_cgi_base"
  if [[ "$configured" != "true" ]]; then
    printf '<div class="alert alert-danger">Configuration required: please set provider, API key and model in Settings.</div>\n'
  fi
  [[ -f "$TEMPLATES_DIR/content.html" ]] && render_template "$TEMPLATES_DIR/content.html" "$esc_lang" "$esc_theme" "$esc_model" "$esc_provider" "$esc_conv" "$esc_cgi_base"
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && render_template "$TEMPLATES_DIR/footer.html" "$esc_lang" "$esc_theme" "$esc_model" "$esc_provider" "$esc_conv" "$esc_cgi_base"
}

render_page_settings() {
  local lang="$1" theme model_cur prov_cur conv_file configured models_file
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  conv_file="$(get_current_conversation_file)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  if is_configured; then configured="true"; else configured="false"; fi
  MODEL_OPTIONS="$(build_model_options "$model_cur")"
  CONV_LIST="$(build_conv_list)"
  build_current_conv_block "$conv_file"
  LANG_CODE="$(sanitize_param "$lang")"
  THEME="$(sanitize_param "$theme")"
  PROVIDER_CURRENT="$(sanitize_param "$prov_cur")"
  MODEL_CURRENT="$(sanitize_param "$model_cur")"
  API_KEY_FIELD="$(html_escape "$(read_api_key_file)")"
  LANG_OPTIONS="$(build_lang_options "$LANG_CODE")"
  if [[ "$THEME" == "light" ]]; then
    THEME_IS_light="selected"; THEME_IS_dark=""
  else
    THEME_IS_light=""; THEME_IS_dark="selected"
  fi
  models_file="$(get_models_file)"
  if [[ -f "$models_file" && -n "$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)" ]]; then
    MODEL_WHITELIST_PRESENT="true"
  else
    MODEL_WHITELIST_PRESENT="false"
  fi
  CURRENT_CONV_FILE="$(basename -- "$conv_file" 2>/dev/null || printf '')"
  : "${GUI_CGI_BASE:=/groqbash-gui/cgi/}"
  GUI_CGI_BASE="${GUI_CGI_BASE%/}/"
  build_provider_options "$prov_cur"
  build_model_list_and_select "$model_cur" "$prov_cur"
  export PROVIDER_OPTIONS MODEL_LIST_SCROLL MODEL_SELECT_OPTIONS
  export MODEL_OPTIONS CONV_LIST CURRENT_CONV
  export LANG_CODE THEME PROVIDER_CURRENT MODEL_CURRENT LANG_OPTIONS THEME_IS_light THEME_IS_dark API_KEY_FIELD MODEL_WHITELIST_PRESENT CURRENT_CONV_FILE CONFIGURED GUI_CGI_BASE
  local esc_lang esc_theme esc_model esc_provider esc_conv esc_cgi_base
  esc_lang="$(html_escape "$LANG_CODE")"
  esc_theme="$(html_escape "$THEME")"
  esc_model="$(html_escape "$MODEL_CURRENT")"
  esc_provider="$(html_escape "$PROVIDER_CURRENT")"
  esc_conv="$(html_escape "$CURRENT_CONV_FILE")"
  esc_cgi_base="$(html_escape "$GUI_CGI_BASE")"
  [[ -f "$TEMPLATES_DIR/settings-header.html" ]] && render_template "$TEMPLATES_DIR/settings-header.html" "$esc_lang" "$esc_theme" "$esc_model" "$esc_provider" "$esc_conv" "$esc_cgi_base"
  [[ -f "$TEMPLATES_DIR/settings-content.html" ]] && render_template "$TEMPLATES_DIR/settings-content.html" "$esc_lang" "$esc_theme" "$esc_model" "$esc_provider" "$esc_conv" "$esc_cgi_base"
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && render_template "$TEMPLATES_DIR/footer.html" "$esc_lang" "$esc_theme" "$esc_model" "$esc_provider" "$esc_conv" "$esc_cgi_base"
}

# -------------------------
# Main router
# -------------------------
main() {
  run_if_func ensure_dirs
  if [[ "${is_termux:-}" = "true" ]]; then
    run_if_func fix_termux_perms || true
  fi
  run_if_func ensure_config_defaults
  log_rotate_if_needed "${SERVER_LOG:-/dev/null}" 1048576
  log_rotate_if_needed "${ERROR_LOG:-/dev/null}" 1048576
  if ! (declare -f ensure_flock_available >/dev/null 2>&1 && ensure_flock_available); then
    run_if_func log_error "GUILOCK" "flock missing"
    print_http_error "500 Internal Server Error" "Server misconfiguration: flock not available"
    exit 1
  fi
  if ! (declare -f ensure_groqbash_available >/dev/null 2>&1 && ensure_groqbash_available); then
    run_if_func log_error "GUIIO" "groqbash not found: ${GROQBASH_CMD:-<unset>}"
    print_http_error "500 Internal Server Error" "groqbash not found on server. Contact administrator."
    exit 1
  fi
  if ! (declare -f acquire_lock >/dev/null 2>&1 && acquire_lock); then
    run_if_func log_error "GUILOCK" "Failed to acquire lock"
    exit 1
  fi
  local method="${REQUEST_METHOD:-}"
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  if [[ -z "$method" ]]; then
    method="${1:-GET}"
    method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  fi
  QUERY_STRING="${QUERY_STRING:-}"
  QUERY_STRING="$(printf '%s' "$QUERY_STRING" | tr -d '\000-\037')"
  local lang_code
  lang_code="$(get_query_param "lang" 2>/dev/null || printf '')"
  if [[ -n "$lang_code" ]]; then
    lang_code="$(sanitize_param "$lang_code")"
    if validate_name "$lang_code"; then
      atomic_write_safe "$LANG_CURRENT_FILE" "$lang_code"
    else
      lang_code="en"
    fi
  else
    lang_code="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi
  local theme_code
  theme_code="$(get_query_param "theme" 2>/dev/null || printf '')"
  if [[ -n "$theme_code" ]]; then
    theme_code="$(sanitize_param "$theme_code")"
    if [[ "$theme_code" == "light" || "$theme_code" == "dark" ]]; then
      atomic_write_safe "$THEME_CURRENT_FILE" "$theme_code"
    else
      theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
    fi
  else
    theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  fi
  case "${REQUEST_URI:-${QUERY_STRING:-}} " in
    *page=settings*|*page=settings\&*|*page=settings\?*)
      if [[ "$method" == "POST" ]]; then
        handle_post_settings
        print_http_redirect "${GUI_CGI_BASE:-/groqbash-gui/cgi/}?page=settings"
      else
        print_http_header "200 OK" "text/html; charset=utf-8"
        render_page_settings "$lang_code"
      fi
      ;;
    *page=main*|*page=main\&*|*page=main\?*|*page=*)
      if [[ "$method" == "POST" ]]; then
        handle_post_main
        print_http_redirect "${GUI_CGI_BASE:-/groqbash-gui/cgi/}?page=main"
      else
        print_http_header "200 OK" "text/html; charset=utf-8"
        render_page_main "$lang_code"
      fi
      ;;
    *)
      print_http_header "200 OK" "text/html; charset=utf-8"
      render_page_main "$lang_code"
      ;;
  esac
  return 0
}
main "$@"
