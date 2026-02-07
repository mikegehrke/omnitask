"""
Task Executor
Executes the plan and generates results
"""
from typing import Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from app.ai.base import AIProvider, AIMessage
from app.db.models import Task, User
import json


EXECUTION_PROMPT = """You are an expert task executor. Execute this plan and deliver the result.

ORIGINAL REQUEST: {description}

PLAN:
{plan}

User's language: {language}

Execute ALL steps in the plan and provide the final result.
Be thorough, accurate, and deliver exactly what was requested.

Output the result in the format specified in the plan."""


async def execute_plan(
    plan: Dict[str, Any],
    provider: AIProvider,
    task: Task,
    user: User,
    db: AsyncSession
) -> Dict[str, Any]:
    """
    Execute the task plan and generate results
    
    Args:
        plan: Execution plan from planner
        provider: AI provider
        task: Task object
        user: User object
        db: Database session
        
    Returns:
        Dict with results:
        - text: Generated text
        - files: List of file IDs (if any)
        - total_cost: Total cost incurred
        - total_tokens: Total tokens used
    """
    
    # Build execution prompt
    prompt = EXECUTION_PROMPT.format(
        description=task.description,
        plan=json.dumps(plan, indent=2),
        language=user.output_language
    )
    
    messages = [
        AIMessage(role="system", content="You are an expert executor."),
        AIMessage(role="user", content=prompt)
    ]
    
    # Execute with AI
    response = await provider.chat_completion(
        messages=messages,
        temperature=0.7,
        max_tokens=4000  # Allow longer responses
    )
    
    # Calculate costs
    total_cost = response.cost
    total_tokens = response.tokens_used
    
    # Prepare result
    result = {
        "text": response.content,
        "files": [],  # TODO: File generation
        "total_cost": total_cost,
        "total_tokens": total_tokens,
        "provider_used": provider.name,
        "model_used": response.model
    }
    
    # Save execution message to database
    from app.agents.task_manager import save_message
    await save_message(
        task_id=task.id,
        role="assistant",
        content=response.content,
        tokens=total_tokens,
        cost=total_cost,
        provider=provider.name,
        db=db
    )
    
    return result
