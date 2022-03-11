with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

base_v2 as (

    select *
    from {{ source('dbt_artifacts', 'dbt_run_results') }}

),

run_results as (

    select *
    from base
    where artifact_type = 'run_results.json'

),

fields as (

    -- V1
    select
        generated_at::timestamp_tz as artifact_generated_at,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        data:metadata:dbt_version::string as dbt_version,
        data:metadata:env as env,
        data:elapsed_time::float as elapsed_time,
        data:args:which::string as execution_command,
        coalesce(data:args:full_refresh, 'false')::boolean as was_full_refresh,
        coalesce(data:args:models, data:args:select) as selected_models,
        data:args:target::string as target
    from run_results

    union all

    -- V2
    select
        artifact_generated_at,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        dbt_version,
        env,
        elapsed_time,
        execution_command,
        was_full_refresh,
        selected_models,
        target
    from base_v2

)

select * from fields
