{{ config(enabled = target.type == "snowflake") }}

with
    models as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , depends_on_nodes
            , 'model' as resource_type
        from {{ ref("stg_dbt__models") }}
    ),

    snapshots as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , depends_on_nodes
            , 'snapshot' as resource_type
        from {{ ref("stg_dbt__snapshots") }}
    ),

    tests as (
        select
            command_invocation_id
            , node_id
            , run_started_at
            , depends_on_nodes
            , 'test' as resource_type
        from {{ ref("stg_dbt__tests") }}
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
