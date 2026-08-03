{{ config(enabled = target.type == "snowflake") }}
-- lineage_edges must be non-empty, and every model in the latest graph
-- state that declares dependencies must appear as a child of >= 1 edge.
-- Fails (returns rows) for any model-with-deps that has no edge, and for an
-- empty mart. The empty-mart branch matters: without it this test passes
-- vacuously when the mart has no rows at all, since models_with_deps is
-- itself empty in that case.
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
),

edge_count as (
    select count(*) as row_count
    from {{ ref("dim_dbt__lineage_edges") }}
)

select 'model_missing_edge: ' || models_with_deps.node_id as issue
from models_with_deps
left join edge_children on models_with_deps.node_id = edge_children.child_node_id
where edge_children.child_node_id is null

union all

select 'empty_mart' as issue
from edge_count
where row_count = 0
