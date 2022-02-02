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

deduped as (

    select
        *,
        row_number() over (
            partition by command_invocation_id, artifact_type
            order by generated_at desc
        ) as index
    from fields
    qualify index = 1

),

artifacts as (

    select
        command_invocation_id,
        dbt_cloud_run_id,
        -- This ID provides a reliable ID, regardless of whether running in a local or cloud environment.
        sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256) as artifact_run_id,
        generated_at,
        path,
        artifact_type,
        data
    from deduped

)

select * from artifacts