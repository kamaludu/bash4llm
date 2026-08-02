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
