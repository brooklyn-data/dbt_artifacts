with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__af2ed3136d79e1794c438abb6843672ded391a51.stg_dbt__models

),

models as (

    select
        model_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        database,
        schema,
        name,
        depends_on_nodes,
        package_name,
        path,
        checksum,
        materialization,
        tags,
        meta,
        alias
    from base

)

select * from models