# 📦 Installazione completa della GroqBash⁺ GUI

Questa guida descrive l’intero processo di installazione della GUI:

1. Installazione della UI come extra di GroqBash  
2. Attivazione della GUI CGI:
   - Installazione automatica su Apache tramite groqbash-gui-install.sh
   - Installazione manuale su qualsiasi server con supporto CGI

---

## 🧩 Installazione della UI come extra di GroqBash

La GUI vive nella directory:

```
groqbash/groqbash.d/extras/ui/
```

La struttura aggiornata è:

```sh
ui/
  groqbash-gui-install.sh
  gui-server.sh
  gui-bootstrap.sh
  gui-lang.conf
  gui-style-light.css
  gui-style-dark.css

  templates/
    header.html
    content.html
    footer.html
    settings-header.html
    settings-content.html

  conversations/
  files/
      input/
      output/
  config/
  logs/
  tmp/
  assets/
```

### ✔ Installazione UI (metodo ufficiale)

1. Clona o aggiorna GroqBash:
   ```sh
   git clone https://github.com/kamaludu/groqbash
   ```

2. Verifica che la UI sia presente in:
   ```
   groqbash/groqbash.d/extras/ui
   ```

3. Non spostare la UI altrove.  
   La GUI **deve rimanere dentro l’albero di GroqBash**, perché gui-bootstrap.sh deriva i percorsi da lì.

---

## 🅰 Installazione automatica su Apache (consigliata)

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
- non copia la UI (Apache punta alla directory reale)  

### ✔ Esecuzione

1. Vai nella directory della UI:
   ```sh
   cd groqbash/groqbash.d/extras/ui
   ```

2. Rendi eseguibile l’installer:
   ```sh
   chmod +x groqbash-gui-install.sh
   ```

3. Avvia l’installazione:
   ```sh
   ./groqbash-gui-install.sh
   ```

4. Al termine, apri:
   ```
   http://localhost:19970/groqbash-gui/cgi
   ```

### ✔ Cosa fa l’installer

- Crea il file:
  ```
  <APACHE_CONF_DIR>/groqbash-gui.conf
  ```

- Configura:
  ```
  ScriptAlias /groqbash-gui/cgi <APP_BIN>/gui-server.sh
  Alias /groqbash-gui/static <APP_BIN>
  ```

- Imposta HOME e PATH per CGI (Termux)
- Applica permessi:
  - script: 755  
  - template/static: 644  
  - runtime dirs: 700  
  - runtime files: 600  

- Esegue configtest  
- Esegue reload Apache (o mostra istruzioni manuali)

---

## 🅱 Installazione manuale su qualsiasi server CGI

Se non usi Apache, puoi configurare la GUI manualmente.

### ✔ 3.1 Rendere eseguibile il CGI

```sh
chmod +x ui/gui-server.sh
```

### ✔ 3.2 Configurare il server per eseguire gui-server.sh

Dipende dal server:

---

## 🔹 BusyBox httpd

Aggiungi nel file di configurazione:

```
/cgi-bin:groqbash/groqbash.d/extras/ui
```

E avvia:

```sh
busybox httpd -f -p 8080 -h .
```

Apri:

```
http://localhost:8080/cgi-bin/gui-server.sh
```

---

## 🔹 Lighttpd

Aggiungi:

```
cgi.assign = ( ".sh" => "/bin/bash" )
alias.url += ( "/groqbash-gui" => "/percorso/ui" )
```

---

## 🔹 Nginx (tramite fcgiwrap)

Nginx non supporta CGI nativamente.  
Serve fcgiwrap + configurazione dedicata.

---

## 🔹 Qualsiasi altro server CGI

Regole generali:

- gui-server.sh deve essere eseguibile  
- deve essere invocato come CGI (stdin + env + stdout)  
- deve poter leggere/scrivere nelle directory runtime  
- deve poter eseguire GroqBash  

URL tipico:

```
http://localhost/cgi-bin/gui-server.sh
```

---

## 🧪 Requisiti

- bash  
- coreutils  
- findutils  
- util-linux  
- gawk  
- curl  
- jq  
- web server con CGI  
- GroqBash installato  

---

## 🛠️ Debug

Log disponibili in:

```
ui/logs/server.log
ui/logs/errors.log
```
