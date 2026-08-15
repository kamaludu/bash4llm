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
import time
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
    safe_thread_id = job.thread_id if THREAD_ID_REGEX.match(job.thread_id) else "default"
    cmd = [
        "bash",
        core_script_path,
        "--thread", safe_thread_id,
        "--thread-window", str(job.thread_window),
        "--json-diagnostics"
    ]

    if job.stream:
        cmd.append("--stream")

    if job.provider:
        cmd.extend(["--provider", job.provider])
    if job.model and job.model.lower() != "default":
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
    sanitized_env["SANITIZE_OUTPUT"] = "1" if job.sanitize_output else "0"

    job.state = JobState.STARTING
    job.started_at = time.time()

    process = None
    stderr_lines: List[str] = []

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

        # Concurrent Stdin Writer with complete exception safety
        async def stdin_writer():
            try:
                if process and process.stdin:
                    prompt_bytes = (job.prompt or "").encode('utf-8')
                    process.stdin.write(prompt_bytes)
                    await process.stdin.drain()
                    process.stdin.close()
                    try:
                        await process.stdin.wait_closed()
                    except Exception:
                        pass
            except (BrokenPipeError, ConnectionResetError, OSError):
                pass

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

        # Resilient JSON diagnostics and raw error parser for stderr
        async def stderr_reader():
            if not process or not process.stderr:
                return
            async for line in process.stderr:
                line_str = line.decode('utf-8', errors='replace').strip()
                if not line_str:
                    continue
                stderr_lines.append(line_str)
                if "{" in line_str and "}" in line_str:
                    try:
                        start_idx = line_str.find("{")
                        end_idx = line_str.rfind("}") + 1
                        diag = json.loads(line_str[start_idx:end_idx])
                        if diag.get("bash4llm_status") == "ERROR":
                            job.core_error_code = diag.get("code")
                            msg = diag.get("message")
                            reason = diag.get("reason")
                            job.core_error_reason = msg if msg else reason
                    except Exception:
                        pass

        # Concurrent Gather to guarantee deadlock-free pipe processing
        await asyncio.gather(stdin_writer(), stdout_reader(), stderr_reader(), process.wait())

        job.exit_code = process.returncode

        # State Machine Resolution & Clear Descriptive Error Mapping
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
            
            # Map canonical Core Error Code 10 (Missing API Key / Locked Vault)
            if job.core_error_code == 10:
                job.core_error_reason = "Vault is locked or API key missing. Please unlock the Vault or save an API key."
            elif not job.core_error_reason and stderr_lines:
                # Extract clean error message from stderr
                error_candidates = [l for l in stderr_lines if "ERROR:" in l or "FATAL:" in l]
                job.core_error_reason = error_candidates[-1] if error_candidates else stderr_lines[-1]

    except Exception as exc:
        job.state = JobState.FAILED
        job.termination_cause = TerminationCause.UNKNOWN
        job.core_error_reason = str(exc)
    finally:
        # Zero Zombie Process Guarantee
        if process and process.returncode is None:
            try:
                process.terminate()
                await process.wait()
            except Exception:
                try:
                    process.kill()
                except Exception:
                    pass

        job.completed_at = time.time()
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
    if not job.process_pid or job.state in (JobState.COMPLETED, JobState.FAILED, JobState.CANCELLED):
        return False

    job.state = JobState.CANCEL_REQUESTED
    job.termination_requested = True
    job.cancel_requested_at = time.time()

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
            os.kill(job.process_pid, signal.SIGTERM)
            job.termination_cause = TerminationCause.SIGTERM
            
            for _ in range(50):
                await asyncio.sleep(0.1)
                if job.state == JobState.CANCELLED:
                    return True
            
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
    if not THREAD_ID_REGEX.match(thread_id):
        return []

    # Strict SHA-256 Thread ID Anonymization matching bash4llm core (Closed-World Data)
    sha256_hex = hashlib.sha256(thread_id.encode('utf-8')).hexdigest()
    target_file = os.path.join(history_dir, "threads", f"{sha256_hex}.ndjson")

    if not (os.path.isfile(target_file) and os.access(target_file, os.R_OK)):
        return []

    messages: List[Dict[str, Any]] = []
    try:
        with open(target_file, 'r', encoding='utf-8', errors='replace') as f:
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
    config_dir: str,
    history_dir: str,
    tmp_dir: str,
    thread_id: str
) -> Dict[str, Any]:
    if not THREAD_ID_REGEX.match(thread_id):
        return {"error": "Invalid thread_id format"}

    session_engine_script = os.path.join(extras_dir, "session", "session-engine.sh")
    
    # Contract Guarantee: Ensure both threads and sessions directories exist (0700)
    os.makedirs(os.path.join(history_dir, "threads"), mode=0o700, exist_ok=True)
    os.makedirs(os.path.join(history_dir, "sessions"), mode=0o700, exist_ok=True)

    sha256_hex = hashlib.sha256(thread_id.encode('utf-8')).hexdigest()
    thread_file = os.path.join(history_dir, "threads", f"{sha256_hex}.ndjson")

    # If session engine script is present, try generating the formal snapshot
    if os.path.isfile(session_engine_script):
        out_file = os.path.join(tmp_dir, f"snapshot_{secrets.token_hex(8)}.json")

        env = {**os.environ}
        env["BASH4LLM_DIR"] = os.path.dirname(config_dir)
        env["BASH4LLM_CONFIG_DIR"] = config_dir
        env["BASH4LLM_HISTORY_DIR"] = history_dir
        env["BASH4LLM_EXTRAS_DIR"] = extras_dir
        env["RUN_TMPDIR"] = tmp_dir
        env["BASH4LLM_TMPDIR"] = tmp_dir
        env["B4L_IPC_THREAD_ID"] = sha256_hex
        env["B4L_IPC_OUT_FILE"] = out_file
        env["B4L_IPC_ENGINE_SCRIPT"] = session_engine_script

        bash_code = """
        source "$B4L_IPC_ENGINE_SCRIPT"
        session_engine_snapshot "$B4L_IPC_THREAD_ID" "$B4L_IPC_OUT_FILE"
        """

        try:
            proc = await asyncio.create_subprocess_exec(
                "bash", "-c", bash_code,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env
            )
            await proc.communicate()

            if os.path.isfile(out_file) and os.path.getsize(out_file) > 0:
                try:
                    with open(out_file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    return data
                finally:
                    try:
                        os.remove(out_file)
                    except OSError:
                        pass
        except Exception:
            pass

    # Defensive Zero-State Fallback: Compute valid snapshot data directly from history
    messages = read_thread_history_ndjson(history_dir, thread_id)
    file_size_bytes = os.path.getsize(thread_file) if os.path.isfile(thread_file) else 0
    segment_count = 1 if os.path.isfile(thread_file) else 0

    return {
        "session_id": thread_id,
        "stats": {
            "message_count": len(messages),
            "segments": segment_count,
            "total_size_bytes": file_size_bytes
        },
        "last_messages": messages[-50:] if messages else [],
        "summaries": []
    }


async def test_vault_unlock_ipc(
    extras_dir: str,
    config_dir: str,
    tmp_dir: str,
    master_password: str
) -> bool:
    """
    Tests master password validity or bootstraps canonical vault triad (keys.enc, keys.rec, keys.dat)
    if not existing on disk (Zero-State Clean Install).
    """
    openssl_helper_script = os.path.join(extras_dir, "security", "openssl-helper.sh")
    if not os.path.isfile(openssl_helper_script):
        return False

    env = {**os.environ}
    env["BASH4LLM_CONFIG_DIR"] = config_dir
    env["RUN_TMPDIR"] = tmp_dir
    env["BASH4LLM_TMPDIR"] = tmp_dir
    env["_B4L_RT_CTX"] = master_password
    env["B4L_IPC_HELPER_SCRIPT"] = openssl_helper_script

    bash_code = """
    source "$B4L_IPC_HELPER_SCRIPT"
    vault_file="${BASH4LLM_CONFIG_DIR}/keys.enc"
    rec_file="${BASH4LLM_CONFIG_DIR}/keys.rec"
    dat_file="${BASH4LLM_CONFIG_DIR}/keys.dat"

    # Non-interactive Vault Bootstrap on Clean Install
    if [ ! -f "$vault_file" ]; then
        safe_mkdir "$BASH4LLM_CONFIG_DIR" 700
        vault_key="$(openssl rand -hex 32 2>/dev/null || printf 'vk-%s-%s-%s' "$(date +%s)" "$RANDOM" "$RANDOM")"
        recovery_key="$(openssl rand -hex 16 2>/dev/null || printf 'rec-%s-%s' "$(date +%s)" "$RANDOM")"

        _vault_encrypt_to_file "$vault_key" "$vault_file" "$_B4L_RT_CTX" || exit 1
        _vault_encrypt_to_file "$vault_key" "$rec_file" "$recovery_key" || exit 1
        _vault_encrypt_to_file "{}" "$dat_file" "$vault_key" || exit 1
        exit 0
    fi

    vault_key="$(_vault_decrypt_file "$vault_file" "$_B4L_RT_CTX" 2>/dev/null || true)"
    if [ -n "$vault_key" ]; then
        if [ -f "$dat_file" ]; then
            payload="$(_vault_decrypt_file "$dat_file" "$vault_key" 2>/dev/null || true)"
            if [ -n "$payload" ] && printf '%s' "$payload" | jq -e . >/dev/null 2>&1; then
                exit 0
            else
                exit 1
            fi
        fi
        exit 0
    else
        exit 1
    fi
    """

    try:
        proc = await asyncio.create_subprocess_exec(
            "bash", "-c", bash_code,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env
        )
        await proc.wait()
        return proc.returncode == 0
    except Exception:
        return False


async def get_vault_keys_ipc(
    extras_dir: str,
    config_dir: str,
    tmp_dir: str,
    master_password: str
) -> List[str]:
    """
    Extracts configured provider names from keys.dat using decrypted payload.
    """
    openssl_helper_script = os.path.join(extras_dir, "security", "openssl-helper.sh")
    if not os.path.isfile(openssl_helper_script):
        return []

    env = {**os.environ}
    env["BASH4LLM_CONFIG_DIR"] = config_dir
    env["RUN_TMPDIR"] = tmp_dir
    env["BASH4LLM_TMPDIR"] = tmp_dir
    env["_B4L_RT_CTX"] = master_password
    env["B4L_IPC_HELPER_SCRIPT"] = openssl_helper_script

    bash_code = """
    source "$B4L_IPC_HELPER_SCRIPT"
    vault_file="${BASH4LLM_CONFIG_DIR}/keys.enc"
    dat_file="${BASH4LLM_CONFIG_DIR}/keys.dat"
    [ -f "$vault_file" ] && [ -f "$dat_file" ] || exit 0
    
    vault_key="$(_vault_decrypt_file "$vault_file" "$_B4L_RT_CTX" 2>/dev/null)"
    [ -n "$vault_key" ] || exit 1
    
    payload="$(_vault_decrypt_file "$dat_file" "$vault_key" 2>/dev/null)"
    [ -n "$payload" ] || exit 0
    
    printf '%s' "$payload" | jq -r 'keys[]' 2>/dev/null || true
    """

    try:
        proc = await asyncio.create_subprocess_exec(
            "bash", "-c", bash_code,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env
        )
        stdout, _ = await proc.communicate()
        if proc.returncode == 0:
            return [k.strip() for k in stdout.decode('utf-8', errors='replace').splitlines() if k.strip()]
        return []
    except Exception:
        return []


async def save_vault_api_key_ipc(
    extras_dir: str,
    config_dir: str,
    tmp_dir: str,
    master_password: str,
    provider: str,
    api_key: str
) -> bool:
    """
    Saves an API key into keys.dat securely via isolated env variables,
    normalizing provider name and handling non-interactive vault creation.
    """
    openssl_helper_script = os.path.join(extras_dir, "security", "openssl-helper.sh")
    if not os.path.isfile(openssl_helper_script):
        return False

    env = {**os.environ}
    env["BASH4LLM_CONFIG_DIR"] = config_dir
    env["RUN_TMPDIR"] = tmp_dir
    env["BASH4LLM_TMPDIR"] = tmp_dir
    env["_B4L_RT_CTX"] = master_password
    env["B4L_IPC_PROVIDER"] = provider
    env["B4L_IPC_API_KEY"] = api_key
    env["B4L_IPC_HELPER_SCRIPT"] = openssl_helper_script

    bash_code = """
    source "$B4L_IPC_HELPER_SCRIPT"
    vault_file="${BASH4LLM_CONFIG_DIR}/keys.enc"
    rec_file="${BASH4LLM_CONFIG_DIR}/keys.rec"
    dat_file="${BASH4LLM_CONFIG_DIR}/keys.dat"
    
    # Non-interactive Vault Initialization if not present
    if [ ! -f "$vault_file" ]; then
        safe_mkdir "$BASH4LLM_CONFIG_DIR" 700
        vault_key="$(openssl rand -hex 32 2>/dev/null || printf 'vk-%s-%s-%s' "$(date +%s)" "$RANDOM" "$RANDOM")"
        recovery_key="$(openssl rand -hex 16 2>/dev/null || printf 'rec-%s-%s' "$(date +%s)" "$RANDOM")"

        _vault_encrypt_to_file "$vault_key" "$vault_file" "$_B4L_RT_CTX" || exit 1
        _vault_encrypt_to_file "$vault_key" "$rec_file" "$recovery_key" || exit 1
        _vault_encrypt_to_file "{}" "$dat_file" "$vault_key" || exit 1
    fi

    vault_key="$(_vault_decrypt_file "$vault_file" "$_B4L_RT_CTX" 2>/dev/null)"
    [ -n "$vault_key" ] || exit 1
    
    current_payload=""
    if [ -f "$dat_file" ]; then
        current_payload="$(_vault_decrypt_file "$dat_file" "$vault_key" 2>/dev/null)"
    fi
    [ -n "$current_payload" ] || current_payload="{}"
    
    # Lowercase provider normalization
    prov="$(printf '%s' "$B4L_IPC_PROVIDER" | tr '[:upper:]' '[:lower:]')"
    
    updated_payload="$(printf '%s' "$current_payload" | jq --arg p "$prov" --arg k "$B4L_IPC_API_KEY" '.[$p] = $k' 2>/dev/null)"
    [ -n "$updated_payload" ] || exit 1
    
    _vault_encrypt_to_file "$updated_payload" "$dat_file" "$vault_key"
    """

    try:
        proc = await asyncio.create_subprocess_exec(
            "bash", "-c", bash_code,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env
        )
        await proc.wait()
        return proc.returncode == 0
    except Exception:
        return False
