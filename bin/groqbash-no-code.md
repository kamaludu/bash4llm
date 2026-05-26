{
  "compact_file_type": "groqbash_compact_no_code",
  "language": "it",
  "generated_from": "attached_document_aggregated",
  "expand_flags": ["fn", "vars", "cm"],
  "meta": {
    "name": "groqbash",
    "size_bytes": 191346,
    "sha256": "d5c92cd7637d5d0b78d65c37aaf4afae28be02f5307656b5b580a025dbf9ec4c",
    "line_count": 5033,
    "shebang": "#!/usr/bin/env bash",
    "author": "Cristian Evangelisti",
    "license": "GNU GPL v3+"
  },
  "note": "Questo file compatto non contiene codice sorgente. Sono incluse descrizioni estese di funzioni, variabili e mappatura del codice (code_map) come richiesto.",
  "functions_expanded": [
    {
      "name": "resolve_script_dir",
      "signature": "resolve_script_dir()",
      "purpose_it": "Restituisce la directory canonica dello script in esecuzione risolvendo eventuali symlink."
    },
    {
      "name": "canonical_config_dir",
      "signature": "canonical_config_dir()",
      "purpose_it": "Restituisce la directory di configurazione canonica senza slash finale."
    },
    {
      "name": "provider_api_env_var_name",
      "signature": "provider_api_env_var_name <prov>",
      "purpose_it": "Calcola il nome canonico della variabile d'ambiente per la chiave API del provider (es. GROQ_API_KEY)."
    },
    {
      "name": "ensure_api_key_for_provider",
      "signature": "ensure_api_key_for_provider <prov>",
      "purpose_it": "Garantisce la presenza della chiave API per il provider; prompt interattivo se necessario; fallisce in non-interattivo salvo DRY_RUN."
    },
    {
      "name": "enforce_network_policy",
      "signature": "enforce_network_policy()",
      "purpose_it": "Controllo centrale che impedisce chiamate HTTP quando DRY_RUN o GROQBASH_SKIP_NETWORK sono attivi; ritorna non-zero per bloccare la rete."
    },
    {
      "name": "log_info / log_warn / log_error",
      "signature": "log_info(code,msg); log_warn(code,msg); log_error(code,msg)",
      "purpose_it": "Helper per logging strutturato; rispettano DEBUG e l'eventuale file GROQBASH_LOG."
    },
    {
      "name": "b64encode / b64decode",
      "signature": "b64encode(); b64decode()",
      "purpose_it": "Wrapper portabili per base64 che normalizzano le opzioni tra piattaforme."
    },
    {
      "name": "stage_b64",
      "signature": "stage_b64 [src] dst",
      "purpose_it": "Legge payload (stdin o file), lo codifica in base64 e scrive in modo atomico un file di staging sotto RUN_TMPDIR o destdir con controlli di dimensione."
    },
    {
      "name": "lock_exec",
      "signature": "lock_exec <lockfile> <timeout> -- <command> [args...]",
      "purpose_it": "Acquisisce un lock esclusivo (flock) su lockfile con timeout ed esegue il comando in una subshell; fallisce chiaramente se flock non disponibile."
    },
    {
      "name": "_mktemp_in_dir",
      "signature": "_mktemp_in_dir <dir> [prefix]",
      "purpose_it": "Wrapper di compatibilità che delega a _tmpf per creare file temporanei sicuri in una directory."
    },
    {
      "name": "atomic_write",
      "signature": "atomic_write <dest> [timeout]",
      "purpose_it": "Scrive stdin in un file temporaneo e poi lo sposta in modo atomico in dest, opzionalmente sotto lock."
    },
    {
      "name": "extract_text_from_resp",
      "signature": "extract_text_from_resp()",
      "purpose_it": "Estrae contenuto testuale da RESP JSON usando euristiche jq; supporta più forme di risposta e gestione diagnostica."
    },
    {
      "name": "ensure_run_tmpdir",
      "signature": "ensure_run_tmpdir [--print]",
      "purpose_it": "Crea una run-specific temporary directory sotto GROQBASH_TMPDIR, imposta PAYLOAD/RESP/ERRF e installa il trap di cleanup."
    },
    {
      "name": "b64_atomic_write / b64_atomic_read",
      "signature": "b64_atomic_write <dest.b64> [timeout]; b64_atomic_read <src.b64>",
      "purpose_it": "Helper per scritture/letture atomiche base64 usando GROQBASH_TMPDIR e lock_exec per spostamenti sicuri."
    },
    {
      "name": "ui_state_write",
      "signature": "ui_state_write <relpath> <json-string>",
      "purpose_it": "Scrive lo stato UI JSON in modo atomico in $GROQBASH_CONFIG_DIR/ui_state con permessi restrittivi; non-fatal su errore."
    },
    {
      "name": "load_provider_module",
      "signature": "load_provider_module <provider>",
      "purpose_it": "Carica in sicurezza un modulo provider: controlli di sicurezza, sourcing in subshell isolata, importa solo definizioni di funzione e registra capacità in ui_state."
    },
    {
      "name": "_detect_base64_opts",
      "signature": "_detect_base64_opts()",
      "purpose_it": "Rileva opzioni base64 specifiche della piattaforma ed esporta B64_WRAP_OPT e B64_DECODE_OPT."
    },
    {
      "name": "list_files_sorted_by_mtime",
      "signature": "list_files_sorted_by_mtime <dir>",
      "purpose_it": "Elenca file con righe mtime|path ordinate ascendentemente (stat portabile)."
    },
    {
      "name": "tac_fallback",
      "signature": "tac_fallback <file>",
      "purpose_it": "Fallback portabile per invertire le righe di un file usando tac o awk."
    },
    {
      "name": "_file_mtime",
      "signature": "_file_mtime <file>",
      "purpose_it": "Restituisce la mtime di un file in secondi epoch (portabile)."
    },
    {
      "name": "jq_safe",
      "signature": "jq_safe <filter> <file>",
      "purpose_it": "Esegue jq con gestione errori e diagnostica opzionale scritta in ERRF."
    },
    {
      "name": "_cleanup_local_tmp",
      "signature": "_cleanup_local_tmp(tmp_payload, tmp_b64_local, json_input_file)",
      "purpose_it": "Rimuove file temporanei locali (payload, staged b64, file json) per evitare artefatti."
    },
    {
      "name": "buildpayload_groq",
      "signature": "buildpayload_groq()",
      "purpose_it": "Costruisce e valida il payload JSON per chiamate al provider Groq; supporta staging base64 e imposta variabili globali PAYLOAD/GROQBASH_TMP_PAYLOAD."
    },
    {
      "name": "call_api_groq",
      "signature": "call_api_groq()",
      "purpose_it": "Esegue chiamata HTTP non-streaming con curl; gestisce decoding .b64, verifica API key, applica policy di rete e salva RESP e diagnostica."
    },
    {
      "name": "call_api_streaming_groq",
      "signature": "call_api_streaming_groq()",
      "purpose_it": "Esegue chiamata streaming, legge chunk 'data:' dal flusso, estrae contenuto incrementale e costruisce RESP JSON finale; gestisce errori e diagnostica."
    },
    {
      "name": "refresh_models_groq",
      "signature": "refresh_models_groq()",
      "purpose_it": "Scarica la lista modelli dall'API provider, normalizza i nomi e salva MODELS_FILE in modo atomico; fallisce se chiave API mancante o risposta non valida."
    },
    {
      "name": "validate_model_groq",
      "signature": "validate_model_groq(model)",
      "purpose_it": "Verifica la presenza del modello in MODELS_FILE (se esistente) e che sia supportato; normalizza prefissi per confronto."
    },
    {
      "name": "auto_select_model_groq",
      "signature": "auto_select_model_groq()",
      "purpose_it": "Scorre MODELS_FILE e restituisce il primo modello supportato (normalizzato)."
    },
    {
      "name": "validate_provider_interface",
      "signature": "validate_provider_interface(p)",
      "purpose_it": "Verifica che il modulo provider definisca le funzioni richieste e opzionali; segnala errori e ritorna stato."
    },
    {
      "name": "resolve_provider_url",
      "signature": "resolve_provider_url(provider)",
      "purpose_it": "Risoluzione dell'URL del provider seguendo la precedenza ENV > provider-url file > embedded default."
    },
    {
      "name": "session_engine_build_window",
      "signature": "session_engine_build_window(session_id, window, target_bytes, out_file)",
      "purpose_it": "Costruisce il file JSON delle messages per la sessione; preferisce engine dedicato, legacy come fallback."
    },
    {
      "name": "session_engine_append",
      "signature": "session_engine_append(session_id, role, content, meta_json)",
      "purpose_it": "Appende messaggi alla sessione; usa engine preferito o fallback legacy; usato per user e assistant."
    }
  ],
  "variables_expanded": [
    {
      "name": "SCRIPT_NAME / SCRIPT_VERSION / SCRIPT_DATE",
      "value": "groqbash / 2.0.0 / 2026-05-07",
      "purpose_it": "Identificativi dello script e versione."
    },
    {
      "name": "DEBUG / GROQBASH_LOG",
      "value": "DEBUG default 0; GROQBASH_LOG percorso opzionale per log strutturati",
      "purpose_it": "Controllo diagnostica e destinazione log."
    },
    {
      "name": "MODELS_FILE / MAX_MODELS",
      "value": "MODELS_FILE default $GROQBASH_MODELS_DIR/models.txt; MAX_MODELS default 200",
      "purpose_it": "File dove vengono salvati i modelli e limite massimo di modelli memorizzati."
    },
    {
      "name": "LOCK files and timeouts",
      "value": "MODELS_LOCK, HISTORY_LOCK, TMP_LOCK; GROQBASH_LOCK_TIMEOUT_TMP, GROQBASH_LOCK_TIMEOUT_MODELS, GROQBASH_LOCK_TIMEOUT_HISTORY",
      "purpose_it": "Variabili per lock e timeout usate nelle operazioni atomiche."
    },
    {
      "name": "RUN_TMPDIR / PAYLOAD / RESP / ERRF",
      "value": "Run-specific tempdir e percorsi canonici per payload/response/error sotto RUN_TMPDIR",
      "purpose_it": "Percorsi temporanei per singola esecuzione."
    },
    {
      "name": "B64_WRAP_OPT / B64_DECODE_OPT",
      "value": "Opzioni base64 rilevate dalla piattaforma esportate da _detect_base64_opts",
      "purpose_it": "Parametri portabili per codifica/decodifica base64."
    },
    {
      "name": "GROQ_API_KEY",
      "value": "Chiave API provider Groq (può essere sovrascritta da PROVIDER_API_ENV_groq)",
      "purpose_it": "Credenziale principale per il provider groq."
    },
    {
      "name": "PROVIDER_API_ENV_groq",
      "value": "Nome della variabile d'ambiente opzionale che contiene la chiave API per groq",
      "purpose_it": "Alias per la variabile d'ambiente provider-specifica."
    },
    {
      "name": "GROQBASH_API_KEY",
      "value": "Chiave API alternativa usata se GROQ_API_KEY non è impostata",
      "purpose_it": "Fallback generico per chiave API."
    },
    {
      "name": "MODEL / FINAL_MODEL",
      "value": "MODEL è il modello richiesto; FINAL_MODEL è il risultato di resolve_model() prima della validazione finale",
      "purpose_it": "Controllo del modello attivo."
    },
    {
      "name": "TURE",
      "value": "Parametro temperature (stringa numerica), validato e convertito in numero per jq",
      "purpose_it": "Controllo della temperatura di generazione."
    },
    {
      "name": "MAX_TOKENS",
      "value": "Massimo numero di token; validato e convertito in numero per jq",
      "purpose_it": "Limite token per la richiesta."
    },
    {
      "name": "STREAM_MODE",
      "value": "Flag che determina se il payload deve impostare stream=true",
      "purpose_it": "Controllo modalità streaming."
    },
    {
      "name": "JSON_INPUT / MESSAGES_JSON / BUILD_MESSAGES_FILE / CONTENT",
      "value": "Variabili di input usate per costruire il payload secondo la priorità definita",
      "purpose_it": "Fonti di contenuto per il payload."
    },
    {
      "name": "GROQBASH_PROVIDER_URL",
      "value": "URL del provider risolto (usato per costruire api_url e per le chiamate)",
      "purpose_it": "Endpoint effettivo usato per le chiamate API."
    },
    {
      "name": "MODELS_FILE / MODELS_LOCK / MAX_MODELS",
      "value": "File e lock per la lista modelli e limite massimo di modelli salvati",
      "purpose_it": "Gestione persistente della lista modelli."
    },
    {
      "name": "RESP",
      "value": "Percorso del file di risposta JSON dove vengono scritte le risposte/diagnostiche",
      "purpose_it": "File di output JSON della chiamata."
    },
    {
      "name": "SE_AVAILABLE / SE_ENGINE_PATH",
      "value": "Contesto per il Session Engine opzionale; SE_AVAILABLE indica preferenza engine",
      "purpose_it": "Configurazione per engine di sessione alternativo."
    },
    {
      "name": "STREAM_MODE / CHAT_MODE / BATCH_FILE / DRY_RUN / DEBUG / QUIET",
      "value": "Flag di controllo del flusso: modalità streaming, chat interattiva, batch, dry-run, debug e quiet",
      "purpose_it": "Controlli di esecuzione e modalità."
    },
    {
      "name": "GROQBASH_ROTATE_HISTORY / GROQBASH_HISTORY_MAX_FILES / GROQBASH_HISTORY_MAX_BYTES / GROQBASH_HISTORY_KEEP_DAYS",
      "value": "Parametri di history e rotazione (max files, max bytes, keep days)",
      "purpose_it": "Configurazione per rotazione della cronologia."
    },
    {
      "name": "CURL_BASE_OPTS",
      "value": "Opzioni base per curl usate dall'applicazione",
      "purpose_it": "Opzioni conservative per invocazioni curl (es. --silent --show-error --no-buffer --max-time 120)."
    }
  ],
  "code_map_expanded": [
    {
      "item": "Precore boot setup and env checks",
      "description_it": "Impostazioni iniziali (set -euo pipefail), verifica comandi obbligatori e variabili d'ambiente critiche."
    },
    {
      "item": "Config and runtime directory derivation and validation",
      "description_it": "Derivazione e validazione di GROQBASH_DIR, GROQBASH_TMPDIR e invarianti relativi ai tmp."
    },
    {
      "item": "API key handling and provider URL resolution",
      "description_it": "Gestione chiavi API (prompt, alias GROQBASH_API_KEY/GROQ_API_KEY) e risoluzione URL provider (ENV > file > default)."
    },
    {
      "item": "Atomic file helpers and staging",
      "description_it": "Helper atomici per scritture, stage base64, atomic_write, b64_atomic_write/read e lock per movimenti sicuri."
    },
    {
      "item": "Run tmpdir lifecycle and cleanup trap",
      "description_it": "Creazione di RUN_TMPDIR per esecuzione, impostazione PAYLOAD/RESP/ERRF e trap di pulizia; permessi restrittivi."
    },
    {
      "item": "Provider safe-load and capability reporting",
      "description_it": "Caricamento sicuro dei moduli provider in subshell, importazione solo di funzioni e report delle capacità in ui_state."
    },
    {
      "item": "Portable utilities",
      "description_it": "Utility portabili: rilevamento opzioni base64, gestione mtime file, tac fallback, jq_safe."
    },
    {
      "item": "rotate_history, save_to_history, manifest_*",
      "description_it": "Funzionalità per rotazione della history, salvataggio atomico e manifest multimodale con staging base64."
    },
    {
      "item": "_get_perm_string and tmp helpers",
      "description_it": "Primitive per permessi, signature file, creazione sicura di tmpdir e _tmpf."
    },
    {
      "item": "session_* helpers",
      "description_it": "Gestione sessioni NDJSON: validate_id, now_ts, messages_tmp_path, read_window, append idempotente."
    },
    {
      "item": "session_cache_* and _session_hash",
      "description_it": "Cache di sessione con prima riga expiry epoch e payload; scritture atomiche e rimozione scaduti."
    },
    {
      "item": "Provider-specific payload and API calls",
      "description_it": "buildpayload_groq, call_api_groq, call_api_streaming_groq, refresh_models_groq: costruzione payload, chiamate streaming/non-streaming e refresh modelli."
    },
    {
      "item": "CORE_SETUP dispatch and request flow",
      "description_it": "Dispatch verso implementazioni provider-specifiche, resolve_model, perform_request_once, finalize_and_output e wrapper DRY_RUN."
    },
    {
      "item": "CORE_SETUP CLI and extras",
      "description_it": "Parsing CLI, installazione atomica di extras e caricamento opzionale del Session Engine."
    },
    {
      "item": "Provider discovery and flows",
      "description_it": "Scoperta e selezione provider, provider-url default, validazione interfaccia, assemble_content, batch/chat/streaming flows e session handling."
    }
  ],
  "defs_summary": [
    {
      "title_it": "Codici di errore canonici",
      "value": "GROQBASH_ERR_* (es. NO_API_KEY=10, BAD_MODEL=11, CURL_FAILED=12, INVALID_JSON=13, NO_PROMPT=14, TMP=15, API=16)"
    },
    {
      "title_it": "Variabili layout directory",
      "value": "GROQBASH_DIR, GROQBASH_CONFIG_DIR, GROQBASH_MODELS_DIR, GROQBASH_TEMPLATES_DIR, GROQBASH_HISTORY_DIR, GROQBASH_TMPDIR, GROQBASH_EXTRAS_DIR, PROVIDERS_DIR"
    },
    {
      "title_it": "Provider contract (safe-load)",
      "value": "Provider deve esporre buildpayload_<prov> e call_api_<prov>; opzionali: call_api_streaming_<prov>, refresh_models_<prov>, validate_model_<prov>, auto_select_model_<prov>."
    },
    {
      "title_it": "Tmpfile/tmpdir policy",
      "value": "Creazione sicura tramite _tmpf; GROQBASH_TMPDIR come perimetro canonico; umask 077; permessi restrittivi; rifiuto symlink."
    },
    {
      "title_it": "Assemble content",
      "value": "assemble_content costruisce CONTENT da JSON_INPUT, FILE_INPUTS, TEMPLATE, STDIN o ARGS; preserva newline quando sostituisce {{CONTENT}}."
    }
  ],
  "operational_highlights_it": {
    "os_target": ["Linux", "macOS", "WSL", "Cygwin", "Termux", "BSD"],
    "bash_version_min": ">=4.0",
    "dependencies_minime": ["bash", "coreutils", "findutils", "util-linux", "gawk", "curl", "jq"],
    "tmp_policy_summary": "GROQBASH_TMPDIR deve essere dentro GROQBASH_DIR; /tmp non è consentito per tmp interni; permessi 700/600; uso di _tmpf e lock per operazioni atomiche."
  },
  "security_and_risks_it": [
    "Dipendenza da utilità esterne (curl, jq, gawk): assenza di fallback.",
    "Gestione chiavi API: prompting interattivo; in non-interattivo mancanza di chiave causa fallimento rapido salvo DRY_RUN.",
    "Permessi e atomicità: uso estensivo di temp file + mv + lock per evitare leakage di credenziali e race condition.",
    "No eval: lo script evita l'esecuzione di risposte API."
  ],
  "file_summary_it": "groqbash è un orchestratore bash per chiamate a provider LLM (default 'groq'). Fornisce ambiente sicuro, helper atomici per file e base64, gestione sessioni NDJSON e history con rotazione, costruzione payload da molteplici input e supporto per chiamate streaming e non-streaming con diagnostica robusta. Il caricamento dei provider è isolato in subshell e l'interfaccia provider è formalizzata; la risoluzione del modello segue una priorità multilivello.",
  "outputs_list": [
    "groqbash.d/history",
    "GROQBASH_TMP_PAYLOAD",
    "RESP",
    "ERRF",
    "MODELS_FILE",
    "session cache files",
    "last_history.json",
    "provider-url file (per groq se mancante)"
  ],
  "generation_notes_it": "Ho espanso le sezioni richieste (funzioni, variabili, code_map) mantenendo l'assenza di codice sorgente come richiesto. Se desideri un formato diverso (YAML, Markdown strutturato, o un file compatto con ulteriori campi), indicami il formato preciso e lo genererò.",
  "lossy": false
}
