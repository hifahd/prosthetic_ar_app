import pytest
from app.models.database import db, Assembly, Part, AssemblyPart
from app.services.assembly_service import AssemblyService

def test_create_assembly(client):
    """Test creating a new assembly."""
    with client.application.app_context():
        assembly = AssemblyService.create_assembly("Test Assembly")
        assert assembly is not None
        assert assembly.name == "Test Assembly"

def test_add_part_to_assembly(client):
    """Test adding a part to an assembly."""
    with client.application.app_context():
        part = Part(name="Test Part", type="mechanical", file_path="/path/to/part.obj")
        assembly = AssemblyService.create_assembly("Test Assembly")
        db.session.add(part)
        db.session.commit()

        assembly_part = AssemblyService.add_part_to_assembly(
            assembly.id, part.id, {"x": 0, "y": 0, "z": 0}, 
            {"x": 0, "y": 0, "z": 0}, {"x": 1, "y": 1, "z": 1}
        )
        
        assert assembly_part is not None
        assert assembly_part.assembly_id == assembly.id
        assert assembly_part.part_id == part.id

def test_merge_assembly(client, mocker):
    """Test merging an assembly using BlenderService."""
    with client.application.app_context():
        part = Part(name="Test Part", type="mechanical", file_path="/path/to/part.obj")
        assembly = AssemblyService.create_assembly("Test Assembly")
        db.session.add(part)
        db.session.commit()
        AssemblyService.add_part_to_assembly(assembly.id, part.id, {}, {}, {})

        mocker.patch("app.services.assembly_service.BlenderService.merge_assembly", return_value=True)
        
        merged_path = AssemblyService.merge_assembly(assembly.id)
        assert merged_path is not None
        assert assembly.merged_file_path is not None
