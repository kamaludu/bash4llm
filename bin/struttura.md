## GroqBash — Documento di Architettura Strutturale

### PRECORE

**Responsabilità principali**  
- Inizializzazione dell’ambiente di esecuzione e delle variabili globali critiche.  
- Validazione dei prerequisiti di sistema e delle dipendenze esterne.  
- Fornitura di utilità di basso livello condivise (logging, locking, base64, scritture atomiche, gestione tmp).  
- Protezione e hardening iniziale (permessi directory, controlli su symlink e ownership).

**Gruppi di funzioni e loro ruolo**  
- **Inizializzazione e configurazione**: risolve il percorso dello script, determina directory canoniche (config, models, templates, history, tmp), applica umask e crea directory con permessi restrittivi.  
- **Validazione prerequisiti**: verifica la presenza dei comandi obbligatori e termina in caso di mancanze.  
- **Logging strutturato**: funzioni per log informativi, warning ed errori con opzione di scrittura su file di log.  
- **Locking e atomicità**: wrapper per acquisire lock con timeout e funzioni per scritture atomiche (file raw e staging base64).  
- **Base64 e staging**: rilevamento opzioni portabili di base64, wrapper per encode/decode e helper per scritture/letture atomiche in formato base64.  
- **Tmpdir runtime**: creazione e pulizia di una RUN_TMPDIR isolata per ogni esecuzione, con trap per cleanup.  
- **Utility portabili**: funzioni per dimensione file, firma file, permessi, owner, e altre astrazioni portabili tra sistemi.

**Guard per sourcing / test**  
- Il PRECORE include un meccanismo di guard che permette di importare (sourcere) lo script senza eseguire il flusso principale. Questo è realizzato tramite una variabile di controllo (es. una variabile tipo `GROQBASH_SOURCE_ONLY`) che, se impostata, interrompe l’esecuzione del main e lascia disponibili solo le definizioni di funzione.  
- **Scopo**: consentire test e sviluppo delle singole funzioni interne in isolamento, senza attivare il parsing CLI, prompt interattivi, creazione di tmpdir di esecuzione o chiamate di rete. Questo facilita unit testing, validazione statica e riuso delle primitive in contesti di test/dev.

**Come i pezzi si collegano**  
- Le utility di basso livello forniscono primitive usate da tutte le altre sezioni: locking e atomic write sono usati per aggiornare manifest, models e history; base64/staging è usato per payload e manifest; tmpdir è il contesto operativo per payload, risposte e marker di sessione. Il PRECORE stabilisce lo stato iniziale e le garanzie di sicurezza su cui si appoggiano provider e core.

---

### PROVIDER

**Responsabilità principali**  
- Incapsulare le differenze tra servizi esterni (API provider): costruzione del payload, chiamata HTTP (streaming e non), refresh dei modelli, validazione specifica del provider e logiche di auto-selezione del modello.  
- Fornire un’interfaccia modulare che il CORE può invocare in modo agnostico rispetto al provider attivo.

**Contratto minimo (interfaccia richiesta)**  
- **Funzioni obbligatorie** (nome e ruolo):  
  - `buildpayload_<provider>()` — costruisce e prepara il payload API a partire dalle variabili runtime e dai file di staging; produce uno staging sicuro (es. file in RUN_TMPDIR).  
  - `call_api_<provider>()` — esegue la chiamata HTTP non‑streaming, valida il payload/response e salva la risposta in modo atomico.  
- **Funzioni opzionali** (se implementate, il CORE le invocherà):  
  - `call_api_streaming_<provider>()` — supporto per streaming/SSE con parsing incrementale e ricostruzione dei chunk.  
  - `refresh_models_<provider>()` — recupera la lista modelli dal provider e aggiorna il MODELS_FILE in modo atomico.  
  - `validate_model_<provider>()` — validazione provider-specifica di un nome modello.  
  - `auto_select_model_<provider>()` — logica di auto-selezione del modello preferito dal provider.  

**Gruppi di funzioni e loro ruolo**  
- **Costruttori di payload**: trasformano variabili runtime (CONTENT, SYSTEM_PROMPT, BUILD_MESSAGES_FILE, JSON_INPUT, opzioni di stream/temperature/max_tokens) in un payload pronto per l’API; spesso producono uno staging base64 nel RUN_TMPDIR.  
- **Chiamate API non-streaming**: wrapper che decodificano payload staged, validano JSON, invocano l’endpoint HTTP, gestiscono output atomico su file di risposta e mappano codici HTTP in esiti.  
- **Chiamate API streaming**: implementano la logica SSE/stream parsing, salvataggio raw del flusso, estrazione incrementale dei frammenti e ricostruzione di un JSON finale con chunk.  
- **Gestione modelli**: refresh remoto dei modelli disponibili, parsing e normalizzazione della lista, scrittura atomica del MODELS_FILE; funzioni di validazione e auto-selezione modello provider-specifiche.  
- **Adattatori e fallback**: helper per compatibilità con formati legacy o nomi provider-specifici.

**Come i pezzi si collegano**  
- Il CORE invoca le funzioni provider-nominate tramite dispatch. I provider devono usare le primitive del PRECORE (tmpdir, b64_atomic_write, lock_exec, atomic_write) per garantire atomicità e sicurezza. La separazione permette di aggiungere o sostituire provider senza modificare la logica di alto livello; il CORE parla con i provider esclusivamente attraverso l’interfaccia minima sopra elencata.

---

### CORE

**Responsabilità principali**  
- Orchestrare il flusso principale dell’applicazione: parsing CLI, selezione provider e modello, costruzione del payload, invocazione API, gestione delle risposte, retry e salvataggio storico.  
- Fornire funzionalità di sessione, batch, chat interattiva, e azioni immediate (list models, refresh, install extras, diagnostics).

**Gruppi di funzioni e loro ruolo**  
- **Dispatch provider**: wrapper che chiamano le funzioni provider-specifiche e gestiscono errori di interfaccia (assenza di funzioni richieste).  
- **Costruzione payload orchestrata**: prepara il contesto (BUILD_MESSAGES_FILE, SYSTEM_PROMPT, STDIN_CONTENT, template expansion) e delega al provider per il payload finale.  
- **Chiamata API e retry**: logica di esecuzione con tentativi multipli, gestione di DRY_RUN, distinzione tra streaming e non-streaming, e mapping degli errori.  
- **Estrazione e finalizzazione risposta**: estrazione del testo da JSON di risposta (supporto per message.content e delta.content), rilevamento di edge case, formattazione finale (json/pretty/text/raw) e salvataggio condizionato nella history.  
- **Session management**: orchestrazione dell’uso di BUILD_MESSAGES_FILE, invocazione dei helper di sessione per leggere la finestra di messaggi e per appendere user/assistant al file di sessione.  
- **Azioni immediate e CLI**: parsing delle opzioni, gestione di comandi come list-models, list-providers, set-default, install-extras, refresh-models, diagnostics e show-config.  
- **Gestione history e rotazione**: salvataggio atomico degli output, rotazione e compattazione della history secondo policy configurabili.

**Edge case API e logging strutturato**  
- Esiste un percorso centralizzato per la gestione dell’edge case noto come “completion vuota”. Questo percorso è composto da tre componenti orchestrati nel CORE: l’estrazione del testo (`extract_text_from_resp`), il rilevamento dell’edge case (`detect_empty_edge_case`) e la logica di controllo/retry (`perform_request_once`).  
- Quando l’edge case viene rilevato, il CORE emette un logging strutturato **una sola volta** in un punto definito della sequenza di gestione della risposta. Il log contiene dettagli diagnostici chiave (ad esempio `req_id`, `finish_reason`, `completion_tokens`) e viene usato per decisioni successive (es. non retryare o segnalare errore API). Questo approccio centralizzato evita duplicazioni di messaggi diagnostici e garantisce che l’informazione critica sia disponibile in modo coerente per operatori e strumenti di monitoraggio.

**Come i pezzi si collegano**  
- Il CORE è il coordinatore: usa PRECORE per operazioni atomiche e di sicurezza, invoca PROVIDER per costruire e inviare payload, usa i helper di sessione per integrare la persistenza conversazionale, e infine applica la logica di output e salvataggio. Le azioni CLI immediate possono interrompere il flusso principale e richiamare funzioni specifiche del CORE o del PROVIDER.

---

### Directory e path runtime

**Responsabilità principali**  
- Definire e centralizzare i percorsi usati dall’applicazione per configurazione, modelli, template, history, tmp e plugin.  
- Garantire permessi e isolamento dei dati sensibili.

**Elementi chiave e loro ruolo**  
- **GROQBASH_DIR**: root configurabile dell’installazione; base per tutte le sottodirectory.  
- **GROQBASH_CONFIG_DIR**: contiene file di configurazione persistenti (es. provider, model.<provider>, config).  
- **GROQBASH_MODELS_DIR e MODELS_FILE**: archivio locale dei modelli disponibili e file whitelist.  
- **GROQBASH_TEMPLATES_DIR**: template per prompt con placeholder.  
- **GROQBASH_HISTORY_DIR**: salvataggio degli output e sessioni NDJSON; include sottodirectory sessions.  
- **GROQBASH_TMPDIR e RUN_TMPDIR**: tmp persistente per l’applicazione e tmp per singola esecuzione; RUN_TMPDIR è creato per ogni invocazione e ospita payload, resp, err, marker di sessione.  
- **PROVIDERS_DIR e GROQBASH_EXTRAS_DIR**: directory runtime per plugin provider e script opzionali installati tramite install-extras.  
- **Lock files**: file di lock collocati vicino alle risorse (models.lock, history.lock, tmp.lock) per sincronizzazione.

**Distinzione sorgente vs runtime**  
- `./extras/` nella root del repository è **solo** sorgente per installazione manuale o per il comando di installazione degli extras; non è il percorso di runtime.  
- **A runtime** gli unici percorsi autorizzati per extras e provider sono `GROQBASH_EXTRAS_DIR` e `PROVIDERS_DIR` (sotto `GROQBASH_DIR`). Questi sono i percorsi effettivamente usati dall’eseguibile per caricare provider, template e script opzionali.  
- È esplicitamente previsto che il codice non usi direttamente `./extras/` a runtime: il flusso di installazione copia/installa i file da `./extras/` sorgente verso `GROQBASH_EXTRAS_DIR`/`PROVIDERS_DIR`, e solo questi ultimi vengono considerati attendibili ed eseguibili in produzione.

**Come i pezzi si collegano**  
- Le funzioni di PRECORE e CORE leggono/scrivono in queste directory usando le primitive atomiche e i lock. RUN_TMPDIR è il contesto operativo per payload e risposte; MODELS_FILE e PROVIDER_FILE sono usati per decisioni di selezione modello/provider; HISTORY_DIR conserva la cronologia e le sessioni NDJSON.

---

### Vincoli architetturali

**Responsabilità principali**  
- Stabilire regole e limitazioni progettuali che guidano implementazione e sicurezza.

**Principali vincoli osservati**  
- **Portabilità shell**: dipendenza esclusiva da strumenti POSIX/GNU comuni (bash, jq, curl, mktemp, flock, base64) e astrazioni per differenze tra sistemi (stat, base64 options).  
- **Atomicità e concorrenza**: tutte le scritture critiche (models, manifest, history, payload) devono essere atomiche e protette da lock per evitare corruzione in esecuzioni concorrenti.  
- **Minimo privilegio e sicurezza file**: directory e file creati con permessi restrittivi; rifiuto di directory o file world-writable o symlink sospetti; controlli di ownership.  
- **Modularità provider**: interfaccia ben definita che richiede funzioni minime per ogni provider; fallback al provider embedded se plugin non valido.  
- **Non-intrusività**: operazioni che possono essere pericolose (es. refresh modelli, install extras) richiedono chiari controlli e validazioni prima di scrivere.  
- **Robustezza input**: supporto per vari formati di input (raw content, template, JSON_INPUT con diverse forme) e deduplicazione/normalizzazione dei messaggi.  
- **Gestione edge case API**: rilevamento e logging strutturato di casi anomali (completions vuote, errori HTTP, payload non-JSON).

**Invarianti critici (non negoziabili)**  
1. **Nessun file runtime al di fuori di `GROQBASH_DIR`**: tutti i file creati o modificati durante l’esecuzione devono risiedere sotto il percorso runtime canonicalizzato (`GROQBASH_DIR` e sue sottodirectory).  
2. **Nessun uso diretto di `/tmp` di sistema**: l’applicazione deve usare esclusivamente `GROQBASH_TMPDIR` e `RUN_TMPDIR` per tutti i file temporanei e di staging.  
3. **Nessun `eval` e nessuna esecuzione di contenuto generato dal modello**: il codice non deve eseguire stringhe o script prodotti dal provider; ogni input esterno è trattato come dati, non come codice eseguibile.  
4. **Tutte le scritture su history/models sono atomiche e protette da lock**: ogni aggiornamento a MODELS_FILE, manifest o history passa attraverso primitive atomiche e lock per garantire consistenza in presenza di concorrenza.  
5. **I provider devono usare le primitive di PRECORE per I/O e lock**: le implementazioni provider non devono bypassare le API atomiche e di locking fornite dal PRECORE; questo mantiene le invarianti di sicurezza e atomicità.

**Come i pezzi si collegano**  
- I vincoli sono applicati trasversalmente: PRECORE fornisce primitive per rispettare atomicità e permessi; CORE applica policy di retry, validazione modello e sicurezza; PROVIDER deve rispettare le aspettative di formato e usare le primitive atomiche per staging e I/O.

---

### Flusso di esecuzione ad alto livello

**1. Avvio e bootstrap**  
- Il PRECORE esegue controlli di prerequisiti, risolve directory e crea RUN_TMPDIR di lavoro. Vengono inizializzate variabili globali e logging. Se la variabile di guard per sourcing è attiva, il main viene saltato e lo script espone solo le funzioni per test.

**2. Parsing CLI e azioni immediate**  
- Il CORE interpreta opzioni CLI. Se è richiesta un’azione immediata (list providers/models, install-extras, set-default, diagnostics), viene eseguita e il processo termina.

**3. Selezione provider e caricamento modulo**  
- Viene determinato il provider attivo (persisted o CLI). Se esiste un modulo provider esterno, viene validato (syntax check, owner/permessi) e sorgente; altrimenti si usa il provider embedded. L’interfaccia del provider viene verificata (funzioni richieste presenti).

**4. Se necessario refresh modelli**  
- Se MODELS_FILE mancante o richiesta esplicita, il CORE invoca il refresh provider-specifico che aggiorna MODELS_FILE in modo atomico.

**5. Determinazione modello finale**  
- Il CORE applica la gerarchia di precedenza (CLI, persisted config, auto-select provider, MODELS_FILE, ALLOWED_MODELS) e valida il modello sia a livello core che provider-specifico.

**6. Preparazione input e payload**  
- assemble_content costruisce CONTENT da file, stdin, template o JSON_INPUT. Se sessioning attivo, session_read_window produce BUILD_MESSAGES_FILE. Il CORE chiama buildpayload_<provider> che usa BUILD_MESSAGES_FILE, CONTENT e opzioni per creare il payload staged (spesso .b64) in RUN_TMPDIR.

**7. Invocazione API**  
- In base a STREAM_MODE e DRY_RUN, il CORE invoca call_api_<provider> o call_api_streaming_<provider>. Le funzioni provider decodificano payload, validano JSON, eseguono la chiamata HTTP e salvano la risposta in modo atomico. Per lo streaming viene anche prodotto un raw stream e una ricostruzione a chunk.

**8. Estrazione risposta e gestione edge case**  
- extract_text_from_resp estrae testo da response JSON; detect_empty_edge_case individua completions vuote o anomalie. Il percorso centralizzato nel CORE decide se emettere il logging strutturato (una sola volta), retryare o fallire in modo controllato.

**9. Finalizzazione e persistenza**  
- finalize_and_output formatta l’output (json/pretty/text/raw), decide se salvare nella history (soglia, FORCE_SAVE_MODE, OUT_PATH) e invoca save_to_history che effettua scrittura atomica e può attivare rotate_history.

**10. Session persistence**  
- Se SESSION_ID è attivo, il CORE usa session_append per registrare l’user message e, se presente, la risposta assistant. session_append è idempotente tramite marker basati su message_id e protegge la scrittura con lock.

**11. Uscita e cleanup**  
- RUN_TMPDIR viene rimosso (salvo debug mode) tramite trap; log finali vengono emessi e il processo termina con codice coerente allo stato dell’operazione.

---

**Nota finale**  
Questo documento descrive l’organizzazione interna e l’architettura logica del file senza entrare nei dettagli di implementazione. Le sezioni evidenziano responsabilità, gruppi funzionali e i punti di integrazione tra PRECORE, PROVIDER e CORE, oltre ai vincoli, alle invarianti critiche e al flusso operativo che governano l’esecuzione di GroqBash.
