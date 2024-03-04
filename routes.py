from flask import Blueprint, request, jsonify, render_template
from models import mongo

survey_routes = Blueprint('survey_routes', __name__)

@survey_routes.route('/', methods=['GET'])
def home():
    return render_template('index.html')

@survey_routes.route('/survey', methods=['POST'])
def survey():
    # Handle survey submission
    # Here you would save survey data to MongoDB
    return jsonify({"message": "Survey submitted successfully"})

@survey_routes.route('/dashboard')
def dashboard():
    # Retrieve survey data from MongoDB
    # Here you would fetch data and render the dashboard
    return "Dashboard"
