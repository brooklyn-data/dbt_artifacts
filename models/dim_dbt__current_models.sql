with run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

models as (

    select *
    from {{ ref('dim_dbt__models') }}

),

model_executions as (

    select *
    from {{ ref('fct_dbt__model_executions') }}

),

-- Get the most recent comile run
latest_compile as (

    select artifact_run_id
    from run_results
    where execution_command = 'run'
    order by artifact_generated_at desc
    limit 1

),

-- Models present in the most recent compile run
latest_models as (

    select models.*
    from models
    -- In a local deploy, the command id is sufficient, but not in cloud - that requires the cloud run id to achieve a match.
    inner join latest_compile
        on models.artifact_run_id = latest_compile.artifact_run_id

),

latest_model_runs as (

    select
        latest_models.node_id,
        model_executions.query_completed_at,
        model_executions.total_node_runtime,
        model_executions.rows_affected,
        model_executions.was_full_refresh,
        -- Work out indices so we can get the most recent runs, both incremental and full.
        row_number() over (
            partition by latest_models.node_id, model_executions.was_full_refresh
            order by model_executions.query_completed_at desc
        ) as run_idx
    from latest_models
    inner join model_executions
        on latest_models.node_id = model_executions.node_id
    -- Only successful runs
    where model_executions.status = 'success'

),

latest_model_stats as (
    select
        node_id,
        max(iff(not was_full_refresh, query_completed_at, null)) as last_incremental_run_completed_at,
        max(iff(not was_full_refresh, total_node_runtime, null)) as last_incremental_run_total_runtime,
        max(iff(not was_full_refresh, rows_affected, null)) as last_incremental_run_rows_affected,
        max(iff(was_full_refresh, query_completed_at, null)) as last_full_run_completed_at,
        max(iff(was_full_refresh, total_node_runtime, null)) as last_full_run_total_runtime,
        max(iff(was_full_refresh, rows_affected, null)) as last_full_run_rows_affected
    from latest_model_runs
    -- Only most recent runs (of each type)
    where run_idx = 1
    group by node_id

),

final as (

    select
        latest_models.*,
        latest_model_stats.last_incremental_run_completed_at,
        latest_model_stats.last_incremental_run_total_runtime,
        latest_model_stats.last_incremental_run_rows_affected,
        latest_model_stats.last_full_run_completed_at,
        latest_model_stats.last_full_run_total_runtime,
        latest_model_stats.last_full_run_rows_affected
    from latest_models
    left join latest_model_stats
        on latest_models.node_id = latest_model_stats.node_id

)

select * from final
