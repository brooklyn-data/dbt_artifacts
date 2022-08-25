{{
    config(
        materialized='incremental',
        unique_key='test_execution_id'
    )
}}

with base as (

    select
        *
    
    from
        {{ ref('stg_dbt__tests') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select max(run_started_at) from {{ this }})
    
    {% endif %}

),

tests as (

    select
        test_execution_id,
        command_invocation_id,
        node_id,
        test_name,
        column_name,
        run_started_at,
        materialized,
        severity,
        where_clause,
        limit,
        fail_calculation,
        warn_if,
        error_if,
        depends_on_nodes,
        depends_on_macros,
        tags,
        refs,
        sources,
        database,
        schema,
        name,
        package_name,
        path,
        compiled_sql,
        checksum,
        is_enabled,
        is_full_refresh

    from
        base

)

select * from tests
