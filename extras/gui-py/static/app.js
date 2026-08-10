// bash4llm⁺ WebApp Vanilla ES6 Client
// SSE Token Streaming, Anti-CSRF Fetch Wrapper & Progressive Enhancement

let csrfToken = "";
let currentThreadId = "default";
let activeJobId = null;
let eventSource = null;
let currentProvider = null;
let currentModel = null;
let temperature = 1.0;
let threadWindow = 10;
let i18n = {};

// 1. Initialize Application
document.addEventListener("DOMContentLoaded", async () => {
  await loadLocalization();
  await refreshStatus();
  await loadThreads();
  await loadProvidersAndModels();
  setupEventListeners();
  setInterval(sendHeartbeat, 8000);
});

// Load Localization Dictionary from mounted /langs endpoint
async function loadLocalization() {
  const lang = navigator.language.startsWith("it") ? "it" : "en";
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

// Authenticated Anti-CSRF Fetch Wrapper
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
      document.getElementById("status-dot").className = "status-dot ready";
    }
  } catch (e) {
    document.getElementById("status-dot").className = "status-dot busy";
  }
}

async function sendHeartbeat() {
  try {
    await apiFetch("/api/heartbeat", { method: "POST" });
  } catch (e) {}
}

// Thread Navigation & History Loading
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
  listEl.innerHTML = "";
  threads.forEach(tid => {
    const li = document.createElement("li");
    li.className = `thread-item ${tid === currentThreadId ? "active" : ""}`;
    li.textContent = tid;
    li.onclick = () => switchThread(tid);
    listEl.appendChild(li);
  });
}

async function switchThread(tid) {
  currentThreadId = tid;
  document.getElementById("form-thread-id").value = tid;
  document.getElementById("current-thread-title").textContent = tid;
  document.querySelectorAll(".thread-item").forEach(el => {
    el.classList.toggle("active", el.textContent === tid);
  });
  
  // Close mobile sidebar drawer after thread selection
  const sidebar = document.getElementById("sidebar");
  if (sidebar) sidebar.classList.remove("active");

  // Load History
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
  const div = document.createElement("div");
  div.className = `message ${role}`;
  div.textContent = content;
  container.appendChild(div);
  container.scrollTop = container.scrollHeight;
  return div;
}

// Event Listeners Initialization
function setupEventListeners() {
  const form = document.getElementById("chat-form");
  const promptInput = document.getElementById("prompt-input");

  // New Thread Handler: Auto-generates ID, editable by user before switching
  const btnNewThread = document.getElementById("btn-new-thread");
  if (btnNewThread) {
    btnNewThread.addEventListener("click", () => {
      const autoId = `thread-${new Date().toISOString().slice(2, 10).replace(/-/g, "")}-${Math.floor(Math.random() * 1000)}`;
      const userChoice = prompt("Enter new thread name:", autoId);
      if (userChoice && userChoice.trim()) {
        const finalId = userChoice.trim();
        switchThread(finalId);
      }
    });
  }

  // Mobile Sidebar Toggle Handler
  const btnToggleSidebar = document.getElementById("btn-toggle-sidebar");
  if (btnToggleSidebar) {
    btnToggleSidebar.addEventListener("click", () => {
      const sidebar = document.getElementById("sidebar");
      if (sidebar) sidebar.classList.toggle("active");
    });
  }

  // Chat Form Submit (Triggered strictly by clicking the submit button)
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const prompt = promptInput.value.trim();
    if (!prompt) return;

    appendMessageUI("user", prompt);
    promptInput.value = "";

    const payload = {
      thread_id: currentThreadId,
      prompt: prompt,
      stream: true,
      thread_window: threadWindow,
      provider: currentProvider,
      model: currentModel,
      temperature: temperature
    };

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

  document.getElementById("btn-cancel").onclick = cancelJob;
  
  // Settings Modal Handlers
  const modal = document.getElementById("settings-modal");
  document.getElementById("btn-settings").onclick = () => modal.showModal();
  document.getElementById("btn-close-settings").onclick = () => modal.close();
  document.getElementById("btn-save-settings").onclick = () => {
    currentProvider = document.getElementById("select-provider").value;
    currentModel = document.getElementById("select-model").value;
    temperature = parseFloat(document.getElementById("input-temperature").value);
    threadWindow = parseInt(document.getElementById("input-thread-window").value);
    document.getElementById("badge-provider").textContent = currentProvider;
    document.getElementById("badge-model").textContent = currentModel;
    modal.close();
  };
}

function startSSEStream(jobId) {
  const assistantMsgEl = appendMessageUI("assistant", "");
  eventSource = new EventSource(`/api/stream/${jobId}`);

  eventSource.addEventListener("token", (e) => {
    const data = JSON.parse(e.data);
    assistantMsgEl.textContent += data.delta;
    document.getElementById("chat-messages").scrollTop = document.getElementById("chat-messages").scrollHeight;
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
  document.getElementById("btn-send").classList.toggle("hidden", isBusy);
  document.getElementById("btn-cancel").classList.toggle("hidden", !isBusy);
  document.getElementById("prompt-input").disabled = isBusy;
}

async function loadProvidersAndModels() {
  try {
    const resP = await apiFetch("/api/providers");
    if (resP.ok) {
      const dataP = await resP.json();
      const selectP = document.getElementById("select-provider");
      selectP.innerHTML = dataP.providers.map(p => `<option value="${p}">${p}</option>`).join("");
      if (dataP.providers.length > 0) currentProvider = dataP.providers[0];
    }

    const resM = await apiFetch("/api/models");
    if (resM.ok) {
      const dataM = await resM.json();
      const selectM = document.getElementById("select-model");
      selectM.innerHTML = dataM.models.map(m => `<option value="${m}">${m}</option>`).join("");
      if (dataM.models.length > 0) currentModel = dataM.models[0];
    }

    document.getElementById("badge-provider").textContent = currentProvider || "groq";
    document.getElementById("badge-model").textContent = currentModel || "default";
  } catch (e) {}
}
