{{
    config(
        materialized='incremental',
        unique_key='snapshot_execution_id'
    )
}}

with base as (

    select
        *
    
    from
        {{ source('dbt_artifacts', 'snapshots') }}

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
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'snapshot:unique_id::string']) }} as snapshot_execution_id,
        command_invocation_id,
        snapshot:unique_id::string as node_id,
        run_started_at,
        snapshot:config:materialized::string as materialized,
        snapshot:config:on_schema_change::string as on_schema_change,
        snapshot:config:strategy::string as strategy,
        snapshot:config:check_cols as check_columns,
        snapshot:config:"post-hook":sql::string as post_hook,
        snapshot:depends_on:nodes as depends_on_nodes,
        snapshot:depends_on:macros as depends_on_macros,
        snapshot:tags as tags,
        snapshot:refs as refs,
        snapshot:sources as sources,
        snapshot:database::string as database,
        snapshot:schema::string as schema,
        snapshot:name::string as name,
        snapshot:package_name::string as package_name,
        snapshot:path::string as path,
        snapshot:raw_sql::string as raw_sql,
        snapshot:compiled_sql::string as compiled_sql,
        snapshot:checksum::string as checksum,
        snapshot:config:enabled::boolean as is_enabled,
        snapshot:config:full_refresh::boolean as is_full_refresh

    from
        base

)

select * from enhanced
