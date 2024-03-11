from flask import Flask
from routes import survey_routes
from models import mongo

def create_app():
    app = Flask(__name__)
    
    # Configuration for MongoDB
    mongo_uri = f'mongodb://admin:admin@172.18.255.200:27017/'
    app.config["MONGO_URI"] = mongo_uri
    mongo.init_app(app)
    
    # Register blueprints
    app.register_blueprint(survey_routes)

    return app
