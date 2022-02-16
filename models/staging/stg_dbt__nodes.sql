with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

manifests as (

    select *
    from base
    where artifact_type = 'manifest.json'

),

flattened as (

    {{ flatten_manifest("manifests") }}

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as manifest_node_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        resource_type,
        node_database,
        node_schema,
        name,
        depends_on_nodes,
        depends_on_sources,
        exposure_type,
        exposure_owner,
        exposure_maturity,
        source_name,
        package_name,
        relation_name,
        node_path,
        checksum,
        materialization
    from flattened

)

select * from surrogate_key
