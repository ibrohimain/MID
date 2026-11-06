from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AppBalance(Base):
    __tablename__ = "app_balance"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    company_cash: Mapped[int] = mapped_column(Integer, default=0)
    reserve_cash: Mapped[int] = mapped_column(Integer, default=0)
    seq: Mapped[int] = mapped_column(Integer, default=100)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    full_name: Mapped[str] = mapped_column(String(255))
    login: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    # Demo UX: leadership can see/reset plain password shown in UI
    password_plain: Mapped[str] = mapped_column(String(255), default="")
    role: Mapped[str] = mapped_column(String(32), index=True)
    sector: Mapped[str | None] = mapped_column(String(8), nullable=True)
    department_id: Mapped[str | None] = mapped_column(
        String(64), ForeignKey("departments.id"), nullable=True
    )
    position: Mapped[str | None] = mapped_column(String(255), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    group_id: Mapped[str | None] = mapped_column(
        String(64), ForeignKey("study_groups.id"), nullable=True
    )
    direction: Mapped[str | None] = mapped_column(String(255), nullable=True)
    salary: Mapped[int] = mapped_column(Integer, default=0)
    payment_amount: Mapped[int] = mapped_column(Integer, default=0)
    studied_months: Mapped[int] = mapped_column(Integer, default=0)
    total_months: Mapped[int] = mapped_column(Integer, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Department(Base):
    __tablename__ = "departments"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    sector: Mapped[str] = mapped_column(String(8))
    head_id: Mapped[str] = mapped_column(String(64))
    positions: Mapped[list] = mapped_column(JSON, default=list)


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text, default="")
    assignee_id: Mapped[str] = mapped_column(String(64), index=True)
    created_by_id: Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(32), default="yangi")
    priority: Mapped[str] = mapped_column(String(32), default="orta")
    project_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Project(Base):
    __tablename__ = "projects"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text, default="")
    stage: Mapped[str] = mapped_column(String(64), default="Goya")
    required_budget: Mapped[int] = mapped_column(Integer, default=0)
    investment: Mapped[int] = mapped_column(Integer, default=0)
    expense: Mapped[int] = mapped_column(Integer, default=0)
    sector: Mapped[str] = mapped_column(String(8))
    assignee_ids: Mapped[list] = mapped_column(JSON, default=list)
    parts: Mapped[dict] = mapped_column(JSON, default=dict)

    updates: Mapped[list["ProjectUpdate"]] = relationship(
        back_populates="project", cascade="all, delete-orphan"
    )


class ProjectUpdate(Base):
    __tablename__ = "project_updates"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    project_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("projects.id", ondelete="CASCADE"), index=True
    )
    author_id: Mapped[str] = mapped_column(String(64))
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    project: Mapped["Project"] = relationship(back_populates="updates")


class Announcement(Base):
    __tablename__ = "announcements"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[str] = mapped_column(Text, default="")
    author_id: Mapped[str] = mapped_column(String(64))
    audience: Mapped[str] = mapped_column(String(32), default="barcha")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class FinanceRecord(Base):
    __tablename__ = "finance_records"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    title: Mapped[str] = mapped_column(String(255))
    amount: Mapped[int] = mapped_column(Integer)
    type: Mapped[str] = mapped_column(String(32))
    receipt_no: Mapped[str] = mapped_column(String(64), unique=True)
    note: Mapped[str] = mapped_column(Text, default="")
    related_user_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    project_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class StudyGroup(Base):
    __tablename__ = "study_groups"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    direction: Mapped[str] = mapped_column(String(255))
    teacher_id: Mapped[str] = mapped_column(String(64))
    sector: Mapped[str | None] = mapped_column(String(8), nullable=True)


class AttendanceRecord(Base):
    __tablename__ = "attendance"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    group_id: Mapped[str] = mapped_column(String(64), index=True)
    student_id: Mapped[str] = mapped_column(String(64), index=True)
    date: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    present: Mapped[bool] = mapped_column(Boolean, default=True)
    grade: Mapped[int] = mapped_column(Integer, default=5)


class StudyMaterial(Base):
    __tablename__ = "study_materials"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    group_id: Mapped[str] = mapped_column(String(64), index=True)
    title: Mapped[str] = mapped_column(String(255))
    type: Mapped[str] = mapped_column(String(32))
    url_or_note: Mapped[str] = mapped_column(Text, default="")
