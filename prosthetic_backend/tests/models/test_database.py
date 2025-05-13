import pytest
from app.models.database import db, Part, Assembly, AssemblyPart

def test_create_part(client):
    """Test creating a Part in the database."""
    with client.application.app_context():
        part = Part(name="Test Part", type="mechanical", file_path="/path/to/test.obj")
        db.session.add(part)
        db.session.commit()

        retrieved_part = Part.query.first()
        assert retrieved_part is not None
        assert retrieved_part.name == "Test Part"
        assert retrieved_part.type == "mechanical"

def test_create_assembly(client):
    """Test creating an Assembly in the database."""
    with client.application.app_context():
        assembly = Assembly(name="Test Assembly", status="draft")
        db.session.add(assembly)
        db.session.commit()

        retrieved_assembly = Assembly.query.first()
        assert retrieved_assembly is not None
        assert retrieved_assembly.name == "Test Assembly"
        assert retrieved_assembly.status == "draft"

def test_create_assembly_part(client):
    """Test linking a Part to an Assembly using AssemblyPart."""
    with client.application.app_context():
        part = Part(name="Test Part", type="mechanical", file_path="/path/to/test.obj")
        assembly = Assembly(name="Test Assembly", status="draft")
        db.session.add_all([part, assembly])
        db.session.commit()

        # Create an AssemblyPart relationship
        assembly_part = AssemblyPart(assembly_id=assembly.id, part_id=part.id, position={}, rotation={}, scale={})
        db.session.add(assembly_part)
        db.session.commit()

        retrieved_assembly_part = AssemblyPart.query.first()
        assert retrieved_assembly_part is not None
        assert retrieved_assembly_part.assembly_id == assembly.id
        assert retrieved_assembly_part.part_id == part.id
