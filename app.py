from flask import Flask, Blueprint, request, jsonify, render_template
from pymongo import MongoClient
import os   

class VoteResult:
    @classmethod
    def insert_vote(cls, parameter, mongo):
        # Insert or update vote count in MongoDB
        mongo.db.vote_results.update_one(
            {"parameter": parameter},
            {"$inc": {"count": 1}},
            upsert=True
        )

    @classmethod
    def get_all_results(cls, mongo):
        # Retrieve all vote results from MongoDB
        return mongo.db.vote_results.find()

survey_routes = Blueprint('survey_routes', __name__)

@survey_routes.route('/')
def index():
    return render_template('index.html')

# Define route to handle voting
@survey_routes.route('/vote', methods=['POST'])
def vote():
    parameter = request.json.get('parameter')

    # Update vote count in MongoDB
    VoteResult.insert_vote(parameter, mongo)

    return jsonify({"message": "Vote submitted successfully"})

# Define route to render the HTML page displaying vote results
@survey_routes.route('/results')
def survey_results():
    # Assuming you have a collection named 'vote_results' in your MongoDB
    survey_data = VoteResult.get_all_results(mongo)
    parameters = []
    for data in survey_data:
        parameters.append({'name': data['parameter'], 'value': data['count']})
    return render_template('results.html', parameters=parameters)

mongo_username = os.environ.get('MONGO_INITDB_ROOT_USERNAME')
mongo_password = os.environ.get('MONGO_INITDB_ROOT_PASSWORD')
mongo_host = os.environ.get('MONGO_HOST')
mongo_port = os.environ.get('MONGO_PORT')

def create_app():
    app = Flask(__name__)
    

    # Configuration for MongoDB
    mongo_uri = f'mongodb://{mongo_username}:{mongo_password}@{mongo_host}:{mongo_port}/'
    client = MongoClient(mongo_uri)
    global mongo
    mongo = client.survey_db
    
    app.config["MONGO_URI"] = mongo_uri

    try:
        # Initialize MongoDB with the required collections
        if 'vote_results' not in mongo.list_collection_names():
            # Create 'vote_results' collection if it doesn't exist
            mongo.create_collection('vote_results')
            # Initialize vote counts to 0 for each parameter
            initial_parameters = ['parameter1', 'parameter2', 'parameter3']  # Add your parameters here
            for param in initial_parameters:
                mongo.vote_results.insert_one({"parameter": param, "count": 0})
    except Exception as e:
        print(f"Error initializing MongoDB: {e}")

    # Register blueprints
    app.register_blueprint(survey_routes)

    return app

app = create_app()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
