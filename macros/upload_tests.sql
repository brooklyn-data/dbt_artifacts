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
                struct(
                    '{{ invocation_id }}' as command_invocation_id, {# command_invocation_id #}
                    '{{ test.unique_id }}' as node_id, {# node_id #}
                    '{{ run_started_at }}' as run_started_at, {# run_started_at #}
                    '{{ test.name }}' as name, {# name #}
                    {{ tojson(test.depends_on.nodes) }} as depends_on_nodes, {# depends_on_nodes #}
                    '{{ test.package_name }}' as package_name, {# package_name #}
                    '{{ test.original_file_path | replace('\\', '\\\\') }}' as test_path, {# test_path #}
                    {{ tojson(test.tags) }} as tags {# tags #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        select
            data.command_invocation_id,
            data.node_id,
            cast(data.run_started_at as timestamp),
            data.name,
            data.depends_on_nodes,
            data.package_name,
            data.test_path,
            data.tags
        from unnest([{{ test_values }}]) as data
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}



