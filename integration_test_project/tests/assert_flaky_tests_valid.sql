{{ config(enabled = target.type == "snowflake") }}
-- flaky_tests must be valid (possibly empty). Fails on any out-of-range
-- flake_rate or flips exceeding executions.
select
    test_node_id
    , month
    , flips
    , executions
    , flake_rate
from {{ ref("fct_dbt__flaky_tests") }}
where flake_rate < 0
    or flake_rate > 1
    or flips > executions
