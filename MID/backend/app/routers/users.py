from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import can_delete_user, get_current_user, require_leadership
from app.models import User
from app.schemas import LoginCheck, MessageOut, UserCreate, UserOut, UserUpdate
from app.security import hash_password
from app.serializers import user_out, users_out
from app.services import next_id

router = APIRouter(prefix="/users", tags=["users"])


@router.get("", response_model=list[UserOut])
def list_users(
    role: str | None = None,
    sector: str | None = None,
    department_id: str | None = None,
    q: str | None = None,
    active: bool | None = True,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[UserOut]:
    stmt = select(User)
    if active is not None:
        stmt = stmt.where(User.active.is_(active))
    if role:
        stmt = stmt.where(User.role == role)
    if sector:
        stmt = stmt.where(User.sector == sector)
    if department_id:
        stmt = stmt.where(User.department_id == department_id)
    rows = list(db.scalars(stmt).all())
    if q:
        needle = q.strip().lower()
        rows = [
            u
            for u in rows
            if needle in u.full_name.lower() or needle in u.login.lower()
        ]
    return users_out(rows, user)


@router.get("/employees", response_model=list[UserOut])
def employees(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[UserOut]:
    rows = db.scalars(
        select(User).where(
            User.active.is_(True),
            User.role.in_(["direktor", "rahbar", "xodim"]),
        )
    ).all()
    return users_out(list(rows), user)


@router.get("/learners", response_model=list[UserOut])
def learners(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[UserOut]:
    rows = db.scalars(
        select(User).where(
            User.active.is_(True),
            User.role.in_(["oquvchi", "shogirt"]),
        )
    ).all()
    if user.role in {"oquvchi", "shogirt"}:
        rows = [u for u in rows if u.id == user.id]
    return users_out(list(rows), user)


@router.get("/check-login", response_model=LoginCheck)
def check_login(
    login: str = Query(...),
    except_user_id: str | None = None,
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> LoginCheck:
    needle = login.strip().lower()
    rows = db.scalars(select(User).where(User.active.is_(True))).all()
    taken = any(
        u.login.lower() == needle and u.id != except_user_id for u in rows
    )
    return LoginCheck(taken=taken)


@router.get("/{user_id}", response_model=UserOut)
def get_user(
    user_id: str,
    viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserOut:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    show_pw = viewer.role in {"direktor", "rahbar"}
    return user_out(target, include_password=show_pw)


@router.post("", response_model=UserOut, status_code=201)
def create_user(
    body: UserCreate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> UserOut:
    if body.role == "direktor":
        raise HTTPException(400, "Direktor yaratib bo'lmaydi")
    if body.role == "rahbar" and actor.role != "direktor":
        raise HTTPException(403, "Faqat direktor rahbar qo'sha oladi")
    needle = body.login.strip().lower()
    existing = db.scalars(select(User).where(User.active.is_(True))).all()
    if any(u.login.lower() == needle for u in existing):
        raise HTTPException(400, "Bu login band")
    user = User(
        id=next_id(db, "u"),
        full_name=body.full_name.strip(),
        login=body.login.strip(),
        password_hash=hash_password(body.password),
        password_plain=body.password,
        role=body.role,
        sector=body.sector,
        department_id=body.department_id,
        position=body.position,
        email=body.email,
        phone=body.phone,
        group_id=body.group_id,
        direction=body.direction,
        salary=body.salary,
        payment_amount=body.payment_amount,
        studied_months=body.studied_months,
        total_months=body.total_months,
        active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user_out(user, include_password=True)


@router.patch("/{user_id}", response_model=UserOut)
def update_user(
    user_id: str,
    body: UserUpdate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> UserOut:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    if body.login is not None:
        needle = body.login.strip().lower()
        rows = db.scalars(select(User).where(User.active.is_(True))).all()
        if any(u.login.lower() == needle and u.id != user_id for u in rows):
            raise HTTPException(400, "Bu login band")
        target.login = body.login.strip()
    if body.full_name is not None:
        target.full_name = body.full_name.strip()
    if body.password is not None and body.password.strip():
        plain = body.password.strip()
        target.password_hash = hash_password(plain)
        target.password_plain = plain
    if body.role is not None and body.role != "direktor":
        if body.role == "rahbar" and actor.role != "direktor":
            raise HTTPException(403, "Faqat direktor rolni rahbarga o'zgartira oladi")
        target.role = body.role
    for field in (
        "sector",
        "department_id",
        "position",
        "email",
        "phone",
        "group_id",
        "direction",
        "salary",
        "payment_amount",
        "studied_months",
        "total_months",
    ):
        val = getattr(body, field)
        if val is not None:
            setattr(target, field, val)
    db.commit()
    db.refresh(target)
    return user_out(target, include_password=True)


@router.delete("/{user_id}", response_model=MessageOut)
def delete_user(
    user_id: str,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> MessageOut:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(404, "Foydalanuvchi topilmadi")
    if not can_delete_user(actor, target):
        raise HTTPException(403, "Bu foydalanuvchini o'chirib bo'lmaydi")
    target.active = False
    db.commit()
    return MessageOut(message="O'chirildi")
