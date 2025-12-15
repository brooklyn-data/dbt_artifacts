{{
  config(
    materialized = 'view',
    )
}}

with
    mb_transactions as (
        select
            {{ dbt_artifacts.safe_cast('transaction_id', 'integer') }} as transaction_id,
            {{ dbt_artifacts.safe_cast('transaction_date','date') }} as transaction_date,
            {{ dbt_artifacts.safe_cast('transaction_time', 'string') }} as transaction_time,
            {{ dbt_artifacts.safe_cast('transaction_ts', 'timestamp') }} as transaction_ts,
            {{ dbt_artifacts.safe_cast('transaction_qty', 'integer') }} as transaction_qty,
            {{ dbt_artifacts.safe_cast('store_id', 'integer') }} as store_id,
            {{ dbt_artifacts.safe_cast('store_location', 'string') }} as store_location,
            {{ dbt_artifacts.safe_cast('product_id', 'integer') }} as product_id,
            {{ dbt_artifacts.safe_cast('unit_price', dbt_artifacts.type_numeric() ) }} as unit_price,
            {{ dbt_artifacts.safe_cast('product_category', 'string') }} as product_category,
            {{ dbt_artifacts.safe_cast('product_type', 'string') }} as product_type,
            {{ dbt_artifacts.safe_cast('product_detail', 'string') }} as product_detail
        from {{ ref('microbatch_seed') }}
    )

    , transaction_interval as (
        select
            transaction_id,
            case
                when {{ dbt_artifacts.str_left('transaction_time', 2) }} = '07' then 0
                when {{ dbt_artifacts.str_left('transaction_time', 2) }} = '08' then -1
                else -2
            end as transaction_interval
        from mb_transactions
    )

    /* do this to prevent and db errors in case we can't self reference ...*/
    , transaction_time_today as (
        select
            transaction_id,
            transaction_time,
            {{ dbt_artifacts.safe_cast(dbt.current_timestamp(), 'date') }} as todays_date
        from mb_transactions
    )

    , transaction_time_today_string as (
        select
            transaction_id,
            transaction_time,
            todays_date,
            {{ dbt_artifacts.safe_cast('todays_date', 'string') }} as todays_date__str
        from transaction_time_today
    )

    , transaction_times as (
        select
            transaction_id,
            todays_date,
            {{ dbt.concat(['todays_date__str', "' '", 'transaction_time']) }} as transaction_time__ts
        from transaction_time_today_string
    )

select
    t.*,
    {{ dbt_artifacts.safe_cast('tt.transaction_time__ts', 'timestamp') }} as transaction_ts__hourly,

    {{ dbt.dateadd(
        datepart='day',
        interval='ti.transaction_interval',
        from_date_or_timestamp='tt.todays_date'
     )}} as transaction_ts__daily
from mb_transactions as t
left join transaction_times as tt
    on t.transaction_id = tt.transaction_id
left join transaction_interval as ti
    on t.transaction_id = ti.transaction_id
