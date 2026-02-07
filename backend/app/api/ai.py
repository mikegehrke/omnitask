"""
AI Test Endpoint - REAL Ollama Integration
"""
from fastapi import APIRouter
from pydantic import BaseModel
from app.core.ollama_client import ollama


router = APIRouter()


class AITestRequest(BaseModel):
    prompt: str


class AITestResponse(BaseModel):
    prompt: str
    response: str
    model: str


@router.post("/test", response_model=AITestResponse)
async def ai_test(request: AITestRequest):
    """
    Test endpoint for real Ollama AI.
    NO MOCKS. NO SLEEP. REAL LLM.
    
    Example:
    curl -X POST http://localhost:8000/api/ai/test \
      -H "Content-Type: application/json" \
      -d '{"prompt":"What is 2+2?"}'
    """
    response_text = await ollama.generate(
        prompt=request.prompt,
        system="You are a helpful AI assistant. Be concise."
    )
    
    return AITestResponse(
        prompt=request.prompt,
        response=response_text,
        model=ollama.model
    )


@router.post("/analyze-task")
async def analyze_task(request: AITestRequest):
    """
    Real task analysis using Ollama.
    This replaces the mock TriageAgent.
    """
    system_prompt = """You are a task analysis AI.
Analyze the given task and return:
1. Complexity (1-5)
2. Category (general/technical/creative/etc)
3. Whether it needs user clarification (yes/no)

Be concise and structured."""

    response_text = await ollama.generate(
        prompt=f"Analyze this task: {request.prompt}",
        system=system_prompt
    )
    
    return {
        "task": request.prompt,
        "analysis": response_text,
        "model": ollama.model
    }
