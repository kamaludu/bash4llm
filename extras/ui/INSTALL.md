[![GroqBash GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 
# GroqBash⁺ GUI   [🇮🇹](#-sezione-italiana) [🇬🇧](#-english-section)
---
## 🇮🇹 Sezione Italiana
# Installazione della GroqBash⁺ GUI

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

## 2.2 Configurazione manuale Apache (senza installer)

Questa sezione spiega come configurare manualmente Apache per eseguire la GroqBash GUI in modalità CGI, senza usare lo script di installazione automatica.

È utile quando:
- vuoi integrare la GUI in un VirtualHost esistente
- Apache non usa directory standard
- stai lavorando in ambienti embedded o containerizzati

---
### 1. Abilitare CGI

`sudo a2enmod cgi`  
oppure:

`sudo a2enmod cgid`

Poi:

`sudo systemctl restart apache2`

---
### 2. Individuare la directory della UI

La UI si trova in:

`<APP_ROOT>/groqbash/groqbash.d/extras/ui`

Lo script CGI principale è:

`<APP_ROOT>/groqbash/groqbash.d/extras/ui/gui-server.sh`

Assicurati che sia eseguibile:

`chmod 755 gui-server.sh`

---
### 3. VirtualHost di esempio (configurazione moderna)

Questa configurazione:
- esegue direttamente `gui-server.sh` come CGI
- espone gli asset statici
- non richiede cgi-bin
- è compatibile con la struttura attuale della GUI

```
<VirtualHost *:80>
    ServerName groqbash.local

    # Directory della UI
    Alias /groqbash-gui/static /path/to/ui
    ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh

    <Directory "/path/to/ui">
        Options -Indexes -ExecCGI
        AllowOverride None
        Require all granted
    </Directory>

    <Directory "/path/to/ui">
        Options +ExecCGI
        AddHandler cgi-script .sh
        Require all granted
    </Directory>
</VirtualHost>
```

Sostituisci:
- `/path/to/ui` con il percorso reale della UI

---
### 4. Attivare il sito

`sudo a2ensite groqbash`  
`sudo systemctl reload apache2`

---
### 5. Apertura della GUI

`http://localhost/groqbash-gui/cgi`

---
## 2.3 Installazione manuale su qualsiasi server CGI
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
# Installing GroqBash⁺ GUI

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
## 2.2 Manual Apache Configuration (without installer)

This section explains how to manually configure Apache to run the GroqBash GUI in CGI mode, without using the automatic installer.

Useful when:
- integrating the GUI into an existing VirtualHost
- Apache uses non‑standard directories
- working in embedded or containerized environments

---
### 1. Enable CGI

`sudo a2enmod cgi`  
or:

`sudo a2enmod cgid`

Then:

`sudo systemctl restart apache2`

---
### 2. Locate the UI directory

The UI lives at:

`<APP_ROOT>/groqbash/groqbash.d/extras/ui`

The main CGI script is:

`<APP_ROOT>/groqbash/groqbash.d/extras/ui/gui-server.sh`

Ensure it is executable:

`chmod 755 gui-server.sh`

---
### 3. Example VirtualHost (modern configuration)

This configuration:
- executes `gui-server.sh` directly as a CGI script
- exposes static assets
- does not require cgi-bin
- matches the current GUI architecture

```
<VirtualHost *:80>
    ServerName groqbash.local

    # UI directory
    Alias /groqbash-gui/static /path/to/ui
    ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh

    <Directory "/path/to/ui">
        Options -Indexes -ExecCGI
        AllowOverride None
        Require all granted
    </Directory>

    <Directory "/path/to/ui">
        Options +ExecCGI
        AddHandler cgi-script .sh
        Require all granted
    </Directory>
</VirtualHost>
```

Replace:
- `/path/to/ui` with the actual UI path

---
### 4. Enable the site

`sudo a2ensite groqbash`  
`sudo systemctl reload apache2`

---
### 5. Open the GUI

`http://localhost/groqbash-gui/cgi`

---
## 2.3 Manual installation on any CGI server
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
