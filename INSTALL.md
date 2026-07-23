[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLAZIONE 🇮🇹 [🇬🇧](INSTALL-en.md)

Bash4LLM⁺ è un wrapper Bash portabile e sicuro per l'API di svariati LLM (con supporto nativo a Groq).  
Non richiede Python né dipendenze esterne oltre ai comandi POSIX/coreutils e alle utility di base della shell.

---

## 1. Requisiti di Sistema

Bash4LLM⁺ richiede che i seguenti **23 binari/utilità** siano disponibili nel tuo `PATH`:

- **bash** (versione 4.0 o superiore per il supporto agli array associativi e al caching in-process)
- **coreutils** (`cat`, `chmod`, `cp`, `date`, `head`, `mktemp`, `mv`, `printf`, `rm`, `sort`, `stat`, `tr`, `wc`, `tee`)
- **findutils** (`find`)
- **util-linux** (`xargs`)
- **awk**, **sed**, **grep**, **comm**
- **curl**
- **jq**

*Nota: L'utility `flock` non è obbligatoria; se assente (es. su Termux/Android), lo script devia automaticamente su directory lock atomiche.*

### Compatibilità Piattaforme

Bash4LLM⁺ è testato e supportato su:

- **GNU/Linux** (Tutte le distribuzioni principali)
- **macOS** (Con utilità di sistema di default o pacchetti GNU da Homebrew)
- **WSL e Cygwin** (Windows)
- **Termux** (Android)
- **BSD** (FreeBSD, OpenBSD, NetBSD, DragonFly)

---

## 2. Installazione Rapida (Fast Forward)

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
> cp repo-bash4llm/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
> 
> # 3. Entra nella cartella e aggiorna i modelli 
> cd bash4llm 
> ./bash4llm --refresh-models
> ```
> 
> In assenza di una chiave salvata, lo script chiederà l'inserimento interattivo:
> `Enter API key for provider groq (env GROQ_API_KEY):`
> 
> Inserisci la tua API key di Groq. Per evitare di reinserirla nelle successive esecuzioni della sessione corrente, esportala:
> 
> `export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`
> 
> Consigliato: ***installa gli Extras opzionali*** (provider aggiuntivi, Vault crittografico, chat REPL, template):
> ```sh
> # 4. Installazione degli Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Usa Bash4llm ⚡

---

### 2.1 Installazione Manuale

Se scarichi solo l'eseguibile singolo `bash4llm`, rendilo eseguibile applicando i permessi POSIX:

```sh
chmod +x bash4llm
```

---

### 2.2 Impostare la Chiave API

Bash4LLM⁺ ricerca la chiave API nell'ambiente. Puoi esportarla nel tuo file di configurazione della shell (es. `~/.bashrc`, `~/.bash_profile` o `~/.zshrc`):

```sh
export GROQ_API_KEY="la_tua_chiave_qui"
```

In alternativa, puoi salvare le chiavi API in modo cifrato su disco utilizzando il **Security Vault** integrato (vedi Sezione 4).

---

## 3. Struttura delle Directory

Alla prima esecuzione, Bash4LLM⁺ crea automaticamente l'albero di lavoro isolato nella directory di runtime (`bash4llm.d/`), applicando permessi restrittivi `700` (cartelle) e `600` (file):

```text
bash4llm.d/
├── config/                                # Configurazione e persistenza provider
│   ├── config                             # Variabili e parametri globali utente
│   ├── provider                           # Nome del provider attivo
│   ├── provider-url                       # URL delle API del provider attivo
│   ├── model.<provider>                   # Modello di default per il provider
│   ├── keys.enc                           # Database cifrato delle chiavi API (Vault)
│   ├── keys.rec                           # Chiave di ripristino offline cifrata (Vault)
│   ├── keys.dat                           # Payload cifrato delle chiavi API
│   ├── providers/                         # Cartella per configurazioni avanzate
│   │   └── hf_endpoints                   # Mappatura modelli/endpoint Hugging Face
│   └── ui_state/                          # File JSON di stato per GUI ed automazioni
│       ├── last_api.json                  # Stato dell'ultima chiamata API
│       ├── last_history.json              # Stato dell'ultimo output salvato
│       ├── provider_capabilities.json     # Capacità del provider attivo
│       └── threads/                       # Metadati ed indici dei thread
│           ├── index.json                 # Elenco dei thread attivi
│           └── <safe_thread_id>.json      # Metadati dello stato del singolo thread (SHA-256)
├── models/                                # Whitelist dei modelli per ciascun provider
│   └── <provider>.txt                     # Elenco modelli approvati
├── templates/                             # Prompt template riutilizzabili
├── history/                               # Cronologia delle risposte ed output
│   └── threads/                           # Storico conversazionale (.ndjson anonimizzato)
│       └── <safe_thread_id>.ndjson        # Registro della conversazione in NDJSON
├── var/                                   # Processi e file di runtime isolati
│   └── run/                              # Directory di runtime di processo (700)
│       └── locks/                         # Directory isolata dei file di blocco (700)
│           ├── models.lock                # Lock per l'aggiornamento dei modelli
│           ├── history.lock               # Lock per l'aggiornamento della cronologia
│           └── tmp.lock                   # Lock per allocazione file temporanei
├── tmp/                                   # Cartella temporanea sicura ad accesso esclusivo (700)
│   └── rates/                             # Tracciamento transazioni rate limiting (700)
│       └── <safe_thread_id>/              # Timestamp delle richieste per finestra scorrevole
└── extras/                                # Componenti aggiuntivi ed estensioni
    ├── manifest.sha256                    # Manifesto dell'integrità crittografica SHA-256
    ├── chat/                              # Interfaccia REPL TUI (tui-repl.sh)
    ├── hooks/                             # Moduli di estensione pre/post esecuzione (hook.sh)
    ├── security/                          # Vault ed helper di sicurezza (openssl-helper.sh)
    ├── providers/                         # Moduli provider esterni (Gemini, Hugging Face, Mistral)
    └── session/                           # Gestore avanzato di sessione (session-engine.sh)
```

---

## 4. Gestione Cifrata delle Chiavi (Security Vault)

Se hai installato gli Extras ed è disponibile il binario `openssl`, puoi evitare di conservare le chiavi API in chiaro nelle variabili d'ambiente utilizzando la console crittografica integrata:

```sh
./bash4llm --vault
```

### Funzionalità del Vault:
* **Cifratura At-Rest**: Le chiavi vengono cifrate in AES-256-CBC con derivazione PBKDF2 (100.000 iterazioni) e salvate in `bash4llm.d/config/keys.dat`.
* **Sblocco Sessione in RAM**: Puoi sbloccare il Vault per la sessione corrente di terminale eseguendo il sourcing dello script:
  ```sh
  . ./bash4llm
  ```
  Questo memorizza temporaneamente il token offuscato `_B4L_RT_CTX` nella memoria RAM della shell, bypassando le richieste di password fino alla chiusura del terminale.
* **Disabilitazione del Vault**: Puoi disabilitare il Vault impostando la variabile d'ambiente `BASH4LLM_VAULT_ENABLED=0`.

---

## 5. Installazione degli Extras (`--install-extras`)

Per attivare le funzionalità avanzate (la console Vault, la chat interattiva TUI, il Session Engine o i provider aggiuntivi come Gemini, Mistral e Hugging Face), installa il pacchetto Extras:

```sh
./bash4llm --install-extras
```

Se esegui l'eseguibile da una cartella diversa dal repository clonato, specifica il percorso esplicito della cartella `extras`:

```sh
./bash4llm --install-extras /percorso/di/sorgente/extras
```

### Comportamento di Sicurezza dell'Installer:
1. **Verifica di Integrità SHA-256**: Tutti i moduli copiati vengono verificati rispetto al manifesto crittografico `manifest.sha256`. Se un file risulta manomesso, l'installazione viene segnalata.
2. **Copia Atomica e Protetta**: I file vengono copiati sotto lock esclusivo applicando permessi restrittivi `700` alle cartelle/eseguibili e `600` ai file di configurazione e documentazione.
3. **Rifiuto dei Symlink**: L'installer rifiuta la copia di collegamenti simbolici per prevenire attacchi di Directory Traversal.

---

## 6. Troubleshooting e Risoluzione dei Problemi

### Errore di Sicurezza (Codice d'uscita 17 - BASH4LLM_ERR_SEC)
Se lo script si interrompe con il codice `17` (`BASH4LLM_ERR_SEC`), significa che è stata rilevata una violazione della politica di sicurezza:
* **Permessi troppo aperti**: Il file di configurazione o le directory sono scrivibili da gruppi o altri utenti (`group/world-writable`).
* **Symlink rilevato**: È presente un collegamento simbolico non autorizzato su un percorso critico.
* **Manomissione del codice**: Un modulo della cartella `extras/` non corrisponde al relativo digest SHA-256 nel file `manifest.sha256`.

Per ripristinare i permessi POSIX corretti, esegui:

```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config
```

### Blocco del Rate Limiter
Se invii un numero eccessivo di richieste all'interno di una finestra di 30 secondi, il limitatore di frequenza locale bloccherà l'esecuzione con il codice `17`. Puoi regolare il limite o bypassarlo definendo la variabile:

```sh
export BASH4LLM_RATE_LIMIT=10  # Consente 10 richieste ogni 30 secondi per thread
```

### Timeout sui Lock del Filesystem
Se ricevi un errore di timeout (`Exit Code 15`) durante l'accesso ai file di blocco a causa di operazioni concorrenti prolungate, puoi aumentare il tempo di attesa massimo (espresso in secondi):

```sh
export BASH4LLM_LOCK_TIMEOUT_HISTORY=30
```

---

## 7. Disinstallazione

Bash4LLM⁺ è completamente isolato e auto-confinato. Per rimuoverlo definitivamente dal sistema è sufficiente eliminare l'eseguibile e la sua cartella di lavoro:

```sh
rm -rf bash4llm.d
rm bash4llm
```

---

## 8. Licenza

Bash4LLM⁺ è un software libero distribuito sotto licenza [**GNU GPL v3**](LICENSE).
