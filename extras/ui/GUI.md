# GroqBash⁺ GUI  

---
## 🇮🇹 Sezione Italiana
---
# Guida all’Installazione della GroqBash⁺ GUI

Questa guida descrive l’intero processo per installare e attivare la **GroqBash GUI**, sia tramite Apache (installazione automatica) sia tramite qualsiasi altro server con supporto CGI (installazione manuale).

La GUI è un extra opzionale di GroqBash e fornisce un’interfaccia web locale con backend CGI sicuro e isolato.

---
## 1. Installazione della UI (extra di GroqBash)
---

La GUI vive nella struttura standard di GroqBash:

```
groqbash/
  groqbash.d/
    extras/
      ui/
        gui-server.sh
        gui-bootstrap.sh
        templates/
        assets/
        runtime/
```

### ✔️ Installazione tramite GroqBash

Se GroqBash è già installato:

`groqbash extras install ui`

Oppure dal repository:

`./groqbash extras install ui`

Questo comando:
- posiziona la UI nella directory corretta
- prepara gli script CGI
- crea la struttura runtime
- verifica la disponibilità di groqbash

