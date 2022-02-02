with run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

model_executions as (

    select *
    from {{ ref('fct_dbt__model_executions') }}

),

latest_full as (

    select *
    from run_results
    where execution_command = 'run' and selected_models is null and was_full_refresh = false
    order by artifact_generated_at desc
    limit 1

),

joined as (

    select
        model_executions.*
    from latest_full
    left join model_executions on
        model_executions.artifact_run_id = latest_full.artifact_run_id

),

fields as (

    select
        artifact_generated_at,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        model_execution_id,
        model_materialization,
        model_schema,
        name,
        node_id,
        thread_id,
        rows_affected,
        status,
        was_full_refresh
    from joined

)

select * from fields
