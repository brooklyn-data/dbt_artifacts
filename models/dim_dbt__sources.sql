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
        {{ ref('stg_dbt__sources') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select dateadd('day', -1, max(run_started_at)) from {{ this }})
    
    {% endif %}

),

sources as (

    select
        source_execution_id,
        command_invocation_id,
        node_id,
        run_started_at,
        depends_on_nodes,
        depends_on_macros,
        tags,
        refs,
        loader,
        source_name,
        name,
        package_name,
        path,
        checksum,
        freshness_warn_after_count,
        freshness_warn_after_period,
        freshness_error_after_count,
        freshness_error_after_period,
        freshness_filter,
        is_enabled,
        is_full_refresh

    from
        base

)

select * from sources
