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
    
    - User can send text messages or file attachments
    - Text files (.txt, .md) are processed by AI immediately
    - Images/PDFs are stored but AI processing pending (Phase 2: Vision API)
    - AI responds based on task context
    """
    import httpx
    import os
    
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
    
    # Determine if file has AI support
    ai_supported_types = ['text', 'txt', 'md', 'markdown']
    file_has_ai_support = False
    file_content_for_ai = None
    
    # If file is attached, check if we can process it with AI
    if message_data.file_url:
        file_type = message_data.file_type or ''
        file_name = message_data.file_name or ''
        file_ext = file_name.split('.')[-1].lower() if '.' in file_name else ''
        
        # Check if this file type supports AI processing
        if file_ext in ai_supported_types or file_type == 'text':
            file_has_ai_support = True
            # Load file content for AI
            try:
                backend_url = os.getenv('BACKEND_URL', 'http://localhost:8000')
                file_full_url = f"{backend_url}{message_data.file_url}"
                async with httpx.AsyncClient() as client:
                    response = await client.get(file_full_url)
                    if response.status_code == 200:
                        file_content_for_ai = response.text
            except Exception as e:
                print(f"Warning: Could not load file content: {e}")
    
    # Build content for user message
    user_content = message_data.content or ""
    if message_data.file_url and not file_has_ai_support:
        # File attached but no AI support yet
        user_content += f"\n\n[Datei hochgeladen: {message_data.file_name}]"
    elif file_content_for_ai:
        # Text file - include content for AI
        user_content += f"\n\n--- Inhalt von {message_data.file_name} ---\n{file_content_for_ai}\n--- Ende ---"
    
    # Save user message
    user_message = Message(
        task_id=task_id,
        role="user",
        content=user_content or None,
        file_url=message_data.file_url,
        file_name=message_data.file_name,
        file_type=message_data.file_type,
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
