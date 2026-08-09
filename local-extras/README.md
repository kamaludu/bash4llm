# Bash4LLM⁺ — Local Extras Domain Specification

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
