[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![ShellCheck](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml)

# GroqBash⁺ 🇮🇹 [🇬🇧](README-en.md)

**GroqBash⁺** — wrapper CLI sicuro, Bash‑first e completamente auditabile per l’API Chat Completions compatibile OpenAI di Groq.

GroqBash è un singolo script Bash, auto‑contenuto, leggibile e verificabile.  
Scaricalo, rendilo eseguibile, esporta la tua API key e inizia subito a usarlo.

Compatibile con ambienti Unix‑like: Linux, macOS, WSL, Termux.

---

## Caratteristiche principali

- **Lista modelli dinamica**  
  tramite `GET https://api.groq.com/openai/v1/models`  
  → nessun modello hardcoded.

- **Sicurezza by design**  
  → nessun uso di `/tmp`, nessun `eval`, permessi restrittivi, validazione provider avanzata.

- **Struttura modulare a sezioni**  
  → PRECORE, PROVIDER, CORE, **Sistema di Stato UI**.

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

GroqBash è progettato per ambienti single‑user (laptop, Termux, shell personale).

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

Questi pacchetti forniscono tutti i comandi necessari:
`bash mv cp chmod stat find sort head wc tee date curl jq flock base64 mktemp readlink awk sed grep xargs sync sha256sum stdbuf`

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

## Opzioni principali

| Opzione | Descrizione |
|--------|-------------|
| `-m, --model <name>` | Seleziona il modello |
| `-f <file>` | Legge il prompt da file |
| `--system <text>` | Imposta il system prompt |
| `--ture <value>` / `--temperature <value>` | Temperature |
| `--max <n>` | Max tokens |
| `--refresh-models` | Aggiorna la lista modelli |
| `--list-models` | Mostra i modelli disponibili |
| `--set-default <model>` | Imposta modello predefinito |
| `--provider <name>` | Usa provider esterno |
| `--provider` | Selezione provider interattiva |
| `--install-extras` | Installa extras |
| `--json-input <file>` | Input JSON diretto |
| `--template <name>` | Usa template |
| `--batch <file>` | Esegue batch di prompt |
| `--stream` / `--no-stream` | Streaming on/off |
| `--json` / `--pretty` / `--raw` / `--text` | Formati output |
| `--save` / `--nosave` | Forza salvataggio o no |
| `--out <path>` | Percorso output |
| `--threshold <n>` | Soglia autosave |
| `--quiet` | Output minimale |
| `--debug` | Debug esteso |
| `--diagnostics` | Diagnostica completa |
| `--show-config` | Mostra configurazione |
| `--version` | Versione |
| `-h, --help` | Help |

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

La GUI legge **solo** questi file per i placeholder CGI (20–23).  
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

## Extras avanzati

Gli extras non modificano il core.

### Sicurezza

- provider aggiuntivi (**vedi: `[Sembra che non fosse sicuro mostrare il risultato. Cambiamo le cose e facciamo un altro tentativo.]`**)
- strumenti di verifica permessi, symlink, owner  
- template e documentazione

### Test

- suite JSON/SSE  
- test provider

---

## Note di sicurezza

- Nessun `eval`.  
- Nessuna esecuzione dell’output del modello.  
- Provider = codice: mantieni `extras/providers` sicuro.  
- Variabili d’ambiente = configurazione fidata.  
- Parsing JSON/SSE robusto ma non completo.  
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

## Licenza

GroqBash è distribuito sotto licenza GPL v3.  
Vedi `LICENSE`.

---

## Contatti

Autore: Cristian Evangelisti  
Email: opensource​@​cevangel.​anonaddy.​me  
Repository: https://github.com/kamaludu/groqbash
