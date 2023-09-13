{# dbt doesn't like us ref'ing in an operation so we fetch the info from the graph #}

{% macro upload_results(results) -%}

    {% if execute %}

        {% set datasets_to_load = ['exposures', 'seeds', 'snapshots', 'invocations', 'sources', 'tests', 'models'] %}
        {% if results != [] %}
            {# When executing, and results are available, then upload the results #}
            {% set datasets_to_load = ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] + datasets_to_load %}
        {% endif %}

        {# Upload each data set in turn #}
        {% for dataset in datasets_to_load %}

            {% do log("Uploading " ~ dataset.replace("_", " "), true) %}

            {# Get the relation that the results will be uploaded to #}
            {% set dataset_relation = dbt_artifacts.get_relation(dataset) %}

            {# Get the results that need to be uploaded #}

            {% if dataset in ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] %}
                {# Executions make use of the results object #}
                {% set objects = results | selectattr("node.resource_type", "equalto", dataset.split("_")[0]) | list %}
            {% elif dataset in ['seeds', 'snapshots', 'tests', 'models'] %}
                {# Use the nodes in the [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) to extract details #}
                {% set objects = graph.nodes.values() | selectattr("resource_type", "equalto", dataset[:-1]) | list %}
            {% elif dataset in ['exposures', 'sources'] %}
                {# Use the [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) to extract details #}
                {% set objects = graph.get(dataset).values() | list %}
            {% elif dataset == 'invocations' %}
                {#
                    Invocations doesn't need anything input, but we include this so that it will still be picked up
                    as part of the loop below - the length must be >0 to allow for an upload, hence the empty string
                #}
                {% set objects = [''] %}
            {% endif %}


            {# Upload in chunks to reduce query size #}
            {% if dataset == 'model' %}
                {% set upload_limit = 50 if target.type == 'bigquery' else 100 %}
            {% else %}
                {% set upload_limit = 300 if target.type == 'bigquery' else 5000 %}
            {% endif %}

            {# Loop through each chunk in turn #}
            {% for i in range(0, objects | length, upload_limit) -%}

                {# Get just the objects to load on this loop #}
                {% set objects_to_upload = objects[i: i + upload_limit] %}

                {# Convert the results to data to be imported #}
                {% set content %}

                    {% if dataset == 'model_executions' %}
                        {{ dbt_artifacts.upload_model_executions(objects_to_upload) }}
                    {% elif dataset == 'seed_executions' %}
                        {{ dbt_artifacts.upload_seed_executions(objects_to_upload) }}
                    {% elif dataset == 'test_executions' %}
                        {{ dbt_artifacts.upload_test_executions(objects_to_upload) }}
                    {% elif dataset == 'snapshot_executions' %}
                        {{ dbt_artifacts.upload_snapshot_executions(objects_to_upload) }}
                    {% elif dataset == 'exposures' %}
                        {{ dbt_artifacts.upload_exposures(objects_to_upload) }}
                    {% elif dataset == 'models' %}
                        {{ dbt_artifacts.upload_models(objects_to_upload) }}
                    {% elif dataset == 'seeds' %}
                        {{ dbt_artifacts.upload_seeds(objects_to_upload) }}
                    {% elif dataset == 'snapshots' %}
                        {{ dbt_artifacts.upload_snapshots(objects_to_upload) }}
                    {% elif dataset == 'sources' %}
                        {{ dbt_artifacts.upload_sources(objects_to_upload) }}
                    {% elif dataset == 'tests' %}
                        {{ dbt_artifacts.upload_tests(objects_to_upload) }}
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

            {# Loop the next 'chunk' #}
            {% endfor %}

        {# Loop the next 'dataset' #}
        {% endfor %}

    {% endif %}

{%- endmacro %}
