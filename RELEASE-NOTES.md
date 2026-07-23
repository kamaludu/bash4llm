[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)  

# Bash4LLM v2.6.0 — Release Notes

**Data / Date:** 2026‑07‑21  
**Stato / Status:** Stable – Security Hardening & Feature Release (Upgrade from v2.5.0)

## 💡 EVOLUZIONE ARCHITETTURALE / ARCHITECTURAL EVOLUTION

**🇮🇹 Sicurezza Crittografica, Privacy PII e Resilienza I/O**  
La versione 2.6.0 eleva la sicurezza di **Bash4LLM** introducendo un sistema di verifica crittografica dell'integrità del codice basato su manifest SHA-256, la protezione totale della privacy degli utenti tramite anonimizzazione dei Thread ID, un motore locale di rate-limiting a finestra scorrevole e la gestione avanzata dell'I/O esente da deadlock nelle pipeline automatizzate.

**🇬🇧 Cryptographic Integrity, PII Privacy & I/O Resilience**  
Version 2.6.0 hardens **Bash4LLM** security by introducing a cryptographic SHA-256 code integrity manifest system, complete user privacy via Thread ID anonymization, a native sliding-window rate limiter, and deadlock-free I/O pipeline execution for non-interactive automation.

---

## 🇮🇹 Sezione Italiana

### ✨ Novità principali
 * **Integrità Crittografica dei Moduli (`extras/manifest.sha256`)**: Controllo obbligatorio dell'hash SHA-256 su tutti i provider, estensioni ed hook prima del sourcing (`verify_module_integrity`). Qualsiasi manomissione o modifica non autorizzata blocca l'esecuzione con `Exit Code 17`.
 * **Anonimizzazione PII dei Thread ID (`anonymize_thread_id`)**: Cifratura automatica SHA-256 dei Thread ID in `$SAFE_THREAD_ID`. Impedisce la scrittura di dati personali (es. email o nomi) in chiaro su disco (.ndjson, .json, lock e cartelle di rate limit).
 * **Limitatore di Frequenza Locale (Rate Limiter)**: Motore a finestra scorrevole (30s) per prevenire abusi per thread (`BASH4LLM_RATE_LIMIT`), con possibilità di bypass tramite token autorizzato (`BASH4LLM_AUTH_TOKEN`).
 * **Esecuzione Isolata degli Hook (`execute_isolated_hook`)**: Sistema di estensione per hook `pre` e `post` esecuzione in subshell isolata con pulizia in memoria delle chiavi API e parsing Zero-Eval per variabili dinamiche (`FALLBACK_PAYLOAD`).
 * **Filtro di Sicurezza per File Binari (`validate_file_input`)**: Sanificazione degli input che blocca file contenenti byte nulli (`\x00`) o caratteri di controllo non stampabili prima di qualsiasi sostituzione di comando.

### 🔐 Sicurezza e Controllo del File-System
 * **Gestione Duale TTY / Pipe in `read_secure_input`**: Risolto il blocco I/O nelle pipeline. Se eseguito in terminale interattivo (`[ -t 0 ]`) nasconde l'input via TTY (`stty -echo`); se eseguito via pipe/script (`! [ -t 0 ]`), legge direttamente dallo `stdin` senza arrestarsi.
 * **Isolamento delle Directory di Runtime (`var/run/locks`)**: Organizzazione strutturata dei processi e dei file di blocco (`models.lock`, `tmp.lock`) all'interno della cartella dedicata `bash4llm.d/var/run/locks/` con permessi restrittivi `700`.

### 🛠️ Gestione Thread e Strumenti CLI
 * **Nuovi Comandi di Gestione Thread**:
   * `--delete-thread <id>`: Per eliminare definitivamente cronologia, metadati e indice di un thread sotto lock.
   * `--rename-thread <id> --title <testo>`: Per rinominare il titolo visibile di un thread.
   * `--init-thread`: Per pre-registrare la struttura di un thread senza effettuare chiamate API.
 * **Query dei Percorsi Canonici**: Aggiunti i flag `--print-config-dir`, `--print-provider-file` e `--print-model-file <provider>` per l'integrazione immediata in script ed estensioni esterne.

---

## 🇬🇧 English Section

### ✨ Key Highlights
 * **Cryptographic Module Integrity (`extras/manifest.sha256`)**: Mandatory SHA-256 hash verification for all external providers, extensions, and hooks prior to sourcing (`verify_module_integrity`). Any tampering blocks execution throwing `Exit Code 17`.
 * **Thread PII Anonymization (`anonymize_thread_id`)**: Automatic SHA-256 hashing of raw Thread IDs into `$SAFE_THREAD_ID`. Prevents personal user identifiers (e.g., emails or usernames) from leaking in cleartext to disk (.ndjson, .json, locks, and rate limit files).
 * **Local Sliding-Window Rate Limiter**: Native 30-second sliding-window request throttling per thread (`BASH4LLM_RATE_LIMIT`), featuring an authorized token bypass (`BASH4LLM_AUTH_TOKEN`).
 * **Isolated Subshell Hook Execution (`execute_isolated_hook`)**: Isolated subshell environment for pre/post execution hooks with memory credential stripping and Zero-Eval parsing for dynamic variables (`FALLBACK_PAYLOAD`).
 * **Binary Input & Null-Byte Rejection Filter (`validate_file_input`)**: Rigorous input validation rejecting files containing null bytes (`\x00`) or unprintable control characters before command substitutions occur.

### 🔐 Security & File-System Hardening
 * **Resilient Dual TTY / Pipe I/O Handling (`read_secure_input`)**: Deadlock-free secure input handling. Uses TTY echo suppression (`stty -echo`) when interactive (`[ -t 0 ]`), and seamlessly reads standard input (`stdin`) when executed in automated pipes (`! [ -t 0 ]`).
 * **Isolated Runtime Directory Architecture (`var/run/locks`)**: Clean separation of active process files and synchronization locks (`models.lock`, `tmp.lock`) into dedicated, mode `700` directories (`bash4llm.d/var/run/locks/`).

### 🛠️ Thread Management & CLI Tools
 * **Enhanced Thread CLI Commands**:
   * `--delete-thread <id>`: Permanently wipes thread history, metadata, and index entries under lock.
   * `--rename-thread <id> --title <text>`: Updates the user-facing title of a thread.
   * `--init-thread`: Pre-registers a thread structure on disk without making API network calls.
 * **Canonical Path Query Flags**: Added `--print-config-dir`, `--print-provider-file`, and `--print-model-file <provider>` for seamless integration with external scripts and tooling.

---

*This release notes document corresponds to release <a href='https://github.com/kamaludu/bash4llm/releases/tag/v2.6.0'>Bash4LLM v2.6.0</a>.*
