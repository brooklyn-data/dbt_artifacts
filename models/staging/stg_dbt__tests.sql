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
        short_name,
        test_type,
        test_severity_config,
        depends_on_nodes,
        model_refs,
        source_refs,
        column_names,
        package_name,
        test_path,
        tags
    from base

)

select * from enhanced
