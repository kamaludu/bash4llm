#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM+ — Bash-first wrapper for the LLM
# File: extras/ui/gui-bootstrap.sh
# Extra: GUI-CGI Lifecycle bootstrap and dependency resolution
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# This script is sourced during runtime to verify the environment,
# discover the location of the bash4llm executable, and maintain caches.
#

# ---------------------------------------------------------------------------
# Core Environment Sourcing (Conditional and Safe)
# ---------------------------------------------------------------------------
# Sourcing the centralized environment layer if not already loaded in memory.
# This prevents unbound variable crashes under set -u and ensures essential
# disk, permission, and configuration functions are fully available.
if ! declare -f gui_env_init >/dev/null 2>&1; then
  if [[ -f "$(dirname "${BASH_SOURCE[0]:-$0}")/gui-env.sh" ]]; then
    # shellcheck source=/dev/null
    source "$(dirname "${BASH_SOURCE[0]:-$0}")/gui-env.sh"
  fi
fi

# ---------------------------------------------------------------------------
# Ensure bash4llm is available (DETERMINISTIC: discovery-only)
# ---------------------------------------------------------------------------
ensure_bash4llm_available() {
  # 1. Absolute priority: check if the local wrapper is present and executable
  if [[ -n "${UI_ROOT:-}" ]]; then
    local wrapper_path="${UI_ROOT%/}/bin/bash4llm-wrapper"
    if [[ -x "$wrapper_path" ]]; then
      BASH4LLM_CMD="$(readlink -f "$wrapper_path" 2>/dev/null || printf '%s' "$wrapper_path")"
      export BASH4LLM_CMD
      return 0
    fi
  fi

  # 2. Check the persisted path config
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

  # 3. Check BASH4LLM_CMD if set by environment and is absolute
  if [[ -n "${BASH4LLM_CMD:-}" && "${BASH4LLM_CMD}" = /* && -x "${BASH4LLM_CMD}" ]]; then
    BASH4LLM_CMD="$(readlink -f "$BASH4LLM_CMD" 2>/dev/null || printf '%s' "$BASH4LLM_CMD")"
    export BASH4LLM_CMD
    return 0
  fi

  # 4. Discovery candidates list
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

# ---------------------------------------------------------------------------
# Resolve BASH_PATH once (deterministic for wrapper creation)
# ---------------------------------------------------------------------------
BASH_PATH="$(command -v bash 2>/dev/null || true)"
if [[ -n "$BASH_PATH" && ! -x "$BASH_PATH" ]]; then
  BASH_PATH=""
fi

# ---------------------------------------------------------------------------
# Best-effort permissions adjustments for Termux
# ---------------------------------------------------------------------------
fix_termux_perms() {
  if [[ -d "/data/data/com.termux/files/usr" ]]; then
    chmod 700 "$TMP_DIR" 2>/dev/null || true
    chmod 700 "$LOG_DIR" 2>/dev/null || true
    chmod 700 "$CFG_DIR" 2>/dev/null || true
    chmod 700 "$CONV_DIR" 2>/dev/null || true
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Cache refresh helpers (deterministic, single-shot per invocation)
# ---------------------------------------------------------------------------
ensure_provider_cache_fresh() {
  local providers_file="${CFG_DIR%/}/providers.txt"
  local lockfd tmpf rc
  local lockfile="${BOOTSTRAP_LOCK:-$TMP_DIR/bootstrap.lock}"

  mkdir -p "$(dirname -- "$providers_file")" 2>/dev/null || true

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

  if declare -f export_api_key_for_provider >/dev/null 2>&1 && declare -f get_default_provider >/dev/null 2>&1; then
    export_api_key_for_provider "$(get_default_provider)" || true
  fi

  tmpf="$(portable_mktemp "$TMP_DIR" "providers.XXXXXX")" || tmpf=""
  if [[ -n "$tmpf" ]]; then
    "${BASH4LLM_CMD}" --list-providers-raw 2>/dev/null | awk 'NF' >"$tmpf" 2>/dev/null || rc=$?
    if [[ -s "$tmpf" ]]; then
      atomic_write "$providers_file" "$(cat "$tmpf")" || true
      chmod 644 "$providers_file" 2>/dev/null || true
      log_info "PROV" "Providers cache refreshed: $providers_file"
    else
      rm -f -- "$tmpf" 2>/dev/null || true
      log_warn "PROV" "Providers refresh produced no data; keeping existing cache"
    fi
  else
    log_warn "PROV" "Could not create tmp file for providers refresh"
  fi

  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&- 2>/dev/null || true
  return 0
}

ensure_model_cache_fresh() {
  local provider="$1"
  if [[ -z "$provider" ]]; then
    log_warn "MODEL" "ensure_model_cache_fresh called without provider"
    return 1
  fi
  if ! validate_name "$provider"; then
    log_warn "MODEL" "Invalid provider name: $provider"
    return 1
  fi

  local models_file="${CFG_DIR%/}/models.${provider}.txt"
  local lockfd tmpf rc
  local lockfile="${BOOTSTRAP_LOCK:-$TMP_DIR/bootstrap.lock}"

  mkdir -p "$(dirname -- "$models_file")" 2>/dev/null || true

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

  if declare -f export_api_key_for_provider >/dev/null 2>&1; then
    export_api_key_for_provider "$provider" || true
  fi

  tmpf="$(portable_mktemp "$TMP_DIR" "models.${provider}.XXXXXX")" || tmpf=""
  if [[ -n "$tmpf" ]]; then
    "${BASH4LLM_CMD}" --list-models-raw --provider "$provider" 2>/dev/null | awk 'NF' >"$tmpf" 2>/dev/null || rc=$?
    if [[ -s "$tmpf" ]]; then
      atomic_write "$models_file" "$(cat "$tmpf")" || true
      chmod 644 "$models_file" 2>/dev/null || true
      log_info "MODEL" "Models cache refreshed for provider '$provider': $models_file"
    else
      rm -f -- "$tmpf" 2>/dev/null || true
      log_warn "MODEL" "Models refresh for '$provider' produced no data; keeping existing cache"
    fi
  else
    log_warn "MODEL" "Could not create tmp file for models refresh for '$provider'"
  fi

  flock -u "$lockfd" 2>/dev/null || true
  exec {lockfd}>&- 2>/dev/null || true
  return 0
}

# ---------------------------------------------------------------------------
# Final initialization sequence (strict order)
# ---------------------------------------------------------------------------
if [[ "${BOOTSTRAP_SKIP_INIT:-0}" -ne 1 ]]; then
  env_detect || log_warn "ENV" "env_detect returned non-zero"
  ensure_dirs || { log_error "INIT" "ensure_dirs failed"; return 1 2>/dev/null || exit 1; }
  
  # Execute foundational setups now cleanly decoupled in gui-env.sh
  ensure_sh_executables "$UI_ROOT" || true
  remove_unnecessary_symlinks "$UI_ROOT" || true
  ensure_config_defaults || true
  fix_termux_perms || true
  env_prepare_runtime || log_warn "ENV" "env_prepare_runtime returned non-zero"

  if ! ensure_bash4llm_available; then
    log_error "INIT" "bash4llm binary not found in allowed locations; aborting"
    printf 'bash4llm: ERROR: bash4llm binary not found; aborting\n' >&2
    return 1 2>/dev/null || exit 1
  fi

  env_after_bash4llm_resolved || log_warn "ENV" "env_after_bash4llm_resolved returned non-zero"
fi

export UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR \
       LOCK_FILE SERVER_LOG ERROR_LOG CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE \
       DEFAULT_MODEL_FILE DEFAULT_PROVIDER_FILE API_KEY_FILE BASH4LLM_CMD

return 0 2>/dev/null || true
