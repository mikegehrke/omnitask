"""
Complete database models for OmniTask
Following the master rebuild plan
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, Float, Boolean, JSON, Enum as SQLEnum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.base import Base
import enum
from datetime import datetime


# ============================================================================
# ENUMS
# ============================================================================

class UserPlan(str, enum.Enum):
    FREE = "free"
    PRO = "pro"
    UNLIMITED = "unlimited"


class TaskStatus(str, enum.Enum):
    AWAITING_PAYMENT = "awaiting_payment"  # KRITISCH: Task wartet auf Zahlung
    PENDING = "pending"
    ANALYZING = "analyzing"
    CLARIFYING = "clarifying"
    PLANNING = "planning"
    EXECUTING = "executing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class TaskUrgency(str, enum.Enum):
    FLEXIBLE = "flexible"
    TODAY = "today"
    ASAP = "asap"


class AIProvider(str, enum.Enum):
    AUTO = "auto"
    OPENAI = "openai"
    CLAUDE = "claude"
    GEMINI = "gemini"
    OLLAMA = "ollama"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    REFUNDED = "refunded"


class MessageRole(str, enum.Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class FilePurpose(str, enum.Enum):
    INPUT = "input"
    OUTPUT = "output"
    TEMP = "temp"


# ============================================================================
# MODELS
# ============================================================================

class User(Base):
    """User account with plan and credits"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    company = Column(String, nullable=True)
    
    # Plan & Billing
    plan = Column(SQLEnum(UserPlan), default=UserPlan.FREE, nullable=False)
    credits_balance = Column(Float, default=0.0, nullable=False)
    monthly_limit = Column(Float, default=10.0, nullable=False)  # USD
    monthly_usage = Column(Float, default=0.0, nullable=False)
    stripe_customer_id = Column(String, nullable=True)
    
    # Preferences
    language = Column(String, default="en", nullable=False)  # UI language
    output_language = Column(String, default="en", nullable=False)  # AI output language
    default_provider = Column(SQLEnum(AIProvider), default=AIProvider.AUTO, nullable=False)
    
    # Settings
    theme = Column(String, default="system", nullable=False)
    notifications_enabled = Column(Boolean, default=True, nullable=False)
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="user", cascade="all, delete-orphan")
    files = relationship("File", back_populates="user", cascade="all, delete-orphan")


class Task(Base):
    """Main task/job entity"""
    __tablename__ = "tasks"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Task Details
    description = Column(Text, nullable=False)
    status = Column(SQLEnum(TaskStatus), default=TaskStatus.PENDING, nullable=False, index=True)
    urgency = Column(SQLEnum(TaskUrgency), default=TaskUrgency.FLEXIBLE, nullable=False)
    provider = Column(SQLEnum(AIProvider), default=AIProvider.AUTO, nullable=False)
    
    # Execution Data
    plan = Column(JSON, nullable=True)  # Execution plan from planner
    analysis = Column(JSON, nullable=True)  # Analysis results
    clarification_questions = Column(JSON, nullable=True)  # Questions for user
    
    # Results
    result_text = Column(Text, nullable=True)
    result_files = Column(JSON, nullable=True)  # List of file IDs
    
    # Costs & Pricing
    estimated_cost = Column(Float, default=0.0, nullable=False)
    final_cost = Column(Float, default=0.0, nullable=False)
    tokens_used = Column(Integer, default=0, nullable=False)
    
    # Metadata
    error_message = Column(Text, nullable=True)
    retry_count = Column(Integer, default=0, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="tasks")
    messages = relationship("Message", back_populates="task", cascade="all, delete-orphan")
    files = relationship("File", back_populates="task", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="task")


class Message(Base):
    """Chat messages between user and AI"""
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False, index=True)
    
    role = Column(SQLEnum(MessageRole), nullable=False)
    content = Column(Text, nullable=True)  # Nullable if message is file-only
    
    # File attachments
    file_url = Column(String, nullable=True)
    file_name = Column(String, nullable=True)
    file_type = Column(String, nullable=True)  # image/pdf/document/text
    
    # Metadata
    tokens_used = Column(Integer, default=0, nullable=False)
    cost = Column(Float, default=0.0, nullable=False)
    provider_used = Column(SQLEnum(AIProvider), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    task = relationship("Task", back_populates="messages")


class Payment(Base):
    """Payment transactions"""
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=True, index=True)
    
    # Payment Details
    amount = Column(Float, nullable=False)
    currency = Column(String, default="USD", nullable=False)
    status = Column(SQLEnum(PaymentStatus), default=PaymentStatus.PENDING, nullable=False)
    
    # Provider Info
    provider = Column(String, nullable=False)  # stripe, paypal, credits
    provider_payment_id = Column(String, nullable=True)  # External ID
    provider_session_id = Column(String, nullable=True)  # Checkout session
    
    # Invoice
    invoice_url = Column(String, nullable=True)
    invoice_pdf = Column(String, nullable=True)
    
    # Metadata
    description = Column(String, nullable=True)
    payment_metadata = Column(JSON, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="payments")
    task = relationship("Task", back_populates="payments")


class File(Base):
    """Uploaded and generated files"""
    __tablename__ = "files"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=True, index=True)
    
    # File Info
    filename = Column(String, nullable=False)
    file_path = Column(String, nullable=False)  # Storage path
    file_type = Column(String, nullable=False)  # MIME type
    size_bytes = Column(Integer, nullable=False)
    purpose = Column(SQLEnum(FilePurpose), nullable=False)
    
    # Metadata
    checksum = Column(String, nullable=True)  # For integrity
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="files")
    task = relationship("Task", back_populates="files")


class Automation(Base):
    """Scheduled/recurring tasks"""
    __tablename__ = "automations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    
    # Schedule
    schedule_type = Column(String, nullable=False)  # daily, weekly, monthly, cron
    schedule_config = Column(JSON, nullable=False)  # Cron or config
    
    # Task Template
    task_template = Column(JSON, nullable=False)  # Task creation params
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    last_run = Column(DateTime(timezone=True), nullable=True)
    next_run = Column(DateTime(timezone=True), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class SystemLog(Base):
    """System-wide logs for monitoring"""
    __tablename__ = "system_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    
    level = Column(String, nullable=False)  # INFO, WARNING, ERROR
    category = Column(String, nullable=False)  # auth, task, payment, ai
    message = Column(Text, nullable=False)
    details = Column(JSON, nullable=True)
    
    user_id = Column(Integer, nullable=True)
    task_id = Column(Integer, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
