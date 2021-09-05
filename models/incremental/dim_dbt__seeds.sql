{{ config( materialized='incremental', unique_key='manifest_seed_id' ) }}

with dbt_seeds as (

    select * from {{ ref('stg_dbt__seeds') }}

),

dbt_seeds_incremental as (

    select *
    from dbt_seeds

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        manifest_seed_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_generated_at,
        node_id,
        seed_database,
        seed_schema,
        name,
        depends_on_nodes,
        package_name,
        seed_path,
        checksum
    from dbt_seeds_incremental

)

select * from fields