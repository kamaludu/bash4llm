## GroqBash — Documento di Architettura Strutturale

**Scopo**  
Documento di architettura e specifica tecnica per sviluppatori. Descrive PRECORE, PROVIDER, CORE e l’integrazione del **Sistema di Stato UI (UI State System)**: il CORE espone lo stato operativo verso la GUI tramite file JSON sotto **`$GROQBASH_CONFIG_DIR/ui_state`**. La semantica dei placeholder CGI (20–23) resta definita nella *Fonte di Verità Unificata dei Placeholder (GUI + CGI)*; qui si documenta la realizzazione tecnica e il contratto di lettura/scrittura.

---

### PRECORE — primitive e garanzie fondamentali
**Ruolo**  
Fornire primitive portabili, sicure e atomiche usate da CORE e PROVIDER: logging, locking, scritture atomiche, base64 staging, tmpdir runtime, controllo permessi/ownership.

**Primitive rilevanti per Sistema di Stato UI (UI State System)**
- **`atomic_write` / `b64_atomic_write`** — scritture atomiche obbligatorie per tutti i file di stato.
- **`lock_exec` / flock** — sincronizzazione per risorse condivise (models, history, sessioni).
- **`ensure_run_tmpdir`** — creazione di RUN_TMPDIR per staging; usato da provider/core.
- **Permessi** — PRECORE impone `chmod 700` per directory sensibili e `chmod 600` per file sensibili.

**Invarianti ereditate**
- Nessun file runtime al di fuori di `GROQBASH_DIR` e sottodirectory canoniche.
- Nessun uso diretto di `/tmp` di sistema; usare `GROQBASH_TMPDIR`/`RUN_TMPDIR`.
- Tutte le scritture critiche sono atomiche e protette da lock.

---

### PROVIDER — interfaccia e responsabilità
**Ruolo**  
Incapsulare le differenze tra servizi esterni: costruzione payload, chiamata HTTP (streaming/non‑streaming), refresh modelli, validazione provider‑specifica.

**Contratto minimo**
- **Obbligatorie**: `buildpayload_<provider>()`, `call_api_<provider>()`.
- **Opzionali**: `call_api_streaming_<provider>()`, `refresh_models_<provider>()`, `validate_model_<provider>()`, `auto_select_model_<provider>()`.

**Regole operative**
- I provider **non** scrivono file `ui_state`. Forniscono dati (RESP, http_code, chunk) al CORE; il CORE è l’unico responsabile dell’esposizione verso la GUI (Sistema di Stato UI (UI State System)).
- I provider devono usare le primitive PRECORE per I/O e lock.

---

### CORE — orchestrazione e Sistema di Stato UI (UI State System) (esposizione stato)
**Ruolo generale**  
Orchestrare parsing CLI, selezione provider/modello, costruzione payload, invocazione API, gestione retry, estrazione risposta, salvataggio history, gestione sessioni.

**Sistema di Stato UI (UI State System) — principio operativo**
- **Il CORE espone lo stato verso la GUI** tramite file JSON atomici in **`$GROQBASH_CONFIG_DIR/ui_state`**.
- **La GUI legge solo `ui_state`**; non deve leggere NDJSON, log o file interni per ricostruire i placeholder CGI.
- La *Fonte di Verità Unificata dei Placeholder (GUI + CGI)* rimane la definizione semantica; questo documento descrive la realizzazione tecnica (file + chiavi + eventi).

**Chi scrive `ui_state`**
- **CORE** (funzioni specifiche): `session_append`, `session_read_window`, `load_provider_module`, `call_api_<provider>`, `call_api_streaming_<provider>`, `save_to_history`, fallback in `perform_request_once`.
- **Regola**: tutte le scritture passano dall’helper centralizzato `ui_state_write` che:
  - crea `GROQBASH_CONFIG_DIR/ui_state` e `.../sessions` con `mkdir -p` e `chmod 700`,
  - usa `atomic_write` per la scrittura,
  - imposta `chmod 600` sul file,
  - logga warning in caso di errore ma non interrompe il flusso CLI.

**Eventi logici che aggiornano `ui_state`**
- **Dopo `session_append`** (user o assistant append): aggiornamento `ui_state/sessions/<sid>.json` e aggiornamento best‑effort di `ui_state/sessions/index.json`.
- **Dopo `session_read_window`** (costruzione BUILD_MESSAGES_FILE): aggiornamento `ui_state/sessions/<sid>.json`.
- **Dopo caricamento provider** (`load_provider_module`): scrittura `ui_state/provider_capabilities.json`.
- **Dopo chiamata API** (non‑streaming o streaming completato): scrittura `ui_state/last_api.json` (o fallback da `perform_request_once`).
- **Dopo `save_to_history`** (salvataggio file output): scrittura `ui_state/last_history.json`.

---

### Directory e path runtime (incluso ui_state)
**Percorsi canonici**
- **`GROQBASH_DIR`** — root runtime.
- **`GROQBASH_CONFIG_DIR`** — configurazione persistente; contiene `ui_state`.
- **`GROQBASH_CONFIG_DIR/ui_state`** — **nuova directory ufficiale** per stato esposto alla GUI.
  - Permessi: `700` directory, `600` file.
  - Contenuto: solo metadati JSON destinati alla GUI (no API key, no contenuti completi delle risposte).
- **`GROQBASH_CONFIG_DIR/ui_state/sessions`** — metadati per sessioni.
- **`GROQBASH_HISTORY_DIR`** — history e sessioni NDJSON (contenuto conversazioni).
- **`GROQBASH_TMPDIR` / `RUN_TMPDIR`** — staging temporaneo per payload/resp/err.

**Regole**
- `ui_state` è la fonte canonica per la GUI; i messaggi restano in `GROQBASH_HISTORY_DIR/sessions/*.ndjson`.
- Nessun file `ui_state` deve essere scritto al di fuori di `GROQBASH_CONFIG_DIR/ui_state`.

---

### Flusso sessione / history / API (end‑to‑end, eventi chiave)
**1. Creazione/append sessione**
- **Azione**: `session_append()` aggiunge record NDJSON sotto `GROQBASH_HISTORY_DIR/sessions/<sid>.ndjson` (idempotente, lock).
- **Effetto `ui_state`**: dopo append riuscito il CORE calcola `msg_count` (es. `wc -l`) e `last_ts` (ultima riga `.ts`) e scrive `ui_state/sessions/<sid>.json`; aggiorna `ui_state/sessions/index.json` (best‑effort).

**2. Lettura finestra sessione (BUILD_MESSAGES_FILE)**
- **Azione**: `session_read_window()` costruisce `BUILD_MESSAGES_FILE` per il payload.
- **Effetto `ui_state`**: dopo la costruzione il CORE aggiorna `ui_state/sessions/<sid>.json` con `msg_count` e `last_ts`.

**3. Caricamento provider**
- **Azione**: `load_provider_module()` valida e carica il modulo provider.
- **Effetto `ui_state`**: scrive `ui_state/provider_capabilities.json` con `supports_streaming` e `supports_refresh_models`.

**4. Invocazione API**
- **Azione**: `call_api_<provider>()` o `call_api_streaming_<provider>()` eseguono la chiamata.
- **Effetto `ui_state`**: al termine (o ricostruzione chunk) il CORE scrive `ui_state/last_api.json` con `last_http_status`, `last_finish_reason`, `last_edgecase_detected`, `last_req_id`, `last_time_utc`. Se il provider non scrive, `perform_request_once()` esegue un fallback.

**5. Salvataggio history**
- **Azione**: `save_to_history()` salva output in `GROQBASH_HISTORY_DIR`.
- **Effetto `ui_state`**: dopo il successo scrive `ui_state/last_history.json` con `saved:true`, `path`, `basename`, `ts`, `size_bytes`; in caso di fallimento scrive `saved:false`.

**Regole di non‑invasività**
- Tutte le scritture `ui_state` sono side‑effects non bloccanti: in caso di errore il CORE logga e prosegue senza interrompere il flusso CLI.

---

### Vincoli e invarianti (sintesi)
- **Atomicità**: tutte le scritture critiche (models, history, ui_state) sono atomiche e protette da lock.
- **Isolamento**: nessun file runtime al di fuori di `GROQBASH_DIR` e sottodirectory canoniche.
- **Permessi**: directory `700`, file `600`.
- **Unica fonte per metadati sessione**: `ui_state/sessions/<sid>.json` è la fonte canonica per i placeholder di sessione; i messaggi restano in NDJSON.
- **CORE come unica scrittura `ui_state`**: i provider non scrivono `ui_state`.
- **Non duplicazione della FoV**: la semantica dei placeholder resta nella *Fonte di Verità Unificata dei Placeholder (GUI + CGI)*; qui è la vista implementativa.

---

## Appendice tecnica — vista rapida per sviluppatori

### Elenco file `ui_state` (path relativi a `GROQBASH_CONFIG_DIR`)
- `ui_state/provider_capabilities.json`  
  ```json
  { "provider":"<name>", "supports_streaming":true|false, "supports_refresh_models":true|false, "loaded_from":"<path|embedded>" }
  ```
- `ui_state/last_api.json`  
  ```json
  { "last_http_status":<int>, "last_finish_reason":"<string>", "last_edgecase_detected":true|false, "last_req_id":"<string>", "last_time_utc":"YYYY-MM-DDTHH:MM:SSZ" }
  ```
- `ui_state/last_history.json`  
  ```json
  { "saved":true|false, "path":"/full/path", "basename":"<file>", "ts":"YYYY-MM-DDTHH:MM:SSZ", "size_bytes":<int> }
  ```
- `ui_state/sessions/index.json`  
  ```json
  { "sessions": ["sid1","sid2", ...] }
  ```
- `ui_state/sessions/<SESSION_ID>.json`  
  ```json
  { "id":"<SESSION_ID>", "active":true|false, "msg_count":<int>, "last_ts":"YYYY-MM-DDTHH:MM:SSZ" }
  ```

### Mappa rapida placeholder CGI → file JSON → chiave
| Placeholder CGI | File JSON | Chiave JSON |
|---|---:|---|
| SESSION_ACTIVE | `ui_state/sessions/<SESSION_ID>.json` | `active` |
| SESSION_ID | `ui_state/sessions/<SESSION_ID>.json` | `id` |
| SESSION_MSG_COUNT | `ui_state/sessions/<SESSION_ID>.json` | `msg_count` |
| SESSION_LAST_TS | `ui_state/sessions/<SESSION_ID>.json` | `last_ts` |
| SESSION_LIST | `ui_state/sessions/index.json` | `sessions` |
| PROVIDER_SUPPORTS_STREAMING | `ui_state/provider_capabilities.json` | `supports_streaming` |
| PROVIDER_SUPPORTS_REFRESH_MODELS | `ui_state/provider_capabilities.json` | `supports_refresh_models` |
| LAST_HTTP_STATUS | `ui_state/last_api.json` | `last_http_status` |
| LAST_FINISH_REASON | `ui_state/last_api.json` | `last_finish_reason` |
| LAST_EDGECASE_DETECTED | `ui_state/last_api.json` | `last_edgecase_detected` |
| LAST_SAVED_TO_HISTORY | `ui_state/last_history.json` | `saved` |
| LAST_HISTORY_FILE | `ui_state/last_history.json` | `basename` / `path` |

**Nota**: per la semantica (tipi, obbligatorietà, fallback) fare riferimento alla *Fonte di Verità Unificata dei Placeholder (GUI + CGI)*.

### Operazioni consigliate per la GUI (implementatori)
- Leggere i file `ui_state` con `jq` o parser JSON robusto; non leggere NDJSON per i placeholder CGI.
- Per `SESSION_LIST` convertire l’array JSON in multilinea se la UI richiede quel formato.
- Non assumere che `ui_state` sia sempre aggiornato istantaneamente: leggere e gestire assenza/valori vuoti (fallback UI).
- Non esporre o loggare contenuti sensibili; `ui_state` non contiene API key o contenuti completi delle risposte.

---

### Checklist di integrazione per sviluppatori core
1. Implementare helper `ui_state_write(relpath, json)` che:
   - crea `GROQBASH_CONFIG_DIR/ui_state` e `.../sessions` con `chmod 700`,
   - scrive con `atomic_write` e imposta `chmod 600`,
   - logga warning su errori senza interrompere il flusso.
2. Inserire chiamate `ui_state_write` nei punti logici:
   - `session_append`, `session_read_window` → `sessions/<sid>.json` e `sessions/index.json`.
   - `load_provider_module` → `provider_capabilities.json`.
   - `call_api_<provider>`, `call_api_streaming_<provider>` (o fallback in `perform_request_once`) → `last_api.json`.
   - `save_to_history` → `last_history.json`.
3. Testare permessi, atomicità e resilienza (fallimento scrittura non fatale).
4. Documentare `ui_state` nel repository (es. `docs/ui_state.md`) e aggiornare la GUI per leggere solo `ui_state`.

---

**Conclusione**  
Questa versione integra il **Sistema di Stato UI (UI State System)** come responsabilità del CORE, definisce i file `ui_state` e i punti del flusso in cui vengono aggiornati, e fornisce una vista tecnica chiara e sintetica per sviluppatori di CORE e GUI. Per la semantica dettagliata dei placeholder CGI fare sempre riferimento alla *Fonte di Verità Unificata dei Placeholder (GUI + CGI)*; questo documento è la specifica implementativa che la GUI e il CORE devono rispettare.
