[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
## Session Engine [🇮🇹](#-sezione-italiana)   [🇬🇧](#-english-section)

### 🇮🇹 Sezione Italiana

# 🗃️ Session Engine (extra opzionale per GroqBash)

Il *Session Engine* è un componente **opzionale** che estende le funzionalità di session management del CORE di GroqBash.  
Non sostituisce le primitive MVP (`session_read_window`, `session_append`, cache), ma le **potenzia** con segmentazione, rotazione, deduplicazione, caching avanzato e snapshot diagnostici.

È progettato per essere **sicuro**, **deterministico**, **auditabile** e completamente confinato in `GROQBASH_HISTORY_DIR` e `RUN_TMPDIR`.

---

## 🎯 Obiettivi del Session Engine

- Gestire sessioni lunghe senza degradazione delle prestazioni.
- Ridurre la dimensione dei file di sessione tramite segmentazione e rotazione.
- Evitare duplicati e rumore nei messaggi.
- Costruire finestre di contesto ottimizzate per i modelli LLM.
- Fornire snapshot diagnostici completi.
- Garantire atomicità, idempotenza e sicurezza dei dati.

---

# ⚙️ Funzionalità principali

## 1. **Segmentazione e Rotazione Automatica**
- Ogni sessione inizia con un file base:  
  `sessions/<sid>.ndjson`
- Quando supera `GROQBASH_SESSION_SEGMENT_MAX_BYTES`, viene ruotato in:  
  `sessions/<sid>.NNN.ndjson`
- La rotazione avviene **sotto lock**, garantendo assenza di corruzione.
- I segmenti più vecchi possono essere compressi (opzionale).

**Benefici:**  
- Nessun file cresce indefinitamente.  
- Accesso rapido alle parti recenti della sessione.  

---

## 2. **Append Sicuro e Idempotente**
`session_engine_append`:

- Scrive un nuovo record NDJSON con:
  - timestamp UTC
  - ruolo
  - contenuto
  - hash
  - meta JSON
- Usa:
  - **lock esclusivo**
  - **marker di idempotenza** basato su `message_id`
  - **permessi 600**
  - **dedup opzionale** (evita ripetizioni ravvicinate)

**Garantisce:**  
- Nessun doppio append  
- Nessuna perdita dati  
- Nessuna race condition  

---

## 3. **Costruzione della Finestra di Contesto**
`session_engine_build_window`:

Due modalità:

### **A) Override esplicito: N messaggi**
Se `N > 0`:
- Recupera gli ultimi N messaggi reali (escludendo `meta.ignored`)
- Attraversa tutti i segmenti, dal più recente al più vecchio
- Mantiene l’ordine cronologico corretto

### **B) Modalità intelligente (target_bytes)**
Se `N = 0`:
- Costruisce una finestra ottimizzata rispettando:
  - `GROQBASH_SESSION_TARGET_BYTES`
  - `GROQBASH_SESSION_MIN_MESSAGES`
  - `GROQBASH_SESSION_MAX_MESSAGES`
- Pesa i messaggi (role+content)
- Esclude quelli marcati come `ignored`

### **Caching in-process**
- Cache per chiave: `sid|params_hash`
- TTL configurabile
- Invalidate automatica dopo ogni append

---

## 4. **Snapshot Diagnostico Completo**
`session_engine_snapshot` produce un JSON con:

- numero totale di messaggi
- numero di segmenti
- dimensione totale
- ultime 50 righe della sessione
- eventuali messaggi marcati come `summary:true`

Perfetto per debugging, audit e strumenti esterni.

---

## 5. **Sicurezza e Invarianti**
Il Session Engine garantisce:

- **Nessun uso di `/tmp` di sistema**  
  Tutti i file temporanei sono in `RUN_TMPDIR` con permessi 600.

- **Nessun uso di `eval`**  
  Nessuna esecuzione dinamica di codice.

- **Atomicità totale**  
  Tutte le scritture sono protette da lock o `mv` atomici.

- **Idempotenza**  
  Marker basati su `message_id` impediscono duplicazioni.

- **Validazione session_id**  
  Se il CORE espone `session_validate_id`, viene usata automaticamente.

---

# 🧩 API pubbliche

### `session_engine_enabled`
Determina se l’engine può essere usato.  
Controlla:
- variabile `GROQBASH_SESSION_ENGINE`
- esistenza e scrivibilità di `SE_SESSION_DIR`
- disponibilità di `RUN_TMPDIR`

---

### `session_engine_append <sid> <role> <content> <meta_json>`
Aggiunge un messaggio alla sessione in modo sicuro e idempotente.

---

### `session_engine_build_window <sid> <N> <target_bytes> <out_file>`
Costruisce la finestra di contesto per il modello.

---

### `session_engine_snapshot <sid> <out_file>`
Genera un report diagnostico completo.

---

# 🧭 Come si usa

## 1. Installazione dell’extra
Il file deve trovarsi in:
```
$GROQBASH_EXTRAS_DIR/session/session-engine.sh
```

## 2. Attivazione
Nel tuo script principale:
```sh
if session_engine_enabled; then
    session_engine_append ...
    session_engine_build_window ...
else
    # fallback al CORE/MVP
fi
```

## 3. Configurazione (opzionale)
Variabili principali:

- `GROQBASH_SESSION_ENGINE=on|off`
- `GROQBASH_SESSION_SEGMENT_MAX_BYTES`
- `GROQBASH_SESSION_SEGMENT_MAX_FILES`
- `GROQBASH_SESSION_DEDUP_ENABLED`
- `SESSION_CACHE_ENABLED`
- `SESSION_CACHE_TTL_SEC`

---

# 📌 Quando usarlo

Usa il Session Engine quando:

- vuoi sessioni lunghe senza rallentamenti
- vuoi finestre di contesto ottimizzate
- vuoi dedup e pulizia automatica
- vuoi snapshot diagnostici
- vuoi rotazione e compressione dei segmenti

Se non installato o disabilitato, GroqBash usa automaticamente il CORE/MVP.

---

### 🇬🇧 English section

# 🗃️ Session Engine (optional extra for GroqBash)

The *Session Engine* is an **optional** component that extends the session‑management capabilities of the GroqBash CORE.  
It does **not** replace the MVP primitives (`session_read_window`, `session_append`, cache); instead, it **enhances** them with segmentation, rotation, deduplication, advanced caching, and diagnostic snapshots.

It is designed to be **safe**, **deterministic**, **auditable**, and fully confined within `GROQBASH_HISTORY_DIR` and `RUN_TMPDIR`.

---

## 🎯 Goals of the Session Engine

- Handle long‑running sessions without performance degradation.
- Reduce session file size through segmentation and rotation.
- Avoid duplicate or noisy messages.
- Build optimized context windows for LLM models.
- Provide complete diagnostic snapshots.
- Guarantee atomicity, idempotence, and data safety.

---

# ⚙️ Key Features

## 1. **Automatic Segmentation and Rotation**
- Each session starts with a base file:  
  `sessions/<sid>.ndjson`
- When it exceeds `GROQBASH_SESSION_SEGMENT_MAX_BYTES`, it is rotated into:  
  `sessions/<sid>.NNN.ndjson`
- Rotation happens **under lock**, ensuring no corruption.
- Older segments may be compressed (optional).

**Benefits:**  
- No file grows indefinitely.  
- Fast access to the most recent session data.  

---

## 2. **Safe and Idempotent Append**
`session_engine_append`:

- Writes a new NDJSON record containing:
  - UTC timestamp  
  - role  
  - content  
  - hash  
  - meta JSON  
- Uses:
  - **exclusive locking**
  - **idempotency markers** based on `message_id`
  - **600 permissions**
  - **optional dedup** (prevents near‑duplicate messages)

**Guarantees:**  
- No double‑append  
- No data loss  
- No race conditions  

---

## 3. **Context Window Construction**
`session_engine_build_window` supports two modes:

### **A) Explicit override: N messages**
If `N > 0`:
- Retrieves the last N real messages (excluding `meta.ignored`)
- Walks all segments from newest to oldest
- Restores correct chronological order

### **B) Smart mode (target_bytes)**
If `N = 0`:
- Builds an optimized window respecting:
  - `GROQBASH_SESSION_TARGET_BYTES`
  - `GROQBASH_SESSION_MIN_MESSAGES`
  - `GROQBASH_SESSION_MAX_MESSAGES`
- Weighs messages (role + content)
- Excludes those marked as `ignored`

### **In‑process caching**
- Cache key: `sid|params_hash`
- Configurable TTL
- Automatically invalidated after each append

---

## 4. **Complete Diagnostic Snapshot**
`session_engine_snapshot` produces a JSON report containing:

- total number of messages  
- number of segments  
- total size  
- last 50 lines of the session  
- any messages marked with `summary:true`  

Ideal for debugging, auditing, and external tools.

---

## 5. **Safety and Invariants**
The Session Engine guarantees:

- **No use of system `/tmp`**  
  All temporary files live in `RUN_TMPDIR` with 600 permissions.

- **No use of `eval`**  
  No dynamic code execution.

- **Full atomicity**  
  All writes are protected by locks or atomic `mv`.

- **Idempotency**  
  `message_id`‑based markers prevent duplicates.

- **Session ID validation**  
  If the CORE exposes `session_validate_id`, it is used automatically.

---

# 🧩 Public API

## `session_engine_enabled`
Determines whether the engine can be used.  
Checks:
- `GROQBASH_SESSION_ENGINE` variable  
- existence and writability of `SE_SESSION_DIR`  
- availability of `RUN_TMPDIR`  

---

## `session_engine_append <sid> <role> <content> <meta_json>`
Safely and idempotently appends a message to the session.

---

## `session_engine_build_window <sid> <N> <target_bytes> <out_file>`
Builds the context window for the model.

---

## `session_engine_snapshot <sid> <out_file>`
Generates a complete diagnostic report.

---

# 🧭 Usage

## 1. Installing the extra
The file must be located at:
```
$GROQBASH_EXTRAS_DIR/session/session-engine.sh
```

## 2. Enabling it
In your main script:
```sh
if session_engine_enabled; then
    session_engine_append ...
    session_engine_build_window ...
else
    # fallback to CORE/MVP
fi
```

## 3. Optional configuration
Main variables:

- `GROQBASH_SESSION_ENGINE=on|off`
- `GROQBASH_SESSION_SEGMENT_MAX_BYTES`
- `GROQBASH_SESSION_SEGMENT_MAX_FILES`
- `GROQBASH_SESSION_DEDUP_ENABLED`
- `SESSION_CACHE_ENABLED`
- `SESSION_CACHE_TTL_SEC`

---

# 📌 When to Use It

Use the Session Engine when:

- you need long sessions without slowdown  
- you want optimized context windows  
- you want automatic dedup and noise filtering  
- you want diagnostic snapshots  
- you want segment rotation and optional compression  

If not installed or disabled, GroqBash automatically falls back to the CORE/MVP.
