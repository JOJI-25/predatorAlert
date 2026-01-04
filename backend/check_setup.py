
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

from app.config import get_settings
from app.core.firebase import initialize_firebase
from app.services.cloudinary_service import initialize_cloudinary

def check_setup():
    print("🔍 Checking Backend Setup...\n")
    
    settings = get_settings()
    
    # 1. Environment Variables
    print(f"1. Loading Configuration...")
    if not settings.firebase_project_id:
        print("❌ FIREBASE_PROJECT_ID missing")
    else:
        print(f"✅ Project ID: {settings.firebase_project_id}")
        
    if not settings.cloudinary_configured:
        print("❌ Cloudinary credentials missing")
    else:
        print(f"✅ Cloudinary Configured (Cloud Name: {settings.cloudinary_cloud_name})")

    # 2. Firebase Connection
    print(f"\n2. Testing Firebase Connection...")
    try:
        initialize_firebase()
        print("✅ Firebase initialized successfully")
    except Exception as e:
        print(f"❌ Firebase error: {e}")

    # 3. Cloudinary Connection
    print(f"\n3. Testing Cloudinary Connection...")
    try:
        success = initialize_cloudinary()
        if success:
            print("✅ Cloudinary initialized successfully")
        else:
            print("❌ Cloudinary failed to initialize")
    except Exception as e:
        print(f"❌ Cloudinary error: {e}")

if __name__ == "__main__":
    check_setup()
