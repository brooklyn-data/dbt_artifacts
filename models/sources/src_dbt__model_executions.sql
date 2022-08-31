/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) command_invocation_id,
    cast(null as {{ type_string() }}) node_id,
    cast(null as {{ type_timestamp() }}) run_started_at,
    cast(null as {{ type_boolean() }}) was_full_refresh,
    cast(null as {{ type_string() }}) thread_id,
    cast(null as {{ type_string() }}) status,
    cast(null as {{ type_timestamp() }}) compile_started_at,
    cast(null as {{ type_timestamp() }}) query_completed_at,
    cast(null as {{ type_float() }}) total_node_runtime,
    cast(null as {{ type_int() }}) rows_affected,
    {% if target.type == 'bigquery' %}
        cast(null as {{ type_int() }}) bytes_processed,
    {% endif %}
    cast(null as {{ type_string() }}) materialization,
    cast(null as {{ type_string() }}) schema,
    cast(null as {{ type_string() }}) name
from dummy_cte
where 1 = 0
