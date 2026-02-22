print("db.py LOADED")

import os
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Function for engine generation
def get_engine():
    # Retrieve database connection parameters from environment variables
    db_user = os.getenv('PG_USER')
    db_password = os.getenv('PG_PASSWORD')
    db_host = os.getenv('PG_HOST')
    db_port = os.getenv('PG_PORT')
    db_name = os.getenv('PG_DBNAME')

    # Create the database connection string
    connection_string = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'

    # Create and return the SQLAlchemy engine
    engine = create_engine(connection_string)
    return engine