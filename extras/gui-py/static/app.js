
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
let selectedTemplate = "";
let validateSml = false;
let sanitizeOutput = true;
let attachedFiles = [];

let i18n = {};

// 1. Initialize Application
document.addEventListener("DOMContentLoaded", async () => {
  setupEventListeners();

  try { await loadLocalization(); } catch (e) {}
  try { await refreshStatus(); } catch (e) {}
  try { await checkVaultStatus(); } catch (e) {}
  try { await loadThreads(); } catch (e) {}
  try { await loadProviders(); } catch (e) {}
  try { await loadTemplates(); } catch (e) {}

  setInterval(sendHeartbeat, 8000);
});

async function loadLocalization() {
  const supportedLangs = ["de", "en", "es", "fr", "it"];

  // Extract 2-letter primary language code (e.g., "fr-FR" -> "fr")
  const userLang = (navigator.language || "en").slice(0, 2).toLowerCase();

  // Match against supported languages list, defaulting to English
  const lang = supportedLangs.includes(userLang) ? userLang : "en";

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
    const key = el.getAttribute("data-i18n");
    if (i18n[key]) el.textContent = i18n[key];
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
    const key = el.getAttribute("data-i18n-placeholder");
    if (i18n[key]) el.placeholder = i18n[key];
  });
}

async function apiFetch(url, options = {}) {
  options.headers = options.headers || {};
  if (csrfToken && ["POST", "PUT", "PATCH", "DELETE"].includes(options.method?.toUpperCase())) {
    options.headers["X-CSRF-Token"] = csrfToken;
  }
  options.credentials = "same-origin";
  
  const response = await fetch(url, options);
  if (response.status === 401) {
    window.location.reload();
  }
  return response;
}

async function refreshStatus() {
  try {
    const res = await apiFetch("/api/status");
    if (res.ok) {
      const data = await res.json();
      csrfToken = data.csrf_token;
      const statusDot = document.getElementById("status-dot");
      if (statusDot) statusDot.className = "status-dot ready";
    }
  } catch (e) {
    const statusDot = document.getElementById("status-dot");
    if (statusDot) statusDot.className = "status-dot busy";
  }
}

async function sendHeartbeat() {
  try {
    await apiFetch("/api/heartbeat", { method: "POST" });
  } catch (e) {}
}

async function checkVaultStatus() {
  try {
    const res = await apiFetch("/api/vault/status");
    if (res.ok) {
      const data = await res.json();
      const banner = document.getElementById("vault-status-banner");
      const text = document.getElementById("vault-status-text");
      const unlockSec = document.getElementById("vault-unlock-section");
      const keySec = document.getElementById("vault-key-section");

      if (data.unlocked) {
        if (banner) banner.className = "vault-banner unlocked";
        if (text) text.textContent = "🔓 Vault Unlocked (Session Context Active)";
        if (unlockSec) unlockSec.classList.add("hidden");
        if (keySec) keySec.classList.remove("hidden");
      } else {
        if (banner) banner.className = "vault-banner";
        if (text) text.textContent = data.vault_exists ? "🔒 Vault Initialized (Locked)" : "🔒 Vault Not Initialized";
        if (unlockSec) unlockSec.classList.remove("hidden");
        if (keySec) keySec.classList.add("hidden");
      }
    }
  } catch (e) {}
}

async function loadThreads() {
  try {
    const res = await apiFetch("/api/threads");
    if (res.ok) {
      const data = await res.json();
      renderThreadList(data.threads);
    }
  } catch (e) {}
}

function renderThreadList(threads) {
  const listEl = document.getElementById("thread-list");
  if (!listEl) return;
  listEl.innerHTML = "";
  threads.forEach(tid => {
    const li = document.createElement("li");
    li.className = `thread-item ${tid === currentThreadId ? "active" : ""}`;
    li.textContent = tid;
    li.onclick = () => switchThread(tid);
    listEl.appendChild(li);
  });
}

function closeSidebar() {
  const sidebar = document.getElementById("sidebar");
  const overlay = document.getElementById("sidebar-overlay");
  if (sidebar) sidebar.classList.remove("active");
  if (overlay) overlay.classList.remove("active");
}

function openSidebar() {
  const sidebar = document.getElementById("sidebar");
  const overlay = document.getElementById("sidebar-overlay");
  if (sidebar) sidebar.classList.add("active");
  if (overlay) overlay.classList.add("active");
}

async function switchThread(tid) {
  currentThreadId = tid;
  const formThreadId = document.getElementById("form-thread-id");
  const threadTitle = document.getElementById("current-thread-title");
  if (formThreadId) formThreadId.value = tid;
  if (threadTitle) threadTitle.textContent = tid;

  document.querySelectorAll(".thread-item").forEach(el => {
    el.classList.toggle("active", el.textContent === tid);
  });
  
  closeSidebar();

  try {
    const res = await apiFetch(`/api/threads/${tid}`);
    if (res.ok) {
      const data = await res.json();
      renderChatHistory(data.messages);
    } else {
      renderChatHistory([]);
    }
  } catch (e) {
    renderChatHistory([]);
  }
}

function renderChatHistory(messages) {
  const container = document.getElementById("chat-messages");
  if (!container) return;
  container.innerHTML = "";
  if (Array.isArray(messages)) {
    messages.forEach(msg => {
      appendMessageUI(msg.role, msg.content);
    });
  }
  container.scrollTop = container.scrollHeight;
}

function appendMessageUI(role, content) {
  const container = document.getElementById("chat-messages");
  if (!container) return null;
  const div = document.createElement("div");
  div.className = `message ${role}`;
  div.textContent = content;
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
  return div;
}

async function loadProviders() {
  try {
    const res = await apiFetch("/api/providers");
    if (res.ok) {
      const data = await res.json();
      const selectP = document.getElementById("select-provider");
      const selectVP = document.getElementById("select-vault-provider");
      
      const optionsHtml = data.providers.map(p => `<option value="${p}">${p}</option>`).join("");
      if (selectP) selectP.innerHTML = optionsHtml;
      if (selectVP) selectVP.innerHTML = optionsHtml;

      if (data.providers.length > 0) {
        currentProvider = data.providers[0];
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
      const selectM = document.getElementById("select-model");
      if (selectM) {
        selectM.innerHTML = data.models.map(m => `<option value="${m}">${m}</option>`).join("");
        if (data.default_model && data.models.includes(data.default_model)) {
          selectM.value = data.default_model;
          currentModel = data.default_model;
        } else if (data.models.length > 0) {
          currentModel = data.models[0];
        }
      }
      updateActiveBadge();
    }
  } catch (e) {}
}

async function loadTemplates() {
  try {
    const res = await apiFetch("/api/templates");
    if (res.ok) {
      const data = await res.json();
      const selectT = document.getElementById("select-template");
      if (selectT) {
        selectT.innerHTML = `<option value="">-- No Template --</option>` +
          data.templates.map(t => `<option value="${t}">${t}</option>`).join("");
      }
    }
  } catch (e) {}
}

function updateActiveBadge() {
  const badgeP = document.getElementById("badge-provider");
  const badgeM = document.getElementById("badge-model");
  if (badgeP) badgeP.textContent = currentProvider || "groq";
  if (badgeM) badgeM.textContent = currentModel || "default";
}

function setupEventListeners() {
  const form = document.getElementById("chat-form");
  const promptInput = document.getElementById("prompt-input");

  // New Thread
  document.getElementById("btn-new-thread")?.addEventListener("click", () => {
    const autoId = `thread-${new Date().toISOString().slice(2, 10).replace(/-/g, "")}-${Math.floor(Math.random() * 1000)}`;
    const userChoice = prompt("Enter new thread name:", autoId);
    if (userChoice && userChoice.trim()) {
      switchThread(userChoice.trim());
    }
  });

  // Mobile Sidebar Toggle and Close
  document.getElementById("btn-toggle-sidebar")?.addEventListener("click", openSidebar);
  document.getElementById("btn-close-sidebar")?.addEventListener("click", closeSidebar);
  document.getElementById("sidebar-overlay")?.addEventListener("click", closeSidebar);

  // File Attachment Upload (-f)
  document.getElementById("file-upload-input")?.addEventListener("change", async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await apiFetch("/api/upload", {
        method: "POST",
        body: formData
      });
      if (res.ok) {
        const data = await res.json();
        attachedFiles.push({ name: data.filename, path: data.file_path });
        renderAttachmentChips();
      }
    } catch (err) {
      alert("Failed to upload attachment.");
    }
    e.target.value = "";
  });

  // Context Window Strategy Switch
  document.getElementById("select-context-mode")?.addEventListener("change", (e) => {
    contextMode = e.target.value;
    document.getElementById("group-thread-window")?.classList.toggle("hidden", contextMode !== "messages");
    document.getElementById("group-target-bytes")?.classList.toggle("hidden", contextMode !== "bytes");
  });

  // Provider Selection Change -> Reload Models
  document.getElementById("select-provider")?.addEventListener("change", async (e) => {
    const newProv = e.target.value;
    currentProvider = newProv;
    await loadModelsForProvider(newProv);
  });

  // Set Default Model Button
  document.getElementById("btn-set-default-model")?.addEventListener("click", async () => {
    const selectM = document.getElementById("select-model");
    const selectedM = selectM ? selectM.value : "";
    if (!selectedM) return;
    try {
      const res = await apiFetch("/api/models/default", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: currentProvider, model: selectedM })
      });
      if (res.ok) {
        currentModel = selectedM;
        updateActiveBadge();
        alert(`Default model for ${currentProvider} set to ${selectedM}`);
      }
    } catch (e) {}
  });

  // Refresh Models Button
  document.getElementById("btn-refresh-models")?.addEventListener("click", async () => {
    try {
      const res = await apiFetch(`/api/models/refresh?provider=${encodeURIComponent(currentProvider)}`, { method: "POST" });
      if (res.ok) {
        await loadModelsForProvider(currentProvider);
        alert("Models list refreshed from provider.");
      }
    } catch (e) {}
  });

  // Submit Chat Form
  if (form) {
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
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
        template: document.getElementById("select-template")?.value || null,
        attachments: attachedFiles.map(a => a.path),
        validate_sml: document.getElementById("check-sml-gate")?.checked || false,
        sanitize_output: sanitizeOutput
      };

      if (contextMode === "messages") {
        payload.thread_window = threadWindow;
        payload.target_bytes = null;
      } else {
        payload.thread_window = 0;
        payload.target_bytes = targetBytes;
      }

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
          appendMessageUI("assistant", "Error submitting job.");
          toggleInputState(false);
        }
      } catch (e) {
        appendMessageUI("assistant", "Network error.");
        toggleInputState(false);
      }
    });
  }

  const btnCancel = document.getElementById("btn-cancel");
  if (btnCancel) btnCancel.onclick = cancelJob;
  
  // Settings Modal Handlers
  const modalSettings = document.getElementById("settings-modal");
  document.getElementById("btn-settings")?.addEventListener("click", () => modalSettings?.showModal());
  document.getElementById("btn-close-settings")?.addEventListener("click", () => modalSettings?.close());
  document.getElementById("btn-save-settings")?.addEventListener("click", () => {
    const selP = document.getElementById("select-provider");
    const selM = document.getElementById("select-model");
    const inputSys = document.getElementById("input-system-prompt");
    const inputTemp = document.getElementById("input-temperature");
    const inputMaxTok = document.getElementById("input-max-tokens");
    const inputWin = document.getElementById("input-thread-window");
    const selBytes = document.getElementById("select-target-bytes");
    const checkSan = document.getElementById("check-sanitize");

    if (selP) currentProvider = selP.value;
    if (selM) currentModel = selM.value;
    if (inputSys) systemPrompt = inputSys.value.trim();
    if (inputTemp) temperature = parseFloat(inputTemp.value);
    
    const maxTokVal = inputMaxTok ? inputMaxTok.value : "";
    maxTokens = maxTokVal ? parseInt(maxTokVal) : null;
    
    if (inputWin) threadWindow = parseInt(inputWin.value);
    if (selBytes) targetBytes = parseInt(selBytes.value);
    if (checkSan) sanitizeOutput = checkSan.checked;

    updateActiveBadge();
    modalSettings?.close();
  });

  // Vault Modal Handlers
  const modalVault = document.getElementById("vault-modal");
  document.getElementById("btn-vault")?.addEventListener("click", () => {
    checkVaultStatus();
    modalVault?.showModal();
  });
  document.getElementById("btn-close-vault")?.addEventListener("click", () => modalVault?.close());

  // Vault Unlock Button
  document.getElementById("btn-unlock-vault")?.addEventListener("click", async () => {
    const inputPass = document.getElementById("input-master-password");
    const pass = inputPass ? inputPass.value : "";
    if (!pass) return;

    try {
      const res = await apiFetch("/api/vault/unlock", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ master_password: pass })
      });
      if (res.ok) {
        if (inputPass) inputPass.value = "";
        await checkVaultStatus();
      } else {
        alert("Invalid Master Password.");
      }
    } catch (e) {}
  });

  // Save Encrypted API Key
  document.getElementById("btn-save-vault-key")?.addEventListener("click", async () => {
    const selVP = document.getElementById("select-vault-provider");
    const inputKey = document.getElementById("input-vault-api-key");
    const prov = selVP ? selVP.value : "";
    const key = inputKey ? inputKey.value.trim() : "";
    if (!prov || !key) return;

    try {
      const res = await apiFetch("/api/vault/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: prov, api_key: key })
      });
      if (res.ok) {
        if (inputKey) inputKey.value = "";
        alert(`API Key for ${prov} saved securely in OpenSSL Vault.`);
      } else {
        alert("Failed to save API key.");
      }
    } catch (e) {}
  });

  // Session Engine Snapshot Stats Modal
  const modalSnapshot = document.getElementById("snapshot-modal");
  document.getElementById("btn-thread-stats")?.addEventListener("click", async () => {
    try {
      const res = await apiFetch(`/api/threads/${currentThreadId}/snapshot`);
      if (res.ok) {
        const data = await res.json();
        const detailsEl = document.getElementById("snapshot-details");
        if (detailsEl) {
          if (data.stats) {
            detailsEl.innerHTML = `
              <strong>Thread ID:</strong> ${data.session_id}<br>
              <strong>Total Messages:</strong> ${data.stats.message_count}<br>
              <strong>Segment Files:</strong> ${data.stats.segments}<br>
              <strong>Total Byte Size:</strong> ${(data.stats.total_size_bytes / 1024).toFixed(2)} KB
            `;
          } else {
            detailsEl.textContent = JSON.stringify(data, null, 2);
          }
        }
        modalSnapshot?.showModal();
      }
    } catch (e) {}
  });
  const btnCloseSnapshot = document.getElementById("btn-close-snapshot");
  if (btnCloseSnapshot) btnCloseSnapshot.onclick = () => modalSnapshot?.close();
}

function renderAttachmentChips() {
  const container = document.getElementById("attachment-list");
  if (!container) return;
  container.innerHTML = "";
  attachedFiles.forEach((att, idx) => {
    const chip = document.createElement("div");
    chip.className = "chip-attachment";
    chip.innerHTML = `
      <span>📎 ${att.name}</span>
      <button type="button" class="btn-remove-chip" data-idx="${idx}">×</button>
    `;
    const btnRemove = chip.querySelector(".btn-remove-chip");
    if (btnRemove) {
      btnRemove.onclick = () => {
        attachedFiles.splice(idx, 1);
        renderAttachmentChips();
      };
    }
    container.appendChild(chip);
  });
}

function startSSEStream(jobId) {
  const assistantMsgEl = appendMessageUI("assistant", "");
  eventSource = new EventSource(`/api/stream/${jobId}`);

  eventSource.addEventListener("token", (e) => {
    const data = JSON.parse(e.data);
    if (assistantMsgEl) assistantMsgEl.textContent += data.delta;
    const messagesEl = document.getElementById("chat-messages");
    if (messagesEl) messagesEl.scrollTop = messagesEl.scrollHeight;
  });

  eventSource.addEventListener("done", (e) => {
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
      assistantMsgEl.textContent = "[Error: Stream disconnected]";
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
  const btnSend = document.getElementById("btn-send");
  const btnCancel = document.getElementById("btn-cancel");
  const promptInput = document.getElementById("prompt-input");

  if (btnSend) btnSend.classList.toggle("hidden", isBusy);
  if (btnCancel) btnCancel.classList.toggle("hidden", !isBusy);
  if (promptInput) promptInput.disabled = isBusy;
}
