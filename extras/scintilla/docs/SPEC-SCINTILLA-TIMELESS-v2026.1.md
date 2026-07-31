# ✴ SCINTILLA CORE - CANONICAL SPECIFICATION
## Candidate Canonical Standard Edition v4.5.1

**Core Deterministico e Umano-Centrico per la Gestione di Percorsi di Emancipazione Personale**

* **Stato:** Specifica Normativa Canonica Formale (Single Source of Truth - Candidate Standard)
* **Edizione:** v4.5.1 Candidate Canonical Standard Edition (Human-Agency Centric & Formally Verified)
* **Autorità Governance:** Single Source of Truth Normativa per il dominio SCINTILLA CORE.
* **Terminologia Normativa:** RFC 2119 / RFC 8174 (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`).
* **Regola di Precedenza Normativa (`RULE-NORMATIVE-PRECEDENCE-01`):** In caso di divergenza o indecidibilità tra le descrizioni narrative in linguaggio naturale (Layer B) ed i contratti esecutivi machine-readable (Layer C / Capitolo 10), i contratti machine-readable di Layer C costituiscono l'autorità normativamente prevalente per l'esecuzione del runtime.

---

### STRATIFICAZIONE FORMALE DELLA SPECIFICA

Il presente documento è organizzato in tre livelli di astrazione formale espliciti:

1. **LAYER A (Modello Matematico Astratto):** Definizioni algebriche di insiemi, proiezioni, relazioni di equivalenza, funzioni pure deterministiche, automi ed equazioni di teoremi condizionate da ipotesi esplicite.
2. **LAYER B (Specifica Normativa e Politiche di Dominio):**
   * **Layer B1 (Assunzioni Normative & Principi Etici):** Principi etici, assiomi di confine (`AXIOM-`) e postulati di dominio non derivati.
   * **Layer B2 (Requisiti Ingegneristici di Sistema):** Requisiti operativi (`REQ-`), vincoli di sicurezza, tassonomia HOBM e codici di errore.
   * **Layer B3 (Regole Operative SOS):** Regole di inferenza della semantica operazionale (Small-Step Operational Semantics).
3. **LAYER C (Profilo Concreto di Riferimento):** Binding degli algoritmi crittografici, formato SC-JCS-1, contratti JSON e strutture dati concrete.

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE
## (Layer B1 - Assunzioni Normative & Principi Etici)

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

Il dominio SCINTILLA CORE è ingegnerizzato attorno ad una singola missione: **aumentare la capacità concreta di una persona fragile o vulnerabile di trasformare una situazione di instabilità in un percorso strutturato di emancipazione ed autonomia**.

#### 0.1.1 Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)
Ogni algoritmo, regola di policy, automa o trasformazione di stato `MUST` conformarsi incondizionatamente al seguente Invariante Supremo:

```math
\mathbf{INV-SUPREME-AGENCY-01}
```

> **"SCINTILLA CORE ha la missione di creare un automa di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e l'agency delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volontà e senza mai supportare azioni incompatibili con la dignità umana, la sicurezza ed i diritti altrui."**

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

```math
\forall S \in \mathcal{S}, \quad \text{SystemRole}(S) \neq \text{LifeDecisionMaker}(S)
```

Il sistema `SHALL`:
1. Aiutare la persona a comprendere la propria situazione attraverso l'analisi dei vincoli e delle risorse disponibili;
2. Proporre opzioni operative chiare e contestualizzate;
3. Esplicitare in modo trasparente le conseguenze prevedibili, i rischi ed i prerequisiti di ogni scelta;
4. Supportare la persona nella costruzione e nel mantenimento di un piano d'azione personalizzato (Playbook).

#### 0.2.2 Assioma di Sovranità del Consenso Umano (`AXIOM-HUMAN-CONSENT-SOVEREIGNTY`)
```math
\mathbf{AXIOM-HUMAN-CONSENT-SOVEREIGNTY}
```
> **"L'utente umano costituisce l'autorità decisionale suprema ed inalienabile del proprio percorso. Nessuna raccomandazione del sistema, inferenza del modello probabilistico o suggerimento dell'operatore può mutare lo stato di avanzamento personale senza il consenso esplicito, informato e revocabile dell'utente."**

---

### 0.3 DISACCOPPIAMENTO PERSONA-COMPORTAMENTO E DIRITTI

#### 0.3.1 Invariante di Separazione Persona-Comportamento (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)
Il sistema `MUST` mantenere una distinzione formale assoluta tra l'**Identità dell'Attore Umano** (rappresentata dall'identificatore di attore) e lo specifico **Payload della Transazione** $t$.

```math
\text{EvaluateAccess}(\alpha, t) := \text{RespectUserDignity}(\alpha) \land \text{EvaluatePayloadSafety}(t.\text{payload})
```

1. **Inviolabilità della Dignità della Persona:** L'utente, indipendentemente dai suoi trascorsi personali, legali o sociali, `SHALL` ricevere incondizionatamente il supporto del sistema per migliorare la propria condizione di vita. L'identificatore dell'attore non `SHALL` mai essere oggetto di squalifica o stigmatizzazione morale.
2. **Valutazione Rigorosa della Richiesta ($t$):** La funzione di valutazione valuta unicamente la sicurezza, la legalità e la sostenibilità dello specifico payload della transazione $t$.

---

# CAPITOLO 1: ALGEBRA ASTRATTA DEL MODELLO DI DOMINIO
## (Layer A & Layer B1/B2)

---

### 1.1 Formalizzazione dello Spazio degli Stati e delle Proiezioni

Lo Spazio degli Stati
```math
\mathcal{S}
```
è il sotto-spazio cartesiano dello stato primario valido di sistema.

#### 1.1.1 Definizione del Sottospazio dello Stato Primario (Layer A)
Lo stato primario del sistema
```math
\mathcal{S}
```
è formalizzato come l'insieme delle triple valide appartenenti al prodotto cartesiano dei domini di persistenza, controllo e buffer temporaneo:

```math
\mathcal{S} := \left\{ (p, i, a) \in \mathcal{S}_{\text{persistent}} \times \mathcal{S}_{\text{internal}} \times \mathcal{S}_{\text{auxiliary}} \mid \text{ValidState}(p, i, a) = \text{TRUE} \right\}
```

Dove i domini componenti sono definiti come:
1. **Dominio di Persistenza Ricostruibile dal Ledger:**
```math
\mathcal{S}_{\text{persistent}} := \mathcal{I}_{\text{case}} \times \mathcal{M}_{\text{prov}} \times \mathcal{Q}_{\text{consent}} \times \mathcal{K}_{\text{playbook}} \times \mathcal{Q}_{\text{revoked\_items}} \times \mathcal{K}_{\text{competence}} \times \mathcal{V}_{\text{vault}}
```
2. **Dominio Interno di Runtime e Sicurezza:**
```math
\mathcal{S}_{\text{internal}} := Q \times Q_H \times \mathcal{P}_{\text{active}} \times \mathcal{F}_{\text{lease}} \times \mathcal{H}_{\text{bound}} \times (\mathcal{T} \cup \{\text{null}\}) \times \mathcal{M}_{\text{metrics}}
```
3. **Dominio Ausiliario Volatile di Co-creazione:**
```math
\mathcal{S}_{\text{auxiliary}} := \mathcal{D}_{\text{drafts}}
```

#### 1.1.2 Vista Derivata Pura Disaccoppiata e Contatori di Interazione (Layer A)
La componente di stato derivato
```math
\mathcal{S}_{\text{derived}}
```
non costituisce una dimensione indipendente dello spazio
```math
\mathcal{S}
```
bensì una vista calcolata mediante la funzione pura:

```math
\text{Derive} : \mathcal{S}_{\text{persistent}} \times \mathcal{S}_{\text{internal}} \longrightarrow \mathcal{S}_{\text{derived}}
```
```math
\mathcal{S}_{\text{derived}} := \mathcal{O}_{\text{decision}} \times \mathcal{A}_{\text{index}}
```

La tupla dei contatori cumulativi di interazione
```math
\mathcal{M}_{\text{metrics}} \in \mathbb{N}^4
```
risiede nel dominio primario di controllo interno
```math
\mathcal{S}_{\text{internal}}
```
ed è normativamente ordinata come:

```math
\mathcal{M}_{\text{metrics}} := \left\langle c_{\text{interaction}}, \ c_{\text{rephrase}}, \ c_{\text{ambiguity}}, \ c_{\text{overwhelm}} \right\rangle
```

La mutazione deterministica della tupla
```math
\mathcal{M}_{\text{metrics}}' = \text{UpdateMetrics}(\mathcal{M}_{\text{metrics}}, t.\text{event}, \text{SMLOutcome})
```
è regolata dalle seguenti regole di incremento applicate da $\text{ApplyValidated}$:
1. $c_{\text{interaction}}$ si incrementa di $+1$ per ogni transazione valida $t$ elaborata con esito `PASS`.
2. $c_{\text{rephrase}}$ si incrementa di $+1$ quando l'esito conversazionale SML è `NEEDS_REPHRASING`.
3. $c_{\text{overwhelm}}$ si incrementa di $+1$ quando l'evento recepito è `HEV_EMOTIONAL_OVERWHELM`.
4. $c_{\text{ambiguity}}$ si incrementa di $+1$ quando la valutazione di policy restituisce l'esito `RECALIBRATE`.

#### 1.1.3 Proiezioni Canoniche dello Stato (Layer A)
La scomposizione dello stato astratto $S \in \mathcal{S}$ nelle sue componenti primarie è regolata esclusivamente dagli operatori di proiezione ortogonale:
```math
\pi_{\text{persistent}} : \mathcal{S} \longrightarrow \mathcal{S}_{\text{persistent}}
```
```math
\pi_{\text{internal}} : \mathcal{S} \longrightarrow \mathcal{S}_{\text{internal}}
```
```math
\pi_{\text{auxiliary}} : \mathcal{S} \longrightarrow \mathcal{S}_{\text{auxiliary}}
```

---

### 1.2 Interfaccia Osservabile Pubblica ed Equivalenza di Stato

#### 1.2.1 Funzione di Osservazione Pubblica Obs (Layer A)
La proiezione esterna dello stato verso le interfacce utente, API e viste pubbliche è governata dalla funzione pura di osservazione:

```math
\text{Obs} : \mathcal{S} \longrightarrow \mathcal{O}
```
```math
\text{Obs}(S) := \pi_{\text{persistent}}(S) \setminus \{ \text{elementi cifrati o soggetti a } \mathcal{Q}_{\text{revoked\_items}} \}
```

#### 1.2.2 Equivalenza di Stato Primario CoreState (Layer A)
Due stati astratti $S_1, S_2 \in \mathcal{S}$ sono semanticamente equivalenti nello stato primario se e solo se le loro proiezioni di persistenza e controllo interno sono identiche:

```math
S_1 \equiv_{\text{CoreState}} S_2 \iff \pi_{\text{persistent}}(S_1) = \pi_{\text{persistent}}(S_2) \land \pi_{\text{internal}}(S_1) = \pi_{\text{internal}}(S_2)
```

#### 1.2.3 Invariante di Irrilevanza Osservazionale del Buffer Temporaneo (`INV-AUX-IRRELEVANCE`) (Layer B1)
```math
\mathbf{INVARIANT-AUXILIARY-IRRELEVANCE}
```
```math
\forall S_1, S_2 \in \mathcal{S}, \quad S_1 \equiv_{\text{CoreState}} S_2 \implies \text{Obs}(S_1) = \text{Obs}(S_2)
```
*(Dichiara che le variazioni nel buffer volatile* $\mathcal{S}_{\text{auxiliary}}$ *non alterano le proiezioni osservabili dei diritti, del percorso o dello stato storico dell'utente).*

---

### 1.3 Assioma del Genesis State s0 (Layer A)

Lo stato iniziale di genesi:
```math
s_0 = P(\epsilon) \in \mathcal{S}
```
`MUST` contenere i valori predefiniti, con la tupla dei contatori dell'interazione:
```math
\mathcal{M}_{\text{metrics}} = \langle 0, 0, 0, 0 \rangle
```
posizionata nello stato iniziale della componente di controllo interno:
```math
\mathcal{S}_{\text{internal}}
```

```math
s_0 := \left\langle \text{case}_{\text{id}}=\text{null}, \ q=\text{NORMAL}, \ q_H=\text{UNASSESSED}, \ \mathcal{P}_{\text{active}}=\mathcal{P}_{\text{default}}, \ \mathcal{M}_{\text{prov}}=\emptyset, \ \mathcal{F}_{\text{lease}}=\langle 0, t_0 \rangle, \ \mathcal{Q}_{\text{consent}}=\emptyset, \ \mathcal{K}_{\text{playbook}}=\langle \text{null}, \text{null}, \emptyset \rangle, \ \mathcal{H}_{\text{bound}}=\text{AUTOMATED\_SUPPORT}, \ \mathcal{M}_{\text{metrics}}=\langle 0, 0, 0, 0 \rangle, \ t_{\text{pause\_start}}=\text{null}, \ \mathcal{Q}_{\text{revoked\_items}}=\emptyset, \ \mathcal{K}_{\text{competence}}=\emptyset, \ \mathcal{V}_{\text{vault}}=\emptyset, \ \mathcal{D}_{\text{drafts}}=\emptyset \right\rangle
```

*con vista derivata iniziale:*
```math
\text{Derive}(s_0) = \langle \mathcal{O}_{\text{decision}}=\text{NONE}, \ \mathcal{A}_{\text{index}}=0 \rangle
```

---

### 1.4 Transazioni, Involucro di Esecuzione e Ledger Immutabile L

#### 1.4.1 Spazio delle Transazioni T, Codifica EncodeTx e Busta di Esecuzione (Layer A)
Una transazione $t \in T$ è formalizzata come la tupla: 
```math
t := \langle \text{TransactionBody}, \text{execution\_envelope}, \text{proof} \rangle
```

La funzione pura di codifica per la persistenza è definita come:

```math
\text{EncodeTx} : T \longrightarrow \text{TransactionBody}
```
```math
\text{TransactionBody} := \left\langle \text{tx}_{\text{id}}, \text{case}_{\text{id}}, \text{seq}_{\text{num}}, \text{prev}_{\text{hash}}, \text{timestamp}, \text{actor}, \text{event}, \text{payload}, \text{policy}_{\text{binding}_{\text{hash}}}, \text{schema}_{\text{hash}}, \text{authorization}_{\text{snapshot}_{\text{hash}}}, \text{runtime}_{\text{profile}}, \text{specification\_id} \right\rangle
```

L'**Involucro di Esecuzione (Execution Envelope)** è la componente di metadati applicativi generata dal runtime che registra il risultato dell'elaborazione senza contaminare il payload di dominio:

```math
\text{execution\_envelope} := \left\langle \text{execution\_status}, \text{reason\_code}, \text{state\_mutations\_applied} \right\rangle
```

Quando una transazione viene elaborata durante lo stato di pausa dell'automa umano:
```math
h_7 = \text{HUMAN\_PAUSED}
```
l'involucro di esecuzione `MUST` registrare:
```math
\text{execution\_envelope} = \left\langle \text{"PROCESSED\_NO\_STATE\_EFFECT"}, \text{"HUMAN\_JOURNEY\_PAUSED"}, \text{false} \right\rangle
```

#### 1.4.2 Il Ledger come Monoide Libero L e Funzione Persist (Layer A)
Il registro immutabile delle decisioni (Ledger) è formalizzato come un Monoide Libero:
```math
\mathcal{L} := \langle T^*, \mathbin{\Vert}, \epsilon \rangle
```
La funzione pura di persistenza è:

```math
\text{Persist} : \mathcal{L} \times T \longrightarrow \mathcal{L}
```
```math
\text{Persist}(L, t) := L \mathbin{\Vert} \langle \text{EncodeTx}(t) \rangle
```

#### 1.4.3 Invariante di Consistenza della Proiezione del Ledger (Layer A)

```math
\mathbf{INVARIANT-LEDGER-PROJECTION-CONSISTENCY}
```
* **Ipotesi H1:** La funzione $\text{EncodeTx}: T \to \text{TransactionBody}$ preserva la semantica formale della transazione $t \in T$.
* **Ipotesi H2:** Il monoide libero $\mathcal{L}$ applica rigorosamente l'operazione di concatenazione associativa monotonica append-only.
* **Ipotesi H3:** La funzione di transizione $\text{ApplyValidated}$ è una funzione pura deterministica.
* **Tesi (Proof Obligation Induttiva su $|L|$):** Per qualsiasi Ledger $L \in \mathcal{L}$ e transazione $t \in T$, lo stato proiettato $P$ soddisfa l'equivalenza semantica dello stato primario rispetto al risultato della validazione ambientale:
```math
\forall L \in \mathcal{L}, \forall t \in T, \quad P(\text{Persist}(L, t)) \equiv_{\text{CoreState}} \text{ApplyValidated}(P(L), t, \text{ValidateEnvironment}(P(L), t, E))
```

---

### 1.5 Privacy, Revoca Logica Parziale e Crypto-Erasure Totale

#### 1.5.1 Revoca Logica Parziale (`SOFT_LOGICAL_REVOCATION`) (Layer B2)
La revoca di un singolo elemento informativo da parte dell'utente genera una transizione recante l'evento `EV_ITEM_PRIVACY_REVOKED`. L'applicazione della transazione aggiunge l'identificatore al registro:

```math
\mathcal{Q}_{\text{revoked\_items}}' = \mathcal{Q}_{\text{revoked\_items}} \cup \{\text{item\_id}\}
```
In sede di proiezione dello stato o consultazione via API ($\text{Obs}$), qualsiasi elemento avente
```math
\text{item\_id} \in \mathcal{Q}_{\text{revoked\_items}}
```
`MUST` restituire il valore nullo $\bot$.  

*Nota di Invarianza Strutturale:* La revoca logica parziale oscura la visibilità dei dati nella vista pubblica $\text{Obs}(S)$, ma **NON rimuove l'identificatore del nodo dall'insieme dei nodi completati** $V_{\text{completed}}$ in $\mathcal{K}_{\text{playbook}}$, preservando l'integrità del grafo e la deterministica riproducibilità dell'avanzamento.

#### 1.5.2 Oblio Crittografico Totale (`FULL_CRYPTO_SHREDDING`) (Layer B2 & Layer C)
L'oblio totale dell'intero caso utente `SHALL` essere eseguito mediante la distruzione irreversibile della chiave radice $K_{\text{case}}$ nel modulo KMS ed il cancellamento di ogni percorso di recupero:

```math
\text{ShredKey}(K_{\text{case}}) \implies \text{NoRecovery}(K_{\text{case}}) \quad \land \quad \forall v \in \mathcal{V}, \ \text{DecryptPayload}(\bot, E_{K_{\text{case}}}(v)) = \bot
```
L'atto di distruzione `MUST` registrare sul Ledger la transazione formale $t_{\text{shred}}$ recante l'evento `EV_CRYPTO_SHRED_EXECUTED`.

---

### 1.6 Validazione Ambientale Impura vs Funzione Pura ApplyValidated

#### 1.6.1 Predicato Impuro di Validazione Ambientale ValidateEnvironment e Requisiti di Cluster (Layer A & B2)
La validazione delle condizioni di contesto fisiche, temporali e crittografiche esterne allo stato algebrico è governata dal predicato impuro:

```math
\text{ValidateEnvironment} : \mathcal{S} \times T \times E \longrightarrow \text{ValidationResult}
```
```math
\text{ValidationResult} := \{ \text{PASS} \} \cup \mathcal{E}_{\text{validation}}
```

```math
\text{ValidateEnvironment}(S, t, E) = \begin{cases}
\text{PASS} & \text{se } \text{VerifySignature}(t.\text{proof}, t.\text{TransactionBody}, E.K_{\text{pubkey\_registry}}) = \text{TRUE} \\
& \quad \land \ |t.\text{timestamp} - E.t_{\text{wall}}| \le \Delta t_{\text{max}} \\
& \quad \land \ E.\text{LeaseManager}.\text{IsTokenValid}(S.\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}}) = \text{TRUE} \\
\text{ERR\_SIG} & \text{se la firma crittografica è invalida} \\
\text{ERR\_CLOCK} & \text{se } |t.\text{timestamp} - E.t_{\text{wall}}| > \Delta t_{\text{max}} \\
\text{ERR\_LEASE} & \text{se il lease di concorrenza è scaduto o invalido}
\end{cases}
```

```math
\mathbf{REQ-CLUSTER-CLOCK-SYNC} := \max_{i,j} |t_{\text{wall}, i} - t_{\text{wall}, j}| \le \delta_{\text{clock}} \quad \text{con } \delta_{\text{clock}} < \frac{1}{2} \Delta t_{\text{max}}
```
*(Impone che la sincronizzazione temporale tra i nodi esecutori sia limitata superiormente per prevenire rifiuti inconsistenti per clock skew).*

#### 1.6.2 Funzione Pura di Transizione di Stato ApplyValidated (Layer A)
La mutazione di stato è governata dalla funzione pura e deterministica $\text{ApplyValidated}$, priva di accesso diretto all'ambiente $E$:

```math
\text{ApplyValidated} : \mathcal{S} \times T \times \text{ValidationResult} \longrightarrow \mathcal{S}
```

#### 1.6.3 Requisito Normativo di Totalità di ApplyValidated (`REQ-APPLY-TOTALITY-POLICY`) (Layer B2)
La funzione pura $\text{ApplyValidated}$ è una **funzione totale** su $\mathcal{S}$ definita dalla seguente specifica a casi:

```math
\text{ApplyValidated}(S, t, \text{v\_res}) := \begin{cases}
\delta_{\text{nominal}}(S, t) & \text{se } \text{v\_res} = \text{PASS} \land \text{EvaluateGuards}(S, t) = \text{PASS} \\
S & \text{se } t.\text{event} = \text{EV\_HASH\_CORRUPT} \quad (\text{Stuttering Step su dati persistenti}) \\
\delta_{\text{err}}(S, t, \text{v\_res}) & \text{se } \text{v\_res} \in \mathcal{E}_{\text{validation}} \lor \text{EvaluateGuards}(S, t) = \text{FAIL}
\end{cases}
```

---

### 1.7 Indice Proxy Operativo di Guadagno di Agency (AGI_proxy)

L'Indice Proxy $\text{AGI}_{\text{proxy}} \in [0, 10000]$ (espresso in Basis Points interi) misura gli indicatori comportamentali descrittivi di avanzamento dell'utente sul sistema.

#### 1.7.1 Assunzione di Confine Epistemico ed Invariante di Isolamento Descrittivo (Layer B1)
```math
\mathbf{AXIOM-EPISTEMIC-BOUNDARY-AGI}
```
*(Dichiara che l'indice sintetico calcolato dal sistema costituisce unicamente un proxy descrittivo di tracciamento e non equivale alla misura interiore o psicologica dell'Agency Umana).*

```math
\mathbf{INV-AGI-DESCRIPTIVE-ISOLATION}
```
```math
\forall S \in \mathcal{S}, \forall t \in T, \quad \text{EvaluateGuards}(S, t) \text{ MUST NOT depend on } \text{AGI}_{\text{proxy}}(S)
```
*(Stabilisce che l'indice descrittivo AGI MUST NOT essere utilizzato come condizione di guardia nelle decisioni di sicurezza dell'automa M o nei predicati esecutivi R_exec).*

#### 1.7.2 Definizione Normativa di Invarianza per Stati Non-Attivi (Layer B1)
```math
\mathbf{DEF-AGI-PAUSED-STATE-INVARIANCE}
```
```math
\forall S_N \in \mathcal{S}, \quad \text{AGI}_{\text{proxy}}(S_N) := \begin{cases}
\text{AGI}_{\text{proxy}}(S_{N-1}) & \text{se } q_H(S_N) \in \{ \text{HUMAN\_PAUSED}, \text{HUMAN\_DECLINED\_ASSISTANCE} \} \\
\text{AGI}_{\text{computed}}(S_N) & \text{se } q_H(S_N) \notin \{ \text{HUMAN\_PAUSED}, \text{HUMAN\_DECLINED\_ASSISTANCE} \}
\end{cases}
```

#### 1.7.3 Calcolo Deterministico dell'AGI in Aritmetica Intera Sicura (Layer A)
Per tutti gli stati attivi, 
```math
\text{AGI}_{\text{computed}}(S) \in [0, 10000]
è calcolato unicamente in aritmetica intera sicura a 64 bit 
```math
I_{\text{safe}}
```
 con saturazione dei contatori a $10^6$ ed operatore di troncamento $\lfloor \dots \rfloor$:

```math
\text{AGI}_{\text{computed}}(S) := \left\lfloor \frac{w_1 \cdot \text{ClarityScore}_{\text{bp}}(S) + w_2 \cdot \text{ActionExecutionRatio}_{\text{bp}}(S) + w_3 \cdot \text{DependencyReductionScore}_{\text{bp}}(S)}{10000} \right\rfloor
```
*dove* $w_1, w_2, w_3 \in [0, 10000]$ sono interi tali che $w_1 + w_2 + w_3 = 10000$.

1. **ClarityScore in Basis Points:**
```math
\text{ClarityScore}_{\text{bp}}(S) := \begin{cases}
10000 & \text{se } c_{\text{interaction}} = 0 \\
\max\left(0, \ 10000 - \left\lfloor \frac{(c_{\text{rephrase}} + c_{\text{ambiguity}} + 2 \cdot c_{\text{overwhelm}}) \times 10000}{\max(1, c_{\text{interaction}})} \right\rfloor \right) & \text{se } c_{\text{interaction}} > 0
\end{cases}
```

2. **ActionExecutionRatio in Basis Points:**
```math
\text{ActionExecutionRatio}_{\text{bp}}(S) := \begin{cases}
0 & \text{se } \text{pb}_{\text{id}} = \text{null} \lor |V_P| = 0 \\
\left\lfloor \frac{|V_{\text{completed}} \cap V_P| \times 10000}{|V_P|} \right\rfloor & \text{se } \text{pb}_{\text{id}} \neq \text{null} \land |V_P| > 0
\end{cases}
```

3. **DependencyReductionScore in Basis Points:**
```math
\text{DependencyReductionScore}_{\text{bp}}(S) := \begin{cases}
0 & \text{se } |V_{\text{completed}}| = 0 \\
\left\lfloor \frac{|\{ v \in V_{\text{completed}} \mid \text{IsEmpoweredAction}(v, S) \}| \times 10000}{|V_{\text{completed}}|} \right\rfloor & \text{se } |V_{\text{completed}}| > 0
\end{cases}
```
dove il predicato booleano puro $\text{IsEmpoweredAction}(v, S)$ è formalizzato come:
```math
\text{IsEmpoweredAction}(v, S) \iff \left( v.\text{action\_type} \in \{\text{USER\_CONFIRMED\_STEP}, \text{REQUIRED\_FOR\_SYSTEM\_STATE}\} \land v.\text{gained\_skill} \neq \text{null} \right)
```

---

### 1.8 Contratto del Modulo Crittografico Astratto (`CryptoProviderContract`) (Layer A & C)

Ogni implementazione esecutiva di SCINTILLA CORE `MUST` integrare un modulo crittografico conforme alla seguente interfaccia astratta:

```math
\mathbf{CryptoProviderContract} := \langle \text{DeriveKey}, \text{EncryptPayload}, \text{DecryptPayload}, \text{ShredKey}, \text{VerifySignature} \rangle
```

1. $\text{DeriveKey}(K_{\text{parent}}, \text{context}) \to K_{\text{child}}$: Derivazione deterministica chiavi effimere tramite HKDF.
2. $\text{EncryptPayload}(K_{\text{item}}, v) \to \text{Payload}_{\text{encrypted}}$: Cifratura autenticata AES-256-GCM.
3. $\text{DecryptPayload}(K_{\text{item}}, \text{Payload}_{\text{encrypted}}) \to v \mid \bot$: Decifratura ed autenticazione payload.
4. $\text{ShredKey}(K_{\text{id}}) \to \text{TRUE}$: Distruzione del materiale di chiave ed elisione dei percorsi di recupero ($\text{NoRecovery}$).
5. $\text{VerifySignature}(\text{proof}, \text{data}, K_{\text{pub}}) \to \mathbb{B}$: Verifica firma digitale Ed25519.

---

# CAPITOLO 2: ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI
## (Layer A & Layer B2)

---

### 2.1 Modello di Isolamento Stratificato a 6 Livelli

L'architettura di SCINTILLA CORE è strutturata in 6 livelli funzionali ad isolamento unidirectionale rigoroso, dove i livelli superiori non possiedono alcuna autorità di scrittura diretta sullo stato di runtime:

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

```math
M := \langle Q, \Sigma, T_{\text{JSON}}, \delta_M, q_0, F_{\text{oper}} \rangle
```

1. **Insieme degli Stati Canonici $Q$ ($|Q|=7$):**
```math
Q = \{ \text{NORMAL } (q_0), \text{REQUIRE\_RECALIBRATION } (q_1), \text{VALIDATION\_ERROR } (q_2), \text{RECOVERABLE\_FAILURE } (q_3), \text{OPERATOR\_REQUIRED } (q_4), \text{SECURITY\_LOCKDOWN } (q_5), \text{SAFE\_READ\_ONLY\_MODE } (q_6) \}
```
2. **Stato Iniziale:** $q_0 = \text{NORMAL}$.
3. **Insieme degli Stati Operativamente Stabili $F_{\text{oper}}$:**
```math
F_{\text{oper}} = \{ \text{NORMAL}, \text{SAFE\_READ\_ONLY\_MODE} \}
```

#### 2.2.1 Definizione di Dominio DP-FSM e Precondizione Statica di Unicità
Ai fini della specifica SCINTILLA CORE, un automa DP-FSM indica una macchina a stati finiti la cui relazione di transizione è deterministica a valle dell'applicazione della funzione di risoluzione prioritaria $\mathbf{Resolve}(q, \sigma)$.

Un contratto di automa è valido ed eseguibile se e solo se soddisfa la precondizione statica di unicità:

```math
\mathbf{ValidFSMContract} \iff \left( \forall q \in Q, \forall \sigma \in \Sigma, \ |\delta_{\text{explicit}}(q, \sigma)| \le 1 \right) \ \land \ \left( \forall \sigma \in \Sigma, \ |\delta_{\text{wildcard}}(\sigma)| \le 1 \right)
```

#### 2.2.2 Regola di Mascheramento delle Wildcard e Funzione Algebrica Resolve
```math
\mathbf{RULE-EXPLICIT-SHADOWS-WILDCARD}
```
> **"The wildcard transition rule $\delta_{\text{wildcard}}(\sigma)$ SHALL NOT participate in transition resolution when an explicit transition $\delta_{\text{explicit}}(q, \sigma)$ exists for the given state $q$ and event $\sigma$."**

La risoluzione deterministica della transizione nell'automa DP-FSM è governata dalla funzione algebrica pura:

```math
\mathbf{Resolve}(q, \sigma) := \begin{cases}
q & \text{se } q \in F_H \quad (\text{Terminal Trap Rule}) \\
\delta_{\text{explicit}}(q, \sigma) & \text{se } \delta_{\text{explicit}}(q, \sigma) \neq \bot \land q \notin F_H \\
\delta_{\text{wildcard}}(\sigma) & \text{se } \delta_{\text{explicit}}(q, \sigma) = \bot \land \delta_{\text{wildcard}}(\sigma) \neq \bot \land q \notin F_H \\
q & \text{se } \delta_{\text{explicit}} = \bot \land \delta_{\text{wildcard}} = \bot \land q \notin F_H \quad (\text{Implicit Stuttering})
\end{cases}
```

#### 2.2.3 Partizione dell'Alfabeto Sigma (Layer B2)
L'alfabeto degli eventi di sistema $\Sigma$ ($|\Sigma|=10$) è partizionato nei seguenti sotto-insiemi disgiunti:

1. **Eventi di Business ($\Sigma_{\text{business}}$):** Eventi di mutazione operativa e di progresso del caso utente:
```math
\Sigma_{\text{business}} := \{ \text{EV\_SUCCESS}, \text{EV\_ABANDON}, \text{EV\_SML\_FAIL}, \text{EV\_LEASE\_EXP}, \text{EV\_TIMEOUT} \}
```
2. **Eventi di Ripristino Operativo ($\Sigma_{\text{recovery}}$):** Eventi di override ed intervento autorizzato per il ripristino di stato:
```math
\Sigma_{\text{recovery}} := \{ \text{EV\_OVERRIDE}, \text{EV\_REPAIR} \}
```
3. **Eventi Amministrativi e di Tutela Diritti ($\Sigma_{\text{administrative}}$):** Eventi relativi all'integrità crittografica e alla gestione dei diritti dell'utente:
```math
\Sigma_{\text{administrative}} := \{ \text{EV\_HASH\_CORRUPT}, \text{EV\_ITEM\_PRIVACY\_REVOKED}, \text{EV\_CRYPTO\_SHRED\_EXECUTED} \}
```

#### 2.2.4 Gestione della Stasi Operativa in SAFE_READ_ONLY_MODE (q6) (Layer B2)
Quando l'automa $M$ si trova nello stato:
```math
q_6 = \text{SAFE\_READ\_ONLY\_MODE}
```

1. Per tutti gli eventi di business $\sigma \in \Sigma_{\text{business}}$, la funzione $\delta_M$ impone uno stuttering step ($q_6 \to q_6$), precludendo qualsiasi mutazione dello stato operativo.
2. Per tutti gli eventi amministrativi $\sigma \in \Sigma_{\text{administrative}}$, la funzione $\delta_M$ ammette l'elaborazione e la persistenza della transizione sul Ledger immutabile $\mathcal{L}$, garantendo l'esercizio dei diritti dell'utente anche in stasi operativa.
3. Per gli eventi di ripristino $\sigma \in \Sigma_{\text{recovery}}$, la funzione $\delta_M$ transita lo stato verso $\text{NORMAL}$ secondo il contratto formale §10.4.

---

### 2.3 Human Journey State Machine H (Layer A & B2)

L'evoluzione concettuale del percorso umano dell'utente è modellata dall'automa DP-FSM di dominio $\mathcal{H}$:

```math
\mathcal{H} := \langle Q_H, \Sigma_H, \delta_H, q_{H0}, F_H \rangle
```

1. **Insieme degli Stati del Percorso Umano $Q_H$ ($|Q_H|=12$):**
```math
Q_H = \{ \text{UNASSESSED}, \text{INITIAL\_ASSESSMENT}, \text{STABILIZATION}, \text{DOCUMENT\_RECOVERY}, \text{EMPLOYMENT\_READINESS}, \text{FINANCIAL\_AUTONOMY}, \text{SUSTAINED\_INDEPENDENCE}, \text{HUMAN\_PAUSED}, \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{HUMAN\_GOAL\_CHANGED}, \text{HUMAN\_DECLINED\_ASSISTANCE}, \text{PREVENTIVE\_STANDBY} \}
```
2. **Stato Iniziale:** $q_{H0} = \text{UNASSESSED}$.
3. **Insieme degli Stati Target / Terminali $F_H$:**
```math
F_H = \{ \text{HUMAN\_DECLINED\_ASSISTANCE} \}
```
4. **Alfabeto degli Eventi Umani $\Sigma_H$ ($|\Sigma_H|=14$):**
```math
\Sigma_H = \{ \text{HEV\_ASSESS\_START}, \text{HEV\_STABILIZED}, \text{HEV\_DOCS\_OBTAINED}, \text{HEV\_JOB\_READY}, \text{HEV\_FINANCE\_OK}, \text{HEV\_INDEPENDENCE\_ACHIEVED}, \text{HEV\_RELAPSE\_REGRESS}, \text{HEV\_RECALIBRATION\_REQ}, \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_RESUME\_REQUESTED}, \text{HEV\_GOAL\_UPDATE}, \text{HEV\_DECLINE\_ALL}, \text{HEV\_EMOTIONAL\_OVERWHELM}, \text{HEV\_PREVENTIVE\_SUPPORT\_REQ} \}
```

#### 2.3.1 Dinamica dello Stato h11 (PREVENTIVE_STANDBY) (Layer B2)
Lo stato:
```math
h_{11} = \text{PREVENTIVE\_STANDBY}
```
definisce una condizione di equilibrio ad alta autonomia ed azione preventiva:
1. **Ingresso in $h_{11}$:** La transizione dallo stato di indipendenza a $h_{11}$ si verifica su emissione dell'evento:
```math
\text{HEV\_PREVENTIVE\_SUPPORT\_REQ} \in \Sigma_H
```

2. **Uscita per Ricalibrazione:** La ricezione degli eventi:
```math
\text{HEV\_EMOTIONAL\_OVERWHELM}
```
 o 
```math
\text{HEV\_RELAPSE\_REGRESS}
```
forza il rientro diretto dallo stato $h_{11}$ allo stato di ricalibrazione `HUMAN_RECALIBRATION_REQUIRED`, riattivando il supporto focalizzato del Playbook Engine senza resettare lo storico delle competenze acquisite.

---

### 2.4 Equazione Matematica del Sistema Reattivo Composito (Layer A)

Il sistema reattivo globale di SCINTILLA CORE è modellato dallo spazio di stato composito $S_C = Q \times Q_H$. 

La funzione di transizione pura dell'automa composito $\delta_C : (Q \times Q_H) \times (\Sigma \cup \Sigma_H) \longrightarrow (Q \times Q_H)$ è definita dall'equazione a casi:

```math
\delta_C((q, q_H), \sigma_C) = \begin{cases} 
(\delta_M(q, \sigma_C, T_{\text{JSON}}), q_H) & \text{se } \sigma_C \in \Sigma \\
(q, \mathbf{Resolve}(q_H, \sigma_C)) & \text{se } \sigma_C \in \Sigma_H \land q \in F_{\text{oper}} \\
(q, \mathbf{Resolve}(q_H, \sigma_C)) & \text{se } \sigma_C \in \Sigma_H \land q \in \{\text{VALIDATION\_ERROR}, \text{RECOVERABLE\_FAILURE}\} \\
(q, \mathbf{Resolve}(q_H, \sigma_C)) & \text{se } \sigma_C \in \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \land q \in \{\text{OPERATOR\_REQUIRED}, \text{SECURITY\_LOCKDOWN}\} \\
(q, q_H) & \text{se } \sigma_C \in \Sigma_H \setminus \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \land q \in \{\text{OPERATOR\_REQUIRED}, \text{SECURITY\_LOCKDOWN}\}
\end{cases}
```

1. **Invariante di Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`):** Gli eventi dell'automa umano $\Sigma_H$ non mutano lo stato di runtime $Q$. Viceversa, errori tecnici di sistema:
```math
q \in \{\text{VALIDATION\_ERROR}, \text{RECOVERABLE\_FAILURE}\}
```
`SHALL NOT` paralizzare l'evoluzione concettuale dello stato umano $Q_H$.

2. **Eccezione di Sovranità Umana in Lockdown:** In presenza di blocco critico di sicurezza:
```math
q = \text{SECURITY\_LOCKDOWN}
```
le sole transizioni dell'automa umano ammesse per la registrazione ed applicazione immediata sono quelle di richiesta di pausa o revoca del supporto (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

# CAPITOLO 3: SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)
## (Layer B3 - Regole Operative SOS)

---

### 3.0 Mappa di Osservazione e Corrispondenza Relazione-Funzione

La Mappa di Osservazione Canonica $\pi_{\text{SOS}}$ estrae la tripla dello stato di valutazione della semantica operazionale:

```math
\pi_{\text{SOS}} : \mathcal{S} \longrightarrow \left( Q \times Q_H \times \mathcal{S}_{\text{persistent}} \right)
```
```math
\pi_{\text{SOS}}(S) := \langle \pi_Q(S), \ \pi_{Q_H}(S), \ \pi_{\text{persistent}}(S) \rangle
```

#### 3.0.1 Proprietà Derivata di Determinismo della Relazione SOS (`PROPERTY-SOS-DETERMINISM`) (Layer B1)
```math
\mathbf{PROPERTY-SOS-DETERMINISM}
```
```math
\forall S \in \mathcal{S}, \forall t \in T, \quad \left( \pi_{\text{SOS}}(S) \xrightarrow{t}_{\text{Sys}} \sigma_1 \land \pi_{\text{SOS}}(S) \xrightarrow{t}_{\text{Sys}} \sigma_2 \right) \implies \sigma_1 = \sigma_2
```
*(Deriva direttamente dalla purezza e dal determinismo delle funzioni \delta_M, \delta_H e ApplyValidated).*

#### 3.0.2 Requisito di Progresso SOS Condizionato (`REQ-SOS-CONDITIONED-PROGRESS`) (Layer B2)
```math
\mathbf{REQ-SOS-CONDITIONED-PROGRESS}
```
```math
\forall (\pi_{\text{SOS}}(S), t) \in \text{Domain}(\xrightarrow{t}_{\text{Sys}}), \quad \exists! \sigma' \in \left( Q \times Q_H \times \mathcal{S}_{\text{persistent}} \right) \quad \text{t.c.} \quad \pi_{\text{SOS}}(S) \xrightarrow{t}_{\text{Sys}} \sigma'
```

#### 3.0.3 Proprietà di Corrispondenza Relazionale-Funzionale (Layer A)

```math
\mathbf{PROPERTY-SOS-SEMANTIC-CORRESPONDENCE}
```
* **Ipotesi H1:** La relazione di transizione SOS $\to_{\text{Sys}}$ soddisfa la Proprietà di Determinismo (`PROPERTY-SOS-DETERMINISM`).
* **Ipotesi H2:** Il predicato di validazione d'ambiente restituisce l'esito $\text{ValidateEnvironment}(S, t, E) = \text{PASS}$.
* **Ipotesi H3:** La funzione $\text{ApplyValidated}$ ammette come parametro d'ingresso il risultato della validazione.
* **Tesi (Proof Obligation su analisi per casi):** La transizione relazionale SOS 
```math
\pi_{\text{SOS}}(S) \xrightarrow{t}_{\text{Sys}} \langle q', q_H', S_{\text{persistent}}' \rangle
```
sussiste se e solo se lo stato successivo $S' = \text{ApplyValidated}(S, t, \text{PASS})$ soddisfa la coincidenza di proiezioni:
```math
S' = \text{ApplyValidated}(S, t, \text{PASS}) \quad \land \quad q' = \pi_Q(S') \quad \land \quad q_H' = \pi_{Q_H}(S') \quad \land \quad S_{\text{persistent}}' = \pi_{\text{persistent}}(S')
```

---

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore (Layer B2)

Una transizione $t \in T$ con evento $\sigma_C = \text{event}(t)$ ed emessa dall'attore $\alpha = \text{actor}(t)$ è autorizzata se e solo se soddisfa il predicato booleano $\text{Authorized}(\sigma_C, \text{type}(\alpha))$:

```math
\text{Authorized}(\sigma_C, \text{type}(\alpha)) \iff \begin{cases}
\text{True} & \text{se } \sigma_C \in \Sigma_H \land \text{type}(\alpha) \in \{\text{USER}, \text{OPERATOR}, \text{SYSTEM}\} \\
\text{True} & \text{se } \sigma_C \in \Sigma_{\text{business}} \cup \Sigma_{\text{administrative}} \land \text{type}(\alpha) = \text{SYSTEM} \\
\text{True} & \text{se } \sigma_C = \text{EV\_ITEM\_PRIVACY\_REVOKED} \land \text{type}(\alpha) \in \{\text{USER}, \text{OPERATOR}\} \\
\text{True} & \text{se } \sigma_C \in \Sigma_{\text{recovery}} \land \text{type}(\alpha) = \text{OPERATOR} \\
\text{False} & \text{in tutti gli altri casi (compreso qualsiasi tentativo con } \text{type}(\alpha) = \text{LLM})
\end{cases}
```

---

### 3.2 Meta-Regole SOS della Sicurezza di Runtime (M) (Layer B3)

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q' = \mathbf{Resolve}(q, \sigma_C) \quad \text{EvaluateGuards}(S, t) = \text{PASS}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q', q_H, \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-META-SAFETY}]
```

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma \quad (\text{v\_res} \in \mathcal{E}_{\text{validation}} \lor \neg \text{Authorized}(\sigma_C, \text{type}(\alpha)) \lor \text{EvaluateGuards}(S, t) = \text{FAIL}) \quad q' = \begin{cases} q & \text{se } q \in \{\text{SECURITY\_LOCKDOWN}, \text{SAFE\_READ\_ONLY\_MODE}\} \\ \text{VALIDATION\_ERROR} & \text{altrimenti} \end{cases}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q', q_H, \text{ApplyValidated}(S, \text{BuildErrorTx}(\sigma_C), \text{v\_res}) \rangle} \quad [\text{SOS-META-SAFETY-FAIL}]
```

#### 3.2.1 Meta-Regole SOS di Ripristino ed Override da Operatore (Layer B3)
```math
\frac{\sigma_C = \text{EV\_REPAIR} \quad q \in \{\text{SECURITY\_LOCKDOWN}, \text{SAFE\_READ\_ONLY\_MODE}\} \quad \text{type}(\alpha) = \text{OPERATOR} \quad \text{ValidRepairPatch}(p)}{\langle q, q_H, S \rangle \xrightarrow{\text{EV\_REPAIR}}_{\text{Sys}} \langle \text{NORMAL}, q_H, \text{ApplyCompensativeRepair}(S, p) \rangle} \quad [\text{SOS-COMPENSATIVE-REPAIR}]
```

```math
\frac{\sigma_C = \text{EV\_OVERRIDE} \quad q = \text{OPERATOR\_REQUIRED} \quad \text{type}(\alpha) = \text{OPERATOR} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS}}{\langle \text{OPERATOR\_REQUIRED}, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle \text{NORMAL}, q_H, \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-OPERATOR-OVERRIDE}]
```

---

### 3.3 Meta-Regole SOS per Competenze e Custodia Credenziali (Layer B3)

#### 3.3.1 Meta-Regola SOS per la Palestra delle Competenze (`[SOS-COMPETENCE-UPDATE]`)
Quando l'utente completa un nodo di Playbook $v \in V_P$ recante un attributo di competenza acquisita:

```math
\frac{\sigma_C = \text{HEV\_STEP\_COMPLETED} \quad v.\text{gained\_skill} = \langle k, l \rangle \quad \mathcal{K}_{\text{competence}}' = \mathcal{K}_{\text{competence}} \cup \{ \langle k, l, t_{\text{wall}} \rangle \}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, q_H, \text{ApplyValidated}(S, t[\mathcal{K}_{\text{competence}} \mapsto \mathcal{K}_{\text{competence}}'], \text{PASS}) \rangle} \quad [\text{SOS-COMPETENCE-UPDATE}]
```

#### 3.3.2 Meta-Regola SOS per la Custodia Credenziali (`[SOS-VAULT-RECORD]`)
All'ottenimento o verifica oggettiva di un documento d'identità o attestato formale:

```math
\frac{\sigma_C = \text{HEV\_DOCS\_OBTAINED} \quad \text{doc} = \langle \text{doc\_id}, H_{\text{doc}}, \text{VERIFIED} \rangle \quad \mathcal{V}_{\text{vault}}' = \mathcal{V}_{\text{vault}} \cup \{ \text{doc} \}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, \text{DOCUMENT\_RECOVERY}, \text{ApplyValidated}(S, t[\mathcal{V}_{\text{vault}} \mapsto \mathcal{V}_{\text{vault}}'], \text{PASS}) \rangle} \quad [\text{SOS-VAULT-RECORD}]
```

---

### 3.4 Meta-Regole SOS del Percorso Umano (H) e Sovranità (Layer B3)

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma_H \quad q \in F_{\text{oper}} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q_H' = \mathbf{Resolve}(q_H, \sigma_C) \quad \mathcal{R}_{\text{exec}}(S, t) = \text{ALLOW}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, q_H', \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-META-HUMAN}]
```

```math
\frac{\sigma_C \in \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \quad q \notin F_{\text{oper}} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, \mathbf{Resolve}(q_H, \sigma_C), \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-HUMAN-SOVEREIGNTY-LOCKDOWN}]
```

#### 3.4.1 Meta-Regola SOS di Stasi in Stato Pausa (`[SOS-HUMAN-PAUSED-STUTTER]`)
Quando l'automa del percorso umano si trova nello stato:
```math
q_H = \text{HUMAN\_PAUSED}
```
e giunge un qualsiasi evento $t$ non corrispondente a `HEV_RESUME_REQUESTED` o `HEV_DECLINE_ALL`, l'automa esegue uno stuttering step preservando lo stato di stasi ed emettendo una transazione recante l'involucro di esecuzione $e_{\text{paused}}$:

```math
\frac{q_H = \text{HUMAN\_PAUSED} \quad \sigma_C \in \Sigma_H \setminus \{ \text{HEV\_RESUME\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \quad e_{\text{paused}} = \langle \text{"PROCESSED\_NO\_STATE\_EFFECT"}, \text{"HUMAN\_JOURNEY\_PAUSED"}, \text{false} \rangle}{\langle q, \text{HUMAN\_PAUSED}, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, \text{HUMAN\_PAUSED}, \text{ApplyValidated}(S, t[e \mapsto e_{\text{paused}}], \text{PASS}) \rangle} \quad [\text{SOS-HUMAN-PAUSED-STUTTER}]
```

#### 3.4.2 Meta-Regola SOS di Timeout ed Inattività Umana (`[SOS-HUMAN-TIMEOUT]`)
Quando l'automa umano si trova in:
```math
q_H = \text{HUMAN\_PAUSED}
```
ed il tempo di permanenza supera la soglia parametrizzata:
```math
\theta_{\text{inactivity\_timeout}}
```

```math
\frac{q_H = \text{HUMAN\_PAUSED} \quad (E.t_{\text{wall}} - t_{\text{pause\_start}}) > \theta_{\text{inactivity\_timeout}} \quad t_{\text{timeout}} = \text{BuildSystemTx}(\text{HEV\_RECALIBRATION\_REQ})}{\langle q, \text{HUMAN\_PAUSED}, S \rangle \xrightarrow{t_{\text{timeout}}}_{\text{Sys}} \langle q, \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{ApplyValidated}(S, t_{\text{timeout}}, \text{PASS}) \rangle} \quad [\text{SOS-HUMAN-TIMEOUT}]
```

#### 3.4.3 Meta-Regola SOS di Adattamento per Sopraffazione Emotiva (`[SOS-EMOTIONAL-OVERWHELM]`)
Alla rilevazione di uno stato di sopraffazione emotiva segnalato dall'utente o dal parser SML:

```math
\frac{\sigma_C = \text{HEV\_EMOTIONAL\_OVERWHELM}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-EMOTIONAL-OVERWHELM}]
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
```math
\mathcal{R}_{\text{exec}} : \mathcal{S} \times T \longrightarrow \{ \text{ALLOW}, \text{DENY}, \text{RECALIBRATE} \}
```
l'unico direttamente eseguibile dal runtime al Livello 2.

---

### 4.2 Definizione Algebrica del Policy Bundle (Layer A)

Un `PolicyBundle` $\mathcal{P}$ è formalizzato come la tupla algebrica:

```math
\mathcal{P} := \left\langle \text{PolicyID}, \text{Version}, \Theta, \mathcal{R}_{\text{exec}}, \text{Sig}_\mathcal{P} \right\rangle
```

* $\text{PolicyID} \in \mathcal{I}$: Identificatore unico della policy (UUIDv7).
* $\text{Version} \in V$: Versione della policy nello Spazio delle Versioni $V$ (§6.1).
* $\Theta$: Lo spazio dei parametri di configurazione e soglie (es. $\theta_{\text{duration}}, \theta_{\text{confidence}}$).
* $\mathcal{R}_{\text{exec}}$: Predicato esecutivo puro valutato sullo stato e sulla transazione.
* $\text{Sig}_\mathcal{P}$: La firma crittografica dell'autorità di policy emittente calcolata su $\text{Canon}(\mathcal{P})$.

---

### 4.3 Composizione di Policy e Regola di Versione Composita (Layer A & B2)

L'operatore di composizione algebrica $\oplus$ produce il bundle composito $\mathcal{P}_{\text{comp}} = \mathcal{P}_1 \oplus \mathcal{P}_2$ mediante la funzione esplicita $\text{ComposePolicy}$:

```math
\text{ComposePolicy}(\mathcal{P}_1, \mathcal{P}_2) := \left\langle \text{PolicyID}_{\text{comp}}, \text{CompositePolicyVersion}, \text{CompositePolicyDigest}, \Theta_1 \cup \Theta_2, \mathcal{R}_{\text{exec, comp}}, \text{Sig}_{\text{comp}} \right\rangle
```

1. **Impronta Crittografica Composita (Content-Addressed Binary Digest):**
   L'identità immutabile del bundle composito è determinata dalla concatenazione binaria esplicita dei due digest a 256 bit disposti in ordine lessicografico non codificato:
```math
\text{CompositePolicyDigest} := \text{SHA256}\left( A_{\text{sorted}} \mathbin{\Vert} B_{\text{sorted}} \right)
```
dove $A_{\text{sorted}}$ e $B_{\text{sorted}}$ sono i due array di 32 byte binari ordinati secondo la relazione:
```math
A_{\text{sorted}} \le B_{\text{sorted}} \iff \text{ByteLexicographicalCompare}(A, B) \le 0
```

2. **Requisito Normativo di Assegnazione Versione Composita (`REQ-POLICY-SEMVER-DERIVATION`) (Layer B2):**
   La versione formale $\text{CompositePolicyVersion} \in V$ segue la convenzione di dominio definita per segnalare incompatibilità tra bundle eterogenei:
```math
\text{CompositePolicyVersion} := \begin{cases}
v_2 & \text{se } v_1 \preceq_{\text{compat}} v_2 \\
v_1 & \text{se } v_2 \preceq_{\text{compat}} v_1 \\
\langle \max(M_1, M_2) + 1, \ 0, \ 0 \rangle & \text{se } v_1 \text{ e } v_2 \text{ sono incompatibili } (M_1 \neq M_2)
\end{cases}
```

3. **Valutazione Composita Disgiunta (`DENY-OVERRIDES`):**
   La funzione di valutazione esecutiva composita $\mathcal{R}_{\text{exec, comp}}(S, t)$ è governata dalla regola disgiunta conservativa:
```math
\mathcal{R}_{\text{exec, comp}}(S, t) = \begin{cases}
\text{DENY} & \text{se } \mathcal{R}_{\text{exec}, 1}(S, t) = \text{DENY} \lor \mathcal{R}_{\text{exec}, 2}(S, t) = \text{DENY} \\
\text{RECALIBRATE} & \text{se } (\mathcal{R}_{\text{exec}, 1}(S, t) = \text{RECALIBRATE} \lor \mathcal{R}_{\text{exec}, 2}(S, t) = \text{RECALIBRATE}) \\
& \quad \land \mathcal{R}_{\text{exec}, 1}(S, t) \neq \text{DENY} \land \mathcal{R}_{\text{exec}, 2}(S, t) \neq \text{DENY} \\
\text{ALLOW} & \text{se } \mathcal{R}_{\text{exec}, 1}(S, t) = \text{ALLOW} \land \mathcal{R}_{\text{exec}, 2}(S, t) = \text{ALLOW}
\end{cases}
```

---

### 4.4 Decodifica Deterministica Input SML v2.0 in Evento Umano (Layer A & B2)

Per eliminare l'ambiguità tra i suggerimenti linguistici generati dal Livello 5 (LLM) e gli eventi accettati dal runtime (Livello 3/1), il Livello 4 applica la funzione pura di decodifica deterministica $\text{MapSMLToFSMEvent}$.

La funzione mappa tutti gli esiti conversazionali SML v2.0 definiti nella sintassi sintattica (§C.1) agli eventi esecutivi dell'automa umano $\Sigma_H \cup \{ \text{NONE} \}$:

```math
\text{MapSMLToFSMEvent} : \text{SMLDocumentParsed} \longrightarrow \Sigma_H \cup \{ \text{NONE} \}
```

```math
\text{MapSMLToFSMEvent}(d) := \begin{cases}
\text{HEV\_EMOTIONAL\_OVERWHELM} & \text{se } d.\text{conversation\_outcome} = \text{OVERWHELMED} \\
\text{HEV\_RECALIBRATION\_REQ} & \text{se } d.\text{conversation\_outcome} = \text{NEEDS\_REPHRASING} \\
\text{HEV\_PAUSE\_REQUESTED} & \text{se } d.\text{conversation\_outcome} = \text{DECLINED\_ACTION} \\
\text{HEV\_PREVENTIVE\_SUPPORT\_REQ} & \text{se } d.\text{conversation\_outcome} = \text{ASKED\_FOR\_HELP} \\
\text{HEV\_DOCS\_OBTAINED} & \text{se } d.\text{proposed\_transition} \neq \text{"NONE"} \land d.\text{evidence\_type} = \text{DOCUMENT} \\
\text{HEV\_STABILIZED} & \text{se } d.\text{proposed\_transition} \neq \text{"NONE"} \land d.\text{conversation\_outcome} = \text{MOTIVATED} \\
\text{NONE} & \text{in qualsiasi altro caso (compreso } d.\text{conversation\_outcome} = \text{UNDERSTOOD})
\end{cases}
```

---

### 4.5 Tassonomia della Guida ed Ergonomia Cognitiva (Layer B2)

Al fine di ridurre lo stress ed il carico cognitivo dell'utente vulnerabile senza usurparne la sovranità decisionale, il sistema definisce tre livelli formali di guida comunicativa:

1. **Direttiva Autoritativa (Authoritative Directive):** Formulazione prescrittiva ammessa **esclusivamente** in condizioni di imminente rischio per la sicurezza o situazioni di emergenza acuta (`PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Raccomandazione Motivata e Contestualizzata (Motivated Recommendation):** Formulazione consigliata che propone un percorso operativo riducendo il carico cognitivo. La raccomandazione `MUST` esplicitare la motivazione, il grado di certezza ed essere immediatamente revocabile o modificabile dall'utente (`USER_CONFIRMED_STEP`).
3. **Opzione Esplorativa (Exploratory Option):** Presentazione neutrale di alternative multiple, indicata quando l'utente si trova in uno stato di stabilità emotiva e desidera confrontare autonomamente le possibilità.

---

### 4.6 Filosofia Normativa dell'Intervento Umano (Human Override) (Layer B2)

L'intervento di un operatore umano (`OPERATOR`) costituisce un meccanismo di garanzia e supporto e `MUST` conformarsi ai seguenti principi normativi inderogabili:

1. **Principio di Tracciabilità:** Ogni azione di override `MUST` generare una transizione registrata nel Ledger $\mathcal{L}$ contenente l'ID dell'operatore.
2. **Principio di Autenticazione Forte:** L'override richiede una firma crittografica valida ed il possesso del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. **Principio di Spiegabilità Obbligatoria:** Ogni intervento di override `MUST` includere una motivazione esplicita in formato testuale non vuoto.
4. **Principio di Inalterabilità Storica:** L'override modifica unicamente lo stato proiettato corrente $S_N$, ma `SHALL NOT` cancellare o alterare le transizioni precedenti del Ledger.
5. **Principio di Rispettabilità del Consenso:** L'operatore umano `SHALL NOT` forzare l'esecuzione di azioni in violazione del consenso espresso dall'utente, salvo nei casi previsti dal livello HOBM `PROFESSIONAL_INTERVENTION_REQUIRED`.

---

# CAPITOLO 5: EMANCIPATION PLAYBOOK ENGINE
## (Layer A & Layer B2)

---

### 5.1 Struttura del Grafo del Playbook (Layer A)

Un **Emancipation Playbook** è formalizzato come un grafo orientato ed etichettato:

```math
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

```math
\mathbf{INV-PLAYBOOK-GRAPH-01} := \text{IsAcyclic}(G_P \vert_{\text{REQUIRED\_FOR\_SYSTEM\_STATE}}) = \text{TRUE}
```
La rilevazione di cicli sui nodi bloccanti determina il rifiuto immediato del caricamento del Playbook ed il sollevamento del **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.

#### 5.3.2 Durata Parametrizzata dei Micro-Passi (Layer B2)
La durata stimata di una micro-azione non può superare il valore definito dal parametro di policy:
```math
\theta_{\text{max\_duration}} \in \Theta
```

#### 5.3.3 Tracciamento dello Stato di Avanzamento (Layer A)
Ogni avanzamento nel grafo $G_P$ `MUST` aggiornare la componente $\mathcal{K}_{\text{playbook}}$ nello stato $\mathcal{S}$, dove:
```math
\mathcal{K}_{\text{playbook}} := \langle \text{pb}_{\text{id}}, \text{node}_{\text{curr}}, V_{\text{completed}} \rangle \in (\mathcal{I} \cup \{\text{null}\}) \times (\mathcal{I} \cup \{\text{null}\}) \times \mathcal{P}(\mathcal{I})
```

---

# CAPITOLO 6: TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ
## (Layer A & Layer B2)

---

### 6.1 Spazio delle Versioni e Tupla dei Profili di Runtime (Layer A)

Ogni componente versionabile di SCINTILLA CORE appartiene allo spazio vettoriale discreto delle versioni $V := \mathbb{N} \times \mathbb{N} \times \mathbb{N}$ rappresentato dalla tupla $v = \langle \text{major}, \text{minor}, \text{patch} \rangle$.

Il contesto esecutivo completo di una transazione o di un registro è vincolato dalla **Tupla dei Profili di Runtime (Runtime Profile Tuple)**:

```math
\mathbf{RuntimeProfile} := \left\langle \text{semantic\_profile}, \text{schema\_profile}, \text{canonicalization\_profile}, \text{policy\_profile} \right\rangle
```

#### 6.1.1 Regola di Compatibilità Temporale per il Replay Storico (`RULE-HISTORICAL-REPLAY-COMPATIBILITY`) (Layer B2)
```math
\mathbf{RULE-HISTORICAL-REPLAY-COMPATIBILITY}
```
In fase di ricostruzione deterministica dello stato $P(L)$ a partire dal Ledger:
1. Ogni transazione $t_i \in L$ `MUST` essere interpretata e validata applicando le regole di semantica operazionale SOS e gli schemi di validazione corrispondenti al profilo `t_i.runtime_profile` registrato nella transazione stessa (o nel Manifest di segmento del Ledger).
2. L'introduzione di una nuova versione dello standard `SHALL NOT` alterare retroattivamente il risultato delle transizioni storiche già consolidate sotto una versione precedente.

---

### 6.2 Relazione di Compatibilità Retroattiva (Layer A)

Siano $v_1 = \langle M_1, m_1, p_1 \rangle$ e $v_2 = \langle M_2, m_2, p_2 \rangle$ due versioni nello spazio $V$. 

La relazione di compatibilità retroattiva $v_1 \preceq_{\text{compat}} v_2$ è definita formalmente come l'ordine parziale:

```math
v_1 \preceq_{\text{compat}} v_2 \iff (M_1 = M_2) \land \left( (m_1 < m_2) \lor (m_1 = m_2 \land p_1 \le p_2) \right)
```

---

# CAPITOLO 7: CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA
## (Layer A & Layer B2)

---

### 7.1 Spazio Normalizzato e Canonizzazione (Layer A)

Sia $\mathcal{S}_{\text{normalized}} \subseteq \mathcal{S}$ il sottoinsieme di stati conformi alle regole di normalizzazione del profilo di riferimento SC-JCS-1 (§10.2). 

La funzione di canonizzazione deterministica $\text{Canon} : \mathcal{S}_{\text{normalized}} \longrightarrow \mathcal{B}^*$ converte lo stato strutturato nella sua rappresentazione binaria unica. L'iniettività semantica di $\text{Canon}$ costituisce una proprietà obiettivo garantita dall'applicazione dell'algoritmo deterministico SC-JCS-1 (§10.3), assicurando che due stati semanticamente identici producano il medesimo flusso di byte UTF-8.

---

### 7.2 Catena di Hash Immutabile ed Integrità delle Transazioni (Layer A)

La continuità e l'integrità del Ledger $\mathcal{L}$ per la transazione $N$-esima è determinata dal calcolo del checksum $H_N \in \mathcal{D}_{256}$ eseguito sul corpo della transazione $\text{TransactionBody}_N$:

```math
H_0 = \mathbf{0}_{\mathcal{D}_{256}} \quad (\text{Digest nullo di Genesi a 256 bit})
```
```math
H_N = H\left( \text{Canon}(\text{TransactionBody}_N) \right)
```

Dove 
```math
H: \mathcal{B}^* \to \mathcal{D}_{256}
```
è la funzione di hash astratta (SHA-256) e 
```math
\text{TransactionBody}_N$ contiene $H_{N-1}
```
come valore vincolato del campo `prev_hash`.

---

# CAPITOLO 8: FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEI RUNTIME ERROR CODES
## (Layer B2 - Specificazione Normativa)

---

### 8.1 Criteri Normativi di Accettazione PASS/FAIL

Un'implementazione esecutiva ottiene la certificazione di conformità se e solo se soddisfa i seguenti tre criteri normativi vincolanti:

1. **Test Vector Match:** $100\%$ di corrispondenza bit-identica sugli hash generati dalla suite di test normativi (`CONFORMANCE-TEST-SUITE-v4.5.1.JSON`).
2. **Requisito di Verifica Temporale LTL/CTL:** Formalizzazione delle proprietà logiche temporali (§9.2) con superamento degli obblighi di proof/model checking.
3. **Totalità Matematica della Transizione:** Gestione corretta ed esaustiva di tutte le transizioni ammissibili per gli automi $M$ ed $\mathcal{H}$ tramite la funzione $\mathbf{Resolve}$.

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
* **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`):** Errore di formattazione JSON, presenza di notazione scientifica, o fallimento del predicato di unicità statica dell'automa $\mathbf{ValidFSMContract}$.
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
```math
\mathbf{REQ-CLUSTER-CLOCK-SYNC} := \max_{i,j} |t_{\text{wall}, i} - t_{\text{wall}, j}| \le \delta_{\text{clock}} \quad \text{con } \delta_{\text{clock}} < \frac{1}{2} \Delta t_{\text{max}}
```
4. **Delimitazione dell'Ambito di Infrastruttura Ex-Textu:** La presente specifica disciplina rigorosamente la consistenza logica (*Strict Linearizability*) ed i token di scherma monotonicamente crescenti per ogni `case_id`. Le strategie di deduplicazione di rete e di ripristino post-crash sono delegate ai profili infrastrutturali.

---

### 9.2 Modello di Transizione di Kripke e Logica Temporale (Layer A)

#### 9.2.1 Formalizzazione della Struttura di Kripke
La semantica temporale di SCINTILLA CORE è descritta dalla Struttura di Kripke:

```math
M_K := \langle \mathcal{S}, s_0, \to_{\text{Sys}}, AP, L, F \rangle
```

* $\mathcal{S}$: Spazio degli Stati algebrico primario (§1.1.1).
* $s_0 \in \mathcal{S}$: Stato di Genesi (§1.3).
* $\to_{\text{Sys}} \subseteq \mathcal{S} \times \mathcal{S}$: Relazione di transizione generata dalla semantica operazionale SOS (§3).
* $AP$: Insieme finito dei simboli di Proposizione Atomica Booleana.
* $L: \mathcal{S} \to \mathcal{P}(AP)$: La Funzione di Etichettatura (Labeling Function).
* $F \subseteq \mathcal{P}(\mathcal{S})$: Insieme dei vincoli di Fairness definita sulle tracce ammissibili.

#### 9.2.2 Mappatura della Labeling Function tramite Proiezioni
La mappa $L(S)$ determina l'appartenenza dei simboli in $AP$ mediante le proiezioni dello stato $S$:

1. **`SafetyGateAllowed`:**
```math
\text{SafetyGateAllowed} \in L(S) \iff \mathcal{R}_{\text{exec}}(S, t_{\text{prop}}) = \text{ALLOW}
```

2. **`DecisionOutcomeAllowed`:** $\text{DecisionOutcomeAllowed} \in L(S) \iff \pi_{\mathcal{O}}(S) = \text{ALLOW}$.
3. **`HashChainValid`:** 
```math
\text{HashChainValid} \in L(S) \iff H(\text{Canon}(\pi_{\text{last\_tx}}(S))) = \pi_{\text{last\_hash}}(S)
```

4. **`MonotonicFence`:** 
```math
\text{MonotonicFence} \in L(S) \iff \pi_{\text{lease}}(S).\text{fencing}_{\text{token}_N} > \pi_{\text{lease}}(S).\text{fencing}_{\text{token}_{N-1}}
```

5. **`StateIsRecoverableFailure`:** 
```math
\text{StateIsRecoverableFailure} \in L(S) \iff \pi_Q(S) = \text{RECOVERABLE\_FAILURE}
```

6. **`StateIsSecurityLockdown`:** 
```math
\text{StateIsSecurityLockdown} \in L(S) \iff \pi_Q(S) = \text{SECURITY\_LOCKDOWN}
```

7. **`StateIsValidationError`:** 
```math
\text{StateIsValidationError} \in L(S) \iff \pi_Q(S) = \text{VALIDATION\_ERROR}
```

8. **`StateIsNormal`:** $\text{StateIsNormal} \in L(S) \iff \pi_Q(S) = \text{NORMAL}$.
9. **`StateIsReadOnly`:** 
```math
\text{StateIsReadOnly} \in L(S) \iff \pi_Q(S) = \text{SAFE\_READ\_ONLY\_MODE}
```

10. **`JourneyProgressive`:** $\text{JourneyProgressive} \in L(S) \iff \pi_Q(S) \in F_{\text{oper}} \land \pi_{Q_H}(S) \in \{h_1, h_2, h_3, h_4, h_5, h_6, h_{11}\}$.
11. **`KeyIsShredded`:** $\text{KeyIsShredded}_c \in L(S) \iff \text{LookupKey}(c, KMS) = \bot$.
12. **`UserEngaged`:** $\text{UserEngaged} \in L(S) \iff \pi_{Q_H}(S) \notin \{h_7, h_{10}\}$.
13. **`NonTerminalHumanState`:** $\text{NonTerminalHumanState} \in L(S) \iff \pi_{Q_H}(S) \notin F_H$.
14. **`HumanState`:** 
```math
\text{HumanState}_{h_i} \in L(S) \iff \pi_{Q_H}(S) = h_i
```

#### 9.2.3 Formule Temporali First-Order LTL (FO-LTL)
La dinamica di sicurezza del modello è specificata dalle seguenti formule First-Order LTL:

* **FO-LTL Safety 1 (Safety Gate / Policy Guidance Corrected):**
```math
\square \left( \text{DecisionOutcomeAllowed} \implies \text{SafetyGateAllowed} \right)
```
* **FO-LTL Safety 2 (Fencing & Lease Recovery):**
```math
\square \left( \neg \text{MonotonicFence} \implies X(\text{StateIsRecoverableFailure}) \right)
```
* **FO-LTL Safety 3 (Hash Chain Integrity):**
```math
\square \left( \neg \text{HashChainValid} \implies X(\text{StateIsSecurityLockdown}) \right)
```
* **FO-LTL Liveness 4 (Recuperabilità del Progresso dopo Errore Tecnico):**
```math
\square \left( (\text{StateIsValidationError} \lor \text{StateIsRecoverableFailure}) \implies \diamondsuit \text{JourneyProgressive} \right)
```
* **FO-LTL Safety 5 (Invarianza dell'Oblio Crittografico):**
```math
\forall c \in \mathcal{I}_{\text{case}}, \quad \square \left( \text{event} = \text{EV\_CRYPTO\_SHRED\_EXECUTED}(c) \implies \square \text{KeyIsShredded}_c \right)
```

#### 9.2.4 Riduzione e Mapping verso LTL Proposizionale per Model Checkers
Per l'esecuzione diretta su strumenti di Model Checking Simbolico (NuSMV, SPIN, TLC), la quantificazione del primo ordine viene ridotta allo spazio discreto delle proposizioni atomiche mediante istanziazione finita sui domini $\mathcal{I}_{\text{case}}$:

```math
\text{Lowering}_{\text{LTL}}(\forall c \in \mathcal{I}_{\text{case}}, \phi(c)) := \bigwedge_{i=1}^{|\mathcal{I}_{\text{case}}|} \phi(c_i)
```

#### 9.2.5 Proprietà CTL (Computation Tree Logic)

* **CTL System Agency Guarantee (Accessibilità del Progresso di Sistema):**
```math
AG \left( \text{UserEngaged} \implies EF (\text{JourneyProgressive}) \right)
```
* **CTL Trap-Free Safety (Recuperabilità dal Lockdown):**
```math
AG \left( \text{StateIsSecurityLockdown} \implies EF (\text{StateIsNormal} \lor \text{StateIsReadOnly}) \right)
```
* **CTL Non-Terminal Successor Guarantee (Presenza di Transizioni Abilitate):**
```math
AG \left( \text{NonTerminalHumanState} \implies EX(\text{True}) \right)
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
se e solo se tutti i numeri presenti sono interi compresi nell'intervallo chiuso:

```math
I_{\text{safe}} = \left[ -(2^{53} - 1), \ +(2^{53} - 1) \right] = \left[ -9007199254740991, \ +9007199254740991 \right]
```

Qualsiasi notazione contenente virgola mobile, notazione scientifica (`1e10`), `NaN` o `Infinity` `MUST` essere rifiutata con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 10.2.1 Regola sui Valori Probabilistici ed Indici in Basis Points [0, 10000]
Tutti i campi numerici rappresentanti probabilità, punteggi di confidenza o indici AGI $[0.0, 1.0]$ **`MUST` essere convertiti e serializzati in JSON come numeri interi a punto fisso scalati di un fattore $10^4$ (Basis Points, intervallo chiuso intero $[0, 10000]$)**.

---

### 10.3 Algoritmo di Serializzazione Canonica SC-JCS-1

1. **Whitespace Elimination:** Rimuovere tutti i caratteri di spaziatura esterni alle stringhe.
2. **String Escaping:** Applicare l'escaping unicamente per U+0000..U+001F, `"`, e `\`.
3. **Unicode Normalization:** Applicare la normalizzazione Unicode Normalization Form C (NFC).
4. **Object Key Sorting (`Order_SC`):** Ordinare le chiavi degli oggetti in modo ascendente sulla base del confronto lexicografico dei valori scalari Unicode:
```math
\text{Order}_{\text{SC}} := \text{UnicodeCodePointLex}
```
5. **Set Semantics Deep Bottom-Up Array Sorting:** Per tutte le chiavi registrate nel `SetSemanticsRegistry` (`completed_nodes`, `permissions`, `prerequisites`, `roles`, `scopes`), gli elementi dell'array `MUST` essere serializzati autonomamente in byte SC-JCS-1 ed ordinati in modo ascendente sulla base del confronto lexicografico byte-per-byte UTF-8 delle loro rappresentazioni canoniche.
6. **Invarianza Posizionale per Array Generici (Non-Set):** La sequenza logica degli elementi appartenenti ad un array non registrato nel `SetSemanticsRegistry` costituisce parte integrante della rappresentazione canonica dello stato. **È tassativamente vietata qualsiasi trasformazione semantica o strutturale che perda o modifichi l'informazione posizionale.** Il runtime è libero di adottare internamente qualsiasi struttura dati o rappresentazione in memoria, a condizione che la fase di serializzazione canonica ricostruisca senza alterazioni l'esatta sequenza logica originale.

---

### 10.4 Machine-Readable delta_M JSON Definition Contract

Il seguente contratto JSON definisce la funzione di transizione deterministica $\delta_M$ per l'automa DP-FSM. Il valore token `"event": "*"` costituisce la convenzione di fallback normativamente riservata al parser del runtime per rappresentare la regola jolly $\delta_{\text{wildcard}}(\sigma)$ soggetta alla regola di mascheramento `RULE-EXPLICIT-SHADOWS-WILDCARD`.

```json
{
  "automaton_id": "SCINTILLA_RUNTIME_SAFETY_AUTOMATON",
  "specification_version": "4.5.1-CANDIDATE",
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

    {"from": "SECURITY_LOCKDOWN", "event": "EV_OVERRIDE", "to": "NORMAL"},
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

Il seguente contratto JSON definisce la funzione di transizione deterministica dell'automa DP-FSM del percorso umano $\delta_H$. Le transizioni recanti `"from": "*"` `SHALL NOT` essere applicate agli stati presenti nel vettore `terminal_states`.

```json
{
  "automaton_id": "SCINTILLA_HUMAN_JOURNEY_AUTOMATON",
  "specification_version": "4.5.1-CANDIDATE",
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
    {"from": "HUMAN_RECALIBRATION_REQUIRED", "event": "HEV_STABILIZED", "to": "STABILIZATION"}
  ]
}
```

---

# CAPITOLO 11: CONFORMANCE PROFILE E TEST VECTOR AXIOMS
## (Layer B / Layer C)

---

### 11.1 Assiomatizzazione dei Test Vectors e Conformance Suite

I Test Vector concreti per la certificazione di conformità dello Standard Reference Profile 1 sono formalmente definiti nell'artefatto normativo esterno: **`CONFORMANCE-TEST-SUITE-v4.5.1.JSON`**.

La suite di test comprende tre categorie di vettori:
1. **Positive Path Vectors:** Oggetti JSON di input e relative stringhe di byte canonizzate SC-JCS-1 con digest SHA-256 attesi.
2. **Negative Error Vectors:** Documenti contenenti float, cicli su nodi bloccanti o contratti FSM ambigui con verifica dei Runtime Error Codes sollevati ($70-89$).
3. **Security Vectors:** Transazioni recanti firme Ed25519 corrotte o tentativi di violazione della catena di hash $H_N$.

---

# CAPITOLO 12: STATO DI CERTIFICAZIONE E LIVELLI DI VERIFICA
## (Layer B - Specificazione Normativa)

---

### 12.1 Stato Normativo del Documento

La presente **SCINTILLA CORE CANONICAL SPECIFICATION v4.5.1 Candidate Canonical Standard Edition** definisce la specifica normativa canonica e completa del dominio SCINTILLA CORE.

Lo stato corrente del documento è:

**SPECIFICATION-AUDITED & FORMALIZATION-READY — Candidate Canonical Standard Edition (v4.5.1)**

La struttura formale è definita, esente da contraddizioni interne e pronta per la fase di formalizzazione via prover e sviluppo dell'implementazione di riferimento.

---

### 12.2 Architettura a Livelli di Formalizzazione e Metadati di Governance

Ogni runtime conforme `MUST` esportare nei propri metadati di governance la struttura di attestazione per la verifica di conformità:

```json
{
  "governance_conformance": {
    "conformance_suite_id": "SC-SUITE-v4.5.1-DIGEST-a8f3b29c",
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

## ANNEX A: TYPESCRIPT TYPE MAPPING (INFORMATIVO / LAYER C)

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

export type BasisPoints = number; // Strict Safe Signed Integer Range [0, 10000]

export interface ExecutionEnvelope {
  execution_status: "PROCESSED_NOMINAL" | "PROCESSED_NO_STATE_EFFECT" | "REJECTED_VALIDATION_ERROR";
  reason_code: string;
  state_mutations_applied: boolean;
}

export interface RuntimeProfile {
  semantic_profile: string; // es. "SCINTILLA-SOS-v4.5.1"
  schema_profile: string;   // es. "SCHEMA-SC-v10.3"
  canonicalization_profile: string; // es. "SC-JCS-1"
  policy_profile: string;   // es. "POLICY-BUNDLE-v1.2"
}

export interface DataProvenanceRecord {
  provenance_id: string;            
  source_category: "USER_DECLARATION" | "LLM_INFERENCE" | "SYSTEM_VERIFIED" | "OPERATOR_CONFIRMED" | "EXTERNAL_SOURCE";
  asserted_by_actor_id: string;     
  timestamp_utc: string;            
  confidence_score_bp: BasisPoints; // Basis Points [0, 10000]
  verifiability_status: "UNVERIFIED" | "PENDING" | "VERIFIED" | "REJECTED";
  assertion_domain: ProvenanceDomain;
}

export interface AgencyGainIndexRecord {
  clarity_score_bp: BasisPoints;            
  action_execution_ratio_bp: BasisPoints;   
  dependency_reduction_score_bp: BasisPoints; 
  computed_agi_bp: BasisPoints;             
}

export interface SMLDocumentParsed {
  sml_version: "2.0";
  listen_summary: string;
  listen_agency: string;
  conversation_outcome: 
    | "UNDERSTOOD" 
    | "NEEDS_REPHRASING" 
    | "OVERWHELMED" 
    | "MOTIVATED" 
    | "DECLINED_ACTION" 
    | "ASKED_FOR_HELP";
  map_overview: string;
  proposed_transition: string | "NONE";
  micro_action?: {
    id: string | "NONE";
    title: string;
    minutes: number;
  };
  evidence: string;
  evidence_type: 
    | "USER_DECLARATION" 
    | "DOCUMENT" 
    | "SYSTEM_EVENT" 
    | "OPERATOR_CONFIRMATION";
}
```

---

## ANNEX B: EMANCIPATION PLAYBOOK GRAPH SPECIFICATION (LAYER B / LAYER C)

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
  estimated_duration_minutes: number;
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

In fase di caricamento di un oggetto `EmancipationPlaybookGraph`, il Playbook Engine (Livello 2) `MUST` verificare che il sotto-insieme dei nodi con `action_type === 'REQUIRED_FOR_SYSTEM_STATE'` non contenga cicli orientati (`INV-PLAYBOOK-GRAPH-01`). Qualsiasi rilevazione di ciclo determina il rifiuto del caricamento con **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.

---

## ANNEX C: SPECIFICAZIONE SML v2.0 (LAYER B2 / LAYER C)

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

---

**SCINTILLA CORE v4.5.1 CANDIDATE CANONICAL STANDARD EDITION**
* **Coverage:** Chapters 0–12 & Annexes A–C Fully Emitted
* **Governance Authority:** Single Source of Truth for SCINTILLA CORE Domain
