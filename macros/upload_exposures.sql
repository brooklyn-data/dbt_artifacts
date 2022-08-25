{% macro upload_exposures(graph) -%}
    {% set src_dbt_exposures = source('dbt_artifacts', 'exposures') %}
    {% set exposures = [] %}
    {% for node in graph.exposures.values() %}
        {% do exposures.append(node) %}
    {% endfor %}

    {% if exposures != [] %}
        {% set exposure_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(3)) }}
        from values
        {% for exposure in exposures -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ tojson(exposure) | replace('\\', '\\\\') | replace("'", "\\'") }}' {# exposure #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_exposures.database,
            schema_name=src_dbt_exposures.schema,
            table_name=src_dbt_exposures.identifier,
            content=exposure_values
            )
        }}
    {% endif %}
{% endmacro -%}
