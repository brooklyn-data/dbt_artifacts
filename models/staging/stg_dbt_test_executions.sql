with base as (

    select * from {{ ref('stg_dbt_artifacts') }}

),

run_results as (

    select * from base
    where artifact_type = 'run_results.json'

),

dbt_test as (

    select * from run_results
    where data:args:which = 'test'

),

fields as (

    select

        command_invocation_id,
        dbt_cloud_run_id,
        generated_at as artifact_generated_at,
        result.value:unique_id::string as node_id,
        split(result.value:thread_id::string, '-')[1]::integer as thread_id,
        result.value:status::string as status,

        -- The first item in the timing array is the model-level `compile`
        result.value:timing[0]:started_at::timestamp_ntz as compile_started_at,

        -- The second item in the timing array is `execute`.
        result.value:timing[1]:completed_at::timestamp_ntz as compile_completed_at,

        -- Confusingly, this does not match the delta of the above two timestamps.
        -- should we calculate it instead?
        coalesce(result.value:execution_time::float, 0) as total_node_runtime

    from dbt_test,
    lateral flatten(input => data:results) as result

),

surrogate_key as (

    select

        {{ dbt_utils.surrogate_key([
                'command_invocation_id',
                'node_id'])
            }} as test_execution_id,

        *

    from fields

)

select * from surrogate_key