from flask import Blueprint, request, jsonify, render_template
from models import mongo, VoteResult

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
    # Assuming you have a collection named 'survey_results' in your MongoDB
    survey_data = mongo.db.vote_results.find()
    parameters = []
    for data in survey_data:
        parameters.append({'name': data['parameter'], 'value': data['count']})
    return render_template('results.html', parameters=parameters)
