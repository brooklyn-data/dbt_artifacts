{{ config( materialized='incremental', unique_key='manifest_test_id' ) }}

with dbt_nodes as (

    select * from {{ ref('stg_dbt__nodes') }}

),

dbt_tests_incremental as (

    select *
    from dbt_nodes
    where resource_type = 'test'

        {% if is_incremental() %}
            -- this filter will only be applied on an incremental run
            and coalesce(artifact_generated_at > (select max(artifact_generated_at) from {{ this }}), true)
        {% endif %}

),

fields as (

    select
        manifest_node_id as manifest_test_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        name,
        to_array(node_json:depends_on:nodes) as depends_on_nodes,
        node_json:package_name::string as package_name,
        node_json:path::string as test_path
    from dbt_tests_incremental

)

select * from fields
