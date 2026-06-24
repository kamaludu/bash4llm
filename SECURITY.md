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
- Ogni transazione scriva in una cartella isolata `$RUN_TMPDIR` specifica del processo.
- `$BASH4LLM_TMPDIR` debba essere una sottodirectory interna al perimetro di `$BASH4LLM_DIR`.
- I file temporanei interni siano creati esclusivamente con permessi restrittivi `700` (`umask 077`).

### ✔ Sandbox dei provider (Isolamento funzioni)
Durante il caricamento dei moduli aggiuntivi, lo script esegue l'importazione in una sotto-shell di sandbox isolata:
- Cattura un dump statico delle sole funzioni dichiarate dal modulo (tramite `declare -f`).
- Blocca l'esecuzione di codice globale arbitrario o la persistenza di variabili globali estranee nel runtime principale.
- Controlla severamente i permessi di scrittura sul filesystem dei moduli prima del caricamento (vietati file world/group-writable o directory insicure).

### ✔ Sicurezza delle API Key e sanitizzazione dell'ambiente
- Le chiavi di autenticazione vengono caricate temporaneamente in memoria per la durata dell'invocazione curl e non vengono **mai persistite o scritte su disco**.
- Lo script verifica la presenza e la validità delle chiavi per ciascun provider prima di avviare richieste, bloccando preventivamente i tentativi non autorizzati con il codice di errore `BASH4LLM_ERR_NO_API_KEY`.
- L'espansione dinamica delle variabili sotto `set -u` (nounset) è protetta e sanitizzata, impedendo arresti anomali dovuti a query indirette vuote (es. `${!prov_env}`).

### ✔ Gestione dei Lock concorrenti e compatibilità Termux
- Per evitare collisioni di scrittura nella cronologia o nella cronologia dei messaggi NDJSON, lo script implementa un sistema centrale di lock.
- **Risoluzione Termux:** Sotto ambiente Android/Termux, l'utility nativa `flock` (e il locking su file descriptor a livello kernel) può causare arresti e congelamenti indefiniti. Bash4LLM⁺ rileva automaticamente l'ambiente Termux (tramite `TERMUX_VERSION`) disattivando in trasparenza l'uso di `flock` e deviando la logica di locking sul robusto meccanismo atomico di directory lock (`mkdir`).

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

## 7. Responsible Disclosure

- Si prega di non aprire pubblicamente issue su GitHub per segnalare vulnerabilità di sicurezza non ancora risolte.
- Si consiglia di coordinare la pubblicazione dei dettagli solo a seguito del rilascio di un fix correttivo ufficiale.

---

## 8. Extras di sicurezza inclusi

Bash4LLM⁺ include strumenti opzionali dedicati alla verifica della sicurezza in `extras/security/`:

- `verify.sh` — Controlla l'integrità, la firma crittografica e i permessi dei file dei provider caricabili.
- `validate-env.sh` — Verifica che l'ambiente e il filesystem in cui risiede lo script core soddisfino tutti i requisiti di sicurezza descritti in questa policy.

---

## 9. Note finali

Bash4LLM⁺ è progettato con una forte attenzione alla sicurezza complessiva, ma rimane uno script operante all'interno dei limiti intrinseci di Bash. L'utente deve comprendere tali assunzioni e applicare le migliori pratiche locali prima di eseguirlo in contesti di produzione sensibili.
