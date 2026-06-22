[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# Bash4LLM v2.0.0 — Release Notes  
**Data / Date:** 2026‑06‑20  
**Stato / Status:** Stable – Major Release (Upgrade from GroqBash 1.0.0)

---

## ⚠️ NOTA IMPORTANTE SUL REBRANDING / IMPORTANT NOTICE ON REBRANDING
*GroqBash* cambia nome e diventa **Bash4LLM** (v2.0.0). 

**🇮🇹 Perché questo cambiamento?**
Questa transizione è stata decisa principalmente per evitare potenziali sovrapposizioni o future contestazioni legate ai marchi registrati (trademark) con i provider di servizi upstream, e per dare al progetto un'identità visiva ed estetica più definita. Fin dalle prime versioni, il software è stato progettato per supportare moduli e provider diversi oltre a Groq: il nome *Bash4LLM* descrive quindi in modo più accurato e neutrale la natura multi-LLM e "bash-first" dell'applicazione.

**🇬🇧 Why this change?**
This transition was primarily decided to prevent potential trademark conflicts or overlaps with upstream service providers, as well as to give the project a more distinct aesthetic identity. Since its early versions, the software was designed to support various modules and providers beyond Groq; the name *Bash4LLM* therefore more accurately and neutrally describes the multi-LLM and "bash-first" nature of the application.

---

## 🇮🇹 Sezione Italiana

### ✨ Novità principali
- **Rebranding completo**: Transizione da GroqBash a Bash4LLM, con riorganizzazione della directory di runtime principale in `bash4llm.d/`.
- **Session Engine MVP & Avanzato**: Introdotto il supporto nativo per la gestione delle sessioni di chat (NDJSON) con deduplicazione dei messaggi cross-processo e supporto per un modulo esterno estensibile (`session-engine.sh`).
- **Integrazione UI State**: Scrittura atomica e centralizzata dello stato di runtime (file JSON in `ui_state/`) per facilitare l'integrazione con interfacce grafiche esterne.
- **Isolamento dei Provider**: Meccanismo di caricamento sicuro dei moduli provider in subshell isolate per prevenire l'esecuzione accidentale o malevola di codice non autorizzato.
- **Sistema di Cache**: Supporto integrato per la memorizzazione temporanea delle risposte (session cache) con TTL configurabile.

### 🔐 Sicurezza e Robustezza
- **Prevenzione TOCTOU & Sanificazione percorsi**: Validazione rigorosa del perimetro di sicurezza di `BASH4LLM_TMPDIR` (con blocco esplicito dell'uso di `/tmp` non protetto).
- **Nuovo motore di Lock**: Introdotto `lock_exec` con fallback automatico per macOS (utilizzando directory atomiche in assenza di `flock` nativo di sistema).
- **Network Policy centralizzata**: Controllo rigoroso sulle chiamate di rete tramite regole globali per garantire che nessuna connessione avvenga durante simulazioni (`DRY_RUN`) o quando disabilitata esplicitamente.

### 🛠️ Miglioramenti tecnici
- **Risoluzione directory robusta**: Migliorato il rilevamento dinamico della cartella di installazione tramite link simbolici portabili.
- **Base64 Portabile**: Unificazione delle chiamate base64 tramite wrapper interni per evitare discrepanze tra GNU coreutils e sistemi BSD/macOS.
- **CLI potenziata**:
  - Flag `--install-extras` per specificare una sorgente personalizzata.
  - Opzioni `--list-providers-raw` e `--list-models-raw` per un parsing semplificato da parte di script esterni.
  - Flag `--bootstrap-only` per inizializzazioni strutturali rapide.
- **Codici di errore canonici**: Definizione di costanti per codici d'errore standardizzati per una gestione più pulita dei fallimenti.

---

## 🇬🇧 English Section

### ✨ Key Highlights
- **Complete Rebranding**: Transition from GroqBash to Bash4LLM, consolidating the main runtime assets into the new `bash4llm.d/` directory.
- **MVP & Advanced Session Engine**: Built-in support for chat sessions (using a compact NDJSON format) with cross-process message deduplication and compatibility with an external extensible module (`session-engine.sh`).
- **UI State Integration**: Centralized, atomic writing of runtime state variables (JSON files in `ui_state/`) to simplify integration with external graphical frontends.
- **Secure Provider Isolation**: Safe loading of external provider modules inside isolated subshells to prevent execution of unauthorized or malformed functions.
- **Session Caching**: Native support for caching response payloads with configurable Time-To-Live (TTL) to save API calls.

### 🔐 Security & Robustness
- **Strict Path Validation**: Hardened temporary directory logic by strictly blocking the use of `/tmp` (or its subpaths) to mitigate shared directory vulnerabilities.
- **Improved Locking Mechanism**: Enhanced `lock_exec` engine featuring automatic directory-based locking fallback to guarantee atomic execution on macOS/Darwin systems.
- **Centralized Network Policy**: Global validation layer to prevent any network activity during dry runs (`DRY_RUN`) or under explicit offline constraints.

### 🛠️ Technical Improvements
- **Robust Path Resolution**: Upgraded dynamic installation directory lookup, resolving symbolic links in a highly portable manner.
- **Portable Base64**: Internal encoders/decoders to seamlessly abstract differences between GNU and BSD/macOS implementations.
- **Expanded CLI**:
  - Added `--install-extras <source_dir>` to install extras from custom locations.
  - New machine-readable flags: `--list-providers-raw` and `--list-models-raw`.
  - Added `--bootstrap-only` for fast structural initializing.
- **Canonical Exit Codes**: Refactored error handling using centralized, standardized exit constants.

<hr /><em>This discussion was created from the release <a href='https://github.com/kamaludu/bash4llm/releases/tag/v2.0.0'>Bash4LLM v2.0.0</a>.</em>
