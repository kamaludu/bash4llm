<img width="64" height="64" alt="K" src="https://github.com/user-attachments/assets/a99ee2ca-9c1d-4bd4-8430-07f0bb0493f1" /> **Timeless Normatives**

## Bash4LLM Architecture Specification (Timeless Edition 2026.1)

**Status:** Standard / Definitive Architecture Specification  
**Scope:** Core Runtime & Extension Ecosystem  
**Authority:** Supreme Source of Truth (Precedes any Implementation Plan or Protocol)

---

### 1. Hierarchy of Authority

In the event of any ambiguity, conflict, or discrepancy between project documents:
1. **Architecture Specification (Edition 2026.1)** holds absolute authority.
2. **Implementation & Migration Plan** MUST yield to this Specification.
3. **LLM Execution Protocol** governs execution methodology only and SHALL NOT override architectural requirements.

---

### 2. System Requirements & Compatibility Contract

#### System Requirements
* **Shell Target:** Bash >= 4.0
* **Required System Utilities:** POSIX system utilities (`bash`, `jq`, `curl`, `mktemp`, `stat`, `base64`, `find`, `awk`, `sed`, `grep`, `xargs`, `tr`, `sort`, `head`, `wc`, `tee`, `date`, `mv`, `chmod`, `cp`, `rm`, `printf`, `comm`). Missing any required utility MUST cause immediate execution failure at bootstrap with exit code `15`.
* **Target Platforms:** Linux, macOS, BSD (FreeBSD, OpenBSD, NetBSD, DragonFly), WSL, Cygwin/MSYS/MinGW, Termux/Android.

#### Compatibility Contract
The following public interfaces SHALL remain unchanged across implementations:
1. **CLI Options & Arguments:** Existing CLI options, positional arguments, and flag semantics.
2. **Canonical Exit Codes:** `10` (No API Key), `11` (Bad Model), `12` (cURL Failed), `13` (Parse / Syntax Error), `14` (No Prompt), `15` (TMP/System Error), `16` (API Error), `17` (Security Violation).
3. **Output Formats:** `json`, `pretty`, `raw`, `text` output structure and conventions.
4. **Environment Variables:** All documented `BASH4LLM_*` and provider API key variables.
5. **Private Directory Layout:** Standard runtime directory structure under `BASH4LLM_DIR` (`config/`, `models/`, `templates/`, `history/`, `tmp/`, `var/run/`, `extras/`, `local-extras/`).

---

### 3. Security Invariants

The following security properties MUST hold at all times:

1. **[INV-1] No Internal Secret Exposure:** No secret (API key, bearer token, credentials) SHALL be observable through operating-system interfaces intended for process inspection (including, but not limited to, process argument vectors `argv`, environment inspection where applicable, and system logs).
2. **[INV-2] No Shared Temporary Storage:** Neither the Core nor any module SHALL write temporary files or directories to `/tmp` or any other shared system location. All temporary storage MUST reside within isolated runtime directories (`RUN_TMPDIR` / `BASH4LLM_TMPDIR`) with `0600` (files) / `0700` (directories) permissions.
3. **[INV-3] No Dynamic Code Evaluation:** Introduction of new dynamic evaluation constructs (`eval`) is STRICTLY PROHIBITED. Any pre-existing `eval` construct MUST be treated as technical debt and isolated. All module loading and hook outputs MUST use zero-eval whitelist parsing.
4. **[INV-4] Module Execution Integrity:** Execution or sourcing of untrusted, altered, or permission-compromised external modules MUST fail closed immediately with exit code `17`. Vendor domain modules MUST match their SHA-256 digest registered in `manifest.sha256` and pass Ed25519 manifest signature checks. Loading MUST occur via anti-TOCTOU staging copy isolation.
5. **[INV-5] Atomic State Persistence:** All persistent state modifications controlled by the Core MUST be atomic and consistent to prevent state corruption (utilizing file/directory locks and atomic write patterns).
6. **[INV-6] Function Immutability & Defensive Locks:** Core security, network, and atomic execution functions (`_exec_curl_secure`, `verify_module_integrity`, `validate_path_security`, `atomic_write`, `check_local_rate_limit`, `read_secure_input`, `enforce_network_policy`, `execute_isolated_hook`) MUST be locked as read-only (`readonly -f`) post-initialization to prevent function hijacking or runtime overriding.
7. **[INV-7] PII & Identifier Anonymization:** Thread identifiers MUST be cryptographically anonymized (`anonymize_thread_id`) via SHA-256/MD5 hashing prior to disk persistence to eliminate Personally Identifiable Information (PII) leakage.
8. **[INV-8] Encrypted Storage & Vault Policy:** Secret storage MUST support encrypted key management via OpenSSL (AES-256-CBC with PBKDF2). When mandatory vault policy (`BASH4LLM_REQUIRE_VAULT=1`) is enabled, non-vault key acquisition MUST be denied with exit code `17`.

---

### 4. Architecture & Design Principles

* **Single Authoritative Code Path:** Every security-sensitive, network, or persistence operation MUST have exactly one authoritative code path (`_exec_curl_secure` for HTTP, `verify_module_integrity` for code loading, `atomic_write` for persistence). Code duplication for critical tasks is prohibited.
* **Runtime Command Integrity:** Command resolution MUST be resilient against post-initialization environment tampering, including modifications to `PATH`, alias injection, or shell function hijacking.
* **Deterministic & Scintilla-Ready Extensions:** The architecture supports deterministic output validation, structure enforcement, and diagnostic reporting via CLI flags (`--validate-sml` for SML v2.0 validation, `--validate-regex` for POSIX ERE matching, `--sanitize` for ANSI zero-eval output filtering, and `--json-diagnostics` for machine-readable JSON error payloads).
* **Preserve Existing Semantics:** Observable program behaviour MUST remain unchanged, except where explicitly modified by this specification to satisfy security requirements.
* **Observable Behaviour Definition:** Observable behaviour includes CLI flags, stdout/stderr streams, exit codes, output payload schemas, documented environment variables, and persistence formats.

---

### 5. Threat Model & Trust Assumptions

#### Security Boundaries
* **In Scope:** Internal secret exposure via process inspection interfaces; command execution hijacking via PATH or function overriding; execution of tampered modules; TOCTOU file replacement attacks; uncleaned execution environment; insecure temporary file allocation; PII leakage in history metadata; unauthorized high-frequency requests (mitigated via sliding-window rate limiting).
* **Out of Scope:** Malicious local `root` user or co-privileged processes; RAM memory inspection / `ptrace` debugging; compromised kernel, libc, or `/bin/bash` binary; non-POSIX network filesystems lacking atomic lock semantics.

#### Trust Assumptions
* The host operating system correctly enforces POSIX file and directory permissions (`0600`/`0700`).
* The Bash interpreter behaves in accordance with the Bash 4.0+ specification.
* Core system utilities (`curl`, `jq`, `awk`) function correctly according to their documentation.

---

### 6. Definition of Done (DoD)

A release or implementation iteration SHALL be considered complete only when all the following conditions are met:

1. **[DOD-1] Regression Testing:** All regression test suites SHALL complete with zero failures.
2. **[DOD-2] Secret Exposure Verification:** Absence of internal secret leaks in process argument vectors MUST be demonstrated during synchronous and streaming operations.
3. **[DOD-3] File Isolation Verification:** Zero temporary files or directories SHALL be created in `/tmp` during execution.
4. **[DOD-4] Integrity Enforcement Verification:** Mismatch between an external module and its cryptographic manifest entry MUST cause an immediate execution halt with exit code `17`.
5. **[DOD-5] Static Analysis:** ShellCheck static analysis SHALL produce no new warnings compared to the baseline.
