{% macro upload_test_executions(results) -%}
    {% set tests = [] %}
    {% for result in results  %}
        {% if result.node.resource_type == "test" %}
            {% do tests.append(result) %}
        {% endif %}
    {% endfor %}
    {{ return(adapter.dispatch('get_test_executions_dml_sql', 'dbt_artifacts')(tests)) }}
{%- endmacro %}

{% macro default__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(5) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(6) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(7) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(8) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(9) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(10) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(12) }}
        from values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.node.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                '{{ config_full_refresh }}', {# was_full_refresh #}

                '{{ test.thread_id }}', {# thread_id #}
                '{{ test.status }}', {# status #}

                {% if test.timing != [] %}
                    {% for stage in test.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null, {# compile_started_at #}
                        {% else %}
                            '{{ stage.started_at }}', {# compile_started_at #}
                        {% endif %}
                    {% endfor %}

                    {% for stage in test.timing if stage.name == "execute" %}
                        {% if loop.length == 0 %}
                            null, {# query_completed_at #}
                        {% else %}
                            '{{ stage.completed_at }}', {# query_completed_at #}
                        {% endif %}
                    {% endfor %}
                {% else %}
                    null, {# compile_started_at #}
                    null, {# query_completed_at #}
                {% endif %}

                {{ test.execution_time }}, {# total_node_runtime #}
                null, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }}, {# failures #}
                '{{ test.message }}' {# message #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ test_execution_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_test_executions_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_execution_values %}
        {% for test in tests -%}
            struct(
                '{{ invocation_id }}' as command_invocation_id, {# command_invocation_id #}
                '{{ test.node.unique_id }}' as node_id, {# node_id #}
                '{{ run_started_at }}' as run_started_at, {# run_started_at #}

                {% set config_full_refresh = test.node.config.full_refresh %}
                {% if config_full_refresh is none %}
                    {% set config_full_refresh = flags.FULL_REFRESH %}
                {% endif %}
                {{ config_full_refresh }} as was_full_refresh, {# was_full_refresh #}

                '{{ test.thread_id }}' as thread_id, {# thread_id #}
                '{{ test.status }}' as status, {# status #}

                {% if test.timing != [] %}
                    {% for stage in test.timing if stage.name == "compile" %}
                        {% if loop.length == 0 %}
                            null as compile_started_at, {# compile_started_at #}
                        {% else %}
                            '{{ stage.started_at }}' as compile_started_at, {# compile_started_at #}
                        {% endif %}
                    {% endfor %}

                    {% for stage in test.timing if stage.name == "execute" %}
                        {% if loop.length == 0 %}
                            null as query_completed_at, {# query_completed_at #}
                        {% else %}
                            '{{ stage.completed_at }}' as query_completed_at, {# query_completed_at #}
                        {% endif %}
                    {% endfor %}
                {% else %}
                    null as compile_started_at, {# compile_started_at #}
                    null as query_completed_at, {# query_completed_at #}
                {% endif %}

                {{ test.execution_time }} as total_node_runtime, {# total_node_runtime #}
                null as rows_affected, {# rows_affected not available in Databricks #}
                {{ 'null' if test.failures is none else test.failures }} as failures, {# failures #}
                '{{ test.message }}' as message {# message #}
            )
            {%- if not loop.last %},{%- endif %}

        {%- endfor %}
        {% endset %}
        select
            data.command_invocation_id,
            data.node_id,
            cast(data.run_started_at as timestamp),
            data.was_full_refresh,
            data.thread_id,
            data.status,
            cast(data.compile_started_at as timestamp),
            cast(data.query_completed_at as timestamp),
            data.total_node_runtime,
            data.rows_affected,
            data.failures,
            data.message
        from unnest([{{ test_execution_values }}]) as data
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}
