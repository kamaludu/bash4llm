[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI][![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)  
[![ShellCheck](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml)
[![Cross-Platform Tests](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/cross-platform.yml)
[![Bash Compatibility](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/bash-compatibility.yml)

# Bash4LLM⁺ [🇮🇹](README.md) 🇬🇧

**Bash4LLM⁺** — a secure, Bash‑first, fully auditable CLI wrapper for Groq’s OpenAI‑compatible Chat Completions API (and extendable to other providers).

Bash4LLM⁺ is a single, self‑contained Bash script that is readable and verifiable. Download it, make it executable, export your API key, and start using it.

Compatible with Unix‑like environments: Linux, macOS, WSL, Cygwin, Termux (Android), BSD.

---

## Key features

- **Dynamic model list**  
  via `GET https://api.groq.com/openai/v1/models` → no hardcoded models.

- **Security by design**  
  → no use of `/tmp`, no `eval`, restrictive permissions, advanced provider validation.

- **Modular sectioned structure**  
  → PRECORE_BOOT, PRECORE_RUN, PROVIDER, CORE_SETUP, CORE_PROVIDER.

- **UI State System (ui_state)**  
  → the CORE continuously exposes atomic JSON metadata for integration with GUIs or external tools (e.g., Home Assistant).

- **Streaming and non‑streaming**  
  → real‑time output or full response at the end.

- **Automatic saving**  
  → for outputs longer than a configurable threshold.

- **Advanced model management**  
  → refresh, list, persistent default, dynamic whitelist, auto‑selection.

- **Optional extras**  
  → additional providers (Gemini, Hugging Face, Mistral), templates, documentation, security tools.

- **Termux / Android ready**  
  → automatically detects Termux and bypasses `flock` (often unstable or limited at kernel/SELinux level on Android) and transparently falls back to a robust directory‑lock mechanism (`mkdir` atomic).

---

## Threat model (short)

Bash4LLM⁺ is designed for single‑user environments (PC/laptop, personal servers).

- Providers are code executed in your shell: they must reside in secure directories you own.  
- Variables such as `BASH4LLM_EXTRAS_DIR` and `BASH4LLM_TMPDIR` are considered trusted configuration.  
- The script never executes model output.  
- TOCTOU risks and JSON/SSE parsing limits are mitigated and documented.

Full details in **[SECURITY](SECURITY-en.md)**.

---

## Requirements
Bash4LLM⁺ requires the following packages to be available in your PATH:
 * ***bash*** (version 4.0 or higher)
 * coreutils (stat, chmod, mkdir, etc.)
 * findutils
 * util-linux
 * gawk
 * curl
 * jq
## Quick Installation
> [!TIP]
> **⏩ FAST FORWARD (Quick Installation)**
> Run these commands in your terminal to quickly download and configure **Bash4LLM⁺**:
> ```sh
> # 1. Clone the repository (shallow clone for maximum speed)
> git clone --depth 1 --branch main https://github.com/kamaludu/bash4llm.git repo-bash4llm  
> 
> # 2. Create a working directory and extract the executable
> mkdir -p bash4llm
> cp repo-bash4llm/bin/bash4llm bash4llm/
> chmod +x bash4llm/bash4llm
> 
> # 3. Enter the directory and refresh the models 
> cd bash4llm 
> ./bash4llm --refresh-models
> 
> ```
> The script will detect the missing key and prompt you for interactive input:
> Enter API key for provider groq (env GROQ_API_KEY):
> Enter your Groq API key. To avoid re-entering it in subsequent executions within the current terminal session, export it:
> export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
> Recommended: ***install the optional Extras*** (additional providers, REPL chat, templates):
> ```sh
> # 4. Install Extras
> ./bash4llm --install-extras ../repo-bash4llm/extras/
> 
> ```
> Use Bash4llm ⚡
> 
Detailed installation instructions are available in **INSTALLATION**.
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
## Available Commands, Flags, and Options
### Models and Providers

| Flag | Argument | Effect |
| :--- | :--- | :--- |
| --refresh-models, --refresh-model | no | Synchronizes the active model list of the provider (requires API key). |
| --list-models | no | Shows the active provider's models (interactive format). |
| --list-models-raw | no | Prints the list of active models in raw format (one model per line). |
| --list-providers | no | Prints the list of available providers. |
| --list-providers-raw | no | Prints the list of providers in raw format. |
| --set-default <model> | yes | Saves and persistently sets the default model for the active provider. |
| -m <model>, --model <model> | yes | Specifies the model to use for the current execution. |
| --provider <name> | yes | Selects the active provider for this execution. |
| --provider | no | Shows the interactive menu to select the default provider. | <br> ### Input (files, JSON, templates, batch)
| Flag | Argument | Effect |
| :--- | :--- | :--- |
| -f <file> | yes | Loads the specified file, appending it to the text input queue. |
| --json-input <json> | yes | Passes a direct OpenAI-like JSON structure (array of messages). |
| --template <name> | yes | Loads and processes the prompt by inserting it into the chosen template. |
| --batch <file> | yes | Executes a series of prompts stored in the file (one per line). | <br> ### Conversational Thread Management (Memory)
| Flag | Argument | Effect |
| :--- | :--- | :--- |
| --thread <id> | yes | Activates the conversational session for the specified thread. |
| --thread-window [n] | optional | Defines the maximum number of history messages to include (default: 10). |
| --init-thread | no | Safely initializes the NDJSON files and local metadata for a new thread. Requires using --thread <id>. | <br> ### Generation Parameters
| Flag | Argument | Effect |
| :--- | :--- | :--- |
| --system <text> | yes | Sets the system prompt for the current execution. |
| --ture <n>, --temperature <n> | yes | Adjusts the generation temperature (validated numerical value from 0.0 to 2.0). |
| --max <n> | yes | Sets the maximum limit for response tokens (default: 4096). | <br> ### Output and Autosaving
| Flag | Argument | Effect |
| :--- | :--- | :--- |
| --save | no | Forces writing and archiving the response in the history folder. |
| --nosave | no | Completely disables autosaving of the response. |
| --out <path> | yes | Redirects and saves the response to the specified file or directory. |
| --threshold <n> | yes | Sets the minimum threshold in bytes for autosaving (default: 1000). |
| --json | no | Returns the original and complete JSON response returned by the API. |
| --pretty | no | Returns the original JSON response formatted in a readable way. |
| --text | no | Extracts and returns only the text response (default behavior). |
| --raw | no | Returns the raw text response, excluding trailing newlines. | <br> ### Operating Modes
| Flag | Argument | Effect |
| :--- | :--- | :--- |
| --dry-run | no | Simulates the entire execution in dry run without contacting the API servers. |
| --quiet | no | Minimizes diagnostic header messages on stderr. |
| --stream | no | Enables real-time streaming of tokens to stdout (Server-Sent Events). |
| --no-stream | no | Disables streaming mode for the current request. |
| --chat | no | Launches the interactive TUI-based REPL chat (requires extras installation). |
| --bootstrap-only | no | Performs only filesystem bootstrap checks and then stops. | <br> ### Configuration and Diagnostics
| Flag | Argument | Effect |
| :--- | :--- | :--- |
| --check-config | no | Verifies the safety of configuration file permissions and detects linter errors. |
| --explain-error <code > | yes | Returns the detailed definition and mitigations for the entered error code or alias. |
| --show-config | no | Prints the list of active variables and parameters at runtime. |
| --diagnostics | no | Runs an integrated diagnostic, including a TLS handshake to the active endpoint. |
| --vault | no | Launches the interactive console for managing the encrypted OpenSSL Key Vault. |
| --version | no | Shows the current script version and terminates. |
| -h, --help | no | Renders the inline help on the screen, formatted from a local file. | <br> ## UI State Structure (ui_state) <br> To facilitate monitoring or automation integration (such as Home Assistant or local graphical dashboards), Bash4LLM⁺ atomically writes updated state metadata within the folder: <br> bash4llm.d/config/ui_state/ <br> The available files are: <br> * threads/<thread_id>.json → Thread-specific state (active, msg_count, last_ts, title). <br> * threads/index.json → Structured index containing the list of active threads. <br> * last_api.json → Metadata of the last call made (http_status, finish_reason, req_id, edgecase_detected). <br> * last_history.json → Details about the last file physically saved in the history folder. <br> * provider_capabilities.json → Information about the provider in use (whether it supports streaming, models, or refresh). <br> ## Exit Codes
| Code | Canonical Variable | Meaning |
| :--- | :--- | :--- |
| **0** | - | Operational success. |
| **10** | BASH4LLM_ERR_NO_API_KEY | Authentication failed or missing API Key for the active provider. |
| **11** | BASH4LLM_ERR_BAD_MODEL | Invalid, unsupported (non-textual), or non-whitelisted model. |
| **12** | BASH4LLM_ERR_CURL_FAILED | Network connection error or failure executing the curl command. |
| **14** | BASH4LLM_ERR_NO_PROMPT | Empty input or request prompt not specified. |
| **15** | BASH4LLM_ERR_TMP | Filesystem error (directory cannot be created, lock collision, or symlink detected). |
| **16** | BASH4LLM_ERR_API | HTTP error returned by the API or JSON response uninterpretable by the core. |
| **17** | BASH4LLM_ERR_SEC | Security policy violation (configuration file modifiable by third parties). |

## License
Bash4LLM⁺ is released under the **GNU GPL v3** license.
See the **LICENSE** file for more details.

## Contacts
*   **Author:** Cristian Evangelisti  
*   **Email:** `opensource@cevangel.anonaddy.me`  
*   **Repository:** [GitHub kamaludu/bash4llm](https://github.com/kamaludu/bash4llm)
