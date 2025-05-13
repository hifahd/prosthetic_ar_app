from locust import HttpUser, task, between

class UploadLoadTest(HttpUser):
    wait_time = between(1, 2)  # Simulates user delay

    @task
    def upload_file(self):
        """Simulates multiple users uploading files at once."""
        files = {"file": ("test.stl", b"x" * 1024 * 100)}  # 100KB file
        data = {"name": "Load Test Part", "type": "stl"}
        self.client.post("/parts", files=files, data=data)

