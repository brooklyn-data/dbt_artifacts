with
    base as (

        select *
        from {{ ref('stg_dbt__tests') }}

    )

    , tests as (

        select
            test_execution_id
            , command_invocation_id
            , node_id
            , run_started_at
            , name
            , depends_on_nodes
            , package_name
            , test_path
            , tags
        from base

    )

select * from tests
