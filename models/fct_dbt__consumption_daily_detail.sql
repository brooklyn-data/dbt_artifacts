{{ config(enabled = target.type == "snowflake") }}

{#-
    Detail grain for consumption: UTC day x meter x materialization x target_name.
    This is the BASE grain; fct_dbt__consumption_daily is a strict roll-up of
    this model (sum of quantity), so the two always reconcile by construction.

    Meters (v1):
      - 'smb'  : Successful Models Built. One row per successful model execution
                 in a deployment-classed invocation whose dbt_command is
                 run/build/retry (mirrors dbt's published SMB rules). Additive.
      - 'active_target_tables' : distinct node_ids (models u seeds u snapshots u
                 tests) with >=1 successful deployment execution that day, counted
                 per deployment target (materialization is null). On single-
                 deployment-target setups (the common case) this equals a plain
                 per-day distinct-node count; when
                 a node runs under several deployment targets in one day it is
                 counted once per target, which keeps the roll-up additive.
-#}

with
    model_executions as (
        select
            me.node_id
            , me.status
            , me.materialization
            , {{ dbt_artifacts.cast_to_utc_date("me.run_started_at") }} as date_day
            , i.target_name
            , i.dbt_command
            , {{ dbt_artifacts.classify_invocation_billing() }} as billing_class
        from {{ ref("stg_dbt__model_executions") }} as me
        inner join {{ ref("stg_dbt__invocations") }} as i
            on me.command_invocation_id = i.command_invocation_id
    ),

    smb_detail as (
        select
            date_day
            , 'smb' as meter
            , materialization
            , target_name
            , count(*) as quantity
        from model_executions
        where status = 'success'
            and dbt_command in ('run', 'build', 'retry')
            and billing_class = 'deployment'
        group by date_day, materialization, target_name
    ),

    all_executions as (
        select
            node_id
            , status
            , run_started_at
            , command_invocation_id
        from {{ ref("stg_dbt__model_executions") }}
        union all
        select
            node_id
            , status
            , run_started_at
            , command_invocation_id
        from {{ ref("stg_dbt__seed_executions") }}
        union all
        select
            node_id
            , status
            , run_started_at
            , command_invocation_id
        from {{ ref("stg_dbt__snapshot_executions") }}
        union all
        select
            node_id
            , status
            , run_started_at
            , command_invocation_id
        from {{ ref("stg_dbt__test_executions") }}
    ),

    active_executions as (
        select
            ae.node_id
            , ae.status
            , {{ dbt_artifacts.cast_to_utc_date("ae.run_started_at") }} as date_day
            , i.target_name
            , {{ dbt_artifacts.classify_invocation_billing() }} as billing_class
        from all_executions as ae
        inner join {{ ref("stg_dbt__invocations") }} as i
            on ae.command_invocation_id = i.command_invocation_id
    ),

    active_target_tables_detail as (
        select
            date_day
            , 'active_target_tables' as meter
            , cast(null as {{ dbt.type_string() }}) as materialization
            , target_name
            , count(distinct node_id) as quantity
        from active_executions
        where status = 'success'
            and billing_class = 'deployment'
        group by date_day, target_name
    ),

    combined as (
        select
            date_day
            , meter
            , materialization
            , target_name
            , quantity
        from smb_detail
        union all
        select
            date_day
            , meter
            , materialization
            , target_name
            , quantity
        from active_target_tables_detail
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key([
                "date_day", "meter", "materialization", "target_name"
            ]) }} as consumption_daily_detail_id
            , date_day
            , meter
            , materialization
            , target_name
            , quantity
        from combined
    )

select *
from final
