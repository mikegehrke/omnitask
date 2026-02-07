import os
from openai import AsyncOpenAI
from app.core.config import settings

# Determine Provider and Base URL
# If provider is 'ollama', use the internal docker service name 'http://ollama:11434/v1'
# If using real cloud, use default.

class AIClient:
    def __init__(self):
        self.provider = os.getenv("DEFAULT_AI_PROVIDER", "ollama")
        self.base_url = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
        self.api_key = os.getenv("OPENAI_API_KEY", "ollama") # Ollama doesn't care about key

        # Adjust for Ollama v1 compatibility
        if self.provider == "ollama":
            if not self.base_url.endswith("/v1"):
                self.base_url = f"{self.base_url}/v1"
        
        print(f"[AI CORE] Initializing Client. Provider: {self.provider}, URL: {self.base_url}")
        
        self.client = AsyncOpenAI(
            base_url=self.base_url,
            api_key=self.api_key
        )

    async def generate(self, prompt: str, model: str = "llama3") -> str:
        """
        REAL AI GENERATION. No mocks.
        """
        try:
            print(f"[AI CORE] Sending request to {model}...")
            response = await self.client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7
            )
            content = response.choices[0].message.content
            print(f"[AI CORE] Received response: {content[:50]}...")
            return content
        except Exception as e:
            print(f"[AI CORE] ERROR: {str(e)}")
            raise e

# Singleton instance
llm = AIClient()
