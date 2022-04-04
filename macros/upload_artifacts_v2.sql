{% macro upload_dbt_artifacts_v2(prefix='target/') %}

{# All main dbt commands produce both files and so set both by default #}
{% set filenames = ['manifest', 'run_results'] %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}
{% set artifact_stage = src_dbt_artifacts.database ~ "." ~ src_dbt_artifacts.schema ~ "." ~ var('dbt_artifacts_stage', 'dbt_artifacts_stage') %}

{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_manifest_nodes') %}

{# All uploads are prefixed by the invocation_id in the stage to isolate parallel jobs from one another #}
{% set remove_query %}
    remove @{{ artifact_stage }} pattern='.*\/{{ invocation_id }}\/.*\.json.gz';
{% endset %}

{% set results_query %}

    -- Merge to avoid duplicates
    merge into {{ src_results }} as old_data using (
        with raw_data as (

            select
                run_results.$1:metadata as metadata,
                run_results.$1:args as args,
                run_results.$1:elapsed_time::float as elapsed_time
            from @{{ artifact_stage }}/{{ invocation_id }} as run_results

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
            coalesce(args:models, args:select) as selected_models,
            args:target::string as target,
            metadata,
            args
        from raw_data
    ) as new_data
    on old_data.command_invocation_id = new_data.command_invocation_id
    -- NB: No clause for "when matched" - as matching rows should be skipped.
    when not matched then insert (
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        dbt_version,
        env,
        elapsed_time,
        execution_command,
        was_full_refresh,
        selected_models,
        target,
        metadata,
        args
    ) values (
        new_data.command_invocation_id,
        new_data.dbt_cloud_run_id,
        new_data.artifact_run_id,
        new_data.artifact_generated_at,
        new_data.dbt_version,
        new_data.env,
        new_data.elapsed_time,
        new_data.execution_command,
        new_data.was_full_refresh,
        new_data.selected_models,
        new_data.target,
        new_data.metadata,
        new_data.args
    )

{% endset %}

{% set result_nodes_query %}

    -- Merge to avoid duplicates
    merge into {{ src_results_nodes }} as old_data using (
        with raw_data as (

            select
                run_results.$1:metadata as metadata,
                run_results.$1 as data,
                metadata:invocation_id::string as command_invocation_id,
                -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here
                metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
                {{ make_artifact_run_id() }} as artifact_run_id,
                metadata:generated_at::timestamp_tz as generated_at
            from @{{ artifact_stage }}/{{ invocation_id }} as run_results

        )

        {{ flatten_results("raw_data") }}

    ) as new_data
    on old_data.command_invocation_id = new_data.command_invocation_id and old_data.node_id = new_data.node_id
    -- NB: No clause for "when matched" - as matching rows should be skipped.
    when not matched then insert (
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        execution_command,
        was_full_refresh,
        node_id,
        status,
        compile_started_at,
        query_completed_at,
        total_node_runtime,
        result_json
    ) values (
        new_data.command_invocation_id,
        new_data.dbt_cloud_run_id,
        new_data.artifact_run_id,
        new_data.artifact_generated_at,
        new_data.execution_command,
        new_data.was_full_refresh,
        new_data.node_id,
        new_data.status,
        new_data.compile_started_at,
        new_data.query_completed_at,
        new_data.total_node_runtime,
        new_data.result_json
    )

{% endset %}

{% set manifest_nodes_query %}

    -- Merge to avoid duplicates
    merge into {{ src_manifest_nodes }} as old_data using (
        with raw_data as (

            select
                manifests.$1:metadata as metadata,
                metadata:invocation_id::string as command_invocation_id,
                -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here
                metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
                {{ make_artifact_run_id() }} as artifact_run_id,
                metadata:generated_at::timestamp_tz as generated_at,
                manifests.$1 as data
            from @{{ artifact_stage }}/{{ invocation_id }} as manifests

        )

        {{ flatten_manifest("raw_data") }}

    ) as new_data
    -- NB: We dedupe on artifact_run_id rather than command_invocation_id for manifest nodes
    -- to avoid holding duplicate data.
    on old_data.artifact_run_id = new_data.artifact_run_id and old_data.node_id = new_data.node_id
    -- NB: No clause for "when matched" - as matching rows should be skipped.
    when not matched then insert (
        command_invocation_id,
        dbt_cloud_run_id,
        artifact_run_id,
        artifact_generated_at,
        node_id,
        resource_type,
        node_database,
        node_schema,
        name,
        node_json
    ) values (
        new_data.command_invocation_id,
        new_data.dbt_cloud_run_id,
        new_data.artifact_run_id,
        new_data.artifact_generated_at,
        new_data.node_id,
        new_data.resource_type,
        new_data.node_database,
        new_data.node_schema,
        new_data.name,
        new_data.node_json
    )

{% endset %}

{% do log("Clearing existing files from Stage: " ~ remove_query, info=True) %}
{% do run_query(remove_query) %}

{% for filename in filenames %}

    {% set file = filename ~ '.json' %}

    {% set put_query %}
        put file://{{ prefix }}{{ file }} @{{ artifact_stage }}/{{ invocation_id }} auto_compress=true;
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

