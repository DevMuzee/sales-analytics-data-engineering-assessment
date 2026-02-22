

````markdown
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
    E --> F[Analytics / BI Tools]
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

## Airflow DAG Orchestration

**Location:** `airflow/dags/sales_pipeline_dag.py`
**Features:**

* PythonOperator → Runs ETL (`main.py`)
* BashOperator → Runs dbt transformations & tests
* Retry logic: 3 retries, 5 min delay
* Failure alerts via email
* DAG scheduling: Daily, `catchup=False`

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
python3.10 -m venv airflow/venv_airflow
# Activate venv
# Windows
airflow\venv_airflow\Scripts\activate
# Linux/Mac
source airflow/venv_airflow/bin/activate

pip install --upgrade pip
pip install -r requirement.txt

# Start Airflow
cd airflow
airflow standalone
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
│   ├── main.py
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
├── requirements_airflow.txt # Airflow dependencies
└── README.md
```

---

## Business Value

* Preserves **data integrity** by flagging missing distributors
* Provides **analytics-ready models** for BI dashboards
* Enables transparent revenue reporting, MoM growth analysis, and KPI tracking
* Demonstrates **best practices in data engineering** suitable for production and interviews


```
