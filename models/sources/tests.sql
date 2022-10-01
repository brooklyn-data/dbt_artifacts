/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) as command_invocation_id,
    cast(null as {{ type_string() }}) as node_id,
    cast(null as {{ type_timestamp() }}) as run_started_at,
    cast(null as {{ type_string() }}) as name,
    cast(null as {{ type_string() }}) as short_name,
    cast(null as {{ type_string() }}) as test_type,
    cast(null as {{ type_string() }}) as test_severity_config,
    cast(null as {{ type_array() }}) as depends_on_nodes,
    cast(null as {{ type_string() }}) as model_refs,
    cast(null as {{ type_string() }}) as source_refs,
    cast(null as {{ type_string() }}) as package_name,
    cast(null as {{ type_string() }}) as test_path,
    cast(null as {{ type_array() }}) as tags
from dummy_cte
where 1 = 0
