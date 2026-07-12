[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](../../README.md)

**[vedi Contratto Provider - see Provider Contract](../../PROVIDERS.md)**

## Provider Hugging Face (`huggingface.sh`)

Questo provider integra Hugging Face in Bash4LLM offrendo un'architettura ibrida e sicura: supporta sia gli **Inference Endpoint dedicati** sia il **Serverless Router unificato** ufficiale (`router.huggingface.co`), escludendo qualsiasi meccanismo di discovery remota legacy o chiamate obsolete al vecchio Hub.

---

### 1. Principi chiave

- **Modelli disponibili**: solo quelli mappati localmente in un file di configurazione o esplicitamente autorizzati.
- **Endpoint supportati**: URL di **Inference Endpoint dedicati** (es. `https://<id>.<region>.endpoints.huggingface.cloud`) oppure, come fallback automatico e gratuito, il **Serverless Router unificato** compatibile con lo standard OpenAI Chat Completions.
- **API key**: letta da variabile d’ambiente, **mai salvata su disco**.
- **Nessuna chiamata legacy al Hub** (come `/api/models` o `/models/<id>`) per elenchi modelli o validazione.

---

### 2. File e path usati

- Script provider:  
  `bash4llm.d/extras/providers/huggingface.sh`
- Configurazione endpoint:  
  `bash4llm.d/config/providers/hf_endpoints`
- Tmp runtime confinata:  
  `bash4llm.d/tmp` (via `RUN_TMPDIR` / `BASH4LLM_TMPDIR`)

---

### 3. Configurazione degli endpoint

#### 3.1 Formato `hf_endpoints`

File: `bash4llm.d/config/providers/hf_endpoints`

```text
# Format: <model_name>|<endpoint_url>
google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
llama-3.1-8b-instruct|https://abc1234.eu-west-1.aws.endpoints.huggingface.cloud
```

Regole:

- Una riga per modello.
- Separatore: `|` (pipe).
- L'identificativo a sinistra del pipe deve essere il Model ID canonico dell'Hub di Hugging Face (es. `google/gemma-2-2b-it`).
- `endpoint_url` può essere un Inference Endpoint dedicato o l'indirizzo del Serverless Router unificato.

#### 3.2 Helper interni

Quando `huggingface.sh` è sorgente-ato manualmente (fuori da Bash4LLM core) sono disponibili helper:

- **`hf_list_endpoints`**  
  Stampa l’elenco degli endpoint configurati.

- **`hf_add_endpoint "<model>" "<url>"`**  
  Aggiunge (o sostituisce) una riga nel file `hf_endpoints`.

- **`hf_remove_endpoint "<model>"`**  
  Rimuove l’endpoint associato a `<model>`.

Esempio:

```sh
. ./bash4llm.d/extras/providers/huggingface.sh

hf_add_endpoint "google/gemma-2-2b-it" "https://router.huggingface.co/v1/chat/completions"
hf_list_endpoints
hf_remove_endpoint "google/gemma-2-2b-it"
```

---

> [!TIP]
> **File hf_endpoints pregenerato**
> 
> Ecco una selezione di modelli di testo e conversazionali attivi sul serverless Hugging Face, suddivisi tra modelli ad accesso libero e modelli gated (che richiedono l'accettazione preliminare delle condizioni d'uso sul portale Hugging Face). 
> 
> Crea o sostituisci il contenuto del file:
> `bash4llm.d/config/providers/hf_endpoints`
> 
> con le seguenti righe:
>
> **Modelli Liberi (Accesso immediato con qualsiasi Token HF valido)**
> 
> ```text
> # Modelli Liberi (Accesso immediato con qualsiasi Token HF valido)
> Qwen/Qwen2.5-7B-Instruct|https://router.huggingface.co/v1/chat/completions
> Qwen/Qwen2.5-Coder-7B-Instruct|https://router.huggingface.co/v1/chat/completions
> microsoft/Phi-3-mini-4k-instruct|https://router.huggingface.co/v1/chat/completions
> microsoft/Phi-3.5-mini-instruct|https://router.huggingface.co/v1/chat/completions
> HuggingFaceTB/smollm2-1.7b-instruct|https://router.huggingface.co/v1/chat/completions
> deepseek-ai/DeepSeek-R1|https://router.huggingface.co/v1/chat/completions
> ```
>
> 
> **Modelli Gated (Richiedono l'accettazione dei termini d'uso su huggingface.co prima dell'uso)**
> 
> ```text
> # Modelli Gated (Richiedono l'accettazione dei termini d'uso su huggingface.co prima dell'uso)
> google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
> mistralai/Mistral-7B-Instruct-v0.3|https://router.huggingface.co/v1/chat/completions
> meta-llama/Llama-3.2-1B-Instruct|https://router.huggingface.co/v1/chat/completions
> meta-llama/Llama-3.2-3B-Instruct|https://router.huggingface.co/v1/chat/completions
> ```

---

### 4. API key e sicurezza

- Variabile usata: `HUGGINGFACE_API_KEY` (o alias risolto dal core).
- La chiave viene letta solo da ambiente (o da `ensure_api_key_for_provider`).
- **Non** viene mai scritta su file.
- In modalità non interattiva, se manca la chiave il provider fallisce con errore esplicito.

Suggerimento:

```sh
export HUGGINGFACE_API_KEY="hf_..."
```

---

#### 4.1 Validazione attiva della chiave (Diagnostica)
Il modulo supporta la convalida proattiva della chiave tramite la funzione `validate_key_huggingface`:
- **Endpoint interrogato**: `https://huggingface.co/api/whoami-v2` (richiesta GET).
- **Meccanismo**: Il token viene trasmesso nell'header `Authorization: Bearer <token>`.
- **Esito**: Un codice di risposta HTTP `200` conferma che il token è valido e l'account è attivo (ritorna `0`). Un codice `401` indica che il token è invalido o scaduto (ritorna `1`). Eventuali problemi di connessione o timeout entro i 10 secondi restituiscono il codice d'errore di rete.

---

### 5. Comportamento runtime

#### 5.1 Selezione modello e Fallback automatico

Quando usi:

```sh
./bash4llm --provider huggingface --model <nome-modello> "prompt"
```

il provider:

1. Cerca `<nome-modello>` in `hf_endpoints`.
2. Se lo trova, recupera l’`endpoint_url` associato (es. un endpoint dedicato o il router).
3. Se **non** lo trova (ma la validazione del core lo consente), esegue un **fallback automatico** verso il Serverless Router unificato all'indirizzo `https://router.huggingface.co/v1/chat/completions`.
4. Compila il payload JSON (in formato standard OpenAI Chat Completions o legacy in base all'endpoint) ed esegue una chiamata `POST` tramite `curl`.

#### 5.2 Nessun fallback legacy “magico”

- **Non** viene usato in alcun caso il vecchio dominio deprecato `https://api-inference.huggingface.co/models/<id>`.
- **Non** viene usato il vecchio endpoint `/pipeline/text-generation`.
- Nessun tentativo di correzione automatica o parsing empirico del model id.

Se l’endpoint restituisce un errore HTTP, Bash4LLM:

- logga i dettagli utili all'ispezione (come intestazioni ed eventuali errori HTML troncati) in modalità debug,
- scrive un JSON strutturato di errore in `RESP`,
- ritorna un codice di errore coerente (`BASH4LLMERRAPI`).

---

### 6. `--list-models` e `--refresh-models`

Per Hugging Face, in linea con l’architettura:

- **`--list-models`**  
  Mostra i modelli locali registrati in `hf_endpoints`.

  Esempio output:

  ```text
  google/gemma-2-2b-it
  Qwen/Qwen2.5-7B-Instruct
  ```

- **`--refresh-models`**  
  Non interroga il Hub esterno di Hugging Face per evitare latenze o dipendenze non necessarie. Esegue una rilettura pulita e una sincronizzazione locale delle chiavi di `hf_endpoints` aggiornando la whitelist locale dei modelli.

---

### 7. Limitazioni note

- Gli URL associati all'host deprecato `api-inference.huggingface.co` **non sono supportati** e restituiscono errori DNS (`Could not resolve host`) o codici di errore HTTP.
- Lo streaming progressivo (`--stream`) è nativamente supportato per tutte le chiamate effettuate tramite il Serverless Router unificato (`router.huggingface.co`). Per gli endpoint dedicati privati, lo streaming in tempo reale è subordinato alla presenza di un container compatibile con la generazione di eventi standard SSE (Server-Sent Events).
- Alcuni modelli contrassegnati come *Gated* (es. Llama 3.2) richiedono di autenticarsi su Hugging Face e accettare esplicitamente le condizioni d'uso prima di poter essere interrogati con successo tramite il Token API.

---

### 8. Esempi d’uso

#### 8.1 Configurazione minima

```sh
mkdir -p bash4llm.d/config/providers

cat > bash4llm.d/config/providers/hf_endpoints <<'EOF'
google/gemma-2-2b-it|https://router.huggingface.co/v1/chat/completions
EOF

export HUGGINGFACE_API_KEY="hf_..."
```

#### 8.2 Chiamata semplice

```sh
./bash4llm --provider huggingface --model google/gemma-2-2b-it "Ciao, spiegami Bash4LLM in poche righe."
```

#### 8.3 Chiamata con sessione (Mantenimento della memoria)

```sh
./bash4llm --session test-conver "Mi chiamo Cristian."
./bash4llm --session test-conver "Come mi chiamo?"
```
