/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as TEXT) as command_invocation_id,
    cast(null as TEXT) as dbt_version,
    cast(null as TEXT) as project_name,
    cast(null as TIMESTAMP) as run_started_at,
    cast(null as TEXT) as dbt_command,
    cast(null as BOOLEAN) as full_refresh_flag,
    cast(null as TEXT) as target_profile_name,
    cast(null as TEXT) as target_name,
    cast(null as TEXT) as target_schema,
    cast(null as INT) as target_threads,
    cast(null as TEXT) as dbt_cloud_project_id,
    cast(null as TEXT) as dbt_cloud_job_id,
    cast(null as TEXT) as dbt_cloud_run_id,
    cast(null as TEXT) as dbt_cloud_run_reason_category,
    cast(null as TEXT) as dbt_cloud_run_reason,
    cast(null as 
   OBJECT
) as env_vars,
    cast(null as 
   OBJECT
) as dbt_vars,
    cast(null as 
   OBJECT
) as invocation_args,
    cast(null as 
   OBJECT
) as dbt_custom_envs
from dummy_cte
where 1 = 0