with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

base_v2 as (

    select *
    from {{ source('dbt_artifacts', 'dbt_run_manifest_nodes') }}

),

manifests as (

    select *
    from base
    where artifact_type = 'manifest.json'

),

flatten as (

    -- V1
    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at as artifact_generated_at,
        node.key as node_id,
        node.value:database::string as snapshot_database,
        node.value:schema::string as snapshot_schema,
        node.value:name::string as name,
        to_array(node.value:depends_on:nodes) as depends_on_nodes,
        node.value:package_name::string as package_name,
        node.value:path::string as snapshot_path,
        node.value:checksum.checksum::string as checksum
    from manifests,
        lateral flatten(input => data:nodes) as node
    where node.value:resource_type = 'snapshot'

    union all

    -- V2
    select
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        model_database as snapshot_database,
        model_schema as snapshot_schema,
        name,
        depends_on_nodes,
        package_name,
        model_path as snapshot_path,
        checksum
    from base_v2
    where resource_type = 'snapshot'

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as manifest_snapshot_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        snapshot_database,
        snapshot_schema,
        name,
        depends_on_nodes,
        package_name,
        snapshot_path,
        checksum
    from flatten

)

select * from surrogate_key
