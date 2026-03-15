[![GroqBash GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 🇮🇹 [🇬🇧](#installation-guide-for-groqbash-gui)

# 🇮🇹 INSTALLAZIONE DELLA GUI DI GROQBASH

## 🧩 Panoramica
Questo documento descrive come installare e configurare la GUI HTML di GroqBash su diversi web server:
- BusyBox httpd (consigliato per semplicità e portabilità)
- Apache (con installer automatico)
- Nginx (con fcgiwrap)
- Lighttpd

Include inoltre note di sicurezza, test e suggerimenti per la produzione.

---

# 📦 STRUTTURA DELLA UI (AGGIORNATA)

```sh
ui/
  groqbash-gui-install.sh
  gui-server.sh          ← entrypoint CGI
  gui-bootstrap.sh       ← bootstrap portabile (ambiente, percorsi, atomic_write, lock, ecc.)
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css

  templates/
    header.html
    content.html
    footer.html
    settings-header.html
    settings-content.html

  conversations/         ← creato automaticamente
  files/
      input/             ← creato automaticamente
      output/            ← creato automaticamente

  config/                ← creato automaticamente
      current-conversation
      lang-current
      default-model
      default-provider
      gui-theme

  logs/                  ← creato automaticamente
      server.log
      errors.log

  tmp/                   ← creato automaticamente
      (file temporanei, lock, atomic_write)

  assets/                ← creato automaticamente (vuoto)
```

---

# 🟦 A) Installazione con BusyBox (consigliata)

BusyBox include un webserver CGI integrato: `httpd`.  
È la soluzione più semplice, portabile e leggera.

## 1. Installare BusyBox

Debian/Ubuntu:
```sh
sudo apt install busybox
```

Alpine:
```sh
sudo apk add busybox
```

## 2. Creare la directory del webserver
```sh
sudo mkdir -p /var/www/groqbash-ui/cgi-bin
```

## 3. Copiare la GUI
```sh
sudo cp -r extras/ui/* /var/www/groqbash-ui/
sudo cp extras/ui/gui-server.sh /var/www/groqbash-ui/cgi-bin/
sudo chmod +x /var/www/groqbash-ui/cgi-bin/gui-server.sh
```

## 4. Avviare il webserver
```sh
sudo busybox httpd -f -p 8080 -h /var/www/groqbash-ui
```

## 5. Aprire nel browser
```
http://localhost:8080/cgi-bin/gui-server.sh
```

---

# 🤖📱 Installazione su Termux (Android)

Questa sezione descrive come installare e avviare la GUI di GroqBash ***su Android utilizzando Termux e BusyBox***.  
Non richiede root.

## 1. Requisiti

- Termux installato da F-Droid  
- BusyBox installato in Termux  
- GroqBash installato (che crea: `$PREFIX/groqbash.d`)

Installa BusyBox:
```sh
pkg install busybox
```

## 2. Posizionamento corretto della GUI

La GUI deve essere installata **dentro l’albero degli extras di GroqBash**, cioè:

```
$PREFIX/groqbash.d/extras/ui/
```

Crea la struttura:
```sh
mkdir -p $PREFIX/groqbash.d/extras/ui/cgi-bin
```

Copia i file:
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
    assets/

    cgi-bin/
        gui-server.sh   ← QUI
```

## 3. Avvio del web server BusyBox

```sh
busybox httpd -f -p 8080 -h $PREFIX/groqbash.d/extras/ui
```

## 4. Apertura della GUI nel browser Android

```
http://127.0.0.1:8080/cgi-bin/gui-server.sh
```

---

# 🟩 B) Installazione automatica su Apache (consigliata)

La GUI include un installer dedicato:

```
ui/groqbash-gui-install.sh
```

Questo script:

- rileva automaticamente Apache  
- determina la directory corretta per i file .conf  
- crea un VirtualHost dedicato  
- configura CGI e statici  
- applica i permessi minimi  
- garantisce idempotenza  
- **non copia la UI** (Apache punta alla directory reale)  

## 1. Esecuzione

```sh
cd groqbash/groqbash.d/extras/ui
chmod +x groqbash-gui-install.sh
./groqbash-gui-install.sh
```

## 2. Apertura della GUI

```
http://localhost:19970/groqbash-gui/cgi
```

---

# 🟧 C) Configurazione manuale Apache (senza installer)

## 1. Abilitare CGI
```sh
sudo a2enmod cgi
sudo systemctl restart apache2
```

## 2. VirtualHost di esempio

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

## 3. Attivare il sito
```sh
sudo a2ensite groqbash
sudo systemctl reload apache2
```

---

# 🟧 D) Configurazione Nginx (con fcgiwrap)

Nginx non supporta CGI nativamente: serve `fcgiwrap`.

## 1. Installare fcgiwrap
```sh
sudo apt install fcgiwrap
sudo systemctl enable --now fcgiwrap
```

## 2. Configurare Nginx

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

## 3. Attivare il sito
```sh
sudo ln -s /etc/nginx/sites-available/groqbash /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

---

# 🟨 E) Configurazione Lighttpd

## 1. Abilitare mod_cgi
```sh
sudo lighttpd-enable-mod cgi
sudo systemctl restart lighttpd
```

## 2. Configurare CGI

```conf
cgi.assign = (
    ".sh" => "/bin/bash"
)

alias.url += (
    "/cgi-bin/" => "/var/www/groqbash-ui/cgi-bin/"
)
```

---

# 🟪 F) Note di sicurezza

- Nessun uso di `/tmp` di sistema  
- Tutte le scritture sono atomiche (atomic_write)  
- Lock globale tramite `flock`  
- Sanitizzazione completa dei parametri  
- Permessi consigliati:
```sh
chmod 700 config conversations files logs tmp
```

---

# 🟫 G) Test dell’installazione

## 1. Verifica CGI
```sh
curl http://localhost/cgi-bin/gui-server.sh
```

## 2. Verifica log
```sh
tail -f logs/server.log
tail -f logs/errors.log
```

## 3. Verifica conversazioni
```sh
ls conversations/
```

---

# 🇬🇧 INSTALLATION GUIDE FOR GROQBASH GUI

## 🧩 Overview
This document explains how to install and configure the GroqBash HTML GUI on:
- BusyBox httpd
- Apache (with automatic installer)
- Nginx (with fcgiwrap)
- Lighttpd

It also includes security notes and testing instructions.

---

# (English section preserved identically to original, updated where needed)

## 🟦 BusyBox Installation (recommended)

```sh
sudo apt install busybox
sudo mkdir -p /var/www/groqbash-ui/cgi-bin
sudo cp -r extras/ui/* /var/www/groqbash-ui/
sudo cp extras/ui/gui-server.sh /var/www/groqbash-ui/cgi-bin/
sudo chmod +x /var/www/groqbash-ui/cgi-bin/gui-server.sh
sudo busybox httpd -f -p 8080 -h /var/www/groqbash-ui
```

Open:
```
http://localhost:8080/cgi-bin/gui-server.sh
```

---

## 🤖📱 Termux Installation

```sh
pkg install busybox
mkdir -p $PREFIX/groqbash.d/extras/ui/cgi-bin
cp -r extras/ui/* $PREFIX/groqbash.d/extras/ui/
cp extras/ui/gui-server.sh $PREFIX/groqbash.d/extras/ui/cgi-bin/
chmod +x $PREFIX/groqbash.d/extras/ui/cgi-bin/gui-server.sh
busybox httpd -f -p 8080 -h $PREFIX/groqbash.d/extras/ui
```

Open:
```
http://127.0.0.1:8080/cgi-bin/gui-server.sh
```

---

## 🟩 Apache (automatic installer)

```sh
cd groqbash/groqbash.d/extras/ui
chmod +x groqbash-gui-install.sh
./groqbash-gui-install.sh
```

Open:
```
http://localhost:19970/groqbash-gui/cgi
```

---

## 🟧 Nginx (fcgiwrap)

```nginx
location /cgi-bin/ {
    fastcgi_pass unix:/run/fcgiwrap.socket;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME /var/www/groqbash-ui$fastcgi_script_name;
}
```

---

## 🟨 Lighttpd

```conf
cgi.assign = ( ".sh" => "/bin/bash" )
alias.url += ( "/cgi-bin/" => "/var/www/groqbash-ui/cgi-bin/" )
```

---

## 🟪 Security Notes

- No system `/tmp`  
- Atomic writes  
- Global flock lock  
- Sanitization  

---

## 🟫 Testing

```sh
curl http://localhost/cgi-bin/gui-server.sh
tail -f logs/server.log
tail -f logs/errors.log
```
