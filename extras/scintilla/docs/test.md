
#### 1.1.3 Proiezioni Canoniche dello Stato (Layer A)
La scomposizione dello stato astratto $S \in \mathcal{S}$ nelle sue componenti primarie e scalari è regolata dagli operatori di proiezione ortogonale:

```math
\pi_{\text{persistent}} : \mathcal{S} \longrightarrow \mathcal{S}_{\text{persistent}}
```
```math
\pi_{\text{internal}} : \mathcal{S} \longrightarrow \mathcal{S}_{\text{internal}}
```
```math
\pi_{\text{auxiliary}} : \mathcal{S} \longrightarrow \mathcal{S}_{\text{auxiliary}}
```

Proiezioni scalari derivate degli automi:
```math
\pi_Q(S) := \pi_{\text{internal}}(S).q \in Q
```
```math
\pi_{Q_H}(S) := \pi_{\text{internal}}(S).q_H \in Q_H
```

---


### 1.2 Interfaccia Osservabile Pubblica ed Equivalenza di Stato

#### 1.2.1 Funzione di Osservazione Pubblica Obs (Layer A)
La proiezione esterna dello stato verso le interfacce utente, API e viste pubbliche è governata dalla funzione pura di osservazione:

```math
\text{Obs} : \mathcal{S} \longrightarrow \mathcal{O}
```
```math
\text{Obs}(S) := \left\langle \pi_{\text{persistent}}(S).\text{case}_{\text{id}}, \ \mathcal{M}_{\text{prov}}, \ \mathcal{Q}_{\text{consent}} \setminus \mathcal{R}, \ \mathcal{K}_{\text{playbook}}, \ \mathcal{Q}_{\text{revoked\_items}}, \ \mathcal{K}_{\text{competence}} \setminus \mathcal{R}, \ \mathcal{V}_{\text{vault}} \setminus \mathcal{R} \right\rangle
```

*dove* 
```math
\mathcal{R} = \{ e \mid \text{ResourceId}(e) \in \mathcal{Q}_{\text{revoked\_items}} \}
```

#### 1.2.2 Equivalenza di Stato Primario CoreState (Layer A)
Due stati astratti $S_1, S_2 \in \mathcal{S}$ sono semanticamente equivalenti nello stato primario se e solo se le loro proiezioni di persistenza e controllo interno sono identiche:

```math
S_1 \equiv_{\text{CoreState}} S_2 \iff \pi_{\text{persistent}}(S_1) = \pi_{\text{persistent}}(S_2) \land \pi_{\text{internal}}(S_1) = \pi_{\text{internal}}(S_2)
```

#### 1.2.3 Proprietà Derivata dell'Algebra di Stato: Irrilevanza Osservazionale del Buffer Temporaneo (Layer A / Level 3)
```math
\mathbf{THEOREM-AUXILIARY-IRRELEVANCE}
```
```math
\forall S_1, S_2 \in \mathcal{S}, \quad S_1 \equiv_{\text{CoreState}} S_2 \implies \text{Obs}(S_1) = \text{Obs}(S_2)
```
*(Dichiara che le variazioni nel buffer volatile*
```math
\mathcal{S}_{\text{auxiliary}}
```
*non alterano le proiezioni osservabili dei diritti, del percorso o dello stato storico dell'utente. Costituisce un teorema derivato direttamente dalle definizioni matematiche di* $\text{Obs}(S)$ e
```math
\equiv_{\text{CoreState}}
```

---


### 1.3 ASSIOMA DEL GENESIS STATE s0 (Layer A)

Lo stato iniziale di genesi $s_0 = P(\epsilon) \in \mathcal{S}$ è formalizzato come la tripla annidata conforme alla struttura di $\mathcal{S}$ (§1.1.1):

```math
s_0 := \left\langle s_{0,\text{persistent}}, \ s_{0,\text{internal}}, \ s_{0,\text{auxiliary}} \right\rangle
```

dove:

```math
s_{0,\text{persistent}} := \left\langle \text{case}_{\text{id}}=\text{null}, \ \mathcal{M}_{\text{prov}}=\emptyset, \ \mathcal{Q}_{\text{consent}}=\emptyset, \ \mathcal{K}_{\text{playbook}}=\langle \text{null}, \text{null}, \emptyset \rangle, \ \mathcal{Q}_{\text{revoked\_items}}=\emptyset, \ \mathcal{K}_{\text{competence}}=\emptyset, \ \mathcal{V}_{\text{vault}}=\emptyset \right\rangle
```

```math
s_{0,\text{internal}} := \left\langle q=\text{NORMAL}, \ q_H=\text{UNASSESSED}, \ \mathcal{P}_{\text{active}}=\mathcal{P}_{\text{default}}, \ \mathcal{F}_{\text{lease}}=\langle 0, t_0 \rangle, \ \mathcal{O}_{\text{bound}}=\text{AUTOMATED\_SUPPORT}, \ t_{\text{pause\_start}}=\text{null}, \ \mathcal{M}_{\text{metrics}}=\langle 0, 0, 0, 0 \rangle, \ \text{seq\_num}=0, \ \text{last\_hash}=\mathbf{0}_{\mathcal{D}_{256}} \right\rangle
```

```math
s_{0,\text{auxiliary}} := \left\langle \mathcal{D}_{\text{drafts}}=\emptyset \right\rangle
```

con vista derivata iniziale:

```math
\text{Derive}(s_0) = \langle \mathcal{O}_{\text{decision}}=\text{NONE}, \ \mathcal{A}_{\text{index}}=0 \rangle
```

#### 1.3.1 Obbligo Formale di Invarianza di Serializzazione del Genesis State (RFC-007)

```math
\mathbf{PROOF-OBLIGATION-GENESIS-SERIALIZATION-INVARIANCE} := \text{Canon}(\text{ToJSON}(s_0^{\text{v4.5.5}})) \equiv_{\text{bytes}} \text{Canon}(\text{ToJSON}(s_0^{\text{v4.5.3}}))
```
*(Garantisce che il refactoring algebrico ed organizzativo di* $s_0$ *produca un flusso di byte UTF-8 e un hash* 
```math
H_0 = \mathbf{0}_{\mathcal{D}_{256}}
```
*identici alla versione canonica di riferimento).*

---

### 1.4 TRANSAZIONI, INVOLUCRO DI ESECUZIONE E LEDGER IMMUTABILE L

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
q_H = \text{HUMAN\_PAUSED}
```
l'involucro di esecuzione `MUST` registrare:

```math
\text{execution\_envelope} = \left\langle \text{"PROCESSED\_NO\_STATE\_EFFECT"}, \text{"HUMAN\_JOURNEY\_PAUSED"}, \text{false} \right\rangle
```

#### 1.4.2 Predicato Normativo di Sicurezza in Costruzione Errori e BuildErrorTx (Layer A e B2 / RFC-006)

```math
\text{IsLockdownEvent}(\sigma) \iff \sigma \in \{ \text{EV\_HASH\_CORRUPT} \}
```

```math
\text{BuildErrorTx}(S, E, \text{err}, \sigma_{\text{orig}}) := \left\langle \text{TransactionBody}\left(\text{case}_{\text{id}}=S.\text{case}_{\text{id}}, \text{seq}_{\text{num}}=S.\text{seq}_{\text{num}}+1, \text{prev}_{\text{hash}}=S.\text{last\_hash}, \text{timestamp}=E.t_{\text{wall}}, \text{event}=\begin{cases} \sigma_{\text{orig}} & \text{se } \text{IsLockdownEvent}(\sigma_{\text{orig}}) \\ \text{EV\_SML\_FAIL} & \text{altrimenti} \end{cases}, \text{actor}=\text{SYSTEM}, \text{payload}=\text{err}\right), \ \text{execution\_envelope}_{\text{err}}, \ \text{proof}_{\text{null}} \right\rangle
```

```math
\text{BuildSystemTx}(S, E, \sigma) := \left\langle \text{TransactionBody}(\text{case}_{\text{id}}=S.\text{case}_{\text{id}}, \text{seq}_{\text{num}}=S.\text{seq}_{\text{num}}+1, \text{prev}_{\text{hash}}=S.\text{last\_hash}, \text{timestamp}=E.t_{\text{wall}}, \text{event}=\sigma, \text{actor}=\text{SYSTEM}), \ \text{execution\_envelope}_{\text{default}}, \ \text{proof}_{\text{null}} \right\rangle
```

#### 1.4.3 Il Ledger come Monoide Libero L e Funzione Persist (Layer A)

Il registro immutabile delle decisioni (Ledger) è formalizzato come un Monoide Libero definito sullo spazio dei corpi delle transazioni canonizzate:

```math
\mathcal{L} := \langle (\text{TransactionBody})^*, \mathbin{\Vert}, \epsilon \rangle
```

La funzione pura di persistenza converte la transazione $t \in T$ nel suo corpo canonico mediante $\text{EncodeTx}(t) \in \text{TransactionBody}$ e la concatena in modo append-only al registro:

```math
\text{Persist} : \mathcal{L} \times T \longrightarrow \mathcal{L}
```

```math
\text{Persist}(L, t) := L \mathbin{\Vert} \langle \text{EncodeTx}(t) \rangle
```

#### 1.4.4 Invariante di Consistenza della Proiezione del Ledger (Layer A)

```math
\mathbf{INVARIANT-LEDGER-PROJECTION-CONSISTENCY}
```

* **Ipotesi H1:** La funzione $\text{EncodeTx} : T \to \text{TransactionBody}$ preserva la semantica formale della transazione $t \in T$.
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
```math
\text{ResourceId}(e) := \begin{cases}
e.\text{doc\_id} & \text{se } e \in \mathcal{V}_{\text{vault}} \\
e.\text{consent\_id} & \text{se } e \in \mathcal{Q}_{\text{consent}} \\
e.\text{skill\_id} & \text{se } e \in \mathcal{K}_{\text{competence}}
\end{cases}
```

In sede di proiezione dello stato o consultazione via API ($\text{Obs}$), qualsiasi elemento $e$ tale che:
```math
\text{ResourceId}(e) \in \mathcal{Q}_{\text{revoked\_items}}
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
& \quad \land \ |t.\text{timestamp} - E.t_{\text{wall}}| \le \Theta.\theta_{\text{max\_clock\_skew}} \\
& \quad \land \ E.\text{LeaseManager}.\text{IsTokenValid}(S.\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}}) = \text{TRUE} \\
\text{ERR\_SIG} & \text{se la firma crittografica è invalida} \\
\text{ERR\_CLOCK} & \text{se } |t.\text{timestamp} - E.t_{\text{wall}}| > \Theta.\theta_{\text{max\_clock\_skew}} \\
\text{ERR\_LEASE} & \text{se il lease di concorrenza è scaduto o invalido}
\end{cases}
```

```math
\mathbf{REQ-CLUSTER-CLOCK-SYNC} := \max_{i,j} |t_{\text{wall}, i} - t_{\text{wall}, j}| \le \delta_{\text{clock}} \quad \text{con } \delta_{\text{clock}} < \frac{1}{2} \Theta.\theta_{\text{max\_clock\_skew}}
```
*(Impone che la sincronizzazione temporale tra i nodi esecutori sia limitata superiormente per prevenire rifiuti inconsistenti per clock skew).*

#### 1.6.2 Funzione Pura di Transizione di Stato ApplyValidated (Layer A)
La mutazione di stato è governata dalla funzione pura e deterministica $\text{ApplyValidated}$, priva di accesso diretto all'ambiente $E$:

```math
\text{ApplyValidated} : \mathcal{S} \times T \times \text{ValidationResult} \longrightarrow \mathcal{S}
```

#### 1.6.3 Requisito Normativo di Totalità di ApplyValidated (`REQ-APPLY-TOTALITY-POLICY`) (Layer B2)
La funzione pura $\text{ApplyValidated}$ è una **funzione totale** su $\mathcal{S}$ definita dalla seguente specifica a casi con precedenza assoluta di lockdown per corruzione dell'hash:

```math
\text{ApplyValidated}(S, t, \text{v\_res}) := \begin{cases}
S[ q \mapsto \text{SECURITY\_LOCKDOWN} ] & \text{se } t.\text{event} = \text{EV\_HASH\_CORRUPT} \\
\delta_{\text{nominal}}(S, t) & \text{se } t.\text{event} \neq \text{EV\_HASH\_CORRUPT} \land \text{v\_res} = \text{PASS} \land \mathcal{R}_{\text{exec}}(S, t) = \text{ALLOW} \\
\delta_{\text{err}}(S, t, \text{v\_res}) & \text{se } t.\text{event} \neq \text{EV\_HASH\_CORRUPT} \land (\text{v\_res} \in \mathcal{E}_{\text{validation}} \lor \mathcal{R}_{\text{exec}}(S, t) \neq \text{ALLOW})
\end{cases}
```

---

### 1.7 INDICE PROXY OPERATIVO DI GUADAGNO DI AGENCY (AGI_proxy)

L'Indice Proxy $\text{AGI}_{\text{proxy}} \in [0, 10000]$ (espresso in Basis Points interi) misura gli indicatori comportamentali descrittivi di avanzamento dell'utente sul sistema.

#### 1.7.1 Assunzione di Confine Epistemico ed Invariante di Isolamento Descrittivo (Layer B1)

```math
\mathbf{AXIOM-EPISTEMIC-BOUNDARY-AGI}
```

```math
\mathbf{INV-AGI-DESCRIPTIVE-ISOLATION}
```

```math
\forall S \in \mathcal{S}, \forall t \in T, \quad \mathcal{R}_{\text{exec}}(S, t) \text{ MUST NOT depend on } \text{AGI}_{\text{proxy}}(S)
```

*Nota di Chiarimento Semantico sull'Acronimo:* Ai fini della presente specifica e di qualsiasi contratto di interfaccia (API/JSON), l'acronimo **`AGI_proxy`** indica esclusivamente l'**Agency Governance Indicator Proxy** (Indicatore Proxy di Governance dell'Agency Operativa) e non ha alcuna relazione teorica, funzionale o concettuale con costrutti di Artificial General Intelligence.

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

#### 1.7.3 Calcolo Deterministico dell'AGI in Aritmetica Intera Sicura (Layer A / RFC-003)

Per tutti gli stati attivi, 
```math
\text{AGI}_{\text{computed}}(S) \in [0, 10000]
```
è calcolato unicamente in aritmetica intera sicura a 64 bit $I_{\text{safe}}$ con saturazione dei contatori a $10^6$ ed operatore di troncamento $\lfloor \dots \rfloor$:

```math
\text{AGI}_{\text{computed}}(S) := \left\lfloor \frac{w_1 \cdot \text{ClarityScore}_{\text{bp}}(S) + w_2 \cdot \text{ActionExecutionRatio}_{\text{bp}}(S) + w_3 \cdot \text{DependencyReductionScore}_{\text{bp}}(S)}{10000} \right\rfloor
```
where $w_1, w_2, w_3 \in [0, 10000]$ sono interi tali che $w_1 + w_2 + w_3 = 10000$.

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
\left\lfloor \frac{|\{ \text{id} \in V_{\text{completed}} \mid \exists v \in G_P.V_P \text{ t.c. } v.\text{node\_id} = \text{id} \}| \times 10000}{|V_P|} \right\rfloor & \text{se } \text{pb}_{\text{id}} \neq \text{null} \land |V_P| > 0
\end{cases}
```

3. **DependencyReductionScore in Basis Points (RFC-003):**

```math
\text{DependencyReductionScore}_{\text{bp}}(S) := \begin{cases}
0 & \text{se } |V_{\text{active\_completed}}| = 0 \\
\left\lfloor \frac{|\{ \text{id} \in V_{\text{active\_completed}} \mid \exists v \in G_P.V_P \text{ t.c. } v.\text{node\_id} = \text{id} \land \text{IsEmpoweredAction}(v, S) \}| \times 10000}{|V_{\text{active\_completed}}|} \right\rfloor & \text{se } |V_{\text{active\_completed}}| > 0
\end{cases}
```
dove
```math
V_{\text{active\_completed}} = V_{\text{completed}} \cap \{v.\text{node\_id} \mid v \in G_P.V_P\}
```
ed il predicato booleano puro $\text{IsEmpoweredAction}(v, S)$ è formalizzato come:

```math
\text{IsEmpoweredAction}(v, S) \iff \left( v.\text{action\_type} \in \{\text{USER\_CONFIRMED\_STEP}, \text{REQUIRED\_FOR\_SYSTEM\_STATE}\} \land v.\text{gained\_skill} \neq \text{null} \right)
```

---

### 1.8 Contratto del Modulo Crittografico Astratto (`CryptoProviderContract`) (Layer A & C)

Ogni implementazione esecutiva di SCINTILLA Core `MUST` integrare un modulo crittografico conforme alla seguente interfaccia astratta:

```math
\mathbf{CryptoProviderContract} := \langle \text{DeriveKey}, \text{EncryptPayload}, \text{DecryptPayload}, \text{ShredKey}, \text{VerifySignature}, \text{LookupKey} \rangle
```

1. $\text{DeriveKey}(K_{\text{parent}}, \text{context}) \to K_{\text{child}}$: Derivazione deterministica chiavi effimere.
2. $\text{EncryptPayload}(K_{\text{item}}, v) \to \text{Payload}_{\text{encrypted}}$: Cifratura autenticata simmetrica.
3. $\text{DecryptPayload}(K_{\text{item}}, \text{Payload}_{\text{encrypted}}) \to v \mid \bot$: Decifratura ed autenticazione payload.
4. $\text{ShredKey}(K_{\text{id}}) \to \text{TRUE}$: Distruzione del materiale di chiave ed elisione dei percorsi di recupero ($\text{NoRecovery}$).
5. $\text{VerifySignature}(\text{proof}, \text{data}, K_{\text{pub}}) \to \mathbb{B}$: Verifica firma digitale a chiave pubblica.
6. $\text{LookupKey}(K_{\text{id}}) \to K_{\text{active}} \mid \bot$: Verifica presenza ed estrazione del materiale di chiave attivo.

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

```math
M := \langle Q, \Sigma, T_{\delta}, \delta_M, q_0, F_{\text{oper}} \rangle
```

1. **Insieme degli Stati Canonici $Q$ ($|Q|=7$):**
```math
Q = \{ \text{NORMAL } (q_0), \text{REQUIRE\_RECALIBRATION } (q_1), \text{VALIDATION\_ERROR } (q_2), \text{RECOVERABLE\_FAILURE } (q_3), \text{OPERATOR\_REQUIRED } (q_4), \text{SECURITY\_LOCKDOWN } (q_5), \text{SAFE\_READ\_ONLY\_MODE } (q_6) \}
```
2. **Stato Iniziale:** $q_0 = \text{NORMAL}$
3. **Insieme degli Stati Operativamente Stabili $F_{\text{oper}}$:**
```math
F_{\text{oper}} = \{ \text{NORMAL}, \text{SAFE\_READ\_ONLY\_MODE} \}
```

#### 2.2.1 Definizione di Dominio DP-FSM e Precondizione Statica di Unicità
Ai fini della specifica SCINTILLA Core, un automa DP-FSM indica una macchina a stati finiti la cui relazione di transizione è deterministica a valle dell'applicazione della funzione di risoluzione prioritaria $\mathbf{Resolve}(q, \sigma)$.

Un contratto di automa è valido ed eseguibile se e solo se soddisfa la precondizione statica di unicità:

```math
\mathbf{ValidFSMContract} \iff \left( \forall q \in Q, \forall \sigma \in \Sigma, \ |\delta_{\text{explicit}}(q, \sigma)| \le 1 \right) \ \land \ \left( \forall \sigma \in \Sigma, \ |\delta_{\text{wildcard}}(\sigma)| \le 1 \right)
```

#### 2.2.2 Regola di Precedenza Wildcard, Funzione Algebrica Resolve e Regola di Parsing Target Wildcard

```math
\mathbf{RULE-EXPLICIT-SHADOWS-WILDCARD}
```
**"The explicit transition rules SHALL strictly shadow wildcard transition rules according to the four-tier resolution order."**

```math
\mathbf{RULE-WILDCARD-TARGET-REFLEXIVITY}
```
**"When a wildcard token `"*"` appears in the target state field (`"to": "*"`) of a machine transition contract, the runtime parser MUST interpret the transition as an identity/stuttering step ($q' = q$), maintaining the current state unchanged."**

La risoluzione deterministica della transizione negli automi DP-FSM è governata dalla funzione algebrica pura con gerarchia a 4 livelli (estesa dalla regola di riflessività sul target):

```math
\mathbf{Resolve}(q, \sigma, F_T) := \begin{cases}
q & \text{se } q \in F_T \quad (\text{Terminal Trap Rule}) \\
\delta(q, \sigma) & \text{se } \delta(q, \sigma) \text{ è definita su } (\text{Stato Esplicito } q, \text{Evento Esplicito } \sigma) \land q \notin F_T \\
\delta(*, \sigma) & \text{se } \delta(*, \sigma) \text{ è definita su } (\text{Stato Wildcard } *, \text{Evento Esplicito } \sigma) \land q \notin F_T \\
\delta(q, *) & \text{se } \delta(q, *) \text{ è definita su } (\text{Stato Esplicito } q, \text{Evento Wildcard } *) \land q \notin F_T \\
\delta(*, *) & \text{se } \delta(*, *) \text{ è definita su } (\text{Stato Wildcard } *, \text{Evento Wildcard } *) \land q \notin F_T \\
q & \text{altrimenti } (\text{Implicit Stuttering})
\end{cases}
```

*Nota esplicativa:* Quando l'immagine della funzione $\delta$ restituisce il token wildcard (es. $\delta(*, \sigma) = *$), la funzione $\mathbf{Resolve}$ applica l'identità $q' = q$.

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
La permanenza dell'automa $M$ nello stato:
```math
q_6 = \text{SAFE\_READ\_ONLY\_MODE}
```
è governata esclusivamente dalle regole di transizione del contratto $\delta_M$ (§10.4) e dalle meta-regole SOS (§3.2):
1. **Eventi di Business** ($\Sigma_{\text{business}}$): Impongono uno *stuttering step* ($q_6 \to q_6$), precludendo qualsiasi mutazione dello stato operativo.
2. **Eventi Amministrativi** ($\Sigma_{\text{administrative}}$): Sono ammessi ed elaborati per garantire l'esercizio inalienabile dei diritti dell'utente (revoca privacy, oblivion).
3. **Eventi di Ripristino** ($\Sigma_{\text{recovery}}$): Transitano lo stato verso $\text{NORMAL}$ previa verifica autorizzativa dell'operatore o applicazione di patch formale.

---

### 2.3 Human Journey State Machine H (Layer A & B2)

L'evoluzione concettuale del percorso umano dell'utente è modellata dall'automa DP-FSM di dominio $\mathcal{H}$:

```math
\mathcal{H} := \langle Q_H, \Sigma_H, \delta_H, q_{H0}, F_H \rangle
```

1. **Insieme degli Stati del Percorso Umano** $Q_H$ ($|Q_H|=12$):
```math
Q_H = \{ \text{UNASSESSED}, \text{INITIAL\_ASSESSMENT}, \text{STABILIZATION}, \text{DOCUMENT\_RECOVERY}, \text{EMPLOYMENT\_READINESS}, \text{FINANCIAL\_AUTONOMY}, \text{SUSTAINED\_INDEPENDENCE}, \text{HUMAN\_PAUSED}, \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{HUMAN\_GOAL\_CHANGED}, \text{HUMAN\_DECLINED\_ASSISTANCE}, \text{PREVENTIVE\_STANDBY} \}
```

2. **Stato Iniziale:** $q_{H0} = \text{UNASSESSED} = h_0$
3. **Insieme degli Stati Target / Terminali** $F_H$:
```math
F_H = \{ \text{HUMAN\_DECLINED\_ASSISTANCE} \} = \{ h_{10} \}
```

4. **Alfabeto degli Eventi Umani** $\Sigma_H$ ($|\Sigma_H|=15$):
```math
\Sigma_H = \{ \text{HEV\_ASSESS\_START}, \text{HEV\_STABILIZED}, \text{HEV\_DOCS\_OBTAINED}, \text{HEV\_JOB\_READY}, \text{HEV\_FINANCE\_OK}, \text{HEV\_INDEPENDENCE\_ACHIEVED}, \text{HEV\_RELAPSE\_REGRESS}, \text{HEV\_RECALIBRATION\_REQ}, \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_RESUME\_REQUESTED}, \text{HEV\_GOAL\_UPDATE}, \text{HEV\_DECLINE\_ALL}, \text{HEV\_EMOTIONAL\_OVERWHELM}, \text{HEV\_PREVENTIVE\_SUPPORT\_REQ}, \text{HEV\_STEP\_COMPLETED} \}
```

#### 2.3.1 Dinamica dello Stato h11 (PREVENTIVE_STANDBY) come "Base Sicura" (Layer B2)
Lo stato:
```math
h_{11} = \text{PREVENTIVE\_STANDBY}
```
definisce la condizione di **Santuario in Standby (Base Sicura)**:

1. **Semantica di Custodia Discreta:** Quando l'automa umano $\mathcal{H}$ raggiunge lo stato $h_{11}$, l'utente ha acquisito piena autonomia operativa. Il sistema cessa di proporre micro-azioni quotidiane o notifiche proattive, ma mantiene attiva la vista di ascolto discreto.
2. **Invarianza di Accessibilità dello Stato Finale:** Nel raggiungimento dello stato target:
```math
h_6 = \text{SUSTAINED\_INDEPENDENCE}
```
l'automa umano induce la transizione allo stato
```math
h_{11} = \text{PREVENTIVE\_STANDBY}
```
preservando a tempo indeterminato l'accesso alla vista osservabile $\text{Obs}(S)$, al Vault
```math
\mathcal{V}_{\text{vault}}
```
e al registro delle competenze
```math
\mathcal{K}_{\text{competence}}
```
3. **Re-ingaggio Immediato:** Qualsiasi espressione di disagio, sopraffazione emotiva o richiesta esplicita dell'utente transitano immediatamente l'automa da $h_{11}$ allo stato di supporto attivo `HUMAN_RECALIBRATION_REQUIRED`, riattivando la guida senza che l'utente debba giustificare la propria ricaduta.

#### 2.3.2 Regola Normativa di Preservazione del Progresso Umano (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`)
Quando l'automa $\mathcal{H}$ si trova nello stato $h_8$ (`HUMAN_RECALIBRATION_REQUIRED`) e riceve l'evento:
```math
\text{HEV\_STABILIZED}
```
il runtime `MUST` determinare lo stato di destinazione $q_H'$ mediante la funzione pura:
```math
\text{ResolveNextHumanState}(q_H, \pi_{\text{persistent}}(S).\mathcal{K}_{\text{playbook}})
```
Tale funzione assegna $q_H'$ allo stato corrispondente al nodo attivo in:
```math
\mathcal{K}_{\text{playbook}}.\text{node}_{\text{curr}}
```

È tassativamente vietato retrocedere l'utente allo stato $h_2$ (`STABILIZATION`) qualora i prerequisiti degli stati successivi risultino già soddisfatti in $V_{\text{completed}}$.

---

### 2.4 Equazione Matematica del Sistema Reattivo Composito (Layer A)

Il sistema reattivo globale di SCINTILLA Core è modellato dallo spazio di stato composito $S_C = Q \times Q_H$.

La funzione di transizione pura dell'automa composito $\delta_C : (Q \times Q_H) \times (\Sigma \cup \Sigma_H) \longrightarrow (Q \times Q_H)$ è definita dall'equazione a casi:

```math
\delta_C((q, q_H), \sigma_C) = \begin{cases} 
(\delta_M(q, \sigma_C, T_{\delta}), q_H) & \text{se } \sigma_C \in \Sigma \\
(q, \mathbf{Resolve}(q_H, \sigma_C, F_H)) & \text{se } \sigma_C \in \Sigma_H \land q \in (F_{\text{oper}} \cup \{\text{REQUIRE\_RECALIBRATION}\}) \\
(q, \mathbf{Resolve}(q_H, \sigma_C, F_H)) & \text{se } \sigma_C \in \Sigma_H \land q \in \{\text{VALIDATION\_ERROR}, \text{RECOVERABLE\_FAILURE}\} \\
(q, \mathbf{Resolve}(q_H, \sigma_C, F_H)) & \text{se } \sigma_C \in \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \land q \in \{\text{OPERATOR\_REQUIRED}, \text{SECURITY\_LOCKDOWN}\} \\
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
*(Deriva direttamente dalla purezza e dal determinismo delle funzioni* $\delta_M$, $\delta_H$ e $\text{ApplyValidated}$)

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

### 3.2 META-REGOLE SOS DELLA SICUREZZA DI RUNTIME (M) (Layer B3)

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q' = \mathbf{Resolve}(q, \sigma_C, \emptyset) \quad \text{EvaluateGuards}(S, t) = \text{PASS}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q', q_H, \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-META-SAFETY}]
```

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma \quad (\text{v\_res} \in \mathcal{E}_{\text{validation}} \lor \neg \text{Authorized}(\sigma_C, \text{type}(\alpha)) \lor \text{EvaluateGuards}(S, t) = \text{FAIL}) \quad q' = \begin{cases} q & \text{se } q \in \{\text{SECURITY\_LOCKDOWN}, \text{SAFE\_READ\_ONLY\_MODE}\} \\ \text{VALIDATION\_ERROR} & \text{altrimenti} \end{cases}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q', q_H, \text{ApplyValidated}(S, \text{BuildErrorTx}(S, E, \text{v\_res}, \sigma_C), \text{v\_res}) \rangle} \quad [\text{SOS-META-SAFETY-FAIL}]
```

#### 3.2.1 Meta-Regole SOS di Ripristino ed Override da Operatore (Layer B3)

```math
\frac{\sigma_C = \text{event}(t) = \text{EV\_REPAIR} \quad q \in \{\text{SECURITY\_LOCKDOWN}, \text{SAFE\_READ\_ONLY\_MODE}\} \quad \text{type}(\alpha) = \text{OPERATOR} \quad p = t.\text{payload} \quad \text{ValidRepairPatch}(p)}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle \text{NORMAL}, q_H, \text{ApplyCompensativeRepair}(S, p) \rangle} \quad [\text{SOS-COMPENSATIVE-REPAIR}]
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

### 3.4 META-REGOLE SOS DEL PERCORSO UMANO (H) E SOVRANITÀ (Layer B3)

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma_H \quad q \in F_{\text{oper}} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q_H' = \mathbf{Resolve}(q_H, \sigma_C, F_H) \quad \mathcal{R}_{\text{exec}}(S, t) = \text{ALLOW}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, q_H', \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-META-HUMAN}]
```

```math
\frac{\sigma_C \in \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \quad q \notin F_{\text{oper}} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS}}{\langle q, q_H, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, \mathbf{Resolve}(q_H, \sigma_C, F_H), \text{ApplyValidated}(S, t, \text{PASS}) \rangle} \quad [\text{SOS-HUMAN-SOVEREIGNTY-LOCKDOWN}]
```

#### 3.4.1 Meta-Regola SOS di Stasi in Stato Pausa (SOS-HUMAN-PAUSED-STUTTER / RFC-002)

Quando l'automa del percorso umano si trova nello stato:
```math
q_H = \text{HUMAN\_PAUSED}
```
e giunge un qualsiasi evento $t$ non corrispondente a `HEV_RESUME_REQUESTED`, `HEV_DECLINE_ALL` o `HEV_EMOTIONAL_OVERWHELM`, l'automa esegue uno stuttering step preservando lo stato di stasi ed emettendo una transazione recante l'involucro di esecuzione $e_{\text{paused}}$ :

```math
\frac{q_H = \text{HUMAN\_PAUSED} \quad \sigma_C \in \Sigma_H \setminus \{ \text{HEV\_RESUME\_REQUESTED}, \text{HEV\_DECLINE\_ALL}, \text{HEV\_EMOTIONAL\_OVERWHELM} \} \quad e_{\text{paused}} = \langle \text{"PROCESSED\_NO\_STATE\_EFFECT"}, \text{"HUMAN\_JOURNEY\_PAUSED"}, \text{false} \rangle}{\langle q, \text{HUMAN\_PAUSED}, S \rangle \xrightarrow{t}_{\text{Sys}} \langle q, \text{HUMAN\_PAUSED}, \text{ApplyValidated}(S, t[e \mapsto e_{\text{paused}}], \text{PASS}) \rangle} \quad [\text{SOS-HUMAN-PAUSED-STUTTER}]
```

#### 3.4.2 Meta-Regola SOS di Timeout ed Inattività Umana (SOS-HUMAN-TIMEOUT)

Quando l'automa umano si trova in:
```math
q_H = \text{HUMAN\_PAUSED}
```
ed il tempo di permanenza supera la soglia parametrizzata
```math
\theta_{\text{inactivity\_timeout}}
```

```math
\frac{q_H = \text{HUMAN\_PAUSED} \quad (E.t_{\text{wall}} - \pi_{\text{internal}}(S).t_{\text{pause\_start}}) > \theta_{\text{inactivity\_timeout}} \quad t_{\text{timeout}} = \text{BuildSystemTx}(S, E, \text{HEV\_RECALIBRATION\_REQ})}{\langle q, \text{HUMAN\_PAUSED}, S \rangle \xrightarrow{t_{\text{timeout}}}_{\text{Sys}} \langle q, \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{ApplyValidated}(S, t_{\text{timeout}}, \text{PASS}) \rangle} \quad [\text{SOS-HUMAN-TIMEOUT}]
```

#### 3.4.3 Meta-Regola SOS di Adattamento per Sopraffazione Emotiva (SOS-EMOTIONAL-OVERWHELM)

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
* $\Theta$: Lo spazio dei parametri di configurazione e soglie, es. 
```math
\theta_{\text{duration}}, \theta_{\text{confidence}}, \theta_{\text{max\_clock\_skew}}
```

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

#### 4.5.1 Regola di Non-Pregiudizio sul Rifiuto dei Suggerimenti (`RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01`)

```math
\forall S_1, S_2 \in \mathcal{S}, \ \text{se } S_2 = \text{ApplyValidated}(S_1, t, \text{PASS}) \text{ con } \text{event}(t) \in \{\text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL}\} \implies \text{Capabilities}(\text{Obs}(S_2)) = \text{Capabilities}(\text{Obs}(S_1))
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
5. **Rispetto del Consenso:** L'operatore `SHALL NOT` forzare l'esecuzione di azioni in violazione del consenso espresso dall'utente, salvo nei casi previsti dal livello HOBM `PROFESSIONAL_INTERVENTION_REQUIRED`.

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

Ogni componente versionabile di SCINTILLA Core appartiene allo spazio vettoriale discreto delle versioni $V := \mathbb{N} \times \mathbb{N} \times \mathbb{N}$ rappresentato dalla tupla $v = \langle \text{major}, \text{minor}, \text{patch} \rangle$.

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

### 7.1 SPAZIO NORMALIZZATO E CANONIZZAZIONE (Layer A)

Sia $\mathcal{S}_{\text{normalized}} \subseteq \mathcal{S}$ il sottoinsieme di stati conformi alle regole di normalizzazione del profilo di riferimento SC-JCS-1 (§10.2). 

La funzione di canonizzazione deterministica $\text{Canon} : \mathcal{S}_{\text{normalized}} \longrightarrow \mathcal{B}^*$ converte lo stato strutturato nella sua rappresentazione binaria unica. L'iniettività semantica di $\text{Canon}$ costituisce una proprietà obiettivo garantita dall'applicazione dell'algoritmo deterministico SC-JCS-1 (§10.3), assicurando che due stati semanticamente identici producano il medesimo flusso di byte UTF-8.

#### 7.1.1 Teorema di Totalità ed Univocità della Serializzazione (Layer A / RFC-010)

```math
\mathbf{THEOREM-SERIALIZATION-TOTALITY-AND-UNIQUENESS} := \forall t \in T, \ \text{EncodeTx}(t) \in J_{\text{SC}} \implies \exists! b \in \mathcal{B}^* \text{ t.c. } \text{Canon}(\text{EncodeTx}(t)) = b
```

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
\mathbf{REQ-CLUSTER-CLOCK-SYNC} := \max_{i,j} |t_{\text{wall}, i} - t_{\text{wall}, j}| \le \delta_{\text{clock}} \quad \text{con } \delta_{\text{clock}} < \frac{1}{2} \Theta.\theta_{\mathtt{max\_clock\_skew}}
```

4. **Delimitazione dell'Ambito di Infrastruttura Ex-Textu:** La presente specifica disciplina rigorosamente la consistenza logica (*Strict Linearizability*) ed i token di scherma monotonicamente crescenti per ogni `case_id`. Le strategie di deduplicazione di rete e di ripristino post-crash sono delegate ai profili infrastrutturali.

---

### 9.2 MODELLO DI TRANSIZIONE DI KRIPKE E LOGICA TEMPORALE (Layer A)

#### 9.2.1 Formalizzazione della Struttura di Kripke
La semantica temporale di SCINTILLA Core è descritta dalla Struttura di Kripke:

```math
M_K := \langle \mathcal{S}, s_0, \to_{\text{Sys}}, AP, L, F \rangle
```

- $\mathcal{S}$: Spazio degli Stati algebrico primario (§1.1.1).
- $s_0 \in \mathcal{S}$: Stato di Genesi (§1.3).
- $\to_{\text{Sys}} \subseteq \mathcal{S} \times \mathcal{S}$: Relazione di transizione generata dalla semantica operazionale SOS (§3).  
- $AP$: Insieme finito dei simboli di Proposizione Atomica Booleana.  
- $L: \mathcal{S} \to \mathcal{P}(AP)$: La Funzione di Etichettatura (Labeling Function).  
- $F \subseteq \mathcal{P}(\mathcal{S})$: Insieme dei vincoli di Fairness definita sulle tracce ammissibili.

---

#### 9.2.2 Mappatura della Labeling Function e Predicati sulle Transizioni

La mappa $L(S)$ determina l'appartenenza dei simboli in $AP$ mediante le proiezioni dello stato $S$ e la transazione candidata in valutazione contesto $t_{\text{prop}}$ , mentre i predicati di concorrenza e transizione sono formalizzati sulle coppie di stati adiacenti $(S_i, S_{i+1})$ :

1. **SafetyGateAllowed:** 
```math
\text{SafetyGateAllowed} \in L(S) \iff \mathcal{R}_{\text{exec}}(S, t_{\text{prop}}) = \text{ALLOW}
```

2. **DecisionOutcomeAllowed:** $\text{DecisionOutcomeAllowed} \in L(S) \iff \text{Derive}(\pi_{\text{persistent}}(S), \pi_{\text{internal}}(S)).\mathcal{O}_{\text{decision}} = \text{ALLOW}$.
3. **HashChainValid:** 
```math
\text{HashChainValid} \in L(S) \iff H(\text{Canon}(t_{\text{prev}})) = \pi_{\text{internal}}(S).\text{last\_hash}
```

4. **MonotonicFence (Predicato su Transizione):** 
```math
\text{MonotonicFence}(S_i, S_{i+1}) \iff \pi_{\text{internal}}(S_{i+1}).\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}} > \pi_{\text{internal}}(S_i).\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}}
```

5. **StateIsRecoverableFailure:** 
```math
\text{StateIsRecoverableFailure} \in L(S) \iff \pi_Q(S) = \text{RECOVERABLE\_FAILURE}
```

6. **StateIsSecurityLockdown:** 
```math
\text{StateIsSecurityLockdown} \in L(S) \iff \pi_Q(S) = \text{SECURITY\_LOCKDOWN}
```

7. **StateIsValidationError:** 
```math
\text{StateIsValidationError} \in L(S) \iff \pi_Q(S) = \text{VALIDATION\_ERROR}
```

8. **StateIsNormal:** $\text{StateIsNormal} \in L(S) \iff \pi_Q(S) = \text{NORMAL}$.
9. **StateIsReadOnly:** 
```math
\text{StateIsReadOnly} \in L(S) \iff \pi_Q(S) = \text{SAFE\_READ\_ONLY\_MODE}
```

10. **JourneyProgressive:** $\text{JourneyProgressive} \in L(S) \iff \pi_Q(S) \in F_{\text{oper}} \land \pi_{Q_H}(S) \in \{h_1, h_2, h_3, h_4, h_5, h_6, h_{11}\}$.
11. **KeyIsShredded:** 
```math
\text{KeyIsShredded}_c \in L(S) \iff \text{LookupKey}(K_c) = \bot
```

12. **UserEngaged:** 
```math
\text{UserEngaged} \in L(S) \iff \pi_{Q_H}(S) \notin \{h_7, h_{10}\}
```

13. **NonTerminalHumanState:** 
```math
\text{NonTerminalHumanState} \in L(S) \iff \pi_{Q_H}(S) \notin F_H
```

14. **HumanState:** 
```math
\text{HumanState}_{h_i} \in L(S) \iff \pi_{Q_H}(S) = h_i
```

15. **CryptoShredExecuted (RFC-005):**
```math
\text{CryptoShredExecuted}_c \in L(S) \iff t.\text{event} = \text{EV\_CRYPTO\_SHRED\_EXECUTED}(c)
```

#### 9.2.3 Formule Temporali First-Order LTL (FO-LTL)
La dinamica di sicurezza del modello è specificata dalle seguenti formule First-Order LTL:

* **FO-LTL Safety 1 (Safety Gate / Policy Guidance Corrected):**

```math
\square \left( \text{DecisionOutcomeAllowed} \implies \text{SafetyGateAllowed} \right)
```

* **FO-LTL Safety 2 (Fencing e Lease Recovery):**

```math
\square \left( \neg \text{MonotonicFence}(S_i, S_{i+1}) \implies X(\text{StateIsRecoverableFailure}) \right)
```

* **FO-LTL Safety 3 (Hash Chain Integrity):**

```math
\square \left( \neg \text{HashChainValid} \implies X(\text{StateIsSecurityLockdown}) \right)
```

* **FO-LTL Liveness 4 (Recuperabilità del Progresso dopo Errore Tecnico):**

```math
\square \left( (\text{StateIsValidationError} \lor \text{StateIsRecoverableFailure}) \implies \diamondsuit \text{JourneyProgressive} \right)
```

* **FO-LTL Safety 5 (Invarianza dell'Oblio Crittografico / RFC-005):**

```math
\forall c \in \mathcal{I}_{\text{case}}, \quad \square \left( \text{CryptoShredExecuted}_c \implies X(\square \text{KeyIsShredded}_c) \right)
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
