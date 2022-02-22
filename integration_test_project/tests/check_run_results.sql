with raw_runs as (

    select * from {{ ref('stg_dbt__run_results') }}

),

grouped_runs as (

    select
        count(*) as runs
    from raw_runs

),

expected_results as (

    select
        runs,
        -- Hard coded expected results. Potentially to improve later.
        7 as expected_runs
    from grouped_runs
    where runs != expected_runs
)

select * from expected_results
