{{config(MATERIALIZED= 'view')}}

SELECT
     distributor_id :: text,
     distributor_name,
     region,
     city,
     outlet_type,
     onboarding_date :: date,
     is_active :: boolean
FROM raw.raw_distributors