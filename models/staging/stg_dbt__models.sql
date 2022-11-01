with base as (

    select *
    from {{ ref('models') }}

),

enhanced as (

    select
        {{ dbt_artifacts.surrogate_key(['command_invocation_id', 'node_id']) }} as model_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        database,
        schema,
        name,
        alias,
        depends_on_nodes,
        package_name,
        path,
        checksum,
        materialization,
        tags,
        meta
    from base

)

select * from enhanced
