"""
Module containing environment configurations
"""

import os


class Development:
    """
    Development environment configuration
    """

    DEBUG = True
    TESTING = False
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class Production:
    """
    Production environment configuration
    """

    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class Testing:
    """
    Testing environment configuration
    """

    DEBUG = True
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False


app_config = {
    "development": Development,
    "production": Production,
    "testing": Testing,
}
