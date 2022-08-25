{{
    config(
        materialized='incremental',
        unique_key='command_invocation_id'
    )
}}

with base as (

    select
        *
    
    from
        {{ ref('stg_dbt__invocations') }}

    where
        1 = 1
    
    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select max(run_started_at) from {{ this }})
    
    {% endif %}

),

executions as (

    select
        executions__aggregated.*

    from
        {{ ref('executions__aggregated') }}
    inner join
        base
        on executions__aggregated.command_invocation_id = base.command_invocation_id

),

invocations as (

    select
        base.command_invocation_id,
        base.job_id,
        base.dbt_version,
        base.project_name,
        base.run_started_at,
        executions.run_ended_at,
        base.dbt_command,
        base.full_refresh_flag,
        base.target_profile_name,
        base.target_name,
        base.target_database,
        base.target_schema,
        base.target_threads,
        base.dbt_cloud_project_id,
        base.dbt_cloud_job_id,
        base.dbt_cloud_run_id,
        base.dbt_cloud_run_reason_category,
        base.dbt_cloud_run_reason,
        base.job_name,
        base.env_vars,
        base.dbt_vars,
        base.selected_resources,
        executions.models,
        executions.tests,
        executions.snapshots,
        executions.seeds,
        executions.compile_execution_time,
        executions.query_execution_time,
        executions.execution_time

    from
        base
    left join
        executions
        on base.command_invocation_id = executions.command_invocation_id

)

select * from invocations
