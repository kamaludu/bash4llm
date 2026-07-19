[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Bash4LLM v2.5.0 — Release Notes

**Data / Date:** 2026‑07‑18
**Stato / Status:** Stable – Feature & Hardening Release (Upgrade from v2.0.0)
## 💡 EVOLUZIONE ARCHITETTURALE / ARCHITECTURAL EVOLUTION
**🇮🇹 Un Framework Estensibile e Blindato**
La versione 2.5.0 segna il passaggio di **Bash4LLM** da un client lineare a un framework modulare altamente ottimizzato e sicuro. Questa release introduce un ecosistema di estensioni avanzate (extras/) per la gestione crittografica delle credenziali e l'ottimizzazione del contesto delle sessioni. È stato inoltre integrato il supporto nativo per ambienti mobile/Termux e una suite di diagnostica statica ad intercettazione precoce.
**🇬🇧 An Extensible & Hardened Framework**
Version 2.5.0 marks the evolution of **Bash4LLM** from a linear client into a highly optimized, production-hardened modular framework. This release introduces an advanced extensions ecosystem (extras/) providing at-rest credential encryption and context session optimization. It also brings out-of-the-box support for mobile/Termux environments and a suite of early-interception static diagnostics.
## 🇮🇹 Sezione Italiana
### ✨ Novità principali
 * **Estensione Security Vault (openssl-helper.sh)**: Gestione delle chiavi API cifrate a riposo (at-rest) tramite AES-256-CBC con derivazione PBKDF2 (100.000 iterazioni). Include un token di sessione volatile in memoria (_B4L_RT_CTX) e la distruzione fisica anti-forensic dei dati sensibili sul disco (shred/dd).
 * **Session Engine Avanzato (session-engine.sh)**: Ottimizzazione dei thread conversazionali tramite segmentazione automatica dei log NDJSON (limite 1MB) e compressione nativa gzip. Introduce la modalità "byte-budget" (N=0) per accumulare dinamicamente la cronologia fino a una soglia target in byte.
 * **Supporto Mobile & Termux Trasparente**: Rilevamento automatico dell'ambiente Android via TERMUX_VERSION con deviazione dinamica dei lock concorrenti su directory atomiche (mkdir), superando le instabilità del comando flock su kernel mobile.
 * **Gestione dei Manifesti**: Abilitato lo staging strutturato e transazionale di payload multimediali complessi tramite accoppiamento di metadati JSON e file specchio in Base64 (.b64).
### 🔐 Sicurezza e Controllo del File-System
 * **Hardening del Plugin Loader**: Il caricamento dei moduli esterni (load_provider_module) applica controlli bloccanti contro attacchi di privilege escalation: rifiuto di symlink, blocco di file group/world-writable e doppia verifica di integrità crittografica via hash SHA-256 prima e dopo il sourcing.
 * **Invariante di Scrittura Atomica**: Vincolata la creazione dei file temporanei all'interno dello stesso inode/partizione fisica del file di destinazione finale, garantendo che lo spostamento (mv) sia un'operazione atomica a livello di sistema operativo.
 * **Nuovo Codice di Errore**: Introdotta la costante canonica BASH4LLM_ERR_SEC (Valore 17) per isolare in modo specifico le violazioni delle policy del filesystem e le anomalie di sicurezza.
### 🛠️ Ottimizzazioni tecniche e Diagnostica
 * **Cache Associativa dei Modelli (BASH4LLM_MODEL_CACHE)**: Normalizzazione dei nomi dei modelli gestita interamente in-process tramite array associativi, eliminando i costosi fork di sotto-shell e abbattendo la latenza interna.
 * **Parser Statico "Zero-Eval"**: Estrazione della documentazione e delle costanti da core-notes.sh affidata a un parser POSIX awk isolato, escludendo rischi di iniezione di codice.
 * **CLI Diagnostica Anticipata**:
   * Flag --check-config per eseguire il linter statico delle chiavi e dei permessi delle directory.
   * Flag --explain-error per decodificare istantaneamente i codici di errore e visualizzare le relative note di mitigazione.
## 🇬🇧 English Section
### ✨ Key Highlights
 * **Security Vault Extension (openssl-helper.sh)**: Hardened at-rest encryption for API credentials using AES-256-CBC and PBKDF2 (100,000 iterations). Features an in-memory volatile session token (_B4L_RT_CTX) and anti-forensic secure data erasure (shred/dd).
 * **Advanced Session Engine (session-engine.sh)**: Conversational history optimization via automatic NDJSON log rotation (1MB threshold) and native gzip compression. Introduces a dynamic "byte-budget" window mode (N=0) to accumulate messages up to a specific byte target.
 * **Seamless Mobile & Termux Support**: Automatic Android runtime detection (via TERMUX_VERSION) featuring a transparent fallback from flock to atomic directory-based locks (mkdir), bypassing mobile kernel limitations.
 * **Multimedia Manifest Staging**: Transactional staging for rich payloads using structured JSON metadata mirrors backed by temporary Base64 (.b64) streams.
### 🔐 Security & File-System Hardening
 * **Strict Plugin Loader Verification**: External provider modules (load_provider_module) undergo strict multi-layered checks to mitigate privilege escalation: symbolic links are blocked, group/world-writable files are rejected, and mandatory pre/post-sourcing SHA-256 integrity signatures are verified.
 * **Enforced Write Atomicity**: Temporary staging files are strictly confined to the same physical partition/inode as their final destination, ensuring that the final file swap (mv) translates into an atomic kernel system call.
 * **New Canonical Exit Code**: Dedicated BASH4LLM_ERR_SEC constant (Value 17) to isolate and report file-system policy violations and security errors.
### 🛠️ Technical Optimizations & Diagnostics
 * **In-Process Model Name Caching (BASH4LLM_MODEL_CACHE)**: Model name normalization is now fully managed within the shell memory via associative arrays, wiping out subshell fork overhead and decreasing internal latency.
 * **Zero-Eval Static Parser**: Documentation and system constants are extracted from core-notes.sh using a pure POSIX awk stream, completely preventing code execution vectors.
 * **Early-Interception CLI Tools**:
   * Added --check-config to run an immediate static linting process over keys and runtime folder permissions.
   * Added --explain-error to instantly parse exit status codes and output mitigation strategies.
<em>This discussion was created from the release <a href='[https://github.com/kamaludu/bash4llm/releases/tag/v2.5.0](https://github.com/kamaludu/bash4llm/releases/tag/v2.5.0)'>Bash4LLM v2.5.0</a>.</em>
