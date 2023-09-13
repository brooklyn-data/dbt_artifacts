{# dbt doesn't like us ref'ing in an operation so we fetch the info from the graph #}

{% macro upload_results(results) -%}

    {% if execute %}

        {% set standard_datasets = ['exposures', 'seeds', 'snapshots', 'invocations'] %}
        {% if results != [] %}
            {# When executing, and results are available, then upload the results #}
            {% set standard_datasets = ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] + standard_datasets %}
        {% endif %}

        {# Upload each data set in turn #}
        {% for dataset in standard_datasets %}

            {% do log("Uploading " ~ dataset.replace("_", ""), true) %}
            {% set dataset_relation = dbt_artifacts.get_relation(dataset) %}

            {# Get the results that need to be uploaded #}
            {% set objects %}

                {% if dataset in ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] %}
                    {{ results | selectattr("node.resource_type", "equalto", dataset.split("_")[0]) | list }}
                {#
                    Use the [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) to extract details about
                    the exposures, seeds, snapshots and invocations
                #}
                {% elif dataset in ['seeds', 'snapshots'] %}
                    {{ graph.nodes.values() | selectattr("resource_type", "equalto", dataset[:-1]) }}
                {% elif dataset == 'exposures' %}
                    {{ graph.exposures.values() | list }}
                {% endif %}

            {% endset %}

            {# Convert the results to data to be imported #}
            {% set content %}

                {# Executions make use of the results object #}
                {% if dataset == 'model_executions' %}
                    {{ dbt_artifacts.upload_model_executions(objects) }}
                {% elif dataset == 'seed_executions' %}
                    {{ dbt_artifacts.upload_seed_executions(objects) }}
                {% elif dataset == 'test_executions' %}
                    {{ dbt_artifacts.upload_test_executions(objects) }}
                {% elif dataset == 'snapshot_executions' %}
                    {{ dbt_artifacts.upload_snapshot_executions(objects) }}
                {% elif dataset == 'exposures' %}
                    {{ dbt_artifacts.upload_exposures(objects) }}
                {% elif dataset == 'seeds' %}
                    {{ dbt_artifacts.upload_seeds(objects) }}
                {% elif dataset == 'snapshots' %}
                    {{ dbt_artifacts.upload_snapshots(objects) }}
                {# Invocations only requires data from variables available in the macro #}
                {% elif dataset == 'invocations' %}
                    {{ dbt_artifacts.upload_invocations() }}
                {% endif %}

            {% endset %}

            {# Insert the content into the metadata table #}
            {{ dbt_artifacts.insert_into_metadata_table(
                database_name=dataset_relation.database,
                schema_name=dataset_relation.schema,
                table_name=dataset_relation.identifier,
                fields=dbt_artifacts.get_column_name_list(dataset),
                content=content
                )
            }}

        {% endfor %}


        {#
            We can also use a similar approach for sources, but we want to reduce the number uploaded each time
        #}

        {% do log("Uploading sources", true) %}
        {% set sources = dbt_artifacts.get_relation('sources') %}
        {% set sources_set = graph.sources.values() | list %}
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

        {#
            Use the [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) to extract details about
            the tests, models and sources - need to look through the nodes and select the ones we want
        #}

        {% do log("Uploading tests", true) %}
        {% set tests = dbt_artifacts.get_relation('tests') %}
        {% set tests_set = graph.nodes.values() | selectattr("resource_type", "equalto", "test") | list %}
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

        {% do log("Uploading models", true) %}
        {% set models = dbt_artifacts.get_relation('models') %}
        {% set models_set = graph.nodes.values() | selectattr("resource_type", "equalto", "model") | list %}
        {% set fields_models = dbt_artifacts.get_column_name_list('models') %}
        {# upload tests in chunks of 100 models (50 for BigQuery), or less #}
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

    {% endif %}
{%- endmacro %}
