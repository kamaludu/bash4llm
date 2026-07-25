[![Logo 320](docs/img/bash4llm320.png "Logo bash4llm")](README.md)

[![Latest Release](https://img.shields.io/github/v/release/kamaludu/bash4llm?style=flat&color=4EAA25&label=version&labelColor=2B2B2B&logo=gnu-bash&logoColor=white)](https://github.com/kamaludu/bash4llm/releases)  

# Bash4LLM v2.8.0 — Release Notes

**Data / Date:** 2026-07-25  
**Stato / Status:** Stable – Security Hardening & Zero Secret Exposure Release (Upgrade from v2.7.0)

## EVOLUZIONE ARCHITETTURALE / ARCHITECTURAL EVOLUTION

**🇮🇹 Mediazione di Rete Unificata, Redazione dei Segreti in `argv`, Guardie Read-Only e Integrità Fail-Closed**  
La versione 2.8.0 implementa le specifiche dell'**Architecture Specification (Edition 2026.1)**, introducendo la funzione centrale di mediazione di rete `_exec_curl_secure()` per l'azzeramento dell'esposizione dei segreti nella tabella dei processi del sistema operativo (`argv`), il blocco in memoria delle funzioni di sicurezza mediante `readonly -f` (`_lock_security_guards`), la bonifica delle variabili d'ambiente all'avvio, il controllo di integrità dei moduli strictly *fail-closed* ed il Modulo 9 di test avversari.

**🇬🇧 Centralized Network Mediation, Process Argument Secret Redaction, Read-Only Guards & Fail-Closed Integrity**  
Version 2.8.0 implements the requirements of the **Architecture Specification (Edition 2026.1)**, introducing the authoritative network execution engine `_exec_curl_secure()` to eliminate secret exposure in process argument vectors (`argv`), in-memory function locking via `readonly -f` (`_lock_security_guards`), bootstrap environment sanitization, strictly fail-closed module integrity verification, and Module 9 adversarial security test assertions.

---

## 🇮🇹 Sezione Italiana

### Novità principali e Hardening di Sicurezza
 * **Mediazione di Rete Unificata ed Eliminazione Secret Leak in `argv` (`_exec_curl_secure`)**: Tutte le chiamate HTTP (sincrone, streaming, refresh dei modelli e validazione delle chiavi) di tutti i provider (Groq, Gemini, Hugging Face, Mistral) sono convogliate nella funzione centrale `_exec_curl_secure()`. Le credenziali vengono scritte esclusivamente in file temporanei isolati (`0600`) e inoltrate a `curl` via File Descriptor (`/dev/fd/3`), azzerando l'esposizione delle chiavi API nei vettori d'argomento del processo (`argv` / `ps aux`).
 * **Guardie di Inizializzazione Read-Only (`_lock_security_guards`)**: Al termine della fase di bootstrap, le funzioni critiche di sicurezza, mediazione e gestione del filesystem vengono marcate come `readonly -f`, impedendone la ridefinizione o la cancellazione in memoria da parte di moduli esterni o sotto-shell.
 * **Bonifica dell'Ambiente di Esecuzione all'Avvio**: Rimozione automatica delle variabili d'ambiente a rischio (`unset BASH_ENV ENV CDPATH GLOBIGNORE`) nella sezione iniziale di boot del Core per prevenire hijacking dei percorsi o iniezioni di codice.
 * **Integrità Crittografica Moduli Fail-Closed**: Rigoroso blocco immediato con codice di uscita `17` (`BASH4LLM_ERR_SEC`) in caso di mancata corrispondenza dell'hash SHA-256 di un modulo opzionale rispetto a `extras/manifest.sha256` o qualora il calcolo dell'hash fallisca.

### Estensioni e Test Suite
 * **Estensione della Test Suite Master (Modulo 9)**: Aggiunta delle asserzioni di test avversarie per verificare automaticamente la protezione delle funzioni `readonly`, il blocco delle manomissioni dei moduli ed il corretto funzionamento di `_exec_curl_secure()`.
 * **Allineamento dei Provider Esterni (`gemini.sh`, `huggingface.sh`, `mistral.sh`)**: Migrazione completa di tutti i moduli provider opzionali sulla funzione centrale di rete `_exec_curl_secure()`. Per Gemini e Hugging Face, le chiavi API non vengono più trasmesse nei parametri URL (`?key=...`), eliminando la visibilità dei token negli argomenti di riga di comando.

---

## 🇬🇧 English Section

### Key Features & Security Hardening
 * **Authoritative Secure Network Path & `argv` Secret Redaction (`_exec_curl_secure`)**: All HTTP calls (synchronous, streaming, model-refresh, and key-validation) across all providers (Groq, Gemini, Hugging Face, Mistral) route strictly through `_exec_curl_secure()`. Authentication headers are written to private temporary files (`0600`) and forwarded to `curl` via File Descriptor redirection (`/dev/fd/3`), completely redacting Bearer tokens and API keys from process argument vectors (`argv` / `ps aux`).
 * **Read-Only Security Function Guards (`_lock_security_guards`)**: Post-bootstrap function locking marks critical security, mediation, and filesystem routines as `readonly -f` in shell memory to prevent function overriding or hijacking by external modules.
 * **Bootstrap Environment Sanitization**: Unsets high-risk environment variables (`unset BASH_ENV ENV CDPATH GLOBIGNORE`) during early Core initialization to prevent environment hijacking.
 * **Fail-Closed Cryptographic Module Integrity**: Enforces an immediate execution halt with exit code `17` (`BASH4LLM_ERR_SEC`) if an extension module's SHA-256 hash fails to match `extras/manifest.sha256` or if digest calculation fails.

### Extension Modules & Master Test Suite
 * **Master Test Suite Expansion (Module 9)**: Integrated adversarial security test assertions to automatically validate `readonly -f` function guards, module tamper detection, and secure `curl` execution.
 * **Secondary Provider Alignment (`gemini.sh`, `huggingface.sh`, `mistral.sh`)**: Refactored all external provider modules to route network requests through `_exec_curl_secure()`. API keys for Gemini and Hugging Face are no longer passed as URL query parameters (`?key=...`), keeping credentials fully hidden from process command lines.

---

*This release notes document corresponds to release <a href='https://github.com/kamaludu/bash4llm/releases/tag/v2.8.0'>Bash4LLM v2.8.0</a>.*
