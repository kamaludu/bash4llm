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
* **Required System Utilities:** POSIX system utilities (`awk`, `sed`, `grep`, `find`, `mkdir`, `mv`, `rm`, `chmod`, `stat`, `date`, `tr`, `sort`, `head`, `wc`) plus `curl` and `jq` (or equivalent functional implementations on the target platform).
* **Target Platforms:** Linux, macOS, BSD, WSL, Cygwin, Termux/Android.

#### Compatibility Contract
The following public interfaces SHALL remain unchanged across implementations:
1. **CLI Options & Arguments:** Existing CLI options, positional arguments, and flag semantics.
2. **Canonical Exit Codes:** `10` (No API Key), `11` (Bad Model), `12` (cURL Failed), `14` (No Prompt), `15` (TMP/System Error), `16` (API Error), `17` (Security Violation).
3. **Output Formats:** `json`, `pretty`, `raw`, `text` output structure and conventions.
4. **Environment Variables:** All documented `BASH4LLM_*` and provider API key variables.
5. **Private Directory Layout:** Standard runtime directory structure under `BASH4LLM_DIR`.

---

### 3. Security Invariants

The following security properties MUST hold at all times:

1. **[INV-1] No Internal Secret Exposure:** No secret (API key, bearer token, credentials) SHALL be observable through operating-system interfaces intended for process inspection (including, but not limited to, process argument vectors `argv`, environment inspection where applicable, and system logs).
2. **[INV-2] No Shared Temporary Storage:** Neither the Core nor any module SHALL write temporary files or directories to `/tmp` or any other shared system location. All temporary storage MUST reside within isolated runtime directories with `0600` (files) / `0700` (directories) permissions.
3. **[INV-3] No Dynamic Code Evaluation:** Introduction of new dynamic evaluation constructs (`eval`) is STRICTLY PROHIBITED. Any pre-existing `eval` construct MUST be treated as technical debt and isolated.
4. **[INV-4] Module Execution Integrity:** Execution or sourcing of untrusted, altered, or permission-compromised external modules MUST fail closed immediately with exit code `17`.
5. **[INV-5] Atomic State Persistence:** All persistent state modifications controlled by the Core MUST be atomic and consistent to prevent state corruption.

---

### 4. Architecture & Design Principles

* **Single Authoritative Code Path:** Every security-sensitive, network, or persistence operation MUST have exactly one authoritative code path. Code duplication for critical tasks is prohibited.
* **Runtime Command Integrity:** Command resolution MUST be resilient against post-initialization environment tampering, including modifications to `PATH`, alias injection, or shell function hijacking.
* **Preserve Existing Semantics:** Observable program behaviour MUST remain unchanged, except where explicitly modified by this specification to satisfy security requirements.
* **Observable Behaviour Definition:** Observable behaviour includes CLI flags, stdout/stderr streams, exit codes, output payload schemas, documented environment variables, and persistence formats.

---

### 5. Threat Model & Trust Assumptions

#### Security Boundaries
* **In Scope:** Internal secret exposure via process inspection interfaces; command execution hijacking via PATH; execution of tampered modules; uncleaned execution environment; insecure temporary file allocation.
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
