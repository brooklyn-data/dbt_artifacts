{{
    config(
        materialization='incremental'
    )
}}

with base as (

    select distinct
        run_sk
      , run_id
      , dbt_cloud_run_id
      , core_run_id
      , job_sk
    
    from {{ ref('stg_dbt__invocations') }}

    where 1 = 1 

    {% if target.name == 'reddev' %}
        and run_started_at > dateadd('day', -10, current_date)
    
    {% elif is_incremental() %}
        and run_started_at > (select dateadd('day', -1, max(started_at)) from {{ this }})
    
    {% endif %}

),

executions as (

    select
        executions__run_aggregated.*

    from
        {{ ref('executions__run_aggregated') }}
    inner join
        base
        on executions__run_aggregated.run_sk = base.run_sk

),


final as (

    select
        base.run_sk
      , base.run_id
      , base.dbt_cloud_run_id
      , base.core_run_id
      , base.job_sk
      , executions.run_started_at as started_at
      , executions.run_ended_at as ended_at
      , datediff('microsecond', started_at, ended_at) / 1000000 as total_duration
      , executions.compile_execution_time
      , executions.query_execution_time
      , executions.execution_time
      , executions.invocations
      , executions.models
      , executions.tests
      , executions.snapshots
      , executions.seeds

    from base
    left join executions
        on base.run_sk = executions.run_sk

)

select * from final