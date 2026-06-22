[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Changelog

## [Unreleased]
- Additional documentation improvements
- Optional enhancements for extras and test suites

---

## [2.0.0] – 2026‑06‑20 - [RELEASE NOTES](RELEASE-NOTES.md)
### Added
- Rebranding completo da *GroqBash* a *Bash4LLM* (v2.0.0) con aggiornamento della struttura del repository.
- Supporto per Session Engine modulare con integrazione opzionale del modulo esterno `session-engine.sh`.
- Gestore di sessione MVP nativo (`session_append`, `session_read_window`) con deduplicazione dei messaggi cross-processo basata su marcatori.
- Sistema integrato di cache delle risposte (`session_cache_get`, `session_cache_set`) con TTL configurabile per ridurre le chiamate API ripetute.
- Gestore di stato centralizzato per le interfacce grafiche (`ui_state_write`) con salvataggio atomico di file JSON in `ui_state/`.
- Nuove opzioni CLI per output automatizzato e machine-readable: `--list-providers-raw` e `--list-models-raw`.
- Nuova opzione `--bootstrap-only` per consentire l'inizializzazione strutturale dello shell senza effetti collaterali a runtime.
- Standardizzazione dei codici di errore tramite l'uso di costanti canoniche (`BASH4LLM_ERR_*`).

### Changed
- Riorganizzazione del layout di runtime, consolidando tutte le risorse e configurazioni all'interno della directory `bash4llm.d/` (migrando `extras`, `config`, `history` e `tmp`).
- Riprogettazione della scrittura temporanea tramite l'helper sicuro `_tmpf`, vincolando tutte le operazioni all'interno del perimetro validato di `BASH4LLM_TMPDIR`.
- Unificazione dell'elaborazione Base64 multi-piattaforma tramite wrapper interni (`b64encode`/`b64decode`).
- Isolamento del caricamento dei moduli provider esterni tramite cattura in subshell e importazione controllata delle funzioni.
- Potenziamento di `lock_exec` con l'introduzione di un fallback atomico basato su directory per sistemi macOS/Darwin privi di `flock`.
- Ottimizzazione della pipeline di streaming SSE con la rimozione del comando `tee` per azzerare i ritardi di buffering e garantire una risposta immediata.

### Fixed
- Rafforzate le barriere di sicurezza vietando esplicitamente l'uso di `/tmp` o delle sue sotto-cartelle per `BASH4LLM_TMPDIR`.
- Risolti i crash dovuti al dynamic linker su ambienti Termux (Android) rimuovendo `stdbuf` dalla pipeline di streaming.
- Risolti potenziali errori di variabile non definita sotto `set -u` (es. inizializzazione di `http_code` durante il fallback dello stream).
- Corretto il comportamento di normalizzazione dei prefissi durante la validazione e l'auto-selezione dei modelli con namespace personalizzati.
- Impedita la scrittura di messaggi vuoti dell'utente all'interno dei file di cronologia.

---

## [1.0.0] – 2026‑01‑23 - [RELEASE NOTES](RELEASE-NOTES.md)
[![Announcements](https://img.shields.io/badge/GroqBash-Announcements-green?logo=github)](https://github.com/kamaludu/groqbash/discussions/127)

### Added
- Full security‑hardened release after STEP 5.6 → STEP 7.2 audit cycle
- Dynamic model whitelist using Groq Models API (`/openai/v1/models`)
- External help system (`extras/docs/help.txt`)
- Provider module system (`extras/providers/`)
- Optional advanced tools:
  - `extras/security/verify.sh` (provider integrity checks)
  - `extras/security/validate-env.sh` (environment validation)
  - `extras/test/json-sse-suite.sh` (JSON/SSE parsing tests)
- `--install-extras` installer (idempotent, safe)
- Interactive provider selection (`--provider` without argument)
- Secure temporary directory handling (no `/tmp`, strict permissions)
- Automatic output saving with configurable threshold
- Streaming and non‑streaming response handling
- Debug mode with preserved temp files
- Complete documentation set: README, README‑it, INSTALL, SECURITY, CHANGELOG

### Changed
- Major hardening of provider loading:
  - directory permission checks
  - file‑level owner/permission/symlink checks
  - minimal TOCTOU mitigation
  - before/after integrity check now uses `getfile_signature()` (stat/find) instead of `ls -ld`
- Improved JSON escaping and SSE parsing robustness
- Unified banner and header across all scripts
- More consistent CLI behavior and error messages
- CURL options unified via array (`CURLBASEOPTS[@]`) to eliminate SC2086
- Centralized DRY‑RUN behavior with single payload preview point
- Improved streaming parsing using `jq -R -c 'fromjson?'`
- Consistent tmpdir initialization via `ensureruntmpdir()`

### Fixed
- Removed unsafe fallback temp paths
- Eliminated legacy parsing logic and deprecated model fallbacks
- Corrected edge cases in model auto‑selection policy
- Replaced fragile `A && B || C` logic with explicit `if` block (SC2015)
- Removed all remaining `ls -ld` fallbacks (SC2012)
- Quoting fixes for exit codes (SC2086)
- Resolved unbound‑variable edge cases under `set -euo pipefail`

---

## [0.12.0] – 2026‑01‑19
### Added
- Core CLI options: `--refresh-models`, `--list-models`, `--dry-run`, `--debug`
- Automatic output saving beyond threshold
- Documentation: README, INSTALL, CHANGELOG, CONTRIBUTING

---

## [0.11.1] – 2026‑01‑18
### Added
- First public version with Groq API model whitelist support

---

## [Initial]
- Minimal repository structure
- First prototype of `bash4llm` with basic model refresh
- Essential documentation

---

*Note: Some sections of the codebase were drafted or refined with the assistance of AI tools.  
Architecture, design, and final decisions remain manually curated.*
