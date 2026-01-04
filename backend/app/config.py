"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Firebase (Firestore + FCM only)
    firebase_project_id: str = ""
    google_application_credentials: str = "./firebase-credentials.json"
    google_application_credentials_json: str = ""  # New: for Render env var support
    
    # Cloudinary (Image Storage)
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""
    
    # API Security
    api_keys: str = ""
    
    # Detection Settings
    cooldown_seconds: int = 30
    predator_animals: str = "Bear,Elephant,Leopard,Monkey,Snake,Tiger,Wild-Boar,Porcupine"
    
    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False
    
    @property
    def api_keys_list(self) -> List[str]:
        """Parse API keys from comma-separated string."""
        return [key.strip() for key in self.api_keys.split(",") if key.strip()]
    
    @property
    def predator_animals_list(self) -> List[str]:
        """Parse predator animals from comma-separated string."""
        return [animal.strip().lower() for animal in self.predator_animals.split(",")]
    
    @property
    def cloudinary_configured(self) -> bool:
        """Check if Cloudinary credentials are configured."""
        return bool(
            self.cloudinary_cloud_name and 
            self.cloudinary_api_key and 
            self.cloudinary_api_secret
        )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
