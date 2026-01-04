# Predator Alert System

A production-grade wildlife threat detection and notification system.

## Architecture

```
Edge Device (Raspberry Pi + YOLO)
        ↓
Secure Backend API (FastAPI)
        ├── Cloudinary (image storage - FREE)
        ├── Firestore (metadata & logs)
        └── FCM (push notifications)
                ↓
Flutter Mobile Application
```

## Project Structure

```
PredatorAlert App/
├── backend/           # FastAPI backend
│   ├── app/           # Application code
│   ├── Dockerfile     # Container configuration
│   └── requirements.txt
├── firebase/          # Firebase configuration
│   ├── firestore.rules
│   └── setup-guide.md
└── flutter_app/       # Flutter mobile app
    ├── lib/           # Dart source code
    ├── android/       # Android configuration
    └── assets/        # Audio and images
```

## Quick Start

### 1. Cloudinary Setup (FREE, No Credit Card)

1. Sign up at [cloudinary.com](https://cloudinary.com)
2. Note your Cloud Name, API Key, and API Secret

### 2. Firebase Setup

See [firebase/setup-guide.md](firebase/setup-guide.md) for detailed instructions.

### 3. Backend Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Configure environment
copy .env.example .env
# Edit .env with your credentials

# Run the server
uvicorn app.main:app --reload
```

### 4. Flutter App Setup

```bash
cd flutter_app
flutter pub get
flutterfire configure
flutter run
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/detections` | Submit detection event |
| GET | `/health` | Health check |
| GET | `/docs` | Swagger documentation |

## Features

- 🔐 Secure device authentication
- ⏱️ Cooldown and deduplication
- 📷 Image upload to Cloudinary (FREE)
- 📝 Real-time detection logging
- 🚨 Push notifications for predators
- 🔊 Siren alarm in mobile app
- 📳 Vibration alerts
- 📊 Professional dark theme UI

## Cost

| Service | Cost |
|---------|------|
| Cloudinary | FREE (25GB storage) |
| Firebase Firestore | FREE tier available |
| Firebase FCM | FREE |

**No credit card required!**

## License

MIT License
