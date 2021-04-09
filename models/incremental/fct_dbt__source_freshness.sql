{{ config( materialized='incremental', unique_key='source_freshness_id' ) }}

with models as (

    select *
    from {{ ref('dim_dbt__models') }}

),

source_freshness_executions as (

    select *
    from {{ ref('int_dbt__source_freshness_executions') }}

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
        source_freshness_executions_incremental.command_invocation_id = models.command_invocation_id
        and source_freshness_executions_incremental.node_id = models.node_id
    )

),

fields as (

    select
         source_freshness_id,
        command_invocation_id,
        artifact_generated_at,
        node_id,
        project_name,
        source_name,
        table_name,
        freshness_status,
        max_loaded_at,
        freshness_checked_at,
        max_loaded_at_time_ago_in_s
    from source_freshness_executions_incremental

)

select * from fields