from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator


class OrmModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# --- Auth ---
class LoginRequest(BaseModel):
    login: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=4)


class ProfileUpdate(BaseModel):
    full_name: str | None = None
    email: str | None = None
    phone: str | None = None
    password: str | None = None


# --- Users ---
class UserOut(OrmModel):
    id: str
    full_name: str
    login: str
    password: str = ""
    role: str
    sector: str | None = None
    department_id: str | None = None
    position: str | None = None
    email: str | None = None
    phone: str | None = None
    group_id: str | None = None
    direction: str | None = None
    salary: int = 0
    payment_amount: int = 0
    studied_months: int = 0
    total_months: int = 0
    active: bool = True


class UserCreate(BaseModel):
    full_name: str
    login: str
    password: str = Field(min_length=4)
    role: str
    sector: str | None = None
    department_id: str | None = None
    position: str | None = None
    email: str | None = None
    phone: str | None = None
    group_id: str | None = None
    direction: str | None = None
    salary: int = 0
    payment_amount: int = 0
    studied_months: int = 0
    total_months: int = 0


class UserUpdate(BaseModel):
    full_name: str | None = None
    login: str | None = None
    password: str | None = None
    role: str | None = None
    sector: str | None = None
    department_id: str | None = None
    position: str | None = None
    email: str | None = None
    phone: str | None = None
    group_id: str | None = None
    direction: str | None = None
    salary: int | None = None
    payment_amount: int | None = None
    studied_months: int | None = None
    total_months: int | None = None


class LoginCheck(BaseModel):
    taken: bool


# --- Tasks ---
class TaskOut(OrmModel):
    id: str
    title: str
    description: str
    assignee_id: str
    created_by_id: str
    status: str
    priority: str
    project_id: str | None = None
    created_at: datetime


class TaskCreate(BaseModel):
    title: str
    description: str = ""
    assignee_id: str
    priority: str = "orta"
    project_id: str | None = None


class TaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    assignee_id: str | None = None
    priority: str | None = None
    status: str | None = None
    project_id: str | None = None


class TaskStatusUpdate(BaseModel):
    status: str


# --- Projects ---
class ProjectOut(OrmModel):
    id: str
    name: str
    description: str
    stage: str
    required_budget: int
    investment: int
    expense: int
    sector: str  # a | b | both
    assignee_ids: list[str] = []
    parts: dict[str, str] = {}
    member_positions: dict[str, str] = {}

    @field_validator("assignee_ids", mode="before")
    @classmethod
    def _assignees(cls, v):  # noqa: N805
        return v or []

    @field_validator("parts", "member_positions", mode="before")
    @classmethod
    def _maps(cls, v):  # noqa: N805
        return v or {}


class ProjectCreate(BaseModel):
    name: str
    description: str = ""
    stage: str = "Goya"
    required_budget: int = 0
    investment: int = 0
    expense: int = 0
    sector: str  # a | b | both
    assignee_ids: list[str] = []


class ProjectUpdateBody(BaseModel):
    name: str | None = None
    description: str | None = None
    stage: str | None = None
    required_budget: int | None = None
    investment: int | None = None
    expense: int | None = None
    sector: str | None = None


class ProjectStageUpdate(BaseModel):
    stage: str


class ProjectPartAssign(BaseModel):
    part_name: str
    employee_id: str
    position: str | None = None


class JobTitleOut(OrmModel):
    id: str
    name: str
    active: bool = True


class JobTitleCreate(BaseModel):
    name: str


class JobTitleUpdate(BaseModel):
    name: str | None = None
    active: bool | None = None


class DepartmentStaffAssign(BaseModel):
    user_id: str
    position: str
    make_head: bool = False


class ProjectUpdateOut(OrmModel):
    id: str
    project_id: str
    author_id: str
    title: str
    body: str
    created_at: datetime


class ProjectUpdateCreate(BaseModel):
    title: str
    body: str = ""


# --- Finance ---
class FinanceOut(OrmModel):
    id: str
    title: str
    amount: int
    type: str
    receipt_no: str
    note: str = ""
    related_user_id: str | None = None
    project_id: str | None = None
    created_at: datetime


class FinanceCreate(BaseModel):
    title: str
    amount: int
    type: str
    note: str = ""
    related_user_id: str | None = None
    project_id: str | None = None


class FinanceUpdate(BaseModel):
    title: str | None = None
    amount: int | None = None
    type: str | None = None
    note: str | None = None


class FinanceSummary(BaseModel):
    company_cash: int
    reserve_cash: int
    total_kirim: int
    total_chiqim: int
    total_maosh: int
    records_count: int


# --- Departments ---
class DepartmentOut(OrmModel):
    id: str
    name: str
    sector: str
    head_id: str
    positions: list[str] = []


class DepartmentCreate(BaseModel):
    name: str
    sector: str
    head_id: str
    positions: list[str] = []


class DepartmentUpdate(BaseModel):
    name: str | None = None
    sector: str | None = None
    head_id: str | None = None
    positions: list[str] | None = None


class DepartmentHeadUpdate(BaseModel):
    head_id: str


# --- Education ---
class GroupOut(OrmModel):
    id: str
    name: str
    direction: str
    teacher_id: str
    sector: str | None = None


class GroupCreate(BaseModel):
    name: str
    direction: str
    teacher_id: str
    sector: str | None = None


class AttendanceOut(OrmModel):
    id: str
    group_id: str
    student_id: str
    date: datetime
    present: bool
    grade: int


class AttendanceEntry(BaseModel):
    student_id: str
    present: bool = True
    grade: int = 5


class AttendanceBulk(BaseModel):
    group_id: str
    date: datetime | None = None
    records: list[AttendanceEntry]


class MaterialOut(OrmModel):
    id: str
    group_id: str
    title: str
    type: str
    url_or_note: str = ""


class MaterialCreate(BaseModel):
    group_id: str
    title: str
    type: str
    url_or_note: str = ""


class RankingItem(BaseModel):
    user: UserOut
    average_grade: float


# --- Announcements ---
class AnnouncementOut(OrmModel):
    id: str
    title: str
    body: str
    author_id: str
    audience: str
    created_at: datetime


class AnnouncementCreate(BaseModel):
    title: str
    body: str = ""
    audience: str = "barcha"


class AnnouncementUpdate(BaseModel):
    title: str | None = None
    body: str | None = None
    audience: str | None = None


# --- Dashboard / Bootstrap ---
class DashboardSummary(BaseModel):
    staff_count: int
    active_projects: int
    company_cash: int
    reserve_cash: int
    loaded_employees: list[UserOut]
    unloaded_employees: list[UserOut]
    responded_employees: list[UserOut]
    no_response_employees: list[UserOut]


class BootstrapData(BaseModel):
    users: list[UserOut]
    tasks: list[TaskOut]
    projects: list[ProjectOut]
    project_updates: list[ProjectUpdateOut]
    finances: list[FinanceOut]
    departments: list[DepartmentOut]
    job_titles: list[JobTitleOut] = []
    groups: list[GroupOut]
    attendance: list[AttendanceOut]
    materials: list[MaterialOut]
    announcements: list[AnnouncementOut]
    company_cash: int
    reserve_cash: int
    me: UserOut


class MessageOut(BaseModel):
    message: str
    detail: Any | None = None
