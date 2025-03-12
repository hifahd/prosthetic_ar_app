import os
from datetime import datetime
from pathlib import Path

from config import Config

from ..models.database import Assembly, AssemblyPart, db
from .blender_service import BlenderService


class AssemblyService:
    @staticmethod
    def create_assembly(name):
        """Create a new assembly"""
        assembly = Assembly(name=name)
        db.session.add(assembly)
        db.session.commit()
        return assembly

    @staticmethod
    def update_assembly(assembly_id, name):
        """Update an assembly's name"""
        assembly = Assembly.query.get_or_404(assembly_id)
        assembly.name = name
        assembly.updated_at = datetime.utcnow()
        db.session.commit()
        return assembly

    @staticmethod
    def delete_assembly(assembly_id):
        """Delete an assembly and its associated parts"""
        assembly = Assembly.query.get_or_404(assembly_id)
        
        # Delete any merged file if it exists
        if assembly.merged_file_path and os.path.exists(assembly.merged_file_path):
            try:
                os.remove(assembly.merged_file_path)
            except Exception as e:
                print(f"Warning: Could not delete merged file: {e}")
        
        # Delete from database
        db.session.delete(assembly)
        db.session.commit()
        return True

    @staticmethod
    def add_part_to_assembly(assembly_id, part_id, position, rotation, scale):
        """Add a part to an assembly with transformation data"""
        assembly_part = AssemblyPart(
            assembly_id=assembly_id,
            part_id=part_id,
            position=position,
            rotation=rotation,
            scale=scale
        )
        db.session.add(assembly_part)
        db.session.commit()
        return assembly_part

    @staticmethod
    def remove_part_from_assembly(assembly_id, assembly_part_id):
        """Remove a part from an assembly"""
        # Verify assembly exists
        assembly = Assembly.query.get_or_404(assembly_id)
        
        # Find the assembly part
        assembly_part = AssemblyPart.query.get_or_404(assembly_part_id)
        
        # Verify the part belongs to this assembly
        if assembly_part.assembly_id != assembly_id:
            raise ValueError("The specified part does not belong to this assembly")
        
        # Remove the part from the assembly
        db.session.delete(assembly_part)
        db.session.commit()
        
        # Update assembly status if it was 'complete'
        if assembly.status == 'complete':
            assembly.status = 'draft'
            assembly.updated_at = datetime.utcnow()
            db.session.commit()
        
        return True

    @staticmethod
    def merge_assembly(assembly_id):
        """Merge all parts in an assembly into a single model using Blender"""
        assembly = Assembly.query.get_or_404(assembly_id)
        
        if not assembly.parts:
            return None
            
        try:
            # Generate merged filename
            merged_filename = f"merged_{assembly_id}_{int(datetime.utcnow().timestamp())}.stl"
            merged_path = Path(Config.MERGED_FOLDER) / merged_filename
            merged_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Use Blender service to merge parts
            success = BlenderService.merge_assembly(
                assembly.parts,
                str(merged_path)
            )
            
            if success:
                # Update assembly
                assembly.merged_file_path = str(merged_path)
                assembly.status = 'complete'
                assembly.updated_at = datetime.utcnow()
                db.session.commit()
                
                return str(merged_path)
            else:
                raise Exception("Failed to merge assembly")
            
        except Exception as e:
            print(f"Error merging assembly: {str(e)}")
            raise

    @staticmethod
    def get_all_assemblies():
        """Get all assemblies"""
        return Assembly.query.all()

    @staticmethod
    def get_assembly(assembly_id):
        """Get specific assembly by ID"""
        return Assembly.query.get_or_404(assembly_id)