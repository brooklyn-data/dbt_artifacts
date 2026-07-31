{{
  config(
    materialized = 'table',
    event_time = 'transaction_ts__hourly'
    )
}}

select
    transaction_id,
    transaction_ts__hourly,
    transaction_ts__daily,
    transaction_qty,
    unit_price,
    store_id,
    product_id,
    product_type,
    product_detail
from {{ ref('microbatch_transaction_base') }}
