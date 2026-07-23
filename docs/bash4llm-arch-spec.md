# SPECIFICA TECNICA DEL SISTEMA BASH4LLM⁺ (v2.6.0)

## SEZIONE 1: ARCHITETTURA GENERALE E RELAZIONI TRA MACRO-SEZIONI

Il sistema Bash4LLM⁺ è strutturato in sezioni logiche progettate per operare in modo sequenziale e integrato. La stabilità e l'integrazione del runtime sono garantite da una gerarchia di dipendenze, requisiti di sistema rigorosi e costanti di sicurezza applicate a livello di file-system.

### 1.1 Dipendenze tra Sezioni
*   **PRECORE_RUN**: Dipende da `PRECORE_BOOT` per il caricamento dei percorsi canonici, la gestione delle variabili di ambiente, gli helper di codifica/decodifica Base64, l'utilità di acquisizione dei lock esclusivi (`lock_exec`), la verifica di integrità dei moduli (`verify_module_integrity`) e l'inizializzazione sicura della directory temporanea (`ensure_run_tmpdir`).
*   **SECURITY EXTENSION (openssl-helper.sh)**: Estensione facoltativa caricata durante il bootstrap se abilitata da `BASH4LLM_VAULT_ENABLED`. Fornisce la decrittografia in memoria delle chiavi API e i servizi di hashing/diagnostica SSL.
*   **SESSION ENGINE EXTENSION (session-engine.sh)**: Estensione facoltativa caricata durante la configurazione iniziale per la gestione avanzata dei thread (segmentazione, compressione e caching). Se assente o disabilitata, il sistema esegue un fallback trasparente sulla logica NDJSON del core.
*   **PROVIDER**: Dipende da `PRECORE_BOOT` e `PRECORE_RUN` per la risoluzione degli URL degli endpoint, la verifica delle autorizzazioni di rete, lo staging transazionale dei payload, il buffering dell'I/O e la scrittura atomica dei log e degli stati della UI.
*   **CORE_SETUP**: Dipende da `PRECORE_BOOT`, `PRECORE_RUN` e `PROVIDER` per il dispatching delle chiamate specifiche dei provider, la convalida formale dei parametri CLI, l'estrazione sintattica delle whitelist e l'integrazione delle estensioni esterne.
*   **CORE_PROVIDER**: Dipende da tutte le sezioni precedenti per il caricamento protetto dei moduli provider esterni, l'inizializzazione del menu interattivo, l'allineamento dei modelli e la gestione del ciclo di chat, batch o prompt singolo.

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

Questa macro-sezione gestisce l'inizializzazione primaria della shell, l'analisi preventiva degli argomenti CLI, la convalida dell'ambiente operativo e l'esposizione delle funzioni fondamentali di logging, codifica e I/O.

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

### 2.2 Funzioni di PRECORE_BOOT

#### resolve_script_dir
*   **Ruolo**: Identifica la directory reale in cui risiede lo script risolvendo in modo ricorsivo eventuali link simbolici sul file-system.

#### safe_mkdir
*   **Ruolo**: Crea una directory in modo sicuro applicando permessi restrittivi ed escludendo la presenza di symlink per mitigare attacchi di tipo directory traversal.
*   **Input**: Percorso della directory, permessi ottali opzionali (default `700`).

#### check_required_arg
*   **Ruolo**: Verifica se un'opzione CLI riceve l'argomento richiesto, prevenendo errori di sfasamento parametri (*shift boundaries*).
*   **Input**: Opzione analizzata, conteggio argomenti residui (`$#`).

#### canonical_config_dir / canonical_provider_file / canonical_provider_url_file / canonical_model_file
*   **Ruolo**: Generano e restituiscono i percorsi canonici e normalizzati dei file di configurazione locale, del file provider, del file URL e dei file dei modelli dei singoli provider.

#### trim_space
*   **Ruolo**: Esegue un trimming degli spazi vuoti, tabulazioni e carriage return (`\r`) dall'inizio e dalla fine di una stringa in modo POSIX nativo.

#### read_secure_input
*   **Ruolo**: Acquisisce in modo protetto dati sensibili (come password o chiavi API). In sessioni interattive (`[ -t 0 ]`), disabilita l'eco a schermo tramite `stty -echo < /dev/tty`. In sessioni automatizzate o invii via pipe (`! [ -t 0 ]`), legge direttamente dallo standard input (`stdin`) applicando la sanificazione dei caratteri di controllo.

#### sync_models_file_path
*   **Ruolo**: Sincronizza dinamicamente la variabile `$MODELS_FILE` in base al provider attivo (es. `<provider>.txt`), applicando una rigida sanificazione dei caratteri per prevenire tentativi di iniezione di percorsi.

#### validate_file_input
*   **Ruolo**: Convalida che un file di input esista, sia regolare, leggibile, non vuoto (superiore a 0 byte) ed esclude in modo indipendente dal locale la presenza di byte nulli o caratteri di controllo C0 (eccetto tab, CR, LF).
*   **Output**: Ritorna `0` se il file è un testo UTF-8 stampabile e sicuro, altrimenti un codice da `1` a `4` in base all'anomalia rilevata.

#### _normalize_model_name
*   **Ruolo**: Normalizza i nomi dei modelli LLM eliminando i prefissi e gli spazi. Si appoggia alla memoria cache associativa `BASH4LLM_MODEL_CACHE` per saltare l'esecuzione di sotto-shell e massimizzare la reattività.

#### validate_path_security
*   **Ruolo**: Verifica rigorosamente i permessi POSIX e la proprietà del file target e delle sue directory padre, assicurando che appartengano all'utente corrente e non siano scrivibili da gruppi o terzi (`group/world-writable`).

#### _core_sha256
*   **Ruolo**: Calcola il digest SHA-256 di un file utilizzando in modo portabile le utilità di sistema disponibili (`sha256sum`, `openssl` o `shasum`).

#### verify_module_integrity
*   **Ruolo**: Esegue la verifica integrata di un modulo o estensione: convalida la sicurezza del percorso via `validate_path_security` e ne confronta l'hash SHA-256 contro il file manifesto `extras/manifest.sha256`. Ritorna `BASH4LLM_ERR_SEC` (17) in caso di manomissione.

#### ensure_api_key_for_provider
*   **Ruolo**: Convalida la presenza di una chiave API per il provider. Cerca prioritariamente la chiave nell'ambiente (usando `provider_api_env_var_name`), poi tenta di decrittografarla dal Vault OpenSSL in memoria (`BASH4LLM_DECRYPTED_VAULT_JSON`). Se assente, in TTY interattivo richiede l'inserimento via `read_secure_input`, sanifica la stringa ed esporta la chiave.

#### enforce_network_policy
*   **Ruolo**: Centralizza la valutazione sull'opportunità di inibire le chiamate di rete. Rispetta `DRY_RUN`, `BASH4LLM_SKIP_NETWORK`, `BASH4LLM_ENFORCE_NO_NETWORK_IF_QUIET` e `QUIET`.

#### _extract_notes_section
*   **Ruolo**: Esegue un parsing "Zero-Eval" (POSIX-compliant awk) per estrarre sezioni testuali di documentazione da `core-notes.sh` senza eseguire codice.

#### log_prefix / log_info / log_warn / log_error / log_info_user / dbg
*   **Ruolo**: Gestiscono la formattazione e la visualizzazione dei log strutturati. `log_info_user` rispetta l'impostazione `QUIET` dello script.

#### ensure_config_dir
*   **Ruolo**: Crea e testa la directory di configurazione utente con permessi `700`, verificando che sia scrivibile.

#### write_provider_url_if_missing / resolve_provider_url
*   **Ruolo**: Registrano in modo transazionale e risolvono l'URL di connessione dell'API per il provider attivo.

#### provider_api_env_var_name
*   **Ruolo**: Calcola il nome della variabile d'ambiente standardizzata per contenere la chiave API di un provider (es. `MISTRAL_API_KEY`).

#### is_valid_json_string / is_valid_json_file / jq_safe
*   **Ruolo**: Validano la conformità sintattica JSON ed eseguono query protette, deviando eventuali messaggi di errore strutturali in `$ERRF`.

#### b64encode / b64decode / b64_atomic_write / b64_atomic_read / stage_b64
*   **Ruolo**: Gestiscono la codifica/decodifica Base64 e lo staging dei payload entro il limite `$MAX_STAGE_BYTES`.

#### lock_exec
*   **Ruolo**: Garantisce l'esecuzione esclusiva e concorrente dei comandi tramite `flock` o, in ambiente Termux, tramite la creazione atomica di directory lock (`mkdir`).

#### _mktemp_in_dir / atomic_write
*   **Ruolo**: Creano risorse temporanee sicure ed eseguono scritture atomiche sul filesystem.

#### extract_text_from_resp
*   **Ruolo**: Estrae in modo resiliente il testo dell'assistente dal JSON di risposta, gestendo formati diversi e strutture nidificate, salvando i log di fallimento in `$ERRF`.

#### ensure_run_tmpdir / cleanup_run_tmp_on_exit
*   **Ruolo**: Gestiscono il ciclo di vita della directory temporanea esclusiva della transazione corrente (`$RUN_TMPDIR`), inizializzando i canali `$PAYLOAD`, `$RESP` e `$ERRF` ed eseguendo una rimozione sicura all'uscita o interruzione.

#### ui_state_write
*   **Ruolo**: Persiste in modo atomico e protetto da lock lo stato dell'interfaccia utente (come JSON) sotto la directory `$BASH4LLM_CONFIG_DIR/ui_state`.

#### load_provider_module
*   **Ruolo**: Carica i moduli provider esterni eseguendo verifiche rigide (no symlink, proprietario valido, no group/world writable, conformità sintattica tramite `bash -n`, controllo dell'integrità tramite `verify_module_integrity` e validazione delle funzioni obbligatorie d'interfaccia).

#### run_static_config_check
*   **Ruolo**: Verifica la sicurezza dei permessi del file di configurazione ed esegue il linter delle chiavi di configurazione confrontandole con le definizioni estratte da `core-notes.sh`.

#### explain_error_code
*   **Ruolo**: Spiega i codici d'errore (o alias) fornendo la definizione formale e i consigli di mitigazione estratti da `core-notes.sh`.

### 2.3 Flussi e Blocchi Logici di PRECORE_BOOT
*   **PRECORE_BOOT_SETUP_SHELL**: Imposta `set -euo pipefail` solo se lo script è eseguito direttamente per non inquinare la shell interattiva dell'utente in caso di sourcing.
*   **PRECORE_BOOT_SETUP_ENV_CMDS**: Verifica la presenza dei 23 comandi di sistema obbligatori.
*   **PRECORE_BOOT_EARLY_HELPERS**: Carica le primitive fondamentali di directory, URL, sicurezza dell'input e stringhe.
*   **PRECORE_BOOT_DIR_PATH**: Configura l'albero delle directory di lavoro operative (`var/run`, `locks`, `tmp`).
*   **PRECORE_BOOT_HELPERS**: Espone Base64, staging, lock_exec, atomic_write e controlli di static linting.
*   **PRECORE_BOOT_CLI_HELPERS**: Intercetta precocemente le opzioni CLI di diagnostica o ispezione percorsi (`--print-*`, `--check-config`, `--explain-error`) ed esegue l'arresto immediato.

---

## SEZIONE 3: PRECORE_RUN

Questa macro-sezione si occupa della persistenza a lungo termine, della gestione dello storico delle conversazioni, dei thread e delle sessioni conversazionali NDJSON.

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

### 3.2 Funzioni di PRECORE_RUN

#### rotate_history / save_to_history
*   **Ruolo**: Gestiscono l'archiviazione sicura degli output e la manutenzione automatica del registro storico sotto lock esclusivo di sicurezza.

#### manifest_create / manifest_add_part / manifest_read
*   **Ruolo**: Gestiscono la compilazione e la lettura di manifesti JSON multimediali accoppiati a una versione specchio in Base64 (`.b64`).

#### anonymize_thread_id
*   **Ruolo**: Applica l'hashing SHA-256 all'ID del thread grezzo fornito dall'utente, memorizzando il risultato in `$SAFE_THREAD_ID`. Garantisce che tutti i file salvati su disco (`.ndjson`, `.json`, lock) utilizzino esclusivamente identificatori anonimi, prevenendo la scrittura di PII (dati personali) sul filesystem.

#### execute_isolated_hook
*   **Ruolo**: Esegue gli script di hook (`pre` o `post`) situati in `extras/hooks/` all'interno di una sotto-shell isolata. Rimuove preventivamente le chiavi API dalla memoria della sotto-shell, convalida la sicurezza del percorso e ne verifica l'integrità crittografica tramite `verify_module_integrity`. Raccoglie in modo deterministico solo le variabili approvate (`BASH4LLM_RATE_LIMIT`, `FALLBACK_PAYLOAD`, `BASH4LLM_AUTH_TOKEN`).

#### check_local_rate_limit
*   **Ruolo**: Motore di controllo della frequenza locale basato su finestra scorrevole a 30 secondi. Registra i file di transazione in `$BASH4LLM_RATES_DIR/$SAFE_THREAD_ID`. Se il conteggio supera `$BASH4LLM_RATE_LIMIT` e non è presente un `$BASH4LLM_AUTH_TOKEN` valido, blocca l'esecuzione ritornando il codice `BASH4LLM_ERR_SEC` (17).

#### _get_perm_string / _get_owner / getfile_signature / _is_world_writable / make_tmpdir / _tmpf
*   **Ruolo**: Prerogative di sicurezza del filesystem. `_tmpf` verifica la conformità dei percorsi interni impedendo attacchi di Directory Traversal.

#### thread_validate_id / thread_now_ts / thread_messages_tmp_path / thread_sanitize_cmd
*   **Ruolo**: Convalidano l'ID del thread (`^[A-Za-z0-9._-]{1,128}$`), generano timestamp ISO 8601 UTC e sanificano le stringhe dei comandi registrati escludendo variabili sensibili o chiavi (etichettate come `[REDACTED]`).

#### _update_thread_index
*   **Ruolo**: Registra in sicurezza e sotto lock l'ID del thread all'interno dell'indice globale `ui_state/threads/index.json`.

#### thread_delete_core
*   **Ruolo**: Purga fisicamente e sotto lock i file NDJSON, i file di lock concorrenti, i metadati locali e rimuove l'ID dall'indice globale dei thread.

#### thread_rename_core
*   **Ruolo**: Consente di rinominare in sicurezza il titolo utente all'interno del file di metadati JSON del thread (`ui_state/threads/<id>.json`) sotto lock.

#### acquire_thread_lock / release_thread_lock
*   **Ruolo**: Meccanismo di blocco esclusivo cross-processo specifico per i thread conversazionali. Previene conflitti o sovrascritture in caso di esecuzioni parallele sullo stesso ID.

#### thread_read_window
*   **Ruolo**: Estrae la finestra degli ultimi messaggi storici del thread (memorizzati nativamente in `history/threads/<id>.ndjson`), normalizzandoli in un array strutturato e aggiornando i metadati di lettura in `ui_state/threads/<id>.json`.

#### thread_append
*   **Ruolo**: Accoda un nuovo messaggio al file NDJSON del thread (`history/threads/<id>.ndjson`) sotto lock concorrente, assicurando l'idempotenza di scrittura tramite generazione di hash del messaggio. Aggiorna l'indice globale e i file di stato UI della sessione.

#### thread_cache_key / thread_cache_get / thread_cache_set / thread_cache_invalidate
*   **Ruolo**: Gestiscono il caching delle risposte basato su TTL ed epoch di scadenza memorizzati nella prima riga del file cache.

### 3.3 Flussi e Blocchi Logici di PRECORE_RUN
*   **PRECORE_RUN_HISTORY**: Inizializzazione della cronologia e rotazione.
*   **PRECORE_RUN_MANIFEST**: Generazione e staging dei manifesti Base64.
*   **PRECORE_RUN_UTIL_HELPERS**: Gestione permessi, proprietari, anonimizzazione PII, rate limit, firme crittografiche e cartelle temporanee protette.
*   **PRECORE_RUN_THREAD_MVP**: Meccanismi di append, indexing, locks, rinomina, eliminazione e gestione dei thread.
*   **PRECORE_RUN_THREAD_CACHE**: Logica di gestione della cache locale.
*   **PRECORE_RUN_RUNTIME_GLOBALS**: Inizializza i valori predefiniti del runtime e normalizza le variabili booleane del core.

---

## SEZIONE 4: SECURITY EXTENSION (openssl-helper.sh)

Estensione opzionale (collocata in `extras/security/`) abilitata per default se è presente il binario `openssl`. Fornisce la gestione delle credenziali API tramite cifratura a più livelli con password master.

### 4.1 File di Supporto del Vault
*   `keys.enc`: Contiene la chiave di sblocco simmetrica interna (*Vault Key*) cifrata con la Master Password dell'utente.
*   `keys.rec`: Contiene la medesima *Vault Key* cifrata con una chiave di ripristino offline esadecimale casuale a 128 bit (*Recovery Key*).
*   `keys.dat`: Contiene il payload JSON effettivo delle chiavi API di tutti i provider, cifrato con la *Vault Key*.

### 4.2 Funzioni della Security Extension

#### _vault_read_password
*   **Ruolo**: Legge in modo sicuro una password dallo standard input senza mostrarla a schermo tramite `read_secure_input`.

#### _vault_set_opts
*   **Ruolo**: Configura l'array globale `_VAULT_OPTS` impostando l'algoritmo AES-256-CBC, salt, PBKDF2 con 100.000 iterazioni e caricamento sicuro della password tramite variabile d'ambiente (`-pass env:BASH4LLM_VAULT_PASS`).

#### _vault_encrypt_to_file / _vault_decrypt_file
*   **Ruolo**: Eseguono la cifratura e la decrittografia di payload testuali scrivendo in sicurezza e in modo atomico i file sul disco.

#### vault_exists / vault_init
*   **Ruolo**: `vault_exists` attesta la presenza dei file chiave. `vault_init` inizializza il vault: richiede la definizione della Master Password, genera la chiave di ripristino esadecimale e scrive i file di database vuoti con umask restrittiva.

#### vault_load_keys
*   **Ruolo**: Esegue il caricamento e la decrittografia in memoria del JSON delle chiavi API. Tenta prioritariamente l'autenticazione silenziosa leggendo la password dal token di sessione `_B4L_RT_CTX`.

#### vault_change_password
*   **Ruolo**: Consente di modificare la Master Password decrittografando la *Vault Key* esistente e ricifrandola con le nuove credenziali. Genera un nuovo token di ripristino.

#### vault_destroy
*   **Ruolo**: Esegue una distruzione sicura fisica dei dati sul disco. Sovrascrive i blocchi dei file tramite `shred` o, in sua assenza, tramite `dd` con flusso di zeri, prima di rimuovere definitivamente i file dal filesystem.

#### vault_recover
*   **Ruolo**: Consente di ripristinare l'accesso al vault decifrando la *Vault Key* tramite la *Recovery Key* esadecimale offline, richiedendo la definizione di una nuova Master Password.

#### vault_manage_keys
*   **Ruolo**: Console interattiva di amministrazione delle chiavi API per aggiungere, modificare, elencare e rimuovere le chiavi dei singoli provider all'interno del database cifrato.

#### vault_console
*   **Ruolo**: Punto di ingresso per l'interfaccia a riga di comando interattiva avviata dall'opzione `--vault`.

#### _secure_hash_sha256
*   **Ruolo**: Calcola l'hash SHA-256 di un file per i controlli di integrità dei moduli provider esterni prima del sourcing.

#### diagnose_tls_connection
*   **Ruolo**: Esegue un test diagnostico di rete eseguendo un handshake completo tramite `openssl s_client` verso la porta 443 dell'endpoint API per accertare la stabilità di connessione TLS.

---

## SEZIONE 5: SESSION ENGINE EXTENSION (session-engine.sh)

Estensione opzionale di ottimizzazione delle sessioni (collocata in `extras/session/`). Gestisce la segmentazione automatica dei registri NDJSON, la compressione e la costruzione reattiva del contesto tramite caching in-process.

### 5.1 Funzioni del Session Engine

#### _se_list_segments
*   **Ruolo**: Scansiona la directory dei log della sessione avanzata e restituisce l'elenco ordinato in ordine crescente dei segmenti NDJSON associati alla sessione (es. `chat1.ndjson`, `chat1.001.ndjson`, ecc.).

#### _se_segment_rotate_if_needed
*   **Ruolo**: Se il file NDJSON principale supera `$BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (default 1MB), acquisisce un lock esclusivo, identifica l'indice di rotazione incrementale successivo e sposta atomicamente il file di log nel segmento numerato. Se il numero di segmenti supera la soglia di mantenimento, applica la compressione tramite `gzip` dei blocchi più obsoleti.

#### session_engine_append
*   **Ruolo**: Esegue l'accodamento di un messaggio nel registro del thread (all'interno della cartella avanzata `sessions/` configurata dal modulo). Gestisce la deduplicazione dei messaggi duplicati verificando il contenuto nel raggio definito da `BASH4LLM_SESSION_DEDUP_WINDOW` (default 20 righe) ed esegue la scrittura con umask restrittiva prima di invalidare la cache di lettura in memoria.

#### session_engine_build_window
*   **Ruolo**: Compila ed assembla la finestra dei messaggi storici da inviare al modello.
    *   Se l'ID thread è registrato nella cache in-process e non è scaduto (rispetto a `SESSION_CACHE_TTL_SEC`, default 30 secondi), restituisce i dati istantaneamente bypassando l'I/O.
    *   **Opzione A (N > 0)**: Estrae esattamente gli ultimi N messaggi non ignorati dai segmenti fisici senza limiti di byte.
    *   **Opzione B (N = 0)**: Calcola dinamicamente il peso in byte di ciascun messaggio accumulando record fino al limite impostato in `$BASH4LLM_SESSION_TARGET_BYTES` (default 32KB), rispettando i vincoli di sicurezza sui messaggi minimi e massimi del thread.

#### session_engine_snapshot
*   **Ruolo**: Produce un report di telemetria strutturato in formato JSON contenente statistiche dettagliate, il conteggio dei messaggi e dei segmenti fisici attivi sul disco, le ultime 50 righe del thread e i blocchi contrassegnati come sommari della conversazione.

---

## SEZIONE 6: PROVIDER (embedded: groq)

Questa macro-sezione descrive l'interfaccia obbligatoria dei provider esterni e l'implementazione del modulo Groq integrato nel core.

### 6.1 Funzioni del modulo Groq

#### buildpayload_groq
*   **Ruolo**: Compila il file JSON di payload OpenAI-compatible leggendo l'input utente (`CONTENT`, `JSON_INPUT`, `SYSTEM_PROMPT` o `BUILD_MESSAGES_FILE`), impostando i parametri di temperatura (`TURE`) e max token, scrivendolo in `$PAYLOAD` (e applicando lo staging Base64 se configurato).

#### call_api_groq
*   **Ruolo**: Esegue la chiamata HTTP non-streaming sincrona tramite `curl` decodificando preventivamente il payload se in Base64, trasmettendo la chiave API tramite file di intestazione temporaneo sicuro (modalità 600) per nasconderla dai processi di sistema, e salvando la risposta in `$RESP`.

#### call_api_streaming_groq
*   **Ruolo**: Esegue la connessione streaming SSE, estrae e stampa in tempo reale i token su `stdout` convogliando i flussi via `tee` verso `jq --unbuffered` per non degradare le prestazioni. Al termine, compila il JSON consolidato in `$RESP` e aggiorna `last_api.json`.

#### validate_key_groq
*   **Ruolo**: Esegue una chiamata GET di diagnostica (timeout rigido a 10s) verso l'endpoint `/models` per convalidare la chiave API.

#### auto_select_model_groq / validate_model_groq / refresh_models_groq
*   **Ruolo**: Rispettano i contratti di auto-selezione, validazione e sincronizzazione locale dei cataloghi modelli del provider.

---

## SEZIONE 7: CORE_SETUP

Gestisce il parsing dei parametri riga di comando (CLI), il whitelisting e la risoluzione dei flussi operativi generali.

### 7.1 Funzioni principali di CORE_SETUP

#### resolve_model
*   **Ruolo**: Risolve il modello LLM finale da adottare (`FINAL_MODEL`) seguendo le priorità: 1) parametro CLI `-m`, 2) configurazione predefinita del provider `model.<provider>`, 3) auto-selezione del provider, 4) prima voce della whitelist locale, 5) modello predefinito in `config`, 6) whitelist globale `$ALLOWED_MODELS`.

#### perform_request_once
*   **Ruolo**: Esegue la chiamata API sincrona verificando la frequenza di invio via `check_local_rate_limit`, eseguendo gli hook pre/post esecuzione (`execute_isolated_hook`) e implementando cicli di reinvio lineare (fino a `$MAX_RETRIES`) in caso di caduta temporanea della connessione o errori fisici di curl.

### 7.2 Flussi di setup principali
*   **parse_cli_arguments**: Analizza opzioni, compilando percorsi, file `-f`, parametri operativi, thread ID (`--thread`), gestione thread (`--delete-thread`, `--rename-thread`, `--title`), opzioni del Vault (`--vault`), linter statico (`--check-config`), spiegazione errori (`--explain-error`) e query dei percorsi canonici (`--print-*`).
*   **source_session_engine**: Se abilitato, esegue l'importazione sicura di `session-engine.sh` previa verifica di integrità esportando il flag `$SE_AVAILABLE=1`, altrimenti attiva la modalità di fallback integrata basata su file NDJSON standard.
*   **immediate_actions**: Intercetta ed esegue comandi che non richiedono chiamate di rete (aiuto, elenchi raw, impostazione modello di default, azioni sui thread, linter di configurazione e l'installazione sicura degli extras tramite copia atomica, verifica di manifesto SHA-256 e applicazione permessi `700`/`600`).

---

## SEZIONE 8: CORE_PROVIDER

Gestisce l'assemblaggio dei prompt complessi, l'avvio delle modalità interattive (chat) e i cicli di chiamata standard.

### 8.1 Funzioni di CORE_PROVIDER

#### validate_provider_interface
*   **Ruolo**: Verifica la presenza fisica in memoria delle funzioni d'interfaccia obbligatorie del provider (`buildpayload_<p>`, `call_api_<p>`).

#### assemble_content
*   **Ruolo**: Costruisce la stringa del prompt principale `$CONTENT` leggendo file di input con validazione di sicurezza `validate_file_input`, applicando prompt di template (sostituendo `{{CONTENT}}`), o unendo standard input e argomenti posizionali CLI.

### 8.2 Cicli di esecuzione
*   **CORE_PROVIDER_PRO_LOAD**: Gestisce la selezione e persistenza del provider attivo. Consente la selezione grafica interattiva tramite menu e avvia il caricamento del modulo.
*   **CORE_PROVIDER_SHOW**: Gestisce l'elaborazione dei percorsi, la stampa di configurazioni attive (`--show-config`) o l'autoverifica del sistema e test handshake TLS (`--diagnostics`).
*   **CORE_PROVIDER_MAIN_EXECUTION**: Esegue l'assemblaggio finale e smista l'esecuzione nei tre rami primari:
    1.  **BATCH**: Scansiona il file batch, allinea l'ambiente di sessione del thread se configurato, compila il payload ed esegue le richieste in sequenza.
    2.  **CHAT (TUI REPL)**: Verifica l'integrità del modulo `tui-repl.sh` tramite `verify_module_integrity`, controlla il TTY ed esegue il passaggio del controllo all'interfaccia di chat REPL interattiva.
    3.  **STANDARD**: Inizializza l'ambiente del thread (`THREAD_ID`), anonimizza l'ID tramite `anonymize_thread_id`, allinea la cronologia dei messaggi storici tramite il Session Engine o la logica NDJSON core, compila il payload ed esegue la transazione (streaming o non-streaming), provvedendo alla sanificazione ed accodamento dei messaggi in caso di successo.

---

## SEZIONE 9: STRUTTURA DEL FILE-SYSTEM E LAYOUT DI MEMORIA

Per assicurare la persistenza delle informazioni e l'integrazione di sicurezza, la directory di runtime `bash4llm.d/` è organizzata come segue:

```text
bash4llm.d/
├── config/                                # Configurazione e persistenza provider
│   ├── config                             # Variabili e parametri globali utente
│   ├── provider                           # Memorizza il nome del provider attivo
│   ├── provider-url                       # Memorizza l'URL delle API del provider attivo
│   ├── model.<provider>                   # Memorizza il modello di default del provider
│   ├── keys.enc                           # Chiave Vault cifrata con Master Password
│   ├── keys.rec                           # Chiave Vault cifrata con Recovery Key offline
│   ├── keys.dat                           # Database cifrato contenente il JSON delle chiavi API
│   ├── providers/                         # Cartella per configurazioni avanzate
│   │   └── hf_endpoints                   # Mappatura modelli/endpoint di Hugging Face
│   └── ui_state/                          # Cartella di stato per GUI ed automazioni
│       ├── last_api.json                  # Stato dell'ultima chiamata API
│       ├── last_history.json              # Stato dell'ultimo output salvato
│       ├── provider_capabilities.json     # Elenco capacità del provider attivo
│       └── threads/                       # Indici e metadati delle sessioni
│           ├── index.json                 # Elenco strutturato dei thread attivi
│           └── <safe_thread_id>.json      # Metadati dello stato del thread (anonimizzato SHA-256)
├── models/                                # Cataloghi locali dei modelli ammessi
│   └── <provider>.txt                     # Whitelist modelli validati (formato txt)
├── templates/                             # Area prompt template riutilizzabili
├── history/                               # Archiviazione output delle risposte
│   ├── threads/                           # File NDJSON storici dei thread attivi (Core fallback)
│   │   └── <safe_thread_id>.ndjson        # Registro NDJSON anonimizzato SHA-256
│   └── sessions/                          # File NDJSON storici avanzati (Session Engine)
│       ├── <safe_thread_id>.ndjson        # Registro NDJSON principale anonimizzato
│       ├── <safe_thread_id>.001.ndjson    # Segmento storico rotato
│       └── <safe_thread_id>.001.ndjson.gz # Segmento storico rotato e compresso
├── var/                                   # Processi e file di runtime isolati
│   └── run/                              # Directory di runtime di processo (700)
│       └── locks/                         # Directory isolata dei file di blocco (700)
│           ├── models.lock                # Lock di sincronizzazione dei modelli
│           ├── history.lock               # Lock di sincronizzazione della cronologia
│           └── tmp.lock                   # Lock di allocazione file temporanei
├── tmp/                                   # Area sicura ad accesso esclusivo (700)
│   └── rates/                             # Tracciamento transazioni rate limiting (700)
│       └── <safe_thread_id>/              # Timestamp delle richieste per finestra scorrevole
└── extras/                                # Estensioni installate tramite l'installer
    ├── manifest.sha256                    # Manifesto dell'integrità crittografica SHA-256
    ├── chat/                              # Interfaccia di chat interattiva (tui-repl.sh)
    ├── hooks/                             # Moduli di estensione pre/post esecuzione (hook.sh)
    ├── lib/                               # Librerie e moduli helper condivisi
    ├── security/                          # Sicurezza (openssl-helper.sh, verify.sh)
    ├── test/                              # Suite di test e diagnostica automatica
    ├── docs/                              # Documentazione (core-notes.sh, help.txt, BASH4LLM.1)
    ├── providers/                         # Provider aggiuntivi (gemini.sh, huggingface.sh, mistral.sh)
    └── session/                           # Ottimizzazione e sessioni (session-engine.sh)
```
