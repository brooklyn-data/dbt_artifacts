{#-
    Core consumption mart: one row per UTC day x meter.

    A strict roll-up of fct_dbt__consumption_daily_detail (sum of quantity),
    so daily totals always reconcile exactly to the detail grain. Meters and
    their definitions live in the detail model's header.
-#}

with
    detail as (select * from {{ ref("fct_dbt__consumption_daily_detail") }}),

    aggregated as (
        select
            date_day
            , meter
            , sum(quantity) as quantity
        from detail
        group by date_day, meter
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["date_day", "meter"]) }}
                as consumption_daily_id
            , date_day
            , meter
            , quantity
        from aggregated
    )

select *
from final
