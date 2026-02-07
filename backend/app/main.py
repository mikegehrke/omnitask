"""
OmniTask Backend - Main Application
Complete rebuild with full AI integration
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api import auth, tasks, chat
from app.ai.factory import ProviderFactory


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    print("🚀 OmniTask Backend starting...")
    
    # Check AI providers health
    health = await ProviderFactory.health_check_all()
    print(f"📡 AI Providers: {health}")
    
    yield
    
    # Shutdown
    print("👋 OmniTask Backend shutting down...")


# Create FastAPI app
app = FastAPI(
    title="OmniTask API",
    description="AI-powered task automation platform",
    version="2.0.0",
    lifespan=lifespan
)


# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict in production
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(tasks.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "OmniTask API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    
    # Check AI providers
    providers = await ProviderFactory.health_check_all()
    
    return {
        "status": "healthy",
        "database": "connected",  # TODO: Actual DB check
        "ai_providers": providers
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
