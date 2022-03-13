-- NOTE: We only flatten the fields likely to be joined or filtered
-- at this stage. The rest are flattened later in more specific models.

{% macro flatten_manifest(manifest_cte_name) %}

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at::timestamp_tz as artifact_generated_at,
        node.key as node_id,
        node.value:resource_type::string as resource_type,
        node.value:database::string as node_database,
        node.value:schema::string as node_schema,
        node.value:name::string as name,
        -- Include the raw JSON to unpack other values.
        node.value as node_json
    from {{ manifest_cte_name }} as manifests,
        lateral flatten(input => manifests.data:nodes) as node

    union all

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at::timestamp_tz as artifact_generated_at,
        exposure.key as node_id,
        'exposure' as resource_type,
        null as node_database,
        null as node_schema,
        exposure.value:name::string as name,
        -- Include the raw JSON to unpack other values.
        exposure.value as node_json
    from {{ manifest_cte_name }} as manifests,
        lateral flatten(input => manifests.data:exposures) as exposure

    union all

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at::timestamp_tz as artifact_generated_at,
        source.key as node_id,
        'source' as resource_type,
        source.value:database::string as node_database,
        source.value:schema::string as node_schema,
        source.value:name::string::string as name,
        -- Include the raw JSON to unpack other values.
        source.value as node_json
    from {{ manifest_cte_name }} as manifests,
        lateral flatten(input => manifests.data:sources) as source

{% endmacro %}
