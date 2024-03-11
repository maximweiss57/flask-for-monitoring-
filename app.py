from flask import Flask, Blueprint, request, jsonify, render_template
from flask_pymongo import PyMongo

mongo = PyMongo()

class VoteResult:
    @classmethod
    def insert_vote(cls, parameter):
        # Insert or update vote count in MongoDB
        mongo.db.vote_results.update_one(
            {"parameter": parameter},
            {"$inc": {"count": 1}},
            upsert=True
        )

    @classmethod
    def get_all_results(cls):
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
    VoteResult.insert_vote(parameter)

    return jsonify({"message": "Vote submitted successfully"})

# Define route to render the HTML page displaying vote results
@survey_routes.route('/results')
def survey_results():
    # Assuming you have a collection named 'vote_results' in your MongoDB
    survey_data = VoteResult.get_all_results()
    parameters = []
    for data in survey_data:
        parameters.append({'name': data['parameter'], 'value': data['count']})
    return render_template('results.html', parameters=parameters)
def create_app():
    app = Flask(__name__)
    
    # Configuration for MongoDB
    # mongo_uri = f'mongodb://localhost:27017/survey_db'
    mongo_uri = f'mongodb://admin:admin@172.18.255.200:27017/survey_db'
    app.config["MONGO_URI"] = mongo_uri

    try:
        mongo.init_app(app)

        # Initialize MongoDB with the required collections
        with app.app_context():
            if 'vote_results' not in mongo.db.list_collection_names():
                # Create 'vote_results' collection if it doesn't exist
                mongo.db.create_collection('vote_results')
                # Initialize vote counts to 0 for each parameter
                initial_parameters = ['parameter1', 'parameter2', 'parameter3']  # Add your parameters here
                for param in initial_parameters:
                    mongo.db.vote_results.insert_one({"parameter": param, "count": 0})
    except Exception as e:
        print(f"Error initializing MongoDB: {e}")

    # Register blueprints
    app.register_blueprint(survey_routes)

    return app


app=create_app()

if __name__ == "__main__":
    app.run(host='0.0.0.0',port=5000)
