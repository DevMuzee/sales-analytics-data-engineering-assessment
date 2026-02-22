{{ config(MATERIALIZED= 'table') }}

SELECT
    p.product_name,
    SUM(t.revenue_ngn) AS total_revenue_ngn
FROM {{ ref ('stg_transactions') }} t
JOIN raw.raw_products p 
    ON t.product_id = p.product_id
GROUP BY 1
