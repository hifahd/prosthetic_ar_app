import trimesh
import numpy as np
from datetime import datetime
from pathlib import Path
from ..models.database import db, Part
from config import Config

class ModelService:
    @staticmethod
    def save_part(file, name, type):
        """Save a new part file and create database entry"""
        filename = f"{Path(file.filename).stem}_{int(datetime.utcnow().timestamp())}{Path(file.filename).suffix}"
        filepath = Path(Config.UPLOAD_FOLDER) / filename
        
        # Ensure directory exists
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Save file
        file.save(str(filepath))
        
        # Create database entry
        part = Part(
            name=name,
            type=type,
            file_path=str(filepath),
            model_metadata=ModelService.extract_metadata(filepath)  # Changed from metadata to model_metadata
        )
        db.session.add(part)
        db.session.commit()
        
        return part

    @staticmethod
    def extract_metadata(filepath):
        """Extract metadata from 3D model file"""
        mesh = trimesh.load(str(filepath))

        if isinstance(mesh, trimesh.Scene):
            if not mesh.geometry:  # No mesh data found
                raise ValueError("No geometry found in the provided scene file.")
            # Merge all meshes in the scene into one, or pick the first available mesh
            mesh = trimesh.util.concatenate(list(mesh.geometry.values()))

        return {
            'vertices': len(mesh.vertices),
            'faces': len(mesh.faces),
            'bounds': mesh.bounds if isinstance(mesh.bounds, list) else mesh.bounds.tolist(),
            'center_mass': mesh.center_mass if isinstance(mesh.center_mass, list) else mesh.center_mass.tolist()
        }

    @staticmethod
    def get_all_parts():
        """Get all parts from database"""
        return Part.query.all()

    @staticmethod
    def get_part(part_id):
        """Get specific part by ID"""
        return Part.query.get_or_404(part_id)

    @staticmethod
    def delete_part(part_id):
        """Delete a part and its associated file"""
        part = Part.query.get_or_404(part_id)
        
        # Delete file
        try:
            Path(part.file_path).unlink(missing_ok=True)
        except Exception as e:
            print(f"Error deleting file: {e}")
        
        # Delete database entry
        db.session.delete(part)
        db.session.commit()
        
        return True