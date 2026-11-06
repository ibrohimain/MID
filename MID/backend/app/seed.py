from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import (
    Announcement,
    AppBalance,
    AttendanceRecord,
    Department,
    FinanceRecord,
    Project,
    ProjectUpdate,
    StudyGroup,
    StudyMaterial,
    Task,
    User,
)
from app.security import hash_password


def _user(**kwargs) -> User:
    plain = kwargs.pop("password")
    return User(password_hash=hash_password(plain), password_plain=plain, **kwargs)


def seed_if_empty(db: Session) -> None:
    if db.scalar(select(User).limit(1)):
        return

    director = _user(
        id="u-dir",
        full_name="Aziza Karimova",
        login="direktor",
        password="1234",
        role="direktor",
        position="Direktor",
        email="direktor@mid.uz",
        salary=25_000_000,
    )
    rahbar_a = _user(
        id="u-ra",
        full_name="Bekzod Tursunov",
        login="rahbar_a",
        password="a12345",
        role="rahbar",
        sector="a",
        position="A sektor rahbari",
        email="rahbar.a@mid.uz",
        phone="+998 90 111 22 33",
        salary=18_000_000,
    )
    rahbar_b = _user(
        id="u-rb",
        full_name="Nilufar Saidova",
        login="rahbar_b",
        password="b12345",
        role="rahbar",
        sector="b",
        position="B sektor rahbari",
        email="rahbar.b@mid.uz",
        phone="+998 90 444 55 66",
        salary=18_000_000,
    )

    dept_a1 = Department(
        id="d-a1",
        name="Loyihalar",
        sector="a",
        head_id=rahbar_a.id,
        positions=["Loyiha menejeri", "Product owner", "Analitik"],
    )
    dept_a2 = Department(
        id="d-a2",
        name="O'quv",
        sector="a",
        head_id=rahbar_a.id,
        positions=["Mentor", "O'qituvchi", "Kurator"],
    )
    dept_b1 = Department(
        id="d-b1",
        name="Moliya",
        sector="b",
        head_id=rahbar_b.id,
        positions=["Moliyaviy analitik", "Buxgalter", "Investitsiya menejeri"],
    )
    dept_b2 = Department(
        id="d-b2",
        name="HR",
        sector="b",
        head_id=rahbar_b.id,
        positions=["HR mutaxassisi", "Rekruter"],
    )

    jasur = _user(
        id="u-x1",
        full_name="Jasur Aliyev",
        login="jasur",
        password="1234",
        role="xodim",
        sector="a",
        department_id=dept_a1.id,
        position="Loyiha menejeri",
        salary=9_000_000,
    )
    dilshod = _user(
        id="u-x2",
        full_name="Dilshod Normatov",
        login="dilshod",
        password="1234",
        role="xodim",
        sector="a",
        department_id=dept_a2.id,
        position="Mentor",
        salary=8_000_000,
    )
    malika = _user(
        id="u-x3",
        full_name="Malika Ergasheva",
        login="malika",
        password="1234",
        role="xodim",
        sector="b",
        department_id=dept_b1.id,
        position="Moliyaviy analitik",
        salary=8_500_000,
    )
    odil = _user(
        id="u-x4",
        full_name="Odil Hasanov",
        login="odil",
        password="1234",
        role="xodim",
        sector="b",
        department_id=dept_b2.id,
        position="HR mutaxassisi",
        salary=7_000_000,
    )

    g_flutter = StudyGroup(
        id="g-1",
        name="Flutter-01",
        direction="Flutter",
        teacher_id=dilshod.id,
        sector="a",
    )
    g_ux = StudyGroup(
        id="g-2",
        name="UIUX-02",
        direction="UI/UX",
        teacher_id=dilshod.id,
        sector="a",
    )

    madina = _user(
        id="u-o1",
        full_name="Madina Yusupova",
        login="madina",
        password="1234",
        role="oquvchi",
        sector="a",
        group_id=g_flutter.id,
        direction="Flutter",
        payment_amount=3_500_000,
        studied_months=4,
        total_months=9,
    )
    sardor = _user(
        id="u-s1",
        full_name="Sardor Rahimov",
        login="sardor",
        password="1234",
        role="shogirt",
        sector="a",
        group_id=g_flutter.id,
        direction="Flutter",
        payment_amount=0,
        studied_months=2,
        total_months=6,
    )
    dilnoza = _user(
        id="u-o2",
        full_name="Dilnoza Ergasheva",
        login="dilnoza",
        password="1234",
        role="oquvchi",
        sector="a",
        group_id=g_ux.id,
        direction="UI/UX",
        payment_amount=3_000_000,
        studied_months=3,
        total_months=8,
    )

    projects = [
        Project(
            id="p-1",
            name="EduLink",
            description="Ta'lim platformasi MVP va mentor marketplace.",
            stage="MVP",
            required_budget=150_000_000,
            investment=120_000_000,
            expense=48_000_000,
            sector="a",
            assignee_ids=[jasur.id, sardor.id],
            parts={"Frontend": jasur.id, "Amaliyot": sardor.id},
        ),
        Project(
            id="p-2",
            name="PayNest",
            description="To'lov va investitsiya kuzatuv tizimi.",
            stage="Growth",
            required_budget=250_000_000,
            investment=210_000_000,
            expense=96_000_000,
            sector="b",
            assignee_ids=[malika.id],
            parts={"Moliya moduli": malika.id},
        ),
        Project(
            id="p-3",
            name="AgroSense",
            description="Agro sensor monitoring startup.",
            stage="Boshlanish",
            required_budget=100_000_000,
            investment=85_000_000,
            expense=12_000_000,
            sector="a",
            assignee_ids=[],
            parts={},
        ),
    ]

    tasks = [
        Task(
            id="t-1",
            title="Pitch deck yangilash",
            description="EduLink investorlar uchun deck.",
            assignee_id=jasur.id,
            created_by_id=rahbar_a.id,
            status="jarayonda",
            priority="yuqori",
            project_id="p-1",
        ),
        Task(
            id="t-2",
            title="Haftalik moliya hisoboti",
            description="Kirim-chiqim va zaxira.",
            assignee_id=malika.id,
            created_by_id=rahbar_b.id,
            status="javobBerildi",
            priority="yuqori",
            project_id="p-2",
        ),
        Task(
            id="t-3",
            title="Yangi mentor sessiyasi",
            description="Flutter-01 guruhiga sessiya.",
            assignee_id=dilshod.id,
            created_by_id=rahbar_a.id,
            status="yangi",
            priority="orta",
        ),
    ]

    finances = [
        FinanceRecord(
            id="f-1",
            title="Investitsiya — EduLink",
            amount=120_000_000,
            type="kirim",
            receipt_no="CHK-2026-1",
            project_id="p-1",
        ),
        FinanceRecord(
            id="f-2",
            title="Ofis ijarasi",
            amount=25_000_000,
            type="chiqim",
            receipt_no="CHK-2026-2",
        ),
        FinanceRecord(
            id="f-3",
            title="Maosh — Jasur Aliyev",
            amount=9_000_000,
            type="maosh",
            receipt_no="CHK-2026-3",
            related_user_id=jasur.id,
        ),
        FinanceRecord(
            id="f-4",
            title="Zaxira fondiga ajratish",
            amount=80_000_000,
            type="zaxira",
            receipt_no="CHK-2026-4",
            note="Yillik zaxira",
        ),
        FinanceRecord(
            id="f-5",
            title="Marketing budjeti",
            amount=15_000_000,
            type="ajratma",
            receipt_no="CHK-2026-5",
        ),
    ]

    yesterday = datetime.utcnow() - timedelta(days=1)
    attendance = [
        AttendanceRecord(
            id="a-1",
            group_id=g_flutter.id,
            student_id=madina.id,
            date=yesterday,
            present=True,
            grade=9,
        ),
        AttendanceRecord(
            id="a-2",
            group_id=g_flutter.id,
            student_id=sardor.id,
            date=yesterday,
            present=True,
            grade=8,
        ),
        AttendanceRecord(
            id="a-3",
            group_id=g_ux.id,
            student_id=dilnoza.id,
            date=yesterday,
            present=True,
            grade=10,
        ),
    ]

    materials = [
        StudyMaterial(
            id="m-1",
            group_id=g_flutter.id,
            title="Widget tree asoslari",
            type="darslik",
            url_or_note="pdf/flutter-widgets.pdf",
        ),
        StudyMaterial(
            id="m-2",
            group_id=g_flutter.id,
            title="Uy vazifa #4",
            type="uyVazifa",
            url_or_note="ListView + model",
        ),
        StudyMaterial(
            id="m-3",
            group_id=g_ux.id,
            title="Figma prototip video",
            type="video",
            url_or_note="https://mid.uz/video/figma-01",
        ),
    ]

    updates = [
        ProjectUpdate(
            id="pu-1",
            project_id="p-1",
            author_id=director.id,
            title="MVP demo tayyor",
            body="EduLink asosiy oqimlar sinovdan o'tdi. Keyingi qadam — investor demo.",
        )
    ]

    announcements = [
        Announcement(
            id="an-1",
            title="Haftalik yig'ilish",
            body="Juma soat 16:00 da barcha xodimlar uchun yig'ilish.",
            author_id=director.id,
            audience="xodimlar",
        ),
        Announcement(
            id="an-2",
            title="Amaliyot yangiligi",
            body="Shogirtlar uchun yangi mentor sessiyasi dushanba kuni.",
            author_id=rahbar_a.id,
            audience="shogirtlar",
        ),
        Announcement(
            id="an-3",
            title="Umumiy e'lon",
            body="MID tizimida yangi funksiyalar yoqildi — profil va e'lonlar.",
            author_id=director.id,
            audience="barcha",
        ),
    ]

    balance = AppBalance(
        id=1,
        company_cash=420_000_000,
        reserve_cash=80_000_000,
        seq=200,
    )

    # Departments first (no FK from users yet for dept), then groups without users FK issue
    # User.department_id / group_id are nullable FKs — insert order:
    # departments, study_groups (teacher ids exist after users), users need groups...
    # Study groups reference teacher_id as plain string (no FK). User.group_id FK to study_groups.
    # So: departments → users without group → groups → update/add learners with group
    # Simpler: make sure groups are added before learners who reference them.

    staff_users = [director, rahbar_a, rahbar_b, jasur, dilshod, malika, odil]
    learner_users = [madina, sardor, dilnoza]

    db.add(balance)
    db.add_all([dept_a1, dept_a2, dept_b1, dept_b2])
    db.add_all(staff_users)
    db.flush()
    db.add_all([g_flutter, g_ux])
    db.flush()
    db.add_all(learner_users)
    db.add_all(projects)
    db.add_all(tasks)
    db.add_all(finances)
    db.add_all(attendance)
    db.add_all(materials)
    db.add_all(updates)
    db.add_all(announcements)
    db.commit()
