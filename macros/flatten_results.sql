{% macro flatten_results(results_cte_name) %}

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

        result.value:adapter_response:rows_affected::int as rows_affected,

        -- Include the raw JSON for future proofing.
        result.value as result_json
    from {{ results_cte_name }} as run_results,
        lateral flatten(input => run_results.data:results) as result

{% endmacro %}
