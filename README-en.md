[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![ShellCheck](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml)

# GroqBash⁺ [🇮🇹](README.md) 🇬🇧

**GroqBash⁺** — secure, Bash‑first, fully auditable CLI wrapper for Groq’s OpenAI‑compatible Chat Completions API.

GroqBash is a single Bash script, self‑contained, readable, and verifiable.  
Download it, make it executable, export your API key, and start using it immediately.

Compatible with Unix‑like environments: Linux, macOS, WSL, Cygwin, Termux, BSD.

---

## Main features

- **Dynamic model list**  
  via `GET https://api.groq.com/openai/v1/models`  
  → no hardcoded models.

- **Security by design**  
  → no use of `/tmp`, no `eval`, restrictive permissions, advanced provider validation.

- **Modular sectioned structure**  
  → PRECORE_BOOT, PRECORE_RUN, PROVIDER, CORE_SETUP, CORE_PROVIDER.

- **UI State System (ui_state)**  
  → the CORE exposes metadata for GUIs/external tools via atomic JSON files.

- **Streaming and non‑streaming**  
  → real‑time output or full output at end of response.

- **Automatic saving**  
  → for long outputs beyond a configurable threshold.

- **Advanced model management**  
  → refresh, list, persistent default, dynamic whitelist, auto‑selection.

- **Optional extras**  
  → additional providers, templates, documentation, security tools.

---

## Threat model (short version)

GroqBash is designed for single‑user environments (PC/laptop, personal servers).

- Providers are code executed in your shell: they must reside in secure directories.  
- Variables such as `GROQBASH_EXTRAS_DIR` and `GROQBASH_TMPDIR` are considered trusted configuration.  
- The script never executes model output.  
- TOCTOU risks and JSON/SSE parsing limits are mitigated and documented.

Full details in **`[Sembra che non fosse sicuro mostrare il risultato. Cambiamo le cose e facciamo un altro tentativo.]`**.

---

## Requirements

GroqBash requires the following packages (or equivalents) to be available in PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

---

## Installation

> [!TIP]
> **⏩ Quick Installation (Fast-Forward)**
> 
> Run these commands in your terminal to get **GroqBash** up and running immediately:
> 
> ```sh
> # 1. Clone the repository (shallow clone for maximum speed)
> git clone --depth 1 --branch main https://github.com/kamaludu/groqbash.git repo-groqbash  
> 
> # 2. Create a working directory and extract the executable
> mkdir -p groqbash
> cp repo-groqbash/bin/groqbash groqbash/
> chmod +x groqbash/groqbash
> 
> # 3. Enter the directory and refresh the models 
> cd groqbash 
> ./groqbash --refresh-models
> ```
> 
> The script will prompt you to enter your API key:
> `Enter API key for provider groq (env GROQ_API_KEY):`
> 
> Enter your API key, then export it to avoid entering it again during your current session:
> 
> `export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`
> 
> Enjoy GroqBash! ⚡


Detailed instructions in: **`[Sembra che non fosse sicuro mostrare il risultato. Cambiamo le cose e facciamo un altro tentativo.]`**

In short:

```sh
chmod +x groqbash
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"
./groqbash --help
```

Optional extras:

```sh
./groqbash --install-extras
```

With options:

- `--source <dir>`  
- `--force`  
- `--dry-run`  
- selective installation:  
  `./groqbash --install-extras provider1 templateA`

---

## Quick usage

Direct prompt:

```sh
./groqbash "write a short poem in Italian"
```

Multiline prompt:

```sh
./groqbash <<'EOF'
write a short poem
in Italian
EOF
```

Input from file:

```sh
./groqbash -f prompt.txt
```

Pipe:

```sh
echo "explain relativity to me" | ./groqbash
```

Specific model:

```sh
./groqbash -m llama-3.3-70b-versatile "write a short essay"
```

Dry run:

```sh
./groqbash --dry-run "hello"
```

External provider (if installed):

```sh
./groqbash --provider gemini "translate this"
```

---

## Commands, flags and available options

### Models and providers
| Flag | Argument | Effect |
|------|-----------|---------|
| `--refresh-models`, `--refresh-model` | no | Refreshes model list (requires API key). |
| `--list-models` | no | Prints model list (interactive format). |
| `--list-models-raw` | no | Prints model list in raw format (one line per model). |
| `--list-providers` | no | Prints provider list. |
| `--list-providers-raw` | no | Prints providers in raw format. |
| `--set-default <model>` | yes | Sets persistent default model. |
| `-m <model>`, `--model <model>` | yes | Sets model for this execution. |
| `--provider <name>` | yes | Sets provider from CLI. |
| `--provider` | no | Without argument → opens interactive selection. |

### Input (file, JSON, template, batch)
| Flag | Argument | Effect |
|------|-----------|---------|
| `-f <file>` | yes | Adds file to `FILE_INPUTS`. |
| `--json-input <json>` | yes | Sets JSON input. |
| `--template <name>` | yes | Applies template from `GROQBASH_TEMPLATES_DIR`. |
| `--batch <file>` | yes | Executes batch requests (one line = one prompt). |

### Sessions
| Flag | Argument | Effect |
|------|-----------|---------|
| `--session <id>` | yes | Enables session with specific ID. |
| `--session-window [n]` | optional | Sets session window (default 10 if not provided). |

### Model / generation parameters
| Flag | Argument | Effect |
|------|-----------|---------|
| `--system <text>` | yes | Sets system prompt. |
| `--ture <n>` | yes | Sets temperature (internal alias). |
| `--temperature <n>` | yes | Alias of `--ture`. |
| `--max <n>` | yes | Sets max tokens. |

### Output and saving
| Flag | Argument | Effect |
|------|-----------|---------|
| `--save` | no | Forces output saving. |
| `--nosave` | no | Disables saving. |
| `--out <path>` | yes | Output file/directory path. |
| `--threshold <n>` | yes | Size threshold for saving. |
| `--json` | no | JSON output. |
| `--pretty` | no | Pretty‑printed JSON output. |
| `--text` | no | Text output. |
| `--raw` | no | Raw output. |

### Operating modes
| Flag | Argument | Effect |
|------|-----------|---------|
| `--dry-run` | no | No API calls. |
| `--quiet` | no | Reduces output. |
| `--stream` | no | Enables streaming. |
| `--no-stream` | no | Disables streaming. |
| `--chat` | no | Interactive chat mode. |
| `--bootstrap-only` | no | Runs only bootstrap and exits. |

### Configuration and diagnostics
| Flag | Argument | Effect |
|------|-----------|---------|
| `--show-config` | no | Shows full configuration. |
| `--diagnostics` | no | Runs full diagnostics. |
| `--version` | no | Prints version and exits. |
| `-h`, `--help` | no | Shows help from file. |

### Extras installation
| Flag | Argument | Effect |
|------|-----------|---------|
| `--install-extras` | optional | Installs extras; may accept directory. |
| `--install-extras=<dir>` | yes | Installs extras from specific directory. |

### Parsing termination
| Flag | Effect |
|------|---------|
| `--` | Terminates option parsing. |
| `-*` | Unknown option → error. |
| `*` | Positional argument → added to `ARGS`. |

---

## Configuration and models

### Configuration files

- `$GROQBASH_CONFIG_DIR/config`  
  → local parameters (MODEL, TURE, MAX_TOKENS, FORMAT, THRESHOLD)

- `$GROQBASH_CONFIG_DIR/model.$PROVIDER`  
  → default model for provider

- `$MODELS_FILE`  
  → model whitelist updated by `--refresh-models`

### Model selection precedence

1. `-m/--model`  
2. `model.$PROVIDER`  
3. `config`  
4. provider auto‑selection  
5. first entry in whitelist

---

## Temporary files and output

- No use of `/tmp`.  
- Temporary files in dedicated directory with permissions 700.  
- Saved files with permissions 600.  
- With `--out`, GroqBash creates the directory if possible.

---

# 📁 UI State System (ui_state)

GroqBash exposes operational metadata intended for GUIs/external tools via atomic JSON files in:

```
$GROQBASH_CONFIG_DIR/ui_state
```

Contains:

- `sessions/<id>.json` → session state (active, msg_count, last_ts)  
- `sessions/index.json` → session list  
- `last_api.json` → last API result  
- `last_history.json` → last history save  
- `provider_capabilities.json` → active provider capabilities  

The GUI (optional extra) reads **only** these files for CGI placeholders (20–23).  
Placeholder semantics are defined in the *Unified Source of Truth for Placeholders (GUI + CGI)*.

---

# 📘 Contextual memory in GroqBash

GroqBash **does not maintain memory by itself**.  
Memory exists **only if you enable a session** via `--session`.

Each session creates a persistent NDJSON file:

```
$GROQBASH_HISTORY_DIR/sessions/<session_id>.ndjson
```

And GroqBash maintains session metadata in:

```
$GROQBASH_CONFIG_DIR/ui_state/sessions/<session_id>.json
```

These metadata files are the canonical source for GUIs/external tools.

---

### 🟩 Correct use of `--session`

```sh
./groqbash --session chat1 "Hello"
./groqbash --session chat1 "Summarize what I said"
```

### 🟩 Correct use of `--session-window`

```sh
./groqbash --session chat1 --session-window 10 "continue"
```

### 🟧 Fundamental rule

To have contextual memory **you must always** include `--session <id>`.

---

## Security notes

- No `eval`.  
- No execution of model output.  
- Provider = code: keep `extras/providers` secure.  
- Environment variables = trusted configuration.  
- TOCTOU mitigated.

---

## Exit codes

| Code | Meaning |
|--------|-------------|
| 0 | Success |
| `GROQBASHERRTMP` | Generic / temporary error |
| `GROQBASHERRCURL_FAILED` | Network/curl error |
| `GROQBASHERRAPI` | HTTP/API error |
| `GROQBASHERRBAD_MODEL` | Invalid model |
| `GROQBASHERRNO_PROMPT` | No prompt provided |
| `GROQBASHERRNOAPIKEY` | Missing API key |
| `GROQBASHERRINSTALL` | Extras installer error |

---

## Main variables

| Variable | Required | Description |
|-----------|------------|-------------|
| `GROQ_API_KEY` | yes for API calls | Provider API key. |
| `GROQBASH_CONFIG_DIR` | recommended | Configuration directory. |
| `GROQBASH_MODELS_DIR` | recommended | Models directory. |
| `GROQBASH_TMPDIR` | yes | Temporary directory. |
| `GROQBASH_HISTORY_DIR` | recommended | Sessions directory. |
| `MODEL` | no | Active model. |
| `PROVIDER` | no | Active provider. |
| `ALLOWED_MODELS` | no | Model whitelist. |

---

## License

GroqBash is distributed under GPL v3.  
See `LICENSE`.

---

## Contacts

Author: Cristian Evangelisti  
Email: opensource​@​cevangel.​anonaddy.​me  
Repository: [https://github.com/kamaludu/groqbash](https://github.com/kamaludu/groqbash)

---
