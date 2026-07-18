{#-
    "Where is the consumption going" mart: one row per billing_month x node_id
    (models only), with SMB burn, build cadence, runtime, and the dbt State ROI
    estimate.

    Uses the same SMB filter as fct_dbt__consumption_daily (deployment-classed
    invocation, status = 'success', dbt_command in run/build/retry) so the two
    marts reconcile. billing_month is the calendar month (date_trunc) of the
    UTC execution day. v1 excludes attached-test DATT counting (design's v2).
-#}

with
    model_executions as (
        select
            me.node_id
            , me.name
            , me.status
            , me.total_node_runtime
            , {{ dbt_artifacts.cast_to_utc_date("me.run_started_at") }} as date_day
            , i.dbt_command
            , {{ dbt_artifacts.classify_invocation_billing() }} as billing_class
        from {{ ref("stg_dbt__model_executions") }} as me
        inner join {{ ref("stg_dbt__invocations") }} as i
            on me.command_invocation_id = i.command_invocation_id
    ),

    smb_executions as (
        select
            node_id
            , name
            , total_node_runtime
            , date_day
            , date_trunc('month', date_day) as billing_month
        from model_executions
        where status = 'success'
            and dbt_command in ('run', 'build', 'retry')
            and billing_class = 'deployment'
    ),

    by_model as (
        select
            billing_month
            , node_id
            , max(name) as name
            , count(*) as smb_quantity
            , count(distinct date_day) as distinct_days_built
            , sum(total_node_runtime) as total_runtime_seconds
        from smb_executions
        group by billing_month, node_id
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["billing_month", "node_id"]) }}
                as consumption_by_model_id
            , billing_month
            , node_id
            , name
            , smb_quantity
            , smb_quantity
                / sum(smb_quantity) over (partition by billing_month)
                as pct_of_month_smb
            , smb_quantity / nullif(distinct_days_built, 0) as builds_per_day_avg
            , distinct_days_built
            , total_runtime_seconds
            , distinct_days_built * {{ var("dbt_artifacts_datt_price", 0.094) }}
                as estimated_monthly_datt_cost_if_reused
        from by_model
    )

select *
from final
