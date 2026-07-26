[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

# Master Test Suite Architecture (`extras/test/run-all-tests.sh`)

**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**

---

## 🇮🇹 Sezione Italiana

# Guida all'Architettura di Test e all'Orchestratore (`run-all-tests.sh`)

Lo script `extras/test/run-all-tests.sh` costituisce il **Master Orchestrator** della suite di test unificata di **Bash4LLM⁺**. Permette la validazione automatizzata, deterministica, isolata e sicura dell'intero runtime, garantendo il rispetto delle invarianti di architettura, la gestione dei lockfile e la piena conformità alle specifiche della **Test Architecture Specification (Edition 2026.1)**.

Tutti i test vengono eseguiti all'interno di una sandbox isolata su filesystem (`.test_tmp/`), applicando i permessi restrittivi POSIX `0700` senza mai contaminare la directory condivisa di sistema `/tmp` (**Principio `[TST-1]`**).

---

## Invocazione e Sintassi CLI da Core (`bash4llm`)

Il Core `bash4llm` agisce da **Gatekeeper di Sicurezza** e supporta gli alias abbreviati ed estesi per delegare l'esecuzione all'orchestratore:

```sh
# Invocazione della suite completa (dati di default)
./bash4llm --test
./bash4llm --run-all-test
./bash4llm --run-all-tests

# Visualizzazione della guida CLI e dell'elenco delle suite autorizzate
./bash4llm --test help
./bash4llm --test list

# Esecuzione con arresto immediato al primo errore (Fail-Fast)
./bash4llm --test all --fail-fast

# Esecuzione di una singola suite di livello
./bash4llm --test sanity
./bash4llm --test hardening

# Esecuzione di più suite specifiche in sequenza
./bash4llm --test sanity compatibility regression
```

---

## La Piramide di Verifica a 6 Livelli

L'architettura di test è strutturata in 6 livelli a responsabilità singola, organizzati per durata ed ambito di verifica:

```text
               / \
              /   \     [Livello 6] Stress Test (stress.sh)
             /     \    [Livello 5] Concurrency Test (concurrency.sh)
            /       \   [Livello 4] Hardening Test (hardening.sh)
           /         \  [Livello 3] Regression Test (regression.sh)
          /           \ [Livello 2] Compatibility Test (compatibility.sh)
         /_____________\[Livello 1] Sanity Test (sanity.sh)
```

### Livello 1: Sanity Test (`sanity.sh`)
* **Scope & Durata:** Interattivo / Rapido. Controllo immediato della vitalità del sistema.
* **Verifiche:** Disponibilità dipendenze host (Bash >= 4.0, POSIX, `jq`), bootstrap della CLI, flag `--version` e `--help`, discoverability dei provider installati e linter statico della configurazione (`--check-config`).

### Livello 2: Compatibility Test (`compatibility.sh`)
* **Scope & Durata:** Breve durata. Validazione del Contratto Pubblico di Compatibilità.
* **Verifiche:** Exit Code canonici (`10`, `11`, `12`, `14`, `15`, `16`, `17`), opzioni CLI, precedenza delle variabili d'ambiente, schemi di output (`json`, `pretty`, `raw`, `text`) e persistenza del modello predefinito.

### Livello 3: Regression Test (`regression.sh`)
* **Scope & Durata:** Breve durata. Verifica dei flussi funzionali End-to-End.
* **Verifiche:** Assemblaggio prompt da STDIN piped, elaborazione file d'input (`-f`), espansione dei modelli di template (`--template`), ciclo di vita dei thread di storico (init, rename, delete) e metadati `ui_state`.

### Livello 4: Hardening Test (`hardening.sh`)
* **Scope & Durata:** Breve durata. Invarianti di sicurezza e sbarramenti di confine.
* **Verifiche:**
  * **`[INV-1]`** Assenza di segreti in `argv` (`_exec_curl_secure`);
  * **`[INV-2]`** Isolamento workspace rispetto a `/tmp`;
  * **`[INV-3]`** Audit statico della guardia di valutazione del codice dinamico (`eval`);
  * **`[INV-4]`** Verifica di manomissione dei moduli via SHA-256 (Exit Code `17`);
  * **`[INV-5]`** Anonimizzazione crittografica PII degli ID thread su disco;
  * Filtro dei file binari con byte nulli (Exit Code `17`), mitigazione path traversal/command injection, rate limiter a finestra scorrevole, blocco immutabilità delle funzioni e cifratura/decifratura Key Vault OpenSSL.

### Livello 5: Concurrency Test (`concurrency.sh`)
* **Scope & Durata:** Media durata. Correttezza della sincronizzazione multiprocesso.
* **Verifiche:** Adattamento dinamico dei worker paralleli (in base ai core CPU o all'ambiente vincolato come Termux/WSL/Cygwin), contesa dei lock di file (`flock` / dir-lock) ed integrità dell'append atomico su stream NDJSON senza corruzione dei dati.

### Livello 6: Stress Test (`stress.sh`)
* **Scope & Durata:** Lunga durata / Intensivo. Scalabilità e limiti delle risorse.
* **Verifiche:** Gestione della memoria per lo staging di payload ad alto volume (Base64) e politiche di rotazione e ritenzione dello storico dei thread (`rotate_history`).

---

## Modello di Sicurezza: *Manifest-Authorized Test Discovery*

In conformità al principio **`[TST-7] No Implicit Test Execution`**, l'orchestratore non esegue mai script arbitrari trovati su disco tramite scansioni generiche (`find` o `*.sh`).

Un modulo di test viene eseguito **esclusivamente** se soddisfa il modello ad **Intersezione a 4 Livelli**:

$$\text{Esecuzione} = \text{Suite Canonica} \;\cap\; \text{File Esistente} \;\cap\; \text{Whitelist Manifest} \;\cap\; \text{Integrità SHA-256 Validata}$$

1. **Nome Canonico:** La suite deve appartenere al registro ufficiale (`sanity`, `compatibility`, `regression`, `hardening`, `concurrency`, `stress`).
2. **Esistenza Percorso:** Il file deve risiedere in `extras/test/<suite>.sh`.
3. **Whitelist Manifest:** La suite deve essere iscritta ufficialmente in `extras/manifest.sha256`.
4. **Validazione Crittografica:** L'hash SHA-256 attuale del file deve corrispondere esattamente a quello registrato.

---

## 🇬🇧 English Section

# Master Test Architecture & Orchestrator Guide (`run-all-tests.sh`)

The `extras/test/run-all-tests.sh` script serves as the **Master Test Suite Orchestrator** for **Bash4LLM⁺**. It delivers automated, deterministic, isolated, and secure verification of the core runtime, ensuring total compliance with system invariants, lock file handling, and the **Test Architecture Specification (Edition 2026.1)**.

All test suites execute within a strictly isolated filesystem sandbox (`.test_tmp/`), enforcing POSIX `0700` restrictive directory permissions without polluting system shared storage `/tmp` (**Principle `[TST-1]`**).

---

## Command Line Interface & Core Delegation (`bash4llm`)

The core executable `bash4llm` acts as a **Security Gatekeeper**, supporting both short and long flag aliases to delegate execution to the orchestrator:

```sh
# Execute full test suite sequence (default)
./bash4llm --test
./bash4llm --run-all-test
./bash4llm --run-all-tests

# Display test suite CLI help manual and list authorized suites
./bash4llm --test help
./bash4llm --test list

# Execute full suite with fail-fast mode enabled
./bash4llm --test all --fail-fast

# Execute a single specific test level
./bash4llm --test sanity
./bash4llm --test hardening

# Execute multiple specific test levels sequentially
./bash4llm --test sanity compatibility regression
```

---

## The 6-Level Verification Pyramid

The verification framework is structured into 6 discrete, single-responsibility testing levels categorized by execution duration and scope:

```text
               / \
              /   \     [Level 6] Stress Test (stress.sh)
             /     \    [Level 5] Concurrency Test (concurrency.sh)
            /       \   [Level 4] Hardening Test (hardening.sh)
           /         \  [Level 3] Regression Test (regression.sh)
          /           \ [Level 2] Compatibility Test (compatibility.sh)
         /_____________\[Level 1] Sanity Test (sanity.sh)
```

### Level 1: Sanity Test (`sanity.sh`)
* **Scope & Duration:** Interactive / Fast. Rapid black-box system vitality check.
* **Checks:** Host dependency verification (Bash >= 4.0, POSIX, `jq`), Core CLI bootstrap, `--version` and `--help` responses, provider discoverability, and static configuration linter (`--check-config`).

### Level 2: Compatibility Test (`compatibility.sh`)
* **Scope & Duration:** Short-running. Public Compatibility Contract verification.
* **Checks:** Canonical Exit Codes (`10`, `11`, `12`, `14`, `15`, `16`, `17`), CLI options, environment variable precedence, output format schemas (`json`, `pretty`, `raw`, `text`), and default model persistence.

### Level 3: Regression Test (`regression.sh`)
* **Scope & Duration:** Short-running. End-to-end functional flow verification.
* **Checks:** Piped STDIN prompt assembly, file input processing (`-f`), template variable expansion (`--template`), thread history lifecycle (init, rename, delete), and `ui_state` metadata writes.

### Level 4: Hardening Test (`hardening.sh`)
* **Scope & Duration:** Short-running. Security boundaries and system invariants.
* **Checks:**
  * **`[INV-1]`** No Secret Exposure in `argv` (`_exec_curl_secure`);
  * **`[INV-2]`** Absolute Workspace Isolation outside `/tmp`;
  * **`[INV-3]`** Dynamic Code Evaluation Guard static audit (`eval`);
  * **`[INV-4]`** Module Integrity Enforcement via SHA-256 (Exit Code `17`);
  * **`[INV-5]`** Cryptographic PII Thread Anonymization on disk;
  * Null-byte binary input filter (Exit Code `17`), path traversal and command injection fuzzing, sliding-window rate limiting, read-only function immutability locks, and OpenSSL Key Vault operations.

### Level 5: Concurrency Test (`concurrency.sh`)
* **Scope & Duration:** Medium-running. Multi-process synchronization correctness.
* **Checks:** Platform-adaptive parallel worker detection (scaling according to CPU cores or constrained environments like Termux/WSL/Cygwin), process lock contention (`flock` / dir-lock), and atomic append integrity on concurrent NDJSON data streams.

### Level 6: Stress Test (`stress.sh`)
* **Scope & Duration:** Long-running / Resource-intensive. System scalability and boundaries.
* **Checks:** High-volume base64 payload staging memory handling (`stage_b64`), thread history retention and rotation policies (`rotate_history`).

---

## Security Model: *Manifest-Authorized Test Discovery*

In compliance with **Principle `[TST-7] No Implicit Test Execution`**, the orchestrator never executes arbitrary scripts discovered on disk via un-filtered directory scans (`find` or `*.sh`).

A test module is executed **strictly** if it satisfies the **4-Level Set Intersection Model**:

$$\text{Execution} = \text{Canonical Suite} \;\cap\; \text{Physical File} \;\cap\; \text{Manifest Whitelist} \;\cap\; \text{Verified SHA-256 Hash}$$

1. **Canonical Name:** The suite must belong to the official registry (`sanity`, `compatibility`, `regression`, `hardening`, `concurrency`, `stress`).
2. **Physical Location:** The script file must reside at `extras/test/<suite>.sh`.
3. **Manifest Whitelist:** The suite must be explicitly registered in `extras/manifest.sha256`.
4. **Cryptographic Integrity:** The calculated SHA-256 digest of the script must strictly match the registered manifest hash.
