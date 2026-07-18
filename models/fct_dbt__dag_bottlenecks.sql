{{ config(enabled = target.type == "snowflake") }}

{#-
    Per parent model x UTC day: how much wall-clock time its children spent
    waiting on it (measured stall). The "pinch point" mart. Roll-up of
    fct_dbt__dag_bottlenecks_detail over rows where the parent actually gated a
    child (stall_seconds > 0). Descendant counts / blocking scores are out of
    scope for v1 (parked). Snowflake-only (inherits O-02 enablement).
-#}

with
    detail as (select * from {{ ref("fct_dbt__dag_bottlenecks_detail") }}),

    gating as (
        select *
        from detail
        where stall_seconds > 0
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key(["date_day", "binding_parent_node_id"]) }}
                as dag_bottleneck_id
            , date_day
            , binding_parent_node_id as parent_node_id
            , count(distinct child_node_id) as blocked_children
            , sum(stall_seconds) as total_stall_seconds
            , max(stall_seconds) as max_stall_seconds
            , count(distinct command_invocation_id) as invocations_observed
        from gating
        group by date_day, binding_parent_node_id
    )

select *
from final
