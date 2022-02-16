{% macro flatten_manifest(manifest_cte_name) %}

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at as artifact_generated_at,
        node.key as node_id,
        node.value:resource_type::string as resource_type,
        node.value:database::string as node_database,
        node.value:schema::string as node_schema,
        node.value:name::string as name,
        to_array(node.value:depends_on:nodes) as depends_on_nodes,
        null as depends_on_sources,
        null as exposure_type,
        null as exposure_owner,
        null as exposure_maturity,
        null as source_name,
        node.value:package_name::string as package_name,
        null as relation_name,
        node.value:path::string as node_path,
        node.value:checksum.checksum::string as checksum,
        node.value:config.materialized::string as materialization,
        -- Include the raw JSON for future proofing.
        node.value as node_json
    from {{ manifest_cte_name }} as manifests,
        lateral flatten(input => manifests.data:nodes) as node

    union all

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at as artifact_generated_at,
        exposure.key as node_id,
        'exposure' as resource_type,
        null as node_database,
        null as node_schema,
        exposure.value:name::string as name,
        to_array(exposure.value:depends_on:nodes) as depends_on_nodes,
        to_array(exposure.value:sources:nodes) as depends_on_sources,
        exposure.value:type::string as exposure_type,
        exposure.value:owner:name::string as exposure_owner,
        exposure.value:maturity::string as exposure_maturity,
        null as source_name,
        exposure.value:package_name::string as package_name,
        null as relation_name,
        null as node_path,
        null as checksum,
        null as materialization,
        -- Include the raw JSON for future proofing.
        exposure.value as node_json
    from {{ manifest_cte_name }} as manifests,
        lateral flatten(input => manifests.data:exposures) as exposure

    union all

    select
        manifests.command_invocation_id,
        manifests.dbt_cloud_run_id,
        manifests.artifact_run_id,
        manifests.generated_at as artifact_generated_at,
        source.key as node_id,
        'source' as resource_type,
        source.value:database::string as node_database,
        source.value:schema::string as node_schema,
        source.value:name::string::string as name,
        null as depends_on_nodes,
        null as depends_on_sources,
        null as exposure_type,
        null as exposure_owner,
        null as exposure_maturity,
        source.value:source_name::string as source_name,
        source.value:package_name::string as package_name,
        source.value:relation_name::string as relation_name,
        source.value:path::string as node_path,
        null as checksum,
        null as materialization,
        -- Include the raw JSON for future proofing.
        source.value as node_json
    from {{ manifest_cte_name }} as manifests,
        lateral flatten(input => manifests.data:sources) as source

{% endmacro %}
