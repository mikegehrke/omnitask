"""
Background Worker for Task Processing
Uses ARQ for async task queue
"""
import asyncio
from arq.connections import RedisSettings
from app.db.base import AsyncSessionLocal
from app.db.models import Task
from app.agents.task_manager import execute_task_async
from sqlalchemy import select
import os


async def startup(ctx):
    """Worker startup"""
    print("🚀 OmniTask Worker starting up...")


async def shutdown(ctx):
    """Worker shutdown"""
    print("👋 OmniTask Worker shutting down...")


async def process_task(ctx, task_id: int):
    """
    Process a task through the complete lifecycle
    
    Args:
        ctx: ARQ context
        task_id: Task ID to process
    """
    print(f"📋 Processing task {task_id}...")
    
    try:
        await execute_task_async(task_id)
        print(f"✅ Task {task_id} completed successfully")
    except Exception as e:
        print(f"❌ Task {task_id} failed: {e}")
        
        # Mark task as failed
        async with AsyncSessionLocal() as db:
            result = await db.execute(select(Task).where(Task.id == task_id))
            task = result.scalar_one_or_none()
            
            if task:
                task.status = "failed"
                task.error_message = str(e)
                await db.commit()


class WorkerSettings:
    """ARQ Worker Settings"""
    
    functions = [process_task]
    
    redis_settings = RedisSettings(
        host=os.getenv("REDIS_HOST", "redis"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        database=0
    )
    
    on_startup = startup
    on_shutdown = shutdown
    
    # Worker configuration
    max_jobs = 10
    job_timeout = 600  # 10 minutes (for Ollama)
    keep_result = 3600  # Keep results for 1 hour
