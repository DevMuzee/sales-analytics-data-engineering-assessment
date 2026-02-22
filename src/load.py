from sqlalchemy import create_engine
from src.extract import logging
from src.db import get_engine

def load_data_to_db(df, table_name, schema):
    engine = get_engine()

    try:
        logging.info(f"Loading data to database: {schema}.{table_name}")
        df.to_sql(
            table_name,
            engine,
            schema= schema,
            if_exists='replace',
            index=False
        )
        print(f"Data loaded successfully into {schema}.{table_name}")

    except Exception as e:
        logging.error(f"Error loading data to database: {e}")
        raise