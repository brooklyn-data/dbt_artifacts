with base as (

    select *
    from {{ ref('stg_dbt__model_executions') }}

),

model_executions as (

    select
        model_execution_id,
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
        {% if target.type == 'bigquery' %}
            bytes_processed,
        {% endif %}
        materialization,
        schema, -- noqa
        name,
        alias
    from base

)

select * from model_executions
