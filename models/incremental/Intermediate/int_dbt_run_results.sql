{{
    config(
        materialized = 'incremental',
        unique_key = 'command_invocation_id'
    )
}}

with run_results as (

    select * from {{ ref('stg_dbt_run_results') }}

),


fields as (

    select

        run_results.*,
        -- matches our dbt job names to their job ids
        case
            when dbt_cloud_job_id = '5969'
                then 'refresh pipes'
            when dbt_cloud_job_id = '6128'
                then 'bi hourly run'
            when dbt_cloud_job_id = '11534'
                then 'inventory and toolio daily run'
            when dbt_cloud_job_id = '14409'
                then 'loyalty refresh'
            when dbt_cloud_job_id = '6295'
                then 'midweek snowplow refresh'
            when dbt_cloud_job_id = '6129'
                then 'run on pr'
            when dbt_cloud_job_id = '9895'
                then 'snapshot users'
            when dbt_cloud_job_id = '8320'
                then 'spree full refresh'
            when dbt_cloud_job_id = '7399'
                then 'weekend runs'
            when dbt_cloud_job_id = '6228'
                then 'weekly full refresh'
            when dbt_cloud_job_id = '6979'
                then 'full daily run'
            else null
        end as dbt_cloud_job_name

    from run_results

)


select * from fields

