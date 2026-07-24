[![Logo 320](../docs/img/bash4llm320.png "Logo bash4llm")](../README.md)

# Bash4llm Extras

[![Update Extras Manifest](https://github.com/kamaludu/bash4llm/actions/workflows/update-manifest.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/update-manifest.yml)
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)

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
│   ├── core-notes.sh
│   ├── help.txt
│   ├── manual-en.txt
│   └── manual-it.txt
├── lib/                      # Shared Utility & Debug Helpers
│   ├── debug.sh
│   └── utils.sh
├── providers/                # Secondary LLM Provider Extension Modules
│   ├── gemini.sh
│   ├── huggingface.md
│   ├── huggingface.sh
│   └── mistral.sh
├── security/                 # Active Security, Encryption & Output Sanitization
│   ├── OPENSSL-HELPER.md
│   ├── openssl-helper.sh     # Encrypted OpenSSL Key Vault Engine (chmod 600, sourced)
│   └── output-sanitizer.sh   # Zero-Eval ANSI Filter & Output Sanitizer (chmod 700)
├── session/                  # Token-Aware Session Engine Extension
│   ├── README.md
│   ├── session-engine.sh
│   └── struttura.md
├── test/                     # Automated Verification Test Suites
│   ├── adversarial_tests.sh. # NDJSON Lock Contention & Fuzzing Tests (chmod 700)
│   └── run-all-tests.sh      # Master Unified Automated Test Suite (chmod 700)
└── manifest.sha256           # SHA-256 Cryptographic Module Integrity Manifest
```
