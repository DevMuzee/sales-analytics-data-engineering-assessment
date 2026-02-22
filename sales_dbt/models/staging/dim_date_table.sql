{{config(MATERIALIZED= 'view')}}

SELECT 
    date,
    year,
    quarter,
    month,
    month_name,
    week,
    day_of_week,
    is_weekend,
    is_month_end
FROM raw.raw_date