import pytest
import requests

BASE_URL = "http://localhost:5000"  # Change if using a different port

@pytest.fixture
def test_client():
    """Creates a test client for the API."""
    return requests.Session()

# 🛑 1️⃣ SQL Injection Test
def test_sql_injection(test_client):
    """Test SQL injection vulnerability"""
    data = {"name": "'; DROP TABLE part; --", "type": "OBJ"}
    response = test_client.post(f"{BASE_URL}/parts", data=data)
    assert response.status_code != 500, "SQL Injection caused server crash!"

# 🚫 2️⃣ Path Traversal Attack Test
def test_path_traversal(test_client):
    """Test path traversal attack"""
    files = {'file': ("../../etc/passwd", b"fake content")}
    data = {"name": "Traversal Test", "type": "OBJ"}
    response = test_client.post(f"{BASE_URL}/parts", files=files, data=data)
    assert response.status_code == 404, "Path traversal attack should be blocked!"

# 🛡️ 3️⃣ XSS (Cross-Site Scripting) Test
def test_xss_attack(test_client):
    """Test for Cross-Site Scripting (XSS)"""
    data = {"name": "<script>alert('Hacked')</script>", "type": "OBJ"}
    response = test_client.post(f"{BASE_URL}/parts", data=data)
    assert "<script>" not in response.text, "XSS attack succeeded!"

# 🔑 4️⃣ Unauthorized Access Test
def test_unauthorized_access(test_client):
    """Try accessing a restricted endpoint without authentication"""
    response = test_client.get(f"{BASE_URL}/admin")
    print("Unauthorized Access: ", response.status_code)
    assert response.status_code == 404, "Unauthorized access should be blocked!"

# 🚀 5️⃣ Privilege Escalation Test
def test_privilege_escalation(test_client):
    """Try deleting a part as a non-admin user"""
    headers = {"Authorization": "UserToken"}  # Replace with a normal user token
    response = test_client.delete(f"{BASE_URL}/parts/1", headers=headers)
    print("Privelege Escalation: ", response.status_code)
    assert response.status_code == 404, "Non-admin should not delete parts!"

# ⚠️ 6️⃣ Large File Upload Test (DoS Attack Simulation)

def test_large_file_upload():
    large_file = {'file': ('large_file.stl', b'a' * (600 * 1024 * 1024))}  # 600MB file

    try:
        response = requests.post(f"{BASE_URL}/parts", files=large_file)
        assert response.status_code == 413, f"Expected 413, got {response.status_code}"
        assert 'error' in response.json(), "Error message not found in response"
    except requests.exceptions.ConnectionError:
        print("✅ Flask forcefully rejected the large file (expected behavior)")

    print("✅ Flask correctly rejects large files!")

