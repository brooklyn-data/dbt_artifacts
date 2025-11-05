{% macro upload_execution_results(results) -%}

    {% if execute %}

        {% set datasets_to_load = ['model_executions', 'seed_executions', 'test_executions', 'snapshot_executions'] %}

        {% for dataset in datasets_to_load %}

            {% set objects = dbt_artifacts.get_dataset_content(dataset) %}

            {% if (objects | length) == 0 %}
                {% continue %}
            {% endif %}

            {% do log("Uploading " ~ dataset.replace("_", " "), true) %}

            {% set upload_limit = 300 if target.type == 'bigquery' else 5000 %}

            {% for i in range(0, objects | length, upload_limit) -%}
                {% set content = dbt_artifacts.get_table_content_values(dataset, objects[i: i + upload_limit]) %}
                {{ dbt_artifacts.insert_into_metadata_table(
                    dataset=dataset,
                    fields=dbt_artifacts.get_column_name_list(dataset),
                    content=content
                    )
                }}
            {% endfor %}

        {% endfor %}

    {% endif %}

{%- endmacro %}



