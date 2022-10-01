with base as (

    select *
    from {{ ref('stg_dbt__tests') }}

),

tests as (

    select
        test_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        name,
        short_name,
        test_type,
        test_severity_config,
        depends_on_nodes,
        model_refs,
        source_refs,
        package_name,
        test_path,
        tags
    from base

)

select * from tests
