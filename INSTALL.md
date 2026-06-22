[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLAZIONE  🇮🇹 [🇬🇧](INSTALL-en.md)

Bash4LLM è un wrapper Bash portabile e sicuro per l’API Groq.  
Non richiede Python né dipendenze esterne oltre ai comandi POSIX/coreutils.

---

## 1. Requisiti

Bash4LLM richiede che i seguenti pacchetti (o equivalenti) siano disponibili nel PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

### Compatibilità

Bash4LLM funziona su:

- GNU/Linux
- macOS (con pacchetti GNU installabili via Homebrew)
- WSL e Cygwin (Windows)
- Termux (Android)
- BSD

---

## 2. Installazione di base

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
