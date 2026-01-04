"""Detection processing service with cooldown and deduplication.

Uses Cloudinary for image storage (NOT Firebase Storage).
"""

from datetime import datetime
from typing import Tuple
from cachetools import TTLCache
from google.cloud.firestore import SERVER_TIMESTAMP

from app.config import get_settings
from app.core.firebase import get_firestore
from app.models.detection import DetectionRequest, DetectionResponse
from app.services.cloudinary_service import CloudinaryService
from app.services.fcm_service import FCMService


class DetectionService:
    """Service for processing detection events from edge devices."""
    
    # In-memory cache for cooldown tracking
    # Key: device_id, Value: last detection timestamp
    _cooldown_cache: TTLCache = TTLCache(maxsize=1000, ttl=300)
    
    @staticmethod
    def is_predator(animal: str) -> bool:
        """Check if the detected animal is classified as a predator."""
        settings = get_settings()
        return animal.lower() in settings.predator_animals_list
    
    @staticmethod
    def check_cooldown(device_id: str) -> Tuple[bool, int]:
        """
        Check if device is in cooldown period.
        
        Args:
            device_id: The device identifier
            
        Returns:
            Tuple of (is_in_cooldown, seconds_remaining)
        """
        settings = get_settings()
        cooldown_seconds = settings.cooldown_seconds
        
        last_detection = DetectionService._cooldown_cache.get(device_id)
        
        if last_detection is None:
            return False, 0
        
        elapsed = (datetime.utcnow() - last_detection).total_seconds()
        
        if elapsed < cooldown_seconds:
            remaining = int(cooldown_seconds - elapsed)
            return True, remaining
        
        return False, 0
    
    @staticmethod
    def update_cooldown(device_id: str) -> None:
        """Update the cooldown timestamp for a device."""
        DetectionService._cooldown_cache[device_id] = datetime.utcnow()
    
    @staticmethod
    async def process_detection(request: DetectionRequest) -> DetectionResponse:
        """
        Process a detection event from an edge device.
        
        This method:
        1. Checks cooldown status
        2. Uploads image to Cloudinary (if present)
        3. Stores detection in Firestore
        4. Triggers FCM alerts for predators
        
        Args:
            request: Detection request from edge device
            
        Returns:
            DetectionResponse with processing results
        """
        # Check cooldown
        in_cooldown, remaining = DetectionService.check_cooldown(request.device_id)
        
        if in_cooldown:
            return DetectionResponse(
                success=False,
                message=f"Device in cooldown. Wait {remaining} seconds.",
                is_predator=DetectionService.is_predator(request.animal)
            )
        
        try:
            # Parse timestamp
            detection_time = datetime.utcnow()
            if request.timestamp:
                try:
                    detection_time = datetime.fromisoformat(
                        request.timestamp.replace("Z", "+00:00")
                    )
                except ValueError:
                    pass  # Use current time if parsing fails
            
            # Upload image to Cloudinary (if present)
            image_url = None
            if request.image_base64:
                image_url = await CloudinaryService.upload_detection_image(
                    device_id=request.device_id,
                    image_base64=request.image_base64,
                    timestamp=detection_time
                )
            
            # Determine if predator
            is_predator = DetectionService.is_predator(request.animal)
            
            # Store in Firestore (schema unchanged)
            db = get_firestore()
            doc_ref = db.collection("detections").document()
            
            detection_doc = {
                "device_id": request.device_id,
                "animal": request.animal,
                "confidence": request.confidence,
                "is_predator": is_predator,
                "image_url": image_url,  # Now a Cloudinary URL
                "detection_time": detection_time,
                "created_at": SERVER_TIMESTAMP,
                "alert_sent": False
            }
            
            doc_ref.set(detection_doc)
            detection_id = doc_ref.id
            
            # Update cooldown
            DetectionService.update_cooldown(request.device_id)
            
            # Trigger alert for predators
            alert_triggered = False
            if is_predator:
                alert_triggered = await FCMService.send_predator_alert(
                    animal=request.animal,
                    confidence=request.confidence,
                    device_id=request.device_id,
                    image_url=image_url,
                    detection_id=detection_id
                )
                
                # Update document with alert status
                if alert_triggered:
                    doc_ref.update({"alert_sent": True})
            
            return DetectionResponse(
                success=True,
                detection_id=detection_id,
                message="Detection processed successfully",
                is_predator=is_predator,
                alert_triggered=alert_triggered,
                image_url=image_url
            )
            
        except Exception as e:
            print(f"Error processing detection: {e}")
            return DetectionResponse(
                success=False,
                message=f"Processing error: {str(e)}",
                is_predator=DetectionService.is_predator(request.animal)
            )
