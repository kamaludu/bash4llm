**Clone locale, senza cronologia:**
```sh
git clone --depth 1 --branch release-v1.1.0 https://github.com/kamaludu/bash4llm.git repo-bash4llm
```
---

### Bash4LLM - punti essenziali:

---

#### bash4llm è uno script Bash, single-file, idempotente (funziona ovunque).


bash4llm è compatibile con ambienti Unix‑like:
- Linux
- macOS
- WSL, Cygwin (Windows)
- Termux (Android)


bash4llm richiede che i seguenti pacchetti (o equivalenti) siano disponibili nel PATH:
- bash
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

Tutti questi pacchetti vanno considerati requisiti obbligatori: se ne manca uno, bash4llm fallisce con errore chiaro.
In quanto requisiti obbligatori, nessun pacchetto richiede fallback.
Nessuna dipendenza ulteriore è consentita.


bash4llm è progettato per ambienti single‑user, come:
- pc/laptop/tablet personali
- server privati
- installazioni Termux
- ambienti WSL
- shell locali


bash4llm non è progettato per:
server multi‑tenant o ambienti ostili, dove utenti non fidati possono modificare il filesystem, sistemi dove le variabili d’ambiente possono essere manipolate da terzi, scenari che richiedono sandboxing forte o separazione dei privilegi


bash4llm assume che:
L’utente possegga e controlli le directory in cui risiedono Bash4LLM e gli extras.
Nessun utente non fidato possa scrivere nella directory contenente bash4llm
Le variabili d’ambiente siano configurazione fidata, non input non attendibile.
I provider siano codice fidato, non plugin provenienti da fonti sconosciute.


bash4llm non esegue mai le risposte API come comandi shell.
Lo script non utilizza mai eval o costrutti equivalenti.
I file temporanei interni non vengono mai creati in /tmp di sistema.


Tutti i file e le directory riguardanti Bash4LLM devono trovarsi dentro bash4llm.d/ , posizionata accanto allo script bash4llm.

---
