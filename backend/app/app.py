from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from .config import Config
from .models import db

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    migrate = Migrate(app, db)
    CORS(app)
    jwt = JWTManager(app)

    from .routes import bp
    app.register_blueprint(bp)

    return app

app = create_app()

# Ensure we can use app.app_context()
def get_app():
    return app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)