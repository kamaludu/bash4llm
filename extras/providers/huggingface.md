[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)
 
**[vedi Contratto Provider - see Provider Contract](../../PROVIDERS.md)**

**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**

## 🇮🇹 Sezione Italiana
# Provider Hugging Face (`huggingface.sh`)

Il modulo `huggingface.sh` integra i servizi di inferenza di Hugging Face in Bash4LLM⁺ supportando sia gli **Inference Endpoint dedicati** sia il **Serverless Router unificato** (`router.huggingface.co`), escludendo meccanismi di discovery remota legacy e chiamate obsolete al vecchio Hub.

---

## 1. Principi chiave

- **Mappatura modelli**: Risoluzione locale dei modelli tramite file di configurazione dedicato o whitelist.
- **Endpoint supportati**: URL di **Inference Endpoint dedicati** (es. `https://<id>.<region>.endpoints.huggingface.cloud`) oppure, come fallback automatico, il **Serverless Router unificato** compatibile con lo standard OpenAI Chat Completions (`router.huggingface.co`).
- **Gestione API Key**: Lettura esclusivamente da variabile d'ambiente o Vault cifrato, con **redazione totale della chiave dagli argomenti di processo (`argv`)**.
- **Nessuna chiamata legacy al Hub**: Esclusione di chiamate deprecate (es. `/api/models` o `/models/<id>`) per elenchi modelli o validazioni.

---

## 2. Struttura dei file e percorsi

- Script modulo provider:  
  `bash4llm.d/extras/providers/huggingface.sh`
- File di configurazione endpoint:  
  `bash4llm.d/config/providers/hf_endpoints`
- Directory di runtime isolata:  
  `bash4llm.d/tmp` (via `RUN_TMPDIR` / `BASH4LLM_TMPDIR`)

---

## 3. Configurazione degli endpoint

### 3.1 Formato `hf_endpoints`

File: `bash4llm.d/config/providers/hf_endpoints`

```text
# Formato: <model_id>|<endpoint_url>
google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
llama-3.1-8b-instruct|https://abc1234.eu-west-1.aws.endpoints.huggingface.cloud
```

Regole:
- Una voce per riga.
- Separatore: `|` (pipe).
- L'identificativo a sinistra del pipe rappresenta il Model ID dell'Hub di Hugging Face (es. `google/gemma-2-2b-it`).
- `endpoint_url` definisce l'Inference Endpoint dedicato o l'indirizzo del Serverless Router.

### 3.2 Helper interni per l'amministrazione

Quando il modulo `huggingface.sh` viene caricato direttamente nella shell, sono disponibili le seguenti funzioni di supporto:

- `hf_list_endpoints`: Stampa l'elenco degli endpoint configurati.
- `hf_add_endpoint "<model>" "<url>"`: Aggiunge o aggiorna una voce nel file `hf_endpoints`.
- `hf_remove_endpoint "<model>"`: Rimuove l'endpoint associato al modello specificato.

Esempio d'uso:

```sh
. ./bash4llm.d/extras/providers/huggingface.sh

hf_add_endpoint "google/gemma-2-2b-it" "https://router.huggingface.co/v1/chat/completions"
hf_list_endpoints
hf_remove_endpoint "google/gemma-2-2b-it"
```

---

### 3.3 Configurazione di riferimento per `hf_endpoints`

Esempio di configurazione per `bash4llm.d/config/providers/hf_endpoints` per modelli ad accesso libero e gated:

```text
# Modelli ad accesso libero
deepseek-ai/DeepSeek-R1|https://router.huggingface.co/v1/chat/completions
microsoft/phi-4|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-7B-Instruct|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-72B-Instruct|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-Coder-32B-Instruct|https://router.huggingface.co/v1/chat/completions
deepseek-ai/DeepSeek-R1-Distill-Qwen-7B|https://router.huggingface.co/v1/chat/completions

# Modelli Gated (Richiedono accettazione preventiva delle condizioni su huggingface.co)
meta-llama/Llama-3.3-70B-Instruct|https://router.huggingface.co/v1/chat/completions
google/gemma-3-12b-it|https://router.huggingface.co/v1/chat/completions
google/gemma-3-27b-it|https://router.huggingface.co/v1/chat/completions
mistralai/Mistral-7B-Instruct-v0.3|https://router.huggingface.co/v1/chat/completions
```

---

## 4. API key e gestione sicurezza

- Variabile d'ambiente: `HUGGINGFACE_API_KEY` (o identificatore dinamico risolto dal Core).
- La chiave viene letta unicamente dalla memoria di processo tramite `ensure_api_key_for_provider`.
- La chiave **non viene mai scritta su file non cifrati**.
- In modalità non interattiva, l'assenza della chiave causa l'arresto immediato dell'esecuzione con codice di uscita `10` (`BASH4LLM_ERR_NO_API_KEY`).

### 4.1 Validazione della chiave API

Il modulo implementa la funzione `validate_key_huggingface` per la verifica preventiva del token:
- **Endpoint interrogato**: `https://huggingface.co/api/whoami-v2` (richiesta GET).
- **Invariante di sicurezza**: L'autenticazione viene inoltrata tramite `_exec_curl_secure()`, che memorizza la chiave in un file di header temporaneo privato (`0600`) e la reindirizza via File Descriptor senza mai esporre il token negli argomenti del comando `curl`.
- **Codici di ritorno**:
  - `0`: Token valido (HTTP 200).
  - `1`: Token non valido o non autorizzato (HTTP 401/403).
  - `28`: Timeout di rete (limite impostato a 10 secondi).

---

## 5. Comportamento a runtime

### 5.1 Risoluzione endpoint e fallback

Esecuzione standard:

```sh
./bash4llm --provider huggingface --model google/gemma-2-2b-it "Prompt di test"
```

Flusso di risoluzione:
1. Il modulo ricerca il modello specificato all'interno del file `hf_endpoints`.
2. Se presente, utilizza l'URL associato (`endpoint_url`).
3. In caso di mancata corrispondenza nel file locale, esegue il fallback verso il Serverless Router ufficiale all'indirizzo `https://router.huggingface.co/v1/chat/completions`.
4. Compila il payload JSON (formato Chat Completions) ed esegue la richiesta HTTP tramite la funzione di rete sicura del Core `_exec_curl_secure()`.

### 5.2 Trattamento errori e domini deprecati

- Il sistema non effettua connessioni verso il vecchio host deprecato `api-inference.huggingface.co`.
- In presenza di errori HTTP, il modulo scrive i metadati dell'errore nel file `$RESP` e restituisce il codice di errore canonico `16` (`BASH4LLM_ERR_API`).

---

## 6. Sincronizzazione ed elenco modelli

- **`--list-models`**: Stampa i modelli registrati nel file di configurazione locale `hf_endpoints`.
- **`--refresh-models`**: Sincronizza l'elenco locale rileggendo le voci di `hf_endpoints` ed aggiornando il file di cache dei modelli senza effettuare chiamate di rete esterne.

---

## 7. Limitazioni note

- Gli host appartenenti al vecchio dominio `api-inference.huggingface.co` non sono supportati.
- Lo streaming in tempo reale (`--stream`) è attivo per tutte le richieste instradate tramite il Serverless Router (`router.huggingface.co`). Per gli Inference Endpoint dedicati privati, lo streaming richiede che il contenitore remoto generi eventi SSE (Server-Sent Events) compatibili.
- I modelli contrassegnati come *Gated* richiedono la preventiva accettazione delle condizioni d'uso sull'account Hugging Face collegato al token.

---

## 8. Esempi d'uso

### 8.1 Inizializzazione configurazione minima

```sh
mkdir -p bash4llm.d/config/providers

cat > bash4llm.d/config/providers/hf_endpoints <<'EOF'
google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
EOF

export HUGGINGFACE_API_KEY="hf_..."
```

### 8.2 Richiesta singola

```sh
./bash4llm --provider huggingface --model google/gemma-2-2b-it "Spiega il funzionamento di una pipe in Unix."
```

### 8.3 Richiesta con contesto di sessione (Thread)

```sh
./bash4llm --thread test-conversazione "Il mio nome è Cristian."
./bash4llm --thread test-conversazione "Qual è il mio nome?"
```

---------_------------------

## 🇬🇧 English Section

# Hugging Face Provider (`huggingface.sh`)

The `huggingface.sh` module integrates Hugging Face inference services into Bash4LLM⁺, supporting both **Dedicated Inference Endpoints** and the official **Unified Serverless Router** (`router.huggingface.co`), explicitly excluding legacy remote discovery mechanisms and obsolete calls to the old Hub.

---

## 1. Key Principles

- **Model Mapping**: Local model resolution via a dedicated configuration file or whitelist.
- **Supported Endpoints**: URLs for **Dedicated Inference Endpoints** (e.g., `https://<id>.<region>.endpoints.huggingface.cloud`) or, as an automatic fallback, the **Unified Serverless Router** compatible with the OpenAI Chat Completions standard (`router.huggingface.co`).
- **API Key Management**: Read exclusively from process environment variables or the encrypted Vault, ensuring **complete redaction of the API key from process arguments (`argv`)**.
- **No Legacy Hub Calls**: Elimination of deprecated calls (e.g., `/api/models` or `/models/<id>`) for model discovery or validation.

---

## 2. File Structure and Paths

- Provider module script:  
  `bash4llm.d/extras/providers/huggingface.sh`
- Endpoint configuration file:  
  `bash4llm.d/config/providers/hf_endpoints`
- Isolated runtime directory:  
  `bash4llm.d/tmp` (via `RUN_TMPDIR` / `BASH4LLM_TMPDIR`)

---

## 3. Endpoint Configuration

### 3.1 `hf_endpoints` Format

File: `bash4llm.d/config/providers/hf_endpoints`

```text
# Format: <model_id>|<endpoint_url>
google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
llama-3.1-8b-instruct|https://abc1234.eu-west-1.aws.endpoints.huggingface.cloud
```

Rules:
- One entry per line.
- Delimiter: `|` (pipe).
- The identifier to the left of the pipe represents the canonical Hugging Face Hub Model ID (e.g., `google/gemma-2-2b-it`).
- `endpoint_url` defines the Dedicated Inference Endpoint or the Unified Serverless Router address.

### 3.2 Internal Administrative Helpers

When the `huggingface.sh` module is sourced directly in a shell environment, the following management helper functions are available:

- `hf_list_endpoints`: Displays the list of configured endpoints.
- `hf_add_endpoint "<model>" "<url>"`: Adds or updates an entry in the `hf_endpoints` file.
- `hf_remove_endpoint "<model>"`: Removes the endpoint entry associated with the specified model.

Usage example:

```sh
. ./bash4llm.d/extras/providers/huggingface.sh

hf_add_endpoint "google/gemma-2-2b-it" "https://router.huggingface.co/v1/chat/completions"
hf_list_endpoints
hf_remove_endpoint "google/gemma-2-2b-it"
```

---

### 3.3 Reference Configuration for `hf_endpoints`

Sample configuration for `bash4llm.d/config/providers/hf_endpoints` covering public and gated models:

```text
# Public access models
deepseek-ai/DeepSeek-R1|https://router.huggingface.co/v1/chat/completions
microsoft/phi-4|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-7B-Instruct|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-72B-Instruct|https://router.huggingface.co/v1/chat/completions
Qwen/Qwen2.5-Coder-32B-Instruct|https://router.huggingface.co/v1/chat/completions
deepseek-ai/DeepSeek-R1-Distill-Qwen-7B|https://router.huggingface.co/v1/chat/completions

# Gated models (Require prior terms acceptance on huggingface.co)
meta-llama/Llama-3.3-70B-Instruct|https://router.huggingface.co/v1/chat/completions
google/gemma-3-12b-it|https://router.huggingface.co/v1/chat/completions
google/gemma-3-27b-it|https://router.huggingface.co/v1/chat/completions
mistralai/Mistral-7B-Instruct-v0.3|https://router.huggingface.co/v1/chat/completions
```

---

## 4. API Key and Security Handling

- Environment variable: `HUGGINGFACE_API_KEY` (or dynamic variable name resolved by CORE).
- The key is read strictly from process memory via `ensure_api_key_for_provider`.
- The key **is never written to unencrypted files**.
- In non-interactive mode, a missing key causes immediate execution halt with exit code `10` (`BASH4LLM_ERR_NO_API_KEY`).

### 4.1 API Key Validation

The module implements the `validate_key_huggingface` function for proactive token validation:
- **Target endpoint**: `https://huggingface.co/api/whoami-v2` (GET request).
- **Security Invariant**: Authentication is forwarded via `_exec_curl_secure()`, which writes credentials to a private temporary header file (`0600`) and redirects via File Descriptor, keeping tokens completely hidden from process vectors (`argv` / `ps aux`).
- **Return codes**:
  - `0`: Valid token (HTTP 200).
  - `1`: Invalid or unauthorized token (HTTP 401/403).
  - `28`: Network timeout (10-second limit enforced).

---

## 5. Runtime Behavior

### 5.1 Endpoint Resolution and Fallback

Standard execution:

```sh
./bash4llm --provider huggingface --model google/gemma-2-2b-it "Test prompt"
```

Resolution sequence:
1. The module looks up the specified model name in the `hf_endpoints` file.
2. If found, it uses the associated `endpoint_url`.
3. If no match is found in the local file, it performs an automatic fallback to the official Serverless Router at `https://router.huggingface.co/v1/chat/completions`.
4. Compiles the JSON request payload (Chat Completions format) and executes the HTTP call via the Core's secure network function `_exec_curl_secure()`.

### 5.2 Error Handling and Deprecated Domains

- Connections to the deprecated host `api-inference.huggingface.co` are strictly prohibited.
- On HTTP errors, the module writes error metadata to the `$RESP` file and returns canonical exit code `16` (`BASH4LLM_ERR_API`).

---

## 6. Model Synchronization and Listing

- **`--list-models`**: Displays models registered in the local `hf_endpoints` configuration file.
- **`--refresh-models`**: Synchronizes local cache by re-reading `hf_endpoints` entries and updating the local models cache file without making external network calls.

---

## 7. Known Limitations

- Hosts on the legacy domain `api-inference.huggingface.co` are not supported.
- Real-time streaming (`--stream`) is available for requests routed through the Serverless Router (`router.huggingface.co`). For private Dedicated Inference Endpoints, streaming requires a container image generating valid SSE (Server-Sent Events) payloads.
- Models marked as *Gated* require prior acceptance of license terms on the Hugging Face account associated with the token.

---

## 8. Usage Examples

### 8.1 Minimal Configuration Setup

```sh
mkdir -p bash4llm.d/config/providers

cat > bash4llm.d/config/providers/hf_endpoints <<'EOF'
google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
EOF

export HUGGINGFACE_API_KEY="hf_..."
```

### 8.2 Single Request

```sh
./bash4llm --provider huggingface --model google/gemma-2-2b-it "Explain Unix pipes."
```

### 8.3 Request with Session Context (Thread)

```sh
./bash4llm --thread test-conversation "My name is Cristian."
./bash4llm --thread test-conversation "What is my name?"
```
