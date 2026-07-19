[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Providers  
**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**
 
Bash4LLM 2.x

---

## 🇮🇹 Sezione Italiana


# Contratto Provider per Bash4LLM⁺

Questo documento definisce il **contratto ufficiale** per creare o integrare provider esterni compatibili con Bash4LLM⁺.  
Un *provider* è un modulo Bash che implementa un adattatore alternativo all’API Groq (es. Gemini, HuggingFace, Mistral, ecc.).

I provider vengono caricati in modalità isolata dal percorso di installazione degli extra:

`bash4llm.d/extras/providers/nome.sh`

---

## 1. Caricamento e Isolamento (Sandbox)

A tutela della sicurezza del sistema, Bash4LLM⁺ **non** esegue il codice dei provider direttamente nel flusso principale del programma, bensì applica un meccanismo di isolamento:

1. Il file del provider viene analizzato in una **sotto-shell isolata (sandbox)** tramite `load_provider_module`.
2. Vengono catturate ed esportate nel guscio principale **esclusivamente le definizioni delle funzioni** (tramite `declare -f`).
3. **Variabili globali o codice di inizializzazione posizionati al di fuori delle funzioni nel file del provider non persistono nel runtime principale.** Ogni parametro di configurazione, URL o costante deve essere pertanto definito internamente alle funzioni o gestito tramite i meccanismi di risoluzione del CORE.

---

## 2. Requisiti di Sicurezza del File

Ogni modulo provider deve superare i controlli di integrità di `extras/security/verify.sh` e soddisfare i seguenti requisiti:

- Essere un file regolare (`-f`).
- Non essere un collegamento simbolico (symlink).
- Essere di proprietà dell'utente corrente che esegue lo script.
- Non avere permessi di scrittura per il gruppo o per altri utenti (non world/group-writable).
- Risiedere in una directory non world-writable.

Il nome del provider è determinato dal nome del file senza estensione (es. `gemini.sh` identifica il provider `"gemini"`).

---

## 3. Interfaccia del Provider

Il core di Bash4LLM⁺ interagisce con i provider tramite funzioni dedicate. Per essere considerato valido dal validatore d'interfaccia, un provider **deve implementare obbligatoriamente le due funzioni principali** (non-streaming), mentre le funzioni di streaming e di refresh dei modelli sono considerate moduli opzionali integrativi.

---

### 3.1. Funzioni Obbligatorie (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsabilità:**
- Costruire un payload JSON in formato **OpenAI-like** (compatibile con la struttura Chat Completions, es. `{"model":"...","messages":[...]}`).
- Leggere le variabili globali fornite dal CORE:
  - `MODEL` (modello attivo)
  - `CONTENT` (prompt inserito dall'utente)
  - `TURE` (variabile canonica di temperatura, precedentemente validata dal CORE)
  - `MAX_TOKENS`
  - `STREAM_MODE` (indica se la generazione richiederà uno streaming)
  - `SYSTEM_PROMPT` (prompt di sistema se impostato da CLI)
  - `BUILD_MESSAGES_FILE` (file temporaneo contenente la cronologia dei messaggi della sessione, se attiva)
- Se `BUILD_MESSAGES_FILE` è definito e valido, il provider deve dare la priorità alla lettura dell'array dei messaggi storici in esso contenuto, inserendoli nel payload per garantire il mantenimento della sessione (multi-turn).
- Se `SYSTEM_PROMPT` è impostata, il provider deve integrarla (ad esempio inserendola come messaggio con ruolo `"system"` in testa all'array dei messaggi).
- Scrivere il payload finale **nel file `$PAYLOAD`** (sia esso in formato JSON semplice o codificato base64-staged tramite l'utility `stage_b64`).
- Non produrre alcun output su stdout.
- In caso di errore durante la compilazione del payload, restituire il codice di stato canonico `"${BASH4LLM_ERR_TMP:-15}"`. **Evitare l'uso di variabili non definite** (es. `BASH4LLMERRTMP` o `BASH4LLERR_TMP` senza underscore), in quanto causano crash immediati in modalità rigorosa `set -u`.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsabilità:**
- Leggere il payload pre-compilato dal percorso `$PAYLOAD`.
- **Rilevamento e decodifica Base64:** Se il file in `$PAYLOAD` termina con estensione `.b64`, il provider ha la responsabilità di decodificarlo in chiaro in un file temporaneo locale all'interno di `$RUN_TMPDIR` prima di inoltrarlo a `curl`.
- Eseguire la chiamata di rete HTTP verso il rispettivo server API.
- Salvare la risposta JSON integra (inclusi eventuali metadati di errore nativi) in `$RESP`.
- Restituire codice di stato `0` in caso di successo, non-zero (es. `"${BASH4LLM_ERR_API:-16}"` o `"${BASH4LLM_ERR_CURL_FAILED:-12}"`) in caso di errore.
- La risposta JSON di successo deve rispettare lo schema OpenAI-like in modo da essere compatibile con la funzione di estrazione del core (`choices[].message.content`). In caso contrario, la funzione deve rimodellare la risposta prima di scriverla in `$RESP`.

---

### 3.2. Funzioni Opzionali (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsabilità:**
- Eseguire la richiesta HTTP in modalità streaming a pacchetti (Server-Sent Events).
- **Integrazione della Pipeline ad alte prestazioni:** Per evitare il degrado delle prestazioni dovuto all'avvio ripetuto di processi `jq` riga per riga, il provider **deve** convogliare l'output continuo di `curl` verso un'unica istanza di `jq --unbuffered` tramite l'uso di `tee`:
  ```bash
  curl ... | tee -a "$RESP_RAW" | jq --unbuffered -R -r '...'
  ```
- **Intercettazione e formattazione unificata degli errori:** Il filtro `jq` continuo deve essere in grado di rilevare se la risposta del server non inizia con il prefisso SSE `data: ` (caso tipico di errore HTTP JSON immediato, es. `429 Rate Limit`) ed emettere sul terminale la formattazione corretta del messaggio di errore nativo (es. `\nAPI Error: <messaggio>`).
- Accumulare i frammenti ricevuti e scrivere la risposta JSON aggregata e completa in `$RESP` prima del termine della funzione (fondamentale per consentire la persistenza della sessione e della cronologia).
- Restituire `0` in caso di successo, non-zero in caso di errore di rete.

---

#### ➕ `refresh_models_<provider>()`

**Responsabilità:**
- Interrogare l'endpoint di catalogo dei modelli del rispettivo fornitore.
- Generare la lista dei modelli e salvarla nel file dei modelli configurato per il provider.
- Per evitare collisioni di scrittura tra diversi provider, ciascun modulo deve ridefinire localmente la variabile `MODELS_FILE` puntando a un file specifico (es. `gemini.txt` anziché il file generico condiviso `models.txt`):
  `MODELS_FILE="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/gemini.txt}"`
- Scrivere l'URL base del provider all'interno del file restituito da `canonical_provider_url_file` tramite scrittura atomica, e impostare coerentemente la variabile `BASH4LLM_PROVIDER_URL`.
- Rispettare i vincoli di sicurezza (umask 077, nessun uso di cartelle condivise globali come `/tmp`, nessun uso di `eval` o `cd`).
- Restituire 0 in caso di successo.

*Nota sulle capacità: Il core di Bash4LLM⁺ rileva automaticamente se un provider supporta questa funzionalità ispezionando la presenza della funzione tramite `type "refresh_models_${provider}"`. Non è richiesto l'uso di variabili di abilitazione esterne.*

---

#### ➕ `validate_key_<provider>()`

**Responsabilità:**
- Verificare la validità della chiave API inserita dall'utente tramite una richiesta di rete leggera (GET) all'endpoint di diagnostica del rispettivo provider.
- Impostare un timeout di rete rigido a 10 secondi (passando `--max-time 10` a curl).
- Restituire i seguenti codici di stato:
  - `0` se la chiave è valida (es. risposta HTTP 200).
  - `1` se la chiave non è valida (es. risposta HTTP 401/403/400).
  - `28` (o il codice di errore restituito da curl) in caso di timeout di rete o errore di connessione.
- Rispettare la modalità rigorosa `set -u` gestendo l'esistenza delle variabili tramite introspezione sicura prima di effettuare espansioni indirette.

---

### 3.3: `normalize_model_<provider>()` (Opzionale)
* **Responsabilità:** Riceve come argomento `$1` il nome del modello grezzo. Deve restituire esclusivamente su `stdout` il nome del modello normalizzato.
* **Isolamento:** La funzione viene eseguita dal CORE in una sotto-shell. Qualsiasi modifica a variabili globali, directory corrente (`cd`) o opzioni di shell effettuata all'interno dell'hook non avrà effetto sul CORE.
* **Vincoli di Output:** L'output deve idealmente conformarsi alla whitelist dei caratteri sicuri. Qualsiasi carattere non conforme (es. spazi, simboli di controllo) verrà comunque rimosso d'ufficio dal CORE.

---

## 4. Variabili garantite dal CORE

Il CORE di Bash4LLM⁺ rende disponibili e valorizza per il provider le seguenti variabili d'ambiente e di stato prima di invocare le rispettive funzioni:

- `MODEL` (modello da utilizzare)
- `CONTENT` (prompt testuale dell'utente)
- `TURE` (parametro di temperatura numerico validato dal CORE, alias di `TEMPERATURE`)
- `MAX_TOKENS` (numero massimo di token)
- `STREAM_MODE` (1 se streaming attivo, 0 altrimenti)
- `PAYLOAD` (percorso del file del payload)
- `RESP` (percorso in cui scrivere la risposta JSON)
- `RUN_TMPDIR` (directory temporanea sicura e isolata specifica della transazione corrente)
- `CURL_BASE_OPTS` (array contenente le opzioni curl di default del programma)
- `BUILD_MESSAGES_FILE` (percorso del file contenente la cronologia dei messaggi della sessione corrente)
- `SYSTEM_PROMPT` (prompt di sistema se specificato)
- `BASH4LLM_PROVIDER_URL` (URL base del provider attualmente attivo)
- `BASH4LLM_API_KEY` (chiave di autenticazione generica o ereditata)

Il provider non deve in nessun caso modificare o sovrascrivere queste variabili nel runtime principale del core.

---

### 4.1. Risoluzione della API Key e Compatibilità `set -u`

Ciascun provider deve determinare ed estrarre la chiave di autenticazione seguendo rigorosamente questo ordine di priorità decrescente:

1. `PROVIDER_API_ENV_<provider>` (se definita nell'ambiente, indica la variabile d'ambiente personalizzata da leggere).
2. La chiave specifica del provider (es. `GEMINI_API_KEY`, `MISTRAL_API_KEY` o `HUGGINGFACE_API_KEY`).
3. La chiave globale di fallback `BASH4LLM_API_KEY`.

#### Sicurezza `set -u` (nounset) ed espansione indiretta:
Per evitare interruzioni fatali dovute all'espansione di riferimenti dinamici non dichiarati (es. `${!prov_env}`), l'esistenza e lo stato delle variabili d'ambiente devono essere ispezionati in via preventiva tramite il comando di introspezione nativo di Bash `declare -p`. Questo garantisce la massima conformità a `set -u` senza alterare lo stato dei flag globali dello script:

```bash
local key="" envvar
if type provider_api_env_var_name >/dev/null 2>&1; then
  envvar="$(provider_api_env_var_name "example")"
  # Safely check if the variable is declared before executing indirect expansion
  if [ -n "$envvar" ] && declare -p "$envvar" >/dev/null 2>&1; then
    key="${!envvar}"
  fi
fi
```

In assenza di una chiave valida per gli endpoint che richiedono autenticazione, le funzioni del provider devono interrompersi in sicurezza restituendo il codice di stato canonico `"${BASH4LLM_ERR_NO_API_KEY:-10}"`.

---

## 5. Regole di Comportamento e Invarianti

🚫 **Il provider NON deve:**
- Modificare la directory di lavoro corrente (mai usare `cd`).
- Modificare o inquinare le variabili globali dello script principale.
- Utilizzare la directory globale `/tmp` o percorsi non controllati (ogni file temporaneo deve risiedere all'interno di `RUN_TMPDIR`).
- Utilizzare il comando `eval`.
- Generare output testuale spurio su stdout (ad eccezione dello streaming testuale decodificato in tempo reale).
- Hardcodare URL fissi all'interno delle funzioni di chiamata, ma fare sempre riferimento alla risoluzione di `BASH4LLM_PROVIDER_URL`.
- **Eseguire direttamente chiamate a `flock` di sistema:** l'uso dei lock sui descrittori di file di `flock` è instabile o non supportato su ambienti mobile e sandboxed come Termux (Android 14+), dove causa blocchi indefiniti o errori irreversibili. Il provider deve affidarsi unicamente alle funzioni di astrazione fornite dal core (`atomic_write`, `lock_exec`), le quali escludono automaticamente `flock` su Termux ed eseguono la deviazione trasparente sul meccanismo atomico di directory lock (`mkdir`).

⚠️ **Il provider DEVE:**
- Generare file JSON validi ed esenti da errori di sintassi.
- Rispettare i vincoli di sicurezza dei file generati impostando permessi restrittivi (`umask 077`).
- Rispettare l'opzione `DRY_RUN`. Se `DRY_RUN=1`, il core blocca automaticamente le chiamate di rete a monte tramite la centrale `enforce_network_policy`; il provider deve comunque comportarsi in modo predittivo garantendo la scrittura di file `$RESP` o `$PAYLOAD` fittizi ma formalmente validi.
- Assicurarsi che ogni file scritto (JSON o liste testuali) si chiuda sempre con un carattere di a capo (`\n`) finale.

---

## 6. Esempio Minimo di Struttura Corretta e Compatibile

```sh
# -------------------------
# buildpayload_example
# -------------------------
buildpayload_example() {
  local workdir tmpf
  workdir="$(_get_work_tmpdir_example)"
  tmpf="$(_mktemp_in_dir_example "$workdir")"

  # Build OpenAI-compatible chat completions payload using the validated temperature variable TURE
  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    --arg temp "${TURE:-1.0}" \
    '{model: $model, temperature: ($temp|tonumber), messages: [{role: "user", content: $content}]}' > "$tmpf"

  # Atomic write payload back to core configuration
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
  local key_trim prov_env key=""

  # Retrieve API key securely avoiding unbound variable triggers
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

  # Robust array-expansion wrapper for network execution
  local -a curl_cmd=(curl -sS)
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    -H "Authorization: Bearer ${key_trim}"
    -H "Content-Type: application/json"
    --data-binary @"$PAYLOAD"
    -o "$RESP"
    "$BASH4LLM_PROVIDER_URL"
  )

  "${curl_cmd[@]}"
  return $?
}
```

---

## 🇬🇧 English Section

# Provider Contract for Bash4LLM⁺

This document defines the **official contract** for creating or integrating external providers compatible with Bash4LLM⁺.  
A *provider* is a Bash module that implements an alternative adapter to the Groq API (e.g., Gemini, HuggingFace, Mistral, etc.).

Providers are loaded in an isolated environment from the extras installation path:

`bash4llm.d/extras/providers/name.sh`

---

## 1. Loading and Isolation (Sandbox)

To protect system security, Bash4LLM⁺ **does not** execute provider code directly within the main program flow. Instead, it enforces an isolation mechanism:

1. The provider file is analyzed in an **isolated subshell (sandbox)** via `load_provider_module`.
2. Only **function definitions** are captured and exported back into the main shell environment (via `declare -f`).
3. **Global variables or initialization code located outside functions inside the provider file will not persist in the main runtime.** Therefore, any configuration parameters, URLs, or constants must be defined internally within functions or managed via the CORE's resolution mechanisms.

---

## 2. File Security Requirements

Each provider module must pass the integrity checks in `extras/security/verify.sh` and satisfy the following requirements:

- Must be a regular file (`-f`).
- Must not be a symbolic link (symlink).
- Must be owned by the current user executing the script.
- Must not have write permissions for group or others (non world/group-writable).
- Must reside in a non world-writable directory.

The provider's name is determined by the file name without its extension (e.g., `gemini.sh` identifies the `"gemini"` provider).

---

## 3. Provider Interface

The CORE of Bash4LLM⁺ interacts with providers via dedicated functions. To be considered valid by the interface validator, a provider **must obligatorily implement the two main functions** (non-streaming), while streaming and model refresh functions are treated as optional integrative modules.

---

### 3.1. Mandatory Functions (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsibilities:**
- Construct a JSON payload in **OpenAI-like** format (compatible with the Chat Completions structure, e.g., `{"model":"...","messages":[...]}`).
- Read the global variables supplied by the CORE:
  - `MODEL` (active model)
  - `CONTENT` (user prompt)
  - `TURE` (canonical temperature variable, previously validated by the CORE)
  - `MAX_TOKENS`
  - `STREAM_MODE` (indicates whether generation requires streaming)
  - `SYSTEM_PROMPT` (system prompt if set via CLI)
  - `BUILD_MESSAGES_FILE` (temporary file containing the session's message history, if active)
- If `BUILD_MESSAGES_FILE` is defined and valid, the provider must prioritize reading the historic messages array inside it, inserting them into the payload to preserve multi-turn sessions.
- If `SYSTEM_PROMPT` is set, the provider must integrate it (for example, by inserting it as a message with a `"system"` role at the head of the messages array).
- Write the final payload **to the `$PAYLOAD` file** (either in plain JSON format or base64-staged via the `stage_b64` utility).
- Must not produce any output to stdout.
- In case of error during payload compilation, return the canonical status code `"${BASH4LLM_ERR_TMP:-15}"`. **Avoid using undefined variables** (e.g., `BASH4LLMERRTMP` or `BASH4LLERR_TMP` without underscores), as they trigger immediate crashes in strict `set -u` mode.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsibilities:**
- Read the pre-compiled payload from the `$PAYLOAD` path.
- **Base64 Detection and Decoding:** If the file in `$PAYLOAD` ends with a `.b64` extension, the provider is responsible for decoding it to plain text in a local temporary file within `$RUN_TMPDIR` before forwarding it to `curl`.
- Perform the HTTP network call to the respective API server.
- Save the unmodified JSON response (including any native JSON error metadata) in `$RESP`.
- Return exit status code `0` on success, or non-zero (e.g., `"${BASH4LLM_ERR_API:-16}"` or `"${BASH4LLM_ERR_CURL_FAILED:-12}"`) on failure.
- The successful JSON response must match the OpenAI-like schema to remain compatible with the core's extraction routine (`choices[].message.content`). If it does not, the function must reshape the response before writing it to `$RESP`.

---

### 3.2. Optional Functions (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsibilities:**
- Perform the HTTP request in packet-streaming mode (Server-Sent Events).
- **High-Performance Pipeline Integration:** To avoid performance degradation caused by repeatedly invoking `jq` processes line by line, the provider **must** pipe the continuous output of `curl` into a single, unbuffered instance of `jq --unbuffered` using `tee`:
  ```bash
  curl ... | tee -a "$RESP_RAW" | jq --unbuffered -R -r '...'
  ```
- **Unified Error Interception and Formatting:** The continuous `jq` filter must detect if the server's response does not start with the SSE `data: ` prefix (indicative of an immediate non-SSE JSON error, e.g., a `429 Rate Limit`) and output the formatted native error message directly to the terminal (e.g., `\nAPI Error: <message>`).
- Accumulate received fragments and write the complete, aggregated JSON response to `$RESP` before the function exits (essential for preserving sessions and history).
- Return `0` on success, non-zero on network failure.

---

#### ➕ `refresh_models_<provider>()`

**Responsibilities:**
- Query the respective provider's model catalog endpoint.
- Generate the list of models and save it to the model file configured for the provider.
- To prevent write collisions between different providers, each module must locally redefine the `MODELS_FILE` variable to point to a specific file (e.g., `gemini.txt` instead of the generic, shared `models.txt`):
  `MODELS_FILE="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/gemini.txt}"`
- Write the provider's base URL inside the file returned by `canonical_provider_url_file` using atomic writing, and set the `BASH4LLM_PROVIDER_URL` variable accordingly.
- Respect security constraints (umask 077, no use of global shared directories like `/tmp`, no use of `eval` or `cd`).
- Return 0 on success.

*Note on capabilities: The CORE of Bash4LLM⁺ automatically detects if a provider supports this feature by inspecting the function's presence via `type "refresh_models_${provider}"`. No external enablement flags are required.*

---

#### ➕ `validate_key_<provider>()`

**Responsibilities:**
- Verify the validity of the API key entered by the user via a lightweight network request (GET) to the diagnostic endpoint of the respective provider.
- Set a rigid network timeout of 10 seconds (by passing `--max-time 10` to curl).
- Return the following exit status codes:
  - `0` if the key is valid (e.g., HTTP 200 response).
  - `1` if the key is invalid (e.g., HTTP 401/403/400 response).
  - `28` (or the error code returned by curl) in case of network timeout or connection failure.
- Respect strict `set -u` mode by managing variable existence via safe introspection before performing indirect expansions.

---

### 3.3: `normalize_model_<provider>()` (Optional)
* **Responsibilities:** Receives the raw model name as argument `$1`. It must return the normalized model name exclusively to `stdout`.
* **Isolation:** This function is executed by the CORE in a subshell. Any modification to global variables, current directory (`cd`), or shell options made inside the hook will not affect the CORE.
* **Output Constraints:** The output should ideally conform to the safe characters whitelist. Any non-compliant characters (e.g., spaces, control characters) will be stripped automatically by the CORE.

---

## 4. Variables Guaranteed by the CORE

The CORE of Bash4LLM⁺ makes available and populates the following environment and state variables before invoking the respective provider functions:

- `MODEL` (model to use)
- `CONTENT` (user's text prompt)
- `TURE` (numerical temperature parameter validated by the CORE, alias of `TEMPERATURE`)
- `MAX_TOKENS` (maximum number of tokens)
- `STREAM_MODE` (1 if streaming is active, 0 otherwise)
- `PAYLOAD` (payload file path)
- `RESP` (path where the JSON response should be written)
- `RUN_TMPDIR` (safe and isolated temporary directory specific to the current transaction)
- `CURL_BASE_OPTS` (array containing default curl options)
- `BUILD_MESSAGES_FILE` (path to the file containing the current session's message history)
- `SYSTEM_PROMPT` (system prompt if specified)
- `BASH4LLM_PROVIDER_URL` (base URL of the currently active provider)
- `BASH4LLM_API_KEY` (generic or inherited authentication key)

The provider must not modify or overwrite these variables in the main runtime of the CORE under any circumstances.

---

### 4.1. API Key Resolution and `set -u` Compatibility

Each provider must determine and extract the authentication key following this strict decreasing order of priority:

1. `PROVIDER_API_ENV_<provider>` (if defined in the environment, indicates the custom environment variable to read).
2. The provider-specific key (e.g., `GEMINI_API_KEY`, `MISTRAL_API_KEY`, or `HUGGINGFACE_API_KEY`).
3. The global fallback key `BASH4LLM_API_KEY`.

#### Safety under `set -u` (nounset) and indirect expansion:
To prevent fatal crashes caused by expanding non-declared dynamic references (e.g., `${!prov_env}`), the existence and state of environment variables must be inspected in advance via the native Bash introspection command `declare -p`. This guarantees complete compliance with `set -u` without mutating the global shell option flags of the script:

```bash
local key="" envvar
if type provider_api_env_var_name >/dev/null 2>&1; then
  envvar="$(provider_api_env_var_name "example")"
  # Safely check if the variable is declared before executing indirect expansion
  if [ -n "$envvar" ] && declare -p "$envvar" >/dev/null 2>&1; then
    key="${!envvar}"
  fi
fi
```

In the absence of a valid key for endpoints requiring authentication, the provider functions must abort safely, returning the canonical status code `"${BASH4LLM_ERR_NO_API_KEY:-10}"`.

---

## 5. Rules of Behavior and Invariants

🚫 **The provider MUST NOT:**
- Modify the current working directory (never use `cd`).
- Modify or pollute the global variables of the main script.
- Use the global `/tmp` directory or unmonitored paths (every temporary file must reside inside `RUN_TMPDIR`).
- Use the `eval` command.
- Generate spurious text output to stdout (with the exception of real-time decoded streaming text).
- Hardcode fixed URLs inside call functions; always refer to the resolution of `BASH4LLM_PROVIDER_URL`.
- **Directly call system `flock`:** Using file descriptor locks via `flock` is unstable or unsupported in mobile and sandboxed environments such as Termux (Android 14+), where it causes indefinite hangs or irreversible errors. The provider must rely entirely on the abstraction functions provided by the core (`atomic_write`, `lock_exec`), which automatically exclude `flock` on Termux and transparently detour to the atomic directory lock mechanism (`mkdir`).

⚠️ **The provider MUST:**
- Generate valid JSON files free of syntax errors.
- Respect file security constraints by setting restrictive permissions on generated files (`umask 077`).
- Respect the `DRY_RUN` option. If `DRY_RUN=1`, the core blocks network calls at the source via `enforce_network_policy`; the provider must still behave predictably, ensuring the writing of mock but formally valid `$RESP` or `$PAYLOAD` files.
- Ensure that every written file (JSON or text lists) always closes with a final newline (`\n`) character.

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

  # Build OpenAI-compatible chat completions payload using the validated temperature variable TURE
  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    --arg temp "${TURE:-1.0}" \
    '{model: $model, temperature: ($temp|tonumber), messages: [{role: "user", content: $content}]}' > "$tmpf"

  # Atomic write payload back to core configuration
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
  local key_trim prov_env key=""

  # Retrieve API key securely avoiding unbound variable triggers
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

  # Robust array-expansion wrapper for network execution
  local -a curl_cmd=(curl -sS)
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    -H "Authorization: Bearer ${key_trim}"
    -H "Content-Type: application/json"
    --data-binary @"$PAYLOAD"
    -o "$RESP"
    "$BASH4LLM_PROVIDER_URL"
  )

  "${curl_cmd[@]}"
  return $?
}
```
