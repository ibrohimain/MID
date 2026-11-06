from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security import decode_token

bearer = HTTPBearer(auto_error=False)

LEADERSHIP = {"direktor", "rahbar"}
STAFF_ROLES = {"direktor", "rahbar", "xodim"}
LEARNER_ROLES = {"oquvchi", "shogirt"}


def get_current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if creds is None or not creds.credentials:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Autentifikatsiya kerak")
    user_id = decode_token(creds.credentials)
    if not user_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token yaroqsiz")
    user = db.get(User, user_id)
    if user is None or not user.active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Foydalanuvchi topilmadi")
    return user


def require_leadership(user: User = Depends(get_current_user)) -> User:
    if user.role not in LEADERSHIP:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Ruxsat yo'q")
    return user


def require_finance(user: User = Depends(get_current_user)) -> User:
    if user.role not in LEADERSHIP:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Moliya faqat rahbariyat uchun")
    return user


def can_delete_user(actor: User, target: User) -> bool:
    if target.role == "direktor":
        return False
    if actor.role == "direktor":
        return target.role in {"xodim", "oquvchi", "shogirt", "rahbar"}
    if actor.role == "rahbar":
        return target.role in {"xodim", "oquvchi", "shogirt"}
    return False
