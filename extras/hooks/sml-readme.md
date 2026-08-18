# Structured Metadata Layout (SML v2.0)
## [🇮🇹](#-sezione-italiana) [🇬🇧](#-english-section)

**[🇮🇹 Italiano](#-sezione-italiana) / [🇬🇧 English](#-english-section)**

```text
                       +---------------------------------------+
                       |             USER INVOCATION           |
                       | CLI: ./bash4llm -t sml --validate-sml |
                       | GUI: [x] Validate SML + sml.txt       |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |       CORE: assemble_content()        |
                       |    Injects extras/templates/sml.txt   |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |     CORE: build_payload_from_vars()   |
                       |   Compiles JSON payload ($PAYLOAD)    |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |           LLM API INFERENCE           |
                       |    (Groq, Gemini, Mistral, etc.)      |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |     CORE: perform_request_once()      |
                       |  Extracts text ($RESP -> $text)       |
                       +---------------------------------------+
                                           |
                                           v
                   +-----------------------------------------------+
                   |        CORE: validate_response_syntax()       |
                   +-----------------------------------------------+
                          |                                 |
                [FAIL]    |                       [PASS]    |
                          v                                 v
       +------------------------------------+  +-------------------------+
       | * log_error "SYNTAX_VAL"           |  | execute_isolated_hook   |
       | * emit_json_diagnostics (code 13)  |  | "post" "hook" "SUCCESS" |
       | * release_thread_lock              |  +-------------------------+
       | * exit 13 (BASH4LLM_ERR_PARSE)     |               |
       +------------------------------------+               v
                                              +--------------------------+
                                              | extras/hooks/sml-gate.sh |
                                              | * Strip ``` fences (AWK) |
                                              | * Anchored POSIX ERE     |
                                              | * Emit b64 payload       |
                                              +--------------------------+
                                                            |
                                                            v
                                              +--------------------------+
                                              | CORE: finalize_and_      |
                                              |        output()          |
                                              | (Stdout / GUI / NDJSON)  |
                                              +--------------------------+                                +--------------------------+
```

## Architettura, Core Engine & Specifica del Safety Gate
## Sezione italiana 🇮🇹

## 🇮🇹 Sezione Italiana

## 1. Panoramica del Sistema & Flusso Topologico

Il sottosistema **Structured Metadata Layout (SML v2.0)** in **Bash4LLM⁺ (v2.8.5.3+)** è una pipeline end-to-end di validazione semantica, sanitizzazione e sagomatura dell'output (output-shaping). Si estende su tre livelli architetturali:

1. **Core Layer (`bash4llm`):** Fornisce flag di runtime (`--validate-sml`), variabili di stato globali, validazione della sintassi fail-closed (`validate_response_syntax`), mappatura degli errori (`SYNTAX_VAL` / codice `13`) e l'esecutore isolato degli hook (`execute_isolated_hook`).
2. **Template Layer (`extras/templates/sml.txt`):** Esegue il condizionamento a monte del prompt utilizzando la macro `{{CONTENT}}` per istruire l'LLM sull'esatto layout a 5 header.
3. **Boundary Hook Layer (`extras/hooks/sml-gate.sh`):** Opera all'interno di una subshell sandboxata come T2 Boundary Integration Hook, rimuovendo i fence Markdown esterni, verificando espressioni regolari POSIX ancorate ed emettendo payload trasformati in Base64 (`TRANSFORMED_PAYLOAD`).

---

## 2. Implementazione Core in `bash4llm`

Lo script core `bash4llm` integra nativamente la validazione SML e la gestione dello stato attraverso variabili dedicate, costanti di errore, opzioni CLI e fasi di esecuzione della pipeline.

### 2.1 Variabili Globali & Costanti
Definite in `SECTION: PRECORE_BOOT_SETUP_SHELL`:

* `VALIDATE_SML` *(Integer, Default: `0`)*: Toggle principale per la validazione sintattica SML v2.0. Impostato a `1` quando viene passato `--validate-sml`.
* `VALIDATE_REGEX` *(String, Default: `""`)*: Pattern POSIX Extended Regular Expression (ERE) passato tramite `--validate-regex`. Valutato concorrentemente con la validazione SML.
* `BASH4LLM_ERR_PARSE` *(Integer, Constant: `13`)*: Codice di uscita POSIX canonico per violazioni di sintassi e parser (`BASH4LLMERR_PARSE=13`).

### 2.2 Gatekeeper di Parsing CLI
Analizzati in `SECTION: CORE_SETUP_CLI_PARSE`:

```bash
--validate-sml)
  VALIDATE_SML=1
  shift
  ;;
--validate-regex)
  check_required_arg "--validate-regex" "$#"
  VALIDATE_REGEX="$2"
  shift 2
  ;;
--json-diagnostics)
  JSON_DIAGNOSTICS=1
  shift
  ;;
```

### 2.3 Funzione di Validazione della Sintassi: `validate_response_syntax()`
Posizionata in `SECTION: CORE_SETUP_API_CALL`

### 2.4 Ciclo di Vita di Esecuzione Autorevole in `perform_request_once()`
In `SECTION: CORE_SETUP_API_CALL`, la validazione SML è collocata in un checkpoint autorevole:

1. **Estrazione del Testo:** `text="$(extract_text_from_resp 2>/dev/null || true)"` estrae il testo pulito da `$RESP`. Se in esecuzione sotto `--dry-run`, ricade su `$CONTENT`.
2. **Controllo Gatekeeper Fail-Closed:**
   ```bash
   if ! validate_response_syntax "$text"; then
     log_error "SYNTAX_VAL" "Response failed syntax validation."
     release_thread_lock
     exit "${BASH4LLM_ERR_PARSE:-13}"
   fi
   ```
   *Nota:* Eseguito **prima** dell'uscita anticipata di `--dry-run`, consentendo il test offline della validazione della sintassi senza connessioni di rete attive.
3. **Invocazione dell'Hook & Isolamento in Subshell:**
   ```bash
   execute_isolated_hook "post" "hook" "SUCCESS" "$rc" "${http_code_fallback:-200}"
   ```
4. **Sostituzione del Payload Zero-Eval:**
   Se `TRANSFORMED_PAYLOAD` viene emesso da `sml-gate.sh`, il core decodifica lo stream Base64 e sovrascrive `$text` prima di inviarlo a `finalize_and_output`.

### 2.5 Parser della Whitelist di Sicurezza in `execute_isolated_hook()`
In `SECTION: PRECORE_RUN_UTIL_HELPERS`, l'esecutore dell'hook rimuove le chiavi API dall'ambiente (`compgen -v | grep -E '(_API_KEY|_TOKEN)'`) e importa esclusivamente variabili strettamente autorizzate in whitelist tramite suddivisione di stringhe POSIX (Zero-Eval):

```bash
case "$key" in
  TRANSFORMED_PAYLOAD)
    if [[ "$val" =~ ^[a-zA-Z0-9+/=]+$ ]]; then
      export TRANSFORMED_PAYLOAD="$val"
    fi
    ;;
  FALLBACK_PAYLOAD)
    if [[ "$val" =~ ^[a-zA-Z0-9+/=]+$ ]]; then
      export FALLBACK_PAYLOAD="$val"
    fi
    ;;
esac
```

---

## 3. Specifica Formale SML v2.0

### 3.1 Contratto degli Header Obbligatori
Tutti i **5 header obbligatori** devono essere presenti nel testo della risposta:

| Identificatore Header | Regola | Descrizione |
| :--- | :--- | :--- |
| `SML_VERSION: 2.0` | **Mandatory** | Dichiara la conformità alla versione 2.0. Deve essere letterale `2.0`. |
| `LISTEN_SUMMARY:` | **Mandatory** | Sintesi di ascolto attivo (1–2 frasi che riassumono l'intento dell'utente). |
| `CONVERSATION_OUTCOME:` | **Mandatory** | Payload primario della risposta (spiegazione dettagliata, codice, soluzione). |
| `PROPOSED_TRANSITION:` | **Mandatory** | Passaggio operativo successivo, proposta di follow-up o chiusura conversazionale. |
| `EVIDENCE_TYPE:` | **Mandatory** | Token della categoria epistemica (vedere i valori enum consentiti di seguito). |

### 3.2 Valori Enum Consentiti per `EVIDENCE_TYPE`
Il valore di `EVIDENCE_TYPE:` deve corrispondere rigorosamente a uno dei seguenti token:
* `FACTUAL`: Conoscenza oggettivamente verificata, citazioni della documentazione.
* `ANALYTICAL`: Ragionamento comparativo, valutazione dell'architettura, analisi tecnica.
* `PROCEDURAL`: Istruzioni passo-passo, implementazioni di codice, guide eseguibili.
* `CONVERSATIONAL`: Chiarimenti diretti, risposte informali, dialogo.
* `SYNTHETIC`: Ipotesi teoriche, simulazioni, generazione creativa.

### 3.3 Grammatica EBNF Formale
```ebnf
SML_Document       ::= Header_Version WS
                       Header_Listen WS
                       Header_Outcome WS
                       Header_Transition WS
                       Header_Evidence ;

Header_Version     ::= "SML_VERSION:" [ \t]* "2.0" ;
Header_Listen      ::= "LISTEN_SUMMARY:" [ \t]* Text_Block ;
Header_Outcome     ::= "CONVERSATION_OUTCOME:" [ \t]* Text_Block ;
Header_Transition  ::= "PROPOSED_TRANSITION:" [ \t]* Text_Block ;
Header_Evidence    ::= "EVIDENCE_TYPE:" [ \t]* ("FACTUAL" | "ANALYTICAL" | "PROCEDURAL" | "CONVERSATIONAL" | "SYNTHETIC") ;

Text_Block         ::= [^\r\n]+ (NL [^\r\n]+)* ;
WS                 ::= [ \t\r\n]+ ;
NL                 ::= "\n" | "\r\n" ;
```

---

## 4. Moduli del Sottosistema Extras

### 4.1 Template di Input: `extras/templates/sml.txt`
* **Percorso del File:** `extras/templates/sml.txt`
* **Permessi:** `0600` (Lettura/Scrittura solo proprietario)
* **Macro:** Utilizza `{{CONTENT}}` per l'iniezione dinamica del prompt dell'utente.

```text
[SYSTEM INSTRUCTION: STRICT STRUCTURED METADATA LAYOUT (SML v2.0) ENFORCEMENT]
You are an AI assistant required to structure your entire response using the Structured Metadata Layout (SML v2.0) specification.

STRICT OUTPUT RULES:
1. Do NOT wrap your output in Markdown code blocks (no ``` or ```sml).
2. Output plain text starting immediately with the header 'SML_VERSION: 2.0'.
3. You MUST provide all five mandatory sections using the exact uppercase keys below.

SKELETON TEMPLATE:
SML_VERSION: 2.0
LISTEN_SUMMARY: <Concise, 1-2 sentence synthesis of your understanding of the user request and intent>
CONVERSATION_OUTCOME: <The comprehensive, direct, and detailed answer or solution to the user prompt>
PROPOSED_TRANSITION: <Next logical step, actionable follow-up, or clean conversational closure>
EVIDENCE_TYPE: <One of: FACTUAL | ANALYTICAL | PROCEDURAL | CONVERSATIONAL | SYNTHETIC>

---
USER REQUEST:
{{CONTENT}}
```

---

### 4.2 Hook Sandboxato: `extras/hooks/sml-gate.sh`
* **Percorso del File:** `extras/hooks/sml-gate.sh`
* **Categoria Target:** T2 Boundary Integration Hook
* **Funzioni dell'Hook:**
  * `pre_execution_hook()`: Pass-through (restituisce 0).
  * `post_execution_hook()`: Valida gli header, rimuove i fence markdown che racchiudono l'output tramite `awk` ed emette `TRANSFORMED_PAYLOAD`.

---

## 5. Integrazione GUI WebApp (`gui-py`)

Nell'adattatore WebApp Python (`extras/gui-py/main.py` e `ipc.py`):

1. **Rilevamento Template:** `GET /api/templates` elenca tutti i file `.txt` in `BASH4LLM_TEMPLATES_DIR`. `sml.txt` appare automaticamente nel menu a discesa.
2. **Dispacciamento del Sottoprocesso (`ipc.py`):**
   ```python
   if job.template:
       cmd.extend(["--template", job.template])
   if job.validate_sml:
       cmd.append("--validate-sml")
   ```
3. **Diagnostica Senza Deadlock:** Se la validazione fallisce, il core emette la diagnostica JSON su `stderr` (`{"bash4llm_status":"ERROR","code":13,"reason":"SYNTAX_VAL",...}`), che `ipc.py` cattura senza andare in crash e trasmette tramite Server-Sent Events (SSE).

---

## 6. Suite di Verifica & Test Automatizzati

### 6.1 Suite Scintilla Core T3 (`extras/test/scintilla-t3.sh`)
La suite di test valida il comportamento di rifiuto SML del core:

```bash
# Test 1: SML Validation Reject Check
INVALID_OUT=$(echo "Hello world" | bash "$BASH4LLM_BIN" -m "$TEST_MODEL" --validate-sml --dry-run 2>&1 || true)
if echo "$INVALID_OUT" | grep -qE "SYNTAX_VAL|13|14"; then
  printf "PASSED\n"
fi
```

### 6.2 Scenari di Verifica Manuale da CLI

#### Scenario A: Inferenza SML Conforme
```bash
./bash4llm -t sml "Analyze the benefits of immutable infrastructure" --validate-sml
```

#### Scenario B: Testo Non Conforme (Atteso Codice di Uscita 13)
```bash
printf "Unstructured plain text" | ./bash4llm --validate-sml --dry-run
echo "Exit status: $?" # Output: 13
```

#### Scenario C: Diagnostica di Errore JSON Strutturata
```bash
printf "Hello world" | ./bash4llm --validate-sml --json-diagnostics --dry-run
```
*Output su `stderr`:*
```json
{"bash4llm_status":"ERROR","code":13,"reason":"SYNTAX_VAL","message":"Response failed syntax validation.","timestamp":"2026-08-18T19:54:00Z"}
```

---

## 7. Registrazione Crittografica del Manifest

Ogni volta che `extras/hooks/sml-gate.sh` o `extras/templates/sml.txt` viene aggiornato, rigenerare il manifest firmato:

```bash
# 1. Update SHA-256 digests and Ed25519 signature
./extras/security/generate-manifest.sh

# 2. Verify all extra modules
./bash4llm --install-extras
```

---

## Architecture, Core Engine & Safety Gate Specification
## 🇬🇧

## 1. System Overview & Topological Flow

The **Structured Metadata Layout (SML v2.0)** subsystem in **Bash4LLM⁺ (v2.8.5.3+)** is an end-to-end semantic validation, sanitization, and output-shaping pipeline. It spans across three architectural layers:

1. **Core Layer (`bash4llm`):** Provides runtime flags (`--validate-sml`), global state variables, fail-closed syntax validation (`validate_response_syntax`), error mapping (`SYNTAX_VAL` / code `13`), and the isolated hook executor (`execute_isolated_hook`).
2. **Template Layer (`extras/templates/sml.txt`):** Performs upstream prompt conditioning using the `{{CONTENT}}` macro to instruct the LLM on the exact 5-header layout.
3. **Boundary Hook Layer (`extras/hooks/sml-gate.sh`):** Operates inside a sandboxed subshell as a T2 Boundary Integration Hook, stripping outer Markdown fences, verifying anchored POSIX regular expressions, and emitting Base64-transformed payloads (`TRANSFORMED_PAYLOAD`).

---

## 2. Core Implementation in `bash4llm`

The core script `bash4llm` natively integrates SML validation and state management through dedicated variables, error constants, CLI options, and pipeline execution stages.

### 2.1 Global Variables & Constants
Defined in `SECTION: PRECORE_BOOT_SETUP_SHELL`:

* `VALIDATE_SML` *(Integer, Default: `0`)*: Master toggle for SML v2.0 syntactic validation. Set to `1` when `--validate-sml` is passed.
* `VALIDATE_REGEX` *(String, Default: `""`)*: POSIX Extended Regular Expression (ERE) pattern passed via `--validate-regex`. Evaluated concurrently with SML validation.
* `BASH4LLM_ERR_PARSE` *(Integer, Constant: `13`)*: Canonical POSIX exit code for syntax and parser violations (`BASH4LLMERR_PARSE=13`).

### 2.2 CLI Parsing Gatekeepers
Parsed in `SECTION: CORE_SETUP_CLI_PARSE`:

```bash
--validate-sml)
  VALIDATE_SML=1
  shift
  ;;
--validate-regex)
  check_required_arg "--validate-regex" "$#"
  VALIDATE_REGEX="$2"
  shift 2
  ;;
--json-diagnostics)
  JSON_DIAGNOSTICS=1
  shift
  ;;
```

### 2.3 Syntax Validation Function: `validate_response_syntax()`
Located in `SECTION: CORE_SETUP_API_CALL`

### 2.4 Authoritative Execution Lifecycle in `perform_request_once()`
In `SECTION: CORE_SETUP_API_CALL`, SML validation is placed at an authoritative checkpoint:

1. **Text Extraction:** `text="$(extract_text_from_resp 2>/dev/null || true)"` extracts clean text from `$RESP`. If running under `--dry-run`, it falls back to `$CONTENT`.
2. **Fail-Closed Gatekeeper Check:**
   ```bash
   if ! validate_response_syntax "$text"; then
     log_error "SYNTAX_VAL" "Response failed syntax validation."
     release_thread_lock
     exit "${BASH4LLM_ERR_PARSE:-13}"
   fi
   ```
   *Note:* Executed **before** `--dry-run` early exit, allowing offline syntax validation testing without active network connections.
3. **Hook Invocation & Subshell Isolation:**
   ```bash
   execute_isolated_hook "post" "hook" "SUCCESS" "$rc" "${http_code_fallback:-200}"
   ```
4. **Zero-Eval Payload Replacement:**
   If `TRANSFORMED_PAYLOAD` is emitted by `sml-gate.sh`, the core decodes the Base64 stream and overrides `$text` before sending it to `finalize_and_output`.

### 2.5 Security Whitelist Parser in `execute_isolated_hook()`
In `SECTION: PRECORE_RUN_UTIL_HELPERS`, the hook runner strips environment API keys (`compgen -v | grep -E '(_API_KEY|_TOKEN)'`) and only imports strictly whitelisted variables via POSIX string splitting (Zero-Eval):

```bash
case "$key" in
  TRANSFORMED_PAYLOAD)
    if [[ "$val" =~ ^[a-zA-Z0-9+/=]+$ ]]; then
      export TRANSFORMED_PAYLOAD="$val"
    fi
    ;;
  FALLBACK_PAYLOAD)
    if [[ "$val" =~ ^[a-zA-Z0-9+/=]+$ ]]; then
      export FALLBACK_PAYLOAD="$val"
    fi
    ;;
esac
```

---

## 3. SML v2.0 Formal Specification

### 3.1 Mandatory Headers Contract
All **5 mandatory headers** must be present in the response text:

| Header Identifier | Rule | Description |
| :--- | :--- | :--- |
| `SML_VERSION: 2.0` | **Mandatory** | Declares compliance with version 2.0. Must be literal `2.0`. |
| `LISTEN_SUMMARY:` | **Mandatory** | Active listening synthesis (1–2 sentences summarizing user intent). |
| `CONVERSATION_OUTCOME:` | **Mandatory** | Primary response payload (detailed explanation, code, solution). |
| `PROPOSED_TRANSITION:` | **Mandatory** | Operational next step, follow-up proposal, or conversational exit. |
| `EVIDENCE_TYPE:` | **Mandatory** | Epistemic category token (see allowed enum values below). |

### 3.2 Allowed `EVIDENCE_TYPE` Enum Values
The value of `EVIDENCE_TYPE:` must strictly match one of the following tokens:
* `FACTUAL`: Objectively verified knowledge, documentation citations.
* `ANALYTICAL`: Comparative reasoning, architecture evaluation, technical analysis.
* `PROCEDURAL`: Step-by-step instructions, code implementations, executable guides.
* `CONVERSATIONAL`: Direct clarifications, informal responses, dialogue.
* `SYNTHETIC`: Theoretical hypotheses, simulations, creative generation.

### 3.3 Formal EBNF Grammar
```ebnf
SML_Document       ::= Header_Version WS
                       Header_Listen WS
                       Header_Outcome WS
                       Header_Transition WS
                       Header_Evidence ;

Header_Version     ::= "SML_VERSION:" [ \t]* "2.0" ;
Header_Listen      ::= "LISTEN_SUMMARY:" [ \t]* Text_Block ;
Header_Outcome     ::= "CONVERSATION_OUTCOME:" [ \t]* Text_Block ;
Header_Transition  ::= "PROPOSED_TRANSITION:" [ \t]* Text_Block ;
Header_Evidence    ::= "EVIDENCE_TYPE:" [ \t]* ("FACTUAL" | "ANALYTICAL" | "PROCEDURAL" | "CONVERSATIONAL" | "SYNTHETIC") ;

Text_Block         ::= [^\r\n]+ (NL [^\r\n]+)* ;
WS                 ::= [ \t\r\n]+ ;
NL                 ::= "\n" | "\r\n" ;
```

---

## 4. Extras Subsystem Modules

### 4.1 Input Template: `extras/templates/sml.txt`
* **File Path:** `extras/templates/sml.txt`
* **Permissions:** `0600` (Read/Write owner only)
* **Macro:** Uses `{{CONTENT}}` for dynamic user prompt injection.

```text
[SYSTEM INSTRUCTION: STRICT STRUCTURED METADATA LAYOUT (SML v2.0) ENFORCEMENT]
You are an AI assistant required to structure your entire response using the Structured Metadata Layout (SML v2.0) specification.

STRICT OUTPUT RULES:
1. Do NOT wrap your output in Markdown code blocks (no ``` or ```sml).
2. Output plain text starting immediately with the header 'SML_VERSION: 2.0'.
3. You MUST provide all five mandatory sections using the exact uppercase keys below.

SKELETON TEMPLATE:
SML_VERSION: 2.0
LISTEN_SUMMARY: <Concise, 1-2 sentence synthesis of your understanding of the user request and intent>
CONVERSATION_OUTCOME: <The comprehensive, direct, and detailed answer or solution to the user prompt>
PROPOSED_TRANSITION: <Next logical step, actionable follow-up, or clean conversational closure>
EVIDENCE_TYPE: <One of: FACTUAL | ANALYTICAL | PROCEDURAL | CONVERSATIONAL | SYNTHETIC>

---
USER REQUEST:
{{CONTENT}}
```

---

### 4.2 Sandboxed Hook: `extras/hooks/sml-gate.sh`
* **File Path:** `extras/hooks/sml-gate.sh`
* **Target Category:** T2 Boundary Integration Hook
* **Hook Functions:**
  * `pre_execution_hook()`: Pass-through (returns 0).
  * `post_execution_hook()`: Validates headers, strips enclosing markdown fences via `awk`, and emits `TRANSFORMED_PAYLOAD`.

---

## 5. WebApp GUI Integration (`gui-py`)

In the Python WebApp adapter (`extras/gui-py/main.py` and `ipc.py`):

1. **Template Discovery:** `GET /api/templates` lists all `.txt` files in `BASH4LLM_TEMPLATES_DIR`. `sml.txt` appears in the dropdown automatically.
2. **Subprocess Dispatch (`ipc.py`):**
   ```python
   if job.template:
       cmd.extend(["--template", job.template])
   if job.validate_sml:
       cmd.append("--validate-sml")
   ```
3. **Deadlock-Free Diagnostics:** If validation fails, the core outputs JSON diagnostics to `stderr` (`{"bash4llm_status":"ERROR","code":13,"reason":"SYNTAX_VAL",...}`), which `ipc.py` captures without crashing and broadcasts via Server-Sent Events (SSE).

---

## 6. Verification & Automated Test Suite

### 6.1 Scintilla Core T3 Suite (`extras/test/scintilla-t3.sh`)
The test suite validates the core SML rejection behavior:

```bash
# Test 1: SML Validation Reject Check
INVALID_OUT=$(echo "Hello world" | bash "$BASH4LLM_BIN" -m "$TEST_MODEL" --validate-sml --dry-run 2>&1 || true)
if echo "$INVALID_OUT" | grep -qE "SYNTAX_VAL|13|14"; then
  printf "PASSED\n"
fi
```

### 6.2 Manual CLI Verification Scenarios

#### Scenario A: Compliant SML Inference
```bash
./bash4llm -t sml "Analyze the benefits of immutable infrastructure" --validate-sml
```

#### Scenario B: Non-Compliant Text (Expect Exit Code 13)
```bash
printf "Unstructured plain text" | ./bash4llm --validate-sml --dry-run
echo "Exit status: $?" # Output: 13
```

#### Scenario C: Structured JSON Error Diagnostic
```bash
printf "Hello world" | ./bash4llm --validate-sml --json-diagnostics --dry-run
```
*Output on `stderr`:*
```json
{"bash4llm_status":"ERROR","code":13,"reason":"SYNTAX_VAL","message":"Response failed syntax validation.","timestamp":"2026-08-18T19:54:00Z"}
```

---

## 7. Cryptographic Manifest Registration

Whenever `extras/hooks/sml-gate.sh` or `extras/templates/sml.txt` is updated, regenerate the signed manifest:

```bash
# 1. Update SHA-256 digests and Ed25519 signature
./extras/security/generate-manifest.sh

# 2. Verify all extra modules
./bash4llm --install-extras
```
