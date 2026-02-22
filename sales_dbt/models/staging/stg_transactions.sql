{{config(MATERIALIZED= 'view')}}

SELECT transaction_id :: Text,
        transaction_date :: Date,
        product_id :: text,
        distributor_id :: text,
        salesperson_id :: text,
        quantity ::int,
        unit_price_ngn,
        discount_pct,
        discount_amount_ngn :: numeric,
        revenue_ngn,
        cogs_ngn,
        gross_profit_ngn,
        payment_method,
        delivery_status,
        transaction_status,
        notes,
        is_missing_distributor
FROM raw.raw_transactions

