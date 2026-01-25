from flask import Flask
import logging
from prometheus_flask_exporter import PrometheusMetrics
from .config import app_config
from .models import db
from .views.people import people_api as people

logger = logging.getLogger(__name__)


def create_app(env_name: str) -> Flask:
    """
    Initializes the application registers

    Parameters:
        env_name: the name of the environment to initialize the app with

    Returns:
        The initialized app instance
    """
    app = Flask(__name__)
    app.config.from_object(app_config[env_name])

    # Initialize Prometheus metrics
    metrics = PrometheusMetrics(app)
    metrics.info('app_info', 'Application info', version='1.0.0')

    # Initialize database
    db.init_app(app)

    logger.info(f"Application initialized with environment: {env_name}")

    app.register_blueprint(people, url_prefix="/")

    @app.route("/", methods=["GET"])
    def index():
        """
        Root endpoint for populating root route

        Returns:
            Greeting message
        """
        return """
        Welcome to the Titanic API
        """

    @app.route("/health", methods=["GET"])
    def health():
        """Health check endpoint"""
        return {"status": "healthy"}, 200

    return app
