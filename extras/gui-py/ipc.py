#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# Bash4LLM⁺ — Bash-first wrapper for the LLM
# File: extras/gui-py/ipc.py
# Component: Async Subprocess Execution, Deadlock Prevention & SSE Reader for bash4llm⁺
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/bash4llm
# Contact: opensource@cevangel.anonaddy.me
# ======================================

import asyncio
import codecs
import hashlib
import json
import os
import re
import secrets
import signal
import sys
import tempfile
from typing import Dict, Any, List, Optional
from models import Job, JobState, TerminationCause

THREAD_ID_REGEX = re.compile(r"^[A-Za-z0-9._-]{1,128}$")


async def execute_job_subprocess(
    job: Job,
    core_script_path: str,
    sanitized_env: Dict[str, str],
    runtime_dir: str,
    sse_queue: asyncio.Queue
) -> None:
    """
    Asynchronously invokes the bash4llm core script via pipe.
    Writes stdin concurrently with stdout/stderr reads to prevent OS Pipe Deadlocks.
    """
    cmd = [
        "bash",
        core_script_path,
        "--thread", job.thread_id,
        "--thread-window", str(job.thread_window),
        "--json-diagnostics"
    ]

    if job.stream:
        cmd.append("--stream")

    if job.provider:
        cmd.extend(["--provider", job.provider])
    if job.model:
        cmd.extend(["--model", job.model])
    if job.system_prompt:
        cmd.extend(["--system", job.system_prompt])
    if job.temperature is not None:
        cmd.extend(["--temperature", str(job.temperature)])
    if job.max_tokens is not None:
        cmd.extend(["--max", str(job.max_tokens)])
    if job.template:
        cmd.extend(["--template", job.template])
    if job.validate_sml:
        cmd.append("--validate-sml")
    if job.sanitize_output:
        cmd.append("--sanitize")

    if job.attachments:
        for att_path in job.attachments:
            if os.path.isfile(att_path) and os.access(att_path, os.R_OK):
                cmd.extend(["-f", att_path])

    # Dynamic Environment Injection for Extras
    sanitized_env["BASH4LLM_SESSION_ENGINE"] = "on"
    if job.target_bytes is not None:
        sanitized_env["BASH4LLM_SESSION_TARGET_BYTES"] = str(job.target_bytes)
    if job.sanitize_output:
        sanitized_env["SANITIZE_OUTPUT"] = "1"

    job.state = JobState.STARTING
    job.started_at = asyncio.get_event_loop().time()

    process = None
    try:
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=sanitized_env,
            cwd=runtime_dir
        )
        job.process_pid = process.pid
        job.state = JobState.RUNNING

        # Concurrent Stdin Writer (Prevents deadlock if prompt is large or process exits early)
        async def stdin_writer():
            try:
                if process and process.stdin:
                    process.stdin.write(job.prompt.encode('utf-8'))
                    await process.stdin.drain()
                    process.stdin.close()
            except (BrokenPipeError, ConnectionResetError):
                pass  # Subprocess terminated early before reading all stdin

        # Incremental UTF-8 Decoder for stdout token streaming
        async def stdout_reader():
            if not process or not process.stdout:
                return
            decoder = codecs.getincrementaldecoder('utf-8')(errors='replace')
            chunk_size = 1024
            while chunk := await process.stdout.read(chunk_size):
                segment = decoder.decode(chunk, final=False)
                if segment:
                    job.prompt_response += segment
                    job.sse_sequence += 1
                    await sse_queue.put({
                        "id": job.sse_sequence,
                        "event": "token",
                        "data": json.dumps({"delta": segment})
                    })
            tail = decoder.decode(b'', final=True)
            if tail:
                job.prompt_response += tail
                job.sse_sequence += 1
                await sse_queue.put({
                    "id": job.sse_sequence,
                    "event": "token",
                    "data": json.dumps({"delta": tail})
                })

        # Strict JSON diagnostics parser for stderr (Zero Regex on free text)
        async def stderr_reader():
            if not process or not process.stderr:
                return
            async for line in process.stderr:
                line_str = line.decode('utf-8', errors='replace').strip()
                if line_str.startswith('{') and line_str.endswith('}'):
                    try:
                        diag = json.loads(line_str)
                        if diag.get("bash4llm_status") == "ERROR":
                            job.core_error_code = diag.get("code")
                            job.core_error_reason = diag.get("reason")
                    except Exception:
                        pass

        # Concurrent Gather to guarantee deadlock-free pipe processing
        await asyncio.gather(stdin_writer(), stdout_reader(), stderr_reader(), process.wait())

        job.exit_code = process.returncode

        # State Machine Resolution
        if job.termination_requested or job.state == JobState.CANCEL_REQUESTED:
            job.state = JobState.CANCELLED
            if job.termination_cause is None:
                job.termination_cause = TerminationCause.SIGTERM
        elif process.returncode == 0:
            job.state = JobState.COMPLETED
            job.termination_cause = TerminationCause.NATURAL
        else:
            job.state = JobState.FAILED
            job.termination_cause = TerminationCause.CORE_EXIT

    except Exception as exc:
        job.state = JobState.FAILED
        job.termination_cause = TerminationCause.UNKNOWN
        job.core_error_reason = str(exc)
    finally:
        job.completed_at = asyncio.get_event_loop().time()
        # Broadcast final status event via SSE
        await sse_queue.put({
            "id": job.sse_sequence + 1,
            "event": "done",
            "data": json.dumps({
                "job_id": job.job_id,
                "state": job.state.value,
                "error_code": job.core_error_code,
                "error_reason": job.core_error_reason
            })
        })


async def cancel_job_process(job: Job) -> bool:
    """
    Terminates the process tree associated with a Job.
    Uses SIGTERM -> 5s timeout -> SIGKILL on POSIX, taskkill on Windows.
    """
    if not job.process_pid or job.state in (JobState.COMPLETED, JobState.FAILED, JobState.CANCELLED):
        return False

    job.state = JobState.CANCEL_REQUESTED
    job.termination_requested = True
    job.cancel_requested_at = asyncio.get_event_loop().time()

    try:
        if sys.platform == "win32":
            proc = await asyncio.create_subprocess_exec(
                "taskkill", "/F", "/T", "/PID", str(job.process_pid),
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL
            )
            await proc.wait()
            job.termination_cause = TerminationCause.SIGKILL
        else:
            # POSIX Process Termination Tree
            os.kill(job.process_pid, signal.SIGTERM)
            job.termination_cause = TerminationCause.SIGTERM
            
            # Wait up to 5.0 seconds before escalating to SIGKILL
            for _ in range(50):
                await asyncio.sleep(0.1)
                if job.state == JobState.CANCELLED:
                    return True
            
            # Force escalation if process is still alive
            try:
                os.kill(job.process_pid, signal.SIGKILL)
                job.termination_cause = TerminationCause.SIGKILL
            except ProcessLookupError:
                pass
        return True
    except ProcessLookupError:
        job.state = JobState.CANCELLED
        return True
    except Exception as exc:
        job.core_error_reason = f"Cancellation failed: {exc}"
        return False


def read_thread_history_ndjson(history_dir: str, thread_id: str) -> List[Dict[str, Any]]:
    """
    Performs 2-Level Read-Only Resolution for Thread History without subshell spawns.
    Level 1: SHA-256 hash lookup (bash4llm.d/history/threads/{sha256}.ndjson)
    Level 2: Plain ID fallback lookup (bash4llm.d/history/threads/{thread_id}.ndjson)
    """
    if not THREAD_ID_REGEX.match(thread_id):
        return []

    sha256_hex = hashlib.sha256(thread_id.encode('utf-8')).hexdigest()
    
    target_file = os.path.join(history_dir, "threads", f"{sha256_hex}.ndjson")
    fallback_file = os.path.join(history_dir, "threads", f"{thread_id}.ndjson")

    chosen_file = None
    if os.path.isfile(target_file) and os.access(target_file, os.R_OK):
        chosen_file = target_file
    elif os.path.isfile(fallback_file) and os.access(fallback_file, os.R_OK):
        chosen_file = fallback_file

    if not chosen_file:
        return []

    messages: List[Dict[str, Any]] = []
    try:
        with open(chosen_file, 'r', encoding='utf-8', errors='replace') as f:
            for line in f:
                line_str = line.strip()
                if not line_str:
                    continue
                try:
                    msg_obj = json.loads(line_str)
                    messages.append(msg_obj)
                except Exception:
                    continue
    except Exception:
        return []

    return messages


async def get_session_snapshot_ipc(
    extras_dir: str,
    history_dir: str,
    tmp_dir: str,
    thread_id: str
) -> Dict[str, Any]:
    """
    Invokes session_engine_snapshot in an isolated subshell to export
    session statistics (message count, byte size, segments) for the thread.
    """
    if not THREAD_ID_REGEX.match(thread_id):
        return {"error": "Invalid thread_id format"}

    session_engine_script = os.path.join(extras_dir, "session", "session-engine.sh")
    if not os.path.isfile(session_engine_script):
        return {"error": "session-engine.sh not found"}

    out_file = os.path.join(tmp_dir, f"snapshot_{secrets.token_hex(8)}.json")
    
    bash_code = f"""
    export BASH4LLM_HISTORY_DIR={json.dumps(history_dir)}
    export RUN_TMPDIR={json.dumps(tmp_dir)}
    export BASH4LLM_TMPDIR={json.dumps(tmp_dir)}
    source {json.dumps(session_engine_script)}
    session_engine_snapshot {json.dumps(thread_id)} {json.dumps(out_file)}
    """

    try:
        proc = await asyncio.create_subprocess_exec(
            "bash", "-c", bash_code,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await proc.communicate()

        if os.path.isfile(out_file):
            try:
                with open(out_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                return data
            finally:
                try:
                    os.remove(out_file)
                except OSError:
                    pass
        return {"error": "Snapshot generation failed"}
    except Exception as exc:
        return {"error": str(exc)}


async def test_vault_unlock_ipc(
    extras_dir: str,
    config_dir: str,
    tmp_dir: str,
    master_password: str
) -> bool:
    """
    Tests master password validity against the encrypted OpenSSL Vault in an isolated subshell.
    Returns True if decryption succeeds, False otherwise.
    """
    openssl_helper_script = os.path.join(extras_dir, "security", "openssl-helper.sh")
    if not os.path.isfile(openssl_helper_script):
        return False

    bash_code = f"""
    export BASH4LLM_CONFIG_DIR={json.dumps(config_dir)}
    export RUN_TMPDIR={json.dumps(tmp_dir)}
    export BASH4LLM_TMPDIR={json.dumps(tmp_dir)}
    export _B4L_RT_CTX={json.dumps(master_password)}
    source {json.dumps(openssl_helper_script)}
    res="$(vault_load_keys 2>/dev/null)"
    if [ -n "$res" ] && printf '%s' "$res" | jq -e . >/dev/null 2>&1; then
        exit 0
    else
        exit 1
    fi
    """

    try:
        proc = await asyncio.create_subprocess_exec(
            "bash", "-c", bash_code,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await proc.wait()
        return proc.returncode == 0
    except Exception:
        return False


async def save_vault_api_key_ipc(
    extras_dir: str,
    config_dir: str,
    tmp_dir: str,
    master_password: str,
    provider: str,
    api_key: str
) -> bool:
    """
    Saves an API key encrypted into the OpenSSL Vault for a specified provider.
    Runs strictly inside an isolated subshell.
    """
    openssl_helper_script = os.path.join(extras_dir, "security", "openssl-helper.sh")
    if not os.path.isfile(openssl_helper_script):
        return False

    bash_code = f"""
    export BASH4LLM_CONFIG_DIR={json.dumps(config_dir)}
    export RUN_TMPDIR={json.dumps(tmp_dir)}
    export BASH4LLM_TMPDIR={json.dumps(tmp_dir)}
    export _B4L_RT_CTX={json.dumps(master_password)}
    source {json.dumps(openssl_helper_script)}
    
    vault_key="$(_vault_decrypt_file "$_VAULT_FILE" "$_B4L_RT_CTX" 2>/dev/null)"
    [ -n "$vault_key" ] || exit 1
    
    current_payload="$(_vault_decrypt_file "$_VAULT_DAT_FILE" "$vault_key" 2>/dev/null)"
    [ -n "$current_payload" ] || current_payload="{{}}"
    
    updated_payload="$(printf '%s' "$current_payload" | jq --arg p {json.dumps(provider)} --arg k {json.dumps(api_key)} '.[$p] = $k' 2>/dev/null)"
    [ -n "$updated_payload" ] || exit 1
    
    _vault_encrypt_to_file "$updated_payload" "$_VAULT_DAT_FILE" "$vault_key"
    """

    try:
        proc = await asyncio.create_subprocess_exec(
            "bash", "-c", bash_code,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await proc.wait()
        return proc.returncode == 0
    except Exception:
        return False
