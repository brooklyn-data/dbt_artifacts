{{ config( materialized='incremental', unique_key='seed_execution_id' ) }}

with seeds as (

    select *
    from {{ ref('dim_dbt__seeds') }}

),

node_executions as (

    select *
    from {{ ref('stg_dbt__node_executions') }}

),

seed_executions_incremental as (

    select *
    from node_executions
    where resource_type = 'seed'
        {% if is_incremental() %}
            -- this filter will only be applied on an incremental run
            and coalesce(artifact_generated_at > (select max(artifact_generated_at) from {{ this }}), true)
        {% endif %}

),

seed_executions_with_materialization as (

    select
        seed_executions_incremental.*,
        seeds.seed_schema,
        seeds.name
    from seed_executions_incremental
    left join seeds on
        seed_executions_incremental.artifact_run_id = seeds.artifact_run_id
        and seed_executions_incremental.node_id = seeds.node_id

),

fields as (

    select
        node_execution_id as seed_execution_id,
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
