from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "MID API"
    api_prefix: str = "/api/v1"
    secret_key: str = "mid-dev-secret-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7
    database_url: str = "sqlite:///./mid.db"
    cors_origins: list[str] = [
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8080",
        "*",
    ]


settings = Settings()
