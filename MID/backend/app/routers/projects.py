from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import LEADERSHIP, get_current_user, require_leadership
from app.models import Project, ProjectUpdate, Task, User
from app.schemas import (
    ProjectCreate,
    ProjectOut,
    ProjectPartAssign,
    ProjectStageUpdate,
    ProjectUpdateBody,
    ProjectUpdateCreate,
    ProjectUpdateOut,
)
from app.services import next_id

router = APIRouter(prefix="/projects", tags=["projects"])


def _rahbars_for_sector(db: Session, sector: str) -> list[User]:
    q = select(User).where(User.active.is_(True), User.role == "rahbar")
    if sector == "both":
        return list(db.scalars(q).all())
    return list(db.scalars(q.where(User.sector == sector)).all())


@router.get("", response_model=list[ProjectOut])
def list_projects(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Project]:
    rows = list(db.scalars(select(Project)).all())
    if user.role in {"xodim", "shogirt"}:
        rows = [p for p in rows if user.id in (p.assignee_ids or [])]
    elif user.role == "oquvchi":
        rows = []
    return rows


@router.post("", response_model=ProjectOut, status_code=201)
def create_project(
    body: ProjectCreate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Project:
    if body.sector not in {"a", "b", "both"}:
        raise HTTPException(400, "Sektor: a, b yoki both")

    assignee_ids = list(body.assignee_ids)
    member_positions: dict[str, str] = {}
    rahbars = _rahbars_for_sector(db, body.sector)
    for r in rahbars:
        if r.id not in assignee_ids:
            assignee_ids.append(r.id)
        member_positions[r.id] = "Loyiha rahbari"

    project = Project(
        id=next_id(db, "p"),
        name=body.name.strip(),
        description=body.description,
        stage=body.stage,
        required_budget=body.required_budget,
        investment=body.investment,
        expense=body.expense,
        sector=body.sector,
        assignee_ids=assignee_ids,
        parts={},
        member_positions=member_positions,
    )
    db.add(project)
    db.flush()

    # Rahbarlarga loyiha bo'yicha topshiriq yuklash
    for r in rahbars:
        db.add(
            Task(
                id=next_id(db, "t"),
                title=f"Loyiha rahbarligi: {project.name}",
                description=(
                    f"Siz «{project.name}» loyihasiga rahbar etib tayinlandingiz "
                    f"({body.sector} jamoa)."
                ),
                assignee_id=r.id,
                created_by_id=actor.id,
                status="yangi",
                priority="yuqori",
                project_id=project.id,
            )
        )

    db.commit()
    db.refresh(project)
    return project


@router.patch("/{project_id}", response_model=ProjectOut)
def update_project(
    project_id: str,
    body: ProjectUpdateBody,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Project:
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(404, "Loyiha topilmadi")
    for field in (
        "name",
        "description",
        "stage",
        "required_budget",
        "investment",
        "expense",
        "sector",
    ):
        val = getattr(body, field)
        if val is not None:
            setattr(project, field, val)
    db.commit()
    db.refresh(project)
    return project


@router.patch("/{project_id}/stage", response_model=ProjectOut)
def set_stage(
    project_id: str,
    body: ProjectStageUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Project:
    if user.role not in LEADERSHIP:
        raise HTTPException(403, "Ruxsat yo'q")
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(404, "Loyiha topilmadi")
    project.stage = body.stage
    db.commit()
    db.refresh(project)
    return project


@router.put("/{project_id}/parts", response_model=ProjectOut)
def assign_part(
    project_id: str,
    body: ProjectPartAssign,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Project:
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(404, "Loyiha topilmadi")
    parts = dict(project.parts or {})
    parts[body.part_name] = body.employee_id
    project.parts = parts
    ids = list(project.assignee_ids or [])
    if body.employee_id not in ids:
        ids.append(body.employee_id)
        project.assignee_ids = ids
    if body.position:
        mp = dict(project.member_positions or {})
        mp[body.employee_id] = body.position.strip()
        project.member_positions = mp
    db.commit()
    db.refresh(project)
    return project


@router.delete("/{project_id}")
def delete_project(
    project_id: str,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> dict:
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(404, "Loyiha topilmadi")
    db.delete(project)
    db.commit()
    return {"message": "O'chirildi"}


@router.get("/{project_id}/updates", response_model=list[ProjectUpdateOut])
def list_updates(
    project_id: str,
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ProjectUpdate]:
    return list(
        db.scalars(
            select(ProjectUpdate)
            .where(ProjectUpdate.project_id == project_id)
            .order_by(ProjectUpdate.created_at.desc())
        ).all()
    )


@router.post("/{project_id}/updates", response_model=ProjectUpdateOut, status_code=201)
def add_update(
    project_id: str,
    body: ProjectUpdateCreate,
    actor: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProjectUpdate:
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(404, "Loyiha topilmadi")
    if actor.role not in LEADERSHIP and actor.id not in (project.assignee_ids or []):
        raise HTTPException(403, "Ruxsat yo'q")
    upd = ProjectUpdate(
        id=next_id(db, "pu"),
        project_id=project_id,
        author_id=actor.id,
        title=body.title.strip(),
        body=body.body,
    )
    db.add(upd)
    db.commit()
    db.refresh(upd)
    return upd
