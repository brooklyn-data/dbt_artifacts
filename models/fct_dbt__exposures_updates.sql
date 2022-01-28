with model_executions as (

    select * from {{ ref('fct_dbt__model_executions') }}

),

exposures_record as (

    select * from {{ ref('dim_dbt__exposures') }}

),


model_updates as (

    select
        max(query_completed_at) as latest_update,
        node_id
    from model_executions
    group by node_id

),

exposures_latest as (

    select
        artifact_generated_at as latest_generation,
        node_id,
        name,
        type,
        owner,
        maturity,
        package_name,
        output_feeds
    from exposures_record
    where artifact_generated_at = (select max(artifact_generated_at) from exposures_record)

),

exposures_updates as (

    select
        exposures_latest.latest_generation,
        exposures_latest.node_id,
        exposures_latest.name,
        exposures_latest.type,
        exposures_latest.owner,
        exposures_latest.maturity,
        exposures_latest.package_name,
        exposures_latest.output_feeds,
        model_updates.latest_update as feed_latest_update
    from exposures_latest
    left join model_updates
        on exposures_latest.output_feeds = model_updates.node_id

)

select * from exposures_updates
