#!/usr/bin/env python3
"""Upload MID to remote VPS and docker compose up. Password via MID_SSH_PASSWORD env."""

from __future__ import annotations

import os
import stat
import sys
import time
from pathlib import Path

import paramiko

HOST = os.environ.get("MID_SSH_HOST", "173.249.47.202")
USER = os.environ.get("MID_SSH_USER", "root")
PASSWORD = os.environ.get("MID_SSH_PASSWORD", "")
REMOTE_DIR = "/opt/mid"

ROOT = Path(__file__).resolve().parents[1]  # MID/

SKIP_DIR_NAMES = {
    ".venv",
    "__pycache__",
    ".dart_tool",
    "build",
    ".idea",
    ".vscode",
    ".git",
}
SKIP_SUFFIXES = {".pyc", ".db"}


def should_skip(path: Path) -> bool:
    parts = set(path.parts)
    if parts & SKIP_DIR_NAMES:
        return True
    if path.suffix in SKIP_SUFFIXES:
        return True
    if path.name == ".env":
        return True
    return False


def connect() -> paramiko.SSHClient:
    if not PASSWORD:
        raise SystemExit("MID_SSH_PASSWORD env kerak")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Connecting {USER}@{HOST} ...")
    client.connect(
        HOST,
        username=USER,
        password=PASSWORD,
        timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )
    return client


def _safe_print(text: str) -> None:
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("ascii", errors="replace").decode("ascii"))


def run(client: paramiko.SSHClient, cmd: str, check: bool = True) -> str:
    print(f"$ {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, get_pty=True)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    code = stdout.channel.recv_exit_status()
    if out.strip():
        _safe_print(out[-8000:] if len(out) > 8000 else out)
    if err.strip():
        _safe_print(err[-4000:] if len(err) > 4000 else err)
    if check and code != 0:
        raise RuntimeError(f"Command failed ({code}): {cmd}")
    return out


def upload_tree(sftp: paramiko.SFTPClient, local: Path, remote: str) -> None:
    try:
        sftp.stat(remote)
    except FileNotFoundError:
        sftp.mkdir(remote)

    for item in local.iterdir():
        if should_skip(item):
            continue
        rpath = f"{remote}/{item.name}".replace("\\", "/")
        if item.is_dir():
            upload_tree(sftp, item, rpath)
        else:
            print(f"  put {item.relative_to(ROOT)}")
            sftp.put(str(item), rpath)


def main() -> None:
    client = connect()
    try:
        # OS prep
        sftp = client.open_sftp()
        setup_local = ROOT / "deploy" / "remote_setup.sh"
        sftp.put(str(setup_local), "/tmp/mid_remote_setup.sh")
        run(client, "chmod +x /tmp/mid_remote_setup.sh && bash /tmp/mid_remote_setup.sh")

        print(f"Uploading {ROOT} -> {REMOTE_DIR}")
        run(client, f"mkdir -p {REMOTE_DIR} && rm -rf {REMOTE_DIR}/lib {REMOTE_DIR}/backend {REMOTE_DIR}/web {REMOTE_DIR}/deploy {REMOTE_DIR}/assets || true")
        upload_tree(sftp, ROOT, REMOTE_DIR)
        sftp.close()

        # Ensure scripts executable and secret
        secret = os.environ.get(
            "MID_SECRET_KEY",
            "mid-prod-" + str(int(time.time())) + "-change-after",
        )
        http_port = os.environ.get("MID_HTTP_PORT", "8100")
        run(
            client,
            f"cd {REMOTE_DIR} && chmod +x deploy/*.sh && "
            f"printf 'SECRET_KEY=%s\\nMID_HTTP_PORT=%s\\n' '{secret}' '{http_port}' > .env",
        )

        # Swap helps Flutter web image build on busy hosts
        run(
            client,
            "if [ ! -f /swapfile_mid ]; then "
            "fallocate -l 4G /swapfile_mid && chmod 600 /swapfile_mid && "
            "mkswap /swapfile_mid && swapon /swapfile_mid; "
            "else swapon /swapfile_mid || true; fi",
            check=False,
        )

        print("Building containers (Flutter web build may take several minutes)...")
        run(
            client,
            f"cd {REMOTE_DIR} && docker compose down || true && "
            f"docker compose --env-file .env up -d --build --remove-orphans",
            check=True,
        )
        run(client, f"cd {REMOTE_DIR} && docker compose ps")
        run(
            client,
            f"curl -fsS http://127.0.0.1:{http_port}/health || "
            f"curl -fsS http://127.0.0.1:{http_port}/ || true",
            check=False,
        )
        print(f"\nDeployed: http://{HOST}:{http_port}/")
        print(f"API docs: http://{HOST}:{http_port}/docs")
    finally:
        client.close()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
