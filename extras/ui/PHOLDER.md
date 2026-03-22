### Tabella estesa dei placeholder (completa)
| **Placeholder** | **Origine** | **Tipo** | **Esempio valore** | **Sanitizzazione / Note** |
|---|---:|---|---:|---|
| **`{{MODEL_OPTIONS}}`** | `build_model_options()` (gui-server) | HTML `<option>` | `<option value="gpt-4">gpt-4</option>` | Già generato con `html_escape`; **inserire come HTML sicuro** (no double-escape). |
| **`{{CONV_LIST}}`** | `build_conv_list()` (gui-server) | HTML/text list | `conv-001.txt — Titolo` | Generato internamente con `html_escape` per nomi/titoli. |
| **`{{CURRENT_CONV}}`** | `build_current_conv_html()` (gui-server) | HTML (title + `<pre>`) | `<h2>Title</h2><pre>USER: ...</pre>` | Contenuto conversazione escapato con `html_escape_stream`. |
| **`{{CONFIGURED}}`** | env var `CONFIGURED` | stringa/flag | `true` / `false` | Sostituire solo se esportata; escape se inserita in HTML. |
| **`{{1}}..{{N}}`** | argomenti posizionali passati a `render_template` | posizionali | `en`, `light`, `gpt-4` | **DEVE** essere `html_escape` prima della sostituzione quando usato in HTML. |
| **`{{LANG_CODE}}`** | router (`lang_code`) | runtime | `en` / `it` | Validare con regex whitelist; `sanitize_param` + `html_escape`. |
| **`{{THEME}}`** | router (`theme_code`) | runtime | `light` / `dark` | Validare su `light|dark`; `html_escape`. |
| **`{{PROVIDER_CURRENT}}`** | `get_default_provider()` | runtime (input value) | `groq` | `sanitize_param` + `html_escape`. **Non** esporre API key. |
| **`{{MODEL_CURRENT}}`** | `get_default_model()` | runtime (input value) | `gpt-4` | `sanitize_param` + `html_escape`. |
| **`{{LANG_OPTIONS}}`** | generare da `gui-lang.conf` | HTML `<option>` | `<option value="it">Italiano</option>` | Generare internamente; `html_escape` su value/label; `selected` su `LANG_CODE`. |
| **`{{THEME_IS_light}}` / `{{THEME_IS_dark}}`** | derived da `theme_code` | attribute marker | `selected` o `` | Restituiscono `selected`/`checked` o stringa vuota; non escape necessario ma calcolare internamente. |
| **`{{TXT_<KEY>}}`** (es. `{{TXT_HOME}}`) | `gui-lang.conf` (localizzazione) | testo UI | `Home` / `Impostazioni` | Caricare lingua corrente; `html_escape` sempre; non esporre valori non presenti. |
| **`{{TXT_REPO_URL}}`** | costante o `gui-lang.conf` | URL | `https://github.com/...` | Validare come URL sicuro; `html_escape` in attributi. |
| **`{{TXT_REPO_LINK}}`** | costante o `gui-lang.conf` | testo link | `Repo` | `html_escape`. |
| **`{{TXT_FOOTER_COPYRIGHT}}`** | `gui-lang.conf` | testo | `GPL-3.0-or-later — Project GroqBash` | `html_escape`. |
| **`{{CURRENT_CONV_FILE}}`** | `get_current_conversation_file()` basename | testo | `conv-001.txt` | `html_escape`; non esporre path assoluti. |
| **`{{MODEL_WHITELIST_PRESENT}}`** | derived (esistenza/modelli file) | boolean | `true` / `false` | Utile per mostrare messaggi condizionali; sostituire con `true`/`false` o HTML condizionale. |

---

### Regole generali di sicurezza e comportamento
- **Sempre** usare `html_escape` per valori testuali inseriti in HTML (attributi o testo).  
- **Non** inserire mai l’`API_KEY` o altri segreti nei placeholder o nelle variabili esportate.  
- I placeholder che contengono HTML (MODEL_OPTIONS, CONV_LIST, CURRENT_CONV) devono essere **generati internamente** e i loro componenti escapati singolarmente; trattarli come “trusted HTML” solo se generati correttamente.  
- `LANG_CODE` e `THEME` devono essere **validate/whitelist** prima di essere scritti o mostrati.  
- I posizionali `{{1}}..{{N}}` attualmente vengono inseriti raw: **modificare** `render_template` per eseguire escape automatico o fornire modalità raw vs escaped.
