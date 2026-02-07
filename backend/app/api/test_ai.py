from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.llm import llm

router = APIRouter()

class TestRequest(BaseModel):
    prompt: str
    model: str = "llama3"

class TestResponse(BaseModel):
    response: str
    provider: str

@router.post("/test", response_model=TestResponse)
async def test_ai_generation(request: TestRequest):
    """
    PROOF OF LIFE ENDPOINT.
    Calls the real AI core and returns the result.
    """
    try:
        result = await llm.generate(request.prompt, request.model)
        return TestResponse(
            response=result,
            provider=llm.provider
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
