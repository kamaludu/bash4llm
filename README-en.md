[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![ShellCheck](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/bash4llm/actions/workflows/smoke.yml)

# Bash4LLM⁺ [🇮🇹](README.md) 🇬🇧


### Bash4LLM⁺ — secure, Bash‑first, fully auditable CLI wrapper for Groq’s OpenAI‑compatible Chat Completions API

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

Bash4LLM⁺ requires the following packages (or equivalents) to be available in `PATH`:

- **bash**  
- coreutils  
- findutils  
- util‑linux  
- gawk  
- curl  
- jq

---

## Installation

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

Detailed instructions: **[INSTALL](INSTALL-en.md)**

Quick summary:
```sh
chmod +x bash4llm
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
./bash4llm --help
```

Optional extras:
```sh
./bash4llm --install-extras
```

Extras install options:
- `--source <dir>`  
- `--force`  
- `--dry-run`  
- selective install: `./bash4llm --install-extras provider1 templateA`

---

## Quick usage

**Direct prompt**
```sh
./bash4llm "write a short poem in Italian"
```

**Multiline prompt**
```sh
./bash4llm <<'EOF'
write a short poem
in Italian
EOF
```

**Input from file**
```sh
./bash4llm -f prompt.txt
```

**Pipe**
```sh
echo "explain relativity" | ./bash4llm
```

**Specific model**
```sh
./bash4llm -m llama-3.3-70b-versatile "write a short essay"
```

**Dry run**
```sh
./bash4llm --dry-run "hello"
```

**External provider (if installed)**
```sh
./bash4llm --provider gemini "translate this"
```

---

## Commands, flags and available options

### Models and providers
| Flag | Argument | Effect |
|------|----------|--------|
| `--refresh-models`, `--refresh-model` | no | Refresh the model list (requires API key). |
| `--list-models` | no | Print model list (interactive format). |
| `--list-models-raw` | no | Print model list raw (one line per model). |
| `--list-providers` | no | Print provider list. |
| `--list-providers-raw` | no | Print providers raw. |
| `--set-default <model>` | yes | Set persistent default model for the active provider. |
| `-m <model>`, `--model <model>` | yes | Set model for this run. |
| `--provider <name>` | yes | Set provider from CLI. |
| `--provider` | no | If no argument → open interactive selection. |

### Input (file, JSON, template, batch)
| Flag | Argument | Effect |
|------|----------|--------|
| `-f <file>` | yes | Add file to `FILE_INPUTS`. |
| `--json-input <json>` | yes | Set JSON input (OpenAI‑like format). |
| `--template <name>` | yes | Apply template from `BASH4LLM_TEMPLATES_DIR`. |
| `--batch <file>` | yes | Run batch requests (one prompt per line). |

### Sessions
| Flag | Argument | Effect |
|------|----------|--------|
| `--session <id>` | yes | Enable session with specific ID. |
| `--session-window [n]` | optional | Set session window (default 10 if not provided). |

### Model / generation parameters
| Flag | Argument | Effect |
|------|----------|--------|
| `--system <text>` | yes | Set system prompt. |
| `--ture <n>` | yes | Set temperature parameter (0.0–2.0, canonical alias). |
| `--temperature <n>` | yes | Alias for `--ture`. |
| `--max <n>` | yes | Set max tokens. |

### Output and saving
| Flag | Argument | Effect |
|------|----------|--------|
| `--save` | no | Force saving output. |
| `--nosave` | no | Disable saving. |
| `--out <path>` | yes | Output file/directory path. |
| `--threshold <n>` | yes | Byte size threshold for automatic saving (default: 1000). |
| `--json` | no | Output raw JSON intact. |
| `--pretty` | no | Pretty‑print JSON output. |
| `--text` | no | Standard extracted textual output (default behavior). |
| `--raw` | no | Raw textual output excluding final separators. |

### Operational modes
| Flag | Argument | Effect |
|------|----------|--------|
| `--dry-run` | no | No real API call (simulated behavior). |
| `--quiet` | no | Reduce nonessential output and suppress titles on TTY. |
| `--stream` | no | Enable asynchronous streaming. |
| `--no-stream` | no | Disable asynchronous streaming. |
| `--chat` | no | Interactive REPL chat mode. |
| `--bootstrap-only` | no | Only validate paths/locks and exit. |

### Configuration and diagnostics
| Flag | Argument | Effect |
|------|----------|--------|
| `--show-config` | no | Show full active configuration. |
| `--diagnostics` | no | Run full system diagnostics. |
| `--version` | no | Print script version and exit. |
| `-h`, `--help` | no | Show interactive help formatted from file. |

### Install extras
| Flag | Argument | Effect |
|------|----------|--------|
| `--install-extras` | optional | Install extras; may accept source directory. |
| `--install-extras=<dir>` | yes | Install extras from specified source directory. |

### Parsing termination
| Flag | Effect |
|------|--------|
| `--` | End option parsing. |
| `-*` | Unknown option → error. |
| `*` | Positional argument → appended to `ARGS`. |

---

## Configuration and models

### Configuration files
- `$BASH4LLM_CONFIG_DIR/config` → local parameters (MODEL, TURE, MAX_TOKENS, FORMAT, THRESHOLD)  
- `$BASH4LLM_CONFIG_DIR/model.$PROVIDER` → default model for provider  
- `$MODELS_FILE` → model whitelist updated by `--refresh-models`

### Model selection precedence
1. `-m/--model`  
2. `model.$PROVIDER`  
3. provider auto‑selection (`auto_select_model_<provider>`)  
4. first entry in whitelist (`models.txt`)  
5. legacy global `config` (`MODEL=...`)

---

## Temporary files and output

- No use of system shared `/tmp`.  
- Temporary files isolated in `$RUN_TMPDIR` with `700` permissions (`umask 077`).  
- Saved files use `600` permissions.  
- With `--out` Bash4LLM⁺ creates the directory if possible.

---

## UI State System (ui_state)

Bash4LLM⁺ exposes operational metadata for GUIs/external tools via atomic JSON files in:

```
$BASH4LLM_CONFIG_DIR/ui_state
```

Contains:

- `sessions/<id>.json` → session state (active, msg_count, last_ts)  
- `sessions/index.json` → session list  
- `last_api.json` → last API result (http_status, req_id, edgecase_detected, etc.)  
- `last_history.json` → last saved history  
- `provider_capabilities.json` → active provider capabilities (streaming, refresh_models)

Optional GUI extras should read **only** these files for CGI placeholders.

---

## Contextual memory in Bash4LLM⁺

Bash4LLM⁺ **does not keep memory by itself**. Memory exists **only if you enable a session** via `--session`.

Each session creates a persistent NDJSON file:

```
$BASH4LLM_HISTORY_DIR/sessions/<session_id>.ndjson
```

Bash4LLM⁺ also keeps session metadata in:

```
$BASH4LLM_CONFIG_DIR/ui_state/sessions/<session_id>.json
```

These metadata files are the canonical source for external GUIs/tools.

### Correct usage of `--session`
```sh
./bash4llm --session chat1 "Ciao"
./bash4llm --session chat1 "Summarize what I said"
```

### Correct usage of `--session-window`
```sh
./bash4llm --session chat1 --session-window 10 "continue"
```

### Fundamental rule
To have contextual memory **you must always** include `--session <id>`.

---

## Security notes

- No `eval`.  
- Never execute model output.  
- Provider = code: keep `extras/providers` secure.  
- Environment variables = trusted configuration.  
- TOCTOU mitigations in place.

---

## Exit codes

| Code | Variable | Meaning |
|:---:|:---|:---|
| **0** | - | Success |
| **10** | `BASH4LLM_ERR_NO_API_KEY` | Missing API key |
| **11** | `BASH4LLM_ERR_BAD_MODEL` | Invalid or non‑whitelisted model |
| **12** | `BASH4LLM_ERR_CURL_FAILED` | Network/curl error |
| **14** | `BASH4LLM_ERR_NO_PROMPT` | No prompt provided |
| **15** | `BASH4LLM_ERR_TMP` | Generic filesystem / temp error |
| **16** | `BASH4LLM_ERR_API` | Provider HTTP/API error |

---

## Main environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GROQ_API_KEY` | yes for API calls | Groq provider API key. |
| `BASH4LLM_CONFIG_DIR` | recommended | Configuration directory. |
| `BASH4LLM_MODELS_DIR` | recommended | Models directory. |
| `BASH4LLM_TMPDIR` | yes | Temporary directory. |
| `BASH4LLM_HISTORY_DIR` | recommended | Sessions and history directory. |
| `MODEL` | no | Active model. |
| `PROVIDER` | no | Active provider. |
| `ALLOWED_MODELS` | no | Whitelisted allowed models. |

---

## License

Bash4LLM⁺ is distributed under **GPL v3**. See **[LICENSE](LICENSE)**.

---

## Contacts

Author: **Cristian Evangelisti**  
Email: `opensource@cevangel.anonaddy.me`  
Repository: `https://github.com/kamaludu/bash4llm`
