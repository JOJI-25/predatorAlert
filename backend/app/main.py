"""
Predator Alert System - FastAPI Backend

Main application entry point with Firebase initialization and route registration.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.core.firebase import initialize_firebase
from app.api.routes import health, detections


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.
    
    Handles initialization on startup and cleanup on shutdown.
    """
    # Startup
    print("[*] Starting Predator Alert API...")
    
    settings = get_settings()
    
    # Initialize Firebase (Firestore + FCM)
    try:
        initialize_firebase()
    except FileNotFoundError as e:
        print(f"[!] Firebase not initialized: {e}")
        print("   The API will start but Firebase operations will fail.")
    except Exception as e:
        print(f"[!] Firebase initialization error: {e}")
    
    # Initialize Cloudinary
    from app.services.cloudinary_service import initialize_cloudinary
    initialize_cloudinary()
    
    print(f"[+] API ready on {settings.host}:{settings.port}")
    
    yield
    
    # Shutdown
    print("[*] Shutting down Predator Alert API...")


# Create FastAPI application
app = FastAPI(
    title="Predator Alert System API",
    description="""
## Predator Alert System Backend

This API receives detection events from edge devices (Raspberry Pi + YOLO),
processes them, and triggers real-time alerts through Firebase.

### Architecture
- **Edge Devices** → This API → **Firebase** → **Flutter App**

### Features
- 🔐 Device authentication via API keys
- ⏱️ Cooldown & deduplication logic
- 📷 Image upload to Firebase Storage
- 📝 Detection logging to Firestore
- 🚨 Push notifications via FCM

### Authentication
All detection endpoints require an API key in the Authorization header:
```
Authorization: Bearer <your-api-key>
```
    """,
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)


# CORS middleware for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Register routes
app.include_router(health.router)
app.include_router(detections.router)


if __name__ == "__main__":
    import uvicorn
    
    settings = get_settings()
    
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )
