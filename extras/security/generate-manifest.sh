#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: generate-manifest.sh
# Component: Official Extras Manifest Generator & Ed25519 Signer
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================

set -euo pipefail

SCRIPT_NAME="generate-manifest.sh"
SCRIPT_VERSION="1.1.0"

log_prefix() { printf '%s: ' "$SCRIPT_NAME"; }
log_info() { printf '%sINFO: %s\n' "$(log_prefix)" "$*"; }
log_warn() { printf '%sWARN: %s\n' "$(log_prefix)" "$*" >&2; }
log_error() { printf '%sERROR: %s\n' "$(log_prefix)" "$*" >&2; }

show_help() {
  cat <<'EOF'
Bash4LLM⁺ Manifest Generator and Ed25519 Signer

Usage:
  generate-manifest.sh [options]

Options:
  --extras-dir <dir>            Path to extras directory (default: auto-detect)
  --key <file>                  Path to Ed25519 private key file (default: ./extras-private-key.pem)
  --generate-key                Generate a new Ed25519 key pair if missing
  --no-sign-if-missing-key      Do not fail if private key is missing; update SHA-256 manifest only
  -h, --help                    Show this help message

Examples:
  ./generate-manifest.sh --generate-key
  ./generate-manifest.sh --key /path/to/private.pem --extras-dir ./bash4llm.d/extras
EOF
}

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
EXTRAS_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
KEY_FILE="${SCRIPT_DIR}/extras-private-key.pem"
GENERATE_KEY=0
ALLOW_MISSING_KEY=0

# Parse command line options
while [ $# -gt 0 ]; do
  case "$1" in
    --extras-dir)
      if [ -n "${2:-}" ] && [ -d "$2" ]; then
        EXTRAS_DIR="$(cd "$2" >/dev/null 2>&1 && pwd -P)"
        shift 2
      else
        log_error "Option --extras-dir requires a valid directory argument"
        exit 1
      fi
      ;;
    --key)
      if [ -n "${2:-}" ]; then
        KEY_FILE="$2"
        shift 2
      else
        log_error "Option --key requires a private key file path"
        exit 1
      fi
      ;;
    --generate-key)
      GENERATE_KEY=1
      shift
      ;;
    --no-sign-if-missing-key)
      ALLOW_MISSING_KEY=1
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

_compute_sha256() {
  local target="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 -r "$target" | awk '{print $1}'
  else
    shasum -a 256 "$target" | awk '{print $1}'
  fi
}

PUBKEY_FILE="${EXTRAS_DIR}/official-ed25519.pub"

# Key generation if requested or needed
if [ "$GENERATE_KEY" -eq 1 ] && [ ! -f "$KEY_FILE" ]; then
  if command -v openssl >/dev/null 2>&1; then
    log_info "Generating new Ed25519 key pair..."
    mkdir -p "$(dirname "$KEY_FILE")"
    openssl genpkey -algorithm Ed25519 -out "$KEY_FILE" 2>/dev/null
    chmod 600 "$KEY_FILE"
    openssl pkey -in "$KEY_FILE" -pubout -out "$PUBKEY_FILE" 2>/dev/null
    chmod 600 "$PUBKEY_FILE"
    log_info "Ed25519 Private Key saved to: $KEY_FILE"
    log_info "Ed25519 Public Key saved to: $PUBKEY_FILE"
  else
    log_error "OpenSSL is required to generate Ed25519 key pair"
    exit 1
  fi
fi

MANIFEST_FILE="${EXTRAS_DIR}/manifest.sha256"
SIG_FILE="${EXTRAS_DIR}/manifest.sha256.sig"

log_info "Scanning extras directory: ${EXTRAS_DIR}"

TMP_MANIFEST="$(mktemp "${EXTRAS_DIR}/manifest.tmp.XXXXXX")"
chmod 600 "$TMP_MANIFEST"

{
  printf '# Bash4LLM Extras Integrity Manifest (SHA-256)\n'
  printf '# Format: <sha256_hash>  <relative_path_from_extras_dir>\n'
  printf '# Official release modules integrity verification table\n\n'
} > "$TMP_MANIFEST"

# Collect file list deterministically
(
  cd "$EXTRAS_DIR"
  find . -type f | while IFS= read -r f; do
    rel="${f#./}"
    case "$rel" in
      manifest.sha256*|official-ed25519.pub|*.pem|*.key|tools/*|.git*|*.tmp*|*.b64|.DS_Store)
        continue
        ;;
    esac
    hash="$(_compute_sha256 "$f")"
    printf '%s  %s\n' "$hash" "$rel"
  done | LC_ALL=C sort -k2,2
) >> "$TMP_MANIFEST"

if [ ! -s "$TMP_MANIFEST" ]; then
  log_error "No valid files found to register in manifest"
  rm -f "$TMP_MANIFEST"
  exit 1
fi

mv -f "$TMP_MANIFEST" "$MANIFEST_FILE"
chmod 600 "$MANIFEST_FILE"

entry_count="$(grep -vE '^[[:space:]]*#' "$MANIFEST_FILE" | grep -vE '^[[:space:]]*$' | wc -l | tr -d ' ')"
log_info "Generated manifest.sha256 with $entry_count registered entries"

# Signature phase
if [ ! -f "$KEY_FILE" ]; then
  if [ "$ALLOW_MISSING_KEY" -eq 1 ]; then
    log_warn "Private key missing at $KEY_FILE. Skipping Ed25519 signature (--no-sign-if-missing-key active)."
    exit 0
  else
    log_error "Private key file not found at: $KEY_FILE"
    log_error "Use --generate-key or pass --no-sign-if-missing-key"
    exit 1
  fi
fi

if ! command -v openssl >/dev/null 2>&1; then
  log_error "OpenSSL is required to perform Ed25519 signing"
  exit 1
fi

log_info "Signing manifest using Ed25519 private key..."
openssl pkeyutl -sign -inkey "$KEY_FILE" -rawin -in "$MANIFEST_FILE" -out "$SIG_FILE" 2>/dev/null
chmod 600 "$SIG_FILE"

log_info "Generated signature: ${SIG_FILE}"

# Verification check
if [ -f "$PUBKEY_FILE" ]; then
  if openssl pkeyutl -verify -pubin -inkey "$PUBKEY_FILE" -rawin -in "$MANIFEST_FILE" -sigfile "$SIG_FILE" >/dev/null 2>&1; then
    log_info "SUCCESS: Manifest successfully generated and cryptographically verified!"
  else
    log_error "SELF-TEST FAILED: Signature verification check failed!"
    exit 1
  fi
fi

exit 0
