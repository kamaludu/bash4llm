
[![Specifica](https://img.shields.io/badge/%E2%9C%B4_SCINTILLA-CORE_CANONICAL_SPECIFICATION-2ea44f?style=for-the-badge&labelColor=gold)](SPEC-SCINTILLA-TIMELESS-v2026.1.md)

# ✴ SCINTILLA Core - SPECIFICA NORMATIVA CANONICA INTEGRALE IN PROSA DIVULGATIVA
## Edizione Standard Canonica v4.5.5
*(Equivalente alla Specifica Formale - Single Source of Truth — in Prosa Espansa con Scenari Pratici e Schede di Garanzia)*

---

* **Stato del Documento:** Specifica Normativa Canonica Integrale in Prosa Divulgativa (Single Source of Truth).
* **Edizione:** v4.5.5 Candidate Canonical Standard Edition.
* **Caratteristica Editoriale:** Testo normativo esplicativo, espanso e divulgativo, rigorosamente privo di formule matematiche o notazioni in codice LaTeX. La logica del sistema è espressa in lingua italiana chiara e fluida, integrata da note informative, schede di garanzia e micro-scenari pratici di vita reale.
* **Destinatari:** Chiunque possieda un titolo di studio di scuola secondaria di secondo grado (diploma). Non è richiesta alcuna competenza preventiva in programmazione, crittografia, matematica avanzata o diritto.
* **Autorità Normativa:** Questo documento definisce in forma narrativa le medesime regole, vincoli ed invarianti espressi nelle formule matematiche della specifica formale.
* **Terminologia Normativa Vincolante:**
  * **`MUST` / `OBBLIGATORIO` / `SHALL`:** Indica un requisito assoluto ed inderogabile.
  * **`MUST NOT` / `VIETATO` / `SHALL NOT`:** Indica un divieto assoluto ed inderogabile.
  * **`SHOULD` / `RACCOMANDATO`:** Indica una raccomandazione fortemente consigliata, derogabile solo per comprovate e documentate ragioni tecniche.
  * **`MAY` / `OPZIONALE`:** Indica una facoltà del tutto opzionale.
* **Regola di Precedenza Normativa (`RULE-NORMATIVE-PRECEDENCE-01`):** In caso di qualsiasi apparente divergenza interpretativa tra la descrizione narrativa in linguaggio naturale ed i contratti esecutivi elaborabili dai calcolatori (Capitolo 10), i contratti esecutivi costituiscono l'autorità normativamente prevalente per l'esecuzione del software.

---

# MISSIONE

## a) Scopo, Natura e Missione della Specifica

La presente specifica definisce **SCINTILLA Core**, il Kernel (nucleo centrale) Normativo Canonico progettato per la costruzione di sistemi informatici deterministici destinati a supportare l'emancipazione personale e l'autonomia operativa di persone fragili, vulnerabili o in situazione di instabilità temporanea o prolungata.

SCINTILLA Core costituisce la fonte unica ed autoritativa di verità del dominio (il cosiddetto *Single Source of Truth*). Essa definisce, in modo formale, deterministico e pienamente verificabile, l'insieme dei comportamenti osservabili, degli invarianti irrinunciabili e dei vincoli normativi che qualsiasi applicazione software conforme **`MUST`** preservare nel tempo.

La missione del Kernel è ridurre gli ostacoli cognitivi (la difficoltà di comprendere cosa fare), informativi (la mancanza di chiarezza sulle risorse disponibili), organizzativi (la confusione nella sequenza dei passi) ed emotivi (lo scoraggiamento o la sopraffazione) che impediscono ad una persona di passare dall'intenzione all'azione concreta.

Il sistema è progettato affinché l'intelligenza artificiale aumenti le capacità umane senza mai produrre dipendenza psicologica, manipolazione comportamentale o perdita di autodeterminazione. L'obiettivo del Kernel non è prendere decisioni al posto della persona, ma garantire che ogni implementazione conforme preservi i principi di autonomia, consenso, dignità, sicurezza, responsabilità e verificabilità definiti da questa specifica.

SCINTILLA Core è una specifica normativa pura: non costituisce un prodotto software commerciale, un'interfaccia utente, un chatbot o un'applicazione mobile, ma il contratto di garanzia ed il modello di regole sulla cui base tali strumenti possono essere costruiti in modo sicuro.

---

**NOTA INFORMATIVA: Che cos'è un Kernel Normativo?**  
In campo informatico, il "Kernel" è il cuore fondamentale di un sistema operativo, ovvero la parte che gestisce le regole base ed il controllo delle risorse essenziali. Un "Kernel Normativo" è un insieme di regole logiche e informatiche che stabiliscono esattamente cosa il software può fare e cosa gli è tassativamente vietato, garantendo che il sistema rispetti sempre i diritti dell'utente e non possa mai deviare dai suoi principi fondativi.

---

## b) Ambito Normativo

La presente specifica disciplina ed individua in modo rigoroso:
- Il **Modello di Stato** (la struttura completa delle informazioni memorizzate dal sistema);
- La **Semantica delle Transazioni** (come ogni singola richiesta viene convalidata ed eseguita);
- Il **Registro Immutabile** (il libro mastro inalterabile delle decisioni);
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
- I motori di ricerca e le basi di conoscenza esterne;
- Le interfacce grafiche utente (applicazioni per smartphone, siti web);
- I servizi cloud ed i sistemi di autenticazione di terze parti;
- Le integrazioni con software o banche dati di enti pubblici o privati.

La presenza, l'assenza o la sostituzione di tali componenti esterni non modifica in alcun modo la validità e la semantica normativa di SCINTILLA Core. Essi costituiscono semplici strumenti ausiliari di supporto, ma non possiedono alcuna autorità decisionale sullo stato interno del sistema.

---

## d) Rapporto con le Implementazioni Software

La presente specifica definisce esclusivamente il "cosa" il sistema deve fare, lasciando alle singole implementazioni software la scelta del "come" realizzarlo.

Implementazioni differenti possono essere conformi pur adottando linguaggi di programmazione (es. Rust, Go, TypeScript, Java), piattaforme, architetture, algoritmi o librerie differenti. Un'applicazione software è conforme se, e solo se, il suo comportamento osservabile e la sua gestione dei dati rispettano al cento per cento gli invarianti ed i contratti definiti in questo documento.

---

## e) Separazione tra Componenti Deterministiche e Probabilistiche

SCINTILLA Core traccia una linea di demarcazione assoluta ed insuperabile tra due categorie di componenti:

1. **Componenti Probabilistiche (es. Intelligenza Artificiale / LLM):** Hanno il solo ed unico compito di generare ipotesi, suggerimenti, spiegazioni conversazionali o traduzioni testuali. Esse sono intrinsecamente soggette a possibili imprecisioni ed **`MUST NOT`** (non devono mai) possedere alcuna autorità di scrittura diretta sullo stato del sistema o sulle decisioni operative.
2. **Componenti Deterministiche (Il Kernel SCINTILLA Core):** Sono algoritmi matematici certi e riproducibili al cento per cento. Qualsiasi modifica della memoria, avanzamento di percorso o concessione di permessi **`MUST`** avvenire esclusivamente attraverso l'applicazione delle regole deterministiche del Kernel.

---

**NOTA INFORMATIVA: Perché separiamo l'Intelligenza Artificiale dal Kernel Deterministico?**  
I modelli di Intelligenza Artificiale attuali sono straordinari nel parlare e nel comprendere il linguaggio umano, ma hanno un difetto strutturale: sono "probabilistici", cioè possono talvolta inventare informazioni non vere (fenomeno noto come allucinazione) o dare risposte diverse a fronte della stessa domanda. SCINTILLA Core risolve questo problema separando i compiti: l'Intelligenza Artificiale parla con l'utente e spiega i concetti, ma il Kernel deterministico (che funziona in modo rigido e matematico al 100%) controlla le regole, memorizza i dati ed esegue solo le azioni ammesse e sicure.

---

> 💡 **SCENARIO PRATICO: L'Intelligenza Artificiale propone, il Kernel dispone**  
> *Situazione:* Durante una conversazione, l'Intelligenza Artificiale dice all'utente: *"Ho segnato che oggi hai ottenuto la carta d'identità!"*.  
> *Cosa fa SCINTILLA Core:* Il messaggio dell'IA è solo un'ipotesi conversazionale. Il Kernel **non aggiorna lo stato dell'utente** finché l'utente stesso non clicca sul pulsante di conferma o non carica la foto del documento. L'IA ha proposto una possibilità, ma solo il Kernel ed il consenso umano possono mutare la memoria ufficiale.

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE
## (Layer B1 - Assunzioni Normative & Principi Etici)

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

L'intero dominio di SCINTILLA Core è ingegnerizzato ed organizzato attorno ad un unico grande obiettivo: **aumentare la capacità concreta e reale di una persona fragile o vulnerabile di trasformare una condizione di instabilità in un percorso strutturato di emancipazione ed autonomia**.

#### 0.1.1 Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)
Ogni regola, algoritmo, automa o trasformazione di dati all'interno del sistema **`MUST`** conformarsi incondizionatamente e sempre al seguente principio supremo:

---

> 🛡️ **SCHEDA DI GARANZIA: Invariante Etico Supremo di Design (`INV-SUPREME-AGENCY-01`)**  
> * **Cosa stabilisce la regola:** SCINTILLA Core ha la missione di creare un automa di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e l'agency delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volontà e senza mai supportare azioni incompatibili con la dignità umana, la sicurezza ed i diritti altrui.  
> * **Perché esiste:** Per garantire che la tecnologia rimanga sempre uno strumento al servizio dell'emancipazione umana e non diventi mai un mezzo di controllo o di coercizione.  
> * **Cosa impedisce:** Impedisce che il software possa essere programmato per condizionare l'utente, spingerlo ad azioni contrarie ai suoi interessi o forzarlo verso scelte non volute.

---

#### 0.1.2 Tassonomia Concettuale dell'Agency Responsabile
Con il termine **Agency Operativa Responsabile**, il sistema indica la capacità della persona di guidare la propria vita, definita attraverso la combinazione qualitativa di sei dimensioni fondamentali:
1. **Capacità di Azione:** La facoltà concreta di compiere piccoli passi pratici (micro-azioni) orientati ad uno scopo;
2. **Comprensione del Contesto:** La chiarezza informativa su quali siano i propri vincoli, le risorse disponibili e le opportunità;
3. **Valutazione delle Alternative:** La capacità di confrontare diverse strade possibili comprendendone rischi e benefici;
4. **Pianificazione:** La facoltà di scomporre un obiettivo grande e complesso in una sequenza ordinata di passaggi semplici ed eseguibili;
5. **Perseveranza:** La capacità di mantenere l'impegno nel tempo e di gestire le battute d'arresto senza abbandonare il percorso;
6. **Percezione di Controllo:** La consapevolezza interiore di essere i veri ed unici protagonisti del proprio cambiamento personale.

*Nota Normativa:* L'Agency Operativa Responsabile è un valore umano qualitativo di dominio. Essa **non viene mai misurata come un voto o un punteggio morale** sulla persona, ma rappresenta la guida etica fondamentale dell'intero sistema.

---

### 0.2 ASSIOMI DI NON-PATERNALISMO E AUTODETERMINAZIONE

#### 0.2.1 Invariante Anti-Paternalista (`INV-ANTI-PATERNALISM-01`)
Il sistema **`SHALL NOT`** (non deve mai) adottare un modello decisionale paternalistico basato sull'assunto presuntivo che "il software o l'intelligenza artificiale sappiano cosa sia meglio per l'utente".

---

> 🛡️ **SCHEDA DI GARANZIA: Invariante Anti-Paternalista (`INV-ANTI-PATERNALISM-01`)**  
> * **Cosa stabilisce la regola:** Il sistema non può mai agire come decisore di vita dell'utente. Il suo ruolo è unicamente quello di facilitatore e consulente trasparente.  
> * **Perché esiste:** Per evitare che il software tratti l'utente fragile come un soggetto incapace di intendere e di volere, espropriandolo della sua libertà di scelta.  
> * **Cosa impedisce:** Impedisce al software di dire *"Devi fare così perché è la cosa migliore per te"*. Il software deve invece dire *"Ecco tre strade possibili con i relativi costi e benefici: quale desideri approfondire?"*.

---

In nessuna circostanza il sistema può prendere decisioni di vita al posto della persona. Il sistema **`SHALL`**:
1. Aiutare la persona a comprendere la propria situazione attraverso l'analisi dei vincoli e delle risorse disponibili;
2. Proporre opzioni operative chiare, pratiche e contestualizzate;
3. Esplicitare in modo trasparente le conseguenze prevedibili, i rischi ed i prerequisiti di ogni scelta;
4. Supportare la persona nella costruzione e nel mantenimento di un piano d'azione personalizzato (Playbook).

#### 0.2.2 Assioma di Sovranità del Consenso Umano (`AXIOM-HUMAN-CONSENT-SOVEREIGNTY`)
> **"L'utente umano costituisce l'autorità decisionale suprema ed inalienabile del proprio percorso. Nessuna raccomandazione del sistema, inferenza dell'intelligenza artificiale o suggerimento di un operatore umano può modificare lo stato di avanzamento personale senza il consenso esplicito, informato e sempre revocabile dell'utente."**

---

### 0.3 DISACCOPPIAMENTO PERSONA-COMPORTAMENTO E DIRITTI

#### 0.3.1 Invariante di Separazione Persona-Comportamento (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)
Il sistema **`MUST`** mantenere una distinzione formale ed assoluta tra l'**Identità dell'Attore Umano** (rappresentata dall'identificatore di attore) e lo specifico **Payload della Transazione** (il contenuto della singola richiesta formulata).

1. **Inviolabilità della Dignità della Persona:** L'utente, indipendentemente dai suoi trascorsi personali, legali, finanziari o sociali, **`SHALL`** ricevere incondizionatamente il supporto del sistema per migliorare la propria condizione di vita. L'identificatore dell'attore non **`SHALL`** mai essere oggetto di squalifica o stigmatizzazione morale.
2. **Valutazione Oggettiva della Richiesta:** La funzione di valutazione valuta unicamente la sicurezza, la legalità e la sostenibilità dello specifico contenuto della transazione, senza mai esprimere valutazioni di merito sulla persona che l'ha formulata.

---

> 💡 **SCENARIO PRATICO: Valutazione oggettiva senza pregiudizio**  
> *Situazione:* Un utente che in passato ha interrotto più volte il percorso o ha avuto problemi con la legge chiede al sistema aiuto per iscriversi ad un corso di formazione.  
> *Cosa fa SCINTILLA Core:* Il Kernel **non rifiuta la richiesta** basandosi sulla storia passata dell'utente. Valuta solo se la richiesta attuale è valida (es. se ci sono posti disponibili e se i requisiti tecnici sono soddisfatti). L'utente viene trattato con la medesima dignità ed ha diritto al medesimo supporto di chiunque altro.

---

# CAPITOLO 1: LO STATO DEL SISTEMA, IL REGISTRO IMMUTABILE ED I CONTATORI DI AVANZAMENTO
## (Layer A & Layer B1/B2)

---

### 1.1 Formalizzazione dello Spazio degli Stati e delle sue Componenti

Lo **Spazio degli Stati** rappresenta la totalità delle informazioni che il sistema memorizza e gestisce in un dato istante per ciascun percorso utente. In SCINTILLA Core, lo stato primario è formalizzato come la combinazione di tre grandi domini di memoria distinti ed indipendenti tra loro:

1. **Dominio di Persistenza permanente (Ricostruibile dal Registro):** Contiene le informazioni storiche ed i dati di fatto fondamentali del percorso, tra cui:
   * L'identificativo unico del caso utente;
   * La traccia dell'origine e della provenienza di ciascuna informazione;
   * Il registro dei consensi forniti o revocati;
   * Lo stato attuale del piano d'azione guidato (Playbook);
   * L'elenco degli elementi informativi di cui l'utente ha richiesto l'oscuramento (revoca logica parziale della privacy);
   * La palestra delle competenze pratiche acquisite ed attestate nel tempo;
   * La custodia sicura (Vault) dei documenti d'identità e degli attestati formali.
2. **Dominio Interno di Runtime e Sicurezza (Gestito dal Kernel):** Contiene i parametri operativi di funzionamento e controllo interno, tra cui:
   * Lo stato corrente dell'automa di sicurezza del software;
   * Lo stato corrente dell'automa del percorso umano;
   * Le regole di sicurezza attive ed i parametri di configurazione;
   * Le chiavi temporali di sincronizzazione (fencing lease) per impedire accessi simultanei e contrastanti da più dispositivi;
   * L'indicatore della modalità di affiancamento attiva;
   * Il timestamp dell'inizio dell'eventuale stato di pausa;
   * La tupla dei quattro contatori numerici cumulativi delle interazioni;
   * Il numero progressivo di sequenza dell'operazione e l'impronta crittografica (hash) dell'ultima transazione consolidata.
3. **Dominio Ausiliario Volatile (Buffer temporaneo di co-creazione):** Un'area di lavoro temporanea utilizzata per la preparazione di bozze di lavoro (es. la bozza di un curriculum, di una lettera o di un modulo), che non altera lo stato permanente ed i diritti dell'utente finché il contenuto non viene confermato ed inviato.

---

**NOTA INFORMATIVA: Come funziona la Memoria a Tre Livelli del Sistema?**  
Immagina la memoria di SCINTILLA Core come un ufficio ben organizzato:  
1. Il **Dominio di Persistenza** è l'archivio blindato in cui sono custoditi i faldoni ufficiali, i contratti firmati ed i documenti d'identità.  
2. Il **Dominio Interno** è la lavagna di controllo dell'ufficiale di sicurezza, dove sono segnati i turni di guardia, i semafori d'accesso ed il contatore delle operazioni svolte.  
3. Il **Dominio Ausiliario** è un blocco per appunti sul tavolo su cui utente e sistema scarabocchiano bozze provvisorie. Finché un appunto non viene approvato e messo nel faldone ufficiale, la lavagna di controllo e l'archivio blindato rimangono invariati.

---

### 1.1.2 Vista Derivata e Contatori cumulativi di Interazione

La componente di stato derivato non costituisce una dimensione di memoria indipendente, bensì una vista calcolata in tempo reale mediante una funzione pura che analizza lo stato permanente ed interno.

Il sistema mantiene all'interno del dominio interno di controllo una tupla ordinata di **quattro contatori numerici cumulativi interi**:
1. **Contatore delle Interazioni:** Si incrementa di una unità per ciascuna transazione valida elaborata con successo con esito favorevole;
2. **Contatore delle Riformulazioni:** Si incrementa di una unità ogni volta che l'analisi della conversazione evidenzia che l'utente ha chiesto di rispiegare o semplificare un messaggio;
3. **Contatore delle Ambiguità:** Si incrementa di una unità ogni volta che la valutazione di sicurezza riscontra incertezza e richiede una ricalibrazione;
4. **Contatore della Sopraffazione:** Si incrementa di una unità ogni volta che viene recepito un evento di stanchezza o sopraffazione emotiva dell'utente.

Questi contatori servono unicamente al software per comprendere se la comunicazione è chiara o se occorre adottare un linguaggio più semplice e graduale.

---

### 1.2 Interfaccia Osservabile Pubblica ed Equivalenza di Stato

#### 1.2.1 Funzione di Osservazione Pubblica (`Obs`)
La proiezione esterna dello stato verso le interfacce utente, le API e gli schermi pubblici è governata dalla funzione pura di osservazione. Per tutelare la privacy ed i diritti della persona:
* La vista pubblica mostra l'identificativo del caso, le fonti dei dati, i consensi attivi, il piano d'azione, le competenze ed i documenti validi;
* La vista pubblica **`MUST` nascondere ed oscurare immediatamente qualsiasi documento, consenso o competenza di cui l'utente abbia richiesto la revoca logica** (tramite l'inserimento nell'elenco degli elementi revocati), restituendo un valore nullo al suo posto.

#### 1.2.2 Invariante di Irrilevanza del Buffer Temporaneo (`INV-AUX-IRRELEVANCE`)
Le variazioni apportate nell'area ausiliaria volatile (le bozze di lavoro temporanee) non alterano in alcun modo i diritti, la sicurezza storica o lo stato di avanzamento ufficiale dell'utente. Se due stati sono identici nella memoria permanente e di controllo interno, essi sono semanticamente equivalenti a tutti gli effetti normativi e producono la medesima vista osservabile.

---

### 1.3 Lo Stato Iniziale di Genesi ($s_0$) ed Invarianza di Serializzazione

Quando un nuovo percorso utente viene attivato, il sistema si trova nello **Stato di Genesi ($s_0$)**:
* Tutti gli insiemi di dati storici (provenienze, consensi, competenze, documenti, revoche) sono rigorosamente **vuoti**;
* L'automa di sicurezza è nello stato iniziale `NORMAL`;
* L'automa del percorso umano è nello stato iniziale `UNASSESSED` (Non Valutato);
* Le regole di sicurezza sono impostate sui valori predefiniti di base;
* I quattro contatori numerici cumulativi sono tutti azzerati;
* Il numero di sequenza delle operazioni è zero ed l'impronta crittografica dell'ultima transazione è costituita da una sequenza nulla di azzeramento.

#### 1.3.1 Obbligo Formale di Invarianza di Serializzazione del Genesis State (RFC-007)
Per garantire che l'evoluzione del sistema non introduca discrepanze retroattive nei dati storici, la rappresentazione digitale canonizzata dello Stato di Genesi della versione corrente (v4.5.5) **`MUST`** produrre un flusso di byte UTF-8 ed un'impronta crittografica iniziale esattamente identici a quelli generati dalla versione canonica di riferimento (v4.5.3).

---

### 1.4 TRANSAZIONI, INVOLUCRO DI ESECUZIONE E LIBRO MASTRO IMMUTABILE (LEDGER)

Ogni singola operazione, mutazione o richiesta avanzata all'interno di SCINTILLA Core viene formalizzata come una **Transazione**.

Una transazione è composta da tre elementi distinti:
1. **Il Corpo della Transazione (`TransactionBody`):** Contiene l'identificativo unico della transazione, l'identificativo del caso, il numero progressivo di sequenza, l'impronta crittografica della transazione precedente, il timestamp temporale, l'autore dell'azione (utente, sistema, operatore), l'evento esecutivo ed il contenuto utile dei dati (payload);
2. **L'Involucro di Esecuzione (`Execution Envelope`):** I metadati applicativi generati dal runtime che registrano l'esito dell'elaborazione (esito nominale con successo, rifiuto per errore di validazione, o elaborazione senza effetti sullo stato);
3. **La Prova Crittografica (`proof`):** La firma digitale che ne garantisce l'autenticità e la non ripudiabilità.

Quando una transazione viene inviata mentre l'automa del percorso umano si trova nello stato di pausa (`HUMAN_PAUSED`), l'involucro di esecuzione **`MUST`** registrare lo stato di elaborazione "Elaborato senza effetti sullo stato" (`PROCESSED_NO_STATE_EFFECT`), spiegato dal codice di ragione "Percorso umano in pausa" (`HUMAN_JOURNEY_PAUSED`).

---

**NOTA INFORMATIVA: Che cos'è un Libro Mastro Immutabile (Ledger Append-Only)?**  
Un Ledger è un registro informatico organizzato come un libro mastro contabile digitale: ogni nuova transazione viene scritta subito dopo la precedente e legata ad essa mediante un'impronta crittografica (hash). Una volta scritta, una transazione non può più essere modificata, cancellata o sovrascritta da nessuno al mondo. Se si vuole correggere un errore del passato, occorre scrivere una nuova transazione di rettifica in fondo al registro. Questo garantisce una trasparenza ed un'onestà totale sulla storia del percorso.

---

#### 1.4.1 Il Ledger come Monoide Libero e la Funzione Pura di Persistenza
Il registro immutabile delle decisioni (Ledger) è formalizzato come un Monoide Libero, ovvero una sequenza ordinata di corpi di transazione canonizzati gestita con modalità a sola aggiunta (*append-only*). La funzione pura di persistenza converte la transazione nella sua codifica canonica e la concatena in modo sequenziale ed irreversibile in fondo al registro.

#### 1.4.2 Invariante di Consistenza della Proiezione del Ledger
In qualsiasi momento, lo stato corrente del sistema espresso dalla memoria di lavoro **`MUST`** coincidere perfettamente ed in modo deterministico con il risultato della rielaborazione sequenziale di tutte le transizioni scritte sul Ledger a partire dallo Stato di Genesi $s_0$.

---

### 1.5 PRIVACY: REVOCA LOGICA PARZIALE ED OBLIO CRITTOGRAFICO TOTALE

SCINTILLA Core implementa due livelli distinti ed integrati di tutela della riservatezza e gestione dei diritti dell'utente:

#### 1.5.1 Revoca Logica Parziale (`SOFT_LOGICAL_REVOCATION`)
Quando un utente decide di revocare l'accesso ad uno specifico documento, consenso o competenza precedentemente inserito:
* Il sistema registra una transazione ufficiale di revoca recante l'evento `EV_ITEM_PRIVACY_REVOKED`;
* L'identificatore della risorsa viene aggiunto all'insieme degli elementi revocati;
* Da quel momento in poi, le API e la vista pubblica `Obs` nascondono completamente l'elemento, restituendo un valore nullo al suo posto;
* *Invariante di Integrità:* La revoca logica oscura il dato informativo, ma **non cancella l'identificatore del passaggio completato dal grafo del Playbook**, consentendo al sistema di mantenere intatta la coerenza del percorso svolto senza bloccare il flusso operativo.

#### 1.5.2 Oblio Crittografico Totale (`FULL_CRYPTO_SHREDDING`)
Qualora l'utente richieda la cancellazione totale, definitiva ed irreversibile dell'intero caso e di ogni suo dato personale:
* Il modulo di sicurezza procede alla **distruzione irreversibile ed alla fusione della chiave crittografica radice** ($K_{\text{case}}$) custode dei dati utente memorizzata nel sistema KMS;
* Senza tale chiave, tutti i dati cifrati contenuti nel libro mastro diventano matematicamente ed irreversibilmente illeggibili, trasformandosi in rumore casuale senza alcuna possibilità di recupero;
* L'atto di distruzione viene certificato registrando sul Ledger la transazione formale finale `EV_CRYPTO_SHRED_EXECUTED`.

---

**NOTA INFORMATIVA: Che cos'è il Crypto-Shredding (Distruzione Crittografica)?**  
Immagina di riporre tutti i tuoi documenti personali in una cassaforte d'acciaio indistruttibile ed inattaccabile. Invece di tentare di distruggere la cassaforte o i fogli al suo interno, prendi l'unica chiave esistente che può aprirla e la sciogli nell'acido. La cassaforte ed i fogli rimangono fisicamente lì, ma nessuno al mondo potrà mai più leggerne il contenuto. Il Crypto-Shredding è l'equivalente digitale della distruzione irreversibile della chiave.

---

> 💡 **SCENARIO PRATICO: La cancellazione totale dei dati (Crypto-Shredding in azione)**  
> *Situazione:* Laura decide di non voler più utilizzare il sistema e chiede la cancellazione completa di ogni suo dato.  
> *Cosa fa SCINTILLA Core:* Il Kernel cancella la chiave crittografica di Laura nel modulo KMS. Anche se il registro storico rimane salvato sul server, i dati di Laura sono ora una sequenza di lettere e numeri casuali senza senso. Nessun hacker, amministratore di sistema o autorità potrà mai più decifrare il nome di Laura, i suoi documenti o le sue conversazioni.

---

### 1.6 VALIDAZIONE AMBIENTALE IMPURA E FUNZIONE PURA DI TRANSIZIONE

Il processo di modifica dello stato del sistema avviene attraverso una netta separazione tra i controlli del contesto esterno e la mutazione matematica interna:

1. **Validazione Ambientale Impura (`ValidateEnvironment`):** Prima di applicare una transazione, il sistema verifica le condizioni esterne di contesto:
   * La validità della firma digitale crittografica applicata alla transazione;
   * La concordanza dell'orologio temporale (la differenza tra l'ora del sistema e la data della transazione non deve superare la tolleranza massima consentita per il disallineamento dell'orologio);
   * La validità della chiave temporale di concorrenza (`fencing_token`) per evitare sovrascritture o comandi duplicati inviati in ritardo sulla rete.
2. **Funzione Pura di Transizione (`ApplyValidated`):** Una volta superati i controlli ambientali, la funzione pura di transizione modifica lo stato del sistema in modo totalmente deterministico. Se la validazione ambientale fallisce, la funzione applica una transizione di errore o porta il sistema in stato di blocco di sicurezza (`SECURITY_LOCKDOWN`) qualora venga riscontrata la corruzione dell'impronta crittografica.

---

### 1.7 INDICE PROXY OPERATIVO DI GUADAGNO DI AGENCY (`AGI_proxy`)

L'Indice Proxy **`AGI_proxy`** è un valore numerico intero compreso nell'intervallo chiuso tra **zero e diecimila Punti Base** (corrispondente a percentuali da 0,00% a 100,00%) che fornisce un'indicazione descrittiva ed aggregata sull'andamento dell'operatività dell'utente all'interno del sistema.

---

**NOTA INFORMATIVA: Chiarimento fondamentale sull'acronimo AGI_proxy**.  
Nelle tecnologie moderne, l'acronimo "AGI" viene comunemente usato per indicare l'Intelligenza Artificiale Generale (*Artificial General Intelligence*). **In SCINTILLA Core, AGI_proxy NON ha alcuna relazione con l'Intelligenza Artificiale Generale.**  
L'acronimo indica esclusivamente l'**Agency Governance Indicator Proxy** (Indicatore Proxy di Governance dell'Agency Operativa): una misura matematica descrittiva usata dal software per capire se l'interfaccia digitale sta aiutando la persona o se la sta confondendo, adattando di conseguenza la chiarezza dei messaggi.

---

#### 1.7.1 Assunzione di Confine Epistemico ed Isolamento Descrittivo
L'indice `AGI_proxy` è un indicatore puramente descrittivo ed **`MUST NOT`** (non deve mai) essere utilizzato dalle regole di sicurezza per condizionare, limitare o bloccare i diritti di accesso dell'utente, le sue scelte o le decisioni del sistema (`INV-AGI-DESCRIPTIVE-ISOLATION`). Un utente con un indice basso conserva esattamente i medesimi diritti di scelta, di sovranità e di consenso di un utente con un indice alto.

#### 1.7.2 Invarianza durante la Pausa del Percorso Umano
Se l'utente decide di mettere in pausa il proprio percorso (stato `HUMAN_PAUSED` o `HUMAN_DECLINED_ASSISTANCE`), il valore dell'indice `AGI_proxy` viene congelato e rimane perfettamente identico al valore dello stato precedente per tutta la durata della stasi.

#### 1.7.3 Calcolo Deterministico dell'Indice in Aritmetica Intera Sicura
Per tutti gli stati attivi del percorso, l'indice `AGI_proxy` viene calcolato mediante una media ponderata di tre sotto-punteggi numerici (ciascuno espresso in Punti Base da zero a diecimila):

1. **Punteggio di Chiarezza (`ClarityScore_bp`):** Valuta quanto la comunicazione sia fluida e priva di ostacoli. Parte da diecimila Punti Base e diminuisce proporzionalmente se l'utente deve chiedere spesso di rispiegare i messaggi, se si verificano ambiguità o se riscontra sopraffazione emotiva;
2. **Rapporto di Esecuzione delle Azioni (`ActionExecutionRatio_bp`):** Misura la percentuale di micro-passi completati dall'utente all'interno del piano d'azione (Playbook) attivo rispetto al totale dei passi previsti dal piano;
3. **Punteggio di Riduzione della Dipendenza (`DependencyReductionScore_bp`):** Misura la percentuale di azioni completate con successo dall'utente che hanno portato all'acquisizione diretta di competenze pratiche ed attestate riutilizzabili in autonomia nella vita reale.

Tutti i calcoli matematici sono eseguiti rigorosamente in **aritmetica intera con numeri a 64-bit**, escludendo del tutto l'uso di numeri con la virgola per garantire che il risultato sia identico al cento per cento su qualsiasi calcolatore o sistema operativo.

---

**NOTA INFORMATIVA: Che cosa sono i Punti Base (Basis Points) e l'Aritmetica Intera Sicura?**  
Nei calcoli ad alta precisione, l'uso di numeri con la virgola (la cosiddetta virgola mobile) può causare impercettibili differenze di arrotondamento a seconda del processore o del sistema operativo utilizzato. Per evitare questo problema e garantire un determinismo assoluto su qualsiasi computer, SCINTILLA Core esprime tutte le percentuali moltiplicandole per cento:  
* Il valore 0% corrisponde a 0 Punti Base;  
* Il valore 50% corrisponde a 5000 Punti Base;  
* Il valore 100% corrisponde a 10000 Punti Base.  
In questo modo, i calcoli avvengono usando unicamente numeri interi esatti e senza decimali.

---

### 1.8 CONTRATTO DEL MODULO CRITTOGRAFICO ASTRATTO (`CryptoProviderContract`)

Ogni applicazione o runtime conforme a SCINTILLA Core **`MUST`** integrare un modulo crittografico che metta a disposizione sei operazioni fondamentali di sicurezza:

1. **Derivazione Chiavi (`DeriveKey`):** Generazione deterministica di chiavi crittografiche figlie effimere a partire da una chiave madre e da un contesto;
2. **Cifratura Dati (`EncryptPayload`):** Cifratura simmetrica autenticata per rendere i contenuti informativi personali inintelligibili a terzi non autorizzati;
3. **Decifratura Dati (`DecryptPayload`):** Decifratura ed autenticazione dei dati cifrati mediante l'uso della chiave corretta;
4. **Distruzione Chiave (`ShredKey`):** Cancellazione definitiva, irreversibile ed unicamente confermata di una chiave per attuare l'oblio crittografico totale;
5. **Verifica Firma (`VerifySignature`):** Controllo della validità della firma digitale a chiave pubblica associata ad una transazione;
6. **Verifica Presenza Chiave (`LookupKey`):** Controllo della presenza e dell'attivazione della chiave all'interno del modulo KMS.

I dettagli tecnici specifici degli algoritmi crittografici concreti (AES-256-GCM per la cifratura simmetrica, Ed25519 per le firme digitali a chiave pubblica) sono definiti unicamente nel Profilo Concreto di Riferimento SC-JCS-1 (Capitolo 10).

---

# CAPITOLO 2: ARCHITETTURA A LIVELLI E DOPPIA MACCHINA DEGLI STATI
## (Layer A & Layer B2)

---

### 2.1 Modello di Isolamento Stratificato a 6 Livelli

L'architettura di SCINTILLA Core è organizzata come una torre di sei livelli funzionali sovrapposti, separati da un principio di **isolamento unidirezionale rigoroso**.

I livelli superiori (quelli più vicini all'interfaccia utente ed all'intelligenza artificiale conversazionale) non possiedono **alcuna autorità o capacità di scrittura diretta** sullo stato del sistema o sulla memoria di runtime. Ogni informazione o proposta deve scendere verso il basso attraversando rigorosi cancelli di validazione e filtraggio:

```text
[ LIVELLO 5 ] Modello Linguistico di Intelligenza Artificiale (Generatore Probabilistico)
     │ Contratto API: Genera unicamente testo sintattico SML v2.0 (Zero autorità di stato)
[ LIVELLO 4 ] Livello di Comunicazione, Parsing SML e Validazione Sintattica
     │ Contratto API: Decodifica il testo e crea oggetti di provenienza dati strutturati
[ LIVELLO 3 ] Motore di Interazione Umana, Consenso ed Agency (Consenso, Registro & HOBM)
     │ Contratto API: Valuta il contesto umano, i consensi attivi e l'indice AGI_proxy
[ LIVELLO 2 ] Motore delle Politiche e della Guida (Policy Guidance Engine & Safety Gate)
     │ Contratto API: Compila e valuta le regole esecutive pure (DecisionResult)
[ LIVELLO 1 ] Runtime Deterministico Kernel (Validazione Ambientale e Transizione Pura)
     │ Contratto API: Gestisce il lock di concorrenza e muta lo stato in modo puro
[ LIVELLO 0 ] Registro Immutabile delle Decisioni (Ledger Append-Only su File NDJSON)
```

---

**NOTA INFORMATIVA: Come funziona l'Isolamento a 6 Livelli e perché protegge l'Utente?**  
Nei comuni sistemi di intelligenza artificiale, il modello conversazionale (l'LLM, come ChatGPT) dialoga con l'utente e spesso modifica direttamente i dati o prende decisioni sul software. In SCINTILLA Core questo è **tassativamente vietato**. L'intelligenza artificiale si trova al Livello 5 (il più alto ed esterno) e non ha alcuna chiave per toccare la memoria. Per fare qualsiasi cosa, la risposta dell'intelligenza artificiale deve scendere al Livello 4 (che la controlla sintatticamente), poi al Livello 2 (che verifica le regole di sicurezza) ed infine al Livello 1 (il Kernel deterministico). Se l'intelligenza artificiale inventa o sbaglia qualcosa, i livelli sottostanti la bloccano immediatamente.

---

### 2.2 Automa di Sicurezza di Runtime

L'operatività tecnica e la sicurezza del software sono modellate da un automa a stati finiti ad alta priorità, denominato **Deterministic Priority Finite State Machine (DP-FSM)**.

L'automa di sicurezza si trova sempre ed unicamente in uno dei seguenti **sette Stati Canonici di Sicurezza**:

1. **`NORMAL`:** Lo stato operativo standard. Il sistema elabora nominalmente le richieste dell'utente e dell'applicazione;
2. **`REQUIRE_RECALIBRATION`:** Stato di ricalibrazione tecnica. Attivato quando una richiesta risulta ambigua o quando l'utente abbandona un'azione, richiedendo un chiarimento conversazionale;
3. **`VALIDATION_ERROR`:** Stato di errore di validazione. Attivato quando giunge un input malformato, incompleto o sintatticamente errato;
4. **`RECOVERABLE_FAILURE`:** Stato di fallimento recuperabile. Attivato quando si verifica un problema tecnico temporaneo (es. la scadenza della chiave temporale di concorrenza);
5. **`OPERATOR_REQUIRED`:** Stato di intervento operatore. Attivato quando il sistema riscontra un blocco tecnico non risolvibile automaticamente, richiedendo l'autorizzazione esplicita di un operatore umano qualificato;
6. **`SECURITY_LOCKDOWN`:** Stato di blocco critico di sicurezza. Attivato immediatamente quando viene rilevata una violazione o manomissione dell'integrità crittografica del libro mastro. In questo stato, qualsiasi operazione ordinaria è paralizzata;
7. **`SAFE_READ_ONLY_MODE`:** Stato di sola lettura sicura. L'automa consente all'utente di consultare i propri dati e di esercitare i propri diritti di privacy, ma impedisce qualsiasi nuova mutazione operativa.

Lo stato iniziale di partenza dell'automa di sicurezza è sempre **`NORMAL`**. Gli unici due stati considerati **operativamente stabili** in cui il sistema può rimanere a riposo sono `NORMAL` e `SAFE_READ_ONLY_MODE`.

---

**NOTA INFORMATIVA: Che cos'è un Automa a Stati Finiti con Regole Prioritarie (DP-FSM)?**  
Un automa a stati finiti è un modello matematico che funziona come un semaforo o una porta automatica: il sistema può trovarsi in un solo "stato" alla volta (es. "Rosso", "Giallo", "Verde"). Quando arriva un evento (es. la pressione di un pulsante o un sensore), l'automa segue una regola precisa per passare allo stato successivo. L'aggiunta di "Priorità Deterministica" significa che, se arrivano più segnali insieme, il sistema sa sempre esattamente a quale segnale dare la precedenza assoluta, senza mai esitare o bloccarsi.

---

#### 2.2.1 Regola di Risoluzione delle Priorità e Mascheramento dei Caratteri Jolly
Per evitare qualsiasi ambiguità o incertezza nelle transizioni, l'automa applica una funzione di risoluzione prioritaria organizzata su quattro livelli di gerarchia:
1. Se esiste una regola esplicita definita per lo specifico Stato Corrente ed il preciso Evento Corrente, essa viene applicata con massima priorità assoluta (`RULE-EXPLICIT-SHADOWS-WILDCARD`);
2. Se non esiste una regola specifica, ma esiste una regola definita per lo Stato Jolly (valido per qualsiasi stato) ed il preciso Evento Corrente, si applica questa seconda regola;
3. Se non esiste neppure questa, ma esiste una regola per lo Stato Corrente ed un Evento Jolly, si applica la terza regola;
4. In mancanza di qualsiasi regola corrispondente, il sistema esegue un passo di identità (*stuttering step*), ovvero **mantiene lo stato esattamente invariato**.

#### 2.2.2 Regola del Target Jolly e Riflessività (`RULE-WILDCARD-TARGET-REFLEXIVITY`)
Quando il carattere jolly `*` appare nel campo dello stato di destinazione all'interno di un contratto di transizione, il parser del runtime **`MUST`** interpretare la transizione come un passo di identità (*stuttering step*), mantenendo invariato lo stato corrente dell'automa senza applicare alcuna modifica.

#### 2.2.3 Partizione degli Eventi di Sistema
L'insieme di tutti gli eventi tecnici recepibili dal Kernel è suddiviso in tre gruppi disgiunti:
1. **Eventi di Business:** Eventi legati al progresso operativo ordinario (esito positivo, abbandono dell'azione, errore sintattico, scadenza del lock temporale, timeout);
2. **Eventi di Ripristino Operativo:** Eventi riservati agli interventi autorizzati di sblocco e riparazione (`EV_OVERRIDE`, `EV_REPAIR`);
3. **Eventi Amministrativi e di Tutela Diritti:** Eventi legati all'integrità crittografica ed ai diritti inalienabili dell'utente (rilevazione corruzione hash, revoca della privacy su un elemento, cancellazione totale dei dati).

#### 2.2.4 Gestione della Stasi Operativa nello Stato SAFE_READ_ONLY_MODE
Quando l'automa di sicurezza si trova nello stato di sola lettura sicura (`SAFE_READ_ONLY_MODE`):
* Tutti gli eventi operativi di business producono un passo di identità, precludendo qualsiasi mutazione dello stato operativo;
* Gli **eventi amministrativi e di tutela dei diritti** **`MUST`** essere recepiti ed elaborati ed immagazzinati sul libro mastro, garantendo all'utente l'esercizio inalienabile dei propri diritti anche durante una stasi tecnica;
* Gli eventi di ripristino autorizzato possono riportare il sistema nello stato `NORMAL` previa applicazione di una patch di riparazione formale.

---

### 2.3 Automa del Percorso Umano ($\mathcal{H}$)

Mentre l'automa di sicurezza gestisce la protezione del software, l'evoluzione ed il progresso personale dell'utente sono modellati da un secondo automa di dominio, denominato **Human Journey State Machine ($\mathcal{H}$)**.

L'automa del percorso umano definisce la posizione concettuale dell'utente all'interno di **dodici Stati del Percorso Umano**:

1. **`UNASSESSED`:** Stato iniziale di partenza. Il percorso dell'utente non è ancora stato valutato;
2. **`INITIAL_ASSESSMENT`:** Fase di prima accoglienza ed analisi dei bisogni, vincoli e risorse;
3. **`STABILIZATION`:** Fase di stabilizzazione dell'emergenza o dei bisogni primari;
4. **`DOCUMENT_RECOVERY`:** Fase di recupero dei documenti d'identità e delle posizioni amministrative;
5. **`EMPLOYMENT_READINESS`:** Fase di preparazione al lavoro, bilancio delle competenze e formazione;
6. **`FINANCIAL_AUTONOMY`:** Fase di raggiungimento dell'autonomia finanziaria e gestione del bilancio;
7. **`SUSTAINED_INDEPENDENCE`:** Fase di consolidamento dell'indipendenza e di piena autonomia di vita;
8. **`HUMAN_PAUSED`:** Stato di pausa deliberata. L'utente ha richiesto di sospendere momentaneamente il percorso;
9. **`HUMAN_RECALIBRATION_REQUIRED`:** Stato di ricalibrazione del percorso umano. Attivato a seguito di eventi di stanchezza, sopraffazione emotiva o cambio di obiettivi;
10. **`HUMAN_GOAL_CHANGED`:** L'utente ha ridefinito o cambiato i propri obiettivi personali di vita;
11. **`HUMAN_DECLINED_ASSISTANCE`:** Stato terminale. L'utente ha scelto esplicitamente di revocare ed interrompere il supporto del sistema;
12. **`PREVENTIVE_STANDBY`:** Stato di guardia preventiva. L'utente ha raggiunto la piena indipendenza ma mantiene attivo un monitoraggio discreto di prevenzione delle ricadute.

---

#### 2.3.1 Dinamica della Guardia Preventiva e della Ricalibrazione
Nello stato di guardia preventiva (`PREVENTIVE_STANDBY`), la persona vive in piena autonomia. Qualora dovesse manifestarsi un nuovo momento di crisi o sopraffazione emotiva (`HEV_EMOTIONAL_OVERWHELM`), l'automa sposta lo stato in `HUMAN_RECALIBRATION_REQUIRED`, riattivando il supporto focalizzato del sistema.

#### 2.3.2 Regola Normativa di Preservazione del Progresso Umano (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`)
Quando l'automa umano si trova nello stato di ricalibrazione e supera il momento di difficoltà (evento `HEV_STABILIZED`), il runtime **`MUST`** determinare lo stato di destinazione calcolando la funzione pura `ResolveNextHumanState` basata sul nodo attivo del piano d'azione (Playbook) memorizzato nello stato permanente.

---

> 🛡️ **SCHEDA DI GARANZIA: Preservazione del Progresso Umano (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`)**  
> * **Cosa stabilisce la regola:** Quando un utente supera un momento di sopraffazione o di pausa ed il suo percorso si stabilizza, il sistema lo riporta esattamente allo stato del piano d'azione in cui si trovava prima della difficoltà.  
> * **Perché esiste:** Per evitare che una momentanea debolezza emotiva o un periodo di pausa punisca l'utente azzerando i suoi successi passati.  
> * **Cosa impedisce:** Impedisce che l'utente debba ripartire dall'inizio o ripetere passaggi burocratici già superati (es. doversi procurare nuovamente documenti già in suo possesso).

---

> 💡 **SCENARIO PRATICO: La gestione della crisi emotiva senza perdita di progresso**  
> *Situazione:* Giovanni si trova nella fase di ricerca lavoro (`EMPLOYMENT_READINESS`), dopo aver già ottenuto i documenti d'identità. Un giorno riceve una notizia scoraggiante e segnala una forte sopraffazione emotiva.  
> *Cosa fa SCINTILLA Core:* L'automa umano sposta Giovanni nello stato di Ricalibrazione (`HUMAN_RECALIBRATION_REQUIRED`). Il sistema rallenta il ritmo, gli propone messaggi di ascolto e sospende i compiti pressanti. Una settimana dopo, Giovanni si sente meglio ed invia il segnale di stabilizzazione (`HEV_STABILIZED`). Il Kernel riattiva il percorso **portandolo direttamente alla ricerca lavoro (`EMPLOYMENT_READINESS`)**, conservando intatta tutta la sua storia precedente.

---

### 2.4 Sistema Reattivo Composito ed Invariante di Disaccoppiamento

Il sistema globale reattivo di SCINTILLA Core unisce i due automi in un unico spazio composito. La dinamica è regolata dall'**Invariante di Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`)**:

1. **Gli eventi dell'automa umano non alterano la sicurezza del runtime:** Una richiesta o una difficoltà emotiva dell'utente non possono mai far fallire o mandare in errore l'automa tecnico di sicurezza.
2. **Gli errori tecnici non penalizzano il percorso umano:** Un guasto informatico o un timeout di rete **`SHALL NOT`** paralizzare o retrocedere il progresso umano concettuale dell'utente.
3. **Eccezione di Sovranità in Lockdown:** Qualora il sistema tecnico dovesse piombare in blocco critico di sicurezza (`SECURITY_LOCKDOWN`), le uniche transizioni dell'automa umano che il sistema **`MUST`** continuare ad accettare ed applicare immediatamente sono quelle di richiesta di pausa o di revoca definitiva del supporto (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

# CAPITOLO 3: SEMANTICA OPERAZIONALE FORMALE ESAUSTIVA (SMALL-STEP SOS)
## (Layer B3 - Regole Operative SOS)

---

### 3.1 Matrice Normativa di Autorizzazione Evento-Attore

Ogni transazione inviata al sistema reca l'indicazione dell'attore che l'ha generata. Il sistema applica una matrice di autorizzazione stringente ed inderogabile:

| Attore che invia l'azione | Tipo di Azione Consentita | Note di Sicurezza |
| :--- | :--- | :--- |
| 🧑 **Utente Umano (`USER`)** | Tutti gli eventi del percorso umano, pausa, revoca privacy, recesso | **Autorità Suprema sul proprio percorso.** |
| ⚙️ **Kernel di Sistema (`SYSTEM`)** | Eventi interni di gestione, registrazione errori, gestione timeout | Operatività tecnica automatizzata. |
| 👤 **Operatore Umano (`OPERATOR`)** | Eventi di ripristino tecnico (`EV_REPAIR`, `EV_OVERRIDE`), supporto validato | Richiede firma crittografica forte e motivazione. |
| 🤖 **Intelligenza Artificiale (`LLM`)** | **`SHALL NOT` (0% PERMESSI DI SCRITTURA)** | **Non può modificare lo stato in nessun caso.** |

---

> 🛡️ **SCHEDA DI GARANZIA: Divieto Assoluto di Scrittura per l'Intelligenza Artificiale**  
> * **Cosa stabilisce la regola:** L'Intelligenza Artificiale (LLM, Livello 5) ha esattamente ZERO permessi di modifica sullo stato del sistema o sui dati dell'utente.  
> * **Perché esiste:** Per garantire che un'allucinazione, un errore di comprensione o una risposta stravagante dell'IA non possano mai cancellare dati, cambiare consensi o modificare il percorso della persona.  
> * **Cosa impedisce:** Impedisce che l'IA possa farsi passare per l'utente o per il sistema, agendo come barriera di protezione totale.

---

> 💡 **SCENARIO PRATICO: L'IA non può fingere il completamento di un'azione**  
> *Situazione:* L'Intelligenza Artificiale genera un testo che dice: *"Ho verificato la tua presenza al colloquio, segnavo la tappa come completata"*.  
> *Cosa fa SCINTILLA Core:* Quando il testo dell'IA arriva al Kernel, il controllo dell'attore rileva che l'autore della richiesta è `LLM`. Il Kernel **rifiuta immediatamente la transazione** e solleva un errore di autorizzazione. L'azione verrà registrata solo quando l'utente umano in persona o un operatore autorizzato cliccheranno sul pulsante di conferma.

---

### 3.2 Meta-Regole Operative di Sicurezza di Runtime

La semantica operazionale Small-Step SOS definisce formalmente come lo stato cambia passo dopo passo:

* **Regola di Nominale Sicurezza (`[SOS-META-SAFETY]`):** Se la transazione è autorizzata dall'attore corretto, la validazione ambientale restituisce esito positivo e le regole di sicurezza della policy danno via libera (`ALLOW`), lo stato dell'automa di sicurezza e dello stato permanente vengono aggiornati in modo puro.
* **Regola di Gestione del Fallimento (`[SOS-META-SAFETY-FAIL]`):** Se la validazione ambientale fallisce o l'azione è negata dalle regole, la transazione originale viene scartata ed il sistema genera automaticamente una transazione di errore, portando l'automa di sicurezza in stato di errore di validazione (o mantenendo lo stato di blocco se si trovava già in `SECURITY_LOCKDOWN`).
* **Regola di Ripristino Tecnico (`[SOS-COMPENSATIVE-REPAIR]`):** Un operatore umano autenticato può far uscire il sistema dallo stato di blocco `SECURITY_LOCKDOWN` o `SAFE_READ_ONLY_MODE` **unicamente sottomettendo l'evento `EV_REPAIR` corredato da una patch formale di riparazione dello stato**.

---

### 3.3 Meta-Regole Operative per Competenze e Custodia Documentale

* **Regola per l'Aggiornamento delle Competenze (`[SOS-COMPETENCE-UPDATE]`):** Quando l'utente completa un nodo del piano d'azione che prevede l'apprendimento di una capacità pratica, la nuova competenza viene inserita nel registro permanente delle competenze dell'utente.
* **Regola per la Custodia Documentale (`[SOS-VAULT-RECORD]`):** Quando viene verificato o recuperato un documento d'identità o un attestato, il documento cifrato viene inserito nella cassaforte digitale dell'utente e l'automa umano avanza allo stato di recupero documenti (`DOCUMENT_RECOVERY`).
* **Regola di Stasi in Stato Pausa (`[SOS-HUMAN-PAUSED-STUTTER]`):** Quando l'utente si trova nello stato di pausa (`HUMAN_PAUSED`), qualsiasi evento ordinario giunga viene elaborato con esito "Elaborato senza effetti sullo stato", preservando la stasi finché l'utente non sottomette l'evento esplicito di ripresa (`HEV_RESUME_REQUESTED`).
* **Regola di Timeout per Inattività (`[SOS-HUMAN-TIMEOUT]`):** Se il percorso rimane nello stato di pausa per un periodo di tempo superiore alla soglia parametrizzata di inattività, il sistema genera un evento automatico di ricalibrazione (`HEV_RECALIBRATION_REQ`), invitando delicatamente l'utente ad un aggiornamento del percorso al suo rientro.

---

# CAPITOLO 4: POLICY GUIDANCE ENGINE & STRATIFICAZIONE DELLE POLICY
## (Layer A & Layer B2)

---

### 4.1 Stratificazione delle Policy in 3 Livelli

Per impedire che regole di sicurezza scritte in modo ambiguo o in linguaggio naturale possano causare comportamenti imprevedibili nel software, il Motore delle Politiche (Policy Guidance Engine) adotta una stratificazione rigorosa su tre livelli:

1. **Livello Normativo Umano (Policy Specification Layer):** Testi normativi, principi etici e linee guida redatti in linguaggio naturale controllato per la consultazione da parte degli operatori umani;
2. **Livello di Compilazione (Policy Compilation Layer):** Il processo informatico verificato che traduce le specifiche umane in algoritmi e parametri numerici matematici;
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

**NOTA INFORMATIVA: Che cos'è la Regola Deny-Overrides (Il Diniego Prevale)?**  
È una regola di massima sicurezza usata nei sistemi informatici critici. Immagina un controllo accessi custodito da tre guardiani: se due guardiani dicono "può passare", ma il terzo dice "no, ho rilevato un pericolo", il sistema obbedisce al guardiano che ha rilevato il pericolo e nega l'accesso. La sicurezza e la protezione dell'utente hanno sempre la priorità assoluta su tutto.

---

### 4.4 Decodifica Deterministica dell'Input SML v2.0 in Evento Umano

Per evitare qualsiasi ambiguità tra il linguaggio naturale usato dall'utente o generato dall'intelligenza artificiale ed i comandi rigidi dell'automa umano, il Livello 4 applica la funzione pura `MapSMLToFSMEvent`.

Questa funzione trasforma l'esito conversazionale del documento SML (§C.1) nei comandi esecutivi dell'automa:
* L'esito conversazionale `OVERWHELMED` (Sopraffatto) viene tradotto rigorosamente nell'evento `HEV_EMOTIONAL_OVERWHELM`;
* L'esito `NEEDS_REPHRASING` (Richiesta di chiarimento) viene tradotto in `HEV_RECALIBRATION_REQ`;
* L'esito `DECLINED_ACTION` (Rifiuto dell'azione) viene tradotto in `HEV_PAUSE_REQUESTED`;
* L'esito `ASKED_FOR_HELP` (Richiesta di aiuto) viene tradotto in `HEV_PREVENTIVE_SUPPORT_REQ`.

Se l'esito della conversazione è semplicemente `UNDERSTOOD` (Compreso), la funzione restituisce l'assenza di evento (`NONE`), assicurando che una semplice chiacchierata informativa non produca scatti indesiderati nell'automa del percorso umano.

---

### 4.5 Tassonomia della Guida ed Ergonomia Cognitiva

Per ridurre il carico di stress e l'ansia da prestazione dell'utente vulnerabile, il sistema definisce **tre livelli formali di guida comunicativa**:

1. **Direttiva Autoritativa (`Authoritative Directive`):** Formulazione prescrittiva ed imperativa. È ammessa **esclusivamente** in condizioni di imminente pericolo per la sicurezza fisica o in emergenze acute che richiedono l'intervento immediato di professionisti sanitari o legali (`PROFESSIONAL_INTERVENTION_REQUIRED`).
2. **Raccomandazione Motivata (`Motivated Recommendation`):** Formulazione consigliata che propone un passaggio operativo motivandone il perché, riducendo lo sforzo di pianificazione dell'utente. La raccomandazione **`MUST`** spiegare le ragioni del consiglio ed essere immediatamente modificabile o rifiutabile dall'utente (`USER_CONFIRMED_STEP`).
3. **Opzione Esplorativa (`Exploratory Option`):** Presentazione neutrale di alternative multiple, utilizzata quando l'utente è sereno e desidera valutare autonomamente le diverse possibilità di scelta.

---

> 💡 **SCENARIO PRATICO: Raccomandazione Motivata vs Opzione Esplorativa**  
> *Caso A (Raccomandazione Motivata):* Maria dice: *"Non so da dove cominciare per trovare lavoro"*. Il sistema propone: *"Ti consiglio di richiedere prima il Codice Fiscale, perché è necessario per qualsiasi contratto. Vuoi che ti aiuti a preparare il modulo?"*.  
> *Caso B (Opzione Esplorativa):* Maria dice: *"Vorrei capire che corsi posso fare"*. Il sistema risponde in modo neutrale: *"Ecco tre settori disponibili: Informatica di base, Assistenza agli anziani, Panificazione. Quale di questi suscita la tua curiosità?"*.

---

### 4.6 Filosofia Normativa dell'Intervento Umano (Human Override)

Qualora un operatore umano qualificato (`OPERATOR`) debba intervenire per affiancare l'utente o sbloccare una situazione tecnica, l'azione di override **`MUST`** conformarsi ai seguenti cinque principi normativi:

1. **Tracciabilità Assoluta:** Ogni intervento dell'operatore **`MUST`** generare una transizione firmata e registrata sul libro mastro recante il suo identificativo univoco;
2. **Autenticazione Forte:** L'operatore deve possedere una firma digitale valida ed il permesso esplicito `SC.PERMISSION.OPERATOR_OVERRIDE`;
3. **Spiegabilità Obbligatoria:** Ogni intervento di override **`MUST`** includere una motivazione esplicita in formato testuale chiaro e non vuoto;
4. **Inalterabilità Storica:** L'override modifica lo stato corrente di lavoro, ma **`SHALL NOT`** cancellare, alterare o nascondere le transizioni storiche precedenti scritte sul libro mastro;
5. **Rispetto Assoluto del Consenso dell'Utente:** L'operatore umano **`SHALL NOT`** forzare l'esecuzione di azioni in violazione del consenso espresso dalla persona, salvo nei soli casi di emergenza acuta e tutela della vita previsti dalla legge.

---

# CAPITOLO 5: EMANCIPATION PLAYBOOK ENGINE
## (Layer A & Layer B2)

---

### 5.1 Struttura del Grafo del Piano d'Azione (Playbook)

Un **Emancipation Playbook** (Piano d'Azione per l'Emancipazione) è la mappa operativa che trasforma un grande obiettivo di vita (es. "Ottenere un lavoro", "Trovare casa", "Ricostruire la propria posizione documentale") in una sequenza ordinata e chiara di piccoli passaggi pratici, chiamati **Nodi di Micro-Azione**.

Dal punto di vista della struttura informatica, il Playbook è modellato come una rete orientata composta da tre elementi fondamentali:
1. **Nodi di Micro-Azione:** L'insieme delle singole azioni o tappe pratiche che l'utente può compiere;
2. **Archi di Collegamento Orientati:** Le frecce di direzione che stabiliscono la sequenza logica di successione tra i nodi (es. "Prima richiedi il codice fiscale, POI richiedi la carta d'identità");
3. **Condizioni di Verificabilità:** L'insieme delle regole di controllo informatico che verificano in modo automatico e puro se i prerequisiti necessari per accedere ad uno specifico nodo siano stati effettivamente soddisfatti dallo stato dell'utente.

---

**NOTA INFORMATIVA: Che cos'è un Grafo Orientato ed Aciclico (DAG)?**  
Un grafo è una rete di punti (nodi) collegati da linee (archi). È "orientato" quando le linee hanno una freccia che indica un'unica direzione obbligatoria di percorrenza. È "aciclico" quando, seguendo le frecce, è matematicamente ed algebricamente impossibile tornare indietro formando un circolo vizioso o un loop infinito. Questa struttura garantisce che ogni passo nel Playbook porti sempre l'utente in avanti e mai in trappole burocratiche senza uscita.

---

### 5.2 Tipizzazione dei Nodi del Playbook

Ogni nodo di micro-azione contenuto all'interno del Playbook **`MUST`** appartenere ad una ed una sola delle seguenti quattro categorie formali:

1. **`INFORMATION` (Nodo Informativo):** Un passaggio a contenuto puramente educativo, formativo o informativo (es. "Leggi come funziona un contratto di locazione"). Non richiede alcuna azione pratica o conferma da parte dell'utente per poter proseguire verso i nodi successivi;
2. **`OPTIONAL_STEP` (Passo Opzionale):** Un micro-passo consigliato per ottimizzare il percorso, ma che l'utente può scegliere di saltare liberamente senza produrre alcun blocco o ritardo nel flusso dell'automa;
3. **`USER_CONFIRMED_STEP` (Passo con Conferma dell'Utente):** Un passaggio operativo che richiede la conferma o la dichiarazione esplicita dell'utente prima di poter essere marcato come completato (es. "Dichiaro di aver inviato il modulo di richiesta");
4. **`REQUIRED_FOR_SYSTEM_STATE` (Prerequisito Bloccante di Sistema):** Un passaggio tecnico o legale inderogabile (es. "Verifica dell'avvenuto rilascio del documento d'identità"). Solamente i nodi appartenenti a questa categoria possono condizionare l'avanzamento degli automi di sicurezza del Kernel.

---

### 5.3 Invarianti di Esecuzione e Tracciamento dello Stato

#### 5.3.1 Invariante di Aciclicità Locale sui Nodi Bloccanti (`INV-PLAYBOOK-GRAPH-01`)
Per evitare che l'utente rimanga bloccato in un circolo burocratico infinito, la struttura formata dai soli nodi bloccanti (`REQUIRED_FOR_SYSTEM_STATE`) **`MUST`** costituire una rete orientata strettamente aciclica.

---

> 🛡️ **SCHEDA DI GARANZIA: Invariante di Aciclicità del Piano d'Azione (`INV-PLAYBOOK-GRAPH-01`)**  
> * **Cosa stabilisce la regola:** Il piano d'azione non può mai contenere percorsi circolari tra i passaggi obbligatori (es. "A richiede B, B richiede C, e C richiede A").  
> * **Perché existe:** Per proteggere le persone vulnerabili dalla frustrazione dei vicoli ciechi burocratici o dei rimandi continui tra uffici.  
> * **Cosa impedisce:** Se chi progetta un Playbook inserisce per errore un ciclo tra tappe bloccanti, il Kernel rileva immediatamente l'errore all'atto del caricamento, rifiuta il file e blocca l'esecuzione prima che l'utente possa imbattersi nel problema.

---

> 💡 **SCENARIO PRATICO: La protezione dalle trappole burocratiche circolari**  
> *Situazione:* Un ente locale carica un Playbook errato in cui per richiedere la Tessera Sanitaria occorre la Carta d'Identità, ma per la Carta d'Identità la linea guida richiede la Tessera Sanitaria.  
> *Cosa fa SCINTILLA Core:* Il Playbook Engine controlla la rete dei nodi bloccanti. Riscontrando il ciclo Burocratico chiuso, il Kernel blocca il caricamento e solleva l'errore `ERR_GRAPH_CYCLE_DETECTED` (Codice 83). L'operatore viene costretto a correggere il flusso prima che qualsiasi utente possa trovarsi di fronte al blocco.

---

#### 5.3.2 Durata Parametrizzata delle Micro-Azioni
Per ridurre lo stress e la stanchezza cognitiva dell'utente vulnerabile, la durata stimata di una singola micro-azione non deve superare la soglia massima definita dai parametri di policy (indicata dal parametro temporale di durata massima). Ogni azione deve essere pensata per essere eseguibile in un tempo contenuto, chiaro e ben definito.

#### 5.3.3 Tracciamento dell'Avanzamento nel Registro
Ogni avanzamento dell'utente all'interno del piano d'azione aggiorna lo stato permanente del sistema, registrando l'identificativo del piano d'azione attivo, il nodo correntemente in corso di esecuzione e l'insieme degli identificativi dei nodi già completati con successo.

---

# CAPITOLO 6: TASSONOMIA DELLE VERSIONI ED ALGEBRA DI COMPATIBILITÀ
## (Layer A & Layer B2)

---

### 6.1 Spazio delle Versioni e Profilo di Runtime

Ogni componente software, schema di dati o pacchetto di regole appartiene allo spazio delle versioni ed è identificato da una tupla numerica composta da tre valori: il numero di versione principale, il numero di versione secondaria ed il numero di correzione (secondo la convenzione del Versionamento Semantico).

Il contesto operativo esecutivo di ogni operazione o transazione è vincolato dalla **Tupla del Profilo di Runtime (`RuntimeProfile`)**, che specifica la versione esatta dei quattro pilastri del sistema:
1. Il profilo semantico delle regole operative (es. `"SCINTILLA-SOS-v4.5.5"`);
2. Il profilo dello schema dei dati (es. `"SCHEMA-SC-v10.3"`);
3. Il profilo dell'algoritmo di canonizzazione (es. `"SC-JCS-1"`);
4. Il profilo del pacchetto delle politiche di sicurezza attive (es. `"POLICY-BUNDLE-v1.2"`).

---

**NOTA INFORMATIVA: Che cos'è il Replay Storico Deterministico del Libro Mastro?**  
Poiché il libro mastro registra le decisioni per anni, le regole del software potrebbero aggiornarsi nel tempo passando dalla versione 4 alla versione 5. Quando il sistema deve "riavvolgere il nastro" e rielaborare una vecchia transazione del passato per ricostruire lo stato originale, non deve usare le regole nuove di oggi, ma **deve applicare esattamente le regole che erano in vigore nel momento esatto in cui quella vecchia transazione è stata scritta**. Questo principio garantisce che il passato rimanga sempre perfettamente riproducibile.

---

#### 6.1.1 Regola di Compatibilità per il Replay Storico (`RULE-HISTORICAL-REPLAY-COMPATIBILITY`)
In fase di ricostruzione deterministica dello stato a partire dal registro storico:
1. Ogni transazione passata **`MUST`** essere interpretata e convalidata applicando le regole di semantica operazionale ed i profili di schema esplicitamente registrati nella transazione stessa;
2. L'introduzione di una nuova versione dello standard **`SHALL NOT`** alterare retroattivamente o invalidare il risultato delle transizioni storiche già consolidate sotto le versioni precedenti.

#### 6.1.2 Relazione di Compatibilità Retroattiva
Una prima versione del sistema è compatibile con una seconda versione se, e solo se, entrambe condividono il medesimo numero di versione principale e la prima possiede un numero di versione secondaria o di correzione inferiore o uguale alla seconda.

---

# CAPITOLO 7: CANONIZZAZIONE ASTRATTA ED INTEGRITÀ CRITTOGRAFICA
## (Layer A & Layer B2)

---

### 7.1 Canonizzazione dello Stato (`Canon`)

Per consentire la verifica della firma digitale e l'identificazione univoca delle informazioni su qualsiasi calcolatore, qualsiasi dato strutturato o stato di memoria deve essere convertito in una sequenza binaria di byte UTF-8 attraverso la funzione di **Canonizzazione Deterministica (`Canon`)**.

La funzione di canonizzazione garantisce l'univocità assoluta: due stati o due dati che contengono le medesime informazioni **`MUST`** produrre una rappresentazione in byte esattamente ed inalterabilmente identica (§7.1.1).

---

### 7.2 Catena di Hash Immutabile ed Integrità del Libro Mastro

L'integrità del libro mastro (Ledger) per ogni nuova transazione successiva è garantita dal calcolo dell'impronta crittografica eseguito sul corpo della transazione:
* La primissima transazione dello Stato di Genesi ha un'impronta iniziale costituita da una sequenza nulla di azzeramento a 256 bit;
* Ogni transazione successiva include all'interno del proprio corpo l'impronta della transazione precedente. L'impronta corrente viene calcolata applicando l'algoritmo di hash SHA-256 sulla rappresentazione canonizzata della transazione.

Se un malintenzionato o un guasto hardware tenta di alterare anche solo un singolo carattere di una transazione passata, la catena delle impronte si spezza immediatamente e l'automa di sicurezza piomba nello stato di blocco critico `SECURITY_LOCKDOWN`.

---

**NOTA INFORMATIVA: Che cos'è una Catena di Hash (Hash Chain)?**  
Immagina un registro cartaceo in cui ogni pagina reca in alto un timbro speciale calcolato sul contenuto esatto della pagina precedente. Se qualcuno strappa una pagina passata o ne scarabocchia una sola riga, il timbro sulla pagina successiva non corrisponderà più e la manomissione diventerà immediatamente evidente a chiunque controlli il registro.

---

> 💡 **SCENARIO PRATICO: Il rilevamento di una manomissione storica**  
> *Situazione:* Un utente malevolo o un hacker tenta di accedere direttamente al database del server per modificare una transazione di sei mesi fa, cambiando l'esito di un consenso.  
> *Cosa fa SCINTILLA Core:* Alla transazione successiva, il Kernel ricalcola la catena delle impronte crittografiche. Riscontrando che l'impronta storica non corrisponde più all'impronta memorizzata nella transazione successiva, il sistema rileva l'evento `EV_HASH_CORRUPT`, blocca immediatamente l'esecuzione e sposta l'automa di sicurezza in `SECURITY_LOCKDOWN` (Codice di Errore 77).

---

# CAPITOLO 8: FRAMEWORK DI CONFORMITÀ E TASSONOMIA DEI RUNTIME ERROR CODES
## (Layer B2 - Specificazione Normativa)

---

### 8.1 Criteri Normativi di Accettazione PASS/FAIL

Un'applicazione software ottiene la certificazione ufficiale di conformità allo standard SCINTILLA Core se, e solo se, soddisfa **tre criteri normativi vincolanti**:

1. **Test Vector Match (100% Corrispondenza):** Il software supera la suite di test ufficiali (`CONFORMANCE-TEST-SUITE-v4.5.5.JSON`), generando impronte crittografiche e byte canonizzati bit-a-bit identici a quelli attesi;
2. **Superamento delle Verifiche Temporali LTL/CTL:** Le proprietà matematiche di sicurezza e di avanzamento (§9.2) sono formalmente verificate sul modello dell'applicazione;
3. **Totalità Matematica delle Transizioni:** Il software gestisce in modo esaustivo qualsiasi combinazione possibile di stato ed evento attraverso la funzione di risoluzione prioritaria, senza mai piombare in stati indefiniti o crash imprevisti.

---

### 8.2 Tassonomia dei Runtime Error Codes e Process Exit Codes

Quando si verifica una violazione degli invarianti di sicurezza, un errore di sintassi o una condizione di blocco, il Kernel **`MUST`** segnalare l'anomalia emettendo un **Runtime Error Code** appartenente allo spazio numerico riservato **`70–89`**.

Quando il Kernel viene eseguito come processo autonomo in un sistema operativo (es. Linux o Windows), tale codice di errore **`SHALL`** essere propagato come **Process Exit Code** del programma.

---

**NOTA INFORMATIVA: Che cosa sono i Process Exit Codes (Codici di Uscita del Processo)?**  
Quando un programma informatico termina la propria esecuzione o si blocca per un guasto, restituisce un numero al sistema operativo per spiegare com'è andata. Il numero zero significa "tutto bene", mentre i numeri diversi da zero indicano uno specifico problema. Riservando i numeri da 70 a 89, SCINTILLA Core permette ai sistemi di monitoraggio automatici di capire istantaneamente la causa esatta di un blocco di sicurezza.

---

#### 8.2.1 Sotto-insieme Crittografia, Sicurezza e Consenso (70–79)
* **Codice 71 (`ERR_INVALID_CRYPTO_SIGNATURE`):** La firma digitale applicata alla transazione risulta invalida o contraffatta;
* **Codice 72 (`ERR_CONSENT_REVOKED_VIOLATION`):** Tentativo di eseguire un'operazione su dati di cui l'utente ha esplicitamente revocato il consenso;
* **Codice 73 (`ERR_INFRASTRUCTURE_IO`):** Guasto dell'infrastruttura di memoria, perdita di connessione al disco o impossibilità di scrivere sul libro mastro;
* **Codice 77 (`ERR_SECURITY_VIOLATION`):** Violazione dell'integrità crittografica della catena delle impronte o tentata manomissione storica del registro;
* **Codice 78 (`ERR_LEASE_ACQUISITION_TIMEOUT`):** Scadenza della chiave temporale di concorrenza durante un tentativo di modifica dello stato;
* **Codice 79 (`ERR_CLOCK_SKEW_EXCEEDED`):** L'orologio del calcolatore locale è disallineato rispetto alla data della transazione oltre la tolleranza massima consentita.

#### 8.2.2 Sotto-insieme Validazione, Parsing, Flussi e KMS (80–89)
* **Codice 80 (`ERR_SML_PARSE_FAILED`):** Errore di sintassi nella struttura del documento generato dall'intelligenza artificiale;
* **Codice 81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`):** Scadenza del periodo massimo di inattività consentito durante lo stato di pausa dell'utente;
* **Codice 82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`):** Tentativo di avanzare verso un nodo inesistente nel piano d'azione attivo;
* **Codice 83 (`ERR_GRAPH_CYCLE_DETECTED`):** Rilevazione di un ciclo burocratico bloccante ed illegale all'interno del grafo del Playbook;
* **Codice 84 (`ERR_SCHEMA_MISMATCH`):** Incompatibilità tra la versione dei dati inviati e lo schema atteso dal Kernel;
* **Codice 85 (`ERR_CONFIGURATION_MALFORMED`):** Configurazione malformata, presenza di numeri decimali non interi o violazione delle regole dei Punti Base;
* **Codice 86 (`ERR_HOBM_BOUNDARY_VIOLATION`):** Tentativo di eseguire un'azione ad alto rischio legale senza l'autorizzazione o la firma di un operatore umano;
* **Codice 87 (`ERR_KMS_UNAVAILABLE`):** Indisponibilità o mancata risposta del modulo di custodia delle chiavi crittografiche.

---

# CAPITOLO 9: MODELLI DI SISTEMA DISTRIBUITO, CONCORRENZA E VERIFICA FORMALE
## (Layer A & Layer B2)

---

### 9.1 Consistenza Esterna, Lock e Scherma di Concorrenza

Quando SCINTILLA Core viene eseguito su una rete di più calcolatori collegati tra loro:

1. **Strict Linearizability (Consistenza Esterna):** Il libro mastro garantisce che l'ordine delle operazioni per ogni singolo caso utente sia strettamente sequenziale, come se esista un solo ed unico calcolatore al mondo ad elaborare le richieste;
2. **Fencing Token (Token di Scherma):** Per evitare che due calcolatori diversi modifichino lo stato dell'utente contemporaneamente, ogni operazione **`MUST`** verificare ed incrementare un contatore numerico strettamente crescente (`fencing_token`). Qualsiasi richiesta che arrivi recando un token vecchio o scaduto viene immediatamente rifiutata (`ERR_LEASE_ACQUISITION_TIMEOUT`);
3. **Sincronizzazione Temporale Cluster (`REQ-CLUSTER-CLOCK-SYNC`):** La differenza massima tra gli orologi fisici dei calcolatori della rete non deve mai superare la metà della tolleranza di disallineamento temporale consentita.

---

**NOTA INFORMATIVA: Che cos'è un Fencing Token (Token di Scherma)?**  
Immagina un bastone della parola in un'assemblea: solo chi possiede il bastone può parlare, ed ogni volta che il bastone passa di mano riceve un numero progressivo più alto (1, 2, 3...). Se un membro dell'assemblea tenta di parlare usando un vecchio bastone recante il numero 1 quando ormai si è arrivati al numero 3, la sala lo ignora. Il Fencing Token impedisce che vecchi comandi giunti in ritardo sulla rete possano sovrascrivere o corrompere le decisioni presenti.

---

### 9.2 Modello di Kripke e Verificabilità con Logiche Temporali (LTL e CTL)

Per consentire la verifica formale delle proprietà di sicurezza tramite strumenti automatici di controllo dei modelli (Model Checkers), la dinamica di SCINTILLA Core viene modellata come una struttura di transizione temporale di Kripke.

Il comportamento del sistema nel tempo è vincolato da regole espresse in **Logica Temporale Lineare (LTL)** e **Logica del Tempo Computazionale (CTL)**:

* **LTL Safety 1 (Correttezza delle Decisioni):** Il sistema produce una decisione favorevole solo ed unicamente se le politiche di sicurezza hanno dato esito via libera (`ALLOW`);
* **LTL Safety 2 (Protezione della Scherma):** Se un'operazione non rispetta l'incremento strettamente crescente del token di scherma, il sistema si sposta immediatamente nello stato di errore recuperabile;
* **LTL Safety 3 (Integrità del Libro Mastro):** Se la catena delle impronte crittografiche risulta alterata o non valida, il sistema piomba istantaneamente nello stato di blocco critico di sicurezza (`SECURITY_LOCKDOWN`);
* **LTL Liveness 4 (Recuperabilità del Progresso):** In caso di un guasto tecnico temporaneo o di un errore di validazione, esiste sempre la garanzia temporale che il sistema possa ripristinarsi e consentire all'utente di riprendere il proprio percorso avanzato;
* **LTL Safety 5 (Invarianza dell'Oblio Crittografico):** Una volta eseguita la distruzione della chiave crittografica (`EV_CRYPTO_SHRED_EXECUTED`), la chiave rimane distrutta per sempre in tutti gli istanti futuri del tempo;
* **CTL System Agency Guarantee:** Per qualsiasi stato attivo dell'utente, esiste sempre almeno un cammino futuro raggiungibile che porta ad un avanzamento effettivo del percorso personale.

---

**NOTA INFORMATIVA: Che cos'è il Model Checking con Logiche Temporali?**  
Il Model Checking è una tecnica matematica avanzata in cui un software speciale esplora automaticamente TUTTI i miliardi di percorsi futuri possibili di un programma per dimostrare che non si verificherà mai una situazione pericolosa. Le formule di logica temporale dicono al software cosa deve essere SEMPRE vero in ogni istante (Safety) e cosa deve poter SEMPRE accadere in futuro (Liveness).

---

> 🛡️ **SCHEDA DI GARANZIA: Invarianza dell'Oblio Crittografico nel Tempo (LTL Safety 5)**  
> * **Cosa stabilisce la regola:** Una volta che l'evento di Crypto-Shredding viene eseguito e la chiave viene distrutta, il sistema garantisce che la chiave rimarrà distrutta per sempre in qualsiasi istante del futuro.  
> * **Perché esiste:** Per garantire che un dato cancellato non possa mai "risorgere" o essere ripristinato di nascosto da futuri aggiornamenti software.  
> * **Cosa impedisce:** Impedisce qualsiasi tentativo di recupero o di "backdoor" sui dati dell'utente che ha esercitato il diritto all'oblio.

---

# CAPITOLO 10: STANDARD REFERENCE PROFILE 1 (SC-JCS-1) E CONTRATTI DEGLI AUTOMI IN PROSA
## (Layer C - Profilo Concreto di Riferimento)

---

### 10.1 Definizione del Profilo SC-JCS-1

Per garantire che qualunque sistema informatico produca la medesima identica rappresentazione digitale dei dati su qualsiasi elaboratore al mondo, la specifica definisce il profilo di canonizzazione **SC-JCS-1**.

SCINTILLA Core adotta regole di serializzazione proprietarie e rigorose che **NON sono compatibili a livello di impronta crittografica con lo standard generico RFC 8785**:
1. Imponimento dell'ordinamento delle stringhe di testo basato unicamente sui punti di codice Unicode (*Unicode Code Point Lexicographical Order*);
2. **Divieto assoluto ed inderogabile di qualsiasi numero con la virgola (virgola mobile) o scritto in notazione scientifica.**

---

**NOTA INFORMATIVA: Che cos'è la Canonizzazione SC-JCS-1 e perché vieta i numeri con la virgola?**  
In un file di testo JSON, lo stesso dato può essere scritto in molti modi diversi: inserendo uno spazio in più, invertendo l'ordine di due chiavi (es. `"nome", "cognome"` invece di `"cognome", "nome"`), o scrivendo un numero come `10.0` invece di `10`. Per un calcolatore, anche un solo spazio diverso cambia completamente l'impronta digitale (hash). La canonizzazione SC-JCS-1 elimina tutti gli spazi inutili, ordina le chiavi in modo matematicamente univoco e converte tutti i numeri in interi esatti. I numeri con la virgola vengono vietati perché i diversi processori dei computer li calcolano con impercettibili arrotondamenti differenti, che farebbero fallire la verifica dell'impronta crittografica.

---

### 10.2 Sottoinsieme di Serializzazione e Range degli Interi Sicuri

Un documento JSON appartiene al sottoinsieme valido di SCINTILLA Core se, e solo se, tutti i numeri in esso contenuti sono **esclusivamente numeri interi compresi nell'intervallo sicuro**:
da **-9007199254740991** a **+9007199254740991** (ovvero l'intervallo chiuso compreso tra meno due alla cinquantatreesima potenza più uno e più due alla cinquantatreesima potenza meno uno).

Qualsiasi tentativo di sottomissione di documenti contenenti numeri decimali (es. `1.5`), notazione scientifica (`1e10`), valori non definiti (`NaN`) o infiniti (`Infinity`) **`MUST`** essere immediatamente rifiutato con il **Runtime Error Code 85 (`ERR_CONFIGURATION_MALFORMED`)**.

#### 10.2.1 Regola dei Punti Base (Basis Points)
Tutti i valori probabilistici, i punteggi di confidenza ed i sotto-indici dell'indice `AGI_proxy` **`MUST`** essere espressi e serializzati come numeri interi scalati di un fattore diecimila, ovvero nell'intervallo chiuso di numeri interi compreso tra **0 e 10000 Punti Base** (dove 0 corrisponde allo 0,00% e 10000 corrisponde al 100,00%).

---

### 10.3 Algoritmo di Serializzazione Canonica SC-JCS-1 in 6 Passaggi

L'algoritmo SC-JCS-1 trasforma un documento informatico in byte canonici attraverso i seguenti passaggi sequenziali:

1. **Eliminazione degli Spazi (`Whitespace Elimination`):** Rimuove tutti i caratteri di spaziatura, a capo o tabulazione esterni alle stringhe di testo;
2. **Escaping delle Stringhe (`String Escaping`):** Applica il carattere di fuga unicamente per i caratteri di controllo speciali (da U+0000 a U+001F), le virgolette `"` ed il carattere `\`;
3. **Normalizzazione Unicode (`NFC`):** Applica la normalizzazione Unicode Normalization Form C su tutte le stringhe di testo;
4. **Ordinamento delle Chiavi degli Oggetti (`Object Key Sorting`):** Ordina tutte le chiavi di un oggetto JSON in modo ascendente basandosi sul valore Unicode dei caratteri;
5. **Ordinamento degli Insiemi nel Registro (`SetSemanticsRegistry`):** Per tutte e sole le chiavi registrate nel registro degli insiemi (`completed_nodes`, `permissions`, `prerequisites`, `roles`, `scopes`, `consent_items`, `revoked_items`, `competence_records`, `vault_records`), gli elementi dell'array **`MUST`** essere ordinati in modo ascendente confrontando byte-per-byte le loro rappresentazioni canoniche UTF-8;
6. **Invarianza Posizionale degli Array Generici:** Per tutti gli array non presenti nel registro degli insiemi, la sequenza posizionale degli elementi **`MUST`** essere preservata senza alcuna alterazione, in quanto l'ordine degli elementi costituisce parte integrante della semantica dello stato.

---

> 🛡️ **SCHEDA DI GARANZIA: Determinismo dell'Ordinamento degli Insiemi nel Registro SC-JCS-1**  
> * **Cosa stabilisce la regola:** Gli insiemi di dati memorizzati nel registro (come l'elenco dei consensi, dei documenti o delle competenze) vengono sempre ordinati byte-per-byte secondo una sequenza alfabeticamente perfetta prima di calcolare l'impronta crittografica.  
> * **Perché esiste:** Per evitare che due server o due telefoni diversi, salvando gli stessi documenti in ordine diverso in memoria, generino impronte crittografiche differenti facendosi fallire il consenso a vicenda.  
> * **Cosa impedisce:** Impedisce qualsiasi errore di disallineamento o di incompatibilità tra sistemi informatici diversi che eseguono lo stesso Kernel SCINTILLA Core.

---

### 10.4 Contratto dell'Automa di Sicurezza in Prosa

Il contratto informatico dell'automa di sicurezza di runtime definisce le transizioni deterministiche tra gli stati di sicurezza:

* **Dallo stato `NORMAL`:**
  * Un evento di successo o di ripristino mantiene lo stato in `NORMAL`;
  * L'evento di abbandono sposta lo stato in `REQUIRE_RECALIBRATION`;
  * L'evento di fallimento sintattico SML o di timeout sposta lo stato in `VALIDATION_ERROR`;
  * L'evento di scadenza della chiave temporale di concorrenza sposta lo stato in `RECOVERABLE_FAILURE`;
  * L'evento di corruzione dell'impronta crittografica sposta lo stato in `SECURITY_LOCKDOWN`.
* **Dallo stato `VALIDATION_ERROR` e `RECOVERABLE_FAILURE`:**
  * L'evento di successo ripristina lo stato a `NORMAL`;
  * Il persistere dell'errore di timeout in `RECOVERABLE_FAILURE` sposta lo stato in `OPERATOR_REQUIRED`;
  * L'evento di corruzione dell'impronta crittografica sposta immediatamente lo stato in `SECURITY_LOCKDOWN`.
* **Dallo stato `OPERATOR_REQUIRED`:**
  * Un intervento autorizzato dell'operatore (`EV_OVERRIDE`) ripristina lo stato a `NORMAL`.
* **Dallo stato `SECURITY_LOCKDOWN`:**
  * **È VIETATO qualsiasi ripristino tramite semplice `EV_OVERRIDE`** (rimosso per prevenire livelock);
  * L'unica via di ripristino verso `NORMAL` richiede la sottomissione dell'evento `EV_REPAIR` corredato da una patch di riparazione valida;
  * L'evento di timeout sposta lo stato in `SAFE_READ_ONLY_MODE`.
* **Dallo stato `SAFE_READ_ONLY_MODE`:**
  * L'evento `EV_REPAIR` o `EV_OVERRIDE` ripristina lo stato a `NORMAL`;
  * Gli eventi amministrativi (revoca privacy, cancellazione dati) mantengono lo stato in `SAFE_READ_ONLY_MODE` ma vengono correttamente eseguiti e scritti sul libro mastro.

---

### 10.5 Contratto dell'Automa del Percorso Umano in Prosa

Il contratto dell'automa umano definisce le transizioni dell'utente lungo i dodici stati del percorso umano:

* La progressione nominale segue la sequenza: `UNASSESSED` $\to$ `INITIAL_ASSESSMENT` $\to$ `STABILIZATION` $\to$ `DOCUMENT_RECOVERY` $\to$ `EMPLOYMENT_READINESS` $\to$ `FINANCIAL_AUTONOMY` $\to$ `SUSTAINED_INDEPENDENCE` $\to$ `PREVENTIVE_STANDBY`;
* La richiesta di pausa (evento `HEV_PAUSE_REQUESTED`) sposta l'automa nello stato `HUMAN_PAUSED` da qualsiasi stato attivo;
* La richiesta di ripresa dalla pausa (`HEV_RESUME_REQUESTED`), una sopraffazione emotiva (`HEV_EMOTIONAL_OVERWHELM`) o una regressione sposta l'automa nello stato di ricalibrazione (`HUMAN_RECALIBRATION_REQUIRED`);
* Dallo stato di ricalibrazione, il superamento delle difficoltà (`HEV_STABILIZED`) **riporta l'utente allo stato corrispondente al nodo attivo del Playbook** (`RULE-HUMAN-RECALIBRATION-PRESERVE-PROGRESS-01`), senza mai azzerare le competenze ed i documenti già ottenuti;
* La revoca totale del supporto (`HEV_DECLINE_ALL`) sposta l'automa nello stato terminale ed irreversibile `HUMAN_DECLINED_ASSISTANCE`.

---

# CAPITOLO 11: FRAMEWORK DI CONFORMITÀ E VETTORI DI TEST
## (Layer B / Layer C)

---

### 11.1 Assiomatizzazione della Conformance Suite

La certificazione di conformità di un'implementazione software viene verificata eseguendo la suite di test ufficiali contenuta nell'artefatto **`CONFORMANCE-TEST-SUITE-v4.5.5.JSON`**, che include:
1. **Positive Path Vectors:** Casi di test di successo che verificano la perfetta corrispondenza bit-a-bit delle impronte SHA-256 e dei byte SC-JCS-1 prodotti;
2. **Negative Error Vectors:** Casi di test di errore (input contenenti numeri decimali, cicli burocratici o contratti ambigui) che verificano il corretto sollevamento dei codici di errore da 70 a 89;
3. **Security Vectors:** Tentativi di manomissione della catena delle impronte o firme crittografiche alterate che verificano l'immediato ingresso nello stato di blocco critico `SECURITY_LOCKDOWN`.

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
L'Annesso A.1 definisce la mappatura dei tipi di dati nel linguaggio TypeScript, traducendo i domini informatici negli insiemi corrispondenti (`ActorType`, `GuidanceType`, `PlaybookNodeActionType`, `HumanOversightLevel`, `ProvenanceDomain`).

Tutti i numeri interi e le percentuali sono vincolati dai tipi "brandizzati" `SafeInteger` e `BasisPoints` (intervallo chiuso da 0 a 10000 Punti Base).

### A.2 Implementazione delle Funzioni Helper di Riferimento
L'Annesso A.2 fornisce il codice TypeScript di riferimento per tre operazioni critiche:
1. `parseSafeInteger`: Verifica che un valore numerico sia un numero intero compreso tra -9007199254740991 e +9007199254740991;
2. `parseBasisPoints`: Verifica e satura i valori numerici all'interno dell'intervallo consentito da 0 a 10000 Punti Base;
3. `mapSMLToFSMEvent`: Traduce in modo puro e deterministico l'esito del documento conversazionale SML negli eventi dell'automa umano (es. `OVERWHELMED` $\to$ `HEV_EMOTIONAL_OVERWHELM`).

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

## ANNEX B: SPECIFICA DEL GRAFO DEL PLAYBOOK (LAYER B / LAYER C)

L'Annesso B definisce le strutture dati JSON dei nodi e degli archi che compongono un piano d'azione (Playbook). 

Stabilisce l'obbligo per il motore di gioco di eseguire la validazione di aciclicità sui nodi bloccanti (`REQUIRED_FOR_SYSTEM_STATE`) all'atto del caricamento, sollevando il Codice di Errore 83 (`ERR_GRAPH_CYCLE_DETECTED`) in caso di cicli.

---

## ANNEX C: SPECIFICA SML v2.0 (LAYER B2 / LAYER C)

L'Annesso C definisce la grammatica EBNF sintattica del linguaggio **SML (Syntactic Messaging Language) v2.0**, la struttura testo usata dall'intelligenza artificiale per comunicare con il Kernel.

Definisce inoltre il **Semantic Safety Gate di Livello 2**: se l'intelligenza artificiale genera asserzioni prescrittive su diritti o leggi senza ancorarsi ad una fonte verificata, il parser di Livello 4 scarta immediatamente il messaggio e genera l'evento di errore `EV_SML_FAIL`.

---

## ANNEX D: REGISTRO DELLE DICHIARAZIONI PREVENTIVE (FORWARD DECLARATIONS)

L'Annesso D fornisce il registro di risoluzione topologica di tutti i simboli primitivi utilizzati nella specifica (`P(L)`, `delta_nominal`, `delta_err`, `R_exec`, `DecisionProof`, `SMLOutcome`), consentendo ai sistemi di verifica formale automatizzata (Coq, Lean 4, TLA+) di compilare il modello senza ambiguità di dichiarazione.

---

# GLOSSARIO DEI TERMINI TECNICI

---

**Agency Operativa Responsabile**  
La capacità concreta, qualitativa e personale di un individuo di comprendere il proprio contesto, valutare le alternative, pianificare le azioni ed esercitare il controllo sulla propria vita senza subire manipolazioni o decisioni eterodirette.

**AGI_proxy (Agency Governance Indicator Proxy)**  
Un indicatore numerico descrittivo (compreso tra 0 e 10000 Punti Base) calcolato dal software per valutare l'ergonomia della comunicazione e l'avanzamento del percorso. *Non ha alcuna relazione con l'Intelligenza Artificiale Generale (Artificial General Intelligence).*

**Automa a Stati Finiti (DP-FSM)**  
Un modello matematico di calcolo costituito da un insieme finito di stati e da regole di transizione deterministiche e prioritarie che stabiliscono lo stato successivo in base all'evento ricevuto.

**Basis Points (Punti Base)**  
Un'unità di misura proporzionale in cui 1 Punto Base equivale allo 0,01% (ovvero un diecimillesimo). In SCINTILLA Core viene usata per rappresentare percentuali usando unicamente numeri interi compresi tra 0 e 10000 Punti Base.

**Canonizzazione (SC-JCS-1)**  
Il processo deterministico che converte un documento di dati strutturati (JSON) in una sequenza binaria di byte UTF-8 unica ed inalterabile, eliminando spazi, ordinando le chiavi e normalizzando i testi.

**Crypto-Shredding (Oblio Crittografico Totale)**  
La tecnica di protezione della privacy consistente nella distruzione irreversibile della chiave crittografica usata per cifrare i dati personali dell'utente, rendendo i dati memorizzati sul libro mastro matematicamente ed ininterrottamente illeggibili.

**Determinismo**  
La proprietà di un sistema informatico per cui, dato un determinato stato iniziale ed un medesimo ingresso, il sistema produrrà SEMPRE e rigorosamente lo stesso identico stato finale su qualsiasi calcolatore.

**Fencing Token (Token di Scherma)**  
Un contatore numerico strettamente crescente utilizzato nei sistemi distribuiti per garantire che solo un calcolatore alla volta possa modificare i dati di un utente, rifiutando comandi in ritardo o duplicati.

**Hash / Hash Chain (Catena di Hash / Impronte Crittografiche)**  
Un'impronta digitale crittografica di lunghezza fissa (SHA-256). In una catena di hash, l'impronta di ogni nuova operazione include l'impronta della precedente, rendendo impossibile modificare il passato senza spezzare la catena.

**Invariante di Sistema**  
Una condizione logica o matematica che **`MUST`** rimanere sempre vera in ogni istante di funzionamento del software. Se un'azione tenta di violare un invariante, l'operazione viene bloccata.

**Kernel Normativo**  
Il nucleo centrale deterministico di un sistema informatico che racchiude le regole inderogabili, le politiche di sicurezza ed i vincoli di garanzia dei diritti dell'utente.

**Ledger (Libro Mastro Immutabile)**  
Un registro informatico a sola aggiunta (*append-only*) in cui tutte le decisioni e le transazioni vengono scritte in modo sequenziale, cronologico ed inalterabile.

**LLM (Large Language Model / Modello Linguistico)**  
Un sistema di intelligenza artificiale probabilistico specializzato nell'elaborazione e generazione di linguaggio umano. In SCINTILLA Core opera al Livello 5 senza alcuna autorità di scrittura sullo stato.

**Model Checking (LTL e CTL / Logiche Temporali)**  
Una tecnica di verifica formale automatizzata che esplora matematicamente tutti i possibili stati futuri di un programma per dimostrare che le proprietà di sicurezza (LTL) e di accessibilità (CTL) siano sempre rispettate.

**Playbook (Piano d'Azione per l'Emancipazione)**  
Un grafo orientato ed aciclico di micro-azioni pratiche che guida l'utente verso il raggiungimento di un obiettivo di vita strutturato.

**Process Exit Code (Codice di Uscita del Processo)**  
Un numero intero (in SCINTILLA Core riservato nell'intervallo da 70 a 89) restituito dal programma al sistema operativo per comunicare la causa esatta di un blocco o di un errore di runtime.

**Probabilismo**  
Il comportamento di un componente software il cui risultato non è rigido o matematicamente predicibile a priori, ma espresso in termini di probabilità o verosimiglianza (tipico dell'intelligenza artificiale).

**Safe Integers (Interi Sicuri)**  
L'intervallo chiuso di numeri interi da -9007199254740991 a +9007199254740991 che può essere rappresentato in modo matematicamente esatto secondo lo standard IEEE 754 senza incorrere in errori di arrotondamento.

**SML (Syntactic Messaging Language)**  
Il linguaggio di messaggistica sintattico v2.0 basato su grammatica EBNF utilizzato dall'intelligenza artificiale per proporre azioni e riassunti al Kernel.

**Soft Logical Revocation (Revoca Logica Parziale)**  
Il meccanismo di tutela della privacy mediante il quale un elemento informativo viene nascosto ed oscurato dalle viste pubbliche e dalle API, rimanendo tracciato solo come identificatore revocato nel registro storico per preservare la continuità del grafo.

**Strict Linearizability (Consistenza Esterna)**  
Il modello di consistenza per cui le operazioni su un registro distribuito appaiono a tutti gli osservatori come se venissero eseguite in un ordine temporale unico, istantaneo e sequenziale.

**Stuttering Step (Passo di Identità)**  
Una transizione di un automa a stati finiti in cui l'arrivo di un evento lascia il sistema esattamente nel medesimo stato in cui si trovava, senza produrre alcuna modifica o effetto collaterale.

---

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
