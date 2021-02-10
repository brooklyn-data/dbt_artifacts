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
    where data:args:which = 'run'

),

fields as (

    select
        data:metadata:invocation_id::string as command_invocation_id,
        generated_at as artifact_generated_at,
        coalesce(data:args:full_refresh, 'false')::boolean as was_full_refresh,
        result.value:unique_id::string as node_id,
        result.value:status::string as status,
        -- Incremental models have a null execution_time, so coalesce to 0 for calculations
        coalesce(result.value:execution_time::float, 0) as execution_time,
        result.value:adapter_response:rows_affected::int as rows_affected
    from dbt_run,
    lateral flatten(input => data:results) as result

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as model_execution_id,
        command_invocation_id,
        artifact_generated_at,
        was_full_refresh,
        node_id,
        status,
        execution_time,
        rows_affected
    from fields

)

select * from surrogate_key
