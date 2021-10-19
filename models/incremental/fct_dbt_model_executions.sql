{{
    config(
        materialized = 'incremental',
        unique_key = 'model_execution_id'
    )
}}

with models as (

    select distinct

        node_id,
        model_materialization,
        model_schema,
        name

    from {{ ref('int_dbt_models') }}

),

model_executions as (

    select * from {{ ref('int_dbt_model_executions') }}

),

model_executions_incremental as (

    select * from model_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
        where artifact_generated_at > (
            select max(artifact_generated_at)
            from {{ this }}
        )
    {% endif %}

),

model_executions_with_materialization as (

    select

        {{ dbt_utils.surrogate_key([
                'command_invocation_id',
                'models.node_id',
                'models.model_schema'])
            }} as model_id,

        model_executions_incremental.*,

        models.model_materialization,
        models.model_schema,
        models.name

    from model_executions_incremental
    left join models
        on (model_executions_incremental.command_invocation_id = models.command_invocation_id
            or model_executions_incremental.dbt_cloud_run_id = models.dbt_cloud_run_id)
        and model_executions_incremental.node_id = models.node_id

)

select * from model_executions_with_materialization
