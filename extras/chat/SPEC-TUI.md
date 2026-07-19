[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

[![Bash](https://img.shields.io/badge/TUI%20REPL-Bash4LLM-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](SPEC-TUI.md)

## 📟 Specifica Tecnica — Modulo TUI (`tui-repl.sh`) per `bash4llm`

Questo documento definisce le specifiche architettoniche, i flussi di controllo, la gestione dello stato, il sistema di internazionalizzazione e il comportamento interattivo del modulo TUI REPL (`tui-repl.sh`) per lo strumento `bash4llm`.

---

### 1. Architettura ed Integrazione (Hook & Sourcing)

Il modulo TUI è concepito come un componente esterno opzionale integrato con il nucleo funzionale (core) dell'applicazione.

* **Isolamento dei Processi:** Quando l'utente invoca `bash4llm --chat`, il core rileva la presenza dello script `tui-repl.sh` in `bash4llm.d/extras/chat/tui-repl.sh` e lo esegue come **processo figlio indipendente** (tramite `bash tui-repl.sh "$@"`). Questo garantisce l'isolamento dello scope delle variabili e impedisce che eventuali eccezioni o interruzioni della TUI compromettano l'integrità del processo chiamante.
* **Risoluzione del Percorso del Core:** Il modulo TUI individua il file principale di `bash4llm` leggendo la variabile d'ambiente `BASH4LLM_CORE_SCRIPT` esportata dal processo padre. In caso di esecuzione autonoma fuori dal core, implementa un algoritmo di fallback che risale l'albero delle directory fino alla radice del repository per localizzare il core.
* **Sourcing Guard per il Riutilizzo del Codice:** All'avvio, il modulo TUI importa le utility, i lock e le funzioni di rete di `bash4llm` eseguendo il `source` del core sotto la guardia ambientale:
  ```bash
  export BASH4LLM_SOURCE_ONLY=1
  ```
  Questo meccanismo interrompe l'esecuzione del core subito prima del parsing degli argomenti CLI, consentendo alla TUI di ereditarne le librerie e le funzioni interne (es. `call_api_streaming`, `thread_append`, `thread_read_window`) senza alcuna duplicazione di codice.

---

### 2. Requisiti e Compatibilità

* **Sistemi Operativi:** macOS, Linux (distribuzioni basate su Debian/RedHat/Arch), Termux (Android), WSL (Windows Subsystem for Linux) ed esecuzione remota via SSH.
* **Interprete:** GNU Bash 4.x o superiore (necessario per il supporto nativo agli array associativi).
* **Dipendenze Strumentali:** `jq`, `curl`, `base64`, `less` (o `more` in alternativa).

---

### 3. Trasferimento dello Stato e Variabili d'Ambiente

Il modulo TUI eredita lo stato dal processo padre e ne gestisce le variazioni locali tramite le seguenti variabili d'ambiente esportate:

| Variabile d'Ambiente | Descrizione | Default Locale in TUI |
| :--- | :--- | :--- |
| `BASH4LLM_ACTIVE_THREAD` | ID del thread di chat attivo. | Se vuota, avvia il Wizard dei Thread. |
| `BASH4LLM_ACTIVE_MODEL` | Modello LLM selezionato dal core. | Risolto dinamicamente tramite `resolve_model`. |
| `BASH4LLM_ACTIVE_TEMPERATURE` | Temperatura di generazione (TURE). | `1.0` |
| `BASH4LLM_LANG` | Codice della lingua dell'interfaccia (i18n). | Rilevato o richiesto al primo avvio. |
| `BASH4LLM_HISTORY_DIR` | Percorso della directory della cronologia. | `bash4llm.d/history` |
| `BASH4LLM_CONFIG_DIR` | Percorso della directory di configurazione. | `bash4llm.d/config` |

---

### 4. Sistema di Internazionalizzazione (i18n) Sicuro

Il modulo implementa un sistema multilingue isolato e protetto che supporta cinque lingue: **Inglese (default), Italiano, Spagnolo, Francese e Tedesco**.

* **Co-localizzazione delle Risorse:** I file di traduzione locali (formato `.properties`) sono memorizzati all'interno della directory del modulo stesso, isolandone il contesto:
  ```text
  bash4llm.d/extras/chat/langs/
  ├── en.properties  # Inglese (Default & Fallback)
  ├── de.properties  # Tedesco
  ├── es.properties  # Spagnolo
  ├── fr.properties  # Francese
  └── it.properties  # Italiano
  ```
* **Parser Dichiarativo Isolato:** La lettura dei file di risorsa avviene riga per riga tramite ciclo `while read` nativo. Non viene mai usato `source` o `eval` per caricare le traduzioni, neutralizzando attacchi di iniezione di codice arbitrario.
* **Sanitizzazione e Validazione:**
  * Il codice lingua viene forzato a due caratteri alfabetici minuscoli (`^[a-z]{2}$`) tramite espressione regolare, prevenendo attacchi di *Directory Traversal* (es. `LANG=../../`).
  * Ogni chiave letta dal file viene ripulita da caratteri speciali mantenendo solo caratteri alfanumerici e underscore (`tr -d -c 'A-Za-z0-9_'`).
* **Lookup ad alte prestazioni:** Le coppie chiave-valore vengono caricate in memoria all'avvio in un array associativo globale (`declare -A T_MSG`). L'interrogazione avviene tramite la funzione `_msg()`. Sotto `set -u` (nounset), l'esistenza della chiave viene verificata tramite espansione condizionale (`${T_MSG[$key]+x}`) prima dell'accesso, prevenendo crash per variabili unbound.
* **Inizializzazione al Primo Avvio:** Se la variabile `BASH4LLM_LANG` non è presente nel file `config`, viene mostrato immediatamente un menu di scelta numerato (1-5). La scelta viene salvata atomicamente nel file di configurazione per le esecuzioni successive.
* **Strategia di Fallback a Cascata:** Se un file di lingua o una chiave specifica sono mancanti, il sistema esegue il fallback automatico sulla lingua inglese (`en.properties`) e, in ultima istanza, restituisce la chiave testuale stessa come testo letterale.

---

### 5. Interfaccia Visiva e Rendering

* **Scrittura Sequenziale Standard:** L'interfaccia utente rifiuta l'uso di librerie a schermo intero (come `ncurses` o sequenze di posizionamento assoluto ANSI tramite `tput`). Tutto il rendering visivo si affida al normale scorrimento verticale (*vertical scrolling*) del terminale.
* **Resistenza ai Ridimensionamenti (`SIGWINCH`):** L'approccio sequenziale rende la TUI nativamente immune a sfarfallii visivi causati dal ridimensionamento della finestra o dall'uso su terminali mobili e connessioni SSH instabili.
* **Conformità NO_COLOR:** La TUI adotta le variabili di stile ANSI caricate dal core (`C_LOGO`, `C_BCYAN`, `C_BGREEN`, `C_RST`). Se l'ambiente rileva l'impostazione `NO_COLOR` o se gli output non sono associati a una TTY interattiva, i colori vengono disattivati automaticamente.

---

### 6. Gestione Sincrona del Flusso e Interruzioni

Il REPL opera secondo un modello sincrono e sequenziale:
```
Attesa Input Utente -> Compilazione Contesto -> Chiamata API (Sincrona/Bloccante) -> Output Stream -> Nuovo Input
```
* **Gestione Dinamica dei Segnali (`SIGINT` / `Ctrl+C`):**
  1. *Fase di Input Passivo (Prompt):* L'interruzione `Ctrl+C` viene gestita dal trap globale configurato nella TUI: interrompe l'inserimento corrente, va a capo e ripresenta il prompt vuoto `Tu > ` (localizzato) senza terminare la shell REPL.
  2. *Fase di Generazione Attiva (Chiamata di Rete):* Prima di invocare `call_api_streaming` o `perform_request_once`, la TUI disattiva temporaneamente il proprio trap per consentire alla pipeline del core di intercettare il `Ctrl+C`. Il core cattura l'interruzione, arresta la pipeline di `curl`, restituisce l'exit code controllato `130` e restituisce il controllo alla TUI, che si riposiziona sul prompt in modo pulito.

---

### 7. Componenti e Logica dei Menu

#### 7.1. Wizard di Selezione Thread (Startup)
Se all'avvio `THREAD_ID` non è popolato, lo script esegue `load_threads_wizard` per la gestione guidata dello storico:
1. Legge i file `.ndjson` presenti nella directory `threads/`, ordinandoli per data di ultima modifica decrescente (i più recenti in alto).
2. Mostra un elenco di thread paginato a gruppi di **10 thread per pagina**.
3. Ciascuna riga descrive lo stato del thread nel formato sequenziale:
   ```
   [Indice] <data_creazione> > <Titolo_thread> > <data_ultimo_messaggio>
   ```
   * *Data Creazione:* Ricavata dal timestamp `.ts` della prima riga del file NDJSON, formattata come `YYYY-MM-DD HH:MM` (tramite elaborazione stringa portabile `_format_ts`).
   * *Titolo:* Estratto dal file metadati JSON `ui_state/threads/<THREAD_ID>.json`. Se assente, estrae il primo messaggio utente dal file NDJSON (troncato a 35 caratteri); in caso di ulteriore assenza, mostra un default indicando l'ID.
   * *Data Ultimo Messaggio:* Ricavata dal timestamp `.ts` dell'ultima riga del file NDJSON, formattata in modo identico.
4. **Navigazione:** Gestita tramite input rapidi da tastiera: `+` o `n` (pagina successiva), `-` o `p` (pagina precedente), `c` (crea un nuovo thread vuoto con ID randomizzato), oppure l'inserimento dell'indice numerico per caricare la conversazione.

#### 7.2. Menu di Configurazione (`/config`)
Fornisce un menu interattivo numerato (**1-11**) richiamabile durante la chat per modificare dinamicamente i parametri del modulo LLM:
1. **Changer Provider:** Scelta del Provider attivo (verifica la presenza nei provider registrati).
2. **Change LLM Model:** Scelta del Modello (valida la compatibilità testuale tramite `validate_model_dispatch`).
3. **Manage API Key:** Inserimento o aggiornamento manuale della Chiave API del provider selezionato (scrive la variabile d'ambiente dinamica corrispondente).
4. **Change UI Language:** Selezione interattiva della lingua dell'interfaccia (ricarica immediatamente il dizionario delle traduzioni).
5. **Change Temperature:** Modifica del parametro di temperatura.
6. **Change Max Tokens:** Impostazione del limite dei token di risposta.
7. **Change Save Threshold:** Valore di soglia in byte per il salvataggio automatico dello storico.
8. **Change Output Format:** Scelta del formato di output (`text`, `raw`, `json`, `pretty`).
9. **Refresh Model List:** Esecuzione del Refresh dei modelli (invoca la chiamata API tramite `refresh_models_dispatch`).
10. **List Locally Cached Models:** Visualizzazione dei modelli installati localmente (`list_models_cli`).
11. **Return to Chat:** Chiude il menu e ritorna al prompt.

#### 7.3. Menu di Gestione Thread (`/thread` o `/threads`)
Consolida le funzionalità di controllo del flusso di dialogo in un sottomenu strutturato (**1-6**):
1. **Rinomina Thread Attivo:** Aggiorna il titolo del thread attivo (scrive atomicamente nel file di metadati della UI).
2. **Elimina Thread Attivo:** Eliminazione fisica del file NDJSON e dei metadati associati su disco (previa doppia conferma interattiva). Al termine, ricarica il Wizard dei Thread.
3. **Avvia Nuovo Thread:** Generazione istantanea di un nuovo thread vuoto con ID casuale.
4. **Elenca e Leggi Thread passati:** Mostra l'elenco dei thread su disco e ne consente la lettura in modalità sicura tramite il pager `less -R`.
5. **Carica Thread passato:** Avvia il Wizard interattivo per selezionare e riprendere un thread di conversazione precedente.
6. **Ritorna al Prompt:** Chiude il menu e ritorna alla sessione di chat attiva.

---

### 8. Comandi Speciali (Slash Commands)

La riga inserita dall'utente viene intercettata dal parser locale del ciclo REPL. I comandi speciali implementati sono:

* **/exit o /quit:** Chiude in sicurezza la sessione di chat e termina il processo TUI.
* **/clear:** Pulisce lo schermo del terminale, ristampando il banner e lo stato corrente. **Non altera i dati del thread su disco**.
* **/thread o /threads:** Apre il sottomenu interattivo consolidato per la gestione del thread attivo e storico.
* **/undo:** Rimuove l'ultimo turno di conversazione (l'ultimo prompt utente e la corrispettiva risposta dell'assistente) dal file NDJSON del thread, aggiornando la cache del modulo di contesto.
* **/status:** Mostra le configurazioni attive, i percorsi e i metadati del thread corrente (ID, numero di messaggi, dimensione in byte e lo stato del system prompt).
* **/system [\<prompt\>]:** Visualizza il system prompt attivo o ne imposta uno nuovo per la durata del thread corrente.
* **/model \<name\>:** Consente di cambiare istantaneamente il modello LLM in uso dopo averne validato la compatibilità.
* **/temperature o /ture \<value\>:** Imposta il valore di temperatura di generazione per il thread attivo.
* **/max \<value\>:** Imposta il limite di token per le risposte.
* **/threshold \<value\>:** Imposta la soglia di salvataggio automatico.
* **/format \<format\>:** Cambia il formato di rendering dell'output.
* **/file \<path\> [\<prompt\>]:** Legge il file specificato (limite di 100 KB), ne concatena l'eventuale prompt opzionale e lo invia al modello LLM.
* **/block:** Entra in modalità di input multilinea (blocco). Consente di incollare o digitare testi complessi. La modalità si conclude digitando `/end` su una riga vuota.
* **/edit:** Apre l'editor di testo di sistema (definito in `$EDITOR`, con fallback su `nano` o `vi`) per consentire la composizione avanzata del prompt. All'uscita dell'editor, il testo salvato viene inviato al modello.
* **/help o /?:** Mostra a schermo in modo sequenziale ed ordinato la legenda dei comandi interattivi abilitati.

---

### 9. Persistenza, Stato e Cronologia Comandi

* **Database dei Messaggi:** Ogni conversazione viene scritta e aggiornata in tempo reale in formato NDJSON all'interno della directory `threads/` del database di `bash4llm`:
  ```
  bash4llm.d/history/threads/<THREAD_ID>.ndjson
  ```
  Il modulo TUI delega la scrittura delle interazioni a `thread_append` (o al modulo di sessione `session-engine.sh` se rilevato e compatibile), preservando la firma dei dati e le logiche dei lock di concorrenza.
* **Isolamento della Cronologia REPL (`tui_history`):** Per garantire la possibilità di navigare nello storico delle domande digitate all'interno della TUI usando le frecce della tastiera, impedendo al contempo che i comandi interni e i cicli di valutazione della TUI sporchino la cronologia, viene adottato un meccanismo di isolamento rigoroso:
  * Viene impostato permanentemente il comando **`set +o history`** all'avvio dello script, disabilitando la registrazione automatica delle istruzioni di Bash.
  * All'avvio di `run_repl()`, il buffer in memoria viene svuotato con `history -c` e popolato solo con i dati puliti dello storico letti da `history -r "$HISTFILE"`.
  * La registrazione dei soli prompt digitati dall'utente avviene manualmente all'interno del loop REPL tramite le istruzioni esplicite `history -s "$userline"` e `history -w "${HISTFILE}"` (salvo quando è attiva la modalità `/private`).

---

### 10. Sicurezza e Meccanismi di Protezione

La TUI implementa controlli rigorosi per garantire l'integrità del sistema host durante l'interazione interattiva:

* **Limitazione dei File Allegati (/file):** Per evitare un consumo eccessivo di memoria RAM durante l'assemblaggio del payload JSON o crash dell'interprete `jq`, lo script impone un limite hardware rigido di **100 KB** per qualsiasi file caricato tramite il comando `/file`. I file che superano questa soglia vengono rifiutati immediatamente prima del caricamento in memoria.
* **Isolamento dell'Editor di Testo (/edit):** La scrittura temporanea del prompt tramite editor esterno avviene in una directory di runtime protetta (allineata a `BASH4LLM_TMPDIR`), con permessi di acesso ristretti all'utente corrente (`chmod 600`). Il file temporaneo viene rimosso in modo deterministico non appena il testo viene importato nel REPL.
* **Neutralizzazione delle Sotto-shell nei Dizionari:** Le stringhe all'interno dei file `.properties` sono trattate come costanti letterali pure. Eventuali costrutti di subshell incorporati (es. `$(comando)` o `` `comando` ``) non vengono valutati all'atto del parsing, eliminando la possibilità di attacchi di iniezione di comandi tramite file di traduzione manipolati.

---

### 11. Procedure di Deploy e Test di Conformità

Prima di considerare il modulo TUI pronto per l'ambiente di produzione, è necessario eseguire la seguente matrice di conformità:

1. **Verifica dello Strict Mode (`set -u`):**
   Eseguire lo script in un ambiente privo di variabili esportate per assicurarsi che nessuna chiamata a funzioni interne provochi l'interruzione dello script a causa di variabili non dichiarate. Tutte le espansioni di parametro devono utilizzare valori de fallback sicuri (es. `${VARIABLE:-default}`).
2. **Test di Integrità dei Lock:**
   Simulare l'avvio simultaneo di due istanze del REPL sullo stesso thread NDJSON per verificare che il meccanismo di lock atomico (`atomic_write` e directory-lock) impedisca la corruzione del file di storico o la sovrascrittura incrociata dei dati.
3. **Conformità dei Permessi di Scrittura:**
   Verificare che i file creati dinamicamente (`tui_history`, i file metadati JSON dei thread e i file NDJSON) siano generati con maschera di protezione restrittiva (`umask 077` o `chmod 600`), impedendo l'accesso in lettura e scrittura ad altri utenti del sistema host.
