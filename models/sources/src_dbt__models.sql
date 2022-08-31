select
    cast(null as {{ type_string() }}) command_invocation_id,
    cast(null as {{ type_string() }}) node_id,
    cast(null as {{ type_timestamp() }}) run_started_at,
    cast(null as {{ type_string() }}) database,
    cast(null as {{ type_string() }}) schema,
    cast(null as {{ type_string() }}) name,
    cast(null as {{ type_array() }}) depends_on_nodes,
    cast(null as {{ type_string() }}) package_name,
    cast(null as {{ type_string() }}) path,
    cast(null as {{ type_string() }}) checksum,
    cast(null as {{ type_string() }}) materialization
where 1 = 0
