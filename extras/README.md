[![Logo 320](../docs/img/bash4llm320.png "Logo bash4llm")](../README.md)

# Bash4llm Extras

[![Update Extras Manifest](https://img.shields.io/github/actions/workflow/status/kamaludu/bash4llm/update-manifest.yml?branch=main&style=flat&color=00b4d8&label=manifest%20sha256&labelColor=2B2B2B&logo=github&logoColor=white)](https://github.com/kamaludu/bash4llm/actions/workflows/update-manifest.yml)
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)

```text
extras/
├── chat/                   # Text User Interface
│   ├── langs/
│   │   ├── de.properties
│   │   ├── en.properties
│   │   ├── es.properties
│   │   ├── fr.properties
│   │   └── it.properties
│   ├── SPEC-TUI.md
│   └── tui-repl.sh
├── docs/                   # Inline Docs
│   ├── core-notes.sh
│   ├── help.txt
│   ├── manual-en.txt
│   └── manual-it.txt
├── lib/                    # Optional Helpers
│   ├── debug.sh
│   └── utils.sh
├── providers/              #:Extra Providers 
│   ├── gemini.sh
│   ├── huggingface.md
│   ├── huggingface.sh
│   └── mistral.sh
├── security/               # Security and Encryption Modules
│   ├── OPENSSL-HELPER.md
│   ├── openssl-helper.sh
│   ├── validate-env.sh
│   └── verify.sh
├── session/                # Optional Session Engine
│   ├── README.md
│   ├── session-engine.sh
│   └── struttura.md
└── test/
    ├── concurrency-test.sh
    └── json-sse-suite.sh
```
