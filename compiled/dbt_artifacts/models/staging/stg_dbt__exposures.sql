with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__adf735861224874ff84ce59e5c4ae287b7856413.exposures

),

enhanced as (

    select
        
md5(cast(coalesce(cast(command_invocation_id as TEXT), '') || '-' || coalesce(cast(node_id as TEXT), '') as TEXT)) as exposure_execution_id,
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

select * from enhanced