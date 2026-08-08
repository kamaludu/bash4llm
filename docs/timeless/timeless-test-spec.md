<img width="64" height="64" alt="K" src="https://github.com/user-attachments/assets/a99ee2ca-9c1d-4bd4-8430-07f0bb0493f1" /> **Timeless Normatives**

## TEST ARCHITECTURE SPECIFICATION (Timeless Edition 2026.1)

**Status:** Standard / Definitive Test Architecture Specification  
**Scope:** Test Harness, Quality Assurance & Verification Ecosystem  
**Authority:** Supreme Source of Truth for Verification Methodology (Complements Architecture Specification Edition 2026.1)

---

### 1. Hierarchy of Testing Authority & Principles

In the event of any conflict or discrepancy within testing assets or test plans:
1. **Architecture Specification (Edition 2026.1)** holds absolute authority over system behavior.
2. **Test Architecture Specification (Edition 2026.1)** holds absolute authority over testing methodologies, test isolation, and verification compliance.
3. **Test Implementation Plans** MUST yield to this Specification and are valid only for their targeted codebase iteration.

#### Core Testing Principles
* **[TST-1] Absolute Workspace Isolation:** Test execution SHALL occur within a dedicated, isolated workspace. Tests SHALL NOT modify user configuration, home directories, or shared system locations (`/tmp`). All test artifacts MUST be cleaned up automatically upon completion via signal traps (`EXIT`, `INT`, `TERM`).
* **[TST-2] Idempotency:** Executing any test suite single or multiple times ($N$ consecutive runs) MUST produce identical results and leave zero residual state.
* **[TST-3] Offline & Deterministic Execution:** The test suite SHALL execute strictly offline without external network dependency. Network interactions MUST be stubbed or simulated natively via offline execution mechanisms (such as `--dry-run` or isolated local mocks).
* **[TST-4] Fail-Fast Dependency Verification:** Every test script MUST verify host requirements (`bash >= 4.0`, POSIX utilities, `jq`) before executing assertions, halting with a clear diagnostic if prerequisites are missing.
* **[TST-5] Black-Box & Observable Behavior Verification:** Functional tests SHALL verify externally observable behavior (exit codes, stdout/stderr streams, payload schemas, documented environment flags, and persistent file state) without relying on internal implementation mechanics.

---

### 2. Testing Taxonomy & Pyramid

The verification framework is structured into six discrete, single-responsibility testing levels categorized by execution duration and scope, complemented by specialized deterministic validation suites:

```text
               / \
              /   \     [Level 6] Stress Test (Long-Running / Resource-Intensive)
             /     \    [Level 5] Concurrency Test (Medium-Running / Parallel Verification)
            /       \   [Level 4] Hardening Test (Short-Running / Security Boundaries)
           /         \  [Level 3] Regression Test (Short-Running / End-to-End Functional)
          /           \ [Level 2] Compatibility Test (Fast / Public Contract Verification)
         /_____________\[Level 1] Sanity Test (Interactive / Immediate System Vitality)
```

1. **Level 1: Sanity Test (`sanity.sh`)**
   * **Scope & Duration:** Interactive / Fast. Rapid black-box system vitality check.
   * **Checks:** Host dependency availability, Core CLI bootstrap, help/version flag responses, provider discoverability, and valid configuration parsing.
2. **Level 2: Compatibility Test (`compatibility.sh`)**
   * **Scope & Duration:** Short-running. Verification of the public Compatibility Contract.
   * **Checks:** Canonical exit codes (`10`, `11`, `12`, `13`, `14`, `15`, `16`, `17`), CLI flag semantics, environment variable precedence, and output schemas (`json`, `pretty`, `raw`, `text`).
3. **Level 3: Regression Test (`regression.sh`)**
   * **Scope & Duration:** Short-running. End-to-end functional flow verification.
   * **Checks:** Prompt assembly, STDIN piping, file input processing, template variable expansion, thread history lifecycle (init/rename/delete), session context windowing (`session-engine.sh`), output sanitization (`--sanitize`), SML v2.0 validation (`--validate-sml`), and REGEX matching (`--validate-regex`).
4. **Level 4: Hardening Test (`hardening.sh`)**
   * **Scope & Duration:** Short-running. System security invariants and boundary enforcement.
   * **Checks:** Invariants `INV-1` through `INV-8`, PII thread anonymization (`anonymize_thread_id`), null-byte binary input rejection (`validate_file_input`), path traversal and command injection fuzzing, sliding-window rate limiting, function immutability guards (`readonly -f`), encrypted key storage operations (`openssl-helper.sh` Vault), anti-TOCTOU module staging, and Ed25519 manifest signature verification.
5. **Level 5: Concurrency Test (`concurrency.sh`)**
   * **Scope & Duration:** Medium-running. Multi-process synchronization correctness.
   * **Checks:** Parallel process lock contention (`flock` / directory locks), race condition immunity, and atomic append integrity on concurrent data streams.
6. **Level 6: Stress Test (`stress.sh`)**
   * **Scope & Duration:** Long-running / Resource-intensive. System scalability and resource boundary handling.
   * **Checks:** History retention rotation policies ($O(N)$ memory rotation), high-volume payload memory handling, and resource exhaustion resilience.
7. **Specialized Suite: SCINTILLA Core — T3 Test (`scintilla-t3.sh`)**
   * **Scope & Duration:** Target verification suite for Scintilla-Ready deterministic extensions.
   * **Checks:** Strict SML v2.0 EBNF compliance, POSIX REGEX matching, zero-eval ANSI filtering, and structured JSON error diagnostic output (`--json-diagnostics`).

---

### 3. Traceability & Coverage Matrix

This matrix maps System Architecture Invariants (`INV-1`..`INV-8`), the Compatibility Contract, and Definition of Done (`DOD-1`..`DOD-5`) directly to the verifying Test Levels.

*Legend: **[P]** = Primary Verification Target | **[I]** = Incidental / Secondary Coverage*

| Architectural Requirement / Invariant | Sanity | Compatibility | Regression | Hardening | Concurrency | Stress | Scintilla T3 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **[INV-1] No Secret Exposure (`argv`)** | — | — | — | **[P]** | — | — | — |
| **[INV-2] No Shared Temp Storage (`/tmp`)** | **[I]** | **[I]** | **[I]** | **[P]** | **[I]** | **[I]** | — |
| **[INV-3] No Dynamic Code Evaluation (`eval`)** | — | — | — | **[P]** | — | — | — |
| **[INV-4] Module Integrity Enforcement (Code 17)** | — | — | — | **[P]** | — | — | — |
| **[INV-5] Atomic State Persistence** | — | — | **[I]** | **[P]** | **[P]** | — | — |
| **[INV-6] Function Immutability Guards** | — | — | — | **[P]** | — | — | — |
| **[INV-7] PII Thread Anonymization** | — | — | **[I]** | **[P]** | — | — | — |
| **[INV-8] Encrypted Storage & Vault Policy** | — | — | — | **[P]** | — | — | — |
| **Compatibility: Exit Codes (`10`..`17`)** | — | **[P]** | — | — | — | — | — |
| **Compatibility: CLI Options & Flags** | **[I]** | **[P]** | **[I]** | — | — | — | — |
| **Compatibility: Output Schemas (`json`/`text`)** | — | **[P]** | **[I]** | — | — | — | — |
| **Compatibility: Environment Variables** | — | **[P]** | — | — | — | — | — |
| **Deterministic Extensions (SML/REGEX/ANSI)** | — | — | **[P]** | — | — | — | **[P]** |
| **[DOD-1] Regression Suite Zero Failures** | — | — | **[P]** | — | — | — | — |
| **[DOD-2] Secret Exposure Verification** | — | — | — | **[P]** | — | — | — |
| **[DOD-3] File Isolation Verification** | **[I]** | **[I]** | **[I]** | **[P]** | **[I]** | **[I]** | — |
| **[DOD-4] Integrity Enforcement (Exit 17)** | — | — | — | **[P]** | — | — | — |

*Threat Model Mapping Note:* Every Security Boundary defined in Section 5 of the Architecture Specification SHALL be covered by at least one Primary Verification Target in Level 4 (Hardening).

---

### 4. Orchestration & Execution Protocol

* **Unified Entrypoint:** `extras/test/run-all-tests.sh` acts as the master orchestrator, capable of executing either individual test levels independently or the full suite sequence:
  $$\text{Sanity} \rightarrow \text{Compatibility} \rightarrow \text{Regression} \rightarrow \text{Hardening} \rightarrow \text{Concurrency} \rightarrow \text{Stress}$$
* **Forwarded CLI Options:** The orchestrator forwards transparent context flags (such as `--no-color` and `--dry-run`) directly to child test scripts.
* **Fail-Fast Mode (`--fail-fast`):** When enabled, the orchestrator MUST halt immediately upon the first test failure in any level.
* **Granular Level Selection:** The orchestrator SHALL allow invoking any single test level script directly or via CLI aliases (`--test`, `--run-all-test`, `--run-all-tests`) without requiring full suite execution.
* **Cumulative Reporting:** In full suite execution mode, the orchestrator MUST complete all levels and output a structured diagnostic summary reporting Passed, Failed, and Skipped counts.
