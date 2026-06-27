[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![ShellCheck](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml)

# Bash4LLM⁺ 🇮🇹 [🇬🇧](README-en.md)

**Bash4LLM⁺** — wrapper CLI sicuro, Bash‑first e completamente auditabile per l’API Chat Completions compatibile OpenAI di Groq (ed estendibile ad altri provider).

Bash4LLM⁺ è un singolo script Bash, auto‑contenuto, leggibile e verificabile.  
Scaricalo, rendilo eseguibile, esporta la tua API key e inizia subito a usarlo.

Compatibile con ambienti Unix‑like: Linux, macOS, WSL, Cygwin, Termux (Android), BSD.

---

## Caratteristiche principali

- **Lista modelli dinamica**  
  tramite `GET https://api.groq.com/openai/v1/models`  
  → nessun modello hardcoded.

- **Sicurezza by design**  
  → nessun uso di `/tmp`, nessun `eval`, permessi restrittivi, validazione provider avanzata.

- **Struttura modulare a sezioni**  
  → PRECORE_BOOT, PRECORE_RUN, PROVIDER, CORE_SETUP, CORE_PROVIDER.
  
- **Sistema di Stato UI (ui_state)**  
  → il CORE espone costantemente metadati in formato JSON atomico per l'integrazione con GUI o strumenti esterni (es. Home Assistant).

- **Streaming e non‑streaming**  
  → output in tempo reale o completo a fine risposta.

- **Salvataggio automatico**  
  → per output lunghi oltre una soglia configurabile.

- **Gestione modelli avanzata**  
  → refresh, lista, default persistente, whitelist dinamica, auto‑selezione.

- **Extras opzionali**  
  → provider aggiuntivi (come Gemini, Hugging Face, Mistral), template, documentazione, strumenti di sicurezza.

- **Pronto per Termux / Android**  
  → rileva automaticamente l'ambiente Termux bypassando `flock` (spesso instabile o limitato a livello kernel/SELinux su Android) e devia trasparentemente la gestione della concorrenza sul robusto meccanismo di directory lock (`mkdir` atomico).

---

## Modello di minaccia (versione breve)

Bash4LLM⁺ è progettato per ambienti single‑user (PC/laptop, server personali).

- I provider sono codice eseguito nella tua shell: devono risiedere in directory sicure di tua proprietà.  
- Variabili come `BASH4LLM_EXTRAS_DIR` e `BASH4LLM_TMPDIR` sono considerate configurazione fidata.  
- Lo script non esegue mai l’output del modello.  
- I rischi TOCTOU e i limiti del parsing JSON/SSE sono mitigati e documentati.

Dettagli completi in **[SECURITY](SECURITY.md)**.

---

## Requisiti

Bash4LLM⁺ richiede che i seguenti pacchetti (o equivalenti) siano disponibili nel PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

---

## Installazione

> [!TIP]
> **⏩ FAST FORWARD (Installazione Rapida)**
> 
> Esegui questi comandi nel tuo terminale per avviare subito **Bash4LLM⁺**:
> 
> ```sh
> # 1. Clona il repository (solo l'ultimo commit per massima velocità)
> git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  
> 
> # 2. Crea una cartella di lavoro ed estrai l'eseguibile
> mkdir -p bash4llm
> cp repo-bash4llm/bin/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
> 
> # 3. Entra nella cartella e aggiorna i modelli 
> cd bash4llm 
> ./bash4llm --refresh-models
> ```
> 
> Lo script ti chiederà l'inserimento della chiave API:
> `Enter API key for provider groq (env GROQ_API_KEY):`
> 
> Inserisci la tua API key, poi esportala per non doverla più inserire durante la sessione:
> 
> `export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`
> 
> Consigliato: ***installa gli Extras opzionali***:
> ```sh
> # 4. Installazione degli Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Usa Bash4llm ⚡
> 

Istruzioni dettagliate in: **[INSTALL](INSTALL.md)**

In breve:

```sh
chmod +x bash4llm
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
./bash4llm --help
```

Extras opzionali:

```sh
./bash4llm --install-extras
```

Con opzioni:

- `--source <dir>`  
- `--force`  
- `--dry-run`  
- installazione selettiva:  
  `./bash4llm --install-extras provider1 templateA`

---

## Uso rapido

Prompt diretto:

```sh
./bash4llm "scrivi una breve poesia in italiano"
```

Prompt multilinea:

```sh
./bash4llm <<'EOF'
scrivi una breve poesia
in italiano
EOF
```

Input da file:

```sh
./bash4llm -f prompt.txt
```

Pipe:

```sh
echo "spiegami la relatività" | ./bash4llm
```

Modello specifico:

```sh
./bash4llm -m llama-3.3-70b-versatile "scrivi un saggio breve"
```

Dry run:

```sh
./bash4llm --dry-run "ciao"
```

Provider esterno (se installato):

```sh
./bash4llm --provider gemini "traduci questo"
```

---

## Comandi, flag e opzioni disponibili  

### Modelli e provider
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--refresh-models`, `--refresh-model` | no | Aggiorna la lista modelli (richiede API key). |
| `--list-models` | no | Stampa lista modelli (formato interattivo). |
| `--list-models-raw` | no | Stampa lista modelli in formato raw (una riga per modello). |
| `--list-providers` | no | Stampa lista provider. |
| `--list-providers-raw` | no | Stampa provider in formato raw. |
| `--set-default <model>` | sì | Imposta modello di default persistente per il provider attivo. |
| `-m <model>`, `--model <model>` | sì | Imposta modello per questa esecuzione. |
| `--provider <name>` | sì | Imposta provider da CLI. |
| `--provider` | no | Se senza argomento → apre selezione interattiva. |


### Input (file, JSON, template, batch)
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `-f <file>` | sì | Aggiunge file a `FILE_INPUTS`. |
| `--json-input <json>` | sì | Imposta input JSON (formato OpenAI-like). |
| `--template <name>` | sì | Applica template da `BASH4LLM_TEMPLATES_DIR`. |
| `--batch <file>` | sì | Esegue richieste batch (una riga = un prompt). |


### Sessioni
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--session <id>` | sì | Abilita sessione con ID specifico. |
| `--session-window [n]` | opzionale | Imposta finestra sessione (default 10 se non fornito). |


### Parametri modello / generazione
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--system <text>` | sì | Imposta system prompt. |
| `--ture <n>` | sì | Imposta parametro temperatura (da 0.0 a 2.0, alias canonico). |
| `--temperature <n>` | sì | Alias di `--ture`. |
| `--max <n>` | sì | Imposta max token. |


### Output e salvataggio
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--save` | no | Forza salvataggio output. |
| `--nosave` | no | Disabilita salvataggio. |
| `--out <path>` | sì | Percorso file/directory output. |
| `--threshold <n>` | sì | Soglia dimensione in byte per salvataggio automatico (default: 1000). |
| `--json` | no | Output JSON raw integro. |
| `--pretty` | no | Output JSON formattato. |
| `--text` | no | Output testuale standard estratto (comportamento predefinito). |
| `--raw` | no | Output testuale grezzo escludendo separazioni finali. |


### Modalità operative
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--dry-run` | no | Nessuna chiamata API reale (comportamento simulato). |
| `--quiet` | no | Riduce l'output non necessario e sopprime i titoli su TTY. |
| `--stream` | no | Streaming asincrono attivo. |
| `--no-stream` | no | Disattiva streaming asincrono. |
| `--chat` | no | Modalità chat interattiva REPL. |
| `--bootstrap-only` | no | Esegue solo validazione percorsi/lock e termina. |


### Configurazione e diagnostica
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--show-config` | no | Mostra configurazione completa attiva. |
| `--diagnostics` | no | Esegue diagnostica completa del sistema. |
| `--version` | no | Stampa versione dello script e termina. |
| `-h`, `--help` | no | Mostra help interattivo formattato da file. |


### Installazione extras
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--install-extras` | opzionale | Installa extras; può accettare directory sorgente. |
| `--install-extras=<dir>` | sì | Installa extras da directory sorgente specifica. |


### Terminazione parsing
| Flag | Effetto |
|------|---------|
| `--` | Termina parsing opzioni. |
| `-*` | Opzione sconosciuta → errore. |
| `*` | Argomento posizionale → aggiunto a `ARGS`. |


---

## Configurazione e modelli

### File di configurazione

- `$BASH4LLM_CONFIG_DIR/config`  
  → parametri locali (MODEL, TURE, MAX_TOKENS, FORMAT, THRESHOLD)

- `$BASH4LLM_CONFIG_DIR/model.$PROVIDER`  
  → modello predefinito per provider

- `$MODELS_FILE`  
  → whitelist modelli aggiornata da `--refresh-models`

### Precedenza selezione modello

1. `-m/--model`  
2. `model.$PROVIDER`  
3. auto‑selezione provider (`auto_select_model_<provider>`)
4. prima voce della whitelist (`models.txt`)
5. configurazione globale legacy `config` (`MODEL=...`)

---

## File temporanei e output

- Nessun uso di `/tmp` a livello di sistema operativo condiviso.  
- File temporanei isolati in directory `$RUN_TMPDIR` con permessi `700` (`umask 077`).  
- File salvati con permessi `600`.  
- Con `--out` Bash4LLM⁺ crea la directory se possibile.

---

# 📁 Sistema di Stato UI (ui_state)

Bash4LLM⁺ espone metadati operativi destinati a GUI/strumenti esterni tramite file JSON atomici in:

```
$BASH4LLM_CONFIG_DIR/ui_state
```

Contiene:

- `sessions/<id>.json` → stato sessione (active, msg_count, last_ts)  
- `sessions/index.json` → elenco sessioni  
- `last_api.json` → ultimo risultato API (http_status, req_id, edgecase_detected, ecc.)  
- `last_history.json` → ultimo salvataggio history  
- `provider_capabilities.json` → capacità provider attivo (streaming, refresh_models)  

La GUI (extra opzionale) legge **solo** questi file per i placeholder CGI.

---

# 📘 Memoria contestuale in Bash4LLM⁺

Bash4LLM⁺ **non mantiene memoria da solo**.  
La memoria esiste **solo se attivi una sessione** tramite `--session`.

Ogni sessione crea un file NDJSON persistente:

```
$BASH4LLM_HISTORY_DIR/sessions/<session_id>.ndjson
```

E Bash4LLM⁺ mantiene i metadati della sessione in:

```
$BASH4LLM_CONFIG_DIR/ui_state/sessions/<session_id>.json
```

Questi metadati sono la fonte canonica per GUI/strumenti esterni.

---

### 🟩 Uso corretto di `--session`

```sh
./bash4llm --session chat1 "Ciao"
./bash4llm --session chat1 "Riassumi ciò che ho detto"
```

### 🟩 Uso corretto di `--session-window`

```sh
./bash4llm --session chat1 --session-window 10 "continua"
```

### 🟧 Regola fondamentale

Per avere memoria contestuale **devi sempre** includere `--session <id>`.

---

## Note di sicurezza

- Nessun `eval`.  
- Nessuna esecuzione dell’output del modello.  
- Provider = codice: mantieni `extras/providers` sicuro.  
- Variabili d’ambiente = configurazione fidata.  
- TOCTOU mitigato.

---

## Codici di uscita

| Codice | Variabile | Significato |
|:---:|:---|:---|
| **0** | - | Successo |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | API key mancante |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Modello non valido o non in whitelist |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Errore rete/curl |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | Nessun prompt fornito |
| **15** | `BASH4LLM_ERR_TMP` | Errore generico filesystem / temporanei |
| **16** | `BASH4LLM_ERR_API` | Errore HTTP/API del fornitore |

---

## Variabili principali  

| Variabile | Necessaria | Descrizione |
|-----------|------------|-------------|
| `GROQ_API_KEY` | sì per chiamate API | API key provider Groq. |
| `BASH4LLM_CONFIG_DIR` | consigliata | Directory configurazione. |
| `BASH4LLM_MODELS_DIR` | consigliata | Directory modelli. |
| `BASH4LLM_TMPDIR` | sì | Directory temporanea. |
| `BASH4LLM_HISTORY_DIR` | consigliata | Directory sessioni e cronologia. |
| `MODEL` | no | Modello attivo. |
| `PROVIDER` | no | Provider attivo. |
| `ALLOWED_MODELS` | no | Whitelist modelli ammessi. |

---

## Licenza

Bash4LLM⁺ è distribuito sotto licenza GPL v3.  
Vedi `LICENSE`.

---

## Contatti

Autore: Cristian Evangelisti  
Email: opensource​@​cevangel.​anonaddy.​me  
Repository: https://github.com/kamaludu/bash4llm
