{% macro upload_tests(graph) -%}
    {% set tests = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "test") %}
        {% do tests.append(node) %}
    {% endfor %}
    {{ return(adapter.dispatch('get_tests_dml_sql', 'dbt_artifacts')(tests)) }}
{%- endmacro %}

{% macro default__get_tests_dml_sql(tests) -%}

    {% if tests != [] %}
        {% set test_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(5)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(6) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(7) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(8)) }}
        from values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ test.name }}', {# name #}
                '{{ tojson(test.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ test.package_name }}', {# package_name #}
                '{{ test.original_file_path | replace('\\', '\\\\') }}', {# test_path #}
                '{{ tojson(test.tags) }}' {# tags #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ test_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_tests_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_values %}
            {% for test in tests -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ test.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ test.name }}', {# name #}
                    {{ tojson(test.depends_on.nodes) }}, {# depends_on_nodes #}
                    '{{ test.package_name }}', {# package_name #}
                    '{{ test.original_file_path | replace('\\', '\\\\') }}', {# test_path #}
                    {{ tojson(test.tags) }} {# tags #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ test_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}
