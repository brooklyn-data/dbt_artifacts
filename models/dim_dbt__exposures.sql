{{
    config(
        materialized='incremental',
        unique_key='exposure_execution_id'
    )
}}

with base as (

    select
        *
    
    from
        {{ ref('stg_dbt__exposures') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select dateadd('day', -1, max(run_started_at)) from {{ this }})
    
    {% endif %}

),

exposures as (

    select
        exposure_execution_id,
        command_invocation_id,
        node_id,
        run_started_at

    from
        base

)

select * from exposures
