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
        static/
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

## 2.2 Installazione manuale della GroqBash GUI (senza installer)

Questa procedura è allineata alla versione aggiornata di ```groqbash-gui-install.sh```  
ed è pensata per:

- integrazione in VirtualHost esistenti  
- server non standard  
- container, embedded, chroot  
- installazioni dove NON vuoi usare l’installer automatico  

---

### 1. Abilitare CGI

Su Debian/Ubuntu:

```sh
sudo a2enmod cgi
sudo systemctl restart apache2
```

Oppure, se disponibile:

```sh
sudo a2enmod cgid
sudo systemctl restart apache2
```

---

### 2. Individuare la directory della UI

La UI vive qui:

```
<APP_ROOT>/groqbash/groqbash.d/extras/ui
```

La CGI principale è:

```
<APP_ROOT>/groqbash/groqbash.d/extras/ui/gui-server.sh
```

Rendila eseguibile:

```sh
chmod 755 gui-server.sh gui-bootstrap.sh
```

---

### 3. Permessi e traversal (obbligatori)

Apache deve poter:

- attraversare le directory fino alla UI  
- eseguire gli script  
- leggere gli asset statici  

```sh
chmod u+x <APP_ROOT>
chmod u+x <APP_ROOT>/groqbash
chmod u+x <APP_ROOT>/groqbash/groqbash.d
chmod u+x <APP_ROOT>/groqbash/groqbash.d/extras
chmod u+x <APP_ROOT>/groqbash/groqbash.d/extras/ui

find <APP_ROOT>/groqbash/groqbash.d/extras/ui -maxdepth 1 -type f -name '*.sh' -exec chmod 755 {} \;
find <APP_ROOT>/groqbash/groqbash.d/extras/ui/static -type f -exec chmod 644 {} \;
chmod 755 <APP_ROOT>/groqbash/groqbash.d/extras/ui/static
```

---

### 4. VirtualHost moderno (coerente con l’installer)

```apache
<VirtualHost *:80>
    ServerName groqbash.local

    ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh
    Alias /groqbash-gui/static /path/to/ui

    <Directory "/path/to/ui">
        Options +ExecCGI -Indexes
        AllowOverride None
        Require all granted
        AddHandler cgi-script .sh
    </Directory>

    <Directory "/path/to/ui/static">
        Options -ExecCGI -Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
```

Sostituisci:

```/path/to/ui``` → ```<APP_ROOT>/groqbash/groqbash.d/extras/ui```

---

### 5. Attivare il sito

```sh
sudo a2ensite groqbash
sudo systemctl reload apache2
```

---

### 6. Aprire la GUI

```
http://localhost/groqbash-gui/cgi
```

---

## 2.3 Installazione manuale generica (qualsiasi server CGI)

### Requisiti minimi

- Supporto CGI  
- Possibilità di eseguire ```.sh``` come CGI  
- Permessi corretti su UI_ROOT  

### Passi

### 1. Script CGI principale

```
/path/to/ui/gui-server.sh
```

### 2. Configurazione server generica

```apache
ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh
Alias /groqbash-gui/static /path/to/ui
```

### 3. Permessi

```sh
chmod 755 /path/to/ui/*.sh
chmod 644 /path/to/ui/static/*
chmod 755 /path/to/ui/static
```

### 4. Directory runtime

```sh
chmod 700 /path/to/ui/runtime
chmod 700 /path/to/ui/runtime/cgid
```

### 5. Riavvio server

### 6. Apertura GUI

```
http://localhost:<PORT>/groqbash-gui/cgi
```

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
## 2.2 Manual installation of the GroqBash GUI (without installer)

This procedure matches the updated ```groqbash-gui-install.sh```  
and is intended for:

- integrating into existing VirtualHosts  
- non‑standard Apache layouts  
- containers, embedded systems, chroot  
- setups where you do NOT want the automatic installer  

---

## 1. Enable CGI

On Debian/Ubuntu:

```sh
sudo a2enmod cgi
sudo systemctl restart apache2
```

Or, if available:

```sh
sudo a2enmod cgid
sudo systemctl restart apache2
```

---

## 2. Locate the UI directory

The UI lives here:

```
<APP_ROOT>/groqbash/groqbash.d/extras/ui
```

Main CGI script:

```
<APP_ROOT>/groqbash/groqbash.d/extras/ui/gui-server.sh
```

Make it executable:

```sh
chmod 755 gui-server.sh gui-bootstrap.sh
```

---

## 3. Permissions and traversal (mandatory)

Apache must be able to:

- traverse directories down to the UI  
- execute the scripts  
- read static assets  

```sh
chmod u+x <APP_ROOT>
chmod u+x <APP_ROOT>/groqbash
chmod u+x <APP_ROOT>/groqbash/groqbash.d
chmod u+x <APP_ROOT>/groqbash/groqbash.d/extras
chmod u+x <APP_ROOT>/groqbash/groqbash.d/extras/ui

find <APP_ROOT>/groqbash/groqbash.d/extras/ui -maxdepth 1 -type f -name '*.sh' -exec chmod 755 {} \;
find <APP_ROOT>/groqbash/groqbash.d/extras/ui/static -type f -exec chmod 644 {} \;
chmod 755 <APP_ROOT>/groqbash/groqbash.d/extras/ui/static
```

---

## 4. Modern VirtualHost (matching the installer)

```apache
<VirtualHost *:80>
    ServerName groqbash.local

    ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh
    Alias /groqbash-gui/static /path/to/ui

    <Directory "/path/to/ui">
        Options +ExecCGI -Indexes
        AllowOverride None
        Require all granted
        AddHandler cgi-script .sh
    </Directory>

    <Directory "/path/to/ui/static">
        Options -ExecCGI -Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
```

Replace:

```/path/to/ui``` → ```<APP_ROOT>/groqbash/groqbash.d/extras/ui```

---

## 5. Enable the site

```sh
sudo a2ensite groqbash
sudo systemctl reload apache2
```

---

## 6. Open the GUI

```
http://localhost/groqbash-gui/cgi
```

---

## 2.3 Generic manual installation (any CGI-capable server)

### Minimum requirements

- CGI support  
- Ability to run ```.sh``` as CGI  
- Correct permissions on UI_ROOT  

### Steps

### 1. Main CGI script

```
/path/to/ui/gui-server.sh
```

### 2. Generic server configuration

```apache
ScriptAlias /groqbash-gui/cgi /path/to/ui/gui-server.sh
Alias /groqbash-gui/static /path/to/ui
```

### 3. Permissions

```sh
chmod 755 /path/to/ui/*.sh
chmod 644 /path/to/ui/static/*
chmod 755 /path/to/ui/static
```

### 4. Runtime directories

```sh
chmod 700 /path/to/ui/runtime
chmod 700 /path/to/ui/runtime/cgid
```

### 5. Restart server

### 6. Open GUI

```
http://localhost:<PORT>/groqbash-gui/cgi
```

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
