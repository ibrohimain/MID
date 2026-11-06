from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import LEADERSHIP, get_current_user, require_leadership
from app.models import Task, User
from app.schemas import TaskCreate, TaskOut, TaskStatusUpdate, TaskUpdate
from app.services import next_id

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=list[TaskOut])
def list_tasks(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Task]:
    rows = list(db.scalars(select(Task).order_by(Task.created_at.desc())).all())
    if user.role not in LEADERSHIP:
        rows = [t for t in rows if t.assignee_id == user.id]
    return rows


@router.post("", response_model=TaskOut, status_code=201)
def create_task(
    body: TaskCreate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Task:
    assignee = db.get(User, body.assignee_id)
    if assignee is None or not assignee.active:
        raise HTTPException(400, "Mas'ul topilmadi")

    # Direktor → faqat rahbarlarga; Rahbar → o'z sektoridagi xodimlarga
    if actor.role == "direktor":
        if assignee.role != "rahbar":
            raise HTTPException(
                400, "Direktor topshiriqni faqat Rahbarlarga yuklaydi"
            )
    elif actor.role == "rahbar":
        if assignee.role != "xodim":
            raise HTTPException(
                400, "Rahbar topshiriqni faqat xodimlarga yuklaydi"
            )
        if actor.sector and assignee.sector and actor.sector != assignee.sector:
            raise HTTPException(400, "Faqat o'z sektoridagi xodimga yuklash mumkin")

    task = Task(
        id=next_id(db, "t"),
        title=body.title.strip(),
        description=body.description,
        assignee_id=body.assignee_id,
        created_by_id=actor.id,
        status="yangi",
        priority=body.priority,
        project_id=body.project_id,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.patch("/{task_id}", response_model=TaskOut)
def update_task(
    task_id: str,
    body: TaskUpdate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Task:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(404, "Topshiriq topilmadi")
    for field in ("title", "description", "assignee_id", "priority", "status", "project_id"):
        val = getattr(body, field)
        if val is not None:
            setattr(task, field, val.strip() if isinstance(val, str) and field == "title" else val)
    db.commit()
    db.refresh(task)
    return task


@router.patch("/{task_id}/status", response_model=TaskOut)
def set_status(
    task_id: str,
    body: TaskStatusUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Task:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(404, "Topshiriq topilmadi")
    if user.role not in LEADERSHIP and task.assignee_id != user.id:
        raise HTTPException(403, "Ruxsat yo'q")
    if user.role not in LEADERSHIP and body.status not in {
        "javobBerildi",
        "bajarildi",
        "jarayonda",
    }:
        raise HTTPException(403, "Bu statusni o'zgartira olmaysiz")
    task.status = body.status
    db.commit()
    db.refresh(task)
    return task


@router.delete("/{task_id}")
def delete_task(
    task_id: str,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> dict:
    task = db.get(Task, task_id)
    if task is None:
        raise HTTPException(404, "Topshiriq topilmadi")
    db.delete(task)
    db.commit()
    return {"message": "O'chirildi"}
