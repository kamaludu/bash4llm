# ✴ SCINTILLA Standard Operating Procedure (SOP)
## Canonical Methodological Laboratory Manual v1.0

**Manuale Operativo e Metodologico di Laboratorio per l'Applicazione e la Verifica di SCINTILLA Core**

* **Document ID:** `SCINTILLA-SOP-CANONICAL-v1.0`
* **Stato:** Standard Operativo Canonico Ufficiale (Subordinato a SCINTILLA Core v4.5.6)
* **Normative Baseline:** `SCINTILLA Core v4.5.6` (**STRICTLY FROZEN** — Single Source of Truth Normativa)
* **Gerarchia Documentale Vincolante:**
```text
SCINTILLA Core v4.5.6 (WHAT / Single Source of Truth Normativa)
         │
         ▼
SCINTILLA SOP v1.0 (HOW TO OPERATE / Manuale Metodologico di Laboratorio)
         │
         ▼
SCINTILLA Blueprint (HOW TO ORGANIZE / Architettura di Riferimento)
         │
         ▼
Implementation (HOW TO BUILD / Realizzazione Software e Concreta)
```
* **Notazione Matematica:** ASCII pura conforme alle norme di interoperabilità (zero LaTeX, zero comandi con barra retroversa, zero caratteri o simboli greci/matematici Unicode).

---

# SEZIONE 1: QUADRO METODOLOGICO, GERARCHIA E PRINCIPI DI LABORATORIO

---

### 1.1 Natura della SOP, Ambito e Subordinazione al Core v4.5.6

La presente **SCINTILLA Standard Operating Procedure (SOP)** costituisce il manuale metodologico-operativo di laboratorio destinato a operatori, metodologi, auditor e sistemi di orchestrazione incaricati di eseguire, monitorare, verificare e documentare i processi definiti da **SCINTILLA Core v4.5.6**.

#### 1.1.1 Principio di Subordinazione Assoluta
```text
RULE-SOP-SUBORDINATION-01
```
> **"SCINTILLA Core v4.5.6 costituisce l'autorità normativa suprema ed immutabile. La presente SOP definisce il COME (HOW TO OPERATE) e non possiede alcuna autorità normativa autonoma per modificare, reinterpretare, estendere o completare il COSA (WHAT) definito dal Core. In caso di qualsiasi apparente tensione o divergenza tra la presente SOP e SCINTILLA Core v4.5.6, il Core prevale incondizionatamente."**

#### 1.1.2 Delimitazione di Astrazione (Technology-Agnostic Principle)
La presente SOP opera a livello metodologico e procedurale. Essa `SHALL NOT` prescrivere:
1. Linguaggi di programmazione, framework software, librerie o runtime specifici;
2. Database commerciali o open-source, motori di storage o schemi di tabelle concrete;
3. Protocolli di trasporto di rete (es. HTTP, gRPC, WebSocket), API concrete o formati di messaggistica non vincolati dal Core;
4. Modelli linguistici specifici, tecniche proprietarie di prompt engineering o infrastrutture di calcolo GPU/cloud;
5. Layout grafici, interfacce utente (UI/UX) o componenti visuali.

Tali decisioni appartengono tassativamente ai livelli subordinati di **SCINTILLA Blueprint** (Architettura) e **Implementation** (Costruzione).

---

### 1.2 Tassonomia Epistemica delle Prescrizioni e Convenzioni Operative

Ogni enunciato, controllo o sequenza descritta nella presente SOP appartiene rigorosamente a una delle seguenti categorie formali:

1. **`CORE-MANDATED`:** Vincolo o trasformazione algebrica determinata direttamente ed esplicitamente dal testo di SCINTILLA Core v4.5.6. La sua violazione costituisce una non-conformità normativa critica. Per queste prescrizioni si applicano i verbi deontici `MUST`, `MUST NOT`, `SHALL`, `SHALL NOT`.
2. **`CORE-DERIVED PROCEDURE`:** Sequenza metodologica necessaria per eseguire o verificare un requisito del Core senza introdurre nuova semantica normativa.
3. **`SOP-CONVENTION`:** Convenzione o standard procedurale adottato dal laboratorio per garantire uniformità operativa ove il Core lasci aperta la modalità pratica. Per queste prescrizioni si applicano i verbi deontici deboli `SHOULD`, `RECOMMENDED`.
4. **`ORG-POLICY`:** Politica esterna di governance, turnistica, organizzazione del personale, SLA aziendali o accordi di servizio. Non costituisce derivazione dal Core e non ha forza normativa di sistema.
5. **`BLUEPRINT-DELEGATED`:** Decisione architetturale o strutturale lasciata aperta dal Core e demandata al Blueprint.
6. **`IMPLEMENTATION-DELEGATED`:** Scelta di codice, algoritmo software o struttura dati concreta demandata all'Implementation.
7. **`UNDETERMINED`:** Condizione o parametro non determinato dal Core v4.5.6, registrato esplicitamente per prevenire decisioni arbitrarie.

---

### 1.3 Ruoli Operativi Metodologici e Matrice delle Responsabilità di Laboratorio

La SOP disciplina l'interazione tra i ruoli operativi nel rispetto della matrice di autorizzazione del Core (Cap 3.1: `type(actor) in { USER, OPERATOR, SYSTEM }`):

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ RUOLI METODOLOGICI DI LABORATORIO                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. UTENTE (type(actor) == USER):                                            │
│    Titolare inalienabile del percorso di emancipazione e del consenso.      │
│    Autorità decisionale primaria su avanzamento, pause e revoche.           │
│                                                                             │
│ 2. OPERATORE METODOLOGICO / TUTOR (type(actor) == OPERATOR):                │
│    Professionista umano accreditato con permesso SC.PERMISSION.OPERATOR_... │
│    Responsabile di supporto, revisione HOBM, override e ripristini.         │
│                                                                             │
│ 3. SISTEMA DETERMINISTICO (type(actor) == SYSTEM):                          │
│    Motore di runtime esecutivo di Livello 1/0. Applica le regole SOS,       │
│    valida l'ambiente, aggiorna il Ledger e calcola le metriche pure.        │
│                                                                             │
│ 4. AUDITOR DI CONFORMITÀ (Ruolo di Ispezione e Verifica):                   │
│    Figura terza incaricata di verificare il replay deterministico,          │
│    la continuità dell'hash chain, l'isolamento AGI e l'assenza di cicli.    │
└─────────────────────────────────────────────────────────────────────────────┘
```

*Nota di Delimitazione:* La composizione delle squadre, i turni di reperibilità e le metriche di prestazione del personale costituiscono `ORG-POLICY` e non alterano le regole di transizione del Kernel.

---

### 1.4 Principio Duale di Laboratorio (Evidence vs Format & Procedure vs Algorithm)

Nell'applicazione della presente SOP, ogni operatore ed auditor `MUST` conformarsi ai seguenti due principi cardine:

#### 1.4.1 Principio di Distinzione tra Obiettivo di Prova e Formato di Archiviazione
```text
EVIDENCE OBJECTIVE != EVIDENCE FORMAT
```
La SOP specifica **quale proprietà formale deve essere dimostrata, tracciata o resa verificabile** (es. invariabilità del digest, esito nullo di decifratura, presenza della transizione sul Ledger). Il formato di memorizzazione materiale (es. schema di database, file system, estensione, codifica di trasporto) è demandato al **Blueprint**. La SOP non impone formati di file o certificati esterni non previsti dal Core.

#### 1.4.2 Principio di Distinzione tra Procedura Metodologica e Algoritmo Software
```text
OPERATIONAL PROCEDURE != IMPLEMENTATION ALGORITHM
```
La SOP specifica la **sequenza di passi metodologici e i punti di controllo logici** necessari per validare un requisito (es. accertare che un grafo sia aciclico o che una firma sia valida). La SOP `SHALL NOT` imporre specifici algoritmi di calcolo, routine di codice (es. ordinamento di Kahn vs visita DFS) o classi di complessità computazionale, la cui scelta è demandata all'**Implementation**.

---

# SEZIONE 2: PROTOCOLLI OPERATIVI DEL CICLO DI VITA DEL CASO (DP-1)

---

### PROCEDURA SOP-F01: Inizializzazione Caso Utente e Genesi dello Stato

```text
========================================================================================
SOP-ID: SOP-F01
NOME DELLA PROCEDURA: Inizializzazione Caso Utente e Genesi dello Stato
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 1.3 (s0), Cap 1.4.3 (Persist), PO-01 (Cap 1.3.1)
========================================================================================
```

#### 1. TRIGGER
Ricezione della richiesta formale di apertura di un nuovo percorso di emancipazione per un utente, corredata dall'allocazione di un identificatore di caso univoco `case_id`.

#### 2. PRECONDITIONS
1. L'identificatore di caso `case_id in I_case` è generato e privo di collisioni nello spazio degli stati.
2. Il modulo crittografico conforme a `CryptoProviderContract` (Cap 1.8) ha allocato il contesto per il caso.
3. Il registro immutabile del caso è nello stato iniziale vuoto: `L_ledger == epsilon`.
4. Il Policy Bundle di default `P_default` è compilato, firmato e verificato conforme (Cap 4.2).

#### 3. INPUTS
1. `case_id`: Identificatore del caso appartenente a `I_case`.
2. `P_default`: Bundle di policy di base attivo.
3. `E.t_wall`: Timestamp UTC di genesi espresso in millisecondi a 64 bit.

#### 4. OPERATIONAL SEQUENCE
1. **Istanziazione Metodologica di $s_0$:** Configurare lo stato iniziale secondo la definizione formale di Cap 1.3:
   - `s0_persistent := < case_id = case_id, M_prov = empty_set, Q_consent = empty_set, K_playbook = < null, null, empty_set >, Q_revoked_items = empty_set, K_competence = empty_set, V_vault = empty_set >`
   - `s0_internal := < q = NORMAL, q_H = UNASSESSED, P_active = P_default, F_lease = < 0, E.t_wall >, O_bound = AUTOMATED_SUPPORT, t_pause_start = null, M_metrics = < 0, 0, 0, 0 >, seq_num = 0, last_hash = 0_D256 >`
   - `s0_auxiliary := < D_drafts = empty_set >`
2. **Costruzione della Transazione di Genesi $t_0$:**
   - Impostare `tx_id` univoco, `case_id = case_id`, `seq_num = 0`, `prev_hash = 0_D256` (32 byte 0x00).
   - Impostare `event = EV_SUCCESS`, `actor = SYSTEM`, `timestamp = E.t_wall`.
   - Impostare `policy_binding_hash = P_default.digest`, `schema_hash = SchemaDigest(CurrentSchemaVersion)`.
   - Assegnare `execution_envelope = < "PROCESSED_NOMINAL", "GENESIS_INITIALIZATION", true >`.
3. **Serializzazione e Persistenza:**
   - Serializzare $t_0$ conformemente all'algoritmo SC-JCS-1 (Cap 10.3).
   - Calcolare l'hash di genesi $H_0 = SHA256(Canon(TransactionBody_0))$.
   - Eseguire l'operazione di persistenza append-only: `Persist(empty_set, t_0)`.
   - Applicare la transizione pura: `S_0 = ApplyValidated(s0, t_0, PASS)`.

#### 5. VERIFICATION POINTS
1. Verificare che `pi_internal(S_0).last_hash == H_0`.
2. Verificare che `pi_internal(S_0).seq_num == 0`.
3. Verificare che `Derive(S_0)` restituisca `A_index == 0` e `O_decision == NONE`.
4. Verificare che `PROOF-OBLIGATION-GENESIS-SERIALIZATION-INVARIANCE` (`PO-01`) sia soddisfatta (flusso di byte UTF-8 canonico bit-identico).

#### 6. EXPECTED RESULT / STATE
Stato primario inizializzato `S_0` persistito sul Ledger con catena crittografica ancorata a $H_0$, automa di sicurezza in $q_0 = \text{NORMAL}$ ed automa umano in $h_0 = \text{UNASSESSED}$.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la presenza della transazione $t_0$ memorizzata nel Ledger immutabile, recante `prev_hash = 0_D256`, firma valida e digest SHA-256 coincidente con il valore `last_hash` registrato nello stato.

#### 8. NON-CONFORMITY HANDLING
- Se la verifica di serializzazione SC-JCS-1 fallisce (es. presenza di float o formato malformato), bloccare l'inizializzazione ed emettere **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.
- Se il modulo crittografico non risponde, bloccare la genesi ed emettere **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`)**.

#### 9. ESCALATION
Segnalazione all'Amministratore di Sistema in caso di errore di persistenza o mancata allocazione della chiave crittografica.

#### 10. AUTHORITY CLASSIFICATION
* Invarianza di $s_0$, calcolo $H_0$ e SC-JCS-1: `CORE-MANDATED`.
* Sequenza di avvio caso: `CORE-DERIVED PROCEDURE`.
* Formato consigliato per `case_id` (UUIDv7): `SOP-CONVENTION`.

#### 11. BLUEPRINT DEPENDENCIES
Scelta dell'engine di memorizzazione append-only del Ledger; allocazione del contesto crittografico; driver di ricezione richiesta onboarding.

#### 12. IMPLEMENTATION DEPENDENCIES
Libreria di serializzazione SC-JCS-1; generatore di numeri casuali crittografici per ID; funzione hash SHA-256.

---

### PROCEDURA SOP-F02: Gestione del Consenso Informato e Revoca Logica Parziale

```text
========================================================================================
SOP-ID: SOP-F02
NOME DELLA PROCEDURA: Gestione del Consenso Informato e Revoca Logica Parziale
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 0.2.2 (AXIOM-HUMAN-CONSENT-SOVEREIGNTY),
                Cap 1.5.1 (SOFT_LOGICAL_REVOCATION), Cap 3.1 (Autorizzazioni)
========================================================================================
```

#### 1. TRIGGER
Ricezione di una dichiarazione esplicita da parte dell'utente di concessione di nuovo consenso, modifica delle autorizzazioni o revoca puntuale di un elemento informativo (`item_id`).

#### 2. PRECONDITIONS
1. Il caso utente è inizializzato e attivo (`case_id != null`).
2. L'automa di sicurezza di runtime è in uno stato operativo stabile: `q in F_oper = { NORMAL, SAFE_READ_ONLY_MODE }`.
3. L'attore è autenticato come `USER` (o `OPERATOR` autorizzato dall'utente).

#### 3. INPUTS
1. `item_id`: Identificatore univoco dell'elemento (`doc_id in V_vault`, `consent_id in Q_consent`, o `skill_id in K_competence`).
2. `action_type`: Tipo operazione (`GRANT_CONSENT` oppure `REVOKE_ITEM`).
3. Firma digitale dell'attore calcolata sul payload della richiesta.

#### 4. OPERATIONAL SEQUENCE
##### Caso A: Concessione Consenso (`GRANT_CONSENT`)
1. Costruire la transazione $t$ con `event = HEV_STEP_COMPLETED` o evento business associato, includendo la tupla di consenso in `payload`.
2. Validare l'ambiente `ValidateEnvironment(S, t, E)`.
3. Applicare la transizione: `Q_consent' = Q_consent union { consent_item }`.

##### Caso B: Revoca Logica Parziale (`REVOKE_ITEM` / `SOFT_LOGICAL_REVOCATION`)
1. Costruire la transazione $t$ con `event = EV_ITEM_PRIVACY_REVOKED`, `actor = USER`, recante `item_id` nel payload.
2. Sottoporre la transazione a `ValidateEnvironment(S, t, E)`.
3. Applicare la mutazione deterministica:
   ```text
   Q_revoked_items' = Q_revoked_items union { item_id }
   ```
4. **Isolamento della Vista Pubblica:** Eseguire la proiezione pura `Obs(S)` verificando che:
   ```text
   forall e t.c. ResourceId(e) == item_id, e notin Obs(S)  (valore restituito = null)
   ```
5. **Preservazione dell'Avanzamento di Grafo:** Mantenere inalterato l'insieme dei nodi completati $V_{completed}$ in `K_playbook` (Cap 1.5.1).

#### 5. VERIFICATION POINTS
1. Verificare che l'identificatore `item_id` sia presente in `pi_persistent(S').Q_revoked_items`.
2. Verificare che `Obs(S')` restituisca `null` in corrispondenza dell'elemento revocato.
3. Verificare che il nodo Playbook associato all'acquisizione dell'elemento rimanga in `K_playbook.V_completed`.
4. Verificare che le capacità residue dell'utente in `Capabilities(Obs(S'))` non subiscano decurtazioni punitive (`RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01`).

#### 6. EXPECTED RESULT / STATE
Elemento revocato oscurato con effetto immediato dalla vista pubblica e dai servizi di interfaccia; storico del Ledger e consistenza del grafo Playbook matematicamente preservati.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la persistenza sul Ledger della transazione `EV_ITEM_PRIVACY_REVOKED` firmata dall'utente e la dimostrabile assenza del dato revocato dall'output della funzione di osservazione `Obs(S')`.

#### 8. NON-CONFORMITY HANDLING
- Se un processo interno o esterno tenta di elaborare un elemento presente in `Q_revoked_items`, sollevare e registrare **Runtime Error Code 72 (`ERR_CONSENT_REVOKED_VIOLATION`)**.
- Se la firma sulla richiesta di revoca risulta non valida, rifiutare l'operazione con **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`)**.

#### 9. ESCALATION
Nessuna escalation bloccante: la revoca del consenso è un diritto inalienabile e unilaterale dell'utente umano che il sistema esegue deterministicamente.

#### 10. AUTHORITY CLASSIFICATION
* Invarianza di $V_{completed}$ su revoca e filtraggio `Obs(S)`: `CORE-MANDATED`.
* Procedura di ingestione richiesta: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Interfaccia di gestione privacy per l'utente; meccanismi di re-rendering immediato delle viste client; canali sicuri di ricezione revoche.

#### 12. IMPLEMENTATION DEPENDENCIES
Funzione di estrazione `ResourceId(e)` e operatore di differenza insiemistica nella proiezione `Obs`.

---

### PROCEDURA SOP-F03: Esecuzione dell'Oblio Crittografico Totale (Crypto-Shredding)

```text
========================================================================================
SOP-ID: SOP-F03
NOME DELLA PROCEDURA: Esecuzione dell'Oblio Crittografico Totale (Crypto-Shredding)
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 1.5.2 (FULL_CRYPTO_SHREDDING),
                Cap 9.2.4 (FO-LTL Safety 5: Invarianza dell'Oblio), RFC-005
========================================================================================
```

#### 1. TRIGGER
Ricezione di una richiesta esplicita ed irrevocabile di cancellazione totale del caso e distruzione dei dati (`HEV_DECLINE_ALL` con opzione oblio, o richiesta legale di crypto-erasure).

#### 2. PRECONDITIONS
1. Il caso utente è attivo (`case_id != null`).
2. La chiave crittografica radice del caso `K_case` è presente e attiva nel modulo KMS (`LookupKey(K_case) != null`).
3. L'attore richiedente è autenticato con diritti di sovranità sul caso (`USER` o rappresentante legale autorizzato).

#### 3. INPUTS
1. `case_id`: Identificatore del caso da distruggere.
2. Richiesta formale di cancellazione recante la prova crittografica dell'utente.

#### 4. OPERATIONAL SEQUENCE
1. **Verifica di Autenticità:** Validare l'autenticità e la non-ambiguità della volontà espressa dall'utente di cancellazione totale.
2. **Invocazione di Crypto-Shredding:**
   - Invocare l'operazione distruttiva pura del modulo crittografico:
     ```text
     CryptoProviderContract.ShredKey(K_case)
     ```
   - Verificare l'elisione irreversibile di ogni percorso di ripristino (`NoRecovery(K_case)`).
3. **Verifica di Irrecuperabilità del Vault:**
   - Eseguire un test formale di decifratura su un record cifrato $v \in \mathcal{V}_{vault}$:
     ```text
     DecryptPayload(null, Encrypt_{K_case}(v)) == null
     ```
4. **Emissione della Transazione di Chiusura $t_{shred}$:**
   - Costruire la transazione finale $t_{shred}$ con `event = EV_CRYPTO_SHRED_EXECUTED`, `actor = SYSTEM` (o `USER`), recante `case_id` e causale.
   - Registrare $t_{shred}$ in modo append-only sul Ledger: `Persist(L, t_{shred})`.
5. **Transizione Terminale dell'Automa Umano:**
   - Applicare `ApplyValidated` transitando l'automa umano allo stato terminale definitivo:
     ```text
     q_H' = HUMAN_DECLINED_ASSISTANCE  (h10 in F_H)
     ```

#### 5. VERIFICATION POINTS
1. Verificare che `LookupKey(K_case) == null` (chiave non più rintracciabile nel KMS).
2. Verificare che la proprietà temporale `FO-LTL Safety 5` sia soddisfatta:
   ```text
   [] ( CryptoShredExecuted_c ===> X([] KeyIsShredded_c) )
   ```
3. Verificare che l'automa $\mathcal{H}$ sia nello stato terminale $h_{10} \in F_H$ e che nessuna transizione successiva sia abilitata (`Resolve(h10, sigma, F_H) == h10`).

#### 6. EXPECTED RESULT / STATE
Chiave radice $K_{case}$ definitivamente distrutta; payload cifrati del Vault matematicamente irrecuperabili; Ledger strutturalmente integro recante l'attestazione terminale $t_{shred}$; automa umano in stasi terminale $h_{10}$.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la presenza nel Ledger della transazione immutabile `EV_CRYPTO_SHRED_EXECUTED` e l'esito nullo (`null`) restituito da qualsiasi operazione di lookup della chiave $K_{case}$ o di decifratura dei record del Vault.

#### 8. NON-CONFORMITY HANDLING
- Se l'operazione `ShredKey(K_case)` fallisce nel KMS, bloccare il processo, **NON emettere la transazione $t_{shred}$** ed emettere **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`)**.
- Ritentare l'operazione di distruzione fino a garanzia di irrevocabilità prima di consolidare lo stato.

#### 9. ESCALATION
Notifica immediata al Responsabile della Sicurezza e Privacy (DPO) in caso di mancata risposta del KMS durante una procedura di oblio.

#### 10. AUTHORITY CLASSIFICATION
* Invariante di distruzione chiave e formula FO-LTL Safety 5: `CORE-MANDATED`.
* Sequenza operativa di cancellazione: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Integrazione con il driver KMS/HSM fisico; meccanismi di cancellazione sicura delle copie cache in memoria volatile.

#### 12. IMPLEMENTATION DEPENDENCIES
Implementazione del metodo `ShredKey` e routine di verifica fallimento decifratura.

---

### PROCEDURA SOP-F11: Custodia Discreta in Base Sicura (Standby h11)

```text
========================================================================================
SOP-ID: SOP-F11
NOME DELLA PROCEDURA: Custodia Discreta in Base Sicura (Standby h11)
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 0.2.3 (INV-CONTINUITY-OF-SUPPORT-01),
                Cap 2.3.1 (Dinamica dello Stato h11 - PREVENTIVE_STANDBY)
========================================================================================
```

#### 1. TRIGGER
Raggiungimento da parte dell'utente dello stato di autonomia sostenuta:
```text
q_H = SUSTAINED_INDEPENDENCE  (h6)
```
ed emissione dell'evento `HEV_PREVENTIVE_SUPPORT_REQ` (o transizione automatica programmata di fine percorso).

#### 2. PRECONDITIONS
1. L'automa umano $\mathcal{H}$ si trova nello stato $h_6$ (`SUSTAINED_INDEPENDENCE`).
2. L'automa di sicurezza $M$ si trova in uno stato operativo stabile: `q in F_oper = { NORMAL, SAFE_READ_ONLY_MODE }`.
3. Tutti i prerequisiti del Playbook di autonomia risultano completati in $V_{completed}$.

#### 3. INPUTS
1. Transazione recante `event = HEV_PREVENTIVE_SUPPORT_REQ` emessa dall'utente o generata dal sistema a compimento percorso.

#### 4. OPERATIONAL SEQUENCE
1. **Transizione a Base Sicura:**
   - Elaborare la transizione deterministica:
     ```text
     delta_H(SUSTAINED_INDEPENDENCE, HEV_PREVENTIVE_SUPPORT_REQ) = PREVENTIVE_STANDBY  (h11)
     ```
2. **Attivazione della Modalità di Ascolto Discreto:**
   - Sospendere la generazione automatica di micro-azioni quotidiane, promemoria o notifiche proattive.
   - Mantenere attivo e pienamente accessibile all'utente il canale di interrogazione della vista `Obs(S)`.
3. **Preservazione Indefinita delle Risorse:**
   - Garantire a tempo indeterminato la consultazione del Vault `V_vault` e del registro delle competenze `K_competence` (`INV-CONTINUITY-OF-SUPPORT-01`).
4. **Sorveglianza per Re-ingaggio Immediato:**
   - Mantenere abilitata la ricezione degli eventi di disagio o regressione:
     * `HEV_EMOTIONAL_OVERWHELM`
     * `HEV_RELAPSE_REGRESS`
   - All'arrivo di uno di tali eventi, transitare immediatamente l'automa da $h_{11}$ allo stato attivo di supporto:
     ```text
     q_H' = HUMAN_RECALIBRATION_REQUIRED  (h8)
     ```
     riattivando la guida senza richiedere all'utente alcuna giustificazione morale.

#### 5. VERIFICATION POINTS
1. Verificare che `pi_Q_H(S') == PREVENTIVE_STANDBY` ($h_{11}$).
2. Verificare che $h_{11} \in H_{active}$, garantendo che la proposizione `JourneyProgressive` permanga `True` in assenza di fault tecnici.
3. Verificare che la vista `Obs(S')` mantenga invariati tutti i record di competenza e documenti nel Vault.
4. Verificare che non vengano inviate notifiche proattive non richieste dall'utente.

#### 6. EXPECTED RESULT / STATE
Automa umano attestato nello stato di "Base Sicura" ($h_{11}$); utente pienamente autonomo con garanzia di accesso permanente alle proprie credenziali e riattivazione istantanea della guida in caso di necessità.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la transizione sul Ledger a `PREVENTIVE_STANDBY`, la persistente disponibilità della funzione `Obs(S)` e la corretta transizione a $h_8$ in presenza di eventi di re-ingaggio.

#### 8. NON-CONFORMITY HANDLING
- Qualora un modulo esterno tenti di revocare l'accesso ai dati o dismettere il caso a seguito del raggiungimento dell'indipendenza, bloccare l'azione in ossequio all'invariante supremo `INV-CONTINUITY-OF-SUPPORT-01`.

#### 9. ESCALATION
Nessuna escalation: la permanenza in $h_{11}$ è a tempo indeterminato e non costituisce anomalia.

#### 10. AUTHORITY CLASSIFICATION
* Invariante di continuità del supporto e transizione $h_6 \to h_{11}$: `CORE-MANDATED`.
* Guardrail operativo di custodia discreta: `OPERATIONAL_GUARDRAIL`.

#### 11. BLUEPRINT DEPENDENCIES
Configurazione del gateway di interfaccia per l'accesso in consultazione passiva; disattivazione dei trigger di notifica push proattiva.

#### 12. IMPLEMENTATION DEPENDENCIES
Mapping deterministico degli eventi di ricaduta nell'automa $\mathcal{H}$.

---

# SEZIONE 3: METODOLOGIA DEL PERCORSO DI EMANCIPAZIONE E PLAYBOOK (DP-2)

---

### PROCEDURA SOP-F06: Validazione di Aciclicità e Caricamento del Grafo Playbook

```text
========================================================================================
SOP-ID: SOP-F06
NOME DELLA PROCEDURA: Validazione di Aciclicità e Caricamento del Grafo Playbook
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 5.1 (Struttura Grafo G_P),
                Cap 5.3.1 (INV-PLAYBOOK-GRAPH-01), Annex B.2, Cap 8.2 (Err 83)
========================================================================================
```

#### 1. TRIGGER
Ricezione o sottomissione di un nuovo oggetto `EmancipationPlaybookGraph` serializzato (`G_P`) destinato all'assegnazione a un caso utente o all'aggiornamento del catalogo dei percorsi.

#### 2. PRECONDITIONS
1. L'automa di sicurezza di runtime è in stato operativo: `q == NORMAL`.
2. L'oggetto Playbook è validato sintatticamente rispetto all'interfaccia di schema (Annex B.1).
3. Tutti gli identificatori dei nodi `v.node_id` all'interno del grafo sono mutuamente distinti (unicità dei vertici).

#### 3. INPUTS
1. Oggetto grafo serializzato: `G_P := (V_P, E_P, C_P)`.
2. Parametro di configurazione di policy: `Theta.theta_max_duration` (durata massima stimata per micro-passo).

#### 4. OPERATIONAL SEQUENCE
1. **Isolamento del Sottografo Bloccante:**
   - Estrarre il sottoinsieme dei vertici bloccanti di sicurezza:
     ```text
     V_blocking := { v in V_P | v.action_type == "REQUIRED_FOR_SYSTEM_STATE" }
     ```
   - Costruire il sottografo indotto $G_{\text{blocking}} := (V_{\text{blocking}}, E_{\text{blocking}})$ dove:
     ```text
     E_blocking := { (u, v) in E_P | u in V_blocking and v in V_blocking }
     ```
2. **Esecuzione della Verifica di Aciclicità:**
   - Eseguire il controllo metodologico del predicato puro:
     ```text
     IsAcyclic(G_blocking) == TRUE
     ```
     accertando l'assenza di qualsiasi cammino orientato chiuso $\langle v_1, v_2, \dots, v_k, v_1 \rangle$ nel sottografo bloccante (`INV-PLAYBOOK-GRAPH-01`).
3. **Verifica della Durata dei Micro-Passi:**
   - Verificare che per ogni nodo $v \in V_P$:
     ```text
     v.estimated_duration_minutes <= Theta.theta_max_duration
     ```
4. **Verifica delle Condizioni Pure:**
   - Accertare che ogni condizione associata $c \in C_P$ sia formulata come predicato booleano puro privo di effetti collaterali $c: \mathcal{S} \to \{ \text{True}, \text{False} \}$.
5. **Caricamento ed Integrazione di Stato:**
   - Se tutti i controlli hanno esito positivo, autorizzare l'ingestione del Playbook nello stato persistente:
     ```text
     K_playbook' := < G_P.playbook_id, InitialNode(G_P), V_completed >
     ```

#### 5. VERIFICATION POINTS
1. Verificare che `IsAcyclic(G_blocking) == TRUE`.
2. Verificare che nessun ciclo coinvolga nodi con `action_type == "REQUIRED_FOR_SYSTEM_STATE"`.
3. Verificare che la durata stimata di ciascun nodo rispetti il limite massimo `theta_max_duration`.

#### 6. EXPECTED RESULT / STATE
Grafo Playbook validato e caricato nello stato $\mathcal{S}$ con `pb_id` associato; runtime pronto per l'avanzamento dei micro-passi senza rischio di stallo circolare.

#### 7. EVIDENCE OBJECTIVE
Dimostrare che la verifica di aciclicità ha restituito esito positivo prima dell'ingestione del grafo e che il digest del Playbook è registrato nel contesto di stato.

#### 8. NON-CONFORMITY HANDLING
- Qualora venga rilevato anche un solo ciclo orientato tra nodi bloccanti, **rifiutare immediatamente il caricamento del Playbook**, interrompere la sequenza ed emettere **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.
- Se un nodo supera la durata massima consentita, rifiutare il caricamento con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 9. ESCALATION
Segnalazione al Metodologo / Autore del Playbook per la reingegnerizzazione della sequenza dei passi e la rimozione delle dipendenze circolari.

#### 10. AUTHORITY CLASSIFICATION
* Invariante di aciclicità `INV-PLAYBOOK-GRAPH-01` e codice errore 83: `CORE-MANDATED`.
* Sequenza metodologica di verifica: `VERIFICATION PROCEDURE`.
* Scelta dell'algoritmo software di verifica (topologico / DFS): `IMPLEMENTATION-DELEGATED`.

#### 11. BLUEPRINT DEPENDENCIES
Struttura del repository dei Playbook e driver di caricamento/caching dei grafi.

#### 12. IMPLEMENTATION DEPENDENCIES
Algoritmo di verifica aciclicità su grafi orientati; modulo di parsing schema JSON/TypeScript.

---

### PROCEDURA SOP-F07: Esecuzione ed Avanzamento delle Micro-Azioni Playbook

```text
========================================================================================
SOP-ID: SOP-F07
NOME DELLA PROCEDURA: Esecuzione ed Avanzamento delle Micro-Azioni Playbook
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 5.2 (Tipizzazione Nodi),
                Cap 3.3.1 ([SOS-COMPETENCE-UPDATE]), Cap 5.3.3 (Tracking K_playbook)
========================================================================================
```

#### 1. TRIGGER
Ricezione di una transazione recante l'evento `HEV_STEP_COMPLETED` emessa a fronte dell'avvenuto completamento di un nodo di micro-azione da parte dell'utente.

#### 2. PRECONDITIONS
1. L'automa di sicurezza è in stato operativo: `q in F_oper = { NORMAL, SAFE_READ_ONLY_MODE }`.
2. Il Playbook attivo è inizializzato: `pi_persistent(S).K_playbook.pb_id != null`.
3. Il nodo indicato $v_{target}$ esiste nel grafo attivo $G_P$.
4. Tutti i prerequisiti del nodo risultano soddisfatti:
   ```text
   v_target.prerequisites subset pi_persistent(S).K_playbook.V_completed
   ```

#### 3. INPUTS
1. `node_id`: Identificatore del nodo completato.
2. `t`: Transazione candidata recante `event = HEV_STEP_COMPLETED`, `actor = USER` (o `OPERATOR`).
3. Stato corrente $\mathcal{S}$.

#### 4. OPERATIONAL SEQUENCE
1. **Verifica della Tipologia di Nodo:**
   - Se `v_target.action_type == "INFORMATION"`: Avanzamento automatico non vincolante.
   - Se `v_target.action_type == "OPTIONAL_STEP"`: Avanzamento ammesso senza verifiche bloccanti.
   - Se `v_target.action_type == "USER_CONFIRMED_STEP"`: Verificare la presenza del consenso/conferma esplicita dell'utente.
   - Se `v_target.action_type == "REQUIRED_FOR_SYSTEM_STATE"`: Verificare che tutti i predicati di guardia $c \in C_P$ associati al nodo restituiscano `True` sullo stato corrente $\mathcal{S}$.
2. **Aggiornamento Insieme Nodi Completati:**
   - Calcolare il nuovo insieme dei nodi completati:
     ```text
     V_completed' = V_completed union { node_id }
     ```
3. **Applicazione della Meta-Regola SOS Competenze (`[SOS-COMPETENCE-UPDATE]`):**
   - Se il nodo reca un attributo di competenza acquisita $v_{\text{target}}.\text{gained\_skill} = \langle \text{skill\_id}, \text{level\_bp} \rangle$:
     ```text
     K_competence' = K_competence union { < skill_id, level_bp, E.t_wall > }
     ```
4. **Determinazione del Nodo Successivo:**
   - Determinare il nuovo nodo attivo `node_curr'` conformemente alla topologia del grafo $G_P$.
   - Aggiornare atomicamente la tupla: `K_playbook' = < pb_id, node_curr', V_completed' >`.
5. **Transizione Deterministica di Stato:**
   - Eseguire `ApplyValidated(S, t[K_playbook |-> K_playbook', K_competence |-> K_competence'], PASS)`.

#### 5. VERIFICATION POINTS
1. Verificare che `node_id in pi_persistent(S').K_playbook.V_completed`.
2. Verificare che la competenza acquisita sia registrata in `pi_persistent(S').K_competence`.
3. Verificare che l'avanzamento rispetti l'invariante di anti-gamification (`RULE-ANTI-GAMIFICATION-01`), senza indurre trattenimento artificiale dell'utente.

#### 6. EXPECTED RESULT / STATE
Stato persistente $\mathcal{S}'$ aggiornato deterministicamente con inclusione del nodo completato, arricchimento del registro competenze e puntamento al nuovo passo del percorso.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la presenza della transazione persistita `HEV_STEP_COMPLETED` nel Ledger e la mutazione coerente e verificabile di `K_playbook` e `K_competence`.

#### 8. NON-CONFORMITY HANDLING
- Se l'identificatore del nodo non esiste nel grafo attivo $G_P$, rifiutare la transazione ed emettere **Runtime Error Code 82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`)**.
- Se i prerequisiti di un nodo bloccante non sono soddisfatti, respingere la transazione con esito `FAIL` delle guardie, preservando lo stato invariato.

#### 9. ESCALATION
Segnalazione all'operatore/tutor qualora l'utente rimanga bloccato su un nodo con prerequisiti complessi.

#### 10. AUTHORITY CLASSIFICATION
* Regola di inferenza SOS `[SOS-COMPETENCE-UPDATE]` e tipizzazione nodi: `CORE-MANDATED`.
* Sequenza operativa di avanzamento: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Interfaccia di presentazione delle micro-azioni e gestione dell'interazione utente.

#### 12. IMPLEMENTATION DEPENDENCIES
Engine di transizione di stato e gestione delle collezioni persistenti in memoria.

---

### PROCEDURA SOP-F08: Ingestione Documentale e Custodia Credenziali nel Vault

```text
========================================================================================
SOP-ID: SOP-F08
NOME DELLA PROCEDURA: Ingestione Documentale e Custodia Credenziali nel Vault
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 3.3.2 ([SOS-VAULT-RECORD]),
                Cap 1.8 (CryptoProviderContract), Cap 2.3 (Stato DOCUMENT_RECOVERY)
========================================================================================
```

#### 1. TRIGGER
Acquisizione, scansione o verifica di un documento d'identità, attestato o certificato formale da parte dell'utente o dell'operatore, con emissione dell'evento `HEV_DOCS_OBTAINED`.

#### 2. PRECONDITIONS
1. L'automa di sicurezza è in stato operativo stabile: `q in F_oper = { NORMAL, SAFE_READ_ONLY_MODE }`.
2. Il modulo crittografico conforme a `CryptoProviderContract` è disponibile ed operativo.
3. Il payload documentale è validato sintatticamente ed include il digest crittografico del documento originale.

#### 3. INPUTS
1. `doc_id`: Identificatore univoco del documento (UUIDv7 o stringa conforme).
2. `doc_payload`: Contenuto del documento o credenziale.
3. `H_doc`: Impronta crittografica SHA-256 calcolata sul documento binario originale.
4. `status`: Stato di verifica (fissato normativamente a `VERIFIED`).

#### 4. OPERATIONAL SEQUENCE
1. **Verifica di Integrità del Documento:**
   - Calcolare l'hash SHA-256 sul payload documentale grezzo:
     ```text
     H_computed = SHA256(doc_payload)
     ```
   - Verificare l'esatta coincidenza: `H_computed == H_doc`.
2. **Cifratura Autenticata Simmetrica:**
   - Invocare la funzione del modulo crittografico:
     ```text
     Payload_encrypted = CryptoProviderContract.EncryptPayload(K_item, doc_payload)
     ```
3. **Costruzione della Tupla di Custodia:**
   - Formare la tupla canonica di custodia: `doc_entry := < doc_id, H_doc, VERIFIED >`.
4. **Applicazione della Meta-Regola SOS Vault (`[SOS-VAULT-RECORD]`):**
   - Eseguire la transizione di stato persistente:
     ```text
     V_vault' = V_vault union { doc_entry }
     ```
   - Transire deterministicamente l'automa umano allo stato di avanzamento documentale:
     ```text
     q_H' = DOCUMENT_RECOVERY  (h3)
     ```
5. **Persistenza su Ledger:**
   - Registrare la transazione $t$ recante `event = HEV_DOCS_OBTAINED`, includendo `doc_entry` e il payload cifrato nell'involucro protetto.

#### 5. VERIFICATION POINTS
1. Verificare che `doc_entry in pi_persistent(S').V_vault`.
2. Verificare che `pi_Q_H(S') == DOCUMENT_RECOVERY`.
3. Verificare che il digest $H_{doc}$ consenta l'ispezione di integrità senza esporre i dati in chiaro nella vista non autenticata.

#### 6. EXPECTED RESULT / STATE
Documento cifrato e custodito nel Vault; record registrato nello stato persistente $\mathcal{S}'$; percorso umano avanzato allo stato $h_3$ (`DOCUMENT_RECOVERY`).

#### 7. EVIDENCE OBJECTIVE
Dimostrare la persistenza sul Ledger della transazione `HEV_DOCS_OBTAINED` recante la tupla $\langle \text{doc\_id}, H_{\text{doc}}, \text{VERIFIED} \rangle$ e la corretta transizione a `DOCUMENT_RECOVERY`.

#### 8. NON-CONFORMITY HANDLING
- Se il calcolo dell'hash documentale non coincide con $H_{doc}$, rifiutare l'ingestione per mancata integrità.
- Se il modulo crittografico fallisce l'operazione di cifratura, bloccare l'ingestione ed emettere **Runtime Error Code 87 (`ERR_KMS_UNAVAILABLE`)**.

#### 9. ESCALATION
Assistenza all'utente da parte dell'operatore in caso di documenti non leggibili o rigettati per vizi formali.

#### 10. AUTHORITY CLASSIFICATION
* Meta-regola `[SOS-VAULT-RECORD]` e transizione a $h_3$: `CORE-MANDATED`.
* Procedura di cifratura e verifica hash: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Architettura fisica del Vault cifrato e storage per i blob binari protetti.

#### 12. IMPLEMENTATION DEPENDENCIES
Integrazione con il `CryptoProviderContract` e routine di calcolo SHA-256.

---

### PROCEDURA SOP-F09: Gestione della Stasi Umana, Pausa e Timeout di Inattività

```text
========================================================================================
SOP-ID: SOP-F09
NOME DELLA PROCEDURA: Gestione della Stasi Umana, Pausa e Timeout di Inattività
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 3.4.1 ([SOS-HUMAN-PAUSED-STUTTER]),
                Cap 3.4.2 ([SOS-HUMAN-TIMEOUT]), RFC-002, Cap 8.2 (Err 81)
========================================================================================
```

#### 1. TRIGGER
Richiesta esplicita di pausa da parte dell'utente (`HEV_PAUSE_REQUESTED`), oppure superamento della soglia temporale massima di permanenza in inattività nello stato di stasi.

#### 2. PRECONDITIONS
1. L'automa di sicurezza è in stato operativo: `q in F_oper = { NORMAL, SAFE_READ_ONLY_MODE }`.
2. L'orologio ambientale $E.t_{\text{wall}}$ è sincronizzato e validato.

#### 3. INPUTS
1. Evento umano di ingresso ($\sigma_C \in \Sigma_H$).
2. Parametro di policy: `Theta.theta_inactivity_timeout` (durata massima di pausa ammessa).
3. Timestamp di inizio pausa: `pi_internal(S).t_pause_start`.

#### 4. OPERATIONAL SEQUENCE
##### Caso A: Ingresso in Stato Pausa
1. Alla ricezione dell'evento `HEV_PAUSE_REQUESTED`:
   - Eseguire la transizione: $\delta_H(q_H, \text{HEV\_PAUSE\_REQUESTED}) = \text{HUMAN\_PAUSED} \; (h_7)$.
   - Registrare il timestamp di inizio: `t_pause_start' = E.t_wall`.
   - Congelare l'indice AGI conformemente a `DEF-AGI-PAUSED-STATE-INVARIANCE` (Cap 1.7.2).

##### Caso B: Elaborazione di Eventi durante la Stasi (`[SOS-HUMAN-PAUSED-STUTTER]`)
1. Quando $q_H == \text{HUMAN\_PAUSED}$ e giunge un evento $\sigma_C \in \Sigma_H \setminus \{ \text{HEV\_RESUME\_REQUESTED}, \text{HEV\_DECLINE\_ALL}, \text{HEV\_EMOTIONAL\_OVERWHELM} \}$:
   - L'automa esegue uno **stuttering step** ($h_7 \to h_7$), mantenendo lo stato invariato.
   - Emettere la transazione recante l'involucro di esecuzione normativo:
     ```text
     execution_envelope = < "PROCESSED_NO_STATE_EFFECT", "HUMAN_JOURNEY_PAUSED", false >
     ```

##### Caso C: Rilevazione del Timeout di Inattività (`[SOS-HUMAN-TIMEOUT]`)
1. Se $q_H == \text{HUMAN\_PAUSED}$ e la condizione temporale è verificata:
   ```text
   (E.t_wall - pi_internal(S).t_pause_start) > Theta.theta_inactivity_timeout
   ```
2. Il sistema genera deterministicamente la transizione di sistema:
   ```text
   t_timeout = BuildSystemTx(S, E, HEV_RECALIBRATION_REQ)
   ```
3. Applicare la meta-regola `[SOS-HUMAN-TIMEOUT]` transitando l'automa allo stato di ricalibrazione:
   ```text
   q_H' = HUMAN_RECALIBRATION_REQUIRED  (h8)
   ```

##### Caso D: Ripresa Esplicita dell'Utente
1. Alla ricezione dell'evento `HEV_RESUME_REQUESTED`:
   - Eseguire la transizione: $\delta_H(\text{HUMAN\_PAUSED}, \text{HEV\_RESUME\_REQUESTED}) = \text{HUMAN\_RECALIBRATION\_REQUIRED} \; (h_8)$.
   - Reimpostare `t_pause_start' = null`.

#### 5. VERIFICATION POINTS
1. Verificare che durante la permanenza in $h_7$ nessun avanzamento o arricchimento competenze abbia luogo.
2. Verificare che l'involucro di esecuzione contenga rigorosamente `"PROCESSED_NO_STATE_EFFECT"`.
3. Verificare che allo scadere del timeout avvenga la transizione automatica a $h_8$.

#### 6. EXPECTED RESULT / STATE
Automa umano mantenuto in stasi protetta ($h_7$) senza decurtazione di diritti o competenze, con transizione controllata a $h_8$ per ricalibrazione all'atto della ripresa o del timeout.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la presenza delle transizioni con involucro `"HUMAN_JOURNEY_PAUSED"` sul Ledger e l'emissione di `BuildSystemTx` recante `HEV_RECALIBRATION_REQ` in caso di superamento del timeout.

#### 8. NON-CONFORMITY HANDLING
- Se il sistema non rileva il superamento del timeout ed omette la transizione a $h_8$, segnalare **Runtime Error Code 81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`)**.

#### 9. ESCALATION
Contatto discreto ed empatico da parte del tutor/operatore qualora l'utente entri ripetutamente in timeout.

#### 10. AUTHORITY CLASSIFICATION
* Meta-regole SOS `[SOS-HUMAN-PAUSED-STUTTER]` e `[SOS-HUMAN-TIMEOUT]`: `CORE-MANDATED`.
* Monitoraggio temporale: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Daemon/Scheduler per il controllo asincrono della scadenza dei timeout di inattività.

#### 12. IMPLEMENTATION DEPENDENCIES
Routine di costruzione transazioni `BuildSystemTx` e comparatori di timestamp a 64 bit.

---

### PROCEDURA SOP-F10: Ricalibrazione e Rientro da Sopraffazione Emotiva

```text
========================================================================================
SOP-ID: SOP-F10
NOME DELLA PROCEDURA: Ricalibrazione e Rientro da Sopraffazione Emotiva
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 2.3.2 (RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01),
                Cap 3.4.3 ([SOS-EMOTIONAL-OVERWHELM]), PO-16, Cap 10.5 (delta_H)
========================================================================================
```

#### 1. TRIGGER
Ricezione dell'evento `HEV_EMOTIONAL_OVERWHELM` (da utente o da parser SML) oppure ricezione di `HEV_STABILIZED` mentre l'automa si trova nello stato $h_8$ (`HUMAN_RECALIBRATION_REQUIRED`).

#### 2. PRECONDITIONS
1. L'automa umano $\mathcal{H}$ si trova nello stato $h_8$ (`HUMAN_RECALIBRATION_REQUIRED`) o riceve un segnale di sopraffazione emotiva da qualsiasi stato non-terminale.
2. L'automa di sicurezza è in stato operativo: `q in F_oper = { NORMAL, SAFE_READ_ONLY_MODE }`.

#### 3. INPUTS
1. Evento umano di ingresso (`HEV_EMOTIONAL_OVERWHELM` oppure `HEV_STABILIZED`).
2. Tupla di stato del Playbook: `K_playbook = < pb_id, node_curr, V_completed >`.

#### 4. OPERATIONAL SEQUENCE
##### Fase 1: Gestione dell'Impatto Emotivo
1. Alla ricezione di `HEV_EMOTIONAL_OVERWHELM`:
   - Applicare la meta-regola SOS `[SOS-EMOTIONAL-OVERWHELM]`: transitare immediatamente a $q_H' = h_8$.
   - Incrementare di $+1$ il contatore cumulativo `c_overwhelm` nella tupla `M_metrics` (Cap 1.1.2).
   - Sospendere qualsiasi richiesta di azione o notifica incalzante verso l'utente.

##### Fase 2: Risoluzione Protetta del Rientro (`PO-16`)
1. Quando l'utente trasmette l'evento `HEV_STABILIZED` in stato $h_8$:
   - Invocare la funzione pura di risoluzione deterministica:
     ```text
     q_H' = ResolveNextHumanState(h8, pi_persistent(S).K_playbook)
     ```
2. **Logica di Risoluzione della Funzione Pura (Cap 2.3.2):**
   - Se `node_curr != null` e `MapNodeToHumanState(node_curr)` restituisce uno stato valido $h_{\text{target}} \in H_{\text{active}}$:
     ```text
     q_H' = h_target
     ```
   - Se `node_curr == null` o privo di mapping valido:
     ```text
     q_H' = STABILIZATION  (Fallback difensivo su h2 in H_active)
     ```
3. **Preservazione Assoluta del Progresso Storico:**
   - **È TASSATIVAMENTE VIETATO** azzerare o ridurre l'insieme dei nodi già completati $V_{\text{completed}}$.
   - **È TASSATIVAMENTE VIETATO** retrocedere l'utente a $h_2$ se i nodi in $V_{\text{completed}}$ attestano il già avvenuto soddisfacimento dei requisiti degli stati successivi ($h_3, h_4, h_5$).
4. **Consolidamento di Stato:**
   - Eseguire la transizione `ApplyValidated(S, t, PASS)`.

#### 5. VERIFICATION POINTS
1. Verificare che $q_H' \in H_{\text{active}} = \{ h_1, h_2, h_3, h_4, h_5, h_6, h_{11} \}$.
2. Verificare che l'insieme $V_{\text{completed}}$ sia rimasto intatto.
3. Verificare che la transizione ripristini la proposizione `JourneyProgressive == True`.

#### 6. EXPECTED RESULT / STATE
Rientro dell'utente nel percorso attivo allo stato corrispondente al nodo effettivo di avanzamento, con tutela della serenità emotiva e senza penalizzazioni di progresso.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la registrazione sul Ledger della transazione `HEV_STABILIZED` e la corretta transizione a $q_H' \in H_{\text{active}}$ conforme a `ResolveNextHumanState`.

#### 8. NON-CONFORMITY HANDLING
- Qualora un algoritmo o processo tenti di cancellare record da $V_{\text{completed}}$ o retrocedere ingiustificatamente l'utente, bloccare la transazione in ossequio a `RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`.

#### 9. ESCALATION
Intervento di supporto maieutico da parte dell'operatore umano qualora l'utente rimanga in $h_8$ senza stabilizzarsi.

#### 10. AUTHORITY CLASSIFICATION
* Regola `RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01` e fallback `PO-16`: `CORE-MANDATED`.
* Procedura metodologica di ricalibrazione: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Interfaccia di accoglienza e messaggistica a basso carico cognitivo per la fase di ricalibrazione.

#### 12. IMPLEMENTATION DEPENDENCIES
Implementazione esatta della funzione pura `ResolveNextHumanState`.

---

# SEZIONE 4: PROTOCOLLI DI SICUREZZA PER INTERAZIONI PROBABILISTICHE (DP-3)

---

### PROCEDURA SOP-F13: Gating Semantico e Parsing Sintattico EBNF di SML v2.0

```text
========================================================================================
SOP-ID: SOP-F13
NOME DELLA PROCEDURA: Gating Semantico e Parsing Sintattico EBNF di SML v2.0
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 4.4 (MapSMLToFSMEvent), Annex C
                (Grammatica EBNF, Semantic Safety Gate, REQ-PROBABILISTIC-INVARIANT-ALIGNMENT),
                Cap 8.2 (Err 80)
========================================================================================
```

#### 1. TRIGGER
Ricezione di un payload testuale generato da un modello probabilistico esterno (Livello 5 / LLM) a seguito di un'interazione conversazionale con l'utente.

#### 2. PRECONDITIONS
1. Il componente probabilistico (Livello 5) opera come pura scatola nera generativa priva di autorità normativa di scrittura sullo stato (Missione e, Cap 2.1).
2. La stringa testuale grezza è disponibile per l'ispezione al Livello 4.

#### 3. INPUTS
1. `raw_text`: Stringa di testo generata dall'LLM.
2. Contesto del caso e stato del Vault $\mathcal{V}_{vault}$.

#### 4. OPERATIONAL SEQUENCE
1. **Validazione Sintattica EBNF Pura (Fase 1 - Livello 4):**
   - Sottoporre `raw_text` al parser sintattico verificando la rigorosa conformità alla grammatica EBNF (Annex C.1):
     * Presenza dell'header `SML_VERSION: 2.0`
     * Presenza delle sezioni obbligatorie: `LISTEN_SUMMARY`, `LISTEN_AGENCY`, `CONVERSATION_OUTCOME`, `MAP_OVERVIEW`, `PROPOSED_TRANSITION`, `EVIDENCE`, `EVIDENCE_TYPE`.
     * Validità dei token enumerati (es. `CONVERSATION_OUTCOME in { "UNDERSTOOD", "NEEDS_REPHRASING", "OVERWHELMED", "MOTIVATED", "DECLINED_ACTION", "ASKED_FOR_HELP" }`).
2. **Gating di Sicurezza Semantica (Fase 2 - Livello 2 / Semantic Safety Gate):**
   - Ispezionare i contenuti estratti nel documento parsato `SMLDocumentParsed`:
   - **Filtro Anti-Allucinazione Amministrativa:** Se il testo o l'evidenza formulano asserzioni categorizzate nel dominio `FACTUAL_ADMINISTRATIVE` (es. requisiti di legge, bandi, scadenze inderogabili):
     * Verificare che l'asserzione sia ancorata a una fonte con stato `VERIFIED` presente nel Vault `V_vault` o a un nodo validato del Playbook.
     * Se l'asserzione amministrativa è priva di riscontro verificato $\to$ **SCARTARE L'INPUT**, sollevare l'evento di errore `EV_SML_FAIL` ed imporre al runtime la conversione dell'output in *Opzione Esplorativa* (Cap 4.5).
3. **Decodifica Deterministica dell'Evento FSM (Fase 3):**
   - Se i controlli sintattici e semantici hanno esito positivo, applicare la funzione pura deterministica `MapSMLToFSMEvent(doc)` (Cap 4.4):
     ```text
     MapSMLToFSMEvent(doc) :=
       (doc.conversation_outcome == "OVERWHELMED")                              ? HEV_EMOTIONAL_OVERWHELM :
       (doc.conversation_outcome == "NEEDS_REPHRASING")                         ? HEV_RECALIBRATION_REQ :
       (doc.conversation_outcome == "DECLINED_ACTION")                          ? HEV_PAUSE_REQUESTED :
       (doc.conversation_outcome == "ASKED_FOR_HELP")                           ? HEV_PREVENTIVE_SUPPORT_REQ :
       (doc.proposed_transition != "NONE" and doc.evidence_type == "DOCUMENT")   ? HEV_DOCS_OBTAINED :
       (doc.proposed_transition != "NONE" and doc.conversation_outcome == "MOTIVATED") ? HEV_STABILIZED :
       NONE
     ```
4. **Instradamento e Attribuzione dell'Attore:**
   - La transizione candidata viene instradata con attore `USER` (se confermata) o `SYSTEM`. **È TASSATIVAMENTE VIETATO** attribuire la transizione a un attore di tipo `LLM` (Cap 3.1).

#### 5. VERIFICATION POINTS
1. Verificare la validità sintattica rispetto alla grammatica EBNF formale.
2. Verificare che nessuna allucinazione amministrativa non verificata varchi il Safety Gate.
3. Verificare che l'evento FSM sia derivato unicamente dalla funzione pura `MapSMLToFSMEvent`.

#### 6. EXPECTED RESULT / STATE
Documento SML v2.0 parsato con successo e convertito deterministicamente in evento $\Sigma_H$, oppure input non conforme rigettato senza alcuna alterazione dello stato normativo.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la validazione sintattica EBNF e la registrazione dell'oggetto `SMLDocumentParsed` nei record di provenienza `M_prov` prima di qualsiasi transizione.

#### 8. NON-CONFORMITY HANDLING
- Se il testo viola la grammatica EBNF, scartare l'input ed emettere **Runtime Error Code 80 (`ERR_SML_PARSE_FAILED`)**.
- Se viene rilevata un'allucinazione amministrativa, emettere `EV_SML_FAIL`, incrementare il contatore `c_rephrase` in `M_metrics` e forzare la ricalibrazione comunicativa.

#### 9. ESCALATION
Segnalazione al team di manutenzione prompt/modelli qualora il tasso di errore SML superi le soglie fisiologiche di monitoraggio.

#### 10. AUTHORITY CLASSIFICATION
* Grammatica EBNF, Semantic Safety Gate e `MapSMLToFSMEvent`: `CORE-MANDATED`.
* Sequenza di parsing e validazione: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Proxy di inferenza LLM, middleware di parsing SML v2.0 e gateway API.

#### 12. IMPLEMENTATION DEPENDENCIES
Parser deterministico EBNF e libreria di pattern matching su stringhe UTF-8.

---

### PROCEDURA SOP-F14: Applicazione della Tassonomia di Guida e Non-Pregiudizio

```text
========================================================================================
SOP-ID: SOP-F14
NOME DELLA PROCEDURA: Applicazione della Tassonomia di Guida e Non-Pregiudizio
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 4.5 (Tassonomia della Guida),
                Cap 4.5.1 (RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01),
                Cap 0.2.1 (INV-ANTI-PATERNALISM-01)
========================================================================================
```

#### 1. TRIGGER
Formulazione, selezione o erogazione di raccomandazioni, opzioni operative o collegamenti verso servizi esterni e comunità reali destinati all'utente.

#### 2. PRECONDITIONS
1. Il runtime si trova in uno stato di interazione attivo.
2. Il livello di supervisione HOBM associato all'azione è definito in `O_bound`.

#### 3. INPUTS
1. Testo della proposta o notifica da erogare.
2. Tipologia di interazione proposta (`GuidanceType in { AUTHORITATIVE_DIRECTIVE, MOTIVATED_RECOMMENDATION, EXPLORATORY_OPTION }`).

#### 4. OPERATIONAL SEQUENCE
1. **Verifica di Conformità della Tassonomia di Guida (Cap 4.5):**
   - **Direttiva Autoritativa (`AUTHORITATIVE_DIRECTIVE`):** Verificare che sia utilizzata **esclusivamente** in condizioni di rischio imminente per la sicurezza o emergenza acuta (`O_bound == PROFESSIONAL_INTERVENTION_REQUIRED`).
   - **Raccomandazione Motivata (`MOTIVATED_RECOMMENDATION`):** Verificare che espliciti chiaramente la motivazione, sia revocabile dall'utente e richieda conferma (`USER_CONFIRMED_STEP`).
   - **Opzione Esplorativa (`EXPLORATORY_OPTION`):** Verificare che presenti le alternative in modo neutrale e non giudicante.
2. **Applicazione della Regola di Non-Pregiudizio (`RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01`):**
   - Qualora l'utente rifiuti o rinvii un suggerimento di collegamento esterno emettendo `HEV_PAUSE_REQUESTED` o `HEV_DECLINE_ALL`:
     ```text
     Capabilities(Obs(S_dopo)) == Capabilities(Obs(S_prima))
     ```
   - **Divieto Assoluto di Decurtazione:** Verificare che nessun diritto, permesso o funzionalità accessibile all'utente venga ridotta a seguito del rifiuto.
3. **Divieto di Ultimatum:**
   - Verificare che nessun nodo del Playbook condizioni la progressione all'accettazione di interazioni esterne, salvo che non sia normativamente tipizzato come `REQUIRED_FOR_SYSTEM_STATE`.

#### 5. VERIFICATION POINTS
1. Verificare che nessuna direttiva autoritativa sia impiegata al di fuori dei casi di emergenza accertata.
2. Verificare che a seguito di un rifiuto dell'utente l'insieme `Capabilities(Obs(S))` rimanga rigorosamente invariato.
3. Verificare l'assenza di penalizzazioni o messaggi colpevolizzanti.

#### 6. EXPECTED RESULT / STATE
Interazione rispettosa dell'autonomia e della dignità dell'utente; piena tutela contro pratiche manipolatorie o paternalistiche.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la conformità della tipizzazione dei messaggi e l'invarianza matematica delle capacità in `Obs(S)` a fronte di eventi di rifiuto dell'utente.

#### 8. NON-CONFORMITY HANDLING
- Qualora un template o una regola di policy violi il principio di non-pregiudizio (es. bloccando l'utente a fronte del rifiuto di un'opzione facoltativa), rigettare la policy in fase di compilazione con esito `DENY`.

#### 9. ESCALATION
Segnalazione al Comitato Etico e Metodologico in caso di riscontro di pattern comunicativi paternalistici nelle interfacce client.

#### 10. AUTHORITY CLASSIFICATION
* Regola di non-pregiudizio e tassonomia della guida: `CORE-MANDATED` / `OPERATIONAL_GUARDRAIL`.
* Linee guida di redazione dei messaggi: `SOP-CONVENTION`.

#### 11. BLUEPRINT DEPENDENCIES
Template grafici e componenti UI di presentazione delle opzioni di guida.

#### 12. IMPLEMENTATION DEPENDENCIES
Filtro logico di compilazione policy e validatore delle capacità in `Obs(S)`.

---

# SEZIONE 5: GOVERNANCE DELLE POLICY, SUPERVISIONE ED ESCALATION (DP-4)

---

### PROCEDURA SOP-F12: Compilazione, Firma e Composizione Disgiunta Policy Bundle

```text
========================================================================================
SOP-ID: SOP-F12
NOME DELLA PROCEDURA: Compilazione, Firma e Composizione Disgiunta Policy Bundle
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 4.1 (Stratificazione Policy),
                Cap 4.2 (PolicyBundle P), Cap 4.3 (ComposePolicy, REQ-POLICY-SEMVER-DERIVATION),
                Cap 10.2.2 (DecisionProof)
========================================================================================
```

#### 1. TRIGGER
Rilascio, aggiornamento o composizione algebrica di bundle di regole operative e vincoli di sicurezza destinati all'esecuzione nel Policy Guidance Engine (Livello 2).

#### 2. PRECONDITIONS
1. Le specifiche normative in linguaggio naturale controllato sono verificate e approvate dall'Autorità di Policy.
2. Le chiavi private di firma Ed25519 dell'Autorità emittente sono disponibili nel modulo crittografico autorizzato.
3. Lo spazio dei parametri di configurazione $\Theta$ è interamente valorizzato.

#### 3. INPUTS
1. Policy sorgente singole o tuple di bundle da comporre: $\mathcal{P}_1, \mathcal{P}_2$.
2. Spazio dei parametri: $\Theta$.
3. Chiave privata di firma dell'Autorità di Policy: $K_{\text{private, policy}}$.

#### 4. OPERATIONAL SEQUENCE
1. **Compilazione del Predicato Esecutivo Puro (Livello 2):**
   - Tradurre le regole normative nel predicato deterministico puro:
     ```text
     R_exec : S_space * T_tx -> { ALLOW, DENY, RECALIBRATE }
     ```
2. **Assegnazione di Identificatore e Versione:**
   - Assegnare `PolicyID` univoco conforme allo standard UUIDv7 (Cap 4.2).
   - Assegnare la tupla di versione semantica: `Version := < Major, Minor, Patch > in Nat * Nat * Nat`.
3. **Composizione Algebrica Disgiunta ($\mathcal{P}_{\text{comp}} = \mathcal{P}_1 \oplus \mathcal{P}_2$):**
   - Se l'operazione richiede la fusione di due bundle:
   - **Ordinamento Lessicografico Binario dei Digest:** Estrarre i digest a 32 byte $A = \mathcal{P}_1.\text{digest}$ e $B = \mathcal{P}_2.\text{digest}$ ed ordinarli:
     ```text
     A_sorted <= B_sorted <===> ByteLexicographicalCompare(A, B) <= 0
     ```
   - **Calcolo del Digest Composito Immutabile:**
     ```text
     CompositePolicyDigest := SHA256( concat(A_sorted, B_sorted) )
     ```
   - **Derivazione della Versione Semantica Composita (`REQ-POLICY-SEMVER-DERIVATION`):**
     ```text
     CompositePolicyVersion :=
       (v1 <=_compat v2)              ? v2 :
       (v2 <=_compat v1)              ? v1 :
       < max(M1, M2) + 1, 0, 0 >      (Incompatibilita' Major con M1 != M2)
     ```
   - **Valutazione Composita Conservativa (`DENY-OVERRIDES`):**
     ```text
     R_exec,comp(S, t) :=
       (R_exec,1(S, t) == DENY or R_exec,2(S, t) == DENY) ? DENY :
       (R_exec,1(S, t) == RECALIBRATE or R_exec,2(S, t) == RECALIBRATE) ? RECALIBRATE :
       (R_exec,1(S, t) == ALLOW and R_exec,2(S, t) == ALLOW) ? ALLOW :
       DENY
     ```
4. **Apposizione del DecisionProof Crittografico (Cap 10.2.2):**
   - Serializzare canonicamente il bundle composito: `Canon(P_comp)`.
   - Calcolare la firma digitale Ed25519 a 64 byte sulla concatenazione binaria e formattarla come stringa esadecimale UTF-8 di 128 caratteri:
     ```text
     DecisionProof := HexEncode( Sign_Ed25519(K_private, concat(Canon(P_comp), Canon(t))) )
     ```

#### 5. VERIFICATION POINTS
1. Verificare che l'ordinamento binario dei digest rispetti il confronto lessicografico byte-per-byte prima del calcolo SHA-256.
2. Verificare che la regola `DENY-OVERRIDES` prevalga rigorosamente su esiti `ALLOW` o `RECALIBRATE`.
3. Verificare che `DecisionProof` sia una stringa esadecimale valida di esattamente 128 caratteri UTF-8.

#### 6. EXPECTED RESULT / STATE
Bundle di policy esecutivo `P_comp` compilato, firmato e verificato, pronto per essere associato allo stato primario `P_active`.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la validità della firma crittografica `DecisionProof`, la riproducibilità bit-identica del `CompositePolicyDigest` e la corretta applicazione della regola SemVer composita.

#### 8. NON-CONFORMITY HANDLING
- Qualora la verifica di firma Ed25519 fallisca, bloccare il deployment del bundle ed emettere **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`)**.
- In caso di parametri $\Theta$ malformati o float presenti nelle soglie, rigettare con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 9. ESCALATION
Rinvio all'Autorità di Emissione Policy in caso di incongruenze logiche tra predicati composti.

#### 10. AUTHORITY CLASSIFICATION
* Regole di composizione, SemVer `REQ-POLICY-SEMVER-DERIVATION` e `DecisionProof`: `CORE-MANDATED`.
* Sequenza metodologica di compilazione: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Repository distribuito dei Policy Bundle e registry delle chiavi pubbliche di verifica.

#### 12. IMPLEMENTATION DEPENDENCIES
Libreria Ed25519 conforme a SC-JCS-1 e modulo comparatore di byte lessicografico.

---

### PROCEDURA SOP-F15: Esecuzione di Human Override da Operatore Autenticato

```text
========================================================================================
SOP-ID: SOP-F15
NOME DELLA PROCEDURA: Esecuzione di Human Override da Operatore Autenticato
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 4.6 (5 Principi Fondamentali di Override),
                Cap 3.2.1 ([SOS-OPERATOR-OVERRIDE]), Cap 3.1 (Matrice Autorizzazioni)
========================================================================================
```

#### 1. TRIGGER
Automa di sicurezza di runtime bloccato nello stato `q == OPERATOR_REQUIRED` (a seguito di timeout da recoverable failure o richiesta esplicita HOBM) che richiede intervento manuale autorizzato per il ripristino.

#### 2. PRECONDITIONS
1. L'automa di sicurezza è in: `pi_Q(S) == OPERATOR_REQUIRED`.
2. L'operatore umano dispone del permesso formale `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. La chiave crittografica di firma dell'operatore è attiva e censita nel registry di sistema.

#### 3. INPUTS
1. `actor_id`: Identificatore univoco dell'operatore umano (`type(actor) == OPERATOR`).
2. `reason_text`: Stringa testuale non vuota attestante la motivazione dell'intervento.
3. Payload della transizione di correzione/ripristino.
4. Firma digitale Ed25519 dell'operatore calcolata su `TransactionBody`.

#### 4. OPERATIONAL SEQUENCE
1. **Verifica dei 5 Principi Normativi di Override (Cap 4.6):**
   - **Principio 1 (Tracciabilità Assoluta):** Predisporre la costruzione della transizione formale $t$ da registrare immutabilmente sul Ledger.
   - **Principio 2 (Autenticazione Forte):** Verificare la firma digitale Ed25519 e la titolarità del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
   - **Principio 3 (Spiegabilità Obbligatoria):** Verificare che il campo `reason_text` contenga una stringa non vuota (`length(trim(reason_text)) > 0`).
   - **Principio 4 (Inalterabilità Storica):** Verificare che l'azione operi esclusivamente sullo stato proiettato corrente $S_N$, senza mutare o cancellare transizioni storiche pregresse ($t_0 \dots t_{N-1}$).
   - **Principio 5 (Rispetto del Consenso):** Verificare che l'override non forzi azioni in violazione del consenso espresso dall'utente in `Q_consent` (salvo livello HOBM `PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Costruzione della Transazione di Override:**
   - Impostare `event = EV_OVERRIDE`, `actor = OPERATOR`, includendo `reason_text` nell'involucro di payload.
3. **Validazione Ambientale ed Esecuzione SOS (`[SOS-OPERATOR-OVERRIDE]`):**
   - Sottoporre $t$ a `ValidateEnvironment(S, t, E) == PASS`.
   - Applicare la meta-regola deterministica:
     ```text
     < OPERATOR_REQUIRED, q_H, S > --t/Sys--> < NORMAL, q_H, ApplyValidated(S, t, PASS) >
     ```
4. **Preservazione dello Stato Umano (`INV-DECOUPLING-01`):**
   - Verificare che lo stato dell'automa umano $q_H$ e la proposizione `UserEngaged` rimangano rigorosamente inalterati durante il ripristino tecnico.

#### 5. VERIFICATION POINTS
1. Verificare che `pi_Q(S') == NORMAL`.
2. Verificare che `pi_Q_H(S') == pi_Q_H(S)` (disaccoppiamento unidirezionale garantito).
3. Verificare che la motivazione testuale sia persistita nel corpo della transazione sul Ledger.

#### 6. EXPECTED RESULT / STATE
Automa di sicurezza ripristinato allo stato nominale `NORMAL`; blocco operativo rimosso; tracciabilità forense completa dell'intervento umano consolidata nel Ledger.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la persistenza sul Ledger della transazione `EV_OVERRIDE` recante la firma Ed25519 dell'operatore, la stringa di motivazione non vuota e la transizione verificata a `NORMAL`.

#### 8. NON-CONFORMITY HANDLING
- Se la firma dell'operatore è invalida o manca il permesso di override, rifiutare con **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`)**.
- Se il campo motivazione `reason_text` è vuoto o omesso, respingere l'azione con **Runtime Error Code 86 (`ERR_HOBM_BOUNDARY_VIOLATION`)**.

#### 9. ESCALATION
Notifica al Responsabile Operativo di Sistema in caso di tentativi non autorizzati di override.

#### 10. AUTHORITY CLASSIFICATION
* 5 Principi di Human Override e meta-regola SOS: `CORE-MANDATED`.
* Layout del modulo di inserimento motivazione: `SOP-CONVENTION`.
* Assegnazione turni e reperibilità operatori: `ORG-POLICY`.

#### 11. BLUEPRINT DEPENDENCIES
Dashboard/Console per operatori accreditati e modulo di gestione directory permessi RBAC.

#### 12. IMPLEMENTATION DEPENDENCIES
Validatore di campi stringa non vuoti e modulo di verifica firme crittografiche.

---

### PROCEDURA SOP-F16: Riparazione Compensativa e Uscita da Security Lockdown

```text
========================================================================================
SOP-ID: SOP-F16
NOME DELLA PROCEDURA: Riparazione Compensativa e Uscita da Security Lockdown
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 3.2.1 ([SOS-COMPENSATIVE-REPAIR]),
                Cap 8.2 (Err 77), Cap 10.4 (delta_M), Cap 9.2.6 (CTL Trap-Free Safety)
========================================================================================
```

#### 1. TRIGGER
Automa di sicurezza di runtime entrato nello stato critico `q == SECURITY_LOCKDOWN` (o `q == SAFE_READ_ONLY_MODE`) a seguito di rilevazione di corruzione crittografica della catena di hash (`EV_HASH_CORRUPT`) o guasto irreversibile di coerenza.

#### 2. PRECONDITIONS
1. L'automa di sicurezza si trova in: `pi_Q(S) in { SECURITY_LOCKDOWN, SAFE_READ_ONLY_MODE }`.
2. L'analisi tecnica di laboratorio ha isolato la causa della violazione ed ha formulato una patch compensativa formale $p$.
3. L'operatore dispone di autorizzazione di disaster recovery e firma digitale accreditata.

#### 3. INPUTS
1. Payload della patch compensativa: `p`.
2. Predicato di validità della patch: `ValidRepairPatch(p) == True`.
3. Transazione firmata dall'operatore recante `event = EV_REPAIR`.

#### 4. OPERATIONAL SEQUENCE
1. **Ispezione e Diagnostica del Blocco:**
   - Ispezionare il payload di errore generato da `BuildErrorTx` sul Ledger per identificare la transazione o il digest disallineato.
2. **Generazione e Validazione della Patch Compensativa:**
   - Costruire la patch $p$ destinata a riallineare le proiezioni di stato senza cancellare la cronologia degli eventi.
   - Verificare formalmente il predicato di validità:
     ```text
     ValidRepairPatch(p) == True
     ```
3. **Applicazione della Meta-Regola SOS di Riparazione (`[SOS-COMPENSATIVE-REPAIR]`):**
   - Eseguire la transizione di ripristino compensativo:
     ```text
     < q, q_H, S > --t/Sys--> < NORMAL, q_H, ApplyCompensativeRepair(S, p) >
     ```
4. **Riconciliazione dello Stato Primario:**
   - La funzione pura `ApplyCompensativeRepair(S, p)` rigenera la continuità dell'hash chain consolidando la patch come nuova transizione $t_{repair}$ con digest valido $H_{repair}$.
   - L'automa di sicurezza $M$ transita formalmente da `SECURITY_LOCKDOWN` a `NORMAL`.

#### 5. VERIFICATION POINTS
1. Verificare che `pi_Q(S') == NORMAL`.
2. Verificare che la catena di hash $H_N$ risulti nuovamente valida e continua a partire da $H_{repair}$.
3. Verificare che la proprietà `CTL Trap-Free Safety` sia rispettata:
   ```text
   AG ( StateIsSecurityLockdown ===> EF (StateIsNormal or StateIsReadOnly) )
   ```

#### 6. EXPECTED RESULT / STATE
Blocco di sicurezza rimosso; integrità crittografica del Ledger ripristinata tramite transazione compensativa trasparente; automa di sicurezza tornato in `NORMAL`.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la persistenza nel Ledger della transazione `EV_REPAIR` recante il payload della patch validata `ValidRepairPatch(p)` e l'avvenuta transizione verificata a `NORMAL`.

#### 8. NON-CONFORMITY HANDLING
- Se la patch non supera il predicato di validità (`ValidRepairPatch(p) != True`), rifiutare la transazione e **mantenere inderogabilmente il sistema in `SECURITY_LOCKDOWN`**.

#### 9. ESCALATION
Convocazione immediata del Comitato di Sicurezza e Architettura in caso di impossibilità di formulare una patch compensativa valida.

#### 10. AUTHORITY CLASSIFICATION
* Meta-regola SOS `[SOS-COMPENSATIVE-REPAIR]` e modello $\delta_M$: `CORE-MANDATED`.
* Processo di analisi e approvazione della patch: `ORG-POLICY`.

#### 11. BLUEPRINT DEPENDENCIES
Console di emergenza per disaster recovery isolata e tooling di generazione patch formali.

#### 12. IMPLEMENTATION DEPENDENCIES
Funzione pura `ApplyCompensativeRepair` e validatore del predicato `ValidRepairPatch`.

---

# SEZIONE 6: AUDIT, CONCORRENZA E VERIFICA FORENSE DEL LEDGER (DP-5 & DP-6)

---

### PROCEDURA SOP-F04: Validazione Ambientale Ingress, Fencing e Controllo Clock

```text
========================================================================================
SOP-ID: SOP-F04
NOME DELLA PROCEDURA: Validazione Ambientale Ingress, Fencing e Controllo Clock
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 1.6.1 (ValidateEnvironment),
                Cap 9.1 (REQ-CLUSTER-CLOCK-SYNC), Cap 8.2 (Err 71, 78, 79)
========================================================================================
```

#### 1. TRIGGER
Presentazione di una qualsiasi transazione candidata $t \in T_{tx}$ al gate di ingresso del Kernel deterministico prima della sua valutazione di stato.

#### 2. PRECONDITIONS
1. La transazione $t := \langle \text{TransactionBody}, \text{execution\_envelope}, \text{proof} \rangle$ è formata e serializzabile.
2. L'ambiente operativo $E$ rende disponibili il timestamp fisico $E.t_{\text{wall}}$, il registry delle chiavi pubbliche $E.K_{\text{pubkey\_registry}}$ e il gestore dei lease $E.\text{LeaseManager}$.

#### 3. INPUTS
1. Stato corrente $S$.
2. Transazione candidata $t$.
3. Contesto ambientale $E$.

#### 4. OPERATIONAL SEQUENCE
1. **Ispezione Crittografica della Firma Digitale:**
   - Verificare la firma presente in `t.proof`:
     ```text
     VerifySignature(t.proof, t.TransactionBody, E.K_pubkey_registry) == TRUE
     ```
   - Se la verifica fallisce $\to$ interrompere ed emettere esito `ERR_SIG`.
2. **Verifica della Tolleranza di Disallineamento Temporale (Clock Skew):**
   - Calcolare la differenza assoluta tra il timestamp della transazione e l'orologio locale:
     ```text
     Delta_t = abs(t.timestamp - E.t_wall)
     ```
   - Verificare la condizione: `Delta_t <= Theta.theta_max_clock_skew`.
   - Se $\Delta t > \Theta.\theta_{\text{max\_clock\_skew}} \to$ interrompere ed emettere esito `ERR_CLOCK`.
3. **Verifica della Validità del Lease di Concorrenza (Fencing Token):**
   - Verificare la validità del token nel gestore dei lease:
     ```text
     E.LeaseManager.IsTokenValid(pi_internal(S).F_lease.fencing_token) == TRUE
     ```
   - Se il token è scaduto o non valido $\to$ interrompere ed emettere esito `ERR_LEASE`.
4. **Verifica di Sincronizzazione di Cluster (`REQ-CLUSTER-CLOCK-SYNC`):**
   - Verificare periodicamente che la sincronizzazione tra nodi del cluster rispetti:
     ```text
     max_{i,j} abs(t_wall_i - t_wall_j) <= delta_clock  con  delta_clock < (1/2) * Theta.theta_max_clock_skew
     ```
5. **Emissione del Risultato:**
   - Se tutti i controlli hanno esito positivo, emettere il risultato unificato `PASS`, autorizzando l'invocazione di `ApplyValidated(S, t, PASS)`.

#### 5. VERIFICATION POINTS
1. Verificare che nessuna transazione con firma invalida o assente superi il gate di ingresso.
2. Verificare che il clock skew sia rigidamente contenuto entro $\theta_{\text{max\_clock\_skew}}$.
3. Verificare che ogni transazione comporti l'incremento strettamente monotonico del `fencing_token`.

#### 6. EXPECTED RESULT / STATE
Transazione validata con esito `PASS` ed ammessa alla mutazione di stato deterministica, oppure rigetto formale con instradamento del corrispondente errore.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la rispondenza deterministica del predicato puro `ValidateEnvironment(S, t, E)` rispetto alle condizioni temporali, crittografiche e di concorrenza.

#### 8. NON-CONFORMITY HANDLING
- In caso di esito `ERR_SIG`, sollevare **Runtime Error Code 71 (`ERR_INVALID_CRYPTO_SIGNATURE`)**.
- In caso di esito `ERR_LEASE`, sollevare **Runtime Error Code 78 (`ERR_LEASE_ACQUISITION_TIMEOUT`)**.
- In caso di esito `ERR_CLOCK`, sollevare **Runtime Error Code 79 (`ERR_CLOCK_SKEW_EXCEEDED`)**.

#### 9. ESCALATION
Segnalazione all'Amministratore di Rete/Cluster qualora si verifichino errori sistematici di clock skew (`ERR_CLOCK`).

#### 10. AUTHORITY CLASSIFICATION
* Predicato `ValidateEnvironment`, codici errore 71, 78, 79 e `REQ-CLUSTER-CLOCK-SYNC`: `CORE-MANDATED`.
* Sequenza procedurale di gate: `VERIFICATION PROCEDURE`.
* Meccanismo fisico di sincronizzazione temporale (NTP/PTP): `BLUEPRINT-DELEGATED`.

#### 11. BLUEPRINT DEPENDENCIES
Infrastruttura di clock sync di cluster e modulo Lease Manager per la concorrenza distribuita.

#### 12. IMPLEMENTATION DEPENDENCIES
Routine di verifica crittografica e comparatori di tempo a 64 bit.

---

### PROCEDURA SOP-F05: Monitoraggio e Calcolo dell'Indice Proxy di Agency (AGI_proxy)

```text
========================================================================================
SOP-ID: SOP-F05
NOME DELLA PROCEDURA: Monitoraggio e Calcolo dell'Indice Proxy di Agency (AGI_proxy)
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 1.7 (Calcolo Deterministico AGI in Basis Points),
                Cap 1.7.1 (INV-AGI-DESCRIPTIVE-ISOLATION), Cap 10.2.1
========================================================================================
```

#### 1. TRIGGER
Aggiornamento dello stato del caso a seguito di una transazione valida o richiesta di ispezione descrittiva del livello di autonomia operativa raggiunto dall'utente.

#### 2. PRECONDITIONS
1. Lo stato primario $S$ è valido e proiettabile.
2. I contatori cumulativi $\mathcal{M}_{\text{metrics}} = \langle c_{\text{interaction}}, c_{\text{rephrase}}, c_{\text{ambiguity}}, c_{\text{overwhelm}} \rangle \in \mathbb{N}^4$ sono aggiornati.
3. I pesi di configurazione $w_1, w_2, w_3 \in [0, 10000]$ sono interi e soddisfano $w_1 + w_2 + w_3 == 10000$.

#### 3. INPUTS
1. Stato primario corrente $S$.
2. Pesi interi di ponderazione: $w_1, w_2, w_3$.

#### 4. OPERATIONAL SEQUENCE
1. **Controllo di Invarianza per Stati Non-Attivi (`DEF-AGI-PAUSED-STATE-INVARIANCE`):**
   - Se $\pi_{Q\_H}(S_N) \in \{ \text{HUMAN\_PAUSED}, \text{HUMAN\_DECLINED\_ASSISTANCE} \}$:
     ```text
     AGI_proxy(S_N) := AGI_proxy(S_{N-1})
     ```
     *(Il calcolo dinamico viene sospeso preservando il punteggio precedente).*
2. **Calcolo Deterministico in Aritmetica Intera Sicura $I_{\text{safe}}$ (Cap 1.7.3):**
   - Se l'automa umano è in uno stato attivo, calcolare le tre componenti pure in Basis Points $[0, 10000]$ applicando saturazione a $10^6$ e troncamento intero $\lfloor \dots \rfloor$:
   - **ClarityScore in Basis Points:**
     ```text
     ClarityScore_bp(S) :=
       (c_interaction == 0) ? 10000 :
       max(0, 10000 - floor( ((c_rephrase + c_ambiguity + 2 * c_overwhelm) * 10000) / max(1, c_interaction) ))
     ```
   - **ActionExecutionRatio in Basis Points:**
     ```text
     ActionExecutionRatio_bp(S) :=
       (pb_id == null or |V_P| == 0) ? 0 :
       floor( (|{ id in V_completed | exists v in G_P.V_P t.c. v.node_id == id }| * 10000) / |V_P| )
     ```
   - **DependencyReductionScore in Basis Points:**
     ```text
     DependencyReductionScore_bp(S) :=
       (|V_active_completed| == 0) ? 0 :
       floor( (|{ id in V_active_completed | exists v in G_P.V_P t.c. v.node_id == id and IsEmpoweredAction(v, S) }| * 10000) / |V_active_completed| )
     ```
3. **Aggregazione Ponderata Pura:**
   - Calcolare l'indice sintetico finale in Basis Points interi:
     ```text
     AGI_computed(S) := floor( (w1 * ClarityScore_bp(S) + w2 * ActionExecutionRatio_bp(S) + w3 * DependencyReductionScore_bp(S)) / 10000 )
     ```
4. **Verifica di Isolamento Descrittivo Assoluto (`INV-AGI-DESCRIPTIVE-ISOLATION`):**
   - Verificare che il valore calcolato risieda unicamente nella vista derivata $\mathcal{S}_{\text{derived}}$ e **NON sia utilizzato come parametro decisionale o condizione di guardia** da alcun predicato di policy $\mathcal{R}_{\text{exec}}(S, t)$.

#### 5. VERIFICATION POINTS
1. Verificare che il calcolo sia eseguito esclusivamente tramite aritmetica intera a 64 bit `I_safe`, senza impiego di tipi floating-point o notazione scientifica.
2. Verificare che il valore finale appartenga rigidamente all'intervallo chiuso $[0, 10000]$.
3. Verificare che `R_exec` mantenga zero dipendenze funzionali rispetto ad `AGI_proxy`.

#### 6. EXPECTED RESULT / STATE
Indice `AGI_proxy` aggiornato ed esposto nella vista di telemetria e audit senza alcun effetto collaterale sulle decisioni di policy del Kernel.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la riproducibilità matematica esatta dell'indice in Basis Points e l'assoluta assenza di influenza del punteggio sui cancelli di sicurezza del Policy Guidance Engine.

#### 8. NON-CONFORMITY HANDLING
- Qualora un modulo software introduca numeri floating point o tenti di condizionare l'accesso a un diritto/azione al valore dell'indice AGI, bloccare la configurazione con **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 9. ESCALATION
Segnalazione al team di auditing etico qualora si riscontrino trend anomali di sopraffazione prolungata (`c_overwhelm`).

#### 10. AUTHORITY CLASSIFICATION
* Formula algebrica in Basis Points, $I_{\text{safe}}$ e `INV-AGI-DESCRIPTIVE-ISOLATION`: `CORE-MANDATED`.
* Monitoraggio telemetrico: `VERIFICATION PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Pipeline di metriche per la visualizzazione dell'andamento del percorso nelle dashboard di monitoraggio.

#### 12. IMPLEMENTATION DEPENDENCIES
Funzioni aritmetiche a 64 bit sicure con operatore di divisione intera / troncamento `floor`.

---

### PROCEDURA SOP-F17: Ispezione della Catena di Hash e Replay Storico Deterministico

```text
========================================================================================
SOP-ID: SOP-F17
NOME DELLA PROCEDURA: Ispezione della Catena di Hash e Replay Storico Deterministico
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 1.4.4 (INVARIANT-LEDGER-PROJECTION-CONSISTENCY),
                Cap 7.1 (Canon), Cap 7.2 (Catena Hash HN), Cap 6.1.1 (Replay Compatibility),
                Cap 10.3 (Profilo SC-JCS-1)
========================================================================================
```

#### 1. TRIGGER
Attività periodica di audit di sicurezza, verifica di integrità del Ledger immutabile o procedura di ricostruzione deterministica dello stato primario $P(L)$ da storico transazioni.

#### 2. PRECONDITIONS
1. La sequenza delle transazioni persistite sul Ledger $L := \langle t_0, t_1, \dots, t_N \rangle$ è accessibile per la scansione sequenziale.
2. Il modulo di canonizzazione deterministica conforme a SC-JCS-1 (Cap 10.3) è inizializzato.

#### 3. INPUTS
1. Sequenza completa del Ledger $L$.
2. Stato iniziale di genesi $s_0$.

#### 4. OPERATIONAL SEQUENCE
1. **Verifica del Blocco di Genesi:**
   - Estrarre $t_0$ e verificare che `t_0.prev_hash == 0_D256` (32 byte 0x00).
   - Calcolare $H_0 = SHA256(Canon(TransactionBody_0))$.
   - Inizializzare lo stato di verifica: $S_{\text{verif}, 0} = ApplyValidated(s_0, t_0, PASS)$.
2. **Scansione Sequenziale della Catena di Hash ($i = 1 \dots N$):**
   - Per ciascuna transazione $t_i$:
   - **Verifica del Puntatore Indietro:** Accertare che:
     ```text
     t_i.prev_hash == H_{i-1}
     ```
   - **Canonizzazione Deterministica SC-JCS-1:** Serializzare $t_i$ applicando rigorosamente l'eliminazione spaziature, l'escaping standard, la normalizzazione NFC e l'ordinamento lessicografico `Order_SC` (Cap 10.3).
   - **Ricalcolo Checksum SHA-256:** Calcolare:
     ```text
     H_i = SHA256( Canon(TransactionBody_i) )
     ```
   - **Verifica Compatibilità di Replay (`RULE-HISTORICAL-REPLAY-COMPATIBILITY`):** Verificare che la transizione sia rieseguita applicando le regole SOS e gli schemi corrispondenti a `t_i.runtime_profile`.
   - **Riesecuzione Transizione Pura:** Calcolare $S_{\text{verif}, i} = ApplyValidated(S_{\text{verif}, i-1}, t_i, PASS)$.
3. **Riconciliazione dello Stato Proiettato Finale:**
   - Verificare l'invariante fondamentale di consistenza (Cap 1.4.4):
     ```text
     P(L) ==_CoreState S_verif,N
     ```
   - Verificare che `pi_internal(S_verif,N).last_hash == H_N` e `pi_internal(S_verif,N).seq_num == N`.

#### 5. VERIFICATION POINTS
1. Verificare che ogni singolo puntatore `prev_hash` coincida esattamente con il digest ricalcolato della transazione precedente.
2. Verificare che non siano presenti salti di numerazione in `seq_num`.
3. Verificare la perfetta coincidenza semantica dello stato ricostruito: $P(L) \equiv_{\text{CoreState}} S_{\text{corrente}}$.

#### 6. EXPECTED RESULT / STATE
Integrità crittografica della catena di hash validata al 100%; esatta riproducibilità deterministica dello stato primario confermata senza discrepanze.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la continuità ininterrotta della catena crittografica SHA-256 e l'identità matematica tra lo stato primario persistito e il risultato del replay puro $P(L)$.

#### 8. NON-CONFORMITY HANDLING
- Qualora venga rilevata anche una sola discrepanza di hash ($H_i \ne t_{i+1}.\text{prev\_hash}$) o alterazione storica, **bloccare immediatamente l'elaborazione**, generare la transizione di sicurezza tramite `BuildErrorTx` recante `EV_HASH_CORRUPT` ed emettere **Runtime Error Code 77 (`ERR_SECURITY_VIOLATION`)**, forzando la transizione istantanea dell'automa a `SECURITY_LOCKDOWN`.

#### 9. ESCALATION
Segnalazione immediata al Security Officer e all'Auditor Capo con blocco operativo del cluster in caso di violazione dell'integrità del Ledger.

#### 10. AUTHORITY CLASSIFICATION
* Invariante di consistenza del Ledger, SC-JCS-1, formula hash $H_N$ e codice errore 77: `CORE-MANDATED`.
* Procedura di replay ed ispezione: `VERIFICATION PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Tooling di scansione batch del Ledger, connettori di lettura storage e runner di replay forense.

#### 12. IMPLEMENTATION DEPENDENCIES
Serializzatore canonico conforme a SC-JCS-1 e libreria di calcolo SHA-256 bit-identica.

---

### PROCEDURA SOP-F18: Gestione ed Instradamento dei Runtime Error Codes (70–89)

```text
========================================================================================
SOP-ID: SOP-F18
NOME DELLA PROCEDURA: Gestione ed Instradamento dei Runtime Error Codes (70–89)
CORE REFERENCE: SCINTILLA Core v4.5.6 — Cap 8.2 (Tassonomia Error Codes 70-89),
                Cap 1.4.2 (BuildErrorTx, IsLockdownEvent), Cap 1.6.3 (REQ-APPLY-TOTALITY)
========================================================================================
```

#### 1. TRIGGER
Rilevazione di un fallimento di validazione, errore crittografico, violazione di guardie o eccezione di runtime durante l'elaborazione di una transazione.

#### 2. PRECONDITIONS
1. L'evento di errore o la condizione eccezionale è intercettata dal runtime prima di qualsiasi mutazione non controllata di memoria.

#### 3. INPUTS
1. Condizione di errore rilevata.
2. Stato corrente $S$.
3. Evento originario $\sigma_{\text{orig}}$.
4. Contesto ambientale $E$.

#### 4. OPERATIONAL SEQUENCE
1. **Mappatura Rigorosa del Codice di Errore (Cap 8.2):**
   - Assegnare alla condizione di errore l'esatto identificatore numerico appartenente allo spazio riservato `70–89`:
   - **Sotto-insieme Crittografia, Sicurezza e Consenso (70–79):**
     * `71` $\to$ `ERR_INVALID_CRYPTO_SIGNATURE`: Firma Ed25519 non valida.
     * `72` $\to$ `ERR_CONSENT_REVOKED_VIOLATION`: Tentativo di accesso a risorsa revocata.
     * `73` $\to$ `ERR_INFRASTRUCTURE_IO`: Guasto I/O, perdita connessione Ledger o lease.
     * `77` $\to$ `ERR_SECURITY_VIOLATION`: Corruzione catena hash $H_N$ o manomissione storico.
     * `78` $\to$ `ERR_LEASE_ACQUISITION_TIMEOUT`: Scadenza lease di concorrenza durante mutazione.
     * `79` $\to$ `ERR_CLOCK_SKEW_EXCEEDED`: Disallineamento temporale oltre $\theta_{\text{max\_clock\_skew}}$.
   - **Sotto-insieme Validazione, Parsing, Flussi e KMS (80–89):**
     * `80` $\to$ `ERR_SML_PARSE_FAILED`: Fallimento validazione sintattica EBNF SML v2.0.
     * `81` $\to$ `ERR_HUMAN_INACTIVITY_TIMEOUT`: Superamento soglia inattività in stato pausa ($h_7$).
     * `82` $\to$ `ERR_PLAYBOOK_NODE_NOT_FOUND`: Nodo inesistente nel grafo Playbook attivo $G_P$.
     * `83` $\to$ `ERR_GRAPH_CYCLE_DETECTED`: Rilevazione cicli su nodi bloccanti Playbook.
     * `84` $\to$ `ERR_SCHEMA_MISMATCH`: Incompatibilità di versione schema non migrata.
     * `85` $\to$ `ERR_CONFIGURATION_MALFORMED`: Presenza float, NaN o JSON malformato.
     * `86` $\to$ `ERR_HOBM_BOUNDARY_VIOLATION`: Mancanza firma operatore su azione ad alto rischio.
     * `87` $\to$ `ERR_KMS_UNAVAILABLE`: Indisponibilità o errore I/O modulo KMS.
2. **Valutazione del Predicato di Lockdown (`IsLockdownEvent`):**
   - Verificare se l'evento appartiene agli eventi critici:
     ```text
     IsLockdownEvent(sigma_orig) <===> (sigma_orig in { EV_HASH_CORRUPT })
     ```
3. **Costruzione della Transazione di Errore (`BuildErrorTx`):**
   - Invocare la funzione deterministica (Cap 1.4.2):
     ```text
     t_err = BuildErrorTx(S, E, err_code, sigma_orig)
     ```
   - Impostare l'evento formale: se `IsLockdownEvent(sigma_orig)` imposta `EV_HASH_CORRUPT`, altrimenti `EV_SML_FAIL`.
4. **Applicazione della Mutazione di Sicurezza e Persistenza:**
   - Se l'evento è di lockdown $\to$ applicare $S' = S[ q \mapsto \text{SECURITY\_LOCKDOWN} ]$.
   - Se l'errore è applicativo/validazione $\to$ applicare $\delta_{\text{err}}(S, t, v_{\text{res}})$, transitando $M$ a `VALIDATION_ERROR` o `RECOVERABLE_FAILURE`.
   - Persistere $t_{\text{err}}$ in modo append-only sul Ledger.
5. **Propagazione come Process Exit Code:**
   - Se il runtime esegue come processo autonomo del sistema operativo, terminare o notificare lo status propagando il codice numerico `70–89` come **Process Exit Code**.

#### 5. VERIFICATION POINTS
1. Verificare che ogni condizione di errore sia mappata a uno e un solo codice nello spazio `70–89`.
2. Verificare che l'`execution_envelope` contenga il codice errore e la causale formale.
3. Verificare che le violazioni di hash inducano istantaneamente lo stato `SECURITY_LOCKDOWN`.

#### 6. EXPECTED RESULT / STATE
Errore intercettato, tipizzato ed archiviato sul Ledger in modo deterministico; automa di sicurezza attestato nello stato di contenimento appropriato; propagazione del corretto exit code.

#### 7. EVIDENCE OBJECTIVE
Dimostrare la registrazione sul Ledger della transazione di errore generata da `BuildErrorTx` recante l'esatto codice numerico 70–89 e l'adeguamento conforme dello stato dell'automa $M$.

#### 8. NON-CONFORMITY HANDLING
- È tassativamente vietato sollevare eccezioni non gestite o codici non censiti: la totalità della funzione `ApplyValidated` (`REQ-APPLY-TOTALITY-POLICY`) garantisce che ogni input produca uno stato valido.

#### 9. ESCALATION
Allarme automatico al team di supporto in base alla classe di errore (70–79 $\to$ Sicurezza/Infrastruttura, 80–89 $\to$ Validazione/Metodologia).

#### 10. AUTHORITY CLASSIFICATION
* Tassonomia numerica 70–89, `BuildErrorTx` e propagazione exit code: `CORE-MANDATED`.
* Instradamento notifiche operative: `CORE-DERIVED PROCEDURE`.

#### 11. BLUEPRINT DEPENDENCIES
Infrastruttura di telemetria, log aggregation e monitoraggio allarmi di cluster.

#### 12. IMPLEMENTATION DEPENDENCIES
Error handler trap a basso livello e mappatore dei segnali di uscita del processo.

---

# SEZIONE 7: APPENDICI METODOLOGICHE, CHECKLIST E MODULI DI LABORATORIO

---

### 7.1 Checklist Metodologica di Pre-Flight per Rilascio Policy e Playbook

Prima di autorizzare la firma, la compilazione o il caricamento di un nuovo **Emancipation Playbook Graph** ($G_P$) o di un **Policy Bundle** ($\mathcal{P}$) all'interno dell'ambiente operativo, il Metodologo di Laboratorio `MUST` verificare puntualmente la seguente checklist di conformità:

```text
===================================================================================================
CHECKLIST PRE-FLIGHT 1: VALIDAZIONE PLAYBOOK GRAPH (G_P) — [Rif. SOP-F06]
===================================================================================================
[ ] 1. UNICITÀ DEI VERTICI:
       Tutti i campi node_id all'interno di V_P sono stringhe non vuote e mutuamente distinte.
[ ] 2. TIPIZZAZIONE DEI NODI:
       Ogni nodo v appartiene esattamente a una delle 4 categorie formali:
       { INFORMATION, OPTIONAL_STEP, USER_CONFIRMED_STEP, REQUIRED_FOR_SYSTEM_STATE }.
[ ] 3. VERIFICA DI ACICLICITÀ SOTTOGRAFO BLOCCANTE (INV-PLAYBOOK-GRAPH-01):
       Il sottografo indotto formato dai soli nodi REQUIRED_FOR_SYSTEM_STATE è dimostrato
       privo di cicli orientati: IsAcyclic(G_blocking) == TRUE (Rigetto con Err 83 se violato).
[ ] 4. VERIFICA SOGLIA DURATA (theta_max_duration):
       Per ogni nodo v in V_P: v.estimated_duration_minutes <= Theta.theta_max_duration.
[ ] 5. PUREZZA DELLE CONDIZIONI (C_P):
       Ogni condizione c in C_P è un predicato puro c : S_space -> { True, False } privo di I/O.
[ ] 6. VERIFICA NON-PREGIUDIZIO (RULE-COMMUNITY-REFERRAL-NON-PREJUDICE-01):
       Nessun nodo subordina la progressione a servizi esterni salvo se REQUIRED_FOR_SYSTEM_STATE.
===================================================================================================

===================================================================================================
CHECKLIST PRE-FLIGHT 2: VALIDAZIONE POLICY BUNDLE (P) — [Rif. SOP-F12]
===================================================================================================
[ ] 1. IDENTIFICATORE POLICYID:
       Assegnato PolicyID conforme allo standard UUIDv7 (Cap 4.2).
[ ] 2. CONFORMITÀ DEI PARAMETRI (Theta):
       Tutte le soglie numeriche, pesi ed indici sono interi compresi in I_safe (zero float).
[ ] 3. PREDICATO ESECUTIVO PURO (R_exec):
       La funzione R_exec restituisce esclusivamente un valore in { ALLOW, DENY, RECALIBRATE }.
[ ] 4. COMPOSIZIONE DISGIUNTA (DENY-OVERRIDES):
       In caso di bundle composito, R_exec,comp applica la regola conservativa DENY-OVERRIDES.
[ ] 5. ORDINAMENTO LESSICOGRAFICO DIGEST:
       Il CompositePolicyDigest è calcolato su SHA256(concat(A_sorted, B_sorted)) con ordinamento
       lessicografico dei byte binari (Cap 4.3).
[ ] 6. DERIVAZIONE SEMVER COMPOSITA (REQ-POLICY-SEMVER-DERIVATION):
       Assegnazione di versione composita conforme alla compatibilità retroattiva <=_compat.
[ ] 7. FIRMA DIGITALE E DECISIONPROOF:
       Calcolata firma Ed25519 a 64 byte (128 caratteri Hex UTF-8) su Canon(P) e Canon(t).
===================================================================================================
```

---

### 7.2 Modulo Standard di Attestazione Motivazionale per Human Override

In conformità alla procedura **SOP-F15** ed ai **5 Principi Fondamentali di Human Override** (Cap 4.6 del Core), l'operatore umano accreditato che esegue una transizione `EV_OVERRIDE` `MUST` compilare il payload della transazione attestando i seguenti campi obbligatori:

```text
===================================================================================================
SCINTILLA CORE — RECORD DI ATTESTAZIONE HUMAN OVERRIDE [SOP-F15]
===================================================================================================
1. METADATI DI IDENTIFICAZIONE E AUTORIZZAZIONE
   - Case ID:                      [ Inserire case_id conforme a I_case ]
   - Operator ID (actor_id):       [ Identificatore univoco operatore conforme a I_id ]
   - Permesso di Sistema:          SC.PERMISSION.OPERATOR_OVERRIDE [VERIFICATO]
   - Timestamp UTC (E.t_wall):     [ Inserire timestamp a 64 bit in millisecondi ]

2. CONTESTO DI STATO E MOTIVAZIONE DELL'INTERVENTO (Principio 3: Spiegabilità Obbligatoria)
   - Stato Iniziale di Sicurezza:   OPERATOR_REQUIRED (q4)
   - Stato Destinazione:           NORMAL (q0)
   - Stato Umano Corrente (q_H):   [ Inserire stato invariato conforme a INV-DECOUPLING-01 ]
   - Motivazione Formale (reason): [ Inserire testo non vuoto esplicativo della causa del ]
                                   [ blocco e delle verifiche umane condotte prima del ripristino ]

3. DICHIARAZIONE DI CONFORMITÀ ETICA (Principi 4 e 5)
   [X] Si attesta che l'intervento non altera né elide la cronologia degli eventi sul Ledger.
   [X] Si attesta che l'azione rispetta i consensi espressi dall'utente in Q_consent (salvo HOBM
       PROFESSIONAL_INTERVENTION_REQUIRED accertato e documentato).

4. ATTESTAZIONE CRITTOGRAFICA DI FIRMA (Principio 2: Autenticazione Forte)
   - Algoritmo di Firma:           Ed25519 (RFC 8032 / Profilo SC-JCS-1)
   - Firma Digitale (t.proof):     [ Inserire firma esadecimale a 64 byte calcolata sul body ]
===================================================================================================
```

---

### 7.3 Matrice di Risoluzione Rapida per i Runtime Error Codes (70–89)

La seguente tabella fornisce la guida metodologica di laboratorio per la diagnosi, il contenimento e la risoluzione dei **Runtime Error Codes** (Cap 8.2 del Core / **SOP-F18**):

```text
==================================================================================================================================
Codice | Identificativo Simbolico          | Causa Tipica di Laboratorio           | Procedura SOP | Azione di Risoluzione e Ripristino
==================================================================================================================================
71     | ERR_INVALID_CRYPTO_SIGNATURE      | Firma Ed25519 corrotta, errata o      | SOP-F04       | Rigetto transazione; verificare chiave
       |                                   | non corrispondente alla chiave pubblica.| SOP-F15     | pubblica dell'attore nel registry E.
----------------------------------------------------------------------------------------------------------------------------------
72     | ERR_CONSENT_REVOKED_VIOLATION     | Tentativo di elaborare una risorsa    | SOP-F02       | Rigetto operazione; verificare l'insieme
       |                                   | presente in Q_revoked_items.          |               | Q_revoked_items e mascherare la risorsa.
----------------------------------------------------------------------------------------------------------------------------------
73     | ERR_INFRASTRUCTURE_IO             | Perdita di connessione allo storage   | SOP-F01       | Isolare il guasto di I/O; ripristinare il
       |                                   | del Ledger o fallimento di scrittura. | SOP-F17       | canale di persistenza append-only.
----------------------------------------------------------------------------------------------------------------------------------
77     | ERR_SECURITY_VIOLATION            | Rilevato disallineamento hash HN o    | SOP-F16       | Transizione istantanea a SECURITY_LOCKDOWN;
       |                                   | manomissione storica del Ledger.      | SOP-F17       | formulare ValidRepairPatch(p) via EV_REPAIR.
----------------------------------------------------------------------------------------------------------------------------------
78     | ERR_LEASE_ACQUISITION_TIMEOUT     | Scadenza o invalidità del lease di    | SOP-F04       | Rinnovare il fencing_token incrementando
       |                                   | concorrenza distribuita durante il lock.|             | strettamente in Nat+ prima di ritentare.
----------------------------------------------------------------------------------------------------------------------------------
79     | ERR_CLOCK_SKEW_EXCEEDED           | Delta temporale tra timestamp e ora   | SOP-F04       | Sospendere il nodo disallineato; riallineare
       |                                   | locale superiore a theta_max_clock_skew.|             | il clock entro la soglia delta_clock.
----------------------------------------------------------------------------------------------------------------------------------
80     | ERR_SML_PARSE_FAILED              | Output LLM non conforme alla          | SOP-F13       | Scartare l'input con EV_SML_FAIL; richiedere
       |                                   | grammatica formale EBNF di SML v2.0.  |               | rigenerazione all'LLM (Livello 5).
----------------------------------------------------------------------------------------------------------------------------------
81     | ERR_HUMAN_INACTIVITY_TIMEOUT      | Permanenza in pausa (h7) oltre la     | SOP-F09       | Il sistema emette HEV_RECALIBRATION_REQ;
       |                                   | soglia theta_inactivity_timeout.      |               | transizione controllata a h8 per ripresa.
----------------------------------------------------------------------------------------------------------------------------------
82     | ERR_PLAYBOOK_NODE_NOT_FOUND       | Identificatore di nodo non presente   | SOP-F07       | Respingere la richiesta; verificare la
       |                                   | nel grafo del Playbook attivo G_P.    |               | corrispondenza con i vertici V_P.
----------------------------------------------------------------------------------------------------------------------------------
83     | ERR_GRAPH_CYCLE_DETECTED          | Rilevato ciclo orientato su nodi      | SOP-F06       | Rifiuto categorico del Playbook; correggere
       |                                   | bloccanti REQUIRED_FOR_SYSTEM_STATE.  |               | il grafo eliminando le dipendenze circolari.
----------------------------------------------------------------------------------------------------------------------------------
84     | ERR_SCHEMA_MISMATCH               | Incompatibilità di versione schema    | SOP-F17       | Applicare il manifest di migrazione schema
       |                                   | non coperta da manifest valido.       |               | corrispondente al runtime_profile registrato.
----------------------------------------------------------------------------------------------------------------------------------
85     | ERR_CONFIGURATION_MALFORMED      | Presenza di numeri floating point,    | SOP-F01       | Riformattare la configurazione eliminando float;
       |                                   | NaN, o violazione contratto DP-FSM.   | SOP-F05       | convertire tutti i valori in interi I_safe.
----------------------------------------------------------------------------------------------------------------------------------
86     | ERR_HOBM_BOUNDARY_VIOLATION       | Azione ad alto rischio priva di firma | SOP-F15       | Bloccare l'azione; richiedere esplicita
       |                                   | operatore o con motivazione vuota.    |               | revisione umana e firma operatore accreditato.
----------------------------------------------------------------------------------------------------------------------------------
87     | ERR_KMS_UNAVAILABLE               | Indisponibilità o errore di I/O       | SOP-F03       | Verificare la connettività del modulo KMS;
       |                                   | con il modulo crittografico KMS/HSM.  | SOP-F08       | ritentare la derivazione o purga di chiave.
==================================================================================================================================
```

---

### 7.4 Registro delle Non-Determinazioni e Tracciabilità di Chiusura

A salvaguardia dell'integrità dei livelli di astrazione, la presente tabella riassume le aree in cui la SOP **non assume decisioni architetturali o implementative**, demandandole formalmente ai livelli appropriati:

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│ REGISTRO DELLE NON-DETERMINAZIONI DI LABORATORIO                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. MECCANISMO DI STORAGE CONCRETO [Delega: BLUEPRINT / IMPLEMENTATION]                          │
│    La SOP impone la persistenza append-only della sequenza canonica di byte UTF-8 (SC-JCS-1)    │
│    e la validazione della catena di hash H_N. La scelta tra database relazionale, log su file, │
│    o database a grafo immutabile appartiene al Blueprint.                                       │
│                                                                                                 │
│ 2. ALGORITMI DI ORDINAMENTO E VISITA GRAFI [Delega: IMPLEMENTATION]                            │
│    La SOP impone la verifica del predicato puro IsAcyclic(G_blocking) == TRUE. L'adozione di    │
│    un algoritmo specifico (Kahn, DFS con colorazione nodi) appartiene all'Implementation.      │
│                                                                                                 │
│ 3. INFRASTRUTTURA KMS E PROTEZIONE CHIAVI [Delega: BLUEPRINT / HARDWARE]                        │
│    La SOP impone l'invocazione di ShredKey, l'esito nullo di LookupKey e la verifica delle     │
│    firme Ed25519. La scelta tra moduli HSM dedicati, KMS cloud o enclave sicure appartiene     │
│    al Blueprint.                                                                                │
│                                                                                                 │
│ 4. MODELLO DI LINGUAGGIO E PROMPT ENGINEERING [Delega: BLUEPRINT / LEVEL 5 BLACKBOX]            │
│    La SOP tratta il Livello 5 come scatola nera, imponendo il parsing EBNF e il Semantic Safety│
│    Gate. Nessuna tecnica di prompting o architettura di rete neurale è vincolata dalla SOP.     │
│                                                                                                 │
│ 5. GOVERNANCE AZIENDALE E TURNI OPERATORI [Delega: ORGANIZATIONAL POLICY]                       │
│    La SOP prescrive i 5 Principi di Human Override e la presenza di motivazione non vuota. La   │
│    turnistica del personale, gli SLA di risposta e i contratti di lavoro sono ORG-POLICY.       │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

# SEZIONE 8: DICHIARAZIONE FINALE DI CONFORMITÀ METODOLOGICA E CHIUSURA

Si dichiara formalmente e categoricamente che:

1. **SCINTILLA SOP v1.0 costituisce una specifica metodologico-operativa autonoma, internamente coerente e rigorosamente subordinata a SCINTILLA Core v4.5.6.**
2. **Nessun elemento normativo nuovo, stato, evento, transizione o invariante è stato introdotto** rispetto al testo congelato del Core.
3. Ogni singola procedura operativa rispetta rigorosamente la dualità:
   ```text
   EVIDENCE OBJECTIVE != EVIDENCE FORMAT
   OPERATIONAL PROCEDURE != IMPLEMENTATION ALGORITHM
   ```
   garantendo che la SOP rimanga *technology-agnostic* e non si trasformi in un Blueprint architetturale o in una specifica di implementazione software.
4. Le non-determinazioni del Core sono state formalmente registrate e delegate ai rispettivi livelli di competenza.

---

```text
===================================================================================================
SCINTILLA SOP v1.0 — CANONICAL METHODOLOGICAL LABORATORY MANUAL
===================================================================================================
* Coverage: Sezioni 1–8 e Procedure SOP-F01 .. SOP-F18 Fully Emitted
* Status: Official Methodological Standard (Subordinated to SCINTILLA Core v4.5.6 Frozen Baseline)
* Authority: Methodological and Operational Manual for SCINTILLA Core Implementations
===================================================================================================
```

***Normative Information***  

**Author:** Cristian Evangelisti  
**Contact:** `opensource@cevangel.anonaddy.me`  
The Author is responsible for the definition, maintenance, and publication of this normative specification.  

***Copyright and License***  
Copyright (c) 2026 Cristian Evangelisti.  
This specification is distributed under the terms of the **GNU Free Documentation License (GNU FDL)**, Version 1.3 or any later version published by the Free Software Foundation; with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.  
A copy of the license is available at: `https://www.gnu.org/licenses/fdl-1.3.html`  
[License Information](https://www.gnu.org/licenses/fdl)  

***AI-Assisted Development***  
This specification was developed through an iterative process of analysis, design, review, and refinement assisted by Generative Artificial Intelligence systems (Large Language Models - LLMs). These systems were used exclusively as support tools for document design, review, formalization, and editing.  
All content within this specification has been selected, verified, modified where necessary, and explicitly approved by the Author. Artificial Intelligence systems possess no normative authority, do not determine the content of the specification, do not hold the role of author or co-author, and assume no editorial, technical, or regulatory liability regarding this document. The Author retains full responsibility for the content, consistency, correctness, and evolution of this specification.  

***Compatibility and Versioning***  
Unless otherwise indicated, compatibility between different versions of this specification is not implied. Every implementation must explicitly declare the version of SCINTILLA Core and SCINTILLA SOP with which it complies.
