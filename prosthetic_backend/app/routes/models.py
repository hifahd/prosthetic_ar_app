from flask import Blueprint, request, jsonify, send_file
from ..services.model_service import ModelService
from ..models.database import Part
from werkzeug.utils import secure_filename
import os

bp = Blueprint('models', __name__)

def allowed_file(filename):
    ALLOWED_EXTENSIONS = {'stl', 'obj'}
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@bp.route('/parts', methods=['POST'])
def upload_part():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
        
    file = request.files['file']
    name = request.form.get('name', file.filename)
    type = request.form.get('type', 'unknown')
    
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
        
    if not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file type'}), 400
    
    try:
        part = ModelService.save_part(file, name, type)
        return jsonify({
            'id': part.id,
            'name': part.name,
            'type': part.type,
            'model_metadata': part.model_metadata
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/parts', methods=['GET'])
def get_parts():
    try:
        parts = ModelService.get_all_parts()
        return jsonify([{
            'id': part.id,
            'name': part.name,
            'type': part.type,
            'model_metadata': part.model_metadata
        } for part in parts])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@bp.route('/parts/<int:part_id>', methods=['GET'])
def get_part(part_id):
    try:
        part = ModelService.get_part(part_id)
        return jsonify({
            'id': part.id,
            'name': part.name,
            'type': part.type,
            'model_metadata': part.model_metadata
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 404

@bp.route('/parts/<int:part_id>', methods=['DELETE'])
def delete_part(part_id):
    try:
        ModelService.delete_part(part_id)
        return jsonify({'message': 'Part deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 404