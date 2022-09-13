/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) as command_invocation_id,
    cast(null as {{ type_string() }}) as node_id,
    cast(null as {{ type_timestamp() }}) as run_started_at,
    cast(null as {{ type_string() }}) as name,
    cast(null as {{ type_string() }}) as type,
    cast(null as {{ type_json() }}) as owner,
    cast(null as {{ type_string() }}) as maturity,
    cast(null as {{ type_string() }}) as path,
    cast(null as {{ type_string() }}) as description,
    cast(null as {{ type_string() }}) as url,
    cast(null as {{ type_string() }}) as package_name,
    cast(null as {{ type_array() }}) as depends_on_nodes
from dummy_cte
where 1 = 0
