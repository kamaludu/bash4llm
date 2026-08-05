[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README-en.md)

# INSTALLATION GUIDE FOR BASH4LLM⁺ [🇮🇹](INSTALL.md) 🇬🇧

Bash4LLM⁺ is a portable Bash CLI wrapper designed for interfacing with various LLM provider APIs. It operates without external dependencies like Python or Node.js, relying strictly on standard POSIX system utilities and shell builtins.

---

## 1. System Requirements

Bash4LLM⁺ requires the following core system utilities to be present in your `PATH`:

- **bash** (version 4.0 or higher for associative array support)
- **coreutils** (`cat`, `chmod`, `cp`, `date`, `head`, `mktemp`, `mv`, `printf`, `rm`, `sort`, `stat`, `tr`, `wc`, `tee`)
- **findutils** (`find`)
- **util-linux** (`xargs`)
- **awk**, **sed**, **grep**, **comm**
- **curl**
- **jq**

*Note on concurrency: System `flock` is optional. On environments with restricted flock support (e.g., Android/Termux), the script transparently shifts concurrency management to atomic directory locking (`mkdir`).*

### Supported Platforms

Verified operational environments:

- **GNU/Linux** (All standard distributions)
- **macOS** (Built-in system binaries or Homebrew GNU packages)
- **WSL and Cygwin** (Windows)
- **Termux** (Android)
- **BSD** (FreeBSD, OpenBSD, NetBSD, DragonFly)

---

## 2. Installation Procedure

### 2.1 Direct Setup

To download and set up the main executable from a terminal:

```sh
# 1. Clone repository (shallow clone)
git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  

# 2. Create workspace directory and extract executable
mkdir -p bash4llm
cp repo-bash4llm/bash4llm bash4llm/
chmod +x bash4llm/bash4llm

# 3. Enter folder and synchronize model catalog
cd bash4llm 
./bash4llm --refresh-models
```

If no API key is set in environment variables or saved, the script will prompt for masked entry:
`Enter API key for provider groq (env GROQ_API_KEY):`

To retain the API key in active RAM for your current terminal session:
```sh
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
```

---

### 2.2 Installing Optional Extras (`--install-extras`)

Extension modules (secondary providers such as Gemini, Mistral, and Hugging Face, TUI interactive chat, Vault console, and Session Engine) reside in `extras/`. To install them locally:

```sh
./bash4llm --install-extras ../repo-bash4llm/extras/
```

### Installer Security Controls:
1. **SHA-256 Integrity Check**: Copied modules are validated against `extras/manifest.sha256`. Any hash mismatch halts installation with exit code `17` (`BASH4LLM_ERR_SEC`).
2. **File Permissions**: Files are written with restrictive permissions (`0700` for directories/executables, `0600` for configuration and documentation files).
3. **Symlink Rejection**: The installer rejects symbolic links to prevent Directory Traversal vulnerabilities.

---

## 3. Directory Layout

On initial launch, the script generates its isolated working directory `bash4llm.d/` with strict POSIX permissions (`0700` for directories, `0600` for files):

```text
bash4llm.d/
├── config/                                # Provider configuration and state
│   ├── config                             # Global user parameters
│   ├── provider                           # Active provider identifier
│   ├── provider-url                       # Active provider API URL
│   ├── model.<provider>                   # Default model for active provider
│   ├── keys.enc                           # Encrypted Vault Master key database
│   ├── keys.rec                           # Offline encrypted recovery key
│   ├── keys.dat                           # Encrypted API keys data payload
│   ├── providers/                         # Advanced provider configurations
│   │   └── hf_endpoints                   # Hugging Face model/endpoint map
│   └── ui_state/                          # JSON state files for GUI/automation
│       ├── last_api.json                  # Last API call status
│       ├── last_history.json              # Last saved output status
│       ├── provider_capabilities.json     # Active provider features
│       └── threads/                       # Thread index and status files
│           ├── index.json                 # Active threads index
│           └── <safe_thread_id>.json      # Thread status metadata (SHA-256)
├── models/                                # Local model cache per provider
│   └── <provider>.txt                     # Validated models list
├── templates/                             # Reusable prompt templates
├── history/                               # Saved interaction outputs
│   └── threads/                           # Conversational history (.ndjson)
│       └── <safe_thread_id>.ndjson        # Conversation log in NDJSON
├── var/                                   # Isolated runtime process files
│   └── run/                              # Process execution directory (0700)
│       └── locks/                         # Concurrency lock files (0700)
│           ├── models.lock                # Model synchronization lock
│           ├── history.lock               # History and thread lock
│           └── tmp.lock                   # Temporary file allocation lock
├── tmp/                                   # Isolated temporary directory (0700)
│   └── rates/                             # Rate limiting timestamp tracking (0700)
│       └── <safe_thread_id>/              # Sliding-window timestamps
└── extras/                                # Extension components
    ├── manifest.sha256                    # Cryptographic SHA-256 integrity manifest
    ├── chat/                              # TUI REPL interface (tui-repl.sh)
    ├── hooks/                             # Execution hook modules
    ├── security/                          # OpenSSL security helper (openssl-helper.sh)
    ├── providers/                         # External providers (Gemini, Hugging Face, Mistral)
    └── session/                           # Advanced session engine (session-engine.sh)
```

---

## 4. Encrypted Key Management (Security Vault)

When `extras/` is installed and `openssl` is available on the host system, API keys can be encrypted on disk using the integrated Vault console:

```sh
./bash4llm --vault
```

### Vault Functionality:
* **At-Rest Encryption**: Keys are encrypted using AES-256-CBC with PBKDF2 key derivation (100,000 iterations) and saved to `keys.dat`.
* **RAM Session Unlock**: Unlock the Vault for your active shell session by sourcing the script:
  ```sh
  . ./bash4llm
  ```
  This temporarily caches the obfuscated session token `_B4L_RT_CTX` in process RAM, bypassing password prompts until the shell terminates.
* **Disabling the Vault**: To disable Vault lookups, set `BASH4LLM_VAULT_ENABLED=0`.

---

## 5. Troubleshooting & Error Resolution

### Security Violation (Exit Code 17 - BASH4LLM_ERR_SEC)
Execution halts with exit code `17` if a security policy violation is detected:
* **Insecure File Permissions**: Configuration files or directories are group/world-writable.
* **Symlink Detected**: An unauthorized symbolic link exists on a critical working path.
* **Checksum Mismatch**: A module file in `extras/` does not match its SHA-256 digest in `manifest.sha256`.

Restoring standard POSIX permissions:
```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config
```

### Rate Limiter Throttling
Submitting requests exceeding the allowed quota within a 30-second window causes a rate limit halt (exit code `17`). Adjust or bypass the quota using:
```sh
export BASH4LLM_RATE_LIMIT=10  # Allows 10 requests per 30-second window per thread
```

### Concurrency Lock Timeout (Exit Code 15 - BASH4LLM_ERR_TMP)
If concurrent execution causes lock acquisition timeouts, extend the maximum wait timeout (in seconds):
```sh
export BASH4LLM_LOCK_TIMEOUT_HISTORY=30
```

---

## 6. Uninstallation

Bash4LLM⁺ is fully self-contained. To completely remove the software and runtime data, delete the executable and runtime directory:

```sh
rm -rf bash4llm.d
rm bash4llm
```

---

## 7. License

Bash4LLM⁺ is open-source software distributed under the [**GNU GPL v3.0**](LICENSE) license.
