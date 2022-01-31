with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),

run_results as (

    select *
    from base
    where artifact_type = 'run_results.json'

),

dbt_run as (

    select *
    from run_results
    where data:args:which = 'test'

),

fields as (

    select
        dbt_run.command_invocation_id,
        dbt_run.dbt_cloud_run_id,
        dbt_run.artifact_run_id,
        dbt_run.generated_at as artifact_generated_at,
        coalesce(dbt_run.data:args:full_refresh, 'false')::boolean as was_full_refresh,
        result.value:unique_id::string as node_id,
        split(result.value:thread_id::string, '-')[1]::integer as thread_id,
        result.value:status::string as status,
        result.value:message::string as message,

        -- The first item in the timing array is the test-level `compile`
        result.value:timing[0]:started_at::timestamp_ntz as compile_started_at,

        -- The second item in the timing array is `execute`.
        result.value:timing[1]:completed_at::timestamp_ntz as query_completed_at,

        -- Confusingly, this does not match the delta of the above two timestamps.
        -- should we calculate it instead?
        coalesce(result.value:execution_time::float, 0) as total_node_runtime,

        result.value:adapter_response:rows_affected::int as rows_affected
    from dbt_run,
        lateral flatten(input => data:results) as result

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as test_execution_id,
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        was_full_refresh,
        node_id,
        thread_id,
        status,
        message,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        rows_affected
    from fields

)

select * from surrogate_key
