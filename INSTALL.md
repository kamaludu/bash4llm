[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

# INSTALLAZIONE DELLO SCRIPT BASH4LLM⁺ 🇮🇹 [🇬🇧](INSTALL-en.md)

Bash4LLM⁺ è un wrapper CLI in ambiente Bash progettato per l'interfacciamento sicuro con le API di vari provider di modelli linguistici (LLM). Non richiede l'installazione di runtime esterni come Python o Node.js, basandosi esclusivamente sui comandi POSIX standard e sulle utilità della shell.

---

## 1. Requisiti di Sistema

Bash4LLM⁺ richiede che i seguenti pacchetti ed utilità di sistema siano installati ed accessibili nel `PATH`:

- **bash** (versione 4.0 o superiore per il supporto agli array associativi)
- **coreutils** (`cat`, `chmod`, `cp`, `date`, `head`, `mktemp`, `mv`, `printf`, `rm`, `sort`, `stat`, `tr`, `wc`, `tee`)
- **findutils** (`find`)
- **util-linux** (`xargs`)
- **awk**, **sed**, **grep**, **comm**
- **curl**
- **jq**

*Nota sulla concorrenza: L'uso di `flock` è opzionale. Nei sistemi in cui `flock` è limitato o assente (es. Android/Termux), lo script rileva l'ambiente e reindirizza la gestione dei lock su allocazioni di directory atomiche (`mkdir`).*

### Compatibilità Piattaforme

Il runtime è verificato sui seguenti ambienti:

- **GNU/Linux** (Tutte le distribuzioni standard)
- **macOS** (Utility di sistema di serie o pacchetti GNU da Homebrew)
- **WSL e Cygwin** (Windows)
- **Termux** (Android)
- **BSD** (FreeBSD, OpenBSD, NetBSD, DragonFly)

---

## 2. Procedura di Installazione

### 2.1 Esecuzione Rapida da Repository

Per scaricare e configurare l'eseguibile principale da terminale:

```sh
# 1. Clona il repository (download limitato all'ultimo commit)
git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  

# 2. Crea la directory di lavoro e copia il binario principale
mkdir -p bash4llm
cp repo-bash4llm/bash4llm bash4llm/
chmod +x bash4llm/bash4llm

# 3. Accedi alla cartella e sincronizza i modelli
cd bash4llm 
./bash4llm --refresh-models
```

Se non è presente una chiave API salvata o esportata nelle variabili d'ambiente, lo script richiederà l'inserimento interattivo mascherato:
`Enter API key for provider groq (env GROQ_API_KEY):`

Per mantenere la chiave attiva nella RAM per la sessione corrente del terminale:
```sh
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
```

---

### 2.2 Installazione degli Extras Opzionali (`--install-extras`)

I moduli aggiuntivi (provider secondari come Gemini, Mistral e Hugging Face, la chat interattiva TUI, la console Vault e il gestore avanzato delle sessioni) sono collocati nella cartella `extras/`. Per installarli nell'ambiente locale:

```sh
./bash4llm --install-extras ../repo-bash4llm/extras/
```

### Meccanismi di Sicurezza dell'Installer:
1. **Verifica Integrità SHA-256**: I moduli copiati vengono verificati rispetto al manifesto crittografico `extras/manifest.sha256`. Discrepanze o file alterati arrestano il processo con codice di uscita `17` (`BASH4LLM_ERR_SEC`).
2. **Permessi del Filesystem**: I file vengono scritti applicando permessi restrittivi `0700` per le directory e `0600` per i file di configurazione e modulo.
3. **Rifiuto Symlink**: L'installer rifiuta la copia di collegamenti simbolici per prevenire vulnerabilità di attraversamento directory (*Directory Traversal*).

---

## 3. Struttura delle Directory di Runtime

Alla prima esecuzione, lo script crea la directory di lavoro isolata `bash4llm.d/` applicando i permessi POSIX `0700` (directory) e `0600` (file):

```text
bash4llm.d/
├── config/                                # Configurazione e persistenza provider
│   ├── config                             # Variabili e parametri globali utente
│   ├── provider                           # Nome del provider attivo
│   ├── provider-url                       # URL dell'API del provider attivo
│   ├── model.<provider>                   # Modello predefinito per il provider
│   ├── keys.enc                           # Database cifrato della chiave Master (Vault)
│   ├── keys.rec                           # Chiave di ripristino offline cifrata (Vault)
│   ├── keys.dat                           # Payload cifrato delle chiavi API (Vault)
│   ├── providers/                         # Configurazioni avanzate dei provider
│   │   └── hf_endpoints                   # Mappatura modelli ed endpoint Hugging Face
│   └── ui_state/                          # File JSON di stato per GUI ed automazioni
│       ├── last_api.json                  # Stato dell'ultima chiamata API
│       ├── last_history.json              # Stato dell'ultimo output salvato
│       ├── provider_capabilities.json     # Capacità del provider attivo
│       └── threads/                       # Metadati ed indici dei thread
│           ├── index.json                 # Elenco dei thread registrati
│           └── <safe_thread_id>.json      # Metadati di stato del thread (SHA-256)
├── models/                                # Cache locale dei modelli per provider
│   └── <provider>.txt                     # Elenco modelli approvati
├── templates/                             # Prompt template riutilizzabili
├── history/                               # Cronologia delle risposte salvate
│   └── threads/                           # Storico conversazionale (.ndjson)
│       └── <safe_thread_id>.ndjson        # Registro conversazione in NDJSON
├── var/                                   # Processi e file di runtime isolati
│   └── run/                              # Directory di esecuzione del processo (0700)
│       └── locks/                         # File di blocco della concorrenza (0700)
│           ├── models.lock                # Lock per l'aggiornamento dei modelli
│           ├── history.lock               # Lock per la gestione della cronologia
│           └── tmp.lock                   # Lock per allocazione file temporanei
├── tmp/                                   # Cartella temporanea sicura e isolata (0700)
│   └── rates/                             # Tracciamento transazioni rate limiting (0700)
│       └── <safe_thread_id>/              # Timestamp per finestra scorrevole
└── extras/                                # Componenti ed estensioni opzionali
    ├── manifest.sha256                    # Manifesto dell'integrità crittografica
    ├── chat/                              # Interfaccia REPL TUI (tui-repl.sh)
    ├── hooks/                             # Moduli hook pre/post esecuzione
    ├── security/                          # Helper di sicurezza OpenSSL (openssl-helper.sh)
    ├── providers/                         # Provider esterni (Gemini, Hugging Face, Mistral)
    └── session/                           # Gestore di sessione avanzato (session-engine.sh)
```

---

## 4. Gestione Cifrata delle Credenziali (Security Vault)

Se la cartella `extras/` è installata ed è presente il binario `openssl`, è possibile archiviare le chiavi API in forma cifrata tramite il Vault integrato:

```sh
./bash4llm --vault
```

### Caratteristiche del Vault:
* **Cifratura su disco**: Le chiavi vengono cifrate in formato AES-256-CBC con derivazione PBKDF2 (100.000 iterazioni) e salvate in `keys.dat`.
* **Sblocco di sessione in RAM**: È possibile sbloccare il Vault per la sessione corrente della shell tramite il comando di sourcing:
  ```sh
  . ./bash4llm
  ```
  L'operazione esporta temporaneamente il token di contesto `_B4L_RT_CTX` nella memoria della shell, evitando richieste di password fino alla chiusura della sessione.
* **Disabilitazione del Vault**: Per disattivare la ricerca delle chiavi nel Vault, impostare `BASH4LLM_VAULT_ENABLED=0`.

---

## 5. Risoluzione dei Problemi (Troubleshooting)

### Violazione delle Politiche di Sicurezza (Exit Code 17 - BASH4LLM_ERR_SEC)
Se lo script termina con codice di uscita `17`, è stata rilevata un'anomalia di sicurezza:
* **Permessi non restrittivi**: File di configurazione o cartelle scrivibili da gruppi o terzi (`group/world-writable`).
* **Symlink rilevato**: Presenza di un collegamento simbolico non consentito in una directory di lavoro.
* **Mancata corrispondenza Hash**: Un file nella cartella `extras/` è stato modificato rispetto a `manifest.sha256`.

Ripristino dei permessi POSIX standard:
```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config
```

### Blocco del Rate Limiter
Se il numero di richieste supera la soglia consentita entro una finestra di 30 secondi, l'esecuzione viene bloccata con codice `17`. È possibile modificare o disattivare il limite tramite la variabile:
```sh
export BASH4LLM_RATE_LIMIT=10  # Consente 10 richieste ogni 30 secondi per thread
```

### Timeout sui Lock di Concorrenza (Exit Code 15 - BASH4LLM_ERR_TMP)
In presenza di esecuzioni concorrenti, è possibile estendere il tempo massimo di attesa dei lock tramite la variabile:
```sh
export BASH4LLM_LOCK_TIMEOUT_HISTORY=30
```

---

## 6. Disinstallazione

Per rimuovere completamente il runtime e i dati dal sistema, eliminare l'eseguibile e la directory di lavoro:

```sh
rm -rf bash4llm.d
rm bash4llm
```

---

## 7. Licenza

Bash4LLM⁺ è rilasciato sotto licenza [**GNU GPL v3.0**](LICENSE).
