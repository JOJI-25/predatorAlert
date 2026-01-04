"""Security utilities for API authentication."""

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
from app.config import get_settings


api_key_header = APIKeyHeader(name="Authorization", auto_error=False)


async def verify_api_key(api_key: str = Security(api_key_header)) -> str:
    """
    Verify the API key from the Authorization header.
    
    Expected format: Bearer <api_key>
    
    Returns:
        str: The validated API key
        
    Raises:
        HTTPException: If API key is missing or invalid
    """
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing API key in Authorization header"
        )
    
    # Extract key from "Bearer <key>" format
    if api_key.startswith("Bearer "):
        api_key = api_key[7:]
    
    settings = get_settings()
    valid_keys = settings.api_keys_list
    
    if not valid_keys:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No API keys configured on server"
        )
    
    if api_key not in valid_keys:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )
    
    return api_key
