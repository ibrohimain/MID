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
cmd = (
    "docker compose version; "
    "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | head -40; "
    "swapon --show; free -h; ss -tlnp | grep -E ':80|:443|:8000' || true"
)
_, stdout, stderr = c.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
c.close()
