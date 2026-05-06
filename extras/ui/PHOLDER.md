[![GroqBash⁺ GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 

### Placeholder CGI: elenco completo e specifiche.  🇮🇹 [🇬🇧](PHOLDER-en.md)

## Fonte di Verità Unificata dei Placeholder (GUI + CGI)

---

### Nota introduttiva architetturale
**Sintesi:** GroqBash⁺ separa nettamente due classi di placeholder:

- **Placeholder GUI (1–19)** — generati e popolati **interamente dalla GUI** (`gui-server.sh`, `gui-bootstrap.sh`). Sono valori di presentazione usati da `render_template()` e non fanno parte del contratto runtime tra backend e frontend.
- **Placeholder CGI (20–23)** — generati **dal backend / core** (o da moduli engine opzionali). Sono valori runtime che la GUI **non può calcolare da sola** e costituiscono il **contratto CGI** tra backend e GUI.

Questo documento esteso descrive **per ciascun placeholder** (1–23) solo informazioni **certe al 100%** ricavate dai file analizzati (`gui-bootstrap.sh`, `gui-server.sh`, `extras/ui/static/gui-lang.conf`) e dalle funzioni del core e degli extras citati nei file. Per ogni placeholder sono indicate: **Pagine**, **Tipo**, **Origine**, **Sanitizzazione / Validazione**, **Obblig./Opz.**, **Funzioni `.sh` coinvolte**, **File coinvolti**, **Fallback**, **Note di sicurezza / operazionali**.

---

## Pipeline dei dati (riassunto)
- **Placeholder GUI (1–19)**  
  `GUI (gui-server.sh / gui-bootstrap.sh)` → **sanitize/validate** (`sanitize_param`, `validate_name`, `sanitize_model_output`, `html_escape`) → `render_template()` → HTML.
- **Placeholder CGI (20–23)**  
  `groqbash` / engine → produce valori primitivi (file NDJSON, variabili locali, file di history) → GUI legge/normalizza (`session_read_window`, `detect_empty_edge_case`, `save_to_history`, test esistenza funzioni provider) → **sanitize** (`html_escape`, `sanitize_param`) → `render_template()` → HTML.

---

## SEZIONE 1 — PLACEHOLDER GUI (1–19)

#### 1. `{{LANG_CODE}}`
- **Pagine:** header, content, footer, main, settings (tutti i template che ricevono `esc_lang`).
- **Tipo:** codice lingua (stringa, es. `en`, `it`).
- **Origine:** query `lang` (via `get_query_param`) o file `LANG_CURRENT_FILE` (lettura tramite `read_config_or_default`).
- **Sanitizzazione / Validazione:** `sanitize_param`; pattern di validazione usato nel codice: `^[A-Za-z_-]+$` quando necessario; passato ai template come `html_escape`.
- **Obblig./Opz.:** opzionale (default `en`).
- **Funzioni coinvolte:** `get_query_param`, `read_config_or_default`, `sanitize_param`, `html_escape`.
- **File coinvolti:** `LANG_CURRENT_FILE` (config).
- **Fallback:** `en` (via `read_config_or_default`).
- **Note di sicurezza:** sempre `html_escape` prima di inserire in template.

#### 2. `{{THEME}}`
- **Pagine:** header, content, footer, main, settings.
- **Tipo:** `light` | `dark`.
- **Origine:** query `theme` o file `THEME_CURRENT_FILE` (via `read_config_or_default`).
- **Sanitizzazione / Validazione:** `sanitize_param`; accepted values explicitly checked (`"light"` or `"dark"`).
- **Obblig./Opz.:** opzionale (default `light`).
- **Funzioni coinvolte:** `get_query_param`, `read_config_or_default`, `atomic_write_safe` (per persistenza), `html_escape`.
- **File coinvolti:** `THEME_CURRENT_FILE`.
- **Fallback:** `light`.
- **Note:** genera anche `{{THEME_IS_light}}` / `{{THEME_IS_dark}` (valori `selected`/empty).

#### 3. `{{PROVIDER_CURRENT}}`
- **Pagine:** header, content, footer, main, settings.
- **Tipo:** stringa (nome provider).
- **Origine:** `get_default_provider()` → `DEFAULT_PROVIDER_FILE` (lettura con `read_config_or_default`).
- **Sanitizzazione / Validazione:** `sanitize_param`; `validate_name` usata quando si imposta/usa il provider.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `get_default_provider`, `read_config_or_default`, `sanitize_param`, `validate_name`.
- **File coinvolti:** `DEFAULT_PROVIDER_FILE`, `PROVIDER_CACHE_FILE` (per opzioni).
- **Fallback:** vuoto se non configurato.
- **Note:** usato per generare `{{PROVIDER_OPTIONS}}`.

#### 4. `{{MODEL_CURRENT}}`
- **Pagine:** header, content, footer, main, settings.
- **Tipo:** stringa (nome modello).
- **Origine:** `get_default_model()` → `DEFAULT_MODEL_FILE`.
- **Sanitizzazione / Validazione:** `sanitize_param`; `validate_name` quando impostato o passato al core.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `get_default_model`, `read_config_or_default`, `sanitize_param`, `validate_name`.
- **File coinvolti:** `DEFAULT_MODEL_FILE`, `models.*.txt` (cache).
- **Fallback:** vuoto o primo modello nella whitelist (se presente).
- **Note:** usato per `MODEL_OPTIONS`, `MODEL_SELECT_OPTIONS`, `MODEL_LIST_SCROLL`.

#### 5. `{{API_KEY_FIELD}}`
- **Pagine:** header, content, footer, main, settings.
- **Tipo:** stringa (contenuto API key), **HTML-escaped**.
- **Origine:** `read_api_key_file()` → `API_KEY_FILE`.
- **Sanitizzazione / Validazione:** letto con `sed -n '1p'`; passato a template tramite `html_escape`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `read_api_key_file`, `save_api_key_file`, `html_escape`.
- **File coinvolti:** `API_KEY_FILE`.
- **Fallback:** vuoto se non presente.
- **Note di sicurezza:** file `API_KEY_FILE` è scritto con `chmod 600` da `save_api_key_file`; visualizzazione è HTML-escaped.

#### 6. `{{LANG_OPTIONS}}`
- **Pagine:** header, content, footer, main, settings.
- **Tipo:** blocco HTML `<option>`.
- **Origine:** `build_lang_options()` → lettura di `gui-lang.conf` (candidati tramite `find_lang_conf`).
- **Sanitizzazione / Validazione:** `sanitize_param` su code/label; `html_escape` per output.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `find_lang_conf`, `build_lang_options`, `sanitize_param`, `html_escape`.
- **File coinvolti:** `gui-lang.conf` (possibili percorsi: `CFG_DIR`, `UI_ROOT/static`, `extras/ui`, ecc.).
- **Fallback:** vuoto se file mancante.
- **Note:** labels e codici sempre `html_escape`.

#### 7. `{{MODEL_OPTIONS}}`
- **Pagine:** header, content, footer, main, settings.
- **Tipo:** blocco HTML `<option>`.
- **Origine:** `build_model_options()` → `get_models_file()` (file modelli).
- **Sanitizzazione / Validazione:** `sanitize_param` per ogni modello; `html_escape` per output.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `get_models_file`, `build_model_options`, `sanitize_param`, `html_escape`.
- **File coinvolti:** `models/models.txt` o `CFG_DIR/models.<provider>.txt`.
- **Fallback:** vuoto se file mancante.
- **Note:** lista derivata dal file modelli risolto.

#### 8. `{{PROVIDER_OPTIONS}}`
- **Pagine:** settings.
- **Tipo:** blocco HTML `<option>`.
- **Origine:** `build_provider_options()` → `PROVIDER_CACHE_FILE` (`providers.txt`), con chiamata preventiva a `ensure_provider_cache_fresh`.
- **Sanitizzazione / Validazione:** `sanitize_param` + `html_escape`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `build_provider_options`, `ensure_provider_cache_fresh`, `sanitize_param`, `html_escape`.
- **File coinvolti:** `PROVIDER_CACHE_FILE` (`CFG_DIR/providers.txt`).
- **Fallback:** vuoto se cache mancante.
- **Note:** `ensure_provider_cache_fresh` può invocare `groqbash --list-providers-raw`.

#### 9. `{{MODEL_LIST_SCROLL}}`
- **Pagine:** settings.
- **Tipo:** testo multilinea (lista modelli, una per riga).
- **Origine:** `build_model_list_and_select()` (parte di output non-HTML `<option>`).
- **Sanitizzazione / Validazione:** `sanitize_param` per ogni riga; `html_escape` quando inserito in template.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `build_model_list_and_select`, `sanitize_param`, `html_escape`.
- **File coinvolti:** file modelli risolto da `get_models_file`.
- **Fallback:** vuoto se file mancante.

#### 10. `{{MODEL_SELECT_OPTIONS}}`
- **Pagine:** settings.
- **Tipo:** blocco HTML `<option>`.
- **Origine:** `build_model_list_and_select()` (provider-aware).
- **Sanitizzazione / Validazione:** `sanitize_param`, `html_escape`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `build_model_list_and_select`, `sanitize_param`, `html_escape`.
- **File coinvolti:** file modelli.

#### 11. `{{CONV_LIST}}`
- **Pagine:** main, settings.
- **Tipo:** testo/HTML (lista conversazioni con titoli).
- **Origine:** `build_conv_list()` → enumerazione `CONV_DIR` (`conv-*.txt`) + `read_conv_title()`.
- **Sanitizzazione / Validazione:** `html_escape` su basename e titolo.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `build_conv_list`, `read_conv_title`, `html_escape`.
- **File coinvolti:** `CONV_DIR/*` (es. `conv-001.txt`, `*.title`).
- **Fallback:** vuoto se directory vuota.

#### 12. `{{CURRENT_CONV_FILE}}`
- **Pagine:** main, settings.
- **Tipo:** stringa (basename).
- **Origine:** `get_current_conversation_file()` → legge `CURRENT_CONV_FILE` e costruisce percorso in `CONV_DIR`.
- **Sanitizzazione / Validazione:** `sanitize_param`, `validate_name` (fallback a `conv-001.txt` se invalido).
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `get_current_conversation_file`, `read_config_or_default`, `sanitize_param`, `validate_name`, `atomic_write`.
- **File coinvolti:** `CURRENT_CONV_FILE` (config), file effettivo in `CONV_DIR`.
- **Fallback:** `conv-001.txt`.

#### 13. `{{MODEL_WHITELIST_PRESENT}}`
- **Pagine:** main, settings.
- **Tipo:** booleano (`true` | `false`).
- **Origine:** `get_models_file()` + controllo primo record non vuoto (`awk 'NF{print; exit}'`).
- **Sanitizzazione / Validazione:** controllo presenza di almeno una riga non vuota nel file modelli.
- **Obblig./Opz.:** sempre presente (GUI imposta `MODEL_WHITELIST_PRESENT`).
- **Funzioni coinvolte:** `get_models_file`, `awk` check.
- **File coinvolti:** file modelli risolto.
- **Fallback:** `false` se file mancante o vuoto.

#### 14. `{{CONFIGURED}}`
- **Pagine:** main, settings.
- **Tipo:** booleano (`true` | `false`).
- **Origine:** `is_configured()` (controlla default provider, API key, e modello o file modelli non vuoto).
- **Sanitizzazione / Validazione:** logica deterministica in `is_configured`.
- **Obblig./Opz.:** sempre presente (GUI esporta `CONFIGURED`).
- **Funzioni coinvolte:** `is_configured`, `read_api_key_file`, `get_default_provider`, `get_default_model`, `get_models_file`.
- **Note:** usato per mostrare avvisi di configurazione.

#### 15. `{{GUI_CGI_BASE}}`
- **Pagine:** tutte (usato per costruire URL base).
- **Tipo:** stringa (URL base).
- **Origine:** env `GUI_CGI_BASE` o default `"/groqbash-gui/cgi/"` (normalizzato).
- **Sanitizzazione / Validazione:** `html_escape`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** assegnazione diretta in `render_page_*`.
- **Note:** normalizzato con trailing slash.

#### 16. `{{THEME_IS_light}}` / `{{THEME_IS_dark}}`
- **Pagine:** header, settings.
- **Tipo:** stringa (`selected` | vuoto).
- **Origine:** derivato da `THEME` (se `light` → `THEME_IS_light="selected"`).
- **Sanitizzazione / Validazione:** `html_escape` se necessario.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** logica in `render_page_*`.

#### 17. `{{CURRENT_CONV}}`
- **Pagine:** main.
- **Tipo:** blocco HTML `<pre>...</pre>`.
- **Origine:** `build_current_conv_block()` → legge file conversazione corrente, riga per riga, applica `sanitize_model_output` e `html_escape`.
- **Sanitizzazione / Validazione:** `sanitize_model_output` (rimozione ANSI, controllo lunghezza, truncamento) + `html_escape`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `build_current_conv_block`, `get_current_conversation_file`, `sanitize_model_output`, `html_escape`, `html_unescape`/`html_unescape_fallback`.
- **File coinvolti:** file conversazione in `CONV_DIR`.
- **Note di sicurezza:** output è HTML-escaped e racchiuso in `<pre>`.

#### 18. `{{TXT_<KEY>}}`
- **Pagine:** tutte.
- **Tipo:** stringa (HTML-escaped).
- **Origine:** variabile shell (se definita) o `gui-lang.conf` tramite `read_txt_key()`; fallback su `DEFAULT_LANG`.
- **Sanitizzazione / Validazione:** `html_escape`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `read_txt_key`, `find_lang_conf`, `html_escape`.
- **File coinvolti:** `gui-lang.conf` (possibili percorsi).
- **Note:** usato per localizzazione testuale.

#### 19. Posizionali `{{1}}`, `{{2}}`, …
- **Pagine:** tutte.
- **Tipo:** stringhe HTML-escaped.
- **Origine:** argomenti passati a `render_template()` (posizionali).
- **Sanitizzazione / Validazione:** `html_escape` applicato in `render_template`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `render_template`, `html_escape`.

---

## SEZIONE 2 — PLACEHOLDER CGI (20–23)
*(nuove funzionalità lato backend; la GUI deve leggere/esporre questi valori dal backend o dai file prodotti dal backend)*

### 20. Placeholder CGI — Session Management

#### 20.1 `{{SESSION_ACTIVE}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** booleano (`true` | `false`).
- **Origine:** **assenza/presenza** di file sessione `${GROQBASH_HISTORY_DIR%/}/sessions/${SESSION_ID}.ndjson` o stato fornito dal Session Engine opzionale (`extras/session/session-engine.sh`) se presente.
- **Sanitizzazione / Validazione:** determinazione tramite `session_validate_id` per `SESSION_ID` e controllo esistenza file; GUI deve `html_escape` se visualizzato.
- **Obblig./Opz.:** sempre presente nella sezione CGI (la GUI dovrebbe mostrare lo stato).
- **Funzioni coinvolte:** `session_validate_id`, `session_read_window` (per ricavare messaggi), eventuali funzioni del Session Engine (`session_engine_enabled`).
- **File coinvolti:** `${GROQBASH_HISTORY_DIR}/sessions/*.ndjson`.
- **Fallback:** `false` se `SESSION_ID` vuoto o file non esistente.
- **Note operative:** la GUI può determinare lo stato leggendo il filesystem o interrogando il Session Engine se disponibile.

#### 20.2 `{{SESSION_ID}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** stringa.
- **Origine:** variabile `SESSION_ID` (CLI/ENV) impostata dal wrapper o dal core; può essere passata alla GUI tramite l’endpoint CGI.
- **Sanitizzazione / Validazione:** `session_validate_id` con regex `^[A-Za-z0-9._-]{1,128}$`.
- **Obblig./Opz.:** opzionale (presente solo se sessione attiva o fornita).
- **Funzioni coinvolte:** `session_validate_id`, `session_append`, `session_messages_tmp_path`.
- **File coinvolti:** `${GROQBASH_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson`.
- **Fallback:** vuoto se non impostato.

#### 20.3 `{{SESSION_MSG_COUNT}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** intero (numero di messaggi).
- **Origine:** conteggio degli elementi dell’array `messages` prodotto da `session_read_window` o conteggio dei record NDJSON in `${GROQBASH_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson`.
- **Sanitizzazione / Validazione:** `session_read_window` usa `jq` per validare JSON; GUI deve contare solo record validi.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `session_read_window`, `session_append`.
- **File coinvolti:** file sessione NDJSON.
- **Fallback:** `0` se file assente o vuoto.

#### 20.4 `{{SESSION_LAST_TS}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** stringa (ISO8601 UTC).
- **Origine:** campo `ts` dell’ultimo record NDJSON scritto da `session_append` (generato da `session_now_ts`).
- **Formato esatto:** `YYYY-MM-DDTHH:MM:SSZ` (prodotto da `date -u +%Y-%m-%dT%H:%M:%SZ`).
- **Sanitizzazione / Validazione:** valore safe-by-construction; GUI `html_escape` se visualizzato.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `session_append`, `session_now_ts`, `session_read_window`.
- **File coinvolti:** file sessione NDJSON.
- **Fallback:** vuoto se nessun record presente.

#### 20.5 `{{SESSION_LIST}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** testo multilinea (elenco session id).
- **Origine:** elenco dei file in `${GROQBASH_HISTORY_DIR%/}/sessions` (basenames senza `.ndjson`); GUI deve filtrare con `session_validate_id`.
- **Sanitizzazione / Validazione:** includere solo basenames che passano `session_validate_id`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** helper di listing (es. `list_files_sorted_by_mtime` se presente) o semplice `find`/`ls` nella GUI.
- **File coinvolti:** `${GROQBASH_HISTORY_DIR}/sessions/*.ndjson`.
- **Fallback:** vuoto se directory assente o vuota.

---

### 21. Placeholder CGI — Provider Capabilities

#### 21.1 `{{PROVIDER_SUPPORTS_STREAMING}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** booleano (`true` | `false`).
- **Origine:** test di esistenza della funzione provider-specifica `call_api_streaming_${PROVIDER}` (meccanismo di dispatch usato dal core).
- **Sanitizzazione / Validazione:** test di esistenza funzione (`declare -f` / `type`).
- **Obblig./Opz.:** sempre presente nella sezione CGI (GUI può mostrarlo).
- **Funzioni coinvolte:** `call_api_streaming_<provider>` (es. `call_api_streaming_groq` per provider `groq`).
- **File coinvolti:** modulo provider (embedded o in `PROVIDERS_DIR`).
- **Fallback:** `false` se funzione non definita.
- **Note:** per `groq` embedded la funzione è presente → `true`.

#### 21.2 `{{PROVIDER_SUPPORTS_REFRESH_MODELS}}`
- **Pagine:** settings, diagnostics.
- **Tipo:** booleano (`true` | `false`).
- **Origine:** test di esistenza della funzione provider-specifica `refresh_models_${PROVIDER}`.
- **Sanitizzazione / Validazione:** test di esistenza funzione.
- **Obblig./Opz.:** sempre presente nella sezione CGI.
- **Funzioni coinvolte:** `refresh_models_<provider>` (es. `refresh_models_groq`).
- **File coinvolti:** modulo provider.
- **Fallback:** `false` se funzione non definita.
- **Note:** per `groq` embedded la funzione è presente → `true`.

---

### 22. Placeholder CGI — API Metadata & Edge-case

#### 22.1 `{{LAST_HTTP_STATUS}}`
- **Pagine:** diagnostics.
- **Tipo:** stringa / intero (codice HTTP, es. `200`, `404`).
- **Origine:** `http_code` ricavato dalle chiamate HTTP del provider (es. `curl -w '%{http_code} %{time_total}'` in `call_api_groq` o analoghi).
- **Sanitizzazione / Validazione:** valore derivato dall’output di `curl` o dall’analisi del file di risposta `${RESP}`; non esposto automaticamente dal core nei file analizzati.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `call_api_groq` (o `call_api_<provider>`), parsing di `curl` output.
- **File coinvolti:** file di risposta temporaneo `${RESP}` (usato internamente).
- **Fallback:** non disponibile a meno che il core non scriva esplicitamente il codice in un file/variabile esposta.
- **Note operative:** per esporre questo placeholder la GUI/backend devono salvare `http_code` in un file o variabile accessibile.

#### 22.2 `{{LAST_FINISH_REASON}}`
- **Pagine:** diagnostics.
- **Tipo:** stringa (es. `stop`, `length`).
- **Origine:** estrazione da file di risposta `${RESP}` (campo JSON `.choices[0].finish_reason`) e memorizzazione in `GROQBASH_EDGE_FINISH_REASON` da `detect_empty_edge_case`.
- **Sanitizzazione / Validazione:** estrazione tramite `jq -r` (raw string); GUI `html_escape` se visualizzato.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `detect_empty_edge_case`, parsing JSON con `jq`.
- **File coinvolti:** `${RESP}` (file di risposta JSON).
- **Fallback:** vuoto se campo assente.

#### 22.3 `{{LAST_EDGECASE_DETECTED}}`
- **Pagine:** diagnostics.
- **Tipo:** booleano (`true` | `false`).
- **Origine:** flag interno `GROQBASH_EDGE_EMPTY` impostato da `detect_empty_edge_case` quando viene rilevata la condizione "empty completion".
- **Sanitizzazione / Validazione:** valore booleano interno; GUI `html_escape` se visualizzato.
- **Obblig./Opz.:** sempre presente nella sezione CGI (flag diagnostico).
- **Funzioni coinvolte:** `detect_empty_edge_case`.
- **File coinvolti:** `${RESP}` (analizzato).
- **Fallback:** `false` se non impostato.

---

### 23. Placeholder CGI — History

#### 23.1 `{{LAST_SAVED_TO_HISTORY}}`
- **Pagine:** diagnostics.
- **Tipo:** booleano (o stringa path, raccomandato stringa path).
- **Origine:** esito della funzione `save_to_history` (core) che crea file in `${GROQBASH_HISTORY_DIR}` con pattern `$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt`.
- **Sanitizzazione / Validazione:** `save_to_history` ritorna 0 su successo; file creato con `chmod 600`.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `save_to_history`, `rotate_history`.
- **File coinvolti:** `${GROQBASH_HISTORY_DIR}/${YYYYMMDD-HHMMSS}-groq-output-$$.txt`.
- **Fallback:** `false` o vuoto se non salvato; raccomandazione: esporre il path del file salvato per maggiore utilità.
- **Note di sicurezza:** file protetto con permessi `600`.

#### 23.2 `{{LAST_HISTORY_FILE}}`
- **Pagine:** diagnostics.
- **Tipo:** stringa (basename o percorso).
- **Origine:** nome del file creato da `save_to_history`.
- **Sanitizzazione / Validazione:** nome generato dal core (timestamp + pid) — safe-by-construction; GUI `html_escape` se visualizzato.
- **Obblig./Opz.:** opzionale.
- **Funzioni coinvolte:** `save_to_history`, `rotate_history`.
- **File coinvolti:** file creato in `${GROQBASH_HISTORY_DIR}`.
- **Fallback:** vuoto se nessun file creato.

---

## Conclusione e note operative finali
- **Separazione netta:** il documento mantiene la distinzione tra placeholder GUI (template) e placeholder CGI (contratto runtime). Questa separazione è fondamentale per la stabilità del contratto tra backend e GUI.
- **Implementazione richiesta (pratica):**
  - Per i **placeholder CGI (20–23)** il backend deve **esporre** i valori in modo deterministico (file sotto `CFG_DIR`/`UI_ROOT/config` o endpoint CGI) affinché la GUI li possa leggere e `render_template()` li possa sostituire. Alcuni valori (es. `LAST_HTTP_STATUS`) **non** sono attualmente scritti in file accessibili: per esporli è necessario aggiungere una scrittura atomica nel core/wrapper.
  - Per i **placeholder GUI (1–19)** non è richiesta alcuna modifica al core; sono già prodotti da `gui-server.sh` / `gui-bootstrap.sh`.
- **Sicurezza:** tutte le stringhe visualizzate nei template devono essere `html_escape`-ate; i file sensibili (API key, history) sono scritti con permessi restrittivi (`chmod 600`) dove previsto.
- **Verifiche consigliate:** generare test shell che:
  - verifichino la presenza e il formato dei file di configurazione (`LANG_CURRENT_FILE`, `THEME_CURRENT_FILE`, `DEFAULT_MODEL_FILE`, `DEFAULT_PROVIDER_FILE`, `API_KEY_FILE`),
  - verifichino che `render_template()` sostituisca correttamente i token,
  - verifichino che i nuovi placeholder CGI siano esposti (file/variabili) dopo l’implementazione backend.

---

### Informazioni su `gui-lang.conf`

<mark> **gui-lang.conf** è un dizionario di traduzioni multilingue </mark> che fornisce i TXT_... disponibili per i template; non definisce nuovi placeholder di propria iniziativa, tutto è <mark> basato sulla Fonte di Verità unificata dei placeholder CGI </mark>.
Contiene un set completo di `TXT_...` e `LANG_NAME.*` (elencati sotto).
- Pattern `TXT_<KEY>.<lang>`: il file definisce chiavi TXT_... per le lingue supportate (**en, it, es, fr, de**). Queste chiavi sono la fonte primaria per i placeholder dinamici `{{TXT_<KEY>}}` quando non esiste una variabile d’ambiente corrispondente.

- Pattern `LANG_NAME.<code>`: definisce le etichette leggibili per i codici lingua (es. `LANG_NAME.it=Italiano`) usate da `build_lang_options()` per generare `<option>` nella `select` lingua. Lingue presenti nel file: **en, it, es, fr, de**.

#### Elenco delle chiavi presenti in gui-lang.conf:

```text
LANG_NAME

TXT_HOME
TXT_SETTINGS
TXT_NEW_CONVERSATION
TXT_APPLY
TXT_THEME_LIGHT
TXT_THEME_DARK
TXT_LANGUAGE
TXT_THEME
TXT_CONVERSATIONS
TXT_CURRENT_CONVERSATION
TXT_SEND_PROMPT
TXT_PROMPT
TXT_SEND
TXT_PROVIDER
TXT_MODEL
TXT_SET_MODEL
TXT_API_KEY
TXT_REFRESH_MODELS
TXT_REFRESH
TXT_SAVE
TXT_FOOTER_COPYRIGHT
TXT_FILES_INPUT
TXT_REPO_URL
TXT_REPO_LINK
TXT_ABOUT
TXT_HELP
TXT_WARNING
TXT_ERROR
```
