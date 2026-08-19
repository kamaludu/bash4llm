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
│   ├── gui-py.sh             # Launcher CLI Wrapper (POSIX Bash 4.0+, 0700)
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
│   ├── sml-gate.sh           # Structured Metadata Layout - Semantic Safety Gate
│   └── sml-readme.md 
├── providers/                # Optional LLM Provider Extension Modules
│   ├── gemini.sh
│   ├── huggingface.md
│   ├── huggingface.sh
│   ├── mistral.sh
│   └── openrouter.sh
├── security/                 # Active Security, Encryption & Output Sanitization
│   ├── OPENSSL-HELPER.md
│   ├── generate-manifest.sh  # Official Extras Manifest Generator & Ed25519 Signer
│   ├── openssl-helper.sh     # Encrypted OpenSSL Key Vault Engine (chmod 600, sourced)
│   └── output-sanitizer.sh   # Zero-Eval ANSI Filter & Output Sanitizer (chmod 700)
├── session/                  # Token-Aware Session Engine Extension
│   ├── README.md
│   ├── session-engine.sh
│   └── struttura.md
├── templates/                  
│   └── sml.txt               # Structured Metadata Layout v2.0 prompt template 
├── test/                     # Automated Verification Test Suites
│   ├── README-tests.md
│   ├── compatibility.sh
│   ├── concurrency.sh
│   ├── hardening.sh
│   ├── help-test.txt
│   ├── regression.sh
│   ├── run-all-tests.sh      # Master Unified Automated Test Suite (chmod 700)
│   ├── sanity.sh
│   ├── scintilla-t3.sh       # SCINTILLA Core — T3 TEST SUITE FOR BASH4LLM
│   └── stress.sh
├── manifest.sha256           # SHA-256 Cryptographic Module Integrity Manifest
├── manifest.sha256.sig       # Ed25519 Cryptographic Signature
└── official-ed25519.pub      # Official Ed25519 Public Key

```

**Installazione / Installation**

`./bash4llm --install-extras </path/to/extras/>`

## [🇮🇹 Italiano](#sezione-italiana) / [🇬🇧 English](#english-section)

---

# Ecosistema e Moduli Estesi (Extras) — Bash4LLM⁺

<a id="sezione-italiana"></a>
### 🇮🇹 Sezione Italiana

La cartella `extras/` ospita l'ecosistema di estensioni modulari e opzionali per **Bash4LLM⁺**. L'architettura è rigorosamente segregata: il Core `./bash4llm` rimane un componente fidato, minimale e a dipendenze zero (POSIX/Bash 4.0+), mentre gli *extras* estendono le capacità operative integrando dipendenze opzionali e circoscritte (*soft dependencies* come OpenSSL o Python 3.10+).

Tutti i componenti in `extras/` operano in conformità a quattro invarianti architetturali primarie:
1. **Zero-Eval**: Nessun uso del comando dinamico `eval` sui flussi di input, payload o risposte generate.
2. **Isolamento Workspace**: Nessuna allocazione nella directory condivisa `/tmp`. I file temporanei risiedono esclusivamente in `RUN_TMPDIR` con permessi `0700` (`umask 077`).
3. **Principio del Minimo Privilegio**: I file sono impostati a `0600` e le directory a `0700`. Il bit di esecuzione (`0700`) è concesso rigorosamente ed esclusivamente ai 4 entrypoint autorizzati: `chat/tui-repl.sh`, `gui-py/gui-py.sh`, `security/output-sanitizer.sh` e `test/*.sh`.
4. **Modello Manifest-Authorized**: Nessun modulo o test viene caricato o eseguito implicitamente; ogni risorsa deve essere registrata e validata nel manifest crittografico SHA-256 (`extras/manifest.sha256`). In caso di mismatch, il sistema applica una politica *fail-closed* immediata restituendo il codice di errore `17` (`BASH4LLM_ERR_SEC`).

---

## Mappa Architetturale

```text
extras/
├── chat/          # Interfaccia REPL a schermo intero (TUI nativa Bash)
├── docs/          # Autocompletamento shell Bash e documentazione tecnica
├── gui-py/        # WebApp GUI locale basata su FastAPI / Python 3.10+
├── hooks/         # Gate semantici e filtri post-esecuzione (SML Gate)
├── providers/     # Moduli driver per provider LLM OpenAI-compatibili
├── security/      # Key Vault cifrato OpenSSL, sanitizzazione ANSI e generatore manifest
├── session/       # Advanced Session Engine (NDJSON segmentato, rotazione e cache)
└── test/          # Master Test Suite unificata (6 livelli + SCINTILLA T3)
```

---

## Dettaglio dei Componenti

### 1. Interfacce Utente (`chat/` e `gui-py/`)
* **Interactive TUI REPL (`extras/chat/tui-repl.sh`)**
  * **Invocazione Core:** `bash4llm --chat` oppure `bash4llm --tui`
  * **Caratteristiche:** Terminal User Interface interattiva a schermo intero nativa in Bash (zero dipendenze binarie oltre POSIX standard). Offre supporto multilingua tramite file `.properties` (`it`, `en`, `es`, `fr`, `de`), gestione cronologia multi-riga, comandi slash (`/`) e commutazione dinamica del modello e della temperatura.
* **WebApp GUI Bridge (`extras/gui-py/`)**
  * **Invocazione Core:** `bash4llm --gui` oppure `bash4llm --webapp`
  * **Caratteristiche:** Server locale asincrono in Python 3.10+ (FastAPI + Uvicorn) che espone un'interfaccia responsive SPA a zero framework HTML5/CSS/JS. Implementa streaming SSE (Server-Sent Events), protezione Origin/CSRF header, lockfile per istanza singola e comunicazione sicura via subprocess pipe (IPC).

### 2. Provider Estesi (`extras/providers/`)
* **Invocazione Core:** `bash4llm --provider <nome>` (es. `--provider gemini`)
* **Moduli Inclusi:** `gemini.sh` (Google Gemini), `mistral.sh` (Mistral AI), `huggingface.sh` (Hugging Face Inference Endpoints).
* **Contratto Pubblico:** Ogni provider estende il backend OpenAI-compatibile implementando in modo isolato le primitive `buildpayload_<provider>` e `call_api_<provider>`. Il caricamento avviene in subshell isolata con verifica di sicurezza anti-TOCTOU, snapshot/restore dell'ambiente shell e validazione dell'interfaccia.

### 3. Sicurezza, Cifratura e Sanitizzazione (`extras/security/`)
* **OpenSSL Key Vault Helper (`openssl-helper.sh`)**
  * **Invocazione Core:** `bash4llm --vault`
  * **Caratteristiche:** Gestione crittografica locale delle chiavi API con cifratura simmetrica AES-256-CBC e KDF PBKDF2 (100.000 iterazioni). Utilizza il wrapping a chiave intermedia (**Vault Key**): la chiave master cifra `keys.enc`, mentre il sistema genera contestualmente una **Recovery Key** offline a 32 caratteri esadecimali (`keys.rec`). Impedisce l'esposizione delle credenziali nella tabella dei processi (`ps aux` / `argv`) esportando la password solo a descrittori/env effimeri.
* **Output Sanitizer Engine (`output-sanitizer.sh`)**
  * **Invocazione Core:** `bash4llm --sanitize` (oppure con `--strict-output`)
  * **Caratteristiche:** Filtro Zero-Eval basato su `awk`/`tr` per ripulire lo stream di testo da sequenze di escape ANSI e caratteri di controllo C0. In modalità strict esegue l'escaping preventivo dei metacaratteri shell (`\`, `$`, `` ` ``, `!`) per un pipelining sicuro.

### 4. Advanced Session Engine (`extras/session/`)
* **Attivazione:** Automatica se `BASH4LLM_SESSION_ENGINE=on` (default).
* **Caratteristiche:** Progettato per prevenire il degrado prestazionale nelle conversazioni estese:
  * **Segmentazione e Rotazione:** Ruota i file NDJSON in segmenti numerati (`<sid>.NNN.ndjson`) al raggiungimento della soglia configurata (default 1MB, `BASH4LLM_SESSION_SEGMENT_MAX_BYTES`), con supporto alla compressione `.gz`.
  * **Deduplicazione:** Elimina l'accodamento di messaggi identici ravvicinati.
  * **Finestra di Contesto Dinamica:** Ricostruzione deterministica del payload per numero esplicito di messaggi ($N$) o budget di byte (`target_bytes`).
  * **In-Memory Cache:** Cache associativa in memoria con TTL (default 30s) invalidata a ogni nuovo append atomico.

### 5. Semantic Safety Hooks (`extras/hooks/`)
* **SML Safety Gate (`sml-gate.sh`)**
  * **Invocazione Core:** `bash4llm --validate-sml`
  * **Caratteristiche:** Hook post-esecuzione isolato che convalida formalmente che l'output dell'LLM sia conforme allo standard *Structured Metadata Layout* (SML v2.0), verificando la presenza e la coerenza dei blocchi obbligatori `LISTEN_SUMMARY:` e `CONVERSATION_OUTCOME:`.

### 6. Autocompletamento e Documentazione (`extras/docs/`)
* **Shell Completion Module (`bash4llm-completion.sh`)**
  * **Attivazione:** Sourcing diretto (`source extras/docs/bash4llm-completion.sh`) o sourcing del core (`. ./bash4llm`).
  * **Caratteristiche:** Autocompletamento contestuale nativo per Bash 4.0+ per opzioni CLI, modelli locali per provider attivo e codici di errore diagnostici.
* **Guide e Manuali:** Include le note di progettazione `core-notes.sh` e i manuali utente (`manual-it.txt`, `manual-en.txt`, `help.txt`).

### 7. Master Test Suite (`extras/test/`)
* **Invocazione Core:** `bash4llm --test [suite]` oppure `bash4llm --run-all-tests`
* **Sandbox:** Esecuzione completamente isolata in `.test_tmp/` (permessi `0700`, no `/tmp`).
* **Piramide di Verifica a 6 Livelli:**
  1. `sanity.sh`: Validazione dipendenze host, bootstrap CLI e linter statico configurazione.
  2. `compatibility.sh`: Validazione exit code canonici (`10`-`17`), formati output e flag CLI.
  3. `regression.sh`: Flussi End-to-End, elaborazione file `-f`, template e lifecycle thread.
  4. `hardening.sh`: Invarianti di sicurezza `[INV-1]`-`[INV-5]`, assenza di secret in `argv`, audit `eval` e rate limiting.
  5. `concurrency.sh`: Sincronizzazione parallela multiprocesso, contesa lockfile e scritture atomiche NDJSON.
  6. `stress.sh`: Staging ad alto volume Base64 e saturazione storico rotativo.
* **SCINTILLA Core T3 Test Suite (`scintilla-t3.sh`)**: Modulo di test dedicato alla verifica delle implementazioni di refactoring (`--validate-sml`, `--sanitize`, `--json-diagnostics`).

---

## Gestione dell'Integrità Crittografica del Manifest

L'integrità dei moduli è garantita dal manifest `manifest.sha256` e dalla relativa firma Ed25519 (`manifest.sha256.sig`). Per registrare modifiche locali o nuovi moduli:

```bash
# 1. Rigenerazione checksum manifest senza firma (aggiornamento locale)
./extras/security/generate-manifest.sh --no-sign-if-missing-key

# 2. Generazione di una nuova coppia di chiavi Ed25519 e firma completa
./extras/security/generate-manifest.sh --generate-key

# 3. Firma con chiave privata Ed25519 esistente
./extras/security/generate-manifest.sh --key /percorso/alla/chiave-privata.pem
```

---

# Ecosystem and Extended Modules (Extras) — Bash4LLM⁺

<a id="english-section"></a>
### 🇬🇧 English Section

The `extras/` directory hosts the modular, optional extension ecosystem for **Bash4LLM⁺**. The architecture follows a strict segregation model: the Core `./bash4llm` executable remains a trusted, minimal, and zero-dependency component (standard POSIX/Bash 4.0+), while the *extras* introduce targeted, opt-in enhancements (*soft dependencies* such as OpenSSL or Python 3.10+).

All components residing in `extras/` strictly adhere to four primary architectural invariants:
1. **Zero-Eval**: Zero usage of dynamic `eval` commands on inputs, payload construction, or generated outputs.
2. **Isolated Workspace**: Absolute avoidance of the shared system `/tmp` directory. All temporary files reside in `RUN_TMPDIR` under restrictive `0700` permissions (`umask 077`).
3. **Principle of Least Privilege**: File permissions are strictly enforced to `0600` and directories to `0700`. Executable bits (`0700`) are strictly restricted to the 4 authorized entrypoint categories: `chat/tui-repl.sh`, `gui-py/gui-py.sh`, `security/output-sanitizer.sh`, and `test/*.sh`.
4. **Manifest-Authorized Security Model**: No module or test is implicitly executed from disk; every component must be registered in the cryptographic SHA-256 manifest (`extras/manifest.sha256`). Any hash mismatch triggers a fail-closed exit with code `17` (`BASH4LLM_ERR_SEC`).

---

## Architectural Map

```text
extras/
├── chat/          # Full-screen REPL interface (Native Bash TUI)
├── docs/          # Shell completion and core architectural documentation
├── gui-py/        # Local WebApp GUI powered by FastAPI / Python 3.10+
├── hooks/         # Semantic safety gates and post-execution hooks (SML Gate)
├── providers/     # Modular drivers for OpenAI-compatible LLM providers
├── security/      # Encrypted OpenSSL Key Vault, ANSI sanitizer, and manifest generator
├── session/       # Advanced Session Engine (Segmented NDJSON, rotation, caching)
└── test/          # Master Test Suite framework (6 verification levels + SCINTILLA T3)
```

---

## Component Reference

### 1. User Interfaces (`chat/` & `gui-py/`)
* **Interactive TUI REPL (`extras/chat/tui-repl.sh`)**
  * **Core Invocation:** `bash4llm --chat` or `bash4llm --tui`
  * **Features:** Full-screen interactive Terminal User Interface written 100% in native Bash (zero external binary dependencies beyond POSIX standards). Features multilingual support via `.properties` files (`en`, `it`, `es`, `fr`, `de`), multi-line input handling, slash commands (`/`), and dynamic model/temperature switching.
* **WebApp GUI Bridge (`extras/gui-py/`)**
  * **Core Invocation:** `bash4llm --gui` or `bash4llm --webapp`
  * **Features:** Asynchronous Python 3.10+ local server (FastAPI + Uvicorn) delivering a responsive zero-framework HTML5/CSS/JS WebApp. Features Server-Sent Events (SSE) streaming, Origin/CSRF header validation, single-instance process lock, and secure subprocess IPC pipe communication.

### 2. Extended Providers (`extras/providers/`)
* **Core Invocation:** `bash4llm --provider <name>` (e.g., `--provider gemini`)
* **Supported Modules:** `gemini.sh` (Google Gemini), `mistral.sh` (Mistral AI), `huggingface.sh` (Hugging Face Inference Endpoints).
* **Provider Contract:** Each module extends the OpenAI-compatible backend by implementing isolated `buildpayload_<provider>` and `call_api_<provider>` primitives. Modules load inside a clean subshell with TOCTOU mitigation, environment snapshot/restore guards, and interface integrity audits.

### 3. Security, Encryption & Sanitization (`extras/security/`)
* **OpenSSL Key Vault Helper (`openssl-helper.sh`)**
  * **Core Invocation:** `bash4llm --vault`
  * **Features:** Local symmetric API key credential vault utilizing AES-256-CBC and PBKDF2 (100,000 iterations). Implements **Vault Key** wrapping: the Master Password encrypts `keys.enc`, while the system automatically generates an offline 32-character hexadecimal **Recovery Key** (`keys.rec`). Eliminates secret leakage in system process tables (`ps aux` / `argv`) by passing credentials strictly through ephemeral environment variables and unlinked file descriptors.
* **Output Sanitizer Engine (`output-sanitizer.sh`)**
  * **Core Invocation:** `bash4llm --sanitize` (or with `--strict-output`)
  * **Features:** Zero-Eval stream filter built on `awk`/`tr` to strip malicious ANSI escape codes and unprintable C0 control characters. Strict mode automatically escapes shell metacharacters (`\`, `$`, `` ` ``, `!`) for downstream pipeline safety.

### 4. Advanced Session Engine (`extras/session/`)
* **Activation:** Loaded automatically when `BASH4LLM_SESSION_ENGINE=on` (default).
* **Features:** Engineered to eliminate latency and memory degradation across long-running conversational contexts:
  * **Segmentation & Rotation:** Rotates NDJSON log files into indexed segments (`<sid>.NNN.ndjson`) when exceeding the byte threshold (default 1MB, `BASH4LLM_SESSION_SEGMENT_MAX_BYTES`), with optional `.gz` compression.
  * **Message Deduplication:** Prevents duplicate consecutive messages from polluting the context window.
  * **Dynamic Context Window:** Deterministic payload construction using explicit message count ($N$) or byte-budget limits (`target_bytes`).
  * **In-Memory Caching:** Associative in-process context cache with configurable TTL (default 30s), invalidated on every atomic append.

### 5. Semantic Safety Hooks (`extras/hooks/`)
* **SML Safety Gate (`sml-gate.sh`)**
  * **Core Invocation:** `bash4llm --validate-sml`
  * **Features:** Isolated post-execution hook validating that assistant completions strictly adhere to the *Structured Metadata Layout* (SML v2.0) specification by checking for required `LISTEN_SUMMARY:` and `CONVERSATION_OUTCOME:` structures.

### 6. Autocompletion & Documentation (`extras/docs/`)
* **Native Shell Completion (`bash4llm-completion.sh`)**
  * **Activation:** Direct source (`source extras/docs/bash4llm-completion.sh`) or core sourcing (`. ./bash4llm`).
  * **Features:** Full contextual autocompletion for Bash 4.0+ covering CLI options, cached local provider models, and diagnostic error codes.
* **Technical Manuals:** Includes design notes `core-notes.sh` and offline user guides (`manual-en.txt`, `manual-it.txt`, `help.txt`).

### 7. Master Test Suite (`extras/test/`)
* **Core Invocation:** `bash4llm --test [suite]` or `bash4llm --run-all-tests`
* **Sandbox:** Executes strictly within `.test_tmp/` (`0700` permissions, no `/tmp` usage).
* **6-Level Verification Pyramid:**
  1. `sanity.sh`: Host dependency checks, Core bootstrapping, and configuration linter.
  2. `compatibility.sh`: Public compatibility contract, canonical exit codes (`10`-`17`), and output formats.
  3. `regression.sh`: End-to-End execution flows, `-f` input handling, prompt templates, and thread lifecycles.
  4. `hardening.sh`: Security invariants `[INV-1]`–`[INV-5]`, process list secret leakage, `eval` audits, and rate limiting.
  5. `concurrency.sh`: Multi-process parallel synchronization, lockfile contention, and atomic NDJSON stream integrity.
  6. `stress.sh`: High-volume Base64 staging and history rotation boundaries.
* **SCINTILLA Core T3 Test Suite (`scintilla-t3.sh`)**: Dedicated T3 verification module testing refactored safety flags (`--validate-sml`, `--sanitize`, `--json-diagnostics`).

---

## Supply Chain Security & Manifest Integrity

Extras module integrity is verified against `manifest.sha256` and authenticated with the Ed25519 signature `manifest.sha256.sig`. To update checksums after adding or modifying local modules:

```bash
# 1. Update SHA-256 manifest without signature (local development mode)
./extras/security/generate-manifest.sh --no-sign-if-missing-key

# 2. Generate a new Ed25519 key pair and sign the manifest
./extras/security/generate-manifest.sh --generate-key

# 3. Sign manifest with an existing Ed25519 private key
./extras/security/generate-manifest.sh --key /path/to/private-key.pem
```
