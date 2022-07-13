with base as (

    select *
    from {{ ref('stg_dbt__snapshots') }}

),

snapshots as (

    select
        snapshot_execution_id,
        command_invocation_id,
        node_id,
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

select * from snapshots
