[✴ SCINTILLA - SPECIFICA CANONICA IN LINGUAGGIO NATURALE](SPEC-SCI-TL--NATLANGv2026.1.md)

# ✴ SCINTILLA - CORE CANONICAL SPECIFICATION
## Standard Edition v4.3 Timeless

**Core Deterministico e Umano-Centrico per la Gestione di Percorsi di Emancipazione Personale**

* **Stato:** Specifica Normativa Canonica Formale (Single Source of Truth)
* **Edizione:** v4.3 Timeless Standard Edition (Human-Agency Centric, Epistemically Invariant & Formally Verified)
* **Autorità Governance:** Single Source of Truth Normativa per il dominio SCINTILLA CORE. Versionata secondo l'Algebra delle Versioni (§6).
* **Terminologia Normativa:** RFC 2119 / RFC 8174 (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`).

---

***Human Agency (Agentività Umana, Capacità di Agire Umana)***: La capacità intenzionale e concreta dell'individuo di esercitare il controllo causale sulle proprie azioni, decisioni e traiettorie di vita, supportata dalla consapevolezza della propria efficacia.

---

# PREAMBOLO E PRINCIPIO FONDAMENTALE DI GARANZIA

SCINTILLA CORE è un sistema operativo deterministico e umano-centrico per la gestione di **Percorsi di Emancipazione Personale** (es. uscita dall'instabilità abitativa, recupero documenti d'identità, autonomia finanziaria e lavorativa).

**Principio Assoluto dell'Architettura:**
SCINTILLA CORE non è un "automa che gestisce persone", ma un **automa di garanzia** che assicura che un assistente probabilistico (LLM al Livello 5) rimanga permanentemente subordinato all'autonomia, al consenso, all'ergonomia cognitiva e alla sovranità decisionale dell'utente fragile.

L'architettura separa in modo strutturale e non negoziabile:
1. **Ciò che il sistema GARANTISCE:** Integrità crittografica, tracciabilità immutabile del Ledger, sicurezza di runtime, rispetto del consenso, isolamento deterministico e trasparenza epistemica;
2. **Ciò che il sistema SUGGERISCE:** Passi operativi dei Playbook, raccomandazioni motivate e contestualizzate volte a ridurre il carico cognitivo dell'utente in stato di stress da trauma;
3. **Ciò che appartiene ESCLUSIVAMENTE all'Umano:** Scelte di vita, stato emotivo, vissuto personale, decisioni finali, revoca del consenso e ridefinizione degli obiettivi personali.

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE
## (Design Principles & Ethical Foundations)

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

Il dominio SCINTILLA CORE è strutturato ed ingegnerizzato attorno ad una singola missione di valore sociale ed etico: **aumentare la capacità concreta di una persona fragile o vulnerabile di trasformare una situazione di instabilità o crisi in un percorso strutturato di emancipazione e autonomia**.

#### 0.1.1 Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)
Ogni algoritmo, regola di policy, automa o trasformazione di stato all'interno del sistema `MUST` conformarsi incondizionatamente al seguente Invariante Supremo:

```math
\mathbf{INV-SUPREME-AGENCY-01}
```

> **"SCINTILLA CORE ha la missione di creare un automa di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e l'agency delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volontà e senza mai supportare azioni incompatibili con la dignità umana, la sicurezza ed i diritti altrui."**

#### 0.1.2 Formalizzazione del Concetto di Agency Responsabile
Il sistema definisce l'**Agency Umana** non come un mero esercizio di arbitrio o consumo di opzioni, bensì come **Agency Operativa Responsabile** ($\text{Agency}_{\text{resp}}$), formalizzata dalla tupla algebrica:

```math
\text{Agency}_{\text{resp}} := \langle \text{CapacitàDiAzione}, \text{ComprensioneContesto}, \text{ValutazioneAlternative}, \text{Pianificazione}, \text{Perseveranza}, \text{PercezioneDiControllo} \rangle
```

L'obiettivo dell'architettura è la massimizzazione dell'autodeterminazione della persona entro i confini inviolabili della sicurezza, della legalità e della tutela della dignità umana.

---

### 0.2 ASSIOMI DI NON-PATERNALISMO E AUTODETERMINAZIONE GUIDATA

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

#### 0.2.2 Riduzione del Carico Cognitivo senza Infantilizzazione
Il sistema `MUST` bilanciare l'autonomia dell'utente con l'ergonomia cognitiva. In presenza di stati di stress da trauma, sopraffazione emotiva o stanchezza decisionale (*decision fatigue*), l'omissione di indicazioni chiare può paralizzare l'azione dell'utente. 

Il sistema `SHALL` applicare la Tassonomia della Guida (§4.4), fornendo *Raccomandazioni Motivate e Contestualizzate* volte a ridurre il carico cognitivo, mantenendo sempre esplicita la natura non vincolante della raccomandazione e la piena facoltà di modifica o rifiuto da parte dell'utente (`USER_CONFIRMED_STEP`).

---

### 0.3 CONFINI ETICI DELL'AUTONOMIA E PROTEZIONE DEI DIRITTI

#### 0.3.1 Invariante dei Confini Etici dell'Assistenza (`INV-ETHICAL-BOUNDS-01`)
Il principio di supporto all'autodeterminazione dell'utente incontra un limite assoluto ed inderogabile nei diritti fondamentali altrui, nella legalità e nell'integrità fisica e psicologica della persona stessa.

```math
\forall t \in T, \quad \text{IsHarmfulOrIllegal}(t.\text{payload}) = \text{TRUE} \implies \mathcal{R}_{\text{exec}}(S, t) = \text{DENY}
```

Il sistema `SHALL NOT` generare, validare o eseguire transizioni volte a:
1. Arrecare danno intenzionale a sé o ad altre persone;
2. Sfruttare, manipolare o ingannare individui vulnerabili;
3. Organizzare, facilitare o perfezionare attività criminali o illecite;
4. Eludere controlli di legge o falsificare dichiarazioni e documenti ufficiali.

---

### 0.4 DISACCOPPIAMENTO TRA IDENTITÀ DELLA PERSONA E VALUTAZIONE DELLA RICHIESTA

#### 0.4.1 Invariante di Separazione Persona-Comportamento (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)
Il sistema `MUST` mantenere una distinzione formale assoluta tra l'**Identità dell'Attore Umano** ($\alpha \in \mathcal{I}_{\text{actor}}$) e la **Specifica Transazione / Richiesta** ($t \in T$).

```math
\text{EvaluateAccess}(\alpha, t) := \text{RespectUserDignity}(\alpha) \land \text{EvaluatePayloadSafety}(t.\text{payload})
```

1. **Inviolabilità della Dignità della Persona ($\alpha$):** L'utente, indipendentemente dai suoi trascorsi personali, legali, giudiziari o sociali, `SHALL` ricevere incondizionatamente il supporto del sistema per migliorare la propria condizione di vita, acquisire competenze, trovare un impiego, stabilizzare la propria dimora e reinserirsi nella società. L'identificatore $\alpha$ non `SHALL` mai essere oggetto di squalifica o stigmatizzazione morale.
2. **Valutazione Rigorosa della Richiesta ($t$):** La funzione di valutazione del Policy Engine $\mathcal{R}_{\text{exec}}(S, t)$ giudica unicamente la sicurezza, la legalità e la sostenibilità dello specifico payload della transazione $t$. Una richiesta volta a commettere un illecito `MUST` essere rifiutata (`DENY`), mentre una successiva richiesta della medesima persona volta a trovare un alloggio o un lavoro `MUST` essere accolta ed assistita con pari dedizione e neutralità.

---

### 0.5 PRINCIPI DI EMPOWERMENT, RESPONSABILIZZAZIONE E CRESCITA DELLE COMPETENZE

#### 0.5.1 Invariante di Riduzione della Dipendenza dal Sistema (`INV-EMPOWERMENT-01`)
Il successo di SCINTILLA CORE non è misurato dall'impiego continuativo o dalla permanenza dell'utente sulla piattaforma, bensì dal progressivo incremento dell'autonomia reale dell'utente e dalla conseguente riduzione della sua dipendenza dal sistema.

```math
\forall S_N, S_{N+k} \in \mathcal{S} \quad (k > 0), \quad \mathbb{E}[\text{DependencyReductionScore}(S_{N+k})] \ge \text{DependencyReductionScore}(S_N)
```

Il sistema `SHALL` strutturare ogni interazione come un'opportunità di apprendimento, alfabetizzazione burocratica/digitale e responsabilizzazione, trasferendo progressivamente all'utente la capacità di gestire in autonomia le proprie relazioni con le istituzioni ed il territorio.

---

### 0.6 STRATEGIA NORMATIVA ANTI-BIAS, NON-STIGMATIZZAZIONE E DIALOGO RELAZIONALE

#### 0.6.1 Invariante di Non-Stigmatizzazione e Neutralità Linguistica (`INV-NON-STIGMATIZATION-01`)
Il sistema `MUST` adottare nelle sue interazioni linguistiche (Livello 5 / SML v2.0) un linguaggio non giudicante, esente da stereotipi socio-culturali, paternalistici o pietistici.

1. **Rifiuto degli Stereotipi sulla Povertà:** Il sistema `SHALL NOT` formulare assunzioni preconcette sulle capacità cognitive, morali o lavorative dell'utente basate sulla sua condizione di fragilità abitativa o finanziaria.
2. **Diritto di Contestazione e Ri-taratura:** L'utente mantiene in qualsiasi momento il diritto esplicito ed inalienabile di contestare un suggerimento, rifiutare un micro-passo di un playbook o richiedere la riconfigurazione completa dei propri obiettivi attraverso l'evento (§2.3):
```math
\text{HEV\_RECALIBRATION\_REQ} \in \Sigma_H
```

#### 0.6.2 Valore del Dialogo e Confini delle Decisioni ad Alto Rischio
Il sistema riconosce che il valore primario dell'assistente probabilistico (LLM) risiede nella capacità di dialogo, spiegazione ed adattamento empatico del linguaggio. 

Tuttavia, in conformità con il Modello dei Confini di Supervisione Umana (HOBM, §1.8) e con la Doppia Autorità della Provenienza (§1.5), l'LLM `SHALL NOT` formulare interpretazioni legali vincolanti, perizie mediche o decisioni di assegnazione di sussidi pubblici in autonomia, delegando tali attività alle autorità umane competenti o a fonti ufficiali verificate.

---

# PARTE I: SPECIFICA NORMATIVA ASTRATTA (CORE ABSTRACT SPECIFICATION)

---

## 1. ALGEBRA ASTRATTA DEL MODELLO DI DOMINIO SCINTILLA

### 1.1 Formalizzazione dello Spazio degli Stati $\mathcal{S}$ e dello Spazio delle Transazioni $T$

#### 1.1.1 Spazio degli Stati $\mathcal{S}$
Lo Spazio degli Stati $\mathcal{S}$ è il prodotto cartesiano dei domini di stato fondamentali del sistema:
```math
\mathcal{S} \subseteq \mathcal{I}_{\text{case}} \times Q \times Q_H \times \mathcal{P}_{\text{active}} \times \mathcal{M}_{\text{prov}} \times \mathcal{F}_{\text{lease}} \times \mathcal{Q}_{\text{consent}} \times \mathcal{O}_{\text{decision}} \times \mathcal{K}_{\text{playbook}} \times \mathcal{A}_{\text{index}} \times \mathcal{H}_{\text{bound}} \times \mathcal{M}_{\text{metrics}}
```

Dove:
* $\mathcal{I}_{\text{case}} \subset \mathcal{I}$: Identificatore unico del caso utente.
* $Q$: Stato corrente della Runtime Safety State Machine (§2.2).
* $Q_H$: Stato corrente della Human Journey State Machine (§2.3).
* $\mathcal{P}_{\text{active}}$: Il bundle di policy attivo (§4.2).
* La mappa dello stato informativo arricchito con Data Provenance e Doppia Autorità (§1.5):
```math
\mathcal{M}_{\text{prov}}: \mathcal{K}_{\text{data}} \to D_P
```

* Lo stato del lock di concorrenza:
```math
\mathcal{F}_{\text{lease}} := \langle \text{fencing}_{\text{token}}, \text{lease}_{\text{expiry}} \rangle \in \mathbb{N} \times \mathcal{T}
```

* $\mathcal{Q}_{\text{consent}}$: Lo stato corrente del registro delle manifestazioni di consenso granulare dell'utente.
* $\mathcal{O}_{\text{decision}} \in \{ \text{ALLOW}, \text{DENY}, \text{RECALIBRATE}, \text{NONE} \}$: L'esito dell'ultima valutazione decisionale del Policy Guidance Engine.
* Lo stato dell'esecutore del Playbook (§5):
```math
\mathcal{K}_{\text{playbook}} := \langle \text{playbook}_{\text{id}}, \text{current}_{\text{node}_{\text{id}}}, \text{completed}_{\text{nodes}} \rangle \in (\mathcal{I} \cup \{\text{null}\}) \times (\mathcal{I} \cup \{\text{null}\}) \times \mathcal{P}(\mathcal{I})
```

* $\mathcal{A}_{\text{index}} \in [0.0, 1.0]$: Lo stato corrente dell'Indice di Guadagno di Agency ($\text{AGI}$, §1.7).
* Il livello corrente di supervisione secondo l'Human Oversight Boundary Model (HOBM, §1.8):
```math
\mathcal{H}_{\text{bound}} \in \{ \text{AUTOMATED\_SUPPORT}, \text{ASSISTED\_DECISION}, \text{HUMAN\_REVIEW\_REQUIRED}, \text{PROFESSIONAL\_INTERVENTION\_REQUIRED} \}
```

* I contatori per le metriche dinamiche dell'AGI (§1.7):
```math
\mathcal{M}_{\text{metrics}} := \langle \text{rephrase\_count}, \text{ambiguity\_count}, \text{interaction\_count} \rangle \in \mathbb{N}^3
```

#### 1.1.2 Assioma del Genesis State $s_0$
Lo stato iniziale di genesi $s_0 = P(\epsilon) \in \mathcal{S}$ `MUST` contenere tassativamente i seguenti valori predefiniti:
```math
s_0 := \left\langle \text{case}_{\text{id}}=\text{null}, \ q=\text{NORMAL}, \ q_H=\text{UNASSESSED}, \ \mathcal{P}_{\text{active}}=\mathcal{P}_{\text{default}}, \ \mathcal{M}_{\text{prov}}=\emptyset, \ \mathcal{F}_{\text{lease}}=\langle 0, t_0 \rangle, \ \mathcal{Q}_{\text{consent}}=\emptyset, \ \mathcal{O}_{\text{decision}}=\text{NONE}, \ \mathcal{K}_{\text{playbook}}=\langle \text{null}, \text{null}, \emptyset \rangle, \ \mathcal{A}_{\text{index}}=0.0, \ \mathcal{H}_{\text{bound}}=\text{AUTOMATED\_SUPPORT}, \ \mathcal{M}_{\text{metrics}}=\langle 0, 0, 0 \rangle \right\rangle
```

Dove $t_0 \in \mathcal{T}$ rappresenta l'istante temporale canonico di origine del sistema (§10.1).

#### 1.1.3 Spazio delle Transazioni $T$ e Corpo della Transazione Content-Addressed
Lo Spazio delle Transazioni $T$ è l'insieme di tutti i record di mutazione atomici ed immutabili commitabili nel sistema. Una transazione $t \in T$ è formalizzata come la tupla algebrica:

```math
t := \langle \text{TransactionBody}, \text{proof} \rangle
```

In conformità ai requisiti di riproducibilità e content-addressing (`OBI-002`), il corpo della transazione $\text{TransactionBody}$ racchiude esplicitamente tutte le dipendenze semantiche necessarie all'esecuzione deterministica:

```math
\text{TransactionBody} := \left\langle \text{tx}_{\text{id}}, \text{case}_{\text{id}}, \text{seq}_{\text{num}}, \text{prev}_{\text{hash}}, \text{timestamp}, \text{actor}, \text{event}, \text{payload}, \text{policy}_{\text{binding}_{\text{hash}}}, \text{schema}_{\text{hash}}, \text{authorization}_{\text{snapshot}_{\text{hash}}}, \text{runtime}_{\text{profile}_{\text{hash}}}, \text{specification}_{\text{id}} \right\rangle
```

* $\text{tx}_{\text{id}} \in \mathcal{I}$: Identificatore unico della transazione (UUIDv7).
* $\text{case}_{\text{id}} \in \mathcal{I}$: Identificatore del caso utente associato.
* $\text{seq}_{\text{num}} \in \mathbb{N}^+$: Numero di sequenza monotonico della transazione.
* Impronta crittografica della transazione precedente ($H_{N-1}$): $\text{prev}_{\text{hash}} \in \mathcal{D}$.
* $\text{timestamp} \in \mathcal{T}$: Istante temporale di generazione.
* $\text{actor} \in \mathcal{I}_{\text{actor}}$: Identificatore dell'attore mittente.
* $\text{event} \in \Sigma \cup \Sigma_H$: Evento di transizione dell'automa.
* $\text{payload} \in \mathcal{V}$: Contenuto informativo specifico della mutazione.
* Impronta content-addressed del predicato di policy attivo: 
```math
\text{policy}_{\text{binding}_{\text{hash}}} \in \mathcal{D}
```

* $\text{schema}_{\text{hash}} \in \mathcal{D}$: Impronta content-addressed dello schema dati applicativo.
* Impronta dello stato delle autorizzazioni dell'attore: 
```math
\text{authorization}_{\text{snapshot}_{\text{hash}}} \in \mathcal{D}
```

* Impronta della configurazione del profilo di runtime: 
```math
$\text{runtime}_{\text{profile}_{\text{hash}}} \in \mathcal{D}
```

* $\text{specification}_{\text{id}} \in \mathcal{I}$: Identificatore canonico dello standard (`SCINTILLA-CORE-v4.3-TIMELESS`).
* $\text{proof} \in \mathcal{S}_{\text{sig}}$: Firma digitale dell'attore calcolata su $\text{Canon}(\text{TransactionBody})$.

#### 1.1.3.1 Invariante di Oblio Crittografico e Audit Trail (`INV-PRIVACY-SHREDDING-01`)
Qualsiasi dato identificativo personale (PII) o sensibile contenuto nel campo `payload` $\mathcal{V}$ di una transazione $t \in T$ **`MUST NOT` essere memorizzato in chiaro nel Ledger immutabile**.

1. Il payload sensibile $v \in \mathcal{V}$ `MUST` essere memorizzato cifrato tramite una chiave derivata per singolo elemento
```math
K_{\text{item}} = \text{HKDF}(K_{\text{case}}, \text{item\_id})$, derivata dalla chiave radice effimera del caso utente $K_{\text{case}}
```

```math
\text{Payload}_{\text{encrypted}} = E_{K_{\text{item}}}(v)
```

L'oblio parziale di un singolo dato avviene mediante la distruzione della chiave specifica $K_{\text{item}}$. L'oblio totale del caso utente avviene mediante la distruzione irreversibile della chiave radice $K_{\text{case}}$ e del salt $S_{\text{case}}$.

2. Per impedire attacchi a forza bruta o Rainbow Tables sugli hash dei dati PII a bassa entropia presenti sul Ledger immutabile, l'impronta crittografica $H_{\text{salted}}$ `MUST` essere generata concatenando al dato un salt effimero casuale a 256 bit $S_{\text{case}} \in \mathcal{B}^{32}$ associato al caso utente:
```math
H_{\text{salted}}(v) = H(v \mathbin{\Vert} S_{\text{case}})
```
   Nel corpo della transazione viene registrata la tupla:
```math
$\langle \text{Payload}_{\text{encrypted}}, H_{\text{salted}}(v) \rangle
```

3. **Crypto-Shredding e Architettura KMS:** L'esercizio del diritto alla cancellazione dei dati/oblio da parte dell'utente `SHALL` essere eseguito mediante **Crypto-Shredding**, formalizzato come la distruzione irreversibile e atomica della tupla

```math
\langle K_{\text{case}}, S_{\text{case}} \rangle
```

gestita dal subsistema isolato di Livello 1 (`KMS_KeyStore`). 
   * La distruzione coordinata di

```math
\langle K_{\text{case}}, S_{\text{case}} \rangle
```

 rende il payload cifrato  

```math
\text{Payload}_{\text{encrypted}}
```

 irreversibilmente incomprensibile e l'hash $H_{\text{salted}}(v)$ matematicamente non verificabile a partire dal dato in chiaro, preservando intatta la catena di checksum $H_N$ del Ledger senza esporre PII.
   * Qualsiasi fallimento di comunicazione o indisponibilità del subsistema `KMS_KeyStore` durante le operazioni di cifratura o distruzione `MUST` interrompere la transazione e restituire il **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`)**.

4. **Regola di Registrazione dell'Evento di Oblio ($t_{\text{shred}}$):** L'atto di distruzione della chiave $K_{\text{case}}$ `MUST` generare ed appendere al Ledger una transazione formale di sistema $t_{\text{shred}} \in T$ recante l'evento `EV_CRYPTO_SHRED_EXECUTED`. Tale transazione certifica in modo immutabile l'istante temporale e la revoca del consenso che hanno determinato la distruzione irreversibile della chiave, senza esporre alcun dato PII.

#### 1.1.4 Invarianti Globali di Sicurezza e Integrità
Ogni stato $S \in \mathcal{S}$ e transazione $t \in T$ `MUST` soddisfare rigorosamente i seguenti invarianti sistemici:
1. **`INV-GLOBAL-SEQ-01` (Sequenza Monotona Stretta):**  
```math
\forall N > 1, \quad \text{seq}_N > \text{seq}_{N-1}
```
2. **`INV-GLOBAL-CASE-02` (Immutabilità Identificatore Caso):**  
```math
\forall N > 1, \quad \text{case}_{\text{id}_N} = \text{case}_{\text{id}_{N-1}} = \text{case}_{\text{id}_0}
```
3. **`INV-GLOBAL-POLICY-03` (Integrità Content-Addressed Binding):**  
```math
\forall N \ge 1, \quad H(\text{ExecutablePolicy}(\mathcal{P}_{\text{active}})) = \text{policy}_{\text{binding}_{\text{hash}_N}}
```

#### 1.1.5 Invarianti di Protezione dell'Agency Umana e Trasparenza
1. **`INV-HUMAN-AGENCY-01` (Supporto senza Sostituzione):**  
```math
\forall S \in \mathcal{S}, \quad \text{SystemAction}(S) \neq \text{UserDecision}(S)
```
   Il sistema `SHALL` supportare e strutturare il processo decisionale dell'utente, ma `SHALL NOT` sostituire le scelte autonome dell'utente con azioni automatizzate.
2. **`INV-TRANSPARENCY-01` (Classificazione Epistemica Rigorosa):**  
   Ogni elemento informativo $v \in \mathcal{V}$ nello stato $\mathcal{S}$ `MUST` essere classificato mediante la sua tupla di provenienza $D_P = \langle v, \kappa, \alpha, t, \phi, \psi, \omega \rangle$ (§1.5) come Fatto Verificato, Inferenza, Suggerimento o Dichiarazione Soggettiva.
3. **`INV-CONSENT-02` (Non-Escalation della Raccomandazione):**  
   Il sistema `SHALL NOT` trasformare una raccomandazione di guida o un micro-passo di un playbook in un obbligo operativo vincolante senza il consenso esplicito e revocabile dell'utente registrato in $\mathcal{Q}_{\text{consent}}$.

---

### 1.2 Spazio Ambientale $E$ e Separazione Pura: $\text{ValidateEnvironment}$ vs $\text{Apply}$ (`OBI-001`)

Per garantire sia il determinismo matematico assoluto della funzione di transizione di stato, sia la validazione rigorosa rispetto al contesto esecutivo esterno, il runtime separa formalmente la verifica d'ambiente dalla mutazione algebrica dello stato.

#### 1.2.1 Spazio Ambientale $E$
Lo Spazio Ambientale $E$ raccoglie i fattori di contesto fisici, temporali ed infrastrutturali non contenuti nello stato algebrico $S$:
```math
E := \langle t_{\text{wall}}, K_{\text{pubkey\_registry}}, \text{LeaseManager}, \text{I/O}_{\text{status}} \rangle
```

* $t_{\text{wall}} \in \mathcal{T}$: L'ora di sistema dell'ambiente esecutivo (Wall Clock).
* Il registro esterno delle chiavi pubbliche e dei certificati di revoca:
```math
K_{\text{pubkey\_registry}}
```

* $\text{LeaseManager}$: Il coordinatore infrastrutturale dei lock e dei token di recinzione.
* $\text{I/O}_{\text{status}}$: Lo stato di integrità dei canali di comunicazione fisica.

#### 1.2.2 Predicato di Validazione Ambientale $\text{ValidateEnvironment}$
Il predicato impuro di validazione d'ambiente $\text{ValidateEnvironment}: \mathcal{S} \times T \times E \to \{ \text{PASS}, \text{FAIL} \}$ valuta la transazione $t$ rispetto allo stato $S$ e all'ambiente $E$:
```math
\text{ValidateEnvironment}(S, t, E) = \begin{cases}
\text{PASS} & \text{se } \text{VerifySignature}(t.\text{proof}, t.\text{TransactionBody}, E.K_{\text{pubkey\_registry}}) = \text{TRUE} \\
& \quad \land \ |t.\text{timestamp} - E.t_{\text{wall}}| \le \Delta t_{\text{max}} \\
& \quad \land \ E.\text{LeaseManager}.\text{IsTokenValid}(S.\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}}) = \text{TRUE} \\
& \quad \land \ E.\text{I/O}_{\text{status}} = \text{HEALTHY} \\
\text{FAIL} & \text{in qualsiasi altro caso}
\end{cases}
```

---

### 1.3 Il Ledger come Monoide Libero $\mathcal{L}$ e Content-Addressing delle Dipendenze (`OBI-002`)
Il registro immutabile delle decisioni (Ledger) è formalizzato come un Monoide Libero $\mathcal{L} := \langle T^*, \mathbin{\Vert}, \epsilon \rangle$:
* $T^*$: L'insieme di tutti i record di mutazione immutabili.
* $\mathbin{\Vert}$: L'operazione binaria di concatenazione associativa di transazioni (Append-Only).
* $\epsilon$: La sequenza vuota (elemento neutro del monoide).

**Assioma di Immutabilità Algebrica del Ledger:**  
```math
\forall L_1, L_2 \in \mathcal{L}, \quad (L_1 \mathbin{\Vert} L_2 = L_3 \land L_2 \neq \epsilon) \implies L_1 \text{ è un prefisso stretto ed inalterabile di } L_3
```

---

### 1.4 La Funzione di Proiezione dello Stato $P: \mathcal{L} \to \mathcal{S}$ e la Persistence dei Security Events

La relazione tra la storia immutabile delle transazioni $L \in \mathcal{L}$ e lo stato proiettato corrente $S \in \mathcal{S}$ è governata dalla funzione pura $P$:

```math
P(\epsilon) = s_0 \quad (\text{Stato Iniziale di Genesi})
```
```math
P(L \mathbin{\Vert} \langle t \rangle) = \text{Apply}(P(L), t)
```

Dove $\text{Apply}: (\mathcal{S} \cup \{\bot\}) \times T \to \mathcal{S} \cup \{\bot\}$ è la **funzione pura e deterministica** di transizione di stato, priva di accessi all'ambiente $E$.

#### 1.4.1 Assiomi Formali della Funzione Pura $\text{Apply}$
1. **Determinismo Assoluto:**  
```math
\forall S \in \mathcal{S}, \forall t \in T, \quad \text{Apply}(S, t) = S' \land \text{Apply}(S, t) = S'' \implies S' = S''
```
2. **Purezza Matematica:** La valutazione di $\text{Apply}(S, t)$ non effettua I/O, non consulta il clock di sistema e non altera riferimenti in memoria esterni.
3. **Preservazione degli Invarianti:**  
```math
\forall I \in \{\text{INV-GLOBAL-SEQ-01}, \dots, \text{INV-HUMAN-DEPENDENCY-01}\}, \quad (I(S) \land \text{Valid}(t)) \implies I(\text{Apply}(S, t))
```

#### 1.4.2 Persistenza Esaustiva dei Security ed Error Events e Risoluzione dell'Integrità del Replay

Quando un tentativo di transizione $t_{\text{prop}}$ viene inviato al sistema e la validazione fallisce ($\text{ValidateEnvironment}(P(L), t_{\text{prop}}, E) = \text{FAIL} \lor \text{EvaluateGuards}(P(L), t_{\text{prop}}) = \text{FAIL}$):
1. La proposta non valida $t_{\text{prop}}$ viene scartata senza mutare il caso utente.
2. Per gli errori di validazione non causati da corruzione strutturale del supporto di memorizzazione, il runtime `MUST` generare ed appendere immediatamente al Ledger una transizione formale di sistema $t_{\text{err}} \in T$:
```math
t_{\text{err}} = \left\langle \text{TransactionBody}(\text{actor}=\text{SYSTEM}, \text{event}=\sigma_{\text{err}}, \text{payload}=\text{ErrorContext}), \ \text{proof}_{\text{sys}} \right\rangle
```
   recante l'evento corrispondente: 
```math
\sigma_{\text{err}} \in \{\text{EV\_SML\_FAIL}, \text{EV\_LEASE\_EXP}, \text{EV\_TIMEOUT}\}
```
   **Eccezione per Corruzione del Ledger 
```math
\text{EV\_HASH\_CORRUPT}
```
** Qualora il fallimento sia causato dalla corruzione fisica o manomissione della catena di hash sul Ledger, la transizione $t_{\text{err}}$ `MUST NOT` essere appesa alla catena invalida, bensì registrata in uno storage diagnostico sidecar non volatile, provocando l'immediata transizione dello stato di sicurezza a 
```math
q = \text{SECURITY\_LOCKDOWN}
```

3. Per gli errori standard, la concatenazione di $t_{\text{err}}$ al Ledger:
```math
L' = L \mathbin{\Vert} \langle t_{\text{err}} \rangle
```

assicura che la valutazione pura di $\text{Apply}(P(L), t_{\text{err}})$ produca deterministicamente lo stato proiettato di errore:
```math
q \in \{\text{VALIDATION\_ERROR}, \text{RECOVERABLE\_FAILURE}\}
```

**Teorema della Totalità del Replay Deterministico:**
```math
\forall L \in \mathcal{L}, \quad P(L) = \text{Replay}(L) \neq \bot
```

In virtù di questa regola, **ogni mutazione dello stato di runtime corrisponde ad una transizione immutabile presente nel Ledger** (o nel registro diagnostico sidecar in caso di corruzione del supporto), garantendo l'uguaglianza assoluta tra proiezione e riesecuzione.

---

### 1.5 Tassonomia Dati e Doppia Autorità della Provenienza ($\mathcal{K}_{\text{prov}}$, `OBI-007`)

Ogni elemento informativo $v \in \mathcal{V}$ contenuto nello stato $S \in \mathcal{S}$ `MUST` essere incapsulato nella tupla di provenienza del dato $D_P$:

```math
D_P := \langle v, \kappa, \alpha, t, \phi, \psi, \omega \rangle
```

* $v \in \mathcal{V}$: Il valore informativo.
* 
```math
\kappa \in \mathcal{K}_{\text{prov}} 
```
Categoria di provenienza: 
```math
\mathcal{K}_{\text{prov}} = \mathcal{K}_{\text{epistemic}} \cup \mathcal{K}_{\text{personal}}
```

* $\alpha \in \mathcal{I}_{\text{actor}}$: Identificatore dell'attore asseritore.
* $t \in \mathcal{T}$: Istante temporale di asserzione.
* $\phi \in [0.0, 1.0]$: Punteggio numerico di confidenza.
* $\psi \in \{ \text{UNVERIFIED}, \text{PENDING}, \text{VERIFIED}, \text{REJECTED} \}$: Stato di verifica oggettiva.
* Dominio dell'asserzione:
```math
\omega \in \{ \text{FACTUAL\_ADMINISTRATIVE}, \text{SUBJECTIVE\_EMOTIONAL}, \text{PERSONAL\_GOAL}, \text{TECHNICAL\_SYSTEM} \}
```

#### 1.5.1 Modello di Doppia Autorità (Dual Authority Model)
In conformità a `OBI-007`, l'ordine di autorità informativa varia in base al dominio dell'asserzione $\omega$:

1. **Dominio dei Fatti Amministrativi e Legali:**
```math
\omega = \text{FACTUAL\_ADMINISTRATIVE}
```

```math
\text{LLM\_INFERENCE} \prec \text{USER\_DECLARATION} \prec \text{EXTERNAL\_SOURCE} \prec \text{OPERATOR\_CONFIRMED} \prec \text{SYSTEM\_VERIFIED}
```
   *(Esempio: La verifica del possesso di un documento d'identità vede la fonte esterna o verificata prevalere sulla dichiarazione).*

2. **Dominio Soggettivo, Emotivo e degli Obiettivi Personali:
```math
\omega \in \{ \text{SUBJECTIVE\_EMOTIONAL}, \text{PERSONAL\_GOAL} \}
```

```math
\text{LLM\_INFERENCE} \prec \text{EXTERNAL\_SOURCE} \prec \text{SYSTEM\_VERIFIED} \prec \text{OPERATOR\_CONFIRMED} \prec \text{USER\_DECLARATION}
```
   *(Esempio: La percezione di sicurezza o la scelta dei propri obiettivi vede la dichiarazione dell'utente come autorità suprema ed inoppugnabile).*

---

### 1.6 Modello di Minaccia Formale, Confini di Fiducia e Modello di Rischio Psicologico $R_{\text{human}}$ (`OBI-004`)

#### 1.6.1 Modello dell'Avversario ($\mathcal{A}$)
Il sistema formalizza la propria sicurezza rispetto ad un avversario razionale $\mathcal{A}$ in grado di iniettare prompt malevoli nel Livello 5 (LLM), inviare transizioni non autorizzate, tentare attacchi di replay o manipolare fonti esterne. $\mathcal{A}$ `SHALL NOT` invertire primitive crittografiche (SHA-256, Ed25519) né alterare il Ledger $L$.

#### 1.6.2 Modello di Rischio Psicologico $R_{\text{human}}$ e Invarianti di Protezione
Al fine di tutelare gli utenti in condizioni di fragilità psicologica, sociale o cognitiva, il sistema integra nel dominio di sicurezza il modello di rischio antropomorfico e psicologico $R_{\text{human}}$, governato da due invarianti vincolanti:

1. **`INV-HUMAN-DEPENDENCY-01` (Divieto di Simulata Affettività e Parasocialità):**  
   Il sistema `SHALL NOT` utilizzare formule linguistiche, toni espressivi o comportamenti simulati volti a instaurare relazioni affettive, amicali, romantiche o sostitutive della rete sociale ed umana dell'utente. Il sistema `MUST` mantenere un tono professionale, empatico ma chiaramente artificiale.
2. **`INV-AUTHORITY-DISCLOSURE-01` (Trasparenza Obbligatoria dell'Incertezza Probabilistica):**  
   Ogni output generato dal Livello 5 (LLM) `MUST` contenere la dichiarazione esplicita della propria natura probabilistica. Il sistema `SHALL NOT` presentare inferenze dell'LLM come verità assolute o prescrizioni legali inappellabili.

---

### 1.7 Indice di Guadagno di Agency ($\text{AGI}$) con Principio di Invarianza Epistemica

L'**Indice di Guadagno di Agency** ($\text{AGI} \in [0.0, 1.0]$) misura l'efficacia del sistema nell'aumentare la capacità operativa dell'utente. 

#### 1.7.1 Assioma di Invarianza Epistemica per Stati Non-Attivi (`AXIOM-AGI-INVARIANCE`)
Quando l'utente sospende il percorso:
```math
h_7 = \text{HUMAN\_PAUSED}
```
 o esercita la facoltà di rifiutare l'assistenza:
```math
h_{10} = \text{HUMAN\_DECLINED\_ASSISTANCE}
```
il sistema perde la capacità di osservazione dinamica dell'utente. Per evitare sia penalizzazioni ingiuste ($\text{AGI} \to 0.0$) sia false attestazioni di successo ($\text{AGI} := 1.0$), il sistema `MUST` congelare il valore dell'indice al valore calcolato nell'ultimo stato attivo misurato:

```math
\forall S_N \in \mathcal{S}, \quad \text{AGI}(S_N) := \begin{cases}
\text{AGI}(S_{N-1}) & \text{se } q_H(S_N) \in \{ \text{HUMAN\_PAUSED}, \text{HUMAN\_DECLINED\_ASSISTANCE} \} \\
\text{AGI}_{\text{computed}}(S_N) & \text{se } q_H(S_N) \notin \{ \text{HUMAN\_PAUSED}, \text{HUMAN\_DECLINED\_ASSISTANCE} \}
\end{cases}
```

#### 1.7.2 Calcolo Dinamico dell'AGI negli Stati Attivi ($\text{AGI}_{\text{computed}}$)
Per tutti gli stati attivi ($q_H \notin \{h_7, h_{10}\}$), la funzione di valutazione dinamica è formalizzata come:

```math
\text{AGI}_{\text{computed}}(S) := w_1(q_H) \cdot \text{ClarityScore}(S) + w_2(q_H) \cdot \text{ActionExecutionRatio}(S) + w_3(q_H) \cdot \text{DependencyReductionScore}(S)
```

Con il vincolo di normalizzazione del vettore dei pesi:
```math
\forall q_H \in Q_H \setminus \{h_7, h_{10}\}, \quad w_1(q_H) + w_2(q_H) + w_3(q_H) = 1.0
```

#### Mappatura Normativa del Vettore dei Pesi $\mathbf{w}(q_H)$:
```math
\mathbf{w}(q_H) := \begin{cases}
\langle 0.60, \ 0.30, \ 0.10 \rangle & \text{se } q_H \in \{ \text{UNASSESSED}, \text{INITIAL\_ASSESSMENT}, \text{STABILIZATION} \} \\
\langle 0.30, \ 0.50, \ 0.20 \rangle & \text{se } q_H \in \{ \text{DOCUMENT\_RECOVERY}, \text{EMPLOYMENT\_READINESS} \} \\
\langle 0.20, \ 0.30, \ 0.50 \rangle & \text{se } q_H \in \{ \text{FINANCIAL\_AUTONOMY}, \text{SUSTAINED\_INDEPENDENCE} \} \\
\langle 0.40, \ 0.20, \ 0.40 \rangle & \text{se } q_H \in \{ \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{HUMAN\_GOAL\_CHANGED} \} \\
\text{FROZEN} & \text{se } q_H \in \{ \text{HUMAN\_PAUSED}, \text{HUMAN\_DECLINED\_ASSISTANCE} \} \quad (\text{Mantenimento } \text{AGI}_{N-1})
\end{cases}
```

* Assioma di Calibrazione di Genesi: $\text{AGI}(s_0) = 0.0$.

---

### 1.8 Modello dei Confini di Supervisione Umana (HOBM) (`OBI-011`)

Per definire in modo rigoroso le responsabilità operative ed etiche, ogni transazione e stato di avanzamento è categorizzato all'interno dell'**Human Oversight Boundary Model (HOBM)**:

1. **`AUTOMATED_SUPPORT`:** Supporto informativo e riorganizzazione del carico cognitivo per micro-azioni a basso rischio (es. consultazione orari, preparazione bozza documenti).
2. **`ASSISTED_DECISION`:** Formulazione di raccomandazioni motivate e contestualizzate (§4.4) prive di impatti legali irreversibili, richiedenti conferma esplicita dell'utente (`USER_CONFIRMED_STEP`).
3. **`HUMAN_REVIEW_REQUIRED`:** Azioni aventi impatto formale, legale o finanziario che richiedono la revisione e controfirma di un operatore umano autorizzato (`OPERATOR`).
4. **`PROFESSIONAL_INTERVENTION_REQUIRED`:** Rilevazione di situazioni di crisi acuta, rischio per la sicurezza personale o trauma grave che impongono il blocco automatizzato del sistema e l'ingaggio immediato dei servizi sociali/professionali territoriali.

---

## 2. ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI FORMALE

### 2.1 Modello di Isolamento Stratificato a 6 Livelli

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

### 2.2 Runtime Safety State Machine $M$ (Sicurezza e Integrità di Sistema)
L'operatività di sicurezza di runtime è modellata come un Automa a Stati Finiti Deterministico Totale $M$:
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
   
4. **Alfabeto degli Eventi di Sistema $\Sigma$ ($|\Sigma|=8$):**
```math
\Sigma = \{ \text{EV\_SUCCESS } (\sigma_0), \text{EV\_ABANDON } (\sigma_1), \text{EV\_SML\_FAIL } (\sigma_2), \text{EV\_LEASE\_EXP } (\sigma_3), \text{EV\_HASH\_CORRUPT } (\sigma_4), \text{EV\_TIMEOUT } (\sigma_5), \text{EV\_OVERRIDE } (\sigma_6), \text{EV\_REPAIR } (\sigma_7) \}
```

#### 2.2.1 Mappatura Formale della Funzione Totale di Transizione $\delta_M$ e Portabilità dei Dati
La funzione pura di transizione: 
```math
$\delta_M: Q \times \Sigma \times \mathcal{T}_{\text{JSON}} \to Q
```
è derivata in modo deterministico dal contratto canonico JSON $T_{\text{JSON}}$ (§10.3) mediante la funzione normativamente definita $\text{firstMatch}$:
```math
\delta_M(q, \sigma, T_{\text{JSON}}) := \text{firstMatch}(T_{\text{JSON}}, q, \sigma)
```

#### 2.2.1.1 Operatore di Risoluzione Deterministica $\text{firstMatch}$ e Precedenza Wildcard
La funzione deterministica $\text{firstMatch}(T_{\text{JSON}}, q, \sigma)$ valuta l'insieme delle regole di transizione definite nel contratto JSON $T_{\text{JSON}}$ applicando la seguente **Gerarchia di Precedenza Assoluta**:

```math
\text{firstMatch}(T_{\text{JSON}}, q, \sigma) := \begin{cases}
q_{\text{target}} & \text{se } \exists \ r \in T_{\text{JSON}} \text{ t.c. } r.\text{from} = q \land r.\text{event} = \sigma \quad (\text{Exact Match}) \\
q_{\text{wildcard}} & \text{se } \nexists \ \text{Exact Match} \land \exists \ r \in T_{\text{JSON}} \text{ t.c. } r.\text{from} = q \land r.\text{event} = \text{"*"} \quad (\text{Wildcard Match}) \\
q & \text{se } \nexists \ \text{Match} \quad (\text{Stuttering Step Default})
\end{cases}
```

**Regola di Invarianza dal Parsing:** L'esito della valutazione di $\text{firstMatch}$ `MUST` dipendere unicamente dalla gerarchia matematica sopra definita e `MUST NOT` essere influenzato dall'ordine strutturale di elencazione delle righe all'interno del file JSON.

**Invariante di Portabilità in Read-Only (`INV-READONLY-PORTABILITY-01`):**

Quando l'automa $M$ si trova nello stato:
```math
q_6 = \text{SAFE\_READ\_ONLY\_MODE}
```

il runtime `MUST` mantenere attiva ed accessibile la funzione di sola lettura dello stato proiettato $P(L)$, garantendo all'utente la facoltà inalienabile di consultare ed esportare l'intera storia del proprio percorso personale e dei dati visibili non cifrati.

---

### 2.3 Human Journey State Machine $\mathcal{H}$ (Percorso di Emancipazione Personale) (`OBI-009`)

L'evoluzione del percorso umano dell'utente è modellata da un automa di dominio autonomo $\mathcal{H}$, esteso per includere formalmente gli stati di pausa, ripensamento e scelta autonoma dell'utente:
```math
\mathcal{H} := \langle Q_H, \Sigma_H, \delta_H, q_{H0}, F_H \rangle
```
   
1. **Insieme degli Stati del Percorso Umano $Q_H$ ($|Q_H|=11$):**
```math
Q_H = \{ \text{UNASSESSED } (h_0), \text{INITIAL\_ASSESSMENT } (h_1), \text{STABILIZATION } (h_2), \text{DOCUMENT\_RECOVERY } (h_3), \text{EMPLOYMENT\_READINESS } (h_4), \text{FINANCIAL\_AUTONOMY } (h_5), \text{SUSTAINED\_INDEPENDENCE } (h_6), \text{HUMAN\_PAUSED } (h_7), \text{HUMAN\_RECALIBRATION\_REQUIRED } (h_8), \text{HUMAN\_GOAL\_CHANGED } (h_9), \text{HUMAN\_DECLINED\_ASSISTANCE } (h_{10}) \}
```

2. **Stato Iniziale:** $q_{H0} = \text{UNASSESSED}$.
3. **Insieme degli Stati Target / Terminali $F_H$:** 
```math
F_H = \{ \text{SUSTAINED\_INDEPENDENCE}, \text{HUMAN\_DECLINED\_ASSISTANCE} \}
```
   
4. **Alfabeto degli Eventi Umani $\Sigma_H$ ($|\Sigma_H|=13$):**
```math
\Sigma_H = \{ \text{HEV\_ASSESS\_START}, \text{HEV\_STABILIZED}, \text{HEV\_DOCS\_OBTAINED}, \text{HEV\_JOB\_READY}, \text{HEV\_FINANCE\_OK}, \text{HEV\_INDEPENDENCE\_ACHIEVED}, \text{HEV\_RELAPSE\_REGRESS}, \text{HEV\_RECALIBRATION\_REQ}, \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_RESUME\_REQUESTED}, \text{HEV\_GOAL\_UPDATE}, \text{HEV\_DECLINE\_ALL}, \text{HEV\_EMOTIONAL\_OVERWHELM} \}
```

#### 2.3.1 Assioma di Chiusura per Stazionarietà (Stuttering Step Axiom)
La funzione di transizione $\delta_H: Q_H \times \Sigma_H \to Q_H$ è una **funzione totale**. Per qualsiasi coppia $(q_H, \sigma_H) \in Q_H \times \Sigma_H$ non mappata esplicitamente, vale la regola di chiusura:
```math
\forall (q_H, \sigma_H) \notin \text{Domain}(\delta_{H,\text{explicit}}), \quad \delta_H(q_H, \sigma_H) = q_H
```

#### 2.3.2 Regola di Timeout ed Inattività Umana
Quando l'automa del percorso umano $\mathcal{H}$ si trova nello stato:
```math
h_7 = \text{HUMAN\_PAUSED}
```
il tempo di permanenza nello stato è monitorato rispetto al parametro di policy:
```math
\theta_{\text{inactivity\_timeout}} \in \Theta
```
   
Se la durata della pausa supera la soglia consentita:
```math
(t_{\text{wall}} - t_{\text{pause\_start}}) > \theta_{\text{inactivity\_timeout}}
```
   
Il runtime genera automaticamente l'evento di sistema:
```math
\sigma_H = \text{HEV\_RECALIBRATION\_REQ}
```
determinando la transizione di stato:
```math
\delta_H(\text{HUMAN\_PAUSED}, \text{HEV\_RECALIBRATION\_REQ}) = \text{HUMAN\_RECALIBRATION\_REQUIRED}
```

#### 2.3.3 Regola di Adattamento per Sopraffazione Emotiva (Adaptive Overwhelm Rule)
Se l'input del Livello 5 (SML v2.0) riporta l'esito conversazionale `CONVERSATION_OUTCOME: OVERWHELMED`, il runtime `MUST` generare l'evento
```math
\text{HEV\_EMOTIONAL\_OVERWHELM} \in \Sigma_H
```

La ricezione di tale evento impone la transizione di stato:
```math
\delta_H(q_H, \text{HEV\_EMOTIONAL\_OVERWHELM}) = \text{HUMAN\_RECALIBRATION\_REQUIRED}
```
e forza il Playbook Engine (§5) ad isolare e presentare all'utente un **singolo ed esclusivo micro-passo di emergenza/stabilizzazione**, sospendendo la visualizzazione della mappa di avanzamento complessa.

---

### 2.4 Equazione Matematica del Sistema Reattivo Composito $S_C = Q \times Q_H$

Il sistema reattivo globale di Scintilla Core è modellato dallo spazio di stato composito $S_C = Q \times Q_H$. La funzione di transizione strutturale pura dell'automa composito $\delta_C: (Q \times Q_H) \times (\Sigma \cup \Sigma_H) \to (Q \times Q_H)$ è definita dall'equazione a casi:
```math
\delta_C((q, q_H), \sigma_C) = \begin{cases} 
(\delta_M(q, \sigma_C, T_{\text{JSON}}), q_H) & \text{se } \sigma_C \in \Sigma \\
(q, \delta_H(q_H, \sigma_C)) & \text{se } \sigma_C \in \Sigma_H \land q \in F_{\text{oper}} \\
(q, \delta_H(q_H, \sigma_C)) & \text{se } \sigma_C \in \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \land q \notin F_{\text{oper}} \quad (\text{Human Sovereignty Exception}) \\
(q, q_H) & \text{se } \sigma_C \in \Sigma_H \setminus \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \land q \notin F_{\text{oper}} \quad (\text{Lockdown Freeze Axiom})
\end{cases}
```
   
1. **`INV-DECOUPLING-01` (Disaccoppiamento Unidirezionale):** L'automa del percorso umano $\mathcal{H}$ genera unicamente ipotetiche transizioni di guida. L'automa $\mathcal{H}$ **`SHALL NOT` possedere alcuna autorità diretta di mutazione sullo stato del Runtime Safety State Machine $M$**.
2. **Eccezione di Sovranità Umana in Lockdown:** Se lo stato del runtime $q \notin F_{\text{oper}}$, le sole transizioni dell'automa umano ammesse per la registrazione immediata nel Ledger sono quelle di revoca del consenso o sospensione (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

## 3. SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)

La dinamica globale del sistema Scintilla Core è formalizzata mediante lo schema di Meta-Regole di **Small-Step Structural Operational Semantics (SOS)** definita sulla configurazione generica $\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q', q_H', S' \rangle$.

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore
Un evento $\sigma_C \in \Sigma \cup \Sigma_H$ contenuto in una transizione $t \in T$ emessa dall'attore $\alpha = \text{actor}(t)$ è valido se e solo se la coppia $(\sigma_C, \text{type}(\alpha))$ appartiene alla seguente matrice di autorizzazione:
```math
\text{Authorized}(\sigma_C, \text{type}(\alpha)) \iff \begin{cases}
\text{True} & \text{se } \sigma_C \in \Sigma_H \land \text{type}(\alpha) \in \{\text{USER}, \text{OPERATOR}, \text{SYSTEM}\} \\
\text{True} & \text{se } \sigma_C \in \{\sigma_0, \sigma_1, \sigma_2, \sigma_3, \sigma_4, \sigma_5\} \land \text{type}(\alpha) = \text{SYSTEM} \\
\text{True} & \text{se } \sigma_C \in \{\text{EV\_OVERRIDE}, \text{EV\_REPAIR}\} \land \text{type}(\alpha) = \text{OPERATOR} \\
\text{False} & \text{in tutti gli altri casi (compreso qualsiasi tentativo con } \text{type}(\alpha) = \text{LLM})
\end{cases}
```

---

### 3.2 Mappatura Normativa delle Guardie ($\text{EvaluateGuards}$)
La funzione pura di valutazione $\text{EvaluateGuards}: \mathcal{S} \times T \to \{ \text{PASS}, \text{FAIL} \}$ valuta la transizione $t$ rispetto allo stato $S$:
```math
\text{EvaluateGuards}(S, t) = \begin{cases}
\text{PASS} & \text{se } \sigma_C = \text{EV\_SUCCESS} \land \text{IsHashChainValid}(S) \land \text{IsMonotonicFence}(S) \land \text{ValidLease}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_ABANDON} \land \text{IsHashChainValid}(S) \land \text{ValidLease}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_SML\_FAIL} \land \text{IsHashChainValid}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_LEASE\_EXP} \land (\neg \text{ValidLease}(S) \lor \neg \text{IsMonotonicFence}(S)) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_HASH\_CORRUPT} \land \neg \text{IsHashChainValid}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_TIMEOUT} \land \text{IsTimeoutExpired}(S) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_OVERRIDE} \land \text{AuthenticatedOperator}(\alpha) \land \text{ValidProof}(p) \\
\text{PASS} & \text{se } \sigma_C = \text{EV\_REPAIR} \land \text{AuthenticatedOperator}(\alpha) \land \text{ValidRepairPatch}(p) \\
\text{FAIL} & \text{in qualsiasi altro caso}
\end{cases}
```

---

### 3.3 Meta-Regole SOS della Sicurezza di Runtime ($M$)
```math
\frac{\sigma_C = \text{event}(t) \in \Sigma \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q' = \delta_M(q, \sigma_C, T_{\text{JSON}}) \quad \text{EvaluateGuards}(S, t) = \text{PASS}}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q', q_H, \text{Apply}(S, t) \rangle} \quad [\text{SOS-META-SAFETY}]
```

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma \quad (\text{ValidateEnvironment}(S, t, E) = \text{FAIL} \lor \neg \text{Authorized}(\sigma_C, \text{type}(\alpha)) \lor \text{EvaluateGuards}(S, t) = \text{FAIL}) \quad t_{\text{err}} = \text{BuildErrorTx}(\sigma_C)}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle \text{VALIDATION\_ERROR}, q_H, \text{Apply}(S, t_{\text{err}}) \rangle} \quad [\text{SOS-META-SAFETY-FAIL}]
```

---

### 3.4 Meta-Regole SOS del Percorso Umano ($\mathcal{H}$)
```math
\frac{\sigma_C = \text{event}(t) \in \Sigma_H \quad q \in F_{\text{oper}} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS} \quad \text{Authorized}(\sigma_C, \text{type}(\alpha)) \quad q_H' = \delta_H(q_H, \sigma_C) \quad \mathcal{R}_{\text{exec}}(S, t) = \text{ALLOW}}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q, q_H', \text{Apply}(S, t) \rangle} \quad [\text{SOS-META-HUMAN}]
```

```math
\frac{\sigma_C = \text{event}(t) \in \Sigma_H \quad q \in F_{\text{oper}} \quad (\neg \text{Authorized}(\sigma_C, \text{type}(\alpha)) \lor \mathcal{R}_{\text{exec}}(S, t) \in \{\text{DENY}, \text{RECALIBRATE}\})}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q, \delta_H(q_H, \text{HEV\_RECALIBRATION\_REQ}), S \rangle} \quad [\text{SOS-META-HUMAN-DENY}]
```

```math
\frac{q_H = \text{HUMAN\_PAUSED} \quad (t_{\text{wall}} - t_{\text{pause\_start}}) > \theta_{\text{inactivity\_timeout}} \quad \sigma_H = \text{HEV\_RECALIBRATION\_REQ}}{\langle q, \text{HUMAN\_PAUSED}, \sigma_H, S, E \rangle \to_{\text{Sys}} \langle q, \text{HUMAN\_RECALIBRATION\_REQUIRED}, \text{Apply}(S, t_{\text{timeout}}) \rangle} \quad [\text{SOS-HUMAN-TIMEOUT}]
```

Dove $t_{\text{timeout}} \in T$ è la transizione formale di sistema definita esplicitamente da:
```math
t_{\text{timeout}} := \left\langle \text{TransactionBody}(\text{actor}=\text{SYSTEM}, \text{event}=\text{HEV\_RECALIBRATION\_REQ}), \ \text{proof}_{\text{sys}} \right\rangle
```

---

### 3.5 Meta-Regola SOS di Sovranità Umana in Lockdown (Human Sovereignty Override)
```math
\frac{\sigma_C \in \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \quad q \notin F_{\text{oper}} \quad \text{ValidateEnvironment}(S, t, E) = \text{PASS}}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q, \delta_H(q_H, \sigma_C), \text{Apply}(S, t) \rangle} \quad [\text{SOS-HUMAN-SOVEREIGNTY-LOCKDOWN}]
```

### 3.6 Meta-Regola SOS di Congelamento da Lockdown (Lockdown Freeze Standard)
```math
\frac{\sigma_C \in \Sigma_H \setminus \{ \text{HEV\_PAUSE\_REQUESTED}, \text{HEV\_DECLINE\_ALL} \} \quad q \notin F_{\text{oper}}}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q, q_H, S \rangle} \quad [\text{SOS-LOCKDOWN-FREEZE}]
```

### 3.7 Meta-Regola SOS di Congelamento degli Stati Terminali (Terminal State Freeze)
```math
\frac{q_H \in F_H \quad \sigma_C \in \Sigma_H \setminus \{ \text{HEV\_GOAL\_UPDATE} \}}{\langle q, q_H, \sigma_C, S, E \rangle \to_{\text{Sys}} \langle q, q_H, S \rangle} \quad [\text{SOS-TERMINAL-FREEZE}]
```

---

## 4. POLICY GUIDANCE ENGINE & STRATIFICAZIONE DELLE POLICY

### 4.1 Stratificazione delle Policy in 3 Livelli (`OBI-005`)
Per impedire l'esecuzionalità diretta di regole in lingua naturale o suscettibili di ambiguità interpretativa, il Policy Guidance Engine adotta una stratificazione rigorosa a 3 livelli:

1. **Policy Specification Layer (Livello Normativo):** Testo normativo, principi etici e linee guida espresse in linguaggio naturale comprensibile dagli operatori umani.
2. **Policy Compilation Layer (Livello di Compilazione):** Processo di traduzione automatizzata e validata che trasforma le specifiche in predicati formali e parametri $\Theta$.
3. **Executable Policy Predicate Layer (Livello Esecutivo Puro):** Il codice o byte-code deterministico derivato $\mathcal{R}_{\text{exec}}: \mathcal{S} \times T \to \{ \text{ALLOW}, \text{DENY}, \text{RECALIBRATE} \}$, l'unico direttamente eseguibile dal runtime al Livello 2.

---

### 4.2 Definizione Algebrica del Policy Bundle $\mathcal{P}$
Il `PolicyBundle` $\mathcal{P}$ è formalizzato come la tupla algebrica:

```math
\mathcal{P} := \langle \text{PolicyID}, \text{Version}, \Theta, \mathcal{R}_{\text{exec}}, \text{Sig}_\mathcal{P} \rangle
```

* $\text{PolicyID} \in \mathcal{I}$: Identificatore unico della policy.
* $\text{Version} \in V$: Versione della policy nell'Algebra delle Versioni (§6).
* $\Theta$: Lo spazio dei parametri di configurazione e soglie della policy (es. $\theta_{\text{duration}}, \theta_{\text{confidence}}$).
* $\mathcal{R}_{\text{exec}}: \mathcal{S} \times T \to \{ \text{ALLOW}, \text{DENY}, \text{RECALIBRATE} \}$: Predicato esecutivo puro.
* $\text{Sig}_\mathcal{P}$: La firma crittografica dell'autorità di policy emittente.

---

### 4.3 Composizione Algebrica Disgiunta ($\oplus$) e Versione Composita Commutativa via Hash (`OBI-006`)

L'operatore di composizione algebrica $\oplus$ produce il bundle composito $\mathcal{P}_{\text{comp}} = \mathcal{P}_1 \oplus \mathcal{P}_2$ mediante la funzione esplicita $\text{ComposePolicy}$:

```math
\text{ComposePolicy}(\mathcal{P}_1, \mathcal{P}_2) := \left\langle \text{PolicyID}_{\text{comp}}, \text{CompositePolicyVersion}, \text{CompositePolicyDigest}, \Theta_1 \cup \Theta_2, \mathcal{R}_{\text{exec, comp}}, \text{Sig}_{\text{comp}} \right\rangle
```

Dove:
```math
\text{PolicyID}_{\text{comp}} = H(\text{sort}(\text{PolicyID}_1, \text{PolicyID}_2))
```

* **Impronta Crittografica Composita (`OBI-006`):**
```math
\text{CompositePolicyDigest} = H\left( \text{sort}(\text{PolicyID}_1, \text{PolicyID}_2) \mathbin{\Vert} \text{sort}(\text{Version}_1, \text{Version}_2) \right) \in \mathcal{D}
```

* **Versione Composita Compatibile col Dominio $V$:**
  La versione del bundle composito $\text{CompositePolicyVersion} \in V$ è derivata componendo le tuple SemVer $v_1 = \langle M_1, m_1, p_1 \rangle$ e $v_2 = \langle M_2, m_2, p_2 \rangle$ tramite l'operatore di estremo superiore:
```math
\text{CompositePolicyVersion} := \left\langle \max(M_1, M_2), \ \max(m_1, m_2), \ \max(p_1, p_2) \right\rangle \in V
```

  Tale formalizzazione preserva l'appartenenza allo Spazio delle Versioni $V := \mathbb{N} \times \mathbb{N} \times \mathbb{N}$ (§6.1) e garantisce la valutabilità della relazione di compatibilità retroattiva $\preceq_{\text{compat}}$ (§6.2).

* La funzione di valutazione composita $\mathcal{R}_{\text{exec, comp}}(S, t)$ è governata dalla regola disgiunta `DENY-OVERRIDES`:

```math
\mathcal{R}_{\text{exec, comp}}(S, t) = \begin{cases}
\text{DENY} & \text{se } \mathcal{R}_{\text{exec}, 1}(S, t) = \text{DENY} \lor \mathcal{R}_{\text{exec}, 2}(S, t) = \text{DENY} \\
\text{RECALIBRATE} & \text{se } (\mathcal{R}_{\text{exec}, 1}(S, t) = \text{RECALIBRATE} \lor \mathcal{R}_{\text{exec}, 2}(S, t) = \text{RECALIBRATE}) \\
& \quad \land \mathcal{R}_{\text{exec}, 1}(S, t) \neq \text{DENY} \land \mathcal{R}_{\text{exec}, 2}(S, t) \neq \text{DENY} \\
\text{ALLOW} & \text{se } \mathcal{R}_{\text{exec}, 1}(S, t) = \text{ALLOW} \land \mathcal{R}_{\text{exec}, 2}(S, t) = \text{ALLOW}
\end{cases}
```

---

### 4.4 Tassonomia della Guida ed Ergonomia Cognitiva (`OBI-003`)

Al fine di ridurre lo stress ed il carico cognitivo dell'utente vulnerabile senza usurparne la sovranità decisionale, il sistema definisce 3 livelli formali di guida comunicativa:

1. **Direttiva Autoritativa (Authoritative Directive):** Formulazione prescrittiva ammessa **esclusivamente** in condizioni di imminente rischio per la sicurezza o situazioni di emergenza acuta (`PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Raccomandazione Motivata e Contestualizzata (Motivated & Contextualized Recommendation):** Formulazione consigliata che propone un percorso operativo riducendo il carico cognitivo ("Sulla base di quanto analizzato, il prossimo passo consigliato è X. Vuoi procedere o valutare alternative?"). La raccomandazione `MUST` esplicitare la motivazione, il grado di certezza ed essere immediatamente revocabile o modificabile dall'utente.
3. **Opzione Esplorativa (Exploratory Option):** Presentazione neutrale di alternative multiple, indicata quando l'utente si trova in uno stato di stabilità emotiva e desidera confrontare autonomamente le possibilità.

---

### 4.5 Filosofia Normativa dell'Intervento Umano (Human Override)
L'intervento di un operatore umano (`OPERATOR`) costituisce un meccanismo di garanzia e supporto e `MUST` conformarsi ai seguenti 5 principi normativi inderogabili:

1. **Principio di Tracciabilità:** Ogni azione di override `MUST` generare una transizione registrata nel ledger $\mathcal{L}$ contenente l'ID dell'operatore.
2. **Principio di Autenticazione Forte:** L'override richiede una firma crittografica valida ed il possesso del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. **Principio di Spiegabilità Obbligatoria:** Ogni intervento di override `MUST` includere una motivazione esplicita in formato testuale non vuoto.
4. **Principio di Inalterabilità Storica:** L'override modifica unicamente lo stato proiettato corrente $S_N$, ma `SHALL NOT` cancellare o alterare le transizioni precedenti del ledger.
5. **Principio di Rispettabilità del Consenso:** L'operatore umano `SHALL NOT` forzare l'esecuzione di azioni in violazione del consenso espresso dall'utente, salvo nei casi previsti dal livello HOBM `PROFESSIONAL_INTERVENTION_REQUIRED`.

---

## 5. EMANCIPATION PLAYBOOK ENGINE

### 5.1 Struttura del Grafo del Playbook $G_P$
Un **Emancipation Playbook** è formalizzato come un grafo orientato $G_P = (V_P, E_P, C_P)$:
* $V_P$: Insieme dei Nodi di Micro-Azione ($v \in V_P$).
* $E_P \subseteq V_P \times V_P$: Archi diretti rappresentanti la sequenza logica di progressione.
* $C_P$: Insieme delle Condizioni e Prerequisiti di Verificabilità, dove ogni elemento $c \in C_P$ è un predicato booleano puro $c: \mathcal{S} \to \{ \text{True}, \text{False} \}$.

---

### 5.2 Tipizzazione dei Nodi Playbook (`OBI-008`)
Per evitare che una mappa di orientamento si trasformi in una procedura burocratica prescrittiva ed bloccante, ogni nodo $v \in V_P$ `MUST` appartenere ad una delle seguenti categorie formali:

1. **`INFORMATION`:** Nodo a contenuto puramente informativo o educativo. Non richiede azioni o conferme per il proseguimento.
2. **`OPTIONAL_STEP`:** Micro-passo suggerito per ottimizzare il percorso, saltabile dall'utente senza alcun blocco del flusso.
3. **`USER_CONFIRMED_STEP`:** Micro-passo che richiede il consenso o la conferma esplicita dell'utente prima di essere marcato come completato.
4. **`REQUIRED_FOR_SYSTEM_STATE`:** Prerequisito tecnico o legale bloccante (es. rilascio codice fiscale per apertura conto). Solo i nodi appartenenti a questa categoria possono condizionare le transizioni dell'automa di runtime $M$.

---

### 5.3 Invarianti di Esecuzione e Tracking dello Stato Playbook ($\mathcal{K}_{\text{playbook}}$)
1. **`INV-PLAYBOOK-GRAPH-01` (Aclicienza Locale sui Nodi Bloccanti):** Il sotto-grafo dei nodi tipizzati `REQUIRED_FOR_SYSTEM_STATE` `MUST` essere un Grafo Diretto Aclicico (DAG). La rilevazione di cicli bloccanti causa l'immediato scarto con **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.
2. **`INV-PLAYBOOK-STEP-02` (Durata Parametrizzata):** La durata stimata di una micro-azione non può superare il valore definito dal parametro:
```math
\theta_{\text{max\_duration}} \in \Theta
```
   
4. **`INV-PLAYBOOK-STATE-03` (Tracciamento dello Stato di Avanzamento):** Ogni avanzamento nel grafo $G_P$ `MUST` aggiornare la componente $\mathcal{K}_{\text{playbook}}$ nello stato $\mathcal{S}$, registrando la relativa Data Provenance ($D_P$).

---

## 6. TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ

### 6.1 Spazio delle Versioni $V$
Ogni componente versionabile di Scintilla Core appartiene allo spazio vettoriale discreto delle versioni $V := \mathbb{N} \times \mathbb{N} \times \mathbb{N}$, rappresentato dalla tupla $v = \langle \text{major}, \text{minor}, \text{patch} \rangle$.

### 6.2 Relazione di Compatibilità Retroattiva $\preceq_{\text{compat}}$
Siano $v_1 = \langle M_1, m_1, p_1 \rangle$ e $v_2 = \langle M_2, m_2, p_2 \rangle$ due versioni nello spazio $V$. La relazione di compatibilità retroattiva $v_1 \preceq_{\text{compat}} v_2$ è definita formalmente come:

```math
v_1 \preceq_{\text{compat}} v_2 \iff (M_1 = M_2) \land \left( (m_1 < m_2) \lor (m_1 = m_2 \land p_1 \le p_2) \right)
```

---

## 7. CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA

### 7.1 Spazio Normalizzato $\mathcal{S}_{\text{normalized}}$ e Canonizzazione $\text{Canon}$
Sia 
```math
\mathcal{S}_{\text{normalized}} \subseteq \mathcal{S}
```
il sottoinsieme di stati conformi alle regole di normalizzazione SC-JCS-1 (§10.2). La funzione di canonizzazione deterministica
```math
\text{Canon}: \mathcal{S}_{\text{normalized}} \to \mathcal{B}^*
```
è una **funzione iniettiva**:

```math
\forall s_1, s_2 \in \mathcal{S}_{\text{normalized}}, \quad \text{Canon}(s_1) = \text{Canon}(s_2) \iff s_1 = s_2
```

---

### 7.2 Costruzione della Catena di Hash Immutabile e Verifica delle Firme
La continuità e l'integrità del ledger $L \in \mathcal{L}$ per la transazione $N$-esima è determinata dal calcolo del checksum $H_N \in \mathcal{D}$ eseguito sul corpo della transazione $\text{TransactionBody}_N$ (§1.1.3):

```math
H_0 = \mathbf{0}_{\mathcal{D}} \quad (\text{Digest nullo di Genesi})
```
```math
H_N = H\left( \text{Canon}(\text{TransactionBody}_N) \right)
```

Dove 
```math
H: \mathcal{B}^* \to \mathcal{D}
```
è la funzione di hash astratta (SHA-256) e 
```math
\text{TransactionBody}_N
```
contiene $H_{N-1}$ come valore del campo `prev_hash`.

---

## 8. FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEI RUNTIME ERROR CODES

### 8.1 Criteri Normativi di Accettazione PASS/FAIL
Un'implementazione esecutiva ottiene la **Certificazione di Conformità Scintilla Core v4.3** se e solo se soddisfa i seguenti criteri:
1. **Test Vector Match:** $100\%$ di corrispondenza bit-identica sugli hash generati dal profilo di riferimento applicato.
2. **Requisito di Verifica LTL/CTL:** $100\%$ delle proprietà logiche temporali (§9.2) risultano soddisfatte nel modello formale.
3. **Totalità Matematica:** Gestione corretta ed esaustiva di tutte le coppie $(q, \sigma) \in Q \times \Sigma$ e $(q_H, \sigma_H) \in Q_H \times \Sigma_H$.

---

### 8.2 Tassonomia Normativa dei Runtime Error Codes e Process Exit Codes
In caso di violazione degli invarianti di sicurezza o fallimento delle precondizioni, il runtime `MUST` segnalare la condizione di errore mediante un **Runtime Error Code** canonico appartenente allo spazio numerico riservato `70–99`. 

Quando il runtime esegue come processo autonomo di sistema operativo, tale identificatore `SHALL` essere propagato come **Process Exit Code** dell'ambiente di esecuzione:

#### Sotto-insieme Crittografia, Sicurezza e Consenso (70–79)
* **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`):** Fallimento nella verifica della firma digitale Ed25519 sulla transazione $t$.
* **Runtime Error Code 72 (`ERR_CONSENT_REVOKED_VIOLATION`):** Tentativo di eseguire un'operazione in assenza di consenso o con consenso esplicitamente revocato in $\mathcal{Q}_{\text{consent}}$.
* **Runtime Error Code 73 (`ERR_INFRASTRUCTURE_IO`):** Fallimento dell'infrastruttura di I/O, acquisizione del lease di concorrenza o perdita di connessione al Ledger.
* **Runtime Error Code 77 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrità crittografica della catena di hash ($H_N$), manomissione del ledger o tentata alterazione storica.
* **Runtime Error Code 78 (`ERR_LEASE_ACQUISITION_TIMEOUT`):** Scadenza del lease di concorrenza durante un tentativo di mutazione di stato.
* **Runtime Error Code 79 (`ERR_CLOCK_SKEW_EXCEEDED`):** La differenza tra l'ora di sistema locale $E.t_{\text{wall}}$ ed il timestamp della transazione supera la tolleranza massima consentita $\Delta t_{\text{max}}$.

#### Sotto-insieme Validazione, Parsing, Flussi e KMS (80–89)
* **Runtime Error Code 80 (`ERR_SML_PARSE_FAILED`):** Errore di validazione sintattica dell'input SML v2.0 rispetto alla grammatica EBNF (§C.1).
* **Runtime Error Code 81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`):** Scadenza della soglia temporale di inattività nello stato $h_7$ (`HUMAN_PAUSED`).
* **Runtime Error Code 82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`):** Tentativo di avanzamento verso un identificatore di nodo non esistente nel grafo del Playbook active ($G_P$).
* **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo illegale sui nodi bloccanti all'interno di un Emancipation Playbook Graph ($G_P$).
* **Runtime Error Code 84 (`ERR_SCHEMA_MISMATCH`):** Incompatibilità di versione dello schema dati non coperta da un `MigrationManifest` valido.
* **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`):** Errore di formattazione o presenza di numeri fuori dall'intervallo consentito (*Strict Signed Safe Integer Range*).
* **Runtime Error Code 86 (`ERR_HOBM_BOUNDARY_VIOLATION`):** Tentativo di eseguire un'azione ad alto rischio o impatto legale (`HUMAN_REVIEW_REQUIRED`) priva della firma autorizzativa di un attore di tipo `OPERATOR`.
* **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`):** Indisponibilità, errore di I/O o fallimento di comunicazione con il subsistema di gestione delle chiavi effimere (`KMS_KeyStore`).

---

## 9. MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE

### 9.1 Modello di Sistema Distribuito, Consistenza e Concorrenza
1. **Modello di Consistenza del Ledger:** Il registro $L \in \mathcal{L}$ garantisce la **Strict Linearizability (Consistenza Esterna)** per singolo `case_id`.
2. **Protocollo di Lock e Fencing Token:** La gestione delle scritture concorrenti si avvale di un meccanismo di lease a tempo. Ogni mutazione `MUST` verificare e incrementare in modo strettamente monotonico il `fencing_token` $N \in \mathbb{N}^+$.
3. **Tolleranza al Disallineamento Temporale (Clock Skew):** L'intervallo di tolleranza massima tra l'orologio locale ed il tempo di riferimento $t \in \mathcal{T}$ è vincolato dal parametro $\Delta t_{\text{max}} \in \Theta$.

---

### 9.2 Logica Temporale Normativa (Formule LTL e CTL)

#### Predicati Atomici di Stato
Sia $S \in \mathcal{S}$ lo stato algebrico corrente. Sono definiti i seguenti predicati booleani puri:

```math
\text{IsSafetyGateAllowed}(S) \iff \mathcal{R}_{\text{exec}}(S, t) = \text{ALLOW}
```
```math
\text{IsDecisionOutcomeAllowed}(S) \iff \pi_{\mathcal{O}}(S) = \text{ALLOW}
```
```math
\text{IsHashChainValid}(S) \iff H(\text{Canon}(\text{TransactionBody}_N)) = H_N
```
```math
\text{IsMonotonicFence}(S) \iff \text{fencing}_{\text{token}_N} > \text{fencing}_{\text{token}_{N-1}}
```

#### Assunzioni di Equità Ambientale e dell'Utente (Fairness Assumptions)
```math
\text{FAIR}_{\text{USER}} \iff \square \diamondsuit (\text{UserEngaged}) \land \neg \text{ConsentRevoked}
```
```math
\text{FAIR}_{\text{SYSTEM}} \iff \square \diamondsuit (\text{SystemAvailable}) \land \text{ResourcesExist}
```
```math
\text{Fairness} \iff \text{FAIR}_{\text{USER}} \land \text{FAIR}_{\text{SYSTEM}}
```

#### Proprietà LTL (Linear Temporal Logic)
* **LTL Safety 1 (Safety Gate / Policy Guidance Corrected):**
```math
\square \left( \text{IsDecisionOutcomeAllowed}(S) \implies \text{IsSafetyGateAllowed}(S) \right)
```
   
* **LTL Safety 2 (Fencing & Lease Recovery):**
```math
\square \left( \neg \text{IsMonotonicFence}(S) \implies X(q = \text{RECOVERABLE\_FAILURE}) \right)
```
   
* **LTL Safety 3 (Hash Chain Integrity):**
```math
\square \left( \neg \text{IsHashChainValid}(S) \implies X(q = \text{SECURITY\_LOCKDOWN}) \right)
```
   
* **LTL Safety 4 (Unidirectional Automata Decoupling):**
```math
\square \left( \text{State}(\mathcal{H}) = q_H \implies \text{DirectMutation}(M) = \text{FALSE} \right)
```
   
#### Proprietà CTL (Computation Tree Logic)
* **CTL System Agency Guarantee (Accessibilità del Progresso di Sistema):**
```math
\text{Fairness} \implies AG \left( \text{UserEngaged} \implies EF (\text{SystemProgress}) \right)
```
  dove: 
```math
\text{SystemProgress} \iff \text{StepCompleted} \lor \text{Recalibrated} \lor \text{AGI\_Increased}
```
   
* **CTL Trap-Free Safety (Garante di Recuperabilità dal Lockdown):**
```math
AG \left( q = \text{SECURITY\_LOCKDOWN} \implies EF (q = \text{NORMAL} \lor q = \text{SAFE\_READ\_ONLY\_MODE}) \right)
```

---

# PARTE II: PROFILE ARCHITECTURE & CONCRETE REFERENCE PROFILES

---

## 10. STANDARD REFERENCE PROFILE 1 (JSON / SC-JCS-1 / SHA-256 / Ed25519)

### 10.1 Binding delle Primitive Crittografiche, Identificatori e Mapping dei Campi
* **Mappatura Identificatori ($\mathcal{I}$):** Stringhe `UUIDv7` conformi a RFC 9562.
* **Mappatura Tempo ($\mathcal{T}$):** Stringhe formattate secondo ISO 8601 / RFC 3339 UTC Z con precisione ai millisecondi.
* **Mappatura Istante Temporale di Genesi ($t_0$):** `"1970-01-01T00:00:00.000Z"`.
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
  10. `schema_hash` $\longrightarrow$ `"schema_hash"`
  11. `authorization_snapshot_hash` $\longrightarrow$ `"authorization_snapshot_hash"`
  12. `runtime_profile_hash` $\longrightarrow$ `"runtime_profile_hash"`
  13. `specification_id` $\longrightarrow$ `"specification_id"`

---

### 10.2 Il Profilo di Canonizzazione JSON SC-JCS-1
**SC-JCS-1 è un profilo di canonizzazione derivato e NON-COMPATIBILE a livello di hash con lo standard RFC 8785 JCS**.

#### 10.2.1 Sottoinsieme $J_{\text{SC}}$ e Strict Signed Safe Integer Range
Un documento JSON 
```math
j \in \text{JSON}_{\text{RFC8259}}
```

appartiene al sottoinsieme 
```math
J_{\text{SC}}
```

se e solo se tutti i numeri presenti sono interi compresi nell'intervallo chiuso:
```math
I_{\text{safe}} = \left[ -(2^{53} - 1), \ +(2^{53} - 1) \right] = \left[ -9007199254740991, \ +9007199254740991 \right]
```

Qualsiasi notazione contenente notazione scientifica (`1e10`), `NaN` o `Infinity` `MUST` essere rifiutata con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

**Regola Esclusiva sui Valori in $[0.0, 1.0]$ (Basis Points Standard):** 
Per garantire una funzione di canonizzazione $\text{Canon}$ **rigorosamente iniettiva e priva di ambiguità di hashing**, tutti i campi numerici rappresentanti probabilità, punteggi di confidenza ($\phi$) o indici AGI $[0.0, 1.0]$ **`MUST` essere convertiti e serializzati in JSON come numeri interi a punto fisso scalati di un fattore $10^4$ (Basis Points, intervallo chiuso intero $[0, 10000]$)**. La rappresentazione in virgola mobile diretta per tali campi è severamente vietata e determina lo scarto immediato del documento.

#### 10.2.2 Algoritmo di Serializzazione Canonica SC-JCS-1
1. **Whitespace Elimination:** Rimuovere tutti i caratteri di spaziatura esterni alle stringhe.
2. **String Escaping & Literal Primitives Rule:** Escape unicamente per U+0000..U+001F, `"`, e `\`.
3. **Unicode Normalization:** Normalizzazione Normalization Form C (NFC).
4. **Object Key Sorting:** Ordinamento ascendente secondo i code-unit UTF-16.
5. **Set Semantics Deep Bottom-Up Array Sorting:** Per tutte le chiavi registrate nel `SetSemanticsRegistry`:
```math
\text{SetSemanticsRegistry} = \left[ \text{"completed\_nodes"}, \ \text{"permissions"}, \ \text{"prerequisites"}, \ \text{"roles"}, \ \text{"scopes"} \right]
```
   L'ordinamento degli elementi dell'array `MUST` essere eseguito con una strategia **Ricorsiva Bottom-Up (Deep Canonicalization)**:
   * **Passo 5.a:** Ogni elemento dell'array (sia esso una primitiva o un oggetto JSON complesso nidificato) `MUST` essere prima serializzato autonomamente in una sequenza di byte canonica SC-JCS-1 applicando ricorsivamente le regole 1-4.
   * **Passo 5.b:** Gli elementi dell'array così serializzati `MUST` essere ordinati in modo ascendente sulla base del confronto lexicografico byte-per-byte delle loro rappresentazioni UTF-8 canoniche.

---

### 10.3 Machine-Readable $\delta_M$ JSON Definition Contract

```json
{
  "automaton_id": "SCINTILLA_RUNTIME_SAFETY_AUTOMATON",
  "specification_version": "4.2.0-TIMELESS",
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
    {"from": "SECURITY_LOCKDOWN", "event": "EV_TIMEOUT", "to": "SAFE_READ_ONLY_MODE"},
    {"from": "SECURITY_LOCKDOWN", "event": "*", "to": "SECURITY_LOCKDOWN"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_HASH_CORRUPT", "to": "SECURITY_LOCKDOWN"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_REPAIR", "to": "NORMAL"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "EV_OVERRIDE", "to": "NORMAL"},
    {"from": "SAFE_READ_ONLY_MODE", "event": "*", "to": "SAFE_READ_ONLY_MODE"}
  ]
}
```

---

# PARTE III: ANNEXES (INFORMATIVE & SYNTACTIC MAPPINGS)

---

## ANNEX A: TYPESCRIPT TYPE MAPPING (INFORMATIVE)

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

export interface DataProvenanceRecord {
  provenance_id: string;            
  source_category: "USER_DECLARATION" | "LLM_INFERENCE" | "SYSTEM_VERIFIED" | "OPERATOR_CONFIRMED" | "EXTERNAL_SOURCE";
  asserted_by_actor_id: string;     
  timestamp_utc: string;            
  confidence_score: number;         // [0.0, 1.0]
  verifiability_status: "UNVERIFIED" | "PENDING" | "VERIFIED" | "REJECTED";
  assertion_domain: ProvenanceDomain;
}

export interface AgencyGainIndexRecord {
  clarity_score: number;            // [0.0, 1.0]
  action_execution_ratio: number;   // [0.0, 1.0]
  dependency_reduction_score: number; // [0.0, 1.0]
  computed_agi: number;             // [0.0, 1.0]
}
```

```typescript
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

## ANNEX C: SML v2.0 SPECIFICATION (SYNTACTIC EBNF & SEMANTIC VALIDATION)

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

### C.2 Validazione Semantica e Gate di Sicurezza di Livello 2 (Semantic Safety Gate)

Il Policy Guidance Engine (Livello 2) applica una verifica semantica vincolante sugli oggetti `SMLDocumentParsed` prima di ammettere qualsiasi proposta di transizione:

1. **Filtro contro Allucinazioni Amministrative/Legali:** Se l'oggetto SML contiene asserzioni categorizzate nel dominio:
```math
\omega = \text{FACTUAL\_ADMINISTRATIVE}
```
 (es. diritti a sussidi, scadenze di legge), l'asserzione `MUST` essere ancorata ad un nodo di Playbook o fonte esterna con stato di verifica $\psi = \text{VERIFIED}$.
2. **Azione di Violazione:** Qualora il Livello 5 generi un'asserzione amministrativa prescrittiva priva di riscontro verificato, il parser di Livello 4 `MUST` scartare l'input e generare l'evento di errore:
```math
\sigma_2 = \text{EV\_SML\_FAIL}
```
 imponendo al runtime la riconfigurazione dell'output in forma di *Opzione Esplorativa* (§4.4).

---

# PARTE IV: CONFORMANCE FRAMEWORK & TEST VECTOR AXIOMS

---

## 11. CONFORMANCE PROFILE E TEST VECTOR AXIOMS

### 11.1 Assiomatizzazione dei Test Vectors
I Test Vector concreti (stringhe serializzate SC-JCS-1 ed impronte esadecimali SHA-256) per lo Standard Reference Profile 1 sono formalmente mantenuti nell'artefatto normativo di conformità: **`SCINTILLA-CORE-CONFORMANCE-PROFILE-1.JSON`**.

---

## 12. STATO DI CERTIFICAZIONE E LIVELLI DI VERIFICA (`OBI-010`)

### 12.1 Stato Normativo della Specifica
La presente **SCINTILLA CORE CANONICAL SPECIFICATION v4.3 Timeless (GitHub Edition)** definisce la specifica normativa canonica e completa del dominio SCINTILLA CORE.

Lo stato corrente del documento è:

**SPEC-COMPLETE — Specifica Canonica Completa e Corretta (v4.3)**

Tale stato certifica che la struttura normativa, l'algebra degli stati, la grammatica sintattica e il formato delle formule matematiche sono matematicamente coerenti, esenti da ambiguità, pronti per GitHub e costituiscono la Single Source of Truth del sistema.

---

### 12.2 Separazione tra Specifica, Verifica e Certificazione

SCINTILLA CORE distingue formalmente i seguenti livelli di maturità:

1. **Livello SPEC (Specifica Canonica):** Stato **SPEC-COMPLETE** (raggiunto dal presente documento v4.3).
2. **Livello VERIF (Verifica Formale degli Artefatti):** Richiede la modellazione formale eseguibile (TLA+, NuSMV) e la verifica dell'assenza di deadlock. Stato: **PENDING VERIFICATION ARTIFACTS**.
3. **Livello VERIF-PROOF (Dimostrazione Meccanizzata):** Richiede la produzione di prove formali mediante theorem proving assistito (Lean 4, Coq) per tutti i *Proof Claims* dichiarati nella specifica. Stato: **PENDING PROOF ARTIFACTS**.
4. **Livello CERT (Certificazione di Implementazione):** Richiede un'implementazione software sottoposta a verifica con test runner e test vector ufficiali. Stato: **PENDING IMPLEMENTATION CERTIFICATION**.

---

### 12.3 Regola di Dichiarazione della Certificazione
Nessuna implementazione o documento derivato `SHALL` dichiarare SCINTILLA CORE come "formalmente verificato" o "matematicamente provato" in assenza dei corrispondenti artefatti verificati definiti ai livelli VERIF e VERIF-PROOF. La conformità alla presente specifica garantisce esclusivamente lo stato:

**SPEC-COMPLETE — Canonical Specification v4.3 Timeless**
