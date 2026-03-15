
[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](README.md)

# SECURITY POLICY  🇮🇹 [🇬🇧](SECURITY-en.md)

# GroqBash⁺ — Politica di Sicurezza

GroqBash è uno script Bash singolo progettato con forte attenzione a **sicurezza**, **portabilità** e **trasparenza**.  
Questo documento descrive il **modello di minaccia**, le **assunzioni di sicurezza**, le **limitazioni note**, le **raccomandazioni** e il processo di **responsible disclosure**.

---

# 1. Versioni supportate

GroqBash segue un modello di supporto semplice:

| Versione | Stato |
|----------|--------|
| **1.0.0+** | Supportata, riceve aggiornamenti di sicurezza |
| < 1.0.0 | Non supportata |

Solo l’ultima release stabile riceve fix di sicurezza.

---

# 2. Modello di minaccia

GroqBash è progettato per ambienti **single‑user**, come:

- laptop personali  
- server privati  
- installazioni Termux  
- ambienti WSL  
- shell locali di sviluppo  

GroqBash **non** è progettato per:

- server multi‑tenant o ostili  
- ambienti dove utenti non fidati possono modificare il filesystem  
- sistemi dove le variabili d’ambiente possono essere manipolate da terzi  
- scenari che richiedono sandboxing forte o separazione dei privilegi  

## Assunzioni fondamentali

GroqBash assume che:

- L’utente **possegga** e **controlli** le directory in cui risiedono GroqBash e gli extras.  
- Nessun utente non fidato possa scrivere in:
  - `$GROQBASHEXTRASDIR`
  - `$GROQBASHTMPDIR`
  - la directory contenente `groqbash`
- Le variabili d’ambiente siano **configurazione fidata**, non input non attendibile.
- I provider siano **codice fidato**, non plugin provenienti da fonti sconosciute.

---

# 3. Principi di sicurezza

## ✔ Nessuna esecuzione dell’output del modello  
GroqBash **non esegue mai** le risposte API come comandi shell.

## ✔ Nessun `eval`  
Lo script non utilizza `eval` o costrutti equivalenti.

## ✔ Nessun uso di `/tmp`  
I file temporanei interni **non** vengono mai creati in `/tmp`.  
GroqBash usa:

- `$GROQBASHTMPDIR` (se impostato)  
- un fallback sicuro nella home dell’utente  

I temporanei sono creati con:

- `mktemp -d`  
- permessi `700`

## ✔ Hardened provider loading  
Prima di eseguire un provider, GroqBash verifica:

- esistenza del file  
- che sia un file regolare  
- che non sia un symlink  
- che il proprietario coincida con l’utente corrente  
- assenza di permessi di scrittura per gruppo/mondo  
- directory non world‑writable  
- mitigazione TOCTOU tramite controlli pre/post  

## ✔ Nessun fallback nascosto  
Se la lista modelli è vuota, GroqBash fallisce in modo sicuro.

## ✔ Dipendenze minime  
Solo strumenti Unix standard sono richiesti.  
Strumenti opzionali (`jq`, `python3`) migliorano la robustezza ma non sono obbligatori.

---

# 4. Limitazioni note

GroqBash è uno script Bash, non un runtime sandboxato.

## ⚠ Rischi TOCTOU residui  
Bash non può eliminare completamente i race condition.

## ⚠ I provider sono codice  
Gli script in `extras/providers/` vengono **eseguiti nella shell**.  
Devono essere:

- di tua proprietà  
- non scrivibili da altri  
- conservati in directory fidate  

## ⚠ Le variabili d’ambiente sono considerate fidate  
Esempi:

- `GROQBASHEXTRASDIR`
- `GROQBASHTMPDIR`
- `GROQ_API_KEY`
- `GROQ_MODEL`

## ⚠ Parsing JSON/SSE best‑effort  
Basato su `sed`/`awk`/`grep`.  
Robusto, ma non equivalente a un parser completo.

## ⚠ Nessun isolamento multi‑utente  
GroqBash non tenta di isolarsi da altri utenti sullo stesso sistema.

---

# 5. Raccomandazioni per un uso sicuro

## ✔ Conserva GroqBash in una directory di tua proprietà

`CODEON
mkdir -p "$HOME/.local/bin"
CODEOFF`

## ✔ Mantieni sicure le directory degli extras

`CODEON
chmod 700 "$GROQBASHEXTRASDIR"
chmod -R go-w "$GROQBASHEXTRASDIR"
CODEOFF`

## ✔ Installa provider solo da fonti fidate  
I provider sono script shell eseguiti direttamente.

## ✔ Evita ambienti condivisi o ostili  
GroqBash non è progettato per server multi‑tenant.

## ✔ Usa `--debug` solo in ambienti sicuri  
La modalità debug conserva file temporanei potenzialmente sensibili.

---

# 6. Segnalazione vulnerabilità

Se scopri un problema di sicurezza, segnalalo **privatamente**.

### Contatto (disclosure privata)
- **Email:** opensource​@​cevangel.​anonaddy.​me  
- **Oggetto:** `[GroqBash Security Report]`

Includi:

- descrizione chiara del problema  
- passi per riprodurlo  
- dettagli sull’ambiente (OS, Bash, Termux/macOS/etc.)  
- impatto potenziale (esecuzione codice, escalation, esposizione dati)

Tempo di risposta tipico: **entro 72 ore**.

---

# 7. Responsible Disclosure

- Non aprire issue pubblici per vulnerabilità.  
- Non pubblicare dettagli prima della fix.  
- La disclosure coordinata è apprezzata.  
- Il riconoscimento pubblico è opzionale.

---

# 8. Extras di sicurezza

GroqBash include strumenti opzionali in `extras/security/`:

- `verify.sh` — controlla integrità provider  
- `validate-env.sh` — verifica sicurezza ambiente  

Non modificano il comportamento del core.

---

# 9. Note finali

GroqBash è costruito con forte attenzione alla sicurezza, ma resta uno script Bash.  
L’utente deve comprendere le sue assunzioni e limitazioni prima di usarlo in ambienti sensibili.

Documentazione completa:

- **[README](README.md)**  
- **[INSTALL](INSTALL.md)**  
- **[CHANGELOG](CHANGELOG.md)**
