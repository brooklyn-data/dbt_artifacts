{{ config(enabled = target.type == "snowflake") }}
-- C-06: monthly SMB totals must reconcile between consumption_by_model and
-- consumption_daily. Fails (returns rows) on any mismatched month.
with by_model as (
    select
        date_trunc('month', billing_month) as month
        , sum(smb_quantity) as smb
    from {{ ref("fct_dbt__consumption_by_model") }}
    group by 1
),

daily as (
    select
        date_trunc('month', date_day) as month
        , sum(quantity) as smb
    from {{ ref("fct_dbt__consumption_daily") }}
    where meter = 'smb'
    group by 1
)

select
    by_model.month as by_model_month
    , daily.month as daily_month
    , by_model.smb as by_model_smb
    , daily.smb as daily_smb
from by_model
full outer join daily on by_model.month = daily.month
where coalesce(by_model.smb, -1) != coalesce(daily.smb, -1)
