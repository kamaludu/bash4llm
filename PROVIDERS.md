[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Providers  
Documento bilingue: Italiano / English  
GroqBash 2.x

---

# 🇮🇹 Sezione Italiana — Contratto Provider

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

### ✔️ `buildpayload_<provider>()`

Responsabilità:

- costruire il payload JSON **OpenAI‑like**  
  (es. `{"model":"...","messages":[...]}`)
- leggere variabili globali fornite dal CORE:
  - `MODEL`  
  - `CONTENT` (prompt utente)  
  - `SYSTEM_PROMPT`  
  - `TURE` (temperature)  
  - `MAX_TOKENS`  
  - `STREAM_MODE`  
- scrivere il payload **nel file `$PAYLOAD`** usando `atomic_write`  
- non produrre output su stdout  

Formato richiesto: **OpenAI Chat Completions compatibile**  
(es. `choices[].message.content`)

---

### ✔️ `call_api_<provider>()` (non‑streaming)

Responsabilità:

- leggere il payload da `$PAYLOAD`  
- eseguire la richiesta HTTP  
- salvare la risposta JSON in `$RESP`  
- restituire codice 0 in caso di successo  

La risposta deve contenere:

```
choices[].message.content
```

---

### ✔️ `call_api_streaming_<provider>()`

Responsabilità:

- eseguire la richiesta in modalità streaming (SSE)  
- stampare i chunk testuali in tempo reale su stdout  
- salvare la risposta aggregata in `$RESP`  
- restituire codice 0  

Formato chunk richiesto:

```
data: { "choices":[{"delta":{"content":"..."}}] }
```

---

## 4. Variabili garantite dal CORE

Il CORE garantisce al provider:

- `MODEL`  
- `CONTENT`  
- `SYSTEM_PROMPT`  
- `TURE`  
- `MAX_TOKENS`  
- `STREAM_MODE`  
- `PAYLOAD`  
- `RESP`  
- `ERRF`  
- `RUN_TMPDIR`  
- `CURL_BASE_OPTS`  
- API key specifiche del provider (es. `GEMINI_API_KEY`, `HFAPIKEY`, `MISTRAL_API_KEY`)

Il provider **non deve modificare** queste variabili.

---

## 5. Regole di comportamento

Un provider **NON deve**:

- cambiare directory (`cd`)  
- modificare variabili globali del CORE  
- scrivere file fuori da `$RUN_TMPDIR` o `$GROQBASH_TMPDIR`  
- usare `/tmp`  
- usare `eval`  
- produrre output non JSON su stdout (eccetto streaming)  
- introdurre dipendenze non necessarie  
- alterare il formato JSON richiesto dal CORE  

Un provider **DEVE**:

- restituire JSON valido  
- seguire lo schema OpenAI‑like  
- usare `atomic_write`  
- rispettare permessi sicuri (umask 077)

---

## 6. Esempio minimo

```sh
buildpayload_example() {
    jq -n \
      --arg model "$MODEL" \
      --arg user "$CONTENT" \
      '{model:$model, messages:[{role:"user",content:$user}]}' \
      | atomic_write "$PAYLOAD"
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

# 🇬🇧 English Section — Provider Contract

This document defines the **official contract** for creating external providers compatible with GroqBash.

Providers live in:

```
extras/providers/<name>.sh
```

and run **inside the user’s shell**.

---

## 1. Provider file requirements

A provider must:

- be a regular file (`-f`)  
- not be a symlink  
- be owned by the current user  
- not be group/world writable  
- reside in a non‑world‑writable directory  

---

## 2. Provider name

The provider name is the filename without extension:

```
gemini.sh  → "gemini"  
mistral.sh → "mistral"
```

---

## 3. Required functions

Each provider must implement:

---

### ✔️ `buildpayload_<provider>()`
- Build an **OpenAI‑compatible JSON payload**  
- Use global variables (`MODEL`, `CONTENT`, `SYSTEM_PROMPT`, `TURE`, `MAX_TOKENS`)  
- Write the payload to `$PAYLOAD` using `atomic_write`  
- Produce **no stdout output**

---

### ✔️ `call_api_<provider>()`
- Perform the **non‑streaming** HTTP request  
- Read from `$PAYLOAD`  
- Write the full JSON response to `$RESP`  
- Return exit code 0 on success  

Response must contain:

```
choices[].message.content
```

---

### ✔️ `call_api_streaming_<provider>()`
- Perform the **streaming** request (SSE)  
- Print chunks to stdout  
- Save the aggregated JSON to `$RESP`  
- Return exit code 0  

Chunk format:

```
data: { "choices":[{"delta":{"content":"..."}}] }
```

---

## 4. Variables guaranteed by GroqBash

The CORE provides:

- `MODEL`  
- `CONTENT`  
- `SYSTEM_PROMPT`  
- `TURE`  
- `MAX_TOKENS`  
- `STREAM_MODE`  
- `PAYLOAD`  
- `RESP`  
- `ERRF`  
- `RUN_TMPDIR`  
- `CURL_BASE_OPTS`  
- provider‑specific API keys  

Providers **must not modify** these variables.

---

## 5. Behavioral rules

A provider **MUST NOT**:

- change directory  
- modify CORE globals  
- write unsafe files  
- output non‑JSON to stdout (except streaming)  
- use `/tmp`  
- use `eval`  

A provider **MUST**:

- output valid JSON  
- follow the OpenAI‑like schema  
- use `atomic_write`  
- respect secure permissions  

---

## 6. Minimal example

```sh
buildpayload_example() {
    jq -n \
      --arg model "$MODEL" \
      --arg user "$CONTENT" \
      '{model:$model, messages:[{role:"user",content:$user}]}' \
      | atomic_write "$PAYLOAD"
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

and that they always produce JSON compatible with `extract_text_from_text`.
