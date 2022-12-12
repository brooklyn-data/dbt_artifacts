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
        {{ adapter.dispatch('quote_reserved_keywords', 'dbt_artifacts')('database') }},
        {{ adapter.dispatch('quote_reserved_keywords', 'dbt_artifacts')('schema') }},
        name,
        depends_on_nodes,
        package_name,
        path,
        checksum,
        materialization,
        tags,
        meta,
        alias
    from base

)

select * from models
