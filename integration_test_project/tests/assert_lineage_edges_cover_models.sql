{{ config(enabled = target.type == "snowflake") }}
-- lineage_edges must be non-empty, and every model in the latest graph
-- state that declares dependencies must appear as a child of >= 1 edge.
-- Fails (returns rows) for any model-with-deps that has no edge.
with latest_models as (
    select
        node_id
        , depends_on_nodes
        , row_number() over (
            partition by node_id order by run_started_at desc
        ) as run_rank
    from {{ ref("stg_dbt__models") }}
),

models_with_deps as (
    select node_id
    from latest_models
    where run_rank = 1
        and array_size(depends_on_nodes) > 0
),

edge_children as (
    select distinct child_node_id
    from {{ ref("dim_dbt__lineage_edges") }}
)

select models_with_deps.node_id as model_missing_edge
from models_with_deps
left join edge_children on models_with_deps.node_id = edge_children.child_node_id
where edge_children.child_node_id is null
