/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as TEXT) as command_invocation_id,
    cast(null as TEXT) as node_id,
    cast(null as TIMESTAMP) as run_started_at,
    cast(null as BOOLEAN) as was_full_refresh,
    cast(null as TEXT) as thread_id,
    cast(null as TEXT) as status,
    cast(null as TIMESTAMP) as compile_started_at,
    cast(null as TIMESTAMP) as query_completed_at,
    cast(null as FLOAT) as total_node_runtime,
    cast(null as INT) as rows_affected,
    
    cast(null as TEXT) as materialization,
    cast(null as TEXT) as schema,
    cast(null as TEXT) as name,
    cast(null as TEXT) as alias,
    cast(null as TEXT) as message,
    cast(null as 
   object
) as adapter_response
from dummy_cte
where 1 = 0