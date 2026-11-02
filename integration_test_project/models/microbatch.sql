{#- Adapter-specific config for DuckDB, which builds this microbatch model:
    partition_by is set only on BigQuery, because the dict form is BigQuery's and DuckDB rejects it;
    unique_key is left off on DuckDB, which refuses it for microbatch (other adapters ignore it);
    batches run one at a time on DuckDB, because dbt-core 1.10 with dbt-duckdb 1.10 hangs when it
    schedules a second batch concurrently. -#}
{{
  config(
        materialized = 'incremental',
        incremental_strategy = 'microbatch',
        event_time = 'transaction_ts',
        begin = (modules.datetime.datetime.now().replace(hour=6, minute=0, second=0) - modules.datetime.timedelta(2)).isoformat(),
        batch_size = 'day',

        unique_key = 'transaction_id' if target.type != 'duckdb' else none,
        partition_by = {
            'field': 'transaction_ts',
            'data_type': 'datetime',
            'granularity': 'day'
        } if target.type == 'bigquery' else none,

        concurrent_batches = false if target.type == 'duckdb' else none,

        enabled = target.type != 'trino'
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
