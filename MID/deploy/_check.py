import os
import paramiko

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(
    "173.249.47.202",
    username="root",
    password=os.environ["MID_SSH_PASSWORD"],
    timeout=30,
    allow_agent=False,
    look_for_keys=False,
)
cmds = [
    "cd /opt/mid && docker compose ps -a",
    "cd /opt/mid && docker compose logs --tail=80 web 2>&1 | tail -80",
    "cd /opt/mid && docker compose logs --tail=40 backend 2>&1 | tail -40",
    "curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8100/health || true",
    "echo",
    "curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8100/ || true",
    "echo",
]
for cmd in cmds:
    print("====", cmd)
    _, stdout, stderr = c.exec_command(cmd)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    print(out)
    if err.strip():
        print(err)
c.close()
