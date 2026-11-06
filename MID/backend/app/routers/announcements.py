from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import LEADERSHIP, get_current_user, require_leadership
from app.models import Announcement, User
from app.schemas import AnnouncementCreate, AnnouncementOut, AnnouncementUpdate
from app.services import next_id

router = APIRouter(prefix="/announcements", tags=["announcements"])


def _visible(a: Announcement, user: User) -> bool:
    if user.role in LEADERSHIP:
        return True
    return a.audience == "barcha" or (
        (a.audience == "xodimlar" and user.role == "xodim")
        or (a.audience == "shogirtlar" and user.role == "shogirt")
        or (a.audience == "oquvchilar" and user.role == "oquvchi")
    )


@router.get("", response_model=list[AnnouncementOut])
def list_announcements(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Announcement]:
    rows = list(
        db.scalars(
            select(Announcement).order_by(Announcement.created_at.desc())
        ).all()
    )
    return [a for a in rows if _visible(a, user)]


@router.post("", response_model=AnnouncementOut, status_code=201)
def create_announcement(
    body: AnnouncementCreate,
    actor: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Announcement:
    item = Announcement(
        id=next_id(db, "an"),
        title=body.title.strip(),
        body=body.body,
        author_id=actor.id,
        audience=body.audience,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.patch("/{ann_id}", response_model=AnnouncementOut)
def update_announcement(
    ann_id: str,
    body: AnnouncementUpdate,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> Announcement:
    item = db.get(Announcement, ann_id)
    if item is None:
        raise HTTPException(404, "E'lon topilmadi")
    if body.title is not None:
        item.title = body.title.strip()
    if body.body is not None:
        item.body = body.body
    if body.audience is not None:
        item.audience = body.audience
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{ann_id}")
def delete_announcement(
    ann_id: str,
    _: User = Depends(require_leadership),
    db: Session = Depends(get_db),
) -> dict:
    item = db.get(Announcement, ann_id)
    if item is None:
        raise HTTPException(404, "E'lon topilmadi")
    db.delete(item)
    db.commit()
    return {"message": "O'chirildi"}
