"""
Pricing Engine
Calculates costs for tasks based on provider and AI costs

FINALE PREISREGEL (VERBINDLICH):
- KI-Kosten ≤ 0,49 € → Endpreis = 1,50 € (fix)
- ab 0,50 € → Endpreis = KI-Kosten × 3 (200% Marge)
- Kein Output vor Payment/Credit-OK
"""
from typing import Dict


# Provider base costs per 1K tokens (USD)
PROVIDER_COSTS = {
    "openai": {
        "gpt-4o-mini": {"input": 0.00015, "output": 0.0006},
        "gpt-4-turbo": {"input": 0.01, "output": 0.03},
        "gpt-3.5-turbo": {"input": 0.0005, "output": 0.0015},
    },
    "claude": {
        "claude-3-opus": {"input": 0.015, "output": 0.075},
        "claude-3-sonnet": {"input": 0.003, "output": 0.015},
        "claude-3-haiku": {"input": 0.00025, "output": 0.00125},
    },
    "gemini": {
        "gemini-1.5-flash": {"input": 0.00010, "output": 0.0004},
        "gemini-pro": {"input": 0.00025, "output": 0.0005},
    },
    "ollama": {
        "default": {"input": 0.0, "output": 0.0},  # Free!
    },
    "auto": {
        "default": {"input": 0.00015, "output": 0.0006},  # OpenAI gpt-4o-mini default
    }
}


def estimate_tokens(description: str) -> int:
    """
    Estimate tokens needed for a task
    
    Simple heuristic:
    - Input: description length
    - Output: 3x description (AI response is usually longer)
    - Total: 4x description tokens
    
    Args:
        description: Task description
        
    Returns:
        Estimated total tokens
    """
    # Rough estimate: 4 characters ≈ 1 token
    input_tokens = len(description) // 4
    
    # Assume output is 3x input
    output_tokens = input_tokens * 3
    
    # Add buffer for system prompts and context
    total_tokens = (input_tokens + output_tokens) * 1.2
    
    return int(total_tokens)


def get_provider_cost(provider: str, tokens: int) -> float:
    """
    Calculate base AI provider cost
    
    Args:
        provider: Provider name
        tokens: Total tokens (input + output)
        
    Returns:
        Cost in USD
    """
    if provider not in PROVIDER_COSTS:
        provider = "auto"
    
    # Get first model for provider
    models = PROVIDER_COSTS[provider]
    model_name = list(models.keys())[0]
    pricing = models[model_name]
    
    # Assume 25% input, 75% output (typical for generation)
    input_tokens = tokens * 0.25
    output_tokens = tokens * 0.75
    
    input_cost = (input_tokens / 1000) * pricing["input"]
    output_cost = (output_tokens / 1000) * pricing["output"]
    
    return input_cost + output_cost


def calculate_task_price(
    description: str,
    urgency: str,
    provider: str,
    estimated_tokens: int
) -> Dict[str, float]:
    """
    Calculate total task price
    
    FINALE PREISREGEL (VERBINDLICH):
    - KI-Kosten ≤ 0,49 € → Endpreis = 1,50 € (fix)
    - ab 0,50 € → Endpreis = KI-Kosten × 3 (200% Marge)
    
    Args:
        description: Task description
        urgency: Urgency level (kept for compatibility, not used in pricing)
        provider: AI provider
        estimated_tokens: Estimated token count
        
    Returns:
        Dict with price breakdown
    """
    
    # Get base AI provider cost
    ai_cost = get_provider_cost(provider, estimated_tokens)
    
    # Apply finale Preisregel
    if ai_cost <= 0.49:
        total_price = 1.50
    else:
        total_price = ai_cost * 3
    
    return {
        "base_cost": round(ai_cost, 4),
        "ai_cost": round(ai_cost, 4),
        "provider_cost": round(ai_cost, 4),
        "total_price": round(total_price, 2),
        "currency": "EUR",
        "pricing_rule": "≤0.49€→1.50€ | ≥0.50€→×3"
    }


def calculate_refund(
    task_status: str,
    estimated_cost: float,
    actual_cost: float
) -> float:
    """
    Calculate refund amount if task is cancelled
    
    Rules:
    - Pending: 100% refund
    - Analyzing/Planning: 80% refund
    - Executing: No refund (work started)
    - Completed/Failed: No refund
    
    Args:
        task_status: Current task status
        estimated_cost: Original estimated cost
        actual_cost: Actual cost incurred
        
    Returns:
        Refund amount in USD
    """
    
    if task_status == "pending":
        return estimated_cost
    
    elif task_status in ["analyzing", "clarifying", "planning"]:
        return estimated_cost * 0.8
    
    else:
        # No refund if execution started or completed
        return 0.0
