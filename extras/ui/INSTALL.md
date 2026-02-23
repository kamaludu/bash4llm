[![GroqBash GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 🇮🇹🇬🇧

## 🇮🇹 INSTALLAZIONE DELLA GUI DI GROQBASH

## 🧩 Panoramica
Questo documento descrive come installare e configurare la GUI HTML di GroqBash su diversi web server:
- BusyBox httpd (consigliato per semplicità e portabilità)
- Apache
- Nginx (con fcgiwrap)
- Lighttpd

Include inoltre note di sicurezza, test e suggerimenti per la produzione.

---

## 🟦 A) Installazione con BusyBox (consigliata)

BusyBox include un webserver CGI integrato: `httpd`. È la soluzione più semplice, portabile e leggera.

### 1. Installare BusyBox

Debian/Ubuntu:
```sh
sudo apt install busybox
```

Alpine:
```sh
sudo apk add busybox
```

### 2. Creare la directory del webserver
```sh
sudo mkdir -p /var/www/groqbash-ui/cgi-bin
```

### 3. Copiare la GUI
```sh
sudo cp -r extras/ui/* /var/www/groqbash-ui/
sudo cp extras/ui/gui-server.sh /var/www/groqbash-ui/cgi-bin/
sudo chmod +x /var/www/groqbash-ui/cgi-bin/gui-server.sh
```

### 4. Avviare il webserver
```sh
sudo busybox httpd -f -p 8080 -h /var/www/groqbash-ui
```

### 5. Aprire nel browser
```
http://localhost:8080/cgi-bin/gui-server.sh
```
---

## 🤖📱 Installazione su Termux (Android)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](#) [![Termux](https://img.shields.io/badge/Termux-000000?logo=gnu-bash&logoColor=white)](#)

Questa sezione descrive come installare e avviare la GUI di GroqBash ***su Android utilizzando Termux e BusyBox***.  
L’installazione è semplice e non richiede permessi di root.

### 🟦 1. Requisiti

- Termux installato da F-Droid
- BusyBox disponibile in Termux
- GroqBash installato correttamente (che crea la directory: `$PREFIX/groqbash.d`)

Installa BusyBox se necessario:
```sh
pkg install busybox
```


### 🟩 2. Posizionamento corretto della GUI

La GUI deve essere installata **dentro l’albero degli extras di GroqBash**, cioè:

```
$PREFIX/groqbash.d/extras/ui/
```

Crea la struttura:
```sh
mkdir -p $PREFIX/groqbash.d/extras/ui/cgi-bin
```

Copia i file della GUI:
```sh
cp -r extras/ui/* $PREFIX/groqbash.d/extras/ui/
cp extras/ui/gui-server.sh $PREFIX/groqbash.d/extras/ui/cgi-bin/
chmod +x $PREFIX/groqbash.d/extras/ui/cgi-bin/gui-server.sh
```
***Struttura delle directory:***
```sh
$PREFIX/groqbash.d/extras/ui/
    gui-style-light.css
    gui-style-dark.css
    gui-lang.conf
    templates/
    assets/ (opzionale)

    cgi-bin/
        gui-server.sh   ← QUI
```

### 🟧 3. Avvio del web
server BusyBox

Avvia BusyBox httpd puntando alla directory della GUI:

```sh
busybox httpd -f -p 8080 -h $PREFIX/groqbash.d/extras/ui
```

- `-f` = foreground (utile per debug)
- `-p 8080` = porta
- `-h` = document root


### 🟨 4. Apertura della GUI nel browser Android

Apri Chrome/Firefox e visita:

```
http://127.0.0.1:8080/cgi-bin/gui-server.sh
```

Funziona anche:

```
http://localhost:8080/cgi-bin/gui-server.sh
```


### 🟪 5. Note importanti per Termux

- Non usare `sudo` (non esiste in Termux)
- Non usare percorsi come `/var/www`
- Tutto deve vivere sotto `$PREFIX/groqbash.d/extras/ui`
- Le directory: config/, logs/, tmp/, conversations/, files/ vengono create automaticamente

---

## 🟩 B) Configurazione Apache

### 1. Abilitare CGI
```sh
sudo a2enmod cgi
sudo systemctl restart apache2
```

### 2. Configurare VirtualHost

File: `/etc/apache2/sites-available/groqbash.conf`

```apache
<VirtualHost *:80>
    ServerName groqbash.local
    DocumentRoot /var/www/groqbash-ui

    ScriptAlias /cgi-bin/ /var/www/groqbash-ui/cgi-bin/
    <Directory "/var/www/groqbash-ui/cgi-bin/">
        Options +ExecCGI
        AddHandler cgi-script .sh
        Require all granted
    </Directory>
</VirtualHost>
```

### 3. Attivare il sito
```sh
sudo a2ensite groqbash
sudo systemctl reload apache2
```

---

## 🟧 C) Configurazione Nginx (con fcgiwrap)

Nginx non supporta CGI nativamente: serve `fcgiwrap`.

### 1. Installare fcgiwrap
```sh
sudo apt install fcgiwrap
sudo systemctl enable --now fcgiwrap
```

### 2. Configurare Nginx

File: `/etc/nginx/sites-available/groqbash`

```nginx
server {
    listen 80;
    server_name groqbash.local;

    root /var/www/groqbash-ui;

    location /cgi-bin/ {
        gzip off;
        fastcgi_pass unix:/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/groqbash-ui$fastcgi_script_name;
    }
}
```

### 3. Attivare il sito
```sh
sudo ln -s /etc/nginx/sites-available/groqbash /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

---

## 🟨 D) Configurazione Lighttpd

### 1. Abilitare mod_cgi
```sh
sudo lighttpd-enable-mod cgi
sudo systemctl restart lighttpd
```

### 2. Configurare CGI

File: `/etc/lighttpd/lighttpd.conf`

```conf
cgi.assign = (
    ".sh" => "/bin/bash"
)

alias.url += (
    "/cgi-bin/" => "/var/www/groqbash-ui/cgi-bin/"
)
```

---

## 🟪 E) Note di sicurezza

- Nessun uso di `/tmp` di sistema (la GUI usa `tmp/` locale con permessi restrittivi)
- Tutte le scritture sono atomiche (atomic_write)
- Lock globale tramite `flock` per evitare race condition
- Sanitizzazione completa dei parametri in ingresso
- Permessi consigliati:
  ```sh
  chmod 700 config conversations files logs tmp
  ```

---

## 🟫 F) Test dell’installazione

### 1. Verifica CGI
```sh
curl http://localhost/cgi-bin/gui-server.sh
```

### 2. Verifica log
```sh
tail -f /var/www/groqbash-ui/logs/server.log
tail -f /var/www/groqbash-ui/logs/errors.log
```

### 3. Verifica conversazioni
```sh
ls /var/www/groqbash-ui/conversations/
```

---

## 🇬🇧 INSTALLATION GUIDE FOR GROQBASH GUI

### 🧩 Overview
This document explains how to install and configure the GroqBash HTML GUI on:
- BusyBox httpd
- Apache
- Nginx (with fcgiwrap)
- Lighttpd

It also includes security notes and testing instructions.

---

## 🟦 A) BusyBox Installation (recommended)

BusyBox httpd is the simplest and most portable CGI server.

### 1. Install BusyBox

Debian/Ubuntu:
```sh
sudo apt install busybox
```

Alpine:
```sh
sudo apk add busybox
```

### 2. Create server directory
```sh
sudo mkdir -p /var/www/groqbash-ui/cgi-bin
```

### 3. Copy GUI files
```sh
sudo cp -r extras/ui/* /var/www/groqbash-ui/
sudo cp extras/ui/gui-server.sh /var/www/groqbash-ui/cgi-bin/
sudo chmod +x /var/www/groqbash-ui/cgi-bin/gui-server.sh
```

### 4. Start the server
```sh
sudo busybox httpd -f -p 8080 -h /var/www/groqbash-ui
```

### 5. Open in browser
```
http://localhost:8080/cgi-bin/gui-server.sh
```
---

## 🤖📱 Installation on Termux (Android)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](#) [![Termux](https://img.shields.io/badge/Termux-000000?logo=gnu-bash&logoColor=white)](#)

This section explains how to install and run the GroqBash GUI ***on Android using Termux and BusyBox***.  
No root access is required.

### 🟦 1. Requirements

- Termux installed from F-Droid
- BusyBox available in Termux
- GroqBash installed (which creates: `$PREFIX/groqbash.d`)

Install BusyBox if needed:
```sh
pkg install busybox
```


### 🟩 2. Correct GUI placement

The GUI must be installed **inside GroqBash’s extras tree**, here:

```
$PREFIX/groqbash.d/extras/ui/
```

Create the structure:
```sh
mkdir -p $PREFIX/groqbash.d/extras/ui/cgi-bin
```

Copy GUI files:
```sh
cp -r extras/ui/* $PREFIX/groqbash.d/extras/ui/
cp extras/ui/gui-server.sh $PREFIX/groqbash.d/extras/ui/cgi-bin/
chmod +x $PREFIX/groqbash.d/extras/ui/cgi-bin/gui-server.sh
```
***Directory structure:***
```sh
$PREFIX/groqbash.d/extras/ui/
    gui-style-light.css
    gui-style-dark.css
    gui-lang.conf
    templates/
    assets/ (opzionale)

    cgi-bin/
        gui-server.sh   ← HERE
```

### 🟧 3. Start BusyBox webserver

Run BusyBox httpd pointing to the GUI directory:

```sh
busybox httpd -f -p 8080 -h $PREFIX/groqbash.d/extras/ui
```


### 🟨 4. Open the GUI in Android browser

Open Chrome/Firefox and visit:

```
http://127.0.0.1:8080/cgi-bin/gui-server.sh
```

Alternatively:

```
http://localhost:8080/cgi-bin/gui-server.sh
```


### 🟪 5. Important notes for Termux

- Do not use `sudo`
- Do not use `/var/www`
- Everything must live under `$PREFIX/groqbash.d/extras/ui`
- Directories like config/, logs/, tmp/, conversations/, files/ are auto‑created by the GUI

---

## 🟩 B) Apache Configuration

### 1. Enable CGI
```sh
sudo a2enmod cgi
sudo systemctl restart apache2
```

### 2. VirtualHost configuration

File: `/etc/apache2/sites-available/groqbash.conf`

```apache
<VirtualHost *:80>
    ServerName groqbash.local
    DocumentRoot /var/www/groqbash-ui

    ScriptAlias /cgi-bin/ /var/www/groqbash-ui/cgi-bin/
    <Directory "/var/www/groqbash-ui/cgi-bin/">
        Options +ExecCGI
        AddHandler cgi-script .sh
        Require all granted
    </Directory>
</VirtualHost>
```

### 3. Enable site
```sh
sudo a2ensite groqbash
sudo systemctl reload apache2
```

---

## 🟧 C) Nginx Configuration (requires fcgiwrap)

### 1. Install fcgiwrap
```sh
sudo apt install fcgiwrap
sudo systemctl enable --now fcgiwrap
```

### 2. Configure Nginx

File: `/etc/nginx/sites-available/groqbash`

```nginx
server {
    listen 80;
    server_name groqbash.local;

    root /var/www/groqbash-ui;

    location /cgi-bin/ {
        gzip off;
        fastcgi_pass unix:/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/groqbash-ui$fastcgi_script_name;
    }
}
```

### 3. Enable site
```sh
sudo ln -s /etc/nginx/sites-available/groqbash /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

---

## 🟨 D) Lighttpd Configuration

### 1. Enable CGI
```sh
sudo lighttpd-enable-mod cgi
sudo systemctl restart lighttpd
```

### 2. Configure CGI

File: `/etc/lighttpd/lighttpd.conf`

```conf
cgi.assign = (
    ".sh" => "/bin/bash"
)

alias.url += (
    "/cgi-bin/" => "/var/www/groqbash-ui/cgi-bin/"
)
```

---

## 🟪 E) Security Notes

- No system `/tmp` usage (local `tmp/` directory with strict permissions)
- All writes are atomic (atomic_write)
- Global lock via `flock` to prevent race conditions
- Full input sanitization
- Recommended permissions:
  ```sh
  chmod 700 config conversations files logs tmp
  ```

---

## 🟫 F) Testing

### 1. CGI test
```sh
curl http://localhost/cgi-bin/gui-server.sh
```

### 2. Logs
```sh
tail -f logs/server.log
tail -f logs/errors.log
```

### 3. Conversations
```sh
ls conversations/
```
