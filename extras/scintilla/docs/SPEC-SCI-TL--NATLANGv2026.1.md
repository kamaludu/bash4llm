[![Specifica](https://img.shields.io/badge/%E2%9C%B4_SCINTILLA-CORE_CANONICAL_SPECIFICATION-2ea44f?style=for-the-badge&labelColor=gold)](SPEC-SCINTILLA-TIMELESS-v2026.1.md)

# ✴ SCINTILLA Core - SPECIFICA NORMATIVA CANONICA INTEGRALE IN LINGUAGGIO NATURALE
## Edizione Standard Canonica v4.5.5
*(Equivalente al 100% alla Specifica Formale - Single Source of Truth)*

---

* **Stato del Documento:** Specifica Normativa Canonica Integrale in Linguaggio Naturale (Single Source of Truth).
* **Edizione:** v4.5.5 Candidate Canonical Standard Edition.
* **Destinatari:** Chiunque possieda un titolo di studio di scuola secondaria di secondo grado (diploma). Non è richiesta alcuna competenza preventiva in programmazione, crittografia, matematica avanzata o diritto.
* **Autorità Normativa:** Questo documento definisce in prosa discorsiva le medesime regole, vincoli ed invarianti espressi nelle formule matematiche della specifica formale.
* **Terminologia Normativa Vincolante:** Nel testo vengono usati i termini standard internazionali per indicare gli obblighi:
  * **`MUST` / `OBBLIGATORIO` / `SHALL`:** Indica un requisito assoluto ed inderogabile.
  * **`MUST NOT` / `VIETATO` / `SHALL NOT`:** Indica un divieto assoluto ed inderogabile.
  * **`SHOULD` / `RACCOMANDATO`:** Indica una raccomandazione fortemente consigliata, derogabile solo per valide e comprovate ragioni tecniche.
  * **`MAY` / `OPZIONALE`:** Indica una facoltà del tutto facoltativa.
* **Regola di Precedenza Normativa (`RULE-NORMATIVE-PRECEDENCE-01`):** In caso di qualsiasi apparente divergenza interpretativa tra la descrizione narrativa in linguaggio naturale ed i contratti esecutivi elaborabili dai calcolatori (Capitolo 10), i contratti esecutivi costituiscono l'autorità normativamente prevalente per l'esecuzione del software.

---

# MISSIONE

## a) Scopo, Natura e Missione della Specifica

La presente specifica definisce **SCINTILLA Core**, il Kernel (nucleo centrale) Normativo Canonico progettato per la costruzione di sistemi informatici deterministici destinati a supportare l'emancipazione personale e l'autonomia operativa di persone fragili, vulnerabili o in situazione di instabilità.

SCINTILLA Core costituisce la fonte unica ed autoritativa di verità del dominio (*Single Source of Truth*). Essa definisce, in modo formale, deterministico e pienamente verificabile, l'insieme dei comportamenti osservabili, degli invarianti irrinunciabili e dei vincoli normativi che qualsiasi applicazione software conforme **`MUST`** preservare nel tempo.

La missione fondamentale del Kernel è ridurre gli ostacoli cognitivi (la difficoltà di comprendere cosa fare), informativi (la mancanza di chiarezza sulle risorse), organizzativi (la confusione nella sequenza dei passi) ed emotivi (lo scoraggiamento o la sopraffazione) che impediscono ad una persona di passare dall'intenzione all'azione concreta.

Il sistema è progettato affinché l'intelligenza artificiale aumenti le capacità umane senza mai produrre dipendenza psicologica, manipolazione comportamentale o perdita di autodeterminazione.

SCINTILLA Core è una specifica normativa pura: non costituisce un prodotto software commerciale, un'interfaccia utente, un chatbot o un'applicazione mobile, ma il contratto di garanzia ed il modello di regole sulla cui base tali strumenti possono essere costruiti in modo sicuro.

---

**NOTA INFORMATIVA: Che cos'è un Kernel Normativo?**  
In campo informatico, un "Kernel" è il cuore fondamentale di un sistema operativo, la parte che gestisce le regole base e le risorse essenziali. Un "Kernel Normativo" è un insieme di regole matematiche e logiche che stabiliscono esattamente cosa il software può fare e cosa gli è tassativamente vietato, garantendo che il sistema rispetti sempre i diritti dell'utente.

---

## b) Ambito Normativo

La presente specifica disciplina ed individua in modo rigoroso:
- Il **Modello di Stato** (la struttura completa delle informazioni memorizzate dal sistema);
- La **Semantica delle Transazioni** (come una richiesta viene convalidata ed eseguita);
- Il **Ledger Immutabile** (il registro storico inalterabile delle decisioni);
- Gli **Automi a Stati Finiti** (i motori logici che guidano la sicurezza ed il percorso dell'utente);
- Gli **Invarianti di Sicurezza** (le regole che non possono mai essere violate in nessuna circostanza);
- Le **Politiche di Sicurezza e Riservatezza** (la gestione dei permessi e la cancellazione dei dati);
- I **Diritti dell'Utente** (il consenso, la pausa del percorso ed il diritto all'oblio);
- Gli **Obblighi di Conformità** (i test che un software deve superare per essere dichiarato conforme).

Nessun sistema software che si dichiari conforme a SCINTILLA Core può derogare o modificare gli invarianti ed i vincoli normativi stabiliti da questa specifica.

---

## c) Componenti Esterni al Kernel

Qualsiasi componente tecnologico non esplicitamente definito all'interno di questa specifica è considerato esterno al Kernel. Appartengono a questa categoria:
- I modelli linguistici di intelligenza artificiale (LLM);
- I motori di ricerca e le basi di conoscenza esterne (RAG);
- Le interfacce grafiche utente (applicazioni per smartphone, siti web);
- I servizi cloud ed i sistemi di autenticazione di terze parti.

La presenza, l'assenza o la sostituzione di tali componenti esterni non modifica in alcun modo la validità e la semantica normativa di SCINTILLA Core. Essi costituiscono semplici strumenti ausiliari di supporto, ma non possiedono alcuna autorità decisionale sullo stato interno del sistema.

---

**NOTA INFORMATIVA: Che cos'è un Modello Linguistico (LLM)?**  
Un Modello Linguistico di Grandi Dimensioni (LLM, come ChatGPT) è un programma probabilistico capace di elaborare e generare testo in linguaggio umano. In SCINTILLA Core, l'LLM viene usato esclusivamente per conversare, spiegare e motivare, ma **non ha alcun potere di prendere decisioni** o di modificare i dati dell'utente. Le decisioni sono delegate unicamente alle regole matematiche e deterministiche del Kernel.

---

## d) Rapporto con le Implementazioni Software

La presente specifica definisce esclusivamente il "cosa" il sistema deve fare, lasciando alle singole implementazioni software la scelta del "come" realizzarlo.

Un'applicazione software realizzata in qualsiasi linguaggio di programmazione (es. Rust, Go, TypeScript, Java) è dichiarata conforme a SCINTILLA Core se, e solo se, il suo comportamento osservabile e la sua gestione dei dati rispettano al 100% gli invarianti e i contratti definiti in questo documento.

---

## e) Separazione tra Componenti Deterministiche e Probabilistiche

SCINTILLA Core traccia una linea di demarcazione assoluta ed insuperabile tra due categorie di componenti:

1. **Componenti Probabilistiche (es. Intelligenza Artificiale / LLM):** Hanno il solo ed unico compito di generare ipotesi, suggerimenti, spiegazioni conversazionali o traduzioni testuali. Esse sono intrinsecamente soggette a possibili imprecisioni ed **`MUST NOT`** possedere alcuna autorità di scrittura diretta sullo stato del sistema o sulle decisioni operative.
2. **Componenti Deterministiche (Il Kernel SCINTILLA Core):** Sono algoritmi matematici certi e riproducibili al 100%. Qualsiasi modifica della memoria, avanzamento di percorso o concessione di permessi **`MUST`** avvenire esclusivamente attraverso l'applicazione delle regole deterministiche del Kernel.

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE
## (Layer B1 - Assunzioni Normative & Principi Etici)

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

L'intero dominio di SCINTILLA Core è progettato attorno ad un unico grande obiettivo: **aumentare la capacità concreta e reale di una persona in difficoltà di trasformare una condizione di disagio o instabilità in un percorso strutturato di autonomia e crescita personale**.

#### 0.1.1 Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)
Ogni regola, algoritmo, automa o trasformazione di dati all'interno del sistema **`MUST`** conformarsi incondizionatamente e sempre al seguente principio supremo:

> **"SCINTILLA Core ha la missione di creare un automa di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e l'agency delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volontà e senza mai supportare azioni incompatibili con la dignità umana, la sicurezza ed i diritti altrui."**

#### 0.1.2 Tassonomia Concettuale dell'Agency Responsabile
Con il termine **Agency Operativa Responsabile**, il sistema indica la capacità della persona di guidare la propria vita, definita attraverso sei dimensioni fondamentali:
1. **Capacità di Azione:** La facoltà concreta di compiere piccoli passi pratici (micro-azioni) orientati ad un fine;
2. **Comprensione del Contesto:** La chiarezza informativa su quali siano i propri vincoli, le risorse disponibili e le opportunità;
3. **Valutazione delle Alternative:** La capacità di confrontare diverse strade possibili comprendendone rischi e benefici;
4. **Pianificazione:** La facoltà di scomporre un obiettivo grande e complesso in una sequenza ordinata di passaggi semplici;
5. **Perseveranza:** La capacità di mantenere l'impegno nel tempo e di gestire le battute d'arresto senza abbandonare il percorso;
6. **Percezione di Controllo:** La consapevolezza interiore di essere i veri ed unici protagonisti del proprio cambiamento.

*Nota Normativa:* L'Agency Operativa Responsabile è un valore umano qualitativo. Essa **non viene mai misurata come un voto o un punteggio morale** sulla persona, ma rappresenta la guida etica dell'intero sistema.

---

### 0.2 ASSIOMI DI NON-PATERNALISMO E AUTODETERMINAZIONE

#### 0.2.1 Invariante Anti-Paternalista (`INV-ANTI-PATERNALISM-01`)
Il sistema **`SHALL NOT`** (non deve mai) adottare un atteggiamento paternalistico basato sull'idea presuntuosa che "il software o l'intelligenza artificiale sappiano cosa sia meglio per l'utente".

In nessuna circostanza il sistema può prendere decisioni di vita al posto della persona. Il sistema **`SHALL`**:
1. Aiutare la persona a capire la propria situazione analizzando vincoli e risorse;
2. Proporre opzioni pratiche chiare e contestualizzate;
3. Spiegare in modo trasparente rischi, prerequisiti e conseguenze di ogni scelta;
4. Affiancare la persona nella costruzione e nel rispetto del proprio piano d'azione personalizzato (Playbook).

#### 0.2.2 Assioma di Sovranità del Consenso Umano (`AXIOM-HUMAN-CONSENT-SOVEREIGNTY`)
> **"L'utente umano costituisce l'autorità decisionale suprema ed inalienabile del proprio percorso. Nessuna raccomandazione del sistema, inferenza dell'intelligenza artificiale o suggerimento di un operatore umano può modificare lo stato di avanzamento personale senza il consenso esplicito, informato e sempre revocabile dell'utente."**

---

### 0.3 DISACCOPPIAMENTO PERSONA-COMPORTAMENTO E DIRITTI

#### 0.3.1 Invariante di Separazione Persona-Comportamento (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)
Il sistema **`MUST`** mantenere una distinzione formale ed assoluta tra l'**Identità della Persona** (chi è l'utente) e lo specifico **Contenuto della Richiesta** avanzata in un dato momento.

1. **Inviolabilità della Dignità Umana:** Ogni persona, indipendentemente dai suoi trascorsi personali, legali, finanziari o sociali, ha il diritto inalienabile di ricevere il supporto del sistema per migliorare la propria vita. L'identità dell'utente non deve mai essere oggetto di giudizio, stigmatizzazione o squalifica morale.
2. **Valutazione Oggettiva della Richiesta:** La funzione di controllo del sistema valuta esclusivamente se la specifica azione richiesta sia sicura, legale e sostenibile, senza mai esprimere valutazioni di merito sulla persona che l'ha formulata.

---

**NOTA INFORMATIVA: Che cos'è un Invariante di Sistema?**  
In ingegneria del software, un "invariante" è una condizione logica o matematica che deve rimanere SEMPRE vera, prima, durante e dopo qualsiasi operazione. Se un'azione rischia di violare un invariante, il sistema blocca immediatamente l'operazione per garantire la sicurezza assoluta del sistema e dell'utente.

---

# CAPITOLO 1: LO STATO DEL SISTEMA, IL REGISTRO IMMUTABILE ED I CONTATORI DI AVANZAMENTO
## (Layer A & Layer B1/B2)

---

### 1.1 Formalizzazione dello Spazio degli Stati e delle sue Componenti

Lo **Spazio degli Stati** rappresenta l'insieme di tutte le informazioni che il sistema memorizza e gestisce in un dato istante. In SCINTILLA Core, lo stato totale di un utente è suddiviso in modo ortogonale e rigoroso in tre grandi contenitori:

1. **Dominio di Persistenza permanente (Ricostruibile dal Registro):** Contiene i dati storici fondamentali del percorso, tra cui:
   * L'identificativo del caso utente;
   * La traccia dell'origine delle informazioni (provenienza dei dati);
   * Il registro dei consensi forniti o revocati;
   * Lo stato attuale del piano d'azione guidato (Playbook);
   * L'elenco degli elementi informativi di cui l'utente ha richiesto l'oscuramento (revoca privacy);
   * La palestra delle competenze pratiche acquisite nel tempo;
   * La custodia sicura dei documenti d'identità e degli attestati (Vault).
2. **Dominio Interno di Controllo e Sicurezza (Gestito dal Runtime):** Contiene i parametri operativi di funzionamento, tra cui:
   * Lo stato corrente dell'automa di sicurezza del software ($Q$);
   * Lo stato corrente dell'automa del percorso umano ($Q_H$);
   * Le regole di sicurezza attive (Policy Bundle);
   * Le chiavi temporali di sincronizzazione per impedire accessi simultanei e contrastanti (Fencing Lease);
   * La tupla dei contatori delle interazioni;
   * Il numero progressivo di sequenza e l'impronta crittografica (hash) dell'ultima operazione.
3. **Dominio Ausiliario Volatile (Bozze temporanee):** Un'area di lavoro temporanea utilizzata per la co-creazione di contenuti (es. la bozza di un curriculum o di una lettera), che non altera lo stato permanente finché non viene confermata dall'utente.

---

### 1.1.2 Vista Derivata e Contatori di Interazione

Il sistema mantiene una tupla di **quattro contatori numerici cumulativi** che registrano l'andamento del dialogo e dell'operatività:
1. $c_{\text{interaction}}$: Il numero totale di interazioni valide e completate con successo.
2. $c_{\text{rephrase}}$: Il numero di volte in cui l'utente ha chiesto di rispiegare o semplificare un concetto.
3. $c_{\text{ambiguity}}$: Il numero di volte in cui il sistema ha riscontrato ambiguità ed ha richiesto una ricalibrazione.
4. $c_{\text{overwhelm}}$: Il numero di volte in cui l'utente ha segnalato uno stato di stanchezza o sopraffazione emotiva.

Questi contatori servono unicamente al software per comprendere se la comunicazione è chiara o se occorre adottare un linguaggio più semplice e graduale.

---

### 1.2 Interfaccia Osservabile Pubblica ed Equivalenza di Stato

#### 1.2.1 Vista Pubblica (`Obs`)
La funzione di osservazione pubblica rappresenta la "finestra" attraverso cui l'utente o le applicazioni esterne vedono lo stato del sistema. Per tutelare la privacy ed i diritti della persona:
* La vista pubblica mostra lo stato del percorso, i consensi attivi, le competenze e i documenti validi;
* La vista pubblica **`MUST` nascondere ed oscurare immediatamente qualsiasi documento, consenso o competenza di cui l'utente abbia richiesto la revoca logica** (tramite l'inserimento nell'elenco degli elementi revocati).

#### 1.2.2 Invariante di Irrilevanza del Buffer Temporaneo (`INV-AUX-IRRELEVANCE`)
Le modifiche apportate nell'area ausiliaria volatile (le bozzedi lavoro temporanee) non alterano in alcun modo i diritti, la sicurezza storica o lo stato di avanzamento ufficiale dell'utente. Se due stati sono identici nella memoria permanente e di controllo, essi sono semanticamente equivalenti a tutti gli effetti normativi.

---

### 1.3 Lo Stato Iniziale di Genesi ($s_0$) ed Invarianza di Serializzazione

Quando un nuovo percorso utente viene creato, il sistema si trova nello **Stato di Genesi ($s_0$)**:
* Tutti gli insiemi di dati (consenti, competenze, documenti, revoche) sono rigorosamente **vuoti**;
* L'automa di sicurezza è nello stato `NORMAL`;
* L'automa del percorso umano è nello stato `UNASSESSED` (Non Valutato);
* I contatori numerici sono tutti azzerati ($0$);
* Il numero di sequenza delle operazioni è $0$ e l'impronta crittografica iniziale è costituita da una sequenza di zeri.

#### 1.3.1 Obbligo Formale di Invarianza di Serializzazione (RFC-007)
Per garantire che il passaggio alla nuova versione del sistema (v4.5.5) non introduca discrepanze nei sistemi esistenti, il flusso di byte e l'impronta crittografica generati dalla rappresentazione digitale dello Stato di Genesi $s_0$ **`MUST`** risultare bit-a-bit identici a quelli generati dalla versione precedente (v4.5.3).

---

### 1.4 TRANSAZIONI, INVOLUCRO DI ESECUZIONE E REGISTRO IMMUTABILE (LEDGER)

Ogni singola azione, avanzamento o richiesta all'interno di SCINTILLA Core viene rappresentata come una **Transazione ($t$)**.

Una transazione è composta da tre elementi:
1. **Il Corpo della Transazione (`TransactionBody`):** Contiene l'identificativo unico del caso, il numero progressivo di sequenza, l'impronta crittografica dell'operazione precedente, il timestamp temporale, l'autore dell'azione (utente, sistema, operatore), l'evento ed il carico utile dei dati (payload);
2. **L'Involucro di Esecuzione (`Execution Envelope`):** I metadati generati dal sistema che certificano se l'operazione è stata elaborata con successo, se è stata rifiutata o se è stata elaborata senza produrre modifiche (es. quando il percorso è in pausa);
3. **La Prova Crittografica (`proof`):** La firma digitale che ne garantisce l'autenticità.

---

**NOTA INFORMATIVA: Che cos'è un Ledger (Libro Mastro Immutabile)?**  
Un Ledger è un registro digitale organizzato come una catena di montaggio: ogni nuova operazione viene scritta subito dopo la precedente e legata ad essa mediante una cifra crittografica (hash). Una volta scritta, una transazione non può più essere modificata o cancellata da nessuno. Se si vuole correggere un errore, occorre scrivere una nuova transazione di rettifica. Questo garantisce un'onestà e una trasparenza totale sul passato.

---

#### 1.4.1 Il Ledger come Monoide Libero e la Funzione di Persistenza
Il registro delle decisioni (Ledger $\mathcal{L}$) è un registro **append-only** (a sola aggiunta). La funzione di persistenza prende una transazione valida, ne calcola la codifica canonica e la concatena in modo sequenziale ed irreversibile in fondo al registro.

#### 1.4.2 Invariante di Consistenza della Proiezione del Ledger
In qualsiasi momento, lo stato corrente del sistema espresso dalla memoria di lavoro **`MUST`** coincidere perfettamente ed in modo deterministico con il risultato della rielaborazione sequenziale di tutte le transizioni scritte sul Ledger a partire dallo Stato di Genesi $s_0$.

---

### 1.5 PRIVACY: REVOCA LOGICA PARZIALE ED OBLIO CRITTOGRAFICO TOTALE

SCINTILLA Core implementa due livelli distinti di tutela della riservatezza e gestione dei diritti dell'utente:

#### 1.5.1 Revoca Logica Parziale (`SOFT_LOGICAL_REVOCATION`)
Quando un utente decide di revocare l'accesso ad uno specifico documento, consenso o competenza precedentemente inserito:
* Il sistema registra una transazione ufficiale di revoca (`EV_ITEM_PRIVACY_REVOKED`);
* L'identificatore della risorsa viene aggiunto all'insieme degli elementi revocati;
* Da quel momento in poi, le API e la vista pubblica `Obs` nascondono completamente l'elemento, restituendo un valore nullo ($\bot$);
* *Invariante di Integrità:* La revoca logica oscura il dato informativo, ma **non cancella l'identificatore del passaggio completato dal grafo del Playbook**, consentendo al sistema di mantenere intatta la coerenza del percorso svolto senza bloccare il flusso operativo.

#### 1.5.2 Oblio Crittografico Totale (`FULL_CRYPTO_SHREDDING`)
Qualora l'utente richieda la cancellazione totale e definitiva dell'intero caso e di ogni suo dato personale:
* Il modulo di sicurezza procede alla **distruzione irreversibile della chiave crittografica radice** ($K_{\text{case}}$) custode dei dati utente memorizzata nel sistema KMS;
* Senza tale chiave, tutti i dati cifrati contenuti nel registro storico diventano matematicamente ed irreversibilmente illeggibili (rumore casuale), rendendo impossibile qualsiasi recupero;
* L'atto di distruzione viene certificato registrando sul Ledger la transazione formale finale `EV_CRYPTO_SHRED_EXECUTED`.

---

**NOTA INFORMATIVA: Che cos'è il Crypto-Shredding (Distruzione Crittografica)?**  
Immagina di riporre i tuoi documenti riservati in una cassaforte d'acciaio indistruttibile. Invece di tentare di distruggere la cassaforte o i fogli al suo interno, prendi l'unica chiave esistente che può aprirla e la fondi al crogiolo. La cassaforte ed i fogli rimangono lì, ma nessuno al mondo potrà mai più leggerne il contenuto. Il Crypto-Shredding è l'equivalente digitale della distruzione della chiave.

---

### 1.6 VALIDAZIONE AMBIENTALE E FUNZIONE PURA DI TRANSIZIONE

Il processo di modifica dello stato avviane attraverso una netta separazione tra controlli esterni e mutazione interna:

1. **Validazione Ambientale Impura (`ValidateEnvironment`):** Prima di applicare una transazione, il sistema verifica le condizioni esterne di contesto:
   * La validità della firma digitale crittografica;
   * La concordanza dell'orologio temporale (il timestamp non deve superare la tolleranza massima di disallineamento `clock_skew`);
   * La validità della chiave di concorrenza (`fencing_token`) per evitare sovrascritture simultanee.
2. **Funzione Pura di Transizione (`ApplyValidated`):** Una volta superati i controlli ambientali, la funzione pura di transizione modifica lo stato del sistema in modo totalmente deterministico. Se la validazione fallisce, la funzione applica una transizione di errore o porta il sistema in stato di blocco di sicurezza (`SECURITY_LOCKDOWN`) in caso di corruzione della catena di hash.

---

### 1.7 INDICE PROXY OPERATIVO DI GUADAGNO DI AGENCY (`AGI_proxy`)

L'Indice Proxy **`AGI_proxy`** è un valore numerico intero compreso tra $0$ e $10000$ (espresso in Basis Points, ovvero da 0,00% a 100,00%) che fornisce un'indicazione descrittiva sull'andamento dell'operatività dell'utente all'interno del sistema.

---

**NOTA INFORMATIVA: Chiarimento fondamentale sull'acronimo AGI_proxy**.  
Nelle tecnologie moderne, l'acronimo "AGI" viene spesso usato per indicare l'Intelligenza Artificiale Generale (*Artificial General Intelligence*). **In SCINTILLA Core, AGI_proxy NON ha alcuna relazione con l'Intelligenza Artificiale Generale.**  
L'acronimo indica esclusivamente l'**Agency Governance Indicator Proxy** (Indicatore Proxy di Governance dell'Agency Operativa): una misura matematica descrittiva usata dal software per capire se l'interfaccia digitale sta aiutando la persona o se la sta confondendo.

---

#### 1.7.1 Assunzione di Confine Epistemico ed Isolamento Descrittivo
L'indice `AGI_proxy` è un indicatore descrittivo e **`MUST NOT`** (non deve mai) essere utilizzato per condizionare, limitare o bloccare i diritti di accesso dell'utente o le decisioni del sistema (`INV-AGI-DESCRIPTIVE-ISOLATION`). Un utente con un indice basso conserva esattamente i medesimi diritti di scelta e di consenso di un utente con un indice alto.

#### 1.7.2 Invarianza durante la Pausa del Percorso
Se l'utente decide di mettere in pausa il proprio percorso umano (stato `HUMAN_PAUSED`), il valore dell'indice `AGI_proxy` viene congelato e rimane perfettamente identico al valore dello stato precedente per tutta la durata della stasi.

#### 1.7.3 Calcolo Deterministico dell'Indice in Aritmetica Intera Sicura
Per tutti gli stati attivi, l'indice `AGI_proxy` viene calcolato mediante una media ponderata di tre sotto-punteggi (ciascuno espresso in Basis Points da 0 a 10000):

1. **Punteggio di Chiarezza (`ClarityScore_bp`):** Valuta quanto la comunicazione sia fluida. Diminuisce se l'utente deve chiedere spesso di rispiegare i concetti ($c_{\text{rephrase}}$) o se riscontra sopraffazione emotiva ($c_{\text{overwhelm}}$).
2. **Rapporto di Esecuzione delle Azioni (`ActionExecutionRatio_bp`):** Misura la percentuale di micro-passi completati dall'utente all'interno del piano d'azione (Playbook) attivo rispetto al totale dei passi previsti.
3. **Punteggio di Riduzione della Dipendenza (`DependencyReductionScore_bp`):** Misura la percentuale di azioni completate con successo dall'utente che hanno portato all'acquisizione di competenze pratiche riutilizzabili in autonomia.

Tutti i calcoli sono eseguiti rigorosamente in **aritmetica intera con numeri a 64-bit**, escludendo del tutto l'uso di numeri con virgola mobile per garantire che il risultato sia identico al 100% su qualsiasi calcolatore.

---

**NOTA INFORMATIVA: Che cosa sono i Basis Points (Punti Base)?**  
Nei calcoli di alta precisione, l'uso di numeri con la virgola (virgola mobile) può causare impercettibili arrotondamenti diversi a seconda del computer utilizzato. Per evitare questo problema e garantire un determinismo assoluto, SCINTILLA Core esprime tutte le percentuali moltiplicandole per 100: il valore 0% diventa 0, il valore 50% diventa 5000 ed il valore 100% diventa 10000 Basis Points. In questo modo si usano solo numeri interi matematicamente esatti.

---

### 1.8 CONTRATTO DEL MODULO CRITTOGRAFICO ASTRATTO (`CryptoProviderContract`)

Ogni applicazione conforme a SCINTILLA Core **`MUST`** integrare un modulo di crittografia che metta a disposizione sei operazioni fondamentali:
1. **Derivazione Chiavi (`DeriveKey`):** Generazione deterministica di chiavi crittografiche derivate a partire da una chiave madre;
2. **Cifratura Dati (`EncryptPayload`):** Cifratura simmetrica autenticata per rendere i dati personali inintelligibili a terzi;
3. **Decifratura Dati (`DecryptPayload`):** Decifratura ed autenticazione dei dati mediante la chiave corretta;
4. **Distruzione Chiave (`ShredKey`):** Cancellazione definitiva ed irreversibile di una chiave per attuare l'oblio crittografico;
5. **Verifica Firma (`VerifySignature`):** Controllo della validità della firma digitale a chiave pubblica associata ad una transazione;
6. **Verifica Presenza Chiave (`LookupKey`):** Controllo della presenza della chiave attiva nel sistema di custodia KMS.

I dettagli tecnici degli algoritmi crittografici concreti (AES-256-GCM per la cifratura, Ed25519 per le firme digitali) sono definiti in modo stringente nel Profilo Concreto di Riferimento SC-JCS-1 (Capitolo 10).

---

# CAPITOLO 2: ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI
## (Layer A & Layer B2)

---

### 2.1 Modello di Isolamento Stratificato a 6 Livelli

L'architettura di SCINTILLA Core è organizzata come una torre di 6 livelli funzionali sovrapposti, separati da un principio di **isolamento unidirezionale rigoroso**. 

I livelli superiori (quelli più vicini all'interfaccia utente ed all'intelligenza artificiale conversazionale) non possiedono **alcuna autorità o capacità di scrittura diretta** sullo stato del sistema o sulla memoria di runtime. Ogni informazione o proposta deve scendere verso il basso attraversando rigorosi cancelli di validazione:

```text
[ LIVELLO 5 ] Modello Linguistico di Intelligenza Artificiale (Generatore Probabilistico)
     │ Contratto API: Genera unicamente testo sintattico SML v2.0 (Zero autorità di stato)
[ LIVELLO 4 ] Livello di Comunicazione, Parsing SML e Validazione Sintattica
     │ Contratto API: Decodifica il testo e crea oggetti di provenienza dati strutturati
[ LIVELLO 3 ] Motore di Interazione Umana, Consenso ed Agency (Consenso, Registro & HOBM)
     │ Contratto API: Valuta il contesto umano, i consensi attivi e l'indice AGI_proxy
[ LIVELLO 2 ] Motore delle Politiche e della Guida (Policy Guidance Engine & Safety Gate)
     │ Contratto API: Compila e valuta le regole esecutive pure (DecisionResult)
[ LIVELLO 1 ] Runtime Deterministico Kernel (Validazione Ambientale e Transizione Pura δ)
     │ Contratto API: Gestisce il lock di concorrenza e muta lo stato in modo puro
[ LIVELLO 0 ] Registro Immutabile delle Decisioni (Ledger Append-Only su File NDJSON)
```

---

**NOTA INFORMATIVA: Perché l'Isolamento a 6 Livelli è così importante?**  
Nei comuni sistemi di intelligenza artificiale, l'LLM (il modello linguistico) dialoga con l'utente e spesso modifica direttamente i dati o prende decisioni. In SCINTILLA Core questo è **tassativamente vietato**. L'LLM si trova al Livello 5 (il più alto ed esterno) e non può toccare la memoria. Per fare qualsiasi cosa, la risposta dell'LLM deve scendere al Livello 4 (che la controlla sintatticamente), poi al Livello 2 (che verifica le regole di sicurezza) ed infine al Livello 1 (il Kernel deterministico). Se l'LLM inventa o sbaglia qualcosa, i livelli sottostanti lo bloccano immediatamente.

---

### 2.2 Automa di Sicurezza di Runtime ($M$)

L'operatività tecnica e la sicurezza del software sono modellate da un automa a stati finiti ad alta priorità, denominato **DP-FSM (Deterministic Priority Finite State Machine) $M$**.

L'automa $M$ si trova sempre ed unicamente in uno dei seguenti **7 Stati Canonici di Sicurezza**:

1. **`NORMAL` ($q_0$):** Lo stato operativo standard. Il sistema elabora nominalmente le richieste dell'utente e dell'applicazione;
2. **`REQUIRE_RECALIBRATION` ($q_1$):** Stato di ricalibrazione. Attivato quando una richiesta risulta ambigua o quando l'utente abbandona un'azione, richiedendo un chiarimento conversazionale;
3. **`VALIDATION_ERROR` ($q_2$):** Stato di errore di validazione. Attivato quando giunge un input malformato o sintatticamente errato;
4. **`RECOVERABLE_FAILURE` ($q_3$):** Stato di fallimento recuperabile. Attivato quando si verifica un problema tecnico temporaneo (es. scadenza del lock di concorrenza);
5. **`OPERATOR_REQUIRED` ($q_4$):** Stato di intervento operatore. Attivato quando il sistema riscontra un blocco tecnico non risolvibile automaticamente, richiedendo l'autorizzazione esplicita di un operatore umano qualificato;
6. **`SECURITY_LOCKDOWN` ($q_5$):** Stato di blocco critico di sicurezza. Attivato immediatamente quando viene rilevata una violazione o manomissione dell'integrità crittografica del Ledger (`EV_HASH_CORRUPT`). In questo stato, qualsiasi operazione ordinaria è paralizzata;
7. **`SAFE_READ_ONLY_MODE` ($q_6$):** Stato di sola lettura sicura. L'automa consente all'utente di consultare i propri dati e di esercitare i propri diritti di privacy, ma impedisce qualsiasi nuova mutazione operativa.

Lo stato iniziale di partenza dell'automa $M$ è sempre **`NORMAL`**. Gli unici due stati considerati **operativamente stabili** in cui il sistema può rimanere a riposo sono `NORMAL` e `SAFE_READ_ONLY_MODE`.

---

**NOTA INFORMATIVA: Che cos'è un Automa a Stati Finiti (FSM)?**  
Un automa a stati finiti è un modello matematico che funziona come un semaforo o una porta automatica: il sistema può trovarsi in un solo "stato" alla volta (es. "Rosso", "Giallo", "Verde"). Quando arriva un evento (es. la pressione di un pulsante o un sensore), l'automa segue una regola precisa per passare allo stato successivo. Non esistono stati intermedi o incerti.

---

#### 2.2.1 Regola di Risoluzione delle Priorità e Risoluzione dei Caratteri Jolly (Wildcard)
Per evitare qualsiasi ambiguità nelle transizioni, l'automa applica la **Funzione di Risoluzione Prioritaria (`Resolve`)** a 4 livelli:
1. Se esiste una regola esplicita definita per lo (*Stato Corrente*, *Evento Corrente*), essa viene applicata con massima priorità;
2. Se esiste una regola definita per lo (*Stato Jolly `*`*, *Evento Corrente*), essa si applica a qualsiasi stato;
3. Se nell'indicazione dello stato di destinazione compare il carattere jolly `"*"` (`RULE-WILDCARD-TARGET-REFLEXIVITY`), il sistema interpreta la transizione come un'identità (*stuttering step*), ovvero **mantiene invariato lo stato corrente** senza produrre modifiche.

#### 2.2.2 Gestione della Stasi Operativa nello Stato SAFE_READ_ONLY_MODE ($q_6$)
Quando l'automa $M$ si trova nello stato di sola lettura sicura $q_6$:
* Qualsiasi evento operativo o di business ($\Sigma_{\text{business}}$) produce uno *stuttering step* ($q_6 \to q_6$), impedendo la modifica dei dati;
* Gli **eventi amministrativi e di tutela dei diritti** ($\Sigma_{\text{administrative}}$, come la revoca della privacy o il Crypto-Shredding) **`MUST`** essere recepiti ed elaborati ed immagazzinati sul Ledger, garantendo all'utente l'esercizio inalienabile dei propri diritti anche durante una stasi tecnica;
* Gli eventi di ripristino autorizzato ($\Sigma_{\text{recovery}}$) possono riportare il sistema nello stato `NORMAL` previa applicazione di una patch di riparazione formale.

---

### 2.3 Automa del Percorso Umano ($\mathcal{H}$)

Mentre l'automa $M$ gestisce la sicurezza del software, l'evoluzione ed il progresso personale dell'utente sono modellati da un secondo automa di dominio, denominato **Human Journey State Machine ($\mathcal{H}$)**.

L'automa $\mathcal{H}$ definisce la posizione dell'utente all'interno di **12 Stati del Percorso Umano**:

1. **`UNASSESSED` ($h_0$):** Stato iniziale. Il percorso dell'utente non è ancora stato valutato;
2. **`INITIAL_ASSESSMENT` ($h_1$):** Fase di prima accoglienza ed analisi dei bisogni, vincoli e risorse;
3. **`STABILIZATION` ($h_2$):** Fase di stabilizzazione dell'emergenza o dei bisogni primari;
4. **`DOCUMENT_RECOVERY` ($h_3$):** Fase di recupero dei documenti d'identità e delle posizioni amministrative;
5. **`EMPLOYMENT_READINESS` ($h_4$):** Fase di preparazione al lavoro, bilancio delle competenze e formazione;
6. **`FINANCIAL_AUTONOMY` ($h_5$):** Fase di raggiungimento dell'autonomia finanziaria e gestione del bilancio;
7. **`SUSTAINED_INDEPENDENCE` ($h_6$):** Fase di consolidamento dell'indipendenza e di piena autonomia;
8. **`HUMAN_PAUSED` ($h_7$):** Stato di pausa deliberata. L'utente ha richiesto di sospendere momentaneamente il percorso;
9. **`HUMAN_RECALIBRATION_REQUIRED` ($h_8$):** Stato di ricalibrazione del percorso umano. Attivato a seguito di eventi di stanchezza, sopraffazione emotiva o cambio di obiettivi;
10. **`HUMAN_GOAL_CHANGED` ($h_9$):** L'utente ha ridefinito o cambiato i propri obiettivi personali;
11. **`HUMAN_DECLINED_ASSISTANCE` ($h_{10}$):** Stato terminale. L'utente ha scelto esplicitamente di revocare ed interrompere il supporto del sistema;
12. **`PREVENTIVE_STANDBY` ($h_{11}$):** Stato di guardia preventiva. L'utente ha raggiunto la piena indipendenza ma mantiene attivo un monitoraggio discreto di prevenzione delle ricadute.

---

#### 2.3.1 Dinamica della Guardia Preventiva ($h_{11}$) e della Ricalibrazione
Nello stato $h_{11}$ (`PREVENTIVE_STANDBY`), la persona vive in piena autonomia. Qualora dovesse manifestarsi un nuovo momento di crisi o sopraffazione emotiva (`HEV_EMOTIONAL_OVERWHELM`), l'automa sposta lo stato in `HUMAN_RECALIBRATION_REQUIRED` ($h_8$), riattivando il supporto del sistema.

#### 2.3.2 Regola Normativa di Preservazione del Progresso Umano (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`)
Quando l'automa umano si trova nello stato di ricalibrazione $h_8$ e supera il momento di difficoltà (evento `HEV_STABILIZED`), il runtime **`MUST`** determinare lo stato di destinazione $q_H'$ calcolando la funzione pura `ResolveNextHumanState` basata sul nodo attivo del piano d'azione ($\mathcal{K}_{\text{playbook}}.\text{node}_{\text{curr}}$).

**È tassativamente vietato retrocedere forzatamente l'utente allo stato iniziale di stabilizzazione $h_2$ (`STABILIZATION`)** se i prerequisiti degli stati successivi (es. documenti ottenuti, competenze apprese) risultano già registrati come completati nell'insieme $V_{\text{completed}}$. Il percorso riprende esattamente dal punto in cui era stato interrotto.

---

### 2.4 Equazione del Sistema Reattivo Composito ed Invariante di Disaccoppiamento

Il sistema globale reattivo di SCINTILLA Core unisce i due automi nello spazio composito $S_C = Q \times Q_H$. La dinamica è regolata dall'**Invariante di Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`)**:

1. **Gli eventi dell'automa umano non alterano la sicurezza del runtime:** Una richiesta o una difficoltà dell'utente non possono mai far fallire o mandare in errore l'automa tecnico $M$.
2. **Gli errori tecnici non penalizzano il percorso umano:** Un guasto informatico o un timeout di rete ($q \in \{\text{VALIDATION\_ERROR}, \text{RECOVERABLE\_FAILURE}\}$) **`SHALL NOT`** paralizzare o retrocedere il progresso umano concettuale $Q_H$.
3. **Eccezione di Sovranità in Lockdown:** Qualora il sistema tecnico dovesse piombare in blocco critico di sicurezza (`SECURITY_LOCKDOWN`), le uniche transizioni dell'automa umano che il sistema **`MUST`** continuare ad accettare ed applicare immediatamente sono quelle di richiesta di pausa o di revoca definitiva del supporto (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

# CAPITOLO 3: SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)
## (Layer B3 - Regole Operative SOS)

---

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore

Ogni transazione $t$ sottomessa al sistema reca l'indicazione dell'attore che l'ha generata ($\text{actor}$). Il sistema applica una matrice di autorizzazione stringente ed inderogabile:

1. **Attore Umano (`USER`):** È autorizzato ad emettere tutti gli eventi del percorso umano ($\Sigma_H$), a richiedere la pausa, la revoca della privacy dei propri dati ed il recesso totale.
2. **Attore Sistema (`SYSTEM`):** È autorizzato ad emettere gli eventi interni di business, di timeout e di registrazione degli errori.
3. **Attore Operatore (`OPERATOR`):** È autorizzato ad emettere gli eventi di ripristino tecnico (`EV_REPAIR`, `EV_OVERRIDE`) e di supporto validato.
4. **Attore Intelligenza Artificiale (`LLM`):** **`SHALL NOT` (non è mai autorizzato) ad emettere alcuna transazione o evento capace di mutare lo stato del sistema.** Qualsiasi tentativo di sottomissione di transazione diretta da parte dell'LLM **`MUST`** essere rifiutato con esito negativo immediato (`False`).

---

**NOTA INFORMATIVA: Perché l'Intelligenza Artificiale ha ZERO autorizzazione?**  
Questo vincolo è la garanzia suprema di SCINTILLA Core. Anche se l'LLM generasse un testo che dice "L'utente ha completato il corso" oppure "Paga questo debito", il Kernel controlla la firma dell'attore. Riscontrando che l'autore è l'LLM, il Kernel scarta l'azione. Solamente quando l'utente umano clicca "Confermo" sul proprio schermo, l'azione diventa firmata dall'attore `USER` e viene accettata dal sistema.

---

### 3.2 Meta-Regole Operative di Sicurezza di Runtime

La semantica operazionale Small-Step SOS definisce formalmente come lo stato cambia passo dopo passo:

* **Regola di Nominale Sicurezza (`[SOS-META-SAFETY]`):** Se la transazione è autorizzata dall'attore corretto, la validazione ambientale restituisce esito positivo (`PASS`) e le regole di sicurezza della policy danno via libera (`ALLOW`), lo stato dell'automa $M$ e dello stato permanente vengono aggiornati in modo puro tramite $\text{ApplyValidated}$.
* **Regola di Gestione del Fallimento (`[SOS-META-SAFETY-FAIL]`):** Se la validazione ambientale fallisce o l'azione è negata, la transazione originale viene scartata ed il sistema genera automaticamente una transazione di errore (`BuildErrorTx`), portando l'automa $M$ in `VALIDATION_ERROR` (o mantenendo lo stato di blocco se si trovava già in `SECURITY_LOCKDOWN`).
* **Regola di Ripristino Tecnico (`[SOS-COMPENSATIVE-REPAIR]`):** Un operatore umano autenticato può far uscire il sistema dallo stato di blocco `SECURITY_LOCKDOWN` o `SAFE_READ_ONLY_MODE` **unicamente sottomettendo l'evento `EV_REPAIR` corredato da una patch formale di riparazione dello stato** (`ValidRepairPatch`).

---

### 3.3 Meta-Regole Operative del Percorso Umano e Sovranità

* **Regola per l'Aggiornamento delle Competenze (`[SOS-COMPETENCE-UPDATE]`):** Quando l'utente completa un nodo del piano d'azione che prevede l'apprendimento di una capacità, la nuova competenza viene inserita nel registro permanente dell'utente $\mathcal{K}_{\text{competence}}$.
* **Regola per la Custodia Documentale (`[SOS-VAULT-RECORD]`):** Quando viene verificato o recuperato un documento d'identità o un attestato, il documento cifrato viene inserito nella cassaforte digitale dell'utente $\mathcal{V}_{\text{vault}}$ e l'automa umano avanza allo stato `DOCUMENT_RECOVERY`.
* **Regola di Stasi in Stato Pausa (`[SOS-HUMAN-PAUSED-STUTTER]`):** Quando l'utente si trova nello stato di pausa (`HUMAN_PAUSED`), qualsiasi evento ordinario giunga viene elaborato con esito "Nessun Effetto sullo Stato" (`PROCESSED_NO_STATE_EFFECT`), preservando la stasi finché l'utente non sottomette l'evento esplicito di ripresa (`HEV_RESUME_REQUESTED`).
* **Regola di Timeout per Inattività (`[SOS-HUMAN-TIMEOUT]`):** Se il percorso rimane nello stato di pausa per un periodo di tempo superiore alla soglia parametrizzata ($\theta_{\text{inactivity\_timeout}}$), il sistema genera un evento automatico di ricalibrazione (`HEV_RECALIBRATION_REQ`), invitando delicatamente l'utente ad un aggiornamento del percorso al suo rientro.

---

# CAPITOLO 4: POLICY GUIDANCE ENGINE & STRATIFICAZIONE DELLE POLICY
## (Layer A & Layer B2)

---

### 4.1 Stratificazione delle Policy in 3 Livelli

Per impedire che regole di sicurezza scritte in modo ambiguo o in linguaggio naturale possano causare comportamenti imprevedibili nel software, il Motore delle Politiche (Policy Guidance Engine) adotta una stratificazione rigorosa su tre livelli:

1. **Livello Normativo Umano (Policy Specification Layer):** Testi normativi, principi etici e linee guida redatti in linguaggio naturale controllato per la consultazione da parte degli operatori umani;
2. **Livello di Compilazione (Policy Compilation Layer):** Il processo informatico verificato che traduce le specifiche umane in algoritmi e parametri numerici matematici ($\Theta$);
3. **Livello Esecutivo Puro (Executable Policy Predicate Layer):** Il codice deterministico derivato $\mathcal{R}_{\text{exec}}$, che riceve in ingresso lo stato e la transazione e restituisce **unicamente uno di tre esiti possibili**:
   * **`ALLOW`:** Via libera, l'operazione è conforme e sicura;
   * **`DENY`:** Divieto assoluto, l'operazione è rischiosa o non autorizzata e viene bloccata;
   * **`RECALIBRATE`:** Ricalibrazione, l'operazione richiede un chiarimento conversazionale con l'utente prima di poter essere eseguita.

---

### 4.3 Composizione di Policy e Regola del Diniego Prevalente (`DENY-OVERRIDES`)

Quando più pacchetti di regole di sicurezza (Policy Bundle) vengono combinati insieme per valutare una transazione, il sistema applica la regola algebrica disgiunta conservativa:

* **Se anche una sola policy restituisce `DENY`, l'esito finale composito è tassativamente `DENY`** (il divieto prevale sempre su qualsiasi autorizzazione);
* Se nessuna policy restituisce `DENY`, ma almeno una restituisce `RECALIBRATE`, l'esito finale composito è `RECALIBRATE`;
* L'esito finale è `ALLOW` se, e solo se, **tutte** le policy valutate restituiscono `ALLOW`.

---

**NOTA INFORMATIVA: Che cos'è il principio Deny-Overrides (Il Diniego Prevale)?**  
È una regola di massima sicurezza usata nei sistemi critici. Immagina un controllo accessi con tre guardiani: se due guardiani dicono "può passare", ma il terzo dice "no, c'è un pericolo", il sistema obbedisce al guardiano che ha rilevato il pericolo e nega l'accesso. La sicurezza ha sempre la priorità assoluta.

---

### 4.4 Decodifica Deterministica dell'Input SML v2.0 in Evento Umano

Per evitare qualsiasi ambiguità tra il linguaggio naturale usato dall'utente o generato dall'LLM ed i comandi rigidi dell'automa umano, il Livello 4 applica la funzione pura `MapSMLToFSMEvent`.

Questa funzione trasforma l'esito conversazionale del documento SML (§C.1) nei comandi esecutivi dell'automa:
* L'esito conversazionale `OVERWHELMED` (Sopraffatto) viene tradotto rigorosamente nell'evento `HEV_EMOTIONAL_OVERWHELM`;
* L'esito `NEEDS_REPHRASING` (Richiesta di chiarimento) viene tradotto in `HEV_RECALIBRATION_REQ`;
* L'esito `DECLINED_ACTION` (Rifiuto dell'azione) viene tradotto in `HEV_PAUSE_REQUESTED`;
* L'esito `ASKED_FOR_HELP` (Richiesta di aiuto) viene tradotto in `HEV_PREVENTIVE_SUPPORT_REQ`.

Se l'esito della conversazione è semplicemente `UNDERSTOOD` (Compreso), la funzione restituisce `NONE`, assicurando che la semplice chiacchierata non produca scatti indesiderati nell'automa del percorso.

---

### 4.5 Tassonomia della Guida ed Ergonomia Cognitiva

Per ridurre il carico di stress e l'ansia da prestazione dell'utente vulnerabile, il sistema definisce **tre livelli formali di guida comunicativa**:

1. **Direttiva Autoritativa (`Authoritative Directive`):** Formulazione prescrittiva ed imperativa. È ammessa **esclusivamente** in condizioni di imminente pericolo per la sicurezza fisica o in emergenze acute che richiedono l'intervento di professionisti (`PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Raccomandazione Motivata (`Motivated Recommendation`):** Formulazione consigliata che propone un passaggio operativo motivandone il perché, riducendo lo sforzo di pianificazione dell'utente. La raccomandazione **`MUST`** spiegare le ragioni del consiglio ed essere immediatamente modificabile o rifiutabile dall'utente (`USER_CONFIRMED_STEP`).
3. **Opzione Esplorativa (`Exploratory Option`):** Presentazione neutrale di alternative multiple, utilizzata quando l'utente è sereno e desidera valutare autonomamente le diverse possibilità.

---

### 4.6 Filosofia Normativa dell'Intervento Umano (Human Override)

Qualora un operatore umano qualificato (`OPERATOR`) debba intervenire per affiancare l'utente o sbloccare una situazione tecnica, l'azione di override **`MUST`** conformarsi ai seguenti 5 principi normativi:

1. **Tracciabilità Assoluta:** Ogni intervento dell'operatore **`MUST`** generare una transizione firmata e registrata sul Ledger $\mathcal{L}$ recante il suo identificativo univoco;
2. **Autenticazione Forte:** L'operatore deve possedere una firma crittografica valida ed il permesso esplicito `SC.PERMISSION.OPERATOR_OVERRIDE`;
3. **Spiegabilità Obbligatoria:** Ogni intervento di override **`MUST`** includere una motivazione esplicita in formato testuale chiaro e non vuoto;
4. **Inalterabilità Storica:** L'override modifica lo stato corrente di lavoro, ma **`SHALL NOT`** cancellare, alterare o nascondere le transizioni precedenti scritte sul Ledger;
5. **Rispetto Assoluto del Consenso dell'Utente:** L'operatore umano **`SHALL NOT`** forzare l'esecuzione di azioni in violazione del consenso espresso dalla persona, salvo nei soli casi di emergenza acuta e tutela della vita previsti dalla legge.

---

# CAPITOLO 5: EMANCIPATION PLAYBOOK ENGINE
## (Layer A & Layer B2)

---

### 5.1 Struttura del Grafo del Piano d'Azione (Playbook)

Un **Emancipation Playbook** (Piano d'Azione per l'Emancipazione) è la mappa operativa che trasforma un grande obiettivo di vita (es. "Ottenere un lavoro", "Trovare casa", "Ricostruire la propria posizione documentale") in una sequenza ordinata e chiara di piccoli passaggi pratici, chiamati **Nodi di Micro-Azione**.

Dal punto di vista matematico, il Playbook è strutturato come un **Grafo Orientato ed Etichettato $G_P = (V_P, E_P, C_P)$**:
* $V_P$ (Nodi): L'insieme delle singole micro-azioni che l'utente può compiere;
* $E_P$ (Archi diretti): Le frecce di collegamento che indicano la sequenza logica di successione tra i nodi (es. "Prima richiedi il codice fiscale, POI richiedi la carta d'identità");
* $C_P$ (Condizioni di Verificabilità): L'insieme dei controlli automatici che verificano se i prerequisiti di uno specifico nodo sono stati soddisfatti dallo stato dell'utente.

---

**NOTA INFORMATIVA: Che cos'è un Grafo Orientato ed Aciclico (DAG)?**  
Un grafo è una rete di punti (nodi) collegati da linee (archi). È "orientato" quando le linee hanno una freccia che indica un'unica direzione obbligatoria di percorrenza. È "aciclico" quando, seguendo le frecce, è matematicamente impossibile tornare indietro formando un circolo vizioso o un loop infinito.

---

### 5.2 Tipizzazione dei Nodi del Playbook

Ogni nodo di micro-azione $v \in V_P$ contenuto nel Playbook **`MUST`** appartenere ad una ed una sola delle seguenti quattro categorie formali:

1. **`INFORMATION` (Nodo Informativo):** Un passaggio a contenuto puramente educativo, formativo o informativo (es. "Leggi come funziona un contratto di locazione"). Non richiede alcuna azione pratica o conferma per proseguire;
2. **`OPTIONAL_STEP` (Passo Opzionale):** Un micro-passo consigliato per ottimizzare il percorso, ma che l'utente può scegliere di saltare liberamente senza produrre alcun blocco nel flusso dell'automa;
3. **`USER_CONFIRMED_STEP` (Passo con Conferma dell'Utente):** Un passaggio operativo che richiede la conferma o la dichiarazione esplicita dell'utente prima di poter essere marcato come completato (es. "Dichiaro di aver spedito il modulo di richiesta");
4. **`REQUIRED_FOR_SYSTEM_STATE` (Prerequisito Bloccante di Sistema):** Un passaggio tecnico o legale bloccante (es. "Verifica dell'avvenuto rilascio del documento d'identità"). Solamente i nodi appartenenti a questa categoria possono condizionare l'avanzamento degli automi di sicurezza del Kernel.

---

### 5.3 Invarianti di Esecuzione e Tracciamento dello Stato

#### 5.3.1 Invariante di Aciclicità Locale sui Nodi Bloccanti (`INV-PLAYBOOK-GRAPH-01`)
Per evitare che l'utente rimanga bloccato in un circolo burocratico infinito, il sotto-insieme formato dai soli nodi bloccanti (`REQUIRED_FOR_SYSTEM_STATE`) **`MUST`** costituire un Grafo Orientato Strettamente Aciclico (DAG).

Qualora la struttura di un Playbook caricato dovesse contenere un ciclo chiuso tra nodi bloccanti, il sistema **`MUST`** rifiutare immediatamente il caricamento del file sollevando il **Runtime Error Code 83 (`ERR_GRAPH_CYCLE_DETECTED`)**.

#### 5.3.2 Durata Parametrizzata delle Micro-Azioni
Per ridurre lo stress e la stanchezza cognitiva dell'utente vulnerabile, la durata stimata di una singola micro-azione non deve superare la soglia massima definita dai parametri di policy ($\theta_{\text{max\_duration}}$). Ogni azione deve essere eseguibile in un tempo contenuto e ben definito.

#### 5.3.3 Tracciamento dell'Avanzamento
Ogni avanzamento dell'utente nel Playbook aggiorna lo stato permanente nella componente $\mathcal{K}_{\text{playbook}}$, registrando l'identificativo del piano d'azione attivo ($\text{pb}_{\text{id}}$), il nodo correntemente in corso ($\text{node}_{\text{curr}}$) e l'insieme dei nodi già completati con successo ($V_{\text{completed}}$).

---

# CAPITOLO 6: TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ
## (Layer A & Layer B2)

---

### 6.1 Spazio delle Versioni e Profilo di Runtime

Ogni componente software, schema di dati o pacchetto di regole appartiene allo spazio delle versioni ed è identificato dalla tupla numerica $v = \langle \text{major}, \text{minor}, \text{patch} \rangle$ (secondo la convenzione del Versionamento Semantico).

Il contesto operativo di ogni operazione è racchiuso nella **Tupla del Profilo di Runtime (`RuntimeProfile`)**, che specifica la versione esatta dei quattro pilastri del sistema:
1. Il profilo semantico delle regole operative (es. `"SCINTILLA-SOS-v4.5.5"`);
2. Il profilo dello schema dei dati (es. `"SCHEMA-SC-v10.3"`);
3. Il profilo dell'algoritmo di canonizzazione (es. `"SC-JCS-1"`);
4. Il profilo del pacchetto delle politiche di sicurezza attive (es. `"POLICY-BUNDLE-v1.2"`).

---

**NOTA INFORMATIVA: Che cos'è il Replay Storico del Ledger?**  
Poiché il Ledger registra le decisioni per anni, le regole del software potrebbero cambiare nel tempo passando dalla versione 4 alla versione 5. Quando il sistema deve "riavvolgere il nastro" e rielaborare una vecchia transazione del passato per ricostruire lo stato, non deve usare le regole nuove di oggi, ma **deve applicare esattamente le regole che erano in vigore nel momento esatto in cui quella vecchia transazione è stata scritta**. Questo principio si chiama *Replay Storico Deterministico*.

---

#### 6.1.1 Regola di Compatibilità per il Replay Storico (`RULE-HISTORICAL-REPLAY-COMPATIBILITY`)
In fase di ricostruzione deterministica dello stato a partire dal registro storico:
1. Ogni transazione $t_i$ passata **`MUST`** essere interpretata e convalidata applicando le regole SOS ed i profili di schema esplicitamente registrati nella transazione stessa;
2. L'introduzione di una nuova versione dello standard **`SHALL NOT`** alterare retroattivamente o invalidare il risultato delle transizioni storiche già consolidate sotto le versioni precedenti.

---

# CAPITOLO 7: CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA
## (Layer A & Layer B2)

---

### 7.1 Canonizzazione dello Stato (`Canon`)

Per consentire la verifica della firma digitale e l'identificazione univoca delle informazioni, qualsiasi dato strutturato o stato di memoria deve essere convertito in una sequenza binaria di byte UTF-8 attraverso la funzione di **Canonizzazione Deterministica (`Canon`)**.

La funzione `Canon` garantisce l'iniettività semantica: due stati o due dati che contengono le medesime informazioni **`MUST`** produrre una rappresentazione in byte esattamente identica (§7.1.1).

---

### 7.2 Catena di Hash Immutabile ed Integrità del Ledger

L'integrità del libro mastro (Ledger) per ogni nuova transazione $N$-esima è garantita dal calcolo dell'impronta crittografica $H_N$ eseguito sul corpo della transazione:
* La primissima transazione dello Stato di Genesi ha un'impronta iniziale $H_0$ costituita da una sequenza di zeri ($\mathbf{0}_{\mathcal{D}_{256}}$);
* Ogni transazione successiva $N$-esima include all'interno del proprio corpo l'impronta della transazione precedente $H_{N-1}$. L'impronta corrente $H_N$ viene calcolata applicando l'algoritmo di hash SHA-256 sulla rappresentazione canonizzata della transazione:
```math
H_N = \text{SHA256}\left( \text{Canon}(\text{TransactionBody}_N) \right)
```

Se un malintenzionato tenta di alterare anche solo un singolo carattere di una transazione passata, la catena di impronte si spezza immediatamente e l'automa $M$ entra nello stato di blocco critico `SECURITY_LOCKDOWN`.

---

**NOTA INFORMATIVA: Che cos'è una Catena di Hash (Hash Chain)?**  
Immagina un registro in cui ogni pagina reca in alto un timbro speciale calcolato sul contenuto esatto della pagina precedente. Se qualcuno strappa una pagina passata o ne scarabocchia una riga, il timbro sulla pagina successiva non corrisponderà più e la manomissione diventerà immediatamente visibile a tutti.

---

# CAPITOLO 8: FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEI RUNTIME ERROR CODES
## (Layer B2 - Specificazione Normativa)

---

### 8.1 Criteri Normativi di Accettazione PASS/FAIL

Un'applicazione software ottiene la certificazione ufficiale di conformità allo standard SCINTILLA Core se, e solo se, soddisfa **tre criteri normativi vincolanti**:

1. **Test Vector Match (100% Corrispondenza):** Il software supera la suite di test ufficiali (`CONFORMANCE-TEST-SUITE-v4.5.5.JSON`), generando hash e byte canonizzati bit-a-bit identici a quelli attesi;
2. **Superamento delle Verifiche Temporali LTL/CTL:** Le proprietà di sicurezza e liveness (§9.2) sono formalmente verificate sul modello dell'applicazione;
3. **Totalità Matematica delle Transizioni:** Il software gestisce in modo esaustivo qualsiasi combinazione possibile di stato ed evento attraverso la funzione $\mathbf{Resolve}$, senza mai piombare in stati indefiniti o crash imprevisti.

---

### 8.2 Tassonomia dei Runtime Error Codes e Process Exit Codes

Quando si verifica una violazione degli invarianti di sicurezza, un errore di sintassi o una condizione di blocco, il Kernel **`MUST`** segnalare l'anomalia emettendo un **Runtime Error Code** appartenente allo spazio numerico riservato **`70–89`**.

Quando il Kernel viene eseguito come processo autonomo in un sistema operativo (es. Linux), tale codice di errore **`SHALL`** essere propagato come **Process Exit Code** del programma.

---

**NOTA INFORMATIVA: Che cosa sono i Process Exit Codes (Codici di Uscita)?**  
Quando un programma informatico termina la propria esecuzione o si blocca, restituisce un numero al sistema operativo per spiegare com'è andata. Il numero 0 significa "tutto bene", mentre i numeri diversi da zero indicano uno specifico problema. Riservando i numeri da 70 a 89, SCINTILLA Core permette ai sistemi di monitoraggio di capire istantaneamente la causa esatta di un blocco di sicurezza.

---

#### 8.2.1 Sotto-insieme Crittografia, Sicurezza e Consenso (70–79)
* **Codice 71 (`ERR_INVALID_CRYPTO_SIGNATURE`):** La firma digitale applicata alla transazione risulta invalida o contraffatta;
* **Codice 72 (`ERR_CONSENT_REVOKED_VIOLATION`):** Tentativo di eseguire un'operazione su dati di cui l'utente ha esplicitamente revocato il consenso;
* **Codice 73 (`ERR_INFRASTRUCTURE_IO`):** Guasto dell'infrastruttura di memoria, perdita di connessione al disco o impossibilità di scrivere sul Ledger;
* **Codice 77 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrità crittografica della catena di hash ($H_N$) o tentata manomissione storica del registro;
* **Codice 78 (`ERR_LEASE_ACQUISITION_TIMEOUT`):** Scadenza del lock di concorrenza durante un tentativo di modifica dello stato;
* **Codice 79 (`ERR_CLOCK_SKEW_EXCEEDED`):** L'orologio del calcolatore locale è disallineato rispetto al timestamp della transazione oltre la tolleranza massima consentita.

#### 8.2.2 Sotto-insieme Validazione, Parsing, Flussi e KMS (80–89)
* **Codice 80 (`ERR_SML_PARSE_FAILED`):** Errore di sintassi nella struttura del documento generato dall'intelligenza artificiale;
* **Codice 81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`):** Scadenza del periodo massimo di inattività durante lo stato di pausa dell'utente;
* **Codice 82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`):** Tentativo di avanzare verso un nodo inesistente nel piano d'azione attivo;
* **Codice 83 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo burocratico bloccante ed illegale all'interno del grafo del Playbook;
* **Codice 84 (`ERR_SCHEMA_MISMATCH`):** Incompatibilità tra la versione dei dati inviati e lo schema atteso dal Kernel;
* **Codice 85 (`ERR_CONFIGURATION_MALFORMED`):** Configurazione malformata, presenza di numeri non interi o violazione delle regole dei Basis Points;
* **Codice 86 (`ERR_HOBM_BOUNDARY_VIOLATION`):** Tentativo di eseguire un'azione ad alto rischio legale senza l'autorizzazione o la firma di un operatore umano;
* **Codice 87 (`ERR_KMS_UNAVAILABLE`):** Indisponibilità o mancata risposta del modulo di custodia delle chiavi crittografiche.

---

# CAPITOLO 9: MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE
## (Layer A & Layer B2)

---

### 9.1 Consistenza Esterna, Lock e Scherma di Concorrenza

Quando SCINTILLA Core viene eseguito su un cluster di più calcolatori collegati in rete:

1. **Strict Linearizability (Consistenza Esterna):** Il registro $\mathcal{L}$ garantisce che l'ordine delle operazioni per ogni singolo caso utente sia strettamente sequenziale, come se esistesse un solo calcolatore al mondo ad elaborare le richieste;
2. **Fencing Token (Token di Scherma):** Per evitare che due calcolatori diversi modifichino lo stato dell'utente contemporaneamente, ogni operazione **`MUST`** verificare ed incrementare un contatore numerico monotonico (`fencing_token`). Qualsiasi richiesta che arrivi recando un token vecchio o scaduto viene immediatamente rifiutata (`ERR_LEASE_ACQUISITION_TIMEOUT`);
3. **Sincronizzazione Temporale Cluster (`REQ-CLUSTER-CLOCK-SYNC`):** La differenza massima tra gli orologi fisici dei calcolatori del cluster non deve mai superare la metà della tolleranza di disallineamento temporale ($\delta_{\text{clock}} < \frac{1}{2}\theta_{\text{max\_clock\_skew}}$).

---

**NOTA INFORMATIVA: Che cos'è un Fencing Token (Token di Scherma)?**  
Immagina un bastone della parola in un'assemblea: solo chi possiede il bastone può parlare, ed ogni volta che il bastone passa di mano riceve un numero progressivo più alto (1, 2, 3...). Se un membro dell'assemblea tenta di parlare usando un vecchio bastone recante il numero 1 quando ormai si è arrivati al numero 3, la sala lo ignora. Il Fencing Token impedisce che vecchi comandi in ritardo sulla rete possano sovrascrivere le decisioni presenti.

---

### 9.2 Modello di Kripke e Verificabilità con Logiche Temporali (LTL e CTL)

Per consentire la verifica formale e matematica delle proprietà di sicurezza tramite strumenti automatici di controllo dei modelli (Model Checkers come NuSMV o SPIN), la dinamica di SCINTILLA Core viene modellata come una **Struttura di Kripke $M_K$**.

Il comportamento del sistema nel tempo è vincolato da formule rigide espresse in **Logica Temporale Lineare (LTL)** e **Logica del Tempo Computazionale (CTL)**:

* **LTL Safety 1 (Correttezza delle Decisioni):** Il sistema produce una decisione favorevole solo ed unicamente se le politiche di sicurezza hanno dato esito via libera (`ALLOW`);
* **LTL Safety 2 (Protezione della Scherma):** Se un'operazione non rispetta l'incremento monotonico del token di scherma, il sistema si sposta immediatamente in stato di errore recuperabile;
* **LTL Safety 3 (Integrità del Registro):** Se la catena di hash risulta alterata o non valida, il sistema piomba istantaneamente in blocco critico di sicurezza (`SECURITY_LOCKDOWN`);
* **LTL Liveness 4 (Recuperabilità del Progresso):** In caso di un guasto tecnico temporaneo, esiste sempre la garanzia che il sistema possa ripristinarsi e consentire all'utente di riprendere il proprio percorso avanzato;
* **LTL Safety 5 (Invarianza dell'Oblio Crittografico):** Una volta eseguita la distruzione della chiave crittografica (`EV_CRYPTO_SHRED_EXECUTED`), la chiave rimane distrutta per sempre in tutti gli stati futuri del tempo ($\square \text{KeyIsShredded}$);
* **CTL System Agency Guarantee:** Per qualsiasi stato attivo dell'utente, esiste sempre almeno un cammino futuro raggiungibile che porta al progresso del percorso personale ($AG(\text{UserEngaged} \implies EF(\text{JourneyProgressive}))$).

---

**NOTA INFORMATIVA: Che cos'è il Model Checking con Logiche Temporali?**  
Il Model Checking è una tecnica matematica avanzata in cui un software speciale esplora automaticamente TUTTI i miliardi di percorsi futuri possibili di un programma per dimostrare che non si verificherà mai una situazione pericolosa. Le formule LTL e CTL sono le "leggi temporali" che dicono al Model Checker cosa deve essere SEMPRE vero (Safety) e cosa deve poter SEMPRE accadere in futuro (Liveness).

---

# CAPITOLO 10: STANDARD REFERENCE PROFILE 1 (SC-JCS-1) E CONTRATTI DEGLI AUTOMI IN PROSA
## (Layer C - Profilo Concreto di Riferimento)

---

### 10.1 Definizione del Profilo SC-JCS-1

Per garantire che qualunque sistema informatico produca la medesima identica rappresentazione digitale dei dati, la specifica definisce il profilo di canonizzazione **SC-JCS-1**.

SCINTILLA Core adotta regole di serializzazione proprietarie e rigorose che **NON sono compatibili a livello di hash con lo standard generico RFC 8785**:
1. Imponimento dell'ordinamento stringhe basato unicamente sui punti di codice Unicode (*Unicode Code Point Lexicographical Order*);
2. **Divieto assoluto ed inderogabile di qualsiasi numero con virgola mobile o notazione scientifica.**

---

**NOTA INFORMATIVA: Che cos'è la Canonizzazione SC-JCS-1?**  
In un file di testo JSON, lo stesso dato può essere scritto in molti modi diversi: inserendo uno spazio in più, invertendo l'ordine di due chiavi (es. `"nome", "cognome"` invece di `"cognome", "nome"`), o scrivendo un numero come `10.0` invece di `10`. Per un calcolatore, anche un solo spazio diverso cambia completamente l'impronta digitale (hash). La canonizzazione SC-JCS-1 elimina tutti gli spazi inutili, ordina le chiavi in modo matematicamente univoco e converte tutti i numeri in interi esatti, facendo sì che qualsiasi computer nel mondo produca la medesima sequenza di byte.

---

### 10.2 Sottoinsieme di Serializzazione e Range degli Interi Sicuri

Un documento JSON appartiene al sottoinsieme valido $J_{\text{SC}}$ di SCINTILLA Core se, e solo se, tutti i numeri in esso contenuti sono **esclusivamente numeri interi compresi nell'intervallo sicuro**:
```math
I_{\text{safe}} = \left[ -9007199254740991, \ +9007199254740991 \right] \quad (-(2^{53}-1) \text{ a } +(2^{53}-1))
```

Qualsiasi tentativo di sottomissione di documenti contenenti decimali (`1.5`), notazione scientifica (`1e10`), valori non definiti (`NaN`) o infiniti (`Infinity`) **`MUST`** essere immediatamente rifiutato con il **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 10.2.1 Regola dei Basis Points $[0, 10000]$
Tutti i valori probabilistici, i punteggi di confidenza ed i sotto-indici dell'indice `AGI_proxy` **`MUST`** essere espressi e serializzati come numeri interi scalati di un fattore $10^4$, ovvero nell'intervallo chiuso di numeri interi compreso tra **$0$ e $10000$ Basis Points** ($0 = 0,00\%$, $10000 = 100,00\%$).

---

### 10.3 Algoritmo di Serializzazione Canonica SC-JCS-1 in 6 Passaggi

L'algoritmo SC-JCS-1 trasforma un documento in byte canoni attraverso i seguenti passaggi sequenziali:

1. **Eliminazione degli Spazi (`Whitespace Elimination`):** Rimuove tutti i caratteri di spaziatura, a capo o tabulazione esterni alle stringhe di testo;
2. **Escaping delle Stringhe (`String Escaping`):** Applica il carattere di fuga unicamente per i caratteri di controllo speciali (da U+0000 a U+001F), le virgolette `"` ed il carattere `\`;
3. **Normalizzazione Unicode (`NFC`):** Applica la normalizzazione Unicode Normalization Form C su tutte le stringhe di testo;
4. **Ordinamento delle Chiavi degli Oggetti (`Object Key Sorting`):** Ordina tutte le chiavi di un oggetto JSON in modo ascendente basandosi sul valore Unicode dei caratteri;
5. **Ordinamento degli Insiemi nel Registro (`SetSemanticsRegistry`):** Per tutte e sole le chiavi registrate nel registro degli insiemi (`completed_nodes`, `permissions`, `prerequisites`, `roles`, `scopes`, `consent_items`, `revoked_items`, `competence_records`, `vault_records`), gli elementi dell'array **`MUST`** essere ordinati in modo ascendente confrontando byte-per-byte le loro rappresentazioni canoniche UTF-8.
6. **Invarianza Posizionale degli Array Generici:** Per tutti gli array non presenti nel registro degli insiemi, la sequenza posizionale degli elementi **`MUST`** essere preservata senza alcuna alterazione, in quanto l'ordine degli elementi costituisce parte integrante della semantica dello stato.

---

### 10.4 Contratto dell'Automa di Sicurezza ($\delta_M$) in Prosa

Il contratto informatico dell'automa di sicurezza di runtime $\delta_M$ definisce le transizioni deterministiche tra gli stati $Q$:

* **Dallo stato `NORMAL`:**
  * Un evento `EV_SUCCESS` o di ripristino mantiene lo stato in `NORMAL`;
  * L'evento `EV_ABANDON` sposta lo stato in `REQUIRE_RECALIBRATION`;
  * L'evento `EV_SML_FAIL` o `EV_TIMEOUT` sposta lo stato in `VALIDATION_ERROR`;
  * L'evento `EV_LEASE_EXP` sposta lo stato in `RECOVERABLE_FAILURE`;
  * L'evento `EV_HASH_CORRUPT` sposta lo stato in `SECURITY_LOCKDOWN`.
* **Dallo stato `VALIDATION_ERROR` e `RECOVERABLE_FAILURE`:**
  * L'evento `EV_SUCCESS` ripristina lo stato a `NORMAL`;
  * Il persistere dell'errore di timeout in `RECOVERABLE_FAILURE` sposta lo stato in `OPERATOR_REQUIRED`;
  * L'evento `EV_HASH_CORRUPT` sposta immediatamente lo stato in `SECURITY_LOCKDOWN`.
* **Dallo stato `OPERATOR_REQUIRED`:**
  * Un intervento autorizzato dell'operatore (`EV_OVERRIDE`) ripristina lo stato a `NORMAL`.
* **Dallo stato `SECURITY_LOCKDOWN`:**
  * **È VIETATO qualsiasi ripristino tramite semplice `EV_OVERRIDE`** (rimosso per prevenire livelock);
  * L'unica via di ripristino verso `NORMAL` richiede la sottomissione dell'evento `EV_REPAIR` corredato da una patch di riparazione valida;
  * L'evento `EV_TIMEOUT` sposta lo stato in `SAFE_READ_ONLY_MODE`.
* **Dallo stato `SAFE_READ_ONLY_MODE`:**
  * L'evento `EV_REPAIR` o `EV_OVERRIDE` ripristina lo stato a `NORMAL`;
  * Gli eventi amministrativi (`EV_ITEM_PRIVACY_REVOKED`, `EV_CRYPTO_SHRED_EXECUTED`) mantengono lo stato in `SAFE_READ_ONLY_MODE` ma vengono correttamente eseguiti e scritti sul Ledger.

---

### 10.5 Contratto dell'Automa del Percorso Umano ($\delta_H$) in Prosa

Il contratto dell'automa umano $\delta_H$ definisce le transizioni dell'utente lungo i 12 stati $Q_H$:

* La progressione nominale segue la sequenza: `UNASSESSED` $\to$ `INITIAL_ASSESSMENT` $\to$ `STABILIZATION` $\to$ `DOCUMENT_RECOVERY` $\to$ `EMPLOYMENT_READINESS` $\to$ `FINANCIAL_AUTONOMY` $\to$ `SUSTAINED_INDEPENDENCE` $\to$ `PREVENTIVE_STANDBY`;
* La richiesta di pausa (evento `HEV_PAUSE_REQUESTED`) sposta l'automa nello stato `HUMAN_PAUSED` da qualsiasi stato attivo;
* La richiesta di ripresa dalla pausa (`HEV_RESUME_REQUESTED`), una sopraffazione emotiva (`HEV_EMOTIONAL_OVERWHELM`) o una regressione sposta l'automa in `HUMAN_RECALIBRATION_REQUIRED` ($h_8$);
* Dallo stato $h_8$, il superamento delle difficoltà (`HEV_STABILIZED`) **riporta l'utente allo stato corrispondente al nodo attivo del Playbook** (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`), senza mai azzerare le competenze ed i documenti già ottenuti;
* La revoca totale del supporto (`HEV_DECLINE_ALL`) sposta l'automa nello stato terminale ed irreversibile `HUMAN_DECLINED_ASSISTANCE`.

---

# CAPITOLO 11: FRAMEWORK DI CONFORMITÀ E VETTORI DI TEST
## (Layer B / Layer C)

---

### 11.1 Assiomatizzazione della Conformance Suite

La certificazione di conformità di un'implementazione software viene verificata eseguendo la suite di test ufficiali contenuta nell'artefatto **`CONFORMANCE-TEST-SUITE-v4.5.5.JSON`**, che include:
1. **Positive Path Vectors:** Casi di test di successo che verificano la perfetta corrispondenza bit-a-bit degli hash SHA-256 e dei byte SC-JCS-1 prodotti;
2. **Negative Error Vectors:** Casi di test di errore (input contenenti decimali, cicli burocratici o contratti ambigui) che verificano il corretto sollevamento dei codici di errore $70–89$;
3. **Security Vectors:** Tentativi di manomissione della catena di hash o firme crittografiche alterate che verificano l'immediato ingresso in `SECURITY_LOCKDOWN`.

---

# CAPITOLO 12: STATO DI CERTIFICAZIONE E GOVERNANCE
## (Layer B - Specificazione Normativa)

---

### 12.1 Stato Normativo del Documento

La presente **SCINTILLA Core CANONICAL SPECIFICATION v4.5.5 Candidate Canonical Standard Edition** costituisce la specifica normativa canonica e completa del dominio.

Lo stato del documento è: **SPECIFICATION-AUDITED & FORMALIZATION-READY**. Esso è totalmente privo di contraddizioni interne e pronto per lo sviluppo di applicazioni di produzione.

### 12.2 Metadati di Attestazione di Governance
Ogni runtime conforme **`MUST`** esportare nei propri metadati di funzionamento l'attestazione di conformità alla suite v4.5.5, includendo l'impronta crittografica dell'eseguibile, la versione del compilatore ed il digest del manifest delle dipendenze.

---

# ANNESSI NORMATIVI ED INFORMATIVI

---

## ANNEX A: TYPESCRIPT TYPE MAPPING (INFORMATIVO / LAYER C)

### A.1 Tipi Normativi e Vincoli di Interfaccia
L'Annesso A.1 definisce la mappatura dei tipi di dati nel linguaggio TypeScript, traducendo i domini matematici negli insiemi corrispondenti (`ActorType`, `GuidanceType`, `PlaybookNodeActionType`, `HumanOversightLevel`, `ProvenanceDomain`).

Tutti i numeri interi e le percentuali sono vincolati dai tipi "brandizzati" `SafeInteger` e `BasisPoints` (intervallo chiuso $[0, 10000]$).

### A.2 Implementazione delle Funzioni Helper di Riferimento
L'Annesso A.2 fornisce il codice TypeScript di riferimento per tre operazioni critiche:
1. `parseSafeInteger`: Verifica che un valore numerico sia un numero intero compreso tra $-(2^{53}-1)$ e $+(2^{53}-1)$;
2. `parseBasisPoints`: Verifica e satura i valori numerici all'interno dell'intervallo consentito $[0, 10000]$;
3. `mapSMLToFSMEvent`: Traduce in modo puro e deterministico l'esito del documento conversazionale SML negli eventi dell'automa umano (es. `OVERWHELMED` $\to$ `HEV_EMOTIONAL_OVERWHELM`).

---

## ANNEX B: SPECIFICA DEL GRAFO DEL PLAYBOOK (LAYER B / LAYER C)

L'Annesso B definisce le strutture dati JSON dei nodi (`PlaybookNode`) e degli archi (`PlaybookEdge`) che compongono un piano d'azione. 

Stabilisce l'obbligo per il motore di gioco di eseguire la validazione di aciclicità sui nodi bloccanti (`REQUIRED_FOR_SYSTEM_STATE`) all'atto del caricamento, sollevando il Codice di Errore 83 (`ERR_GRAPH_CYCLE_DETECTED`) in caso di cicli.

---

## ANNEX C: SPECIFICA SML v2.0 (LAYER B2 / LAYER C)

L'Annesso C definisce la grammatica EBNF sintattica del linguaggio **SML (Syntactic Messaging Language) v2.0**, la struttura testo usata dall'intelligenza artificiale per comunicare con il Kernel.

Definisce inoltre il **Semantic Safety Gate di Livello 2**: se l'intelligenza artificiale genera asserzioni prescrittive su diritti o leggi senza ancorarsi ad una fonte verificata, il parser di Livello 4 scarta immediatamente il messaggio e genera l'evento di errore `EV_SML_FAIL`.

---

## ANNEX D: REGISTRO DELLE DICHIARAZIONI PREVENTIVE (FORWARD DECLARATIONS)

L'Annesso D fornisce il registro di risoluzione topologica di tutti i simboli algebrici utilizzati nella specifica (`P(L)`, `delta_nominal`, `delta_err`, `R_exec`, `DecisionProof`, `SMLOutcome`), consentendo ai sistemi di verifica formale automatizzata (Coq, Lean 4, TLA+) di compilare il modello senza ambiguità di dichiarazione.

---

# GLOSSARIO DEI TERMINI TECNICI

---

**Agency Operativa Responsabile**  
La capacità concreta, qualitativa e personale di un individuo di comprendere il proprio contesto, valutare le alternative, pianificare le azioni ed esercitare il controllo sulla propria vita senza subire manipolazioni o decisioni eterodirette.

**AGI_proxy (Agency Governance Indicator Proxy)**  
Un indicatore numerico descrittivo (compreso tra 0 e 10000 Basis Points) calcolato dal software per valutare l'ergonomia della comunicazione e l'avanzamento del percorso. *Non ha alcuna relazione con l'Intelligenza Artificiale Generale (Artificial General Intelligence).*

**Automa a Stati Finiti (FSM / DP-FSM)**  
Un modello matematico di calcolo costituito da un insieme finito di stati e da regole di transizione deterministiche che stabiliscono lo stato successivo in base all'evento ricevuto.

**Basis Points (Punti Base)**  
Un'unità di misura proporzionale in cui 1 Punto Base equivale allo 0,01% (ovvero $1/10000$). In SCINTILLA Core viene usata per rappresentare percentuali usando unicamente numeri interi compresi tra 0 e 10000.

**Canonizzazione (SC-JCS-1)**  
Il processo deterministico che converte un documento di dati strutturati (JSON) in una sequenza binaria di byte UTF-8 unica ed inalterabile, eliminando spazi, ordinando le chiavi e normalizzando i testi.

**Crypto-Shredding (Oblio Crittografico Totale)**  
La tecnica di protezione della privacy consistente nella distruzione irreversibile della chiave crittografica usata per cifrare i dati personali dell'utente, rendendo i dati memorizzati sul registro storico matematicamente ed ininterrottamente illeggibili.

**Determinismo**  
La proprietà di un sistema informatico per cui, dato un determinato stato iniziale ed un medesimo ingresso, il sistema produrrà SEMPRE e rigorosamente lo stesso identico stato finale su qualsiasi calcolatore.

**Fencing Token (Token di Scherma)**  
Un contatore numerico strettamente crescente utilizzato nei sistemi distribuiti per garantire che solo un calcolatore alla volta possa modificare i dati di un utente, rifiutando comandi in ritardo o duplicati.

**Hash / Hash Chain (Catena di Hash)**  
Un'impronta digitale crittografica di lunghezza fissa (SHA-256). In una catena di hash, l'impronta di ogni nuova operazione include l'impronta della precedente, rendendo impossibile modificare il passato senza spezzare la catena.

**Invariante di Sistema**  
Una condizione logica o matematica che **`MUST`** rimanere sempre vera in ogni istante di funzionamento del software. Se un'azione tenta di violare un invariante, l'operazione viene bloccata.

**Kernel Normativo**  
Il nucleo centrale deterministico di un sistema informatico che racchiude le regole inderogabili, le politiche di sicurezza ed i vincoli di garanzia dei diritti dell'utente.

**Ledger (Libro Mastro Immutabile)**  
Un registro informatico a sola aggiunta (*append-only*) in cui tutte le decisioni e le transazioni vengono scritte in modo sequenziale, cronologico ed inalterabile.

**LLM (Large Language Model / Modello Linguistico)**  
Un sistema di intelligenza artificiale probabilistico specializzato nell'elaborazione e generazione di linguaggio umano. In SCINTILLA Core opera al Livello 5 senza alcuna autorità di scrittura sullo stato.

**Model Checking (LTL e CTL)**  
Una tecnica di verifica formale automatizzata che esplora matematicamente tutti i possibili stati futuri di un programma per dimostrare che le proprietà di sicurezza (LTL) e di accessibilità (CTL) siano sempre rispettate.

**Playbook (Piano d'Azione per l'Emancipazione)**  
Un grafo orientato ed aciclico di micro-azioni pratiche che guida l'utente verso il raggiungimento di un obiettivo di vita strutturato.

**Process Exit Code (Codice di Uscita del Processo)**  
Un numero intero (in SCINTILLA Core riservato nell'intervallo 70–89) restituito dal programma al sistema operativo per comunicare la causa esatta di un blocco o di un errore di runtime.

**Probabilismo**  
Il comportamento di un componente software il cui risultato non è rigido o matematicamente predicibile a priori, ma espresso in termini di probabilità o verosimiglianza (tipico dell'intelligenza artificiale).

**Safe Integers (Interi Sicuri)**  
L'intervallo chiuso di numeri interi $[-9007199254740991, +9007199254740991]$ che può essere rappresentato in modo matematicamente esatto secondo lo standard IEEE 754 senza incorrere in errori di arrotondamento.

**SML (Syntactic Messaging Language)**  
Il linguaggio di messaggistica sintattico v2.0 basato su grammatica EBNF utilizzato dall'intelligenza artificiale per proporre azioni e riassunti al Kernel.

**Soft Logical Revocation (Revoca Logica Parziale)**  
Il meccanismo di tutela della privacy mediante il quale un elemento informativo viene nascosto ed oscurato dalle viste pubbliche e dalle API, rimanendo tracciato solo come identificatore revocato nel registro storico per preservare la continuità del grafo.

**Strict Linearizability (Consistenza Esterna)**  
Il modello di consistenza per cui le operazioni su un registro distribuito appaiono a tutti gli osservatori come se venissero eseguite in un ordine temporale unico, istantaneo e sequenziale.

**Stuttering Step (Transizione di Identità)**  
Una transizione di un automa a stati finiti in cui l'arrivo di un evento lascia il sistema esattamente nel medesimo stato in cui si trovava, senza produrre alcuna modifica o effetto collaterale.

---

**SCINTILLA Core v4.5.5 CANDIDATE CANONICAL STANDARD EDITION**
* **Stato del Documento:** Specifica Normativa Canonica Integrale in Linguaggio Naturale Completata
* **Copertura:** Capitoli 0–12, Annessi A–D e Glossario dei Termini Tecnici interamente emessi.
* **Autorità di Governance:** Single Source of Truth per il Dominio SCINTILLA Core.
