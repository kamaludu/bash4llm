[![GroqBash⁺ GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 

### Placeholder CGI: elenco completo e specifiche.  🇮🇹 [🇬🇧](PHOLDER-en.md)

## Fonte di Verità unificata dei placeholder CGI

> **Nota**: i nomi dei placeholder corrispondono ai token che `render_template` sostituisce (es. `{{LANG_CODE}}`, `{{MODEL_OPTIONS}}`, `{{TXT_HOME}}`, `{{CURRENT_CONV}}`, `{{1}}`, ecc.). Per ciascuno è indicata la pagina/contesto dove viene popolato, il tipo, l’origine e le note tecniche.

---

#### 1. `{{LANG_CODE}}`
- **Pagine**: header, content, footer, main, settings (tutti i template che ricevono `esc_lang`).
- **Tipo**: codice lingua (stringa, es. `en`, `it`).
- **Origine**: query `lang` o file `LANG_CURRENT_FILE` (fallback `en`); sanitizzato con `sanitize_param`.
- **Obblig./Opz.**: opzionale (default `en`).
- **Note**: validazione su pattern `^[A-Za-z_-]+$`; passato ai template come `html_escape`.

---

#### 2. `{{THEME}}`
- **Pagine**: header, content, footer, main, settings.
- **Tipo**: enumerazione (`light` | `dark`).
- **Origine**: query `theme` o file `THEME_CURRENT_FILE` (fallback `light`); sanitizzato.
- **Obblig./Opz.**: opzionale (default `light`).
- **Note**: anche esposto come `{{THEME_IS_light}}` / `{{THEME_IS_dark}}` con valore `selected` o `""`.

---

#### 3. `{{PROVIDER_CURRENT}}`
- **Pagine**: header, content, footer, main, settings.
- **Tipo**: stringa (nome provider).
- **Origine**: `get_default_provider()` → `DEFAULT_PROVIDER_FILE`; sanitizzato.
- **Obblig./Opz.**: opzionale.
- **Note**: usato anche per costruire `{{PROVIDER_OPTIONS}}`.

---

#### 4. `{{MODEL_CURRENT}}`
- **Pagine**: header, content, footer, main, settings.
- **Tipo**: stringa (nome modello).
- **Origine**: `get_default_model()` → `DEFAULT_MODEL_FILE`; sanitizzato.
- **Obblig./Opz.**: opzionale.
- **Note**: usato anche per `{{MODEL_OPTIONS}}`, `{{MODEL_SELECT_OPTIONS}}`, `{{MODEL_LIST_SCROLL}}`.

---

#### 5. `{{API_KEY_FIELD}}`
- **Pagine**: header, content, footer, main, settings.
- **Tipo**: stringa (contenuto del file API key), **HTML-escaped**.
- **Origine**: `read_api_key_file()` → `API_KEY_FILE`.
- **Obblig./Opz.**: opzionale.
- **Note**: destinato a visualizzazione testuale; già passato attraverso `html_escape`.

---

#### 6. `{{LANG_OPTIONS}}`
- **Pagine**: header, content, footer, main, settings.
- **Tipo**: blocco HTML `<option>` (stringa multilinea).
- **Origine**: `build_lang_options()` che legge `gui-lang.conf` (cerca `LANG_NAME.<code>` e genera `<option>`); i label/codici sono sanitizzati e `html_escape`-ati.
- **Obblig./Opz.**: opzionale (vuoto se `gui-lang.conf` non trovato).
- **Note**: il file `gui-lang.conf` fornisce `LANG_NAME.en=English`, `LANG_NAME.it=Italiano`, ecc.

---

#### 7. `{{MODEL_OPTIONS}}`
- **Pagine**: header, content, footer, main, settings.
- **Tipo**: blocco HTML `<option>`.
- **Origine**: `build_model_options()` → `get_models_file()` → file `models*.txt`.
- **Obblig./Opz.**: opzionale.
- **Note**: ogni `<option>` è costruita con `sanitize_param` + `html_escape`.

---

#### 8. `{{PROVIDER_OPTIONS}}`
- **Pagine**: settings (principalmente).
- **Tipo**: blocco HTML `<option>`.
- **Origine**: `build_provider_options()` → `PROVIDER_CACHE_FILE` (default `${CFG_DIR}/providers.txt`), con possibile refresh tramite `ensure_provider_cache_fresh`.
- **Obblig./Opz.**: opzionale.
- **Note**: elementi sanitizzati e `html_escape`-ati.

---

#### 9. `{{MODEL_LIST_SCROLL}}`
- **Pagine**: settings.
- **Tipo**: testo multilinea (lista di modelli, newline-separated).
- **Origine**: `build_model_list_and_select()` → file modelli.
- **Obblig./Opz.**: opzionale.
- **Note**: non è HTML `<option>` ma testo; elementi sanitizzati.

---

#### 10. `{{MODEL_SELECT_OPTIONS}}`
- **Pagine**: settings.
- **Tipo**: blocco HTML `<option>`.
- **Origine**: `build_model_list_and_select()` (considera provider corrente).
- **Obblig./Opz.**: opzionale.
- **Note**: simile a `MODEL_OPTIONS` ma con logica provider-aware.

---

#### 11. `{{CONV_LIST}}`
- **Pagine**: main, settings.
- **Tipo**: testo/HTML (stringa con linee; ogni riga `basename — title` o `basename`).
- **Origine**: `build_conv_list()` → legge `CONV_DIR/conv-*.txt` e `read_conv_title()`.
- **Obblig./Opz.**: opzionale.
- **Note**: nomi e titoli sono `html_escape`-ati; risultato pronto per inserimento in HTML.

---

#### 12. `{{CURRENT_CONV_FILE}}`
- **Pagine**: main, settings.
- **Tipo**: stringa (nome file conversazione corrente).
- **Origine**: `get_current_conversation_file()` → `CURRENT_CONV_FILE` (config).
- **Obblig./Opz.**: opzionale.
- **Note**: passato come `html_escape` prima della sostituzione.

---

#### 13. `{{MODEL_WHITELIST_PRESENT}}`
- **Pagine**: main, settings.
- **Tipo**: booleano testuale (`true` | `false`).
- **Origine**: controllo su `get_models_file()` e primo record non vuoto.
- **Obblig./Opz.**: sempre presente (valore `true`/`false`).
- **Note**: usato per abilitare/disabilitare UI relativa ai modelli.

---

#### 14. `{{CONFIGURED}}`
- **Pagine**: main, settings.
- **Tipo**: booleano testuale (`true` | `false`).
- **Origine**: `is_configured()` (verifica provider, api key, modello/whitelist).
- **Obblig./Opz.**: sempre presente.
- **Note**: se `false` il server mostra un alert di configurazione richiesta.

---

#### 15. `{{GUI_CGI_BASE}}` / posizionale `{{6}}`
- **Pagine**: header, content, footer, main, settings (passato come argomento posizionale).
- **Tipo**: URL base (stringa, es. `/groqbash-gui/cgi/`).
- **Origine**: variabile d’ambiente `GUI_CGI_BASE` o default `"/groqbash-gui/cgi/"`.
- **Obblig./Opz.**: opzionale (default presente).
- **Note**: normalizzato con trailing slash e `html_escape` prima della sostituzione; inoltre passato come argomento posizionale `{{6}}`.

---

#### 16. `{{THEME_IS_light}}` / `{{THEME_IS_dark}}`
- **Pagine**: header, settings.
- **Tipo**: stringa attributo `selected` o vuota.
- **Origine**: derivato da `THEME`.
- **Obblig./Opz.**: opzionale.
- **Note**: pensati per inserimento diretto in `<option>`.

---

#### 17. `{{CURRENT_CONV}}`
- **Pagine**: qualsiasi template che contiene il token `{{CURRENT_CONV}}`.
- **Tipo**: blocco HTML preformattato (`<pre>...</pre>`).
- **Origine**: `build_current_conv_block()` che legge il file conversazione corrente, applica `sanitize_model_output` + `html_escape` riga per riga e costruisce `CURRENT_CONV`.
- **Obblig./Opz.**: opzionale (vuoto se file mancante).
- **Note**: la sostituzione è letterale (il token viene rimpiazzato con `CURRENT_CONV` senza ulteriore escaping).

---

#### 18. `{{TXT_<KEY>}}` (es. `{{TXT_HOME}}`, `{{TXT_SETTINGS}}`, ...)
- **Pagine**: tutte le template che includono token `{{TXT_...}}`.
- **Tipo**: testo (stringa), **HTML-escaped** prima dell’inserimento.
- **Origine**: priorità
  1. variabile shell `TXT_<KEY>` se definita,
  2. altrimenti `read_txt_key("TXT_<KEY>", lang)` che legge `gui-lang.conf` (chiave `TXT_<KEY>.<lang>` o fallback su `DEFAULT_LANG`).
- **Obblig./Opz.**: opzionale (se non trovata restituisce stringa vuota).
- **Note**:
  - `gui-lang.conf` fornisce molte chiavi per `en`, `it`, `es`, `fr`, `de` (es. `TXT_HOME.en=Home`, `TXT_SETTINGS.it=Impostazioni`).
  - `render_template` individua dinamicamente tutte le occorrenze `{{TXT_...}}` nel file e le sostituisce con il valore `html_escape`-ato.

---

#### 19. Posizionali `{{1}}`, `{{2}}`, `{{3}}`, ...
- **Pagine**: tutte le template chiamate con argomenti posizionali tramite `render_template`.
- **Tipo**: stringhe **HTML-escaped**.
- **Origine**: argomenti passati a `render_template` (nell’uso corrente: `esc_lang`, `esc_theme`, `esc_model`, `esc_provider`, `esc_conv`, `esc_cgi_base`).
- **Obblig./Opz.**: opzionale (se non forniti rimangono vuoti).
- **Note**: `render_template` esegue `html_escape` su ciascun argomento prima della sostituzione.

---

## Note tecniche generali e sicurezza (riassunto)
- **Escaping**:
  - Le singole variabili passate come argomenti o sostituite direttamente (`LANG_CODE`, `THEME`, `PROVIDER_CURRENT`, `MODEL_CURRENT`, `API_KEY_FIELD`, `CURRENT_CONV_FILE`, `CONFIGURED`, ecc.) sono **HTML-escaped** in `render_template` prima della sostituzione.
  - I blocchi HTML generati (`MODEL_OPTIONS`, `PROVIDER_OPTIONS`, `LANG_OPTIONS`, `MODEL_SELECT_OPTIONS`, `CONV_LIST`) sono costruiti con escaping sui singoli elementi e poi concatenati; i template devono inserirli come HTML (non ri-escape).
  - `CURRENT_CONV` è costruito come `<pre>...</pre>` con ogni riga `sanitize_model_output` + `html_escape`.
- **Origini file/config**:
  - File rilevanti: `${CFG_DIR}/providers.txt`, `models*.txt` (più percorsi possibili), `gui-lang.conf` (più percorsi possibili), `CURRENT_CONV_FILE`, `LANG_CURRENT_FILE`, `THEME_CURRENT_FILE`, `DEFAULT_MODEL_FILE`, `DEFAULT_PROVIDER_FILE`, `API_KEY_FILE`, `CONV_DIR`.
- **Fallback e comportamento quando mancano dati**:
  - Molte variabili hanno fallback (es. lingua `en`, tema `light`, conversazione `conv-001.txt`), e il server gestisce assenza di dati con messaggi di warning o valori vuoti.

---

### Informazioni su `gui-lang.conf`

gui-lang.conf è un dizionario di traduzioni multilingue che fornisce i TXT_... utilizzabili poi nei template; non definisce nuovi placeholder di propria iniziativa.
Contiene un set completo di TXT_... e LANG_NAME.* (elencati sotto).
- Pattern `TXT_<KEY>.<lang>`: il file definisce chiavi TXT_... per le lingue supportate (**en, it, es, fr, de**). Queste chiavi sono la fonte primaria per i placeholder dinamici `{{TXT_<KEY>}}` quando non esiste una variabile d’ambiente corrispondente.

- Pattern `LANG_NAME.<code>`: definisce le etichette leggibili per i codici lingua (es. `LANG_NAME.it=Italiano`) usate da `build_lang_options()` per generare <option> nella select lingua. Lingue presenti nel file: **en, it, es, fr, de**.

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
