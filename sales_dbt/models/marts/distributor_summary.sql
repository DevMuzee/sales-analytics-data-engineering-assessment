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