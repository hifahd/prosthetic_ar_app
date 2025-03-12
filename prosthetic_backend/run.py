from datetime import datetime

from app import create_app
from app.models.database import Assembly, AssemblyPart, db
from flask import jsonify, request
from flask_cors import CORS

app = create_app()
CORS(app)  # Add this line to enable CORS

if __name__ == '__main__':
    app.run(debug=True)

@app.route('/api/assemblies/<int:assembly_id>', methods=['DELETE'])
def delete_assembly(assembly_id):
    try:
        # First, get the assembly to verify it exists
        assembly = Assembly.query.get_or_404(assembly_id)
        
        # Delete all associated assembly parts first
        AssemblyPart.query.filter_by(assembly_id=assembly_id).delete()
        
        # Then delete the assembly itself
        db.session.delete(assembly)
        
        # Commit all changes in a single transaction
        db.session.commit()
        
        return jsonify({'message': 'Assembly deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()  # Roll back on error
        return jsonify({'error': str(e)}), 500

@app.route('/api/assemblies/<int:assembly_id>', methods=['PUT'])
def update_assembly(assembly_id):
    data = request.get_json()
    try:
        assembly = Assembly.query.get_or_404(assembly_id)
        if 'name' in data:
            assembly.name = data['name']
        db.session.commit()
        return jsonify({'message': 'Assembly updated successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/assemblies/<int:assembly_id>/parts/<int:assembly_part_id>', methods=['DELETE'])
def remove_part(assembly_id, assembly_part_id):
    try:
        part = AssemblyPart.query.get_or_404(assembly_part_id)
        db.session.delete(part)
        db.session.commit()
        return jsonify({'message': 'Part removed successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500