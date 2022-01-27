{{ config( materialized='incremental', unique_key='model_execution_id' ) }}

with model_executions as (

    select *
    from {{ ref('stg_dbt__model_executions') }}

),

model_executions_incremental as (

    select *
    from model_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select ifnull(max(artifact_generated_at), '1970-01-01 00:00:00 +0000') from {{ this }})
    {% endif %}

),

fields as (

    select
        model_execution_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_generated_at,
        was_full_refresh,
        node_id,
        thread_id,
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        rows_affected
    from model_executions_incremental

)

select * from fields