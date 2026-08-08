[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README-en.md)

# INSTALLATION GUIDE FOR BASH4LLM⁺ [🇮🇹](INSTALL.md) 🇬🇧

---

## 1. System Requirements

Bash4LLM⁺ requires the following system packages and utilities to be installed and accessible in `PATH` (strictly verified at bootstrap by the core):

- **bash** (version 4.0 or higher for associative array support)
- **coreutils** (`cat`, `chmod`, `cp`, `date`, `head`, `mktemp`, `mv`, `printf`, `rm`, `sort`, `stat`, `tr`, `wc`, `tee`, `base64`)
- **findutils** (`find`)
- **util-linux** (`xargs`)
- **awk**, **sed**, **grep**, **comm**
- **curl**
- **jq**

*Note on concurrency: The use of `flock` is optional. On systems where `flock` is restricted or absent (e.g., Android/Termux), the script detects the environment and redirects lock management to atomic directory allocations (`mkdir`).*

### Platform Compatibility

The runtime is verified on the following environments:

- **GNU/Linux** (All standard distributions)
- **macOS** (Stock system utilities or GNU packages from Homebrew)
- **WSL and Cygwin** (Windows)
- **Termux** (Android)
- **BSD** (FreeBSD, OpenBSD, NetBSD, DragonFly)

---

## 2. Installation Procedure

### 2.1 Quick Execution from Repository

To download and configure the main executable from terminal:

```sh
# 1. Clone the repository (download limited to last commit)
git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  

# 2. Create working directory and copy main binary
mkdir -p bash4llm
cp repo-bash4llm/bash4llm bash4llm/
chmod +x bash4llm/bash4llm

# 3. Enter folder and synchronize models
cd bash4llm 
./bash4llm --refresh-models
```

If a saved or exported API key is not present in the environment variables, the script will prompt for masked interactive entry:
`Enter API key for provider groq (env GROQ_API_KEY):`

To keep the key active in RAM for the current terminal session:
```sh
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
```

---

### 2.2 Optional Extras Installation (`--install-extras`)

Additional modules (secondary providers such as Gemini, Mistral, and Hugging Face, interactive TUI chat, Vault console, and advanced session manager) are located in the `extras/` folder. To install them in the local environment:

```sh
./bash4llm --install-extras ../repo-bash4llm/extras/
```

### Installer Security Mechanisms:
1. **SHA-256 Integrity Verification and Ed25519 Signature**: Copied modules are verified against the cryptographic manifest `extras/manifest.sha256` and the author's Ed25519 signature (`manifest.sha256.sig`) via the public key `official-ed25519.pub`. Discrepancies, altered files, or invalid signatures halt the process with exit code `17` (`BASH4LLM_ERR_SEC`).
2. **Principle of Least Privilege and Filesystem Permissions**: Files are written applying restrictive `0700` permissions for directories and `0600` for configuration and module files. The execution bit (`700`) is granted granularly only to authorized CLI entrypoints (`security/output-sanitizer.sh`, `chat/tui-repl.sh`, test scripts).
3. **Symlink Rejection**: The installer refuses copying symbolic links to prevent directory traversal (*Directory Traversal*) vulnerabilities.

---

## 3. Runtime Directory Structure

At first launch, the script creates the isolated working directory `bash4llm.d/` applying POSIX permissions `0700` (directories) and `0600` (files):

```text
bash4llm.d/
├── config/                                # Configuration and provider persistence (700)
│   ├── config                             # User global variables and parameters (600)
│   ├── provider                           # Active provider name (600)
│   ├── provider-url                       # Active provider API URL (600)
│   ├── model.<provider>                   # Default model for the provider (600)
│   ├── keys.enc                           # Encrypted database of Master key (Vault) (600)
│   ├── keys.rec                           # Encrypted offline recovery key (Vault) (600)
│   ├── keys.dat                           # Encrypted API key payload (Vault) (600)
│   ├── thread_cache/                      # Isolated cache with TTL for thread windows (700)
│   ├── providers/                         # Advanced provider configurations (700)
│   │   └── hf_endpoints                   # Hugging Face models and endpoint mapping
│   └── ui_state/                          # JSON state files for GUI and automations (700)
│       ├── last_api.json                  # State of last API call (600)
│       ├── last_history.json              # State of last saved output (600)
│       ├── provider_capabilities.json     # Active provider capabilities (600)
│       └── threads/                       # Thread metadata and indexes (700)
│           ├── index.json                 # List of registered threads (600)
│           └── <safe_thread_id>.json      # Thread state metadata (SHA-256)
├── models/                                # Local model cache per provider (700)
│   └── <provider>.txt                     # Approved models list (600)
├── templates/                             # Reusable prompt templates (700)
├── history/                               # History of saved responses (700)
│   └── threads/                           # Conversational history (.ndjson) (700)
│       └── <safe_thread_id>.ndjson        # Conversation log in NDJSON (600)
├── var/                                   # Process and isolated runtime files (700)
│   └── run/                              # Process execution directory (0700)
│       └── locks/                         # Concurrency lock files (0700)
│           ├── models.lock                # Lock for model updates
│           ├── history.lock               # Lock for history management
│           └── tmp.lock                   # Lock for temporary file allocation
├── tmp/                                   # Secure and isolated temporary folder (0700)
│   └── rates/                             # Rate limiting transaction tracking (0700)
│       └── <safe_thread_id>/              # Timestamps for sliding window
├── local-extras/                          # User extensions not tracked by network manifest (700)
│   └── providers/                         # User local provider modules (domain local:<name>) (700)
└── extras/                                # Optional Vendor components and extensions (700)
    ├── manifest.sha256                    # Cryptographic integrity manifest (600)
    ├── manifest.sha256.sig                # Ed25519 cryptographic signature of manifest (600)
    ├── official-ed25519.pub               # Official public key for signature verification (600)
    ├── chat/                              # TUI REPL interface (tui-repl.sh, SPEC-TUI.md, langs/)
    ├── hooks/                             # Pre/post execution hook modules (sml-gate.sh, hook.sh)
    ├── security/                          # OpenSSL security helpers (openssl-helper.sh, output-sanitizer.sh)
    ├── test/                              # Automated test suite (run-all-tests.sh, scintilla-t3.sh, stress.sh)
    ├── docs/                              # Documentation (core-notes.sh, help.txt, manual-it.txt, bash4llm-completion.sh)
    ├── providers/                         # External Vendor providers (Gemini, Hugging Face, Mistral)
    └── session/                           # Advanced session manager (session-engine.sh)
```

---

## 4. Encrypted Credential Management (Security Vault)

If the `extras/` folder is installed and the `openssl` binary is present, API keys can be stored in encrypted form via the integrated Vault:

```sh
./bash4llm --vault
```

### Vault Features:
* **On-disk encryption**: Keys are encrypted in AES-256-CBC format with PBKDF2 derivation (100,000 iterations) and saved in `keys.dat`.
* **In-RAM session unlock**: The Vault can be unlocked for the current shell session via the sourcing command:
  ```sh
  . ./bash4llm
  ```
  The operation temporarily exports the context token `_B4L_RT_CTX` to shell memory, avoiding password requests until the session is closed.
* **Advanced Security Policies**:
  * To disable key lookup in the Vault, set `BASH4LLM_VAULT_ENABLED=0`.
  * To make the Vault **mandatory** (preventing key retrieval from unencrypted environment variables), set `export BASH4LLM_REQUIRE_VAULT=1`.

---

## 5. Troubleshooting

### Security Policy Violation (Exit Code 17 - BASH4LLM_ERR_SEC)
If the script terminates with exit code `17`, a security anomaly was detected:
* **Non-restrictive permissions**: Configuration files or folders writable by group or others (`group/world-writable`).
* **Symlink detected**: Presence of an unallowed symbolic link in a working directory.
* **Hash/Signature mismatch**: A file in the `extras/` folder has been modified relative to `manifest.sha256` or the Ed25519 signature (`manifest.sha256.sig`) is invalid.
* **Vault Policy Violation**: The variable `BASH4LLM_REQUIRE_VAULT=1` is active but the provider key is not present in the encrypted Vault.

Restoring standard POSIX permissions:
```sh
chmod 700 bash4llm.d
chmod 600 bash4llm.d/config/config
```

### Rate Limiter Block
If the number of requests exceeds the allowed threshold within a 30-second window, execution is blocked with code `17`. The limit can be modified or disabled via the variable:
```sh
export BASH4LLM_RATE_LIMIT=10  # Allows 10 requests every 30 seconds per thread
```

### Concurrency Lock Timeout (Exit Code 15 - BASH4LLM_ERR_TMP)
In the presence of concurrent executions, the maximum lock wait time can be extended via the variable:
```sh
export BASH4LLM_LOCK_TIMEOUT_HISTORY=30
```

---

## 6. Uninstallation

To completely remove runtime and data from system, delete executable and working directory:

```sh
rm -rf bash4llm.d
rm bash4llm
```

---

## 7. License

Bash4LLM⁺ is released under [**GNU GPL v3.0**](LICENSE) license.
