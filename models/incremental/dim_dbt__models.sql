{{ config( materialized='incremental', unique_key='manifest_model_id' ) }}

with dbt_models as (

    select * from {{ ref('stg_dbt__models') }}

),

run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

dbt_models_incremental as (

    select dbt_models.*
    from dbt_models
    -- Inner join with run results to enforce consistency and avoid race conditions.
    -- https://github.com/brooklyn-data/dbt_artifacts/issues/75
    inner join run_results on
        dbt_models.artifact_run_id = run_results.artifact_run_id

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where coalesce(dbt_models.artifact_generated_at > (select max(artifact_generated_at) from {{ this }}), true)
    {% endif %}

),

fields as (

    select
        manifest_model_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        model_database,
        model_schema,
        name,
        depends_on_nodes,
        package_name,
        model_path,
        checksum,
        model_materialization
    from dbt_models_incremental

)

select * from fields
