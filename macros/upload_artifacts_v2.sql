{% macro upload_dbt_artifacts_v2() %}

{# All main dbt commands produce both files and so set both by default #}
{% set filenames = ['manifest', 'run_results'] %}

{% set artifact_stage = var('dbt_artifacts_stage', 'dbt_artifacts_stage') %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_result_nodes = source('dbt_artifacts', 'dbt_run_result_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_run_manifest_nodes') %}
{% set src_manifest_sources = source('dbt_artifacts', 'dbt_run_manifest_sources') %}
{% set src_manifest_exposures = source('dbt_artifacts', 'dbt_run_manifest_exposures') %}

{% set remove_query %}
    remove @{{ artifact_stage }} pattern='.*.json.gz';
{% endset %}

{% set results_query %}
    begin;
    insert into {{ src_results }}
        with raw_data as (

            select
                run_results.$1:metadata as metadata,
                run_results.$1:args as args,
                run_results.$1:elapsed_time::float as elapsed_time
            from  @{{ artifact_stage }} as run_results

        )
        
        select
            metadata:invocation_id::string as command_invocation_id,
            metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256) as artifact_run_id,
            metadata:generated_at::timestamp_ntz as artifact_generated_at,
            metadata:dbt_version::string as dbt_version,
            metadata:env as env,
            elapsed_time,
            args:which::string as execution_command,
            coalesce(args:full_refresh, 'false')::boolean as was_full_refresh,
            args:models as selected_models,
            args:target::string as target,
            metadata,
            args
        from raw_data;
    commit;
{% endset %}

{% set result_nodes_query %}
    begin;
    insert into {{ src_result_nodes }}
        with raw_data as (

            select
                run_results.$1:metadata as metadata,
                run_results.$1:args as args,
                run_results.$1:results as results
            from  @{{ artifact_stage }} as run_results

        )
        
        select
            metadata:invocation_id::string as command_invocation_id,
            metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256) as artifact_run_id,
            metadata:generated_at::timestamp_ntz as artifact_generated_at,
            result.value:unique_id::string as node_id,
            split(result.value:thread_id::string, '-')[1]::integer as thread_id,
            result.value:status::string as status,
            -- The first item in the timing array is the model-level `compile`
            result.value:timing[0]:started_at::timestamp_ntz as compile_started_at,
            -- The second item in the timing array is `execute`.
            result.value:timing[1]:completed_at::timestamp_ntz as query_completed_at,
            -- Confusingly, this does not match the delta of the above two timestamps.
            -- should we calculate it instead?
            coalesce(result.value:execution_time::float, 0) as total_node_runtime,
            result.value:adapter_response:rows_affected::int as rows_affected,
            -- Future proof by also storing the whole json body to use later if we need to.
            result.value as result_json
        from raw_data,
            lateral flatten(input => results) as result;
    commit;
{% endset %}

{% set manifest_nodes_query %}
    begin;
    insert into {{ src_manifest_nodes }}
        with raw_data as (

            select
                manifests.$1:metadata as metadata,
                manifests.$1:nodes as nodes
            from  @{{ artifact_stage }} as manifests

        )

        select
            metadata:invocation_id::string as command_invocation_id,
            metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256) as artifact_run_id,
            metadata:generated_at::timestamp_ntz as artifact_generated_at,
            node.key as node_id,
            node.value:resource_type::string as resource_type,
            node.value:database::string as model_database,
            node.value:schema::string as model_schema,
            node.value:name::string as name,
            to_array(node.value:depends_on:nodes) as depends_on_nodes,
            node.value:package_name::string as package_name,
            node.value:path::string as model_path,
            node.value:checksum.checksum::string as checksum,
            node.value:config.materialized::string as model_materialization,
            -- Future proof by also storing the whole json body to use later if we need to.
            node.value as node_json
        from raw_data,
            lateral flatten(input => nodes) as node;
    commit;
{% endset %}

{% set manifest_sources_query %}
    begin;
    insert into {{ src_manifest_sources }}
        with raw_data as (

            select
                sources.$1:metadata as metadata,
                sources.$1:sources as sources
            from  @{{ artifact_stage }} as sources

        )

        select
            metadata:invocation_id::string as command_invocation_id,
            metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256) as artifact_run_id,
            metadata:generated_at::timestamp_ntz as artifact_generated_at,
            source.key as node_id,
            source.value:name::string as name,
            source.value:source_name::string as source_name,
            source.value:schema::string as source_schema,
            source.value:package_name::string as package_name,
            source.value:relation_name::string as relation_name,
            source.value:path::string as source_path,
            -- Future proof by also storing the whole json body to use later if we need to.
            source.value as node_json
        from raw_data,
            lateral flatten(input => sources) as source;
    commit;
{% endset %}

{% set manifest_exposures_query %}
    begin;
    insert into {{ src_manifest_exposures }}
        with raw_data as (

            select
                exposures.$1:metadata as metadata,
                exposures.$1:exposures as exposures
            from  @{{ artifact_stage }} as exposures

        )

        select
            metadata:invocation_id::string as command_invocation_id,
            metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            sha2_hex(coalesce(dbt_cloud_run_id::string, command_invocation_id::string), 256) as artifact_run_id,
            metadata:generated_at::timestamp_ntz as artifact_generated_at,
            exposure.key as node_id,
            exposure.value:name::string as name,
            to_array(exposure.value:depends_on:nodes) as depends_on_nodes,
            to_array(exposure.value:sources:nodes) as depends_on_sources,
            exposure.value:type::string as type,
            exposure.value:owner:name::string as owner,
            exposure.value:maturity::string as maturity,
            exposure.value:package_name::string as package_name,
            -- Future proof by also storing the whole json body to use later if we need to.
            exposure.value as node_json
        from raw_data,
            lateral flatten(input => exposures) as exposure;
    commit;
{% endset %}

{% do log("Clearing existing files from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}

{% for filename in filenames %}

    {% set file = filename ~ '.json' %}

    {% set put_query %}
        put file://target/{{ file }} @{{ artifact_stage }} auto_compress=true;
    {% endset %}

    {% do log("Uploading " ~ file ~ " to Stage: " ~ put_query, info=True) %}
    {% do run_query(put_query) %}

    {% if filename == 'run_results' %}
        {% do log("Persisting unflattened results " ~ file ~ " from Stage: " ~ results_query, info=True) %}
        {% do run_query(results_query) %}
        {% do log("Persisting flattened results " ~ file ~ " from Stage: " ~ result_nodes_query, info=True) %}
        {% do run_query(result_nodes_query) %}

    {% elif filename == 'manifest' %}
        {% do log("Persisting flattened manifest nodes " ~ file ~ " from Stage: " ~ manifest_nodes_query, info=True) %}
        {% do run_query(manifest_nodes_query) %}
        {% do log("Persisting flattened manifest sources " ~ file ~ " from Stage: " ~ manifest_sources_query, info=True) %}
        {% do run_query(manifest_sources_query) %}
        {% do log("Persisting flattened manifest exposures " ~ file ~ " from Stage: " ~ manifest_exposures_query, info=True) %}
        {% do run_query(manifest_exposures_query) %}

    {% endif %}

    {% do log("Clearing new files from Stage: " ~ remove_query, info=True) %}
    {% do run_query(remove_query) %}

{% endfor %}

{% endmacro %}

