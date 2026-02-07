"""
Real Ollama AI Client - No Mocks
"""
import httpx
from typing import Optional


class OllamaClient:
    def __init__(self, base_url: str = "http://ollama:11434"):
        self.base_url = base_url
        self.model = "llama3.2"

    async def generate(
        self,
        prompt: str,
        system: Optional[str] = None
    ) -> str:
        """
        Call Ollama API and return the generated text.
        This is REAL. No mocks.
        """
        url = f"{self.base_url}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False
        }
        
        if system:
            payload["system"] = system
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data.get("response", "")

    async def chat(
        self,
        messages: list[dict],
    ) -> str:
        """
        Chat endpoint - supports conversation history
        """
        url = f"{self.base_url}/api/chat"
        
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False
        }
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data.get("message", {}).get("content", "")


# Global singleton
ollama = OllamaClient()
