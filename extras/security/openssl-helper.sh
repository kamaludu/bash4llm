#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/security/openssl-helper.sh
# Component: Optional OpenSSL Security & Vault Helper (Master-Key wrapped)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================

# Soft dependency check: gracefully exit if openssl is missing
if ! command -v openssl >/dev/null 2>&1; then
  if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    exit 0
  else
    return 0
  fi
fi

# Set active flag once openssl binary presence is verified
BASH4LLM_OPENSSL_ACTIVE=1

# Detect PBKDF2 support safely via direct execution test
_BASH4LLM_VAULT_PBKDF2=0
if printf 'test' | openssl enc -aes-256-cbc -pbkdf2 -iter 10 -salt -pass pass:test >/dev/null 2>&1; then
  _BASH4LLM_VAULT_PBKDF2=1
fi

# Safe configuration directory resolution with isolated fallback
_B4L_CFG_DIR="${BASH4LLM_CONFIG_DIR:-}"
if [ -z "$_B4L_CFG_DIR" ]; then
  _B4L_CFG_DIR="./bash4llm.d/config"
fi

# Cryptographic Vault File Layout (fully secured paths)
_VAULT_FILE="${_B4L_CFG_DIR%/}/keys.enc"       # Encrypted Vault Key (using Master Password)
_VAULT_REC_FILE="${_B4L_CFG_DIR%/}/keys.rec"   # Encrypted Vault Key (using Recovery Key)
_VAULT_DAT_FILE="${_B4L_CFG_DIR%/}/keys.dat"   # Encrypted JSON API Keys Payload (using Vault Key)

# Explicitly declare global array to prevent nounset (set -u) warnings
declare -a _VAULT_OPTS=()

# -----------------------------------------------------------------------------
# Fail-safe fallbacks for core shell helpers to ensure independent solidity
# -----------------------------------------------------------------------------
if ! type trim_space >/dev/null 2>&1; then
  trim_space() {
    local var="${1:-}"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
  }
fi

if ! type safe_mkdir >/dev/null 2>&1; then
  safe_mkdir() {
    local dir="${1:-}" perm="${2:-700}"
    if [ -n "$dir" ] && [ ! -d "$dir" ]; then
      mkdir -p "$dir" 2>/dev/null
      chmod "$perm" "$dir" 2>/dev/null || true
    fi
  }
fi

if ! type _tmpf >/dev/null 2>&1; then
  _tmpf() {
    local mode="${1:-}" base="${2:-}" prefix="${3:-groq}" tmp=""
    # Fallback to standard system temp directories if base is unset or empty
    if [ -z "$base" ]; then
      base="${TMPDIR:-/tmp}"
    fi
    if [ "$mode" = "file" ]; then
      tmp="$(mktemp "${base%/}/${prefix}.XXXXXX" 2>/dev/null)"
      [ -n "$tmp" ] && chmod 600 "$tmp" 2>/dev/null
      printf '%s' "$tmp"
    fi
  }
fi

# -----------------------------------------------------------------------------
# Securely read silent password input with terminal fallback
# -----------------------------------------------------------------------------
_vault_read_password() {
  local prompt="${1:-Password}"
  local pass=""
  
  # Linear Prompt UX: display warning in magenta and invitation on next line
  printf '%s  %s[input is hidden]%s:\n  > ' "$prompt" "${C_MAGENTA:-}" "${C_RST:-}" >&2

  # Read from /dev/tty if available, otherwise fallback to standard input
  if [ -r /dev/tty ] && [ -c /dev/tty ]; then
    stty -echo < /dev/tty 2>/dev/null || true
    IFS= read -r pass < /dev/tty
    stty echo < /dev/tty 2>/dev/null || true
  else
    # Fallback for non-interactive environments
    IFS= read -r pass
  fi
  printf '\n' >&2
  printf '%s' "$pass"
}

# Populate global array _VAULT_OPTS with safe arguments, bypassing slow subshells
_vault_set_opts() {
  local mode="${1:-encrypt}"
  _VAULT_OPTS=( -aes-256-cbc -a )

  if [ "$mode" = "decrypt" ]; then
    _VAULT_OPTS+=( -d )
  fi

  if [ "$_BASH4LLM_VAULT_PBKDF2" -eq 1 ]; then
    _VAULT_OPTS+=( -pbkdf2 -iter 100000 -salt )
  fi

  # Protect credentials from process inspection via local environment variables
  _VAULT_OPTS+=( -pass env:BASH4LLM_VAULT_PASS )
}

# Atomic file helper: encrypt string payload to target file
_vault_encrypt_to_file() {
  local plain_text="${1:-}"
  local dest_file="${2:-}"
  local key_material="${3:-}"
  local tmp_file=""

  if [ -z "$dest_file" ]; then
    return 1
  fi

  tmp_file="$(_tmpf file "${RUN_TMPDIR:-${BASH4LLM_TMPDIR:-}}" vault.tmp 2>/dev/null)" || return 1
  if [ -z "$tmp_file" ]; then 
    return 1
  fi

  _vault_set_opts "encrypt"
  export BASH4LLM_VAULT_PASS="$key_material"
  if ! printf '%s' "$plain_text" | openssl enc "${_VAULT_OPTS[@]}" > "$tmp_file" 2>/dev/null; then
    unset BASH4LLM_VAULT_PASS
    rm -f "$tmp_file" 2>/dev/null || true
    return 1
  fi
  unset BASH4LLM_VAULT_PASS

  # Atomic update with write-failure detection
  if ! mv -f "$tmp_file" "$dest_file" 2>/dev/null; then
    if ! cp -f "$tmp_file" "$dest_file" 2>/dev/null; then
      rm -f "$tmp_file" 2>/dev/null || true
      return 1
    fi
  fi
  chmod 600 "$dest_file" 2>/dev/null || true
  rm -f "$tmp_file" 2>/dev/null || true
  return 0
}

# Atomic file helper: decrypt target file and output payload to stdout
_vault_decrypt_file() {
  local src_file="${1:-}"
  local key_material="${2:-}"
  local decrypted="" rc=0

  [ -f "$src_file" ] || return 1

  _vault_set_opts "decrypt"
  export BASH4LLM_VAULT_PASS="$key_material"
  
  decrypted="$(openssl enc "${_VAULT_OPTS[@]}" < "$src_file" 2>/dev/null | tr -d '\0')"
  rc=${PIPESTATUS[0]} # Capture the exit status of the first command in the pipeline (openssl)
  unset BASH4LLM_VAULT_PASS

  if [ "$rc" -eq 0 ] && [ -n "$decrypted" ]; then
    printf '%s' "$decrypted"
    return 0
  fi
  return 1
}

# Determine if the vault files exist and are allocated
vault_exists() {
  [ -f "$_VAULT_FILE" ] && [ -f "$_VAULT_DAT_FILE" ]
}

# Create new credentials vault, master key wrapping and offline Recovery Key
vault_init() {
  local pass1="" pass2="" recovery_key="" vault_key="" initial_json='{}'

  if vault_exists; then
    printf '  %sError: Vault is already initialized.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n  %s=== INITIALIZING SECURE KEY VAULT ===%s\n\n' "${C_BANNER:-}" "${C_RST:-}" >&2
  
  while :; do
    pass1="$(_vault_read_password "  Create a Master Password (min 8 chars)")"
    if [ ${#pass1} -lt 8 ]; then
      printf '  %sError: Password must be at least 8 characters long.%s\n\n' "${C_BRED:-}" "${C_RST:-}" >&2
      continue
    fi
    pass2="$(_vault_read_password "  Confirm Master Password")"
    if [ "$pass1" != "$pass2" ]; then
      printf '  %sError: Passwords do not match. Try again.%s\n\n' "${C_BRED:-}" "${C_RST:-}" >&2
    else
      break
    fi
  done

  # Generate 32-character hexadecimal offline Recovery Key
  recovery_key="$(openssl rand -hex 16 2>/dev/null)"
  [ -n "$recovery_key" ] || recovery_key="rec-$(date +%s)-$RANDOM-$RANDOM"

  # Generate 64-character hexadecimal internal Vault Key (Symmetric Master Key)
  vault_key="$(openssl rand -hex 32 2>/dev/null)"
  [ -n "$vault_key" ] || vault_key="vk-$(date +%s)-$RANDOM-$RANDOM-$RANDOM"

  safe_mkdir "$_B4L_CFG_DIR" 700

  # 1. Encrypt Vault Key with Master Password -> keys.enc
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_FILE" "$pass1"; then
    printf '  %sFatal: Failed to write master key file.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  # 2. Encrypt Vault Key with Recovery Key -> keys.rec
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_REC_FILE" "$recovery_key"; then
    printf '  %sFatal: Failed to write recovery key file.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  # 3. Encrypt initial empty JSON payload with Vault Key -> keys.dat
  if ! _vault_encrypt_to_file "$initial_json" "$_VAULT_DAT_FILE" "$vault_key"; then
    printf '  %sFatal: Failed to write data file.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n  %s[SUCCESS] Key Vault initialized successfully.%s\n\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
  printf '%s=======================================%s\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
  printf '  %sCRITICAL WARNING: Record your emergency Recovery Key offline!%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
  printf '  You will need this key if you forget your Master Password.\n\n' >&2
  printf '  RECOVERY KEY:  %s%s%s\n\n' "${C_BGREEN:-}" "$recovery_key" "${C_RST:-}" >&2
  printf '%s========================================%s\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
  printf '  Press ENTER to continue...' >&2
  read -r _
  return 0
}

# Decrypt the vault using the Master Password (returns raw JSON on success)
vault_load_keys() {
  local master_pass="" vault_key="" decrypted=""

  if ! vault_exists; then
    return 1
  fi

  # 1. Try to decrypt using the inherited runtime context token
  if [ -n "${_B4L_RT_CTX:-}" ]; then
    vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$_B4L_RT_CTX")"
  fi

  # 2. If the context token is empty or decryption failed, prompt user
  if [ -z "$vault_key" ]; then
    printf "  %sTip: Run %b%s. ./bash4llm%s%b once to unlock your session and bypass password prompts.%b\n\n" \
      "${C_BMAGENTA:-}" "${C_BGREEN:-}" "${C_UNDERLINE:-}" "${C_NOUNDERLINE:-}" "${C_RST:-}" "${C_RST:-}" >&2
    master_pass="$(_vault_read_password "  Enter Master Password to unlock Vault")"
    
    # Decrypt internal Vault Key using Master Password
    vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
    if [ -z "$vault_key" ]; then
      return 2 # Authentication failed
    fi
  fi

  # 3. Decrypt data payload file using Vault Key
  decrypted="$(_vault_decrypt_file "$_VAULT_DAT_FILE" "$vault_key")"
  if [ -z "$decrypted" ] || ! printf '%s' "$decrypted" | jq -e . >/dev/null 2>&1; then
    return 2 # Corrupt database payload
  fi

  printf '%s' "$decrypted"
}

# Re-encrypt internal Master Vault Key with a new Master Password & Recovery Key
vault_change_password() {
  local master_pass="" vault_key="" pass1="" pass2="" recovery_key=""

  if ! vault_exists; then
    printf '  %sError: Vault is not initialized. Please initialize it first.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n  %s--- CHANGE MASTER PASSWORD ---%s\n\n' "${C_BANNER:-}" "${C_RST:-}" >&2
  master_pass="$(_vault_read_password "  Enter CURRENT Master Password")"

  # Decrypt existing internal Vault Key to preserve it
  vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
  if [ -z "$vault_key" ]; then
    printf '  %sError: Authentication failed. Password modification aborted.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
    return 1
  fi

  while :; do
    pass1="$(_vault_read_password "  Enter NEW Master Password (min 8 chars)")"
    if [ ${#pass1} -lt 8 ]; then
      printf '  %sError: Password must be at least 8 characters long.%s\n\n' "${C_BRED:-}" "${C_RST:-}" >&2
      continue
    fi
    pass2="$(_vault_read_password "  Confirm NEW Master Password")"
    if [ "$pass1" != "$pass2" ]; then
      printf '  %sError: Passwords do not match. Try again.%s\n\n' "${C_BRED:-}" "${C_RST:-}" >&2
    else
      break
    fi
  done

  # Regenerate emergency recovery tokens on security credential changes
  recovery_key="$(openssl rand -hex 16 2>/dev/null)"
  [ -n "$recovery_key" ] || recovery_key="rec-$(date +%s)-$RANDOM-$RANDOM"

  # Re-encrypt Vault Key with NEW Master Password -> keys.enc
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_FILE" "$pass1"; then
    printf '  %sError: Failed to update master key file.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  # Re-encrypt Vault Key with NEW Recovery Key -> keys.rec
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_REC_FILE" "$recovery_key"; then
    printf '  %sError: Failed to update recovery key file.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n  %sNotice: A new Recovery Key has been generated for your safety.%s\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
  printf '  NEW RECOVERY KEY:  %s%s%s\n\n' "${C_BGREEN:-}" "$recovery_key" "${C_RST:-}" >&2
  printf '  Press ENTER to continue...' >&2
  read -r _
  return 0
}

# Perform a secure cryptographic wipe of all key files on the filesystem
vault_destroy() {
  local confirm=""

  printf '\n  %sWARNING: This will permanently delete ALL saved API keys and credentials.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
  printf '  Type "DESTROY" to confirm absolute database purge:\n  > ' >&2
  
  read -r confirm
  if [ "$confirm" != "DESTROY" ]; then
    printf '  %sAborted.%s\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
    return 1
  fi

  local file_to_wipe=""
  local wipe_list=()
  wipe_list=("$_VAULT_FILE" "$_VAULT_REC_FILE" "$_VAULT_DAT_FILE")

  for file_to_wipe in "${wipe_list[@]}"; do
    if [ -f "$file_to_wipe" ]; then
      # Attempt native cryptographic removal via shred first
      if ! shred -u -n 3 "$file_to_wipe" 2>/dev/null; then
        # Secure fallback: Determine byte size and calculate real blocks
        local sz=0
        sz=$(wc -c < "$file_to_wipe" 2>/dev/null || echo 0)
        if [ "$sz" -gt 0 ]; then
          local blocks=$(( (sz + 1023) / 1024 ))
          dd if=/dev/zero of="$file_to_wipe" bs=1024 count="$blocks" conv=notrunc 2>/dev/null || true
        fi
        # Flush the file to release the logical inode to disk
        : > "$file_to_wipe" 2>/dev/null || true
      fi
      rm -f -- "$file_to_wipe" 2>/dev/null || true
    fi
  done

  printf '\n  %sVault successfully destroyed. All saved configurations have been wiped.%s\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
  return 0
}

# Decrypt Vault Key using Recovery Key and set a new Master Password
vault_recover() {
  local rec_key="" vault_key="" pass1="" pass2=""

  if [ ! -f "$_VAULT_REC_FILE" ]; then
    printf '  %sError: Recovery database keys.rec is missing. System unrecoverable.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n  %s=== KEY VAULT PASSCODE RECOVERY ===%s\n' "${C_BCYAN:-}" "${C_RST:-}" >&2
  printf '  Enter your offline Recovery Key:\n  > ' >&2
  
  read -r rec_key
  rec_key="$(trim_space "$rec_key")"

  # Decrypt Vault Key using the offline Recovery Key
  vault_key="$(_vault_decrypt_file "$_VAULT_REC_FILE" "$rec_key")"
  if [ -z "$vault_key" ]; then
    printf '  %sError: Invalid Recovery Key or database corruption.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n  %sRecovery authorization successful!%s\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
  printf '  Define a new Master Password to restore standard vault operations.\n\n' >&2

  while :; do
    pass1="$(_vault_read_password "  Enter NEW Master Password (min 8 chars)")"
    if [ ${#pass1} -lt 8 ]; then
      printf '  %sError: Password must be at least 8 characters long.%s\n\n' "${C_BRED:-}" "${C_RST:-}" >&2
      continue
    fi
    pass2="$(_vault_read_password "  Confirm NEW Master Password")"
    if [ "$pass1" != "$pass2" ]; then
      printf '  %sError: Passwords do not match. Try again.%s\n\n' "${C_BRED:-}" "${C_RST:-}" >&2
    else
      break
    fi
  done

  # Re-encrypt Vault Key with new Master Password -> keys.enc
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_FILE" "$pass1"; then
    printf '  %sError: Failed to write recovered database files.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '  %sAccess recovered successfully. Master Password restored.%s\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
  return 0
}

# Manage API key mappings (Add, Modify, and Delete keys)
vault_manage_keys() {
  local current_payload="" master_pass="" vault_key="" choice="" prov="" key_val="" updated_payload=""

  if ! vault_exists; then
    vault_init || return 1
  fi

  master_pass="$(_vault_read_password "  Enter Master Password to access Key Manager")"
  
  # Decrypt internal Vault Key
  vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
  if [ -z "$vault_key" ]; then
    printf '  %sAccess Denied: Incorrect Master Password.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  # Decrypt payload JSON database using Vault Key
  current_payload="$(_vault_decrypt_file "$_VAULT_DAT_FILE" "$vault_key")"
  if [ -z "$current_payload" ]; then
    printf '  %sError: Failed to decrypt database payload.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
    return 1
  fi

  while :; do
    printf '\n  %s=== KEY VAULT OPERATIONS ===%s\n' "${C_BANNER:-}" "${C_RST:-}" >&2
    printf "    %s1)%s List Configured Providers\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s2)%s Add / Update Provider API Key\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s3)%s Delete Provider API Key\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s4)%s Return to Security Console\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf '  Choice:\n  > ' >&2
    
    read -r choice
    
    case "$choice" in
      1)
        printf '\n  %s--- CONFIGURED PROVIDERS ---%s\n' "${C_BCYAN:-}" "${C_RST:-}" >&2
        # Use line-buffered read redirection to process keys safely, preventing word splitting
        while IFS= read -r k; do
          [ -n "$k" ] && printf '    - %s:  %s[SECURED CARD SAVED]%s\n' "$k" "${C_BGREEN:-}" "${C_RST:-}" >&2
        done < <(printf '%s' "$current_payload" | jq -r 'keys[]' 2>/dev/null)
        ;;
      2)
        printf '\n  Enter Provider Name (e.g., groq, gemini, huggingface):\n  > ' >&2
        
        read -r prov
        prov="$(trim_space "$prov" | tr '[:upper:]' '[:lower:]')"
        [ -n "$prov" ] || continue

        printf '  Enter API Key for %s:\n  > ' "$prov" >&2
        
        read -r key_val
        key_val="$(trim_space "$key_val")"
        [ -n "$key_val" ] || continue

        # Transactional verification: validate updated payload before writing to disk
        updated_payload="$(printf '%s' "$current_payload" | jq --arg p "$prov" --arg k "$key_val" '.[$p] = $k' 2>/dev/null || true)"
        
        if [ -n "$updated_payload" ] && printf '%s' "$updated_payload" | jq -e . >/dev/null 2>&1; then
          current_payload="$updated_payload"
          # Update dat file using the immutable Vault Key with write integrity check
          if _vault_encrypt_to_file "$current_payload" "$_VAULT_DAT_FILE" "$vault_key"; then
            printf '  %sKey for "%s" saved securely.%s\n' "${C_BGREEN:-}" "$prov" "${C_RST:-}" >&2
          else
            printf '  %sError: Failed to write database update. Keys not saved.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
          fi
        else
          printf '  %sError: Internal database formatting failed. Operation aborted.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
        fi
        ;;
      3)
        printf '\n  Enter Provider Name to remove:\n  > ' >&2
        
        read -r prov
        prov="$(trim_space "$prov" | tr '[:upper:]' '[:lower:]')"
        [ -n "$prov" ] || continue

        # Transactional verification: validate updated payload before writing to disk
        updated_payload="$(printf '%s' "$current_payload" | jq --arg p "$prov" 'del(.[$p])' 2>/dev/null || true)"
        
        if [ -n "$updated_payload" ] && printf '%s' "$updated_payload" | jq -e . >/dev/null 2>&1; then
          current_payload="$updated_payload"
          # Update dat file using the immutable Vault Key with write integrity check
          if _vault_encrypt_to_file "$current_payload" "$_VAULT_DAT_FILE" "$vault_key"; then
            printf '  %sKey for "%s" deleted.%s\n' "${C_BGREEN:-}" "$prov" "${C_RST:-}" >&2
          else
            printf '  %sError: Failed to save changes to database. Deletion aborted.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
          fi
        else
          printf '  %sError: Internal database formatting failed. Operation aborted.%s\n' "${C_BRED:-}" "${C_RST:-}" >&2
        fi
        ;;
      4)
        break
        ;;
      *)
        printf '  %sInvalid selection.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

# Cryptographically unwrap secure key data from vault without interaction if cached
vault_get_provider_key() {
  local prov="${1:-}"
  local master_pass="${2:-}"
  local vault_key="" decrypted=""

  if [ -z "$prov" ] || [ -z "$master_pass" ] || ! vault_exists; then
    return 1
  fi

  # 1. Decrypt internal Vault Key
  vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
  [ -n "$vault_key" ] || return 2

  # 2. Decrypt data payload JSON using Vault Key
  decrypted="$(_vault_decrypt_file "$_VAULT_DAT_FILE" "$vault_key")"
  [ -n "$decrypted" ] || return 2
  
  printf '%s' "$decrypted" | jq -r --arg p "$prov" '.[$p] // empty' 2>/dev/null
  return 0
}

# Primary Interactive Console Entrypoint
vault_console() {
  local choice=""
  while :; do
    printf '\n  %s=== SECURITY & ENCRYPTION CONSOLE ===%s\n' "${C_BANNER:-}" "${C_RST:-}" >&2
    printf "    %s1)%s Access Key Vault Manager\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s2)%s Change Master Password\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s3)%s Emergency Access Recovery (Forgotten Password)\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s4)%s WIPE Vault (Destroy all credentials)\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf "    %s5)%s Close Console\n" "${C_BCYAN:-}" "${C_RST:-}" >&2
    printf '  Choice:\n  > ' >&2
    
    read -r choice
    
    case "$choice" in
      1) vault_manage_keys ;;
      2) vault_change_password ;;
      3) vault_recover ;;
      4) 
        if vault_destroy; then
          break
        fi
        ;;
      5) 
        break 
        ;;
      *) 
        printf '  %sInvalid selection.%s\n' "${C_RED:-}" "${C_RST:-}" >&2 
        ;;
    esac
  done
}

# Unified cryptographic file hashing API
_secure_hash_sha256() {
  local target_file="${1:-}"
  if [ ! -f "$target_file" ]; then 
    return 1
  fi

  openssl dgst -sha256 -r "$target_file" 2>/dev/null | awk '{print $1}'
}

# Diagnostically test network handshakes to API endpoints
diagnose_tls_connection() {
  local url="${1:-}"
  local target_host=""
  declare -a t_cmd=()

  if [ -z "$url" ]; then 
    return 1
  fi

  target_host="$(printf '%s' "$url" | sed -E 's#https?://([^:/]+).*#\1#')"

  if command -v timeout >/dev/null 2>&1; then 
    t_cmd=( timeout 5 )
  fi

  if "${t_cmd[@]}" openssl s_client -connect "${target_host}:443" -servername "$target_host" </dev/null >/dev/null 2>&1; then
    return 0
  else
    return 2
  fi
}
