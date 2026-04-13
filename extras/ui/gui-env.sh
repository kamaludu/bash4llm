#!/usr/bin/env bash
# =============================================================================
# Environment layer for GroqBash GUI
# File: gui-env.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================

# ---------------------------------------------------------------------------
# env_detect
# - sets flags: IS_TERMUX, IS_LINUX, IS_MAC, IS_WSL, IS_CYGWIN
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
# - performs environment-specific runtime preparation BEFORE ensure_groqbash_available
# - IMPORTANT: runtime must be read-only for shadow/wrapper persistence unless
#   INSTALL_MODE=1 (explicit install/adapt invocation).
# ---------------------------------------------------------------------------
env_prepare_runtime() {
  : "${UI_ROOT:=${PWD}}"
  : "${TMP_DIR:=${UI_ROOT%/}/tmp}"
  : "${CFG_DIR:=${UI_ROOT%/}/config}"
  : "${BOOTSTRAP_LOCK:=${TMP_DIR%/}/bootstrap.lock}"
  : "${BASH_PATH:=$(command -v bash 2>/dev/null || true)}"
  : "${INSTALL_MODE:=0}"   # 0 = normal runtime (no writes), 1 = install/adapt (allowed writes)"

  # --- Safe defaults for GUI runtime (single source of truth) ---
  : "${MAX_PROMPT_CHARS:=4096}"
  : "${MAX_RESPONSE_CHARS:=8192}"
  : "${MAX_TOKENS:=2048}"
  : "${PROVIDER_CACHE_FILE:=${CFG_DIR%/}/providers.txt}"
  : "${PROVIDER_MODELS_DIR:=${CFG_DIR%/}/models}"
  export MAX_PROMPT_CHARS MAX_RESPONSE_CHARS MAX_TOKENS PROVIDER_CACHE_FILE PROVIDER_MODELS_DIR
  # ----------------------------------------------------------------

  # Ensure runtime dirs exist and safe perms (idempotent)
  mkdir -p "${TMP_DIR%/}" "${CFG_DIR%/}" "${UI_ROOT%/}/bin" 2>/dev/null || true
  chmod 700 "${TMP_DIR%/}" "${CFG_DIR%/}" "${UI_ROOT%/}/bin" 2>/dev/null || true

  # Log ownership for debugging if CGI runs as different user
  if command -v stat >/dev/null 2>&1; then
    _tmp_owner="$(stat -c '%U:%G' "${TMP_DIR%/}" 2>/dev/null || true)"
    _cfg_owner="$(stat -c '%U:%G' "${CFG_DIR%/}" 2>/dev/null || true)"
    log_info "ENV" "TMP_DIR owner: ${_tmp_owner:-<unknown>}, CFG_DIR owner: ${_cfg_owner:-<unknown>}"
  fi

  # Determine deterministic real binary locations (robust list)
  local groqbash_real groqbash_shadow BIN_DIR wrapper tmp_shadow rc real_hash shadow_hash
  groqbash_shadow="/data/data/com.termux/files/usr/bin/groqbash"

  local candidates=(
    "${UI_ROOT%/}/../groqbash/groqbash"
    "${UI_ROOT%/}/../../groqbash/groqbash"
    "${PWD%/}/groqbash"
    "${HOME%/}/groqbash/groqbash"
    "/data/data/com.termux/files/home/groqbash/groqbash"
  )

  groqbash_real=""
  for cand in "${candidates[@]}"; do
    if [[ -x "$cand" ]]; then
      groqbash_real="$cand"
      log_info "ENV" "Found local groqbash candidate: $groqbash_real"
      break
    fi
  done

  # RUNTIME-ONLY behavior (no persistent writes)
  if [[ "${INSTALL_MODE:-0}" -ne 1 ]]; then
    # Prefer persisted groqbash-path if present and valid
    if [[ -f "${CFG_DIR%/}/groqbash-path" ]]; then
      local persisted
      persisted="$(sed -n '1p' "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true)"
      if [[ -n "$persisted" && -x "$persisted" ]]; then
        GROQBASH_CMD="$persisted"
        export GROQBASH_CMD
        PATH="${UI_ROOT%/}/bin:${PATH:-}"
        export PATH
        log_info "ENV" "Runtime mode: using persisted GROQBASH_CMD=${GROQBASH_CMD}"
        return 0
      else
        log_warn "ENV" "Persisted groqbash-path exists but is not executable or empty; ignoring in runtime"
      fi
    fi

    # If Termux, prefer wrapper/shadow only if already present and executable
    if [[ "${IS_TERMUX:-0}" -eq 1 ]]; then
      BIN_DIR="${UI_ROOT%/}/bin"
      wrapper="$BIN_DIR/groqbash-wrapper"
      if [[ -x "$wrapper" ]]; then
        GROQBASH_CMD="$wrapper"
        export GROQBASH_CMD
        PATH="$BIN_DIR:${PATH:-}"
        export PATH
        log_info "ENV" "Runtime mode (Termux): using existing wrapper $wrapper"
        return 0
      fi
      # If no wrapper, prefer groqbash_real if available
      if [[ -n "$groqbash_real" && -x "$groqbash_real" ]]; then
        GROQBASH_CMD="$groqbash_real"
        export GROQBASH_CMD
        log_info "ENV" "Runtime mode (Termux): no wrapper found, using local repo binary $groqbash_real"
        return 0
      fi
      log_warn "ENV" "Runtime mode (Termux): no wrapper and no local repo binary found; leaving GROQBASH_CMD unset"
      return 0
    fi

    # Non-Termux runtime: prefer local repo binary if present
    if [[ -n "$groqbash_real" && -x "$groqbash_real" ]]; then
      GROQBASH_CMD="$groqbash_real"
      export GROQBASH_CMD
      log_info "ENV" "Runtime mode (non-Termux): using local repo binary $groqbash_real"
      return 0
    fi

    # Nothing resolved; leave defaults
    log_warn "ENV" "Runtime mode: no groqbash resolved (no persisted path, no wrapper, no local binary)"
    return 0
  fi

  # ---------------------------
  # INSTALL_MODE=1 (install/adapt)
  # Allowed to create/update shadow/wrapper/persist groqbash-path
  # ---------------------------

  # If not Termux, do not create a shadow; persist groqbash_real into groqbash-path
  if [[ "${IS_TERMUX:-0}" -ne 1 ]]; then
    if [[ -n "$groqbash_real" && -x "$groqbash_real" ]]; then
      # Persist groqbash_real into CFG_DIR/groqbash-path atomically
      mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
      if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" ]]; then
        tmp_path="$(portable_mktemp "${CFG_DIR%/}")" || tmp_path="${CFG_DIR%/}/groqbash-path.tmp"
        if printf '%s\n' "$groqbash_real" >"$tmp_path" 2>/dev/null; then
          line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
          if [[ "$line_count" -eq 1 ]]; then
            mv -f -- "$tmp_path" "${CFG_DIR%/}/groqbash-path"
            chmod 600 "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
            log_info "ENV" "INSTALL_MODE: persisted groqbash-path -> $groqbash_real"
            GROQBASH_CMD="$groqbash_real"
            export GROQBASH_CMD
            return 0
          else
            log_warn "ENV" "INSTALL_MODE: refusing to persist groqbash-path: temp file contains ${line_count} non-empty lines"
            rm -f -- "$tmp_path" 2>/dev/null || true
            return 0
          fi
        else
          log_warn "ENV" "INSTALL_MODE: failed to write temporary groqbash-path at $tmp_path"
          rm -f -- "$tmp_path" 2>/dev/null || true
          return 0
        fi
      else
        log_warn "ENV" "INSTALL_MODE: CFG_DIR not writable; cannot persist groqbash-path"
        return 0
      fi
    else
      log_warn "ENV" "INSTALL_MODE: no local repo binary found to persist on non-Termux"
      return 0
    fi
  fi

  # From here: IS_TERMUX=1 and INSTALL_MODE=1 -> perform Termux shadow/wrapper update
  # Ensure TMP_DIR usable and flock available; bail gracefully if not
  ensure_tmpdir || { log_warn "ENV" "ensure_tmpdir failed; skipping Termux sync"; return 0; }
  if ! command -v flock >/dev/null 2>&1; then
    log_warn "ENV" "flock not available; skipping Termux shadow/wrapper update"
    return 0
  fi

  # Acquire bootstrap lock (fd 9)
  exec 9>"${BOOTSTRAP_LOCK}" 2>/dev/null || { log_warn "ENV" "cannot open BOOTSTRAP_LOCK"; return 0; }
  if ! flock -x -w 5 9; then
    exec 9>&- 2>/dev/null || true
    log_warn "ENV" "Could not acquire bootstrap lock; skipping Termux shadow/wrapper update"
    return 0
  fi

  # Helper to release lock before any early return
  _release_lock() {
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
  }

  # Compute hashes once to decide whether to update shadow
  real_hash="$(compute_hash "$groqbash_real" 2>/dev/null || true)"
  shadow_hash="$(compute_hash "$groqbash_shadow" 2>/dev/null || true)"

  # Initialize rc defensively
  rc=1

  if [[ -z "$shadow_hash" || "$real_hash" != "$shadow_hash" ]]; then
    tmp_shadow="$(mktemp_portable "$TMP_DIR" "groqbash-shadow.XXXXXX")" || tmp_shadow=""
    if [[ -n "$tmp_shadow" ]]; then
      if ! cp -f -- "$groqbash_real" "$tmp_shadow" 2>/dev/null; then
        log_warn "ENV" "Failed to copy real groqbash to tmp shadow"
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        _release_lock
        return 0
      fi

      # Patch shebang defensively if BASH_PATH resolved and executable
      if [[ -n "${BASH_PATH:-}" && -x "$BASH_PATH" ]]; then
        if head -n1 "$tmp_shadow" 2>/dev/null | grep -qE '^#!'; then
          sed -i '1s|^#!.*|#!'"$BASH_PATH"'|' "$tmp_shadow" 2>/dev/null || true
        fi
      fi

      if ! mv -f -- "$tmp_shadow" "$groqbash_shadow" 2>/dev/null; then
        log_warn "ENV" "Failed to move tmp shadow into place"
        rm -f -- "$tmp_shadow" 2>/dev/null || true
        _release_lock
        return 0
      fi
      rc=0
    else
      # portable_mktemp failed: log explicit reason and do NOT perform unsafe direct copy
      log_warn "ENV" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; refusing to perform direct copy to $groqbash_shadow in INSTALL_MODE"
      _release_lock
      return 0
    fi

    if (( rc != 0 )); then
      log_warn "ENV" "Shadow update returned non-zero rc"
      _release_lock
      return 0
    fi

    chmod 750 "$groqbash_shadow" 2>/dev/null || true
    shadow_hash="$(compute_hash "$groqbash_shadow" 2>/dev/null || true)"
    log_info "ENV" "INSTALL_MODE: Updated groqbash shadow at $groqbash_shadow"
  else
    log_info "ENV" "INSTALL_MODE: groqbash shadow already up-to-date"
  fi

  # Ensure BASH_PATH resolved and executable before creating wrapper
  if [[ -z "${BASH_PATH:-}" || ! -x "$BASH_PATH" ]]; then
    _release_lock
    log_warn "ENV" "BASH_PATH not resolved or not executable; skipping wrapper creation"
    return 0
  fi

  # Create wrapper in UI_ROOT/bin pointing to shadow using resolved BASH_PATH
  BIN_DIR="${UI_ROOT%/}/bin"
  mkdir -p "$BIN_DIR" 2>/dev/null || true
  chmod 700 "$BIN_DIR" 2>/dev/null || true
  wrapper="$BIN_DIR/groqbash-wrapper"

  # Write wrapper atomically into TMP_DIR, then move only if different
  local tmp_wrapper new_wrapper_hash existing_wrapper_hash wrapper_hash
  tmp_wrapper="$(mktemp_portable "$TMP_DIR" "wrapper.XXXXXX")" || tmp_wrapper=""
  if [[ -n "$tmp_wrapper" ]]; then
    printf '%s\n' "#!$BASH_PATH" "exec \"$BASH_PATH\" \"$groqbash_shadow\" \"\$@\"" >"$tmp_wrapper" 2>/dev/null || {
      log_warn "ENV" "Failed to write tmp wrapper"
      rm -f -- "$tmp_wrapper" 2>/dev/null || true
      _release_lock
      return 0
    }

    # If wrapper exists, compare hashes and avoid unnecessary mv
    if [[ -f "$wrapper" ]]; then
      new_wrapper_hash="$(compute_hash "$tmp_wrapper" 2>/dev/null || true)"
      existing_wrapper_hash="$(compute_hash "$wrapper" 2>/dev/null || true)"
      if [[ -n "$new_wrapper_hash" && -n "$existing_wrapper_hash" && "$new_wrapper_hash" == "$existing_wrapper_hash" ]]; then
        rm -f -- "$tmp_wrapper" 2>/dev/null || true
        rc=0
      else
        if ! mv -f -- "$tmp_wrapper" "$wrapper" 2>/dev/null; then
          log_warn "ENV" "Failed to move new wrapper into place"
          rm -f -- "$tmp_wrapper" 2>/dev/null || true
          _release_lock
          return 0
        fi
        rc=0
      fi
    else
      if ! mv -f -- "$tmp_wrapper" "$wrapper" 2>/dev/null; then
        log_warn "ENV" "Failed to move wrapper into place"
        rm -f -- "$tmp_wrapper" 2>/dev/null || true
        _release_lock
        return 0
      fi
      rc=0
    fi
  else
    # fallback: do NOT perform unsafe direct write in INSTALL_MODE; require mktemp
    log_warn "ENV" "portable_mktemp failed for TMP_DIR=${TMP_DIR:-<unset>}; refusing to write wrapper directly in INSTALL_MODE"
    _release_lock
    return 0
  fi

  chmod 750 "$wrapper" 2>/dev/null || true

  # compute wrapper hash once for later use
  wrapper_hash="$(compute_hash "$wrapper" 2>/dev/null || true)"

  # release lock
  _release_lock

  # Export wrapper preference for runtime if executable
  if [[ -x "$wrapper" ]]; then
    GROQBASH_CMD="$wrapper"
    export GROQBASH_CMD
    PATH="$BIN_DIR:${PATH:-}"
    export PATH
    log_info "ENV" "INSTALL_MODE: Termux wrapper ensured at $wrapper (hash: ${wrapper_hash:-<none>})"
  else
    log_warn "ENV" "Wrapper not executable; GROQBASH_CMD not set to wrapper"
  fi

  # Persist groqbash-path into CFG_DIR atomically; ensure CFG_DIR exists
  if [[ -n "${CFG_DIR:-}" ]]; then
    mkdir -p "${CFG_DIR%/}" 2>/dev/null || true
    if [[ -d "${CFG_DIR%/}" && -w "${CFG_DIR%/}" && -n "${wrapper:-}" && -x "$wrapper" ]]; then
      # write into a temp file inside CFG_DIR and validate it contains exactly one non-empty line
      tmp_path="$(portable_mktemp "${CFG_DIR%/}")" || tmp_path="${CFG_DIR%/}/groqbash-path.tmp"
      if printf '%s\n' "$wrapper" >"$tmp_path" 2>/dev/null; then
        # normalize and count non-empty lines
        line_count="$(sed -n '/./p' "$tmp_path" | wc -l 2>/dev/null || echo 0)"
        if [[ "$line_count" -eq 1 ]]; then
          mv -f -- "$tmp_path" "${CFG_DIR%/}/groqbash-path"
          chmod 600 "${CFG_DIR%/}/groqbash-path" 2>/dev/null || true
          log_info "ENV" "INSTALL_MODE: Persisted groqbash-path to ${CFG_DIR%/}/groqbash-path -> $wrapper"
        else
          log_warn "ENV" "INSTALL_MODE: Refusing to persist groqbash-path: temp file contains ${line_count} non-empty lines (expected 1); tmp: $tmp_path"
          rm -f -- "$tmp_path" 2>/dev/null || true
        fi
      else
        log_warn "ENV" "INSTALL_MODE: Failed to write temporary groqbash-path at $tmp_path; skipping persist"
        rm -f -- "$tmp_path" 2>/dev/null || true
      fi
    else
      log_warn "ENV" "INSTALL_MODE: CFG_DIR not writable or wrapper unset/not executable; skipping persist of groqbash-path"
    fi
  fi

  return 0
}

# ---------------------------------------------------------------------------
# env_after_groqbash_resolved
# - operations that require GROQBASH_CMD already resolved
# ---------------------------------------------------------------------------
env_after_groqbash_resolved() {
  if [[ -n "${GROQBASH_CMD:-}" && -x "${GROQBASH_CMD}" ]]; then
    # Lightweight diagnostic: count providers if possible (best-effort)
    local prov_count
    prov_count="$("${GROQBASH_CMD}" --list-providers-raw 2>/dev/null | wc -l 2>/dev/null || true)"
    log_info "ENV" "groqbash resolved: ${GROQBASH_CMD} (providers: ${prov_count:-0})"
  else
    log_warn "ENV" "groqbash not resolved in env_after_groqbash_resolved"
  fi
  return 0
}

# End of gui-env.sh
