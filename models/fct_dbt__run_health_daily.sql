{{ config(enabled = target.type == "snowflake") }}

{#-
    Run-health rollup: one row per UTC day across ALL invocations (no billing
    classification -- dev failures are still failures). Node counts span
    models + seeds + snapshots + tests. Companion fct_dbt__run_health_daily_detail
    adds a target_name cut.

    Status mapping (defensive across adapters/resource types):
      success = status in ('success','pass'); failure = ('fail','failure');
      error = ('error'); skip = ('skipped','skip').
    success_rate = successes / (successes + failures + errors) (skips excluded).
    A "failed invocation" is any invocation with >=1 node in error or failure.
-#}

with
    invocations as (
        select
            command_invocation_id
            , dbt_command
            , target_name
            , run_started_at
            , {{ dbt_artifacts.cast_to_utc_date("run_started_at") }} as date_day
        from {{ ref("stg_dbt__invocations") }}
    ),

    executions as (
        select
            command_invocation_id
            , node_id
            , status
            , total_node_runtime
            , run_started_at
        from {{ ref("stg_dbt__model_executions") }}
        union all
        select
            command_invocation_id
            , node_id
            , status
            , total_node_runtime
            , run_started_at
        from {{ ref("stg_dbt__seed_executions") }}
        union all
        select
            command_invocation_id
            , node_id
            , status
            , total_node_runtime
            , run_started_at
        from {{ ref("stg_dbt__snapshot_executions") }}
        union all
        select
            command_invocation_id
            , node_id
            , status
            , total_node_runtime
            , run_started_at
        from {{ ref("stg_dbt__test_executions") }}
    ),

    exec_classified as (
        select
            e.command_invocation_id
            , i.date_day
            , e.total_node_runtime
            , e.run_started_at
            , case when e.status in ('success', 'pass') then 1 else 0 end as is_success
            , case when e.status in ('fail', 'failure') then 1 else 0 end as is_failure
            , case when e.status = 'error' then 1 else 0 end as is_error
            , case when e.status in ('skipped', 'skip') then 1 else 0 end as is_skip
        from executions as e
        inner join invocations as i
            on e.command_invocation_id = i.command_invocation_id
    ),

    node_daily as (
        select
            date_day
            , sum(is_success) as node_successes
            , sum(is_failure) as node_failures
            , sum(is_error) as node_errors
            , sum(is_skip) as node_skips
            , sum(total_node_runtime) as total_runtime_seconds
            , max(total_node_runtime) as max_node_runtime_seconds
            , min(run_started_at) as first_run_started_at
            , max(run_started_at) as last_run_started_at
        from exec_classified
        group by date_day
    ),

    invocation_daily as (
        select
            date_day
            , count(distinct command_invocation_id) as invocations
            , count(distinct dbt_command) as distinct_commands
        from invocations
        group by date_day
    ),

    failed_invocation_daily as (
        select
            date_day
            , count(distinct command_invocation_id) as failed_invocations
        from exec_classified
        where is_error = 1 or is_failure = 1
        group by date_day
    ),

    final as (
        select
            inv.date_day
            , inv.invocations
            , inv.distinct_commands
            , coalesce(nd.node_successes, 0) as node_successes
            , coalesce(nd.node_failures, 0) as node_failures
            , coalesce(nd.node_errors, 0) as node_errors
            , coalesce(nd.node_skips, 0) as node_skips
            , coalesce(fid.failed_invocations, 0) as failed_invocations
            , nd.node_successes
                / nullif(nd.node_successes + nd.node_failures + nd.node_errors, 0)
                as success_rate
            , coalesce(nd.total_runtime_seconds, 0) as total_runtime_seconds
            , nd.max_node_runtime_seconds
            , nd.first_run_started_at
            , nd.last_run_started_at
        from invocation_daily as inv
        left join node_daily as nd on inv.date_day = nd.date_day
        left join failed_invocation_daily as fid on inv.date_day = fid.date_day
    )

select *
from final
