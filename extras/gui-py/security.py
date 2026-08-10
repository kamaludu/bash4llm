# extras/gui-py/security.py
# Security & Process Isolation Subsystem for bash4llm⁺ GUI

import os
import sys
import secrets
from typing import Optional, Set
from fastapi import Request, HTTPException, status

# Conditional import for POSIX systems (prevents crash on Windows)
if sys.platform != "win32":
    import fcntl

_lock_file_fd: Optional[int] = None


def validate_runtime_tmpdir(tmpdir: str) -> str:
    """
    Validates that the isolated temporary directory complies with T3 Hardened security.
    Rejects system global /tmp (including subdirectories, case variants on Windows, and macOS symlinks)
    and enforces 0700 permissions.
    """
    real_tmp = os.path.realpath(tmpdir)
    real_tmp_lower = real_tmp.lower()
    
    # Strict prefix matching (case-insensitive for Windows compatibility)
    forbidden_prefixes = ("/tmp", "/var/tmp", "/private/tmp", "/private/var/tmp", "c:\\windows\\temp")
    if any(real_tmp_lower == p or real_tmp_lower.startswith(p + os.sep) for p in forbidden_prefixes):
        raise RuntimeError(f"SECURITY VIOLATION: Refusing to use system shared temp directory: {real_tmp}")

    if not os.path.exists(real_tmp):
        os.makedirs(real_tmp, mode=0o700, exist_ok=True)

    if sys.platform != "win32":
        st = os.stat(real_tmp)
        if st.st_uid != os.geteuid():
            raise RuntimeError(f"SECURITY VIOLATION: Temp directory owner mismatch: {real_tmp}")
        if (st.st_mode & 0o077) != 0:
            os.chmod(real_tmp, 0o700)
    else:
        if not os.access(real_tmp, os.W_OK):
            raise RuntimeError(f"SECURITY VIOLATION: Temp directory not writable: {real_tmp}")

    return real_tmp


def acquire_single_instance_lock(lock_file_path: str) -> bool:
    """
    Acquires an exclusive single-instance advisory lock at OS kernel level.
    Ensures 1-byte initialization on Windows before locking to prevent msvcrt OSError.
    """
    global _lock_file_fd
    try:
        _lock_file_fd = os.open(lock_file_path, os.O_CREAT | os.O_RDWR, 0o600)
        if sys.platform == "win32":
            import msvcrt
            os.write(_lock_file_fd, b"L")
            os.lseek(_lock_file_fd, 0, os.SEEK_SET)
            msvcrt.locking(_lock_file_fd, msvcrt.LK_NBLCK, 1)
        else:
            fcntl.flock(_lock_file_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return True
    except (IOError, OSError):
        return False


def verify_security_headers(request: Request, active_csrf_token: str, session_id: Optional[str]) -> None:
    """
    Enforces Host, Primary Origin, and CSRF header validation for mutating requests.
    Uses request.url.hostname for robust IPv6 and IPv4 loopback matching.
    """
    # 1. Host Header Validation via robust URL parser
    host_name = (request.url.hostname or "").lower()
    allowed_hostnames: Set[str] = {"127.0.0.1", "localhost", "::1"}
    
    if host_name not in allowed_hostnames:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Host header mismatch: strictly loopback interfaces allowed"
        )

    # 2. Origin Header Check for state-changing HTTP methods
    if request.method in ("POST", "PUT", "PATCH", "DELETE"):
        origin = request.headers.get("origin")
        if origin:
            port = request.url.port
            port_str = f":{port}" if port else ""
            valid_origins = {
                f"http://127.0.0.1{port_str}",
                f"http://localhost{port_str}",
                f"http://[::1]{port_str}"
            }
            if origin not in valid_origins:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Origin header mismatch"
                )

        # 3. Anti-CSRF Token Validation
        csrf_header = request.headers.get("X-CSRF-Token")
        if not csrf_header or not secrets.compare_digest(csrf_header, active_csrf_token):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Invalid or missing CSRF Token"
            )
            
