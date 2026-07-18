{{ config(enabled = target.type == "snowflake") }}
-- O-07: dag_bottlenecks must be valid (possibly empty). Fails on any negative
-- stall time.
select
    date_day
    , parent_node_id
    , total_stall_seconds
    , max_stall_seconds
from {{ ref("fct_dbt__dag_bottlenecks") }}
where total_stall_seconds < 0
    or max_stall_seconds < 0
