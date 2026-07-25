[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
<!-- Release & General CI Badges -->
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?sort=semver&style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)
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

# Bash4LLM⁺   [🇮🇹](README.md) 🇬🇧

A Bash CLI wrapper for interfacing with OpenAI-compliant LLM APIs. Includes an embedded default provider (Groq) and supports additional providers through extension modules.

Designed as a self-contained Bash script with zero external dependencies beyond standard POSIX system utilities and shell builtins.

Supported platforms: Linux, macOS, WSL, Cygwin, Termux (Android), and BSD.

---

## Key Features

* **Dynamic Model Management**  
  Queries live endpoints (`GET /v1/models`) to update available model lists without hardcoding model names in the core script.
* **Filesystem Isolation**  
  Temporary files are maintained in process-isolated runtime directories (`RUN_TMPDIR`) with restrictive `0700` permissions (`umask 077`). Shared system paths such as `/tmp` are strictly avoided.
* **Encrypted Key Vault (`--vault`)**  
  Optional OpenSSL-based key storage. API keys are encrypted using AES-256-CBC with PBKDF2 key derivation (100,000 iterations) and a Master Password. Supports an offline recovery key and RAM session context unlocking (`_B4L_RT_CTX`).
* **Termux / Android Compatibility**  
  Detects Android Termux environments to handle platform lock limitations: if `flock` is restricted by kernel policy, concurrency control switches transparently to atomic directory locking (`mkdir`).
* **UI State Metadata (`ui_state`)**  
  Exposes operational state metadata as atomic JSON files within `ui_state` to support integration with external dashboards, GUIs, or local automation tools.
* **Session Management & History**  
  Supports multi-turn context retention with NDJSON history files. With the optional `session-engine.sh` module, automatic log rotation, segment compression, and in-memory TTL caching are enabled.
* **Modular Provider Architecture**  
  Dynamically loads external provider modules (Gemini, Hugging Face, Mistral) located in the extras directory, validating module file ownership, permissions, and SHA-256 hashes against a cryptographic manifest.

---

## System Requirements

The following command-line utilities must be available in `PATH`:

* **bash** (version 4.0 or higher)
* **coreutils** (`stat`, `chmod`, `mkdir`, `mv`, `rm`, etc.)
* **findutils**
* **util-linux**
* **awk**
* **curl**
* **jq**

---

## Installation

### Quick Start ⏩

```sh
# 1. Clone the repository
git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  

# 2. Extract executable to working directory
mkdir -p bash4llm
cp repo-bash4llm/bin/bash4llm bash4llm/
chmod +x bash4llm/bash4llm

# 3. Initialize and fetch model list
cd bash4llm 
./bash4llm --refresh-models
```

If no API key environment variable is set on first run, the script prompts for masked key entry.

```sh
# 4. Optional: Install Extras
./bash4llm --install-extras ../repo-bash4llm/extras/
```

For comprehensive installation details, refer to **[INSTALL-en.md](INSTALL-en.md)**.

---

## Usage Examples

Command-line prompt:
```sh
./bash4llm "Provide a concise summary of the SSH protocol."
```

Standard input pipe:
```sh
cat code.sh | ./bash4llm "Review this script"
```

Specify model:
```sh
./bash4llm -m llama-3.3-70b-versatile "Explain the Fermi paradox."
```

Dry-run simulation:
```sh
./bash4llm --dry-run "Test prompt"
```

Secondary provider:
```sh
./bash4llm --provider gemini "Translate text to French"
```

---

## Security & Permissions 🚨

To protect the executable from unauthorized modification in multi-user environments, set proper file ownership and permissions for your platform:

* **Linux (GNU/Linux):**
  ```bash
  sudo chown root:root /path/to/bash4llm && sudo chmod 755 /path/to/bash4llm
  sudo chattr +i /path/to/bash4llm
  ```
* **macOS / BSD:**
  ```bash
  sudo chown root:wheel /path/to/bash4llm && sudo chmod 755 /path/to/bash4llm
  sudo chflags schg /path/to/bash4llm
  ```
* **Termux (Android):**
  ```bash
  chmod 500 ~/bash4llm
  ```
* **WSL / Cygwin:**
  ```bash
  setfacl -b /path/to/bash4llm 2>/dev/null
  chmod 755 /path/to/bash4llm
  ```

For security policies and architecture details, consult **[SECURITY-en.md](SECURITY-en.md)**.

---

## Automated Security Audits 🛡️

The `./bash4llm` core script is continuously validated using automated test workflows:

1. **[Section Marker Integrity Audit](.github/workflows/section-integrity.yml)**: Verifies section tags and structural anchors in the source file.
2. **[Sourcing Isolation Audit](.github/workflows/sourcing-isolation.yml)**: Tests `_cleanup_sourced_env` to confirm sourcing `bash4llm` leaves no residual functions in parent shell memory.
3. **[Process Argument Exposure Audit](.github/workflows/security-hardening.yml)**: Monitors process arguments (`argv` / `ps aux`) during `curl` transactions to verify Bearer tokens and API keys are redacted. Validates POSIX `0700` and `0600` permissions.
4. **[API Fault Resilience Suite](.github/workflows/api-mock-chaos.yml)**: Simulates HTTP errors, rate limits, and empty completion edge cases via a mock server.
5. **[Module Integrity Manifest](.github/workflows/extras-integrity-manifest.yml)**: Validates extension file hashes against `extras/manifest.sha256`.

---

## Command Reference

### Models and Providers
| Flag | Argument | Description |
|------|-----------|-------------|
| `--refresh-models`, `--refresh-model` | No | Fetches updated model list from active provider. |
| `--list-models` | No | Lists local models for the active provider. |
| `--list-models-raw` | No | Outputs model list in unformatted raw text. |
| `--list-providers` | No | Lists installed provider modules. |
| `--list-providers-raw` | No | Outputs installed providers in unformatted raw text. |
| `--set-default <model>` | Yes | Saves default model for the active provider. |
| `-m <model>`, `--model <model>` | Yes | Overrides model for active execution. |
| `--provider <name>` | Yes | Sets active provider for current execution. |
| `--provider` | No | Launches interactive provider selection menu. |

### Input
| Flag | Argument | Description |
|------|-----------|-------------|
| `-f <file>` | Yes | Appends file content to prompt input queue. |
| `--json-input <json>` | Yes | Passes raw JSON message array payload directly. |
| `--template <name>` | Yes | Applies template file from templates directory. |
| `--batch <file>` | Yes | Processes file containing line-separated prompts. |

### Thread Management
| Flag | Argument | Description |
|------|-----------|-------------|
| `--thread <id>` | Yes | Enables multi-turn context history for specified thread ID. |
| `--thread-window [n]` | Optional | Sets maximum historical messages in context window (default: 10). |
| `--init-thread` | No | Initializes thread context files and exits. |

### Generation Parameters
| Flag | Argument | Description |
|------|-----------|-------------|
| `--system <text>` | Yes | Defines system prompt context. |
| `--ture <n>`, `--temperature <n>` | Yes | Sets sampling temperature (0.0 to 2.0). |
| `--max <n>` | Yes | Sets maximum completion tokens (default: 4096). |

### Output and Storage
| Flag | Argument | Description |
|------|-----------|-------------|
| `--save` | No | Forces response output saving to history. |
| `--nosave` | No | Disables response saving to history. |
| `--out <path>` | Yes | Writes response output to designated file or folder. |
| `--threshold <n>` | Yes | Minimum output byte size for auto-saving (default: 1000). |
| `--json` | No | Outputs raw API JSON response. |
| `--pretty` | No | Outputs formatted JSON response. |
| `--text` | No | Outputs response message text (default). |
| `--raw` | No | Outputs raw response text without trailing newline. |

### Operating Modes
| Flag | Argument | Description |
|------|-----------|-------------|
| `--dry-run` | No | Prepares request payload without making network calls. |
| `--quiet` | No | Suppresses non-error stderr logging. |
| `--stream` | No | Enables real-time SSE token streaming. |
| `--no-stream` | No | Disables streaming mode. |
| `--chat` | No | Starts interactive TUI/REPL session. |
| `--bootstrap-only` | No | Performs initialization checks and exits. |

### Configuration and Inspection
| Flag | Argument | Description |
|------|-----------|-------------|
| `--check-config` | No | Runs configuration security audit and key linter. |
| `--explain-error <code>` | Yes | Explains specified exit code or error alias. |
| `--show-config` | No | Prints active configuration variables. |
| `--diagnostics` | No | Runs system diagnostics and TLS handshake checks. |
| `--vault` | No | Opens interactive key vault manager. |
| `--version` | No | Prints script version information. |
| `-h`, `--help` | No | Displays help text. |

---

## UI State Directory (`ui_state`)

Operational metadata is written atomically to JSON files under:

`bash4llm.d/config/ui_state/`

Generated files:
* `threads/<thread_id>.json`: Active thread state and message count.
* `threads/index.json`: Registered thread list index.
* `last_api.json`: Status, request ID, and metadata of last API call.
* `last_history.json`: File path and metadata of last saved history entry.
* `provider_capabilities.json`: Active provider feature flags.

---

## Exit Codes

| Exit Code | Constant Variable | Meaning |
|:---:|:---|:---|
| **0** | - | Execution completed successfully. |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | API key missing for active provider. |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Specified model is invalid or non-textual. |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Network transport error during `curl` execution. |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | Prompt or input payload missing or empty. |
| **15** | `BASH4LLM_ERR_TMP` | Filesystem, temporary allocation, or lock error. |
| **16** | `BASH4LLM_ERR_API` | API error HTTP status code or unparseable response. |
| **17** | `BASH4LLM_ERR_SEC` | Security violation or module integrity digest mismatch. |

---

## License & Contact

* **License:** GNU General Public License v3.0 ([LICENSE](LICENSE))
* **Author:** Cristian Evangelisti  
* **Email:** `opensource@cevangel.anonaddy.me`  
* **Repository:** [GitHub kamaludu/bash4llm](https://github.com/kamaludu/bash4llm)
