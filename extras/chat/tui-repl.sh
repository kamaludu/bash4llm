#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# =============================================================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: tui-repl.sh
# Component: TUI REPL Interactive Module (External Extra)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# =============================================================================
# Clean execution environment: inherits variables from parent process group.
set -u

# =============================================================================
# FASE 1: BOOTSTRAP, SOURCING GUARD E IMPORTAZIONE CORE LIBRERIE
# =============================================================================
CORE_SCRIPT="${BASH4LLM_CORE_SCRIPT:-}"

if [ -z "$CORE_SCRIPT" ] || [ ! -f "$CORE_SCRIPT" ]; then
  # Fallback dinamico se invocato direttamente fuori dal core (ricerca a 3 livelli)
  _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  _repo_root="$(cd "$_self_dir/../../.." >/dev/null 2>&1 && pwd)"
  if [ -f "$_repo_root/bash4llm" ]; then
    CORE_SCRIPT="$_repo_root/bash4llm"
  elif [ -f "$_repo_root/bash4llm.sh" ]; then
    CORE_SCRIPT="$_repo_root/bash4llm.sh"
  fi
fi

if [ -n "$CORE_SCRIPT" ] && [ -f "$CORE_SCRIPT" ]; then
  # Sourcing del core sotto la guardia BASH4LLM_SOURCE_ONLY=1
  export BASH4LLM_SOURCE_ONLY=1
  # shellcheck source=/dev/null
  . "$CORE_SCRIPT"
else
  printf 'tui-repl.sh: %sERROR%s: Cannot locate core bash4llm script.\n' "${C_RED:-}" "${C_RST:-}" >&2
  printf 'Please run directly using: bash4llm --chat\n' >&2
  exit 15
fi

# Validazione ambiente TTY interattivo
if [ ! -t 0 ] || [ ! -t 1 ]; then
  log_error "TUI" "TUI REPL requires a valid and active interactive TTY."
  exit 15
fi

# =============================================================================
# FASE 2: DIZIONARIO DI STATO REPL E INIZIALIZZAZIONE VARIABILI
# =============================================================================
# Mappatura dello stato operativo ereditato o inizializzazione dei default
SESSION_ID="${BASH4LLM_ACTIVE_SESSION:-}"
MODEL="${BASH4LLM_ACTIVE_MODEL:-}"
TEMPERATURE="${BASH4LLM_ACTIVE_TEMPERATURE:-1.0}"
TURE="$TEMPERATURE"

# Configurazione default di sicurezza se lo stato ereditato è nullo
[ -n "$MODEL" ] || {
  # Risolve modello predefinito riutilizzando la funzione del core
  if resolve_model >/dev/null 2>&1 && [ -n "${FINAL_MODEL:-}" ]; then
    MODEL="$FINAL_MODEL"
  else
    MODEL="default"
  fi
}

# Assicura le directory necessarie per lo stato di ui_state
ensure_run_tmpdir >/dev/null 2>&1 || {
  log_error "TUI" "Unable to initialize secure run-specific temporary directory."
  exit "$BASH4LLM_ERR_TMP"
}

# =============================================================================
# FASE 3: CONFIGURAZIONE CRONOLOGIA INPUT (READLINE ISOLATO)
# =============================================================================
# Abilitazione manuale dei meccanismi di cronologia nel processo REPL corrente
set -o history 2>/dev/null || true
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTFILE="${BASH4LLM_HISTORY_DIR}/tui_history"

# Inizializzazione sicura del database della cronologia interna
if [ ! -f "$HISTFILE" ]; then
  : > "$HISTFILE" 2>/dev/null
  chmod 600 "$HISTFILE" 2>/dev/null || true
fi
history -r "$HISTFILE" 2>/dev/null || true

# =============================================================================
# FASE 4: ARCHITETTURA DI GESTIONE DEI SEGNALI (SIGINT / Ctrl+C)
# =============================================================================
# Flag dinamico per distinguere lo stato di streaming di rete dallo stato di prompt passivo
IS_STREAMING=0

handle_sigint() {
  if [ "$IS_STREAMING" -eq 1 ]; then
    # Se stiamo ricevendo dati dalle API, lasciamo che sia il meccanismo locale 
    # della pipeline del core ad intercettare e gestire l'interruzione di curl.
    :
  else
    # Se siamo nel prompt di attesa input, ripuliamo visivamente la riga
    # di Readline e ripresentiamo il prompt vuoto in modo non distruttivo.
    printf '\n' >&2
  fi
}
trap handle_sigint INT

# =============================================================================
# FASE 5: UTILITY DI RENDERING SEQUENZIALE E HELPERS GRAFICI
# =============================================================================
print_banner() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  printf '%b' "
${C_LOGO}  Bash4LLM⁺  ${C_RST} — ${C_BCYAN}Interactive TUI Shell (v${SCRIPT_VERSION:-2.3.0})${C_RST}
  Sessione Attiva: ${C_YELLOW}${SESSION_ID:-<Nessuna>}${C_RST} | Modello: ${C_BGREEN}${MODEL:-<Default>}${C_RST}
  Digita ${C_BYELLOW}/?${C_RST} o ${C_BYELLOW}/help${C_RST} per l'elenco dei comandi.
  ----------------------------------------------------------------------
" >&2
}

print_status_bar() {
  [ "${QUIET:-0}" -eq 1 ] && return 0
  local stream_status="Disabilitato"
  if [ "${STREAM_MODE:-0}" -eq 1 ]; then stream_status="Attivo"; fi
  
  printf '%b' "
  ${C_BCYAN}[STATO REPL]${C_RST} Sessione: ${C_BOLD}${SESSION_ID:-none}${C_RST} | LLM: ${C_GREEN}${MODEL:-default}${C_RST} | Temp: ${C_YELLOW}${TEMPERATURE:-1.0}${C_RST} | Stream: ${C_BOLD}${stream_status}${C_RST}
" >&2
}
# =============================================================================
# FASE 6: IMPLEMENTAZIONE WIZARD DI AVVIO PAGINATO (SELEZIONE SESSIONI)
# =============================================================================
_format_ts() {
  local ts="${1:-}"
  if [ -n "$ts" ]; then
    # Converte il formato ISO8601 (YYYY-MM-DDTHH:MM:SSZ) in YYYY-MM-DD HH:MM
    printf '%s %s' "${ts:0:10}" "${ts:11:5}"
  else
    printf 'N/A'
  fi
}

load_sessions_wizard() {
  local session_dir="${BASH4LLM_HISTORY_DIR}/sessions"
  safe_mkdir "$session_dir" 700

  # Recupero dell'elenco dei file .ndjson esistenti ordinati per mtime decrescente (i più recenti prima)
  local -a files=()
  local mtime f
  while IFS='|' read -r mtime f; do
    if [ -f "$f" ] && [ "${f##*.}" = "ndjson" ]; then
      files+=("$f")
    fi
  done < <(list_files_sorted_by_mtime "$session_dir" | tac_fallback)

  local total_sessions="${#files[@]}"

  # Se non ci sono sessioni sul disco, saltiamo il wizard inizializzandone una nuova
  if [ "$total_sessions" -eq 0 ]; then
    SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
    local new_sess_file="${session_dir}/${SESSION_ID}.ndjson"
    : > "$new_sess_file"
    chmod 600 "$new_sess_file"
    log_info_user "TUI" "Nessuna sessione trovata. Inizializzata nuova sessione: ${SESSION_ID}"
    return 0
  fi

  # Parametri di paginazione
  local page_size=10
  local current_page=0
  local total_pages=$(( (total_sessions + page_size - 1) / page_size ))

  while true; do
    if [ -t 1 ]; then
      clear 2>/dev/null || printf '\033[H\033[2J' >&2
    fi

    printf '%b' "
${C_LOGO}  SELEZIONE DI SESSIONE PREGRESSA  ${C_RST}
  Pagina: ${C_BOLD}$((current_page + 1)) di ${total_pages}${C_RST} (Totale sessioni: ${total_sessions})
  --------------------------------------------------------------------------------
" >&2

    local start_idx=$((current_page * page_size))
    local end_idx=$((start_idx + page_size))
    [ "$end_idx" -gt "$total_sessions" ] && end_idx="$total_sessions"

    # Rendering sequenziale della riga per ciascuna sessione
    local i
    for ((i = start_idx; i < end_idx; i++)); do
      local s_file="${files[i]}"
      local s_id
      s_id="$(basename "$s_file" .ndjson)"

      # Estrazione data creazione (prima riga)
      local first_line creation_ts creation_date
      first_line="$(head -n 1 "$s_file" 2>/dev/null || true)"
      creation_ts="$(printf '%s' "$first_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      creation_date="$(_format_ts "$creation_ts")"

      # Estrazione del Titolo registrato nel database UI o ricavato dal primo messaggio
      local meta_file title
      meta_file="${BASH4LLM_CONFIG_DIR}/ui_state/sessions/${s_id}.json"
      title=""
      if [ -f "$meta_file" ]; then
        title="$(jq -r '.title // empty' "$meta_file" 2>/dev/null || true)"
      fi
      if [ -z "$title" ] && [ -f "$s_file" ]; then
        title="$(jq -r 'select(.role=="user") | .content' "$s_file" 2>/dev/null | head -n 1 | tr -d '\n\r' | cut -c 1-35 || true)"
      fi
      [ -n "$title" ] || title="Session ${s_id:0:8}"

      # Estrazione data ultimo messaggio (ultima riga)
      local last_line last_ts last_date
      last_line="$(tail -n 1 "$s_file" 2>/dev/null || true)"
      last_ts="$(printf '%s' "$last_line" | jq -r '.ts // empty' 2>/dev/null || true)"
      last_date="$(_format_ts "$last_ts")"

      # Stampa riga formattata in modo sequenziale compatibile
      printf '  ${C_BCYAN}[%2d]${C_RST} %s ${C_CYAN}>${C_RST} %-35s ${C_CYAN}>${C_RST} %s\n' \
        "$((i + 1))" "$creation_date" "$title" "$last_date" >&2
    done

    printf '%b' "
  --------------------------------------------------------------------------------
  Opzioni di navigazione:
  ${C_BGREEN} [ + / n ] ${C_RST} Pagina Succ.      | ${C_BGREEN} [ - / p ] ${C_RST} Pagina Prec.
  ${C_BGREEN} [   c   ] ${C_RST} Nuova Sessione     | ${C_BGREEN} [   q   ] ${C_RST} Esci REPL
  --------------------------------------------------------------------------------
" >&2

    # Lettura dell'input di controllo dell'utente
    local choice
    printf '  Inserisci un numero d'\''indice o un comando d'\''opzione: ' >&2
    IFS= read -r choice || { printf '\n' >&2; exit 0; }
    choice="$(printf '%s' "$choice" | awk '{$1=$1;print}')"

    case "$choice" in
      + | n | N)
        current_page=$(( (current_page + 1) % total_pages ))
        ;;
      - | p | P)
        current_page=$(( (current_page - 1 + total_pages) % total_pages ))
        ;;
      c | C | new | NEW)
        SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_sess_file="${session_dir}/${SESSION_ID}.ndjson"
        : > "$new_sess_file"
        chmod 600 "$new_sess_file"
        break
        ;;
      q | Q | exit | EXIT)
        printf '\nExited.\n' >&2
        exit 0
        ;;
      *)
        if printf '%s\n' "$choice" | grep -qE '^[0-9]+$'; then
          local target_idx=$((choice - 1))
          if [ "$target_idx" -ge 0 ] && [ "$target_idx" -lt "$total_sessions" ]; then
            local selected_file="${files[target_idx]}"
            SESSION_ID="$(basename "$selected_file" .ndjson)"
            break
          else
            printf '\n  %sIndice fuori intervallo!%s Riprova.\n' "${C_RED:-}" "${C_RST:-}" >&2
            sleep 1
          fi
        else
          printf '\n  %sComando non valido!%s Inserisci l'\''indice o l'\''opzione corrispondente.\n' "${C_RED:-}" "${C_RST:-}" >&2
          sleep 1
        fi
        ;;
    esac
  done

  # Pulizia visiva finale dello schermo all'uscita dal wizard prima dell'avvio della chat
  if [ -t 1 ]; then
    clear 2>/dev/null || printf '\033[H\033[2J' >&2
  fi
  return 0
}
# =============================================================================
# FASE 7: INTERFACCIA INTERATTIVA DI CONFIGURAZIONE (/config e /menu)
# =============================================================================
show_config_menu() {
  while true; do
    printf '%b' "
  ${C_LOGO}  MENU DI CONFIGURAZIONE  ${C_RST}
  1) Cambia Provider Attivo (Attuale: ${C_YELLOW}${PROVIDER:-groq}${C_RST})
  2) Cambia Modello LLM     (Attuale: ${C_YELLOW}${MODEL:-default}${C_RST})
  3) Gestisci Chiave API    (env: ${C_YELLOW}$(provider_api_env_var_name "${PROVIDER:-groq}")${C_RST})
  4) Esegui Refresh dei Modelli (Chiamata di rete API)
  5) Elenca Modelli Installati Localmente
  6) Chiudi menu e torna alla chat
" >&2
    local m_sel
    printf '  Scegli un'\''opzione (1-6): ' >&2
    IFS= read -r m_sel || return 0
    m_sel="$(trim "$m_sel")"

    case "$m_sel" in
      1)
        printf '\n  Provider installati: %s\n' "$SUPPORTED_PROVIDERS" >&2
        printf '  Inserisci nome provider: ' >&2
        local new_prov
        IFS= read -r new_prov || continue
        new_prov="$(trim "$new_prov")"
        if [ -n "$new_prov" ]; then
          case " $SUPPORTED_PROVIDERS " in
            *" $new_prov "*)
              PROVIDER="$new_prov"
              load_provider_module "$PROVIDER" >/dev/null 2>&1 || true
              resolve_provider_url "$PROVIDER" >/dev/null 2>&1 || true
              # Reset modello al default per evitare conflitti tra provider diversi
              resolve_model >/dev/null 2>&1 && MODEL="${FINAL_MODEL:-default}"
              printf '\n  %sProvider impostato su %s.%s\n' "${C_GREEN:-}" "$PROVIDER" "${C_RST:-}" >&2
              ;;
            *) printf '\n  %sProvider sconosciuto!%s\n' "${C_RED:-}" "${C_RST:-}" >&2 ;;
          esac
        fi
        ;;
      2)
        printf '\n  Inserisci il nome del nuovo modello: ' >&2
        local new_model
        IFS= read -r new_model || continue
        new_model="$(trim "$new_model")"
        if [ -n "$new_model" ]; then
          if validate_model_dispatch "$new_model" >/dev/null 2>&1; then
            MODEL="$new_model"
            printf '\n  %sModello impostato su: %s%s\n' "${C_GREEN:-}" "$MODEL" "${C_RST:-}" >&2
          else
            printf '\n  %sModello non valido o non registrato.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
          fi
        fi
        ;;
      3)
        local key_var
        key_var="$(provider_api_env_var_name "${PROVIDER:-groq}")"
        printf '\n  Configura chiave per: %s (Attuale: %s)\n' "$key_var" "${!key_var:-<non impostata>}" >&2
        printf '  Inserisci la nuova chiave API: ' >&2
        local new_key
        IFS= read -r new_key || continue
        new_key="$(trim "$new_key")"
        if [ -n "$new_key" ]; then
          export "${key_var}=${new_key}"
          if [ "${PROVIDER:-groq}" = "groq" ]; then export GROQ_API_KEY="$new_key"; fi
          printf '\n  %sChiave API aggiornata con successo.%s\n' "${C_GREEN:-}" "${C_RST:-}" >&2
        fi
        ;;
      4)
        printf '\n  Avvio scaricamento elenco modelli in corso...\n' >&2
        if ensure_api_key_for_provider "$PROVIDER"; then
          if refresh_models_dispatch; then
            printf '\n  %sElenco modelli aggiornato con successo.%s\n' "${C_GREEN:-}" "${C_RST:-}" >&2
          else
            printf '\n  %sErrore nel refresh dei modelli.%s\n' "${C_RED:-}" "${C_RST:-}" >&2
          fi
        fi
        ;;
      5)
        printf '\n  --- Modelli Installati (%s) ---\n' "$PROVIDER" >&2
        list_models_cli || true
        printf '  -----------------------------\n' >&2
        ;;
      6 | q | Q | "")
        return 0
        ;;
      *)
        printf '\n  %sOpzione non valida!%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

show_tools_menu() {
  while true; do
    printf '%b' "
  ${C_LOGO}  MENU DI CONTESTO (STRUMENTI)  ${C_RST}
  1) Rinomina Sessione Attiva  (Attuale: ${C_YELLOW}${SESSION_ID:-none}${C_RST})
  2) Cancella Sessione Attiva  (Verranno rimossi i file su disco)
  3) Avvia Nuova Sessione      (Genera nuova sessione vuota)
  4) Toggle Streaming Risposta (Stato streaming: ${C_YELLOW}${STREAM_MODE:-0}${C_RST})
  5) Visualizza Informazioni di Stato e Diagnostica Completa
  6) Chiudi menu e torna alla chat
" >&2
    local m_sel
    printf '  Scegli un'\''opzione (1-6): ' >&2
    IFS= read -r m_sel || return 0
    m_sel="$(trim "$m_sel")"

    case "$m_sel" in
      1)
        printf '\n  Inserisci nuovo titolo per la sessione: ' >&2
        local new_title
        IFS= read -r new_title || continue
        new_title="$(trim "$new_title")"
        if [ -n "$new_title" ]; then
          session_rename_core "$SESSION_ID" "$new_title"
          printf '\n  %sSessione rinominata con successo.%s\n' "${C_GREEN:-}" "${C_RST:-}" >&2
        fi
        ;;
      2)
        printf '\n  %sATTENZIONE:%s Sei sicuro di voler cancellare la sessione %s? [y/N]: ' "${C_RED:-}" "${C_RST:-}" "$SESSION_ID" >&2
        local confirm
        IFS= read -r confirm || continue
        confirm="$(trim "$confirm")"
        if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
          session_delete_core "$SESSION_ID"
          printf '\n  %sSessione eliminata.%s Riavvio del wizard in corso...\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
          sleep 1
          load_sessions_wizard
          return 0
        else
          printf '\n  Cancellazione annullata.\n' >&2
        fi
        ;;
      3)
        SESSION_ID="repl-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
        local new_sess_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
        : > "$new_sess_file"
        chmod 600 "$new_sess_file"
        printf '\n  %sNuova sessione vuota creata: %s%s\n' "${C_GREEN:-}" "$SESSION_ID" "${C_RST:-}" >&2
        return 0
        ;;
      4)
        if [ "${STREAM_MODE:-0}" -eq 1 ]; then
          STREAM_MODE=0
          printf '\n  %sStreaming disabilitato.%s Risposte non-stream attive.\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
        else
          STREAM_MODE=1
          printf '\n  %sStreaming abilitato.%s Generazione in tempo reale attiva.\n' "${C_GREEN:-}" "${C_RST:-}" >&2
        fi
        ;;
      5)
        printf '\n  --- STATO COMPLETO ---' >&2
        print_status_bar
        printf '  File di sessione NDJSON: %s/sessions/%s.ndjson\n' "$BASH4LLM_HISTORY_DIR" "$SESSION_ID" >&2
        printf '  File di configurazione:  %s/config\n' "$BASH4LLM_CONFIG_DIR" >&2
        printf '  File di log storico TUI: %s\n' "$HISTFILE" >&2
        printf '  ----------------------\n' >&2
        ;;
      6 | q | Q | "")
        return 0
        ;;
      *)
        printf '\n  %sOpzione non valida!%s\n' "${C_RED:-}" "${C_RST:-}" >&2
        ;;
    esac
  done
}

# =============================================================================
# FASE 8: CICLO REPL INTERATTIVO DI CHAT PRINCIPALE
# =============================================================================
run_repl() {
  # Se non è stata configurata una sessione attiva ereditata, carichiamo il wizard
  if [ -z "$SESSION_ID" ]; then
    load_sessions_wizard
  fi

  print_banner
  print_status_bar

  local prompt_str="${C_BCYAN}Tu > ${C_RST}"

  # Disattiviamo strict mode limitatamente all'interazione dell'utente per evitare crash impropri
  set +e 2>/dev/null || true
  set +u 2>/dev/null || true

  while true; do
    # Visualizzazione statico "Tu:" per compatibilità o riga standard Readline
    local userline=""
    IFS= read -r -e -p "$prompt_str" userline
    local read_rc=$?

    # Intercettazione della combinazione Ctrl+D (EOF) o fallimenti di lettura
    if [ "$read_rc" -ne 0 ]; then
      if [ "$read_rc" -eq 130 ]; then
        # Ctrl+C digitato nel prompt: andiamo semplicemente a capo e rigeneriamo il ciclo
        printf '\n' >&2
        continue
      fi
      printf '\nExited.\n' >&2
      break
    fi

    userline="$(trim "$userline")"
    [ -z "$userline" ] && continue

    # Registrazione della linea nel file di history isolato
    history -s "$userline" 2>/dev/null || true
    history -w "$HISTFILE" 2>/dev/null || true

    # Parser dei comandi Slash speciali
    case "$userline" in
      /exit | /quit)
        break
        ;;
      /clear)
        if [ -t 1 ]; then
          clear 2>/dev/null || printf '\033[H\033[2J' >&2
        fi
        print_banner
        print_status_bar
        continue
        ;;
      /help | /\?)
        printf '%b' "
${C_BCYAN}  Comandi disponibili nella TUI:${C_RST}
  ${C_BGREEN}/help${C_RST}, ${C_BGREEN}/?${C_RST}             - Visualizza questo menu di guida
  ${C_BGREEN}/exit${C_RST}, ${C_BGREEN}/quit${C_RST}          - Esci dalla TUI interattiva salvando lo stato
  ${C_BGREEN}/clear${C_RST}                - Pulisce visivamente lo schermo (non distruttivo)
  ${C_BGREEN}/reset-session${C_RST}        - Svuota interamente la cronologia della sessione NDJSON
  ${C_BGREEN}/history [N]${C_RST}          - Sfoglia gli ultimi N messaggi nel pager (default 20, o -all)
  ${C_BGREEN}/config${C_RST}               - Menu di gestione configurazioni LLM, provider e chiavi API
  ${C_BGREEN}/menu${C_RST}                 - Menu di contesto per sessioni, rinomine e parametri
" >&2
        continue
        ;;
      /reset-session)
        printf '\n  %sSICUREZZA:%s Sei sicuro di voler azzerare la sessione attiva? [y/N]: ' "${C_RED:-}" "${C_RST:-}" >&2
        local confirm
        IFS= read -r confirm
        confirm="$(trim "$confirm")"
        if [[ "$confirm" =~ ^[yY](es|ES)?$ ]]; then
          local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"
          : > "$session_file" 2>/dev/null
          session_cache_invalidate "$SESSION_ID" >/dev/null 2>/dev/null || true
          printf '\n  %sSessione azzerata con successo (cronologia svuotata).%s\n\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
        else
          printf '\n  Azione annullata.\n\n' >&2
        fi
        continue
        ;;
      /history | /history\ *)
        local opt="${userline#/history}"
        opt="$(trim "$opt")"
        local session_file="${BASH4LLM_HISTORY_DIR}/sessions/${SESSION_ID}.ndjson"

        if [ ! -f "$session_file" ] || [ ! -s "$session_file" ]; then
          printf '\n  %sLa cronologia di questa sessione è attualmente vuota.%s\n\n' "${C_YELLOW:-}" "${C_RST:-}" >&2
          continue
        fi

        local lines_to_read=40
        local print_alert=0
        if [ -z "$opt" ]; then
          lines_to_read=40 # 20 messaggi default (10 turni utente-assistente)
          print_alert=1
        elif [ "$opt" = "-all" ]; then
          lines_to_read=999999
        elif printf '%s\n' "$opt" | grep -qE '^[0-9]+$'; then
          lines_to_read=$(( opt * 2 ))
        else
          printf '  Sintassi comando non valida. Usa: /history [N] o /history -all\n' >&2
          continue
        fi

        local tmp_hist
        tmp_hist="$(_tmpf file "$RUN_TMPDIR" hist_preview 2>/dev/null)"
        if [ -n "$tmp_hist" ]; then
          if [ "$print_alert" -eq 1 ]; then
            printf '[Visualizzazione degli ultimi 20 messaggi. Digita "/history -all" per leggerli tutti]\n\n' > "$tmp_hist"
          fi

          tail -n "$lines_to_read" "$session_file" | while IFS= read -r line || [ -n "$line" ]; do
            local role content role_color
            role="$(printf '%s' "$line" | jq -r '.role // empty' 2>/dev/null)"
            content="$(printf '%s' "$line" | jq -r '.content // empty' 2>/dev/null)"
            if [ "$role" = "user" ]; then
              printf '%sTu >%s\n%s\n\n' "${C_BCYAN:-}" "${C_RST:-}" "$content" >> "$tmp_hist"
            elif [ "$role" = "assistant" ]; then
              printf '%s%s - %s >%s\n%s\n\n' "${C_BGREEN:-}" "$PROVIDER" "$MODEL" "${C_RST:-}" "$content" >> "$tmp_hist"
            fi
          done

          if command -v less >/dev/null 2>&1; then
            less -R "$tmp_hist"
          else
            cat "$tmp_hist" | head -n 100
          fi
          rm -f "$tmp_hist" 2>/dev/null || true
        fi
        continue
        ;;
      /config)
        show_config_menu
        continue
        ;;
      /menu)
        show_tools_menu
        continue
        ;;
      /*)
        printf '  %sComando slash sconosciuto!%s Digita /help per la legenda.\n' "${C_RED:-}" "${C_RST:-}" >&2
        continue
        ;;
    esac

    # Se siamo qui, si tratta di una query standard da inviare alle API
    CONTENT="$userline"

    # 1. Configurazione contesto della sessione attiva (compilazione cronologia)
    BUILD_MESSAGES_FILE="$RUN_TMPDIR/session-${SESSION_ID}-messages.json"
    export BUILD_MESSAGES_FILE

    if [ "${SE_AVAILABLE:-0}" -eq 1 ]; then
      session_engine_build_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "${BASH4LLM_SESSION_TARGET_BYTES:-}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 \
        || session_read_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    else
      session_read_window "$SESSION_ID" "${SESSION_WINDOW:-10}" "$BUILD_MESSAGES_FILE" >/dev/null 2>&1 || true
    fi

    # 2. Generazione payload strutturato JSON
    if ! build_payload_from_vars >/dev/null 2>&1; then
      log_error "TUI" "Errore nella compilazione strutturata del payload JSON."
      continue
    fi

    # 3. Validazione delle credenziali prima di procedere
    if ! ensure_api_key_for_provider "$PROVIDER"; then
      log_error "APIKEY" "Chiave d'accesso API non presente per il provider $PROVIDER."
      continue
    fi

    # 4. Intestazione visiva della risposta a capo
    printf '\n%s%s - %s:%s\n' "${C_BGREEN:-}" "$PROVIDER" "$MODEL" "${C_RST:-}" >&2

    # 5. Invocazione sincrona in streaming o non-streaming con protezione dei segnali
    IS_STREAMING=1
    local call_rc=0
    if [ "${STREAM_MODE:-0}" -eq 1 ]; then
      call_api_streaming
      call_rc=$?
    else
      perform_request_once
      call_rc=$?
    fi
    IS_STREAMING=0

    # 6. Salvataggio della conversazione nello storico NDJSON su disco
    if [ "$call_rc" -eq 0 ] && [ "${DRY_RUN:-0}" -ne 1 ]; then
      local meta_source="cli"
      local meta_cmd="$(session_sanitize_cmd "$0")"
      local meta_json
      meta_json="$(jq -c -n --arg source "$meta_source" --arg cmd "$meta_cmd" --arg id "" '{source:$source, cmd:$cmd, id:$id}')"

      # Append messaggio Utente
      if [ "${SE_AVAILABLE:-0}" -eq 1 ]; then
        session_engine_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 \
          || session_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      else
        session_append "$SESSION_ID" "user" "$CONTENT" "$meta_json" >/dev/null 2>&1 || true
      fi

      # Lettura, estrazione ed append della risposta Assistente
      if [ -s "${RESP:-}" ]; then
        local assistant_text
        assistant_text="$(extract_text_from_resp 2>/dev/null || true)"
        assistant_text="$(printf '%s' "$assistant_text" | sed -e 's/\r$//' -e '/^[[:space:]]*$/d' || true)"
        if [ -n "$assistant_text" ]; then
          meta_source="provider"
          meta_json="$(jq -c -n --arg source "$meta_source" --arg model "$MODEL" --arg id "" '{source:$source, model:$model, id:$id}')"

          if [ "${SE_AVAILABLE:-0}" -eq 1 ]; then
            session_engine_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 \
              || session_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          else
            session_append "$SESSION_ID" "assistant" "$assistant_text" "$meta_json" >/dev/null 2>&1 || true
          fi
        fi
      fi
    fi

    # Reset per il turno successivo
    unset CONTENT
    printf '\n' >&2
  done

  # Ripristino echo standard del terminale all'uscita dal REPL
  stty echo 2>/dev/null || true
  return 0
}

# =============================================================================
# INGRESSO OPERATIVO
# =============================================================================
run_repl

cleanup_run_tmp_on_exit
exit 0
