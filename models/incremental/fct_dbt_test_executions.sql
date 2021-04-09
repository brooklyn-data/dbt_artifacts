{{ config( materialized='incremental', unique_key='test_execution_id' ) }}

with models as (

    select *
    from {{ ref('int_dbt_models') }}

),

test_executions as (

    select *
    from {{ ref('int_dbt_test_executions') }}

),

test_executions_incremental as (

    select *
    from test_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

test_executions_with_materialization as (

    select
        test_executions_incremental.*,
        models.model_materialization,
        models.model_schema,
        models.name
    from test_executions_incremental
    left join models on (
        test_executions_incremental.command_invocation_id = models.command_invocation_id
        and test_executions_incremental.node_id = models.node_id
    )

)

select * from test_executions_with_materialization