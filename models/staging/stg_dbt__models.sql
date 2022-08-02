with base as (

    select *
    from {{ source('dbt_artifacts', 'models') }}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as model_execution_id,
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
        materialization
    from base

)

select * from enhanced
