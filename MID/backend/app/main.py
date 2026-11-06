from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.routers import (
    announcements,
    auth,
    dashboard,
    departments,
    education,
    finance,
    positions,
    projects,
    tasks,
    users,
)
from app.seed import (
    ensure_job_titles,
    ensure_schema,
    reconcile_company_cash,
    seed_if_empty,
)


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine, checkfirst=True)
    ensure_schema(engine)
    db = SessionLocal()
    try:
        seed_if_empty(db)
        ensure_job_titles(db)
        reconcile_company_cash(db)
    finally:
        db.close()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)

_origins = settings.cors_origin_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

prefix = settings.api_prefix
app.include_router(auth.router, prefix=prefix)
app.include_router(users.router, prefix=prefix)
app.include_router(tasks.router, prefix=prefix)
app.include_router(projects.router, prefix=prefix)
app.include_router(finance.router, prefix=prefix)
app.include_router(departments.router, prefix=prefix)
app.include_router(positions.router, prefix=prefix)
app.include_router(education.router, prefix=prefix)
app.include_router(announcements.router, prefix=prefix)
app.include_router(dashboard.router, prefix=prefix)


@app.get("/")
def root() -> dict:
    return {
        "name": settings.app_name,
        "docs": "/docs",
        "api": prefix,
    }


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
