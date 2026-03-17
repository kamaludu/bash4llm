# GroqBash⁺ GUI   🇮🇹 [🇬🇧](#-english-section)
---
## 🇮🇹 Sezione Italiana
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

---
## 2. Attivazione della GUI in modalità CGI
---

La GUI può essere attivata in due modi:

1. **Installazione automatica su Apache** (consigliata)  
2. **Installazione manuale su qualsiasi server CGI**

---
## 2.1 Installazione automatica su Apache
---

Lo script `groqbash-gui-install.sh`:
- rileva automaticamente la UI
- rileva la configurazione di Apache tramite `apachectl -V`
- trova una directory di configurazione realmente inclusa
- genera `groqbash-gui.conf`
- abilita ScriptSock e CGI
- esegue `configtest`
- ricarica Apache

### ✔️ Esecuzione

`extras/ui/groqbash-gui-install.sh`

Oppure:

`groqbash gui install`

### ✔️ Risultato

Lo script mostra un riepilogo simile:

```
APP_ROOT: /path/to/project
APACHE_CONF: /etc/apache2/conf.d/groqbash-gui.conf
PORT: 19970
URL: http://localhost:19970/groqbash-gui/cgi
```

Apri il browser e visita l’URL indicato.

---
## 2.2 Installazione manuale su qualsiasi server CGI
---

Funziona con:
- lighttpd
- nginx + fcgiwrap
- busybox httpd
- thttpd
- server embedded
- container minimalisti

### ✔️ Requisiti minimi
- Supporto CGI
- Possibilità di eseguire script `.sh` come CGI
- Permessi di esecuzione nella directory della UI

### ✔️ Passi

#### 1. Individua lo script CGI principale

`APP_BIN/groqbash/groqbash.d/extras/ui/gui-server.sh`

#### 2. Configura il server

Esempio generico:

```
ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh
Alias /groqbash-gui/static /path/to/ui
```

#### 3. Rendi eseguibili gli script

`chmod 755 gui-server.sh gui-bootstrap.sh`

#### 4. Proteggi le directory runtime

`chmod 700 runtime runtime/cgid`

#### 5. Riavvia il server

#### 6. Apri nel browser:

`http://localhost:<PORT>/groqbash-gui/cgi`

---
## 3. Aggiornamento della GUI
---

`groqbash extras update ui`

Poi, se usi Apache:

`extras/ui/groqbash-gui-install.sh`

---
## 4. Rimozione della GUI
---

### ✔️ Rimozione UI

`groqbash extras remove ui`

### ✔️ Rimozione configurazione Apache

Elimina:

`/path/to/apache/conf.d/groqbash-gui.conf`

Poi:

`apachectl graceful`

---
## 5. Troubleshooting rapido
---

### ❗ La GUI non si apre
- Controlla che Apache ascolti sulla porta indicata
- Controlla che mod_cgi o mod_cgid siano attivi
- Controlla i permessi:
  - `chmod 755 gui-server.sh`
  - `chmod 700 runtime runtime/cgid`

### ❗ Errore 500
- Controlla i log Apache
- Verifica groqbash:
  - `extras/ui/gui-bootstrap.sh`

### ❗ Porta occupata
Lo script lo rileva automaticamente.

---
## 🇬🇧 English Section
# GroqBash GUI Installation Guide

This guide explains how to install and activate the **GroqBash GUI**, either through Apache (automatic installation) or any CGI-capable server (manual installation).

The GUI is an optional GroqBash extra providing a local web interface with a secure CGI backend.

---
## 1. Installing the UI (GroqBash extra)
---

The GUI lives inside the standard GroqBash structure:

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

### ✔️ Install via GroqBash

If GroqBash is installed:

`groqbash extras install ui`

Or from the repository:

`./groqbash extras install ui`

This command:
- places the UI in the correct directory
- prepares the CGI scripts
- creates runtime directories
- verifies groqbash availability

---
## 2. Activating the GUI in CGI mode
---

Two activation methods:

1. **Automatic Apache installation** (recommended)  
2. **Manual installation on any CGI server**

---
## 2.1 Automatic Apache installation
---

The script `groqbash-gui-install.sh`:
- auto-detects the UI
- reads Apache configuration via `apachectl -V`
- finds an actually included config directory
- generates `groqbash-gui.conf`
- enables ScriptSock and CGI
- runs `configtest`
- reloads Apache

### ✔️ Run it

`extras/ui/groqbash-gui-install.sh`

Or:

`groqbash gui install`

### ✔️ Result

You will see something like:

```
APP_ROOT: /path/to/project
APACHE_CONF: /etc/apache2/conf.d/groqbash-gui.conf
PORT: 19970
URL: http://localhost:19970/groqbash-gui/cgi
```

Open the URL in your browser.

---
## 2.2 Manual installation on any CGI server
---

Works with:
- lighttpd
- nginx + fcgiwrap
- busybox httpd
- thttpd
- embedded servers
- minimal containers

### ✔️ Requirements
- CGI support
- Ability to execute `.sh` scripts as CGI
- Proper execution permissions

### ✔️ Steps

#### 1. Locate the CGI script

`APP_BIN/groqbash/groqbash.d/extras/ui/gui-server.sh`

#### 2. Configure your server

Generic example:

```
ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh
Alias /groqbash-gui/static /path/to/ui
```

#### 3. Make scripts executable

`chmod 755 gui-server.sh gui-bootstrap.sh`

#### 4. Secure runtime directories

`chmod 700 runtime runtime/cgid`

#### 5. Restart your server

#### 6. Open in browser:

`http://localhost:<PORT>/groqbash-gui/cgi`

---
## 3. Updating the GUI
---

`groqbash extras update ui`

Then, if using Apache:

`extras/ui/groqbash-gui-install.sh`

---
## 4. Removing the GUI
---

### ✔️ Remove UI

`groqbash extras remove ui`

### ✔️ Remove Apache config

Delete:

`/path/to/apache/conf.d/groqbash-gui.conf`

Then:

`apachectl graceful`

---
## 5. Quick Troubleshooting
---

### ❗ GUI not loading
- Check Apache is listening on the configured port
- Ensure mod_cgi or mod_cgid is enabled
- Check permissions:
  - `chmod 755 gui-server.sh`
  - `chmod 700 runtime runtime/cgid`

### ❗ 500 Internal Server Error
- Check Apache logs
- Verify groqbash:
  - `extras/ui/gui-bootstrap.sh`

### ❗ Port already in use
The installer detects this automatically.

---
# Fine / End
---
