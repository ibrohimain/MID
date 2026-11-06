# MID

Yagona boshqaruv paneli — Direktor, 2 Rahbar (A/B sektor), xodim, o‘quvchi, shogirt.

```
MID/
├── lib/          # Flutter UI
├── backend/      # FastAPI + SQLite
├── deploy/       # production scripts
└── docker-compose.yml
```

## Production (Docker)

```bash
cd MID
# serverda:
docker compose --env-file .env up -d --build
```

Default port: **8100** (`MID_HTTP_PORT`).

Deploy helper (local → VPS):

```bash
set MID_SSH_PASSWORD=...
set MID_SSH_HOST=...
python deploy/push_deploy.py
```

## Local backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Local frontend

```bash
flutter pub get
flutter run -d chrome
```

## Demo loginlar

| Login | Parol | Rol |
|---|---|---|
| `direktor` | `1234` | Yagona Direktor |
| `rahbar_a` | `a12345` | A sektor rahbari |
| `rahbar_b` | `b12345` | B sektor rahbari |
| `jasur` | `1234` | Xodim |
| `madina` | `1234` | O‘quvchi |
| `sardor` | `1234` | Shogirt |
