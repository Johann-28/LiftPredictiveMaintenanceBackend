"""
Base models for shared use across microservices
"""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class BaseResponse(BaseModel):
    success: bool
    message: str
    timestamp: datetime = datetime.now()

class PaginationParams(BaseModel):
    page: int = 1
    size: int = 20
    
class SortParams(BaseModel):
    field: str = "created_at"
    direction: str = "desc"

class HealthStatus(BaseModel):
    status: str
    timestamp: datetime
    version: str
    uptime: float

class AlertSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"
