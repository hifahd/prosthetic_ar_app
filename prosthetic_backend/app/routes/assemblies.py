from flask import Blueprint, jsonify, request, send_file

from ..models.database import Assembly, Part
from ..services.assembly_service import AssemblyService

bp = Blueprint('assemblies', __name__)

@bp.route('/assemblies', methods=['POST'])
def create_assembly():
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({'error': 'Name is required'}), 400
    
    try:
        assembly = AssemblyService.create_assembly(data['name'])
        return jsonify({
            'id': assembly.id,
            'name': assembly.name,
            'status': assembly.status
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/assemblies/<int:assembly_id>', methods=['PUT'])
def update_assembly(assembly_id):
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({'error': 'Name is required'}), 400
    
    try:
        assembly = AssemblyService.update_assembly(assembly_id, data['name'])
        return jsonify({
            'id': assembly.id,
            'name': assembly.name,
            'status': assembly.status
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 404

@bp.route('/assemblies/<int:assembly_id>', methods=['DELETE'])
def delete_assembly(assembly_id):
    try:
        # First, delete all associated assembly parts
        from ..models.database import AssemblyPart, db

        # Delete all related assembly parts first
        AssemblyPart.query.filter_by(assembly_id=assembly_id).delete()
        db.session.commit()
        
        # Then delete the assembly
        AssemblyService.delete_assembly(assembly_id)
        return jsonify({'message': 'Assembly deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 404

@bp.route('/assemblies/<int:assembly_id>/parts/<int:assembly_part_id>', methods=['DELETE'])
def remove_part_from_assembly(assembly_id, assembly_part_id):
    try:
        AssemblyService.remove_part_from_assembly(assembly_id, assembly_part_id)
        return jsonify({'message': 'Part removed from assembly successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 404

@bp.route('/assemblies/<int:assembly_id>/parts', methods=['POST'])
def add_part_to_assembly(assembly_id):
    data = request.get_json()
    required_fields = ['part_id']
    if not data or not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    try:
        # Verify part exists before adding
        part_id = data['part_id']
        part = Part.query.get(part_id)
        if not part:
            return jsonify({'error': f'Part with ID {part_id} not found'}), 404
            
        # Log part being added for debugging
        print(f"Adding part {part_id} ({part.name}) to assembly {assembly_id}")
            
        assembly_part = AssemblyService.add_part_to_assembly(
            assembly_id=assembly_id,
            part_id=part_id,
            position=data.get('position', {'x': 0, 'y': 0, 'z': 0}),
            rotation=data.get('rotation', {'angle': 0, 'x': 0, 'y': 0, 'z': 1}),
            scale=data.get('scale', {'x': 1, 'y': 1, 'z': 1})
        )
        
        # Include part data in response
        return jsonify({
            'assembly_part_id': assembly_part.id,
            'part_id': assembly_part.part_id,
            'part_data': {
                'id': part.id,
                'name': part.name,
                'type': part.type
            },
            'position': assembly_part.position,
            'rotation': assembly_part.rotation,
            'scale': assembly_part.scale
        }), 201
    except Exception as e:
        print(f"Error adding part to assembly: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@bp.route('/assemblies/<int:assembly_id>/merge', methods=['POST', 'GET'])
def merge_assembly(assembly_id):
    try:
        merged_path = AssemblyService.merge_assembly(assembly_id)
        if merged_path:
            return send_file(merged_path, as_attachment=True)
        return jsonify({'error': 'No parts to merge'}), 400
    except Exception as e:
        print(f"Error merging assembly: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@bp.route('/assemblies', methods=['GET'])
def get_assemblies():
    try:
        assemblies = AssemblyService.get_all_assemblies()
        return jsonify([{
            'id': assembly.id,
            'name': assembly.name,
            'status': assembly.status,
            'created_at': assembly.created_at,
            'updated_at': assembly.updated_at
        } for assembly in assemblies])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/assemblies/<int:assembly_id>', methods=['GET'])
def get_assembly(assembly_id):
    try:
        assembly = AssemblyService.get_assembly(assembly_id)
        
        # Get all part data in one query to avoid multiple requests
        assembly_parts = []
        for assembly_part in assembly.parts:
            try:
                # Always load the part directly from the database for consistency
                part = Part.query.get(assembly_part.part_id)
                
                if part:
                    part_data = {
                        'id': part.id,
                        'name': part.name,
                        'type': part.type
                    }
                else:
                    part_data = {
                        'id': None,
                        'name': f'Missing Part (ID: {assembly_part.part_id})',
                        'type': 'undefined'
                    }
                
                assembly_parts.append({
                    'assembly_part_id': assembly_part.id,
                    'part_id': assembly_part.part_id,
                    'part_data': part_data,
                    'position': assembly_part.position,
                    'rotation': assembly_part.rotation,
                    'scale': assembly_part.scale
                })
            except Exception as inner_e:
                print(f"Error processing part {assembly_part.id}: {str(inner_e)}")
                # Still include the part in the response, but with error info
                assembly_parts.append({
                    'assembly_part_id': assembly_part.id,
                    'part_id': assembly_part.part_id,
                    'part_data': {
                        'id': None,
                        'name': 'Error loading part',
                        'type': 'error'
                    },
                    'position': assembly_part.position,
                    'rotation': assembly_part.rotation,
                    'scale': assembly_part.scale
                })
        
        return jsonify({
            'id': assembly.id,
            'name': assembly.name,
            'status': assembly.status,
            'created_at': assembly.created_at,
            'updated_at': assembly.updated_at,
            'parts': assembly_parts
        })
    except Exception as e:
        import traceback
        print(f"Error in get_assembly: {str(e)}")
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 404