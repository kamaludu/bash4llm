### GroqBash - punti essenziali:

---

#### groqbash è uno script Bash, single-file, idempotente (funziona ovunque).


groqbash è compatibile con ambienti Unix‑like:
- Linux
- macOS
- WSL, Cygwin (Windows)
- Termux (Android)


groqbash richiede che i seguenti pacchetti (o equivalenti) siano disponibili nel PATH:
- bash
- coreutils
- findutils
- util-linux
- gawk
- curl
- jq

Tutti questi pacchetti vanno considerati requisiti obbligatori: se ne manca uno, groqbash fallisce von errore chiaro.
In quanto requisiti obbligatori, nessun pacchetto richiede fallback.
Nessuna dipendenza ulteriore è consentita.


groqbash è progettato per ambienti single‑user, come:
pc/laptop/tablet personali
server privati
installazioni Termux
ambienti WSL
shell locali


groqbash non è progettato per:
server multi‑tenant o ambienti ostili, dove utenti non fidati possono modificare il filesystem, sistemi dove le variabili d’ambiente possono essere manipolate da terzi, scenari che richiedono sandboxing forte o separazione dei privilegi


groqbash assume che:
L’utente possegga e controlli le directory in cui risiedono GroqBash e gli extras.
Nessun utente non fidato possa scrivere nella directory contenente groqbash
Le variabili d’ambiente siano configurazione fidata, non input non attendibile.
I provider siano codice fidato, non plugin provenienti da fonti sconosciute.


groqbash non esegue mai le risposte API come comandi shell.
Lo script non utilizza mai eval o costrutti equivalenti.
I file temporanei interni non vengono mai creati in /tmp di sistema.


Tutti i file e le directory riguardanti GroqBash devono trovarsi dentro groqbash.d/ , posizionata accanto allo script groqbash.

---
