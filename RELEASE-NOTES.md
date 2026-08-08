[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)  

# Bash4LLM v2.8.5 — Release Notes  [🇮🇹](#-sezione-italiana) [🇬🇧](#-english-section)

**Data / Date:** 2026-08-07  
**Stato / Status:** Stable – Ed25519 Cryptographic Verification, Scintilla Deterministic Extensions & Domain Isolation Release (Upgrade from v2.8.0)

---

## 🇮🇹 Sezione Italiana

### Novità principali e Hardening di Sicurezza
* **Firma Crittografica Ed25519 del Manifesto (`_verify_manifest_signature`)**: Convalida crittografica nativa del file `extras/manifest.sha256.sig` tramite la chiave pubblica `official-ed25519.pub` (gestita via OpenSSL o `ssh-keygen`). Nuova policy opzionale di obbligatorietà `BASH4LLM_REQUIRE_MANIFEST_SIG=1`.
* **Isolamento Anti-TOCTOU tramite Staging Copy**: I moduli dei provider esterni e gli script di hook vengono copiati in un file di staging temporaneo isolato (`staged_file` in `$RUN_TMPDIR` con permessi `0600`) prima dell'esecuzione dei controlli di sicurezza e dell'importazione, azzerando le finestre di gara Time-of-Check to Time-of-Use.
* **Anonimizzazione PII degli ID Thread (`anonymize_thread_id`)**: Hashing crittografico SHA-256/MD5 automatico di tutti gli identificatori di thread prima della scrittura su disco (`SAFE_THREAD_ID`), prevenendo la persistenza di percorsi riservati o dati personali nei metadati e nei registri.
* **Policy Vault Obbligatorio (`BASH4LLM_REQUIRE_VAULT=1`)**: Nuova opzione di sicurezza che impone l'estrazione delle API Key esclusivamente dal Vault cifrato OpenSSL, rifiutando tassativamente il ripiegamento su variabili d'ambiente in chiaro.
* **Rate Limiting Locale a Finestra Scorrevole (`check_local_rate_limit`)**: Protezione nativa da inondazioni di richieste per thread (finestra di 30 secondi tracciata in `tmp/rates/` con blocco ad exit code 17 in caso di superamento).
* **Filtro di Sicurezza sugli Input File (`validate_file_input`)**: Convalida preventiva dei file caricati con `-f` o argomenti posizionali, con rifiuto immediato in caso di file vuoti, byte nulli o dati binari non stampabili.
* **Estensione delle Guardie Read-Only (`_lock_security_guards`)**: Blocco `readonly -f` esteso a 8 funzioni critiche di sicurezza, rete e filesystem (`_exec_curl_secure`, `verify_module_integrity`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `read_secure_input`, `enforce_network_policy`, `execute_isolated_hook`).

### Estensioni Deterministiche (Scintilla-Ready)
* **Validazione Sintattica SML v2.0 (`--validate-sml`)**: Verifica deterministica dell'output dell'LLM rispetto allo standard sintattico EBNF SML v2.0 (`SML_VERSION: 2.0`, `LISTEN_SUMMARY:`, `CONVERSATION_OUTCOME:`, `PROPOSED_TRANSITION:`, `EVIDENCE_TYPE:`).
* **Validazione REGEX (`--validate-regex <expr>`)**: Convalida formale della risposta rispetto a un'espressione regolare POSIX Extended.
* **Codice d'Errore Canonico 13 (`BASH4LLM_ERR_PARSE`)**: Inserita la costante di errore `13` (`BASH4LLMERR_PARSE`) per segnalare fallimenti di parsing JSON o il mancato superamento dei controlli sintattici SML/REGEX.
* **Sanitizzazione Output ANSI (`--sanitize`)**: Filtraggio zero-eval delle sequenze di escape ANSI e caratteri non stampabili mediante delegazione a `extras/security/output-sanitizer.sh` o fallback POSIX.
* **Diagnostica JSON Strutturata (`--json-diagnostics`)**: Emissione di log d'errore in formato JSON formattato (`emit_json_diagnostics`) contenenti stato, codice, ragione, messaggio e timestamp UTC.

### Architettura Provider, Domini di Fiducia e Contratto API
* **Contratto di Versione API Provider (`BASH4LLM_SUPPORTED_PROVIDER_API=1`)**: Introdotto il controllo di versione sull'interfaccia dell'API dei provider esterni (`BASH4LLM_PROVIDER_API_VERSION`), con blocco dell'importazione ad exit code 98 in caso di incompatibilità.
* **Domini di Fiducia Espliciti**: Risoluzione flessibile dei provider tramite prefisso (`builtin:`, `vendor:`, `local:`). Creata la directory `local-extras/providers/` per i moduli utente non tracciati dal manifesto vendor.
* **Filtro Whitelist Anti-Hijacking (`comm -13`)**: L'importazione dei moduli provider estrae ed esporta nel processo principale **esclusivamente le 8 funzioni dell'interfaccia autorizzata**, bloccando l'iniezione di codice o funzioni arbitrarie.
* **Interfaccia Estesa Provider**: Aggiunte le funzioni opzionali `validate_model_<provider>()` e `auto_select_model_<provider>()`.

### Gestione Thread, Interfaccia CLI e Tooling
* **Comandi CLI CRUD per Thread**:
  * `--init-thread`: Inizializzazione manuale di metadati e contesto per un nuovo thread.
  * `--delete-thread <id>`: Eliminazione atomica di storico NDJSON, lock e metadati di un thread.
  * `--rename-thread <id> --title <titolo>`: Rinomina atomica del titolo nei metadati del thread.
* **Caching locale Thread con TTL**: Implementato il caching isolato in `config/thread_cache/` per ottimizzare le letture della finestra dei messaggi.
* **Ispezione Percorsi e Listing Grezzo**: Aggiunte le opzioni `--print-config-dir`, `--print-provider-file`, `--print-model-file [provider]`, `--list-providers-raw` e `--list-models-raw`.
* **Console Vault e Autocompletamento**: Avvio diretto della console Key Vault tramite `--vault` e caricamento dello script di completamento shell `extras/docs/bash4llm-completion.sh`.

### Suite di Test, CI/CD e Documentazione
* **Modulo SCINTILLA Core T3 (`scintilla-t3.sh`)**: Inserita la nuova suite di test nell'orchestratore Master (`--run-all-tests`) per la verifica automatizzata delle flag `--validate-sml`, `--validate-regex`, `--sanitize` e `--json-diagnostics`.
* **Aggiornamento Specifiche e Documentazione**: Allineamento completo di `docs/bash4llm-arch-spec.md`, `README.md`, `INSTALL.md`, `SECURITY.md`, `PROVIDERS.md` e `llms.txt` alla versione 2.8.5.

---

## 🇬🇧 English Section

### Key Features & Security Hardening
* **Ed25519 Cryptographic Manifest Signature (`_verify_manifest_signature`)**: Native cryptographic validation of `extras/manifest.sha256.sig` via public key `official-ed25519.pub` (handled via OpenSSL or `ssh-keygen`). Optional mandatory enforcement policy `BASH4LLM_REQUIRE_MANIFEST_SIG=1`.
* **Anti-TOCTOU Staging Copy Isolation**: External provider modules and hook scripts are copied to an isolated temporary staging file (`staged_file` in `$RUN_TMPDIR` with `0600` permissions) prior to path security checks and sourcing, eliminating Time-of-Check to Time-of-Use race conditions.
* **Thread ID PII Anonymization (`anonymize_thread_id`)**: Automatic SHA-256/MD5 cryptographic hashing of thread identifiers (`SAFE_THREAD_ID`) prior to writing to disk, preventing personal data or confidential paths from persisting in metadata and logs.
* **Mandatory Vault Policy (`BASH4LLM_REQUIRE_VAULT=1`)**: New security policy forcing API key retrieval strictly from the OpenSSL Encrypted Vault, strictly prohibiting fallback to unencrypted environment variables.
* **Local Sliding-Window Rate Limiting (`check_local_rate_limit`)**: Native request flood protection per thread (30-second window tracked in `tmp/rates/` with exit code 17 block when exceeded).
* **Input File Binary Filter (`validate_file_input`)**: Preventive validation of files loaded via `-f` or positional arguments, with immediate rejection if empty, containing null bytes, or unprintable binary control characters.
* **Expanded Read-Only Function Guards (`_lock_security_guards`)**: Extended `readonly -f` locking to 8 critical security, network, and filesystem functions (`_exec_curl_secure`, `verify_module_integrity`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `read_secure_input`, `enforce_network_policy`, `execute_isolated_hook`).

### Scintilla-Ready Deterministic Extensions
* **SML v2.0 Syntax Validation (`--validate-sml`)**: Deterministic verification of LLM output against the SML v2.0 EBNF syntax standard (`SML_VERSION: 2.0`, `LISTEN_SUMMARY:`, `CONVERSATION_OUTCOME:`, `PROPOSED_TRANSITION:`, `EVIDENCE_TYPE:`).
* **REGEX Validation (`--validate-regex <expr>`)**: Formal response validation against a POSIX Extended Regular Expression.
* **Canonical Error Code 13 (`BASH4LLM_ERR_PARSE`)**: Introduced constant error code `13` (`BASH4LLMERR_PARSE`) to signal JSON parse errors or failed SML/REGEX syntax checks.
* **ANSI Output Sanitization (`--sanitize`)**: Zero-eval filtering of ANSI escape sequences and non-printable characters by delegating to `extras/security/output-sanitizer.sh` or POSIX fallback.
* **Structured JSON Diagnostics (`--json-diagnostics`)**: Emission of formatted JSON error logs (`emit_json_diagnostics`) containing status, code, reason, message, and UTC timestamp.

### Provider Architecture, Trust Domains & API Contract
* **Provider API Version Contract (`BASH4LLM_SUPPORTED_PROVIDER_API=1`)**: Introduced interface version control for external provider modules (`BASH4LLM_PROVIDER_API_VERSION`), aborting import with exit code 98 in case of incompatibility.
* **Explicit Trust Domains**: Flexible provider resolution via domain prefix (`builtin:`, `vendor:`, `local:`). Added `local-extras/providers/` directory for user local modules not tracked by the vendor manifest.
* **Anti-Hijacking Whitelist Export Filter (`comm -13`)**: Provider module importing captures and exports to the main shell **strictly the 8 authorized interface functions**, blocking injection of arbitrary code or functions.
* **Extended Provider Interface**: Added optional functions `validate_model_<provider>()` and `auto_select_model_<provider>()`.

### Thread Engine, CLI Interface & Tooling
* **Thread CRUD CLI Commands**:
  * `--init-thread`: Manual context and metadata initialization for a new thread.
  * `--delete-thread <id>`: Atomic deletion of NDJSON history, locks, and thread metadata.
  * `--rename-thread <id> --title <title>`: Atomic title renaming in thread metadata.
* **Local Thread Caching with TTL**: Implemented isolated caching in `config/thread_cache/` to optimize message window reads.
* **Path Inspection & Raw Listing Options**: Added flags `--print-config-dir`, `--print-provider-file`, `--print-model-file [provider]`, `--list-providers-raw`, and `--list-models-raw`.
* **Vault Console & Shell Completion**: Direct launch of Key Vault console via `--vault` and loading of shell completion script `extras/docs/bash4llm-completion.sh`.

### Test Suite, CI/CD & Documentation
* **SCINTILLA Core T3 Module (`scintilla-t3.sh`)**: Added new dedicated test suite to the Master Test Runner (`--run-all-tests`) for automated verification of `--validate-sml`, `--validate-regex`, `--sanitize`, and `--json-diagnostics` flags.
* **Documentation & Specs Alignment**: Full alignment of `docs/bash4llm-arch-spec.md`, `README.md`, `INSTALL.md`, `SECURITY.md`, `PROVIDERS.md`, and `llms.txt` to version 2.8.5.

---

*This release notes document corresponds to release <a href='https://github.com/kamaludu/bash4llm/releases/tag/v2.8.5'>Bash4LLM v2.8.5</a>.*
