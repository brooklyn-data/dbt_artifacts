{{ config( 
    materialized='incremental', 
    unique_key='source_freshness_id' 
    ) 
}}

with source_freshness_executions as (

    select * from {{ ref('stg_dbt_source_freshness') }}

),

source_freshness_executions_incremental as (

    select * from source_freshness_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

)

select * from source_freshness_executions_incremental