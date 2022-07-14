with base as (

    select *
    from {{ source('dbt_artifacts', 'exposures') }}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as exposure_execution_id,
        command_invocation_id,
        node_id,
        name,
        type,
        owner,
        maturity,
        path,
        description,
        url,
        package_name,
        {{ adapter.dispatch('parse_json')('depends_on_nodes')}} as depends_on_nodes
    from base

)

select * from enhanced
