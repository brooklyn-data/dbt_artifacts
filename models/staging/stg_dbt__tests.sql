with base as (

    select *
    from {{ source('dbt_artifacts', 'tests') }}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as test_execution_id,
        command_invocation_id,
        node_id,
        name,
        {{ adapter.dispatch('parse_json')('depends_on_nodes')}} as depends_on_nodes,
        package_name,
        test_path,
        tags
    from base

)

select * from enhanced
