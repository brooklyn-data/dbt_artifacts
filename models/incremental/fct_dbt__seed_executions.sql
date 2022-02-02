{{ config( materialized='incremental', unique_key='seed_execution_id' ) }}

with seeds as (

    select *
    from {{ ref('dim_dbt__seeds') }}

),

seed_executions as (

    select *
    from {{ ref('stg_dbt__seed_executions') }}

),

run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

seed_executions_incremental as (

    select seed_executions.*
    from seed_executions
    -- Inner join with run results to enforce consistency and avoid race conditions.
    -- https://github.com/brooklyn-data/dbt_artifacts/issues/75
    inner join run_results on
        seed_executions.artifact_run_id = run_results.artifact_run_id

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where seed_executions.artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

seed_executions_with_materialization as (

    select
        seed_executions_incremental.*,
        seeds.seed_schema,
        seeds.name
    from seed_executions_incremental
    left join seeds on
        (
            seed_executions_incremental.command_invocation_id = seeds.command_invocation_id
            or seed_executions_incremental.dbt_cloud_run_id = seeds.dbt_cloud_run_id
        )
        and seed_executions_incremental.node_id = seeds.node_id

),

fields as (

    select
        seed_execution_id,
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
        rows_affected,
        seed_schema,
        name
    from seed_executions_with_materialization

)

select * from fields