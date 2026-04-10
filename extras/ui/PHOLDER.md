[![GroqBash⁺ GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 

### Placeholder CGI: elenco completo e specifiche

| **Placeholder** | **Origine** | **Tipo** | **Esempio** | **Sanitizzazione / Note** |
|:---|:---|---|:---|:---|
| **`{{MODEL_OPTIONS}}`** | `build_model_options()` (gui-server) | HTML `<option>` | `<option value="gpt-4">gpt-4</option>` | Generato internamente; ogni valore `html_escape`; **inserire come HTML pre-sanitizzato** (no double-escape). Usato in template che richiedono un semplice select di modelli globale. |
| **`{{PROVIDER_OPTIONS}}`** | `build_provider_options()` (gui-server) | HTML `<option>` | `<option value="groq" selected>groq</option>` | Generato internamente; `html_escape` su value/label; **inserire come HTML pre-sanitizzato**. |
| **`{{CONV_LIST}}`** | `build_conv_list()` (gui-server) | HTML/text list | `conv-001.txt — Titolo` | Generato internamente con `html_escape` su nomi e titoli; trattarlo come HTML sicuro (non double-escape). |
| **`{{CURRENT_CONV}}`** | `build_current_conv_block()` (gui-server) | HTML (title + `<pre>`) | `<h2>Title</h2><pre>USER: ...</pre>` | Contenuto conversazione escapato con `html_escape_stream`; **inserire come HTML pre-sanitizzato**. Nota: funzione corretta è `build_current_conv_block`. |
| **`{{MODEL_LIST_SCROLL}}`** | `build_model_list_and_select()` (gui-server) | testo/HTML per textarea | `gpt-4\ngpt-4o\n...` | Generato internamente; contenuto escapato; **inserire come HTML pre-sanitizzato** nella textarea che mostra l’elenco modelli. |
| **`{{MODEL_SELECT_OPTIONS}}`** | `build_model_list_and_select()` (gui-server) | HTML `<option>` | `<option value="gpt-4" selected>gpt-4</option>` | Generato internamente; `html_escape` su value/label; **inserire come HTML pre-sanitizzato**. |
| **`{{CONFIGURED}}`** | env `CONFIGURED` (export) | flag stringa | `true` / `false` | Esportata dal server; usare come stringa; `html_escape` se inserita in testo HTML. |
| **`{{1}}..{{N}}`** | argomenti posizionali passati a `render_template` | posizionali | `en`, `light`, `gpt-4` | Vengono escapati da `render_template` prima della sostituzione; usare per valori testuali. |
| **`{{LANG_CODE}}`** | router / `lang_code` | runtime | `en` / `it` | Validare con whitelist; `sanitize_param` + `html_escape`. |
| **`{{THEME}}`** | router / `theme_code` | runtime | `light` / `dark` | Validare su `light/dark`; `sanitize_param` + `html_escape`. |
| **`{{PROVIDER_CURRENT}}`** | `get_default_provider()` | runtime (input value) | `groq` | `sanitize_param` + `html_escape`; non esporre segreti. |
| **`{{MODEL_CURRENT}}`** | `get_default_model()` | runtime (input value) | `gpt-4` | `sanitize_param` + `html_escape`. |
| **`{{LANG_OPTIONS}}`** | generato da `gui-lang.conf` | HTML `<option>` | `<option value="it" selected>Italiano</option>` | Generare internamente; `html_escape` su value/label; `selected` su `LANG_CODE`; inserire come HTML pre-sanitizzato. |
| **`{{THEME_IS_light}}`** | derived da `theme_code` | attribute marker | `selected` / `` | Restituisce `selected` o stringa vuota; calcolare internamente; non necessita escape. |
| **`{{THEME_IS_dark}}`** | derived da `theme_code` | attribute marker | `selected` / `` | Restituisce `selected` o stringa vuota; calcolare internamente; non necessita escape. |
| **`{{TXT_<KEY>}}`** (es. `{{TXT_HOME}}`) | `gui-lang.conf` via `read_txt_key` | testo UI localizzato | `Home` / `Impostazioni` | Caricare per lingua corrente; **sempre** `html_escape` prima di inserire. |
| **`{{TXT_REPO_URL}}`** | `gui-lang.conf` o costante | URL | `https://github.com/...` | Validare URL; `html_escape` in attributi. |
| **`{{TXT_REPO_LINK}}`** | `gui-lang.conf` o costante | testo link | `Repo` | `html_escape`. |
| **`{{TXT_FOOTER_COPYRIGHT}}`** | `gui-lang.conf` | testo | `GPL-3.0-or-later — Project GroqBash` | `html_escape`. |
| **`{{API_KEY_FIELD}}`** | `read_api_key_file()` (gui-server) | input value (escaped) | `xsk_xxxxxxxxx` | **Solo** valore per campo input; `html_escape` obbligatorio; **non esportare** come env ai template; server deve usare `export_api_key_for_provider` per runtime. |
| **`{{CURRENT_CONV_FILE}}`** | `get_current_conversation_file()` basename | testo | `conv-001.txt` | `html_escape`; non esporre path assoluti. |
| **`{{MODEL_WHITELIST_PRESENT}}`** | derived da `get_models_file()` | boolean string | `true` / `false` | Usato per messaggi condizionali; sostituire con `true`/`false` o HTML condizionale. |

---

### Regole operative essenziali (sintetico)
- **Escape obbligatorio**: tutti i valori testuali devono passare per `sanitize_param` e `html_escape` prima di essere inseriti nei template.  
- **HTML pre-generato**: `MODEL_OPTIONS`, `PROVIDER_OPTIONS`, `CONV_LIST`, `CURRENT_CONV`, `LANG_OPTIONS`, `MODEL_LIST_SCROLL`, `MODEL_SELECT_OPTIONS` sono generati internamente e **non** devono essere double-escaped; documentare esplicitamente “inserire come HTML pre-sanitizzato”.  
- **Differenza importante**: `MODEL_OPTIONS` è una sorgente di `<option>` usata in alcuni template; `build_model_list_and_select()` produce invece **due** output distinti: `MODEL_LIST_SCROLL` (textarea) e `MODEL_SELECT_OPTIONS` (select). Usare il campo corretto nel template appropriato.  
- **API key**: `{{API_KEY_FIELD}}` mostra la chiave nel form come valore escapato; non loggare né esportare la chiave nei template. L’uso runtime della chiave è gestito dal server.  
- **Posizionali**: `{{1}}..{{N}}` sono argomenti posizionali passati a `render_template`; `render_template` effettua `html_escape`.  
- **Localizzazione**: ogni `{{TXT_*}}` è risolto leggendo `gui-lang.conf` per la lingua corrente; fallback su `DEFAULT_LANG`.  
- **Validazione**: `LANG_CODE` e `THEME` devono essere validate prima di essere scritte su file di configurazione.  
- **Booleani stringa**: `CONFIGURED` e `MODEL_WHITELIST_PRESENT` sono stringhe `"true"`/`"false"`; i template devono testarle come stringhe.

