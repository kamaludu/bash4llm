[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

# Politica di Sicurezza per Bash4LLM⁺  🇮🇹 [🇬🇧](SECURITY-en.md)

Bash4LLM⁺ è sviluppato adottando principi di progettazione definiti nell'**Architecture Specification (Edition 2026.1)** in materia di isolamento delle variabili, protezione delle informazioni in transito e sul filesystem, ed eliminazione dei vettori di iniezione di codice.

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
2. I moduli esterni posizionati nella cartella `extras/` provengano da fonti verificate e corrispondano alle impronte crittografiche registrate.
3. Lo spazio di memoria RAM del processo utente non sia accessibile a utenze locali non privilegiate.

---

## 3. Mitigazioni di sicurezza integrate

### Redazione delle credenziali nei vettori d'argomento del processo (`argv`)
Tutte le chiamate di rete HTTP (sincrone, streaming, aggiornamento modelli e validazione chiavi) sono convogliate nella funzione centrale `_exec_curl_secure()`. Le chiavi API ed i token Bearer vengono scritti esclusivamente in file di header temporanei con permessi `0600` e inoltrati a `curl` tramite reindirizzamento di File Descriptor (`/dev/fd/3`). In questo modo, le credenziali **non compaiono mai nei vettori d'argomento della riga di comando (`argv`)** e sono protette dall'ispezione della tabella dei processi (`ps aux` o `/proc/<pid>/cmdline`).

### Prevenzione della Remote Code Execution (RCE)
Bash4LLM⁺ riceve, visualizza ed eventualmente archivia l'output testuale restituito dalle API. Lo script **non esegue mai** il testo generato dal modello all'interno dell'interprete shell, prevenendo vulnerabilità RCE derivanti da attacchi di Prompt Injection.

### Assenza di costrutti di valutazione dinamica (`eval`)
In conformità all'invariante di sicurezza **[INV-3]**, è vietata l'introduzione di nuovi costrutti `eval`. L'unica istruzione preesistente per il ripristino delle trap dei segnali è isolata e documentata.

### Isolamento dei file temporanei e divieto di uso di `/tmp`
In conformità all'invariante **[INV-2]**, lo script **non utilizza mai la directory condivisa di sistema `/tmp`**. Tutti i file temporanei, le risposte grezze e i file di errore vengono allocati all'interno della directory isolata di runtime (`RUN_TMPDIR`), creata come sottocartella locale di `bash4llm.d/tmp/` con permessi restrittivi `0700` e file a permessi `0600` (`umask 077`).

### Caricamento isolato dei moduli e verifica dell'integrità (Fail-Closed)
I moduli dei provider e gli hook caricati dalla directory `extras/` vengono analizzati in una sotto-shell isolata prima dell'importazione delle sole definizioni di funzione. Prima di ogni caricamento, la funzione `verify_module_integrity()` esegue la verifica della sicurezza del percorso e la validazione crittografica dell'hash SHA-256 rispetto a `extras/manifest.sha256`. Qualsiasi manomissione o fallimento del calcolo dell'hash arresta immediatamente l'esecuzione con codice di uscita `17` (`BASH4LLM_ERR_SEC`).

### Protezione delle funzioni di guardia a runtime (`readonly -f`)
Al termine dell'inizializzazione del Core, la funzione `_lock_security_guards()` marca le funzioni di sicurezza, mediazione e gestione del filesystem come `readonly -f`. Questo impedisce qualsiasi tentativo di sovrascrittura o cancellazione in memoria delle funzioni di guardia da parte di moduli esterni o script derivati.

### Cifratura locale delle chiavi API (`--vault`)
Tramite il modulo opzionale basato su OpenSSL (`--vault`), le chiavi API possono essere memorizzate in forma cifrata sul filesystem (`keys.dat`). La protezione utilizza l'algoritmo AES-256-CBC con derivazione PBKDF2 (100.000 iterazioni) e Master Password. Il riutilizzo del contesto di sessione sbloccato (`_B4L_RT_CTX`) consente l'uso continuativo senza scrittura di credenziali in chiaro su disco.

### Gestione della memoria per l'input interattivo (Session Sandboxing)
L'acquisizione manuale delle credenziali avviene tramite mascheramento dell'input TTY (`stty -echo`). Quando l'utente sceglie di esportare la chiave per la sessione corrente, lo script esegue la sostituzione del processo via `exec "${SHELL:-bash}"`, mantenendo la variabile esclusivamente nella RAM della sotto-shell senza scriverla nei file di cronologia del terminale (`.bash_history`).

### Gestione della concorrenza su Termux (Android)
In ambienti Android/Termux, dove `flock` può essere soggetto a restrizioni del kernel o di SELinux, la gestione dei lock viene reindirizzata in modo trasparente sul meccanismo atomico basato su directory (`mkdir`).

---

## 4. Limitazioni note

* **Finestra di gara su filesystem POSIX (TOCTOU):** Sui filesystem POSIX standard, esiste una finestra teorica di gara (Time-of-Check to Time-of-Use) tra la verifica dei permessi di un file e la successiva operazione di lettura/scrittura. Tale rischio è mitigato dall'uso di directory isolate `0700` sotto il controllo esclusivo dell'utente.
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
3. **Verifica della configurazione:**
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
