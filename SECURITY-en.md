[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README-en.md)

# SECURITY POLICY  [🇮🇹](SECURITY.md) 🇬🇧

## Security Policy for Bash4LLM⁺
Bash4LLM⁺ was developed by adopting rigorous design principles regarding **variable safety**, **protection of information in transit and locally**, and the **prevention of code injection**.
This document describes its threat model, core filesystem assumptions, known limitations, and channels for private vulnerability disclosure.

## 1. Supported Versions
Only the latest official stable version released on the main branch of the repository receives bug fixes and security patches.

## 2. Threat Model
Bash4LLM⁺ is designed to operate in trusted, **single-user** contexts:
 * Personal desktop and laptop computers.
 * Personal servers, private compute nodes, or single-owner Docker instances.
 * Protected local terminals such as Termux on personal mobile devices (Android).
 * WSL (Windows) development environments or standard Unix user consoles.
Bash4LLM⁺ is **not** designed for:
 * Shared multi-tenant servers with hostile or unauthorized users.
 * Environments where concurrent unauthorized users have physical write access to the same folders as the script.
 * Being executed by the root user in exposed network contexts.

### Fundamental Security Assumptions
The script assumes that:
 1. The user running the script is the exclusive owner and holder of write permissions for the main working directory bash4llm.d/ and its configuration and extras folders.
 2. The provider modules placed in the extras folder come exclusively from controlled and trusted sources.
 3. Local environment variables loaded into memory cannot be intercepted or manipulated by hostile local users with higher privileges.

## 3. Built-In Security Mitigations

### ✔ No Execution of Generated Content (RCE Prevention)
Bash4LLM⁺ strictly routes, displays, and optionally archives the text output returned by the LLM API. The script **never executes** the model's output within the current shell, completely eliminating at the root the risk of Remote Code Execution (RCE) vulnerabilities arising from indirect Prompt Injection attacks.

### ✔ Absolute Ban on the eval Command
No part of the internal code of the main script, nor its parsing and module-loading functions, uses the eval command or similar mechanisms for dynamic command-string evaluation, thereby preventing Bash code injection attempts.

### ✔ Temporary File Isolation (No Global /tmp)
To eliminate hijacking risks based on the use of symbolic links (*Symlink Exploitation*) or write collisions caused by concurrent processes, the script **never uses** the operating system's shared /tmp directory.
All transactions, network error files, or raw responses are processed inside the isolated execution temporary directory (RUN_TMPDIR), created as a local subdirectory of bash4llm.d/tmp/ with exclusive 700 permissions (umask 077).

### ✔ Provider Module Import Sandbox
To ensure that optional provider modules loaded from the extras directory cannot pollute the main runtime with unstable global variables or execute arbitrary code at startup, loading occurs within an isolated sandbox subshell.
**Exclusively authorized function signatures** (buildpayload_*, call_api_*) are extracted and exported to the main shell, ignoring any global instructions placed outside the functions themselves.

### ✔ Symmetric Encryption for API Keys (--vault)
Bash4LLM⁺ does not require storing API keys in plaintext inside configuration files. By activating the optional OpenSSL module (--vault), authentication keys are placed inside a symmetrically encrypted database (keys.dat).
Protection is guaranteed by a Master Password with AES-256-CBC encryption, PBKDF2 key derivation (100,000 iterations), and a cryptographic salt, preventing credential theft in the event of physical inspection or disk copying. Unlocking via a session token stored in memory (_B4L_RT_CTX) allows bypassing constant password entry without compromising security at rest.

### ✔ Volatile RAM Session Sandboxing
Standard environment variable exports (e.g., `export KEY="value"`) executed directly at the user's terminal prompt pose significant security threats, specifically command history harvesting (*Command History Leak*) and scrollback buffer persistence (*Scrollback Leak*).

To eliminate these threat vectors in transient environments without sacrificing usability, Bash4LLM⁺ implements a native **Volatile RAM Session Sandboxing** mechanism:
*   **TTY-level Input Masking**: Manual key ingestion is performed using an internal `read` builtin temporarily coupled with `stty -echo`. This disables character echoing during pasting or typing, preventing any visual persistence in the terminal emulator's buffer.
*   **Process Image Replacement (exec)**: If the user opts to export the key to the current session via the interactive `y/N` prompt in a non-sourced execution context, the script injects the key into its process environment and triggers an OS-level process replacement:
    ```bash
    # Executed context: export key and replace the process with a new active shell
    export GROQ_API_KEY="typed_value"
    exec "${SHELL:-bash}"
    ```
*   **Zero-Footprint Lifecycle**: This instruction instantly replaces the active `./bash4llm` child process with a fresh, nested interactive shell session. The environment key is inherited strictly inside the volatile RAM of this sub-shell. Because the `export` command was never typed directly in the parent terminal's prompt, **no secret key records are ever written to the user's command history file**.
*   **Instant Memory Deallocation**: Typing the `exit` command terminates the sub-shell, causing the operating system to immediately deallocate and wipe the volatile RAM segment containing the key. The user is returned to their pristine base terminal session.

### ✔ Termux Protection (Atomic Directory Lock)
On Android/Termux devices, the standard operating system-level flock utility can fail due to kernel security restrictions or SELinux policies.
Bash4LLM⁺ automatically detects the Termux environment, transparently disabling flock and automatically falling back to an atomic lock mechanism based on the creation of exclusive directories (atomic mkdir), ensuring the absolute integrity of NDJSON thread logs without risks of process locking.

## 4. Known Limitations
 * **TOCTOU (Time-of-Check to Time-of-Use) Vulnerability:** Although the script performs strict security checks on file write permissions before loading or writing to them, a microscopic window remains at the base POSIX filesystem level where an attacker with root privileges or concurrent physical access to the folder could theoretically attempt file substitution between the check phase and the use phase.
 * **Debugging Exposes Sensitive Data:** Using debug mode (BASH4LLM_DEBUG=1 or --debug) disables the automatic removal of transaction temporary files to allow inspection of the curl output. It is recommended not to keep debug mode active in production environments, as files in tmp/ would remain stored on disk until the next transaction.

## 5. Hardening Recommendations
 1. **Install in a user folder that is inaccessible to others:**
   ```sh
   mkdir -p "$HOME/.local/bin"
   cp bash4llm "$HOME/.local/bin/"
   chmod 700 "$HOME/.local/bin/bash4llm"
   
   ```
 2. **Apply restrictive permissions to the runtime folder:**
   ```sh
   chmod 700 "$HOME/bash4llm.d"
   chmod 600 "$HOME/bash4llm.d/config/config"
   
   ```
 3. **Use --check-config regularly:**
   Run the built-in static scanner before launching in sensitive environments to ensure that no configuration files can be modified by third parties.

## 6. Private Vulnerability Reporting (Responsible Disclosure)
If you detect a potential vulnerability or security flaw within the core script or its extensions, please report it in a **confidential and private** manner to protect the integrity of active users.

#### Contact for Private Reporting:
*   **Email:** `opensource@cevangel.anonaddy.me`
*   **Subject:** `[Bash4LLM Security Report]`

We kindly ask you to include in your report:
 1. A detailed description of the nature of the vulnerability.
 2. A Proof of Concept (PoC) or the sequence of commands necessary to reproduce the vulnerability scenario.
 3. The estimated impact and any suggestions for a corrective patch.
We commit to responding for the initial analysis **within 72 hours** of receiving the report and to coordinating the release of the patch together before publicly disclosing the details of the vulnerability.
