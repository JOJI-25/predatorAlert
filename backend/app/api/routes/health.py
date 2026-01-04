"""Health check endpoints."""

from fastapi import APIRouter
from datetime import datetime


router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring.
    
    Returns:
        Health status and server timestamp
    """
    return {
        "status": "healthy",
        "service": "predator-alert-api",
        "timestamp": datetime.utcnow().isoformat()
    }


@router.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "Predator Alert System API",
        "version": "1.0.0",
        "documentation": "/docs"
    }
