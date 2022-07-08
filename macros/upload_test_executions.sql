{% macro upload_test_executions(results) -%}
    {% set tests = [] %}
    {% for result in results  %}
        {% if result.node.resource_type == "test" %}
            {% do tests.append(result) %}
        {% endif %}
    {% endfor %}
    {% if tests != [] %}
        {% set src_dbt_test_executions = source('dbt_artifacts', 'test_executions') %}
        {{ dbt_artifacts.create_test_executions_table_if_not_exists(src_dbt_test_executions.schema, src_dbt_test_executions.identifier) }}

        {% set test_execution_values %}
        {% for test in tests -%}
            (
                '{{ invocation_id }}',
                '{{ test.node.unique_id }}',

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}',

                '{{ test.thread_id }}',
                '{{ test.status }}',

                {% if test.timing != [] %}
                    {% for stage in test.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null,
                        {% else %}
                            '{{ stage.started_at }}',
                        {% endif %}
                    {% endfor %}

                    {% for stage in test.timing if stage.name == "execute" %}
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

                {{ test.execution_time }},
                null, -- rows_affected not available in Databricks
                '{{ test.failures }}'
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_test_executions.schema,
            table_name=src_dbt_test_executions.identifier,
            content=test_execution_values
            )
        }}
    {% endif %}
{% endmacro -%}
