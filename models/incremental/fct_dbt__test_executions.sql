{{ config( materialized='incremental', unique_key='test_execution_id' ) }}

with test_executions as (

    select *
    from {{ ref('stg_dbt__test_executions') }}

),

run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

test_executions_incremental as (

    select test_executions.*
    from test_executions
    -- Inner join with run results to enforce consistency and avoid race conditions.
    -- https://github.com/brooklyn-data/dbt_artifacts/issues/75
    inner join run_results on
        test_executions.artifact_run_id = run_results.artifact_run_id

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where test_executions.artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        test_execution_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        was_full_refresh,
        node_id,
        thread_id,
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        rows_affected
    from test_executions_incremental

)

select * from fields
