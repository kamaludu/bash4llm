[![Bash4LLM](https://img.shields.io/badge/_Bash4LLM⁺_-00aa55?style=for-the-badge&label=%E2%9E%9C&labelColor=004d00)](../../README.md)
[![Bash4LLM⁺ GUI](https://img.shields.io/badge/Graphic_User_Interface-00aa55?style=for-the-badge)](README.md) 
## [🇮🇹](#-interfaccia-web-minimalista) [🇬🇧](#-minimalist-web-interface)

# Bash4LLM⁺ GUI
## 🇮🇹 Interfaccia Web Minimalista

## 🧩 Panoramica
Questa è la GUI HTML ufficiale di Bash4LLM, progettata per essere:

- completamente portabile  
- Bash‑only (nessuna dipendenza esterna oltre a bash, coreutils, findutils, util-linux, gawk, curl, jq)  
- sicura (atomic_write, lock globale, sanitizzazione input)  
- compatibile con qualsiasi web server che supporti CGI (BusyBox httpd, Lighttpd, Apache, ecc.)  
- integrabile automaticamente con Apache tramite installer dedicato  

La GUI fornisce:

- Chat con Bash4LLM  
- Gestione conversazioni  
- Localizzazione multilingua  
- Temi chiaro/scuro  
- Gestione file (input/output)  
- Configurazioni persistenti  

Per istruzioni dettagliate di installazione, consulta anche:  
**[INSTALL.md](INSTALL.md)**

---

## 📁 Struttura delle directory

```
ui/
  gui-server.sh          ← entrypoint CGI
  gui-bootstrap.sh       ← bootstrap portabile (ambiente, percorsi, atomic_write, lock, ecc.)
  bash4llm-gui-adapt.sh
  bash4llm-gui-install.sh
  
  static/
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

## ⚙️ Architettura

### gui-server.sh  
È l’unico script eseguito dal web server.  
Contiene la logica applicativa:

- routing GET/POST  
- rendering template  
- gestione conversazioni  
- chiamate a Bash4LLM  
- sanitizzazione input  

### gui-bootstrap.sh  
Viene importato da gui-server.sh e gestisce tutto l’ambiente:

- rilevamento UI_ROOT  
- creazione directory  
- atomic_write / atomic_append_conv  
- mktemp portabile  
- lock globale tramite flock  
- logging  
- HTTP header  
- risoluzione BASH4LLM_CMD  
- configurazioni di default  

Questa separazione garantisce portabilità totale e manutenibilità.

---

## 🚀 Installazione

### ✔ Installazione automatica su Apache (consigliata)

Usa l’installa‑script ufficiale:

`./bash4llm-gui-install.sh`

L’installer:

- rileva automaticamente Apache  
- determina una directory di configurazione realmente inclusa  
- crea un VirtualHost dedicato sulla porta 19970  
- configura CGI e statici  
- imposta ScriptSock  
- applica i permessi corretti  
- garantisce idempotenza  
- **non copia la UI**: Apache punta alla directory reale  

Dopo l’installazione, apri:

`http://localhost:19970/bash4llm-gui/cgi`

---

### ✔ Installazione generica su altri web server CGI

1. Copia la cartella `ui/` sul server CGI.  
2. Rendi eseguibile lo script:

`chmod +x ui/gui-server.sh`

3. Configura il web server per eseguire `gui-server.sh` come CGI.  
4. Apri nel browser l’URL configurato.

Per configurazioni dettagliate (BusyBox, Nginx, Lighttpd, Apache manuale):  
**vedi [INSTALL.md](INSTALL.md)**

---

## 🌐 Localizzazione

La localizzazione è definita in:

- `gui-lang.conf`

Ogni chiave può avere:

- una versione globale  
- una versione specifica per lingua (es. KEY.en=, KEY.it=)

Esempio:

`TXT_TITLE.en=Bash4LLM Web UI`  
`TXT_TITLE.it=Interfaccia Web Bash4LLM`

---

## 🎨 Temi

La GUI supporta due temi:

- light  
- dark  

Il tema selezionato viene salvato in:

- `config/gui-theme`

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
- Bash4LLM installato nel PATH (o percorso configurato)  

---

## 🛠️ Debug

Log disponibili in:

- `logs/server.log`  
- `logs/errors.log`  

---
# Bash4LLM⁺ GUI
## 🇬🇧 Minimalist Web Interface

## 🧩 Overview
This is the official HTML GUI for Bash4LLM, designed to be:

- fully portable  
- Bash‑only (no external dependencies beyond bash, coreutils, findutils, util-linux, gawk, curl, jq)  
- secure (atomic_write, global lock, input sanitization)  
- compatible with any CGI‑capable web server (BusyBox httpd, Lighttpd, Apache, etc.)  
- automatically integrable with Apache via a dedicated installer  

The GUI provides:

- Chat with Bash4LLM  
- Conversation management  
- Multilingual localization  
- Light/Dark themes  
- File handling (input/output)  
- Persistent configuration  

For detailed installation instructions, **see: [INSTALL.md](INSTALL.md)**

---

## 📁 Directory Structure

```
ui/
  gui-server.sh
  gui-bootstrap.sh
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css
  README.md
  INSTALL.md

  templates/
  conversations/
  files/
  config/
  logs/
  tmp/
  assets/
```

---

## ⚙️ Architecture

### gui-server.sh  
Executed by the web server. Handles:

- GET/POST routing  
- template rendering  
- conversation management  
- Bash4LLM calls  
- input sanitization  

### gui-bootstrap.sh  
Imported by gui-server.sh. Handles:

- UI_ROOT detection  
- directory creation  
- atomic_write  
- portable mktemp  
- global flock lock  
- logging  
- HTTP headers  
- BASH4LLM_CMD resolution  
- default configuration  

---

## 🚀 Installation

### ✔ Automatic Apache installation (recommended)

Run:

`./bash4llm-gui-install.sh`

The installer:

- auto-detects Apache  
- finds a truly included config directory  
- creates a dedicated VirtualHost on port 19970  
- configures CGI and static assets  
- sets ScriptSock  
- applies minimal permissions  
- ensures idempotency  
- **does not copy the UI**  

Open:

`http://localhost:19970/bash4llm-gui/cgi`

---

### ✔ Generic installation on any CGI server

1. Copy the `ui/` directory to your CGI server  
2. Make the CGI script executable:

`chmod +x ui/gui-server.sh`

3. Configure your server to execute `gui-server.sh` as CGI  
4. Open the configured URL in your browser  

For detailed server-specific instructions (BusyBox, Nginx, Lighttpd, manual Apache),  **see: [INSTALL.md](INSTALL.md)**

---
## 🌐 Localization

Defined in:

- `gui-lang.conf`

Keys may have:

- a global version  
- language-specific versions (KEY.en=, KEY.it=)

---

## 🎨 Themes

Two themes available:

- light  
- dark  

Stored in:

- `config/gui-theme`

---

## 🔒 Security

- No `eval`  
- No system `/tmp`  
- All writes use atomic_write  
- Global flock lock  
- Full input sanitization  
- No arbitrary command execution  
- Minimal permissions applied automatically  

---

## 🧪 Requirements

- bash  
- coreutils  
- findutils  
- util-linux  
- gawk  
- curl  
- jq  
- any CGI-capable web server  
- Bash4LLM available in PATH  

---

## 🛠️ Debug

Logs:

- `logs/server.log`  
- `logs/errors.log`  
