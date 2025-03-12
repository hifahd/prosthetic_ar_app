from flask import Flask
from flask_cors import CORS
import os
import sys
from pathlib import Path

# Add the project root directory to Python path
sys.path.append(str(Path(__file__).resolve().parent.parent))

from config import Config
from .models.database import init_db

def create_app(config_class=Config):
    app = Flask(__name__)
    CORS(app)
    app.config.from_object(config_class)
    
    # Ensure upload directories exist
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    os.makedirs(app.config['MERGED_FOLDER'], exist_ok=True)
    
    # Initialize database
    init_db(app)
    
    # Import and register blueprints
    from app.routes.models import bp as models_bp
    from app.routes.assemblies import bp as assemblies_bp
    
    app.register_blueprint(models_bp, url_prefix='/api')
    app.register_blueprint(assemblies_bp, url_prefix='/api')
    
    @app.route('/')
    def index():
        return 'Backend is working!'
    
    @app.route('/test')
    def test_route():
        return 'Backend is working!'
        
    @app.errorhandler(404)
    def not_found_error(error):
        return {'error': 'Not found'}, 404
        
    @app.errorhandler(500)
    def internal_error(error):
        return {'error': 'Internal server error'}, 500
    
    return app