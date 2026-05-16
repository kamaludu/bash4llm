## GroqBash - Spec tecnica LLM readable
**(groqbash senza codice)**

### Panoramica globale del sistema

**GroqBash** è un singolo script Bash, auto‑contenuto e auditabile, che fornisce un wrapper CLI sicuro per l’API Chat Completions compatibile OpenAI di Groq. Progettato per ambienti single‑user Unix‑like, GroqBash centralizza: inizializzazione sicura dell’ambiente, gestione atomica di tmp/history/sessioni/manifest, integrazione provider (builtin `groq` + extras), costruzione payload, chiamate HTTP streaming e non‑streaming via `curl`, e salvataggio/diagnostica delle risposte. Tutte le operazioni critiche sono atomiche, protette da lock e soggette a policy di rete centralizzate.

---

### Invarianti e modello mentale

**Invarianti globali**
- Directory canoniche esistono e hanno permessi **700**; file sensibili **600**.
- Nessun tmp principale creato direttamente in `/tmp` di sistema; RUN_TMPDIR è sotto GROQBASH_TMPDIR.
- Nessuna esecuzione di contenuti provenienti da API; nessun uso di `eval`.
- Locking esplicito per tutte le operazioni concorrenti critiche; timeout configurabili.
- Provider caricati solo dopo validazione di owner, permessi, non‑symlink e firma invariata dopo sourcing.

**Modello mentale per LLM/analisi**
- **Single‑user trusted environment**: l’utente controlla le directory; variabili d’ambiente sono configurazione fidata.
- **Atomicità prima di tutto**: ogni scrittura persistente usa staging + mv atomico o flock.
- **Sezioni separate per responsabilità**: PRECORE_BOOT (bootstrap e sicurezza), PRECORE_RUN (runtime atomico e sessioni), PROVIDER (integrazione API), CORE_SETUP (orchestrazione CLI e request), CORE_PROVIDER (selezione/persistenza provider).
- **Fail‑fast per sicurezza**: condizioni critiche (mancanza comandi obbligatori, permessi errati, firma provider mutata) causano exit immediato con codici canonici.

---

### Dipendenze tra macro‑sezioni

| Consumer | Dipende da | Tipo di dipendenza |
|---|---:|---|
| PRECORE_RUN | PRECORE_BOOT | helper tmp, lock_exec, ensure_run_tmpdir |
| PROVIDER | PRECORE_BOOT, PRECORE_RUN | tmp, b64 helpers, lock_exec, ensure_run_tmpdir |
| CORE_SETUP | PRECORE_BOOT, PROVIDER, PRECORE_RUN | dispatch provider, resolve_model, save_to_history |
| CORE_PROVIDER | PRECORE_BOOT, PRECORE_RUN | canonical paths, atomic_write, load_provider_module |
| Tutte | sistema: bash, coreutils, findutils, util‑linux, gawk, curl, jq | requisiti obbligatori |

---

### Flusso di esecuzione end‑to‑end

1. **Bootstrap (PRECORE_BOOT)**  
   - Verifica comandi obbligatori; risolve SCRIPTDIR e directory canoniche; crea e protegge config, models, templates, history, extras; imposta opzioni base64 e lock names; prepara helper atomici e enforce_network_policy.

2. **Preparazione runtime (PRECORE_RUN)**  
   - ensure_run_tmpdir crea RUN_TMPDIR; installa trap di cleanup; inizializza history, manifest e session engine; abilita cache sessione.

3. **Selezione provider (CORE_PROVIDER)**  
   - Popola SUPPORTED_PROVIDERS; applica provider persistente o CLI; valida interfaccia provider; carica modulo provider con load_provider_module; risolve GROQBASH_PROVIDER_URL; opzionale refresh modelli.

4. **Risoluzione modello e costruzione payload (CORE_SETUP + PROVIDER)**  
   - resolve_model determina FINAL_MODEL; build_payload_from_vars delega a buildpayload_<prov> che produce GROQBASH_TMP_PAYLOAD/PAYLOAD.

5. **Esecuzione richiesta (CORE_SETUP → PROVIDER)**  
   - enforce_network_policy; call_api_once o call_api_streaming che invocano call_api_<prov> o call_api_streaming_<prov>; streaming emesso su stdout; aggregazione chunk e scrittura RESP.

6. **Post‑processing e persistenza**  
   - extract_text_from_resp, detect_empty_edge_case, finalize_and_output; save_to_history per output lunghi; ui_state_write best‑effort.

---

## Sezioni principali

### PRECORE_BOOT
**Scopo**  
Inizializzare ambiente, validare requisiti, normalizzare percorsi, fornire helper atomici e policy di sicurezza.

**Responsabilità**
- Fail‑fast su comandi obbligatori mancanti.
- Risoluzione SCRIPTDIR, GROQBASH_DIR, GROQBASH_CONFIG_DIR, PROVIDERS_DIR, GROQBASH_TMPDIR.
- Creazione e protezione directory/file canonici con permessi 700/600.
- Fornitura helper: atomic_write, b64_atomic_write/read, _mktemp_in_dir, lock_exec, ensure_run_tmpdir, ui_state_write.
- Validazione e caricamento sicuro dei moduli provider; scrittura provider_capabilities.json.
- Centralizzazione enforce_network_policy.

**Dipendenze**
- PATH con: bash, coreutils, findutils, util‑linux, gawk, curl, jq.
- ENV letti: GROQBASH_DIR, GROQBASH_CONFIG_DIR, PROVIDERS_DIR, GROQBASH_TMPDIR, DEBUG, DRY_RUN, GROQBASH_SKIP_NETWORK, ecc.

**API esposta**
- `resolve_script_dir`
- `canonical_config_dir`, `canonical_provider_file`, `canonical_model_file`, `canonical_provider_url_file`
- `provider_api_env_var_name`
- `ensure_api_key_for_provider`
- `enforce_network_policy`
- `ensure_config_dir`
- `write_provider_url_if_missing`
- `is_valid_json_string`, `is_valid_json_file`, `jq_safe`
- `b64encode`, `b64decode`, `b64_atomic_write`, `b64_atomic_read`, `stage_b64`
- `lock_exec`, `_mktemp_in_dir`, `atomic_write`, `_tmpf`
- `ensure_run_tmpdir`, `cleanup_run_tmp_on_exit`, `ui_state_write`
- `load_provider_module`, `getfile_signature`, `_get_owner`, `_get_perm_string`, `_is_world_writable`

**Side‑effect**
- Creazione di directory e file canonici; esport di variabili SCRIPTDIR, RUN_TMPDIR; scrittura provider_capabilities.json; log su stderr.

**Flussi principali**
- Bootstrap normale: verifica comandi → ensure_config_dir → set opts base64/lock → pronto per load_provider_module o ensure_run_tmpdir.
- Flag `--print-*`: stampa percorso canonico e exit.
- Caricamento provider: validazione permessi/owner/symlink → bash -n + source → verifica funzioni richieste → scrittura provider_capabilities.json.

---

### PRECORE_RUN
**Scopo**  
Primitive runtime atomiche per history, manifest, tmp, sessioni e cache.

**Responsabilità**
- Gestione history con rotazione atomica.
- Creazione e aggiornamento manifest multimodale con staging base64.
- Session engine NDJSON: validazione id, append idempotente, lettura window atomica.
- Cache sessione con TTL e invalidazione.
- Utility permessi/firma: _get_perm_string, _get_owner, _get_file_signature, getfile_signature, _is_world_writable.

**Dipendenze**
- ENV: GROQBASH_HISTORY_DIR, GROQBASH_TMPDIR, RUN_TMPDIR, GROQBASH_LOCK_TIMEOUT_*, SESSION_DIR, LAST_CHECK_LINES.
- Funzioni esterne: lock_exec, ui_state_write, ensure_run_tmpdir, b64encode/decode, file_size, is_truthy, log_*.
- Comandi: jq, mktemp, stat, find, grep, awk, sed, tail, sort, head, mv, cp, chmod, rm, mkdir, flock, date, sha256sum/openssl opzionale.

**API esposta**
- `rotate_history`, `save_to_history`
- `manifest_create`, `manifest_add_part`, `manifest_read`
- `make_tmpdir`, `_tmpf`
- `session_validate_id`, `session_now_ts`, `session_messages_tmp_path`, `session_sanitize_cmd`
- `session_read_window`, `session_append`
- `session_cache_key`, `session_cache_get`, `session_cache_set`, `session_cache_invalidate`
- `_get_perm_string`, `_get_owner`, `_get_file_signature`, `getfile_signature`, `_is_world_writable`

**Side‑effect**
- File history, manifest (.b64), session NDJSON, session_cache files; lockfiles sotto RUN_TMPDIR; ui_state updates best‑effort.

**Flussi principali**
- `save_to_history`: staging + mv atomico sotto HISTORY_LOCK → rotate_history se necessario.
- `manifest_add_part`: verifica sorgente → b64_atomic_write → aggiornamento manifest sotto lock.
- `session_append`: crea marker dir per message_id → flock → evita duplicati → append NDJSON atomico → aggiorna index e ui_state.

---

### PROVIDER (implementazione `groq`)
**Scopo**  
Integrazione con API Groq: costruzione payload, chiamate HTTP streaming/non‑streaming, gestione modelli.

**Responsabilità**
- `buildpayload_groq`: costruzione payload chat JSON.
- `call_api_groq`: chiamata non‑streaming e salvataggio RESP.
- `call_api_streaming_groq`: streaming SSE, emissione su stdout, aggregazione chunk.
- `refresh_models_groq`: fetch `/openai/v1/models`, normalizzazione e scrittura MODELS_FILE.
- `validate_model_groq`, `auto_select_model_groq`.

**Dipendenze**
- ENV: GROQ_API_KEY, PROVIDER_API_ENV_groq, GROQBASH_PROVIDER_URL, MODELS_FILE, CURL_BASE_OPTS, RUN_TMPDIR, STREAM_MODE, B64_DECODE_OPT.
- Helper: ensure_run_tmpdir, _mktemp_in_dir, is_truthy, is_valid_json_*, b64decode, stage_b64, b64_atomic_write, lock_exec, resolve_provider_url, is_supported_model, ui_state_write, log_*.

**API esposta**
- `buildpayload_groq` / `buildpayloadgroq`
- `call_api_groq`
- `call_api_streaming_groq` / `call_api_streaming_groq_legacy`
- `refresh_models_groq` / `refreshmodelsgroq`
- `validate_model_groq` / `validatemodelgroq`
- `auto_select_model_groq` / `autoselectmodelgroq`

**Side‑effect**
- Creazione payload files, resp.raw/resp.lines/resp.json/resp.text, MODELS_FILE atomico; emissione streaming su stdout; scrittura last_api.json via ui_state_write.

**Flussi principali**
- Non‑streaming: buildpayload → enforce_network_policy → curl → validate JSON → scrivi RESP.
- Streaming: buildpayload(stream) → curl SSE → parse `data:` lines → stampa incrementale → aggrega chunk → scrivi RESP.
- Refresh modelli: curl `/openai/v1/models` → jq normalize → b64_atomic_write sotto MODELS_LOCK.

---

### CORE_SETUP
**Scopo**  
Orchestrare stato CLI/runtime, risolvere modello, dispatch provider, wrapper chiamate API, gestione output e salvataggio.

**Responsabilità**
- Normalizzazione flag CLI e popolamento SUPPORTED_PROVIDERS.
- Risoluzione modello con `resolve_model`.
- Dispatch dinamico a provider tramite `call_provider`.
- Wrapper `call_api_once`, `call_api_streaming`, retry loop `perform_request_once`.
- Estrazione testo da RESP, rilevamento edge empty, finalize_and_output.

**Dipendenze**
- ENV: MODEL, PROVIDER, DRY_RUN, STREAM_MODE, OUTPUT_MODE, GROQBASH_CONFIG_DIR, RUN_TMPDIR, THRESHOLD.
- Funzioni: call_provider, ensure_run_tmpdir, is_truthy, canonical_* , is_valid_json_file, extract_text_from_resp, ui_state_write, save_to_history, session_engine_*.

**API esposta**
- `call_provider`
- `refresh_models_dispatch`
- `validate_model_dispatch`
- `auto_select_model_dispatch`
- `resolve_model`
- `build_payload_from_vars`
- `call_api_once`, `call_api_streaming`
- `extract_api_error`, `detect_empty_edge_case`
- `finalize_and_output`
- `perform_request_once`
- `list_models_cli`, `validate_model_core`, `load_local_config`, `load_whitelist`, `is_tty_out`

**Side‑effect**
- Impostazione FINAL_MODEL, MODEL_PROVIDER_CFG, normalized flags; scrittura fallback ui_state/last_api.json; salvataggio history.

**Flussi principali**
- CLI parse → load config/whitelist → resolve_model → build_payload_from_vars → perform_request_once → finalize_and_output.

---

### CORE_PROVIDER
**Scopo**  
Scoperta, selezione, persistenza e validazione del provider; orchestrazione refresh modelli e comandi diagnostici.

**Responsabilità**
- Popolare SUPPORTED_PROVIDERS (builtin + PROVIDERS_DIR/*.sh).
- Applicare provider persistente o override CLI/interactive.
- Validare interfaccia provider e caricare modulo con load_provider_module.
- Risolvere GROQBASH_PROVIDER_URL e persistere provider file atomico.
- Invalida cache modelli su cambio provider; orchestrare refresh_models_dispatch.

**Dipendenze**
- ENV: PROVIDER, PROVIDER_CLI, PROVIDER_INTERACTIVE, REFRESH_MODELS, MODELS_FILE.
- Funzioni: canonical_provider_file, canonical_provider_url_file, ensure_config_dir, atomic_write, load_provider_module, resolve_provider_url, ensure_api_key_for_provider, refresh_models_dispatch, write_provider_url_if_missing.

**API esposta**
- `validate_provider_interface(p)`
- `load_provider_module(PROVIDER)`
- `resolve_provider_url(PROVIDER)`
- `ensure_api_key_for_provider(PROVIDER)`
- `refresh_models_dispatch(MODELS_FILE)`
- `write_provider_url_if_missing(provider, url)`

**Side‑effect**
- Persistenza provider file atomica; possibile rimozione MODELS_FILE; impostazione GROQBASH_PROVIDER_URL; stdout/stderr diagnostici.

**Flussi principali**
- Determina provider → persist atomic → load_provider_module → validate interface → resolve_provider_url → optional refresh_models_dispatch.

---

---

## Glossario e convenzioni

**Termini chiave**
- **RUN_TMPDIR**: tmp per singola esecuzione, creato da ensure_run_tmpdir.
- **GROQBASH_TMPDIR**: base tmp sotto config; non è `/tmp`.
- **PAYLOAD / GROQBASH_TMP_PAYLOAD**: file JSON inviato all’API.
- **RESP**: file risposta aggregata (JSON o diagnostico).
- **MODELS_FILE**: file persistente con lista modelli normalizzata.
- **provider_capabilities.json**: metadata scritto dopo load_provider_module.
- **edge empty**: completions vuote rilevate da detect_empty_edge_case.

**Codici di errore canonici**
- **0**: successo.
- **1**: errore generico / validazione fallita.
- **2**: JSON/diagnostica non valida.
- **124**: timeout lock (lock_exec).
- **127**: funzione provider mancante (dispatch).
- **GROQBASHERRNOAPIKEY**: mancanza API key quando richiesta.
- **GROQBASHERRAPI**: errore API generico.
- **GROQBASHERRTMP**: errori tmp/I/O.

**Schema minimo RESP diagnostico (JSON)**
```json
{
  "timestamp": "ISO8601",
  "provider": "groq",
  "request_id": "string|null",
  "status": "ok|error|partial",
  "http_code": 0,
  "error": {"message":"string","type":"string","detail":"string|null"},
  "resp_snippet": "string|null",
  "raw_path": "path/to/resp.raw"
}
```

---

### Variabili d’ambiente canoniche

**Configurazione directory e runtime**
- `GROQBASH_DIR`, `SCRIPTDIR`, `GROQBASH_CONFIG_DIR`, `GROQBASH_MODELS_DIR`, `GROQBASH_TEMPLATES_DIR`, `GROQBASH_HISTORY_DIR`, `GROQBASH_TMPDIR`, `RUN_TMPDIR`, `PROVIDERS_DIR`, `GROQBASH_EXTRAS_DIR`

**Provider / API**
- `GROQ_API_KEY`, `GROQBASH_API_KEY`, `PROVIDER_API_ENV_<prov>`, `GROQBASH_PROVIDER_URL`, `PROVIDER`, `PROVIDER_CLI`, `PROVIDER_INTERACTIVE`

**Runtime flags**
- `DEBUG`, `DRY_RUN`, `QUIET`, `STREAM_MODE`, `ALLOW_API_CALLS`, `GROQBASH_SKIP_NETWORK`, `GROQBASH_ENFORCE_NO_NETWORK_IF_QUIET`

**Limits / timeouts**
- `MAX_MODELS`, `MAX_STAGE_BYTES`, `MAX_TOKENS`, `GROQBASH_LOCK_TIMEOUT_HISTORY`, `GROQBASH_LOCK_TIMEOUT_TMP`, `GROQBASH_LOCK_TIMEOUT_MODELS`

**Base64 / encoding**
- `B64_WRAP_OPT`, `B64_DECODE_OPT`

**Session / history**
- `SESSION_DIR`, `SESSION_ID`, `SESSION_WINDOW`, `LAST_CHECK_LINES`, `GROQBASH_ROTATE_HISTORY`, `GROQBASH_HISTORY_MAX_FILES`, `GROQBASH_HISTORY_MAX_BYTES`, `GROQBASH_HISTORY_KEEP_DAYS`

---

### Percorsi canonici e permessi

**Regole generali**
- Tutte le directory create da GroqBash: **mode 700**.
- Tutti i file sensibili creati da GroqBash: **mode 600**.
- Provider modules e extras: non devono essere symlink; owner deve essere utente esecutore; firma file verificata dopo sourcing.
- Nessun tmp principale in `/tmp`; RUN_TMPDIR sotto `GROQBASH_TMPDIR` nello stesso filesystem della destinazione.

**Percorsi principali (esempi semantici)**
- `$(SCRIPTDIR)/groqbash` — script principale.
- `$(GROQBASH_DIR)/config` — config persistente.
- `$(GROQBASH_CONFIG_DIR)/ui_state` — ui_state files, `last_api.json`.
- `$(GROQBASH_CONFIG_DIR)/provider-url` — provider URL persistente, file 600.
- `$(PROVIDERS_DIR)/*.sh` — provider modules, file 600, non symlink.
- `$(GROQBASH_MODELS_DIR)/models.b64` — MODELS_FILE atomico.
- `$(GROQBASH_HISTORY_DIR)/history/*.json` — history files, rotazione gestita.
- `$(GROQBASH_TMPDIR)/run-<pid>-<ts>` — RUN_TMPDIR, dir 700.

---

---

## Appendici

### Timeout / Retry defaults
- **Lock timeout default**: `GROQBASH_LOCK_TIMEOUT_*` variabili configurabili; default operativo consigliato: **10s** per tmp/history, **30s** per MODELS_LOCK.
- **API retry**: `MAX_RETRIES` default consigliato **3**; backoff esponenziale best‑practice.
- **Curl timeout**: usare `CURL_BASE_OPTS` per impostare `--max-time` coerente con retry.

### Contratto firma provider
- **Obiettivo**: garantire che il modulo provider non sia stato modificato dopo il sourcing.
- **Meccanismo**:
  - Calcolare firma file prima del `source` con `getfile_signature` (sha256).
  - `bash -n` per validazione sintattica.
  - `source` in subshell controllata.
  - Ricalcolare firma e confrontare; mismatch → fail‑fast.
- **Requisiti file**: non symlink, owner utente, permessi 600, non world‑writable.

### Indice funzioni helper (sintetico)
- **Bootstrap / sicurezza**: `resolve_script_dir`, `ensure_config_dir`, `atomic_write`, `_mktemp_in_dir`, `lock_exec`, `ensure_run_tmpdir`, `ui_state_write`, `getfile_signature`.
- **Base64 / staging**: `b64encode`, `b64decode`, `b64_atomic_write`, `b64_atomic_read`, `stage_b64`.
- **JSON / validation**: `is_valid_json_string`, `is_valid_json_file`, `jq_safe`, `extract_text_from_resp`.
- **Session / history**: `save_to_history`, `rotate_history`, `manifest_create`, `manifest_add_part`, `session_append`, `session_read_window`, `session_cache_*`.
- **Provider dispatch**: `load_provider_module`, `validate_provider_interface`, `call_provider`, `refresh_models_dispatch`, `resolve_provider_url`, `ensure_api_key_for_provider`.
- **Core orchestration**: `resolve_model`, `build_payload_from_vars`, `call_api_once`, `call_api_streaming`, `perform_request_once`, `finalize_and_output`, `detect_empty_edge_case`.

### Runbook operativo minimo
- **Installazione prerequisiti**: assicurare `bash`, `coreutils`, `findutils`, `util‑linux`, `gawk`, `curl`, `jq` nel PATH.
- **Posizionamento**: collocare `groqbash` e `groqbash.d/` nello stesso owner; verificare permessi 700 per dir e 600 per file.
- **Configurazione iniziale**:
  1. Impostare `GROQBASH_CONFIG_DIR` se non default.
  2. Posizionare provider modules in `PROVIDERS_DIR` con permessi 600.
  3. Esportare `GROQ_API_KEY` o usare `ensure_api_key_for_provider` in modalità interattiva.
- **Esecuzione diagnostica**:
  - `--print-config-dir`, `--print-provider-file`, `--list-providers`, `--list-models` per verifiche non distruttive.
- **Aggiornamento modelli**:
  - Eseguire refresh modelli tramite `refresh_models_dispatch`; verificare MODELS_FILE e permessi.
- **Recupero errori**:
  - Lock timeout 124 → verificare processi concorrenti e rimuovere lock stale solo se sicuri.
  - Firma provider mismatch → ripristinare modulo da fonte fidata.
  - RESP diagnostico → controllare `resp.raw` e `curl.err` nel RUN_TMPDIR.
- **Backup e pulizia**:
  - Eseguire backup periodico di `GROQBASH_CONFIG_DIR` e `GROQBASH_HISTORY_DIR`.
  - Monitorare dimensione MODELS_FILE e history; regolare `GROQBASH_HISTORY_*` e `MAX_MODELS`.

---

Documento concepito come specifica architetturale completa e leggibile da LLM per analisi, verifica e future implementazioni senza accesso al codice sorgente.
