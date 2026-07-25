# Session Engine Module (`session-engine.sh`)

**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**

---

## 🇮🇹 Sezione Italiana

# Session Engine (Modulo opzionale per Bash4LLM⁺)

Il *Session Engine* è un componente opzionale che estende le funzionalità di gestione delle sessioni del CORE di Bash4LLM⁺.  
Non sostituisce le funzioni base di gestione dei thread, ma le integra con meccanismi di segmentazione dei file di storico, rotazione automatica, deduplicazione dei messaggi, caching in memoria con TTL e generazione di snapshot diagnostici.

Il modulo è progettato per operare in modo isolato, confinando tutte le scritture temporanee all'interno delle directory `BASH4LLM_HISTORY_DIR` e `RUN_TMPDIR` con permessi restrittivi.

---

## 1. Obiettivi e funzionalità

- **Gestione di sessioni estese**: Previene il degrado delle prestazioni nell'elaborazione di cronologie conversazionali di grandi dimensioni.
- **Segmentazione e rotazione dei log**: Limita la dimensione dei singoli file di storico suddividendoli in segmenti numerati al superamento della soglia di byte configurata.
- **Deduplicazione dei messaggi**: Filtra i messaggi duplicati ravvicinati per ridurre il rumore nel contesto.
- **Costruzione flessibile della finestra di contesto**: Supporta la selezione di un numero fisso $N$ di messaggi oppure il calcolo dinamico basato sul budget di byte (`target_bytes`).
- **Snapshot diagnostici**: Genera un report JSON contenente metadati statistici sulla sessione per l'ispezione ed il debugging.
- **Sicurezza e atomicità**: Tutte le operazioni di scrittura e rotazione avvengono sotto lock esclusivo (`lock_exec`) con permessi file `0600`.

---

## 2. Dettaglio delle funzionalità

### 2.1 Segmentazione e Rotazione Automatica
- Ogni sessione viene inizializzata nel file base:  
  `bash4llm.d/history/sessions/<sid>.ndjson`
- Quando la dimensione del file supera il limite `BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (default 1MB), il file viene ruotato in:  
  `bash4llm.d/history/sessions/<sid>.NNN.ndjson`
- La rotazione avviene all'interno di una sezione critica protetta da lock.
- I segmenti storici meno recenti possono essere compressi in formato `.gz` tramite `gzip`.

### 2.2 Accodamento Atomico (`session_engine_append`)
Scrive i messaggi nello storico NDJSON garantendo:
- Timestamp UTC, ruolo, contenuto, hash SHA-256 e metadati JSON.
- Verifica di idempotenza tramite marcatore `message_id`.
- Lock esclusivo prima di ogni scrittura.
- Applicazione dei permessi `0600`.

### 2.3 Costruzione della Finestra di Contesto (`session_engine_build_window`)
Supporta due modalità operative:

- **Modalità $N$ esplicito ($N > 0$)**: Estrae esattamente gli ultimi $N$ messaggi non ignorati attraversando i segmenti dal più recente al più vecchio e ricostruendo l'ordine cronologico.
- **Modalità basata su Byte-Budget ($N = 0$)**: Accumula messaggi storici fino al raggiungimento del limite `BASH4LLM_SESSION_TARGET_BYTES` rispettando i vincoli `BASH4LLM_SESSION_MIN_MESSAGES` e `BASH4LLM_SESSION_MAX_MESSAGES`.

Include un meccanismo di caching in memoria associativo (`sid|params_hash`) con TTL configurabile, invalidato automaticamente a ogni nuovo inserimento.

### 2.4 Snapshot Diagnostico (`session_engine_snapshot`)
Esporta un report JSON con le seguenti informazioni:
- Numero totale dei messaggi e dei segmenti.
- Dimensione complessiva in byte della sessione.
- Ultime 50 righe di storico ed eventuali messaggi di riassunto (`summary: true`).

---

## 3. Invarianti di Sicurezza

- **Isolamento temporaneo**: Nessun uso della directory condivisa `/tmp`. Tutti i file temporanei risiedono in `RUN_TMPDIR` con permessi `0600`/`0700`.
- **Zero Eval**: Nessun uso del comando `eval`.
- **Scritture atomiche**: Scritture e rotazioni protette da lock o rinomina atomica (`mv`).
- **Validazione ID**: Validazione della struttura dell'ID di sessione prima dell'elaborazione.

---

## 4. API Pubbliche del Modulo

```bash
# Verifica se il modulo è attivo e le directory necessarie sono disponibili
session_engine_enabled

# Aggiunge un messaggio alla sessione
session_engine_append <sid> <role> <content> <meta_json>

# Costruisce la finestra di contesto per il payload dell'LLM
session_engine_build_window <sid> <N> <target_bytes> <out_file>

# Genera lo snapshot diagnostico in formato JSON
session_engine_snapshot <sid> <out_file>
```

---

## 5. Configurazione

Principali variabili d'ambiente:

| Variabile | Valore Predefinito | Descrizione |
|---|---|---|
| `BASH4LLM_SESSION_ENGINE` | `on` | Abilita (`on`) o disabilita (`off`) il modulo. |
| `BASH4LLM_SESSION_SEGMENT_MAX_BYTES` | `1048576` | Soglia di rotazione dei file di sessione in byte (1MB). |
| `BASH4LLM_SESSION_SEGMENT_MAX_FILES` | `100` | Numero massimo di segmenti uncompressed da mantenere. |
| `BASH4LLM_SESSION_DEDUP_ENABLED` | `1` | Abilita il controllo di deduplicazione dei messaggi. |
| `SESSION_CACHE_ENABLED` | `1` | Abilita il caching in memoria della finestra di contesto. |
| `SESSION_CACHE_TTL_SEC` | `30` | Tempo di validità (TTL) della cache in secondi. |

---

## 🇬🇧 English Section

# Session Engine (Optional Extra for Bash4LLM⁺)

The *Session Engine* is an optional extension module enhancing the session management features of the Bash4LLM⁺ CORE.  
It does not replace core thread operations, but extends them with file segmentation, log rotation, message deduplication, in-memory TTL caching, and diagnostic snapshot generation.

The module operates in strict isolation, confining temporary allocations within `BASH4LLM_HISTORY_DIR` and `RUN_TMPDIR` using restrictive file permissions.

---

## 1. Key Objectives and Features

- **Long Session Management**: Prevents performance degradation when processing large conversation histories.
- **Log Segmentation & Rotation**: Limits individual history file sizes by rotating records into numbered segments upon reaching a byte threshold.
- **Message Deduplication**: Filters near-duplicate messages to reduce context noise.
- **Flexible Context Window Construction**: Supports selecting an explicit message count $N$ or dynamically accumulating messages within a byte budget (`target_bytes`).
- **Diagnostic Snapshots**: Exports JSON reports containing session statistics for inspection and debugging.
- **Security & Atomicity**: All file writes and rotations execute under exclusive locking (`lock_exec`) with strict `0600` file permissions.

---

## 2. Detailed Technical Features

### 2.1 Automatic Segmentation & Rotation
- Sessions initialize in a base file:  
  `bash4llm.d/history/sessions/<sid>.ndjson`
- When file size exceeds `BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (default 1MB), it rotates to:  
  `bash4llm.d/history/sessions/<sid>.NNN.ndjson`
- Rotation executes within a lock-protected critical section.
- Older historical segments can be compressed as `.gz` files via `gzip`.

### 2.2 Atomic Append (`session_engine_append`)
Appends messages to NDJSON logs enforcing:
- UTC timestamp, role, content, SHA-256 hash, and JSON metadata.
- Idempotency checking via `message_id` markers.
- Exclusive locking prior to file writes.
- Strict `0600` file permissions.

### 2.3 Context Window Construction (`session_engine_build_window`)
Supports two operational modes:

- **Explicit $N$ Override ($N > 0$)**: Extracts exactly the last $N$ non-ignored messages across segments from newest to oldest, restoring chronological order.
- **Byte-Budget Mode ($N = 0$)**: Accumulates historic messages up to the `BASH4LLM_SESSION_TARGET_BYTES` limit while respecting `BASH4LLM_SESSION_MIN_MESSAGES` and `BASH4LLM_SESSION_MAX_MESSAGES`.

Includes an in-process associative cache (`sid|params_hash`) with configurable TTL, automatically invalidated on each append operation.

### 2.4 Diagnostic Snapshot (`session_engine_snapshot`)
Produces a JSON report containing:
- Total message count and segment count.
- Cumulative session size in bytes.
- Last 50 lines of history and summary messages (`summary: true`).

---

## 3. Security Invariants

- **Isolated Storage**: No usage of shared `/tmp` paths. All temporary files reside in `RUN_TMPDIR` with `0600`/`0700` permissions.
- **Zero Eval**: No dynamic execution using `eval`.
- **Full Atomicity**: Writes and rotations are protected by locks or atomic renames (`mv`).
- **ID Validation**: Session ID structure is validated before processing.

---

## 4. Public API Reference

```bash
# Check if session engine is enabled and required directories exist
session_engine_enabled

# Append a message to the active session
session_engine_append <sid> <role> <content> <meta_json>

# Construct context window payload for the LLM
session_engine_build_window <sid> <N> <target_bytes> <out_file>

# Generate a complete diagnostic snapshot report
session_engine_snapshot <sid> <out_file>
```

---

## 5. Configuration

Main environment variables:

| Variable | Default Value | Description |
|---|---|---|
| `BASH4LLM_SESSION_ENGINE` | `on` | Enables (`on`) or disables (`off`) the module. |
| `BASH4LLM_SESSION_SEGMENT_MAX_BYTES` | `1048576` | Segment rotation size threshold in bytes (1MB). |
| `BASH4LLM_SESSION_SEGMENT_MAX_FILES` | `100` | Maximum uncompressed segments to retain. |
| `BASH4LLM_SESSION_DEDUP_ENABLED` | `1` | Enables message deduplication filter. |
| `SESSION_CACHE_ENABLED` | `1` | Enables in-memory context window caching. |
| `SESSION_CACHE_TTL_SEC` | `30` | In-memory cache time-to-live in seconds. |
