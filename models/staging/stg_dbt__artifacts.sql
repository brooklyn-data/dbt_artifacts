with base as (

    select *
    from {{ source('dbt_artifacts', 'artifacts') }}

),

fields as (

    select
        data,
        generated_at,
        path,
        artifact_type
    from base

)

select * from fields