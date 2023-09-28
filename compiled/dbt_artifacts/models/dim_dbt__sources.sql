with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__af2ed3136d79e1794c438abb6843672ded391a51.stg_dbt__sources

),

sources as (

    select
        source_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        database,
        schema,
        source_name,
        loader,
        name,
        identifier,
        loaded_at_field,
        freshness
    from base

)

select * from sources