# MID Backend (FastAPI)

Flutter MID boshqaruv paneli uchun REST API.

## Ishga tushirish

```bash
cd MID/backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Docs: http://127.0.0.1:8000/docs
- API: http://127.0.0.1:8000/api/v1

## Demo loginlar

| Login | Parol | Rol |
|---|---|---|
| `direktor` | `1234` | Direktor |
| `rahbar_a` | `a12345` | Rahbar A |
| `rahbar_b` | `b12345` | Rahbar B |
| `jasur` | `1234` | Xodim |
| `madina` | `1234` | O‘quvchi |
| `sardor` | `1234` | Shogirt |

## Asosiy endpointlar

- `POST /api/v1/auth/login`
- `GET /api/v1/bootstrap` — frontend cache uchun barcha ma’lumot
- `GET /api/v1/dashboard/summary`
- users / tasks / projects / finance / departments / groups / attendance / materials / announcements
