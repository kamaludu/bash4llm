[![GroqBash](https://img.shields.io/badge/_GroqBash_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# INSTALLAZIONE  
**Lingue:**  
🇮🇹 Italiano (questa sezione)  
🇬🇧 English: vedi [English installation](#english-installation)

GroqBash è uno strumento Bash **portabile e auto‑contenuto**, progettato per ambienti **single‑user** (Linux, macOS, WSL, Termux, Cygwin/MSYS2).

- Puoi posizionare il file `groqbash` in **qualsiasi directory**.  
- Alla prima esecuzione, GroqBash crea automaticamente:

`
groqbash.d/
`

accanto al binario, con la struttura runtime necessaria.  
- Gli **extras** (provider esterni, UI, sicurezza, test, documentazione) sono **opzionali** e vivono sempre sotto:

`
groqbash.d/extras/
`

---

# 1. Prerequisiti e dipendenze

## Richiesti (core GroqBash)
- **bash**
- **curl**
- **coreutils** (almeno: `mktemp`, `chmod`, `mv`, `mkdir`, `head`, `sed`, `awk`, `grep`)
- **jq**

## Consigliati
- **python3** — fallback per fsync e serializzazione (opzionale)
- **sha256sum / shasum** — per verifiche e, in futuro, aggiornamenti degli extras
- Ambiente POSIX‑like (Linux, macOS, BusyBox, WSL, Cygwin/MSYS2)

## Locale e encoding
GroqBash richiede un ambiente UTF‑8.

`sh
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
`

---

# 2. Installazione minima (core)

## 2.1 Scarica GroqBash

`sh
curl -O https://raw.githubusercontent.com/kamaludu/groqbash/main/bin/groqbash
`

## 2.2 Rendi eseguibile

`sh
chmod +x groqbash
`

## 2.3 (Opzionale) Installa nel PATH

`sh
mkdir -p "$HOME/.local/bin"
mv groqbash "$HOME/.local/bin/groqbash"
export PATH="$HOME/.local/bin:$PATH"
`

## 2.4 Prima esecuzione e auto‑setup

`sh
groqbash --version
`

Alla prima esecuzione, GroqBash crea automaticamente:

`
groqbash.d/
  config/
  models/
  history/
  tmp/
  logs/
  extras/        (vuota, pronta per gli extras opzionali)
`

Tutto viene creato accanto al binario, con permessi restrittivi (directory 700, file 600).

---

# 3. Provider embedded e chiavi API

GroqBash include un **provider embedded** che permette il funzionamento minimo anche senza extras.

Per usare provider esterni (es. Groq API):

`sh
export GROQ_API_KEY="gsk_XXXXXXXXXXXXXXXX"
`

---

# 4. Installazione degli extras (opzionale)

Gli **extras** includono, ad esempio:

- provider esterni aggiuntivi  
- UI web (CGI)  
- strumenti di sicurezza  
- test suite  
- documentazione aggiuntiva (es. `extras/docs/help.txt`)  

Gli extras sono **sempre locali** e vivono in:

`
<SCRIPTDIR>/groqbash.d/extras/
`

dove `<SCRIPTDIR>` è la directory che contiene il file `groqbash`.

## 4.1 Sorgente degli extras

Oggi GroqBash si aspetta che gli extras provengano da una directory `extras/` locale, ad esempio:

- repository clonato:  
  `repo/extras/`  
- oppure un pacchetto distribuito che contiene una directory `extras/`

Non è previsto alcun download automatico da Internet.

---

## 4.2 Installazione con `--install-extras`

Quando implementato, il comando:

`sh
groqbash --install-extras
`

dovrà:

- cercare una sorgente `extras/` locale (es. `<SCRIPTDIR>/extras/` o `<SCRIPTDIR>/../extras/`)  
- copiare in modo **non distruttivo** il contenuto in:

  `
  <SCRIPTDIR>/groqbash.d/extras/
  `

- **non** creare symlink (solo copie reali)  
- **non** sovrascrivere file esistenti modificati dall’utente  
- essere **idempotente**: eseguirlo più volte non deve rompere nulla

### Installazione selettiva (comportamento previsto)

In futuro, sarà possibile installare solo alcune componenti, ad esempio:

`sh
groqbash --install-extras providers ui security
`

dove i nomi corrispondono a sottodirectory di `extras/` (es. `extras/providers/`, `extras/ui/`, ecc.).

Se una componente richiesta non esiste nella sorgente, verrà semplicemente ignorata con un messaggio informativo.

> Nota: se stai usando una versione in cui `--install-extras` non è ancora implementato, usa la procedura manuale seguente.

---

## 4.3 Installazione manuale degli extras (oggi operativa)

Finché `--install-extras` non è implementato nella tua versione, puoi installare gli extras **copiando manualmente** la directory `extras/` del repository nella destinazione runtime.

Esempio (repo e binario nella stessa directory):

`sh
# Sei in: repo/
cp -r extras/* ./groqbash.d/extras/
`

Esempio (binario in `$HOME/.local/bin`, repo altrove):

`sh
# Percorso del binario
BIN="$HOME/.local/bin/groqbash"
SCRIPTDIR="$(cd "$(dirname "$BIN")" && pwd)"

# Percorso del repository clonato
REPO="$HOME/src/groqbash"

# Copia degli extras nella destinazione runtime
mkdir -p "$SCRIPTDIR/groqbash.d/extras"
cp -r "$REPO/extras/"* "$SCRIPTDIR/groqbash.d/extras/"
`

Dopo la copia, il core continuerà a funzionare come prima, ma avrai:

- provider esterni disponibili  
- UI (se presente in `extras/ui/`)  
- strumenti di sicurezza  
- test suite  
- help esteso (es. `extras/docs/help.txt`)

---

# 5. Comportamento dei file temporanei

- GroqBash **non usa mai `/tmp`** del sistema per i temporanei interni.  
- I temporanei vengono creati in:

`
groqbash.d/tmp/
`

- Permessi: 700  
- In modalità `--debug`, i temporanei **non vengono rimossi** per facilitare l’ispezione.

---

# 6. Percorso di output (`--out`)

- Se passi `--out /percorso/file`, GroqBash:
  - tenta di creare la directory di destinazione  
  - verifica permessi e sicurezza  
  - salva il file con permessi restrittivi (600)

- Se la directory non è sicura o non è scrivibile:
  - **non** usa `/tmp`
  - stampa l’output su terminale
  - mostra un messaggio esplicito

**Consiglio:** usa percorsi sotto la tua home o sotto `groqbash.d/`.

---

# 7. Uso base ed esempi

Prompt semplice:

`sh
groqbash "scrivi una funzione bash che..."
`

Input da pipe:

`sh
echo "Spiegami questo codice" | groqbash
`

Input da file:

`sh
groqbash -f input.txt
`

Forzare salvataggio:

`sh
groqbash --save --out output.txt "testo lungo..."
`

Dry run (mostra payload JSON):

`sh
groqbash --dry-run "ciao"
`

Provider (se extras installati):

`sh
groqbash --provider gemini "traduci questo"
`

---

# 8. Codici di uscita

| Codice | Significato                                                                 |
|-------:|------------------------------------------------------------------------------|
| **0**  | Successo                                                                      |
| **1**  | Errore generico (argomenti, file, configurazione)                            |
| **2**  | Errore di rete / curl                                                         |
| **3**  | Errore HTTP/API (4xx/5xx)                                                     |
| **4**  | Nessun contenuto testuale estratto (errore parsing)                           |

Note operative:
- Codice 2 → retry automatici possibili (timeout, DNS, connessione rifiutata)  
- Codice 3 → nessun retry (errori API, autorizzazione, limiti)  
- Con `--debug`, i log completi sono in `groqbash.d/tmp/`

---

# 9. Troubleshooting e test consigliati

Verifica JSON inviato:

`sh
groqbash --dry-run "Test payload with \"quotes\" and newlines\nand unicode: € ✓"
`

Pipe input:

`sh
echo "Spiegami questo codice" | groqbash
`

API key non valida:

`sh
GROQ_API_KEY="invalid" groqbash "ciao" || echo "exit:$?"
`

Test senza jq (solo per debug, non in produzione):

`sh
mv /usr/bin/jq /usr/bin/jq.bak
groqbash --dry-run "test"
mv /usr/bin/jq.bak /usr/bin/jq
`

---

# 10. Installazione su Termux (Android)

`sh
pkg update
pkg install -y bash curl jq python
mkdir -p "$HOME/.local/bin"
mv groqbash "$HOME/.local/bin/groqbash"
chmod +x "$HOME/.local/bin/groqbash"
export PATH="$HOME/.local/bin:$PATH"
export GROQ_API_KEY="gsk_..."
groqbash --version
`

---

# 11. Note finali

- GroqBash è progettato per ambienti **single‑user**.  
- Gli extras sono **opzionali** e vivono sempre in `groqbash.d/extras/`.  
- Nessun output del modello viene mai eseguito come comando.  
- Per dettagli sulla sicurezza, vedi `SECURITY.md`.

---

# English installation  

GroqBash is a **portable, self‑contained Bash tool**, designed for **single‑user** environments (Linux, macOS, WSL, Termux, Cygwin/MSYS2).

- You can place the `groqbash` file in **any directory**.  
- On first run, GroqBash automatically creates:

`
groqbash.d/
`

next to the binary, with the required runtime structure.  
- **Extras** (external providers, UI, security tools, tests, docs) are **optional** and always live under:

`
groqbash.d/extras/
`

---

## 1. Requirements

### Required (core GroqBash)
- **bash**
- **curl**
- **coreutils** (at least: `mktemp`, `chmod`, `mv`, `mkdir`, `head`, `sed`, `awk`, `grep`)
- **jq**

### Recommended
- **python3** — optional fsync/serialization helper  
- **sha256sum / shasum** — for checks and future extras updates  
- POSIX‑like environment (Linux, macOS, BusyBox, WSL, Cygwin/MSYS2)

### Locale
GroqBash requires UTF‑8:

`sh
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
`

---

## 2. Minimal installation (core)

### 2.1 Download GroqBash

`sh
curl -O https://raw.githubusercontent.com/kamaludu/groqbash/main/bin/groqbash
`

### 2.2 Make it executable

`sh
chmod +x groqbash
`

### 2.3 (Optional) Add to PATH

`sh
mkdir -p "$HOME/.local/bin"
mv groqbash "$HOME/.local/bin/groqbash"
export PATH="$HOME/.local/bin:$PATH"
`

### 2.4 First run and auto‑setup

`sh
groqbash --version
`

On first run, GroqBash automatically creates:

`
groqbash.d/
  config/
  models/
  history/
  tmp/
  logs/
  extras/        (empty, ready for optional extras)
`

Everything is created next to the binary, with restrictive permissions (dirs 700, files 600).

---

## 3. Embedded provider and API keys

GroqBash includes an **embedded provider**, so it works even without extras.

To use external providers (e.g. Groq API):

`sh
export GROQ_API_KEY="gsk_XXXXXXXXXXXXXXXX"
`

---

## 4. Installing extras (optional)

Extras may include:

- additional external providers  
- web UI (CGI)  
- security tools  
- test suite  
- additional documentation (e.g. `extras/docs/help.txt`)

Extras are **always local** and live in:

`
<SCRIPTDIR>/groqbash.d/extras/
`

where `<SCRIPTDIR>` is the directory containing the `groqbash` file.

### 4.1 Extras source

Currently, GroqBash expects extras to come from a local `extras/` directory, for example:

- cloned repository:  
  `repo/extras/`  
- or a distributed package containing an `extras/` directory

No automatic download from the Internet is assumed.

---

### 4.2 Installation with `--install-extras`

Once implemented, the command:

`sh
groqbash --install-extras
`

will:

- search for a local `extras/` source (e.g. `<SCRIPTDIR>/extras/` or `<SCRIPTDIR>/../extras/`)  
- copy content **non‑destructively** into:

  `
  <SCRIPTDIR>/groqbash.d/extras/
  `

- **never** create symlinks (only real copies)  
- **never** overwrite user‑modified files by default  
- be **idempotent**: running it multiple times should not break anything

#### Selective installation (planned behavior)

In the future, you will be able to install only specific components, e.g.:

`sh
groqbash --install-extras providers ui security
`

where names correspond to subdirectories of `extras/` (e.g. `extras/providers/`, `extras/ui/`, etc.).

If a requested component does not exist in the source, it will be skipped with an informational message.

> Note: if you are using a version where `--install-extras` is not yet implemented, use the manual procedure below.

---

### 4.3 Manual extras installation (currently effective)

Until `--install-extras` is implemented in your version, you can install extras by **manually copying** the repository’s `extras/` directory into the runtime destination.

Example (repo and binary in the same directory):

`sh
# You are in: repo/
cp -r extras/* ./groqbash.d/extras/
`

Example (binary in `$HOME/.local/bin`, repo elsewhere):

`sh
# Binary path
BIN="$HOME/.local/bin/groqbash"
SCRIPTDIR="$(cd "$(dirname "$BIN")" && pwd)"

# Cloned repository path
REPO="$HOME/src/groqbash"

# Copy extras into runtime destination
mkdir -p "$SCRIPTDIR/groqbash.d/extras"
cp -r "$REPO/extras/"* "$SCRIPTDIR/groqbash.d/extras/"
`

After copying, the core still works as before, but you gain:

- external providers  
- UI (if present in `extras/ui/`)  
- security tools  
- test suite  
- extended help (e.g. `extras/docs/help.txt`)

---

## 5. Temporary files

- GroqBash **never uses `/tmp`** for internal temporary files.  
- Temporary files live in:

`
groqbash.d/tmp/
`

- Permissions: 700  
- With `--debug`, temporary files are preserved for inspection.

---

## 6. Output path (`--out`)

If you pass `--out /path/file`, GroqBash:

- tries to create the directory  
- checks permissions and safety  
- saves the file with restrictive permissions (600)

If the directory is unsafe or not writable:

- it **does not** use `/tmp`  
- it prints output to the terminal  
- it shows an explicit message

**Tip:** use paths under your home or under `groqbash.d/`.

---

## 7. Basic usage and examples

Simple prompt:

`sh
groqbash "write a bash function that..."
`

Pipe input:

`sh
echo "Explain this code" | groqbash
`

File input:

`sh
groqbash -f input.txt
`

Force saving:

`sh
groqbash --save --out output.txt "long text..."
`

Dry run (show JSON payload):

`sh
groqbash --dry-run "hello"
`

Provider (if extras installed):

`sh
groqbash --provider gemini "translate this"
`

---

## 8. Exit codes

| Code | Meaning                                      |
|------:|----------------------------------------------|
| **0** | Success                                      |
| **1** | Generic error (args, files, config)          |
| **2** | Network / curl error                         |
| **3** | HTTP/API error (4xx/5xx)                     |
| **4** | No textual content extracted (parsing error) |

Operational notes:
- Code 2 → automatic retries may be appropriate (timeout, DNS, connection refused)  
- Code 3 → no retry (API errors, auth, limits)  
- With `--debug`, full logs are in `groqbash.d/tmp/`

---

## 9. Troubleshooting and tests

Check JSON payload:

`sh
groqbash --dry-run "Test payload with \"quotes\" and newlines\nand unicode: € ✓"
`

Pipe input:

`sh
echo "Explain this code" | groqbash
`

Invalid API key:

`sh
GROQ_API_KEY="invalid" groqbash "hello" || echo "exit:$?"
`

Test without jq (debug only):

`sh
mv /usr/bin/jq /usr/bin/jq.bak
groqbash --dry-run "test"
mv /usr/bin/jq.bak /usr/bin/jq
`

---

## 10. Termux installation (Android)

`sh
pkg update
pkg install -y bash curl jq python
mkdir -p "$HOME/.local/bin"
mv groqbash "$HOME/.local/bin/groqbash"
chmod +x "$HOME/.local/bin/groqbash"
export PATH="$HOME/.local/bin:$PATH"
export GROQ_API_KEY="gsk_..."
groqbash --version
`

---

## 11. Final notes

- GroqBash is designed for **single‑user** environments.  
- Extras are **optional** and always live in `groqbash.d/extras/`.  
- Model output is never executed as code.  
- See `SECURITY.md` for security details.
