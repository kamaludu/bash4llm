#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/gui-py/config.py
# Component: Configuration Subsystem for bash4llm⁺ GUI Adapter
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================

import os
from dataclasses import dataclass, field
from typing import Optional


def _resolve_default_bash4llm_dir() -> str:
    """
    Risolve la directory di runtime bash4llm.d distinguendo:
    1. Modalità installata: <root>/bash4llm.d/extras/gui-py (sale di 2 livelli ed è già in bash4llm.d)
    2. Modalità sorgente: <root>/extras/gui-py (sale di 2 livelli alla radice e aggiunge bash4llm.d)
    """
    env_dir = os.environ.get("BASH4LLM_DIR")
    if env_dir:
        return os.path.abspath(env_dir)

    current_dir = os.path.dirname(os.path.abspath(__file__))
    two_up = os.path.abspath(os.path.join(current_dir, "..", ".."))

    if os.path.basename(two_up) == "bash4llm.d" and os.path.isdir(two_up):
        return two_up

    return os.path.abspath(os.path.join(two_up, "bash4llm.d"))


@dataclass
class Config:
    """
    Runtime configuration settings derived from environment variables
    and canonical bash4llm directory paths (Closed-World Data Policy).
    """
    script_dir: str = field(default_factory=lambda: os.path.dirname(os.path.abspath(__file__)))
    
    # Session-only RAM Vault Context Token (_B4L_RT_CTX)
    vault_session_context: Optional[str] = None
    
    # BASH4LLM Canonical Directory Paths
    BASH4LLM_DIR: str = field(default_factory=_resolve_default_bash4llm_dir)
    
    BASH4LLM_TMPDIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_TMPDIR",
        os.path.join(_resolve_default_bash4llm_dir(), "tmp")
    ))
    
    BASH4LLM_CONFIG_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_CONFIG_DIR",
        os.path.join(_resolve_default_bash4llm_dir(), "config")
    ))
    
    BASH4LLM_HISTORY_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_HISTORY_DIR",
        os.path.join(_resolve_default_bash4llm_dir(), "history")
    ))
    
    BASH4LLM_RUN_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_RUN_DIR",
        os.path.join(_resolve_default_bash4llm_dir(), "var", "run")
    ))

    BASH4LLM_EXTRAS_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_EXTRAS_DIR",
        os.path.join(_resolve_default_bash4llm_dir(), "extras")
    ))

    BASH4LLM_TEMPLATES_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_TEMPLATES_DIR",
        os.path.join(_resolve_default_bash4llm_dir(), "templates")
    ))

    @property
    def core_script_path(self) -> str:
        """
        Returns the authoritative canonical path to the bash4llm core script.
        Adheres strictly to Closed-World Data and Fail-Fast policies without probing loops.
        """
        env_core = os.environ.get("BASH4LLM_CORE_SCRIPT")
        if env_core and os.path.isfile(env_core):
            return env_core
        
        # 1. Fallback per runtime installato (3 livelli: bash4llm.d/extras/gui-py/ -> ../../../bash4llm)
        path_3_up = os.path.abspath(os.path.join(self.script_dir, "..", "..", "..", "bash4llm"))
        if os.path.isfile(path_3_up):
            return path_3_up

        # 2. Fallback per sorgente repository (2 livelli: extras/gui-py/ -> ../../bash4llm)
        path_2_up = os.path.abspath(os.path.join(self.script_dir, "..", "..", "bash4llm"))
        if os.path.isfile(path_2_up):
            return path_2_up
        
        raise FileNotFoundError(
            f"Core script bash4llm not found at canonical locations: {path_3_up} or {path_2_up}"
        )
