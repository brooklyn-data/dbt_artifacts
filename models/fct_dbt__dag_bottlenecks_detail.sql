{{ config(enabled = target.type == "snowflake") }}

{#-
    Measured stall time, per (invocation, child, binding parent). For each
    successful child model execution, its stall against the BINDING parent is
    child.compile_started_at - max(parent.query_completed_at) among that child's
    model-parents in the same invocation (the latest-completing parent is the
    binding constraint). Negative stalls (child started before parent finished --
    different threads / non-blocking) clamp to 0.

    This is *measured* wall-clock gating, not graph theory. Model parents only;
    seed/source parents are excluded (documented) -- seeds rarely gate and keep
    the join simple. Depends on dim_dbt__lineage_edges (O-02); Snowflake-only.
-#}

with
    edges as (
        select
            parent_node_id
            , child_node_id
        from {{ ref("dim_dbt__lineage_edges") }}
        where child_resource_type = 'model'
            and parent_node_id like 'model.%'
    ),

    model_executions as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , compile_started_at
            , query_completed_at
        from {{ ref("stg_dbt__model_executions") }}
        where status = 'success'
    ),

    child_parent as (
        select
            child.command_invocation_id
            , child.node_id as child_node_id
            , child.run_started_at
            , child.compile_started_at as child_compile_started_at
            , parent.node_id as parent_node_id
            , parent.query_completed_at as parent_query_completed_at
        from model_executions as child
        inner join edges on child.node_id = edges.child_node_id
        inner join model_executions as parent
            on parent.node_id = edges.parent_node_id
            and parent.command_invocation_id = child.command_invocation_id
    ),

    binding_parent as (
        select
            command_invocation_id
            , child_node_id
            , run_started_at
            , child_compile_started_at
            , parent_node_id
            , parent_query_completed_at
        from child_parent
        qualify
            row_number() over (
                partition by command_invocation_id, child_node_id
                order by parent_query_completed_at desc, parent_node_id asc
            )
            = 1
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["command_invocation_id", "child_node_id"]) }}
                as dag_bottleneck_detail_id
            , command_invocation_id
            , {{ dbt_artifacts.cast_to_utc_date("run_started_at") }} as date_day
            , child_node_id
            , parent_node_id as binding_parent_node_id
            , parent_query_completed_at
            , child_compile_started_at
            , greatest(
                timestampdiff('millisecond', parent_query_completed_at, child_compile_started_at)
                / 1000.0,
                0
            ) as stall_seconds
        from binding_parent
    )

select *
from final
