// SPDX-License-Identifier: GPL-3.0-or-later
// ======================================
// Bash4LLM⁺ — Bash-first wrapper for the LLM
// File: extras/gui-py/static/app.js
// Component: WebApp Vanilla ES6 Client (SSE Token Streaming & UI Logic)
// Copyright (C) 2026 Cristian Evangelisti
// License: GPL-3.0-or-later
// Repository: https://github.com/kamaludu/bash4llm
// Contact: opensource@cevangel.anonaddy.me
// ======================================

'use strict';

// Compact DOM Helpers
const $ = id => document.getElementById(id);
const on = id => (evt, fn) => $(id)?.addEventListener(evt, fn);

let csrfToken = "";
let currentThreadId = "default";
let activeJobId = null;
let eventSource = null;

// Application Settings State
let currentProvider = "groq";
let currentModel = "";
let systemPrompt = "";
let temperature = 1.0;
let maxTokens = null;
let contextMode = "messages";
let threadWindow = 10;
let targetBytes = 32768;
let sanitizeOutput = true;
let attachedFiles = [];
let i18n = {};

// Translation helper for dynamic JavaScript strings and parameter replacement
function t(key, fallback = "", params = {}) {
  let text = i18n[key] || fallback || key;
  Object.keys(params).forEach(p => {
    text = text.split(`{${p}}`).join(params[p]);
  });
  return text;
}

// Save runtime settings to LocalStorage
function saveSettingsToLocalStorage() {
  localStorage.setItem("bash4llm_gui_settings", JSON.stringify({
    currentProvider, currentModel, systemPrompt, temperature,
    maxTokens, contextMode, threadWindow, targetBytes, sanitizeOutput
  }));
}

// Load runtime settings from LocalStorage
function loadSettingsFromLocalStorage() {
  try {
    const saved = localStorage.getItem("bash4llm_gui_settings");
    if (!saved) return;
    const s = JSON.parse(saved);

    currentProvider = s.currentProvider || currentProvider;
    currentModel = s.currentModel || currentModel;
    systemPrompt = s.systemPrompt ?? systemPrompt;
    temperature = s.temperature ?? temperature;
    maxTokens = s.maxTokens ?? maxTokens;
    contextMode = s.contextMode || contextMode;
    threadWindow = s.threadWindow ?? threadWindow;
    targetBytes = s.targetBytes ?? targetBytes;
    sanitizeOutput = s.sanitizeOutput ?? sanitizeOutput;

    // Synchronize UI form fields with loaded settings
    syncSettingsFormFields();
    updateActiveBadge();
  } catch (e) {
    console.warn("Failed to load settings from LocalStorage", e);
  }
}

// Synchronize Settings Modal inputs with active state
function syncSettingsFormFields() {
  if ($("input-system-prompt")) $("input-system-prompt").value = systemPrompt;
  if ($("input-temperature")) $("input-temperature").value = temperature;
  if ($("input-max-tokens")) $("input-max-tokens").value = maxTokens !== null ? maxTokens : "";
  if ($("select-context-mode")) $("select-context-mode").value = contextMode;
  if ($("input-thread-window")) $("input-thread-window").value = threadWindow;
  if ($("select-target-bytes")) $("select-target-bytes").value = targetBytes;
  if ($("check-sanitize")) $("check-sanitize").checked = sanitizeOutput;

  $("group-thread-window")?.classList.toggle("hidden", contextMode !== "messages");
  $("group-target-bytes")?.classList.toggle("hidden", contextMode !== "bytes");
}

// 1. Application Initialization Lifecycle
document.addEventListener("DOMContentLoaded", async () => {
  // A. Load fundamental UI localization (required across all views: index, error, help)
  await loadLocalization();

  // B. DEFENSE-IN-DEPTH EARLY-EXIT GUARD (Anti-Loop & Unauthenticated Protection)
  // Terminate initialization on static/informational views (error, help) or any view
  // lacking the primary interactive workspace form (#chat-form).
  // This prevents unauthenticated HTTP 401 API cascades and subsequent location.reload() loops.
  const pageType = document.body.dataset.page;
  const isStaticOrNonWorkspace = pageType === "error" || 
                                 pageType === "help" || 
                                 Boolean(document.querySelector(".error-layout, .help-layout")) ||
                                 !$("chat-form");

  if (isStaticOrNonWorkspace) {
    return;
  }

  // C. Interactive Workspace Initialization (Authenticated index.html only)
  setupEventListeners();
  loadSettingsFromLocalStorage();

  await Promise.allSettled([
    refreshStatus(),
    checkVaultStatus(),
    loadThreads(),
    loadProviders(),
    loadTemplates()
  ]);

  setInterval(sendHeartbeat, 8000);
});

async function loadLocalization() {
  const lang = ["de", "en", "es", "fr", "it"].includes((navigator.language || "en").slice(0, 2).toLowerCase())
    ? (navigator.language || "en").slice(0, 2).toLowerCase() : "en";
  try {
    const res = await fetch(`/langs/${lang}.json`);
    if (res.ok) {
      i18n = await res.json();
      applyLocalization();
    }
  } catch (e) {
    console.warn("Could not load localization file, using default text.");
  }
}

function applyLocalization() {
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const k = el.getAttribute("data-i18n");
    if (i18n[k]) el.textContent = i18n[k];
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
    const k = el.getAttribute("data-i18n-placeholder");
    if (i18n[k]) el.placeholder = i18n[k];
  });
  document.querySelectorAll("[data-i18n-title]").forEach(el => {
    const k = el.getAttribute("data-i18n-title");
    if (i18n[k]) el.title = i18n[k];
  });
}

async function apiFetch(url, options = {}) {
  options.headers = options.headers || {};
  if (csrfToken && ["POST", "PUT", "PATCH", "DELETE"].includes(options.method?.toUpperCase())) {
    options.headers["X-CSRF-Token"] = csrfToken;
  }
  options.credentials = "same-origin";
  const res = await fetch(url, options);
  if (res.status === 401) window.location.reload();
  return res;
}

async function refreshStatus() {
  try {
    const res = await apiFetch("/api/status");
    if (res.ok) {
      const data = await res.json();
      csrfToken = data.csrf_token;
      if ($("status-dot")) $("status-dot").className = "status-dot ready";
      if ($("status-text")) $("status-text").textContent = t("status_ready", "Ready");
    }
  } catch (e) {
    if ($("status-dot")) $("status-dot").className = "status-dot busy";
    if ($("status-text")) $("status-text").textContent = t("status_busy", "Busy");
  }
}

async function sendHeartbeat() {
  try { await apiFetch("/api/heartbeat", { method: "POST" }); } catch (e) {}
}

async function checkVaultStatus() {
  try {
    const res = await apiFetch("/api/vault/status");
    if (res.ok) {
      const data = await res.json();
      const banner = $("vault-status-banner");
      const text = $("vault-status-text");
      if (data.unlocked) {
        if (banner) banner.className = "vault-banner unlocked";
        if (text) text.textContent = t("vault_unlocked", "🔓 Vault Unlocked (Session Context Active)");
        $("vault-unlock-section")?.classList.add("hidden");
        $("vault-key-section")?.classList.remove("hidden");
      } else {
        if (banner) banner.className = "vault-banner";
        if (text) text.textContent = data.vault_exists
          ? t("vault_locked", "🔒 Vault Initialized (Locked)")
          : t("vault_not_init", "🔒 Vault Not Initialized");
        $("vault-unlock-section")?.classList.remove("hidden");
        $("vault-key-section")?.classList.add("hidden");
      }
    }
  } catch (e) {}
}

async function loadThreads() {
  try {
    const res = await apiFetch("/api/threads");
    if (res.ok) {
      const data = await res.json();
      const listEl = $("thread-list");
      if (!listEl) return;
      listEl.innerHTML = "";
      data.threads.forEach(tid => {
        const li = document.createElement("li");
        li.className = `thread-item ${tid === currentThreadId ? "active" : ""}`;
        li.textContent = tid;
        li.onclick = () => switchThread(tid);
        listEl.appendChild(li);
      });
    }
  } catch (e) {}
}

const toggleSidebar = active => {
  $("sidebar")?.classList.toggle("active", active);
  $("sidebar-overlay")?.classList.toggle("active", active);
};

async function switchThread(tid) {
  currentThreadId = tid;
  if ($("form-thread-id")) $("form-thread-id").value = tid;
  if ($("current-thread-title")) $("current-thread-title").textContent = tid;
  document.querySelectorAll(".thread-item").forEach(el => {
    el.classList.toggle("active", el.textContent === tid);
  });
  toggleSidebar(false);

  try {
    const res = await apiFetch(`/api/threads/${tid}`);
    renderChatHistory(res.ok ? (await res.json()).messages : []);
  } catch (e) {
    renderChatHistory([]);
  }
}

function renderChatHistory(messages) {
  const container = $("chat-messages");
  if (!container) return;
  container.innerHTML = "";
  if (Array.isArray(messages)) {
    messages.forEach(msg => appendMessageUI(msg.role, msg.content));
  }
  container.scrollTop = container.scrollHeight;
}

function appendMessageUI(role, content) {
  const container = $("chat-messages");
  if (!container) return null;
  const div = document.createElement("div");
  div.className = `message ${role}`;
  div.textContent = content;
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
  return div;
}

function populateSelect(id, items, selected = "", defaultOption = "", defaultOptionKey = "") {
  const el = $(id);
  if (!el) return;
  let html = "";
  if (defaultOption) {
    const i18nAttr = defaultOptionKey ? ` data-i18n="${defaultOptionKey}"` : "";
    html += `<option value=""${i18nAttr}>${defaultOption}</option>`;
  }
  html += items.map(i => `<option value="${i}" ${i === selected ? "selected" : ""}>${i}</option>`).join("");
  el.innerHTML = html;
}

async function loadProviders() {
  try {
    const res = await apiFetch("/api/providers");
    if (res.ok) {
      const data = await res.json();
      if (data.providers.length > 0) {
        if (!data.providers.includes(currentProvider)) {
          currentProvider = data.providers[0];
        }
        populateSelect("select-provider", data.providers, currentProvider);
        populateSelect("select-vault-provider", data.providers);
        await loadModelsForProvider(currentProvider);
      }
    }
  } catch (e) {}
}

async function loadModelsForProvider(prov) {
  try {
    const res = await apiFetch(`/api/models?provider=${encodeURIComponent(prov)}`);
    if (res.ok) {
      const data = await res.json();
      if (currentModel && data.models.includes(currentModel)) {
        // Retain active model
      } else if (data.default_model && data.models.includes(data.default_model)) {
        currentModel = data.default_model;
      } else if (data.models.length > 0) {
        currentModel = data.models[0];
      }
      populateSelect("select-model", data.models, currentModel);
      updateActiveBadge();
    }
  } catch (e) {}
}

async function loadTemplates() {
  try {
    const res = await apiFetch("/api/templates");
    if (res.ok) {
      populateSelect("select-template", (await res.json()).templates, "", t("no_template", "-- No Template --"), "no_template");
    }
  } catch (e) {}
}

function updateActiveBadge() {
  if ($("badge-provider")) $("badge-provider").textContent = currentProvider || "groq";
  if ($("badge-model")) $("badge-model").textContent = currentModel || "default";
}

function setupEventListeners() {
  on("btn-new-thread")("click", () => {
    const autoId = `thread-${new Date().toISOString().slice(2, 10).replace(/-/g, "")}-${Math.floor(Math.random() * 1000)}`;
    const userChoice = prompt(t("prompt_new_thread", "Enter new thread name:"), autoId);
    if (userChoice && userChoice.trim()) switchThread(userChoice.trim());
  });

  on("btn-toggle-sidebar")("click", () => toggleSidebar(true));
  on("btn-close-sidebar")("click", () => toggleSidebar(false));
  on("sidebar-overlay")("click", () => toggleSidebar(false));

  on("file-upload-input")("change", async e => {
    const file = e.target.files[0];
    if (!file) return;
    const formData = new FormData();
    formData.append("file", file);
    try {
      const res = await apiFetch("/api/upload", { method: "POST", body: formData });
      if (res.ok) {
        const data = await res.json();
        attachedFiles.push({ name: data.filename, path: data.file_path });
        renderAttachmentChips();
      }
    } catch (err) {
      alert(t("msg_upload_failed", "Failed to upload attachment."));
    }
    e.target.value = "";
  });

  on("select-context-mode")("change", e => {
    contextMode = e.target.value;
    $("group-thread-window")?.classList.toggle("hidden", contextMode !== "messages");
    $("group-target-bytes")?.classList.toggle("hidden", contextMode !== "bytes");
  });

  on("select-provider")("change", async e => {
    currentProvider = e.target.value;
    currentModel = "";
    await loadModelsForProvider(currentProvider);
  });

  on("btn-set-default-model")("click", async () => {
    const selectedM = $("select-model")?.value || "";
    if (!selectedM) return;
    try {
      const res = await apiFetch("/api/models/default", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: currentProvider, model: selectedM })
      });
      if (res.ok) {
        currentModel = selectedM;
        saveSettingsToLocalStorage();
        updateActiveBadge();
        alert(t("msg_default_set", `Default model for ${currentProvider} set to ${selectedM}`, { provider: currentProvider, model: selectedM }));
      }
    } catch (e) {}
  });

  on("btn-refresh-models")("click", async () => {
    try {
      const res = await apiFetch(`/api/models/refresh?provider=${encodeURIComponent(currentProvider)}`, { method: "POST" });
      if (res.ok) {
        await loadModelsForProvider(currentProvider);
        alert(t("msg_models_refreshed", "Models list refreshed from provider."));
      }
    } catch (e) {}
  });

  const form = $("chat-form");
  if (form) {
    form.addEventListener("submit", async e => {
      e.preventDefault();
      const promptInput = $("prompt-input");
      const prompt = promptInput ? promptInput.value.trim() : "";
      if (!prompt) return;

      appendMessageUI("user", prompt);
      if (promptInput) promptInput.value = "";

      const payload = {
        thread_id: currentThreadId,
        prompt: prompt,
        stream: true,
        provider: currentProvider,
        model: currentModel,
        system_prompt: systemPrompt || null,
        temperature: temperature,
        max_tokens: maxTokens,
        template: $("select-template")?.value || null,
        attachments: attachedFiles.map(a => a.path),
        validate_sml: $("check-sml-gate")?.checked || false,
        sanitize_output: sanitizeOutput,
        thread_window: contextMode === "messages" ? threadWindow : 0,
        target_bytes: contextMode === "bytes" ? targetBytes : null
      };

      attachedFiles = [];
      renderAttachmentChips();
      toggleInputState(true);

      try {
        const res = await apiFetch("/api/chat", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload)
        });

        if (res.status === 202) {
          const data = await res.json();
          activeJobId = data.job_id;
          startSSEStream(activeJobId);
        } else {
          const errData = await res.json().catch(() => ({ detail: t("err_submission_failed", "Error submitting job.") }));
          appendMessageUI("assistant", `[Error: ${errData.detail || t("err_submission_failed", "Error submitting job.")}]`);
          toggleInputState(false);
        }
      } catch (e) {
        appendMessageUI("assistant", `[Error: ${t("err_network_failed", "Network connection failed")}]`);
        toggleInputState(false);
      }
    });
  }

  on("btn-cancel")("click", cancelJob);

  // Settings Modal Handlers
  on("btn-settings")("click", () => {
    syncSettingsFormFields();
    if ($("select-provider")) $("select-provider").value = currentProvider;
    if ($("select-model")) $("select-model").value = currentModel;
    $("settings-modal")?.showModal();
  });
  on("btn-close-settings")("click", () => $("settings-modal")?.close());
  on("btn-save-settings")("click", () => {
    currentProvider = $("select-provider")?.value || currentProvider;
    currentModel = $("select-model")?.value || currentModel;
    systemPrompt = $("input-system-prompt")?.value.trim() || "";
    temperature = parseFloat($("input-temperature")?.value || "1.0");

    const maxTokVal = $("input-max-tokens")?.value;
    maxTokens = maxTokVal ? parseInt(maxTokVal) : null;

    threadWindow = parseInt($("input-thread-window")?.value || "10");
    targetBytes = parseInt($("select-target-bytes")?.value || "32768");
    sanitizeOutput = $("check-sanitize")?.checked ?? true;

    saveSettingsToLocalStorage();
    updateActiveBadge();
    $("settings-modal")?.close();
  });

  // Vault Modal Handlers
  on("btn-vault")("click", () => { checkVaultStatus(); $("vault-modal")?.showModal(); });
  on("btn-close-vault")("click", () => $("vault-modal")?.close());

  on("btn-unlock-vault")("click", async () => {
    const pass = $("input-master-password")?.value || "";
    if (!pass) return;
    try {
      const res = await apiFetch("/api/vault/unlock", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ master_password: pass })
      });
      if (res.ok) {
        if ($("input-master-password")) $("input-master-password").value = "";
        await checkVaultStatus();
      } else {
        alert(t("msg_invalid_password", "Invalid Master Password."));
      }
    } catch (e) {}
  });

  on("btn-save-vault-key")("click", async () => {
    const prov = $("select-vault-provider")?.value || "";
    const key = $("input-vault-api-key")?.value.trim() || "";
    if (!prov || !key) return;
    try {
      const res = await apiFetch("/api/vault/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: prov, api_key: key })
      });
      if (res.ok) {
        if ($("input-vault-api-key")) $("input-vault-api-key").value = "";
        alert(t("msg_key_saved", `API Key for ${prov} saved securely in OpenSSL Vault.`, { provider: prov }));
      } else {
        alert(t("msg_save_key_failed", "Failed to save API key."));
      }
    } catch (e) {}
  });

  // Snapshot Modal Handlers
  on("btn-thread-stats")("click", async () => {
    try {
      const res = await apiFetch(`/api/threads/${currentThreadId}/snapshot`);
      if (res.ok) {
        const data = await res.json();
        const detailsEl = $("snapshot-details");
        if (detailsEl) {
          detailsEl.innerHTML = data.stats ? `
            <strong>Thread ID:</strong> ${data.session_id}<br>
            <strong>Total Messages:</strong> ${data.stats.message_count}<br>
            <strong>Segment Files:</strong> ${data.stats.segments}<br>
            <strong>Total Byte Size:</strong> ${(data.stats.total_size_bytes / 1024).toFixed(2)} KB
          ` : JSON.stringify(data, null, 2);
        }
        $("snapshot-modal")?.showModal();
      }
    } catch (e) {}
  });

  on("btn-close-snapshot")("click", () => $("snapshot-modal")?.close());
}

function renderAttachmentChips() {
  const container = $("attachment-list");
  if (!container) return;
  container.innerHTML = "";
  attachedFiles.forEach((att, idx) => {
    const chip = document.createElement("div");
    chip.className = "chip-attachment";
    chip.innerHTML = `
      <span>📎 ${att.name}</span>
      <button type="button" class="btn-remove-chip">×</button>
    `;
    chip.querySelector(".btn-remove-chip").onclick = () => {
      attachedFiles.splice(idx, 1);
      renderAttachmentChips();
    };
    container.appendChild(chip);
  });
}

function startSSEStream(jobId) {
  const assistantMsgEl = appendMessageUI("assistant", "");
  eventSource = new EventSource(`/api/stream/${jobId}`);

  eventSource.addEventListener("token", e => {
    const data = JSON.parse(e.data);
    if (assistantMsgEl) assistantMsgEl.textContent += data.delta;
    const messagesEl = $("chat-messages");
    if (messagesEl) messagesEl.scrollTop = messagesEl.scrollHeight;
  });

  eventSource.addEventListener("done", e => {
    try {
      const data = JSON.parse(e.data);
      if (data.state === "FAILED" || data.error_code) {
        if (assistantMsgEl) {
          const errCode = data.error_code ? `Error ${data.error_code}` : "Execution Failed";
          const errReason = data.error_reason ? `: ${data.error_reason}` : "";
          assistantMsgEl.textContent += `\n[${errCode}${errReason}]`;
        }
      }
    } catch (err) {}

    eventSource.close();
    eventSource = null;
    activeJobId = null;
    toggleInputState(false);
    loadThreads();
  });

  eventSource.onerror = () => {
    if (eventSource) {
      eventSource.close();
      eventSource = null;
    }
    if (assistantMsgEl && !assistantMsgEl.textContent.trim()) {
      assistantMsgEl.textContent = `[Error: ${t("err_stream_disconnected", "Stream disconnected")}]`;
    }
    toggleInputState(false);
  };
}

async function cancelJob() {
  if (activeJobId) {
    await apiFetch(`/api/jobs/${activeJobId}/cancel`, { method: "POST" });
    if (eventSource) {
      eventSource.close();
      eventSource = null;
    }
    toggleInputState(false);
  }
}

function toggleInputState(isBusy) {
  if ($("btn-send")) $("btn-send").classList.toggle("hidden", isBusy);
  if ($("btn-cancel")) $("btn-cancel").classList.toggle("hidden", !isBusy);
  if ($("prompt-input")) $("prompt-input").disabled = isBusy;
}
