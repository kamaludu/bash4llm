# 🎆 SCINTILLA CORE CANONICAL SPECIFICATION v2026.1

## TIMELESS NORMATIVE EDITION

### Core Deterministico per la Gestione di Percorsi di Emancipazione Personale
**Stato:** Specifica Normativa di Riferimento (Normative Reference Specification)  
**Autorità:** Authoritative Specification / Single Source of Truth per SCINTILLA CORE  
**Data di Rilascio:** 27 Luglio 2026  
**Nota di Decoupling:** *L'architettura definita in questa specifica è senza tempo (Timeless Normative Architecture); l'implementazione di riferimento si basa su Bash4LLM⁺ Core v2.8.0, Bash 4.0+, utilità POSIX e `jq`.*

---

## 1. VISIONE ED ETICA DI SISTEMA (IL MANIFESTO DELL'EMANCIPAZIONE)

### 1.1 L'Assistente di Emancipazione Personale
> **Scintilla non è un motore di ricerca per i servizi sociali, né un semplice sistema RAG.**  
>   
> **Scintilla è un assistente di emancipazione personale progettato per accompagnare le persone vulnerabili da uno stato di disorientamento ("non so da dove iniziare") a un piano d'azione concreto per il futuro ("ho una micro-azione per domani mattina").**

```text
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                            MOTORE RAG TRADIZIONALE                               │
 │ "Ecco 15 indirizzi di mense e dormitori con orari e norme di accesso."           │
 └──────────────────────────────────────────────────────────────────────────────────┘
                                         VS
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                          SCINTILLA CORE (EMANCIPAZIONE)                        │
 │ "So che ti senti sopraffatto. Stasera pensiamo solo a trovare un posto sicuro     │
 │  dove dormire. Domani mattina faremo un piccolo passo insieme per il documento. │
 │  Non sei solo, ti guiderò io punto per punto."                                  │
 └──────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 La Conversazione Trasformativa e la Rete di Salvataggio Deterministica
* **L'LLM come Strumento Pedagogico Umano:** L'LLM gestisce la conversazione: spiega, motiva, riformula, verifica la comprensione, adatta il registro linguistico ed ha pazienza infinita, risultando disponibile 24 ore su 24 in decine di lingue.
* **Il Runtime Deterministico come Rete di Salvataggio:** L'LLM opera esclusivamente all'esterno dello stato. Il controllo delle dipendenze, la verifica delle evidenze, la tutela della privacy e l'avanzamento dei percorsi sono governati in modo **rigidamente deterministico da Bash e `jq`**, impedendo allucinazioni o indicazioni fuorvianti su norme e requisiti.

---

## 2. INVARIANTI TECNICHE E ARCHITETTURA DI BASE

### 2.1 Target Runtime & Compatibilità Hardware
* **Shell Target:** Bash $\ge 4.0$ (Linux, Termux/Android su hardware limitato a 2GB RAM, macOS, WSL, BSD).
* **Air-Gap & Offline Resilience:** Operatività completa anche in assenza di connessione di rete (LLM locale via llama.cpp/Ollama o fallback su Knowledge Base/Playbook locali).
* **Zero `declare -n` / Nameref:** Invariante di compatibilità per Bash 4.0+. Uso esclusivo di espansione indiretta `${!var}` e `printf -v`.
* **Zero `eval`:** Assegnazione delle variabili da parser allo scope locale tramite `printf -v` previa verifica dell'identificatore tramite regex `^[a-zA-Z_][a-zA-Z0-9_]*$`.

### 2.2 Principi di Sicurezza I/O e Isolamento
* **Isolamento del Filesystem:** Operatività confinata nella directory isolata `$BASH4LLM_DIR` (o `$BASH4LLM_RUN_DIR`). Permessi rigorosi `0700` per le directory e `0600` per i file. Maschera preventiva `umask 077` impostata prima di qualsiasi operazione I/O.
* **Integrità Crittografica dei Moduli:** Ogni modulo o adattatore viene verificato crittograficamente tramite SHA-256 (`manifest.sha256`) attraverso la funzione `verify_module_integrity()` di Bash4LLM⁺ prima del caricamento.

### 2.3 Contratto di Integrabilità con Bash4LLM⁺ Core v2.8.0
Scintilla risiede in `extras/scintilla/` e riutilizza l'infrastruttura hardened del monolite `bash4llm`:
* `lock_exec()` per i lock esclusivi POSIX Anti-TOCTOU.
* `atomic_write()` e `_tmpf()` per le allocazioni temporanee e le Scritture Atomiche.
* `_core_sha256()` per il calcolo dei checksum SHA-256.
* `rotate_history()` per la rotazione e l'archiviazione cifrata dei log.

---

## 3. MODELLO DI DOMINIO E SCHEMI DI TIPO FORMALI

Scintilla separa nettamente il **Caso (`Case`)** dalla traccia conversazionale (**`Thread`**).

```text
SCINTILLA DOMAIN MODEL ARCHITECTURE
│
├── Case (Entità di Dominio Principale - Stato di Autonomia)
│   ├── Case ID: case_2026_0891
│   ├── Graph Identity: { adapter_id: "italy@2026.1", graph_version: "2026.1.0", graph_sha256: "a1b2c3..." }
│   ├── Goal Active: "housing_autonomy"
│   ├── Focus Node: "financial_identity_established"
│   ├── Capacities: Patrimonio permanente di abilità dell'utente (Non decadono)
│   ├── Outcomes: Traguardi materiali temporali (Con scadenze e stato di freschezza)
│   └── Documents: Stato dei documenti (Con distinzione tra claimed e verified)
│
├── Domain Logging (Dual-Log System)
│   ├── events.ndjson (Registro dei fatti neutri di sistema/utente - raw_sha256)
│   └── decisions.ndjson (Registro delle decisioni del Policy Core - Chain Hash)
│
└── Thread (Log di Esecuzione Conversazionale - Gestito da Bash4LLM Core)
    └── history/threads/<case_id>.ndjson (Traccia conversazionale grezza)
```

### 3.1 Definizione Formale dei Tipi e degli Enum (Type Schemas)

```typescript
type ProofLevel = 0 | 1 | 2 | 3;
type StatusEnum = "unknown" | "claimed" | "observed" | "pending" | "verified" | "expired" | "revoked";
type SensitivityEnum = "PUBLIC" | "PERSONAL" | "SENSITIVE" | "HIGHLY_SENSITIVE";

interface CapabilityState {
  status: StatusEnum;
  proof_level: ProofLevel;
  trust_score: number; // 0 - 100
  last_updated_utc: string; // ISO-8601 UTC
}

interface OutcomeState {
  status: StatusEnum;
  proof_level: ProofLevel;
  trust_score: number; // 0 - 100
  observed_at: string;        // ISO-8601 UTC
  expires_at: string;         // ISO-8601 UTC
  last_confirmed_utc: string; // ISO-8601 UTC
}

interface DocumentState {
  status: StatusEnum;
  proof_level: ProofLevel;
  trust_score: number; // 0 - 100
  evidence_ref: string;
}

interface CanonicalEvidence {
  normalized_text: string;
  language: string;
  extraction_method: string;
  confidence_score: number; // 0.0 - 1.0 (Pure Telemetry)
}
```

### 3.2 Capability (Permanente) vs. Outcome (Temporale)
* **Capability (Competenza/Abilità):** Patrimonio permanente di abilità dell'utente (es. `CAP_USE_EMAIL`, `CAP_WRITE_CV`, `CAP_ITALIAN_A2`). Le capability non decadono automaticamente nel tempo e richiedono un'azione esplicita di revoca per essere modificate.
* **Outcome (Traguardo/Risultato Materiale):** Condizione osservabile e temporale soggetta a decadimento o perdita (es. `OUTCOME_FIRST_NIGHT_SAFE`, `OUTCOME_EMPLOYMENT_CONTRACT`, `OUTCOME_HOUSING_LEASE`). Includono i campi obbligatori di freschezza temporale (`observed_at`, `expires_at`, `last_confirmed_utc`).

### 3.3 Ortogonalità tra `status` e `proof_level`
La qualità dell'evidenza originaria e lo stato del ciclo di vita temporale sono due dimensioni **completamente indipendenti (ortogonali)**:

* **`proof_level` (0 - 3) e `trust_score` (0-100):** Misura la forza della fonte dell'evidenza. Non decade mai nel tempo.
  * `0`: Dichiarazione dell'utente non verificata (`USER_DECLARATION`).
  * `1`: Documento caricato o fatto osservato ma non validato (`DOCUMENT`).
  * `2`: Verificato da evento di sistema o registro algoritmico (`SYSTEM_EVENT`).
  * `3`: Verificato ed approvato esplicitamente da un operatore umano (`OPERATOR_CONFIRMATION`).
  * *Nota:* La Knowledge Base locale (`LOCAL_KB`) fornisce procedure normative ma **non eleva mai il `proof_level` o `trust_score` dell'utente**.

* **`status`:** Rappresenta lo stato corrente nel ciclo di vita:
  * `unknown`, `claimed`, `observed`, `pending`, `verified`, `expired`, `revoked`.

*Esempio Ortogonale:* Un contratto di lavoro scaduto mantiene `proof_level: 3` (verificato da umano nel passato) ma acquisisce `status: "expired"`.

### 3.4 Semantica di Revoca e Valutazione Pigra Continuativa delle Scadenze
* **Revoca:** Quando uno stato o un documento viene revocato (`status: "revoked"`), il valore storico di `proof_level` rimane memorizzato per audit, ma il valutatore del Grafo e il Policy Core trattano il nodo come avente **forza attiva effettiva pari a 0**.
* **Continuative Lazy Expiry Evaluation:** Ad **ogni valutazione di stato, lettura o esecuzione di policy**, l'Core valuta la scadenza in memoria:
  $$\text{Se } \text{now\_utc} > \text{expires\_at} \implies \text{status} \leftarrow \text{"expired"}$$

### 3.5 Tempo Autorevole e Resilienza Offline
* **Sorgente del Tempo:** Orologio di sistema POSIX espresso in formato **UTC ISO-8601** (`date -u +%Y-%m-%dT%H:%M:%SZ`).
* **Time Skew Invariant:** Se viene rilevato un salto temporale all'indietro dovuto al riavvio dell'orologio RTC di un dispositivo offline ($\text{now\_utc} < \text{last\_updated\_utc}$), l'Core registra un avviso in `events.ndjson` e preserva l'integrità dello stato senza arrestarsi.

### 3.6 Schema dello Stato del Caso (`case_state.json`)
Ubicazione su disco: `bash4llm.d/cases/<case_id>/case_state.json` (Permessi `0600`).

```json
{
  "schema_version": "1.0.0",
  "case_id": "case_2026_0891",
  "session_id": "sess_20260726_001",
  "correlation_id": "c0a80101-4f8a-4b2a-9e12-8f9a0b1c2d3e",
  "turn_sequence": 14,
  "graph_identity": {
    "adapter_id": "italy@2026.1",
    "graph_version": "2026.1.0",
    "graph_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  },
  "needs_human_review": false,
  "active_goal": "housing_autonomy",
  "focus_node": "financial_identity_established",
  "background_nodes": [
    "temporary_housing_search"
  ],
  "capacities": {
    "CAP_IDENTITY": {
      "status": "verified",
      "proof_level": 3,
      "trust_score": 100,
      "last_updated_utc": "2026-07-26T17:00:00Z"
    },
    "CAP_FINANCE": {
      "status": "claimed",
      "proof_level": 0,
      "trust_score": 10,
      "last_updated_utc": "2026-07-26T17:00:00Z"
    }
  },
  "outcomes": {
    "employment": {
      "status": "expired",
      "proof_level": 3,
      "trust_score": 95,
      "observed_at": "2026-01-10T10:00:00Z",
      "expires_at": "2026-07-10T10:00:00Z",
      "last_confirmed_utc": "2026-05-01T08:00:00Z"
    }
  },
  "documents": {
    "id_card": {
      "status": "verified",
      "proof_level": 3,
      "trust_score": 100,
      "evidence_ref": "evid_0001"
    }
  },
  "last_updated_utc": "2026-07-26T17:00:00Z"
}
```

### 3.7 Risoluzione Formale del Grafo $G=(V,E)$ e Invarianti Topologiche
I percorsi sono definiti da file JSON dichiarativi in `extras/scintilla/graph/`:

```json
{
  "node_id": "financial_identity_established",
  "goal_id": "economic_autonomy",
  "title": "Identità Finanziaria Stabilita",
  "requires_all": [
    "legal_identity_established"
  ],
  "requires_any": [
    ["passport"],
    ["national_id_card"],
    ["emergency_identity_document"]
  ],
  "provides": [
    "financial_identity"
  ],
  "unlocks": [
    "employment_contract_execution",
    "housing_lease_execution"
  ],
  "country_adapter": "italy/finance.json"
}
```

#### Costruzione Matematica del Grafo:
$$\text{Sia } V = \{\text{nodi del grafo}\}. \quad \text{Per ogni } v \in V, \text{ i suoi requisiti } \text{requires\_all}(v) \text{ e } \text{requires\_any}(v) \text{ vengono risolti sui nodi } u \in V \text{ che li forniscono in } \text{provides}(u).$$
$$\text{Si definisce l'insieme degli archi orientati } E = \{(u, v) \mid u \text{ soddisfa una dipendenza propedeutica di } v\}.$$

#### Regole Normative Topologiche:
1. **DAG Invariant:** Il Grafo delle Dipendenze Risolto $G=(V,E)$ MUST essere un **Grafo Diretto Aciclico (DAG)**. La presenza di un ciclo fa fallire la validazione con **Exit Code 23 (`ERR_GRAPH_CYCLE_DETECTED`)**.
2. **`node_id` Uniqueness:** Ogni `node_id` MUST essere univoco a livello globale nell'intero adattatore.
3. **`provides` Non-Uniqueness & Disjunctive Resolution:** Nodi distinti CAN fornire il medesimo identificatore in `provides`. Un requisito $X$ per un nodo $C$ è soddisfatto se **almeno uno** dei nodi fornitori possiede `status == "verified"`.
4. **Shared Nodes Across Goals:** Goal differenti CAN fare riferimento agli stessi `node_id` sottostanti.

#### Goal Memory Sharding (Chiusura Transitiva sulle Dipendenze):
Su hardware a 2GB RAM, Scintilla carica in memoria via `jq` **solamente il sotto-grafo del Goal attivo (`active_goal`) e la chiusura transitiva dei soli rami di dipendenza propedeutica all'indietro (`requires_all`, `requires_any`)**, escludendo esplicitamente i rami di sblocco in avanti (`unlocks`). Questo mantiene l'impronta RAM sotto i 10MB.

---

## 4. KNOWLEDGE LAYERING, POLICY ENGINE PURO E PEP GUARDIAN

### 4.1 Adattatori a 3 Livelli
1. **Universal Knowledge (`Universal`):** Principi universali di sviluppo umano e dipendenze logiche del grafo.
2. **Country Adapter (`country_adapter` - SemVer `MAJOR.MINOR`):** Mappatura delle istituzioni, leggi e strumenti nazionali (es. Italia: SPID, Codice Fiscale, Centro per l'Impiego).
3. **Local Adapter (`local_adapter` - SemVer `MAJOR.MINOR`):** Risorse territoriali, indirizzi, telefoni, orari di sportelli e contatti locali (es. Bologna: Anagrafe Via Larga).

### 4.2 Governance delle Regole di Policy e Requisiti di Testing
Le regole di policy risiedono in `extras/scintilla/policies/{privacy,legal,minors,finance}/`. Ogni regola MUST includere obbligatoriamente i 6 metadati di governance:

```json
{
  "id": "minors_housing_check",
  "version": "1.0.0",
  "author": "Scintilla Safety Team",
  "created_at": "2026-01-15",
  "risk_level": "HIGH",
  "test_suite_ref": "test_minors_policy.sh",
  "condition": {
    "user_age_lt": 18,
    "target_nodes": ["housing_move_in", "housing_lease_execution"]
  },
  "action": {
    "decision": "NEEDS_HUMAN_REVIEW",
    "mask_fields": ["national_id_card"]
  }
}
```

*Requisito Normativo di Testing:* Ogni suite di test riferita in `test_suite_ref` DEVE contenere tassativamente: 1) **Positive Tests** (`ALLOW`), 2) **Negative Tests** (`DENY`/`REVIEW`), 3) **Boundary Tests** (valori limite).

### 4.3 Pure Policy Core (Trasparenza Referenziale & Precedenza)
La funzione `scintilla_policy_eval()` è pura e deterministica:
* **Contratto Matematico:**
  $$\text{Policy}(\text{CaseState}, \text{Hypothesis}, \text{Policies}) \longrightarrow \{\text{Decision}, \text{MatchedRules}, \text{AppliedMasks}, \text{Reason}\}$$
* **Invariante:** **Zero I/O, zero modifiche al filesystem, zero effetti collaterali.**

#### Gerarchia Rigida di Precedenza Decisionale:
Configurabile via `SCINTILLA_POLICY_PRECEDENCE` (Default di sicurezza):
$$\text{DENY} > \text{ESCALATE} > \text{NEEDS\_HUMAN\_REVIEW} > \text{ALLOW}$$

### 4.4 Policy Enforcement Point (PEP) Guardian
> **INVARIANTE ARCHITETTURALE ASSOLUTA (SANDWICH TOPOLOGY):**  
> $$\text{Application} \longrightarrow \text{PEP} \longrightarrow \text{Provider Adapter} \longrightarrow \text{LLM}$$  
> **Ogni adattatore provider DEVE tassativamente ricevere i payload in uscita esclusivamente attraverso il Policy Enforcement Point (PEP). Il trasferimento diretto di dati al layer di rete bypassando il PEP è strutturalmente proibito.**

#### Invarianti e Confini del PEP:
1. **Filtering su Chiavi Strutturate:** Il PEP esegue il mascheramento/redazione **esclusivamente basandosi sulle CHIAVI strutturate dei dati JSON** mappate nella `sensitivity_map`.
2. **Strategia Configurabile (`SCINTILLA_PEP_STRATEGY`):**
   * **`REMOVE` (Default di Sicurezza):** Rimuove completamente la chiave e il valore dal JSON.
   * **`REDACT`:** Sostituisce il valore con `"[REDACTED]"`.
3. **Testo Libero (Unstructured Text):** Il PEP non effettua l'analisi semantica del testo libero. I dati `HIGHLY_SENSITIVE` **NON DEVONO MAI essere scritti in campi di testo libero**, ma veicolati unicamente tramite chiavi strutturate tipizzate.

```bash
scintilla_pep_filter() {
  local raw_payload="${1:-}"
  local sensitivity_map="${2:-}"
  local strategy="${SCINTILLA_PEP_STRATEGY:-REMOVE}"
  
  if [ "$strategy" = "REMOVE" ]; then
    printf '%s' "$raw_payload" | jq --argjson sens "$sensitivity_map" '
      walk(if type == "object" then with_entries(if ($sens[.key] == "HIGHLY_SENSITIVE" or $sens[.key] == "SENSITIVE") then empty else . end) else . end)
    ' 2>/dev/null
  else
    printf '%s' "$raw_payload" | jq --argjson sens "$sensitivity_map" '
      walk(if type == "object" then with_entries(if ($sens[.key] == "HIGHLY_SENSITIVE") then empty elif ($sens[.key] == "SENSITIVE") then .value = "[REDACTED]" else . end) else . end)
    ' 2>/dev/null
  fi
}
```

### 4.5 Cryptographic Erasure e Diritto all'Oblio (DEK Destruction)
A causa della fisica delle memorie flash/SSD moderni (Wear-Leveling, Controller FTL, Copy-on-Write su Btrfs/ZFS/APFS) che rendono inefficace l'utilità `shred`:

* **Invariante Cifratura:** Ogni file del caso (`case_state.json`, `decisions.ndjson`, `events.ndjson`) viene cifrato a riposo tramite una **Data Encryption Key (DEK)** unica per il caso, conservata nell'OpenSSL Vault.
* **Case Purge Protocol (`bash4llm --case ID --purge-case`):** L'epurazione sicura del caso avviene tramite **Cryptographic Erasure**, distruggendo ed azzerando atomicamente la DEK nel Vault (`vault_destroy_key`). Senza la DEK, tutti i file su disco diventano istantaneamente ed irreversibilmente ciphertext inattaccabile, rendendo irrilevante la presenza di blocchi o snapshot residui.

---

## 5. PIPELINE DETERMINISTICA A 5 STADI E REASONING KERNEL

L'LLM opera completamente all'esterno dello stato del caso. L'elaborazione segue una pipeline unidirezionale a 5 stadi:

```text
 ┌─────────────┐     ┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌────────────────┐
 │ 1. Output   │ ──> │ 2. SML Parser   │ ──> │ 3. Reasoning     │ ──> │ 4. Pure Policy  │ ──> │ 5. Runtime     │
 │    LLM      │     │    & Sanitizer  │     │    Kernel (Bash) │     │    Core       │     │    Commit      │
 └─────────────┘     └─────────────────┘     └──────────────────┘     └─────────────────┘     └────────────────┘
                                                       │                                              │
                                                       ▼                                              ▼
                                               Genera Ipotesi                                   Scrive Event Log
                                             Strutturata JSON                                  & Decision Log
```

### 5.1 Contratto SML (Structured Markup Language) e Regole di Robustezza
```text
SML_VERSION: 1.0
LISTEN_SUMMARY: <Sintesi empatica dello stato attuale dell'utente - Max 50 parole>
LISTEN_AGENCY: <Opzioni e decisioni pratiche restituite al controllo dell'utente>
MAP_OVERVIEW: <Mappa sintetica dei passaggi per i nodi attivi>
NEXT_STEP: <Micro-azione concreta monoriga da compiere subito>
PROPOSED_TRANSITION: <node_id|NONE>
EVIDENCE: <Motivazione ed evidenza estratta dalle parole dell'utente o dall'azione svolta>
EVIDENCE_TYPE: <USER_DECLARATION|OPERATOR_CONFIRMATION|DOCUMENT|SYSTEM_EVENT>
```

#### Regole Normative di Parsing SML:
1. **Unknown Fields:** Eventuali campi sconosciuti generati dall'LLM **DEVONO essere ignorati** senza sollevare errori (*Forward Compatibility*).
2. **Missing Mandatory Fields:** L'assenza di anche solo un campo obbligatorio (`SML_VERSION`, `LISTEN_SUMMARY`, `NEXT_STEP`, `PROPOSED_TRANSITION`, `EVIDENCE`, `EVIDENCE_TYPE`) **DEVE sollevare `ERR_SML_PARSE_FAILED` (Exit Code 20)**.

### 5.2 Il Transition Kernel e Immutabilità dell'Ipotesi
Il Transition Kernel (`extras/scintilla/kernel.sh`) trasforma l'SML nell'oggetto `hypothesis.json`.

> **INVARIANTE DI AUDIT:** L'oggetto `hypothesis.json` generato dal Kernel è **rigidamente immutabile**. Una volta creato, non viene mai modificato durante le fasi successive di valutazione e commit.

```json
{
  "hypothesis_id": "hyp_2026_9941",
  "session_id": "sess_20260726_001",
  "correlation_id": "c0a80101-4f8a-4b2a-9e12-8f9a0b1c2d3e",
  "turn_sequence": 14,
  "sml_version": "1.0",
  "proposed_transition": "financial_identity_established",
  "proof_level": 0,
  "evidence": {
    "type": "USER_DECLARATION",
    "text_sanitized": "Ho aperto il conto corrente stamattina",
    "raw_ref": "audit_2026_0891.log",
    "raw_sha256": "f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2",
    "canonical_evidence": {
      "normalized_text": "ho aperto il conto corrente stamattina",
      "language": "it",
      "extraction_method": "sml_regex_v1",
      "confidence_score": 0.95
    }
  }
}
```

### 5.3 Algoritmo di Scoring Algebrico per il `focus_node` e Tie-Breaker
Per evitare oscillazioni del contesto LLM ("thrashing"), la selezione del `focus_node` calcola lo score di ogni nodo $n$:

$$\text{Score}(n) = (w_1 \cdot \text{MissingDeps}) + (w_2 \cdot \text{UnlocksWeight}) + (w_3 \cdot \text{RiskLevel}) + (w_4 \cdot \text{GoalDistance})$$

#### Gerarchia di Selezione:
1. **Priorità 1 (Human Override):** Impostazione manuale dell'operatore (`--set-focus <node_id>`).
2. **Priorità 2 (Algoritmo di Score):** Nodo attivo con il minor valore di $\text{Score}(n)$.
3. **Priorità 3 (Tie-Breaker Assoluto):** In caso di perfetta parità di score, vince il **minore ordine lessicografico ASCII del `node_id`**.
4. **Priorità 4 (Stabilità):** Il `focus_node` **non varia** finché l'evidenza corrente non viene processata.

---

## 6. MACCHINA A STATI E CICLO DI VITA FORMALE

Il ciclo di vita di un'interazione rispetta la seguente macchina a stati formale:

```text
 ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
 │ 1. USER      │ ──> │ 2. EVENT     │ ──> │ 3. EVIDENCE  │ ──> │ 4. HYPOTHESIS│
 │    INPUT     │     │    LOGGING   │     │    EXTRACTION│     │    CREATION  │
 └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                                        │
                                                                        ▼
 ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
 │ 8. OUTBOUND  │ <── │ 7. STATE     │ <── │ 6. DECISION  │ <── │ 5. PURE      │
 │    PROMPT    │     │    COMMIT    │     │    LOGGING   │     │    POLICY    │
 └──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

### Formula Matematica della Transizione:
$$\text{Transition}(S_{t}, \text{Event}_e) \xrightarrow{\text{Transition Kernel}} \text{Hypothesis}_h \xrightarrow{\text{Pure Policy}} \text{Decision}_d \xrightarrow{\text{Runtime}} S_{t+1}$$

---

## 7. AUDITING, DUAL-LOG SYSTEM, CHAIN HASH E RECOVERY

### 7.1 Registro Duale (Dual-Log System)
I log risiedono in `bash4llm.d/cases/<case_id>/` (Permessi `0600`):

1. **`events.ndjson` (Event Log - Fatti Neutri Grezzi):**
   ```json
   {
     "timestamp_utc": "2026-07-26T17:00:00Z",
     "session_id": "sess_20260726_001",
     "correlation_id": "c0a80101-4f8a-4b2a-9e12-8f9a0b1c2d3e",
     "turn_sequence": 14,
     "event_type": "USER_MESSAGE_RECEIVED",
     "raw_ref": "audit_001.log",
     "raw_sha256": "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0"
   }
   ```
   *Resilienza Corruzione Event Log:* Se una riga di `events.ndjson` risulta corrotta, viene isolata in `events.ndjson.corrupted.<TS>` e il log riprende con un record `LOG_RECOVERY_EVENT` senza bloccare la macchina a stati del caso.

2. **`decisions.ndjson` (Decision Log - Tamper-Evident Chain Log):**
   ```json
   {
     "timestamp_utc": "2026-07-26T17:00:05Z",
     "case_id": "case_2026_0891",
     "session_id": "sess_20260726_001",
     "correlation_id": "c0a80101-4f8a-4b2a-9e12-8f9a0b1c2d3e",
     "turn_sequence": 14,
     "core_version": "2026.1",
     "policy_version": "1.0.4",
     "policy_sha256": "f4k5l6m7n8o9p0q1r2s3t4u5v6w7x8y9z0a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5",
     "sml_version": "1.0",
     "graph_version": "2026.1.0",
     "graph_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "actor": { "id": "scintilla_core", "role": "runtime" },
     "state_checksum_before": "e3b0c44298fc1c149afbf4c8996fb924...",
     "state_checksum_after": "d4e5f6a1b2c34567890123456789abcd...",
     "prev_decision_checksum": "8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c...",
     "decision_checksum": "b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e...",
     "hypothesis_id": "hyp_2026_9941",
     "decision": "ALLOW",
     "matched_rules": ["minors_housing_check"],
     "applied_masks": ["user_national_id"]
   }
   ```

### 7.2 Canonicalizzazione JSON Cross-Platform (`jq -S -c .`) & Chain Hash
Per garantire la riproducibilità degli Hash su qualsiasi sistema operativo (Linux, macOS, Termux):

```bash
scintilla_canonicalize_json() {
  local raw_input="${1:-}"
  printf '%s' "$raw_input" | tr -d '\r' | jq -S -c . 2>/dev/null
}
```

#### Genesis Seed ($N=1$):
$$\text{Genesis\_Seed} = \text{\_core\_sha256}(\text{case\_id})$$

#### Record Successivi ($N > 1$):
La concatenazione avviene sulla sequenza di byte UTF-8:
$$\text{decision\_checksum}_N = \text{\_core\_sha256}(\text{decision\_checksum}_{N-1} + \text{canonical\_json}(\text{Payload}_N))$$

### 7.3 Interfaccia CLI di Verifica e Recovery
* **Verification:** `bash4llm --case ID --verify-decision-chain`  
  Ricalcola la catena hash. Se rileva una manomissione, esce con **Exit Code 17** (`BASH4LLM_ERR_SEC`).
* **Repair & Recovery:** `bash4llm --case ID --repair-log`  
  Isola il segmento corrotto in `decisions.ndjson.corrupted.<TIMESTAMP>`, ripristina la catena valida fino all'ultimo blocco integro e registra l'evento `LOG_REPAIRED`.

---

## 8. PROTOCOLLO TRANSAZIONALE WAL ED HARDENING I/O POSIX

### 8.1 Consistency Model & Bijection Invariant
> **CONSISTENCY MODEL:**  
> **Scintilla garantisce transizioni di stato Single-Writer Serializable. In qualsiasi istante fisico $t$, esiste al massimo un solo file `case_state.json` committato su disco. Ogni stato valido committato $S_k$ corrisponde biiettivamente ($1:1$) a una e una sola riga del Decision Log $D_k$ tale che $D_k.\text{state\_checksum\_after} = \text{\_core\_sha256}(S_k)$.**

### 8.2 Protocollo Transazionale Two-Phase Commit & Roll-Forward Recovery

#### Fasi di Commit:
1. **Fase 1 (Prepare):** Scrittura del nuovo stato calcolato nel file temporaneo nello stesso filesystem: `case_state.json.tmp`.
2. **Fase 2 (Log Commit):** Scrittura ad append atomico del record su `decisions.ndjson`, contenente `state_checksum_after = sha256(case_state.json.tmp)`.
3. **Fase 3 (State Commit):** Sostituzione atomica dello stato: `mv -f case_state.json.tmp case_state.json`.

> **CRITICAL WAL INVARIANT:**  
> **Il checksum `state_checksum_after` registrato nel record di `decisions.ndjson` DEVE tassativamente essere calcolato sull'esatta sequenza di byte presente nel buffer temporaneo (`case_state.json.tmp`) che verrà successivamente spostata atomicamente come `case_state.json`.**

#### Algoritmo di Recovery all'Avvio (`Roll-Forward`):
All'avvio, l'Core verifica se $\text{\_core\_sha256}(\text{case\_state.json}) \stackrel{?}{=} \text{state\_checksum\_after}$ dell'ultima riga di `decisions.ndjson`:
* **Crash prima della Fase 2:** `case_state.json.tmp` esiste, ma `decisions.ndjson` NON ha il record. $\rightarrow$ Viene rimosso `case_state.json.tmp`.
* **Crash tra Fase 2 e Fase 3:** `decisions.ndjson` contiene `state_checksum_after`, ma `case_state.json` ha ancora il vecchio hash. `case_state.json.tmp` esiste e il suo hash equivale a `state_checksum_after`. $\rightarrow$ **Roll-Forward Automatico:** L'Core esegue `mv -f case_state.json.tmp case_state.json` prima di elaborare qualsiasi operazione.

### 8.3 Concorrenza, Timeout e Serializzazione Append
* **Kernel Append Serialization:** Ogni operazione di aggiunta registro su `decisions.ndjson` è serializzata dal kernel dell'OS quando il file è aperto con flag `O_APPEND` su **filesystem locali POSIX-compliant** (`>>`).
* **Locking Timeout Policy:** Se un processo concorrente tenta di acquisire il lock mentre è occupato, attende con backoff esponenziale fino a `SCINTILLA_LOCK_TIMEOUT` (default: 10s). Se scade il timeout, il processo si arresta senza apportare alcuna modifica ed esce con **Exit Code 13 (`ERR_INFRASTRUCTURE_IO`)**.
* **Best-Effort POSIX Storage Synchronization:** L'aggiornamento dello stato richiede il flush dei buffer fisici tramite la procedura:

```bash
scintilla_atomic_state_commit() {
  local state_file="${1:-}"
  local tmp_file="${2:-}"
  
  # 1. Spostamento atomico nello stesso filesystem
  mv -f "$tmp_file" "$state_file" || return 1
  
  # 2. Best-effort POSIX storage synchronization
  if command -v sync >/dev/null 2>&1; then
    sync "$state_file" 2>/dev/null || sync 2>/dev/null || true
  fi
  
  chmod 600 "$state_file" 2>/dev/null || true
  return 0
}
```

### 8.4 Git-Style Monotonic Rollback Protocol
I ripristini di stato (rollback) non cancellano e non troncano mai la catena di log:
* Il comando `--rollback` scrive un **nuovo record decisionale di tipo `ROLLBACK`** contenente `target_state_checksum`.
* Il Runtime applica lo stato di backup come nuovo stato corrente $S_{t+1}$. La catena decisionale prosegue linearmente in avanti.

### 8.5 Audit Completo degli Human Override
Ogni operazione di override umano registra il payload esteso di audit:

```bash
bash4llm --case ID --override-accept <node_id> \
  --operator-id "usr_op_402" \
  --reason "Documento cartaceo visionato fisicamente in sede" \
  --ticket-ref "TICK-2026-8812"
```

---

## 9. TASSONOMIA DEGLI EXIT CODE E CONFIGURAZIONE

### 9.1 Tabella Completa degli Exit Code

| Codice | Costante | Categoria | Descrizione |
| :---: | :--- | :---: | :--- |
| `0` | `ERR_SUCCESS` | Core | Operazione completata con successo. |
| `10` | `BASH4LLM_ERR_NO_API_KEY` | Core | Chiave API del provider mancante. |
| `11` | `BASH4LLM_ERR_BAD_MODEL` | Core | Modello LLM non valido o non supportato. |
| `12` | `BASH4LLM_ERR_CURL_FAILED` | Core | Errore di rete / connessione HTTP cURL. |
| `13` | `ERR_INFRASTRUCTURE_IO` | Core | Errore I/O, disco pieno, permessi o lock timeout expired. |
| `15` | `BASH4LLM_ERR_TMP` | Core | Impossibile allocare file/directory temporanee. |
| `17` | `BASH4LLM_ERR_SEC` | Core | Violazione di sicurezza, corruzione della chain hash o manomissione. |
| **`20`** | **`ERR_SML_PARSE_FAILED`** | Core | Output SML generato dall'LLM non conforme al formato o campi mancanti. |
| **`21`** | **`ERR_EVIDENCE_MISSING`** | Core | Evidenza dichiarata assente o non valida per la transizione. |
| **`22`** | **`ERR_KB_NOT_FOUND`** | Core | Dato richiesto non trovato nella KB locale (in modalità offline). |
| **`23`** | **`ERR_GRAPH_CYCLE_DETECTED`** | Core | **Fail-Fast:** Rilevato un ciclo nel Grafo delle Capacità. |
| **`24`** | **`ERR_SCHEMA_MISMATCH`** | Core | **Segnale Non-Letale:** Richiesta revisione operatore per aggiornamento adattatore. |
| **`25`** | **`ERR_CONFIGURATION_MALFORMED`** | Core | **Config Error:** File di adattatore, grafo JSON o modulo di policy malformato. |

### 9.2 Parametri di Configurazione Default
Definiti in `bash4llm.d/config` o sovrascrivibili via ambiente:

```bash
SCINTILLA_MAX_NODES="${SCINTILLA_MAX_NODES:-500}"
SCINTILLA_EVIDENCE_MAX_CHARS="${SCINTILLA_EVIDENCE_MAX_CHARS:-250}"
SCINTILLA_LOCK_TIMEOUT="${SCINTILLA_LOCK_TIMEOUT:-10}"
SCINTILLA_MAX_BACKGROUND_NODES="${SCINTILLA_MAX_BACKGROUND_NODES:-50}"
SCINTILLA_HISTORY_MAX_BYTES="${SCINTILLA_HISTORY_MAX_BYTES:-104857600}"
SCINTILLA_HISTORY_KEEP_DAYS="${SCINTILLA_HISTORY_KEEP_DAYS:-90}"
SCINTILLA_PEP_STRATEGY="${SCINTILLA_PEP_STRATEGY:-REMOVE}"
SCINTILLA_POLICY_PRECEDENCE="${SCINTILLA_POLICY_PRECEDENCE:-DENY,ESCALATE,NEEDS_HUMAN_REVIEW,ALLOW}"
```
