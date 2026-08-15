[![Logo 320](../docs/img/bash4llm320.png "Logo bash4llm")](../README.md)

# Bash4llm Extras

[![Manifest Integrity & Auto-Update](https://github.com/kamaludu/bash4llm/actions/workflows/extras-integrity-manifest.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/extras-integrity-manifest.yml)
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?sort=semver&style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)

```text
extras/
├── chat/                     # Text User Interface (TUI) REPL & Translations
│   ├── langs/
│   │   ├── de.properties
│   │   ├── en.properties
│   │   ├── es.properties
│   │   ├── fr.properties
│   │   └── it.properties
│   ├── SPEC-TUI.md
│   └── tui-repl.sh           # Interactive TUI REPL CLI entrypoint (chmod 700)
├── docs/                     # Core Documentation & Reference Notes
│   ├── bash4llm-completion.sh  # Native Shell Autocompletion Module
│   ├── core-notes.sh
│   ├── help.txt
│   ├── manual-en.txt
│   └── manual-it.txt
├── gui-py/
│.  ├── gui-py.sh             # Launcher CLI Wrapper (POSIX Bash 4.0+, 0700)
│   ├── main.py               # Entrypoint Adapter Python 3.10+ (FastAPI + Uvicorn)
│   ├── config.py             # Dataclass, Runtime Settings, Temp Validation
│   ├── models.py             # Dataclass Job, State Enum, Termination Cause
│   ├── security.py           # Host/Origin Validation, Cookies, CSRF, Single-Instance Lock
│   ├── ipc.py                # Subprocess Executor, Pipe I/O, UTF-8 Decoder, SSE Dispatcher
│   ├── static/
│   │   ├── index.html        # Progressive Enhancement SPA HTML5
│   │   ├── help.html         # Help file
│   │   ├── error.html        # Error template HTTP 401/403/500 minimal
│   │   ├── style.css         # Design UI responsive zero-framework
│   │   └── app.js            # SSE Streamer, CSRF Fetch, Form Enhancements
│   └── langs/                # Multilingual translations 
│       ├── de.json
│       ├── en.json
│       ├── es.json
│       ├── fr.json
│       └── it.json
├── hooks/                    # Hooks 
│   └── sml-gate.sh.          # Structured Metadata Layout - Semantic Safety Gate
├── providers/                # Optional LLM Provider Extension Modules
│   ├── gemini.sh
│   ├── huggingface.md
│   ├── huggingface.sh
│   └── mistral.sh
├── security/                 # Active Security, Encryption & Output Sanitization
│   ├── OPENSSL-HELPER.md
│   ├── generate-manifest.sh. # Official Extras Manifest Generator & Ed25519 Signer
│   ├── openssl-helper.sh     # Encrypted OpenSSL Key Vault Engine (chmod 600, sourced)
│   └── output-sanitizer.sh   # Zero-Eval ANSI Filter & Output Sanitizer (chmod 700)
├── session/                  # Token-Aware Session Engine Extension
│   ├── README.md
│   ├── session-engine.sh
│   └── struttura.md
├── test/                     # Automated Verification Test Suites
│   ├── README-tests.md
│   ├── compatibility.sh
│   ├── concurrency.sh
│   ├── hardening.sh
│   ├── help-test.txt
│   ├── regression.sh
│   ├── run-all-tests.sh      # Master Unified Automated Test Suite (chmod 700)
│   ├── sanity.sh
│   ├── scintilla-t3.sh.      # SCINTILLA Core — T3 TEST SUITE FOR BASH4LLM
│   └── stress.sh
├── manifest.sha256           # SHA-256 Cryptographic Module Integrity Manifest
├── manifest.sha256.sig
└── official-ed25519.pub

```

**Installazione / Installation**

`./bash4llm --install-extras </path/to/extras/>`

