{{ config(enabled = target.type == "snowflake") }}

{#-
    The current graph: each node's dependencies as of its most recent manifest
    upload. This is not a history of lineage changes.

    The manifest tables hold one row per node per uploaded invocation, so
    reading all of them means reading every graph ever uploaded. Every
    manifest upload carries the whole graph, so only uploads in the last
    dbt_artifacts_mart_lookback_days days are read. The filter is a fixed date
    so the warehouse can skip older data without reading it. Nodes removed
    from the project drop out once their last upload is older than the window.
    If no run has uploaded the manifest within the window (see
    dbt_artifacts_upload_manifest), this model is empty.
-#}

{%- set lookback_start = dbt_artifacts.mart_lookback_start() -%}

with
    models as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , depends_on_nodes
            , 'model' as resource_type
        from {{ ref("stg_dbt__models") }}
        where {{ dbt_artifacts.mart_lookback_filter("run_started_at", lookback_start) }}
    ),

    snapshots as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , depends_on_nodes
            , 'snapshot' as resource_type
        from {{ ref("stg_dbt__snapshots") }}
        where {{ dbt_artifacts.mart_lookback_filter("run_started_at", lookback_start) }}
    ),

    tests as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , depends_on_nodes
            , 'test' as resource_type
        from {{ ref("stg_dbt__tests") }}
        where {{ dbt_artifacts.mart_lookback_filter("run_started_at", lookback_start) }}
    ),

    all_nodes as (
        select * from models
        union all
        select * from snapshots
        union all
        select * from tests
    ),

    latest_per_node as (

        {# Latest graph state: keep only each node's most-recent appearance,
           mirroring the dedupe intent of dim_dbt__current_models. #}
        select
            command_invocation_id
            , node_id
            , depends_on_nodes
            , resource_type
            , row_number() over (
                partition by node_id order by run_started_at desc
            ) as run_rank
        from all_nodes
    ),

    latest_graph as (
        select * from latest_per_node where run_rank = 1
    ),

    edges as (
        select
            dep.value::string as parent_node_id
            , latest_graph.node_id as child_node_id
            , latest_graph.resource_type as child_resource_type
            , latest_graph.command_invocation_id as edge_source_invocation_id
        from latest_graph
        , {{ dbt_artifacts.flatten_json_array("latest_graph.depends_on_nodes", "dep") }}
    ),

    distinct_edges as (
        select distinct
            parent_node_id
            , child_node_id
            , child_resource_type
            , edge_source_invocation_id
        from edges
    ),

    final as (
        select
            {{ dbt_artifacts.generate_surrogate_key([
                "parent_node_id", "child_node_id", "child_resource_type"
            ]) }} as lineage_edge_id
            , parent_node_id
            , child_node_id
            , child_resource_type
            , edge_source_invocation_id
        from distinct_edges
    )

select *
from final
