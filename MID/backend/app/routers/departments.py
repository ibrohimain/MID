from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user, require_leadership
from app.models import Department, User
from app.schemas import (
    DepartmentCreate,
    DepartmentHeadUpdate,
    DepartmentOut,
    DepartmentStaffAssign,
    DepartmentUpdate,
)
from app.services import next_id

router = APIRouter(prefix="/departments", tags=["departments"])


@router.get("", response_model=list[DepartmentOut])
def list_departments(
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Department]:
    return list(db.scalars(select(Department)).all())


@router.post("", response_model=DepartmentOut, status_code=201)
def create_department(
    body: DepartmentCreate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Department:
    dept = Department(
        id=next_id(db, "d"),
        name=body.name.strip(),
        sector=body.sector,
        head_id=body.head_id,
        positions=list(body.positions),
    )
    db.add(dept)
    db.commit()
    db.refresh(dept)
    return dept


@router.patch("/{dept_id}", response_model=DepartmentOut)
def update_department(
    dept_id: str,
    body: DepartmentUpdate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Department:
    dept = db.get(Department, dept_id)
    if dept is None:
        raise HTTPException(404, "Bo'lim topilmadi")
    if body.name is not None:
        dept.name = body.name.strip()
    if body.sector is not None:
        dept.sector = body.sector
    if body.head_id is not None:
        dept.head_id = body.head_id
    if body.positions is not None:
        dept.positions = list(body.positions)
    db.commit()
    db.refresh(dept)
    return dept


@router.patch("/{dept_id}/head", response_model=DepartmentOut)
def assign_head(
    dept_id: str,
    body: DepartmentHeadUpdate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Department:
    dept = db.get(Department, dept_id)
    if dept is None:
        raise HTTPException(404, "Bo'lim topilmadi")
    dept.head_id = body.head_id
    db.commit()
    db.refresh(dept)
    return dept


@router.post("/{dept_id}/staff", response_model=DepartmentOut)
def assign_staff_from_catalog(
    dept_id: str,
    body: DepartmentStaffAssign,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Department:
    """Katalogdan mavjud xodimni bo'limga biriktirish + lavozim."""
    dept = db.get(Department, dept_id)
    if dept is None:
        raise HTTPException(404, "Bo'lim topilmadi")
    user = db.get(User, body.user_id)
    if user is None or not user.active or user.role != "xodim":
        raise HTTPException(400, "Katalogdan faqat faol xodim tanlanadi")
    pos = body.position.strip()
    if not pos:
        raise HTTPException(400, "Lavozim majburiy")
    user.department_id = dept.id
    user.sector = dept.sector
    user.position = pos
    positions = list(dept.positions or [])
    if pos not in positions:
        positions.append(pos)
        dept.positions = positions
    if body.make_head:
        dept.head_id = user.id
    db.commit()
    db.refresh(dept)
    return dept


@router.delete("/{dept_id}")
def delete_department(
    dept_id: str,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> dict:
    dept = db.get(Department, dept_id)
    if dept is None:
        raise HTTPException(404, "Bo'lim topilmadi")
    users = db.scalars(select(User).where(User.department_id == dept_id)).all()
    for u in users:
        u.department_id = None
    db.delete(dept)
    db.commit()
    return {"message": "O'chirildi"}
