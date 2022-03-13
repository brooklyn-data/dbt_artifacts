with base as (

    select *
    from {{ source('dbt_artifacts', 'artifacts') }}

),

fields as (

    select
        data:metadata:invocation_id::string as command_invocation_id,
        data:metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
        generated_at,
        path,
        artifact_type,
        data
    from base

),

artifacts as (

    select
        command_invocation_id,
        dbt_cloud_run_id,
        {{ make_artifact_run_id() }} as artifact_run_id,
        generated_at,
        path,
        artifact_type,
        data
    from fields

)

select * from artifacts