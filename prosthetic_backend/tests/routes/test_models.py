import io
import os 
def test_upload_part(client):
    """Test uploading a valid part"""
    file_path = os.path.join(os.path.dirname(__file__), "..", "resources", "test.obj")

    with open(file_path, "rb") as f:
        data = {
            'name': 'Test Part',
            'type': 'mechanical',
            'file': (io.BytesIO(f.read()), 'test.obj')
        }

    response = client.post('/api/parts', data=data, content_type='multipart/form-data')

    assert response.status_code == 201
    assert 'id' in response.get_json()

def test_upload_part_invalid_file(client):
    """Test uploading an invalid file type"""
    data = {
        'file': (io.BytesIO(b"fake file content"), 'test.txt')
    }
    response = client.post('/api/parts', data=data, content_type='multipart/form-data')
    assert response.status_code == 400
    assert response.get_json() == {'error': 'Invalid file type'}

def test_get_parts(client):
    """Test retrieving parts"""
    response = client.get('/api/parts')
    assert response.status_code == 200
    assert isinstance(response.get_json(), list)
