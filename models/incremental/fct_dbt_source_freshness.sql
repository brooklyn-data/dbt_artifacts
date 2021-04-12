{{ config( materialized='incremental', unique_key='source_freshness_id' ) }}

with models as (

    select *
    from {{ ref('int_dbt_models') }}

),

source_freshness_executions as (

    select *
    from {{ ref('int_dbt_source_freshness') }}

),

source_freshness_executions_incremental as (

    select *
    from source_freshness_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

source_freshness_executions_with_materialization as (

    select
        source_freshness_executions_incremental.*,
        models.model_materialization,
        models.model_schema,
        models.name
    from source_freshness_executions_incremental
    left join models on (
        source_freshness_executions_incremental.node_id = models.node_id
    )

)

select * from source_freshness_executions_with_materialization