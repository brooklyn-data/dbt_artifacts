{{
  config(
    materialized = 'view',
    )
}}

with
    cte as (
        select
            transaction_id,
            transaction_date,
            transaction_time,
            transaction_qty,
            store_id,
            product_id,
            unit_price,
            product_category,
            product_type,
            product_detail,
        from {{ ref('microbatch_seed') }}
    )

select
    *,
    cast(
        cast(current_date as string) || ' ' || transaction_time
        as timestamp_ntz
     ) as transaction_ts__hourly,
    dateadd(
        day,
        case left(transaction_time, 2)
            when '07' then 0
            when '08' then 1
            else 2
        end,
        current_date
    ) as transaction_ts__daily
from cte
