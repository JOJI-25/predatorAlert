"""Detection data models."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator


class DetectionRequest(BaseModel):
    """Request model for detection submission from edge devices."""
    
    device_id: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Unique identifier for the edge device"
    )
    animal: str = Field(
        ...,
        min_length=1,
        max_length=50,
        description="Detected animal type"
    )
    confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Detection confidence score (0.0 to 1.0)"
    )
    timestamp: Optional[str] = Field(
        default=None,
        description="ISO 8601 timestamp of detection"
    )
    image_base64: Optional[str] = Field(
        default=None,
        description="Base64 encoded detection image"
    )
    
    @field_validator('animal')
    @classmethod
    def normalize_animal(cls, v: str) -> str:
        """Normalize animal name to lowercase."""
        return v.strip().lower()
    
    @field_validator('device_id')
    @classmethod
    def normalize_device_id(cls, v: str) -> str:
        """Normalize device ID."""
        return v.strip()


class DetectionResponse(BaseModel):
    """Response model for detection submission."""
    
    success: bool
    detection_id: Optional[str] = None
    message: str
    is_predator: bool = False
    alert_triggered: bool = False
    image_url: Optional[str] = None


class DetectionDocument(BaseModel):
    """Firestore document model for detection records."""
    
    device_id: str
    animal: str
    confidence: float
    is_predator: bool
    image_url: Optional[str] = None
    timestamp: datetime
    created_at: datetime
    alert_sent: bool = False
