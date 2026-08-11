# extras/gui-py/models.py
# Data Models and Dataclasses for bash4llm⁺ GUI Adapter

import time
import secrets
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, Field


class JobState(str, Enum):
    CREATED = "CREATED"
    STARTING = "STARTING"
    RUNNING = "RUNNING"
    STREAMING = "STREAMING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCEL_REQUESTED = "CANCEL_REQUESTED"
    CANCELLED = "CANCELLED"


class TerminationCause(str, Enum):
    NATURAL = "NATURAL"
    CORE_EXIT = "CORE_EXIT"
    SIGTERM = "SIGTERM"
    SIGKILL = "SIGKILL"
    UNKNOWN = "UNKNOWN"


@dataclass
class Job:
    """
    In-memory representation of an asynchronous LLM Execution Job.
    Domain-Stateless in Python, stateful for orchestrating runtime processes.
    """
    job_id: str = field(default_factory=lambda: f"job_{secrets.token_hex(16)}")
    owner_session_id: str = ""
    idempotency_key: Optional[str] = None
    request_fingerprint: Optional[str] = None      # SHA-256 of canonical payload
    thread_id: str = "default"
    prompt: str = ""                              # Passed via stdin pipe to core
    prompt_response: str = ""                     # Buffer accumulated in RAM
    thread_window: int = 10
    stream: bool = True
    provider: Optional[str] = None
    model: Optional[str] = None
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None
    system_prompt: Optional[str] = None
    target_bytes: Optional[int] = None
    template: Optional[str] = None
    attachments: List[str] = field(default_factory=list)
    validate_sml: bool = False
    sanitize_output: bool = True
    state: JobState = JobState.CREATED
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    cancel_requested_at: Optional[float] = None
    process_pid: Optional[int] = None
    process_group_id: Optional[int] = None
    termination_requested: bool = False
    termination_cause: Optional[TerminationCause] = None
    exit_code: Optional[int] = None                # OS Process Return Code
    core_error_code: Optional[int] = None           # Diagnostic code from emit_json_diagnostics (10..17)
    core_error_reason: Optional[str] = None
    metadata_verified: bool = False
    sse_sequence: int = 0


# Pydantic Schemas for API Payload Validation
class ChatRequest(BaseModel):
    thread_id: str = Field(default="default", min_length=1, max_length=128)
    prompt: str = Field(..., min_length=1)
    stream: bool = True
    thread_window: int = Field(default=10, ge=0, le=100) # ge=0 allows N=0 for Byte-Budget Mode
    provider: Optional[str] = None
    model: Optional[str] = None
    temperature: Optional[float] = Field(default=None, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(default=None, ge=1, le=128000)
    system_prompt: Optional[str] = Field(default=None, max_length=10000)
    target_bytes: Optional[int] = Field(default=None, ge=0, le=1048576)
    template: Optional[str] = Field(default=None, max_length=128)
    attachments: List[str] = Field(default_factory=list)
    validate_sml: bool = False
    sanitize_output: bool = True


class RenameThreadRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=256)


class VaultUnlockRequest(BaseModel):
    master_password: str = Field(..., min_length=1)


class VaultKeyRequest(BaseModel):
    provider: str = Field(..., min_length=1, max_length=64)
    api_key: str = Field(..., min_length=1)


class SetDefaultModelRequest(BaseModel):
    provider: str = Field(..., min_length=1, max_length=64)
    model: str = Field(..., min_length=1, max_length=128)
