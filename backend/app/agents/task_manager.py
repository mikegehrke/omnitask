"""
Task Manager - Core execution engine
Orchestrates the complete task lifecycle
"""
import asyncio
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.sql import func

from app.db.base import AsyncSessionLocal
from app.db.models import Task, User, Message
from app.ai.factory import get_ai_provider, ProviderFactory
from app.ai.base import AIMessage
from app.agents.analyzer import analyze_task
from app.agents.planner import create_plan
from app.agents.executor import execute_plan


async def execute_task_async(task_id: int):
    """
    Execute task in background
    This is the main entry point for task execution
    
    Args:
        task_id: ID of task to execute
    """
    async with AsyncSessionLocal() as db:
        try:
            await execute_task(task_id, db)
        except Exception as e:
            # Handle any unexpected errors
            result = await db.execute(select(Task).where(Task.id == task_id))
            task = result.scalar_one_or_none()
            
            if task:
                task.status = "failed"
                task.error_message = str(e)
                await db.commit()
            
            print(f"Task {task_id} failed: {e}")


async def execute_task(task_id: int, db: AsyncSession):
    """
    Main task execution logic
    
    Phases:
    1. ANALYZING - Understand what user wants
    2. CLARIFYING - Ask questions if needed (optional)
    3. PLANNING - Create execution plan
    4. EXECUTING - Run the plan
    5. COMPLETED - Deliver results
    
    Args:
        task_id: ID of task to execute
        db: Database session
    """
    
    # Load task
    result = await db.execute(select(Task).where(Task.id == task_id))
    task = result.scalar_one_or_none()
    
    if not task:
        return
    
    # Load user
    result = await db.execute(select(User).where(User.id == task.user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        task.status = "failed"
        task.error_message = "User not found"
        await db.commit()
        return
    
    # Get AI provider
    try:
        provider = get_ai_provider(task.provider)
    except Exception as e:
        task.status = "failed"
        task.error_message = f"Provider error: {e}"
        await db.commit()
        return
    
    # ========================================================================
    # PHASE 1: ANALYZING
    # ========================================================================
    task.status = "analyzing"
    task.started_at = func.now()
    await db.commit()
    
    try:
        analysis = await analyze_task(
            description=task.description,
            provider=provider,
            user_language=user.output_language
        )
        
        task.analysis = analysis
        await db.commit()
        
    except Exception as e:
        task.status = "failed"
        task.error_message = f"Analysis failed: {e}"
        await db.commit()
        return
    
    # ========================================================================
    # PHASE 2: CLARIFYING (if needed)
    # ========================================================================
    if analysis.get("needs_clarification", False):
        task.status = "clarifying"
        task.clarification_questions = analysis.get("questions", [])
        await db.commit()
        
        # Wait for user to answer questions
        # This is handled by the chat endpoint
        return
    
    # ========================================================================
    # PHASE 3: PLANNING
    # ========================================================================
    task.status = "planning"
    await db.commit()
    
    try:
        plan = await create_plan(
            description=task.description,
            analysis=analysis,
            provider=provider,
            user_language=user.output_language
        )
        
        task.plan = plan
        await db.commit()
        
    except Exception as e:
        task.status = "failed"
        task.error_message = f"Planning failed: {e}"
        await db.commit()
        return
    
    # ========================================================================
    # PHASE 4: EXECUTING
    # ========================================================================
    task.status = "executing"
    await db.commit()
    
    try:
        result = await execute_plan(
            plan=plan,
            provider=provider,
            task=task,
            user=user,
            db=db
        )
        
        # Update task with results
        task.result_text = result.get("text")
        task.result_files = result.get("files", [])
        task.final_cost = result.get("total_cost", 0.0)
        task.tokens_used = result.get("total_tokens", 0)
        
        # Deduct cost from user
        user.credits_balance -= task.final_cost
        user.monthly_usage += task.final_cost
        
        task.status = "completed"
        task.completed_at = func.now()
        
        await db.commit()
        
    except Exception as e:
        task.status = "failed"
        task.error_message = f"Execution failed: {e}"
        await db.commit()
        
        # Try fallback provider
        tried_providers = [task.provider]
        fallback = await ProviderFactory.get_fallback_provider(
            task.provider,
            tried_providers
        )
        
        if fallback and task.retry_count < 2:
            task.retry_count += 1
            task.provider = fallback.name
            task.status = "pending"
            await db.commit()
            
            # Retry with fallback
            await execute_task(task_id, db)


async def save_message(
    task_id: int,
    role: str,
    content: str,
    tokens: int,
    cost: float,
    provider: str,
    db: AsyncSession
):
    """
    Save a chat message to database
    
    Args:
        task_id: Task ID
        role: Message role (user/assistant/system)
        content: Message content
        tokens: Tokens used
        cost: Cost incurred
        provider: AI provider used
        db: Database session
    """
    message = Message(
        task_id=task_id,
        role=role,
        content=content,
        tokens_used=tokens,
        cost=cost,
        provider_used=provider
    )
    
    db.add(message)
    await db.commit()
