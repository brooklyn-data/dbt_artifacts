with raw_model_executions as (

    select * from {{ ref('fct_dbt__model_executions') }}

),

grouped_executions as (

    select
        artifact_run_id,
        count(*) as runs
    from raw_model_executions
    group by artifact_run_id

),

expected_results as (

    select
        artifact_run_id,
        runs,
        -- Hard coded expected results. Potentially to improve later.
        case artifact_run_id
            when 'a' then 1
            when 'b' then 2
            else 3
        end as expected_runs
    from grouped_executions
    where runs != expected_runs
)

select * from expected_results
