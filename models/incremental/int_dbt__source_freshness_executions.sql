{{ config( materialized='incremental', unique_key='source_freshness_id' ) }}

with source_freshness_executions as (

    select *
    from {{ ref('stg_dbt__source_freshness_executions') }}

),

source_freshness_executions_incremental as (

    select *
    from source_freshness_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        source_freshness_id,
        command_invocation_id,
        artifact_generated_at,
        was_full_refresh,
        node_id,
        thread_id,
        status,
        compile_started_at,
        compile_completed_at,
        total_node_runtime,
        rows_affected
    from source_freshness_executions_incremental

)

select * from fields