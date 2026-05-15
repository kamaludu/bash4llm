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

Questa versione compatta contiene i nomi delle funzioni, le dipendenze critiche, le invarianti e le garanzie necessarie per ragionare sull’architettura e sul comportamento della sezione PRECORE_RUN senza codice né dettagli superflui.

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

Fine della specifica tecnica strutturale per la macro‑sezione **PROVIDER**.

---
