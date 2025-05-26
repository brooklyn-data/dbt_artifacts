/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) as command_invocation_id,
    cast(null as {{ type_string() }}) as node_id,
    cast(null as {{ type_timestamp() }}) as run_started_at,
    cast(null as {{ type_string() }}) as thread_id,
    cast(null as {{ type_string() }}) as status,
    cast(null as {{ type_timestamp() }}) as compile_started_at,
    cast(null as {{ type_timestamp() }}) as query_completed_at,
    cast(null as {{ type_float() }}) as total_node_runtime,
    cast(null as {{ type_string() }}) as schema,
    cast(null as {{ type_string() }}) as name,
    cast(null as {{ type_string() }}) as source_name,
    cast(null as {{ type_string() }}) as loaded_at_field,
    cast(null as {{ type_int() }}) as warn_after_count,
    cast(null as {{ type_string() }}) as warn_after_period,
    cast(null as {{ type_int() }}) as error_after_count,
    cast(null as {{ type_string() }}) as error_after_period,
    cast(null as {{ type_timestamp() }}) as max_loaded_at,
    cast(null as {{ type_timestamp() }}) as snapshotted_at,
    cast(null as {{ type_float() }}) as age,
    cast(null as {{ type_json() }}) as adapter_response
from dummy_cte
where 1 = 0
