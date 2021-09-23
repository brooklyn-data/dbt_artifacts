with base as (

    select * from {{ source('dbt_artifacts', 'artifacts') }}

),

fields as (

    select
        data:metadata:invocation_id::string as command_invocation_id,
        generated_at,
        path,
        artifact_type,
        data
    from base

),

duduped as (

    select
        *,
        row_number() over (
            partition by command_invocation_id, artifact_type
            order by generated_at desc
        ) as index
    from fields
    qualify index = 1 -- qualify filters down the result of the window function in this cte to select only those with the index 1

),

artifacts as (

    select
        command_invocation_id,
        generated_at,
        path,
        artifact_type,
        data
    from duduped

)

select * from artifacts