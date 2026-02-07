"""
AI Provider Factory
Manages provider selection and fallback logic
"""
import os
from typing import Optional, List
from app.ai.base import AIProvider
from app.ai.openai_provider import OpenAIProvider
from app.ai.ollama_provider import OllamaProvider


class ProviderFactory:
    """Factory for creating and managing AI providers"""
    
    _instances = {}
    
    @classmethod
    def get_provider(cls, provider_name: str) -> AIProvider:
        """
        Get AI provider instance
        
        Args:
            provider_name: Name of provider (openai, claude, gemini, ollama, auto)
            
        Returns:
            AIProvider instance
        """
        
        # Handle AUTO selection
        if provider_name == "auto":
            provider_name = cls._select_best_provider()
        
        # Return cached instance if exists
        if provider_name in cls._instances:
            return cls._instances[provider_name]
        
        # Create new instance
        provider = cls._create_provider(provider_name)
        cls._instances[provider_name] = provider
        return provider
    
    @classmethod
    def _create_provider(cls, provider_name: str) -> AIProvider:
        """Create provider instance"""
        
        providers = {
            "openai": lambda: OpenAIProvider(os.getenv("OPENAI_API_KEY")),
            "ollama": lambda: OllamaProvider(),
            # TODO: Add Claude and Gemini when implemented
            # "claude": lambda: ClaudeProvider(os.getenv("ANTHROPIC_API_KEY")),
            # "gemini": lambda: GeminiProvider(os.getenv("GOOGLE_API_KEY")),
        }
        
        if provider_name not in providers:
            print(f"Warning: Provider '{provider_name}' not found, falling back to ollama")
            provider_name = "ollama"
        
        return providers[provider_name]()
    
    @classmethod
    def _select_best_provider(cls) -> str:
        """
        Select best available provider
        Priority: ollama (free) -> openai -> claude -> gemini
        """
        
        # Check which providers have API keys
        if os.getenv("OPENAI_API_KEY"):
            return "openai"
        
        # Default to free Ollama
        return "ollama"
    
    @classmethod
    async def get_fallback_provider(
        cls,
        failed_provider: str,
        tried_providers: Optional[List[str]] = None
    ) -> Optional[AIProvider]:
        """
        Get fallback provider when one fails
        
        Args:
            failed_provider: Provider that failed
            tried_providers: List of already tried providers
            
        Returns:
            Next provider to try, or None if all failed
        """
        
        tried_providers = tried_providers or []
        tried_providers.append(failed_provider)
        
        # Fallback order
        fallback_order = ["ollama", "openai", "claude", "gemini"]
        
        for provider_name in fallback_order:
            if provider_name not in tried_providers:
                provider = cls.get_provider(provider_name)
                if await provider.health_check():
                    return provider
        
        return None
    
    @classmethod
    async def health_check_all(cls) -> dict:
        """Check health of all providers"""
        
        providers = ["openai", "ollama"]  # TODO: Add claude, gemini
        results = {}
        
        for provider_name in providers:
            try:
                provider = cls.get_provider(provider_name)
                is_healthy = await provider.health_check()
                results[provider_name] = "healthy" if is_healthy else "unhealthy"
            except Exception as e:
                results[provider_name] = f"error: {str(e)}"
        
        return results


# Convenience function
def get_ai_provider(provider_name: str = "auto") -> AIProvider:
    """Get AI provider instance"""
    return ProviderFactory.get_provider(provider_name)
