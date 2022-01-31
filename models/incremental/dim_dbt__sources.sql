{{ config( materialized='incremental', unique_key='manifest_source_id' ) }}

with dbt_sources as (

    select * from {{ ref('stg_dbt__sources') }}

),

run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

dbt_sources_incremental as (

    select dbt_sources.*
    from dbt_sources
    -- Inner join with run results to enforce consistency and avoid race conditions.
    -- https://github.com/brooklyn-data/dbt_artifacts/issues/75
    inner join run_results on
        dbt_sources.artifact_run_id = run_results.artifact_run_id

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where dbt_sources.artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        manifest_source_id,
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
    from dbt_sources_incremental

)

select * from fields
