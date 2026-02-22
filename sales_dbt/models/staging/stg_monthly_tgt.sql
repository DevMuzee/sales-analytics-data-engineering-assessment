{{config(MATERIALIZED= 'view')}}

SELECT record_id :: Text,
        salesperson_id :: Text,
        year,
        month,
        region,
        target_revenue_ngn:: numeric,
        actual_revenue_ngn:: numeric,
        achievement_pct :: numeric
FROM raw.raw_monthly_targets