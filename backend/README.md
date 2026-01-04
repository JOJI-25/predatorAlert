# Predator Alert System - Backend API

FastAPI backend for the Predator Alert System.

## Setup

```bash
# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Configure environment
copy .env.example .env
# Edit .env with your Firebase credentials
```

## Running

```bash
# Development
uvicorn app.main:app --reload --port 8000

# Production
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Docker

```bash
# Build
docker build -t predator-alert-api .

# Run
docker-compose up -d
```

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Testing

```bash
# Submit a test detection
curl -X POST http://localhost:8000/api/detections \
  -H "Authorization: Bearer device_key_01" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test_cam_01",
    "animal": "leopard",
    "confidence": 0.87
  }'
```
