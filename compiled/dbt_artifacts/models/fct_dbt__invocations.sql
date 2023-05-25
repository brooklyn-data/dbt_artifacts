with base as (

    select *
    from dbt_artifacts_ci_tests.dbt_artifacts_test_commit__0378fead257544898c29fb3ee9620c75b3b7a9cf.stg_dbt__invocations

),

invocations as (

    select
        command_invocation_id,
        dbt_version,
        project_name,
        run_started_at,
        dbt_command,
        full_refresh_flag,
        target_profile_name,
        target_name,
        target_schema,
        target_threads,
        dbt_cloud_project_id,
        dbt_cloud_job_id,
        dbt_cloud_run_id,
        dbt_cloud_run_reason_category,
        dbt_cloud_run_reason,
        env_vars,
        dbt_vars,
        invocation_args,
        dbt_custom_envs
    from base

)

select * from invocations