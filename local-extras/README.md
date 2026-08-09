[![Logo 320](../docs/img/bash4llm320.png "Logo bash4llm")](../README.md)
# Bash4LLM⁺ — Local Extras Domain Specification
## [🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)

---

## 🇮🇹 Sezione italiana 

## 1. Introduzione e Finalità

La directory `local-extras/` definisce il **Dominio Utente Isolato** (*Local Trust Domain*) di Bash4LLM⁺.

È progettata per consentire a utenti, sviluppatori e amministratori di sistema di estendere le funzionalità di `bash4llm` (ad esempio aggiungendo provider LLM personalizzati, gateway aziendali o server locali come Ollama, LocalAI o vLLM) **senza alterare i moduli ufficiali del repository** e **senza interferire con il manifest di integrità crittografica**.

---

## 2. Distinzione tra Repository e Runtime

È fondamentale distinguere tra la directory nel controllo versione e la directory attiva a runtime:

- **Repository (`./local-extras/`)**:
  Rappresenta la directory presente nel sorgente Git.
  - Contiene il file segnaposto `./local-extras/providers/.gitkeep` per preservare la struttura vuota nel tracciamento del repository.
  - Il file `.gitkeep` è un mero segnaposto tecnico: **può essere liberamente ignorato o eliminato** quando si aggiungono i propri moduli.
- **Runtime (`$BASH4LLM_DIR/local-extras/`)**:
  Di default corrisponde a `./bash4llm.d/local-extras/` (o `~/.bash4llm.d/local-extras/`). È la **directory effettivamente letta da `bash4llm` durante l'esecuzione del programma**.

---

## 3. Gestione Interna e Ciclo di Vita (`bash4llm`)

### A. Mappatura dei Percorsi
All'avvio, `bash4llm` assegna le seguenti costanti di percorso:
- `CANONICAL_LOCAL_EXTRAS_DIR="${BASH4LLM_DIR}/local-extras"`
- `LOCAL_PROVIDERS_DIR="${BASH4LLM_LOCAL_EXTRAS_DIR}/providers"`

Il programma assicura automaticamente la presenza della directory di runtime isolata applicando permessi POSIX restrittivi (`chmod 700`):
```text
$BASH4LLM_DIR/
└── local-extras/
    └── providers/       # Directory attiva per i provider locali (<nome>.sh)
```

---

### B. Modello di Sicurezza (Bypass Manifest e Controlli POSIX)

In `bash4llm`, i moduli in `local-extras/` appartengono al dominio `local`. La funzione `verify_module_integrity()` applica la seguente politica:

1. **Bypass del Manifest Ufficiale (`extras/manifest.sha256`)**:
   Lo script `generate-manifest.sh` scansiona unicamente la directory sorgente `extras/`. I file contenuti in `local-extras/` **non vengono inclusi nel `manifest.sha256` ufficiale** e non richiedono firma crittografica Ed25519.
2. **Validazione di Sicurezza POSIX (`validate_path_security()`)**:
   Prima dell'importazione di un modulo da `local-extras/providers/`, `bash4llm` esegue una rigorosa verifica di sicurezza sul filesystem:
   - **Rifiuto dei Collegamenti Simbolici (`[ -L "$target_file" ]`)**: Se il modulo è un symlink, l'esecuzione viene bloccata immediatamente con errore `BASH4LLM_ERR_SEC` (17) per prevenire attacchi di tipo TOCTOU o Directory Traversal.
   - **Controllo di Proprietà**: Il modulo e la sua directory padre devono appartenere all'utente che esegue lo script (`id -un`).
   - **Controllo Permessi di Scrittura**: Il modulo e la sua directory padre **non** devono avere il bit di scrittura abilitato per il gruppo o per altri utenti (`group_write` o `others_write`).

---

### C. Risoluzione dei Moduli, Precedenza e Shadowing

La funzione `_resolve_provider_module_path()` gestisce l'individuazione dei provider secondo le seguenti regole:

#### 1. Sintassi Esplicita (`local:<nome>`)
```sh
bash4llm --provider local:<nome>
```
Forza la risoluzione **esclusivamente** sul file `$LOCAL_PROVIDERS_DIR/<nome>.sh`. Se il file non esiste, l'esecuzione si interrompe con un errore esplicito senza effettuare ricerca nei provider ufficiali o builtin.

#### 2. Sintassi Implicita (`<nome>`)
```sh
bash4llm --provider <nome>
```
Applica l'ordine di precedenza di fallback:
```text
1. Vendor (extras/providers/<nome>.sh)
   └──► 2. Local ($BASH4LLM_DIR/local-extras/providers/<nome>.sh)
          └──► 3. Builtin (embedded groq)
```

#### 3. Avviso di Shadowing (Conflitto di Nomi)
Se esistono simultaneamente sia un modulo Vendor (`extras/providers/<nome>.sh`) sia un modulo Local (`local-extras/providers/<nome>.sh`) con lo stesso nome, `bash4llm` utilizza la versione Vendor ed emette un avviso esplicito su `stderr`:
> `WARN: PROVIDER: Local provider shadows vendor provider. Using vendor provider. Use '--provider local:<nome>' or '--provider vendor:<nome>' to disambiguate.`

#### 4. Elenco CLI (`--list-providers`)
Il comando `bash4llm --list-providers` rileva automaticamente i moduli presenti in `$LOCAL_PROVIDERS_DIR` e li stampa a schermo identificandoli col suffisso `(local)`:
```text
Available providers:
  - groq (builtin)
  - gemini (vendor)
  - ollama (local)
```

---

## 4. Contratto dell'Interfaccia dei Moduli

Ogni modulo in `local-extras/providers/<nome>.sh` viene caricato all'interno di una subshell isolata. Per essere valido, deve definire le seguenti **due funzioni obbligatorie**:

1. `buildpayload_<nome>()`: Costruisce la richiesta JSON, scrive il payload in un file temporaneo sicuro e ne assegna il percorso alla variabile esportata `PAYLOAD`.
2. `call_api_<nome>()`: Inoltra la richiesta HTTP verso l'endpoint prescelto.

### Funzioni Opzionali Supportate
Se definite, `bash4llm` le rileva ed esporta automaticamente:
- `call_api_streaming_<nome>()` — Gestione delle risposte in streaming SSE.
- `refresh_models_<nome>()` — Aggiornamento dinamico dei modelli disponibili.
- `validate_model_<nome>()` — Validazione personalizzata del nome del modello.
- `validate_key_<nome>()` — Validazione remota della chiave API.
- `auto_select_model_<nome>()` — Selezione automatica del modello di default.
- `normalize_model_<nome>()` — Normalizzazione del nome del modello.

---

## 5. Variabili e Helper Messi A Disposizione dal Core

Durante l'esecuzione delle funzioni del provider, `bash4llm` mette a disposizione l'ambiente di runtime:

- `RUN_TMPDIR`: Directory temporanea isolata della transazione corrente.
- `PAYLOAD`: Percorso del file JSON di payload inviato all'API.
- `RESP`: Percorso del file di risposta JSON (`$RUN_TMPDIR/resp.json`).
- `ERRF`: Percorso del file di log degli errori cURL (`$RUN_TMPDIR/err.log`).
- `MODEL`: Nome del modello selezionato per la richiesta.
- `CONTENT`: Testo del prompt fornito dall'utente.
- `BASH4LLM_PROVIDER_URL`: Endpoint URL eventualmente sovrascritto via configurazione.

### Helper di Rete Sicuro: `_exec_curl_secure`
La funzione interna `_exec_curl_secure` consente di eseguire chiamate HTTP nascondendo le chiavi API dall'elenco dei processi di sistema (`ps`):

```sh
_exec_curl_secure <METHOD> <URL> <API_KEY> <PAYLOAD_FILE> <OUT_FILE> <ERR_FILE> <IS_STREAMING>
```

---

## 6. Esempio Pratico: Provider Ollama Locale (`local-extras/providers/ollama.sh`)

Creare il file `$BASH4LLM_DIR/local-extras/providers/ollama.sh` (oppure `./local-extras/providers/ollama.sh` prima della sincronizzazione):

```sh
#!/usr/bin/env bash
# File: local-extras/providers/ollama.sh
# Provider locale per Ollama API

buildpayload_ollama() {
  local tmp_payload=""
  tmp_payload="$(_tmpf file "$RUN_TMPDIR" payload_ollama 2>/dev/null || printf '%s/payload.json' "$RUN_TMPDIR")"
  
  jq -n \
    --arg model "${MODEL:-llama3}" \
    --arg prompt "${CONTENT:-}" \
    '{model: $model, prompt: $prompt, stream: false}' > "$tmp_payload"

  PAYLOAD="$tmp_payload"
  export PAYLOAD
}

call_api_ollama() {
  local url="${BASH4LLM_PROVIDER_URL:-http://127.0.0.1:11434/api/generate}"
  
  # Chiamata HTTP sicura senza autenticazione API key (passata come riga vuota "")
  _exec_curl_secure "POST" "$url" "" "$PAYLOAD" "$RESP" "$ERRF" 0
}
```

### Esempio di Invocazione
```sh
bash4llm --provider local:ollama -m llama3 "Spiega lo standard POSIX in tre punti"
```

---

## 🇬🇧 English section

## 1. Introduction and Purpose

The `local-extras/` directory defines the **Isolated User Domain** (*Local Trust Domain*) of Bash4LLM⁺.

It is designed to allow users, developers, and system administrators to extend `bash4llm` functionality (for example by adding custom LLM providers, corporate gateways, or local servers like Ollama, LocalAI, or vLLM) **without altering official repository modules** and **without interfering with the cryptographic integrity manifest**.

---

## 2. Distinction Between Repository and Runtime

It is essential to distinguish between the directory in version control and the active directory at runtime:

- **Repository (`./local-extras/`)**:
  Represents the directory present in the Git source.
  - Contains the placeholder file `./local-extras/providers/.gitkeep` to preserve the empty structure in repository tracking.
  - The `.gitkeep` file is a mere technical placeholder: **it can be freely ignored or deleted** when adding custom modules.
- **Runtime (`$BASH4LLM_DIR/local-extras/`)**:
  By default corresponds to `./bash4llm.d/local-extras/` (or `~/.bash4llm.d/local-extras/`). It is the **directory actually read by `bash4llm` during program execution**.

---

## 3. Internal Management and Lifecycle (`bash4llm`)

### A. Path Mapping
At startup, `bash4llm` assigns the following path constants:
- `CANONICAL_LOCAL_EXTRAS_DIR="${BASH4LLM_DIR}/local-extras"`
- `LOCAL_PROVIDERS_DIR="${BASH4LLM_LOCAL_EXTRAS_DIR}/providers"`

The program automatically ensures the presence of the isolated runtime directory by applying restrictive POSIX permissions (`chmod 700`):
```text
$BASH4LLM_DIR/
└── local-extras/
    └── providers/       # Active directory for local providers (<nome>.sh)
```

---

### B. Security Model (Manifest Bypass and POSIX Checks)

In `bash4llm`, modules in `local-extras/` belong to the `local` domain. The `verify_module_integrity()` function applies the following policy:

1. **Official Manifest Bypass (`extras/manifest.sha256`)**:
   The `generate-manifest.sh` script scans only the `extras/` source directory. Files contained in `local-extras/` **are not included in the official `manifest.sha256`** and do not require Ed25519 cryptographic signature.
2. **POSIX Security Validation (`validate_path_security()`)**:
   Before importing a module from `local-extras/providers/`, `bash4llm` performs a rigorous security check on the filesystem:
   - **Rejection of Symbolic Links (`[ -L "$target_file" ]`)**: If the module is a symlink, execution is blocked immediately with error `BASH4LLM_ERR_SEC` (17) to prevent TOCTOU or Directory Traversal attacks.
   - **Ownership Check**: The module and its parent directory must belong to the user executing the script (`id -un`).
   - **Write Permission Check**: The module and its parent directory **must not** have the write bit set for the group or for other users (`group_write` or `others_write`).

---

### C. Module Resolution, Precedence, and Shadowing

The `_resolve_provider_module_path()` function handles provider resolution according to the following rules:

#### 1. Explicit Syntax (`local:<nome>`)
```bash
bash4llm --provider local:<nome>
```
Forces resolution **exclusively** on the file `$LOCAL_PROVIDERS_DIR/<nome>.sh`. If the file does not exist, execution terminates with an explicit error without searching official or builtin providers.

#### 2. Implicit Syntax (`<nome>`)
```bash
bash4llm --provider <nome>
```
Applies the fallback precedence order:
```text
1. Vendor (extras/providers/<nome>.sh)
   └──► 2. Local ($BASH4LLM_DIR/local-extras/providers/<nome>.sh)
          └──► 3. Builtin (embedded groq)
```

#### 3. Shadowing Warning (Name Conflict)
If both a Vendor module (`extras/providers/<nome>.sh`) and a Local module (`local-extras/providers/<nome>.sh`) exist simultaneously with the same name, `bash4llm` uses the Vendor version and emits an explicit warning on `stderr`:
> `WARN: PROVIDER: Local provider shadows vendor provider. Using vendor provider. Use '--provider local:<nome>' or '--provider vendor:<nome>' to disambiguate.`

#### 4. CLI Listing (`--list-providers`)
The `bash4llm --list-providers` command automatically detects modules present in `$LOCAL_PROVIDERS_DIR` and prints them on screen marked with the `(local)` suffix:
```text
Available providers:
  - groq (builtin)
  - gemini (vendor)
  - ollama (local)
```

---

## 4. Module Interface Contract

Every module in `local-extras/providers/<nome>.sh` is loaded within an isolated subshell. To be valid, it must define the following **two mandatory functions**:

1. `buildpayload_<nome>()`: Constructs the JSON request, writes the payload to a secure temporary file, and assigns its path to the exported `PAYLOAD` variable.
2. `call_api_<nome>()`: Forwards the HTTP request to the selected endpoint.

### Supported Optional Functions
If defined, `bash4llm` detects and exports them automatically:
- `call_api_streaming_<nome>()` — Handling of SSE streaming responses.
- `refresh_models_<nome>()` — Dynamic refresh of available models.
- `validate_model_<nome>()` — Custom validation of the model name.
- `validate_key_<nome>()` — Remote validation of the API key.
- `auto_select_model_<nome>()` — Automatic selection of default model.
- `normalize_model_<nome>()` — Normalization of the model name.

---

## 5. Variables and Helpers Provided by Core

During execution of provider functions, `bash4llm` provides the runtime environment:

- `RUN_TMPDIR`: Isolated temporary directory for the current transaction.
- `PAYLOAD`: Path to the JSON payload file sent to the API.
- `RESP`: Path to the JSON response file (`$RUN_TMPDIR/resp.json`).
- `ERRF`: Path to the cURL error log file (`$RUN_TMPDIR/err.log`).
- `MODEL`: Name of the model selected for the request.
- `CONTENT`: Prompt text provided by the user.
- `BASH4LLM_PROVIDER_URL`: Endpoint URL optionally overridden via configuration.

### Secure Network Helper: `_exec_curl_secure`
The internal `_exec_curl_secure` function enables executing HTTP calls while hiding API keys from the system process list (`ps`):

```bash
_exec_curl_secure <METHOD> <URL> <API_KEY> <PAYLOAD_FILE> <OUT_FILE> <ERR_FILE> <IS_STREAMING>
```

---

## 6. Practical Example: Local Ollama Provider (`local-extras/providers/ollama.sh`)

Create the file `$BASH4LLM_DIR/local-extras/providers/ollama.sh` (or `./local-extras/providers/ollama.sh` before synchronization):

```bash
#!/usr/bin/env bash
# File: local-extras/providers/ollama.sh
# Provider locale per Ollama API

buildpayload_ollama() {
  local tmp_payload=""
  tmp_payload="$(_tmpf file "$RUN_TMPDIR" payload_ollama 2>/dev/null || printf '%s/payload.json' "$RUN_TMPDIR")"
  
  jq -n \
    --arg model "${MODEL:-llama3}" \
    --arg prompt "${CONTENT:-}" \
    '{model: $model, prompt: $prompt, stream: false}' > "$tmp_payload"

  PAYLOAD="$tmp_payload"
  export PAYLOAD
}

call_api_ollama() {
  local url="${BASH4LLM_PROVIDER_URL:-http://127.0.0.1:11434/api/generate}"
  
  # Chiamata HTTP sicura senza autenticazione API key (passata come riga vuota "")
  _exec_curl_secure "POST" "$url" "" "$PAYLOAD" "$RESP" "$ERRF" 0
}
```

### Usage Example
```bash
bash4llm --provider local:ollama -m llama3 "Spiega lo standard POSIX in tre punti"
```
