[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)
[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)  

# Bash4LLM v2.7.0 — Release Notes

**Data / Date:** 2026‑07‑24  
**Stato / Status:** Stable – Automated Verification & Platform Optimization Release (Upgrade from v2.6.0)

## 💡 EVOLUZIONE ARCHITETTURALE / ARCHITECTURAL EVOLUTION

**🇮🇹 Suite di Test Unificata, Concorrenza Adattiva Multi-Piattaforma e Diagnostica Avanzata**  
La versione 2.7.0 introduce l'integrazione diretta della suite di test unificata via CLI, un motore di concorrenza adattivo capace di scalare i processi in base alla piattaforma per prevenire crash da OOM o Signal 9 (Termux, WSL, Cygwin, Linux, macOS), una diagnostica dettagliata dei fallimenti e un ripristino impeccabile della palette di colori ANSI ufficiali.

**🇬🇧 Unified Master Test Suite, Adaptive Cross-Platform Concurrency & Enhanced Diagnostics**  
Version 2.7.0 introduces direct CLI-level execution of the unified test suite, an adaptive concurrency engine that dynamically scales worker processes based on the target platform to prevent OOM / Signal 9 crashes (Termux/Android, WSL, Cygwin, Linux, macOS), detailed failure/skip diagnostics, and full ANSI color palette restoration.

---

## 🇮🇹 Sezione Italiana

### ✨ Novità principali
 * **Integrazione della Suite di Test Unificata (`--run-all-tests`)**: Nuovo comando CLI (con alias `--run-all-test`) per l'esecuzione automatizzata dell'intera suite a 8 moduli (27 test convalidati) previa verifica di integrità crittografica SHA-256 dello script `run-all-tests.sh`.
 * **Concorrenza Adattiva Multi-Piattaforma (`detect_safe_concurrency`)**: Calcolo dinamico del numero dei processi worker per il test di stress sui lock (Modulo 7). Limita automaticamente l'esecuzione a `10` worker su ambienti con forking pesante o risorse limitate (Termux/Android, Cygwin), `20` su WSL e fino a `50` su Linux/macOS multi-core. Supporta l'override manuale tramite `BASH4LLM_TEST_CONCURRENCY`.
 * **Report Diagnostico Dettagliato per Test Falliti o Saltati**: In caso di errori, la suite genera le sezioni dedicate `DETAILED FAILURE DIAGNOSTICS` e `SKIPPED TESTS DIAGNOSTICS`, mostrando i codici di uscita attesi/ricevuti, le motivazioni e i suggerimenti operativi di risoluzione.
 * **Cornice Visiva Finale Uniforme**: Introduzione del banner di chiusura `===` perfettamente coordinato all'intestazione per racchiudere l'output di test in una struttura visiva pulita.

### 🔐 Stabilità, Sicurezza e Permessi
 * **Prevenzione dei Crash `Signal 9 (SIGKILL)`**: Eliminato l'abbattimento del processo da parte del Phantom Process Killer di Android/Termux durante i test di concorrenza intensiva.
 * **Risoluzione Dinamica del Binario (`TARGET_BIN`)**: Corretto il caricamento del binario eseguibile per funzionare sia dalla cartella sorgente sia dalla collocazione installata canonica `bash4llm.d/extras/test/`.
 * **Hardening dei Permessi dell'Installer (`--install-extras`)**: Applicazione del principio del minimo privilegio in fase di installazione (cartelle `700`, file di dati `600`, binari ed entrypoint CLI `700`).

### 🎨 Interfaccia e Palette Cromatica
 * **Ripristino dei Colori ANSI (`init_colors`)**: Risolto il problema di azzeramento delle variabili cromatiche quando le funzioni core vengono caricate in memoria con output reindirizzato (`>/dev/null 2>&1`). La suite ora rispetta la palette **Bold** ufficiale di `Bash4LLM⁺` (`C_BGREEN`, `C_BRED`, `C_BYELLOW`, `C_BCYAN`).
 * **Inoltro Trasparente delle Flag di Contesto**: Invocando `--run-all-tests`, le opzioni `--no-color` e `--dry-run` vengono propagate automaticamente all'esecutore dei test.

---

## 🇬🇧 English Section

### ✨ Key Highlights
 * **Integrated Master Test Suite (`--run-all-tests`)**: New CLI flag (and alias `--run-all-test`) to execute the complete 8-module automated verification suite (27 validated tests) backed by pre-execution SHA-256 cryptographic integrity validation.
 * **Adaptive Cross-Platform Concurrency Engine (`detect_safe_concurrency`)**: Dynamic worker scaling for lock contention stress testing (Module 7). Automatically adjusts concurrency limits to `10` workers on constrained or heavy-fork platforms (Termux/Android, Cygwin), `20` on WSL, and up to `50` on multi-core Linux/macOS. Supports manual override via `BASH4LLM_TEST_CONCURRENCY`.
 * **Detailed Failure & Skipped Test Diagnostics**: On test failures or skips, the suite renders dedicated `DETAILED FAILURE DIAGNOSTICS` and `SKIPPED TESTS DIAGNOSTICS` sections featuring expected vs actual exit codes, skip reasons, and operational hints.
 * **Unified Enclosing Visual Banner**: Added a matching closing banner (`===`) to neatly frame the entire test execution report.

### 🔐 Stability, Security & Permission Hardening
 * **`Signal 9 (SIGKILL)` Crash Prevention**: Eliminates process termination triggered by Android/Termux Phantom Process Killer / OOM Killer during high-concurrency lock stress tests.
 * **Dynamic Target Binary Path Resolution (`TARGET_BIN`)**: Resolved target binary path lookup to work seamlessly both from repository source trees and canonical installed locations (`bash4llm.d/extras/test/`).
 * **Least-Privilege Extras Installer Hardening**: Enforces strict mode `700` for directories, `600` for data files, and `700` strictly for executable CLI entrypoints during `--install-extras`.

### 🎨 Terminal UI & Color Theme Alignment
 * **ANSI Color Theme Restoration (`init_colors`)**: Fixed an issue where sourcing core components with redirected output (`>/dev/null 2>&1`) cleared active color variables. Fully aligns test runner colors with the official `Bash4LLM⁺` bold palette (`C_BGREEN`, `C_BRED`, `C_BYELLOW`, `C_BCYAN`).
 * **Transparent Context Flag Forwarding**: Invoking `--run-all-tests` seamlessly forwards `--no-color` and `--dry-run` flags to the underlying test runner.

---

*This release notes document corresponds to release <a href='https://github.com/kamaludu/bash4llm/releases/tag/v2.7.0'>Bash4LLM v2.7.0</a>.*
