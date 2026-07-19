[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# POLITICA DI SICUREZZA 🇮🇹 [🇬🇧](SECURITY-en.md)

## Politica di Sicurezza per Bash4LLM⁺

Bash4LLM⁺ è stato sviluppato adottando principi di progettazione rigorosi in materia di **sicurezza delle variabili**, **protezione delle informazioni in transito e in locale** ed **evitazione di iniezioni di codice**.  
Questo documento ne descrive il modello di minaccia, le assunzioni fondamentali del filesystem, le limitazioni note e i canali per la segnalazione privata di vulnerabilità.

---

## 1. Versioni supportate

Solo l'ultima versione stabile ufficiale rilasciata sul ramo `main` del repository riceve patch correttive e aggiornamenti di sicurezza.

---

## 2. Modello di minaccia (Threat Model)

Bash4LLM⁺ è progettato per operare in contesti **single-user** fidati:
*   Computer desktop e laptop personali.
*   Server personali, nodi di calcolo privati o istanze Docker a singolo proprietario.
*   Terminali locali protetti come Termux su dispositivi mobili personali (Android).
*   Ambienti di sviluppo WSL (Windows) o console utente standard Unix.

Bash4LLM⁺ **non** è progettato per:
*   Server multi-tenant condivisi con utenti ostili o non autorizzati.
*   Ambienti in cui utenti concorrenti non autorizzati dispongono di accesso in scrittura fisica alle stesse cartelle dello script.
*   Essere eseguito da utente `root` in contesti di rete esposti.

### Assunzioni fondamentali di sicurezza
Lo script assume che:
1.  L'utente che esegue lo script sia l'esclusivo proprietario e detentore dei diritti di scrittura sulla directory di lavoro principale `bash4llm.d/` e sulle sue cartelle di configurazione ed extras.
2.  I moduli provider posizionati nella cartella degli extras provengano esclusivamente da fonti controllate e fidate.
3.  Le variabili d'ambiente locali caricate in memoria non possano essere intercettate o manipolate da utenze locali ostili con privilegi superiori.

---

## 3. Mitigazioni di sicurezza implementate di serie

### ✔ Nessuna esecuzione del contenuto generato (RCE Prevention)
Bash4LLM⁺ si limita a convogliare, visualizzare ed eventualmente archiviare l'output testuale restituito dall'API LLM. Lo script **non esegue mai** l'output del modello all'interno della shell corrente, azzerando alla radice il rischio di vulnerabilità di tipo Remote Code Execution (RCE) derivanti da attacchi di Prompt Injection indiretti.

### ✔ Divieto assoluto del comando `eval`
Nessuna porzione del codice interno dello script principale o delle sue funzioni di parsing e caricamento dei moduli fa uso del comando `eval` o di analoghi meccanismi di interpretazione dinamica della stringa di comando, prevenendo tentativi di iniezione di codice Bash.

### ✔ Isolamento dei file temporanei (No `/tmp` globale)
Al fine di eliminare i rischi di dirottamento basati sull'uso di collegamenti simbolici (*Symlink Exploitation*) o collisioni di scrittura ad opera di processi concorrenti, lo script **non utilizza mai** la directory condivisa `/tmp` del sistema operativo. 
Tutte le transazioni, i file di errore di rete o le risposte grezze vengono elaborati all'interno della directory isolata temporanea di esecuzione (`RUN_TMPDIR`), creata come sottocartella locale di `bash4llm.d/tmp/` con permessi esclusivi `700` (`umask 077`).

### ✔ Sandbox di importazione dei moduli Provider
Per garantire che i moduli dei provider opzionali caricati dalla directory degli extras non possano inquinare il runtime principale con variabili globali instabili o eseguire codice arbitrario all'avvio, il caricamento avviene all'interno di una sotto-shell di sandbox isolata. 
Vengono estratte ed esportate nel guscio principale **esclusivamente le firme delle funzioni** autorizzate (`buildpayload_*`, `call_api_*`), ignorando qualsiasi istruzione globale posizionata al di fuori delle funzioni stesse.

### ✔ Crittografia simmetrica delle chiavi API (`--vault`)
Bash4LLM⁺ non richiede di memorizzare le chiavi API in chiaro nei file di configurazione. Attivando il modulo opzionale OpenSSL (`--vault`), le chiavi di autenticazione vengono inserite all'interno di un database crittografato simmetricamente (`keys.dat`). 
La protezione è garantita da Master Password con cifratura AES-256-CBC, derivazione PBKDF2 (100.000 iterazioni) e sale crittografico, prevenendo la sottrazione delle credenziali in caso di ispezione fisica o copia del disco. Il sblocco tramite token di sessione memorizzato in memoria (`_B4L_RT_CTX`) consente di bypassare l'inserimento costante della password senza compromettere la sicurezza a riposo.

### ✔ Protezione Termux (Directory Lock atomico)
Sui dispositivi Android/Termux, l'utility standard `flock` a livello di sistema operativo può fallire a causa di restrizioni di sicurezza del kernel o politiche di SELinux. 
Bash4LLM⁺ rileva automaticamente l'ambiente Termux disabilitando in trasparenza `flock` ed effettuando il fallback automatico sul meccanismo di lock atomico basato sulla creazione di directory esclusive (`mkdir` atomico), garantendo l'assoluta integrità dei log di thread NDJSON senza rischi di blocco del processo.

---

## 4. Limitazioni note

*   **Vulnerabilità TOCTOU (Time-of-Check to Time-of-Use):** Nonostante lo script effettui controlli di sicurezza rigorosi sui permessi di scrittura dei file prima di caricarli o scriverli, a livello di filesystem di base POSIX rimane una finestra infinitesimale in cui un attaccante con privilegi di root o accesso fisico concorrente alla cartella potrebbe teoricamente tentare la sostituzione del file tra la fase di controllo e quella di utilizzo.
*   **Il debug espone dati sensibili:** L'uso della modalità debug (`BASH4LLM_DEBUG=1` o `--debug`) disattiva la rimozione automatica dei file temporanei della transazione per consentire l'ispezione dell'output di curl. Si raccomanda di non mantenere la modalità debug attiva in contesti operativi reali poiché i file in `tmp/` rimarrebbero memorizzati su disco fino alla transazione successiva.

---

## 5. Raccomandazioni per la messa in sicurezza

1.  **Installa in una cartella utente non accessibile ad altri:**
    ```sh
    mkdir -p "$HOME/.local/bin"
    cp bash4llm "$HOME/.local/bin/"
    chmod 700 "$HOME/.local/bin/bash4llm"
    ```
2.  **Applica permessi restrittivi alla cartella di runtime:**
    ```sh
    chmod 700 "$HOME/bash4llm.d"
    chmod 600 "$HOME/bash4llm.d/config/config"
    ```
3.  **Utilizza regolarmente `--check-config`:**
    Esegui lo scanner statico integrato prima dell'avvio in ambienti sensibili per assicurarti che nessun file di configurazione sia modificabile da terze parti.

---

## 6. Segnalazione privata di vulnerabilità (Responsible Disclosure)

In caso di rilevamento di una potenziale vulnerabilità o criticità di sicurezza all'interno dello script core o delle sue estensioni, si prega di effettuare una segnalazione in modo **riservato e privato** per proteggere l'integrità degli utenti attivi.

#### Contatto per la segnalazione privata:
*   **Email:** `opensource@cevangel.anonaddy.me`
*   **Oggetto:** `[Bash4LLM Security Report]`

Ti chiediamo gentilmente di includere nella segnalazione:
1.  Una descrizione dettagliata della natura della vulnerabilità.
2.  Una Proof of Concept (PoC) o la sequenza di comandi necessari per riprodurre lo scenario di vulnerabilità.
3.  L'impatto stimato ed eventuali suggerimenti per la patch correttiva.

Ci impegniamo a rispondere per l'analisi iniziale **entro 72 ore** dalla ricezione della segnalazione e a coordinare insieme il rilascio della patch prima di diffondere pubblicamente i dettagli della vulnerabilità.
