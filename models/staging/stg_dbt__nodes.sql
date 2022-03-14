with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

base_v2 as (

    select *
    from {{ source('dbt_artifacts', 'dbt_manifest_nodes') }}

),

manifests_v1 as (

    select *
    from base
    where artifact_type = 'manifest.json'

),

flattened_v1 as (

    {{ flatten_manifest("manifests_v1") }}

),

deduped_v1 as (

    select *
    from flattened_v1
    -- Deduplicate the V1 issue of potential multiple manifest files.
    -- This is a very likely occurance if using dbt-cloud as each artifact upload
    -- will generate a new manifest.
    qualify row_number() over (partition by artifact_run_id, node_id order by artifact_generated_at asc) = 1

),

unioned as (

    -- V1 uploads
    select * from deduped_v1

    union all

    -- V2 uploads
    -- NB: We can safely select * because we know the schemas are the same
    -- as they're made by the same macro.
    select * from base_v2

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
        node_json:description::string as node_description,
        name,
        node_json
    from unioned

)

select * from surrogate_key
