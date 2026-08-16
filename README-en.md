[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE) [![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?sort=semver&style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases) [![Bash](https://img.shields.io/badge/TUI-Bash4LLM-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](extras/chat/SPEC-TUI.md) [![WebApp](https://img.shields.io/badge/GUI--WebApp-Python--3.10+-007acc?style=flat-square&logo=python&logoColor=white)](extras/gui-py/README-en.md)
  

<!-- Release & General CI Badges -->
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

A Bash-native wrapper for interfacing with OpenAI-compatible LLM APIs. It includes a built-in default provider (Groq) and is extensible to additional providers via modular drivers (e.g., Gemini, Mistral, HuggingFace).  
It offers three interaction modes: direct command-line execution (**CLI**) and a fullscreen interactive terminal (**TUI REPL**) — both 100% Bash-native —, as well as a local browser-based graphical interface (**WebApp GUI**) provided as an optional extension (requires Python 3.10+).

Native compatibility: Linux, macOS, WSL and Cygwin (Windows), Termux (Android), BSD.

---

## Technical features

* **Dynamic model management**  
  Querying user endpoints (`GET /v1/models`) to update the list of supported models, without hardcoded identifiers in the main script.
* **Filesystem-level isolation**  
  Temporary files are managed within dedicated process directories (`RUN_TMPDIR`) with restrictive `0700` permissions (`umask 077`). Shared directories like `/tmp` are not used.
* **API key encryption (`--vault`)**  
  Optional OpenSSL integration for local API key encryption. Uses the AES-256-CBC algorithm with key derivation via PBKDF2 (100,000 iterations) and Master Password. Supports an offline recovery key, session context reuse (`_B4L_RT_CTX`), and the mandatory vault policy `BASH4LLM_REQUIRE_VAULT`.
* **Termux / Android support**  
  Detection of the Android Termux environment with locking mechanism adaptation: where `flock` has system limitations, concurrency management is redirected to atomic directory locks (`mkdir`).
* **State data integration (`ui_state`)**  
  Atomic writing of JSON files containing runtime operational metadata into the `ui_state` folder, for integration with external control panels or monitoring scripts.
* **Session management, history, and PII protection**  
  Management of multi-turn conversational context with history saving in NDJSON format and cryptographic anonymization of thread IDs (`anonymize_thread_id`) to prevent personal data leaks. With the optional `session-engine.sh` module, token tracking, rotation/compression of history segments, and local TTL caching are enabled.
* **Extensible modules and cryptographic signature**  
  Dynamic loading of external provider modules (`builtin`, `vendor`, `local`) into an anti-TOCTOU staging copy, with SHA-256 hash integrity verification and validation of the manifest's Ed25519 cryptographic signature (`manifest.sha256.sig`).
* **Deterministic validation**  
  Native support for response syntax validation (`--validate-sml` for SML v2.0, `--validate-regex`), zero-eval ANSI sanitization (`--sanitize`), structured JSON diagnostics (`--json-diagnostics`), function immutability guards (`readonly -f`), and local sliding-window rate limiting (30s).
* **Local WebApp GUI interface (`--gui`, `--webapp`)**:
 Responsive WebApp based on a Python/FastAPI stack and a Vanilla JS/CSS frontend (Zero CDN). Features a *Thin Adapter / Domain-Stateless* architecture with real-time token streaming via SSE, exclusive loopback binding (`127.0.0.1`), One-Time URL authentication, `HttpOnly` / `SameSite=Strict` cookies, and constant-time Anti-CSRF protection.

📘 **Architectural Documentation**: For a detailed analysis of macro-sections, isolation mechanisms and memory layout, see the **[TECHNICAL SPECIFICATION OF THE BASH4LLM⁺ SYSTEM](docs/bash4llm-arch-spec-en.md)**.

---

## System requirements

Required packages in `PATH`:

* **bash** (version 4.0 or higher)
* **coreutils** (`stat`, `chmod`, `mkdir`, `mv`, `rm`, `cp`, `mktemp`, `base64`, etc.)
* **findutils**
* **util-linux**
* **awk**
* **curl**
* **jq**

*Optional requirements for the GUI WebApp (--gui, --webapp):*  
**Python** (version 3.10 or higher)  
**Python Packages**: fastapi, uvicorn, pydantic
```sh
  pip install --user fastapi "uvicorn[standard]" pydantic
```

*(CLI and TUI mode usage remains 100% native Bash/POSIX with no Python dependencies).*

---

## Installation guide

### Quick installation ⏩
With *Installation of optional Extras:*

```sh
# 1. Clone the repository
git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  

# 2. Copy executable to working folder
mkdir -p bash4llm
cp repo-bash4llm/bin/bash4llm bash4llm/
chmod +x bash4llm/bash4llm

# 3. Initialization and model refresh
cd bash4llm 
./bash4llm --refresh-models

# 4. Optional installation of Extras (additional providers, TUI, modules)
./bash4llm --install-extras ../repo-bash4llm/extras/
```

On first launch without an environment variable set, the script will prompt for interactive input of the API key (hidden input on screen).

Detailed instructions are available in **[INSTALL](INSTALL-en.md)**.

---

## Usage examples

Command-line prompt:
```sh
./bash4llm "Fornisci una spiegazione del protocollo SSH."
```

Input from standard input (pipe):
```sh
cat codice.sh | ./bash4llm "Analizza questo script"
```

Selection of a specific model:
```sh
./bash4llm -m llama-3.3-70b-versatile "Spiega il paradosso di Fermi."
```

Test execution without network calls (Dry-Run):
```sh
./bash4llm --dry-run "Test di generazione payload"
```

Use of a secondary provider:
```sh
./bash4llm --provider gemini "Traduci il testo in inglese"
```

---

## Security and filesystem permissions 🚨

To protect the `bash4llm` script from unauthorized modifications in shared environments, appropriate read/execution permissions can be set for the operating system in use:

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

For detailed information on security policies, consult **[SECURITY](SECURITY-en.md)**.

---

## Security checks and automated tests 🛡️

The `./bash4llm` executable integrates continuous checks on code and execution environment:

1. **[Section marking check](.github/workflows/section-integrity.yml)**: Check of section anchors and delimiters structure of the main file.
2. **[Sourcing environment isolation](.github/workflows/sourcing-isolation.yml)**: Test of the `_cleanup_sourced_env` function to verify that inclusion via `source` leaves no residual functions in the calling shell.
3. **[Secret leak check in `argv`](.github/workflows/security-hardening.yml)**: Verification of the absence of API keys and Bearer tokens in the operating system process table during `curl` execution. Check of POSIX `0700` and `0600` permissions.
4. **[API resilience test](.github/workflows/api-mock-chaos.yml)**: Simulation of HTTP error responses, rate limits, and edge cases via mock server.
5. **[`extras` manifest integrity](.github/workflows/extras-integrity-manifest.yml)**: Check of SHA-256 hashes and Ed25519 cryptographic signature (`manifest.sha256.sig`) of optional modules against the `extras/manifest.sha256` file.

---

## Command and option reference

### Models and providers
| Flag | Argument | Description |
|------|-----------|-------------|
| `--refresh-models`, `--refresh-model` | No | Synchronizes the model list of the active provider. |
| `--list-models` | No | Lists available models for the active provider. |
| `--list-models-raw` | No | Prints the model list in raw text format. |
| `--list-providers` | No | Lists installed providers. |
| `--list-providers-raw` | No | Prints the provider list in raw text format. |
| `--set-default <model>` | Yes | Sets default model for active provider. |
| `-m <model>`, `--model <model>` | Yes | Specifies model for current execution. |
| `--provider <name>` | Yes | Selects active provider for current execution. |
| `--provider` | No | Opens interactive provider selection menu. |

### Input
| Flag | Argument | Description |
|------|-----------|-------------|
| `-f <file>` | Yes | Adds file content to input prompt. |
| `--json-input <json>` | Yes | Sends direct JSON structure with message array. |
| `--template <name>` | Yes | Applies a template file from templates folder. |
| `--batch <file>` | Yes | Executes a series of prompts from file (one prompt per line). |

### Thread and context management
| Flag | Argument | Description |
|------|-----------|-------------|
| `--thread <id>` | Yes | Activates conversational context for specified ID. |
| `--thread-window [n]` | Optional | Sets maximum number of historical messages to include (default: 10). |
| `--init-thread` | No | Initializes context files for a new thread and exits. |
| `--delete-thread <id>` | Yes | Atomically deletes thread history and metadata. |
| `--rename-thread <id>` | Yes | Renames metadata title for specified thread. |
| `--title <title>` | Yes | Specifies new title in combination with `--rename-thread`. |

### Generation parameters
| Flag | Argument | Description |
|------|-----------|-------------|
| `--system <text>` | Yes | Sets system prompt for execution. |
| `--ture <n>`, `--temperature <n>` | Yes | Sets temperature value (from 0.0 to 2.0). |
| `--max <n>` | Yes | Sets maximum response token limit (default: 4096). |

### Output and saving
| Flag | Argument | Description |
|------|-----------|-------------|
| `--save` | No | Forces saving response in history. |
| `--nosave` | No | Disables saving response in history. |
| `--out <path>` | Yes | Saves output in specified file or directory. |
| `--threshold <n>` | Yes | Minimum byte threshold for automatic saving (default: 1000). |
| `--json` | No | Returns complete API JSON payload. |
| `--pretty` | No | Returns formatted JSON payload. |
| `--text` | No | Returns text-only response (default). |
| `--raw` | No | Returns raw text without trailing newline. |
| `--sanitize` | No | Filters and elides ANSI escape sequences and non-printable characters from output. |

### Operating modes
| Flag | Argument | Description |
|------|-----------|-------------|
| `--dry-run` | No | Simulates execution without making network calls. |
| `--quiet` | No | Omits non-essential informational messages on stderr. |
| `--stream` | No | Enables streaming reception (Server-Sent Events). |
| `--no-stream` | No | Disables streaming for current request. |
| `--chat`, `--tui` | No | Launches interactive TUI/REPL interface. |
| `--gui`, `--webapp` | No | Launch the local WebApp GUI in a browser. |
| `--bootstrap-only` | No | Executes startup phase and checks filesystem, then exits. |
| `--test`, `--run-all-tests` | No | Invokes the automated test suite orchestrator. |

### Configuration and diagnostics
| Flag | Argument | Description |
|------|-----------|-------------|
| `--check-config` | No | Performs permission checks and configuration linter. |
| `--explain-error <code>` | Yes | Shows definition and mitigations for entered error code. |
| `--show-config` | No | Prints active configuration variables. |
| `--diagnostics` | No | Executes system diagnostic tests and TLS check. |
| `--vault` | No | Launches encrypted Key Vault management console. |
| `--validate-sml` | No | Validates LLM response against SML v2.0 syntax standard. |
| `--validate-regex <regex>` | Yes | Validates response against provided POSIX ERE regular expression. |
| `--json-diagnostics` | No | Emits system and network errors in structured JSON format. |
| `--print-config-dir` | No | Prints canonical path of configuration directory on screen. |
| `--print-provider-file` | No | Prints path of active provider persistence file on screen. |
| `--print-model-file [provider]` | Optional | Prints path of model file for provider on screen. |
| `--version` | No | Shows script version. |
| `--install-extras` | Optional | Installs the entire extras package into bash4llm.d/extras/ with integrity verification. Accepts the source directory path as an optional argument. |
| `-h`, `--help` | No | Shows inline help. |

---

## UI state structure (`ui_state`)

The runtime atomically updates state metadata in the directory:

`bash4llm.d/config/ui_state/`

Generated files:
* `threads/<thread_id>.json`: Active thread state and metadata.
* `threads/index.json`: Index of saved threads.
* `last_api.json`: Metadata of last API call (HTTP status, request ID, time).
* `last_history.json`: Information on last file written in history.
* `provider_capabilities.json`: Features supported by active provider.

---

## Exit codes

| Code | Constant | Description |
|:---:|:---|:---|
| **0** | - | Execution completed successfully. |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | API key not found for active provider. |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Invalid model or unsupported format. |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Error executing HTTP request (`curl`). |
| **13** | `BASH4LLM_ERR_PARSE` | JSON parsing error, or response syntax/SML/REGEX validation failure. |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | Empty prompt or input payload. |
| **15** | `BASH4LLM_ERR_TMP` | Filesystem, temporary allocation, or lock error. |
| **16** | `BASH4LLM_ERR_API` | Error returned by API or empty completion. |
| **17** | `BASH4LLM_ERR_SEC` | Security policy violation or module hash/signature mismatch. |

---

## License and Contacts

* **License:** GNU General Public License v3.0 ([LICENSE](LICENSE))
* **Author:** Cristian Evangelisti  
* **Email:** `opensource@cevangel.anonaddy.me`  
* **Repository:** [GitHub kamaludu/bash4llm](https://github.com/kamaludu/bash4llm)

### Use of Artificial Intelligence tools in development

Bash4LLM is a work developed by the author with **extensive use of generative Artificial Intelligence (LLM)** tools for design, implementation, analysis, debugging, review, and documentation.

LLMs were used as **development tools**, not as autonomous generators of the project. The author defined the architecture, requirements, and design choices, orchestrating the work across different models and sessions and using the LLMs themselves to examine, question, and critique work produced by other models.

The code and documentation are therefore the result of an **iterative and supervised process**, in which proposals generated by LLMs were evaluated, compared, modified, or discarded by the author. The final decisions and overall project result belong to the author.

The use of LLMs offers significant advantages in terms of productivity, analysis, and review, but also introduces risks: **no verification process can guarantee that every error or omission is identified**. This notice is intended to make transparent both the extent of LLM usage and their actual role in the development process.
