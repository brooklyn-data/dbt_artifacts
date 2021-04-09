{{ config( materialized='incremental', unique_key='command_invocation_id' ) }}

with run_results as (

    select *
    from {{ ref('int_dbt__run_results') }}

),

incremental_run_results as (

    select *
    from run_results

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

)

select * from incremental_run_results
