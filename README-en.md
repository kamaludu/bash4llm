[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
<!-- Release & General CI Badges -->
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)   
[![ShellCheck](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml)
[![Cross-Platform Tests](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml)
[![Bash Compatibility](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml)  

<!-- Core Hardening & Security Audits (Strictly targeting bash4llm executable) -->
[![API Chaos & Resilience Mock Suite](https://github.com/kamaludu/bash4llm/actions/workflows/api-mock-chaos.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/api-mock-chaos.yml)
[![Extras SHA-256 Manifest Integrity](https://github.com/kamaludu/bash4llm/actions/workflows/extras-integrity-manifest.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/extras-integrity-manifest.yml)
[![Security & Process List Leak Audit](https://github.com/kamaludu/bash4llm/actions/workflows/security-hardening.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/security-hardening.yml)
[![Sourcing Isolation & Namespace Audit](https://github.com/kamaludu/bash4llm/actions/workflows/sourcing-isolation.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/sourcing-isolation.yml)
[![Section Marker Integrity Audit](https://github.com/kamaludu/bash4llm/actions/workflows/section-integrity.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/section-integrity.yml)  
> 🛡️ **Core Verification Note:** The bottom row of security, sourcing isolation, section integrity, and API chaos badges executes **strictly and exclusively** on the `./bash4llm` executable core file to guarantee Zero-Leakage, Flat Architecture compliance, and Superior Resilience.

# Bash4LLM⁺ [🇮🇹](README.md) 🇬🇧

**Bash4LLM⁺** — A secure, Bash-first, modular, and fully auditable CLI wrapper for interfacing with OpenAI-compliant LLM APIs (featuring a built-in Groq provider out of the box, extendable to others via external modules).

Bash4LLM⁺ is a single, self-contained, readable script designed to have zero external dependencies beyond standard POSIX commands and core shell utilities.

It runs natively on: Linux, macOS, WSL, Cygwin, Termux (Android), and BSD.

---

## Key Features

*   **Dynamic and Obsolescence-Free Model List**  
    Obtained by querying live endpoints (`GET /v1/models`). No model names are hardcoded in the core script.
*   **Filesystem-level Security and Sandboxing**  
    No global shared folders like `/tmp` are used. Temporary files are isolated using process-exclusive directories (`RUN_TMPDIR`) with restrictive `700` permissions (`umask 077`). Absolute ban on `eval`.
*   **Built-in Cryptographic Vault (`--vault`)**  
    Optional OpenSSL-based integration to securely store and manage API keys on the filesystem. Keys are encrypted using the AES-256-CBC algorithm with a Master Password and PBKDF2 key derivation (100,000 iterations). Supports an offline emergency Recovery Key and shell session unlock (`_B4L_RT_CTX`) to avoid repeated password prompts.
*   **Portability on Termux / Android**  
    Automatic detection of the Android Termux environment to bypass kernel or SELinux restrictions on `flock`. File concurrency management is transparently redirected to an atomic directory lock (`mkdir`) mechanism.
*   **UI State System (`ui_state`)**  
    The CORE script exposes real-time operational metadata in atomic JSON format (write-protected via locks) to facilitate structured integration with external dashboards, GUIs, or third-party automations (e.g., Home Assistant).
*   **Conversational Caching and Advanced Session Engine**  
    Supports multi-turn sessions and thread history management in NDJSON format. The integration of the optional `session-engine.sh` module enables automatic segmentation of historical files (automatic rotation and compression of segments exceeding 1MB) and in-memory caching with TTL to maximize responsiveness.
*   **Modular Extensibility**  
    On-demand loading of external providers (Gemini, Hugging Face, Mistral) placed in the extras folder, with dynamic isolation of authorized function definitions and integrity checks.

---

## Requirements

Bash4LLM⁺ requires the following packages to be available in your `PATH`:

- ***bash*** (version 4.0 or superior)
- coreutils (stat, chmod, mkdir, etc.)
- findutils
- util-linux
- gawk
- curl
- jq

---

## Quick Installation

> [!TIP]
> **⏩ FAST FORWARD (Quick Installation)**
> 
> Run these commands in your terminal to quickly download and configure **Bash4LLM⁺**:
> 
> ```sh
> # 1. Clone the repository (shallow clone for maximum speed)
> git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  
> 
> # 2. Create a workspace directory and extract the executable
> mkdir -p bash4llm
> cp repo-bash4llm/bin/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
> 
> # 3. Enter the folder and refresh the models 
> cd bash4llm 
> ./bash4llm --refresh-models
> ```
> 
> The script will detect the missing key and prompt you for a masked interactive input:
> `Enter API key for provider groq (env GROQ_API_KEY) [input is hidden]:`
> 
> Type or paste your Groq API key (characters will remain invisible on your screen). Immediately after, the script will securely offer to export it for your current terminal session via the interactive prompt (Session Sandboxing):
> 
> `Export this API key to your current terminal session? [y/N]: y`
> 
> Answer **`y` (Yes)** to load the key into active RAM and start using the script right away without entering your key again in this session.
> 
> Recommended: ***install optional Extras*** (additional providers, chat REPL, templates):
> ```sh
> # 4. Install the Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> ```
> 
> Use Bash4llm ⚡
>

Detailed installation instructions are available in **[INSTALL](INSTALL-en.md)**.

---

## Quick Usage and Examples

Direct prompt:
```sh
./bash4llm "Provide a concise explanation of the SSH protocol."
```

Standard input pipe:
```sh
cat code.sh | ./bash4llm "Optimize this Bash script"
```

Using a specific model:
```sh
./bash4llm -m llama-3.3-70b-versatile "Explain the Fermi paradox."
```

Simulated execution (Dry-Run):
```sh
./bash4llm --dry-run "Generate a dummy response"
```

Using an external provider (if installed and configured):
```sh
./bash4llm --provider gemini "Translate the following text into English"
```

---

## 🚨 Security & File System Hardening

The core executable `bash4llm` serves as the system's **Root of Trust**. To prevent unauthorized tampering by local processes, apply the quick hardening commands for your platform:

* **Linux (GNU/Linux):**
  ```bash
  sudo chown root:root /path/to/bash4llm && sudo chmod 755 /path/to/bash4llm
  sudo chattr +i /path/to/bash4llm  # Kernel Immutability Attribute
  ```
* **macOS / BSD:**
  ```bash
  sudo chown root:wheel /path/to/bash4llm && sudo chmod 755 /path/to/bash4llm
  sudo chflags schg /path/to/bash4llm  # System Immutable Flag
  ```
* **Termux (Android):**
  ```bash
  chmod 500 ~/bash4llm  # Read/execute exclusively for sandbox owner
  ```
* **WSL / Cygwin (Windows):**
  ```bash
  setfacl -b /path/to/bash4llm 2>/dev/null  # Strip Windows ACL overrides
  chmod 755 /path/to/bash4llm
  ```

 📖 For detailed instructions refer to: **[SECURITY-en.md](SECURITY-en.md)**.

---

---

## 🛡️ Core Hardening & Automated Security Audits

Beyond standard cross-platform CI/CD, the `./bash4llm` executable undergoes **5 continuous automated security and architecture audits** targeted strictly at the core source file:

1. **[Section Marker Integrity Audit](.github/workflows/section-integrity.yml)**: Validates the 23-Section Flat Architecture, verifying 100% tag symmetry, trailing anchors, and preventing subsection leaks ($N.X$).
2. **[Sourcing Isolation & Namespace Audit](.github/workflows/sourcing-isolation.yml)**: Tests `_cleanup_sourced_env` to guarantee that importing `bash4llm` into an interactive shell leaves **Zero Function Leaks** in parent memory.
3. **[Security & Process List Leak Audit](.github/workflows/security-hardening.yml)**: Runs real `curl` transactions against local mock endpoints while sampling `ps aux` at 5ms intervals to prove Bearer API Keys **never leak into the system process table**. Enforces strict `0700` and `0600` POSIX file-system permissions.
4. **[API Chaos & Resilience Mock Suite](.github/workflows/api-mock-chaos.yml)**: Simulates fault-injection (HTTP 500 errors, rate limits, empty completion edge-cases) using a local Python HTTP Mock Server.
5. **[Extras SHA-256 Manifest Integrity](.github/workflows/extras-integrity-manifest.yml)**: Verifies cryptographic hashes of all extensions against `extras/manifest.sha256` to prevent tampering or broken modules.

---

## Available Commands, Flags, and Options

### Models and Providers
| Flag | Argument | Effect |
|------|-----------|---------|
| `--refresh-models`, `--refresh-model` | no | Syncs the active provider's model list (requires API key). |
| `--list-models` | no | Shows models of the active provider (interactive format). |
| `--list-models-raw` | no | Prints the active model list in raw format (one model per line). |
| `--list-providers` | no | Prints the list of available providers. |
| `--list-providers-raw` | no | Prints the list of available providers in raw format. |
| `--set-default <model>` | yes | Saves and sets the default model persistently for the active provider. |
| `-m <model>`, `--model <model>` | yes | Specifies the model to use for the current execution. |
| `--provider <name>` | yes | Selects the active provider for this execution. |
| `--provider` | no | Shows the interactive default provider selection menu. |

### Input (files, JSON, templates, batch)
| Flag | Argument | Effect |
|------|-----------|---------|
| `-f <file>` | yes | Loads the specified file, appending it to the text input queue. |
| `--json-input <json>` | yes | Passes a direct OpenAI-like JSON structure (array of messages). |
| `--template <name>` | yes | Loads and processes the prompt, placing it inside the chosen template. |
| `--batch <file>` | yes | Runs a series of prompts stored in the file (one per line). |

### Conversational Thread Management (Memory)
| Flag | Argument | Effect |
|------|-----------|---------|
| `--thread <id>` | yes | Activates the conversational session for the specified thread. |
| `--thread-window [n]` | optional | Defines the maximum number of history messages to include (default: 10). |
| `--init-thread` | no | Securely initializes NDJSON files and local metadata for a new thread. Requires `--thread <id>`. |

### Generation Parameters
| Flag | Argument | Effect |
|------|-----------|---------|
| `--system <text>` | yes | Sets the system prompt (*System Prompt*) for the current execution. |
| `--ture <n>`, `--temperature <n>` | yes | Adjusts the generation temperature (validated numerical value from 0.0 to 2.0). |
| `--max <n>` | yes | Sets the maximum limit of response tokens (default: 4096). |

### Output and Autosave
| Flag | Argument | Effect |
|------|-----------|---------|
| `--save` | no | Forces the output to be written and archived in the history folder. |
| `--nosave` | no | Completely disables the automatic saving of the response. |
| `--out <path>` | yes | Redirects and saves the response to the specified file or directory. |
| `--threshold <n>` | yes | Sets the minimum byte threshold for automatic saving (default: 1000). |
| `--json` | no | Returns the original and complete JSON response returned by the API. |
| `--pretty` | no | Returns the original JSON response formatted in a readable layout. |
| `--text` | no | Extracts and returns only the text response (default behavior). |
| `--raw` | no | Returns the raw text response, excluding trailing newlines. |

### Operating Modes
| Flag | Argument | Effect |
|------|-----------|---------|
| `--dry-run` | no | Simulates the entire execution without contacting any API servers. |
| `--quiet` | no | Minimizes diagnostic header messages on stderr. |
| `--stream` | no | Enables real-time streaming of tokens on stdout (Server-Sent Events). |
| `--no-stream` | no | Disables streaming mode for the current request. |
| `--chat` | no | Starts the TUI-based interactive REPL chat (requires extras installation). |
| `--bootstrap-only` | no | Only performs filesystem bootstrap checks and stops. |

### Configuration and Diagnostics
| Flag | Argument | Effect |
|------|-----------|---------|
| `--check-config` | no | Verifies configuration file permission security and detects linter errors. |
| `--explain-error <code>` | yes | Returns the detailed definition and mitigations for the entered error code or alias. |
| `--show-config` | no | Prints the list of active runtime variables and parameters. |
| `--diagnostics` | no | Runs integrated diagnostics, including a TLS handshake to the active endpoint. |
| `--vault` | no | Launches the interactive console for the encrypted OpenSSL Key Vault. |
| `--version` | no | Shows the current version of the script and exits. |
| `-h`, `--help` | no | Renders formatted online help from a local file. |

---

## UI State Structure (`ui_state`)

To facilitate monitoring or automation integration (such as Home Assistant or local graphical dashboards), Bash4LLM⁺ atomically writes updated state metadata inside the directory:

`bash4llm.d/config/ui_state/`

The available files are:
*   `threads/<thread_id>.json` → Specific thread state (active, msg_count, last_ts, title).
*   `threads/index.json` → Structured index containing the list of active threads.
*   `last_api.json` → Metadata of the last call made (http_status, finish_reason, req_id, edgecase_detected).
*   `last_history.json` → Details of the last file physically saved in the history folder.
*   `provider_capabilities.json` → Information on the provider in use (whether it supports streaming, models, or refresh).

---

## Exit Codes

| Code | Canonical Variable | Meaning |
|:---:|:---|:---|
| **0** | - | Operational success. |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | Authentication failed or API Key missing for the active provider. |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Invalid, unsupported (non-textual), or missing model in whitelist. |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Network connection error or failure of the `curl` command execution. |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | Empty input or unspecified request prompt. |
| **15** | `BASH4LLM_ERR_TMP` | Filesystem error (directory not creatable, lock collision, or symlink detected). |
| **16** | `BASH4LLM_ERR_API` | HTTP error returned by the API or uninterpretable JSON response. |
| **17** | `BASH4LLM_ERR_SEC` | Security policy violation (configuration file write-accessible by others). |

---

## License
Bash4LLM⁺ is released under the **GNU GPL v3** license.
See the  **[LICENSE](LICENSE)** file for more details.

## Contacts
*   **Author:** Cristian Evangelisti  
*   **Email:** `opensource@cevangel.anonaddy.me`  
*   **Repository:** [GitHub kamaludu/bash4llm](https://github.com/kamaludu/bash4llm)
