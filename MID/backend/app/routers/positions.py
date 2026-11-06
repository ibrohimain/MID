from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user, require_leadership
from app.models import JobTitle, User
from app.schemas import JobTitleCreate, JobTitleOut, JobTitleUpdate
from app.services import next_id

router = APIRouter(prefix="/positions", tags=["positions"])


@router.get("", response_model=list[JobTitleOut])
def list_positions(
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[JobTitle]:
    return list(
        db.scalars(
            select(JobTitle).where(JobTitle.active.is_(True)).order_by(JobTitle.name)
        ).all()
    )


@router.post("", response_model=JobTitleOut, status_code=201)
def create_position(
    body: JobTitleCreate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> JobTitle:
    if actor.role != "direktor":
        raise HTTPException(403, "Lavozimni faqat Direktor kiritadi")
    name = body.name.strip()
    if not name:
        raise HTTPException(400, "Lavozim nomi bo'sh")
    exists = db.scalar(select(JobTitle).where(JobTitle.name == name))
    if exists:
        raise HTTPException(400, "Bu lavozim allaqachon bor")
    row = JobTitle(id=next_id(db, "jt"), name=name, active=True)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{title_id}", response_model=JobTitleOut)
def update_position(
    title_id: str,
    body: JobTitleUpdate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> JobTitle:
    if actor.role != "direktor":
        raise HTTPException(403, "Lavozimni faqat Direktor tahrirlaydi")
    row = db.get(JobTitle, title_id)
    if row is None:
        raise HTTPException(404, "Lavozim topilmadi")
    if body.name is not None:
        row.name = body.name.strip()
    if body.active is not None:
        row.active = body.active
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{title_id}")
def delete_position(
    title_id: str,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> dict:
    if actor.role != "direktor":
        raise HTTPException(403, "Lavozimni faqat Direktor o'chiradi")
    row = db.get(JobTitle, title_id)
    if row is None:
        raise HTTPException(404, "Lavozim topilmadi")
    row.active = False
    db.commit()
    return {"message": "O'chirildi"}
