import asyncio
from app.db.base import AsyncSessionLocal
from app.db.models import User


async def create_demo_user():
    async with AsyncSessionLocal() as db:
        user = User(
            email="demo@omnitask.ai",
            hashed_password="hashed_secret",
            is_active=True,
            is_superuser=True
        )
        db.add(user)
        await db.commit()
        print(f"Demo User Created: {user.email}")

if __name__ == "__main__":
    asyncio.run(create_demo_user())
