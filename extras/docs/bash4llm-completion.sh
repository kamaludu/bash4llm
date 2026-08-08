#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/docs/bash4llm-completion.sh
# Component: Native Shell Autocompletion Module
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Requirements: bash 4.0+
# Security Constraints: No eval, no system /tmp, no side effects
# =============================================================================

_bash4llm_completions() {
    local cur prev words cword
    
    # Standard completion initialization with native fallback for Bash 4.0+
    if declare -f _init_completion >/dev/null 2>&1; then
        _init_completion -n = || return
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi

    # Static list of all supported options in bash4llm
    local opts=(
        --no-color
        --init-thread
        --delete-thread
        --rename-thread
        --title
        --refresh-models
        --list-models
        --list-providers
        --list-providers-raw
        --list-models-raw
        --set-default
        -m
        --model
        -f
        --json-input
        --template
        --batch
        --thread
        --thread-window
        --system
        --ture
        --temperature
        --max
        --debug
        --save
        --nosave
        --out
        --threshold
        --dry-run
        --quiet
        --stream
        --no-stream
        --json
        --pretty
        --text
        --raw
        --chat
        --tui
        --show-config
        --diagnostics
        --diagnostic
        --test
        --run-all-tests
        --provider
        --providers
        --install-extras
        --install-extra
        --vault
        --version
        -h
        --help
        --bootstrap-only
        --validate-sml
        --validate-regex
        --sanitize
        --json-diagnostics
        --check-config
        --explain-error
        --print-config-dir
        --print-provider-file
        --print-model-file
    )

    # Detect active provider if specified earlier in the command line
    local active_provider=""
    local i
    for ((i = 0; i < cword; i++)); do
        case "${words[i]}" in
            --provider|--providers)
                if (( i + 1 < cword )); then
                    active_provider="${words[i+1]}"
                fi
                ;;
            --provider=*)
                active_provider="${words[i]#*=}"
                ;;
        esac
    done

    # Contextual completion based on the previous option
    case "$prev" in
        --provider|--providers)
            local providers=""
            # Query existing core raw listing flag without side-effects
            if command -v bash4llm >/dev/null 2>&1; then
                providers="$(bash4llm --list-providers-raw 2>/dev/null)"
            fi
            if [ -z "$providers" ]; then
                providers="groq"
            fi
            COMPREPLY=( $(compgen -W "$providers" -- "$cur") )
            return 0
            ;;
        -m|--model|--set-default|--print-model-file)
            local models=""
            # Query existing core raw listing flag with active provider context if available
            if command -v bash4llm >/dev/null 2>&1; then
                if [ -n "$active_provider" ]; then
                    models="$(bash4llm --provider "$active_provider" --list-models-raw 2>/dev/null)"
                else
                    models="$(bash4llm --list-models-raw 2>/dev/null)"
                fi
            fi
            if [ -n "$models" ]; then
                COMPREPLY=( $(compgen -W "$models" -- "$cur") )
                return 0
            fi
            ;;
        --explain-error)
            local error_codes="10 11 12 13 14 15 16 17 BASH4LLM_ERR_NO_API_KEY BASH4LLM_ERR_BAD_MODEL BASH4LLM_ERR_CURL_FAILED BASH4LLM_ERR_PARSE BASH4LLM_ERR_NO_PROMPT BASH4LLM_ERR_TMP BASH4LLM_ERR_API BASH4LLM_ERR_SEC"
            COMPREPLY=( $(compgen -W "$error_codes" -- "$cur") )
            return 0
            ;;
        -f|--batch|--out)
            # File completion for input, output, or batch files
            if declare -f _filedir >/dev/null 2>&1; then
                _filedir
            else
                COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            return 0
            ;;
        --format)
            COMPREPLY=( $(compgen -W "text raw json pretty" -- "$cur") )
            return 0
            ;;
        --thread|--delete-thread|--rename-thread|--title|--system|--json-input|--template|--temperature|--ture|--max|--threshold|--validate-regex)
            # Options requiring freeform user input
            return 0
            ;;
    esac

    # Handle completion for option arguments formatted with '=' (e.g. --print-model-file=...)
    if [[ "$cur" == --*=* ]]; then
        local opt="${cur%%=*}"
        local val="${cur#*=}"
        case "$opt" in
            --print-model-file|--provider)
                local providers=""
                if command -v bash4llm >/dev/null 2>&1; then
                    providers="$(bash4llm --list-providers-raw 2>/dev/null)"
                fi
                [ -z "$providers" ] && providers="groq"
                local matches
                matches=$(compgen -W "$providers" -- "$val")
                COMPREPLY=( $(for m in $matches; do printf '%s=%s\n' "$opt" "$m"; done) )
                return 0
                ;;
        esac
    fi

    # Option completion when typing flags starting with '-' or '--'
    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "${opts[*]}" -- "$cur") )
        return 0
    fi

    # Fallback file completion for positional arguments
    if declare -f _filedir >/dev/null 2>&1; then
        _filedir
    else
        COMPREPLY=( $(compgen -f -- "$cur") )
    fi
}

# Register completion function strictly for the bash4llm command
complete -F _bash4llm_completions bash4llm
