{{ config( materialized='incremental', unique_key='manifest_snapshot_id' ) }}

with dbt_snapshots as (

    select * from {{ ref('stg_dbt__snapshots') }}

),

dbt_snapshots_incremental as (

    select *
    from dbt_snapshots

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        manifest_snapshot_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_generated_at,
        node_id,
        snapshot_database,
        snapshot_schema,
        name,
        depends_on_nodes,
        package_name,
        snapshot_path,
        checksum
    from dbt_snapshots_incremental

)

select * from fields