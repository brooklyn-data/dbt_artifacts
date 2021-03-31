with base as (

    select *
    from {{ ref('stg_dbt__artifacts') }}

),


sources as (

    select *
    from base
    where artifact_type = 'sources.json'

),


fields as (

    select
        data:metadata:invocation_id::string as command_invocation_id,
        generated_at as artifact_generated_at,
        result.value:unique_id::string as node_id,
        split(node_id, '.')[1]::string as project_name,
        split(node_id, '.')[2]::string as source_name,
        split(node_id, '.')[3]::string as table_name,
        result.value:status::string as freshness_status,
        result.value:max_loaded_at::timestamp_ntz as max_loaded_at,
        result.value:snapshotted_at::timestamp_ntz as freshness_checked_at,
        result.value:max_loaded_at_time_ago_in_s::decimal as max_loaded_at_time_ago_in_s

    from sources,
    lateral flatten(input => data:results) as result

),

surrogate_key as (

    select
        {{ dbt_utils.surrogate_key(['command_invocation_id', 'node_id']) }} as source_freshness_execution_id,
        command_invocation_id,
        artifact_generated_at,
        node_id,
        project_name,
        source_name,
        table_name,
        freshness_status,
        max_loaded_at,
        freshness_checked_at,
        max_loaded_at_time_ago_in_s

    from fields

)

select * from fields
