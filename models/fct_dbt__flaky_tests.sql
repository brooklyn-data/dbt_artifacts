{{ config(enabled = target.type == "snowflake") }}

{#-
    Flaky-test rollup: one row per test_node_id x month. flips comes from
    fct_dbt__flaky_tests_detail (genuine fail->pass-without-parent-rebuild
    events); executions counts all of the test's executions that month.
    is_flaky = flips >= dbt_artifacts_flaky_min_flips (default 2). Snowflake-only.
-#}

with
    test_executions as (
        select
            node_id as test_node_id
            , date_trunc('month', {{ dbt_artifacts.cast_to_utc_date("run_started_at") }})
                as month
        from {{ ref("stg_dbt__test_executions") }}
    ),

    executions_monthly as (
        select
            test_node_id
            , month
            , count(*) as executions
        from test_executions
        group by test_node_id, month
    ),

    flips_monthly as (
        select
            test_node_id
            , date_trunc('month', date_day) as month
            , count(*) as flips
            , max(passed_at) as last_flip_at
        from {{ ref("fct_dbt__flaky_tests_detail") }}
        group by test_node_id, date_trunc('month', date_day)
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["em.test_node_id", "em.month"]) }}
                as flaky_test_id
            , em.test_node_id
            , em.month
            , coalesce(fm.flips, 0) as flips
            , em.executions
            , coalesce(fm.flips, 0) / nullif(em.executions, 0) as flake_rate
            , fm.last_flip_at
            , case
                when coalesce(fm.flips, 0) >= {{ var("dbt_artifacts_flaky_min_flips", 2) }}
                    then true
                else false
            end as is_flaky
        from executions_monthly as em
        left join flips_monthly as fm
            on em.test_node_id = fm.test_node_id
            and em.month = fm.month
    )

select *
from final
