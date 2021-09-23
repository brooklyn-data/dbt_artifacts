{{
    config(
        materialized = 'incremental',
        unique_key = 'test_execution_id'
    )
}}

with test_executions as (

    select * from {{ ref('stg_dbt_test_executions') }}

),

test_executions_incremental as (

    select * from test_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
        where artifact_generated_at > (
            select max(artifact_generated_at)
            from {{ this }}
        )
    {% endif %}

)

select * from test_executions_incremental