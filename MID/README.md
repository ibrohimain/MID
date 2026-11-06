# MID

Yagona boshqaruv paneli — Direktor, 2 Rahbar (A/B sektor), xodim, o‘quvchi, shogirt.

## Talablar

1. **Backend** (Python / FastAPI) — `../backend`
2. **Flutter** SDK

## Backendni ishga tushirish

```bash
cd ../backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://127.0.0.1:8000/docs

## Frontendni ishga tushirish

```bash
cd MID
flutter pub get
flutter run -d chrome
```

Boshqa host/port:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.10:8000
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
