import pytest
from unittest.mock import MagicMock, patch
from app.services.model_service import ModelService
from app.models.database import Part
from werkzeug.datastructures import FileStorage
import io

@pytest.fixture
def test_file():
    """Creates a mock file object for testing."""
    file_path = "tests/resources/test.obj"
    with open(file_path, "rb") as f:
        return FileStorage(stream=f, filename="test.obj", content_type="application/octet-stream")

@pytest.fixture
def mock_db_session():
    """Mock the database session."""
    with patch("app.models.database.db.session") as mock_session:
        yield mock_session

@pytest.fixture
def mock_config():
    """Mock the configuration upload folder."""
    with patch("config.Config.UPLOAD_FOLDER", "tests/uploads"):
        yield

@pytest.fixture
def mock_trimesh():
    """Mock trimesh.load function."""
    mock_mesh = MagicMock()
    mock_mesh.vertices = [[0, 0, 0], [1, 1, 1]]
    mock_mesh.faces = [[0, 1, 2]]
    mock_mesh.bounds = [[0, 0, 0], [1, 1, 1]]
    mock_mesh.center_mass = [0.5, 0.5, 0.5]
    
    with patch("trimesh.load", return_value=mock_mesh):
        yield

def test_save_part(mock_db_session, mock_config, mock_trimesh):
    """Test saving a part."""
    test_file = FileStorage(
        stream=io.BytesIO(b"test content"),
        filename="/tests/resources/test.obj",
        content_type="application/octet-stream"
    )

    test_file.seek(0)  # Ensure the file is readable before saving

    part = ModelService.save_part(test_file, "Test Part", "OBJ")
    assert part is not None
    assert part.name == "Test Part"


def test_get_all_parts(mock_db_session):
    """Test retrieving all parts."""
    # Mock Part.query.all() directly
    with patch.object(Part, "query") as mock_query:
        mock_query.all.return_value = [
            Part(id=1, name="Test Part", type="OBJ", file_path="/tests/resources/test.obj")
        ]

        parts = ModelService.get_all_parts()

        assert len(parts) == 1
        assert parts[0].name == "Test Part"


def test_get_part(mock_db_session):
    """Test retrieving a specific part."""
    with patch.object(Part, "query") as mock_query:
        mock_query.get_or_404.return_value = Part(
            id=1, name="Test Part", type="OBJ", file_path="/tests/resources/test.obj"
        )

        part = ModelService.get_part(1)
        print("Returned Part:", part)  # Debugging

        assert part is not None
        assert part.name == "Test Part"
        assert part.type == "OBJ"


def test_delete_part(mock_db_session):
    """Test deleting a part."""
    part = Part(id=1, name="Test Part", type="OBJ", file_path="tests/uploads/test.obj")
    mock_db_session.query.return_value.get_or_404.return_value = part
    
    # Mock file deletion
    with patch("pathlib.Path.unlink") as mock_unlink:
        result = ModelService.delete_part(1)

        mock_unlink.assert_called_once()  # Ensure file deletion is attempted
        assert result is True