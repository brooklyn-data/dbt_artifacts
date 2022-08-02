with base as (

    select *
    from {{ source('dbt_artifacts', 'seeds') }}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as seed_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        database,
        schema,
        name,
        package_name,
        path,
        checksum
    from base

)

select * from enhanced
