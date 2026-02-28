[![GroqBash](https://img.shields.io/badge/_GroqBash_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# INSTALLAZIONE  
**Lingue:**  
🇮🇹 Italiano (questa sezione)  
🇬🇧 [English version](#english-installation)

GroqBash è un eseguibile Bash **portabile e auto‑contenuto**.  
Puoi metterlo **ovunque**, anche da solo, e funziona immediatamente.  
Alla prima esecuzione crea automaticamente la directory:

`
groqbash.d/
`

accanto al binario, con tutta la struttura runtime necessaria.

Gli **extras** (UI, provider esterni, sicurezza, test) sono **opzionali**: GroqBash funziona anche senza.

---

# 1. Requisiti

## Necessari
- bash  
- curl  
- coreutils (mkdir, mv, chmod, mktemp, sed, awk, grep…)  
- jq  

## Ambienti supportati
- Linux  
- macOS  
- BusyBox / Alpine  
- Windows WSL  
- Windows Cygwin / MSYS2  

## Locale
GroqBash richiede UTF‑8:

`sh
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
`

---

# 2. Installazione minima (file singolo)

## 1) Scarica il binario

`sh
curl -O https://raw.githubusercontent.com/kamaludu/groqbash/main/bin/groqbash
`

## 2) Rendi eseguibile

`sh
chmod +x groqbash
`

## 3) (Opzionale) Mettilo nel PATH

`sh
mkdir -p "$HOME/.local/bin"
mv groqbash "$HOME/.local/bin/"
export PATH="$HOME/.local/bin:$PATH"
`

## 4) Prima esecuzione

`sh
groqbash --version
`

Alla prima esecuzione GroqBash crea automaticamente:

`
groqbash.d/
  config/
  models/
  history/
  tmp/
  logs/
`

con permessi sicuri (700/600).

---

# 3. Provider embedded

GroqBash include un **provider interno** che funziona senza extras.  
Per usare provider esterni (Gemini, Mistral, HuggingFace) devi installare gli extras.

---

# 4. API key (per provider esterni)

`sh
export GROQ_API_KEY="gsk_XXXXXXXXXXXXXXXX"
`

---

# 5. Installazione degli extras (opzionale)

Gli extras includono:

- provider esterni  
- UI web (CGI)  
- strumenti di sicurezza  
- test suite  
- documentazione aggiuntiva  

Installa gli extras copiando la directory `extras/` del repository dentro:

`
groqbash.d/extras/
`

Esempio:

`sh
cp -r path/al/repo/extras/* groqbash.d/extras/
`

Gli extras **non sono obbligatori**: GroqBash funziona anche senza.

---

# 6. File temporanei

- GroqBash **non usa mai /tmp** del sistema.  
- I temporanei vivono in:

`
groqbash.d/tmp/
`

- Permessi: 700  
- Con `--debug`, i temporanei non vengono rimossi.

---

# 7. Output (`--out`)

Se passi `--out file.txt`:

- GroqBash crea la directory se sicura  
- salva con permessi 600  
- se la directory non è sicura → stampa su terminale

---

# 8. Esempi rapidi

`sh
groqbash "scrivi una funzione bash che..."
`

`sh
echo "Spiegami questo codice" | groqbash
`

`sh
groqbash -f input.txt
`

`sh
groqbash --dry-run "ciao"
`

`sh
groqbash --provider gemini "traduci questo"
`

---

# 9. Codici di uscita

| Codice | Significato |
|-------:|-------------|
| 0 | Successo |
| 1 | Errore generico |
| 2 | Errore di rete / curl |
| 3 | Errore HTTP/API |
| 4 | Nessun contenuto testuale estratto |

---

# 10. Troubleshooting

- **cannot create destination directory** → percorso non sicuro  
- **output non salvato** → `mv` fallito, controlla `groqbash.d/tmp/`  
- **JSON invalido** → controlla UTF‑8 e jq  

---

# 11. Note finali

- GroqBash è progettato per ambienti **single‑user**.  
- Gli extras sono **opzionali**.  
- Nessun output viene mai eseguito come comando.  
- Per la sicurezza vedi `SECURITY.md`.

---
🇬🇧
# English Installation  
*(Jump here from top: English version)*

GroqBash is a **portable, self‑contained Bash executable**.  
You can place it **anywhere**, even alone, and it works immediately.  
On first run it automatically creates:

`
groqbash.d/
`

next to the binary, with all required runtime directories.

Extras (UI, external providers, security tools, tests) are **optional**.

---

## 1. Requirements

### Required
- bash  
- curl  
- coreutils  
- jq  

### Supported environments
- Linux  
- macOS  
- BusyBox / Alpine  
- Windows WSL  
- Windows Cygwin / MSYS2  

### Locale
GroqBash requires UTF‑8:

`sh
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
`

---

## 2. Minimal installation (single file)

### 1) Download

`sh
curl -O https://raw.githubusercontent.com/kamaludu/groqbash/main/bin/groqbash
`

### 2) Make executable

`sh
chmod +x groqbash
`

### 3) (Optional) Add to PATH

`sh
mkdir -p "$HOME/.local/bin"
mv groqbash "$HOME/.local/bin/"
export PATH="$HOME/.local/bin:$PATH"
`

### 4) First run

`sh
groqbash --version
`

GroqBash will automatically create:

`
groqbash.d/
  config/
  models/
  history/
  tmp/
  logs/
`

---

## 3. Embedded provider

GroqBash includes an **embedded provider** so it works even without extras.

---

## 4. API key (for external providers)

`sh
export GROQ_API_KEY="gsk_XXXXXXXXXXXXXXXX"
`

---

## 5. Optional extras

Extras include:

- external providers  
- web UI (CGI)  
- security tools  
- test suite  
- additional docs  

Install them by copying the repository’s `extras/` directory into:

`
groqbash.d/extras/
`

Example:

`sh
cp -r path/to/repo/extras/* groqbash.d/extras/
`

Extras are **not required**.

---

## 6. Temporary files

- GroqBash **never uses /tmp**.  
- Temporary files live in:

`
groqbash.d/tmp/
`

- Permissions: 700  
- With `--debug`, temporary files are preserved.

---

## 7. Output (`--out`)

If you pass `--out file.txt`:

- GroqBash creates the directory if safe  
- saves with permissions 600  
- if unsafe → prints to terminal instead

---

## 8. Quick examples

`sh
groqbash "write a bash function that..."
`

`sh
echo "Explain this code" | groqbash
`

`sh
groqbash -f input.txt
`

`sh
groqbash --dry-run "hello"
`

`sh
groqbash --provider gemini "translate this"
`

---

## 9. Exit codes

| Code | Meaning |
|------:|---------|
| 0 | Success |
| 1 | Generic error |
| 2 | Network / curl error |
| 3 | HTTP/API error |
| 4 | No textual content extracted |

---

## 10. Troubleshooting

- **cannot create destination directory** → unsafe path  
- **output not saved** → `mv` failed, check `groqbash.d/tmp/`  
- **invalid JSON** → check UTF‑8 locale and jq  

---

## 11. Final notes

- GroqBash is designed for **single‑user** environments.  
- Extras are **optional**.  
- Model output is never executed as code.  
- See `SECURITY.md` for details.
