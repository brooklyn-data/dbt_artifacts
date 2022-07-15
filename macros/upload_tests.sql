{% macro upload_tests(graph) -%}
    {% set tests = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "test") %}
        {% do tests.append(node) %}
    {% endfor %}
    {% if tests != [] %}
        {% set src_dbt_tests = source('dbt_artifacts', 'tests') %}
        {{ dbt_artifacts.create_tests_table_if_not_exists(src_dbt_tests.schema, src_dbt_tests.identifier) }}

        {% set test_values %}
        select
            $1,
            $2,
            $3,
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')('$4') }},
            $5,
            $6,
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')('$7') }}
        from values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.unique_id }}', {# node_id #}
                '{{ test.name }}', {# name #}
                '{{ tojson(test.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ test.package_name }}', {# package_name #}
                '{{ test.original_file_path }}', {# test_path #}
                '{{ tojson(test.tags) }}' {# tags #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_tests.schema,
            table_name=src_dbt_tests.identifier,
            content=test_values
            )
        }}
    {% endif %}
{% endmacro -%}
