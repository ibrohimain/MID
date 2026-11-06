import os
import sys

import paramiko

HOST = os.environ.get("MID_SSH_HOST", "173.249.47.202")
PASSWORD = os.environ.get("MID_SSH_PASSWORD", "")
REPO = "https://github.com/ibrohimain/MID.git"


def run(client, cmd, check=True):
    print(f"\n$ {cmd}")
    _, stdout, stderr = client.exec_command(cmd, get_pty=True)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    code = stdout.channel.recv_exit_status()
    text = (out + err).strip()
    if text:
        try:
            print(text[-6000:] if len(text) > 6000 else text)
        except UnicodeEncodeError:
            print(text.encode("ascii", "replace").decode())
    if check and code != 0:
        raise RuntimeError(f"failed ({code}): {cmd}")
    return out, code


def main():
    if not PASSWORD:
        sys.exit("MID_SSH_PASSWORD kerak")
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(
        HOST,
        username="root",
        password=PASSWORD,
        timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )
    try:
        # Detect layout: /opt/mid may be app root or repo root with MID/
        run(c, "ls -la /opt/mid | head -30", check=False)
        run(c, "test -d /opt/mid/.git && echo HAS_GIT || echo NO_GIT", check=False)
        run(c, "test -f /opt/mid/docker-compose.yml && echo COMPOSE_ROOT || true", check=False)
        run(c, "test -f /opt/mid/MID/docker-compose.yml && echo COMPOSE_MID || true", check=False)

        # Ensure git checkout of latest main
        # Keep .env and volume data; replace code via git
        run(
            c,
            "mkdir -p /opt && "
            "if [ -d /opt/mid-repo/.git ]; then "
            "  cd /opt/mid-repo && git fetch origin && git reset --hard origin/main && git pull --ff-only origin main; "
            "else "
            "  rm -rf /opt/mid-repo && git clone --branch main " + REPO + " /opt/mid-repo; "
            "fi",
        )

        # Sync app files into /opt/mid (compose lives in MID/)
        run(
            c,
            "mkdir -p /opt/mid && "
            "if [ -f /opt/mid/.env ]; then cp /opt/mid/.env /tmp/mid.env.bak; fi && "
            "rsync -a --delete "
            "--exclude '.env' --exclude '.venv' --exclude '*.db' --exclude 'mid_data' "
            "/opt/mid-repo/MID/ /opt/mid/ && "
            "if [ -f /tmp/mid.env.bak ]; then mv /tmp/mid.env.bak /opt/mid/.env; "
            "elif [ ! -f /opt/mid/.env ]; then "
            "  printf 'SECRET_KEY=mid-prod-restart\\nMID_HTTP_PORT=8100\\n' > /opt/mid/.env; "
            "fi && "
            "grep -q MID_HTTP_PORT /opt/mid/.env || echo MID_HTTP_PORT=8100 >> /opt/mid/.env",
        )

        run(c, "swapon /swapfile_mid 2>/dev/null || true", check=False)
        run(
            c,
            "cd /opt/mid && docker compose --env-file .env down && "
            "docker compose --env-file .env up -d --build --remove-orphans",
        )
        run(c, "cd /opt/mid && docker compose ps")
        run(
            c,
            "curl -fsS -o /dev/null -w 'health:%{http_code}\\n' http://127.0.0.1:8100/health && "
            "curl -fsS -o /dev/null -w 'home:%{http_code}\\n' http://127.0.0.1:8100/",
            check=False,
        )
        print(f"\nOK: http://{HOST}:8100/")
    finally:
        c.close()


if __name__ == "__main__":
    main()
