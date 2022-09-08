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
        {{ source('dbt_artifacts', 'invocations') }}

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
        command_invocation_id,
        coalesce(
            dbt_cloud_job_id,
            job_name,
            target_database || '.' || target_schema
        ) as job_id,
        {{ dbt_utils.surrogate_key(['job_id']) }} as job_sk,
        dbt_version,
        project_name,
        run_started_at,
        dbt_command,
        full_refresh_flag,
        target_profile_name,
        target_name,
        target_database,
        target_schema,
        target_threads,
        dbt_cloud_project_id,
        dbt_cloud_job_id,
        dbt_cloud_run_id,
        dbt_cloud_run_reason_category,
        dbt_cloud_run_reason,
        job_name,
        env_vars,
        dbt_vars,
        selected_resources

    from
        base

)

select * from enhanced
