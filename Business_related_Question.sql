SET search_path TO staging_staging;

--- Q1. Top 5 products by total revenue in 2024

SELECT
    p.product_name,
    SUM(t.revenue_ngn) AS total_revenue_2024
FROM stg_transactions t
JOIN dim_products p
    ON t.product_id = p.product_id
WHERE t.transaction_date >= DATE '2024-01-01'
  AND t.transaction_date < DATE '2025-01-01'
  AND t.is_missing_distributor = 'false'
GROUP BY p.product_name
ORDER BY total_revenue_2024 DESC
LIMIT 5;

---Q2. Region with highest MoM revenue growth in Q3 2024

WITH monthly_revenue AS (
    SELECT
        d.region,
        DATE_TRUNC('month', t.transaction_date) AS month,
        SUM(t.revenue_ngn) AS revenue
    FROM stg_transactions t
    JOIN dim_distributors d
        ON t.distributor_id = d.distributor_id
    WHERE t.transaction_date BETWEEN DATE '2024-07-01' AND DATE '2024-09-30'
      AND t.is_missing_distributor = 'false'
    GROUP BY d.region, month
),
mom_growth AS (
    SELECT
        region,
        month,
        revenue,
        revenue - LAG(revenue) OVER (
            PARTITION BY region ORDER BY month
        ) AS mom_growth
    FROM monthly_revenue
)
SELECT
    region,
    SUM(mom_growth) AS total_q3_growth
FROM mom_growth
WHERE mom_growth IS NOT NULL
GROUP BY region
ORDER BY total_q3_growth DESC
LIMIT 1;


---Q3. Average achievement % per salesperson
SELECT
    s.salesperson_name,
    AVG(mt.achievement_pct) AS avg_achievement_pct
FROM stg_monthly_tgt mt
JOIN dim_salespersons s
    ON mt.salesperson_id = s.salesperson_id
GROUP BY s.salesperson_name;


---Q4. Distributor with highest return rate
SELECT
    d.distributor_name,
    COUNT(*) FILTER (WHERE t.is_missing_distributor = 'true')::float
    / COUNT(*) AS return_rate
FROM stg_transactions t
JOIN dim_distributors d
    ON t.distributor_id = d.distributor_id
GROUP BY d.distributor_name
ORDER BY return_rate DESC
LIMIT 1;


---Q5. Rolling 3-month revenue trend by product category
WITH monthly_category_revenue AS (
    SELECT
        p.category,
        DATE_TRUNC('month', t.transaction_date) AS month,
        SUM(t.revenue_ngn) AS revenue
    FROM stg_transactions t
    JOIN dim_products p
        ON t.product_id = p.product_id
    WHERE t.is_missing_distributor = 'false'
    GROUP BY p.category, month
)
SELECT
    category,
    month,
    SUM(revenue) OVER (
        PARTITION BY category
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_revenue
FROM monthly_category_revenue
ORDER BY category, month;

