{% macro upload_models(graph) -%}
    {% set src_dbt_models = source('dbt_artifacts', 'models') %}
    {% set models = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}
        {% do models.append(node) %}
    {% endfor %}

    {% if models != [] %}
        {% set model_values %}
        select
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(1) }},
            {{ adapter.dispatch('column_identifier', 'dbt_artifacts')(2) }},
            {{ adapter.dispatch('parse_json', 'dbt_artifacts')(adapter.dispatch('column_identifier', 'dbt_artifacts')(3)) }}
        from values
        {% for model in models -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ run_started_at }}', {# run_started_at #}
                '{{ tojson(model) | replace('\\', '\\\\') | replace("'", "\\'") }}' {# model #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            database_name=src_dbt_models.database,
            schema_name=src_dbt_models.schema,
            table_name=src_dbt_models.identifier,
            content=model_values
            )
        }}
    {% endif %}
{% endmacro -%}
