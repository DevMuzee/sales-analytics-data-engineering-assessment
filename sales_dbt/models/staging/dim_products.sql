{{config(MATERIALIZED= 'view')}}

SELECT
      product_id :: text,
      product_name,
      category,
      unit_price_ngn,
      unit_cost_ngn,
      pack_size,
      is_active :: boolean
FROM raw.raw_products
