{{ config(enabled = target.type == "snowflake") }}
-- O-07: run_health_daily must have at least one row with invocations > 0.
select count(*) as days_with_invocations
from {{ ref("fct_dbt__run_health_daily") }}
where invocations > 0
having count(*) = 0
