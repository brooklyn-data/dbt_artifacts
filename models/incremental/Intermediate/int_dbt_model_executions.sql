{{ config( 
    materialized='incremental', 
    unique_key='model_execution_id' 
    ) 
}}

with model_executions as (

    select * from {{ ref('stg_dbt_model_executions') }}

),

model_executions_incremental as (

    select * from model_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

)

select * from model_executions_incremental