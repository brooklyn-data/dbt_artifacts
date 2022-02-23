{% macro migrate_artifacts_v1_to_v2() %}

{% set src_dbt_artifacts = source('dbt_artifacts', 'artifacts') %}
{% set src_results = source('dbt_artifacts', 'dbt_run_results') %}
{% set src_results_nodes = source('dbt_artifacts', 'dbt_run_results_nodes') %}
{% set src_manifest_nodes = source('dbt_artifacts', 'dbt_manifest_nodes') %}

{% set migrate_results_query %}

    insert into {{ src_results }}
        with run_results as (

            select data
            from {{ src_dbt_artifacts }}
            where artifact_type = 'run_results.json'

        )
        
        select
            data:metadata:invocation_id::string as command_invocation_id,
            -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here 
            data:metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
            {{ make_artifact_run_id() }} as artifact_run_id,
            data:metadata:generated_at::timestamp_tz as artifact_generated_at,
            data:metadata:dbt_version::string as dbt_version,
            data:metadata:env as env,
            data:elapsed_time,
            data:args:which::string as execution_command,
            coalesce(data:args:full_refresh, 'false')::boolean as was_full_refresh,
            data:args:models as selected_models,
            data:args:target::string as target,
            data:metadata,
            data:args
        from run_results;

{% endset %}

{% set migrate_results_nodes_query %}

    insert into {{ src_results_nodes }}
        with run_results as (

            select data
            from {{ src_dbt_artifacts }}
            where artifact_type = 'run_results.json'

        ),
        
        raw_data as (

            select
                data:metadata as metadata,
                data,
                metadata:invocation_id::string as command_invocation_id,
                -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here 
                metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
                {{ make_artifact_run_id() }} as artifact_run_id,
                metadata:generated_at::timestamp_tz as generated_at
            from run_results

        )

        {{ flatten_results("raw_data") }};

{% endset %}

{% set migrate_manifest_nodes_query %}

    insert into {{ src_manifest_nodes }}
        with manifests as (

            select data
            from {{ src_dbt_artifacts }}
            where artifact_type = 'manifest.json'

        ),
        
        raw_data as (

            select
                data:metadata as metadata,
                metadata:invocation_id::string as command_invocation_id,
                -- NOTE: DBT_CLOUD_RUN_ID is case sensitive here 
                metadata:env:DBT_CLOUD_RUN_ID::int as dbt_cloud_run_id,
                {{ make_artifact_run_id() }} as artifact_run_id,
                metadata:generated_at::timestamp_tz as generated_at,
                data
            from manifests

        )

        {{ flatten_manifest("raw_data") }};

{% endset %}

{% set truncate_artifacts_query %}

    truncate {{ src_dbt_artifacts }}

{% endset %}

{% do log("Migrating Results: " ~ migrate_results_query, info=True) %}
{% do run_query(migrate_results_query) %}

{% do log("Migrating Result Nodes: " ~ migrate_results_nodes_query, info=True) %}
{% do run_query(migrate_results_nodes_query) %}

{% do log("Migrating Manifest Nodes: " ~ migrate_manifest_nodes_query, info=True) %}
{% do run_query(migrate_manifest_nodes_query) %}

{% do log("Truncating Artifacts Table: " ~ truncate_artifacts_query, info=True) %}
{% do run_query(truncate_artifacts_query) %}

{% do log("DONE! :)", info=True) %}

{% endmacro %}

