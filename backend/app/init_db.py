"""
Database initialization script
Imports all models and creates tables
"""
import asyncio
from app.db.base import engine, Base, AsyncSessionLocal
# Import ALL models so they are registered with Base.metadata
from app.db.models import (
    User, Task, Message, Payment, File, Automation, SystemLog
)


async def init_and_create_admin():
    """Initialize database and create admin user"""
    # Create tables
    async with engine.begin() as conn:
        # Drop all tables
        await conn.run_sync(Base.metadata.drop_all)
        # Create all tables
        await conn.run_sync(Base.metadata.create_all)
    print("✅ Database tables created successfully")
    
    # Create admin user
    from app.core.security import get_password_hash
    
    async with AsyncSessionLocal() as session:
        # Check if admin exists
        from sqlalchemy import select
        result = await session.execute(
            select(User).where(User.email == "admin@omnitask.ai")
        )
        existing = result.scalar_one_or_none()
        
        if not existing:
            admin = User(
                email="admin@omnitask.ai",
                hashed_password=get_password_hash("admin123"),
                full_name="Admin User",
                plan="unlimited",
                is_admin=True,
                is_verified=True,
                is_active=True,
                credits_balance=1000.0,
                monthly_limit=10000.0
            )
            session.add(admin)
            await session.commit()
            print("✅ Admin user created: admin@omnitask.ai / admin123")
        else:
            print("ℹ️  Admin user already exists")


if __name__ == "__main__":
    asyncio.run(init_and_create_admin())
