import pytest
import os
from src.app import create_app

@pytest.fixture
def app():
    os.environ['FLASK_ENV'] = 'testing'
    app = create_app('testing')
    app.config.update({
        'TESTING': True,
    })
    yield app

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def runner(app):
    return app.test_cli_runner()
