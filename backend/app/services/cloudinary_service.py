"""Cloudinary service for image uploads.

This service replaces Firebase Storage for image hosting.
Cloudinary free tier provides:
- 25 GB storage
- 25 GB bandwidth/month
- No credit card required
"""

import base64
import uuid
from datetime import datetime
from typing import Optional
import cloudinary
import cloudinary.uploader
from app.config import get_settings


_cloudinary_configured = False


def initialize_cloudinary() -> bool:
    """
    Initialize Cloudinary with credentials from environment.
    
    Returns:
        bool: True if successfully configured, False otherwise
    """
    global _cloudinary_configured
    
    if _cloudinary_configured:
        return True
    
    settings = get_settings()
    
    if not settings.cloudinary_configured:
        print("[!] Cloudinary not configured - image uploads will be skipped")
        return False
    
    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True
    )
    
    _cloudinary_configured = True
    print("[+] Cloudinary initialized")
    return True


class CloudinaryService:
    """Service for handling Cloudinary image uploads."""
    
    @staticmethod
    async def upload_detection_image(
        device_id: str,
        image_base64: str,
        timestamp: Optional[datetime] = None
    ) -> Optional[str]:
        """
        Upload a base64-encoded image to Cloudinary.
        
        Args:
            device_id: The device ID for folder organization
            image_base64: Base64-encoded image data
            timestamp: Optional timestamp for public_id
            
        Returns:
            Secure HTTPS URL of the uploaded image, or None on failure
        """
        # Ensure Cloudinary is initialized
        if not initialize_cloudinary():
            return None
        
        try:
            # Decode base64 image
            if "," in image_base64:
                # Handle data URL format: data:image/jpeg;base64,<data>
                image_base64 = image_base64.split(",")[1]
            
            image_data = base64.b64decode(image_base64)
            
            # Generate unique public_id
            ts = timestamp or datetime.utcnow()
            unique_id = f"{ts.strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
            
            # Upload to Cloudinary
            # Folder structure: predator_alert/{device_id}/
            result = cloudinary.uploader.upload(
                image_data,
                folder=f"predator_alert/{device_id}",
                public_id=unique_id,
                resource_type="image",
                format="jpg",
                overwrite=False,
                invalidate=True
            )
            
            # Return the secure HTTPS URL
            secure_url = result.get("secure_url")
            
            if secure_url:
                print(f"[+] Image uploaded to Cloudinary: {secure_url[:50]}...")
                return secure_url
            
            return None
            
        except Exception as e:
            # Never block detection ingestion on upload failure
            print(f"[!] Cloudinary upload error (non-blocking): {e}")
            return None
    
    @staticmethod
    async def delete_image(public_id: str) -> bool:
        """
        Delete an image from Cloudinary.
        
        Args:
            public_id: The public ID of the image to delete
            
        Returns:
            True if deleted successfully
        """
        if not initialize_cloudinary():
            return False
        
        try:
            result = cloudinary.uploader.destroy(public_id)
            return result.get("result") == "ok"
        except Exception as e:
            print(f"Error deleting from Cloudinary: {e}")
            return False
