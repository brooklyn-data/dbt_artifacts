/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (select 1 as foo)

select
    cast(null as {{ type_string() }}) as command_invocation_id,
    cast(null as {{ type_string() }}) as node_id,
    cast(null as {{ type_timestamp() }}) as run_started_at,
    cast(null as {{ type_string() }}) as {% if target.type == "sqlserver" %} "database"
    {% else %} database
    {% endif %},
    cast(null as {{ type_string() }}) as {% if target.type == "sqlserver" %} "schema"
    {% else %} schema
    {% endif %},
    cast(null as {{ type_string() }}) as source_name,
    cast(null as {{ type_string() }}) as loader,
    cast(null as {{ type_string() }}) as name,
    cast(null as {{ type_string() }}) as identifier,
    cast(null as {{ type_string() }}) as loaded_at_field
    {% if target.type == "snowflake" %}, cast(null as {{ type_array() }}) as freshness
    {% else %}, cast(null as {{ type_json() }}) as freshness
    {% endif %},
    cast(null as {{ type_json() }}) as all_results
from dummy_cte
where 1 = 0

