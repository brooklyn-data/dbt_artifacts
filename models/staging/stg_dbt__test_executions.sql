with base as (

    select *
    from {{ source('dbt_artifacts', 'test_executions') }}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as test_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        was_full_refresh,
        {{ dbt_utils.split_part('thread_id', "'-'", 2) }} as thread_id, -- noqa
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        rows_affected,
        failures
    from base

)

select * from enhanced
