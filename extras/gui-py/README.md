[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

[![WebApp](https://img.shields.io/badge/GUI--WebApp-Python--3.10+-007acc?style=flat-square&logo=python&logoColor=white)](#)

# DOCUMENTAZIONE TECNICA ED OPERATIVA INTEGRATA 🇮🇹 [🇬🇧](README-en.md)
## Modulo GUI WebApp `gui-py` per `bash4llm⁺` (v4.4)
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
   * **Runtime-Stateful**: L'Adapter gestisce in memoria RAM effimera un registro dei Job attivi (`jobs_registry`), i gestori dei sottoprocessi (`process_pid`), le code dei token Server-Sent Events (`job_queues`), le sessioni client attive (`sessions`) e la tabella di idempotenza temporanea (`idempotency_store`).

3. ***Zero Credential Mirroring***:
   * Python non memorizza, estrae né manipola le credenziali degli LLM o la master password del Vault in chiaro su disco.
   * L'autenticazione verso i provider viene delegata al core `bash4llm` tramite variabili d'ambiente di processo isolate o tramite il meccanismo di Vault nativo dello script Bash (`_B4L_RT_CTX`).

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

* **Divieto di Automatismi (Zero-Automatisms Policy)**: Lo script launcher `gui-py.sh` non installa automaticamente pacchetti né crea virtualenv senza autorizzazione esplicita. In caso di dipendenze mancanti, l'avvio si interrompe con exit code 15 fornendo le istruzioni esatte per l'installazione manuale.

#### Esempi di Installazione Dipendenze:

**Debian / Ubuntu (con apt e pip)**
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

Questo comando copia l'alberatura in `bash4llm.d/extras/gui-py/` applicando i permessi restrittivi `0700` per le directory e `0600` per i file (`0700` per `gui-py.sh`).

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
  Lo script wrapper sanifica l'ambiente, valida la presenza di Python >= 3.10 e dei moduli richiesti, acquisisce l'Advisory Lock kernel su `gui_adapter.lock` tramite `fcntl.flock`, alloca la prima porta di loopback libera (intervallo `19970-20069`) e apre automaticamente l'URL di autenticazione nel browser predefinito via `webbrowser.open()`.

* **Windows (Git Bash / MSYS2)**:
  ```bash
  ./bash4llm --gui
  ```
  Lo script rileva l'ambiente Windows, gestisce l'Advisory Lock via `msvcrt.locking` con inizializzazione a 1 byte e valida che la directory temporanea isolata runtime sia accessibile in scrittura.

* **Android (Termux)**:
  ```bash
  ./bash4llm --gui
  ```
  Il server rileva automaticamente l'ambiente Termux (`IS_TERMUX`) e disabilita l'apertura automatica del browser (`webbrowser.open`), stampando a video l'URL completo con il One-Time Token per consentire all'utente di copiarlo o aprirlo con il browser preferito.

---

### 🌐 Manuale d'Uso della GUI WebApp

1. **Autenticazione Iniziale (One-Time Token)**:
   All'avvio viene generato un `one_time_token` crittografico a 64 caratteri hex. Il browser viene indirizzato su:
   `http://127.0.0.1:19970/auth?one_time_token=...`
   Il token viene consumato atomicamente in RAM al primo accesso e viene rilasciato un cookie di sessione sicuro `HttpOnly` con flag `SameSite=Strict`.

2. **Navigazione Thread (Sidebar Sinistra)**:
   * **+ Nuova Chat (+ New Thread)**: Inizializza un nuovo contesto di conversazione.
   * **Elenco Thread**: Visualizza le conversazioni attive. Cliccando su un thread, la cronologia dei messaggi viene caricata in sola lettura dai file `.ndjson`.
   * **🗑️ Elimina (Delete)**: Elimina definitivamente il thread selezionato o azzera la cronologia della chat predefinita.
   * **Ridenominazione**: Possibilità di rinominare il titolo del thread (aggiornato tramite `PATCH /api/threads/{id}`).
   * **📊 Statistiche (Stats)**: Visualizza il conteggio messaggi, i segmenti di sessione e l'utilizzo cumulativo di byte (`GET /api/threads/{id}/snapshot`).

3. **Invio Prompt e Streaming in Tempo Reale**:
   * Digitare la richiesta nell'area di testo e premere **"Invia"** (o `Invio`).
   * La risposta dell'LLM viene flussata in tempo reale token per token via Server-Sent Events (SSE).
   * **Stream Toggle**: Permette di disabilitare lo streaming per ricevere la risposta completa in un singolo blocco.

4. **Interruzione Immediata (Pulsante Stop)**:
   Durante la generazione, il pulsante d'invio si trasforma in **"Stop"**. Cliccandolo, l'Adapter inoltra una richiesta `POST /api/jobs/{id}/cancel` arrestando il sottoprocesso con segnale di terminazione immediata (`SIGTERM`/`SIGKILL` su POSIX o `taskkill` su Windows), senza corrompere la cronologia pregressa.

5. **Allegati di Contesto (📎 Attach)**:
   Consente di caricare uno o più file di testo/contesto. Il backend salva il file in `$BASH4LLM_TMPDIR/gui_uploads/` con permessi `0600` e lo inoltra al core `bash4llm` tramite il parametro `-f`.

6. **Template di Prompt (Templates)**:
   Permette di selezionare e applicare uno dei template testuali archiviati nella cartella `templates/` del progetto.

7. **SML Gate (Safety Validation)**:
   Abilita la validazione semantica obbligatoria dello schema Structured Metadata Layout (presenza dei blocchi `LISTEN_SUMMARY` e `CONVERSATION_OUTCOME`). Se il modello non rispetta lo schema, la risposta viene contrassegnata come non verificata.

8. **Sanificazione Output (Sanitize)**:
   Rimuove automaticamente le sequenze di escape ANSI dei colori terminale e i caratteri di controllo non stampabili dalla risposta.

9. **Gestione OpenSSL Key Vault (🔒 Vault)**:
   Apre la finestra modale per gestire le chiavi API crittografate con cifratura locale AES-256:
   * **Sblocco Vault**: Autenticazione con Master Password in memoria RAM (`_B4L_RT_CTX`).
   * **Salvataggio Chiavi**: Memorizzazione sicura di nuove API key per ciascun provider supportato.

10. **Pannello Impostazioni (⚙️ Settings)**:
    * **Provider & Modello**: Selezione del backend LLM attivo e del modello.
    * **Imposta Predefinito (Set Default)**: Salva il modello preferito per il provider attivo (`POST /api/models/default`).
    * **🔄 Aggiorna Modelli**: Interroga l'API del provider per risincronizzare il catalogo modelli (`POST /api/models/refresh`).
    * **Parametri di Generazione**: Regolazione di Prompt di Sistema, Temperatura (0.0 - 2.0) e Token Massimi (1 - 128000).
    * **Strategia Contesto**: Scelta tra finestra a conteggio messaggi (`thread_window`, 0-100) o limite a budget di byte (`target_bytes`).

11. **Arresto Pulito del Server (🛑 Stop Server)**:
    Invia la richiesta `POST /api/shutdown`, arrestando in modo controllato il processo backend Python.

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
│   ├── help.html     # Guida comandi e documentazione integrata multilingue
│   ├── error.html    # Template d'errore HTTP 401/403/500 minimale
│   ├── style.css     # Design UI responsive zero-framework
│   └── app.js        # SSE Streamer, CSRF Fetch, Form Enhancements
└── langs/            # Traduzioni multilingue
    ├── de.json       # Tedesco
    ├── en.json       # Inglese
    ├── es.json       # Spagnolo
    ├── fr.json       # Francese
    └── it.json       # Italiano
```

### Ciclo di Vita del Job (`JobState`)

Ogni richiesta di generazione inviata alla WebApp viene incapsulata in un oggetto `Job` gestito in memoria RAM dall'Adapter Python.

```
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
* **`STARTING`**: L'Adapter ha preparato la lista esplicita degli argomenti CLI e l'ambiente sanificato, e avvia il sottoprocesso via `asyncio.create_subprocess_exec`.
* **`RUNNING`**: Il processo `bash4llm` è attivo (`process.pid` assegnato). Il prompt utente viene inviato mediante scrittura asincrona sulla pipe `stdin`.
* **`STREAMING`**: I token generati da `bash4llm` vengono letti da `stdout` mediante `codecs.getincrementaldecoder('utf-8')` e trasmessi al client via SSE.
* **`CANCEL_REQUESTED`**: È stata ricevuta una richiesta `POST /api/jobs/{job_id}/cancel`. L'Adapter ha avviato la procedura di terminazione dell'albero dei processi.
* **`CANCELLED`**: Il processo `bash4llm` è stato terminato con successo da segnale di sistema (`SIGTERM` o `SIGKILL`). Il campo `termination_cause` viene valorizzato.
* **`COMPLETED`**: Il processo `bash4llm` è uscito spontaneamente con exit code `0`. La risposta completa è memorizzata nel buffer di RAM `prompt_response`.
* **`FAILED`**: Il processo è uscito con exit code non-zero oppure il core ha emesso un errore di diagnostica JSON su `stderr` (`core_error_code` $10\div17$).

### Gestione Multi-Tab, Active Clients & Memoria RAM

L'Adapter gestisce la presenza simultanea di più schede o browser connessi tramite il tracciamento dinamico delle sessioni.

#### Definizione Formale di *Active Client*
Un client è considerato **Attivo** se si verifica almeno una delle seguenti condizioni:
1. Ha uno stream HTTP Server-Sent Events (`/api/stream/{job_id}`) aperto e in ascolto.
2. Ha effettuato un'interazione HTTP o inviato un segnale di Heartbeat (`POST /api/heartbeat`) negli ultimi **60.0 secondi** (`sessions[session_id] >= now - 60.0`).

#### Algoritmo di Spegnimento Automatico (*Graceful Shutdown*)
Per evitare che il server Python rimanga in esecuzione indefinita in background alla chiusura del browser, l'Adapter esegue un task asincrono permanente (`graceful_shutdown_checker`).

Il server si arresta automaticamente inviando un segnale `SIGINT` a se stesso se e solo se è soddisfatta la seguente equazione logico-temporale:

$$\text{server\_has\_seen\_first\_client} == \text{True} \quad \land \quad \text{Active Clients} == 0 \quad \land \quad \text{Active Jobs} == 0 \quad \land \quad (\text{now} - \text{grace\_started\_at}) \ge 120.0\text{s}$$

#### Garbage Collection della Memoria RAM
La funzione `prune_expired_memory_records()` viene eseguita periodicamente per prevenire la crescita incontrollata della RAM:
* I job completati con età superiore a 2 ore ($TTL = 7200.0\text{s}$) vengono rimossi dalla memoria.
* Se il registro supera i 200 record totali, i job inattivi più vecchi vengono rimossi forzatamente salvaguardando i job in esecuzione.

---

### Gestione dei Sottoprocessi e Pulizia Cross-Platform

La cancellazione di un Job (`cancel_job_process`) è un'interruzione di processo deterministica e **non un rollback transazionale**. Se il core ha già committato una riga NDJSON prima della ricezione del segnale, la riga rimane persistita.

#### Algoritmo di Terminazione Process Tree
1. **Piattaforme POSIX (Linux, macOS, WSL, Termux)**:
   * L'Adapter invia il segnale `signal.SIGTERM` al PID del sottoprocesso (`os.kill(job.process_pid, signal.SIGTERM)`).
   * L'Adapter imposta `job.termination_cause = TerminationCause.SIGTERM` e attende in un ciclo non bloccante fino a un massimo di $5.0$ secondi (50 iterazioni da 100ms).
   * Se il processo non si arresta entro $5.0$ secondi, l'Adapter forza l'arresto inviando `signal.SIGKILL` e aggiorna `job.termination_cause = TerminationCause.SIGKILL`.

2. **Piattaforme Windows (Git Bash / MSYS2)**:
   * L'Adapter esegue in modo asincrono l'utility nativa di sistema:
     ```cmd
     taskkill /F /T /PID <process_pid>
     ```
   * Questo garantisce l'abbattimento forzato e ricorsivo dell'intero albero dei processi figli spawned dal guscio Bash.

---

## 4. Protocollo IPC e Flussaggio Dati (IPC Contract)

### Invocazione CLI Asincrona e Iniezione Prompt
L'Adapter Python invoca lo script core `bash4llm` assemblando dinamicamente i parametri di riga di comando:

```python
cmd = [
    "bash", core_script_path,
    "--thread", safe_thread_id,
    "--thread-window", str(job.thread_window),
    "--json-diagnostics"
]

if job.stream:
    cmd.append("--stream")
if job.provider:
    cmd.extend(["--provider", job.provider])
if job.model and job.model.lower() != "default":
    cmd.extend(["--model", job.model])
if job.system_prompt:
    cmd.extend(["--system", job.system_prompt])
if job.temperature is not None:
    cmd.extend(["--temperature", str(job.temperature)])
if job.max_tokens is not None:
    cmd.extend(["--max", str(job.max_tokens)])
if job.template:
    cmd.extend(["--template", job.template])
if job.validate_sml:
    cmd.append("--validate-sml")
if job.sanitize_output:
    cmd.append("--sanitize")
if job.attachments:
    for att_path in job.attachments:
        if os.path.isfile(att_path) and os.access(att_path, os.R_OK):
            cmd.extend(["-f", att_path])
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
    prompt_bytes = (job.prompt or "").encode('utf-8')
    process.stdin.write(prompt_bytes)
    await process.stdin.drain()
    process.stdin.close()
    await process.stdin.wait_closed()
```

### Decodifica UTF-8 e Prevenzione Deadlock Pipe OS
Per evitare il blocco del sottoprocesso causato dalla saturazione dei buffer delle pipe del sistema operativo (OS Pipe Deadlock), le pipe di `stdin`, `stdout` e `stderr` vengono processate in modo concorrente tramite `asyncio.gather()`:

1. **Lettura `stdout` e Flussaggio SSE**:
   I token emessi dal core vengono decodificati progressivamente a blocchi di 1024 byte mediante un decodificatore incrementale UTF-8 (`codecs.getincrementaldecoder('utf-8')(errors='replace')`), accumulati nel buffer di memoria RAM del Job e trasmessi istantaneamente sulla coda SSE del client:
   ```text
   id: 1
   event: token
   data: {"delta": "Ciao"}

   id: 2
   event: token
   data: {"delta": "!"}
   ```

2. **Lettura `stderr` e Parsing Diagnostico (Zero Regex)**:
   La diagnostica di errore si basa sul parsing di righe JSON valide emesse da `bash4llm` (`emit_json_diagnostics`), catturando `code`, `message` e `reason` (es. codice errore 10 mappato automaticamente su *"Vault is locked or API key missing"*):
   ```json
   {"bash4llm_status":"ERROR","code":10,"reason":"NO_API_KEY","message":"GROQ_API_KEY is not set","timestamp":"2026-08-10T17:00:00Z"}
   ```

### Risoluzione NDJSON a 2 Livelli (`GET /api/threads/{id}`)
Per servire la cronologia dei messaggi senza overhead di sottoprocessi, l'Adapter applica una scansione in **Sola Lettura (Read-Only)**:

1. **Validazione Sintattica**: Verificato l'ID della conversazione tramite la regex `^[A-Za-z0-9._-]{1,128}$`.
2. **Scansione Directory Canoniche**: Cerca sia in `history/sessions/` che in `history/threads/`.
3. **Risoluzione File**: Cerca sia il digest SHA-256 (`{sha256_hex}.ndjson`) sia l'ID in chiaro (`{thread_id}.ndjson`) inclusi i file segmentati (`{id}.*.ndjson`).
4. Se i file non esistono, l'Adapter restituisce un array vuoto `[]`.

---

## 5. Modello di Sicurezza e Protezione Rotte

### Architettura di Sicurezza Ad Albero

```
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

* **Validazione Rigorosa Tempdir (T3 Hardened)**: La funzione `validate_runtime_tmpdir` rifiuta esplicitamente percorsi di sistema condivisi (`/tmp`, `/var/tmp`, `/private/tmp`, `/private/var/tmp`, `c:\windows\temp`), impone la creazione con permessi `0700` e valida che l'UID proprietario coincida strettamente con l'utente in esecuzione (`os.geteuid()`).
* **Loopback Binding Esclusivo**: Il server Uvicorn è vincolato esclusivamente agli indirizzi di loopback locale (`127.0.0.1` o `[::1]`). Binding su `0.0.0.0` severamente vietato.
* **Single-Instance Advisory Lock**:
  * **POSIX**: `fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)` sul file `gui_adapter.lock` con permessi `0600`.
  * **Windows**: `msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)` dopo scrittura di 1 byte iniziale.
  * Il kernel OS rilascia automaticamente il lock alla chiusura o crash del processo, eliminando il rischio di lock orfani.
* **Cookie & Anti-CSRF**:
  * Cookie di sessione: `Set-Cookie: session_id=...; HttpOnly; SameSite=Strict; Path=/`.
  * Token CSRF: Generato in RAM (`secrets.token_hex(32)`), restituito nel payload di `/api/status` e validato in tempo costante (`secrets.compare_digest`) sull'header `X-CSRF-Token` per tutte le operazioni mutative (`POST`, `PUT`, `PATCH`, `DELETE`).
* **Bootstrap Token Monouso**:
  * All'avvio viene generato `active_one_time_token = secrets.token_hex(32)`.
  * L'endpoint `/auth?one_time_token=XYZ` valida il token, lo consuma atomicamente (impostandolo a `None` in RAM per impedire il riuso), rilascia il cookie di sessione ed esegue un `HTTP 302 Redirect` alla radice `/`.

---

## 6. Referenza API REST e SSE (OpenAPI 3.1.0 Compatible)

### Matrice Completa delle Interfacce API

| Endpoint | Metodo | Headers Obbligatori | Input Body / Query | Status & Payload di Risposta | Descrizione & Operazione Core Mappata |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `/auth` | `GET` | - | `?one_time_token=...` | `302 Redirect /` | Consuma token monouso, imposta Cookie `session_id`. |
| `/` / `/index.html`| `GET`| Cookie Session | - | `200 OK` (HTML) | Serve la Single Page Application (`static/index.html`). |
| `/api/status` | `GET` | Cookie Session | - | `200 OK`<br>`{"server":"READY","active_clients":1,"active_jobs":0,"csrf_token":"...","vault_unlocked":bool}` | Aggiorna `last_seen`, ritorna stato runtime, CSRF token e stato Vault. |
| `/api/heartbeat`| `POST`| Cookie Session | - | `200 OK`<br>`{"status":"ok"}` | Aggiorna il timestamp di presenza client per evitare lo shutdown. |
| `/api/shutdown` | `POST`| `X-CSRF-Token` | - | `200 OK`<br>`{"status":"shutting_down"}` | Avvia lo spegnimento pulito e controllato dell'istanza. |
| `/api/models` | `GET` | Cookie Session | `?provider=...` (opt) | `200 OK`<br>`{"models":[],"provider":"...","default_model":"..."}` | Invocazione CLI `bash4llm --provider <p> --list-models-raw`. |
| `/api/models/default`| `POST`| `X-CSRF-Token` | `{"provider":"...","model":"..."}` | `200 OK`<br>`{"status":"default_model_set"}` | Invocazione CLI `bash4llm --provider <p> --set-default <m>`. |
| `/api/models/refresh`| `POST`| `X-CSRF-Token` | `?provider=...` (opt) | `200 OK`<br>`{"status":"refreshed"}` | Invocazione CLI `bash4llm [--provider <p>] --refresh-models`. |
| `/api/providers`| `GET` | Cookie Session | - | `200 OK`<br>`{"providers":["groq","gemini",...]}` | Invocazione CLI `bash4llm --list-providers-raw`. |
| `/api/templates`| `GET` | Cookie Session | - | `200 OK`<br>`{"templates":["t1.txt",...]}` | Elenca i file template `.txt` in `$BASH4LLM_TEMPLATES_DIR`. |
| `/api/vault/status`| `GET` | Cookie Session | - | `200 OK`<br>`{"vault_exists":bool,"unlocked":bool}` | Verifica l'esistenza di `keys.enc` e lo stato di sblocco in RAM. |
| `/api/vault/keys` | `GET` | Cookie Session | - | `200 OK`<br>`{"keys":["groq","gemini",...]}` | Decifra e restituisce i provider registrati nel Vault via IPC. |
| `/api/vault/unlock`| `POST`| `X-CSRF-Token` | `{"master_password":"..."}` | `200 OK`<br>`{"status":"unlocked"}` | Sblocca o inizializza il Vault cifrato in memoria RAM (`_B4L_RT_CTX`). |
| `/api/vault/keys` | `POST`| `X-CSRF-Token` | `{"provider":"...","api_key":"..."}` | `200 OK`<br>`{"status":"key_saved"}` | Cifra e memorizza una nuova chiave provider nel Vault via IPC. |
| `/api/upload` | `POST`| `X-CSRF-Token` | `multipart/form-data` | `200 OK`<br>`{"filename":"...","file_path":"...","size":N}` | Salva allegato in `$BASH4LLM_TMPDIR/gui_uploads/` (permessi `0600`). |
| `/api/threads` | `GET` | Cookie Session | - | `200 OK`<br>`{"threads":["default","t1",...]}` | Legge la lista thread persistita in `ui_state/threads/index.json`. |
| `/api/threads` | `POST`| `X-CSRF-Token` | `{"thread_id":"..."}` | `200 OK`<br>`{"status":"created","thread_id":"..."}` | Registra un nuovo identificatore di thread nell'indice. |
| `/api/threads/{id}`| `GET` | Cookie Session | - | `200 OK`<br>`{"thread_id":"...","messages":[]}` | Estrazione messaggi in sola lettura da file NDJSON (threads e sessions). |
| `/api/threads/{id}/snapshot`| `GET` | Cookie Session | - | `200 OK`<br>`{"session_id":"...","stats":{...}}` | Estrae snapshot metriche (conteggio messaggi, segmenti, byte) via IPC. |
| `/api/threads/{id}`| `DELETE`| `X-CSRF-Token` | - | `200 OK`<br>`{"status":"deleted"}` | Invocazione CLI `bash4llm --delete-thread {id}` e pulizia file NDJSON. |
| `/api/threads/{id}`| `PATCH`| `X-CSRF-Token` | `{"title":"..."}` | `200 OK`<br>`{"status":"renamed"}` | Invocazione CLI `bash4llm --rename-thread {id} --title "..."`. |
| `/api/chat` | `POST` | `X-CSRF-Token`<br>`Idempotency-Key` (opt)| `ChatRequest` (JSON o Form) | `202 Accepted` / `409 Conflict`<br>`{"job_id":"job_...","state":"STARTING"}` | Valida idempotenza+fingerprint SHA-256, alloca `job_id`, ed esegue il subprocess. |
| `/api/jobs/{id}`| `GET` | Cookie Session | - | `200 OK`<br>`{"job_id":"...","state":"RUNNING",...}` | Verifica lo stato, i codici diagnostici e la risposta del Job. |
| `/api/jobs/{id}/cancel`| `POST`| `X-CSRF-Token` | - | `200 OK`<br>`{"status":"cancel_requested","success":bool}` | Invia richiesta di cancellazione immediata del processo (`SIGTERM`/`SIGKILL`). |
| `/api/stream/{job}`| `GET` | Cookie Session | - | `200 OK` (`text/event-stream`) | Streaming SSE token-by-token e notifica evento di chiusura `done`. |

### Semantica dell'Esito `HTTP 202 Accepted`
La risposta `HTTP 202 Accepted` restituita dall'endpoint `POST /api/chat` indica che la richiesta è stata validata sintatticamente e l'oggetto `Job` è stato **allocato nel runtime dell'Adapter**. Gli eventuali errori di esecuzione dello script Bash o dell'API remota (codici di errore $10\div17$) vengono veicolati in modo asincrono all'interno dello stream SSE (`event: done`) e nell'oggetto Job interrogabile via `GET /api/jobs/{id}`.

---

## 7. Matrice di Compatibilità Cross-Platform & Resilience

### Matrice di Portabilità

| Piattaforma Target | Requisito Bash Core | Python Engine | OS Lock & Tree Termination Method | Note Ingegneristiche & Dipendenze |
| :--- | :--- | :--- | :--- | :--- |
| **Linux (Generic)** | Bash >= 4.0 | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Supporto nativo completo. Validazione UID e permessi `0700` su `BASH4LLM_TMPDIR`. |
| **macOS (Darwin)** | Bash >= 4.0 | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Utility BSD native. Zero dipendenze da binari esterni non standard. |
| **WSL (Microsoft)** | Bash >= 4.0 | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Comportamento equivalente a Linux nativo. |
| **Android (Termux)** | Termux Bash (4.0+) | Python 3.10+ | `fcntl.flock` \| `os.kill(pid, SIGTERM)` | Auto-browser disabilitato. URL stampato a video. Auto-reconnect JS su Doze Mode. |
| **Windows (Git Bash / MSYS2)**| Bash >= 4.0 (Git Bash) | Python Windows | `msvcrt.locking` \| `taskkill /F /T /PID` | Inizializzazione a 1 byte del file di lock. Normalizzazione percorsi Windows. |

### Resilienza Mobile & Termux (Android Doze Mode)

Sui dispositivi mobili basati su Android/Termux, i meccanismi di risparmio energetico (*Doze Mode*) o le politiche aggressive del sistema operativo possono sospendere temporaneamente il processo browser o interrompere la connessione TCP della socket SSE.

Per garantire la massima resilienza:
1. **Pipelining Asincrono Indipendente**: Il sottoprocesso Bash continua l'esecuzione e la persistenza della risposta sui file NDJSON anche se il client web si disconnette dallo stream SSE.
2. **Auto-Reconnect EventSource**: Il client JavaScript Vanilla (`app.js`) intercetta `eventSource.onerror` tentando la riconnessione automatica verso `/api/stream/{job_id}`.
3. **Flussaggio Heartbeat SSE**: Il generatore asincrono dell'endpoint `/api/stream/{job_id}` invia un commento di keepalive (`: heartbeat\n\n`) ogni 15 secondi di inattività per impedire la chiusura della socket da parte dei gateway di rete.

---
