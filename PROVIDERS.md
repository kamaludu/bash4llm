[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Providers  
**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**
 
GroqBash 2.x

---

## 🇮🇹 Sezione Italiana


# Contratto Provider

Questo documento definisce il **contratto ufficiale** per creare o integrare provider esterni compatibili con GroqBash.  
Un *provider* è un modulo Bash che implementa un adattatore alternativo all’API Groq (es. Gemini, HuggingFace, Mistral, ecc.).

I provider vengono caricati in modalità isolata dal percorso di installazione degli extra:

`groqbash.d/extras/providers/nome.sh`


---

## 1. Caricamento e Isolamento (Sandbox)

A tutela della sicurezza del sistema, GroqBash **non** esegue il codice dei provider direttamente nel flusso principale del programma, bensì applica un meccanismo di isolamento:

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

Il core di GroqBash interagisce con i provider tramite funzioni dedicate. Per essere considerato valido dal validatore d'interfaccia, un provider **deve implementare obbligatoriamente le due funzioni principali** (non-streaming), mentre le funzioni di streaming e di refresh dei modelli sono considerati moduli opzionali integrativi.

---

### 3.1. Funzioni Obbligatorie (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsabilità:**
- Costruire un payload JSON in formato **OpenAI-like** (compatibile con la struttura Chat Completions, es. `{"model":"...","messages":[...]}`).
- Leggere le variabili globali fornite dal CORE:
  - `MODEL` (modello attivo)
  - `CONTENT` (prompt inserito dall'utente)
  - `TURE` (temperature)
  - `MAX_TOKENS`
  - `STREAM_MODE` (indica se la generazione richiederà uno streaming)
  - `SYSTEM_PROMPT` (prompt di sistema se impostato da CLI)
  - `BUILD_MESSAGES_FILE` (file temporaneo contenente la cronologia dei messaggi della sessione, se attiva)
- Se `BUILD_MESSAGES_FILE` è definito e valido, il provider deve dare la priorità alla lettura dell'array dei messaggi storici in esso contenuto, inserendoli nel payload per garantire il mantenimento della sessione (multi-turn).
- Se `SYSTEM_PROMPT` è impostata, il provider deve integrarla (ad esempio inserendola come messaggio con ruolo `"system"` in testa all'array dei messaggi).
- Scrivere il payload finale **nel file `$PAYLOAD`** (sia esso in formato JSON semplice o codificato base64-staged tramite l'utility `stage_b64`).
- Non produrre alcun output su stdout.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsabilità:**
- Leggere il payload pre-compilato dal percorso `$PAYLOAD`.
- Eseguire la chiamata di rete HTTP verso il rispettivo server API.
- Salvare la risposta JSON integra (inclusi eventuali metadati di errore nativi) in `$RESP`.
- Restituire codice di stato `0` in caso di successo, non-zero in caso di errore.
- La risposta JSON di successo deve rispettare lo schema OpenAI-like in modo da essere compatibile con la funzione di estrazione del core (`choices[].message.content`). In caso contrario, la funzione deve rimodellare la risposta prima di scriverla in `$RESP`.

---

### 3.2. Funzioni Opzionali (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsabilità:**
- Eseguire la richiesta HTTP in modalità streaming a pacchetti (Server-Sent Events).
- **Stampare direttamente su stdout il testo grezzo dei frammenti (chunk) non appena vengono ricevuti** per garantire l'effetto di digitazione fluida in tempo reale sul terminale.  
  *(Nota: il core di GroqBash non decodifica l'output dello streaming dei provider esterni; pertanto il provider non deve stampare le buste JSON SSE tipo `data: {...}` a schermo, ma deve decodificarle internamente in tempo reale).*
- Accumulare i frammenti ricevuti e scrivere la risposta JSON aggregata e completa in `$RESP` prima del termine della funzione (fondamentale per consentire la persistenza della sessione e della cronologia).
- Restituire `0` in caso di successo, non-zero in caso di errore di rete.

---

#### ➕ `refresh_models_<provider>()`

**Responsabilità:**
- Interrogare l'endpoint di catalogo dei modelli del rispettivo fornitore.
- Generare la lista dei modelli e salvarla nel file dei modelli configurato per il provider.
- Per evitare collisioni di scrittura tra diversi provider, ciascun modulo deve ridefinire localmente la variabile `MODELS_FILE` puntando a un file specifico (es. `gemini.txt` anziché il file generico condiviso `models.txt`):
  `MODELS_FILE="${MODELS_FILE:-${GROQBASH_MODELS_DIR:-}/gemini.txt}"`
- Scrivere l'URL base del provider all'interno del file restituito da canonical_provider_url_file tramite scrittura atomica, e impostare coerentemente la variabile GROQBASH_PROVIDER_URL.
- Rispettare i vincoli di sicurezza (umask 077, nessun uso di cartelle condivise globali come /tmp, nessun uso di eval o cd).
- Restituire 0 in caso di successo.

Nota sulle capacità: Il core di GroqBash rileva automaticamente se un provider
supporta questa funzionalità ispezionando la presenza della funzione tramite
type "refresh_models_${provider}". Non è richiesto l'uso di variabili di
abilitazione esterne.

4. Variabili garantite dal CORE

Il CORE di GroqBash rende disponibili e valorizza per il provider le seguenti
variabili d'ambiente e di stato prima di invocare le rispettive funzioni:

  - MODEL (modello da utilizzare)
  - CONTENT (prompt testuale dell'utente)
  - TURE / TEMPERATURE (parametro di temperatura numerico validato)
  - MAX_TOKENS (numero massimo di token)
  - STREAM_MODE (1 se streaming attivo, 0 altrimenti)
  - PAYLOAD (percorso del file del payload)
  - RESP (percorso in cui scrivere la risposta JSON)
  - RUN_TMPDIR (directory temporanea sicura e isolata specifica della
    transazione corrente)
  - CURL_BASE_OPTS (array contenente le opzioni curl di default del programma)
  - BUILD_MESSAGES_FILE (percorso del file contenente la cronologia dei messaggi
    della sessione corrente)
  - SYSTEM_PROMPT (prompt di sistema se specificato)
  - GROQBASH_PROVIDER_URL (URL base del provider attualmente attivo)
  - GROQBASH_API_KEY (chiave di autenticazione generica o ereditata)

Il provider non deve in nessun caso modificare o sovrascrivere queste variabili
nel runtime principale del core.

4.1. Risoluzione della API Key

Ciascun provider deve determinare ed estrarre la chiave di autenticazione
seguendo rigorosamente questo ordine di priorità decrescente:

1.  PROVIDER_API_ENV_<provider> (se definita nell'ambiente, indica la variabile
    d'ambiente personalizzata da leggere).
2.  La chiave specifica del provider (es. GEMINI_API_KEY o HF_API_KEY).
3.  La chiave generica globale di fallback GROQBASH_API_KEY.

In assenza di una chiave valida per gli endpoint che richiedono autenticazione,
le funzioni del provider devono interrompersi in sicurezza restituendo un codice
di stato non-zero e registrando un errore formattato in $RESP.

5. Regole di Comportamento e Invarianti

🚫 Il provider NON deve:

  - Modificare la directory di lavoro corrente (mai usare cd).
  - Modificare o inquinare le variabili globali dello script principale.
  - Utilizzare la directory globale /tmp o percorsi non controllati (ogni file
    temporaneo deve risiedere all'interno di RUN_TMPDIR).
  - Utilizzare il comando eval.
  - Generare output testuale spurio su stdout (ad eccezione dello streaming
    testuale decodificato in tempo reale).
  - Hardcodare URL fissi all'interno delle funzioni di chiamata, ma fare sempre
    riferimento alla risoluzione di GROQBASH_PROVIDER_URL.

⚠️ Il provider DEVE:

  - Generare file JSON validi ed esenti da errori di sintassi.
  - Rispettare i vincoli di sicurezza dei file generati impostando permessi
    restrittivi (umask 077).
  - Rispettare l'opzione DRY_RUN. Se DRY_RUN=1, il core blocca automaticamente
    le chiamate di rete a monte tramite la centrale enforce_network_policy; il
    provider deve comunque comportarsi in modo predittivo garantendo la
    scrittura di file $RESP o $PAYLOAD fittizi ma formalmente validi.
  - Assicurarsi che ogni file scritto (JSON o liste testuali) si chiuda sempre
    con un carattere di a capo (\n) finale.

6. Esempio Minimo di Struttura

```sh
# -------------------------
# buildpayload_example
# -------------------------
buildpayload_example() {
  local workdir tmpf
  workdir="$(_get_work_tmpdir_example)"
  tmpf="$(_mktemp_in_dir_example "$workdir")"

  # Genera il payload OpenAI-like
  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    '{model: $model, messages: [{role: "user", content: $content}]}' > "$tmpf"

  # Scrive in modalità atomica su PAYLOAD
  _write_atomic "$tmpf" "$PAYLOAD"
}

# -------------------------
# call_api_example
# -------------------------
call_api_example() {
  local key_trim
  key_trim="$(printf '%s' "$EXAMPLE_API_KEY" | awk '{$1=$1; print}')"

  # Esegue la chiamata non-streaming scrivendo su RESP
  curl "${CURL_BASE_OPTS[@]:-}" \
       -H "x-goog-api-key: ${key_trim}" \
       -H "Content-Type: application/json" \
       --data-binary @"$PAYLOAD" \
       -o "$RESP"
}
```

---

## 🇬🇧 English Section

# Provider Contract

This document defines the **official contract** to create or integrate external providers compatible with GroqBash.  
A *provider* is a Bash module that implements an alternative adapter to the Groq API (e.g., Gemini, HuggingFace, Mistral, etc.).

Providers are loaded in an isolated mode from the extras installation path:

`groqbash.d/extras/providers/<name>.sh`

---

## 1. Loading and Isolation (Sandbox)

To protect system security, GroqBash **does not** execute provider code directly in the main shell. Instead, it applies an isolation mechanism:

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

The GroqBash core interacts with providers through dedicated functions. To be considered valid by the interface validator, a provider **must implement the two main functions** (non-streaming), while streaming and model refreshing functions are treated as optional integrations.

---

### 3.1. Mandatory Functions (Core Interface)

#### ✔️ `buildpayload_<provider>()`

**Responsibilities:**
- Build a JSON payload in **OpenAI-like** format (compatible with the Chat Completions structure, e.g., `{"model":"...","messages":[...]}`).
- Read global variables provided by the CORE:
  - `MODEL` (active model)
  - `CONTENT` (text prompt entered by the user)
  - `TURE` (validated temperature)
  - `MAX_TOKENS` (maximum tokens)
  - `STREAM_MODE` (indicates if the generation requires streaming)
  - `SYSTEM_PROMPT` (system prompt if set via CLI)
  - `BUILD_MESSAGES_FILE` (temporary file containing the current session's message history, if active)
- If `BUILD_MESSAGES_FILE` is defined and valid, the provider must prioritize reading the array of historical messages contained within it, inserting them into the payload to guarantee session persistence (multi-turn).
- If `SYSTEM_PROMPT` is set, the provider must integrate it (e.g., by inserting it as a message with a `"system"` role at the beginning of the messages array).
- Write the final payload **into the `$PAYLOAD` file** (whether in raw JSON format or base64-staged via the `stage_b64` utility).
- Produce no output on stdout.

---

#### ✔️ `call_api_<provider>()` (Non-streaming)

**Responsibilities:**
- Read the pre-compiled payload from `$PAYLOAD`.
- Execute the HTTP network call to the respective API server.
- Save the complete JSON response (including any native error metadata) into `$RESP`.
- Return exit status `0` on success, non-zero on error.
- The successful JSON response must conform to the OpenAI-like schema to be compatible with the core's extraction function (`choices[].message.content`). Otherwise, the function must reshape the response before writing it to `$RESP`.

---

### 3.2. Optional Functions (Extended Interface)

#### ➕ `call_api_streaming_<provider>()`

**Responsibilities:**
- Execute the HTTP request in streaming chunk mode (Server-Sent Events).
- **Print the raw text of the chunks directly to stdout as they are received** to ensure a smooth, real-time typing effect on the terminal.  
  *(Note: the GroqBash core does not decode the streaming output of external providers; therefore, the provider must not print raw SSE JSON lines like `data: {...}` on screen, but must decode them internally in real time).*
- Accumulate the received chunks and write the complete, aggregated JSON response into `$RESP` before the function terminates (crucial to allow session and history persistence).
- Return `0` on success, non-zero on network error.

---

#### ➕ `refresh_models_<provider>()`

**Responsibilities:**
- Query the model catalog endpoint of the respective provider.
- Generate the model list and save it in the provider-specific model file.
- To avoid write collisions between different providers, each module must locally redefine the `MODELS_FILE` variable pointing to a specific file (e.g., `gemini.txt` instead of the shared `models.txt` file):
  `MODELS_FILE="${MODELS_FILE:-${GROQBASH_MODELS_DIR:-}/gemini.txt}"`
- Write the provider's base URL into the file returned by `canonical_provider_url_file` via atomic write, and consistently set the `GROQBASH_PROVIDER_URL` variable.
- Respect security constraints (umask 077, no use of global shared directories like `/tmp`, no use of `eval` or `cd`).
- Return `0` on success.

*Note on capabilities: The GroqBash core automatically detects whether a provider supports this feature by inspecting the presence of the function via `type "refresh_models_${provider}"`. No external enablement variables are required.*

---

## 4. Variables Guaranteed by the CORE

The GroqBash CORE makes available and populates the following environment and state variables for the provider before invoking its respective functions:

- `MODEL` (model to use)
- `CONTENT` (user's text prompt)
- `TURE` / `TEMPERATURE` (validated numerical temperature parameter)
- `MAX_TOKENS` (maximum token limit)
- `STREAM_MODE` (`1` if streaming active, `0` otherwise)
- `PAYLOAD` (payload file path)
- `RESP` (path where the JSON response should be written)
- `RUN_TMPDIR` (secure and isolated temporary directory specific to the current transaction)
- `CURL_BASE_OPTS` (array containing the default curl options of the program)
- `BUILD_MESSAGES_FILE` (file path containing the current session's message history)
- `SYSTEM_PROMPT` (system prompt if specified)
- `GROQBASH_PROVIDER_URL` (base URL of the currently active provider)
- `GROQBASH_API_KEY` (generic or inherited authentication key)

The provider **must under no circumstances modify or overwrite** these variables in the main runtime of the core.

---

### 4.1. API Key Resolution
Each provider must determine and extract the authentication key following this strict descending order of priority:

1. `PROVIDER_API_ENV_<provider>` (if defined in the environment, it indicates the custom environment variable to read).
2. The provider-specific key (e.g., `GEMINI_API_KEY` or `HF_API_KEY`).
3. The generic global fallback key `GROQBASH_API_KEY`.

In the absence of a valid key for endpoints requiring authentication, the provider's functions must abort safely, returning a non-zero exit status and recording a formatted error in `$RESP`.

---

## 5. Behavioral Rules and Invariants

🚫 **The provider MUST NOT:**
- Change the current working directory (never use `cd`).
- Modify or pollute the global variables of the main core script.
- Use the global `/tmp` directory or unmanaged paths (all temporary files must reside within `RUN_TMPDIR`).
- Use the `eval` command.
- Generate spurious text output on stdout (except for real-time decoded streaming text).
- Hardcode fixed URLs within calling functions, but always refer to the resolution of `GROQBASH_PROVIDER_URL`.

⚠️ **The provider MUST:**
- Generate valid JSON files free of syntax errors.
- Respect generated file security constraints by setting restrictive permissions (umask 077).
- Respect the `DRY_RUN` option. If `DRY_RUN=1`, the core automatically blocks network calls upstream via the central `enforce_network_policy`; the provider must still behave predictably, ensuring that dummy but formally valid `$RESP` or `$PAYLOAD` files are written.
- Ensure that every written file (JSON or text lists) always ends with a trailing newline (`\n`) character.

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

  # Generate the OpenAI-like payload
  jq -n \
    --arg model "$MODEL" \
    --arg content "$CONTENT" \
    '{model: $model, messages: [{role: "user", content: $content}]}' > "$tmpf"

  # Write atomically to PAYLOAD
  _write_atomic "$tmpf" "$PAYLOAD"
}

# -------------------------
# call_api_example
# -------------------------
call_api_example() {
  local key_trim
  key_trim="$(printf '%s' "$EXAMPLE_API_KEY" | awk '{$1=$1; print}')"

  # Execute the non-streaming call writing to RESP
  curl "${CURL_BASE_OPTS[@]:-}" \
       -H "x-goog-api-key: ${key_trim}" \
       -H "Content-Type: application/json" \
       --data-binary @"$PAYLOAD" \
       -o "$RESP"
}
```
---
