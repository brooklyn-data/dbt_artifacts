/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) command_invocation_id,
    cast(null as {{ type_string() }}) node_id,
    cast(null as {{ type_timestamp() }}) run_started_at,
    cast(null as {{ type_string() }}) name,
    cast(null as {{ type_array() }}) depends_on_nodes,
    cast(null as {{ type_string() }}) package_name,
    cast(null as {{ type_string() }}) test_path,
    cast(null as {{ type_array() }}) tags
from dummy_cte
where 1 = 0
