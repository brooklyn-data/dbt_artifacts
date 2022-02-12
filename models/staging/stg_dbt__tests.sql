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
        node.value:name::string as name,
        to_array(node.value:depends_on:nodes) as depends_on_nodes,
        node.value:package_name::string as package_name,
        node.value:path::string as test_path
    from manifests,
        lateral flatten(input => data:nodes) as node
    where node.value:resource_type = 'test'

    union all

    -- V2
    select
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        name,
        depends_on_nodes,
        package_name,
        model_path as test_path
    from base_v2
    where resource_type = 'test'

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as manifest_test_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        name,
        depends_on_nodes,
        package_name,
        test_path

    from flatten

)

select * from surrogate_key
