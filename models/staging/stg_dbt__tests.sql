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
        {{ source('dbt_artifacts', 'tests') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select max(run_started_at) from {{ this }})
    
    {% endif %}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'test:node_id::string']) }} as test_execution_id,
        command_invocation_id,
        test:unique_id::string as node_id,
        test:test_metadata:name::string as test_name,
        test:test_metadata:kwargs:column_name::string as column_name,
        run_started_at,
        test:config:materialized::string as materialized,
        test:config:severity::string as severity,
        test:config:where::string as where_clause,
        test:config:limit::string as limit,
        test:config:fail_calc::string as fail_calculation,
        test:config:warn_if::string as warn_if,
        test:config:error_if::string as error_if,
        test:depends_on:nodes as depends_on_nodes,
        test:depends_on:macros as depends_on_macros,
        test:tags as tags,
        test:refs as refs,
        test:sources as sources,
        test:database::string as database,
        test:schema::string as schema,
        test:name::string as name,
        test:package_name::string as package_name,
        test:path::string as path,
        test:compiled_sql::string as compiled_sql,
        test:checksum::string as checksum,
        test:config:enabled::boolean as is_enabled,
        test:config:full_refresh::boolean as is_full_refresh

    from
        base

)

select * from enhanced
