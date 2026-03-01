# INSTALL.md

## Italiano

### Introduzione
GroqBash è un singolo file eseguibile che crea al primo avvio la directory runtime `groqbash.d/` accanto al binario. Gli **extras** (provider opzionali, UI, strumenti di sicurezza, test, documentazione) sono **opzionali** e devono essere forniti localmente. Questo documento descrive **esattamente** come installarli oggi e il comportamento previsto per `--install-extras` (specifica progettuale).

---

### Requisiti hard del core
- **bash**  
- **coreutils (tutti)**  
- **curl**  
- **jq**  
- **mktemp**  
- **stat**  
- **flock**  
- **base64**

---

### Dove vivono gli extras (destinazione canonica)
La destinazione prevista e obbligatoria è:

`
<SCRIPTDIR>/groqbash.d/extras/
`

dove **`<SCRIPTDIR>`** è la directory che contiene il file `groqbash` (il binario). Il bootstrap del core crea `groqbash.d/` e `groqbash.d/extras/` ma **non** popola la directory.

---

### Origine degli extras (sorgente)
Gli extras devono essere forniti dall’operatore come una directory `extras/` locale. L’ordine di ricerca previsto per la sorgente è:

1. ` <SCRIPTDIR>/extras/`  
2. ` <SCRIPTDIR>/../extras/`  
3. percorso esplicito fornito dall’utente (se l’interfaccia CLI lo permette)  
4. percorso configurato tramite variabile `GROQBASHEXTRASSOURCE` (se documentata e valida)

Regole di robustezza:
- la sorgente deve essere una **directory esistente** e **non** un symlink; se è symlink, va rifiutata.
- se più sorgenti sono presenti, si usa la prima valida nell’ordine sopra e si segnala quale sorgente è stata scelta.
- se nessuna sorgente valida è trovata → errore bloccante.

---

### Struttura attesa sotto `extras/`
Sottodirectory previste (opzionali, possono mancare):

- `providers/`  
- `lib/`  
- `security/`  
- `ui/`  
  - `cgi-bin/`
  - `templates/`
  - `static/`
  - `gui-lang.conf`  
- `docs/`  
- `test/`

Se una sottodirectory manca nella sorgente, non è un errore bloccante: la componente viene saltata con warning informativo.

---

### Comportamento previsto di `groqbash --install-extras` (documentato)
> **Nota**: oggi la flag `--install-extras` è definita nell’interfaccia CLI ma **non è implementata** nel codice analizzato. La seguente sezione descrive il comportamento progettuale che va implementato e che deve essere documentato nell’INSTALL.md. Se la versione in uso non include ancora l’implementazione, usare la procedura manuale descritta più avanti.

#### A. `groqbash --install-extras` (senza argomenti)
- Individua la sorgente `extras/` secondo l’ordine di ricerca sopra. Se nessuna sorgente valida → abort (errore bloccante).
- Crea le directory di destinazione mancanti sotto `<SCRIPTDIR>/groqbash.d/extras/` con permessi restrittivi (directory `700`).
- Acquisisce un lock di installazione (file lock locale: `groqbash.d/extras/.install.lock`) per evitare race.
- Itera ricorsivamente sulla sorgente:
  - Per ogni directory: crea la directory corrispondente in destinazione se mancante.
  - Per ogni file regolare: copia il contenuto (mai symlink) in modo atomico (scrittura in file temporaneo, impostazione permessi, rename atomico).
  - Per ogni symlink nella sorgente:
    - se punta all’interno della sorgente: risolvere e copiare il contenuto reale;
    - se punta fuori dalla sorgente: rifiutare quella voce e registrare warning/errore (non seguire).
- Rilascia il lock e stampa un sommario (copiati, saltati, conflitti, warnings).
- Risultato: tutte le componenti presenti nella sorgente sono presenti in `groqbash.d/extras/` senza sovrascrivere file utente esistenti (salvo policy di sovrascrittura).

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
  - se identico (stesso checksum quando disponibile, altrimenti confronto `mtime`+`size`) → considerato già installato (nessuna azione);
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
- richiesta di seguire symlink che puntano fuori dalla sorgente → abort per quella voce.

**Warning (non bloccanti):**
- componente richiesta non trovata → skip con warning;
- file di destinazione esistente e differente → skip e segnalazione di conflitto;
- `chmod` non applicabile (es. NTFS) → warning;
- checksum non disponibile → fallback a `mtime`+`size` con warning.

**Messaggi da mostrare (concettuali):**
- sorgente scelta (path);
- sommario: numero file copiati, saltati, conflitti, warnings;
- per ogni conflitto: percorso sorgente, percorso destinazione, motivo;
- azioni consigliate: `--force-extras`, rimuovere manualmente, esaminare differenze.

Regole di uscita:
- errori bloccanti → codice di uscita non‑zero;
- solo warnings → uscita con codice zero ma messaggio che indica componenti non installate.

---

### Portabilità e strumenti ammessi
Implementabile usando solo strumenti portabili e POSIX‑compatibili:
- **bash** e comandi POSIX: `mkdir`, `test`/`[ ]`, `cp` (senza opzioni GNU‑specifiche), `mv`, `chmod`, `stat` (con fallback), `mktemp`, `flock` (o fallback con `mkdir` atomico), `printf`, `rm`.
- Checksum: usare `sha256sum` se disponibile; fallback a `shasum` o confronto `mtime`+`size`.
- Evitare: `readlink -f`, `rsync`, opzioni GNU‑only.
Attenzioni:
- BusyBox: alcune opzioni possono mancare; la copia deve essere implementata con file temporanei e rename atomico.
- NTFS (WSL/Cygwin): `chmod` può essere no‑op; emettere warning se i permessi non possono essere applicati.
- Locking: preferire `flock`; se non disponibile usare `mkdir` atomico con timeout.

---

### Symlink policy
- **Mai** creare symlink nella destinazione. Copiare sempre il contenuto reale.
- Se nella sorgente esistono symlink che puntano **dentro** la sorgente → risolvere e copiare il contenuto reale.
- Se puntano **fuori** dalla sorgente → rifiutare quella voce e registrare warning/errore.

---

### Registro di installazione
Si raccomanda (documentare/implementare) la scrittura di un file `INSTALLATION-RECORD` in `groqbash.d/extras/` contenente elenco file copiati e checksum per audit e rollback manuale.

---

### Procedura manuale (uso pratico oggi)
Finché `--install-extras` non è implementato nella versione in uso, installa manualmente gli extras copiando la directory `extras/` del repository nella destinazione runtime.

Esempi:

Se il repository e il binario sono nella stessa directory:
`
cp -r extras/* ./groqbash.d/extras/
`

Se il binario è in `$HOME/.local/bin` e il repo altrove:
`
BIN="$HOME/.local/bin/groqbash"
SCRIPTDIR="$(cd "$(dirname "$BIN")" && pwd)"
REPO="$HOME/src/groqbash"
mkdir -p "$SCRIPTDIR/groqbash.d/extras"
cp -r "$REPO/extras/"* "$SCRIPTDIR/groqbash.d/extras/"
`

Dopo la copia, i provider opzionali, la UI e la documentazione aggiuntiva saranno disponibili dove il core si aspetta di trovarli.

---

### Note finali (italiano)
- `--install-extras` è descritto qui come comportamento progettuale; se la tua versione non lo implementa ancora, usa la procedura manuale.  
- Il core include un provider embedded che permette il funzionamento minimo anche senza extras.  
- Non usare symlink per popolare `groqbash.d/extras/`.  
- Documentare eventuali differenze di permessi su filesystem non POSIX (NTFS).

---

## English

### Introduction
GroqBash is a single executable file that creates `groqbash.d/` next to the binary on first run. **Extras** (optional providers, UI, security tools, tests, docs) are optional and must be provided locally. This document states exactly how to install them today and the designed behavior for `--install-extras`.

---

### Hard requirements (core)
- **bash**  
- **coreutils (all)**  
- **curl**  
- **jq**  
- **mktemp**  
- **stat**  
- **flock**  
- **base64**

---

### Canonical destination for extras
Destination is always:

`
<SCRIPTDIR>/groqbash.d/extras/
`

where **`<SCRIPTDIR>`** is the directory containing the `groqbash` binary. The core bootstrap creates `groqbash.d/` and `groqbash.d/extras/` but does not populate it.

---

### Source of extras (search order)
The operator must provide a local `extras/` directory. Search order:

1. `<SCRIPTDIR>/extras/`  
2. `<SCRIPTDIR>/../extras/`  
3. explicit path provided by user (if CLI supports)  
4. path configured via `GROQBASHEXTRASSOURCE` (if documented and valid)

Rules:
- source must be an existing directory and **not** a symlink; symlinks are rejected.
- first valid source in order is used and reported.
- no valid source → blocking error.

---

### Expected structure under `extras/`
Optional subdirectories:

- `providers/`  
- `lib/`  
- `security/`  
- `ui/`  
  - `cgi-bin/`
  - `templates/`
  - `static/`
  - `gui-lang.conf`  
- `docs/`  
- `test/`

Missing subdirectories are skipped with a warning.

---

### Designed behavior of `groqbash --install-extras`
> Note: the `--install-extras` flag exists in the CLI but is **not implemented** in the analyzed code. The following is the design specification to implement and document. If your version lacks it, use the manual procedure below.

#### A. `groqbash --install-extras` (no args)
- Locate source `extras/` per search order; abort if none found.
- Create missing destination directories under `<SCRIPTDIR>/groqbash.d/extras/` with restrictive perms (`700`).
- Acquire installation lock (`groqbash.d/extras/.install.lock`) to avoid races.
- Recursively iterate source:
  - create directories in destination as needed;
  - copy regular files atomically (temp file → set perms → rename);
  - for symlinks:
    - if pointing inside source → resolve and copy real content;
    - if pointing outside source → reject that entry and log warning/error.
- Release lock and print summary (copied, skipped, conflicts, warnings).
- Result: components present in source are present in destination without overwriting user-modified files (unless overwrite policy applied).

#### B. `groqbash --install-extras providers ui security ...` (with args)
- Validate each component name as an immediate subdirectory in source.
- For each valid component, perform the same copy procedure limited to that subdirectory.
- Missing requested components → warn and continue.

---

### Overwrite policy and idempotence
Guiding principle: protect user‑modified files; make operation repeatable.

Default:
- **Never overwrite** existing files in `groqbash.d/extras/` by default.
- If destination file missing → copy it.
- If destination exists:
  - if identical (checksum if available, else `mtime`+`size`) → no action;
  - if different → do not overwrite; record conflict and instruct user (e.g. `--force-extras`).
- Optional flags to implement:
  - `--force-extras` → unconditional overwrite;
  - `--update-extras` → overwrite only if source differs and destination not modified by user.
- Files with newer `mtime` or different checksum → considered user files; do not overwrite without `--force-extras`.
- Idempotence: repeated runs produce same state after first successful run (unless manual changes occur).

---

### Errors, warnings, and user messages
**Blocking errors:**
- source not found → abort;
- destination not writable → abort;
- lock not acquired after timeout → abort;
- insufficient disk space during copy → abort and partial rollback;
- requested following of symlink pointing outside source → abort for that entry.

**Warnings:**
- requested component not found → skip with warning;
- destination file exists and differs → skip and report conflict;
- `chmod` not applicable (NTFS) → warning;
- checksum tool missing → fallback to `mtime`+`size` with warning.

Messages should report:
- which source was used;
- summary counts (copied, skipped, conflicts, warnings);
- per-conflict details and recommended actions.

Exit rules:
- blocking errors → non‑zero exit code;
- only warnings → zero exit code but informative message.

---

### Portability and allowed tools
Implementable with POSIX tools:
- **bash** and POSIX commands: `mkdir`, `test`/`[ ]`, `cp` (no GNU‑only flags), `mv`, `chmod`, `stat` (with fallback), `mktemp`, `flock` (or `mkdir` fallback), `printf`, `rm`.
- Checksum: `sha256sum` preferred; fallback to `shasum` or `mtime`+`size`.
- Avoid `readlink -f`, `rsync`, GNU‑only flags.
Notes:
- BusyBox may lack some options; use temp files + atomic rename.
- NTFS (WSL/Cygwin): `chmod` may be no‑op; warn user.
- Locking: prefer `flock`; fallback to atomic `mkdir` with timeout.

---

### Symlink policy
- **Never** create symlinks in destination; always copy real content.
- Symlinks in source pointing inside source → resolve and copy content.
- Symlinks pointing outside source → reject and log warning/error.

---

### Installation record
Recommended to write `INSTALLATION-RECORD` in `groqbash.d/extras/` listing copied files and checksums for audit/rollback.

---

### Manual installation (current practical method)
Until `--install-extras` is implemented, copy the repository `extras/` into the runtime destination.

Examples:

Repository and binary in same directory:
`
cp -r extras/* ./groqbash.d/extras/
`

Binary in `$HOME/.local/bin`, repo elsewhere:
`
BIN="$HOME/.local/bin/groqbash"
SCRIPTDIR="$(cd "$(dirname "$BIN")" && pwd)"
REPO="$HOME/src/groqbash"
mkdir -p "$SCRIPTDIR/groqbash.d/extras"
cp -r "$REPO/extras/"* "$SCRIPTDIR/groqbash.d/extras/"
`

After copying, optional providers, UI and docs are available where the core expects them.

---

### Final notes (English)
- `--install-extras` is specified here as the designed behavior; if your installed version lacks it, use the manual copy procedure.  
- The core contains an embedded provider enabling minimal operation without extras.  
- Do not use symlinks to populate `groqbash.d/extras/`.  
- Document permission differences on non‑POSIX filesystems (NTFS).

---

*Fine del documento.*
