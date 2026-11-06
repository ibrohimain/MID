from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import User
from app.schemas import (
    ChangePasswordRequest,
    LoginRequest,
    ProfileUpdate,
    TokenResponse,
    UserOut,
)
from app.security import create_access_token, hash_password, verify_password
from app.serializers import user_out

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    needle = body.login.strip().lower()
    user = db.scalar(select(User).where(User.login == needle))
    if user is None:
        # case-insensitive fallback
        users = db.scalars(select(User).where(User.active.is_(True))).all()
        user = next((u for u in users if u.login.lower() == needle), None)
    if (
        user is None
        or not user.active
        or not verify_password(body.password, user.password_hash)
    ):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Login yoki parol noto'g'ri"
        )
    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        user=user_out(user, include_password=False),
    )


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)) -> UserOut:
    return user_out(user, include_password=False)


@router.patch("/me", response_model=UserOut)
def update_me(
    body: ProfileUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserOut:
    if body.full_name is not None and body.full_name.strip():
        user.full_name = body.full_name.strip()
    if body.email is not None:
        user.email = body.email.strip()
    if body.phone is not None:
        user.phone = body.phone.strip()
    if body.password is not None and body.password.strip():
        plain = body.password.strip()
        if len(plain) < 4:
            raise HTTPException(400, "Parol kamida 4 belgi bo'lishi kerak")
        user.password_hash = hash_password(plain)
        user.password_plain = plain
    db.commit()
    db.refresh(user)
    return user_out(user, include_password=False)


@router.post("/change-password", response_model=UserOut)
def change_password(
    body: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserOut:
    if not verify_password(body.current_password, user.password_hash):
        raise HTTPException(400, "Joriy parol noto'g'ri")
    user.password_hash = hash_password(body.new_password)
    user.password_plain = body.new_password
    db.commit()
    db.refresh(user)
    return user_out(user, include_password=False)


@router.post("/logout")
def logout(_: User = Depends(get_current_user)) -> dict:
    return {"message": "OK"}
