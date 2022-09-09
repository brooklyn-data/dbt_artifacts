{{
    config(
        materialization='table'
    )
}}

with base as (

    select * from {{ ref('stg_dbt__invocations') }}

),

names as (

    select * from {{ ref('stg_dbt__jobs') }}

),

final as (

    select distinct
        base.job_sk
      , base.job_id
      , base.dbt_cloud_job_id
      , base.core_job_id
      , names.name
      , nvl2(base.dbt_cloud_job_id, true, false)::boolean as is_dbt_cloud_job
      , nvl2(coalesce(base.dbt_cloud_job_id, base.core_job_id), false, true)::boolean as is_local_dev

    from base
    left join names
        on base.job_sk = names.job_sk

)

select * from final