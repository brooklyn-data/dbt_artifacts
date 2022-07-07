with results_executions as (

    select *
    from {{ ref('stg_dbt__results_executions') }}

),

models_executions as (

    select
        node_execution_id as model_execution_id,
        command_invocation_id,
        node_id,
        was_full_refresh,
        thread_id,
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        rows_affected,
        model_materialization,
        model_schema,
        name
    from results_executions

)

select * from models_executions