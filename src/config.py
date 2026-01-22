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


class Production:
    """
    Production environment configuration
    """

    DEBUG = False
    TESTING = False
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")


class Testing:
    """
    Testing environment configuration
    """

    DEBUG = True
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")


app_config = {
    "development": Development,
    "production": Production,
    "testing": Testing,
}
