from src.extract import extract_file, logging
from src.transform import transform_data, transform_monthly_data
from src.load import load_data_to_db
from sqlalchemy import create_engine



file_path = "data/FMN_DE_Sales_Assessment_Dataset.xlsx"

def run_pipeline():
    try:
        logging.info("ETL pipeline started")

        # ------Extract data-----
        logging.info("Extracting data from source")
        sheets = extract_file(file_path)
        logging.info("Data extraction completed")

        # ------Transform data
        transformed_data = transform_data(sheets['Transactions'])
        transformed_monthly_data = transform_monthly_data(sheets['Monthly_Targets'])
        logging.info("Data transformation completed")

        # -------Load data to database
        load_data_to_db(transformed_data, "raw_transactions", "raw")

        load_data_to_db(sheets["Products"], "raw_products", "raw")

        load_data_to_db(sheets["Distributors"], "raw_distributors", "raw")
        load_data_to_db(sheets["Salespersons"], "raw_salespersons", "raw")
        load_data_to_db(transformed_monthly_data, "raw_monthly_targets", "raw")
        load_data_to_db(sheets["Date_Table"], "raw_date", "raw")
    
    except Exception as e:
        logging.error(f"Error in ETL pipeline: {e}")
        raise


if __name__ == '__main__':
    run_pipeline()