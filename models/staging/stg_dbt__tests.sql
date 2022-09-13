with base as (

    select *
    from {{ ref('tests') }}

),

enhanced as (

    select
        {{ dbt_artifacts.surrogate_key(['command_invocation_id', 'node_id']) }} as test_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        name,
        depends_on_nodes,
        package_name,
        test_path,
        tags
    from base

)

select * from enhanced
