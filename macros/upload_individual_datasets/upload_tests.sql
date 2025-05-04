{% macro upload_tests(tests) -%}
    {{ return(adapter.dispatch("get_tests_dml_sql", "dbt_artifacts")(tests)) }}
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
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(8)) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(9)) }}
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
                '{{ tojson(test.tags) }}', {# tags #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(test) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"') }}' {# all_fields #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ test_values }}
    {% else %} {{ return("") }}
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
                    {{ tojson(test.tags) }}, {# tags #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        {{ adapter.dispatch('parse_json', 'dbt_artifacts')(tojson(test) | replace("\\", "\\\\") | replace("'","\\'") | replace('"', '\\"')) }} {# all_fields #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ test_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro postgres__get_tests_dml_sql(tests) -%}
    {% if tests != [] %}
        {% set test_values %}
            {% for test in tests -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ test.unique_id }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ test.name }}', {# name #}
                    $${{ tojson(test.depends_on.nodes) }}$$, {# depends_on_nodes #}
                    '{{ test.package_name }}', {# package_name #}
                    '{{ test.original_file_path | replace('\\', '\\\\') }}', {# test_path #}
                    $${{ tojson(test.tags) }}$$, {# tags #}
                    {% if var('dbt_artifacts_exclude_all_results', false) %}
                        null
                    {% else %}
                        $${{ tojson(test) }}$$ {# all_results #}
                    {% endif %}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ test_values }}
    {% else %} {{ return("") }}
    {% endif %}
{%- endmacro %}

{% macro clickhouse__get_tests_dml_sql(tests) -%}
{{ return(dbt_artifacts.postgres__get_tests_dml_sql(tests)) }}
{%- endmacro %}

{% macro sqlserver__get_tests_dml_sql(tests) -%}

    {% if tests != [] %}
        {% set test_values %}
        select
            "1", "2", "3", "4", "5", "6", "7", "8", "9"
        from ( values
        {% for test in tests -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ test.unique_id }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ test.name }}', {# name #}
                '{{ tojson(test.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ test.package_name }}', {# package_name #}
                '{{ test.original_file_path }}', {# test_path #}
                '{{ tojson(test.tags) }}', {# tags #}
                {% if var('dbt_artifacts_exclude_all_results', false) %}
                    null
                {% else %}
                    '{{ tojson(test) | replace("'","''") }}' {# all_fields #}
                {% endif %}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        ) v ("1", "2", "3", "4", "5", "6", "7", "8", "9")
        {% endset %}
        {{ test_values }}
    {% else %} {{ return("") }}
    {% endif %}
{% endmacro -%}

