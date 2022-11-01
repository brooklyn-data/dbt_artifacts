with base as (

    select *
    from {{ ref('seeds') }}

),

enhanced as (

    select
        {{ dbt_artifacts.surrogate_key(['command_invocation_id', 'node_id']) }} as seed_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        database,
        schema,
        name,
        alias,
        package_name,
        path,
        checksum,
        meta
    from base

)

select * from enhanced
