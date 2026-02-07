"""
Ollama Provider Implementation
Free, local AI provider
"""
import os
import aiohttp
from typing import List, Optional, AsyncGenerator
from app.ai.base import AIProvider, AIMessage, AIResponse


class OllamaProvider(AIProvider):
    """Ollama local AI provider"""
    
    def __init__(self, api_key: Optional[str] = None):
        super().__init__(api_key)
        self.base_url = os.getenv("OLLAMA_URL", "http://ollama:11434")
        self.name = "ollama"
        self.default_model = "llama3.2"  # Better JSON compliance than tinyllama
    
    async def chat_completion(
        self,
        messages: List[AIMessage],
        stream: bool = False,
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> AIResponse | AsyncGenerator[str, None]:
        """Send chat completion to Ollama"""
        
        model = model or self.default_model
        
        # Convert messages to Ollama format
        ollama_messages = [
            {"role": msg.role, "content": msg.content}
            for msg in messages
        ]
        
        if stream:
            return self._stream_completion(
                ollama_messages, model, temperature
            )
        else:
            return await self._complete(
                ollama_messages, model, temperature
            )
    
    async def _complete(
        self,
        messages: List[dict],
        model: str,
        temperature: float
    ) -> AIResponse:
        """Non-streaming completion"""
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": False,
                    "options": {"temperature": temperature}
                }
            ) as response:
                data = await response.json()
                
                # DEBUG: Log raw response
                print(f"🔍 Ollama raw response: {data}")
                
                content = data.get("message", {}).get("content", "")
                
                # DEBUG: Log extracted content
                print(f"📝 Extracted content: '{content}'")
                
                # Ollama doesn't return exact token counts
                # Estimate: ~4 chars per token
                estimated_tokens = len(content) // 4
                
                return AIResponse(
                    content=content,
                    tokens_used=estimated_tokens,
                    cost=0.0,  # Free!
                    model=model,
                    provider=self.name
                )
    
    async def _stream_completion(
        self,
        messages: List[dict],
        model: str,
        temperature: float
    ) -> AsyncGenerator[str, None]:
        """Streaming completion"""
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": True,
                    "options": {"temperature": temperature}
                }
            ) as response:
                async for line in response.content:
                    if line:
                        import json
                        try:
                            data = json.loads(line)
                            if "message" in data and "content" in data["message"]:
                                yield data["message"]["content"]
                        except json.JSONDecodeError:
                            continue
    
    def calculate_cost(
        self,
        input_tokens: int,
        output_tokens: int,
        model: str
    ) -> float:
        """Ollama is free"""
        return 0.0
    
    def count_tokens(self, text: str, model: str) -> int:
        """Estimate tokens (4 chars ≈ 1 token)"""
        return len(text) // 4
    
    async def health_check(self) -> bool:
        """Check if Ollama is running"""
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/api/tags") as response:
                    return response.status == 200
        except Exception as e:
            print(f"Ollama health check failed: {e}")
            return False
    
    def get_default_model(self) -> str:
        return self.default_model
    
    def get_available_models(self) -> List[str]:
        return ["llama2", "mistral", "codellama", "phi"]
