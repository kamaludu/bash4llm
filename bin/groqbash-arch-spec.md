# GroqBash - SPEC TECNICA STRUTTURALE
***Macro Sezioni***
- **[PRECORE_BOOT](#PRECORE_BOOT)**
- **[PRECORE_RUN](#PRECORE_RUN)**
- **[PROVIDER](#PROVIDER)**
- **[CORE_SETUP](#CORE_SETUP)**
- **[CORE_PROVIDER](#CORE_PROVIDER)**

---

### IDENTITÀ DELLA SEZIONE
- **Nome sezione**  
#  PRECORE_BOOT
- **Scopo**  
  Inizializzare l'ambiente di esecuzione di groqbash e fornire helper fondamentali per il bootstrap. Garantire che requisiti, percorsi e risorse locali siano validi e sicuri prima dell'esecuzione del core.
- **Responsabilità principali**  
  - Validare la presenza dei comandi obbligatori e terminare con errore se mancanti.  
  - Risolvere e normalizzare percorsi di script, config, tmp, extras e provider.  
  - Creare e proteggere directory e file di configurazione con permessi restrittivi.  
  - Fornire helper di basso livello per gestione temp, lock, base64, logging e validazione JSON.  
  - Caricare e validare moduli provider esterni in modo sicuro.  
- **Non-responsabilità**  
  - Non esegue chiamate API remote direttamente salvo tramite provider che devono rispettare enforce_network_policy.  
  - Non implementa la logica di buildpayload o call_api per provider specifici.  
  - Non gestisce l'intera CLI utente oltre a flag di stampa rapida e setup iniziale.  

---

### INVARIANTI E MODELLO MENTALE
- **Invarianti di stato prima e dopo**  
  - Prima: script può essere invocato da qualsiasi working directory.  
  - Dopo: GROQBASH_CONFIG_DIR, GROQBASH_TMPDIR e directory correlate esistono e hanno permessi 700 o file permessi 600 quando applicabile.  
  - Dopo: RUN_TMPDIR non esiste ancora fino a ensure_run_tmpdir, ma le funzioni per crearlo sono pronte.  
- **Assunzioni su ambiente file variabili**  
  - L'utente che esegue lo script possiede e controlla le directory sotto GROQBASH_DIR.  
  - Variabili d'ambiente fornite sono considerate attendibili.  
  - Nessun utente non fidato può scrivere nella directory contenente groqbash.  
  - I comandi esterni elencati sono disponibili nel PATH.  
- **Garanzie offerte al resto del sistema**  
  - Fornisce percorsi canonici e helper per leggere/scrivere in modo atomico e sicuro.  
  - Garantisce che i file di configurazione e provider non siano world-writable e che i provider caricati siano sintatticamente validi e non modificati durante il caricamento.  
  - Espone funzioni per validare JSON, gestire base64 e locking coerente con timeout configurabili.  

---

### DIPENDENZE
- **Dipendenze in ingresso**
  - Variabili d’ambiente lette  
    - GROQBASH_DIR, GROQBASH_ROOT, GROQBASH_CONFIG_DIR, GROQBASH_MODELS_DIR, GROQBASH_TEMPLATES_DIR, GROQBASH_HISTORY_DIR, GROQBASH_TMPDIR, GROQBASH_EXTRAS_DIR, PROVIDERS_DIR, GROQBASH_API_URL, GROQBASH_PROVIDER_URL, GROQBASH_DEBUG, DEBUG, DRY_RUN, GROQBASH_SKIP_NETWORK, GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET, QUIET, RUN_TMPDIR, DEBUG_PRESERVE, MAX_STAGE_BYTES, B64_WRAP_OPT, B64_DECODE_OPT, GROQBASH_LOG, GROQBASH_LOCK_TIMEOUT_TMP, GROQBASH_LOCK_TIMEOUT_MODELS, GROQBASH_LOCK_TIMEOUT_HISTORY
  - File letti  
    - canonical provider-url file, provider file sotto PROVIDERS_DIR, model files sotto GROQBASH_MODELS_DIR, provider capability ui_state file path, eventuali file temporanei esistenti in GROQBASH_TMPDIR
  - Funzioni esterne chiamate  
    - Funzioni definite in altre sezioni quando presenti come getfile_signature, _is_world_writable, _get_owner, _get_perm_string, make_tmpdir, _tmpf, getfile_signature e possibili provider-specific functions buildpayload_<prov>, call_api_<prov>, call_api_streaming_<prov>, refresh_models_<prov>
- **Dipendenze in uscita**
  - Variabili globali impostate o modificate  
    - SCRIPTDIR, GROQBASH_DIR, CANONICAL_EXTRAS_DIR, LEGACY_EXTRAS_DIR, GROQBASH_EXTRAS_DIR, PROVIDERS_DIR, GROQBASH_CONFIG_DIR, GROQBASH_MODELS_DIR, GROQBASH_TEMPLATES_DIR, GROQBASH_HISTORY_DIR, GROQBASH_TMPDIR, MODELS_FILE, MAX_MODELS, PROVIDER_FILE, PROVIDER_MODULE_PATH, PROVIDER_DIR, LOADED_PROVIDER_NAME, PROVIDER_MODULE_LOADED, B64_WRAP_OPT, B64_DECODE_OPT, MODELS_LOCK, HISTORY_LOCK, TMP_LOCK, RUN_TMPDIR, PAYLOAD, RESP, ERRF, DEBUG
  - File creati o scritti  
    - Directory canoniche sotto GROQBASH_DIR e GROQBASH_CONFIG_DIR, provider-url file se write_provider_url_if_missing viene invocata, ui_state provider_capabilities.json tramite ui_state_write, file di controllo temporanei creati da ensure_run_tmpdir e atomic helpers
  - Side-effect  
    - Scrittura su stdout per flag di stampa rapida, scrittura su stderr per log_info log_warn log_error, exit con codici di errore predefiniti in caso di condizioni critiche, possibili prompt interattivi per API key tramite ensure_api_key_for_provider, nessuna chiamata di rete diretta a meno che enforce_network_policy non lo blocchi e provider non lo esegua
  - Exit code  
    - Exit immediato con codice 1 se comandi obbligatori mancanti, exit con codici specifici definiti per errori canonici quando invocati

---

### API ESPOSTA
Per le funzioni rilevanti esposte come modulo.

- **resolve_script_dir**  
  - Ruolo: determinare la directory canonica dello script.  
  - Input: nessuno diretto.  
  - Output: stampa percorso su stdout.  
  - Errori: ritorna percorso relativo se non riesce a risolvere link simbolici.  

- **canonical_config_dir**  
  - Ruolo: restituire il percorso canonico di configurazione senza slash finale.  
  - Input: variabile GROQBASH_CONFIG_DIR.  
  - Output: stampa percorso su stdout.  
  - Errori: nessuno, può restituire stringa vuota se non impostata.

- **canonical_provider_file**  
  - Ruolo: restituire percorso file provider canonico.  
  - Input: GROQBASH_CONFIG_DIR.  
  - Output: stampa percorso su stdout.  
  - Errori: nessuno.

- **canonical_model_file**  
  - Ruolo: restituire percorso file modello per provider dato.  
  - Input: parametro provider.  
  - Output: stampa percorso su stdout.  
  - Errori: ritorno non-zero se input mancante.

- **canonical_provider_url_file**  
  - Ruolo: restituire percorso file provider-url canonico.  
  - Input: GROQBASH_CONFIG_DIR o GROQBASH_DIR.  
  - Output: stampa percorso su stdout.  
  - Errori: nessuno.

- **ensure_api_key_for_provider**  
  - Ruolo: assicurare che la API key per un provider sia presente e sincronizzare GROQ alias.  
  - Input: parametro provider, variabili d'ambiente potenzialmente nominate dinamicamente tramite provider_api_env_var_name, stato TTY.  
  - Output: exit code 0 su successo, esporta la variabile d'ambiente corrispondente e eventualmente GROQ_API_KEY.  
  - Errori: ritorna GROQBASHERRNOAPIKEY se mancante in non-interattivo o se input vuoto; stampa messaggi su stderr.

- **enforce_network_policy**  
  - Ruolo: decidere se le chiamate di rete sono permesse.  
  - Input: variabili DRY_RUN, GROQBASH_SKIP_NETWORK, GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET, QUIET, DEBUG.  
  - Output: exit code 0 se rete permessa, non-zero se bloccata; log informativi su stderr se DEBUG.  
  - Errori: nessuno oltre al valore di ritorno che indica policy.

- **ensure_config_dir**  
  - Ruolo: creare e verificare la directory di configurazione con permessi restrittivi.  
  - Input: GROQBASH_CONFIG_DIR.  
  - Output: exit code 0 su successo, crea directory e imposta permessi 700.  
  - Errori: ritorna non-zero e log_error se non può creare o scrivere nella directory.

- **write_provider_url_if_missing**  
  - Ruolo: scrivere in modo atomico provider-url non segreta se mancante.  
  - Input: provider e url.  
  - Output: crea file provider-url con permessi 600, exit code 0 su successo.  
  - Errori: ritorna non-zero se non può creare file o directory.

- **resolve_provider_url**  
  - Ruolo: risolvere URL provider con priorità ENV, file provider-url, fallback embedded per groq.  
  - Input: parametro provider, GROQBASH_API_URL, GROQBASH_PROVIDER_URL, provider-url file.  
  - Output: esporta GROQBASH_PROVIDER_URL e ritorna 0 su successo.  
  - Errori: ritorna 1 se non riesce a risolvere.

- **provider_api_env_var_name**  
  - Ruolo: calcolare nome canonico della variabile d'ambiente per API key di un provider.  
  - Input: provider.  
  - Output: stampa nome variabile su stdout.  
  - Errori: nessuno.

- **is_valid_json_string / is_valid_json_file / jq_safe**  
  - Ruolo: validare JSON in stringhe o file e fornire wrapper sicuro per jq.  
  - Input: stringa o file.  
  - Output: exit code 0 se valido, non-zero altrimenti; jq_safe scrive errori su ERRF se definito.  
  - Errori: ritorni non-zero e logging.

- **b64encode / b64decode / b64_atomic_write / b64_atomic_read / stage_b64**  
  - Ruolo: gestire codifica base64 portabile e staging atomico di payload.  
  - Input: stdin o file, opzioni B64_WRAP_OPT e B64_DECODE_OPT, MAX_STAGE_BYTES.  
  - Output: file .b64 creati in modo atomico, stdout per decode, exit code 0 su successo.  
  - Errori: ritorni non-zero e log_error su fallimenti di I/O o superamento dimensione.

- **lock_exec**  
  - Ruolo: acquisire lock esclusivo con timeout e eseguire comando sotto lock.  
  - Input: lockfile, timeout, comando.  
  - Output: esegue comando e ritorna il suo exit code, log di timeout su stderr.  
  - Errori: ritorna 2 se flock non disponibile o 124 su timeout.

- **_mktemp_in_dir / atomic_write**  
  - Ruolo: creare file temporanei sicuri e scrivere in modo atomico con lock.  
  - Input: directory di destinazione, timeout opzionale.  
  - Output: file creati con permessi restrittivi, exit code 0 su successo.  
  - Errori: ritorni non-zero e log_error su fallimenti.

- **extract_text_from_resp**  
  - Ruolo: estrarre contenuto testuale da file di risposta JSON in vari formati.  
  - Input: RESP variabile che punta a file.  
  - Output: stampa testo estratto su stdout, ritorni 0 successo, 2 se diagnostico, 1 se nessun testo.  
  - Errori: log_warn e fallback a output raw se JSON non valido.

- **ensure_run_tmpdir / cleanup_run_tmp_on_exit / cleanup_tmp**  
  - Ruolo: creare e gestire RUN_TMPDIR con permessi restrittivi e trap di pulizia.  
  - Input: GROQBASH_TMPDIR, DEBUG_PRESERVE, BASHPID, variabili di ambiente esistenti.  
  - Output: esporta RUN_TMPDIR PAYLOAD RESP ERRF, imposta trap per rimozione, ritorna 0 su successo.  
  - Errori: ritorni non-zero e log_error se non può creare tmpdir.

- **ui_state_write**  
  - Ruolo: scrivere file JSON di stato GUI in modo atomico sotto GROQBASH_CONFIG_DIR/ui_state.  
  - Input: nome file e stringa JSON.  
  - Output: crea file con permessi 600, ritorna 0 su successo.  
  - Errori: log_warn e ritorno non-zero su fallimenti.

- **load_provider_module**  
  - Ruolo: caricare e validare modulo provider da PROVIDERS_DIR in modo sicuro.  
  - Input: provider name, PROVIDERS_DIR, funzioni helper di sicurezza come _is_world_writable, _get_owner, _get_perm_string, getfile_signature.  
  - Output: imposta LOADED_PROVIDER_NAME, PROVIDER_MODULE_LOADED, carica il file se valido, scrive provider_capabilities.json tramite ui_state_write.  
  - Errori: ritorna 1 su problemi di sicurezza o I/O, imposta PROVIDER_MODULE_LOADED a 0 se modulo mancante o incompleto, log_error o log_warn a seconda del problema.

---

### FLUSSI PRINCIPALI
- **Bootstrap normale**  
  1. Verifica che lo script non sia stato importato in modalità source-only e ritorna se lo è.  
  2. Controlla la presenza dei comandi obbligatori e fallisce con exit se manca uno.  
  3. Risolve SCRIPTDIR e normalizza GROQBASH_DIR e percorsi canonici.  
  4. Crea directory essenziali con permessi restrittivi e verifica che non siano symlink.  
  5. Imposta variabili globali di percorso e opzioni base64, prepara lock names e valori di default.  
  6. Esegue ensure_config_dir per garantire scrivibilità e permessi.  
  7. Inizializza logging e helper, pronto per chiamare ensure_run_tmpdir o caricare provider.  
- **Flag di stampa rapida**  
  1. Scansione degli argomenti in ingresso.  
  2. Se trova flag --print-*, stampa il percorso canonico corrispondente su stdout.  
  3. Exit immediato con codice 0.  
- **Errore di configurazione**  
  1. Mancata creazione di una directory critica o permessi non corretti.  
  2. ensure_config_dir fallisce e log_error viene emesso.  
  3. Script esce con codice GROQBASHERRTMP o 1 a seconda del punto di fallimento.  
- **Caricamento provider**  
  1. load_provider_module verifica PROVIDERS_DIR e proprietà di sicurezza.  
  2. Controlla esistenza del file provider e che non sia symlink.  
  3. Valida proprietà file owner e permessi.  
  4. Esegue bash -n per validità sintattica e sourca il file se valido.  
  5. Verifica presenza delle funzioni richieste e scrive provider_capabilities.json; in caso di problemi fallback a provider embedded.  

---

### ERROR HANDLING E POLICY
- **Strategia generale**  
  - Fail-fast per condizioni critiche come comandi mancanti o config dir non scrivibile.  
  - Log strutturato su stderr per errori e avvisi.  
  - Codici di errore canonici definiti all'inizio della sezione per casi comuni.  
  - Operazioni non critiche tentano fallback sicuri e loggano warn invece di terminare l'intero processo.  
- **Punti di validazione importanti**  
  - Verifica presenza di comandi obbligatori prima di procedere.  
  - Controllo di symlink e permessi su directory e file sensibili.  
  - Validazione JSON tramite jq prima di trattare file come JSON.  
  - Confronto di firma file prima e dopo il sourcing del provider per rilevare modifiche in-flight.  
  - Dimensione massima per staging payload e rimozione di file .b64 vuoti.  
- **Policy particolari**  
  - Rete: enforce_network_policy centralizza il blocco delle chiamate HTTP quando DRY_RUN o GROQBASH_SKIP_NETWORK sono attivi.  
  - Sicurezza file: directory e file creati con permessi restrittivi 700 per directory e 600 per file.  
  - Nessun uso di /tmp di sistema per file temporanei principali; tutti i tmp sono sotto GROQBASH_TMPDIR.  
  - Nessuna esecuzione automatica delle risposte API e nessun uso di eval.  
  - Locking obbligatorio per operazioni atomiche tramite lock_exec con timeout configurabile.  

---

### IDENTITÀ DELLA SEZIONE
**Nome sezione**  
# PRECORE_RUN

**Scopo**  
Fornire primitive runtime sicure, atomiche e portabili per gestione history, manifest multimodale, tmp, sessioni e cache usate dall’intero script.

**Responsabilità principali**
- Rotazione e salvataggio atomico della history: `rotate_history`, `save_to_history`.  
- Creazione e aggiornamento manifest base64-compatibile: `manifest_create`, `manifest_add_part`, `manifest_read`.  
- Helper file/permessi/firma: `_get_perm_string`, `_get_owner`, `_get_file_signature`, `getfile_signature`, `_is_world_writable`.  
- Creazione sicura tmp: `make_tmpdir`, `_tmpf`.  
- Sessione MVP e cache: `session_validate_id`, `session_now_ts`, `session_messages_tmp_path`, `session_read_window`, `session_append`, `session_sanitize_cmd`, `session_marker_create` (marker logic integrata), `session_cache_key`, `session_cache_get`, `session_cache_set`, `session_cache_invalidate`.  
- Normalizzazione runtime e variabili booleane.

**Non-responsabilità**
- Non esegue output API come comandi; non usa eval.  
- Non effettua chiamate API di rete in questa sezione.  
- Non fornisce UI di alto livello né sandbox multi‑tenant.

---

### INVARIANTI E GARANZIE
**Invarianti prima/dopo**
- Operazioni critiche avvengono sotto lock; dopo ritorno i file target sono coerenti o l’operazione è stata annullata senza lasciare artefatti globali.
- File creati hanno permessi restrittivi (umask 077, chmod 600/700 quando possibile).
- Tmpfile/tmpdir sono creati nello stesso filesystem della destinazione per mv atomiche.

**Assunzioni ambiente**
- `GROQBASH_TMPDIR`, `RUN_TMPDIR`, `GROQBASH_HISTORY_DIR`, `GROQBASH_CONFIG_DIR`, `GROQBASH_DIR` e lock timeout (`GROQBASH_LOCK_TIMEOUT_*`) sono configurati e scrivibili dall’utente esecutore.
- Binari obbligatori nel PATH: `bash`, coreutils, `find`, `awk`, `curl`, `jq`; opzionali per funzionalità: `sha256sum` o `openssl`.
- L’utente controlla la directory dello script; nessun utente non fidato può scriverci.

**Garanzie offerte**
- Atomicità delle scritture su history, manifest e sessioni tramite lock e mv atomico.  
- Idempotenza append sessione per `message_id` tramite marker directory e controllo sotto lock.  
- Tmp e file con permessi restrittivi; nessun uso di `/tmp` di sistema come default.  
- Cache sessione con TTL e invalidazione deterministica.

---

### DIPENDENZE IMPORTANTI
**Variabili d’ambiente lette**
- History e rotazione: `GROQBASH_ROTATE_HISTORY`, `GROQBASH_HISTORY_MAX_FILES`, `GROQBASH_HISTORY_MAX_BYTES`, `GROQBASH_HISTORY_KEEP_DAYS`, `GROQBASH_HISTORY_DIR`, `GROQBASH_LOCK_TIMEOUT_HISTORY`.  
- Tmp e lock: `GROQBASH_TMPDIR`, `RUN_TMPDIR`, `TMP_LOCK`, `GROQBASH_LOCK_TIMEOUT_TMP`, `HISTORY_LOCK`.  
- Manifest: `B64_WRAP_OPT`, `B64_DECODE_OPT`, `GROQBASH_LOCK_TIMEOUT_MODELS`.  
- Runtime: `GROQBASH_CONFIG_DIR`, `GROQBASH_DIR`, `GROQBASH_SOURCE_ONLY`, `DEBUG`, `DRY_RUN`, `ALLOW_API_CALLS`, `GROQBASH_SIG_HASH`.  
- Session runtime defaults: `SESSION_DIR`, `LAST_CHECK_LINES`.

**File letti**
- History files sotto `${GROQBASH_HISTORY_DIR}`.  
- Session NDJSON `${history_dir}/sessions/${sid}.ndjson`.  
- Manifest `${manifest}` e `${manifest}.b64`.  
- UI state sotto `${GROQBASH_CONFIG_DIR%/}/ui_state`.

**Funzioni esterne richieste**
- `lock_exec`, `ui_state_write`, `ensure_run_tmpdir`, `ensure_config_dir`, `b64encode`, `b64decode`, `file_size`, `is_truthy`, `log_error`, `log_warn`, `log_info`.  
- Comandi esterni: `jq`, `mktemp`, `stat`, `find`, `grep`, `awk`, `sed`, `tail`, `sort`, `head`, `mv`, `cp`, `chmod`, `rm`, `mkdir`, `flock`, `date`, `sha256sum` o `openssl` (opzionali).

**Output e side‑effect principali**
- Variabili esportate: normalizzazione booleane `ALLOW_API_CALLS`, `DRY_RUN`, `DEBUG`.  
- File creati: history files, `last_history.json`, manifest e `.b64`, parti base64, tmpfile/tmpdir, session NDJSON e lockfile, marker dir, cache files in `session_cache`.  
- Log su stdout/stderr tramite `log_*`.  
- Exit code delle funzioni per segnalare successo/fallimento.

---

### API COMPATTA DEL MODULO
Per ogni funzione esposta, ruolo e contratti essenziali

- **rotate_history**  
  Ruolo: compattare history rispettando max files, max bytes, keep days sotto `HISTORY_LOCK`.  
  Contratto: ritorna 0 su successo; rimuove file eccedenti; può fallire con exit non-zero se lock o I/O critico fallisce.

- **save_to_history**  
  Ruolo: salvare contenuto in file history atomico e aggiornare `last_history.json`; opzionalmente chiamare `rotate_history`.  
  Contratto: ritorna 0 su successo; garantisce permessi 600; pulisce tmp su errore.

- **manifest_create / manifest_add_part / manifest_read**  
  Ruolo: creare manifest JSON + staging base64, aggiungere parti codificate e leggere manifest.  
  Contratto: operazioni atomiche sotto lock; `manifest_add_part` richiede file sorgente esistente; errori segnalati via exit code.

- **_get_perm_string / _get_owner / _get_file_signature / getfile_signature / _is_world_writable**  
  Ruolo: interrogazioni portabili su permessi, owner e firma file; controllo world-writable.  
  Contratto: restituiscono stringhe o exit code; non abortano il processo principale su stat fallito.

- **make_tmpdir / _tmpf**  
  Ruolo: creare tmpdir/tmpfile sicuri sotto `GROQBASH_TMPDIR` con permessi restrittivi e lock.  
  Contratto: stampano percorso su stdout; falliscono con `GROQBASHERRTMP` se base non disponibile.

- **session_validate_id / session_now_ts / session_messages_tmp_path / session_sanitize_cmd**  
  Ruolo: validazione id, timestamp UTC, path tmp per sessione, sanitizzazione comandi.  
  Contratto: semplici helper; `session_validate_id` ritorna 0/1.

- **session_read_window**  
  Ruolo: estrarre ultime N entry NDJSON di una sessione, normalizzare ruoli e scrivere `{"messages":[...]}` in out file in modo atomico.  
  Contratto: richiede `RUN_TMPDIR` scrivibile; aggiorna `ui_state` in best-effort; ritorna non-zero su errori I/O o parametri mancanti.

- **session_append**  
  Ruolo: append idempotente di record NDJSON in file sessione; previene duplicati tramite `message_id` marker e flock.  
  Contratto: garantisce idempotenza cross-processo per `message_id`; aggiorna `ui_state` e sessions index; ritorna non-zero su lock o I/O falliti; pulisce marker su fallimento.

- **session_cache_key / session_cache_get / session_cache_set / session_cache_invalidate**  
  Ruolo: generare chiave cache, leggere hit con TTL, scrivere cache atomica, invalidare.  
  Contratto: cache memorizzata in `${GROQBASH_CONFIG_DIR}/session_cache`; `session_cache_get` rimuove file scaduti; ritorna 0 su hit.

- **_tmpf**
  ignora qualsiasi directory esterna e forza sempre l’uso di `GROQBASH_TMPDIR`

---

### FLUSSI PRINCIPALI (sintesi)
- **Init runtime**  
  1. `ensure_run_tmpdir` viene chiamata; se fallisce exit con errore tmp.  
  2. Impostazione opzioni curl e default runtime.  
  3. `_normalize_bool_env` esporta booleani 0/1.

- **Salvataggio history**  
  1. `save_to_history` crea tmp in history dir.  
  2. Muove atomico in destinazione sotto `HISTORY_LOCK`.  
  3. Aggiorna `last_history.json` via `ui_state_write`.  
  4. Se abilitato, chiama `rotate_history`.

- **Append sessione idempotente**  
  1. Preparazione session dir e file.  
  2. Generazione `message_id` se assente.  
  3. Creazione marker dir; se esiste skip.  
  4. Acquisizione flock su `session_file`; controllo duplicato; append NDJSON; rilascio lock.  
  5. Lascia marker `done` e aggiorna `ui_state`.

- **Aggiunta parte manifest**  
  1. Codifica file sorgente in base64 e stage atomico.  
  2. Lock su `${manifest}.lock`, decodifica manifest.b64 o legge manifest.  
  3. Aggiorna JSON con jq e riscrive manifest + manifest.b64 atomicamente.

---

### ERROR HANDLING E POLICY ESSENZIALI
**Strategia**  
- Lock e mv atomici per evitare TOCTOU; best‑effort per metadata; pulizia tmp su fallimento; log strutturato per diagnostica.

**Validazioni critiche**
- `session_validate_id` prima di operare su sessioni.  
- Verifica scrivibilità di `RUN_TMPDIR`/`GROQBASH_TMPDIR` prima di creare tmp.  
- Esistenza file sorgente per `manifest_add_part`.  
- Normalizzazione `meta_json` con `jq` prima di append.

**Policy di sicurezza**
- Permessi restrittivi su tmp e file creati (umask 077, chmod 600/700).  
- Evitare `/tmp` di sistema come default; usare `GROQBASH_TMPDIR`/`RUN_TMPDIR`.  
- Nessuna esecuzione di contenuti esterni; sanitizzazione comandi per rimozione token e coppie env-like.  
- Timeout configurabili per lock (`GROQBASH_LOCK_TIMEOUT_*`) per prevenire deadlock.

---

### 1. IDENTITÀ DELLA SEZIONE
**Nome sezione**  
# PROVIDER 
(implementazione provider `groq`)

**Scopo**  
Fornire l’integrazione completa e autonoma con l’API compatibile OpenAI di Groq: costruzione payload, chiamate HTTP (streaming e non‑streaming), gestione e refresh della lista modelli, validazione e selezione automatica dei modelli.

**Responsabilità principali**
- Costruire payload JSON coerenti per le chat (`buildpayload_groq`).
- Eseguire chiamate HTTP non‑streaming verso l’endpoint provider con gestione diagnostica (`call_api_groq`).
- Eseguire chiamate HTTP in streaming (SSE) e aggregare chunk JSON in output finali (`call_api_streaming_groq`).
- Recuperare e normalizzare la lista dei modelli remoti e salvarla in modo atomico (`refresh_models_groq`).
- Validare che un modello richiesto sia presente e supportato (`validate_model_groq`).
- Selezionare automaticamente un modello valido dalla lista locale (`auto_select_model_groq`).
- Fornire alias compatibili (es. `buildpayloadgroq`, `refreshmodelsgroq`, `validatemodelgroq`, `autoselectmodelgroq`, `call_api_streaming_groq_legacy`).

**Non‑responsabilità (cosa NON fa)**
- Non gestisce UI, interazione utente o parsing CLI esterno alla sezione.
- Non implementa risoluzione globale dell’URL provider (si affida a `resolve_provider_url` esterno).
- Non esegue comandi shell provenienti dalle risposte API; non usa eval.
- Non fornisce fallback a pacchetti mancanti: assume che gli strumenti richiesti esistano.
- Non scrive file al di fuori della gerarchia temporanea controllata (`RUN_TMPDIR`) e dei file esplicitamente indicati (MODELS_FILE, RESP, ecc.).

---

### 2. INVARIANTI E MODELLO MENTALE
**Invarianti di stato prima/dopo**
- Prima di ogni funzione che tocca filesystem temporaneo: `ensure_run_tmpdir` deve avere creato e reso disponibile `RUN_TMPDIR`.
- Dopo `buildpayload_groq`: esiste un file payload valido (o una versione .b64) referenziato da `GROQBASH_TMP_PAYLOAD` o `PAYLOAD`.
- Dopo `call_api_groq` / `call_api_streaming_groq`: esiste un file di risposta finale in `RESP` (diagnostico se errore).
- Dopo `refresh_models_groq`: `MODELS_FILE` esiste e contiene una lista normalizzata non vuota (se la chiamata ha avuto successo).

**Assunzioni su ambiente / file / variabili**
- `RUN_TMPDIR`, `MODELS_FILE`, `MODELS_LOCK`, `MAX_MODELS`, `CURL_BASE_OPTS`, `DEBUG`, `DRY_RUN`, `GROQBASH_API_KEY`, `PROVIDER`, `GROQBASH_PROVIDER_URL` possono essere presenti e influenzano il comportamento.
- `GROQ_API_KEY` può essere fornita direttamente o tramite `PROVIDER_API_ENV_groq` che punta a un env var contenente la chiave.
- Strumenti esterni obbligatori: bash, coreutils, findutils, util-linux, gawk, curl, jq; helper locali come `b64decode`, `b64_atomic_write`, `stage_b64`, `lock_exec`, `is_truthy`, `is_valid_json_string`, `is_valid_json_file`, `is_supported_model`, `ensure_run_tmpdir`, `_mktemp_in_dir`, `resolve_provider_url`, `ui_state_write`, `log_*` devono esistere altrove nello script.
- L’utente controlla la directory contenente lo script; non ci sono utenti non fidati che possono modificare i file usati.

**Garanzie offerte al resto del sistema**
- Produce payload JSON validi o fallisce con diagnostica chiara.
- Non lascia payload temporanei non rimossi (cleanup gestito).
- Fornisce file di risposta `RESP` sempre: risposta reale o JSON diagnostico con motivo dell’errore.
- Quando possibile, scrive `MODELS_FILE` in modo atomico e sotto lock per evitare corruzione concorrente.
- Non espone chiavi API nei log a meno che `DEBUG=1` non richieda diagnostica (ma codice evita di stampare chiavi).

---

### 3. DIPENDENZE
**Dipendenze in ingresso**

- *Variabili d’ambiente lette*
  - `GROQ_API_KEY`, `PROVIDER_API_ENV_groq`, `GROQBASH_API_KEY`, `GROQBASH_PROVIDER_URL`, `PROVIDER`, `MODELS_FILE`, `MODELS_LOCK`, `MAX_MODELS`, `CURL_BASE_OPTS`, `DEBUG`, `DRY_RUN`, `PAYLOAD`, `GROQBASH_TMP_PAYLOAD`, `RESP`, `RUN_TMPDIR`, `TURE`, `MAX_TOKENS`, `MESSAGES_JSON`, `BUILD_MESSAGES_FILE`, `JSON_INPUT`, `CONTENT`, `STREAM_MODE`, `MODELS_FILE`, `MODELS_LOCK`, `GROQBASH_EDGE_EMPTY`, `CURL_BASE_OPTS`, `B64_DECODE_OPT`.

- *File letti*
  - `BUILD_MESSAGES_FILE` (se specificato), eventuali payload `.b64` staged, `MODELS_FILE` per validazione/auto‑selezione, file temporanei in `RUN_TMPDIR`.

- *Funzioni esterne chiamate (altre macro‑sezioni / helper)*
  - `ensure_run_tmpdir`, `_mktemp_in_dir`, `is_truthy`, `is_valid_json_string`, `is_valid_json_file`, `b64decode`, `stage_b64`, `b64_atomic_write`, `lock_exec`, `resolve_provider_url`, `is_supported_model`, `ui_state_write`, `log_info`, `log_warn`, `log_error`, `show_payload_head`.

**Dipendenze in uscita**

- *Variabili globali impostate o modificate*
  - `GROQBASH_TMP_PAYLOAD` (setta percorso payload), `PAYLOAD` (se non già impostata), `RESP` (se non già impostata viene popolata), `MODELS_FILE` (aggiornato da `refresh_models_groq`), `ui_state` tramite `ui_state_write` (last_api.json).

- *File creati/scritti*
  - Payload temporanei (`payload.json`, `.b64`, decoded payload), `resp.json`, `resp.raw`, `resp.lines`, `resp.valid.jsons`, `resp.chunks.json`, `resp.text.txt`, `MODELS_FILE` (atomico), lock files temporanei, vari file diagnostici in `RUN_TMPDIR`.

- *Side‑effects*
  - Rete: richieste HTTP verso `GROQBASH_PROVIDER_URL` o derivati (`/openai/v1/chat/completions`, `/openai/v1/models`).
  - Stdout: emissione incrementale del contenuto durante streaming (per `call_api_streaming_groq`).
  - Stderr: logging diagnostico tramite `log_*` e scrittura di file di errore curl.
  - Exit code / return value: ogni funzione ritorna codici specifici (0 successo, codici di errore predefiniti per problemi di tmp, API key, curl, ecc.).

---

### 4. API ESPOSTA (vista come modulo)
Per ogni funzione rilevante: ruolo, input, output, errori.

**buildpayload_groq**  
- **Ruolo**: costruisce il payload JSON per la chiamata chat e produce un file payload (raw o .b64) referenziato da `GROQBASH_TMP_PAYLOAD`/`PAYLOAD`.  
- **Input**: variabili globali: `MODEL`, `TURE`, `MAX_TOKENS`, `MESSAGES_JSON`, `BUILD_MESSAGES_FILE`, `STREAM_MODE`, `JSON_INPUT`, `CONTENT`; helper esterni e `RUN_TMPDIR`.  
- **Output / side‑effect**: crea file payload in `RUN_TMPDIR` o file .b64; imposta `GROQBASH_TMP_PAYLOAD` e `PAYLOAD` se non già impostata; ritorna 0 su successo.  
- **Errori / fallimenti**: fallisce con codice di errore temporaneo se `ensure_run_tmpdir` fallisce, se `jq` non riesce a costruire il payload, o se payload risultante è vuoto; scrive messaggi diagnostici via `log_error`/`log_warn`.

**call_api_groq**  
- **Ruolo**: esegue chiamata HTTP non‑streaming verso provider, salva risposta in `RESP` e fornisce diagnostica.  
- **Input**: `GROQBASH_TMP_PAYLOAD` o `PAYLOAD`, `GROQ_API_KEY`/`GROQBASH_API_KEY`/`PROVIDER_API_ENV_groq`, `GROQBASH_PROVIDER_URL` (o `resolve_provider_url`), `RUN_TMPDIR`, `CURL_BASE_OPTS`, `DRY_RUN`, `DEBUG`.  
- **Output / side‑effect**: scrive file di risposta `RESP` (o diagnostico), scrive file di errore curl, ritorna il codice di ritorno del processo curl (0 se trasporto OK).  
- **Errori / fallimenti**: segnala e ritorna codici specifici per: mancanza payload, payload vuoto, mancanza API key, mancanza provider URL, fallimento decodifica .b64, fallimento curl (rc non zero). In ogni caso produce un `RESP` diagnostico quando possibile.

**call_api_streaming_groq**  
- **Ruolo**: esegue chiamata streaming SSE, emette contenuto incrementale su stdout, aggrega chunk JSON e scrive `RESP` finale.  
- **Input**: come `call_api_groq` più `STREAM_MODE` implicito; `GROQBASH_TMP_PAYLOAD`/`PAYLOAD`, `GROQ_API_KEY`, `GROQBASH_PROVIDER_URL`, `RUN_TMPDIR`, `DEBUG`, `DRY_RUN`.  
- **Output / side‑effect**: streaming su stdout del contenuto estratto dai chunk; file temporanei `resp.raw`, `resp.lines`, `resp.valid.jsons`, `resp.chunks.json`, `resp.text.txt`; scrive `RESP` finale o diagnostico; ritorna rc di curl (pipeline).  
- **Errori / fallimenti**: segnala mancanza payload, payload vuoto, mancanza API key, mancanza provider URL; se stream non contiene JSON validi scrive `RESP` diagnostico; ritorna codice di curl o codice di errore specifico.

**refresh_models_groq**  
- **Ruolo**: recupera `/openai/v1/models`, normalizza e salva la lista in `MODELS_FILE` in modo atomico e sotto lock.  
- **Input**: `GROQ_API_KEY` (o `PROVIDER_API_ENV_groq`), `GROQBASH_PROVIDER_URL` (o `resolve_provider_url`), `MAX_MODELS`, `MODELS_FILE`, `MODELS_LOCK`, `CURL_BASE_OPTS`, `RUN_TMPDIR`.  
- **Output / side‑effect**: scrive `MODELS_FILE` (atomico via `.b64` e `lock_exec`), ritorna 0 su successo.  
- **Errori / fallimenti**: fallisce se mancano API key, provider URL, se curl fallisce, se JSON non valido, se parsing produce lista vuota, o se scrittura atomica fallisce; ritorna codici di errore distinti e log di diagnostica.

**validate_model_groq**  
- **Ruolo**: verifica che un modello richiesto sia presente nella `MODELS_FILE` (se esiste) e che sia supportato testualmente.  
- **Input**: parametro `model` (arg1), `MODELS_FILE`, helper `is_supported_model`.  
- **Output / side‑effect**: ritorna 0 se valido; scrive messaggi di errore su stderr in caso di invalidità.  
- **Errori / fallimenti**: fallisce con codice 1 e messaggio su stderr se `model` mancante, non presente in `MODELS_FILE` (quando file esiste e non vuoto), o non supportato da `is_supported_model`.

**auto_select_model_groq**  
- **Ruolo**: scorre `MODELS_FILE` e stampa il primo modello normalizzato che `is_supported_model` accetta.  
- **Input**: `MODELS_FILE`, `MAX_MODELS`, helper `is_supported_model`.  
- **Output / side‑effect**: stampa il modello selezionato su stdout e ritorna 0; ritorna 1 se nessun modello valido trovato.  
- **Errori / fallimenti**: ritorna 1 se file mancante o nessun candidato valido.

---

### 5. FLUSSI PRINCIPALI
**Flusso A — Costruzione payload e chiamata non‑streaming (normale)**
1. `ensure_run_tmpdir` crea `RUN_TMPDIR`.
2. `buildpayload_groq` valida input (JSON_INPUT, MESSAGES_JSON, BUILD_MESSAGES_FILE, CONTENT) e costruisce payload JSON; produce `GROQBASH_TMP_PAYLOAD` o `PAYLOAD`.
3. Verifica `enforce_network_policy` (chiamata esterna) e `DRY_RUN`/`DEBUG`.
4. `call_api_groq` verifica presenza API key e `GROQBASH_PROVIDER_URL` (o chiama `resolve_provider_url`).
5. Decodifica payload .b64 se necessario, esegue `curl` con opzioni e salva output in `resp_tmp`.
6. Normalizza e valida JSON di risposta; scrive `RESP` o JSON diagnostico; ritorna rc di curl.

**Flusso B — Streaming SSE**
1. `ensure_run_tmpdir`.
2. `buildpayload_groq` prepara payload con `stream:true`.
3. `call_api_streaming_groq` verifica network policy e API key.
4. Decodifica payload .b64 se necessario; lancia `curl` in modalità streaming e pipe verso loop di parsing.
5. Per ogni linea `data: ...` estrae JSON e stampa contenuto incrementale su stdout.
6. Alla fine aggrega chunk validi in `resp.chunks.json` e `resp.text.txt`, scrive `RESP` finale o diagnostico; ritorna rc.

**Flusso C — Refresh lista modelli**
1. Verifica `GROQ_API_KEY` (o `PROVIDER_API_ENV_groq`).
2. `ensure_run_tmpdir` e crea temp dir.
3. Determina `api_url` derivando l’origine da `GROQBASH_PROVIDER_URL` o fallisce.
4. Esegue `curl` per `/openai/v1/models` e salva output.
5. Valida JSON con `jq`; estrae nomi candidati e normalizza (rimuove prefissi).
6. Scrive lista normalizzata in modo atomico via `b64_atomic_write` e `lock_exec` su `MODELS_FILE`.

**Flusso D — Validazione / Auto‑selezione modello**
1. `validate_model_groq` normalizza input e, se `MODELS_FILE` esiste e non vuoto, verifica presenza (raw o normalizzata).
2. Chiama `is_supported_model` per garantire compatibilità testuale.
3. `auto_select_model_groq` scorre `MODELS_FILE`, normalizza ogni riga e restituisce il primo modello supportato.

---

### 6. ERROR HANDLING E POLICY
**Strategia generale**
- Fallimenti sono segnalati con codici di ritorno specifici e messaggi log tramite `log_error`/`log_warn`/`log_info`.
- Quando possibile, la sezione produce un file `RESP` diagnostico contenente motivo, timestamp e frammento di stderr per consentire al caller di distinguere errori di trasporto da errori applicativi.
- Operazioni su file sensibili sono eseguite con permessi restrittivi (chmod 600) quando possibile.

**Punti di validazione importanti**
- Validità JSON di input (`is_valid_json_string`, `is_valid_json_file`) prima di usarlo come `.messages`.
- Validità numerica di `TURE` e `MAX_TOKENS` prima di passare a `jq`.
- Presenza e non‑vuotezza del payload prima di chiamare `curl`.
- Presenza di `GROQ_API_KEY` o `GROQBASH_API_KEY` prima di chiamate di rete.
- Validità JSON della risposta prima di considerarla definitiva; estrazione conservativa di prefissi JSON se la risposta contiene dati extra.
- Normalizzazione e validazione della lista modelli prima di scriverla.

**Policy particolari**
- **Rete**: tutte le chiamate sono soggette a `enforce_network_policy`; in `DRY_RUN` le chiamate reali sono evitate e possono essere simulate per diagnostica.
- **Sicurezza**: non usare `/tmp` di sistema per file temporanei; usare `RUN_TMPDIR` controllato; permessi file impostati restrittivi; non stampare chiavi API nei log (diagnostica evita esposizione).
- **Atomicità**: scrittura di `MODELS_FILE` tramite staging base64 e lock per evitare corruzione; movimenti di file preferiti via `mv` con fallback a `cp`.
- **Streaming**: parsing conservativo dei chunk SSE; emissione incrementale su stdout senza eseguire contenuto; aggregazione dei chunk validi in file finali.
- **Diagnostica**: in caso di output non JSON, estrazione di un prefisso JSON valido e salvataggio del resto in file di trailing diagnostici; `RESP` contiene sempre informazioni utili per il caller.

---

### 1. IDENTITÀ DELLA SEZIONE
- **Nome sezione:**
# CORE_SETUP  
- **Scopo:** inizializzare e normalizzare lo stato CLI e di runtime necessario al core; validare e risolvere il modello attivo; orchestrare chiamate API (wrapper) e gestione output/ritentativi; fornire helper di input e parsing CLI.  
- **Responsabilità principali**
  - Dispatch verso implementazioni provider-specifiche (invocazione dinamica di funzioni provider).  
  - Risoluzione del modello finale secondo priorità (CLI, persistito per provider, auto‑select, file MODELS_FILE, legacy config, ALLOWED_MODELS).  
  - Costruzione del payload delegata al provider e invocazione delle chiamate API (streaming e non‑streaming) con modalità DRY_RUN.  
  - Gestione della risposta: estrazione testo, rilevamento edge case (empty completion), salvataggio output lungo, scrittura stato UI fallback.  
  - Parsing e normalizzazione delle opzioni CLI, azioni immediate (--list, --set-default, --install-extras), caricamento config locale e whitelist.  
  - Helpers di input (lettura file, espansione argomenti), validazione modelli test‑only.  
- **Non‑responsabilità (cosa NON fa)**
  - Non implementa logica provider‑specifica (solo dispatch).  
  - Non esegue richieste HTTP direttamente (usa provider modules per call_api_*).  
  - Non esegue comandi shell provenienti da risposte API; non effettua eval.  
  - Non gestisce persistenti di lunga durata oltre i file di configurazione canonici; non effettua sandboxing di sistema.



---

### 2. INVARIANTI E MODELLO MENTALE
- **Invarianti di stato prima/dopo**
  - Prima dell’esecuzione: variabili globali di configurazione possono essere vuote; MODELS_FILE e GROQBASH_CONFIG_DIR possono esistere o meno.  
  - Dopo le funzioni di setup: variabili booleane normalizzate (DRY_RUN, STREAM_MODE, ecc.) sono 0/1; SUPPORTED_PROVIDERS è popolato; FINAL_MODEL è impostato o vuoto; SE_AVAILABLE riflette disponibilità engine sessione.  
  - Le funzioni non lasciano file temporanei in /tmp di sistema; ogni scrittura persistente avviene sotto canonical config/extras/history.  
- **Assunzioni su ambiente / file / variabili**
  - L’ambiente è trusted: l’utente controlla le directory dove risiede GroqBash; nessun utente non fidato può scrivere nella directory dello script.  
  - Esistenza di strumenti esterni obbligatori nel PATH (bash, curl, jq, awk, coreutils, ecc.) — mancati strumenti causano fallimenti espliciti altrove.  
  - Variabili d’ambiente come GROQ_API_KEY sono configurazione fidata; ALLOW_API_CALLS può bloccare chiamate reali.  
  - Canonical config dir e file (canonical_config_dir, canonical_provider_file, canonical_model_file, MODELS_FILE) sono punti di verità per persistenti.  
- **Garanzie offerte al resto del sistema**
  - Fornisce un modello coerente di quale *provider* e *model* usare (FINAL_MODEL) o fallisce in modo deterministico.  
  - Normalizza flag CLI in valori booleani 0/1 e costruisce SUPPORTED_PROVIDERS.  
  - Espone wrapper sicuri per chiamate API che rispettano DRY_RUN e delegano al provider; segnala errori provider‑missing con codici di errore standard.  
  - Garantisce che output lunghi vengano salvati tramite meccanismi atomici (save_to_history) e che lo stato UI abbia un fallback last_api.json.



---

### 3. DIPENDENZE
- **Dipendenze in ingresso**
  - *Variabili d’ambiente lette:* MODEL, MODEL_CLI_SET, PROVIDER, PROVIDER_CLI, GROQ_API_KEY, ALLOW_API_CALLS, DEBUG, DRY_RUN, STREAM_MODE, OUTPUT_MODE, GROQBASH_CONFIG_DIR, GROQBASH_EXTRAS_DIR, PROVIDERS_DIR, MODELS_FILE, GROQBASH_HISTORY_DIR, RUN_TMPDIR, MAX_MODELS, THRESHOLD, INSTALL_EXTRAS_SRC, LEGACY_EXTRAS_DIR, SESSION_ID, SESSION_WINDOW, FORCE_SAVE_MODE, OUT_PATH, ALLOWED_MODELS, SCRIPTDIR, SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_DATE, GROQBASHERR* (error codes).  
  - *File letti:* MODELS_FILE, canonical provider/model files (canonical_provider_file, canonical_model_file), ${GROQBASH_CONFIG_DIR}/config, extras files under extras/providers, help file under extras/docs/help.txt, session engine module file.  
  - *Funzioni esterne chiamate (altre macro‑sezioni / provider):* call_provider (invoca funzioni provider come refresh_models_<prov>, validate_model_<prov>, auto_select_model_<prov>, buildpayload_<prov>, call_api_<prov>, call_api_streaming_<prov>), ensure_run_tmpdir, is_truthy, canonical_config_dir, canonical_provider_file, canonical_model_file, is_valid_json_file, extract_text_from_resp, ui_state_write, save_to_history, atomic_write, _get_owner, session_engine_* (se caricati), log_error/log_warn/log_info, show_payload_head.  
- **Dipendenze in uscita**
  - *Variabili globali impostate/modificate:* FINAL_MODEL, MODEL_PROVIDER_CFG, SUPPORTED_PROVIDERS, SE_AVAILABLE, ALLOWED_MODELS, various normalized flags (DRY_RUN, STREAM_MODE, ...), GROQBASH_EDGE_* diagnostics, RESP (assunto scritto da provider), PAYLOAD (usata per DRY_RUN diagnostics), ui_last fallback content.  
  - *File creati/scritti:* target_model_file (quando --set-default), files under DEST_BASE when --install-extras, ui_state last_api.json fallback, files under GROQBASH_HISTORY_DIR via save_to_history.  
  - *Side‑effects:* rete (delegata ai provider), stdout/stderr (help text, info/warn/error messages, model lists), exit codes (script may exit early for actions like --list, --set-default, --install-extras, invalid args), atomic writes via atomic_write, chmod operations.

---

### 4. API ESPOSTA (vista come modulo)
> Sono elencate le funzioni rilevanti esposte dalla sezione; micro‑helper locali non elencati.

- **call_provider**
  - **Ruolo:** invocare dinamicamente una funzione per nome se definita (dispatch generico).  
  - **Input:** primo argomento = nome funzione; argomenti successivi passati in avanti. ENV non rilevanti.  
  - **Output:** exit code della funzione invocata; 127 se la funzione non esiste.  
  - **Errori:** ritorna 127 quando la funzione non è definita.

- **refresh_models_dispatch**
  - **Ruolo:** orchestrare il refresh della lista modelli delegando a refresh_models_<PROVIDER>.  
  - **Input:** opzionale destfile (default MODELS_FILE o groqbash.d/models.txt); legge PROVIDER, DEBUG.  
  - **Output:** 0 se refresh ok; 127 se provider non implementa la funzione; altrimenti ritorna rc del provider.  
  - **Errori:** log_error e ritorno 127 se funzione provider mancante; log_error con rc se fallisce.

- **validate_model_dispatch**
  - **Ruolo:** chiamare validate_model_<PROVIDER> se presente; fallback permissivo.  
  - **Input:** model name.  
  - **Output:** exit code della validazione provider o 0 se non implementata.  
  - **Errori:** propagazione del codice di errore del provider.

- **auto_select_model_dispatch**
  - **Ruolo:** tentare di ottenere un modello suggerito dal provider (auto_select_model_<PROVIDER>).  
  - **Input:** nessuno diretto; usa PROVIDER.  
  - **Output:** ritorna 0 se call_provider ha successo (stdout può contenere candidate); 1 altrimenti.  
  - **Errori:** fallimento silenzioso (ritorno 1).

- **resolve_model**
  - **Ruolo:** determinare e validare FINAL_MODEL seguendo priorità multiple.  
  - **Input:** variabili globali (MODEL, MODEL_CLI_SET, PROVIDER_CLI, PROVIDER, MODELS_FILE, ALLOWED_MODELS, GROQBASH_CONFIG_DIR, MAX_MODELS).  
  - **Output:** imposta FINAL_MODEL (stringa) e ritorna 0 se risolto; imposta FINAL_MODEL="" e ritorna 1 se non risolto.  
  - **Errori:** non esce direttamente; log_warn/log_error per condizioni di sicurezza (es. canonical_config_dir invalida). Fallimenti di validate_model_core/dispatch impediscono la selezione.

- **build_payload_from_vars**
  - **Ruolo:** assicurare tmp runtime e delegare la costruzione del payload al provider (buildpayload_<PROVIDER>).  
  - **Input:** variabili globali di contesto (PROVIDER, PAYLOAD, RUN_TMPDIR).  
  - **Output:** 0 se provider costruisce payload; se provider mancante log_error e exit con GROQBASHERRAPI; altrimenti ritorna rc provider.  
  - **Errori:** exit immediato con codice GROQBASHERRAPI se provider non implementa la funzione.

- **call_api_once / call_api_streaming**
  - **Ruolo:** wrapper per invocare la chiamata API provider-specifica, rispettando DRY_RUN.  
  - **Input:** PAYLOAD, PROVIDER, DRY_RUN, DEBUG.  
  - **Output:** 0 su successo; se provider mancante exit con GROQBASHERRAPI; altrimenti ritorna rc provider.  
  - **Errori:** gestione DRY_RUN (nessuna chiamata reale), log_error e exit su provider non implementato.

- **extract_api_error**
  - **Ruolo:** estrarre messaggio di errore leggibile dal file RESP.  
  - **Input:** RESP file path.  
  - **Output:** stampa su stdout la prima stringa di errore trovata; exit 0.  
  - **Errori:** se RESP non JSON restituisce la prima riga non vuota; nessun errore critico.

- **detect_empty_edge_case**
  - **Ruolo:** rilevare completions "vuote" e popolare variabili diagnostiche GROQBASH_EDGE_*.  
  - **Input:** RESP file path.  
  - **Output:** imposta GROQBASH_EDGE_EMPTY e variabili correlate; ritorna 0.  
  - **Errori:** nessuno; comportamento conservativo (considera non‑JSON come edge empty).

- **finalize_and_output**
  - **Ruolo:** emettere output in modalità richiesta (json/pretty/text/raw) e salvare output lunghi tramite save_to_history.  
  - **Input:** mode, text; legge RESP, FORCE_SAVE_MODE, THRESHOLD, OUT_PATH, GROQBASH_HISTORY_DIR, RUN_TMPDIR.  
  - **Output:** stampa su stdout; ritorna 0 o GROQBASHERRTMP su errori di tmp/salvataggio.  
  - **Errori:** segnala e ritorna GROQBASHERRTMP se RESP mancante per json/pretty o se RUN_TMPDIR non disponibile per salvataggio.

- **perform_request_once**
  - **Ruolo:** ciclo di tentativi per eseguire la richiesta API con retry e gestione degli errori/edge cases.  
  - **Input:** MAX_RETRIES, DRY_RUN, DEBUG, OUTPUT_MODE, RESP, PAYLOAD.  
  - **Output:** 0 su successo; GROQBASHERRAPI su fallimenti; stampa diagnostica su stderr.  
  - **Errori:** distingue errori di rete (GROQBASHERRCURL_FAILED) da errori API (GROQBASHERRAPI) e non‑retry per errori API.

- **list_models_cli / validate_model_core / is_supported_model / load_local_config / load_whitelist / is_tty_out**
  - **Ruolo:** utilities pubbliche per listing, validazione e caricamento config.  
  - **Input/Output/Errori:** comportamenti documentati nel codice; errori segnalati via stderr e codici di ritorno non‑zero.

---

### 5. FLUSSI PRINCIPALI
- **Bootstrap normale (invocazione CLI senza azioni immediate)**
  1. Normalizzazione variabili e parsing CLI (popola DRY_RUN, STREAM_MODE, ARGS, FILE_INPUTS, ecc.).  
  2. Costruzione SUPPORTED_PROVIDERS leggendo extras/providers e aggiungendo "groq".  
  3. Caricamento config locale (load_local_config) e whitelist (load_whitelist).  
  4. Risoluzione modello tramite resolve_model (applica priorità e validazioni).  
  5. Chiamata a build_payload_from_vars (delegata al provider).  
  6. Esecuzione perform_request_once che invoca call_api_once o call_api_streaming; gestione retries e finalize_and_output.  

- **Azione immediata: --list-models / --list-providers**
  1. Parsing CLI imposta LIST_MODELS o LIST_PROVIDERS.  
  2. Se LIST_PROVIDERS: stampa elenco providers e tenta leggere default model persistito; esce 0.  
  3. Se LIST_MODELS: chiama list_models_cli che legge MODELS_FILE e stampa; esce 0/errore.  

- **Persist default model (--set-default)**
  1. Verifica e crea canonical_config_dir; rifiuta se è symlink.  
  2. Determina target_provider (PROVIDER_CLI > persisted provider file > PROVIDER).  
  3. Scrive target_model_file con atomic_write e imposta permessi 600; log e exit 0.  

- **Install extras (--install-extras)**
  1. Determina SRC_BASE e DEST_BASE; canonicalizza path.  
  2. Controlli di sicurezza: legacy dir, symlink, source inside dest, source==dest.  
  3. Raccoglie file regolari con find; valida ownership e tipi.  
  4. Copia atomica dei file in DEST_BASE preservando layout; imposta permessi restrittivi.  
  5. Stampa riepilogo e verifica sintassi provider installati; exit 0.  

- **Chiamata API con retry e edge detection**
  1. build_payload_from_vars prepara PAYLOAD.  
  2. perform_request_once tenta call_api_once; se DRY_RUN simula e ritorna.  
  3. Dopo risposta, extract_text_from_resp e detect_empty_edge_case.  
  4. Se necessario, scrive fallback last_api.json.  
  5. Se testo vuoto e non JSON/pretty, estrae api_err o segnala edge empty; altrimenti finalize_and_output e ritorna 0.

---

### 6. ERROR HANDLING E POLICY
- **Strategia generale**
  - *Fail‑fast* per condizioni di sicurezza o incoerenze critiche (es. config dir symlink, provider module mancante per operazioni richieste).  
  - *Delegazione degli errori provider* al chiamante: quando una funzione provider manca si logga e si ritorna/exit con codici specifici (127 o GROQBASHERRAPI).  
  - *Retry* per errori non‑API (perform_request_once usa MAX_RETRIES e backoff lineare).  
  - *Diagnostica dettagliata* quando DEBUG=1 (stampa head di RESP, log_info/log_warn).  
- **Punti di validazione importanti**
  - Validazione modello: validate_model_core verifica presenza in MODELS_FILE e pattern test‑only; validate_model_dispatch permette controlli provider‑specifici.  
  - Sicurezza filesystem: rifiuto di usare canonical_config_dir se invalido o root; rifiuto di scrivere se config dir è symlink.  
  - Install extras: verifica che sorgente non sia symlink, che i file siano regolari e di proprietà dell’utente corrente.  
  - API call: DRY_RUN blocca chiamate reali; ALLOW_API_CALLS impedisce chiamate se GROQ_API_KEY è impostata ma ALLOW_API_CALLS non è vero.  
- **Policy particolari**
  - **Rete:** tutte le chiamate HTTP sono delegate ai provider; CORE_SETUP non effettua chiamate dirette; DRY_RUN impedisce rete reale.  
  - **Permessi:** file persistenti creati con permessi restrittivi (600 per file sensibili, 700 per dir extras); atomic_write usato quando disponibile.  
  - **Sicurezza:** non leggere file di configurazione se canonical_config_dir è sospetto; non eseguire codice proveniente da extras (solo sourcing controllato con bash -n e verifica di funzioni richieste).  
  - **Non‑esecuzione delle risposte:** il sistema non esegue output API come comandi shell; nessun uso di eval.

---

**Estratto rilevante dal codice analizzato:**  
- *"resolve_model: determina MODEL finale seguendo ordine di priorità e validando"*.   
- *"Build payload from current vars (delegates to provider)"*. 

---

### IDENTITÀ DELLA SEZIONE
- **Nome sezione**  
# CORE_PROVIDER**
- **Scopo**  
  Gestire la scoperta, selezione, caricamento e validazione del provider API; esporre comandi diagnostici e operazioni correlate ai modelli (refresh, visualizzazione). Fornire persistenza della scelta provider e risolvere l’URL del provider.

- **Responsabilità principali**
  - Scoprire provider disponibili (builtin + extras) e costruire `SUPPORTED_PROVIDERS`.
  - Applicare priorità di selezione: persistito su file, override CLI, selezione interattiva.
  - Persistere la scelta provider in modo atomico e con permessi restrittivi.
  - Caricare il modulo provider tramite `load_provider_module` e risolvere l’URL tramite `resolve_provider_url`.
  - Validare l’interfaccia del provider (funzioni richieste/optional) tramite `validate_provider_interface`.
  - Gestire refresh dei modelli (`REFRESH_MODELS`) e refresh automatico se whitelist locale mancante.
  - Esporre operazioni di diagnostica/config (`PRINT_CONFIG_DIR`, `SHOW_CONFIG`, `DIAGNOSTICS`, ecc.).

- **Non‑responsabilità (cosa NON fa)**
  - Non implementa chiamate API concrete (delegate al provider: `call_api_*`).
  - Non gestisce parsing o invio di prompt; non costruisce payload (delegate a `buildpayload_*`).
  - Non esegue operazioni di rete dirette oltre a quelle delegate (non usa curl direttamente qui).
  - Non modifica la logica interna dei provider né i file di modello oltre a rimuovere cache quando cambia provider.

> Estratto rilevante dal codice sorgente: "Provider discovery and loading (keeps behavior compatible)".   
> Estratto rilevante dal codice sorgente: "local required=( \"buildpayload_${p}\" \"call_api_${p}\" )". 

---

### INVARIANTI E MODELLO MENTALE
- **Invarianti di stato prima/dopo**
  - Prima dell’esecuzione: variabili globali di configurazione (es. `PROVIDER`, `PROVIDERS_DIR`, `GROQBASH_MODELS_DIR`) possono essere impostate esternamente; `SUPPORTED_PROVIDERS` non è ancora popolato.
  - Dopo l’esecuzione: `SUPPORTED_PROVIDERS` è popolato; `PROVIDER` riflette la scelta finale (persistita se necessario); il modulo provider è caricato e validato; `GROQBASH_PROVIDER_URL` può essere risolto.
  - Se `PROVIDER_MODULE_LOADED` è 1, allora l’interfaccia provider è stata validata con successo.

- **Assunzioni su ambiente / file / variabili**
  - Esistenza di helper esterni: `canonical_provider_file`, `canonical_provider_url_file`, `canonical_model_file`, `ensure_config_dir`, `atomic_write`, `load_provider_module`, `resolve_provider_url`, `ensure_api_key_for_provider`, `refresh_models_dispatch`, `log_error`, `log_info`, `trim`.
  - Directory `PROVIDERS_DIR` può contenere script provider `.sh` (extras).
  - File di persistenza provider è leggibile/scrivibile dall’utente; permessi possono essere impostati a 600.
  - Variabili d’ambiente come `PROVIDER_CLI`, `PROVIDER_INTERACTIVE`, `REFRESH_MODELS`, `PRINT_CONFIG_DIR`, `SHOW_CONFIG`, `DIAGNOSTICS`, `MODELS_FILE`, `MODEL`, `ALLOWED_MODELS` sono usate come input di controllo.
  - L’utente controlla la directory di installazione; ambiente single‑user (non multi‑tenant).

- **Garanzie offerte al resto del sistema**
  - Fornisce un provider coerente e persistente per l’intera esecuzione.
  - Garantisce che il modulo provider caricato implementi le funzioni richieste (`buildpayload_*`, `call_api_*`) prima che il resto del sistema tenti di usarle.
  - Se la selezione provider è cambiata, la cache dei modelli (`MODELS_FILE`) viene invalidata per evitare incoerenze.
  - Fornisce diagnostica e informazioni canoniche sui file di configurazione e percorsi.

---

### DIPENDENZE
- **Dipendenze in ingresso**
  - *Variabili d’ambiente lette*
    - `PROVIDER`, `PROVIDER_CLI`, `PROVIDER_INTERACTIVE`, `PROVIDER_INTERACTIVE_SELECTED` (set internamente), `REFRESH_MODELS`, `PRINT_CONFIG_DIR`, `PRINT_PROVIDER_FILE`, `PRINT_MODEL_FILE`, `SHOW_CONFIG`, `DIAGNOSTICS`, `MODELS_FILE`, `MODEL`, `MODEL_CLI_SET`, `GROQBASH_MODELS_DIR`, `GROQBASH_TMPDIR`, `GROQBASH_HISTORY_DIR`, `GROQBASH_CONFIG_DIR`, `GROQBASH_EXTRAS_DIR`, `ALLOWED_MODELS`, `DEBUG`, `QUIET`, `DRY_RUN`, eventuali provider‑specific env come `${PROV}_API_KEY` o `PROVIDER_API_ENV_${PROVIDER}`.
  - *File letti*
    - File persistente provider: `$(canonical_provider_file)` (se esiste).
    - File provider-url: `$(canonical_provider_url_file)` (per embedded default logic).
    - Eventuali script provider in `PROVIDERS_DIR/*.sh`.
    - File modello persistente: `MODELS_FILE` (per refresh/invalidate).
    - File modello per provider: `canonical_model_file`.
  - *Funzioni esterne chiamate (altre macro‑sezioni / helper)*
    - `canonical_provider_file`, `canonical_provider_url_file`, `canonical_model_file`, `ensure_config_dir`, `atomic_write`, `load_provider_module`, `resolve_provider_url`, `ensure_api_key_for_provider`, `refresh_models_dispatch`, `log_error`, `log_info`, `trim`, `atomic_write`, `write_provider_url_if_missing`, `type` (builtin shell), `sed`, `awk`, `printf`, `grep`.

- **Dipendenze in uscita**
  - *Variabili globali impostate o modificate*
    - `SUPPORTED_PROVIDERS` (stringa)
    - `PROVIDER` (scelta finale)
    - `PROVIDER_INTERACTIVE_SELECTED` (flag)
    - `PROVIDER_MODULE_LOADED` è atteso essere impostato da `load_provider_module` (non direttamente qui)
    - `GROQBASH_PROVIDER_URL` (tramite `resolve_provider_url`)
    - Possibile aggiornamento di `MODELS_FILE` (rimozione) quando provider cambia
  - *File creati/scritti*
    - Persistenza scelta provider: file `canonical_provider_file` scritto tramite `atomic_write` e chmod 600.
    - Best‑effort: provider-url file scritto tramite `write_provider_url_if_missing`.
    - Rimozione file `MODELS_FILE` quando necessario.
  - *Side‑effects*
    - Stampa su `stderr`/`stdout` per prompt interattivi, messaggi di info/errore e diagnostica.
    - Exit con codici specifici (`$GROQBASHERRTMP`, `$GROQBASHERRAPI`, `$GROQBASHERRNOAPIKEY`, 0) in caso di errori o operazioni terminate.
    - Possibile rete indiretta: `refresh_models_dispatch` può effettuare chiamate di rete (delegato al provider).

---

### API ESPOSTA (vista come modulo)
> Nota: la sezione definisce principalmente funzioni helper e flussi; le funzioni rilevanti esposte sono quelle chiamate o definite qui.

- **validate_provider_interface**
  - **Ruolo**: Verificare che il modulo provider definisca le funzioni richieste e segnalare mancanze.
  - **Input**: parametro posizionale `p` (nome provider); legge `DEBUG` per logging opzionale.
  - **Output**: ritorna `0` se tutte le funzioni richieste sono presenti; ritorna non‑zero se mancano funzioni richieste.
  - **Side‑effect**: chiama `log_error` per ogni funzione richiesta mancante; chiama `log_info` per funzioni opzionali mancanti se `DEBUG=1`.
  - **Errori**: segnala mancanze impostando `missing=1` e ritorna codice di errore; il chiamante esegue `exit` con `$GROQBASHERRAPI` se fallisce.

- **load_provider_module** *(invocata ma non definita in questa sezione)*
  - **Ruolo**: caricare il file modulo del provider e impostare `PROVIDER_MODULE_LOADED`.
  - **Input**: `PROVIDER` (nome provider).
  - **Output**: valore booleano/exit code; qui la sezione verifica il successo e fa `exit` su fallimento.
  - **Errori**: fallimento causa log e `exit $GROQBASHERRTMP`.

- **resolve_provider_url** *(invocata ma non definita qui)*
  - **Ruolo**: risolvere `GROQBASH_PROVIDER_URL` da ENV > provider-url file > embedded default.
  - **Input**: `PROVIDER`.
  - **Output**: imposta `GROQBASH_PROVIDER_URL` come side‑effect; ritorna successo/fallimento (qui ignorato con `|| true`).
  - **Errori**: non critici in questa sezione (silenziosamente ignorati).

- **refresh_models_dispatch** *(invocata ma non definita qui)*
  - **Ruolo**: aggiornare la lista modelli provider‑specifica e scriverla in `MODELS_FILE`.
  - **Input**: `MODELS_FILE`.
  - **Output**: ritorna successo/fallimento; qui la sezione esegue `exit` o continua in base al contesto.
  - **Errori**: fallimento può causare `exit $GROQBASHERRAPI` quando esplicitamente richiesto; in refresh automatico è tollerato.

- **ensure_api_key_for_provider** *(invocata ma non definita qui)*
  - **Ruolo**: verificare che sia presente una API key valida per il provider.
  - **Input**: `PROVIDER`.
  - **Output**: booleano; usato per decidere se eseguire refresh modelli.
  - **Errori**: assenza di API key porta a log e `exit $GROQBASHERRNOAPIKEY` quando richiesta.

- **atomic_write** *(helper esterno)*
  - **Ruolo**: scrivere file in modo atomico con retry.
  - **Input**: contenuto via stdin, percorso file, timeout/retry.
  - **Output**: successo/fallimento; fallimento qui causa log e exit.

---

### FLUSSI PRINCIPALI
- **Bootstrap provider discovery e selezione (non interattivo)**
  1. Popola `_supported_providers_arr` con "groq" e con gli script `.sh` trovati in `PROVIDERS_DIR`.
  2. Costruisce `SUPPORTED_PROVIDERS` come stringa separata da spazi.
  3. Se esiste file persistito provider e non c’è override CLI/interactive, legge e imposta `PROVIDER`.
  4. Se `PROVIDER_CLI` è fornito (non "list"), valida che sia in `SUPPORTED_PROVIDERS`; imposta `PROVIDER` e persiste la scelta con `atomic_write`.
  5. Se il provider è cambiato, rimuove `MODELS_FILE` per invalidare cache.

- **Selezione provider interattiva**
  1. Costruisce array `_prov_arr` da `SUPPORTED_PROVIDERS`.
  2. Determina `current_default` da `PROVIDER` o file persistito.
  3. Stampa elenco e legge selezione utente da stdin.
  4. Mappa input numerico o nome a `chosen`; valida scelta.
  5. Assicura `ensure_config_dir`, persiste scelta con `atomic_write`, imposta `PROVIDER` e `PROVIDER_INTERACTIVE_SELECTED`.
  6. Carica modulo provider (`load_provider_module`) e rimuove `MODELS_FILE` se provider cambiato.
  7. Se l’invocazione era solo per cambiare provider (nessun argomento), stampa conferma ed esce 0.

- **Caricamento e validazione modulo provider**
  1. Chiama `load_provider_module` per il `PROVIDER` finale; fallimento => log + exit.
  2. Chiama `resolve_provider_url` per impostare `GROQBASH_PROVIDER_URL`.
  3. Esegue `validate_provider_interface` per assicurare presenza di `buildpayload_*` e `call_api_*`.
  4. Se validazione fallisce => exit con `$GROQBASHERRAPI`.

- **Refresh modelli esplicito e implicito**
  1. Se `REFRESH_MODELS=1`: verifica API key con `ensure_api_key_for_provider`; se assente => exit con `$GROQBASHERRNOAPIKEY`.
  2. Se presente API key, chiama `refresh_models_dispatch` su `MODELS_FILE`; fallimento => exit con `$GROQBASHERRAPI`.
  3. Se `MODELS_FILE` non esiste o è vuoto e API key presente, chiama `refresh_models_dispatch` ma ignora errori (best‑effort).

- **Mostra configurazione / diagnostica**
  1. Se flag `PRINT_CONFIG_DIR`/`PRINT_PROVIDER_FILE`/`PRINT_MODEL_FILE` impostati, stampa percorso corrispondente ed esce.
  2. Se `SHOW_CONFIG=1`, stampa riepilogo configurazione e stato file modello persistente.
  3. Se `DIAGNOSTICS=1`, verifica esistenza directory, presenza funzioni provider, whitelist modello, API key e tmpdir; stampa risultati ed esce.

---

### ERROR HANDLING E POLICY
- **Strategia generale**
  - Fail‑fast per errori critici (impossibilità di persistere provider, caricamento modulo fallito, validazione interfaccia mancante) con logging e exit con codici specifici.
  - Tolleranza per operazioni non critiche: best‑effort per scrittura provider‑url, refresh modelli automatico non bloccante se manca API key.
  - Uso coerente di helper `log_error`/`log_info` per messaggi diagnostici.

- **Punti di validazione importanti**
  - Validazione che `PROVIDER_CLI` sia in `SUPPORTED_PROVIDERS`.
  - Verifica che `ensure_config_dir` ritorni successo prima di persistere.
  - `atomic_write` deve riuscire per considerare la persistenza valida; altrimenti exit.
  - `load_provider_module` deve riuscire e impostare `PROVIDER_MODULE_LOADED`.
  - `validate_provider_interface` deve confermare la presenza di `buildpayload_*` e `call_api_*`.

- **Policy particolari**
  - **Sicurezza file**: file persistiti (provider file) sono scritti con permessi restrittivi (chmod 600).
  - **No /tmp globale**: la sezione rispetta la policy di non usare `/tmp` di sistema per file temporanei (gestito a livello globale).
  - **Non esecuzione di codice remoto**: la sezione non esegue output proveniente da provider come comandi shell; delega solo a funzioni provider verificate.
  - **Minimizzare privilegi**: scritture su file di configurazione avvengono solo dopo `ensure_config_dir` e con atomicità.
  - **Rete**: chiamate di rete per refresh modelli sono delegate al provider e richiedono API key; la sezione non effettua chiamate di rete dirette.

---
