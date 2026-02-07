from app.agents.base import BaseAgent
import asyncio

class QAAgent(BaseAgent):
    def __init__(self):
        super().__init__("QAAgent")

    async def run(self, input_data: dict) -> dict:
        """
        Validates the output of the Executor.
        """
        output = input_data.get("output", "")
        print(f"[{self.name}] Validating output: {output}")
        await asyncio.sleep(0.5)
        
        return {
            "passed": True,
            "feedback": "Output meets quality standards."
        }
