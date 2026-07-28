# ✴ SCINTILLA CORE CANONICAL SPECIFICATION
## Standard Edition v2.0 Timeless (Canonical & Formally Defined)

**Core Deterministico e Umano-Centrico per la Gestione di Percorsi di Emancipazione Personale**

* **Stato:** Specifica Normativa Canonica Formale (Single Source of Truth)  
* **Edizione:** v2.0 Timeless Standard Edition (Canonical & Formally Consistent)  
* **Autorità Governance:** Single Source of Truth Normativa per il dominio SCINTILLA CORE. Versionata secondo l'Algebra delle Versioni (§6).  
* **Terminologia Normativa:** RFC 2119 / RFC 8174 (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`).

---

# PARTE I: SPECIFICA NORMATIVA ASTRATTA (CORE ABSTRACT SPECIFICATION)

---

## 1. ALGEBRA ASTRATTA DEL MODELLO DI DOMINIO SCINTILLA

### 1.1 Formalizzazione dello Spazio degli Stati $\mathcal{S}$ e dello Spazio delle Transazioni $T$
Il modello di dominio di Scintilla Core è definito sui seguenti spazi algebrici rigorosi:

#### 1.1.1 Spazio degli Stati $\mathcal{S}$
Lo Spazio degli Stati $\mathcal{S}$ è il prodotto cartesiano dei domini di stato fondamentali del sistema:

$$\mathcal{S} \subseteq \mathcal{I}_{\text{case}} \times Q \times Q_H \times \mathcal{P}_{\text{active}} \times \mathcal{M}_{\text{prov}} \times \mathcal{F}_{\text{lease}} \times \mathcal{Q}_{\text{consent}} \times \mathcal{O}_{\text{decision}} \times \mathcal{K}_{\text{playbook}}$$

Dove:
* $\mathcal{I}_{\text{case}} \subset \mathcal{I}$: Identificatore unico del caso utente.
* $Q$: Stato corrente della Runtime Safety State Machine (§2.2).
* $Q_H$: Stato corrente della Human Journey State Machine (§2.3).
* $\mathcal{P}_{\text{active}}$: Il bundle di policy attivo (§4.1).
* $\mathcal{M}_{\text{prov}}: \mathcal{K}_{\text{data}} \to D_P$: La mappa dello stato informativo arricchito con Data Provenance (§1.4).
* $\mathcal{F}_{\text{lease}} := \langle \text{fencing\_token}, \text{lease\_expiry} \rangle \in \mathbb{N} \times \mathcal{T}$: Lo stato del lock di concorrenza.
* $\mathcal{Q}_{\text{consent}}$: Lo stato corrente del registro delle manifestazioni di consenso dell'utente.
* $\mathcal{O}_{\text{decision}} \in \{ \text{ALLOW}, \text{DENY}, \text{RECALIBRATE}, \text{NONE} \}$: L'esito dell'ultima valutazione decisionale del Policy Guidance Engine.
* $\mathcal{K}_{\text{playbook}} := \langle \text{playbook\_id}, \text{current\_node\_id}, \text{completed\_nodes} \rangle \in (\mathcal{I} \cup \{\text{null}\}) \times (\mathcal{I} \cup \{\text{null}\}) \times \mathcal{P}(\mathcal{I})$: Lo stato dell'esecutore del Playbook (§5).

#### 1.1.2 Assioma del Genesis State $s_0$
Lo stato iniziale di genesi $s_0 = P(\epsilon) \in \mathcal{S}$ `MUST` contenere tassativamente i seguenti valori predefiniti:

$$s_0 := \left\langle \text{case\_id}=\text{null}, \ q=\text{NORMAL}, \ q_H=\text{UNASSESSED}, \ \mathcal{P}_{\text{active}}=\mathcal{P}_{\text{default}}, \ \mathcal{M}_{\text{prov}}=\emptyset, \ \mathcal{F}_{\text{lease}}=\langle 0, t_0 \rangle, \ \mathcal{Q}_{\text{consent}}=\emptyset, \ \mathcal{O}_{\text{decision}}=\text{NONE}, \ \mathcal{K}_{\text{playbook}}=\langle \text{null}, \text{null}, \emptyset \rangle \right\rangle$$

#### 1.1.3 Spazio delle Transazioni $T$ e Corpo della Transazione ($\text{TransactionBody}$)
Lo Spazio delle Transazioni $T$ è l'insieme di tutti i record di mutazione atomici ed immutabili commitabili nel sistema. Una transazione $t \in T$ è formalizzata come la tupla algebrica:

$$t := \langle \text{TransactionBody}, \text{proof} \rangle$$

Dove il corpo della transazione $\text{TransactionBody}$ racchiude tutti i metadati e il contesto informativo soggetti ad autenticazione ed hashing:

$$\text{TransactionBody} := \left\langle \text{tx\_id}, \text{case\_id}, \text{seq\_num}, \text{prev\_hash}, \text{timestamp}, \text{actor}, \text{event}, \text{payload}, \text{policy\_binding\_hash}, \text{schema\_version}, \text{specification\_id} \right\rangle$$

* $\text{tx\_id} \in \mathcal{I}$: Identificatore unico della transazione.
* $\text{case\_id} \in \mathcal{I}$: Identificatore del caso utente associato.
* $\text{seq\_num} \in \mathbb{N}^+$: Numero di sequenza monotonico della transazione.
* $\text{prev\_hash} \in \mathcal{D}$: Impronta crittografica della transazione precedente ($H_{N-1}$).
* $\text{timestamp} \in \mathcal{T}$: Istante temporale di generazione.
* $\text{actor} \in \mathcal{I}_{\text{actor}}$: Identificatore dell'attore mittente.
* $\text{event} \in \Sigma \cup \Sigma_H$: Evento di transizione dell'automa.
* $\text{payload} \in \mathcal{V}$: Contenuto informativo specifico della mutazione.
* $\text{policy\_binding\_hash} \in \mathcal{D}$: Impronta della policy attiva al momento dell'emissione.
* $\text{schema\_version} \in V$: Versione dello schema dati applicativo.
* $\text{specification\_id} \in \mathcal{I}$: Identificatore canonico della specifica dello standard.
* $\text{proof} \in \mathcal{S}_{\text{sig}}$: Firma digitale dell'attore calcolata su $\text{Canon}(\text{TransactionBody})$.

---

### 1.2 Il Ledger come Monoide Libero $\mathcal{L}$
Il registro immutabile delle decisioni (Ledger) è formalizzato come un Monoide Libero $\mathcal{L} := \langle T^*, \mathbin{\Vert}, \epsilon \rangle$:
* $T^*$: L'insieme di tutte le sequenze finite di transazioni $t \in T$.
* $\mathbin{\Vert}$: L'operazione binaria di concatenazione associativa di transazioni (Append-Only).
* $\epsilon$: La sequenza vuota (elemento neutro del monoide).

**Assioma di Immutabilità Algebrica del Ledger:**  
$$\forall L_1, L_2 \in \mathcal{L}, \quad (L_1 \mathbin{\Vert} L_2 = L_3 \land L_2 \neq \epsilon) \implies L_1 \text{ è un prefisso stretto ed inalterabile di } L_3$$

**Teorema di Estensione Monotonica:**  
$$\forall L \in \mathcal{L}, \forall t \in T, \quad |L \mathbin{\Vert} \langle t \rangle| = |L| + 1 \quad \land \quad L \prec (L \mathbin{\Vert} \langle t \rangle)$$

---

### 1.3 La Funzione di Proiezione dello Stato $P: \mathcal{L} \to \mathcal{S} \cup \{\bot\}$
La relazione tra la storia immutabile delle transazioni $L \in \mathcal{L}$ e lo stato proiettato corrente $s \in \mathcal{S}$ è governata dalla funzione pura $P$:

$$P(\epsilon) = s_0 \quad (\text{Stato Iniziale di Genesi})$$
$$P(L \mathbin{\Vert} \langle t \rangle) = \text{Apply}(P(L), t)$$

Dove $\text{Apply}: (\mathcal{S} \cup \{\bot\}) \times T \to \mathcal{S} \cup \{\bot\}$ è la funzione pura di transizione di stato. Se la transizione $t$ è invalida rispetto allo stato $s$, la funzione restituisce l'elemento di errore bottom ($\bot$).

**Assioma di Assorbimento del Bottom (Bottom Absorption Axiom):**  
$$\forall t \in T, \quad \text{Apply}(\bot, t) = \bot$$

La generazione dell'elemento $\bot$ forza immediatamente il runtime nello stato di sicurezza $q = \text{SECURITY\_LOCKDOWN}$.

#### 1.3.1 Teorema del Replay Deterministico (Deterministic Replay Theorem)
$$\forall L_1, L_2 \in \mathcal{L}, \quad L_1 = L_2 \implies P(L_1) = P(L_2)$$

---

### 1.4 Tassonomia Astratta dei Dati e Algebra della Provenienza ($\text{DataProvenance}$)
Ogni elemento informativo $v \in \mathcal{V}$ contenuto nello stato $s \in \mathcal{S}$ `MUST` essere incapsulato nella tupla di provenienza del dato $D_P$:

$$D_P := \langle v, \kappa, \alpha, t, \phi, \psi \rangle$$

* $v \in \mathcal{V}$: Il valore informativo.
* $\kappa \in \mathcal{K}_{\text{prov}}$: Categoria di provenienza ($\mathcal{K}_{\text{prov}} \supset \{ \text{USER\_DECLARATION}, \text{LLM\_INFERENCE}, \text{SYSTEM\_VERIFIED}, \text{OPERATOR\_CONFIRMED}, \text{EXTERNAL\_SOURCE} \}$).
* $\alpha \in \mathcal{I}_{\text{actor}}$: Identificatore dell'attore asseritore.
* $t \in \mathcal{T}$: Istante temporale di asserzione.
* $\phi \in [0.0, 1.0]$: Punteggio numerico di confidenza.
* $\psi \in \{ \text{UNVERIFIED}, \text{PENDING}, \text{VERIFIED}, \text{REJECTED} \}$: Stato di verifica oggettiva.

#### 1.4.1 Ordine Parziale di Fiducia e Assioma di Degradazione della Provenienza
È definito sull'insieme $\mathcal{K}_{\text{prov}}$ un ordine parziale stretto di autorità informativa:

$$\text{LLM\_INFERENCE} \prec \text{USER\_DECLARATION} \prec \text{EXTERNAL\_SOURCE} \prec \text{OPERATOR\_CONFIRMED} \prec \text{SYSTEM\_VERIFIED}$$

**Regola di Fallback per Categorie Estese:** qualsiasi categoria appartenente a `EXTENSION_PROVENANCE` `MUST` essere mappata, ai fini del calcolo dell'ordine parziale $\prec$, al livello di autorità di `USER_DECLARATION`, salvo diversa riconfigurazione esplicita nel `PolicyBundle`.

**Assioma di Contaminazione e Degradazione della Provenienza:**  
Se un nuovo dato $D_{P,\text{derived}}$ è sintetizzato a partire da un insieme di dati di input $\{D_{P,1}, \dots, D_{P,n}\}$, la sua categoria di provenienza e la sua confidenza `MUST` rispettare le seguenti disuguaglianze algebriche:

$$\kappa(D_{P,\text{derived}}) \preceq \min_{i=1..n} \left( \kappa(D_{P,i}) \right)$$
$$\phi(D_{P,\text{derived}}) \le \min_{i=1..n} \left( \phi(D_{P,i}) \right)$$

---

### 1.5 Identificatori Astratti, Tempo e Crypto-Agilità
1. **Identificatore Unico Astratto ($\text{ID} \in \mathcal{I}$):** Elemento di un insieme opaco dotato di unicità globale e ordinamento totale.
2. **Istante Temporale Astratto ($t \in \mathcal{T}$):** Elemento di uno spazio affine continuo unidimensionale e totalmente ordinato $\mathcal{T}$.
3. **Crypto-Agilità Normativa:**
   * **Funzione di Hash Astratta:** $H: \mathcal{B}^* \to \mathcal{D}$ mappa sequenze di byte arbitrari in digest di lunghezza fissa nel dominio $\mathcal{D}$.
   * **Schema di Firma Astratto:** Tupla $\text{Sig} = \langle \text{GenKey}, \text{Sign}, \text{Verify} \rangle$.

---

## 2. ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI FORMALE

### 2.1 Modello di Isolamento Stratificato a 6 Livelli
L'infrastruttura di Scintilla Core è organizzata in 6 livelli logici sovrapposti. L'interfaccia tra i livelli è regolata da contratti rigidi: **nessun livello superiore `SHALL` modificare la semantica o lo stato dei livelli inferiori**:

```text
[ LEVEL 5 ] Large Language Model (Probabilistic Hypothesis Generator)
     │ API Contract: Output SML v2.0 Syntactic Text Only
[ LEVEL 4 ] Communication, SML Parsing & Semantic Validation Layer
     │ API Contract: Structured Hypothesis & Data Provenance Object
[ LEVEL 3 ] Human Interaction & Consent Model (Consent Ledger & Recalibration Engine)
     │ API Contract: Validated Human Context & Consent State
[ LEVEL 2 ] Policy Guidance Engine (Safety Gate & Pure Deterministic Rules)
     │ API Contract: DecisionResult with DecisionProof
[ LEVEL 1 ] Deterministic Runtime (Fencing Lease, Monotonic Timestamp Validation, State Transition δ)
     │ API Contract: Canonical Serialized Payload & State Mutation
[ LEVEL 0 ] Immutable State Ledger (Append-Only decisions.ndjson Hash Chain)
```

---

### 2.2 Runtime Safety State Machine $M$ (Sicurezza e Integrità di Sistema)
L'operatività di sicurezza di runtime è modellata come un Automa a Stati Finiti Deterministico Totale $M$:

$$M := \langle Q, \Sigma, \delta_M, q_0, F_{\text{oper}} \rangle$$

1. **Insieme degli Stati Canonici $Q$ ($|Q|=7$):**
   $$Q = \{ \text{NORMAL } (q_0), \text{REQUIRE\_RECALIBRATION } (q_1), \text{VALIDATION\_ERROR } (q_2), \text{RECOVERABLE\_FAILURE } (q_3), \text{OPERATOR\_REQUIRED } (q_4), \text{SECURITY\_LOCKDOWN } (q_5), \text{SAFE\_READ\_ONLY\_MODE } (q_6) \}$$
2. **Stato Iniziale:** $q_0 = \text{NORMAL}$.
3. **Insieme degli Stati Operativamente Stabili $F_{\text{oper}}$:** $F_{\text{oper}} = \{ \text{NORMAL}, \text{SAFE\_READ\_ONLY\_MODE} \}$.
4. **Alfabeto degli Eventi di Sistema $\Sigma$ ($|\Sigma|=8$):**
   $$\Sigma = \{ \text{EV\_SUCCESS } (\sigma_0), \text{EV\_ABANDON } (\sigma_1), \text{EV\_SML\_FAIL } (\sigma_2), \text{EV\_LEASE\_EXP } (\sigma_3), \text{EV\_HASH\_CORRUPT } (\sigma_4), \text{EV\_TIMEOUT } (\sigma_5), \text{EV\_OVERRIDE } (\sigma_6), \text{EV\_REPAIR } (\sigma_7) \}$$

---

### 2.3 Human Journey State Machine $\mathcal{H}$ (Percorso di Emancipazione Personale)
L'evoluzione del percorso umano dell'utente è modellata da un automa di dominio autonomo $\mathcal{H}$:

$$\mathcal{H} := \langle Q_H, \Sigma_H, \delta_H, q_{H0}, F_H \rangle$$

1. **Insieme degli Stati del Percorso Umano $Q_H$ ($|Q_H|=7$):**
   $$Q_H = \{ \text{UNASSESSED } (h_0), \text{INITIAL\_ASSESSMENT } (h_1), \text{STABILIZATION } (h_2), \text{DOCUMENT\_RECOVERY } (h_3), \text{EMPLOYMENT\_READINESS } (h_4), \text{FINANCIAL\_AUTONOMY } (h_5), \text{SUSTAINED\_INDEPENDENCE } (h_6) \}$$
2. **Stato Iniziale:** $q_{H0} = \text{UNASSESSED}$.
3. **Insieme degli Stati Target $F_H$:** $F_H = \{ \text{SUSTAINED\_INDEPENDENCE} \}$.
4. **Alfabeto degli Eventi Umani $\Sigma_H$ ($|\Sigma_H|=8$):**
   $$\Sigma_H = \{ \text{HEV\_ASSESS\_START } (\sigma_{H0}), \text{HEV\_STABILIZED } (\sigma_{H1}), \text{HEV\_DOCS\_OBTAINED } (\sigma_{H2}), \text{HEV\_JOB\_READY } (\sigma_{H3}), \text{HEV\_FINANCE\_OK } (\sigma_{H4}), \text{HEV\_INDEPENDENCE\_ACHIEVED } (\sigma_{H5}), \text{HEV\_RELAPSE\_REGRESS } (\sigma_{H6}), \text{HEV\_RECALIBRATE } (\sigma_{H7}) \}$$

#### 2.3.1 Assioma di Chiusura e Totalità della Funzione $\delta_H$
La funzione di transizione $\delta_H: Q_H \times \Sigma_H \to Q_H$ è una **funzione totale**. Per qualsiasi coppia $(q_H, \sigma_H) \in Q_H \times \Sigma_H$ non mappata esplicitamente nella tabella delle transizioni di dominio, vale la regola di chiusura per stazionarietà (*Stuttering Step Axiom*):

$$\forall (q_H, \sigma_H) \notin \text{Domain}(\delta_{H,\text{explicit}}), \quad \delta_H(q_H, \sigma_H) = q_H$$

---

### 2.4 Equazione Matematica del Sistema Reattivo Composito $S_C = Q \times Q_H$
Il sistema reattivo globale di Scintilla Core è modellato dallo spazio di stato composito $S_C = Q \times Q_H$. La funzione di transizione strutturale pura dell'automa composito $\delta_C: (Q \times Q_H) \times (\Sigma \cup \Sigma_H) \to (Q \times Q_H)$ è definita in modo esaustivo dalla seguente equazione a casi:

$$\delta_C((q, q_H), \sigma_C) = \begin{cases} 
(\delta_M(q, \sigma_C), q_H) & \text{se } \sigma_C \in \Sigma \\
(q, \delta_H(q_H, \sigma_C)) & \text{se } \sigma_C \in \Sigma_H \land q \in F_{\text{oper}} \\
(q, q_H) & \text{se } \sigma_C \in \Sigma_H \land q \notin F_{\text{oper}} \quad (\text{Lockdown Freeze Axiom})
\end{cases}$$

1. **`INV-DECOUPLING-01` (Disaccoppiamento Unidirezionale):** L'automa del percorso umano $\mathcal{H}$ genera unicamente ipotetiche transizioni di guida per l'utente. L'automa $\mathcal{H}$ **`SHALL NOT` possedere alcuna autorità diretta di mutazione sullo stato del Runtime Safety State Machine $M$**.
2. **Isolamento da Lockdown:** Se lo stato del runtime $q \notin F_{\text{oper}}$, qualsiasi transizione nell'automa umano $\mathcal{H}$ eguaglia un no-op fino al ripristino di $q \in F_{\text{oper}}$.

---

## 3. SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)

La dinamica globale del sistema Scintilla Core è formalizzata mediante lo schema di Meta-Regole di **Small-Step Structural Operational Semantics (SOS)** definite sulla configurazione generica $\langle q, q_H, \sigma_C, S \rangle \to_{\text{Sys}} \langle q', q_H', S' \rangle$.

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore
Un evento $\sigma_C \in \Sigma \cup \Sigma_H$ contenuto in una transizione $t \in T$ emessa dall'attore $\alpha = \text{actor}(t)$ è valido se e solo se la coppia $(\sigma_C, \text{type}(\alpha))$ appartiene alla seguente matrice di autorizzazione:

$$\text{Authorized}(\sigma_C, \text{type}(\alpha)) \iff \begin{cases}
\text{True} & \text{se } \sigma_C \in \Sigma_H \land \text{type}(\alpha) \in \{\text{USER}, \text{OPERATOR}, \text{SYSTEM}\} \\
\text{True} & \text{se } \sigma_C \in \{\sigma_0, \sigma_1, \sigma_2, \sigma_3, \sigma_4, \sigma_5\} \land \text{type}(\alpha) = \text{SYSTEM} \\
\text{True} & \text{se } \sigma_C \in \{\text{EV\_OVERRIDE}, \text{EV\_REPAIR}\} \land \text{type}(\alpha) = \text{OPERATOR} \\
\text{False} & \text{in tutti gli altri casi (compreso qualsiasi tentativo con } \text{type}(\alpha) = \text{LLM})
\end{cases}$$

---

### 3.2 Mappatura Normativa delle Guardie ($\text{EvaluateGuards}$)
La funzione $\text{EvaluateGuards}: \mathcal{S} \times \Sigma \to \{ \text{PASS}, \text{FAIL} \}$ valuta le precondizioni di sicurezza per gli eventi di runtime:

$$\text{EvaluateGuards}(S, \sigma_C) = \begin{cases}
\text{PASS} & \text{se } \sigma_C = \text{EV\_SUCCESS} \land \text{IsHashChainValid}(S) \land \text{IsMonotonicFence}(S) \land \text{ValidLease}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_ABANDON} \land \text{IsHashChainValid}(S) \land \text{ValidLease}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_SML\_FAIL} \land \text{IsHashChainValid}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_LEASE\_EXP} \land (\neg \text{ValidLease}(S) \lor \neg \text{IsMonotonicFence}(S)) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_HASH\_CORRUPT} \land \neg \text{IsHashChainValid}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_TIMEOUT} \land \text{IsTimeoutExpired}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_OVERRIDE} \land \text{AuthenticatedOperator}(\alpha) \land \text{ValidProof}(p) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_REPAIR} \land \text{AuthenticatedOperator}(\alpha) \land \text{ValidRepairPatch}(p) \\
\text{FAIL} & \text{in qualsiasi altro caso}
\end{cases}$$

---

### 3.3 Meta-Regole SOS della Sicurezza di Runtime ($M$)

$$\frac{\sigma_C \in \Sigma \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q' = \delta_M(q, \sigma_C) \quad \text{EvaluateGuards}(S, \sigma_C) = \text{PASS}}{\langle q, q_H, \sigma_C, S \rangle \to_{\text{Sys}} \langle q', q_H, \text{Apply}(S, \sigma_C) \rangle} \quad [\text{SOS-META-SAFETY}]$$

$$\frac{\sigma_C \in \Sigma \quad (\neg \text{Authorized}(\sigma_C, \text{type}(\alpha)) \lor \text{EvaluateGuards}(S, \sigma_C) = \text{FAIL})}{\langle q, q_H, \sigma_C, S \rangle \to_{\text{Sys}} \langle \text{VALIDATION\_ERROR}, q_H, S \rangle} \quad [\text{SOS-META-SAFETY-FAIL}]$$

---

### 3.4 Meta-Regole SOS del Percorso Umano ($\mathcal{H}$)

$$\frac{\sigma_C \in \Sigma_H \quad q \in F_{\text{oper}} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q_H' = \delta_H(q_H, \sigma_C) \quad \mathcal{R}(S, \sigma_C, \Theta) = \text{ALLOW}}{\langle q, q_H, \sigma_C, S \rangle \to_{\text{Sys}} \langle q, q_H', \text{Apply}(S, \sigma_C) \rangle} \quad [\text{SOS-META-HUMAN}]$$

$$\frac{\sigma_C \in \Sigma_H \quad q \in F_{\text{oper}} \quad (\neg \text{Authorized}(\sigma_C, \text{type}(\alpha)) \lor \mathcal{R}(S, \sigma_C, \Theta) \in \{\text{DENY}, \text{RECALIBRATE}\})}{\langle q, q_H, \sigma_C, S \rangle \to_{\text{Sys}} \langle q, \delta_H(q_H, \text{HEV\_RECALIBRATE}), S \rangle} \quad [\text{SOS-META-HUMAN-DENY}]$$

---

### 3.5 Meta-Regola SOS di Congelamento da Lockdown (Lockdown Freeze)

$$\frac{\sigma_C \in \Sigma_H \quad q \notin F_{\text{oper}}}{\langle q, q_H, \sigma_C, S \rangle \to_{\text{Sys}} \langle q, q_H, S \rangle} \quad [\text{SOS-LOCKDOWN-FREEZE}]$$

---

## 4. POLICY GUIDANCE ENGINE & FORMALIZZAZIONE ALGEBRICA DELLE POLICY

### 4.1 Definizione Algebrica del Policy Bundle $\mathcal{P}$
Il **Policy Guidance Engine** (Livello 2) valuta la sicurezza ed ammissibilità di ogni proposta di decisione mediante il `PolicyBundle` $\mathcal{P}$, formalizzato come la tupla algebrica:

$$\mathcal{P} := \langle \text{PolicyID}, \text{Version}, \Theta, \mathcal{R}, \text{Sig}_\mathcal{P} \rangle$$

* $\text{PolicyID} \in \mathcal{I}$: Identificatore unico della policy.
* $\text{Version} \in V$: Versione della policy nell'Algebra delle Versioni (§6).
* $\Theta$: Lo spazio dei parametri di configurazione e soglie della policy (es. $\theta_{\text{duration}}, \theta_{\text{confidence}}$).
* $\mathcal{R}: \mathcal{S} \times T \times \Theta \to \{ \text{ALLOW}, \text{DENY}, \text{RECALIBRATE} \}$: Una funzione pura e deterministica di valutazione dei predicati di sicurezza.
* $\text{Sig}_\mathcal{P}$: La firma crittografica dell'autorità di policy emittente.

### 4.2 Composizione Algebrica Disgiunta di Policy Multiple (`DENY-OVERRIDES`)
In presenza di due o più bundle di policy attivi $\mathcal{P}_1, \mathcal{P}_2$, l'operatore di composizione algebrica $\oplus$ produce il bundle composito $\mathcal{P}_{\text{comp}} = \mathcal{P}_1 \oplus \mathcal{P}_2$ governato dalla regola semantica `DENY-OVERRIDES` espressa tramite le seguenti clausole disgiunte:

$$\mathcal{R}_{\text{comp}}(s, t, \Theta_1 \cup \Theta_2) = \begin{cases}
\text{DENY} & \text{se } \mathcal{R}_1(s, t, \Theta_1) = \text{DENY} \lor \mathcal{R}_2(s, t, \Theta_2) = \text{DENY} \\
\text{RECALIBRATE} & \text{se } (\mathcal{R}_1(s, t, \Theta_1) = \text{RECALIBRATE} \lor \mathcal{R}_2(s, t, \Theta_2) = \text{RECALIBRATE}) \\
& \quad \land \mathcal{R}_1(s, t, \Theta_1) \neq \text{DENY} \land \mathcal{R}_2(s, t, \Theta_2) \neq \text{DENY} \\
\text{ALLOW} & \text{se } \mathcal{R}_1(s, t, \Theta_1) = \text{ALLOW} \land \mathcal{R}_2(s, t, \Theta_2) = \text{ALLOW}
\end{cases}$$

---

### 4.3 Filosofia Normativa dell'Intervento Umano (Human Override)
L'intervento di un operatore umano (`OPERATOR`) costituisce un meccanismo di garanzia e supporto e `MUST` conformarsi ai seguenti 5 principi normativi inderogabili:

1. **Principio di Tracciabilità:** Ogni azione di override `MUST` generare una transizione registrata in modo immutabile nel ledger $\mathcal{L}$ contenente l'ID dell'operatore.
2. **Principio di Autenticazione Forte:** L'override richiede una firma crittografica valida ed il possesso del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. **Principio di Spiegabilità Obbligatoria:** Ogni intervento di override `MUST` includere una motivazione esplicita espressa in formato testuale non vuoto nel campo `explanation`.
4. **Principio di Inalterabilità Storica:** L'override modifica unicamente lo stato proiettato corrente $S_N$, ma `SHALL NOT` cancellare, sovrascrivere o alterare le transizioni precedenti del ledger.
5. **Principio di Rispettabilità del Consenso:** L'operatore umano `SHALL NOT` forzare il trattamento dei dati o l'esecuzione di azioni in violazione del consenso espresso dall'utente.

---

## 5. EMANCIPATION PLAYBOOK ENGINE

### 5.1 Struttura del Grafo del Playbook $G_P$
Un **Emancipation Playbook** è formalizzato come un grafo orientato $G_P = (V_P, E_P, C_P)$:
* $V_P$: Insieme dei Nodi di Micro-Azione ($v \in V_P$).
* $E_P \subseteq V_P \times V_P$: Archi diretti rappresentanti la sequenza logica di progressione.
* $C_P$: Insieme delle Condizioni e Prerequisiti di Verificabilità, dove ogni elemento $c \in C_P$ è tipizzato come un predicato di stato booleano puro $c: \mathcal{S} \to \{ \text{True}, \text{False} \}$.

### 5.2 Invarianti di Esecuzione e Tracking dello Stato Playbook ($\mathcal{K}_{\text{playbook}}$)
1. **`INV-PLAYBOOK-GRAPH-01` (Aclicienza Locale sui Passi Obbligatori):** Il sotto-grafo dei nodi contenenti azioni bloccanti `is_blocking = true` `MUST` essere un Grafo Diretto Aclicico (DAG). La rilevazione di cicli bloccanti causa l'immediato scarto del Playbook con **Exit Code 23 (`ERR_GRAPH_CYCLE_DETECTED`)**.
2. **`INV-PLAYBOOK-STEP-02` (Durata Parametrizzata):** La durata stimata di una micro-azione non può superare il valore definito dal parametro $\theta_{\text{max\_duration}} \in \Theta$ della policy attiva.
3. **`INV-PLAYBOOK-STATE-03` (Tracciamento dello Stato di Avanzamento):** Ogni avanzamento nel grafo $G_P$ `MUST` aggiornare la componente $\mathcal{K}_{\text{playbook}} = \langle \text{playbook\_id}, \text{current\_node\_id}, \text{completed\_nodes} \rangle$ nello stato $\mathcal{S}$, registrando la relativa Data Provenance ($D_P$).

---

## 6. TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ

### 6.1 Spazio delle Versioni $V$
Ogni componente versionabile di Scintilla Core appartiene allo spazio vettoriale discreto delle versioni $V := \mathbb{N} \times \mathbb{N} \times \mathbb{N}$, rappresentato dalla tupla $v = \langle \text{major}, \text{minor}, \text{patch} \rangle$.

### 6.2 Relazione di Compatibilità Retroattiva $\preceq_{\text{compat}}$
Siano $v_1 = \langle M_1, m_1, p_1 \rangle$ e $v_2 = \langle M_2, m_2, p_2 \rangle$ due versioni nello spazio $V$. La relazione di compatibilità retroattiva $v_1 \preceq_{\text{compat}} v_2$ è definita formalmente come:

$$v_1 \preceq_{\text{compat}} v_2 \iff (M_1 = M_2) \land \left( (m_1 < m_2) \lor (m_1 = m_2 \land p_1 \le p_2) \right)$$

**Regola di Propagazione dell'Aggiornamento Major:**  
$$\Delta M_{\text{schema}} > 0 \implies \Delta M_{\text{transaction}} > 0 \quad (\text{Richiede esecuzione di un MigrationManifest})$$

---

## 7. CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA

### 7.1 Injective Canonical Mapping $\text{Canon}: \mathcal{S} \to \mathcal{B}^*$
Per garantire l'indipendenza da formati di serializzazione specifici, il runtime definisce la funzione astratta di canonizzazione deterministica $\text{Canon}$:

$$\text{Canon}: \mathcal{S} \to \mathcal{B}^*$$

La funzione $\text{Canon}$ `MUST` essere **iniettiva**:

$$\forall s_1, s_2 \in \mathcal{S}, \quad \text{Canon}(s_1) = \text{Canon}(s_2) \iff s_1 = s_2$$

### 7.2 Costruzione della Catena di Hash Immutabile
La continuità e l'integrità del ledger $L \in \mathcal{L}$ per la transazione $N$-esima è determinata dal calcolo del checksum $H_N \in \mathcal{D}$ eseguito sul corpo della transazione $\text{TransactionBody}_N$ (§1.1.3) che include al suo interno il riferimento $H_{N-1}$ (`prev_hash`):

$$H_0 = \mathbf{0}_{\mathcal{D}} \quad (\text{Digest nullo di Genesi})$$
$$H_N = H\left( \text{Canon}(\text{TransactionBody}_N) \right)$$

Dove $H: \mathcal{B}^* \to \mathcal{D}$ è la funzione di hash astratta e $\text{TransactionBody}_N$ contiene $H_{N-1}$ come valore del campo `prev_hash`.

---

## 8. FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEGLI EXIT CODES

### 8.1 Criteri Normativi di Accettazione PASS/FAIL
Un'implementazione esecutiva ottiene la **Certificazione di Conformità Scintilla Core** se e solo se soddisfa i seguenti criteri:
1. **Test Vector Match:** $100\%$ di corrispondenza bit-identica sugli hash generati dal profilo di riferimento applicato.
2. **Requisito di Verifica LTL/CTL:** $100\%$ delle proprietà logiche temporali (§9.2) risultano soddisfatte nel modello formale.
3. **Totalità Matematica:** Gestione corretta ed esaustiva di tutte le coppie $(q, \sigma) \in Q \times \Sigma$ e $(q_H, \sigma_H) \in Q_H \times \Sigma_H$.

### 8.2 Tassonomia Normativa degli Exit Codes di Runtime
In caso di violazione degli invarianti di sicurezza o fallimento delle precondizioni, il runtime `MUST` terminare l'esecuzione restituendo unicamente uno dei seguenti Exit Code canonici:

* **Exit Code 13 (`ERR_INFRASTRUCTURE_IO`):** Fallimento dell'infrastruttura di I/O, acquisizione del lease di concorrenza o scadenza del lock.
* **Exit Code 17 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrità crittografica della catena di hash ($H_N$), manomissione del ledger o fallimento delle verifiche di sicurezza.
* **Exit Code 20 (`ERR_SML_PARSE_FAILED`):** Errore di validazione sintattica dell'input SML v2.0 rispetto alla grammatica EBNF (§C.1).
* **Exit Code 23 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo illegale sui nodi bloccanti all'interno di un Emancipation Playbook Graph ($G_P$).
* **Exit Code 24 (`ERR_SCHEMA_MISMATCH`):** Incompatibilità di versione dello schema dati non coperta da un `MigrationManifest` valido.
* **Exit Code 25 (`ERR_CONFIGURATION_MALFORMED`):** Errore di formattazione o presenza di numeri fuori dall'intervallo consentito (*Strict Signed Safe Integer Range*).

---

## 9. MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE

### 9.1 Modello di Sistema Distribuito, Consistenza e Concorrenza
1. **Modello di Consistenza del Ledger:** Il registro $L \in \mathcal{L}$ garantisce la **Strict Linearizability (Consistenza Esterna)** per singolo `case_id`.
2. **Protocollo di Lock e Fencing Token:** La gestione delle scritture concorrenti si avvale di un meccanismo di lease a tempo. Ogni mutazione `MUST` verificare e incrementare in modo strettamente monotonico il `fencing_token` $N \in \mathbb{N}^+$.
3. **Tolleranza al Disallineamento Temporale (Clock Skew):** L'intervallo di tolleranza massima tra l'orologio locale ed il tempo di riferimento $t \in \mathcal{T}$ è vincolato dal parametro $\Delta t_{\text{max}} \in \Theta$. Violazioni superiori a $\Delta t_{\text{max}}$ forzano la transizione a `RECOVERABLE_FAILURE`.

---

### 9.2 Logica Temporale Normativa (Formule LTL e CTL)

#### Predicati Atomici di Stato
Sia $s \in \mathcal{S}$ lo stato algebrico corrente. Sono definiti i seguenti predicati booleani puri:
* $\text{IsSafetyGateAllowed}(s) \iff \mathcal{R}(s, t, \Theta) = \text{ALLOW}$
* $\text{IsDecisionOutcomeAllowed}(s) \iff \pi_{\mathcal{O}}(s) \in \{ \text{ALLOW}, \text{NONE} \}$ (dove $\pi_{\mathcal{O}}$ è la proiezione della componente $\mathcal{O}_{\text{decision}}$ dello stato $s$).
* $\text{IsHashChainValid}(s) \iff H(\text{Canon}(\text{TransactionBody}_N)) = H_N$
* $\text{IsMonotonicFence}(s) \iff \text{fencing\_token}_N > \text{fencing\_token}_{N-1}$

#### Proprietà LTL (Linear Temporal Logic)
* **LTL Safety 1 (Safety Gate / Policy Guidance):**
  $$\square \left( \neg \text{IsSafetyGateAllowed}(s) \implies \neg \text{IsDecisionOutcomeAllowed}(s) \right)$$
* **LTL Safety 2 (Fencing & Lease Recovery):**
  $$\square \left( \neg \text{IsMonotonicFence}(s) \implies X(q = \text{RECOVERABLE\_FAILURE}) \right)$$
* **LTL Safety 3 (Hash Chain Integrity):**
  $$\square \left( \neg \text{IsHashChainValid}(s) \implies X(q = \text{SECURITY\_LOCKDOWN}) \right)$$
* **LTL Safety 4 (Unidirectional Automata Decoupling):**
  $$\square \left( \text{State}(\mathcal{H}) = q_H \implies \text{DirectMutation}(M) = \text{FALSE} \right)$$

#### Proprietà CTL (Computation Tree Logic)
* **CTL Reachability (Accessibilità Permanente dell'Emancipazione):**
  $$AG \left( EF (q_H = \text{SUSTAINED\_INDEPENDENCE}) \right)$$

* **CTL Trap-Free Safety (Assenza di Stati Trappola Irrecuperabili):**
  $$AG \left( q = \text{SECURITY\_LOCKDOWN} \implies EX (q = \text{SECURITY\_LOCKDOWN} \lor q = \text{NORMAL} \lor q = \text{SAFE\_READ\_ONLY\_MODE}) \right)$$

---

# PARTE II: PROFILE ARCHITECTURE & CONCRETE REFERENCE PROFILES

---

## 10. STANDARD REFERENCE PROFILE 1 (JSON / SC-JCS-1 / SHA-256 / Ed25519)

Il presente capitolo definisce il **Profilo di Riferimento Concreto Predefinito (Profile 1)** per l'interoperabilità di primo livello.

### 10.1 Binding delle Primitive Crittografiche, Identificatori e Mapping dei Campi
* **Mappatura Identificatori ($\mathcal{I}$):** Stringhe `UUIDv7` conformi a RFC 9562.
* **Mappatura Tempo ($\mathcal{T}$):** Stringhe formattate secondo ISO 8601 / RFC 3339 UTC Z con precisione ai millisecondi.
* **Mappatura Hash ($H$):** Algoritmo **SHA-256** (digest di 32 byte / 64 caratteri esadecimali).
* **Mappatura Firma ($\text{Sig}$):** Algoritmo **Ed25519** (PureEd25519 su curva Ed25519).
* **Mapping 1-a-1 Esaustivo dei Campi di $\text{TransactionBody}$ (§1.1.3):**
  1. `tx_id` $\longrightarrow$ `"tx_id"`
  2. `case_id` $\longrightarrow$ `"case_id"`
  3. `seq_num` $\longrightarrow$ `"sequence_number"`
  4. `prev_hash` $\longrightarrow$ `"prev_decision_checksum"`
  5. `timestamp` $\longrightarrow$ `"timestamp_utc"`
  6. `actor` $\longrightarrow$ `"actor_id"`
  7. `event` $\longrightarrow$ `"event"`
  8. `payload` $\longrightarrow$ `"payload"`
  9. `policy_binding_hash` $\longrightarrow$ `"policy_binding_hash"`
  10. `schema_version` $\longrightarrow$ `"schema_version"`
  11. `specification_id` $\longrightarrow$ `"specification_id"`

---

### 10.2 Il Profilo di Canonizzazione JSON SC-JCS-1
**Dichiarazione Normativa di Non-Equivalenza:** **SC-JCS-1 è un profilo di canonizzazione derivato e NON-COMPATIBILE a livello di hash con lo standard RFC 8785 JCS**.

#### 10.2.1 Sottoinsieme $J_{\text{SC}}$ e Strict Signed Safe Integer Range
Un documento JSON $j \in \text{JSON}_{\text{RFC8259}}$ appartiene al sottoinsieme $J_{\text{SC}}$ se e solo se tutti i numeri presenti sono interi compresi nell'intervallo chiuso:

$$I_{\text{safe}} = \left[ -(2^{53} - 1), \ +(2^{53} - 1) \right] = \left[ -9007199254740991, \ +9007199254740991 \right]$$

Qualsiasi notazione contenente punti decimali (`1.0`), notazione scientifica (`1e10`), `NaN` o `Infinity` `MUST` essere rifiutata con **Exit Code 25 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 10.2.2 Algoritmo di Serializzazione Canonica SC-JCS-1
1. **Whitespace Elimination:** Rimuovere tutti i caratteri di spaziatura esterni alle stringhe.
2. **String Escaping & Literal Primitives Rule:**
   * Le stringhe JSON `MUST` applicare l'escaping unicamente per i caratteri di controllo Unicode U+0000..U+001F, le virgolette doppie (`"`) ed il carattere di barra rovesciata (`\`). Qualsiasi altro carattere (compreso `/`) `MUST` essere rappresentato in forma letterale unescaped UTF-8.
   * I valori booleani `MUST` essere rappresentati esplicitamente come letterali `true` o `false`.
   * I valori nulli `MUST` essere rappresentati esplicitamente come letterale `null`.
3. **Unicode Normalization:** Applicare la normalizzazione Unicode Normalization Form C (NFC) a tutte le stringhe.
4. **Object Key Sorting:** Ordinare le chiavi degli oggetti JSON in modo ascendente secondo i code-unit UTF-16.
5. **Preservazione e Ordinamento degli Array (Registro Insiemi):**
   * **Default Posizionale:** Tutti gli array JSON negli schemi di Scintilla Core `MUST` preservare rigorosamente l'ordine posizionale originale degli elementi.
   * **Registro Insiemi (Set Semantics Array Registry):** Esclusivamente per i campi espressamente identificati dal seguente registro normativo come insiemi matematici non ordinati, gli elementi dell'array `MUST` essere ordinati in modo ascendente basandosi sulla comparazione binaria dei byte UTF-8 della loro serializzazione SC-JCS-1 canonica:
     $$\text{SetSemanticsRegistry} = \left[ \text{"permissions"}, \ \text{"scopes"}, \ \text{"roles"}, \ \text{"prerequisites"}, \ \text{"completed\_nodes"} \right]$$

---

### 10.3 Machine-Readable $\delta_M$ JSON Definition Contract
Il contratto JSON canonico della macchina degli stati di sicurezza di runtime $M$ per la convalida automatica delle transizioni è definito dal seguente documento schema (la valutazione delle transizioni nell'array `transitions` rispetta tassativamente l'ordine sequenziale top-down / *first-matching rule*):

```json
{
  "automaton_id": "SCINTILLA_RUNTIME_SAFETY_AUTOMATON",
  "specification_version": "2.0.0-TIMELESS",
  "states": ["NORMAL", "REQUIRE_RECALIBRATION", "VALIDATION_ERROR", "RECOVERABLE_FAILURE", "OPERATOR_REQUIRED", "SECURITY_LOCKDOWN", "SAFE_READ_ONLY_MODE"],
  "initial_state": "NORMAL",
  "events": ["EV_SUCCESS", "EV_ABANDON", "EV_SML_FAIL", "EV_LEASE_EXP", "EV_HASH_CORRUPT", "EV_TIMEOUT", "EV_OVERRIDE", "EV_REPAIR"],
  "transitions": [
    {"from": "NORMAL", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "NORMAL", "event": "EV_ABANDON", "to": "REQUIRE_RECALIBRATION"},
    {"from": "NORMAL", "event": "EV_SML_FAIL", "to": "VALIDATION_ERROR"},
    {"from": "NORMAL", "event": "EV_LEASE_EXP", "to": "RECOVERABLE_FAILURE"},
    {"from": "NORMAL", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "NORMAL", "event": "EV_TIMEOUT", "to": "VALIDATION_ERROR"},
    {"from": "NORMAL", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "NORMAL", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_ABANDON", "to": "REQUIRE_RECALIBRATION"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_SML_FAIL", "to": "VALIDATION_ERROR"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_LEASE_EXP", "to": "RECOVERABLE_FAILURE"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_TIMEOUT", "to": "VALIDATION_ERROR"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "REQUIRE_RECALIBRATION", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "VALIDATION_ERROR", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "VALIDATION_ERROR", "event": "*", "to": "VALIDATION_ERROR"},
    {"from": "RECOVERABLE_FAILURE", "event": "EV_SUCCESS", "to": "NORMAL"},
    {"from": "RECOVERABLE_FAILURE", "event": "EV_TIMEOUT", "to": "OPERATOR_REQUIRED"},
    {"from": "RECOVERABLE_FAILURE", "event": "*", "to": "RECOVERABLE_FAILURE"},
    {"from": "OPERATOR_REQUIRED", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "OPERATOR_REQUIRED", "event": "*", "to": "OPERATOR_REQUIRED"},
    {"from": "SECURITY_LOCKDOWN", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "SECURITY_LOCKDOWN", "event": "EV_TIMEOUT", "to": "SAFE_READ_ONLY_MODE"},
    {"from": "SECURITY_LOCKDOWN", "event": "*", "to": "SECURITY_LOCKDOWN"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "*", "to": "SAFE_READ_ONLY_MODE"}
  ]
}
```

---

### 10.4 Mappatura Tassonomica degli Exit Codes nel Profilo 1
* Fallimento Schema / EBNF $\implies$ **Exit Code 20 (`ERR_SML_PARSE_FAILED`)**
* Fallimento Hash / Replay $\implies$ **Exit Code 17 (`ERR_SECURITY_VIOLATION` / Alias `BASH4LLM_ERR_SEC`)**
* Fallimento Fencing / Lease $\implies$ **Exit Code 13 (`ERR_INFRASTRUCTURE_IO`)**
* Fallimento DAG / Ciclo $\implies$ **Exit Code 23 (`ERR_GRAPH_CYCLE_DETECTED`)**
* Fallimento Mismatch Schema $\implies$ **Exit Code 24 (`ERR_SCHEMA_MISMATCH`)**
* Fallimento JSON / Number $\implies$ **Exit Code 25 (`ERR_CONFIGURATION_MALFORMED`)**

---

# PARTE III: ANNEXES (INFORMATIVE & SYNTACTIC MAPPINGS)

---

## ANNEX A: TYPESCRIPT TYPE MAPPING (INFORMATIVE)

Le seguenti definizioni TypeScript costituiscono una mappatura informativa non-normativa degli Abstract Data Types definita nella Parte I per facilitare lo sviluppo sui runtime JavaScript/Node.js/Deno/Bun:

```typescript
export type ActorType = "USER" | "LLM" | "OPERATOR" | "SYSTEM" | `EXTENSION_ACTOR:${string}`;

export type PermissionIdentifier = 
  | "SC.PERMISSION.READ_LEDGER"
  | "SC.PERMISSION.CREATE_DECISION"
  | "SC.PERMISSION.MIGRATE_SCHEMA"
  | "SC.PERMISSION.OPERATOR_OVERRIDE"
  | "SC.PERMISSION.REVOKE_CONSENT"
  | `SC.PERMISSION.EXTENSION:${string}`;

export interface AuthorizationGrant {
  grant_id: string;              // UUIDv7
  actor_id: string;              
  permission: PermissionIdentifier;    
  scope: string;                 
  issued_by: string;             
  issued_at_utc: string;         // ISO 8601 UTC Z
  expires_at_utc?: string;       
  policy_hash: string;           
}

export type ProvenanceCategory = 
  | "USER_DECLARATION"
  | "LLM_INFERENCE"
  | "SYSTEM_VERIFIED"
  | "OPERATOR_CONFIRMED"
  | "EXTERNAL_SOURCE"
  | `EXTENSION_PROVENANCE:${string}`;

export interface DataProvenanceRecord {
  provenance_id: string;            
  source_category: ProvenanceCategory;
  asserted_by_actor_id: string;     
  timestamp_utc: string;            
  confidence_score: number;         // Intervallo [0.0, 1.0]
  verifiability_status: "UNVERIFIED" | "PENDING_VERIFICATION" | "VERIFIED" | "REJECTED";
  verification_method?: string;     
}
```

---

## ANNEX C: SML v2.0 SPECIFICATION (SYNTACTIC EBNF & SEMANTIC VALIDATION)

### C.1 Grammatica EBNF Formale Puramente Sintattica

```ebnf
SML_Document          ::= SML_Header 
                           SML_ListenSummary 
                           SML_ListenAgency 
                           SML_ConvOutcome 
                           SML_MapOverview 
                           SML_Transition 
                           SML_MicroAction 
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

---

### C.2 Livello di Validazione Semantica (Semantic Validation Layer)
Il processo di analisi dell'output SML v2.0 si articola in due fasi nettamente separate:
1. **Fase 1: Validazione Sintattica (Syntactic Validation):** Eseguita dal Parser SML (Livello 4) per verificare il rispetto della grammatica EBNF (§C.1). Un fallimento sintattico produce l'evento `EV_SML_FAIL` ($\sigma_2$) ed Exit Code 20 (`ERR_SML_PARSE_FAILED`).
2. **Fase 2: Validazione Semantica (Semantic Validation):** Eseguita dai livelli superiori (Livelli 3 e 2) sull'oggetto ipotesi strutturato. La validazione semantica controlla:
   * **Coerenza Logica:** Corrispondenza con lo stato corrente dell'automa $\mathcal{H}$;
   * **Integrità della Provenienza:** Verifica che i dati dichiarati siano marcati con la corretta `DataProvenanceRecord` (§1.4);
   * **Valutazione della Confidenza:** Verifica del superamento della soglia parametrizzata $\theta_{\text{confidence}} \in \Theta$;
   * **Compatibilità di Policy:** Assenza di violazioni delle regole del Policy Guidance Engine (Livello 2).

---

# PARTE IV: CONFORMANCE FRAMEWORK & TEST VECTOR AXIOMS

### 11.1 Assiomatizzazione dei Test Vectors
I Test Vector concreti (stringhe serializzate SC-JCS-1 ed impronte esadecimali SHA-256) per lo Standard Reference Profile 1 sono formalmente separati dalla presente specifica astratta e sono mantenuti nell'artefatto normativo di conformità: **`SCINTILLA-CORE-CONFORMANCE-PROFILE-1.JSON`**.

---

# 12. STATO DI CERTIFICAZIONE E LIVELLI DI VERIFICA

## 12.1 Stato Normativo della Specifica

La presente **SCINTILLA CORE CANONICAL SPECIFICATION v2.0 Timeless** definisce una specifica normativa canonica del dominio SCINTILLA CORE.

Lo stato corrente del documento è:

**SPEC-COMPLETE — Specifica Canonica Completa**

Tale stato certifica che:
- la struttura normativa del modello è definita;
- i domini astratti, gli invarianti, gli automi, le regole operative e i profili di riferimento sono specificati;
- la specifica costituisce la Single Source of Truth normativa del sistema SCINTILLA CORE.

Lo stato **SPEC-COMPLETE** non implica automaticamente l'avvenuta esecuzione di verifiche meccanizzate, prove formali assistite da strumenti o certificazione di una specifica implementazione software.

---

## 12.2 Separazione tra Specifica, Verifica e Certificazione

SCINTILLA CORE distingue formalmente i seguenti livelli di maturità:

### Livello SPEC — Specifica Canonica

Comprende il presente documento normativo.

Stato attuale:

**SPEC-COMPLETE**

---

### Livello VERIF — Verifica Formale degli Artefatti

Richiede artefatti esterni di verifica, tra cui:

- modello formale eseguibile derivato dalla specifica (es. TLA+, NuSMV o equivalente);
- verifica delle proprietà temporali dichiarate;
- verifica dell'assenza di deadlock o configurazioni non definite nel dominio modellato;
- formalizzazione delle eventuali assunzioni ambientali, incluse condizioni di fairness.

Stato:

**PENDING VERIFICATION ARTIFACTS**

---

### Livello VERIF-PROOF — Dimostrazione Meccanizzata

Richiede la produzione di prove formali mediante strumenti di theorem proving assistito (es. Lean 4, Coq, Isabelle/HOL o equivalenti).

Tali prove devono dimostrare, secondo il formalismo scelto:

- le proprietà del modello algebrico del Ledger;
- il determinismo della funzione di proiezione dello stato;
- le proprietà dichiarate come teoremi nella presente specifica.

Stato:

**PENDING PROOF ARTIFACTS**

---

### Livello CERT — Certificazione di Implementazione

Richiede un'implementazione conforme sottoposta a verifica tramite test runner e artefatti di conformance.

La certificazione deve includere almeno:

- esecuzione dei test vector normativi;
- verifica della corrispondenza degli output canonici;
- verifica della catena di hash;
- verifica degli exit code previsti;
- verifica dei comportamenti di errore definiti dalla specifica.

Stato:

**PENDING IMPLEMENTATION CERTIFICATION**

---

## 12.3 Regola di Dichiarazione della Certificazione

Nessuna implementazione, documento derivato o comunicazione esterna SHALL dichiarare SCINTILLA CORE come:

- "formalmente verificato";
- "formalmente certificato";
- "matematicamente provato";

in assenza dei corrispondenti artefatti verificati relativi al livello dichiarato.

La sola conformità alla presente specifica garantisce esclusivamente lo stato:

**SPEC-COMPLETE — Canonical Specification**

---

## 12.4 Evoluzione dello Stato di Certificazione

Il passaggio tra livelli di certificazione richiede la conservazione degli artefatti prodotti e la loro associazione alla versione esatta della specifica mediante identificativo univoco della specifica (`specification_id`) e versione normativa.

Ogni modifica alla specifica che alteri semantica, invarianti, algoritmi o contratti normativi SHALL richiedere una nuova valutazione dello stato di certificazione.
