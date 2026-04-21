[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
[![CLI](https://img.shields.io/badge/CLI-green?&logo=gnu-bash&logoColor=grey)](#)
[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![ShellCheck](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/shellcheck.yml)
[![Smoke Tests](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml/badge.svg)](https://github.com/kamaludu/groqbash/actions/workflows/smoke.yml)

# GroqBash⁺ [🇮🇹](README.md) 🇬🇧

**GroqBash⁺** — secure, Bash‑first and fully auditable CLI wrapper for Groq’s OpenAI‑compatible Chat Completions API.

GroqBash is a single Bash script, self‑contained, readable and verifiable.  
Download it, make it executable, export your API key and start using it.

Compatible with Unix‑like environments: Linux, macOS, WSL, Termux.

---

## Key features

- **Dynamic model list**  
  via `GET https://api.groq.com/openai/v1/models`  
  → no hardcoded models.

- **Security by design**  
  → no use of `/tmp`, no `eval`, restrictive permissions, advanced provider validation.

- **Modular sectioned structure**  
  → BOOTSTRAP, HISTORY_MANIFEST, INSTALL_EXTRAS, PROVIDER, CLI_MAIN.

- **Streaming and non‑streaming**  
  → real‑time output or full response at the end.

- **Automatic saving**  
  → for long outputs above a configurable threshold.

- **Advanced model management**  
  → refresh, list, persistent default, dynamic whitelist, auto‑selection.

- **Optional extras**  
  → additional providers, templates, documentation, security tools.

---

## Threat model (short)

GroqBash is designed for single‑user environments (laptop, Termux, personal shell).

- Providers are code executed in your shell: they must reside in secure directories.  
- Variables such as `GROQBASH_EXTRAS_DIR` and `GROQBASH_TMPDIR` are considered trusted configuration.  
- The script never executes model output.  
- TOCTOU risks and JSON/SSE parsing limits are mitigated and documented.

See  **[SECURITY](SECURITY-en.md)** for full details.

---

## Requirements

GroqBash requires the following packages (or equivalent) to be available in the PATH:

- ***bash***
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

These packages provide all the necessary commands:
*bash* ` mv cp chmod stat find sort head wc tee date curl jq flock base64 mktemp readlink awk sed grep xargs sync sha256sum stdbuf `

---

## Installation

Detailed instructions in:  **[INSTALL](INSTALL-en.md)**

In short:

`chmod +x groqbash`  
`export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxx"`  
`./groqbash --help`

Optional extras:

`./groqbash --install-extras`

With options:

- `--source <dir>`  
- `--force`  
- `--dry-run`  
- selective install: `./groqbash --install-extras provider1 templateA`

---

## Quick start

Direct prompt:

`./groqbash "write a short poem in Italian"`

Multiline prompt:

```sh
./groqbash <<'EOF'
> scrivi una breve poesia
> in italiano
> EOF
```

Input from file:

`./groqbash -f prompt.txt`

Pipe:

`echo "explain relativity" | ./groqbash`

Specific model:

`./groqbash -m llama-3.3-70b-versatile "write a short essay"`

Dry run:

`./groqbash --dry-run "hello"`

External provider (if installed):

`./groqbash --provider gemini "translate this"`

---

## Main options

| Option | Description |
|--------|-------------|
| `-m, --model <name>` | Select model |
| `-f <file>` | Read prompt from file |
| `--system <text>` | Set system prompt |
| `--ture <value>` / `--temperature <value>` | Temperature |
| `--max <n>` | Max tokens |
| `--refresh-models` | Refresh model list |
| `--list-models` | Show available models |
| `--set-default <model>` | Set persistent default model |
| `--provider <name>` | Use external provider |
| `--provider` | Interactive provider selection |
| `--install-extras` | Install extras |
| `--json-input <file>` | Direct JSON input |
| `--template <name>` | Use template |
| `--batch <file>` | Run batch of prompts |
| `--stream` / `--no-stream` | Streaming on/off |
| `--json` / `--pretty` / `--raw` / `--text` | Output formats |
| `--save` / `--nosave` | Force save or no save |
| `--out <path>` | Output path |
| `--threshold <n>` | Autosave threshold |
| `--quiet` | Minimal output |
| `--debug` | Extended debug |
| `--diagnostics` | Full diagnostics |
| `--show-config` | Show configuration |
| `--version` | Version |
| `-h, --help` | Help |

---

## Configuration and models

### Configuration files

- `$GROQBASH_CONFIG_DIR/config`  
  → local parameters (MODEL, TURE, MAX_TOKENS, FORMAT, THRESHOLD)

- `$GROQBASH_CONFIG_DIR/model.$PROVIDER`  
  → default model per provider

- `$MODELS_FILE`  
  → whitelist updated by `--refresh-models`

### Model selection precedence

1. `-m/--model`  
2. `model.$PROVIDER`  
3. `config`  
4. provider auto‑selection  
5. first entry in whitelist

---

## Temp files and output paths

- No use of `/tmp`.  
- Runtime temporaries in a dedicated directory with 700 permissions.  
- Saved files with 600 permissions.  
- With `--out` GroqBash creates the directory if possible.


---

# 🟦 How contextual memory works in GroqBash
GroqBash **does not keep memory on its own**.  
Memory exists **only if you enable a session** via `--session`.

Each session creates a persistent NDJSON file:

```
$GROQBASH_HISTORY_DIR/sessions/<session_id>.ndjson
```

Every message is **appended** there, and on subsequent invocations GroqBash reads the last N lines and resends them to the model as `messages`.

---

### 🟩 Correct use of `--session`
Enable a persistent session:

```sh
./groqbash --session chat1 "Hello"
```

Effect:
- creates/uses `sessions/chat1.ndjson`
- saves the message
- on subsequent invocations retrieves the contextual window

---

### 🟩 Correct use of `--session-window`
Controls **how many previous messages** are resent to the model:

```sh
./groqbash --session chat1 --session-window 10 "continue"
```

Meaning:
- read the **last 10 messages**
- build `BUILD_MESSAGES_FILE`
- the model sees the previous conversation

If omitted → default **10**  
If >20 → GroqBash warns (but accepts)

---

### 🟧 Fundamental rule
To have contextual memory you **must always** include `--session <id>` in every invocation of the same conversation.

Correct example:

```sh
./groqbash --session chat1 "Hello"
./groqbash --session chat1 "Summarize what I said"
```

Incorrect example (loses memory):

```sh
./groqbash "Hello"
./groqbash "Summarize what I said"
```

---

## Advanced extras

Extras do not change core behavior.

### Security

- additional providers (**see: [ PROVIDERS](PROVIDERS.md)**)
- tools to verify permissions, symlinks, owner, checksum  
- templates and documentation

### Tests

- JSON/SSE suite  
- provider tests

---

## Security notes

- No `eval`.  
- No execution of model output.  
- Provider = code: keep `extras/providers` secure.  
- Environment variables = trusted configuration.  
- JSON/SSE parsing robust but not a full parser.  
- TOCTOU mitigated.

---

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| `GROQBASHERRTMP` | Generic / temporary error |
| `GROQBASHERRCURL_FAILED` | Network / curl error |
| `GROQBASHERRAPI` | HTTP/API error |
| `GROQBASHERRBAD_MODEL` | Invalid model |
| `GROQBASHERRNO_PROMPT` | No prompt provided |
| `GROQBASHERRNOAPIKEY` | API key missing |
| `GROQBASHERRINSTALL` | Extras installer error |

---

## License

GroqBash is distributed under the GPL v3 license.  
See `LICENSE`.

---

## Contacts

Author: Cristian Evangelisti  
Email: opensource@cevangel.anonaddy.me  
Repository: https://github.com/kamaludu/groqbash
