#!/usr/bin/env bash
# =============================================================================
# Mini server Bash per GUI HTML di GroqBash (server, logica applicativa)
# File: gui-server.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
# Requisiti: bash, coreutils, curl, jq (usati da GroqBash) e un qualsiasi web server che supporta CGI (es. busybox).
# Vincoli: Bash-only, nessun eval, nessun uso di /tmp di sistema, atomic_write obbligatorio,
# lock globale per serializzare richieste, sanitizzazione input, limiti dimensione prompt.

set -euo pipefail
umask 077

# Resolve script dir and source bootstrap
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/gui-bootstrap.sh"
if [[ ! -f "$BOOTSTRAP" ]]; then
  printf 'Status: 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\nBootstrap missing: %s\n' "$BOOTSTRAP"
  exit 1
fi
# Allow environment overrides before sourcing (optional)
: "${GROQBASH_CMD:=groqbash}"
source "$BOOTSTRAP"

# Now bootstrap exported variables and functions are available:
# UI_ROOT TMP_DIR LOG_DIR CFG_DIR CONV_DIR FILES_DIR TEMPLATES_DIR
# LOCK_FILE SERVER_LOG ERROR_LOG CURRENT_CONV_FILE LANG_CURRENT_FILE THEME_CURRENT_FILE
# DEFAULT_MODEL_FILE DEFAULT_PROVIDER_FILE GROQBASH_CMD
# Functions: log_info, log_error, ensure_dirs, ensure_config_defaults, atomic_write, atomic_append_conv,
# ensure_flock_available, acquire_lock, release_lock, print_http_header, print_http_error,
# html_escape, validate_name, sanitize_param, get_query_param, read_post_body, parse_form_field,
# get_current_conversation_file, get_default_model, get_default_provider, sanitize_model_output, mktemp_portable

#######################################
# Application-specific helpers (remain here)
#######################################

# Minimal template renderer (keeps original behavior)
render_template() {
  local tpl="$1" lang="$2" theme="$3" model_cur="$4" prov_cur="$5" conv_file="$6"
  [ -r "$tpl" ] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line//\{\{THEME\}\}/$theme}"
    line="${line//\{\{LANG_CODE\}\}/$lang}"
    line="${line//\{\{MODEL_CURRENT\}\}/$(html_escape "$model_cur")}"
    line="${line//\{\{PROVIDER_CURRENT\}\}/$(html_escape "$prov_cur")}"

    while [[ "$line" =~ \{\{TXT_[A-Za-z0-9_]+\}\} ]]; do
      local token="${BASH_REMATCH[0]}"
      local key="${token#\{\{}"
      key="${key%\}\}}"
      local val
      val="$(lookup "$key" "$lang" 2>/dev/null || printf '')"
      line="${line//$token/$val}"
    done

    if [[ "$line" == *"{{LANG_OPTIONS}}"* ]]; then
      local opts=""
      for code in en it es fr de; do
        local name
        name="$(lookup "LANG_NAME" "$code" 2>/dev/null || printf '%s' "$code")"
        if [[ "$code" == "$lang" ]]; then
          opts+="<option value=\"$code\" selected>$(html_escape "$name")</option>"
        else
          opts+="<option value=\"$code\">$(html_escape "$name")</option>"
        fi
      done
      line="${line//\{\{LANG_OPTIONS\}\}/$opts}"
    fi

    line="${line//\{\{THEME_IS_light\}\}/$( [ "$theme" = "light" ] && printf 'selected' || printf '' )}"
    line="${line//\{\{THEME_IS_dark\}\}/$( [ "$theme" = "dark" ] && printf 'selected' || printf '' )}"

    if [[ "$line" == *"{{FILES_LIST}}"* ]]; then
      local flist=""
      if [[ -d "$FILES_DIR/input" ]]; then
        for f in "$FILES_DIR/input"/*; do
          [ -e "$f" ] || continue
          local bn; bn="$(basename -- "$f")"
          if validate_name "$bn"; then flist+="$(html_escape "$bn")"$'\n'; fi
        done
      fi
      line="${line//\{\{FILES_LIST\}\}/$(printf '%s' "$flist")}"
    fi

    if [[ "$line" == *"{{CONV_LIST}}"* ]]; then
      local clist=""
      if [[ -d "$CONV_DIR" ]]; then
        for f in "$CONV_DIR"/*; do
          [ -e "$f" ] || continue
          local bn; bn="$(basename -- "$f")"
          if validate_name "$bn"; then clist+="$(html_escape "$bn")"$'\n'; fi
        done
      fi
      line="${line//\{\{CONV_LIST\}\}/$(printf '%s' "$clist")}"
    fi

    if [[ "$line" == *"{{CURRENT_CONV}}"* || "$line" == *"{{CONVERSATION}}"* ]]; then
      local conv_html=""
      if [[ -f "$conv_file" ]]; then
        while IFS= read -r cl || [[ -n "$cl" ]]; do
          if [[ "$cl" == USER:* ]]; then
            conv_html+="<pre class=\"user\">$(html_escape "${cl#USER: }")</pre>"$'\n'
          elif [[ "$cl" == AI:* ]]; then
            conv_html+="<pre class=\"ai\">$(html_escape "${cl#AI: }")</pre>"$'\n'
          else
            conv_html+="<pre>$(html_escape "$cl")</pre>"$'\n'
          fi
        done <"$conv_file"
      fi
      line="${line//\{\{CURRENT_CONV\}\}/$conv_html}"
      line="${line//\{\{CONVERSATION\}\}/$conv_html}"
    fi

    printf '%s\n' "$line"
  done <"$tpl"
}

# lookup and get_text (use gui-lang.conf in UI_ROOT)
lookup() {
  local key="$1" lang="$2" conf="$UI_ROOT/gui-lang.conf" val=""
  [ -r "$conf" ] || return 1
  val="$(awk -F= -v k="${key}.${lang}" '$1==k { $1=""; sub(/^=/,""); print substr($0,2); exit }' "$conf" 2>/dev/null || true)"
  if [[ -n "$val" ]]; then printf '%s' "$val"; return 0; fi
  val="$(awk -F= -v k="${key}" '$1==k { $1=""; sub(/^=/,""); print substr($0,2); exit }' "$conf" 2>/dev/null || true)"
  if [[ -n "$val" ]]; then printf '%s' "$val"; return 0; fi
  return 1
}

get_text() {
  local key="$1" lang="$2" raw
  raw="$(lookup "$key" "$lang")" || raw=""
  printf '%s' "$raw" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

sanitize_model_output() {
  local out="$1"
  out="$(printf '%s' "$out" | tr -d '\000-\011\013\014\016-\037')"
  if (( ${#out} > MAX_MODEL_OUTPUT_CHARS )); then
    log_error "Model output truncated (length ${#out})"
    out="${out:0:MAX_MODEL_OUTPUT_CHARS}"
  fi
  printf '%s' "$out"
}

# --- POST handlers (unchanged logic) ---
handle_post_main() {
  local body prompt model provider conv_file output sanitized_output
  body="$(read_post_body)"

  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"
  model="$(printf '%s' "$body" | parse_form_field "model" || get_default_model)"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || get_default_provider)"

  prompt="$(sanitize_param "$prompt")"
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"

  if (( ${#prompt} > MAX_PROMPT_CHARS )); then
    log_error "Prompt truncated from ${#prompt} to $MAX_PROMPT_CHARS chars"
    prompt="${prompt:0:MAX_PROMPT_CHARS}"
  fi

  if ! validate_name "$model"; then
    log_error "Invalid model name attempted: $model"
    model="$(get_default_model)"
  fi
  if ! validate_name "$provider"; then
    log_error "Invalid provider name attempted: $provider"
    provider="$(get_default_provider)"
  fi

  conv_file="$(get_current_conversation_file)"

  atomic_append_conv "$conv_file" "USER: $prompt" || {
    log_error "Failed to append USER to conversation"
  }

  if [[ -n "$provider" && "$provider" != "default" ]]; then
    if [[ -n "$model" && "$model" != "default" ]]; then
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" --provider "$provider" --model "$model" 2>>"$ERROR_LOG" || true)"
    else
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" --provider "$provider" 2>>"$ERROR_LOG" || true)"
    fi
  else
    if [[ -n "$model" && "$model" != "default" ]]; then
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" --model "$model" 2>>"$ERROR_LOG" || true)"
    else
      output="$(printf '%s' "$prompt" | "$GROQBASH_CMD" 2>>"$ERROR_LOG" || true)"
    fi
  fi

  sanitized_output="$(sanitize_model_output "$output")"
  atomic_append_conv "$conv_file" "AI: $sanitized_output" || {
    log_error "Failed to append AI to conversation"
  }
}

handle_post_settings() {
  local body model provider lang
  body="$(read_post_body)"

  model="$(printf '%s' "$body" | parse_form_field "model" || get_default_model)"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || get_default_provider)"
  lang="$(printf '%s' "$body" | parse_form_field "lang" || read_config_or_default "$LANG_CURRENT_FILE" "en")"

  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  lang="$(sanitize_param "$lang")"

  if ! validate_name "$model"; then
    log_error "Invalid model name attempted: $model"
    model="$(get_default_model)"
  fi
  if ! validate_name "$provider"; then
    log_error "Invalid provider name attempted: $provider"
    provider="$(get_default_provider)"
  fi
  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi

  atomic_write "$DEFAULT_MODEL_FILE" "$model"
  atomic_write "$DEFAULT_PROVIDER_FILE" "$provider"
  atomic_write "$LANG_CURRENT_FILE" "$lang"
}

# --- Page renderers (use templates) ---
render_page_main() {
  local lang="$1"
  local theme model_cur prov_cur conv_file
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  conv_file="$(get_current_conversation_file)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"

  [[ -f "$TEMPLATES_DIR/header.html" ]] && render_template "$TEMPLATES_DIR/header.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/content.html" ]] && render_template "$TEMPLATES_DIR/content.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && render_template "$TEMPLATES_DIR/footer.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
}

render_page_settings() {
  local lang="$1"
  local theme model_cur prov_cur conv_file
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  conv_file="$(get_current_conversation_file)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"

  [[ -f "$TEMPLATES_DIR/settings-header.html" ]] && render_template "$TEMPLATES_DIR/settings-header.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/settings-content.html" ]] && render_template "$TEMPLATES_DIR/settings-content.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && render_template "$TEMPLATES_DIR/footer.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
}

# --- Main router (keeps original flow) ---
main() {
  ensure_dirs
  ensure_config_defaults

  ensure_flock_available || { log_error "flock missing"; print_http_error "500 Internal Server Error" "Server misconfiguration: flock not available"; exit 1; }
  if ! ensure_groqbash_available; then
    log_error "groqbash not found: $GROQBASH_CMD"
    print_http_error "500 Internal Server Error" "groqbash not found on server. Contact administrator."
    exit 1
  fi

  acquire_lock

  local method="${REQUEST_METHOD:-}"
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  if [[ -z "$method" ]]; then
    method="${1:-GET}"
    method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  fi

  QUERY_STRING="${QUERY_STRING:-}"
  QUERY_STRING="$(printf '%s' "$QUERY_STRING" | tr -d '\000-\037')"

  local lang_code
  lang_code="$(get_query_param "lang" 2>/dev/null || printf '')"
  if [[ -n "$lang_code" ]]; then
    lang_code="$(sanitize_param "$lang_code")"
    if validate_name "$lang_code"; then
      atomic_write "$LANG_CURRENT_FILE" "$lang_code"
    else
      lang_code="en"
    fi
  else
    lang_code="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi

  local theme_code
  theme_code="$(get_query_param "theme" 2>/dev/null || printf '')"
  if [[ -n "$theme_code" ]]; then
    theme_code="$(sanitize_param "$theme_code")"
    if [[ "$theme_code" == "light" || "$theme_code" == "dark" ]]; then
      atomic_write "$THEME_CURRENT_FILE" "$theme_code"
    else
      theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
    fi
  else
    theme_code="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  fi

  local page
  page="$(get_query_param "page" 2>/dev/null || printf 'main')"
  page="$(sanitize_param "$page")"
  if ! validate_name "$page"; then
    page="main"
  fi

  log_info "Request method=$method page=$page lang=$lang_code theme=$theme_code"

  case "$method" in
    GET)
      print_http_header
      case "$page" in
        settings) render_page_settings "$lang_code" ;;
        *) render_page_main "$lang_code" ;;
      esac
      ;;
    POST)
      case "$page" in
        settings)
          handle_post_settings
          lang_code="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
          print_http_header
          render_page_settings "$lang_code"
          ;;
        newconv)
          local next convname bn
          next=1
          for f in "$CONV_DIR"/conv-*.txt; do
            [ -e "$f" ] || continue
            bn="$(basename -- "$f")"
            bn="${bn#conv-}"
            bn="${bn%.txt}"
            if [[ "$bn" =~ ^[0-9]+$ ]]; then
              if (( bn+0 >= next )); then next=$((bn+1)); fi
            fi
          done
          convname="$(printf 'conv-%03d.txt' "$next")"
          atomic_write "$CONV_DIR/$convname" ""
          atomic_write "$CURRENT_CONV_FILE" "$convname"
          print_http_header
          render_page_main "$lang_code"
          ;;
        *)
          handle_post_main
          print_http_header
          render_page_main "$lang_code"
          ;;
      esac
      ;;
    *)
      print_http_header
      printf '<h1>405 Method Not Allowed</h1>\n'
      ;;
  esac

  release_lock
}

# Start
main "$@"
