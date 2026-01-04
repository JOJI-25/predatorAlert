# Firebase Setup Guide (Cloudinary Edition)

## Overview

This system uses:
- **Firebase Firestore** - Detection logs and metadata
- **Firebase Cloud Messaging** - Push notifications
- **Cloudinary** - Image storage (FREE, no credit card required)

> ⚠️ **Firebase Storage is NOT used** to avoid billing requirements.

---

## 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name: `predator-alert-system`
4. Enable Google Analytics (optional)
5. Click "Create project"

## 2. Enable Required Services

### Firestore Database
1. Go to **Build → Firestore Database**
2. Click "Create database"
3. Choose **Production mode**
4. Select region closest to your users
5. Click "Enable"

### Cloud Messaging (FCM)
1. Go to **Project Settings → Cloud Messaging**
2. FCM is enabled by default
3. Note your **Server Key** for backend use

### Authentication
1. Go to **Build → Authentication**
2. Click "Get started"
3. Enable **Email/Password** sign-in

> ⚠️ **DO NOT enable Firebase Storage** - We use Cloudinary instead

---

## 3. Create Cloudinary Account (FREE)

1. Go to [cloudinary.com](https://cloudinary.com)
2. Sign up for a **free account**
3. No credit card required!
4. Go to Dashboard and note:
   - **Cloud Name**
   - **API Key**
   - **API Secret**

### Free Tier Limits
- 25 GB storage
- 25 GB bandwidth/month
- Unlimited transformations

---

## 4. Generate Firebase Service Account

1. Go to **Project Settings → Service accounts**
2. Click "Generate new private key"
3. Save as `firebase-credentials.json`
4. Place in `backend/` directory
5. **⚠️ NEVER commit this file!**

---

## 5. Configure Flutter App

### Android Setup
1. Go to **Project Settings → General**
2. Click "Add app" → Android
3. Enter package name: `com.predatoralert.app`
4. Download `google-services.json`
5. Place in `flutter_app/android/app/`

---

## 6. Deploy Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /detections/{detectionId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /alert_config/{configId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

---

## 7. Backend Environment Variables

Create `.env` file in `backend/`:

```env
# Firebase (Firestore + FCM)
FIREBASE_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=./firebase-credentials.json

# Cloudinary (Image Storage)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# API Security
API_KEYS=device_key_01,device_key_02
COOLDOWN_SECONDS=30
```

---

## 8. Initialize Firestore Data

Create `alert_config/global` document:

```json
{
  "alert_enabled": true,
  "siren_enabled": true,
  "owner_contacts": [
    {"name": "Farm Owner", "phone": "+91XXXXXXXXXX"}
  ],
  "authority_contacts": [
    {"name": "Forest Dept", "phone": "+91XXXXXXXXXX"}
  ]
}
```

---

## 9. Test Image Upload

```bash
# Start backend
cd backend
uvicorn app.main:app --reload

# Test detection with image
curl -X POST http://localhost:8000/api/detections \
  -H "Authorization: Bearer device_key_01" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test_cam_01",
    "animal": "leopard",
    "confidence": 0.87,
    "image_base64": "/9j/4AAQSkZJRg..."
  }'
```

The response will include a Cloudinary URL:
```json
{
  "success": true,
  "image_url": "https://res.cloudinary.com/your-cloud/image/upload/..."
}
```

---

## Security Checklist

- [ ] Firebase credentials in `.gitignore`
- [ ] Cloudinary secrets in `.gitignore`
- [ ] Firestore rules deployed
- [ ] NO Firebase Storage enabled
- [ ] Flutter app has NO Cloudinary credentials
