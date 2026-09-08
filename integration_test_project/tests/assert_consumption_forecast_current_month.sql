{{ config(enabled = target.type == "snowflake") }}
-- The forecast must have exactly one 'smb' row for the current billing
-- month, with non-null month_to_date_quantity and non-null allowance (developer
-- plan is set in dbt_project.yml). Fails if not exactly one, or either is null.
select
    count(*) as n_rows
    , count(month_to_date_quantity) as non_null_mtd
    , count(allowance) as non_null_allowance
from {{ ref("fct_dbt__consumption_forecast") }}
where meter = 'smb'
    and billing_month = date_trunc('month', current_date())
having count(*) != 1
    or count(month_to_date_quantity) != 1
    or count(allowance) != 1
