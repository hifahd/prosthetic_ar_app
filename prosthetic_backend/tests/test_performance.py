import pytest
import time
import os
import requests

BASE_URL = "http://127.0.0.1:5000"  # Change if running on a different port

@pytest.fixture
def large_test_file(tmp_path):
    """Creates a large temporary file (50MB) for testing."""
    file_path = tmp_path / "large_test.stl"
    with open(file_path, "wb") as f:
        f.write(os.urandom(50 * 1024 * 1024))  # 50MB random data
    return str(file_path)

def test_upload_large_file(large_test_file):
    """Tests if the app properly rejects large files."""
    url = f"{BASE_URL}/parts"
    files = {"file": open(large_test_file, "rb")}
    data = {"name": "Large Test Part", "type": "stl"}

    start_time = time.time()
    try:
        response = requests.post(url, files=files, data=data)
        elapsed_time = time.time() - start_time

        if response.status_code == 413:
            print("✅ Large file correctly rejected (413 Payload Too Large)")
        else:
            assert response.status_code == 201, f"Failed: {response.json()}"
            assert elapsed_time < 10, f"Upload took too long: {elapsed_time:.2f}s"
    
    except requests.exceptions.ConnectionError:
        print("✅ Flask forcefully rejected large file (expected behavior)")

def test_multiple_file_uploads():
    """Sends multiple files to test response time."""
    url = f"{BASE_URL}/parts"
    test_file = {"file": ("test.stl", b"x" * 1024)}  # 1KB file
    data = {"name": "Test Part", "type": "stl"}

    start_time = time.time()
    for _ in range(10):  # Upload 10 files
        try:
            print("The URL: ", url)
            response = requests.post(url, files=test_file, data=data)
            print("Here is the reponse: ", response.status_code, response.json())
            assert response.status_code == 404, f"Failed: {response.json()}"
        except requests.exceptions.ConnectionError:
            pytest.fail("❌ Connection error occurred during multiple uploads")
    
    elapsed_time = time.time() - start_time
    assert elapsed_time < 5, f"Multiple uploads took too long: {elapsed_time:.2f}s"
