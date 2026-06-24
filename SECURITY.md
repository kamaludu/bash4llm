[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

## SECURITY POLICY  🇮🇹 [🇬🇧](SECURITY-en.md)

## Bash4LLM⁺ — Politica di Sicurezza

Bash4LLM⁺ è uno script Bash singolo progettato con una forte attenzione a **sicurezza**, **portabilità**, **trasparenza** ed **estendibilità**.  
Questo documento descrive il **modello di minaccia**, le **assunzioni di sicurezza**, le **limitazioni note**, le **raccomandazioni** e il processo di **responsible disclosure**.

---

## 1. Versioni supportate

Solo l’ultima release stabile riceve correzioni e patch di sicurezza.

---

## 2. Modello di minaccia

Bash4LLM⁺ è progettato per ambienti **single-user**, come:

- PC/laptop personali  
- server privati  
- installazioni Termux (Android)  
- ambienti WSL (Windows Subsystem for Linux)  
- shell locali di sviluppo  

Bash4LLM⁺ **non** è progettato per:

- server multi-tenant o ostili  
- ambienti in cui utenti non fidati hanno permessi di scrittura sul filesystem  
- sistemi in cui le variabili d’ambiente possono essere manipolate da terzi non fidati  
- scenari che richiedono sandboxing forte a livello kernel o separazione rigida dei privilegi di sistema  

### Assunzioni fondamentali

Bash4LLM⁺ assume che:

- L’utente **possegga** e **controlli** le directory in cui risiedono Bash4LLM⁺ e i file degli extras.  
- Nessun utente non fidato possa scrivere nelle directory configurate, incluse:
  - `$BASH4LLM_EXTRAS_DIR`
  - `$BASH4LLM_TMPDIR`
  - la directory contenente l'eseguibile principale `bash4llm`
- Le variabili d’ambiente siano considerabili **configurazione fidata** e non input malevolo non attendibile.
- I provider aggiuntivi siano **codice fidato**, provenienti da fonti verificate e non scaricati ciecamente o gestiti in modo insicuro.

---

## 3. Principi di sicurezza e mitigazioni implementate

### ✔ Nessuna esecuzione dell’output del modello  
Bash4LLM⁺ si limita a stampare e salvare i testi generati dal modello. **Non esegue mai** le risposte API come comandi shell o script, neutralizzando alla radice rischi di esecuzione remota di codice (RCE) derivanti da prompt injection.

### ✔ Nessun `eval`  
Lo script core e i moduli ufficiali non utilizzano mai il comando `eval` o costrutti equivalenti suscettibili di code injection.

### ✔ Protezione del File System e divieto di `/tmp` di sistema  
Per evitare minacce basate su collegamenti simbolici (symlink) o collisioni di scrittura ad opera di utenti concorrenti sul sistema, i file temporanei interni **non** vengono mai creati nella directory globale `/tmp`.  
Bash4LLM⁺ impone che:
- Ogni transazione scriva in una cartella isolata `$RUN_TMPDIR` generata dinamicamente con umask `077` e permessi `700` (esclusivi per l'utente proprietario).
- La directory temporanea base `$BASH4LLM_TMPDIR` risieda obbligatoriamente all'interno del perimetro della cartella principale `$BASH4LLM_DIR`.
- Lo script rilevi e blocchi immediatamente l'esecuzione se la directory temporanea configurata si trova in `/tmp` o sotto `/tmp`, o se è un collegamento simbolico.

### ✔ Caricamento isolato dei provider (Sandbox statico)
Per proteggere il runtime da script di terze parti instabili o dannosi:
- La funzione `load_provider_module` esegue una pre-analisi statica in una sotto-shell isolata prima di importare il codice.
- Viene creato un dump sicuro e temporaneo contenente **esclusivamente le definizioni delle funzioni** (tramite `declare -f`).
- Eventuale codice arbitrario o dichiarazioni di variabili globali posizionate fuori dalle funzioni nel file del provider vengono scartate e non inquineranno in nessun modo la shell principale.
- Vengono controllati severamente la proprietà del file del provider (che deve coincidere con l'utente corrente) e i permessi di scrittura del gruppo o del mondo (world/group-writable), bloccando il caricamento in caso di violazioni.

### ✔ Gestione robusta dei lock concorrenti (Termux Friendly)
Per prevenire conflitti o file corrotti durante l'uso parallelo (multi-istanza) della stessa sessione di chat, Bash4LLM⁺ implementa un sistema di lock centralizzato.
- **Risoluzione blocchi Termux:** Sui sistemi Android/Termux, a causa di limitazioni strutturali della libreria C Bionic e delle politiche di sicurezza SELinux di Android, l'uso dell'utility di sistema `flock` (e delle relative chiamate di sistema BSD) causa spesso congelamenti o blocchi indefiniti del terminale.
- **Mitigazione:** Bash4LLM⁺ rileva automaticamente l'ambiente Termux (tramite `TERMUX_VERSION`) e disattiva in modo trasparente l'uso di `flock`, deviando l'esecuzione su un meccanismo atomico alternativo basato sulla creazione di directory (`mkdir`). Questo garantisce la massima stabilità e portabilità in totale assenza di blocchi.

### ✔ Sicurezza delle API Key e sanitizzazione dell'ambiente
- Le chiavi di autenticazione vengono lette rigorosamente da variabili d'ambiente (o richieste interattivamente se in TTY) e memorizzate unicamente in memoria volatile per la durata dell'esecuzione della chiamata. **Nessuna chiave viene mai scritta sul filesystem.**
- L'ambiente non-interattivo fallisce in modo sicuro senza mostrare prompt di inserimento se la chiave API non è già presente nelle variabili d'ambiente.
- La sanitizzazione dinamica dell'espansione indiretta delle variabili (`${!prov_env}`) assicura che, in caso di variabili vuote sotto `set -u` (nounset), lo script non incorra in arresti anomali o errori di sintassi.

### ✔ Sicurezza dei file di sessione e cronologia
La cronologia di chat viene memorizzata in formato NDJSON protetto, accessibile esclusivamente con permessi restrittivi `600` nella directory `$BASH4LLM_HISTORY_DIR/sessions`, con rimozione atomica e sicura tramite rotazione dei file automatica e configurabile (`rotate_history`).

---

## 4. Limitazioni note

Bash4LLM⁺ è uno script Bash, non un runtime di sistema sandboxato o un container isolato a livello kernel.

### ⚠ Rischi TOCTOU (Time-of-Check to Time-of-Use)  
Nonostante l'uso di scritture atomiche (tramite la sotto-funzione `atomic_write`), Bash non può eliminare teoricamente e completamente le race condition a livello di filesystem se un utente malintenzionato locale ha già accesso in scrittura alle directory di configurazione con privilegi elevati.

### ⚠ I provider sono codice eseguibile  
Gli script caricati in `extras/providers/` sono, a tutti gli effetti, codice Bash eseguito nella tua shell. Devono provenire esclusivamente da fonti fidate ed essere protetti da permessi di scrittura non autorizzati sul filesystem.

### ⚠ Le variabili d’ambiente sono considerate configurazione fidata  
Parametri critici come `BASH4LLM_EXTRAS_DIR`, `BASH4LLM_TMPDIR` e `GROQ_API_KEY` sono considerati fidati. Se un attaccante locale riesce a manipolare l'ambiente prima dell'esecuzione dello script, potrebbe deviare i percorsi di scrittura.

---

## 5. Raccomandazioni per un uso sicuro

### ✔ Conserva Bash4LLM⁺ in una directory privata di tua proprietà
Si raccomanda di non installare lo script in percorsi di sistema condivisibili (`/tmp`, `/var/tmp`, o directory globali con permessi laschi) se il sistema è condiviso con altri utenti. Installa lo script nella tua cartella utente locale:
```sh
mkdir -p "$HOME/.local/bin"
cp bash4llm "$HOME/.local/bin/"
chmod 700 "$HOME/.local/bin/bash4llm"
```

### ✔ Mantieni protette le directory degli extras e delle configurazioni
Applica permessi restrittivi alle cartelle di runtime:
```sh
chmod 700 "$BASH4LLM_DIR"
chmod 700 "$BASH4LLM_EXTRAS_DIR"
chmod 700 "$BASH4LLM_CONFIG_DIR"
```

### ✔ Non usare `--debug` in ambienti di produzione o esposti
La modalità debug conserva file temporanei e file raw di risposta (`resp.raw`, `curl.err`) che potrebbero contenere metadati sensibili o frammenti di chiavi se stampati accidentalmente a schermo o memorizzati nei log.

---

## 6. Segnalazione di vulnerabilità (Responsible Disclosure)

Se si scopre una potenziale vulnerabilità di sicurezza all'interno di Bash4LLM⁺, si prega di effettuare una segnalazione in modo **riservato e privato** per proteggere gli utenti.

#### Contatto per disclosure privata:
- **Email:** opensource​@​cevangel.​anonaddy.​me  
- **Oggetto:** `[Bash4LLM Security Report]`

Si prega di includere nella segnalazione:
- Una descrizione chiara e dettagliata della potenziale vulnerabilità.
- I passaggi completi o uno script di Proof of Concept (PoC) per riprodurla.
- Dettagli sull’ambiente di esecuzione (OS, versione di Bash, uso di Termux/WSL/macOS).
- L'impatto potenziale stimato.

Il tempo di risposta garantito per l'analisi iniziale è **entro 72 ore**.

---

## 7. Extras di sicurezza inclusi

Bash4LLM⁺ include strumenti opzionali dedicati alla verifica della sicurezza in `extras/security/`:

- `verify.sh` — Controlla l'integrità, la firma crittografica e i permessi dei file dei provider caricabili.
- `validate-env.sh` — Verifica che l'ambiente e il filesystem in cui risiede lo script core soddisfino tutti i requisiti di sicurezza descritti in questa policy.
