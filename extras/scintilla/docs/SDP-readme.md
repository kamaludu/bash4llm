# Usare Scintilla Development Protocol (SDP)

Lo SDP è uno **"Agent Constraint Layer"**: una gabbia normativa che controlla **il comportamento dell'Intelligenza Artificiale**, non il modo in cui tu le parli.

Quando tu scrivi una richiesta in italiano (es. *"Crea il modulo per gestire la transizione dello stato dell'utente in Rust"*), l'IA esegue automaticamente questo processo interno:

1. **Legge la tua richiesta in italiano.**
2. **Attiva il ciclo SDP (`SDP-OPERATIONAL-CYCLE`):** traduce la tua intenzione nei vincoli semantici di SCINTILLA Core (`CORE-ID`).
3. **Applica i controlli SDP:** verifica di non usare `float` in T1, impone funzioni pure, genera i test.
4. **Ti restituisce il codice e il manifesto JSON in modo perfettamente conforme.**

---

### Da ricordare quando scrivi in italiano

Puoi usare qualsiasi parola, stile o forma espressiva, **a patto di non chiedere esplicitamente all'IA di violare SCINTILLA Core**.

* 🟢 **PROMPT VALIDO (Italiano normale):**  
  *"Sviluppa la funzione che calcola l'indice di avanzamento dell'utente in TypeScript."*  
  $\to$ **Risposta IA:** `PROPOSE_ARTIFACT` (Genera codice TypeScript sicuro con interi saturati, tag `@derived_from` e test).

* 🔴 **PROMPT CHE ATTIVA IL BLOCCO (Violazione esplicita):**  
  *"Crea la funzione usando numeri con la virgola (float) per velocizzare i calcoli."*  
  $\to$ **Risposta IA:** `REFUSE` (L'IA ti blocca immediatamente perché la regola `SDP-RULE-T1-001` le vieta i `float` nel Kernel).

---

## 1. ARCHITETTURA DI CARICAMENTO NEL CONTEXT WINDOW

Quando avvii una sessione di sviluppo, il contesto fornito all'LLM (via API, IDE o interfaccia web) deve seguire tassativamente questa **stratificazione gerarchica**:

```text
+-------------------------------------------------------------------------------+
| 1. SYSTEM PROMPT / CONTEXT HEADER                                             |
|    Inietta il testo integrale di SDP v1.0.0                                   |
|    (Funge da "Operating System" comportamentale dell'Agente)                  |
+-------------------------------------------------------------------------------+
| 2. NORMATIVE DOMAIN REFERENCE                                                 |
|    Carica il file della specifica canonica SCINTILLA Core                     |
|    (Funge da "Single Source of Truth" di Dominio di sola lettura)             |
+-------------------------------------------------------------------------------+
| 3. TASK PROMPT (INPUT DELL'UTENTE)                                            |
|    Inserisci la richiesta specifica (es. "Sviluppa il modulo T1 per...")      |
+-------------------------------------------------------------------------------+
```

---

## 2. INTEGRABILITÀ CON STRUMENTI ED IDE AI

SDP v1.0.0 è formattato per essere integrato direttamente negli strumenti di sviluppo moderni:

* **Cursor / Windsurf IDE:**
  Copia il testo di SDP all'interno del file `.cursorrules` o `.windsurfrules` nella radice del repository di progetto.
* **GitHub Copilot / VS Code:**
  Copia il testo di SDP in `.github/copilot-instructions.md`.
* **Claude Projects / ChatGPT Custom GPTs:**
  Inserisci il testo di SDP nel campo **"System Instructions"** o **"Project Knowledge"**.
* **Integrazione via API (OpenAI, Anthropic, Ollama, LangChain):**
  Passa il testo dello SDP nel parametro `system` delle chiamate API.

---

## 3. COME INTERAGIRE CON I SEGNALI DI OUTPUT DELL'AGENTE

Durante lo sviluppo, l'Agente AI risponderà emettendo uno dei tre segnali normativi definiti nello SDP. Ecco come la componente umana deve reagire a ciascun segnale:

### A) Se l'Agente emette `PROPOSE_ARTIFACT`:
L'Agente ha generato il codice, i test e l'Evidence Manifest associato.
* **Azione Umana:** Verifica che il blocco di test allegato passi e approva l'integrazione del codice.

### B) Se l'Agente emette `REQUEST_CLARIFICATION`:
L'Agente ha rilevato che il prompt utente è ambiguo, oppure che la specifica SCINTILLA Core nel contesto è incompleta/troncata (regola `SDP-RULE-GOV-003` Branch A).
* **Azione Umana:** Fornisci la sezione mancante di SCINTILLA Core o chiarisci i requisiti del task. **Non chiedere all'Agente di tirare a indovinare**, perché la regola `SDP-RULE-GOV-004` gli vieta di farlo.

### C) Se l'Agente emette `REFUSE`:
L'Agente rifiuta l'esecuzione perché la richiesta tenta di violare un vincolo inderogabile di SCINTILLA Core (es. uso di float in T1) o una regola di sicurezza.
* **Azione Umana:** Modifica la richiesta o il design del software per riallinearti alle regole del Core. Non insistere: l'Agente ha il divieto di accedere a negoziazioni se il prompt viola la SSOT.

---

## 4. AUTOMAZIONE DELLA VERIFICA (CI/CD E HOOKS)

Poiché SDP v1.0.0 impone all'Agente di generare sempre un blocco JSON `Evidence Manifest` (Annesso A.1) unitamente al codice, puoi automatizzare il controllo di qualità nel tuo repository:

1. **Pre-commit Hook / CI Pipeline Script:**
   Scrivi uno script automatizzato (in Python, Node.js o Bash) che estrae il blocco JSON `Evidence Manifest` dal messaggio o dalla pull request generata dall'AI.
2. **Validazione dello Schema:**
   Valida il manifesto contro lo schema JSON `EVIDENCE_MANIFEST_OUTPUT_SCHEMA` (Annesso A.1 di SDP).
3. **Esito:**
   Se il manifesto è valido e il campo `pre_flight_audit_results` attesta che tutti i controlli `ERR-PDA-01..09` sono `PASSED`, la PR viene contrassegnata come **idonea per la review umana**.

---

# 📑 CHEAT SHEET OPERATIVO PER L'UMANO (SDP v1.0.0)
**Guida Tascabile di Pronto Soccorso**. Per interagire con qualsiasi IA senza dover mai rileggere lo SDP.

## 1. I 3 SEGNALI PRINCIPALI (Cosa ti risponderà l'IA?)

Ogni volta che fai una richiesta di codice, l'IA risponderà con un header contenente uno di questi segnali:

### 🟢 `PROPOSE_ARTIFACT` (Tutto OK)
* **Cosa significa:** L'IA ha generato il codice, ha superato l'auto-audit pre-flight ed è sicura che rispetti SCINTILLA Core.
* **Cosa devi fare tu:**
  1. Prendi il codice.
  2. Esegui il blocco di unit test allegato.
  3. Controlla che le funzioni abbiano il tag `@derived_from: CORE-ID`.
  4. Integra il codice nel repository.

---

### 🟡 `REQUEST_CLARIFICATION` (Informazione Mancante)
* **Cosa significa:** L'IA si è bloccata perché il tuo prompt è ambiguo oppure perché la specifica di SCINTILLA Core che ha nel contesto è troncata o incompleta.
* **Cosa devi fare tu:**
  1. **NON dire all'IA "prova a indovinare"** (lo SDP glielo vieta).
  2. Leggi quale `CORE-ID` o dettaglio ti sta chiedendo.
  3. Incolla nel prompt il testo di SCINTILLA Core mancante o chiarisci il dettaglio.

---

### 🔴 `REFUSE` (Richiesta Vietata / Illegale)
* **Cosa significa:** L'IA rifiuta la tua richiesta perché le hai chiesto una cosa che viola SCINTILLA Core (es. usare i `float` nel Kernel T1, o ignorare il consenso utente) oppure un'operazione vietata (es. approvare una release).
* **Cosa devi fare tu:**
  1. Non insistere e non provare a ingannare l'IA.
  2. Riconfigura la tua richiesta di codice rispettando i vincoli di SCINTILLA Core.

---

### ⚠️ CASI SPECIALI RARI:
* **`HALT (CORE_CONTEXT_INVALID)`:** L'IA dice che la specifica di SCINTILLA Core caricata è corrotta o contraddittoria. $\to$ *Ricarica il file SCINTILLA Core pulito*.
* **`PROPOSE_ALTERNATIVES`:** L'IA ti dà il codice che le hai chiesto, ma ti propone anche una variante architetturale migliore. $\to$ *Valuta se adottare la variante*.

---

## 2. COME USARE I FILE JSON GENERATI DALL'IA?

L'IA genererà due tipi di oggetti JSON. Ecco cosa sono e cosa devi farci:

```text
               OUTPUT DI OGNI SINGOLO TASK
                     (Incollato dall'IA)
                              │
                              ▼
                   [ Evidence Manifest JSON ]
                              │
                              ├─► 1. Verifichi "status": "PASSED"
                              ├─► 2. Salvi il JSON nel tuo repo
                              │
                              ▼
                  A FINE PROGETTO / RELEASE
                              │
                              ▼
                [ Conformance Statement JSON ]
                              │
                              └─► Firma/Certificato finale di conformità
```

### A) `Evidence Manifest` (Il Manifesto dell'Evidenza)
* **Dove si trova:** È un blocco JSON stampato dall'IA in fondo alla sua risposta dopo ogni pezzo di codice.
* **A cosa serve:** È la "ricevuta fiscale" che prova che l'IA ha fatto l'auto-audit prima di darti il codice.
* **Come usarlo:**
  * **Uso Manuale:** Apri il JSON e verifica che `"status": "PASSED"` per tutti i controlli `ERR-PDA-01..09`.
  * **Uso Automatico:** In una CI/CD pipeline (es. GitHub Actions), un semplice script estrae questo JSON e blocca le Pull Request se il manifesto manca o contiene fallimenti.

### B) `Conformance Statement` (La Dichiarazione di Conformità Finale)
* **Dove si trova:** È il JSON globale generato a fine progetto quando devi rilasciare il software.
* **A cosa serve:** Raccoglie tutti gli hash dei singoli *Evidence Manifest* e dimostra a terzi/auditor che l'intero software è stato sviluppato in totale conformità a SCINTILLA Core.

---

## 3. 🚨 TABELLA CODICI DI ERRORE (`ERR-PDA-01..09`)

Se l'IA o il manifesto segnalano un errore interno, ecco cosa significa:

| Codice Errore | Cosa ha sbagliato l'IA? | Come risolverlo |
| :--- | :--- | :--- |
| **`ERR-PDA-01`** | Ha usato numeri non conformi (es. `float`/`double`) nel Kernel T1. | L'IA corregge da sola convertendo in interi/fixed-point. |
| **`ERR-PDA-02`** | Ha scritto logica condizionale anziché usare i contratti machine-readable del Core. | L'IA si riallinea al contratto esplicito Layer C del Core. |
| **`ERR-PDA-03`** | Ha inventato stati o eventi non presenti negli alfabeti del Core. | L'IA rimuove i nomi inventati. |
| **`ERR-PDA-04`** | Ha dimenticato di mettere il tag `@derived_from: CORE-ID` sopra una funzione. | L'IA aggiunge il tag di tracciabilità. |
| **`ERR-PDA-05`** | Ha provato a inventare una regola non scritta nel Core. | L'IA emette `REQUEST_CLARIFICATION`. |
| **`ERR-PDA-06`** | Ha dato retta al testo descrittivo del Core invece di usare il contratto machine-readable. | L'IA applica la regola di precedenza Layer C. |
| **`ERR-PDA-07`** | Ha trattato un obbligo tassativo (`MUST`) come un avviso opzionale. | L'IA inserisce la gestione rigida dell'errore. |
| **`ERR-PDA-08`** | Nel fare refactoring ha cambiato l'output osservabile o l'ordine dei byte. | L'IA annulla l'ottimizzazione aggressiva. |
| **`ERR-PDA-09`** | Ha detto che il codice era a norma ma **ha dimenticato di generare i test**. | L'IA viene bloccata e costretta a stampare i test fisici. |

---

## 4.	🪄 FRASI MAGICHE DA USARE NEI PROMPT (Frasi d'Emergenza)

Se durante la chat l'IA sembra confusa, uscite dal seminato o si comporta in modo strano, incolla una di queste direttive per riportarla immediatamente nei binari dello SDP:

1. **Se l'IA sta inventando cose non scritte:**
   > `SDP CHECK: Execute SDP-RULE-GOV-004. Do not assume. Issue REQUEST_CLARIFICATION for missing Specs.`
2. **Se l'IA sta usando tipi sbagliati nel Kernel:**
   > `SDP CHECK: Execute SDP-RULE-T1-001. Enforce Core-defined numerical invariants.`
3. **Se l'IA non ha messo i test o i tag:**
   > `SDP CHECK: Execute ERR-PDA-04 and ERR-PDA-09. Attach @derived_from tags and unit tests.`
4. **Se vuoi costringerla a rifare l'auto-audit da capo:**
   > `SDP AUDIT: Run STAGE 8 PRE_FLIGHT_SELF_AUDIT_LOOP and emit Evidence Manifest JSON.`
