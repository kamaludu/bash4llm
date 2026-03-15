[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLATION [🇮🇹](INSTALL.md) 🇬🇧

GroqBash is a portable and secure Bash wrapper for the Groq API.  
It does not require Python or external dependencies beyond POSIX/coreutils commands.

---

## 1. Requirements

GroqBash requires the following packages (or equivalent) to be available in the PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

These packages provide all the necessary commands:
*bash* ` mv cp chmod stat find sort head wc tee date curl jq flock base64 mktemp readlink awk sed grep xargs sync sha256sum stdbuf `

### Compatibility

GroqBash works on:

- GNU/Linux
- macOS (with GNU packages - installable via Homebrew)
- BusyBox/Alpine
- WSL and Cygwin (Windows)
- Termux (Android)

---

## 2. Basic installation

### 2.1 Clone or download GroqBash

`git clone https://github.com/<your-repo>/groqbash.git`  
`cd groqbash`

Or download the `groqbash` file and make it executable:

`chmod +x groqbash`

### 2.2 Set the API key

GroqBash uses the variable:

`export GROQ_API_KEY="your_key"`

You can add it to your `.bashrc` or `.zshrc`.

---

## 3. Directory structure

On first run, GroqBash automatically creates:
`
groqbash.d/
    config/
    models/
    templates/
    history/
    tmp/
    extras/
        providers/
`
All directories are created with 700 permissions (best‑effort on non‑POSIX filesystems).

---

## 4. Quick usage

### Single prompt

`./groqbash -m mixtral-8x7b -- "Write a haiku about the wind."`

### Streaming mode

`./groqbash --stream -- "Generate streaming text."`

### Input from file

`./groqbash -f input.txt`

### JSON output

`./groqbash --json -- "What do you know about Bash?"`

---

## 5. Models

### Update the model list

`./groqbash --refresh-models`

The list is saved in:

`groqbash.d/models/models.txt`

### List models

`./groqbash --list-models`

---

## 6. History and autosave

GroqBash automatically saves output when:

- it exceeds a certain size (THRESHOLD, default 1000 bytes), or  
- `--save` is active.

Files are saved in:

`groqbash.d/history/`

Rotation is configurable via:

- GROQBASH_ROTATE_HISTORY  
- GROQBASH_HISTORY_MAX_FILES  
- GROQBASH_HISTORY_MAX_BYTES  
- GROQBASH_HISTORY_KEEP_DAYS  

---

## 7. Installing extras (option `--install-extras`)

GroqBash includes a secure and portable installer to copy additional components (scripts, providers, templates, documentation) into the directory:

`groqbash.d/extras/`

### 7.1 Basic usage

`./groqbash --install-extras`

If you don’t specify components, **all** files in the extras source directory are installed.

### 7.2 Install specific components

`./groqbash --install-extras provider1 templateA`

### 7.3 Custom source

`./groqbash --install-extras --source /path/to/extras`

### 7.4 Overwrite conflicting files

`./groqbash --install-extras --force`

### 7.5 Dry‑run mode

`./groqbash --install-extras --dry-run`

No files are modified.

---

## 8. Installer behavior (technical details)

### 8.1 Security and atomicity

- Each file is copied using:
  - mktemp  
  - cat (portable)  
  - atomic mv -f  
- Each operation is protected by a lock (flock) on:
  `groqbash.d/extras/.install.lock`

### 8.2 Permissions

- Regular files → chmod 600  
- Executable files → chmod 700  
- If the filesystem does not support permissions (NTFS/WSL), GroqBash shows a **warning**, not an error.

### 8.3 Symlinks

- Symlinks in the source are resolved safely.  
- If they point outside the source directory → **they are rejected**.

### 8.4 Conflicts

- If a file already exists and **is different**, GroqBash:
  - shows a **warning**,  
  - **does not overwrite**,  
  - **does not fail** (exit code 0),  
  - unless `--force` is used.

### 8.5 Lock timeout

The lock timeout is configurable:

`export GROQBASH_LOCK_TIMEOUT_MODELS=10`

Default: **10 seconds**.

---

## 9. Useful environment variables

- GROQ_API_KEY — Groq API key  
- MODEL — default model  
- TURE / TEMPERATURE — temperature  
- MAX_TOKENS  
- OUTPUT_MODE — text, raw, json, pretty  
- GROQBASH_DEBUG=1 — enable detailed logs  
- ALLOW_API_CALLS=0 — block real API calls (useful for testing)

---

## 10. Portability and filesystem notes

### 10.1 NTFS / WSL

- chmod may fail → GroqBash shows a warning.  
- Operations remain atomic.

### 10.2 NFS

- flock may be unreliable → GroqBash shows a warning in debug mode.

### 10.3 BusyBox

- All functions are compatible.

---

## 11. Uninstallation

To remove GroqBash:

`rm -rf groqbash.d`  
`rm groqbash`

---

## 12. Troubleshooting

### No response from the model

- Check GROQ_API_KEY  
- Check network connection  
- Enable debug:  
  `GROQBASH_DEBUG=1 ./groqbash -- "test"`

### Permission error

Likely a non‑POSIX filesystem (NTFS).  
GroqBash continues installation anyway.

### Lock timeout

Increase:

`export GROQBASH_LOCK_TIMEOUT_MODELS=30`

---

## 13. License

GroqBash is distributed under the [**GNU GPL v3**](LICENSE)
