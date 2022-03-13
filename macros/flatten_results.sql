{% macro flatten_results(results_cte_name) %}

    select
        run_results.command_invocation_id,
        run_results.dbt_cloud_run_id,
        run_results.artifact_run_id,
        run_results.generated_at::timestamp_tz as artifact_generated_at,
        run_results.data:args:which::string as execution_command,
        coalesce(run_results.data:args:full_refresh, 'false')::boolean as was_full_refresh,
        result.value:unique_id::string as node_id,
        result.value:status::string as status,

        -- The first item in the timing array is the model-level `compile`
        result.value:timing[0]:started_at::timestamp_tz as compile_started_at,

        -- The second item in the timing array is `execute`.
        result.value:timing[1]:completed_at::timestamp_tz as query_completed_at,

        -- Confusingly, this does not match the delta of the above two timestamps.
        -- should we calculate it instead?
        coalesce(result.value:execution_time::float, 0) as total_node_runtime,

        -- Include the raw JSON to unpack the rest later.
        result.value as result_json
    from {{ results_cte_name }} as run_results,
        lateral flatten(input => run_results.data:results) as result

{% endmacro %}
