### Motore di sessione — Documento architetturale (session-engine.sh)

#### Scopo e responsabilità
**Scopo:** fornire un motore opzionale, installabile come *extra*, che estende le primitive di sessione del CORE (`session_read_window`, `session_append`, cache) con funzionalità avanzate: segmentazione, rotazione, compressione, deduplicazione, caching in-process, costruzione della finestra di messaggi (window building) e snapshot diagnostico.  
**Responsabilità principali:**  
- Esporre l’API pubblica: **`session_engine_enabled`**, **`session_engine_build_window`**, **`session_engine_append`**, **`session_engine_snapshot`**.  
- Gestire segmentazione e rotazione dei file di sessione in modo atomico e thread‑safe.  
- Applicare politiche di deduplicazione e marcatura `ignored`.  
- Costruire la finestra di messaggi per il CORE secondo due modalità (override N oppure target_bytes).  
- Fornire snapshot diagnostici e caching in-process con TTL.  
- Usare esclusivamente primitive sicure (RUN_TMPDIR, lock_exec, atomic write) e non scrivere fuori da `BASH4LLM_DIR`.

---

#### Interfaccia pubblica e contratti
**Funzioni esportate (contratto):**
- `session_engine_enabled() -> 0|1`  
  Verifica se l’engine è attivato e utilizzabile (controlla `BASH4LLM_SESSION_ENGINE`, presenza `SE_DIR`, disponibilità `RUN_TMPDIR`).
- `session_engine_append <session_id> <role> <content> <meta_json> -> 0|1`  
  Append idempotente di un record NDJSON in `SE_SESSION_DIR`. Implementa marker idempotenza, lock, rotazione pre/post, dedup, aggiornamento cache in-process.
- `session_engine_build_window <session_id> <N> <target_bytes> <out_file> -> 0|1`  
  Costruisce `{"messages":[...]}` in `out_file`. Se `N>0` applica la modalità override (ultime N righe across segments, esclude `meta.ignored`). Altrimenti applica logica target_bytes/min/max/messages.
- `session_engine_snapshot <session_id> <out_file> -> 0|1`  
  Produce JSON diagnostico con statistiche (message_count, segments, total_size), ultime righe e sommari marcati.

**Contractual guarantees:**
- Su fallimento la funzione ritorna non‑zero e lascia i file originali consistenti.  
- Richiede `RUN_TMPDIR` scrivibile; se non disponibile ritorna non‑zero e il CORE deve effettuare fallback.  
- Usa lock_exec per sezioni critiche; tutte le scritture su file sessione sono atomiche o protette da lock.

---

#### Dipendenze e variabili di configurazione
**Dipendenze esterne:** `jq`, `mktemp`, `tac`, `tail`, `stat`, `sha256sum` o `openssl` (fallback), `gzip` o altro comando di compressione se abilitato. Deve poter invocare le primitive del PRECORE: `ensure_run_tmpdir`, `lock_exec`, `log_info/log_warn/log_error` (se presenti).  
**Variabili di configurazione (env, con valori di default nel file):**
- `BASH4LLM_SESSION_ENGINE` (on|off)  
- `BASH4LLM_SESSION_SEGMENT_MAX_BYTES` (default 1048576)  
- `BASH4LLM_SESSION_SEGMENT_MAX_FILES` (default 100)  
- `BASH4LLM_SESSION_COMPRESSION_ENABLED` (0|1)  
- `BASH4LLM_SESSION_COMPRESSION_CMD` (es. gzip)  
- `BASH4LLM_SESSION_TARGET_BYTES` (default 32768)  
- `BASH4LLM_SESSION_MIN_MESSAGES`, `BASH4LLM_SESSION_MAX_MESSAGES`  
- `BASH4LLM_SESSION_DEDUP_ENABLED`, `BASH4LLM_SESSION_DEDUP_WINDOW`  
- `SESSION_CACHE_ENABLED`, `SESSION_CACHE_TTL_SEC`  
**Percorsi runtime calcolati:**
- `SE_DIR=${BASH4LLM_EXTRAS_DIR%/}/session` (sorgente extra)  
- `SE_SESSION_DIR=${BASH4LLM_HISTORY_DIR%/}/sessions` (runtime session files)  
- `RUN_TMPDIR` (obbligatorio per l’engine; fallback su `BASH4LLM_TMPDIR`)

---

#### Flusso operativo e logica interna
**Append (high level):**
1. Validazione input e creazione `SE_SESSION_DIR` con permessi 700.  
2. Assicurazione `RUN_TMPDIR` tramite `ensure_run_tmpdir`.  
3. **Pre-append:** `_se_segment_rotate_if_needed` — se il file corrente supera `SEGMENT_MAX_BYTES` effettua rotazione atomica dentro `lock_exec`.  
4. **Dedup:** `_se_dedupe_check` esamina le ultime `DEDUP_WINDOW` righe per ruolo+contenuto; se duplicato marca `meta.ignored=true`.  
5. Composizione della riga NDJSON con `ts`, `role`, `content`, `hash`, `schema_version`, `meta`.  
6. **Idempotency marker:** crea `RUN_TMPDIR/session-msg-<message_id>.lockdir` o run-local marker; se esiste, skip append.  
7. **Append atomico:** `lock_exec` sul `session_file.lock` e append della riga; garantisce chmod 600.  
8. **Post-append:** tentativo non-fallimentare di rotazione; invalidazione cache in-process per `sid`; lascia marker con `done`.  

**Build window (high level):**
- Calcola `segments` (lista ordinata ascendente) e lavora newest-first.  
- **Modalità N>0 (override):** raccoglie le ultime N righe across segments (esclude `.gz`), esclude `meta.ignored`, mantiene ordine cronologico (oldest→newest), scrive `{"messages":[{role,content},...]}`. Non applica trimming per `target_bytes`.  
- **Modalità target_bytes:** scorre newest-first, accumula messaggi fino a `target_bytes` rispettando `min_msgs` e `max_msgs`, calcola peso tramite `_se_compute_weight`, esclude `meta.ignored`. Produce JSON compatto con `jq`.  
- Caching in-process: chiave `sid|params_hash`; memorizza `SE_CACHE_WINDOW`, `SE_CACHE_MTIME`, `SE_CACHE_STORED_TS` e rispetta `SESSION_CACHE_TTL_SEC`.

**Snapshot:**
- Elenca segmenti, somma conteggi e dimensioni, concatena segmenti non compressi per estrarre ultime 50 righe, raccoglie record con `meta.summary==true`, costruisce JSON diagnostico con `jq`.

---

#### Error handling, recovery e invarianti
**Error handling:**
- Ogni funzione valida prerequisiti (esistenza directory, RUN_TMPDIR) e ritorna non‑zero con log in caso di errore.  
- Operazioni critiche (rotazione, append) eseguite dentro `lock_exec`; se falliscono, la funzione segnala errore e non lascia file parziali.  
- Compressione e post-append rotation sono non-fatal: loggano warn/err ma non fanno fallire l’append già riuscito.  
**Recovery:**  
- Se append fallisce dopo creazione marker, il marker viene rimosso per evitare blocchi permanenti.  
- Cache in-process invalidata su append per evitare serving di finestre stale.  
**Invarianti critiche mantenute:**
- Tutti i file runtime risiedono sotto `BASH4LLM_HISTORY_DIR` e `RUN_TMPDIR`.  
- Nessuna scrittura su `/tmp` di sistema; tmp creati solo in `RUN_TMPDIR`.  
- Locking e atomicità garantiscono consistenza in presenza di concorrenza.  
- File di sessione con permessi restrittivi (600/700).

---

#### Sicurezza, performance e limiti operativi
**Sicurezza:**  
- Non eseguire contenuto proveniente dalle sessioni; il motore tratta i messaggi come dati.  
- Marker e lock directory creati con permessi restrittivi; non usare symlink non verificati.  
**Performance:**  
- Segmentazione limita la dimensione dei file attivi; rotazione e compressione mantengono spazio su disco.  
- Caching in-process riduce lavoro di `jq`/I/O per richieste ripetute; TTL configurabile.  
**Limiti operativi noti:**  
- Non processa file `.gz` per build_window (salta segmenti compressi).  
- Dipende da `tac`/`tail`/`jq`; su sistemi privi di questi comandi alcune funzioni degradano.  
- Cache in-process è volatile (per processo) e non condivisa tra invocazioni separate.

---

#### Integrazione con CORE e raccomandazioni
**Integrazione:**  
- Il CORE deve chiamare `session_engine_enabled()` per decidere se usare l’engine; in caso di `false` deve ricadere sulle primitive CORE/MVP (`session_read_window`, `session_append`, `session_cache_*`).  
- Quando l’engine è attiva, il CORE deve delegare a `session_engine_build_window` per costruire `BUILD_MESSAGES_FILE` e a `session_engine_append` per la persistenza dei messaggi.  
**Raccomandazioni operative:**  
- Persistere `RUN_TMPDIR` e `GROQABASH_HISTORY_DIR` nello stesso ambiente del processo che esegue il CORE.  
- Abilitare `SESSION_CACHE_ENABLED` con TTL breve (es. 30s) per ridurre latenza su richieste ripetute.  
- Abilitare compressione solo se `BASH4LLM_SESSION_COMPRESSION_CMD` è disponibile e testato; la build_window ignora segmenti compressi, quindi prevedere policy di decompressione se si vuole includerli.  
- Documentare chiaramente che `session-engine.sh` è **un extra opzionale** che si appoggia alle primitive CORE; non deve sostituirle né bypassare PRECORE.

---

#### Test e controlli consigliati
- **Unit test funzionali:** append concorrenti su stessa sessione (più processi) per verificare idempotenza e lock.  
- **Test rotazione:** generare file > `SEGMENT_MAX_BYTES` e verificare creazione di segmenti numerati e integrità dei dati.  
- **Test build_window:** confrontare output `N override` vs `target_bytes` su sessioni multi-segmento con messaggi `ignored`.  
- **Test cache:** verificare hit/miss e invalidazione dopo append.  
- **Test fallback:** disabilitare `RUN_TMPDIR` e verificare che `session_engine_enabled` ritorni non‑zero e che il CORE ricada sul MVP.

---
