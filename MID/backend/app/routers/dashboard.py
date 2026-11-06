from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import LEADERSHIP, get_current_user
from app.models import (
    Announcement,
    AttendanceRecord,
    Department,
    FinanceRecord,
    JobTitle,
    Project,
    ProjectUpdate,
    StudyGroup,
    StudyMaterial,
    Task,
    User,
)
from app.schemas import BootstrapData, DashboardSummary, ProjectOut
from app.serializers import user_out, users_out
from app.services import get_balance

router = APIRouter(tags=["dashboard"])


def _staff_only(db: Session) -> list[User]:
    return list(
        db.scalars(
            select(User).where(User.active.is_(True), User.role == "xodim")
        ).all()
    )


@router.get("/dashboard/summary", response_model=DashboardSummary)
def dashboard_summary(
    viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> DashboardSummary:
    bal = get_balance(db)
    staff = list(
        db.scalars(
            select(User).where(
                User.active.is_(True),
                User.role.in_(["direktor", "rahbar", "xodim"]),
            )
        ).all()
    )
    projects = list(db.scalars(select(Project)).all())
    active = [p for p in projects if p.stage.lower() != "yopilgan"]
    tasks = list(db.scalars(select(Task)).all())
    open_statuses = {"yangi", "jarayonda", "javobBerildi"}
    open_assignees = {
        t.assignee_id for t in tasks if t.status in open_statuses
    }
    responded_ids = {
        t.assignee_id for t in tasks if t.status == "javobBerildi"
    }
    pending_ids = {
        t.assignee_id
        for t in tasks
        if t.status in {"yangi", "jarayonda"}
    }
    xodimlar = _staff_only(db)
    loaded = [e for e in xodimlar if e.id in open_assignees]
    unloaded = [e for e in xodimlar if e.id not in open_assignees]
    responded = [e for e in xodimlar if e.id in responded_ids]
    no_response = [
        e for e in xodimlar if e.id in pending_ids and e.id not in responded_ids
    ]
    return DashboardSummary(
        staff_count=len(staff),
        active_projects=len(active),
        company_cash=bal.company_cash,
        reserve_cash=bal.reserve_cash,
        loaded_employees=users_out(loaded, viewer),
        unloaded_employees=users_out(unloaded, viewer),
        responded_employees=users_out(responded, viewer),
        no_response_employees=users_out(no_response, viewer),
    )


@router.get("/bootstrap", response_model=BootstrapData)
def bootstrap(
    viewer: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> BootstrapData:
    """Bitta so'rovda UI cache uchun barcha ma'lumotlar."""
    bal = get_balance(db)
    all_users = list(db.scalars(select(User)).all())
    tasks = list(db.scalars(select(Task).order_by(Task.created_at.desc())).all())
    projects = list(db.scalars(select(Project)).all())
    updates = list(
        db.scalars(
            select(ProjectUpdate).order_by(ProjectUpdate.created_at.desc())
        ).all()
    )
    finances = list(
        db.scalars(
            select(FinanceRecord).order_by(FinanceRecord.created_at.desc())
        ).all()
    )
    departments = list(db.scalars(select(Department)).all())
    job_titles = list(
        db.scalars(
            select(JobTitle).where(JobTitle.active.is_(True)).order_by(JobTitle.name)
        ).all()
    )
    groups = list(db.scalars(select(StudyGroup)).all())
    attendance = list(
        db.scalars(
            select(AttendanceRecord).order_by(AttendanceRecord.date.desc())
        ).all()
    )
    materials = list(db.scalars(select(StudyMaterial)).all())
    announcements = list(
        db.scalars(
            select(Announcement).order_by(Announcement.created_at.desc())
        ).all()
    )

    # Role-based filtering mirrors individual endpoints
    if viewer.role not in LEADERSHIP:
        tasks = [t for t in tasks if t.assignee_id == viewer.id]
        announcements = [
            a
            for a in announcements
            if a.audience == "barcha"
            or (a.audience == "xodimlar" and viewer.role == "xodim")
            or (a.audience == "shogirtlar" and viewer.role == "shogirt")
            or (a.audience == "oquvchilar" and viewer.role == "oquvchi")
        ]
    if viewer.role in {"xodim", "shogirt"}:
        projects = [p for p in projects if viewer.id in (p.assignee_ids or [])]
    elif viewer.role == "oquvchi":
        projects = []
    if viewer.role not in LEADERSHIP:
        finances = []
    if viewer.role in {"oquvchi", "shogirt"}:
        attendance = [a for a in attendance if a.student_id == viewer.id]
        if viewer.group_id:
            materials = [m for m in materials if m.group_id == viewer.group_id]

    show_pw = viewer.role in LEADERSHIP
    return BootstrapData(
        users=[user_out(u, include_password=show_pw) for u in all_users],
        tasks=tasks,
        projects=[ProjectOut.model_validate(p) for p in projects],
        project_updates=updates,
        finances=finances,
        departments=departments,
        job_titles=job_titles,
        groups=groups,
        attendance=attendance,
        materials=materials,
        announcements=announcements,
        company_cash=bal.company_cash,
        reserve_cash=bal.reserve_cash,
        me=user_out(viewer, include_password=False),
    )
