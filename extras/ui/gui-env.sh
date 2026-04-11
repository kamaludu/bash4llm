#!/usr/bin/env bash
# =============================================================================
# Environment layer for GroqBash GUI
# File: gui-env.sh 
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Obligatory file: defines env_detect, env_prepare_runtime, env_after_groqbash_resolved

# ---------------------------------------------------------------------------
# env_detect
# - sets flags: IS_TERMUX, IS_LINUX, IS_MAC, IS_WSL, IS_CYGWIN
# - no side-effects (no PATH/file/perm changes)
# ---------------------------------------------------------------------------
env_detect() {
  IS_TERMUX=0
  IS_LINUX=0
  IS_MAC=0
  IS_WSL=0
  IS_CYGWIN=0

  local uname_s
  uname_s="$(uname -s 2>/dev/null || true)"

  if [[ -d "/data/data/com.termux/files/usr" ]]; then
    IS_TERMUX=1
  elif [[ "$uname_s" == "Darwin" ]]; then
    IS_MAC=1
  elif [[ "$uname_s" == "Linux" ]]; then
    # WSL detection: check /proc/version or /proc/sys/kernel/osrelease for "microsoft"
    if grep -qi microsoft /proc/version 2>/dev/null || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
      IS_WSL=1
    else
      IS_LINUX=1
    fi
  elif [[ "$uname_s" == *"CYGWIN"* || "$uname_s" == *"MINGW"* ]]; then
    IS_CYGWIN=1
  fi

  export IS_TERMUX IS_LINUX IS_MAC IS_WSL IS_CYGWIN
  return 0
}

# ---------------------------------------------------------------------------
# env_prepare_runtime
# - performs all environment-specific runtime preparation BEFORE ensure_groqbash_available
# - migrates create_termux_compat_bootstrap logic for Termux
# - idempotent, no exit, no eval, uses TMP_DIR only for temporaries
# - may set GROQBASH_CMD and persist groqbash-path into CFG_DIR
# ---------------------------------------------------------------------------
env_prepare_runtime() {
  # Ensure required globals exist; if not, be conservative and return success (no-op)
  : "${UI_ROOT:=${PWD}}"
  : "${TMP_DIR:=${UI_ROOT%/}/tmp}"
  : "${CFG_DIR:=${UI_ROOT%/}/config}"
  : "${BOOTSTRAP_LOCK:=${TMP_DIR%/}/bootstrap.lock}"
  : "${BASH_PATH:=$(command -v bash 2>/dev/null || true)}"

  # Termux-specific flow
  if [[ "${IS_TERMUX:-0}" -ne 1 ]]; then
    return 0
  fi

  # Determine deterministic real binary locations
  local groqbash_real groqbash_shadow BIN_DIR wrapper tmp_shadow rc real_hash shadow_hash
  groqbash_shadow="/data/data/com.termux/files/usr/bin/groqbash"

  local candidates=("$UI_ROOT/../groqbash/groqbash" "$HOME/groqbash/groqbash")
  groqbash_real=""
  for groqbash_real in "${candidates[@]}"; do
    if [[ -x "$groqbash_real" ]]; then break; else groqbash_real=""; fi
  done

  # If no real binary found, nothing to do here (ensure_groqbash_available will handle)
  if [[ -z "$groqbash_real" ]]; then
    return 0
  fi

  # Ensure TMP_DIR usable and flock available; if not, bail gracefully (no exit)
  ensure_tmpdir || return 0
  if ! command -v flock >/dev/null 2>&1; then
    log_warn "ENV" "flock not available; skipping Termux shadow/wrapper update"
    return 0
  fi

  # Acquire bootstrap lock (fd 9) local to this function
  exec 9>"${BOOTSTRAP_LOCK}" 2>/dev/null || return 0
  if ! flock -x -w 5 9; then
    exec 9>&- 2>/dev/null || true
    log_warn "ENV" "Could not acquire bootstrap lock; skipping Termux shadow/wrapper update"
    return 0
  fi

  # Compute hashes to decide whether to update shadow
  real_hash="$(compute_hash "$groqbash_real" 2>/dev/null || true)"
  shadow_hash="$(compute_hash "$groqbash_shadow" 2>/dev/null || true)"

  if [[ -z "$shadow_hash" || "$real_hash" != "$shadow_hash" ]]; then
    tmp_shadow="$(mktemp_portable "$TMP_DIR" "groqbash-shadow.XXXXXX")" || tmp_shadow=""
    if [[ -n "$tmp_shadow" ]]; then
      if ! cp -f -- "$groqbash_real" "$tmp_shadow" 2>/dev/null; then
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true
        return 0
      fi

      # Patch shebang defensively if BASH_PATH resolved and executable
      if [[ -n "${BASH_PATH:-}" && -x "$BASH_PATH" ]]; then
        if head -n1 "$tmp_shadow" 2>/dev/null | grep -qE '^#!'; then
          # Replace /usr/bin/env bash or env-based shebangs with resolved BASH_PATH
          sed -i '1s|^#! */usr/bin/env[[:space:]]\+bash.*|#!'"$BASH_PATH"'|' "$tmp_shadow" 2>/dev/null || true
          sed -i '1s|^#! */usr/bin/env.*|#!'"$BASH_PATH"'|' "$tmp_shadow" 2>/dev/null || true
        fi
      fi

      if ! mv -f -- "$tmp_shadow" "$groqbash_shadow" 2>/dev/null; then
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true
        return 0
      fi
      rc=0
    else
      # If mktemp_portable failed, attempt direct copy (best-effort)
      if ! cp -f -- "$groqbash_real" "$groqbash_shadow" 2>/dev/null; then
        flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true
        return 0
      fi
      rc=$?
    fi

    if (( rc != 0 )); then
      flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true
      return 0
    fi

    chmod 750 "$groqbash_shadow" 2>/dev/null || true
    shadow_hash="$(compute_hash "$groqbash_shadow" 2>/dev/null || true)"
  fi

  # Ensure BASH_PATH resolved and executable before creating wrapper
  if [[ -z "${BASH_PATH:-}" || ! -x "$BASH_PATH" ]]; then
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
    log_warn "ENV" "BASH_PATH not resolved or not executable; skipping wrapper creation"
    return 0
  fi

  # Create wrapper in UI_ROOT/bin pointing to shadow using resolved BASH_PATH
  BIN_DIR="${UI_ROOT%/}/bin"
  mkdir -p "$BIN_DIR" 2>/dev/null || true
  chmod 700 "$BIN_DIR" 2>/dev/null || true
  wrapper="$BIN_DIR/groqbash-wrapper"

  # Write wrapper atomically: use a temp file in TMP_DIR then move into place
  local tmp_wrapper
  tmp_wrapper="$(mktemp_portable "$TMP_DIR" "wrapper.XXXXXX")" || tmp_wrapper=""
  if [[ -n "$tmp_wrapper" ]]; then
    printf '%s\n' "#!$BASH_PATH" "exec \"$BASH_PATH\" \"$groqbash_shadow\" \"\$@\"" >"$tmp_wrapper" 2>/dev/null || { rm -f -- "$tmp_wrapper" 2>/dev/null || true; flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true; return 0; }
    mv -f -- "$tmp_wrapper" "$wrapper" 2>/dev/null || { rm -f -- "$tmp_wrapper" 2>/dev/null || true; flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true; return 0; }
  else
    # fallback direct write (best-effort)
    printf '%s\n' "#!$BASH_PATH" "exec \"$BASH_PATH\" \"$groqbash_shadow\" \"\$@\"" >"$wrapper" 2>/dev/null || { flock -u 9 2>/dev/null || true; exec 9>&- 2>/dev/null || true; return 0; }
  fi

  chmod 750 "$wrapper" 2>/dev/null || true

  # release lock
  flock -u 9 2>/dev/null || true
  exec 9>&- 2>/dev/null || true

  # Export wrapper preference for runtime
  GROQBASH_CMD="$wrapper"
  export GROQBASH_CMD
  PATH="$BIN_DIR:${PATH:-}"
  export PATH

  # Persist groqbash-path into CFG_DIR only if writable
  if [[ -n "${CFG_DIR:-}" && -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" ]]; then
    atomic_write "${CFG_DIR%/}/groqbash-path" "$wrapper" || true
    chmod 600 "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
  fi

  log_info "ENV" "Termux wrapper ensured at $wrapper"
  return 0
}

# ---------------------------------------------------------------------------
# env_after_groqbash_resolved
# - operations that require GROQBASH_CMD already resolved
# - idempotent, no exit
# ---------------------------------------------------------------------------
env_after_groqbash_resolved() {
  # If groqbash resolved, perform lightweight diagnostics (no side-effects)
  if [[ -n "${GROQBASH_CMD:-}" && -x "${GROQBASH_CMD}" ]]; then
    log_info "ENV" "groqbash resolved: ${GROQBASH_CMD}"
  else
    log_warn "ENV" "groqbash not resolved in env_after_groqbash_resolved"
  fi
  return 0
}

# End of gui-env.sh
