[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](../../README.md)

**[vedi Contratto Provider - see Provider Contract](../../PROVIDERS.md)**

## Provider Hugging Face (`huggingface.sh`)

Questo provider integra Hugging Face in Bash4LLM **solo** tramite **Inference Endpoint dedicati** configurati localmente.  
Nessuna discovery remota, nessun uso di `/api/models` o `/models/<id>`.

---

### 1. Principi chiave

- **Modelli disponibili**: solo quelli mappati localmente in un file di configurazione.
- **Endpoint supportati**: esclusivamente URL di **Inference Endpoint dedicati**  
  (tipicamente `https://<id>.<region>.endpoints.huggingface.cloud`).
- **API key**: letta da variabile d’ambiente, **mai salvata su disco**.
- **Nessuna chiamata al Hub** per elenchi modelli o validazione.

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
llama-3.1-8b-instruct|https://abc1234.eu-west-1.aws.endpoints.huggingface.cloud
mistral-7b|https://xyz9876.us-east-1.aws.endpoints.huggingface.cloud
```

Regole:

- Una riga per modello.
- Separatore: `|` (pipe).
- `endpoint_url` **deve** essere un Inference Endpoint dedicato, non `api-inference.huggingface.co/models/...`.

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

hf_add_endpoint "llama-3.1-8b-instruct" "https://abc1234.eu-west-1.aws.endpoints.huggingface.cloud"
hf_list_endpoints
hf_remove_endpoint "llama-3.1-8b-instruct"
```

---

> [!TIP]
> **File hf_endpoints pregenerato**
> 
> Ecco una selezione di modelli di testo e > conversazionali attivi sul serverless Hugging Face, suddivisi tra modelli ad accesso libero e modelli gated (che richiedono l'accettazione preliminare delle condizioni d'uso sul portale Hugging Face). 
> 
> Crea o sostituisci il contenuto del file > bash4llm.d/config/providers/hf_endpoints > con le seguenti righe:
> 
```text
# Modelli Liberi (Accesso immediato con qualsiasi Token HF valido)
gemma-2-2b-it|https://router.huggingface.co/hf-inference/models/google/gemma-2-2b-it
mistral-7b-instruct-v0.3|https://router.huggingface.co/hf-inference/models/mistralai/Mistral-7B-Instruct-v0.3
qwen-2.5-7b-instruct|https://router.huggingface.co/hf-inference/models/Qwen/Qwen2.5-7B-Instruct
qwen-2.5-coder-7b-instruct|https://router.huggingface.co/hf-inference/models/Qwen/Qwen2.5-Coder-7B-Instruct
phi-3-mini-4k-instruct|https://router.huggingface.co/hf-inference/models/microsoft/Phi-3-mini-4k-instruct
phi-3.5-mini-instruct|https://router.huggingface.co/hf-inference/models/microsoft/Phi-3.5-mini-instruct
smollm2-1.7b-instruct|https://router.huggingface.co/hf-inference/models/HuggingFaceTB/smollm2-1.7b-instruct
deepseek-r1-distill-qwen-1.5b|https://router.huggingface.co/hf-inference/models/deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B

# Modelli Gated (Richiedono l'accettazione dei termini d'uso su huggingface.co prima dell'uso)
llama-3.2-1b-instruct|https://router.huggingface.co/hf-inference/models/meta-llama/Llama-3.2-1B-Instruct
llama-3.2-3b-instruct|https://router.huggingface.co/hf-inference/models/meta-llama/Llama-3.2-3B-Instruct
```

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

### 5. Comportamento runtime

#### 5.1 Selezione modello

Quando usi:

```sh
./bash4llm --provider huggingface --model <nome-modello> "prompt"
```

il provider:

1. Cerca `<nome-modello>` in `hf_endpoints`.
2. Recupera l’`endpoint_url` associato.
3. Esegue una `POST` JSON verso quell’URL con il payload costruito da Bash4LLM.

Se il modello non è presente in `hf_endpoints`, la validazione fallisce (o il core può rifiutare il modello).

#### 5.2 Nessun fallback “magico”

- **Non** viene più usato `https://api-inference.huggingface.co/models/<id>`.
- **Non** viene più usato `/pipeline/text-generation`.
- Nessun tentativo di discovery o correzione automatica del model id.

Se l’endpoint restituisce `404` o altro errore, Bash4LLM:

- logga header, corpo (troncato) e stderr di `curl` in debug,
- scrive un JSON di errore in `RESP`,
- ritorna un codice di errore coerente (`BASH4LLMERRAPI`).

---

### 6. `--list-models` e `--refresh-models`

Per Hugging Face, in linea con l’architettura:

- **`--list-models`**  
  Deve mostrare solo i modelli presenti in `hf_endpoints`.

  Esempio output atteso:

  ```text
  huggingface:
    - llama-3.1-8b-instruct
    - mistral-7b
  ```

- **`--refresh-models`**  
  Non interroga il Hub.  
  Per Hugging Face può essere implementato come semplice rilettura di `hf_endpoints` o no-op controllato.

Qualsiasi logica precedente che chiamava `https://huggingface.co/api/models` va considerata **deprecata** e rimossa per questo provider.

---

### 7. Limitazioni note

- Gli URL tipo `https://api-inference.huggingface.co/models/gpt2` **non sono supportati** in questa architettura e possono restituire `404` anche con token valido.
- È responsabilità dell’utente creare e configurare gli Inference Endpoint dedicati sul sito Hugging Face e incollarne l’URL in `hf_endpoints`.
- Lo streaming (`call_api_streaming_huggingface`) funziona solo se l’endpoint dedicato restituisce eventi compatibili (chunk `data:` stile SSE/JSON). In caso contrario, l’output potrebbe non essere streamabile.

---

### 8. Esempi d’uso

#### 8.1 Configurazione minima

```sh
mkdir -p bash4llm.d/config/providers

cat > bash4llm.d/config/providers/hf_endpoints <<'EOF'
llama-3.1-8b-instruct|https://abc1234.eu-west-1.aws.endpoints.huggingface.cloud
EOF

export HUGGINGFACE_API_KEY="hf_..."
```

#### 8.2 Chiamata semplice

```sh
./bash4llm --provider huggingface --model llama-3.1-8b-instruct "Ciao, spiegami Bash4LLM in poche righe."
```

Se l’endpoint è corretto e il token ha permessi di inference sull’endpoint, otterrai una risposta JSON valida.

---

In sintesi: il provider `huggingface.sh` è progettato per essere **deterministico, auditabile e sicuro**, basato solo su **endpoint dedicati configurati localmente** e su una **API key in ambiente**, senza alcuna dipendenza da discovery remota o API “magiche” del Hub.
