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
