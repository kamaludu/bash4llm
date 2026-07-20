[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)  
[![ShellCheck](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml)
[![Cross-Platform Tests](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml)
[![Bash Compatibility](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml)

# Bash4LLM⁺ 🇮🇹 [🇬🇧](README-en.md)

**Bash4LLM⁺** — Wrapper CLI sicuro, Bash-first, modulare e interamente controllabile per l'interfacciamento con API LLM compatibili con OpenAI (con provider Groq incorporato di serie ed estendibile ad altri tramite moduli esterni).

Bash4LLM⁺ è uno script singolo, auto-contenuto, leggibile e progettato per non avere dipendenze esterne al di fuori dei comandi POSIX standard e delle utilità di base della shell.

Funziona in modo nativo su: Linux, macOS, WSL, Cygwin, Termux (Android) e BSD.

---

## Caratteristiche principali

*   **Lista modelli dinamica ed esente da obsolescenza**  
    Ottenuta tramite interrogazione degli endpoint live (`GET /v1/models`). Nessun nome di modello è hardcoded all'interno del core script.
*   **Sicurezza e Sandboxing a livello di Filesystem**  
    Nessun uso di cartelle condivise globali come `/tmp`. File temporanei isolati tramite directory esclusive di processo (`RUN_TMPDIR`) con permessi restrittivi `700` (`umask 077`). Divieto assoluto dell'uso di `eval`.
*   **Cryptographic Vault incorporato (`--vault`)**  
    Integrazione opzionale basata su OpenSSL per conservare e gestire in modo sicuro le chiavi API sul filesystem. Le chiavi vengono cifrate con algoritmo AES-256-CBC mediante Master Password e derivazione della chiave PBKDF2 (100.000 iterazioni). Supporta una chiave di ripristino (*Recovery Key*) offline di emergenza e lo sblocco della sessione di shell (`_B4L_RT_CTX`) per evitare costanti richieste di password.
*   **Portabilità su Termux / Android**  
    Rilevamento automatico dell'ambiente Android Termux per aggirare i limiti del kernel o di SELinux sull'uso di `flock`. La gestione della concorrenza sui file viene deviata in modo trasparente sul meccanismo atomico di directory lock (`mkdir`).
*   **Sistema di Stato UI (`ui_state`)**  
    Il CORE espone in tempo reale metadati operativi in formato JSON atomico (scrittura protetta da lock) per agevolare l'integrazione strutturata con pannelli di controllo esterni, GUI o automazioni di terze parti (es. Home Assistant).
*   **Caching conversazionale e Session Engine avanzato**  
    Supporta sessioni multi-turn e gestione della cronologia dei thread in formato NDJSON. L'integrazione del modulo opzionale `session-engine.sh` consente la segmentazione automatica dei file storici (rotazione e compressione automatica dei blocchi superiori a 1MB) e caching in memoria con TTL per massimizzare la reattività.
*   **Estendibilità modulare**  
    Caricamento on-demand di provider esterni (Gemini, Hugging Face, Mistral) posizionati nella cartella degli extras, con isolamento dinamico delle sole definizioni delle funzioni e verifiche di integrità.

---

## Requisiti

Bash4LLM⁺ richiede che i seguenti pacchetti siano disponibili nel `PATH`:

- ***bash*** (versione 4.0 o superiore)
- coreutils (stat, chmod, mkdir, ecc.)
- findutils
- util-linux
- gawk
- curl
- jq

---

## Installazione rapida

> [!TIP]
> **⏩ FAST FORWARD (Installazione Rapida)**
> 
> Esegui questi comandi nel tuo terminale per scaricare e configurare subito **Bash4LLM⁺**:
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
> Lo script rileverà l'assenza della chiave e ti chiederà l'inserimento interattivo mascherato:
> `Enter API key for provider groq (env GROQ_API_KEY) [input is hidden]:`
>
> Inserisci la tua API key di Groq (la digitazione rimarrà invisibile a schermo). Subito dopo, lo script ti proporrà in modo sicuro di esportarla automaticamente per la sessione corrente tramite l'avviso interattivo (Session Sandboxing):
>
> `Export this API key to your current terminal session? [y/N]: y`
>
> Rispondi **`y` (Sì)** per caricare la chiave in memoria RAM e iniziare subito a utilizzare lo script senza inserire nuovamente la password in questa sessione.
> 
> Consigliato: ***installa gli Extras opzionali*** (provider aggiuntivi, chat REPL, template):
> ```sh
> # 4. Installazione degli Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Usa Bash4llm ⚡
>

Istruzioni di installazione dettagliate sono disponibili in **[INSTALLATION](INSTALL.md)**.

---

## Uso rapido ed esempi

Prompt diretto:
```sh
./bash4llm "Fornisci una spiegazione sintetica del protocollo SSH."
```

Pipe di standard input:
```sh
cat codice.sh | ./bash4llm "Ottimizza questo script Bash"
```

Uso di un modello specifico:
```sh
./bash4llm -m llama-3.3-70b-versatile "Spiega il paradosso di Fermi."
```

Esecuzione simulata (Dry-Run):
```sh
./bash4llm --dry-run "Genera una risposta fittizia"
```

Uso di un provider esterno (se installato e configurato):
```sh
./bash4llm --provider gemini "Traduci in inglese il seguente testo"
```

---

## Session Sandboxing (RAM Volatile)

Se decidi di non salvare in modo permanente le tue chiavi sul disco fisso (tramite il Vault Cifrato o i file di configurazione), `Bash4LLM⁺` ti permette di lavorare interamente in memoria RAM in modo sicuro, esente da registrazioni a schermo o inquinamento della cronologia della shell (*Command History Leak*).

Quando rispondi **`y` (Sì)** all'avviso di esportazione nella sessione corrente:
1. Lo script carica la chiave segreta nella memoria d'ambiente del processo.
2. Sostituisce il processo corrente aprendo una nuova shell nidificata (*Session Sandbox*) in cui la chiave è attiva.
3. Puoi eseguire qualsiasi comando di `./bash4llm` liberamente senza che ti venga mai più chiesta la chiave.

Per chiudere questa sessione protetta e cancellare istantaneamente e in modo irreversibile la chiave dalla memoria RAM del computer, digita:
```bash
exit
```
Questo comando ti riporterà in totale sicurezza al tuo terminale di partenza (puoi digitare nuovamente `exit` se desideri chiudere definitivamente la scheda del terminale).

---

## Comandi, flag e opzioni disponibili

### Modelli e provider
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--refresh-models`, `--refresh-model` | no | Sincronizza la lista dei modelli attivi del provider (richiede chiave API). |
| `--list-models` | no | Mostra i modelli del provider attivo (formato interattivo). |
| `--list-models-raw` | no | Stampa l'elenco dei modelli attivi in formato raw (un modello per riga). |
| `--list-providers` | no | Stampa l'elenco dei provider disponibili. |
| `--list-providers-raw` | no | Stampa l'elenco dei provider in formato raw. |
| `--set-default <model>` | sì | Salva e imposta il modello predefinito in modo persistente per il provider attivo. |
| `-m <model>`, `--model <model>` | sì | Specifica il modello da utilizzare per l'esecuzione corrente. |
| `--provider <name>` | sì | Seleziona il provider attivo per questa esecuzione. |
| `--provider` | no | Mostra il menu interattivo di selezione del provider di default. |

### Input (file, JSON, template, batch)
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `-f <file>` | sì | Carica il file specificato accodandolo alla coda degli input di testo. |
| `--json-input <json>` | sì | Passa una struttura JSON diretta OpenAI-like (array di messaggi). |
| `--template <name>` | sì | Carica ed elabora il prompt inserendolo nel template prescelto. |
| `--batch <file>` | sì | Esegue una serie di prompt memorizzati nel file (uno per riga). |

### Gestione dei Thread conversazionali (Memoria)
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--thread <id>` | sì | Attiva la sessione conversazionale per il thread specificato. |
| `--thread-window [n]` | opzionale | Definisce il numero massimo di messaggi della cronologia da includere (default: 10). |
| `--init-thread` | no | Inizializza in sicurezza i file NDJSON e i metadati locali per un nuovo thread. Richiede l'uso di `--thread <id>`. |

### Parametri di Generazione
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--system <text>` | sì | Imposta il prompt di sistema (*System Prompt*) per l'esecuzione corrente. |
| `--ture <n>`, `--temperature <n>` | sì | Regola la temperatura di generazione (valore numerico validato da 0.0 a 2.0). |
| `--max <n>` | sì | Imposta il limite massimo dei token di risposta (default: 4096). |

### Output e Salvataggio automatico
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--save` | no | Forza la scrittura e l'archiviazione della risposta nella cartella history. |
| `--nosave` | no | Disattiva completamente il salvataggio automatico della risposta. |
| `--out <path>` | sì | Redirige e salva la risposta nel file o nella directory specificata. |
| `--threshold <n>` | sì | Imposta la soglia minima in byte per il salvataggio automatico (default: 1000). |
| `--json` | no | Restituisce la risposta JSON originale e completa restituita dall'API. |
| `--pretty` | no | Restituisce la risposta JSON originale formattata in modo leggibile. |
| `--text` | no | Estrae e restituisce unicamente la risposta testuale (comportamento predefinito). |
| `--raw` | no | Restituisce la risposta testuale grezza escludendo le spaziature di a capo finali. |

### Modalità Operative
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--dry-run` | no | Simula l'intera esecuzione a vuoto senza contattare i server API. |
| `--quiet` | no | Riduce al minimo i messaggi di intestazione diagnostici su stderr. |
| `--stream` | no | Abilita lo streaming in tempo reale dei token su stdout (Server-Sent Events). |
| `--no-stream` | no | Disabilita la modalità streaming per la richiesta corrente. |
| `--chat` | no | Avvia la chat interattiva REPL basata su TUI (richiede l'installazione degli extras). |
| `--bootstrap-only` | no | Esegue solo le verifiche di bootstrap del filesystem e si arresta. |

### Configurazione e Diagnostica
| Flag | Argomento | Effetto |
|------|-----------|---------|
| `--check-config` | no | Verifica la sicurezza dei permessi del file di configurazione e rileva errori di linter. |
| `--explain-error <codice>` | sì | Restituisce la definizione dettagliata e le mitigazioni per il codice d'errore o alias inserito. |
| `--show-config` | no | Stampa l'elenco delle variabili e dei parametri attivi in runtime. |
| `--diagnostics` | no | Esegue una diagnostica integrata comprensiva di handshake TLS verso l'endpoint attivo. |
| `--vault` | no | Avvia la console interattiva di gestione del Key Vault crittografato OpenSSL. |
| `--version` | no | Mostra la versione corrente dello script e termina. |
| `-h`, `--help` | no | Rende a schermo l'aiuto in linea formattato da file locale. |

---

## Struttura dello Stato UI (`ui_state`)

Per facilitare l'integrazione di monitoraggio o automazione (come Home Assistant o pannelli grafici locali), Bash4LLM⁺ scrive in modo atomico metadati di stato aggiornati all'interno della cartella:

`bash4llm.d/config/ui_state/`

I file disponibili sono:
*   `threads/<thread_id>.json` → Stato specifico del thread (active, msg_count, last_ts, title).
*   `threads/index.json` → Indice strutturato contenente l'elenco dei thread attivi.
*   `last_api.json` → Metadati dell'ultima chiamata effettuata (http_status, finish_reason, req_id, edgecase_detected).
*   `last_history.json` → Dettagli sull'ultimo file salvato fisicamente nella cartella cronologia.
*   `provider_capabilities.json` → Informazioni sul provider in uso (se supporta streaming, modelli, o refresh).

---

## Codici di uscita (Exit Codes)

| Codice | Variabile canonica | Significato |
|:---:|:---|:---|
| **0** | - | Successo operativo. |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | Autenticazione fallita o API Key mancante per il provider attivo. |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Modello non valido, non supportato (non testuale) o assente in whitelist. |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Errore di connessione di rete o fallimento dell'esecuzione del comando `curl`. |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | Input vuoto o prompt di richiesta non specificato. |
| **15** | `BASH4LLM_ERR_TMP` | Errore di filesystem (directory non creabile, collisione di lock o symlink rilevato). |
| **16** | `BASH4LLM_ERR_API` | Errore HTTP restituito dall'API o risposta JSON non interpretabile dal core. |
| **17** | `BASH4LLM_ERR_SEC` | Violazione delle politiche di sicurezza (file di configurazione modificabile da terzi). |

---

## Licenza

Bash4LLM⁺ è rilasciato sotto licenza **GNU GPL v3**.  
Vedi il file **[LICENSE](LICENSE)** per maggiori dettagli.

---

## Contatti

*   **Autore:** Cristian Evangelisti  
*   **Email:** `opensource@cevangel.anonaddy.me`  
*   **Repository:** [GitHub kamaludu/bash4llm](https://github.com/kamaludu/bash4llm)
```
