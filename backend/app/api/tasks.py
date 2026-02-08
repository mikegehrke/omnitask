"""
Task API endpoints
Core business logic for task management
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List

from app.db.base import get_db
from app.db.models import User, Task
from app.schemas import TaskCreate, TaskResponse, TaskDetail, PriceEstimate
from app.core.security import get_current_user
from app.billing.pricing import calculate_task_price, estimate_tokens


router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.post("/estimate-price", response_model=PriceEstimate)
async def estimate_price(
    task_data: TaskCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Estimate price for a task before creation
    
    - Analyzes task description
    - Estimates token usage
    - Calculates price with urgency multiplier
    """
    
    # Estimate tokens needed
    estimated_tokens = estimate_tokens(task_data.description)
    
    # Calculate price
    price_info = calculate_task_price(
        description=task_data.description,
        urgency=task_data.urgency.value,
        provider=task_data.provider.value,
        estimated_tokens=estimated_tokens
    )
    
    return PriceEstimate(
        base_cost=price_info["base_cost"],
        urgency_multiplier=price_info["urgency_multiplier"],
        urgency_fee=price_info["urgency_fee"],
        provider_cost=price_info["provider_cost"],
        total_price=price_info["total_price"],
        currency=price_info["currency"],
        estimated_tokens=estimated_tokens
    )


@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_data: TaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new task
    
    PAYMENT-FLOW (KRITISCH):
    1. Task wird mit Status 'awaiting_payment' erstellt
    2. Preis wird dem User angezeigt
    3. User muss zahlen/bestätigen
    4. ERST DANN wird Task zur Ausführung freigegeben (POST /tasks/{id}/confirm)
    
    WICHTIG: Kein Output/Execution vor Payment!
    """
    
    # Estimate cost
    estimated_tokens = estimate_tokens(task_data.description)
    price_info = calculate_task_price(
        description=task_data.description,
        urgency=task_data.urgency.value,
        provider=task_data.provider.value,
        estimated_tokens=estimated_tokens
    )
    
    estimated_cost = price_info["total_price"]
    
    # Check if user has enough credits/limit (vorab-prüfung)
    if current_user.plan == "free":
        if current_user.monthly_usage + estimated_cost > current_user.monthly_limit:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED,
                detail=f"Monthly limit exceeded. Upgrade your plan or wait for next month."
            )
    
    if current_user.credits_balance < estimated_cost:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=f"Insufficient credits. Need ${estimated_cost:.2f}, have ${current_user.credits_balance:.2f}"
        )
    
    # Create task mit STATUS awaiting_payment
    # Task wird NICHT sofort ausgeführt!
    new_task = Task(
        user_id=current_user.id,
        description=task_data.description,
        urgency=task_data.urgency.value,
        provider=task_data.provider.value,
        status="awaiting_payment",  # KRITISCH: Nicht "pending"!
        estimated_cost=estimated_cost
    )
    
    db.add(new_task)
    await db.commit()
    await db.refresh(new_task)
    
    # KEIN ENQUEUE! Task wartet auf Payment/Bestätigung
    
    return new_task


@router.get("/", response_model=List[TaskResponse])
async def get_tasks(
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all tasks for current user
    
    - Returns tasks ordered by creation date (newest first)
    - Supports pagination
    """
    
    result = await db.execute(
        select(Task)
        .where(Task.user_id == current_user.id)
        .order_by(desc(Task.created_at))
        .offset(skip)
        .limit(limit)
    )
    
    tasks = result.scalars().all()
    return tasks


@router.get("/{task_id}", response_model=TaskDetail)
async def get_task(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get specific task details
    
    - Returns full task info including plan and analysis
    - Only owner can access
    """
    
    result = await db.execute(
        select(Task).where(
            Task.id == task_id,
            Task.user_id == current_user.id
        )
    )
    
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a task
    
    - Only owner can delete
    - Cannot delete running tasks
    """
    
    result = await db.execute(
        select(Task).where(
            Task.id == task_id,
            Task.user_id == current_user.id
        )
    )
    
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.status in ["analyzing", "planning", "executing"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete running task. Cancel it first."
        )
    
    await db.delete(task)
    await db.commit()
    
    return None


@router.post("/{task_id}/cancel", response_model=TaskResponse)
async def cancel_task(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Cancel a running task
    
    - Stops execution
    - Refunds unused credits
    """
    
    result = await db.execute(
        select(Task).where(
            Task.id == task_id,
            Task.user_id == current_user.id
        )
    )
    
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.status in ["completed", "failed", "cancelled"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Task already finished"
        )
    
    # Cancel task
    task.status = "cancelled"
    
    # Refund if not started
    if task.final_cost == 0:
        current_user.credits_balance += task.estimated_cost
        current_user.monthly_usage -= task.estimated_cost
    
    await db.commit()
    await db.refresh(task)
    
    return task


@router.post("/{task_id}/confirm", response_model=TaskResponse)
async def confirm_task_payment(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Bestätigt Zahlung und startet Task-Ausführung
    
    PAYMENT-FLOW Schritt 2:
    1. Prüft ob Task in 'awaiting_payment' Status
    2. Zieht estimated_cost von User Credits ab
    3. Setzt Status auf 'pending'
    4. Enqueued Task zur Worker-Ausführung
    
    User muss VOR diesem Call AGB akzeptiert haben!
    """
    
    result = await db.execute(
        select(Task).where(
            Task.id == task_id,
            Task.user_id == current_user.id
        )
    )
    
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.status != "awaiting_payment":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Task status is {task.status}, expected awaiting_payment"
        )
    
    # Final check: Hat User genug Credits?
    if current_user.credits_balance < task.estimated_cost:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=f"Insufficient credits"
        )
    
    # Geld abziehen (WICHTIG!)
    current_user.credits_balance -= task.estimated_cost
    current_user.monthly_usage += task.estimated_cost
    
    # Status auf pending setzen
    task.status = "pending"
    
    await db.commit()
    await db.refresh(task)
    
    # JETZT Task in Queue stellen
    from arq import create_pool
    from arq.connections import RedisSettings
    import os
    
    try:
        redis = await create_pool(
            RedisSettings(
                host=os.getenv("REDIS_HOST", "redis"),
                port=int(os.getenv("REDIS_PORT", "6379"))
            )
        )
        await redis.enqueue_job('process_task', task.id)
        await redis.close()
        print(f"✅ Task {task.id} payment confirmed, enqueued to worker")
    except Exception as e:
        print(f"⚠️ Failed to enqueue task {task.id}: {e}")
    
    return task
