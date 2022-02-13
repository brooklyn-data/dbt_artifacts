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
        and artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
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
        depends_on_nodes,
        package_name,
        node_path as test_path
    from dbt_tests_incremental

)

select * from fields
