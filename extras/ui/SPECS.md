
# STRATEGIA DI URL REWRITING STATELESS (SENZA COOKIE)
## Documento di Architettura e Flusso Dati per Bash4LLM⁺ GUI

Questo documento illustra il funzionamento della strategia di tracciamento e separazione delle sessioni introdotta per eliminare la dipendenza dai cookie HTTP e garantire la piena portabilità dell'applicazione in ambienti locali, incognito e browser testuali (come Lynx o w3m).

---

### 1. Il Problema di Origine: Perché i Cookie Falliscono
Nelle architetture Web tradizionali, lo stato della sessione di un utente viene memorizzato sul server e associato a un identificativo univoco inviato al browser tramite un cookie (es. intestazione `Set-Cookie` con attributi `HttpOnly` e `SameSite=Strict`).

Tuttavia, questo meccanismo si rivela instabile o inutilizzabile nei seguenti scenari:
*   **HTTP locale non protetto:** I browser moderni tendono a scartare o rifiutare l'impostazione di cookie con policy di sicurezza rigide se la connessione avviene su `http://localhost` o indirizzi IP privati senza cifratura TLS (HTTPS).
*   **Navigazione Anonima / Incognito:** Molti browser isolano o eliminano i cookie al termine di ogni singola interazione o ricaricamento di pagina.
*   **Browser testuali / CLI:** Strumenti a riga di comando o browser per terminale non sempre implementano il supporto completo al motore dei cookie.

Il risultato di questa instabilità in Bash4LLM⁺ era la frammentazione dei tenant: ad ogni clic o invio di messaggio, l'applicazione generava un nuovo tenant casuale, perdendo l'accesso alla chiave API memorizzata e interrompendo la continuità delle conversazioni.

---

### 2. La Soluzione: URL Rewriting Deliberato
La strategia introdotta si basa sul principio della **propagazione esplicita e stateless** dello stato. Lo stato dell'applicazione non è più delegato alla memoria del browser, ma viene registrato all'interno di ogni singola transazione di rete tramite due canali principali:
1.  **Parametri di Query (GET):** Inseriti direttamente negli indirizzi URL di navigazione.
2.  **Campi Nascosti (POST):** Inseriti all'interno dei moduli di invio dati.

Il server CGI, ad ogni esecuzione, riceve l'identificativo dell'utente (denominato `tenant` o `TENANT_HASH`), ricompone i percorsi fisici su disco e serve le risorse isolate relative a quel client specifico.

---

### 3. Anatomia del Flusso dei Dati

#### Fase A: Accesso e Inizializzazione
1.  L'utente si collega al server CGI per la prima volta.
2.  Lo script `gui-bootstrap.sh` rileva che non è presente alcun parametro `tenant` nei dati GET o POST.
3.  Il router `gui-server.sh` intercetta questo stato vuoto e richiama la funzione `render_login_page`.
4.  L'utente inserisce un identificativo personalizzato (es. `utente-ufficio`) oppure clicca per generarne uno casuale (es. un hash di 32 caratteri esadecimali).
5.  Il form invia una richiesta GET che reindirizza l'utente a: `?page=main&tenant=utente-ufficio`.

#### Fase B: Configurazione Dinamica dell'Ambiente
1.  A partire da questo momento, ogni richiesta contiene l'indicatore del tenant.
2.  `gui-bootstrap.sh` estrae il parametro e definisce le variabili d'ambiente operative:
    *   `BASH4LLM_DIR` viene impostato su: `tmp/gui-runtime.d/tenant_utente-ufficio`
    *   `CFG_DIR` diventa: `tmp/gui-runtime.d/tenant_utente-ufficio/config`
    *   `TMP_DIR` diventa: `tmp/gui-runtime.d/tenant_utente-ufficio/tmp`
3.  Tutte le scritture e letture di file (chiavi API, configurazioni del modello, cronologia dei messaggi) avvengono esclusivamente all'interno di questo perimetro protetto.

#### Fase C: Propagazione dello Stato
Per evitare che l'utente perda la sessione navigando nell'interfaccia, la variabile `TENANT_HASH` viene propagata dinamicamente in tutti gli elementi HTML generati dal server:

*   **Menu delle Conversazioni (Link GET):**
    Ogni link per cambiare chat viene riscritto includendo il tenant:
    `href="?page=main&select_conv=session-123&tenant=utente-ufficio"`
*   **Moduli e Form (POST):**
    All'interno dei form (come l'invio del prompt o il salvataggio delle impostazioni), viene iniettato un campo nascosto:
    `<input type="hidden" name="tenant" value="utente-ufficio">`
*   **Reindirizzamenti HTTP (303 See Other):**
    La funzione di utilità `print_http_redirect` è stata modificata per intercettare l'indirizzo di destinazione e accodarvi automaticamente il tenant prima di inviare l'header `Location: ...` al browser.

---

### 4. Risoluzione del Consumo dello Standard Input (POST Caching)
Nei server CGI, il corpo delle richieste POST viene trasmesso dal server web (Apache/httpd) allo script tramite lo standard input (`stdin`). Per ragioni architetturali, lo `stdin` può essere letto **una sola volta**; qualsiasi tentativo successivo di lettura restituisce un flusso vuoto.

Questo rappresentava un ostacolo per l'URL Rewriting: per determinare quale fosse la cartella del tenant (e quindi configurare le variabili d'ambiente di bootstrap), era necessario scansionare il corpo POST alla ricerca del campo `tenant`. Tuttavia, facendo ciò, il corpo POST veniva consumato, impedendo alle successive funzioni di estrarre i parametri reali (es. il testo del prompt o i parametri delle impostazioni).

#### Il Meccanismo di Cache Implementato:
Per risolvere questo problema, nel file `gui-env.sh` sono state introdotte le variabili di controllo `_GUI_CACHED_POST_BODY` e `_GUI_POST_BODY_READ`.
La funzione `read_post_body` agisce ora come un proxy:
1.  Al primo richiamo, legge interamente lo standard input e ne memorizza il contenuto nella variabile globale `_GUI_CACHED_POST_BODY`, impostando l'indicatore `_GUI_POST_BODY_READ` a `1`.
2.  A partire dal secondo richiamo, la funzione salta la lettura dello `stdin` e restituisce immediatamente la stringa memorizzata in cache.

Questo consente a `gui-bootstrap.sh` di analizzare il POST all'avvio per estrarre l'ID del tenant, e a `gui-server.sh` di ri-analizzarlo successivamente per elaborare le azioni e i testi inseriti dall'utente, senza alcuna perdita di dati.

---

### 5. Integrazione Trasparente con il Motore dei Template (AWK)
Il sistema di rendering di Bash4LLM⁺ utilizza un parser testuale snello scritto in `awk` (funzione `render_template` in `gui-env.sh`). Questo motore scansiona i file HTML statici e sostituisce i placeholder con la sintassi `{{VARNAME}}` o `${VARNAME}` utilizzando i valori memorizzati nell'array `ENVIRON` di sistema.

Esportando esplicitamente le variabili dal CGI:
```bash
export TENANT_INPUT_HTML="<input type=\"hidden\" name=\"tenant\" value=\"utente-ufficio\">"
export TENANT_QUERY_VAR="&amp;tenant=utente-ufficio"
```
I designer e gli sviluppatori possono integrare il supporto all'URL Rewriting nei file HTML statici semplicemente inserendo questi placeholder all'interno delle form e dei link, garantendo una separazione pulita tra logica di programmazione e presentazione visiva.
