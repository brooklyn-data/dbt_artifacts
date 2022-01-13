{{
    config(
        materialized = 'incremental',
        unique_key = 'source_freshness_id'
    )
}}

with sources as (

    select distinct

        node_id,
        source_schema,
        source_path,
        name,
        relation_name

     from {{ ref('int_dbt_sources') }}

),

source_freshness_executions as (

    select * from {{ ref('int_dbt_source_freshness') }}

),

source_freshness_incremental as (

    select * from source_freshness_executions

    {% if is_incremental() %}
    -- this filter will only be applied on an incremental run
        where artifact_generated_at > (
            select max(artifact_generated_at)
            from {{ this }}
        )
    {% endif %}

),

source_freshness_executions_with_materialization as (

    select

        source_freshness_incremental.*,

        sources.source_schema,
        sources.source_path,
        sources.relation_name

    from source_freshness_incremental
    left join sources
        on source_freshness_incremental.node_id = sources.node_id

)

select * from source_freshness_executions_with_materialization