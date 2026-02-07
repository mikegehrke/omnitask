from app.agents.base import BaseAgent
import asyncio

class ClarificationAgent(BaseAgent):
    def __init__(self):
        super().__init__("ClarificationAgent")

    async def run(self, input_data: dict) -> dict:
        """
        Analyzes task description. If ambiguous, generates questions.
        """
        description = input_data.get("description", "")
        print(f"[{self.name}] Checking ambiguity in: {description}")
        await asyncio.sleep(0.5)
        
        # Simple Mock Logic:
        # If description length < 20 chars, ask for more details.
        if len(description) < 20:
            return {
                "needs_clarification": True,
                "questions": [
                    "Can you provide more specific details?",
                    "Do you have a preferred deadline?",
                    "Are there any specific file formats required?"
                ]
            }
        
        return {
            "needs_clarification": False,
            "questions": []
        }
