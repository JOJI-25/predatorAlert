"""Firebase Admin SDK initialization for Firestore and FCM only.

Note: Image storage is handled by Cloudinary, NOT Firebase Storage.
"""

import os
from typing import Optional
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from app.config import get_settings


_firebase_app: Optional[firebase_admin.App] = None
_firestore_client = None


def initialize_firebase() -> None:
    """Initialize Firebase Admin SDK with service account credentials."""
    global _firebase_app, _firestore_client
    
    if _firebase_app is not None:
        return
    
    settings = get_settings()
    
    cred_path = settings.google_application_credentials
    json_creds = settings.google_application_credentials_json
    
    # Priority 1: JSON from environment variable (Render)
    if json_creds:
        import json
        try:
            cred_dict = json.loads(json_creds)
            cred = credentials.Certificate(cred_dict)
            print("[+] Loaded Firebase credentials from environment JSON")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in google_application_credentials_json: {e}")
            
    # Priority 2: File path (Local Development)
    elif os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        print(f"[+] Loaded Firebase credentials from file: {cred_path}")
        
    else:
        raise FileNotFoundError(
            f"Firebase credentials not found. Set GOOGLE_APPLICATION_CREDENTIALS_JSON env var or place file at {cred_path}"
        )
    
    # Initialize WITHOUT storage bucket (using Cloudinary instead)
    _firebase_app = firebase_admin.initialize_app(cred)
    
    _firestore_client = firestore.client()
    
    print(f"[+] Firebase initialized for project: {settings.firebase_project_id}")
    print("  - Firestore: Enabled")
    print("  - FCM: Enabled")
    print("  - Storage: Using Cloudinary instead")


def get_firestore():
    """Get Firestore client instance."""
    if _firestore_client is None:
        initialize_firebase()
    return _firestore_client


def get_firebase_app():
    """Get Firebase App instance."""
    if _firebase_app is None:
        initialize_firebase()
    return _firebase_app
