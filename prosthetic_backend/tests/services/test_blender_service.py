import pytest
from unittest.mock import patch
from app.services.blender_service import BlenderService
import json

@patch("subprocess.run")
def test_run_blender_script(mock_subprocess):
    """Test running a Blender script."""
    mock_subprocess.return_value = None
    result = BlenderService.run_blender_script("script.py", "arg1", "arg2")
    assert result is True

@patch("app.services.blender_service.BlenderService.run_blender_script")
def test_merge_assembly(mock_run_script):
    """Test merging an assembly using Blender."""
    mock_run_script.return_value = True
    
    assembly_parts = [
        {
            "file_path": "/tests/resources/test.obj",
            "position": {"x": 0, "y": 0, "z": 0},
            "rotation": {"x": 0, "y": 0, "z": 0},
            "scale": {"x": 1, "y": 1, "z": 1}
        }
    ]
    
    assembly_json = json.dumps(assembly_parts)
    
    result = BlenderService.merge_assembly(assembly_json, "/output/path.stl")
    assert result is True
