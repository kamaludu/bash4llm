[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Providers  
**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**
 
Bash4LLM 2.x

---

## 🇮🇹 Sezione Italiana

# Contratto Provider

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
- Eseguire la chiamata di rete HTTP verso il rispettivo server API.
- Salvare la risposta JSON integra (inclusi eventuali metadati di errore nativi) in `$RESP`.
- Restituire codice di stato `0` in caso di successo, non-zero (es. `"${BASH4LLM_ERR_API:-16}"` o `"${BASH4LLM_ERR_CURL_FAILED:-12}"`) in caso di errore.
- La risposta JSON di successo deve rispettare lo schema OpenAI-like in modo da essere compatibile con la funzione di estrazione del core (`choices[].message.content`). In caso contrario, la funzione deve rimodellare la risposta prima di scriverla in `$RESP`.

---

### 3.2. Funzioni Opzionali (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsabilità:**
- Eseguire la richiesta HTTP in modalità streaming a pacchetti (Server-Sent Events).
- **Stampare direttamente su stdout il testo grezzo dei frammenti (chunk) non appena vengono ricevuti** per garantire l'effetto di digitazione fluida in tempo reale sul terminale.  
  *(Nota: il core di Bash4LLM⁺ non decodifica l'output dello streaming dei provider esterni; pertanto il provider non deve stampare le buste JSON SSE tipo `data: {...}` a schermo, ma deve decodificarle internamente in tempo reale).*
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
- Rispettare la modalità rigorosa `set -u` gestendo e ripristinando temporaneamente lo stato tramite variabili locali se necessario.

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
3. La chiave generica globale di fallback `BASH4LLM_API_KEY`.

#### Sicurezza `set -u` (nounset) ed espansione indiretta:
Se il CORE o l'ambiente dell'utente utilizzano la modalità rigorosa `set -u`, l'uso dell'espansione indiretta (es. `${!prov_env}`) su una variabile vuota o non definita causerà un blocco o un errore fatale (`invalid variable name`). 
Per garantire la massima robustezza, ogni operazione di risoluzione della chiave deve:
1. Verificare esplicitamente che `prov_env` non sia vuota prima di eseguire l'espansione indiretta: `[ -n "$prov_env" ]`.
2. Utilizzare un meccanismo di salvataggio/ripristino dello stato `set -u` all'interno delle funzioni per evitare crash:

```bash
local _set_u_was_on=0
case "$-" in
  *u*) _set_u_was_on=1; set +u ;;
esac

# ... operazioni di risoluzione chiave ...

[ "$_set_u_was_on" -eq 1 ] && set -u
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

  # Genera il payload OpenAI-like usando la variabile di temperatura canonica TURE
  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    --arg temp "${TURE:-1.0}" \
    '{model: $model, temperature: ($temp|tonumber), messages: [{role: "user", content: $content}]}' > "$tmpf"

  # Scrive in modalità atomica su PAYLOAD usando il CORE helper
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
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local key_trim prov_env
  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "example")"
    if [ -n "$prov_env" ]; then
      EXAMPLE_API_KEY="${!prov_env:-${EXAMPLE_API_KEY:-}}"
    fi
  fi

  key_trim="$(printf '%s' "${EXAMPLE_API_KEY:-}" | awk '{$1=$1; print}')"

  if [ -z "$key_trim" ]; then
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  # Esegue la chiamata non-streaming scrivendo su RESP tramite array robusto
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
  local rc=$?

  [ "$_set_u_was_on" -eq 1 ] && set -u
  return $rc
}
```

---

## 🇬🇧 English Section

# Provider Contract

This document defines the **official contract** to create or integrate external providers compatible with Bash4LLM⁺.  
A *provider* is a Bash module that implements an alternative adapter to the Groq API (e.g., Gemini, HuggingFace, Mistral, etc.).

Providers are loaded in an isolated mode from the extras installation path:

`bash4llm.d/extras/providers/<name>.sh`

---

## 1. Loading and Isolation (Sandbox)

To protect system security, Bash4LLM⁺ **does not** execute provider code directly in the main shell. Instead, it applies an isolation mechanism:

1. The provider file is analyzed in an **isolated subshell (sandbox)** via `load_provider_module`.
2. Only **function definitions are captured and exported** into the main shell (via `declare -f`).
3. **Global variables or initialization code located outside functions in the provider file do not persist in the main runtime.** Any configuration parameters, URLs, or constants must therefore be defined internally within the functions or managed through the CORE's resolution mechanisms.

---

## 2. File Security Requirements

Every provider module must pass the integrity checks of `extras/security/verify.sh` and meet the following requirements:

- Be a regular file (`-f`).
- Not be a symbolic link (symlink).
- Be owned by the current user running the script.
- Not have write permissions for the group or other users (not world/group-writable).
- Reside in a non-world-writable directory.

The provider name is determined by the filename without its extension (e.g., `gemini.sh` identifies the `"gemini"` provider).

---

## 3. Provider Interface

The core of Bash4LLM⁺ interacts with providers through dedicated functions. To be considered valid by the interface validator, a provider **must implement the two main functions** (non-streaming), while the streaming and model refresh functions are considered optional integrations.

---

### 3.1. Mandatory Functions (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsibilities:**
- Build a JSON payload in **OpenAI-like** format (compatible with the Chat Completions structure, e.g., `{"model":"...","messages":[...]}`).
- Read global variables provided by the CORE:
  - `MODEL` (active model)
  - `CONTENT` (text prompt entered by the user)
  - `TURE` (validated temperature variable from the CORE)
  - `MAX_TOKENS` (maximum tokens)
  - `STREAM_MODE` (indicates if the generation requires streaming)
  - `SYSTEM_PROMPT` (system prompt if set via CLI)
  - `BUILD_MESSAGES_FILE` (temporary file containing the current session's message history, if active)
- If `BUILD_MESSAGES_FILE` is defined and valid, the provider must prioritize reading the array of historical messages contained within it, inserting them into the payload to guarantee session persistence (multi-turn).
- If `SYSTEM_PROMPT` is set, the provider must integrate it (e.g., by inserting it as a message with a `"system"` role at the beginning of the messages array).
- Write the final payload **into the `$PAYLOAD` file** (whether in raw JSON format or base64-staged via the `stage_b64` utility).
- Produce no output on stdout.
- On error during payload compilation, return the canonical exit code `"${BASH4LLM_ERR_TMP:-15}"`. **Avoid using unassigned variables** (e.g. typos like `BASH4LLMERRTMP` or `BASH4LLERR_TMP`), as they trigger immediate crashes in `set -u` mode.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsibilities:**
- Read the pre-compiled payload from `$PAYLOAD`.
- Execute the HTTP network call to the respective API server.
- Save the complete JSON response (including any native error metadata) into `$RESP`.
- Return exit status `0` on success, non-zero (e.g., `"${BASH4LLM_ERR_API:-16}"` or `"${BASH4LLM_ERR_CURL_FAILED:-12}"`) on error.
- The successful JSON response must conform to the OpenAI-like schema to be compatible with the core's extraction function (`choices[].message.content`). Otherwise, the function must reshape the response before writing it to `$RESP`.

---

### 3.2. Optional Functions (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsibilities:**
- Execute the HTTP request in streaming chunk mode (Server-Sent Events).
- **Print the raw text of the chunks directly to stdout as they are received** to ensure a smooth, real-time typing effect on the terminal.  
  *(Note: the Bash4LLM⁺ core does not decode the streaming output of external providers; therefore, the provider must not print raw SSE JSON lines like `data: {...}` on screen, but must decode them internally in real time).*
- Accumulate the received chunks and write the complete, aggregated JSON response into `$RESP` before the function terminates (crucial to allow session and history persistence).
- Return `0` on success, non-zero on network error.

---

#### ➕ `refresh_models_<provider>()`

**Responsibilities:**
- Query the model catalog endpoint of the respective provider.
- Generate the model list and save it in the provider-specific model file.
- To avoid write collisions between different providers, each module must locally redefine the `MODELS_FILE` variable pointing to a specific file (e.g., `gemini.txt` instead of the shared `models.txt` file):
  `MODELS_FILE="${MODELS_FILE:-${BASH4LLM_MODELS_DIR:-}/gemini.txt}"`
- Write the provider's base URL into the file returned by `canonical_provider_url_file` via atomic write, and consistently set the `BASH4LLM_PROVIDER_URL` variable.
- Respect security constraints (umask 077, no use of global shared directories like `/tmp`, no use of `eval` or `cd`).
- Return `0` on success.

*Note on capabilities: The Bash4LLM⁺ core automatically detects whether a provider supports this feature by inspecting the presence of the function via `type "refresh_models_${provider}"`. No external enablement variables are required.*

---

#### ➕ `validate_key_<provider>()`

**Responsibilities:**
- Verify the validity of the API key entered by the user via a lightweight network request (GET) to the respective provider's diagnostic endpoint.
- Set a strict network timeout of 10 seconds (by passing `--max-time 10` to curl).
- Return the following status codes:
- `0` if the key is valid (e.g., HTTP 200 response).
- `1` if the key is invalid (e.g., HTTP 401/403/400 response).
- `28` (or the error code returned by curl) in the event of a network timeout or connection failure.
- Enforce the strict `set -u` mode by temporarily managing and restoring state via local variables if necessary.

---

### 3.3: `normalize_model_<provider>()` (Optional)
* **Responsibilities:** Takes the raw model name as the `$1` argument. Must return only the normalized model name to `stdout`.
* **Isolation:** The function is executed by CORE in a subshell. Any changes to global variables, the current directory (`cd`), or shell options made within the hook will have no effect on CORE.
* **Output Constraints:** The output should ideally conform to the whitelist of safe characters. Any non-conforming characters (e.g., spaces, control symbols) will be automatically removed from CORE.

---

## 4. Variables Guaranteed by the CORE

The Bash4LLM⁺ CORE makes available and populates the following environment and state variables for the provider before invoking its respective functions:

- `MODEL` (model to use)
- `CONTENT` (user's text prompt)
- `TURE` (validated numerical temperature parameter, alias of `TEMPERATURE`)
- `MAX_TOKENS` (maximum token limit)
- `STREAM_MODE` (`1` if streaming active, `0` otherwise)
- `PAYLOAD` (payload file path)
- `RESP` (path where the JSON response should be written)
- `RUN_TMPDIR` (secure and isolated temporary directory specific to the current transaction)
- `CURL_BASE_OPTS` (array containing the default curl options of the program)
- `BUILD_MESSAGES_FILE` (file path containing the current session's message history)
- `SYSTEM_PROMPT` (system prompt if specified)
- `BASH4LLM_PROVIDER_URL` (base URL of the currently active provider)
- `BASH4LLM_API_KEY` (generic or inherited authentication key)

The provider **must under no circumstances modify or overwrite** these variables in the main runtime of the core.

---

### 4.1. API Key Resolution and `set -u` Compatibility

Each provider must determine and extract the authentication key following this strict descending order of priority:

1. `PROVIDER_API_ENV_<provider>` (if defined in the environment, it indicates the custom environment variable to read).
2. The provider-specific key (e.g., `GEMINI_API_KEY`, `MISTRAL_API_KEY` or `HF_API_KEY`).
3. The generic global fallback key `BASH4LLM_API_KEY`.

#### `set -u` (nounset) safety and indirect expansion:
If the CORE or user environment has `set -u` (nounset) enabled, performing indirect expansion (e.g., `${!prov_env}`) on an empty or undefined variable will trigger a fatal shell error (`invalid variable name`).
For maximum robustness, every key resolution operation must:
1. Explicitly verify that `prov_env` is non-empty before evaluating indirect expansion: `[ -n "$prov_env" ]`.
2. Temporarily disable `set -u` inside key-resolving helper functions to prevent unexpected shell crashes:

```bash
local _set_u_was_on=0
case "$-" in
  *u*) _set_u_was_on=1; set +u ;;
esac

# ... perform dynamic/indirect expansions safely ...

[ "$_set_u_was_on" -eq 1 ] && set -u
```

In the absence of a valid key for endpoints requiring authentication, the provider's functions must abort safely, returning a non-zero exit status and recording a formatted error in `$RESP`.

---

## 5. Behavioral Rules and Invariants

🚫 **The provider MUST NOT:**
- Change the current working directory (never use `cd`).
- Modify or pollute the global variables of the main core script.
- Use the global `/tmp` directory or unmanaged paths (all temporary files must reside within `RUN_TMPDIR`).
- Use the `eval` command.
- Generate spurious text output on stdout (except for real-time decoded streaming text).
- Hardcode fixed URLs within calling functions, but always refer to the resolution of `BASH4LLM_PROVIDER_URL`.

⚠️ **The provider MUST:**
- Generate valid JSON files free of syntax errors.
- Respect generated file security constraints by setting restrictive permissions (umask 077).
- Respect the `DRY_RUN` option. If `DRY_RUN=1`, the core automatically blocks network calls upstream via the central `enforce_network_policy`; the provider must still behave predictably, ensuring that dummy but formally valid `$RESP` or `$PAYLOAD` files are written.
- Ensure that every written file (JSON or text lists) always ends with a trailing newline (`\n`) character.
- **Avoid calling system `flock` directly:** using lock files on file descriptors via `flock` is unstable or unsupported on sandboxed/mobile environments such as Termux (Android 14+), causing indefinite hangs or kernel deadlocks. The provider must rely solely on the core's abstract lock utilities (`atomic_write`, `lock_exec`), which automatically bypass `flock` on Termux and transparently fall back to directory lock atomicity (`mkdir`).

---

## 6. Minimal Structure Example

```sh
# -------------------------
# buildpayload_example
# -------------------------
buildpayload_example() {
  local workdir tmpf
  workdir="$(_get_work_tmpdir_example)"
  tmpf="$(_mktemp_in_dir_example "$workdir")"

  # Generate the OpenAI-like payload using canonical temperature TURE
  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    --arg temp "${TURE:-1.0}" \
    '{model: $model, messages: [{role: "user", content: $content}], temperature: ($temp|tonumber)}' > "$tmpf"

  # Write atomically to PAYLOAD
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
  local _set_u_was_on=0
  case "$-" in
    *u*) _set_u_was_on=1; set +u ;;
  esac

  local key_trim prov_env
  if type provider_api_env_var_name >/dev/null 2>&1; then
    prov_env="$(provider_api_env_var_name "example")"
    if [ -n "$prov_env" ]; then
      EXAMPLE_API_KEY="${!prov_env:-${EXAMPLE_API_KEY:-}}"
    fi
  fi

  key_trim="$(printf '%s' "${EXAMPLE_API_KEY:-}" | awk '{$1=$1; print}')"

  if [ -z "$key_trim" ]; then
    [ "$_set_u_was_on" -eq 1 ] && set -u
    return "${BASH4LLM_ERR_NO_API_KEY:-10}"
  fi

  # Execute the non-streaming call writing to RESP
  local -a curl_cmd=(curl)
  if [ -n "${CURL_BASE_OPTS[*]:-}" ]; then
    curl_cmd+=("${CURL_BASE_OPTS[@]}")
  fi
  curl_cmd+=(
    -H "x-goog-api-key: ${key_trim}"
    -H "Content-Type: application/json"
    --data-binary @"$PAYLOAD"
    -o "$RESP"
    "$BASH4LLM_PROVIDER_URL"
  )

  "${curl_cmd[@]}"
  local rc=$?

  [ "$_set_u_was_on" -eq 1 ] && set -u
  return $rc
}
```
