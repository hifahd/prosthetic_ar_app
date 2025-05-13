import pytest
from app import create_app
from app.models.database import db, Part
import io
import os

@pytest.fixture
def client():
    app = create_app()  # Assuming you have a testing config
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.session.remove()
            db.drop_all()


def test_create_part(client):

    file_path = os.path.join(os.path.dirname(__file__), "resources", "test.obj")

    with open(file_path, "rb") as f:
        data = {
            'name': 'Test Part',
            'type': 'OBJ',
            'file': (io.BytesIO(f.read()), 'test.obj')
        }
    
    response = client.post("/api/parts", data=data, content_type='multipart/form-data')

    assert response.status_code == 201, response.get_json()
    response_data = response.get_json()
    assert response_data['name'] == 'Test Part'
    assert response_data['type'] == 'OBJ'


def test_get_all_parts(client):
    # Add a test part first
    part = Part(name="Test Part", type="OBJ", file_path="/tests/resources/test.obj")
    db.session.add(part)
    db.session.commit()

    response = client.get("/api/parts")
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert data[0]["name"] == "Test Part"


def test_get_part(client):
    part = Part(name="Test Part", type="OBJ", file_path="/tests/resources/test.obj")
    db.session.add(part)
    db.session.commit()

    response = client.get(f"/api/parts/{part.id}")
    assert response.status_code == 200
    data = response.get_json()
    assert data["name"] == "Test Part"


def test_delete_part(client):
    part = Part(name="Test Part", type="OBJ", file_path="/tests/resources/test.obj")
    db.session.add(part)
    db.session.commit()

    response = client.delete(f"/api/parts/{part.id}")
    assert response.status_code == 200

    # Verify deletion
    response = client.get(f"/api/parts/{part.id}")
    assert response.status_code == 404
