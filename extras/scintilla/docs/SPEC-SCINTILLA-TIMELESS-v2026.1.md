[![Specifica](https://img.shields.io/badge/✴️_SCINTILLA-SPECIFICA_CANONICA_DIVULGATIVA-2ea44f?style=for-the-badge&labelColor=gold)](SPEC-SCI-TL--NATLANGv2026.1.md)

# SCINTILLA Core - CANONICAL SPECIFICATION
## Canonical Standard Edition v4.5.6

**Core Deterministico e Umano-Centrico per la Gestione di Percorsi di Emancipazione Personale**

* **Stato:** Specifica Normativa Canonica Formale (Single Source of Truth - Proposal for Standard Revision)
* **Edizione:** v4.5.6 Consolidated Canonical Standard Edition (Human-Agency Centric & Formally Specified)
* **Normative Authority:** Single Source of Truth Normativa per tutte le implementazioni conformi a SCINTILLA Core.
* **Terminologia Normativa:** RFC 2119 / RFC 8174 (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`), assumono significato normativo quando utilizzati in forma maiuscola.

---

# MISSIONE

## a) Scopo, Natura e Missione della Specifica

La presente specifica definisce **SCINTILLA Core**, il Kernel Normativo Canonico per la costruzione di sistemi deterministici destinati a supportare l'emancipazione personale e l'autonomia operativa di persone fragili o vulnerabili.

SCINTILLA Core costituisce il *Single Source of Truth* del dominio e definisce, in modo formale, deterministico e verificabile, il comportamento osservabile, gli invarianti ed i vincoli normativi che ogni implementazione conforme `MUST` preservare.

La missione del Kernel e' ridurre gli ostacoli cognitivi, informativi, organizzativi ed emotivi che impediscono il passaggio dall'intenzione all'azione, garantendo che l'intelligenza artificiale aumenti le capacita' umane senza mai produrre dipendenza, manipolazione o perdita di autodeterminazione.

SCINTILLA Core e' una specifica normativa pura (non un prodotto software, una piattaforma web o un chatbot) ed opera come contratto di garanzia sul quale prodotti ed interfacce possono essere costruiti.

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
- le proprieta' di determinismo;
- gli obblighi di conformita'.

Ogni elemento definito dalla presente specifica costituisce parte del contratto normativo del Kernel.

Nessuna implementazione conforme puo' derogare agli invarianti, ai requisiti normativi o ai contratti definiti dalla presente specifica.

---

## c) Componenti Esterni

Qualsiasi componente non definito dalla presente specifica e' considerato esterno al Kernel.

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

Essi possono essere sostituiti, aggiornati o rimossi senza modificare il comportamento normativo del Kernel, purche' ogni implementazione rimanga conforme alla presente specifica.

---

## d) Rapporto con le Implementazioni

La presente specifica non prescrive una particolare architettura software.

Implementazioni differenti possono essere conformi pur adottando linguaggi, piattaforme, architetture, algoritmi, librerie o infrastrutture differenti.

Un'implementazione e' conforme se, e solo se, preserva gli invarianti, i requisiti normativi e il comportamento osservabile definiti da SCINTILLA Core.

La conformita' e' determinata esclusivamente dal comportamento osservabile del sistema e non dalle scelte implementative adottate.

---

## e) Separazione tra Componenti Deterministiche e Componenti Probabilistiche

SCINTILLA Core distingue formalmente tra componenti deterministiche e componenti probabilistiche.

Le componenti probabilistiche possono esclusivamente generare ipotesi, suggerimenti, classificazioni, spiegazioni o contenuti.

Esse non possiedono autorita' normativa sullo stato del sistema.

Qualsiasi modifica dello stato persistente puo' avvenire esclusivamente attraverso le regole deterministiche definite dalla presente specifica.

Le componenti probabilistiche costituiscono strumenti di supporto all'elaborazione, ma non possono modificare direttamente lo stato normativo del Kernel.

---

**Principio Fondamentale**

**SCINTILLA Core definisce il comportamento normativo del sistema; le modalita' implementative sono lasciate alle singole implementazioni conformi.**  
**In altre parole, la presente specifica definisce il "cosa"; ogni implementazione conforme definisce il "come".**

---

### ARCHITETTURA NORMATIVA DELLA SPECIFICA

Il presente documento e' organizzato in livelli di astrazione formale espliciti:

1. **LAYER A (Modello Matematico Astratto):** Definizioni algebriche di insiemi, proiezioni, relazioni di equivalenza, funzioni pure deterministiche, automi ed equazioni di teoremi condizionate da ipotesi esplicite.
2. **LAYER B (Specifica Normativa e Politiche di Dominio):**
   * **Layer B1 (Assunzioni Normative & Principi Etici):** Principi etici, assiomi di confine (`AXIOM-`) e postulati di dominio non derivati.
   * **Layer B2 (Requisiti Ingegneristici di Sistema):** Requisiti operativi (`REQ-`), vincoli di sicurezza, tassonomia HOBM e codici di errore.
   * **Layer B3 (Regole Operative SOS):** Regole di inferenza della semantica operazionale (Small-Step Operational Semantics).
3. **LAYER C (Profilo Concreto di Riferimento):** Binding degli algoritmi crittografici, formato SC-JCS-1, contratti JSON e strutture dati concrete.

---

# CAPITOLO 0.0: DOCUMENT GOVERNANCE & META-SPECIFICATION

### 0.0.1 Principio di Minimalita' Normativa (`PRINCIPLE-NORMATIVE-MINIMALITY-01`)

```text
PRINCIPLE-NORMATIVE-MINIMALITY-01
```

> **"Un nuovo Invariante Supremo o Fondamentale MUST essere introdotto nella presente specifica esclusivamente quando non sia formalmente derivabile dagli Invarianti gia' esistenti nell'ambito del modello normativo. Ogni nuova regola di comportamento o vincolo operativo MUST essere classificato al livello gerarchico minimo sufficiente a rappresentarne la semantica esecutiva (Regola Operativa Derivata, Requisito Ingegneristico o Contratto di Interfaccia)."**

---

### 0.0.2 Regola di Precedenza Normativa (`RULE-NORMATIVE-PRECEDENCE-01`)

```text
RULE-NORMATIVE-PRECEDENCE-01
```

> **"In caso di divergenza, ambiguita' o indecidibilita' tra le descrizioni narrative in linguaggio naturale (Layer B) e i contratti esecutivi machine-readable (Layer C / Capitolo 10), i contratti machine-readable di Layer C costituiscono l'autorita' normativamente prevalente per l'esecuzione del runtime."**

---

### 0.0.3 Tassonomia Epistemica delle Modifiche Normative (`TAXONOMY-EPISTEMIC-MODIFICATIONS-01`)
`[DISAMBIGUAZIONE]`

Al fine di garantire la totale trasparenza scientifica e tracciabilita' dell'evoluzione normativa, qualsiasi clausola, formula o requisito emendato rispetto all'edizione v4.5.5 e' categorizzato secondo la seguente quadripartizione epistemica:

1. **`[CORREZIONE_FORMALE]`:** Rettifica di notazione sintattica, correzione di indici, tipizzazione di insiemi o allineamento metrico che preserva l'identica semantica originaria eliminando salti formali o ambivalenze tipologiche.
2. **`[DISAMBIGUAZIONE]`:** Esplicitazione rigorosa di premesse, vincoli logici o clausole operative gia' implicitamente intese nella semantica normativa originaria ma prive di formalizzazione esaustiva.
3. **`[IPOTESI_ESPLICITA]`:** Dichiarazione trasparente e delimitazione di assunzioni ambientali o requisiti esterni di contesto (External Invariant Requirements - EIR) necessari per la validita' condizionale di teoremi o proprieta' del sistema.
4. **`[CAMBIO_SEMANTICO_MOTIVATO]`:** Emendamento deliberato e motivato del comportamento osservabile o di una proprieta' formale rispetto alle edizioni precedenti, introdotto per sanare una falsificazione logica o un'incompatibilita' strutturale dimostrata.

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE
## (Layer B1 - Assunzioni Normative & Principi Etici)

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

Il dominio SCINTILLA Core e' ingegnerizzato attorno ad una singola missione: **aumentare la capacita' concreta di una persona fragile o vulnerabile di trasformare una situazione di instabilita' in un percorso strutturato di emancipazione ed autonomia**.

#### 0.1.1 Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)
Ogni algoritmo, regola di policy, automa o trasformazione di stato `MUST` conformarsi incondizionatamente al seguente Invariante Supremo:

```text
INV-SUPREME-AGENCY-01
```

> **"SCINTILLA Core ha la missione di creare un automa di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e l'agency delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volonta' e senza mai supportare azioni incompatibili con la dignita' umana, la sicurezza ed i diritti altrui."**

#### 0.1.2 Tassonomia Concettuale dell'Agency Responsabile
Il sistema definisce l'**Agency Operativa Responsabile** come la combinazione qualitativa di dominio di sei dimensioni fondamentali:
1. **Capacita' di Azione:** La facolta' concreta di eseguire micro-azioni orientate ad uno scopo.
2. **Comprensione del Contesto:** La chiarezza informativa sui vincoli, sulle risorse e sulle opzioni disponibili.
3. **Valutazione delle Alternative:** La facolta' di confrontare i percorsi operativi e le loro conseguenze prevedibili.
4. **Pianificazione:** La strutturazione di obiettivi complessi in sequenze ordinate di passi eseguibili.
5. **Perseveranza:** La capacita' di mantenere l'impegno operativo nel tempo e di gestire le battute d'arresto.
6. **Percezione di Controllo:** La consapevolezza interiore di essere l'agente primario del proprio cambiamento personale.

*Nota Normativa:* L'Agency Operativa Responsabile costituisce una grandezza qualitativa di dominio dell'utente umano e non rappresenta una tupla vettoriale calcolata o valutata numericamente dal runtime.

---

### 0.2 ASSIOMI DI NON-PATERNALISMO E AUTODETERMINAZIONE

#### 0.2.1 Invariante Anti-Paternalista (`INV-ANTI-PATERNALISM-01`)
Il sistema `SHALL NOT` adottare un modello decisionale paternalistico basato sull'assunto presuntivo che "il sistema sa cosa e' meglio per l'utente".

```text
forall S in S_space, SystemRole(S) != LifeDecisionMaker(S)
```

Il sistema `SHALL`:
1. Aiutare la persona a comprendere la propria situazione attraverso l'analisi dei vincoli e delle risorse disponibili;
2. Proporre opzioni operative chiare e contestualizzate;
3. Esplicitare in modo trasparente le conseguenze prevedibili, i rischi ed i prerequisiti di ogni scelta;
4. Supportare la persona nella costruzione e nel mantenimento di un piano d'azione personalizzato (Playbook).

##### 0.2.1.1 Regola Operativa Derivata: Rispettosita' del Tempo e Anti-Gamification (`RULE-ANTI-GAMIFICATION-01`)
1. **Divieto di Trattenimento Indipendente dal Progresso:** Il sistema `SHALL NOT` implementare meccanismi o sequenze di interazione il cui effetto osservabile sia incrementare il tempo di permanenza dell'utente sulla piattaforma indipendentemente dal completamento delle attivita' definite dal Playbook attivo `G_P` o dall'interesse esplicitamente manifestato dall'utente.
2. **Sussidiarieta' dell'Interazione:** Le notifiche e le interazioni proposte dal sistema `MUST` essere strettamente commisurate ai prerequisiti del Playbook attivo `G_P`, minimizzando il carico cognitivo dell'utente.

#### 0.2.2 Assioma di Sovranita' del Consenso Umano (`AXIOM-HUMAN-CONSENT-SOVEREIGNTY`)
```text
AXIOM-HUMAN-CONSENT-SOVEREIGNTY
```
> **"L'utente umano costituisce l'autorita' decisionale suprema ed inalienabile del proprio percorso. Nessuna raccomandazione del sistema, inferenza del modello probabilistico o suggerimento dell'operatore puo' mutare lo stato di avanzamento personale senza il consenso esplicito, informato e revocabile dell'utente."**

#### 0.2.3 Invariante di Continuita' del Supporto (`INV-CONTINUITY-OF-SUPPORT-01`)
```text
INV-CONTINUITY-OF-SUPPORT-01
```
> **"Un'implementazione conforme SHALL NOT terminare o revocare unilateralmente la disponibilita' del comportamento normativo del Kernel** in conseguenza del completamento di un percorso di Playbook, dell'inattivita' dell'utente o di regressioni nello stato del percorso umano (`q_H`), salvo esplicita richiesta revocatoria dell'utente o transizione dell'automa `M` allo stato:
```text
q5 = SECURITY_LOCKDOWN
```
espressamente prevista dalla presente specifica."

1. **Invarianza di Accessibilita' dello Stato Finale:** Il raggiungimento dello stato target:
```text
h6 = SUSTAINED_INDEPENDENCE
```
induce la transizione dell'automa umano allo stato:
```text
h11 = PREVENTIVE_STANDBY
```
preservando a tempo indeterminato l'accesso alla vista osservabile `Obs(S)`, al Vault `V_vault` e al registro delle competenze `K_competence`.

2. **Conservazione delle Funzionalita' su Regressione:** Qualsiasi transizione regressiva nell'automa `H` (es. `HEV_EMOTIONAL_OVERWHELM` o `HEV_RELAPSE_REGRESS`) `SHALL NOT` ridurre le autorizzazioni, i diritti o le funzionalita' rese osservabili dalla funzione `Obs(S)`.

---

### 0.3 DISACCOPPIAMENTO PERSONA-COMPORTAMENTO E DIRITTI

#### 0.3.1 Invariante di Separazione Persona-Comportamento (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)
Il sistema `MUST` mantenere una distinzione formale assoluta tra l'**Identita' dell'Attore Umano** (rappresentata dall'identificatore di attore) e lo specifico **Payload della Transazione** `t`:

```text
EvaluateAccess(alpha, t) := RespectUserDignity(alpha) and EvaluatePayloadSafety(t.payload)
```

1. **Inviolabilita' della Dignita' della Persona:** L'utente, indipendentemente dai suoi trascorsi personali, legali o sociali, `SHALL` ricevere incondizionatamente il supporto del sistema per migliorare la propria condizione di vita. L'identificatore dell'attore `SHALL NOT` mai essere oggetto di squalifica o stigmatizzazione morale.
2. **Valutazione Rigorosa della Richiesta (`t`):** La funzione di valutazione valuta unicamente la sicurezza, la legalita' e la sostenibilita' dello specifico payload della transazione `t`.

---

# CAPITOLO 1: ALGEBRA ASTRATTA DEL MODELLO DI DOMINIO
## (Layer A & Layer B1/B2)

---

### 1.1 Formalizzazione dello Spazio degli Stati e delle Proiezioni

Lo Spazio degli Stati `S_space` e' il sotto-spazio cartesiano dello stato primario valido di sistema.

#### 1.1.1 Definizione del Sottospazio dello Stato Primario (Layer A)
`[CORREZIONE_FORMALE]`

Lo stato primario del sistema `S` e' formalizzato come l'insieme delle triple valide appartenenti al prodotto cartesiano dei domini di persistenza, controllo e buffer temporaneo:

```text
S := S_persistent * S_internal * S_auxiliary
```

Dove i domini componenti sono formalizzati come segue:

1. **Dominio di Persistenza Ricostruibile dal Ledger (Tupla Etichettata):**
```text
S_persistent := < case_id in (I_case union {null}), M_prov, Q_consent, K_playbook, Q_revoked_items, K_competence, V_vault >
```
dove:
- `case_id`: Identificatore univoco del caso utente appartenente a `I_case` oppure valore nullo `null`;
- `M_prov`: Insieme dei record di provenienza dei dati;
- `Q_consent`: Insieme degli item di consenso informato registrati;
- `K_playbook`: Tupla di stato del Playbook `K_playbook := < pb_id in (I_pb union {null}), node_curr in (I_node union {null}), V_completed in Set(I_node) >`;
- `Q_revoked_items`: Insieme degli identificatori di risorse logicamente revocate;
- `K_competence`: Insieme delle tuple di competenze acquisite `< skill_id, level_bp, timestamp >`;
- `V_vault`: Insieme dei documenti e record di credenziali nel Vault cifrato `< doc_id, doc_hash, status >`.

2. **Dominio Interno di Runtime e Sicurezza:**
```text
S_internal := < q in Q, q_H in Q_H, P_active in P_bundle_space, F_lease in Lease_space, O_bound in HumanOversightLevel, t_pause_start in (T_time union {null}), M_metrics in Nat^4, seq_num in Nat, last_hash in D_256 >
```
dove:
- `Q`: Insieme degli stati dell'automa di runtime `M` (|Q| = 7);
- `Q_H`: Insieme degli stati dell'automa del percorso umano `H` (|Q_H| = 12);
- `P_active`: Bundle di policy attualmente attivo appartenente allo spazio dei bundle `P_bundle_space`;
- `F_lease`: Tupla di lease di concorrenza `F_lease := < fencing_token in Nat, lease_expiration in T_time >`;
- `O_bound`: Livello di supervisione umana vincolato appartenente all'enumerazione `HumanOversightLevel`;
- `t_pause_start`: Timestamp UTC di inizio pausa espresso in millisecondi a 64 bit (`T_time subset Nat^+`) oppure `null`;
- `M_metrics`: Tupla dei contatori cumulativi di interazione in `Nat^4`;
- `seq_num`: Numero progressivo di transazione (`seq_num in Nat`);
- `last_hash`: Impronta crittografica SHA-256 della transazione precedente (`last_hash in D_256` dove `D_256` e' lo spazio dei digest binari a 256 bit).

3. **Dominio Ausiliario Volatile di Co-creazione:**
```text
S_auxiliary := < D_drafts >
```
dove `D_drafts` e' l'insieme volatile delle bozze e contesti transitori non consolidati nel Ledger.

#### 1.1.2 Vista Derivata Pura Disaccoppiata e Contatori di Interazione (Layer A)
La componente di stato derivato `S_derived` non costituisce una dimensione indipendente dello spazio `S_space` bensi' una vista calcolata mediante la funzione pura:

```text
Derive : S_persistent * S_internal -> S_derived
S_derived := O_decision * A_index
```

La tupla dei contatori cumulativi di interazione `M_metrics in Nat^4` risiede nel dominio primario di controllo interno `S_internal` ed e' ordinata come:

```text
M_metrics := < c_interaction, c_rephrase, c_ambiguity, c_overwhelm >
```

La mutazione deterministica della tupla:
```text
M_metrics' = UpdateMetrics(M_metrics, t.event, SMLOutcome)
```
e' regolata dalle seguenti regole di incremento applicate da `ApplyValidated`:
1. `c_interaction`: si incrementa di +1 per ogni transazione valida `t` elaborata con esito `PASS`.
2. `c_rephrase`: si incrementa di +1 quando l'esito conversazionale SML e' `NEEDS_REPHRASING`.
3. `c_overwhelm`: si incrementa di +1 quando l'evento recepito e' `HEV_EMOTIONAL_OVERWHELM`.
4. `c_ambiguity`: si incrementa di +1 quando la valutazione di policy restituisce l'esito `RECALIBRATE`.

#### 1.1.3 Proiezioni Canoniche dello Stato (Layer A)
La scomposizione dello stato astratto `S in S_space` nelle sue componenti primarie e scalari e' regolata dagli operatori di proiezione ortogonale:

```text
pi_persistent : S_space -> S_persistent
pi_internal   : S_space -> S_internal
pi_auxiliary  : S_space -> S_auxiliary
```

Proiezioni scalari derivate degli automi:
```text
pi_Q(S)   := pi_internal(S).q   in Q
pi_Q_H(S) := pi_internal(S).q_H in Q_H
```

---

### 1.2 Interfaccia Osservabile Pubblica ed Equivalenza di Stato

#### 1.2.1 Funzione di Osservazione Pubblica Obs (Layer A)
La proiezione esterna dello stato verso le interfacce utente, API e viste pubbliche e' governata dalla funzione pura di osservazione:

```text
Obs : S_space -> O_obs
Obs(S) := < pi_persistent(S).case_id, M_prov, Q_consent \ R_rev, K_playbook, Q_revoked_items, K_competence \ R_rev, V_vault \ R_rev >
```
dove:
```text
R_rev = { e | ResourceId(e) in pi_persistent(S).Q_revoked_items }
```

#### 1.2.2 Equivalenza di Stato Primario CoreState (Layer A)
Due stati astratti `S1, S2 in S_space` sono semanticamente equivalenti nello stato primario se e solo se le loro proiezioni di persistenza e controllo interno sono identiche:

```text
S1 ==_CoreState S2 <===> pi_persistent(S1) == pi_persistent(S2) and pi_internal(S1) == pi_internal(S2)
```

#### 1.2.3 Proprieta' Derivata dell'Algebra di Stato: Irrilevanza Osservazionale del Buffer Temporaneo (Layer A)
```text
THEOREM-AUXILIARY-IRRELEVANCE
```
```text
forall S1, S2 in S_space, (S1 ==_CoreState S2) ===> (Obs(S1) == Obs(S2))
```
*(Dichiara che le variazioni nel buffer volatile `S_auxiliary` non alterano le proiezioni osservabili dei diritti, del percorso o dello stato storico dell'utente. Costituisce un teorema derivato direttamente dalle definizioni matematiche di `Obs(S)` e `==_CoreState`).*

---

### 1.3 ASSIOMA DEL GENESIS STATE s0 (Layer A)

Lo stato iniziale di genesi `s0 = P(epsilon) in S_space` e' formalizzato come la tripla annidata conforme alla struttura di `S_space` (§1.1.1):

```text
s0 := < s0_persistent, s0_internal, s0_auxiliary >
```
dove:

```text
s0_persistent := < case_id = null, M_prov = empty_set, Q_consent = empty_set, K_playbook = < null, null, empty_set >, Q_revoked_items = empty_set, K_competence = empty_set, V_vault = empty_set >
```

```text
s0_internal := < q = NORMAL, q_H = UNASSESSED, P_active = P_default, F_lease = < 0, t0 >, O_bound = AUTOMATED_SUPPORT, t_pause_start = null, M_metrics = < 0, 0, 0, 0 >, seq_num = 0, last_hash = 0_D256 >
```

```text
s0_auxiliary := < D_drafts = empty_set >
```

con vista derivata iniziale:
```text
Derive(s0_persistent, s0_internal) = < O_decision = NONE, A_index = 0 >
```

#### 1.3.1 Obbligo Formale di Invarianza di Serializzazione del Genesis State (`PO-01` / RFC-007)
`[CORREZIONE_FORMALE]`

```text
PROOF-OBLIGATION-GENESIS-SERIALIZATION-INVARIANCE := Canon(ToJSON(s0^(v4.5.6))) ==_bytes Canon(ToJSON(s0^(v4.5.3)))
```
*(Garantisce che la definizione algebrica di `s0` produca un flusso di byte UTF-8 canonico e un hash `H0 = 0_D256` identici alla sequenza di 32 byte nulli prescritta).*

---

### 1.4 TRANSAZIONI, INVOLUCRO DI ESECUZIONE E LEDGER IMMUTABILE L

#### 1.4.1 Spazio delle Transazioni T_tx, Codifica EncodeTx e Busta di Esecuzione (Layer A)

Una transazione `t in T_tx` e' formalizzata come la tupla: 

```text
t := < TransactionBody, execution_envelope, proof >
```

La funzione pura di codifica per la persistenza e' definita come:

```text
EncodeTx : T_tx -> TransactionBody
```

```text
TransactionBody := < tx_id, case_id, seq_num, prev_hash, timestamp, actor, event, payload, policy_binding_hash, schema_hash, authorization_snapshot_hash, runtime_profile, specification_id >
```

L'**Involucro di Esecuzione (Execution Envelope)** e' la componente di metadati applicativi generata dal runtime che registra il risultato dell'elaborazione senza contaminare il payload di dominio:

```text
execution_envelope := < execution_status, reason_code, state_mutations_applied >
```

Quando una transazione viene elaborata durante lo stato di pausa dell'automa umano:
```text
q_H = HUMAN_PAUSED
```
l'involucro di esecuzione `MUST` registrare:

```text
execution_envelope = < "PROCESSED_NO_STATE_EFFECT", "HUMAN_JOURNEY_PAUSED", false >
```

#### 1.4.2 Predicato Normativo di Sicurezza in Costruzione Errori e BuildErrorTx (Layer A e B2 / RFC-006)
`[CORREZIONE_FORMALE]`

```text
IsLockdownEvent(sigma) <===> (sigma in { EV_HASH_CORRUPT })
```

```text
BuildErrorTx(S, E, err, sigma_orig) := < TransactionBody(
  case_id = pi_persistent(S).case_id,
  seq_num = pi_internal(S).seq_num + 1,
  prev_hash = pi_internal(S).last_hash,
  timestamp = E.t_wall,
  event = (IsLockdownEvent(sigma_orig) ? sigma_orig : EV_SML_FAIL),
  actor = SYSTEM,
  payload = err,
  policy_binding_hash = pi_internal(S).P_active.digest,
  schema_hash = SchemaDigest(CurrentSchemaVersion),
  authorization_snapshot_hash = SnapshotDigest(pi_persistent(S).Q_consent),
  runtime_profile = DefaultRuntimeProfile,
  specification_id = "SCINTILLA-CORE-v4.5.6"
), execution_envelope_err, proof_null >
```

```text
BuildSystemTx(S, E, sigma) := < TransactionBody(
  case_id = pi_persistent(S).case_id,
  seq_num = pi_internal(S).seq_num + 1,
  prev_hash = pi_internal(S).last_hash,
  timestamp = E.t_wall,
  event = sigma,
  actor = SYSTEM,
  payload = empty_payload,
  policy_binding_hash = pi_internal(S).P_active.digest,
  schema_hash = SchemaDigest(CurrentSchemaVersion),
  authorization_snapshot_hash = SnapshotDigest(pi_persistent(S).Q_consent),
  runtime_profile = DefaultRuntimeProfile,
  specification_id = "SCINTILLA-CORE-v4.5.6"
), execution_envelope_default, proof_null >
```

#### 1.4.3 Il Ledger come Monoide Libero L e Funzione Persist (Layer A)

Il registro immutabile delle decisioni (Ledger) e' formalizzato come un Monoide Libero definito sullo spazio dei corpi delle transazioni canonizzate:

```text
L_ledger := < (TransactionBody)*, concat, epsilon >
```

La funzione pura di persistenza converte la transazione `t in T_tx` nel suo corpo canonico mediante `EncodeTx(t) in TransactionBody` e la concatena in modalita' append-only al registro:

```text
Persist : L_ledger * T_tx -> L_ledger
Persist(L, t) := concat(L, < EncodeTx(t) >)
```

#### 1.4.4 Invariante di Consistenza della Proiezione del Ledger (`PO-02` / Layer A)
`[CORREZIONE_FORMALE]`

```text
INVARIANT-LEDGER-PROJECTION-CONSISTENCY
```

* **Ipotesi H1:** La funzione `EncodeTx : T_tx -> TransactionBody` preserva la semantica formale della transazione `t in T_tx`.
* **Ipotesi H2:** Il monoide libero `L_ledger` applica rigorosamente l'operazione di concatenazione associativa monotonica append-only.
* **Ipotesi H3:** La funzione di transizione `ApplyValidated` e' una funzione pura deterministica.
* **Tesi (Proof Obligation Induttiva su |L|):** Per qualsiasi Ledger `L in L_ledger` e transazione `t in T_tx`, lo stato proiettato `P` soddisfa l'equivalenza semantica dello stato primario rispetto al risultato della validazione ambientale:

```text
forall L in L_ledger, forall t in T_tx, P(Persist(L, t)) ==_CoreState ApplyValidated(P(L), t, ValidateEnvironment(P(L), t, E))
```

---

### 1.5 Privacy, Revoca Logica Parziale e Crypto-Erasure Totale

#### 1.5.1 Revoca Logica Parziale (`SOFT_LOGICAL_REVOCATION`) (Layer B2)
La revoca di un singolo elemento informativo da parte dell'utente genera una transizione recante l'evento `EV_ITEM_PRIVACY_REVOKED`. L'applicazione della transazione aggiunge l'identificatore al registro:

```text
Q_revoked_items' = Q_revoked_items union { item_id }
```
```text
ResourceId(e) := 
  (e in V_vault)      ? e.doc_id :
  (e in Q_consent)    ? e.consent_id :
  (e in K_competence) ? e.skill_id : null
```

In sede di proiezione dello stato o consultazione via API (`Obs`), qualsiasi elemento `e` tale che:
```text
ResourceId(e) in pi_persistent(S).Q_revoked_items
```
`MUST` restituire il valore nullo `null` (oscuramento logico).

*Nota di Invarianza Strutturale:* La revoca logica parziale oscura la visibilita' dei dati nella vista pubblica `Obs(S)`, ma **NON rimuove l'identificatore del nodo dall'insieme dei nodi completati** `V_completed` in `K_playbook`, preservando l'integrita' del grafo e la deterministica riproducibilita' dell'avanzamento.

#### 1.5.2 Oblio Crittografico Totale (`FULL_CRYPTO_SHREDDING`) (Layer B2 & Layer C)
L'oblio totale dell'intero caso utente `SHALL` essere eseguito mediante la distruzione irreversibile della chiave radice `K_case` nel modulo KMS ed il cancellamento di ogni percorso di recupero:

```text
ShredKey(K_case) ===> NoRecovery(K_case) and (forall v in V_vault, DecryptPayload(null, Encrypt_{K_case}(v)) == null)
```
L'atto di distruzione `MUST` registrare sul Ledger la transazione formale `t_shred` recante l'evento `EV_CRYPTO_SHRED_EXECUTED`.

---

### 1.6 Validazione Ambientale Impura vs Funzione Pura ApplyValidated

#### 1.6.1 Predicato Impuro di Validazione Ambientale ValidateEnvironment e Requisiti di Cluster (Layer A & B2)
La validazione delle condizioni di contesto fisiche, temporali e crittografiche esterne allo stato algebrico e' governata dal predicato impuro:

```text
ValidateEnvironment : S_space * T_tx * Env -> ValidationResult
ValidationResult := { PASS } union E_validation
```

```text
ValidateEnvironment(S, t, E) :=
  (VerifySignature(t.proof, t.TransactionBody, E.K_pubkey_registry) != TRUE) ? ERR_SIG :
  (abs(t.timestamp - E.t_wall) > Theta.theta_max_clock_skew)                 ? ERR_CLOCK :
  (E.LeaseManager.IsTokenValid(pi_internal(S).F_lease.fencing_token) != TRUE) ? ERR_LEASE :
  PASS
```

```text
REQ-CLUSTER-CLOCK-SYNC := max_{i,j} abs(t_wall_i - t_wall_j) <= delta_clock con delta_clock < (1/2) * Theta.theta_max_clock_skew
```
*(Impone che la sincronizzazione temporale tra i nodi esecutori sia limitata superiormente per prevenire rifiuti inconsistenti per clock skew).*

#### 1.6.2 Funzione Pura di Transizione di Stato ApplyValidated (Layer A)
La mutazione di stato e' governata dalla funzione pura e deterministica `ApplyValidated`, priva di accesso diretto all'ambiente `E`:

```text
ApplyValidated : S_space * T_tx * ValidationResult -> S_space
```

#### 1.6.3 Requisito Normativo di Totalita' di ApplyValidated (`REQ-APPLY-TOTALITY-POLICY`) (Layer B2)
La funzione pura `ApplyValidated` e' una **funzione totale** su `S_space` definita dalla seguente specifica a casi con precedenza assoluta di lockdown per corruzione dell'hash:

```text
ApplyValidated(S, t, v_res) :=
  (t.event == EV_HASH_CORRUPT) ? S[ pi_internal.q |-> SECURITY_LOCKDOWN ] :
  (v_res == PASS and R_exec(S, t) == ALLOW) ? delta_nominal(S, t) :
  delta_err(S, t, v_res)
```

---

### 1.7 INDICE PROXY OPERATIVO DI GUADAGNO DI AGENCY (AGI_proxy)

L'Indice Proxy `AGI_proxy in [0, 10000]` (espresso in Basis Points interi) misura gli indicatori comportamentali descrittivi di avanzamento dell'utente sul sistema.

#### 1.7.1 Assunzione di Confine Epistemico ed Invariante di Isolamento Descrittivo (Layer B1)

```text
AXIOM-EPISTEMIC-BOUNDARY-AGI
```

```text
INV-AGI-DESCRIPTIVE-ISOLATION
```

```text
forall S in S_space, forall t in T_tx, R_exec(S, t) MUST NOT depend on AGI_proxy(S)
```

*Nota di Chiarimento Semantico sull'Acronimo:* Ai fini della presente specifica e di qualsiasi contratto di interfaccia (API/JSON), l'acronimo **`AGI_proxy`** indica esclusivamente l'**Agency Governance Indicator Proxy** (Indicatore Proxy di Governance dell'Agency Operativa) e non ha alcuna relazione teorica, funzionale o concettuale con costrutti di Artificial General Intelligence.

#### 1.7.2 Definizione Normativa di Invarianza per Stati Non-Attivi (Layer B1)

```text
DEF-AGI-PAUSED-STATE-INVARIANCE
```

```text
forall S_N in S_space, AGI_proxy(S_N) := 
  (pi_Q_H(S_N) in { HUMAN_PAUSED, HUMAN_DECLINED_ASSISTANCE }) ? AGI_proxy(S_{N-1}) :
  AGI_computed(S_N)
```

#### 1.7.3 Calcolo Deterministico dell'AGI in Aritmetica Intera Sicura (Layer A / RFC-003)

Per tutti gli stati attivi, `AGI_computed(S) in [0, 10000]` e' calcolato unicamente in aritmetica intera sicura a 64 bit `I_safe` con saturazione dei contatori a `10^6` ed operatore di troncamento intero `floor( ... )`:

```text
AGI_computed(S) := floor( (w1 * ClarityScore_bp(S) + w2 * ActionExecutionRatio_bp(S) + w3 * DependencyReductionScore_bp(S)) / 10000 )
```
dove `w1, w2, w3 in [0, 10000]` sono interi tali che `w1 + w2 + w3 == 10000`.

1. **ClarityScore in Basis Points:**
```text
ClarityScore_bp(S) :=
  (c_interaction == 0) ? 10000 :
  max(0, 10000 - floor( ((c_rephrase + c_ambiguity + 2 * c_overwhelm) * 10000) / max(1, c_interaction) ))
```

2. **ActionExecutionRatio in Basis Points:**
```text
ActionExecutionRatio_bp(S) :=
  (pb_id == null or |V_P| == 0) ? 0 :
  floor( (|{ id in V_completed | exists v in G_P.V_P t.c. v.node_id == id }| * 10000) / |V_P| )
```

3. **DependencyReductionScore in Basis Points (RFC-003):**
```text
DependencyReductionScore_bp(S) :=
  (|V_active_completed| == 0) ? 0 :
  floor( (|{ id in V_active_completed | exists v in G_P.V_P t.c. v.node_id == id and IsEmpoweredAction(v, S) }| * 10000) / |V_active_completed| )
```
dove `V_active_completed = V_completed intersect { v.node_id | v in G_P.V_P }`, ed il predicato booleano puro `IsEmpoweredAction(v, S)` e' formalizzato come:

```text
IsEmpoweredAction(v, S) <===> ( v.action_type in { USER_CONFIRMED_STEP, REQUIRED_FOR_SYSTEM_STATE } and v.gained_skill != null )
```

---

### 1.8 Contratto del Modulo Crittografico Astratto (`CryptoProviderContract`) (Layer A & C)

Ogni implementazione esecutiva di SCINTILLA Core `MUST` integrare un modulo crittografico conforme alla seguente interfaccia astratta:

```text
CryptoProviderContract := < DeriveKey, EncryptPayload, DecryptPayload, ShredKey, VerifySignature, LookupKey >
```

1. `DeriveKey(K_parent, context) -> K_child`: Derivazione deterministica chiavi effimere.
2. `EncryptPayload(K_item, v) -> Payload_encrypted`: Cifratura autenticata simmetrica.
3. `DecryptPayload(K_item, Payload_encrypted) -> v | null`: Decifratura ed autenticazione payload.
4. `ShredKey(K_id) -> TRUE`: Distruzione del materiale di chiave ed elisione dei percorsi di recupero (`NoRecovery`).
5. `VerifySignature(proof, data, K_pub) -> Bool`: Verifica firma digitale a chiave pubblica.
6. `LookupKey(K_id) -> K_active | null`: Verifica presenza ed estrazione del materiale di chiave attivo.

*Nota di Binding Normativo:* Il binding concreto degli algoritmi crittografici (AES-256-GCM, HKDF-SHA256, Ed25519) e' definito unicamente nel Profilo Concreto di Riferimento SC-JCS-1 (Layer C / Capitolo 10).

---

# CAPITOLO 2: ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI
## (Layer A & Layer B2)

---

### 2.1 Modello di Isolamento Stratificato a 6 Livelli

L'architettura di SCINTILLA Core e' strutturata in 6 livelli funzionali ad isolamento unidirezionale rigoroso, dove i livelli superiori non possiedono alcuna autorita' di scrittura diretta sullo stato di runtime:

```text
[ LEVEL 5 ] Large Language Model (Probabilistic Hypothesis Generator)
     │ API Contract: Output SML v2.0 Syntactic Text Only (No State Authority)
[ LEVEL 4 ] Communication, SML Parsing & Semantic Validation Layer
     │ API Contract: Structured Hypothesis & Data Provenance Object
[ LEVEL 3 ] Human Interaction, Consent & Agency Engine (Consent Ledger, AGI & HOBM)
     │ API Contract: Validated Human Context, AGI Score & Consent State
[ LEVEL 2 ] Policy Guidance Engine (Safety Gate, Policy Compilation & Rule Evaluation)
     │ API Contract: Executable Policy DecisionResult with DecisionProof
[ LEVEL 1 ] Deterministic Runtime (Fencing Lease, Monotonic Fence, ValidateEnv & Apply Pure Transition delta)
     │ API Contract: Canonical Serialized Payload & Pure State Mutation
[ LEVEL 0 ] Immutable State Ledger (Append-Only decisions.ndjson Content-Addressed Hash Chain)
```

---

### 2.2 Runtime Safety State Machine M (Layer A & B2)

L'operativita' di sicurezza di runtime e' modellata dall'automa **Deterministic Priority Finite State Machine (DP-FSM)** `M`:

```text
M := < Q, Sigma, T_delta, delta_M, q0, F_oper >
```

1. **Insieme degli Stati Canonici `Q` (|Q| = 7):**
```text
Q = { NORMAL (q0), REQUIRE_RECALIBRATION (q1), VALIDATION_ERROR (q2), RECOVERABLE_FAILURE (q3), OPERATOR_REQUIRED (q4), SECURITY_LOCKDOWN (q5), SAFE_READ_ONLY_MODE (q6) }
```
2. **Stato Iniziale:** `q0 = NORMAL`
3. **Insieme degli Stati Operativamente Stabili `F_oper`:**
```text
F_oper = { NORMAL, SAFE_READ_ONLY_MODE }
```

#### 2.2.1 Definizione di Dominio DP-FSM e Precondizione Statica di Unicita'
Ai fini della specifica SCINTILLA Core, un automa DP-FSM indica una macchina a stati finiti la cui relazione di transizione e' deterministica a valle dell'applicazione della funzione di risoluzione prioritaria `Resolve(q, sigma, F_T)`.

Un contratto di automa e' valido ed eseguibile se e solo se soddisfa la precondizione statica di unicita':

```text
ValidFSMContract <===> (forall q in Q, forall sigma in Sigma, |delta_explicit(q, sigma)| <= 1) and (forall sigma in Sigma, |delta_wildcard(sigma)| <= 1)
```

#### 2.2.2 Regola di Precedenza Wildcard, Funzione Algebrica Resolve e Regola di Parsing Target Wildcard

```text
RULE-EXPLICIT-SHADOWS-WILDCARD
```
> **"The explicit transition rules SHALL strictly shadow wildcard transition rules according to the four-tier resolution order."**

```text
RULE-WILDCARD-TARGET-REFLEXIVITY
```
> **"When a wildcard token '*' appears in the target state field ('to': '*') of a machine transition contract, the runtime parser MUST interpret the transition as an identity/stuttering step (q' = q), maintaining the current state unchanged."**

La risoluzione deterministica della transizione negli automi DP-FSM e' governata dalla funzione algebrica pura con gerarchia a 4 livelli (estesa dalla regola di riflessivita' sul target):

```text
Resolve(q, sigma, F_T) :=
  (q in F_T)                                  ? q :
  (delta(q, sigma) is defined and q notin F_T) ? delta(q, sigma) :
  (delta(*, sigma) is defined and q notin F_T) ? delta(*, sigma) :
  (delta(q, *) is defined and q notin F_T)     ? delta(q, *) :
  (delta(*, *) is defined and q notin F_T)     ? delta(*, *) :
  q
```

*Nota esplicativa:* Quando l'immagine della funzione `delta` restituisce il token wildcard (es. `delta(*, sigma) = *`), la funzione `Resolve` applica l'identita' `q' = q`.

#### 2.2.3 Partizione dell'Alfabeto Sigma (Layer B2)
L'alfabeto degli eventi di sistema `Sigma` (|Sigma| = 10) e' partizionato nei seguenti tre sotto-insiemi mutuamente disgiunti:

1. **Eventi di Business (`Sigma_business`):** Eventi di mutazione operativa e di progresso del caso utente:
```text
Sigma_business := { EV_SUCCESS, EV_ABANDON, EV_SML_FAIL, EV_LEASE_EXP, EV_TIMEOUT }
```
2. **Eventi di Ripristino Operativo (`Sigma_recovery`):** Eventi di override ed intervento autorizzato per il ripristino di stato:
```text
Sigma_recovery := { EV_OVERRIDE, EV_REPAIR }
```
3. **Eventi Amministrativi e di Tutela Diritti (`Sigma_administrative`):** Eventi relativi all'integrita' crittografica e alla gestione dei diritti dell'utente:
```text
Sigma_administrative := { EV_HASH_CORRUPT, EV_ITEM_PRIVACY_REVOKED, EV_CRYPTO_SHRED_EXECUTED }
```

#### 2.2.4 Gestione della Stasi Operativa in SAFE_READ_ONLY_MODE (q6) (Layer B2)
La permanenza dell'automa `M` nello stato:
```text
q6 = SAFE_READ_ONLY_MODE
```
e' governata esclusivamente dalle regole di transizione del contratto `delta_M` (§10.4) e dalle meta-regole SOS (§3.2):
1. **Eventi di Business** (`Sigma_business`): Impongono uno *stuttering step* (`q6 -> q6`), precludendo qualsiasi mutazione dello stato operativo.
2. **Eventi Amministrativi** (`Sigma_administrative`): Sono ammessi ed elaborati per garantire l'esercizio inalienabile dei diritti dell'utente (revoca privacy, oblivion).
3. **Eventi di Ripristino** (`Sigma_recovery`): Transitano lo stato verso `NORMAL` previa verifica autorizzativa dell'operatore o applicazione di patch formale.

---

### 2.3 Human Journey State Machine H (Layer A & B2)

L'evoluzione concettuale del percorso umano dell'utente e' modellata dall'automa DP-FSM di dominio `H`:

```text
H := < Q_H, Sigma_H, delta_H, q_H0, F_H >
```

1. **Insieme degli Stati del Percorso Umano `Q_H` (|Q_H| = 12):**
```text
Q_H = { UNASSESSED (h0), INITIAL_ASSESSMENT (h1), STABILIZATION (h2), DOCUMENT_RECOVERY (h3), EMPLOYMENT_READINESS (h4), FINANCIAL_AUTONOMY (h5), SUSTAINED_INDEPENDENCE (h6), HUMAN_PAUSED (h7), HUMAN_RECALIBRATION_REQUIRED (h8), HUMAN_GOAL_CHANGED (h9), HUMAN_DECLINED_ASSISTANCE (h10), PREVENTIVE_STANDBY (h11) }
```

2. **Partizione Funzionale degli Stati Umani:**
`[DISAMBIGUAZIONE]`
   * **Stati Umani Attivi e Progressivi (`H_active`):**
     ```text
     H_active := { h1, h2, h3, h4, h5, h6, h11 }
     ```
   * **Stati Umani Transitori e di Ricalibrazione (`H_trans`):**
     ```text
     H_trans := { h0, h8, h9 }
     ```
   * **Stati Umani Non-Attivi / Terminali:**
     ```text
     H_non_active := { h7, h10 }
     ```

3. **Stato Iniziale:** `q_H0 = UNASSESSED = h0`
4. **Insieme degli Stati Target / Terminali `F_H`:**
```text
F_H = { HUMAN_DECLINED_ASSISTANCE } = { h10 }
```

5. **Alfabeto degli Eventi Umani `Sigma_H` (|Sigma_H| = 15):**
```text
Sigma_H = { HEV_ASSESS_START, HEV_STABILIZED, HEV_DOCS_OBTAINED, HEV_JOB_READY, HEV_FINANCE_OK, HEV_INDEPENDENCE_ACHIEVED, HEV_RELAPSE_REGRESS, HEV_RECALIBRATION_REQ, HEV_PAUSE_REQUESTED, HEV_RESUME_REQUESTED, HEV_GOAL_UPDATE, HEV_DECLINE_ALL, HEV_EMOTIONAL_OVERWHELM, HEV_PREVENTIVE_SUPPORT_REQ, HEV_STEP_COMPLETED }
```

#### 2.3.1 Dinamica dello Stato h11 (PREVENTIVE_STANDBY) come "Base Sicura" (Layer B2)
Lo stato `h11 = PREVENTIVE_STANDBY` definisce la condizione di **Santuario in Standby (Base Sicura)**:

1. **Semantica di Custodia Discreta:** Quando l'automa umano `H` raggiunge lo stato `h11`, l'utente ha acquisito piena autonomia operativa. Il sistema cessa di proporre micro-azioni quotidiane o notifiche proattive, ma mantiene attiva la vista di ascolto discreto.
2. **Invarianza di Accessibilita' dello Stato Finale:** Nel raggiungimento dello stato target `h6 = SUSTAINED_INDEPENDENCE`, l'automa umano induce la transizione allo stato `h11 = PREVENTIVE_STANDBY`, preservando a tempo indeterminato l'accesso alla vista osservabile `Obs(S)`, al Vault `V_vault` e al registro delle competenze `K_competence`.
3. **Re-ingaggio Immediato:** Qualsiasi espressione di disagio, sopraffazione emotiva o richiesta esplicita dell'utente transita immediatamente l'automa da `h11` allo stato di supporto attivo `HUMAN_RECALIBRATION_REQUIRED` (`h8`), riattivando la guida senza che l'utente debba giustificare la propria ricaduta.

#### 2.3.2 Regola Normativa di Preservazione del Progresso Umano (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`)
`[DISAMBIGUAZIONE]`

Quando l'automa `H` si trova nello stato `h8` (`HUMAN_RECALIBRATION_REQUIRED`) e riceve l'evento:
```text
HEV_STABILIZED
```
il runtime `MUST` determinare lo stato di destinazione `q_H'` mediante la funzione pura:
```text
ResolveNextHumanState : Q_H * K_playbook_type -> Q_H
```
formalizzata come:
```text
ResolveNextHumanState(q_H, K_pb) :=
  (K_pb.node_curr != null and MapNodeToHumanState(K_pb.node_curr) is defined) ? MapNodeToHumanState(K_pb.node_curr) :
  STABILIZATION  // Fallback difensivo normativo su h2 in H_active
```
*(Tale formulazione assicura la totalita' matematica della risoluzione ed impedisce la retrocessione indebita dell'utente qualora i prerequisiti degli stati successivi risultino gia' soddisfatti in `V_completed`).*

---

### 2.4 Equazione Matematica del Sistema Reattivo Composito (Layer A)

Il sistema reattivo globale di SCINTILLA Core e' modellato dallo spazio di stato composito `S_C := Q * Q_H`.

La funzione di transizione pura dell'automa composito `delta_C : (Q * Q_H) * (Sigma union Sigma_H) -> (Q * Q_H)` e' definita dall'equazione a casi:

```text
delta_C((q, q_H), sigma_C) :=
  (sigma_C in Sigma) ? (delta_M(q, sigma_C, T_delta), q_H) :
  (sigma_C in Sigma_H and q in (F_oper union { REQUIRE_RECALIBRATION })) ? (q, Resolve(q_H, sigma_C, F_H)) :
  (sigma_C in Sigma_H and q in { VALIDATION_ERROR, RECOVERABLE_FAILURE }) ? (q, Resolve(q_H, sigma_C, F_H)) :
  (sigma_C in { HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL } and q in { OPERATOR_REQUIRED, SECURITY_LOCKDOWN }) ? (q, Resolve(q_H, sigma_C, F_H)) :
  (q, q_H)
```

1. **Invariante di Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`):** Gli eventi dell'automa umano `Sigma_H` non mutano lo stato di runtime `Q`. Viceversa, errori tecnici di sistema:
```text
q in { VALIDATION_ERROR, RECOVERABLE_FAILURE }
```
`SHALL NOT` paralizzare l'evoluzione concettuale dello stato umano `Q_H`.

2. **Eccezione di Sovranita' Umana in Lockdown:** In presenza di blocco critico di sicurezza:
```text
q = SECURITY_LOCKDOWN
```
le sole transizioni dell'automa umano ammesse per la registrazione ed applicazione immediata sono quelle di richiesta di pausa o revoca del supporto (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

# CAPITOLO 3: SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)
## (Layer B3 - Regole Operative SOS)

---

### 3.0 Mappa di Osservazione e Corrispondenza Relazione-Funzione

La Mappa di Osservazione Canonica `pi_SOS` estrae la tripla dello stato di valutazione della semantica operazionale:

```text
pi_SOS : S_space -> (Q * Q_H * S_persistent)
pi_SOS(S) := < pi_Q(S), pi_Q_H(S), pi_persistent(S) >
```

#### 3.0.1 Proprieta' Derivata di Determinismo della Relazione SOS (`PROPERTY-SOS-DETERMINISM` / `PO-03`) (Layer B1)
`[CORREZIONE_FORMALE]`

```text
PROPERTY-SOS-DETERMINISM
```
```text
forall S in S_space, forall t in T_tx, forall E in Env, (pi_SOS(S) --t/Sys--> sigma_1 and pi_SOS(S) --t/Sys--> sigma_2) ===> (sigma_1 == sigma_2)
```
*(Costituisce una proprieta' derivata direttamente dalla purezza matematica e dal determinismo delle funzioni `delta_M`, `delta_H` e `ApplyValidated`).*

#### 3.0.2 Requisito di Progresso SOS Condizionato (`REQ-SOS-CONDITIONED-PROGRESS`) (Layer B2)
```text
REQ-SOS-CONDITIONED-PROGRESS
```
```text
forall (pi_SOS(S), t) in Domain(--t/Sys-->), exists! sigma' in (Q * Q_H * S_persistent) t.c. pi_SOS(S) --t/Sys--> sigma'
```

#### 3.0.3 Proprieta' di Corrispondenza Relazionale-Funzionale (`PROPERTY-SOS-SEMANTIC-CORRESPONDENCE`) (Layer A)
`[DISAMBIGUAZIONE]`

* **Ipotesi H1:** La relazione di transizione SOS `--t/Sys-->` soddisfa la Proprieta' di Determinismo (`PROPERTY-SOS-DETERMINISM`).
* **Ipotesi H2:** Il predicato di validazione d'ambiente restituisce l'esito `ValidateEnvironment(S, t, E) == PASS`.
* **Ipotesi H3:** La funzione `ApplyValidated` ammette come parametro d'ingresso il risultato della validazione ambientale.
* **Tesi (Proof Obligation su analisi per casi):** La transizione relazionale SOS:
```text
pi_SOS(S) --t/Sys--> < q', q_H', S_persistent' >
```
sussiste se e solo se lo stato successivo `S' = ApplyValidated(S, t, PASS)` soddisfa la rigorosa coincidenza delle proiezioni:
```text
S' == ApplyValidated(S, t, PASS) and q' == pi_Q(S') and q_H' == pi_Q_H(S') and S_persistent' == pi_persistent(S')
```

#### 3.0.4 Flusso Unidirezionale di Abilitazione e Disaccoppiamento dei Predicati (Layer A & B2)
`[DISAMBIGUAZIONE]`

Il predicato di abilitazione all'esecuzione di una transizione `Enabled(S, t, E)` e' disaccoppiato in componenti ortogonali prive di circolarita' logica:

```text
Environment E  +  ActorIntent
       │
       ▼
Transaction Construction t
       │
  ( Authorized(event(t), type(actor(t))) and EnvOK(S, t, E) and GuardsOK(S, t) and PolicyOK(S, t, P_active) )
       │
       ▼
  Enabled(S, t, E)
       │
       ▼
  StepSys(S, t, E, S') con S' = ApplyValidated(S, t, PASS)
```

1. **`EnvOK(S, t, E)`:** Predicato di validita' ambientale:
```text
EnvOK(S, t, E) <===> (ValidateEnvironment(S, t, E) == PASS)
```
2. **`PolicyOK(S, t, P_active)`:** Predicato di conformita' al bundle di policy attivo:
```text
PolicyOK(S, t, P_active) <===> (R_exec^{P_active}(S, t) == ALLOW)
```
3. **`GuardsOK(S, t)`:** Predicato di soddisfacimento delle condizioni di guardia di sicurezza:
```text
GuardsOK(S, t) <===> (EvaluateGuards(S, t) == PASS)
```
4. **`ActorIntent(t, E)`:** Validita' sintattica (EBNF) e disponibilita' dell'input da parte dell'attore esterno disaccoppiata dallo stato interno `S`.

```text
PO-18 (SOS-Enabled-to-Step) := forall S in S_space, forall t in T_tx, forall E in Env, Enabled(S, t, E) ===> exists S' in S_space t.c. (S --t/Sys--> S' and S' == ApplyValidated(S, t, PASS))
```

---

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore (Layer B2)

Una transizione `t in T_tx` con evento `sigma_C = event(t)` ed emessa dall'attore `alpha = actor(t)` e' autorizzata se e solo se soddisfa il predicato booleano `Authorized(sigma_C, type(alpha))`:

```text
Authorized(sigma_C, type(alpha)) <===>
  (sigma_C in Sigma_H and type(alpha) in { USER, OPERATOR, SYSTEM }) or
  (sigma_C in (Sigma_business union Sigma_administrative) and type(alpha) == SYSTEM) or
  (sigma_C == EV_ITEM_PRIVACY_REVOKED and type(alpha) in { USER, OPERATOR }) or
  (sigma_C in Sigma_recovery and type(alpha) == OPERATOR)
```
*(Qualsiasi tentativo di emissione diretta di transizioni da parte di attori con `type(alpha) == LLM` restituisce inderogabilmente `False`).*

---

### 3.2 META-REGOLE SOS DELLA SICUREZZA DI RUNTIME (M) (Layer B3)

```text
sigma_C = event(t) in Sigma    EnvOK(S, t, E)    Authorized(sigma_C, type(alpha))    q' = Resolve(q, sigma_C, empty_set)    GuardsOK(S, t)
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-META-SAFETY]
                                     < q, q_H, S > --t/Sys--> < q', q_H, ApplyValidated(S, t, PASS) >
```

```text
sigma_C = event(t) in Sigma    (v_res in E_validation or not Authorized(sigma_C, type(alpha)) or not GuardsOK(S, t))    q' = ((q in { SECURITY_LOCKDOWN, SAFE_READ_ONLY_MODE }) ? q : VALIDATION_ERROR)
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-META-SAFETY-FAIL]
                                           < q, q_H, S > --t/Sys--> < q', q_H, ApplyValidated(S, BuildErrorTx(S, E, v_res, sigma_C), v_res) >
```

#### 3.2.1 Meta-Regole SOS di Ripristino ed Override da Operatore (Layer B3)

```text
sigma_C = event(t) == EV_REPAIR    q in { SECURITY_LOCKDOWN, SAFE_READ_ONLY_MODE }    type(alpha) == OPERATOR    p = t.payload    ValidRepairPatch(p)
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-COMPENSATIVE-REPAIR]
                                           < q, q_H, S > --t/Sys--> < NORMAL, q_H, ApplyCompensativeRepair(S, p) >
```

```text
sigma_C = event(t) == EV_OVERRIDE    q == OPERATOR_REQUIRED    type(alpha) == OPERATOR    EnvOK(S, t, E)
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-OPERATOR-OVERRIDE]
                           < OPERATOR_REQUIRED, q_H, S > --t/Sys--> < NORMAL, q_H, ApplyValidated(S, t, PASS) >
```

---

### 3.3 Meta-Regole SOS per Competenze e Custodia Credenziali (Layer B3)

#### 3.3.1 Meta-Regola SOS per la Palestra delle Competenze (`[SOS-COMPETENCE-UPDATE]`)
Quando l'utente completa un nodo di Playbook `v in V_P` recante un attributo di competenza acquisita:

```text
sigma_C = HEV_STEP_COMPLETED    v.gained_skill == < skill_id, level_bp >    K_competence' = pi_persistent(S).K_competence union { < skill_id, level_bp, E.t_wall > }
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-COMPETENCE-UPDATE]
                                     < q, q_H, S > --t/Sys--> < q, q_H, ApplyValidated(S, t[K_competence |-> K_competence'], PASS) >
```

#### 3.3.2 Meta-Regola SOS per la Custodia Credenziali (`[SOS-VAULT-RECORD]`)
All'ottenimento o verifica oggettiva di un documento d'identita' o attestato formale:

```text
sigma_C = HEV_DOCS_OBTAINED    doc == < doc_id, H_doc, VERIFIED >    V_vault' = pi_persistent(S).V_vault union { doc }
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-VAULT-RECORD]
                   < q, q_H, S > --t/Sys--> < q, DOCUMENT_RECOVERY, ApplyValidated(S, t[V_vault |-> V_vault'], PASS) >
```

---

### 3.4 META-REGOLE SOS DEL PERCORSO UMANO (H) E SOVRANITÀ (Layer B3)

```text
sigma_C = event(t) in Sigma_H    q in F_oper    EnvOK(S, t, E)    Authorized(sigma_C, type(alpha))    q_H' = Resolve(q_H, sigma_C, F_H)    PolicyOK(S, t, P_active)
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-META-HUMAN]
                                                    < q, q_H, S > --t/Sys--> < q, q_H', ApplyValidated(S, t, PASS) >
```

```text
sigma_C in { HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL }    q notin F_oper    EnvOK(S, t, E)
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-HUMAN-SOVEREIGNTY-LOCKDOWN]
                         < q, q_H, S > --t/Sys--> < q, Resolve(q_H, sigma_C, F_H), ApplyValidated(S, t, PASS) >
```

#### 3.4.1 Meta-Regola SOS di Stasi in Stato Pausa (`[SOS-HUMAN-PAUSED-STUTTER]` / RFC-002)

Quando l'automa del percorso umano si trova nello stato:
```text
q_H = HUMAN_PAUSED
```
e giunge un qualsiasi evento `t` non corrispondente a `HEV_RESUME_REQUESTED`, `HEV_DECLINE_ALL` o `HEV_EMOTIONAL_OVERWHELM`, l'automa esegue uno stuttering step preservando lo stato di stasi ed emettendo una transazione recante l'involucro di esecuzione `e_paused`:

```text
q_H == HUMAN_PAUSED    sigma_C in (Sigma_H \ { HEV_RESUME_REQUESTED, HEV_DECLINE_ALL, HEV_EMOTIONAL_OVERWHELM })    e_paused = < "PROCESSED_NO_STATE_EFFECT", "HUMAN_JOURNEY_PAUSED", false >
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-HUMAN-PAUSED-STUTTER]
                                                                < q, HUMAN_PAUSED, S > --t/Sys--> < q, HUMAN_PAUSED, ApplyValidated(S, t[envelope |-> e_paused], PASS) >
```

#### 3.4.2 Meta-Regola SOS di Timeout ed Inattivita' Umana (`[SOS-HUMAN-TIMEOUT]`)

Quando l'automa umano si trova in:
```text
q_H = HUMAN_PAUSED
```
ed il tempo di permanenza supera la soglia parametrizzata `theta_inactivity_timeout`:

```text
q_H == HUMAN_PAUSED    (E.t_wall - pi_internal(S).t_pause_start) > Theta.theta_inactivity_timeout    t_timeout = BuildSystemTx(S, E, HEV_RECALIBRATION_REQ)
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-HUMAN-TIMEOUT]
                                                < q, HUMAN_PAUSED, S > --t_timeout/Sys--> < q, HUMAN_RECALIBRATION_REQUIRED, ApplyValidated(S, t_timeout, PASS) >
```

#### 3.4.3 Meta-Regola SOS di Adattamento per Sopraffazione Emotiva (`[SOS-EMOTIONAL-OVERWHELM]`)

Alla rilevazione di uno stato di sopraffazione emotiva segnalato dall'utente o dal parser SML:

```text
sigma_C = HEV_EMOTIONAL_OVERWHELM
───────────────────────────────────────────────────────────────────────────────────────────────────────────── [SOS-EMOTIONAL-OVERWHELM]
                      < q, q_H, S > --t/Sys--> < q, HUMAN_RECALIBRATION_REQUIRED, ApplyValidated(S, t, PASS) >
```

---

# CAPITOLO 4: POLICY GUIDANCE ENGINE & STRATIFICAZIONE DELLE POLICY
## (Layer A & Layer B2)

---

### 4.1 Stratificazione delle Policy in 3 Livelli

Per impedire l'esecuzionalita' diretta di regole espresse in linguaggio naturale o soggette ad ambiguita' interpretativa, il Policy Guidance Engine adotta una stratificazione rigorosa su tre livelli di astrazione:

1. **Policy Specification Layer (Livello Normativo Umano):** Testo normativo, principi etici e linee guida operative espresse in linguaggio naturale controllato per gli operatori umani.
2. **Policy Compilation Layer (Livello di Compilazione):** Processo di traduzione automatizzata e validata che trasforma le specifiche normative in predicati formali e insiemi di parametri `Theta`.
3. **Executable Policy Predicate Layer (Livello Esecutivo Puro):** Il codice deterministico derivato:
```text
R_exec : S_space * T_tx -> { ALLOW, DENY, RECALIBRATE }
```
l'unico direttamente eseguibile dal runtime al Livello 2.

---

### 4.2 Definizione Algebrica del Policy Bundle (Layer A)

Un `PolicyBundle` `P_bundle` e' formalizzato come la tupla algebrica:

```text
P_bundle := < PolicyID, Version, Theta, R_exec, Sig_P >
```

* `PolicyID in I_id`: Identificatore unico della policy (UUIDv7).
* `Version in V_version`: Versione della policy nello Spazio delle Versioni `V_version` (§6.1).
* `Theta`: Lo spazio dei parametri di configurazione e soglie, es.
```text
theta_max_duration, theta_confidence, theta_max_clock_skew, theta_inactivity_timeout
```
* `R_exec`: Predicato esecutivo puro valutato sullo stato `S` e sulla transazione `t`.
* `Sig_P`: La firma crittografica dell'autorita' di policy emittente calcolata su `Canon(P_bundle)`.

---

### 4.3 Composizione di Policy e Regola di Versione Composita (Layer A & B2)

L'operatore di composizione algebrica `compose` produce il bundle composito `P_comp = compose(P1, P2)` mediante la funzione esplicita `ComposePolicy`:

```text
ComposePolicy(P1, P2) := < PolicyID_comp, CompositePolicyVersion, CompositePolicyDigest, Theta1 union Theta2, R_exec_comp, Sig_comp >
```

1. **Impronta Crittografica Composita (Content-Addressed Binary Digest):**
   L'identita' immutabile del bundle composito e' determinata dalla concatenazione binaria esplicita dei due digest a 256 bit disposti in ordine lessicografico non codificato:
```text
CompositePolicyDigest := SHA256( concat(A_sorted, B_sorted) )
```
dove `A_sorted` e `B_sorted` sono i due array di 32 byte binari ordinati secondo la relazione:
```text
A_sorted <= B_sorted <===> ByteLexicographicalCompare(A, B) <= 0
```

2. **Requisito Normativo di Assegnazione Versione Composita (`REQ-POLICY-SEMVER-DERIVATION`) (Layer B2):**
   La versione formale `CompositePolicyVersion in V_version` segue la convenzione di dominio definita per segnalare incompatibilita' tra bundle eterogenei:
```text
CompositePolicyVersion :=
  (v1 <=_compat v2)              ? v2 :
  (v2 <=_compat v1)              ? v1 :
  < max(M1, M2) + 1, 0, 0 >      // Incompatibilita' Major (M1 != M2)
```

3. **Valutazione Composita Disgiunta (`DENY-OVERRIDES`):**
   La funzione di valutazione esecutiva composita `R_exec_comp(S, t)` e' governata dalla regola conservativa:
```text
R_exec_comp(S, t) :=
  (R_exec_1(S, t) == DENY or R_exec_2(S, t) == DENY) ? DENY :
  (R_exec_1(S, t) == RECALIBRATE or R_exec_2(S, t) == RECALIBRATE) ? RECALIBRATE :
  (R_exec_1(S, t) == ALLOW and R_exec_2(S, t) == ALLOW) ? ALLOW :
  DENY
```

---

### 4.4 Decodifica Deterministica Input SML v2.0 in Evento Umano (Layer A & B2)

Per eliminare l'ambiguita' tra i suggerimenti linguistici generati dal Livello 5 (LLM) e gli eventi accettati dal runtime (Livello 3/1), il Livello 4 applica la funzione pura di decodifica deterministica `MapSMLToFSMEvent`.

La funzione mappa tutti gli esiti conversazionali SML v2.0 definiti nella grammatica sintattica (§C.1) agli eventi esecutivi dell'automa umano `Sigma_H union { NONE }`:

```text
MapSMLToFSMEvent : SMLDocumentParsed -> Sigma_H union { NONE }
```

```text
MapSMLToFSMEvent(d) :=
  (d.conversation_outcome == OVERWHELMED)                               ? HEV_EMOTIONAL_OVERWHELM :
  (d.conversation_outcome == NEEDS_REPHRASING)                          ? HEV_RECALIBRATION_REQ :
  (d.conversation_outcome == DECLINED_ACTION)                           ? HEV_PAUSE_REQUESTED :
  (d.conversation_outcome == ASKED_FOR_HELP)                            ? HEV_PREVENTIVE_SUPPORT_REQ :
  (d.proposed_transition != "NONE" and d.evidence_type == DOCUMENT)     ? HEV_DOCS_OBTAINED :
  (d.proposed_transition != "NONE" and d.conversation_outcome == MOTIVATED) ? HEV_STABILIZED :
  NONE
```

---

### 4.5 Tassonomia della Guida ed Ergonomia Cognitiva (Layer B2)

Al fine di ridurre lo stress ed il carico cognitivo dell'utente vulnerabile senza usurparne la sovranita' decisionale, il sistema definisce tre livelli formali di guida comunicativa:

1. **Direttiva Autoritativa (Authoritative Directive):** Formulazione prescrittiva ammessa **esclusivamente** in condizioni di imminente rischio per la sicurezza o situazioni di emergenza acuta (`PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Raccomandazione Motivata e Contestualizzata (Motivated Recommendation):** Formulazione consigliata che propone un percorso operativo riducendo il carico cognitivo. La raccomandazione `MUST` esplicitare la motivazione, il grado di certezza ed essere immediatamente revocabile o modificabile dall'utente (`USER_CONFIRMED_STEP`).
3. **Opzione Esplorativa (Exploratory Option):** Presentazione neutrale di alternative multiple, indicata quando l'utente si trova in uno stato di stabilita' emotiva e desidera confrontare autonomamente le possibilita'.

#### 4.5.1 Regola di Non-Pregiudizio sul Rifiuto dei Suggerimenti (`RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01`)

```text
forall S1, S2 in S_space, (S2 == ApplyValidated(S1, t, PASS) and event(t) in { HEV_PAUSE_REQUESTED, HEV_DECLINE_ALL }) ===> (Capabilities(Obs(S2)) == Capabilities(Obs(S1)))
```

1. **Invarianza della Proiezione Osservabile:** La ricezione di un evento di rifiuto o rinvio relativo a un suggerimento di collegamento con servizi esterni o comunita' reali `SHALL NOT` ridurre l'insieme delle autorizzazioni, dei diritti e delle capacita' rese osservabili dalla funzione `Obs(S)`.
2. **Divieto di Ultimatum:** Nessun nodo del grafo di Playbook `G_P` `SHALL` condizionare il proseguimento del percorso all'accettazione di interazioni esterne, salvo nei casi in cui tali interazioni costituiscano un prerequisito tecnico o legale esplicitamente tipizzato come `REQUIRED_FOR_SYSTEM_STATE`.

---

### 4.6 Filosofia Normativa dell'Intervento Umano (Human Override) (Layer B2)

L'intervento di un operatore umano (`OPERATOR`) costituisce un meccanismo di garanzia e supporto e `MUST` conformarsi ai seguenti 5 principi normativi inderogabili:

1. **Tracciabilita' Assoluta:** Ogni azione di override `MUST` generare una transizione registrata sul Ledger `L_ledger` recante l'identificativo dell'operatore.
2. **Autenticazione Forte:** L'override richiede una firma digitale valida ed il possesso del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. **Spiegabilita' Obbligatoria:** Ogni intervento `MUST` includere la motivazione esplicita in formato testuale non vuoto.
4. **Inalterabilita' Storica:** L'override modifica unicamente lo stato proiettato corrente `S_N`, ma `SHALL NOT` alterare o elidere le transizioni storiche precedenti.
5. **Rispetto del Consenso:** L'operatore `SHALL NOT` forzare l'esecuzione di azioni in violazione del consenso espresso dall'utente, salvo nei casi previsti dal livello HOBM `PROFESSIONAL_INTERVENTION_REQUIRED`.

---

# CAPITOLO 5: EMANCIPATION PLAYBOOK ENGINE
## (Layer A & Layer B2)

---

### 5.1 Struttura del Grafo del Playbook (Layer A)

Un **Emancipation Playbook** e' formalizzato come un grafo orientato ed etichettato:

```text
G_P := (V_P, E_P, C_P)
```

* `V_P`: Insieme dei Nodi di Micro-Azione (`v in V_P`).
* `E_P subset (V_P * V_P)`: Archi diretti rappresentanti la sequenza logica di progressione.
* `C_P`: Insieme delle Condizioni di Verificabilita', dove ogni elemento `c in C_P` e' un predicato booleano puro `c : S_space -> { True, False }`.

---

### 5.2 Tipizzazione dei Nodi Playbook (Layer B2)

Ogni nodo `v in V_P` `MUST` appartenere ad una delle seguenti quattro categorie formali:

1. **`INFORMATION`:** Nodo a contenuto puramente informativo o educativo. Non richiede azioni o conferme per il proseguimento.
2. **`OPTIONAL_STEP`:** Micro-passo suggerito per ottimizzare il percorso, saltabile dall'utente senza alcun blocco del flusso.
3. **`USER_CONFIRMED_STEP`:** Micro-passo che richiede il consenso o la conferma esplicita dell'utente prima di essere marcato come completato.
4. **`REQUIRED_FOR_SYSTEM_STATE`:** Prerequisito tecnico o legale bloccante. Solo i nodi appartenenti a questa categoria possono condizionare le transizioni dell'automa di sicurezza `M`.

---

### 5.3 Invarianti di Esecuzione e Tracking dello Stato Playbook (Layer A & Layer B2)

#### 5.3.1 Invariante di Aciclicita' Locale sui Nodi Bloccanti (`INV-PLAYBOOK-GRAPH-01`) (Layer A & B2)
Il sotto-grafo formato dai soli nodi tipizzati `REQUIRED_FOR_SYSTEM_STATE` `MUST` essere uno Strict Directed Acyclic Graph (DAG).

```text
INV-PLAYBOOK-GRAPH-01 := IsAcyclic(G_P | REQUIRED_FOR_SYSTEM_STATE) == TRUE
```
La rilevazione di cicli sui nodi bloccanti determina il rifiuto immediato del caricamento del Playbook ed il sollevamento del **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.

#### 5.3.2 Durata Parametrizzata dei Micro-Passi (Layer B2)
La durata stimata di una micro-azione non puo' superare il valore definito dal parametro di policy:
```text
theta_max_duration in Theta
```

#### 5.3.3 Tracciamento dello Stato di Avanzamento (Layer A)
Ogni avanzamento nel grafo `G_P` `MUST` aggiornare la componente `K_playbook` nello stato `S`, dove:
```text
K_playbook := < pb_id, node_curr, V_completed > in (I_pb union {null}) * (I_node union {null}) * Set(I_node)
```

---

# CAPITOLO 6: TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ
## (Layer A & Layer B2)

---

### 6.1 Spazio delle Versioni e Tupla dei Profili di Runtime (Layer A)

Ogni componente versionabile di SCINTILLA Core appartiene allo spazio vettoriale discreto delle versioni `V_version := Nat * Nat * Nat` rappresentato dalla tripla ordinata `v := < major, minor, patch >`.

Il contesto esecutivo completo di una transazione o di un registro e' vincolato dalla **Tupla dei Profili di Runtime (Runtime Profile Tuple)**:

```text
RuntimeProfile := < semantic_profile, schema_profile, canonicalization_profile, policy_profile >
```

#### 6.1.1 Regola di Compatibilita' Temporale per il Replay Storico (`RULE-HISTORICAL-REPLAY-COMPATIBILITY`) (Layer B2)
```text
RULE-HISTORICAL-REPLAY-COMPATIBILITY
```
In fase di ricostruzione deterministica dello stato `P(L)` a partire dal Ledger:
1. Ogni transazione `t_i in L` `MUST` essere interpretata e validata applicando le regole di semantica operazionale SOS e gli schemi di validazione corrispondenti al profilo `t_i.runtime_profile` registrato nella transazione stessa (o nel Manifest di segmento del Ledger).
2. L'introduzione di una nuova versione dello standard `SHALL NOT` alterare retroattivamente il risultato delle transizioni storiche gia' consolidate sotto una versione precedente.

---

### 6.2 Relazione di Compatibilita' Retroattiva (Layer A)

Siano `v1 = < M1, m1, p1 >` e `v2 = < M2, m2, p2 >` due versioni nello spazio `V_version`.

La relazione di compatibilita' retroattiva `v1 <=_compat v2` e' definita formalmente come l'ordine parziale:

```text
v1 <=_compat v2 <===> (M1 == M2) and ((m1 < m2) or (m1 == m2 and p1 <= p2))
```

---

# CAPITOLO 7: CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA
## (Layer A & Layer B2)

---

### 7.1 SPAZIO NORMALIZZATO E CANONIZZAZIONE (Layer A)

Sia `S_normalized subset S_space` il sottoinsieme di stati conformi alle regole di normalizzazione del profilo di riferimento SC-JCS-1 (§10.2). 

La funzione di canonizzazione deterministica `Canon : S_normalized -> B*` converte lo stato strutturato nella sua rappresentazione binaria unica. L'iniettivita' semantica di `Canon` costituisce una proprieta' obiettivo garantita dall'applicazione dell'algoritmo deterministico SC-JCS-1 (§10.3), assicurando che due stati semanticamente identici producano il medesimo flusso di byte UTF-8.

#### 7.1.1 Teorema di Totalita' ed Univocita' della Serializzazione (Layer A / RFC-010)

```text
THEOREM-SERIALIZATION-TOTALITY-AND-UNIQUENESS := forall t in T_tx, (EncodeTx(t) in J_SC) ===> exists! b in B* t.c. Canon(EncodeTx(t)) == b
```

---

### 7.2 Catena di Hash Immutabile ed Integrita' delle Transazioni (Layer A)

La continuita' e l'integrita' del Ledger `L_ledger` per la transazione N-esima e' determinata dal calcolo del checksum `H_N in D_256` eseguito sul corpo della transazione `TransactionBody_N`:

```text
H_0 = 0_D256  // Digest nullo di Genesi a 256 bit (32 byte 0x00)
```
```text
H_N = SHA256( Canon(TransactionBody_N) )
```

dove `TransactionBody_N` contiene `H_{N-1}` come valore vincolato del campo `prev_hash`.

---

# CAPITOLO 8: FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEI RUNTIME ERROR CODES
## (Layer B2 - Specificazione Normativa)

---

### 8.1 Criteri Normativi di Accettazione PASS/FAIL

Un'implementazione esecutiva ottiene la certificazione di conformita' se e solo se soddisfa i seguenti tre criteri normativi vincolanti:

1. **Test Vector Match:** 100% di corrispondenza bit-identica sugli hash generati dalla suite di test normativi (`CONFORMANCE-TEST-SUITE-v4.5.6.JSON`).
2. **Requisito di Verifica Temporale LTL/CTL:** Formalizzazione delle proprieta' logiche temporali (§9.2) con superamento degli obblighi di proof/model checking.
3. **Totalita' Matematica della Transizione:** Gestione corretta ed esaustiva di tutte le transizioni ammissibili per gli automi `M` ed `H` tramite la funzione `Resolve`.

---

### 8.2 Tassonomia dei Runtime Error Codes e Process Exit Codes

In caso di violazione degli invarianti di sicurezza, fallimento delle precondizioni o errori di parsing, il runtime `MUST` segnalare la condizione di errore mediante un **Runtime Error Code** appartenente allo spazio numerico riservato `70-89`.

Quando il runtime esegue come processo autonomo del sistema operativo, tale identificatore `SHALL` essere propagato come **Process Exit Code** del processo di esecuzione.

#### 8.2.1 Sotto-insieme Crittografia, Sicurezza e Consenso (70–79)
* **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`):** Fallimento nella verifica della firma digitale Ed25519 sulla transazione `t`.
* **Runtime Error Code 72 (`ERR_CONSENT_REVOKED_VIOLATION`):** Tentativo di eseguire un'operazione in assenza di consenso o con consenso esplicitamente revocato in `Q_consent`.
* **Runtime Error Code 73 (`ERR_INFRASTRUCTURE_IO`):** Fallimento dell'infrastruttura di I/O, acquisizione del lease di concorrenza o perdita di connessione al Ledger.
* **Runtime Error Code 77 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrita' crittografica della catena di hash (`H_N`), manomissione del Ledger o tentata alterazione storica. Genera un payload di errore formale mediante la funzione ausiliaria `BuildErrorTx`.
* **Runtime Error Code 78 (`ERR_LEASE_ACQUISITION_TIMEOUT`):** Scadenza del lease di concorrenza durante un tentativo di mutazione di stato.
* **Runtime Error Code 79 (`ERR_CLOCK_SKEW_EXCEEDED`):** La differenza tra l'ora di sistema locale `E.t_wall` ed il timestamp della transazione supera la tolleranza massima consentita `theta_max_clock_skew`.

#### 8.2.2 Sotto-insieme Validazione, Parsing, Flussi e KMS (80–89)
* **Runtime Error Code 80 (`ERR_SML_PARSE_FAILED`):** Errore di validazione sintattica dell'input SML v2.0 rispetto alla grammatica EBNF (§C.1).
* **Runtime Error Code 81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`):** Scadenza della soglia temporale di inattivita' nello stato `h7` (`HUMAN_PAUSED`).
* **Runtime Error Code 82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`):** Tentativo di avanzamento verso un identificatore di nodo non esistente nel grafo del Playbook attivo (`G_P`).
* **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo illegale sui nodi bloccanti `REQUIRED_FOR_SYSTEM_STATE` all'interno di un Emancipation Playbook Graph (`G_P`).
* **Runtime Error Code 84 (`ERR_SCHEMA_MISMATCH`):** Incompatibilita' di versione dello schema dati non coperta da un manifest di migrazione valido.
* **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`):** Errore di formattazione JSON, presenza di notazione scientifica/virgola mobile, o fallimento del predicato di unicita' statica dell'automa `ValidFSMContract`.
* **Runtime Error Code 86 (`ERR_HOBM_BOUNDARY_VIOLATION`):** Tentativo di eseguire un'azione ad alto rischio o impatto legale (`HUMAN_REVIEW_REQUIRED`) priva della firma autorizzativa di un attore di tipo `OPERATOR`.
* **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`):** Indisponibilita', errore di I/O o fallimento di comunicazione con il modulo KMS di gestione delle chiavi effimere.

---

# CAPITOLO 9: MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE
## (Layer A & Layer B2)

---

### 9.1 Modello di Sistema Distribuito, Consistenza e Concorrenza (Layer B2)

1. **Modello di Consistenza del Ledger:** Il registro `L_ledger` garantisce la **Strict Linearizability (Consistenza Esterna)** per singolo identificatore di caso utente `I_case`.
2. **Protocollo di Lock e Fencing Token:** La gestione delle scritture concorrenti si avvale di un meccanismo di lease a tempo. Ogni mutazione `MUST` verificare ed incrementare in modo strettamente monotonico il `fencing_token in Nat^+`.
3. **Causalita' Temporale e Sincronizzazione Cluster:** L'ordine causale delle transizioni e' stabilito unicamente dal numero di sequenza `seq_num` e dal `fencing_token`. L'orologio fisico `E.t_wall` costituisce un attributo informativo di policy. La tolleranza al disallineamento temporale tra nodi di un cluster e' vincolata dalla norma:
```text
REQ-CLUSTER-CLOCK-SYNC := max_{i,j} abs(t_wall_i - t_wall_j) <= delta_clock con delta_clock < (1/2) * Theta.theta_max_clock_skew
```
4. **Delimitazione dell'Ambito di Infrastruttura Ex-Textu:** La presente specifica disciplina rigorosamente la consistenza logica (*Strict Linearizability*) ed i token di scherma monotonicamente crescenti per ogni `case_id`. Le strategie di deduplicazione di rete e di ripristino post-crash sono delegate ai profili infrastrutturali.

---

### 9.2 MODELLO DI TRANSIZIONE DI KRIPKE E LOGICA TEMPORALE (Layer A)

#### 9.2.1 Formalizzazione della Struttura di Kripke
La semantica temporale di SCINTILLA Core e' descritta dalla Struttura di Kripke:

```text
M_K := < S_space, s0, ->_Sys, AP, L_map, F_fair >
```

- `S_space`: Spazio degli Stati algebrico primario (§1.1.1).
- `s0 in S_space`: Stato di Genesi (§1.3).
- `->_Sys subset (S_space * S_space)`: Relazione di transizione binaria formale generata dalla semantica operazionale SOS (§3).  
- `AP`: Insieme finito dei simboli di Proposizione Atomica Booleana.  
- `L_map : S_space -> Set(AP)`: La Funzione di Etichettatura (Labeling Function).  
- `F_fair subset Set(S_space)`: Insieme dei vincoli di Fairness definita sulle tracce ammissibili.  

#### 9.2.2 Mappatura della Labeling Function e Predicati sulle Transizioni
`[DISAMBIGUAZIONE]`

La mappa `L_map(S)` determina l'appartenenza dei simboli in `AP` mediante le proiezioni dello stato `S` e la transazione candidata in valutazione `t_prop`, mentre i predicati di concorrenza e transizione sono formalizzati sulle coppie di stati adiacenti `(S_i, S_{i+1})`:

1. **SafetyGateAllowed:** 
```text
SafetyGateAllowed in L_map(S) <===> (R_exec(S, t_prop) == ALLOW)
```
2. **DecisionOutcomeAllowed:** 
```text
DecisionOutcomeAllowed in L_map(S) <===> (Derive(pi_persistent(S), pi_internal(S)).O_decision == ALLOW)
```
3. **HashChainValid:** 
```text
HashChainValid in L_map(S) <===> (SHA256(Canon(t_prev)) == pi_internal(S).last_hash)
```
4. **MonotonicFence (Predicato su Transizione):** 
```text
MonotonicFence(S_i, S_{i+1}) <===> (pi_internal(S_{i+1}).F_lease.fencing_token > pi_internal(S_i).F_lease.fencing_token)
```
5. **StateIsRecoverableFailure:** 
```text
StateIsRecoverableFailure in L_map(S) <===> (pi_Q(S) == RECOVERABLE_FAILURE)
```
6. **StateIsSecurityLockdown:** 
```text
StateIsSecurityLockdown in L_map(S) <===> (pi_Q(S) == SECURITY_LOCKDOWN)
```
7. **StateIsValidationError:** 
```text
StateIsValidationError in L_map(S) <===> (pi_Q(S) == VALIDATION_ERROR)
```
8. **StateIsNormal:** 
```text
StateIsNormal in L_map(S) <===> (pi_Q(S) == NORMAL)
```
9. **StateIsReadOnly:** 
```text
StateIsReadOnly in L_map(S) <===> (pi_Q(S) == SAFE_READ_ONLY_MODE)
```
10. **JourneyProgressive:** 
```text
JourneyProgressive in L_map(S) <===> (pi_Q(S) in F_oper and pi_Q_H(S) in H_active)
```
dove `H_active := { h1, h2, h3, h4, h5, h6, h11 }`.
11. **StateIsHumanActive:** 
```text
StateIsHumanActive in L_map(S) <===> (pi_Q_H(S) in H_active)
```
12. **KeyIsShredded:** 
```text
KeyIsShredded_c in L_map(S) <===> (LookupKey(K_c) == null)
```
13. **UserEngaged:** 
```text
UserEngaged in L_map(S) <===> (pi_Q_H(S) notin { h7, h10 })
```
14. **NonTerminalHumanState:** 
```text
NonTerminalHumanState in L_map(S) <===> (pi_Q_H(S) notin F_H)
```
15. **HumanState:** 
```text
HumanState_{h_i} in L_map(S) <===> (pi_Q_H(S) == h_i)
```
16. **CryptoShredExecuted (RFC-005):**
```text
CryptoShredExecuted_c in L_map(S) <===> (t.event == EV_CRYPTO_SHRED_EXECUTED(c))
```

---

#### 9.2.3 Falsificazione Formale della Proprieta' Liveness 4 Originaria
`[CAMBIO_SEMANTICO_MOTIVATO]`

Nelle edizioni precedenti (v4.5.5), la proprieta' temporale di recupero globale era formalizzata come:
```text
FO-LTL Liveness 4 (ORIGINARIA, FALSIFICATA):
[] ( (StateIsValidationError or StateIsRecoverableFailure) ===> <> JourneyProgressive )
```

**Dimostrazione di Falsificazione mediante Contro-Modello Condizionale `pi_counter` (`PO-17`):**
1. Si consideri la traiettoria `pi_counter = (S_0, S_1, S_2, S_3, S_4, S_5, ...)` generata a partire dallo stato iniziale `s0` mediante il prefisso di transizioni nominali umane:
   `HEV_ASSESS_START -> HEV_STABILIZED -> HEV_EMOTIONAL_OVERWHELM`
   raggiungendo lo stato di ricalibrazione emotiva `q_H = h8` (`HUMAN_RECALIBRATION_REQUIRED`).
2. Al passo `k = 4`, si verifica un errore tecnico recuperabile di sistema, portando lo stato a `S_4` con `pi_Q(S_4) = RECOVERABLE_FAILURE` e `pi_Q_H(S_4) = h8`.
3. Al passo `k = 5`, una transizione di recupero tecnico `EV_SUCCESS` ripristina lo stato di runtime a `pi_Q(S_5) = NORMAL`. Per l'Invariante di Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`, §2.4), lo stato umano rimane invariato: `pi_Q_H(S_5) = h8`.
4. Per tutti i passi successivi `n >= 5`, il verificarsi di transizioni nominali periodiche di sistema `EV_SUCCESS` genera una sequenza infinita di stati distinti `S_n` (`seq_num` e `last_hash` monotonicamente crescenti per `PO-21` e `PO-22`) con `pi_Q(S_n) = NORMAL` e `pi_Q_H(S_n) = h8`.
5. Poiche' `h8 notin H_active`, la proposizione `JourneyProgressive` risulta falsa per ogni `n >= 4` (`forall n >= 4, not JourneyProgressive(S_n)`).
6. Di conseguenza, la premessa `StateIsRecoverableFailure` e' verificata a `k = 4`, ma la conclusione `<> JourneyProgressive` non e' mai soddisfatta su `pi_counter`, falsificando formalmente la formula originaria nel modello globale `M_K`.

---

#### 9.2.4 Formule Temporali First-Order LTL Corrette (FO-LTL)
`[CAMBIO_SEMANTICO_MOTIVATO]`

La dinamica di sicurezza e liveness del modello e' re-ingegnerizzata mediante la sostituzione della liveness globale indifferenziata con due teoremi condizionali rigorosamente circoscritti:

* **FO-LTL Safety 1 (Safety Gate / Policy Guidance Corrected):**
```text
[] ( DecisionOutcomeAllowed ===> SafetyGateAllowed )
```

* **FO-LTL Safety 2 (Fencing e Lease Recovery):**
```text
[] ( not MonotonicFence(S_i, S_{i+1}) ===> X(StateIsRecoverableFailure) )
```

* **FO-LTL Safety 3 (Hash Chain Integrity):**
```text
[] ( not HashChainValid ===> X(StateIsSecurityLockdown) )
```

* **FO-LTL Liveness 4a (Deterministic Runtime Technical Recovery):**
`[CAMBIO_SEMANTICO_MOTIVATO]` `[IPOTESI_ESPLICITA]`
```text
[] ( (StateIsValidationError or StateIsRecoverableFailure) ===> F_{<= B_total}^+ StateIsNormal )
```
*(Condizionato ai requisiti ambientali di scheduling ed accodamento EIR, dove `B_total := B_ingress + B_sched` e' il limite massimo di passi per il dispatch del ripristino tecnico).*

* **FO-LTL Liveness 4b (Progressive Recovery under Local Human Stability):**
`[CAMBIO_SEMANTICO_MOTIVATO]` `[IPOTESI_ESPLICITA]`
```text
[] ( ((StateIsValidationError or StateIsRecoverableFailure) and StateIsHumanActive)
     ===> or(j=1 to B_total, ( and(i=0 to j-1, X^i StateIsHumanActive) and X^j JourneyProgressive )) )
```
*(Dimostrato come teorema condizionale parametrico locale subordinato alla stabilita' emotiva umana nella finestra finita di ripristino tecnico).*

* **FO-LTL Safety 5 (Invarianza dell'Oblio Crittografico / RFC-005):**
```text
forall c in I_case, [] ( CryptoShredExecuted_c ===> X([] KeyIsShredded_c) )
```

#### 9.2.5 Riduzione e Mapping verso LTL Proposizionale per Model Checkers
Per l'esecuzione diretta su strumenti di Model Checking Simbolico (NuSMV, SPIN, TLC), la quantificazione del primo ordine viene ridotta allo spazio discreto delle proposizioni atomiche mediante istanziazione finita sui domini `I_case`:

```text
Lowering_LTL(forall c in I_case, phi(c)) := and(i=1 to |I_case|, phi(c_i))
```

---

#### 9.2.6 Proprieta' CTL (Computation Tree Logic) e Garanzia di Agency

* **CTL System Agency Guarantee (`PO-10` / `PO-14` / `PO-20`):**
`[DISAMBIGUAZIONE]`

Sul modello vincolato dalle ipotesi etiche e di disponibilita' delle azioni `M_K^{ETH}` vale il teorema:

```text
M_K^{ETH} |= AG ( UserEngaged ===> EF (JourneyProgressive) )
```

**Struttura della Dimostrazione per Induzione Ben Fondata su Nat (`PO-14`):**
1. Si definisce la metrica di rango scalare:
```text
rank : S_space -> Nat
rank(S) := delta_rank_Q(pi_Q(S)) + delta_rank_H(pi_Q_H(S))
```
dove:
- `delta_rank_Q(q) := (q in F_oper) ? 0 : 1`
- `delta_rank_H(h) := (h in H_active) ? 0 : 1`

2. **Base Case (`PO-20`):**
```text
rank(S) == 0 <===> JourneyProgressive(S) == True
```

3. **Passo Induttivo e Decomposizione del Recupero (`PO-19a` / `PO-19b`):**
Per ogni stato `S` tale che `rank(S) > 0` e `UserEngaged(S) == True`, esiste un'azione abilitata `t` tale che lo stato successivo `S' = ApplyValidated(S, t, PASS)` soddisfa:
```text
rank(S') < rank(S) and UserEngaged(S') == True
```
- **PO-19a (Control Decrease):** Se `delta_rank_Q(pi_Q(S)) == 1`, l'esecuzione di un'azione di ripristino tecnico (classe `Q_fault/Q_recal` via `EV_SUCCESS`, `OPERATOR_REQUIRED` via `EV_OVERRIDE`, `SECURITY_LOCKDOWN` via `EV_REPAIR`) azzera `delta_rank_Q` lasciando inalterato `pi_Q_H(S)` per `INV-DECOUPLING-01`, preservando `UserEngaged`.
- **PO-19b (Human Target Validity):** Se `delta_rank_Q == 0` e `delta_rank_H(pi_Q_H(S)) == 1` (stati `H_trans = { h0, h8, h9 }`), l'azione umana abilitata (es. `HEV_STABILIZED` o `HEV_ASSESS_START`) transita l'automa in uno stato appartenente a `H_active` grazie alla totalita' di `ResolveNextHumanState` con fallback su `h2` (`PO-16`), azzerando `delta_rank_H`.

4. **Trasferimento al Modello Globale `M_K`:**
I cammini testimone esistenziali (`EF`) stabiliti su `M_K^{ETH}` si trasferiscono direttamente per inclusione di tracce al modello globale `M_K` per tutti gli stati raggiungibili `Reach(M_K^{ETH})`.

* **CTL Trap-Free Safety (Recuperabilita' dal Lockdown):**
```text
AG ( StateIsSecurityLockdown ===> EF (StateIsNormal or StateIsReadOnly) )
```

* **CTL Non-Terminal Successor Guarantee (Presenza di Transizioni Abilitate):**
```text
AG ( NonTerminalHumanState ===> EX(True) )
```

---

# CAPITOLO 10: STANDARD REFERENCE PROFILE 1 (SC-JCS-1)
## (Layer C - Profilo Concreto di Riferimento)

---

### 10.1 Definizione del Profilo SC-JCS-1 ed Incompatibilita' con RFC 8785

**SC-JCS-1 e' un profilo di canonizzazione proprietario ispirato concettualmente a JCS, ma NON COMPATIBILE a livello di hash con lo standard RFC 8785**, in quanto impone l'ordinamento delle stringhe Unicode Code Point ed impedisce tassativamente qualsiasi rappresentazione in virgola mobile.

---

### 10.2 Sottoinsieme di Serializzazione e Strict Signed Safe Integer Range

Un documento JSON `j in JSON_RFC8259` appartiene al sottoinsieme `J_SC` se e solo se tutti i numeri presenti sono interi compresi nell'intervallo chiuso:

```text
I_safe = [ -(2^53 - 1), +(2^53 - 1) ] = [ -9007199254740991, +9007199254740991 ]
```

Qualsiasi notazione contenente virgola mobile, notazione scientifica (`1e10`), `NaN` o `Infinity` `MUST` essere rifiutata con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 10.2.1 Regola sui Valori Probabilistici ed Indici in Basis Points [0, 10000]
Tutti i campi numerici rappresentanti probabilita', punteggi di confidenza o indici AGI `[0.0, 1.0]` **`MUST` essere convertiti e serializzati in JSON come numeri interi a punto fisso scalati di un fattore 10^4 (Basis Points, intervallo chiuso intero `[0, 10000]`)**.

#### 10.2.2 Formato Binario di Attestazione Decisionale `DecisionProof`
Il tipo dati `DecisionProof` citato nei contratti di Livello 2 costituisce una stringa esadecimale UTF-8 di 128 caratteri (Hex) rappresentante la firma digitale Ed25519 di 64 byte calcolata sull'array di byte canonici:

```text
DecisionProof := HexEncode( Sign_Ed25519(K_private, concat(Canon(P_comp), Canon(t))) )
```

---

### 10.3 Algoritmo di Serializzazione Canonica SC-JCS-1

1. **Whitespace Elimination:** Rimuovere tutti i caratteri di spaziatura esterni alle stringhe.
2. **String Escaping:** Applicare l'escaping unicamente per i caratteri di controllo `U+0000..U+001F`, `"` (virgolette), e `\` (barra retroversa).
3. **Unicode Normalization:** Applicare la normalizzazione Unicode Normalization Form C (NFC).
4. **Object Key Sorting (`Order_SC`):** Ordinare le chiavi degli oggetti in modo ascendente sulla base del confronto lessicografico dei valori scalari Unicode:
```text
Order_SC := UnicodeCodePointLex
```
5. **Set Semantics Deep Bottom-Up Array Sorting:** Per tutte le chiavi registrate nel `SetSemanticsRegistry` (`completed_nodes`, `permissions`, `prerequisites`, `roles`, `scopes`, `consent_items`, `revoked_items`, `competence_records`, `vault_records`), gli elementi dell'array `MUST` essere serializzati autonomamente in byte SC-JCS-1 ed ordinati in modo ascendente sulla base del confronto lessicografico byte-per-byte UTF-8 delle loro rappresentazioni canoniche.
6. **Invarianza Posizionale per Array Generici (Non-Set):** La sequenza logica degli elementi appartenenti ad un array non registrato nel `SetSemanticsRegistry` costituisce parte integrante della rappresentazione canonica dello stato. **E' tassativamente vietata qualsiasi trasformazione semantica o strutturale che perda o modifichi l'informazione posizionale.** Il runtime e' libero di adottare internamente qualsiasi struttura dati o rappresentazione in memoria, a condizione che la fase di serializzazione canonica ricostruisca senza alterazioni l'esatta sequenza logica originale.

---

### 10.4 Machine-Readable delta_M JSON Definition Contract

Il seguente contratto JSON definisce la funzione di transizione deterministica `delta_M` per l'automa DP-FSM. Il valore token `"event": "*"` costituisce la convenzione di fallback riservata al parser del runtime per rappresentare la regola jolly `delta_wildcard(sigma)` soggetta alla regola di mascheramento `RULE-EXPLICIT-SHADOWS-WILDCARD`.

```json
{
  "automaton_id": "SCINTILLA_RUNTIME_SAFETY_AUTOMATON",
  "specification_version": "4.5.6",
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

Il seguente contratto JSON definisce la funzione di transizione deterministica dell'automa DP-FSM del percorso umano `delta_H`.

**Norme Vincolanti di Interpretazione del Contratto Machine-Readable:**
1. Le transizioni recanti `"from": "*"` `SHALL NOT` essere applicate agli stati presenti nel vettore `terminal_states`.
2. La transizione recante `"to": "*"` (`RULE-WILDCARD-TARGET-REFLEXIVITY`, §2.2.2) `MUST` essere interpretata dal parser runtime come una macro-direttiva riservata:
   - Se applicata a una regola generica (es. `HEV_STEP_COMPLETED`), esegue uno stuttering step (`q_H' = q_H`), mantenendo lo stato corrente dell'automa.
   - Se applicata alla ricalibrazione (`HUMAN_RECALIBRATION_REQUIRED` su `HEV_STABILIZED`), invoca la valutazione dinamica della funzione pura `ResolveNextHumanState` (§2.3.2), preservando lo stato corrispondente al nodo attivo del Playbook con fallback difensivo su `STABILIZATION` (`h2`).

```json
{
  "automaton_id": "SCINTILLA_HUMAN_JOURNEY_AUTOMATON",
  "specification_version": "4.5.6",
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

I Test Vector concreti per la certificazione di conformita' dello Standard Reference Profile 1 sono formalmente definiti nell'artefatto normativo esterno: **`CONFORMANCE-TEST-SUITE-v4.5.6.JSON`**.

La suite di test comprende tre categorie di vettori:
1. **Positive Path Vectors:** Oggetti JSON di input e relative stringhe di byte canonizzate SC-JCS-1 con digest SHA-256 attesi.
2. **Negative Error Vectors:** Documenti contenenti float, cicli su nodi bloccanti o contratti FSM ambigui con verifica dei Runtime Error Codes sollevati (`70-89`).
3. **Security Vectors:** Transazioni recanti firme Ed25519 corrotte o tentativi di violazione della catena di hash `H_N`.

---

# CAPITOLO 12: STATO DI CERTIFICAZIONE E LIVELLI DI VERIFICA
## (Layer B - Specificazione Normativa)

---

### 12.1 Stato Normativo del Documento

La presente **SCINTILLA Core CANONICAL SPECIFICATION v4.5.6 Standard Revision** definisce la specifica normativa canonica e completa del dominio SCINTILLA Core.

Lo stato corrente del documento e':

**PROPOSAL-AUDITED & FORMALIZATION-READY — Consolidated Canonical Standard Edition (v4.5.6)**

La struttura formale e' definita, dimostrata corretta a livello logico, verificata priva di contraddizioni e pronta per la fase di formalizzazione interattiva via prover (Lean 4/Coq) e sviluppo del runtime di riferimento.

---

### 12.2 Architettura a Livelli di Formalizzazione e Metadati di Governance

Ogni runtime conforme `MUST` esportare nei propri metadati di governance la struttura di attestazione per la verifica di conformita':

```json
{
  "governance_conformance": {
    "conformance_suite_id": "SC-SUITE-v4.5.6-DIGEST-b7c1e48f",
    "runtime_attestation": {
      "runtime_artifact_digest": "SHA256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "compiler_fingerprint": "RUSTC-1.80.0-NIGHTLY-2026",
      "dependency_manifest_hash": "SHA256:8a14c2789ff2eb64c892ab18158b2e76fa3d789b1fa4e78127efed129a089078"
    },
    "conformance_status": "100_PERCENT_PASSED"
  }
}
```

---

### 12.3 Matrice dello Stato delle Proof Obligations (POCM v4.5.6)
`[CORREZIONE_FORMALE]`

La Proof Obligations Conformance Matrix (**POCM v4.5.6**) mappa le 22 Proof Obligations formali e le 4 ipotesi esplicite (`|N| = 26` nodi, 28 archi orientati `Dep_explicit`) ordinate in livelli topologici aciclici strettamente crescenti:

| Livello Topologico | ID Obbligo / Ipotesi | Tipologia Epistemica | Descrizione Sintetica | Stato di Verifica |
| :--- | :--- | :--- | :--- | :--- |
| **Livello 10** | `PO-05` | Definizione Primaria | Formalizzazione disaccoppiata di `Enabled(S, t, E)` | **SPECIFICATA** (Cap. 3.0.4) |
| **Livello 20** | `PO-01` | Fatto Normativo | Invarianza serializzazione Genesis State `s0` | **VERIFICATA** (Cap. 1.3.1) |
| **Livello 20** | `PO-02` | Fatto Normativo | Invariante consistenza proiezione Ledger | **SPECIFICATA** (Cap. 1.4.4) |
| **Livello 20** | `PO-03` | Fatto Normativo | Proprieta' di Determinismo SOS | **SPECIFICATA** (Cap. 3.0.1) |
| **Livello 20** | `PO-06` | Fatto Normativo | Corrispondenza semantica SOS (`PROPERTY-SOS`) | **SPECIFICATA** (Cap. 3.0.3) |
| **Livello 30** | `PO-16` | Scelta di Design | Totalita' `ResolveNextHumanState` con fallback `h2` | **INTEGRATA** (Cap. 2.3.2) |
| **Livello 40** | `PO-07` .. `PO-09` | Ipotesi EIR | Vincoli ambientali di scheduling, lease e clock | **ESPLICITATE** (Cap. 1.6 / 9.1) |
| **Livello 40** | `HYP-REC` | Ipotesi Esplicita | Esistenza di azioni di ripristino per attori | **ESPLICITATA** (Cap. 9.2.6) |
| **Livello 50** | `PO-18` | Lemma Derivato | Relazione `Enabled`-to-`StepSys` | **DIMOSTRATO** (Cap. 3.0.4) |
| **Livello 50** | `PO-20` | Lemma Derivato | Equivalenza `rank(S) == 0 <==> JourneyProgressive` | **DIMOSTRATO** (Cap. 9.2.6) |
| **Livello 52** | `PO-19a` | Lemma Derivato | Riduzione rango tecnico e preservazione `Q_H` | **DIMOSTRATO** (Cap. 9.2.6) |
| **Livello 52** | `PO-19b` | Lemma Derivato | Riduzione rango umano verso `H_active` | **DIMOSTRATO** (Cap. 9.2.6) |
| **Livello 54** | `PO-21` | Lemma Algebrico | Preservazione invariante `INV_{h8}` su `EV_SUCCESS` | **DIMOSTRATO** (Cap. 9.2.3) |
| **Livello 56** | `PO-22` | Teorema Esistenza | Costruzione del testimone infinito `W` | **DIMOSTRATO** (Cap. 9.2.3) |
| **Livello 60** | `PO-10` / `PO-14` | Teorema Condizionale | Dimostrazione CTL System Agency Guarantee | **DIMOSTRATO** (Cap. 9.2.6) |
| **Livello 60** | `PO-12` | Teorema Condizionale | FO-LTL Liveness 4a (Technical Recovery) | **DIMOSTRATO** (Cap. 9.2.4) |
| **Livello 60** | `PO-13` | Teorema Condizionale | FO-LTL Liveness 4b (Local Progressive Recovery) | **DIMOSTRATO** (Cap. 9.2.4) |
| **Livello 80** | `PO-17` | Contro-Modello | Falsificazione Liveness 4 originaria (`pi_counter`) | **FORMALIZZATO** (Cap. 9.2.3) |

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
export type BasisPoints = SafeInteger; // Intervallo chiuso intero [0, 10000]
```

### A.2 Reference TypeScript Helper Implementation

*Nota Informativa:* Il codice TypeScript contenuto nella presente sezione ha scopo puramente illustrativo. In caso di divergenza tra l'implementazione TypeScript ed il modello matematico algebrico, l'equazione pura del Capitolo 4.4 costituisce l'autorita' normativamente prevalente.

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
export function mapSMLToFSMEvent(doc: {
  conversation_outcome: string;
  proposed_transition: string;
  evidence_type: string;
}): string {
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

Un Playbook di Emancipazione serializzato `MUST` rispettare la seguente interfaccia TypeScript per la validazione di schema:

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

### B.2 Validazione di Aciclicita' sui Nodi Bloccanti

In fase di caricamento di un oggetto `EmancipationPlaybookGraph`, il Playbook Engine (Livello 2) `MUST` verificare che il sotto-insieme dei nodi con `action_type === 'REQUIRED_FOR_SYSTEM_STATE'` non contenga cicli orientati (`INV-PLAYBOOK-GRAPH-01`). Qualsiasi rilevazione di ciclo determina il rifiuto del caricamento con **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.

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

### C.3 Requisito di Conformita' dei Componenti Probabilistici (`REQ-PROBABILISTIC-INVARIANT-ALIGNMENT`)

1. **Vincolo Causale sulle Transizioni:** Qualsiasi componente probabilistico esterno (Livello 5 / LLM) integrato nel sistema `MUST` essere orchestrato dal Livello 4 in modo tale che i contenuti generati non possano causare ne' contribuire a causare transizioni di stato incompatibili con gli invarianti `INV-SUPREME-AGENCY-01`, `INV-ANTI-PATERNALISM-01` e `INV-CONTINUITY-OF-SUPPORT-01`.
2. **Valutazione a Scatola Nera del Runtime:** La conformita' al presente requisito e' valutata esclusivamente rispetto al comportamento osservabile del sistema complessivo e non rispetto alla struttura, ai prompt interni o ai meccanismi di funzionamento del componente probabilistico.

---

## ANNEX D: FORWARD DECLARATIONS, SYMBOL REGISTRY & INTERNAL RFC INDEX (LAYER A / INFORMATIVO)

### D.1 Registro dei Simboli e Dichiarazioni Preventive

Al fine di garantire la risoluzione topologica dei simboli per i formalizzatori matematici e per i sistemi di verifica formale (Coq, Lean 4, TLA+), la seguente tabella mappa la dichiarazione ed il dominio di appartenenza dei simboli primitivi utilizzati nella specifica:

| Simbolo Formale | Dominio di appartenenza / Firma algebrica | Descrizione sintetica | Definizione primaria |
| :--- | :--- | :--- | :--- |
| `P(L)` | `L_ledger -> S_space` | Funzione di Proiezione dal Ledger allo Stato | Capitolo 1.4.4 |
| `delta_nominal` | `(S_space * T_tx) -> S_space` | Transizione pura in assenza di errori di validazione | Capitolo 1.6.3 |
| `delta_err` | `(S_space * T_tx * ValidationResult) -> S_space` | Transizione pura di gestione dell'errore applicativo | Capitolo 1.6.3 |
| `R_exec` | `(S_space * T_tx) -> { ALLOW, DENY, RECALIBRATE }` | Predicato esecutivo puro del Policy Guidance Engine | Capitolo 4.1 |
| `DecisionProof` | `ByteString (128 Hex UTF-8)` | Impronta crittografica di attestazione della decisione | Capitolo 2.1 & 10.2.2 |
| `SMLOutcome` | `Enum` | Esito conversazionale sintattico decodificato | Capitolo 1.1.2 & C.1 |
| `rank` | `S_space -> Nat` | Metrica scalare per induzione ben fondata CTL | Capitolo 9.2.6 |

### D.2 Indice delle RFC Normative Interne

I riferimenti normativi interni di tipo `RFC-XXX` citati nel documento sono mappati alle sezioni corrispondenti della presente specifica secondo il seguente indice:

| Identificativo RFC | Titolo dell'Istituto Normativo | Sezione della Specifica Corrispondente |
| :--- | :--- | :--- |
| **`RFC-002`** | Human Journey Stasis & Paused State Semantics | Capitolo 3.4.1 (`[SOS-HUMAN-PAUSED-STUTTER]`) |
| **`RFC-003`** | Safe Integer Arithmetic & Dependency Reduction Score Calculation | Capitolo 1.7.3 (`AGI_computed`) |
| **`RFC-005`** | Cryptographic Erasure & Case Shredding Specification | Capitolo 1.5.2 & Capitolo 9.2.4 (`FO-LTL Safety 5`) |
| **`RFC-006`** | System & Error Transaction Construction Predicates | Capitolo 1.4.2 (`BuildErrorTx` / `BuildSystemTx`) |
| **`RFC-007`** | Genesis State Canonical Serialization Invariance | Capitolo 1.3.1 (`PROOF-OBLIGATION-GENESIS`) |
| **`RFC-008`** | TypeScript Type System & Data Interfaces Mapping | Annex A & Annex B |
| **`RFC-010`** | SC-JCS-1 Canonical Serialization Totality & Uniqueness | Capitolo 7.1.1 (`THEOREM-SERIALIZATION-TOTALITY`) |

---

**SCINTILLA Core v4.5.6 CANONICAL STANDARD REVISION**
* **Coverage:** Chapters 0.0–12 & Annexes A–D Fully Emitted
* **Governance Authority:** Single Source of Truth for SCINTILLA Core Domain

***Normative Information***  

**Author:** Cristian Evangelisti  
**Contact:** `opensource@cevangel.anonaddy.me`  
The Author is responsible for the definition, maintenance, and publication of this normative specification.  

***Copyright and License***  
Copyright (c) 2026 Cristian Evangelisti.  
This specification is distributed under the terms of the **GNU Free Documentation License (GNU FDL)**, Version 1.3 or any later version published by the Free Software Foundation; with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.  
A copy of the license is available at: https://www.gnu.org/licenses/fdl-1.3.html  
[License Information](https://www.gnu.org/licenses/fdl)  

***AI-Assisted Development***  
This specification was developed through an iterative process of analysis, design, review, and refinement assisted by Generative Artificial Intelligence systems (Large Language Models - LLMs). These systems were used exclusively as support tools for document design, review, formalization, and editing.  
All content within this specification has been selected, verified, modified where necessary, and explicitly approved by the Author. Artificial Intelligence systems possess no normative authority, do not determine the content of the specification, do not hold the role of author or co-author, and assume no editorial, technical, or regulatory liability regarding this document. The Author retains full responsibility for the content, consistency, correctness, and evolution of this specification.  

***Compatibility and Versioning***  
Unless otherwise indicated, compatibility between different versions of this specification is not implied. Every implementation must explicitly declare the version of the specification with which it complies.
