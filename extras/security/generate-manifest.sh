#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/security/generate-manifest.sh
# Component: Official Extras Manifest Generator & Ed25519 Signer
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================

set -euo pipefail
umask 077

SCRIPT_NAME="generate-manifest.sh"
SCRIPT_VERSION="1.1.5"
SCRIPT_DATE="2026-08-15"

# --------------------------------------------------
# Pre-parse arguments for early flags
# --------------------------------------------------
if [ "$#" -gt 0 ]; then
  for _arg in "$@"; do
    if [ "$_arg" = "--no-color" ]; then
      export NO_COLOR=1
    fi
  done
  unset _arg
fi

# --------------------------------------------------
# Terminal Color Theme Initialization (conforms to NO_COLOR standard)
# --------------------------------------------------
if { [ -t 1 ] || [ -t 2 ]; } && [ "${TERM:-}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
  C_RST=$'\e[0m'
  C_BOLD=$'\e[1m'
  C_NOBOLD=$'\e[22m'

  # Foreground - Normal
  C_BLACK=$'\e[0;30m'
  C_RED=$'\e[0;31m'
  C_GREEN=$'\e[0;32m'
  C_YELLOW=$'\e[0;33m'
  C_BLUE=$'\e[0;34m'
  C_MAGENTA=$'\e[0;35m'
  C_CYAN=$'\e[0;36m'
  C_WHITE=$'\e[0;37m'

  # Foreground - Bold
  C_BBLACK=$'\e[1;30m'
  C_BRED=$'\e[1;31m'
  C_BGREEN=$'\e[1;32m'
  C_BYELLOW=$'\e[1;33m'
  C_BBLUE=$'\e[1;34m'
  C_BMAGENTA=$'\e[1;35m'
  C_BCYAN=$'\e[1;36m'
  C_BWHITE=$'\e[1;37m'
else
  C_RST="" C_BOLD="" C_NOBOLD=""
  C_BLACK="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_MAGENTA="" C_CYAN="" C_WHITE=""
  C_BBLACK="" C_BRED="" C_BGREEN="" C_BYELLOW="" C_BBLUE="" C_BMAGENTA="" C_BCYAN="" C_BWHITE=""
fi

# --------------------------------------------------
# Logging Functions (All diagnostic outputs directed to stderr)
# --------------------------------------------------
log_prefix() { printf '%s: ' "$SCRIPT_NAME"; }

log_info() {
  printf '%s%sINFO%s: %s\n' "$(log_prefix)" "${C_GREEN}" "${C_RST}" "$*" >&2
}

log_warn() {
  printf '%s%sWARN%s: %s\n' "$(log_prefix)" "${C_BYELLOW}" "${C_RST}" "$*" >&2
}

log_error() {
  printf '%s%sERROR%s: %s\n' "$(log_prefix)" "${C_RED}" "${C_RST}" "$*" >&2
}

show_help() {
  cat <<EOF
${C_BOLD}Bash4LLM⁺ Manifest Generator and Ed25519 Signer${C_RST}

${C_BCYAN}Usage:${C_RST}
  generate-manifest.sh [options]

${C_BCYAN}Options:${C_RST}
  ${C_BGREEN}--extras-dir <dir>${C_RST}            Path to extras directory (default: auto-detect)
  ${C_BGREEN}--key <file>${C_RST}                  Path to Ed25519 private key file (default: ./extras-private-key.pem)
  ${C_BGREEN}--generate-key${C_RST}                Generate a new Ed25519 key pair if missing
  ${C_BGREEN}--no-sign-if-missing-key${C_RST}      Do not fail if private key is missing; update SHA-256 manifest only
  ${C_BGREEN}--no-color${C_RST}                    Disable ANSI color outputs
  ${C_BGREEN}--version${C_RST}                     Show version information
  ${C_BGREEN}-h, --help${C_RST}                    Show this help message

${C_BCYAN}Examples:${C_RST}
  ./generate-manifest.sh --generate-key
  ./generate-manifest.sh --key /path/to/private.pem --extras-dir ./bash4llm.d/extras
EOF
}

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

# Intelligent auto-detection of extras directory
if [ -d "${SCRIPT_DIR}/providers" ] || [ -f "${SCRIPT_DIR}/manifest.sha256" ]; then
  EXTRAS_DIR="$SCRIPT_DIR"
elif [ -d "${SCRIPT_DIR}/../providers" ] || [ -f "${SCRIPT_DIR}/../manifest.sha256" ]; then
  EXTRAS_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
else
  EXTRAS_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
fi

KEY_FILE="${SCRIPT_DIR}/extras-private-key.pem"
GENERATE_KEY=0
ALLOW_MISSING_KEY=0
err_out=""

# Parse command line options
while [ $# -gt 0 ]; do
  case "$1" in
    --no-color)
      shift
      ;;
    --extras-dir)
      if [ -n "${2:-}" ] && [ "${2:0:1}" != "-" ] && [ -d "$2" ]; then
        EXTRAS_DIR="$(cd "$2" >/dev/null 2>&1 && pwd -P)"
        shift 2
      else
        log_error "Option --extras-dir requires a valid directory argument"
        exit 1
      fi
      ;;
    --extras-dir=*)
      val="${1#--extras-dir=}"
      if [ -n "$val" ] && [ -d "$val" ]; then
        EXTRAS_DIR="$(cd "$val" >/dev/null 2>&1 && pwd -P)"
        shift
      else
        log_error "Option --extras-dir requires a valid directory argument"
        exit 1
      fi
      ;;
    --key)
      if [ -n "${2:-}" ] && [ "${2:0:1}" != "-" ]; then
        KEY_FILE="$2"
        shift 2
      else
        log_error "Option --key requires a private key file path"
        exit 1
      fi
      ;;
    --key=*)
      val="${1#--key=}"
      if [ -n "$val" ]; then
        KEY_FILE="$val"
        shift
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
    --version)
      printf '%s %s (%s)\n' "$SCRIPT_NAME" "$SCRIPT_VERSION" "$SCRIPT_DATE"
      exit 0
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

unset val 2>/dev/null || true

# Normalize KEY_FILE to absolute path if parent directory exists
if [ -d "$(dirname "$KEY_FILE")" ]; then
  KEY_FILE="$(cd "$(dirname "$KEY_FILE")" >/dev/null 2>&1 && pwd -P)/$(basename "$KEY_FILE")"
fi

_compute_sha256() {
  local target="$1"
  [ -f "$target" ] || return 1

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target" 2>/dev/null | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 -r "$target" 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$target" 2>/dev/null | awk '{print $1}'
  else
    log_error "No SHA-256 utility (sha256sum, openssl, shasum) found in PATH"
    return 1
  fi
}

PUBKEY_FILE="${EXTRAS_DIR}/official-ed25519.pub"

# Key generation if requested or needed
if [ "$GENERATE_KEY" -eq 1 ] && [ ! -f "$KEY_FILE" ]; then
  if command -v openssl >/dev/null 2>&1; then
    log_info "Generating new Ed25519 key pair..."
    mkdir -p "$(dirname "$KEY_FILE")"
    err_out="$(openssl genpkey -algorithm Ed25519 -out "$KEY_FILE" 2>&1)" || {
      log_error "Failed to generate private key: ${err_out:-unknown error}"
      exit 1
    }
    chmod 600 "$KEY_FILE"
    err_out="$(openssl pkey -in "$KEY_FILE" -pubout -out "$PUBKEY_FILE" 2>&1)" || {
      log_error "Failed to export public key: ${err_out:-unknown error}"
      exit 1
    }
    chmod 600 "$PUBKEY_FILE"
    log_info "Ed25519 Private Key saved to: ${C_CYAN}$KEY_FILE${C_RST}"
    log_info "Ed25519 Public Key saved to: ${C_CYAN}$PUBKEY_FILE${C_RST}"
  else
    log_error "OpenSSL is required to generate Ed25519 key pair"
    exit 1
  fi
fi

MANIFEST_FILE="${EXTRAS_DIR}/manifest.sha256"
SIG_FILE="${EXTRAS_DIR}/manifest.sha256.sig"

log_info "Scanning extras directory: ${C_CYAN}${EXTRAS_DIR}${C_RST}"

TMP_MANIFEST="$(mktemp "${EXTRAS_DIR}/manifest.tmp.XXXXXX")"
chmod 600 "$TMP_MANIFEST"

# Trap handler ensuring immediate cleanup of temporary file upon exit/signal
_manifest_cleanup() {
  if [ -n "${TMP_MANIFEST:-}" ] && [ -f "$TMP_MANIFEST" ]; then
    rm -f "$TMP_MANIFEST" 2>/dev/null || true
  fi
}
trap '_manifest_cleanup' EXIT INT TERM

{
  printf '# Bash4LLM Extras Integrity Manifest (SHA-256)\n'
  printf '# Format: <sha256_hash>  <relative_path_from_extras_dir>\n'
  printf '# Official release modules integrity verification table\n\n'
} > "$TMP_MANIFEST"

# Collect file list deterministically using null-byte delimiters
(
  cd "$EXTRAS_DIR"
  find . -type f -print0 | while IFS= read -r -d '' f; do
    rel="${f#./}"
    case "$rel" in
      .*|*/.*|*manifest.sha256*|*.sig|*official-ed25519.pub|*.pub|*.pem|*.key|tools/*|*/tools/*|*generate-manifest.sh|*.tmp*|*.b64|*.swp|*~|*.bak|*.orig)
        continue
        ;;
    esac
    if ! hash="$(_compute_sha256 "$f")" || [ -z "$hash" ]; then
      log_error "Failed to compute SHA-256 for file: $f"
      exit 1
    fi
    printf '%s  %s\n' "$hash" "$rel"
  done | LC_ALL=C sort -k2
) >> "$TMP_MANIFEST"

entry_count="$(grep -vE '^[[:space:]]*#' "$TMP_MANIFEST" | grep -vE '^[[:space:]]*$' | wc -l | tr -d ' ')"

if [ "${entry_count:-0}" -eq 0 ]; then
  log_error "No valid files found to register in manifest (directory is empty or all files are excluded)"
  exit 1
fi

mv -f "$TMP_MANIFEST" "$MANIFEST_FILE"
chmod 600 "$MANIFEST_FILE"
TMP_MANIFEST=""

log_info "Generated manifest.sha256 with ${C_BGREEN}${entry_count}${C_RST} registered entries"

# Signature phase
if [ ! -f "$KEY_FILE" ]; then
  if [ "$ALLOW_MISSING_KEY" -eq 1 ]; then
    log_warn "Private key missing at $KEY_FILE. Skipping Ed25519 signature (--no-sign-if-missing-key active)."
    exit 0
  else
    log_error "Private key file not found at: $KEY_FILE"
    log_error "
Use:
  ${C_BGREEN}--generate-key${C_RST}

or pass:
  ${C_BGREEN}--no-sign-if-missing-key${C_RST}"
    exit 1
  fi
fi

if ! command -v openssl >/dev/null 2>&1; then
  log_error "OpenSSL is required to perform Ed25519 signing"
  exit 1
fi

log_info "Signing manifest using Ed25519 private key..."
err_out="$(openssl pkeyutl -sign -inkey "$KEY_FILE" -rawin -in "$MANIFEST_FILE" -out "$SIG_FILE" 2>&1)" || {
  log_error "OpenSSL signing failed: ${err_out:-unknown error}"
  exit 1
}
chmod 600 "$SIG_FILE"

log_info "Generated signature: ${C_CYAN}${SIG_FILE}${C_RST}"

# Ensure official public key is synchronized and matches active private key
err_out="$(openssl pkey -in "$KEY_FILE" -pubout -out "$PUBKEY_FILE" 2>&1)" || {
  log_error "Failed to synchronize public key: ${err_out:-unknown error}"
  exit 1
}
chmod 600 "$PUBKEY_FILE"

# Verification self-test check
if [ -f "$PUBKEY_FILE" ]; then
  if err_out="$(openssl pkeyutl -verify -pubin -inkey "$PUBKEY_FILE" -rawin -in "$MANIFEST_FILE" -sigfile "$SIG_FILE" 2>&1)"; then
    log_info "${C_BGREEN}SUCCESS:${C_RST} Manifest successfully generated and cryptographically verified!"
  else
    log_error "${C_BRED}SELF-TEST FAILED:${C_RST} Signature verification check failed!"
    [ -n "$err_out" ] && log_error "OpenSSL details: $err_out"
    exit 1
  fi
fi

exit 0
