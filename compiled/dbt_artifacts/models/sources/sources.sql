/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as TEXT) as command_invocation_id,
    cast(null as TEXT) as node_id,
    cast(null as TIMESTAMP) as run_started_at,
    cast(null as TEXT) as database,
    cast(null as TEXT) as schema,
    cast(null as TEXT) as source_name,
    cast(null as TEXT) as loader,
    cast(null as TEXT) as name,
    cast(null as TEXT) as identifier,
    cast(null as TEXT) as loaded_at_field,
    
        cast(null as 
   array
) as freshness,
    
    cast(null as 
   object
) as all_results
from dummy_cte
where 1 = 0