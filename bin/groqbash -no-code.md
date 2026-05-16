## groqbash senza codice — Documento architetturale unificato

### 1 Panoramica globale del sistema
**Descrizione sintetica**  
GroqBash è un singolo script Bash, auto‑contenuto e auditabile, che fornisce un wrapper CLI sicuro per l’API Chat Completions compatibile OpenAI di Groq. Lo script opera in ambienti Unix like e si basa esclusivamente su strumenti obbligatori presenti nel PATH. GroqBash centralizza sicurezza, atomicità e portabilità per costruzione payload, chiamate HTTP streaming e non streaming, gestione modelli, sessioni, history e provider.

**Principi guida**  
- Sicurezza by design con permessi restrittivi e nessun uso di eval.  
- Atomicità per tutte le scritture critiche tramite staging e mv atomico.  
- Nessun uso del /tmp di sistema per tmp principali.  
- Fail fast su condizioni critiche, best effort per metadata non critici.  
- Single user trust model: l’utente controlla le directory usate.

---

### 2 Invarianti e modello mentale
**Invarianti globali**  
- Directory canoniche esistono e hanno permessi 700, file sensibili 600.  
- RUN_TMPDIR creato solo tramite ensure_run_tmpdir e rimosso a EXIT salvo debug preserve.  
- Nessuna esecuzione di contenuti provenienti da API o extras.  
- Tutte le operazioni concorrenti critiche usano lock con timeout.  
- Dopo ogni chiamata provider esiste un file RESP utile, reale o diagnostico.

**Modello mentale per progettisti e revisori**  
- Trattare GroqBash come un insieme di primitive sicure e orchestratori: PRECORE_BOOT fornisce l’ambiente e gli helper atomici, PRECORE_RUN gestisce runtime persistente e sessioni, PROVIDER implementa l’integrazione API, CORE_SETUP orchestra il flusso CLI e request, CORE_PROVIDER gestisce discovery e persistenza del provider.  
- Ogni scrittura persistente è atomicizzata; ogni operazione concorrente è protetta da lock; ogni chiamata di rete è delegata e soggetta a policy centrale.  
- Variabili d’ambiente sono configurazione fidata, non input non attendibile.

---

### 3 Dipendenze tra macro sezioni
**Relazioni principali**  
- PRECORE_BOOT è prerequisito per tutte le altre sezioni. Fornisce helper atomici, risoluzione percorsi, enforce_network_policy e caricamento sicuro dei moduli provider.  
- PRECORE_RUN usa helper di PRECORE_BOOT per tmp, lock e atomic write e fornisce sessioni, history e manifest usati da CORE_SETUP e PROVIDER.  
- CORE_PROVIDER gestisce selezione e persistenza del provider e invoca load_provider_module implementato in PRECORE_BOOT.  
- PROVIDER implementa buildpayload, call_api e refresh_models e si appoggia a ensure_run_tmpdir e primitive di PRECORE_RUN e PRECORE_BOOT.  
- CORE_SETUP orchestra dispatch verso PROVIDER e usa PRECORE_RUN per history, sessioni e salvataggio output.

**Dipendenze funzionali chiave**  
- `ensure_run_tmpdir`, `atomic_write`, `lock_exec` sono forniti da PRECORE_BOOT e consumati da PRECORE_RUN, PROVIDER e CORE_SETUP.  
- `load_provider_module` è implementato in PRECORE_BOOT e invocato da CORE_PROVIDER e CORE_SETUP.  
- `refresh_models_<prov>` e `buildpayload_<prov>` sono forniti dal modulo provider e invocati da CORE_SETUP.

---

### 4 Flusso di esecuzione end to end
1. **Bootstrap PRECORE_BOOT**  
   - Verifica comandi obbligatori e PATH.  
   - Risolve SCRIPTDIR e directory canoniche.  
   - Crea e protegge GROQBASH_CONFIG_DIR, GROQBASH_MODELS_DIR, GROQBASH_TMPDIR con permessi restrittivi.  
   - Prepara helper atomici e policy di rete.

2. **Selezione provider CORE_PROVIDER**  
   - Popola SUPPORTED_PROVIDERS da builtin e PROVIDERS_DIR.  
   - Applica persisted provider salvo override CLI.  
   - Valida interfaccia provider e carica modulo con load_provider_module.  
   - Risolve GROQBASH_PROVIDER_URL e assicura API key se necessario.

3. **Inizializzazione runtime PRECORE_RUN**  
   - ensure_run_tmpdir crea RUN_TMPDIR e installa trap di cleanup.  
   - Inizializza history, manifest e cache directories con permessi corretti.

4. **Risoluzione modello e costruzione payload CORE_SETUP**  
   - Normalizza flag CLI e carica config locale.  
   - Risolve FINAL_MODEL tramite resolve_model con possibili refresh modelli.  
   - Invoca build_payload_from_vars che delega a buildpayload_<PROVIDER>.

5. **Esecuzione richiesta e gestione risposta PROVIDER + CORE_SETUP**  
   - enforce_network_policy valuta permessi di rete.  
   - call_api_once o call_api_streaming eseguono la chiamata tramite curl.  
   - Streaming emesso su stdout in modo sicuro; aggregazione chunk in file temporanei.  
   - RESP finale scritto sempre, valido o diagnostico.

6. **Finalizzazione CORE_SETUP + PRECORE_RUN**  
   - extract_text_from_resp estrae testo; detect_empty_edge_case popola diagnostica.  
   - finalize_and_output emette output e salva su history se supera soglia.  
   - Pulizia RUN_TMPDIR salvo DEBUG_PRESERVE.

---

### 5 Sezioni principali

#### PRECORE_BOOT
**Scopo**  
Inizializzare ambiente, validare requisiti, normalizzare percorsi e fornire helper atomici e policy di sicurezza.

**Responsabilità**  
- Fail fast su comandi obbligatori mancanti.  
- Risoluzione SCRIPTDIR e canonical paths.  
- Creazione e protezione directory e file canonici.  
- Fornitura di helper atomici: atomic_write, b64_atomic_write, _mktemp_in_dir, lock_exec.  
- Caricamento sicuro dei moduli provider e scrittura provider_capabilities.

**Dipendenze**  
- ENV letti: GROQBASH_DIR, GROQBASH_CONFIG_DIR, PROVIDERS_DIR, GROQBASH_TMPDIR, DEBUG, DRY_RUN, GROQBASH_LOCK_TIMEOUT_*.  
- Comandi obbligatori: bash, coreutils, findutils, util-linux, gawk, curl, jq.

**API esposta rilevante**  
- resolve_script_dir  
- canonical_config_dir, canonical_provider_file, canonical_model_file, canonical_provider_url_file  
- provider_api_env_var_name  
- ensure_api_key_for_provider  
- enforce_network_policy  
- ensure_config_dir  
- write_provider_url_if_missing  
- is_valid_json_string, is_valid_json_file, jq_safe  
- b64encode, b64decode, b64_atomic_write, b64_atomic_read, stage_b64  
- lock_exec, _mktemp_in_dir, atomic_write  
- extract_text_from_resp  
- ensure_run_tmpdir, cleanup_run_tmp_on_exit, cleanup_tmp  
- ui_state_write  
- load_provider_module

**Side effect principali**  
- Creazione di SCRIPTDIR, GROQBASH_DIR, GROQBASH_CONFIG_DIR, GROQBASH_MODELS_DIR, GROQBASH_TMPDIR.  
- Impostazione variabili: RUN_TMPDIR, MODELS_LOCK, HISTORY_LOCK, B64_WRAP_OPT, B64_DECODE_OPT.  
- Scrittura provider_capabilities.json e provider-url file.

**Flussi principali**  
- Bootstrap normale: verifica comandi, crea dir, setta opzioni base64 e lock names.  
- Flag --print-*: stampa percorsi canonici e exit.  
- Caricamento provider: verifica permessi, bash -n, source sicuro, verifica funzioni richieste.

---

#### PRECORE_RUN
**Scopo**  
Primitive runtime atomiche e portabili per history, manifest multimodale, tmp, sessioni e cache.

**Responsabilità**  
- Gestione history con rotazione atomica.  
- Creazione e aggiornamento manifest JSON e staging base64.  
- Session engine: validazione id, append idempotente, lettura finestra, cache sessione.  
- Utility permessi e firma file.

**Dipendenze**  
- ENV letti: GROQBASH_HISTORY_DIR, GROQBASH_TMPDIR, RUN_TMPDIR, SESSION_DIR, GROQBASH_LOCK_TIMEOUT_*.  
- Funzioni esterne: lock_exec, ui_state_write, ensure_run_tmpdir, b64encode, b64decode, file_size, is_truthy, log_*  
- Comandi esterni: jq, mktemp, stat, find, grep, awk, sed, tail, sort, head, mv, cp, chmod, rm, mkdir, flock, date, sha256sum or openssl.

**API esposta rilevante**  
- rotate_history, save_to_history  
- manifest_create, manifest_add_part, manifest_read  
- _get_perm_string, _get_owner, _get_file_signature, getfile_signature, _is_world_writable  
- make_tmpdir, _tmpf  
- session_validate_id, session_now_ts, session_messages_tmp_path, session_sanitize_cmd  
- session_read_window, session_append  
- session_cache_key, session_cache_get, session_cache_set, session_cache_invalidate

**Side effect principali**  
- File history atomici, manifest JSON e .b64, session NDJSON, cache files.  
- Lockfile per history e tmp.  
- Aggiornamento ui_state best effort.

**Flussi principali**  
- save_to_history scrive atomico e invoca rotate_history sotto HISTORY_LOCK.  
- manifest_create e manifest_add_part gestiscono parti multimodali con staging base64.  
- session_append garantisce idempotenza tramite marker dir e flock.  
- session_cache_* gestisce TTL e invalidazione atomica.

---

#### PROVIDER groq
**Scopo**  
Implementare integrazione con API OpenAI compatible Groq: costruzione payload, chiamate HTTP streaming e non streaming, gestione modelli.

**Responsabilità**  
- Costruzione payload con buildpayload_groq.  
- Chiamata non streaming con call_api_groq.  
- Streaming SSE con call_api_streaming_groq.  
- Refresh e normalizzazione modelli con refresh_models_groq.  
- Validazione e auto selezione modello.

**Dipendenze**  
- ENV letti: GROQ_API_KEY, PROVIDER_API_ENV_groq, GROQBASH_PROVIDER_URL, MODELS_FILE, RUN_TMPDIR, CURL_BASE_OPTS, STREAM_MODE.  
- Helper esterni: ensure_run_tmpdir, _mktemp_in_dir, is_truthy, is_valid_json_*, b64decode, stage_b64, b64_atomic_write, lock_exec, resolve_provider_url, is_supported_model, ui_state_write, log_*.

**API esposta rilevante**  
- buildpayload_groq / buildpayloadgroq  
- call_api_groq  
- call_api_streaming_groq / call_api_streaming_groq_legacy  
- refresh_models_groq / refreshmodelsgroq  
- validate_model_groq / validatemodelgroq  
- auto_select_model_groq / autoselectmodelgroq

**Side effect principali**  
- Creazione di payload file, decoded payload temporanei, resp.raw, resp.lines, resp.valid.jsons, resp.chunks.json, resp.text.txt, resp.json.  
- Scrittura MODELS_FILE atomico e last_api.json via ui_state_write.  
- Emissione streaming su stdout e log diagnostici su stderr.

**Flussi principali**  
- Costruzione payload, enforce_network_policy, call_api_groq, validazione JSON, scrittura RESP.  
- Streaming: parsing conservativo di data lines, stampa incrementale, aggregazione chunk e scrittura RESP.  
- Refresh modelli: fetch /openai/v1/models, parse jq, b64_atomic_write sotto lock.

---

#### CORE_SETUP
**Scopo**  
Orchestrare stato CLI e runtime, risolvere modello, dispatch verso provider, gestire retry e finalizzazione output.

**Responsabilità**  
- Normalizzazione flag e config.  
- Risoluzione FINAL_MODEL con resolve_model.  
- Dispatch dinamico verso funzioni provider.  
- Wrapper di chiamata API con retry e gestione edge cases.  
- Estrazione testo e salvataggio output lungo.

**Dipendenze**  
- ENV letti: MODEL, PROVIDER, DRY_RUN, STREAM_MODE, MODELS_FILE, GROQBASH_CONFIG_DIR, RUN_TMPDIR, THRESHOLD, GROQBASH_HISTORY_DIR.  
- Funzioni esterne: call_provider, ensure_run_tmpdir, is_truthy, canonical_* helpers, is_valid_json_file, extract_text_from_resp, ui_state_write, save_to_history, atomic_write, session engine functions, log_*.

**API esposta rilevante**  
- call_provider  
- refresh_models_dispatch  
- validate_model_dispatch  
- auto_select_model_dispatch  
- resolve_model  
- build_payload_from_vars  
- call_api_once, call_api_streaming  
- extract_api_error, detect_empty_edge_case  
- finalize_and_output  
- perform_request_once  
- list_models_cli, validate_model_core, load_local_config, load_whitelist, is_tty_out

**Side effect principali**  
- Impostazione FINAL_MODEL, MODEL_PROVIDER_CFG, normalized flags.  
- Scrittura fallback ui_state/last_api.json e history files.  
- Emissione stdout/stderr e exit codes coerenti.

**Flussi principali**  
- Bootstrap CLI, load config, resolve_model, build_payload_from_vars, perform_request_once che gestisce retry e chiama finalize_and_output.  
- Azioni immediate per list, set-default e install-extras con exit immediato.

---

#### CORE_PROVIDER
**Scopo**  
Scoperta, selezione, persistenza e validazione del provider API; orchestrazione refresh modelli e comandi diagnostici.

**Responsabilità**  
- Popolare SUPPORTED_PROVIDERS e applicare persisted provider.  
- Validare interfaccia provider e caricare modulo con load_provider_module.  
- Risolvere e persistere GROQBASH_PROVIDER_URL e provider persist file.  
- Innescare refresh modelli quando richiesto.

**Dipendenze**  
- ENV letti: PROVIDER, PROVIDER_CLI, REFRESH_MODELS, MODELS_FILE, DEBUG, DRY_RUN.  
- Helper: canonical_provider_file, canonical_provider_url_file, ensure_config_dir, atomic_write, load_provider_module, resolve_provider_url, ensure_api_key_for_provider, refresh_models_dispatch, log_*.

**API esposta rilevante**  
- validate_provider_interface(p)  
- load_provider_module(PROVIDER)  
- resolve_provider_url(PROVIDER)  
- ensure_api_key_for_provider(PROVIDER)  
- refresh_models_dispatch(MODELS_FILE)  
- write_provider_url_if_missing(provider, url)

**Side effect principali**  
- Impostazione PROVIDER, PROVIDER_INTERACTIVE_SELECTED, GROQBASH_PROVIDER_URL.  
- Scrittura atomica del provider persist file e possibile rimozione MODELS_FILE su cambio provider.  
- Output diagnostico su stdout/stderr.

**Flussi principali**  
- Applicazione persisted provider salvo override CLI, validazione e persistenza atomica, caricamento modulo, risoluzione URL, refresh modelli opzionale.

---

### 6 Glossario e convenzioni
**Termini chiave**  
- **RUN_TMPDIR** Directory temporanea per singola esecuzione creata tramite ensure_run_tmpdir.  
- **GROQBASH_TMPDIR** Directory temporanea persistente sotto GROQBASH_DIR.  
- **MODELS_FILE** File normalizzato contenente lista modelli recuperata dal provider.  
- **PAYLOAD / GROQBASH_TMP_PAYLOAD** File JSON del payload inviato all’API.  
- **RESP** File contenente la risposta aggregata o diagnostica.  
- **LOCK** File usato con flock tramite lock_exec per garantire atomicità.  
- **provider module** Script sotto PROVIDERS_DIR che espone buildpayload_<prov>, call_api_<prov>, refresh_models_<prov>.  
- **edge empty** Caso diagnostico in cui la completion è vuota e viene popolata diagnostica GROQBASH_EDGE_*.

**Convenzioni di sicurezza e permessi**  
- Directory 700, file 600.  
- Umask 077 per creazione tmp e file sensibili.  
- Nessun uso di eval o esecuzione automatica di output API.  
- Nessun tmp principale in /tmp di sistema.

**Codici di errore canonici**  
- Errori critici di bootstrap o sicurezza causano exit immediato con codici GROQBASH_ERR_*.  
- 127 per funzione provider mancante.  
- GROQBASHERRNOAPIKEY per assenza API key quando richiesta.  
- GROQBASHERRAPI per errori API generici.  
- GROQBASHERRTMP per errori tmp/I O.

**Linee guida per estensioni future**  
- Nuovi provider devono rispettare l’interfaccia obbligatoria buildpayload_<prov> e call_api_<prov> e passare validate_provider_interface.  
- Ogni nuova scrittura persistente deve usare atomic_write o b64_atomic_write e lock_exec.  
- Tutte le chiamate di rete devono passare per enforce_network_policy.

---

Documento completo e auto‑descrittivo per analisi, revisione e sviluppo futuro senza accesso al codice sorgente.
