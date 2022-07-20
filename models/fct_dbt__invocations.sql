with base as (

    select *
    from {{ ref('stg_dbt__invocations') }}

),

invocations as (

    select
        command_invocation_id,
        dbt_version,
        project_name,
        run_started_at,
        dbt_command,
        was_full_refresh,
        target_profile_name,
        target_name,
        target_schema,
        target_threads
    from base

)

select * from invocations
