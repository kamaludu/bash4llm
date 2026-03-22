#!/usr/bin/env bash
# =============================================================================
# Mini server Bash per GUI HTML di GroqBash (router, logica applicativa)
# File: gui-server.sh
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Source: https://github.com/kamaludu/groqbash
# =============================================================================
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/gui-bootstrap.sh"
if [[ ! -f "$BOOTSTRAP" ]]; then
  printf 'Status: 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\nBootstrap missing: %s\n' "$BOOTSTRAP"
  exit 1
fi
: "${GROQBASH_CMD:=groqbash}"
source "$BOOTSTRAP"

# -------------------------
# Helpers (small, focused)
# -------------------------
is_configured() {
  # configured if provider set, api-key present (if provider requires it), and model set or MODELS_FILE has entries
  local prov model models_file entries
  prov="$(get_default_provider)"
  model="$(get_default_model)"
  models_file="$(get_models_file)"
  # provider and api-key
  if [[ -z "$prov" ]]; then
    return 1
  fi
  # if api-key file exists and non-empty -> ok; otherwise not configured
  if [[ -z "$(read_api_key_file)" ]]; then
    return 1
  fi
  # model: either explicitly set or models file has at least one non-empty line
  if [[ -n "$model" ]]; then
    return 0
  fi
  if [[ -f "$models_file" ]]; then
    entries="$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)"
    if [[ -n "$entries" ]]; then
      return 0
    fi
  fi
  return 1
}

# safe wrapper to call groqbash; assumes env key exported already
call_groqbash_with_args() {
  # $@ are args to groqbash
  # read prompt from stdin and pipe to groqbash, capture stdout
  "$GROQBASH_CMD" "$@"
}

# read MODELS_FILE path used by groqbash (best-effort)
get_models_file() {
  # try canonical location relative to groqbash dir
  local candidate groq_dir
  groq_dir="$(dirname -- "$GROQBASH_CMD" 2>/dev/null || printf '.')"
  candidate="$groq_dir/groqbash.d/models/models.txt"
  if [[ -f "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi
  # fallback to UI_ROOT sibling
  candidate="$UI_ROOT/../groqbash.d/models/models.txt"
  if [[ -f "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi
  # final fallback to UI_ROOT/models
  candidate="$UI_ROOT/models/models.txt"
  printf '%s' "$candidate"
  return 0
}

# refresh models via groqbash and atomically write to MODELS_FILE
refresh_models_via_groqbash() {
  local prov models_file out rc
  prov="$1"
  models_file="$(get_models_file)"
  # ensure groqbash available
  if ! ensure_groqbash_available; then
    log_error "GUIIO" "groqbash not available for refresh"
    return 1
  fi
  # export API key for provider if present
  export_api_key_for_provider "$prov" || true
  # call groqbash --refresh-models and capture stdout
  if out="$( "$GROQBASH_CMD" --provider "$prov" --refresh-models 2>>"$ERROR_LOG" || true )"; then
    # sanitize output: keep non-empty lines
    out="$(printf '%s\n' "$out" | sed -n '/\S/ p')"
    if [[ -n "$out" ]]; then
      atomic_write "$models_file" "$out" || { log_error "GUIIO" "Failed to write models file"; return 1; }
      log_info "GUIIO" "Models refreshed for provider $prov"
      return 0
    else
      log_warn "GUIIO" "Refresh returned empty list for provider $prov"
      return 1
    fi
  else
    rc=$?
    log_error "GUIIO" "Refresh models failed (rc=$rc)"
    return 1
  fi
}

# -------------------------
# Conversation title helpers
# -------------------------
get_title_file_for_conv() {
  local conv_path="$1"
  printf '%s' "${conv_path%.txt}.title"
}

read_conv_title() {
  local conv_path="$1"
  local title_file
  title_file="$(get_title_file_for_conv "$conv_path")"
  if [[ -r "$title_file" ]]; then
    sed -n '1p' "$title_file" 2>/dev/null || printf ''
  else
    printf ''
  fi
}

# -------------------------
# POST handlers (revised)
# -------------------------
handle_post_settings() {
  local body model provider lang api_key action models_file
  body="$(read_post_body)"

  model="$(printf '%s' "$body" | parse_form_field "model" || printf '')"
  provider="$(printf '%s' "$body" | parse_form_field "provider" || printf '')"
  lang="$(printf '%s' "$body" | parse_form_field "lang" || read_config_or_default "$LANG_CURRENT_FILE" "en")"
  api_key="$(printf '%s' "$body" | parse_form_field "api_key" || printf '')"
  action="$(printf '%s' "$body" | parse_form_field "action" || printf '')"

  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"
  lang="$(sanitize_param "$lang")"
  api_key="$(sanitize_param "$api_key")"

  # validate names
  if [[ -n "$model" ]]; then
   if ! validate_name "$model"; then
     log_error "GUIIO" "Invalid model name attempted: $model"
     model=""
   fi
  fi

  if [[ -n "$provider" ]]; then
   if ! validate_name "$provider"; then
     log_error "GUIIO" "Invalid provider name attempted: $provider"
     provider=""
   fi
  fi

  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi

  # persist provider/model/lang (allow empty to indicate "not configured")
  atomic_write "$DEFAULT_MODEL_FILE" "$model" || log_warn "GUIIO" "Failed to write default model"
  atomic_write "$DEFAULT_PROVIDER_FILE" "$provider" || log_warn "GUIIO" "Failed to write default provider"
  atomic_write "$LANG_CURRENT_FILE" "$lang" || true

  # persist API key securely if provided (empty -> remove)
  if [[ -n "$api_key" ]]; then
    save_api_key_file "$api_key" || log_warn "GUIIO" "Failed to save API key"
  fi

  # handle refresh action
  if [[ "$action" == "refresh_models" ]]; then
    if [[ -z "$provider" ]]; then
      log_error "GUIIO" "Refresh requested but provider empty"
    else
      refresh_models_via_groqbash "$provider" || log_error "GUIIO" "Refresh models failed for $provider"
    fi
  fi
}

handle_post_main() {
  local body prompt model provider conv_file output sanitized_output models_file models_list lang
  body="$(read_post_body)"

  # ensure lang is defined for validation and templates
  lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"

  prompt="$(printf '%s' "$body" | parse_form_field "prompt" || printf '')"

  # --- FIX: robust parsing to avoid subshell boolean syntax errors ---
  model_raw="$(printf '%s' "$body" | parse_form_field "model" || true)"
  provider_raw="$(printf '%s' "$body" | parse_form_field "provider" || true)"

  model="${model_raw:-$(get_default_model)}"
  provider="${provider_raw:-$(get_default_provider)}"

  # allow renaming conversation title from main form
  conv_title_raw="$(printf '%s' "$body" | parse_form_field "conv_title" || true)"
  conv_title="$(sanitize_param "$conv_title_raw")"

  prompt="$(sanitize_param "$prompt")"
  model="$(sanitize_param "$model")"
  provider="$(sanitize_param "$provider")"

  # basic truncation
  if (( ${#prompt} > MAX_PROMPT_CHARS )); then
    log_error "GUIIO" "Prompt truncated from ${#prompt} to $MAX_PROMPT_CHARS chars"
    prompt="${prompt:0:MAX_PROMPT_CHARS}"
  fi

  # validate names (fixed: call functions outside [[ ... ]])
  if [[ -n "$model" ]]; then
    if ! validate_name "$model"; then
      log_error "GUIIO" "Invalid model name attempted: $model"
      model=""
    fi
  fi

  if [[ -n "$provider" ]]; then
    if ! validate_name "$provider"; then
      log_error "GUIIO" "Invalid provider name attempted: $provider"
      provider=""
    fi
  fi

  if ! [[ "$lang" =~ ^[A-Za-z_-]+$ ]]; then
    lang="$(read_config_or_default "$LANG_CURRENT_FILE" "en")"
  fi

  # ensure conversation file exists and append user turn
  conv_file="$(get_current_conversation_file)"

  # if user provided a conv title, save it
  if [[ -n "$conv_title" ]]; then
    title_file="$(get_title_file_for_conv "$conv_file")"
    atomic_write "$title_file" "$conv_title" || log_warn "GUIIO" "Failed to write conversation title"
  fi

  atomic_append_conv "$conv_file" "USER: $prompt" || log_error "GUIIO" "Failed to append USER to conversation"

  # PRE-CHECKS: do not call groqbash unless configured
  if ! is_configured; then
    log_error "GUIIO" "Attempt to call groqbash while GUI not configured"
    atomic_append_conv "$conv_file" "AI: ERROR: GUI not configured. Please set provider, API key and model in Settings." || true
    return 0
  fi

  # ensure API key exported for provider
  if ! export_api_key_for_provider "$provider"; then
    log_error "GUIIO" "API key missing for provider $provider"
    atomic_append_conv "$conv_file" "AI: ERROR: API key missing for provider $provider. Set it in Settings." || true
    return 0
  fi

  # if MODELS_FILE exists and non-empty, validate model presence
  models_file="$(get_models_file)"
  if [[ -f "$models_file" ]]; then
    if [[ -n "$model" ]]; then
      if ! grep -Fxq "$model" "$models_file" 2>/dev/null; then
        log_error "GUIIO" "Model $model not in whitelist"
        atomic_append_conv "$conv_file" "AI: ERROR: Selected model not in whitelist. Please refresh models or choose another model." || true
        return 0
      fi
    else
      # if no model selected, try to auto-select first entry
      model="$(awk 'NF{print; exit}' "$models_file" 2>/dev/null || true)"
      model="$(sanitize_param "$model")"
      if [[ -z "$model" ]]; then
        atomic_append_conv "$conv_file" "AI: ERROR: No model selected and whitelist empty. Please refresh models in Settings." || true
        return 0
      fi
    fi
  fi

  # Finally, call groqbash with provider and model
  local groq_args=()
  if [[ -n "$provider" ]]; then groq_args+=(--provider "$provider"); fi
  if [[ -n "$model" ]]; then groq_args+=(--model "$model"); fi

  # Use a subshell to capture output safely and avoid leaking env changes
  output="$(printf '%s' "$prompt" | call_groqbash_with_args "${groq_args[@]}" 2>>"$ERROR_LOG" || true)"
  sanitized_output="$(sanitize_model_output "$output")"
  atomic_append_conv "$conv_file" "AI: $sanitized_output" || log_error "GUIIO" "Failed to append AI to conversation"
}

# -------------------------
# Template helper builders (Solution A)
# -------------------------
build_model_options() {
  local models_file model_cur out m
  models_file="$(get_models_file)"
  model_cur="$1"
  out=''
  if [[ -f "$models_file" ]]; then
    while IFS= read -r m; do
      m="$(sanitize_param "$m")"
      [ -z "$m" ] && continue
      if [[ "$m" == "$model_cur" ]]; then
        out+='<option value="'"$(html_escape "$m")"'" selected>'"$(html_escape "$m")"'</option>'
      else
        out+='<option value="'"$(html_escape "$m")"'">'"$(html_escape "$m")"'</option>'
      fi
      out+=$'\n'
    done < <(awk 'NF{print}' "$models_file" 2>/dev/null || true)
  fi
  printf '%s' "$out"
}

build_conv_list() {
  local out f bn title
  out=''
  if [[ -d "$CONV_DIR" ]]; then
    for f in "$CONV_DIR"/conv-*.txt; do
      [ -e "$f" ] || continue
      bn="$(basename -- "$f")"
      title="$(read_conv_title "$f")"
      if [[ -n "$title" ]]; then
        out+="$(html_escape "$bn") — $(html_escape "$title")"$'\n'
      else
        out+="$(html_escape "$bn")"$'\n'
      fi
    done
  fi
  printf '%s' "$out"
}

build_current_conv_html() {
  local conv_file cur_title out
  conv_file="$1"
  out=''
  if [[ -f "$conv_file" ]]; then
    cur_title="$(read_conv_title "$conv_file")"
    if [[ -n "$cur_title" ]]; then
      out+="<h2>$(html_escape "$cur_title")</h2>"
    else
      out+="<h2>$(html_escape "$(read_config_or_default 'TXT_CURRENT_CONVERSATION' 'Current conversation')")</h2>"
    fi
    out+=$'\n'
    out+='<pre>'$'\n'
    out+="$(sed -n '1,2000p' "$conv_file" 2>/dev/null | html_escape_stream)"
    out+=$'\n</pre>'
  fi
  printf '%s' "$out"
}

# -------------------------
# Page renderers (pass CONFIGURED flag and inject MODEL_OPTIONS/CONV_LIST/CURRENT_CONV)
# -------------------------
render_page_main() {
  local lang="$1"
  local theme model_cur prov_cur conv_file configured
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  conv_file="$(get_current_conversation_file)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  if is_configured; then configured="true"; else configured="false"; fi

  # build template variables
  MODEL_OPTIONS="$(build_model_options "$model_cur")"
  CONV_LIST="$(build_conv_list)"
  CURRENT_CONV="$(build_current_conv_html "$conv_file")"

  export MODEL_OPTIONS CONV_LIST CURRENT_CONV

  [[ -f "$TEMPLATES_DIR/header.html" ]] && render_template "$TEMPLATES_DIR/header.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  # inject a small banner if not configured (templates can use {{CONFIGURED}})
  if [[ "$configured" != "true" ]]; then
    printf '<div class="alert alert-danger">Configuration required: please set provider, API key and model in Settings.</div>\n'
  fi
  [[ -f "$TEMPLATES_DIR/content.html" ]] && render_template "$TEMPLATES_DIR/content.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && render_template "$TEMPLATES_DIR/footer.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
}

render_page_settings() {
  local lang="$1"
  local theme model_cur prov_cur conv_file configured models_file
  model_cur="$(get_default_model)"
  prov_cur="$(get_default_provider)"
  conv_file="$(get_current_conversation_file)"
  theme="$(read_config_or_default "$THEME_CURRENT_FILE" "light")"
  if is_configured; then configured="true"; else configured="false"; fi

  # build template variables
  MODEL_OPTIONS="$(build_model_options "$model_cur")"
  CONV_LIST="$(build_conv_list)"
  CURRENT_CONV="$(build_current_conv_html "$conv_file")"

  export MODEL_OPTIONS CONV_LIST CURRENT_CONV

  [[ -f "$TEMPLATES_DIR/settings-header.html" ]] && render_template "$TEMPLATES_DIR/settings-header.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/settings-content.html" ]] && render_template "$TEMPLATES_DIR/settings-content.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
  [[ -f "$TEMPLATES_DIR/footer.html" ]] && render_template "$TEMPLATES_DIR/footer.html" "$lang" "$theme" "$model_cur" "$prov_cur" "$conv_file"
}

# -------------------------
# Main router
# -------------------------
main() {
  ensure_dirs

  if [[ "${is_termux:-}" = "true" ]]; then
    fix_termux_perms || true
  fi

  ensure_config_defaults

  log_rotate_if_needed "$SERVER_LOG" 1048576
  log_rotate_if_needed "$ERROR_LOG" 1048576

  ensure_flock_available || { log_error "GUILOCK" "flock missing"; print_http_error "500 Internal Server Error" "Server misconfiguration: flock not available"; exit 1; }
  if ! ensure_groqbash_available; then
    log_error "GUIIO" "groqbash not found: $GROQBASH_CMD"
    print_http_error "500 Internal Server Error" "groqbash not found on server. Contact administrator."
    exit 1
  fi

  if ! acquire_lock; then
    exit 1
  fi

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

  log_info "GUILOCK" "Request method=$method page=$page lang=$lang_code theme=$theme_code"

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
          atomic_write "$CONV_DIR/$convname" "" || true
          # create empty title file
          atomic_write "$CONV_DIR/${convname%.txt}.title" "" || true
          atomic_write "$CURRENT_CONV_FILE" "$convname" || true
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

main "$@"
