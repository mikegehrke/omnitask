"""
Base AI Provider Interface
All AI providers must implement this interface
"""
from abc import ABC, abstractmethod
from typing import AsyncGenerator, List, Dict, Any, Optional
from dataclasses import dataclass


@dataclass
class AIMessage:
    """Standard message format"""
    role: str  # user, assistant, system
    content: str


@dataclass
class AIResponse:
    """Standard AI response"""
    content: str
    tokens_used: int
    cost: float
    model: str
    provider: str


class AIProvider(ABC):
    """Base class for all AI providers"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key
        self.name = "base"
    
    @abstractmethod
    async def chat_completion(
        self,
        messages: List[AIMessage],
        stream: bool = False,
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> AIResponse | AsyncGenerator[str, None]:
        """
        Send chat completion request
        
        Args:
            messages: List of messages
            stream: Whether to stream response
            model: Specific model to use
            temperature: Creativity (0-1)
            max_tokens: Max response length
            
        Returns:
            AIResponse or AsyncGenerator for streaming
        """
        pass
    
    @abstractmethod
    def calculate_cost(
        self,
        input_tokens: int,
        output_tokens: int,
        model: str
    ) -> float:
        """
        Calculate cost for token usage
        
        Args:
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens
            model: Model name
            
        Returns:
            Cost in USD
        """
        pass
    
    @abstractmethod
    def count_tokens(self, text: str, model: str) -> int:
        """
        Count tokens in text
        
        Args:
            text: Text to count
            model: Model for tokenization
            
        Returns:
            Number of tokens
        """
        pass
    
    @abstractmethod
    async def health_check(self) -> bool:
        """
        Check if provider is available
        
        Returns:
            True if healthy, False otherwise
        """
        pass
    
    def get_default_model(self) -> str:
        """Get default model for this provider"""
        return "default"
    
    def get_available_models(self) -> List[str]:
        """Get list of available models"""
        return [self.get_default_model()]
