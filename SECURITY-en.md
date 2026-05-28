[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README-en.md)

# SECURITY POLICY  [🇮🇹](SECURITY.md) 🇬🇧

## GroqBash⁺ — Security Policy

GroqBash is a single Bash script designed with strong focus on **security**, **portability**, and **transparency**.  
This document describes the **threat model**, **security assumptions**, **known limitations**, **recommendations**, and the **responsible disclosure** process.

---

## 1. Supported versions

Only the latest stable release receives security fixes.

---

## 2. Threat model

GroqBash is designed for **single‑user** environments, such as:

- personal PCs/laptops  
- private servers  
- Termux installations  
- WSL environments  
- local development shells  

GroqBash is **not** designed for:

- multi‑tenant or hostile servers  
- environments where untrusted users can modify the filesystem  
- systems where environment variables can be manipulated by third parties  
- scenarios requiring strong sandboxing or privilege separation  

### Fundamental assumptions

GroqBash assumes that:

- The user **owns** and **controls** the directories where GroqBash and extras reside.  
- No untrusted user can write to:
  - `$GROQBASHEXTRASDIR`
  - `$GROQBASHTMPDIR`
  - the directory containing `groqbash`
- Environment variables are **trusted configuration**, not untrusted input.
- Providers are **trusted code**, not plugins from unknown sources.

---

## 3. Security principles

### ✔ No execution of model output  
GroqBash **never executes** API responses as shell commands.

### ✔ No `eval`  
The script does not use `eval` or equivalent constructs.

### ✔ No use of `/tmp`  
Internal temporary files are **never** created in `/tmp`.  
GroqBash uses:

- `$GROQBASHTMPDIR` (if set)  
- a safe fallback in the user’s home directory  

Temporary files are created with:

- `mktemp -d`  
- permissions `700`

### ✔ No hidden fallback  
If the model list is empty, GroqBash fails safely.

### Provider security:
verifies that the provider defines required functions  
(buildpayload_<p>, call_api_<p>, etc.)

### API key security
The code checks:  
presence of API key for model refresh, presence of API key for API calls, clear errors: `GROQBASHERRNOAPIKEY`

### Model security
The code checks:  
valid model via `validate_model_core`, allowed model via `ALLOWED_MODELS`

### Input security
The code handles:  
`JSON_INPUT`, `FILE_INPUTS`, `TEMPLATE`, `STDIN_CONTENT`

### Session security
The code:  
creates session directories with `mkdir -p`, sets permissions 700, uses JSON files for history

### Tmpdir security
The code:  
uses `GROQBASH_TMPDIR`, fails if not writable, does NOT use system `/tmp`

---

## 4. Known limitations

GroqBash is a Bash script, not a sandboxed runtime.

### ⚠ Residual TOCTOU risks  
Bash cannot fully eliminate race conditions.

### ⚠ Providers are code  
Scripts in `extras/providers/` are **executed in the shell**.  
They must be:

- owned by you  
- not writable by others  
- stored in trusted directories  

### ⚠ Environment variables are considered trusted  
Examples:

- `GROQBASHEXTRASDIR`
- `GROQBASHTMPDIR`
- `GROQ_API_KEY`
- `GROQ_MODEL`

### ⚠ No multi‑user isolation  
GroqBash does not attempt to isolate itself from other users on the same system.

---

## 5. Recommendations for safe usage

### ✔ Keep GroqBash in a directory you own

`CODEON
mkdir -p "$HOME/.local/bin"
CODEOFF`

### ✔ Keep extras directories secure

`CODEON
chmod 700 "$GROQBASHEXTRASDIR"
chmod -R go-w "$GROQBASHEXTRASDIR"
CODEOFF`

### ✔ Install providers only from trusted sources  
Providers are shell scripts executed directly.

### ✔ Avoid shared or hostile environments  
GroqBash is not designed for multi‑tenant servers.

### ✔ Use `--debug` only in safe environments  
Debug mode preserves potentially sensitive temporary files.

---

## 6. Reporting vulnerabilities

If you discover a security issue, report it **privately**.

#### Contact (private disclosure)
- **Email:** opensource​@​cevangel.​anonaddy.​me  
- **Subject:** `[GroqBash Security Report]`

Include:

- clear description of the issue  
- steps to reproduce  
- environment details (OS, Bash, Termux/macOS/etc.)  
- potential impact (code execution, escalation, data exposure)

Typical response time: **within 72 hours**.

---

## 7. Responsible Disclosure

- Do not open public issues for vulnerabilities.  
- Do not publish details before the fix.  
- Coordinated disclosure is appreciated.  
- Public acknowledgment is optional.

---

## 8. Security extras

GroqBash includes optional tools in `extras/security/`:

- `verify.sh` — checks provider integrity  
- `validate-env.sh` — verifies environment security  

They do not modify core behavior.

---

## 9. Final notes

GroqBash is built with strong attention to security, but it remains a Bash script.  
The user must understand its assumptions and limitations before using it in sensitive environments.

Full documentation:

- **[README](README-en.md)**  
- **[INSTALL](INSTALL-en.md)**  
- **[CHANGELOG](CHANGELOG.md)**
