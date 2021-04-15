with model_updates as (
    select 
        max(query_completed_at) as latest_update,
        node_id
    from {{ ref('fct_dbt__model_executions') }}
    group by node_id
),

exposures as (
    select
        artifact_generated_at as latest_generation,
        node_id,
        name,
        type,
        owner,
        maturity,
        package_name,
        output_feeds
    from {{ ref('dim_dbt__exposures') }}
    where artifact_generated_at = (select max(artifact_generated_at) from {{ ref('dim_dbt__exposures') }})
)

select 
    e.latest_generation,
    e.node_id,
    e.name, 
    e.type,
    e.owner,
    e.maturity,
    e.package_name,
    e.output_feeds,
    latest_update as feed_latest_update
from exposures e
left join model_updates m
on m.node_id = e.output_feeds