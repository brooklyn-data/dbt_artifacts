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
            {% set src_dbt__model_executions = dbt_artifacts.get_relation('src_dbt__model_executions') %}
            {% set content_model_executions = dbt_artifacts.upload_model_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt__model_executions.database,
                schema_name=src_dbt__model_executions.schema,
                table_name=src_dbt__model_executions.identifier,
                content=content_model_executions
                )
            }}

            {% do log("Uploading seed executions", true) %}
            {% set src_dbt__seed_executions = dbt_artifacts.get_relation('src_dbt__seed_executions') %}
            {% set content_seed_executions = dbt_artifacts.upload_seed_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt__seed_executions.database,
                schema_name=src_dbt__seed_executions.schema,
                table_name=src_dbt__seed_executions.identifier,
                content=content_seed_executions
                )
            }}

            {% do log("Uploading snapshot executions", true) %}
            {% set src_dbt__snapshot_executions = dbt_artifacts.get_relation('src_dbt__snapshot_executions') %}
            {% set content_snapshot_executions = dbt_artifacts.upload_snapshot_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt__snapshot_executions.database,
                schema_name=src_dbt__snapshot_executions.schema,
                table_name=src_dbt__snapshot_executions.identifier,
                content=content_snapshot_executions
                )
            }}

            {% do log("Uploading test executions", true) %}
            {% set src_dbt__test_executions = dbt_artifacts.get_relation('src_dbt__test_executions') %}
            {% set content_test_executions = dbt_artifacts.upload_test_executions(results) %}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=src_dbt__test_executions.database,
                schema_name=src_dbt__test_executions.schema,
                table_name=src_dbt__test_executions.identifier,
                content=content_test_executions
                )
            }}

        {% endif %}

        {% do log("Uploading exposures", true) %}
        {% set src_dbt__exposures = dbt_artifacts.get_relation('src_dbt__exposures') %}
        {% set content_exposures = dbt_artifacts.upload_exposures(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__exposures.database,
            schema_name=src_dbt__exposures.schema,
            table_name=src_dbt__exposures.identifier,
            content=content_exposures
            )
        }}

        {% do log("Uploading tests", true) %}
        {% set src_dbt__tests = dbt_artifacts.get_relation('src_dbt__tests') %}
        {% set content_tests = dbt_artifacts.upload_tests(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__tests.database,
            schema_name=src_dbt__tests.schema,
            table_name=src_dbt__tests.identifier,
            content=content_tests
            )
        }}

        {% do log("Uploading seeds", true) %}
        {% set src_dbt__seeds = dbt_artifacts.get_relation('src_dbt__seeds') %}
        {% set content_seeds = dbt_artifacts.upload_seeds(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__seeds.database,
            schema_name=src_dbt__seeds.schema,
            table_name=src_dbt__seeds.identifier,
            content=content_seeds
            )
        }}

        {% do log("Uploading models", true) %}
        {% set src_dbt__models = dbt_artifacts.get_relation('src_dbt__models') %}
        {% set content_models = dbt_artifacts.upload_models(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__models.database,
            schema_name=src_dbt__models.schema,
            table_name=src_dbt__models.identifier,
            content=content_models
            )
        }}

        {% do log("Uploading sources", true) %}
        {% set src_dbt__sources = dbt_artifacts.get_relation('src_dbt__sources') %}
        {% set content_sources = dbt_artifacts.upload_sources(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__sources.database,
            schema_name=src_dbt__sources.schema,
            table_name=src_dbt__sources.identifier,
            content=content_sources
            )
        }}

        {% do log("Uploading snapshots", true) %}
        {% set src_dbt__snapshots = dbt_artifacts.get_relation('src_dbt__snapshots') %}
        {% set content_snapshots = dbt_artifacts.upload_snapshots(graph) %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__snapshots.database,
            schema_name=src_dbt__snapshots.schema,
            table_name=src_dbt__snapshots.identifier,
            content=content_snapshots
            )
        }}

        {% do log("Uploading invocations", true) %}
        {% set src_dbt__invocations = dbt_artifacts.get_relation('src_dbt__invocations') %}
        {% set content_invocations = dbt_artifacts.upload_invocations() %}
        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt__invocations.database,
            schema_name=src_dbt__invocations.schema,
            table_name=src_dbt__invocations.identifier,
            content=content_invocations
            )
        }}

    {% endif %}
{%- endmacro %}
