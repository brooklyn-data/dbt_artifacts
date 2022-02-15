with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

base_nodes as (

    select *
    from {{ ref('stg_dbt__nodes') }}

),

run_results as (

    select *
    from base
    where artifact_type = 'run_results.json'

),

fields as (

    select
        run_results.command_invocation_id,
        run_results.dbt_cloud_run_id,
        run_results.artifact_run_id,
        run_results.generated_at as artifact_generated_at,
        run_results.data:args:which::string as execution_command,
        coalesce(run_results.data:args:full_refresh, 'false')::boolean as was_full_refresh,
        result.value:unique_id::string as node_id,
        split(result.value:thread_id::string, '-')[1]::integer as thread_id,
        result.value:status::string as status,
        result.value:message::string as message,

        -- The first item in the timing array is the model-level `compile`
        result.value:timing[0]:started_at::timestamp_ntz as compile_started_at,

        -- The second item in the timing array is `execute`.
        result.value:timing[1]:completed_at::timestamp_ntz as query_completed_at,

        -- Confusingly, this does not match the delta of the above two timestamps.
        -- should we calculate it instead?
        coalesce(result.value:execution_time::float, 0) as total_node_runtime,

        result.value:adapter_response:rows_affected::int as rows_affected
    from run_results,
        lateral flatten(input => data:results) as result

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
        fields.thread_id,
        fields.status,
        fields.message,
        fields.compile_started_at,
        fields.query_completed_at,
        fields.total_node_runtime,
        fields.rows_affected
    from fields
    -- Inner join so that we only represent results for nodes which definitely have a manifest
    -- and visa versa.
    inner join base_nodes on (
        fields.artifact_run_id = base_nodes.artifact_run_id
        and fields.node_id = base_nodes.node_id)

)

select * from surrogate_key
