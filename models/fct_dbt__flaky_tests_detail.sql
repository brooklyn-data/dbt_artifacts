{{ config(enabled = target.type == "snowflake") }}

{#-
    One row per flip event: a test that went fail/error -> pass on the SAME UTC
    day with NO parent model rebuilt in between (the "retry until green" signal).

    Flip (v1): order a test's executions by run_started_at; a pass whose
    immediately preceding execution (same test) was a fail or error on the same
    UTC day is a flip candidate. warn does NOT count as a fail. A candidate is a
    genuine flip unless a parent model (via dim_dbt__lineage_edges) had a
    successful build with run_started_at strictly between the fail and the pass
    (that's a legitimate fix, excluded). If the test has no resolvable model
    parents, we still count the flip but set parent_rebuilt_between = null --
    we don't hide the uncertainty. Depends on dim_dbt__lineage_edges (O-02);
    Snowflake-only.
-#}

with
    test_executions as (
        select
            node_id as test_node_id
            , run_started_at
            , status
            , {{ dbt_artifacts.cast_to_utc_date("run_started_at") }} as date_day
        from {{ ref("stg_dbt__test_executions") }}
    ),

    sequenced as (
        select
            test_node_id
            , run_started_at
            , status
            , date_day
            , lag(status) over (
                partition by test_node_id order by run_started_at
            ) as prev_status
            , lag(run_started_at) over (
                partition by test_node_id order by run_started_at
            ) as prev_run_started_at
            , lag(date_day) over (
                partition by test_node_id order by run_started_at
            ) as prev_date_day
        from test_executions
    ),

    flip_candidates as (
        select
            test_node_id
            , date_day
            , prev_run_started_at as failed_at
            , run_started_at as passed_at
        from sequenced
        where status = 'pass'
            and prev_status in ('fail', 'error')
            and prev_date_day = date_day
    ),

    test_model_parents as (
        select
            child_node_id as test_node_id
            , parent_node_id
        from {{ ref("dim_dbt__lineage_edges") }}
        where child_resource_type = 'test'
            and parent_node_id like 'model.%'
    ),

    candidate_parent_activity as (
        select
            fc.test_node_id
            , fc.date_day
            , fc.failed_at
            , fc.passed_at
            , count(distinct tmp.parent_node_id) as n_parents
            , count(distinct
                case
                    when me.node_id is not null then me.node_id
                end
            ) as n_parents_rebuilt_between
        from flip_candidates as fc
        left join test_model_parents as tmp
            on fc.test_node_id = tmp.test_node_id
        left join {{ ref("stg_dbt__model_executions") }} as me
            on me.node_id = tmp.parent_node_id
            and me.status = 'success'
            and me.run_started_at > fc.failed_at
            and me.run_started_at < fc.passed_at
        group by fc.test_node_id, fc.date_day, fc.failed_at, fc.passed_at
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["test_node_id", "failed_at", "passed_at"]) }}
                as flaky_test_flip_id
            , test_node_id
            , date_day
            , failed_at
            , passed_at
            , case when n_parents = 0 then null else false end as parent_rebuilt_between
        from candidate_parent_activity
        where n_parents_rebuilt_between = 0
    )

select *
from final
