#!/usr/bin/env bash
# =============================================================================
# groqbash-tui.sh - GroqBash TUI Versione 0.8 fixed6
# File: groqbash-tui.sh
# Autore: Cristian Evangelisti (modificato)
# License: GPL-3.0-or-later
# =============================================================================
# - Requisiti minimi: bash (>=4 consigliato), coreutils, flock, awk, timeout (opzionale)
# - Vincoli rispettati: Bash-only, nessun eval, nessun uso di /tmp di sistema (usa TMPDIR/$HOME/tmp), atomic_write obbligatorio.
# =============================================================================

# -------------------- CONFIG / COLORI --------------------------------------
DEBUG="${DEBUG:-0}"
LOGFILE="${TMPDIR:-$HOME/tmp}/groq-tui.log"

BG="\e[48;2;255;255;240m"
FG="\e[38;2;51;51;51m"
TITLE="\e[38;2;93;133;8m"
BORDER="\e[38;2;85;85;85m"
USER_COL="\e[1;38;2;30;30;120m"
AI_COL="\e[1;38;2;8;100;40m"
RESET="\e[0m"

TL="╭"; TR="╮"; BL="╰"; BR="╯"; HL="─"; VL="│"

BASE_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
CFG_DIR="$BASE_DIR/config"
CONV_DIR="$BASE_DIR/conversations"
CURRENT_CONV_FILE="$CFG_DIR/current-conversation"
DEFAULT_MODEL_FILE="$CFG_DIR/default-model"
DEFAULT_PROVIDER_FILE="$CFG_DIR/default-provider"
LANG_CURRENT_FILE="$CFG_DIR/lang-current"
GROQBASH_CMD="groqbash"

# -------------------- GLOBAL STATE ------------------------------------------
TERM_ROWS=24
TERM_COLS=80
running=1
mode="main"
conversation=()

declare -a visual_lines
declare -a visual_msg_idx
declare -a visual_msg_off

scroll_pos=0
visible_rows=0

panel_width=0
panel_inner_w=0

declare -a prompt_lines
prompt_row=0
prompt_col=0
multiline_mode=0
history=()
history_index=-1

model="default"
provider="default"
lang="it"
conv_name="conv-001.txt"
conv_path=""

spinner_frames=("|" "/" "-" "\\")
spinner_index=0

settings_fields=("Modello" "Provider" "Lingua" "Conversazione")
settings_index=0
settings_editing=0
settings_input=""

declare -a conv_snapshot

conversation_changed=1
conv_mtime=0
resize_flag=0
last_resize_ts=0
last_reload_check_ms=0

MAX_LINES_IN_MEMORY=5000
MAX_NAME_LEN=64

declare -a msg_cached_raw
declare -a msg_cached_wrapped

conversation_truncated=0

# -------------------- UTILITIES / LOGGING -----------------------------------
log_debug() {
  if [[ "${DEBUG}" -eq 1 ]]; then
    mkdir -p "$(dirname -- "$LOGFILE")" 2>/dev/null || true
    printf "%s %s\n" "$(date +"%F %T")" "$*" >> "$LOGFILE"
  fi
}

ensure_dirs() { mkdir -p "$CFG_DIR" "$CONV_DIR" "$(dirname -- "$LOGFILE")"; }

read_config_or_default() {
  local f="$1" d="$2"
  if [[ -r "$f" ]]; then
    head -n1 "$f"
  else
    printf "%s" "$d"
  fi
}

timestamp_now() { date +"%H:%M"; }

clear_screen() { printf "\e[2J\e[H"; }

# -------------------- TERMINAL SIZE ----------------------------------------
get_term_size() {
  TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
  TERM_COLS=$(tput cols 2>/dev/null || echo 80)
  TERM_ROWS=${TERM_ROWS:-24}
  TERM_COLS=${TERM_COLS:-80}
  log_debug "get_term_size: rows=$TERM_ROWS cols=$TERM_COLS"
}

# -------------------- ATOMIC WRITE / MKTEMP PORTABLE -------------------------
mktemp_portable() {
  local dest_dir="$1"
  local tmp
  mkdir -p "$dest_dir" || return 1
  if command -v mktemp >/dev/null 2>&1; then
    tmp="$(mktemp "${dest_dir}/groqtmp.XXXXXX" 2>/dev/null)" || tmp="${dest_dir}/groqtmp.$$.$RANDOM"
  else
    tmp="${dest_dir}/groqtmp.$$.$RANDOM"
  fi
  : > "$tmp" 2>/dev/null || return 1
  chmod 600 "$tmp" 2>/dev/null || true
  printf "%s" "$tmp"
}

atomic_write() {
  local dest="$1" content="$2"
  local dest_dir tmp rc=0
  dest_dir="$(dirname -- "$dest")"
  tmp="$(mktemp_portable "$dest_dir")" || { log_debug "atomic_write: mktemp failed for $dest"; return 1; }
  printf "%s" "$content" > "$tmp" 2>/dev/null || rc=$?
  if [[ $rc -ne 0 ]]; then
    log_debug "atomic_write: write to tmp failed ($tmp)"
    rm -f "$tmp"
    return 2
  fi
  mv -f "$tmp" "$dest" 2>/dev/null || { log_debug "atomic_write: mv failed $tmp -> $dest"; rm -f "$tmp"; return 3; }
  return 0
}

# -------------------- SANITIZE / NORMALIZE ----------------------------------
sanitize_param() {
  local s="${1:-}"
  printf "%s" "$s" | tr '\t' ' ' | sed -E 's/[\x00-\x08\x0B\x0C\x0E-\x1F]//g' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
}

normalize_conv_name() {
  local name="$1"
  name="$(printf "%s" "$name" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | tr -s '[:space:]' ' ')"
  if [[ -z "$name" || "${name:0:1}" == "." || "$name" == *"/"* ]]; then return 1; fi
  if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then return 1; fi
  if (( ${#name} > MAX_NAME_LEN )); then return 1; fi
  printf "%s" "$name"
}

# -------------------- STRIP ANSI ---------------------------------------------
strip_ansi() {
  sed -E 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g'
}

# -------------------- SANITIZE OUTPUT (groqbash) ----------------------------
MAX_MODEL_OUTPUT_CHARS=20000
sanitize_output() {
  local s="$1"
  s="$(printf "%s" "$s" | tr '\r' '\n' | tr -d '\000-\010\013\014\016-\037')"
  if (( ${#s} > MAX_MODEL_OUTPUT_CHARS )); then
    s="${s:0:MAX_MODEL_OUTPUT_CHARS}"
    s="${s%$'\n'}"
  fi
  printf "%s" "$s"
}

# -------------------- WRAPPING con AWK (multibyte-aware, long-word split) ---
wrap_awk() {
  local width="$1"
  awk -v W="$width" '
  BEGIN { OFS=""; }
  {
    gsub(/\t/, " ")
    gsub(/\r/, "")
    line = $0
    n = split(line, words, /[ ]+/)
    out = ""
    for (i = 1; i <= n; i++) {
      w = words[i]
      while (length(w) > W) {
        if (out != "") { print out; out = "" }
        print substr(w,1,W)
        w = substr(w, W+1)
      }
      if (out == "") {
        out = w
      } else if (length(out " " w) <= W) {
        out = out " " w
      } else {
        print out
        out = w
      }
    }
    if (out != "") print out
  }'
}

# -------------------- CONFIG / CONVERSATION IO ------------------------------
load_config() {
  conv_name="$(read_config_or_default "$CURRENT_CONV_FILE" "conv-001.txt")"
  model="$(read_config_or_default "$DEFAULT_MODEL_FILE" "default")"
  provider="$(read_config_or_default "$DEFAULT_PROVIDER_FILE" "default")"
  lang="$(read_config_or_default "$LANG_CURRENT_FILE" "it")"
  conv_path="$CONV_DIR/$conv_name"
}

save_config() {
  atomic_write "$CURRENT_CONV_FILE" "$conv_name"
  atomic_write "$DEFAULT_MODEL_FILE" "$model"
  atomic_write "$DEFAULT_PROVIDER_FILE" "$provider"
  atomic_write "$LANG_CURRENT_FILE" "$lang"
}

load_conversation() {
  conversation=()
  conversation_truncated=0
  if [[ -f "$conv_path" ]]; then
    local total
    total=$(wc -l < "$conv_path" 2>/dev/null || echo 0)
    if (( total > MAX_LINES_IN_MEMORY )); then
      tail -n "$MAX_LINES_IN_MEMORY" "$conv_path" | while IFS= read -r line; do conversation+=("$line"); done
      conversation_truncated=1
    else
      while IFS= read -r line; do conversation+=("$line"); done < "$conv_path"
    fi
  fi
  msg_cached_raw=()
  msg_cached_wrapped=()
  for ((i=0;i<${#conversation[@]};i++)); do msg_cached_raw[i]=""; msg_cached_wrapped[i]=""; done
  conversation_changed=1
  # set conv_mtime to current file mtime to avoid immediate reload loops
  if stat_mtime="$(get_file_mtime "$conv_path")"; then conv_mtime="$stat_mtime"; fi
}

# -------------------- APPEND with robust flock pattern ----------------------
append_conversation() {
  local line="$1"
  local ts
  ts="$(timestamp_now)"
  local stored="${line}|||${ts}"

  # ensure file exists but do NOT truncate it
  mkdir -p "$(dirname -- "$conv_path")" 2>/dev/null || true
  [[ -f "$conv_path" ]] || : > "$conv_path" || { log_debug "append_conversation: cannot create $conv_path"; return 1; }

  exec 9>>"$conv_path" || { log_debug "append_conversation: open fd failed"; return 2; }
  if ! flock -x 9; then log_debug "append_conversation: flock failed"; exec 9>&-; return 3; fi
  if ! printf "%s\n" "$stored" >&9; then log_debug "append_conversation: write failed"; flock -u 9; exec 9>&-; return 4; fi
  flock -u 9
  exec 9>&-

  conversation+=("$stored")
  msg_cached_raw+=("")
  msg_cached_wrapped+=("")
  conversation_changed=1

  if stat_mtime="$(get_file_mtime "$conv_path")"; then conv_mtime="$stat_mtime"; fi

  return 0
}

# -------------------- STAT FALLBACK / reload_if_changed ---------------------
get_file_mtime() {
  local f="$1"
  local m

  [[ -f "$f" ]] || return 1

  # try GNU stat
  m=$(stat -c %Y "$f" 2>/dev/null)
  if [[ $? -eq 0 && -n "$m" ]]; then
    printf "%s" "$m"
    return 0
  fi

  # try BSD stat
  m=$(stat -f %m "$f" 2>/dev/null)
  if [[ $? -eq 0 && -n "$m" ]]; then
    printf "%s" "$m"
    return 0
  fi

  # both stat variants failed: return failure (no external deps)
  return 1
}

reload_if_changed() {
  # debounce: avoid stat checks too frequently (ms)
  local now_ms
  now_ms=$(date +%s%3N 2>/dev/null || printf "%s000" "$(date +%s)")
  if [[ -z "${last_reload_check_ms:-}" ]]; then last_reload_check_ms=0; fi
  if (( now_ms - last_reload_check_ms < 200 )); then
    return 0
  fi
  last_reload_check_ms=$now_ms

  if [[ ! -f "$conv_path" ]]; then return 0; fi
  local m
  if ! m="$(get_file_mtime "$conv_path")"; then
    m=0
  fi
  # if m is empty or equal to conv_mtime, nothing to do
  if [[ -z "$m" || "$m" == "$conv_mtime" ]]; then
    return 0
  fi

  if command -v flock >/dev/null 2>&1; then
    exec 9<"$conv_path"
    flock -s 9
    conversation=()
    while IFS= read -r line <&9; do conversation+=("$line"); done
    flock -u 9
    exec 9<&-
  else
    load_conversation
  fi
  msg_cached_raw=()
  msg_cached_wrapped=()
  for ((i=0;i<${#conversation[@]};i++)); do msg_cached_raw[i]=""; msg_cached_wrapped[i]=""; done
  conv_mtime="$m"
  conversation_changed=1
}

# -------------------- GROQBASH CALL (stderr -> log, timeout, sanitize) ------
run_groqbash() {
  local prompt="$1"
  local cmd=( "$GROQBASH_CMD" )
  if [[ -n "$provider" && "$provider" != "default" ]]; then
    cmd+=("--provider" "$provider")
    if [[ -n "$model" && "$model" != "default" ]]; then cmd+=("--model" "$model"); fi
  else
    if [[ -n "$model" && "$model" != "default" ]]; then cmd+=("--model" "$model"); fi
  fi

  local logdir="${TMPDIR:-$HOME/tmp}/groq-tui-logs"
  mkdir -p "$logdir" 2>/dev/null || true
  local stderr_log
  stderr_log="$(mktemp "${logdir}/groqbash-stderr.XXXX" 2>/dev/null)" || stderr_log="/dev/null"
  chmod 600 "$stderr_log" 2>/dev/null || true

  local output=""
  if command -v timeout >/dev/null 2>&1; then
    output="$(printf "%s" "$prompt" | timeout 30 "${cmd[@]}" 2> "$stderr_log")"
    local rc=$?
    if [[ $rc -eq 124 ]]; then
      log_debug "run_groqbash: timeout"
      [[ -s "$stderr_log" ]] && log_debug "groqbash stderr: $(head -c 4096 "$stderr_log" 2>/dev/null)"
      rm -f "$stderr_log"
      printf "%s" "[timeout]"
      return 124
    fi
    if [[ $rc -ne 0 ]]; then
      log_debug "run_groqbash: exit $rc"
      [[ -s "$stderr_log" ]] && log_debug "groqbash stderr: $(head -c 4096 "$stderr_log" 2>/dev/null)"
      rm -f "$stderr_log"
      printf "%s" "[error]"
      return $rc
    fi
  else
    output="$(printf "%s" "$prompt" | "${cmd[@]}" 2> "$stderr_log")"
    local rc=$?
    if (( rc != 0 )); then
      log_debug "run_groqbash: exit $rc (no timeout)"
      [[ -s "$stderr_log" ]] && log_debug "groqbash stderr: $(head -c 4096 "$stderr_log" 2>/dev/null)"
      rm -f "$stderr_log"
      printf "%s" "[error]"
      return $rc
    fi
  fi

  if [[ -s "$stderr_log" ]]; then
    if [[ "${DEBUG}" -eq 1 ]]; then
      log_debug "groqbash stderr saved to $stderr_log"
    else
      rm -f "$stderr_log"
    fi
  fi

  if [[ -z "$output" ]]; then
    printf "%s" "[no response]"
  else
    sanitize_output "$output"
  fi
}

# -------------------- TERMINAL / INPUT / CLEANUP ----------------------------
orig_stty=""
enter_raw_mode() {
  orig_stty="$(stty -g 2>/dev/null || true)"
  stty -echo -icanon time 0 min 0 2>/dev/null || stty -echo -icanon
  printf "\e[?25l"
}
exit_raw_mode() {
  printf "\e[?25h"
  [[ -n "$orig_stty" ]] && stty "$orig_stty" 2>/dev/null || stty sane
}
cleanup() {
  exit_raw_mode
  printf "\n"
  log_debug "cleanup called"
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' EXIT

read_key() {
  local key rest ch i
  if ! IFS= read -rsn1 -t 0.08 key 2>/dev/null; then printf ""; return; fi
  if [[ $key == $'\e' ]]; then
    rest=""
    for i in 1 2 3 4 5; do
      if IFS= read -rsn1 -t 0.005 ch 2>/dev/null; then rest+="$ch"; else break; fi
    done
    printf "%s" "$key$rest"
  else
    printf "%s" "$key"
  fi
}

# -------------------- MOVE CURSOR (prompt) ----------------------------------
move_cursor_right() {
  local line="${prompt_lines[prompt_row]}"
  if (( prompt_col < ${#line} )); then
    ((prompt_col++))
  else
    if (( prompt_row + 1 < ${#prompt_lines[@]} )); then
      ((prompt_row++))
      prompt_col=0
    fi
  fi
  draw_prompt_block
}
move_cursor_left() {
  if (( prompt_col > 0 )); then
    ((prompt_col--))
  else
    if (( prompt_row > 0 )); then
      ((prompt_row--))
      prompt_col=${#prompt_lines[prompt_row]}
    fi
  fi
  draw_prompt_block
}

# -------------------- VISUAL MAP / BUILD ------------------------------------
build_visual_map() {
  visual_lines=(); visual_msg_idx=(); visual_msg_off=()
  local header_h=3 footer_h=2 prompt_h=3 usable_h=$((TERM_ROWS - header_h - footer_h - prompt_h))
  visible_rows=$(( usable_h - 1 ))
  (( visible_rows < 3 )) && visible_rows=3

  if (( TERM_COLS >= 120 )); then panel_width=$(( TERM_COLS * 65 / 100 )); else panel_width=$TERM_COLS; fi
  panel_inner_w=$(( panel_width - 6 ))
  (( panel_inner_w < 20 )) && panel_inner_w=20

  local i raw line ts who text wrapped j
  for ((i=0;i<${#conversation[@]};i++)); do
    raw="${conversation[$i]}"
    if [[ "$raw" == *"|||"* ]]; then line="${raw%%|||*}"; ts="${raw##*|||}"; else line="$raw"; ts="$(timestamp_now)"; fi
    if [[ "$line" =~ ^USER:\  ]]; then who="USER"; text="${line#USER: }"; else who="AI"; text="${line#AI:   }"; fi

    visual_lines+=("${who}: ${ts}")
    visual_msg_idx+=("$i")
    visual_msg_off+=(0)

    if [[ "${msg_cached_raw[i]}" == "$text" && -n "${msg_cached_wrapped[i]}" ]]; then
      mapfile -t wrapped < <(printf "%s" "${msg_cached_wrapped[i]}")
    else
      mapfile -t wrapped < <(printf "%s" "$text" | strip_ansi | wrap_awk "$panel_inner_w")
      msg_cached_raw[i]="$text"
      msg_cached_wrapped[i]="$(printf "%s\n" "${wrapped[@]}")"
    fi

    if (( ${#wrapped[@]} == 0 )); then
      visual_lines+=("")
      visual_msg_idx+=("$i")
      visual_msg_off+=(1)
    else
      for j in "${!wrapped[@]}"; do
        visual_lines+=("${wrapped[$j]}")
        visual_msg_idx+=("$i")
        visual_msg_off+=("$((j+1))")
      done
    fi
    visual_lines+=("─")
    visual_msg_idx+=("$i")
    visual_msg_off+=("$(( ${#wrapped[@]} + 1 ))")
  done

  (( scroll_pos < 0 )) && scroll_pos=0
  if (( ${#visual_lines[@]} - visible_rows >= 0 )); then
    (( scroll_pos > ${#visual_lines[@]} - visible_rows )) && scroll_pos=$(( ${#visual_lines[@]} - visible_rows ))
  else
    scroll_pos=0
  fi

  conv_snapshot=()
  for ((i=0;i<visible_rows;i++)); do conv_snapshot[i]="" ; done
}

# -------------------- ANSI-SAFE TRUNCATION ---------------------------------
truncate_with_ansi() {
  local s="$1"; local max="$2"
  local clean
  clean="$(printf "%s" "$s" | strip_ansi)"
  if (( ${#clean} <= max )); then
    printf "%s" "$s"
    return 0
  fi
  local prefix="${clean:0:max}"
  local out
  out="$(printf "%s" "$s" | awk -v P="$prefix" '
    BEGIN { p=P; plen=length(p); out=""; cleanout=""; }
    {
      line=$0
      for(i=1;i<=length(line);i++) {
        ch=substr(line,i,1)
        if (ch == "\033") {
          seq = ch
          j = i+1
          while (j <= length(line)) {
            seq = seq substr(line,j,1)
            if (substr(line,j,1) ~ /[@-~]/) { i = j; break }
            j++
          }
          out = out seq
          continue
        }
        cleanout = cleanout ch
        out = out ch
        if (length(cleanout) >= plen) { print out; exit }
      }
      print out
    }')"
  printf "%s" "$out"
}

# -------------------- DRAW (differential) ----------------------------------
draw_conversation_region() {
  local top=4 content_top=$((top + 2)) panel_left=1
  if (( panel_width <= 0 )); then
    if (( TERM_COLS >= 120 )); then panel_width=$(( TERM_COLS * 65 / 100 )); else panel_width=$TERM_COLS; fi
  fi
  local start="$scroll_pos" end=$(( start + visible_rows - 1 ))
  (( end > ${#visual_lines[@]} - 1 )) && end=$(( ${#visual_lines[@]} - 1 ))
  local row=0 idx line content maxw=$panel_inner_w color clean_content
  for ((idx=start; idx<=end; idx++)); do
    line="${visual_lines[idx]}"
    if [[ "$line" == "─" ]]; then
      content="$(printf '%*s' "$maxw" '' | sed 's/ /─/g')"
      color="$BORDER"
    else
      content="$(truncate_with_ansi "$line" "$maxw")"
      if [[ "$content" == USER:* ]]; then color="$USER_COL"; elif [[ "$content" == AI:* ]]; then color="$AI_COL"; else color="$FG"; fi
    fi
    clean_content="$(printf "%s" "$content" | strip_ansi)"
    if [[ "${conv_snapshot[row]}" != "$clean_content" ]]; then
      printf "\e[%s;%sH%s%s%s" "$((content_top + row))" "$((panel_left + 2))" "$color" "$content" "$RESET"
      conv_snapshot[row]="$clean_content"
    fi
    ((row++))
  done
  while (( row < visible_rows )); do
    if [[ "${conv_snapshot[row]}" != "" ]]; then
      printf "\e[%s;%sH%*s" "$((content_top + row))" "$((panel_left + 2))" "$((panel_width - 4))" ""
      conv_snapshot[row]=""
    fi
    ((row++))
  done
}

# -------------------- UI: prompt, header, footer ----------------------------
# safe width helper
_safe_width() {
  local w="$1"
  (( w < 0 )) && w=0
  printf "%s" "$w"
}

draw_header() {
  local text="  GroqBash TUI — Conversazione corrente: $conv_name  "
  if (( conversation_truncated )); then text="$text (ultime $MAX_LINES_IN_MEMORY righe)"; fi
  local len=${#text}
  local fill_w=$((_safe_width $((TERM_COLS - len - 2))))
  printf "\e[1;1H${BORDER}${TL}"
  printf "%${fill_w}s" "" | sed "s/ /${HL}/g"
  printf "${TR}${RESET}"
  printf "\e[2;1H${BORDER}${VL}${RESET}"
  printf "${TITLE}%s${RESET}" "$text"
  printf "%$((TERM_COLS - len - 2))s" ""
  printf "${BORDER}${VL}${RESET}"
  printf "\e[3;1H${BORDER}${BL}"
  printf "%$((TERM_COLS-2))s" "" | sed "s/ /${HL}/g"
  printf "${BR}${RESET}"
}

draw_footer() {
  local y=$((TERM_ROWS - 1))
  printf "\e[%s;1H${BORDER}" "$y"
  printf "%${TERM_COLS}s" "" | sed "s/ /${HL}/g"
  printf "${RESET}"
  printf "\e[%s;1H${FG}" "$y"
  printf "  Ctrl+T multilinea  |  Ctrl+S invia  |  ← → cursore  |  ↑↓ scroll riga  |  PgUp/PgDn pagina  |  Esc esci"
  printf "${RESET}"
}

draw_box() {
  local top=$1 left=$2 height=$3 width=$4 title="$5"
  local inner_w=$((width-2))
  (( inner_w < 0 )) && inner_w=0
  printf "\e[%s;%sH${BORDER}${TL}" "$top" "$left"
  printf "%${inner_w}s" "" | sed "s/ /${HL}/g"
  printf "${TR}${RESET}"
  printf "\e[%s;%sH${BORDER}${VL}${RESET}" "$((top+1))" "$left"
  printf "${TITLE} %s ${RESET}" "$title"
  local used=$(( ${#title} + 2 ))
  local pad=$(( width - used - 2 ))
  (( pad < 0 )) && pad=0
  printf "%${pad}s" ""
  printf "${BORDER}${VL}${RESET}"
  for ((r=top+2; r<top+height-1; r++)); do
    printf "\e[%s;%sH${BORDER}${VL}${RESET}" "$r" "$left"
    printf "%${inner_w}s" ""
    printf "${BORDER}${VL}${RESET}"
  done
  printf "\e[%s;%sH${BORDER}${BL}" "$((top+height-1))" "$left"
  printf "%${inner_w}s" "" | sed "s/ /${HL}/g"
  printf "${BR}${RESET}"
}

draw_prompt_block() {
  local y=$((TERM_ROWS - 3))
  local label=" Prompt "
  local label_len=${#label}
  local left_margin=2
  local inner_w=$((TERM_COLS-2))
  (( inner_w < 0 )) && inner_w=0
  printf "\e[%s;1H${BORDER}${TL}" "$y"
  printf "%${inner_w}s" "" | sed "s/ /${HL}/g"
  printf "${TR}${RESET}"
  printf "\e[%s;1H${BORDER}${VL}${RESET}" "$((y+1))"
  local mode_label="[Single-line]"; (( multiline_mode )) && mode_label="[Multiline]"
  printf "${FG}%s %s${RESET}" "$label" "$mode_label"
  local used_len=$((label_len + 1))
  local avail_w=$((TERM_COLS - used_len - left_margin - 6)); (( avail_w < 10 )) && avail_w=10
  local total_lines=${#prompt_lines[@]}; local avail_h=2; local start=0
  if (( total_lines > avail_h )); then start=$(( total_lines - avail_h )); fi
  local i line idx=0
  for ((i=start;i<total_lines;i++)); do
    line="${prompt_lines[i]}"
    line="${line:0:avail_w}"
    printf "%s" "$line"
    printf "%$((avail_w - ${#line}))s" ""
    if (( idx < avail_h - 1 )); then printf "\e[%s;1H${BORDER}${VL}${RESET}" "$((y+2+idx))"; fi
    ((idx++))
  done
  while (( idx < avail_h )); do printf "%$((avail_w))s" ""; ((idx++)); done
  printf "${BORDER}${VL}${RESET}"
  printf "\e[%s;1H${BORDER}${BL}" "$((y+2))"
  printf "%$((TERM_COLS-2))s" "" | sed "s/ /${HL}/g"
  printf "${BR}${RESET}"
  local cursor_screen_row=$((y+1 + (prompt_row - start)))
  local cursor_screen_col=$((left_margin + used_len + prompt_col))
  if (( cursor_screen_row >= y+1 && cursor_screen_row <= y+avail_h )); then
    printf "\e[%s;%sH\e[7m \e[27m" "$cursor_screen_row" "$cursor_screen_col"
  fi
}

draw_settings_overlay() {
  local h=10 w=50
  local top=$(( (TERM_ROWS - h) / 2 ))
  local left=$(( (TERM_COLS - w) / 2 ))
  draw_box "$top" "$left" "$h" "$w" "Impostazioni"
  local row=$((top+2)) i field val mark
  for i in "${!settings_fields[@]}"; do
    field="${settings_fields[$i]}"
    case "$field" in
      "Modello") val="$model" ;;
      "Provider") val="$provider" ;;
      "Lingua") val="$lang" ;;
      "Conversazione") val="$conv_name" ;;
    esac
    mark=" "; (( i == settings_index )) && mark=">"
    printf "\e[%s;%sH${FG}%s %s: %s${RESET}" "$row" "$((left+2))" "$mark" "$field" "$val"
    ((row++))
  done
  printf "\e[%s;%sH${FG}[Invio] modifica  [S] salva  [Esc] chiudi${RESET}" "$((top+h-2))" "$((left+2))"
  if (( settings_editing )); then printf "\e[%s;%sH${FG}Nuovo valore: %s${RESET}" "$((top+h-3))" "$((left+2))" "$settings_input"; fi
}

# -------------------- SCROLL HELPERS / SPINNER ------------------------------
scroll_by_lines() {
  local n=$1
  (( scroll_pos += n )); (( scroll_pos < 0 )) && scroll_pos=0
  if (( ${#visual_lines[@]} - visible_rows >= 0 )); then
    (( scroll_pos > ${#visual_lines[@]} - visible_rows )) && scroll_pos=$(( ${#visual_lines[@]} - visible_rows ))
  else
    scroll_pos=0
  fi
  draw_conversation_region
}
scroll_page_up() { scroll_by_lines $(( -visible_rows )); }
scroll_page_down() { scroll_by_lines $(( visible_rows )); }

draw_spinner() {
  spinner_index=$(( (spinner_index + 1) % ${#spinner_frames[@]} ))
  local frame="${spinner_frames[$spinner_index]}"
  printf "\e[%s;%sH${TITLE}%s${RESET}" "$((TERM_ROWS - 3))" "$((TERM_COLS - 3))" "$frame"
}

# -------------------- MAIN LOOP ----------------------------------------------
render_layout_main() {
  local header_h=3 footer_h=2 prompt_h=3 usable_h=$((TERM_ROWS - header_h - footer_h - prompt_h))
  clear_screen
  for ((r=1;r<=TERM_ROWS;r++)); do printf "\e[%s;1H${BG}%${TERM_COLS}s${RESET}" "$r" ""; done
  draw_header
  if (( TERM_COLS >= 120 )); then
    local left_w=$((TERM_COLS * 65 / 100)); local right_w=$((TERM_COLS - left_w - 2))
    draw_box 4 1 $usable_h $left_w "Conversazione"
    draw_conversation_region
    draw_box 4 $((left_w+2)) $usable_h $right_w "Impostazioni"
    printf "\e[6;$((left_w+4))H${FG}Modello: $model${RESET}"
    printf "\e[7;$((left_w+4))H${FG}Provider: $provider${RESET}"
    printf "\e[8;$((left_w+4))H${FG}Lingua: $lang${RESET}"
    printf "\e[9;$((left_w+4))H${FG}Conv:   $conv_name${RESET}"
  else
    local box_h=$((usable_h / 2))
    draw_box 4 1 $box_h $TERM_COLS "Conversazione"
    draw_conversation_region
    draw_box $((4+box_h)) 1 $((usable_h - box_h)) $TERM_COLS "Impostazioni"
    printf "\e[$((6+box_h));4H${FG}Modello: $model${RESET}"
    printf "\e[$((7+box_h));4H${FG}Provider: $provider${RESET}"
    printf "\e[$((8+box_h));4H${FG}Lingua: $lang${RESET}"
    printf "\e[$((9+box_h));4H${FG}Conv:   $conv_name${RESET}"
  fi
  draw_footer
  draw_prompt_block
}

main_loop() {
  local idle_cycles=0
  while ((running)); do
    if (( resize_flag )); then
      local now
      now=$(date +%s%3N 2>/dev/null || printf "%s000" "$(date +%s)")
      if (( last_resize_ts == 0 )); then last_resize_ts="$now"; fi
      if (( now - last_resize_ts > 80 )); then
        get_term_size
        conversation_changed=1
        resize_flag=0
        last_resize_ts=0
      else
        last_resize_ts="$now"
      fi
    fi

    reload_if_changed

    if (( conversation_changed )); then build_visual_map; conversation_changed=0; fi

    render_layout_main

    key="$(read_key)"
    if [[ -z "$key" ]]; then
      ((idle_cycles++))
      if (( idle_cycles > 5 )); then
        sleep 0.08
        idle_cycles=0
      else
        sleep 0.02
      fi
      continue
    fi
    idle_cycles=0

    if [[ "$key" == $'\003' ]]; then
      exit_raw_mode
      printf "\n\nModalità copia: seleziona testo con mouse/touch, poi premi Invio per tornare alla TUI...\n"
      read -r _
      enter_raw_mode
      conversation_changed=1
      continue
    fi

    case "$mode" in
      main)
        case "$key" in
          $'\e') running=0 ;;
          $'\e[A') scroll_by_lines -1 ;;
          $'\e[B') scroll_by_lines 1 ;;
          $'\e[5~') scroll_page_up ;;
          $'\e[6~') scroll_page_down ;;
          $'\e[C') move_cursor_right ;;
          $'\e[D') move_cursor_left ;;
          $'\177') delete_before_cursor; draw_prompt_block ;;
          $'\025') clear_current_line; draw_prompt_block ;;
          $'\027') delete_word_before_cursor; draw_prompt_block ;;
          $'\024')
            multiline_mode=$((1-multiline_mode))
            if (( multiline_mode == 0 )); then
              local joined
              joined="$(printf "%s\n" "${prompt_lines[@]}" | sed ':a;N;$!ba;s/\n/ /g')"
              prompt_lines=("$joined")
              prompt_row=0
              prompt_col=${#joined}
            fi
            render_layout_main
            ;;
          $'\023')
            local text
            text="$(get_prompt_text)"
            if [[ -n "$text" ]]; then
              append_conversation "USER: $text"
              history+=("$text"); history_index=-1
              build_visual_map; scroll_pos=$(( ${#visual_lines[@]} - visible_rows )); (( scroll_pos < 0 )) && scroll_pos=0
              render_layout_main
              for i in {1..12}; do draw_spinner; sleep 0.04; done
              local reply
              reply="$(run_groqbash "$text")"
              append_conversation "AI:   $reply"
              build_visual_map; scroll_pos=$(( ${#visual_lines[@]} - visible_rows )); (( scroll_pos < 0 )) && scroll_pos=0
              prompt_lines=(""); prompt_row=0; prompt_col=0
              render_layout_main
            fi
            ;;
          $'\n')
            if (( multiline_mode == 1 )); then
              insert_newline_at_cursor
              draw_prompt_block
            else
              local text
              text="$(get_prompt_text)"
              if [[ -n "$text" ]]; then
                append_conversation "USER: $text"
                history+=("$text"); history_index=-1
                build_visual_map; scroll_pos=$(( ${#visual_lines[@]} - visible_rows )); (( scroll_pos < 0 )) && scroll_pos=0
                render_layout_main
                for i in {1..12}; do draw_spinner; sleep 0.04; done
                local reply
                reply="$(run_groqbash "$text")"
                append_conversation "AI:   $reply"
                build_visual_map; scroll_pos=$(( ${#visual_lines[@]} - visible_rows )); (( scroll_pos < 0 )) && scroll_pos=0
                prompt_lines=(""); prompt_row=0; prompt_col=0
                render_layout_main
              fi
            fi
            ;;
          $'\eOP'|$'\e[11~')
            mode="settings"; settings_index=0; settings_editing=0; settings_input=""
            draw_settings_overlay
            ;;
          $'\eOQ'|$'\e[12~')
            create_new_conversation
            conversation_changed=1
            build_visual_map
            render_layout_main
            ;;
          *)
            if [[ "$key" > $'\x1f' ]]; then insert_char_at_cursor "$key"; draw_prompt_block; fi
            ;;
        esac
        ;;
      settings)
        case "$key" in
          $'\e')
            if (( settings_editing )); then
              settings_editing=0; settings_input=""
              draw_settings_overlay
            else
              mode="main"; render_layout_main
            fi
            ;;
          $'\n')
            if (( settings_editing )); then
              local field="${settings_fields[$settings_index]}"
              case "$field" in
                "Modello") [[ -n "$settings_input" ]] && model="$(sanitize_param "$settings_input")" ;;
                "Provider") [[ -n "$settings_input" ]] && provider="$(sanitize_param "$settings_input")" ;;
                "Lingua") [[ -n "$settings_input" ]] && lang="$(sanitize_param "$settings_input")" ;;
                "Conversazione")
                  if [[ -n "$settings_input" ]]; then
                    local norm
                    norm="$(normalize_conv_name "$settings_input")" || { draw_settings_overlay; continue; }
                    conv_name="$norm"
                    conv_path="$CONV_DIR/$conv_name"
                    [[ -f "$conv_path" ]] || : > "$conv_path"
                    load_conversation
                  fi
                  ;;
              esac
              settings_editing=0
              save_config
              draw_settings_overlay
            else
              settings_editing=1
              settings_input=""
              draw_settings_overlay
            fi
            ;;
          $'\177')
            if (( settings_editing )); then
              settings_input="${settings_input%?}"
              draw_settings_overlay
            fi
            ;;
          $'\e[A')
            if (( ! settings_editing )); then
              ((settings_index>0)) && ((settings_index--))
              draw_settings_overlay
            fi
            ;;
          $'\e[B')
            if (( ! settings_editing )); then
              ((settings_index<${#settings_fields[@]}-1)) && ((settings_index++))
              draw_settings_overlay
            fi
            ;;
          [sS])
            if (( ! settings_editing )); then
              save_config
              draw_settings_overlay
            fi
            ;;
          *)
            if (( settings_editing )); then
              settings_input+="$key"
              draw_settings_overlay
            fi
            ;;
        esac
        ;;
    esac
    sleep 0.01
  done
}

# -------------------- HELPERS: create_new_conversation -----------------------
create_new_conversation() {
  local max_n=0 n file base num
  shopt -s nullglob
  for file in "$CONV_DIR"/conv-*.txt; do
    [[ -e "$file" ]] || continue
    base="${file##*/}"; num="${base#conv-}"; num="${num%.txt}"
    if [[ "$num" =~ ^[0-9]+$ ]]; then (( num > max_n )) && max_n="$num"; fi
  done
  shopt -u nullglob
  n=$((max_n + 1))
  conv_name=$(printf "conv-%03d.txt" "$n")
  conv_path="$CONV_DIR/$conv_name"
  : > "$conv_path"
  save_config
  load_conversation
}

# -------------------- UI: prompt helpers (no eval) --------------------------
init_prompt() { prompt_lines=(""); prompt_row=0; prompt_col=0; multiline_mode=0; }
get_prompt_text() { local IFS=$'\n'; printf "%s" "${prompt_lines[*]}"; }
insert_char_at_cursor() { local ch="$1"; local line="${prompt_lines[prompt_row]}"; prompt_lines[prompt_row]="${line:0:prompt_col}$ch${line:prompt_col}"; ((prompt_col++)); }
delete_before_cursor() {
  if (( prompt_col > 0 )); then
    local line="${prompt_lines[prompt_row]}"
    prompt_lines[prompt_row]="${line:0:prompt_col-1}${line:prompt_col}"
    ((prompt_col--))
  else
    if (( prompt_row > 0 )); then
      local prev="${prompt_lines[prompt_row-1]}"
      local cur="${prompt_lines[prompt_row]}"
      prompt_col=${#prev}
      prompt_lines[prompt_row-1]="${prev}${cur}"
      unset 'prompt_lines[prompt_row]'
      prompt_lines=("${prompt_lines[@]}")
      ((prompt_row--))
    fi
  fi
}
insert_newline_at_cursor() {
  local line="${prompt_lines[prompt_row]}"
  local left="${line:0:prompt_col}"
  local right="${line:prompt_col}"
  prompt_lines[prompt_row]="$left"
  local new_index=$((prompt_row+1))
  prompt_lines=( "${prompt_lines[@]:0:new_index}" "$right" "${prompt_lines[@]:new_index}" )
  prompt_row=$new_index
  prompt_col=0
}
delete_word_before_cursor() {
  local line="${prompt_lines[prompt_row]}"
  local left="${line:0:prompt_col}"
  local right="${line:prompt_col}"
  while [[ "${left: -1}" == " " ]]; do left="${left:0:-1}"; done
  if [[ "$left" == *" "* ]]; then left="${left% *}"; else left=""; fi
  prompt_lines[prompt_row]="${left}${right}"
  prompt_col=${#left}
}
clear_current_line() { prompt_lines[prompt_row]=""; prompt_col=0; }

# -------------------- STARTUP ------------------------------------------------
ensure_dirs
get_term_size
load_config
[[ -f "$conv_path" ]] || : > "$conv_path"
load_conversation
init_prompt
enter_raw_mode
build_visual_map
render_layout_main
main_loop
