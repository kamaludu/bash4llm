[![Specifica](https://img.shields.io/badge/✴️_SCINTILLA-SPECIFICA_CANONICA_DIVULGATIVA-2ea44f?style=for-the-badge&labelColor=gold)](SPEC-SCI-TL--NATLANGv2026.1.md)

# ✴ SCINTILLA Core - CANONICAL SPECIFICATION
## Canonical Standard Edition v4.5.5

**Core Deterministico e Umano-Centrico per la Gestione di Percorsi di Emancipazione Personale**

* **Stato:** Specifica Normativa Canonica Formale (Single Source of Truth - Candidate Standard)
* **Edizione:** v4.5.5 Consolidated Canonical Standard Edition (Human-Agency Centric & Formally Specified)
* **Normative Authority:** Single Source of Truth Normativa per tutte le implementazioni conformi a SCINTILLA Core.
* **Terminologia Normativa:** RFC 2119 / RFC 8174 (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`), assumono significato normativo quando utilizzati in forma maiuscola.

---

# MISSIONE

## a) Scopo, Natura e Missione della Specifica

La presente specifica definisce **SCINTILLA Core**, il Kernel Normativo Canonico per la costruzione di sistemi deterministici destinati a supportare l'emancipazione personale e l'autonomia operativa di persone fragili o vulnerabili.

SCINTILLA Core costituisce il *Single Source of Truth* del dominio e definisce, in modo formale, deterministico e verificabile, il comportamento osservabile, gli invarianti ed i vincoli normativi che ogni implementazione conforme `MUST` preservare.

La missione del Kernel è ridurre gli ostacoli cognitivi, informativi, organizzativi ed emotivi che impediscono il passaggio dall'intenzione all'azione, garantendo che l'intelligenza artificiale aumenti le capacità umane senza mai produrre dipendenza, manipolazione o perdita di autodeterminazione.

SCINTILLA Core è una specifica normativa pura (non un prodotto software, una piattaforma web o un chatbot) ed opera come contratto di garanzia sul quale prodotti ed interfacce possono essere costruiti.

---

## b) Ambito Normativo

La presente specifica definisce in modo canonico:

- il modello di stato;
- la semantica delle transazioni;
- il ledger immutabile;
- gli automi;
- gli invarianti;
- le regole di transizione;
- le politiche di sicurezza;
- i diritti dell'utente;
- i contratti di persistenza;
- le proprietà di determinismo;
- gli obblighi di conformità.

Ogni elemento definito dalla presente specifica costituisce parte del contratto normativo del Kernel.

Nessuna implementazione conforme può derogare agli invarianti, ai requisiti normativi o ai contratti definiti dalla presente specifica.

---

## c) Componenti Esterni

Qualsiasi componente non definito dalla presente specifica è considerato esterno al Kernel.

A titolo esemplificativo, appartengono a tale categoria:

modelli linguistici (LLM);  
sistemi RAG;  
motori di ricerca;  
basi di conoscenza;  
servizi pubblici;  
servizi cloud;  
interfacce utente;  
sistemi di autenticazione;  
sistemi di orchestrazione;  
applicazioni client;  
integrazioni con software di terze parti.  

La presenza, l'assenza o la sostituzione di tali componenti non modifica la semantica normativa di SCINTILLA Core.

Essi possono essere sostituiti, aggiornati o rimossi senza modificare il comportamento normativo del Kernel, purché ogni implementazione rimanga conforme alla presente specifica.

---

## d) Rapporto con le Implementazioni

La presente specifica non prescrive una particolare architettura software.

Implementazioni differenti possono essere conformi pur adottando linguaggi, piattaforme, architetture, algoritmi, librerie o infrastrutture differenti.

Un'implementazione è conforme se, e solo se, preserva gli invarianti, i requisiti normativi e il comportamento osservabile definiti da SCINTILLA Core.

La conformità è determinata esclusivamente dal comportamento osservabile del sistema e non dalle scelte implementative adottate.

---

## e) Separazione tra Componenti Deterministiche e Componenti Probabilistiche

SCINTILLA Core distingue formalmente tra componenti deterministiche e componenti probabilistiche.

Le componenti probabilistiche possono esclusivamente generare ipotesi, suggerimenti, classificazioni, spiegazioni o contenuti.

Esse non possiedono autorità normativa sullo stato del sistema.

Qualsiasi modifica dello stato persistente può avvenire esclusivamente attraverso le regole deterministiche definite dalla presente specifica.

Le componenti probabilistiche costituiscono strumenti di supporto all'elaborazione, ma non possono modificare direttamente lo stato normativo del Kernel.

---

**Principio Fondamentale**

**SCINTILLA Core definisce il comportamento normativo del sistema; le modalità implementative sono lasciate alle singole implementazioni conformi.**  
**In altre parole, la presente specifica definisce il "cosa"; ogni implementazione conforme definisce il "come".**

---

### ARCHITETTURA NORMATIVA DELLA SPECIFICA

Il presente documento è organizzato in livelli di astrazione formale espliciti:

1. **LAYER A (Modello Matematico Astratto):** Definizioni algebriche di insiemi, proiezioni, relazioni di equivalenza, funzioni pure deterministiche, automi ed equazioni di teoremi condizionate da ipotesi esplicite.
2. **LAYER B (Specifica Normativa e Politiche di Dominio):**
   * **Layer B1 (Assunzioni Normative & Principi Etici):** Principi etici, assiomi di confine (`AXIOM-`) e postulati di dominio non derivati.
   * **Layer B2 (Requisiti Ingegneristici di Sistema):** Requisiti operativi (`REQ-`), vincoli di sicurezza, tassonomia HOBM e codici di errore.
   * **Layer B3 (Regole Operative SOS):** Regole di inferenza della semantica operazionale (Small-Step Operational Semantics).
3. **LAYER C (Profilo Concreto di Riferimento):** Binding degli algoritmi crittografici, formato SC-JCS-1, contratti JSON e strutture dati concrete.

---

# CAPITOLO 0.0: DOCUMENT GOVERNANCE & META-SPECIFICATION

### 0.0.1 Principio di Minimalità Normativa (`PRINCIPLE-NORMATIVE-MINIMALITY-01`)

```text
PRINCIPLE-NORMATIVE-MINIMALITY-01
```

> **"Un nuovo Invariante Supremo o Fondamentale MUST essere introdotto nella presente specifica esclusivamente quando non sia formalmente derivabile dagli Invarianti già esistenti nell'ambito del modello normativo. Ogni nuova regola di comportamento o vincolo operativo MUST essere classificato al livello gerarchico minimo sufficiente a rappresentarne la semantica esecutiva (Regola Operativa Derivata, Requisito Ingegneristico o Contratto di Interfaccia)."**

---

### 0.0.2 Regola di Precedenza Normativa (`RULE-NORMATIVE-PRECEDENCE-01`)

```text
RULE-NORMATIVE-PRECEDENCE-01
```

> **"In caso di divergenza, ambiguità o indecidibilità tra le descrizioni narrative in linguaggio naturale (Layer B) e i contratti esecutivi machine-readable (Layer C / Capitolo 10), i contratti machine-readable di Layer C costituiscono l'autorità normativamente prevalente per l'esecuzione del runtime."**

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE
## (Layer B1 - Assunzioni Normative & Principi Etici)

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

Il dominio SCINTILLA Core è ingegnerizzato attorno ad una singola missione: **aumentare la capacità concreta di una persona fragile o vulnerabile di trasformare una situazione di instabilità in un percorso strutturato di emancipazione ed autonomia**.

#### 0.1.1 Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)
Ogni algoritmo, regola di policy, automa o trasformazione di stato `MUST` conformarsi incondizionatamente al seguente Invariante Supremo:

```text
INV-SUPREME-AGENCY-01
```

> **"SCINTILLA Core ha la missione di creare un automa di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e l'agency delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volontà e senza mai supportare azioni incompatibili con la dignità umana, la sicurezza ed i diritti altrui."**

#### 0.1.2 Tassonomia Concettuale dell'Agency Responsabile
Il sistema definisce l'**Agency Operativa Responsabile** come la combinazione qualitativa di dominio di sei dimensioni fondamentali:
1. **Capacità di Azione:** La facoltà concreta di eseguire micro-azioni orientate ad uno scopo.
2. **Comprensione del Contesto:** La chiarezza informativa sui vincoli, sulle risorse e sulle opzioni disponibili.
3. **Valutazione delle Alternative:** La facoltà di confrontare i percorsi operativi e le loro conseguenze prevedibili.
4. **Pianificazione:** La strutturazione di obiettivi complessi in sequenze ordinate di passi eseguibili.
5. **Perseveranza:** La capacità di mantenere l'impegno operativo nel tempo e di gestire le battute d'arresto.
6. **Percezione di Controllo:** La consapevolezza interiore di essere l'agente primario del proprio cambiamento personale.

*Nota Normativa:* L'Agency Operativa Responsabile costituisce una grandezza qualitativa di dominio dell'utente umano e non rappresenta una tupla vettoriale calcolata o valutata numericamente dal runtime.

---

### 0.2 ASSIOMI DI NON-PATERNALISMO E AUTODETERMINAZIONE

#### 0.2.1 Invariante Anti-Paternalista (`INV-ANTI-PATERNALISM-01`)
Il sistema `SHALL NOT` adottare un modello decisionale paternalistico basato sull'assunto presuntivo che "il sistema sa cosa è meglio per l'utente".

```text
∀ S ∈ 𝒮, SystemRole(S) ≠ LifeDecisionMaker(S)
```

Il sistema `SHALL`:
1. Aiutare la persona a comprendere la propria situazione attraverso l'analisi dei vincoli e delle risorse disponibili;
2. Proporre opzioni operative chiare e contestualizzate;
3. Esplicitare in modo trasparente le conseguenze prevedibili, i rischi ed i prerequisiti di ogni scelta;
4. Supportare la persona nella costruzione e nel mantenimento di un piano d'azione personalizzato (Playbook).

##### 0.2.1.1 Regola Operativa Derivata: Rispettosità del Tempo e Anti-Gamification (`RULE-ANTI-GAMIFICATION-01`)
1. **Divieto di Trattenimento Indipendente dal Progresso:** Il sistema `SHALL NOT` implementare meccanismi o sequenze di interazione il cui effetto osservabile sia incrementare il tempo di permanenza dell'utente sulla piattaforma indipendentemente dal completamento delle attività definite dal Playbook attivo $G_P$ o dall'interesse esplicitamente manifestato dall'utente.
2. **Sussidiarietà dell'Interazione:** Le notifiche e le interazioni proposte dal sistema `MUST` essere strettamente commisurate ai prerequisiti del Playbook attivo $G_P$, minimizzando il carico cognitivo dell'utente.

#### 0.2.2 Assioma di Sovranità del Consenso Umano (`AXIOM-HUMAN-CONSENT-SOVEREIGNTY`)
```text
AXIOM-HUMAN-CONSENT-SOVEREIGNTY
```
> **"L'utente umano costituisce l'autorità decisionale suprema ed inalienabile del proprio percorso. Nessuna raccomandazione del sistema, inferenza del modello probabilistico o suggerimento dell'operatore può mutare lo stato di avanzamento personale senza il consenso esplicito, informato e revocabile dell'utente."**

#### 0.2.3 Invariante di Continuità del Supporto (`INV-CONTINUITY-OF-SUPPORT-01`)
```text
INV-CONTINUITY-OF-SUPPORT-01
```
> **"Un'implementazione conforme SHALL NOT terminare o revocare unilateralmente la disponibilità del comportamento normativo del Kernel** in conseguenza del completamento di un percorso di Playbook, dell'inattività dell'utente o di regressioni nello stato del percorso umano ($Q_H$), salvo esplicita richiesta revocatoria dell'utente o transizione dell'automa $M$ allo stato:
```text
q₅ = SECURITY_LOCKDOWN
```
espressamente prevista dalla presente specifica."

1. **Invarianza di Accessibilità dello Stato Finale:** Il raggiungimento dello stato target:
```text
h₆ = SUSTAINED_INDEPENDENCE
```
induce la transizione dell'automa umano allo stato:
```text
h₁₁ = PREVENTIVE_STANDBY
```
preservando a tempo indeterminato l'accesso alla vista osservabile `Obs(S)`, al Vault `𝒱_vault` e al registro delle competenze `𝒦_competence`.

2. **Conservazione delle Funzionalità su Regressione:** Qualsiasi transizione regressiva nell'automa `ℋ` (es. `HEV_EMOTIONAL_OVERWHELM` o `HEV_RELAPSE_REGRESS`) `SHALL NOT` ridurre le autorizzazioni, i diritti o le funzionalità rese osservabili dalla funzione `Obs(S)`.

---

### 0.3 DISACCOPPIAMENTO PERSONA-COMPORTAMENTO E DIRITTI

#### 0.3.1 Invariante di Separazione Persona-Comportamento (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)
Il sistema `MUST` mantenere una distinzione formale assoluta tra l'**Identità dell'Attore Umano** (rappresentata dall'identificatore di attore) e lo specifico **Payload della Transazione** $t$:

```text
EvaluateAccess(α, t) := RespectUserDignity(α) ∧ EvaluatePayloadSafety(t.payload)
```

1. **Inviolabilità della Dignità della Persona:** L'utente, indipendentemente dai suoi trascorsi personali, legali o sociali, `SHALL` ricevere incondizionatamente il supporto del sistema per migliorare la propria condizione di vita. L'identificatore dell'attore non `SHALL` mai essere oggetto di squalifica o stigmatizzazione morale.
2. **Valutazione Rigorosa della Richiesta ($t$):** La funzione di valutazione valuta unicamente la sicurezza, la legalità e la sostenibilità dello specifico payload della transazione $t$.

---

# CAPITOLO 1: ALGEBRA ASTRATTA DEL MODELLO DI DOMINIO
## (Layer A & Layer B1/B2)

---

### 1.1 Formalizzazione dello Spazio degli Stati e delle Proiezioni

Lo Spazio degli Stati 𝒮 è il sotto-spazio cartesiano dello stato primario valido di sistema.

#### 1.1.1 Definizione del Sottospazio dello Stato Primario (Layer A)
Lo stato primario del sistema S è formalizzato come l'insieme delle triple valide appartenenti al prodotto cartesiano dei domini di persistenza, controllo e buffer temporaneo:

```text
S := S_persistent × S_internal × S_auxiliary
```

Dove i domini componenti sono definiti come:

1. **Dominio di Persistenza Ricostruibile dal Ledger (Tupla Etichettata):**
```text
S_persistent := ⟨ case_id ∈ I_case, M_prov, Q_consent, K_playbook, Q_revoked_items, K_competence, V_vault ⟩
```

2. **Dominio Interno di Runtime e Sicurezza:**
```text
S_internal := Q × Q_H × P_active × F_lease × O_bound × (T ∪ {null}) × M_metrics × ℕ × D_256
```
dove T ⊂ ℕ⁺ denota lo spazio dei timestamp UTC espresso in millisecondi a 64 bit e O_bound denota il dominio dei livelli di supervisione umana (`HumanOversightLevel`).

3. **Dominio Ausiliario Volatile di Co-creazione:**
```text
S_auxiliary := D_drafts
```

#### 1.1.2 Vista Derivata Pura Disaccoppiata e Contatori di Interazione (Layer A)
La componente di stato derivato 𝒮_derived non costituisce una dimensione indipendente dello spazio 𝒮 bensì una vista calcolata mediante la funzione pura:

```text
Derive : 𝒮_persistent × 𝒮_internal → 𝒮_derived
𝒮_derived := 𝒪_decision × 𝒜_index
```

La tupla dei contatori cumulativi di interazione ℳ_metrics ∈ ℕ⁴ risiede nel dominio primario di controllo interno 𝒮_internal ed è normatively ordinata come:

```text
ℳ_metrics := ⟨ c_interaction, c_rephrase, c_ambiguity, c_overwhelm ⟩
```

La mutazione deterministica della tupla:
```text
ℳ_metrics′ = UpdateMetrics(ℳ_metrics, t.event, SMLOutcome)
```

è regolata dalle seguenti regole di incremento applicate da `ApplyValidated`:
1. `c_interaction`: si incrementa di $+1$ per ogni transazione valida $t$ elaborata con esito `PASS`.
2. `c_rephrase`: si incrementa di $+1$ quando l'esito conversazionale SML è `NEEDS_REPHRASING`.
3. `c_overwhelm`: si incrementa di $+1$ quando l'evento recepito è `HEV_EMOTIONAL_OVERWHELM`.
4. `c_ambiguity`: si incrementa di $+1$ quando la valutazione di policy restituisce l'esito `RECALIBRATE`.

#### 1.1.3 Proiezioni Canoniche dello Stato (Layer A)
La scomposizione dello stato astratto $S \in \mathcal{S}$ nelle sue componenti primarie e scalari è regolata dagli operatori di proiezione ortogonale:

```text
π_persistent : 𝒮 → 𝒮_persistent
```
```text
π_internal : 𝒮 → 𝒮_internal
```
```text
π_auxiliary : 𝒮 → 𝒮_auxiliary
```

Proiezioni scalari derivate degli automi:
```text
π_Q(S) := π_internal(S).q ∈ Q
```
```text
π_Q_H(S) := π_internal(S).q_H ∈ Q_H
```

---

### 1.2 Interfaccia Osservabile Pubblica ed Equivalenza di Stato

#### 1.2.1 Funzione di Osservazione Pubblica Obs (Layer A)
La proiezione esterna dello stato verso le interfacce utente, API e viste pubbliche è governata dalla funzione pura di osservazione:

```text
Obs : 𝒮 → 𝒪
```
```text
Obs(S) := ⟨ π_persistent(S).case_id, ℳ_prov, 𝒬_consent ∖ ℛ, 𝒦_playbook, 𝒬_revoked_items, 𝒦_competence ∖ ℛ, 𝒱_vault ∖ ℛ ⟩
```

*dove* 
```text
ℛ = { e | ResourceId(e) ∈ 𝒬_revoked_items }
```

#### 1.2.2 Equivalenza di Stato Primario CoreState (Layer A)
Due stati astratti $S_1, S_2 \in \mathcal{S}$ sono semanticamente equivalenti nello stato primario se e solo se le loro proiezioni di persistenza e controllo interno sono identiche:

```text
S₁ ≡_CoreState S₂ ⇔ π_persistent(S₁) = π_persistent(S₂) ∧ π_internal(S₁) = π_internal(S₂)
```

#### 1.2.3 Proprietà Derivata dell'Algebra di Stato: Irrilevanza Osservazionale del Buffer Temporaneo (Layer A / Level 3)
```text
THEOREM-AUXILIARY-IRRELEVANCE
```
```text
∀ S₁, S₂ ∈ 𝒮, S₁ ≡_CoreState S₂ ⇒ Obs(S₁) = Obs(S₂)
```
*(Dichiara che le variazioni nel buffer volatile 𝒮_auxiliary non alterano le proiezioni osservabili dei diritti, del percorso o dello stato storico dell'utente. Costituisce un teorema derivato direttamente dalle definizioni matematiche di `Obs(S)` e `≡_CoreState`).*

---

### 1.3 ASSIOMA DEL GENESIS STATE s0 (Layer A)

Lo stato iniziale di genesi $s_0 = P(\epsilon) \in \mathcal{S}$ è formalizzato come la tripla annidata conforme alla struttura di 𝒮 (§1.1.1):

```text
s₀ := ⟨ s₀_persistent, s₀_internal, s₀_auxiliary ⟩
```

dove:

```text
s₀_persistent := ⟨ case_id=null, ℳ_prov=∅, 𝒬_consent=∅, 𝒦_playbook=⟨null, null, ∅⟩, 𝒬_revoked_items=∅, 𝒦_competence=∅, 𝒱_vault=∅ ⟩
```

```text
s₀_internal := ⟨ q=NORMAL, q_H=UNASSESSED, 𝒫_active=𝒫_default, ℱ_lease=⟨0, t₀⟩, 𝒪_bound=AUTOMATED_SUPPORT, t_pause_start=null, ℳ_metrics=⟨0, 0, 0, 0⟩, seq_num=0, last_hash=0_𝒟₂₅₆ ⟩
```

```text
s₀_auxiliary := ⟨ 𝒟_drafts=∅ ⟩
```

con vista derivata iniziale:

```text
Derive(s₀) = ⟨ 𝒪_decision=NONE, 𝒜_index=0 ⟩
```

#### 1.3.1 Obbligo Formale di Invarianza di Serializzazione del Genesis State (RFC-007)

```text
PROOF-OBLIGATION-GENESIS-SERIALIZATION-INVARIANCE := Canon(ToJSON(s₀^(v4.5.5))) ≡_bytes Canon(ToJSON(s₀^(v4.5.3)))
```
(Garantisce che il refactoring algebrico ed organizzativo di $s_0$ produca un flusso di byte UTF-8 e un hash $H_0 = 0_{\mathcal{D}_{256}}$ identici alla versione canonica di riferimento).

---

### 1.4 TRANSAZIONI, INVOLUCRO DI ESECUZIONE E LEDGER IMMUTABILE L

#### 1.4.1 Spazio delle Transazioni T, Codifica EncodeTx e Busta di Esecuzione (Layer A)

Una transazione $t \in T$ è formalizzata come la tupla: 

```text
t := ⟨ TransactionBody, execution_envelope, proof ⟩
```

La funzione pura di codifica per la persistenza è definita come:

```text
EncodeTx : T → TransactionBody
```

```text
TransactionBody := ⟨ tx_id, case_id, seq_num, prev_hash, timestamp, actor, event, payload, policy_binding_hash, schema_hash, authorization_snapshot_hash, runtime_profile, specification_id ⟩
```

L'**Involucro di Esecuzione (Execution Envelope)** è la componente di metadati applicativi generata dal runtime che registra il risultato dell'elaborazione senza contaminare il payload di dominio:

```text
execution_envelope := ⟨ execution_status, reason_code, state_mutations_applied ⟩
```

Quando una transazione viene elaborata durante lo stato di pausa dell'automa umano:
```text
q_H = HUMAN_PAUSED
```
l'involucro di esecuzione `MUST` registrare:

```text
execution_envelope = ⟨ "PROCESSED_NO_STATE_EFFECT", "HUMAN_JOURNEY_PAUSED", false ⟩
```

#### 1.4.2 Predicato Normativo di Sicurezza in Costruzione Errori e BuildErrorTx (Layer A e B2 / RFC-006)

```text
IsLockdownEvent(σ) ⇔ σ ∈ { EV_HASH_CORRUPT }
```

```text
BuildErrorTx(S, E, err, σ_orig) := ⟨ TransactionBody(
  case_id = S.case_id,
  seq_num = S.seq_num + 1,
  prev_hash = S.last_hash,
  timestamp = E.t_wall,
  event = { σ_orig      se IsLockdownEvent(σ_orig)
          { EV_SML_FAIL altrimenti,
  actor = SYSTEM,
  payload = err
), execution_envelope_err, proof_null ⟩
```

```text
BuildSystemTx(S, E, σ) := ⟨ TransactionBody(
  case_id = S.case_id,
  seq_num = S.seq_num + 1,
  prev_hash = S.last_hash,
  timestamp = E.t_wall,
  event = σ,
  actor = SYSTEM
), execution_envelope_default, proof_null ⟩
```

#### 1.4.3 Il Ledger come Monoide Libero L e Funzione Persist (Layer A)

Il registro immutabile delle decisioni (Ledger) è formalizzato come un Monoide Libero definito sullo spazio dei corpi delle transazioni canonizate:

```text
ℒ := ⟨ (TransactionBody)*, ‖, ϵ ⟩
```

La funzione pura di persistenza converte la transazione $t \in T$ nel suo corpo canonico mediante $\text{EncodeTx}(t) \in \text{TransactionBody}$ e la concatena in modo append-only al registro:

```text
Persist : ℒ × T → ℒ
```

```text
Persist(L, t) := L ‖ ⟨ EncodeTx(t) ⟩
```

#### 1.4.4 Invariante di Consistenza della Proiezione del Ledger (Layer A)

```text
INVARIANT-LEDGER-PROJECTION-CONSISTENCY
```

* **Ipotesi H1:** La funzione $\text{EncodeTx} : T \to \text{TransactionBody}$ preserva la semantica formale della transazione $t \in T$.
* **Ipotesi H2:** Il monoide libero ℒ applica rigorosamente l'operazione di concatenazione associativa monotonica append-only.
* **Ipotesi H3:** La funzione di transizione $\text{ApplyValidated}$ è una funzione pura deterministica.
* **Tesi (Proof Obligation Induttiva su $|L|$):** Per qualsiasi Ledger $L \in \mathcal{L}$ e transazione $t \in T$, lo stato proiettato $P$ soddisfa l'equivalenza semantica dello stato primario rispetto al risultato della validazione ambientale:

```text
∀ L ∈ ℒ, ∀ t ∈ T, P(Persist(L, t)) ≡_CoreState ApplyValidated(P(L), t, ValidateEnvironment(P(L), t, E))
```

---

### 1.5 Privacy, Revoca Logica Parziale e Crypto-Erasure Totale

#### 1.5.1 Revoca Logica Parziale (`SOFT_LOGICAL_REVOCATION`) (Layer B2)
La revoca di un singolo elemento informativo da parte dell'utente genera una transizione recante l'evento `EV_ITEM_PRIVACY_REVOKED`. L'applicazione della transazione aggiunge l'identificatore al registro:

```text
𝒬_revoked_items′ = 𝒬_revoked_items ∪ {item_id}
```
```text
ResourceId(e) := 
  e.doc_id     se e ∈ 𝒱_vault
  e.consent_id se e ∈ 𝒬_consent
  e.skill_id   se e ∈ 𝒦_competence
```

In sede di proiezione dello stato o consultazione via API (`Obs`), qualsiasi elemento $e$ tale che:
```text
ResourceId(e) ∈ 𝒬_revoked_items
```
`MUST` restituire il valore nullo $\bot$.

*Nota di Invarianza Strutturale:* La revoca logica parziale oscura la visibilità dei dati nella vista pubblica `Obs(S)`, ma **NON rimuove l'identificatore del nodo dall'insieme dei nodi completati** $V_{\text{completed}}$ in $\mathcal{K}_{\text{playbook}}$, preservando l'integrità del grafo e la deterministica riproducibilità dell'avanzamento.

#### 1.5.2 Oblio Crittografico Totale (`FULL_CRYPTO_SHREDDING`) (Layer B2 & Layer C)
L'oblio totale dell'intero caso utente `SHALL` essere eseguito mediante la distruzione irreversibile della chiave radice $K_{\text{case}}$ nel modulo KMS ed il cancellamento di ogni percorso di recupero:

```text
ShredKey(K_case) ⇒ NoRecovery(K_case) ∧ ∀ v ∈ 𝒱, DecryptPayload(⊥, E_{K_case}(v)) = ⊥
```
L'atto di distruzione `MUST` registrare sul Ledger la transazione formale $t_{\text{shred}}$ recante l'evento `EV_CRYPTO_SHRED_EXECUTED`.

---

### 1.6 Validazione Ambientale Impura vs Funzione Pura ApplyValidated

#### 1.6.1 Predicato Impuro di Validazione Ambientale ValidateEnvironment e Requisiti di Cluster (Layer A & B2)
La validazione delle condizioni di contesto fisiche, temporali e crittografiche esterne allo stato algebrico è governata dal predicato impuro:

```text
ValidateEnvironment : 𝒮 × T × E → ValidationResult
```
```text
ValidationResult := { PASS } ∪ ℰ_validation
```

```text
ValidateEnvironment(S, t, E) =
  PASS      se VerifySignature(t.proof, t.TransactionBody, E.K_pubkey_registry) = TRUE
               ∧ |t.timestamp - E.t_wall| ≤ Θ.θ_max_clock_skew
               ∧ E.LeaseManager.IsTokenValid(S.ℱ_lease.fencing_token) = TRUE
  ERR_SIG   se la firma crittografica è invalida
  ERR_CLOCK se |t.timestamp - E.t_wall| > Θ.θ_max_clock_skew
  ERR_LEASE se il lease di concorrenza è scaduto o invalido
```

```text
REQ-CLUSTER-CLOCK-SYNC := max_{i,j} |t_wall,i - t_wall,j| ≤ δ_clock con δ_clock < (1/2) * Θ.θ_max_clock_skew
```
*(Impone che la sincronizzazione temporale tra i nodi esecutori sia limitata superiormente per prevenire rifiuti inconsistenti per clock skew).*

#### 1.6.2 Funzione Pura di Transizione di Stato ApplyValidated (Layer A)
La mutazione di stato è governata dalla funzione pura e deterministica $\text{ApplyValidated}$, priva di accesso diretto all'ambiente $E$:

```text
ApplyValidated : 𝒮 × T × ValidationResult → 𝒮
```

#### 1.6.3 Requisito Normativo di Totalità di ApplyValidated (`REQ-APPLY-TOTALITY-POLICY`) (Layer B2)
La funzione pura $\text{ApplyValidated}$ è una **funzione totale** su 𝒮 definita dalla seguente specifica a casi con precedenza assoluta di lockdown per corruzione dell'hash:

```text
ApplyValidated(S, t, v_res) :=
  S[ q ↦ SECURITY_LOCKDOWN ]  se t.event = EV_HASH_CORRUPT
  δ_nominal(S, t)             se t.event ≠ EV_HASH_CORRUPT ∧ v_res = PASS ∧ ℛ_exec(S, t) = ALLOW
  δ_err(S, t, v_res)          se t.event ≠ EV_HASH_CORRUPT ∧ (v_res ∈ ℰ_validation ∨ ℛ_exec(S, t) ≠ ALLOW)
```

---

### 1.7 INDICE PROXY OPERATIVO DI GUADAGNO DI AGENCY (AGI_proxy)

L'Indice Proxy $\text{AGI}_{\text{proxy}} \in [0, 10000]$ (espresso in Basis Points interi) misura gli indicatori comportamentali descrittivi di avanzamento dell'utente sul sistema.

#### 1.7.1 Assunzione di Confine Epistemico ed Invariante di Isolamento Descrittivo (Layer B1)

```text
AXIOM-EPISTEMIC-BOUNDARY-AGI
```

```text
INV-AGI-DESCRIPTIVE-ISOLATION
```

```text
∀ S ∈ 𝒮, ∀ t ∈ T, ℛ_exec(S, t) MUST NOT depend on AGI_proxy(S)
```

*Nota di Chiarimento Semantico sull'Acronimo:* Ai fini della presente specifica e di qualsiasi contratto di interfaccia (API/JSON), l'acronimo **`AGI_proxy`** indica esclusivamente l'**Agency Governance Indicator Proxy** (Indicatore Proxy di Governance dell'Agency Operativa) e non ha alcuna relazione teorica, funzionale o concettuale con costrutti di Artificial General Intelligence.

#### 1.7.2 Definizione Normativa di Invarianza per Stati Non-Attivi (Layer B1)

```text
DEF-AGI-PAUSED-STATE-INVARIANCE
```

```text
∀ S_N ∈ S,  AGI_proxy(S_N) := 
    AGI_proxy(S_N-1)  se q_H(S_N) ∈ { HUMAN_PAUSED, HUMAN_DECLINED_ASSISTANCE }
    AGI_computed(S_N) se q_H(S_N) ∉ { HUMAN_PAUSED, HUMAN_DECLINED_ASSISTANCE }
```

#### 1.7.3 Calcolo Deterministico dell'AGI in Aritmetica Intera Sicura (Layer A / RFC-003)

Per tutti gli stati attivi, AGI_computed(S) ∈ [0, 10000] è calcolato unicamente in aritmetica intera sicura a 64 bit I_safe con saturazione dei contatori a 10⁶ ed operatore di troncamento ⌊ ... ⌋:

```text
AGI_computed(S) := ⌊ (w1 · ClarityScore_bp(S) + w2 · ActionExecutionRatio_bp(S) + w3 · DependencyReductionScore_bp(S)) / 10000 ⌋
```
dove w1, w2, w3 ∈ [0, 10000] sono interi tali che w1 + w2 + w3 = 10000.

1. **ClarityScore in Basis Points:**

```text
ClarityScore_bp(S) :=
    10000                                                                     se c_interaction = 0
    max(0, 10000 - ⌊ ((c_rephrase + c_ambiguity + 2 · c_overwhelm) · 10000) / max(1, c_interaction) ⌋)  se c_interaction > 0
```

2. **ActionExecutionRatio in Basis Points:**

```text
ActionExecutionRatio_bp(S) :=
    0                                                                         se pb_id = null ∨ |V_P| = 0
    ⌊ (|{ id ∈ V_completed | ∃ v ∈ G_P.V_P t.c. v.node_id = id }| · 10000) / |V_P| ⌋  se pb_id ≠ null ∧ |V_P| > 0
```

3. **DependencyReductionScore in Basis Points (RFC-003):**

```text
DependencyReductionScore_bp(S) :=
    0                                                                         se |V_active_completed| = 0
    ⌊ (|{ id ∈ V_active_completed | ∃ v ∈ G_P.V_P t.c. v.node_id = id ∧ IsEmpoweredAction(v, S) }| · 10000) / |V_active_completed| ⌋  se |V_active_completed| > 0
```
dove V_active_completed = V_completed ∩ {v.node_id | v ∈ G_P.V_P}, ed il predicato booleano puro IsEmpoweredAction(v, S) è formalizzato come:

```text
IsEmpoweredAction(v, S) ⇔ ( v.action_type ∈ {USER_CONFIRMED_STEP, REQUIRED_FOR_SYSTEM_STATE} ∧ v.gained_skill ≠ null )
```

---

### 1.8 Contratto del Modulo Crittografico Astratto (`CryptoProviderContract`) (Layer A & C)

Ogni implementazione esecutiva di SCINTILLA Core `MUST` integrare un modulo crittografico conforme alla seguente interfaccia astratta:

```text
CryptoProviderContract := ⟨ DeriveKey, EncryptPayload, DecryptPayload, ShredKey, VerifySignature, LookupKey ⟩
```

1. `DeriveKey(K_parent, context) → K_child`: Derivazione deterministica chiavi effimere.
2. `EncryptPayload(K_item, v) → Payload_encrypted`: Cifratura autenticata simmetrica.
3. `DecryptPayload(K_item, Payload_encrypted) → v | ⊥`: Decifratura ed autenticazione payload.
4. `ShredKey(K_id) → TRUE`: Distruzione del materiale di chiave ed elisione dei percorsi di recupero (`NoRecovery`).
5. `VerifySignature(proof, data, K_pub) → 𝔹`: Verifica firma digitale a chiave pubblica.
6. `LookupKey(K_id) → K_active | ⊥`: Verifica presenza ed estrazione del materiale di chiave attivo.

*Nota di Binding Normativo:* Il binding concreto degli algoritmi crittografici (AES-256-GCM, HKDF-SHA256, Ed25519) è definito unicamente nel Profilo Concreto di Riferimento SC-JCS-1 (Layer C / Capitolo 10).

---

# CAPITOLO 2: ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI
## (Layer A & Layer B2)

---

### 2.1 Modello di Isolamento Stratificato a 6 Livelli

L'architettura di SCINTILLA Core è strutturata in 6 livelli funzionali ad isolamento unidirezionale rigoroso, dove i livelli superiori non possiedono alcuna autorità di scrittura diretta sullo stato di runtime:

```text
[ LEVEL 5 ] Large Language Model (Probabilistic Hypothesis Generator)
     │ API Contract: Output SML v2.0 Syntactic Text Only (No State Authority)
[ LEVEL 4 ] Communication, SML Parsing & Semantic Validation Layer
     │ API Contract: Structured Hypothesis & Data Provenance Object
[ LEVEL 3 ] Human Interaction, Consent & Agency Engine (Consent Ledger, AGI & HOBM)
     │ API Contract: Validated Human Context, AGI Score & Consent State
[ LEVEL 2 ] Policy Guidance Engine (Safety Gate, Policy Compilation & Rule Evaluation)
     │ API Contract: Executable Policy DecisionResult with DecisionProof
[ LEVEL 1 ] Deterministic Runtime (Fencing Lease, Monotonic Fence, ValidateEnv & Apply Pure Transition δ)
     │ API Contract: Canonical Serialized Payload & Pure State Mutation
[ LEVEL 0 ] Immutable State Ledger (Append-Only decisions.ndjson Content-Addressed Hash Chain)
```

---

### 2.2 Runtime Safety State Machine M (Layer A & B2)

L'operatività di sicurezza di runtime è modellata dall'automa **Deterministic Priority Finite State Machine (DP-FSM)** $M$:

```text
M := ⟨ Q, Σ, T_δ, δ_M, q₀, F_oper ⟩
```

1. **Insieme degli Stati Canonici $Q$ ($|Q|=7$):**
```text
Q = { NORMAL (q₀), REQUIRE_RECALIBRATION (q₁), VALIDATION_ERROR (q₂), RECOVERABLE_FAILURE (q₃), OPERATOR_REQUIRED (q₄), SECURITY_LOCKDOWN (q₅), SAFE_READ_ONLY_MODE (q₆) }
```
2. **Stato Iniziale:** $q_0 = \text{NORMAL}$
3. **Insieme degli Stati Operativamente Stabili $F_{\text{oper}}$:**
```text
F_oper = { NORMAL, SAFE_READ_ONLY_MODE }
```

#### 2.2.1 Definizione di Dominio DP-FSM e Precondizione Statica di Unicità
Ai fini della specifica SCINTILLA Core, un automa DP-FSM indica una macchina a stati finiti la cui relazione di transizione è deterministica a valle dell'applicazione della funzione di risoluzione prioritaria `Resolve(q, σ)`.

Un contratto di automa è valido ed eseguibile se e solo se soddisfa la precondizione statica di unicità:

```text
ValidFSMContract ⇔ (∀ q ∈ Q, ∀ σ ∈ Σ, |δ_explicit(q, σ)| ≤ 1) ∧ (∀ σ ∈ Σ, |δ_wildcard(σ)| ≤ 1)
```

#### 2.2.2 Regola di Precedenza Wildcard, Funzione Algebrica Resolve e Regola di Parsing Target Wildcard

```text
RULE-EXPLICIT-SHADOWS-WILDCARD
```
**"The explicit transition rules SHALL strictly shadow wildcard transition rules according to the four-tier resolution order."**

```text
RULE-WILDCARD-TARGET-REFLEXIVITY
```
**"When a wildcard token `"*"` appears in the target state field (`"to": "*"`) of a machine transition contract, the runtime parser MUST interpret the transition as an identity/stuttering step ($q′ = q$), maintaining the current state unchanged."**

La risoluzione deterministica della transizione negli automi DP-FSM è governata dalla funzione algebrica pura con gerarchia a 4 livelli (estesa dalla regola di riflessività sul target):

```text
Resolve(q, σ, F_T) :=
  q           se q ∈ F_T  (Terminal Trap Rule)
  δ(q, σ)     se δ(q, σ) è definita su (Stato Esplicito q, Evento Esplicito σ) ∧ q ∉ F_T
  δ(*, σ)     se δ(*, σ) è definita su (Stato Wildcard *, Evento Esplicito σ) ∧ q ∉ F_T
  δ(q, *)     se δ(q, *) è definita su (Stato Esplicito q, Evento Wildcard *) ∧ q ∉ F_T
  δ(*, *)     se δ(*, *) è definita su (Stato Wildcard *, Evento Wildcard *) ∧ q ∉ F_T
  q           altrimenti  (Implicit Stuttering)
```

*Nota esplicativa:* Quando l'immagine della funzione $\delta$ restituisce il token wildcard (es. $\delta(*, \sigma) = *$), la funzione `Resolve` applica l'identità $q′ = q$.

#### 2.2.3 Partizione dell'Alfabeto Sigma (Layer B2)
L'alfabeto degli eventi di sistema $\Sigma$ ($|\Sigma|=10$) è partizionato nei seguenti sotto-insiemi disgiunti:

1. **Eventi di Business ($\Sigma_{\text{business}}$):** Eventi di mutazione operativa e di progresso del caso utente:
```text
Σ_business := { EV_SUCCESS, EV_ABANDON, EV_SML_FAIL, EV_LEASE_EXP, EV_TIMEOUT }
```
2. **Eventi di Ripristino Operativo ($\Sigma_{\text{recovery}}$):** Eventi di override ed intervento autorizzato per il ripristino di stato:
```text
Σ_recovery := { EV_OVERRIDE, EV_REPAIR }
```
3. **Eventi Amministrativi e di Tutela Diritti ($\Sigma_{\text{administrative}}$):** Eventi relativi all'integrità crittografica e alla gestione dei diritti dell'utente:
```text
Σ_administrative := { EV_HASH_CORRUPT, EV_ITEM_PRIVACY_REVOKED, EV_CRYPTO_SHRED_EXECUTED }
```

#### 2.2.4 Gestione della Stasi Operativa in SAFE_READ_ONLY_MODE (q6) (Layer B2)
La permanenza dell'automa $M$ nello stato:
```text
q₆ = SAFE_READ_ONLY_MODE
```
è governata esclusivamente dalle regole di transizione del contratto $\delta_M$ (§10.4) e dalle meta-regole SOS (§3.2):
1. **Eventi di Business** ($\Sigma_{\text{business}}$): Impongono uno *stuttering step* ($q_6 \to q_6$), precludendo qualsiasi mutazione dello stato operativo.
2. **Eventi Amministrativi** ($\Sigma_{\text{administrative}}$): Sono ammessi ed elaborati per garantire l'esercizio inalienabile dei diritti dell'utente (revoca privacy, oblivion).
3. **Eventi di Ripristino** ($\Sigma_{\text{recovery}}$): Transitano lo stato verso $\text{NORMAL}$ previa verifica autorizzativa dell'operatore o applicazione di patch formale.

---

### 2.3 Human Journey State Machine H (Layer A & B2)

L'evoluzione concettuale del percorso umano dell'utente è modellata dall'automa DP-FSM di dominio $\mathcal{H}$:

```text
ℋ := ⟨ Q_H, Σ_H, δ_H, q_H0, F_H ⟩
```

1. **Insieme degli Stati del Percorso Umano** $Q_H$ ($|Q_H|=12$):
```text
Q_H = { UNASSESSED, INITIAL_ASSESSMENT, STABILIZATION, DOCUMENT_RECOVERY, EMPLOYMENT_READINESS, FINANCIAL_AUTONOMY, SUSTAINED_INDEPENDENCE, HUMAN_PAUSED, HUMAN_RECALIBRATION_REQUIRED, HUMAN_GOAL_CHANGED, HUMAN_DECLINED_ASSISTANCE, PREVENTIVE_STANDBY }
```

2. **Stato Iniziale:** $q_{H0} = \text{UNASSESSED} = h_0$
3. **Insieme degli Stati Target / Terminali** $F_H$:
```text
F_H = { HUMAN_DECLINED_ASSISTANCE } = { h₁₀ }
```

4. **Alfabeto degli Eventi Umani** $\Sigma_H$ ($|\Sigma_H|=15$):
```text
Σ_H = { HEV_ASSESS_START, HEV_STABILIZED, HEV_DOCS_OBTAINED, HEV_JOB_READY, HEV_FINANCE_OK, HEV_INDEPENDENCE_ACHIEVED, HEV_RELAPSE_REGRESS, HEV_RECALIBRATION_REQ, HEV_PAUSE_REQUESTED, HEV_RESUME_REQUESTED, HEV_GOAL_UPDATE, HEV_DECLINE_ALL, HEV_EMOTIONAL_OVERWHELM, HEV_PREVENTIVE_SUPPORT_REQ, HEV_STEP_COMPLETED }
```

#### 2.3.1 Dinamica dello Stato h11 (PREVENTIVE_STANDBY) come "Base Sicura" (Layer B2)
Lo stato:
```text
h₁₁ = PREVENTIVE_STANDBY
```
definisce la condizione di **Santuario in Standby (Base Sicura)**:

1. **Semantica di Custodia Discreta:** Quando l'automa umano $\mathcal{H}$ raggiunge lo stato $h_{11}$, l'utente ha acquisito piena autonomia operativa. Il sistema cessa di proporre micro-azioni quotidiane o notifiche proattive, ma mantiene attiva la vista di ascolto discreto.
2. **Invarianza di Accessibilità dello Stato Finale:** Nel raggiungimento dello stato target:
```text
h₆ = SUSTAINED_INDEPENDENCE
```
l'automa umano induce la transizione allo stato
```text
h₁₁ = PREVENTIVE_STANDBY
```
preservando a tempo indeterminato l'accesso alla vista osservabile `Obs(S)`, al Vault `𝒱_vault` e al registro delle competenze `𝒦_competence`.
3. **Re-ingaggio Immediato:** Qualsiasi espressione di disagio, sopraffazione emotiva o richiesta esplicita dell'utente transitano immediatamente l'automa da $h_{11}$ allo stato di supporto attivo `HUMAN_RECALIBRATION_REQUIRED`, riattivando la guida senza che l'utente debba giustificare la propria ricaduta.

#### 2.3.2 Regola Normativa di Preservazione del Progresso Umano (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`)
Quando l'automa $\mathcal{H}$ si trova nello stato $h_8$ (`HUMAN_RECALIBRATION_REQUIRED`) e riceve l'evento:
```text
HEV_STABILIZED
```
il runtime `MUST` determinare lo stato di destinazione $q_H′$ mediante la funzione pura:
```text
ResolveNextHumanState(q_H, π_persistent(S).𝒦_playbook)
```
Tale funzione assegna $q_H′$ allo stato corrispondente al nodo attivo in:
```text
𝒦_playbook.node_curr
```

È tassativamente vietato retrocedere l'utente allo stato $h_2$ (`STABILIZATION`) qualora i prerequisiti degli stati successivi risultino già soddisfatti in $V_{\text{completed}}$.

---

### 2.4 Equazione Matematica del Sistema Reattivo Composito (Layer A)

Il sistema reattivo globale di SCINTILLA Core è modellato dallo spazio di stato composito $S_C = Q \times Q_H$.

La funzione di transizione pura dell'automa composito $\delta_C : (Q \times Q_H) \times (\Sigma \cup \Sigma_H) \longrightarrow (Q \times Q_H)$ è definita dall'equazione a casi:

```text
δ_C((q, q_H), σ_C) =
  (δ_M(q, σ_C, T_δ), q_H)              se σ_C ∈ Σ
  (q, Resolve(q_H, σ_C, F_H))          se σ_C ∈ Σ_H ∧ q ∈ (F_oper ∪ {REQUIRE_RECALIBRATION})
  (q, Resolve(q_H, σ_C, F_H))          se σ_C ∈ Σ_H ∧ q ∈ {VALIDATION_ERROR, RECOVERABLE_FAILURE}
  (q, Resolve(q_H, σ_C, F_H))          se σ_C ∈ {HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL} ∧ q ∈ {OPERATOR_REQUIRED, SECURITY_LOCKDOWN}
  (q, q_H)                             se σ_C ∈ Σ_H ∖ {HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL} ∧ q ∈ {OPERATOR_REQUIRED, SECURITY_LOCKDOWN}
```

1. **Invariante di Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`):** Gli eventi dell'automa umano $\Sigma_H$ non mutano lo stato di runtime $Q$. Viceversa, errori tecnici di sistema:
```text
q ∈ {VALIDATION_ERROR, RECOVERABLE_FAILURE}
```
`SHALL NOT` paralizzare l'evoluzione concettuale dello stato umano $Q_H$.

2. **Eccezione di Sovranità Umana in Lockdown:** In presenza di blocco critico di sicurezza:
```text
q = SECURITY_LOCKDOWN
```
le sole transizioni dell'automa umano ammesse per la registrazione ed applicazione immediata sono quelle di richiesta di pausa o revoca del supporto (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

# CAPITOLO 3: SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)
## (Layer B3 - Regole Operative SOS)

---

### 3.0 Mappa di Osservazione e Corrispondenza Relazione-Funzione

La Mappa di Osservazione Canonica $\pi_{\text{SOS}}$ estrae la tripla dello stato di valutazione della semantica operazionale:

```text
π_SOS : 𝒮 → (Q × Q_H × 𝒮_persistent)
```
```text
π_SOS(S) := ⟨ π_Q(S), π_Q_H(S), π_persistent(S) ⟩
```

#### 3.0.1 Proprietà Derivata di Determinismo della Relazione SOS (`PROPERTY-SOS-DETERMINISM`) (Layer B1)
```text
PROPERTY-SOS-DETERMINISM
```
```text
∀ S ∈ 𝒮, ∀ t ∈ T, (π_SOS(S) --t/Sys--> σ₁ ∧ π_SOS(S) --t/Sys--> σ₂) ⇒ σ₁ = σ₂
```
(Deriva direttamente dalla purezza e dal determinismo delle funzioni $\delta_M$, $\delta_H$ e $\text{ApplyValidated}$).

#### 3.0.2 Requisito di Progresso SOS Condizionato (`REQ-SOS-CONDITIONED-PROGRESS`) (Layer B2)
```text
REQ-SOS-CONDITIONED-PROGRESS
```
```text
∀ (π_SOS(S), t) ∈ Domain(--t/Sys-->), ∃! σ′ ∈ (Q × Q_H × 𝒮_persistent) t.c. π_SOS(S) --t/Sys--> σ′
```

#### 3.0.3 Proprietà di Corrispondenza Relazionale-Funzionale (Layer A)

```text
PROPERTY-SOS-SEMANTIC-CORRESPONDENCE
```
* **Ipotesi H1:** La relazione di transizione SOS $\to_{\text{Sys}}$ soddisfa la Proprietà di Determinismo (`PROPERTY-SOS-DETERMINISM`).
* **Ipotesi H2:** Il predicato di validazione d'ambiente restituisce l'esito $\text{ValidateEnvironment}(S, t, E) = \text{PASS}$.
* **Ipotesi H3:** La funzione $\text{ApplyValidated}$ ammette come parametro d'ingresso il risultato della validazione.
* **Tesi (Proof Obligation su analisi per casi):** La transizione relazionale SOS 
```text
π_SOS(S) --t/Sys--> ⟨ q′, q_H′, S_persistent′ ⟩
```
sussiste se e solo se lo stato successivo $S′ = \text{ApplyValidated}(S, t, \text{PASS})$ soddisfa la coincidenza di proiezioni:
```text
S′ = ApplyValidated(S, t, PASS) ∧ q′ = π_Q(S′) ∧ q_H′ = π_Q_H(S′) ∧ S_persistent′ = π_persistent(S′)
```

---

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore (Layer B2)

Una transizione $t \in T$ con evento $\sigma_C = \text{event}(t)$ ed emessa dall'attore $\alpha = \text{actor}(t)$ è autorizzata se e solo se soddisfa il predicato booleano $\text{Authorized}(\sigma_C, \text{type}(\alpha))$:

```text
Authorized(σ_C, type(α)) ⇔
  True  se σ_C ∈ Σ_H ∧ type(α) ∈ {USER, OPERATOR, SYSTEM}
  True  se σ_C ∈ Σ_business ∪ Σ_administrative ∧ type(α) = SYSTEM
  True  se σ_C = EV_ITEM_PRIVACY_REVOKED ∧ type(α) ∈ {USER, OPERATOR}
  True  se σ_C ∈ Σ_recovery ∧ type(α) = OPERATOR
  False in tutti gli altri casi (compreso qualsiasi tentativo con type(α) = LLM)
```

---

### 3.2 META-REGOLE SOS DELLA SICUREZZA DI RUNTIME (M) (Layer B3)

```text
σ_C = event(t) ∈ Σ    ValidateEnvironment(S, t, E) = PASS    Authorized(σ_C, type(α))    q′ = Resolve(q, σ_C, ∅)    EvaluateGuards(S, t) = PASS
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-META-SAFETY]
                                             ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q′, q_H, ApplyValidated(S, t, PASS) ⟩
```

```text
σ_C = event(t) ∈ Σ    (v_res ∈ ℰ_validation ∨ ¬Authorized(σ_C, type(α)) ∨ EvaluateGuards(S, t) = FAIL)    q′ = (q ∈ {SECURITY_LOCKDOWN, SAFE_READ_ONLY_MODE} ? q : VALIDATION_ERROR)
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-META-SAFETY-FAIL]
                                       ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q′, q_H, ApplyValidated(S, BuildErrorTx(S, E, v_res, σ_C), v_res) ⟩
```

#### 3.2.1 Meta-Regole SOS di Ripristino ed Override da Operatore (Layer B3)

```text
σ_C = event(t) = EV_REPAIR    q ∈ {SECURITY_LOCKDOWN, SAFE_READ_ONLY_MODE}    type(α) = OPERATOR    p = t.payload    ValidRepairPatch(p)
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-COMPENSATIVE-REPAIR]
                                           ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ NORMAL, q_H, ApplyCompensativeRepair(S, p) ⟩
```

```text
σ_C = EV_OVERRIDE    q = OPERATOR_REQUIRED    type(α) = OPERATOR    ValidateEnvironment(S, t, E) = PASS
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-OPERATOR-OVERRIDE]
                           ⟨ OPERATOR_REQUIRED, q_H, S ⟩ --t/Sys--> ⟨ NORMAL, q_H, ApplyValidated(S, t, PASS) ⟩
```

---

### 3.3 Meta-Regole SOS per Competenze e Custodia Credenziali (Layer B3)

#### 3.3.1 Meta-Regola SOS per la Palestra delle Competenze (`[SOS-COMPETENCE-UPDATE]`)
Quando l'utente completa un nodo di Playbook $v \in V_P$ recante un attributo di competenza acquisita:

```text
σ_C = HEV_STEP_COMPLETED    v.gained_skill = ⟨k, l⟩    𝒦_competence′ = 𝒦_competence ∪ { ⟨k, l, t_wall⟩ }
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-COMPETENCE-UPDATE]
                   ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q, q_H, ApplyValidated(S, t[𝒦_competence ↦ 𝒦_competence′], PASS) ⟩
```

#### 3.3.2 Meta-Regola SOS per la Custodia Credenziali (`[SOS-VAULT-RECORD]`)
All'ottenimento o verifica oggettiva di un documento d'identità o attestato formale:

```text
σ_C = HEV_DOCS_OBTAINED    doc = ⟨doc_id, H_doc, VERIFIED⟩    𝒱_vault′ = 𝒱_vault ∪ { doc }
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-VAULT-RECORD]
                   ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q, DOCUMENT_RECOVERY, ApplyValidated(S, t[𝒱_vault ↦ 𝒱_vault′], PASS) ⟩
```

---

### 3.4 META-REGOLE SOS DEL PERCORSO UMANO (H) E SOVRANITÀ (Layer B3)

```text
σ_C = event(t) ∈ Σ_H    q ∈ F_oper    ValidateEnvironment(S, t, E) = PASS    Authorized(σ_C, type(α))    q_H′ = Resolve(q_H, σ_C, F_H)    ℛ_exec(S, t) = ALLOW
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-META-HUMAN]
                                                 ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q, q_H′, ApplyValidated(S, t, PASS) ⟩
```

```text
σ_C ∈ { HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL }    q ∉ F_oper    ValidateEnvironment(S, t, E) = PASS
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-HUMAN-SOVEREIGNTY-LOCKDOWN]
                         ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q, Resolve(q_H, σ_C, F_H), ApplyValidated(S, t, PASS) ⟩
```

#### 3.4.1 Meta-Regola SOS di Stasi in Stato Pausa (SOS-HUMAN-PAUSED-STUTTER / RFC-002)

Quando l'automa del percorso umano si trova nello stato:
```text
q_H = HUMAN_PAUSED
```
e giunge un qualsiasi evento $t$ non corrispondente a `HEV_RESUME_REQUESTED`, `HEV_DECLINE_ALL` o `HEV_EMOTIONAL_OVERWHELM`, l'automa esegue uno stuttering step preservando lo stato di stasi ed emettendo una transazione recante l'involucro di esecuzione $e_{\text{paused}}$:

```text
q_H = HUMAN_PAUSED    σ_C ∈ Σ_H ∖ { HEV_RESUME_REQUESTED, HEV_DECLINE_ALL, HEV_EMOTIONAL_OVERWHELM }    e_paused = ⟨ "PROCESSED_NO_STATE_EFFECT", "HUMAN_JOURNEY_PAUSED", false ⟩
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-HUMAN-PAUSED-STUTTER]
                                                      ⟨ q, HUMAN_PAUSED, S ⟩ --t/Sys--> ⟨ q, HUMAN_PAUSED, ApplyValidated(S, t[e ↦ e_paused], PASS) ⟩
```

#### 3.4.2 Meta-Regola SOS di Timeout ed Inattività Umana (SOS-HUMAN-TIMEOUT)

Quando l'automa umano si trova in:
```text
q_H = HUMAN_PAUSED
```
ed il tempo di permanenza supera la soglia parametrizzata 
```math
\theta_{\text{inactivity\_timeout}}
```

```text
q_H = HUMAN_PAUSED    (E.t_wall - π_internal(S).t_pause_start) > θ_inactivity_timeout    t_timeout = BuildSystemTx(S, E, HEV_RECALIBRATION_REQ)
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-HUMAN-TIMEOUT]
                                      ⟨ q, HUMAN_PAUSED, S ⟩ --t_timeout/Sys--> ⟨ q, HUMAN_RECALIBRATION_REQUIRED, ApplyValidated(S, t_timeout, PASS) ⟩
```

#### 3.4.3 Meta-Regola SOS di Adattamento per Sopraffazione Emotiva (SOS-EMOTIONAL-OVERWHELM)

Alla rilevazione di uno stato di sopraffazione emotiva segnalato dall'utente o dal parser SML:

```text
σ_C = HEV_EMOTIONAL_OVERWHELM
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-EMOTIONAL-OVERWHELM]
                      ⟨ q, q_H, S ⟩ --t/Sys--> ⟨ q, HUMAN_RECALIBRATION_REQUIRED, ApplyValidated(S, t, PASS) ⟩
```

---

# CAPITOLO 4: POLICY GUIDANCE ENGINE & STRATIFICAZIONE DELLE POLICY
## (Layer A & Layer B2)

---

### 4.1 Stratificazione delle Policy in 3 Livelli

Per impedire l'esecuzionalità diretta di regole espresse in linguaggio naturale o soggette ad ambiguità interpretativa, il Policy Guidance Engine adotta una stratificazione rigorosa su tre livelli di astrazione:

1. **Policy Specification Layer (Livello Normativo Umano):** Testo normativo, principi etici e linee guida operative espresse in linguaggio naturale controllato per gli operatori umani.
2. **Policy Compilation Layer (Livello di Compilazione):** Processo di traduzione automatizzata e validata che trasforma le specifiche normative in predicati formali e insiemi di parametri $\Theta$.
3. **Executable Policy Predicate Layer (Livello Esecutivo Puro):** Il codice o byte-code deterministico derivato:
```text
ℛ_exec : 𝒮 × T → { ALLOW, DENY, RECALIBRATE }
```
l'unico direttamente eseguibile dal runtime al Livello 2.

---

### 4.2 Definizione Algebrica del Policy Bundle (Layer A)

Un `PolicyBundle` $\mathcal{P}$ è formalizzato come la tupla algebrica:

```text
𝒫 := ⟨ PolicyID, Version, Θ, ℛ_exec, Sig_𝒫 ⟩
```

* $\text{PolicyID} \in \mathcal{I}$: Identificatore unico della policy (UUIDv7).
* $\text{Version} \in V$: Versione della policy nello Spazio delle Versioni $V$ (§6.1).
* $\Theta$: Lo spazio dei parametri di configurazione e soglie, es.
```math
\theta_{\text{duration}}, \theta_{\text{confidence}}, \theta_{\text{max\_clock\_skew}}
```
* $\mathcal{R}_{\text{exec}}$: Predicato esecutivo puro valutato sullo stato e sulla transazione.
* $\text{Sig}_\mathcal{P}$: La firma crittografica dell'autorità di policy emittente calcolata su $\text{Canon}(\mathcal{P})$.

---

### 4.3 Composizione di Policy e Regola di Versione Composita (Layer A & B2)

L'operatore di composizione algebrica $\oplus$ produce il bundle composito $\mathcal{P}_{\text{comp}} = \mathcal{P}_1 \oplus \mathcal{P}_2$ mediante la funzione esplicita $\text{ComposePolicy}$:

```text
ComposePolicy(𝒫₁, 𝒫₂) := ⟨ PolicyID_comp, CompositePolicyVersion, CompositePolicyDigest, Θ₁ ∪ Θ₂, ℛ_exec,comp, Sig_comp ⟩
```

1. **Impronta Crittografica Composita (Content-Addressed Binary Digest):**
   L'identità immutabile del bundle composito è determinata dalla concatenazione binaria esplicita dei due digest a 256 bit disposti in ordine lessicografico non codificato:
```text
CompositePolicyDigest := SHA256(A_sorted ‖ B_sorted)
```
dove $A_{\text{sorted}}$ e $B_{\text{sorted}}$ sono i due array di 32 byte binari ordinati secondo la relazione:
```text
A_sorted ≤ B_sorted ⇔ ByteLexicographicalCompare(A, B) ≤ 0
```

2. **Requisito Normativo di Assegnazione Versione Composita (`REQ-POLICY-SEMVER-DERIVATION`) (Layer B2):**
   La versione formale $\text{CompositePolicyVersion} \in V$ segue la convenzione di dominio definita per segnalare incompatibilità tra bundle eterogenei:
```text
CompositePolicyVersion := { v₂                        se v₁ ⪯_compat v₂
                          { v₁                        se v₂ ⪯_compat v₁
                          { ⟨ max(M₁, M₂) + 1, 0, 0 ⟩  se v₁ e v₂ sono incompatibili (M₁ ≠ M₂)
```

3. **Valutazione Composita Disgiunta (`DENY-OVERRIDES`):**
   La funzione di valutazione esecutiva composita $\mathcal{R}_{\text{exec, comp}}(S, t)$ è governata dalla regola disgiunta conservativa:
```text
ℛ_exec,comp(S, t) := { DENY        se ℛ_exec,1(S, t) = DENY ∨ ℛ_exec,2(S, t) = DENY
                     { RECALIBRATE se (ℛ_exec,1(S, t) = RECALIBRATE ∨ ℛ_exec,2(S, t) = RECALIBRATE)
                     {                ∧ ℛ_exec,1(S, t) ≠ DENY ∧ ℛ_exec,2(S, t) ≠ DENY
                     { ALLOW       se ℛ_exec,1(S, t) = ALLOW ∧ ℛ_exec,2(S, t) = ALLOW
```

---

### 4.4 Decodifica Deterministica Input SML v2.0 in Evento Umano (Layer A & B2)

Per eliminare l'ambiguità tra i suggerimenti linguistici generati dal Livello 5 (LLM) e gli eventi accettati dal runtime (Livello 3/1), il Livello 4 applica la funzione pura di decodifica deterministica $\text{MapSMLToFSMEvent}$.

La funzione mappa tutti gli esiti conversazionali SML v2.0 definiti nella sintassi sintattica (§C.1) agli eventi esecutivi dell'automa umano $\Sigma_H \cup \{ \text{NONE} \}$:

```text
MapSMLToFSMEvent : SMLDocumentParsed → Σ_H ∪ { NONE }
```

```text
MapSMLToFSMEvent(d) := { HEV_EMOTIONAL_OVERWHELM     se d.conversation_outcome = OVERWHELMED
                       { HEV_RECALIBRATION_REQ       se d.conversation_outcome = NEEDS_REPHRASING
                       { HEV_PAUSE_REQUESTED         se d.conversation_outcome = DECLINED_ACTION
                       { HEV_PREVENTIVE_SUPPORT_REQ  se d.conversation_outcome = ASKED_FOR_HELP
                       { HEV_DOCS_OBTAINED           se d.proposed_transition ≠ "NONE" ∧ d.evidence_type = DOCUMENT
                       { HEV_STABILIZED              se d.proposed_transition ≠ "NONE" ∧ d.conversation_outcome = MOTIVATED
                       { NONE                        altrimenti
```

---

### 4.5 Tassonomia della Guida ed Ergonomia Cognitiva (Layer B2)

Al fine di ridurre lo stress ed il carico cognitivo dell'utente vulnerabile senza usurparne la sovranità decisionale, il sistema definisce tre livelli formali di guida comunicativa:

1. **Direttiva Autoritativa (Authoritative Directive):** Formulazione prescrittiva ammessa **esclusivamente** in condizioni di imminente rischio per la sicurezza o situazioni di emergenza acuta (`PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Raccomandazione Motivata e Contestualizzata (Motivated Recommendation):** Formulazione consigliata che propone un percorso operativo riducendo il carico cognitivo. La raccomandazione `MUST` esplicitare la motivazione, il grado di certezza ed essere immediatamente revocabile o modificabile dall'utente (`USER_CONFIRMED_STEP`).
3. **Opzione Esplorativa (Exploratory Option):** Presentazione neutrale di alternative multiple, indicata quando l'utente si trova in uno stato di stabilità emotiva e desidera confrontare autonomamente le possibilità.

#### 4.5.1 Regola di Non-Pregiudizio sul Rifiuto dei Suggerimenti (`RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01`)

```text
∀ S₁, S₂ ∈ 𝒮, se S₂ = ApplyValidated(S₁, t, PASS) con event(t) ∈ {HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL} ⇒ Capabilities(Obs(S₂)) = Capabilities(Obs(S₁))
```

1. **Invarianza della Proiezione Osservabile:** La ricezione di un evento di rifiuto o rinvio relativo a un suggerimento di collegamento con servizi esterni o comunità reali `SHALL NOT` ridurre l'insieme delle autorizzazioni, dei diritti e delle capacità rese osservabili dalla funzione $\text{Obs}(S)$.
2. **Divieto di Ultimatum:** Nessun nodo del grafo di Playbook $G_P$ `SHALL` condizionare il proseguimento del percorso all'accettazione di interazioni esterne, salvo nei casi in cui tali interazioni costituiscano un prerequisito tecnico o legale esplicitamente tipizzato come `REQUIRED_FOR_SYSTEM_STATE`.

---

### 4.6 Filosofia Normativa dell'Intervento Umano (Human Override) (Layer B2)

L'intervento di un operatore umano (`OPERATOR`) costituisce un meccanismo di garanzia e supporto e `MUST` conformarsi ai seguenti 5 principi normativi inderogabili:

1. **Tracciabilità Assoluta:** Ogni azione di override `MUST` generare una transizione registrata sul Ledger $\mathcal{L}$ recante l'identificativo dell'operatore.
2. **Autenticazione Forte:** L'override richiede una firma digitale valida ed il possesso del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. **Spiegabilità Obbligatoria:** Ogni intervento `MUST` includere la motivazione esplicita in formato testuale non vuoto.
4. **Inalterabilità Storica:** L'override modifica unicamente lo stato proiettato corrente $S_N$, ma `SHALL NOT` alterare o elidere le transizioni storiche precedenti.
5. **Rispetto del Consenso:** L'operatore `SHALL NOT` forzare l'esecuzione di azioni in violazione del consenso espresso dall'utente, salvo nei cases previsti dal livello HOBM `PROFESSIONAL_INTERVENTION_REQUIRED`.

---

# CAPITOLO 5: EMANCIPATION PLAYBOOK ENGINE
## (Layer A & Layer B2)

---

### 5.1 Struttura del Grafo del Playbook (Layer A)

Un **Emancipation Playbook** è formalizzato come un grafo orientato ed etichettato:

```text
G_P := (V_P, E_P, C_P)
```

* $V_P$: Insieme dei Nodi di Micro-Azione ($v \in V_P$).
* $E_P \subseteq V_P \times V_P$: Archi diretti rappresentanti la sequenza logica di progressione.
* $C_P$: Insieme delle Condizioni di Verificabilità, dove ogni elemento $c \in C_P$ è un predicato booleano puro $c: \mathcal{S} \to \{ \text{True}, \text{False} \}$.

---

### 5.2 Tipizzazione dei Nodi Playbook (Layer B2)

Ogni nodo $v \in V_P$ `MUST` appartenere ad una delle seguenti categorie formali:

1. **`INFORMATION`:** Nodo a contenuto puramente informativo o educativo. Non richiede azioni o conferme per il proseguimento.
2. **`OPTIONAL_STEP`:** Micro-passo suggerito per ottimizzare il percorso, saltabile dall'utente senza alcun blocco del flusso.
3. **`USER_CONFIRMED_STEP`:** Micro-passo che richiede il consenso o la conferma esplicita dell'utente prima di essere marcato come completato.
4. **`REQUIRED_FOR_SYSTEM_STATE`:** Prerequisito tecnico o legale bloccante. Solo i nodi appartenenti a questa categoria possono condizionare le transizioni dell'automa di sicurezza $M$.

---

### 5.3 Invarianti di Esecuzione e Tracking dello Stato Playbook (Layer A & Layer B2)

#### 5.3.1 Invariante di Aciclicità Locale sui Nodi Bloccanti (`INV-PLAYBOOK-GRAPH-01`) (Layer A & B2)
Il sotto-grafo formato dai soli nodi tipizzati `REQUIRED_FOR_SYSTEM_STATE` `MUST` essere uno Strict Directed Acyclic Graph (DAG).

```text
INV-PLAYBOOK-GRAPH-01 := IsAcyclic(G_P ↾ REQUIRED_FOR_SYSTEM_STATE) = TRUE
```
La rilevazione di cicli sui nodi bloccanti determina il rifiuto immediato del caricamento del Playbook ed il sollevamento del **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.

#### 5.3.2 Durata Parametrizzata dei Micro-Passi (Layer B2)
La durata stimata di una micro-azione non può superare il valore definito dal parametro di policy:
```text
θ_max_duration ∈ Θ
```

#### 5.3.3 Tracciamento dello Stato di Avanzamento (Layer A)
Ogni avanzamento nel grafo $G_P$ `MUST` aggiornare la componente $\mathcal{K}_{\text{playbook}}$ nello stato $\mathcal{S}$, dove:
```text
𝒦_playbook := ⟨ pb_id, node_curr, V_completed ⟩ ∈ (ℐ ∪ {null}) × (ℐ ∪ {null}) × 𝒫(ℐ)
```

---

# CAPITOLO 6: TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ
## (Layer A & Layer B2)

---

### 6.1 Spazio delle Versioni e Tupla dei Profili di Runtime (Layer A)

Ogni componente versionabile di SCINTILLA Core appartiene allo spazio vettoriale discreto delle versioni $V := \mathbb{N} \times \mathbb{N} \times \mathbb{N}$ rappresentato dalla tupla $v = \langle \text{major}, \text{minor}, \text{patch} \rangle$.

Il contesto esecutivo completo di una transazione o di un registro è vincolato dalla **Tupla dei Profili di Runtime (Runtime Profile Tuple)**:

```text
RuntimeProfile := ⟨ semantic_profile, schema_profile, canonicalization_profile, policy_profile ⟩
```

#### 6.1.1 Regola di Compatibilità Temporale per il Replay Storico (`RULE-HISTORICAL-REPLAY-COMPATIBILITY`) (Layer B2)
```text
RULE-HISTORICAL-REPLAY-COMPATIBILITY
```
In fase di ricostruzione deterministica dello stato $P(L)$ a partire dal Ledger:
1. Ogni transazione $t_i \in L$ `MUST` essere interpretata e validata applicando le regole di semantica operazionale SOS e gli schemi di validazione corrispondenti al profilo `t_i.runtime_profile` registrato nella transazione stessa (o nel Manifest di segmento del Ledger).
2. L'introduzione di una nuova versione dello standard `SHALL NOT` alterare retroattivamente il risultato delle transizioni storiche già consolidate sotto una versione precedente.

---

### 6.2 Relazione di Compatibilità Retroattiva (Layer A)

Siano $v_1 = \langle M_1, m_1, p_1 \rangle$ e $v_2 = \langle M_2, m_2, p_2 \rangle$ due versioni nello spazio $V$.

La relazione di compatibilità retroattiva $v_1 \preceq_{\text{compat}} v_2$ è definita formalmente come l'ordine parziale:

```text
v₁ ⪯_compat v₂ ⇔ (M₁ = M₂) ∧ ((m₁ < m₂) ∨ (m₁ = m₂ ∧ p₁ ≤ p₂))
```

---

# CAPITOLO 7: CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA
## (Layer A & Layer B2)

---

### 7.1 SPAZIO NORMALIZZATO E CANONIZZAZIONE (Layer A)

Sia $\mathcal{S}_{\text{normalized}} \subseteq \mathcal{S}$ il sottoinsieme di stati conformi alle regole di normalizzazione del profilo di riferimento SC-JCS-1 (§10.2). 

La funzione di canonizzazione deterministica $\text{Canon} : \mathcal{S}_{\text{normalized}} \longrightarrow \mathcal{B}^*$ converte lo stato strutturato nella sua rappresentazione binaria unica. L'iniettività semantica di $\text{Canon}$ costituisce una proprietà obiettivo garantita dall'applicazione dell'algoritmo deterministico SC-JCS-1 (§10.3), assicurando che due stati semanticamente identici producano il medesimo flusso di byte UTF-8.

#### 7.1.1 Teorema di Totalità ed Univocità della Serializzazione (Layer A / RFC-010)

```text
THEOREM-SERIALIZATION-TOTALITY-AND-UNIQUENESS := ∀ t ∈ T, EncodeTx(t) ∈ J_SC ⇒ ∃! b ∈ ℬ* t.c. Canon(EncodeTx(t)) = b
```

---

### 7.2 Catena di Hash Immutabile ed Integrità delle Transazioni (Layer A)

La continuità e l'integrità del Ledger $\mathcal{L}$ per la transazione $N$-esima è determinata dal calcolo del checksum $H_N \in \mathcal{D}_{256}$ eseguito sul corpo della transazione $\text{TransactionBody}_N$:

```text
H₀ = 0_𝒟₂₅₆ (Digest nullo di Genesi a 256 bit)
```
```text
H_N = H(Canon(TransactionBody_N))
```

Dove 
```text
H : ℬ* → 𝒟₂₅₆
```
è la funzione di hash astratta (SHA-256) e 
```math
\text{TransactionBody}_N
```
contiene $H_{N-1}$ come valore vincolato del campo `prev_hash`.

---

# CAPITOLO 8: FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEI RUNTIME ERROR CODES
## (Layer B2 - Specificazione Normativa)

---

### 8.1 Criteri Normativi di Accettazione PASS/FAIL

Un'implementazione esecutiva ottiene la certificazione di conformità se e solo se soddisfa i seguenti tre criteri normativi vincolanti:

1. **Test Vector Match:** $100\%$ di corrispondenza bit-identica sugli hash generati dalla suite di test normativi (`CONFORMANCE-TEST-SUITE-v4.5.5.JSON`).
2. **Requisito di Verifica Temporale LTL/CTL:** Formalizzazione delle proprietà logiche temporali (§9.2) con superamento degli obblighi di proof/model checking.
3. **Totalità Matematica della Transizione:** Gestione corretta ed esaustiva di tutte le transizioni ammissibili per gli automi $M$ ed $\mathcal{H}$ tramite la funzione `Resolve`.

---

### 8.2 Tassonomia dei Runtime Error Codes e Process Exit Codes

In caso di violazione degli invarianti di sicurezza, fallimento delle precondizioni o errori di parsing, il runtime `MUST` segnalare la condizione di errore mediante un **Runtime Error Code** appartenente allo spazio numerico riservato `70–89`.

Quando il runtime esegue come processo autonomo del sistema operativo, tale identificatore `SHALL` essere propagato come **Process Exit Code** del processo di esecuzione.

#### 8.2.1 Sotto-insieme Crittografia, Sicurezza e Consenso (70–79)
* **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`):** Fallimento nella verifica della firma digitale Ed25519 sulla transazione $t$.
* **Runtime Error Code 72 (`ERR_CONSENT_REVOKED_VIOLATION`):** Tentativo di eseguire un'operazione in assenza di consenso o con consenso esplicitamente revocato in $\mathcal{Q}_{\text{consent}}$.
* **Runtime Error Code 73 (`ERR_INFRASTRUCTURE_IO`):** Fallimento dell'infrastruttura di I/O, acquisizione del lease di concorrenza o perdita di connessione al Ledger.
* **Runtime Error Code 77 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrità crittografica della catena di hash ($H_N$), manomissione del Ledger o tentata alterazione storica. Genera un payload di errore formale mediante la funzione ausiliaria `BuildErrorTx`.
* **Runtime Error Code 78 (`ERR_LEASE_ACQUISITION_TIMEOUT`):** Scadenza del lease di concorrenza durante un tentativo di mutazione di stato.
* **Runtime Error Code 79 (`ERR_CLOCK_SKEW_EXCEEDED`):** La differenza tra l'ora di sistema locale $E.t_{\text{wall}}$ ed il timestamp della transazione supera la tolleranza massima consentita $\Delta t_{\text{max}}$.

#### 8.2.2 Sotto-insieme Validazione, Parsing, Flussi e KMS (80–89)
* **Runtime Error Code 80 (`ERR_SML_PARSE_FAILED`):** Errore di validazione sintattica dell'input SML v2.0 rispetto alla grammatica EBNF (§C.1).
* **Runtime Error Code 81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`):** Scadenza della soglia temporale di inattività nello stato $h_7$ (`HUMAN_PAUSED`).
* **Runtime Error Code 82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`):** Tentativo di avanzamento verso un identificatore di nodo non esistente nel grafo del Playbook attivo ($G_P$).
* **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo illegale sui nodi bloccanti `REQUIRED_FOR_SYSTEM_STATE` all'interno di un Emancipation Playbook Graph ($G_P$).
* **Runtime Error Code 84 (`ERR_SCHEMA_MISMATCH`):** Incompatibilità di versione dello schema dati non coperta da un manifest di migrazione valido.
* **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`):** Errore di formattazione JSON, presenza di notazione scientifica, o fallimento del predicato di unicità statica dell'automa `ValidFSMContract`.
* **Runtime Error Code 86 (`ERR_HOBM_BOUNDARY_VIOLATION`):** Tentativo di eseguire un'azione ad alto rischio o impatto legale (`HUMAN_REVIEW_REQUIRED`) priva della firma autorizzativa di un attore di tipo `OPERATOR`.
* **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`):** Indisponibilità, errore di I/O o fallimento di comunicazione con il modulo KMS di gestione delle chiavi effimere.

---

# CAPITOLO 9: MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE
## (Layer A & Layer B2)

---

### 9.1 Modello di Sistema Distribuito, Consistenza e Concorrenza (Layer B2)

1. **Modello di Consistenza del Ledger:** Il registro $\mathcal{L}$ garantisce la **Strict Linearizability (Consistenza Esterna)** per singolo identificatore di caso utente $\mathcal{I}_{\text{case}}$.
2. **Protocollo di Lock e Fencing Token:** La gestione delle scritture concorrenti si avvale di un meccanismo di lease a tempo. Ogni mutazione `MUST` verificare ed incrementare in modo strettamente monotonico il `fencing_token` $N \in \mathbb{N}^+$.
3. **Causalità Temporale e Sincronizzazione Cluster:** L'ordine causale delle transizioni è stabilito unicamente dal numero di sequenza $N_{\text{seq}}$ e dal `fencing_token`. L'orologio fisico $E.t_{\text{wall}}$ costituisce un attributo informativo di policy. La tolleranza al disallineamento temporale tra nodi di un cluster è vincolata dalla norma:
```text
REQ-CLUSTER-CLOCK-SYNC := max_{i,j} |t_wall,i - t_wall,j| ≤ δ_clock con δ_clock < (1/2) * Θ.θ_max_clock_skew
```

4. **Delimitazione dell'Ambito di Infrastruttura Ex-Textu:** La presente specifica disciplina rigorosamente la consistenza logica (*Strict Linearizability*) ed i token di scherma monotonicamente crescenti per ogni `case_id`. Le strategie di deduplicazione di rete e di ripristino post-crash sono delegate ai profili infrastrutturali.

---

### 9.2 MODELLO DI TRANSIZIONE DI KRIPKE E LOGICA TEMPORALE (Layer A)

#### 9.2.1 Formalizzazione della Struttura di Kripke
La semantica temporale di SCINTILLA Core è descritta dalla Struttura di Kripke:

```text
M_K := ⟨ 𝒮, s₀, →_Sys, AP, L, F ⟩
```

- 𝒮: Spazio degli Stati algebrico primario (§1.1.1).
- $s_0 \in \mathcal{S}$: Stato di Genesi (§1.3).
- `→_Sys` $\subseteq \mathcal{S} \times \mathcal{S}$: Relazione di transizione binaria formale generata dalla semantica operazionale SOS (§3).  
- $AP$: Insieme finito dei simboli di Proposizione Atomica Booleana.  
- $L : \mathcal{S} \to \mathcal{P}(AP)$: La Funzione di Etichettatura (Labeling Function).  
- $F \subseteq \mathcal{P}(\mathcal{S})$: Insieme dei vincoli di Fairness definita sulle tracce ammissibili.  

#### 9.2.2 Mappatura della Labeling Function e Predicati sulle Transizioni

La mappa $L(S)$ determina l'appartenenza dei simboli in $AP$ mediante le proiezioni dello stato $S$ e la transazione candidata in valutazione contesto $t_{\text{prop}}$, mentre i predicati di concorrenza e transizione sono formalizzati sulle coppie di stati adiacenti $(S_i, S_{i+1})$:

1. **SafetyGateAllowed:** 
```text
SafetyGateAllowed ∈ L(S) ⇔ ℛ_exec(S, t_prop) = ALLOW
```

2. **DecisionOutcomeAllowed:** 
```text
DecisionOutcomeAllowed ∈ L(S) ⇔ Derive(π_persistent(S), π_internal(S)).𝒪_decision = ALLOW
```

3. **HashChainValid:** 
```text
HashChainValid ∈ L(S) ⇔ H(Canon(t_prev)) = π_internal(S).last_hash
```

4. **MonotonicFence (Predicato su Transizione):** 
```text
MonotonicFence(S_i, S_{i+1}) ⇔ π_internal(S_{i+1}).ℱ_lease.fencing_token > π_internal(S_i).ℱ_lease.fencing_token
```

5. **StateIsRecoverableFailure:** 
```text
StateIsRecoverableFailure ∈ L(S) ⇔ π_Q(S) = RECOVERABLE_FAILURE
```

6. **StateIsSecurityLockdown:** 
```text
StateIsSecurityLockdown ∈ L(S) ⇔ π_Q(S) = SECURITY_LOCKDOWN
```

7. **StateIsValidationError:** 
```text
StateIsValidationError ∈ L(S) ⇔ π_Q(S) = VALIDATION_ERROR
```

8. **StateIsNormal:** 
```text
StateIsNormal ∈ L(S) ⇔ π_Q(S) = NORMAL
```

9. **StateIsReadOnly:** 
```text
StateIsReadOnly ∈ L(S) ⇔ π_Q(S) = SAFE_READ_ONLY_MODE
```

10. **JourneyProgressive:** 
```text
JourneyProgressive ∈ L(S) ⇔ π_Q(S) ∈ F_oper ∧ π_Q_H(S) ∈ {h₁, h₂, h₃, h₄, h₅, h₆, h₁₁}
```

11. **KeyIsShredded:** 
```text
KeyIsShredded_c ∈ L(S) ⇔ LookupKey(K_c) = ⊥
```

12. **UserEngaged:** 
```text
UserEngaged ∈ L(S) ⇔ π_Q_H(S) ∉ {h₇, h₁₀}
```

13. **NonTerminalHumanState:** 
```text
NonTerminalHumanState ∈ L(S) ⇔ π_Q_H(S) ∉ F_H
```

14. **HumanState:** 
```text
HumanState_{h_i} ∈ L(S) ⇔ π_Q_H(S) = h_i
```

15. **CryptoShredExecuted (RFC-005):**
```text
CryptoShredExecuted_c ∈ L(S) ⇔ t.event = EV_CRYPTO_SHRED_EXECUTED(c)
```

#### 9.2.3 Formule Temporali First-Order LTL (FO-LTL)
La dinamica di sicurezza del modello è specificata dalle seguenti formule First-Order LTL:

* **FO-LTL Safety 1 (Safety Gate / Policy Guidance Corrected):**

```text
□ (DecisionOutcomeAllowed ⇒ SafetyGateAllowed)
```

* **FO-LTL Safety 2 (Fencing e Lease Recovery):**

```text
□ (¬MonotonicFence(S_i, S_{i+1}) ⇒ ◯(StateIsRecoverableFailure))
```

* **FO-LTL Safety 3 (Hash Chain Integrity):**

```text
□ (¬HashChainValid ⇒ ◯(StateIsSecurityLockdown))
```

* **FO-LTL Liveness 4 (Recuperabilità del Progresso dopo Errore Tecnico):**

```text
□ ((StateIsValidationError ∨ StateIsRecoverableFailure) ⇒ ◇ JourneyProgressive)
```

* **FO-LTL Safety 5 (Invarianza dell'Oblio Crittografico / RFC-005):**

```text
∀ c ∈ ℐ_case, □ (CryptoShredExecuted_c ⇒ ◯(□ KeyIsShredded_c))
```

#### 9.2.4 Riduzione e Mapping verso LTL Proposizionale per Model Checkers
Per l'esecuzione diretta su strumenti di Model Checking Simbolico (NuSMV, SPIN, TLC), la quantificazione del primo ordine viene ridotta allo spazio discreto delle proposizioni atomiche mediante istanziazione finita sui domini $\mathcal{I}_{\text{case}}$:

```text
Lowering_LTL(∀ c ∈ ℐ_case, ϕ(c)) := ⋀_{i=1}^{|ℐ_case|} ϕ(c_i)
```

#### 9.2.5 Proprietà CTL (Computation Tree Logic)

* **CTL System Agency Guarantee (Accessibilità del Progresso di Sistema):**

```text
AG (UserEngaged ⇒ EF (JourneyProgressive))
```

* **CTL Trap-Free Safety (Recuperabilità dal Lockdown):**

```text
AG (StateIsSecurityLockdown ⇒ EF (StateIsNormal ∨ StateIsReadOnly))
```

* **CTL Non-Terminal Successor Guarantee (Presenza di Transizioni Abilitate):**

```text
AG (NonTerminalHumanState ⇒ EX(True))
```

---

# CAPITOLO 10: STANDARD REFERENCE PROFILE 1 (SC-JCS-1)
## (Layer C - Profilo Concreto di Riferimento)

---

### 10.1 Definizione del Profilo SC-JCS-1 ed Incompatibilità con RFC 8785

**SC-JCS-1 è un profilo di canonizzazione proprietario ispirato concettualmente a JCS, ma NON COMPATIBILE a livello di hash con lo standard RFC 8785**, in quanto impone l'ordinamento delle stringhe Unicode Code Point ed impedisce tassativamente qualsiasi rappresentazione in virgola mobile.

---

### 10.2 Sottoinsieme di Serializzazione e Strict Signed Safe Integer Range

Un documento JSON 
```math
j \in \text{JSON}_{\text{RFC8259}}
```
 appartiene al sottoinsieme 
```math
J_{\text{SC}}
```
se e solo se tutti i numeri presenti sono interi compresi nell'intervallo chiuso:

```text
I_safe = [ -(2⁵³ - 1), +(2⁵³ - 1) ] = [ -9007199254740991, +9007199254740991 ]
```

Qualsiasi notazione contenente virgola mobile, notazione scientifica (`1e10`), `NaN` o `Infinity` `MUST` essere rifiutata con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 10.2.1 Regola sui Valori Probabilistici ed Indici in Basis Points [0, 10000]
Tutti i campi numerici rappresentanti probabilità, punteggi di confidenza o indici AGI $[0.0, 1.0]$ **`MUST` essere convertiti e serializzati in JSON come numeri interi a punto fisso scalati di un fattore $10^4$ (Basis Points, intervallo chiuso intero $[0, 10000]$)**.

#### 10.2.2 Formato Binario di Atteccamento Decisionale `DecisionProof`
Il tipo dati `DecisionProof` citato nei contratti di Livello 2 costituisce una stringa esadecimale UTF-8 di 128 caratteri (Hex) rappresentante la firma digitale Ed25519 di 64 byte calcolata sull'array di byte canonici:

```text
DecisionProof := HexEncode(Sign_Ed25519(K_private, Canon(𝒫_comp) ‖ Canon(t)))
```

---

### 10.3 Algoritmo di Serializzazione Canonica SC-JCS-1

1. **Whitespace Elimination:** Rimuovere tutti i caratteri di spaziatura esterni alle stringhe.
2. **String Escaping:** Applicare l'escaping unicamente per U+0000..U+001F, `"`, e `\`.
3. **Unicode Normalization:** Applicare la normalizzazione Unicode Normalization Form C (NFC).
4. **Object Key Sorting (`Order_SC`):** Ordinare le chiavi degli oggetti in modo ascendente sulla base del confronto lexicografico dei valori scalari Unicode:
```text
Order_SC := UnicodeCodePointLex
```
5. **Set Semantics Deep Bottom-Up Array Sorting:** Per tutte le chiavi registrate nel `SetSemanticsRegistry` (`completed_nodes`, `permissions`, `prerequisites`, `roles`, `scopes`, `consent_items`, `revoked_items`, `competence_records`, `vault_records`), gli elementi dell'array `MUST` essere serializzati autonomamente in byte SC-JCS-1 ed ordinati in modo ascendente sulla base del confronto lessicografico byte-per-byte UTF-8 delle loro rappresentazioni canoniche.
6. **Invarianza Posizionale per Array Generici (Non-Set):** La sequenza logica degli elementi appartenenti ad un array non registrato nel `SetSemanticsRegistry` costituisce parte integrante della rappresentazione canonica dello stato. **È tassativamente vietata qualsiasi trasformazione semantica o strutturale che perda o modifichi l'informazione posizionale.** Il runtime è libero di adottare internamente qualsiasi struttura dati o rappresentazione in memoria, a condizione che la fase di serializzazione canonica ricostruisca senza alterazioni l'esatta sequenza logica originale.

---

### 10.4 Machine-Readable delta_M JSON Definition Contract

Il seguente contratto JSON definisce la funzione di transizione deterministica $\delta_M$ per l'automa DP-FSM. Il valore token `"event": "*"` costituisce la convenzione di fallback normatively riservata al parser del runtime per rappresentare la regola jolly $\delta_{\text{wildcard}}(\sigma)$ soggetta alla regola di mascheramento `RULE-EXPLICIT-SHADOWS-WILDCARD`.

```json
{
  "automaton_id": "SCINTILLA_RUNTIME_SAFETY_AUTOMATON",
  "specification_version": "4.5.5-CANDIDATE",
  "states": [
    "NORMAL",
    "REQUIRE_RECALIBRATION",
    "VALIDATION_ERROR",
    "RECOVERABLE_FAILURE",
    "OPERATOR_REQUIRED",
    "SECURITY_LOCKDOWN",
    "SAFE_READ_ONLY_MODE"
  ],
  "initial_state": "NORMAL",
  "events": [
    "EV_SUCCESS",
    "EV_ABANDON",
    "EV_SML_FAIL",
    "EV_LEASE_EXP",
    "EV_HASH_CORRUPT",
    "EV_TIMEOUT",
    "EV_OVERRIDE",
    "EV_REPAIR",
    "EV_ITEM_PRIVACY_REVOKED",
    "EV_CRYPTO_SHRED_EXECUTED"
  ],
  "transitions": [
    {"from": "NORMAL", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "NORMAL", "event": "EV_ABANDON", "to": "REQUIRE_RECALIBRATION"},
    {"from": "NORMAL", "event": "EV_SML_FAIL", "to": "VALIDATION_ERROR"},
    {"from": "NORMAL", "event": "EV_LEASE_EXP", "to": "RECOVERABLE_FAILURE"},
    {"from": "NORMAL", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "NORMAL", "event": "EV_TIMEOUT", "to": "VALIDATION_ERROR"},
    {"from": "NORMAL", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "NORMAL", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "NORMAL", "event": "EV_ITEM_PRIVACY_REVOKED", "to": "NORMAL"},
    {"from": "NORMAL", "event": "EV_CRYPTO_SHRED_EXECUTED", "to": "NORMAL"},
    
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_ABANDON", "to": "REQUIRE_RECALIBRATION"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_SML_FAIL", "to": "VALIDATION_ERROR"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_LEASE_EXP", "to": "RECOVERABLE_FAILURE"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_TIMEOUT", "to": "VALIDATION_ERROR"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_ITEM_PRIVACY_REVOKED", "to": "REQUIRE_RECALIBRATION"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_CRYPTO_SHRED_EXECUTED", "to": "REQUIRE_RECALIBRATION"},

    {"from": "VALIDATION_ERROR", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "VALIDATION_ERROR", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "VALIDATION_ERROR", "event": "*", "to": "VALIDATION_ERROR"},

    {"from": "RECOVERABLE_FAILURE", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "RECOVERABLE_FAILURE", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "RECOVERABLE_FAILURE", "event": "EV_TIMEOUT", "to": "OPERATOR_REQUIRED"},
    {"from": "RECOVERABLE_FAILURE", "event": "*", "to": "RECOVERABLE_FAILURE"},

    {"from": "OPERATOR_REQUIRED", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "OPERATOR_REQUIRED", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "OPERATOR_REQUIRED", "event": "*", "to": "OPERATOR_REQUIRED"},

    {"from": "SECURITY_LOCKDOWN", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "SECURITY_LOCKDOWN", "event": "EV_TIMEOUT", "to": "SAFE_READ_ONLY_MODE"},
    {"from": "SECURITY_LOCKDOWN", "event": "*", "to": "SECURITY_LOCKDOWN"},

    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_ITEM_PRIVACY_REVOKED", "to": "SAFE_READ_ONLY_MODE"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_CRYPTO_SHRED_EXECUTED", "to": "SAFE_READ_ONLY_MODE"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "*", "to": "SAFE_READ_ONLY_MODE"}
  ]
}
```

---

### 10.5 Machine-Readable delta_H JSON Definition Contract

Il seguente contratto JSON definisce la funzione di transizione deterministica dell'automa DP-FSM del percorso umano $\delta_H$.

**Norme Vincolanti di Interpretazione del Contratto Machine-Readable:**
1. Le transizioni recanti `"from": "*"` `SHALL NOT` essere applicate agli stati presenti nel vettore `terminal_states`.
2. La transizione recante `"to": "*"` (`RULE-WILDCARD-TARGET-REFLEXIVITY`, §2.2.2) `MUST` essere interpretata dal parser runtime come una macro-direttiva riservata:
   - Se applicata a una regola generica (es. `HEV_STEP_COMPLETED`), esegue uno stuttering step ($q_H′ = q_H$), mantenendo lo stato corrente dell'automa.
   - Se applicata alla ricalibrazione (`HUMAN_RECALIBRATION_REQUIRED` su `HEV_STABILIZED`), invoca la valutazione dinamica della funzione pura `ResolveNextHumanState` (§2.3.2), preservando lo stato corrispondente al nodo attivo del Playbook.

```json
{
  "automaton_id": "SCINTILLA_HUMAN_JOURNEY_AUTOMATON",
  "specification_version": "4.5.5-APPROVED",
  "states": [
    "UNASSESSED",
    "INITIAL_ASSESSMENT",
    "STABILIZATION",
    "DOCUMENT_RECOVERY",
    "EMPLOYMENT_READINESS",
    "FINANCIAL_AUTONOMY",
    "SUSTAINED_INDEPENDENCE",
    "HUMAN_PAUSED",
    "HUMAN_RECALIBRATION_REQUIRED",
    "HUMAN_GOAL_CHANGED",
    "HUMAN_DECLINED_ASSISTANCE",
    "PREVENTIVE_STANDBY"
  ],
  "initial_state": "UNASSESSED",
  "terminal_states": ["HUMAN_DECLINED_ASSISTANCE"],
  "events": [
    "HEV_ASSESS_START",
    "HEV_STABILIZED",
    "HEV_DOCS_OBTAINED",
    "HEV_JOB_READY",
    "HEV_FINANCE_OK",
    "HEV_INDEPENDENCE_ACHIEVED",
    "HEV_RELAPSE_REGRESS",
    "HEV_RECALIBRATION_REQ",
    "HEV_PAUSE_REQUESTED",
    "HEV_RESUME_REQUESTED",
    "HEV_GOAL_UPDATE",
    "HEV_DECLINE_ALL",
    "HEV_EMOTIONAL_OVERWHELM",
    "HEV_PREVENTIVE_SUPPORT_REQ",
    "HEV_STEP_COMPLETED"
  ],
  "transitions": [
    {"from": "UNASSESSED", "event": "HEV_ASSESS_START", "to": "INITIAL_ASSESSMENT"},
    {"from": "INITIAL_ASSESSMENT", "event": "HEV_STABILIZED", "to": "STABILIZATION"},
    {"from": "STABILIZATION", "event": "HEV_DOCS_OBTAINED", "to": "DOCUMENT_RECOVERY"},
    {"from": "DOCUMENT_RECOVERY", "event": "HEV_JOB_READY", "to": "EMPLOYMENT_READINESS"},
    {"from": "EMPLOYMENT_READINESS", "event": "HEV_FINANCE_OK", "to": "FINANCIAL_AUTONOMY"},
    {"from": "FINANCIAL_AUTONOMY", "event": "HEV_INDEPENDENCE_ACHIEVED", "to": "SUSTAINED_INDEPENDENCE"},
    {"from": "SUSTAINED_INDEPENDENCE", "event": "HEV_PREVENTIVE_SUPPORT_REQ", "to": "PREVENTIVE_STANDBY"},
    {"from": "PREVENTIVE_STANDBY", "event": "HEV_EMOTIONAL_OVERWHELM", "to": "HUMAN_RECALIBRATION_REQUIRED"},
    {"from": "PREVENTIVE_STANDBY", "event": "HEV_RELAPSE_REGRESS", "to": "HUMAN_RECALIBRATION_REQUIRED"},
    {"from": "*", "event": "HEV_PAUSE_REQUESTED", "to": "HUMAN_PAUSED"},
    {"from": "HUMAN_PAUSED", "event": "HEV_RESUME_REQUESTED", "to": "HUMAN_RECALIBRATION_REQUIRED"},
    {"from": "HUMAN_PAUSED", "event": "*", "to": "HUMAN_PAUSED"},
    {"from": "*", "event": "HEV_DECLINE_ALL", "to": "HUMAN_DECLINED_ASSISTANCE"},
    {"from": "*", "event": "HEV_GOAL_UPDATE", "to": "HUMAN_GOAL_CHANGED"},
    {"from": "HUMAN_GOAL_CHANGED", "event": "HEV_ASSESS_START", "to": "INITIAL_ASSESSMENT"},
    {"from": "*", "event": "HEV_EMOTIONAL_OVERWHELM", "to": "HUMAN_RECALIBRATION_REQUIRED"},
    {"from": "HUMAN_RECALIBRATION_REQUIRED", "event": "HEV_STABILIZED", "to": "*"},
    {"from": "*", "event": "HEV_STEP_COMPLETED", "to": "*"}
  ]
}
```

---

# CAPITOLO 11: CONFORMANCE PROFILE E TEST VECTOR AXIOMS
## (Layer B / Layer C)

---

### 11.1 Assiomatizzazione dei Test Vectors e Conformance Suite

I Test Vector concreti per la certificazione di conformità dello Standard Reference Profile 1 sono formalmente definita nell'artefatto normativo esterno: **`CONFORMANCE-TEST-SUITE-v4.5.5.JSON`**.

La suite di test comprende tre categorie di vettori:
1. **Positive Path Vectors:** Oggetti JSON di input e relative stringhe di byte canonizzate SC-JCS-1 con digest SHA-256 attesi.
2. **Negative Error Vectors:** Documenti contenenti float, cicli su nodi bloccanti o contratti FSM ambigui con verifica dei Runtime Error Codes sollevati ($70-89$).
3. **Security Vectors:** Transazioni recanti firme Ed25519 corrotte o tentativi di violazione della catena di hash $H_N$.

---

# CAPITOLO 12: STATO DI CERTIFICAZIONE E LIVELLI DI VERIFICA
## (Layer B - Specificazione Normativa)

---

### 12.1 Stato Normativo del Documento

La presente **SCINTILLA Core CANONICAL SPECIFICATION v4.5.5 Candidate Canonical Standard Edition** definisce la specifica normativa canonica e completa del dominio SCINTILLA Core.

Lo stato corrente del documento è:

**SPECIFICATION-AUDITED & FORMALIZATION-READY — Candidate Canonical Standard Edition (v4.5.5)**

La struttura formale è definita, esente da contraddizioni interne e pronta per la fase di formalizzazione via prover e sviluppo dell'implementazione di riferimento.

---

### 12.2 Architettura a Livelli di Formalizzazione e Metadati di Governance

Ogni runtime conforme `MUST` esportare nei propri metadati di governance la struttura di attestazione per la verifica di conformità:

```json
{
  "governance_conformance": {
    "conformance_suite_id": "SC-SUITE-v4.5.5-DIGEST-a8f3b29c",
    "runtime_attestation": {
      "runtime_artifact_digest": "SHA256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "compiler_fingerprint": "RUSTC-1.78.0-NIGHTLY-2024",
      "dependency_manifest_hash": "SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069"
    },
    "conformance_status": "100_PERCENT_PASSED"
  }
}
```

---

### 12.3 Matrice dello Stato delle Dimostrazioni Formali e Roadmap di Ratifica

La seguente matrice esplicita lo stato epistemico di ciascuna proprietà formale definita nel testo:

| Dimensione di Dominio / Proprietà Formale | Specificata nella Norma? | Verificata nel Modello? | Coperta da Test Vector? |
| :--- | :---: | :--- | :---: |
| **Determinismo SOS (`PROPERTY-SOS-DETERMINISM`)** | **SÌ** (Cap. 3) | **Proof Obligation** *(Da verificare via Coq/Lean 4)* | **SÌ** |
| **Integrity Chain (`INVARIANT-LEDGER-PROJECTION-CONSISTENCY`)** | **SÌ** (Cap. 1) | **Proof Obligation** *(Dimostrazione induttiva sulla lunghezza del Ledger \|L\|)* | **SÌ** |
| **Invarianza Stato Terminale F_H** | **SÌ** (Cap. 2/10) | **Proof Obligation** *(Da verificare sulla funzione Resolve)* | **SÌ** |
| **Liveness CTL (`AG(UserEngaged => EF Progressive)`)** | **SÌ** (Cap. 9) | **Model Checking Obligation** *(Da verificare via NuSMV)* | **SÌ** |

---

# ANNEXES & CONFORMANCE FRAMEWORK

---

## ANNEX A: TYPESCRIPT TYPE MAPPING (INFORMATIVO / LAYER C / RFC-008)

### A.1 Normative Type Constraints & Interfaces

```typescript
export type ActorType = "USER" | "LLM" | "OPERATOR" | "SYSTEM" | `EXTENSION_ACTOR:${string}`;

export type GuidanceType = 
  | "AUTHORITATIVE_DIRECTIVE" 
  | "MOTIVATED_RECOMMENDATION" 
  | "EXPLORATORY_OPTION";

export type PlaybookNodeActionType = 
  | "INFORMATION" 
  | "OPTIONAL_STEP" 
  | "USER_CONFIRMED_STEP" 
  | "REQUIRED_FOR_SYSTEM_STATE";

export type HumanOversightLevel = 
  | "AUTOMATED_SUPPORT" 
  | "ASSISTED_DECISION" 
  | "HUMAN_REVIEW_REQUIRED" 
  | "PROFESSIONAL_INTERVENTION_REQUIRED";

export type ProvenanceDomain = 
  | "FACTUAL_ADMINISTRATIVE" 
  | "SUBJECTIVE_EMOTIONAL" 
  | "PERSONAL_GOAL" 
  | "TECHNICAL_SYSTEM";

// Branded Integer Types per Aritmetica Intera Sicura
export type SafeInteger = number & { readonly __safeIntBrand: unique symbol };
export type BasisPoints = SafeInteger; // Interval closed intero [0, 10000]
```

### A.2 Reference TypeScript Helper Implementation

*Nota Informativa:* Il codice TypeScript contenuto nella presente sezione ha scopo puramente illustrativo. In caso di divergenza tra l'implementazione TypeScript ed il modello matematico algebrico, l'equazione pura del Capitolo 4.4 costituisce l'autorità normativamente prevalente.

```typescript
// 1. Runtime Validation of 64-Bit Safe Integers (Chapter 10.2)
export function parseSafeInteger(v: number): SafeInteger {
  if (!Number.isInteger(v) || v < -9007199254740991 || v > 9007199254740991) {
    throw new Error("ERR_CONFIGURATION_MALFORMED (Code 85): Number is not a safe integer");
  }
  return v as SafeInteger;
}

// 2. Validation and saturation of the Basis Points interval [0, 10000] (Chapter 1.7.3)
export function parseBasisPoints(v: number): BasisPoints {
  const safe = parseSafeInteger(v);
  if (safe < 0 || safe > 10000) {
    throw new Error("ERR_CONFIGURATION_MALFORMED (Code 85): BasisPoints must be in range [0, 10000]");
  }
  return safe as BasisPoints;
}

// 3. Pure Decoding from SMLDocumentParsed to Human Automaton Event (Chapter 4.4)
export function mapSMLToFSMEvent(doc: SMLDocumentParsed): string {
  if (doc.conversation_outcome === "OVERWHELMED") return "HEV_EMOTIONAL_OVERWHELM";
  if (doc.conversation_outcome === "NEEDS_REPHRASING") return "HEV_RECALIBRATION_REQ";
  if (doc.conversation_outcome === "DECLINED_ACTION") return "HEV_PAUSE_REQUESTED";
  if (doc.conversation_outcome === "ASKED_FOR_HELP") return "HEV_PREVENTIVE_SUPPORT_REQ";
  if (doc.proposed_transition !== "NONE" && doc.evidence_type === "DOCUMENT") return "HEV_DOCS_OBTAINED";
  if (doc.proposed_transition !== "NONE" && doc.conversation_outcome === "MOTIVATED") return "HEV_STABILIZED";
  return "NONE";
}
```

---

## ANNEX B: EMANCIPATION PLAYBOOK GRAPH SPECIFICATION (LAYER B / LAYER C / RFC-008)

### B.1 Struttura Dati Formale del Grafo del Playbook

Un Playbook di Emancipazione serializzato MUST rispettare la seguente interfaccia TypeScript per la validazione di schema:

```typescript
export interface PlaybookCondition {
  condition_id: string;
  expression_pure: string; // Predicato booleano puro valutato sullo stato S
  error_message_fallback: string;
}

export interface PlaybookNode {
  node_id: string;
  title: string;
  description: string;
  action_type: PlaybookNodeActionType;
  estimated_duration_minutes: SafeInteger;
  prerequisites: string[]; // Array ordinato di node_id richiesti
  conditions?: PlaybookCondition[];
  gained_skill?: {
    skill_id: string;
    level_bp: BasisPoints;
  };
}

export interface PlaybookEdge {
  from_node_id: string;
  to_node_id: string;
}

export interface EmancipationPlaybookGraph {
  playbook_id: string;
  version: string;
  target_human_state: string; // Stato target in Q_H (es. 'DOCUMENT_RECOVERY')
  nodes: PlaybookNode[];
  edges: PlaybookEdge[];
}
```

### B.2 Validazione di Aciclicità sui Nodi Bloccanti

In fase di caricamento di un oggetto EmancipationPlaybookGraph, il Playbook Engine (Livello 2) MUST verificare che il sotto-insieme dei nodi con action_type === 'REQUIRED_FOR_SYSTEM_STATE' non contenga cicli orientati (INV-PLAYBOOK-GRAPH-01). Qualsiasi rilevazione di ciclo determina il rifiuto del caricamento con Runtime Error Code 83 (ERR_GRAPH_CYCLE_DETECTED).

---

## ANNEX C: SPECIFICAZIONE SML v2.0 & CONFORMITÀ PROBABILISTICA (LAYER B2 / LAYER C)

### C.1 Grammatica EBNF Formale Puramente Sintattica

```ebnf
SML_Document          ::= SML_Header 
                           SML_ListenSummary 
                           SML_ListenAgency 
                           SML_ConvOutcome 
                           SML_MapOverview 
                           SML_Transition 
                           [ SML_MicroAction ] 
                           SML_Evidence 
                           SML_EvidenceType ;

SML_Header           ::= "SML_VERSION: 2.0" CRLF ;
SML_ListenSummary    ::= "LISTEN_SUMMARY: " NonEmptyTextLine CRLF ;
SML_ListenAgency     ::= "LISTEN_AGENCY: " NonEmptyTextLine CRLF ;
SML_ConvOutcome      ::= "CONVERSATION_OUTCOME: " ("UNDERSTOOD" | "NEEDS_REPHRASING" | "OVERWHELMED" | "MOTIVATED" | "DECLINED_ACTION" | "ASKED_FOR_HELP") CRLF ;
SML_MapOverview      ::= "MAP_OVERVIEW: " NonEmptyTextLine CRLF ;
SML_Transition       ::= "PROPOSED_TRANSITION: " (NodeID | "NONE") CRLF ;
SML_MicroAction      ::= "MICRO_ACTION_ID: " (ActionID | "NONE") CRLF 
                         "MICRO_ACTION_TITLE: " NonEmptyTextLine CRLF 
                         "MICRO_ACTION_MINUTES: " NonNegativeNumber CRLF ;
SML_Evidence        ::= "EVIDENCE: " NonEmptyTextLine CRLF ;
SML_EvidenceType    ::= "EVIDENCE_TYPE: " ("USER_DECLARATION" | "DOCUMENT" | "SYSTEM_EVENT" | "OPERATOR_CONFIRMATION") CRLF ;

NonEmptyTextLine     ::= [^\r\n]* [^\r\n\t ] [^\r\n]* ;
NodeID               ::= [a-zA-Z0-9_-]+ ;
ActionID             ::= [a-zA-Z0-9_-]+ ;
NonNegativeNumber    ::= "0" | [1-9] [0-9]* ;
CRLF                 ::= "\r\n" | "\n" ;
```

### C.2 Gate di Sicurezza Semantico di Livello 2 (Semantic Safety Gate)

Il Policy Guidance Engine (Livello 2) applica una verifica semantica vincolante sugli oggetti `SMLDocumentParsed` decodificati prima di ammettere qualsiasi proposta di transizione:

1. **Filtro contro Allucinazioni Amministrative:** Se l'oggetto SML contiene asserzioni categorizzate nel dominio `FACTUAL_ADMINISTRATIVE` (es. diritti a sussidi, scadenze di legge), l'asserzione `MUST` essere ancorata ad un nodo di Playbook verificato o ad una fonte con stato `VERIFIED`.
2. **Azione di Violazione:** Qualora il Livello 5 generi un'asserzione amministrativa prescrittiva priva di riscontro verificato, il parser di Livello 4 `MUST` scartare l'input e generare l'evento di errore `EV_SML_FAIL`, imponendo al runtime la riconfigurazione dell'output in forma di *Opzione Esplorativa* (§4.5).

### C.3 Requisito di Conformità dei Componenti Probabilistici (`REQ-PROBABILISTIC-INVARIANT-ALIGNMENT`)

1. **Vincolo Causale sulle Transizioni:** Qualsiasi componente probabilistico esterno (Livello 5 / LLM) integrato nel sistema `MUST` essere orchestrato dal Livello 4 in modo tale che i contenuti generati non possano causare né contribuire a causare transizioni di stato incompatibili con gli invarianti `INV-SUPREME-AGENCY-01`, `INV-ANTI-PATERNALISM-01` e `INV-CONTINUITY-OF-SUPPORT-01`.
2. **Valutazione a Scatola Nera del Runtime:** La conformità al presente requisito è valutata esclusivamente rispetto al comportamento osservabile del sistema complessivo e non rispetto alla struttura, ai prompt interni o ai meccanismi di funzionamento del componente probabilistico.

---

## ANNEX D: FORWARD DECLARATIONS, SYMBOL REGISTRY & INTERNAL RFC INDEX (LAYER A / INFORMATIVO)

### D.1 Registro dei Simboli e Dichiarazioni Preventive

Al fine di garantire la risoluzione topologica dei simboli per i formalizzatori matematici e per i sistemi di verifica formale (Coq, Lean 4, TLA+), la seguente tabella mappa la dichiarazione ed il dominio di appartenenza dei simboli primitivi utilizzati nella specifica:

| Simbolo Formale | Dominio di appartenenza / Firma algebrica | Descrizione sintetica | Definizione primario |
| :--- | :--- | :--- | :--- |
| `P(L)` | `Ledger -> State` | Funzione di Proiezione dal Ledger allo Stato | Capitolo 1.4.4 |
| `delta_nominal` | `(State, Transaction) -> State` | Transizione pura in assenza di errori di validazione | Capitolo 1.6.3 |
| `delta_err` | `(State, Transaction, Error) -> State` | Transizione pura di gestione dell'errore applicativo | Capitolo 1.6.3 |
| `R_exec` | `(State, Transaction) -> {ALLOW, DENY, RECALIBRATE}` | Predicato esecutivo puro del Policy Guidance Engine | Capitolo 4.1 |
| `DecisionProof` | `ByteString (128 Hex UTF-8)` | Impronta crittografica di attestazione della decisione | Capitolo 2.1 & 10.2.2 |
| `SMLOutcome` | `Enum` | Esito conversazionale sintattico decodificato | Capitolo 1.1.2 & C.1 |

### D.2 Indice delle RFC Normative Interne

I riferimenti normativi interni di tipo `RFC-XXX` citati nel documento sono mappati alle sezioni corrispondenti della presente specifica secondo il seguente indice:

| Identificativo RFC | Titolo dell'Inizio Normativo | Sezione della Specifica Corrispondente |
| :--- | :--- | :--- |
| **`RFC-002`** | Human Journey Stasis & Paused State Semantics | Capitolo 3.4.1 (`[SOS-HUMAN-PAUSED-STUTTER]`) |
| **`RFC-003`** | Safe Integer Arithmetic & Dependency Reduction Score Calculation | Capitolo 1.7.3 (`AGI_computed`) |
| **`RFC-005`** | Cryptographic Erasure & Case Shredding Specification | Capitolo 1.5.2 & Capitolo 9.2.3 (`FO-LTL Safety 5`) |
| **`RFC-006`** | System & Error Transaction Construction Predicates | Capitolo 1.4.2 (`BuildErrorTx` / `BuildSystemTx`) |
| **`RFC-007`** | Genesis State Canonical Serialization Invariance | Capitolo 1.3.1 (`PROOF-OBLIGATION-GENESIS`) |
| **`RFC-008`** | TypeScript Type System & Data Interfaces Mapping | Annex A & Annex B |
| **`RFC-010`** | SC-JCS-1 Canonical Serialization Totality & Uniqueness | Capitolo 7.1.1 (`THEOREM-SERIALIZATION-TOTALITY`) |

---

**SCINTILLA Core v4.5.5 CANDIDATE CANONICAL STANDARD**
* **Coverage:** Chapters 0.0–12 & Annexes A–D Fully Emitted
* **Governance Authority:** Single Source of Truth for SCINTILLA Core Domain

***Normative Information***  

**Author:** Cristian Evangelisti  
**Contact:** `opensource@cevangel.anonaddy.me`  
The Author is responsible for the definition, maintenance, and publication of this normative specification.  

***Copyright and License***  
Copyright © 2026 Cristian Evangelisti.  
This specification is distributed under the terms of the **GNU Free Documentation License (GNU FDL)**, Version 1.3 or any later version published by the Free Software Foundation; with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.  
A copy of the license is available at: https://www.gnu.org/licenses/fdl-1.3.html  
[License Information](https://www.gnu.org/licenses/fdl)  

***AI-Assisted Development***  
This specification was developed through an iterative process of analysis, design, review, and refinement assisted by Generative Artificial Intelligence systems (Large Language Models - LLMs). These systems were used exclusively as support tools for document design, review, formalization, and editing.  
All content within this specification has been selected, verified, modified where necessary, and explicitly approved by the Author. Artificial Intelligence systems possess no normative authority, do not determine the content of the specification, do not hold the role of author or co-author, and assume no editorial, technical, or regulatory liability regarding this document. The Author retains full responsibility for the content, consistency, correctness, and evolution of this specification.  

***Compatibility and Versioning***  
Unless otherwise indicated, compatibility between different versions of this specification is not implied. Every implementation must explicitly declare the version of the specification with which it complies.

---

