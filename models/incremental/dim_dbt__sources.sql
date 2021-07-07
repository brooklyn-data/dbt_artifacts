{{ config( materialized='incremental', unique_key='manifest_source_id' ) }}

with dbt_sources as (

    select * from {{ ref('stg_dbt__sources') }}

),

dbt_sources_incremental as (

    select *
    from dbt_sources

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        manifest_source_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_generated_at,
        node_id,
        name,
        source_name,
        source_schema,
        package_name,
        relation_name,
        source_path
    from dbt_sources_incremental

)

select * from fields
