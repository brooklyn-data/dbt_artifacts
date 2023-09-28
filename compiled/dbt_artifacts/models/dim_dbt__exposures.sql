with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__af2ed3136d79e1794c438abb6843672ded391a51.stg_dbt__exposures

),

exposures as (

    select
        exposure_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        name,
        type,
        owner,
        maturity,
        path,
        description,
        url,
        package_name,
        depends_on_nodes,
        tags
    from base

)

select * from exposures