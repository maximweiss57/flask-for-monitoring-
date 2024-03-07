from flask import Flask
from routes import survey_routes
from models import mongo

def create_app():
    app = Flask(__name__)
    
    # Configuration for MongoDB
    app.config['MONGO_URI'] = 'mongodb://27017/survey_db'
    mongo.init_app(app)
    
    # Register blueprints
    app.register_blueprint(survey_routes)

    return app
