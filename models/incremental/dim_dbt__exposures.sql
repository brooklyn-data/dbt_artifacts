{{
  config(
    materialized='incremental',
    unique_key='manifest_exposure_id'
    )
}}

with dbt_nodes as (

    select * from {{ ref('stg_dbt__nodes') }}

),

dbt_exposures_incremental as (

    select *
    from dbt_nodes
    where resource_type = 'exposure'

        {% if is_incremental() %}
            -- this filter will only be applied on an incremental run
            and coalesce(artifact_generated_at > (select max(artifact_generated_at) from {{ this }}), true)
        {% endif %}

),

fields as (

    select
        t.manifest_node_id as manifest_exposure_id,
        t.command_invocation_id,
        t.dbt_cloud_run_id,
        t.artifact_run_id,
        t.artifact_generated_at,
        t.node_id,
        t.name,
        t.node_json:type::string as type,
        t.node_json:owner:name::string as owner,
        t.node_json:maturity::string as maturity,
        f.value::string as output_feeds,
        t.node_json:package_name::string as package_name
    from dbt_exposures_incremental as t,
        lateral flatten(input => to_array(t.node_json:depends_on:nodes)) as f

)

select * from fields
