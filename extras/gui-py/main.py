# extras/gui-py/main.py
# Main Entrypoint Server Adapter for bash4llm⁺ WebApp GUI

import asyncio
import hashlib
import json
import os
import secrets
import signal
import socket
import sys
import time
import webbrowser
from typing import Dict, Optional, Tuple, List, Any

import uvicorn
from fastapi import FastAPI, Request, Response, HTTPException, status, Depends, Header
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles

from config import Config
from models import Job, JobState, TerminationCause, ChatRequest, RenameThreadRequest
from security import (
    validate_runtime_tmpdir,
    acquire_single_instance_lock,
    verify_security_headers
)
from ipc import (
    execute_job_subprocess,
    cancel_job_process,
    read_thread_history_ndjson,
    THREAD_ID_REGEX
)

# Runtime Memory State
config = Config()
active_one_time_token: Optional[str] = secrets.token_hex(32)
active_csrf_token: str = secrets.token_hex(32)
sessions: Dict[str, float] = {}                   # session_id -> last_seen_timestamp
jobs_registry: Dict[str, Job] = {}
job_queues: Dict[str, asyncio.Queue] = {}
idempotency_store: Dict[Tuple[str, str], Job] = {} # (session_id, key) -> Job

server_has_seen_first_client: bool = False
grace_started_at: Optional[float] = None

app = FastAPI(title="bash4llm WebApp Adapter", docs_url=None, redoc_url=None)

# Mount Static Files and Languages Directories
static_dir = os.path.join(config.script_dir, "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

langs_dir = os.path.join(config.script_dir, "langs")
if os.path.exists(langs_dir):
    app.mount("/langs", StaticFiles(directory=langs_dir), name="langs")


def find_available_loopback_port(start_port: int = 19970, max_attempts: int = 100) -> int:
    """Scans loopback interface for the first available TCP port."""
    for port in range(start_port, start_port + max_attempts):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("127.0.0.1", port))
                return port
            except OSError:
                continue
    raise RuntimeError("No free loopback port found in range.")


async def graceful_shutdown_checker():
    """
    Monitors server lifecycle and triggers shutdown when idle for >= 15 seconds.
    Inhibited until at least one client has authenticated.
    """
    global grace_started_at, server_has_seen_first_client
    while True:
        await asyncio.sleep(2.0)
        if not server_has_seen_first_client:
            continue

        now = time.time()
        active_clients = sum(1 for last_seen in sessions.values() if (now - last_seen) <= 10.0)
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
            elif (now - grace_started_at) >= 15.0:
                print("Graceful shutdown conditions met (15s idle). Stopping server...")
                os.kill(os.getpid(), signal.SIGINT)
                break
        else:
            grace_started_at = None


@app.on_event("startup")
async def startup_event():
    asyncio.create_task(graceful_shutdown_checker())


# Session Verification Dependency
def get_current_session(request: Request) -> str:
    session_id = request.cookies.get("session_id")
    if not session_id or session_id not in sessions:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized session")
    sessions[session_id] = time.time()
    global server_has_seen_first_client
    server_has_seen_first_client = True
    return session_id


# Middleware for Root & HTML Route Protection
@app.middleware("http")
async def protect_html_routes_middleware(request: Request, call_next):
    path = request.url.path
    if path in ("/", "/index.html"):
        session_id = request.cookies.get("session_id")
        if not session_id or session_id not in sessions:
            error_html_path = os.path.join(static_dir, "error.html")
            if os.path.exists(error_html_path):
                with open(error_html_path, "r", encoding="utf-8") as f:
                    content = f.read()
                return HTMLResponse(content=content, status_code=status.HTTP_401_UNAUTHORIZED)
            return HTMLResponse(content="<h1>401 Unauthorized</h1><p>Please authenticate via token link.</p>", status_code=status.HTTP_401_UNAUTHORIZED)
    return await call_next(request)


# --- AUTHENTICATION & STATUS ROUTES ---

@app.get("/auth")
async def authenticate(one_time_token: str, request: Request):
    global active_one_time_token
    if not active_one_time_token or not secrets.compare_digest(one_time_token, active_one_time_token):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or spent token")

    # Consume one-time token
    active_one_time_token = None
    
    new_session_id = secrets.token_hex(32)
    sessions[new_session_id] = time.time()
    
    global server_has_seen_first_client
    server_has_seen_first_client = True

    response = RedirectResponse(url="/", status_code=status.HTTP_302_FOUND)
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
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse(content="<h1>bash4llm WebApp</h1>")


@app.get("/api/status")
async def get_status(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    now = time.time()
    active_clients = sum(1 for last_seen in sessions.values() if (now - last_seen) <= 10.0)
    active_jobs = sum(1 for job in jobs_registry.values() if job.state in (JobState.RUNNING, JobState.STREAMING))
    
    return {
        "server": "READY",
        "active_clients": active_clients,
        "active_jobs": active_jobs,
        "csrf_token": active_csrf_token
    }


@app.post("/api/heartbeat")
async def heartbeat(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    sessions[session_id] = time.time()
    return {"status": "ok"}


# --- CORE CLI BRIDGE ROUTES ---

@app.get("/api/models")
async def list_models(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--list-models-raw",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, _ = await proc.communicate()
    models = [line.strip() for line in stdout.decode('utf-8', errors='replace').splitlines() if line.strip()]
    return {"models": models}


@app.post("/api/models/refresh")
async def refresh_models(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--refresh-models",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    await proc.communicate()
    if proc.returncode != 0:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to refresh models")
    return {"status": "refreshed"}


@app.get("/api/providers")
async def list_providers(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--list-providers-raw",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, _ = await proc.communicate()
    providers = [line.strip() for line in stdout.decode('utf-8', errors='replace').splitlines() if line.strip()]
    return {"providers": providers}


# --- THREAD MANAGEMENT ROUTES ---

@app.get("/api/threads")
async def list_threads(request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    index_file = os.path.join(config.BASH4LLM_CONFIG_DIR, "ui_state", "threads", "index.json")
    
    # Invariant 10: Strict Reconstruction if index missing or corrupt
    index_valid = False
    if os.path.isfile(index_file):
        try:
            with open(index_file, "r", encoding="utf-8") as f:
                json.load(f)
                index_valid = True
        except Exception:
            index_valid = False

    if not index_valid:
        history_threads_dir = os.path.join(config.BASH4LLM_HISTORY_DIR, "threads")
        if os.path.exists(history_threads_dir):
            for fname in os.listdir(history_threads_dir):
                if fname.endswith(".ndjson"):
                    tid = fname[:-7]
                    proc = await asyncio.create_subprocess_exec(
                        "bash", config.core_script_path, "--init-thread", "--thread", tid,
                        stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL
                    )
                    await proc.wait()

    threads = []
    if os.path.isfile(index_file):
        try:
            with open(index_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                threads = data.get("threads", [])
        except Exception:
            threads = []
    return {"threads": threads}


@app.get("/api/threads/{thread_id}")
async def get_thread_history(thread_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    messages = read_thread_history_ndjson(config.BASH4LLM_HISTORY_DIR, thread_id)
    return {"thread_id": thread_id, "messages": messages}


@app.delete("/api/threads/{thread_id}")
async def delete_thread(thread_id: str, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--delete-thread", thread_id,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    await proc.communicate()
    return {"status": "deleted", "thread_id": thread_id}


@app.patch("/api/threads/{thread_id}")
async def rename_thread(thread_id: str, payload: RenameThreadRequest, request: Request, session_id: str = Depends(get_current_session)):
    verify_security_headers(request, active_csrf_token, session_id)
    if not THREAD_ID_REGEX.match(thread_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid thread_id format")

    proc = await asyncio.create_subprocess_exec(
        "bash", config.core_script_path, "--rename-thread", thread_id, "--title", payload.title,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    await proc.communicate()
    return {"status": "renamed", "thread_id": thread_id, "title": payload.title}


# --- CHAT & JOB EXECUTION ROUTES ---

@app.post("/api/chat")
async def create_chat_job(
    payload: ChatRequest,
    request: Request,
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key"),
    session_id: str = Depends(get_current_session)
):
    verify_security_headers(request, active_csrf_token, session_id)

    # Invariant 7: Fingerprinted Ephemeral Idempotency Check (Pydantic v1 & v2 compatible)
    payload_dict = payload.dict() if hasattr(payload, "dict") else payload.model_dump()
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

    # Allocate new Job
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
        max_tokens=payload.max_tokens
    )

    jobs_registry[job.job_id] = job
    sse_queue: asyncio.Queue = asyncio.Queue()
    job_queues[job.job_id] = sse_queue

    if idempotency_key:
        idempotency_store[(session_id, idempotency_key)] = job

    # Clean Environment variables before spawning subprocess
    sanitized_env = {
        k: v for k, v in os.environ.items()
        if not any(k.endswith(sec) for sec in ("_KEY", "_TOKEN", "_SECRET"))
    }
    sanitized_env["BASH4LLM_DIR"] = config.BASH4LLM_DIR
    sanitized_env["BASH4LLM_TMPDIR"] = config.BASH4LLM_TMPDIR

    # Launch subprocess asynchronously
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
        while True:
            try:
                event = await asyncio.wait_for(sse_queue.get(), timeout=15.0)
                yield f"id: {event['id']}\nevent: {event['event']}\ndata: {event['data']}\n\n"
                if event['event'] == 'done':
                    break
            except asyncio.TimeoutError:
                # Handle late reconnection or empty queue on completed jobs without hanging
                if sse_queue.empty() and job.state in (JobState.COMPLETED, JobState.FAILED, JobState.CANCELLED):
                    done_payload = json.dumps({
                        "job_id": job.job_id,
                        "state": job.state.value,
                        "error_code": job.core_error_code,
                        "error_reason": job.core_error_reason
                    })
                    yield f"id: {job.sse_sequence + 1}\nevent: done\ndata: {done_payload}\n\n"
                    break
                # SSE Heartbeat Comment to keep connection alive
                yield ": heartbeat\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")


if __name__ == "__main__":
    runtime_tmp = validate_runtime_tmpdir(config.BASH4LLM_TMPDIR)
    
    lock_path = os.path.join(runtime_tmp, "gui_adapter.lock")
    if not acquire_single_instance_lock(lock_path):
        print("FATAL: Another instance of bash4llm GUI adapter is already running.", file=sys.stderr)
        sys.exit(15)

    port = find_available_loopback_port(start_port=19970)
    auth_url = f"http://127.0.0.1:{port}/auth?one_time_token={active_one_time_token}"
    
    print("=" * 60)
    print(f" bash4llm WebApp GUI Adapter running at: http://127.0.0.1:{port}/")
    print(f" One-Time Auth URL: {auth_url}")
    print("=" * 60)

    try:
        webbrowser.open(auth_url)
    except Exception:
        pass

    uvicorn.run(app, host="127.0.0.1", port=port, log_level="warning")
    
