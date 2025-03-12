from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def init_db(app):
    db.init_app(app)
    
    # Create all tables
    with app.app_context():
        db.create_all()

class Part(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    type = db.Column(db.String(50), nullable=False)
    file_path = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    model_metadata = db.Column(db.JSON)
    assemblies = db.relationship('AssemblyPart', back_populates='part')

class Assembly(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(50), default='draft')
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    updated_at = db.Column(db.DateTime, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
    merged_file_path = db.Column(db.String(200))
    parts = db.relationship('AssemblyPart', back_populates='assembly')

class AssemblyPart(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    assembly_id = db.Column(db.Integer, db.ForeignKey('assembly.id'), nullable=False)
    part_id = db.Column(db.Integer, db.ForeignKey('part.id'), nullable=False)
    position = db.Column(db.JSON)
    rotation = db.Column(db.JSON)
    scale = db.Column(db.JSON)
    assembly = db.relationship('Assembly', back_populates='parts')
    part = db.relationship('Part', back_populates='assemblies')