[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Changelog

## [Unreleased]
 * Additional documentation improvements
 * Optional enhancements for extras and test suites

## [2.6.0] – 2026‑07‑22 - RELEASE NOTES
### Added
 * Verifica dell'integrità crittografica dei moduli (`verify_module_integrity`) tramite file manifesto SHA-256 (`extras/manifest.sha256`) per tutti i provider esterni, estensioni ed hook.
 * Anonimizzazione automatica PII dei Thread ID (`anonymize_thread_id`) tramite hashing SHA-256 (`SAFE_THREAD_ID`), impedendo la scrittura di dati personali (es. email o nomi utente) in chiaro sul filesystem (.ndjson, .json, lock e rate-limit).
 * Motore locale di rate-limiting a finestra scorrevole su base 30s (`check_local_rate_limit`) per prevenire richieste eccessive o attacchi DOS per thread (`BASH4LLM_RATE_LIMIT`), con supporto per token di autorizzazione di bypass (`BASH4LLM_AUTH_TOKEN`).
 * Esecuzione isolata degli hook pre/post esecuzione (`execute_isolated_hook`) in subshell pulite con stripping delle chiavi API in memoria e parsing Zero-Eval delle variabili dinamiche (`FALLBACK_PAYLOAD`).
 * Nuovi comandi CLI per la gestione completa dei thread: `--delete-thread <id>` (rimozione atomica con purga di log e indici), `--rename-thread <id> --title <testo>` (rinomina del titolo utente) e `--init-thread` (pre-registrazione della struttura senza chiamate di rete).
 * Nuove opzioni CLI per la query immediata dei percorsi di sistema canonici: `--print-config-dir`, `--print-provider-file` e `--print-model-file <provider>`.
 * Supporto al sblocco della sessione Vault in memoria RAM tramite sourcing (`. ./bash4llm`) gestito dal token di contesto `_B4L_RT_CTX`.
 * Isolamento strutturale delle directory di runtime e di sincronizzazione con la creazione della cartella dedicata `bash4llm.d/var/run/locks/` (permessi 700).
### Changed
 * Riprogettata la funzione `read_secure_input` per supportare un comportamento duale: nasconde l'input via TTY (`stty -echo`) in modalità interattiva (`[ -t 0 ]`) e legge direttamente dallo `stdin` in caso di esecuzione automatizzata via pipe (`! [ -t 0 ]`), azzerando i blocchi di processo.
 * Spostata la collocazione dei file di blocco (`models.lock`, `tmp.lock`) dalla cartella temporanea alla directory isolata di runtime `var/run/locks/`.
 * Aggiornato il linter statico della configurazione (`--check-config`) e la spiegazione degli errori (`--explain-error`) per supportare le nuove variabili canoniche e la costante `BASH4LLM_ERR_SEC` (17).
### Fixed
 * Risolto un deadlock d'I/O (hang indefinito) durante l'inizializzazione non interattiva del Vault e l'invio di password o segreti via pipe (`printf | vault_init`).
 * Eliminata una vulnerabilità nel runner degli hook che eseguiva gli script di estensione senza verificare preventivamente la corrispondenza dell'hash SHA-256 contro il file manifesto.
 * Rafforzata la validazione dei file di input in `validate_file_input` per escludere universalmente byte nulli (`\x00`) e caratteri di controllo non stampabili prima di qualsiasi valutazione di comando.

## [2.5.0] – 2026‑07‑18 - RELEASE NOTES
### Added
 * Estensione Security Vault (openssl-helper.sh) per la gestione e cifratura at-rest delle chiavi API (AES-256-CBC, PBKDF2 con 100.000 iterazioni), supporto al token di sessione in memoria _B4L_RT_CTX e distruzione fisica anti-forensic dei dati tramite shred/dd.
 * Estensione Session Engine (session-engine.sh) con segmentazione automatica dei log NDJSON al superamento di 1MB, compressione nativa gzip dei segmenti obsoleti e algoritmo di calcolo della finestra dinamico basato su byte-budget (modalità N=0).
 * Meccanismo di caching associativo in-process (BASH4LLM_MODEL_CACHE) per la normalizzazione dei modelli, azzerando l'overhead di fork causato dall'apertura di sotto-shell ricorsive.
 * Rilevamento automatico dell'ambiente mobile Android/Termux (via TERMUX_VERSION) con deviazione trasparente e sicura dei lock concorrenti su directory atomiche (mkdir).
 * Parser documentale "Zero-Eval" scritto in awk conforme POSIX per l'estrazione statica delle definizioni da core-notes.sh senza esecuzione di codice.
 * Gestione integrata dei manifesti multimediali per payload strutturati (JSON accoppiato a una versione specchio .b64) per lo staging transazionale degli asset.
 * Nuove opzioni diagnostiche CLI ad intercettazione precoce: --check-config (linter statico dei permessi e delle chiavi) e --explain-error (risoluzione e mitigazione dei codici di stato).
 * Indice globale centralizzato dei thread conversazionali all'interno del gestore di stato dell'interfaccia utente (ui_state/threads/index.json).
 * Nuova costante canonica d'errore dedicata per violazioni del file-system e delle policy di sicurezza: BASH4LLM_ERR_SEC (Valore 17).
### Changed
 * Ridotto il numero di binari obbligatori nel PATH da 24 a 23, rimuovendo il controllo bloccante sull'utility flock per massimizzare la portabilità cross-piattaforma.
 * Hardening del caricatore dei moduli esterni (load_provider_module): rifiuto tassativo di symlink, file group/world-writable o appartenenti a utenti diversi dall'esecutore, affiancato da una doppia verifica di integrità crittografica SHA-256 pre/post sourcing.
 * Vincolata l'invariante di atomicità delle scritture sul file-system, imponendo che la generazione dei file temporanei avvenga nella stessa partizione fisica/inode del file di destinazione per garantire l'atomicità della chiamata di sistema mv.
### Fixed
 * Mitigati potenziali attacchi di tipo Directory Traversal e Privilege Escalation stringendo le regole di verifica dei percorsi interni nell'allocazione risorse via _tmpf.
 * Corretti i comportamenti di validazione dei file di input all'interno di validate_file_input, garantendo l'esclusione universale e indipendente dal locale di byte nulli o caratteri di controllo C0.
 * Risolti i problemi di ridondanza e loop nei log conversazionali implementando un controllo di deduplicazione crittografica via hash SHA-256 basato su una finestra scorrevole (BASH4LLM_SESSION_DEDUP_WINDOW).

## [2.0.0] – 2026‑06‑20 - RELEASE NOTES
### Added
 * Rebranding completo da *GroqBash* a *Bash4LLM* (v2.0.0) con aggiornamento della struttura del repository.
 * Supporto per Session Engine modulare con integrazione opzionale del modulo esterno session-engine.sh.
 * Gestore di sessione MVP nativo (session_append, session_read_window) con deduplicazione dei messaggi cross-processo basata su marcatori.
 * Sistema integrato di cache delle risposte (session_cache_get, session_cache_set) con TTL configurabile per ridurre le chiamate API ripetute.
 * Gestore di stato centralizzato per le interfacce grafiche (ui_state_write) con salvataggio atomico di file JSON in ui_state/.
 * Nuove opzioni CLI per output automatizzato e machine-readable: --list-providers-raw e --list-models-raw.
 * Nuova opzione --bootstrap-only per consentire l'inizializzazione strutturale dello shell senza effetti collaterali a runtime.
 * Standardizzazione dei codici di errore tramite l'uso di costanti canoniche (BASH4LLM_ERR_*).
### Changed
 * Riorganizzazione del layout di runtime, consolidando tutte le risorse e configurazioni all'interno della directory bash4llm.d/ (migrando extras, config, history e tmp).
 * Riprogettazione della scrittura temporanea tramite l'helper sicuro _tmpf, vincolando tutte le operazioni all'interno del perimetro validato di BASH4LLM_TMPDIR.
 * Unificazione dell'elaborazione Base64 multi-piattaforma tramite wrapper interni (b64encode/b64decode).
 * Isolamento del caricamento dei moduli provider esterni tramite cattura in subshell e importazione controllata delle funzioni.
 * Potenziamento di lock_exec con l'introduzione di un fallback atomico basato su directory per sistemi macOS/Darwin privi di flock.
 * Ottimizzazione della pipeline di streaming SSE con la rimozione del comando tee per azzerare i ritardi di buffering e garantire una risposta immediata.
### Fixed
 * Rafforzate le barriere di sicurezza vietando esplicitamente l'uso di /tmp o delle sue sotto-cartelle per BASH4LLM_TMPDIR.
 * Risolti i crash dovuti al dynamic linker su ambienti Termux (Android) rimuovendo stdbuf dalla pipeline di streaming.
 * Risolti potenziali errori di variabile non definita sotto set -u (es. inizializzazione di http_code durante il fallback dello stream).
 * Corretto il comportamento di normalizzazione dei prefissi durante la validazione e l'auto-selezione dei modelli con namespace personalizzati.
 * Impedita la scrittura di messaggi vuoti dell'utente all'interno dei file di cronologia.

## [1.0.0] – 2026‑01‑23 - RELEASE NOTES
Announcements
### Added
 * Full security‑hardened release after STEP 5.6 → STEP 7.2 audit cycle
 * Dynamic model whitelist using Groq Models API (/openai/v1/models)
 * External help system (extras/docs/help.txt)
 * Provider module system (extras/providers/)
 * Optional advanced tools:
   * extras/security/verify.sh (provider integrity checks)
   * extras/security/validate-env.sh (environment validation)
   * extras/test/json-sse-suite.sh (JSON/SSE parsing tests)
 * --install-extras installer (idempotent, safe)
 * Interactive provider selection (--provider without argument)
 * Secure temporary directory handling (no /tmp, strict permissions)
 * Automatic output saving with configurable threshold
 * Streaming and non‑streaming response handling
 * Debug mode with preserved temp files
 * Complete documentation set: README, README‑it, INSTALL, SECURITY, CHANGELOG
### Changed
 * Major hardening of provider loading:
   * directory permission checks
   * file‑level owner/permission/symlink checks
   * minimal TOCTOU mitigation
   * before/after integrity check now uses getfile_signature() (stat/find) instead of ls -ld
 * Improved JSON escaping and SSE parsing robustness
 * Unified banner and header across all scripts
 * More consistent CLI behavior and error messages
 * CURL options unified via array (CURLBASEOPTS[@]) to eliminate SC2086
 * Centralized DRY‑RUN behavior with single payload preview point
 * Improved streaming parsing using jq -R -c 'fromjson?'
 * Consistent tmpdir initialization via ensureruntmpdir()
### Fixed
 * Removed unsafe fallback temp paths
 * Eliminated legacy parsing logic and deprecated model fallbacks
 * Corrected edge cases in model auto‑selection policy
 * Replaced fragile A && B || C logic with explicit if block (SC2015)
 * Removed all remaining ls -ld fallbacks (SC2012)
 * Quoting fixes for exit codes (SC2086)
 * Resolved unbound‑variable edge cases under set -euo pipefail

## [0.12.0] – 2026‑01‑19
### Added
 * Core CLI options: --refresh-models, --list-models, --dry-run, --debug
 * Automatic output saving beyond threshold
 * Documentation: README, INSTALL, CHANGELOG, CONTRIBUTING

## [0.11.1] – 2026‑01‑18
### Added
 * First public version with Groq API model whitelist support

## [Initial]
 * Minimal repository structure
 * First prototype of bash4llm with basic model refresh
 * Essential documentation

*Note: Some sections of the codebase were drafted or refined with the assistance of AI tools.
Architecture, design, and final decisions remain manually curated.*
