[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Providers  
Documento bilingue: [🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)
 
GroqBash 2.x

---

## 🇮🇹 Sezione Italiana

# Contratto Provider

Questo documento definisce il **contratto ufficiale** per creare provider esterni compatibili con GroqBash.  
Un *provider* è uno script Bash che implementa un backend alternativo all’API Groq (es. Gemini, HuggingFace, Mistral, ecc.).

I provider vengono caricati da:

```
extras/providers/<nome>.sh
```

e sono **eseguiti nella shell dell’utente**, con pieno accesso alle variabili del CORE.

---

## 1. Requisiti del file provider

Un provider deve:

- essere un file regolare (`-f`)  
- non essere un symlink  
- essere di proprietà dell’utente corrente  
- non essere scrivibile da gruppo/mondo  
- risiedere in una directory non world‑writable  

GroqBash verifica automaticamente questi requisiti tramite `extras/security/verify.sh`.

---

## 2. Nome del provider

Il nome del provider è il nome del file senza estensione:

```
extras/providers/gemini.sh  → provider "gemini"  
extras/providers/mistral.sh → provider "mistral"
```

---

## 3. Funzioni obbligatorie

Ogni provider deve implementare **tre funzioni**, con nome basato sul provider:

---

#### ✔️ `buildpayload_<provider>()`

Responsabilità:

- costruire il payload JSON **OpenAI‑like**  
  (es. `{"model":"...","messages":[...]}`)
- leggere variabili globali fornite dal CORE:
  - `MODEL`  
  - `CONTENT` (prompt utente)  
  - `TURE` (temperature)  
  - `MAX_TOKENS`  
  - `STREAM_MODE`  
- scrivere il payload **nel file `$PAYLOAD`**
- non produrre output su stdout  
- mai produrre payload vuoto
- newline finale obbligatorio
- Il provider può produrre payload JSON o payload base64-staged (.b64) tramite `stage_b64`

Formato richiesto: **OpenAI Chat Completions compatibile**  
es.
non‑streaming: `choices[].message.content`  
streaming: `choices[].delta.content`

---

#### ✔️ `call_api_<provider>()` (non‑streaming)

Responsabilità:

- leggere il payload da `$PAYLOAD`  
- eseguire la richiesta HTTP  
- salvare la risposta JSON in `$RESP`  
- restituire codice 0 in caso di successo  
- newline finale obbligatorio
- `$RESP` deve sempre esistere

La risposta deve contenere:

```
choices[].message.content
```

---

#### ✔️ `call_api_streaming_<provider>()`

Responsabilità:

- eseguire la richiesta in modalità streaming (SSE)  
- stampare i chunk testuali in tempo reale su stdout  
- salvare la risposta aggregata in `$RESP`  
- restituire codice 0  
- `$RESP` deve sempre esistere

Formato chunk richiesto:

```
data: { "choices":[{"delta":{"content":"..."}}] }
```

---

#### ✔️ `refresh_models_<provider>()`**
Funzione obbligatoria per tutti i provider che dichiarano supporto al refresh.

**Responsabilità:**
- interrogare l’endpoint dei modelli del provider;  
- generare il file `MODELS_FILE` con un modello per riga;  
- scrivere il file `provider-url` tramite scrittura atomica;  
- impostare `GROQBASH_PROVIDER_URL` coerentemente all’URL scritto;  
- rispettare `DRY_RUN`;  
- fallire in modo sicuro se manca la API key;  
- restituire `0` in caso di successo, diverso da zero in caso di errore.

**Vincoli:**
- nessun output su stdout;  
- `$RESP` deve essere scritto anche in caso di errore;  
- permessi sicuri (umask 077);  
- nessun uso di `/tmp`, `eval`, `cd`.

---

### **3.1. `supports_refresh_models`**
Il provider deve dichiarare esplicitamente:

```sh
supports_refresh_models=1
```

oppure:

```sh
supports_refresh_models_<provider>=1
```

L’assenza di questa variabile indica al CORE che il provider **non** supporta il refresh automatico dei modelli.

---

## 4. Variabili garantite dal CORE

Il CORE garantisce al provider:

- `MODEL`  
- `CONTENT`  
- `TURE`  
- `MAX_TOKENS`  
- `STREAM_MODE`  
- `PAYLOAD`  
- `RESP`  
- `RUN_TMPDIR`  
- `CURL_BASE_OPTS`  
- `JSON_INPUT`
- `MESSAGES_JSON`
- `BUILD_MESSAGES_FILE`
- `GROQBASH_TMP_PAYLOAD`
- `GROQBASH_PROVIDER_URL`
- `GROQBASH_API_KEY` (fallback API key)
- `PROVIDER_API_ENV_<provider>` (override dinamico della API key)
- API key specifiche del provider (es. `GEMINI_API_KEY`, `HFAPIKEY`, `MISTRAL_API_KEY`)

Il provider **non deve modificare** queste variabili.

---

### **4.1. Precedenza API key**
Il provider deve determinare la API key seguendo l’ordine:

1. `PROVIDER_API_ENV_<provider>` (se definita)  
2. `GROQBASH_API_KEY`  
3. API key specifica del provider (es. `GEMINI_API_KEY`)

Se nessuna API key è disponibile e l’endpoint richiede autenticazione, le funzioni `call_api_*` e `refresh_models_*` devono fallire in modo sicuro, scrivendo `$RESP` e restituendo codice non zero.

---

## 5. Regole di comportamento

🚫 Un provider **NON deve**:

- cambiare directory (`cd`)  
- modificare variabili globali del CORE  
- scrivere file solo in percorsi autorizzati (`RUN_TMPDIR`, `GROQBASH_TMPDIR`, `RESP`, `MODELS_FILE`)
- usare `/tmp`  
- usare `eval`  
- produrre output non JSON su stdout (eccetto streaming)  
- introdurre dipendenze non necessarie  
- alterare il formato JSON richiesto dal CORE  
- bypassare la network policy (e deve fallire se non è autorizzato)
- costruire URL hardcoded

⚠️ Un provider **DEVE**:

- restituire JSON o JSON→base64 valido  
- seguire lo schema OpenAI‑like  
- rispettare permessi sicuri (umask 077)
- rispettare DRY_RUN (non effettuare chiamate reali)
- garantire newline finale nei file JSON
- gestire correttamente errori di payload vuoto
- scrivere `$RESP` sempre, anche in errore
- gestire payload .b64
- usare `GROQBASH_PROVIDER_URL` come endpoint base

---

### **5.1. File provider-url**
Il CORE utilizza un file dedicato per memorizzare l’URL base del provider.

**Requisiti:**
- percorso determinato da `canonical_provider_url_file` (fornita dal CORE);  
- il provider non deve ridefinire tale funzione;  
- il file deve contenere **solo** l’URL base, una singola riga con newline finale;  
- deve essere scritto tramite scrittura atomica;  
- deve essere aggiornato da `refresh_models_<provider>()`;  
- deve essere coerente con `GROQBASH_PROVIDER_URL`.

---

### **5.2. File MODELS_FILE (models.txt)**
Il provider deve generare un file contenente la lista dei modelli disponibili.

**Requisiti:**
- un modello per riga;  
- nessun JSON, nessun commento, nessun metadata;  
- newline finale obbligatoria;  
- scrittura atomica;  
- generato e aggiornato da `refresh_models_<provider>()`;  
- deve esistere anche in `DRY_RUN`.

**Formato dei modelli**
Il file `MODELS_FILE` deve contenere:

- un modello per riga;  
- nessun JSON;  
- nessun commento;  
- nessun metadata;  
- solo testo semplice.

---

### **5.3. canonical_provider_url_file**
Il provider deve utilizzare il percorso restituito dal CORE tramite:

```sh
canonical_provider_url_file
```

Il provider **non deve** ridefinire questa funzione né modificare il percorso risultante.

---

### **5.4. resolve_provider_url**
Il CORE utilizza `resolve_provider_url` per determinare l’endpoint finale.

Il provider deve:
- assicurare che `provider-url` sia scritto prima che il CORE lo legga;  
- non ridefinire né interferire con `resolve_provider_url`;  
- non hardcodare URL che bypassino questa logica.

---

### **5.5. DRY_RUN**
Se `DRY_RUN=1`:

- nessuna chiamata di rete deve essere effettuata;  
- il provider deve comunque generare file validi:  
  - `RESP` (JSON fittizio valido),  
  - `MODELS_FILE` (anche vuoto ma valido),  
  - `provider-url`;  
- tutte le funzioni devono restituire `0` salvo errori strutturali.

---

## 6. Esempio minimo

```sh
buildpayload_example() {
    jq -n \
      --arg model "$MODEL" \
      --arg user "$CONTENT" \
      '{model:$model, messages:[{role:"user",content:$user}]}' \
      | jq ... > "$PAYLOAD"
}

call_api_example() {
    curl ${CURL_BASE_OPTS:-} \
         -H "Authorization: Bearer $EXAMPLE_API_KEY" \
         -H "Content-Type: application/json" \
         --data-binary @"$PAYLOAD" \
         -o "$RESP"
}

call_api_streaming_example() {
    curl ${CURL_BASE_OPTS:-} \
         -N \
         -H "Authorization: Bearer $EXAMPLE_API_KEY" \
         --data-binary @"$PAYLOAD" \
         "https://api.example.com/v1/chat/completions/stream"
}
```

## 📎 Note Finali 
Questo contratto garantisce che tutti i provider siano:

- coerenti  
- sicuri  
- compatibili con il CORE  
- facilmente manutenibili  

e che producano sempre JSON compatibile con `extract_text_from_resp`.

---

## 🇬🇧 English Section

# Provider Contract

This document defines the **official contract** for creating external providers compatible with GroqBash.  
A *provider* is a Bash script that implements an alternative backend to the Groq API (e.g., Gemini, HuggingFace, Mistral, etc.).

Providers are loaded from:

```
extras/providers/<name>.sh
```

and are **executed in the user’s shell**, with full access to CORE variables.

---

## 1. Provider file requirements

A provider must:

- be a regular file (`-f`)  
- not be a symlink  
- be owned by the current user  
- not be group/world‑writable  
- reside in a non‑world‑writable directory  

GroqBash automatically verifies these requirements through `extras/security/verify.sh`.

---

## 2. Provider name

The provider name is the filename without extension:

```
extras/providers/gemini.sh  → provider "gemini"  
extras/providers/mistral.sh → provider "mistral"
```

---

## 3. Mandatory functions

Each provider must implement **three functions**, with names based on the provider:

---

#### ✔️ `buildpayload_<provider>()`

Responsibilities:

- build the **OpenAI‑like** JSON payload  
  (e.g., `{"model":"...","messages":[...]}`)
- read global variables provided by the CORE:
  - `MODEL`  
  - `CONTENT` (user prompt)  
  - `TURE` (temperature)  
  - `MAX_TOKENS`  
  - `STREAM_MODE`  
- write the payload **to the `$PAYLOAD` file**
- produce no output on stdout  
- never produce an empty payload  
- final newline required  
- The provider may produce JSON payload or base64‑staged payload (.b64) via `stage_b64`

Required format: **OpenAI Chat Completions compatible**  
e.g.  
non‑streaming: `choices[].message.content`  
streaming: `choices[].delta.content`

---

#### ✔️ `call_api_<provider>()` (non‑streaming)

Responsibilities:

- read the payload from `$PAYLOAD`  
- execute the HTTP request  
- save the JSON response in `$RESP`  
- return exit code 0 on success  
- final newline required  
- `$RESP` must always exist

The response must contain:

```
choices[].message.content
```

---

#### ✔️ `call_api_streaming_<provider>()`

Responsibilities:

- execute the request in streaming mode (SSE)  
- print text chunks in real time to stdout  
- save the aggregated response in `$RESP`  
- return exit code 0  
- `$RESP` must always exist

Required chunk format:

```
data: { "choices":[{"delta":{"content":"..."}}] }
```

---

## 4. Variables guaranteed by the CORE

The CORE guarantees the provider:

- `MODEL`  
- `CONTENT`  
- `TURE`  
- `MAX_TOKENS`  
- `STREAM_MODE`  
- `PAYLOAD`  
- `RESP`  
- `RUN_TMPDIR`  
- `CURL_BASE_OPTS`  
- `JSON_INPUT`
- `MESSAGES_JSON`
- `BUILD_MESSAGES_FILE`
- `GROQBASH_TMP_PAYLOAD`
- `GROQBASH_PROVIDER_URL`
- `GROQBASH_API_KEY` (fallback API key)
- `PROVIDER_API_ENV_<provider>` (dynamic API key override)
- provider‑specific API keys (e.g., `GEMINI_API_KEY`, `HFAPIKEY`, `MISTRAL_API_KEY`)

The provider **must not modify** these variables.

---

## 5. Behavior rules

🚫 A provider **MUST NOT**:

- change directory (`cd`)  
- modify CORE global variables  
- write files outside authorized paths (`RUN_TMPDIR`, `GROQBASH_TMPDIR`, `RESP`, `MODELS_FILE`)
- use `/tmp`  
- use `eval`  
- produce non‑JSON output on stdout (except streaming)  
- introduce unnecessary dependencies  
- alter the JSON format required by the CORE  
- bypass the network policy (and must fail if not authorized)
- build hardcoded URLs

⚠️ A provider **MUST**:

- return valid JSON or JSON→base64  
- follow the OpenAI‑like schema  
- respect secure permissions (umask 077)
- respect DRY_RUN (no real network calls)
- guarantee final newline in JSON files  
- correctly handle empty‑payload errors  
- always write `$RESP`, even on error  
- handle .b64 payloads  
- use `GROQBASH_PROVIDER_URL` as the base endpoint

---

## 6. Minimal example

```sh
buildpayload_example() {
    jq -n \
      --arg model "$MODEL" \
      --arg user "$CONTENT" \
      '{model:$model, messages:[{role:"user",content:$user}]}' \
      | jq ... > "$PAYLOAD"
}

call_api_example() {
    curl ${CURL_BASE_OPTS:-} \
         -H "Authorization: Bearer $EXAMPLE_API_KEY" \
         -H "Content-Type: application/json" \
         --data-binary @"$PAYLOAD" \
         -o "$RESP"
}

call_api_streaming_example() {
    curl ${CURL_BASE_OPTS:-} \
         -N \
         -H "Authorization: Bearer $EXAMPLE_API_KEY" \
         --data-binary @"$PAYLOAD" \
         "https://api.example.com/v1/chat/completions/stream"
}
```

---

## 📎 Final Notes
This contract ensures that all providers are:

- consistent  
- secure  
- compatible with the CORE  
- easy to maintain  

and that they always produce JSON compatible with `extract_text_from_resp`.

---
