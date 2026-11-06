# MID

Yagona boshqaruv paneli (Flutter + FastAPI). Asosiy kod: `MID/`.

```
mid/
└── MID/
    ├── lib/       # Flutter UI
    └── backend/   # FastAPI + SQLite
```

## Backend

```bash
cd MID/backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Frontend

```bash
cd MID
flutter pub get
flutter run -d chrome
```

## Demo loginlar

| Login | Parol | Rol |
|---|---|---|
| `direktor` | `1234` | Direktor |
| `rahbar_a` | `a12345` | Rahbar A |
| `rahbar_b` | `b12345` | Rahbar B |
| `jasur` | `1234` | Xodim |
| `madina` | `1234` | O‘quvchi |
| `sardor` | `1234` | Shogirt |
