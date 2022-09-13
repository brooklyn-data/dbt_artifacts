{# dbt doesn't like us ref'ing in an operation so we fetch the info from the graph #}
{% macro get_relation(get_relation_name) %}
    {% if execute %}
        {% set model_get_relation_node = graph.nodes.values() | selectattr('name', 'equalto', get_relation_name) | first %}
        {% set relation = api.Relation.create(
            database = model_get_relation_node.database,
            schema = model_get_relation_node.schema,
            identifier = model_get_relation_node.alias
        )
        %}
        {% do return(relation) %}
    {% else %}
        {% do return(api.Relation.create()) %}
    {% endif %}
{% endmacro %}

{% macro upload_results(results) -%}

    {% if execute %}

        {% if results != [] %}
            {% do log("Uploading model executions", true) %}
            {% set model_executions = dbt_artifacts.get_relation('model_executions') %}
            {% set content_model_executions = dbt_artifacts.upload_model_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=model_executions.database,
                schema_name=model_executions.schema,
                table_name=model_executions.identifier,
                content=content_model_executions
                )
            }}

            {% do log("Uploading seed executions", true) %}
            {% set seed_executions = dbt_artifacts.get_relation('seed_executions') %}
            {% set content_seed_executions = dbt_artifacts.upload_seed_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=seed_executions.database,
                schema_name=seed_executions.schema,
                table_name=seed_executions.identifier,
                content=content_seed_executions
                )
            }}

            {% do log("Uploading snapshot executions", true) %}
            {% set snapshot_executions = dbt_artifacts.get_relation('snapshot_executions') %}
            {% set content_snapshot_executions = dbt_artifacts.upload_snapshot_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=snapshot_executions.database,
                schema_name=snapshot_executions.schema,
                table_name=snapshot_executions.identifier,
                content=content_snapshot_executions
                )
            }}

            {% do log("Uploading test executions", true) %}
            {% set test_executions = dbt_artifacts.get_relation('test_executions') %}
            {% set content_test_executions = dbt_artifacts.upload_test_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=test_executions.database,
                schema_name=test_executions.schema,
                table_name=test_executions.identifier,
                content=content_test_executions
                )
            }}

        {% endif %}

        {% do log("Uploading exposures", true) %}
        {% set exposures = dbt_artifacts.get_relation('exposures') %}
        {% set content_exposures = dbt_artifacts.upload_exposures(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=exposures.database,
            schema_name=exposures.schema,
            table_name=exposures.identifier,
            content=content_exposures
            )
        }}

        {% do log("Uploading tests", true) %}
        {% set tests = dbt_artifacts.get_relation('tests') %}
        {% set content_tests = dbt_artifacts.upload_tests(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=tests.database,
            schema_name=tests.schema,
            table_name=tests.identifier,
            content=content_tests
            )
        }}

        {% do log("Uploading seeds", true) %}
        {% set seeds = dbt_artifacts.get_relation('seeds') %}
        {% set content_seeds = dbt_artifacts.upload_seeds(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=seeds.database,
            schema_name=seeds.schema,
            table_name=seeds.identifier,
            content=content_seeds
            )
        }}

        {% do log("Uploading models", true) %}
        {% set models = dbt_artifacts.get_relation('models') %}
        {% set content_models = dbt_artifacts.upload_models(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=models.database,
            schema_name=models.schema,
            table_name=models.identifier,
            content=content_models
            )
        }}

        {% do log("Uploading sources", true) %}
        {% set sources = dbt_artifacts.get_relation('sources') %}
        {% set content_sources = dbt_artifacts.upload_sources(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=sources.database,
            schema_name=sources.schema,
            table_name=sources.identifier,
            content=content_sources
            )
        }}

        {% do log("Uploading snapshots", true) %}
        {% set snapshots = dbt_artifacts.get_relation('snapshots') %}
        {% set content_snapshots = dbt_artifacts.upload_snapshots(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=snapshots.database,
            schema_name=snapshots.schema,
            table_name=snapshots.identifier,
            content=content_snapshots
            )
        }}

        {% do log("Uploading invocations", true) %}
        {% set invocations = dbt_artifacts.get_relation('invocations') %}
        {% set content_invocations = dbt_artifacts.upload_invocations() %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=invocations.database,
            schema_name=invocations.schema,
            table_name=invocations.identifier,
            content=content_invocations
            )
        }}

    {% endif %}
{%- endmacro %}
