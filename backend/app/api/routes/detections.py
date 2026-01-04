"""Detection API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import verify_api_key
from app.models.detection import DetectionRequest, DetectionResponse
from app.services.detection_service import DetectionService


router = APIRouter(prefix="/api", tags=["Detections"])


@router.post(
    "/detections",
    response_model=DetectionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit Detection Event",
    description="Submit a detection event from an edge device (Raspberry Pi). "
                "Requires valid API key authentication."
)
async def submit_detection(
    request: DetectionRequest,
    api_key: str = Depends(verify_api_key)
) -> DetectionResponse:
    """
    Process a detection event from an edge device.
    
    This endpoint:
    - Authenticates the device via API key
    - Validates the detection payload
    - Checks cooldown period
    - Uploads image to Firebase Storage (if present)
    - Stores detection record in Firestore
    - Triggers FCM alerts for predator detections
    
    Returns:
        DetectionResponse with processing results
    """
    response = await DetectionService.process_detection(request)
    
    if not response.success:
        # Still return 201 for cooldown (not a server error)
        if "cooldown" in response.message.lower():
            return response
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=response.message
        )
    
    return response


@router.get(
    "/detections/status",
    summary="Get Detection System Status",
    description="Check if detection system is operational"
)
async def detection_status(
    api_key: str = Depends(verify_api_key)
):
    """Get detection system operational status."""
    return {
        "operational": True,
        "cooldown_seconds": 30,
        "predator_animals": [
            "Bear", "Elephant", "Leopard", "Monkey", 
            "Snake", "Tiger", "Wild-Boar", "Porcupine"
        ]
    }
