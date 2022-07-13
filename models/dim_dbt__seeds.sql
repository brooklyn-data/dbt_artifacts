with base as (

    select *
    from {{ ref('stg_dbt__seeds') }}

),

seeds as (

    select
        seed_execution_id,
        command_invocation_id,
        node_id,
        database,
        schema,
        name,
        package_name,
        path,
        checksum
    from base

)

select * from seeds
