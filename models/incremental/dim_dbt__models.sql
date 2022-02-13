{{ config( materialized='incremental', unique_key='manifest_model_id' ) }}

with dbt_nodes as (

    select * from {{ ref('stg_dbt__nodes') }}

),

dbt_models_incremental as (

    select *
    from dbt_nodes
    where resource_type = 'model'

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        and coalesce(artifact_generated_at > (select max(artifact_generated_at) from {{ this }}), true)
    {% endif %}

),

fields as (

    select
        manifest_node_id as manifest_model_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        node_database as model_database,
        node_schema as model_schema,
        name,
        depends_on_nodes,
        package_name,
        node_path as model_path,
        checksum,
        materialization as model_materialization
    from dbt_models_incremental

)

select * from fields
