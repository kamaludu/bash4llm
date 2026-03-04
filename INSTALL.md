[![GroqBash](https://img.shields.io/badge/_GroqBash_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLAZIONE  🇮🇹 [🇬🇧](INSTALL-en.md)

GroqBash è un wrapper Bash portabile e sicuro per l’API Groq.  
Non richiede Python né dipendenze esterne oltre ai comandi POSIX/coreutils.

---

## 1. Requisiti

GroqBash richiede che i seguenti pacchetti (o equivalenti) siano disponibili nel PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

Questi pacchetti forniscono tutti i comandi necessari:
*bash* ` mv cp chmod stat find sort head wc tee date curl jq flock base64 mktemp readlink awk sed grep xargs sync sha256sum stdbuf `

### Compatibilità

GroqBash funziona su:

- GNU/Linux
- macOS (con pacchetti GNU installabili via Homebrew)
- BusyBox/Alpine
- WSL e Cygwin (Windows)
- Termux (Android)

---

## 2. Installazione di base

### 2.1 Clonare o scaricare GroqBash

`git clone https://github.com/<tuo-repo>/groqbash.git`  
`cd groqbash`

Oppure scarica il file `groqbash` e rendilo eseguibile:

`chmod +x groqbash`

### 2.2 Impostare la chiave API

GroqBash usa la variabile:

`export GROQ_API_KEY="la_tua_chiave"`

Puoi inserirla nel tuo `.bashrc` o `.zshrc`.

---

## 3. Struttura delle directory

Alla prima esecuzione, GroqBash crea automaticamente:
`
groqbash.d/
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

`./groqbash -m mixtral-8x7b -- "Scrivi un haiku sul vento."`

### Modalità streaming

`./groqbash --stream -- "Genera testo in streaming."`

### Input da file

`./groqbash -f input.txt`

### Output in JSON

`./groqbash --json -- "Cosa sai di Bash?"`

---

## 5. Modelli

### Aggiornare la lista dei modelli

`./groqbash --refresh-models`

La lista viene salvata in:

`groqbash.d/models/models.txt`

### Elencare i modelli

`./groqbash --list-models`

---

## 6. History e salvataggio automatico

GroqBash salva automaticamente l’output quando:

- supera una certa dimensione (THRESHOLD, default 1000 byte), oppure  
- è attivo `--save`.

I file vengono salvati in:

`groqbash.d/history/`

La rotazione è configurabile tramite:

- GROQBASH_ROTATE_HISTORY  
- GROQBASH_HISTORY_MAX_FILES  
- GROQBASH_HISTORY_MAX_BYTES  
- GROQBASH_HISTORY_KEEP_DAYS  

---

## 7. Installazione degli extras (opzione `--install-extras`)

GroqBash include un installer sicuro e portabile per copiare componenti aggiuntivi (script, provider, template, documentazione) nella directory:

`groqbash.d/extras/`

### 7.1 Uso base

`./groqbash --install-extras`

Se non specifichi componenti, vengono installati **tutti** i file presenti nella directory sorgente degli extras.

### 7.2 Installare componenti specifici

`./groqbash --install-extras provider1 templateA`

### 7.3 Sorgente personalizzata

`./groqbash --install-extras --source /path/to/extras`

### 7.4 Sovrascrivere file in conflitto

`./groqbash --install-extras --force`

### 7.5 Modalità dry‑run

`./groqbash --install-extras --dry-run`

Nessun file viene modificato.

---

## 8. Comportamento dell’installer (dettagli tecnici)

### 8.1 Sicurezza e atomicità

- Ogni file è copiato tramite:
  - mktemp  
  - cat (portabile)  
  - mv -f atomico  
- Ogni operazione è protetta da lock (flock) su:
  `groqbash.d/extras/.install.lock`

### 8.2 Permessi

- File normali → chmod 600  
- File eseguibili → chmod 700  
- Se il filesystem non supporta i permessi (NTFS/WSL), GroqBash mostra un **warning**, non un errore.

### 8.3 Symlink

- I symlink nella sorgente vengono risolti in modo sicuro.  
- Se puntano fuori dalla directory sorgente → **vengono rifiutati**.

### 8.4 Conflitti

- Se un file esiste già e **è diverso**, GroqBash:
  - mostra un **warning**,  
  - **non sovrascrive**,  
  - **non fallisce** (exit code 0),  
  - a meno che non sia usato `--force`.

### 8.5 Timeout lock

Il timeout del lock è configurabile:

`export GROQBASH_LOCK_TIMEOUT_MODELS=10`

Default: **10 secondi**.

---

## 9. Variabili d’ambiente utili

- GROQ_API_KEY — chiave API Groq  
- MODEL — modello predefinito  
- TURE / TEMPERATURE — temperatura  
- MAX_TOKENS  
- OUTPUT_MODE — text, raw, json, pretty  
- GROQBASH_DEBUG=1 — abilita log dettagliati  
- ALLOW_API_CALLS=0 — blocca chiamate reali (utile per test)

---

## 10. Portabilità e note sui filesystem

### 10.1 NTFS / WSL

- chmod può fallire → GroqBash mostra un warning.  
- Le operazioni restano atomiche.

### 10.2 NFS

- flock può essere inaffidabile → GroqBash mostra un warning in modalità debug.

### 10.3 BusyBox

- Tutte le funzioni sono compatibili.

---

## 11. Disinstallazione

Per rimuovere GroqBash:

`rm -rf groqbash.d`  
`rm groqbash`

---

## 12. Troubleshooting

### Nessuna risposta dal modello

- Verifica GROQ_API_KEY  
- Verifica connessione  
- Attiva debug:  
  `GROQBASH_DEBUG=1 ./groqbash -- "test"`

### Errore su permessi

Probabile filesystem non‑POSIX (NTFS).  
GroqBash continua comunque l’installazione.

### Lock timeout

Aumenta:

`export GROQBASH_LOCK_TIMEOUT_MODELS=30`

---

## 13. Licenza

GroqBash è distribuito sotto licenza [**GNU GPL v3**](LICENSE)
