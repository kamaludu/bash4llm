#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/gui-py/gui-py.sh
# Component: GUI WebApp Launcher Wrapper for bash4llm⁺
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================
# Security Level: T3 Hardened | POSIX compliant wrapper

set -euo pipefail

# Environment Sanitization
unset BASH_ENV ENV CDPATH GLOBIGNORE

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Dynamic Core Script Path Resolution (Supports both repo and installed paths)
if [ -f "${SCRIPT_DIR}/../../bash4llm" ]; then
  CORE_SCRIPT="${SCRIPT_DIR}/../../bash4llm"
elif [ -f "${SCRIPT_DIR}/../../../bash4llm" ]; then
  CORE_SCRIPT="${SCRIPT_DIR}/../../../bash4llm"
elif command -v bash4llm >/dev/null 2>&1; then
  CORE_SCRIPT="$(command -v bash4llm)"
else
  printf 'bash4llm-gui: FATAL ERROR: Core script bash4llm not found.\n' >&2
  exit 15
fi
export BASH4LLM_CORE_SCRIPT="${CORE_SCRIPT}"

# 1. Python Interpreter Presence Check
if ! command -v python3 >/dev/null 2>&1; then
  printf 'bash4llm-gui: FATAL ERROR: python3 is not installed or not available in PATH.\n' >&2
  printf 'Please install Python 3.10 or higher using your platform package manager.\n' >&2
  exit 15
fi

# 2. Python Version Check (>= 3.10 via native Python tuple comparison)
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
  PYTHON_VER="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "unknown")"
  printf 'bash4llm-gui: FATAL ERROR: Python 3.10 or superior is required (found %s).\n' "$PYTHON_VER" >&2
  exit 15
fi

# 3. Check Required Python Dependencies - ZERO AUTOMATISMS POLICY
MISSING_DEPS=""
python3 -c "import fastapi" 2>/dev/null || MISSING_DEPS="${MISSING_DEPS} fastapi"
python3 -c "import uvicorn" 2>/dev/null || MISSING_DEPS="${MISSING_DEPS} uvicorn"
python3 -c "import pydantic" 2>/dev/null || MISSING_DEPS="${MISSING_DEPS} pydantic"

if [ -n "$MISSING_DEPS" ]; then
  printf 'bash4llm-gui: FATAL ERROR: Missing required Python dependencies:%s\n' "$MISSING_DEPS" >&2
  printf 'Automatic package installation is strictly prohibited by security policy.\n' >&2
  printf 'Please install missing dependencies manually using your system package manager or pip:\n' >&2
  printf '    python3 -m pip install%s\n' "$MISSING_DEPS" >&2
  exit 15
fi

# 4. Delegate Execution to Python Adapter Entrypoint
exec python3 "${SCRIPT_DIR}/main.py" "$@"
