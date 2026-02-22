{{config(MATERIALIZED= 'view')}}

SELECT
    salesperson_id :: text,
    salesperson_name,
    region,
    team,
    hire_date :: Date,
    monthly_target_ngn
FROM raw.raw_salespersons