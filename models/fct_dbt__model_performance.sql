{{ config(enabled = target.type == "snowflake") }}

{#-
    Runtime-regression detection: one row per UTC day x node_id (models).

    Runtime stats (median/p95/rows_affected) are computed over SUCCESSFUL,
    NON-full-refresh executions only -- a full refresh is not a regression, and
    failures are O-03's job. full_refresh_executions is exposed as a count so
    the signal isn't lost.

    baseline_runtime = median of the SAME node's SAME-day-of-week median_runtime
    over the trailing dbt_artifacts_run_rate_days (default 28) days, EXCLUDING
    the current day (28 days = 4 balanced weekday samples). is_regressed fires
    only when the ratio exceeds dbt_artifacts_regression_threshold (default 1.5)
    AND the baseline was built from at least dbt_artifacts_regression_min_samples
    (default 3) same-DOW days -- so a thin baseline never cries wolf.
-#}

with
    executions as (
        select
            node_id
            , {{ dbt_artifacts.cast_to_utc_date("run_started_at") }} as date_day
            , status
            , total_node_runtime
            , rows_affected
            , was_full_refresh
        from {{ ref("stg_dbt__model_executions") }}
    ),

    daily as (
        select
            date_day
            , node_id
            , count(*) as executions
            , sum(case when status = 'success' then 1 else 0 end) as success_count
            , sum(case when was_full_refresh then 1 else 0 end) as full_refresh_executions
            , {{ dbt_artifacts.median(
                    "case when status = 'success' and not was_full_refresh then total_node_runtime end"
                ) }} as median_runtime
            , {{ dbt_artifacts.p95(
                    "case when status = 'success' and not was_full_refresh then total_node_runtime end"
                ) }} as p95_runtime
            , sum(
                case when status = 'success' and not was_full_refresh then rows_affected else 0 end
            ) as rows_affected_sum
        from executions
        group by date_day, node_id
    ),

    baseline as (
        select
            cur.date_day
            , cur.node_id
            , {{ dbt_artifacts.median("hist.median_runtime") }} as baseline_runtime
            , count(distinct hist.date_day) as baseline_sample_days
        from daily as cur
        left join daily as hist
            on cur.node_id = hist.node_id
            and dayofweekiso(hist.date_day) = dayofweekiso(cur.date_day)
            and hist.date_day < cur.date_day
            and hist.date_day
                >= dateadd('day', -{{ var("dbt_artifacts_run_rate_days", 28) }}, cur.date_day)
            and hist.median_runtime is not null
        group by cur.date_day, cur.node_id
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["daily.date_day", "daily.node_id"]) }}
                as model_performance_id
            , daily.date_day
            , daily.node_id
            , daily.executions
            , daily.success_count
            , daily.full_refresh_executions
            , daily.median_runtime
            , daily.p95_runtime
            , daily.rows_affected_sum
            , baseline.baseline_runtime
            , baseline.baseline_sample_days
            , case
                when baseline.baseline_runtime > 0
                    then daily.median_runtime / baseline.baseline_runtime
            end as runtime_regression_ratio
            , case
                when baseline.baseline_runtime > 0
                    and daily.median_runtime / baseline.baseline_runtime
                        > {{ var("dbt_artifacts_regression_threshold", 1.5) }}
                    and baseline.baseline_sample_days
                        >= {{ var("dbt_artifacts_regression_min_samples", 3) }}
                    then true
                else false
            end as is_regressed
        from daily
        left join baseline
            on daily.date_day = baseline.date_day
            and daily.node_id = baseline.node_id
    )

select *
from final
