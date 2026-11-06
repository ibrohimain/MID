from app.models import User
from app.schemas import UserOut


def user_out(user: User, *, include_password: bool = False) -> UserOut:
    return UserOut(
        id=user.id,
        full_name=user.full_name,
        login=user.login,
        password=user.password_plain if include_password else "",
        role=user.role,
        sector=user.sector,
        department_id=user.department_id,
        position=user.position,
        email=user.email,
        phone=user.phone,
        group_id=user.group_id,
        direction=user.direction,
        salary=user.salary,
        payment_amount=user.payment_amount,
        studied_months=user.studied_months,
        total_months=user.total_months,
        active=user.active,
    )


def users_out(users: list[User], viewer: User | None = None) -> list[UserOut]:
    show_pw = viewer is not None and viewer.role in {"direktor", "rahbar"}
    return [user_out(u, include_password=show_pw) for u in users]
