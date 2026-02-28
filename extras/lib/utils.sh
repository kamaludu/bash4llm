#!/usr/bin/env bash
# =============================================================================
# GroqBash — Bash-first utilities (extras/lib/utils.sh)
# Purpose: small, portable helper functions for groqbash extras
# Location at runtime: groqbash.d/extras/lib/utils.sh
# =============================================================================
# Load guard (exact, valid POSIX/Bash form)
if [ -n "${GROQBASHUTILSLOADED:-}" ]; then
  return 0
fi
GROQBASHUTILSLOADED=1

# No side effects on source: only function definitions and the load guard above.

# gb_trim: trim leading and trailing whitespace
# Usage: gb_trim "  text  "    OR    printf '  text  ' | gb_trim
gb_trim() {
  local input
  if [ $# -gt 0 ]; then
    input="$1"
  else
    # read from stdin
    IFS= read -r input || input=''
  fi
  # Use awk for portability and correctness
  printf '%s' "$input" | awk '{ sub(/^[ \t\r\n]+/, ""); sub(/[ \t\r\n]+$/, ""); print }'
}

# gb_is_number: return 0 if argument is a valid integer or decimal, else 1
# Accepts optional leading + or - and decimal point. No output on success.
# Usage: gb_is_number "3.14" && echo ok || echo not
gb_is_number() {
  local v="$1"
  # Empty string is not a number
  [ -z "$v" ] && return 1
  # Use grep -E with a strict numeric regex (portable)
  # Regex: optional sign, digits with optional fractional part OR fractional starting with dot
  printf '%s' "$v" | grep -E -q '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
  return $?
}

# gb_join: join arguments with separator (first arg is separator)
# Usage: gb_join "," "a" "b" "c"  -> outputs: a,b,c
gb_join() {
  local sep="$1"
  shift || true
  local out=""
  local first=1
  local v
  for v in "$@"; do
    if [ "$first" -eq 1 ]; then
      out="$v"
      first=0
    else
      out="${out}${sep}${v}"
    fi
  done
  printf '%s' "$out"
}

# gb_mktempfile: create a secure temp file
# Usage: tmpf="$(gb_mktempfile "prefix")"
# Prints the filename to stdout or empty string on failure.
gb_mktempfile() {
  local prefix="${1:-tmp}"
  local tmpf=""
  # Prefer GROQBASH_TMPDIR if set and writable
  if [ -n "${GROQBASH_TMPDIR:-}" ] && [ -d "${GROQBASH_TMPDIR}" ] && [ -w "${GROQBASH_TMPDIR}" ]; then
    # Try mktemp -p (GNU, BusyBox). If not supported, fall back to mktemp -t (macOS).
    if mktemp -p "${GROQBASH_TMPDIR}" "${prefix}.XXXX" >/dev/null 2>/dev/null; then
      tmpf="$(mktemp -p "${GROQBASH_TMPDIR}" "${prefix}.XXXX" 2>/dev/null || true)"
    else
      # macOS style: mktemp -t prefix
      if mktemp -t "${prefix}" >/dev/null 2>/dev/null; then
        tmpf="$(mktemp -t "${prefix}" 2>/dev/null || true)"
        # Attempt to move into GROQBASH_TMPDIR if possible
        if [ -n "$tmpf" ] && [ -w "${GROQBASH_TMPDIR}" ]; then
          local base
          base="$(basename "$tmpf")"
          mv -f -- "$tmpf" "${GROQBASH_TMPDIR}/${base}" 2>/dev/null || true
          tmpf="${GROQBASH_TMPDIR}/${base}"
        fi
      fi
    fi
  fi

  # Fallback to system mktemp without -p
  if [ -z "$tmpf" ]; then
    if mktemp "${prefix}.XXXX" >/dev/null 2>/dev/null; then
      tmpf="$(mktemp "${prefix}.XXXX" 2>/dev/null || true)"
    fi
  fi

  # Ensure file exists and has safe perms
  if [ -n "$tmpf" ]; then
    chmod 600 "$tmpf" 2>/dev/null || true
    printf '%s' "$tmpf"
    return 0
  fi

  # Failure: print empty string and return non-zero
  printf ''
  return 1
}

# gb_debug: controlled debug printing to stderr
# Usage: gb_debug "message" or gb_debug "fmt %s" "arg"
gb_debug() {
  # Print only if DEBUG is set and non-empty
  if [ -z "${DEBUG:-}" ]; then
    return 0
  fi
  if [ $# -eq 0 ]; then
    return 0
  fi
  # Print to stderr with prefix
  printf '[gb-debug] %s\n' "$(printf "$@")" >&2
}

# gb_ensure_tmpdir: ensure GROQBASH_TMPDIR exists and is writable (optional helper)
# Usage: gb_ensure_tmpdir && echo ok || echo fail
gb_ensure_tmpdir() {
  if [ -z "${GROQBASH_TMPDIR:-}" ]; then
    return 1
  fi
  if [ -d "${GROQBASH_TMPDIR}" ]; then
    [ -w "${GROQBASH_TMPDIR}" ] || return 1
    return 0
  fi
  mkdir -p "${GROQBASH_TMPDIR}" 2>/dev/null || return 1
  chmod 700 "${GROQBASH_TMPDIR}" 2>/dev/null || true
  return 0
}

# End of extras/lib/utils.sh
