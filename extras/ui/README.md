[![GroqBash](https://img.shields.io/badge/_GroqBash⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](../../README.md)
[![GroqBash⁺ GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 🇮🇹 [🇬🇧](#groqbash-gui-minimalist-web-interface)

# 🇮🇹 GroqBash⁺ GUI — Interfaccia Web Minimalista

## 🧩 Panoramica
Questa è la GUI HTML ufficiale di GroqBash, progettata per essere:

- completamente portabile  
- Bash‑only (nessuna dipendenza oltre a bash, coreutils, findutils, util-linux, gawk, curl, jq)  
- sicura (atomic_write, lock globale, sanitizzazione input)  
- compatibile con qualsiasi web server che supporti CGI  
- integrabile automaticamente con Apache tramite installer dedicato  

La GUI fornisce:

- Chat con GroqBash  
- Gestione conversazioni  
- Localizzazione multilingua  
- Temi chiaro/scuro  
- Gestione file (input/output)  
- Configurazioni persistenti  

---

## 📁 Struttura delle directory

``text
ui/
  gui-server.sh          ← entrypoint CGI
  gui-bootstrap.sh       ← bootstrap portabile (ambiente, percorsi, atomic_write, lock, ecc.)
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css
  groqbash-tui.sh
  README.md
  INSTALL.md

  templates/
    header.html
    content.html
    footer.html
    settings-header.html
    settings-content.html

  conversations/         ← creato automaticamente
      conv-001.txt
      conv-002.txt

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
``

---

## ⚙️ Architettura

### gui-server.sh  
È l’unico script eseguito dal web server.  
Contiene la logica applicativa:

- routing GET/POST  
- rendering template  
- gestione conversazioni  
- chiamate a GroqBash  
- sanitizzazione input  

### gui-bootstrap.sh  
Gestisce l’ambiente di runtime:

- rilevamento UI_ROOT  
- creazione directory runtime  
- atomic_write / atomic_append_conv  
- mktemp portabile  
- lock globale tramite flock  
- logging  
- HTTP header  
- risoluzione GROQBASH_CMD  
- configurazioni di default  

---

## 🚀 Installazione

### ✔ Installazione su Apache (consigliata)
Usa l’installa script ufficiale:

``sh
./groqbash-gui-install.sh
``

L’installer:

- rileva automaticamente Apache  
- crea un VirtualHost dedicato  
- configura CGI e statici  
- applica i permessi corretti  
- garantisce idempotenza  
- non copia la UI: Apache punta alla directory reale  

Dopo l’installazione, apri:

``
http://localhost:19970/groqbash-gui/cgi
``

---

### ✔ Installazione generica su altri web server CGI
1. Assicurati che il server supporti CGI.  
2. Rendi eseguibile lo script:

``sh
chmod +x ui/gui-server.sh
``

3. Configura il server per eseguire gui-server.sh come CGI.  
4. Apri nel browser l’URL configurato.

---

## 🌐 Localizzazione

La localizzazione è definita in:

- gui-lang.conf

Ogni chiave può avere:

- una versione globale  
- una versione specifica per lingua (es. KEY.en=, KEY.it=)

Esempio:

TXT_TITLE.en=GroqBash Web UI  
TXT_TITLE.it=Interfaccia Web GroqBash

---

## 🎨 Temi

La GUI supporta:

- light  
- dark  

Il tema selezionato viene salvato in:

- config/gui-theme

---

## 🔒 Sicurezza

- Nessun uso di `eval`  
- Nessun uso di `/tmp` di sistema  
- Tutte le scritture usano atomic_write  
- Lock globale tramite flock  
- Sanitizzazione completa dei parametri  
- Nessuna esecuzione di comandi arbitrari  
- Permessi minimi applicati automaticamente dall’installer  

---

## 🧪 Requisiti

- bash  
- coreutils  
- findutils  
- util-linux  
- gawk  
- curl  
- jq  
- un web server con CGI abilitato  
- GroqBash installato nel PATH (o percorso configurato)  

---

## 🛠️ Debug

Log disponibili in:

- logs/server.log  
- logs/errors.log  

---

# GroqBash⁺ GUI Minimalist Web Interface

## 🇬🇧 🧩 Overview
This is the official HTML GUI for GroqBash, designed to be:

- fully portable  
- Bash‑only (no dependencies beyond bash, coreutils, findutils, util-linux, gawk, curl, jq)  
- secure (atomic writes, global lock, input sanitization)  
- compatible with any CGI‑capable web server  
- automatically integrable with Apache via dedicated installer  

The GUI provides:

- Chat with GroqBash  
- Conversation management  
- Multi‑language localization  
- Light/Dark themes  
- File handling  
- Persistent configuration  

---

## 📁 Directory Structure

``text
ui/
  gui-server.sh
  gui-bootstrap.sh
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css
  groqbash-tui.sh
  README.md
  INSTALL.md
  templates/
  conversations/
  files/
  config/
  logs/
  tmp/
  assets/
``

---

## 🚀 Installation

### Apache (recommended)
``sh
./groqbash-gui-install.sh
``

Then open:

``
http://localhost:19970/groqbash-gui/cgi
``

### Generic CGI servers
``sh
chmod +x ui/gui-server.sh
``

Configure your server to run gui-server.sh as CGI.

---

## 🌐 Localization
Defined in gui-lang.conf.

---

## 🎨 Themes
Stored in config/gui-theme.

---

## 🔒 Security
- No `eval`  
- No system `/tmp`  
- Atomic writes  
- Global flock lock  
- Full sanitization  

---

## 🧪 Requirements
- bash  
- coreutils  
- findutils  
- util-linux  
- gawk  
- curl  
- jq  
- CGI-capable web server  
- GroqBash in PATH  

---

## 🛠️ Debug
logs/server.log  
logs/errors.log
