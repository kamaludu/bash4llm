[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![ShellCheck](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml)

# GroqBash⁺ 🇮🇹 [🇬🇧](README-en.md)

**GroqBash⁺** — wrapper CLI sicuro, Bash‑first e completamente auditabile per l’API Chat Completions compatibile OpenAI di Groq.

GroqBash è un singolo script Bash, auto‑contenuto, leggibile e verificabile.  
Scaricalo, rendilo eseguibile, esporta la tua API key e inizia subito a usarlo.

Compatibile con ambienti Unix‑like: Linux, macOS, WSL, Cygwin, Termux, BSD.

---

## Caratteristiche principali

- **Lista modelli dinamica**  
  tramite `GET https://api.groq.com/openai/v1/models`  
  → nessun modello hardcoded.

- **Sicurezza by design**  
  → nessun uso di `/tmp`, nessun `eval`, permessi restrittivi, validazione provider avanzata.

- **Struttura modulare a sezioni**  
  → PRECORE_BOOT, PRECORE_RUN, PROVIDER, CORE_SETUP, CORE_PROVIDER .
  
- **Sistema di Stato UI (ui_state)**  
  → il CORE espone metadati per GUI/strumenti esterni tramite file JSON atomici.

- **Streaming e non‑streaming**  
  → output in tempo reale o completo a fine risposta.

- **Salvataggio automatico**  
  → per output lunghi oltre una soglia configurabile.

- **Gestione modelli avanzata**  
  → refresh, lista, default persistente, whitelist dinamica, auto‑selezione.

- **Extras opzionali**  
  → provider aggiuntivi, template, documentazione, strumenti di sicurezza.

---

## Modello di minaccia (versione breve)

GroqBash è progettato per ambienti single‑user (PC/laptop, server personali).

- I provider sono codice eseguito nella tua shell: devono risiedere in directory sicure.  
- Variabili come `GROQBASH_EXTRAS_DIR` e `GROQBASH_TMPDIR` sono considerate configurazione fidata.  
- Lo script non esegue mai l’output del modello.  
- I rischi TOCTOU e i limiti del parsing JSON/SSE sono mitigati e documentati.

Dettagli completi in **[SECURITY](SECURITY.md)**.

---

## Requisiti

GroqBash richiede che i seguenti pacchetti (o equivalenti) siano disponibili nel PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

---

## Installazione

Istruzioni dettagliate in: **[INSTALL](INSTALL.md)**

In breve:

```sh
chmod +x groqbash
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
./groqbash --help
```

Extras opzionali:

```sh
./groqbash --install-extras
```

Con opzioni:

- `--source <dir>`  
- `--force`  
- `--dry-run`  
- installazione selettiva:  
  `./groqbash --install-extras provider1 templateA`

---

## Uso rapido

Prompt diretto:

```sh
./groqbash "scrivi una breve poesia in italiano"
```

Prompt multilinea:

```sh
./groqbash <<'EOF'
scrivi una breve poesia
in italiano
EOF
```

Input da file:

```sh
./groqbash -f prompt.txt
```

Pipe:

```sh
echo "spiegami la relatività" | ./groqbash
```

Modello specifico:

```sh
./groqbash -m llama-3.3-70b-versatile "scrivi un saggio breve"
```

Dry run:

```sh
./groqbash --dry-run "ciao"
```

Provider esterno (se installato):

```sh
./groqbash --provider gemini "traduci questo"
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
| `--set-default <model>` | sì | Imposta modello di default persistente. |
| `-m <model>`, `--model <model>` | sì | Imposta modello per questa esecuzione. |
| `--provider <name>` | sì | Imposta provider da CLI. |
| `--provider` | no | Se senza argomento → apre selezione interattiva. |


### Input (file, JSON, template, batch)
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `-f <file>` | sì | Aggiunge file a `FILE_INPUTS`. |
| `--json-input <json>` | sì | Imposta input JSON. |
| `--template <name>` | sì | Applica template da `GROQBASH_TEMPLATES_DIR`. |
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
| `--ture <n>` | sì | Imposta temperatura (alias interno). |
| `--temperature <n>` | sì | Alias di `--ture`. |
| `--max <n>` | sì | Imposta max token. |


### Output e salvataggio
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--save` | no | Forza salvataggio output. |
| `--nosave` | no | Disabilita salvataggio. |
| `--out <path>` | sì | Percorso file/directory output. |
| `--threshold <n>` | sì | Soglia dimensione per salvataggio. |
| `--json` | no | Output JSON. |
| `--pretty` | no | Output JSON formattato. |
| `--text` | no | Output testuale. |
| `--raw` | no | Output grezzo. |


### Modalità operative
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--dry-run` | no | Nessuna chiamata API. |
| `--quiet` | no | Riduce output. |
| `--stream` | no | Streaming attivo. |
| `--no-stream` | no | Disattiva streaming. |
| `--chat` | no | Modalità chat interattiva. |
| `--bootstrap-only` | no | Esegue solo bootstrap e termina. |


### Configurazione e diagnostica
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--show-config` | no | Mostra configurazione completa. |
| `--diagnostics` | no | Esegue diagnostica completa. |
| `--version` | no | Stampa versione e termina. |
| `-h`, `--help` | no | Mostra help da file. |


### Installazione extras
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--install-extras` | opzionale | Installa extras; può accettare directory. |
| `--install-extras=<dir>` | sì | Installa extras da directory specifica. |


### Terminazione parsing
| Flag | Effetto |
|------|---------|
| `--` | Termina parsing opzioni. |
| `-*` | Opzione sconosciuta → errore. |
| `*` | Argomento posizionale → aggiunto a `ARGS`. |


---

## Configurazione e modelli

### File di configurazione

- `$GROQBASH_CONFIG_DIR/config`  
  → parametri locali (MODEL, TURE, MAX_TOKENS, FORMAT, THRESHOLD)

- `$GROQBASH_CONFIG_DIR/model.$PROVIDER`  
  → modello predefinito per provider

- `$MODELS_FILE`  
  → whitelist modelli aggiornata da `--refresh-models`

### Precedenza selezione modello

1. `-m/--model`  
2. `model.$PROVIDER`  
3. `config`  
4. auto‑selezione provider  
5. prima voce della whitelist

---

## File temporanei e output

- Nessun uso di `/tmp`.  
- Temporanei in directory dedicata con permessi 700.  
- File salvati con permessi 600.  
- Con `--out` GroqBash crea la directory se possibile.

---

# 📁 Sistema di Stato UI (ui_state)

GroqBash espone metadati operativi destinati a GUI/strumenti esterni tramite file JSON atomici in:

```
$GROQBASH_CONFIG_DIR/ui_state
```

Contiene:

- `sessions/<id>.json` → stato sessione (active, msg_count, last_ts)  
- `sessions/index.json` → elenco sessioni  
- `last_api.json` → ultimo risultato API  
- `last_history.json` → ultimo salvataggio history  
- `provider_capabilities.json` → capacità provider attivo  

La GUI (extra opzionale) legge **solo** questi file per i placeholder CGI (20–23).  
La semantica dei placeholder è definita nella *Fonte di Verità Unificata dei Placeholder (GUI + CGI)*.

---

# 📘 Memoria contestuale in GroqBash

GroqBash **non mantiene memoria da solo**.  
La memoria esiste **solo se attivi una sessione** tramite `--session`.

Ogni sessione crea un file NDJSON persistente:

```
$GROQBASH_HISTORY_DIR/sessions/<session_id>.ndjson
```

E GroqBash mantiene metadati della sessione in:

```
$GROQBASH_CONFIG_DIR/ui_state/sessions/<session_id>.json
```

Questi metadati sono la fonte canonica per GUI/strumenti esterni.

---

### 🟩 Uso corretto di `--session`

```sh
./groqbash --session chat1 "Ciao"
./groqbash --session chat1 "Riassumi ciò che ho detto"
```

### 🟩 Uso corretto di `--session-window`

```sh
./groqbash --session chat1 --session-window 10 "continua"
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

| Codice | Significato |
|--------|-------------|
| 0 | Successo |
| `GROQBASHERRTMP` | Errore generico / temporanei |
| `GROQBASHERRCURL_FAILED` | Errore rete/curl |
| `GROQBASHERRAPI` | Errore HTTP/API |
| `GROQBASHERRBAD_MODEL` | Modello non valido |
| `GROQBASHERRNO_PROMPT` | Nessun prompt fornito |
| `GROQBASHERRNOAPIKEY` | API key mancante |
| `GROQBASHERRINSTALL` | Errore installer extras |

---

## Variabili principali  

| Variabile | Necessaria | Descrizione |
|-----------|------------|-------------|
| `GROQ_API_KEY` | sì per chiamate API | API key provider. |
| `GROQBASH_CONFIG_DIR` | consigliata | Directory configurazione. |
| `GROQBASH_MODELS_DIR` | consigliata | Directory modelli. |
| `GROQBASH_TMPDIR` | sì | Directory temporanea. |
| `GROQBASH_HISTORY_DIR` | consigliata | Directory sessioni. |
| `MODEL` | no | Modello attivo. |
| `PROVIDER` | no | Provider attivo. |
| `ALLOWED_MODELS` | no | Whitelist modelli. |

---

## Licenza

GroqBash è distribuito sotto licenza GPL v3.  
Vedi `LICENSE`.

---

## Contatti

Autore: Cristian Evangelisti  
Email: opensource​@​cevangel.​anonaddy.​me  
Repository: https://github.com/kamaludu/groqbash
