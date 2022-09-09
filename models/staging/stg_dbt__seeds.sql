{{
    config(
        materialized='incremental',
        unique_key='seed_execution_id'
    )
}}

with base as (

    select
        *
    
    from
        {{ source('dbt_artifacts', 'seeds') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select dateadd('day', -1, max(run_started_at)) from {{ this }})
    
    {% endif %}

),

enhanced as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'seed:unique_id::string']) }} as seed_execution_id,
        command_invocation_id,
        seed:unique_id::string as node_id,
        run_started_at,
        seed:config:materialized::string as materialized,
        seed:config:on_schema_change::string as on_schema_change,
        seed:config:"post-hook":sql::string as post_hook,
        seed:depends_on:nodes as depends_on_nodes,
        seed:depends_on:macros as depends_on_macros,
        seed:tags as tags,
        seed:refs as refs,
        seed:sources as sources,
        seed:database::string as database,
        seed:schema::string as schema,
        seed:name::string as name,
        seed:package_name::string as package_name,
        seed:path::string as path,
        seed:raw_sql::string as raw_sql,
        seed:checksum::string as checksum,
        seed:config:enabled::boolean as is_enabled,
        seed:config:full_refresh::boolean as is_full_refresh
    
    from
        base

)

select * from enhanced
