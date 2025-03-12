import os
from pathlib import Path

class Config:
    # Get the base directory of your project
    BASE_DIR = Path(__file__).resolve().parent
    
    # Configure upload folders
    UPLOAD_FOLDER = BASE_DIR / 'uploads'
    MERGED_FOLDER = BASE_DIR / 'merged'
    
    # File configurations
    ALLOWED_EXTENSIONS = {'stl', 'obj'}
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    
    # Database configuration
    SQLALCHEMY_DATABASE_URI = 'sqlite:///' + str(BASE_DIR / 'app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Flask configuration
    SECRET_KEY = 'dev'  # Change this in production