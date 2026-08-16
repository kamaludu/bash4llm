[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

[![WebApp](https://img.shields.io/badge/GUI--WebApp-Python--3.10+-007acc?style=flat-square&logo=python&logoColor=white)](#)

# DOCUMENTAZIONE TECNICA ED OPERATIVA INTEGRATA 🇮🇹 [🇬🇧](README-en.md)
## Modulo GUI WebApp `gui-py` per `bash4llm⁺` 
**Standard**: OpenAPI 3.1.0 Compatible | **Security Level**: T3 Hardened

---

## 1. Panoramica del Progetto & Filosofia Architetturale

### Scopo dell'Applicazione
Il modulo **`gui-py`** è un'interfaccia utente web opzionale, leggera e ad alte prestazioni progettata per estendere lo script core **`bash4llm`** (v2.8.5+). Il suo scopo primario è fornire un'esperienza d'uso grafica moderna (WebUI Single Page Application) accessibile da qualsiasi browser web, mantenendo inalterata la natura deterministica e Bash-first dell'infrastruttura sottostante.

### Principi Architetturali Chiave

1. **Modello *Thin Adapter***:
   * Lo script core `bash4llm` rimane l'unica autorità per la logica di dominio, lo stato dei thread di conversazione NDJSON, la persistenza su filesystem, la cifratura del Vault, la selezione dei provider e le chiamate API dirette agli LLM.
   * L'Adapter Python non implementa storage di dominio proprio, non altera il formato dei file e non duplica la logica di business.
   * La presenza o l'assenza del modulo `gui-py` (o di dipendenze Python quali `fastapi`, `uvicorn`, `pydantic`) **non modifica né compromette in alcun modo il funzionamento dello script core `bash4llm`**.

2. ***Domain-Stateless / Runtime-Stateful***:
   * **Domain-Stateless**: L'Adapter Python non memorizza permanentemente messaggi, chiavi API o cronologia. La lettura dei thread avviene mediante estrazione in sola lettura dai file `.ndjson` generati dal core.
   * **Runtime-Stateful**: L'Adapter gestisce in memoria RAM effimera un un registro dei Job attivi (`jobs_registry`), i gestori dei sottoprocessi (`process_pid`), le code dei token Server-Sent Events (`job_queues`), le sessioni client attive (`sessions`) e la tabella di idempotenza temporanea (`idempotency_store`).

3. ***Zero Credential Mirroring***:
   * Python non memorizza, estrae né manipola le credenziali degli LLM o la master password del Vault.
   * L'esecuzione delle chiamate avviene delegando per intero l'autenticazione al core `bash4llm` tramite variabili d'ambiente di processo o tramite il meccanismo di Vault nativo dello script Bash.

4. ***No Double Locking***:
   * L'Adapter Python non applica mutex o lock di sincronizzazione sui file del dominio. Se due o più richieste colpiscono contemporaneamente lo stesso `thread_id`, Python alloca ed esegue i rispettivi sottoprocessi asincroni, delegando al meccanismo di locking atomico nativo di `bash4llm` (`acquire_thread_lock`) l'arbitraggio transazionale su filesystem.

---

## 📋 2. Guida Utente (README & Quickstart)

### Prerequisiti di Sistema

* **Dipendenze Core bash4llm**: Bash 4.0+, coreutils, findutils, util-linux, awk, curl, jq
* **Runtime Python**: Python >= 3.10 (con moduli standard `pip` e `venv`)
* **Librerie Python Richieste**:
  - fastapi (>=0.100.0)
  - uvicorn (>=0.20.0)
  - pydantic (>=2.0.0)

* **Divieto di Automatismi**: Lo script launcher non installa automaticamente pacchetti né crea virtualenv senza autorizzazione esplicita. In caso di dipendenze mancanti, l'avvio si interrompe fornendo le istruzioni esatte per l'installazione manuale.

#### Esempi:

**Debian (con apt e pip)**
```sh
# 1. Installazione dei pacchetti di sistema
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# 2. Creazione e attivazione dell'ambiente virtuale
python3 -m venv .venv
source .venv/bin/activate

# 3. Installazione delle librerie Python
pip install --upgrade pip
pip install "fastapi>=0.100.0" "uvicorn>=0.20.0" "pydantic>=2.0.0"
```

**Termux (Android)**
```sh
# 1. Installazione di Python (include già pip e venv)
pkg update
pkg install -y python

# 2. Creazione e attivazione dell'ambiente virtuale
python -m venv .venv
source .venv/bin/activate

# 3. Installazione delle librerie Python
pip install --upgrade pip
pip install "fastapi>=0.100.0" "uvicorn>=0.20.0" "pydantic>=2.0.0"
```

**macOS (con Homebrew)**
```sh
# 1. Installazione di Python tramite Homebrew (include già pip e venv)
brew install python

# 2. Creazione e attivazione dell'ambiente virtuale
python3 -m venv .venv
source .venv/bin/activate

# 3. Installazione delle librerie Python
pip install --upgrade pip
pip install "fastapi>=0.100.0" "uvicorn>=0.20.0" "pydantic>=2.0.0"
```

**WSL (Windows Subsystem for Linux)**
```sh
# 1. Installazione dei pacchetti di sistema all'interno della shell WSL
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# 2. Creazione e attivazione dell'ambiente virtuale
python3 -m venv .venv
source .venv/bin/activate

# 3. Installazione delle librerie Python
pip install --upgrade pip
pip install "fastapi>=0.100.0" "uvicorn>=0.20.0" "pydantic>=2.0.0"
```

---

### Installazione e Sincronizzazione
Tutti i sorgenti del modulo risiedono nella cartella `extras/gui-py/` del repository. L'installazione sul sistema locale avviene tramite la CLI del core:

```bash
./bash4llm --install-extras
```

Questo comando copia l'alberatura in `bash4llm.d/extras/gui-py/` applicando i permessi restrittivi `0700` per le directory e `0600` per i file (Principio del Minimo Privilegio).

### 🚀 Avvio Rapido dell'Applicazione

L'avvio della WebApp GUI avviene direttamente tramite la CLI di `bash4llm`:

```bash
./bash4llm --gui
# oppure
./bash4llm --webapp
```

Lo script core verifica l'integrità crittografica del modulo mediante `manifest.sha256` e delega l'esecuzione allo script wrapper `extras/gui-py/gui-py.sh`.

#### 💻 Esecuzione Piattaforma per Piattaforma

* **Linux / macOS**:
  ```bash
  ./bash4llm --gui
  ```
  Lo script launcher valida l'ambiente Python, acquisisce l'Advisory Lock del processo su `gui_adapter.lock` tramite `fcntl.flock`, alloca la prima porta di loopback libera (a partire dalla `19970`) e apre automaticamente l'URL di autenticazione nel browser predefinito via `webbrowser.open()`.

* **Windows (Git Bash / MSYS2)**:
  ```bash
  ./bash4llm --gui
  ```
  Lo script rileva l'ambiente Windows, gestisce l'Advisory Lock via `msvcrt.locking` con inizializzazione a 1 byte e valida che la directory temporanea runtime risieda all'interno del profilo utente (`USERPROFILE` / `LOCALAPPDATA`).

* **Android (Termux)**:
  ```bash
  ./bash4llm --gui
  ```
  Utilizza l'utilità `termux-open-url` per l'avvio del browser di sistema e sfrutta la logica di auto-riconnessione del client JS in caso di sospensione del processo da parte del sistema operativo (Doze Mode).

### 🌐 Manuale d'Uso della GUI WebApp

1. **Autenticazione Iniziale**: All'avvio viene generato un `one_time_token` monouso. Il browser viene indirizzato su `http://127.0.0.1:19970/auth?one_time_token=...`. Il token viene consumato atomicamente in RAM e viene rilasciato un cookie di sessione sicuro `HttpOnly` con flag `SameSite=Strict`.
2. **Navigazione Thread (Sidebar)**:
   * Cliccando su **"+ New Thread"**, viene creato un nuovo contesto di conversazione.
   * La lista laterale mostra tutti i thread disponibili letti dal Read-Model. Selezionando un thread, la cronologia dei messaggi viene caricata in modalità sola lettura.
3. **Invio Prompt e Streaming**:
   * Inserire il testo nel campo di testo in basso e premere **"Send"** (o inviare via tastiera).
   * La risposta dell'LLM viene ricevuta in tempo reale token-by-token tramite streaming Server-Sent Events (SSE).
4. **Cancellazione Job in Corso**: Durante la generazione della risposta, il pulsante d'invio si trasforma nel pulsante rosso **"Stop"**. Cliccando su di esso, l'Adapter invia un segnale di interruzione `POST /api/jobs/{id}/cancel` al sottoprocesso Bash, arrestando immediatamente l'esecuzione senza corrompere la cronologia preesistente.
5. **Pannello Impostazioni (Settings)**:
   * Cliccando su **"Settings"**, è possibile selezionare il Provider attivo, il Modello, la Temperatura e la dimensione della finestra della cronologia (`thread_window`).

---

## 3. Architettura Interna e Ciclo di Vita

```text
extras/gui-py/
├── gui-py.sh         # Launcher CLI Wrapper (POSIX Bash 4.0+, 0700)
├── main.py           # Entrypoint Adapter Python 3.10+ (FastAPI + Uvicorn)
├── config.py         # Dataclass, Impostazioni Runtime, Temp Validation
├── models.py         # Dataclass Job, State Enum, Termination Cause
├── security.py       # Host/Origin Validation, Cookies, CSRF, Single-Instance Lock
├── ipc.py            # Subprocess Executor, Pipe I/O, UTF-8 Decoder, SSE Dispatcher
├── static/
│   ├── index.html    # Progressive Enhancement SPA HTML5
│   ├── error.html    # Template d'errore HTTP 401/403/500 minimale
│   ├── style.css     # Design UI responsive zero-framework
│   └── app.js        # SSE Streamer, CSRF Fetch, Form Enhancements
└── langs/            # Traduzioni multilingue 
    ├── en.json       
    └── it.json       
```

### Ciclo di Vita del Job (`JobState`)

Ogni richiesta di generazione inviata alla WebApp viene incapsulata in un oggetto `Job` gestito in memoria RAM dall'Adapter Python.

```text
       [ Client POST /api/chat ]
                   │
                   ▼
              ┌─────────┐
              │ CREATED │ (Allocato in memory registry)
              └────┬────┘
                   │
                   ▼
             ┌──────────┐
             │ STARTING │ (Invocazione subprocess asyncio)
             └─────┬────┘
                   │
                   ▼
              ┌─────────┐
              │ RUNNING │ (Iniezione prompt via stdin pipe)
              └────┬────┘
                   │
                   ▼
             ┌───────────┐
             │ STREAMING │ (Flussaggio token via SSE)
             └─────┬─────┘
                   │
     ┌─────────────┼───────────────────────────┐
     │             │                           │
     ▼             ▼                           ▼
┌───────────┐ ┌──────────┐            ┌──────────────────┐
│ COMPLETED │ │  FAILED  │            │ CANCEL_REQUESTED │
└───────────┘ └──────────┘            └────────┬─────────┘
(Exit Code 0) (Exit Code != 0                   │
               o errore JSON)         ┌─────────┴─────────┐
                                      │  Process Killed   │
                                      └─────────┬─────────┘
                                                │
                                                ▼
                                         ┌───────────┐
                                         │ CANCELLED │
                                         └───────────┘
```

#### Descrizione Formale degli Stati (`JobState` Enum)
* **`CREATED`**: Il Job è stato allocato nell'idempotency registry `jobs_registry` con un `job_id` univoco (`job_<hex16>`).
* **`STARTING`**: L'Adapter ha preparato la lista esplicita degli argomenti CLI e l'ambiente sanificato, e sta avviando il sottoprocesso via `asyncio.create_subprocess_exec`.
* **`RUNNING`**: Il processo `bash4llm` è attivo (`process.pid` assegnato). Il prompt utente viene inviato mediante scrittura asincrona sulla pipe `stdin`.
* **`STREAMING`**: I token generati da `bash4llm` vengono letti da `stdout` mediante `codecs.getincrementaldecoder('utf-8')` e trasmessi al client via SSE.
* **`CANCEL_REQUESTED`**: È stata ricevuta una richiesta `POST /api/jobs/{job_id}/cancel`. L'Adapter ha avviato la procedura di terminazione dell'albero dei processi.
* **`CANCELLED`**: Il processo `bash4llm` è stato terminato con successo da segnale di sistema (`SIGTERM` o `SIGKILL`). Il campo `termination_cause` viene valorizzato.
* **`COMPLETED`**: Il processo `bash4llm` è uscito spontaneamente con exit code `0`. La risposta completa è memorizzata nel buffer di RAM `prompt_response`.
* **`FAILED`**: Il processo è uscito con exit code non-zero oppure il core ha emesso un errore di diagnostica JSON su `stderr` (`core_error_code` $10\div17$).

### Gestione Multi-Tab & Active Clients

L'Adapter gestisce la presenza simultanea di più schede o browser connessi tramite il tracciamento dinamico delle sessioni.

#### Definizione Formale di *Active Client*
Un client è considerato **Attivo** se si verifica almeno una delle seguenti condizioni:
1. Ha uno stream HTTP Server-Sent Events (`/api/stream/{job_id}`) aperto e in ascolto.
2. Ha effettuato un'interazione HTTP o inviato un segnale di Heartbeat (`POST /api/heartbeat`) negli ultimi $10.0$ secondi (`sessions[session_id] >= now - 10.0`).

#### Algoritmo di Spegnimento Automatico (*Graceful Shutdown*)
Per evitare che il server Python rimanga in esecuzione indefinitamente in background alla chiusura del browser, l'Adapter esegue un task asincrono permanente (`graceful_shutdown_checker`).

Il server si arresta automaticamente inviando un segnale `SIGINT` a se stesso se e solo se è soddisfatta la seguente equazione logico-temporale:

$$\text{server\_has\_seen\_first\_client} == \text{True} \quad \land \quad \text{Active Clients} == 0 \quad \land \quad \text{Active Jobs} == 0 \quad \land \quad (\text{now} - \text{grace\_started\_at}) \ge 15.0\text{s}$$

*Nota Ingegneristica*: L'indicatore `server_has_seen_first_client` previene lo spegnimento precoce del server durante la fase di avvio (bootstrap), garantendo all'utente il tempo necessario per completare il primo reindirizzamento d'autenticazione.

### Gestione dei Sottoprocessi e Pulizia Cross-Platform

La cancellazione di un Job (`cancel_job_process`) è un'interruzione di processo deterministica e **non un rollback transazionale**. Se il core ha già committato una riga NDJSON prima della ricezione del segnale, la riga rimane autorevole nel dominio.

#### Algoritmo di Terminazione Process Tree
1. **Piattaforme POSIX (Linux, macOS, WSL, Termux)**:
   * L'Adapter invia il segnale `signal.SIGTERM` al PID del sottoprocesso (`os.kill(job.process_pid, signal.SIGTERM)`).
   * L'Adapter imposta `job.termination_cause = TerminationCause.SIGTERM` e attende in un ciclo non bloccante fino a un massimo di $5.0$ secondi (`CANCELLATION_TERMINATION_TIMEOUT`).
   * Se il processo non si arresta entro $5.0$ secondi, l'Adapter forza l'arresto inviando `signal.SIGKILL` e aggiorna `job.termination_cause = TerminationCause.SIGKILL`.

2. **Piattaforme Windows (Git Bash / MSYS2)**:
   * L'Adapter esegue in modo asincrono l'utility nativa di sistema:
     ```cmd
     taskkill /F /T /PID <process_pid>
     ```
   * Questo garantisce l'abbattimento forzato e ricorsivo dell'intero albero dei processi figli spawned dal guscio Bash.

## 4. Protocollo IPC e Flussaggio Dati (IPC Contract)

### Invocazione CLI Asincrona e Iniezione Prompt
L'Adapter Python invoca lo script core `bash4llm` attivando sempre la modalità streaming e la diagnostica JSON strutturata:

```python
cmd = [
    "bash", core_script_path,
    "--thread", job.thread_id,
    "--thread-window", str(job.thread_window),
    "--stream",
    "--json-diagnostics"
]
```

#### Passaggio del Prompt via `stdin` Pipe
Per prevenire rischi di sicurezza legati all'ispezione dei processi da parte di altri utenti di sistema (`ps aux`) e superare i limiti di lunghezza degli argomenti CLI (`ARG_MAX`), il prompt dell'utente viene iniettato esclusivamente tramite la pipe `stdin`:

```python
process = await asyncio.create_subprocess_exec(
    *cmd,
    stdin=asyncio.subprocess.PIPE,
    stdout=asyncio.subprocess.PIPE,
    stderr=asyncio.subprocess.PIPE,
    env=sanitized_env,
    cwd=runtime_dir
)

# Scrittura asincrona e chiusura atomica della pipe per inviare l'EOF
if process.stdin:
    process.stdin.write(job.prompt.encode('utf-8'))
    await process.stdin.drain()
    process.stdin.close()
```

### Decodifica UTF-8 e Prevenzione Deadlock Pipe OS
Per evitare il blocco del sottoprocesso causato dalla saturazione dei buffer delle pipe del sistema operativo (OS Pipe Deadlock), le pipe di `stdout` e `stderr` vengono lette in modo concorrente tramite `asyncio.gather()`:

1. **Lettura `stdout` e Flussaggio SSE**:
   I token emessi dal core vengono decodificati progressivamente mediante un decodificatore incrementale UTF-8 (`codecs.getincrementaldecoder('utf-8')(errors='replace')`), accumulati nel buffer di memoria RAM del Job e trasmessi istantaneamente sulla coda SSE del client:
   ```text
   id: 1
   event: token
   data: {"delta": "Ciao"}

   id: 2
   event: token
   data: {"delta": "!"}
   ```

2. **Lettura `stderr` e Parsing Diagnostico (Zero Regex)**:
   La diagnostica di errore si basa **esclusivamente** sul parsing di righe JSON valide emesse da `bash4llm` tramite la funzione `emit_json_diagnostics`. È vietato qualsiasi uso di espressioni regolari euristiche su testo libero per dedurre gli errori del core:
   ```json
   {"bash4llm_status":"ERROR","code":10,"reason":"NO_API_KEY","message":"GROQ_API_KEY is not set","timestamp":"2026-08-10T17:00:00Z"}
   ```

### Risoluzione NDJSON a 2 Livelli (`GET /api/threads/{id}`)
Per servire la cronologia dei messaggi di conversazione senza eseguire sottoprocessi overhead, l'Adapter applica una lettura ad alte prestazioni in **Sola Lettura (Read-Only)** a due livelli:

1. **Validazione Sintattica**: Verificato l'ID della conversazione tramite la regex `^[A-Za-z0-9._-]{1,128}$`.
2. **Ricerca di Livello 1 (Digest SHA-256)**: Calcolo dell'hash nativo `sha256_hex = hashlib.sha256(thread_id.encode('utf-8')).hexdigest()`. Tenta l'apertura del file:
   $$\text{bash4llm.d/history/threads/}\{\text{sha256\_hex}\}\text{.ndjson}$$
3. **Ricerca di Livello 2 (Fallback Retrocompatibile)**: Se il file sopra non esiste, tenta l'apertura del file con ID in chiaro:
   $$\text{bash4llm.d/history/threads/}\{\text{thread\_id}\}\text{.ndjson}$$
4. Se entrambi i file non esistono, l'Adapter restituisce un array vuoto `[]`.

### Trattamento di `ui_state/last_api.json`
I file presenti sotto la directory `ui_state/` rappresentano un **Read-Model derivato non transazionale** (*Best-Effort Non-Transactional Projection*, Invariante 9). L'Adapter lega i metadati dell'ultima chiamata API (stato HTTP, motivo di completamento `finish_reason`, ID richiesta) all'oggetto Job. In caso di discrepanze temporali o di concorrenza, tali metadati vengono marcati `"metadata_verified": false` o omessi.

### Ricostruzione dell'Indice dei Thread (Invariante 10)
Se il file d'indice `ui_state/threads/index.json` non è presente o risulta sintatticamente corrotto/non valido:
1. L'Adapter esegue una scansione in sola lettura dei soli nomi file presenti nella directory `history/threads/*.ndjson`.
2. Per ciascun thread individuato, l'Adapter invoca la CLI del core:
   ```bash
   bash4llm --init-thread --thread <thread_id>
   ```
3. L'Adapter delega unicamente al core Bash la rigenerazione atomica dell'indice su filesystem.

---

## 5. Modello di Sicurezza e Protezione Rotte

### Architettura di Sicurezza Ad Albero

```text
[Richiesta HTTP GET / o POST /api/chat]
        │
        ├── 1. Host Validation (Allowlist: 127.0.0.1, localhost, [::1])
        │
        ├── 2. Primary Origin Validation (Origin deve corrispondere a http://127.0.0.1:PORT)
        │
        ├── 3. Session Cookie Check (Cookie HttpOnly: session_id)
        │        │
        │        ├── Assente/Invalido su GET / o GET /index.html ──> Return HTTP 401 (error.html)
        │        └── Assente/Invalido su API Mutative ───────────> Return HTTP 401 (JSON)
        │
        ├── 4. Anti-CSRF Token Header Check (X-CSRF-Token per POST, PATCH, DELETE)
        │
        ├── 5. Job Ownership Check (Proprietà legata a owner_session_id)
        │
        └── 6. Fingerprinted Ephemeral Idempotency Check (SHA-256 Payload Fingerprint)
                 ├── Key preesistente + Stesso Fingerprint SHA-256 ──> Return 202 Accepted (Job esistente)
                 ├── Key preesistente + Fingerprint DIVERSO ──────────> Return HTTP 409 Conflict
                 └── Nuova Key ───────────────────────────────────────> Alloca ed esegue nuovo Job
```

### Meccanismi di Protezione Specifici

* **Loopback Binding Esclusivo**: Il server Uvicorn è vincolato esclusivamente agli indirizzi di loopback locale (`127.0.0.1` o `[::1]`). Binding su `0.0.0.0` severamente vietato.
* **Protezione delle Rotte e dell'HTML**:
  * Un middleware intercetta le richieste verso `/` e `/index.html`.
  * Se la richiesta è priva di un cookie di sessione valido `session_id`, il server respinge l'accesso con `HTTP 401 Unauthorized` servendo il template d'errore minimale `static/error.html`.
* **Single-Instance Advisory Lock**:
  * **POSIX**: `fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)` sul file `gui_adapter.lock`.
  * **Windows**: `msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)` dopo scrittura di un byte iniziale nel file.
  * Il kernel OS rilascia automaticamente il lock alla chiusura o crash del processo, eliminando il rischio di *stale lock file*.
* **Cookie & Anti-CSRF**:
  * Cookie di sessione: `Set-Cookie: session_id=...; HttpOnly; SameSite=Strict; Path=/`.
  * Token CSRF: Generato in RAM (`secrets.token_hex(32)`), restituito nel payload di `/api/status` e richiesto nell'header `X-CSRF-Token` per tutte le operazioni mutative (`POST`, `PATCH`, `DELETE`).
* **Bootstrap Token Monouso**:
  * All'avvio viene generato `active_one_time_token = secrets.token_hex(32)`.
  * L'endpoint `/auth?one_time_token=XYZ` valida il token, lo consuma atomicamente (impostandolo a `None` in RAM per impedire il riuso), rilascia il cookie di sessione ed esegue un `HTTP 302 Redirect` alla radice `/`.

---

## 6. Referenza API REST e SSE (OpenAPI 3.1.0 Compatible)

### Matrice delle Interfacce API

| Endpoint | Metodo | Headers Obbligatori | Input Body / Query | Status & Payload di Risposta | Descrizione & Operazione Core Mappata |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `/auth` | `GET` | - | `?one_time_token=...` | `302 Redirect /` | Consuma token monouso, imposta Cookie `session_id`. |
| `/api/status` | `GET` | Cookie Session | - | `200 OK`<br>`{"server":"READY","active_clients":1,"active_jobs":0,"csrf_token":"..."}` | Aggiorna `last_seen`, ritorna stato runtime e CSRF token. |
| `/api/heartbeat`| `POST`| Cookie Session | - | `200 OK`<br>`{"status":"ok"}` | Aggiorna il timestamp di presenza client per evitare lo shutdown. |
| `/api/models` | `GET` | Cookie Session | - | `200 OK`<br>`{"models":["model1","model2"]}` | Invocazione CLI `bash4llm --list-models-raw`. |
| `/api/models/refresh`| `POST`| `X-CSRF-Token` | - | `200 OK`<br>`{"status":"refreshed"}` | Invocazione CLI remota `bash4llm --refresh-models`. |
| `/api/providers`| `GET` | Cookie Session | - | `200 OK`<br>`{"providers":["groq","gemini"]}` | Invocazione CLI `bash4llm --list-providers-raw`. |
| `/api/threads` | `GET` | Cookie Session | - | `200 OK`<br>`{"threads":["default","t1"]}` | Legge `ui_state/threads/index.json` (con rebuild via CLI se corrotto). |
| `/api/threads/{id}`|`GET`| Cookie Session | - | `200 OK`<br>`{"thread_id":"...","messages":[]}` | Validazione ID ed estrazione Read-Only da file NDJSON. |
| `/api/threads/{id}`|`DELETE`| `X-CSRF-Token` | - | `200 OK`<br>`{"status":"deleted"}` | Invocazione CLI `bash4llm --delete-thread {id}`. |
| `/api/threads/{id}`|`PATCH` | `X-CSRF-Token` | `{"title": "..."}` | `200 OK`<br>`{"status":"renamed"}` | Invocazione CLI `bash4llm --rename-thread {id} --title "..."`. |
| `/api/chat` | `POST` | `X-CSRF-Token`<br>`Idempotency-Key`| `ChatRequest` JSON | `202 Accepted` / `409 Conflict`<br>`{"job_id":"job_a1...","state":"STARTING"}` | Valida idempotenza+fingerprint SHA-256 per sessione, alloca `job_id`, ed esegue il subprocess. |
| `/api/jobs/{id}`| `GET` | Cookie Session | - | `200 OK`<br>`{"job_id":"...","state":"RUNNING"}` | Verifica stato del Job (limitato alla sessione proprietaria). |
| `/api/jobs/{id}/cancel`|`POST`| `X-CSRF-Token` | - | `200 OK`<br>`{"status":"cancel_requested"}` | Imposta `CANCEL_REQUESTED`, interrompe il processo e verifica exit. |
| `/api/stream/{job}`|`GET`| Cookie Session | - | `200 OK` (`text/event-stream`) | Subscription SSE al `job_id` (limitato alla sessione proprietaria). |

### Semantica dell'Esito `HTTP 202 Accepted`
La risposta `HTTP 202 Accepted` restituita dall'endpoint `POST /api/chat` indica unicamente che la richiesta è stata validata sintatticamente e l'oggetto `Job` è stato **allocato nel runtime dell'Adapter**. Gli eventuali errori di esecuzione dello script Bash o dell'API remota (codici di errore $10\div17$) vengono veicolati in modo asincrono all'interno dello stream SSE e nell'oggetto Job interrogabile via `GET /api/jobs/{id}`.

---

## 7. Matrice di Compatibilità Cross-Platform & Resilience

### Matrice di Portabilità

| Piattaforma Target | Requisito Bash Core | Python Engine | OS Lock & Tree Termination Method | Note Ingegneristiche & Dipendenze |
| :--- | :--- | :--- | :--- | :--- |
| **Linux (Generic)** | Bash >= 4.0 | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Supporto nativo completo. Validazione UID e permessi `0700` su `BASH4LLM_TMPDIR`. |
| **macOS (Darwin)** | Bash >= 4.0 | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Utility BSD. Azzerata qualsiasi dipendenza da `stdbuf`. |
| **WSL (Microsoft)** | Bash >= 4.0 | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Comportamento equivalente a Linux nativo. |
| **Android (Termux)** | Termux Bash (4.0+) | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Apertura browser con `termux-open-url`. Auto-reconnect JS su Doze Mode. |
| **Windows (Git Bash / MSYS2)**| Bash >= 4.0 (Git Bash) | Python Windows | `msvcrt.locking` \| `taskkill /F /T /PID` | Inizializzazione a 1 byte del file di lock. Normalizzazione minuscola dei percorsi temporanei. |

### Resilienza Mobile & Termux (Android Doze Mode)

Sui dispositivi mobili basati su Android/Termux, i meccanismi di risparmio energetico (*Doze Mode*) o le politiche aggressive degli OEM possono sospendere temporaneamente il processo browser o interrompere la connessione TCP della socket SSE.

Per garantire la massima resilienza:
1. **Pipelining Asincrono Indipendente**: Il sottoprocesso Bash continua l'esecuzione e la scrittura dei token sul file NDJSON anche se il client web si disconnette dallo stream SSE (Invariante 4).
2. **Auto-Reconnect EventSource**: Il client JavaScript Vanilla (`app.js`) gestisce il gestore d'errore `eventSource.onerror`. In caso di disconnessione, il client tenta la riconnessione automatica verso `/api/stream/{job_id}`.
3. **Flussaggio Heartbeat SSE**: Il generatore asincrono dell'endpoint `/api/stream/{job_id}` invia un commento di heartbeat (`: heartbeat\n\n`) ogni 15 secondi di inattività per impedire la chiusura della socket da parte dei middlebox di rete o dei gateway mobil-data.
