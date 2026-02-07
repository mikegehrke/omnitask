"""
Task Planner
Creates step-by-step execution plan
"""
from typing import Dict, Any
from app.ai.base import AIProvider, AIMessage
import json


PLANNING_PROMPT = """You are an expert task planner. Create a detailed, step-by-step plan to accomplish this task.

TASK: {description}

ANALYSIS:
{analysis}

User's language: {language}

Create a JSON plan with:
{{
    "steps": [
        {{
            "step_number": 1,
            "action": "What to do",
            "details": "How to do it",
            "estimated_tokens": 500
        }}
    ],
    "total_estimated_tokens": 2000,
    "expected_output": "Description of final result",
    "tools_needed": ["research", "writing", "formatting"]
}}

Make the plan clear, actionable, and complete."""


async def create_plan(
    description: str,
    analysis: Dict[str, Any],
    provider: AIProvider,
    user_language: str = "en"
) -> Dict[str, Any]:
    """
    Create execution plan for task
    
    Args:
        description: Original task description
        analysis: Analysis results from analyzer
        provider: AI provider
        user_language: User's language
        
    Returns:
        Execution plan with steps
    """
    
    # Create planning prompt
    prompt = PLANNING_PROMPT.format(
        description=description,
        analysis=json.dumps(analysis, indent=2),
        language=user_language
    )
    
    messages = [
        AIMessage(role="system", content="You are an expert planner."),
        AIMessage(role="user", content=prompt)
    ]
    
    # Get AI response
    response = await provider.chat_completion(
        messages=messages,
        temperature=0.4,
        max_tokens=1000
    )
    
    
    # Parse plan with extraction (handles text-wrapped JSON from Ollama)
    import re
    
    def extract_json_from_text(text: str) -> dict:
        """Extract JSON object from text that may contain surrounding content"""
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if not match:
            raise ValueError("No JSON object found in response")
        return json.loads(match.group(0))
    
    try:
        plan = extract_json_from_text(response.content)
    except (json.JSONDecodeError, ValueError) as e:
        print(f"⚠️  Planner JSON parsing failed: {e}")
        print(f"📄 Raw content: {response.content[:200]}")
        # Fallback plan
        plan = {
            "steps": [
                {
                    "step_number": 1,
                    "action": "Analyze requirements",
                    "details": description,
                    "estimated_tokens": 500
                },
                {
                    "step_number": 2,
                    "action": "Generate solution",
                    "details": "Create the requested output",
                    "estimated_tokens": 1500
                }
            ],
            "total_estimated_tokens": 2000,
            "expected_output": analysis.get("output_type", "text"),
            "tools_needed": ["ai_generation"]
        }
    
    return plan
