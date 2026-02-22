from src.extract import logging

def transform_data(df):
    try:
        logging.info("Transforming data")
        #Flag Null Distributors 
        df['is_missing_distributor']= df['distributor_id'].isnull()

        #Fill Null Distributors with 'Unknown'
        df['distributor_id']= df['distributor_id'].fillna('Unknown')

        #Excluding returned transaction type
        df= df[df['transaction_status'] != 'Returned']

        #Clean Notes
        df['notes']= df['notes'].fillna('No Notes')

        return df

    except Exception as e:
        logging.error(f"Error transforming data: {e}")
        raise
    
def transform_monthly_data(df):
    try:
        logging.info("Calculating Achievement Percentage")
        df['achievement_pct'] = ((
            df['actual_revenue_ngn'] / df['target_revenue_ngn']
        ) * 100).round(2)
        return df

    except Exception as e:
        logging.error(f"Error transforming monthly data: {e}")
        raise

