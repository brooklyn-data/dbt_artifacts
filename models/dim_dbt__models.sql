with base as (

    select *
    from {{ ref('stg_dbt__models') }}

),

models as (

    select
        model_execution_id,
        command_invocation_id,
        node_id,
        model_database,
        model_schema,
        name,
        depends_on_nodes,
        package_name,
        model_path,
        checksum,
        model_materialization
    from base

)

select * from models
