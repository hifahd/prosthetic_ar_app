import json
import os
import subprocess
from datetime import datetime
from pathlib import Path


class BlenderService:
    @staticmethod
    def run_blender_script(script_path, *args):
        """Run a Blender Python script with arguments"""
        blender_path = "E:\\Blender 4.2\\blender.exe"  # or full path to Blender executable
        cmd = [
            blender_path,
            "--background",  # Run in background (no UI)
            "--python",
            script_path,
            "--"  # Anything after this will be passed to the script as args
        ] + list(args)
        
        try:
            subprocess.run(cmd, check=True)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error running Blender script: {e}")
            return False

    @staticmethod
    def merge_assembly(assembly_parts, output_path):
        """Merge assembly parts using Blender"""
        # Create a temporary Python script for Blender
        
        # Remove JSON parsing - assembly_parts is already a Python object
        # The following lines are removed:
        # try:
        #     assembly_parts = json.loads(assembly_parts)
        # except json.JSONDecodeError as e:
        #     print(f"Error decoding JSON: {e}")
        #     return False
        
        script_content = """
import bpy
import sys
import json
import os

# Get arguments passed to the script
argv = sys.argv
argv = argv[argv.index("--") + 1:]  # Get all args after "--"

# Parse the assembly data
assembly_data = json.loads(argv[0])
output_path = argv[1]

# Clear existing objects
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Enable addons for importing STL and OBJ if needed
addons_to_enable = ['io_mesh_stl', 'io_scene_obj']
for addon in addons_to_enable:
    try:
        bpy.ops.preferences.addon_enable(module=addon)
    except Exception as e:
        print(f"Warning: Could not enable addon {addon}: {str(e)}")

# Import and transform each part
for part in assembly_data:
    file_path = part['file_path']
    print(f"Importing file: {file_path}")
    
    # Check if file exists
    if not os.path.exists(file_path):
        print(f"Error: File does not exist: {file_path}")
        continue
    
    try:
        # Import the part based on file extension
        if file_path.lower().endswith('.stl'):
            try:
                bpy.ops.import_mesh.stl(filepath=file_path)
                print("STL import successful")
            except AttributeError:
                # Fallback method if import_mesh.stl is not available
                print("Trying alternative STL import method...")
                bpy.ops.wm.stl_import(filepath=file_path)
        elif file_path.lower().endswith('.obj'):
            try:
                bpy.ops.import_scene.obj(filepath=file_path)
                print("OBJ import successful")
            except AttributeError:
                print("Error: Could not import OBJ file")
        else:
            print(f"Unsupported file format: {file_path}")
            continue
            
        # Check if any objects were imported
        if len(bpy.context.selected_objects) == 0:
            print("Warning: No objects were imported")
            continue
            
        obj = bpy.context.selected_objects[0]
        
        # Apply transformations
        obj.location = (
            part['position']['x'],
            part['position']['y'],
            part['position']['z']
        )
        
        # Apply rotation
        obj.rotation_euler = (
            part['rotation']['x'],
            part['rotation']['y'],
            part['rotation']['z']
        )
        
        # Apply scale
        obj.scale = (
            part['scale']['x'],
            part['scale']['y'],
            part['scale']['z']
        )
    except Exception as e:
        print(f"Error processing part {file_path}: {str(e)}")

# Check if there are objects to join
if len(bpy.context.scene.objects) == 0:
    print("Error: No objects to merge")
    sys.exit(1)

# Select all objects and join them
bpy.ops.object.select_all(action='SELECT')
if len(bpy.context.selected_objects) > 0:
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    if len(bpy.context.selected_objects) > 1:
        bpy.ops.object.join()
    
    # Export the merged model
    try:
        bpy.ops.export_mesh.stl(filepath=output_path, use_selection=True)
        print(f"Successfully exported to {output_path}")
    except AttributeError:
        # Fallback export method
        print("Trying alternative STL export method...")
        bpy.ops.wm.stl_export(filepath=output_path)
        
else:
    print("Error: No objects to export")
    sys.exit(1)
"""
        # Create a temporary directory for the script
        temp_dir = Path("temp")
        temp_dir.mkdir(exist_ok=True)
        
        script_path = temp_dir / "merge_script.py"
        with open(script_path, "w") as f:
            f.write(script_content)
        
        # Prepare assembly data for the script
        assembly_data = []
        for part in assembly_parts:
            print("This is part: ", part)
            assembly_data.append({
                'file_path': part.part.file_path,  # Changed to access the part relationship
                'position': part.position,
                'rotation': part.rotation,
                'scale': part.scale
            })
        
        assembly_json = json.dumps(assembly_data)
        
        # Run the Blender script
        success = BlenderService.run_blender_script(
            str(script_path),
            assembly_json,
            output_path
        )
        
        # Clean up
        script_path.unlink()
        
        return success