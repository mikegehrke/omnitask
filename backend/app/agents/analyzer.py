"""
Task Analyzer
Understands user intent and determines what needs to be done
"""
from typing import Dict, Any
from app.ai.base import AIProvider, AIMessage


ANALYSIS_PROMPT = """You are an expert task analyzer. Your job is to understand what the user wants to accomplish.

Analyze this task request:
"{description}"

User's preferred language: {language}

Provide a JSON response with:
{{
    "intent": "Brief description of what user wants",
    "category": "document|code|design|research|translation|other",
    "complexity": "simple|medium|complex",
    "output_type": "text|pdf|docx|code|image|zip",
    "needs_clarification": true|false,
    "questions": ["question1", "question2"] (if clarification needed),
    "estimated_steps": 3,
    "key_requirements": ["req1", "req2"]
}}

Be concise and accurate."""


async def analyze_task(
    description: str,
    provider: AIProvider,
    user_language: str = "en"
) -> Dict[str, Any]:
    """
    Analyze task to understand intent and requirements
    
    Args:
        description: Task description from user
        provider: AI provider to use
        user_language: User's preferred language
        
    Returns:
        Analysis dict with intent, category, complexity, etc.
    """
    
    # Create analysis prompt
    prompt = ANALYSIS_PROMPT.format(
        description=description,
        language=user_language
    )
    
    messages = [
        AIMessage(role="system", content="You are a task analysis expert."),
        AIMessage(role="user", content=prompt)
    ]
    
    # Get AI response
    response = await provider.chat_completion(
        messages=messages,
        temperature=0.3,  # Low temperature for consistent analysis
        max_tokens=500
    )
    
    
    # Parse JSON response with extraction (handles text-wrapped JSON from Ollama)
    import json
    import re
    
    def extract_json_from_text(text: str) -> dict:
        """Extract JSON object from text that may contain surrounding content"""
        # Try to find JSON object in text
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if not match:
            raise ValueError("No JSON object found in response")
        return json.loads(match.group(0))
    
    try:
        analysis = extract_json_from_text(response.content)
    except (json.JSONDecodeError, ValueError) as e:
        print(f"⚠️  JSON parsing failed: {e}")
        print(f"📄 Raw content: {response.content[:200]}")
        # Fallback if AI doesn't return valid JSON
        analysis = {
            "intent": description[:100],
            "category": "other",
            "complexity": "medium",
            "output_type": "text",
            "needs_clarification": False,
            "questions": [],
            "estimated_steps": 3,
            "key_requirements": []
        }
    
    return analysis
