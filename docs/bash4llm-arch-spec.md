# SPECIFICA TECNICA DEL SISTEMA BASH4LLM (v2.0.0)

## SEZIONE 1: ARCHITETTURA GENERALE E RELAZIONI TRA MACRO-SEZIONI

Il sistema Bash4LLM è strutturato in cinque macro-sezioni logiche, progettate per operare in modo sequenziale e integrato. La stabilità e l'integrità del runtime sono garantite da una gerarchia di dipendenze, requisiti di sistema rigorosi e costanti di sicurezza (invarianti) applicate a livello di file-system.

### 1.1 Dipendenze tra Macro-Sezioni
*   **PRECORE_RUN**: Dipende da `PRECORE_BOOT` per il caricamento dei percorsi canonici, la gestione delle variabili di ambiente, gli helper di codifica/decodifica Base64, l'utilità di acquisizione dei lock esclusivi (`lock_exec`) e l'inizializzazione sicura della directory temporanea (`ensure_run_tmpdir`).
*   **PROVIDER**: Dipende da `PRECORE_BOOT` e `PRECORE_RUN` per la risoluzione degli URL degli endpoint, la verifica delle autorizzazioni di rete, lo staging transazionale dei payload, il buffering dell'I/O e la scrittura atomica dei log e degli stati della UI.
*   **CORE_SETUP**: Dipende da `PRECORE_BOOT`, `PRECORE_RUN` e `PROVIDER` per il dispatching delle chiamate specifiche dei provider, la convalida formale dei parametri CLI, l'estrazione sintattica delle whitelist, l'integrazione del Session Engine esterno e l'archiviazione dello storico.
*   **CORE_PROVIDER**: Dipende da `PRECORE_BOOT`, `PRECORE_RUN` e `CORE_SETUP` per il caricamento protetto dei moduli provider esterni, l'inizializzazione del menu interattivo, l'allineamento automatico dei modelli e la gestione del ciclo di chat o batch.
*   **Tutte le sezioni**: Condividono e dipendono dai requisiti obbligatori di sistema e dalle costanti del runtime globale.

### 1.2 Requisiti Obbligatori di Sistema
Prima di consentire qualunque elaborazione, il sistema verifica la presenza nel percorso di sistema (`PATH`) dei seguenti 24 binari ed utility essenziali. L'assenza di almeno uno di essi causa l'arresto immediato dello script con codice di stato `1`:
1.  `bash`
2.  `jq`
3.  `curl`
4.  `mktemp`
5.  `stat`
6.  `flock`
7.  `base64`
8.  `find`
9.  `awk`
10. `sed`
11. `grep`
12. `xargs`
13. `tr`
14. `sort`
15. `head`
16. `wc`
17. `tee`
18. `date`
19. `mv`
20. `chmod`
21. `cp`
22. `rm`
23. `printf`
24. `type` (o equivalente di shell integrato)

### 1.3 Invarianti Globali di Sicurezza e File-System
Il runtime di Bash4LLM impone regole di isolamento e protezione dei dati persistenti e temporanei per prevenire attacchi di elevazione dei privilegi, manipolazione concorrente ("Race Condition") o iniezione di percorsi ("Directory Traversal"):
*   **Politica dei File Temporanei**: La directory principale `$BASH4LLM_TMPDIR` deve risiedere interamente all'interno della cartella radice `$BASH4LLM_DIR`. È vietato l'uso della cartella globale `/tmp` del sistema operativo per i file temporanei dello script. Il sistema si arresta se `$BASH4LLM_TMPDIR` coincide con `/tmp` o vi risiede direttamente.
*   **Mitigazione Attacchi Symlink**: All'avvio, viene verificato che nessuna delle directory operative dello script (configurazione, modelli, template, storico, sessioni, cache, runtime) sia un collegamento simbolico. Se viene rilevato un symlink su un percorso sensibile, l'esecuzione viene interrotta.
*   **Controllo dei Permessi e Maschera Umask**: All'avvio viene applicata la maschera di processo `umask 077`. Tutte le directory operative vengono create o forzate con permessi `700` (accesso esclusivo per l'utente proprietario). Tutti i file generati (configurazioni, chiavi, cache, risposte, registri) vengono blindati con permessi `600`.
*   **Proprietà dei Moduli Esterni**: Qualunque estensione o modulo provider esterno (`plugin`) deve appartenere all'utente esecutore corrente e non deve presentare permessi di scrittura pubblici o di gruppo (`group/world-writable`).
*   **Invariante del File-System per Atomicità**: Ogni operazione di scrittura atomica viene eseguita scrivendo in un file temporaneo situato all'interno dello stesso file-system (stessa partizione fisica) del file di destinazione finale. Questo assicura che l'operazione di spostamento (`mv`) si traduca in una singola chiamata di sistema atomica a livello di inode, eliminando il rischio di letture parziali da parte di istanze concorrenti.

---

## SEZIONE 2: PRECORE_BOOT

Questa macro-sezione gestisce l'inizializzazione primaria della shell, l'analisi preventiva degli argomenti CLI, la convalida dell'ambiente operativo e l'esposizione delle funzioni fondamentali di logging, codifica e I/O.

### 2.1 Variabili di PRECORE_BOOT
*   **SCRIPT_NAME**: Nome identificativo del programma (costante: `"bash4llm"`).
*   **SCRIPT_VERSION**: Versione corrente del software (costante: `"2.0.0"`).
*   **SCRIPT_DATE**: Data di rilascio del software (costante: `"2026-06-09"`).
*   **Costanti d'Errore Globali**:
    *   `BASH4LLM_ERR_NO_API_KEY` (Valore `10`): Assenza di una chiave API valida.
    *   `BASH4LLM_ERR_BAD_MODEL` (Valore `11`): Modello non supportato, non valido o escluso.
    *   `BASH4LLM_ERR_CURL_FAILED` (Valore `12`): Fallimento di rete o errore di curl.
    *   `BASH4LLM_ERR_INVALID_JSON` (Valore `13`): Sintassi JSON non conforme o corrotta.
    *   `BASH4LLM_ERR_NO_PROMPT` (Valore `14`): Assenza di prompt testuale o JSON di input.
    *   `BASH4LLM_ERR_TMP` (Valore `15`): Errore di I/O, permessi o lock sui file temporanei.
    *   `BASH4LLM_ERR_API` (Valore `16`): Errore applicativo o codice HTTP non valido inviato dalle API.
*   **Alias delle Costanti**: `BASH4LLMERRNOAPIKEY` (10), `BASH4LLMERRBAD_MODEL` (11), `BASH4LLMERRCURL_FAILED` (12), `BASH4LLMERRINVALID_JSON` (13), `BASH4LLMERRNO_PROMPT` (14), `BASH4LLMERRTMP` (15), `BASH4LLMERRAPI` (16).
*   **Variabili Lette**:
    *   `DEBUG`, `BASH4LLM_DEBUG`: Configurazione dei tracciamenti di sviluppo.
    *   `BASH4LLM_DIR`, `BASH4LLM_ROOT`: Percorso radice di installazione.
    *   `BASH4LLM_CONFIG_DIR`, `BASH4LLM_MODELS_DIR`, `BASH4LLM_TEMPLATES_DIR`, `BASH4LLM_HISTORY_DIR`, `BASH4LLM_TMPDIR`, `BASH4LLM_EXTRAS_DIR`, `PROVIDERS_DIR`: Directory di lavoro operative.
    *   `MAX_STAGE_BYTES`: Soglia massima di byte per i payload Base64 (default `10485760` byte, pari a 10MB).
    *   `MAX_MODELS`: Limite massimo di modelli importabili locali (default `200`).
    *   `BASH4LLM_LOG`: Percorso del file di tracciamento centralizzato.
    *   `BASH4LLM_LOCK_TIMEOUT_TMP`, `BASH4LLM_LOCK_TIMEOUT_MODELS`, `BASH4LLM_LOCK_TIMEOUT_HISTORY`: Timeout per i lock esclusivi (default `10` secondi).
*   **Variabili Scritte/Modificate**:
    *   `SCRIPTDIR`: Risoluzione assoluta del percorso dello script.
    *   `CANONICAL_EXTRAS_DIR`, `LEGACY_EXTRAS_DIR`: Percorsi normalizzati delle estensioni.
    *   `MODELS_FILE`: File locale della lista dei modelli (`models.txt`).
    *   `PROVIDER_FILE`: File locale contenente l'ultimo provider selezionato (`provider`).
    *   `SESSION_DIR`: Cartella di registrazione dei log delle chat multi-turno.
    *   `MODELS_LOCK`, `HISTORY_LOCK`, `TMP_LOCK`: Percorsi dei rispettivi file di lock esclusivi.
    *   `B64_WRAP_OPT`, `B64_DECODE_OPT`: Opzioni e flag di formattazione rilevati per il comando `base64`.
    *   `RUN_TMPDIR`, `PAYLOAD`, `RESP`, `ERRF`: Canali e cartelle temporanee del runtime di istanza.

### 2.2 Funzioni di PRECORE_BOOT

#### resolve_script_dir
*   **Ruolo**: Identifica la directory reale in cui risiede lo script risolvendo in modo ricorsivo eventuali link simbolici sul file-system.
*   **Input**: Nessuno (analizza la variabile speciale `$0`).
*   **Output**: Stampa su standard output il percorso assoluto normalizzato.
*   **Errori**: Restituisce un percorso relativo approssimativo in caso di totale fallimento di risoluzione delle utility.

#### canonical_config_dir
*   **Ruolo**: Restituisce il percorso di configurazione normalizzato eliminando le barre finali ridondanti.
*   **Input**: Variabile `$BASH4LLM_CONFIG_DIR`.
*   **Output**: Stampa il percorso normalizzato su standard output.

#### canonical_provider_file / canonical_provider_url_file
*   **Ruolo**: Generano rispettivamente il percorso assoluto del file di persistenza del provider selezionato (`/provider`) e dell'endpoint API specifico del provider attivo (`/provider-url`) posizionati sotto la cartella canonica di configurazione.
*   **Input**: Nessuno.
*   **Output**: Stampa del percorso risultante su standard output.

#### canonical_model_file
*   **Ruolo**: Genera il percorso del file in cui memorizzare il modello predefinito per un determinato provider (`/model.<provider>`).
*   **Input**: Nome del provider come primo parametro.
*   **Output**: Stampa del percorso su standard output. Ritorna errore non-zero se l'input è assente.

#### ensure_api_key_for_provider
*   **Ruolo**: Convalida la presenza di una chiave API valida nell'ambiente per il provider specificato.
*   **Input**: Nome del provider.
*   **Logica**:
    1.  Calcola il nome della variabile attesa tramite `provider_api_env_var_name`.
    2.  Se presente nell'ambiente, la esporta e sincronizza la variabile globale generica `GROQ_API_KEY`.
    3.  Se assente in ambiente non interattivo, restituisce `BASH4LLMERRNOAPIKEY`.
    4.  Se assente in ambiente interattivo (TTY), richiede l'inserimento allo standard input. Pulisce la stringa ricevuta eliminando prefissi di assegnazione come `export` e spazi. Esporta la chiave e visualizza su standard error le istruzioni per il salvataggio permanente nella configurazione utente.
*   **Output**: Ritorna codice di stato `0` in caso di successo, altrimenti `BASH4LLMERRNOAPIKEY`.

#### enforce_network_policy
*   **Ruolo**: Centralizza la valutazione sull'opportunità di inibire le chiamate di rete esterne.
*   **Input**: Analizza i flag `$DRY_RUN`, `$BASH4LLM_SKIP_NETWORK`, `$BASH4LLM_ENFORCE_NO_NETWORK_IF_QUIET`, `$QUIET`.
*   **Output**: Ritorna codice `1` se la rete è bloccata o si opera in modalità simulazione (dry-run), `0` se le chiamate esterne sono ammesse.

#### log_prefix / log_info / log_warn / log_error / dbg
*   **Ruolo**: Gestiscono la formattazione, la visualizzazione e l'archiviazione dei log strutturati.
*   **Input**: Categoria e testo del messaggio.
*   **Logica**:
    *   `log_prefix` genera l'intestazione standard `bash4llm: <SCRIPT_NAME>: `.
    *   Tutti i messaggi vengono indirizzati esclusivamente su standard error (`stderr`).
    *   Se `$BASH4LLM_LOG` è configurato, i log vengono registrati nel file con data in formato UTC e categoria associata.
    *   `dbg` invia log di diagnostica immediata solo se la variabile globale `$DEBUG` è impostata su `1`.

#### ensure_config_dir
*   **Ruolo**: Crea e blinda la directory di configurazione utente.
*   **Input**: Variabile `$BASH4LLM_CONFIG_DIR`.
*   **Logica**: Crea la cartella se assente applicando permessi `700`. Scrive e cancella immediatamente un file temporaneo di prova al suo interno per verificare i permessi effettivi di I/O sul file-system ospite.
*   **Output**: Ritorna codice `0` se la directory è pronta e scrivibile, `1` in caso di errore.

#### write_provider_url_if_missing
*   **Ruolo**: Salva l'URL delle API di un provider in modo permanente e transazionale se il file corrispondente risulta assente.
*   **Input**: Nome del provider, stringa dell'URL.
*   **Logica**: Crea la gerarchia di directory, alloca un file temporaneo, vi scrive l'URL, imposta i permessi a `600`, acquisisce un lock esclusivo sulla cartella e sposta atomicamente il file temporaneo nella destinazione definitiva.
*   **Output**: Ritorna codice `0` in caso di successo, non-zero se falliscono le operazioni su disco.

#### resolve_provider_url
*   **Ruolo**: Identifica ed esporta l'URL di connessione per le API.
*   **Input**: Nome del provider (default `$PROVIDER`).
*   **Logica**: Ispeziona prioritariamente le variabili d'ambiente `$BASH4LLM_API_URL` o `$BASH4LLM_PROVIDER_URL`. In assenza di esse, legge la prima riga del file canonico dell'URL del provider. Se il file non esiste e il provider attivo è `"groq"`, esporta l'endpoint nativo di default di Groq.
*   **Output**: Esporta la variabile `$BASH4LLM_PROVIDER_URL` e ritorna codice `0`. Ritorna `1` in caso di fallimento di risoluzione.

#### provider_api_env_var_name
*   **Ruolo**: Calcola il nome standardizzato della variabile d'ambiente deputata a contenere la chiave API di un provider.
*   **Input**: Nome del provider.
*   **Output**: Stampa su standard output il nome convertito in maiuscolo, rimpiazzando caratteri speciali non alfanumerici con underscore `_` e annettendo il suffisso `_API_KEY` (es. `"gemini"` diventa `"GEMINI_API_KEY"`).

#### is_valid_json_string / is_valid_json_file / jq_safe
*   **Ruolo**: Convalidano la conformità sintattica di dati in formato JSON ed eseguono query protette.
*   **Input**: Stringa o file da analizzare, filtri o query per `jq`.
*   **Logica**:
    *   `is_valid_json_string` e `is_valid_json_file` utilizzano `jq` in modalità silenziosa per verificare la validità sintattica.
    *   `jq_safe` esegue query strutturate su file JSON; in caso di errore o sintassi non conforme, scrive le informazioni di errore nel canale `$ERRF` per l'ispezione dello sviluppatore, senza interrompere l'esecuzione complessiva del runtime.
*   **Output**: Ritorna codice `0` se il JSON o l'espressione sono validi, altrimenti ritorna codice non-zero.

#### b64encode / b64decode / b64_atomic_write / b64_atomic_read / stage_b64
*   **Ruolo**: Gestiscono la codifica/decodifica Base64 e lo staging transazionale dei payload.
*   **Logica**:
    *   `b64encode` rimuove tutti i caratteri di a capo (`tr -d '\r\n'`) restituendo il flusso in un'unica riga su standard output.
    *   `b64decode` applica i flag ottimali rilevati a runtime (`$B64_DECODE_OPT`).
    *   `b64_atomic_write` esegue la codifica Base64 di un flusso letto da `stdin`, scrivendolo in un file temporaneo protetto, impostando permessi `600`, acquisendo un lock esclusivo ed eseguendo lo spostamento atomico definitivo.
    *   `b64_atomic_read` legge un file codificato in Base64 ed invia il flusso decodificato a standard output.
    *   `stage_b64` verifica che la dimensione del file sorgente (o dello standard input) non ecceda la soglia `$MAX_STAGE_BYTES`. Genera un file temporaneo sicuro con permessi `600` tramite `_tmpf` per memorizzarvi la codifica Base64. Utilizza `lock_exec` per spostare il file transizionalmente sul percorso di staging finale. Se riceve un solo parametro, assume che l'input debba essere letto da `stdin`.
*   **Output**: Ritorna codice `0` se completato con successo, altrimenti non-zero.

#### lock_exec
*   **Ruolo**: Garantisce l'esecuzione esclusiva e concorrente di comandi arbitrari sfruttando l'utility `flock` a livello di file-system.
*   **Input**: Percorso del file di lock, timeout numerico in secondi (default `10`), seguiti dal delimitatore `--` e dal comando con i relativi argomenti.
*   **Logica**: Crea la cartella del lock se mancante, tenta l'acquisizione del lock esclusivo tramite `flock`. Se il timeout scade senza acquisizione, fallisce emettendo un errore su `stderr` senza avviare il comando.
*   **Output**: Restituisce il codice di uscita del comando eseguito, `124` in caso di scadenza del timeout, `2` in caso di errori strutturali o di sintassi.

#### _mktemp_in_dir / atomic_write
*   **Ruolo**: Creano risorse temporanee ed eseguono scritture transazionali.
*   **Logica**:
    *   `_mktemp_in_dir` genera in sicurezza un file temporaneo univoco all'interno della cartella di destinazione indicata applicando la maschera `umask 077` e restituendone il percorso assoluto.
    *   `atomic_write` acquisisce un flusso dati da standard input, lo alloca in un file temporaneo posizionato all'interno dello stesso percorso di destinazione del file finale (per preservare l'atomicità di spostamento), imposta i permessi del file a `600`, acquisisce un lock esclusivo tramite `lock_exec` (con timeout di 10 secondi) e sposta definitivamente il file temporaneo sovrascrivendo l'originale.
*   **Output**: Ritorna codice `0` in caso di completamento, altrimenti restituisce codice non-zero di fallimento.

#### ensure_run_tmpdir / cleanup_tmp
*   **Ruolo**: Alloca e isola la directory operativa temporanea esclusiva per l'istanza o sotto-shell dello script in esecuzione.
*   **Logica**:
    *   `ensure_run_tmpdir` crea una sottocartella provvisoria `$RUN_TMPDIR` all'interno della directory temporanea principale sicura `$BASH4LLM_TMPDIR`, blindandone i permessi a `700`.
    *   Inizializza tre file vuoti con permessi `600`: `$PAYLOAD` (payload inviato alle API), `$RESP` (risposta ricevuta dal server o diagnostica) e `$ERRF` (log di errore interni).
    *   Registra una trap di sistema (`EXIT`, `INT`, `TERM`) incaricata della pulizia automatica ricorsiva richiamando `cleanup_tmp`.
    *   Se abilitato il debug di conservazione (`$DEBUG_PRESERVE == 1`), la rimozione fisica dei file temporanei viene bypassata.
    *   Se richiamata con il parametro `--print`, stampa semplicemente il percorso su stdout ed esce.
*   **Output**: Esporta le variabili `$RUN_TMPDIR`, `$PAYLOAD`, `$RESP`, `$ERRF`. Ritorna `0` in caso di successo, altrimenti `BASH4LLMERRTMP`.

#### ui_state_write
*   **Ruolo**: Persiste in modo atomico lo stato corrente dell'interfaccia utente dello script in formato JSON.
*   **Input**: Nome del file di stato, stringa del contenuto JSON.
*   **Logica**: Crea la cartella degli stati sotto `$BASH4LLM_CONFIG_DIR/ui_state` o `$RUN_TMPDIR`, esegue la scrittura transazionale atomica con permessi `600` e lock concorrente.
*   **Output**: Ritorna codice `0` se completato, altrimenti `1` in caso di anomalie fisiche di I/O.

#### load_provider_module
*   **Ruolo**: Importa in sicurezza i metodi esposti da moduli provider esterni (plugin).
*   **Input**: Nome identificativo del provider.
*   **Logica**:
    1.  Verifica che il modulo non corrisponda al modulo nativo integrato `"groq"` (il quale non richiede file esterni).
    2.  Verifica che la directory dei moduli e il file fisico esistano e non siano link simbolici.
    3.  Verifica che l'utente esecutore corrente sia il proprietario del file e che quest'ultimo non sia modificabile da altri o da gruppi (`_is_world_writable` restituisce falso).
    4.  Esegue un'analisi sintattica formale via `bash -n`.
    5.  Calcola la firma crittografica del file prima dell'importazione.
    6.  Esegue il sourcing provvisorio del modulo all'interno di una subshell isolata per mappare le funzioni dichiarate. Verifica che siano implementate le due funzioni obbligatorie richieste: `buildpayload_<provider>` e `call_api_<provider>`.
    7.  Calcola nuovamente la firma crittografica del file dopo l'inclusione per intercettare tentativi di manomissione in tempo reale.
    8.  Disabilita transitoriamente l'opzione di shell `nounset` (`set -u`), esegue il sourcing del modulo nel contesto principale della shell e ne mappa le capacità salvandole in `provider_capabilities.json` tramite `ui_state_write`.
*   **Output**: Ritorna codice `0` in caso di caricamento e convalida superati con successo, altrimenti `1`.

### 2.3 Flussi e Blocchi Logici di PRECORE_BOOT

#### PRECORE_BOOT_SETUP_SHELL
*   **Azione**: Configura i parametri operativi restrittivi della shell Bash all'avvio assoluto dello script:
    *   `set -e`: Arresto immediato se un comando non gestito restituisce uno stato non-zero.
    *   `set -u`: Arresto immediato in caso di tentativi di espansione di variabili non dichiarate.
    *   `set -o pipefail`: Propaga lo stato d'errore all'interno delle pipeline.

#### PRECORE_BOOT_SOURCE_ONLY_CHECK
*   **Azione**: Verifica se la variabile `$BASH4LLM_SOURCE_ONLY` è impostata su `1`. In tal caso, lo script interrompe l'esecuzione del blocco di istruzioni principale e ritorna immediatamente il controllo al chiamante (restituendo codice `0`), consentendo esclusivamente l'importazione passiva e provvisoria di variabili e funzioni.

#### PRECORE_BOOT_VERIFY_CMDS
*   **Azione**: Scansiona il sistema ospite per verificare la presenza delle 24 utilità richieste. Se una o più mancano, invia un messaggio di errore a standard error ed interrompe il runtime con codice `1`.

#### PRECORE_BOOT_DIR_RESOLUTION
*   **Azione**: Determina la directory principale `$BASH4LLM_DIR`. Verifica l'ambiente adottando in ordine di priorità la variabile `$BASH4LLM_DIR` configurata, `$BASH4LLM_ROOT` (derivando la cartella `bash4llm.d`), o calcolando il percorso predefinito relativo a `$SCRIPTDIR/bash4llm.d`.

#### PRECORE_BOOT_FALLBACK_PROVIDERS
*   **Azione**: Esporta globalmente la directory `$PROVIDERS_DIR`. Se non pre-configurata, la localizza sotto la directory delle estensioni utente nel percorso `$BASH4LLM_EXTRAS_DIR/providers`.

#### PRECORE_BOOT_DIR_INVARIANTS
*   **Azione**: Convalida che la directory temporanea `$BASH4LLM_TMPDIR` risieda all'interno del percorso principale `$BASH4LLM_DIR` e che non coincida o risieda sotto `/tmp`. In caso contrario, interrompe l'esecuzione.

#### PRECORE_BOOT_ENSURE_CONFIG_DIR / PRECORE_BOOT_FAILFAST_CONFIG_DIR
*   **Azione**: Richiama `ensure_config_dir` per configurare e testare la cartella. Se l'operazione fallisce o se il percorso normalizzato risulta vuoto, interrompe con codice `BASH4LLMERRTMP` o `1` a seconda del livello di anomalia riscontrato.

#### PRECORE_BOOT_NORMALIZE_DEBUG
*   **Azione**: Sincronizza ed allinea i parametri di debug ereditando `$BASH4LLM_DEBUG` se `$DEBUG` non è esplicitamente impostato dall'utente, forzando il valore di default a `0`.

#### PRECORE_BOOT_EARLY_PRINT_CONFIG
*   **Azione**: Analizza sequenzialmente gli argomenti della riga di comando passati in input all'avvio assoluto dello script. Se intercetta opzioni di ispezione dei percorsi (`--print-config-dir`, `--print-provider-file`, `--print-model-file <provider>`), stampa immediatamente il percorso canonico associato su standard output e termina il processo con codice `0` (o `2` in caso di sintassi non corretta), prima di allocare o inizializzare il runtime completo. Se intercetta `-h` o `--help`, interrompe questa scansione anticipata.

#### PRECORE_BOOT_MKDIR_PERMS
*   **Azione**: Crea l'intera gerarchia di directory operative (`sessions`, `config`, `models`, `templates`, `history`, `tmp`, `extras`, `providers`). Verifica che nessuna directory sia un collegamento simbolico, imposta i permessi di tutte le cartelle a `700` e configura `umask 077` per blindare ogni risorsa creata in seguito.

#### PRECORE_BOOT_DETECT_B64_OPTS
*   **Azione**: Esegue `_detect_base64_opts` per determinare se il sistema ospite adotta standard GNU/Linux (esportando `-w0` in `$B64_WRAP_OPT` e `-d` in `$B64_DECODE_OPT`) o standard macOS/Darwin/BSD (esportando stringa vuota in `$B64_WRAP_OPT` e `-D` in `$B64_DECODE_OPT`).

## SEZIONE 3: PRECORE_RUN

Questa macro-sezione si occupa della persistenza a lungo termine, della gestione dello storico delle conversazioni, della cache di sessione, della compilazione dei manifest multimediali e della conformità di sicurezza per l'accesso ai file.

### 3.1 Variabili di PRECORE_RUN
*   **Variabili Lette**:
    *   `BASH4LLM_ROTATE_HISTORY`: Flag (`0` o `1`) per l'attivazione della manutenzione automatica del registro storico (default `0`).
    *   `BASH4LLM_HISTORY_MAX_FILES`: Numero massimo di file memorizzabili nello storico delle risposte (default `100`).
    *   `BASH4LLM_HISTORY_MAX_BYTES`: Peso totale cumulativo dei file dello storico espresso in byte (default `104857600`, pari a 100MB).
    *   `BASH4LLM_HISTORY_KEEP_DAYS`: Soglia temporale di mantenimento dei log espressa in giorni (default `90`).
    *   `SESSION_CACHE_DIR`: Directory di allocazione dei file temporanei della cache delle sessioni.
    *   `CONTENT`: Prompt testuale o testo inserito dall'utente.
    *   `JSON_INPUT`: Input strutturato in formato JSON fornito dall'utente.
    *   `SESSION_ID`: Identificatore alfanumerico della sessione attiva.
    *   `SESSION_WINDOW`: Numero massimo di messaggi storici da recuperare per comporre la finestra di contesto.
    *   `TEMPLATE`: Nome del file modello da applicare per arricchire il prompt.
    *   `BATCH_FILE`: Percorso del file contenente l'elenco dei prompt da elaborare.
    *   `CHAT_MODE`: Flag booleano (`0` o `1`) per attivare la chat interattiva multi-turno.
    *   `SET_DEFAULT_MODEL`: Modello da impostare come scelta predefinita per il provider attivo.
    *   `REFRESH_MODELS`: Flag booleano (`0` o `1`) per forzare l'allineamento dei modelli locali tramite API.
    *   `LIST_MODELS`: Flag per stampare l'elenco dei modelli supportati.
    *   `FORCE_SAVE_MODE`: Regola il salvataggio dei risultati (`save` forza la scrittura, `nosave` la inibisce, `0` adotta il comportamento standard).
    *   `OUT_PATH`: Percorso di salvataggio dei risultati personalizzato.
    *   `SYSTEM_PROMPT`: Prompt di istruzione di sistema per il modello LLM.
    *   `TURE`, `TEMPERATURE`: Temperatura di campionamento delle API (valore decimale, default `1.0`).
    *   `MAX_TOKENS`: Limite di token generabili nella risposta (default `4096`).
    *   `MODEL`: Modello LLM richiesto.
    *   `AUTO_POLICY`: Politica di selezione del modello di fallback (default `"preferred"`).
    *   `QUIET`: Flag booleano per inibire l'emissione di log informativi (`0` o `1`).
    *   `DRY_RUN`: Flag booleano per simulare le transazioni senza traffico di rete.
    *   `STREAM_MODE`: Flag booleano per attivare lo streaming dei token in tempo reale.
    *   `OUTPUT_MODE`: Stile di visualizzazione dei risultati (`text`, `raw`, `json`, `pretty`).
    *   `THRESHOLD`: Limite minimo di caratteri per attivare l'archiviazione automatica delle risposte lunghe (default `1000`).
    *   `MAX_RETRIES`: Limite di tentativi di connessione per errori di rete temporanei (default `3`).
    *   `SUPPORTED_PROVIDERS`: Elenco dei provider supportati ed installati.
    *   `PROVIDER`: Identificatore del provider API attivo.
    *   `CURL_BASE_OPTS`: Array delle opzioni immutabili di rete passate a `curl` (`--silent`, `--show-error`, `--no-buffer`, `--max-time 120`).
*   **Variabili Scritte/Modificate**:
    *   Normalizzazione ed allineamento di `$ALLOW_API_CALLS`, `$DRY_RUN`, `$DEBUG` ai valori numerici `0` o `1` tramite l'utility `_normalize_bool_env`.

### 3.2 Funzioni di PRECORE_RUN

#### rotate_history
*   **Ruolo**: Esegue la manutenzione della directory storica prevenendo la saturazione del disco o l'accumulo di file obsoleti.
*   **Input**: Timeout del lock (default `$BASH4LLM_LOCK_TIMEOUT_HISTORY`).
*   **Logica**:
    1.  Acquisisce il lock esclusivo su `$HISTORY_LOCK`.
    2.  Identifica ed elimina i file all'interno di `$BASH4LLM_HISTORY_DIR` che risultano più vecchi di `$BASH4LLM_HISTORY_KEEP_DAYS`.
    3.  Se il numero di file rimanenti supera `$BASH4LLM_HISTORY_MAX_FILES`, esegue una purga progressiva partendo dai più datati.
    4.  Se la dimensione cumulativa in byte supera `$BASH4LLM_HISTORY_MAX_BYTES`, scansiona i file ordinati temporalmente tramite `list_files_sorted_by_mtime` ed elimina i più vecchi fino al rientro sotto la soglia stabilita.
*   **Output**: Rimuove fisicamente i file dal disco e ritorna codice `0`.

#### save_to_history
*   **Ruolo**: Archivia in modo sicuro e transazionale il testo generato dal modello in un file cronologico unico.
*   **Input**: Contenuto testuale da salvare.
*   **Logica**:
    1.  Crea la directory storica se mancante.
    2.  Genera un file temporaneo in transizione.
    3.  Scrive il contenuto, imposta i permessi a `600`, acquisisce il lock esclusivo su `$HISTORY_LOCK`.
    4.  Sposta il file temporaneo nella destinazione finale all'interno di `$BASH4LLM_HISTORY_DIR`, contrassegnando il nome del file con data in formato ISO 8601 UTC e PID del processo chiamante.
    5.  Aggiorna lo stato JSON `last_history.json` registrandone i metadati (percorso, nome, timestamp UTC, dimensione in byte) tramite la funzione `ui_state_write`.
    6.  Se `$BASH4LLM_ROTATE_HISTORY` è abilitato, avvia asincronamente `rotate_history`.
*   **Output**: Ritorna codice `0` in caso di successo, altrimenti ritorna codice d'errore temporaneo.

#### manifest_create / manifest_add_part / manifest_read
*   **Ruolo**: Gestiscono la compilazione, l'aggiornamento e la lettura di un manifesto in formato JSON multimediale accoppiato a una versione specchio in Base64 (`.b64`).
*   **Logica**:
    *   `manifest_create` alloca un manifesto JSON strutturalmente vuoto sotto lock esclusivo di sicurezza, impostando i permessi a `600` e rigenerandone simultaneamente la controparte codificata `.b64`.
    *   `manifest_add_part` codifica in Base64 un file risorsa multimediale di input inserendolo in un'area di staging protetta. Sotto lock, aggiorna il manifesto JSON tramite `jq` inserendovi i metadati della parte (nome, percorso di staging, codifica, tipo di risorsa) e rigenera la copia Base64 del manifesto complessivo.
    *   `manifest_read` accede al file manifesto decodificandolo al volo dal file specchio `.b64` qualora il file JSON di origine non sia immediatamente leggibile.

#### _get_perm_string / _get_owner / _get_file_signature / getfile_signature / _is_world_writable
*   **Ruolo**: Interrogano il file-system in modo portabile fornendo informazioni di conformità e sicurezza dei file.
*   **Logica**:
    *   `_get_perm_string` restituisce la stringa simbolica dei permessi (es. `-rw-------`) gestendo le discrepanze strutturali di `stat` tra Linux e macOS.
    *   `_get_owner` restituisce il nome dell'utente proprietario del file.
    *   `_get_file_signature` (e il suo wrapper `getfile_signature`) calcola l'impronta di stato di una risorsa. Se `sha256sum` è disponibile e `$BASH4LLM_SIG_HASH` è attivo, genera l'hash SHA-256 del contenuto. In aggiunta, concatena i metadati fisici della risorsa (device, inode, size, ctime, mtime, uid, gid, permessi ottali) in una stringa protetta per rilevare alterazioni di data o contenuto.
    *   `_is_world_writable` analizza la stringa simbolica dei permessi e ritorna codice `0` (vulnerabile) se i permessi indicano che la risorsa è modificabile da utenti di gruppi esterni o pubblici, altrimenti ritorna `1`.

#### make_tmpdir / _tmpf
*   **Ruolo**: Generano cartelle e file temporanei protetti da lock all'interno del perimetro di sicurezza di `$BASH4LLM_TMPDIR`.
*   **Logica**:
    *   `make_tmpdir` crea una directory temporanea univoca applicando permessi `700` sotto la protezione del lock esclusivo `$TMP_LOCK`.
    *   `_tmpf` verifica che la directory temporanea principale non sia un link simbolico. Convalida che il percorso di base in cui si desidera allocare il file o cartella risieda strettamente all'interno di `$BASH4LLM_TMPDIR` per mitigare attacchi di Directory Traversal. Applica `umask 077` e alloca la risorsa (permessi `600` per i file, `700` per le directory) tramite `mktemp`.
*   **Output**: Stampano il percorso finale su stdout. Ritorna codice `BASH4LLMERRTMP` in caso di anomalie.

#### session_validate_id / session_now_ts / session_messages_tmp_path / session_sanitize_cmd
*   **Ruolo**: Utility per la convalida dei contesti e l'allineamento dei registri.
*   **Logica**:
    *   `session_validate_id` convalida sintatticamente l'ID sessione fornito tramite pattern regex (`^[A-Za-z0-9._-]+$`) con lunghezza compresa tra 1 e 128 caratteri, ritornando `0` se conforme.
    *   `session_now_ts` restituisce l'ora corrente in formato ISO 8601 UTC.
    *   `session_messages_tmp_path` calcola la posizione assoluta del file JSON provvisorio destinato ad accumulare i messaggi storici all'interno di `$RUN_TMPDIR`.
    *   `session_sanitize_cmd` ripulisce e sanifica le stringhe dei comandi registrate nello storico, rimuovendo le assegnazioni di variabili sensibili e rimpiazzando chiavi o token privati con l'etichetta `[REDACTED]`, troncando l'output a un limite di 256 caratteri.

#### session_read_window
*   **Ruolo**: Estrae dal file log NDJSON della sessione indicata la finestra degli ultimi `$n` messaggi registrati.
*   **Logica**:
    1.  Acquisisce il lock sul file di sessione.
    2.  Estrae le ultime righe del file NDJSON (usando `awk` multiriga in presenza di blocchi vuoti o `tail` per flussi piatti).
    3.  Normalizza i record in un array ordinato in formato JSON valido, salvandolo nel file di output provvisorio.
    4.  Calcola il conteggio dei messaggi e la data dell'ultimo record, persistendoli in modo atomico nel file di stato `sessions/<id>.json` tramite la funzione `ui_state_write`.
*   **Output**: Ritorna codice `0` se completato con successo.

#### session_append
*   **Ruolo**: Inserisce un nuovo messaggio nel registro NDJSON della sessione specificata garantendo l'idempotenza cross-processo.
*   **Logica**:
    1.  Se non fornito, genera deterministicamente un ID univoco del messaggio calcolando l'hash SHA-256 del testo normalizzato con timestamp ISO e valore random, impedendo inserimenti duplicati causati da conflitti di rete o reinvii.
    2.  Verifica la presenza di cartelle marcatrici (`.lockdir`) associate al PID del processo per evitare scritture parallele non controllate.
    3.  Acquisisce il lock esclusivo sul file NDJSON di sessione, verifica l'assenza del record ed esegue l'accodamento in coda al file NDJSON con permessi `600`.
    4.  Aggiorna i metadati di sessione via `ui_state_write` nel file `sessions/<id>.json` e inserisce l'ID sessione nel file globale degli indici `sessions/index.json` per l'interfaccia.
*   **Output**: Ritorna codice `0`, o `1` in caso di fallimento della transazione (provvedendo alla rimozione della directory marker).

#### session_cache_key / session_cache_get / session_cache_set / session_cache_invalidate
*   **Ruolo**: Gestiscono la memorizzazione temporanea e la lettura dei record di cache.
*   **Logica**:
    *   `session_cache_key` calcola la chiave identificativa univoca accoppiando l'ID sessione con l'hash SHA-256 dei parametri di invocazione.
    *   `session_cache_get` legge il file di cache associato. Estrae la prima riga (timestamp Unix di scadenza) e la confronta con l'ora corrente del sistema: se il record è scaduto, cancella fisicamente il file dal disco e restituisce errore. Se valido, riversa i dati su stdout o nel file di output indicato.
    *   `session_cache_set` persiste i dati impostando un tempo di validità personalizzato (TTL, default `300` secondi). Scrive il timestamp di scadenza assoluta nella prima riga, annette in coda il payload, archiviando il file in modo atomico con permessi `600`.
    *   `session_cache_invalidate` invalida i file di cache. Se riceve parametri specifici, rimuove esclusivamente quel record, altrimenti cancella ricorsivamente tutti i file di cache associati a quell'ID sessione.

#### _normalize_bool_env
*   **Ruolo**: Uniforma i parametri di configurazione booleani d'ambiente convertendo stringhe permissive (`"true"`, `"yes"`, `"1"`) nel valore intero `1` (attivo) o `0` (inattivo), esportandoli per la coerenza globale.
*   **Input**: Nessuno.

### 3.3 Flussi e Blocchi Logici di PRECORE_RUN

#### block_mkdir_session_cache
*   **Azione**: Crea ed alloca la directory dedicata alla cache delle sessioni (`$SESSION_CACHE_DIR`), blindandone i permessi d'accesso a `700`.

#### block_ensure_config_dir
*   **Azione**: Garantisce la stabilità del runtime richiamando `ensure_config_dir` o verificando preventivamente la presenza della directory utente per accertare che non operi in contesti corrotti o non scrivibili.

#### block_ensure_run_tmpdir
*   **Azione**: Se lo script non è importato in modalità solo-sorgente (`$BASH4LLM_SOURCE_ONLY == 0`), invoca `ensure_run_tmpdir` per allineare l'ambiente transazionale di istanza. Se fallisce, termina l'esecuzione con codice `BASH4LLMERRTMP`.

#### block_normalize_bool_env_call
*   **Azione**: Esegue l'allineamento e la normalizzazione logica di tutti i parametri di controllo richiamando `_normalize_bool_env`.

#### block_last_check_lines_default
*   **Azione**: Verifica se la variabile `$LAST_CHECK_LINES` è impostata nell'ambiente utente. In caso di assenza, ne assegna il valore di default a `50` per le operazioni di scansione storica.

---

## SEZIONE 4: PROVIDER (Core & Groq)

Questa macro-sezione stabilisce i criteri per l'allineamento dei provider, la validazione delle interfacce obbligatorie e l'implementazione del modulo integrato Groq.

### 4.1 Variabili di PROVIDER
*   **Variabili Lette**:
    *   `GROQ_API_KEY`: Chiave API del provider Groq.
    *   `PROVIDER_API_ENV_groq`: Variabile d'ambiente personalizzata per la chiave API di Groq.
*   **Variabili Scritte/Modificate**:
    *   `BASH4LLM_TMP_PAYLOAD`: Percorso del file del payload generato.
    *   `PAYLOAD`: Percorso normalizzato del file di payload inviato alle API.
    *   `RESP`: Percorso del file di risposta finale dell'istanza.
    *   `MODELS_FILE`: Percorso locale del file contenente l'elenco dei modelli.
    *   Aggiornamento del file di stato `last_api.json` scritto tramite `ui_state_write`.

### 4.2 Funzioni di Interfaccia dei Provider (Modulo Groq)

#### _cleanup_local_tmp
*   **Ruolo**: Rimuove in sicurezza dal disco i file temporanei locali generati nel corso delle chiamate.

#### buildpayload_groq
*   **Ruolo**: Compila, struttura e valida il file JSON di payload da trasmettere alle API di Chat-Completion.
*   **Logica**:
    1.  Verifica e garantisce l'esistenza della directory `$RUN_TMPDIR`.
    2.  Valida la correttezza di temperatura (`$TURE`, default `1.0`) e token massimi (`$MAX_TOKENS`, default `4096`), convertendoli in valori numerici JSON validi.
    3.  Estrae i messaggi seguendo l'ordine di precedenza:
        *   Se `$JSON_INPUT` è valorizzato, ne valida la sintassi e lo adotta.
        *   Se presente `$MESSAGES_JSON`, lo adotta.
        *   Se è indicato `$BUILD_MESSAGES_FILE`, ne valida il contenuto e lo adotta.
        *   Altrimenti, converte il prompt testuale raw `$CONTENT` in un record utente standard.
    4.  In assenza totale di input, genera un record utente con testo vuoto ed emette un warning log su `stderr`.
    5.  Se non definito nel payload, tenta di estrarre il modello da utilizzare dai metadati dei messaggi.
    6.  Scrive il file JSON temporaneo e lo codifica in formato Base64 tramite `stage_b64` se presente.
*   **Output**: Assegna il percorso del file finale a `$BASH4LLM_TMP_PAYLOAD` e `$PAYLOAD`. Ritorna `0` in caso di successo, altrimenti `BASH4LLMERRTMP`.

#### call_api_groq
*   **Ruolo**: Esegue la chiamata HTTP sincrona non-streaming verso l'endpoint del provider.
*   **Logica**:
    1.  Verifica che la politica di rete sia favorevole via `enforce_network_policy`.
    2.  Verifica la presenza della chiave API nell'ambiente.
    3.  Se il file del payload è codificato Base64, lo decodifica in un file provvisorio.
    4.  Prepara l'array di argomenti per `curl` abilitando opzioni di buffering `stdbuf` (se disponibili nel sistema host) per controllare l'I/O.
    5.  Esegue la chiamata trasmettendo in modalità binaria il payload ed estrae lo stato HTTP restituito.
    6.  Se la risposta presenta caratteri non-JSON accodati in coda al blocco strutturato principale, isola e ripristina la sola porzione JSON valida.
    7.  Salva il pacchetto in `$RESP` con permessi `600`. In caso di errori fisici di connessione o del server, compila comunque `$RESP` scrivendo una struttura JSON diagnostica dell'errore.
*   **Output**: Ritorna codice `0` se eseguito, non-zero in caso di errori di curl o di I/O.

#### call_api_streaming_groq
*   **Ruolo**: Esegue la chiamata asincrona con supporto Server-Sent Events (SSE), estraendo in tempo reale i token e consolidando la risposta finale.
*   **Logica**:
    1.  Verifica e decodifica il payload se codificato in Base64.
    2.  Configura `curl` disabilitando il buffering (`-N`).
    3.  Avvia la pipeline di lettura riga per riga conforme allo standard SSE: isola le righe che iniziano con prefisso `data: `, scarta messaggi di controllo o vuoti, valida ed estrae i frammenti JSON dei chunk.
    4.  Invia istantaneamente i delta di testo su `stdout` per la reattività dell'utente.
    5.  In parallelo, accumula l'intero flusso grezzo ricevuto in file di staging.
    6.  Al termine della connessione, convalida ed assembla i frammenti JSON per ricostruire il corpo di risposta cumulativo, riversa il testo complessivo unificato e salva il pacchetto JSON completo in `$RESP` con permessi `600`.
    7.  Aggiorna in modo atomico il file di stato `last_api.json` con i metadati (request ID, stato HTTP, finish reason) tramite `ui_state_write`.
*   **Output**: Ritorna lo stato dell'esecuzione della pipeline di connessione.

#### refresh_models_groq
*   **Ruolo**: Interroga l'endpoint `/models` per normalizzare ed aggiornare la lista locale dei modelli supportati.
*   **Logica**:
    1.  Risolve l'URL base del provider e calcola l'endpoint `/openai/v1/models`.
    2.  Esegue la chiamata GET autenticata tramite chiave API.
    3.  Valida la risposta JSON ricevuta gestendo sia array nidificati in `.data` sia strutture piatte.
    4.  Rimuove spazi vuoti, normalizza i nomi dei modelli eliminando i prefissi ridondanti (`models/` o `groq/`) e li ordina univocamente filtrandoli in base a `$MAX_MODELS`.
    5.  Salva la lista in `$MODELS_FILE` in modo transazionale codificandola in Base64 atomico sotto lock esclusivo di 10 secondi per escludere letture concorrenti corrotte.
*   **Output**: Ritorna `0` se completato con successo, altrimenti non-zero.

#### validate_model_groq
*   **Ruolo**: Controlla se il modello richiesto rispetta le regole di compatibilità per il provider.
*   **Logica**: Normalizza il nome del modello rimuovendone i prefissi. Se `$MODELS_FILE` è popolato, controlla se il modello (in forma originale o normalizzata) è presente nel file. Se assente, emette un errore fatale. Infine, verifica se il modello è supportato dal runtime tramite `is_supported_model` (che esclude modelli che richiedono input non testuali come immagini o audio).
*   **Output**: Ritorna codice `0` se conforme, altrimenti `1` stampando l'errore su `stderr`.

#### auto_select_model_groq
*   **Ruolo**: Scorre sequenzialmente `$MODELS_FILE` e restituisce il primo modello compatibile che risulti supportato (escludendo modelli multimodali o non testuali).
*   **Output**: Stampa su standard output il nome del modello normalizzato e ritorna `0`. Ritorna `1` se il file è vuoto o nessun elemento è compatibile.

### 4.3 Blocchi Logici di PROVIDER

#### GROQ_API_KEY_override
*   **Azione**: Verifica se è impostata la variabile d'ambiente personalizzata `PROVIDER_API_ENV_groq`. In caso positivo, ne estrae il valore e sovrascrive la variabile globale `$GROQ_API_KEY` per allineare l'autenticazione delle richieste.

## SEZIONE 5: CORE_SETUP

Questa macro-sezione gestisce la configurazione iniziale dell'ambiente runtime globale, il parsing fine dei parametri passati da riga di comando (CLI), il whitelisting sintattico dei modelli LLM e il meccanismo di caricamento delle configurazioni utente persistenti.

### 5.1 Variabili di CORE_SETUP
*   **Variabili Lette/Scritte**:
    *   `JSON_INPUT`: Input strutturato fornito dall'utente.
    *   `TEMPLATE`: Nome identificativo del file modello per arricchire il prompt.
    *   `BATCH_FILE`: Percorso del file contenente l'elenco dei prompt.
    *   `CHAT_MODE`: Flag booleano (`0` o `1`) per abilitare l'interfaccia interattiva di chat.
    *   `SET_DEFAULT_MODEL`: Modello da impostare come scelta predefinita persistente.
    *   `LIST_MODELS`: Flag booleano per stampare l'elenco dei modelli.
    *   `LIST_PROVIDERS`: Flag booleano per visualizzare l'elenco dei provider installati.
    *   `LIST_PROVIDERS_RAW`: Flag booleano interno per stampare l'elenco dei provider in formato stringa crudo.
    *   `LIST_MODELS_RAW`: Flag booleano interno per stampare i modelli locali in formato stringa crudo.
    *   `FORCE_SAVE_MODE`: Regola l'archiviazione forzata dei risultati.
    *   `OUT_PATH`: Percorso di output personalizzato sul disco.
    *   `DRY_RUN`: Flag booleano di simulazione.
    *   `STREAM_MODE`: Flag booleano per attivare la ricezione streaming dei token.
    *   `QUIET`: Flag booleano per inibire i log informativi.
    *   `INSTALL_EXTRAS`: Flag booleano per attivare l'installazione delle estensioni.
    *   `DEBUG`: Flag di attivazione per il tracciamento dettagliato.
    *   `PROVIDER_CLI`: Nome del provider indicato esplicitamente da riga di comando.
    *   `PROVIDER_INTERACTIVE`: Flag booleano per richiedere la selezione grafica del provider.
    *   `SHOW_CONFIG`: Flag booleano per stampare la configurazione corrente del runtime.
    *   `DIAGNOSTICS`: Flag booleano per avviare il ciclo di diagnostica e autoverifica.
    *   `FILE_INPUTS`: Array vuoto adibito ad accumulare i percorsi dei file passati con l'opzione `-f`.
    *   `ARGS`: Array adibito ad accumulare gli argomenti posizionali non riconosciuti (prompt liberi).
    *   `OUTPUT_MODE`: Configura lo stile di visualizzazione dei risultati.
    *   `MODEL_CLI_SET`: Flag booleano interno che traccia se il modello è stato inserito via CLI.
    *   `INSTALL_EXTRAS_SRC`: Percorso della directory sorgente da cui prelevare le estensioni.
    *   `BOOTSTRAP_ONLY`: Flag booleano per arrestare lo script immediatamente dopo il bootstrap.
    *   `SE_ENGINE_PATH`: Percorso dello script del Session Engine esterno.
    *   `SE_AVAILABLE`: Flag booleano che attesta la disponibilità del modulo Session Engine.
    *   `_supported_providers_arr`: Array interno contenente l'elenco dei provider rilevati.

### 5.2 Funzioni di CORE_SETUP

#### call_provider
*   **Ruolo**: Consente il dispatching ed esecuzione dinamica di una specifica funzione esposta da un modulo provider esterno caricato in memoria.
*   **Input**: Nome della funzione come primo parametro, seguito dai relativi argomenti da inoltrare.
*   **Output**: Ritorna lo stato di uscita della funzione eseguita, o `127` se la funzione non risulta registrata.

#### refresh_models_dispatch
*   **Ruolo**: Coordina la procedura di aggiornamento dei modelli delegando l'operazione alla routine specifica del provider attivo.
*   **Input**: Percorso del file di destinazione opzionale (default `$MODELS_FILE`).
*   **Logica**: Tenta prioritariamente l'invocazione passando il percorso del file di destinazione. In caso di errore o di non corrispondenza della firma del metodo del modulo provider, esegue un fallback avviando la funzione senza parametri aggiuntivi.
*   **Output**: Ritorna codice `0` in caso di successo, `127` se l'interfaccia non è definita, o propaga il codice d'uscita del provider.

#### validate_model_dispatch
*   **Ruolo**: Richiama la funzione di convalida del modello specifica del provider attivo (`validate_model_<provider>`).
*   **Input**: Nome del modello da verificare.
*   **Logica**: Se il provider non implementa una validazione specializzata in memoria, emette un avvertimento log ed esegue un fallback avviando una validazione permissiva predefinita del core.
*   **Output**: Propaga lo stato d'uscita del validatore.

#### auto_select_model_dispatch
*   **Ruolo**: Tenta di ottenere un modello predefinito interrogando la funzione specifica del provider attivo (`auto_select_model_<provider>`).
*   **Output**: Ritorna codice `0` in caso di successo (stampando su standard output il nome del modello selezionato), altrimenti `1`.

#### resolve_model
*   **Ruolo**: Determina e valida il modello finale da adottare (`FINAL_MODEL`) seguendo un rigoroso ordine di precedenza.
*   **Logica**:
    1.  Se impostato da parametro CLI (`-m` / `--model`), lo adotta direttamente.
    2.  Identifica il provider attivo (analizzando parametri, leggendo `$PROVIDER_FILE` o adottando il fallback `"groq"`).
    3.  Tenta di leggere la prima riga del file di configurazione specifico per il provider (`model.<provider>`).
    4.  Richiama la funzione di auto-selezione del provider (`auto_select_model_dispatch`).
    5.  Scansiona riga per riga il file locale dei modelli (`models.txt`) alla ricerca del primo elemento valido e supportato.
    6.  Tenta di recuperare il modello inserito all'interno del file di configurazione globale (`config`).
    7.  Cerca all'interno dell'elenco di modelli autorizzati accumulati nella whitelist `$ALLOWED_MODELS`.
    8.  Se tutte le ricerche falliscono, restituisce un errore di selezione.
*   **Output**: Ritorna codice `0` se risolto (assegnando la scelta a `$FINAL_MODEL`), altrimenti `1`.

#### build_payload_from_vars
*   **Ruolo**: Dispaccia ed orchestra la costruzione del file JSON di richiesta chiamando dinamicamente la funzione `buildpayload_<provider>` del provider attivo.
*   **Output**: Ritorna codice `0` in caso di successo. Se il provider attivo non implementa la routine, termina lo script con codice d'errore applicativo.

#### call_api_once / call_api_streaming
*   **Ruolo**: Wrapper per avviare la chiamata sincrona o streaming delegandola alla funzione del provider attivo (`call_api_<provider>` o `call_api_streaming_<provider>`).
*   **Logica**: Se è attiva la simulazione dry-run, escludono la chiamata reale di rete ed invocano `show_payload_head` per visualizzare a scopo diagnostico l'intestazione del payload d'invio.
*   **Output**: Ritorna lo stato dell'esecuzione della chiamata o `0` se operato in simulazione.

#### extract_api_error
*   **Ruolo**: Ispeziona ed estrae il messaggio d'errore applicativo formale inviato dalle API all'interno del file di risposta `$RESP`.
*   **Logica**: Esegue una scansione sintattica cercando chiavi di errore standard nel JSON. Se il file non contiene JSON valido, estrae e restituisce la prima riga di testo non vuota rilevata nel file.
*   **Output**: Stampa l'errore su standard output.

#### detect_empty_edge_case
*   **Ruolo**: Rileva risposte API prive di contenuto testuale (stato HTTP 200, arresto regolare, ma assenza di token utili nella generazione).
*   **Logica**: Copia temporaneamente il file `$RESP` per ispezionarlo in sicurezza, estraendo metadati quali l'ID della richiesta, il `finish_reason` e il conteggio dei token generati (`completion_tokens`).
*   **Output**: Assegna il verdetto booleano a `$BASH4LLM_EDGE_EMPTY` (`1` se rilevato caso vuoto anomalo, `0` altrimenti) e compila le variabili diagnostiche `$BASH4LLM_EDGE_REQ_ID`, `$BASH4LLM_EDGE_FINISH_REASON` e `$BASH4LLM_EDGE_COMPLETION_TOKENS`.

#### finalize_and_output
*   **Ruolo**: Formatta e presenta i risultati a schermo e gestisce l'archiviazione dello storico sul disco.
*   **Logica**:
    *   Formatta il testo in base alla modalità impostata in `$OUTPUT_MODE` (testo crudo, formato JSON, o visualizzazioni strutturate pretty).
    *   Se l'output supera il limite di caratteri stabilito in `$THRESHOLD` o se il salvataggio è forzato dall'utente, invoca in modo atomico `save_to_history` per archiviare il file.
*   **Output**: Stampa i dati su stdout e ritorna codice `0` o il relativo codice d'errore.

#### perform_request_once
*   **Ruolo**: Gestisce il ciclo di esecuzione della chiamata API implementando tentativi di reinvio in caso di errori di connessione.
*   **Logica**:
    1.  Esegue la chiamata sincrona tramite `call_api_once`.
    2.  Se si verifica un fallimento temporaneo di rete (rilevando errori fisici di trasporto di curl), avvia un ciclo di tentativi (fino a `$MAX_RETRIES`) implementando un backoff lineare per l'attesa.
    3.  In caso di errore applicativo restituito dalle API, non effettua alcun tentativo di reinvio e gestisce l'eccezione tramite `extract_api_error`.
    4.  Analizza la risposta via `extract_text_from_resp` e verifica scenari vuoti tramite `detect_empty_edge_case`.
    5.  Registra l'ultima transazione in `last_api.json` tramite `ui_state_write` e formatta l'output via `finalize_and_output`.
*   **Output**: Ritorna codice `0` per transazioni completate con successo, altrimenti `BASH4LLMERRAPI`.

#### collect_input_from_files / expand_args_to_content / file_readable
*   **Ruolo**: Helper per l'acquisizione dei prompt da file o argomenti CLI.
*   **Logica**:
    *   `collect_input_from_files` legge e concatena la lista di file indicati dall'utente inserendovi delimitatori visivi per consentire al modello LLM di distinguere le diverse fonti.
    *   `expand_args_to_content` converte gli argomenti posizionali: se un argomento corrisponde ad un file esistente e leggibile (`file_readable` ritorna `0`), ne acquisisce il contenuto, altrimenti lo accoda direttamente come testo letterale.

#### trim / is_number / is_supported_model / list_models_cli / validate_model_core / load_local_config / load_whitelist / is_tty_out
*   **Ruolo**: Utility per la manipolazione di stringhe, validazione dei requisiti e caricamento delle whitelists.
*   **Logica**:
    *   `trim` rimuove gli spazi vuoti, tabulazioni e ritorni a capo da inizio e fine stringa tramite `awk`.
    *   `is_number` verifica se un valore rappresenta un numero valido (intero o decimale) tramite `awk`.
    *   `is_supported_model` scarta i modelli che richiedono formati non-testuali esclusivi (audio, video, immagini, whisper, vettori, tts).
    *   `list_models_cli` formatta ed evidenzia sulla console l'elenco dei modelli locali in `$MODELS_FILE`, escludendo o segnalando quelli non supportati.
    *   `validate_model_core` normalizza il nome del modello, controlla che sia registrato nel file dei modelli locali e che sia compatibile via `is_supported_model`.
    *   `load_local_config` analizza il file di configurazione locale (`config` sotto `$BASH4LLM_CONFIG_DIR`), interpretando le righe chiave/valore e impostando le variabili di ambiente corrispondenti (`MODEL`, `TEMPERATURE`, `MAX_TOKENS`, `OUTPUT_MODE`, `THRESHOLD`).
    *   `load_whitelist` normalizza e popola la stringa globale `$ALLOWED_MODELS` con i modelli autorizzati presenti sul disco.
    *   `is_tty_out` verifica se lo standard output è collegato ad un terminale interattivo reale (TTY).

### 5.3 Flussi e Blocchi Logici di CORE_SETUP

#### parse_cli_arguments
*   **Azione**: Analizza sequenzialmente le opzioni passate da CLI compilando i parametri operativi, i file di input `-f`, l'input JSON, i file batch, l'ID sessione, i formati di layout, i flag diagnostici e i parametri dei provider. Raggruppa i parametri posizionali o prompt liberi all'interno dell'array `$ARGS`. Gestisce la terminazione dello script in caso di opzioni di aiuto (`-h` / `--help`) o versione (`--version`).

#### source_session_engine
*   **Azione**: Rileva, analizza sintatticamente (`bash -n`) e tenta di importare lo script del Session Engine esterno (`session-engine.sh`). Se la verifica ha successo, imposta il flag `$SE_AVAILABLE=1`, abilitando la gestione avanzata delle chat multi-turno, altrimenti imposta il fallback sul motore di sessione integrato basato su file NDJSON.

#### verify_api_calls_and_rebuild_providers
*   **Azione**: Arresta l'esecuzione se la chiave API è configurata ma le chiamate esterne sono inibite senza essere in modalità di simulazione dry-run. Scansiona i moduli all'interno di `$PROVIDERS_DIR` per raccogliere dinamicamente tutti i provider installati, aggiornando la stringa globale `$SUPPORTED_PROVIDERS`.

#### raw_listings
*   **Azione**: Intercetta le richieste di visualizzazione cruda dei provider (`--list-providers-raw`) o dei modelli locali (`--list-models-raw`), stampa le informazioni riga per riga su standard output e termina il processo immediatamente con codice `0` (o non-zero in caso di elenchi assenti) senza procedere oltre.

#### immediate_actions
*   **Azione**: Elabora ed esegue i comandi che non richiedono chiamate alle API, terminando lo script con codice `0`:
    *   `--list-providers`: Visualizza l'elenco strutturato dei provider installati.
    *   `--list-models`: Visualizza l'elenco dei modelli supportati memorizzati in locale.
    *   `--set-default`: Imposta in modo persistente il modello predefinito scrivendolo nel file associato con permessi `600`.
    *   `--install-extras`: Installa le estensioni sul sistema. Convalida la sicurezza delle directory sorgente/destinazione per evitare link simbolici o percorsi non conformi. Verifica che l'utente corrente sia proprietario del file sorgente, copia i file preservandone la struttura ad albero, imposta i permessi di sicurezza (`700` per le directory e `600` per i file) e si avvale di `atomic_write` se disponibile. Conduce un'analisi sintattica formale sui moduli installati.
    *   Blocca l'avvio se la modalità streaming è accoppiata con output strutturato JSON.

#### normalize_boolean_flags
*   **Azione**: Scorre la lista delle variabili booleane dello script allineando i loro valori a stati interi `0` o `1` tramite l'utility `is_truthy`.

---

## SEZIONE 6: CORE_PROVIDER

Questa macro-sezione gestisce la convalida dei moduli provider caricati in memoria, l'assemblaggio dei prompt complessi, la gestione delle sessioni interattive di chat e l'allineamento dei modelli locali.

### 6.1 Variabili di CORE_PROVIDER
*   **Variabili Lette/Scritte**:
    *   `_supported_providers_arr`: Array interno contenente l'elenco dei provider supportati.
    *   `SUPPORTED_PROVIDERS`: Elenco dei provider registrati e separati da caratteri di spazio.

### 6.2 Funzioni di CORE_PROVIDER

#### validate_provider_interface
*   **Ruolo**: Convalida che il modulo del provider importato in memoria esponga l'interfaccia obbligatoria richiesta.
*   **Input**: Nome del provider da validare.
*   **Logica**: Verifica la presenza fisica in memoria delle due funzioni obbligatorie `buildpayload_<provider>` e `call_api_<provider>`. Se in modalità debug, segnala a scopo informativo la presenza o l'assenza di routine opzionali (streaming, validazione modelli, auto-selezione, refresh).
*   **Output**: Ritorna codice `0` se l'interfaccia obbligatoria è conforme, altrimenti `1` (emettendo errori critici loggati su `stderr`).

#### assemble_content
*   **Ruolo**: Compila ed organizza la stringa del prompt di input principale `$CONTENT` da trasmettere alle API, seguendo una gerarchia di regole di priorità esclusive:
    1.  Se è configurato un JSON utente in `$JSON_INPUT`, pulisce `$CONTENT` ed esce (in quanto il JSON definisce autonomamente la struttura dei messaggi).
    2.  Se sono presenti file via parametro `-f` (`$FILE_INPUTS`), ne unisce i contenuti tramite `collect_input_from_files` ed annette eventuali argomenti CLI in coda come frammenti testuali.
    3.  Se è richiesto l'uso di un template (`$TEMPLATE`), preleva il file modello dalla directory dei template, esegue la sostituzione deterministica del segnaposto `{{CONTENT}}` con l'input dell'utente utilizzando file temporanei di staging elaborati tramite `awk` e `mv`, ed assegna il testo risultante a `$CONTENT`.
    4.  Se è presente dell'input catturato da standard input (`$STDIN_CONTENT`), lo adotta come prompt principale, allegando in coda eventuali argomenti posizionali.
    5.  Se vi sono solo argomenti CLI posizionali in `$ARGS`, li converte ed unisce nel prompt principale richiamando `expand_args_to_content`.
*   **Output**: Stringa compilata assegnata a `$CONTENT`.

### 6.3 Flussi e Blocchi Logici di CORE_PROVIDER

#### CORE_PROVIDER_PRO_LOAD_INITIALIZATION
*   **Azione**: Gestisce l'allineamento e la selezione del provider attivo.
    *   Se non vengono fornite opzioni CLI o richieste interattive, tenta la lettura del provider registrato in `$PROVIDER_FILE` (con fallback su `"groq"`).
    *   In presenza di un'opzione CLI valida, controlla che sia incluso nell'elenco di quelli supportati, lo imposta come provider attivo, lo salva in `$PROVIDER_FILE` con permessi `600` e, in caso di variazione rispetto all'esecuzione precedente, cancella la vecchia cache dei modelli `$MODELS_FILE` e i file URL preesistenti.
    *   Se viene richiesta la selezione interattiva (`--provider` senza argomenti o valore `"list"`): costruisce un menu numerato evidenziando il provider correntemente predefinito, attende la scelta dell'utente da standard input (accettando l'indice numerico o il nome testuale del modulo), scrive la scelta nel file di configurazione, rimuove l'URL preesistente e cancella la vecchia cache dei modelli `$MODELS_FILE`.
    *   Se il provider attivo è `"groq"` e manca il file URL locale, scrive l'URL dell'API predefinito nel file canonico.
    *   Invoca la funzione di caricamento sicuro `load_provider_module` per importare i metodi del provider ed esegue `resolve_provider_url`.
    *   Se l'interfaccia interattiva viene eseguita senza comandi o parametri aggiuntivi, stampa la conferma del provider impostato ed esce direttamente con stato `0`.

#### CORE_PROVIDER_PRO_LOAD_VALIDATION_REFRESH
*   **Azione**: Verifica che il modulo del provider sia stato correttamente importato ed esegue la convalida dell'interfaccia chiamando `validate_provider_interface`. Se non va a buon fine, interrompe il runtime con codice `BASH4LLMERRAPI`.
    *   Se è richiesto il refresh dei modelli (`$REFRESH_MODELS=1`), verifica le credenziali tramite `ensure_api_key_for_provider` ed avvia l'allineamento locale chiamando `refresh_models_dispatch`, terminando con codice `0`.
    *   Se il file dei modelli locali `$MODELS_FILE` risulta assente o completamente vuoto all'avvio, ma le chiavi di accesso sono presenti nel sistema, avvia una procedura di aggiornamento automatico dei modelli in background (in modalità best-effort, tollerando eventuali errori di rete per non bloccare l'esecuzione dello script).

#### CORE_PROVIDER_SHOW
*   **Azione**: Gestisce le richieste diagnostiche ed esce con codice `0`:
    *   `PRINT_CONFIG_DIR` / `PRINT_PROVIDER_FILE` / `PRINT_MODEL_FILE`: Stampano i relativi percorsi ed escono.
    *   `SHOW_CONFIG`: Visualizza un riepilogo tabulare dei parametri del runtime (versione, date, provider attivo, modello attivo, percorsi delle directory operative, stato di debug e simulazione, whitelist).
    *   `DIAGNOSTICS`: Esegue un'analisi di integrità completa. Verifica l'esistenza e l'accessibilità di tutte le directory operative, attesta che le funzioni obbligatorie del provider siano mappate in memoria, convalida il modello attivo rispetto alla whitelist locale e controlla la presenza della chiave API correlandola con il nome esatto della variabile attesa dal provider.

#### CORE_PROVIDER_MAIN_RESOLVE
*   **Azione**: Se l'avvio è configurato per solo bootstrap (`$BOOTSTRAP_ONLY`), termina immediatamente l'esecuzione con codice `0`. Carica la configurazione locale e le whitelist dei modelli, garantisce la stabilità della directory temporanea `$RUN_TMPDIR`, risolve il modello LLM finale da adottare via `resolve_model` ed esegue le convalide sintattiche (terminando con codice `BASH4LLM_ERR_BAD_MODEL` se falliscono). Cattura e memorizza l'eventuale flusso di testo in arrivo da una redirezione o pipeline nello standard input (`cat -`) all'interno della variabile `$STDIN_CONTENT`.

#### CORE_PROVIDER_MAIN_EXECUTION
*   **Azione**: Invoca `assemble_content` per generare il prompt definitivo. Se lo script è richiamato in modalità interattiva e non contiene prompt, visualizza la notifica del provider attivo ed esce. Controlla la presenza di prompt testuali o JSON di input bloccando l'esecuzione con codice `BASH4LLMERRNO_PROMPT` in caso di assenza (tranne se in chat interattiva o elaborazione batch). Valida la correttezza dei parametri di temperatura e token massimi. Verifica che il modello sia supportato ispezionando la whitelist e garantisce la presenza di `$RUN_TMPDIR`. Procede quindi con i tre flussi di esecuzione principali:
    1.  **Elaborazione BATCH** (`$BATCH_FILE` attivo): Scansiona il file batch riga per riga, escludendo righe vuote o commenti. Per ciascun prompt: configura l'ambiente di sessione se richiesto (validando l'ID sessione, limitando la finestra dei messaggi, e richiamando `session_engine_build_window` o `session_read_window` per generare `$BUILD_MESSAGES_FILE`), compila il payload via `build_payload_from_vars`, verifica la presenza della chiave API per il provider ed esegue la chiamata sincrona o streaming.
    2.  **Chat Interattiva** (`$CHAT_MODE` attivo): Previene l'avvio se l'input non è collegato ad un terminale reale (TTY). Stampa l'intestazione di avvio e apre un ciclo continuo di lettura: acquisisce la riga inserita dall'utente, la pulisce e la accumula nella memoria storica. Se è configurata una sessione attiva, convalida l'ID, inizializza la cartella e compila `$BUILD_MESSAGES_FILE` tramite l'estensione del Session Engine o la routine legacy NDJSON. Compila il payload per il provider tramite `build_payload_from_vars`, controlla la chiave API e invoca la chiamata streaming o sincrona. Il ciclo si ripete fino alla cattura del segnale di fine trasmissione (Ctrl+D).
    3.  **Esecuzione Standard di Singolo Prompt**:
        *   Se è definita una sessione (`$SESSION_ID`), esegue la validazione dell'ID, determina la finestra di recupero, e compila il file storico dei messaggi `$BUILD_MESSAGES_FILE` interrogando il Session Engine o richiamando la routine legacy di lettura NDJSON.
        *   Compila il payload via `build_payload_from_vars`.
        *   Se si opera in esecuzione reale, convalida la presenza della chiave API del provider.
        *   Se lo streaming è attivo (`$STREAM_MODE == 1`): invoca `call_api_streaming`. In caso di completamento con successo: se vi è una sessione attiva, sanifica e registra il messaggio dell'utente e la risposta dell'assistente nel registro storico (via `session_engine_append` o `session_append`). Stampa un carattere di a capo e termina l'esecuzione con stato `0`.
        *   Se la chiamata è sincrona standard (`$STREAM_MODE == 0`): invoca `perform_request_once`. In caso di successo: se è configurata una sessione, sanifica e registra il messaggio dell'utente e la risposta dell'assistente nel file NDJSON di sessione. Esce con stato `0`. In caso di fallimento della chiamata, accoda comunque il messaggio utente alla sessione contrassegnandolo come interazione fallita ed interrompe l'esecuzione con codice `BASH4LLMERRAPI`.
