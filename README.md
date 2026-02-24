# Sales Analytics Pipeline

## Project Overview
This project implements a **production-style sales analytics pipeline** using a single Excel file as source.  
It ingests, cleans, transforms, and loads data into **PostgreSQL** using Python ETL, applies analytics-ready modeling with **dbt**, and orchestrates the workflow with **Apache Airflow**.  

**Key Engineering Principles Applied:**  
- Modular code and package structure  
- Clear separation of concerns: ETL vs transformation vs orchestration  
- Explicit data quality handling (flagging missing or inconsistent data)  
- Environment-based configuration (`.env`)  
- Analytics-ready fact and dimension models  

---

## Architecture Overview

```mermaid
graph TD
    A[Excel Source File] --> B[Python ETL: Extract → Transform → Load]
    B --> C[PostgreSQL: Raw Schema]
    C --> D[dbt: Staging Models]
    D --> E[dbt: Mart Models]
    E --> F[Apache Airflow]
    B -. Data Quality Flags .-> C
    D -. Tests / Validation .-> E
````

**Layer Responsibilities:**

| Layer       | Responsibility                                                                             |
| ----------- | ------------------------------------------------------------------------------------------ |
| Python ETL  | Reads Excel sheets, applies transformations, flags missing/returned data, loads raw tables |
| dbt Staging | Cleans and standardizes raw tables, applies derived flags and types                        |
| dbt Mart    | Aggregates data for analytics, computes business metrics                                   |
| Airflow     | Orchestrates ETL → dbt workflow, retries, alerts                                           |

---

## Source Data & Schema Design

All source data is stored in a single Excel file: `data/sales_data.xlsx`.

| Sheet Name      | Type | Description                      |
| --------------- | ---- | -------------------------------- |
| Transactions    | FACT | Sales transactions (~3,500 rows) |
| Products        | DIM  | Product SKUs and categories      |
| Distributors    | DIM  | Distributor accounts and regions |
| Salespersons    | DIM  | Field reps and targets           |
| Monthly_Targets | FACT | Target vs actual sales           |
| Date_Table      | DIM  | Calendar dimension               |

**Known Data Quality Issues:**

* ~2% of `distributor_id` in Transactions are NULL → flagged, not dropped
* `transaction_status` may contain `Returned` → excluded from revenue
* `monthly_targets.achievement_pct` is computed during transform
* Mixed NULLs and strings in `notes` column
* Column names inconsistent

**PostgreSQL Schemas:**

| Schema  | Owner      | Purpose                     |
| ------- | ---------- | --------------------------- |
| raw     | Python ETL | Raw ingestion               |
| staging | dbt        | Cleaned & standardized data |
| mart    | dbt        | Business-ready aggregations |

> Python ETL writes only to **raw**, dbt writes to **staging** and **mart** schemas.

---

## ETL Pipeline Logic

### Python ETL

**Modules in `src/`:**

* `extract.py` → Reads all sheets, normalizes columns
* `transform.py` → Applies business rules, flags missing/returned data, computes metrics
* `load.py` → Writes data to PostgreSQL raw schema
* `db.py` → Database connection using SQLAlchemy
* `utils.py` → Helper functions
* `main.py` → Orchestrates ETL sequence

**Run locally:**

```bash
python src/main.py
```

### dbt Transformations

* **Staging Layer** → Cleans raw data, applies derived flags, enforces types
* **Mart Layer** → Aggregates revenue, computes performance metrics, prepares analytics tables

```bash
cd sales_dbt
dbt run
dbt test
```

**Example SQL (Mart Layer):**

```sql
{{ config(materialized='table') }}

SELECT
    COALESCE(d.region, 'Unknown_Area') AS region,

    COUNT(*) FILTER (
        WHERE t.is_missing_distributor = TRUE
    ) AS missing_distributor_count,

    ROUND(
        SUM(t.revenue_ngn) FILTER (
            WHERE t.is_missing_distributor = FALSE
        )
    ) AS distributor_revenue_ngn,

    ROUND(
        SUM(t.revenue_ngn) FILTER (
            WHERE t.is_missing_distributor = TRUE
        )
    ) AS unattributed_revenue_ngn,

    ROUND(SUM(t.revenue_ngn)) AS total_revenue_ngn

FROM {{ ref('stg_transactions') }} t
LEFT JOIN raw.raw_distributors d
    ON t.distributor_id = d.distributor_id
GROUP BY 1
ORDER BY total_revenue_ngn DESC
```

---

## Apache Airflow DAG Orchestration

**Location:** `airflow/dags/sales_pipeline_dag.py`
**Purpose**: `Orchestrates ETL → dbt pipeline, retries tasks, alerts on failure`
**Features:**

* PythonOperator → Runs ETL (`main.py`)
* BashOperator → Runs dbt transformations & tests
* Retry logic: 3 retries, 5 min delay
* Failure alerts via email
* DAG scheduling: Daily, `catchup=False`

## Airflow Setup (WSL/Linux Recommended)

**Key Steps I followed:**

1. Removed broken/partial installations:
```bash
rm -rf ~/airflow_runtime
```

2. Created a clean WSL directory for Airflow:
```bash
mkdir ~/airflow_runtime
cd ~/airflow_runtime
python3.10 -m venv venv_airflow
source venv_airflow/bin/activate
```

3. Installed Airflow with official constraints:
```bash
pip install "apache-airflow==2.9.3" \
  --constraint https://raw.githubusercontent.com/apache/airflow/constraints-2.9.3/constraints-3.10.txt
```
4. Set `AIRFLOW_HOME` and initialized the metadata DB:
```bash
export AIRFLOW_HOME=~/airflow_runtime/airflow
airflow db init
```

> Encountered issues like no such table: dag and slot_pool due to partial DB creation, resolved by resetting the DB:
```bash
airflow db reset
```

5. Copied DAGs from local project (avoiding OneDrive paths):

```bash
cp "/mnt/c/Users/TGOPS/OneDrive - Tolaram Pte Ltd/Project compilation/sales_analytics_pipeline/airflow/dags/sales_pipeline.py" ~/airflow_runtime/airflow/dags/
```

6. Started Airflow standalone:
```bash
airflow standalone
```

7. Verified DAGs:
```bash
airflow dags list
airflow dags list-import-errors
```

> Ensured all Python dependencies (pandas, psycopg2-binary, dbt-core) were installed in the venv to avoid import errors.

**Note**: All Airflow runtime files (`venv_airflow/, airflow.db, logs/`) are environment-specific and not pushed to GitHub; only DAGs and helper modules are tracked.

**Note:** Airflow uses **Python 3.10** to avoid conflicts; ETL/dbt run on Python 3.11+.

---

## Business Questions & Queries

1. Top 5 products by revenue in 2024 → `stg_transactions + stg_products`
2. Region with highest MoM revenue growth in Q3 2024 → `stg_transactions + stg_distributors`
3. Average achievement % per salesperson → `stg_monthly_targets + stg_salespersons`
4. Distributor with highest return rate → `stg_transactions + stg_distributors`
5. Rolling 3-month revenue trend by product category → `stg_transactions + stg_products`

---

## Running the Project Locally

### 1. Main ETL + dbt

```bash
# Create virtual environment
python -m venv venv
# Activate venv
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

# Run ETL
python src/main.py

# Run dbt models
cd sales_dbt
dbt run
dbt test
```

### 2. Airflow Environment

```bash
# Python 3.10 virtual environment for Airflow
# Activate Airflow venv
source ~/airflow_runtime/venv_airflow/bin/activate
# Windows
airflow\venv_airflow\Scripts\activate
# Linux/Mac
source airflow/venv_airflow/bin/activate

pip install --upgrade pip
pip install -r requirement.txt

# Start Airflow
cd airflow
airflow standalone

#Check DAGs
airflow dags list
```
---

## Key Engineering Highlights

* **Column normalization at ingestion** → Consistent data for transformations
* **Data quality via flags** → No rows dropped unnecessarily
* **Separation of concerns** → ETL → dbt → Airflow
* **Environment-based configuration** → `.env` for DB credentials
* **Production-ready repo structure** → Clean, modular, reproducible

---

## Folder Structure

```
sales-analytics-pipeline/
├── .env                   # DB credentials
├── data/                  # Excel source file
├── src/                   # Python ETL
│   ├── extract.py
│   ├── transform.py
│   ├── load.py
│   ├── db.py
│   └── utils.py
├── sales_dbt/             # dbt models
│   ├── models/
│   │   ├── staging/
│   │   └── marts/
│   └── dbt_project.yml
├── airflow/
│   ├── dags/
│   │   └── sales_pipeline_dag.py
│   └── venv_airflow/
├── requirements.txt       # ETL + dbt dependencies
├── main.py
└── README.md
```

---

## Business Value

* Preserves **data integrity** by flagging missing distributors
* Provides **analytics-ready models** for BI dashboards
* Enables transparent revenue reporting, MoM growth analysis, and KPI tracking
* Demonstrates **best practices in data engineering** suitable for production and interviews


```
