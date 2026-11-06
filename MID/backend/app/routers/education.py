from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import LEADERSHIP, get_current_user, require_leadership
from app.models import AttendanceRecord, StudyGroup, StudyMaterial, User
from app.schemas import (
    AttendanceBulk,
    AttendanceOut,
    GroupCreate,
    GroupOut,
    MaterialCreate,
    MaterialOut,
    RankingItem,
)
from app.serializers import user_out
from app.services import next_id

router = APIRouter(tags=["education"])


@router.get("/groups", response_model=list[GroupOut])
def list_groups(
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[StudyGroup]:
    return list(db.scalars(select(StudyGroup)).all())


@router.post("/groups", response_model=GroupOut, status_code=201)
def create_group(
    body: GroupCreate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> StudyGroup:
    group = StudyGroup(
        id=next_id(db, "g"),
        name=body.name.strip(),
        direction=body.direction.strip(),
        teacher_id=body.teacher_id,
        sector=body.sector,
    )
    db.add(group)
    db.commit()
    db.refresh(group)
    return group


@router.get("/attendance", response_model=list[AttendanceOut])
def list_attendance(
    group_id: str | None = None,
    student_id: str | None = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[AttendanceRecord]:
    stmt = select(AttendanceRecord).order_by(AttendanceRecord.date.desc())
    if group_id:
        stmt = stmt.where(AttendanceRecord.group_id == group_id)
    if student_id:
        stmt = stmt.where(AttendanceRecord.student_id == student_id)
    rows = list(db.scalars(stmt).all())
    if user.role in {"oquvchi", "shogirt"}:
        rows = [r for r in rows if r.student_id == user.id]
    return rows


@router.post("/attendance/bulk", response_model=list[AttendanceOut], status_code=201)
def bulk_attendance(
    body: AttendanceBulk,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> list[AttendanceRecord]:
    when = body.date or datetime.utcnow()
    created: list[AttendanceRecord] = []
    for entry in body.records:
        grade = max(1, min(10, entry.grade))
        rec = AttendanceRecord(
            id=next_id(db, "a"),
            group_id=body.group_id,
            student_id=entry.student_id,
            date=when,
            present=entry.present,
            grade=grade,
        )
        db.add(rec)
        created.append(rec)
    db.commit()
    for rec in created:
        db.refresh(rec)
    return created


@router.get("/materials", response_model=list[MaterialOut])
def list_materials(
    group_id: str | None = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[StudyMaterial]:
    stmt = select(StudyMaterial)
    if group_id:
        stmt = stmt.where(StudyMaterial.group_id == group_id)
    rows = list(db.scalars(stmt).all())
    if user.role in {"oquvchi", "shogirt"} and user.group_id:
        rows = [m for m in rows if m.group_id == user.group_id]
    return rows


@router.post("/materials", response_model=MaterialOut, status_code=201)
def create_material(
    body: MaterialCreate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> StudyMaterial:
    mat = StudyMaterial(
        id=next_id(db, "m"),
        group_id=body.group_id,
        title=body.title.strip(),
        type=body.type,
        url_or_note=body.url_or_note,
    )
    db.add(mat)
    db.commit()
    db.refresh(mat)
    return mat


def _avg_grade(db: Session, student_id: str) -> float:
    rows = db.scalars(
        select(AttendanceRecord).where(AttendanceRecord.student_id == student_id)
    ).all()
    if not rows:
        return 0.0
    return sum(r.grade for r in rows) / len(rows)


@router.get("/learners/ranking", response_model=list[RankingItem])
def ranking(
    limit: int = Query(5, ge=1, le=50),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[RankingItem]:
    learners = list(
        db.scalars(
            select(User).where(
                User.active.is_(True),
                User.role.in_(["oquvchi", "shogirt"]),
            )
        ).all()
    )
    ranked = sorted(
        learners, key=lambda u: _avg_grade(db, u.id), reverse=True
    )[:limit]
    show_pw = user.role in LEADERSHIP
    return [
        RankingItem(
            user=user_out(u, include_password=show_pw),
            average_grade=_avg_grade(db, u.id),
        )
        for u in ranked
    ]
