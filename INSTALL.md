# INSTALL.md

### Introduzione
GroqBash è un singolo file eseguibile che, alla prima esecuzione, crea la directory runtime `groqbash.d/` accanto al binario. Gli **extras** (provider opzionali, UI, librerie, strumenti di sicurezza, test, documentazione) sono **opzionali** e devono essere forniti localmente. Questo documento descrive lo stato attuale dell’installazione degli extras, la procedura manuale da seguire oggi e la specifica progettuale del comportamento che la flag `--install-extras` dovrebbe rispettare quando implementata.

---

### Requisiti hard del core
- **bash**  
- **coreutils** (comandi POSIX di base: `mkdir`, `cp`, `mv`, `rm`, `chmod`, `printf`, `test`/`[ ]`)  
- **curl**  
- **jq**  
- **mktemp**  
- **stat**  
- **flock**  
- **base64**

> Nota: lo script verifica la presenza esplicita di questi comandi all’avvio; alcune funzionalità degradano se strumenti opzionali (es. `sha256sum`, `shasum`, `stdbuf`) non sono disponibili.

---

### Destinazione canonica degli extras
La destinazione obbligatoria e canonica è:
`
<SCRIPTDIR>/groqbash.d/extras/
`
dove **`<SCRIPTDIR>`** è la directory che contiene il file `groqbash` (il binario). Il bootstrap del core crea `groqbash.d/` e `groqbash.d/extras/` con permessi restrittivi, ma **non** popola la directory con contenuti.

---

### Origine degli extras (sorgente)
Gli extras devono essere forniti dall’operatore come una directory `extras/` locale. L’ordine di ricerca robusto per la sorgente è:

1. `<SCRIPTDIR>/extras/`  
2. `<SCRIPTDIR>/../extras/` (utile se il binario è in `bin/` e il repo è nella directory padre)  
3. percorso esplicito fornito dall’utente (se l’interfaccia CLI lo permette)  
4. percorso configurato tramite variabile `GROQBASH_EXTRAS_SOURCE` **solo se** documentato e valido

Regole di robustezza:
- la sorgente deve essere una **directory esistente** e **non** un symlink; se è symlink, va rifiutata.
- se più sorgenti sono presenti, si usa la prima valida nell’ordine sopra e si segnala quale sorgente è stata scelta.
- se nessuna sorgente valida è trovata → errore bloccante per l’operazione `--install-extras`.

---

### Struttura attesa sotto `extras/`
Sottodirectory previste (opzionali; possono mancare):

- `providers/` — provider opzionali (script, wrapper)  
- `lib/` — librerie di supporto opzionali  
- `security/` — script o risorse di verifica/validazione opzionali  
- `ui/`  
  - `cgi-bin/`  
  - `templates/`  
  - `static/`  
  - `gui-lang.conf`  
- `docs/` — documentazione e help aggiuntivo  
- `test/` — test helper opzionali

Se una sottodirectory manca nella sorgente, **non** è un errore bloccante: la componente viene saltata con warning informativo.

---

### Stato attuale di `--install-extras`
La flag `--install-extras` è presente nell’interfaccia CLI del progetto ma, nella versione del codice analizzata, **non è implementata**. La sezione seguente definisce il comportamento progettuale che l’implementazione dovrà rispettare; fino a quando la flag non è effettivamente implementata, usare la procedura manuale descritta più avanti.

---

### Comportamento progettuale di `groqbash --install-extras`

#### A. `groqbash --install-extras` (senza argomenti)
- Individua la sorgente `extras/` secondo l’ordine di ricerca definito. Se nessuna sorgente valida → abort (errore bloccante).
- Crea le directory di destinazione mancanti sotto `<SCRIPTDIR>/groqbash.d/extras/` con permessi restrittivi (directory `700`).
- Acquisisce un lock di installazione locale (es. `groqbash.d/extras/.install.lock`) per evitare race tra istanze concorrenti.
- Itera ricorsivamente sulla sorgente:
  - Per ogni directory: crea la directory corrispondente in destinazione se mancante.
  - Per ogni file regolare: copia il contenuto (mai symlink) in modo atomico — scrittura in file temporaneo nella stessa directory di destinazione, impostazione permessi sicuri, rename atomico.
  - Per ogni symlink nella sorgente:
    - se punta **all’interno** della sorgente: risolvere e copiare il contenuto reale (file o directory) nella destinazione;
    - se punta **fuori** dalla sorgente: rifiutare quella voce e registrare warning/errore (non seguire).
- Rilascia il lock e stampa un sommario operativo (copiati, saltati, conflitti, warnings).
- Risultato: tutte le componenti presenti nella sorgente sono presenti in `groqbash.d/extras/` senza sovrascrivere file utente esistenti, salvo diversa politica esplicita.

#### B. `groqbash --install-extras providers ui security ...` (con argomenti)
- Valida ogni nome componente: deve corrispondere a una sottodirectory immediata nella sorgente.
- Per ogni componente valida, esegue la stessa procedura di copia limitata a quella sottodirectory.
- Se una componente richiesta non esiste nella sorgente → warning e continua con le altre.

---

### Politica di sovrascrittura e idempotenza
Principio guida: **proteggere i file modificati dall’utente**; rendere l’operazione ripetibile.

Predefinito:
- **Non sovrascrivere mai** un file esistente in `groqbash.d/extras/` per default.
- Se il file di destinazione non esiste → copiarlo.
- Se il file di destinazione esiste:
  - se identico (stesso checksum quando disponibile; altrimenti confronto `mtime`+`size`) → considerato già installato (nessuna azione);
  - se differente → **non sovrascrivere**; registrare un conflitto e segnalarlo con istruzioni chiare (es. usare `--force-extras` o rimuovere manualmente).
- Flag opzionali (da implementare separatamente):
  - `--force-extras` → sovrascrive incondizionatamente i file esistenti.
  - `--update-extras` → sovrascrive solo se il file sorgente è diverso e il file di destinazione non è stato modificato dall’utente (determinato da checksum o confronto `mtime`+`size`); se il file di destinazione è stato modificato → lasciare e segnalare conflitto.
- Se un file in destinazione ha `mtime` più recente o checksum diverso rispetto alla precedente installazione → considerarlo “file utente” e non sovrascriverlo senza `--force-extras`.
- Idempotenza: con la politica “non sovrascrivere per default” e confronto identità, eseguire `--install-extras` più volte non cambia lo stato dopo la prima esecuzione riuscita (salvo interventi manuali).

---

### Errori, warning e messaggi all’utente
**Errori bloccanti (abort):**
- sorgente `extras/` non trovata → abort;
- destinazione non scrivibile → abort;
- lock non acquisibile dopo timeout → abort;
- spazio su disco insufficiente durante copia → abort e rollback parziale;
- richiesta di seguire symlink che puntano fuori dalla sorgente → rifiuto per quella voce (warning o abort a seconda della policy).

**Warning (non bloccanti):**
- componente richiesta non trovata → skip con warning;
- file di destinazione esistente e differente → skip e segnalazione di conflitto;
- `chmod` non applicabile (es. su NTFS) → warning;
- checksum non disponibile → fallback a `mtime`+`size` con warning.

**Messaggi concettuali da mostrare:**
- sorgente scelta (path);
- sommario: numero file copiati, saltati, conflitti, warnings;
- per ogni conflitto: percorso sorgente, percorso destinazione, motivo;
- azioni consigliate: `--force-extras`, rimuovere manualmente, esaminare differenze.

Regole di uscita:
- errori bloccanti → codice di uscita non‑zero;
- solo warnings → uscita con codice zero ma con messaggio che indica componenti non installate.

---

### Portabilità e strumenti ammessi
Il comportamento progettuale è implementabile usando solo strumenti portabili e POSIX‑compatibili:

- **bash** e comandi POSIX: `mkdir`, `test`/`[ ]`, `cp` (senza opzioni GNU‑specifiche), `mv`, `chmod`, `stat` (con fallback), `mktemp`, `flock` (o fallback con `mkdir` atomico), `printf`, `rm`.
- Checksum: usare `sha256sum` se disponibile; fallback a `shasum` o confronto `mtime`+`size`.
- **Evitare**: `readlink -f`, `rsync`, opzioni GNU‑only non portabili.

Attenzioni:
- **BusyBox**: alcune opzioni di `cp`/`mktemp` possono mancare; la copia deve essere eseguita con scrittura in file temporaneo e rename atomico.
- **NTFS (WSL/Cygwin/MSYS2)**: `chmod` può essere no‑op; emettere warning se i permessi POSIX non possono essere applicati.
- **Locking**: preferire `flock`; se non disponibile usare `mkdir` atomico con timeout e warning.

---

### Symlink policy
- **Mai** creare symlink nella destinazione. Copiare sempre il contenuto reale.
- Se nella sorgente esistono symlink che puntano **dentro** la sorgente → risolvere e copiare il contenuto reale.
- Se puntano **fuori** dalla sorgente → rifiutare quella voce e registrare warning/errore (non seguire).

---

### Registro di installazione
Si raccomanda la scrittura di un file `INSTALLATION-RECORD` in `groqbash.d/extras/` contenente elenco file copiati, timestamp e checksum (quando disponibili) per audit e rollback manuale. Questo file deve essere creato solo se l’installazione ha copiato effettivamente nuovi file.

---

### Procedura manuale (uso pratico oggi)
Finché `--install-extras` non è implementato nella versione in uso, installa manualmente gli extras copiando la directory `extras/` del repository nella destinazione runtime.

Esempi pratici (concetto, non comandi obbligatori):
- Se il repository e il binario sono nella stessa directory: copiare il contenuto di `extras/` in `./groqbash.d/extras/`.
- Se il binario è in una directory diversa dal repository: creare `SCRIPTDIR/groqbash.d/extras` e copiare i contenuti della sorgente `extras/` nella destinazione.

Dopo la copia, i provider opzionali, la UI e la documentazione aggiuntiva saranno disponibili dove il core si aspetta di trovarli.

---

### Note finali
- La flag `--install-extras` è descritta qui come comportamento progettuale; se la versione in uso non la implementa ancora, usare la procedura manuale.
- Il core include un provider embedded che permette il funzionamento minimo anche senza extras.
- Non usare symlink per popolare `groqbash.d/extras/`.
- Documentare eventuali limitazioni di permessi su filesystem non POSIX (NTFS) e le implicazioni per `chmod` e per la sicurezza dei file.
