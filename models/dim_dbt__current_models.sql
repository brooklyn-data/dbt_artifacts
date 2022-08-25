{{
    config(
        materialized='table'
    )
}}

with base as (

    select * from {{ ref('stg_dbt__models') }}

),

model_executions as (

    select * from {{ ref('stg_dbt__model_executions') }}

),

latest_models as (
    
    select
        * 
        
    from
        base 
        
    where
        run_started_at = (select max(run_started_at) from base)

),

latest_models_runs as (

    select
        model_executions.node_id
        , model_executions.was_full_refresh
        , model_executions.query_completed_at
        , model_executions.execution_time
        , model_executions.rows_affected
        , row_number() over (
            partition by latest_models.node_id, model_executions.was_full_refresh
            order by model_executions.query_completed_at desc
        ) as run_index

    from
        model_executions
    inner join
        latest_models 
        on model_executions.node_id = latest_models.node_id
    
    where
        model_executions.status = 'success'

),

latest_model_stats as (

    select
        node_id
        , max(case when was_full_refresh then query_completed_at end) as last_full_refresh_run_completed_at
        , max(case when was_full_refresh then execution_time end) as last_full_refresh_run_execution_time
        , max(case when was_full_refresh then rows_affected end) as last_full_refresh_run_rows_affected
        , max(query_completed_at) as last_run_completed_at
        , max(execution_time) as last_run_execution_time
        , max(rows_affected) as last_run_rows_affected
    
    from
        latest_models_runs
    
    where
        run_index = 1
    
    group by 1

),

final as (

    select
        latest_models.*
        , latest_model_stats.last_full_refresh_run_completed_at
        , latest_model_stats.last_full_refresh_run_execution_time
        , latest_model_stats.last_full_refresh_run_rows_affected
        , latest_model_stats.last_run_completed_at
        , latest_model_stats.last_run_execution_time
        , latest_model_stats.last_run_rows_affected
    
    from
        latest_models
    left join
        latest_model_stats
        on latest_models.node_id = latest_model_stats.node_id

)

select * from final
