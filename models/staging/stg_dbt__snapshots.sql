with base as (

    select *
    from {{ source('dbt_artifacts', 'snapshots') }}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as snapshot_execution_id,
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
        strategy
    from base

)

select * from enhanced
