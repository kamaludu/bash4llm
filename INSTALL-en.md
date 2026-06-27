[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
# INSTALLATION [🇮🇹](INSTALL.md) 🇬🇧

**Bash4LLM** is a portable and secure Bash wrapper for the Groq API.  
It does not require Python nor external dependencies beyond POSIX/coreutils commands.

---

## 1. Requirements

Bash4LLM requires the following packages (or equivalents) to be available in PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

### Compatibility

Bash4LLM works on:

- GNU/Linux  
- macOS (with GNU packages installable via Homebrew)  
- WSL and Cygwin (Windows)  
- Termux (Android)  
- BSD  

---

## 2. Basic installation

> [!TIP]
> **⏩ FAST FORWARD (Quick Install)**  
> Run these commands in your terminal to start using **Bash4LLM⁺** immediately:
>
> ```sh
> # 1. Clone the repository (only the latest commit for speed)
> git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm
>
> # 2. Create a working folder and extract the executable
> mkdir -p bash4llm
> cp repo-bash4llm/bin/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
>
> # 3. Enter the folder and refresh models
> cd bash4llm
> ./bash4llm --refresh-models
> ```
>
> The script will ask you to enter your API key for the default provider (Groq):
> `Enter API key for provider groq (env GROQ_API_KEY):`
>
> Enter your API key, then export it to avoid retyping during the session:
> `export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`
>
> Recommended: ***Install Optional Extras***:
> ```sh
> # 4. Installing Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Use Bash4llm ⚡
> 

### 2.1 Clone or download Bash4LLM

`git clone https://github.com/<your-repo>/bash4llm.git`  
`cd bash4llm`

Or download the `bash4llm` file and make it executable:

`chmod +x bash4llm`

### 2.2 Set the API key

Bash4LLM uses the variable:

`export GROQ_API_KEY="your_key"`

You can place it in your `.bashrc` or `.zshrc`.

---

## 3. Directory structure

On first execution, Bash4LLM automatically creates:
```
bash4llm.d/
    config/
    models/
    templates/
    history/
    tmp/
    extras/
        providers/
```
All directories are created with permissions 700 (best‑effort on non‑POSIX filesystems).

---

## 4. Quick usage

### Single prompt

`./bash4llm -m mixtral-8x7b -- "Write a haiku about the wind."`

### Streaming mode

`./bash4llm --stream -- "Generate text in streaming."`

### Input from file

`./bash4llm -f input.txt`

### JSON output

`./bash4llm --json -- "What do you know about Bash?"`

---

## 5. Models

### Refresh the model list

`./bash4llm --refresh-models`

The list is saved in:

`bash4llm.d/models/models.txt`

### List models

`./bash4llm --list-models`

---

## 6. History and automatic saving

Bash4LLM automatically saves output when:

- it exceeds a certain size (THRESHOLD, default 1000 bytes), or  
- `--save` is active.

Files are saved in:

`bash4llm.d/history/`

Rotation is configurable via:

- BASH4LLM_ROTATE_HISTORY  
- BASH4LLM_HISTORY_MAX_FILES  
- BASH4LLM_HISTORY_MAX_BYTES  
- BASH4LLM_HISTORY_KEEP_DAYS  

---

## 7. Installing extras (`--install-extras` option)

Bash4LLM includes a secure and portable installer to copy additional components (scripts, providers, templates, documentation) into:

`bash4llm.d/extras/`

### 7.1 Basic usage

`./bash4llm --install-extras`

If you do not specify components, **all** files in the extras source directory are installed.

### 7.2 Install specific components

`./bash4llm --install-extras provider1 templateA`

### 7.3 Custom source

`./bash4llm --install-extras --source /path/to/extras`

### 7.4 Overwrite conflicting files

`./bash4llm --install-extras --force`

### 7.5 Dry‑run mode

`./bash4llm --install-extras --dry-run`

No files are modified.

---

## 8. Installer behavior (technical details)

### 8.1 Security and atomicity

- Each file is copied using:
  - mktemp  
  - cat (portable)  
  - atomic mv -f  
- Each operation is protected by a lock (flock) on:  
  `bash4llm.d/extras/.install.lock`

### 8.2 Permissions

- Regular files → chmod 600  
- Executable files → chmod 700  
- If the filesystem does not support permissions (NTFS/WSL), Bash4LLM shows a **warning**, not an error.

### 8.3 Symlinks

- Symlinks in the source are resolved safely.  
- If they point outside the source directory → **they are rejected**.

### 8.4 Conflicts

- If a file already exists and **is different**, Bash4LLM:
  - shows a **warning**,  
  - **does not overwrite**,  
  - **does not fail** (exit code 0),  
  - unless `--force` is used.

### 8.5 Lock timeout

Lock timeout is configurable:

`export BASH4LLM_LOCK_TIMEOUT_MODELS=10`

Default: **10 seconds**.

---

## 9. Useful environment variables

- GROQ_API_KEY — Groq API key  
- MODEL — default model  
- TURE / TEMPERATURE — temperature  
- MAX_TOKENS  
- OUTPUT_MODE — text, raw, json, pretty  
- BASH4LLM_DEBUG=1 — enables detailed logs  
- ALLOW_API_CALLS=0 — blocks real API calls (useful for testing)

---

## 10. Portability and filesystem notes

### 10.1 NTFS / WSL

- chmod may fail → Bash4LLM shows a warning.  
- Operations remain atomic.

### 10.2 NFS

- flock may be unreliable → Bash4LLM shows a warning in debug mode.

### 10.3 BusyBox

- All functions are compatible.

---

## 11. Uninstallation

To remove Bash4LLM:

`rm -rf bash4llm.d`  
`rm bash4llm`

---

## 12. Troubleshooting

### No response from model

- Check GROQ_API_KEY  
- Check network connection  
- Enable debug:  
  `BASH4LLM_DEBUG=1 ./bash4llm -- "test"`

### Permission error

Likely a non‑POSIX filesystem (NTFS).  
Bash4LLM continues installation anyway.

### Lock timeout

Increase:

`export BASH4LLM_LOCK_TIMEOUT_MODELS=30`

---

## 13. License

Bash4LLM is distributed under the `[Sembra che non fosse sicuro mostrare il risultato. Cambiamo le cose e facciamo un altro tentativo.]`.

---
