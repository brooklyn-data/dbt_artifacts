{{ config(enabled = target.type == "snowflake") }}

{#-
    The forecast mart: one row per billing_month x meter with month-to-date
    usage, a weekday-aware projected month-end total, the projected allowance-
    breach date, and % of allowance used.

    Projection: over a trailing dbt_artifacts_run_rate_days (default 28) window
    ending as_of (today, clamped to month end), compute the average quantity per
    ISO day-of-week INCLUDING zero-build days (so weekends pull the rate down).
    Each remaining calendar day of the month contributes its day-of-week average;
    forecast_month_end = MTD + sum of those. forecast_exceeded_date is the first
    remaining day whose cumulative expected (added to MTD) reaches the allowance
    (or as_of when MTD already exceeds it). Allowance applies to the 'smb' meter
    only. Pure SQL + Jinja day series -- no seed, no dbt_utils.
-#}

{%- set run_rate_days = var("dbt_artifacts_run_rate_days", 28) -%}
{%- set allowance = dbt_artifacts.get_smb_allowance() -%}

with
    daily as (
        select
            date_day
            , meter
            , quantity
        from {{ ref("fct_dbt__consumption_daily") }}
    ),

    month_anchors as (
        select
            meter
            , date_trunc('month', date_day) as billing_month
            , last_day(date_trunc('month', date_day)) as month_end
            , least(current_date(), last_day(date_trunc('month', date_day))) as as_of_date
            , datediff(
                'day', least(current_date(), last_day(date_trunc('month', date_day))),
                last_day(date_trunc('month', date_day))
            ) as days_remaining
        from daily
        group by meter, date_trunc('month', date_day)
    ),

    month_to_date as (
        select
            ma.meter
            , ma.billing_month
            , sum(
                case when daily.date_day <= ma.as_of_date then daily.quantity else 0 end
            ) as month_to_date_quantity
        from month_anchors as ma
        inner join daily
            on daily.meter = ma.meter
            and date_trunc('month', daily.date_day) = ma.billing_month
        group by ma.meter, ma.billing_month
    ),

    offsets as (
        {% for i in range(run_rate_days) -%}
        select {{ i }} as day_offset
        {%- if not loop.last %}
        union all
        {% endif %}
        {%- endfor %}
    ),

    trailing_days as (
        select
            ma.meter
            , ma.billing_month
            , dayofweekiso(dateadd('day', -offsets.day_offset, ma.as_of_date)) as dow
            , coalesce(daily.quantity, 0) as quantity
        from month_anchors as ma
        cross join offsets
        left join daily
            on daily.meter = ma.meter
            and daily.date_day = dateadd('day', -offsets.day_offset, ma.as_of_date)
    ),

    dow_average as (
        select
            meter
            , billing_month
            , dow
            , avg(quantity) as avg_quantity
        from trailing_days
        group by meter, billing_month, dow
    ),

    daily_run_rate as (
        select
            meter
            , billing_month
            , avg(quantity) as daily_run_rate
        from trailing_days
        group by meter, billing_month
    ),

    day_numbers as (
        {% for i in range(1, 32) -%}
        select {{ i }} as day_number
        {%- if not loop.last %}
        union all
        {% endif %}
        {%- endfor %}
    ),

    remaining_days as (
        select
            ma.meter
            , ma.billing_month
            , dateadd('day', day_numbers.day_number - 1, ma.billing_month) as calendar_date
            , dayofweekiso(
                dateadd('day', day_numbers.day_number - 1, ma.billing_month)
            ) as dow
        from month_anchors as ma
        cross join day_numbers
        where day_numbers.day_number <= day(ma.month_end)
            and dateadd('day', day_numbers.day_number - 1, ma.billing_month) > ma.as_of_date
    ),

    remaining_expected as (
        select
            rd.meter
            , rd.billing_month
            , rd.calendar_date
            , coalesce(da.avg_quantity, 0) as expected_quantity
            , sum(coalesce(da.avg_quantity, 0)) over (
                partition by rd.meter, rd.billing_month
                order by rd.calendar_date
                rows between unbounded preceding and current row
            ) as cumulative_expected
        from remaining_days as rd
        left join dow_average as da
            on da.meter = rd.meter
            and da.billing_month = rd.billing_month
            and da.dow = rd.dow
    ),

    remaining_summary as (
        select
            meter
            , billing_month
            , sum(expected_quantity) as total_expected_remaining
        from remaining_expected
        group by meter, billing_month
    ),

    {%- if allowance is not none %}
    breach as (
        select
            re.meter
            , re.billing_month
            , min(re.calendar_date) as forecast_exceeded_date
        from remaining_expected as re
        inner join month_to_date as mtd
            on mtd.meter = re.meter
            and mtd.billing_month = re.billing_month
        where re.meter = 'smb'
            and (mtd.month_to_date_quantity + re.cumulative_expected) >= {{ allowance }}
        group by re.meter, re.billing_month
    ),
    {%- endif %}

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["ma.meter", "ma.billing_month"]) }}
                as consumption_forecast_id
            , ma.billing_month
            , ma.meter
            , mtd.month_to_date_quantity
            {%- if allowance is not none %}
            , case when ma.meter = 'smb' then {{ allowance }} else null end as allowance
            {%- else %}
            , cast(null as {{ dbt.type_int() }}) as allowance
            {%- endif %}
            , drr.daily_run_rate
            , mtd.month_to_date_quantity + coalesce(rs.total_expected_remaining, 0)
                as forecast_month_end_quantity
            {%- if allowance is not none %}
            , case
                when ma.meter = 'smb' and mtd.month_to_date_quantity >= {{ allowance }}
                    then ma.as_of_date
                when ma.meter = 'smb'
                    then breach.forecast_exceeded_date
            end as forecast_exceeded_date
            , case
                when ma.meter = 'smb'
                    then mtd.month_to_date_quantity / {{ allowance }}
            end as pct_of_allowance_used
            {%- else %}
            , cast(null as {{ dbt.type_timestamp() }}) as forecast_exceeded_date
            , cast(null as {{ dbt.type_float() }}) as pct_of_allowance_used
            {%- endif %}
            , ma.days_remaining
            {%- if allowance is not none %}
            , case
                when ma.meter = 'smb'
                    then (mtd.month_to_date_quantity + coalesce(rs.total_expected_remaining, 0))
                        > {{ allowance }}
            end as is_on_pace_to_exceed
            {%- else %}
            , cast(null as {{ dbt_artifacts.type_boolean() }}) as is_on_pace_to_exceed
            {%- endif %}
        from month_anchors as ma
        inner join month_to_date as mtd
            on mtd.meter = ma.meter and mtd.billing_month = ma.billing_month
        left join daily_run_rate as drr
            on drr.meter = ma.meter and drr.billing_month = ma.billing_month
        left join remaining_summary as rs
            on rs.meter = ma.meter and rs.billing_month = ma.billing_month
        {%- if allowance is not none %}
        left join breach
            on breach.meter = ma.meter and breach.billing_month = ma.billing_month
        {%- endif %}
    )

select *
from final
