{{ config( 
    materialized='incremental', 
    unique_key='manifest_test_id' 
    ) 
}}

with dbt_tests as (

    select 
    *,
    case
        when test_name like 'unique_%'
            then 'unique'
        when test_name like 'not_null_%'
            then 'not null'
        when test_name like 'relationships_%'
            then 'relationship'
    end as test_type
    from {{ ref('stg_dbt_tests') }}

),

dbt_tests_incremental as (

    select * from dbt_tests

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

)

select * from dbt_tests_incremental