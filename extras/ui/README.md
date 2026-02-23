# 🇮🇹 GroqBash GUI — Interfaccia Web Minimalista

## 🧩 Panoramica
Questa è la GUI HTML ufficiale di GroqBash, progettata per essere:
- completamente portabile
- Bash‑only (nessuna dipendenza esterna oltre a bash, coreutils, curl, jq)
- sicura (atomic_write, lock globale, sanitizzazione input)
- compatibile con qualsiasi web server che supporti CGI (BusyBox httpd, Lighttpd, Apache, ecc.)

La GUI fornisce:
- Chat con GroqBash
- Gestione conversazioni
- Localizzazione multilingua
- Temi chiaro/scuro
- Gestione file (input/output)
- Configurazioni persistenti

---

## 📁 Struttura delle directory

```text
ui/
  gui-server.sh
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css

  templates/
    header.html
    content.html
    footer.html
    settings-header.html
    settings-content.html

  conversations/        ← creato automaticamente
      conv-001.txt
      conv-002.txt

  files/
      input/            ← creato automaticamente
      output/           ← creato automaticamente

  config/               ← creato automaticamente
      current-conversation
      lang-current
      default-model
      default-provider
      gui-theme

  logs/                 ← creato automaticamente
      server.log
      errors.log

  tmp/                  ← creato automaticamente
      (file temporanei, lock, atomic_write)

  assets/               ← creato automaticamente (vuoto)
```

---

## 🚀 Installazione

1. Copia la cartella ui/ sul server CGI.
2. Rendi eseguibile lo script:
```sh
chmod +x ui/gui-server.sh
```
3. Configura il web server per eseguire gui-server.sh come CGI.
4. Apri nel browser:
http://localhost/cgi-bin/gui-server.sh

---

## 🌐 Localizzazione

La localizzazione è definita in:

gui-lang.conf

Ogni chiave può avere:
- una versione globale (valida per tutte le lingue)
- una versione specifica:  
  KEY.en=, KEY.it=, KEY.es=, ecc.

Esempio:

TXT_TITLE.en=GroqBash Web UI  
TXT_TITLE.it=Interfaccia Web GroqBash

---

## 🎨 Temi

La GUI supporta due temi:
- light
- dark

Il tema selezionato viene salvato in:

config/gui-theme

---

## 🔒 Sicurezza

- Nessun eval
- Nessun uso di /tmp di sistema
- Tutte le scritture sono atomic_write
- Lock globale tramite flock
- Sanitizzazione completa dei parametri
- Nessuna esecuzione di comandi arbitrari

---

## 🧪 Requisiti

- Bash
- coreutils
- curl
- jq
- Un web server con CGI abilitato
- GroqBash installato nel PATH

---

## 🛠️ Debug

Log disponibili in:

logs/server.log  
logs/errors.log

---

# 🇬🇧 GroqBash GUI — Minimalist Web Interface

## 🧩 Overview
This is the official HTML GUI for GroqBash, designed to be:
- fully portable
- Bash‑only (no external dependencies beyond bash, coreutils, curl, jq)
- secure (atomic writes, global lock, input sanitization)
- compatible with any CGI‑capable web server (BusyBox httpd, Lighttpd, Apache, etc.)

The GUI provides:
- Chat with GroqBash
- Conversation management
- Multi‑language localization
- Light/Dark themes
- File handling (input/output)
- Persistent configuration

---

## 📁 Directory Structure

```text
ui/
  gui-server.sh
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css

  templates/
    header.html
    content.html
    footer.html
    settings-header.html
    settings-content.html

  conversations/        ← auto-created
  files/input/          ← auto-created
  files/output/         ← auto-created
  config/               ← auto-created
  logs/                 ← auto-created
  tmp/                  ← auto-created
  assets/               ← auto-created
```

---

## 🚀 Installation

1. Copy the ui/ folder to your CGI-enabled server.
2. Make the server script executable:
```sh
chmod +x ui/gui-server.sh
```
3. Configure your web server to run gui-server.sh as a CGI script.
4. Open in your browser:
http://localhost/cgi-bin/gui-server.sh

---

## 🌐 Localization

Localization is defined in:

gui-lang.conf

Each key may have:
- a global version (valid for all languages)
- a language-specific version:  
  KEY.en=, KEY.it=, KEY.es=, etc.

Example:

TXT_TITLE.en=GroqBash Web UI  
TXT_TITLE.it=Interfaccia Web GroqBash

---

## 🎨 Themes

The GUI supports:
- light
- dark

The selected theme is stored in:

config/gui-theme

---

## 🔒 Security

- No eval
- No use of system /tmp
- All writes use atomic_write
- Global lock via flock
- Full input sanitization
- No arbitrary command execution

---

## 🧪 Requirements

- Bash
- coreutils
- curl
- jq
- A CGI-capable web server
- GroqBash installed in PATH

---

## 🛠️ Debug

Logs are available in:

logs/server.log  
logs/errors.log
