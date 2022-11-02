/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) as command_invocation_id,
    cast(null as {{ type_string() }}) as node_id,
    cast(null as {{ type_timestamp() }}) as run_started_at,
    cast(null as {{ type_string() }}) as database,
    cast(null as {{ type_string() }}) as schema,
    cast(null as {{ type_string() }}) as name,
    cast(null as {{ type_array() }}) as depends_on_nodes,
    cast(null as {{ type_string() }}) as package_name,
    cast(null as {{ type_string() }}) as path,
    cast(null as {{ type_string() }}) as checksum,
    cast(null as {{ type_string() }}) as materialization,
    cast(null as {{ type_array() }}) as tags,
    cast(null as {{ type_json() }}) as meta,
    cast(null as {{ type_string() }}) as alias
from dummy_cte
where 1 = 0
