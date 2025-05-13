import json

def test_create_assembly(client):
    """Test creating an assembly"""
    response = client.post('/api/assemblies', json={'name': 'Test Assembly'})
    assert response.status_code == 201
    data = response.get_json()
    assert data['name'] == 'Test Assembly'

def test_create_assembly_missing_name(client):
    """Test creating an assembly without a name"""
    response = client.post('/api/assemblies', json={})
    assert response.status_code == 400
    assert response.get_json() == {'error': 'Name is required'}

def test_get_assemblies(client):
    """Test retrieving assemblies"""
    response = client.get('/api/assemblies')
    assert response.status_code == 200
    assert isinstance(response.get_json(), list)
