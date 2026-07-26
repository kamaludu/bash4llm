[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)  

<!-- Release & Badges CI Generali -->
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?sort=semver&style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)
[![ShellCheck](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml)
[![Cross-Platform Tests](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml)
[![Bash Compatibility](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml)

<!-- Hardening del Core e Audit di sicurezza (mirati esclusivamente al Core bash4llm) -->
[![API Chaos & Resilience Mock Suite](https://github.com/kamaludu/bash4llm/actions/workflows/api-mock-chaos.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/api-mock-chaos.yml)
[![Extras SHA-256 Manifest Integrity](https://github.com/kamaludu/bash4llm/actions/workflows/extras-integrity-manifest.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/extras-integrity-manifest.yml)
[![Security & Process List Leak Audit](https://github.com/kamaludu/bash4llm/actions/workflows/security-hardening.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/security-hardening.yml)
[![Sourcing Isolation & Namespace Audit](https://github.com/kamaludu/bash4llm/actions/workflows/sourcing-isolation.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/sourcing-isolation.yml)
[![Section Marker Integrity Audit](https://github.com/kamaludu/bash4llm/actions/workflows/section-integrity.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/section-integrity.yml)  
> 🛡️ **Nota sulla Verifica del Core:** La riga inferiore dei badge dedicati a sicurezza, isolamento dello sourcing, integrità delle sezioni e chaos test API viene eseguita **rigorosamente ed esclusivamente** sul file eseguibile core `./bash4llm` per garantire Zero-Leakage, conformità all'Architettura Piatta e una resilienza superiore.

# Bash4LLM⁺ 🇮🇹 [🇬🇧](README-en.md)

Wrapper CLI in ambiente Bash per l'interfacciamento con API LLM compatibili con lo standard OpenAI. Integra un provider predefinito (Groq) ed è estendibile ad altri provider tramite moduli aggiuntivi.

Il progetto è strutturato come uno script Bash autonomo senza dipendenze esterne oltre ai comandi POSIX standard e alle utilità di base della shell.

Compatibilità nativa: Linux, macOS, WSL, Cygwin, Termux (Android) e BSD.

---

## Caratteristiche tecniche

* **Gestione dinamica dei modelli**  
  Interrogazione degli endpoint degli utenti (`GET /v1/models`) per l'aggiornamento dell'elenco dei modelli supportati, senza identificatori hardcoded nello script principale.
* **Isolamento a livello di filesystem**  
  I file temporanei sono gestiti all'interno di directory di processo dedicate (`RUN_TMPDIR`) con permessi restrittivi `0700` (`umask 077`). Non vengono usate directory condivise come `/tmp`.
* **Cifratura delle chiavi API (`--vault`)**  
  Integrazione opzionale tramite OpenSSL per la cifratura locale delle chiavi API. Utilizza l'algoritmo AES-256-CBC con derivazione della chiave tramite PBKDF2 (100.000 iterazioni) e Master Password. Supporta una chiave di ripristino offline e il riutilizzo del contesto di sessione (`_B4L_RT_CTX`).
* **Supporto Termux / Android**  
  Rilevamento dell'ambiente Android Termux con adattamento dei meccanismi di locking: dove `flock` presenta limitazioni di sistema, la gestione della concorrenza è reindirizzata su atomic directory lock (`mkdir`).
* **Integrazione dati di stato (`ui_state`)**  
  Scrittura atomica di file JSON contenenti i metadati operativi del runtime nella cartella `ui_state`, per l'integrazione con pannelli di controllo esterni o script di monitoraggio.
* **Gestione sessioni e cronologia**  
  Gestione del contesto conversazionale multi-turno con salvataggio dello storico in formato NDJSON. Con il modulo opzionale `session-engine.sh` vengono abilitati il tracciamento dei token, la rotazione/compressione dei segmenti di storico e il caching locale con TTL.
* **Moduli estendibili**  
  Caricamento dinamico dei moduli provider esterni (Gemini, Hugging Face, Mistral) con verifica di integrità crittografica dell'hash SHA-256 rispetto al manifest.

---

## Requisiti di sistema

Pacchetti richiesti nel `PATH`:

* **bash** (versione 4.0 o superiore)
* **coreutils** (`stat`, `chmod`, `mkdir`, `mv`, `rm`, ecc.)
* **findutils**
* **util-linux**
* **awk**
* **curl**
* **jq**

---

## Guida all'installazione

### Installazione rapida ⏩

```sh
# 1. Clona il repository
git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  

# 2. Copia l'eseguibile nella cartella di lavoro
mkdir -p bash4llm
cp repo-bash4llm/bin/bash4llm bash4llm/
chmod +x bash4llm/bash4llm

# 3. Inizializzazione e aggiornamento modelli
cd bash4llm 
./bash4llm --refresh-models
```

Al primo avvio senza variabile d'ambiente impostata, lo script chiederà l'inserimento interattivo della chiave API (input nascosto a schermo).

**Installazione degli Extras opzionali:**

```sh
# 4. Installazione opzionale degli Extras (provider aggiuntivi, TUI, moduli)
./bash4llm --install-extras ../repo-bash4llm/extras/
```

Istruzioni dettagliate sono disponibili in **[INSTALL](INSTALL.md)**.

---

## Esempi d'uso

Prompt da linea di comando:
```sh
./bash4llm "Fornisci una spiegazione del protocollo SSH."
```

Input da standard input (pipe):
```sh
cat codice.sh | ./bash4llm "Analizza questo script"
```

Selezione di un modello specifico:
```sh
./bash4llm -m llama-3.3-70b-versatile "Spiega il paradosso di Fermi."
```

Esecuzione di prova senza chiamate di rete (Dry-Run):
```sh
./bash4llm --dry-run "Test di generazione payload"
```

Uso di un provider secondario:
```sh
./bash4llm --provider gemini "Traduci il testo in inglese"
```

---

## Sicurezza e permessi del filesystem 🚨

Per proteggere lo script `bash4llm` da modifiche non autorizzate in ambienti condivisi, è possibile impostare i permessi di sola lettura/esecuzione appropriati per il sistema operativo in uso:

* **Linux (GNU/Linux):**
  ```bash
  sudo chown root:root /path/to/bash4llm && sudo chmod 755 /path/to/bash4llm
  sudo chattr +i /path/to/bash4llm
  ```
* **macOS / BSD:**
  ```bash
  sudo chown root:wheel /path/to/bash4llm && sudo chmod 755 /path/to/bash4llm
  sudo chflags schg /path/to/bash4llm
  ```
* **Termux (Android):**
  ```bash
  chmod 500 ~/bash4llm
  ```
* **WSL / Cygwin:**
  ```bash
  setfacl -b /path/to/bash4llm 2>/dev/null
  chmod 755 /path/to/bash4llm
  ```

Per informazioni dettagliate sulle politiche di sicurezza, consultare **[SECURITY.md](SECURITY.md)**.

---

## Verifiche di sicurezza e test automatizzati 🛡️

L'eseguibile `./bash4llm` integra verifiche continue sul codice e sull'ambiente di esecuzione:

1. **[Verifica marcatura sezioni](.github/workflows/section-integrity.yml)**: Controllo della struttura ad ancoraggi e delimitatori di sezione del file principale.
2. **[Isolamento ambiente di sourcing](.github/workflows/sourcing-isolation.yml)**: Test della funzione `_cleanup_sourced_env` per verificare che l'inclusione via `source` non lasci funzioni residue nella shell chiamante.
3. **[Verifica secret leak in `argv`](.github/workflows/security-hardening.yml)**: Verifica della mancata presenza di chiavi API e token Bearer nella tabella dei processi del sistema operativo durante l'esecuzione di `curl`. Controllo permessi POSIX `0700` e `0600`.
4. **[Test di resilienza API](.github/workflows/api-mock-chaos.yml)**: Simulazione di risposte di errore HTTP, rate limit e casi limite tramite server mock.
5. **[Integrità del manifest `extras`](.github/workflows/extras-integrity-manifest.yml)**: Controllo degli hash SHA-256 dei moduli opzionali rispetto al file `extras/manifest.sha256`.

---

## Riferimento comandi e opzioni

### Modelli e provider
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `--refresh-models`, `--refresh-model` | No | Sincronizza l'elenco dei modelli del provider attivo. |
| `--list-models` | No | Elenca i modelli disponibili per il provider attivo. |
| `--list-models-raw` | No | Stampa l'elenco dei modelli in formato testo grezzo. |
| `--list-providers` | No | Elenca i provider installati. |
| `--list-providers-raw` | No | Stampa l'elenco dei provider in formato testo grezzo. |
| `--set-default <modello>` | Sì | Imposta il modello predefinito per il provider attivo. |
| `-m <modello>`, `--model <modello>` | Sì | Specifica il modello per l'esecuzione corrente. |
| `--provider <nome>` | Sì | Seleziona il provider attivo per l'esecuzione corrente. |
| `--provider` | No | Apre il menu interattivo di selezione del provider. |

### Input
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `-f <file>` | Sì | Aggiunge il contenuto del file al prompt di input. |
| `--json-input <json>` | Sì | Invia una struttura JSON diretta con l'array dei messaggi. |
| `--template <nome>` | Sì | Applica un file di modello dalla cartella dei template. |
| `--batch <file>` | Sì | Esegue una serie di prompt da file (un prompt per riga). |

### Gestione thread e contesto
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `--thread <id>` | Sì | Attiva il contesto conversazionale per l'ID specificato. |
| `--thread-window [n]` | Opzionale | Imposta il numero massimo di messaggi storici da includere (default: 10). |
| `--init-thread` | No | Inizializza i file di contesto per un nuovo thread ed esce. |

### Parametri di generazione
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `--system <testo>` | Sì | Imposta il prompt di sistema per l'esecuzione. |
| `--ture <n>`, `--temperature <n>` | Sì | Imposta il valore di temperatura (da 0.0 a 2.0). |
| `--max <n>` | Sì | Imposta il limite massimo dei token della risposta (default: 4096). |

### Output e salvataggio
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `--save` | No | Forza il salvataggio della risposta nella cronologia. |
| `--nosave` | No | Disabilita il salvataggio della risposta nella cronologia. |
| `--out <percorso>` | Sì | Salva l'output nel file o nella directory specificata. |
| `--threshold <n>` | Sì | Soglia minima in byte per il salvataggio automatico (default: 1000). |
| `--json` | No | Restituisce il payload JSON completo dell'API. |
| `--pretty` | No | Restituisce il payload JSON formattato. |
| `--text` | No | Restituisce il solo testo della risposta (predefinito). |
| `--raw` | No | Restituisce il testo grezzo senza a capo finale. |

### Modalità operative
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `--dry-run` | No | Simula l'esecuzione senza effettuare chiamate di rete. |
| `--quiet` | No | Omette i messaggi informativi non essenziali su stderr. |
| `--stream` | No | Abilita la ricezione in streaming (Server-Sent Events). |
| `--no-stream` | No | Disabilita lo streaming per la richiesta corrente. |
| `--chat` | No | Avvia l'interfaccia interattiva TUI/REPL. |
| `--bootstrap-only` | No | Esegue la fase di avvio e verificate filesystem, poi termina. |

### Configurazione e diagnostica
| Flag | Argomento | Descrizione |
|------|-----------|-------------|
| `--check-config` | No | Esegue la verifica dei permessi e il linter della configurazione. |
| `--explain-error <codice>` | Sì | Mostra la definizione e le mitigazioni per il codice d'errore inserito. |
| `--show-config` | No | Stampa le variabili di configurazione attive. |
| `--diagnostics` | No | Esegue i test diagnostici di sistema e la verifica TLS. |
| `--vault` | No | Avvia la console di gestione del Key Vault cifrato. |
| `--version` | No | Mostra la versione dello script. |
| `-h`, `--help` | No | Mostra l'aiuto in linea. |

---

## Struttura dello stato UI (`ui_state`)

Il runtime aggiorna in modo atomico i metadati di stato nella directory:

`bash4llm.d/config/ui_state/`

File generati:
* `threads/<thread_id>.json`: Stato e metadati del thread attivo.
* `threads/index.json`: Indice dei thread salvati.
* `last_api.json`: Metadati dell'ultima chiamata API (stato HTTP, ID richiesta, tempo).
* `last_history.json`: Informazioni sull'ultimo file scritto in cronologia.
* `provider_capabilities.json`: Funzionalità supportate dal provider attivo.

---

## Codici di uscita (Exit Codes)

| Codice | Costante | Descrizione |
|:---:|:---|:---|
| **0** | - | Esecuzione completata con successo. |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | Chiave API non trovata per il provider attivo. |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Modello non valido o formato non supportato. |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Errore durante l'esecuzione della richiesta HTTP (`curl`). |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | Prompt o payload di input vuoto. |
| **15** | `BASH4LLM_ERR_TMP` | Errore di filesystem, allocazione temporanea o lock. |
| **16** | `BASH4LLM_ERR_API` | Errore restituito dall'API o completamento vuoto. |
| **17** | `BASH4LLM_ERR_SEC` | Violazione della politica di sicurezza o mancata corrispondenza dell'hash del modulo. |

---

## Licenza e Contatti

* **Licenza:** GNU General Public License v3.0 ([LICENSE](LICENSE))
* **Autore:** Cristian Evangelisti  
* **Email:** `opensource@cevangel.anonaddy.me`  
* **Repository:** [GitHub kamaludu/bash4llm](https://github.com/kamaludu/bash4llm)
