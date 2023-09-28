with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__af2ed3136d79e1794c438abb6843672ded391a51.stg_dbt__test_executions

),

test_executions as (

    select
        test_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        was_full_refresh,
        thread_id,
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        rows_affected,
        failures,
        message
    from base

)

select * from test_executions