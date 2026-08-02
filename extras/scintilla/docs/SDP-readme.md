**[Scintilla Development Protocol](SDP-PDA.md)**

# Usare ✴ Scintilla Development Protocol (SDP v1.1.0)
**Guida Operativa Umana**

Lo SDP è uno **"Agent Constraint Layer"**: una gabbia normativa che controlla **il comportamento dell'Intelligenza Artificiale**, non il modo in cui tu le parli.

Quando tu scrivi una richiesta in italiano (es. *"Crea il modulo per gestire la transizione dello stato dell'utente in Rust"*), l'IA esegue automaticamente questo processo interno:

1. **Legge la tua richiesta in italiano.**
2. **Attiva il ciclo SDP (`SDP-OPERATIONAL-CYCLE`):** traduce la tua intenzione nei vincoli semantici di SCINTILLA Core v4.5.5 (`CORE-ID`).
3. **Applica i controlli SDP:** verifica di non usare `float` in T1, impone l'aritmetica intera $I_{safe}$ ed i Basis Points $[0, 10000]$, applica la serializzazione SC-JCS-1, impone funzioni pure e genera i test di verifica.
4. **Ti restituisce il codice, i test e il manifesto JSON in modo perfettamente conforme.**

---

### Da ricordare quando scrivi in italiano

Puoi usare qualsiasi parola, stile o forma espressiva, **a patto di non chiedere esplicitamente all'IA di violare SCINTILLA Core v4.5.5**.

* 🟢 **PROMPT VALIDO (Italiano normale):**  
  *"Sviluppa la funzione che calcola l'indice di avanzamento dell'utente in TypeScript."*  
  $\to$ **Risposta IA:** `PROPOSE_ARTIFACT` (Genera codice TypeScript sicuro con interi $I_{safe}$, Basis Points $[0, 10000]$, tag `@derived_from` e unit test).

* 🔴 **PROMPT CHE ATTIVA IL BLOCCO (Violazione esplicita):**  
  *"Crea la funzione usando numeri con la virgola (float) per velocizzare i calcoli."*  
  $\to$ **Risposta IA:** `REFUSE` (L'IA ti blocca immediatamente perché la regola `SDP-RULE-T1-001` le vieta i `float` nel Kernel).

---

## 1. ARCHITETTURA DI CARICAMENTO NEL CONTEXT WINDOW

Quando avvii una sessione di sviluppo, il contesto fornito all'LLM (via API, IDE o interfaccia web) deve seguire tassativamente questa **stratificazione gerarchica**:

```text
+-------------------------------------------------------------------------------+
| 1. SYSTEM PROMPT / CONTEXT HEADER                                             |
|    Inietta il testo integrale di SDP v1.1.0                                   |
|    (Funge da "Operating System" comportamentale dell'Agente)                  |
+-------------------------------------------------------------------------------+
| 2. NORMATIVE DOMAIN REFERENCE                                                 |
|    Carica il file della specifica canonica SCINTILLA Core v4.5.5               |
|    (Funge da "Single Source of Truth" di Dominio di sola lettura)             |
+-------------------------------------------------------------------------------+
| 3. TASK PROMPT (INPUT DELL'UTENTE)                                            |
|    Inserisci la richiesta specifica (es. "Sviluppa il modulo T1 per...")      |
+-------------------------------------------------------------------------------+
```

---

## 2. INTEGRABILITÀ CON STRUMENTI ED IDE AI

SDP v1.1.0 è formattato per essere integrato direttamente negli strumenti di sviluppo moderni:

* **Cursor / Windsurf IDE:**
  Copia il testo di SDP v1.1.0 all'interno del file `.cursorrules` o `.windsurfrules` nella radice del repository di progetto.
* **GitHub Copilot / VS Code:**
  Copia il testo di SDP v1.1.0 in `.github/copilot-instructions.md`.
* **Claude Projects / ChatGPT Custom GPTs:**
  Inserisci il testo di SDP v1.1.0 nel campo **"System Instructions"** o **"Project Knowledge"**.
* **Integrazione via API (OpenAI, Anthropic, Ollama, LangChain):**
  Passa il testo dello SDP v1.1.0 nel parametro `system` delle chiamate API.

---

## 3. COME INTERAGIRE CON I SEGNALI DI OUTPUT DELL'AGENTE

Durante lo sviluppo, l'Agente AI risponderà emettendo uno dei tre segnali normativi definiti nello SDP. Ecco come la componente umana deve reagire a ciascun segnale:

### A) Se l'Agente emette `PROPOSE_ARTIFACT`:
L'Agente ha generato il codice, i test e l'Evidence Manifest associato.
* **Azione Umana:** Verifica che il blocco di unit test allegato passi e approva l'integrazione del codice.

### B) Se l'Agente emette `REQUEST_CLARIFICATION`:
L'Agente ha rilevato che il prompt utente è ambiguo, oppure che la specifica SCINTILLA Core v4.5.5 nel contesto è incompleta/troncata (regola `SDP-RULE-GOV-003` Branch A).
* **Azione Umana:** Fornisci la sezione mancante di SCINTILLA Core o chiarisci i requisiti del task. **Non chiedere all'Agente di tirare a indovinare**, perché la regola `SDP-RULE-GOV-004` gli vieta di farlo.

### C) Se l'Agente emette `REFUSE`:
L'Agente rifiuta l'esecuzione perché la richiesta tenta di violare un vincolo inderogabile di SCINTILLA Core v4.5.5 (es. uso di float in T1, scavalco del consenso umano) o una regola di sicurezza.
* **Azione Umana:** Modifica la richiesta o il design del software per riallinearti alle regole del Core. Non insistere: l'Agente ha il divieto di accedere a negoziazioni se il prompt viola la SSOT.

---

## 4. AUTOMAZIONE DELLA VERIFICA (CI/CD E HOOKS)

Poiché SDP v1.1.0 impone all'Agente di generare sempre un blocco JSON `Evidence Manifest` (Annesso A.1) unitamente al codice, puoi automatizzare il controllo di qualità nel tuo repository:

1. **Pre-commit Hook / CI Pipeline Script:**
   Scrivi uno script automatizzato (in Python, Node.js o Bash) che estrae il blocco JSON `Evidence Manifest` dal messaggio o dalla pull request generata dall'AI.
2. **Validazione dello Schema:**
   Valida il manifesto contro lo schema JSON `EVIDENCE_MANIFEST_OUTPUT_SCHEMA` (Annesso A.1 di SDP).
3. **Esito:**
   Se il manifesto è valido e il campo `pre_flight_audit_results` attesta che tutti i controlli `ERR-PDA-01..09` sono `PASSED`, la PR viene contrassegnata come **idonea per la review umana**.

---

# 📑 CHEAT SHEET OPERATIVO PER L'UMANO (SDP v1.1.0)
**Guida Tascabile di Pronto Soccorso**. Per interagire con qualsiasi IA senza dover mai rileggere lo SDP.

## 1. I 3 SEGNALI PRINCIPALI (Cosa ti risponderà l'IA?)

Ogni volta che fai una richiesta di codice, l'IA risponderà con un header contenente uno di questi segnali:

### 🟢 `PROPOSE_ARTIFACT` (Tutto OK)
* **Cosa significa:** L'IA ha generato il codice, ha superato l'auto-audit pre-flight ed è sicura che rispetti SCINTILLA Core v4.5.5.
* **Cosa devi fare tu:**
  1. Prendi il codice.
  2. Esegui il blocco di unit test allegato.
  3. Controlla che le funzioni abbiano il tag `@derived_from: CORE-ID`.
  4. Integra il codice nel repository.

---

### 🟡 `REQUEST_CLARIFICATION` (Informazione Mancante)
* **Cosa significa:** L'IA si è bloccata perché il tuo prompt è ambiguo oppure perché la specifica di SCINTILLA Core v4.5.5 che ha nel contesto è troncata o incompleta.
* **Cosa devi fare tu:**
  1. **NON dire all'IA "prova a indovinare"** (lo SDP glielo vieta).
  2. Leggi quale `CORE-ID` o dettaglio ti sta chiedendo.
  3. Incolla nel prompt il testo di SCINTILLA Core v4.5.5 mancante o chiarisci il dettaglio.

---

### 🔴 `REFUSE` (Richiesta Vietata / Illegale)
* **Cosa significa:** L'IA rifiuta la tua richiesta perché le hai chiesto una cosa che viola SCINTILLA Core v4.5.5 (es. usare i `float` nel Kernel T1, bypassare la funzione `MapSMLToFSMEvent` o ignorare il consenso utente) oppure un'operazione vietata (es. approvare una release).
* **Cosa devi fare tu:**
  1. Non insistere e non provare a ingannare l'IA.
  2. Riconfigura la tua richiesta di codice rispettando i vincoli di SCINTILLA Core.

---

### ⚠️ CASI SPECIALI RARI:
* **`HALT (CORE_CONTEXT_INVALID)`:** L'IA dice che la specifica di SCINTILLA Core caricata è corrotta o contraddittoria. $\to$ *Ricarica il file SCINTILLA Core v4.5.5 pulito*.
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
* **A cosa serve:** Raccoglie tutti gli hash dei singoli *Evidence Manifest* e dimostra a terzi/auditor che l'intero software è stato sviluppato in totale conformità a SCINTILLA Core v4.5.5.

---

## 3. 🚨 TABELLA CODICI DI ERRORE PRE-FLIGHT (`ERR-PDA-01..09`)

*Nota:* I codici `ERR-PDA-xx` indicano controlli interni di auto-audit dell'IA. Non vanno confusi con i **Runtime Error Codes (70–89)** emessi dal software generato in fase di esecuzione.

| Codice Errore | Cosa ha sbagliato l'IA? | Come risolverlo |
| :--- | :--- | :--- |
| **`ERR-PDA-01`** | Ha usato tipi non conformi (es. `float`/`double`), numeri fuori dall'intervallo $I_{safe}$ o percentuali non scalate in Basis Points $[0, 10000]$. | L'IA corregge da sola convertendo in interi sicuri, Basis Points e divisione intera $\lfloor \dots \rfloor$. |
| **`ERR-PDA-02`** | Ha scritto logica condizionale personalizzata anziché usare i contratti machine-readable del Core (Cap. 10). | L'IA si riallinea al contratto esplicito Layer C del Core. |
| **`ERR-PDA-03`** | Ha inventato stati o eventi non presenti negli alfabeti del Core ($Q, Q_H, \Sigma, \Sigma_H$). | L'IA rimuove gli identificatori inventati. |
| **`ERR-PDA-04`** | Ha dimenticato di mettere il tag `@derived_from: CORE-ID` sopra una funzione o modulo. | L'IA aggiunge il tag di tracciabilità. |
| **`ERR-PDA-05`** | Ha provato a inventare una regola non scritta nel Core v4.5.5. | L'IA emette `REQUEST_CLARIFICATION`. |
| **`ERR-PDA-06`** | Ha dato retta al testo descrittivo (Layer B) invece di usare il contratto machine-readable (Layer C). | L'IA applica la regola di precedenza `RULE-NORMATIVE-PRECEDENCE-01`. |
| **`ERR-PDA-07`** | Ha trattato un obbligo tassativo (`MUST`/`SHALL`) come un avviso opzionale. | L'IA inserisce la gestione rigida dell'errore. |
| **`ERR-PDA-08`** | Nel fare refactoring ha cambiato l'output osservabile o l'ordine dei byte canonici SC-JCS-1. | L'IA annulla l'ottimizzazione aggressiva. |
| **`ERR-PDA-09`** | Ha detto che il codice era a norma ma **ha dimenticato di generare i test di verifica**. | L'IA viene bloccata e costretta a stampare il blocco di unit test fisici. |

---

## 4. 🪄 FRASI MAGICHE DA USARE NEI PROMPT (Frasi d'Emergenza)

Se durante la chat l'IA sembra confusa, esce dal seminato o si comporta in modo strano, incolla una di queste direttive per riportarla immediatamente nei binari dello SDP v1.1.0:

1. **Se l'IA sta inventando cose non scritte:**
   > `SDP CHECK: Execute SDP-RULE-GOV-004. Do not assume. Issue REQUEST_CLARIFICATION for missing Specs.`
2. **Se l'IA sta usando tipi o numeri sbagliati nel Kernel (T1):**
   > `SDP CHECK: Execute SDP-RULE-T1-001. Enforce I_safe limits [-9007199254740991, +9007199254740991] and Basis Points [0, 10000]. No floats allowed.`
3. **Se l'IA non rispetta la canonizzazione o la serializzazione:**
   > `SDP CHECK: Execute SDP-RULE-T1-003. Enforce SC-JCS-1 profile (UnicodeCodePointLex key sorting and SetSemanticsRegistry deep sorting).`
4. **Se l'IA sbaglia le transizioni degli automi FSM:**
   > `SDP CHECK: Execute SDP-RULE-T1-004. Enforce 4-tier Resolve(q, σ) precedence and reflexivity on target wildcard '*'.`
5. **Se l'IA non ha messo i test o i tag:**
   > `SDP CHECK: Execute ERR-PDA-04 and ERR-PDA-09. Attach @derived_from tags and physical unit tests.`
6. **Se vuoi costringerla a rifare l'auto-audit da capo:**
   > `SDP AUDIT: Run STAGE 8 PRE_FLIGHT_SELF_AUDIT_LOOP and emit Evidence Manifest JSON.`
