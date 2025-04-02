{{
  config(
    materialized = 'view',
    )
}}

with
    mb_transactions as (
        select
            {{ dbt.cast('transaction_id', api.Column.translate_type('integer') ) }} as transaction_id,
            {{ dbt.cast('transaction_date', api.Column.translate_type('date') ) }} as transaction_date,
            {{ dbt.cast('transaction_time', api.Column.translate_type('string') ) }} as transaction_time,
            {{ dbt.cast('transaction_ts', api.Column.translate_type('timestamp') ) }} as transaction_ts,
            {{ dbt.cast('transaction_qty', api.Column.translate_type('integer') ) }} as transaction_qty,
            {{ dbt.cast('store_id', api.Column.translate_type('integer') ) }} as store_id,
            {{ dbt.cast('store_location', api.Column.translate_type('string') ) }} as store_location,
            {{ dbt.cast('product_id', api.Column.translate_type('integer') ) }} as product_id,
            {{ dbt.cast('unit_price', api.Column.translate_type('numeric') ) }} as unit_price,
            {{ dbt.cast('product_category', api.Column.translate_type('string') ) }} as product_category,
            {{ dbt.cast('product_type', api.Column.translate_type('string') ) }} as product_type,
            {{ dbt.cast('product_detail', api.Column.translate_type('string') ) }} as product_detail
        from {{ ref('microbatch_seed') }}
    )

    , transaction_interval as (
        select
            transaction_id,
            case left(transaction_time, 2)
                when '07' then 0
                when '08' then -1
                else -2
            end as transaction_interval
        from mb_transactions
    )

    /* do this to prevent and db errors in case we can't self reference ...*/
    , transaction_time_today as (
        select
            transaction_id,
            transaction_time,
            {{ dbt.cast(dbt.current_timestamp(), api.Column.translate_type('date') ) }} as todays_date
        from mb_transactions
    )

    , transaction_time_today_string as (
        select
            transaction_id,
            transaction_time,
            todays_date,
            {{ dbt.cast('todays_date', api.Column.translate_type('string') ) }} as todays_date__str
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
    {{ dbt.safe_cast('tt.transaction_time__ts', api.Column.translate_type('timestamp')) }} as transaction_ts__hourly,

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
