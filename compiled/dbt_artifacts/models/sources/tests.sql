/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as TEXT) as command_invocation_id,
    cast(null as TEXT) as node_id,
    cast(null as TIMESTAMP) as run_started_at,
    cast(null as TEXT) as name,
    cast(null as 
   array
) as depends_on_nodes,
    cast(null as TEXT) as package_name,
    cast(null as TEXT) as test_path,
    cast(null as 
   array
) as tags,
    cast(null as 
   object
) as all_results
from dummy_cte
where 1 = 0