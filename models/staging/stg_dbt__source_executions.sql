with base as (

    select *
    from {{ ref('source_executions') }}

),

enhanced as (

    select
        {{ dbt_artifacts.generate_surrogate_key(['command_invocation_id', 'node_id']) }} as source_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        {{ split_part('thread_id', "'-'", 2) }} as thread_id,
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        schema, -- noqa
        name,
        source_name,
        loaded_at_field,
        warn_after_count,
        warn_after_period,
        error_after_count,
        error_after_period,
        max_loaded_at,
        snapshotted_at,
        age,
        adapter_response
    from base

)

select * from enhanced
