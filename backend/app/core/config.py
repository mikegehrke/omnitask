from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "OmniTask"
    API_V1_STR: str = "/api/v1"
    
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "omnitask"
    POSTGRES_HOST: str = "db"
    POSTGRES_PORT: int = 5432
    
    REDIS_URL: str = "redis://redis:6379/0"
    
    # AI API Keys (loaded from environment variables)
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    GOOGLE_API_KEY: str = ""
    GITHUB_TOKEN: str = ""
    
    STRIPE_SECRET_KEY: str = ""
    
    # Ollama Settings
    OLLAMA_BASE_URL: str = "http://ollama:11434"
    OLLAMA_MODEL: str = "tinyllama"

    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:"
            f"{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:"
            f"{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    class Config:
        env_file = ".env"


settings = Settings()
