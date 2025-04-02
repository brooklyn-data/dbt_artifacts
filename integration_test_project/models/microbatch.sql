{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'microbatch',
    unique_key = 'transaction_id',
    event_time = 'transaction_ts',
    begin = (modules.datetime.datetime.now().replace(hour=6, minute=0, second=0) - modules.datetime.timedelta(2)).isoformat(),
    batch_size = 'day'
    )
}}

with transactions as (
    select * from {{ ref('microbatch_transaction') }}
)

, stores as (
    select * from {{ ref('microbatch_store') }}
)

select
    transactions.transaction_id,
    transactions.transaction_ts__daily as transaction_ts,
    stores.store_name,
    transactions.unit_price * transactions.transaction_qty as total_price,
    transactions.product_id
from transactions
left join stores
    on transactions.store_id = stores.store_id
