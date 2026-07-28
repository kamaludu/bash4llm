# ✴ SCINTILLA CORE CANONICAL SPECIFICATION
## Standard Edition v2.0 Timeless (Human-Readable & Plain-Language Canonical Specification)

**Core Deterministico e Umano-Centrico per la Gestione di Percorsi di Emancipazione Personale**

* **Stato:** Specifica Normativa Canonica Formale (Single Source of Truth)  
* **Edizione:** v2.0 Timeless Standard Edition (Canonical & Formally Consistent - Plain-Language Edition)  
* **Autorità Governance:** Single Source of Truth Normativa per il dominio SCINTILLA CORE. Versionata secondo l'Algebra delle Versioni (§6).  
* **Terminologia Normativa:** RFC 2119 / RFC 8174 (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`).

---

# PARTE I: SPECIFICA NORMATIVA ASTRATTA (CORE ABSTRACT SPECIFICATION)

---

## 1. STRUTTURA ED ALGEBRA DEL MODELLO DI DOMINIO SCINTILLA

### 1.1 Formalizzazione dello Spazio degli Stati e dello Spazio delle Transazioni

Il modello di dominio di Scintilla Core è definito su domini di stato e strutture dati rigorosamente definiti.

#### 1.1.1 Spazio degli Stati Globale
Lo Spazio degli Stati del sistema è definito come l'insieme di tutte le configurazioni valide che il sistema può assumere. Ogni stato del sistema è una struttura dati (tupla) formata da **9 componenti fondamentali e obbligatorie**:

1. **Identificatore del Caso (`case_id`):** Un identificatore unico e globale appartenente al dominio degli identificatori, che associa lo stato a uno specifico caso utente.
2. **Stato della Macchina di Sicurezza (`q`):** Lo stato operazionale corrente della macchina a stati di sicurezza del runtime (Runtime Safety State Machine, §2.2).
3. **Stato del Percorso Umano (`q_H`):** Lo stato corrente della macchina a stati del percorso umano (Human Journey State Machine, §2.3).
4. **Bundle di Policy Attivo (`P_active`):** Il pacchetto di regole e vincoli di sicurezza attualmente attivo ed esecutivo nel sistema (§4.1).
5. **Mappa della Provenienza Dati (`M_prov`):** Una mappa informativa che associa a ogni chiave dati il rispettivo valore arricchito con i metadati di provenienza del dato (Data Provenance, §1.4).
6. **Stato del Lock di Concorrenza (`F_lease`):** Lo stato del meccanismo di isolamento e concorrenza, espresso dalla coppia formata dal token di isolamento (fencing token, un numero intero strettamente crescente) e dal momento temporale di scadenza del lease.
7. **Registro del Consenso (`Q_consent`):** L'insieme aggiornato delle manifestazioni di consenso valide espresse dall'utente.
8. **Esito Decisionale (`O_decision`):** Il risultato dell'ultima valutazione effettuata dal motore di guida delle policy (Policy Guidance Engine). Può assumere esclusivamente uno dei seguenti quattro valori: `ALLOW` (consentito), `DENY` (negato), `RECALIBRATE` (richiesta ricalibrazione) oppure `NONE` (nessuna decisione emessa).
9. **Stato del Playbook (`K_playbook`):** Lo stato corrente dell'esecutore del Playbook di Emancipazione (§5), rappresentato dalla tupla contenente l'identificatore del playbook attivo (o valore nullo), l'identificatore del nodo di azione corrente (o valore nullo) e l'insieme dei nodi già completati.

---

Lo Spazio Globale degli Stati può essere rappresentato concretamente mediante una tabella, dove ogni record rappresenta un elemento $s \in \mathcal{S}$ e i campi del record corrispondono alle componenti della tupla che definisce lo stato.
$\mathcal{S}$ definisce formalmente quali configurazioni di stato sono ammissibili.

---

#### 1.1.2 Assioma dello Stato Iniziale di Genesi
Lo stato iniziale di genesi (denotato come stato zero) è la configurazione restituita dal sistema in assenza di transizioni pregresse. Tale stato `MUST` contenere tassativamente i seguenti valori di default:

* `case_id` impostato al valore nullo (`null`);
* Stato della macchina di sicurezza `q` impostato al valore `NORMAL`;
* Stato del percorso umano `q_H` impostato al valore `UNASSESSED`;
* Bundle di policy attivo `P_active` impostato sulla policy predefinita di sistema (`P_default`);
* Mappa di provenienza dati `M_prov` completamente vuota;
* Lock di concorrenza `F_lease` inizializzato con token di fencing uguale a 0 e timestamp pari al momento di avvio del sistema;
* Registro del consenso `Q_consent` vuoto;
* Esito decisionale `O_decision` impostato al valore `NONE`;
* Stato del playbook `K_playbook` avente identificatore di playbook nullo, nodo corrente nullo e insieme dei nodi completati vuoto.

#### 1.1.3 Spazio delle Transazioni e Corpo della Transazione (`TransactionBody`)
Lo Spazio delle Transazioni è l'insieme di tutti i record di mutazione atomici, convalidati e immutabili che possono essere scritti nel sistema. Una transazione è una struttura dati composta da due elementi: il corpo della transazione (`TransactionBody`) e la prova di autenticità (`proof`).

Il corpo della transazione (`TransactionBody`) racchiude tutti i metadati e il contesto informativo soggetti ad autenticazione ed hashing, organizzati in **11 campi obbligatori**:

1. `tx_id`: Identificatore unico globale della transazione.
2. `case_id`: Identificatore del caso utente associato.
3. `seq_num`: Numero di sequenza intero positivo, strettamente crescente e monotonico.
4. `prev_hash`: Impronta crittografica (hash) del corpo della transazione immediatamente precedente nella catena.
5. `timestamp`: Istante temporale di generazione della transazione.
6. `actor`: Identificatore univoco dell'attore (utente, sistema o operatore) che ha originato l'operazione.
7. `event`: L'evento di transizione inviato all'automa di sicurezza o all'automa del percorso umano.
8. `payload`: Il contenuto informativo specifico della mutazione proposta.
9. `policy_binding_hash`: Impronta crittografica del bundle di policy attivo nel sistema al momento dell'emissione della transazione.
10. `schema_version`: Versione dello schema dati applicativo impiegato.
11. `specification_id`: Identificatore canonico della specifica dello standard Scintilla Core.

La prova di autenticità (`proof`) rappresenta la firma digitale dell'attore mittente, calcolata sulla versione serializzata canonica del corpo della transazione (`TransactionBody`).

---

### 1.2 Il Registro Immutabile (Ledger) come Struttura ad Append-Only
Il registro immutabile delle decisioni (Ledger) è modellato come una sequenza ordinata e finita di transazioni dotata delle seguenti proprietà strutturali:

1. È un insieme di sequenze di transazioni che include la sequenza vuota (assenza di transazioni).
2. L'unica operazione di modifica ammessa è l'aggiunta in coda di nuove transazioni (operazione di Append-Only).
3. La sequenza vuota funge da elemento neutro iniziale.

**Assioma di Immutabilità del Ledger:**  
Se una sequenza di transazioni è ottenuta aggiungendo una nuova transazione in coda a una sequenza esistente, la sequenza originale costituisce un prefisso storico immutabile e inalterabile. Le transazioni già confermate non possono essere modificate, cancellate, sovrascritte o riordinate.

**Teorema di Estensione Monotonica:**  
L'aggiunta di una transazione a un registro composto da un numero $N$ di elementi produce un nuovo registro composto esattamente da $N + 1$ elementi, all'interno del quale il registro precedente rimane preservato integralmente come prefisso.

---

### 1.3 La Funzione di Proiezione dello Stato
La relazione tra la storia immutabile delle transazioni registrate nel Ledger e lo stato corrente del sistema è governata da una funzione pura e deterministica chiamata **Funzione di Proiezione dello Stato**:

1. Quando viene applicata alla sequenza vuota di transazioni, la funzione di proiezione restituisce lo stato iniziale di genesi.
2. Quando viene applicata a un registro a cui viene aggiunta una nuova transazione, la funzione calcola il nuovo stato applicando una funzione pura di transizione allo stato precedente e alla nuova transazione.

Se la transazione applicata risulta invalida, non autorizzata o viola le regole di sicurezza rispetto allo stato corrente, la funzione di transizione restituisce un elemento speciale di errore irreversibile (denotato come stato di errore fatale di bottom).

**Assioma di Assorbimento dell'Errore Fatale:**  
Se il sistema entra nello stato di errore fatale, qualsiasi ulteriore transazione applicata restituisce invariabilmente lo stesso stato di errore fatale. Il verificarsi di questo errore forza il runtime a bloccare immediatamente l'operatività ordinaria e a portare il sistema nello stato di isolamento rigido `SECURITY_LOCKDOWN`.

#### 1.3.1 Teorema del Replay Deterministico
Due registri di transazioni identici, se rielaborati a partire dallo stato di genesi applicando le medesime regole di transizione, producono tassativamente lo stesso identico stato finale proiettato.

---

### 1.4 Tassonomia dei Dati e Algebra della Provenienza (`DataProvenance`)
Ogni elemento informativo o dato contenuto nello stato del sistema `MUST` essere incapsulato in una struttura dati di provenienza formata da **6 campi**:

1. **Valore (`value`):** Il dato informativo effettivo.
2. **Categoria di Provenienza (`category`):** La tipologia della fonte del dato, appartenente a una delle seguenti categorie:
   * Dichiarazione dell'Utente (`USER_DECLARATION`);
   * Inferenza da Modello Linguistico (`LLM_INFERENCE`);
   * Dato Verificato dal Sistema (`SYSTEM_VERIFIED`);
   * Dato Confermato da Operatore Umano (`OPERATOR_CONFIRMED`);
   * Fonte Esterna Certificata (`EXTERNAL_SOURCE`).
3. **Attore Asseritore (`assertor_actor`):** L'identificatore dell'attore che ha introdotto il dato.
4. **Timestamp (`timestamp`):** L'istante temporale in cui il dato è stato asserito.
5. **Punteggio di Confidenza (`confidence_score`):** Un valore numerico continuo compreso nell'intervallo chiuso da 0.0 (assenza di fiducia) a 1.0 (massima certezza).
6. **Stato di Verifica (`verifiability_status`):** Lo stato oggettivo di controllo del dato, selezionabile tra: Non Verificato (`UNVERIFIED`), In Attesa di Verifica (`PENDING`), Verificato (`VERIFIED`) o Rifiutato (`REJECTED`).

#### 1.4.1 Ordine Parziale di Fiducia e Degradazione della Provenienza
Tra le categorie di provenienza è stabilito un ordine gerarchico di autorità e affidabilità informativa. L'autorità cresce rigorosamente secondo la seguente scala:

1. Inferenza LLM (`LLM_INFERENCE`) – *Livello minimo di autorità*;
2. Dichiarazione dell'Utente (`USER_DECLARATION`);
3. Fonte Esterna (`EXTERNAL_SOURCE`);
4. Conferma da Operatore Umano (`OPERATOR_CONFIRMED`);
5. Verifica di Sistema (`SYSTEM_VERIFIED`) – *Livello massimo di autorità*.

**Regola di Fallback per Categorie Estese:** qualsiasi categoria appartenente alle estensioni della provenienza `MUST` essere mappata, ai fini del calcolo delle autorizzazioni, al livello di autorità della Dichiarazione Utente (`USER_DECLARATION`), salvo diversa riconfigurazione esplicita nel pacchetto di policy.

**Assioma di Contaminazione e Degradazione della Provenienza:**  
Quando un nuovo dato viene sintetizzato o derivato a partire da un insieme di dati di input:
* La sua categoria di provenienza non può mai superare il livello di autorità della categoria meno fidata tra quelle dei dati usati in input.
* Il suo punteggio di confidenza deve essere minore o uguale al valore di confidenza più basso presente tra i dati di input utilizzati.

---

### 1.5 Identificatori Astratti, Tempo e Crypto-Agilità
1. **Identificatore Unico Astratto:** Un elemento dotato di garanzia di unicità globale e ordinabile in modo sequenziale.
2. **Istante Temporale Astratto:** Un punto all'interno di una scala temporale continua, unidimensionale e totalmente ordinata.
3. **Crypto-Agilità Normativa:**
   * **Funzione di Hash:** Algoritmo deterministico che trasforma una sequenza arbitraria di byte in un'impronta digitale (digest) di lunghezza fissa.
   * **Schema di Firma:** Un insieme di tre algoritmi destinati rispettivamente alla generazione delle chiavi, alla creazione della firma digitale e alla verifica della validità della firma.

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

### 2.2 Runtime Safety State Machine (Sicurezza e Integrità di Sistema)
L'operatività di sicurezza del runtime è modellata come un automa a stati finiti deterministico e totale, definito da:
* L'insieme dei 7 stati canonici;
* L'alfabeto degli 8 eventi di sistema;
* La funzione di transizione deterministica di sicurezza;
* Lo stato iniziale;
* L'insieme degli stati operativamente stabili.

1. **Insieme degli Stati Canonici (7 stati):**
   * `NORMAL`: Stato operativo ordinario (stato iniziale);
   * `REQUIRE_RECALIBRATION`: Stato di richiesta ricalibrazione del contesto;
   * `VALIDATION_ERROR`: Stato di errore di validazione dell'input o dei dati;
   * `RECOVERABLE_FAILURE`: Stato di fallimento ripristinabile dal sistema;
   * `OPERATOR_REQUIRED`: Stato che richiede tassativamente l'intervento di un operatore umano;
   * `SECURITY_LOCKDOWN`: Stato di blocco di sicurezza e isolamento rigido;
   * `SAFE_READ_ONLY_MODE`: Stato operativo sicuro limitato alla sola lettura.

2. **Stato Iniziale:** `NORMAL`.
3. **Insieme degli Stati Operativamente Stabili:** Gli unici stati in cui è consentito l'avanzamento ordinario sono `NORMAL` e `SAFE_READ_ONLY_MODE`.
4. **Alfabeto degli Eventi di Sistema (8 eventi):**
   * `EV_SUCCESS`: Evento di esecuzione completata con successo;
   * `EV_ABANDON`: Evento di abbandono o interruzione del flusso;
   * `EV_SML_FAIL`: Evento di fallimento nella validazione del linguaggio SML;
   * `EV_LEASE_EXP`: Evento di scadenza del lease o violazione del lock di concorrenza;
   * `EV_HASH_CORRUPT`: Evento di rilevazione manomissione o corruzione della catena di hash;
   * `EV_TIMEOUT`: Evento di superamento del tempo massimo limite;
   * `EV_OVERRIDE`: Evento di intervento ed esecuzione straordinaria da parte dell'operatore umano;
   * `EV_REPAIR`: Evento di ripristino e riparazione dello stato di sicurezza.

---

### 2.3 Human Journey State Machine (Percorso di Emancipazione Personale)
L'evoluzione del percorso umano dell'utente è gestita da un automa di dominio autonomo, definito da:
* L'insieme dei 7 stati del percorso umano;
* L'alfabeto degli 8 eventi umani;
* La funzione di transizione del percorso umano;
* Lo stato umano iniziale;
* L'insieme degli stati target di successo.

1. **Insieme degli Stati del Percorso Umano (7 stati):**
   * `UNASSESSED`: Percorso non ancora valutato (stato iniziale);
   * `INITIAL_ASSESSMENT`: Fase di valutazione iniziale delle esigenze;
   * `STABILIZATION`: Fase di stabilizzazione delle condizioni primarie;
   * `DOCUMENT_RECOVERY`: Fase di recupero dei documenti anagrafici e legali;
   * `EMPLOYMENT_READINESS`: Fase di preparazione all'inserimento lavorativo;
   * `FINANCIAL_AUTONOMY`: Fase di raggiungimento dell'autonomia finanziaria;
   * `SUSTAINED_INDEPENDENCE`: Stato di indipendenza personale e autonomia sostenuta nel tempo.

2. **Stato Iniziale:** `UNASSESSED`.
3. **Insieme degli Stati Target:** L'unico stato di completamento con successo del percorso è `SUSTAINED_INDEPENDENCE`.
4. **Alfabeto degli Eventi Umani (8 eventi):**
   * `HEV_ASSESS_START`: Avvio della valutazione del percorso;
   * `HEV_STABILIZED`: Raggiungimento della stabilizzazione primaria;
   * `HEV_DOCS_OBTAINED`: Ottenimento dei documenti necessari;
   * `HEV_JOB_READY`: Raggiungimento della prontezza lavorativa;
   * `HEV_FINANCE_OK`: Conseguimento dell'autonomia finanziaria;
   * `HEV_INDEPENDENCE_ACHIEVED`: Raggiungimento dell'indipendenza autonoma;
   * `HEV_RELAPSE_REGRESS`: Evento di regresso o ricaduta nel percorso;
   * `HEV_RECALIBRATE`: Richiesta di ricalibrazione del percorso umano.

#### 2.3.1 Assioma di Chiusura e Totalità della Funzione di Transizione Umana
La funzione di transizione del percorso umano è una **funzione totale**. Per qualsiasi coppia formata da uno stato umano e un evento umano per la quale non sia espressamente definita una regola di transizione specifica, si applica la regola di stazionarietà (*Stuttering Step Axiom*): il sistema rimane esattamente nello stato umano corrente senza generare errori.

---

### 2.4 Sistema Reattivo Composito e Regole di Disaccoppiamento
Il sistema reattivo globale di Scintilla Core combina lo stato della macchina di sicurezza e lo stato della macchina del percorso umano in un'unica configurazione composita. La funzione di transizione globale è regolata dalle seguenti tre regole mutuamente esclusive:

1. **Gestione degli Eventi di Sistema:** Se l'evento appartiene all'alfabeto degli eventi di sistema, si applica la transizione della macchina a stati di sicurezza del runtime, mentre lo stato del percorso umano rimane invariato.
2. **Gestione degli Eventi Umani in Stato Stabile:** Se l'evento appartiene all'alfabeto degli eventi umani E la macchina di sicurezza si trova in uno stato operativamente stabile (`NORMAL` o `SAFE_READ_ONLY_MODE`), si applica la transizione dell'automa del percorso umano, mentre lo stato della macchina di sicurezza rimane invariato.
3. **Assioma di Congelamento da Lockdown (Lockdown Freeze Axiom):** Se l'evento appartiene all'alfabeto degli eventi umani MA la macchina di sicurezza NON si trova in uno stato operativamente stabile (es. si trova in stato di errore o blocco), l'evento umano viene ignorato e l'intero stato del sistema rimane totalmente congelato.

**Principi di Isolamento e Disaccoppiamento:**
* **`INV-DECOUPLING-01` (Disaccoppiamento Unidirezionale):** L'automa del percorso umano genera unicamente transizioni descrittive di supporto all'utente. L'automa del percorso umano **`SHALL NOT` possedere alcuna autorità diretta di mutazione sullo stato della macchina di sicurezza del runtime**.
* **Isolamento da Lockdown:** Se il runtime entra in uno stato non stabile, qualsiasi evoluzione del percorso umano è bloccata fino al ripristino delle condizioni di sicurezza del runtime.

---

## 3. SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)

La dinamica di esecuzione globale di Scintilla Core è definita mediante regole di semantica operazionale strutturata (Small-Step SOS), che determinano come una configurazione composta da stato di sicurezza, stato umano, evento e stato globale si trasforma nella configurazione successiva.

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore
Un evento contenuto in una transizione emessa da un attore è considerato valido ed esecutivo se e solo se la combinazione tra il tipo di evento e il tipo di attore rispetta le seguenti regole di autorizzazione:

1. Gli eventi del percorso umano sono autorizzati se l'attore mittente è un utente (`USER`), un operatore umano (`OPERATOR`) o il sistema stesso (`SYSTEM`).
2. Gli eventi di sistema ordinari (`EV_SUCCESS`, `EV_ABANDON`, `EV_SML_FAIL`, `EV_LEASE_EXP`, `EV_HASH_CORRUPT`, `EV_TIMEOUT`) sono autorizzati unicamente se emessi dal sistema (`SYSTEM`).
3. Gli eventi di intervento straordinario (`EV_OVERRIDE` ed `EV_REPAIR`) sono autorizzati unicamente se emessi da un operatore umano autenticato (`OPERATOR`).
4. **Divieto Assoluto per i Modelli Linguistici:** Qualsiasi tentativo di emettere eventi direttamente da parte di un modello linguistico (`LLM`) o qualsiasi combinazione non espressamente citata è **tassativamente vietato e non autorizzato**.

---

### 3.2 Mappatura Normativa delle Guardie di Sicurezza (`EvaluateGuards`)
La funzione di valutazione delle guardie verifica le precondizioni di sicurezza necessarie per validare l'esecuzione di un evento di runtime:

* `EV_SUCCESS`: La verifica ha esito positivo (`PASS`) se la catena di hash è integra, il token di fencing è strettamente monotonico e il lease di concorrenza è valido.
* `EV_ABANDON`: La verifica ha esito positivo (`PASS`) se la catena di hash è integra e il lease di concorrenza è valido.
* `EV_SML_FAIL`: La verifica ha esito positivo (`PASS`) se la catena di hash è integra.
* `EV_LEASE_EXP`: La verifica ha esito positivo (`PASS`) se il lease NON è valido oppure il token di fencing NON è strettamente monotonico.
* `EV_HASH_CORRUPT`: La verifica ha esito positivo (`PASS`) se la catena di hash risulta manomessa o non valida.
* `EV_TIMEOUT`: La verifica ha esito positivo (`PASS`) se il tempo limite di esecuzione è scaduto.
* `EV_OVERRIDE`: La verifica ha esito positivo (`PASS`) se l'attore è un operatore umano autenticato e la prova di override è valida.
* `EV_REPAIR`: La verifica ha esito positivo (`PASS`) se l'attore è un operatore umano autenticato e la patch di ripristino è valida.
* In tutti gli altri casi, la valutazione delle guardie restituisce un esito di fallimento (`FAIL`).

---

### 3.3 Regole Operazionali di Sicurezza di Runtime

* **Regola di Sicurezza Ordinaria (`SOS-META-SAFETY`):**  
  SE l'evento appartiene agli eventi di sistema, l'attore è autorizzato, la funzione delle guardie restituisce esito positivo (`PASS`) e la macchina di sicurezza prevede una transizione verso un nuovo stato, ALLORA il sistema aggiorna lo stato della macchina di sicurezza al nuovo stato, mantiene lo stato umano corrente e applica la mutazione allo stato globale.

* **Regola di Fallimento della Sicurezza (`SOS-META-SAFETY-FAIL`):**  
  SE l'evento appartiene agli eventi di sistema MA l'attore NON è autorizzato OPPURE la funzione delle guardie restituisce esito negativo (`FAIL`), ALLORA il sistema transiziona immediatamente nello stato di errore `VALIDATION_ERROR`, mantiene inalterato lo stato umano e NON applica alcuna mutazione allo stato globale.

---

### 3.4 Regole Operazionali del Percorso Umano

* **Regola del Percorso Umano Ordinario (`SOS-META-HUMAN`):**  
  SE l'evento appartiene agli eventi umani, la macchina di sicurezza si trova in uno stato operativamente stabile, l'attore è autorizzato, la macchina del percorso umano prevede la transizione e il motore di policy restituisce esito `ALLOW`, ALLORA il sistema mantiene lo stato di sicurezza corrente, aggiorna lo stato del percorso umano al nuovo stato previsto e applica la mutazione allo stato globale.

* **Regola di Rifiuto o Ricalibrazione Umana (`SOS-META-HUMAN-DENY`):**  
  SE l'evento appartiene agli eventi umani e la macchina di sicurezza si trova in uno stato operativamente stabile, MA l'attore NON è autorizzato OPPURE il motore di policy restituisce un esito pari a `DENY` o `RECALIBRATE`, ALLORA il sistema mantiene lo stato di sicurezza corrente, forza l'automa del percorso umano a eseguire una transizione verso l'evento di ricalibrazione (`HEV_RECALIBRATE`) e NON applica la mutazione proposta allo stato globale.

---

### 3.5 Regola Operazionale di Congelamento da Lockdown

* **Regola di Blocco in Lockdown (`SOS-LOCKDOWN-FREEZE`):**  
  SE l'evento appartiene agli eventi umani MA la macchina di sicurezza NON si trova in uno stato operativamente stabile, ALLORA l'evento viene totalmente ignorato e la configurazione complessiva del sistema rimane inalterata.

---

## 4. POLICY GUIDANCE ENGINE & FORMALIZZAZIONE ALGEBRICA DELLE POLICY

### 4.1 Definizione del Pacchetto di Policy (`PolicyBundle`)
Il **Policy Guidance Engine** (Livello 2) valuta la sicurezza e l'ammissibilità di ogni proposta di decisione mediante il pacchetto di policy (`PolicyBundle`), definito dalle seguenti **5 componenti**:

1. **Identificatore della Policy (`PolicyID`):** Identificatore unico del pacchetto di policy.
2. **Versione (`Version`):** Versione della policy espressa secondo l'Algebra delle Versioni (§6).
3. **Spazio dei Parametri (`Theta`):** L'insieme dei parametri di configurazione e delle soglie operative (ad esempio la durata massima consentita per un'azione o il punteggio minimo di confidenza richiesto per i dati).
4. **Funzione di Valutazione (`R`):** Una funzione pura e deterministica che riceve lo stato corrente, la transazione proposta e i parametri di configurazione, e restituisce esattamente uno dei tre esiti: `ALLOW` (consentito), `DENY` (negato) o `RECALIBRATE` (richiesta ricalibrazione).
5. **Firma della Policy (`Sig_P`):** La firma crittografica emessa dall'autorità di governance che garantisce l'autenticità del pacchetto di policy.

### 4.2 Composizione di Policy Multiple (`DENY-OVERRIDES`)
Quando nel sistema sono attivi contemporaneamente due o più pacchetti di policy, la valutazione decisionale complessiva è determinata dall'operatore di composizione che applica la regola del **Prevalere del Divieto (`DENY-OVERRIDES`)**:

1. L'esito finale della composizione è `DENY` se almeno uno dei pacchetti di policy attivi restituisce `DENY`.
2. L'esito finale della composizione è `RECALIBRATE` se nessun pacchetto di policy restituisce `DENY`, ma almeno uno dei pacchetti restituisce `RECALIBRATE`.
3. L'esito finale della composizione è `ALLOW` se e solo se tutti i pacchetti di policy attivi restituiscono contemporaneamente `ALLOW`.

---

### 4.3 Filosofia Normativa dell'Intervento Umano (Human Override)
L'intervento straordinario da parte di un operatore umano (`OPERATOR`) costituisce un meccanismo di garanzia e supporto e `MUST` conformarsi ai seguenti **5 principi normativi inderogabili**:

1. **Principio di Tracciabilità:** Ogni azione di override `MUST` generare una transizione registrata in modo immutabile nel ledger, contenente l'identificatore univoco dell'operatore.
2. **Principio di Autenticazione Forte:** L'override richiede una firma crittografica valida e il possesso esplicito del permesso `SC.PERMISSION.OPERATOR_OVERRIDE`.
3. **Principio di Spiegabilità Obbligatoria:** Ogni intervento di override `MUST` includere una motivazione esplicita espressa in formato testuale non vuoto nel campo `explanation`.
4. **Principio di Inalterabilità Storica:** L'override modifica unicamente lo stato proiettato corrente del sistema, ma `SHALL NOT` cancellare, sovrascrivere o alterare le transizioni precedentemente registrate nel ledger.
5. **Principio di Rispettabilità del Consenso:** L'operatore umano `SHALL NOT` forzare il trattamento dei dati o l'esecuzione di azioni in violazione del consenso espresso dall'utente.

---

## 5. EMANCIPATION PLAYBOOK ENGINE

### 5.1 Struttura del Grafo del Playbook
Un **Emancipation Playbook** è formalizzato come un grafo orientato composto da tre elementi:

1. **Nodi di Micro-Azione:** L'insieme delle singole unità operative o passi che compongono il percorso.
2. **Archi Orientati:** Le relazioni dirette tra i nodi che definiscono la sequenza logica di progressione ammissibile.
3. **Condizioni e Prerequisiti di Verificabilità:** L'insieme delle regole di controllo associati ai nodi, dove ogni condizione è un predicato puro che, valutato sullo stato del sistema, restituisce un valore booleano di `VERO` o `FALSO`.

### 5.2 Invarianti di Esecuzione e Tracking dello Stato Playbook
1. **`INV-PLAYBOOK-GRAPH-01` (Aclicienza Locale sui Passi Obbligatori):** Il sotto-grafo formato dai nodi contenenti azioni bloccanti (`is_blocking = true`) `MUST` essere un Grafo Diretto Aclicico (DAG), privo di qualsiasi ciclo o dipendenza circolare. La rilevazione di cicli bloccanti causa l'immediato rifiuto del Playbook con **Exit Code 23 (`ERR_GRAPH_CYCLE_DETECTED`)**.
2. **`INV-PLAYBOOK-STEP-02` (Durata Parametrizzata):** La durata stimata di una micro-azione non può superare il valore soglia definito dal parametro di durata massima presente nella policy attiva.
3. **`INV-PLAYBOOK-STATE-03` (Tracciamento dello Stato di Avanzamento):** Ogni avanzamento all'interno del grafo del playbook `MUST` aggiornare lo stato del playbook memorizzato nello stato globale, registrando l'ID del playbook, l'ID del nodo corrente e l'insieme aggiornato dei nodi completati, accompagnando la mutazione con la relativa provenienza dei dati (`DataProvenance`).

---

## 6. TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ

### 6.1 Spazio delle Versioni
Ogni componente versionabile di Scintilla Core appartiene allo spazio delle versioni ed è identificato da una tupla di tre numeri interi non negativi:

$$\text{Versione} = \langle \text{versione\_principale}, \text{versione\_secondaria}, \text{versione\_di\_correzione} \rangle$$

ovvero in formato standard: `major.minor.patch`.

### 6.2 Relazione di Compatibilità Retroattiva
Una versione $A$ è retro-compatibile con una versione $B$ se e solo se:
* Il numero di versione principale (`major`) di $A$ è esattamente uguale al numero di versione principale (`major`) di $B$;
* Il numero di versione secondaria (`minor`) di $A$ è minore di quello di $B$, oppure i numeri di versione secondaria sono uguali e il numero di patch di $A$ è minore o uguale a quello di $B$.

**Regola di Propagazione dell'Aggiornamento Major:**  
Qualsiasi incremento del numero di versione principale (`major`) dello schema dati richiede obbligatoriamente un incremento della versione principale delle transazioni e l'esecuzione esplicita di un manifesto di migrazione (`MigrationManifest`).

---

## 7. CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA

### 7.1 Mappatura Canonica Iniettiva (`Canon`)
Per garantire l'indipendenza da specifici formati di serializzazione o librerie software, il runtime definisce una funzione astratta di canonizzazione deterministica denominata `Canon`, che trasforma lo stato del sistema in una sequenza univoca di byte.

La funzione `Canon` `MUST` essere **iniettiva**: due stati distinti producono sempre due sequenze di byte distinte e, viceversa, due sequenze di byte identiche corrispondono allo stesso identico stato.

### 7.2 Costruzione della Catena di Hash Immutabile
La continuità e l'integrità del registro delle transazioni per la transazione $N$-esima sono garantite dal calcolo dell'impronta crittografica (checksum $H_N$) eseguito sul corpo della transazione (`TransactionBody`) di indice $N$:

1. Per la transazione iniziale di genesi (indice 0), l'impronta precedente $H_0$ è definita come una sequenza nullo di byte formata interamente da zeri.
2. Per ogni transazione successiva di indice $N$, l'impronta $H_N$ viene calcolata applicando la funzione di hash al corpo della transazione serializzato in forma canonica `Canon(TransactionBody)`, il quale include al suo interno il riferimento all'impronta $H_{N-1}$ della transazione precedente nel campo `prev_hash`.

---

## 8. FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEGLI EXIT CODES

### 8.1 Criteri Normativi di Accettazione PASS/FAIL
Un'implementazione esecutiva ottiene la **Certificazione di Conformità Scintilla Core** se e solo se soddisfa i seguenti tre criteri:

1. **Test Vector Match:** Corrispondenza bit-per-bit al $100\%$ sugli hash generati rispetto al profilo di riferimento applicato.
2. **Requisito di Verifica Temporale:** Soddisfazione al $100\%$ di tutte le proprietà logiche temporali stabilite (§9.2) all'interno del modello formale.
3. **Totalità Matematica:** Gestione corretta ed esaustiva di tutte le possibili combinazioni tra stati ed eventi sia per la macchina di sicurezza di runtime che per la macchina del percorso umano.

### 8.2 Tassonomia Normativa degli Exit Codes di Runtime
In caso di violazione degli invarianti di sicurezza o di fallimento delle precondizioni, il runtime `MUST` terminare immediatamente l'esecuzione restituendo unicamente uno dei seguenti Exit Code canonici:

* **Exit Code 13 (`ERR_INFRASTRUCTURE_IO`):** Fallimento dell'infrastruttura di I/O, mancata acquisizione del lease di concorrenza o scadenza del lock.
* **Exit Code 17 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrità crittografica della catena di hash, rilevazione di manomissione del ledger o fallimento delle verifiche di sicurezza.
* **Exit Code 20 (`ERR_SML_PARSE_FAILED`):** Errore di validazione sintattica dell'input SML v2.0 rispetto alla grammatica EBNF (§C.1).
* **Exit Code 23 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo illegale sui nodi bloccanti all'interno del grafo di un Emancipation Playbook.
* **Exit Code 24 (`ERR_SCHEMA_MISMATCH`):** Incompatibilità di versione dello schema dati non coperta da un manifesto di migrazione (`MigrationManifest`) valido.
* **Exit Code 25 (`ERR_CONFIGURATION_MALFORMED`):** Errore di formattazione o presenza di numeri fuori dall'intervallo consentito (*Strict Signed Safe Integer Range*).

---

## 9. MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE

### 9.1 Modello di Sistema Distribuito, Consistenza e Concorrenza
1. **Modello di Consistenza del Ledger:** Il registro delle transazioni garantisce la consistenza esterna e la lineare ordinabilità sequenziale (Strict Linearizability) per ciascun singolo identificatore di caso (`case_id`).
2. **Protocollo di Lock e Fencing Token:** La gestione delle scritture concorrenti si avvale di un meccanismo di lease a tempo. Ogni mutazione `MUST` verificare e incrementare in modo strettamente monotonico il valore del token di isolamento (`fencing_token`), espresso da un numero intero positivo.
3. **Tolleranza al Disallineamento Temporale (Clock Skew):** L'intervallo di tolleranza massima consentito tra l'orologio locale del nodo ed il tempo di riferimento standard è vincolato dal parametro di disallineamento temporale massimo (`Delta_t_max`) specificato nella configurazione della policy. Violazioni superiori a tale soglia forzano la transizione automatica della macchina di sicurezza allo stato `RECOVERABLE_FAILURE`.

---

### 9.2 Logica Temporale Normativa (Regole LTL e CTL)

#### Predicati Atomici di Stato
Sullo stato globale del sistema sono definiti i seguenti predicati booleani puri di controllo:
* **`IsSafetyGateAllowed`:** Restituisce valore VERO se e solo se la funzione di valutazione della policy attiva applicata allo stato e alla transazione proposta restituisce l'esito `ALLOW`.
* **`IsDecisionOutcomeAllowed`:** Restituisce valore VERO se e solo se l'esito decisionale presente nello stato del sistema è pari a `ALLOW` oppure a `NONE`.
* **`IsHashChainValid`:** Restituisce valore VERO se e solo se l'impronta crittografica (hash) calcolata sul corpo della transazione corrente coincide con l'impronta memorizzata.
* **`IsMonotonicFence`:** Restituisce valore VERO se e solo se il valore del token di fencing della transazione corrente è strettamente maggiore del valore del token di fencing della transazione precedente.

#### Proprietà LTL (Linear Temporal Logic)
* **LTL Safety 1 (Safety Gate / Policy Guidance):**
  * **Regola di Sicurezza Permanente 1:** In ogni istante di esecuzione e per tutti gli stati futuri del sistema, se il motore di policy (Safety Gate) non valuta una proposta come autorizzata (`IsSafetyGateAllowed` è FALSO), allora è tassativamente vietato che l'esito della decisione risulti valutato come consentito (`IsDecisionOutcomeAllowed` MUST essere FALSO).

* **LTL Safety 2 (Fencing & Lease Recovery):**
  * **Regola di Sicurezza Permanente 2:** In ogni istante di esecuzione, se la verifica di monotonicità del token di fencing fallisce (`IsMonotonicFence` è FALSO), allora nello stato immediatamente successivo la macchina di sicurezza del runtime MUST transizionare obbligatoriamente nello stato `RECOVERABLE_FAILURE`.

* **LTL Safety 3 (Hash Chain Integrity):**
  * **Regola di Sicurezza Permanente 3:** In ogni istante di esecuzione, se la verifica dell'integrità della catena di hash fallisce (`IsHashChainValid` è FALSO), allora nello stato immediatamente successivo la macchina di sicurezza del runtime MUST transizionare obbligatoriamente nello stato di isolamento rigido `SECURITY_LOCKDOWN`.

* **LTL Safety 4 (Unidirectional Automata Decoupling):**
  * **Regola di Sicurezza Permanente 4:** In ogni istante di esecuzione, qualsiasi variazione dello stato dell'automa del percorso umano non possiede alcuna autorità diretta di mutazione o modifica sullo stato della macchina di sicurezza del runtime (la mutazione diretta del runtime da parte dell'automa umano è sempre FALSA).

#### Proprietà CTL (Computation Tree Logic)
* **CTL Reachability (Accessibilità Permanente dell'Emancipazione):**
  * **Proprietà di Accessibilità Permanente:** Da qualsiasi stato raggiungibile lungo qualsiasi percorso di esecuzione, deve sempre esistere almeno un cammino futuro valido che consenta all'automa del percorso umano di raggiungere lo stato target di completamento `SUSTAINED_INDEPENDENCE`.

* **CTL Trap-Free Safety (Assenza di Stati Trappola Irrecuperabili):**
  * **Proprietà di Assenza di Stati Trappola:** Per tutti i possibili percorsi di esecuzione, se il runtime entra nello stato di isolamento `SECURITY_LOCKDOWN`, deve sempre esistere almeno uno stato immediatamente successivo valido in cui il sistema può rimanere in `SECURITY_LOCKDOWN` oppure evolvere verso lo stato `NORMAL` o lo stato `SAFE_READ_ONLY_MODE` mediante le opportune procedure di ripristino o override autorizzate.

---

# PARTE II: PROFILE ARCHITECTURE & CONCRETE REFERENCE PROFILES

---

## 10. STANDARD REFERENCE PROFILE 1 (JSON / SC-JCS-1 / SHA-256 / Ed25519)

Il presente capitolo definisce il **Profilo di Riferimento Concreto Predefinito (Profile 1)** per l'interoperabilità di primo livello.

### 10.1 Binding delle Primitive Crittografiche, Identificatori e Mapping dei Campi
* **Mappatura Identificatori:** Stringhe `UUIDv7` conformi a RFC 9562.
* **Mappatura Tempo:** Stringhe formattate secondo ISO 8601 / RFC 3339 UTC Z con precisione ai millisecondi.
* **Mappatura Hash:** Algoritmo **SHA-256** (digest di 32 byte / 64 caratteri esadecimali).
* **Mappatura Firma:** Algoritmo **Ed25519** (PureEd25519 su curva Ed25519).
* **Mapping 1-a-1 Esaustivo dei Campi di `TransactionBody` (§1.1.3):**
  1. Identificatore Transazione $\longrightarrow$ `"tx_id"`
  2. Identificatore Caso $\longrightarrow$ `"case_id"`
  3. Numero di Sequenza $\longrightarrow$ `"sequence_number"`
  4. Hash Precedente $\longrightarrow$ `"prev_decision_checksum"`
  5. Timestamp $\longrightarrow$ `"timestamp_utc"`
  6. Attore $\longrightarrow$ `"actor_id"`
  7. Evento $\longrightarrow$ `"event"`
  8. Payload $\longrightarrow$ `"payload"`
  9. Hash Binding Policy $\longrightarrow$ `"policy_binding_hash"`
  10. Versione Schema $\longrightarrow$ `"schema_version"`
  11. Identificatore Specifica $\longrightarrow$ `"specification_id"`

---

### 10.2 Il Profilo di Canonizzazione JSON SC-JCS-1
**Dichiarazione Normativa di Non-Equivalenza:** **SC-JCS-1 è un profilo di canonizzazione derivato e NON-COMPATIBILE a livello di hash con lo standard RFC 8785 JCS**.

#### 10.2.1 Sottoinsieme Canonico e Strict Signed Safe Integer Range
Un documento JSON appartiene al sottoinsieme canonico Scintilla se e solo se tutti i numeri presenti sono interi compresi nell'intervallo chiuso di sicurezza per interi con segno:

$$\text{Intervallo di Sicurezza Interi} = [\text{-9007199254740991}, \ \text{+9007199254740991}]$$

ovvero da $-(2^{53} - 1)$ a $+(2^{53} - 1)$.

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
     * `"permissions"`
     * `"scopes"`
     * `"roles"`
     * `"prerequisites"`
     * `"completed_nodes"`

---

### 10.3 Contratto JSON della Macchina di Sicurezza del Runtime
Il contratto JSON canonico della macchina degli stati di sicurezza di runtime per la convalida automatica delle transizioni è definito dal seguente documento schema (la valutazione delle transizioni nell'array `transitions` rispetta tassativamente l'ordine sequenziale top-down / *first-matching rule*):

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
1. **Fase 1: Validazione Sintattica (Syntactic Validation):** Eseguita dal Parser SML (Livello 4) per verificare il rispetto della grammatica EBNF (§C.1). Un fallimento sintattico produce l'evento di fallimento SML (`EV_SML_FAIL`) ed Exit Code 20 (`ERR_SML_PARSE_FAILED`).
2. **Fase 2: Validazione Semantica (Semantic Validation):** Eseguita dai livelli superiori (Livelli 3 e 2) sull'oggetto ipotesi strutturato. La validazione semantica controlla:
   * **Coerenza Logica:** Corrispondenza con lo stato corrente dell'automa del percorso umano;
   * **Integrità della Provenienza:** Verifica che i dati dichiarati siano marcati con la corretta `DataProvenanceRecord` (§1.4);
   * **Valutazione della Confidenza:** Verifica del superamento della soglia parametrizzata di confidenza presente nella policy attiva;
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
