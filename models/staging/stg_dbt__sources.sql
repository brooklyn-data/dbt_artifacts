with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

manifests as (

    select *
    from base
    where artifact_type = 'manifest.json'

),

flatten as (

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at as artifact_generated_at,
        node.key as node_id,
        node.value:name::string as name,
        node.value:source_name::string as source_name,
        node.value:schema::string as source_schema,
        node.value:package_name::string as package_name,
        node.value:relation_name::string as relation_name,
        node.value:path::string as source_path
    from manifests,
        lateral flatten(input => data:sources) as node
    where node.value:resource_type = 'source'

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as manifest_source_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        name,
        source_name,
        source_schema,
        package_name,
        relation_name,
        source_path
    from flatten

)

select * from surrogate_key
