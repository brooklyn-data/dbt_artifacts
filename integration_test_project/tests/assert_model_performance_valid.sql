{{ config(enabled = target.type == "snowflake") }}
-- O-07: model_performance must return rows and be internally consistent -- no
-- median_runtime without a success, and the mart must not be empty. (A null
-- median on a day whose only successes were full refreshes is CORRECT by
-- design, so we assert consistency rather than blanket non-null.)
select 'median_without_success' as issue
from {{ ref("fct_dbt__model_performance") }}
where median_runtime is not null
    and success_count = 0

union all

select 'empty_mart' as issue
from (select count(*) as row_count from {{ ref("fct_dbt__model_performance") }})
where row_count = 0
