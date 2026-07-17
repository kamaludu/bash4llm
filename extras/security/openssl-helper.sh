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
  return 0
fi

# Detect PBKDF2 support safely, bypassing pipefail exit code traps
_BASH4LLM_VAULT_PBKDF2=0
_openssl_help_text="$(openssl enc -help 2>&1 || true)"
if [[ "$_openssl_help_text" == *"-pbkdf2"* ]]; then
  _BASH4LLM_VAULT_PBKDF2=1
fi

# Cryptographic Vault File Layout
_VAULT_FILE="${BASH4LLM_CONFIG_DIR:-}/keys.enc"       # Encrypted Vault Key (using Master Password)
_VAULT_REC_FILE="${BASH4LLM_CONFIG_DIR:-}/keys.rec"   # Encrypted Vault Key (using Recovery Key)
_VAULT_DAT_FILE="${BASH4LLM_CONFIG_DIR:-}/keys.dat"   # Encrypted JSON API Keys Payload (using Vault Key)

# Explicitly declare global array to prevent nounset (set -u) warnings
declare -a _VAULT_OPTS=()

# Securely read silent password input (signal cleanup is handled by core exit trap)
_vault_read_password() {
  local prompt="${1:-Password: }"
  local pass=""
  
  printf '%s' "$prompt" >&2
  stty -echo 2>/dev/null
  IFS= read -r pass
  stty echo 2>/dev/null
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
  
  decrypted="$(openssl enc "${_VAULT_OPTS[@]}" < "$src_file" 2>/dev/null)"
  rc=$? # Capture exit status immediately before executing unset
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
    printf 'Vault is already initialized.\n' >&2
    return 1
  fi

  printf '\n=== INITIALIZING SECURE KEY VAULT ===\n' >&2
  
  while :; do
    pass1="$(_vault_read_password "Create a Master Password (min 8 chars): ")"
    if [ ${#pass1} -lt 8 ]; then
      printf 'Error: Password must be at least 8 characters long.\n' >&2
      continue
    fi
    pass2="$(_vault_read_password "Confirm Master Password: ")"
    if [ "$pass1" != "$pass2" ]; then
      printf 'Error: Passwords do not match. Try again.\n' >&2
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

  safe_mkdir "$(dirname "$_VAULT_FILE")" 700

  # 1. Encrypt Vault Key with Master Password -> keys.enc
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_FILE" "$pass1"; then
    printf 'Fatal: Failed to write master key file.\n' >&2
    return 1
  fi

  # 2. Encrypt Vault Key with Recovery Key -> keys.rec
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_REC_FILE" "$recovery_key"; then
    printf 'Fatal: Failed to write recovery key file.\n' >&2
    return 1
  fi

  # 3. Encrypt initial empty JSON payload with Vault Key -> keys.dat
  if ! _vault_encrypt_to_file "$initial_json" "$_VAULT_DAT_FILE" "$vault_key"; then
    printf 'Fatal: Failed to write data file.\n' >&2
    return 1
  fi

  printf '\n%b[SUCCESS] Key Vault initialized successfully.%b\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
  printf '%b--------------------------------------------------------%b\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
  printf 'CRITICAL: Record your emergency Recovery Key offline!\n' >&2
  printf 'You will need this key if you forget your Master Password.\n\n' >&2
  printf '  RECOVERY KEY: %b%s%b\n\n' "${C_BGREEN:-}" "$recovery_key" "${C_RST:-}" >&2
  printf '%b--------------------------------------------------------%b\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
  printf 'Press ENTER to continue...' >&2
  read -r _
  return 0
}

# Decrypt the vault using the Master Password (returns raw JSON on success)
vault_load_keys() {
  local master_pass="" vault_key="" decrypted=""

  if ! vault_exists; then
    return 1
  fi

  master_pass="$(_vault_read_password "Enter Master Password to unlock Vault: ")"

  # 1. Decrypt internal Vault Key using Master Password
  vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
  if [ -z "$vault_key" ]; then
    return 2 # Authentication failed
  fi

  # 2. Decrypt data payload file using Vault Key
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
    printf 'Vault is not initialized. Please initialize it first.\n' >&2
    return 1
  fi

  printf '\n--- CHANGE MASTER PASSWORD ---\n' >&2
  master_pass="$(_vault_read_password "Enter CURRENT Master Password: ")"

  # Decrypt existing internal Vault Key to preserve it
  vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
  if [ -z "$vault_key" ]; then
    printf 'Authentication failed. Password modification aborted.\n' >&2
    return 1
  fi

  while :; do
    pass1="$(_vault_read_password "Enter NEW Master Password (min 8 chars): ")"
    if [ ${#pass1} -lt 8 ]; then
      printf 'Error: Password must be at least 8 characters long.\n' >&2
      continue
    fi
    pass2="$(_vault_read_password "Confirm NEW Master Password: ")"
    if [ "$pass1" != "$pass2" ]; then
      printf 'Error: Passwords do not match. Try again.\n' >&2
    else
      break
    fi
  done

  # Regenerate emergency recovery tokens on security credential changes
  recovery_key="$(openssl rand -hex 16 2>/dev/null)"
  [ -n "$recovery_key" ] || recovery_key="rec-$(date +%s)-$RANDOM-$RANDOM"

  # Re-encrypt Vault Key with NEW Master Password -> keys.enc
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_FILE" "$pass1"; then
    printf 'Error: Failed to update master key file.\n' >&2
    return 1
  fi

  # Re-encrypt Vault Key with NEW Recovery Key -> keys.rec
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_REC_FILE" "$recovery_key"; then
    printf 'Error: Failed to update recovery key file.\n' >&2
    return 1
  fi

  printf '\n%bNotice: A new Recovery Key has been generated for your safety.%b\n' "${C_BYELLOW:-}" "${C_RST:-}" >&2
  printf 'NEW RECOVERY KEY: %b%s%b\n\n' "${C_BGREEN:-}" "$recovery_key" "${C_RST:-}" >&2
  printf 'Press ENTER to continue...' >&2
  read -r _
  return 0
}

# Perform a secure cryptographic wipe of all key files on the filesystem
vault_destroy() {
  local confirm=""

  printf '\n%bWARNING: This will permanently delete ALL saved API keys and credentials.%b\n' "${C_BRED:-}" "${C_RST:-}" >&2
  printf 'Type "DESTROY" to confirm absolute database purge: ' >&2
  
  read -r confirm
  if [ "$confirm" != "DESTROY" ]; then
    printf 'Aborted.\n' >&2
    return 1
  fi

  # Zero out file nodes prior to system link unlinking (Termux/BSD/Linux safe)
  if command -v shred >/dev/null 2>&1; then
    shred -u -n 3 "$_VAULT_FILE" "$_VAULT_REC_FILE" "$_VAULT_DAT_FILE" 2>/dev/null || true
  else
    # Fallback to zero-filling dd operations if shred is absent
    [ -f "$_VAULT_FILE" ] && dd if=/dev/zero of="$_VAULT_FILE" bs=1024 count=10 conv=notrunc 2>/dev/null || true
    [ -f "$_VAULT_REC_FILE" ] && dd if=/dev/zero of="$_VAULT_REC_FILE" bs=1024 count=10 conv=notrunc 2>/dev/null || true
    [ -f "$_VAULT_DAT_FILE" ] && dd if=/dev/zero of="$_VAULT_DAT_FILE" bs=1024 count=10 conv=notrunc 2>/dev/null || true
  fi

  rm -f -- "$_VAULT_FILE" "$_VAULT_REC_FILE" "$_VAULT_DAT_FILE" 2>/dev/null || true
  printf '\nVault successfully destroyed. All saved configurations have been wiped.\n' >&2
  return 0
}

# Decrypt Vault Key using Recovery Key and set a new Master Password
vault_recover() {
  local rec_key="" vault_key="" pass1="" pass2=""

  if [ ! -f "$_VAULT_REC_FILE" ]; then
    printf 'Error: Recovery database keys.rec is missing. System unrecoverable.\n' >&2
    return 1
  fi

  printf '\n=== KEY VAULT PASSCODE RECOVERY ===\n' >&2
  printf 'Enter your offline Recovery Key:\n> ' >&2
  
  read -r rec_key
  rec_key="$(trim_space "$rec_key")"

  # Decrypt Vault Key using the offline Recovery Key
  vault_key="$(_vault_decrypt_file "$_VAULT_REC_FILE" "$rec_key")"
  if [ -z "$vault_key" ]; then
    printf '%bError: Invalid Recovery Key or database corruption.%b\n' "${C_RED:-}" "${C_RST:-}" >&2
    return 1
  fi

  printf '\n%bRecovery authorization successful!%b\n' "${C_BGREEN:-}" "${C_RST:-}" >&2
  printf 'Define a new Master Password to restore standard vault operations.\n' >&2

  while :; do
    pass1="$(_vault_read_password "Enter NEW Master Password (min 8 chars): ")"
    if [ ${#pass1} -lt 8 ]; then
      printf 'Error: Password must be at least 8 characters long.\n' >&2
      continue
    fi
    pass2="$(_vault_read_password "Confirm NEW Master Password: ")"
    if [ "$pass1" != "$pass2" ]; then
      printf 'Error: Passwords do not match. Try again.\n' >&2
    else
      break
    fi
  done

  # Re-encrypt Vault Key with new Master Password -> keys.enc
  if ! _vault_encrypt_to_file "$vault_key" "$_VAULT_FILE" "$pass1"; then
    printf 'Error: Failed to write recovered database files.\n' >&2
    return 1
  fi

  printf 'Access recovered successfully. Master Password restored.\n' >&2
  return 0
}

# Manage API key mappings (Add, Modify, and Delete keys)
vault_manage_keys() {
  local current_payload="" master_pass="" vault_key="" choice="" prov="" key_val="" updated_payload="" keys=""

  if ! vault_exists; then
    vault_init || return 1
  fi

  master_pass="$(_vault_read_password "Enter Master Password to access Key Manager: ")"
  
  # Decrypt internal Vault Key
  vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$master_pass")"
  if [ -z "$vault_key" ]; then
    printf 'Access Denied: Incorrect Master Password.\n' >&2
    return 1
  fi

  # Decrypt payload JSON database using Vault Key
  current_payload="$(_vault_decrypt_file "$_VAULT_DAT_FILE" "$vault_key")"
  if [ -z "$current_payload" ]; then
    printf 'Error: Failed to decrypt database payload.\n' >&2
    return 1
  fi

  while :; do
    printf '\n=== KEY VAULT OPERATIONS ===\n' >&2
    printf '1) List Configured Providers\n' >&2
    printf '2) Add / Update Provider API Key\n' >&2
    printf '3) Delete Provider API Key\n' >&2
    printf '4) Return to Security Console\n' >&2
    printf 'Choice: ' >&2
    
    read -r choice
    
    case "$choice" in
      1)
        printf '\n--- CONFIGURED PROVIDERS ---\n' >&2
        # Use line-buffered read redirection to process keys safely, preventing word splitting
        while IFS= read -r k; do
          [ -n "$k" ] && printf '  - %s: [SECURED CARD SAVED]\n' "$k" >&2
        done < <(printf '%s' "$current_payload" | jq -r 'keys[]' 2>/dev/null)
        ;;
      2)
        printf '\nEnter Provider Name (e.g., groq, gemini, huggingface):\n> ' >&2
        
        read -r prov
        prov="$(trim_space "$prov" | tr '[:upper:]' '[:lower:]')"
        [ -n "$prov" ] || continue

        printf 'Enter API Key for %s:\n> ' "$prov" >&2
        
        read -r key_val
        key_val="$(trim_space "$key_val")"
        [ -n "$key_val" ] || continue

        # Transactional verification: validate updated payload before writing to disk
        updated_payload="$(printf '%s' "$current_payload" | jq --arg p "$prov" --arg k "$key_val" '.[$p] = $k' 2>/dev/null || true)"
        
        if [ -n "$updated_payload" ] && printf '%s' "$updated_payload" | jq -e . >/dev/null 2>&1; then
          current_payload="$updated_payload"
          # Update dat file using the immutable Vault Key with write integrity check
          if _vault_encrypt_to_file "$current_payload" "$_VAULT_DAT_FILE" "$vault_key"; then
            printf 'Key for "%s" saved securely.\n' "$prov" >&2
          else
            printf 'Error: Failed to write database update. Keys not saved.\n' >&2
          fi
        else
          printf 'Error: Internal database formatting failed. Operation aborted.\n' >&2
        fi
        ;;
      3)
        printf '\nEnter Provider Name to remove:\n> ' >&2
        
        read -r prov
        prov="$(trim_space "$prov" | tr '[:upper:]' '[:lower:]')"
        [ -n "$prov" ] || continue

        # Transactional verification: validate updated payload before writing to disk
        updated_payload="$(printf '%s' "$current_payload" | jq --arg p "$prov" 'del(.[$p])' 2>/dev/null || true)"
        
        if [ -n "$updated_payload" ] && printf '%s' "$updated_payload" | jq -e . >/dev/null 2>&1; then
          current_payload="$updated_payload"
          # Update dat file using the immutable Vault Key with write integrity check
          if _vault_encrypt_to_file "$current_payload" "$_VAULT_DAT_FILE" "$vault_key"; then
            printf 'Key for "%s" deleted.\n' "$prov" >&2
          else
            printf 'Error: Failed to save changes to database. Deletion aborted.\n' >&2
          fi
        else
          printf 'Error: Internal database formatting failed. Operation aborted.\n' >&2
        fi
        ;;
      4)
        break
        ;;
      *)
        printf 'Invalid selection.\n' >&2
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
  while :; do
    printf '\n=== SECURITY & ENCRYPTION CONSOLE ===\n' >&2
    printf '1) Access Key Vault Manager\n' >&2
    printf '2) Change Master Password\n' >&2
    printf '3) Emergency Access Recovery (Forgotten Password)\n' >&2
    printf '4) WIPE Vault (Destroy all credentials)\n' >&2
    printf '5) Close Console\n' >&2
    printf 'Choice: ' >&2
    local choice=""
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
        printf 'Invalid selection.\n' >&2 
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
  local target_host="" t_cmd=""

  if [ -z "$url" ]; then 
    return 1
  fi

  target_host="$(printf '%s' "$url" | sed -E 's#https?://([^:/]+).*#\1#')"

  if command -v timeout >/dev/null 2>&1; then 
    t_cmd="timeout 5"
  fi

  if $t_cmd openssl s_client -connect "${target_host}:443" -servername "$target_host" </dev/null >/dev/null 2>&1; then
    return 0
  else
    return 2
  fi
}
