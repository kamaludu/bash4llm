#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/ui/gui-bootstrap.sh
# Extra: GUI-CGI Lifecycle bootstrap and dependency resolution
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# This script is sourced during runtime to verify the environment,
# discover the location of the bash4llm executable, and maintain caches.

# Resolve the absolute canonical path of BASH4LLM_DIR (Isolated for GUI environment)
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"

# 1. Immediately load the environment and sanitization layer to access parsing functions
if [[ -f "${BOOTSTRAP_DIR}/gui-env.sh" ]]; then
  source "${BOOTSTRAP_DIR}/gui-env.sh"
fi

# 2. Extracts Tenant state in a stateless manner without the use of cookies
TENANT_HASH=""
if declare -f get_tenant_from_request >/dev/null 2>&1; then
  TENANT_HASH="$(get_tenant_from_request)"
fi
export TENANT_HASH

# 3. Dynamically configures the root directory and subdirectories by isolating the tenant
if [[ -n "${TENANT_HASH:-}" ]]; then
  BASH4LLM_DIR="${BOOTSTRAP_DIR}/tmp/gui-runtime.d/tenant_${TENANT_HASH}"
  CFG_DIR="${BASH4LLM_DIR}/config"
  TMP_DIR="${BASH4LLM_DIR}/tmp"
  CONV_DIR="${BASH4LLM_DIR}/conversations"
  LOCK_FILE="${TMP_DIR}/gui.lock"
  CURRENT_CONV_FILE="${CFG_DIR}/current-conv"
  LANG_CURRENT_FILE="${CFG_DIR}/current-lang"
  THEME_CURRENT_FILE="${CFG_DIR}/current-theme"
  SESSION_WINDOW_FILE="${CFG_DIR}/session-window"
  
  export BASH4LLM_DIR CFG_DIR TMP_DIR CONV_DIR LOCK_FILE CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE SESSION_WINDOW_FILE

  # Securely initialize the directory structure for the active tenant
  mkdir -p "$BASH4LLM_DIR" "$CFG_DIR" "$TMP_DIR" "$CONV_DIR" "$BASH4LLM_DIR/history" "$BASH4LLM_DIR/history/sessions" "$CFG_DIR/ui_state" "$CFG_DIR/ui_state/sessions" 2>/dev/null || true
  chmod 700 "$BASH4LLM_DIR" "$CFG_DIR" "$TMP_DIR" "$CONV_DIR" "$BASH4LLM_DIR/history" "$BASH4LLM_DIR/history/sessions" "$CFG_DIR/ui_state" "$CFG_DIR/ui_state/sessions" 2>/dev/null || true
else
  # Security fallback if request lacks tenant indicator (will show login screen)
  BASH4LLM_DIR="${BOOTSTRAP_DIR}/tmp/gui-runtime.d"
  export BASH4LLM_DIR
fi

if declare -f gui_env_init >/dev/null 2>&1; then
  if declare -f is_cgi_mode >/dev/null 2>&1 && is_cgi_mode; then
    gui_env_init "cgi" || true
  else
    gui_env_init "cli" || true
  fi
fi

# CGI/Web-Server Environment Isolation (Zero conflict, standard writeable path)
export HOME="${TMP_DIR}/home"
export XDG_CONFIG_HOME="${CFG_DIR}/xdg"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" 2>/dev/null || true
chmod 700 "$HOME" "$XDG_CONFIG_HOME" 2>/dev/null || true

# Securely locate the active bash4llm executable
ensure_bash4llm_available() {
  if [[ -n "${UI_ROOT:-}" ]]; then
    local wrapper_path="${UI_ROOT%/}/bin/bash4llm-wrapper"
    if [[ -x "$wrapper_path" ]]; then
      BASH4LLM_CMD="$(readlink -f "$wrapper_path" 2>/dev/null || printf '%s' "$wrapper_path")"
      export BASH4LLM_CMD
      
      local cmd_dir
      cmd_dir="$(dirname "$BASH4LLM_CMD")"
      if [[ -d "$cmd_dir/bash4llm.d" ]]; then
        # PROTEZIONE MULTI-TENANT: Evita di sovrascrivere il percorso se la GUI ha già impostato la directory isolata
        if [[ "${BASH4LLM_DIR:-}" != *"gui-runtime.d"* ]]; then
          BASH4LLM_DIR="$(cd "$cmd_dir/bash4llm.d" >/dev/null 2>&1 && pwd -P)"
          export BASH4LLM_DIR
        fi
      fi
      
      log_info "GUIIO" "Discovered bash4llm at $BASH4LLM_CMD"
      return 0
    fi
  fi

  if [[ -n "${UI_ROOT:-}" && -n "${CFG_DIR:-}" ]]; then
    local cfg="${CFG_DIR%/}/bash4llm-path"
    if [[ -f "$cfg" ]]; then
      local p
      p="$(sed -n '1p' "$cfg" 2>/dev/null || true)"
      if [[ -n "$p" && -x "$p" ]]; then
        case "$p" in
          "${UI_ROOT%/}/bin/"*|*/bash4llm.d/extras/ui/bin/*|"$PWD/"* )
            BASH4LLM_CMD="$(readlink -f "$p" 2>/dev/null || printf '%s' "$p")"
            export BASH4LLM_CMD
            return 0
            ;;
          *)
            log_warn "GUIIO" "Persisted bash4llm-path '$p' is not a UI wrapper/repo path; ignoring"
            ;;
        esac
      else
        log_warn "GUIIO" "Configured bash4llm path '$p' not executable; will attempt discovery"
      fi
    fi
  fi

  if [[ -n "${BASH4LLM_CMD:-}" && "${BASH4LLM_CMD}" = /* && -x "${BASH4LLM_CMD}" ]]; then
    BASH4LLM_CMD="$(readlink -f "$BASH4LLM_CMD" 2>/dev/null || printf '%s' "$BASH4LLM_CMD")"
    export BASH4LLM_CMD
    return 0
  fi

  local candidates=(
    "$UI_ROOT/../../../bash4llm"
    "${PREFIX:-/data/data/com.termux/files/usr}/bin/bash4llm"
    "/data/data/com.termux/files/usr/bin/bash4llm"
    "/usr/local/bin/bash4llm"
    "/usr/bin/bash4llm"
    "$PWD/bash4llm"
    "${HOME:-}/bash4llm/bash4llm"
    "${HOME:-}/repo-bash4llm/bin/bash4llm"
  )
  local p
  for p in "${candidates[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ -x "$p" ]]; then
      BASH4LLM_CMD="$(readlink -f "$p" 2>/dev/null || printf '%s' "$p")"
      export BASH4LLM_CMD
      log_info "GUIIO" "Discovered bash4llm at $BASH4LLM_CMD (discovery-only; not persisting)"
      return 0
    fi
  done

  log_error "GUIIO" "bash4llm not found: set BASH4LLM_CMD to an absolute executable path or create UI_ROOT/bin/bash4llm-wrapper."
  return 1
}

# Resolve BASH_PATH once (deterministic for wrapper creation)
BASH_PATH="$(command -v bash 2>/dev/null || true)"
if [[ -n "$BASH_PATH" && ! -x "$BASH_PATH" ]]; then
  BASH_PATH=""
fi

# Best-effort permissions adjustments for Termux
fix_termux_perms() {
  if [[ -d "/data/data/com.termux/files/usr" ]]; then
    chmod 700 "$TMP_DIR" 2>/dev/null || true
    chmod 700 "$LOG_DIR" 2>/dev/null || true
    chmod 700 "$CFG_DIR" 2>/dev/null || true
    chmod 700 "$CONV_DIR" 2>/dev/null || true
  fi
  return 0
}

# Automatic Security Sandboxing - Systematic .htaccess protection
ensure_htaccess_protection() {
  local d htaccess_file content
  content="Require all denied"$'\n'"<IfModule !mod_authz_core.c>"$'\n'"  Order deny,allow"$'\n'"  Deny from all"$'\n'"</IfModule>"
  
  local target_dirs=(
    "$CFG_DIR"
    "$TMP_DIR"
    "$CONV_DIR"
    "${BASH4LLM_DIR}/history"
  )

  for d in "${target_dirs[@]}"; do
    if [[ -d "$d" ]]; then
      htaccess_file="${d%/}/.htaccess"
      if [[ ! -f "$htaccess_file" ]]; then
        gui_atomic_write "$htaccess_file" "$content" 2>/dev/null || true
      fi
    fi
  done
}

# Secure provider cache refresh exporting API key dynamically
ensure_provider_cache_fresh() {
  # Safe fallback if the environment is not fully initialized (e.g. SKIP_INIT during install)
  local l_cfg_dir="${CFG_DIR:-${BASH4LLM_DIR:-$BOOTSTRAP_DIR/tmp/gui-runtime.d}/config}"
  local l_tmp_dir="${TMP_DIR:-${BASH4LLM_DIR:-$BOOTSTRAP_DIR/tmp/gui-runtime.d}/tmp}"
  local providers_file="${l_cfg_dir%/}/providers.txt"
  local lockfd tmpf rc=0
  local lockfile="${BOOTSTRAP_LOCK:-$l_tmp_dir/bootstrap.lock}"

  # Optimization: Avoid regeneration if a non-empty cache already exists
  if [[ -s "$providers_file" ]]; then
    return 0
  fi

  mkdir -p "$(dirname -- "$providers_file")" 2>/dev/null || true
  mkdir -p "$l_tmp_dir" 2>/dev/null || true

  exec {lockfd}>"$lockfile" 2>/dev/null || return 1
  if ! flock -x -w 5 "$lockfd"; then
    exec {lockfd}>&- 2>/dev/null || true
    return 0
  fi

  if [[ -z "${BASH4LLM_CMD:-}" || ! -x "${BASH4LLM_CMD}" ]]; then
    flock -u "$lockfd" 2>/dev/null || true
    exec {lockfd}>&- 2>/dev/null || true
    log_warn "PROV" "ensure_provider_cache_fresh: bash4llm not available"
    return 0
  fi

  # Pre-loading the API Key for the active provider
  if declare -f export_api_key_for_provider >/dev/null 2>&1 && declare -f get_default_provider >/dev/null 2>&1; then
    export_api_key_for_provider "$(get_default_provider)" || true
  fi

  tmpf="$(gui_portable_mktemp "$l_tmp_dir" "providers.XXXXXX")" || tmpf=""
  if [[ -n "$tmpf" ]]; then
    "${BASH4LLM_CMD}" --list-providers-raw 2>/dev/null | awk 'NF' >"$tmpf" 2>/dev/null || rc=$?
    if [[ -s "$tmpf" ]]; then
      gui_atomic_write "$providers_file" "$(cat "$tmpf")" || true
      chmod 644 "$providers_file" 2>/dev/null || true
      log_info "PROV" "Providers cache refreshed: $providers_file"
    else
      rm -f -- "$tmpf" 2>/dev/null || true
      log_warn "PROV" "Provider regeneration did not produce any data; keeping previous cache"
    fi
  else
    log_warn "PROV" "Unable to create temporary file for provider cache"
  fi

  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&- 2>/dev/null || true
  return 0
}

# Secure models list cache refresh exporting API key dynamically
ensure_model_cache_fresh() {
  local provider="$1"
  if [[ -z "$provider" ]]; then
    log_warn "MODEL" "ensure_model_cache_fresh called without specifying the provider"
    return 1
  fi
  if ! validate_name "$provider"; then
    log_warn "MODEL" "Invalid provider name: $provider"
    return 1
  fi

  # Safe fallback if the environment is not fully initialized (e.g. SKIP_INIT during install)
  local l_cfg_dir="${CFG_DIR:-${BASH4LLM_DIR:-$BOOTSTRAP_DIR/tmp/gui-runtime.d}/config}"
  local l_tmp_dir="${TMP_DIR:-${BASH4LLM_DIR:-$BOOTSTRAP_DIR/tmp/gui-runtime.d}/tmp}"
  local models_file="${l_cfg_dir%/}/models.${provider}.txt"
  local lockfd tmpf rc=0
  local lockfile="${BOOTSTRAP_LOCK:-$l_tmp_dir/bootstrap.lock}"

  # Optimization: Avoid regeneration if a non-empty cache already exists
  if [[ -s "$models_file" ]]; then
    return 0
  fi

  mkdir -p "$(dirname -- "$models_file")" 2>/dev/null || true
  mkdir -p "$l_tmp_dir" 2>/dev/null || true

  exec {lockfd}>"$lockfile" 2>/dev/null || return 1
  if ! flock -x -w 5 "$lockfd"; then
    exec {lockfd}>&- 2>/dev/null || true
    return 0
  fi

  if [[ -z "${BASH4LLM_CMD:-}" || ! -x "${BASH4LLM_CMD}" ]]; then
    flock -u "$lockfd" 2>/dev/null || true
    exec {lockfd}>&- 2>/dev/null || true
    log_warn "MODEL" "ensure_model_cache_fresh: bash4llm not available"
    return 0
  fi

  # Pre-load API Key for target provider
  if declare -f export_api_key_for_provider >/dev/null 2>&1; then
    export_api_key_for_provider "$provider" || true
  fi

  tmpf="$(gui_portable_mktemp "$l_tmp_dir" "models.${provider}.XXXXXX")" || tmpf=""
  if [[ -n "$tmpf" ]]; then
    "${BASH4LLM_CMD}" --list-models-raw --provider "$provider" 2>/dev/null | awk 'NF' >"$tmpf" 2>/dev/null || rc=$?
    if [[ -s "$tmpf" ]]; then
      gui_atomic_write "$models_file" "$(cat "$tmpf")" || true
      chmod 644 "$models_file" 2>/dev/null || true
      log_info "MODEL" "Models cache refreshed for the provider '$provider': $models_file"
    else
      rm -f -- "$tmpf" 2>/dev/null || true
      log_warn "MODEL" "Regenerating templates for '$provider' produced no data; maintaining cache"
    fi
  else
    log_warn "MODEL" "Unable to create temporary file for template cache for '$provider'"
  fi

  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&- 2>/dev/null || true
  return 0
}

# Final initialization sequence (strict order)
if [[ "${BOOTSTRAP_SKIP_INIT:-0}" -ne 1 ]]; then
  env_detect || log_warn "ENV" "env_detect returned non-zero"
  ensure_dirs || { log_error "INIT" "ensure_dirs failed"; return 1 2>/dev/null || exit 1; }
  
  ensure_sh_executables "$UI_ROOT" || true
  remove_unnecessary_symlinks "$UI_ROOT" || true
  ensure_config_defaults || true
  fix_termux_perms || true
  ensure_htaccess_protection || true
  env_prepare_runtime || log_warn "ENV" "env_prepare_runtime returned non-zero"

  if ! ensure_bash4llm_available; then
    log_error "INIT" "bash4llm binary not found in allowed locations; aborting"
    printf 'bash4llm: ERROR: bash4llm binary not found; aborting\n' >&2
    return 1 2>/dev/null || exit 1
  fi

  # Sourcing Core functions inside Shell Context (Skip in CGI mode to prevent trap conflicts)
  if declare -f is_cgi_mode >/dev/null 2>&1 && is_cgi_mode; then
    # CGI mode: leverage isolated subprocesses and native fallback parsers for absolute robustness
    true
  else
    # CLI mode: source core functions directly for in-process acceleration
    if [[ -n "${BASH4LLM_CMD:-}" && -f "${BASH4LLM_CMD}" ]]; then
      export BASH4LLM_SOURCE_ONLY=1
      source_target="${BASH4LLM_CMD}"

      # If the target is a wrapper containing 'exec', do NOT source it directly
      # to prevent replacing and terminating the calling CGI shell process.
      if grep -q "exec " "$source_target" 2>/dev/null; then
        real_script=""
        # Attempt to extract the absolute path of the real script from the wrapper.
        # We append "|| true" to prevent any grep exit code 1 from triggering the global ERR trap.
        real_script="$(grep -o -E '/[A-Za-z0-9._/-]+/bash4llm' "$source_target" 2>/dev/null | head -n1 || true)"
        if [[ -f "$real_script" && ! "$real_script" =~ wrapper ]]; then
          source_target="$real_script"
        else
          # Fallback to the standard repository path
          local repo_script="${BASH4LLM_DIR%/}/../bash4llm"
          if [[ -f "$repo_script" ]]; then
            source_target="$repo_script"
          else
            source_target=""
          fi
        fi
      fi

      # Execute sourcing only if we have a valid and secure target
      if [[ -n "$source_target" && -f "$source_target" ]]; then
        source "$source_target" 2>/dev/null || true
      fi
    fi
  fi
fi
