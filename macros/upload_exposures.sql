{% macro upload_exposures(graph) -%}
    {% set exposures = [] %}
    {% for node in graph.exposures.values() %}
        {% do exposures.append(node) %}
    {% endfor %}
    {{ return(adapter.dispatch('get_exposures_dml_sql', 'dbt_artifacts')(exposures)) }}
{%- endmacro %}

{% macro default__get_exposures_dml_sql(exposures) -%}

    {% if exposures != [] %}
        {% set exposure_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(3) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(4) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(5) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(6)) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(7) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(8) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(9) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(10) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(11) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(12)) }}
        from values
        {% for exposure in exposures -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ exposure.unique_id | replace("'","\\'") }}', {# node_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ exposure.name | replace("'","\\'") }}', {# name #}
                '{{ exposure.type }}', {# type #}
                '{{ tojson(exposure.owner) }}', {# owner #}
                '{{ exposure.maturity }}', {# maturity #}
                '{{ exposure.original_file_path | replace('\\', '\\\\') }}', {# path #}
                '{{ exposure.description | replace("'","\\'") }}', {# description #}
                '{{ exposure.url }}', {# url #}
                '{{ exposure.package_name }}', {# package_name #}
                '{{ tojson(exposure.depends_on.nodes) }}' {# depends_on_nodes #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}
        {{ exposure_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{% endmacro -%}

{% macro bigquery__get_exposures_dml_sql(exposures) -%}
    {% if exposures != [] %}
        {% set exposure_values %}
            {% for exposure in exposures -%}
                (
                    '{{ invocation_id }}', {# command_invocation_id #}
                    '{{ exposure.unique_id | replace("'","\\'") }}', {# node_id #}
                    '{{ run_started_at }}', {# run_started_at #}
                    '{{ exposure.name | replace("'","\\'") }}', {# name #}
                    '{{ exposure.type }}', {# type #}
                    parse_json('{{ tojson(exposure.owner) | replace("'","\\'") }}'), {# owner #}
                    '{{ exposure.maturity }}', {# maturity #}
                    '{{ exposure.original_file_path | replace('\\', '\\\\') }}', {# path #}
                    '{{ exposure.description | replace("'","\\'") }}', {# description #}
                    '{{ exposure.url }}', {# url #}
                    '{{ exposure.package_name }}', {# package_name #}
                    {{ tojson(exposure.depends_on.nodes) }} {# depends_on_nodes #}
                )
                {%- if not loop.last %},{%- endif %}
            {%- endfor %}
        {% endset %}
        {{ exposure_values }}
    {% else %}
        {{ return("") }}
    {% endif %}
{%- endmacro %}
