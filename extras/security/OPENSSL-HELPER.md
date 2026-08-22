[![Logo 320](../../docs/img/bash4llm320.png "Logo bash4llm")](../../README.md)

[![Security](https://img.shields.io/badge/security-OpenSSL%20Helper-gold?style=flat-square&logo=securityscorecard&logoColor=white)](#)

# Specifica Tecnica: Modulo di Sicurezza e Cifratura `openssl-helper.sh`

La presente specifica tecnica descrive l'architettura, i flussi crittografici, le misure di tolleranza ai guasti e i dettagli implementativi del modulo opzionale di sicurezza `openssl-helper.sh` per la suite `Bash4LLM⁺`.

**Requisiti** (oltre a quelli di bash4llm):
- Binario CLI: **openssl** versione 1.1.1 o superiore (su Termux installare **openssl-tool**).  
- Utility di terminale: **stty** (per l'input nascosto delle password).  
- Cancellazione sicura: **dd** (standard) oppure **shred** (opzionale).

---

## 1. Introduzione e Principi di Progettazione

Il modulo `openssl-helper.sh` è sviluppato come un'estensione opzionale (*soft dependency*) per la gestione e cifratura locale delle chiavi API dei provider di modelli linguistici. Il modulo aderisce ai seguenti principi:

* **Graceful Degradation (Degradazione Controllata)**: L'assenza dell'utilità OpenSSL nel sistema non compromette il funzionamento del Core di `bash4llm`, che degrada automaticamente verso il prompt manuale delle chiavi senza blocchi di processo.
* **Zero-Knowledge Locale**: Nessuna chiave o password viene memorizzata in chiaro su disco o trasmessa in rete. La cifratura e la decifrazione avvengono esclusivamente nella memoria RAM locale del processo.
* **Compatibilità Multipiattaforma**: Il codice è sviluppato per essere eseguito in modo uniforme sulle piattaforme supportate, comprese Linux, macOS (Darwin), Termux (Android), BSD, WSL e Cygwin, superando le difformità tra le implementazioni OpenSSL standard e LibreSSL.

---

## 2. Architettura Crittografica (Vault Key Wrapping)

Per garantire che l'aggiornamento delle chiavi API non richieda la rigenerazione e la riscrittura dei credenziali di emergenza offline, il modulo implementa un modello di cifratura a **chiave intermedia (Vault Key)**.

```text
                          [ Master Password ]
                                   │
                                   v (PBKDF2 / AES-256-CBC)
[ Recovery Key ] ─────────> [ keys.enc ]
       │                           │
       v (PBKDF2 / AES-256-CBC)    v
 [ keys.rec ] ────────────> [ Vault Key ] ───> [ keys.dat ] ───> [ API Keys JSON ]
                                                 (AES-256-CBC)
```

### Meccanismo di Sincronizzazione
1. All'inizializzazione del vault viene generata una chiave simmetrica casuale a 256 bit denominata **Vault Key** (`openssl rand -hex 32`).
2. Il database contenente le chiavi API reali (`keys.dat`) viene cifrato **esclusivamente con questa Vault Key** tramite algoritmo AES-256-CBC.
3. La Vault Key viene cifrata a sua volta due volte e memorizzata in due file distinti:
   * **`keys.enc`**: Cifrato utilizzando la Master Password definita dall'utente.
   * **`keys.rec`**: Cifrato utilizzando la Recovery Key (chiave di emergenza offline) generata dal sistema.
4. **Indipendenza dei file di recupero**: Quando l'utente aggiunge, modifica o rimuove chiavi API, il sistema decifra la Vault Key (tramite Master Password), aggiorna il payload `keys.dat` e lo risollecita con la medesima Vault Key. Il file `keys.rec` **non viene modificato**, garantendo che la Recovery Key memorizzata offline rimanga sempre valida per il ripristino dell'intero database.

---

## 3. Layout dei File e Permessi

Tutti i file del vault sono memorizzati all'interno della directory di configurazione dell'applicazione (identificata dalla variabile `${BASH4LLM_CONFIG_DIR}`).

| Nome File | Contenuto | Algoritmo | Permessi |
| :--- | :--- | :--- | :--- |
| **`keys.enc`** | Vault Key (Master Key simmetrica) | AES-256-CBC + PBKDF2 (Master Pass) | `0600` (Lettura/Scrittura proprietario) |
| **`keys.rec`** | Vault Key (Master Key simmetrica) | AES-256-CBC + PBKDF2 (Recovery Key) | `0600` (Lettura/Scrittura proprietario) |
| **`keys.dat`** | Database JSON delle chiavi API | AES-256-CBC (Vault Key) | `0600` (Lettura/Scrittura proprietario) |

---

## 4. Atomicità e Sicurezza di Esecuzione

### Scrittura Atomica su Filesystem
Il salvataggio dei file cifrati non avviene mai scrivendo direttamente sul file di destinazione:
1. I dati vengono crittografati in un file temporaneo sicuro generato tramite la funzione core `_tmpf` all'interno di `$RUN_TMPDIR` con permessi `0600`.
2. Se la cifratura fallisce, il file temporaneo viene rimosso immediatamente.
3. Se la cifratura ha successo, viene eseguito uno spostamento atomico (`mv -f`). Se il comando `mv` fallisce (es. per restrizioni di partizione), viene eseguito il fallback con copia forzata (`cp -f`).
4. In caso di errore su entrambi i comandi, il file temporaneo viene rimosso e viene restituito il codice di fallimento `1`.

### Integrità Transazionale JSON
Prima di riscrivere il database `keys.dat` durante la modifica delle chiavi, il risultato elaborato da `jq` viene convalidato in memoria:
```bash
if [ -n "$updated_payload" ] && printf '%s' "$updated_payload" | jq -e . >/dev/null 2>&1;
```
La sovrascrittura su disco viene autorizzata **solo se** la convalida strutturale del JSON ha esito positivo.

### Gestione del Codice di Ritorno (`$?`)
Nelle funzioni di decifrazione, il codice di stato di OpenSSL viene memorizzato immediatamente in una variabile locale (`rc=$?`) prima dell'esecuzione di `unset BASH4LLM_VAULT_PASS`, per evitare che la successiva operazione di un-export mascheri un eventuale fallimento di decodifica.

### Protezione dalla Visibilità dei Processi (Pass-By-Env) [INV-1]
Per impedire che la Master Password o le chiavi simmetriche siano visibili nell'albero dei processi di sistema (`ps aux` o `/proc/<pid>/cmdline`), le chiavi non vengono mai passate come argomento di riga di comando (flag `-k` o `-pass pass:...`). Il modulo esporta temporaneamente la credenziale in una variabile d'ambiente privata del processo ed istruisce OpenSSL ad attingervi tramite `-pass env:BASH4LLM_VAULT_PASS`. La variabile viene rossa dall'ambiente (`unset`) subito dopo l'esecuzione.

---

## 5. Standardizzazione Crittografica e Portabilità

### Rilevamento Diretto di PBKDF2
L'abilitazione del supporto al KDF avanzato (PBKDF2) viene verificata a runtime eseguendo un test di cifratura reale su uno stream di prova, evitando il parsing del testo di aiuto di OpenSSL o la dipendenza dalle differenze di sintassi tra OpenSSL 3.x e LibreSSL:
```bash
_BASH4LLM_VAULT_PBKDF2=0
if printf 'test' | openssl enc -aes-256-cbc -pbkdf2 -iter 10 -salt -pass pass:test >/dev/null 2>&1; then
  _BASH4LLM_VAULT_PBKDF2=1
fi
```

### Portabilità Base64
Per evitare l'anomalia di LibreSSL su macOS/BSD (che tronca i flussi Base64 superiori a 1024 byte se elaborati con la flag `-A` di `openssl`), il modulo non impiega la flag `-A`. Per le normali operazioni di encoding/decoding viene utilizzata l'utility di sistema `base64` di coreutils, limitando l'uso di `openssl enc` esclusivamente alla cifratura binaria/armored dei file del vault.

---

## 6. API Pubblica del Modulo

### `vault_init()`
Inizializza il Key Vault. Richiede l'inserimento e la conferma di una Master Password, genera la Recovery Key offline a 32 caratteri esadecimali e crea i file di base con un payload JSON vuoto (`{}`).

### `vault_load_keys()`
Verifica il token di contesto `_B4L_RT_CTX` o richiede la Master Password, estrae la Vault Key da `keys.enc` e decifra il database `keys.dat`, restituendo il payload JSON su `stdout`.

### `vault_change_password()`
Consente la rotazione delle credenziali. Decifra la Vault Key simmetrica con la Master Password corrente e la ricifra sotto una nuova Master Password (riscrittura di `keys.enc`) e una nuova Recovery Key (riscrittura di `keys.rec`).

### `vault_recover()`
Procedura d'emergenza in caso di smarrimento della password. Decifra la Vault Key utilizzando la Recovery Key offline registrata in `keys.rec` e reimposta una nuova Master Password.

### `vault_manage_keys()`
Console interattiva del Key Manager per l'aggiunta, visualizzazione e rimozione delle chiavi API dei provider all'interno del database.

### `vault_destroy()`
Esegue il wipe crittografico di sicurezza. Richiede conferma esplicita a schermo, esegue la sovrascrittura dei dati sul filesystem (tramite `shred` o riempimento con zeri via `dd`) e cancella i file del vault.

### `vault_get_provider_key <provider> <master_password>`
Estrazione programmatica non interattiva dell'API key di uno specifico provider fornendo la Master Password.

### `_secure_hash_sha256 <file_path>`
Genera l'hash SHA-256 di un file tramite il motore di OpenSSL, garantendo un output a 64 caratteri esadecimali uniforme tra sistemi GNU e BSD.

### `diagnose_tls_connection <url>`
Esegue un test di handshake TLS verso l'host specificato nell'URL del provider utilizzando `openssl s_client` con un timeout di 5 secondi, evidenziando errori di certificato o intercettazioni proxy.
