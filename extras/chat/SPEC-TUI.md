[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

# Text User Interface 

[![Bash](https://img.shields.io/badge/TUI%20REPL-Bash4LLM-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](SPEC-TUI.md) [![Italiano](https://img.shields.io/badge/Italiano-🇮🇹-white)](#sezione-italiana)
[![English](https://img.shields.io/badge/English-🇬🇧-white)](#english-section)

---

## 🇮🇹 Sezione Italiana

# Specifica Tecnica: Modulo TUI REPL (`tui-repl.sh`) per Bash4LLM⁺

Questo documento definisce le specifiche architetturali, i flussi di controllo, la gestione dello stato, il sistema di internazionalizzazione e il comportamento interattivo del modulo TUI REPL (`tui-repl.sh`) di `Bash4LLM⁺`.

---

## 1. Architettura ed Integrazione

Il modulo TUI è concepito come un'estensione interattiva opzionale integrata con il nucleo funzionale (Core) dell'applicazione.

* **Isolamento dei Processi:** Quando l'utente invoca `bash4llm --chat`, il Core rileva la presenza dello script in `bash4llm.d/extras/chat/tui-repl.sh` e lo esegue sostituendo l'immagine del processo principale (`exec bash "$tui_script" "$@"`). Questo garantisce l'isolamento dello scope delle variabili e impedisce che eventuali eccezioni o interruzioni della TUI compromettano il processo padre.
* **Risoluzione del Percorso del Core:** Il modulo TUI individua il file principale di `bash4llm` leggendo la variabile d'ambiente `BASH4LLM_CORE_SCRIPT` esportata dal Core. In caso di esecuzione autonoma fuori dal Core, implementa un algoritmo di fallback che risale l'albero delle directory fino alla radice del repository.
* **Sourcing Guard per il Riutilizzo del Codice:** All'avvio, il modulo TUI importa le utility, i lock e le funzioni di rete di `bash4llm` eseguendo il `source` del Core sotto la guardia ambientale:
  ```bash
  export BASH4LLM_SOURCE_ONLY=1
  ```
  Questo meccanismo interrompe l'esecuzione del Core prima del parsing degli argomenti CLI, consentendo alla TUI di ereditarne le librerie e le funzioni interne (es. `_exec_curl_secure`, `call_api_streaming`, `thread_append`, `thread_read_window`) senza alcuna duplicazione di codice.

---

## 2. Requisiti di Sistema e Compatibilità

* **Sistemi Operativi:** macOS, Linux (distribuzioni basate su Debian/RedHat/Arch/SUSE), Termux (Android), WSL (Windows Subsystem for Linux), Cygwin ed esecuzione remota via SSH.
* **Interprete Shell:** GNU Bash 4.0 o superiore (necessario per il supporto agli array associativi e per il parsing nativo).
* **Dipendenze Utilità:** `jq`, `curl`, `base64`, `less` (o `more`).

---

## 3. Trasferimento dello Stato e Variabili d'Ambiente

Il modulo TUI eredita lo stato dal processo padre e ne gestisce le variazioni locali tramite le seguenti variabili d'ambiente:

| Variabile d'Ambiente | Descrizione | Default Locale in TUI |
| :--- | :--- | :--- |
| `BASH4LLM_ACTIVE_THREAD` | ID del thread di chat attivo. | Se vuota, avvia il Wizard dei Thread. |
| `BASH4LLM_ACTIVE_MODEL` | Modello LLM selezionato. | Risolto dinamicamente tramite `resolve_model`. |
| `BASH4LLM_ACTIVE_TEMPERATURE` | Temperatura di generazione (TURE). | `1.0` |
| `BASH4LLM_LANG` | Codice della lingua dell'interfaccia (i18n). | Rilevato o richiesto al primo avvio. |
| `BASH4LLM_HISTORY_DIR` | Percorso della directory della cronologia. | `bash4llm.d/history` |
| `BASH4LLM_CONFIG_DIR` | Percorso della directory di configurazione. | `bash4llm.d/config` |

---

## 4. Sistema di Internazionalizzazione (i18n)

Il modulo implementa un sistema multilingue isolato che supporta cinque lingue: **Inglese (default), Italiano, Spagnolo, Francese e Tedesco**.

* **Struttura delle Risorse:** I file di traduzione locali (formato `.properties`) sono memorizzati all'interno della directory del modulo stesso:
  ```text
  bash4llm.d/extras/chat/langs/
  ├── en.properties  # Inglese (Default & Fallback)
  ├── de.properties  # Tedesco
  ├── es.properties  # Spagnolo
  ├── fr.properties  # Francese
  └── it.properties  # Italiano
  ```
* **Parser Dichiarativo Isolato:** La lettura dei file di risorsa avviene riga per riga tramite ciclo `while read` nativo senza ricorrere a `source` o `eval`, prevenendo iniezioni di codice.
* **Sanitizzazione e Validazione:**
  * Il codice lingua viene forzato a due caratteri alfabetici minuscoli (`^[a-z]{2}$`) tramite espressione regolare per prevenire attacchi di *Directory Traversal*.
  * Le chiavi vengono ripulite mantenendo unicamente caratteri alfanumerici e underscore (`tr -d -c 'A-Za-z0-9_'`).
* **Lookup delle Stringhe:** Le coppie chiave-valore vengono caricate in memoria all'avvio in un array associativo globale (`declare -A T_MSG`). L'interrogazione avviene tramite la funzione `_msg()`.
* **Inizializzazione e Fallback:** Se la variabile `BASH4LLM_LANG` non è configurata, viene mostrato il menu di selezione iniziale salvando la preferenza in modo persistente. In caso di chiavi mancanti, il sistema esegue il fallback automatico sulla lingua inglese (`en.properties`).

---

## 5. Interfaccia Visiva e Rendering

* **Scrittura Sequenziale Standard:** L'interfaccia utente evita l'uso di librerie a schermo intero (come `ncurses` o sequenze di posizionamento assoluto ANSI tramite `tput`), affidando il rendering al normale scorrimento verticale (*vertical scrolling*) del terminale.
* **Resistenza ai Ridimensionamenti (`SIGWINCH`):** L'approccio sequenziale rende la TUI immune a sfarfallii o alterazioni del layout visivo durante il ridimensionamento della finestra o su connessioni SSH ad alta latenza.
* **Conformità NO_COLOR:** La TUI adotta le variabili di stile ANSI caricate dal Core. Se l'ambiente rileva l'impostazione `NO_COLOR` o se gli output non sono associati a un TTY interattivo, i colori vengono disattivati automaticamente.

---

## 6. Gestione Sincrona del Flusso ed Esecuzione HTTP

Il REPL opera secondo un modello sequenziale sincrono:
```text
Input Utente -> Compilazione Contesto -> Chiamata API (Sincrona/Streaming) -> Output -> Nuovo Input
```

* **Esecuzione HTTP Sicura [INV-1]:** Le chiamate di rete invocate dal REPL vengono delegate alle routine del Core (`call_api_streaming` o `perform_request_once`), che instradano le richieste tramite `_exec_curl_secure()`. Gli header di autenticazione vengono scritti in file temporanei isolati (`0600`) e reindirizzati via File Descriptor, azzerando la presenza di token nei vettori d'argomento del processo (`argv` / `ps aux`).
* **Gestione Dinamica dei Segnali (`SIGINT` / `Ctrl+C`):**
  1. *Fase di Input Passivo:* L'interruzione `Ctrl+C` viene intercettata dal trap della TUI, azzerando la riga corrente e ripresentando il prompt vuoto.
  2. *Fase di Generazione Attiva:* La TUI ripristina temporaneamente il trap del Core prima di invocare le funzioni di rete. Il Core interrompe la pipeline di `curl`, restituisce il codice di uscita controllato `130` e restituisce il controllo alla TUI in modo pulito.

---

## 7. Componenti e Logica dei Menu

### 7.1 Wizard di Selezione Thread (Startup)
Se all'avvio `THREAD_ID` non è specificato, lo script esegue `load_threads_wizard` per la gestione guidata dello storico:
1. Legge i file `.ndjson` presenti nella directory `threads/`, ordinandoli per data di ultima modifica decrescente.
2. Visualizza l'elenco dei thread paginato a gruppi di 10 elementi per pagina.
3. Mostra data, titolo del thread ed ID anonimizzato (`SAFE_THREAD_ID`).
4. Consente la navigazione tra le pagine (`+`/`n`, `-`/`p`), la creazione di un nuovo thread (`c`) o il caricamento di una conversazione tramite indice numerico.

### 7.2 Menu di Configurazione (`/config`)
Fornisce un menu interattivo numerato (**1-11**) per modificare i parametri del runtime:
1. **Change Provider**: Modifica del provider attivo.
2. **Change LLM Model**: Selezione del modello di testo validato.
3. **Manage API Key**: Inserimento o aggiornamento della chiave API con validazione diagnostica.
4. **Change UI Language**: Selezione della lingua dell'interfaccia.
5. **Change Temperature**: Regolazione del valore di temperatura (`TURE`).
6. **Change Max Tokens**: Impostazione del limite dei token di risposta.
7. **Change Save Threshold**: Soglia in byte per l'archiviazione automatica.
8. **Change Output Format**: Selezione del formato di rendering (`text`, `raw`, `json`, `pretty`).
9. **Refresh Model List**: Aggiornamento dell'elenco dei modelli del provider attivo.
10. **List Locally Cached Models**: Visualizzazione dei modelli registrati localmente.
11. **Return to Chat**: Chiusura del menu e ritorno al prompt.

### 7.3 Menu di Gestione Thread (`/thread` o `/threads`)
Sottomenu dedicato al controllo della conversazione attiva (**1-6**):
1. **Rinomina Thread Attivo**: Aggiornamento del titolo del thread nel file di metadati JSON.
2. **Elimina Thread Attivo**: Eliminazione del file NDJSON e dei metadati associati sotto lock.
3. **Avvia Nuovo Thread**: Inizializzazione immediata di un nuovo thread con ID causale.
4. **Elenca e Leggi Thread Passati**: Ispezione dello storico conversazionale tramite il pager `less -R`.
5. **Carica Thread Passato**: Avvio del wizard interattivo per la selezione di un thread precedente.
6. **Ritorna al Prompt**: Ritorno alla sessione di chat.

---

## 8. Comandi Speciali (Slash Commands)

* `/exit` o `/quit`: Chiusura della sessione e termine del processo TUI.
* `/clear`: Pulizia dello schermo e ristampa del banner senza alterare i dati su disco.
* `/thread` o `/threads`: Apertura del sottomenu di gestione del thread.
* `/undo`: Rimozione dell'ultimo turno di conversazione (prompt utente e risposta assistente) dal file NDJSON.
* `/status`: Visualizzazione dei parametri attivi, dei percorsi e delle statistiche del thread.
* `/system [<prompt>]`: Visualizzazione o impostazione del prompt di sistema.
* `/model <name>`: Modifica istantanea del modello in uso.
* `/temperature` o `/ture <value>`: Modifica della temperatura di generazione.
* `/max <value>`: Impostazione del limite massimo di token.
* `/threshold <value>`: Impostazione della soglia di salvataggio automatico.
* `/format <format>`: Cambiamento del formato dell'output.
* `/file <path> [<prompt>]`: Lettura e allegato di un file di testo (limite massimo 100 KB).
* `/block`: Attivazione della modalità di input multilinea (conclusa digitando `/end`).
* `/edit`: Composizione del prompt tramite l'editor di testo di sistema (`$EDITOR`, `nano` o `vi`).
* `/help` o `/?`: Visualizzazione della guida dei comandi interattivi.

---

## 9. Persistenza e Isolamento della Cronologia

* **Registro Conversazionale NDJSON:** Ogni conversazione viene salvata in tempo reale nel file:
  `bash4llm.d/history/threads/<SAFE_THREAD_ID>.ndjson`
  La scrittura viene effettuata tramite `thread_append` (o il modulo `session-engine.sh`), garantendo l'uso di lock esclusivi e l'anonimizzazione SHA-256 degli identificatori.
* **Isolamento Cronologia REPL (`tui_history`):**
  * La registrazione automatica delle istruzioni della shell viene disabilitata all'avvio con `set +o history`.
  * La cronologia dei prompt utente viene gestita in modo indipendente e salvata esclusivamente nel file `tui_history`.
  * In modalità privata (`/private`), la scrittura dello storico delle domande su disco viene sospesa.

---

## 10. Protezione del Terminale e Sanitizzazione dell'Output

* **Sanitizzazione dell'Output dell'LLM (`sanitize_llm_output`):** Per prevenire attacchi di *Terminal Injection* o la manipolazione dello schermo da parte di risposte dell'LLM contenenti sequenze di controllo malevole, l'output generato dal modello viene filtrato tramite `sanitize_llm_output()` prima della stampa su TTY e del salvataggio. La funzione rimuove sequenze di escape pericolose (OSC/DCS) preservando la formattazione cromatica ANSI standard.
* **Limitazione File Allegati (/file):** Imposizione di un limite massimo di **100 KB** per i file caricati tramite `/file` per prevenire la saturazione della memoria RAM o crash di `jq`.
* **Neutralizzazione delle Sotto-shell nei Dizionari i18n:** Le stringhe nei file `.properties` vengono elaborate come costanti letterali senza valutazione di comandi o subshell incorporati.

---

## 🇬🇧 English Section 


# Technical Specification: TUI REPL Module (`tui-repl.sh`) for Bash4LLM⁺

This document defines the architectural specifications, control flows, state management, internationalization system, and interactive behavior of the TUI REPL module (`tui-repl.sh`) of `Bash4LLM⁺`.

---

## 1. Architecture and Integration

The TUI module is designed as an optional interactive extension integrated with the functional core (Core) of the application.

* **Process Isolation:** When the user invokes `bash4llm --chat`, the Core detects the presence of the script at `bash4llm.d/extras/chat/tui-repl.sh` and executes it by replacing the primary process image (`exec bash "$tui_script" "$@"`). This guarantees variable scope isolation and prevents any TUI exceptions or interruptions from compromising the parent process.
* **Core Path Resolution:** The TUI module locates the main `bash4llm` file by reading the `BASH4LLM_CORE_SCRIPT` environment variable exported by the Core. In the case of standalone execution outside the Core, it implements a fallback algorithm that traverses up the directory tree to the repository root.
* **Sourcing Guard for Code Reuse:** At startup, the TUI module imports `bash4llm`'s utilities, locks, and network functions by sourcing the Core under the environmental guard:
  ```bash
  export BASH4LLM_SOURCE_ONLY=1
  ```
  This mechanism halts Core execution prior to CLI argument parsing, allowing the TUI to inherit its internal libraries and functions (e.g., `_exec_curl_secure`, `call_api_streaming`, `thread_append`, `thread_read_window`) without any code duplication.

---

## 2. System Requirements and Compatibility

* **Operating Systems:** macOS, Linux (Debian/RedHat/Arch/SUSE-based distributions), Termux (Android), WSL (Windows Subsystem for Linux), Cygwin, and remote execution via SSH.
* **Shell Interpreter:** GNU Bash 4.0 or higher (required for associative array support and native parsing).
* **Utility Dependencies:** `jq`, `curl`, `base64`, `less` (or `more`).

---

## 3. State Transfer and Environment Variables

The TUI module inherits its state from the parent process and manages local changes through the following environment variables:

| Environment Variable | Description | Local TUI Default |
| :--- | :--- | :--- |
| `BASH4LLM_ACTIVE_THREAD` | ID of the active chat thread. | If empty, launches the Thread Wizard. |
| `BASH4LLM_ACTIVE_MODEL` | Selected LLM model. | Dynamically resolved via `resolve_model`. |
| `BASH4LLM_ACTIVE_TEMPERATURE` | Generation temperature (TURE). | `1.0` |
| `BASH4LLM_LANG` | Interface language code (i18n). | Detected or prompted on first startup. |
| `BASH4LLM_HISTORY_DIR` | History directory path. | `bash4llm.d/history` |
| `BASH4LLM_CONFIG_DIR` | Configuration directory path. | `bash4llm.d/config` |

---

## 4. Internationalization System (i18n)

The module implements an isolated multilingual system supporting five languages: **English (default), Italian, Spanish, French, and German**.

* **Resource Structure:** Local translation files (`.properties` format) are stored inside the module's own directory:
  ```text
  bash4llm.d/extras/chat/langs/
  ├── en.properties  # English (Default & Fallback)
  ├── de.properties  # German
  ├── es.properties  # Spanish
  ├── fr.properties  # French
  └── it.properties  # Italian
  ```
* **Isolated Declarative Parser:** Resource files are read line by line using a native `while read` loop without invoking `source` or `eval`, preventing code injection attacks.
* **Sanitization and Validation:**
  * Language codes are strictly forced to two lowercase alphabetic characters (`^[a-z]{2}$`) via regular expression to prevent *Directory Traversal* attacks.
  * Keys are sanitized by retaining only alphanumeric characters and underscores (`tr -d -c 'A-Za-z0-9_'`).
* **String Lookup:** Key-value pairs are loaded into memory at startup within a global associative array (`declare -A T_MSG`). Querying is handled via the `_msg()` function.
* **Initialization and Fallback:** If the `BASH4LLM_LANG` variable is unconfigured, an initial selection menu is displayed, and the preference is saved persistently. For missing keys, the system automatically falls back to English (`en.properties`).

---

## 5. Visual Interface and Rendering

* **Standard Sequential Writing:** The user interface avoids full-screen libraries (such as `ncurses` or absolute ANSI positioning sequences via `tput`), relying instead on standard vertical terminal scrolling for rendering.
* **Resize Resilience (`SIGWINCH`):** The sequential approach renders the TUI immune to flickering or visual layout disruptions during window resizing or over high-latency SSH connections.
* **NO_COLOR Compliance:** The TUI adopts the ANSI style variables loaded by the Core. If the environment detects the `NO_COLOR` setting or if outputs are not attached to an interactive TTY, colors are disabled automatically.

---

## 6. Synchronous Flow Management and HTTP Execution

The REPL operates on a synchronous sequential model:
```text
User Input -> Context Compilation -> API Call (Synchronous/Streaming) -> Output -> New Input
```

* **Secure HTTP Execution [INV-1]:** Network calls initiated by the REPL are delegated to Core routines (`call_api_streaming` or `perform_request_once`), which route requests via `_exec_curl_secure()`. Authentication headers are written to isolated temporary files (`0600`) and redirected via File Descriptors, completely eliminating API tokens from process argument vectors (`argv` / `ps aux`).
* **Dynamic Signal Handling (`SIGINT` / `Ctrl+C`):**
  1. *Passive Input Phase:* The `Ctrl+C` interrupt is caught by the TUI trap, clearing the current line and re-displaying an empty prompt.
  2. *Active Generation Phase:* The TUI temporarily restores the Core trap prior to invoking network functions. The Core interrupts the `curl` pipeline, returns the controlled exit code `130`, and safely returns control to the TUI.

---

## 7. Menu Components and Logic

### 7.1 Thread Selection Wizard (Startup)
If `THREAD_ID` is unspecified at startup, the script executes `load_threads_wizard` for guided history management:
1. Reads `.ndjson` files inside the `threads/` directory, sorting them by last modification date in descending order.
2. Displays the list of threads paginated in groups of 10 items per page.
3. Shows the date, thread title, and anonymized ID (`SAFE_THREAD_ID`).
4. Allows page navigation (`+`/`n`, `-`/`p`), creation of a new thread (`c`), or loading a conversation via a numeric index.

### 7.2 Configuration Menu (`/config`)
Provides a numbered interactive menu (**1-11**) to adjust runtime parameters:
1. **Change Provider**: Switch active provider.
2. **Change LLM Model**: Select a validated text model.
3. **Manage API Key**: Input or update the API key with diagnostic validation.
4. **Change UI Language**: Select interface language.
5. **Change Temperature**: Adjust temperature parameter (`TURE`).
6. **Change Max Tokens**: Set response token limit.
7. **Change Save Threshold**: Byte threshold for automatic archiving.
8. **Change Output Format**: Select rendering format (`text`, `raw`, `json`, `pretty`).
9. **Refresh Model List**: Update model list for the active provider.
10. **List Locally Cached Models**: Display locally registered models.
11. **Return to Chat**: Close menu and return to prompt.

### 7.3 Thread Management Menu (`/thread` or `/threads`)
Dedicated submenu for controlling the active conversation (**1-6**):
1. **Rename Active Thread**: Update the thread title in the JSON metadata file.
2. **Delete Active Thread**: Remove the NDJSON file and associated metadata under lock.
3. **Start New Thread**: Instantly initialize a new thread with a random ID.
4. **List and Read Past Threads**: Inspect conversation history via the `less -R` pager.
5. **Load Past Thread**: Launch interactive wizard to select a previous thread.
6. **Return to Prompt**: Return to chat session.

---

## 8. Slash Commands

* `/exit` or `/quit`: Terminate session and exit TUI process.
* `/clear`: Clear screen and reprint banner without altering data on disk.
* `/thread` or `/threads`: Open thread management submenu.
* `/undo`: Remove last conversation turn (user prompt and assistant response) from the NDJSON file.
* `/status`: Display active parameters, paths, and thread statistics.
* `/system [<prompt>]`: Display or set system prompt.
* `/model <name>`: Instantly switch model in use.
* `/temperature` or `/ture <value>`: Adjust generation temperature.
* `/max <value>`: Set maximum completion token limit.
* `/threshold <value>`: Set autosave threshold.
* `/format <format>`: Change output format.
* `/file <path> [<prompt>]`: Read and attach text file (100 KB maximum limit).
* `/block`: Enable multiline input mode (concluded by typing `/end`).
* `/edit`: Compose prompt via system text editor (`$EDITOR`, `nano`, or `vi`).
* `/help` or `/?`: Display interactive command guide.

---

## 9. History Persistence and Isolation

* **NDJSON Conversational Log:** Every conversation is saved in real time to:
  `bash4llm.d/history/threads/<SAFE_THREAD_ID>.ndjson`
  Writes are processed via `thread_append` (or the `session-engine.sh` module), ensuring exclusive lock usage and SHA-256 anonymization of identifiers.
* **REPL History Isolation (`tui_history`):**
  * Automatic recording of shell commands is disabled at startup using `set +o history`.
  * User prompt history is managed independently and saved exclusively to the `tui_history` file.
  * In private mode (`/private`), writing prompt history to disk is suspended.

---

## 10. Terminal Protection and Output Sanitization

* **LLM Output Sanitization (`sanitize_llm_output`):** To prevent *Terminal Injection* attacks or screen manipulation from LLM responses containing malicious control sequences, generated model output is filtered via `sanitize_llm_output()` prior to TTY printing and saving. The function strips dangerous escape sequences (OSC/DCS) while preserving standard ANSI color formatting.
* **Attached File Limit (/file):** Enforces a **100 KB** hard ceiling on files loaded via `/file` to prevent RAM saturation or `jq` crashes.
* **Subshell Neutralization in i18n Dictionaries:** Resource strings in `.properties` files are processed as literal constants without evaluating embedded commands or subshells.
