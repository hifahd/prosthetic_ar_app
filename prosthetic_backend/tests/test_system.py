import os
import io
import sqlite3
import pytest
from io import BytesIO
from app import create_app
from app.models.database import Part, db

# ✅ Test Database Path
TEST_DB_PATH = "test_database.db"

# ✅ Setup Flask App for Testing
@pytest.fixture
def test_client():
    app = create_app()  
    app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{TEST_DB_PATH}"
    app.config["TESTING"] = True

    with app.app_context():
        db.create_all()
        yield app.test_client()
        db.drop_all()

# ✅ Test File Setup
@pytest.fixture
def test_file():
    return BytesIO(b"Mock 3D Model Data")  # Fake OBJ file content

# ✅ System Test for Upload
def test_valid_upload(test_client, test_file):
    """Test valid file upload using system functions"""
    
    # Simulate the uploaded file
    uploaded_file = test_file
    uploaded_file.name = "test.obj"  # Mimic real file name

    # Call system function directly (not API)
    new_part = Part(name="Test Part", type="OBJ", file_path="uploads/test.obj")
    db.session.add(new_part)
    db.session.commit()

    # Verify the file entry exists in the database
    part_in_db = Part.query.filter_by(name="Test Part").first()
    assert part_in_db is not None
    assert part_in_db.type == "OBJ"
    assert part_in_db.file_path == "uploads/test.obj"


# ✅ Test Upload Without Name
def test_upload_without_name(test_client, test_file):
    """Test uploading a file without providing a name"""
    uploaded_file = test_file
    uploaded_file.name = "test.obj"

    new_part = Part(name=None, type="OBJ", file_path="uploads/test.obj")
    db.session.add(new_part)

    with pytest.raises(Exception):  # Should fail due to a NULL constraint
        db.session.commit()

# ✅ Test Upload with Invalid Type
def test_upload_invalid_type(test_client, test_file):
    file_path = os.path.join(os.path.dirname(__file__), "resources", "test.txt")

    with open(file_path, "rb") as f:
        data = {
            'name': 'Test Part',
            'type': 'OBJ',
            'file': (io.BytesIO(f.read()), 'test.txt')
        }
    
    response = test_client.post("/api/parts", data=data, content_type='multipart/form-data')

    assert response.status_code == 400  # ❌ Should return an error
    assert response.json["error"] == "Invalid file type"  # ✅ Match exact message

# ✅ Test Upload Empty File
def test_upload_empty_file(test_client):
    """Test uploading an empty file"""
    empty_file = BytesIO(b"")  # No content
    empty_file.name = "empty.obj"

    new_part = Part(name="Empty File", type="OBJ", file_path="uploads/empty.obj")
    db.session.add(new_part)
    db.session.commit()

    part_in_db = Part.query.filter_by(name="Empty File").first()
    assert part_in_db is not None
    assert part_in_db.file_path == "uploads/empty.obj"

# ✅ Test Database Persistence
def test_database_persistence(test_client, test_file):
    """Ensure that records persist in the database across transactions"""
    uploaded_file = test_file
    uploaded_file.name = "test.obj"

    new_part = Part(name="Persistent Part", type="OBJ", file_path="uploads/test.obj")
    db.session.add(new_part)
    db.session.commit()

    db.session.close()  # Simulate session ending

    part_in_db = Part.query.filter_by(name="Persistent Part").first()
    assert part_in_db is not None
