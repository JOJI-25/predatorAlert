"""Firebase Cloud Messaging service for push notifications."""

from typing import Dict, List, Optional, Any
from firebase_admin import messaging
from app.core.firebase import get_firestore


class FCMService:
    """Service for sending Firebase Cloud Messaging notifications."""
    
    @staticmethod
    async def get_alert_config() -> Dict[str, Any]:
        """
        Fetch alert configuration from Firestore.
        
        Returns:
            Alert configuration dictionary
        """
        try:
            db = get_firestore()
            doc = db.collection("alert_config").document("global").get()
            
            if doc.exists:
                return doc.to_dict()
            
            # Default configuration
            return {
                "alert_enabled": True,
                "siren_enabled": True,
                "sms_enabled": False,
                "owner_contacts": [],
                "authority_contacts": [],
                "fcm_topics": ["predator_alerts"]
            }
            
        except Exception as e:
            print(f"Error fetching alert config: {e}")
            return {"alert_enabled": False}
    
    @staticmethod
    async def send_predator_alert(
        animal: str,
        confidence: float,
        device_id: str,
        image_url: Optional[str] = None,
        detection_id: Optional[str] = None
    ) -> bool:
        """
        Send predator alert notification via FCM.
        
        Args:
            animal: Detected predator type
            confidence: Detection confidence score
            device_id: Device that made the detection
            image_url: Optional URL to detection image
            detection_id: Firestore document ID
            
        Returns:
            True if alert was sent successfully
        """
        try:
            # Get alert configuration
            config = await FCMService.get_alert_config()
            
            if not config.get("alert_enabled", True):
                print("Alerts are disabled in configuration")
                return False
            
            # Build data payload (for handling in app)
            # NOTE: We send data-only message (no notification) so Flutter's
            # background handler can receive it and auto-launch the app with siren
            data = {
                "type": "predator_alert",
                "animal": animal,
                "confidence": str(confidence),
                "device_id": device_id,
                "detection_id": detection_id or "",
                "image_url": image_url or "",
                "siren_enabled": str(config.get("siren_enabled", True)).lower(),
                "title": "PREDATOR ALERT",
                "body": f"{animal.upper()} detected with {confidence*100:.0f}% confidence!",
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "auto_launch": "true"
            }
            
            # Android-specific configuration - HIGH priority for background delivery
            android_config = messaging.AndroidConfig(
                priority="high",
                ttl=0,  # Immediate delivery, no delay
            )
            
            # Send to topic
            topics = config.get("fcm_topics", ["predator_alerts"])
            
            for topic in topics:
                # Data-only message (no notification key) - allows background processing
                message = messaging.Message(
                    data=data,
                    android=android_config,
                    topic=topic
                )
                
                response = messaging.send(message)
                print(f"Data-only alert sent to topic '{topic}': {response}")
            
            return True
            
        except Exception as e:
            print(f"Error sending FCM alert: {e}")
            return False
    
    @staticmethod
    async def send_to_tokens(
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> Dict[str, int]:
        """
        Send notification to specific device tokens.
        
        Args:
            tokens: List of FCM device tokens
            title: Notification title
            body: Notification body
            data: Optional data payload
            
        Returns:
            Dictionary with success and failure counts
        """
        if not tokens:
            return {"success": 0, "failure": 0}
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                tokens=tokens,
                android=messaging.AndroidConfig(
                    priority="high"
                )
            )
            
            response = messaging.send_multicast(message)
            
            return {
                "success": response.success_count,
                "failure": response.failure_count
            }
            
        except Exception as e:
            print(f"Error sending multicast: {e}")
            return {"success": 0, "failure": len(tokens)}
