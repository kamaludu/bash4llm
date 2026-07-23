[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README-en.md)
# INSTALLATION [🇮🇹](INSTALL.md) 🇬🇧

Bash4LLM⁺ is a portable and secure Bash-first wrapper for querying various LLM provider APIs (featuring native support for Groq).  
It requires no Python runtime or external dependencies beyond standard POSIX/coreutils utilities and shell tools.

---

## 1. System Requirements

Bash4LLM⁺ requires the following **23 core system utilities** to be present in your `PATH`:

- **bash** (version 4.0 or higher for associative arrays and in-process caching support)
- **coreutils** (`cat`, `chmod`, `cp`, `date`, `head`, `mktemp`, `mv`, `printf`, `rm`, `sort`, `stat`, `tr`, `wc`, `tee`)
- **findutils** (`find`)
- **util-linux** (`xargs`)
- **awk**, **sed**, **grep**, **comm**
- **curl**
- **jq**

*Note: The `flock` utility is not mandatory; if absent (e.g., in Termux/Android environments), the script automatically falls back to atomic directory locks.*

### Platform Compatibility

Bash4LLM⁺ is tested and supported on:

- **GNU/Linux** (All major distributions)
- **macOS** (Using built-in system tools or Homebrew GNU packages)
- **WSL and Cygwin** (Windows)
- **Termux** (Android)
- **BSD** (FreeBSD, OpenBSD, NetBSD, DragonFly)

---

## 2. Fast Forward Installation

> [!TIP]
> **⏩ FAST FORWARD (Quick Start Installation)**
> 
> Execute these commands in your terminal to quickly download and set up **Bash4LLM⁺**:
> 
> ```sh
> # 1. Clone the repository (latest commit only for maximum speed)
> git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  
> 
> # 2. Create a working directory and extract the executable
> mkdir -p bash4llm
> cp repo-bash4llm/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
> 
> # 3. Enter the folder and refresh local model lists 
> cd bash4llm 
> ./bash4llm --refresh-models
> ```
> 
> If no saved API key is detected, the script will prompt for input interactively:  
> `Enter API key for provider groq (env GROQ_API_KEY):`
> 
> Enter your Groq API key. To avoid re-entering it in subsequent commands during the current terminal session, export it:
> 
> `export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`
> 
> Recommended: ***install the optional Extras package*** (additional providers, Security Vault, TUI chat REPL, templates):
> ```sh
> # 4. Install Extras components
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Use Bash4LLM ⚡

---

### 2.1 Manual Installation

If you download the standalone `bash4llm` executable directly, make it executable using standard POSIX permissions:

```sh
chmod +x bash4llm
```

---

### 2.2 Setting Up Your API Key

Bash4LLM⁺ retrieves the API key from environment variables. You can export it in your shell configuration file (e.g., `~/.bashrc`, `~/.bash_profile`, or `~/.zshrc`):

```sh
export GROQ_API_KEY="your_api_key_here"
```

Alternatively, you can store your API keys in encrypted form on disk using the built-in **Security Vault** (see Section 4).

---

## 3. Directory Structure

Upon first execution, Bash4LLM⁺ automatically creates its isolated workspace inside the runtime directory (`bash4llm.d/`), applying strict POSIX permissions (`700` for directories, `600` for files):

```text
bash4llm.d/
├── config/                                # Provider configuration and persistence
│   ├── config                             # Global user parameters and variables
│   ├── provider                           # Active provider name
│   ├── provider-url                       # Active provider API URL
│   ├── model.<provider>                   # Default model for active provider
│   ├── keys.enc                           # Encrypted API keys database (Vault)
│   ├── keys.rec                           # Offline encrypted recovery key (Vault)
│   ├── keys.dat                           # Encrypted API keys data payload
│   ├── providers/                         # Advanced provider configurations
│   │   └── hf_endpoints                   # Hugging Face endpoint/model mapping
│   └── ui_state/                          # JSON state files for GUI/automation
│       ├── last_api.json                  # State of last API call
│       ├── last_history.json              # State of last saved output
│       ├── provider_capabilities.json     # Active provider features
│       └── threads/                       # Thread metadata and index
│           ├── index.json                 # List of active threads
│           └── <safe_thread_id>.json      # Single thread status metadata (SHA-256)
├── models/                                # Model whitelists per provider
│   └── <provider>.txt                     # Validated models list
├── templates/                             # Reusable prompt templates
├── history/                               # Response outputs and history
│   └── threads/                           # Conversational history (.ndjson anonymized)
│       └── <safe_thread_id>.ndjson        # Conversation log in NDJSON
├── var/                                   # Isolated runtime process files
│   └── run/                              # Runtime process directory (700)
│       └── locks/                         # Isolated locks directory (700)
│           ├── models.lock                # Synchronization lock for models
│           ├── history.lock               # Synchronization lock for history
│           └── tmp.lock                   # Lock for temporary allocation
├── tmp/                                   # Protected temporary directory (700)
│   └── rates/                             # Rate-limiting transaction tracking (700)
│       └── <safe_thread_id>/              # Sliding-window request timestamps
└── extras/                                # Optional components and extensions
    ├── manifest.sha256                    # SHA-256 cryptographic integrity manifest
    ├── chat/                              # TUI REPL interface (tui-repl.sh)
    ├── hooks/                             # Pre/Post execution hook modules (hook.sh)
    ├── security/                          # Vault and security helpers (openssl-helper.sh)
    ├── providers/                         # External provider modules (Gemini, Hugging Face, Mistral)
    └── session/                           # Advanced session engine (session-engine.sh)
```

---

## 4. Encrypted Credential Management (Security Vault)

When the Extras package is installed and the `openssl` binary is available on your host, you can avoid storing plain-text API keys in environment variables by using the integrated cryptographic console:

```sh
./bash4llm --vault
```

### Vault Features:
* **At-Rest Encryption**: API keys are encrypted using AES-256-CBC with PBKDF2 key derivation (100,000 iterations) and saved to `bash4llm.d/config/keys.dat`.
* **RAM Session Unlock**: You can unlock the Vault for your active terminal session by sourcing the script:
  ```sh
  . ./bash4llm
  ```
  This temporarily caches the obfuscated session token `_B4L_RT_CTX` in shell memory, bypassing password prompts across commands until the terminal closes.
* **Bypassing the Vault**: You can disable Vault lookups by exporting `BASH4LLM_VAULT_ENABLED=0`.

---

## 5. Installing Extras (`--install-extras`)

To enable advanced features (such as the Vault console, interactive TUI chat REPL, Session Engine, or external providers like Gemini, Mistral, and Hugging Face), install the Extras package:

```sh
./bash4llm --install-extras
```

If executing from outside the cloned repository directory, specify the explicit source path of the `extras` folder:

```sh
./bash4llm --install-extras /path/to/source/extras
```

### Installer Security & Integrity Invariants:
1. **SHA-256 Integrity Check**: All copied files are cryptographically validated against `manifest.sha256`. Any tampered file triggers an immediate safety warning.
2. **Atomic & Protected Copying**: Files are copied under exclusive locks applying restrictive permissions (`700` for directories/executables, `600` for configuration and documentation files).
3. **Symlink Rejection**: The installer rejects symbolic links to prevent Directory Traversal attacks.

---

## 6. Troubleshooting & Problem Resolution

### Security Error (Exit Code 17 - BASH4LLM_ERR_SEC)
If execution halts with exit code `17` (`BASH4LLM_ERR_SEC`), a security policy violation was detected:
* **Insecure Permissions**: Configuration files or runtime directories are group- or world-writable (`group/world-writable`).
* **Symlink Attack Detected**: An unauthorized symbolic link was detected on a critical execution path.
* **Code Tampering**: A module inside `extras/` does not match its SHA-256 checksum in `manifest.sha256`.

To restore compliant POSIX permissions, run:

```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config
```

### Rate Limiter Throttling
If you submit an excessive number of API requests within a 30-second window, the local rate limiter will block execution with exit code `17`. You can adjust the limit or bypass it using environment variables:

```sh
export BASH4LLM_RATE_LIMIT=10  # Allows 10 requests per 30-second window per thread
```

### Filesystem Lock Timeouts
If you encounter a lock timeout error (`Exit Code 15`) due to concurrent process access, you can extend the maximum lock wait time (in seconds):

```sh
export BASH4LLM_LOCK_TIMEOUT_HISTORY=30
```

---

## 7. Uninstallation

Bash4LLM⁺ is fully self-contained. To completely remove it from your system, delete the executable and its runtime directory:

```sh
rm -rf bash4llm.d
rm bash4llm
```

---

## 8. License

Bash4LLM⁺ is free software distributed under the [**GNU GPL v3**](LICENSE) license.
