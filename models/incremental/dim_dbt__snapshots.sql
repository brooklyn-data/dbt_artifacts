{{ config( materialized='incremental', unique_key='manifest_snapshot_id' ) }}

with dbt_nodes as (

    select * from {{ ref('stg_dbt__nodes') }}

),

dbt_snapshots_incremental as (

    select *
    from dbt_nodes
    where resource_type = 'snapshot'

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        manifest_node_id as manifest_snapshot_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        node_database as snapshot_database,
        node_schema as snapshot_schema,
        name,
        depends_on_nodes,
        package_name,
        node_path as snapshot_path,
        checksum
    from dbt_snapshots_incremental

)

select * from fields