with base as (

    select * from {{ ref('stg_dbt_artifacts') }}

),

run_results as (

    select * from base
    where artifact_type = 'run_results.json'

),

dbt_run as (

    select * from run_results
    where data:args:which = 'run'

),

fields as (

    select
        generated_at as artifact_generated_at,
        command_invocation_id,
        data:metadata:dbt_version::string as dbt_version,
        data:metadata:env as env,
        data:elapsed_time::float as elapsed_time,
        data:args:which::string as execution_command,
        coalesce(data:args:full_refresh, 'false')::boolean as was_full_refresh,
        data:args:models as selected_models,
        data:args:target::string as target,
    -- parse dbt enviornment values and cast as string to remove quotations
        data:metadata:env.DBT_CLOUD_JOB_ID::string as dbt_cloud_job_id,
        data:metadata:env.DBT_CLOUD_PROJECT_ID::string as dbt_cloud_project_id,
        data:metadata:env.DBT_CLOUD_RUN_ID::string as dbt_cloud_run_id,
        data:metadata:env.DBT_CLOUD_RUN_REASON::string as dbt_cloud_run_reason,
        data:metadata:env.DBT_CLOUD_RUN_REASON_CATEGORY::string as dbt_cloud_run_reason_cat,
        data:metadata:env.DBT_CLOUD_PR_ID::string as dbt_cloud_pr_id,
        data:metadata:env.DBT_CLOUD_GIT_SHA::string as dbt_cloud_git_sha
    from dbt_run

)

select * from fields
