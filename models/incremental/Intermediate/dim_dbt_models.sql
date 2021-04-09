{{ config( materialized='incremental', unique_key='manifest_model_id' ) }}

with dbt_models as (

    select * from {{ ref('stg_dbt_models') }}

),

dbt_models_incremental as (

    select *
    from dbt_models

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

)

select * from dbt_models_incremental
