[![Bash4LLM⁺ GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 

### CGI Placeholders: Complete List and Specifications. 🇬🇧 [🇮🇹](PHOLDER.md)

## Unified Source of Truth for Placeholders (GUI + CGI)

---

### Architectural Introductory Note
**Summary:** Bash4LLM⁺ clearly separates two classes of placeholders:

- **GUI Placeholders (1–19)** — generated and populated **entirely by the GUI** (`gui-server.sh`, `gui-bootstrap.sh`). These are presentation values used by `render_template()` and are not part of the runtime contract between backend and frontend.
- **CGI Placeholders (20–23)** — generated **by the backend/core** (or optional engine modules). These are runtime values that the GUI **cannot calculate on its own** and constitute the **CGI contract** between backend and GUI.

This extended document describes **for each placeholder** (1–23) only **100% verified information** derived from the analyzed files (`gui-bootstrap.sh`, `gui-server.sh`, `extras/ui/static/gui-lang.conf`) and from the core and extras functions referenced by those files. For each placeholder, the following are specified: **Pages**, **Type**, **Source**, **Sanitization / Validation**, **Required/Optional**, **Involved `.sh` Functions**, **Involved Files**, **Fallback**, **Security / Operational Notes**.

---

## Data Pipeline (Summary)

- **GUI Placeholders (1–19)**  
  `GUI (gui-server.sh / gui-bootstrap.sh)` → **sanitize/validate** (`sanitize_param`, `validate_name`, `sanitize_model_output`, `html_escape`) → `render_template()` → HTML.

- **CGI Placeholders (20–23)**  
  `bash4llm` / engine → produces primitive values (NDJSON files, local variables, history files) → GUI reads/normalizes (`session_read_window`, `detect_empty_edge_case`, `save_to_history`, provider function existence checks) → **sanitize** (`html_escape`, `sanitize_param`) → `render_template()` → HTML.

---

## SECTION 1 — GUI PLACEHOLDERS (1–19)

#### 1. `{{LANG_CODE}}`

- **Pages:** header, content, footer, main, settings (all templates receiving `esc_lang`).
- **Type:** language code (string, e.g. `en`, `it`).
- **Source:** `lang` query parameter (via `get_query_param`) or `LANG_CURRENT_FILE` (read via `read_config_or_default`).
- **Sanitization / Validation:** `sanitize_param`; validation pattern used in code: `^[A-Za-z_-]+$` when required; passed to templates through `html_escape`.
- **Required/Optional:** optional (default `en`).
- **Involved Functions:** `get_query_param`, `read_config_or_default`, `sanitize_param`, `html_escape`.
- **Involved Files:** `LANG_CURRENT_FILE` (config).
- **Fallback:** `en` (via `read_config_or_default`).
- **Security Notes:** always `html_escape` before insertion into templates.

#### 2. `{{THEME}}`

- **Pages:** header, content, footer, main, settings.
- **Type:** `light` | `dark`.
- **Source:** `theme` query parameter or `THEME_CURRENT_FILE` (via `read_config_or_default`).
- **Sanitization / Validation:** `sanitize_param`; accepted values explicitly checked (`"light"` or `"dark"`).
- **Required/Optional:** optional (default `light`).
- **Involved Functions:** `get_query_param`, `read_config_or_default`, `atomic_write_safe` (for persistence), `html_escape`.
- **Involved Files:** `THEME_CURRENT_FILE`.
- **Fallback:** `light`.
- **Notes:** also generates `{{THEME_IS_light}}` / `{{THEME_IS_dark}}` (`selected`/empty values).

#### 3. `{{PROVIDER_CURRENT}}`

- **Pages:** header, content, footer, main, settings.
- **Type:** string (provider name).
- **Source:** `get_default_provider()` → `DEFAULT_PROVIDER_FILE` (read using `read_config_or_default`).
- **Sanitization / Validation:** `sanitize_param`; `validate_name` used when setting/using the provider.
- **Required/Optional:** optional.
- **Involved Functions:** `get_default_provider`, `read_config_or_default`, `sanitize_param`, `validate_name`.
- **Involved Files:** `DEFAULT_PROVIDER_FILE`, `PROVIDER_CACHE_FILE` (for options).
- **Fallback:** empty if not configured.
- **Notes:** used to generate `{{PROVIDER_OPTIONS}}`.

#### 4. `{{MODEL_CURRENT}}`

- **Pages:** header, content, footer, main, settings.
- **Type:** string (model name).
- **Source:** `get_default_model()` → `DEFAULT_MODEL_FILE`.
- **Sanitization / Validation:** `sanitize_param`; `validate_name` when set or passed to the core.
- **Required/Optional:** optional.
- **Involved Functions:** `get_default_model`, `read_config_or_default`, `sanitize_param`, `validate_name`.
- **Involved Files:** `DEFAULT_MODEL_FILE`, `models.*.txt` (cache).
- **Fallback:** empty or first model in whitelist (if available).
- **Notes:** used for `MODEL_OPTIONS`, `MODEL_SELECT_OPTIONS`, `MODEL_LIST_SCROLL`.

#### 5. `{{API_KEY_FIELD}}`

- **Pages:** header, content, footer, main, settings.
- **Type:** string (API key content), **HTML-escaped**.
- **Source:** `read_api_key_file()` → `API_KEY_FILE`.
- **Sanitization / Validation:** read using `sed -n '1p'`; passed to template via `html_escape`.
- **Required/Optional:** optional.
- **Involved Functions:** `read_api_key_file`, `save_api_key_file`, `html_escape`.
- **Involved Files:** `API_KEY_FILE`.
- **Fallback:** empty if missing.
- **Security Notes:** `API_KEY_FILE` is written with `chmod 600` by `save_api_key_file`; displayed value is HTML-escaped.

#### 6. `{{LANG_OPTIONS}}`

- **Pages:** header, content, footer, main, settings.
- **Type:** HTML `<option>` block.
- **Source:** `build_lang_options()` → reads `gui-lang.conf` (candidates found through `find_lang_conf`).
- **Sanitization / Validation:** `sanitize_param` on code/label; `html_escape` for output.
- **Required/Optional:** optional.
- **Involved Functions:** `find_lang_conf`, `build_lang_options`, `sanitize_param`, `html_escape`.
- **Involved Files:** `gui-lang.conf` (possible locations: `CFG_DIR`, `UI_ROOT/static`, `extras/ui`, etc.).
- **Fallback:** empty if file missing.
- **Notes:** labels and codes are always `html_escape`.

#### 7. `{{MODEL_OPTIONS}}`

- **Pages:** header, content, footer, main, settings.
- **Type:** HTML `<option>` block.
- **Source:** `build_model_options()` → `get_models_file()` (models file).
- **Sanitization / Validation:** `sanitize_param` for each model; `html_escape` for output.
- **Required/Optional:** optional.
- **Involved Functions:** `get_models_file`, `build_model_options`, `sanitize_param`, `html_escape`.
- **Involved Files:** `models/models.txt` or `CFG_DIR/models.<provider>.txt`.
- **Fallback:** empty if file missing.
- **Notes:** list derived from the resolved models file.

#### 8. `{{PROVIDER_OPTIONS}}`

- **Pages:** settings.
- **Type:** HTML `<option>` block.
- **Source:** `build_provider_options()` → `PROVIDER_CACHE_FILE` (`providers.txt`), with a preliminary call to `ensure_provider_cache_fresh`.
- **Sanitization / Validation:** `sanitize_param` + `html_escape`.
- **Required/Optional:** optional.
- **Involved Functions:** `build_provider_options`, `ensure_provider_cache_fresh`, `sanitize_param`, `html_escape`.
- **Involved Files:** `PROVIDER_CACHE_FILE` (`CFG_DIR/providers.txt`).
- **Fallback:** empty if cache missing.
- **Notes:** `ensure_provider_cache_fresh` may invoke `bash4llm --list-providers-raw`.

#### 9. `{{MODEL_LIST_SCROLL}}`

- **Pages:** settings.
- **Type:** multiline text (one model per line).
- **Source:** `build_model_list_and_select()` (non-HTML `<option>` output section).
- **Sanitization / Validation:** `sanitize_param` for each line; `html_escape` when inserted into template.
- **Required/Optional:** optional.
- **Involved Functions:** `build_model_list_and_select`, `sanitize_param`, `html_escape`.
- **Involved Files:** models file resolved by `get_models_file`.
- **Fallback:** empty if file missing.

#### 10. `{{MODEL_SELECT_OPTIONS}}`

- **Pages:** settings.
- **Type:** HTML `<option>` block.
- **Source:** `build_model_list_and_select()` (provider-aware).
- **Sanitization / Validation:** `sanitize_param`, `html_escape`.
- **Required/Optional:** optional.
- **Involved Functions:** `build_model_list_and_select`, `sanitize_param`, `html_escape`.
- **Involved Files:** models file.

#### 11. `{{CONV_LIST}}`

- **Pages:** main, settings.
- **Type:** text/HTML (conversation list with titles).
- **Source:** `build_conv_list()` → enumeration of `CONV_DIR` (`conv-*.txt`) + `read_conv_title()`.
- **Sanitization / Validation:** `html_escape` on basename and title.
- **Required/Optional:** optional.
- **Involved Functions:** `build_conv_list`, `read_conv_title`, `html_escape`.
- **Involved Files:** `CONV_DIR/*` (e.g. `conv-001.txt`, `*.title`).
- **Fallback:** empty if directory is empty.

#### 12. `{{CURRENT_CONV_FILE}}`

- **Pages:** main, settings.
- **Type:** string (basename).
- **Source:** `get_current_conversation_file()` → reads `CURRENT_CONV_FILE` and builds a path in `CONV_DIR`.
- **Sanitization / Validation:** `sanitize_param`, `validate_name` (fallback to `conv-001.txt` if invalid).
- **Required/Optional:** optional.
- **Involved Functions:** `get_current_conversation_file`, `read_config_or_default`, `sanitize_param`, `validate_name`, `atomic_write`.
- **Involved Files:** `CURRENT_CONV_FILE` (config), actual file in `CONV_DIR`.
- **Fallback:** `conv-001.txt`.

#### 13. `{{MODEL_WHITELIST_PRESENT}}`

- **Pages:** main, settings.
- **Type:** boolean (`true` | `false`).
- **Source:** `get_models_file()` + first non-empty record check (`awk 'NF{print; exit}'`).
- **Sanitization / Validation:** verifies the presence of at least one non-empty line in the models file.
- **Required/Optional:** always present (GUI sets `MODEL_WHITELIST_PRESENT`).
- **Involved Functions:** `get_models_file`, `awk` check.
- **Involved Files:** resolved models file.
- **Fallback:** `false` if file missing or empty.

#### 14. `{{CONFIGURED}}`

- **Pages:** main, settings.
- **Type:** boolean (`true` | `false`).
- **Source:** `is_configured()` (checks default provider, API key, and model or non-empty models file).
- **Sanitization / Validation:** deterministic logic inside `is_configured`.
- **Required/Optional:** always present (GUI exports `CONFIGURED`).
- **Involved Functions:** `is_configured`, `read_api_key_file`, `get_default_provider`, `get_default_model`, `get_models_file`.
- **Notes:** used to display configuration warnings.

#### 15. `{{GUI_CGI_BASE}}`

- **Pages:** all (used to build base URLs).
- **Type:** string (base URL).
- **Source:** environment variable `GUI_CGI_BASE` or default `"/bash4llm-gui/cgi/"` (normalized).
- **Sanitization / Validation:** `html_escape`.
- **Required/Optional:** optional.
- **Involved Functions:** direct assignment in `render_page_*`.
- **Notes:** normalized with trailing slash.

#### 16. `{{THEME_IS_light}}` / `{{THEME_IS_dark}}`

- **Pages:** header, settings.
- **Type:** string (`selected` | empty).
- **Source:** derived from `THEME` (if `light` → `THEME_IS_light="selected"`).
- **Sanitization / Validation:** `html_escape` if required.
- **Required/Optional:** optional.
- **Involved Functions:** logic in `render_page_*`.

#### 17. `{{CURRENT_CONV}}`

- **Pages:** main.
- **Type:** HTML `<pre>...</pre>` block.
- **Source:** `build_current_conv_block()` → reads current conversation file line by line, applies `sanitize_model_output` and `html_escape`.
- **Sanitization / Validation:** `sanitize_model_output` (ANSI removal, length checks, truncation) + `html_escape`.
- **Required/Optional:** optional.
- **Involved Functions:** `build_current_conv_block`, `get_current_conversation_file`, `sanitize_model_output`, `html_escape`, `html_unescape`/`html_unescape_fallback`.
- **Involved Files:** conversation file in `CONV_DIR`.
- **Security Notes:** output is HTML-escaped and enclosed in `<pre>`.

#### 18. `{{TXT_<KEY>}}`

- **Pages:** all.
- **Type:** string (HTML-escaped).
- **Source:** shell variable (if defined) or `gui-lang.conf` through `read_txt_key()`; fallback to `DEFAULT_LANG`.
- **Sanitization / Validation:** `html_escape`.
- **Required/Optional:** optional.
- **Involved Functions:** `read_txt_key`, `find_lang_conf`, `html_escape`.
- **Involved Files:** `gui-lang.conf` (possible locations).
- **Notes:** used for text localization.

#### 19. Positional `{{1}}`, `{{2}}`, …

- **Pages:** all.
- **Type:** HTML-escaped strings.
- **Source:** arguments passed to `render_template()` (positional).
- **Sanitization / Validation:** `html_escape` applied in `render_template`.
- **Required/Optional:** optional.
- **Involved Functions:** `render_template`, `html_escape`.

---

## SECTION 2 — CGI PLACEHOLDERS (20–23)

*(new backend-side functionality; the GUI must read/expose these values from the backend or from backend-generated files)*

### 20. CGI Placeholder — Session Management

#### 20.1 `{{SESSION_ACTIVE}}`

- **Pages:** settings, diagnostics.
- **Type:** boolean (`true` | `false`).
- **Source:** **presence/absence** of the session file `${BASH4LLM_HISTORY_DIR%/}/sessions/${SESSION_ID}.ndjson` or status provided by the optional Session Engine (`extras/session/session-engine.sh`) if available.
- **Sanitization / Validation:** determined through `session_validate_id` for `SESSION_ID` and file existence checks; GUI must apply `html_escape` if displayed.
- **Required/Optional:** always present in the CGI section (the GUI should display the status).
- **Involved Functions:** `session_validate_id`, `session_read_window` (to retrieve messages), optional Session Engine functions (`session_engine_enabled`).
- **Involved Files:** `${BASH4LLM_HISTORY_DIR}/sessions/*.ndjson`.
- **Fallback:** `false` if `SESSION_ID` is empty or the file does not exist.
- **Operational Notes:** the GUI can determine the status by reading the filesystem or querying the Session Engine if available.

#### 20.2 `{{SESSION_ID}}`

- **Pages:** settings, diagnostics.
- **Type:** string.
- **Source:** `SESSION_ID` variable (CLI/ENV) set by the wrapper or the core; it may be passed to the GUI through the CGI endpoint.
- **Sanitization / Validation:** `session_validate_id` with regex `^[A-Za-z0-9._-]{1,128}$`.
- **Required/Optional:** optional (present only if a session is active or explicitly provided).
- **Involved Functions:** `session_validate_id`, `session_append`, `session_messages_tmp_path`.
- **Involved Files:** `${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson`.
- **Fallback:** empty if not set.

#### 20.3 `{{SESSION_MSG_COUNT}}`

- **Pages:** settings, diagnostics.
- **Type:** integer (message count).
- **Source:** count of elements in the `messages` array produced by `session_read_window` or count of NDJSON records in `${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson`.
- **Sanitization / Validation:** `session_read_window` uses `jq` to validate JSON; the GUI must count only valid records.
- **Required/Optional:** optional.
- **Involved Functions:** `session_read_window`, `session_append`.
- **Involved Files:** NDJSON session file.
- **Fallback:** `0` if the file is missing or empty.

#### 20.4 `{{SESSION_LAST_TS}}`

- **Pages:** settings, diagnostics.
- **Type:** string (ISO8601 UTC).
- **Source:** `ts` field from the last NDJSON record written by `session_append` (generated by `session_now_ts`).
- **Exact Format:** `YYYY-MM-DDTHH:MM:SSZ` (generated by `date -u +%Y-%m-%dT%H:%M:%SZ`).
- **Sanitization / Validation:** safe-by-construction value; GUI applies `html_escape` if displayed.
- **Required/Optional:** optional.
- **Involved Functions:** `session_append`, `session_now_ts`, `session_read_window`.
- **Involved Files:** NDJSON session file.
- **Fallback:** empty if no records exist.

#### 20.5 `{{SESSION_LIST}}`

- **Pages:** settings, diagnostics.
- **Type:** multiline text (list of session IDs).
- **Source:** listing of files in `${BASH4LLM_HISTORY_DIR%/}/sessions` (basenames without `.ndjson`); the GUI must filter them using `session_validate_id`.
- **Sanitization / Validation:** include only basenames that pass `session_validate_id`.
- **Required/Optional:** optional.
- **Involved Functions:** listing helper (e.g. `list_files_sorted_by_mtime` if available) or a simple `find`/`ls` implementation in the GUI.
- **Involved Files:** `${BASH4LLM_HISTORY_DIR}/sessions/*.ndjson`.
- **Fallback:** empty if the directory is missing or empty.

---

### 21. CGI Placeholder — Provider Capabilities

#### 21.1 `{{PROVIDER_SUPPORTS_STREAMING}}`

- **Pages:** settings, diagnostics.
- **Type:** boolean (`true` | `false`).
- **Source:** existence check of the provider-specific function `call_api_streaming_${PROVIDER}` (dispatch mechanism used by the core).
- **Sanitization / Validation:** function existence test (`declare -f` / `type`).
- **Required/Optional:** always present in the CGI section (GUI may display it).
- **Involved Functions:** `call_api_streaming_<provider>` (e.g. `call_api_streaming_groq` for provider `groq`).
- **Involved Files:** provider module (embedded or located in `PROVIDERS_DIR`).
- **Fallback:** `false` if the function is not defined.
- **Notes:** for embedded `groq`, the function exists → `true`.

#### 21.2 `{{PROVIDER_SUPPORTS_REFRESH_MODELS}}`

- **Pages:** settings, diagnostics.
- **Type:** boolean (`true` | `false`).
- **Source:** existence check of the provider-specific function `refresh_models_${PROVIDER}`.
- **Sanitization / Validation:** function existence test.
- **Required/Optional:** always present in the CGI section.
- **Involved Functions:** `refresh_models_<provider>` (e.g. `refresh_models_groq`).
- **Involved Files:** provider module.
- **Fallback:** `false` if the function is not defined.
- **Notes:** for embedded `groq`, the function exists → `true`.

---

### 22. CGI Placeholder — API Metadata & Edge Cases

#### 22.1 `{{LAST_HTTP_STATUS}}`

- **Pages:** diagnostics.
- **Type:** string / integer (HTTP status code, e.g. `200`, `404`).
- **Source:** `http_code` extracted from provider HTTP calls (e.g. `curl -w '%{http_code} %{time_total}'` in `call_api_groq` or equivalent implementations).
- **Sanitization / Validation:** value derived from `curl` output or from analysis of the response file `${RESP}`; it is not automatically exposed by the core in the analyzed files.
- **Required/Optional:** optional.
- **Involved Functions:** `call_api_groq` (or `call_api_<provider>`), parsing of `curl` output.
- **Involved Files:** temporary response file `${RESP}` (used internally).
- **Fallback:** unavailable unless the core explicitly writes the code into an exposed file or variable.
- **Operational Notes:** to expose this placeholder, the GUI/backend must save `http_code` into an accessible file or variable.

#### 22.2 `{{LAST_FINISH_REASON}}`

- **Pages:** diagnostics.
- **Type:** string (e.g. `stop`, `length`).
- **Source:** extracted from the response file `${RESP}` (JSON field `.choices[0].finish_reason`) and stored in `BASH4LLM_EDGE_FINISH_REASON` by `detect_empty_edge_case`.
- **Sanitization / Validation:** extracted through `jq -r` (raw string); GUI applies `html_escape` if displayed.
- **Required/Optional:** optional.
- **Involved Functions:** `detect_empty_edge_case`, JSON parsing via `jq`.
- **Involved Files:** `${RESP}` (JSON response file).
- **Fallback:** empty if the field is absent.

#### 22.3 `{{LAST_EDGECASE_DETECTED}}`

- **Pages:** diagnostics.
- **Type:** boolean (`true` | `false`).
- **Source:** internal flag `BASH4LLM_EDGE_EMPTY` set by `detect_empty_edge_case` when an "empty completion" condition is detected.
- **Sanitization / Validation:** internal boolean value; GUI applies `html_escape` if displayed.
- **Required/Optional:** always present in the CGI section (diagnostic flag).
- **Involved Functions:** `detect_empty_edge_case`.
- **Involved Files:** `${RESP}` (analyzed file).
- **Fallback:** `false` if not set.

---

### 23. CGI Placeholder — History

#### 23.1 `{{LAST_SAVED_TO_HISTORY}}`

- **Pages:** diagnostics.
- **Type:** boolean (or path string, path string recommended).
- **Source:** result of the core function `save_to_history`, which creates files in `${BASH4LLM_HISTORY_DIR}` using the pattern `$(date +%Y%m%d-%H%M%S)-groq-output-$$.txt`.
- **Sanitization / Validation:** `save_to_history` returns `0` on success; file created with `chmod 600`.
- **Required/Optional:** optional.
- **Involved Functions:** `save_to_history`, `rotate_history`.
- **Involved Files:** `${BASH4LLM_HISTORY_DIR}/${YYYYMMDD-HHMMSS}-groq-output-$$.txt`.
- **Fallback:** `false` or empty if not saved; recommendation: expose the saved file path for greater usefulness.
- **Security Notes:** file protected with `600` permissions.

#### 23.2 `{{LAST_HISTORY_FILE}}`

- **Pages:** diagnostics.
- **Type:** string (basename or path).
- **Source:** name of the file created by `save_to_history`.
- **Sanitization / Validation:** name generated by the core (timestamp + PID) — safe-by-construction; GUI applies `html_escape` if displayed.
- **Required/Optional:** optional.
- **Involved Functions:** `save_to_history`, `rotate_history`.
- **Involved Files:** file created in `${BASH4LLM_HISTORY_DIR}`.
- **Fallback:** empty if no file has been created.

---

## Conclusion and Final Operational Notes

- **Clear Separation:** this document maintains the distinction between GUI placeholders (template layer) and CGI placeholders (runtime contract). This separation is fundamental for the stability of the backend-GUI contract.
- **Required Implementation (Practical):**
  - For **CGI placeholders (20–23)**, the backend must **expose** the values deterministically (files under `CFG_DIR`/`UI_ROOT/config` or a CGI endpoint) so that the GUI can read them and `render_template()` can substitute them. Some values (e.g. `LAST_HTTP_STATUS`) are **not** currently written to accessible files: exposing them requires adding an atomic write operation in the core/wrapper.
  - For **GUI placeholders (1–19)**, no core modifications are required; they are already produced by `gui-server.sh` / `gui-bootstrap.sh`.
- **Security:** all strings displayed in templates must be `html_escape`'d; sensitive files (API keys, history files) are written with restrictive permissions (`chmod 600`) where applicable.
- **Recommended Verification:**
  - Generate shell tests that:
    - verify the presence and format of configuration files (`LANG_CURRENT_FILE`, `THEME_CURRENT_FILE`, `DEFAULT_MODEL_FILE`, `DEFAULT_PROVIDER_FILE`, `API_KEY_FILE`);
    - verify that `render_template()` correctly replaces tokens;
    - verify that the new CGI placeholders are exposed (files/variables) after backend implementation.

---

### Information About `gui-lang.conf`

<mark> **gui-lang.conf** is a multilingual translation dictionary </mark> that provides the `TXT_...` entries available to templates; it does not define new placeholders on its own. Everything is <mark> based on the unified CGI placeholder Source of Truth </mark>.

It contains a complete set of `TXT_...` and `LANG_NAME.*` entries (listed below).

- Pattern `TXT_<KEY>.<lang>`: the file defines `TXT_...` keys for supported languages (**en, it, es, fr, de**). These keys are the primary source for dynamic `{{TXT_<KEY>}}` placeholders when no corresponding environment variable exists.

- Pattern `LANG_NAME.<code>`: defines human-readable labels for language codes (e.g. `LANG_NAME.it=Italiano`) used by `build_lang_options()` to generate language `<option>` elements in the language selector. Languages present in the file: **en, it, es, fr, de**.

#### List of Keys Present in gui-lang.conf:

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
