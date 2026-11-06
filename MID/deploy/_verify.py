import json
import os
import urllib.error
import urllib.request

import paramiko

HOST = "173.249.47.202"
PORT = 8100
base = f"http://{HOST}:{PORT}"


def http(method: str, path: str, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None if data is None else json.dumps(data).encode()
    req = urllib.request.Request(
        base + path, data=body, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            raw = r.read().decode()
            print(method, path, r.status, raw[:200])
            return r.status, raw
    except urllib.error.HTTPError as e:
        print(method, path, e.code, e.read().decode()[:300])
        return e.code, ""
    except Exception as e:
        print(method, path, "ERR", e)
        return 0, str(e)


print("== external checks ==")
http("GET", "/")
http("GET", "/health")
code, raw = http(
    "POST", "/api/v1/auth/login", {"login": "direktor", "password": "1234"}
)
if code == 200:
    tok = json.loads(raw)["access_token"]
    http("GET", "/api/v1/bootstrap", token=tok)

# rebuild backend with 1 worker
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect(
    HOST,
    username="root",
    password=os.environ["MID_SSH_PASSWORD"],
    timeout=30,
    allow_agent=False,
    look_for_keys=False,
)
sftp = c.open_sftp()
sftp.put("backend/Dockerfile", "/opt/mid/backend/Dockerfile")
sftp.put("backend/app/main.py", "/opt/mid/backend/app/main.py")
sftp.close()
_, stdout, stderr = c.exec_command(
    "cd /opt/mid && docker compose --env-file .env up -d --build backend"
)
print(stdout.read().decode("utf-8", errors="replace")[-2000:])
print(stderr.read().decode("utf-8", errors="replace")[-1000:])
c.close()
print("done")
