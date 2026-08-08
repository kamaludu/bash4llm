[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

# Politica di Sicurezza per Bash4LLM⁺  🇮🇹 [🇬🇧](SECURITY-en.md)

Questo documento descrive il modello di minaccia, le assunzioni del filesystem, le mitigazioni di sicurezza integrate, le limitazioni note e le procedure per la segnalazione di vulnerabilità.

---

## 1. Versioni supportate

La manutenzione e il rilascio di patch di sicurezza vengono forniti esclusivamente per l'ultima versione stabile presente sul ramo `main` del repository.

---

## 2. Modello di minaccia (Threat Model)

Bash4LLM⁺ è progettato per operare in contesti **single-user** controllati:
* Computer desktop e laptop personali.
* Server dedicati, nodi di calcolo privati o istanze Docker a singolo proprietario.
* Terminali locali sandboxed come Termux su dispositivi Android personali.
* Ambienti di sviluppo WSL (Windows) o console utente standard Unix/Linux/BSD.

Bash4LLM⁺ **non è progettato** per:
* Ambienti server multi-tenant condivisi con utenti non autorizzati.
* Sistemi in cui utenti concorrenti dispongono di accesso in scrittura fisica alla directory di lavoro dello script.
* Esecuzione da parte dell'utente `root` in contesti di rete esposti.

### Assunzioni di sicurezza del filesystem
Il runtime presuppone che:
1. L'utente che esegue lo script sia l'esclusivo proprietario e detentore dei diritti di accesso sulla directory di lavoro principale (`bash4llm.d/`) e sulle relative sottocartelle.
2. I moduli esterni posizionati nella cartella `extras/` provengano da fonti verificate, corrispondano alle impronte crittografiche registrate e superino la convalida della firma Ed25519 d'autore. I moduli utente locali non tracciati dal manifesto vendor risiedono nel dominio separato `local-extras/`.
3. Lo spazio di memoria RAM del processo utente non sia accessibile a utenze locali non privileged.

---

## 3. Mitigazioni di sicurezza integrate

### Redazione delle credenziali nei vettori d'argomento del processo (`argv`)
Tutte le chiamate di rete HTTP (sincrone, streaming, aggiornamento modelli e validazione chiavi) sono convogliate nella funzione centrale `_exec_curl_secure()`. Le chiavi API ed i token Bearer vengono scritti esclusivamente in file di header temporanei con permessi `0600` e inoltrati a `curl` tramite reindirizzamento di File Descriptor (`/dev/fd/3`). In questo modo, le credenziali **non compaiono mai nei vettori d'argomento della riga di comando (`argv`)** e sono protette dall'ispezione della tabella dei processi (`ps aux` o `/proc/<pid>/cmdline`).

### Prevenzione della Remote Code Execution (RCE)
Bash4LLM⁺ riceve, visualizza ed eventualmente archivia l'output testuale restituito dalle API. Lo script **non esegue mai** il testo generato dal modello all'interno dell'interprete shell, prevenendo vulnerabilità RCE derivanti da attacchi di Prompt Injection.

### Assenza di costrutti di valutazione dinamica (`eval`)
In conformità all'invariante di sicurezza **[INV-3]**, è vietata l'introduzione di nuovi costrutti `eval`. L'unica istruzione preesistente per il ripristino delle trap dei segnali è isolata e documentata. Il caricamento dei moduli e l'analisi dell'output degli hook utilizzano un parser Zero-Eval basato su whitelist.

### Isolamento dei file temporanei e divieto di uso di `/tmp`
In conformità all'invariante **[INV-2]**, lo script **non utilizza mai la directory condivisa di sistema `/tmp`**. Tutti i file temporanei, le risposte grezze e i file di errore vengono allocati all'interno della directory isolata di runtime (`RUN_TMPDIR`), creata come sottocartella locale di `bash4llm.d/tmp/` con permessi restrittivi `0700` e file a permessi `0600` (`umask 077`).

### Caricamento isolato dei moduli, firma Ed25519 e filtro whitelist (Fail-Closed)
I moduli dei provider e gli hook caricati dalla directory `extras/` vengono analizzati in una copia di staging temporanea isolata (protezione anti-TOCTOU). Prima di ogni caricamento:
1. La funzione `verify_module_integrity()` esegue la verifica della sicurezza del percorso (`validate_path_security`), la convalida della firma crittografica Ed25519 del manifesto (`_verify_manifest_signature` con chiave `official-ed25519.pub`) e il controllo dell'hash SHA-256 rispetto a `extras/manifest.sha256`.
2. Viene verificato il contratto di versione dell'API del provider (`BASH4LLM_PROVIDER_API_VERSION`).
3. Le definizioni di funzione vengono filtrate tramite whitelist (`comm -13`) per impedire l'esportazione di funzioni non autorizzate (function hijacking).

Qualsiasi manomissione, firma non valida o fallimento nell'integrità arresta immediatamente l'esecuzione con codice di uscita `17` (`BASH4LLM_ERR_SEC`). La firma può essere resa obbligatoria impostando `BASH4LLM_REQUIRE_MANIFEST_SIG=1`.

### Protezione delle funzioni di guardia a runtime (`readonly -f`)
Al termine dell'inizializzazione del Core, la funzione `_lock_security_guards()` marca le funzioni di sicurezza, mediazione, rete e gestione del filesystem (`_exec_curl_secure`, `verify_module_integrity`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `read_secure_input`, `enforce_network_policy`, `execute_isolated_hook`) come `readonly -f`. Questo impedisce qualsiasi tentativo di sovrascittura o cancellazione in memoria delle funzioni di guardia da parte di moduli esterni o script derivati.

### Cifratura locale delle chiavi API ed enforcement del Vault (`--vault`)
Tramite il modulo opzionale basato su OpenSSL (`--vault`), le chiavi API possono essere memorizzate in forma cifrata sul filesystem (`keys.dat`). La protezione utilizza l'algoritmo AES-256-CBC con derivazione PBKDF2 (100.000 iterazioni) e Master Password. Il riutilizzo del contesto di sessione sbloccato (`_B4L_RT_CTX`) consente l'uso continuativo senza scrittura di credenziali in chiaro su disco. Attivando la variabile `export BASH4LLM_REQUIRE_VAULT=1`, il sistema vieta tassativamente il recupero di chiavi da variabili d'ambiente non cifrate.

### Anonimizzazione PII degli ID Thread
Per prevenire l'esposizione di informazioni personali identificabili (PII) o percorsi riservati nei metadati e nel registro delle conversazioni, la funzione `anonymize_thread_id` converte ogni ID thread in un hash crittografico SHA-256/MD5 prima di qualsiasi scrittura su disco.

### Rate Limiting locale a finestra scorrevole
La funzione `check_local_rate_limit` traccia le transazioni dei thread nella cartella isolata `tmp/rates/` ed applica un limite di frequenza configurabile (finestra di 30 secondi). Il superamento del limite interrompe la richiesta con codice di uscita `17`.

### Validazione dell'input file e filtro dati binari
Prima dell'elaborazione di file forniti tramite l'opzione `-f` o argomenti posizionali, la funzione `validate_file_input` verifica che il file non sia vuoto e non contenga byte nulli o caratteri di controllo binari non validi, bloccando immediatamente l'esecuzione con errore `17` in caso di anomalie.

### Sanitizzazione Output ed Estensioni Deterministiche (Scintilla-Ready)
Il runtime supporta il filtraggio ANSI zero-eval dell'output (`--sanitize` tramite `output-sanitizer.sh`), la validazione sintattica della risposta dell'LLM (`--validate-sml` per lo standard SML v2.0 e `--validate-regex`), e l'emissione della diagnostica di errore in formato JSON strutturato (`--json-diagnostics`).

### Gestione della memoria per l'input interattivo (Session Sandboxing)
L'acquisizione manuale delle credenziali avviene tramite mascheramento dell'input TTY (`stty -echo`). Quando l'utente sceglie di esportare la chiave per la sessione corrente, lo script esegue la sostituzione del processo via `exec "${SHELL:-bash}"`, mantenendo la variabile esclusivamente nella RAM della sotto-shell senza scriverla nei file di cronologia del terminale (`.bash_history`).

### Gestione della concorrenza su Termux (Android)
In ambienti Android/Termux, dove `flock` può essere soggetto a restrizioni del kernel o di SELinux, la gestione dei lock viene reindirizzata in modo trasparente sul meccanismo atomico basato su directory (`mkdir`).

---

## 4. Limitazioni note

* **Finestra di gara su filesystem POSIX (TOCTOU):** Sui filesystem POSIX standard, esiste una finestra teorica di gara (Time-of-Check to Time-of-Use) tra la verifica dei permessi di un file e la successiva operazione di lettura/scrittura. Tale rischio è mitigato dall'uso di directory isolate `0700` sotto il controllo esclusivo dell'utente e dal caricamento dei moduli tramite copie di staging temporanee create con permessi `0600`.
* **Persistenza dei file temporanei in modalità Debug:** L'attivazione della modalità di debug (`--debug` o `DEBUG=1`) preserva i file temporanei della transazione all'interno di `RUN_TMPDIR` per consentire l'ispezione delle risposte. Si raccomanda di disattivare la modalità debug in ambienti di produzione.

---

## 5. Raccomandazioni per la configurazione sicura

1. **Installazione in directory utente riservata:**
   ```sh
   mkdir -p "$HOME/.local/bin"
   cp bash4llm "$HOME/.local/bin/"
   chmod 700 "$HOME/.local/bin/bash4llm"
   ```
2. **Permessi restrittivi sulla cartella di dati:**
   ```sh
   chmod 700 "$HOME/bash4llm.d"
   chmod 600 "$HOME/bash4llm.d/config/config"
   ```
3. **Attivazione delle policy di sicurezza stringenti:**
   ```sh
   export BASH4LLM_REQUIRE_VAULT=1         # Forza l'uso esclusivo del Vault cifrato
   export BASH4LLM_REQUIRE_MANIFEST_SIG=1  # Rende vincolante la firma Ed25519 del manifesto
   ```
4. **Verifica della configurazione:**
   Eseguire periodicamente il controllo statico dei permessi tramite il comando:
   ```sh
   ./bash4llm --check-config
   ```

---

## 6. Protezione dell'eseguibile principale

Per prevenire modifiche non autorizzate allo script principale da parte di processi non privilegiati nel sistema, è possibile applicare i seguenti permessi e controlli di immutabilità:

### Linux (GNU/Linux)
```bash
sudo chown root:root /path/to/bash4llm
sudo chmod 755 /path/to/bash4llm
sudo chattr +i /path/to/bash4llm
```

### macOS / BSD
```bash
sudo chown root:wheel /path/to/bash4llm
sudo chmod 755 /path/to/bash4llm
sudo chflags schg /path/to/bash4llm
```

### Termux (Android)
```bash
chmod 500 ~/bash4llm
```

### WSL / Cygwin
```bash
setfacl -b /path/to/bash4llm 2>/dev/null
chmod 755 /path/to/bash4llm
```

---

## 7. Segnalazione di vulnerabilità (Responsible Disclosure)

In caso di individuazione di potenziali vulnerabilità di sicurezza nel Core o nei moduli estesi, si prega di inviare una segnalazione riservata.

* **Email:** `opensource@cevangel.anonaddy.me`
* **Oggetto:** `[Bash4LLM Security Report]`

Informazioni richieste nella segnalazione:
1. Descrizione tecnica della vulnerabilità.
2. Procedura di riproduzione o Proof of Concept (PoC).
3. Valutazione dell'impatto ed eventuali proposte di correzione.

L'analisi iniziale verrà avviata entro 72 ore dalla ricezione della segnalazione, coordinando il rilascio della patch prima di qualsiasi divulgazione pubblica.
