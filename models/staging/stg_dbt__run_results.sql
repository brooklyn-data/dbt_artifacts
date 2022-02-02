with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

run_results as (

    select *
    from base
    where artifact_type = 'run_results.json'

),

dbt_run as (

    select *
    from run_results
    where data:args:which in ('run', 'seed', 'snapshot', 'test')

),

fields as (

    select
        generated_at as artifact_generated_at,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        data:metadata:dbt_version::string as dbt_version,
        data:metadata:env as env,
        data:elapsed_time::float as elapsed_time,
        data:args:which::string as execution_command,
        coalesce(data:args:full_refresh, 'false')::boolean as was_full_refresh,
        data:args:models as selected_models,
        data:args:target::string as target
    from dbt_run

)

select * from fields
