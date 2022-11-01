with base as (

    select *
    from {{ ref('stg_dbt__seeds') }}

),

seeds as (

    select
        seed_execution_id,
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

select * from seeds
