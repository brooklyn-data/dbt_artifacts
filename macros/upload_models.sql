{% macro upload_models(graph) -%}
    {% set models = [] %}
    {% for node in graph.nodes.values() | selectattr("resource_type", "equalto", "model") %}
        {% do models.append(node) %}
    {% endfor %}
    {% if models != [] %}
        {% set src_dbt_models = source('dbt_artifacts', 'models') %}
        {{ dbt_artifacts.create_models_table_if_not_exists(src_dbt_models.schema, src_dbt_models.identifier) }}

        {% set model_values %}
        {% for model in models -%}
            (
                '{{ invocation_id }}', {# command_invocation_id #}
                '{{ model.unique_id }}', {# node_id #}
                '{{ model.database }}', {# database #}
                '{{ model.schema }}', {# schema #}
                '{{ model.name }}', {# name #}
                '{{ tojson(model.depends_on.nodes) }}', {# depends_on_nodes #}
                '{{ model.package_name }}', {# package_name #}
                '{{ model.original_file_path }}', {# path #}
                '{{ model.checksum.checksum }}', {# checksum #}
                '{{ model.unrendered_config.materialized }}' {# materialization #}
            )
            {%- if not loop.last %},{%- endif %}
        {%- endfor %}
        {% endset %}

        {{ dbt_artifacts.insert_into_metadata_table(
            schema_name=src_dbt_models.schema,
            table_name=src_dbt_models.identifier,
            content=model_values
            )
        }}
    {% endif %}
{% endmacro -%}
