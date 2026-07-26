[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

# Providers  
**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**

Bash4LLM 2.x

---

## 🇮🇹 Sezione Italiana

# Contratto Provider per Bash4LLM⁺

Questo documento definisce il **contratto ufficiale** per la creazione o l'integrazione di provider esterni compatibili con Bash4LLM⁺.  
Un *provider* è un modulo Bash che implementa un adattatore per un'API LLM specifica (es. Gemini, HuggingFace, Mistral, ecc.).

I provider vengono caricati in modalità isolata dal percorso degli extras:

`bash4llm.d/extras/providers/nome.sh`

---

## 1. Caricamento e Isolamento (Sandbox)

Per garantire l'isolamento dell'ambiente di esecuzione:

1. Il file del provider viene analizzato in una sotto-shell isolata tramite `load_provider_module`.
2. Vengono estratte ed esportate nel runtime principale **esclusivamente le definizioni delle funzioni** (tramite `declare -f`).
3. **Variabili globali o codice di inizializzazione posizionati al di fuori delle funzioni non persistono nel runtime principale.** Ogni parametro, URL o costante deve essere definito internamente alle funzioni o gestito tramite i meccanismi di risoluzione del CORE.

---

## 2. Requisiti di Sicurezza del File

Ogni modulo provider deve superare la verifica di integrità del percorso e dell'hash SHA-256 rispetto al file `extras/manifest.sha256` e soddisfare i seguenti requisiti:

- Essere un file regolare (`-f`).
- Non essere un collegamento simbolico (symlink).
- Essere di proprietà dell'utente che esegue lo script.
- Non avere permessi di scrittura per il gruppo o per altri utenti (non world/group-writable).
- Risiedere in una directory non world-writable con permessi `0700`.

Il nome del provider è derivato dal nome del file senza estensione (es. `gemini.sh` identifica il provider `"gemini"`).

---

## 3. Interfaccia del Provider

Il CORE di Bash4LLM⁺ interagisce con i provider tramite funzioni dedicate. Per essere valido, un provider **deve implementare le due funzioni principali obbligatorie** (non-streaming), mentre le funzioni di streaming, refresh dei modelli e validazione chiavi sono opzionali.

---

### 3.1. Funzioni Obbligatorie (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsabilità:**
- Costruire un payload JSON in formato compatibile con lo schema dell'API di destinazione.
- Leggere le variabili globali fornite dal CORE:
  - `MODEL` (modello attivo)
  - `CONTENT` (prompt dell'utente)
  - `TURE` (temperatura validata dal CORE)
  - `MAX_TOKENS`
  - `STREAM_MODE` (1 per streaming, 0 per sincrono)
  - `SYSTEM_PROMPT` (prompt di sistema)
  - `BUILD_MESSAGES_FILE` (file temporaneo contenente la cronologia dei messaggi)
- Se `BUILD_MESSAGES_FILE` è definito e valido, il provider deve dare priorità alla lettura dell'array dei messaggi storici per garantire la continuità della sessione multi-turno.
- Scrivere il payload finale **nel file `$PAYLOAD`** (in formato JSON semplice o Base64 via `stage_b64`).
- Non produrre output su stdout.
- In caso di errore di compilazione, restituire il codice di stato `"${BASH4LLM_ERR_TMP:-15}"`.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsabilità:**
- Leggere il payload dal percorso `$PAYLOAD`. Se il file termina con estensione `.b64`, decodificarlo in chiaro in un file temporaneo locale in `$RUN_TMPDIR`.
- **Mediazione di rete sicura:** Eseguire la chiamata HTTP instradando la richiesta tramite la funzione centrale del Core `_exec_curl_secure()`. **È vietato passare i token di autenticazione come argomenti di riga di comando (`-H "Authorization: Bearer ..."` o `?key=...`)**, poiché risulterebbero visibili nella tabella dei processi (`ps aux`).
- Salvare la risposta JSON in `$RESP`.
- Restituire `0` in caso di successo, non-zero (es. `"${BASH4LLM_ERR_API:-16}"` o `"${BASH4LLM_ERR_CURL_FAILED:-12}"`) in caso di errore.
- Assicurarsi che la risposta JSON in `$RESP` sia formattata secondo lo schema compatibile con la routine di estrazione del Core (`choices[].message.content`).

---

### 3.2. Funzioni Opzionali (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsabilità:**
- Eseguire la richiesta HTTP in streaming (Server-Sent Events) indirizzando `_exec_curl_secure()` in modalità streaming (`is_streaming=1`).
- Canalizzare lo stream continuo verso un'unica istanza di `jq --unbuffered` tramite `tee`:
  ```bash
  _exec_curl_secure "POST" "$api_url" "$key" "$PAYLOAD" "" "$errf" 1 | \
  tee -a "$RESP_RAW" | \
  jq --unbuffered -R -r '...'
  ```
- Rilevare eventuali risposte di errore non-SSE (es. HTTP 429) e formattarle su terminale.
- Accumulare i frammenti ricevuti e scrivere la risposta JSON aggregata finale in `$RESP`.
- Restituire `0` in caso di successo, non-zero in caso di errore.

---

#### ➕ `refresh_models_<provider>()`

**Responsabilità:**
- Interrogare l'endpoint di catalogo dei modelli del provider tramite `_exec_curl_secure()`.
- Generare e salvare l'elenco dei modelli isolando la variabile `MODELS_FILE` sul file specifico del provider (es. `gemini.txt`).
- Salvare l'URL base del provider tramite scrittura atomica nel file restituito da `canonical_provider_url_file`.
- Restituire `0` in caso di successo.

---

#### ➕ `validate_key_<provider>()`

**Responsabilità:**
- Verificare la validità della chiave API tramite una richiesta di diagnostica GET leggera usando `_exec_curl_secure()` con timeout di 10 secondi.
- Restituire `0` se valida (HTTP 200), `1` se non valida (HTTP 401/403/400), `28` in caso di timeout di rete.

---

### 3.3. `normalize_model_<provider>()` (Opzionale)
* **Responsabilità:** Riceve in `$1` il nome grezzo del modello e restituisce su `stdout` il nome normalizzato.
* **Isolamento:** Eseguita in sotto-shell isolata dal CORE.

---

## 4. Variabili garantite dal CORE

Il CORE rende disponibili per il provider le seguenti variabili:

- `MODEL`, `CONTENT`, `TURE`, `MAX_TOKENS`, `STREAM_MODE`
- `PAYLOAD`, `RESP`, `RUN_TMPDIR`, `CURL_BASE_OPTS`
- `BUILD_MESSAGES_FILE`, `SYSTEM_PROMPT`
- `BASH4LLM_PROVIDER_URL`, `BASH4LLM_API_KEY`

Il provider non deve sovrascrivere queste variabili nello scope globale del Core.

---

### 4.1. Risoluzione dell'API Key

La chiave di autenticazione viene determinata seguendo questo ordine di priorità:

1. `PROVIDER_API_ENV_<provider>` (variabile personalizzata)
2. Variabile specifica del provider (es. `GEMINI_API_KEY`, `MISTRAL_API_KEY`, `HUGGINGFACE_API_KEY`)
3. `BASH4LLM_API_KEY` (fallback globale)

L'ispezione della variabile deve avvenire in modo sicuro tramite `declare -p` per garantire compatibilità con `set -u`. In assenza di chiave, restituire `"${BASH4LLM_ERR_NO_API_KEY:-10}"`.

---

## 5. Invarianti e Regole di Sicurezza

🚫 **Il provider NON deve:**
- Modificare la directory di lavoro (`cd`).
- Inquinare il namespace globale della shell principale.
- Scrivere file temporanei in `/tmp` o percorsi condivisi (utilizzare esclusivamente `RUN_TMPDIR` con permessi `0600`/`0700`).
- Passare chiavi API o token in chiaro negli argomenti del comando `curl` (`argv`).
- Utilizzare il comando `eval`.
- Eseguire chiamate dirette a `flock` (utilizzare sempre le astrazioni `atomic_write` o `lock_exec`).

⚠️ **Il provider DEVE:**
- Generare file JSON sintatticamente validi.
- Rispettare i permessi restrittivi sui file creati (`umask 077` e `chmod 600`).
- Rispettare `DRY_RUN`: se attivo, simulare l'operazione scrivendo file `$RESP` o `$PAYLOAD` validi senza effettuare connessioni.

---

## 6. Esempio Minimo di Struttura Compatibile

```sh
# -------------------------
# buildpayload_example
# -------------------------
buildpayload_example() {
  local workdir tmpf
  workdir="$(_get_work_tmpdir_example)"
  tmpf="$(_mktemp_in_dir_example "$workdir")"

  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    --arg temp "${TURE:-1.0}" \
    '{model: $model, temperature: ($temp|tonumber), messages: [{role: "user", content: $content}]}' > "$tmpf"

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmpf" | atomic_write "$PAYLOAD"
  else
    mv -f "$tmpf" "$PAYLOAD" 2>/dev/null || cp -f "$tmpf" "$PAYLOAD" 2>/dev/null || true
  fi
  rm -f "$tmpf" 2>/dev/null || true
}

# -------------------------
# call_api_example
# -------------------------
call_api_example() {
  local key_trim prov_env key="" errf

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "example")"
    if [ -n "$prov_env" ] && declare -p "$prov_env" >/dev/null 2>&1; then
      key="${!prov_env}"
    fi
  fi
  [ -z "$key" ] && key="${EXAMPLE_API_KEY:-${BASH4LLM_API_KEY:-}}"

  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}')"

  if [ -z "$key_trim" ]; then
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  errf="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}/curl.err"

  # Route network call via Core Authoritative Engine (Redacts secrets from argv)
  _exec_curl_secure "POST" "$BASH4LLM_PROVIDER_URL" "$key_trim" "$PAYLOAD" "$RESP" "$errf" 0
  return $?
}
```

---

## 🇬🇧 English Section

# Provider Contract for Bash4LLM⁺

This document defines the **official contract** for creating or integrating external providers compatible with Bash4LLM⁺.  
A *provider* is a Bash module implementing an adapter for a specific LLM API (e.g., Gemini, HuggingFace, Mistral, etc.).

Providers are loaded in an isolated sandbox from the extras installation path:

`bash4llm.d/extras/providers/name.sh`

---

## 1. Loading and Isolation (Sandbox)

To ensure runtime environment isolation:

1. The provider file is parsed in an **isolated subshell sandbox** via `load_provider_module`.
2. Only **function definitions** are captured and exported into the main shell environment (via `declare -f`).
3. **Global variables or initialization code outside functions will not persist in the main runtime.** All configuration parameters, URLs, or constants must be defined inside functions or resolved via CORE helpers.

---

## 2. File Security Requirements

Each provider module must pass path validation and SHA-256 integrity checks against `extras/manifest.sha256`, satisfying the following constraints:

- Be a regular file (`-f`).
- Not be a symbolic link (symlink).
- Be owned by the current user executing the script.
- Not have group or world write permissions (non group/world-writable).
- Reside inside a non world-writable directory with `0700` permissions.

The provider name is derived from the filename without extension (e.g., `gemini.sh` identifies `"gemini"`).

---

## 3. Provider Interface

The CORE interacts with providers via dedicated functions. To be valid, a provider **must implement the two mandatory functions** (non-streaming). Streaming, model refresh, and key validation functions are optional.

---

### 3.1. Mandatory Functions (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsibilities:**
- Construct a JSON request payload matching the target API schema.
- Read global variables provided by CORE: `MODEL`, `CONTENT`, `TURE`, `MAX_TOKENS`, `STREAM_MODE`, `SYSTEM_PROMPT`, `BUILD_MESSAGES_FILE`.
- If `BUILD_MESSAGES_FILE` is valid, prioritize reading historic messages to preserve multi-turn context.
- Write final payload to `$PAYLOAD` (plain JSON or base64-staged via `stage_b64`).
- Produce no stdout output.
- On error, return status code `"${BASH4LLM_ERR_TMP:-15}"`.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsibilities:**
- Read payload from `$PAYLOAD` (handling Base64 decoding if filename ends with `.b64`).
- **Secure Network Mediation:** Execute HTTP request by routing through Core function `_exec_curl_secure()`. **Do NOT pass bearer tokens or keys as command-line arguments (`-H "Authorization: Bearer ..."` or `?key=...")**, as they would be visible in process inspection (`ps aux`).
- Save JSON response to `$RESP`.
- Return `0` on success, non-zero (`"${BASH4LLM_ERR_API:-16}"` or `"${BASH4LLM_ERR_CURL_FAILED:-12}"`) on failure.
- Ensure `$RESP` contains an OpenAI-compliant response schema (`choices[].message.content`).

---

### 3.2. Optional Functions (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsibilities:**
- Execute HTTP SSE request routing through `_exec_curl_secure()` with streaming enabled (`is_streaming=1`).
- Pipe unbuffered output through `tee` to `jq --unbuffered`:
  ```bash
  _exec_curl_secure "POST" "$api_url" "$key" "$PAYLOAD" "" "$errf" 1 | \
  tee -a "$RESP_RAW" | \
  jq --unbuffered -R -r '...'
  ```
- Catch immediate non-SSE HTTP errors (e.g., HTTP 429) and format error output to terminal stderr.
- Accumulate received chunks and write complete aggregated JSON response to `$RESP`.
- Return `0` on success, non-zero on error.

---

#### ➕ `refresh_models_<provider>()`

**Responsibilities:**
- Query provider model catalog endpoint via `_exec_curl_secure()`.
- Save model list to provider-specific `MODELS_FILE` (e.g., `gemini.txt`).
- Atomically write base provider URL to `canonical_provider_url_file`.
- Return `0` on success.

---

#### ➕ `validate_key_<provider>()`

**Responsibilities:**
- Verify API key validity via lightweight GET request using `_exec_curl_secure()` with 10-second timeout.
- Return `0` if valid (HTTP 200), `1` if invalid (HTTP 401/403/400), `28` on network timeout.

---

### 3.3. `normalize_model_<provider>()` (Optional)
* **Responsibilities:** Receives raw model string in `$1` and prints normalized model name to `stdout`.
* **Isolation:** Executed inside an isolated subshell by CORE.

---

## 4. Variables Guaranteed by CORE

CORE supplies the following variables prior to function invocation:

- `MODEL`, `CONTENT`, `TURE`, `MAX_TOKENS`, `STREAM_MODE`
- `PAYLOAD`, `RESP`, `RUN_TMPDIR`, `CURL_BASE_OPTS`
- `BUILD_MESSAGES_FILE`, `SYSTEM_PROMPT`
- `BASH4LLM_PROVIDER_URL`, `BASH4LLM_API_KEY`

Providers must not overwrite these global variables.

---

### 4.1. API Key Resolution

Authentication keys must be resolved in decreasing priority order:

1. `PROVIDER_API_ENV_<provider>` (custom env var)
2. Provider-specific key (e.g., `GEMINI_API_KEY`, `MISTRAL_API_KEY`, `HUGGINGFACE_API_KEY`)
3. `BASH4LLM_API_KEY` (global fallback)

Variable existence must be verified via `declare -p` for `set -u` compatibility. If no key is found, return `"${BASH4LLM_ERR_NO_API_KEY:-10}"`.

---

## 5. Security Rules and Invariants

🚫 **The provider MUST NOT:**
- Change working directory (`cd`).
- Pollute global shell namespace.
- Write temporary files to `/tmp` (use `$RUN_TMPDIR` exclusively with `0600`/`0700` permissions).
- Pass API keys or Bearer tokens in command-line argument vectors (`argv`).
- Use `eval`.
- Invoke system `flock` directly (use `atomic_write` or `lock_exec`).

⚠️ **The provider MUST:**
- Generate valid JSON files.
- Enforce strict file permissions (`umask 077` and `chmod 600`).
- Respect `DRY_RUN`: when `DRY_RUN=1`, mock `$RESP` or `$PAYLOAD` files without executing network calls.

---

## 6. Minimal Compatible Template

```sh
# -------------------------
# buildpayload_example
# -------------------------
buildpayload_example() {
  local workdir tmpf
  workdir="$(_get_work_tmpdir_example)"
  tmpf="$(_mktemp_in_dir_example "$workdir")"

  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    --arg temp "${TURE:-1.0}" \
    '{model: $model, temperature: ($temp|tonumber), messages: [{role: "user", content: $content}]}' > "$tmpf"

  if type atomic_write >/dev/null 2>&1; then
    cat "$tmpf" | atomic_write "$PAYLOAD"
  else
    mv -f "$tmpf" "$PAYLOAD" 2>/dev/null || cp -f "$tmpf" "$PAYLOAD" 2>/dev/null || true
  fi
  rm -f "$tmpf" 2>/dev/null || true
}

# -------------------------
# call_api_example
# -------------------------
call_api_example() {
  local key_trim prov_env key="" errf

  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "example")"
    if [ -n "$prov_env" ] && declare -p "$prov_env" >/dev/null 2>&1; then
      key="${!prov_env}"
    fi
  fi
  [ -z "$key" ] && key="${EXAMPLE_API_KEY:-${BASH4LLM_API_KEY:-}}"

  key_trim="$(printf '%s' "$key" | awk '{$1=$1; print}')"

  if [ -z "$key_trim" ]; then
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  errf="${RUN_TMPDIR:-$BASH4LLM_TMPDIR}/curl.err"

  # Route network call via Core Authoritative Engine (Redacts secrets from argv)
  _exec_curl_secure "POST" "$BASH4LLM_PROVIDER_URL" "$key_trim" "$PAYLOAD" "$RESP" "$errf" 0
  return $?
}
```
