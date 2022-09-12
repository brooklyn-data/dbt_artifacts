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
        and run_started_at > (select dateadd('day', -1, max(started_at)) from {{ this }})
    
    {% endif %}

),

executions as (

    select
        executions__invocation_aggregated.*

    from
        {{ ref('executions__invocation_aggregated') }}
    inner join
        base
        on executions__invocation_aggregated.command_invocation_id = base.command_invocation_id

),

invocations as (

    select
        base.command_invocation_id
      , base.job_id
      , base.job_sk
      , base.run_id
      , base.run_sk
      , base.dbt_cloud_project_id
      , base.dbt_cloud_job_id
      , base.dbt_cloud_run_id
      , base.core_job_id
      , base.core_run_id
      , base.dbt_version
      , base.project_name
      , base.run_started_at as started_at
      , executions.run_ended_at as ended_at
      , datediff('microsecond', started_at, ended_at) / 1000000 as total_duration
      , executions.compile_execution_time
      , executions.query_execution_time
      , executions.execution_time
      , base.dbt_command
      , base.has_full_refresh_flag
      , base.target_profile_name
      , base.target_name
      , base.target_database
      , base.target_schema
      , base.target_threads
      , base.dbt_cloud_run_reason_category
      , base.dbt_cloud_run_reason
      , base.env_vars
      , base.dbt_vars
      , base.selected_resources
      , executions.models
      , executions.model_successes
      , executions.model_errors
      , executions.model_skips
      , executions.tests
      , executions.test_passes
      , executions.test_fails
      , executions.test_skips
      , executions.test_errors
      , executions.snapshots
      , executions.seeds
      , base.run_order
      , executions.is_successful

    from
        base
    left join
        executions
        on base.command_invocation_id = executions.command_invocation_id

)

select * from invocations
