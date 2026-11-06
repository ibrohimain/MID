from datetime import datetime

from sqlalchemy.orm import Session

from app.models import AppBalance


def get_balance(db: Session) -> AppBalance:
    bal = db.get(AppBalance, 1)
    if bal is None:
        bal = AppBalance(id=1, company_cash=0, reserve_cash=0, seq=100)
        db.add(bal)
        db.flush()
    return bal


def next_id(db: Session, prefix: str) -> str:
    bal = get_balance(db)
    bal.seq += 1
    return f"{prefix}-{bal.seq}"


def next_receipt(db: Session) -> str:
    bal = get_balance(db)
    bal.seq += 1
    year = datetime.utcnow().year
    return f"CHK-{year}-{bal.seq}"


def apply_finance(db: Session, finance_type: str, amount: int, *, reverse: bool = False) -> None:
    bal = get_balance(db)
    signed = -amount if reverse else amount
    if finance_type == "kirim":
        bal.company_cash += signed
    elif finance_type in {"chiqim", "maosh", "ajratma"}:
        bal.company_cash -= signed
    elif finance_type == "zaxira":
        bal.company_cash -= signed
        bal.reserve_cash += signed
    else:
        raise ValueError(f"Noma'lum moliya turi: {finance_type}")
