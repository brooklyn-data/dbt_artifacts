{{
    config(
        materialized='incremental',
        unique_key='source_execution_id'
    )
}}

with base as (

    select
        *
    
    from
        {{ source('dbt_artifacts', 'sources') }}

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
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'source:unique_id::string']) }} as source_execution_id,
        command_invocation_id,
        source:unique_id::string as node_id,
        run_started_at,
        source:depends_on:nodes as depends_on_nodes,
        source:depends_on:macros as depends_on_macros,
        source:tags as tags,
        source:refs as refs,
        source:loader::string as loader,
        source:source_name::string as source_name,
        source:name::string as name,
        source:package_name::string as package_name,
        source:path::string as path,
        source:checksum::string as checksum,
        source:freshness:warn_after:count::number as freshness_warn_after_count,
        source:freshness:warn_after:period::string as freshness_warn_after_period,
        source:freshness:error_after:count::number as freshness_error_after_count,
        source:freshness:error_after:period::string as freshness_error_after_period,
        source:freshness:filter::string as freshness_filter,
        source:config:enabled::boolean as is_enabled,
        source:config:full_refresh::boolean as is_full_refresh

    from
        base

)

select * from enhanced
