/* Bigquery won't let us `where` without `from` so we use this workaround */
with
    dummy_cte as (

        select 1 as foo

    )

select
    cast(null as {{ type_string() }}) as command_invocation_id
    , cast(null as {{ type_string() }}) as node_id
    , cast(null as {{ type_timestamp() }}) as run_started_at
    , cast(null as {{ type_string() }}) as name
    {% if target.type == "clickhouse" %}
        , cast(null as {{ type_string() }}) as depends_on_nodes
    {% else %}
        , cast(null as {{ type_array() }}) as depends_on_nodes
    {% endif %}
    , cast(null as {{ type_string() }}) as package_name
    , cast(null as {{ type_string() }}) as test_path
    {% if target.type == "clickhouse" %}
        , cast(null as {{ type_string() }}) as tags
    {% else %}
        , cast(null as {{ type_array() }}) as tags
    {% endif %}
    , cast(null as {{ type_json() }}) as all_results
from dummy_cte
where 1 = 0

