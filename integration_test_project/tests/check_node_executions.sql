with raw_node_executions as (

    select * from {{ ref('stg_dbt__node_executions') }}

),

grouped_executions as (

    select
        artifact_run_id,
        count(*) as runs
    from raw_node_executions
    group by artifact_run_id

),

expected_results as (

    select
        artifact_run_id,
        runs,
        -- Hard coded expected results. Potentially to improve later.
        case artifact_run_id
            when 'b27910c784063dc867a762eb91ac7e93033492ac49b482215cd1761824b07a58' then 51 -- build
            when '1ab40ec436539434416dfca0bb0e8d8cf3708bb568fb2385321a192b59b9c4e7' then 51 -- build_full_refresh
            when 'c6775fc1f3d39acb37f389df8b67aa59cb989994dc9b940b51e7bcba830212a3' then 31 -- run
            when '4fbd1feb6cfc3cd088fc47ac461efdfab7f95380aa5a939360da629bbdb9ce1d' then 31 -- run_full_refresh
            when '6ee8780f7533ae3901f8759fd07ddae4af20b7856c788bf515bdf14ee059e90d' then 1  -- seed
            when '1c87fbb828af7f041f0d7d4440904a8e482a8be74e617eb57a11b76001936550' then 1  -- snapshot
            when '37f4a0fca17b0f8f1fb0db04fbef311dd73cacfcd6653c76d46e3d7f36dc079c' then 18 -- test
            else 0
        end as expected_runs
    from grouped_executions
    where runs != expected_runs
)

select * from expected_results
