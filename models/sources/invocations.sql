/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select
    cast(null as {{ type_string() }}) as command_invocation_id,
    cast(null as {{ type_string() }}) as dbt_version,
    cast(null as {{ type_string() }}) as project_name,
    cast(null as {{ type_timestamp() }}) as run_started_at,
    cast(null as {{ type_string() }}) as dbt_command,
    cast(null as {{ type_boolean() }}) as full_refresh_flag,
    cast(null as {{ type_string() }}) as target_profile_name,
    cast(null as {{ type_string() }}) as target_name,
    cast(null as {{ type_string() }}) as target_schema,
    cast(null as {{ type_int() }}) as target_threads,
    cast(null as {{ type_string() }}) as dbt_cloud_project_id,
    cast(null as {{ type_string() }}) as dbt_cloud_job_id,
    cast(null as {{ type_string() }}) as dbt_cloud_run_id,
    cast(null as {{ type_string() }}) as dbt_cloud_run_reason_category,
    cast(null as {{ type_string() }}) as dbt_cloud_run_reason,
    cast(null as {{ type_json() }}) as env_vars,
    cast(null as {{ type_json() }}) as dbt_vars,
    cast(null as {{ type_json() }}) as invocation_args,
    cast(null as {{ type_json() }}) as dbt_custom_envs
from dummy_cte
where 1 = 0
