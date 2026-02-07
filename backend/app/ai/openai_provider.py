"""
OpenAI Provider Implementation
Supports GPT-4, GPT-3.5-turbo, and other OpenAI models
"""
import os
from typing import List, Optional, AsyncGenerator
from openai import AsyncOpenAI
import tiktoken
from app.ai.base import AIProvider, AIMessage, AIResponse


class OpenAIProvider(AIProvider):
    """OpenAI API provider"""
    
    # Pricing per 1K tokens (USD)
    PRICING = {
        "gpt-4": {"input": 0.03, "output": 0.06},
        "gpt-4-turbo": {"input": 0.01, "output": 0.03},
        "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
        "gpt-3.5-turbo": {"input": 0.0005, "output": 0.0015},
    }
    
    def __init__(self, api_key: Optional[str] = None):
        super().__init__(api_key)
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        self.client = AsyncOpenAI(api_key=self.api_key)
        self.name = "openai"
        self.default_model = "gpt-4o-mini"
    
    async def chat_completion(
        self,
        messages: List[AIMessage],
        stream: bool = False,
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> AIResponse | AsyncGenerator[str, None]:
        """Send chat completion to OpenAI"""
        
        model = model or self.default_model
        
        # Convert messages to OpenAI format
        openai_messages = [
            {"role": msg.role, "content": msg.content}
            for msg in messages
        ]
        
        if stream:
            return self._stream_completion(
                openai_messages, model, temperature, max_tokens
            )
        else:
            return await self._complete(
                openai_messages, model, temperature, max_tokens
            )
    
    async def _complete(
        self,
        messages: List[dict],
        model: str,
        temperature: float,
        max_tokens: Optional[int]
    ) -> AIResponse:
        """Non-streaming completion"""
        
        response = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens
        )
        
        content = response.choices[0].message.content
        input_tokens = response.usage.prompt_tokens
        output_tokens = response.usage.completion_tokens
        total_tokens = response.usage.total_tokens
        
        cost = self.calculate_cost(input_tokens, output_tokens, model)
        
        return AIResponse(
            content=content,
            tokens_used=total_tokens,
            cost=cost,
            model=model,
            provider=self.name
        )
    
    async def _stream_completion(
        self,
        messages: List[dict],
        model: str,
        temperature: float,
        max_tokens: Optional[int]
    ) -> AsyncGenerator[str, None]:
        """Streaming completion"""
        
        stream = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True
        )
        
        async for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content
    
    def calculate_cost(
        self,
        input_tokens: int,
        output_tokens: int,
        model: str
    ) -> float:
        """Calculate cost based on token usage"""
        
        pricing = self.PRICING.get(model, self.PRICING["gpt-4-turbo"])
        
        input_cost = (input_tokens / 1000) * pricing["input"]
        output_cost = (output_tokens / 1000) * pricing["output"]
        
        return round(input_cost + output_cost, 6)
    
    def count_tokens(self, text: str, model: str) -> int:
        """Count tokens using tiktoken"""
        
        try:
            encoding = tiktoken.encoding_for_model(model)
        except KeyError:
            encoding = tiktoken.get_encoding("cl100k_base")
        
        return len(encoding.encode(text))
    
    async def health_check(self) -> bool:
        """Check if OpenAI API is accessible"""
        
        try:
            await self.client.models.list()
            return True
        except Exception as e:
            print(f"OpenAI health check failed: {e}")
            return False
    
    def get_default_model(self) -> str:
        return self.default_model
    
    def get_available_models(self) -> List[str]:
        return list(self.PRICING.keys())
