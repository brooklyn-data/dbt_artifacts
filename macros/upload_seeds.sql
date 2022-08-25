{% macro upload_seeds(graph) -%}
    {% set src_dbt_seeds = source('dbt_artifacts', 'seeds') %}
    {% set seeds = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "seed") %}
        {% do seeds.append(node) %}
    {% endfor %}

    {% if seeds != [] %}
        {% set seed_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(3)) }}
        from values
        {% for seed in seeds -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ tojson(seed) | replace('\\', '\\\\') | replace("'", "\\'") }}' {# seed #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_seeds.database,
            schema_name=src_dbt_seeds.schema,
            table_name=src_dbt_seeds.identifier,
            content=seed_values
            )
        }}
    {% endif %}
{% endmacro -%}
