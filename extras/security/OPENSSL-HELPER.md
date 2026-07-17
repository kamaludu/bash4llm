[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

# ​🔐 Specifica Tecnica: Modulo di Sicurezza e Cifratura `openssl-helper.sh`

La presente specifica tecnica descrive l'architettura, i flussi crittografici, le misure di tolleranza ai guasti e i dettagli implementativi del modulo opzionale di sicurezza `openssl-helper.sh` per l'applicazione `bash4llm`.

---

## 1. Introduzione e Filosofia di Design

Il modulo `openssl-helper.sh` è progettato come un'estensione opzionale (*soft dependency*) per la gestione sicura e locale delle chiavi API dei provider di modelli linguistici. Il modulo aderisce ai seguenti principi:

* **Graceful Degradation (Degradazione Fluida)**: L'assenza di OpenSSL nel sistema non compromette il funzionamento del core script di `bash4llm`, che degrada automaticamente verso il prompt manuale delle chiavi senza causare blocchi.
* **Zero-Knowledge Locale**: Nessuna chiave o password viene memorizzata in chiaro su disco o trasmessa in rete. La cifratura e la decifrazione avvengono interamente in memoria locale.
* **Compatibilità Multipiattaforma**: Il codice è sviluppato per essere eseguito in modo uniforme sulle piattaforme supportate da `bash4llm`, comprese Termux (Android), Linux, macOS (Darwin), BSD, WSL e Cygwin, superando le divergenze sintattiche e crittografiche tra le implementazioni GNU e BSD (LibreSSL).

---

## 2. Architettura Crittografica (Vault Key Wrapping)

Per garantire che i backup e il ripristino delle chiavi API rimangano sincronizzati in modo trasparente, il modulo implementa un modello di cifratura a **chiave intermedia (Vault Key)**.

```
                          [ Master Password ]
                                   │
                                   v (PBKDF2 / AES-256-CBC)
[ Recovery Key ] ─────────> [ keys.enc ]
       │                           │
       v (PBKDF2 / AES-256-CBC)    v
 [ keys.rec ] ────────────> [ Vault Key ] ───> [ keys.dat ] ───> [ API Keys JSON ]
                                                 (AES-256-CBC)
```

### Meccanismo di Sincronizzazione Automatica
1. All'atto dell'inizializzazione del vault, viene generata una chiave simmetrica casuale a 256 bit denominata **Vault Key** (`openssl rand -hex 32`).
2. Il database contenente le chiavi API reali (`keys.dat`) viene cifrato **esclusivamente con questa Vault Key** tramite algoritmo AES-256-CBC.
3. La Vault Key viene cifrata a sua volta due volte e memorizzata in due file distinti:
   * **`keys.enc`**: Cifrato utilizzando la Master Password definita dall'utente.
   * **`keys.rec`**: Cifrato utilizzando la Recovery Key (chiave di emergenza offline) generata dal sistema.
4. **Trasparenza degli aggiornamenti**: Quando l'utente aggiunge, modifica o rimuove chiavi API, il sistema decifra la Vault Key (usando la Master Password), aggiorna il file delle chiavi `keys.dat` e lo risollecita con la stessa Vault Key. Di conseguenza, il file di recupero `keys.rec` **non necessita di alcuna riscrittura**, garantendo che la Recovery Key memorizzata offline rimanga sempre aggiornata e valida per il ripristino dell'intero database corrente.

---

## 3. Layout dei File e Permessi

Tutti i file del vault sono memorizzati all'interno della directory di configurazione dell'applicazione (identificata dalla variabile `${BASH4LLM_CONFIG_DIR}`).

| Nome File | Contenuto | Algoritmo | Permessi |
| :--- | :--- | :--- | :--- |
| **`keys.enc`** | Vault Key (Master Key simmetrica) | AES-256-CBC + PBKDF2 (Master Pass) | `600` (Lettura/Scrittura proprietario) |
| **`keys.rec`** | Vault Key (Master Key simmetrica) | AES-256-CBC + PBKDF2 (Recovery Key) | `600` (Lettura/Scrittura proprietario) |
| **`keys.dat`** | Database JSON delle chiavi API | AES-256-CBC (Vault Key) | `600` (Lettura/Scrittura proprietario) |

---

## 4. Tolleranza ai Guasti, Atomicità e Sicurezza di Esecuzione

Per operare in modo sicuro in ambienti shell complessi con opzioni restrittive attive (`set -euo pipefail`), il modulo implementa specifiche tecniche di protezione del runtime:

### Scrittura Atomica e Rilevamento dei Fallimenti fisici
Il salvataggio di qualsiasi file cifrato non avviene mai scrivendo direttamente sul file di destinazione. 
1. I dati vengono crittografati in un file temporaneo sicuro generato tramite la funzione core `_tmpf`.
2. Se la cifratura fallisce, il file temporaneo viene rimosso e l'operazione viene interrotta restituendo un errore.
3. Se la cifratura ha successo, viene tentato uno spostamento atomico (`mv -f`). Se il comando `mv` fallisce (es. per restrizioni di partizione), viene eseguito un fallback con copia forzata (`cp -f`).
4. Se entrambi i tentativi falliscono (es. filesystem saturo o in sola lettura), il modulo rimuove il file temporaneo e restituisce esplicitamente `1` (fallimento). Questo previene la perdita silente dei dati.

### Integrità Transazionale JSON
Prima di riscrivere il database `keys.dat` durante le modifiche alle chiavi, il risultato elaborato da `jq` viene salvato in una variabile di memoria transitoria e convalidato formalmente:
```bash
if [ -n "$updated_payload" ] && printf '%s' "$updated_payload" | jq -e . >/dev/null 2>&1;
```
La sovrascrittura su disco viene autorizzata **solo se** la convalida strutturale del JSON ha successo, evitando di corrompere o azzerare il database esistente a causa di errori imprevisti di sintassi o parsing.

### Immunità al Mascheramento del Codice di Ritorno (`$?`)
Nelle funzioni di decifrazione, per preservare l'esito del comando di openssl prima della pulizia delle credenziali in memoria, il codice di stato di openssl viene catturato immediatamente in una variabile locale dedicata (`rc=$?`), prevenendo che l'istruzione successiva `unset BASH4LLM_VAULT_PASS` (che restituisce sempre `0`) mascheri un eventuale fallimento di decodifica.

### Prevenzione della Visibilità dei Processi (Pass-By-Env)
Per impedire che la Master Password o le chiavi simmetriche siano visibili nell'albero dei processi di sistema (es. tramite comandi `ps` o `top`), le chiavi di cifratura non vengono mai passate come argomento a riga di comando (flag `-k`). Il modulo esporta temporaneamente la credenziale in una variabile d'ambiente privata del processo ed istruisce OpenSSL ad attingervi direttamente tramite il flag `-pass env:BASH4LLM_VAULT_PASS`. La variabile viene rimossa dall'ambiente (`unset`) subito dopo l'esecuzione dell'istruzione.

---

## 5. Standardizzazione Crittografica e Ottimizzazioni

### Rilevamento PBKDF2 Immune a `pipefail`
Le versioni di OpenSSL 3.x e LibreSSL rispondono in modo differente all'opzione `-help`, uscendo talvolta con codici di errore diversi da zero. Per evitare che l'opzione shell `pipefail` interpreti questo comportamento come un errore globale della pipeline (disattivando erroneamente il supporto a PBKDF2), il rilevamento memorizza l'output del comando in una variabile sicura con fallback positivo ed esegue una ricerca di stringa tramite globbing nativo di Bash, eliminando fork e pipeline:
```bash
_openssl_help_text="$(openssl enc -help 2>&1 || true)"
if [[ "$_openssl_help_text" == *"-pbkdf2"* ]]; then ...
```

### Portabilità Base64
Per scongiurare il bug di LibreSSL su macOS/BSD (che tronca in modo silente i flussi Base664 superiori a 1024 byte se manipolati con il flag `-A` di openssl), il modulo non utilizza il flag `-A`. Per le normali operazioni di encoding/decoding delle transazioni standard di `bash4llm` viene delegata l'utility di sistema `base64` (di coreutils, già richiesta e validata all'avvio del core), limitando l'uso della cifratura openssl unicamente alla persistenza fisica dei tre file crittografici descritti nel layout.

---

## 6. API Pubblica del Modulo

Il modulo esporta le seguenti funzioni chiave integrate direttamente nel ciclo di vita e nell'interfaccia a riga di comando di `bash4llm`:

### `vault_init()`
Inizializza una nuova istanza del Key Vault. Richiede l'inserimento e la conferma di una Master Password, genera una Recovery Key offline ad alta entropia e crea i file di base con un payload JSON vuoto (`{}`).

### `vault_load_keys()`
Richiede la Master Password, estrae la Vault Key da `keys.enc` e decifra il database `keys.dat`, restituendo il payload JSON in chiaro su stdout. In caso di errore di autenticazione o corruzione dei file, restituisce un codice di stato non-zero.

### `vault_change_password()`
Consente la rotazione sicura delle credenziali. Richiede la Master Password corrente, estrae la Vault Key simmetrica, e la ricifra sotto una nuova Master Password (riscrittura di `keys.enc`) e una nuova Recovery Key generata sul momento (riscrittura di `keys.rec`).

### `vault_recover()`
Avvia la procedura di emergenza in caso di smarrimento della password. Consente di decifrare la Vault Key intermedia inserendo la Recovery Key offline memorizzata in `keys.rec`. In caso di successo, richiede e imposta una nuova Master Password riscritturando `keys.enc`.

### `vault_manage_keys()`
Console interattiva del Key Manager. Consente l'aggiunta, la visualizzazione e la rimozione delle chiavi dei provider all'interno del database, applicando verifiche di integrità transazionale prima di scrivere le modifiche su disco.

### `vault_destroy()`
Esegue un wipe crittografico di sicurezza. Richiede una conferma esplicita a schermo, esegue una sovrascrittura fisica multilivello dei dati (tramite `shred` o riempimento con zeri via `dd`) per impedire il recupero dei file, ed elimina definitivamente i file crittografati dal filesystem.

### `vault_get_provider_key <provider> <master_password>`
Funzione programmatica e non interattiva utilizzata dal core script di `bash4llm` per estrarre la chiave API di un provider specifico fornendo la Master Password corretta, restituendo la stringa della chiave direttamente su stdout.

### `_secure_hash_sha256 <file_path>`
Genera l'hash SHA-256 standard di un file utilizzando il motore crittografico ottimizzato di OpenSSL, garantendo un output esadecimale a 64 caratteri uniforme e immune alle variazioni di implementazione tra i sistemi GNU e BSD.

### `diagnose_tls_connection <url>`
Isola i problemi di trasporto di rete eseguendo un handshake TLS interamente locale verso l'host specificato nell'URL del provider, bypassando i trust store del browser ed esponendo errori relativi a certificati scaduti, catene di attendibilità interrotte o intercettazioni proxy. Incorpora un timeout di sicurezza di 5 secondi.
