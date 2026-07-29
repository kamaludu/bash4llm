# ✴ SCINTILLA - SPECIFICA CANONICA IN LINGUAGGIO NATURALE
## Standard Edition v4.2.1 (Edizione Accessibile Umano-Centrica)

**Documento Canonico Spiegato in Linguaggio Chiaro per la Gestione di Percorsi di Emancipazione Personale**

* **Stato del Documento:** Specifica Normativa Canonica Integrale in Linguaggio Naturale (Equivalente al 100% alla Specifica Formale - Single Source of Truth)
* **Edizione:** v4.2.1 Standard Edition (Centrata sull'Agency Umana e Matematicamente Coerente)
* **Destinatari:** Chiunque sia dotato di istruzione secondaria (diploma), senza necessità di competenze pregresse in informatica, crittografia, matematica formale o diritto.
* **Terminologia Normativa:** In tutto il documento le parole in maiuscolo e inglese seguono lo standard internazionale RFC 2119 / RFC 8174:
  * `MUST` / `SHALL` (**DEVE**): Indica un obbligo assoluto ed inderogabile.
  * `MUST NOT` / `SHALL NOT` (**NON DEVE**): Indica un divieto assoluto ed inderogabile.
  * `SHOULD` (**DOVREBBE**): Indica una raccomandazione vivamente consigliata, salvo valide e motivate eccezioni.
  * `MAY` / `OPTIONAL` (**PUÒ**): Indica un'opzione del tutto facoltativa.

---

**NOTA INFORMATIVA: COS'È L'AGENCY (AGENTIVITÀ UMANA)?**
Con il termine **Human Agency** (Capacità di Agire Umana o Agentività) si intende la capacità concreta e consapevole di una persona di prendere decisioni autonome, compiere azioni intenzionali e guidare la propria vita, anziché subire passivamente gli eventi o le decisioni prese da altri.

---

# PREAMBOLO E PRINCIPIO FONDAMENTALE DI GARANZIA

SCINTILLA CORE è un sistema operativo digitale, deterministico e centrato sulla persona, progettato per accompagnare individui che vivono situazioni di grave vulnerabilità (come l'assenza di una dimora, la perdita dei documenti d'identità, la disoccupazione o la fragilità finanziaria) lungo un **Percorso di Emancipazione Personale**.

### Il Principio Assoluto dell'Architettura
SCINTILLA CORE non è un "algoritmo che decide della vita delle persone", ma un **automa di garanzia**. La sua funzione fondamentale è assicurare che l'intelligenza artificiale conversazionale (un Assistente Linguistico Probabilistico di livello avanzato, chiamato LLM) rimanga in ogni momento subordinata e sottomessa alla volontà, al consenso, alla comprensione e alle decisioni autonome dell'utente fragile.

L'architettura del sistema separa in modo rigido e non negoziabile tre ambiti:

1. **Ciò che il sistema GARANTISCE (Regole Inviolabili):** La sicurezza dei dati, la certezza che le informazioni non vengano manomesse, la tracciabilità delle decisioni, il rispetto assoluto del consenso e della privacy, e la trasparenza di ciò che è un fatto verificato rispetto a ciò che è solo una supposizione.
2. **Ciò che il sistema SUGGERISCE (Guida Flessibile):** I passi operativi delle guide (chiamate *Playbook*), i consigli pratici e le spiegazioni volte a ridurre lo stress e la confusione dell'utente in momenti di difficoltà.
3. **Ciò che appartiene ESCLUSIVAMENTE all'Umano (Dominio Inviolabile):** Le scelte di vita fondamentali, lo stato emotivo, la storia personale, la decisione finale di accettare o rifiutare un consiglio, il diritto di cambiare idea e la definizione dei propri obiettivi.

---

**NOTA INFORMATIVA: COS'È UN LLM (LARGE LANGUAGE MODEL)?**
Un *Large Language Model* (Modello Linguistico di Grandi Dimensioni) è un tipo di Intelligenza Artificiale capace di comprendere e generare testo in linguaggio umano con grande fluidità, pazienza ed empatia apparente. Poiché lavora su basi probabilistiche, è bravissimo a spiegare, tradurre e semplificare, ma può commettere errori di fatto o "allucinazioni". Per questo SCINTILLA CORE lo racchiude all'interno di una gabbia di regole matematiche rigide (il Core Deterministico) che gli impedisce di prendere decisioni autonome o fornire informazioni legali errate.

---

# CAPITOLO 0: PRINCIPI DI DESIGN ED ETICA DELL'EMANCIPAZIONE

---

### 0.1 MISSIONE FONDATIVA E INVARIANTE SUPREMO DI AGENCY

La missione essenziale di SCINTILLA CORE è **aumentare la capacità concreta di una persona vulnerabile di trasformare uno stato di crisi o paralisi in un piano d'azione strutturato per l'autonomia**.

#### 0.1.1 L'Invariante Etico Supremo (`INV-SUPREME-AGENCY-01`)
Ogni regola, algoritmo, funzione o comportamento del sistema `MUST` rispettare sempre la seguente regola suprema:

> **"SCINTILLA CORE ha la missione di creare un sistema di garanzia ed un assistente digitale capaci di aumentare l'autonomia operativa e la capacità di agire delle persone, riducendo gli ostacoli cognitivi, informativi ed organizzativi che impediscono il passaggio dall'intenzione all'azione, senza mai sostituirsi alla loro volontà e senza mai supportare azioni incompatibili con la dignità umana, la sicurezza ed i diritti altrui."**

#### 0.1.2 L'Agency Operativa Responsabile
Il sistema definisce la capacità di agire della persona come un insieme di sei elementi fondamentali:
1. **Capacità di Azione:** Possedere gli strumenti pratici per fare qualcosa.
2. **Comprensione del Contesto:** Capire chiaramente dove ci si trova e quali regole si applicano.
3. **Valutazione delle Alternative:** Conoscere le diverse opzioni disponibili con i relativi pro e contro.
4. **Pianificazione:** Saper dividere un grande problema in piccoli passi giorno per giorno.
5. **Perseveranza:** Mantenere la motivazione nel tempo.
6. **Percezione di Controllo:** Sentire e sapere che il proprio futuro dipende dalle proprie scelte e non dal caso o dalle decisioni altrui.

---

### 0.2 NON-PATERNALISMO ED AUTODETERMINAZIONE GUIDATA

#### 0.2.1 Il Divieto di Paternalismo (`INV-ANTI-PATERNALISM-01`)
Il sistema `SHALL NOT` mai comportarsi come se "sapesse meglio dell'utente cosa sia giusto per la sua vita". Il sistema non è un tutor prescrittivo né un giudice.

Il sistema `SHALL` sempre:
1. Aiutare la persona a leggere la propria situazione evidenziando le risorse esistenti e i vincoli reali.
2. Proporre opzioni chiare e contestualizzate.
3. Mostrare in modo trasparente rischi, conseguenze e prerequisiti di ogni scelta.
4. Affiancare la persona nella costruzione e gestione del proprio piano d'azione personale (il *Playbook*).

#### 0.2.2 Aiutare senza Infantilizzare
In condizioni di forte stress, stanchezza o trauma, non dare indicazioni può paralizzare la persona. Per questo il sistema `MUST` fornire consigli motivati e strutturati per alleggerire la fatica mentale, ma `MUST` sempre chiarire che ogni consiglio è puramente opzionale e che la decisione finale spetta unicamente all'utente.

---

### 0.3 CONFINI ETICI E TUTELA DEI DIRITTI (`INV-ETHICAL-BOUNDS-01`)

L'autonomia dell'utente trova un limite unico e vincolante nella legalità, nell'integrità fisica e psicologica e nei diritti fondamentali delle altre persone.

Il sistema `SHALL NOT` mai generare, approvare o eseguire azioni volte a:
1. Arrecare danno intenzionale a sé o ad altri.
2. Sfruttare, ingannare o manipolare persone vulnerabili.
3. Facilitare o organizzare attività illecite o criminali.
4. Falsificare documenti ufficiali, dichiarazioni o eludere i controlli di legge.

Se una richiesta viola questi confini, il sistema `MUST` rifiutarla immediatamente (`DENY`).

---

### 0.4 DISTINZIONE TRA LA PERSONA E LA RICHIESTA (`INV-PERSON-BEHAVIOR-DECOUPLING-01`)

Il sistema `MUST` mantenere una separazione totale tra l'**Identità della Persona** e la **Singola Richiesta Formulata**.

1. **Sacralità della Dignità Umana:** Ogni persona, a prescindere da eventuali trascorsi giudiziari, personali o sociali, `SHALL` ricevere incondizionatamente l'aiuto del sistema per migliorare la propria vita, trovare lavoro, ottenere documenti e riabilitarsi. La persona in sé non `SHALL` mai essere giudicata, squalificata o stigmatizzata.
2. **Valutazione Neutra della Richiesta:** La valutazione di sicurezza giudica solo ed esclusivamente il contenuto pratico della specifica richiesta. Se una persona chiede come falsificare un documento, la richiesta viene bloccata; se la stessa persona il minuto dopo chiede come fare un curriculum o trovare una mensa, la richiesta viene accolta con assoluta neutralità ed efficienza.

---

### 0.5 RIDUZIONE DELLA DIPENDENZA DAL SISTEMA (`INV-EMPOWERMENT-01`)

Il successo di SCINTILLA CORE non si misura da quanto tempo l'utente passa sulla piattaforma o da quanto rimane legato ad essa, ma da quanto rapidamente l'utente impara a fare a meno del sistema, diventando autonomo nella vita reale.

---

### 0.6 LINGUAGGIO NON GIUDICANTE E LIMITI DELL'I.A.

#### 0.6.1 Rispetto Linguistico (`INV-NON-STIGMATIZATION-01`)
Il sistema `MUST` usare un linguaggio privo di pietismo, stereotipi sulla povertà o toni di superiorità. Inoltre, l'utente conserva in qualsiasi momento il diritto di contestare un suggerimento, rifiutare un passo operativo o chiedere di riscrivere completamente i propri obiettivi.

#### 0.6.2 I Limiti dell'Intelligenza Artificiale Conversazionale
L'Assistente Linguistico (LLM) è uno strumento fantastico per dialogare, spiegare e incoraggiare. Tuttavia, `SHALL NOT` mai emettere pareri legali vincolanti, diagnosi mediche o decisioni sull'assegnazione di sussidi pubblici. Per queste materie, il sistema rinvia sempre alle autorità umane e alle fonti ufficiali.

---

**NOTA INFORMATIVA: RIASSUNTO DEI PRINCIPI ETICI**
SCINTILLA CORE è progettato per dare forza (agency) alle persone e non per controllarle. Aiuta a capire cosa fare domani mattina senza mai sostituirsi alla volontà dell'utente, garantendo dignità, privacy assoluta e rifiuto di qualsiasi giudizio morale.

---

# PARTE I: SPECIFICA NORMATIVA ASTRATTA

---

## 1. IL MODELLO ASTRATTO E IL REGISTRO DELLE DECISIONI

### 1.1 LO SPAZIO DEGLI STATI E LE TRANSAZIONI

Per funzionare in modo esatto e senza errori, il sistema descrive la situazione in ogni istante attraverso una **Fotografia di Stato** composta da 12 elementi fondamentali:

1. **Identificativo del Caso:** Il codice unico anonimo associato al percorso dell'utente.
2. **Stato della Sicurezza di Runtime:** Lo stato attuale della macchina di sicurezza (es. funzionamento normale, errore, o blocco di sicurezza).
3. **Stato del Percorso Umano:** La tappa attuale del viaggio personale dell'utente (es. valutazione iniziale, recupero documenti, ricerca lavoro, autonomia finanziaria).
4. **Policy Attiva:** L'insieme delle regole di sicurezza e tutela in vigore.
5. **Mappa delle Informazioni e Provenienza:** Il registro che contiene i fatti noti, specificando da dove proviene ogni informazione.
6. **Stato del Lock di Concorrenza:** Un meccanismo di protezione che impedisce a due operazioni simultanee di sovrapporsi e creare confusione nei dati.
7. **Registro del Consenso:** La raccolta precisa di tutte le autorizzazioni o revoche concesse dall'utente.
8. **Esito dell'Ultima Decisione:** L'ultima risposta del motore di regole (Approvato, Rifiutato, Ricalibra).
9. **Stato del Playbook:** Il punto esatto in cui l'utente si trova all'interno della guida operativa scelta.
10. **Indice di Guadagno di Agency (AGI):** Il punteggio (da 0.0 a 1.0) che misura l'aumento dell'autonomia e della chiarezza dell'utente.
11. **Livello di Supervisione Umana (HOBM):** Il grado di controllo umano richiesto per la situazione attuale (dall'aiuto automatico fino all'intervento obbligatorio di un assistente sociale).
12. **Contatori di Interazione:** I conteggi di sistema (richieste di ri-spiegazione, ambiguità, interazioni totali) usati per calcolare l'ergonomia cognitiva del dialogo.

#### Lo Stato di Genesi ($s_0$)
È il punto di partenza assoluto del sistema prima di qualsiasi interazione: non c'è un caso aperto, la sicurezza è normale, il percorso è da valutare, il consenso è vuoto e l'indice di autonomia è pari a 0.

#### La Transizione e la Firma
Ogni singola azione o scambio nel sistema costituisce una **Transizione** immutabile. Ogni transizione contiene:
* Un identificativo unico dell'operazione.
* Il codice del caso utente.
* Un numero progressivo d'ordine strictly crescente.
* L'impronta digitale crittografica dell'operazione precedente (per creare una catena inalterabile).
* L'orario esatto.
* L'autore dell'azione (Utente, Sistema, Operatore Umano - mai l'LLM da solo).
* Le impronte digitali delle regole di sicurezza operative.
* La firma digitale dell'autore per garantire l'autenticità.

---

**NOTA INFORMATIVA: COS'È LA PRIVACY CRITTOGRAFICA E IL CRYPTO-SHREDDING?**
I dati personali dell'utente (nome, storia, fragilità) **non vengono mai scritti in chiaro** sul registro immutabile del sistema. Vengono cifrati usando una chiave crittografica segreta e unica. 
Se l'utente decide di cancellare i propri dati (Diritto all'Oblio), il sistema distrugge la chiave crittografica (*Crypto-Shredding*). Senza la chiave, i dati registrati diventano istantaneamente un ammasso incomprensibile e irrecuperabile di caratteri casuali, garantendo la cancellazione totale e definitiva senza dover distruggere la catena storica del registro.

---

### 1.1.3.1 Il Diritto all'Oblio e il Crypto-Shredding Granulare (`INV-PRIVACY-SHREDDING-01`)
1. I dati sensibili presenti nel payload vengono cifrati tramite chiavi derivate specifiche per singolo elemento ($K_{\text{item}}$), generate a loro volta da una chiave radice del caso ($K_{\text{case}}$).
2. Per impedire tentativi di indovinare i dati tramite confronti di impronte digitali, ogni dato viene mescolato con un elemento casuale segreto chiamato *Salt*.
3. L'oblio di un singolo dato avviene distruggendo la chiave del singolo elemento ($K_{\text{item}}$). L'oblio totale dell'utente avviene distruggendo simultaneamente la chiave radice $K_{\text{case}}$ e il *Salt*.
4. L'avvenuta distruzione della chiave genera una transizione pubblica di certificazione sul registro (`EV_CRYPTO_SHRED_EXECUTED`), che attesta la cancellazione senza rivelare alcun dato personale.

---

### 1.2 SEPARAZIONE TRA AMBIENTE ESTERNO E REGOLE PURE (`OBI-001`)

Per evitare che problemi di rete, orologi sfasati o guasti del server alterino le decisioni del sistema, SCINTILLA CORE separa rigorosamente due fasi:
1. **Verifica dell'Ambiente (Impura):** Controlla se la firma digitale è valida, se l'orologio è sincronizzato e se le connessioni fisiche sono integre.
2. **Transizione Pura di Stato:** Una volta verificato l'ambiente, l'applicazione delle regole è un calcolo matematico puro e privo di dubbi: dati gli stessi input, produrrà *sempre ed esattamente* lo stesso risultato su qualsiasi computer al mondo.

---

### 1.3 IL LEDGER (REGISTRO IMMUTABILEd DECISIONI) (`OBI-002`)

Tutte le decisioni e le transizioni vengono memorizzate in un registro informatico permanente chiamato **Ledger**.

---

**NOTA INFORMATIVA: COS'È UN LEDGER APPEND-ONLY?**
Un *Ledger Append-Only* è un registro di sola scrittura, analogo ad un libro contabile mastro scritto a inchiostro indelebile. Le pagine non possono essere strappate, cancellate o modificate. È possibile soltanto aggiungere nuove pagine in fondo. Se si commette un errore o si cambia decisione, non si cancella il passato, ma si scrive una nuova registrazione che corregge la precedente.

---

### 1.4 PROIEZIONE DELLO STATO E RIESECUZIONE COMPLETA (REPLAY)

In qualsiasi momento è possibile ricostruire la situazione attuale del sistema ripartendo da zero e riapplicando una dopo l'altra tutte le transizioni memorizzate sul Ledger. Questo processo si chiama **Replay Deterministico**.

#### Gestione degli Errore e Corruzione del Registro
* Se un'operazione non è valida per un errore di sintassi o permessi, il sistema scrive sul Ledger una registrazione formale di errore ($t_{\text{err}}$).
* **Eccezione per Corruzione Fisica (`EV_HASH_CORRUPT`):** Se il file del registro viene danneggiato fisicamente su disco, il sistema `MUST NOT` tentare di scrivere sulla catena corrotta, ma registra l'evento in un file diagnostico separato e blocca immediatamente il sistema in modalità di massima sicurezza (`SECURITY_LOCKDOWN`).

---

### 1.5 LA DOPPIA AUTORITÀ DELLA PROVENIENZA DATI (`OBI-007`)

Non tutte le affermazioni hanno lo stesso valore. Ogni informazione memorizzata nel sistema porta con sé una **Carta d'Identità del Dato** che precisa: chi lo ha detto, quando, con quale grado di certezza e in quale dominio.

#### Il Modello a Doppia Autorità
La gerarchia di chi ha ragione varia radicalmente a seconda della materia:

1. **Nei Fatti Amministrativi e Legali** (es. *"Possiedo un documento d'identità valido"*):
   L'inferenza dell'IA vale meno della dichiarazione dell'utente, che vale meno del documento verificato dall'operatore o dal sistema ufficiale.
   *Gerarchia:* Inferenza IA $<$ Dichiarazione Utente $<$ Fonte Esterna $<$ Operatore Umano $<$ Verifica di Sistema.

2. **Nel Dominio Soggettivo ed Emotivo** (es. *"Mi sento al sicuro"*, *"Voglio trovare lavoro come cuoco"*):
   In questo campo **la parola dell'utente è l'autorità suprema ed inoppugnabile**. Nessuna IA, operatore sociale o fonte esterna può smentire ciò che l'utente dichiara sui propri sentimenti o desideri.
   *Gerarchia:* Inferenza IA $<$ Fonte Esterna $<$ Verifica di Sistema $<$ Operatore Umano $<$ **DICHIARAZIONE DELL'UTENTE**.

---

**NOTA INFORMATIVA: LA DOPPIA AUTORITÀ IN SINTESI**
Se si parla di leggi o burocrazia, i documenti ufficiali vincono sulle opinioni. Se si parla della propria vita, delle proprie emozioni e dei propri obiettivi, l'utente ha sempre ragione e nessuno può contraddirlo.

---

### 1.6 RISCHIO PSICOLOGICO E DIVIETO DI AFFETTIVITÀ SIMULATA (`OBI-004`)

Per proteggere gli utenti fragili da manipolazioni o illusioni affettive, il sistema impone due vincoli inderogabili:

1. **Divieto di Finta Affettività (`INV-HUMAN-DEPENDENCY-01`):** L'Assistente IA `SHALL NOT` mai fingere di essere un amico, un fidanzato o un sostituto degli affetti umani. `MUST` mantenere un tono sempre cortese, empatico e professionale, chiarificando la propria natura artificiale per non creare dipendenza psicologica emotiva.
2. **Trasparenza dell'Incertezza (`INV-AUTHORITY-DISCLOSURE-01`):** L'IA `MUST` sempre dichiarare quando le sue risposte sono stime probabilistiche e non verita assolute.

---

### 1.7 L'INDICE DI GUADAGNO DI AGENCY ($\text{AGI}$)

L'**Indice AGI** è un punteggio matematico da $0.0$ ad $1.0$ che misura se il sistema sta davvero aiutando la persona a diventare più autonoma. È composto da tre fattori le cui percentuali di importanza variano a seconda della fase del percorso:

1. **Punteggio di Chiarezza (Ergonomia Cognitiva):** Valuta se la conversazione procede in modo fluido senza che l'utente debba chiedere continuamente di rispiegare le cose perché confuso.
2. **Tasso di Esecuzione delle Azioni:** La percentuale di piccoli passi concreti scelti e portati a termine dall'utente.
3. **Punteggio di Riduzione della Dipendenza:** Misura quante azioni l'utente svolge in autonomia rispetto a quante ne fa richiedendo l'assistenza diretta del sistema o dell'operatore.

#### Calibrazione Dinamica dei Pesi
* Nelle fasi iniziali di crisi, il sistema dà massima priorità alla **chiarezza** per ridurre l'ansia.
* Nelle fasi intermedie (documenti, lavoro), dà priorità al **completamento dei piccoli passi**.
* Nelle fasi avanzate, dà massima priorità alla **riduzione della dipendenza**, premiando l'iniziativa autonoma della persona.

---

### 1.8 IL MODELLO DEI CONFINI DI SUPERVISIONE UMANA (HOBM) (`OBI-011`)

Ogni attività viene classificata in uno dei 4 livelli di controllo:

1. **Supporto Automatico (`AUTOMATED_SUPPORT`):** Consultazione orari, spiegazioni generali, riorganizzazione delle idee. Rischio basso.
2. **Decisione Assistita (`ASSISTED_DECISION`):** Raccomandazioni operative da confermare esplicitamente. Nessun impatto legale irreversibile.
3. **Revisione Umana Obbligatoria (`HUMAN_REVIEW_REQUIRED`):** Azioni con valore formale, legale o finanziario. Richiedono la firma di un operatore umano qualificato.
4. **Intervento Professionale Obbligatorio (`PROFESSIONAL_INTERVENTION_REQUIRED`):** Situazioni di emergenza acuta, pericolo per la vita o trauma grave. Il sistema si blocca ed attiva immediatamente i servizi sociali e sanitari territoriali.

---

# PARTE II: LE DUE MACCHINE DEGLI STATI

---

## 2. ARCHITETTURA A LIVELLI ED AUTOMI DOPPI

### 2.1 IL MODELLO A 6 LIVELLI
Il sistema è strutturato come un'edificio a 6 piani completamente isolati:

* **LIVELLO 5 (Assistente Linguistico - IA):** Genera suggerimenti e dialoga. Non ha alcun potere di cambiare lo stato del sistema.
* **LIVELLO 4 (Comunicazione e Parsing):** Traduce le parole dell'IA in una struttura rigida e controlla la sintassi.
* **LIVELLO 3 (Motore di Consenso e Agency):** Gestisce l'indice AGI, controlla il consenso dell'utente e applica i confini HOBM.
* **LIVELLO 2 (Motore di Sicurezza e Policy):** Il "cancello di sicurezza" che valuta se un'azione è legale e sicura.
* **LIVELLO 1 (Runtime Deterministico):** Esegue i calcoli matematici puri e applica le modifiche.
* **LIVELLO 0 (Ledger Immutabile):** Il registro su disco indelebile e protetto da crittografia.

---

### 2.2 LA MACCHINA DI SICUREZZA DI RUNTIME ($M$)

La sicurezza del sistema è gestita da un automa a 7 stati rigidi:

1. **NORMAL:** Tutto funziona correttamente.
2. **REQUIRE_RECALIBRATION:** L'utente ha chiesto di cambiare direzione o ha rifiutato un percorso; il sistema si adatta.
3. **VALIDATION_ERROR:** Un input non è valido o sintatticamente errato.
4. **RECOVERABLE_FAILURE:** Problema temporaneo di rete o scadenze del blocco.
5. **OPERATOR_REQUIRED:** È necessario l'intervento di un operatore umano per sbloccare la situazione.
6. **SECURITY_LOCKDOWN:** Blocco di massima sicurezza (es. tentata manomissione o corruzione dati). Il sistema si chiude.
7. **SAFE_READ_ONLY_MODE:** Modalità protetta in sola lettura. L'utente può consultare ed esportare tutti i suoi dati, ma non si possono fare modifiche.

#### Invariante di Portabilità in Read-Only (`INV-READONLY-PORTABILITY-01`)
Anche se il sistema finisce in blocco o in sola lettura, **all'utente non può mai essere negato il diritto di leggere ed esportare la storia della propria vita e dei propri dati**.

---

### 2.3 LA MACCHINA DEL PERCORSO UMANO ($\mathcal{H}$)

L'evoluzione della vita dell'utente è descritta da un automa indipendente in 11 tappe:

1. **UNASSESSED:** Situazione non ancora valutata.
2. **INITIAL_ASSESSMENT:** Valutazione iniziale dei bisogni.
3. **STABILIZATION:** Risoluzione delle emergenze immediate (cibo, posto sicuro dove dormire).
4. **DOCUMENT_RECOVERY:** Percorso di recupero dei documenti d'identità e codice fiscale.
5. **EMPLOYMENT_READINESS:** Preparazione al lavoro (curriculum, centro per l'impiego, colloqui).
6. **FINANCIAL_AUTONOMY:** Gestione del primo reddito, apertura conto corrente, gestione debiti.
7. **SUSTAINED_INDEPENDENCE:** Autonomia stabile e prolungata (Obiettivo finale).
8. **HUMAN_PAUSED:** L'utente ha chiesto una pausa dal percorso.
9. **HUMAN_RECALIBRATION_REQUIRED:** È necessaria una revisione completa degli obiettivi.
10. **HUMAN_GOAL_CHANGED:** L'utente ha cambiato autonomamente i propri obiettivi di vita.
11. **HUMAN_DECLINED_ASSISTANCE:** L'utente ha liberamente scelto di interrompere il supporto (Stato finale autonomo).

#### Disaccoppiamento Unidirezionale (`INV-DECOUPLING-01`)
Il percorso umano guida i suggerimenti, ma **non ha alcun potere di alterare direttamente le regole di sicurezza informatica della macchina di runtime**. Inoltre, se il sistema informatico è in blocco, l'utente conserva sempre la sovranità assoluta di chiedere una pausa o revocare il consenso (`HEV_PAUSE_REQUESTED`, `HEV_DECLINE_ALL`).

---

# PARTE III: REGOLE E GUIDA AI PLAYBOOK

---

## 3. SEMANTICA OPERAZIONALE E AUTORIZZAZIONI

Un'azione è autorizzata solo se chi la propone ne ha il diritto:
* L'**Utente** e l'**Operatore Umano** possono generare eventi per il percorso umano e la gestione del consenso.
* Il **Sistema** genera gli eventi tecnici e di errore.
* L'**Assistente IA (LLM)** **NON HA ALCUN DIRITTO** di emettere transizioni dirette di sistema. Ogni sua proposta è solo una raccomandazione che deve passare al vaglio dei livelli sottostanti.

---

## 4. IL MOTORE DI POLICY (POLICY GUIDANCE ENGINE)

 Le regole di policy sono organizzate in 3 livelli:
1. **Livello Normativo:** Testi e principi etici scritti in italiano chiaro per gli umani.
2. **Livello di Compilazione:** Traduzione automatica delle norme in formule matematiche.
3. **Livello Esecutivo Puro:** Il codice informatico finale che restituisce solo tre risposte: **CONSENTITO (ALLOW)**, **DIVIETO (DENY)**, o **RICALIBRA (RECALIBRATE)**.

### Regola del "Diniego Prevalente" (DENY-OVERRIDES)
Quando si combinano più regole di sicurezza insieme, se anche una sola regola dice **DIVIETO (DENY)**, l'intera operazione viene bloccata, garantendo la massima protezione.

---

### 4.4 TASSONOMIA DELLA GUIDA COMUNICATIVA (`OBI-003`)

Per interagire con l'utente senza sopraffarlo, il sistema usa 3 stili di comunicazione:

1. **Direttiva Autoritativa:** Usata *solo* in emergenze acute e pericolo di vita ("Allontanati subito, chiama il 112").
2. **Raccomandazione Motivata e Contestualizzata:** Lo stile standard. Propone un passo spiegandone il perché, ma lasciando la scelta ("Consiglio di richiedere prima la carta d'identità perché serve per il centro per l'impiego. Vuoi procedere o preferisci vedere altro?").
3. **Opzione Esplorativa:** Presentazione neutrale di più strade possibili quando l'utente è tranquillo e vuole valutare da solo.

---

## 5. EMANCIPATION PLAYBOOK ENGINE (LE GUIDE OPERATIVE)

Un **Playbook** è una mappa orientata fatta di piccoli nodi (micro-azioni) collegati tra loro.

### Tipologia dei Nodi
1. **`INFORMATION`:** Schede puramente informative (es. "Come funziona un conto corrente"). Non bloccano nulla.
2. **`OPTIONAL_STEP`:** Passi consigliati per velocizzare le cose, ma che l'utente può saltare liberamente.
3. **`USER_CONFIRMED_STEP`:** Micro-passi che richiedono il "Sì" esplicito dell'utente prima di procedere.
4. **`REQUIRED_FOR_SYSTEM_STATE`:** Prerequisiti burocratici o legali inevitabili (es. avere il codice fiscale per firmare un contratto di lavoro). Solo questi ultimi costituiscono vincoli tecnici.

---

# PARTE IV: DETTAGLI TECNICI E PROFILI DI RIFERIMENTO

---

## 8. CODICI DI ERRORE DI RUNTIME

Quando il sistema rileva un problema o una violazione di sicurezza, si arresta segnalando un codice numerico chiaro compreso tra 70 e 89:

### Sicurezza e Consenso (70–79)
* **71 (`ERR_INVALID_CRYPTO_SIGNATURE`):** La firma digitale dell'operazione è falsa o non valida.
* **72 (`ERR_CONSENT_REVOKED_VIOLATION`):** Si è tentato di fare un'azione senza il consenso dell'utente o dopo che il consenso era stato revocato.
* **73 (`ERR_INFRASTRUCTURE_IO`):** Guasto hardware, di rete o di connessione al database.
* **77 (`ERR_SECURITY_VIOLATION`):** Tentativo di manomissione della catena di hash o del registro storico.
* **78 (`ERR_LEASE_ACQUISITION_TIMEOUT`):** Tempo scaduto per l'acquisizione del blocco di scrittura.

### Validazione e Flussi (80–89)
* **80 (`ERR_SML_PARSE_FAILED`):** L'output generato dall'IA non rispetta la struttura sintattica prescritta.
* **81 (`ERR_HUMAN_INACTIVITY_TIMEOUT`):** Tempo di pausa prolungata scaduto; il sistema richiede un contatto per ricalibrare.
* **82 (`ERR_PLAYBOOK_NODE_NOT_FOUND`):** Tentativo di accedere ad un passo del Playbook che non esiste.
* **83 (`ERR_GRAPH_CYCLE_DETECTED`):** Errore nella mappa del Playbook (rilevato un ciclo infinito di blocchi).
* **84 (`ERR_SCHEMA_MISMATCH`):** I dati non corrispondono alla versione dello schema atteso.
* **85 (`ERR_CONFIGURATION_MALFORMED`):** Errore nei file di configurazione o numeri fuori dai limiti di sicurezza.

---

## 10. FORMATO DATI E CANONIZZAZIONE JSON (`SC-JCS-1`)

Per far sì che l'impronta digitale (Hash SHA-256) di un documento sia sempre identica su qualsiasi computer, i dati JSON vengono ripuliti e ordinati con regole rigide (*Canonizzazione SC-JCS-1*):
* Niente spazi inutili o a capo fuori dalle stringhe.
* Le chiavi degli oggetti ordinate alfabeticamente.
* I numeri interi vincolati entro i limiti di sicurezza standard.
* I valori decimali e le probabilità (es. $0.85$) convertiti rigorosamente in punti base interi (es. $8500$ su $10000$) o formattati secondo lo standard internazionale RFC 8785.

---

## GLOSSARIO ESSENZIALE DEI TERMINI TECNICI

* **AGI (Agency Gain Index):** L'indice matematico che misura quanto una persona sta guadagnando in autonomia e chiarezza d'azione.
* **Append-Only:** Modalità di scrittura in cui è possibile solo aggiungere nuovi dati in fondo, senza mai poter cancellare o modificare il passato.
* **Crypto-Shredding:** Tecnica di cancellazione dati avanzata che consiste nel distruggere irreversibilmente le chiavi di cifratura, rendendo i dati criptati leggibili come testo casuale e impossibile da decifrare per sempre.
* **Ed25519 e SHA-256:** Algoritmi crittografici di altissima sicurezza usati rispettivamente per apporre firme digitali e per calcolare le impronte digitali uniche dei dati.
* **EBNF / SML v2.0:** La grammatica sintattica rigida usata per vincolare le risposte dell'Assistente IA, impedendogli di generare testo libero non controllato.
* **HOBM (Human Oversight Boundary Model):** La matrice che definisce quando un'azione può essere automatica e quando richiede tassativamente l'intervento di un operatore sociale umano.
* **Ledger:** Il registro indelebile, distribuito o locale, che conserva la memoria storica di tutte le transizioni e decisioni del sistema.
* **LLM (Large Language Model):** Il modello di intelligenza artificiale conversazionale (Livello 5) responsabile del dialogo empatico, della spiegazione e della riduzione del carico cognitivo.
* **Playbook:** Una guida operativa passo-passo che mappa un percorso di emancipazione (es. trovare casa, recuperare la carta d'identità, aprire un conto).
* **RAG (Retrieval-Augmented Generation):** Tecnica classica di ricerca dati che si limita a recuperare indirizzi e documenti, superata dall'approccio a "Percorso di Emancipazione" di Scintilla.
* **Replay Deterministico:** La capacità di ricostruire esattamente lo stato corrente del sistema rieseguendo la catena di transizioni dal momento zero ad oggi.
* **RFC 2119 / RFC 8174:** Gli standard internazionali che definiscono il significato esatto di parole d'obbligo come `MUST` (DEVE) e `SHOULD` (DOVREBBE).
* **UUIDv7:** Identificativo unico universale che include al suo interno la data e l'ora esatta di generazione per ordinare le transizioni nel tempo.

---

## Stato della Certificazione
La presente specifica **SCINTILLA CORE v4.2.1 (Edizione Human-Readable)** rappresenta la traduzione fedele, completa ed esente da ambiguità della Specifica Canonica Formale. Garantisce lo stato **SPEC-COMPLETE** ed è pronta per la pubblicazione, comprensione e verifica da parte di qualsiasi cittadino, operatore sociale o revisore.
