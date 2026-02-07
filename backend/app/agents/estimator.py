from app.agents.base import BaseAgent
import asyncio
from app.schemas import Urgency

class EstimatorAgent(BaseAgent):
    def __init__(self):
        super().__init__("EstimatorAgent")

    async def run(self, input_data: dict) -> dict:
        """
        Calculates complexity, estimated cost, and final price based on urgency.
        """
        description = input_data.get("description", "")
        urgency = input_data.get("urgency", Urgency.FLEXIBLE.value)
        
        print(f"[{self.name}] Estimating for: {description} (Urgency: {urgency})")
        await asyncio.sleep(0.5)
        
        # Mock Logic for Complexity
        # Char count based
        base_cost = 0.50 # Minimum AI cost
        if len(description) > 50:
            base_cost += 0.50
        if len(description) > 200:
            base_cost += 2.0
            
        # Commercial Margin (3x)
        base_price = base_cost * 3
        
        # Urgency Multiplier
        multiplier = 1.0
        if urgency == Urgency.ASAP.value: # 1h
            multiplier = 2.5
        elif urgency == Urgency.TODAY.value:
            multiplier = 1.8
        elif urgency == Urgency.TOMORROW.value:
            multiplier = 1.3
            
        final_price = base_price * multiplier
        
        return {
            "ai_cost_estimate": round(base_cost, 2),
            "base_price": round(base_price, 2),
            "final_price": round(final_price, 2),
            "currency": "USD",
            "eta": "2 hours" if urgency == Urgency.ASAP else "1 day"
        }
