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
    BASH4LLM_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_DIR", 
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
    ))
    
    BASH4LLM_TMPDIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_TMPDIR",
        os.path.join(
            os.environ.get(
                "BASH4LLM_DIR", 
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
            ), 
            "tmp"
        )
    ))
    
    BASH4LLM_CONFIG_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_CONFIG_DIR",
        os.path.join(
            os.environ.get(
                "BASH4LLM_DIR", 
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
            ), 
            "config"
        )
    ))
    
    BASH4LLM_HISTORY_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_HISTORY_DIR",
        os.path.join(
            os.environ.get(
                "BASH4LLM_DIR", 
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
            ), 
            "history"
        )
    ))
    
    BASH4LLM_RUN_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_RUN_DIR",
        os.path.join(
            os.environ.get(
                "BASH4LLM_DIR", 
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
            ), 
            "var", "run"
        )
    ))

    BASH4LLM_EXTRAS_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_EXTRAS_DIR",
        os.path.join(
            os.environ.get(
                "BASH4LLM_DIR", 
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
            ), 
            "extras"
        )
    ))

    BASH4LLM_TEMPLATES_DIR: str = field(default_factory=lambda: os.environ.get(
        "BASH4LLM_TEMPLATES_DIR",
        os.path.join(
            os.environ.get(
                "BASH4LLM_DIR", 
                os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "bash4llm.d"))
            ), 
            "templates"
        )
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
        
        canonical_path = os.path.abspath(os.path.join(self.script_dir, "..", "..", "bash4llm"))
        if os.path.isfile(canonical_path):
            return canonical_path
        
        raise FileNotFoundError(f"Core script bash4llm not found at canonical location: {canonical_path}")
