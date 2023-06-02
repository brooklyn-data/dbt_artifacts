with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__adf735861224874ff84ce59e5c4ae287b7856413.stg_dbt__snapshots

),

snapshots as (

    select
        snapshot_execution_id,
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
        strategy,
        meta,
        alias
    from base

)

select * from snapshots