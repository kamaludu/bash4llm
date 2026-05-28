[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

## SECURITY POLICY  🇮🇹 [🇬🇧](SECURITY-en.md)

## GroqBash⁺ — Politica di Sicurezza

GroqBash è uno script Bash singolo progettato con forte attenzione a **sicurezza**, **portabilità** e **trasparenza**.  
Questo documento descrive il **modello di minaccia**, le **assunzioni di sicurezza**, le **limitazioni note**, le **raccomandazioni** e il processo di **responsible disclosure**.

---

## 1. Versioni supportate

Solo l’ultima release stabile riceve fix di sicurezza.

---

## 2. Modello di minaccia

GroqBash è progettato per ambienti **single‑user**, come:

- PC/laptop personali  
- server privati  
- installazioni Termux  
- ambienti WSL  
- shell locali di sviluppo  

GroqBash **non** è progettato per:

- server multi‑tenant o ostili  
- ambienti dove utenti non fidati possono modificare il filesystem  
- sistemi dove le variabili d’ambiente possono essere manipolate da terzi  
- scenari che richiedono sandboxing forte o separazione dei privilegi  

### Assunzioni fondamentali

GroqBash assume che:

- L’utente **possegga** e **controlli** le directory in cui risiedono GroqBash e gli extras.  
- Nessun utente non fidato possa scrivere in:
  - `$GROQBASHEXTRASDIR`
  - `$GROQBASHTMPDIR`
  - la directory contenente `groqbash`
- Le variabili d’ambiente siano **configurazione fidata**, non input non attendibile.
- I provider siano **codice fidato**, non plugin provenienti da fonti sconosciute.

---

## 3. Principi di sicurezza

### ✔ Nessuna esecuzione dell’output del modello  
GroqBash **non esegue mai** le risposte API come comandi shell.

### ✔ Nessun `eval`  
Lo script non utilizza `eval` o costrutti equivalenti.

### ✔ Nessun uso di `/tmp`  
I file temporanei interni **non** vengono mai creati in `/tmp`.  
GroqBash usa:

- `$GROQBASHTMPDIR` (se impostato)  
- un fallback sicuro nella home dell’utente  

I temporanei sono creati con:

- `mktemp -d`  
- permessi `700`

### ✔ Nessun fallback nascosto  
Se la lista modelli è vuota, GroqBash fallisce in modo sicuro.

### Sicurezza del provider:
verifica che il provider definisca funzioni richieste
(buildpayload_<p>, call_api_<p>, ecc.)

### Sicurezza API key
Il codice verifica:
presenza API key per refresh modelli, presenza API key per chiamate API, errori chiari: `GROQBASHERRNOAPIKEY`

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
usa `GROQBASH_TMPDIR`, fallisce se non scrivibile, NON usa `/tmp` di sistema 

---

## 4. Limitazioni note

GroqBash è uno script Bash, non un runtime sandboxato.

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

- `GROQBASHEXTRASDIR`
- `GROQBASHTMPDIR`
- `GROQ_API_KEY`
- `GROQ_MODEL`

### ⚠ Nessun isolamento multi‑utente  
GroqBash non tenta di isolarsi da altri utenti sullo stesso sistema.

---

## 5. Raccomandazioni per un uso sicuro

### ✔ Conserva GroqBash in una directory di tua proprietà

`CODEON
mkdir -p "$HOME/.local/bin"
CODEOFF`

### ✔ Mantieni sicure le directory degli extras

`CODEON
chmod 700 "$GROQBASHEXTRASDIR"
chmod -R go-w "$GROQBASHEXTRASDIR"
CODEOFF`

### ✔ Installa provider solo da fonti fidate  
I provider sono script shell eseguiti direttamente.

### ✔ Evita ambienti condivisi o ostili  
GroqBash non è progettato per server multi‑tenant.

### ✔ Usa `--debug` solo in ambienti sicuri  
La modalità debug conserva file temporanei potenzialmente sensibili.

---

## 6. Segnalazione vulnerabilità

Se scopri un problema di sicurezza, segnalalo **privatamente**.

#### Contatto (disclosure privata)
- **Email:** opensource​@​cevangel.​anonaddy.​me  
- **Oggetto:** `[GroqBash Security Report]`

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

GroqBash include strumenti opzionali in `extras/security/`:

- `verify.sh` — controlla integrità provider  
- `validate-env.sh` — verifica sicurezza ambiente  

Non modificano il comportamento del core.

---

## 9. Note finali

GroqBash è costruito con forte attenzione alla sicurezza, ma resta uno script Bash.  
L’utente deve comprendere le sue assunzioni e limitazioni prima di usarlo in ambienti sensibili.

Documentazione completa:

- **[README](README.md)**  
- **[INSTALL](INSTALL.md)**  
- **[CHANGELOG](CHANGELOG.md)**
