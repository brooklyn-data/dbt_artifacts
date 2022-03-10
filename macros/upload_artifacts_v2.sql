{% macro upload_dbt_artifacts_v2(prefix='target/') %}

{# All main dbt commands produce both files and so set both by default #}
{% set filenames = ['manifest', 'run_results'] %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}
{% set artifact_stage = src_dbt_artifacts.database ~ "." ~ src_dbt_artifacts.schema ~ "." ~ var('dbt_artifacts_stage', 'dbt_artifacts_stage') %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_manifest_nodes') %}

{% set remove_query %}
    remove @{{ artifact_stage }} pattern='.*.json.gz';
{% endset %}

{% set results_query %}

    insert into {{ src_results }}
        with raw_data as (

            select
                run_results.$1:metadata as metadata,
                run_results.$1:args as args,
                run_results.$1:elapsed_time::float as elapsed_time
            from @{{ artifact_stage }} as run_results

        )
        
        select
            metadata:invocation_id::string as command_invocation_id,
            -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here 
            metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            {{ make_artifact_run_id() }} as artifact_run_id,
            metadata:generated_at::timestamp_tz as artifact_generated_at,
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

{% endset %}

{% set result_nodes_query %}

    insert into {{ src_results_nodes }}
        with raw_data as (

            select
                run_results.$1:metadata as metadata,
                run_results.$1 as data,
                metadata:invocation_id::string as command_invocation_id,
                -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here 
                metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
                {{ make_artifact_run_id() }} as artifact_run_id,
                metadata:generated_at::timestamp_tz as generated_at
            from @{{ artifact_stage }} as run_results

        )

        {{ flatten_results("raw_data") }};

{% endset %}

{% set manifest_nodes_query %}

    insert into {{ src_manifest_nodes }}
        with raw_data as (

            select
                manifests.$1:metadata as metadata,
                metadata:invocation_id::string as command_invocation_id,
                -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here 
                metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
                {{ make_artifact_run_id() }} as artifact_run_id,
                metadata:generated_at::timestamp_tz as generated_at,
                manifests.$1 as data
            from @{{ artifact_stage }} as manifests

        )

        {{ flatten_manifest("raw_data") }};

{% endset %}

{% do log("Clearing existing files from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}

{% for filename in filenames %}

    {% set file = filename ~ '.json' %}

    {% set put_query %}
        put file://{{ prefix }}{{ file }} @{{ artifact_stage }} auto_compress=true;
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

    {% endif %}

    {% do log("Clearing new files from Stage: " ~ remove_query, info=True) %}
    {% do run_query(remove_query) %}

{% endfor %}

{% endmacro %}

