# Specifica Tecnica — Modulo TUI (`tui-repl.sh`) per `bash4llm`

Questo documento definisce le specifiche architettoniche, i flussi di controllo, la gestione dello stato e il comportamento visivo del modulo di interfaccia utente interattivo (`tui-repl.sh`) per lo strumento `bash4llm`.

---

## 1. Architettura ed Integrazione (Hook)

Il modulo TUI è concepito come un componente esterno opzionale separato dal nucleo funzionale (core) dell'applicazione.

* **Isolamento dei Processi:** Quando l'utente invoca `bash4llm --chat`, il core rileva la presenza dello script `tui-repl.sh` in `bash4llm.d/extras/chat/tui-repl.sh` e lo esegue come **processo figlio indipendente** (tramite `bash tui-repl.sh "$@"`). Questo approccio garantisce l'isolamento dello scope delle variabili e impedisce che eventuali interruzioni nella TUI possano compromettere l'integrità del processo chiamante.
* **Risoluzione del Percorso del Core:** Il modulo TUI individua il file principale di `bash4llm` leggendo la variabile d'ambiente `BASH4LLM_CORE_SCRIPT` esportata dal processo padre. In caso di esecuzione autonoma fuori dal core, implementa un algoritmo di fallback che risale l'albero delle directory fino alla radice del repository per localizzare il core.
* **Riutilizzo del Codice (Sourcing Guard):** All'avvio, il modulo TUI importa le utility, i lock e le funzioni di rete di `bash4llm` eseguendo il `source` del core sotto la guardia ambientale:
  ```bash
  export BASH4LLM_SOURCE_ONLY=1
  ```
  Questo meccanismo interrompe l'esecuzione del core subito prima del parsing degli argomenti CLI, consentendo alla TUI di ereditarne le librerie e le funzioni interne (es. `call_api_streaming`, `session_append`, `session_read_window`) senza alcuna duplicazione di codice.

---

## 2. Requisiti e Compatibilità

* **Sistemi Operativi:** macOS, Linux (distribuzioni basate su Debian/RedHat/Arch), Termux (Android), WSL (Windows Subsystem for Linux) ed esecuzione remota via SSH.
* **Interprete:** GNU Bash 4.x o superiore.
* **Dipendenze Strumentali:** `jq`, `curl`, `base64`, `less` (o `more` in alternativa).

---

## 3. Trasferimento dello Stato e Variabili d'Ambiente

Il modulo TUI eredita lo stato dal processo padre e ne gestisce le variazioni locali tramite le seguenti variabili d'ambiente esportate:

| Variabile d'Ambiente | Descrizione | Default Locale in TUI |
| :--- | :--- | :--- |
| `BASH4LLM_ACTIVE_SESSION` | ID della sessione di chat attiva. | Se vuota, avvia il Wizard. |
| `BASH4LLM_ACTIVE_MODEL` | Modello LLM selezionato dal core. | Risolto dinamicamente tramite `resolve_model`. |
| `BASH4LLM_ACTIVE_TEMPERATURE` | Temperatura di generazione (TURE). | `1.0` |
| `BASH4LLM_HISTORY_DIR` | Percorso della directory della cronologia. | `bash4llm.d/history` |
| `BASH4LLM_CONFIG_DIR` | Percorso della directory di configurazione. | `bash4llm.d/config` |

---

## 4. Interfaccia Visiva e Rendering

* **Scrittura Sequenziale Standard:** L'interfaccia utente rifiuta l'uso di librerie a schermo intero (como `ncurses` o sequenze di posizionamento assoluto ANSI tramite `tput`). Tutto il rendering visivo si affida al normale scorrimento verticale (*vertical scrolling*) del terminale.
* **Resistenza ai Ridimensionamenti (`SIGWINCH`):** L'approccio sequenziale rende la TUI nativamente immune a crash o sfarfallii visivi causati dal ridimensionamento della finestra o dall'uso su terminali mobili e connessioni SSH instabili.
* **Conformità NO_COLOR:** La TUI adotta le variabili di stile ANSI caricate dal core (`C_LOGO`, `C_BCYAN`, `C_BGREEN`, `C_RST`). Se l'ambiente rileva l'impostazione `NO_COLOR` o se gli output non sono associati a una TTY interattiva, i colori vengono disattivati automaticamente.

---

## 5. Gestione Sincrona del Flusso e Interruzioni

Il REPL opera secondo un modello sincrono e sequenziale:
```
Attesa Input Utente -> Compilazione Contesto -> Chiamata API (Sincrona/Bloccante) -> Output Stream -> Nuovo Input
```
* **Gestione Dinamica dei Segnali (`SIGINT` / `Ctrl+C`):**
  1. *Fase di Input Passivo (Prompt):* L'interruzione `Ctrl+C` viene gestita dal trap globale configurato nella TUI: interrompe l'inserimento corrente, va a capo e ripresenta il prompt vuoto `Tu > ` senza terminare la shell REPL.
  2. *Fase di Generazione Attiva (Chiamata di Rete):* Prima di invocare `call_api_streaming` o `perform_request_once`, la TUI disattiva temporaneamente il proprio trap per consentire alla pipeline del core di intercettare il `Ctrl+C`. Il core cattura l'interruzione, arresta la pipeline di `curl`, restituisce l'exit code controllato `130` e restituisce il controllo alla TUI, che si riposiziona sul prompt in modo pulito.

---

## 6. Componenti e Logica dei Menu

### 6.1. Wizard di Selezione Sessione (Startup)
Se all'avvio `SESSION_ID` non è popolato, lo script esegue `load_sessions_wizard` per la gestione guidata dello storico:
1. Legge i file `.ndjson` presenti nella directory `sessions/`, ordinandoli per data di ultima modifica decrescente (i più recenti in alto).
2. Mostra un elenco di sessioni paginato a gruppi di **10 sessioni per pagina**.
3. Ciascuna riga descrive lo stato della sessione nel formato sequenziale:
   ```
   [Indice] <data_creazione> > <Titolo_sessione> > <data_ultimo_messaggio>
   ```
   * *Data Creazione:* Ricavata dal timestamp `.ts` della prima riga del file NDJSON, formattata come `YYYY-MM-DD HH:MM` (tramite elaborazione stringa portabile `_format_ts`).
   * *Titolo:* Estratto dal file metadati JSON `ui_state/sessions/<SESSION_ID>.json`. Se assente, estrae il primo messaggio utente dal file NDJSON (troncato a 35 caratteri); in caso di ulteriore assenza, mostra un default indicando l'ID.
   * *Data Ultimo Messaggio:* Ricavata dal timestamp `.ts` dell'ultima riga del file NDJSON, formattata in modo identico.
4. **Navigazione:** Gestita tramite input rapidi da tastiera: `+` o `n` (pagina successiva), `-` o `p` (pagina precedente), `c` (crea una nuova sessione vuota con ID randomizzato), oppure l'inserimento dell'indice numerico per caricare la conversazione.

### 6.2. Menu di Configurazione (`/config`)
Fornisce un menu interattivo numerato (1-6) richiamabile durante la chat per modificare dinamicamente i parametri di configurazione del modulo LLM:
* Scelta del Provider attivo (verifica la presenza nei provider registrati).
* Scelta del Modello (valida la compatibilità testuale tramite `validate_model_dispatch`).
* Inserimento o aggiornamento manuale della Chiave API del provider selezionato (scrive la variabile d'ambiente dinamica corrispondente).
* Esecuzione del Refresh dei modelli (invoca la chiamata API tramite `refresh_models_dispatch`).
* Visualizzazione dei modelli installati localmente (`list_models_cli`).

### 6.3. Menu Strumenti di Contesto (`/menu`)
Fornisce un menu interattivo numerato (1-6) per la gestione ordinativa della chat attiva:
* Ridenominazione del titolo della sessione attiva (aggiorna atomicamente il file di metadati della UI).
* Eliminazione fisica della sessione attiva su disco (previa doppia conferma interattiva di sicurezza).
* Generazione istantanea di una nuova sessione vuota (genera un ID casuale ed esce dal menu).
* Abilitazione o disattivazione in tempo reale della modalità di streaming della risposta (`STREAM_MODE` 0/1).
* Diagnostica completa di stato (visualizza i percorsi assoluti dei file NDJSON, di configurazione e di storico).

---

## 7. Comandi Speciali (Slash Commands)

All'interno della chat, la riga inserita dall'utente viene intercettata dal parser locale. I comandi speciali implementati sono:

* **/clear:** Esegue esclusivamente la pulizia visiva dello schermo del terminale (tramite utility `clear` o sequenza di ripristino ANSI `\033[H\033[2J`), ristampando il banner e lo stato corrente. **Non altera i dati della sessione su disco**.
* **/reset-session:** Inizializza una richiesta di cancellazione dei messaggi della sessione attiva. Richiede una **doppia conferma esplicita** (`[y/N]`). Qualsiasi input non conforme (o riga vuota premendo Invio) viene interpretato come risposta negativa ("No"), annullando l'azione per prevenire perdite accidentali di dati.
* **/history [N]:** Estrae lo storico dei messaggi della sessione corrente formattandoli a colori (`Tu >` in ciano, `<LLM> >` in verde) e li invia in pipeline al pager di sistema prioritario `less -R`.
  * Se l'utente non specifica l'argomento $N$, la TUI visualizza per impostazione predefinita le ultime **20 interazioni** (10 messaggi utente + 10 risposte assistente), stampando in cima un avviso visivo che descrive la visualizzazione parziale.
  * Se viene digitato esplicitamente `/history -all`, l'intera sessione NDJSON viene caricata nel pager.
* **/help o /?:** Mostra a schermo in modo sequenziale ed ordinato la legenda dei comandi interattivi abilitati.

---

## 8. Persistenza, Stato e Cronologia Comandi

* **Database dei Messaggi:** Ogni conversazione viene scritta e aggiornata in tempo reale in formato NDJSON all'interno della directory `sessions/` del database di `bash4llm`:
  ```
  bash4llm.d/history/sessions/<SESSION_ID>.ndjson
  ```
  Il modulo TUI delega la scrittura delle interazioni a `session_append` (o al modulo di sessione `session-engine.sh` se rilevato e compatibile), preservando la firma dei dati e le logiche dei lock di concorrenza.
* **Isolamento della Cronologia REPL (`tui_history`):** Per garantire la possibilità di navigare nello storico delle domande digitate all'interno della TUI usando le frecce della tastiera, ma evitando al contempo di inquinare lo storico dei comandi generali del sistema operativo dell'utente, la TUI configura un file di history isolato:
  ```bash
  HISTFILE="bash4llm.d/history/tui_history"
  ```
  All'avvio, la TUI importa la cronologia locale (`history -r`) e, ad ogni invio di testo da parte dell'utente, registra atomicamente la linea inserita (`history -s` seguito da `history -w`).
