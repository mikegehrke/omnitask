"""
Pydantic schemas for API requests and responses
"""
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


# ============================================================================
# ENUMS (matching database)
# ============================================================================

class UserPlanEnum(str, Enum):
    FREE = "free"
    PRO = "pro"
    UNLIMITED = "unlimited"


class TaskStatusEnum(str, Enum):
    PENDING = "pending"
    ANALYZING = "analyzing"
    CLARIFYING = "clarifying"
    PLANNING = "planning"
    EXECUTING = "executing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class TaskUrgencyEnum(str, Enum):
    FLEXIBLE = "flexible"
    TODAY = "today"
    ASAP = "asap"


class AIProviderEnum(str, Enum):
    AUTO = "auto"
    OPENAI = "openai"
    CLAUDE = "claude"
    GEMINI = "gemini"
    OLLAMA = "ollama"


class MessageRoleEnum(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


# ============================================================================
# AUTH SCHEMAS
# ============================================================================

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: Optional[int] = None


# ============================================================================
# USER SCHEMAS
# ============================================================================

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    company: Optional[str] = None


class UserResponse(UserBase):
    id: int
    plan: UserPlanEnum
    credits_balance: float
    monthly_limit: float
    monthly_usage: float
    language: str
    output_language: str
    default_provider: AIProviderEnum
    is_active: bool
    is_verified: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    company: Optional[str] = None
    language: Optional[str] = None
    output_language: Optional[str] = None
    default_provider: Optional[AIProviderEnum] = None
    theme: Optional[str] = None
    notifications_enabled: Optional[bool] = None


# ============================================================================
# TASK SCHEMAS
# ============================================================================

class TaskCreate(BaseModel):
    description: str = Field(..., min_length=10, max_length=5000)
    urgency: TaskUrgencyEnum = TaskUrgencyEnum.FLEXIBLE
    provider: AIProviderEnum = AIProviderEnum.AUTO


class TaskUpdate(BaseModel):
    description: Optional[str] = None
    urgency: Optional[TaskUrgencyEnum] = None
    provider: Optional[AIProviderEnum] = None


class TaskResponse(BaseModel):
    id: int
    user_id: int
    description: str
    status: TaskStatusEnum
    urgency: TaskUrgencyEnum
    provider: AIProviderEnum
    estimated_cost: float
    final_cost: float
    tokens_used: int
    result_text: Optional[str] = None
    result_files: Optional[List[int]] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None
    
    class Config:
        from_attributes = True


class TaskDetail(TaskResponse):
    """Extended task info with plan and analysis"""
    plan: Optional[Dict[str, Any]] = None
    analysis: Optional[Dict[str, Any]] = None
    clarification_questions: Optional[List[str]] = None


class PriceEstimate(BaseModel):
    """Price calculation before task creation"""
    base_cost: float
    urgency_multiplier: float
    urgency_fee: float
    provider_cost: float
    total_price: float
    currency: str = "USD"
    estimated_tokens: int


# ============================================================================
# MESSAGE SCHEMAS
# ============================================================================

class MessageCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=10000)


class MessageResponse(BaseModel):
    id: int
    task_id: int
    role: MessageRoleEnum
    content: str
    tokens_used: int
    cost: float
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# PAYMENT SCHEMAS
# ============================================================================

class CheckoutCreate(BaseModel):
    """Create payment checkout session"""
    amount: float = Field(..., gt=0)
    task_id: Optional[int] = None
    provider: str = "stripe"  # stripe or paypal
    success_url: str
    cancel_url: str


class CheckoutResponse(BaseModel):
    session_id: str
    checkout_url: str


class PaymentResponse(BaseModel):
    id: int
    user_id: int
    task_id: Optional[int] = None
    amount: float
    currency: str
    status: str
    provider: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# FILE SCHEMAS
# ============================================================================

class FileUploadResponse(BaseModel):
    id: int
    filename: str
    file_type: str
    size_bytes: int
    purpose: str
    created_at: datetime


class FileResponse(BaseModel):
    id: int
    filename: str
    file_type: str
    size_bytes: int
    purpose: str
    download_url: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# AUTOMATION SCHEMAS
# ============================================================================

class AutomationCreate(BaseModel):
    name: str
    description: Optional[str] = None
    schedule_type: str  # daily, weekly, monthly, cron
    schedule_config: Dict[str, Any]
    task_template: Dict[str, Any]


class AutomationResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    schedule_type: str
    is_active: bool
    last_run: Optional[datetime] = None
    next_run: Optional[datetime] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


# ============================================================================
# SYSTEM SCHEMAS
# ============================================================================

class HealthCheck(BaseModel):
    status: str
    database: str
    redis: str
    ai_providers: Dict[str, str]


class ErrorResponse(BaseModel):
    detail: str
    code: Optional[str] = None
