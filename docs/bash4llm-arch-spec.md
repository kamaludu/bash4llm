# SPECIFICA TECNICA DEL SISTEMA BASH4LLM⁺ (v2.6.0)

## SEZIONE 1: ARCHITETTURA GENERALE E RELAZIONI TRA MACRO-SEZIONI

Il sistema Bash4LLM⁺ è strutturato su un'architettura **Lean & Flat** composta da **5 Macro-Sezioni (Livello 0)** e **23 Sezioni Piatte (Livello 1)** senza sottosezioni intermedie. La stabilità e l'integrazione del runtime sono garantite da una gerarchia di dipendenze, requisiti di sistema rigorosi e costanti di sicurezza applicate a livello di file-system.

```text
[PRECORE_BOOT] ──> [PRECORE_RUN] ──> [PROVIDER] ──> [CORE_SETUP] ──> [CORE_PROVIDER]
   (7 Sezioni)        (5 Sezioni)     (Groq Direct)   (7 Sezioni)        (4 Sezioni)
```

### 1.1 Dipendenze tra Sezioni
*   **PRECORE_RUN**: Dipende da `PRECORE_BOOT` per il caricamento dei percorsi canonici, la gestione delle variabili di ambiente, gli helper di sicurezza/integrità (`BOOT_SECURITY`), l'utilità di acquisizione dei lock esclusivi (`lock_exec`), la verifica di integrità dei moduli (`verify_module_integrity`) e l'inizializzazione sicura della directory temporanea (`ensure_run_tmpdir`).
*   **SECURITY EXTENSION (openssl-helper.sh)**: Estensione facoltativa caricata durante il bootstrap se abilitata da `BASH4LLM_VAULT_ENABLED`. Fornisce la decrittografia in memoria delle chiavi API e i servizi di hashing/diagnostica SSL.
*   **SESSION ENGINE EXTENSION (session-engine.sh)**: Estensione facoltativa caricata durante la configurazione iniziale per la gestione avanzata dei thread (segmentazione, compressione e caching). Se assente o disabilitata, il sistema esegue un fallback trasparente sulla logica NDJSON del core.
*   **PROVIDER**: Dipende da `PRECORE_BOOT` e `PRECORE_RUN` per la risoluzione degli URL degli endpoint, la verifica delle autorizzazioni di rete, lo staging transazionale dei payload, il buffering dell'I/O e la scrittura atomica dei log e degli stati della UI.
*   **CORE_SETUP**: Dipende da `PRECORE_BOOT`, `PRECORE_RUN` e `PROVIDER` per il dispatching delle chiamate specifiche dei provider, la convalida formale dei parametri CLI, l'estrazione sintattica delle whitelist e l'integrazione delle estensioni esterne.
*   **CORE_PROVIDER**: Dipende da tutte le sezioni precedenti per il caricamento protetto dei moduli provider esterni, l'inizializzazione del menu interattivo, l'allineamento dei modelli, l'assemblaggio del prompt (`PROMPT_ASSEMBLY`) e la gestione dello smistamento delle pipeline di esecuzione (`PIPELINE_EXEC`).

### 1.2 Requisiti Obbligatori di Sistema
Prima di consentire qualunque prima elaborazione, lo script core verifica la presenza nel `PATH` dei seguenti **23 binari ed utility essenziali**. L'assenza di almeno uno di essi causa l'arresto immediato dello script con codice di stato `15`:
1. `bash` • 2. `jq` • 3. `curl` • 4. `mktemp` • 5. `stat` • 6. `base64` • 7. `find` • 8. `awk` • 9. `sed` • 10. `grep` • 11. `xargs` • 12. `tr` • 13. `sort` • 14. `head` • 15. `wc` • 16. `tee` • 17. `date` • 18. `mv` • 19. `chmod` • 20. `cp` • 21. `rm` • 22. `printf` • 23. `comm`.
*Nota: L'utility `flock` è esclusa da questo ciclo di controllo per consentire l'esecuzione e il fallback automatico su piattaforme che non la supportano nativamente (come Termux).*

### 1.3 Invarianti Globali di Sicurezza e File-System
Il runtime di Bash4LLM⁺ impone regole di isolamento e protezione dei dati persistenti e temporanei per prevenire attacchi di tipo privilege escalation, race condition o directory traversal:
*   **Isolamento dei File Temporanei e delle Directory di Runtime**: La directory principale `$BASH4LLM_TMPDIR` deve risiedere interamente all'interno della cartella radice `$BASH4LLM_DIR`. È vietato l'uso della cartella globale `/tmp` del sistema operativo. Le operazioni di processo risiedono in `$BASH4LLM_RUN_DIR` (`var/run`), i file di lock in `$BASH4LLM_LOCKS_DIR` (`var/run/locks`) e il tracciamento del rate limiting in `$BASH4LLM_RATES_DIR` (`tmp/rates`).
*   **Rilevamento Ambiente Mobile (Android/Termux)**: Sotto ambiente Termux, l'uso di `flock` a livello kernel è inibito o instabile. Lo script rileva automaticamente l'ambiente (tramite `TERMUX_VERSION`) e devia in trasparenza tutte le richieste di lock sul meccanismo atomico di directory lock (`mkdir`).
*   **Mitigazione Attacchi Symlink**: All'avvio, viene verificato che nessuna delle directory operative dello script o file di estensione sia un collegamento simbolico. Se viene rilevato un symlink su un percorso sensibile, l'esecuzione viene interrotta con codice d'errore `BASH4LLM_ERR_SEC` (17) o `BASH4LLM_ERR_TMP` (15).
*   **Controllo dei Permessi e Maschera Umask**: All'avvio viene applicata la maschera di processo `umask 077`. Tutte le directory operative vengono create o forzate con permessi `700` (accesso esclusivo per l'utente proprietario). Tutti i file generati vengono blindati con permessi `600`.
*   **Proprietà dei Moduli Esterni e Integrità Crittografica**: Qualunque estensione, modulo provider esterno o script di hook deve appartenere all'utente esecutore corrente, non deve presentare permessi di scrittura pubblici o di gruppo (`group/world-writable`) e deve superare la verifica dell'hash SHA-256 contro `extras/manifest.sha256`.
*   **Invariante del File-System per Atomicità**: Ogni operazione di scrittura atomica viene eseguita scrivendo in un file temporaneo situato all'interno dello stesso file-system (stessa partizione fisica) del file di destinazione finale. Questo assicura che lo spostamento (`mv`) si traduca in una singola chiamata di sistema atomica a livello di inode, escludendo il rischio di corruzione dei dati.

---

## SEZIONE 2: PRECORE_BOOT

Questa macro-sezione gestisce l'inizializzazione primaria della shell, l'analisi preventiva degli argomenti CLI, la convalida dell'ambiente operativo, la sicurezza dei percorsi e l'esposizione delle funzioni fondamentali di logging, codifica e I/O. È suddivisa in **7 Sezioni Piatte**.

### 2.1 Variabili di PRECORE_BOOT
*   **SCRIPT_NAME**: Nome identificativo del programma (costante: `"bash4llm"`).
*   **SCRIPT_VERSION**: Versione corrente del software (costante: `"2.6.0"`).
*   **SCRIPT_DATE**: Data di rilascio del software (costante: `"2026-07-21"`).
*   **Costanti d'Errore Globali**:
    *   `BASH4LLM_ERR_NO_API_KEY` (Valore `10`): Assenza di una chiave API valida.
    *   `BASH4LLM_ERR_BAD_MODEL` (Valore `11`): Modello non supportato, non valido o escluso.
    *   `BASH4LLM_ERR_CURL_FAILED` (Valore `12`): Fallimento di rete o errore di curl.
    *   `BASH4LLM_ERR_NO_PROMPT` (Valore `14`): Assenza di prompt testuale o JSON di input.
    *   `BASH4LLM_ERR_TMP` (Valore `15`): Errore di I/O, permessi o lock sui file temporanei.
    *   `BASH4LLM_ERR_API` (Valore `16`): Errore applicativo o codice HTTP non valido inviato dalle API.
    *   `BASH4LLM_ERR_SEC` (Valore `17`): Violazione delle politiche di sicurezza, permessi o fallimento di integrità.
*   **Alias delle Costanti**: `BASH4LLMERR_NO_API_KEY` (10), `BASH4LLMERR_BAD_MODEL` (11), `BASH4LLMERR_CURL_FAILED` (12), `BASH4LLMERR_NO_PROMPT` (14), `BASH4LLMERR_TMP` (15), `BASH4LLMERR_API` (16), `BASH4LLMERR_SEC` (17).
*   **Variabili Lette**:
    *   `DEBUG`, `BASH4LLM_DEBUG`: Configurazione dei tracciamenti di sviluppo.
    *   `BASH4LLM_DIR`, `BASH4LLM_ROOT`: Percorso radice di installazione.
    *   `BASH4LLM_CONFIG_DIR`, `BASH4LLM_MODELS_DIR`, `BASH4LLM_TEMPLATES_DIR`, `BASH4LLM_HISTORY_DIR`, `BASH4LLM_TMPDIR`, `BASH4LLM_RUN_DIR`, `BASH4LLM_LOCKS_DIR`, `BASH4LLM_RATES_DIR`, `BASH4LLM_EXTRAS_DIR`, `PROVIDERS_DIR`: Directory di lavoro operative.
    *   `MAX_STAGE_BYTES`: Soglia massima di byte per i payload Base64 (default `10485760` byte, pari a 10MB).
    *   `MAX_MODELS`: Limite massimo di modelli locali (default `200`).
    *   `BASH4LLM_LOG`: Percorso del file di tracciamento centralizzato.
    *   `BASH4LLM_LOCK_TIMEOUT_TMP`, `BASH4LLM_LOCK_TIMEOUT_MODELS`, `BASH4LLM_LOCK_TIMEOUT_HISTORY`: Timeout per i lock esclusivi (default `10` secondi).
    *   `BASH4LLM_VAULT_ENABLED`: Controlla l'attivazione dell'estensione del Vault crittografato OpenSSL (default `1`).
    *   `BASH4LLM_IGNORE_SEC_CHECKS`: Ignora i controlli di proprietà POSIX se impostato a 1 (utile per WSL/Cygwin).
*   **Variabili Scritte/Modificate**:
    *   `SCRIPTDIR`: Risoluzione assoluta del percorso dello script.
    *   `CANONICAL_EXTRAS_DIR`, `LEGACY_EXTRAS_DIR`: Percorsi normalizzati delle estensioni.
    *   `MODELS_FILE`: File locale della whitelist dei modelli (`<provider>.txt`).
    *   `PROVIDER_FILE`: File locale contenente l'ultimo provider selezionato (`provider`).
    *   `THREAD_DIR`: Cartella di registrazione dei log NDJSON dei thread (`history/threads`).
    *   `MODELS_LOCK`, `HISTORY_LOCK`, `TMP_LOCK`: Percorsi dei rispettivi file di lock esclusivi sotto `var/run/locks`.
    *   `B64_WRAP_OPT`, `B64_DECODE_OPT`: Opzioni e flag di formattazione rilevati per il comando `base64`.
    *   `RUN_TMPDIR`, `PAYLOAD`, `RESP`, `ERRF`: Canali e cartelle temporanee del runtime di istanza.
    *   `BASH4LLM_OPENSSL_ACTIVE`: Flag booleano che attesta la disponibilità operativa del modulo OpenSSL.
    *   `SAFE_THREAD_ID`: Identificatore del thread anonimizzato crittograficamente tramite SHA-256.

### 2.2 Mappatura Funzionale per Sezione in PRECORE_BOOT

#### Sezione 1: `PRECORE_BOOT_SETUP_SHELL`
*   **Attività**: Imposta `set -euo pipefail` solo se lo script è eseguito direttamente per non inquinare la shell interattiva dell'utente in caso di sourcing. Disabilita i core dumps (`ulimit -c 0`), esegue l'autodetect della piattaforma (Android/Termux, macOS, WSL, Cygwin, BSD, Linux), resetta i flag d'ambiente e definisce le costanti degli errori e i codici colore ANSI.

#### Sezione 2: `PRECORE_BOOT_SETUP_ENV_CMDS`
*   **Attività**: Verifica la versione di Bash ($\ge 4.0$) e la presenza nel `PATH` dei 23 binari obbligatori.

#### Sezione 3: `PRECORE_BOOT_EARLY_UTILITIES`
*   **Funzioni**: `resolve_script_dir`, `safe_mkdir`, `check_required_arg`, `canonical_config_dir`, `canonical_provider_file`, `canonical_model_file`, `canonical_provider_url_file`, `trim_space`, `sync_models_file_path`, `_normalize_model_name`, `is_truthy`, `_extract_notes_section`, `log_prefix`, `log_info`, `log_warn`, `log_error`, `log_info_user`, `dbg`.
*   **Attività**: Utility fondamentali di calcolo percorsi, manipolazione stringhe, cache associativa di normalizzazione modelli, parsing Zero-Eval della documentazione e motore di logging strutturato.

#### Sezione 4: `PRECORE_BOOT_SECURITY`
*   **Funzioni**: `validate_file_input`, `read_secure_input`, `_get_perm_string`, `_get_owner`, `validate_path_security`, `_core_sha256`, `verify_module_integrity`, `ensure_api_key_for_provider`, `enforce_network_policy`.
*   **Attività**: Isolamento completo dei meccanismi di sicurezza: validazione byte nulli/caratteri di controllo, prompt TTY silenziato (`stty -echo`), controlli di proprietà e permessi POSIX, verifica crittografica SHA-256 contro il manifesto, risoluzione sicura della chiave API (con integrazione Key Vault) ed enforcement della politica di rete.

#### Sezione 5: `PRECORE_BOOT_DIR_PATH`
*   **Funzioni**: `ensure_config_dir`, `write_provider_url_if_missing`, `resolve_provider_url`.
*   **Attività**: Inizializzazione fisica dell'albero delle directory di lavoro (`var/run`, `locks`, `tmp`), caricamento dell'helper OpenSSL se presente e risoluzione/registrazione transazionale degli URL di connessione dei provider.

#### Sezione 6: `PRECORE_BOOT_STORAGE_LOCKS`
*   **Funzioni**: `provider_api_env_var_name`, `print_persistence_reminder`, `is_valid_json_string`, `b64encode`, `b64decode`, `file_size`, `is_valid_json_file`, `stage_b64`, `lock_exec`, `_mktemp_in_dir`, `show_payload_head`, `atomic_write`, `extract_text_from_resp`, `cleanup_run_tmp_on_exit`, `ensure_run_tmpdir`, `b64_atomic_write`, `b64_atomic_read`, `ui_state_write`, `run_static_config_check`, `explain_error_code`.
*   **Attività**: Gestione delle primitive I/O ad alte prestazioni: codifica/decodifica Base64, staging dei payload, locking atomico cross-processo (`lock_exec`), gestione del ciclo di vita di `$RUN_TMPDIR`, scritture atomiche sul filesystem, estrazione del testo dalle risposte, linter statico di configurazione e spiegazione formale dei codici d'errore.

#### Sezione 7: `PRECORE_BOOT_CLI_HELPERS`
*   **Funzioni**: `load_provider_module`, `_detect_base64_opts`, `list_files_sorted_by_mtime`, `tac_fallback`, `_file_mtime`, `jq_safe`.
*   **Attività**: Intercettazione precoce dei flag CLI di diagnostica (`--check-config`, `--explain-error`, `--print-*`), rilevamento opzioni `base64`, definizione delle costanti di lock e caricamento in sandbox isolata dei moduli provider esterni (`load_provider_module`).

### 2.3 Flussi e Blocchi Logici di PRECORE_BOOT
*   **PRECORE_BOOT_SETUP_SHELL**: Imposta `set -euo pipefail` solo se lo script è eseguito direttamente per non inquinare la shell interattiva dell'utente in caso di sourcing.
*   **PRECORE_BOOT_SETUP_ENV_CMDS**: Verifica la presenza dei 23 comandi di sistema obbligatori.
*   **PRECORE_BOOT_EARLY_UTILITIES**: Carica le primitive fondamentali di directory, URL, normalizzazione e logging.
*   **PRECORE_BOOT_SECURITY**: Esegue i controlli di integrità crittografica, permessi POSIX e acquisizione sicura delle credenziali API.
*   **PRECORE_BOOT_DIR_PATH**: Configura l'albero delle directory di lavoro operative (`var/run`, `locks`, `tmp`).
*   **PRECORE_BOOT_STORAGE_LOCKS**: Espone Base64, staging, lock_exec, atomic_write e controlli di static linting.
*   **PRECORE_BOOT_CLI_HELPERS**: Intercetta precocemente le opzioni CLI di diagnostica o ispezione percorsi (`--print-*`, `--check-config`, `--explain-error`) ed esegue l'arresto immediato.

---

## SEZIONE 3: PRECORE_RUN

Questa macro-sezione gestisce la persistenza a lungo termine, la rotazione dello storico, i manifesti per allegati multimodali e il motore unificato di gestione dei thread NDJSON. È suddivisa in **5 Sezioni Piatte**.

### 3.1 Variabili di PRECORE_RUN
*   **Variabili Lette**:
    *   `BASH4LLM_ROTATE_HISTORY`: Attiva la rotazione e manutenzione automatica dello storico (default `0`).
    *   `BASH4LLM_HISTORY_MAX_FILES` (default `100`), `BASH4LLM_HISTORY_MAX_BYTES` (default 100MB), `BASH4LLM_HISTORY_KEEP_DAYS` (default `90`).
    *   `THREAD_ID`: Identificatore del thread attivo.
    *   `SAFE_THREAD_ID`: Identificatore del thread anonimizzato crittograficamente tramite SHA-256.
    *   `THREAD_WINDOW`: Dimensione della finestra dei messaggi storici da recuperare (default `10`).
    *   `BASH4LLM_RATE_LIMIT`: Limite di richieste API per thread nella finestra di 30s (default `unlimited`).
    *   `BASH4LLM_AUTH_TOKEN`: Token autorizzato per scavalcare il limitatore di frequenza locale.
    *   `FALLBACK_PAYLOAD`: Payload di riserva codificato in Base64 restituito dagli hook in caso di errori API.
    *   `BASH4LLM_SESSION_ENGINE`: Controlla l'attivazione del modulo avanzato di gestione sessioni (default `"on"`).
*   **Variabili Scritte/Modificate**:
    *   `THREAD_DIR`: Percorso della directory contenente i file NDJSON dei thread (`history/threads`).
    *   `BASH4LLM_RATES_DIR`: Directory di tracciamento delle transazioni del rate limiter (`tmp/rates`).
    *   Aggiornamento dei registri e metadati in `ui_state/threads/`.

### 3.2 Mappatura Funzionale per Sezione in PRECORE_RUN

#### Sezione 1: `PRECORE_RUN_HISTORY`
*   **Funzioni**: `rotate_history`, `save_to_history`.
*   **Attività**: Salvataggio degli output su disco e motore di rotazione O(N) basato su limite file, dimensione complessiva in byte e giorni di conservazione.

#### Sezione 2: `PRECORE_RUN_MANIFEST`
*   **Funzioni**: `manifest_create`, `manifest_add_part`, `manifest_read`.
*   **Attività**: Creazione e aggiornamento protetto da lock dei manifesti JSON/Base64 per la gestione degli allegati multimodali.

#### Sezione 3: `PRECORE_RUN_UTIL_HELPERS`
*   **Funzioni**: `anonymize_thread_id`, `execute_isolated_hook`, `_get_file_signature`, `getfile_signature`, `_is_world_writable`, `_locked_history_save`, `_locked_manifest_create`, `_locked_manifest_add_part`, `check_local_rate_limit`, `make_tmpdir`, `_tmpf`.
*   **Attività**: Anonimizzazione rigorosa delle PII (hashing SHA-256 di `THREAD_ID`), sandbox per l'esecuzione degli hook `pre`/`post`, controllo delle firme di stato dei file, limitatore di frequenza locale a finestra scorrevole (30s) e allocazione temporanea protetta.

#### Sezione 4: `PRECORE_RUN_THREAD_ENGINE`
*   **Funzioni**: `thread_validate_id`, `thread_now_ts`, `thread_messages_tmp_path`, `thread_sanitize_cmd`, `_update_thread_index`, `_thread_delete_locked`, `thread_delete_core`, `_thread_rename_locked`, `thread_rename_core`, `acquire_thread_lock`, `release_thread_lock`, `_thread_read_window_locked`, `thread_read_window`, `thread_append`, `_thread_hash`, `thread_cache_key`, `thread_cache_get`, `thread_cache_set`, `thread_cache_invalidate`.
*   **Attività**: **Motore Unificato di Gestione dei Thread**: include la validazione degli ID, la sanificazione dei comandi con redazione dati sensibili (`[REDACTED]`), le operazioni CRUD (lettura finestra messaggi NDJSON, accodamento idempotente con ID messaggio, rinomina e cancellazione atomica), la gestione della concorrenza tramite lock esclusivi e il sistema di caching delle risposte con TTL.

#### Sezione 5: `PRECORE_RUN_RUNTIME_GLOBALS`
*   **Funzioni**: `_normalize_bool_env`.
*   **Attività**: Inizializzazione delle variabili di stato e di ambiente globale (`CONTENT`, `PROVIDER`, `TEMPERATURE`, `MAX_TOKENS`, `OUTPUT_MODE`, ecc.), configurazione dell'array `CURL_BASE_OPTS` e normalizzazione booleana delle opzioni di runtime.

### 3.3 Flussi e Blocchi Logici di PRECORE_RUN
*   **PRECORE_RUN_HISTORY**: Inizializzazione della cronologia e rotazione.
*   **PRECORE_RUN_MANIFEST**: Generazione e staging dei manifesti Base64.
*   **PRECORE_RUN_UTIL_HELPERS**: Gestione permessi, proprietari, anonimizzazione PII, rate limit, firme crittografiche e cartelle temporanee protette.
*   **PRECORE_RUN_THREAD_ENGINE**: Meccanismi unificati di append, indexing, locks, rinomina, eliminazione, gestione dei thread e cache.
*   **PRECORE_RUN_RUNTIME_GLOBALS**: Inizializza i valori predefiniti del runtime e normalizza le variabili booleane del core.

---

## SEZIONE 4: SECURITY EXTENSION (openssl-helper.sh)

Estensione opzionale (collocata in `extras/security/`) abilitata per default se è presente il binario `openssl`. Fornisce la gestione delle credenziali API tramite cifratura a più livelli con password master.

### 4.1 File di Supporto del Vault
*   `keys.enc`: Contiene la chiave di sblocco simmetrica interna (*Vault Key*) cifrata con la Master Password dell'utente.
*   `keys.rec`: Contiene la medesima *Vault Key* cifrata con una chiave di ripristino offline esadecimale casuale a 128 bit (*Recovery Key*).
*   `keys.dat`: Contiene il payload JSON effettivo delle chiavi API di tutti i provider, cifrato con la *Vault Key*.

### 4.2 Funzioni della Security Extension
*   **`_vault_read_password`**: Legge in modo sicuro una password senza eco tramite `read_secure_input`.
*   **`_vault_set_opts`**: Configura l'algoritmo AES-256-CBC, salt e PBKDF2 con 100.000 iterazioni.
*   **`_vault_encrypt_to_file` / `_vault_decrypt_file`**: Cifratura e decrittografia atomica di file sul disco.
*   **`vault_exists` / `vault_init`**: Verifica stato e inizializzazione della Master Password e della Recovery Key.
*   **`vault_load_keys`**: Decrittografa in memoria il database JSON delle chiavi usando il token di sessione `_B4L_RT_CTX`.
*   **`vault_change_password`**: Cambia la Master Password e ricifra la Vault Key generando un nuovo token di ripristino.
*   **`vault_destroy`**: Distruzione fisica sicura dei file cifrati tramite `shred` o sovrascrittura con zeri (`dd`).
*   **`vault_recover`**: Ripristina l'accesso al vault tramite la *Recovery Key* offline esadecimale.
*   **`vault_manage_keys` / `vault_console`**: Interfaccia interattiva CLI di gestione delle chiavi attivata dall'opzione `--vault`.
*   **`_secure_hash_sha256`**: Calcola l'hash SHA-256 per i controlli di integrità prima del sourcing.
*   **`diagnose_tls_connection`**: Esegue un handshake di test tramite `openssl s_client` verso la porta 443 dell'endpoint per verificare la catena TLS.

---

## SEZIONE 5: SESSION ENGINE EXTENSION (session-engine.sh)

Estensione opzionale di ottimizzazione delle sessioni (collocata in `extras/session/`). Gestisce la segmentazione automatica dei registri NDJSON, la compressione e la costruzione reattiva del contesto tramite caching in-process.

### 5.1 Funzioni del Session Engine
*   **`_se_list_segments`**: Restituisce l'elenco ordinato dei segmenti NDJSON della sessione (es. `chat1.001.ndjson`).
*   **`_se_segment_rotate_if_needed`**: Se il log supera `$BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (1MB), ruota il file nel segmento successivo e applica la compressione `gzip` ai blocchi più obsoleti.
*   **`session_engine_append`**: Accoda un messaggio con deduplicazione automatica nell'intervallo `BASH4LLM_SESSION_DEDUP_WINDOW` (20 righe) e svuota la cache di lettura.
*   **`session_engine_build_window`**: Compila la finestra del contesto per il modello:
    *   Restituisce i dati dalla cache se validi rispetto a `SESSION_CACHE_TTL_SEC` (30s).
    *   **N > 0**: Estrae esattamente gli ultimi N messaggi.
    *   **N = 0**: Calcola il peso in byte e accumula messaggi fino a `$BASH4LLM_SESSION_TARGET_BYTES` (32KB).
*   **`session_engine_snapshot`**: Genera un report di telemetria JSON con statistiche, segmenti attivi, ultime 50 righe e sommari della conversazione.

---

## SEZIONE 6: PROVIDER (embedded: groq)

Questa macro-sezione racchiude direttamente l'implementazione del provider Groq integrato nel core, senza la necessità di sezioni interne ridondanti.

### 6.1 Funzioni del modulo Groq
*   **`buildpayload_groq`**: Compila il file JSON di payload OpenAI-compatible leggendo l'input utente (`CONTENT`, `JSON_INPUT`, `SYSTEM_PROMPT` o `BUILD_MESSAGES_FILE`), imposta temperatura e max token, producendo il file `$PAYLOAD` (con staging Base64 opzionale).
*   **`call_api_groq`**: Chiamata HTTP sincrona non-streaming tramite `curl`: isola la chiave API in un file di intestazione temporaneo sicuro (`mode 600`) per nasconderla dalla lista processi (`ps aux`) e salva la risposta in `$RESP`.
*   **`call_api_streaming_groq`**: Connessione streaming SSE: elabora il flusso in tempo reale con `tee` e `jq --unbuffered`, invia i token a `stdout`, compila il JSON sintetico finale in `$RESP` e aggiorna `last_api.json`.
*   **`validate_key_groq`**: Test diagnostico rapido (timeout 10s) sull'endpoint `/models` per convalidare la chiave API.
*   **`auto_select_model_groq` / `validate_model_groq` / `refresh_models_groq`**: Gestiscono l'auto-selezione della prima scelta valida, la verifica e la sincronizzazione locale del catalogo modelli in `$MODELS_FILE` con scrittura atomica cifrata.

---

## SEZIONE 7: CORE_SETUP

Gestisce il parsing dei parametri da riga di comando (CLI), l'interfaccia di dispatching, il whitelisting e la risoluzione preventiva delle azioni. È suddivisa in **7 Sezioni Piatte**.

### 7.1 Mappatura Funzionale per Sezione in CORE_SETUP

#### Sezione 1: `CORE_SETUP_DISPATCH_HELPERS`
*   **Funzioni**: `validate_provider_interface`, `call_provider`, `validate_provider_key_dispatch`, `refresh_models_dispatch`, `validate_model_dispatch`, `auto_select_model_dispatch`.
*   **Attività**: Interfaccia di dispatching dinamico: inoltra le chiamate alle funzioni specifiche del provider attivo ed effettua il controllo di conformità dell'interfaccia del modulo (`buildpayload_<p>`, `call_api_<p>`).

#### Sezione 2: `CORE_SETUP_API_CALL`
*   **Funzioni**: `resolve_model`, `build_payload_from_vars`, `call_api_once`, `call_api_streaming`, `extract_api_error`, `detect_empty_edge_case`, `finalize_and_output`, `perform_request_once`.
*   **Attività**: Involucro di esecuzione delle richieste: risolve il modello finale da adottare (`FINAL_MODEL`), gestisce i cicli di re-invio lineare in caso di errore (`$MAX_RETRIES`), intercetta le risposte vuote e gestisce la formattazione di output (`json`, `pretty`, `text`, `raw`) con salvataggio automatico se supera `$THRESHOLD`.

#### Sezione 3: `CORE_SETUP_INPUT_HELPERS`
*   **Funzioni**: `collect_input_from_files`, `expand_args_to_content`, `file_readable`, `trim`, `is_number`, `is_supported_model`, `list_models_cli`, `validate_model_core`, `load_local_config`, `load_whitelist`, `is_tty_out`, `_cleanup_sourced_env`.
*   **Attività**: Raccolta ed espansione degli argomenti da file `-f`, verifica della leggibilità e sicurezza dell'input (`validate_file_input`), linter dei modelli supportati (esclude modelli multimodal/vision/audio non supportati dal wrapper testuale), caricamento della configurazione locale e blocco di protezione per il sourcing interattivo della shell utente con sblocco del Vault.

#### Sezione 4: `CORE_SETUP_CLI_PARSE`
*   **Attività**: Ciclo principale di parsing degli argomenti CLI (`while [ $# -gt 0 ]`), interpretazione dei flag, anonimizzazione immediata degli ID thread ricevuti (`anonymize_thread_id`), risoluzione e persistenza atomica del provider attivo in `canonical_provider_file` e caricamento automatico del rispettivo modulo.

#### Sezione 5: `CORE_SETUP_SESSION_ENGINE`
*   **Attività**: Tenta l'importazione e la verifica di integrità di `extras/session/session-engine.sh`. Se verificato con successo, attiva il flag `_engine_available=1`, altrimenti attiva il fallback automatico sulla logica NDJSON del core.

#### Sezione 6: `CORE_SETUP_NORM_FLAGS`
*   **Attività**: Normalizzazione delle opzioni CLI di esportazione grezza e listing dei provider o modelli locali (`--list-providers-raw`, `--list-models-raw`).

#### Sezione 7: `CORE_SETUP_ACTIONS`
*   **Attività**: Gestione ed esecuzione immediata dei comandi CLI brevi che non richiedono chiamate di rete ai modelli LLM: cancellazione thread (`--delete-thread`), rinomina thread (`--rename-thread`), inizializzazione manuale (`--init-thread`), listing provider e modelli, salvataggio del modello predefinito (`--set-default`), e installazione/sincronizzazione sicura del pacchetto `extras` con verifica di integrità del manifesto SHA-256 e blindatura dei permessi (`700`/`600`).

---

## SEZIONE 8: CORE_PROVIDER

Gestisce l'interazione interattiva, l'assemblaggio dei prompt complessi e lo smistamento finale verso le pipeline di esecuzione. È suddivisa in **4 Sezioni Piatte**.

### 8.1 Mappatura Funzionale per Sezione in CORE_PROVIDER

#### Sezione 1: `CORE_PROVIDER_PRO_LOAD`
*   **Attività**: Gestisce la selezione interattiva del provider in caso di invio della flag `--provider` senza argomenti o valore `list`. Presenta un menu numerato a terminale, persiste la scelta e carica il modulo provider selezionato.

#### Sezione 2: `CORE_PROVIDER_SHOW`
*   **Attività**: Esegue i comandi CLI di visualizzazione preventiva ed arresta l'esecuzione: stampa percorsi configurazione (`--print-*`), mostra le variabili attive (`--show-config`) o esegue il bilancio di diagnostica completo con test di handshake TLS verso l'endpoint del provider (`--diagnostics`).

#### Sezione 3: `CORE_PROVIDER_PROMPT_ASSEMBLY`
*   **Funzioni**: `assemble_content`.
*   **Attività**: **Preparazione e Assemblaggio del Contesto**:
    1. Esegue il refresh automatico dei modelli se richiesto o se il catalogo locale è vuoto.
    2. Sincronizza l'anonimizzazione dell'ID del thread in `$SAFE_THREAD_ID`.
    3. Carica la configurazione e la whitelist locale.
    4. Garantisce la presenza della cartella `$RUN_TMPDIR`.
    5. Risolve ed effettua la convalida formale del modello finale (`MODEL`).
    6. Intercetta ed estrae dati dallo standard input (`stdin`), sanificando e redigendo eventuali chiavi API passate via JSON.
    7. Esegue `assemble_content()` per unire file di input (`-f`), prompt da CLI, o espandere i segnaposto `{{CONTENT}}` all'interno dei file di template (`--template`).
    8. Verifica che il contenuto del prompt non sia vuoto, interrompendo l'esecuzione con errore `BASH4LLM_ERR_NO_PROMPT` (14) in caso di anomalie.

#### Sezione 4: `CORE_PROVIDER_PIPELINE_EXEC`
*   **Attività**: **Smistamento ed Esecuzione della Pipeline**:
    *   **Ramo A - Ciclo BATCH (`--batch`)**: Scansiona il file riga per riga, recupera la finestra di sessione del thread tramite Session Engine o NDJSON fallback, compila il payload ed esegue le richieste in sequenza stampando il promemoria di persistenza.
    *   **Ramo B - Modalità CHAT (`--chat`/`--tui`)**: Verifica l'integrità crittografica del modulo `extras/chat/tui-repl.sh` via `verify_module_integrity`, esporta le variabili d'ambiente ed esegue il passaggio del processo (`exec bash`) all'interfaccia REPL interattiva.
    *   **Ramo C - Richiesta Singola (SSE Streaming / Synchronous)**: Prepara il file dei messaggi storici del thread, compila il payload via `build_payload_from_vars`, assicura la presenza della chiave API, ed esegue la chiamata HTTP (streaming via `call_api_streaming` o sincrona via `perform_request_once`). Al rientro positivo, accoda in sicurezza il messaggio utente e la risposta dell'assistente nel registro del thread.

---

## SEZIONE 9: STRUTTURA DEL FILE-SYSTEM E LAYOUT DI MEMORIA

Per assicurare la persistenza delle informazioni e l'integrazione di sicurezza, la directory di runtime `bash4llm.d/` è organizzata come segue:

```text
bash4llm.d/
├── config/                                # Configurazione e persistenza provider (700)
│   ├── config                             # Variabili e parametri globali utente (600)
│   ├── provider                           # Memorizza il nome del provider attivo (600)
│   ├── provider-url                       # Memorizza l'URL delle API del provider attivo (600)
│   ├── model.<provider>                   # Memorizza il modello di default del provider (600)
│   ├── keys.enc                           # Chiave Vault cifrata con Master Password (600)
│   ├── keys.rec                           # Chiave Vault cifrata con Recovery Key offline (600)
│   ├── keys.dat                           # Database cifrato contenente il JSON delle chiavi API (600)
│   ├── providers/                         # Cartella per configurazioni avanzate (700)
│   │   └── hf_endpoints                   # Mappatura modelli/endpoint di Hugging Face
│   └── ui_state/                          # Cartella di stato per GUI ed automazioni (700)
│       ├── last_api.json                  # Stato dell'ultima chiamata API (600)
│       ├── last_history.json              # Stato dell'ultimo output salvato (600)
│       ├── provider_capabilities.json     # Elenco capacità del provider attivo (600)
│       └── threads/                       # Indici e metadati delle sessioni (700)
│           ├── index.json                 # Elenco strutturato dei thread attivi (600)
│           └── <safe_thread_id>.json      # Metadati dello stato del thread (anonimizzato SHA-256)
├── models/                                # Cataloghi locali dei modelli ammessi (700)
│   └── <provider>.txt                     # Whitelist modelli validati (600)
├── templates/                             # Area prompt template riutilizzabili (700)
├── history/                               # Archiviazione output delle risposte (700)
│   ├── threads/                           # File NDJSON storici dei thread attivi (Core fallback) (700)
│   │   └── <safe_thread_id>.ndjson        # Registro NDJSON anonimizzato SHA-256 (600)
│   └── sessions/                          # File NDJSON storici avanzati (Session Engine) (700)
│       ├── <safe_thread_id>.ndjson        # Registro NDJSON principale anonimizzato (600)
│       ├── <safe_thread_id>.001.ndjson    # Segmento storico rotato (600)
│       └── <safe_thread_id>.001.ndjson.gz # Segmento storico rotato e compresso (600)
├── var/                                   # Processi e file di runtime isolati (700)
│   └── run/                              # Directory di runtime di processo (700)
│       └── locks/                         # Directory isolata dei file di blocco (700)
│           ├── models.lock                # Lock di sincronizzazione dei modelli
│           ├── history.lock               # Lock di sincronizzazione della cronologia
│           └── tmp.lock                   # Lock di allocazione file temporanei
├── tmp/                                   # Area sicura ad accesso esclusivo (700)
│   └── rates/                             # Tracciamento transazioni rate limiting (700)
│       └── <safe_thread_id>/              # Timestamp delle richieste per finestra scorrevole
└── extras/                                # Estensioni installate tramite l'installer (700)
    ├── manifest.sha256                    # Manifesto dell'integrità crittografica SHA-256 (600)
    ├── chat/                              # Interfaccia di chat interattiva (tui-repl.sh)
    ├── hooks/                             # Moduli di estensione pre/post esecuzione (hook.sh)
    ├── lib/                               # Librerie e moduli helper condivisi
    ├── security/                          # Sicurezza (openssl-helper.sh, verify.sh)
    ├── test/                              # Suite di test e diagnostica automatica
    ├── docs/                              # Documentazione (core-notes.sh, help.txt, BASH4LLM.1)
    ├── providers/                         # Provider aggiuntivi (gemini.sh, huggingface.sh, mistral.sh)
    └── session/                           # Ottimizzazione e sessioni (session-engine.sh)
```
