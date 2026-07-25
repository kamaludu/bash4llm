[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

# Master Test Suite (`extras/test/run-all-tests.sh`)

**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**

---

## 🇮🇹 Sezione Italiana

# Guida ed Elenco dei Test Automatizzati (`run-all-tests.sh`)

Lo script `extras/test/run-all-tests.sh` costituisce la suite di test master unificata di **Bash4LLM⁺**. Consente la validazione automatizzata, deterministica ed isolata dell'intero runtime, verificate le invarianti di sicurezza, la gestione dei file di lock e la conformità alle specifiche dell'**Architecture Specification (Edition 2026.1)**.

La suite viene eseguita all'interno di una sandbox isolata su filesystem (`.test_tmp/`), applicando i permessi POSIX `0700` senza mai scrivere nella directory condivisa `/tmp`.

Esecuzione da riga di comando:
```sh
./bash4llm --run-all-tests
```

---

## Elenco dei Moduli di Test e Verifiche Eseguite

### Modulo 1: Configurazione, Utilità e Getter di Percorso
* **Static configuration linter (`--check-config`)**: Verifica la presenza di permessi non restrittivi sui file di configurazione (`group/world-writable`) ed esegue il linter delle variabili.
* **Error documentation explainer (`--explain-error`)**: Valida il funzionamento dell'utilità di spiegazione dei codici d'errore e degli alias canoici.
* **Path getters (`--print-config-dir`, `--print-provider-file`, `--list-providers-raw`)**: Verifica la risoluzione corretta dei percorsi canonici di sistema e l'output grezzo dei provider installati.

### Modulo 2: Pipeline di Input e Assemblaggio Template
* **Piped STDIN prompt assembly**: Verifica l'acquisizione del prompt inviato tramite conduttura (pipe) di standard input.
* **File input payload assembly (`-f`)**: Valida il caricamento e la concatenazione di file di testo come contesto di input.
* **Template engine expansion (`--template`)**: Verifica la sostituzione dinamica del segnaposto `{{CONTENT}}` nei file di modello.

### Modulo 3: Sicurezza Modelli e Formattazione Output
* **Default model persistence (`--set-default`)**: Valida la scrittura e la persistenza del modello predefinito per provider.
* **Non-text model rejection (Exit Code 11)**: Verifica il blocco preventivo dei modelli multimodali non testuali (audio, vision, whisper) con codice di uscita `11` (`BASH4LLM_ERR_BAD_MODEL`).
* **Structured & Pretty JSON selection (`--json`, `--pretty`)**: Valida le modalità di formattazione dell'output JSON.

### Modulo 4: Gestione Thread, Anonimizzazione PII e Fuzzing
* **Path traversal mitigation**: Verifica la neutralizzazione di sequenze di attraversamento directory (es. `../../../etc/passwd`) nei parametri degli ID di thread.
* **Null-byte & command injection fuzzing**: Controlla il blocco di byte nulli (`\x00`) e tenta di iniezione di comandi nei nomi di thread.
* **PII Thread ID anonymization**: Verifica che gli ID dei thread (es. indirizzi email) vengano cifrati in hash SHA-256 (`SAFE_THREAD_ID`) prima di essere scritti su disco nei file `.ndjson` e nei file di metadati.
* **Thread lifecycle operations (`--init-thread`, `--rename-thread`, `--delete-thread`)**: Valida l'inizializzazione locale, la rinomina del titolo e l'eliminazione atomica dei file di storico.

### Modulo 5: Motore di Sicurezza, Rate Limiter e Filtro Binari
* **Binary file rejection filter (Exit Code 17)**: Verifica il blocco immediato dei file binari contenenti byte nulli con codice di uscita `17` (`BASH4LLM_ERR_SEC`).
* **Sliding window rate limiter (Exit Code 17)**: Testa il blocco del traffico al superamento della quota di richieste consentite entro una finestra di 30 secondi.
* **Symlink traversal check**: Verifica il rilevamento e il blocco di collegamenti simbolici non autorizzati sui percorsi di configurazione e temporanei.
* **Cryptographic SHA-256 integrity (Exit Code 17)**: Verifica che la modifica di un singolo byte in un modulo esterno rispetto a `extras/manifest.sha256` provochi l'arresto immediato con codice `17`.

### Modulo 6: Motore Vault Crittografico OpenSSL
* **AES-256/PBKDF2 Vault encryption & decryption**: Test funzionale di cifratura e decifrazione delle chiavi API utilizzando OpenSSL, PBKDF2 (100.000 iterazioni) e salt crittografico.
* **Encrypted vault disk file creation**: Verifica la creazione corretta dei file `keys.enc` e `keys.dat` con permessi restrittivi `0600`.

### Modulo 7: Test di Stress sulla Concorrenza dei Lock
* **High-concurrency parallel workers stress test**: Avvia un numero dinamico di processi worker paralleli (adattati alla piattaforma: da 10 su Termux a 50 su Linux/macOS) che eseguono accodamenti NDJSON simultanei sullo stesso file di thread. Verifica l'assenza di corruzione dei dati o perdita di righe tramite `lock_exec`.

### Modulo 8: Motore Opzionale di Parsing Python 3
* **JSON escaping & SSE chunk payload extractor**: Valida l'esecuzione delle routine di riserva per l'escape delle stringhe JSON ed il parsing SSE via Python 3 (qualora l'interprete sia installato).

### Modulo 9: Invarianti di Sicurezza e Guardie Read-Only
* **Read-only function guard enforcement (`readonly -f`)**: Verifica che le funzioni critiche di sicurezza (`_exec_curl_secure`, `verify_module_integrity`, `read_secure_input`, ecc.) marcate da `_lock_security_guards()` non possano essere ridefinite o rimosse in memoria.
* **Module tampering fail-closed enforcement**: Conferma il modello *fail-closed* che interrompe l'esecuzione con codice `17` in caso di manomissione dei moduli.
* **Authoritative secure cURL path**: Verifica la presenza e la disponibilità della funzione centralizzata `_exec_curl_secure()`.

---

## 🇬🇧 English Section

# Master Automated Test Suite Guide (`run-all-tests.sh`)

The `extras/test/run-all-tests.sh` script represents the unified automated test suite for **Bash4LLM⁺**. It provides deterministic, isolated validation of the core runtime, security invariants, lock concurrency, and compliance with the **Architecture Specification (Edition 2026.1)**.

The suite executes inside an isolated filesystem sandbox (`.test_tmp/`) enforcing POSIX `0700` directory permissions without polluting the system `/tmp` directory.

Execution command:
```sh
./bash4llm --run-all-tests
```

---

## Test Modules and Executed Checks

### Module 1: Configuration, Utilities & Path Getters
* **Static configuration linter (`--check-config`)**: Validates configuration file permissions for group/world write vulnerabilities and lints active variables.
* **Error documentation explainer (`--explain-error`)**: Tests the error code and alias documentation lookup utility.
* **Path getters (`--print-config-dir`, `--print-provider-file`, `--list-providers-raw`)**: Verifies exact canonical directory paths and raw provider listings.

### Module 2: Input Pipeline & Template Assembly
* **Piped STDIN prompt assembly**: Validates reading input prompts forwarded via standard input pipes.
* **File input payload assembly (`-f`)**: Tests reading and concatenating external text files into the prompt queue.
* **Template engine expansion (`--template`)**: Verifies dynamic replacement of the `{{CONTENT}}` placeholder inside template files.

### Module 3: Model Safety & Output Formatting
* **Default model persistence (`--set-default`)**: Tests saving default models persistently per provider.
* **Non-text model rejection (Exit Code 11)**: Verifies proactive blocking of non-textual multimodal models (audio, vision, whisper) with exit code `11` (`BASH4LLM_ERR_BAD_MODEL`).
* **Structured & Pretty JSON selection (`--json`, `--pretty`)**: Validates JSON response output formatting options.

### Module 4: Thread Lifecycle, PII Anonymization & Fuzzing
* **Path traversal mitigation**: Confirms rejection or neutralization of path traversal sequences (e.g., `../../../etc/passwd`) in thread IDs.
* **Null-byte & command injection fuzzing**: Tests blocking of embedded null bytes (`\x00`) and command injection payloads in thread identifiers.
* **PII Thread ID anonymization**: Verifies that user thread IDs (e.g., email addresses) are hashed via SHA-256 (`SAFE_THREAD_ID`) before writing `.ndjson` history or metadata files to disk.
* **Thread lifecycle operations (`--init-thread`, `--rename-thread`, `--delete-thread`)**: Validates thread registration, title updating, and atomic file deletion.

### Module 5: Security Engine, Rate Limiter & Binary Safety
* **Binary file rejection filter (Exit Code 17)**: Verifies immediate rejection of binary files containing null bytes with exit code `17` (`BASH4LLM_ERR_SEC`).
* **Sliding window rate limiter (Exit Code 17)**: Tests request throttling when per-thread request quotas are exceeded within a 30-second window.
* **Symlink traversal check**: Confirms detection and handling of unauthorized symbolic links on configuration paths.
* **Cryptographic SHA-256 integrity (Exit Code 17)**: Verifies that altering a single byte in an extension module triggers an immediate halt with exit code `17`.

### Module 6: OpenSSL Cryptographic Key Vault Engine
* **AES-256/PBKDF2 Vault encryption & decryption**: Validates API key encryption and decryption using OpenSSL, PBKDF2 (100,000 iterations), and salt.
* **Encrypted vault disk file creation**: Confirms creation of `keys.enc` and `keys.dat` files with restrictive `0600` permissions.

### Module 7: High-Concurrency Lock Contention Stress Test
* **Parallel worker stress test**: Launches platform-adapted parallel worker processes (10 workers on Termux/Cygwin up to 50 on multi-core Linux/macOS) executing simultaneous NDJSON appends to the same thread file, verifying data integrity and locking via `lock_exec`.

### Module 8: Optional Python 3 SSE & JSON Parsing Engine
* **JSON escaping & SSE chunk payload extractor**: Tests fallback helper routines for JSON escaping and SSE chunk parsing via Python 3 when present on the host.

### Module 9: Security Invariants & Read-Only Function Guards
* **Read-only function guard enforcement (`readonly -f`)**: Asserts that critical security functions (`_exec_curl_secure`, `verify_module_integrity`, `read_secure_input`, etc.) locked by `_lock_security_guards()` cannot be overridden or unset in memory.
* **Module tampering fail-closed enforcement**: Confirms the *fail-closed* execution halt (exit code `17`) on modified modules.
* **Authoritative secure cURL path**: Asserts availability and presence of `_exec_curl_secure()`.
