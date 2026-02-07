"""
Real Ollama LLM Client - NO MOCKS
"""
import httpx
from typing import Optional, Dict, Any
from app.core.config import settings


class OllamaClient:
    def __init__(self, base_url: str = None):
        self.base_url = base_url or settings.OLLAMA_BASE_URL
        self.model = settings.OLLAMA_MODEL
    
    async def generate(
        self,
        prompt: str,
        system: Optional[str] = None,
        temperature: float = 0.7
    ) -> str:
        """
        Call Ollama API and return response text.
        NO SIMULATION. REAL API CALL.
        """
        payload: Dict[str, Any] = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature
            }
        }
        
        if system:
            payload["system"] = system
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{self.base_url}/api/generate",
                json=payload
            )
            response.raise_for_status()
            data = response.json()
            return data.get("response", "").strip()
    
    async def chat(
        self,
        messages: list,
        temperature: float = 0.7
    ) -> str:
        """
        Chat API for multi-turn conversations.
        """
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature
            }
        }
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{self.base_url}/api/chat",
                json=payload
            )
            response.raise_for_status()
            data = response.json()
            message = data.get("message", {})
            return message.get("content", "").strip()


# Global singleton
ollama_client = OllamaClient()
