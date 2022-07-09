{% macro upload_model_executions(results) -%}
    {% set models = [] %}
    {% for result in results  %}
        {% if result.node.resource_type == "model" %}
            {% do models.append(result) %}
        {% endif %}
    {% endfor %}
    {% if models != [] %}
        {% set src_dbt_model_executions = source('dbt_artifacts', 'model_executions') %}
        {{ dbt_artifacts.create_model_executions_table_if_not_exists(src_dbt_model_executions.schema, src_dbt_model_executions.identifier) }}

        {% set model_execution_values %}
        {% for model in results if model.node.resource_type == "model" -%}
            (
                '{{ invocation_id }}',
                '{{ model.node.unique_id }}',

                {% set config_full_refresh = model.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}',

                '{{ model.thread_id }}',
                '{{ model.status }}',

                {% if model.timing != [] %}
                    {% for stage in model.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null,
                        {% else %}
                            '{{ stage.started_at }}',
                        {% endif %}
                    {% endfor %}

                    {% for stage in model.timing if stage.name == "execute" %}
                        {% if loop.length == 0 %}
                            null,
                        {% else %}
                            '{{ stage.completed_at }}',
                        {% endif %}
                    {% endfor %}
                {% else %}
                    null,
                    null,
                {% endif %}

                {{ model.execution_time }},
                null, -- rows_affected not available in Databricks
                '{{ model.node.config.materialized }}',
                '{{ model.node.schema }}',
                '{{ model.node.name }}'
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_model_executions.schema,
            table_name=src_dbt_model_executions.identifier,
            content=model_execution_values
            )
        }}
    {% endif %}
{% endmacro -%}
