{% macro upload_results(results) -%}
    {% if execute %}
        {% if results != [] %}
            {% do log("Uploading model executions", true) %}
            {% set src_dbt_model_executions = source('dbt_artifacts', 'model_executions') %}
            {% set content_model_executions = dbt_artifacts.upload_model_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt_model_executions.database,
                schema_name=src_dbt_model_executions.schema,
                table_name=src_dbt_model_executions.identifier,
                content=content_model_executions
                )
            }}

            {% do log("Uploading seed executions", true) %}
            {% set src_dbt_seed_executions = source('dbt_artifacts', 'seed_executions') %}
            {% set content_seed_executions = dbt_artifacts.upload_seed_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt_seed_executions.database,
                schema_name=src_dbt_seed_executions.schema,
                table_name=src_dbt_seed_executions.identifier,
                content=content_seed_executions
                )
            }}

            {% do log("Uploading snapshot executions", true) %}
            {% set src_dbt_snapshot_executions = source('dbt_artifacts', 'snapshot_executions') %}
            {% set content_snapshot_executions = dbt_artifacts.upload_snapshot_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt_snapshot_executions.database,
                schema_name=src_dbt_snapshot_executions.schema,
                table_name=src_dbt_snapshot_executions.identifier,
                content=content_snapshot_executions
                )
            }}

            {% do log("Uploading test executions", true) %}
            {% set src_dbt_test_executions = source('dbt_artifacts', 'test_executions') %}
            {% set content_test_executions = dbt_artifacts.upload_test_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt_test_executions.database,
                schema_name=src_dbt_test_executions.schema,
                table_name=src_dbt_test_executions.identifier,
                content=content_test_executions
                )
            }}

        {% endif %}

        {% do log("Uploading exposures", true) %}
        {% set src_dbt_exposures = source('dbt_artifacts', 'exposures') %}
        {% set content_exposures = dbt_artifacts.upload_exposures(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_exposures.database,
            schema_name=src_dbt_exposures.schema,
            table_name=src_dbt_exposures.identifier,
            content=content_exposures
            )
        }}

        {% do log("Uploading tests", true) %}
        {% set src_dbt_tests = source('dbt_artifacts', 'tests') %}
        {% set content_tests = dbt_artifacts.upload_tests(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_tests.database,
            schema_name=src_dbt_tests.schema,
            table_name=src_dbt_tests.identifier,
            content=content_tests
            )
        }}

        {% do log("Uploading seeds", true) %}
        {% set src_dbt_seeds = source('dbt_artifacts', 'seeds') %}
        {% set content_seeds = dbt_artifacts.upload_seeds(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_seeds.database,
            schema_name=src_dbt_seeds.schema,
            table_name=src_dbt_seeds.identifier,
            content=content_seeds
            )
        }}

        {% do log("Uploading models", true) %}
        {% set src_dbt_models = source('dbt_artifacts', 'models') %}
        {% set content_models = dbt_artifacts.upload_models(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_models.database,
            schema_name=src_dbt_models.schema,
            table_name=src_dbt_models.identifier,
            content=content_models
            )
        }}

        {% do log("Uploading sources", true) %}
        {% set src_dbt_sources = source('dbt_artifacts', 'sources') %}
        {% set content_sources = dbt_artifacts.upload_sources(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_sources.database,
            schema_name=src_dbt_sources.schema,
            table_name=src_dbt_sources.identifier,
            content=content_sources
            )
        }}

        {% do log("Uploading snapshots", true) %}
        {% set src_dbt_snapshots = source('dbt_artifacts', 'snapshots') %}
        {% set content_snapshots = dbt_artifacts.upload_snapshots(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_snapshots.database,
            schema_name=src_dbt_snapshots.schema,
            table_name=src_dbt_snapshots.identifier,
            content=content_snapshots
            )
        }}

        {% do log("Uploading invocations", true) %}
        {% set src_dbt_invocations = source('dbt_artifacts', 'invocations') %}
        {% set content_invocations = dbt_artifacts.upload_invocations() %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_invocations.database,
            schema_name=src_dbt_invocations.schema,
            table_name=src_dbt_invocations.identifier,
            content=content_invocations
            )
        }}

    {% endif %}
{%- endmacro %}
