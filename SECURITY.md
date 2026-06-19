[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

## SECURITY POLICY  🇮🇹 [🇬🇧](SECURITY-en.md)

## Bash4LLM⁺ — Politica di Sicurezza

Bash4LLM è uno script Bash singolo progettato con forte attenzione a **sicurezza**, **portabilità** e **trasparenza**.  
Questo documento descrive il **modello di minaccia**, le **assunzioni di sicurezza**, le **limitazioni note**, le **raccomandazioni** e il processo di **responsible disclosure**.

---

## 1. Versioni supportate

Solo l’ultima release stabile riceve fix di sicurezza.

---

## 2. Modello di minaccia

Bash4LLM è progettato per ambienti **single‑user**, come:

- PC/laptop personali  
- server privati  
- installazioni Termux  
- ambienti WSL  
- shell locali di sviluppo  

Bash4LLM **non** è progettato per:

- server multi‑tenant o ostili  
- ambienti dove utenti non fidati possono modificare il filesystem  
- sistemi dove le variabili d’ambiente possono essere manipolate da terzi  
- scenari che richiedono sandboxing forte o separazione dei privilegi  

### Assunzioni fondamentali

Bash4LLM assume che:

- L’utente **possegga** e **controlli** le directory in cui risiedono Bash4LLM e gli extras.  
- Nessun utente non fidato possa scrivere in:
  - `$BASH4LLMEXTRASDIR`
  - `$BASH4LLMTMPDIR`
  - la directory contenente `bash4llm`
- Le variabili d’ambiente siano **configurazione fidata**, non input non attendibile.
- I provider siano **codice fidato**, non plugin provenienti da fonti sconosciute.

---

## 3. Principi di sicurezza

### ✔ Nessuna esecuzione dell’output del modello  
Bash4LLM **non esegue mai** le risposte API come comandi shell.

### ✔ Nessun `eval`  
Lo script non utilizza `eval` o costrutti equivalenti.

### ✔ Nessun uso di `/tmp`  
I file temporanei interni **non** vengono mai creati in `/tmp`.  
Bash4LLM usa:

- `$BASH4LLMTMPDIR` (se impostato)  
- un fallback sicuro nella home dell’utente  

I temporanei sono creati con:

- `mktemp -d`  
- permessi `700`

### ✔ Nessun fallback nascosto  
Se la lista modelli è vuota, Bash4LLM fallisce in modo sicuro.

### Sicurezza del provider:
verifica che il provider definisca funzioni richieste
(buildpayload_<p>, call_api_<p>, ecc.)

### Sicurezza API key
Il codice verifica:
presenza API key per refresh modelli, presenza API key per chiamate API, errori chiari: `BASH4LLMERRNOAPIKEY`

### Sicurezza modello
Il codice verifica:
modello valido tramite `validate_model_core`, modello ammesso tramite `ALLOWED_MODELS`

### Sicurezza input
Il codice gestisce:
`JSON_INPUT`, `FILE_INPUTS`, `TEMPLATE`, `STDIN_CONTENT`

### Sicurezza sessioni
Il codice:
crea directory sessioni con `mkdir -p|, imposta permessi 700, usa file JSON per history

### Sicurezza tmpdir
Il codice:
usa `BASH4LLM_TMPDIR`, fallisce se non scrivibile, NON usa `/tmp` di sistema 

---

## 4. Limitazioni note

Bash4LLM è uno script Bash, non un runtime sandboxato.

### ⚠ Rischi TOCTOU residui  
Bash non può eliminare completamente i race condition.

### ⚠ I provider sono codice  
Gli script in `extras/providers/` vengono **eseguiti nella shell**.  
Devono essere:

- di tua proprietà  
- non scrivibili da altri  
- conservati in directory fidate  

### ⚠ Le variabili d’ambiente sono considerate fidate  
Esempi:

- `BASH4LLMEXTRASDIR`
- `BASH4LLMTMPDIR`
- `GROQ_API_KEY`
- `GROQ_MODEL`

### ⚠ Nessun isolamento multi‑utente  
Bash4LLM non tenta di isolarsi da altri utenti sullo stesso sistema.

---

## 5. Raccomandazioni per un uso sicuro

### ✔ Conserva Bash4LLM in una directory di tua proprietà

`CODEON
mkdir -p "$HOME/.local/bin"
CODEOFF`

### ✔ Mantieni sicure le directory degli extras

`CODEON
chmod 700 "$BASH4LLMEXTRASDIR"
chmod -R go-w "$BASH4LLMEXTRASDIR"
CODEOFF`

### ✔ Installa provider solo da fonti fidate  
I provider sono script shell eseguiti direttamente.

### ✔ Evita ambienti condivisi o ostili  
Bash4LLM non è progettato per server multi‑tenant.

### ✔ Usa `--debug` solo in ambienti sicuri  
La modalità debug conserva file temporanei potenzialmente sensibili.

---

## 6. Segnalazione vulnerabilità

Se scopri un problema di sicurezza, segnalalo **privatamente**.

#### Contatto (disclosure privata)
- **Email:** opensource​@​cevangel.​anonaddy.​me  
- **Oggetto:** `[Bash4LLM Security Report]`

Includi:

- descrizione chiara del problema  
- passi per riprodurlo  
- dettagli sull’ambiente (OS, Bash, Termux/macOS/etc.)  
- impatto potenziale (esecuzione codice, escalation, esposizione dati)

Tempo di risposta tipico: **entro 72 ore**.

---

## 7. Responsible Disclosure

- Non aprire issue pubblici per vulnerabilità.  
- Non pubblicare dettagli prima della fix.  
- La disclosure coordinata è apprezzata.  
- Il riconoscimento pubblico è opzionale.

---

## 8. Extras di sicurezza

Bash4LLM include strumenti opzionali in `extras/security/`:

- `verify.sh` — controlla integrità provider  
- `validate-env.sh` — verifica sicurezza ambiente  

Non modificano il comportamento del core.

---

## 9. Note finali

Bash4LLM è costruito con forte attenzione alla sicurezza, ma resta uno script Bash.  
L’utente deve comprendere le sue assunzioni e limitazioni prima di usarlo in ambienti sensibili.

Documentazione completa:

- **[README](README.md)**  
- **[INSTALL](INSTALL.md)**  
- **[CHANGELOG](CHANGELOG.md)**
