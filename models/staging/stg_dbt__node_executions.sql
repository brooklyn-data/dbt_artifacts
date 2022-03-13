with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

base_nodes as (

    select *
    from {{ ref('stg_dbt__nodes') }}

),

base_v2 as (

    select *
    from {{ source('dbt_artifacts', 'dbt_run_results_nodes') }}

),

run_results as (

    select *
    from base
    where artifact_type = 'run_results.json'

),

fields as (

    -- V1 uploads
    {{ flatten_results("run_results") }}

    union all

    -- V2 uploads
    -- NB: We can safely select * because we know the schemas are the same
    -- as they're made by the same macro.
    select * from base_v2

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['fields.command_invocation_id', 'fields.node_id']) }} as node_execution_id,
        fields.command_invocation_id,
        fields.dbt_cloud_run_id,
        fields.artifact_run_id,
        fields.artifact_generated_at,
        fields.was_full_refresh,
        fields.node_id,
        base_nodes.resource_type,
        split(fields.result_json:thread_id::string, '-')[1]::integer as thread_id,
        fields.status,
        fields.result_json:message::string as message,
        fields.compile_started_at,
        fields.query_completed_at,
        fields.total_node_runtime,
        fields.result_json:adapter_response:rows_affected::int as rows_affected,
        fields.result_json
    from fields
    -- Inner join so that we only represent results for nodes which definitely have a manifest
    -- and visa versa.
    inner join base_nodes on (
        fields.artifact_run_id = base_nodes.artifact_run_id
        and fields.node_id = base_nodes.node_id)

)

select * from surrogate_key
