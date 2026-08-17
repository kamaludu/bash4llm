#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/gui-py/main.py
# Component: Main Entrypoint Server Adapter for bash4llm⁺ WebApp GUI
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================

import asyncio
from contextlib import asynccontextmanager
import hashlib
import json
import os
import secrets
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
from typing import Dict, Optional, Tuple, List, Any

import uvicorn
from fastapi import FastAPI, Request, Response, HTTPException, status, Depends, Header, UploadFile, File
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles

from config import Config
from models import (
    Job, JobState, TerminationCause, ChatRequest, RenameThreadRequest,
    VaultUnlockRequest, VaultKeyRequest, SetDefaultModelRequest
)
from security import (
    validate_runtime_tmpdir,
    acquire_single_instance_lock,
    verify_security_headers
)
from ipc import (
    execute_job_subprocess,
    cancel_job_process,
    read_thread_history_ndjson,
    get_session_snapshot_ipc,
    test_vault_unlock_ipc,
    save_vault_api_key_ipc,
    get_vault_keys_ipc,
    THREAD_ID_REGEX
)

# Termux / Android Environment Detection
IS_TERMUX = "TERMUX_VERSION" in os.environ or os.path.exists("/data/data/com.termux")

# Runtime Memory State
config = Config()
active_one_time_token: Optional[str] = secrets.token_hex(32)
active_csrf_token: str = secrets.token_hex(32)
sessions: Dict[str, float] = {}                    # session_id -> last_seen_timestamp
jobs_registry: Dict[str, Job] = {}
job_queues: Dict[str, asyncio.Queue] = {}
idempotency_store: Dict[Tuple[str, str], Job] = {}  # (session_id, key) -> Job

server_has_seen_first_client: bool = False
grace_started_at: Optional[float] = None


def _safe_int(value: Any, default: Optional[int] = None) -> Optional[int]:
    if value is None:
        return default
    val_str = str(value).strip()
    if not val_str:
        return default
    try:
        return int(float(val_str))
    except (ValueError, TypeError):
        return default


def _safe_float(value: Any, default: Optional[float] = None) -> Optional[float]:
    if value is None:
        return default
    val_str = str(value).strip()
    if not val_str:
        return default
    try:
        return float(val_str)
    except (ValueError, TypeError):
        return default


def _get_threads_index_path() -> str:
    threads_dir = os.path.join(config.BASH4LLM_CONFIG_DIR, "ui_state", "threads")
    os.makedirs(threads_dir, mode=0o700, exist_ok=True)
    return os.path.join(threads_dir, "index.json")


def _read_persisted_threads() -> List[str]:
    index_file = _get_threads_index_path()
    threads_set = {"default"}
    if os.path.isfile(index_file):
        try:
            with open(index_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                raw_threads = data.get("threads", [])
                for t in raw_threads:
                    tid = t if isinstance(t, str) else t.get("id")
                    if tid and THREAD_ID_REGEX.match(str(tid)):
                        threads_set.add(str(tid))
        except Exception:
            pass
    
    return sorted(list(threads_set), key=lambda x: (x != "default", x))


def _save_thread_to_index(thread_id: str) -> None:
    if not THREAD_ID_REGEX.match(thread_id):
        return
    threads = _read_persisted_threads()
    if thread_id not in threads:
        threads.append(thread_id)
        threads = sorted(list(set(threads)), key=lambda x: (x != "default", x))
    index_file = _get_threads_index_path()
    try:
        with open(index_file, "w", encoding="utf-8") as f:
            json.dump({"threads": threads}, f, indent=2)
    except Exception:
        pass


def _remove_thread_from_index(thread_id: str) -> None:
    threads = [t for t in _read_persisted_threads() if t != thread_id]
    if "default" not in threads:
        threads.insert(0, "default")
    index_file = _get_threads_index_path()
    try:
        with open(index_file, "w", encoding="utf-8") as f:
            json.dump({"threads": threads}, f, indent=2)
    except Exception:
        pass


def get_canonical_env() -> Dict[str, str]:
    """
    Constructs an authoritative environment dictionary for all subprocess invocations.
    Guarantees that bash4llm never falls back to unaligned relative paths.
    """
    env = {
        k: v for k, v in os.environ.items()
        if not (k.endswith("_SECRET") or (k.endswith("_TOKEN") and k != "BASH4LLM_AUTH_TOKEN"))
    }
    env["BASH4LLM_DIR"] = config.BASH4LLM_DIR
    env["BASH4LLM_TMPDIR"] = config.BASH4LLM_TMPDIR
    env["BASH4LLM_CONFIG_DIR"] = config.BASH4LLM_CONFIG_DIR
    env["BASH4LLM_HISTORY_DIR"] = config.BASH4LLM_HISTORY_DIR
    env["BASH4LLM_RUN_DIR"] = config.BASH4LLM_RUN_DIR
    env["BASH4LLM_EXTRAS_DIR"] = config.BASH4LLM_EXTRAS_DIR
    env["BASH4LLM_TEMPLATES_DIR"] = config.BASH4LLM_TEMPLATES_DIR
    env["RUN_TMPDIR"] = config.BASH4LLM_TMPDIR

    if config.vault_session_context:
        env["_B4L_RT_CTX"] = config.vault_session_context

    return env


def prune_expired_memory_records() -> None:
    """
    Prevents unbounded RAM growth by evicting completed jobs older than 2 hours
    or trimming excess capacity while protecting active executing jobs.
    """
    now = time.time()
    MAX_RECORDS = 200
    TTL_SECONDS = 7200.0

    expired_job_ids = [
        jid for jid, j in jobs_registry.items()
        if j.completed_at and (now - j.completed_at) > TTL_SECONDS
    ]
    for jid in expired_job_ids:
        jobs_registry.pop(jid, None)

    if len(jobs_registry) > MAX_RECORDS:
        inactive_jids = [
            jid for jid, j in jobs_registry.items()
            if j.state in (JobState.COMPLETED, JobState.FAILED, JobState.CANCELLED)
        ]
        sorted_inactive = sorted(
            inactive_jids,
            key=lambda k: jobs_registry[k].created_at
        )
        excess_count = len(jobs_registry) - MAX_RECORDS
        for jid in sorted_inactive[:excess_count]:
            jobs_registry.pop(jid, None)

    expired_idem_keys = [
        k for k, j in idempotency_store.items()
        if j.completed_at and (now - j.completed_at) > TTL_SECONDS
    ]
    for k in expired_idem_keys:
        idempotency_store.pop(k, None)


async def graceful_shutdown_checker():
    """
    Monitors server lifecycle, triggers idle shutdown and prunes expired RAM objects.
    """
    global grace_started_at, server_has_seen_first_client
    CLIENT_ACTIVITY_WINDOW = 1800.0  # 30 minutes client activity window
    IDLE_GRACE_PERIOD = 1800.0       # 30 minutes idle grace period before shutdown

    while True:
        await asyncio.sleep(2.0)
        prune_expired_memory_records()

        if not server_has_seen_first_client:
            continue

        now = time.time()
        active_clients = sum(1 for last_seen in sessions.values() if (now - last_seen) <= CLIENT_ACTIVITY_WINDOW)
        active_jobs = sum(
            1 for job in jobs_registry.values()
            if job.state in {
                JobState.CREATED, JobState.STARTING, JobState.RUNNING,
                JobState.STREAMING, JobState.CANCEL_REQUESTED
            }
        )

        if active_clients == 0 and active_jobs == 0:
            if grace_started_at is None:
                grace_started_at = now
            elif (now - grace_started_at) >= IDLE_GRACE_PERIOD:
                print(f"Graceful shutdown conditions met ({int(IDLE_GRACE_PERIOD)}s idle). Stopping server...")
                os.kill(os.getpid(), signal.SIGINT)
                break
        else:
            grace_started_at = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    asyncio.create_task(graceful_shutdown_checker())
    yield


app = FastAPI(
    title="bash4llm WebApp Adapter",
    docs_url=None,
    redoc_url=None,
    lifespan=lifespan
)

# Mount Static Files and Languages Directories
static_dir = os.path.join(config.script_dir, "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

langs_dir = os.path.join(config.script_dir, "langs")
if os.path.exists(langs_dir):
    app.mount("/langs", StaticFiles(directory=langs_dir), name="langs")


def render_error_page(status_code: int, title: str, message: str) -> HTMLResponse:
    """
    Safely renders error.html by replacing template placeholders server-side.
    """
    error_html_path = os.path.join(static_dir, "error.html")
    if os.path.exists(error_html_path):
        try:
            with open(error_html_path, "r", encoding="utf-8") as f:
                template = f.read()
            content = (
                template
                .replace("{{ERROR_STATUS_CODE}}", f"HTTP {status_code}")
                .replace("{{ERROR_TITLE}}", title)
                .replace("{{ERROR_MESSAGE}}", message)
            )
            return HTMLResponse(content=content, status_code=status_code)
        except Exception:
            pass
    return HTMLResponse(
        content=f"<h1>HTTP {status_code} - {title}</h1><p>{message}</p>",
        status_code=status_code
    )


def _render_index_html() -> HTMLResponse:
    """
    Centralized helper to render index.html with HTTP 200 OK.
    Guarantees visual and functional parity between / and /auth endpoints.
    """
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        try:
            with open(index_path, "r", encoding="utf-8") as f:
                return HTMLResponse(content=f.read(), status_code=status.HTTP_200_OK)
        except Exception:
            pass
    return HTMLResponse(content="<h1>bash4llm WebApp</h1>", status_code=status.HTTP_200_OK)


def find_available_loopback_port(start_port: int = 19970, max_attempts: int = 100) -> int:
    for port in range(start_port, start_port + max_attempts):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("127.0.0.1", port))
                return port
            except OSError:
                continue
    raise RuntimeError("No free loopback port found in range.")


def get_current_session(request: Request) -> str:
    session_id = request.cookies.get("session_id")
    if not session_id or session_id not in sessions:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized session")
    sessions[session_id] = time.time()
    global server_has_seen_first_client
    server_has_seen_first_client = True
    return session_id


@app.middleware("http")
async def protect_html_routes_middleware(request: Request, call_next):
    path = request.url.path
    if path in ("/", "/index.html"):
        session_id = request.cookies.get("session_id")
        if not session_id or session_id not in sessions:
            return render_error_page(
                status_code=status.HTTP_401_UNAUTHORIZED,
                title="Session Missing or Expired",
                message="Your session is missing, expired, or access was denied by the backend security layer."
            )
    return await call_next(request)


@app.exception_handler(HTTPException)
async def custom_http_exception_handler(request: Request, exc: HTTPException):
    accept_header = request.headers.get("accept", "").lower()
    is_html_request = "text/html" in accept_header and not request.url.path.startswith("/api")

    if not is_html_request:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})

    status_code = exc.status_code
    title_map = {
        400: "Bad Request",
        401: "Authentication Required",
        403: "Access Forbidden",
        404: "Page Not Found",
        405: "Method Not Allowed",
        409: "Conflict",
        422: "Unprocessable Entity",
        500: "Internal Server Error"
    }
    title = title_map.get(status_code, f"HTTP Error {status_code}")
    return render_error_page(
        status_code=status_code,
        title=title,
        message=str(exc.detail) if exc.detail else "An HTTP error occurred."
    )


@app.get("/auth")
async def authenticate(one_time_token: str, request: Request):
    """
    Validates single-use authentication token and directly establishes the authenticated GUI session.
    Eliminates intermediate 302 redirects to prevent browser cookie drops on external invocations.
    Executes synchronous in-memory token consumption without yields.
    """
    global active_one_time_token
    token_to_verify = active_one_time_token
    active_one_time_token = None  # Consume token immediately in memory before verification

    if not token_to_verify or not secrets.compare_digest(one_time_token, token_to_verify):
        return render_error_page(
            status_code=status.HTTP_401_UNAUTHORIZED,
            title="Invalid or Spent Token",
            message="The one-time authentication token provided in the URL is invalid, already spent, or expired."
        )
    
    new_session_id = secrets.token_hex(32)
    sessions[new_session_id] = time.time()
    
    global server_has_seen_first_client
    server_has_seen_first_client = True

    response = _render_index_html()
    response.set_cookie(
        key="session_id",
        value=new_session_id,
        httponly=True,
        samesite="strict",
        path="/"
    )
    return response


@app.get("/")
@app.get("/index.html")
async def root(session_id: str = Depends(get_current_session)):
    return _render_index_html()


@app.get("/api/status")
async def get_status(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    now = time.time()
    active_clients = sum(1 for last_seen in sessions.values() if (now - last_seen) <= 1800.0)
    active_jobs = sum(1 for job in jobs_registry.values() if job.state in (JobState.RUNNING, JobState.STREAMING))
    
    return {
        "server": "READY",
        "active_clients": active_clients,
        "active_jobs": active_jobs,
        "csrf_token": active_csrf_token,
        "vault_unlocked": config.vault_session_context is not None
    }


@app.post("/api/heartbeat")
async def heartbeat(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    sessions[session_id] = time.time()
    return {"status": "ok"}


@app.post("/api/shutdown")
async def shutdown_server(request: Request, session_id: str = Depends(get_current_session)):
    """
    Triggers clean graceful shutdown of the GUI adapter instance.
    """
    verify_security_headers(request, active_csrf_token, session_id)
    
    def _trigger_shutdown():
        time.sleep(0.5)
        os.kill(os.getpid(), signal.SIGINT)

    threading.Thread(target=_trigger_shutdown, daemon=True).start()
    return {"status": "shutting_down", "message": "Server shutdown initiated."}


@app.get("/api/models")
async def list_models(
    request: Request,
    provider: Optional[str] = None,
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)
    
    active_provider = provider
    if not active_provider:
        provider_file = os.path.join(config.BASH4LLM_CONFIG_DIR, "provider")
        if os.path.isfile(provider_file):
            try:
                with open(provider_file, "r", encoding="utf-8") as f:
                    line = f.readline().strip()
                    if line:
                        active_provider = line
            except Exception:
                pass
    active_provider = active_provider or "groq"

    cmd = ["bash", config.core_script_path, "--provider", active_provider, "--list-models-raw"]

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=get_canonical_env()
    )
    stdout, _ = await proc.communicate()
    models = [line.strip() for line in stdout.decode('utf-8', errors='replace').splitlines() if line.strip()]

    model_file = os.path.join(config.BASH4LLM_CONFIG_DIR, f"model.{active_provider}")
    default_model = None
    if os.path.isfile(model_file):
        try:
            with open(model_file, "r", encoding="utf-8") as f:
                line = f.readline().strip()
                if line:
                    default_model = line
        except Exception:
            pass

    return {
        "models": models,
        "provider": active_provider,
        "default_model": default_model
    }


@app.post("/api/models/default")
async def set_default_model(
    payload: SetDefaultModelRequest,
    request: Request,
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)
    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path,
        "--provider", payload.provider,
        "--set-default", payload.model,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=get_canonical_env()
    )
    await proc.communicate()
    if proc.returncode != 0:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to set default model")
    return {"status": "default_model_set", "provider": payload.provider, "model": payload.model}


@app.post("/api/models/refresh")
async def refresh_models(
    request: Request,
    provider: Optional[str] = None,
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)
    cmd = ["bash", config.core_script_path]
    if provider:
        cmd.extend(["--provider", provider])
    cmd.append("--refresh-models")

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=get_canonical_env()
    )
    await proc.communicate()
    if proc.returncode != 0:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to refresh models")
    return {"status": "refreshed", "provider": provider or "default"}


@app.get("/api/providers")
async def list_providers(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--list-providers-raw",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=get_canonical_env()
    )
    stdout, _ = await proc.communicate()
    providers = [line.strip() for line in stdout.decode('utf-8', errors='replace').splitlines() if line.strip()]
    return {"providers": providers}


@app.get("/api/templates")
async def list_templates(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    templates_dir = config.BASH4LLM_TEMPLATES_DIR
    templates = []
    if os.path.exists(templates_dir) and os.path.isdir(templates_dir):
        for fname in sorted(os.listdir(templates_dir)):
            if fname.endswith(".txt") and not fname.startswith("."):
                templates.append(fname)
    return {"templates": templates}


@app.get("/api/vault/status")
async def get_vault_status(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    vault_file = os.path.join(config.BASH4LLM_CONFIG_DIR, "keys.enc")
    vault_exists = os.path.isfile(vault_file)
    unlocked = config.vault_session_context is not None
    return {
        "vault_exists": vault_exists,
        "unlocked": unlocked
    }


@app.get("/api/vault/keys")
async def list_vault_keys(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not config.vault_session_context:
        return {"keys": []}
    
    keys = await get_vault_keys_ipc(
        extras_dir=config.BASH4LLM_EXTRAS_DIR,
        config_dir=config.BASH4LLM_CONFIG_DIR,
        tmp_dir=config.BASH4LLM_TMPDIR,
        master_password=config.vault_session_context
    )
    return {"keys": keys}


@app.post("/api/vault/unlock")
async def unlock_vault(
    payload: VaultUnlockRequest,
    request: Request,
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)
    
    vault_file = os.path.join(config.BASH4LLM_CONFIG_DIR, "keys.enc")
    vault_exists = os.path.isfile(vault_file)

    if not vault_exists and len(payload.master_password) < 11:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Master Password must be at least 11 characters long"
        )

    valid = await test_vault_unlock_ipc(
        extras_dir=config.BASH4LLM_EXTRAS_DIR,
        config_dir=config.BASH4LLM_CONFIG_DIR,
        tmp_dir=config.BASH4LLM_TMPDIR,
        master_password=payload.master_password
    )
    if not valid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid master password")
    
    config.vault_session_context = payload.master_password
    return {"status": "unlocked"}


@app.post("/api/vault/keys")
async def save_vault_key(
    payload: VaultKeyRequest,
    request: Request,
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)
    if not config.vault_session_context:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Vault is locked. Unlock vault first.")
    
    success = await save_vault_api_key_ipc(
        extras_dir=config.BASH4LLM_EXTRAS_DIR,
        config_dir=config.BASH4LLM_CONFIG_DIR,
        tmp_dir=config.BASH4LLM_TMPDIR,
        master_password=config.vault_session_context,
        provider=payload.provider,
        api_key=payload.api_key
    )
    if not success:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to save key in vault")
    return {"status": "key_saved", "provider": payload.provider}


@app.post("/api/upload")
async def upload_attachment(
    request: Request,
    file: UploadFile = File(...),
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)
    
    filename = os.path.basename(file.filename or "attachment.tmp")
    safe_filename = "".join(c for c in filename if c.isalnum() or c in "._-")
    if not safe_filename:
        safe_filename = "attachment.tmp"
    
    upload_dir = os.path.join(config.BASH4LLM_TMPDIR, "gui_uploads")
    os.makedirs(upload_dir, mode=0o700, exist_ok=True)
    
    file_path = os.path.join(upload_dir, f"{secrets.token_hex(8)}_{safe_filename}")
    
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)
    os.chmod(file_path, 0o600)

    return {"filename": safe_filename, "file_path": file_path, "size": len(content)}


@app.get("/api/threads")
async def list_threads(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    threads = _read_persisted_threads()
    return {"threads": threads}


@app.post("/api/threads")
async def create_thread(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    try:
        body = await request.json()
        thread_id = str(body.get("thread_id", "")).strip()
    except Exception:
        thread_id = ""

    if not thread_id or not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    _save_thread_to_index(thread_id)
    return {"status": "created", "thread_id": thread_id}


@app.get("/api/threads/{thread_id}")
async def get_thread_history(thread_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    messages = read_thread_history_ndjson(config.BASH4LLM_HISTORY_DIR, thread_id)
    return {"thread_id": thread_id, "messages": messages}


@app.get("/api/threads/{thread_id}/snapshot")
async def get_thread_snapshot(thread_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    snapshot = await get_session_snapshot_ipc(
        extras_dir=config.BASH4LLM_EXTRAS_DIR,
        config_dir=config.BASH4LLM_CONFIG_DIR,
        history_dir=config.BASH4LLM_HISTORY_DIR,
        tmp_dir=config.BASH4LLM_TMPDIR,
        thread_id=thread_id
    )
    return snapshot


@app.delete("/api/threads/{thread_id}")
async def delete_thread(thread_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--delete-thread", thread_id,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        env=get_canonical_env()
    )
    await proc.communicate()
    
    # Complete cleanup of all matching files on disk (threads & sessions)
    sha256_hex = hashlib.sha256(thread_id.encode('utf-8')).hexdigest()
    for sub in ("sessions", "threads"):
        d = os.path.join(config.BASH4LLM_HISTORY_DIR, sub)
        if os.path.isdir(d):
            for fname in (f"{thread_id}.ndjson", f"{sha256_hex}.ndjson"):
                fp = os.path.join(d, fname)
                if os.path.isfile(fp):
                    try:
                        os.remove(fp)
                    except OSError:
                        pass
            try:
                for f in os.listdir(d):
                    if f.startswith(f"{thread_id}.") or f.startswith(f"{sha256_hex}."):
                        try:
                            os.remove(os.path.join(d, f))
                        except OSError:
                            pass
            except Exception:
                pass

    _remove_thread_from_index(thread_id)

    return {"status": "deleted", "thread_id": thread_id}


@app.patch("/api/threads/{thread_id}")
async def rename_thread(thread_id: str, payload: RenameThreadRequest, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--rename-thread", thread_id, "--title", payload.title,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        env=get_canonical_env()
    )
    _, stderr = await proc.communicate()
    if proc.returncode != 0:
        err_msg = stderr.decode('utf-8', errors='replace').strip() or "Failed to rename thread"
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=err_msg)

    return {"status": "renamed", "thread_id": thread_id, "title": payload.title}


@app.post("/api/chat")
async def create_chat_job(
    request: Request,
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key"),
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)

    content_type = request.headers.get("content-type", "").lower()
    if "application/x-www-form-urlencoded" in content_type or "multipart/form-data" in content_type:
        form_data = await request.form()
        raw_attachments = form_data.getlist("attachments") if hasattr(form_data, "getlist") else []
        payload = ChatRequest(
            thread_id=str(form_data.get("thread_id", "default") or "default"),
            prompt=str(form_data.get("prompt", "")),
            stream=str(form_data.get("stream", "true")).lower() in ("true", "1", "yes"),
            thread_window=_safe_int(form_data.get("thread_window"), 10) or 10,
            provider=str(form_data.get("provider")) if form_data.get("provider") else None,
            model=str(form_data.get("model")) if form_data.get("model") else None,
            temperature=_safe_float(form_data.get("temperature")),
            max_tokens=_safe_int(form_data.get("max_tokens")),
            system_prompt=str(form_data.get("system_prompt")) if form_data.get("system_prompt") else None,
            target_bytes=_safe_int(form_data.get("target_bytes")),
            template=str(form_data.get("template")) if form_data.get("template") else None,
            attachments=[str(a) for a in raw_attachments if a],
            validate_sml=str(form_data.get("validate_sml", "false")).lower() in ("true", "1", "yes"),
            sanitize_output=str(form_data.get("sanitize_output", "true")).lower() in ("true", "1", "yes")
        )
    else:
        try:
            body_bytes = await request.body()
            payload_dict = json.loads(body_bytes.decode('utf-8'))
            payload = ChatRequest(**payload_dict)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid JSON payload: {str(e)}"
            )

    if payload.thread_id:
        _save_thread_to_index(payload.thread_id)

    payload_dict = payload.model_dump() if hasattr(payload, "model_dump") else payload.dict()
    payload_json = json.dumps(payload_dict, sort_keys=True)
    fingerprint = hashlib.sha256(payload_json.encode('utf-8')).hexdigest()

    if idempotency_key:
        idem_key = (session_id, idempotency_key)
        if idem_key in idempotency_store:
            existing_job = idempotency_store[idem_key]
            if existing_job.request_fingerprint == fingerprint:
                return JSONResponse(
                    status_code=status.HTTP_202_ACCEPTED,
                    content={"job_id": existing_job.job_id, "state": existing_job.state.value}
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Idempotency key mismatch with different payload fingerprint"
                )

    job = Job(
        owner_session_id=session_id,
        idempotency_key=idempotency_key,
        request_fingerprint=fingerprint,
        thread_id=payload.thread_id,
        prompt=payload.prompt,
        thread_window=payload.thread_window,
        stream=payload.stream,
        provider=payload.provider,
        model=payload.model,
        temperature=payload.temperature,
        max_tokens=payload.max_tokens,
        system_prompt=payload.system_prompt,
        target_bytes=payload.target_bytes,
        template=payload.template,
        attachments=payload.attachments or [],
        validate_sml=payload.validate_sml,
        sanitize_output=payload.sanitize_output
    )

    jobs_registry[job.job_id] = job
    sse_queue: asyncio.Queue = asyncio.Queue()
    job_queues[job.job_id] = sse_queue

    if idempotency_key:
        idempotency_store[(session_id, idempotency_key)] = job

    sanitized_env = get_canonical_env()

    asyncio.create_task(
        execute_job_subprocess(
            job=job,
            core_script_path=config.core_script_path,
            sanitized_env=sanitized_env,
            runtime_dir=config.BASH4LLM_TMPDIR,
            sse_queue=sse_queue
        )
    )

    return JSONResponse(
        status_code=status.HTTP_202_ACCEPTED,
        content={"job_id": job.job_id, "state": job.state.value}
    )


@app.get("/api/jobs/{job_id}")
async def get_job_status(job_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    job = jobs_registry.get(job_id)
    if not job or job.owner_session_id != session_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")

    return {
        "job_id": job.job_id,
        "state": job.state.value,
        "thread_id": job.thread_id,
        "response_text": job.prompt_response if not job.stream else None,
        "core_error_code": job.core_error_code,
        "core_error_reason": job.core_error_reason
    }


@app.post("/api/jobs/{job_id}/cancel")
async def cancel_job(job_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    job = jobs_registry.get(job_id)
    if not job or job.owner_session_id != session_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")

    cancelled = await cancel_job_process(job)
    return {"status": "cancel_requested", "job_id": job_id, "success": cancelled}


@app.get("/api/stream/{job_id}")
async def stream_job_tokens(job_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    job = jobs_registry.get(job_id)
    if not job or job.owner_session_id != session_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")

    sse_queue = job_queues.get(job_id)
    if not sse_queue:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Stream queue unavailable")

    async def event_generator():
        try:
            while True:
                try:
                    event = await asyncio.wait_for(sse_queue.get(), timeout=15.0)
                    yield f"id: {event['id']}\nevent: {event['event']}\ndata: {event['data']}\n\n"
                    if event['event'] == 'done':
                        break
                except asyncio.TimeoutError:
                    if sse_queue.empty() and job.state in (JobState.COMPLETED, JobState.FAILED, JobState.CANCELLED):
                        done_payload = json.dumps({
                            "job_id": job.job_id,
                            "state": job.state.value,
                            "error_code": job.core_error_code,
                            "error_reason": job.core_error_reason
                        })
                        yield f"id: {job.sse_sequence + 1}\nevent: done\ndata: {done_payload}\n\n"
                        break
                    yield ": heartbeat\n\n"
        finally:
            job_queues.pop(job_id, None)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


def _launch_browser_async(url: str, port: int) -> None:
    """
    Opportunistic browser launcher worker.
    Executes a deterministic readiness probe on the loopback socket before dispatching
    a non-blocking platform-specific launcher. Never blocks server execution or logs credentials.
    """
    # 1. Respect explicit configuration opt-out
    no_browser_env = os.environ.get("BASH4LLM_GUI_NO_BROWSER", "").strip().lower()
    if no_browser_env in ("1", "true", "yes"):
        return

    # 2. Opportunistic socket readiness probe with monotonic clock and clamped timeout (max 3.0s)
    deadline = time.monotonic() + 3.0
    is_ready = False
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=min(0.1, remaining)):
                is_ready = True
                break
        except OSError:
            time.sleep(0.05)

    if not is_ready:
        return

    # 3. Explicit deterministic platform dispatcher
    cmd: Optional[List[str]] = None

    is_android = os.environ.get("BASH4LLM_PLAT_ANDROID") == "1" or IS_TERMUX
    is_wsl = os.environ.get("BASH4LLM_PLAT_WSL") == "1"
    if not is_wsl and sys.platform.startswith("linux"):
        try:
            if os.path.exists("/proc/version"):
                with open("/proc/version", "r", encoding="utf-8") as f:
                    if "microsoft" in f.read().lower():
                        is_wsl = True
        except OSError:
            pass

    is_macos = os.environ.get("BASH4LLM_PLAT_MACOS") == "1" or sys.platform == "darwin"
    is_cygwin = os.environ.get("BASH4LLM_PLAT_CYGWIN") == "1" or sys.platform == "cygwin"
    is_bsd = os.environ.get("BASH4LLM_PLAT_BSD") == "1" or "bsd" in sys.platform
    is_linux = os.environ.get("BASH4LLM_PLAT_LINUX") == "1" or sys.platform.startswith("linux")

    if is_android:
        bin_path = shutil.which("termux-open-url")
        if bin_path:
            cmd = [bin_path, url]
    elif is_wsl:
        wslview = shutil.which("wslview")
        if wslview:
            cmd = [wslview, url]
        else:
            powershell = shutil.which("powershell.exe")
            if powershell:
                # Pass URL strictly as positional parameter $args[0] without script interpolation
                cmd = [powershell, "-NoProfile", "-NonInteractive", "-Command", "& { Start-Process $args[0] }", url]
    elif is_macos:
        open_bin = shutil.which("open") or shutil.which("/usr/bin/open")
        if open_bin:
            cmd = [open_bin, url]
    elif is_cygwin:
        cygstart = shutil.which("cygstart")
        if cygstart:
            cmd = [cygstart, url]
    elif is_linux or is_bsd:
        # Heuristic check for headless or SSH sessions lacking a local display server
        is_remote_headless = bool(
            (os.environ.get("SSH_CONNECTION") or os.environ.get("SSH_CLIENT")) and
            not (os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))
        )
        if not is_remote_headless:
            xdg_open = shutil.which("xdg-open")
            if xdg_open:
                cmd = [xdg_open, url]

    if not cmd:
        return

    # 4. Detached process spawn with stream suppression and POSIX session isolation
    try:
        popen_kwargs: Dict[str, Any] = {
            "stdin": subprocess.DEVNULL,
            "stdout": subprocess.DEVNULL,
            "stderr": subprocess.DEVNULL,
            "close_fds": True,
        }
        if os.name == "posix":
            popen_kwargs["start_new_session"] = True

        subprocess.Popen(cmd, **popen_kwargs)
    except OSError:
        # Suppress launcher failure silently without leaking URL or token to output streams
        pass


if __name__ == "__main__":
    runtime_tmp = validate_runtime_tmpdir(config.BASH4LLM_TMPDIR)
    
    lock_path = os.path.join(runtime_tmp, "gui_adapter.lock")
    if not acquire_single_instance_lock(lock_path):
        print("FATAL: Another instance of bash4llm GUI adapter is already running.", file=sys.stderr)
        sys.exit(15)

    port = find_available_loopback_port(start_port=19970)
    auth_url = f"http://127.0.0.1:{port}/auth?one_time_token={active_one_time_token}"
    
    print("=" * 40)
    print(" Bash4LLM WebApp GUI Adapter running at:")
    print(f" http://127.0.0.1:{port}/")
    print(" One-Time Auth URL (Copy to Browser):\n")
    print(f" {auth_url}\n")
    print("=" * 40)
    
    threading.Thread(target=_launch_browser_async, args=(auth_url, port), daemon=True).start()
    uvicorn.run(app, host="127.0.0.1", port=port, log_level="warning")
