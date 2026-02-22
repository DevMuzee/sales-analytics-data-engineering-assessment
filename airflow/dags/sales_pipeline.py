from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
from main import run_pipeline

default_args = {
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
    "email": ["data-team@company.com"]
}

with DAG(
    dag_id="sales_pipeline",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args=default_args
) as dag:

    etl = PythonOperator(
        task_id="run_etl",
        python_callable=run_pipeline
    )

    dbt_run = BashOperator(
        task_id="run_dbt",
        bash_command="cd sales_dbt && dbt run && dbt test"
    )

    etl >> dbt_run