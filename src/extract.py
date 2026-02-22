import pandas as pd
from src.utils import normalize_column
import logging

logging.basicConfig(level=logging.INFO)


#Extrating the data from the csv file
def extract_file(file_path: str):
    try:
        logging.info(f"Extracting data from file: {file_path}")
        df= pd.read_excel(file_path, sheet_name=None)
    
        for name, sheets in df.items():
            df[name]= normalize_column(sheets)

        return df

    except Exception as e:
        logging.error(f"Error extracting data from file: {e}")
        raise
