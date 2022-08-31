{{
    config(
        materialization='table'
    )
}}

with base as (

    select * from {{ ref('stg_dbt__invocations') }}

),

final as (

    select distinct
        job_id
      , dbt_cloud_job_id
      , job_name
      , nvl2(dbt_cloud_job_id, true, false)::boolean as is_dbt_cloud_job

    from base

)

select * from final