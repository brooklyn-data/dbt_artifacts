{{ config( materialized='incremental', unique_key='snapshot_execution_id' ) }}

with snapshots as (

    select *
    from {{ ref('dim_dbt__snapshots') }}

),

snapshot_executions as (

    select *
    from {{ ref('stg_dbt__snapshot_executions') }}

),

snapshot_executions_incremental as (

    select *
    from snapshot_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

snapshot_executions_with_materialization as (

    select
        snapshot_executions_incremental.*,
        snapshots.snapshot_schema,
        snapshots.name
    from snapshot_executions_incremental
    left join snapshots on
        (
            snapshot_executions_incremental.command_invocation_id = snapshots.command_invocation_id
            or snapshot_executions_incremental.dbt_cloud_run_id = snapshots.dbt_cloud_run_id
        )
        and snapshot_executions_incremental.node_id = snapshots.node_id

),

fields as (

    select
        snapshot_execution_id,
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
        rows_affected,
        snapshot_schema,
        name
    from snapshot_executions_with_materialization

)

select * from fields