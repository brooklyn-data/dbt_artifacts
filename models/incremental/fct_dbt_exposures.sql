{{
    config(
        materialized = 'incremental',
        unique_key = 'manifest_model_id'
    )
}}

with dbt_models as (

    select * from {{ ref('stg_dbt_exposures') }}

),

dbt_models_incremental as (

    select *
    from dbt_models

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
        where artifact_generated_at > (
            select max(artifact_generated_at)
            from {{ this }}
        )
    {% endif %}

),

fields as (

     select

        dbt_models_incremental.manifest_model_id,
        dbt_models_incremental.command_invocation_id,
        dbt_models_incremental.dbt_cloud_run_id,
        dbt_models_incremental.artifact_generated_at,
        dbt_models_incremental.node_id,
        dbt_models_incremental.name,
        dbt_models_incremental.type,
        dbt_models_incremental.owner,
        dbt_models_incremental.maturity,
        dbt_models_incremental.package_name,

        nodes.value::string as output_feeds

    from dbt_models_incremental,
    lateral flatten(input => depends_on_nodes) as nodes

)

select * from fields