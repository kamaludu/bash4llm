# Specifica Tecnica dell'Architettura — Session Engine (`session-engine.sh`)

## 1. Scopo e Responsabilità

- **Scopo**: Fornire un componente opzionale (modulo *extra*) per estendere le primitive di gestione delle sessioni del CORE con funzionalità avanzate: segmentazione dei log, rotazione automatica, compressione, deduplicazione, caching in memoria con TTL, calcolo dinamico della finestra di contesto e generazione di snapshot diagnostici.
- **Responsabilità principali**:
  - Esporre l'API pubblica: `session_engine_enabled`, `session_engine_build_window`, `session_engine_append`, `session_engine_snapshot`.
  - Gestire la segmentazione e la rotazione dei file di sessione in modalità atomica e thread-safe.
  - Applicare le politiche di deduplicazione e la marcatura dei messaggi ignorati (`meta.ignored=true`).
  - Costruire la finestra dei messaggi per il payload dell'LLM in modalità $N$ esplicito oppure tramite budget di byte (`target_bytes`).
  - Gestire il caching in-process con invalidazione automatica e scadenza per TTL.
  - Utilizzare esclusivamente primitive sicure (`RUN_TMPDIR`, `lock_exec`, `atomic_write`), senza mai effettuare scritture al di fuori del perimetro di `BASH4LLM_DIR`.

---

## 2. Interfaccia Pubblica e Contratti

### Funzioni esportate:

- **`session_engine_enabled()` -> `0`|`1`**  
  Verifica se il modulo è attivo e operativo. Controlla la variabile `BASH4LLM_SESSION_ENGINE`, la presenza della directory `SE_DIR` e la disponibilità in scrittura di `RUN_TMPDIR`.

- **`session_engine_append <session_id> <role> <content> <meta_json>` -> `0`|`1`**  
  Esegue l'accodamento idempotente di un record NDJSON nella directory delle sessioni. Applica marker di idempotenza, lock esclusivo, rotazione dei segmenti, deduplicazione e invalidazione della cache locale.

- **`session_engine_build_window <session_id> <N> <target_bytes> <out_file>` -> `0`|`1`**  
  Scrive la struttura JSON `{"messages":[...]}` nel file di destinazione `$out_file`. Se $N > 0$, applica la modalità di override esplicito (ultimi $N$ messaggi non ignorati attraversando i segmenti). Se $N = 0$, applica la logica basata sul budget `target_bytes` e sui limiti `min`/`max` messaggi.

- **`session_engine_snapshot <session_id> <out_file>` -> `0`|`1`**  
  Genera un report diagnostico JSON contenente metadati statistici (conteggio messaggi, numero di segmenti, dimensione complessiva), le ultime righe registrate e i messaggi marcati come riassunto.

### Garanzie contrattuali:
- In caso di errore, le funzioni restituiscono un codice di stato non-zero senza alterare l'integrità dei file esistenti.
- Il modulo richiede che `RUN_TMPDIR` (o `BASH4LLM_TMPDIR`) sia accessibile e scrivibile. Qualora non sia disponibile, il modulo ritorna non-zero imponendo al CORE il fallback automatico sulle primitive base.
- Tutte le sezioni critiche di modifica dei file sono protette da `lock_exec`.

---

## 3. Dipendenze e Configurazione

- **Dipendenze di sistema**: `jq`, `mktemp`, `tac`, `tail`, `stat`, `sha256sum` (o `openssl`), `gzip` (opzionale per la compressione).
- **Integrazione PRECORE**: Invocazione delle primitive del Core `ensure_run_tmpdir`, `lock_exec` e delle routine di logging (`log_info`, `log_warn`, `log_error`).

### Variabili di configurazione d'ambiente:

| Variabile | Valore Predefinito | Descrizione |
|---|---|---|
| `BASH4LLM_SESSION_ENGINE` | `on` | Abilita (`on`) o disabilita (`off`) il motore. |
| `BASH4LLM_SESSION_SEGMENT_MAX_BYTES` | `1048576` | Soglia massima in byte prima della rotazione (1MB). |
| `BASH4LLM_SESSION_SEGMENT_MAX_FILES` | `100` | Limite massimo di segmenti da mantenere. |
| `BASH4LLM_SESSION_COMPRESSION_ENABLED` | `0` | Abilita (`1`) o disabilita (`0`) la compressione dei segmenti. |
| `BASH4LLM_SESSION_COMPRESSION_CMD` | `gzip` | Comando utilizzato per la compressione dei segmenti obsoleti. |
| `BASH4LLM_SESSION_TARGET_BYTES` | `32768` | Budget di byte di default per la costruzione della finestra ($N=0$). |
| `BASH4LLM_SESSION_MIN_MESSAGES` | `3` | Numero minimo di messaggi da conservare nella finestra. |
| `BASH4LLM_SESSION_MAX_MESSAGES` | `200` | Numero massimo di messaggi elaborabili nella finestra. |
| `BASH4LLM_SESSION_DEDUP_ENABLED` | `1` | Abilita il filtro di deduplicazione dei messaggi. |
| `BASH4LLM_SESSION_DEDUP_WINDOW` | `20` | Finestra di righe da scansionare per la verifica dei duplicati. |
| `SESSION_CACHE_ENABLED` | `1` | Abilita il caching in memoria della finestra. |
| `SESSION_CACHE_TTL_SEC` | `30` | Tempo di validità (TTL in secondi) delle voci in cache. |

### Percorsi di runtime:
- `SE_DIR="${BASH4LLM_EXTRAS_DIR%/}/session"` (Directory dei sorgenti del modulo).
- `SE_SESSION_DIR="${BASH4LLM_HISTORY_DIR%/}/sessions"` (Directory dei file di sessione, permessi `0700`).
- `RUN_TMPDIR` (Directory temporanea di processo isolata).

---

## 4. Flusso Operativo Interno

### Procedura di Append (`session_engine_append`):
1. Validazione degli argomenti di input e verifica della directory `SE_SESSION_DIR` (permessi `0700`).
2. Verifica dell'ambiente temporaneo tramite `ensure_run_tmpdir`.
3. **Pre-append**: Invocazione di `_se_segment_rotate_if_needed`. Se la dimensione del file supera `SEGMENT_MAX_BYTES`, viene eseguita la rotazione atomica del file sotto `lock_exec`.
4. **Deduplicazione**: `_se_dedupe_check` analizza le ultime righe per identificare corrispondenze di ruolo e contenuto. In caso di duplicato, imposta la marcatura `meta.ignored=true`.
5. Composizione della riga NDJSON contenente `ts`, `role`, `content`, `hash`, `schema_version` e `meta`.
6. **Marcatore di Idempotenza**: Creazione della directory temporanea di blocco `RUN_TMPDIR/session-msg-<message_id>.lockdir`. Se il marcatore esiste già, l'operazione di inserimento viene saltata.
7. **Scrittura Atomica**: Esecuzione di `lock_exec` sul file di lock della sessione (`<sid>.ndjson.lock`) ed accodamento della riga con applicazione dei permessi `0600`.
8. **Post-append**: Tentativo di rotazione post-scrittura ed invalidazione della cache in-process per l'ID di sessione attivo.

### Procedura di Costruzione Finestra (`session_engine_build_window`):
1. Scansione ed ordinamento dei segmenti disponibili per la sessione.
2. **Modalità $N > 0$ (Override)**: Estrazione degli ultimi $N$ record validi (escludendo i record con `meta.ignored=true`), riordinamento cronologico e generazione del JSON `{"messages":[...]}`.
3. **Modalità $N = 0$ (Byte-Budget)**: Scansione a ritroso dal segmento più recente. Accumulo dei messaggi fino al limite `target_bytes` rispettando i vincoli `min_messages` e `max_messages`.
4. **Caching In-Process**: Calcolo della chiave associativa `sid|params_hash`. Salvataggio della finestra generata in memoria e tracciamento del timestamp di creazione per la gestione del TTL.

---

## 5. Sicurezza e Invarianti

- **Isolamento dei file temporanei**: Nessuna scrittura nella directory condivisa `/tmp`. Ogni file temporaneo risiede in `RUN_TMPDIR` con permessi `0600`.
- **Zero Eval**: Assenza totale del comando `eval` o di meccanismi di interpretazione dinamica.
- **Atomicità delle scritture**: Tutte le modifiche ai file di sessione sono protette da lock o rinomina atomica (`mv`).
- **Anonimizzazione dei dati**: Gli identificatori di sessione e i thread vengono processati in conformità alle politiche di protezione dei dati personali del Core.

---

## 6. Integrazione con il Core

- Il Core interroga `session_engine_enabled()` prima di elaborare le sessioni. Se la funzione restituisce `1` (disabilitato o non disponibile), il Core ripiega sulle primitive base (`thread_read_window`, `thread_append`).
- Quando il modulo è attivo, il Core delega la costruzione del file dei messaggi `BUILD_MESSAGES_FILE` a `session_engine_build_window` e la registrazione della conversazione a `session_engine_append`.
- Si raccomanda di mantenere allineate le variabili d'ambiente `BASH4LLM_HISTORY_DIR` e `RUN_TMPDIR` nello stesso processo di esecuzione del Core.
