[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLAZIONE 🇮🇹 [🇬🇧](INSTALL-en.md)

Bash4LLM⁺ è un wrapper Bash portabile e sicuro per l'API di svariati LLM (con supporto nativo a Groq).  
Non richiede Python né dipendenze esterne oltre ai comandi POSIX/coreutils e alle utility di base della shell.

---

## 1. Requisiti

Bash4LLM⁺ richiede che i seguenti pacchetti siano disponibili nel tuo `PATH`:

- ***bash*** (versione 4.0 o superiore per il supporto agli array associativi)
- coreutils (comandi stat, chmod, mkdir, ecc.)
- findutils
- util-linux
- gawk
- curl
- jq

### Compatibilità

Bash4LLM⁺ è testato e supportato su:

- GNU/Linux
- macOS (con utilità standard o pacchetti GNU da Homebrew)
- WSL e Cygwin (Windows)
- Termux (Android)
- BSD (FreeBSD, OpenBSD, NetBSD)

---

## 2. Installazione rapida (Fast Forward)

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
> Lo script rileverà l'assenza della chiave e ti chiederà l'inserimento interattivo:
> `Enter API key for provider groq (env GROQ_API_KEY):`
> 
> Inserisci la tua API key di Groq. Per evitare di reinserirla nelle successive esecuzioni della sessione di terminale corrente, esportala:
> 
> `export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`
> 
> Consigliato: ***installa gli Extras opzionali*** (provider aggiuntivi, chat REPL, template):
> ```sh
> # 4. Installazione degli Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Usa Bash4llm ⚡
> 

### 2.1 Installazione manuale

Rendi eseguibile il file principale dopo averlo scaricato o copiato:

`chmod +x bash4llm`

### 2.2 Impostare la chiave API

Bash4LLM⁺ legge la chiave API dall'ambiente. Esportala nel tuo file di configurazione della shell (es. `~/.bashrc` o `~/.bash_profile`):

`export GROQ_API_KEY="la_tua_chiave_qui"`

---

## 3. Struttura delle directory

Alla prima esecuzione, lo script crea la seguente struttura di lavoro all'interno della directory di runtime (`bash4llm.d/`), applicando permessi restrittivi `700` (cartelle) e `600` (file) per impedire l'accesso ad altri utenti del sistema:

```text
bash4llm.d/
    config/                # Configurazione e persistenza provider/modelli default
        providers/         # Configurazioni specifiche dei provider (es. hf_endpoints)
        ui_state/          # File JSON di stato per GUI e automazioni
            threads/       # Metadati e indici delle sessioni attive
        thread_cache/      # Caching locale delle risposte dei thread (se attivo)
    models/                # File txt delle whitelist dei modelli per ciascun provider
    templates/             # Prompt template riutilizzabili
    history/               # Cronologia degli output salvati automaticamente
        threads/           # Storico conversazionale dei thread in formato NDJSON
    tmp/                   # Cartella sicura isolata per i lock e i file temporanei
    extras/                # Componenti aggiuntivi opzionali (installati con --install-extras)
        providers/         # Script dei provider esterni (Gemini, Hugging Face, Mistral)
```

---

## 4. Installazione degli Extras (`--install-extras`)

Per utilizzare le funzioni avanzate (la console di cifratura delle chiavi, i provider aggiuntivi come Gemini o Hugging Face, o l'interfaccia di chat interattiva REPL), installa gli Extras:

`./bash4llm --install-extras`

Se esegui l'eseguibile al di fuori della cartella del repository clonato, specifica il percorso in cui si trova la cartella `extras`:

`./bash4llm --install-extras /percorso/di/sorgente/extras`

L'installer si occuperà di copiare ricorsivamente i file necessari all'interno del perimetro sicuro `bash4llm.d/extras/`, applicando permessi restrittivi `700` ai file eseguibili (come i moduli dei provider e la chat TUI) e `600` ai documenti di aiuto o template.

Se stai operando su un filesystem non nativamente POSIX (ad esempio una condivisione NTFS sotto Windows o determinati montaggi di rete), lo script rileverà i limiti di applicazione dei permessi stampando un avviso non bloccante.

---

## 5. Troubleshooting e risoluzione dei problemi

### Errore di sicurezza (Codice d'uscita 17 - BASH4LLM_ERR_SEC)
Se lo script si interrompe con l'errore `BASH4LLM_ERR_SEC`, significa che un controllo statico di sicurezza ha rilevato permessi di scrittura troppo permissivi sul file di configurazione locale o sulla cartella del programma. Metti in sicurezza il tuo ambiente di lavoro eseguendo:

```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config
```

### Timeout sui lock del filesystem
Se ricevi un errore di timeout durante la scrittura dei modelli o dei thread a causa di operazioni concorrenti prolungate, puoi aumentare il tempo di attesa massimo (espresso in secondi) esportando la variabile d'ambiente corretta:

`export BASH4LLM_LOCK_TIMEOUT_HISTORY=30`

---

## 6. Disinstallazione

Bash4LLM⁺ è completamente auto-confinato. Per rimuoverlo definitivamente dal sistema è sufficiente eliminare l'eseguibile e la sua cartella di lavoro:

```sh
rm -rf bash4llm.d
rm bash4llm
```

---

## 7. Licenza

Bash4LLM⁺ è un software libero distribuito sotto licenza [**GNU GPL v3**](LICENSE).

> Lo script ti chiederà l'inserimento della tua chiave API per il provider di default (Groq):
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

### 2.1 Clonare o scaricare Bash4LLM

`git clone https://github.com/<tuo-repo>/bash4llm.git`  
`cd bash4llm`

Oppure scarica il file `bash4llm` e rendilo eseguibile:

`chmod +x bash4llm`

### 2.2 Impostare la chiave API

Bash4LLM usa la variabile:

`export GROQ_API_KEY="la_tua_chiave"`

Puoi inserirla nel tuo `.bashrc` o `.zshrc`.

---

## 3. Struttura delle directory

Alla prima esecuzione, Bash4LLM crea automaticamente:
`
bash4llm.d/
    config/
    models/
    templates/
    history/
    tmp/
    extras/
        providers/
`
Tutte le directory sono create con permessi 700 (best‑effort su filesystem non‑POSIX).

---

## 4. Uso rapido

### Prompt singolo

`./bash4llm -m mixtral-8x7b -- "Scrivi un haiku sul vento."`

### Modalità streaming

`./bash4llm --stream -- "Genera testo in streaming."`

### Input da file

`./bash4llm -f input.txt`

### Output in JSON

`./bash4llm --json -- "Cosa sai di Bash?"`

---

## 5. Modelli

### Aggiornare la lista dei modelli

`./bash4llm --refresh-models`

La lista viene salvata in:

`bash4llm.d/models/models.txt`

### Elencare i modelli

`./bash4llm --list-models`

---

## 6. History e salvataggio automatico

Bash4LLM salva automaticamente l’output quando:

- supera una certa dimensione (THRESHOLD, default 1000 byte), oppure  
- è attivo `--save`.

I file vengono salvati in:

`bash4llm.d/history/`

La rotazione è configurabile tramite:

- BASH4LLM_ROTATE_HISTORY  
- BASH4LLM_HISTORY_MAX_FILES  
- BASH4LLM_HISTORY_MAX_BYTES  
- BASH4LLM_HISTORY_KEEP_DAYS  

---

## 7. Installazione degli extras (opzione `--install-extras`)

Bash4LLM include un installer sicuro e portabile per copiare componenti aggiuntivi (script, provider, template, documentazione) nella directory:

`bash4llm.d/extras/`

### 7.1 Uso base

`./bash4llm --install-extras`

Se non specifichi componenti, vengono installati **tutti** i file presenti nella directory sorgente degli extras.

### 7.2 Installare componenti specifici

`./bash4llm --install-extras provider1 templateA`

### 7.3 Sorgente personalizzata

`./bash4llm --install-extras --source /path/to/extras`

### 7.4 Sovrascrivere file in conflitto

`./bash4llm --install-extras --force`

### 7.5 Modalità dry‑run

`./bash4llm --install-extras --dry-run`

Nessun file viene modificato.

---

## 8. Comportamento dell’installer (dettagli tecnici)

### 8.1 Sicurezza e atomicità

- Ogni file è copiato tramite:
  - mktemp  
  - cat (portabile)  
  - mv -f atomico  
- Ogni operazione è protetta da lock (flock) su:
  `bash4llm.d/extras/.install.lock`

### 8.2 Permessi

- File normali → chmod 600  
- File eseguibili → chmod 700  
- Se il filesystem non supporta i permessi (NTFS/WSL), Bash4LLM mostra un **warning**, non un errore.

### 8.3 Symlink

- I symlink nella sorgente vengono risolti in modo sicuro.  
- Se puntano fuori dalla directory sorgente → **vengono rifiutati**.

### 8.4 Conflitti

- Se un file esiste già e **è diverso**, Bash4LLM:
  - mostra un **warning**,  
  - **non sovrascrive**,  
  - **non fallisce** (exit code 0),  
  - a meno che non sia usato `--force`.

### 8.5 Timeout lock

Il timeout del lock è configurabile:

`export BASH4LLM_LOCK_TIMEOUT_MODELS=10`

Default: **10 secondi**.

---

## 9. Variabili d’ambiente utili

- GROQ_API_KEY — chiave API Groq  
- MODEL — modello predefinito  
- TURE / TEMPERATURE — temperatura  
- MAX_TOKENS  
- OUTPUT_MODE — text, raw, json, pretty  
- BASH4LLM_DEBUG=1 — abilita log dettagliati  
- ALLOW_API_CALLS=0 — blocca chiamate reali (utile per test)

---

## 10. Portabilità e note sui filesystem

### 10.1 NTFS / WSL

- chmod può fallire → Bash4LLM mostra un warning.  
- Le operazioni restano atomiche.

### 10.2 NFS

- flock può essere inaffidabile → Bash4LLM mostra un warning in modalità debug.

### 10.3 BusyBox

- Tutte le funzioni sono compatibili.

---

## 11. Disinstallazione

Per rimuovere Bash4LLM:

`rm -rf bash4llm.d`  
`rm bash4llm`

---

## 12. Troubleshooting

### Nessuna risposta dal modello

- Verifica GROQ_API_KEY  
- Verifica connessione  
- Attiva debug:  
  `BASH4LLM_DEBUG=1 ./bash4llm -- "test"`

### Errore su permessi

Probabile filesystem non‑POSIX (NTFS).  
Bash4LLM continua comunque l’installazione.

### Lock timeout

Aumenta:

`export BASH4LLM_LOCK_TIMEOUT_MODELS=30`

---

## 13. Licenza

Bash4LLM è distribuito sotto licenza [**GNU GPL v3**](LICENSE)
