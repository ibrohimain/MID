from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_finance
from app.models import FinanceRecord, User
from app.schemas import FinanceCreate, FinanceOut, FinanceSummary, FinanceUpdate
from app.services import apply_finance, get_balance, next_id, next_receipt

router = APIRouter(prefix="/finance", tags=["finance"])


@router.get("/summary", response_model=FinanceSummary)
def summary(
    _: User = Depends(require_finance),
    db: Session = Depends(get_db),
) -> FinanceSummary:
    bal = get_balance(db)
    rows = list(db.scalars(select(FinanceRecord)).all())
    kirim = sum(f.amount for f in rows if f.type == "kirim")
    chiqim = sum(
        f.amount for f in rows if f.type in {"chiqim", "maosh", "ajratma"}
    )
    maosh = sum(f.amount for f in rows if f.type == "maosh")
    return FinanceSummary(
        company_cash=bal.company_cash,
        reserve_cash=bal.reserve_cash,
        total_kirim=kirim,
        total_chiqim=chiqim,
        total_maosh=maosh,
        records_count=len(rows),
    )


@router.get("/records", response_model=list[FinanceOut])
def list_records(
    _: User = Depends(require_finance),
    db: Session = Depends(get_db),
) -> list[FinanceRecord]:
    return list(
        db.scalars(
            select(FinanceRecord).order_by(FinanceRecord.created_at.desc())
        ).all()
    )


@router.post("/records", response_model=FinanceOut, status_code=201)
def create_record(
    body: FinanceCreate,
    _: User = Depends(require_finance),
    db: Session = Depends(get_db),
) -> FinanceRecord:
    if body.amount <= 0:
        raise HTTPException(400, "Summa musbat bo'lishi kerak")
    if body.type not in {"kirim", "chiqim", "maosh", "zaxira", "ajratma"}:
        raise HTTPException(400, "Noto'g'ri moliya turi")
    rec = FinanceRecord(
        id=next_id(db, "f"),
        title=body.title.strip(),
        amount=body.amount,
        type=body.type,
        receipt_no=next_receipt(db),
        note=body.note,
        related_user_id=body.related_user_id,
        project_id=body.project_id,
    )
    db.add(rec)
    apply_finance(db, body.type, body.amount, reverse=False)
    db.commit()
    db.refresh(rec)
    return rec


@router.patch("/records/{record_id}", response_model=FinanceOut)
def update_record(
    record_id: str,
    body: FinanceUpdate,
    _: User = Depends(require_finance),
    db: Session = Depends(get_db),
) -> FinanceRecord:
    rec = db.get(FinanceRecord, record_id)
    if rec is None:
        raise HTTPException(404, "Yozuv topilmadi")
    apply_finance(db, rec.type, rec.amount, reverse=True)
    if body.title is not None:
        rec.title = body.title.strip()
    if body.amount is not None:
        rec.amount = body.amount
    if body.type is not None:
        rec.type = body.type
    if body.note is not None:
        rec.note = body.note
    apply_finance(db, rec.type, rec.amount, reverse=False)
    db.commit()
    db.refresh(rec)
    return rec


@router.delete("/records/{record_id}")
def delete_record(
    record_id: str,
    _: User = Depends(require_finance),
    db: Session = Depends(get_db),
) -> dict:
    rec = db.get(FinanceRecord, record_id)
    if rec is None:
        raise HTTPException(404, "Yozuv topilmadi")
    apply_finance(db, rec.type, rec.amount, reverse=True)
    db.delete(rec)
    db.commit()
    return {"message": "O'chirildi"}
