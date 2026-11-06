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
    projects,
    tasks,
    users,
)
from app.seed import seed_if_empty


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_if_empty(db)
    finally:
        db.close()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
