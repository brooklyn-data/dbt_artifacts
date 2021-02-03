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
        data:metadata:invocation_id::string as command_invocation_id,
        generated_at as artifact_generated_at,
        node.key as node_id,
        node.value:name::string as name,
        node.value:schema::string as model_schema,
        node.value:package_name::string as package_name,
        node.value:path::string as model_path,
        node.value:checksum.checksum::string as checksum,
        node.value:config.materialized::string as model_materialization
    from manifests,
    lateral flatten(input => data:nodes) as node
    where node.value:resource_type = 'model'

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'checksum']) }} as manifest_model_id,
        command_invocation_id,
        artifact_generated_at,
        node_id,
        name,
        model_schema,
        package_name,
        model_path,
        checksum,
        model_materialization
    from flatten

)

select * from surrogate_key
