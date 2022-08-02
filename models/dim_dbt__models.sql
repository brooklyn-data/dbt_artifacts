with base as (

    select *
    from {{ ref('stg_dbt__models') }}

),

models as (

    select
        model_execution_id,
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

select * from models
