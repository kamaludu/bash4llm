# SPECIFICA DELL'ARCHITETTURA E DELLA LOGICA DI BASH4LLM⁺ (v2.8.5.3)

Questo documento descrive in modo esaustivo, deterministico e senza perdita di informazioni la logica, le variabili, le funzioni e i blocchi strutturali del sistema **Bash4LLM⁺**, suddivisi secondo le cinque macro-sezioni piatte e allineati al codice sorgente della versione **2.8.5.3 (2026-08-16)**.

---

## 1. PRECORE_BOOT

### VARIABILI

* `SCRIPT_NAME`: Nome identificativo del programma (impostato a `"bash4llm"`).
* `SCRIPT_VERSION`: Versione corrente del software (impostata a `"2.8.5.3"`).
* `SCRIPT_DATE`: Data ufficiale di rilascio dello script (impostata a `"2026-08-16"`).
* `BASH4LLM_SUPPORTED_PROVIDER_API`: Versione del contratto d'interfaccia API supportata dal core per i moduli provider (valore numerico `1`, esportata nell'ambiente).
* `BASH4LLM_PLAT_ANDROID`: Flag di ambiente (`1` o `0`) impostato all'avvio: indica se l'esecuzione avviene sotto ambiente Android/Termux.
* `BASH4LLM_PLAT_MACOS`: Flag di ambiente (`1` o `0`) impostato all'avvio: indica se l'esecuzione avviene sotto sistema macOS/Darwin.
* `BASH4LLM_PLAT_WSL`: Flag di ambiente (`1` o `0`) impostato all'avvio: indica se l'esecuzione avviene sotto Windows Subsystem for Linux (WSL).
* `BASH4LLM_PLAT_CYGWIN`: Flag di ambiente (`1` o `0`) impostato all'avvio: indica se l'esecuzione avviene sotto ambienti Windows compatibili Cygwin, MSYS2 o MinGW.
* `BASH4LLM_PLAT_BSD`: Flag di ambiente (`1` o `0`) impostato all'avvio: indica se l'esecuzione avviene sotto sistemi FreeBSD, OpenBSD, NetBSD o DragonFly.
* `BASH4LLM_PLAT_LINUX`: Flag di ambiente (`1` o `0`) impostato all'avvio: indica se l'esecuzione avviene sotto ambiente Linux generico o WSL.
* `BASH4LLM_KEY_MANUAL_PROMPT`: Flag di stato interno (`1` o `0`) per tracciare se una chiave API è stata inserita manualmente dall'utente via prompt interattivo TTY, con hard reset iniziale a `0` per prevenire leakage di variabili d'ambiente.
* `VALIDATE_SML`: Flag di controllo (`1` o `0`, default `0`) per l'attivazione della validazione sintattica dello standard SML v2.0 sulle risposte LLM.
* `VALIDATE_REGEX`: Stringa contenente l'espressione regolare POSIX ERE per la validazione della risposta estratta (default vuoto).
* `SANITIZE_OUTPUT`: Flag di controllo (`1` o `0`, default `0`) per l'attivazione della sanificazione ANSI e caratteri di controllo speciali sul testo finale.
* `JSON_DIAGNOSTICS`: Flag di controllo (`1` o `0`, default `0`) per l'emissione della diagnostica di errore in formato JSON strutturato su standard error.
* `BASH4LLM_MODEL_CACHE`: Array associativo interno adibito ad archiviare in memoria i nomi dei modelli normalizzati per velocizzare le esecuzioni successive e bypassare sotto-shell o regex ripetute.
* `C_LOGO`: Sequenza di escape ANSI per lo stile grafico del logo dell'applicazione (sfondo verde, testo bianco in grassetto), disattivata in modalità `NO_COLOR` o terminale `dumb`.
* `C_BANNER`: Sequenza di escape ANSI per il banner dell'applicazione (sfondo blu, testo bianco in grassetto), disattivata in modalità `NO_COLOR` o terminale `dumb`.
* `C_RST`: Sequenza di escape ANSI di reset per ripristinare gli stili e i colori predefiniti del terminale.
* `C_BOLD`, `C_NOBOLD`: Sequenze di escape ANSI per attivare e disattivare la formattazione in grassetto del testo.
* `C_UNDERLINE`, `C_NOUNDERLINE`: Sequenze di escape ANSI per attivare e disattivare la sottolineatura del testo.
* `C_BLACK`, `C_RED`, `C_GREEN`, `C_YELLOW`, `C_BLUE`, `C_MAGENTA`, `C_CYAN`, `C_WHITE`: Sequenze di escape ANSI per i colori del testo in modalità normale.
* `C_BBLACK`, `C_BRED`, `C_BGREEN`, `C_BYELLOW`, `C_BBLUE`, `C_BMAGENTA`, `C_BCYAN`, `C_BWHITE`: Sequenze di escape ANSI per i colori del testo in modalità ad alta intensità o grassetto.
* `BG_BLACK`, `BG_RED`, `BG_GREEN`, `BG_YELLOW`, `BG_BLUE`, `BG_MAGENTA`, `BG_CYAN`, `BG_WHITE`: Sequenze di escape ANSI per i colori di sfondo del terminale.
* `BASH4LLM_ERR_NO_API_KEY`: Costante numerica di errore (valore `10`) associata alla mancanza di una chiave API.
* `BASH4LLM_ERR_BAD_MODEL`: Costante numerica di errore (valore `11`) associata alla richiesta di un modello non valido o non supportato.
* `BASH4LLM_ERR_CURL_FAILED`: Costante numerica di errore (valore `12`) associata al fallimento della chiamata di rete cURL.
* `BASH4LLM_ERR_PARSE`: Costante numerica di errore (valore `13`) associata a fallimenti di parsing JSON o errori sintattici.
* `BASH4LLM_ERR_NO_PROMPT`: Costante numerica di errore (valore `14`) associata alla mancanza di un prompt di input.
* `BASH4LLM_ERR_TMP`: Costante numerica di errore (valore `15`) associata a problemi del file-system temporaneo, permessi non validi o gestione dei file di lock.
* `BASH4LLM_ERR_API`: Costante numerica di errore (valore `16`) associata a risposte d'errore o codici HTTP non validi restituiti dal provider API.
* `BASH4LLM_ERR_SEC`: Costante numerica di errore (valore `17`) associata a violazioni della policy di sicurezza, permessi errati sul file-system o fallimento della verifica di integrità SHA-256 dei moduli.
* `BASH4LLMERR_NO_API_KEY`: Mappatura alias diretta del valore di `BASH4LLM_ERR_NO_API_KEY` con notazione ad underscore.
* `BASH4LLMERR_BAD_MODEL`: Mappatura alias diretta del valore di `BASH4LLM_ERR_BAD_MODEL` con notazione ad underscore.
* `BASH4LLMERR_CURL_FAILED`: Mappatura alias diretta del valore di `BASH4LLM_ERR_CURL_FAILED` con notazione ad underscore.
* `BASH4LLMERR_PARSE`: Mappatura alias diretta del valore di `BASH4LLM_ERR_PARSE` con notazione ad underscore.
* `BASH4LLMERR_NO_PROMPT`: Mappatura alias diretta del valore di `BASH4LLM_ERR_NO_PROMPT` con notazione ad underscore.
* `BASH4LLMERR_TMP`: Mappatura alias diretta del valore di `BASH4LLM_ERR_TMP` con notazione ad underscore.
* `BASH4LLMERR_API`: Mappatura alias diretta del valore di `BASH4LLM_ERR_API` con notazione ad underscore.
* `BASH4LLMERR_SEC`: Mappatura alias diretta del valore di `BASH4LLM_ERR_SEC` con notazione ad underscore.
* `DEBUG`: Flag di configurazione per l'output di tracciamento dello sviluppo. Eredita il valore di ambiente `${DEBUG}` o `${BASH4LLM_DEBUG}`, o viene impostato su `0` (disattivo).
* `BASH4LLM_LOG`: Percorso del file in cui registrare i log di tracciamento. Eredita `${BASH4LLM_LOG}` (vuoto se disattivato).
* `SCRIPTDIR`: Percorso assoluto della directory contenente lo script corrente, risolto dinamicamente tramite la funzione `resolve_script_dir`.
* `BASH4LLM_DIR`: Directory principale dei dati e configurazioni di Bash4LLM⁺. Dichiarata dall'ambiente (`${BASH4LLM_DIR}` o derivata da `${BASH4LLM_ROOT}/bash4llm.d` o `$SCRIPTDIR/bash4llm.d`).
* `BASH4LLM_CONFIG_DIR`: Directory dei file di configurazione utente persistenti (`$BASH4LLM_DIR/config`).
* `BASH4LLM_MODELS_DIR`: Directory dei cataloghi modelli supportati (`$BASH4LLM_DIR/models`).
* `BASH4LLM_TEMPLATES_DIR`: Directory dei file di template di prompt (`$BASH4LLM_DIR/templates`).
* `BASH4LLM_HISTORY_DIR`: Directory dello storico e dei log delle interazioni (`$BASH4LLM_DIR/history`).
* `BASH4LLM_TMPDIR`: Directory radice per l'allocazione dei dati temporanei isolati (`$BASH4LLM_DIR/tmp`).
* `BASH4LLM_RUN_DIR`: Directory per i file di stato ed esecuzione del runtime (`$BASH4LLM_DIR/var/run`).
* `BASH4LLM_LOCKS_DIR`: Directory per i file di lock concorrenziali (`$BASH4LLM_RUN_DIR/locks`).
* `CANONICAL_EXTRAS_DIR`: Percorso della directory canonica delle estensioni vendor (`$BASH4LLM_DIR/extras`).
* `LEGACY_EXTRAS_DIR`: Percorso storico di fallback delle estensioni (`$SCRIPTDIR/extras`).
* `BASH4LLM_EXTRAS_DIR`: Directory attiva per l'accesso alle risorse vendor (`CANONICAL_EXTRAS_DIR`).
* `PROVIDERS_DIR`: Percorso dei moduli driver vendor dei provider (`$BASH4LLM_EXTRAS_DIR/providers`).
* `CANONICAL_LOCAL_EXTRAS_DIR`: Percorso canonico delle estensioni utente locali (`$BASH4LLM_DIR/local-extras`).
* `BASH4LLM_LOCAL_EXTRAS_DIR`: Directory radice per le estensioni locali (`CANONICAL_LOCAL_EXTRAS_DIR`).
* `LOCAL_PROVIDERS_DIR`: Directory dei provider utente locali (`$BASH4LLM_LOCAL_EXTRAS_DIR/providers`).
* `THREAD_DIR`: Directory dedicata ai database storici NDJSON dei thread (`$BASH4LLM_HISTORY_DIR/threads`).
* `TMPDIR`: Override dell'ambiente di sistema forzato su `$BASH4LLM_TMPDIR` per garantire l'isolamento locale e sicuro di cURL e dei file provvisori.
* `BASH4LLM_RATES_DIR`: Directory isolata per i marcatori transazionali del rate limiting locale (`$BASH4LLM_TMPDIR/rates`).
* `BASH4LLM_VAULT_ENABLED`: Controllo per l'abilitazione (`1`) o disattivazione (`0`) del Key Vault OpenSSL (default `1`).
* `_BASH4LLM_OPENSSL_HELPER`: Percorso del modulo di ausilio crittografico OpenSSL (`$BASH4LLM_EXTRAS_DIR/security/openssl-helper.sh`).
* `BASH4LLM_OPENSSL_ACTIVE`: Flag booleano indicante se `openssl-helper.sh` è stato verificato via SHA-256 e caricato (`1` o `0`).
* `MODELS_FILE`: File locale contenente l'elenco dei modelli del provider attivo, sincronizzato tramite `sync_models_file_path`.
* `MAX_MODELS`: Limite numerico massimo di modelli importabili o gestibili localmente (default `200`).
* `PROVIDER_FILE`: Percorso del file che persiste l'ultimo provider configurato dall'utente (`canonical_provider_file`).
* `MODELS_LOCK`: Percorso del lock di sincronizzazione modelli (`$BASH4LLM_LOCKS_DIR/models.lock`).
* `HISTORY_LOCK`: Percorso del lock concorrenziale sullo storico (`$BASH4LLM_HISTORY_DIR/history.lock`).
* `TMP_LOCK`: Percorso del lock esclusivo per la gestione temporanea (`$BASH4LLM_LOCKS_DIR/tmp.lock`).
* `BASH4LLM_LOCK_TIMEOUT_TMP`: Timeout massimo in secondi per lock temporanei (default `10`).
* `BASH4LLM_LOCK_TIMEOUT_MODELS`: Timeout in secondi per lock modelli (default `10`).
* `BASH4LLM_LOCK_TIMEOUT_HISTORY`: Timeout in secondi per lock storico messaggi e thread (default `10`).

### FUNZIONI

* `resolve_script_dir`
  * **Scopo**: Identifica la cartella reale in cui risiede lo script risolvendo ricorsivamente eventuali collegamenti simbolici.
  * **Input**: Nessuno (analizza `${BASH_SOURCE[0]}`).
  * **Output**: Percorso assoluto su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `readlink`, `dirname`, `cd`, `pwd`, `printf`.

* `safe_mkdir`
  * **Scopo**: Crea in modo sicuro una directory con permessi restrittivi, impedendo attacchi basati su symlink.
  * **Input**: `$1` (directory), `$2` (opzionale: permessi ottali, default `700`).
  * **Output**: Stato `0` o uscita immediata con codice `15` (`BASH4LLM_ERR_TMP`) se fallisce o se rileva symlink.
  * **Side-effects**: Verifica symlink, creazione directory via `mkdir -p`, `chmod`.
  * **Dipendenze**: `mkdir`, `chmod`, `printf`, `log_error`.

* `check_required_arg`
  * **Scopo**: Convalida la presenza del parametro obbligatorio per un'opzione CLI rispetto agli argomenti residui.
  * **Input**: `$1` (opzione indagata), `$2` (conteggio argomenti residui `$#`).
  * **Output**: Stato `0` o uscita con codice `15`.
  * **Side-effects**: Emissione log errore su standard error.
  * **Dipendenze**: `log_error`.

* `canonical_config_dir`
  * **Scopo**: Restituisce il percorso normalizzato della directory di configurazione privo di slash finale.
  * **Input**: Nessuno (analizza `$BASH4LLM_CONFIG_DIR`).
  * **Output**: Percorso stampato su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `printf`.

* `canonical_provider_file`
  * **Scopo**: Genera il percorso canonico del file di persistenza del provider (`<config_dir>/provider`).
  * **Input**: Nessuno.
  * **Output**: Percorso stampato su standard output.
  * **Side-effects**: Invoca `canonical_config_dir`.
  * **Dipendenze**: `printf`, `canonical_config_dir`.

* `canonical_model_file`
  * **Scopo**: Genera il percorso del file contenente il modello predefinito associato a un dato provider (`<config_dir>/model.<provider>`).
  * **Input**: `$1` (nome provider).
  * **Output**: Percorso stampato su standard output.
  * **Side-effects**: Invoca `canonical_config_dir`.
  * **Dipendenze**: `printf`, `canonical_config_dir`.

* `canonical_provider_url_file`
  * **Scopo**: Genera il percorso canonico del file contenente l'endpoint URL specifico del provider attivo (`<config_dir>/provider-url`).
  * **Input**: Nessuno.
  * **Output**: Percorso stampato su standard output.
  * **Side-effects**: Invoca `canonical_config_dir`.
  * **Dipendenze**: `type`, `printf`, `canonical_config_dir`.

* `trim_space`
  * **Scopo**: Rimuove spazi e tabulazioni iniziali e finali tramite costrutti di parameter expansion nativi (Zero-Fork).
  * **Input**: `$1` (stringa).
  * **Output**: Stringa ripulita su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `printf`.

* `_is_readonly_func`
  * **Scopo**: Verifica se una funzione esiste ed è dichiarata `readonly` testandone l'`unset` in una sotto-shell isolata.
  * **Input**: `$1` (nome funzione).
  * **Output**: Stato `0` se read-only, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `declare`, `unset`.

* `sync_models_file_path`
  * **Scopo**: Sincronizza il percorso globale di `MODELS_FILE` in base al provider attivo, applicando una whitelist che esclude caratteri non alfanumerici (anti directory traversal).
  * **Input**: `$1` (opzionale: nome provider, default `$PROVIDER` o `"groq"`).
  * **Output**: Esporta la variabile globale `MODELS_FILE`.
  * **Side-effects**: Modifica ed esportazione di `MODELS_FILE`.
  * **Dipendenze**: `export`.

* `_normalize_model_name`
  * **Scopo**: Normalizza i nomi dei modelli rimuovendo prefissi (`models/`, provider) e spazi; memorizza il risultato nell'array associativo `BASH4LLM_MODEL_CACHE` per bypassare riesecuzioni.
  * **Input**: `$1` (nome grezzo modello).
  * **Output**: Nome normalizzato e filtrato da whitelist su standard output.
  * **Side-effects**: Popola l'array associativo in memoria `BASH4LLM_MODEL_CACHE`.
  * **Dipendenze**: `normalize_model_<provider>` (se presente nel driver).

* `is_truthy`
  * **Scopo**: Valuta se un valore testuale corrisponde a una veridicità logica affermativa.
  * **Input**: `$1` (stringa).
  * **Output**: Ritorna stato `0` (vero) se il valore è `1`, `true`, `TRUE`, `True`, `yes`, `YES`, `Yes`; altrimenti ritorna `1` (falso).
  * **Side-effects**: Nessuno.
  * **Dipendenze**: Nessuna.

* `_extract_notes_section`
  * **Scopo**: Estrae sezioni testuali letterali in modalità Zero-Eval dal file `core-notes.sh`.
  * **Input**: `$1` (intestazione di sezione).
  * **Output**: Righe estratte su standard output, o stato `1` se assente.
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `awk`.

* `emit_json_diagnostics`
  * **Scopo**: Genera ed emette messaggi diagnostici in formato JSON strutturato su standard error quando `JSON_DIAGNOSTICS=1`.
  * **Input**: `$1` (status type), `$2` (codice errore numerico), `$3` (reason code), `$4` (messaggio).
  * **Output**: Stringa JSON su standard error.
  * **Side-effects**: Scrittura su standard error.
  * **Dipendenze**: `jq`, `date`, `printf`.

* `log_prefix`
  * **Scopo**: Restituisce il prefisso di intestazione unificato per i log (`bash4llm: `).
  * **Input**: Nessuno.
  * **Output**: Stringa su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `printf`.

* `log_info`
  * **Scopo**: Registra e visualizza messaggi informativi se `DEBUG=1`.
  * **Input**: `$1` (categoria, default `"INFO"`), `$2` (messaggio).
  * **Output**: Scrive su standard error se abilitato e appende a `$BASH4LLM_LOG`.
  * **Side-effects**: Scrittura su console e file-system.
  * **Dipendenze**: `log_prefix`, `date`, `printf`.

* `log_warn`
  * **Scopo**: Visualizza a schermo messaggi di avvertimento non critici.
  * **Input**: `$1` (categoria, default `"WARN"`), `$2` (messaggio).
  * **Output**: Scrive su standard error e appende a `$BASH4LLM_LOG`.
  * **Side-effects**: Scrittura su console e file-system.
  * **Dipendenze**: `log_prefix`, `date`, `printf`.

* `log_error`
  * **Scopo**: Registra ed evidenzia errori critici. Se `JSON_DIAGNOSTICS=1`, delega a `emit_json_diagnostics`.
  * **Input**: `$1` (categoria, default `"ERROR"`), `$2` (messaggio).
  * **Output**: Scrive errore su standard error e registra in `$BASH4LLM_LOG`.
  * **Side-effects**: Scrittura su console e file-system.
  * **Dipendenze**: `log_prefix`, `emit_json_diagnostics`, `is_truthy`, `date`, `printf`.

* `log_info_user`
  * **Scopo**: Registra messaggi informativi destinati all'utente (non silenziati da `QUIET=1`).
  * **Input**: `$1` (categoria), `$2` (messaggio).
  * **Output**: Scrive su standard error (se `QUIET=0`) e registra in log.
  * **Side-effects**: Scrittura su standard error e file-system.
  * **Dipendenze**: `log_prefix`, `date`, `printf`.

* `dbg`
  * **Scopo**: Visualizza messaggi di debug rapido su standard error quando `DEBUG!=0`.
  * **Input**: Argomenti testuali `$*`.
  * **Output**: Testo su standard error.
  * **Side-effects**: Scrittura su standard error.
  * **Dipendenze**: `printf`.

* `read_secure_input`
  * **Scopo**: Acquisisce input sensibili disabilitando l'echo del terminale con stty su `/dev/tty` e ripristinando lo stato tramite trap protetta.
  * **Input**: `$1` (variabile target), `$2` (prompt), `$3` (lunghezza minima, default `0`), `$4` (opzionale: allow verify).
  * **Output**: Assegna l'input pulito alla variabile target via `printf -v`. Ritorna `0` o `1` in caso di errore o lunghezza non sufficiente.
  * **Side-effects**: Modifica impostazioni terminale (`stty -echo` / `stty echo`), intercetta segnali `INT`/`TERM`.
  * **Dipendenze**: `stty`, `trap`, `printf`, `read`.

* `validate_file_input`
  * **Scopo**: Esegue la convalida di sicurezza su un file di input, verificando esistenza, leggibilità, dimensione non nulla e assenza di byte nulli o controlli C0 non consentiti.
  * **Input**: `$1` (percorso file).
  * **Output**: Ritorna stati: `0` (valido), `1` (vuoto), `2` (non leggibile), `3` (dimensione 0), `4` (presenza di byte binari/nulli).
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `file_size`, `tr`, `wc`, `LC_ALL=C`.

* `_get_perm_string`
  * **Scopo**: Restituisce la stringa simbolica dei permessi di un file (es. `-rw-------`) gestendo le differenze tra Linux, macOS e BSD.
  * **Input**: `$1` (percorso).
  * **Output**: Stringa permessi su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `stat`.

* `_get_owner`
  * **Scopo**: Restituisce il proprietario di un percorso in modo portabile.
  * **Input**: `$1` (percorso).
  * **Output**: Nome utente su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `stat`.

* `validate_path_security`
  * **Scopo**: Valida la sicurezza di un percorso verificando che il file e la directory padre non siano symlink, appartengano all'utente corrente e non siano scrivibili da terzi (INV-4).
  * **Input**: `$1` (percorso target).
  * **Output**: Ritorna stato `0` se sicuro, `1` se non conforme.
  * **Side-effects**: Log di sicurezza.
  * **Dipendenze**: `_get_owner`, `_get_perm_string`, `log_error`, `log_warn`, `is_truthy`, `dirname`, `id`, `awk`.

* `_core_sha256`
  * **Scopo**: Calcola l'hash crittografico SHA-256 digest di un file usando i binari nativi di sistema (`sha256sum`, `openssl`, `shasum`).
  * **Input**: `$1` (percorso file).
  * **Output**: Digest esadecimale su standard output, o ritorna `1` in caso di errore.
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `sha256sum`, `openssl`, `shasum`, `awk`.

* `verify_module_integrity`
  * **Scopo**: Verifica la sicurezza del percorso e l'integrità crittografica SHA-256 di un modulo rispetto al manifest ufficiale (`extras/manifest.sha256`).
  * **Input**: `$1` (percorso file), `$2` (dominio: `"vendor"` o `"local"`, default `"vendor"`), `$3` (opzionale: percorso logico relativo).
  * **Output**: Ritorna `0` se conforme o se dominio `"local"`; ritorna `17` (`BASH4LLM_ERR_SEC`) se manomesso o non registrato.
  * **Side-effects**: Calcolo hash SHA-256 e logging in caso di manomissione.
  * **Dipendenze**: `validate_path_security`, `_core_sha256`, `log_error`, `log_info`, `awk`, `basename`, `dirname`, `cd`, `pwd`.

* `_provider_env_snapshot`
  * **Scopo**: Salva uno snapshot in memoria delle variabili d'ambiente critiche del guscio (`PATH`, `IFS`, `PWD`, `CDPATH`, `LANG`, `LC_ALL`) prima dell'importazione di moduli provider.
  * **Input**: Nessuno.
  * **Output**: Popola le variabili interne `_B4L_SAVED_*`.
  * **Side-effects**: Assegnazione in memoria.
  * **Dipendenze**: Nessuna.

* `_provider_env_restore`
  * **Scopo**: Ripristina le variabili d'ambiente del guscio salvate via `_provider_env_snapshot` dopo il caricamento del modulo provider.
  * **Input**: Nessuno.
  * **Output**: Ripristina le variabili originali ed esegue `unset` di `_B4L_SAVED_*`.
  * **Side-effects**: Ripristino variabili di shell ed esecuzione `cd`.
  * **Dipendenze**: `export`, `unset`, `cd`.

* `_verify_manifest_signature`
  * **Scopo**: Verifica la firma crittografica Ed25519 del file manifest (`manifest.sha256.sig`) usando OpenSSL o ssh-keygen e la chiave pubblica `official-ed25519.pub`.
  * **Input**: `$1` (percorso manifest).
  * **Output**: Ritorna stato `0` se valida o opzionale; `17` (`BASH4LLM_ERR_SEC`) se fallisce o se richiesta obbligatoriamente.
  * **Side-effects**: Allocazione temporanei e log di sicurezza.
  * **Dipendenze**: `validate_path_security`, `_tmpf`, `log_error`, `is_truthy`, `openssl`, `ssh-keygen`, `rm`.

* `ensure_api_key_for_provider`
  * **Scopo**: Risolve la chiave API per il provider attivo seguendo la gerarchia: 1) Key Vault OpenSSL in memoria; 2) Variabile d'ambiente (se `BASH4LLM_REQUIRE_VAULT=0`); 3) Prompt interattivo TTY blindato.
  * **Input**: `$1` (nome provider).
  * **Output**: Ritorna stato `0` ed esporta la chiave API. Ritorna `10` (`BASH4LLM_ERR_NO_API_KEY`) o `17` (`BASH4LLM_ERR_SEC`) in caso di assenza o violazione di policy.
  * **Side-effects**: Decrittografia Vault, esportazione variabili d'ambiente, prompt TTY.
  * **Dipendenze**: `provider_api_env_var_name`, `vault_exists`, `vault_load_keys`, `read_secure_input`, `is_truthy`, `jq`, `export`.

* `enforce_network_policy`
  * **Scopo**: Determina se le connessioni di rete reali sono autorizzate o devono essere bloccate (`DRY_RUN`, `BASH4LLM_SKIP_NETWORK`, `QUIET` policy).
  * **Input**: Nessuno.
  * **Output**: Ritorna stato `0` se autorizzate, `1` se inibite.
  * **Side-effects**: Log di debug.
  * **Dipendenze**: `is_truthy`, `log_info`.

* `ensure_config_dir`
  * **Scopo**: Crea e convalida la directory di configurazione utente impostando permessi `700` e testandone la reale scrivibilità.
  * **Input**: Nessuno.
  * **Output**: Ritorna `0` se pronta e scrivibile, `1` in caso di errore.
  * **Side-effects**: Creazione directory, file temporaneo di test, `chmod`.
  * **Dipendenze**: `safe_mkdir`, `log_error`, `chmod`, `rm`.

* `write_provider_url_if_missing`
  * **Scopo**: Salva transazionalmente l'endpoint API per un provider nel file `/provider-url` applicando permessi `600`.
  * **Input**: `$1` (nome provider), `$2` (URL API).
  * **Output**: Ritorna `0` in caso di successo, `1` altrimenti.
  * **Side-effects**: File temporaneo in `$RUN_TMPDIR`, scrittura atomica, `chmod 600`.
  * **Dipendenze**: `canonical_provider_url_file`, `safe_mkdir`, `_tmpf`, `mv`, `cp`, `rm`, `chmod`.

* `resolve_provider_url`
  * **Scopo**: Risolve ed esporta l'endpoint API controllando nell'ordine: `BASH4LLM_API_URL`, `BASH4LLM_PROVIDER_URL`, il file `provider-url`, o l'endpoint predefinito per Groq.
  * **Input**: `$1` (opzionale: nome provider).
  * **Output**: Ritorna stato `0` ed esporta `BASH4LLM_PROVIDER_URL`. Ritorna `1` in caso di errore.
  * **Side-effects**: Esporta `BASH4LLM_PROVIDER_URL`.
  * **Dipendenze**: `canonical_provider_url_file`, `sed`, `awk`, `export`.

* `provider_api_env_var_name`
  * **Scopo**: Restituisce il nome standardizzato della variabile d'ambiente deputata alla chiave API (es: `"groq"` -> `"GROQ_API_KEY"`).
  * **Input**: `$1` (nome provider).
  * **Output**: Stringa normalizzata su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `printf`.

* `print_persistence_reminder`
  * **Scopo**: Stampa un avviso su standard error con le istruzioni per rendere persistente una chiave API inserita manualmente durante la sessione.
  * **Input**: Nessuno (analizza `BASH4LLM_KEY_MANUAL_PROMPT`).
  * **Output**: Avviso formattato su standard error e azzeramento del flag.
  * **Side-effects**: Esportazione e reset di `BASH4LLM_KEY_MANUAL_PROMPT`.
  * **Dipendenze**: `provider_api_env_var_name`, `printf`, `export`.

* `is_valid_json_string`
  * **Scopo**: Verifica se la stringa in ingresso è un JSON sintatticamente valido.
  * **Input**: `$1` (stringa).
  * **Output**: Ritorna `0` se valida, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `jq`.

* `b64encode`
  * **Scopo**: Esegue la codifica Base64 da standard input su riga singola senza a capo (tramite `openssl enc` o `base64`).
  * **Input**: Flusso da standard input.
  * **Output**: Stringa codificata su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `openssl`, `base64`, `tr`.

* `b64decode`
  * **Scopo**: Esegue la decodifica Base64 da standard input con folding automatico a 64 caratteri via awk per prevenire bug di LibreSSL/macOS.
  * **Input**: Flusso codificato da standard input.
  * **Output**: Flusso decodificato su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `awk`, `openssl`, `base64`.

* `file_size`
  * **Scopo**: Restituisce la dimensione in byte di un file in modo portabile tra Linux, macOS e BSD.
  * **Input**: `$1` (percorso file).
  * **Output**: Valore numerico in byte su standard output (`0` se assente).
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `stat`.

* `is_valid_json_file`
  * **Scopo**: Verifica se un file esiste, non è vuoto ed è un JSON valido.
  * **Input**: `$1` (percorso file).
  * **Output**: Ritorna `0` se valido, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `jq`.

* `stage_b64`
  * **Scopo**: Codifica un payload in Base64 in un file temporaneo protetto e lo sposta atomicamente a destinazione sotto lock esclusivo.
  * **Input**: `$1` (opzionale: file sorgente), `$2` (file destinazione Base64).
  * **Output**: Ritorna stato `0` o `1` (es. se supera `MAX_STAGE_BYTES`, default 10MB).
  * **Side-effects**: Creazione file temporanei, lock concorrenziale, `chmod 600`.
  * **Dipendenze**: `safe_mkdir`, `_tmpf`, `file_size`, `lock_exec`, `b64encode`, `mv`, `chmod`, `rm`.

* `lock_exec`
  * **Scopo**: Esegue un comando arbitrario garantendo mutua esclusione atomica tramite binario `flock` o directory lock atomica con recupero automatico da crash di processi orfani.
  * **Input**: `$1` (file di lock), `$2` (timeout in secondi, default `10`), seguiti da `--` e dal comando.
  * **Output**: Ritorna lo stato d'uscita del comando, `124` se scade il timeout, o `15` se rileva symlink.
  * **Side-effects**: Creazione lockfile/lockdir, scrittura metadati owner PID e timestamp.
  * **Dipendenze**: `safe_mkdir`, `log_error`, `flock`, `mkdir`, `rm`, `rmdir`, `kill`, `date`, `sleep`.

* `_mktemp_in_dir`
  * **Scopo**: Crea un file temporaneo univoco all'interno della directory indicata.
  * **Input**: `$1` (cartella base), `$2` (opzionale: prefisso).
  * **Output**: Percorso del file temporaneo su standard output o errore `15`.
  * **Side-effects**: Creazione file con permessi restrittivi.
  * **Dipendenze**: `_tmpf`, `log_error`.

* `show_payload_head`
  * **Scopo**: Visualizza su standard error le prime righe del payload inviato alle API (eseguendo decodifica al volo se `.b64`) per diagnostica debug.
  * **Input**: `$1` (percorso payload), `$2` (righe max, default `200`).
  * **Output**: Testo su standard error.
  * **Side-effects**: Lettura e decodifica.
  * **Dipendenze**: `b64decode`, `head`, `printf`.

* `atomic_write`
  * **Scopo**: Scrive o sovrascrive un file in modo atomico e transazionale: riceve dati da stdin, scrive in un file provvisorio `0600`, acquisisce lock esclusivo via `lock_exec` e sposta atomicamente il file.
  * **Input**: `$1` (file destinazione), `$2` (opzionale: timeout lock, default `10`).
  * **Output**: Ritorna stato `0` o codice d'errore.
  * **Side-effects**: Allocazione temporanei, lock concorrenziale, `mv`, `chmod 600`.
  * **Dipendenze**: `safe_mkdir`, `lock_exec`, `mktemp`, `cat`, `mv`, `chmod`, `rm`.

* `extract_text_from_resp`
  * **Scopo**: Estrae in modo resiliente il testo generato dai JSON di risposta delle API LLM scansionando flussi OpenAI Chat Completions, testi diretti o scalari.
  * **Input**: Nessuno (analizza `$RESP`).
  * **Output**: Testo estratto su standard output. Ritorna `0` (successo), `1` (nessun testo) o `2` (JSON diagnostico).
  * **Side-effects**: Copia di lavoro temporanea isolata.
  * **Dipendenze**: `_tmpf`, `is_valid_json_file`, `cp`, `jq`, `cat`.

* `cleanup_run_tmp_on_exit`
  * **Scopo**: Handler di uscita globale per ripristinare il terminale (`stty echo`), rilasciare lock attivi e rimuovere la cartella provvisoria `$RUN_TMPDIR` se posizionata in perimetro autorizzato.
  * **Input**: Nessuno (cattura `$?`).
  * **Output**: Pulizia del runtime e ripristino terminale.
  * **Side-effects**: Rimozione file temporanei, rilascio file descriptor 8, `stty echo`.
  * **Dipendenze**: `release_thread_lock`, `stty`, `rm`.

* `ensure_run_tmpdir`
  * **Scopo**: Alloca, isola ed esporta l'ambiente temporaneo runtime (`RUN_TMPDIR`, `PAYLOAD`, `RESP`, `ERRF`) con permessi `0700`/`0600` e registra la trap di pulizia `cleanup_run_tmp_on_exit`.
  * **Input**: `$1` (opzionale: `--print`).
  * **Output**: Esporta variabili temporanee. Ritorna `0` o `15`.
  * **Side-effects**: Creazione directory e file di stato, registrazione trap.
  * **Dipendenze**: `safe_mkdir`, `_tmpf`, `chmod`, `trap`.

* `b64_atomic_write`
  * **Scopo**: Codifica in Base64 il flusso da stdin e lo scrive atomicamente nel file di destinazione con permessi `0600`.
  * **Input**: `$1` (destinazione), `$2` (timeout lock, default `10`).
  * **Output**: Ritorna stato `0` o `15`.
  * **Side-effects**: Scrittura temporanea e atomica.
  * **Dipendenze**: `_tmpf`, `b64encode`, `atomic_write`, `rm`.

* `b64_atomic_read`
  * **Scopo**: Legge un file Base64 e ne restituisce il contenuto decodificato su standard output.
  * **Input**: `$1` (percorso file).
  * **Output**: Flusso decodificato su standard output.
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `b64decode`.

* `ui_state_write`
  * **Scopo**: Scrive atomicamente frammenti JSON di stato dell'interfaccia nella directory `ui_state/` con permessi `0600`.
  * **Input**: `$1` (nome file relativo), `$2` (contenuto JSON).
  * **Output**: Ritorna stato `0` o `1`.
  * **Side-effects**: `safe_mkdir`, `atomic_write`, `chmod 600`.
  * **Dipendenze**: `safe_mkdir`, `atomic_write`, `printf`, `chmod`.

* `run_static_config_check`
  * **Scopo**: Esegue il linter statico di conformità e sicurezza: convalida i permessi del file di configurazione (blocco immediato con codice `17` se group/world writable) e confronta le variabili con le definizioni canoniche di `core-notes.sh`.
  * **Input**: Nessuno.
  * **Output**: Esito e avvisi su console. Esce con `0` o `17` (`BASH4LLM_ERR_SEC`).
  * **Side-effects**: Parsing configurazione.
  * **Dipendenze**: `_extract_notes_section`, `stat`, `awk`, `sed`, `grep`, `printf`.

* `explain_error_code`
  * **Scopo**: Recupera in modalità Zero-Eval da `core-notes.sh` la definizione formale e le indicazioni operative per un codice numerico d'errore o alias.
  * **Input**: `$1` (codice o alias).
  * **Output**: Spiegazione formattata su standard error.
  * **Side-effects**: Lettura file note.
  * **Dipendenze**: `_extract_notes_section`, `printf`, `grep`.

* `_resolve_provider_module_path`
  * **Scopo**: Risolve la specifica grezza del provider identificandone il percorso fisico, il dominio di appartenenza (`builtin`, `vendor`, `local`) e il nome canonico.
  * **Input**: `$1` (stringa provider).
  * **Output**: Stringa `"percorso|dominio|nome"` su standard output. Ritorna `0` o `1`.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `log_error`, `log_warn`, `printf`.

* `load_provider_module`
  * **Scopo**: Carica in modo isolato i driver provider esterni: esegue snapshot ambiente, copia di staging anti-TOCTOU, verifica firma Ed25519 del manifest per il dominio vendor, validazione sintassi (`bash -n`), controllo API version contract (`BASH4LLM_PROVIDER_API_VERSION`) e filtro whitelist delle funzioni consentite (`buildpayload_<p>`, `call_api_<p>`, `call_api_streaming_<p>`, `refresh_models_<p>`, `validate_model_<p>`, `validate_key_<p>`, `auto_select_model_<p>`, `normalize_model_<p>`). Registra le capacità in `provider_capabilities.json`.
  * **Input**: `$1` (nome provider).
  * **Output**: Ritorna `0` (successo), `17` (violazione sicurezza) o `1` (errore sintassi).
  * **Side-effects**: Snapshot/restore ambiente, staging e dump temporanei, disabilitazione/ripristino `nounset`, scrittura stato UI.
  * **Dipendenze**: `_provider_env_snapshot`, `_provider_env_restore`, `_resolve_provider_module_path`, `verify_module_integrity`, `_verify_manifest_signature`, `_tmpf`, `_mktemp_in_dir`, `sync_models_file_path`, `ui_state_write`, `cp`, `chmod`, `awk`, `sort`, `comm`, `grep`, `jq`, `rm`.

* `_detect_base64_opts`
  * **Scopo**: Rileva a runtime le opzioni ottimali per l'eseguibile `base64` per la formattazione a riga singola e la decodifica su varie piattaforme.
  * **Input**: Nessuno.
  * **Output**: Esporta `B64_WRAP_OPT` e `B64_DECODE_OPT`.
  * **Side-effects**: Esportazione variabili d'ambiente.
  * **Dipendenze**: `base64`, `grep`, `export`.

* `_file_mtime`
  * **Scopo**: Restituisce il timestamp Unix di ultima modifica di un file in modo portabile.
  * **Input**: `$1` (percorso file).
  * **Output**: Timestamp Unix numerico su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `stat`.

* `jq_safe`
  * **Scopo**: Esegue un filtro jq scrivendo eventuali errori diagnostici in `$ERRF` senza causare arresti anomali dello script.
  * **Input**: `$1` (filtro jq), `$2` (file JSON).
  * **Output**: Ritorna lo stato d'uscita di jq.
  * **Side-effects**: Scrittura log su `$ERRF`.
  * **Dipendenze**: `jq`.

### BLOCCHI DI CODICE

* `PRECORE_BOOT_SETUP_SHELL`: Imposta `set -euo pipefail` (solo se eseguito direttamente), pulisce variabili ad alto rischio (`BASH_ENV`, `ENV`, `CDPATH`, `GLOBIGNORE`), azzera i core dump (`ulimit -c 0`) e definisce i metadati di versione (`2.8.5.3`, `2026-08-16`).
* `PRECORE_BOOT_SETUP_ENV_CMDS`: Verifica la presenza nel `PATH` di tutte le utilità essenziali di sistema (`bash`, `jq`, `curl`, `mktemp`, `stat`, `base64`, `find`, `awk`, `sed`, `grep`, `xargs`, `tr`, `sort`, `head`, `wc`, `tee`, `date`, `mv`, `chmod`, `cp`, `rm`, `printf`, `comm`); in caso di assenza, arresta con codice `15`.
* `PRECORE_BOOT_EARLY_UTILITIES`: Risolve il percorso dello script (`resolve_script_dir`), definisce gli helper primari e configura i temi ANSI nel rispetto di `NO_COLOR` e terminali `dumb`.
* `PRECORE_BOOT_SECURITY`: Registra e sigilla le routine di sicurezza, validazione percorsi, calcolo hash SHA-256 e gestione credenziali Vault/interattive.
* `PRECORE_BOOT_DIR_PATH`: Alloca l'albero delle cartelle di runtime (`bash4llm.d`), isola `$TMPDIR` e provvede al caricamento verificato del modulo OpenSSL Vault (`openssl-helper.sh`).
* `PRECORE_BOOT_STORAGE_LOCKS`: Definisce percorsi lock, Base64 portabile, lock-exec concorrenziale e linter di configurazione statico.
* `PRECORE_BOOT_CLI_HELPERS`: Intercetta ed esegue opzioni diagnostiche immediate (`--check-config`, `--explain-error`, `--print-config-dir`, `--print-provider-file`, `--print-model-file`), imposta `umask 077` e definisce l'importatore anti-TOCTOU dei provider.

---

## 2. PRECORE_RUN

### VARIABILI

* `BASH4LLM_ROTATE_HISTORY`: Flag (`1` o `0`, default `0`) per l'attivazione della rotazione automatica dello storico.
* `BASH4LLM_HISTORY_MAX_FILES`: Limite massimo di file memorizzabili nello storico delle risposte (default `100`).
* `BASH4LLM_HISTORY_MAX_BYTES`: Limite massimo in byte del peso cumulativo dello storico (default `104857600`, 100MB).
* `BASH4LLM_HISTORY_KEEP_DAYS`: Giorni massimi di conservazione dei file di storico (default `90`).
* `THREAD_CACHE_DIR`: Directory per la cache temporanea dei thread (`$BASH4LLM_CONFIG_DIR/thread_cache`).
* `CONTENT`: Stringa del prompt testuale primario.
* `PROVIDER`: Identificatore del provider attivo (default `"groq"`).
* `JSON_INPUT`: Input strutturato JSON fornito dall'utente per richieste dirette.
* `THREAD_ID`: Identificatore del thread di chat, sincronizzato con l'hash `SAFE_THREAD_ID`.
* `SAFE_THREAD_ID`: Identificatore del thread anonimizzato crittograficamente in memoria (SHA-256 hex a 64 caratteri) per impedire la persistenza di PII su disco.
* `THREAD_WINDOW`: Numero massimo di messaggi da recuperare per comporre la finestra di contesto (default `10`).
* `TEMPLATE`: Nome del file di template di prompt da applicare.
* `BATCH_FILE`: Percorso del file contenente l'elenco sequenziale di prompt batch.
* `CHAT_MODE`: Flag booleano (`1` o `0`) per abilitare l'interfaccia interattiva TUI REPL da terminale.
* `SET_DEFAULT_MODEL`: Nome del modello da memorizzare come default per il provider attivo.
* `REFRESH_MODELS`: Flag booleano (`1` o `0`) per forzare l'aggiornamento del catalogo modelli dal provider.
* `LIST_MODELS`: Flag booleano (`1` o `0`) per visualizzare l'elenco dei modelli disponibili.
* `FORCE_SAVE_MODE`: Regola il salvataggio dei risultati (`"save"`, `"nosave"` o automatico su soglia).
* `OUT_PATH`: Percorso personalizzato per il salvataggio del file generato.
* `SYSTEM_PROMPT`: Istruzioni di sistema personalizzate per il modello.
* `TEMPERATURE` / `TURE`: Valore numerico per la temperatura di generazione (default `1.0`).
* `MAX_TOKENS`: Limite massimo di token generabili nella risposta (default `4096`).
* `MODEL`: Nome del modello LLM richiesto per l'inferenza.
* `AUTO_POLICY`: Politica per la selezione automatica del modello di fallback (default `"preferred"`).
* `QUIET`: Flag booleano (`1` o `0`) per sopprimere messaggi informativi e banner.
* `DRY_RUN`: Flag booleano (`1` o `0`) per simulare l'esecuzione senza effettuare chiamate di rete reali.
* `STREAM_MODE`: Flag booleano (`1` o `0`) per attivare lo streaming in tempo reale dei token (SSE).
* `OUTPUT_MODE`: Stile di visualizzazione dei risultati (`"text"`, `"raw"`, `"json"`, `"pretty"`).
* `THRESHOLD`: Soglia in caratteri oltre la quale la risposta viene salvata automaticamente nello storico (default `1000`).
* `MAX_RETRIES`: Tentativi massimi di riconnessione in caso di errori di rete temporanei (default `1`).
* `SUPPORTED_PROVIDERS`: Elenco dei provider supportati ed installati.
* `CURL_BASE_OPTS`: Array dei parametri cURL immutabili (`--silent`, `--show-error`, `--no-buffer`, `--max-time 120`).
* `FALLBACK_PAYLOAD`: Payload Base64 alternativo impostato da hook di post-esecuzione in caso di errore.
* `TRANSFORMED_PAYLOAD`: Payload Base64 trasformato in memoria da hook per sovrascrivere la risposta finale.
* `BASH4LLM_RATE_LIMIT`: Valore di soglia per il rate limiting locale (es. numero richieste per 30s o `"unlimited"`).
* `BASH4LLM_AUTH_TOKEN`: Token autorizzato per bypassare il rate limiter locale.
* `BASH4LLM_EDGE_EMPTY`: Flag diagnostico (`1` o `0`) che segnala una risposta vuota anomala del provider.
* `BASH4LLM_EDGE_REQ_ID`: ID richiesta estratto dalla risposta per fini diagnostici.
* `BASH4LLM_EDGE_FINISH_REASON`: Motivo di completamento (`finish_reason`) restituito dall'API.
* `BASH4LLM_EDGE_COMPLETION_TOKENS`: Conteggio token di completamento restituiti nell'oggetto `usage`.

### FUNZIONI

* `rotate_history`
  * **Scopo**: Esegue la manutenzione della directory storico eliminando i file più vecchi del limite temporale (`KEEP_DAYS`) e riducendo il volume sotto lock esclusivo secondo criteri di conteggio file e byte complessivi.
  * **Input**: `$1` (opzionale: timeout lock).
  * **Output**: Purgatura fisica dei file in esubero. Ritorna stato `0`.
  * **Side-effects**: Acquisizione lock su `$HISTORY_LOCK`, rimozione file da disco.
  * **Dipendenze**: `find`, `lock_exec`, `rm`, `sort`, `file_size`, `_file_mtime`.

* `save_to_history`
  * **Scopo**: Archivia il testo generato in un file cronologico protetto (`0600`) contrassegnato da timestamp e PID; aggiorna atomicamente il file di stato `last_history.json` e invoca la rotazione se abilitata.
  * **Input**: `$1` (testo risposta).
  * **Output**: File salvato su disco e stato UI aggiornato. Ritorna `0` o codice d'errore.
  * **Side-effects**: Scrittura atomica sotto lock `$HISTORY_LOCK`, aggiornamento stato JSON, invocazione `rotate_history`.
  * **Dipendenze**: `safe_mkdir`, `_tmpf`, `lock_exec`, `file_size`, `ui_state_write`, `rotate_history`, `jq`, `date`, `chmod`.

* `manifest_create`
  * **Scopo**: Inizializza un file di manifest JSON vuoto sotto lock esclusivo generando contemporaneamente la copia Base64 speculare (`.b64`) con permessi `0600`.
  * **Input**: `$1` (percorso manifest), `$2` (opzionale: timeout lock).
  * **Output**: Manifest JSON e `.b64` creati. Ritorna `0` o `1`.
  * **Side-effects**: Scrittura su disco e codifica Base64.
  * **Dipendenze**: `safe_mkdir`, `lock_exec`, `mktemp`, `printf`, `base64`, `mv`, `chmod`.

* `manifest_add_part`
  * **Scopo**: Inserisce una risorsa allegata nel manifest: codifica il payload in Base64 nella cartella di staging, aggiorna transazionalmente l'array `parts` via jq e rigenera la copia Base64 sotto lock.
  * **Input**: `$1` (manifest), `$2` (nome parte), `$3` (percorso file input), `$4` (MIME type), `$5` (opzionale: timeout lock).
  * **Output**: Record inserito e manifest rigenerato. Ritorna `0` o `1`.
  * **Side-effects**: Codifica Base64, aggiornamento JSON via jq, lock concorrenziale.
  * **Dipendenze**: `safe_mkdir`, `_tmpf`, `b64encode`, `lock_exec`, `jq`, `mktemp`, `mv`, `chmod`.

* `manifest_read`
  * **Scopo**: Legge e restituisce il contenuto JSON di un manifest decodificando la controparte `.b64` se il file primario manca.
  * **Input**: `$1` (percorso manifest).
  * **Output**: JSON su standard output. Ritorna `0` o `1`.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `b64decode`, `cat`.

* `anonymize_thread_id`
  * **Scopo**: Anonimizza crittograficamente l'identificatore del thread in memoria tramite hash SHA-256 hex a 64 caratteri (idempotente) prima di ogni operazione su disco (INV-6).
  * **Input**: `$1` (ID thread in chiaro).
  * **Output**: Esporta la variabile globale `SAFE_THREAD_ID`. Ritorna `0`, o termina con codice `17` (`BASH4LLM_ERR_SEC`) se fallisce l'anonimizzazione.
  * **Side-effects**: Esportazione di `SAFE_THREAD_ID`.
  * **Dipendenze**: `openssl`, `sha256sum`, `shasum`, `md5sum`, `md5`, `awk`, `export`, `log_error`.

* `execute_isolated_hook`
  * **Scopo**: Esegue gli hook di pre/post elaborazione in una sotto-shell isolata privata di token e chiavi API, con verifica di sicurezza percorso e integrità SHA-256; importa nel runtime solo variabili approvate tramite parser Zero-Eval basato su whitelist.
  * **Input**: `$1` (tipo: `"pre"` o `"post"`), `$2` (nome modulo hook).
  * **Output**: Ritorna lo stato dell'hook o `17` se fallisce la sicurezza.
  * **Side-effects**: Sotto-shell isolata, assegnazione selettiva variabili da whitelist.
  * **Dipendenze**: `validate_path_security`, `verify_module_integrity`, `compgen`, `unset`, `export`, `log_error`.

* `_get_file_signature`
  * **Scopo**: Calcola l'impronta di integrità e metadati di un file estraendo hash SHA-256 e attributi `stat` unificati in una stringa delimitata da pipe.
  * **Input**: `$1` (percorso file).
  * **Output**: Stringa `hash|device|inode|size|ctime|mtime|uid|gid|mode` su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `_secure_hash_sha256`, `sha256sum`, `stat`, `awk`, `printf`.

* `getfile_signature`
  * **Scopo**: Wrapper pubblico di interfaccia per `_get_file_signature`.
  * **Input**: `$1` (percorso file).
  * **Output**: Stringa firma su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `_get_file_signature`.

* `_is_world_writable`
  * **Scopo**: Verifica se una directory presenta permessi non sicuri di scrittura a terzi (world-writable).
  * **Input**: `$1` (percorso cartella).
  * **Output**: Ritorna stato `0` (vulnerabile), `1` (sicura o errore).
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `_get_perm_string`, `awk`.

* `_locked_history_save`
  * **Scopo**: Routine interna per lo spostamento protetto dei file storici da invocare sotto lock.
  * **Input**: `$1` (file temporaneo sorgente), `$2` (file destinazione).
  * **Output**: Ritorna `0` (successo) o `1`.
  * **Side-effects**: `mv`, `chmod 600`.
  * **Dipendenze**: `mv`, `chmod`.

* `_locked_manifest_create`
  * **Scopo**: Routine interna per la creazione di manifest e copia Base64 da eseguire sotto lock.
  * **Input**: `$1` (percorso manifest).
  * **Output**: Ritorna `0` o `1`.
  * **Side-effects**: Scrittura temporanea, Base64, `chmod 600`.
  * **Dipendenze**: `mktemp`, `printf`, `base64`, `mv`, `chmod`.

* `_locked_manifest_add_part`
  * **Scopo**: Routine interna per aggiornare il JSON del manifest e la controparte Base64 sotto lock.
  * **Input**: `$1` (manifest), `$2` (staging Base64), `$3` (nome), `$4` (MIME type).
  * **Output**: Ritorna `0` o `1`.
  * **Side-effects**: Scrittura provvisoria, `jq`, `base64`, `mv`, `chmod`.
  * **Dipendenze**: `mktemp`, `cp`, `base64`, `jq`, `mv`, `chmod`, `rm`.

* `check_local_rate_limit`
  * **Scopo**: Motore di limitazione delle richieste basato su finestra scorrevole di 30 secondi per thread anonimizzato; crea ed elenca file marcatori temporanei in `$BASH4LLM_RATES_DIR/<SAFE_THREAD_ID>`.
  * **Input**: Nessuno (analizza `BASH4LLM_RATE_LIMIT`, `BASH4LLM_AUTH_TOKEN`, `SAFE_THREAD_ID`).
  * **Output**: Ritorna `0` se autorizzata, `1` se superata la soglia.
  * **Side-effects**: Creazione e pulizia file marcatori su disco.
  * **Dipendenze**: `safe_mkdir`, `_file_mtime`, `log_info`, `log_error`, `date`, `find`, `wc`, `chmod`, `rm`.

* `make_tmpdir`
  * **Scopo**: Alloca una directory temporanea univoca e protetta in `$BASH4LLM_TMPDIR` sotto lock esclusivo `$TMP_LOCK` con permessi `0700`.
  * **Input**: Nessuno.
  * **Output**: Percorso della cartella su standard output. Ritorna `0` o `15`.
  * **Side-effects**: Creazione cartella provvisoria via `safe_mkdir`, lock su `$TMP_LOCK`.
  * **Dipendenze**: `safe_mkdir`, `lock_exec`, `_tmpf`, `umask`.

* `_tmpf`
  * **Scopo**: Generatore sicuro di file (`0600`) o directory (`0700`) temporanei: convalida che la base risieda strettamente dentro `$BASH4LLM_TMPDIR` (mitigazione Directory Traversal) e applica `umask 077`.
  * **Input**: `$1` (modalità: `"file"` o `"dir"`), `$2` (cartella base), `$3` (opzionale: prefisso, default `"groq"`).
  * **Output**: Percorso assoluto su standard output. Ritorna `0` o `15`.
  * **Side-effects**: Creazione file/directory, `chmod`, logging.
  * **Dipendenze**: `mktemp`, `chmod`, `log_error`, `umask`, `printf`.

* `thread_validate_id`
  * **Scopo**: Convalida che l'identificatore del thread rispetti il formato alfanumerico ammesso (`^[A-Za-z0-9._-]{1,128}$`).
  * **Input**: `$1` (ID thread).
  * **Output**: Ritorna `0` se conforme, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `grep`.

* `thread_now_ts`
  * **Scopo**: Restituisce il timestamp corrente in formato ISO 8601 UTC (`AAAA-MM-GGTHH:MM:SSZ`).
  * **Input**: Nessuno.
  * **Output**: Stringa timestamp su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `date`.

* `thread_messages_tmp_path`
  * **Scopo**: Restituisce il percorso del file provvisorio JSON contenente i messaggi del thread corrente in `$RUN_TMPDIR`.
  * **Input**: `$1` (ID thread).
  * **Output**: Percorso stampato su standard output. Ritorna `0` o `1`.
  * **Side-effects**: Invocazione `ensure_run_tmpdir`.
  * **Dipendenze**: `ensure_run_tmpdir`, `printf`.

* `thread_sanitize_cmd`
  * **Scopo**: Sanifica la riga di comando prima della registrazione storica mascherando parametri sensibili con `[REDACTED]` e troncando a 256 caratteri.
  * **Input**: `$1` (comando grezzo).
  * **Output**: Stringa sanificata su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `sed`, `cut`, `printf`.

* `_update_thread_index`
  * **Scopo**: Aggiorna l'indice globale dei thread attivi nel file `ui_state/threads/index.json` sotto lock esclusivo.
  * **Input**: `$1` (thread ID).
  * **Output**: Ritorna stato `0` o `1`.
  * **Side-effects**: Aggiornamento JSON via jq e `ui_state_write`.
  * **Dipendenze**: `_tmpf`, `ui_state_write`, `jq`, `mv`, `rm`.

* `_thread_delete_locked`
  * **Scopo**: Esegue la rimozione fisica del database NDJSON del thread, dei file di lock concorrenziali e dei metadati, aggiornando l'indice globale.
  * **Input**: `$1` (thread ID), `$2` (file thread), `$3` (file metadati), `$4` (file indice), `$5` (file indice provvisorio).
  * **Output**: Cancellazione file e aggiornamento indice JSON.
  * **Side-effects**: Rimozione file da disco.
  * **Dipendenze**: `rm`, `jq`, `mv`, `chmod`.

* `thread_delete_core`
  * **Scopo**: Rimuove transazionalmente un thread e i relativi lock dal disco invalidando la cache in memoria.
  * **Input**: `$1` (thread ID).
  * **Output**: Ritorna `0` o `15` se l'ID non è valido.
  * **Side-effects**: Cancellazione file sotto lock `$HISTORY_LOCK`, invalidazione cache.
  * **Dipendenze**: `thread_validate_id`, `lock_exec`, `_thread_delete_locked`, `thread_cache_invalidate`, `log_error`, `log_info`.

* `_thread_rename_locked`
  * **Scopo**: Aggiorna atomicamente il file di metadati del thread per modificarne il titolo visualizzato.
  * **Input**: `$1` (file meta), `$2` (file provvisorio), `$3` (thread ID), `$4` (titolo), `$5` (conteggio messaggi), `$6` (ultimo timestamp).
  * **Output**: File metadati scritto con permessi `0600`.
  * **Side-effects**: Sovrascrittura file metadati.
  * **Dipendenze**: `jq`, `mv`, `chmod`.

* `thread_rename_core`
  * **Scopo**: Rinomina transazionalmente il titolo di un thread aggiornandone i metadati storici sotto lock.
  * **Input**: `$1` (thread ID), `$2` (nuovo titolo).
  * **Output**: Ritorna `0` o `15` se l'ID è invalido.
  * **Side-effects**: Modifica file metadati UI sotto lock.
  * **Dipendenze**: `thread_validate_id`, `_tmpf`, `lock_exec`, `_thread_rename_locked`, `log_error`, `log_info`, `wc`, `tail`, `jq`.

* `acquire_thread_lock`
  * **Scopo**: Acquisisce un lock di processo esclusivo non-bloccante sul thread attivo aprendo il file descriptor `8` sul file `.concurrency.lock` via flock.
  * **Input**: Nessuno (analizza `$THREAD_ID`).
  * **Output**: Ritorna stato `0` se acquisito o in dry-run, altrimenti `15`.
  * **Side-effects**: Apertura e lock sul file descriptor 8.
  * **Dipendenze**: `thread_validate_id`, `safe_mkdir`, `flock`, `exec`, `log_error`.

* `release_thread_lock`
  * **Scopo**: Rilascia il lock di processo esclusivo del thread attivo chiudendo il file descriptor `8`.
  * **Input**: Nessuno (analizza `$THREAD_ID`).
  * **Output**: Ritorna `0` o `15`.
  * **Side-effects**: Chiusura del file descriptor 8 (`exec 8>&-`).
  * **Dipendenze**: `thread_validate_id`, `exec`.

* `_thread_read_window_locked`
  * **Scopo**: Estrae in modo ottimizzato le ultime `$n` righe del database NDJSON del thread via `tail` bypassando la scansione totale.
  * **Input**: `$1` (file thread), `$2` (righe `n`), `$3` (file temporaneo destinazione).
  * **Output**: Righe scritte nel file provvisorio.
  * **Side-effects**: Scrittura su file.
  * **Dipendenze**: `tail`, `cp`.

* `thread_read_window`
  * **Scopo**: Estrae la finestra degli ultimi `$n` messaggi dal log NDJSON del thread sotto lock; valida e struttura l'array JSON tramite pipeline jq con try-catch resiliente e aggiorna i metadati UI.
  * **Input**: `$1` (thread ID), `$2` (finestra messaggi, default `10`), `$3` (file JSON destinazione).
  * **Output**: File JSON strutturato con permessi `0600`. Ritorna `0` o `1`.
  * **Side-effects**: Lock, estrazione O(1), parsing jq, aggiornamento metadati UI.
  * **Dipendenze**: `thread_validate_id`, `safe_mkdir`, `_tmpf`, `lock_exec`, `_thread_read_window_locked`, `ui_state_write`, `ensure_run_tmpdir`, `jq`, `mv`, `chmod`, `tail`, `wc`.

* `thread_append`
  * **Scopo**: Accoda un nuovo messaggio al registro NDJSON del thread generando un ID univoco (hash SHA-256); coordina la scrittura atomica sotto lock flock e aggiorna i metadati del thread e l'indice globale.
  * **Input**: `$1` (thread ID), `$2` (ruolo: `"user"`, `"assistant"`, `"system"`), `$3` (contenuto), `$4` (metadati JSON).
  * **Output**: Record accodato al database NDJSON (`0600`). Ritorna `0` o `1`.
  * **Side-effects**: Scrittura atomica sotto lock, marker di concorrenza PID, aggiornamento stato UI.
  * **Dipendenze**: `thread_validate_id`, `thread_now_ts`, `safe_mkdir`, `_tmpf`, `ui_state_write`, `lock_exec`, `_update_thread_index`, `ensure_run_tmpdir`, `jq`, `sha256sum`, `openssl`, `flock`, `chmod`, `wc`, `tail`.

* `_thread_hash`
  * **Scopo**: Calcola l'hash crittografico SHA-256 di una stringa o combinazione di parametri per la gestione della cache.
  * **Input**: `$1` (stringa).
  * **Output**: Digest su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `sha256sum`, `openssl`, `base64`, `awk`, `printf`.

* `thread_cache_key`
  * **Scopo**: Genera la chiave identificativa univoca di cache nel formato `<thread_id>|<hash_parametri>`.
  * **Input**: `$1` (thread ID), `$2` (parametri).
  * **Output**: Chiave stampata su standard output.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `_thread_hash`, `printf`.

* `thread_cache_get`
  * **Scopo**: Recupera i dati dalla cache se il record non è scaduto rispetto al timestamp Unix memorizzato nella prima riga; se scaduto, elimina il file.
  * **Input**: `$1` (thread ID), `$2` (parametri), `$3` (opzionale: file output).
  * **Output**: Dati su standard output o file. Ritorna `0` (valido) o `1` (scaduto/assente).
  * **Side-effects**: Rimozione fisica file se scaduto.
  * **Dipendenze**: `thread_cache_key`, `date`, `rm`, `tail`, `read`.

* `thread_cache_set`
  * **Scopo**: Salva un payload nella cache del thread con scadenza TTL (default `300` secondi), anteponendo il timestamp Unix assoluto di scadenza con permessi `0600`.
  * **Input**: `$1` (thread ID), `$2` (parametri), `$3` (TTL in secondi, default `300`), `$4` (opzionale: file sorgente o stdin).
  * **Output**: File di cache salvato. Ritorna `0` o `1`.
  * **Side-effects**: Scrittura atomica provvisoria, `mv`, `chmod 600`.
  * **Dipendenze**: `thread_cache_key`, `_tmpf`, `date`, `cat`, `chmod`, `mv`, `rm`.

* `thread_cache_invalidate`
  * **Scopo**: Invalida e cancella i file di cache per un thread specifico o per l'intera sessione.
  * **Input**: `$1` (thread ID), `$2` (opzionale: parametri specifici).
  * **Output**: Cancellazione file cache. Ritorna `0` o `1`.
  * **Side-effects**: Rimozione file da disco.
  * **Dipendenze**: `thread_cache_key`, `rm`.

* `_normalize_bool_env`
  * **Scopo**: Uniforma i parametri booleani d'ambiente (`ALLOW_API_CALLS`, `DRY_RUN`, `DEBUG`) convertendo stringhe permissive nei valori interi `1` o `0` ed esportandoli.
  * **Input**: Nessuno.
  * **Output**: Esporta variabili conformi.
  * **Side-effects**: Esportazione variabili d'ambiente.
  * **Dipendenze**: `is_truthy`, `declare`, `export`.

* `_exec_curl_secure`
  * **Scopo**: Percorso unico ed autorevole per tutte le chiamate HTTP/cURL (INV-1). Isola gli header e i token Bearer in un file temporaneo `0600` passato tramite `-H @"$hdr_file"`, eliminando qualsiasi segreto dalla tabella dei processi (`argv` / `ps aux` safe). Rimuove immediatamente il file header al termine.
  * **Input**: `$1` (metodo HTTP, default `"POST"`), `$2` (URL), `$3` (chiave API), `$4` (payload file), `$5` (out file), `$6` (err file), `$7` (streaming flag `1`/`0`), `$8` (opzioni extra cURL).
  * **Output**: Restituisce il codice d'uscita di cURL.
  * **Side-effects**: Connessione HTTP/HTTPS, allocazione e rimozione immediata file header, output su file o stdout.
  * **Dipendenze**: `_tmpf`, `printf`, `chmod`, `curl`, `rm`.

### BLOCCHI DI CODICE

* `PRECORE_RUN_HISTORY`: Configura la gestione e le soglie di rotazione automatica dello storico (`rotate_history`, `save_to_history`).
* `PRECORE_RUN_MANIFEST`: Implementa la gestione atomica dei manifest JSON e copie Base64 per risorse multipart sotto lock.
* `PRECORE_RUN_UTIL_HELPERS`: Definisce l'anonimizzazione crittografica degli ID thread (`anonymize_thread_id`), l'esecutore isolato di hook (`execute_isolated_hook`), la firma dei file, il rate limiting locale a sliding window (`check_local_rate_limit`) e gli allocatori temporanei sicuri.
* `PRECORE_RUN_THREAD_ENGINE`: Implementa il ciclo di vita dei thread NDJSON, acquisizione/rilascio lock flock concorrenziali, estrazione O(1) delle finestre di contesto con try-catch jq, scrittura messaggi e cache con TTL.
* `PRECORE_RUN_RUNTIME_GLOBALS`: Inizializza i default di runtime, assicura `$RUN_TMPDIR`, normalizza i booleani d'ambiente, definisce `CURL_BASE_OPTS` e la funzione autorevole `_exec_curl_secure`.

---

## 3. PROVIDER

### VARIABILI

* `GROQ_API_KEY`: Chiave API per l'autenticazione verso Groq (eredita `${GROQ_API_KEY}` o dalla variabile personalizzata definita in `PROVIDER_API_ENV_groq`).
* `PROVIDER_API_ENV_groq`: Nome dell'eventuale variabile d'ambiente personalizzata da cui estrarre la chiave per Groq.

### FUNZIONI

* `buildpayload_groq`
  * **Scopo**: Compila il file JSON di payload per l'endpoint Chat Completions di Groq gestendo messaggi, system prompt, streaming flag, temperatura e token massimi con eventuale staging Base64.
  * **Input**: Variabili globali `STREAM_MODE`, `TEMPERATURE`/`TURE`, `MAX_TOKENS`, `JSON_INPUT`, `MESSAGES_JSON`, `BUILD_MESSAGES_FILE`, `CONTENT`, `SYSTEM_PROMPT`, `MODEL`, `RUN_TMPDIR`.
  * **Output**: Assegna il percorso del payload generato a `PAYLOAD` ed esporta la variabile. Ritorna `0` o `15`.
  * **Side-effects**: Scrittura temporanei, eventuale codifica Base64 via `stage_b64`.
  * **Dipendenze**: `_mktemp_in_dir`, `_tmpf`, `is_truthy`, `is_valid_json_string`, `is_valid_json_file`, `stage_b64`, `jq`, `export`.

* `call_api_groq`
  * **Scopo**: Esegue una chiamata API sincrona non-streaming verso Groq tramite `_exec_curl_secure` salvando la risposta in `$RESP` con permessi `0600`.
  * **Input**: `BASH4LLM_PROVIDER_URL`, `GROQ_API_KEY`, `PAYLOAD`, `RUN_TMPDIR`, `RESP`, `ERRF`.
  * **Output**: Salva la risposta in `$RESP`. Ritorna `0` (HTTP 2xx), `12` (`BASH4LLM_ERR_CURL_FAILED`) o `16` (`BASH4LLM_ERR_API`).
  * **Side-effects**: Chiamata HTTP POST via `_exec_curl_secure`, decodifica payload Base64, scrittura `$RESP`.
  * **Dipendenze**: `enforce_network_policy`, `_tmpf`, `b64decode`, `_exec_curl_secure`, `mv`, `chmod`, `rm`.

* `call_api_streaming_groq`
  * **Scopo**: Esegue una chiamata API in streaming SSE verso Groq con parsing unbuffered via jq su standard output; ricostruisce la risposta JSON sintetica finale in `$RESP` e aggiorna lo stato in `last_api.json`.
  * **Input**: `GROQ_API_KEY`, `BASH4LLM_API_KEY`, `PAYLOAD`, `BASH4LLM_PROVIDER_URL`, `RUN_TMPDIR`, `RESP`, `QUIET`.
  * **Output**: Flusso token su standard output, salvataggio risposta ricostruita in `$RESP`. Ritorna `0`, `12`, `10` o `16`.
  * **Side-effects**: Connessione HTTP POST persistente, elaborazione streaming unbuffered, scrittura `$RESP` e `last_api.json`.
  * **Dipendenze**: `enforce_network_policy`, `_tmpf`, `b64decode`, `_exec_curl_secure`, `ui_state_write`, `jq`, `tee`, `grep`, `sed`, `chmod`, `rm`.

* `refresh_models_groq`
  * **Scopo**: Interroga l'endpoint `/openai/v1/models` di Groq, normalizza e filtra i modelli e salva la lista aggiornata in `$MODELS_FILE` sotto lock esclusivo.
  * **Input**: `GROQ_API_KEY`, `BASH4LLM_PROVIDER_URL`, `MAX_MODELS`, `MODELS_FILE`, `MODELS_LOCK`.
  * **Output**: File `$MODELS_FILE` aggiornato con permessi `0600`. Ritorna `0`, `10`, `16` o `15`.
  * **Side-effects**: Chiamata HTTP GET, staging Base64 via `b64_atomic_write`, scrittura atomica sotto lock `lock_exec`.
  * **Dipendenze**: `ensure_run_tmpdir`, `resolve_provider_url`, `_exec_curl_secure`, `safe_mkdir`, `b64_atomic_write`, `lock_exec`, `jq`, `awk`, `sort`, `chmod`.

* `validate_model_groq`
  * **Scopo**: Convalida la compatibilità del modello richiesto rispetto al catalogo locale di Groq.
  * **Input**: `$1` (nome modello).
  * **Output**: Ritorna `0` se supportato, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `validate_model_core`.

* `validate_key_groq`
  * **Scopo**: Valida la chiave API di Groq effettuando una richiesta di test con timeout ridotto (10s) all'endpoint dei modelli.
  * **Input**: `$1` (chiave API).
  * **Output**: Ritorna `0` (valida/HTTP 200), `1` (non valida/errore HTTP), `28` (timeout).
  * **Side-effects**: Richiesta HTTP GET diagnostica.
  * **Dipendenze**: `_mktemp_in_dir`, `_tmpf`, `_exec_curl_secure`, `rm`.

* `auto_select_model_groq`
  * **Scopo**: Seleziona automaticamente il primo modello supportato per I/O testuale leggendo dal file modello canonico o da `$MODELS_FILE`.
  * **Input**: Nessuno.
  * **Output**: Nome modello normalizzato su standard output. Ritorna `0` o `1`.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `canonical_model_file`, `_normalize_model_name`, `is_supported_model`, `head`.

### BLOCCHI DI CODICE

* `GROQ_API_KEY_override`: Controlla se è impostata una variabile d'ambiente personalizzata (`PROVIDER_API_ENV_groq`) e la assegna a `GROQ_API_KEY`.

---

## 4. CORE_SETUP

### VARIABILI

* `JSON_INPUT`: Input strutturato JSON fornito dall'utente.
* `TEMPLATE`: Nome del template di prompt da applicare.
* `BATCH_FILE`: Percorso del file con prompt batch.
* `CHAT_MODE`: Flag booleano (`1` o `0`) per attivare la TUI REPL.
* `SET_DEFAULT_MODEL`: Modello da impostare come default per il provider attivo.
* `LIST_MODELS`: Flag booleano (`1` o `0`) per elencare i modelli.
* `LIST_PROVIDERS`: Flag booleano (`1` o `0`) per elencare i provider installati.
* `LIST_PROVIDERS_RAW`: Flag per emettere l'elenco provider in formato testo crudo.
* `LIST_MODELS_RAW`: Flag per emettere l'elenco modelli in formato testo crudo.
* `FORCE_SAVE_MODE`: Regola la persistenza dell'output (`"save"` o `"nosave"`).
* `OUT_PATH`: Percorso di output personalizzato.
* `DRY_RUN`: Flag booleano (`1` o `0`) per simulazione senza rete.
* `STREAM_MODE`: Flag booleano (`1` o `0`) per streaming SSE.
* `QUIET`: Flag booleano (`1` o `0`) per inibire log informativi.
* `INSTALL_EXTRAS`: Flag booleano (`1` o `0`) per installare/sincronizzare gli extras.
* `DEBUG`: Flag di tracciamento verboso (`1` o `0`).
* `PROVIDER_CLI`: Nome provider specificato esplicitamente da CLI.
* `PROVIDER_INTERACTIVE`: Flag che richiede il menu interattivo di scelta provider.
* `SHOW_CONFIG`: Flag booleano (`1` o `0`) per mostrare la configurazione.
* `DIAGNOSTICS`: Flag booleano (`1` o `0`) per avviare l'autoverifica del sistema.
* `VALIDATE_SML`: Flag booleano (`1` o `0`) per la validazione SML v2.0.
* `VALIDATE_REGEX`: Stringa con espressione regolare POSIX ERE per validazione output.
* `SANITIZE_OUTPUT`: Flag booleano (`1` o `0`) per la pulizia ANSI dell'output.
* `JSON_DIAGNOSTICS`: Flag booleano (`1` o `0`) per emissione diagnostica JSON su stderr.
* `FILE_INPUTS`: Array dei file passati con `-f`.
* `ARGS`: Array degli argomenti posizionali CLI residui.
* `OUTPUT_MODE`: Stile output (`"text"`, `"raw"`, `"json"`, `"pretty"`).
* `MODEL_CLI_SET`: Flag interno (`1` o `0`) che traccia se il modello è stato passato da CLI (`-m`/`--model`).
* `INSTALL_EXTRAS_SRC`: Percorso sorgente da cui sincronizzare gli extras.
* `BOOTSTRAP_ONLY`: Flag booleano (`1` o `0`) per fermarsi al bootstrap dei moduli.
* `INIT_THREAD`: Flag per l'inizializzazione atomica di un thread vuoto.
* `DELETE_THREAD`: Flag per la rimozione atomica di un thread.
* `DELETE_THREAD_ID`: Identificatore del thread da eliminare.
* `RENAME_THREAD`: Flag per la ridenominazione dei metadati del thread.
* `RENAME_THREAD_ID`: Identificatore del thread da rinominare.
* `RENAME_TITLE`: Nuovo titolo da assegnare al thread.
* `RUN_SUITE`: Flag per delegare l'esecuzione alla test suite master.
* `gui_script`: Percorso locale del launcher WebApp GUI (`${BASH4LLM_EXTRAS_DIR}/gui-py/gui-py.sh`).
* `suite_script`: Percorso del launcher della test suite master (`${BASH4LLM_EXTRAS_DIR}/test/run-all-tests.sh`).
* `tui_script`: Percorso dell'interfaccia interattiva TUI (`${BASH4LLM_EXTRAS_DIR}/chat/tui-repl.sh`).
* `_B4L_RT_CTX`: Token di memoria per la sessione interattiva di sblocco Vault.
* `_engine_path`: Percorso del Session Engine (`${BASH4LLM_EXTRAS_DIR}/session/session-engine.sh`).
* `_engine_available`: Flag interno (`1` o `0`) che attesta se il Session Engine è caricato e verificato.
* `_supported_providers_arr`: Array interno dei moduli provider installati.

### FUNZIONI

* `validate_provider_interface`
  * **Scopo**: Verifica che il driver provider implementi le funzioni obbligatorie (`buildpayload_<p>`, `call_api_<p>`) e traccia quelle opzionali.
  * **Input**: `$1` (nome provider).
  * **Output**: Ritorna stato `0` (completa) o `1` (mancante).
  * **Side-effects**: Log di errore/info.
  * **Dipendenze**: `type`, `log_error`, `log_info`.

* `call_provider`
  * **Scopo**: Invoca dinamicamente una funzione definita dal provider se presente in memoria.
  * **Input**: `$1` (nome funzione), seguiti dagli argomenti.
  * **Output**: Ritorna lo stato della funzione o `127` se assente.
  * **Side-effects**: Esecuzione della routine chiamata.
  * **Dipendenze**: `type`.

* `validate_provider_key_dispatch`
  * **Scopo**: Dispaccia la validazione della chiave API delegando a `validate_key_<provider>`.
  * **Input**: `$1` (chiave API).
  * **Output**: Ritorna lo stato del validatore o `127`.
  * **Side-effects**: Invocazione metodo provider.
  * **Dipendenze**: `type`.

* `refresh_models_dispatch`
  * **Scopo**: Dispaccia l'aggiornamento dei modelli a `refresh_models_<provider>`.
  * **Input**: `$1` (opzionale: percorso file modelli).
  * **Output**: Ritorna stato `0` o codice d'errore.
  * **Side-effects**: Aggiornamento file modelli su disco.
  * **Dipendenze**: `type`, `log_error`, `log_info`, `print_persistence_reminder`.

* `validate_model_dispatch`
  * **Scopo**: Dispaccia la validazione del modello a `validate_model_<provider>` con fallback permissivo e avviso una tantum se non implementata.
  * **Input**: `$1` (nome modello).
  * **Output**: Ritorna lo stato del validatore o `0`.
  * **Side-effects**: Emissione log di avviso.
  * **Dipendenze**: `type`, `log_warn`.

* `auto_select_model_dispatch`
  * **Scopo**: Dispaccia l'auto-selezione del modello a `auto_select_model_<provider>`.
  * **Input**: Nessuno.
  * **Output**: Nome modello su standard output e stato d'uscita.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `type`.

* `_lock_security_guards`
  * **Scopo**: Blocca in sola lettura (`readonly -f`) le funzioni critiche di sicurezza e mediazione (`_exec_curl_secure`, `verify_module_integrity`, `read_secure_input`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `enforce_network_policy`, `execute_isolated_hook`) prevenendo monkey-patching o manomissioni post-boot.
  * **Input**: Nessuno.
  * **Output**: Nessuno.
  * **Side-effects**: Rende le funzioni immutabili.
  * **Dipendenze**: `readonly`.

* `resolve_model`
  * **Scopo**: Risolve il modello LLM finale seguendo l'ordine di precedenza: 1) Override CLI (`-m`); 2) File canonico `model.<provider>`; 3) Funzione `auto_select_model_dispatch`; 4) Scansione sequenziale di `$MODELS_FILE`; 5) Variabile `MODEL` nel file `config`; 6) Whitelist `$ALLOWED_MODELS`.
  * **Input**: Nessuno.
  * **Output**: Assegna il nome del modello a `FINAL_MODEL` e ritorna `0`; ritorna `1` se non risolto.
  * **Side-effects**: Lettura configurazioni e cataloghi modelli.
  * **Dipendenze**: `canonical_model_file`, `canonical_provider_file`, `validate_model_core`, `validate_model_dispatch`, `auto_select_model_dispatch`, `_normalize_model_name`, `is_supported_model`.

* `build_payload_from_vars`
  * **Scopo**: Dispaccia la costruzione del payload JSON a `buildpayload_<provider>`.
  * **Input**: Nessuno.
  * **Output**: Generazione payload. Ritorna `0` o esce con `16` (`BASH4LLM_ERR_API`) se non implementata.
  * **Side-effects**: Scrittura file payload su disco.
  * **Dipendenze**: `ensure_run_tmpdir`, `call_provider`, `log_error`.

* `call_api_once`
  * **Scopo**: Dispaccia una singola chiamata API sincrona a `call_api_<provider>` (in dry-run mostra l'header del payload e ritorna `0`).
  * **Input**: Nessuno.
  * **Output**: Ritorna lo stato dell'API o `0` in dry-run.
  * **Side-effects**: Connessione HTTP o tracciamento dry-run.
  * **Dipendenze**: `call_provider`, `show_payload_head`, `log_info`, `log_error`.

* `call_api_streaming`
  * **Scopo**: Dispaccia la chiamata API in streaming a `call_api_streaming_<provider>` sotto lock concorrenziale del thread e verifica del rate limit locale, gestendo in sicurezza i segnali di interruzione (`SIGINT`).
  * **Input**: Nessuno.
  * **Output**: Ritorna lo stato dell'API o `0` in dry-run.
  * **Side-effects**: Lock thread, connessione di rete streaming SSE, gestione trap.
  * **Dipendenze**: `acquire_thread_lock`, `release_thread_lock`, `check_local_rate_limit`, `call_provider`, `show_payload_head`, `trap`.

* `extract_api_error`
  * **Scopo**: Estrae messaggi d'errore strutturati dal JSON di risposta in `$RESP`.
  * **Input**: Nessuno (analizza `$RESP`).
  * **Output**: Messaggio d'errore su standard output.
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `jq`, `awk`, `head`.

* `detect_empty_edge_case`
  * **Scopo**: Algoritmo diagnostico per rilevare risposte vuote anomale (HTTP 200 con `finish_reason: "stop"` e token <= 1 ma prive di testo utile).
  * **Input**: Nessuno (analizza `$RESP`).
  * **Output**: Popola `BASH4LLM_EDGE_EMPTY` (`1` o `0`), `BASH4LLM_EDGE_REQ_ID`, `BASH4LLM_EDGE_FINISH_REASON`, `BASH4LLM_EDGE_COMPLETION_TOKENS`.
  * **Side-effects**: Duplicazione temporanea protetta per analisi.
  * **Dipendenze**: `_tmpf`, `is_valid_json_file`, `cp`, `jq`, `rm`.

* `finalize_and_output`
  * **Scopo**: Formatta e stampa i risultati secondo `$OUTPUT_MODE` (`text`, `raw`, `json`, `pretty`); esegue la sanificazione ANSI/POSIX se `SANITIZE_OUTPUT=1` e salva automaticamente su disco sotto lock se l'output supera la soglia `$THRESHOLD` o se forzato da `--save`.
  * **Input**: `$1` (formato output), `$2` (testo risultato).
  * **Output**: Output formattato su standard output e salvataggio transazionale opzionale. Ritorna `0` o `15`.
  * **Side-effects**: Scrittura output, sanificazione testo, salvataggio su file sotto lock.
  * **Dipendenze**: `_tmpf`, `safe_mkdir`, `lock_exec`, `verify_module_integrity`, `is_truthy`, `log_error`, `cat`, `jq`, `printf`, `chmod`.

* `validate_response_syntax`
  * **Scopo**: Esegue la validazione sintattica della risposta: verifica la conformità allo standard EBNF SML v2.0 (se `VALIDATE_SML=1`) o controlla la corrispondenza con l'espressione regolare POSIX ERE fornita in `VALIDATE_REGEX`.
  * **Input**: `$1` (testo risposta).
  * **Output**: Ritorna `0` se valida, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `is_truthy`, `grep`.

* `perform_request_once`
  * **Scopo**: Orchestratore transazionale della richiesta sincrona: acquisisce lock thread, esegue hook pre-esecuzione, valida il rate limit locale, avvia il ciclo di retry (fino a `MAX_RETRIES`), valida la sintassi della risposta via `validate_response_syntax`, esegue diagnostica casi vuoti, gestisce hook post-esecuzione con eventuale override del payload da `TRANSFORMED_PAYLOAD`/`FALLBACK_PAYLOAD`, aggiorna `last_api.json` e formatta l'output.
  * **Input**: Argomenti `$@`.
  * **Output**: Risultato formattato e codici di stato. Ritorna `0` (successo), `13` (`BASH4LLM_ERR_PARSE` se fallisce la validazione sintattica), `16` (`BASH4LLM_ERR_API`) o `17` (`BASH4LLM_ERR_SEC`).
  * **Side-effects**: Lock concorrenziali, chiamate di rete, invocazione hook isolati, scritture stato UI.
  * **Dipendenze**: `acquire_thread_lock`, `release_thread_lock`, `execute_isolated_hook`, `check_local_rate_limit`, `call_api_once`, `extract_text_from_resp`, `validate_response_syntax`, `detect_empty_edge_case`, `ui_state_write`, `extract_api_error`, `finalize_and_output`, `b64decode`, `trap`, `sleep`.

* `collect_input_from_files`
  * **Scopo**: Legge e unifica i file passati con `-f` validandone la sicurezza tramite `validate_file_input` (arresta con codice `17` se binari o non sicuri).
  * **Input**: Array di percorsi file `$@`.
  * **Output**: Testo concatenato con delimitatori su standard output.
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `file_readable`, `validate_file_input`, `log_error`, `cat`.

* `expand_args_to_content`
  * **Scopo**: Converte gli argomenti CLI posizionali in testo di prompt: legge e convalida i file esistenti o accoda direttamente le stringhe letterali.
  * **Input**: Elementi dell'array `$ARGS`.
  * **Output**: Testo unificato su standard output.
  * **Side-effects**: Lettura file.
  * **Dipendenze**: `file_readable`, `validate_file_input`, `log_error`, `cat`.

* `file_readable`
  * **Scopo**: Convalida se un percorso corrisponde a un file regolare leggibile.
  * **Input**: `$1` (percorso file).
  * **Output**: Ritorna `0` se leggibile, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: Test shell `[ -r ... ] && [ -f ... ]`.

* `is_supported_model`
  * **Scopo**: Verifica che il modello sia compatibile con I/O testuale escludendo modelli per visione/immagini, audio/whisper, tts, embedding o multimodali non-standard.
  * **Input**: `$1` (nome modello).
  * **Output**: Ritorna `0` se compatibile, `1` se escluso.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: `tr`.

* `list_models_cli`
  * **Scopo**: Formatta ed elenca a schermo i modelli locali normalizzati evidenziando con badge colorato quelli non supportati per I/O testuale.
  * **Input**: Nessuno (analizza `$MODELS_FILE`).
  * **Output**: Elenco stampato su standard output. Ritorna `0` o `1`.
  * **Side-effects**: Scrittura output.
  * **Dipendenze**: `_normalize_model_name`, `is_supported_model`, `printf`.

* `validate_model_core`
  * **Scopo**: Algoritmo centrale di validazione: normalizza il nome del modello, controlla se è registrato in `$MODELS_FILE` e verifica la compatibilità con `is_supported_model`.
  * **Input**: `$1` (nome modello).
  * **Output**: Ritorna `0` se valido, `1` in caso di errore.
  * **Side-effects**: Log di errore.
  * **Dipendenze**: `_normalize_model_name`, `is_supported_model`, `log_error`, `grep`.

* `load_local_config`
  * **Scopo**: Carica in memoria i parametri chiave/valore dal file `config` locale (`MODEL`, `TEMPERATURE`/`TURE`, `MAX_TOKENS`, `OUTPUT_MODE`/`FORMAT`, `THRESHOLD`).
  * **Input**: Nessuno.
  * **Output**: Assegnazione variabili globali.
  * **Side-effects**: Modifica variabili in memoria.
  * **Dipendenze**: Lettura file.

* `load_whitelist`
  * **Scopo**: Carica e normalizza tutti i modelli autorizzati presenti in `$MODELS_FILE` memorizzandoli nella stringa globale `ALLOWED_MODELS`.
  * **Input**: Nessuno (analizza `$MODELS_FILE`).
  * **Output**: Popola `ALLOWED_MODELS`.
  * **Side-effects**: Modifica variabile globale in memoria.
  * **Dipendenze**: `_normalize_model_name`.

* `is_tty_out`
  * **Scopo**: Verifica se lo standard output è collegato a un terminale interattivo TTY reale.
  * **Input**: Nessuno.
  * **Output**: Ritorna `0` se TTY, `1` altrimenti.
  * **Side-effects**: Nessuno.
  * **Dipendenze**: Test shell `[ -t 1 ]`.

### BLOCCHI DI CODICE

* `CORE_SETUP_DISPATCH_HELPERS`: Registra le routine di dispatch verso i moduli provider e sigilla le guardie di sicurezza con `_lock_security_guards`.
* `CORE_SETUP_API_CALL`: Definisce la risoluzione modelli (`resolve_model`), il payload dispatch, le chiamate sincrone e streaming, la diagnostica e l'orchestratore transazionale con retry `perform_request_once`.
* `CORE_SETUP_INPUT_HELPERS`: Gestisce la lettura e validazione di file e argomenti, l'anonimizzazione immediata di `$THREAD_ID` tramite `anonymize_thread_id`, e il caricamento via sourcing con sblocco interattivo Vault (`_B4L_RT_CTX`) e pulizia automatica del namespace (`_cleanup_sourced_env`).
* `CORE_SETUP_CLI_PARSE`: Analizza tutte le opzioni della riga di comando. Comprende:
  * **Gatekeeper WebApp GUI (`--gui`, `--webapp`)**: Intercetta l'opzione, definisce `gui_script="${BASH4LLM_EXTRAS_DIR}/gui-py/gui-py.sh"`, verifica l'esistenza e leggibilità (Fail-Closed, uscita `15`), esegue `validate_path_security` (INV-4, uscita `17`), valida l'integrità SHA-256 rispetto al manifest vendor via `verify_module_integrity` (uscita `17`) e trasferisce atomicamente il processo con `exec bash "$gui_script" "$@"`.
  * **Gatekeeper Test Suite (`--test`, `--run-all-tests`, `--run-all-test`)**: Verifica esistenza, `validate_path_security` e `verify_module_integrity` su `${BASH4LLM_EXTRAS_DIR}/test/run-all-tests.sh` ed esegue `exec bash "$suite_script" "$@"`.
  * **Gestione Thread, Vault e Tuning**: Parsing di `--thread`, `--thread-window`, `--init-thread`, `--delete-thread`, `--rename-thread`, `--title`, `--vault`, `--validate-sml`, `--validate-regex`, `--sanitize`, `--json-diagnostics`, parametri di temperatura, token e formattazione output.
* `CORE_SETUP_SESSION_ENGINE`: Importa e valida sintatticamente e crittograficamente il modulo esterno `session-engine.sh` abilitando `_engine_available=1` o impostando il fallback sui metodi storici legacy.
* `CORE_SETUP_NORM_FLAGS`: Mappa dinamicamente tutti i moduli provider installati nelle directory vendor (`providers/*.sh`) e locali (`local-extras/providers/*.sh`) popolando `SUPPORTED_PROVIDERS`.
* `CORE_SETUP_ACTIONS`: Esegue comandi amministrativi immediati:
  * Cancellazione thread (`--delete-thread`), ridenominazione thread (`--rename-thread`), listati provider e modelli (`--list-providers`, `--list-models`), impostazione modello predefinito (`--set-default`), inizializzazione thread (`--init-thread`).
  * **Installazione/Sincronizzazione Extras (`--install-extras`)**: Esegue la sincronizzazione ricorsiva con `cp -R`, imposta tutte le directory a `0700` e tutti i file a `0600` (Principio del Minimo Privilegio), concede i bit di esecuzione `0700` **esclusivamente** ai 4 entrypoint autorizzati:
    1. `$DEST_BASE/security/output-sanitizer.sh`
    2. `$DEST_BASE/chat/tui-repl.sh`
    3. `$DEST_BASE/gui-py/gui-py.sh`
    4. `$DEST_BASE/test/*.sh`
    ed effettua la verifica di integrità di tutti i file rispetto a `manifest.sha256`.

---

## 5. CORE_PROVIDER

### VARIABILI

* `_supported_providers_arr`: Array per la memorizzazione e l'indicizzazione dei moduli provider rilevati ed installati.
* `SUPPORTED_PROVIDERS`: Elenco dei provider supportati separati da spazio.
* `PROVIDER`: Identificatore del provider attivo.
* `PROVIDER_INTERACTIVE_SELECTED`: Flag booleano (`1` o `0`) attestante la selezione del provider via menu interattivo.
* `FINAL_MODEL`: Nome del modello risolto e validato pronto per l'inferenza.
* `STDIN_CONTENT`: Buffer di memoria per il flusso di testo catturato da standard input.
* `BASH4LLM_CORE_SCRIPT`: Percorso canonico dello script core risolto dinamicamente (`${SCRIPTDIR}/$(basename "${BASH_SOURCE[0]}")`), esportato nell'ambiente prima della delega all'interfaccia interattiva TUI.
* `BASH4LLM_ACTIVE_THREAD`: Variabile di contesto esportata contenente l'ID del thread attivo (`${THREAD_ID}`).
* `BASH4LLM_ACTIVE_MODEL`: Variabile di contesto esportata contenente il modello risolto (`${MODEL}`).
* `BASH4LLM_ACTIVE_TEMPERATURE`: Variabile di contesto esportata contenente la temperatura attiva (`${TEMPERATURE}`).

### FUNZIONI

* `validate_provider_interface`
  * **Scopo**: Verifica che il modulo provider attivo implementi le funzioni obbligatorie (`buildpayload_<p>`, `call_api_<p>`).
  * **Input**: `$1` (nome provider).
  * **Output**: Ritorna stato `0` (completa) o `1` (mancante).
  * **Side-effects**: Log di errore/info.
  * **Dipendenze**: `type`, `log_error`, `log_info`.

* `assemble_content`
  * **Scopo**: Compila ed unifica la stringa del prompt finale `$CONTENT` seguendo le priorità: 1) Input JSON diretto (`JSON_INPUT`); 2) File da opzione `-f` concatenati via `collect_input_from_files`; 3) File di template (`TEMPLATE`) con sostituzione atomica del segnaposto `{{CONTENT}}` via awk; 4) Flusso da standard input (`STDIN_CONTENT`); 5) Argomenti posizionali CLI unificati via `expand_args_to_content`.
  * **Input**: Variabili globali `JSON_INPUT`, `FILE_INPUTS`, `TEMPLATE`, `STDIN_CONTENT`, `ARGS`, `BASH4LLM_TEMPLATES_DIR`, `RUN_TMPDIR`.
  * **Output**: Assegna la stringa risultante a `CONTENT`. Ritorna stato `0`.
  * **Side-effects**: Lettura file, staging temporaneo atomico, sostituzione awk.
  * **Dipendenze**: `collect_input_from_files`, `expand_args_to_content`, `ensure_run_tmpdir`, `_mktemp_in_dir`, `cat`, `awk`, `mv`, `rm`, `printf`.

### BLOCCHI DI CODICE

* `CORE_PROVIDER_PRO_LOAD_INITIALIZATION`: Gestisce la selezione e persistenza del provider:
  * Da CLI non interattiva: salva in `$PROVIDER_FILE` con permessi `0600` via `atomic_write`, rimuove il vecchio file URL e carica il modulo con `load_provider_module`.
  * Da menu interattivo: visualizza la lista numerata dei provider disponibili, acquisisce la scelta dell'utente da stdin, la persiste in `$PROVIDER_FILE` (`0600`) e carica il modulo.
  * Per Groq embedded: scrive l'URL di default nel file canonico se mancante via `write_provider_url_if_missing`.

* `CORE_PROVIDER_PRO_LOAD_VALIDATION_REFRESH`: Convalida la conformità dell'interfaccia provider via `validate_provider_interface`. Se è stato richiesto `--refresh-models`, assicura la chiave API via `ensure_api_key_for_provider`, avvia l'allineamento con `refresh_models_dispatch` ed esce con stato `0`. Se il file modelli è assente o vuoto, tenta il refresh automatico in background.

* `CORE_PROVIDER_SHOW`: Soddisfa le interrogazioni diagnostiche ed esce con stato `0`:
  * `--print-config-dir`: Stampa il percorso canonico della configurazione.
  * `--print-provider-file`: Stampa il percorso del file provider.
  * `--print-model-file`: Stampa il percorso del file modello del provider.
  * `--show-config`: Stampa la tabella riepilogativa della configurazione corrente.
  * `--diagnostics`: Esegue l'autoverifica completa dello stato del sistema: esistenza e permessi cartelle, stato del manifest di integrità degli extras, stato del Vault OpenSSL (abilitazione, sblocco sessione `_B4L_RT_CTX`, supporto PBKDF2, inizializzazione chiavi) ed esegue un test reale di TLS Handshake verso l'endpoint remoto attivo via `diagnose_tls_connection`.

* `CORE_PROVIDER_MAIN_RESOLVE`: Se `BOOTSTRAP_ONLY=1`, termina con `0`. Carica configurazioni e whitelist, alloca `$RUN_TMPDIR`, risolve il modello LLM finale con `resolve_model` ed esegue le convalide sintattiche `validate_model_core` e `validate_model_dispatch`. Se lo standard input è una pipe (`cat -`), cattura il testo in `STDIN_CONTENT`; se rileva un JSON strutturato con chiave API, la estrae ed esporta sovrascrivendo e cancellando immediatamente il buffer di memoria.

* `CORE_PROVIDER_MAIN_EXECUTION`: Esegue il ciclo principale di inferenza:
  1. Invoca `assemble_content` per compilare il prompt. Blocca con codice `14` (`BASH4LLM_ERR_NO_PROMPT`) se il prompt è vuoto (salvo chat, batch o init-thread).
  2. **Elaborazione BATCH (`BATCH_FILE` attivo)**: Scansiona il file riga per riga, prepara la finestra di contesto del thread (via Session Engine o `thread_read_window`), costruisce il payload, assicura la chiave ed esegue le chiamate in sequenza.
  3. **Chat Interattiva (`CHAT_MODE` attivo)**: Valorizza ed esporta nell'ambiente:
     * `BASH4LLM_CORE_SCRIPT="${SCRIPTDIR}/$(basename "${BASH_SOURCE[0]}")"`
     * `BASH4LLM_ACTIVE_THREAD="${THREAD_ID}"`
     * `BASH4LLM_ACTIVE_MODEL="${MODEL}"`
     * `BASH4LLM_ACTIVE_TEMPERATURE="${TEMPERATURE}"`
     Valida il percorso e l'integrità crittografica di `${BASH4LLM_EXTRAS_DIR}/chat/tui-repl.sh` e trasferisce atomicamente il controllo tramite `exec bash "$tui_script" "$@"`.
  4. **Esecuzione Singola (Streaming o Sincrona)**:
     * Risolve la finestra di contesto storica compilandola in `$BUILD_MESSAGES_FILE` se è attivo un thread.
     * Costruisce il payload JSON via `build_payload_from_vars`.
     * Valida e recupera la chiave API via `ensure_api_key_for_provider` (salvo in `DRY_RUN`).
     * **Streaming (`STREAM_MODE=1`)**: Invoca `call_api_streaming` sotto lock thread; a completamento (salvo in `DRY_RUN`), accoda la richiesta utente e la risposta dell'assistente nel database NDJSON del thread (via Session Engine o `thread_append`) ed esce con `0`.
     * **Sincrono (`STREAM_MODE=0`)**: Visualizza prompt e modello su console se in TTY verboso, esegue `perform_request_once` sotto lock thread, formatta l'output via `finalize_and_output`, registra l'interazione nel registro NDJSON del thread ed esce con stato `0` (o termina con il codice d'errore in caso di fallimento dopo aver registrato il tentativo).
