{% macro upload_exposures(graph) -%}
    {% set exposures = [] %}
    {% for node in graph.exposures.values() %}
        {% do exposures.append(node) %}
    {% endfor %}
    {% if exposures != [] %}
        {% set src_dbt_exposures = source('dbt_artifacts', 'exposures') %}
        {{ dbt_artifacts.create_exposures_table_if_not_exists(src_dbt_exposures.schema, src_dbt_exposures.identifier) }}

        {% set exposure_values %}
        select
            $1,
            $2,
            $3,
            $4,
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')('$5') }},
            $6,
            $7,
            $8,
            $9,
            $10,
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')('$11') }}
        from values
        {% for exposure in exposures -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ exposure.unique_id }}', {# node_id #}
                '{{ exposure.name }}', {# name #}
                '{{ exposure.type }}', {# type #}
                '{{ tojson(exposure.owner) }}', {# owner #}
                '{{ exposure.maturity }}', {# maturity #}
                '{{ exposure.original_file_path }}', {# path #}
                '{{ exposure.description }}', {# description #}
                '{{ exposure.url }}', {# url #}
                '{{ exposure.package_name }}', {# package_name #}
                '{{ tojson(exposure.depends_on.nodes) }}' {# depends_on_nodes #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_exposures.schema,
            table_name=src_dbt_exposures.identifier,
            content=exposure_values
            )
        }}
    {% endif %}
{% endmacro -%}
