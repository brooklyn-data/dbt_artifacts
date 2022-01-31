{{ config( materialized='incremental', unique_key='manifest_snapshot_id' ) }}

with dbt_snapshots as (

    select * from {{ ref('stg_dbt__snapshots') }}

),

run_results as (

    select *
    from {{ ref('fct_dbt__run_results') }}

),

dbt_snapshots_incremental as (

    select dbt_snapshots.*
    from dbt_snapshots
    -- Inner join with run results to enforce consistency and avoid race conditions.
    -- https://github.com/brooklyn-data/dbt_artifacts/issues/75
    inner join run_results on
        dbt_snapshots.artifact_run_id = run_results.artifact_run_id

    {% if is_incremental() %}
        -- this filter will only be applied on an incremental run
        where dbt_snapshots.artifact_generated_at > (select max(artifact_generated_at) from {{ this }})
    {% endif %}

),

fields as (

    select
        manifest_snapshot_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        snapshot_database,
        snapshot_schema,
        name,
        depends_on_nodes,
        package_name,
        snapshot_path,
        checksum
    from dbt_snapshots_incremental

)

select * from fields