"""
Chat API endpoints for task interaction
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.db.base import get_db
from app.db.models import User, Task, Message
from app.schemas import MessageCreate, MessageResponse
from app.core.security import get_current_user
from app.ai.factory import get_ai_provider
from app.ai.base import AIMessage


router = APIRouter(prefix="/tasks/{task_id}/chat", tags=["chat"])


@router.get("/", response_model=List[MessageResponse])
async def get_messages(
    task_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all messages for a task"""
    
    # Verify task ownership
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
    
    # Get messages
    result = await db.execute(
        select(Message)
        .where(Message.task_id == task_id)
        .order_by(Message.created_at)
    )
    
    messages = result.scalars().all()
    return messages


@router.post("/", response_model=MessageResponse)
async def send_message(
    task_id: int,
    message_data: MessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Send a message in task chat
    
    - User can ask questions or provide clarifications
    - AI responds based on task context
    """
    
    # Verify task ownership
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
    
    # Save user message
    user_message = Message(
        task_id=task_id,
        role="user",
        content=message_data.content,
        tokens_used=0,
        cost=0.0
    )
    db.add(user_message)
    await db.commit()
    await db.refresh(user_message)
    
    # Get AI response
    provider = get_ai_provider(task.provider)
    
    # Build conversation history
    result = await db.execute(
        select(Message)
        .where(Message.task_id == task_id)
        .order_by(Message.created_at)
    )
    all_messages = result.scalars().all()
    
    ai_messages = [
        AIMessage(role=msg.role, content=msg.content)
        for msg in all_messages
    ]
    
    # Get AI response
    response = await provider.chat_completion(
        messages=ai_messages,
        temperature=0.7
    )
    
    # Save AI response
    ai_message = Message(
        task_id=task_id,
        role="assistant",
        content=response.content,
        tokens_used=response.tokens_used,
        cost=response.cost,
        provider_used=provider.name
    )
    db.add(ai_message)
    
    # Update task costs
    task.final_cost += response.cost
    task.tokens_used += response.tokens_used
    
    # Deduct from user balance
    current_user.credits_balance -= response.cost
    current_user.monthly_usage += response.cost
    
    await db.commit()
    await db.refresh(ai_message)
    
    return ai_message
