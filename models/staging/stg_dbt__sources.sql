with base as (

    select *
    from {{ ref('sources') }}

),

enhanced as (

    select
        {{ dbt_artifacts.surrogate_key(['command_invocation_id', 'node_id']) }} as source_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        {{ adapter.dispatch('quote_reserved_keywords', 'dbt_artifacts')('database') }},
        {{ adapter.dispatch('quote_reserved_keywords', 'dbt_artifacts')('schema') }},
        source_name,
        loader,
        name,
        identifier,
        loaded_at_field,
        freshness
    from base

)

select * from enhanced
