"""
Chat Agent - Handles conversational responses for tasks
"""
from app.core.ollama import OllamaClient


class ChatAgent:
    def __init__(self):
        self.ollama = OllamaClient()
    
    async def respond(
        self,
        task_description: str,
        user_message: str,
        conversation_history: list = None
    ) -> str:
        """Generate AI response to user message in context of task"""
        
        # Build context from conversation history
        context = f"Task: {task_description}\n\n"
        
        if conversation_history:
            # Last 5 messages for context
            for msg in conversation_history[-5:]:
                sender = msg.get('sender', 'user')
                content = msg.get('content', '')
                context += f"{sender}: {content}\n"
        
        context += f"\nuser: {user_message}\n\n"
        context += "Respond as a helpful AI assistant working on this task:"
        
        # Get AI response
        response = await self.ollama.generate(prompt=context)
        
        return response.strip()
