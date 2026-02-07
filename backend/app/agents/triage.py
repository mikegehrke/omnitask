"""
TriageAgent - REAL AI Implementation
Analyzes task complexity and category using Ollama LLM.
NO MOCKS. NO SLEEP.
"""
from app.agents.base import BaseAgent
from app.core.ollama import ollama_client
import json


class TriageAgent(BaseAgent):
    def __init__(self):
        super().__init__("TriageAgent")

    async def run(self, input_data: dict) -> dict:
        task_description = input_data.get("description", "")
        print(f"[{self.name}] Analyzing task: {task_description}")
        
        system_prompt = (
            "You are a task analysis AI. "
            "Analyze the given task and respond ONLY with valid JSON.\n"
            "Output format:\n"
            '{\n  "complexity": <1-5 number>,\n'
            '  "category": "<one word category>",\n'
            '  "needs_clarification": <true/false>\n}'
        )
        
        prompt = f"Analyze this task:\n{task_description}"
        
        # REAL AI CALL - NO MOCK
        response = await ollama_client.generate(
            prompt=prompt,
            system=system_prompt,
            temperature=0.3
        )
        
        try:
            # Extract JSON from response
            result = json.loads(response)
            print(f"[{self.name}] AI Response: {result}")
            return result
        except json.JSONDecodeError:
            # Fallback if LLM doesn't return valid JSON
            print(f"[{self.name}] AI returned invalid JSON: {response}")
            return {
                "complexity": 3,
                "category": "general",
                "needs_clarification": True,
                "raw_response": response
            }
