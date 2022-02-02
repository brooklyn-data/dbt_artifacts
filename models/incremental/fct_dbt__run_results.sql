{{ config( materialized='incremental', unique_key='command_invocation_id' ) }}

{% set env_keys = dbt_utils.get_column_values(table=ref('stg_dbt__run_results_env_keys'), column='key', default=[]) %}

with run_results as (

    select *
    from {{ ref('stg_dbt__run_results') }}

),

incremental_run_results as (

    select *
    from run_results

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        artifact_generated_at,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        dbt_version,
        elapsed_time,
        execution_command,
        selected_models,
        target,
        was_full_refresh

        {% if env_keys %}
        -- Environment keys are sorted for determinism.
        {% for key in env_keys|sort %}
        ,env:{{ key }} as env_{{ key }}
        {% endfor %}
        {% endif %}
    from incremental_run_results

)

select * from fields
