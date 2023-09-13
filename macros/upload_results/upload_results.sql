{# dbt doesn't like us ref'ing in an operation so we fetch the info from the graph #}

{% macro upload_results(results) -%}

    {% if execute %}

        {% if results != [] %}
            {% do log("Uploading model executions", true) %}
            {% set model_executions = dbt_artifacts.get_relation('model_executions') %}
            {% set content_model_executions = dbt_artifacts.upload_model_executions(results) %}
            {% set fields_model_executions = dbt_artifacts.get_column_name_list('model_executions') %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=model_executions.database,
                schema_name=model_executions.schema,
                table_name=model_executions.identifier,
                fields=fields_model_executions,
                content=content_model_executions
                )
            }}

            {% do log("Uploading seed executions", true) %}
            {% set seed_executions = dbt_artifacts.get_relation('seed_executions') %}
            {% set content_seed_executions = dbt_artifacts.upload_seed_executions(results) %}
            {% set fields_seed_executions = dbt_artifacts.get_column_name_list('seed_executions') %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=seed_executions.database,
                schema_name=seed_executions.schema,
                table_name=seed_executions.identifier,
                fields=fields_seed_executions,
                content=content_seed_executions
                )
            }}

            {% do log("Uploading snapshot executions", true) %}
            {% set snapshot_executions = dbt_artifacts.get_relation('snapshot_executions') %}
            {% set content_snapshot_executions = dbt_artifacts.upload_snapshot_executions(results) %}
            {% set fields_snapshot_executions = dbt_artifacts.get_column_name_list('snapshot_executions') %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=snapshot_executions.database,
                schema_name=snapshot_executions.schema,
                table_name=snapshot_executions.identifier,
                fields=fields_snapshot_executions,
                content=content_snapshot_executions
                )
            }}

            {% do log("Uploading test executions", true) %}
            {% set test_executions = dbt_artifacts.get_relation('test_executions') %}
            {% set content_test_executions = dbt_artifacts.upload_test_executions(results) %}
            {% set fields_test_executions = dbt_artifacts.get_column_name_list('test_executions') %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=test_executions.database,
                schema_name=test_executions.schema,
                table_name=test_executions.identifier,
                fields=fields_test_executions,
                content=content_test_executions
                )
            }}

        {% endif %}

        {% do log("Uploading exposures", true) %}
        {% set exposures = dbt_artifacts.get_relation('exposures') %}
        {% set content_exposures = dbt_artifacts.upload_exposures(graph) %}
        {% set fields_exposures = dbt_artifacts.get_column_name_list('exposures') %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=exposures.database,
            schema_name=exposures.schema,
            table_name=exposures.identifier,
            fields=fields_exposures,
            content=content_exposures
            )
        }}

        {% do log("Uploading tests", true) %}
        {% set tests = dbt_artifacts.get_relation('tests') %}
        {% set tests_set = [] %}
        {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "test") %}
            {% do tests_set.append(node) %}
        {% endfor %}
        {% set fields_tests = dbt_artifacts.get_column_name_list('tests') %}
        {# upload tests in chunks of 5000 tests (300 for BigQuery), or less #}
        {% set upload_limit = 300 if target.type == 'bigquery' else 5000 %}
        {% for i in range(0, tests_set | length, upload_limit) -%}
            {% set content_tests = dbt_artifacts.upload_tests(tests_set[i: i + upload_limit]) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=tests.database,
                schema_name=tests.schema,
                table_name=tests.identifier,
                fields=fields_tests,
                content=content_tests
                )
            }}
        {%- endfor %}

        {% do log("Uploading seeds", true) %}
        {% set seeds = dbt_artifacts.get_relation('seeds') %}
        {% set fields_seeds = dbt_artifacts.get_column_name_list('seeds') %}
        {% set content_seeds = dbt_artifacts.upload_seeds(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=seeds.database,
            schema_name=seeds.schema,
            table_name=seeds.identifier,
            fields=fields_seeds,
            content=content_seeds
            )
        }}

        {% do log("Uploading models", true) %}
        {% set models = dbt_artifacts.get_relation('models') %}
        {% set models_set = [] %}
        {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}
            {% do models_set.append(node) %}
        {% endfor %}
        {% set fields_models = dbt_artifacts.get_column_name_list('models') %}
        {% set upload_limit = 50 if target.type == 'bigquery' else 100 %}
        {% for i in range(0, models_set | length, upload_limit) -%}
            {% set content_models = dbt_artifacts.upload_models(models_set[i: i + upload_limit]) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=models.database,
                schema_name=models.schema,
                table_name=models.identifier,
                fields=fields_models,
                content=content_models
                )
            }}
        {%- endfor %}

        {% do log("Uploading sources", true) %}
        {% set sources = dbt_artifacts.get_relation('sources') %}
        {% set sources_set = [] %}
        {% for node in graph.sources.values() %}
            {% do sources_set.append(node) %}
        {% endfor %}
        {% set fields_sources = dbt_artifacts.get_column_name_list('sources') %}
        {# upload sources in chunks of 5000 sources (300 for BigQuery), or less #}
        {% set upload_limit = 300 if target.type == 'bigquery' else 5000 %}
        {% for i in range(0, sources_set | length, upload_limit) -%}
            {% set content_sources = dbt_artifacts.upload_sources(sources_set[i: i + upload_limit]) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=sources.database,
                schema_name=sources.schema,
                table_name=sources.identifier,
                fields=fields_sources,
                content=content_sources
                )
            }}
        {%- endfor %}

        {% do log("Uploading snapshots", true) %}
        {% set snapshots = dbt_artifacts.get_relation('snapshots') %}
        {% set fields_snapshots = dbt_artifacts.get_column_name_list('snapshots') %}
        {% set content_snapshots = dbt_artifacts.upload_snapshots(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=snapshots.database,
            schema_name=snapshots.schema,
            table_name=snapshots.identifier,
            fields=fields_snapshots,
            content=content_snapshots
            )
        }}

        {% do log("Uploading invocations", true) %}
        {% set invocations = dbt_artifacts.get_relation('invocations') %}
        {% set fields_invocations = dbt_artifacts.get_column_name_list('invocations') %}
        {% set content_invocations = dbt_artifacts.upload_invocations() %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=invocations.database,
            schema_name=invocations.schema,
            table_name=invocations.identifier,
            fields=fields_invocations,
            content=content_invocations
            )
        }}

    {% endif %}
{%- endmacro %}
