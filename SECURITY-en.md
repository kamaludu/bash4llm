[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README-en.md)

# Security Policy for Bash4LLM⁺ [🇮🇹](SECURITY.md) 🇬🇧

This document details the threat model, filesystem assumptions, built-in security mitigations, known limitations, and procedures for private vulnerability disclosure.

---

## 1. Supported Versions

Security maintenance and patch releases are provided exclusively for the latest stable release on the `main` branch of the repository.

---

## 2. Threat Model

Bash4LLM⁺ is engineered for operation in controlled, **single-user** environments:
* Personal desktop and laptop systems.
* Dedicated servers, private compute nodes, or single-owner container environments.
* Protected sandboxed terminals such as Termux on personal Android devices.
* WSL (Windows Subsystem for Linux) environments or standard Unix/Linux/BSD user consoles.

Bash4LLM⁺ **is not designed for**:
* Multi-tenant shared servers with untrusted users.
* Systems where concurrent unauthorized users possess physical write access to the script working directory.
* Direct execution as the `root` user in exposed network services.

### Filesystem Security Assumptions
The runtime operates under the assumptions that:
1. The executing user is the exclusive owner and write-access holder for the root directory (`bash4llm.d/`) and its subdirectories.
2. External modules placed in `extras/` originate from verified sources and match expected cryptographic digests.
3. Unprivileged local processes cannot inspect or alter process memory of other user sessions.

---

## 3. Built-In Security Mitigations

### Process Argument Secret Redaction (`argv`)
All HTTP network interactions (synchronous, streaming, model-refresh, and key-validation) route through the authoritative Core function `_exec_curl_secure()`. API keys and Bearer tokens are written strictly to private temporary header files (`0600`) and forwarded to `curl` via File Descriptor redirection (`/dev/fd/3`). Consequently, credentials **never appear in process argument vectors (`argv`)** and are protected against local process inspection interfaces (`ps aux` or `/proc/<pid>/cmdline`).

### Remote Code Execution (RCE) Prevention
Bash4LLM⁺ handles, displays, and archives textual API outputs. The script **never executes** model-generated text within the active shell interpreter, eliminating Remote Code Execution (RCE) risks stemming from indirect Prompt Injection attacks.

### Prohibition of Dynamic Code Evaluation (`eval`)
In accordance with Security Invariant **[INV-3]**, introducing new `eval` statements is prohibited. The single pre-existing trap-restoration statement is isolated and documented under technical debt tracking.

### Temporary File Isolation (No Shared `/tmp`)
Per Invariant **[INV-2]**, the runtime **never writes temporary files to the shared `/tmp` system directory**. All transactions, error logs, and payload buffers are processed inside an isolated temporary directory (`RUN_TMPDIR`), created as a subfolder of `bash4llm.d/tmp/` with exclusive `0700` permissions and `0600` file permissions (`umask 077`).

### Isolated Module Loading and Fail-Closed Verification
Provider modules and hooks loaded from `extras/` are parsed inside an isolated subshell before importing function definitions. Prior to loading, `verify_module_integrity()` enforces path security validation and SHA-256 digest matching against `extras/manifest.sha256`. Any hash mismatch or computation error triggers an immediate execution halt with exit code `17` (`BASH4LLM_ERR_SEC`).

### Read-Only Security Function Guards (`readonly -f`)
Upon completion of Core initialization, `_lock_security_guards()` locks all security, network mediation, and filesystem functions as `readonly -f`. This prevents post-initialization function overriding or hijacking in shell memory.

### Encrypted Key Storage (`--vault`)
Via the OpenSSL helper module (`--vault`), API keys can be stored encrypted on disk (`keys.dat`) using AES-256-CBC with PBKDF2 key derivation (100,000 iterations) and salt. Unlocked session context caching (`_B4L_RT_CTX`) allows continuous execution without storing plaintext keys on disk.

### RAM Session Sandboxing for Interactive Input
Manual key input uses TTY-level input masking (`stty -echo`). When exporting a key for the current session, the script executes an OS process replacement via `exec "${SHELL:-bash}"`, holding the key in RAM without writing commands to shell history files (`.bash_history`).

### Concurrency Lock Handling on Termux (Android)
On Android/Termux environments where system `flock` may fail due to SELinux or kernel policies, locking transparently detours to an atomic directory lock mechanism (`mkdir`).

---

## 4. Known Limitations

* **POSIX Filesystem Race Condition (TOCTOU):** On standard POSIX filesystems, a theoretical window (Time-of-Check to Time-of-Use) exists between checking file permissions and performing operations. This risk is mitigated by enforcing isolated `0700` parent directories.
* **Debug File Preservation:** Enabling debug mode (`--debug` or `DEBUG=1`) preserves temporary files in `RUN_TMPDIR` for troubleshooting. Debug mode should be disabled in production environments.

---

## 5. Security Configuration Guidelines

1. **Install in a restricted user directory:**
   ```sh
   mkdir -p "$HOME/.local/bin"
   cp bash4llm "$HOME/.local/bin/"
   chmod 700 "$HOME/.local/bin/bash4llm"
   ```
2. **Apply restrictive permissions to the data folder:**
   ```sh
   chmod 700 "$HOME/bash4llm.d"
   chmod 600 "$HOME/bash4llm.d/config/config"
   ```
3. **Run Configuration Audits:**
   Periodically verify permissions using the static linter:
   ```sh
   ./bash4llm --check-config
   ```

---

## 6. Core Binary Protection

To protect the main script from unauthorized modification by unprivileged processes, set appropriate ownership and immutability controls:

### Linux (GNU/Linux)
```bash
sudo chown root:root /path/to/bash4llm
sudo chmod 755 /path/to/bash4llm
sudo chattr +i /path/to/bash4llm
```

### macOS / BSD
```bash
sudo chown root:wheel /path/to/bash4llm
sudo chmod 755 /path/to/bash4llm
sudo chflags schg /path/to/bash4llm
```

### Termux (Android)
```bash
chmod 500 ~/bash4llm
```

### WSL / Cygwin
```bash
setfacl -b /path/to/bash4llm 2>/dev/null
chmod 755 /path/to/bash4llm
```

---

## 7. Private Vulnerability Reporting (Responsible Disclosure)

To report potential security vulnerabilities in the Core script or extension modules, submit a confidential report:

* **Email:** `opensource@cevangel.anonaddy.me`
* **Subject:** `[Bash4LLM Security Report]`

Please include:
1. Technical description of the vulnerability.
2. Reproduction steps or Proof of Concept (PoC).
3. Estimated impact and proposed remediation if available.

Initial triage will begin within 72 hours of receipt, with coordinated patch disclosure prior to public release.
